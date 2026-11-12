"""Lösungen zu den Aufgaben S2 bis S7 (Resilient Serving).

Start: uv run --with scikit-learn --with pandas --with numpy python 04_serving.py
"""
import json
import math

import numpy as np
import pandas as pd
from scipy.stats import norm
from sklearn.datasets import load_digits
from sklearn.linear_model import LogisticRegression, LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.svm import SVC

# --- S2: Online gegen Batch (Annahmen, keine Messung) -------------------------------------------------
print("S2  200 000 Bestellungen; Annahme: 4 ms Fixkosten je Aufruf, 0,01 ms Rechenzeit je Zeile")
n, fix, je_zeile = 200_000, 4.0, 0.01
online = n * (fix + je_zeile) / 1000
batch = (n / 50_000 * fix + n * je_zeile) / 1000
print(f"Einzelaufrufe: {online:.0f} s ({online / 60:.1f} min); Batch zu 50 000 Zeilen: {batch:.2f} s; Faktor {online / batch:.0f}")

# --- S3: Two-Phase, Rechnung ---------------------------------------------------------------------------
print("\nS3  Two-Phase: 82 % sicher (Genauigkeit 99 %), Rest an die Cloud (Genauigkeit 97 %)")
anteil_edge, acc_edge, acc_cloud_rest, acc_edge_rest = 0.82, 0.99, 0.97, 0.71
acc_gesamt = anteil_edge * acc_edge + (1 - anteil_edge) * acc_cloud_rest
print(f"Gesamtgenauigkeit {acc_gesamt:.4f}; Cloud-Anteil {1 - anteil_edge:.0%}")
anfragen, kb, euro = 1_000_000, 200, 0.0004
print(f"Datenvolumen {anfragen * kb / 1e6:.0f} GB -> {anfragen * kb * (1 - anteil_edge) / 1e6:.0f} GB; "
      f"Cloud-Kosten {anfragen * euro:.0f} -> {anfragen * (1 - anteil_edge) * euro:.0f} Euro")
lat_edge, lat_cloud = 20, 250
print(f"Mittlere Latenz {lat_edge + (1 - anteil_edge) * lat_cloud:.0f} ms gegen {lat_edge + lat_cloud} ms im schlechtesten Fall")
print(f"Zum Vergleich: Edge allein auf den unsicheren Fällen {acc_edge_rest:.0%} -> Gesamt {anteil_edge * acc_edge + (1 - anteil_edge) * acc_edge_rest:.4f}")

# --- S4: Schwelle wählen ---------------------------------------------------------------------------------
print("\nS4  Ziffern: Edge = logistische Regression auf 4x4, Cloud = SVM auf 8x8")
X, y = load_digits(return_X_y=True)
X_tr, X_rest, y_tr, y_rest = train_test_split(X, y, test_size=0.5, random_state=0, stratify=y)
X_val, X_te, y_val, y_te = train_test_split(X_rest, y_rest, test_size=0.6, random_state=0, stratify=y_rest)


def klein(Xa):
    b = Xa.reshape(-1, 8, 8)
    return b.reshape(-1, 4, 2, 4, 2).mean(axis=(2, 4)).reshape(-1, 16)


edge = LogisticRegression(max_iter=2000).fit(klein(X_tr), y_tr)
cloud = SVC(gamma=0.001, C=10).fit(X_tr, y_tr)


def phase(Xa):
    p = edge.predict_proba(klein(Xa))
    return p.max(axis=1), p.argmax(axis=1), cloud.predict(Xa)


def lauf(daten, tau):
    sicher, pe, pc = phase(daten[0])
    zur_cloud = sicher < tau
    return zur_cloud.mean(), (np.where(zur_cloud, pc, pe) == daten[1]).mean()


val, test = (X_val, y_val), (X_te, y_te)
acc_e = (phase(X_te)[1] == y_te).mean()
acc_c = (phase(X_te)[2] == y_te).mean()
print(f"Trainingsbilder {len(y_tr)}, Validierung {len(y_val)}, Test {len(y_te)}")
print(f"Test: Edge allein {acc_e:.4f}, Cloud allein {acc_c:.4f}")
print(f"{'Schwelle':>9} {'Cloud-Anteil':>13} {'Genauigkeit':>12}   (Testbilder)")
for tau in (0.5, 0.7, 0.8, 0.9, 0.95, 0.99, 0.999):
    a, g = lauf(test, tau)
    print(f"{tau:>9} {a:>13.3f} {g:>12.4f}")
acc_c_val = (phase(X_val)[2] == y_val).mean()
taus = np.linspace(0.1, 1.0, 91)
ziel = acc_c_val - 0.01
passend = [t for t in taus if lauf(val, t)[1] >= ziel]
tau_gewaehlt = min(passend, key=lambda t: lauf(val, t)[0])
a_val, g_val = lauf(val, tau_gewaehlt)
a_te, g_te = lauf(test, tau_gewaehlt)
print(f"Auf den Validierungsdaten gewählt (höchstens 1 Punkt unter Cloud allein = {ziel:.4f}): tau = {tau_gewaehlt:.2f}, "
      f"Cloud-Anteil {a_val:.3f}, Genauigkeit {g_val:.4f}")
print(f"Einmal auf den Testdaten: Cloud-Anteil {a_te:.3f}, Genauigkeit {g_te:.4f} (Cloud allein {acc_c:.4f})")
kurve = [dict(zip(("tau", "anteil", "acc"), (float(t), *map(float, lauf(test, t))))) for t in taus]
with open("twophase_s4.json", "w") as f:
    json.dump({"kurve": kurve, "acc_edge": float(acc_e), "acc_cloud": float(acc_c),
               "gewaehlt": {"tau": float(tau_gewaehlt), "anteil": float(a_te), "acc": float(g_te)}}, f)

# --- S5: Keyed Predictions ---------------------------------------------------------------------------------
print("\nS5  Ergebnisse treffen in anderer Reihenfolge ein")
df = pd.DataFrame({"bestell_id": [f"B{1000 + i}" for i in range(12)], "x": np.arange(12.0)})
df["y"] = 3 * df["x"] + 1
modell = LinearRegression().fit(df[["x"]], df["y"])
stuecke = [df.iloc[i:i + 3] for i in range(0, 12, 3)]
ankunft = [2, 0, 3, 1]  # so kommen die Stücke an
antworten = [pd.DataFrame({"bestell_id": stuecke[i]["bestell_id"].values,
                           "vorhersage": modell.predict(stuecke[i][["x"]])}) for i in ankunft]
alle = pd.concat(antworten, ignore_index=True)
# Reihenfolge angenommen
falsch = df.assign(vorhersage=alle["vorhersage"].values)
# Join über den Schlüssel
richtig = df.merge(alle, on="bestell_id", validate="one_to_one")
print(f"mittlerer Fehler, Reihenfolge angenommen: {(falsch['vorhersage'] - falsch['y']).abs().mean():.2f}")
print(f"mittlerer Fehler, Join über den Schlüssel: {(richtig['vorhersage'] - richtig['y']).abs().mean():.2f}")
wiederholt = pd.concat([alle, alle.iloc[:3]], ignore_index=True)  # ein Stück kam doppelt (Wiederholung)
try:
    df.merge(wiederholt, on="bestell_id", validate="one_to_one")
except Exception as e:
    print("Doppelte Schlüssel fallen auf:", type(e).__name__)

# --- S6: PSI ---------------------------------------------------------------------------------------------
print("\nS6  Population Stability Index")
erwartet = np.array([0.20, 0.30, 0.25, 0.15, 0.10])
aktuell = np.array([0.10, 0.25, 0.25, 0.20, 0.20])
beitraege = (aktuell - erwartet) * np.log(aktuell / erwartet)
print("Beiträge je Bin:", np.round(beitraege, 4), "PSI =", round(beitraege.sum(), 4))

# --- S7: Stichprobengröße -----------------------------------------------------------------------------------
print("\nS7  Wie viele beschriftete Fälle für den Nachweis eines Rückgangs von 90 % auf 87 %?")
p0, p1, alpha, power = 0.90, 0.87, 0.05, 0.80
za, zb = norm.ppf(1 - alpha / 2), norm.ppf(power)
n_ben = ((za * math.sqrt(p0 * (1 - p0)) + zb * math.sqrt(p1 * (1 - p1))) / (p0 - p1)) ** 2
print(f"z_alpha/2 = {za:.3f}, z_beta = {zb:.3f}, n = {n_ben:.1f} -> {math.ceil(n_ben)}")
for n_ in (100, 500, 1000):
    se = math.sqrt(p0 * (1 - p0) / n_)
    print(f"n = {n_:>4}: Standardfehler {se * 100:.2f} Punkte, 95-%-Intervall +/- {1.96 * se * 100:.2f} Punkte")
print(f"Bei 100 beschrifteten Fällen pro Tag: {math.ceil(n_ben) / 100:.1f} Tage, dazu 30 Tage Verzögerung der Labels")

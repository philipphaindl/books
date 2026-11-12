"""Lösungen zu den Aufgaben D2 bis D6 (Data Representation).

Start: uv run --with scikit-learn --with pandas --with numpy python 01_darstellung.py
"""
import json
import math

import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
from sklearn.tree import DecisionTreeClassifier
from sklearn.utils import murmurhash3_32


def anteil_kollision(n, B):
    """Wahrscheinlichkeit, dass ein bestimmter Wert seinen Bucket mit mindestens einem anderen teilt."""
    return 1 - (1 - 1 / B) ** (n - 1)


def belegte_buckets(n, B):
    """Erwartete Zahl der Buckets, in die mindestens ein Wert fällt."""
    return B * (1 - (1 - 1 / B) ** n)


def gemessen(n, B):
    ids = [f"produkt-{i:06d}" for i in range(n)]
    bucket = np.array([murmurhash3_32(s, seed=0, positive=True) % B for s in ids])
    zaehler = np.bincount(bucket, minlength=B)
    kollidiert = (zaehler[bucket] > 1).mean()
    return kollidiert, int((zaehler > 0).sum())


# --- D2: Kollisionen -------------------------------------------------------------
print("D2  Kollisionen bei n = 20 000 Produkt-IDs")
n = 20_000
print(f"{'B':>9} {'Formel':>8} {'gemessen':>9} {'belegt (Formel)':>16} {'belegt (gemessen)':>18}")
kurve = []
for B in (10_000, 20_000, 50_000, 100_000, 200_000, 500_000, 1_000_000, 2_000_000):
    f = anteil_kollision(n, B)
    g, belegt = gemessen(n, B)
    print(f"{B:>9} {f:>8.4f} {g:>9.4f} {belegte_buckets(n, B):>16.1f} {belegt:>18}")
    kurve.append({"B": B, "formel": f, "gemessen": g})
B_theorie = [{"B": int(b), "formel": anteil_kollision(n, b)} for b in np.logspace(3.7, 6.5, 40)]

# Wie viele Buckets für höchstens 5 % Kollisionsanteil?
B_exakt = 1 / (1 - 0.95 ** (1 / (n - 1)))
B_naeherung = n / -math.log(0.95)
print(f"\nB für höchstens 5 % Kollision: exakt {B_exakt:,.0f}, Näherung n/(-ln 0,95) = {B_naeherung:,.0f}")
print(f"Das ist das {B_exakt / n:.1f}-Fache der Wertezahl.")

# --- Zusatz zu D2: Postleitzahlen ------------------------------------------------------------
n_plz, B_plz = 2_000, 500
print("\nZusatz zu D2: 2 000 Postleitzahlen in 500 Buckets")
print(f"Anteil mit Kollision (Formel): {anteil_kollision(n_plz, B_plz):.4f}")
g, belegt = gemessen(n_plz, B_plz)
print(f"Anteil mit Kollision (gemessen): {g:.4f}, belegte Buckets: {belegt} von {B_plz}")
print(f"Im Mittel {n_plz / B_plz:.0f} Werte je Bucket; One-Hot hätte {n_plz} Spalten.")

# --- D3: Feature Cross --------------------------------------------------------------
print("\nD3  Zellen und Beispiele je Zelle (1 000 000 Fahrten)")
fahrten = 1_000_000
for name, zellen in (("Wochentag x Stunde", 7 * 24),
                     ("Wochentag x Stunde x Bezirk (23)", 7 * 24 * 23),
                     ("Werktag/Wochenende x Stunde", 2 * 24),
                     ("Stunde x Bezirk", 24 * 23)):
    print(f"{name:<36} {zellen:>6} Zellen, {fahrten / zellen:>9.1f} Fahrten je Zelle")

# --- D4: Feature Cross auf Zahlen ------------------------------------------------------
print("\nD4  Quadranten-Aufgabe: Label ist 1, wenn x*y > 0 (5 % Rauschen)")
rng = np.random.default_rng(42)
N = 20_000
x, y = rng.uniform(-1, 1, N), rng.uniform(-1, 1, N)
label = (x * y > 0).astype(int)
label = np.where(rng.random(N) < 0.05, 1 - label, label)
kanten = np.array([-0.5, 0.0, 0.5])
bx, by = np.digitize(x, kanten), np.digitize(y, kanten)  # je 4 Buckets: 0 bis 3
zelle = bx * 4 + by  # das Feature Cross: 16 Zellen
idx_tr, idx_te = train_test_split(np.arange(N), test_size=0.3, random_state=0)


def one_hot(*spalten):
    return OneHotEncoder(handle_unknown="ignore").fit_transform(np.column_stack(spalten))


def genauigkeit(X, modell):
    modell.fit(X[idx_tr], label[idx_tr])
    return modell.score(X[idx_te], label[idx_te])


a_ohne = genauigkeit(one_hot(bx, by), LogisticRegression(max_iter=1000))
a_cross = genauigkeit(one_hot(zelle), LogisticRegression(max_iter=1000))
a_baum = genauigkeit(np.column_stack([bx, by]), DecisionTreeClassifier(max_depth=4, random_state=0))
print(f"Logistische Regression, Buckets einzeln (8 Spalten): {a_ohne:.3f}")
print(f"Logistische Regression, Cross der Buckets (16 Spalten): {a_cross:.3f}")
print(f"Entscheidungsbaum, Buckets einzeln, Tiefe 4:           {a_baum:.3f}")
print(f"Obergrenze durch das Rauschen:                         0.950")

# Beste Gerade auf den Rohwerten (Rastersuche über Richtung und Verschiebung, auf den Trainingsdaten)
beste = (0.0, None)
for winkel in np.linspace(0, np.pi, 91):
    projektion = np.cos(winkel) * x[idx_tr] + np.sin(winkel) * y[idx_tr]
    for c in np.linspace(-1.2, 1.2, 61):
        a = ((projektion > c) == label[idx_tr]).mean()
        a = max(a, 1 - a)
        if a > beste[0]:
            beste = (a, (winkel, c))
w_, c_ = beste[1]
test_gerade = ((np.cos(w_) * x[idx_te] + np.sin(w_) * y[idx_te] > c_) == label[idx_te]).mean()
test_gerade = max(test_gerade, 1 - test_gerade)
print(f"Beste Gerade auf den Rohwerten (Rastersuche): Training {beste[0]:.3f}, Test {test_gerade:.3f}")

# Ohne Cross hängt die Genauigkeit von einem zufälligen Restmuster ab. Über 20 Datensätze gemittelt:
einzeln = []
for seed in range(20):
    r = np.random.default_rng(100 + seed)
    xs, ys = r.uniform(-1, 1, N), r.uniform(-1, 1, N)
    lab = (xs * ys > 0).astype(int)
    lab = np.where(r.random(N) < 0.05, 1 - lab, lab)
    bxs, bys = np.digitize(xs, kanten), np.digitize(ys, kanten)
    X = one_hot(bxs, bys)
    m = LogisticRegression(max_iter=1000).fit(X[idx_tr], lab[idx_tr])
    einzeln.append(m.score(X[idx_te], lab[idx_te]))
print(f"Ohne Cross, 20 Wiederholungen: Mittel {np.mean(einzeln):.3f}, Minimum {min(einzeln):.3f}, Maximum {max(einzeln):.3f}")

# --- D5: Embedding-Größen ------------------------------------------------------------
print("\nD5  Embedding-Tabelle für 4 000 000 Titel")
titel = 4_000_000
d = titel ** 0.25
print(f"Vierte Wurzel: {d:.2f} -> d = {round(d)}")
for name, zeilen, dim in (("ohne Hashing", titel, round(d)), ("Hash auf 500 000 Buckets", 500_000, round(d))):
    parameter = zeilen * dim
    print(f"{name:<26} {parameter:>12,} Parameter, {parameter * 4 / 1e6:>7.0f} MB (float32)")
print(f"Lineares Modell mit One-Hot: {titel:,} Gewichte, {titel * 4 / 1e6:.0f} MB")

# --- D6: Gewicht der Quellen ------------------------------------------------------------
print("\nD6  Multimodal: Betrag der Teilvektoren")
bild, tabelle = 10_000, 5
print(f"Bild: sqrt({bild}) = {math.sqrt(bild):.0f}, Tabelle: sqrt({tabelle}) = {math.sqrt(tabelle):.2f}, "
      f"Verhältnis {math.sqrt(bild) / math.sqrt(tabelle):.1f}")

with open("kollision_d2.json", "w") as f:
    json.dump({"n": n, "punkte": kurve, "kurve": B_theorie, "B_5prozent": B_exakt}, f)

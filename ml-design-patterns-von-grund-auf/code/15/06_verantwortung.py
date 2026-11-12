"""Lösungen zu den Aufgaben V1 bis V6 (Responsible AI).

Start: uv run --with scikit-learn --with pandas --with numpy python 06_verantwortung.py
"""
import itertools
import json
import math

import numpy as np
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import train_test_split


# --- V1: Heuristic Benchmark ---------------------------------------------------------------------------------------
def lieferdaten(n=6000, seed=0):
    r = np.random.default_rng(seed)
    km = r.uniform(0.5, 10, n)
    artikel = r.integers(1, 9, n)
    regen = r.integers(0, 2, n)
    dauer = 12 + 2.6 * km + 0.5 * artikel + 6 * regen + r.normal(0, 2.5, n)
    return np.column_stack([km, artikel, regen]), dauer


print("V1  Lieferzeit: Benchmarks und Modelle (mittlerer absoluter Fehler in Minuten)")
X, y = lieferdaten()
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.3, random_state=0)
ergebnisse = {
    "Mittelwert der Trainingsdaten": mean_absolute_error(y_te, np.full(len(y_te), y_tr.mean())),
    "Faustregel 10 + 3 * km": mean_absolute_error(y_te, 10 + 3 * X_te[:, 0]),
    "Lineare Regression": mean_absolute_error(y_te, LinearRegression().fit(X_tr, y_tr).predict(X_te)),
    "Gradient Boosting": mean_absolute_error(y_te, GradientBoostingRegressor(random_state=0).fit(X_tr, y_tr).predict(X_te)),
}
for name, mae in ergebnisse.items():
    print(f"{name:<32} {mae:.2f}")
b = ergebnisse["Faustregel 10 + 3 * km"]
print(f"Linear gegen Faustregel: {(b - ergebnisse['Lineare Regression']) / b:.1%} weniger Fehler")
print(f"Boosting gegen linear:   {(ergebnisse['Lineare Regression'] - ergebnisse['Gradient Boosting']) / ergebnisse['Lineare Regression']:.1%} weniger Fehler")
print(f"Rauschen der Daten (Standardabweichung 2,5): erwarteter MAE im Optimum {2.5 * math.sqrt(2 / math.pi):.2f}")

# --- V2: Attribution --------------------------------------------------------------------------------------------------
print("\nV2  Lineares Modell: Beitrag je Merkmal gegen eine Baseline")
w = np.array([2.5, 0.6, 5.0])
b0 = 8.0
x = np.array([9.0, 5.0, 1.0])


def modell(v):
    return b0 + v @ w


def beitraege(x, baseline):
    return w * (x - baseline)


def shapley_exakt(x, baseline):
    """Exakte Shapley-Werte: Merkmale außerhalb der Koalition stehen auf dem Wert der Baseline."""
    m = len(x)
    phi = np.zeros(m)
    for i in range(m):
        andere = [j for j in range(m) if j != i]
        for k in range(m):
            for S in itertools.combinations(andere, k):
                gewicht = math.factorial(k) * math.factorial(m - k - 1) / math.factorial(m)
                mit, ohne = baseline.copy(), baseline.copy()
                for j in S:
                    mit[j] = ohne[j] = x[j]
                mit[i] = x[i]
                phi[i] += gewicht * (modell(mit) - modell(ohne))
    return phi


for name, base in (("Mittelwerte (4 km, 3 Artikel, Regenanteil 0,3)", np.array([4.0, 3.0, 0.3])),
                   ("trockener Tag (4 km, 3 Artikel, kein Regen)", np.array([4.0, 3.0, 0.0]))):
    phi = beitraege(x, base)
    print(f"Baseline {name}")
    print(f"  Vorhersage Baseline {modell(base):.1f}, Fall {modell(x):.1f}, Differenz {modell(x) - modell(base):.1f}")
    print(f"  Beiträge km/Artikel/Regen: {np.round(phi, 2)} Summe {phi.sum():.2f}; exakt (Shapley): {np.round(shapley_exakt(x, base), 2)}")

# --- V4: Fairness-Kennzahlen -------------------------------------------------------------------------------------------
print("\nV4  Kennzahlen je Gruppe")
gruppen = {"A": dict(tp=320, fn=80, fp=60, tn=540), "B": dict(tp=60, fn=40, fp=40, tn=360)}
kenn = {}
for g, m in gruppen.items():
    n = sum(m.values())
    kenn[g] = {
        "n": n,
        "Genauigkeit": (m["tp"] + m["tn"]) / n,
        "Auswahlrate": (m["tp"] + m["fp"]) / n,
        "TPR": m["tp"] / (m["tp"] + m["fn"]),
        "FPR": m["fp"] / (m["fp"] + m["tn"]),
        "PPV": m["tp"] / (m["tp"] + m["fp"]),
    }
    print(g, {k: (round(v, 3) if isinstance(v, float) else v) for k, v in kenn[g].items()})
gesamt = {k: sum(m[k] for m in gruppen.values()) for k in ("tp", "fn", "fp", "tn")}
print(f"Gesamtgenauigkeit {(gesamt['tp'] + gesamt['tn']) / sum(gesamt.values()):.4f}")
print(f"Verhältnis der Auswahlraten B/A: {kenn['B']['Auswahlrate'] / kenn['A']['Auswahlrate']:.3f}")
print(f"Differenz der TPR: {kenn['A']['TPR'] - kenn['B']['TPR']:.2f}; Differenz der FPR: {kenn['A']['FPR'] - kenn['B']['FPR']:.2f}")
with open("fairness_v4.json", "w") as f:
    json.dump(kenn, f)

# --- V5: Unmöglichkeit ------------------------------------------------------------------------------------------------------
print("\nV5  Gleiche TPR und FPR, verschiedene Basisraten")
tpr, fpr = 0.8, 0.1
for g, rate in (("A", 0.4), ("B", 0.2)):
    ppv = rate * tpr / (rate * tpr + (1 - rate) * fpr)
    auswahl = rate * tpr + (1 - rate) * fpr
    print(f"Gruppe {g}: Basisrate {rate:.2f} -> PPV {ppv:.3f}, Auswahlrate {auswahl:.3f}")
rate_b, ziel_ppv = 0.2, 0.8421052631578947
fpr_noetig = rate_b * tpr * (1 - ziel_ppv) / (ziel_ppv * (1 - rate_b))
print(f"Damit B dieselbe PPV 0,842 wie A erreicht (TPR 0,8), müsste die FPR in B {fpr_noetig:.4f} sein statt {fpr}")

# --- V6: Proxy-Merkmale --------------------------------------------------------------------------------------------------------
print("\nV6  Das geschützte Merkmal wird entfernt, ein Proxy bleibt")
r = np.random.default_rng(5)
n = 40_000
gruppe = r.integers(0, 2, n)
koennen = r.normal(size=n)
proxy = gruppe + r.normal(0, 0.5, n)
eingestellt = (koennen - 0.9 * gruppe + r.normal(0, 0.5, n) > 0.3).astype(int)  # verzerrte Vergangenheit
print(f"Historische Einstellquote: Gruppe 0 {eingestellt[gruppe == 0].mean():.3f}, Gruppe 1 {eingestellt[gruppe == 1].mean():.3f}")
print(f"Korrelation Proxy und Gruppe: {np.corrcoef(proxy, gruppe)[0, 1]:.2f}")
tr, te = train_test_split(np.arange(n), test_size=0.5, random_state=0)
for name, spalten in (("Können + Proxy", [koennen, proxy]), ("nur Können", [koennen])):
    M = np.column_stack(spalten)
    p = LogisticRegression().fit(M[tr], eingestellt[tr]).predict_proba(M[te])[:, 1]
    schwelle = np.quantile(p, 0.7)  # die besten 30 % werden ausgewählt
    sel = p >= schwelle
    g = gruppe[te]
    print(f"{name:<16} Auswahlrate Gruppe 0: {sel[g == 0].mean():.3f}, Gruppe 1: {sel[g == 1].mean():.3f}")

"""Pattern 18: Continued Model Evaluation, simulierte Drift über 24 Wochen.

Wochen 0-3: Referenz/Training. 4-7: stabil. 8-13: Covariate Shift (Eingaben verschieben sich, die
Beziehung Eingabe -> Label bleibt). 14-17: Concept Drift (die Beziehung selbst wandert), danach neu.
Ausführen:  uv run --with scikit-learn --with numpy --with scipy python drift.py
"""
import json

import numpy as np
from scipy.stats import ks_2samp
from sklearn.linear_model import LogisticRegression

# beschriftete Fälle pro Woche
N = 2000


def woche(w):
    rng = np.random.default_rng(1000 + w)
    # Covariate Shift in Woche 8-13
    x1 = rng.normal(1.5 if 8 <= w <= 13 else 0.0, 1.0, N)
    x2 = rng.normal(0.0, 1.0, N)
    # Concept Drift: Woche 14-17 schrittweise
    a = min(1.0, max(0.0, (w - 13) / 4))
    score = (1 - a) * (1.0 * x1 + 0.5 * x2) + a * (-0.3 * x1 + 1.0 * x2)
    y = (score + rng.normal(0, 0.5, N) > 0).astype(int)
    return np.column_stack([x1, x2]), y


def psi(referenz, aktuell, klassen=10):
    """Population Stability Index über Dezile der Referenz."""
    kanten = np.quantile(referenz, np.linspace(0, 1, klassen + 1))
    kanten[0], kanten[-1] = -np.inf, np.inf
    p = np.histogram(referenz, kanten)[0] / len(referenz)
    q = np.histogram(aktuell, kanten)[0] / len(aktuell)
    p, q = np.clip(p, 1e-4, None), np.clip(q, 1e-4, None)
    return float(np.sum((q - p) * np.log(q / p)))


daten = [woche(w) for w in range(24)]
X_ref = np.vstack([daten[w][0] for w in range(4)])
y_ref = np.concatenate([daten[w][1] for w in range(4)])
alt = LogisticRegression().fit(X_ref, y_ref)
SCHWELLE = 0.80
phase = lambda w: "stabil" if w < 8 else ("Covariate Shift" if w < 14 else "Concept Drift")

print(f"{'Woche':>5s} {'Phase':16s} {'Genauigkeit':>12s} {'PSI(x1)':>8s} {'KS-p(x1)':>10s}  Alarm")
tabelle, ausloeser = [], None
for w in range(4, 24):
    X, y = daten[w]
    acc = alt.score(X, y)
    p = psi(X_ref[:, 0], X[:, 0])
    ks = ks_2samp(X_ref[:, 0], X[:, 0]).pvalue
    alarm = []
    if p > 0.25: alarm.append("Eingaben")
    if acc < SCHWELLE: alarm.append("Qualität")
    if acc < SCHWELLE and ausloeser is None:
        ausloeser = w
    tabelle.append((w, acc, p))
    print(f"{w:5d} {phase(w):16s} {acc:12.3f} {p:8.3f} {ks:10.2g}  {', '.join(alarm)}")

# Retraining: zwei Wochen nach dem Alarm, mit den jeweils letzten vier Wochen
R = ausloeser + 2
print(f"\nQualitätsalarm erstmals in Woche {ausloeser}.")
print(f"Retraining in Woche {R} mit den Wochen {R - 3}-{R}:")
X_neu = np.vstack([daten[w][0] for w in range(R - 3, R + 1)])
y_neu = np.concatenate([daten[w][1] for w in range(R - 3, R + 1)])
neu = LogisticRegression().fit(X_neu, y_neu)
for w in range(R + 1, 24, 2):
    X, y = daten[w]
    print(f"  Woche {w}: altes Modell={alt.score(X, y):.3f}  neues Modell={neu.score(X, y):.3f}")
spaet = LogisticRegression().fit(
    np.vstack([daten[w][0] for w in range(18, 22)]),
    np.concatenate([daten[w][1] for w in range(18, 22)]))
print("Zum Vergleich: Modell nur mit den Wochen 18-21 (Beziehung stabil):")
for w in (22, 23):
    print(f"  Woche {w}: {spaet.score(*daten[w]):.3f}")
json.dump({"woche": [t[0] for t in tabelle], "acc": [round(t[1], 4) for t in tabelle],
           "psi": [round(t[2], 4) for t in tabelle], "ausloeser": ausloeser, "schwelle": SCHWELLE},
          open("drift_verlauf.json", "w"))

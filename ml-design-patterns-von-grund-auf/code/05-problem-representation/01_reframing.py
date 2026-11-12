"""Pattern 5 Reframing: Regression mit zweigipfliger Verteilung als Klassifikation über Bins."""
import json
from pathlib import Path

import numpy as np
from sklearn.ensemble import GradientBoostingRegressor, RandomForestClassifier
from sklearn.linear_model import LinearRegression

rng = np.random.default_rng(11)
n = 20_000
km = rng.uniform(1, 10, n)                         # einziges bekanntes Feature: Entfernung
belegt = rng.random(n) < 0.5                       # Küche überlastet? Zur Vorhersagezeit unbekannt
minuten = 15 + 3 * km + np.where(belegt, 40, 0) + rng.normal(0, 4, n)
X = km.reshape(-1, 1)

# 1) Klassische Regression sagt den Mittelwert voraus
lin = LinearRegression().fit(X, minuten)
punkt = lin.predict([[5.0]])[0]
nahe = (km > 4.5) & (km < 5.5)
treffer = np.mean(np.abs(minuten[nahe] - punkt) <= 5)
print(f"Regression für 5 km: {punkt:.0f} min")
print(f"Anteil echter Lieferungen (4,5-5,5 km) innerhalb ±5 min um diese Vorhersage: {treffer:.1%}")

# 2) Quantil-Regression: ein Intervall statt eines Punktes
q = {a: GradientBoostingRegressor(loss="quantile", alpha=a, n_estimators=100, max_depth=2, random_state=0)
         .fit(X, minuten).predict([[5.0]])[0] for a in (0.1, 0.5, 0.9)}
print("Quantile (10 %, 50 %, 90 %):", {a: round(float(v)) for a, v in q.items()})

# 3) Reframing: Bins von 10 Minuten, Klassifikator liefert eine Verteilung
kanten = np.arange(20, 101, 10)
bins = np.digitize(minuten, kanten) - 1                 # 0 = unter 30 usw.
bins = np.clip(bins, 0, len(kanten) - 1)
clf = RandomForestClassifier(n_estimators=100, min_samples_leaf=100,
                             random_state=0).fit(X, bins)
p = clf.predict_proba([[5.0]])[0]
print("\nVerteilung für 5 km (Bin-Untergrenze: Wahrscheinlichkeit):")
for k, w in zip(clf.classes_, p):
    print(f"  ab {kanten[k]:>3} min: {w:5.1%}")

Path(__file__).with_name("reframing.json").write_text(json.dumps({
    "kanten": kanten.tolist(),
    "klassen": clf.classes_.tolist(),
    "p": [round(float(x), 4) for x in p],
    "wahr": [round(float(np.mean(bins[nahe] == k)), 4) for k in clf.classes_],
    "mittel": round(float(punkt), 1),
    "q10": round(float(q[0.1]), 1), "q90": round(float(q[0.9]), 1),
}))

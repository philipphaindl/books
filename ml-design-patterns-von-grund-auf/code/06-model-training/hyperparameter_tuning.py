"""Pattern 15: Grid Search gegen Random Search mit scikit-learn (SVC auf den Ziffern-Daten).

Ausführen:  uv run --with scikit-learn --with numpy python hyperparameter_tuning.py
"""
import json

import numpy as np
from scipy.stats import loguniform
from sklearn.datasets import load_digits
from sklearn.model_selection import GridSearchCV, RandomizedSearchCV, train_test_split
from sklearn.svm import SVC

X, y = load_digits(return_X_y=True)
X = X / 16.0
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.4, stratify=y, random_state=0)

C_GRID = [0.1, 1, 10, 100, 1000]
# 5 x 5 = 25 Versuche
GAMMA_GRID = [0.001, 0.01, 0.1, 1, 10]
grid = GridSearchCV(SVC(), {"C": C_GRID, "gamma": GAMMA_GRID}, cv=5)
grid.fit(X_tr, y_tr)

# gleicher Bereich
verteilung = {"C": loguniform(0.1, 1000), "gamma": loguniform(0.001, 10)}
# gleiches Budget: 25
zufall = RandomizedSearchCV(SVC(), verteilung, n_iter=25, cv=5, random_state=0)
zufall.fit(X_tr, y_tr)

print("Gleiches Budget: 25 Versuche mit je 5-facher Kreuzvalidierung (125 Läufe)")
print(f"  {'Verfahren':20s} {'CV-Wert':>8s} {'C':>7s} {'gamma':>7s} {'Test':>8s}")
for name, s in [("GridSearchCV", grid), ("RandomizedSearchCV", zufall)]:
    p = s.best_params_
    print(f"  {name:20s} {s.best_score_:8.4f} {p['C']:7.4g} {p['gamma']:7.4g} {s.score(X_te, y_te):8.4f}")
print(f"  verschiedene gamma-Werte ausprobiert: Grid={len(set(grid.cv_results_['param_gamma']))}, "
      f"Random={len(set(np.round(zufall.cv_results_['param_gamma'].data.astype(float), 12)))}")

# Wie stark streut Random Search mit anderen Seeds?
werte = []
for seed in range(10):
    z = RandomizedSearchCV(SVC(), verteilung, n_iter=25, cv=5, random_state=seed).fit(X_tr, y_tr)
    werte.append(z.best_score_)
print("\nRandom Search mit 10 verschiedenen Seeds, bester CV-Wert:")
print(f"  min={min(werte):.4f}  Mittel={np.mean(werte):.4f}  max={max(werte):.4f}  (Grid: {grid.best_score_:.4f})")

# Wie schlecht ist ein beliebiger Versuch? Verteilung aller Grid-Ergebnisse
alle = grid.cv_results_["mean_test_score"]
print(f"\n25 Grid-Ergebnisse: min={alle.min():.3f}  Median={np.median(alle):.3f}  max={alle.max():.3f}")
print(f"  davon unter 0.5: {int((alle < 0.5).sum())} Versuche")

# Punkte für das Diagramm (log10 gamma, log10 C, CV-Wert)
def punkte(s):
    return [[float(np.log10(float(g))), float(np.log10(float(c))), float(v)]
            for g, c, v in zip(s.cv_results_["param_gamma"], s.cv_results_["param_C"], s.cv_results_["mean_test_score"])]
json.dump({"grid": punkte(grid), "zufall": punkte(zufall)}, open("hyper_trials.json", "w"))

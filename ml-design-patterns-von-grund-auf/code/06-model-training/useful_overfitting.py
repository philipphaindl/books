"""Pattern 11: Wann Overfitting gewollt ist.

Teil A: ein Modell als Ersatz für eine deterministische Simulation (kein Rauschen).
Teil B: dasselbe Modell auf verrauschten Messdaten, wo Overfitting schadet.
Teil C: Zhang et al. (2017) im Kleinen: Zufallslabels lassen sich auswendig lernen.
"""
import warnings
import numpy as np
from sklearn.exceptions import ConvergenceWarning
from sklearn.neural_network import MLPRegressor
from sklearn.tree import DecisionTreeClassifier, DecisionTreeRegressor
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

warnings.filterwarnings("ignore", category=ConvergenceWarning)


def simulation(t, c):
    """Gedämpfte Schwingung: Auslenkung zur Zeit t bei Dämpfung c."""
    omega = np.sqrt(4.0 - c ** 2)
    return np.exp(-c * t) * np.cos(omega * t)


# --- Teil A: Eingaberaum ist ein Gitter, die Wahrheit ist exakt
t_raster = np.round(np.arange(0.0, 6.0001, 0.1), 2)       # 61 Zeitpunkte
c_raster = np.round(np.arange(0.2, 1.0001, 0.1), 2)       # 9 Dämpfungswerte
T, C = np.meshgrid(t_raster, c_raster)
X_gitter = np.column_stack([T.ravel(), C.ravel()])
y_gitter = simulation(X_gitter[:, 0], X_gitter[:, 1])

# Zwischenwerte, die nie im Training vorkamen (Mittelpunkte der Gitterzellen)
Tm, Cm = np.meshgrid(t_raster[:-1] + 0.05, c_raster[:-1] + 0.05)
X_zwischen = np.column_stack([Tm.ravel(), Cm.ravel()])
y_zwischen = simulation(X_zwischen[:, 0], X_zwischen[:, 1])


def rmse(modell, X, y):
    return float(np.sqrt(np.mean((modell.predict(X) - y) ** 2)))


print("Teil A: Surrogat für eine deterministische Simulation")
print(f"  Trainingsraum: {len(X_gitter)} Gitterpunkte, Zwischenwerte zum Test: {len(X_zwischen)}")
print(f"  {'Modell':30s} {'RMSE Gitter':>12s} {'RMSE Zwischenwerte':>20s}")
for name, alpha in [("MLP ohne Regularisierung", 0.0),
                    ("MLP, alpha=1 (regularisiert)", 1.0)]:
    m = MLPRegressor(hidden_layer_sizes=(32, 32), activation="tanh",
                     solver="lbfgs",
                     alpha=alpha, max_iter=3000, random_state=0)
    m.fit(X_gitter, y_gitter)
    print(f"  {name:30.30s} {rmse(m, X_gitter, y_gitter):12.5f} "
          f"{rmse(m, X_zwischen, y_zwischen):20.5f}")

# --- Teil B: gleiche Funktion, aber verrauschte Messungen an Zufallspunkten ---------
rng = np.random.default_rng(1)
X_roh = np.column_stack([rng.uniform(0, 6, 400), rng.uniform(0.2, 1.0, 400)])
# Messrauschen
y_roh = simulation(X_roh[:, 0], X_roh[:, 1]) + rng.normal(0, 0.3, 400)
X_tr, X_te, y_tr, y_te = train_test_split(X_roh, y_roh, test_size=0.5, random_state=0)
wahr_te = simulation(X_te[:, 0], X_te[:, 1])

print("\nTeil B: dieselbe Funktion, aber Messdaten mit Rauschen (sigma=0.3)")
print(f"  {'Modell':24s} {'RMSE Training':>14s} {'Test: Messung':>14s} {'Test: Wahrheit':>15s}")
for name, m in [("Baum ohne Tiefenlimit", DecisionTreeRegressor(random_state=0)),
                ("Baum, Tiefe 5", DecisionTreeRegressor(max_depth=5, random_state=0))]:
    m.fit(X_tr, y_tr)
    print(f"  {name:24s} {rmse(m, X_tr, y_tr):14.3f} {rmse(m, X_te, y_te):14.3f} {rmse(m, X_te, wahr_te):15.3f}")

# --- Teil C: Zufallslabels ------------------------------------------------------------
rng = np.random.default_rng(7)
X_z = rng.normal(size=(600, 20))
# Labels ohne jeden Zusammenhang zu X
y_z = rng.integers(0, 2, size=600)
Xz_tr, Xz_te, yz_tr, yz_te = train_test_split(X_z, y_z, test_size=0.5, random_state=0)
print("\nTeil C: Zufallslabels (zwischen X und y gibt es nichts zu lernen)")
for name, m in [("Entscheidungsbaum", DecisionTreeClassifier(random_state=0)),
                ("Random Forest (200 Bäume)", RandomForestClassifier(n_estimators=200, random_state=0))]:
    m.fit(Xz_tr, yz_tr)
    print(f"  {name:28s} Genauigkeit Training={m.score(Xz_tr, yz_tr):.2f}  Test={m.score(Xz_te, yz_te):.2f}")

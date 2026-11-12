"""Overfitting und Underfitting: Polynome verschiedenen Grades an verrauschten Daten."""
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import PolynomialFeatures

from common import speichere

rng = np.random.default_rng(3)


def wahrheit(x):
    return np.sin(2 * np.pi * x)


x_tr = np.linspace(0, 1, 15)  # 15 gleichmäßig verteilte Trainingspunkte
y_tr = wahrheit(x_tr) + rng.normal(0, 0.25, 15)
x_te = rng.uniform(0, 1, 500)
y_te = wahrheit(x_te) + rng.normal(0, 0.25, 500)

raster = np.linspace(0, 1, 101)


def skala(x):
    return (2 * x - 1)[:, None]

tabelle, kurven = [], {}
print(f"{'Grad':>4s} {'RMSE Training':>14s} {'RMSE Test':>10s}")
for grad in range(1, 15):
    # x wird auf [-1, 1] verschoben, das hält die Polynomrechnung numerisch stabil
    m = make_pipeline(PolynomialFeatures(grad), LinearRegression()).fit(skala(x_tr), y_tr)
    rmse_tr = mean_squared_error(y_tr, m.predict(skala(x_tr))) ** 0.5
    rmse_te = mean_squared_error(y_te, m.predict(skala(x_te))) ** 0.5
    tabelle.append([grad, rmse_tr, rmse_te])
    if grad in (1, 3, 14):
        kurven[str(grad)] = m.predict(skala(raster)).tolist()
    if grad in (1, 2, 3, 4, 6, 8, 10, 12, 13, 14):  # Auswahl für die Ausgabe
        print(f"{grad:4d} {rmse_tr:14.3f} {rmse_te:10.3f}")

speichere("overfitting", {
    "train": [[a, b] for a, b in zip(x_tr.tolist(), y_tr.tolist())],
    "raster": raster.tolist(),
    "wahrheit": wahrheit(raster).tolist(),
    "kurven": kurven,
    "fehler": tabelle,
})

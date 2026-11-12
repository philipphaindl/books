"""Pattern 28 Heuristic Benchmark: Modell gegen einfache Vergleichsmaßstäbe (simulierte Lieferdaten)."""
import numpy as np
import pandas as pd
from sklearn.dummy import DummyRegressor
from sklearn.ensemble import HistGradientBoostingRegressor
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import train_test_split

rng = np.random.default_rng(21)
n = 6000
df = pd.DataFrame({
    "distanz_km": rng.gamma(2.5, 2.0, n),
    "stosszeit": rng.integers(0, 2, n),
    "regen": (rng.random(n) < 0.2).astype(int),
    "etage": rng.integers(0, 8, n),
})
df["dauer_min"] = (6 + 2.4 * df.distanz_km * (1 + 0.5 * df.stosszeit) + 4 * df.regen
                   + 0.5 * df.etage + rng.normal(0, 3, n))
train, test = train_test_split(df, test_size=0.25, random_state=0)
merkmale = ["distanz_km", "stosszeit", "regen", "etage"]

ziel = train["dauer_min"]
mae = lambda vorhersage: mean_absolute_error(test["dauer_min"], vorhersage)
ergebnisse = {}

# 1) Konstante: Median der Trainingsdaten
dummy = DummyRegressor(strategy="median").fit(train[merkmale], ziel)
ergebnisse["Median (Konstante)"] = mae(dummy.predict(test[merkmale]))

# 2) Faustregel der Disposition, ohne Daten festgelegt: 10 min + 3 min/km
ergebnisse["Faustregel 10 + 3/km"] = mae(10 + 3 * test["distanz_km"])

# 3) Median je Distanzband (aus Trainingsdaten gelernt, aber erklärbar)
band = lambda d: pd.cut(d, [0, 2, 4, 6, 9, 100], labels=False)
median_je_band = ziel.groupby(band(train["distanz_km"])).median()
ergebnisse["Median je Distanzband"] = mae(band(test["distanz_km"]).map(median_je_band))

# 4) Modell
modell = HistGradientBoostingRegressor(random_state=0).fit(train[merkmale], ziel)
ergebnisse["Gradient Boosting"] = mae(modell.predict(test[merkmale]))

bester_maßstab = min(v for k, v in ergebnisse.items() if k != "Gradient Boosting")
for name, mae in ergebnisse.items():
    print(f"{name:24s} MAE {mae:5.2f} min")
besser = 100 * (1 - ergebnisse["Gradient Boosting"] / bester_maßstab)
print(f"Modell gegenüber bester Heuristik: {besser:.1f} % weniger Fehler")

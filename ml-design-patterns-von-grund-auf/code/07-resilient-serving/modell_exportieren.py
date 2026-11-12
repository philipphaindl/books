"""Pattern 16: Ein Modell trainieren und als Datei exportieren (Pipeline inklusive Feature Engineering).

Ausführen:  uv run --with scikit-learn --with pandas --with numpy python modell_exportieren.py
"""
import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import FunctionTransformer

from merkmale import abendspitze_ergaenzen


def lieferdaten(n, seed):
    """Synthetische Lieferdaten; die Zusammenhänge sind bewusst einfach und bekannt."""
    rng = np.random.default_rng(seed)
    df = pd.DataFrame({
        "distanz_km": rng.uniform(0.5, 15, n).round(1),
        "artikel": rng.integers(1, 12, n),
        "stunde": rng.integers(10, 23, n),
        "regen": rng.integers(0, 2, n),
    })
    spitze = df["stunde"].between(18, 20).astype(int)
    df["lieferzeit_min"] = (8 + 2.2 * df["distanz_km"] + 0.6 * df["artikel"] + 6 * df["regen"]
                            + 5 * spitze + rng.normal(0, 2.5, n))
    return df


if __name__ == "__main__":
    df = lieferdaten(5000, seed=42)
    X, y = df.drop(columns="lieferzeit_min"), df["lieferzeit_min"]
    X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=0)

    modell = Pipeline([
        ("merkmale", FunctionTransformer(abendspitze_ergaenzen)),
        ("regressor", GradientBoostingRegressor(random_state=0)),
    ]).fit(X_tr, y_tr)

    print(f"MAE auf Testdaten: {mean_absolute_error(y_te, modell.predict(X_te)):.2f} Minuten")
    joblib.dump(modell, "modell.joblib")
    import os
    print(f"exportiert nach modell.joblib ({os.path.getsize('modell.joblib') / 1024:.0f} KiB)")

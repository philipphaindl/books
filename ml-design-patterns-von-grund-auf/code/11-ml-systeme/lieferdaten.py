"""Gemeinsame Bausteine der Beispiele in Kapitel 11: synthetische Lieferdaten und ein Modell dazu.

Derselbe Lieferdienst wie in Pattern 16. Die Zusammenhänge sind bewusst einfach und bekannt,
damit man jedes Ergebnis nachprüfen kann.
"""
import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import FunctionTransformer

MERKMALE = ["distanz_km", "artikel", "stunde", "regen"]


def abendspitze_ergaenzen(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["abendspitze"] = df["stunde"].between(18, 20).astype(int)
    return df


def lieferdaten(n, seed, distanz_max=15.0, stunden_versatz=0):
    """Bestellungen mit Lieferzeit. `stunden_versatz` simuliert einen Fehler in der Datenerfassung:
    Die Lieferzeit entsteht aus der echten Uhrzeit, gespeichert wird die verschobene."""
    rng = np.random.default_rng(seed)
    df = pd.DataFrame({
        "distanz_km": rng.uniform(0.5, distanz_max, n).round(1),
        "artikel": rng.integers(1, 12, n),
        "stunde": rng.integers(10, 23, n),
        "regen": rng.integers(0, 2, n),
    })
    spitze = df["stunde"].between(18, 20).astype(int)
    df["lieferzeit_min"] = (8 + 2.2 * df["distanz_km"] + 0.6 * df["artikel"] + 6 * df["regen"]
                            + 5 * spitze + rng.normal(0, 2.5, n))
    df["stunde"] = (df["stunde"] + stunden_versatz) % 24
    return df


def modell_trainieren(df: pd.DataFrame, **parameter) -> Pipeline:
    return Pipeline([
        ("merkmale", FunctionTransformer(abendspitze_ergaenzen)),
        ("regressor", GradientBoostingRegressor(random_state=0, **parameter)),
    ]).fit(df[MERKMALE], df["lieferzeit_min"])

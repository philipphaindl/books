"""Tests für ein ML-System, geordnet nach den vier Kategorien des ML Test Score (Breck et al. 2017).

Ausführen:  uv run --with scikit-learn --with pandas --with numpy --with pytest \
            pytest -q --tb=line test_modell.py
"""
import joblib
import numpy as np
import pandas as pd
import pytest
from sklearn.metrics import mean_absolute_error

from lieferdaten import MERKMALE, lieferdaten, modell_trainieren


@pytest.fixture(scope="module")
def daten():
    return lieferdaten(5000, seed=42), lieferdaten(2000, seed=43)


@pytest.fixture(scope="module")
def modell(daten):
    return modell_trainieren(daten[0])


# --- 1. Daten und Merkmale -------------------------------------------------------------------
def test_daten_erwartungen(daten):
    train, _ = daten
    assert train[MERKMALE].notna().all().all()
    assert train["distanz_km"].between(0.1, 30).all()
    assert train["stunde"].between(0, 23).all()
    assert set(train["regen"]) <= {0, 1}


# --- 2. Modellentwicklung --------------------------------------------------------------------
def mae(modell, df):
    return mean_absolute_error(df["lieferzeit_min"], modell.predict(df[MERKMALE]))


def test_schlaegt_einfache_heuristik(modell, daten):
    """Ein einfacheres Verfahren ist nicht besser (Pattern 28)."""
    _, test = daten
    faustformel = 8 + 2.5 * test["distanz_km"]
    assert mae(modell, test) < 0.8 * mean_absolute_error(test["lieferzeit_min"], faustformel)


@pytest.mark.parametrize("name,maske", [
    ("Regen", lambda d: d["regen"] == 1),
    ("Abendspitze", lambda d: d["stunde"].between(18, 20)),
    ("weite Strecken", lambda d: d["distanz_km"] > 10),
])
def test_qualitaet_je_teilmenge(modell, daten, name, maske):
    """Die Gesamtkennzahl darf keine schlechte Teilgruppe verstecken."""
    _, test = daten
    assert mae(modell, test[maske(test)]) <= 1.5 * mae(modell, test)


def test_regen_wirkt_in_richtiger_richtung(modell, daten):
    """Fachliche Erwartung: Regen verlängert die Lieferung um etwa 6 Minuten."""
    _, test = daten
    trocken, nass = test[MERKMALE].assign(regen=0), test[MERKMALE].assign(regen=1)
    effekt = (modell.predict(nass) - modell.predict(trocken)).mean()
    assert 4 < effekt < 8


def test_extrapolation_distanz(modell):
    """Jeder Kilometer kostet Zeit, auch jenseits der Trainingsdaten."""
    beispiel = pd.DataFrame({"distanz_km": [15.0, 25.0], "artikel": 5,
                             "stunde": 12, "regen": 0})
    zeit_15, zeit_25 = modell.predict(beispiel)
    assert zeit_25 - zeit_15 > 10, (f"15 km: {zeit_15:.1f} min, "
                                    f"25 km: {zeit_25:.1f} min")


# --- 3. Infrastruktur ------------------------------------------------------------------------
def test_training_reproduzierbar(daten):
    a, b = modell_trainieren(daten[0]), modell_trainieren(daten[0])
    assert np.array_equal(a.predict(daten[1][MERKMALE]), b.predict(daten[1][MERKMALE]))


def test_serving_artefakt_gleich_trainiertem_modell(modell, daten, tmp_path):
    joblib.dump(modell, tmp_path / "modell.joblib")
    geladen = joblib.load(tmp_path / "modell.joblib")
    X = daten[1][MERKMALE]
    assert np.array_equal(modell.predict(X), geladen.predict(X))


# --- 4. Monitoring-nahe Modelleigenschaften --------------------------------------------------
def test_numerisch_stabil(modell):
    extrem = pd.DataFrame({"distanz_km": [0.1, 30.0], "artikel": [1, 50],
                           "stunde": [0, 23], "regen": [0, 1]})
    assert np.isfinite(modell.predict(extrem)).all()

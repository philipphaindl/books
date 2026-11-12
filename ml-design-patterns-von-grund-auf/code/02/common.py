"""Gemeinsame, deterministische Beispieldaten für Kapitel 2."""
import json
from pathlib import Path

import numpy as np
import pandas as pd

OUT = Path(__file__).parent / "out"
OUT.mkdir(exist_ok=True)


def speichere(name, daten):
    """Schreibt Werte für die Plots im Handbuch (JSON) neben die Skripte."""
    (OUT / f"{name}.json").write_text(json.dumps(daten))


def wohnungen(n=200, seed=42):
    """Mietwohnungen: Features Fläche, Zimmer, Baujahr; Label Kaltmiete in Euro."""
    rng = np.random.default_rng(seed)
    flaeche = rng.uniform(30, 120, n)
    zimmer = np.clip(np.round(flaeche / 28 + rng.normal(0, 0.5, n)), 1, 5).astype(int)
    baujahr = rng.integers(1950, 2021, n)
    miete = 180 + 8.2 * flaeche + 1.5 * (baujahr - 1950) + rng.normal(0, 70, n)
    return pd.DataFrame({
        "flaeche_m2": flaeche.round(1),
        "zimmer": zimmer,
        "baujahr": baujahr,
        "miete_eur": miete.round(0).astype(int),
    })


def maschinen(n=1000, seed=7):
    """Maschinen: Temperatur (°C), Schwingung (mm/s); Label ausfall = 1 binär.

    Regel dahinter: Ausfall bei Temperatur > 80 ODER Schwingung > 6, mit 5 % Etikettenrauschen.
    fehlerart: 0 kein Fehler, 1 Überhitzung, 2 Lagerschaden (für Mehrklassen-Beispiele).
    """
    rng = np.random.default_rng(seed)
    temp = rng.normal(70, 10, n)
    schw = rng.normal(4, 1.5, n)
    heiss, lager = temp > 80, schw > 6
    ausfall = heiss | lager
    flip = rng.random(n) < 0.05
    ausfall = np.where(flip, ~ausfall, ausfall)
    art = np.where(heiss, 1, np.where(lager, 2, 0))
    art = np.where(flip, np.where(art == 0, 1, 0), art)
    return pd.DataFrame({
        "temperatur_c": temp.round(1),
        "schwingung_mm_s": schw.round(2),
        "ausfall": ausfall.astype(int),
        "fehlerart": art,
    })

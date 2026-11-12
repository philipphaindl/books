"""Datenvalidierung mit pandera: ein Schema für die Bestelldaten, geprüft vor Training und Serving.

Ausführen:  uv run --with pandera --with pandas --with numpy --with scikit-learn python daten_validierung.py
"""
import pandera.pandas as pa
from pandera.typing import Series

from lieferdaten import lieferdaten


class Bestellungen(pa.DataFrameModel):
    """Der Vertrag zwischen Datenerfassung und Modell."""
    distanz_km: Series[float] = pa.Field(gt=0, le=30)
    artikel: Series[int] = pa.Field(ge=1, le=50)
    stunde: Series[int] = pa.Field(ge=0, le=23)
    regen: Series[int] = pa.Field(isin=[0, 1])

    class Config:
        strict = True  # unbekannte Spalten sind ein Fehler
        coerce = False  # keine stille Umwandlung

    @pa.dataframe_check
    def mittlere_distanz_plausibel(cls, df) -> bool:
        """Statistische Prüfung über den ganzen Batch, nicht über Zeilen."""
        return 3.0 <= df["distanz_km"].mean() <= 12.0


def pruefen(name, df):
    try:
        Bestellungen.validate(df, lazy=True)  # lazy: alle Verstöße sammeln
        print(f"{name}: {len(df)} Zeilen, gültig")
    except pa.errors.SchemaErrors as fehler:
        faelle = fehler.failure_cases[["column", "check", "failure_case"]]
        print(f"{name}: {len(faelle)} Verstöße")
        print(faelle.to_string(index=False))


X = lieferdaten(500, seed=11).drop(columns="lieferzeit_min")
pruefen("Batch A (sauber)", X)

kaputt = X.copy()
kaputt.loc[3, "distanz_km"] = -1.0        # Fehlwert aus dem Quellsystem
kaputt.loc[7, "stunde"] = 24              # Mitternacht als 24 statt 0
kaputt.loc[12, "regen"] = 2               # Kategorie, die es nicht geben darf
kaputt["kunde_id"] = 1                    # unerwartete neue Spalte
print()
pruefen("Batch B (kaputt)", kaputt)

meilen = X.assign(distanz_km=X["distanz_km"] / 1.609)  # Quellsystem liefert plötzlich Meilen
print()
pruefen("Batch C (Meilen statt km)", meilen)

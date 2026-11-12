"""Pattern 17: Einzelaufrufe gegen Batch-Vorhersage gegen gestücktes Scoring einer großen Datei.

Voraussetzung: modell_exportieren.py wurde ausgeführt. Zeiten hängen von der Maschine ab.
Ausführen:  uv run --with scikit-learn --with pandas --with numpy python batch_serving.py
"""
import tempfile
import time
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

import merkmale  # noqa: F401
from modell_exportieren import lieferdaten

modell = joblib.load("modell.joblib")
daten = lieferdaten(200_000, seed=7).drop(columns="lieferzeit_min")
daten.insert(0, "bestell_id", np.arange(len(daten)))
X = daten.drop(columns="bestell_id")

# a) Einzelaufrufe, wie ein Online-Service sie sieht
N_EINZEL = 1000
t = time.perf_counter()
for i in range(N_EINZEL):
    modell.predict(X.iloc[[i]])
einzel = N_EINZEL / (time.perf_counter() - t)

# b) alles auf einmal
t = time.perf_counter()
modell.predict(X)
alles = len(X) / (time.perf_counter() - t)

print("a/b) Durchsatz in Vorhersagen pro Sekunde")
print(f"  Einzelaufrufe ({N_EINZEL}):      {einzel:10,.0f}".replace(",", "."))
print(f"  eine Batch-Vorhersage ({len(X):,}): {alles:10,.0f}".replace(",", "."))
print(f"  Faktor: {alles / einzel:.0f}")

# c) Datei in Stücken lesen, bewerten, Ergebnis mit Schlüssel schreiben
ordner = Path(tempfile.mkdtemp())
eingabe, ausgabe = ordner / "bestellungen.csv", ordner / "vorhersagen.csv"
daten.to_csv(eingabe, index=False)
t = time.perf_counter()
erste = True
for stueck in pd.read_csv(eingabe, chunksize=50_000):
    vorhersage = modell.predict(stueck.drop(columns="bestell_id"))
    ergebnis = stueck[["bestell_id"]].assign(lieferzeit_min=vorhersage.round(1))
    ergebnis.to_csv(ausgabe, mode="w" if erste else "a",
                    header=erste, index=False)
    erste = False
dauer = time.perf_counter() - t
ergebnis = pd.read_csv(ausgabe)
zeilen = f"{len(ergebnis):,}".replace(",", ".")
print(f"\nc) {zeilen} Zeilen in 4 Stücken bewertet, {dauer:.1f} s; erste Zeilen:")
print(ergebnis.head(3).to_string(index=False))

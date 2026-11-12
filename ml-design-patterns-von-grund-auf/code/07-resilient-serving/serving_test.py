"""Pattern 16: Den Service ohne laufenden Server testen und Zustandslosigkeit prüfen.

Ausführen:  uv run --with scikit-learn --with pandas --with fastapi --with httpx python serving_test.py
"""
import random
import warnings
from pathlib import Path

import joblib
import pandas as pd
warnings.filterwarnings("ignore")  # Hinweis von starlette zu httpx, ohne Belang
from fastapi.testclient import TestClient  # noqa: E402

# merkmale muss importierbar sein, sonst kann joblib das Modell nicht laden
import merkmale  # noqa: F401
from serving_app import app

client = TestClient(app)
anfrage = {"distanz_km": 6.4, "artikel": 3, "stunde": 19, "regen": 1}

print("POST /predict", anfrage)
r = client.post("/predict", json=anfrage)
print("  ->", r.status_code, r.json())
r = client.post("/predict", json={**anfrage, "stunde": 31})
print("POST /predict mit stunde=31")
print("  ->", r.status_code, r.json()["detail"][0]["msg"])

# Zustandslosigkeit: drei unabhängige Replikate, Anfragen in beliebiger Reihenfolge und Verteilung
pfad = Path("modell.joblib")
replikate = [joblib.load(pfad) for _ in range(3)]
rng = random.Random(0)
anfragen = [{"distanz_km": round(rng.uniform(0.5, 15), 1), "artikel": rng.randint(1, 11),
             "stunde": rng.randint(10, 22), "regen": rng.randint(0, 1)} for _ in range(30)]


def antworten(reihenfolge, zuordnung):
    return {i: float(replikate[zuordnung(i)].predict(pd.DataFrame([anfragen[i]]))[0]) for i in reihenfolge}

# der Reihe nach, reihum verteilt
a = antworten(range(30), lambda i: i % 3)
b_reihenfolge = list(range(30)); rng.shuffle(b_reihenfolge)
# gemischt, zufällig verteilt
b = antworten(b_reihenfolge, lambda i: rng.randrange(3))
print("\n30 Anfragen, einmal reihum, einmal gemischt auf zufällige Kopien:")
print(f"identische Antworten = {a == b}")

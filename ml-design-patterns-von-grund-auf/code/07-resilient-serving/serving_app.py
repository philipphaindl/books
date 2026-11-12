"""Pattern 16: Zustandslose Serving-Funktion hinter REST.

Starten:  uv run --with scikit-learn --with pandas --with fastapi --with uvicorn uvicorn serving_app:app
(im Ordner dieser Datei; vorher modell_exportieren.py ausführen)
"""
from pathlib import Path

import joblib
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel, Field

# einmal beim Start, danach nur lesen
MODELL = joblib.load(Path(__file__).with_name("modell.joblib"))
app = FastAPI(title="Lieferzeit-Service")


class Anfrage(BaseModel):
    distanz_km: float = Field(gt=0, le=50)
    artikel: int = Field(ge=1, le=50)
    stunde: int = Field(ge=0, le=23)
    regen: int = Field(ge=0, le=1)


@app.post("/predict")
def predict(anfrage: Anfrage):
    X = pd.DataFrame([anfrage.model_dump()])
    return {"lieferzeit_min": round(float(MODELL.predict(X)[0]), 1)}

"""Kleiner Prognosedienst: Stateless Serving Function mit Model Versioning (Pattern 16 und 27).

Starten:  uv run --with fastapi --with uvicorn --with scikit-learn --with pandas --with numpy uvicorn dienst:app
Testen :  uv run --with fastapi --with httpx --with scikit-learn --with pandas --with numpy python test_dienst.py
"""
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Literal

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from shop import GERAETE, KAT
from store import aggregiere

MODELLE: dict = {}      # einmal beim Start gefüllt, danach nur gelesen
SCHNAPPSCHUSS: dict = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    ordner = Path(__file__).with_name("modelle")
    for datei in sorted(ordner.glob("v*.joblib")):
        MODELLE[datei.stem] = joblib.load(datei)
    s = np.load(ordner / "store.npz")
    SCHNAPPSCHUSS.update(ans=s["ans"], kauf=s["kauf"])
    yield
    MODELLE.clear()


app = FastAPI(title="Kaufprognose", lifespan=lifespan)


class Anfrage(BaseModel):
    produkt_id: int = Field(ge=0, description="aktuell angesehenes (drittes) Produkt")
    vorher_1: int = Field(ge=0)
    vorher_2: int = Field(ge=0)
    marke: str
    kategorie: Literal[tuple(KAT)]
    preis: float = Field(gt=0)
    titel: str
    geraet: Literal[tuple(GERAETE)]
    stunde: int = Field(ge=0, le=23)


class Antwort(BaseModel):
    version: str
    kaufwahrscheinlichkeit: float


def popularitaet(ids: list[int]) -> tuple[np.ndarray, np.ndarray]:
    """Nachschlagen im Schnappschuss; ein Produkt, das der Store nicht kennt, hat Popularität 0."""
    s = SCHNAPPSCHUSS["ans"]
    ok = [i < len(s) for i in ids]
    ans = np.array([[SCHNAPPSCHUSS["ans"][i] if o else 0 for i, o in zip(ids, ok)]])
    kauf = np.array([[SCHNAPPSCHUSS["kauf"][i] if o else 0 for i, o in zip(ids, ok)]])
    return ans, kauf


def paket(version: str) -> dict:
    if version not in MODELLE:
        raise HTTPException(404, f"unbekannte Version {version}; "
                                 f"vorhanden: {sorted(MODELLE)}")
    return MODELLE[version]


def vorhersage(version: str, a: Anfrage) -> float:
    """Reine Funktion von (Version, Anfrage): nichts wird gespeichert."""
    p = paket(version)
    ans, kauf = popularitaet([a.vorher_1, a.vorher_2, a.produkt_id])
    stand = {k: v[0] for k, v in aggregiere(ans, kauf).items()}
    zeile = pd.DataFrame([{**a.model_dump(), **stand}])
    x = p["merkmale"].transform(zeile)
    return float(p["klassifikator"].predict_proba(x)[0, 1])


@app.get("/{version}/info")
def info(version: str):
    p = paket(version)
    felder = ("version", "beschreibung", "trainingstage", "auc_test")
    return {k: p[k] for k in felder}


@app.post("/{version}/vorhersage", response_model=Antwort)
def vorhersage_route(version: str, anfrage: Anfrage):
    wahrscheinlichkeit = vorhersage(version, anfrage)
    return Antwort(version=version,
                   kaufwahrscheinlichkeit=round(wahrscheinlichkeit, 4))

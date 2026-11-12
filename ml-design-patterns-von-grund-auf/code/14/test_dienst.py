"""Testet den Dienst im Prozess (ohne Netzwerk) mit dem TestClient von FastAPI."""
import warnings

warnings.filterwarnings("ignore", message=".*httpx.*")   # Hinweis neuerer Starlette-Versionen zum TestClient
from fastapi.testclient import TestClient  # noqa: E402

from dienst import app
from gemeinsam import lade_zeilen

_, z, train = lade_zeilen("pit")
zeile = z[~train][z[~train].kauf == 1].iloc[3]     # eine Sitzung, die tatsächlich mit einem Kauf endete
anfrage = {k: (v.item() if hasattr(v, "item") else v) for k, v in zeile[
    ["produkt_id", "vorher_1", "vorher_2", "marke", "kategorie", "preis", "titel", "geraet", "stunde"]].items()}
neu = {**anfrage, "produkt_id": 99_999, "titel": "Trail Gelände Zelt Pro"}   # ID, die es im Training nie gab

with TestClient(app) as c:                        # der "with"-Block startet lifespan: Modelle werden geladen
    for v in ("v1", "v2"):
        i = c.get(f"/{v}/info").json()
        print(f"{v}: AUC {i['auc_test']}, {i['beschreibung']}")
    print()
    for name, body in (("bekanntes Produkt", anfrage), ("neues Produkt 99999", neu)):
        for v in ("v1", "v2"):
            r = c.post(f"/{v}/vorhersage", json=body)
            assert r.status_code == 200
            print(f"{name:<20} {v}: {r.json()['kaufwahrscheinlichkeit']:.4f}")

    # Zustandslosigkeit: gleiche Anfrage, gleiche Antwort, egal was dazwischen passiert ist
    erste = c.post("/v2/vorhersage", json=anfrage).json()
    c.post("/v1/vorhersage", json=neu)
    c.post("/v2/vorhersage", json={**anfrage, "geraet": "desktop", "stunde": 3})
    assert c.post("/v2/vorhersage", json=anfrage).json() == erste
    print("\ngleiche Anfrage nach anderen Anfragen: identische Antwort")

    r = c.post("/v3/vorhersage", json=anfrage)
    print("unbekannte Version  :", r.status_code, r.json()["detail"])
    r = c.post("/v2/vorhersage", json={**anfrage, "stunde": 25})
    print("ungültige Eingabe   :", r.status_code, r.json()["detail"][0]["msg"])

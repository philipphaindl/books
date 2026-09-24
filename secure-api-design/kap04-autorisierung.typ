#import "lib.typ": *

= Autorisierung: Objekte und Funktionen

Authentifizierung beantwortet "Wer bist du?", Autorisierung "Darfst du *das*?". Die OWASP-Liste führt zwei Autorisierungsfehler auf den Plätzen 1 und 5, weil sie so häufig und so folgenreich sind: Zugriff auf fremde *Objekte* (BOLA) und Zugriff auf fremde *Funktionen*.

== BOLA: Broken Object Level Authorization

Das Muster ist fast immer dasselbe: Ein Endpunkt bekommt die ID eines Objekts, prüft, dass jemand angemeldet ist, und liefert das Objekt aus, ohne zu prüfen, ob es diesem Jemand gehört.

#datei("app/main.py")[
```python
# UNSICHER: jeder angemeldete Benutzer kann jede Notiz lesen
@notizen.get("/{notiz_id}")
def lesen(notiz_id: UUID, benutzer: Benutzer = Depends(braucht_scope("notizen:lesen"))):
    notiz = db.execute(select(Notiz).where(Notiz.id == notiz_id)).scalar_one_or_none()
    if notiz is None:
        raise HTTPException(404)
    return notiz
```
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [Angreiferin \ #text(size: 6.5pt)[gültiges Token, \ eigenes Konto]], w: 2.6, h: 1.2, bg: rgb("#FBEAEA"), col: c-red)
    kasten((6.5, 0), [API \ #text(size: 6.5pt)[prüft nur: angemeldet?]], w: 3.0, h: 1.2, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((13.0, 0), [Notiz von Bob \ #text(size: 6.5pt)[`id = 7f3e…`]], w: 2.6, h: 1.2, bg: rgb("#FFF8E6"), col: c-yellow)
    pfeil((1.35, 0.2), (4.95, 0.2), label: "GET /notizen/7f3e…", loff: (0, 0.22), color: c-red)
    pfeil((8.05, 0.2), (11.65, 0.2), label: "SELECT ... WHERE id=", loff: (0, 0.22))
    pfeil((4.95, -0.3), (1.35, -0.3), label: "200 + fremde Daten", loff: (0, -0.24), color: c-red)
  }),
  caption: [BOLA: Die Anmeldung ist korrekt, die Frage nach dem Besitz fehlt.],
)

Die richtige Lösung ist, die Besitzprüfung *in die Abfrage selbst* zu legen. Dann kann es gar nicht passieren, dass ein fremdes Objekt überhaupt geladen wird:

#datei("app/main.py")[
```python
@notizen.get("/{notiz_id}", response_model=NotizAusgabe)
def lesen(notiz_id: UUID, benutzer: Benutzer = Depends(braucht_scope("notizen:lesen"))):
    notiz = db.execute(
        select(Notiz).where(Notiz.id == notiz_id, Notiz.besitzer_id == benutzer.id)
    ).scalar_one_or_none()
    if notiz is None:
        raise HTTPException(404, "Nicht gefunden")   # auch bei fremden Notizen: 404
    return notiz
```
]

Drei Punkte dazu:

- *404 statt 403* für fremde Objekte. Ein 403 verrät, dass es das Objekt gibt. Das hilft beim Ausspähen, etwa von E-Mail-Adressen oder Kundennummern.
- *Zufällige IDs (UUIDs) sind kein Schutz.* Sie erschweren das Raten, aber IDs gelangen über geteilte Links, Logs, Referer-Header oder andere Endpunkte nach außen. Die Prüfung muss trotzdem stattfinden.
- *Jeder Zugriffsweg braucht die Prüfung:* Lesen, Ändern, Löschen, Exportieren, Anhänge herunterladen, Unterobjekte (`/notizen/{id}/kommentare`). Besonders leicht vergessen werden Massenoperationen und Suchendpunkte.

=== Autorisierung zentralisieren

Wenn Notizen geteilt werden können, wird die Regel komplexer: lesen darf der Besitzer, wer eine Freigabe hat, und ein Administrator. Solche Regeln gehören an *eine* Stelle, nicht verstreut in jeden Endpunkt:

#datei("app/rechte.py")[
```python
from sqlalchemy import or_, select

def sichtbare_notizen(benutzer: Benutzer):
    """Basisabfrage: alle Notizen, die dieser Benutzer lesen darf."""
    abfrage = select(Notiz)
    if "notizen-admins" in benutzer.gruppen:
        return abfrage
    freigegeben = select(Freigabe.notiz_id).where(Freigabe.benutzer_id == benutzer.id)
    return abfrage.where(or_(Notiz.besitzer_id == benutzer.id, Notiz.id.in_(freigegeben)))

def darf_aendern(benutzer: Benutzer, notiz: Notiz) -> bool:
    return notiz.besitzer_id == benutzer.id
```
]

Jeder Endpunkt beginnt dann mit `sichtbare_notizen(benutzer)` und schränkt weiter ein. Eine Änderung der Regel wirkt überall gleichzeitig.

#tipp[Als zusätzliche Verteidigungslinie kann PostgreSQL die Besitzregel selbst durchsetzen: Mit _Row Level Security_ (`ALTER TABLE notizen ENABLE ROW LEVEL SECURITY` und einer Policy auf eine Sitzungsvariable mit der Benutzer-ID) liefert die Datenbank fremde Zeilen gar nicht erst aus, auch wenn im Code eine Prüfung fehlt. Der Aufwand lohnt sich bei mandantenfähigen Anwendungen mit vielen Endpunkten.]

== Autorisierung auf Funktionsebene

Der zweite Klassiker: Administrative Funktionen sind nur in der Oberfläche versteckt, die API prüft aber nicht, wer sie aufruft. Wer die Endpunkte kennt (etwa aus der öffentlichen OpenAPI-Dokumentation oder dem JavaScript der Web-App), ruft sie einfach direkt auf.

#datei("app/admin.py")[
```python
admin = APIRouter(
    prefix="/admin",
    dependencies=[Depends(braucht_gruppe("notizen-admins"))],   # für ALLE Endpunkte darunter
)

@admin.delete("/benutzer/{benutzer_id}/notizen")
def alle_loeschen(benutzer_id: str): ...
```
]

Die Regel ist dieselbe wie bei der Anmeldung: Rechte auf Router-Ebene vergeben, damit neue Endpunkte automatisch geschützt sind. Achtung auch bei HTTP-Methoden: Ist `GET /notizen/{id}` korrekt geschützt, heißt das nichts über `PUT`, `PATCH` und `DELETE` auf derselben Adresse.

== Autorisierung testen

Autorisierungsfehler findet kein Scanner, aber ein einfacher Test mit zwei Benutzern findet fast alle. FastAPI erlaubt, die Anmelde-Abhängigkeit im Test durch feste Benutzer zu ersetzen:

#datei("tests/test_rechte.py")[
```python
from contextlib import contextmanager
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.auth import Benutzer, aktueller_benutzer

ALICE = Benutzer(id="alice", scopes=frozenset({"notizen:lesen", "notizen:schreiben"}), gruppen=frozenset())
BOB   = Benutzer(id="bob",   scopes=frozenset({"notizen:lesen", "notizen:schreiben"}), gruppen=frozenset())

@pytest.fixture
def client():
    with TestClient(app) as testclient:
        yield testclient

@contextmanager
def als(benutzer: Benutzer):
    vorher = app.dependency_overrides.get(aktueller_benutzer)
    app.dependency_overrides[aktueller_benutzer] = lambda: benutzer
    try:
        yield
    finally:
        if vorher is None:
            app.dependency_overrides.pop(aktueller_benutzer, None)
        else:
            app.dependency_overrides[aktueller_benutzer] = vorher

def test_bob_sieht_notiz_von_alice_nicht(client):
    with als(ALICE):
        notiz_id = client.post("/notizen", json={"titel": "privat", "text": "..."}).json()["id"]
    with als(BOB):
        antwort = client.get(f"/notizen/{notiz_id}")
    assert antwort.status_code == 404

@pytest.mark.parametrize("methode", ["put", "patch", "delete"])
def test_bob_kann_notiz_von_alice_nicht_aendern(client, methode):
    with als(ALICE):
        notiz_id = client.post("/notizen", json={"titel": "x", "text": "y"}).json()["id"]
    with als(BOB):
        antwort = client.request(methode.upper(), f"/notizen/{notiz_id}",
                                 json={"titel": "gehackt"})
    assert antwort.status_code == 404
```
]

Der Override wird nach jedem Block sicher zurückgesetzt; sonst beeinflusst ein Test den nächsten. Ein `405` wäre hier kein Erfolg: Er würde nur beweisen, dass die Methode fehlt, nicht dass ihre Objektberechtigung stimmt. Für jeden real vorhandenen Lese-, Änderungs-, Lösch-, Export- und Unterobjekt-Endpunkt gehört ein exakter "fremder Benutzer"-Test zur Definition of Done.

#merke[In mandantenfähigen Systemen gehört neben der Besitzer-ID immer auch die Mandanten-ID in jede Abfrage. Bei PostgreSQL-RLS werden Mandant und Benutzer transaktionslokal gesetzt; der Anwendungs-DB-Account darf die Policy weder umgehen noch Tabellen besitzen. RLS ergänzt die Anwendungstests, ersetzt sie aber nicht.]

#import "lib.typ": *

= Ressourcen und Geschäftsabläufe schützen

Eine API ohne Grenzen lädt zu zwei Arten von Missbrauch ein: Sie lässt sich mit Anfragen überlasten (OWASP API4, _Unrestricted Resource Consumption_), und legitime Abläufe lassen sich automatisiert ausnutzen, etwa massenhaftes Registrieren, Durchprobieren von Gutscheincodes oder das Leerkaufen limitierter Angebote (API6, _Unrestricted Access to Sensitive Business Flows_).

== Grenzen auf allen Ebenen

#table(columns: (auto, 1fr),
  [Grenze], [Umsetzung],
  [Größe einer Anfrage], [am Reverse Proxy (Caddy: `request_body { max_size 1MB }`) und in den Pydantic-Modellen],
  [Anzahl der Ergebnisse], [Pflicht-Paginierung mit Höchstwert: `limit: int = Query(20, ge=1, le=100)`],
  [Anfragen pro Zeit], [Rate Limiting pro Benutzer bzw. Client, zusätzlich pro IP für nicht angemeldete Endpunkte],
  [Laufzeit], [Timeouts für Datenbankabfragen (`statement_timeout` in PostgreSQL) und ausgehende HTTP-Aufrufe],
  [Teure Operationen], [Exporte, Berichte, Suchen mit Platzhaltern: eigene, strengere Limits oder asynchron als Job],
  [Speicher und CPU], [Container-Limits (Docker-Handbuch, Kapitel 12)],
)

== Rate Limiting

Rate Limiting begrenzt, wie viele Anfragen ein Aufrufer in einem Zeitfenster stellen darf. Überschreitet er das Limit, antwortet die API mit `429 Too Many Requests` und dem Header `Retry-After`. Für FastAPI eignet sich die Bibliothek `slowapi`, die ihre Zähler bei mehreren API-Instanzen in Redis ablegt:

#datei("app/limits.py")[
```python
from fastapi import Request
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

def schluessel(request: Request) -> str:
    # angemeldete Anfragen pro Benutzer zählen, sonst pro IP
    benutzer = getattr(request.state, "benutzer_id", None)
    return f"u:{benutzer}" if benutzer else f"ip:{request.client.host}"

limiter = Limiter(key_func=schluessel, storage_uri="redis://redis:6379/0",
                  default_limits=["300/minute"])
```
]

#datei("app/main.py")[
```python
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@notizen.post("/export")
@limiter.limit("5/hour")                 # teure Operation: eigenes, strenges Limit
def export(request: Request, benutzer: Benutzer = Depends(braucht_scope("notizen:lesen"))):
    ...
```
]

#achtung[Hinter einem Reverse Proxy sieht die Anwendung als `request.client.host` die Adresse des Proxys, alle Clients teilen sich dann ein Limit. Der Server muss den Headern des Proxys (`X-Forwarded-For`) vertrauen, aber *nur* denen des Proxys: `fastapi run` bzw. Uvicorn übernehmen sie nur von Adressen, die in `FORWARDED_ALLOW_IPS` stehen. Dort gehört die Adresse bzw. das Netz des Proxys hinein, niemals `*` bei direkt erreichbaren Servern, sonst kann jeder Client seine IP frei wählen.]

Damit der Schlüssel pro Benutzer funktioniert, erweitert man `aktueller_benutzer` aus Kapitel 3 um den Parameter `request: Request` und setzt dort `request.state.benutzer_id = claims["sub"]`.

Ein zweites, grobes Limit am Reverse Proxy fängt Lastspitzen ab, bevor sie Python erreichen. Für Anmelde- und Registrierungsabläufe übernimmt Authentik das Begrenzen von Fehlversuchen selbst.

== Idempotenz für kritische Abläufe

Netzwerke sind unzuverlässig: Ein Client schickt eine Bestellung, die Antwort geht verloren, der Client wiederholt die Anfrage. Ohne Vorkehrung entsteht die Bestellung zweimal. Für solche Abläufe schickt der Client einen eindeutigen Schlüssel im Header `Idempotency-Key` mit. Die API merkt sich Schlüssel und Antwort und liefert bei einer Wiederholung die gespeicherte Antwort, statt erneut auszuführen:

#datei("app/idempotenz.py (Skizze)")[
```python
from sqlalchemy.dialects.postgresql import insert

@app.post("/bestellungen", status_code=201)
def bestellen(daten: BestellungNeu, idempotency_key: UUID = Header(),
              benutzer: Benutzer = Depends(braucht_scope("bestellen"))):
    fingerabdruck = hashlib.sha256(daten.model_dump_json().encode()).hexdigest()
    with db.begin():
        neu = db.execute(
            insert(Idempotenz).values(
                benutzer_id=benutzer.id, schluessel=idempotency_key,
                fingerabdruck=fingerabdruck, status="laeuft",
            ).on_conflict_do_nothing(
                index_elements=["benutzer_id", "schluessel"]
            ).returning(Idempotenz.id)
        ).scalar_one_or_none()
        if neu is None:
            eintrag = idempotenz_lesen(benutzer.id, idempotency_key, for_update=True)
            if eintrag.fingerabdruck != fingerabdruck:
                raise HTTPException(409, "Schlüssel gehört zu einer anderen Anfrage")
            if eintrag.status == "fertig":
                return gespeicherte_antwort(eintrag)  # Statuscode, Header, Body
            raise HTTPException(409, "Anfrage wird bereits verarbeitet",
                                headers={"Retry-After": "2"})
        antwort = bestellung_anlegen(daten, benutzer)
        idempotenz_abschliessen(neu, antwort)
        return antwort
```
]

Die Datenbank erzwingt einen Unique-Constraint auf `(benutzer_id, schluessel)`. Die atomare Reservierung verhindert, dass zwei gleichzeitige Requests beide die Wirkung ausführen – ein vorheriges `SELECT` mit anschließendem `INSERT` würde das nicht leisten. Fingerabdruck, Geschäftswirkung und gespeicherte Antwort (Statuscode, relevante Header und Body) liegen in derselben Transaktion; externe Wirkungen werden über eine transaktionale Outbox angestoßen. Abgelaufene Einträge werden erst nach einer dokumentierten Wiederholungsfrist gelöscht.

== Missbrauch legitimer Abläufe

Gegen automatisierten Missbrauch von Geschäftsabläufen hilft kein einzelnes technisches Mittel. Zuerst gilt es, die gefährdeten Abläufe zu identifizieren: Was passiert, wenn jemand diesen Endpunkt 10.000-mal pro Stunde aufruft? Typische Gegenmaßnahmen sind strengere Limits pro Konto und Zeitraum (etwa höchstens drei Freigabe-Einladungen pro Minute), Verzögerungen nach Fehlversuchen, zusätzliche Bestätigung per E-Mail oder zweitem Faktor bei kritischen Aktionen und das Überwachen auffälliger Muster in den Logs (Kapitel 7).

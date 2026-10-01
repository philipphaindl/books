#import "lib.typ": *

= Ressourcen und Geschäftsabläufe schützen

Eine API ohne Grenzen lädt zu zwei Arten von Missbrauch ein: Sie lässt sich mit Anfragen überlasten (OWASP API4, _Unrestricted Resource Consumption_) @api-security-owasp-org-editions-2023-en-0xa4-unrestricted-resource-consumption, und legitime Abläufe lassen sich automatisiert ausnutzen, etwa massenhaftes Registrieren, Durchprobieren von Gutscheincodes oder das Leerkaufen limitierter Angebote (API6, _Unrestricted Access to Sensitive Business Flows_) @api-security-owasp-org-editions-2023-en-0xa6-unrestricted-access-to-sensitive-business-flows.

== Grenzen auf allen Ebenen

#table(columns: (auto, 1fr),
  [Grenze], [Umsetzung],
  [Größe einer Anfrage], [am Reverse Proxy (Caddy: `request_body { max_size 1MB }`) und in den Pydantic-Modellen @caddyserver-com-docs-caddyfile-directives-request-body @api-security-owasp-org-editions-2023-en-0xa4-unrestricted-resource-consumption],
  [Anzahl der Ergebnisse], [Pflicht-Paginierung mit Höchstwert: `limit: int = Query(20, ge=1, le=100)` @api-security-owasp-org-editions-2023-en-0xa4-unrestricted-resource-consumption @fastapi-tiangolo-com-tutorial-path-params-numeric-validations],
  [Anfragen pro Zeit], [Rate Limiting pro Benutzer bzw. Client, zusätzlich pro IP für nicht angemeldete Endpunkte @api-security-owasp-org-editions-2023-en-0xa4-unrestricted-resource-consumption],
  [Laufzeit], [Timeouts für Datenbankabfragen (`statement_timeout` in PostgreSQL) und ausgehende HTTP-Aufrufe @postgresql-org-docs-current-runtime-config-client-html],
  [Teure Operationen], [Exporte, Berichte, Suchen mit Platzhaltern: eigene, strengere Limits oder asynchron als Job @api-security-owasp-org-editions-2023-en-0xa4-unrestricted-resource-consumption],
  [Speicher und CPU], [Container-Limits (Docker-Handbuch, Kapitel 12) @api-security-owasp-org-editions-2023-en-0xa4-unrestricted-resource-consumption],
)

== Rate Limiting

Rate Limiting begrenzt, wie viele Anfragen ein Aufrufer in einem Zeitfenster stellen darf. Überschreitet er das Limit, antwortet die API mit `429 Too Many Requests` @rfc6585 und kann im Header `Retry-After` angeben, wann ein neuer Versuch sinnvoll ist @rfc9110. Für FastAPI eignet sich die Bibliothek `slowapi`, die ihre Zähler bei mehreren API-Instanzen in Redis ablegt @slowapi-readthedocs-io-en-latest. Damit sie `Retry-After` mitschickt, wird der Limiter mit `headers_enabled=True` angelegt @slowapi-readthedocs-io-en-latest-api:

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
                  default_limits=["300/minute"], headers_enabled=True)
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

#achtung[Hinter einem Reverse Proxy sieht die Anwendung als `request.client.host` die Adresse des Proxys, alle Clients teilen sich dann ein Limit @developer-mozilla-org-en-us-docs-web-http-reference-headers-x-forwarded-for. Der Server muss den Headern des Proxys (`X-Forwarded-For`) vertrauen, aber *nur* denen des Proxys: `fastapi run` bzw. Uvicorn übernehmen sie nur von Adressen, die in `FORWARDED_ALLOW_IPS` stehen (Standard: nur `127.0.0.1` und `::1`) @uvicorn-dev-settings @fastapi-tiangolo-com-advanced-behind-a-proxy. Dort gehört die Adresse bzw. das Netz des Proxys hinein, niemals `*` bei direkt erreichbaren Servern, sonst kann jeder Client seine IP frei wählen @developer-mozilla-org-en-us-docs-web-http-reference-headers-x-forwarded-for.]

Damit der Schlüssel pro Benutzer funktioniert, erweitert man `aktueller_benutzer` aus Kapitel 3 um den Parameter `request: Request` und setzt dort `request.state.benutzer_id = claims["sub"]`.

Ein zweites, grobes Limit am Reverse Proxy fängt Lastspitzen ab, bevor sie Python erreichen. Fehlversuche bei der Anmeldung bewertet Authentik selbst: Eine Reputation-Policy zählt sie pro IP-Adresse oder Benutzername und kann bei geringem Vertrauen zusätzliche Prüfungen wie ein CAPTCHA verlangen, sie muss dazu aber in den Anmelde-Flows eingerichtet werden @docs-goauthentik-io-customize-policies-types-reputation.

== Idempotenz für kritische Abläufe

Netzwerke sind unzuverlässig: Ein Client schickt eine Bestellung, die Antwort geht verloren, der Client wiederholt die Anfrage. Ohne Vorkehrung entsteht die Bestellung zweimal. Für solche Abläufe schickt der Client einen eindeutigen Schlüssel im Header `Idempotency-Key` mit (ein Entwurf der IETF, kein verabschiedeter Standard) @datatracker-ietf-org-doc-draft-ietf-httpapi-idempotency-key-header. Die API merkt sich Schlüssel und Antwort und liefert bei einer Wiederholung die gespeicherte Antwort, statt erneut auszuführen:

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
                raise HTTPException(422, "Schlüssel gehört zu einer anderen Anfrage")
            if eintrag.status == "fertig":
                return gespeicherte_antwort(eintrag)  # Statuscode, Header, Body
            raise HTTPException(409, "Anfrage wird bereits verarbeitet",
                                headers={"Retry-After": "2"})
        antwort = bestellung_anlegen(daten, benutzer)
        idempotenz_abschliessen(neu, antwort)
        return antwort
```
]

Die Datenbank erzwingt einen Unique-Constraint auf `(benutzer_id, schluessel)`. Die atomare Reservierung verhindert, dass zwei gleichzeitige Requests beide die Wirkung ausführen @postgresql-org-docs-current-sql-insert-html @postgresql-org-docs-current-index-unique-checks-html – ein vorheriges `SELECT` mit anschließendem `INSERT` würde das nicht leisten. Fingerabdruck, Geschäftswirkung und gespeicherte Antwort (Statuscode, relevante Header und Body) liegen in derselben Transaktion; externe Wirkungen werden über eine transaktionale Outbox angestoßen @microservices-io-patterns-data-transactional-outbox-html. Abgelaufene Einträge werden erst nach einer dokumentierten Wiederholungsfrist gelöscht. Nach dem Entwurf antwortet der Server auf einen Schlüssel, der mit anderer Nutzlast wiederverwendet wird, mit 422 und auf eine noch laufende Anfrage mit 409 @datatracker-ietf-org-doc-draft-ietf-httpapi-idempotency-key-header.

== Missbrauch legitimer Abläufe

Gegen automatisierten Missbrauch von Geschäftsabläufen hilft kein einzelnes technisches Mittel. Zuerst gilt es, die gefährdeten Abläufe zu identifizieren @api-security-owasp-org-editions-2023-en-0xa6-unrestricted-access-to-sensitive-business-flows: Was passiert, wenn jemand diesen Endpunkt 10.000-mal pro Stunde aufruft? Typische Gegenmaßnahmen sind strengere Limits pro Konto und Zeitraum (etwa höchstens drei Freigabe-Einladungen pro Minute), Verzögerungen nach Fehlversuchen, zusätzliche Bestätigung per E-Mail oder zweitem Faktor bei kritischen Aktionen und das Überwachen auffälliger Muster in den Logs (Kapitel 7).

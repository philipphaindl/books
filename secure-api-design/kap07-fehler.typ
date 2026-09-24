#import "lib.typ": *

= Fehler, Logging und Datensparsamkeit

Fehlermeldungen und Logs sind für Entwickler gemacht, werden aber leicht zu einer Informationsquelle für Angreifer oder zu einem Datenschutzproblem. Das Ziel: Der Client erfährt genug, um sinnvoll zu reagieren, aber nichts über Interna. Die Logs enthalten genug, um Vorfälle aufzuklären, aber keine Geheimnisse und so wenig personenbezogene Daten wie möglich.

== Einheitliche Fehler nach RFC 9457

RFC 9457 (_Problem Details for HTTP APIs_, Nachfolger von RFC 7807) definiert ein einheitliches JSON-Format für Fehler mit dem Medientyp `application/problem+json`:

```json
{
  "type": "https://api.example.com/probleme/nicht-gefunden",
  "title": "Nicht gefunden",
  "status": 404,
  "detail": "Die angeforderte Notiz existiert nicht.",
  "instance": "/notizen/7f3e0c1a-...",
  "request_id": "b3a1f2e4"
}
```

#datei("app/fehler.py")[
```python
import logging, uuid
from http import HTTPStatus
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

log = logging.getLogger("notizen")

def problem(status: int, titel: str, request: Request, detail: str | None = None,
            headers: dict[str, str] | None = None):
    return JSONResponse(
        status_code=status,
        media_type="application/problem+json",
        content={"title": titel, "status": status, "detail": detail,
                 "instance": request.url.path, "request_id": request.state.request_id},
        headers=headers,
    )

def registrieren(app: FastAPI) -> None:
    @app.exception_handler(StarletteHTTPException)
    async def http_fehler(request: Request, exc: StarletteHTTPException):
        titel = next((s.phrase for s in HTTPStatus if s.value == exc.status_code),
                     "HTTP-Fehler")
        detail = exc.detail if isinstance(exc.detail, str) else None
        return problem(exc.status_code, titel, request, detail, exc.headers)

    @app.exception_handler(RequestValidationError)
    async def validierung(request: Request, exc: RequestValidationError):
        felder = [".".join(map(str, e["loc"])) for e in exc.errors()]
        return problem(422, "Ungültige Eingabe", request, f"Betroffene Felder: {', '.join(felder)}")

    @app.exception_handler(Exception)
    async def unerwartet(request: Request, exc: Exception):
        log.exception("Unerwarteter Fehler", extra={"request_id": request.state.request_id})
        return problem(500, "Interner Fehler", request)       # kein Stacktrace an den Client
```
]

Der Validierungs-Handler gibt nur Feldnamen zurück, nicht die eingegebenen Werte. Der HTTP-Handler übernimmt `exc.headers`; sonst ginge etwa das für 401 erforderliche `WWW-Authenticate` verloren. Der generische Titel kommt aus dem Statuscode, während Details nur aus bewusst erzeugten Anwendungsfehlern stammen. Der letzte Handler fängt Unerwartetes: Der Client bekommt nur die `request_id`, mit der sich der vollständige Fehler im Log finden lässt.

== Eine Request-ID für jede Anfrage

#datei("app/main.py")[
```python
@app.middleware("http")
async def request_id(request: Request, call_next):
    request.state.request_id = uuid.uuid4().hex[:12]
    antwort = await call_next(request)
    antwort.headers["X-Request-ID"] = request.state.request_id
    return antwort
```
]

Die ID erscheint in jeder Logzeile und in jeder Fehlerantwort. Meldet ein Benutzer einen Fehler, genügt die ID, um den Ablauf nachzuvollziehen, ohne dass er Details beschreiben muss.

== Was ins Log gehört und was nicht

#table(columns: (1fr, 1fr),
  [Loggen], [Nie loggen],
  [Zeitpunkt, Request-ID, Methode, Pfad (ohne Query-Werte mit Geheimnissen), Statuscode, Dauer], [Access-Tokens, Refresh-Tokens, Passwörter, API-Schlüssel, Client-Secrets],
  [Benutzer-ID (`sub`), nicht Name oder E-Mail], [vollständige Request- und Response-Bodies],
  [Sicherheitsereignisse: 401, 403, 429, abgelehnte Tokens, Rechteänderungen], [Gesundheits-, Finanz- oder andere besonders schützenswerte Inhalte],
  [Ursache unerwarteter Fehler mit Stacktrace (nur serverseitig)], [den `Authorization`-Header, auch nicht "zur Fehlersuche"],
)

Logs werden strukturiert (JSON) mit UTC-Zeit geschrieben, damit sie sich durchsuchen und auswerten lassen. Ein eigenes _Audit-Log_ für sicherheitsrelevante Aktionen (Freigabe erteilt, Notiz gelöscht, Rolle geändert) mit Akteur, Aktion, Objekt, Ergebnis und Zeitpunkt ist bei Vorfällen oft die einzige Möglichkeit festzustellen, was geschehen ist. Es ist zugriffsbeschränkt, gegen nachträgliche Änderung geschützt und hat eine festgelegte Aufbewahrungs- und Löschfrist. Für verteilte Systeme ergänzt W3C Trace Context beziehungsweise OpenTelemetry die lokale Request-ID; externe IDs werden validiert und nie blind als Logstruktur übernommen.

#merke[*Datensparsamkeit* ist die wirksamste Datenschutzmaßnahme: Was nicht gespeichert wird, kann weder abfließen noch muss es gelöscht, beauskunftet oder geschützt werden. Für jede Spalte, jedes Log-Feld und jedes Feld in einer Antwort lohnt die Frage, ob es wirklich gebraucht wird. Pseudonyme IDs aus dem IdP (`sub`) statt E-Mail-Adressen in der eigenen Datenbank sind ein einfacher erster Schritt.]

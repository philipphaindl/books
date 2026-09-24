#import "lib.typ": *

= Inventar, Versionen und Lebenszyklus

OWASP API9, _Improper Inventory Management_, beschreibt ein organisatorisches Risiko: APIs, von denen niemand mehr weiß. Eine alte Version `/v1`, die noch läuft, obwohl alle Clients auf `/v2` umgestellt sind und die Sicherheitskorrekturen nur in `/v2` eingebaut wurden. Ein Test-Endpunkt aus der Entwicklung. Eine Staging-Instanz mit Kopien echter Daten, aber schwächerem Schutz.

== Die OpenAPI-Beschreibung als Inventar

FastAPI erzeugt aus dem Code eine vollständige OpenAPI-Beschreibung. Auch wenn `/openapi.json` in Produktion abgeschaltet ist (Kapitel 8), lässt sie sich im Build erzeugen und versionieren:

```bash
uv run python -c "import json; from app.main import app; print(json.dumps(app.openapi(), indent=2))" \
  > openapi.json
git diff -- openapi.json          # welche Endpunkte und Schemas änderten sich?
```

Liegt `openapi.json` im Repository, zeigt jeder Pull Request, welche Endpunkte, Parameter und Felder er verändert. Ein OpenAPI-Diff-Werkzeug prüft zusätzlich automatisiert auf brechende Änderungen; ein reines `--stat` zeigt nur Zeilenzahlen. Das macht Änderungen an der Angriffsfläche im Review sichtbar.

== Versionieren und abkündigen

#table(columns: (auto, 1fr),
  [Regel], [Umsetzung],
  [Versionsnummer im Pfad], [`/v1/notizen`. Einfach, sichtbar in Logs und leicht am Proxy zu sperren.],
  [Abwärtskompatible Änderungen ohne neue Version], [neue optionale Felder, neue Endpunkte],
  [Brechende Änderungen nur in neuer Version], [entfernte Felder, geänderte Bedeutung, strengere Validierung],
  [Abkündigung ankündigen], [Header `Deprecation` (RFC 9745) und `Sunset` (RFC 8594) in jeder Antwort der alten Version],
  [Alte Version wirklich abschalten], [zum angekündigten Datum am Proxy sperren und den Code entfernen],
)

```python
from fastapi import APIRouter, Depends, Response

def abkuendigung(response: Response) -> None:
    response.headers["Deprecation"] = "@1788220800"       # 1. Sept. 2026 UTC
    response.headers["Sunset"] = "Thu, 31 Dec 2026 23:59:59 GMT"
    response.headers["Link"] = (
        '<https://api.example.com/v2/notizen>; rel="successor-version"'
    )

v1 = APIRouter(prefix="/v1", dependencies=[Depends(abkuendigung)])
```

`APIRouter` besitzt keine Middleware-API; eine Router-Abhängigkeit setzt die Header für alle Version-1-Endpunkte. Alternativ kann `/v1` als eigene FastAPI-Unteranwendung mit Middleware gemountet werden.

== Umgebungen

Staging- und Test-Umgebungen sind häufig schwächer geschützt als Produktion, enthalten aber oft Kopien echter Daten. Deshalb: in Test und Staging nur synthetische oder anonymisierte Daten, eigene Authentik-Provider mit eigenen Schlüsseln pro Umgebung (ein Staging-Token darf in Produktion nie gültig sein, was die Issuer- und Audience-Prüfung aus Kapitel 3 automatisch sicherstellt), und nicht mehr benötigte Umgebungen konsequent abbauen.

== Verantwortliches API-Inventar

OpenAPI allein kennt keine Verantwortung. Ein zentrales Inventar hält pro API mindestens Owner und Kontakt, Umgebung und Basis-URL, Datenklassifikation, Authentifizierungsverfahren, externe Erreichbarkeit, Abhängigkeiten, Version, Abkündigungs- und Abschaltdatum fest. CI und Laufzeit-Telemetrie gleichen Soll und Ist ab; unbekannte Hosts, alte Versionen und verwaiste Staging-Systeme werden als Befund behandelt.

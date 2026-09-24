#import "lib.typ": *

= Sicherheit automatisiert testen

Die Prüfungen aus den vorigen Kapiteln verlieren ihren Wert, wenn eine spätere Änderung sie unbemerkt entfernt. Automatisierte Tests in der CI sorgen dafür, dass jede Änderung erneut gegen die wichtigsten Regeln geprüft wird.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let st = (
      ([Statische \ Analyse], [`ruff` (S-Regeln)], c-blue),
      ([Abhängig- \ keiten], [`pip-audit`], c-blue),
      ([Rechte- \ tests], [`pytest`], c-accent),
      ([Fuzzing \ aus OpenAPI], [`schemathesis`], c-accent),
      ([Dynamischer \ Scan], [OWASP ZAP], c-red),
    )
    for (i, s) in st.enumerate() {
      let x = i * 3.1
      kasten((x, 0.15), s.at(0), w: 2.5, h: 1.0, bg: s.at(2).lighten(88%), col: s.at(2), size: 7.3pt)
      content((x, -0.7), text(size: 6.8pt, s.at(1)))
      if i < 4 { pfeil((x + 1.3, 0.15), (x + 1.8, 0.15)) }
    }
    content((1.55, 1.05), text(size: 6.8pt, fill: c-grey.darken(20%), style: "italic")[ohne laufende API])
    content((10.85, 1.05), text(size: 6.8pt, fill: c-grey.darken(20%), style: "italic")[gegen laufende API mit Testdatenbank])
  }),
  caption: [Von schnellen, statischen Prüfungen zu langsameren Tests gegen die laufende API.],
)

== Statische Analyse und Abhängigkeiten

```bash
uv run ruff check --select S .          # Sicherheitsregeln (aus flake8-bandit)
uv run pip-audit                        # bekannte Schwachstellen in installierten Paketen
uv run cyclonedx-py environment -o sbom.json
```

Die `S`-Regeln von Ruff finden unter anderem hart codierte Passwörter, `verify=False`, unsichere Deserialisierung und `subprocess` mit `shell=True`. `pip-audit` prüft den *aufgelösten, gesperrten* Abhängigkeitsstand; die CycloneDX-SBOM macht ihn für Betrieb und Incident Response nachvollziehbar. Secret-Scanning läuft zusätzlich vor dem Commit und in CI. Ausnahmen werden mit Ticket, Begründung und Ablaufdatum dokumentiert.

== Rechte als Tabelle testen

Der Test aus Kapitel 4 lässt sich zu einer vollständigen Matrix ausbauen: Für jeden Endpunkt wird festgehalten, welche Rolle welchen Statuscode bekommen muss. Neue Endpunkte ohne Eintrag lassen den Test fehlschlagen:

#datei("tests/test_rechtematrix.py")[
```python
from fastapi.routing import APIRoute

ERWARTET = {
    ("GET",    "/notizen"):                      {"anonym": 401, "benutzer": 200, "admin": 200},
    ("POST",   "/notizen"):                      {"anonym": 401, "benutzer": 201, "admin": 201},
    ("DELETE", "/admin/benutzer/x/notizen"):     {"anonym": 401, "benutzer": 403, "admin": 204},
}

def test_alle_routen_sind_erfasst():
    routen = {(m, r.path) for r in app.routes if isinstance(r, APIRoute)
              for m in r.methods if m != "HEAD" and r.path != "/health"}
    fehlend = routen - set(ERWARTET)
    assert not fehlend, f"Rechte nicht definiert für: {fehlend}"

@pytest.mark.parametrize("methode,pfad,rolle,status", [
    (methode, pfad, rolle, status)
    for (methode, pfad), rechte in ERWARTET.items()
    for rolle, status in rechte.items()
])
def test_rechtematrix(client_fuer, methode, pfad, rolle, status):
    antwort = client_fuer(rolle).request(methode, pfad)
    assert antwort.status_code == status
```
]

Die Matrix ist projektspezifisch vollständig zu halten; Platzhalter wie `/x/` werden durch Testdaten ersetzt. Der Ausführungstest ist der eigentliche Wert, die Routenprüfung verhindert nur vergessene Einträge. Zusätzlich gehören negative Tokenfälle in die Suite: `alg=none`, falscher Issuer/Audience, abgelaufen, noch nicht gültig, unbekannte `kid`, fehlende/falsch typisierte Claims und insbesondere ein echtes ID-Token.

== Fuzzing aus der OpenAPI-Beschreibung

_Schemathesis_ liest die OpenAPI-Beschreibung und erzeugt daraus automatisch tausende Anfragen mit Grenzwerten, falschen Typen, sehr langen Zeichenketten und unerwarteten Kombinationen. Es meldet Serverfehler (500), Antworten, die nicht zum Schema passen, und fehlende Validierung:

```bash
uv run schemathesis run http://localhost:8000/openapi.json \
  --header "Authorization: Bearer $TEST_TOKEN"
```

Ein 500er bei Schemathesis ist fast immer ein echter Fehler: eine fehlende Längenbegrenzung, ein nicht abgefangener Sonderfall oder ein Datenbankfehler bei ungewöhnlicher Eingabe.

== Dynamischer Scan mit OWASP ZAP

OWASP ZAP bringt einen eigenen Modus für APIs mit, der die OpenAPI-Beschreibung einliest und bekannte Angriffsmuster gegen alle Endpunkte ausprobiert:

```bash
docker run --rm --network notizen_default -v "$PWD:/zap/wrk" \
  zaproxy/zap-stable@sha256:<gepruefter-digest> \
  zap-api-scan.py -t http://api:8000/openapi.json -f openapi -r zap-bericht.html
```

Der Bericht landet als `zap-bericht.html` im aktuellen Verzeichnis. Der Digest wird automatisiert aktualisiert und im Review geprüft; ein beweglicher `latest`-ähnlicher Tag wäre nicht reproduzierbar. ZAP findet vor allem Konfigurations- und Injection-Probleme. Autorisierungsfehler wie BOLA brauchen eigene Tests. Aktives DAST läuft nur mit ausdrücklicher Freigabe gegen eine isolierte Umgebung mit synthetischen Daten, nie ungeplant gegen Produktion.

== In der CI

#datei(".gitea/workflows/ci.yml (Auszug)")[
```yaml
  sicherheit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<gepruefter-commit-sha>
      - name: uv installieren
        uses: astral-sh/setup-uv@<gepruefter-commit-sha>
        with:
          version: "<gepruefte-uv-version>"   # regelmäßig bewusst aktualisieren
      - run: uv sync --locked
      - run: uv run ruff check --select S .
      - run: uv run pip-audit
      - run: uv run pytest tests/test_rechte.py tests/test_rechtematrix.py
```
]

Die Platzhalter werden im echten Repository durch geprüfte vollständige Commit-SHAs beziehungsweise Image-Digests ersetzt; die Beispielwerte dürfen nicht unverändert produktiv verwendet werden. So lädt die CI keinen ungeprüften `curl | sh`-Installer und keine unbemerkt verschobenen Actions. Schemathesis und ZAP brauchen eine laufende API mit Datenbank und laufen deshalb in einem getrennten, autorisierten Workflow gegen eine isolierte Testumgebung.

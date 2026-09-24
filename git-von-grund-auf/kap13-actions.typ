#import "lib.typ": *

= Gitea Actions: die `ci.yml` verstehen

CI/CD steht für _Continuous Integration_ und _Continuous Delivery/Deployment_: Bei jedem Push prüft eine Maschine automatisch, ob der Code gebaut werden kann und die Tests bestehen (CI), und liefert ihn bei Erfolg aus (CD). In Gitea übernimmt das _Gitea Actions_. Die Workflows werden als YAML-Dateien im Repository beschrieben, und die Syntax ist bewusst mit GitHub Actions kompatibel. Viele Anleitungen und fertige Bausteine aus der GitHub-Welt funktionieren deshalb auch hier — Unterschiede müssen aber geprüft werden.

== Wie Gitea Actions funktioniert

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [*Dein Mac* \ #text(size: 6.8pt)[`git push`]], w: 2.0, h: 1.2)
    rect((2.8, -1.5), (7.2, 1.5), radius: 0.15, fill: rgb("#EEF6E6"), stroke: (paint: c-gitea, thickness: 1pt))
    content((5.0, 1.2), text(size: 8pt, weight: "bold", fill: c-gitea.darken(20%))[Gitea-Server])
    content((5.0, 0.05), align(left, text(size: 7pt)[• Repository mit \ #h(0.6em)`.gitea/workflows/ci.yml` \ • Secrets und Variablen \ • Warteschlange der Jobs \ • Logs, Status im PR]))
    rect((10.2, -1.5), (15.0, 1.5), radius: 0.15, fill: rgb("#EAF1FB"), stroke: (paint: c-blue, thickness: 1pt))
    content((12.6, 1.2), text(size: 8pt, weight: "bold", fill: c-blue.darken(20%))[Runner-Host (Docker)])
    kasten((12.6, 0.15), [`gitea-runner`], w: 2.4, h: 0.55, size: 7pt)
    kasten((11.5, -0.95), [Job-Container \ `lint`], w: 1.9, h: 0.75, bg: white, col: c-blue, size: 6.5pt)
    kasten((13.7, -0.95), [Job-Container \ `test`], w: 1.9, h: 0.75, bg: white, col: c-blue, size: 6.5pt)
    line((12.6, -0.13), (11.7, -0.55), stroke: c-grey + 0.7pt, mark: (end: "stealth", fill: c-grey, scale: 0.4))
    line((12.6, -0.13), (13.5, -0.55), stroke: c-grey + 0.7pt, mark: (end: "stealth", fill: c-grey, scale: 0.4))
    pfeil((1.05, 0.2), (2.75, 0.2), label: "1 push", loff: (0, 0.22))
    pfeil((10.15, 1.0), (7.25, 1.0), label: "2 fragt nach Jobs", loff: (0, 0.2), color: c-blue)
    pfeil((7.25, 0.3), (10.15, 0.3), label: "3 Job + Secrets", loff: (0, 0.2), color: c-gitea)
    pfeil((10.15, -0.4), (7.25, -0.4), label: "4 Checkout", loff: (0, 0.2), color: c-blue)
    pfeil((10.15, -1.1), (7.25, -1.1), label: "5 Logs, Status", loff: (0, 0.2), color: c-blue)
  }),
  caption: [Ablauf eines Workflow-Laufs. Der Runner baut alle Verbindungen selbst auf, Gitea muss ihn nicht erreichen können.],
)

+ Du pushst einen Commit. Gitea liest die Workflow-Dateien des Commits und prüft, welche davon auf das Ereignis reagieren (etwa _push auf main_ oder _Pull Request geöffnet_). Für jeden passenden Job legt es einen Eintrag in einer Warteschlange an.
+ Ein *Runner* fragt regelmäßig bei Gitea nach Arbeit. Der Runner ist ein eigenes Programm (`gitea-runner`, früher `act_runner`), das auf einem beliebigen Rechner mit Docker läuft (Kapitel 14).
+ Passt ein Job zu den _Labels_ des Runners, bekommt der Runner die Job-Beschreibung samt der benötigten Secrets.
+ Bei einem Docker-Label startet der Runner für den Job einen frischen Container, der den Code aus Gitea auscheckt und die Schritte ausführt. Ein `host`-Label führt die Schritte dagegen direkt auf dem Runner-Rechner aus und bietet deutlich weniger Isolation.
+ Logs und Ergebnis gehen zurück an Gitea und erscheinen im Tab _Actions_ sowie als Häkchen oder Kreuz am Commit und im Pull Request.

#merke[Weil der Runner die Verbindung zu Gitea aufbaut und nicht umgekehrt, kann er hinter einem Router, in einem Heimnetz oder in einem VPN stehen. Er braucht nur ausgehenden Zugriff auf Gitea (und auf das Internet, wenn Actions oder Docker-Images heruntergeladen werden).]

=== Voraussetzungen

- Actions ist in aktuellen Gitea-Versionen serverweit aktiv. Falls nicht, muss in der `app.ini` im Abschnitt `[actions]` der Wert `ENABLED = true` stehen.
- Im Repository muss die Einheit _Actions_ eingeschaltet sein (_Einstellungen -> Erweiterte Einstellungen_). Dann erscheint der Tab _Actions_.
- Mindestens ein Runner muss registriert und online sein, dessen Labels zu `runs-on` passen.
- Workflows liegen als `.yml`- oder `.yaml`-Dateien im Ordner `.gitea/workflows/`. Existiert dieser Ordner nicht, liest Gitea ersatzweise `.github/workflows/`. Der Dateiname ist frei wählbar, `ci.yml` ist nur eine Konvention.

== YAML in zehn Minuten

Workflow-Dateien sind in YAML geschrieben, einem Format für verschachtelte Daten, dessen Struktur allein durch *Einrückung* entsteht. Fast alle Fehler in Workflows sind Einrückungsfehler.

#datei("yaml-grundlagen.yml")[
```yaml
# Kommentar
name: ci                     # Zuordnung: Schlüssel, Doppelpunkt, Leerzeichen, Wert
timeout: 10                  # Zahl
aktiv: true                  # Wahrheitswert

branches: [main, develop]    # Liste in Kurzform
labels:                      # Liste in Langform: jedes Element mit "- "
  - ubuntu-latest
  - docker

job:                         # verschachtelte Zuordnung: alles darunter um 2 Leerzeichen eingerückt
  name: Test
  steps:                     # Liste von Zuordnungen
    - name: Erster Schritt
      run: echo "Hallo"
    - name: Zweiter Schritt
      run: |                 # "|" = mehrzeiliger Text, Zeilenumbrüche bleiben erhalten
        echo "Zeile 1"
        echo "Zeile 2"
version: "3.10"              # Anführungszeichen, sonst würde daraus die Zahl 3.1
```
]

Die wichtigsten Regeln: Einrückung *nur mit Leerzeichen*, nie mit Tabulatoren. Alles auf derselben Einrückungsebene gehört zusammen. Ein `-` leitet ein Listenelement ein, und alles, was zu diesem Element gehört, steht um zwei Leerzeichen weiter eingerückt als das `-`. Im Zweifel Werte in Anführungszeichen setzen, besonders Versionsnummern, Zeiten und alles mit `:` oder `#`.

#tipp[VS Code mit der Erweiterung _YAML_ von Red Hat markiert Einrückungsfehler sofort. Mit dem Schema für GitHub-Workflows (das für Gitea weitgehend passt) gibt es sogar Autovervollständigung für Schlüssel wie `runs-on` und `steps`.]

== Der erste Workflow

#datei(".gitea/workflows/ci.yml")[
```yaml
name: ci                          # Name des Workflows, erscheint in Gitea und in Statusprüfungen

on:                               # WANN läuft der Workflow?
  push:
    branches: [main]              # bei jedem Push auf main
  pull_request:                   # bei jedem PR (Öffnen und jedem neuen Push darauf)

jobs:                             # WAS läuft? Eine Sammlung von Jobs
  test:                           # frei gewählte Job-ID
    runs-on: ubuntu-latest        # WO läuft er? Muss zu einem Runner-Label passen
    steps:                        # die Schritte, der Reihe nach
      - name: Code auschecken
        uses: actions/checkout@v4 # fertige Action: klont das Repository in den Container
      - name: Tests ausführen
        run: make test            # Shell-Befehl; Rückgabewert ungleich 0 = Fehler
```
]

Zeile für Zeile passiert Folgendes: Bei einem Push auf `main` oder einem PR startet Gitea den Workflow `ci`. Er besteht aus einem Job `test`, der auf einem Runner mit dem Label `ubuntu-latest` in einem frischen Container läuft. Der erste Schritt holt den Code, der zweite führt die Tests aus. Schlägt ein Schritt fehl, bricht der Job ab und wird rot markiert. Im Pull Request erscheint die Prüfung unter dem Namen `ci / test (pull_request)`, also _Workflow / Job (Ereignis)_.

#achtung[Ohne `actions/checkout` ist der Container leer! Der Code wird nicht automatisch bereitgestellt. Der Checkout-Schritt ist deshalb in fast jedem Job der erste.]

== Die Anatomie: Workflow, Jobs, Steps

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    rect((0, -2.25), (15.2, 1.1), radius: 0.15, fill: luma(248), stroke: (paint: c-dark, thickness: 1pt))
    content((0.25, 0.8), anchor: "west", text(size: 8pt, weight: "bold")[Workflow `ci.yml`  #text(weight: "regular", fill: c-grey.darken(20%))[ausgelöst durch `on:`]])
    let job(x, name, steps, col) = {
      rect((x, -1.98), (x + 4.3, 0.35), radius: 0.12, fill: col.lighten(92%), stroke: (paint: col, thickness: 0.9pt))
      content((x + 0.2, 0.08), anchor: "west", text(size: 7.5pt, weight: "bold", fill: col.darken(20%))[Job #raw(name) #text(weight: "regular", size: 6.5pt)[(eigener Container)]])
      for (i, s) in steps.enumerate() {
        rect((x + 0.25, -0.75 - i * 0.55), (x + 4.05, -0.33 - i * 0.55), radius: 0.06, fill: white, stroke: 0.6pt + col.lighten(30%))
        content((x + 0.4, -0.54 - i * 0.55), anchor: "west", text(font: "JetBrains Mono", size: 6.3pt, s))
      }
    }
    job(0.3, "lint", ("1 checkout", "2 make setup", "3 make lint"), c-accent)
    job(5.45, "test", ("1 checkout", "2 make setup", "3 make test"), c-accent)
    job(10.6, "build", ("1 checkout", "2 docker build", "3 docker push"), c-blue)
    line((4.6, -1.0), (5.4, -1.0), stroke: (paint: c-dark, thickness: 0.9pt), mark: (end: "stealth", fill: c-dark, scale: 0.55))
    line((9.75, -1.0), (10.55, -1.0), stroke: (paint: c-dark, thickness: 0.9pt), mark: (end: "stealth", fill: c-dark, scale: 0.55))
    content((5.0, -1.25), text(font: "JetBrains Mono", size: 6pt)[needs])
    content((10.15, -1.25), text(font: "JetBrains Mono", size: 6pt)[needs])
  }),
  caption: [Jobs laufen in getrennten Containern und ohne `needs` parallel. Steps eines Jobs laufen nacheinander im selben Container.],
)

Diese Struktur ist das Wichtigste am ganzen Kapitel:

- Ein *Workflow* ist eine Datei. Er wird durch Ereignisse ausgelöst und enthält einen oder mehrere Jobs.
- Ein *Job* läuft auf einem Runner in einem *eigenen, frischen Container*. Jobs laufen standardmäßig *parallel*. Mit `needs` legst du Abhängigkeiten fest. Jobs teilen *keine Dateien* miteinander, dafür gibt es Artefakte, Caches und Job-Ausgaben.
- Ein *Step* ist entweder ein Shell-Befehl (`run`) oder eine wiederverwendbare *Action* (`uses`). Steps eines Jobs laufen nacheinander im selben Container und teilen sich das Arbeitsverzeichnis. Schlägt ein Step fehl, werden die folgenden übersprungen.

== Auslöser: `on`

#table(columns: (auto, 1fr),
  [Auslöser], [Beispiel und Bedeutung],
  [`push`], [`branches: [main]`, `tags: ['v*']`, `paths: ['src/**']`, `paths-ignore: ['docs/**']`. Filter werden kombiniert: Push auf passenden Branch *und* passende Pfade.],
  [`pull_request`], [`types: [opened, synchronize, reopened]` (Standard). `branches: [main]` filtert nach dem *Ziel*-Branch des PRs.],
  [`workflow_dispatch`], [Manuell starten über eine Schaltfläche im Tab _Actions_, optional mit Eingaben (`inputs`).],
  [`schedule`], [Zeitgesteuert: `- cron: '0 3 * * 1'` (montags 3 Uhr, UTC). Gitea versteht zusätzlich `@daily`, `@weekly` usw.],
  [`release`], [beim Veröffentlichen eines Releases in Gitea],
)

```yaml
on:
  push:
    branches: [main]
    tags: ['v*']              # Tags wie v1.2.0 lösen ebenfalls aus
    paths-ignore: ['**.md']   # reine Doku-Änderungen ignorieren
  pull_request:
  workflow_dispatch:
    inputs:
      ziel:
        description: 'Zielumgebung'
        default: 'staging'
```

== Jobs im Detail

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 20                 # Job nach 20 Minuten abbrechen
    strategy:
      matrix:                           # Job für jede Kombination einmal starten
        version: ["3.12", "3.13"]
    services:                           # Hilfscontainer für die Dauer des Jobs
      db:
        image: postgres:17
        env:
          POSTGRES_PASSWORD: test
    env:
      DATABASE_URL: postgres://postgres:test@db:5432/postgres
    steps:
      - uses: actions/checkout@v4
      - run: make test VERSION=${{ matrix.version }}

  deploy:
    needs: [test]                       # erst nach erfolgreichem test
    if: github.ref == 'refs/heads/main' # nur auf main, nicht in PRs
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deployment ..."
```

- *`runs-on`* wählt den Runner über sein Label. Gitea unterstützt hier nur einen einfachen Namen oder eine einfache Liste, keine Gruppen-Syntax.
- *`needs`* baut aus Jobs einen Ablaufgraphen. Schlägt ein benötigter Job fehl, werden die abhängigen übersprungen.
- *`if`* entscheidet, ob ein Job oder Step überhaupt läuft. Innerhalb von `if` darf man die `${{ }}`-Klammern weglassen.
- *`strategy.matrix`* vervielfacht einen Job, etwa für mehrere Sprachversionen.
- *`services`* startet Hilfscontainer (Datenbank, Redis). Der Job erreicht sie über ihren Namen als Hostnamen, hier `db`.
- *`container`* (nicht gezeigt) lässt den Job statt im Standard-Image in einem eigenen Image laufen, etwa `container: python:3.13-slim`.

== Steps im Detail

```yaml
    steps:
      - name: Code auschecken
        uses: actions/checkout@v4       # Action in Version v4
        with:                           # Eingaben für die Action
          fetch-depth: 0                # komplette Historie statt nur des letzten Commits

      - name: Version bestimmen
        id: version                     # ID, um später auf Ausgaben zuzugreifen
        run: echo "tag=$(git describe --tags --always)" >> "$GITHUB_OUTPUT"

      - name: Bauen
        working-directory: ./app        # in einem Unterordner ausführen
        env:
          VERSION: ${{ steps.version.outputs.tag }}
        run: |
          echo "Baue Version $VERSION"
          make build

      - name: Aufräumen
        if: always()                    # auch ausführen, wenn vorher etwas fehlschlug
        run: make clean
```

`run`-Schritte werden mit `bash -e` ausgeführt: Der erste fehlschlagende Befehl beendet den Schritt mit Fehler. Ausgaben eines Schrittes schreibt man in die Datei, auf die `$GITHUB_OUTPUT` zeigt, im Format `name=wert`. Folgende Schritte lesen sie über `steps.<id>.outputs.<name>`. Auf dieselbe Weise setzt `echo "NAME=wert" >> "$GITHUB_ENV"` eine Umgebungsvariable für alle folgenden Schritte.

#tipp[Actions werden über `uses: besitzer/name@version` eingebunden und standardmäßig von github.com geladen. Die Beispiele verwenden Hauptversions-Tags, damit sie lesbar bleiben. In produktiven Workflows pinnt man fremde Actions nach Prüfung auf einen vollen Commit-Hash (`actions/checkout@<40 Zeichen>`) und lässt Abhängigkeitsupdates bewusst prüfen. Gitea erlaubt außerdem absolute URLs, etwa `uses: https://gitea.example.com/team/meine-action@v1`, womit man geprüfte Actions auf dem eigenen Server spiegeln kann.]

== Ausdrücke und Kontexte

Alles zwischen `${{` und `}}` ist ein Ausdruck, den Gitea vor dem Ausführen auswertet. Die Daten kommen aus _Kontexten_:

#table(columns: (auto, 1fr),
  [Kontext], [Inhalt (Beispiele)],
  [`gitea` / `github`], [Metadaten des Laufs, beide Namen funktionieren: `gitea.ref` (`refs/heads/main`), `gitea.ref_name` (`main`), `gitea.sha`, `gitea.event_name` (`push`, `pull_request`), `gitea.actor`, `gitea.repository` (`team/demo`), `gitea.server_url`, `gitea.run_number`],
  [`secrets`], [geheime Werte, z.B. `secrets.SONAR_TOKEN`, dazu automatisch `secrets.GITEA_TOKEN` (Kapitel 14)],
  [`vars`], [nicht geheime Konfigurationsvariablen, z.B. `vars.DEPLOY_HOST`],
  [`env`], [Umgebungsvariablen aus `env:`-Blöcken],
  [`steps`], [Ausgaben und Ergebnis früherer Schritte: `steps.version.outputs.tag`, `steps.x.outcome`],
  [`needs`], [Ausgaben und Ergebnis benötigter Jobs: `needs.build.outputs.image`, `needs.test.result`],
  [`matrix`], [aktuelle Matrix-Werte: `matrix.version`],
  [`runner`], [Informationen über den Runner: `runner.os`, `runner.temp`],
)

Dazu gibt es Operatoren (`==`, `!=`, `&&`, `||`, `!`) und Funktionen wie `contains(...)`, `startsWith(gitea.ref, 'refs/tags/v')` und `format(...)`. Für Bedingungen auf den bisherigen Verlauf dient `always()`. Für die übrigen Statusfunktionen nennt die Gitea-Dokumentation Einschränkungen. Ungewöhnliche Bedingungen testest du am besten einmal gezielt mit einem kleinen Workflow und `workflow_dispatch`.

Zusätzlich stehen in jedem Schritt Umgebungsvariablen bereit, darunter `GITHUB_SHA`, `GITHUB_REF`, `GITHUB_REF_NAME`, `GITHUB_WORKSPACE` (Arbeitsverzeichnis mit dem ausgecheckten Code), `CI=true` und `GITEA_ACTIONS=true`, an dem ein Skript erkennen kann, dass es in Gitea läuft.

== Daten zwischen Jobs: Artefakte und Caches

Weil jeder Job in einem neuen Container startet, muss alles, was ein späterer Job braucht, ausdrücklich weitergereicht werden:

```yaml
      - uses: actions/upload-artifact@v4       # im Job "build"
        with:
          name: paket
          path: dist/
          retention-days: 7
      # ...
      - uses: actions/download-artifact@v4     # im Job "deploy" (needs: build)
        with:
          name: paket
```

Artefakte erscheinen auch zum Herunterladen in der Oberfläche des Laufs, ideal für Testberichte. *Caches* (`actions/cache@v4`) sind dagegen dafür da, Abhängigkeiten wie Paket-Downloads zwischen Läufen wiederzuverwenden. Der Runner bringt dafür einen eigenen Cache-Server mit. Gitea Runner 3.x verwendet das Cache-v2-Protokoll; die normalen `actions/cache@v4` sowie `actions/upload-artifact` und `actions/download-artifact` ab v4.4 funktionieren damit. Beim Umstieg von `act_runner` oder Runner 2.x zuerst die Upgrade-Hinweise lesen: Runner 3.0 änderte Cache-Verhalten, Sicherheitsfilter für Container-Optionen und die Verwaltung mehrerer Registrierungen.

== Unterschiede zu GitHub Actions

Gitea Actions ist kompatibel, aber nicht identisch. Stand Gitea 1.27.3 und Runner 3.5 gilt laut Dokumentation:

- `jobs.<id>.environment` (Deployment-Umgebungen mit Freigaben) wird ignoriert. Unterschiedliche Ziele bildet man über getrennte Variablen oder Workflows ab (Kapitel 15).
- `runs-on` akzeptiert nur einfache Labels, keine Gruppen oder komplexen Ausdrücke.
- _Problem Matchers_ und Fehler-Annotationen im Code werden ignoriert.
- Der automatische `GITEA_TOKEN` darf keine Pakete in die Gitea-Registry hochladen. Dafür braucht man einen persönlichen Zugriffstoken als Secret.
- `concurrency` und `permissions` werden seit 1.26 unterstützt, `timeout-minutes` und `continue-on-error` seit 1.27. *Ältere Versionen ignorieren diese Schlüssel stillschweigend.* Wer eine ältere Gitea-Version betreibt, sollte sich nicht darauf verlassen.
- Zusätzlich kann Gitea Actions per absoluter URL aus beliebigen Git-Repositories laden und versteht `@daily` & Co. bei `schedule`.

Gitea 1.27 zeigt mit Runner 2.0 oder neuer außerdem Job-Zusammenfassungen aus `$GITHUB_STEP_SUMMARY`, einen eigenen Zustand _Cancelling_ und korrekt aggregiertes `continue-on-error`. Server und Runner werden unabhängig versioniert; eine hohe Runner-Version bedeutet daher nicht, dass die Gitea-Instanz alle Syntaxmerkmale unterstützt.

== Vertrauensgrenzen von Workflows

Ein Workflow ist ausführbarer Code. Wer eine Workflow-Datei, ein eingebundenes Skript oder eine nicht gepinnte Action verändern kann, kann grundsätzlich alle Rechte des Jobs nutzen. Auf einem selbst gehosteten Runner mit Docker-Socket reicht das bis zu Root-Rechten auf dem Runner-Host.

- Workflows aus Forks erhalten keine Secrets, können aber trotzdem schädlichen Code auf dem Runner ausführen. Öffentliche Repositories deshalb nur auf kurzlebigen, isolierten Runnern ausführen und Läufe neuer Fork-Beiträge freigabepflichtig lassen.
- Niemals untrusted PR-Code in einem privilegierten Deployment-Job ausführen. Build/Tests und Deployment auf getrennte Runner-Gruppen oder mindestens getrennte Workflows und Zugangsdaten aufteilen.
- Actions auf unveränderliche Commit-Hashes pinnen, Workflow-Dateien per Branch-Schutz absichern und ausgehenden Netzwerkzugriff sowie erlaubte Volumes minimieren.
- Die Log-Maskierung ist nur ein Auffangnetz. Auch wenn aktuelle Runner mehrere übliche Kodierungen erkennen, können umgeformte, aufgeteilte oder in Artefakten gespeicherte Secrets weiterhin sichtbar werden.

Mit `concurrency` lassen sich überholte Läufe automatisch abbrechen, etwa wenn du mehrmals kurz hintereinander auf denselben PR-Branch pushst:

```yaml
concurrency:
  group: ci-${{ gitea.ref }}
  cancel-in-progress: true
```

== Das Beispielprojekt

Damit Workflows sprachunabhängig bleiben, kapselt das Beispielprojekt `demo` alle Werkzeuge in einem `Makefile`. Die Pipeline ruft nur `make`-Ziele auf. Wechselt die Sprache oder das Test-Framework, ändert sich nur das Makefile, nicht die Pipeline. Ein weiterer Vorteil: Dieselben Befehle laufen lokal am Mac exakt so wie in der CI.

#datei("Makefile")[
```make
.PHONY: setup lint test build

setup:          # Abhängigkeiten installieren, z.B. pip install -r requirements-dev.txt / npm ci
	./scripts/setup.sh

lint:           # statische Prüfungen, z.B. ruff check . / npm run lint
	./scripts/lint.sh

test:           # Tests mit Coverage-Bericht nach reports/coverage.xml
	./scripts/test.sh

build:          # Container-Image bauen
	docker build -t demo:$(or $(VERSION),dev) .
```
]

Wie aus diesem Baustein eine vollständige Pipeline mit Lint, Tests, SonarQube, Image-Build und Deployment wird, zeigt Kapitel 15. Vorher geht es im nächsten Kapitel um die Infrastruktur dahinter: Runner, Secrets, SSH-Zugang und SonarQube.

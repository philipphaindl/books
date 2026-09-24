#import "lib.typ": *

= Images und das Dockerfile

Ein eigenes Image beschreibt man in einer Textdatei namens `Dockerfile`: eine Abfolge von Anweisungen, die ausgehend von einem Basis-Image Schicht für Schicht die Laufzeitumgebung aufbaut. In diesem Kapitel entsteht ein erstes, funktionierendes Image für das Beispielprojekt. Kapitel 8 macht daraus später ein schlankes, sicheres Produktions-Image.

== Images verwalten

```bash
docker pull python:3.14-slim           # Image laden, ohne einen Container zu starten
docker image ls                        # lokale Images (Kurzform: docker images)
docker image history python:3.14-slim  # Schichten mit Größe und erzeugender Anweisung
docker image inspect python:3.14-slim  # Details: Architektur, Umgebung, Digest
docker tag notizen:dev notizen:1.4.0   # zusätzlichen Namen vergeben (keine Kopie)
docker image rm notizen:dev            # Namen entfernen, Image löschen, wenn kein Name mehr bleibt
```
```out
REPOSITORY   TAG           IMAGE ID       CREATED        SIZE
notizen      1.4.0         4c1f0a9d2e11   2 minutes ago  212MB
notizen      dev           4c1f0a9d2e11   2 minutes ago  212MB
python       3.14-slim     a7d3c1e2b9f0   5 days ago     148MB
```

Zwei Namen mit derselben Image-ID sind *ein* Image mit zwei Etiketten, genau wie zwei Branches, die auf denselben Commit zeigen.

== Das erste Dockerfile

Das Beispielprojekt definiert seine Abhängigkeiten in `pyproject.toml` und hält die exakten Versionen in `uv.lock` fest:

#datei("pyproject.toml")[
```toml
[project]
name = "notizen"
version = "1.4.0"
requires-python = ">=3.14"
dependencies = [
    "fastapi[standard]>=0.115",
    "psycopg[binary]>=3.2",
]
```
]

#datei("Dockerfile")[
```dockerfile
FROM python:3.14-slim

# uv aus dem offiziellen Image übernehmen (in Kapitel 8 auf eine feste Version pinnen)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# 1. Nur die Abhängigkeitsbeschreibung kopieren und installieren
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-install-project --no-dev

# 2. Danach den Code kopieren
COPY app/ ./app/

ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 8000
CMD ["fastapi", "run", "app/main.py", "--port", "8000"]
```
]

Bauen und starten:

```bash
docker build -t notizen:dev .              # der Punkt ist der Build-Kontext (siehe unten)
docker run --rm -p 8000:8000 notizen:dev
curl http://localhost:8000/health          # in einem zweiten Terminal
```

== Die Anweisungen

#table(columns: (auto, 1fr),
  [Anweisung], [Bedeutung],
  [`FROM image`], [Basis-Image. Jedes Dockerfile beginnt damit (bei Multi-Stage-Builds mehrfach, Kapitel 8).],
  [`WORKDIR /app`], [Arbeitsverzeichnis für alle folgenden Anweisungen und für den Container, wird bei Bedarf angelegt.],
  [`COPY quelle ziel`], [Dateien aus dem Build-Kontext ins Image kopieren. `--from=` kopiert aus einem anderen Image oder einer Build-Stufe.],
  [`ADD`], [Wie `COPY`, kann zusätzlich URLs laden und Archive entpacken. Nur verwenden, wenn genau das gebraucht wird.],
  [`RUN befehl`], [Befehl beim Bauen ausführen, das Ergebnis wird zur neuen Schicht.],
  [`ENV NAME=wert`], [Umgebungsvariable, gilt beim Bauen *und* im laufenden Container.],
  [`ARG NAME=wert`], [Variable nur beim Bauen, setzbar mit `docker build --build-arg NAME=...`.],
  [`EXPOSE 8000`], [Dokumentiert den Port. Veröffentlicht ihn *nicht*, das macht erst `-p`.],
  [`USER app`], [Benutzer für folgende Anweisungen und den Container (Kapitel 8).],
  [`CMD [...]`], [Standardbefehl beim Start, beim `docker run` überschreibbar.],
  [`ENTRYPOINT [...]`], [Fester Startbefehl, `CMD` liefert dann nur dessen Standardargumente.],
  [`HEALTHCHECK`], [Befehl, mit dem Docker regelmäßig prüft, ob der Container gesund ist (Kapitel 7).],
  [`LABEL`], [Metadaten wie Version oder Quell-Repository.],
)

== Build-Kontext und `.dockerignore`

Der Punkt am Ende von `docker build -t notizen:dev .` ist der *Build-Kontext*: das Verzeichnis, dessen Inhalt an den Build übergeben wird. Nur Dateien darin kann `COPY` erreichen. Ohne Filter landen auch `.git`, virtuelle Umgebungen, Caches und im schlimmsten Fall `.env`-Dateien mit Passwörtern im Kontext und über ein unbedachtes `COPY . .` im Image. Eine `.dockerignore` schließt sie aus:

#datei(".dockerignore")[
```text
.git
.venv
__pycache__/
*.pyc
.pytest_cache/
.env
.env.*
compose*.yaml
Dockerfile
```
]

== Der Schicht-Cache

Docker merkt sich jede gebaute Schicht. Ändert sich an einer Anweisung und ihren Eingaben nichts, wird die Schicht aus dem Cache genommen. Sobald sich aber eine Schicht ändert, werden *alle folgenden* neu gebaut. Deshalb kommt es auf die Reihenfolge an:

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let neu = c-accent
    let alt = c-blue
    content((2.1, 3.0), text(size: 8pt, weight: "bold")[Ungünstig])
    stapel((2.1, 0), (([`FROM python:3.14-slim`], alt), ([`COPY . .`  #h(4pt) (Code geändert)], neu), ([`RUN uv sync` (1 bis 2 Minuten)], neu), ([`CMD ...`], neu)), w: 4.6, h: 0.52, size: 7.3pt)
    content((9.3, 3.0), text(size: 8pt, weight: "bold")[Günstig])
    stapel((9.3, 0), (([`FROM python:3.14-slim`], alt), ([`COPY pyproject.toml uv.lock`], alt), ([`RUN uv sync` (aus dem Cache)], alt), ([`COPY app/` #h(4pt) (Code geändert)], neu), ([`CMD ...`], neu)), w: 4.6, h: 0.52, size: 7.3pt)
    rect((12.2, 2.2), (12.55, 2.45), fill: c-blue.lighten(86%), stroke: c-blue + 0.8pt)
    content((12.7, 2.32), anchor: "west", text(size: 7pt)[aus dem Cache])
    rect((12.2, 1.7), (12.55, 1.95), fill: c-accent.lighten(86%), stroke: c-accent + 0.8pt)
    content((12.7, 1.82), anchor: "west", text(size: 7pt)[neu gebaut])
  }),
  caption: [Nach einer Codeänderung: Links werden alle Abhängigkeiten neu installiert, rechts nur der Code kopiert.],
)

Die Faustregel: *Was sich selten ändert, gehört nach oben; was sich oft ändert, nach unten.* Deshalb kopiert das Dockerfile oben zuerst nur `pyproject.toml` und `uv.lock`, installiert die Abhängigkeiten und kopiert erst danach den Code. Eine Codeänderung baut dann in Sekunden.

== `CMD`, `ENTRYPOINT` und die Signale

Beide Anweisungen gibt es in zwei Schreibweisen, und der Unterschied ist wichtiger, als er aussieht:

#table(columns: (auto, auto, 1fr),
  [Form], [Beispiel], [Folge],
  [Exec-Form], [`CMD ["fastapi", "run", "app/main.py"]`], [Das Programm ist direkt PID 1 und bekommt Signale wie SIGTERM. *Immer verwenden.*],
  [Shell-Form], [`CMD fastapi run app/main.py`], [Docker startet `/bin/sh -c "..."`. PID 1 ist die Shell, die SIGTERM nicht weiterreicht.],
)

`docker stop` schickt dem Hauptprozess SIGTERM und wartet zehn Sekunden. Reagiert er nicht, folgt SIGKILL. Bei der Shell-Form kommt das SIGTERM nie bei der Anwendung an: Jeder Stopp dauert zehn Sekunden und endet mit einem harten Abbruch, offene Datenbankverbindungen werden nicht sauber geschlossen.

`CMD` und `ENTRYPOINT` arbeiten zusammen: Ist ein `ENTRYPOINT` gesetzt, wird `CMD` als Argumente an ihn angehängt. Das Muster eignet sich für Images, die wie ein Programm benutzt werden:

```dockerfile
ENTRYPOINT ["python", "-m", "app.cli"]
CMD ["--help"]
```
```bash
docker run --rm notizen-cli                # führt "python -m app.cli --help" aus
docker run --rm notizen-cli import x.csv   # ersetzt nur CMD: "... app.cli import x.csv"
```

Für die meisten Dienste genügt ein `CMD` in Exec-Form. Mit `docker run --entrypoint sh ...` lässt sich ein `ENTRYPOINT` zur Fehlersuche übergehen (Kapitel 10).

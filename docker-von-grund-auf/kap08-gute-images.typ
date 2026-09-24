#import "lib.typ": *

= Gute Images bauen

Das Image aus Kapitel 4 funktioniert, hat aber drei Schwächen: Es enthält Werkzeuge, die zur Laufzeit niemand braucht (uv, Build-Caches), der Prozess läuft als `root`, und Versionen sind nicht festgelegt. Dieses Kapitel baut daraus das Produktions-Image des Beispielprojekts.

== Das Basis-Image wählen

#table(columns: (auto, auto, 1fr),
  [Variante], [Größe], [Einordnung],
  [`python:3.14`], [ca. 1 GB], [Volles Debian mit Compilern. Nur als Build-Stufe sinnvoll, wenn Pakete kompiliert werden müssen.],
  [`python:3.14-slim`], [ca. 150 MB], [Schlankes Debian mit Python. *Guter Standard.*],
  [`python:3.14-alpine`], [ca. 50 MB], [Sehr klein, nutzt aber die C-Bibliothek musl. Viele Python-Pakete haben dafür keine fertigen Binärpakete und müssen aufwendig kompiliert werden. Für Python meist nicht die Ersparnis wert.],
  [_distroless_ / gehärtete Images], [klein], [Nur Laufzeit, keine Shell, kein Paketmanager. Minimale Angriffsfläche, aber schwerer zu debuggen.],
)

Die Größenangaben sind Größenordnungen. Wichtiger als die letzten Megabytes ist, dass das Image nichts enthält, was nicht gebraucht wird: jedes zusätzliche Programm ist potenziell eine Sicherheitslücke.

== Multi-Stage-Builds

Ein Dockerfile kann mehrere `FROM`-Anweisungen enthalten. Jede beginnt eine neue *Stufe*. Nur die letzte Stufe wird zum Image, aus früheren Stufen werden gezielt Ergebnisse herüberkopiert. So bleiben Build-Werkzeuge und Caches draußen.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    rahmen((0, -1.35), (6.4, 1.55), [Stufe `build` (wird verworfen)], c-grey, bg: luma(250))
    stapel((3.3, -1.0), (([`python:3.14-slim`], c-blue), ([`uv` + Build-Cache], c-grey), ([`.venv` mit Abhängigkeiten], c-blue)), w: 5.6)
    rahmen((8.8, -1.35), (15.2, 1.55), [Stufe `runtime` = fertiges Image], c-blue)
    stapel((12.0, -1.0), (([`python:3.14-slim`], c-blue), ([Benutzer `app`], c-blue), ([`.venv` (kopiert)], c-blue), ([`app/` (Code)], c-blue)), w: 5.4, h: 0.42)
    pfeil((6.45, 0.2), (8.75, 0.2), label: "COPY --from=build", loff: (0, 0.22), color: c-accent)
  }),
  caption: [Nur die virtuelle Umgebung wandert in das fertige Image, uv und der Cache bleiben in der Build-Stufe.],
)

== Das Produktions-Dockerfile

#datei("Dockerfile")[
```dockerfile
# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.14
ARG UV_VERSION=0.12.17                     # feste Version (Stand 18.09.2026)

FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

# ---------- Stufe 1: Abhängigkeiten installieren ----------
FROM python:${PYTHON_VERSION}-slim AS build
COPY --from=uv /uv /bin/uv
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never
WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --locked --no-install-project --no-dev

# ---------- Stufe 2: schlankes Laufzeit-Image ----------
FROM python:${PYTHON_VERSION}-slim AS runtime
RUN groupadd --system --gid 10001 app \
 && useradd --system --uid 10001 --gid app --no-create-home app
WORKDIR /app
COPY --from=build --chown=app:app /app/.venv /app/.venv
COPY --chown=app:app app/ ./app/
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1
USER app
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=2)"]
CMD ["fastapi", "run", "app/main.py", "--port", "8000"]
```
]

Was die einzelnen Teile bewirken:

- *`# syntax=docker/dockerfile:1`* verwendet die aktuelle Dockerfile-Syntax. Sie ist nötig für die `--mount`-Optionen.
- *`ARG` vor dem ersten `FROM`* macht Versionen an einer Stelle änderbar, auch von außen: `docker build --build-arg PYTHON_VERSION=3.14 .`
- *`--mount=type=cache`* hält den Download-Cache von uv zwischen Builds vor, ohne dass er im Image landet. Neue Abhängigkeiten werden nicht jedes Mal komplett neu geladen.
- *`--mount=type=bind`* stellt `pyproject.toml` und `uv.lock` nur für diesen einen Schritt bereit, ohne eine eigene Schicht zu erzeugen.
- *`UV_COMPILE_BYTECODE=1`* erzeugt die `.pyc`-Dateien schon beim Bauen, das beschleunigt den Start.
- *Eigener Benutzer mit fester UID* (Kapitel 12): Der Prozess läuft nicht als `root`. Die feste Nummer erleichtert Rechte auf Volumes und Bind Mounts.
- *`PYTHONUNBUFFERED=1`* sorgt dafür, dass Ausgaben sofort in `docker logs` erscheinen und nicht in einem Puffer hängen.
- *`HEALTHCHECK`* lässt Docker selbst prüfen, ob die Anwendung antwortet. Das slim-Image hat kein `curl`, deshalb erledigt Python den Aufruf.

=== Geheimnisse beim Bauen

Passwörter, Tokens und SSH-Schlüssel dürfen weder über `ARG` oder `ENV` noch mit `COPY` in den Build gelangen: Sie können in Layern, Metadaten oder Cache-Exporten erhalten bleiben. BuildKit stellt sie nur für einen einzelnen `RUN`-Schritt bereit:

```dockerfile
RUN --mount=type=secret,id=pypi_token \
    TOKEN="$(cat /run/secrets/pypi_token)" uv sync --locked
# für private Git-Abhängigkeiten analog: RUN --mount=type=ssh ...
```

```bash
docker build --secret id=pypi_token,src="$HOME/.config/notizen/pypi-token" .
```

Das Geheimnis wird dabei nicht Teil des Images. Der verwendete Befehl darf es allerdings auch nicht selbst in Dateien oder Logs schreiben.

== Versionen festlegen

Reproduzierbare Builds brauchen feste Versionen auf jeder Ebene:

#table(columns: (auto, 1fr),
  [Ebene], [Festlegung],
  [Basis-Image], [beweglicher Versions- und Varianten-Tag (`python:3.14-slim-bookworm`) oder unveränderlicher Digest (`python:3.14-slim-bookworm@sha256:…`)],
  [Werkzeuge], [`ARG UV_VERSION=...` statt `latest`],
  [Python-Pakete], [`uv.lock` mit `uv sync --locked`: Der Build bricht ab, wenn Lockfile und `pyproject.toml` nicht zusammenpassen.],
  [Systempakete], [nur wenn nötig, dann mit `apt-get install --no-install-recommends` und anschließendem Aufräumen von `/var/lib/apt/lists`],
)

Ein Tag bleibt beweglich und liefert Aktualität, aber keine bitgenaue Reproduzierbarkeit. Ein Digest ist unveränderlich, hat jedoch einen Preis: Sicherheitsupdates des Basis-Images kommen nicht mehr automatisch. Wer pinnt, braucht einen Prozess zum Aktualisieren, etwa Renovate mit Pull Requests für neue Digests. Für kleine Projekte ist ein expliziter Python- und Debian-Tag plus regelmäßiges Neubauen pragmatisch; für kontrollierte Releases wird der getestete Digest dokumentiert oder direkt gepinnt.

#tipp[Als weitere Option gibt es _Docker Hardened Images_: minimale, standardmäßig als Nicht-Root ausgelegte Images mit SBOM, Provenance und Signaturen. Sie reduzieren die Angriffsfläche, ersetzen aber keine Kompatibilitäts- und Funktionstests. Für das durchgängige Beispiel bleibt das offizielle Python-Image verständlicher.]

== Metadaten

```dockerfile
LABEL org.opencontainers.image.source="https://gitea.example.com/team/notizen" \
      org.opencontainers.image.version="1.4.0" \
      org.opencontainers.image.revision="3f2a9c1"
```

Die standardisierten `org.opencontainers`-Labels verknüpfen ein Image mit seinem Quellcode. Version und Commit setzt man in der CI per `--label` oder `--build-arg`, damit sie nicht von Hand gepflegt werden müssen (Kapitel 14).

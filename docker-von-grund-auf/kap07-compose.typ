#import "lib.typ": *

= Docker Compose

Spätestens mit zwei Containern, einem Netz und einem Volume werden `docker run`-Befehle unhandlich. Docker Compose beschreibt die ganze Anwendung *deklarativ* in einer Datei: welche Dienste es gibt, aus welchen Images sie entstehen, wie sie verbunden sind und welche Daten sie behalten. Ein einziger Befehl bringt dann alles in genau diesen Zustand.

== Die erste `compose.yaml`

#datei("compose.yaml")[
```yaml
services:
  api:
    build: .                                # Image aus dem Dockerfile im Projekt bauen
    image: notizen:dev
    ports:
      - "127.0.0.1:8000:8000"
    environment:
      DATABASE_URL: postgresql://notizen:${DB_PASSWORD}@db:5432/notizen
    depends_on:
      db:
        condition: service_healthy          # erst starten, wenn die DB bereit ist
    restart: unless-stopped

  db:
    image: postgres:18
    environment:
      POSTGRES_USER: notizen
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: notizen
    volumes:
      - pgdaten:/var/lib/postgresql         # Pfad ab PostgreSQL 18 (Kapitel 5)
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U notizen -d notizen"]
      interval: 5s
      timeout: 3s
      retries: 10
    restart: unless-stopped

volumes:
  pgdaten:
```
]

#datei(".env")[
```ini
DB_PASSWORD=entwicklung
```
]

```bash
docker compose up -d          # alles bauen (falls nötig), anlegen und starten
docker compose ps
curl http://localhost:8000/health
```

Die Datei heißt `compose.yaml` (ältere Projekte nutzen `docker-compose.yml`, beides wird erkannt). Eine Zeile `version: "3.8"` am Anfang ist veraltet und wird nur noch mit einer Warnung ignoriert.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [`docker compose up -d` \ #text(size: 6.5pt)[Projekt `notizen`]], w: 3.0, h: 1.0)
    rahmen((4.0, -1.9), (15.2, 1.9), [erzeugte Ressourcen (Präfix = Projektname)], c-grey, bg: luma(250))
    kasten((6.2, 0.9), [Netz `notizen_default`], w: 3.8, h: 0.6, bg: rgb("#E7F4F2"), col: c-teal, size: 7pt)
    kasten((6.2, 0.0), [Volume `notizen_pgdaten`], w: 3.8, h: 0.6, bg: rgb("#FFF8E6"), col: c-yellow, size: 7pt)
    kasten((6.2, -0.9), [Image `notizen:dev` (gebaut)], w: 3.8, h: 0.6, bg: rgb("#EAF1FB"), col: c-blue, size: 7pt)
    kasten((10.3, 0.0), [`notizen-db-1` \ #text(size: 6.3pt)[wartet auf healthy]], w: 2.3, h: 0.95, bg: rgb("#FDF1EC"), col: c-accent, size: 7pt)
    kasten((13.5, 0.0), [`notizen-api-1`], w: 2.3, h: 0.95, bg: rgb("#FDF1EC"), col: c-accent, size: 7pt)
    pfeil((1.55, 0), (4.25, 0))
    pfeil((11.5, 0), (12.3, 0), label: "dann", loff: (0, 0.2))
  }),
  caption: [Was `docker compose up` anlegt. Der Projektname ist standardmäßig der Verzeichnisname.],
)

Compose leitet einen *Projektnamen* ab, standardmäßig den Namen des Verzeichnisses, und stellt ihn allen Ressourcen voran. Das Netz `notizen_default` entsteht automatisch, alle Dienste der Datei hängen darin und erreichen sich über ihren Dienstnamen (`db`, `api`). Zwei Projekte mit gleichem Verzeichnisnamen würden sich dieselben Ressourcen teilen. Dann hilft `name: notizen` oben in der Datei oder `-p name` beim Aufruf.

== Die Befehle

#table(columns: (auto, 1fr),
  [Befehl], [Wirkung],
  [`docker compose up -d`], [Sollzustand herstellen: fehlende Images bauen, geänderte Container neu erzeugen, starten],
  [`docker compose up -d --build`], [vor dem Start einen Build anstoßen; unveränderte Schichten dürfen aus dem Cache kommen],
  [`docker compose up -d --wait`], [starten und bis `running` beziehungsweise `healthy` warten],
  [`docker compose ps`], [Dienste mit Status und Gesundheit],
  [`docker compose logs -f api`], [Ausgaben eines Dienstes (ohne Name: aller Dienste, farbig getrennt)],
  [`docker compose exec db psql -U notizen`], [Befehl in einem laufenden Dienst ausführen],
  [`docker compose run --rm api pytest`], [Einmal-Container eines Dienstes mit anderem Befehl starten],
  [`docker compose restart api`], [Dienst neu starten (ohne Neuerzeugung, Konfigurationsänderungen greifen *nicht*)],
  [`docker compose stop` / `start`], [anhalten, ohne etwas zu löschen],
  [`docker compose down`], [Container und Netz entfernen. Volumes und Images bleiben.],
  [`docker compose down -v`], [zusätzlich *die Volumes löschen*, also die Datenbank!],
  [`docker compose pull`], [neuere Versionen der Images laden (danach `up -d`)],
  [`docker compose config`], [die vollständig aufgelöste Konfiguration anzeigen],
)

#merke[`docker compose up -d` ist *idempotent*: Es vergleicht Soll- und Istzustand und ändert nur, was nötig ist. Nach jeder Änderung an `compose.yaml`, `.env` oder am Image genügt ein erneutes `up -d`. Ein `restart` übernimmt dagegen keine Konfigurationsänderungen, weil der Container nicht neu erzeugt wird.]

== Variablen: `.env` und `env_file`

Hier gibt es eine Verwechslungsgefahr, die fast jeder einmal erlebt. Es gibt zwei völlig verschiedene Mechanismen:

#table(columns: (auto, 1fr, 1fr),
  [], [`.env` im Projektordner], [`env_file:` in einem Dienst],
  [Wirkt auf], [die `compose.yaml` selbst: ersetzt `${VARIABLE}` beim Einlesen], [den Container: setzt Umgebungsvariablen im laufenden Prozess],
  [Automatisch?], [aus dem Projektverzeichnis; mit `--env-file` lässt sich die Quelle explizit wählen], [nur wenn im Dienst angegeben],
  [Sichtbar im Container?], [nur, was über `environment:` weitergereicht wird], [ja, alle Einträge],
)

```yaml
    environment:
      LOG_LEVEL: ${LOG_LEVEL:-info}                 # mit Standardwert
      SECRET_KEY: ${SECRET_KEY:?SECRET_KEY fehlt}   # Abbruch mit Meldung, wenn nicht gesetzt
    env_file:
      - app.env                                     # alle Zeilen als Variablen in den Container
```

Shell-Variablen, explizite `--env-file`-Dateien und `.env` haben eine festgelegte Priorität. Was Compose aus allen Quellen gemacht hat, zeigen `docker compose config` und `docker compose config --environment`. Das ist der erste Schritt, wenn ein Wert nicht ankommt. Geheimnisse gehören trotzdem nicht in `.env`, weil die aufgelöste Konfiguration und Prozessumgebung sie offenlegen können.

== Startreihenfolge, Healthchecks und Migrationen

`depends_on` allein regelt nur die *Startreihenfolge*: Die Datenbank wird zuerst gestartet, ist aber in dem Moment noch lange nicht bereit, Verbindungen anzunehmen. Erst `condition: service_healthy` wartet beim Start, bis der Healthcheck des anderen Dienstes erfolgreich ist. Das ist keine dauerhafte Selbstheilung: Wird ein laufender Container später `unhealthy`, startet ihn Docker deshalb nicht automatisch neu. Eine Restart Policy greift erst, wenn sein Hauptprozess endet. Deshalb braucht jede Datenbank im Compose-Projekt einen Healthcheck, und die Anwendung muss vorübergehende Verbindungsfehler selbst mit Retries behandeln.

Datenbank-Migrationen, etwa mit Alembic, laufen am saubersten als eigener Einmal-Dienst, der vor der API fertig sein muss:

```yaml
  migrate:
    image: notizen:dev
    command: ["alembic", "upgrade", "head"]
    environment:
      DATABASE_URL: postgresql://notizen:${DB_PASSWORD}@db:5432/notizen
    depends_on:
      db:
        condition: service_healthy
    restart: "no"

  api:
    # ...
    depends_on:
      migrate:
        condition: service_completed_successfully
```

Schlägt die Migration fehl, startet die API gar nicht erst. Das ist genau richtig, denn eine neue Version gegen ein altes Datenbankschema laufen zu lassen, führt zu schwer verständlichen Fehlern.

Seit Compose 5.3 kann ein Dienst alternativ über `pre_start` einen Initialisierungsschritt unmittelbar vor seinem Hauptprozess ausführen. Für kleine lokale Setups ist das kompakt. Ein eigener Migrations-Dienst bleibt für Produktion oft klarer, weil sein einmaliger Status sichtbar ist und mehrere API-Replikate nicht gleichzeitig dieselbe Migration starten.

== Entwickeln mit Compose Watch

Für die Entwicklung soll eine Codeänderung sofort wirken, ohne Neubau. `develop: watch` synchronisiert geänderte Dateien in den laufenden Container und baut nur neu, wenn sich die Abhängigkeiten ändern:

```yaml
  api:
    build: .
    command: ["fastapi", "dev", "app/main.py", "--host", "0.0.0.0", "--port", "8000"]
    develop:
      watch:
        - action: sync             # Code: Dateien in den Container kopieren
          path: ./app
          target: /app/app
        - action: rebuild          # Abhängigkeiten: Image neu bauen
          path: uv.lock
```

```bash
docker compose up --watch        # startet alles und überwacht die Pfade
```

`fastapi dev` lädt die Anwendung bei jeder synchronisierten Änderung neu. Gegenüber einem Bind Mount hat das den Vorteil, dass keine Dateien vom Container zurück auf den Mac geschrieben werden und das Verhalten auf allen Rechnern gleich ist.

== Profile: optionale Dienste

Werkzeuge wie eine Datenbank-Oberfläche sollen nur bei Bedarf laufen. Dienste mit einem Profil startet Compose nur, wenn das Profil ausdrücklich aktiviert wird:

```yaml
  adminer:
    image: adminer
    ports: ["127.0.0.1:8081:8080"]
    profiles: [werkzeuge]
```

```bash
docker compose --profile werkzeuge up -d
```

== Entwicklung und Produktion trennen

Die `compose.yaml` im Repository ist auf die Entwicklung ausgelegt: Sie baut das Image selbst, veröffentlicht die API direkt und nutzt ein einfaches Passwort. Auf dem Server gelten andere Regeln: Das Image kommt fertig aus der Registry, davor steht ein Reverse Proxy, Passwörter liegen in Dateien. Dafür gibt es zwei Wege:

- *Eine eigene Datei für die Produktion*, im Repository als `compose.prod.yaml` gepflegt und auf dem Server als `compose.yaml` abgelegt. Übersichtlich, weil man auf dem Server genau sieht, was läuft. Diesen Weg nutzt Kapitel 13.
- *Überlagerung mehrerer Dateien*: `docker compose -f compose.yaml -f compose.prod.yaml up -d` führt beide zusammen, spätere Dateien überschreiben frühere. Eine Datei `compose.override.yaml` wird sogar automatisch dazugenommen. Das spart Wiederholungen, macht aber schwerer nachvollziehbar, was am Ende gilt. Dann hilft wieder `docker compose config`.

#import "lib.typ": *

= Container benutzen

Bevor es um eigene Images geht, lohnt es sich, mit fertigen Images vertraut zu werden: Container starten, beobachten, in sie hineinschauen und wieder aufräumen. Alle Beispiele nutzen offizielle Images von Docker Hub.

== `docker run` im Detail

`docker run` lädt das Image (falls nicht vorhanden), legt einen Container an und startet ihn. Die Optionen stehen *vor* dem Image-Namen, alles *nach* dem Image-Namen ist der Befehl, der im Container ausgeführt wird.

```bash
docker run -d --name db \
  -e POSTGRES_PASSWORD=geheim \
  -p 127.0.0.1:5432:5432 \
  -v pgdaten:/var/lib/postgresql \
  --restart unless-stopped \
  postgres:18
```

#table(columns: (auto, 1fr),
  [Option], [Bedeutung],
  [`-d`], [im Hintergrund starten (_detached_), statt die Ausgabe im Terminal zu zeigen],
  [`--name db`], [fester Name. Ohne ihn vergibt Docker Zufallsnamen wie `eager_turing`.],
  [`-e NAME=wert`], [Umgebungsvariable setzen, der übliche Weg, Container zu konfigurieren],
  [`-p 127.0.0.1:5432:5432`], [Port veröffentlichen: _Host-Adresse:Host-Port:Container-Port_ (Kapitel 6)],
  [`-v pgdaten:/var/lib/postgresql`], [Volume `pgdaten` an diesen Pfad im Container einbinden (Kapitel 5)],
  [`--restart unless-stopped`], [nach Absturz oder Neustart des Daemons automatisch wieder starten],
  [`--rm`], [Container nach dem Beenden automatisch löschen, ideal für Einmal-Aufgaben],
  [`-it`], [interaktiv mit Terminal, z.B. für eine Shell: `docker run --rm -it python:3.14-slim bash`],
)

== Der Lebenszyklus eines Containers

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let z(x, y, t, c) = kasten((x, y), t, w: 2.2, h: 0.75, bg: c.lighten(88%), col: c, size: 7.5pt)
    z(0, 0, [*created*], c-grey); z(4.5, 0, [*running*], c-accent); z(9, 0, [*exited*], c-grey); z(13.5, 0, [*entfernt*], c-dark)
    z(4.5, -1.8, [*paused*], c-yellow)
    pfeil((1.1, 0.12), (3.4, 0.12), label: "start", loff: (0, 0.2))
    pfeil((5.6, 0.12), (7.9, 0.12), label: "stop / Ende", loff: (0, 0.2))
    pfeil((7.9, -0.18), (5.6, -0.18), label: "start", loff: (0, -0.2), color: c-grey.darken(20%))
    pfeil((10.1, 0.12), (12.4, 0.12), label: "rm", loff: (0, 0.2))
    pfeil((4.3, -0.38), (4.3, -1.42), label: "pause", loff: (-0.5, 0), color: c-grey.darken(20%))
    pfeil((4.7, -1.42), (4.7, -0.38), label: "unpause", loff: (0.65, 0), color: c-grey.darken(20%))
    content((2.2, 0.95), text(font: "JetBrains Mono", size: 6.8pt, weight: "bold")[docker run = create + start])
  }),
  caption: [Zustände eines Containers. Ein gestoppter Container existiert weiter, bis er entfernt wird.],
)

Ein gestoppter Container ist nicht weg: Er behält seine Schreibschicht und seine Konfiguration und kann mit `docker start` fortgesetzt werden. Erst `docker rm` entfernt ihn. Deshalb sammeln sich ohne `--rm` mit der Zeit viele gestoppte Container an.

== Die wichtigsten Befehle

#table(columns: (auto, 1fr),
  [Befehl], [Wirkung],
  [`docker ps`], [laufende Container anzeigen (`-a` zusätzlich gestoppte)],
  [`docker logs -f db`], [Ausgaben des Hauptprozesses fortlaufend anzeigen (`--tail 100`, `--since 10m`)],
  [`docker exec -it db bash`], [Befehl in einem *laufenden* Container ausführen, hier eine Shell],
  [`docker stop db` / `start` / `restart`], [anhalten (erst SIGTERM, nach 10 s SIGKILL), fortsetzen, neu starten],
  [`docker rm db`], [gestoppten Container entfernen (`-f` stoppt vorher)],
  [`docker inspect db`], [vollständige Konfiguration als JSON: IP, Mounts, Umgebung, Status],
  [`docker stats`], [CPU-, Speicher- und Netzwerkverbrauch live],
  [`docker top db`], [Prozesse im Container],
  [`docker cp db:/pfad/datei .`], [Dateien zwischen Container und Mac kopieren],
  [`docker port db`], [veröffentlichte Ports anzeigen],
)

Viele Namen sind abkürzbar: Statt des Namens funktioniert auch der Anfang der Container-ID (`docker logs 3f2a`). Die Formatierung von `docker ps` lässt sich anpassen, was für eine kompakte Übersicht praktisch ist:

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
```

=== `run` oder `exec`?

Ein häufiges Missverständnis: `docker run` startet immer einen *neuen* Container. Wer in einem bereits laufenden Container etwas nachsehen will, braucht `docker exec`. Beispiel mit der Datenbank von oben:

```bash
docker exec -it db psql -U postgres        # psql im laufenden DB-Container
```
```out
psql (18.0 (Debian 18.0-1.pgdg13+1))
Type "help" for help.

postgres=#
```

`docker exec` funktioniert nur, solange der Container läuft, und die Shell muss im Image vorhanden sein. Schlanke Images enthalten oft kein `bash`, dann hilft `sh`. Minimale Images (_distroless_) enthalten gar keine Shell (Kapitel 8 und 10).

== Umgebungsvariablen und Konfiguration

Container werden fast immer über Umgebungsvariablen konfiguriert. Welche ein Image versteht, steht in seiner Dokumentation auf Docker Hub. Bei vielen Variablen ist eine Datei übersichtlicher:

#datei(".env.db")[
```ini
POSTGRES_USER=notizen
POSTGRES_PASSWORD=entwicklung
POSTGRES_DB=notizen
```
]

```bash
docker run -d --name db --env-file .env.db -v pgdaten:/var/lib/postgresql postgres:18
```

#achtung[Umgebungsvariablen sind für jeden sichtbar, der `docker inspect` ausführen darf, und landen leicht in Logs. Für Passwörter in Produktion gibt es bessere Wege (Kapitel 12). Dateien wie `.env.db` gehören in die `.gitignore`.]

== Neustart-Richtlinien

#table(columns: (auto, 1fr),
  [`--restart`], [Verhalten],
  [`no`], [nie automatisch neu starten (Standard)],
  [`on-failure[:5]`], [nur bei Exit-Code ungleich 0, optional höchstens fünfmal],
  [`unless-stopped`], [immer, außer der Container wurde bewusst gestoppt. *Empfohlen für Dienste.*],
  [`always`], [immer, auch nach einem bewussten Stopp, sobald der Daemon neu startet],
)

== Aufräumen

Images, gestoppte Container, ungenutzte Netzwerke und der Build-Cache belegen mit der Zeit viel Platz:

```bash
docker system df                 # Übersicht: wie viel belegt was?
docker container prune           # alle gestoppten Container löschen
docker image prune               # "dangling" Images löschen (ohne Tag)
docker image prune -a            # alle Images löschen, die kein Container nutzt
docker builder prune             # Build-Cache leeren
docker system prune              # gestoppte Container, ungenutzte Netze, Images ohne Tag, Build-Cache
```

#achtung[`docker volume prune` und `docker system prune --volumes` entfernen standardmäßig ungenutzte *anonyme* Volumes. Benannte Volumes werden erst mit `docker volume prune -a` entfernt; `docker compose down -v` entfernt die im Projekt verwendeten benannten und anonymen Volumes. Vor jedem Löschen mit `docker volume ls` beziehungsweise `docker compose config --volumes` prüfen, was betroffen ist.]

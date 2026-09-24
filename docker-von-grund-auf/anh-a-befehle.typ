#import "lib.typ": *

#set page(margin: (x: 1.7cm, top: 2.2cm, bottom: 1.9cm))
= Befehlsübersicht

#let blk(titel, ..rows) = block(breakable: false, below: 0.75em, width: 100%)[
  #text(size: 8pt, weight: "bold", fill: c-accent, upper(titel))
  #v(-0.45em)
  #set text(size: 7.6pt)
  #show table: set text(size: 7.6pt)
  #show raw: it => text(font: "JetBrains Mono", size: 6.9pt, fill: rgb("#2a2d33"), ligatures: false, features: (calt: 0), it.text)
  #show table.cell.where(y: 0): set text(weight: "regular")
  #table(columns: (1.35fr, 1fr), inset: (x: 3pt, y: 2.1pt),
    fill: (x, y) => if x == 0 { luma(246) } else { none },
    stroke: (x, y) => (bottom: 0.4pt + luma(222)),
    ..rows.pos().map(r => (r.at(0), r.at(1))).flatten())
]

#columns(2, gutter: 14pt)[
#blk("Colima und Kontexte",
  ([`colima start` / `stop` / `status`], [VM starten, stoppen, Zustand]),
  ([`colima start --edit`], [Konfiguration ändern]),
  ([`brew services start colima`], [Autostart bei Anmeldung]),
  ([`docker context ls` / `use colima`], [Kontexte anzeigen / wechseln]),
)
#blk("Container",
  ([`docker run -d --name x -p 127.0.0.1:8000:8000 img`], [im Hintergrund starten]),
  ([`docker run --rm -it img sh`], [Wegwerf-Container mit Shell]),
  ([`docker ps -a`], [alle Container]),
  ([`docker logs -f --tail 100 x`], [Ausgaben verfolgen]),
  ([`docker exec -it x sh`], [Shell im laufenden Container]),
  ([`docker stop` / `start` / `rm x`], [anhalten / fortsetzen / entfernen]),
  ([`docker inspect x`], [Details als JSON]),
  ([`docker stats`], [Ressourcenverbrauch live]),
  ([`docker cp x:/pfad .`], [Dateien herauskopieren]),
)
#blk("Images",
  ([`docker build -t name:tag .`], [Image bauen]),
  ([`docker build --no-cache --pull ...`], [komplett neu, Basis frisch]),
  ([`docker image ls` / `history img`], [Images / Schichten]),
  ([`docker tag a b`], [zweiten Namen vergeben]),
  ([`docker push` / `pull name:tag`], [hoch- / herunterladen]),
  ([`docker login gitea.example.com`], [an Registry anmelden]),
)
#blk("Volumes und Netze",
  ([`docker volume ls` / `inspect v`], [Volumes anzeigen]),
  ([`docker volume rm v`], [Volume löschen (!)]),
  ([`docker network create n`], [Netz mit Namensauflösung]),
  ([`docker network inspect n`], [Teilnehmer und IPs]),
  ([`docker run --rm -it --network n nicolaka/netshoot`], [Netzwerk-Werkzeuge]),
)
#blk("Mehrere Plattformen",
  ([`docker build --platform linux/amd64 ...`], [für x86 bauen]),
  ([`docker buildx create --name multi --driver docker-container --use`], [Builder anlegen]),
  ([`docker buildx build --platform linux/amd64,linux/arm64 --push ...`], [Multi-Plattform-Image]),
  ([`docker buildx imagetools inspect img`], [Varianten prüfen]),
)
#blk("Compose",
  ([`docker compose up -d`], [Sollzustand herstellen]),
  ([`docker compose up -d --build`], [Build anstoßen, Cache erlaubt]),
  ([`docker compose up -d --wait`], [starten und auf Health warten]),
  ([`docker compose up --watch`], [Entwicklung mit Sync]),
  ([`docker compose ps` / `logs -f api`], [Status / Logs]),
  ([`docker compose exec db psql -U notizen`], [in laufendem Dienst]),
  ([`docker compose run --rm api pytest`], [Einmal-Befehl]),
  ([`docker compose pull`], [neue Images laden]),
  ([`docker compose config`], [aufgelöste Konfiguration]),
  ([`docker compose down`], [entfernen, Daten bleiben]),
  ([`docker compose down -v`], [inkl. Volumes (!)]),
  ([`docker compose --profile werkzeuge up -d`], [optionale Dienste]),
)
#blk("Fehlersuche",
  ([`docker compose run --rm --entrypoint sh api`], [Shell trotz Absturz]),
  ([`docker inspect -f '{{.State.ExitCode}}' x`], [Exit-Code]),
  ([`docker inspect -f '{{json .State.Health}}' x`], [Healthcheck-Verlauf]),
  ([`docker events --since 10m`], [Ereignisse des Daemons]),
)
#blk("Aufräumen und Sicherung",
  ([`docker system df`], [Platzverbrauch]),
  ([`docker system prune`], [Ungenutztes löschen (ohne Volumes)]),
  ([`docker volume prune -a`], [alle ungenutzten Volumes (!)]),
  ([`docker image prune -a`], [alle ungenutzten Images]),
  ([`docker exec db pg_dump -U u -Fc db > x.dump`], [Datenbank sichern]),
  ([`trivy image name@sha256:...`], [exakten Digest prüfen]),
)
]

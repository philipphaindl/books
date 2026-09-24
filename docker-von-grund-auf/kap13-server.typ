#import "lib.typ": *

= Betrieb auf dem Server

Am Ende soll die Anwendung auf einem Linux-Server laufen: erreichbar über HTTPS, mit gesicherten Daten, sauberen Logs und einem einfachen Weg zu Updates und Rollbacks. Für eine Anwendung dieser Größe genügt ein einzelner Server mit Docker Compose vollkommen.

== Docker Engine installieren

Auf dem Server wird kein Docker Desktop gebraucht, sondern die Docker Engine aus dem offiziellen Paket-Repository von Docker. Die Pakete der Distribution (`docker.io`) sind oft veraltet, das Komfortskript `get.docker.com` ist für Testrechner gedacht. Für Debian sieht die Installation so aus (Ubuntu analog, aktuelle Fassung auf docs.docker.com prüfen):

```bash
sudo apt-get update && sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
. /etc/os-release
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $VERSION_CODENAME
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo docker run --rm hello-world
```

Docker Engine 29 bevorzugt cgroup v2 und hat cgroup v1 als veraltet markiert. Auf einem neuen Server zeigt `docker info --format '{{.CgroupVersion}}'` deshalb `2`. Bestehende Systeme mit cgroup v1 werden vor einer späteren Entfernung des Supports auf cgroup v2 migriert; für Engine 29 ist noch keine sofortige Abschaltung nötig.

=== Grundkonfiguration des Daemons

#datei("/etc/docker/daemon.json")[
```json
{
  "log-driver": "local",
  "log-opts": { "max-size": "20m", "max-file": "5" },
  "live-restore": true
}
```
]

```bash
sudo systemctl restart docker
```

Ohne Begrenzung schreibt Docker die Ausgaben jedes Containers unbegrenzt auf die Platte, bis sie voll ist. Der Treiber `local` rotiert und komprimiert die Logs, hier auf höchstens fünf Dateien mit je 20 MB pro Container. `live-restore` kann Container während eines Daemon-Neustarts oder kompatiblen Patch-Updates weiterlaufen lassen. Bei einem Major-Upgrade oder Änderungen an Storage-Treiber, Bridge-Netz oder anderen Daemon-Optionen gilt diese Garantie nicht. Die Einstellungen gelten nur für neu erzeugte Container.

== Aufbau auf dem Server

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    rahmen((1.0, -2.3), (15.4, 1.9), [Server `app.example.com`], c-grey, bg: luma(250))
    kasten((-0.4, -0.2), [Internet \ #text(size: 6.5pt)[Port 443]], w: 1.4, h: 0.9, size: 7pt)
    rahmen((1.5, -1.95), (15.1, 1.45), [Netz `notizen_default`], c-teal)
    kasten((3.0, -0.2), [`caddy` \ #text(size: 6.3pt)[TLS, Reverse Proxy]], w: 2.3, h: 1.0, bg: rgb("#FDF1EC"), col: c-accent, size: 7.3pt)
    kasten((7.0, -0.2), [`api` \ #text(size: 6.3pt)[kein Port nach außen]], w: 2.3, h: 1.0, bg: rgb("#FDF1EC"), col: c-accent, size: 7.3pt)
    kasten((10.6, -0.2), [`db`], w: 1.6, h: 1.0, bg: rgb("#FDF1EC"), col: c-accent, size: 7.3pt)
    kasten((13.5, 0.55), [`pgdaten`], w: 2.1, h: 0.6, bg: rgb("#FFF8E6"), col: c-yellow, size: 7pt)
    kasten((13.5, -0.95), [`caddy_data`], w: 2.1, h: 0.6, bg: rgb("#FFF8E6"), col: c-yellow, size: 7pt)
    pfeil((0.35, -0.2), (1.8, -0.2), label: "443", loff: (0, 0.2))
    pfeil((4.2, -0.2), (5.8, -0.2), label: "api:8000", loff: (0, 0.22), color: c-teal)
    pfeil((8.2, -0.2), (9.75, -0.2), label: "db:5432", loff: (0, 0.22), color: c-teal)
    line((11.45, 0.05), (12.4, 0.55), stroke: c-yellow.darken(10%) + 0.8pt)
    line((3.0, -0.72), (3.0, -1.25), (12.4, -1.25), (12.4, -0.95), stroke: (paint: c-yellow.darken(10%), thickness: 0.8pt, dash: "dashed"))
  }),
  caption: [Nur Caddy ist von außen erreichbar. API und Datenbank sprechen im internen Netz miteinander.],
)

Das Projekt liegt in einem eigenen Verzeichnis, typischerweise unter `/srv`:

#datei("Verzeichnisstruktur auf dem Server")[
```text
/srv/notizen/
├── compose.yaml          # Kopie von compose.prod.yaml aus dem Repository
├── .env                  # IMAGE_REF=...@sha256:... und weitere, nicht geheime Werte
├── Caddyfile
├── secrets/
│   └── db_passwort.txt   # Besitzer 10001:10001, Modus 0400
├── deploy.sh             # wird von der CI per SSH aufgerufen (Kapitel 14)
└── backups/
```
]

== Reverse Proxy mit automatischem HTTPS

Ein Reverse Proxy nimmt alle Anfragen auf Port 80 und 443 entgegen, kümmert sich um die TLS-Zertifikate und leitet an die Anwendung weiter. *Caddy* ist dafür besonders einfach: Er holt und erneuert Let's-Encrypt-Zertifikate selbstständig, sobald der DNS-Eintrag auf den Server zeigt. Die komplette Konfiguration für eine Domain:

#datei("Caddyfile")[
```text
app.example.com {
    reverse_proxy api:8000
    encode zstd gzip
}
```
]

== Die Produktions-Compose-Datei

#datei("/srv/notizen/compose.yaml")[
```yaml
name: notizen

services:
  caddy:
    image: caddy:2
    ports: ["80:80", "443:443"]
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data                          # Zertifikate: unbedingt persistent!
      - caddy_config:/config
    restart: unless-stopped

  api:
    image: ${IMAGE_REF:?IMAGE_REF fehlt}
    environment:
      DB_HOST: db
      DB_PASSWORD_FILE: /run/secrets/db_passwort
    secrets: [db_passwort]
    read_only: true
    tmpfs: [/tmp]
    cap_drop: [ALL]
    security_opt: ["no-new-privileges:true"]
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: postgres:18
    environment:
      POSTGRES_USER: notizen
      POSTGRES_DB: notizen
      POSTGRES_PASSWORD_FILE: /run/secrets/db_passwort
    secrets: [db_passwort]
    volumes:
      - pgdaten:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U notizen -d notizen"]
      interval: 10s
      retries: 10
    restart: unless-stopped

secrets:
  db_passwort:
    file: ./secrets/db_passwort.txt

volumes:
  pgdaten:
  caddy_data:
  caddy_config:
```
]

Die freigegebene Image-Referenz steht nicht in der Datei, sondern kommt über `IMAGE_REF` aus der `.env`, zum Beispiel `gitea.example.com/team/notizen@sha256:…`. Der Digest bezeichnet unveränderlich exakt das in der CI geprüfte Image. Ein Update oder Applikations-Rollback ändert damit genau eine Zeile. Das `:?` sorgt dafür, dass Compose bei fehlendem Wert abbricht.

Die Tags `caddy:2` und `postgres:18` erhalten Sicherheitsupdates und sind deshalb beweglich. Sie werden nicht ungeprüft bei jedem API-Deployment aktualisiert, sondern in einem eigenen Wartungsfenster gezogen, getestet und bei streng reproduzierbaren Umgebungen zusätzlich über einen dokumentierten Digest festgelegt. Für das selbst gebaute API-Image wird nach der CI der konkrete Registry-Digest protokolliert.

Das file-basierte Secret muss für den Anwendungsbenutzer lesbar sein; `uid`, `gid` und `mode` im Compose-Eintrag würden bei `file:` nicht helfen. Die Einrichtung aus Kapitel 12 setzt deshalb den numerischen Besitzer auf UID 10001. Vor dem ersten Start prüfen:

```bash
docker compose run --rm api test -r /run/secrets/db_passwort
docker compose run --rm db test -r /run/secrets/db_passwort
```

== Updates und Rollbacks

```bash
cd /srv/notizen
sed -i 's|^IMAGE_REF=.*|IMAGE_REF=gitea.example.com/team/notizen@sha256:...|' .env
docker compose pull api                           # nur das neue API-Image laden
docker compose up -d --wait --wait-timeout 60 api # API umstellen und auf Health warten
docker compose ps && docker compose logs --tail 30 api
```

Alte API-Images bleiben zunächst für einen schnellen Rollback lokal vorhanden und werden erst nach der festgelegten Aufbewahrungsfrist durch eine getrennte Wartungsaufgabe entfernt.

Ein Applikations-Rollback ist derselbe Ablauf mit der vorherigen Version, solange die Datenbank dazu kompatibel bleibt. Datenbankänderungen werden deshalb nach dem Expand/Contract-Muster gebaut: zunächst nur additive, rückwärtskompatible Änderungen; Entfernen alter Spalten erst in einem späteren Release. Ein Dump ist die Notfallabsicherung, aber kein schneller automatischer Rollback einer laufenden Migration. In der Praxis erledigt diese Schritte die CI (Kapitel 14), von Hand macht man sie nur im Notfall.

#achtung[Das früher beliebte Werkzeug _Watchtower_, das laufende Container automatisch auf neue Images aktualisiert, wurde im Dezember 2025 archiviert und wird nicht mehr gepflegt. Automatische Updates ohne Tests und ohne Backup sind für eigene Anwendungen ohnehin riskant. Besser: Deployments über die CI, und für Basis-Images wie `postgres` oder `caddy` nur *benachrichtigen* lassen, etwa mit dem Werkzeug _Diun_, und bewusst aktualisieren.]

== Backups

Ein Skript sichert die Datenbank täglich und behält die Sicherungen der letzten 14 Tage:

#datei("/srv/notizen/backup.sh")[
```bash
#!/usr/bin/env bash
set -euo pipefail
umask 077
cd /srv/notizen
mkdir -p backups
exec 9>backups/.backup.lock
flock -n 9 || { echo "Backup läuft bereits" >&2; exit 1; }
zeit="$(date -u +%Y%m%dT%H%M%SZ)"
tmp="backups/.notizen-$zeit.dump.tmp"
datei="backups/notizen-$zeit.dump"
trap 'rm -f "$tmp"' EXIT
docker compose exec -T db pg_dump -U notizen -Fc notizen > "$tmp"
docker compose exec -T db pg_restore -l < "$tmp" >/dev/null
mv "$tmp" "$datei"
trap - EXIT
find backups/ -name 'notizen-*.dump' -mtime +14 -delete
```
]

```bash
chmod 700 /srv/notizen/backup.sh
crontab -e
# Eintrag: täglich um 3:15 Uhr
15 3 * * * /srv/notizen/backup.sh >> /srv/notizen/backups/backup.log 2>&1
```

Das `-T` bei `exec` schaltet das Terminal ab, sonst beschädigt Compose die Binärdaten des Dumps. Zeit bis auf die Sekunde verhindert, dass zwei Deployments am selben Tag dieselbe Datei überschreiben; temporäre Datei und `pg_restore -l` verhindern, dass ein unvollständiger Dump wie ein gültiges Backup aussieht. Rollen und Tablespaces werden bei Bedarf zusätzlich mit `pg_dumpall --globals-only` gesichert. Ein Backup auf demselben Server schützt nur vor Bedienfehlern, nicht vor dessen Ausfall. Die Dumps gehören deshalb verschlüsselt an einen zweiten Ort, etwa mit `restic` auf eine NAS oder in Object Storage. Der Backup-Job wird überwacht, und mindestens quartalsweise wird ein Dump in eine frische Datenbank eingespielt.

== Beobachten

#table(columns: (auto, 1fr),
  [Befehl], [Zweck],
  [`docker compose ps`], [Laufen alle Dienste, sind sie _healthy_?],
  [`docker compose logs --since 1h api`], [Ausgaben der letzten Stunde],
  [`docker stats --no-stream`], [aktueller Verbrauch von CPU und Speicher pro Container],
  [`docker system df`], [Platzverbrauch von Images, Volumes, Build-Cache],
  [`df -h /var/lib/docker`], [freier Platz auf der Partition mit den Docker-Daten],
)

Für mehr als einen Blick von Hand lohnt sich ein externer Uptime-Monitor, der die Health-Route der Anwendung regelmäßig von außen aufruft und bei Ausfall benachrichtigt (etwa _Uptime Kuma_, selbst als Container auf einem anderen Rechner betrieben).

#praxis[*Synology:* Der _Container Manager_ versteht Compose-Dateien als _Projekte_, doch Engine-/Compose-Version, CPU-Architektur, Dateirechte und unterstützte Felder hängen vom DSM-Modell und Release ab. Deshalb `docker version`, `docker compose version` und `docker compose config` vorab prüfen. Der Weg über SSH und `docker compose` ist gut dokumentierbar; Bind Mounts legt man bevorzugt unter `/volume1/docker/<projekt>` an und bezieht sie ausdrücklich in das NAS-Backup ein.]

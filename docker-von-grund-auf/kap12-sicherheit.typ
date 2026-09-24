#import "lib.typ": *

= Sicherheit

Container isolieren gut, aber nicht vollständig: Sie teilen sich den Kernel des Hosts, und die Standardeinstellungen sind auf Bequemlichkeit ausgelegt, nicht auf minimale Rechte. Dieses Kapitel sammelt die Maßnahmen, die mit wenig Aufwand viel bringen.

== Der Docker-Socket ist Root

Wer Befehle an den Docker-Daemon schicken darf, kann einen Container starten, der das komplette Dateisystem des Hosts einbindet, und hat damit volle Kontrolle über den Rechner:

```bash
docker run --rm -it -v /:/host alpine chroot /host sh     # Root-Shell auf dem Host
```

Daraus folgen drei Regeln. *Erstens:* Die Gruppe `docker` auf einem Server ist gleichbedeutend mit `sudo` und wird entsprechend sparsam vergeben. *Zweitens:* `/var/run/docker.sock` wird nie in einen Container eingebunden, außer das Werkzeug braucht ihn zwingend und ist vertrauenswürdig (etwa ein CI-Runner auf einem eigenen Rechner, siehe Git-Handbuch Kapitel 14). *Drittens:* Der Daemon wird nie per TCP ohne TLS im Netz erreichbar gemacht.

Wer die Gefahr grundsätzlich verringern will, kann Docker im _Rootless-Modus_ betreiben: Daemon und Container laufen dann als normaler Benutzer. Das hat Einschränkungen (etwa bei Ports unter 1024 und beim Netzwerk), ist für viele Anwendungen aber gut nutzbar.

== Minimale Rechte im Container

#datei("compose.prod.yaml (Auszug)")[
```yaml
  api:
    image: gitea.example.com/team/notizen:1.4.0
    user: "10001:10001"                 # nicht als root (steht meist schon im Image)
    read_only: true                     # Dateisystem des Containers schreibgeschützt
    tmpfs:
      - /tmp                            # beschreibbar, aber nur im Arbeitsspeicher
    cap_drop: [ALL]                     # alle Kernel-Sonderrechte entziehen
    security_opt:
      - no-new-privileges:true          # keine Rechteausweitung über setuid-Programme
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M                  # bei Überschreitung: Abbruch mit Exit-Code 137
    pids_limit: 200
```
]

#table(columns: (auto, 1fr),
  [Maßnahme], [Schutzwirkung],
  [Nicht-Root-Benutzer], [Eine Lücke in der Anwendung führt nicht zu Root-Rechten im Container, ein Ausbruch aus dem Container ist deutlich schwerer.],
  [`read_only`], [Ein Angreifer kann keine Programme im Container ablegen oder Dateien der Anwendung verändern.],
  [`cap_drop: [ALL]`], [Root im Container verliert Sonderrechte wie Netzwerkkonfiguration oder das Ändern von Dateibesitzern. Einzelne Rechte lassen sich mit `cap_add` gezielt zurückgeben.],
  [`no-new-privileges`], [Verhindert, dass ein Prozess über setuid-Programme mehr Rechte bekommt.],
  [Ressourcenlimits], [Ein Speicherleck oder eine Endlosschleife legt nicht den ganzen Server lahm.],
)

Nicht jede Anwendung verträgt alle Maßnahmen. Die offiziellen Datenbank-Images etwa wechseln beim Start selbst den Benutzer und brauchen dafür Rechte. Das Vorgehen ist deshalb: alles setzen, starten, Logs lesen und nur zurücknehmen, was nachweislich gebraucht wird.

== Geheimnisse

Umgebungsvariablen sind der übliche Weg, Container zu konfigurieren, für Passwörter aber nicht ideal: Sie erscheinen in `docker inspect`, werden an Kindprozesse vererbt und landen in Fehlerberichten. Besser sind Dateien, die nur im Container sichtbar sind. Compose bietet dafür `secrets`:

```yaml
services:
  db:
    image: postgres:18
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_passwort    # offizielle Images kennen *_FILE
    secrets: [db_passwort]
  api:
    image: gitea.example.com/team/notizen:1.4.0
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_passwort
    secrets: [db_passwort]

secrets:
  db_passwort:
    file: ./secrets/db_passwort.txt                        # nur auf dem Server, nie im Git
```

Compose stellt die Datei im Container unter `/run/secrets/db_passwort` bereit. Bei einer lokalen `file:`-Quelle ist das technisch ein schreibgeschützter Bind Mount - kein verschlüsselter Secret-Speicher. Viele offizielle Images (PostgreSQL, MariaDB) verstehen die Konvention `VARIABLE_FILE` bereits. Die eigene Anwendung muss das Passwort selbst aus der Datei lesen:

#datei("app/db.py (Auszug)")[
```python
import os
from pathlib import Path

def db_passwort() -> str:
    if datei := os.environ.get("DB_PASSWORD_FILE"):
        return Path(datei).read_text().strip()
    return os.environ["DB_PASSWORD"]     # Fallback für die Entwicklung
```
]

Bei file-basierten Compose-Secrets werden die optionalen Angaben `uid`, `gid` und `mode` nicht umgesetzt; Besitzer und Modus der Host-Datei gelten auch im Container. Im Beispiel läuft die API als UID 10001. Die Datei wird deshalb rootgeschützt angelegt und gezielt für diese UID lesbar gemacht:

```bash
sudo install -d -o root -g root -m 0711 /srv/notizen/secrets
openssl rand -base64 32 | sudo tee /srv/notizen/secrets/db_passwort.txt >/dev/null
sudo chown 10001:10001 /srv/notizen/secrets/db_passwort.txt
sudo chmod 0400 /srv/notizen/secrets/db_passwort.txt
docker compose run --rm api test -r /run/secrets/db_passwort
```

Das PostgreSQL-Image liest sein `_FILE`-Secret während der Initialisierung mit Root-Rechten. Nutzen mehrere Nicht-Root-Dienste dasselbe Geheimnis, braucht es getrennte Dateien, eine gemeinsame numerische Gruppe oder passende ACLs. Die Dateien gehören nie in die Versionsverwaltung.

== Images auf Schwachstellen prüfen

Basis-Images und Python-Pakete enthalten regelmäßig bekannte Sicherheitslücken. Ein Scanner vergleicht den Inhalt eines Images mit Schwachstellen-Datenbanken:

```bash
brew install trivy
trivy image notizen:1.4.0                                  # alle Befunde
trivy image --severity HIGH,CRITICAL notizen:1.4.0
trivy image --exit-code 1 --exit-on-eol --severity CRITICAL notizen:1.4.0
```

Nicht behobene Lücken sind nicht automatisch irrelevant: Man kann das betroffene Paket entfernen, das Basis-Image wechseln, die Funktion abschalten oder das Risiko vorübergehend dokumentieren. Die CI blockiert im Beispiel behebbare und nicht behebbare kritische Findings; begründete Ausnahmen werden eng befristet und nachvollziehbar gepflegt. `--exit-on-eol` verhindert außerdem, dass ein nicht mehr unterstütztes Betriebssystem unbemerkt weiterläuft. Die wirksamste Routine bleibt: *regelmäßig neu bauen und erneut prüfen*.

== Herkunft und Integrität von Images

Ein Digest schützt davor, dass sich ein bereits ausgewählter Inhalt verändert, sagt aber noch nicht, wer ihn gebaut hat. Docker Content Trust wurde mit Engine 29 aus der Docker-CLI entfernt. Für signierte Images verwendet man heute Werkzeuge wie _Cosign_ oder _Notation_ und prüft die Signatur vor dem Deployment. Die CI erzeugt zusätzlich SBOM und Provenance (Kapitel 14). Signaturen, Scanner und SBOM ergänzen einander; keines davon ersetzt Tests.

== Checkliste

#table(columns: (auto, 1fr),
  [], [Maßnahme],
  [☐], [Images aus vertrauenswürdigen Quellen, mit fester Version],
  [☐], [Multi-Stage-Build, keine Build-Werkzeuge im Laufzeit-Image (Kapitel 8)],
  [☐], [Anwendung läuft als Nicht-Root-Benutzer],
  [☐], [`read_only`, `cap_drop: [ALL]`, `no-new-privileges`, Ressourcenlimits],
  [☐], [Passwörter als Secrets-Dateien, `.env` und `secrets/` nicht im Git],
  [☐], [Nur der Reverse Proxy veröffentlicht Ports, alles andere an `127.0.0.1` oder gar nicht (Kapitel 6)],
  [☐], [Docker-Socket in keinem Anwendungscontainer, Gruppe `docker` nur für Administratoren],
  [☐], [Regelmäßig neu bauen und mit Trivy prüfen, idealerweise automatisch in der CI],
  [☐], [Build-Geheimnisse nur über BuildKit-Secret- oder SSH-Mounts, nie über `ARG`, `ENV` oder `COPY`],
  [☐], [SBOM, Provenance und bei erhöhtem Schutzbedarf Image-Signaturen prüfen],
  [☐], [Host regelmäßig patchen, cgroup v2 sowie seccomp/AppArmor nicht ohne Grund deaktivieren],
)

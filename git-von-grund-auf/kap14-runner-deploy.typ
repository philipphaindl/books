#import "lib.typ": *

= Runner, Secrets, Deployment und SonarQube

Ein Workflow ist nur eine Beschreibung. Damit er läuft, braucht es einen Runner. Damit er etwas Nützliches tun kann, braucht er Zugangsdaten. Und damit das Ergebnis irgendwo ankommt, braucht es einen sicheren Weg auf den Zielserver. Dieses Kapitel baut diese Infrastruktur Schritt für Schritt auf und ergänzt zum Schluss SonarQube für die statische Codeanalyse.

== Der Runner

Der Runner ist ein kleines Go-Programm, das bei Gitea nach Jobs fragt und sie in Docker-Containern oder direkt auf dem Host ausführt. Bis 2026 hieß er `act_runner` (Docker-Image `gitea/act_runner`), seit der Umbenennung heißt er `gitea-runner` (Image `gitea/runner`, Stand September 2026 Version 3.5.0). Server und Runner werden unabhängig versioniert. Beim Wechsel einer Runner-Hauptversion sind die Upgrade-Hinweise verbindlich; sowohl 2.0 als auch 3.0 brachten absichtliche Inkompatibilitäten.

=== Wo ein Runner registriert wird

Ein Runner wird mit einem *Registrierungstoken* an Gitea gebunden. Wo du das Token holst, bestimmt, wem der Runner dient:

#table(columns: (auto, auto, 1fr),
  [Ebene], [Token unter], [Runner nimmt Jobs von],
  [Instanz], [_Administration -> Actions -> Runner_], [allen Repositories des Servers],
  [Organisation], [_Organisation -> Einstellungen -> Actions -> Runner_], [allen Repositories dieser Organisation],
  [Repository], [_Repository -> Einstellungen -> Actions -> Runner_], [nur diesem Repository],
)

Für ein kleines Team ist ein Runner auf Organisationsebene meist die richtige Wahl.

=== Einrichtung mit Docker Compose

Der einfachste Betrieb ist ein Container, der den Docker-Daemon des Host-Rechners mitbenutzt:

#datei("~/runner/docker-compose.yml")[
```yaml
services:
  runner:
    image: gitea/runner:3.5.0             # reproduzierbar; Updates bewusst nach Release Notes
    container_name: gitea-runner
    restart: unless-stopped
    environment:
      CONFIG_FILE: /data/config.yaml
      GITEA_INSTANCE_URL: https://gitea.example.com
      GITEA_RUNNER_REGISTRATION_TOKEN: ${RUNNER_TOKEN}   # aus der Datei .env, nur beim ersten Start nötig
      GITEA_RUNNER_NAME: build-01
      GITEA_RUNNER_LABELS: ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest
    volumes:
      - ./data:/data                                     # .runner (Registrierung) und config.yaml
      - /var/run/docker.sock:/var/run/docker.sock        # Jobs laufen auf dem Docker des Hosts
```
]

```bash
cd ~/runner
mkdir -p data
docker run --rm --entrypoint="" gitea/runner:3.5.0 gitea-runner config generate > data/config.yaml
# ältere Versionen: ... gitea/act_runner:latest act_runner generate-config > data/config.yaml
echo "RUNNER_TOKEN=<Token aus Gitea>" > .env
docker compose up -d
docker compose logs -f           # auf "Runner registered successfully" bzw. "declared successfully" achten
```

In der von `gitea-runner` erzeugten Datei sind alle Optionen auskommentiert, es gelten also die Standardwerte. Was du ändern willst, kommentierst du ein. Nach dem ersten Start liegt die Registrierung in `data/.runner`; behandle diese Datei wie ein Geheimnis und sichere sie nicht öffentlich. Entferne danach `GITEA_RUNNER_REGISTRATION_TOKEN` aus Compose und `.env`, denn das Registrierungstoken wird nicht mehr gebraucht. In Gitea erscheint der Runner in der Runner-Liste mit Status _Idle_.

=== Labels: Wie Jobs zum Runner finden

Ein Label hat die Form `name:schema:argument`. `ubuntu-latest:docker://docker.gitea.com/runner-images:ubuntu-latest` bedeutet: Ein Job mit `runs-on: ubuntu-latest` läuft in einem Container aus dem Image `docker.gitea.com/runner-images:ubuntu-latest`. Diese offiziellen Images enthalten die üblichen Werkzeuge (Git, Node.js für Actions, Docker-CLI, Build-Werkzeuge). Mit dem Schema `host` (etwa `macos:host`) laufen Jobs direkt auf dem Rechner des Runners, ohne Container. So lassen sich zum Beispiel Swift- oder Xcode-Builds auf einem Mac ausführen.

Eigene Labels sind jederzeit möglich, etwa `build:docker://python:3.13` für Jobs mit `runs-on: build`. Findet ein Job keinen Runner mit passendem Label, bleibt er dauerhaft im Zustand _Wartend_. Das ist der häufigste Grund für "die Pipeline startet nicht".

=== Die wichtigsten Einstellungen

#datei("data/config.yaml (Auszug)")[
```yaml
runner:
  capacity: 2          # wie viele Jobs gleichzeitig laufen dürfen
  timeout: 1h          # Obergrenze pro Job
container:
  network: ""          # leer = eigenes Netz pro Job; bei Problemen mit Services ggf. "bridge"
  privileged: false    # Jobs nicht privilegiert starten
  valid_volumes: []    # welche Host-Pfade Workflows einbinden dürfen (leer = keine)
```
]

Mit `gitea-runner config generate` bekommst du die vollständige, kommentierte Liste aller Optionen. Mit `capacity` solltest du bei kleinen Rechnern wie einer NAS vorsichtig sein: Zwei parallele Builds mit Docker können 4 bis 8 GB RAM belegen.

#achtung[Wer den Docker-Socket in einen Container einbindet, gibt diesem Container und damit jedem Job faktisch Root-Rechte auf dem Host. Ein Workflow kann über den Socket beliebige Container starten und das Host-Dateisystem einbinden. Deshalb gehört ein Runner auf einen eigenen Rechner oder in eine eigene VM, nicht auf den Server mit den produktiven Daten. Er sollte nur Workflows aus vertrauenswürdigen Repositories ausführen. Das Image existiert zusätzlich in den Varianten `latest-dind` (eigener Docker-Daemon im Container, privilegiert) und `latest-dind-rootless` (eigener Daemon ohne Root-Rechte). Die rootless-Variante reduziert das Risiko, bringt aber die üblichen Einschränkungen von rootless Docker mit.]

== Secrets und Variablen

Passwörter, Tokens und private Schlüssel gehören nie in eine Workflow-Datei, denn die liegt im Repository und ist für alle lesbar. Stattdessen hinterlegst du sie in Gitea als *Secrets*, nicht geheime Einstellungen als *Variablen*:

#table(columns: (auto, 1fr, 1fr),
  [], [Secret], [Variable],
  [Zugriff im Workflow], [`${{ secrets.NAME }}`], [`${{ vars.NAME }}`],
  [Nach dem Speichern lesbar], [nein, nur überschreibbar], [ja],
  [In Logs], [nach Möglichkeit durch `***` ersetzt], [im Klartext],
  [Typische Inhalte], [SSH-Schlüssel, API-Tokens, Passwörter], [Hostnamen, Benutzernamen, URLs, `known_hosts`],
)

Beide lassen sich auf Ebene des Benutzers, der Organisation und des Repositories anlegen (_Einstellungen -> Actions -> Secrets_ bzw. _Variablen_). Gibt es denselben Namen auf mehreren Ebenen, gewinnt die spezifischere. Namen dürfen nur Buchstaben, Ziffern und Unterstriche enthalten, nicht mit einer Ziffer und nicht mit `GITEA_` oder `GITHUB_` beginnen. Groß- und Kleinschreibung wird nicht unterschieden.

Zusätzlich erzeugt Gitea für jeden Lauf automatisch ein kurzlebiges Token, erreichbar als `secrets.GITEA_TOKEN` (oder `secrets.GITHUB_TOKEN`). Es erlaubt dem Workflow Zugriff auf das eigene Repository über die Gitea-API, aber, wie in Kapitel 13 erwähnt, nicht das Hochladen von Paketen und Container-Images.

Regeln für den sicheren Umgang:

- *Secrets über `env:` übergeben, nicht direkt in Befehle einsetzen.* `run: tool --token ${{ secrets.X }}` macht das Token für andere Prozesse in der Prozessliste sichtbar und kann in Fehlermeldungen landen. Besser: `env: TOKEN: ${{ secrets.X }}` und im Befehl `$TOKEN`.
- *Nie ausgeben* oder in Dateien schreiben, die als Artefakt hochgeladen werden. Die Maskierung erkennt exakte und einige häufig kodierte Formen, aber keine beliebige Umformung, Aufteilung oder Verschlüsselung eines Secrets.
- *Pull Requests aus Forks bekommen keine Secrets.* Das ist eine Schutzmaßnahme: Sonst könnte jeder per PR einen Workflow einschleusen, der die Secrets ausliest.
- *Minimale Rechte und eigene Zugangsdaten pro Zweck.* Ein Token nur für die Registry, ein SSH-Schlüssel nur für das Deployment. Regelmäßig austauschen.

== Deployment per SSH

Das Ziel: Nach einem erfolgreichen Build auf `main` soll der Runner auf dem Zielserver `app.example.com` die neue Version starten. Der naheliegende Weg, dem Runner einen normalen SSH-Zugang zu geben, ist gefährlich: Wer den Schlüssel aus dem Runner erbeutet, hat eine Shell auf dem Produktivserver. Deshalb wird der Schlüssel so eingeschränkt, dass er *genau einen Befehl* auslösen kann und sonst nichts.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    rect((0, -1.1), (4.4, 1.1), radius: 0.15, fill: rgb("#EAF1FB"), stroke: (paint: c-blue, thickness: 1pt))
    content((2.2, 0.75), text(size: 8pt, weight: "bold", fill: c-blue.darken(20%))[Job `deploy` im Runner])
    content((2.2, -0.1), align(left, text(size: 6.8pt)[Secret `DEPLOY_SSH_KEY` \ Variable `DEPLOY_KNOWN_HOSTS` \ `ssh deploy@app "<version>"`]))
    rect((6.6, -1.1), (15.2, 1.1), radius: 0.15, fill: rgb("#FDF1EC"), stroke: (paint: c-accent, thickness: 1pt))
    content((10.9, 0.75), text(size: 8pt, weight: "bold", fill: c-accent.darken(20%))[Zielserver `app.example.com`])
    kasten((8.3, -0.2), [`authorized_keys` \ #text(size: 6.3pt)[`restrict,command=...`]], w: 2.9, h: 0.95, size: 6.8pt)
    kasten((11.5, -0.2), [`deploy.sh` \ #text(size: 6.3pt)[prüft die Version]], w: 2.4, h: 0.95, size: 6.8pt)
    kasten((14.1, -0.2), [`docker` \ `compose up`], w: 1.7, h: 0.95, size: 6.8pt)
    pfeil((4.45, -0.2), (6.8, -0.2), label: "SSH", loff: (0, 0.22), color: c-accent)
    pfeil((9.8, -0.2), (10.25, -0.2))
    pfeil((12.75, -0.2), (13.2, -0.2))
  }),
  caption: [Der Deploy-Schlüssel kann auf dem Server nur ein einziges, vorher festgelegtes Skript starten.],
)

=== Schritt 1: Ein eigenes Schlüsselpaar für das Deployment

```bash
# am Mac, ohne Passphrase, weil der Runner sie nicht eingeben kann
ssh-keygen -t ed25519 -N "" -C "ci-deploy demo" -f ./deploy_demo
```

Das erzeugt `deploy_demo` (privat, kommt als Secret nach Gitea) und `deploy_demo.pub` (öffentlich, kommt auf den Server). Nach dem Einrichten löschst du beide Dateien vom Mac.

=== Schritt 2: Der Server lässt nur ein Skript zu

Auf dem Zielserver legst du einen eigenen Benutzer `deploy` an und trägst den öffentlichen Schlüssel mit Einschränkungen ein:

#datei("/home/deploy/.ssh/authorized_keys")[
```text
restrict,command="/srv/demo/deploy.sh" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... ci-deploy demo
```
]

`restrict` verbietet Port-Weiterleitungen, Agent-Weiterleitung und ein Terminal. `command=` erzwingt, dass bei jeder Anmeldung mit diesem Schlüssel ausschließlich das angegebene Skript läuft, egal welchen Befehl der Client mitschickt. Den mitgeschickten Befehl findet das Skript in der Variable `SSH_ORIGINAL_COMMAND` und kann ihn als Parameter nutzen, hier für die Version. Dabei muss es ihn streng prüfen:

#datei("/srv/demo/deploy.sh")[
```bash
#!/usr/bin/env bash
set -euo pipefail

VERSION="${SSH_ORIGINAL_COMMAND:-}"
# nur Commit-Hashes oder Versions-Tags zulassen, nichts anderes
if [[ ! "$VERSION" =~ ^([0-9a-f]{7,40}|v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  echo "Ungültige Version: '$VERSION'" >&2
  exit 1
fi

cd /srv/demo
exec 9>deploy.lock
flock -n 9 || { echo "Ein Deployment läuft bereits" >&2; exit 1; }

PREVIOUS="$(cat .deployed-version 2>/dev/null || true)"
export IMAGE_TAG="$VERSION"
docker compose pull
if ! docker compose up -d --remove-orphans --wait --wait-timeout 120; then
  echo "Deployment fehlgeschlagen; Rollback auf $PREVIOUS" >&2
  if [[ -n "$PREVIOUS" ]]; then
    export IMAGE_TAG="$PREVIOUS"
    docker compose up -d --remove-orphans --wait --wait-timeout 120
  fi
  exit 1
fi
printf '%s\n' "$VERSION" > .deployed-version.tmp
mv .deployed-version.tmp .deployed-version
docker image prune -f
echo "Deployed $VERSION"
```
]

```bash
sudo chmod 755 /srv/demo/deploy.sh
sudo usermod -aG docker deploy     # siehe Hinweis unten
```

#achtung[Mitglieder der Gruppe `docker` haben faktisch Root-Rechte. Wegen der `command=`-Einschränkung kann der Deploy-Schlüssel diese Rechte aber nur über `deploy.sh` nutzen. Noch strenger ist eine `sudo`-Regel, die dem Benutzer `deploy` nur genau dieses Skript erlaubt, statt ihn in die Docker-Gruppe aufzunehmen. `--wait` setzt funktionierende `healthcheck`-Einträge im Compose-Modell voraus; den Rollback-Pfad vor dem ersten echten Release absichtlich testen.]

=== Schritt 3: Den Server-Schlüssel festnageln

Damit sich niemand als Zielserver ausgeben kann, muss der Runner den Host-Schlüssel des Servers vorab kennen. Den ermittelst du einmal und prüfst den Fingerabdruck gegen den Server selbst:

```bash
ssh-keyscan -t ed25519 app.example.com            # Zeile für known_hosts
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub  # auf dem Server: Fingerabdruck zum Vergleich
```

Die Ausgabe von `ssh-keyscan` speicherst du als Variable `DEPLOY_KNOWN_HOSTS` in Gitea. Im Workflow wird dann mit `StrictHostKeyChecking=yes` geprüft. Das häufig zu sehende `StrictHostKeyChecking=no` schaltet genau diesen Schutz ab.

=== Schritt 4: Secrets und Variablen in Gitea

#table(columns: (auto, auto, 1fr),
  [Name], [Art], [Inhalt],
  [`DEPLOY_SSH_KEY`], [Secret], [kompletter Inhalt von `deploy_demo` inklusive der BEGIN/END-Zeilen],
  [`DEPLOY_KNOWN_HOSTS`], [Variable], [Ausgabe von `ssh-keyscan`],
  [`DEPLOY_HOST`], [Variable], [`app.example.com`],
  [`DEPLOY_USER`], [Variable], [`deploy`],
)

=== Schritt 5: Der Deploy-Job

#datei("Auszug aus .gitea/workflows/deploy.yml")[
```yaml
  deploy:
    needs: [build]
    runs-on: ubuntu-latest
    steps:
      - name: Über SSH ausrollen
        env:
          SSH_KEY: ${{ secrets.DEPLOY_SSH_KEY }}
          KNOWN_HOSTS: ${{ vars.DEPLOY_KNOWN_HOSTS }}
        run: |
          install -m 700 -d "$RUNNER_TEMP/ssh"
          printf '%s\n' "$SSH_KEY" > "$RUNNER_TEMP/ssh/deploy_key"
          chmod 600 "$RUNNER_TEMP/ssh/deploy_key"
          printf '%s\n' "$KNOWN_HOSTS" > "$RUNNER_TEMP/ssh/known_hosts"
          trap 'rm -rf "$RUNNER_TEMP/ssh"' EXIT
          ssh -i "$RUNNER_TEMP/ssh/deploy_key" \
            -o UserKnownHostsFile="$RUNNER_TEMP/ssh/known_hosts" \
            -o StrictHostKeyChecking=yes \
            ${{ vars.DEPLOY_USER }}@${{ vars.DEPLOY_HOST }} "${{ gitea.sha }}"
```
]

Es gibt fertige Actions für SSH-Deployments (etwa `appleboy/ssh-action`). Sie sind bequem, bedeuten aber, dass fremder Code deinen privaten Schlüssel verarbeitet. Die vier Zeilen Shell oben sind transparent und brauchen keine Abhängigkeit.

#praxis[Liegt der Zielserver in einem privaten Netz oder ist er nur über WireGuard erreichbar, muss der *Runner* in diesem Netz sein, nicht Gitea. Da der Runner seine Verbindungen selbst aufbaut (Kapitel 13), genügt es, den Runner-Host ins VPN zu nehmen. Gitea selbst braucht keinen Zugang zum Zielserver.]

== Container-Images in der Gitea-Registry

Gitea hat eine eingebaute Container-Registry. Images heißen dort `gitea.example.com/<besitzer>/<image>:<tag>`, also etwa `gitea.example.com/team/demo:3f2a9c1`. Weil der automatische `GITEA_TOKEN` keine Pakete hochladen darf, legst du unter _Einstellungen -> Anwendungen_ einen persönlichen Zugriffstoken mit Schreibrecht für Pakete an und speicherst ihn als Secret `REGISTRY_TOKEN`:

```yaml
  build:
    needs: [test]
    runs-on: ubuntu-latest
    env:
      IMAGE: gitea.example.com/team/demo
    steps:
      - uses: actions/checkout@v4
      - name: An der Registry anmelden
        env:
          TOKEN: ${{ secrets.REGISTRY_TOKEN }}
        run: echo "$TOKEN" | docker login gitea.example.com -u ${{ gitea.actor }} --password-stdin
      - name: Bauen und hochladen
        run: |
          docker build -t "$IMAGE:${{ gitea.sha }}" -t "$IMAGE:latest" .
          docker push "$IMAGE:${{ gitea.sha }}"
          docker push "$IMAGE:latest"
```

Damit `docker build` im Job funktioniert, braucht der Job Zugriff auf einen Docker-Daemon. Beim Runner-Setup mit eingebundenem Socket ist das gegeben, die Runner-Images bringen die Docker-CLI mit. Auf dem Zielserver steht in der `docker-compose.yml` dann `image: gitea.example.com/team/demo:${IMAGE_TAG}`, und der Server braucht einmalig ein `docker login` mit einem Token, das nur Leserechte für Pakete hat. Ausgerollt wird immer der unveränderliche Commit- oder Versions-Tag; `latest` ist höchstens ein bequemer Hinweis und darf nie die Grundlage für reproduzierbare Deployments oder Rollbacks sein.

== SonarQube: statische Codeanalyse

SonarQube untersucht den Quellcode, ohne ihn auszuführen, auf Fehlermuster, Sicherheitsprobleme (_Vulnerabilities_ und _Security Hotspots_), Wartbarkeitsmängel (_Code Smells_), Duplikate und Testabdeckung. Das Ergebnis wird an einem *Quality Gate* gemessen, einem Satz von Schwellwerten wie "keine neuen kritischen Probleme" und "mindestens 80 % Abdeckung im neuen Code".

#merke[Die kostenlose _Community Build_ von SonarQube analysiert nur *einen* Branch pro Projekt, den Hauptbranch. Analysen von Feature-Branches und Pull Requests samt Kommentaren im PR gibt es erst in den kostenpflichtigen Editionen, und auch dort ist Gitea keine offiziell unterstützte Plattform für PR-Kommentare. Praktische Folge: In der Community Build lässt du Sonar *nur bei Pushes auf `main`* laufen. Eine Analyse eines Feature-Branches würde sonst die Ergebnisse von `main` überschreiben.]

=== Server und Projekt

SonarQube läuft als Docker-Container mit einer PostgreSQL-Datenbank und braucht spürbar Ressourcen (mindestens 2, besser 4 GB RAM). Weil es intern Elasticsearch verwendet, muss auf dem Host ein Kernel-Parameter gesetzt sein, sonst startet es nicht:

```bash
sudo sysctl -w vm.max_map_count=524288   # dauerhaft in /etc/sysctl.conf eintragen
```

Nach dem Start legst du in der Weboberfläche ein Projekt manuell an (_Create Project -> Local project_, Projektschlüssel z.B. `demo`) und erzeugst dafür ein *Project Analysis Token*. Dieses kommt als Secret `SONAR_TOKEN` nach Gitea, die Server-URL als Variable `SONAR_HOST_URL`.

=== Konfiguration im Repository

#datei("sonar-project.properties")[
```ini
sonar.projectKey=demo
sonar.projectName=demo
sonar.sources=src
sonar.tests=tests
sonar.exclusions=**/migrations/**,**/*.min.js
# Coverage-Bericht aus "make test", Schlüssel je nach Sprache, z.B.:
sonar.python.coverage.reportPaths=reports/coverage.xml
# sonar.javascript.lcov.reportPaths=reports/lcov.info
```
]

=== Der Sonar-Job

```yaml
  sonar:
    if: gitea.ref == 'refs/heads/main'       # Community Build: nur main analysieren
    needs: [test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0                      # volle Historie für "neuer Code" und blame
      - run: make setup && make test          # erzeugt den Coverage-Bericht
      - name: SonarQube-Analyse
        uses: SonarSource/sonarqube-scan-action@v7
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ vars.SONAR_HOST_URL }}
      - name: Quality Gate prüfen
        uses: SonarSource/sonarqube-quality-gate-action@v1
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ vars.SONAR_HOST_URL }}
```

Die Scan-Action lädt beim ersten Lauf den _SonarScanner_ samt Java-Laufzeit von den Servern von SonarSource herunter, der Runner braucht dafür Internetzugang. Der Quality-Gate-Schritt wartet auf das Ergebnis der Auswertung und lässt den Job fehlschlagen, wenn das Gate rot ist. Hängen spätere Jobs wie das Deployment per `needs` an `sonar`, wird bei rotem Gate nicht ausgeliefert. Die Versionsangaben `@v7` und `@v1` entsprechen der Sonar-Dokumentation von 2026. Neue Hauptversionen können Konfigurationsänderungen mitbringen, deshalb vor einem Update die Release Notes lesen.

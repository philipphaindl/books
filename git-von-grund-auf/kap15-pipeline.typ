#import "lib.typ": *

= Die komplette Pipeline

Zum Abschluss werden alle Bausteine zu einer vollständigen Pipeline für das Beispielprojekt zusammengesetzt. Sie besteht aus zwei Workflow-Dateien mit klar getrennten Aufgaben: `ci.yml` prüft jede Änderung, `deploy.yml` liefert aus, was in `main` angekommen ist.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let lane(y, titel, col) = {
      content((-0.2, y), anchor: "east", text(size: 7pt, weight: "bold", fill: col.darken(15%), titel))
    }
    lane(1.3, [PR / Push \ auf Branch], c-accent)
    lane(0, [Push \ auf `main`], c-blue)
    lane(-1.3, [Tag `v*`], c-yellow)
    let k(x, y, t, col, h: 0.72) = kasten((x, y), t, w: 1.9, h: h, bg: col.lighten(90%), col: col, size: 7pt)
    // PR-Spur: lint und test parallel
    k(1.1, 1.3, [`lint`], c-accent); k(3.6, 1.3, [`test`], c-accent)
    content((5.0, 1.3), anchor: "west", text(size: 6.8pt, fill: c-grey.darken(20%), style: "italic")[parallel, Statusprüfungen im PR (`ci.yml`)])
    // main-Spur: test, dann sonar und build parallel, dann deploy-staging
    k(1.1, 0, [`test`], c-blue)
    k(3.6, 0.3, [`sonar`], c-blue, h: 0.5); k(3.6, -0.3, [`build`], c-blue, h: 0.5)
    k(6.1, 0, [`deploy-` \ `staging`], c-blue)
    pfeil((2.05, 0.1), (2.65, 0.3)); pfeil((2.05, -0.1), (2.65, -0.3))
    pfeil((4.55, 0.3), (5.15, 0.1)); pfeil((4.55, -0.3), (5.15, -0.1))
    // Tag-Spur
    k(1.1, -1.3, [`test`], c-yellow); k(3.6, -1.3, [`build`], c-yellow); k(6.1, -1.3, [`deploy-` \ `production`], c-yellow)
    pfeil((2.05, -1.3), (2.65, -1.3)); pfeil((4.55, -1.3), (5.15, -1.3))
    content((8.9, 0), anchor: "west", text(size: 6.8pt)[Staging-Server])
    content((8.9, -1.3), anchor: "west", text(size: 6.8pt)[`app.example.com`])
    pfeil((7.05, 0), (8.8, 0), color: c-grey); pfeil((7.05, -1.3), (8.8, -1.3), color: c-grey)
    content((11.6, 0), anchor: "west", text(size: 6.5pt, fill: c-grey.darken(20%), style: "italic")[nur mit grünem \ Quality Gate])
  }),
  caption: [Drei Auslöser, drei Abläufe. Produktion wird nur durch einen bewusst gesetzten Versions-Tag erreicht.],
)

== `ci.yml`: jede Änderung prüfen

#datei(".gitea/workflows/ci.yml")[
```yaml
name: ci

on:
  pull_request:                      # jeder PR und jeder weitere Push darauf
  push:
    branches-ignore: [main]          # Pushes auf Feature-Branches auch ohne PR prüfen
  workflow_dispatch:

concurrency:                         # überholte Läufe abbrechen (ab Gitea 1.26)
  group: ci-${{ gitea.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make setup
      - run: make lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make setup
      - run: make test
      - name: Testbericht sichern
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: testbericht
          path: reports/
          retention-days: 14
```
]

`lint` und `test` laufen parallel, weil keiner vom anderen abhängt. So kommt das Ergebnis schneller. In Gitea trägst du im Branch-Schutz von `main` die Statusprüfungen mit dem Muster `ci / *` als erforderlich ein (Kapitel 12). Ab dann lässt sich kein PR mehr mergen, dessen Lint oder Tests rot sind.

Pushes auf einen Branch mit offenem PR lösen hier beide Ereignisse aus (`push` und `pull_request`), die Prüfung läuft dann doppelt. Wer das vermeiden will, lässt den `push`-Block weg und prüft nur PRs.

== `deploy.yml`: ausliefern

#datei(".gitea/workflows/deploy.yml")[
```yaml
name: deploy

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make setup && make lint && make test

  sonar:
    if: gitea.ref == 'refs/heads/main'
    needs: [test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - run: make setup && make test
      - uses: SonarSource/sonarqube-scan-action@v7
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ vars.SONAR_HOST_URL }}
      - uses: SonarSource/sonarqube-quality-gate-action@v1
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ vars.SONAR_HOST_URL }}

  build:
    needs: [test]
    runs-on: ubuntu-latest
    outputs:
      tag: ${{ steps.meta.outputs.tag }}
    env:
      IMAGE: gitea.example.com/team/demo
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Release-Tag muss aus main stammen
        if: startsWith(gitea.ref, 'refs/tags/v')
        run: |
          git fetch --no-tags origin main:refs/remotes/origin/main
          git merge-base --is-ancestor "$GITHUB_SHA" refs/remotes/origin/main || {
            echo "Release-Tag zeigt nicht auf einen Commit aus main" >&2
            exit 1
          }
      - name: Image-Tag bestimmen (Versions-Tag oder Commit-Hash)
        id: meta
        run: |
          if [[ "$GITHUB_REF" == refs/tags/* ]]; then TAG="$GITHUB_REF_NAME"; else TAG="$GITHUB_SHA"; fi
          echo "tag=$TAG" >> "$GITHUB_OUTPUT"
      - name: Anmelden, bauen, hochladen
        env:
          TOKEN: ${{ secrets.REGISTRY_TOKEN }}
          TAG: ${{ steps.meta.outputs.tag }}
        run: |
          echo "$TOKEN" | docker login gitea.example.com -u ${{ gitea.actor }} --password-stdin
          docker build -t "$IMAGE:$TAG" .
          docker push "$IMAGE:$TAG"

  deploy-staging:
    if: gitea.ref == 'refs/heads/main'
    needs: [build, sonar]              # nur mit grünem Quality Gate
    runs-on: ubuntu-latest
    steps:
      - name: Über SSH ausrollen
        env:
          SSH_KEY: ${{ secrets.STAGING_SSH_KEY }}
          KNOWN_HOSTS: ${{ vars.STAGING_KNOWN_HOSTS }}
        run: |
          install -m 700 -d "$RUNNER_TEMP/ssh"
          printf '%s\n' "$SSH_KEY" > "$RUNNER_TEMP/ssh/deploy_key"
          chmod 600 "$RUNNER_TEMP/ssh/deploy_key"
          printf '%s\n' "$KNOWN_HOSTS" > "$RUNNER_TEMP/ssh/known_hosts"
          trap 'rm -rf "$RUNNER_TEMP/ssh"' EXIT
          ssh -i "$RUNNER_TEMP/ssh/deploy_key" \
            -o UserKnownHostsFile="$RUNNER_TEMP/ssh/known_hosts" \
            -o StrictHostKeyChecking=yes \
            deploy@${{ vars.STAGING_HOST }} "${{ needs.build.outputs.tag }}"

  deploy-production:
    if: startsWith(gitea.ref, 'refs/tags/v')
    needs: [build]
    runs-on: ubuntu-latest
    steps:
      - name: Über SSH ausrollen
        env:
          SSH_KEY: ${{ secrets.PROD_SSH_KEY }}
          KNOWN_HOSTS: ${{ vars.PROD_KNOWN_HOSTS }}
        run: |
          install -m 700 -d "$RUNNER_TEMP/ssh"
          printf '%s\n' "$SSH_KEY" > "$RUNNER_TEMP/ssh/deploy_key"
          chmod 600 "$RUNNER_TEMP/ssh/deploy_key"
          printf '%s\n' "$KNOWN_HOSTS" > "$RUNNER_TEMP/ssh/known_hosts"
          trap 'rm -rf "$RUNNER_TEMP/ssh"' EXIT
          ssh -i "$RUNNER_TEMP/ssh/deploy_key" \
            -o UserKnownHostsFile="$RUNNER_TEMP/ssh/known_hosts" \
            -o StrictHostKeyChecking=yes \
            deploy@${{ vars.PROD_HOST }} "${{ needs.build.outputs.tag }}"
```
]

Einige Entscheidungen in dieser Datei sind bewusst getroffen:

- *Staging und Produktion haben getrennte Schlüssel und Variablen.* Weil Gitea `environment` ignoriert, übernehmen die Namenspräfixe `STAGING_` und `PROD_` diese Trennung. Ein erbeuteter Staging-Schlüssel öffnet nicht die Produktion.
- *Produktion nur über Tags.* Ein Merge nach `main` landet automatisch auf Staging. Für die Produktion setzt du bewusst einen Versions-Tag. Das Image wird dabei unter dem Versionsnamen gebaut, sodass `deploy.sh` auf dem Server genau diese Version startet.
- *Ein Release-Tag muss aus `main` stammen.* Der Build holt `origin/main` und prüft mit `git merge-base --is-ancestor`, dass der getaggte Commit darin enthalten ist. Zusammen mit einem geschützten Tag-Muster `v*` verhindert das, dass ein beliebiger Commit den PR- und Review-Weg umgeht.
- *Sonar nur auf `main`*, passend zur Einschränkung der Community Build aus Kapitel 14. Auf Tags wird nicht erneut analysiert, der getaggte Commit hat die Analyse schon auf `main` durchlaufen.
- *Jeder Job checkt selbst aus.* Jobs teilen keine Dateien. Das Image ist das Artefakt, das vom Build zum Deployment wandert, und zwar über die Registry.

== Ein Feature von Anfang bis Ende

```bash
# 1. Branch anlegen
git switch main && git pull
git switch -c feature/43-csv-export

# 2. Arbeiten, lokal genau das prüfen, was die CI prüft
make lint && make test
git add -p && git commit -m "CSV-Export für Berichte ergänzen"

# 3. Pushen und in Gitea den PR öffnen (Link steht in der Ausgabe)
git push
#    -> ci.yml läuft: lint + test als Statusprüfungen im PR

# 4. Review-Anmerkungen einarbeiten
git commit --fixup=HEAD && git push
#    -> nach Freigabe in Gitea: "Create squash commit", Branch wird gelöscht
#    -> deploy.yml läuft auf main: test, sonar, build, deploy-staging

# 5. Lokal aufräumen
git switch main && git pull && git branch -D feature/43-csv-export

# 6. Nach dem Test auf Staging: Release (auf aktuellem main)
git switch main && git pull --ff-only
git tag -s v1.3.0 -m "Version 1.3.0: CSV-Export"
git push origin v1.3.0
#    -> deploy.yml läuft für den Tag: test, build, deploy-production
```

== Fehlersuche

#table(columns: (1fr, 1.3fr),
  [Symptom], [Ursache und Lösung],
  [Workflow erscheint nicht im Tab _Actions_], [Datei nicht in `.gitea/workflows/` oder falsche Endung. Actions im Repository deaktiviert. YAML-Fehler (Gitea zeigt ihn im Tab _Actions_ an). Das Ereignis passt nicht zu den Filtern unter `on:`.],
  [Job bleibt auf _Wartend_], [Kein Runner mit passendem Label online. `runs-on` vertippt. Runner nur für ein anderes Repository oder eine andere Organisation registriert.],
  [Checkout schlägt fehl (_could not resolve host_, _connection refused_)], [Der Job-Container erreicht Gitea nicht unter dessen `ROOT_URL`. Häufig steht dort `localhost`, oder der Name ist nur im Heimnetz auflösbar. `ROOT_URL` korrigieren oder `container.network` des Runners anpassen.],
  [Secret ist leer], [Name vertippt, auf der falschen Ebene angelegt, als Variable statt als Secret gespeichert (oder umgekehrt), oder der PR stammt aus einem Fork.],
  [_Permission denied (publickey)_], [Privater Schlüssel unvollständig eingefügt (BEGIN/END-Zeilen fehlen), öffentlicher Schlüssel nicht in `authorized_keys`, falsche Rechte auf `~/.ssh` beim Zielbenutzer.],
  [_Host key verification failed_], [`known_hosts`-Variable fehlt oder ist veraltet, etwa nach einer Neuinstallation des Servers. Fingerabdruck neu prüfen und Variable aktualisieren.],
  [_Cannot connect to the Docker daemon_], [Der Runner hat keinen Zugriff auf einen Docker-Daemon, oder das Job-Image enthält keine Docker-CLI.],
  [Sonar: _Not authorized_ oder Timeout beim Quality Gate], [Token falsch oder abgelaufen, `projectKey` passt nicht, oder `SONAR_HOST_URL` ist aus dem Job-Container nicht erreichbar.],
  [Tag löst keinen Workflow aus], [Tag nur lokal angelegt (Tags werden nicht automatisch gepusht), oder das Muster unter `tags:` passt nicht.],
  [`concurrency`, `timeout-minutes` wirken nicht], [Gitea-Version zu alt, die Schlüssel werden dort stillschweigend ignoriert.],
)

=== Lokal testen, bevor gepusht wird

Jeder Fehlversuch in der CI kostet einen Commit und ein paar Minuten. Drei Hilfen verkürzen die Schleife:

- Die Prüfungen über das Makefile lokal ausführen (`make lint && make test`). Das fängt die meisten Fehler ab.
- Workflows lokal in Docker ausführen, ohne Gitea: mit `gitea-runner exec` (früher `act_runner exec`) oder dem Werkzeug `act` (`brew install act`), auf dem der Runner ursprünglich basiert. Am Mac braucht beides einen kompatiblen laufenden Docker-Daemon, etwa Colima, Docker Desktop oder OrbStack; Details liefert `--help`. Das ist ein schneller Test, aber keine vollständige Simulation von Giteas Ereignisdaten, Berechtigungen und Netzwerk.
- Neue Workflows zuerst nur mit `workflow_dispatch` anlegen und über die Schaltfläche im Tab _Actions_ starten, bis sie funktionieren. Erst dann die echten Auslöser eintragen.

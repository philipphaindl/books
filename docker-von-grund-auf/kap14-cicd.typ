#import "lib.typ": *

= Bauen und Ausliefern mit Gitea Actions

Das Git-Handbuch beschreibt in den Kapiteln 13 bis 15 Gitea Actions, Runner, Secrets und das SSH-Deployment mit eingeschränktem Schlüssel ausführlich. Dieses Kapitel setzt darauf auf und zeigt die Docker-spezifischen Teile: Tests gegen eine echte Datenbank, einen reproduzierbaren Build mit SBOM und Provenance, den Test des fertigen Images sowie ein abgesichertes Deployment mit Backup und Applikations-Rollback.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let k(x, t, c) = kasten((x, 0), t, w: 2.35, h: 1.1, bg: c.lighten(90%), col: c, size: 7pt)
    k(0, [`test` \ #text(size: 6.3pt)[Quellcode + DB]], c-accent)
    k(2.95, [`build + push` \ #text(size: 6.3pt)[Kandidat + SBOM]], c-blue)
    k(5.9, [`smoke` \ #text(size: 6.3pt)[fertiges Image]], c-teal)
    k(8.85, [Trivy \ #text(size: 6.3pt)[kritische Lücken?]], c-red)
    k(11.8, [`deploy` \ #text(size: 6.3pt)[SSH -> Digest]], c-violet)
    for x in (1.2, 4.15, 7.1, 10.05) { pfeil((x, 0), (x + 0.55, 0)) }
    rahmen((9.6, -2.5), (15.2, -1.0), [auf dem Server], c-grey, bg: luma(250))
    content((12.4, -1.95), text(size: 6.5pt)[Lock -> Backup -> Migration -> `up --wait` -> ggf. App-Rollback])
    line((11.8, -0.58), (11.8, -1.0), stroke: c-violet + 0.8pt, mark: (end: "stealth", fill: c-violet, scale: 0.5))
  }),
  caption: [Nur der nach dem Build getestete und gescannte Digest wird deployt.],
)

== Vertrauenswürdige Werkzeuge im Runner

Installationsbefehle wie `curl ... | sh` sparen Zeilen, führen aber bei jedem Lauf ungeprüften, veränderlichen Code aus. Der dedizierte Runner dieses Beispiels stellt Docker Buildx, `uv`, Trivy und `curl` in festgelegten Versionen bereit. Das Runner-Image selbst wird separat aktualisiert, per Checksum oder Signatur geprüft und getestet. Auch Actions werden auf den vollständigen Commit-SHA statt nur auf einen beweglichen Tag gepinnt.

#achtung[Ein Runner mit Zugriff auf `/var/run/docker.sock` hat praktisch Root-Rechte auf seinem Host. Er darf deshalb nur vertrauenswürdige Workflows ausführen, ist dediziert oder kurzlebig und erhält bei Pull Requests aus fremden Forks weder Secrets noch Docker-Socket-Zugriff.]

== Tests gegen eine echte Datenbank

Gitea Actions kann für einen Job Hilfscontainer starten (_services_). Der Job erreicht sie über ihren Namen, genau wie in einem Compose-Netz. So laufen die Tests gegen dieselbe PostgreSQL-Hauptversion wie in Produktion statt gegen eine Attrappe:

#datei(".gitea/workflows/ci.yml (Auszug)")[
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      db:
        image: postgres:18
        env:
          POSTGRES_USER: notizen
          POSTGRES_PASSWORD: test
          POSTGRES_DB: notizen
        options: >-
          --health-cmd "pg_isready -U notizen"
          --health-interval 5s
          --health-retries 10
    env:
      DATABASE_URL: postgresql://notizen:test@db:5432/notizen
    steps:
      # actions/checkout v4.2.2; SHA statt beweglichem @v4
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - run: uv --version
      - run: uv sync --locked
      - run: uv run pytest
```
]

Der Runner wartet, bis der Healthcheck des Service-Containers erfolgreich ist, bevor er die Schritte startet. Das prüft den Quellcode. Zusätzlich wird im nächsten Job das wirklich veröffentlichte Image als Container gestartet.

== Image bauen, attestieren und als Kandidat veröffentlichen

BuildKit kann neben dem Image eine Software-Stückliste (_SBOM_) und Provenance über den Build erzeugen. Attestations werden zuverlässig in einer Registry gespeichert; deshalb erhält der Kandidat zunächst nur den vollständigen Commit-SHA als internen Tag. Erst nach Smoke-Test und Scan darf sein Digest deployt oder unter einem Release-Tag beworben werden.

#datei(".gitea/workflows/deploy.yml (Auszug)")[
```yaml
  build:
    needs: [test]
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.image.outputs.digest }}
    env:
      IMAGE: gitea.example.com/team/notizen
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - name: An Registry anmelden
        env:
          TOKEN: ${{ secrets.REGISTRY_TOKEN }}
        run: |
          echo "$TOKEN" | docker login gitea.example.com \
            -u "${{ gitea.actor }}" --password-stdin
      - name: Kandidat mit SBOM und Provenance bauen
        run: |
          docker buildx build --pull --platform linux/amd64 \
            --sbom=true --provenance=mode=max \
            --label org.opencontainers.image.revision="$GITHUB_SHA" \
            -t "$IMAGE:$GITHUB_SHA" --push .
      - name: Unveränderliche Referenz bestimmen
        id: image
        run: |
          docker pull "$IMAGE:$GITHUB_SHA"
          REF="$(docker image inspect "$IMAGE:$GITHUB_SHA" \
            --format '{{index .RepoDigests 0}}')"
          DIGEST="${REF##*@}"
          [[ "$DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]]
          echo "digest=$DIGEST" >> "$GITHUB_OUTPUT"
          echo "Prüfkandidat: $REF"
      - name: Fertiges Image gegen PostgreSQL starten
        run: |
          REF="$IMAGE@${{ steps.image.outputs.digest }}"
          trap 'docker rm -f ci-api ci-db 2>/dev/null || true; \
                docker network rm ci-notizen 2>/dev/null || true' EXIT
          docker network create ci-notizen
          docker run -d --name ci-db --network ci-notizen \
            -e POSTGRES_USER=notizen -e POSTGRES_PASSWORD=test \
            -e POSTGRES_DB=notizen postgres:18
          for i in $(seq 1 30); do
            docker exec ci-db pg_isready -U notizen && break
            [[ "$i" == 30 ]] && exit 1; sleep 2
          done
          docker run --rm --network ci-notizen \
            -e DB_HOST=ci-db -e DB_PASSWORD=test "$REF" \
            alembic upgrade head
          docker run -d --name ci-api --network ci-notizen \
            -p 127.0.0.1:18000:8000 \
            -e DB_HOST=ci-db -e DB_PASSWORD=test "$REF"
          for i in $(seq 1 30); do
            curl -fsS http://127.0.0.1:18000/health && break
            [[ "$i" == 30 ]] && { docker logs ci-api; exit 1; }; sleep 2
          done
      - name: Kandidaten scannen
        run: |
          trivy image --exit-code 1 --exit-on-eol --severity CRITICAL \
            "$IMAGE@${{ steps.image.outputs.digest }}"
```
]

- `--pull` nimmt Sicherheitsupdates des beweglichen Basis-Tags in einen neuen Kandidaten auf.
- `--sbom=true` dokumentiert enthaltene Pakete; `--provenance=mode=max` dokumentiert Build-Quelle und Parameter.
- Der Smoke-Test und Trivy verwenden `repository@sha256:…`, also exakt den veröffentlichten Inhalt. Ein fehlgeschlagener Kandidat bleibt zwar für die Analyse in der Registry, wird aber weder promoted noch deployt.
- Der Registry-Token ist ein persönlicher Zugriffstoken mit Schreibrecht für Pakete, weil der automatische `GITEA_TOKEN` Pakete nicht hochladen kann.

Für besonders schützenswerte Lieferketten signiert die CI den geprüften Digest anschließend mit Cosign oder Notation. Docker Content Trust gehört seit Engine 29 nicht mehr zur Docker-CLI. Die Deployment-Seite prüft dann Signatur und erlaubte Identität, bevor sie den Digest übernimmt.

== Das Deployment-Skript für Compose

Der Deploy-Job ruft per SSH mit einem eingeschränkten Schlüssel (`restrict,command=...`) das folgende Skript auf und übergibt ausschließlich den geprüften Digest. Einrichtung von Schlüssel, `authorized_keys` und `known_hosts` siehe Git-Handbuch Kapitel 14.

#datei("/srv/notizen/deploy.sh")[
```bash
#!/usr/bin/env bash
set -euo pipefail
umask 077

DIGEST="${SSH_ORIGINAL_COMMAND:-}"
if [[ ! "$DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  echo "Ungültiger Digest: '$DIGEST'" >&2; exit 1
fi

cd /srv/notizen
exec 9>/run/lock/notizen-deploy.lock
flock -n 9 || { echo "Deployment läuft bereits" >&2; exit 1; }

NEU="gitea.example.com/team/notizen@$DIGEST"
NEXT_ENV="$(mktemp /srv/notizen/.env.next.XXXXXX)"
trap 'rm -f "$NEXT_ENV"' EXIT
cp .env "$NEXT_ENV"
if grep -q '^IMAGE_REF=' "$NEXT_ENV"; then
  sed -i "s|^IMAGE_REF=.*|IMAGE_REF=$NEU|" "$NEXT_ENV"
else
  printf 'IMAGE_REF=%s\n' "$NEU" >> "$NEXT_ENV"
fi

./backup.sh
docker compose --env-file "$NEXT_ENV" pull api
docker compose --env-file "$NEXT_ENV" run --rm api alembic upgrade head

if docker compose --env-file "$NEXT_ENV" up -d --wait --wait-timeout 60 api; then
  mv "$NEXT_ENV" .env
  trap - EXIT
  echo "Deployed $NEU"
  exit 0
fi

echo "Neue API nicht gesund; stelle vorherige App-Version wieder her" >&2
docker compose --env-file .env pull api || true
docker compose --env-file .env up -d --wait --wait-timeout 60 api || true
docker compose logs --tail 80 api >&2
exit 1
```
]

Das Lock verhindert parallele Deployments. Die produktive `.env` wird erst nach einem erfolgreichen Healthcheck ersetzt. Bei einem Fehler wird die vorherige *Applikationsversion* wieder gestartet. Die bereits ausgeführte Datenbankmigration wird absichtlich nicht automatisch zurückgerollt: Migrationen müssen nach dem Expand/Contract-Muster rückwärtskompatibel sein. Ein Datenbank-Restore ist ein bewusster Notfallvorgang mit möglichem Datenverlust seit dem Backup.

Alte Images werden nicht im selben Skript sofort gelöscht, damit ein Rollback verfügbar bleibt. Eine getrennte, überwachte Wartungsaufgabe entfernt sie nach der festgelegten Aufbewahrungsfrist.

#merke[Das Zusammenspiel der beiden Handbücher: Git regelt, *welcher Code* ausgeliefert wird. Die CI baut einen Kandidaten, versieht ihn mit SBOM und Provenance und prüft exakt seinen Digest. Docker Compose startet genau diesen unveränderlichen Digest mit Daten, Geheimnissen und Netzen. Zurückdrehen lässt sich die Anwendung; Datenbankänderungen brauchen zusätzlich ein bewusstes Migrations- und Restore-Konzept.]

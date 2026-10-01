#import "lib.typ": *

= CI-Gates, Secrets und Repository-Struktur

Eine gute Pipeline sammelt nicht möglichst viele Werkzeuge. Sie beantwortet für jede Änderung wenige klare Fragen: Ist der Code korrekt? Ist er wartbar? Enthält er bekannte Schwachstellen oder Geheimnisse? Ist das gebaute Artefakt das geprüfte Artefakt? Und darf genau dieser Stand in genau diese Umgebung ausgerollt werden?

== Vier Stufen statt eines einzigen großen Jobs

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0.7, 0), [*Check* #linebreak() #text(size: 6pt)[Format, Lint, Tests]], w: 2.9, h: 1.1, bg: rgb("#FDF1EC"), col: c-accent, size: 6.8pt)
    kasten((4.5, 0), [*Quality & Security* #linebreak() #text(size: 6pt)[Sonar, Semgrep, Trivy]], w: 3.0, h: 1.1, bg: rgb("#FFF4D6"), col: c-yellow, size: 6.8pt)
    kasten((8.4, 0), [*Build* #linebreak() #text(size: 6pt)[Image, SBOM, Digest]], w: 2.9, h: 1.1, bg: rgb("#EAF1FB"), col: c-blue, size: 6.8pt)
    kasten((12.3, 0), [*Deploy* #linebreak() #text(size: 6pt)[Staging, Produktion]], w: 2.9, h: 1.1, bg: rgb("#EEF6E6"), col: c-gitea, size: 6.8pt)
    pfeil((2.2, 0), (3.0, 0)); pfeil((6.05, 0), (6.9, 0)); pfeil((9.9, 0), (10.8, 0))
    content((6.5, -1.0), text(size: 6.6pt, fill: c-grey.darken(20%), style: "italic")[schnell links, privilegiert und selten rechts])
  }),
  caption: [Je weiter rechts ein Job steht, desto stärker sind seine Rechte und desto strenger muss seine Ausführung begrenzt sein.],
)

Die Stufen dürfen auf mehrere Workflow-Dateien verteilt sein. Dadurch bleiben Statusprüfungen verständlich und ein PR wartet nicht auf einen Deployment-Job, der dort ohnehin nichts zu tun hat.

#table(columns: (auto, 1fr, 1fr, auto),
  [Gate], [Typische Prüfungen], [Werkzeuge], [Wann],
  [*Check*], [Format, Lint, Typen, Unit- und Integrationstests, Buildbarkeit], [projektnahe Befehle über `make check` und `make test`], [jeder PR],
  [*Quality*], [Duplikate, Komplexität, Coverage, Bugs, Wartbarkeit], [SonarQube oder sprachspezifische Linter], [`main`, bei passender Edition zusätzlich PR @sonarsource-com-blog-sonarqube-compare-editions],
  [*Security*], [SAST, Abhängigkeiten, Secrets, IaC und Container-Image], [Semgrep und Trivy @docs-semgrep-dev-getting-started-cli @trivy-dev-latest-docs-target-filesystem], [PR sowie gebautes Image],
  [*Build*], [reproduzierbares Artefakt, SBOM, unveränderlicher Digest], [Docker/BuildKit @docs-docker-com-reference-cli-docker-buildx-build, Trivy, Registry], [nach grünen Quellcode-Checks],
  [*Deploy*], [Version, Ziel, Migration, Healthcheck, Smoke-Test, Rollback], [eingeschränkter SSH-/API-Zugang], [`main` nach Staging, geschützter Tag nach Produktion],
)

== Welche Checks wirklich sinnvoll sind

=== Check: schnell, deterministisch und lokal ausführbar

Der wichtigste Vertrag ist kein CI-Anbieter, sondern das Repository selbst:

```make
.PHONY: check test
check:
	./scripts/format-check
	./scripts/lint
	./scripts/typecheck

test:
	./scripts/unit-test
	./scripts/integration-test
```

CI führt `make check` und `make test` aus; Entwickler führen dieselben Befehle lokal aus. Formatter, Linter und Compiler werden über Lockfile, Tool-Datei oder ein gepinntes CI-Image versioniert. Ein flüchtiger Fehler wird nicht durch drei automatische Wiederholungen versteckt: Flaky Tests werden repariert oder ausdrücklich isoliert.

=== SonarQube: übergreifende Codequalität

SonarQube eignet sich für langfristige Trends, Duplikate, Coverage und ein zentrales Quality Gate. Die kostenlose Community Build analysiert den Hauptbranch; Branch- und Pull-Request-Analysen gehören zu anderen SonarQube-Varianten @sonarsource-com-blog-sonarqube-compare-editions @sonarsource-com-products-sonarqube-downloads. Deshalb läuft die Community Build typischerweise nach dem Merge auf `main`. Das Quality Gate blockiert dort den Build oder das Staging-Deployment.

Ein Quality Gate sollte vor allem *neuen Code* schützen @docs-sonarsource-com-sonarqube-community-build-user-guide-about-new-code: keine neuen Blocker-/Critical-Befunde, ausreichende Coverage für neuen Code und keine unreviewten Security Hotspots. Starre Gesamt-Coverage auf einem Altprojekt erzeugt dagegen oft Arbeit ohne Risikogewinn.

=== Semgrep: SAST mit verständlichen Regeln

Semgrep sucht Sprachmuster und Sicherheitsfehler direkt im Quellcode. Die Community-Variante kann ohne Cloudkonto laufen @docs-semgrep-dev-getting-started-cli:

```bash
semgrep scan --config auto --error .
```

`auto` lädt passende Regeln aus der Semgrep Registry @docs-semgrep-dev-cli-reference. Für reproduzierbare, vertrauliche oder offline betriebene Pipelines werden freigegebene Regeln in einem internen Repository versioniert und mit `--config .semgrep/` verwendet @docs-semgrep-dev-cli-reference. Zunächst läuft Semgrep sichtbar, aber nicht blockierend; nach Bereinigung und Baseline werden neue High-Confidence-Befunde zum Gate. Jede Ausnahme braucht Regel-ID, Begründung, Verantwortlichen und Ablaufdatum.

=== Trivy: Abhängigkeiten, IaC, Secrets und Images

Trivy deckt mehrere andere Risikoflächen ab. Vor dem Build prüft es Repository, Lockfiles und Infrastrukturcode @trivy-dev-latest-docs-target-filesystem:

```bash
trivy fs \
  --scanners vuln,misconfig,secret \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 .
```

Nach dem Build wird das echte Container-Image geprüft @trivy-dev-latest-docs-target-container-image:

```bash
trivy image \
  --scanners vuln,misconfig,secret \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 "$IMAGE:$GITHUB_SHA"

trivy image --format cyclonedx --output sbom.cdx.json "$IMAGE:$GITHUB_SHA"
```

Die beiden Läufe sind nicht redundant: Der Dateisystemscan sieht Lockfiles und IaC @trivy-dev-latest-docs-target-filesystem, der Image-Scan zusätzlich Betriebssystempakete und den tatsächlichen Inhalt aller Schichten @trivy-dev-latest-docs-target-container-image. `--ignore-unfixed` ist eine bewusste Policy-Entscheidung @trivy-dev-latest-docs-configuration-filtering; bei besonders kritischen Produkten werden auch nicht behobene Critical-Befunde sichtbar gehalten, selbst wenn sie den Build noch nicht blockieren.

#merke[SonarQube, Semgrep und Trivy überschneiden sich teilweise, haben aber verschiedene Schwerpunkte: SonarQube bewertet Codequalität und Trends, Semgrep findet quelltextnahe Sicherheitsmuster, Trivy prüft bekannte Schwachstellen, Konfiguration, Secrets und Images. Zwei Werkzeuge mit demselben Zweck erhöhen ohne abgestimmte Zuständigkeit nur das Rauschen.]

== Referenzworkflow für Pull Requests

Der PR-Workflow bekommt keine Deployment-Secrets und nur Leserechte. Die drei Jobs laufen parallel und liefern stabile Namen für den Branch-Schutz:

#datei(".gitea/workflows/check.yml")[
```yaml
name: check

on:
  pull_request:
  push:
    branches-ignore: [main]

permissions:
  contents: read

jobs:
  code:
    runs-on: untrusted-checks
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - run: make setup
      - run: make check

  test:
    runs-on: untrusted-checks
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v4
      - run: make setup
      - run: make test

  security-source:
    runs-on: untrusted-checks
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4
      - run: semgrep scan --config .semgrep/ --error .
      - run: >-
          trivy fs --scanners vuln,misconfig,secret
          --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 .
```
]

Das Label `untrusted-checks` gehört zu einem Runner-Pool ohne Produktionsnetz, ohne Organisations-Secrets und möglichst ohne Host-Docker-Socket @cheatsheetseries-owasp-org-cheatsheets-docker-security-cheat-sheet-html. Fremder PR-Code ist ausführbarer Fremdcode. Besonders bei öffentlichen Repositories darf ein PR nicht automatisch auf einem privilegierten, dauerhaften Runner starten @docs-github-com-en-actions-reference-security-secure-use. Gitea 1.27.3 schließt eine konkrete Umgehung der Freigabe für erstmalige Fork-Beiträge @blog-gitea-com-release-of-1-27-3; ältere 1.27-Versionen gehören deshalb nicht mehr in eine solche Umgebung.

Actions und Scanner werden in echten Workflows nicht nur mit einem Hauptversions-Tag, sondern mit vollständigem Commit- beziehungsweise Image-Digest gepinnt @docs-github-com-en-actions-reference-security-secure-use @docs-docker-com-build-building-best-practices. Die lesbaren Versionen im Beispiel machen nur den Aufbau deutlich. Renovate aktualisiert diese Pins über Review-PRs @docs-renovatebot-com-docker @docs-renovatebot-com-modules-manager-github-actions.

Das Runner-Image hinter `untrusted-checks` stellt die im Beispiel verwendeten, versionierten Werkzeuge bereit. Alternativ bekommt jeder Scanner einen eigenen Job mit einem auf Digest gepinnten Job-Container. Werkzeuge während jedes Laufs ungeprüft mit `curl | sh` nachzuladen, ist weder reproduzierbar noch eine sinnvolle Lieferkettenkontrolle.

== Build und Deployment: nur das geprüfte Artefakt

Ein sauberer Build erzeugt das Image genau einmal. Nach dem Scan wird es in die Registry übertragen, sein Digest festgehalten und genau dieser Digest ausgerollt. `latest` ist kein Deployment-Nachweis @docs-docker-com-build-building-best-practices.

```bash
IMAGE="gitea.example.com/team/demo"
TAG="$GITHUB_SHA"

docker build --pull -t "$IMAGE:$TAG" .
trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 "$IMAGE:$TAG"
trivy image --format cyclonedx --output sbom.cdx.json "$IMAGE:$TAG"
docker push "$IMAGE:$TAG"

DIGEST="$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE:$TAG")"
printf 'image=%s\n' "$DIGEST" >> "$GITHUB_OUTPUT"
```

Das Deployment erhält `needs.build.outputs.image` und startet diesen Digest. Danach folgen Datenbankmigrationen mit eigener Rückrollstrategie, Healthcheck und ein kleiner Smoke-Test. Erst wenn alles grün ist, wird der neue Stand als aktiv markiert. Kapitel 14 zeigt den eingeschränkten SSH-Zugang und Kapitel 15 den vollständigen Ablauf für Staging und Produktion.

== Secrets, Variablen und Job-Tokens

Gitea speichert Actions-Secrets und Variablen auf Benutzer-, Organisations- und Repository-Ebene @docs-gitea-com-usage-actions-secrets @docs-gitea-com-usage-actions-actions-variables. Bei gleichem Namen gewinnt die spezifischere Ebene; ein Repository-Wert überschreibt also den Organisationswert @docs-gitea-com-usage-actions-secrets @docs-gitea-com-usage-actions-actions-variables.

#table(columns: (auto, 1fr, 1fr),
  [Mittel], [Geeignet für], [Nicht geeignet für],
  [Variable (`vars`)],[Hostnamen, Feature-Schalter, nicht geheime Pfade],[Passwörter, Tokens, private Schlüssel],
  [Actions-Secret],[API-Token, Registry-Passwort, privater Deployment-Schlüssel],[Werte, die jedes Repository der Organisation nicht wirklich braucht],
  [`GITEA_TOKEN`],[Repository-Inhalte und API-Aufrufe des aktuellen Jobs @docs-gitea-com-usage-actions-token-permissions],[organisationsweiter Bot oder dauerhaftes Deployment-Konto],
  [Deploy Key],[maschinelles Klonen genau eines Gitea-Repositories @docs-gitea-com-api-operations-repo-create-key],[Zugriff auf viele Repositories oder den Zielserver],
)

Für das automatische Job-Token werden die Rechte ausdrücklich gesetzt:

```yaml
permissions:
  contents: read
  packages: read
```

Job- und Workflow-`permissions` wirken nur auf `GITEA_TOKEN`, nicht auf selbst angelegte PATs @docs-gitea-com-usage-actions-token-permissions. Zugriff auf andere private Repositories ist standardmäßig verweigert; ausgewählte Leserechte können unter _Actions -> General -> Cross-Repository Access_ freigegeben werden @docs-gitea-com-usage-actions-token-permissions. Ein PAT bleibt die Ausnahme, weil seine Laufzeit und Reichweite nicht automatisch an einen einzelnen Job gebunden sind.

Secrets werden nicht in Befehlszeilenargumente, Artefakte oder Debug-Ausgaben geschrieben. Sie gehen über Standardeingabe oder eine Datei mit Modus `0600` an das Werkzeug und werden mit `trap` entfernt @docs-github-com-en-actions-reference-security-secure-use. Log-Maskierung hilft nur gegen versehentliche Ausgabe @docs-github-com-en-actions-reference-security-secure-use; bösartiger Workflow-Code kann ein Secret verändern, stückeln oder an einen fremden Server senden.

#achtung[Organisations-Secrets sind bequem, vergrößern aber den Explosionsradius @docs-github-com-en-actions-reference-security-secure-use. Gemeinsame lesende Tokens dürfen organisationsweit liegen. Produktionsschlüssel, Signierschlüssel und Renovate-PATs bleiben in einem dedizierten Repository oder besser in einem externen Secret-Manager. Rotation, Ablaufdatum, Besitzer und letzter Test werden dokumentiert.]

== Deploy Keys richtig einordnen

Ein Gitea-_Deploy Key_ ist ein öffentlicher SSH-Schlüssel in den Einstellungen *eines Repositories*. Er ist standardmäßig nur lesend @raw-githubusercontent-com-go-gitea-gitea-main-templates-repo-settings-deploy-keys-tmpl und eignet sich etwa für einen Server, der genau dieses Repository auschecken muss. Schreibzugriff wird nur aktiviert, wenn der konkrete Automat tatsächlich pushen soll.

Für Renovate ist ein Deploy Key ungeeignet: Der Bot braucht API-Zugriff, Issues und Pull Requests in mehreren Repositories und verwendet deshalb ein eigenes Konto mit PAT @docs-renovatebot-com-modules-platform-gitea. Auch der SSH-Schlüssel zum Zielserver aus Kapitel 14 ist kein Gitea-Deploy-Key; er wird im `authorized_keys` des Zielservers auf einen einzigen Deployment-Befehl beschränkt @man-openbsd-org-sshd-8.

Für jeden Verbraucher wird ein eigenes Schlüsselpaar erzeugt. So lässt sich ein kompromittierter Server sperren, ohne alle Deployments zu unterbrechen. Private Schlüssel werden nie zwischen Repositories kopiert. Ein schreibender Deploy Key umgeht keine Branch-Schutzregeln absichtlich @docs-gitea-com-usage-access-control-protected-branches; wenn der technische Weg Regeln umgehen könnte, ist ein Bot-Konto mit normalem PR-Verfahren die bessere Wahl.

== Einzelne Repositories oder Organisation?

#table(columns: (auto, 1fr, 1fr),
  [Variante], [Passt gut für], [Grenzen],
  [persönliches Repository],[Experiment, Kursdemo, privates Einzelprojekt],[Besitz hängt an einer Person; keine Teamrollen, weniger zentrale Runner-/Secret-/Workflow-Verwaltung],
  [Organisations-Repository],[Teamprodukt, gemeinsamer Betrieb, mehrere Dienste],[Organisationsweite Runner und Secrets brauchen klare Vertrauenszonen],
  [mehrere Organisationen],[getrennte Kunden, Sicherheitszonen oder Verantwortlichkeiten],[mehr Verwaltungsaufwand; gemeinsame Automatisierung muss bewusst geteilt werden],
)

Für produktive Team-Repositories ist eine Organisation normalerweise die bessere Heimat. Rechte werden über Teams statt über einzelne Collaborators vergeben @docs-gitea-com-usage-permissions. Organisationseigene Runner, Variablen, Secrets und zentrale _Scoped Workflows_ können mehrere Repositories konsistent versorgen @docs-gitea-com-usage-actions-runner @docs-gitea-com-usage-actions-scoped-workflows. Scoped Workflows laufen dabei im Kontext des jeweiligen Ziel-Repositories: mit dessen Runnern, Secrets, Job-Token und Commit @docs-gitea-com-usage-actions-scoped-workflows.

Eine kleine Struktur kann so aussehen:

```text
organisation/
  app-web                 Produktcode
  app-api                 Produktcode
  platform-ci             geprüfte Scoped Workflows und Regeln
  renovate                geschützter Renovate-Runner und globale Konfiguration
  deploy-manifests        gewünschter Betriebsstand, besonders streng geschützt
```

Teams wie `developers`, `maintainers` und `platform` bekommen nur die benötigten Repository-Einheiten und Rechte. Das Plattformteam verwaltet Runner, gemeinsame Workflows und Produktionszugänge; Entwickler ändern Produktcode über PRs. Ein organisationsweiter Runner ist keine Isolation @docs-gitea-com-usage-actions-runner @docs-gitea-com-usage-actions-overview: Repositories mit unterschiedlichem Vertrauen bekommen getrennte Runner-Pools oder getrennte Organisationen.

== Eine pragmatische Zielarchitektur

#table(columns: (1fr, 1fr, 1fr),
  [Bereich], [Runner/Identität], [Pflicht-Gates],
  [Pull Requests],[ephemerer oder stark isolierter `untrusted-checks`-Runner, keine Secrets],[Format, Lint, Typen, Tests, Semgrep, Trivy-Dateisystemscan],
  [`main`],[vertrauenswürdiger Build-Runner, Registry-Token nur für diesen Job],[erneute Tests, Sonar-Quality-Gate, Build, Image-Scan, SBOM],
  [Staging],[eingeschränkter Deployment-Schlüssel für Staging],[Digest-Deployment, Migration, Healthcheck, Smoke-Test],
  [Produktion],[separater Produktionsschlüssel, geschützter Tag und Review],[bereits geprüftes Image, Freigabe, Healthcheck, Rollback],
  [Renovate],[geschütztes Automatisierungs-Repository, eigenes Bot-Konto],[Konfigurationsprüfung, PR statt Direkt-Push, normale CI-Gates],
)

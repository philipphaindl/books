#import "lib.typ": *

= Dependency-Bots mit Renovate

Abhängigkeiten veralten auch dann, wenn sich der eigene Code nicht ändert. Bibliotheken, Container-Images, Actions und Tool-Versionen bekommen Fehlerkorrekturen und Sicherheitsupdates. Ein _Dependency-Bot_ sucht diese Änderungen, aktualisiert Versionsangaben und Lockfiles und eröffnet normale Pull Requests @docs-renovatebot-com. Er ersetzt weder Tests noch Reviews: Er sorgt dafür, dass Updates klein, sichtbar und regelmäßig eintreffen.

Dieses Kapitel verwendet Renovate als Beispiel. Renovate unterstützt Gitea direkt @docs-renovatebot-com-modules-platform-gitea, kann Repositories automatisch finden @docs-renovatebot-com-self-hosted-configuration und versteht viele Paketmanager sowie Docker-, Compose-, Terraform- und Workflow-Dateien @docs-renovatebot-com-modules-manager @docs-renovatebot-com-modules-manager-github-actions.

== Der sichere Ablauf

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0.7, 0), [geschütztes Repo #linebreak() #text(size: 6pt)[`platform/renovate`]], w: 2.8, h: 1.0, bg: rgb("#EAF1FB"), col: c-blue, size: 6.8pt)
    kasten((4.5, 0), [Gitea Runner #linebreak() #text(size: 6pt)[geplanter Job]], w: 2.7, h: 1.0, bg: rgb("#EAF1FB"), col: c-blue, size: 6.8pt)
    kasten((8.3, 0), [Renovate #linebreak() #text(size: 6pt)[Bot-Konto + PAT]], w: 2.7, h: 1.0, bg: rgb("#EEF6E6"), col: c-gitea, size: 6.8pt)
    kasten((12.5, 0.6), [Repository A #linebreak() #text(size: 6pt)[Update-PR]], w: 2.6, h: 0.8, bg: rgb("#FDF1EC"), col: c-accent, size: 6.8pt)
    kasten((12.5, -0.6), [Repository B #linebreak() #text(size: 6pt)[Update-PR]], w: 2.6, h: 0.8, bg: rgb("#FDF1EC"), col: c-accent, size: 6.8pt)
    pfeil((2.15, 0), (3.1, 0))
    pfeil((5.9, 0), (6.9, 0))
    pfeil((9.7, 0.15), (11.15, 0.55))
    pfeil((9.7, -0.15), (11.15, -0.55))
    content((12.5, -1.35), text(size: 6.4pt, fill: c-grey.darken(20%), style: "italic")[CI, Review, Branch-Schutz])
  }),
  caption: [Renovate arbeitet als eigener Dienstbenutzer. Seine Änderungen nehmen denselben PR- und CI-Weg wie menschliche Änderungen.],
)

Die wichtigste Trennung lautet: *Der Runner führt Renovate aus; das Bot-Konto ändert Repositories.* Das Registrierungstoken des Runners, das automatische `GITEA_TOKEN` eines Jobs und der persönliche Zugriffstoken (PAT) des Bots sind drei verschiedene Zugangsdaten:

#table(columns: (auto, 1fr, 1fr),
  [Zugangsdaten], [Zweck], [Reichweite],
  [Runner-Registrierungstoken], [einen Runner bei Gitea registrieren], [Instanz, Organisation oder ein Repository; nach Registrierung nicht mehr im laufenden Job nötig @docs-gitea-com-runner-registration],
  [`GITEA_TOKEN`], [API- und Git-Zugriff des aktuellen Jobs], [standardmäßig das Repository des Jobs; Rechte über `permissions:` begrenzen @docs-gitea-com-usage-actions-token-permissions],
  [Renovate-PAT], [Branches, Issues und Pull Requests des Bot-Kontos], [alle Repositories, auf die das Bot-Konto tatsächlich Zugriff hat],
)

#achtung[Ein organisationsweiter Renovate-PAT gehört nicht als Organisations-Secret in alle Projekt-Repositories. Ein veränderbarer Projekt-Workflow könnte ihn sonst verwenden. Das Secret liegt ausschließlich in einem kleinen, besonders geschützten Automatisierungs-Repository, auf das nur die Plattformverantwortlichen Schreibzugriff haben.]

== Ein Bot-Konto statt eines persönlichen Kontos

Lege in Gitea einen eigenen Benutzer `renovate-bot` mit Name und E-Mail-Adresse an. Gib diesem Konto nur Zugriff auf die Organisationen und Repositories, die es pflegen soll. Für den PAT nennt Renovate bei aktuellem Gitea folgende Rechte @docs-renovatebot-com-modules-platform-gitea:

- `repo`: Lesen und Schreiben
- `user`: Lesen
- `issue`: Lesen und Schreiben
- `organization`: Lesen, falls Organisationslabels oder Teams gelesen werden
- zusätzlich `read:packages`, wenn Pakete aus der Gitea-Registry ausgewertet werden

Der PAT kommt als `RENOVATE_TOKEN` @docs-renovatebot-com-modules-platform-gitea in ein Repository-Secret des geschützten Automatisierungs-Repositories. Er steht weder in `config.js` noch in `renovate.json`, `.env`, Compose-Dateien oder Shell-History. Für Changelogs und Release Notes von github.com kann optional ein eigener, nur lesender `RENOVATE_GITHUB_COM_TOKEN` nötig sein @docs-renovatebot-com-getting-started-running; auch dieser Token bekommt ein eigenes Secret.

#praxis[Für mehrere Sicherheitszonen sind mehrere Bot-Konten besser als ein allmächtiges Konto: etwa `renovate-internal` für interne Dienste und `renovate-public` für öffentliche Projekte. Ein kompromittierter Token erreicht dann nicht automatisch alle Repositories.]

== Zentraler Lauf auf einem Runner

Renovate kann als CronJob, geplanter Container oder Gitea-Workflow laufen @docs-renovatebot-com-getting-started-running. Für eine kleine Gitea-Installation ist ein geplanter Workflow in einem geschützten Repository gut nachvollziehbar: Konfiguration, Laufprotokoll und verwendete Image-Version sind versioniert. Der Job läuft auf einem vertrauenswürdigen Organisations-Runner, nicht auf einem öffentlichen PR-Runner @docs-gitea-com-usage-actions-overview.

#datei("platform/renovate/.gitea/workflows/renovate.yml")[
```yaml
name: renovate

on:
  schedule:
    - cron: '17 */4 * * *'             # UTC: alle vier Stunden
  workflow_dispatch:

permissions:
  contents: read                        # betrifft nur das automatische GITEA_TOKEN

jobs:
  renovate:
    runs-on: trusted-automation
    timeout-minutes: 60
    container: renovate/renovate:44.115.2
    env:
      RENOVATE_CONFIG_FILE: ${{ gitea.workspace }}/config.js
      RENOVATE_TOKEN: ${{ secrets.RENOVATE_TOKEN }}
      RENOVATE_GITHUB_COM_TOKEN: ${{ secrets.RENOVATE_GITHUB_COM_TOKEN }}
      LOG_LEVEL: info
    steps:
      - uses: actions/checkout@v4
      - name: Konfiguration prüfen
        run: renovate-config-validator config.js
      - name: Repositories aktualisieren
        run: renovate
```
]

Das Beispiel pinnt eine lesbare Renovate-Version. Produktiv wird das Image zusätzlich auf einen geprüften Digest festgelegt; anschließend darf Renovate genau diesen Pin über einen normalen PR aktualisieren @docs-renovatebot-com-docker. `schedule` bestimmt, wann der Backend-Prozess startet @raw-githubusercontent-com-go-gitea-gitea-main-models-actions-schedule-spec-go. Zeitfenster in einer Repository-Konfiguration können Updates weiter einschränken, aber keinen häufigeren Lauf erzwingen @docs-renovatebot-com-configuration-options @docs-renovatebot-com-getting-started-running.

#merke[Ein dauerhafter Cron-Container ist genauso möglich und entkoppelt Renovate vollständig von Actions. Der Sicherheitsgrundsatz bleibt gleich: eigener Dienstbenutzer, minimaler PAT, feste Image-Version, eingeschränkter Netzwerkzugriff und eine Konfiguration, die Projekt-Repositories nicht überschreiben können.]

== Die globale Konfiguration

Selbst gehostete Optionen gehören in die vom Plattformteam kontrollierte `config.js` @docs-renovatebot-com-self-hosted-configuration. Projekt-Repositories bekommen nur die dort ausdrücklich erlaubte Repository-Konfiguration.

#datei("platform/renovate/config.js")[
```javascript
module.exports = {
  platform: 'gitea',
  endpoint: 'https://gitea.example.com/api/v1',
  autodiscover: true,
  autodiscoverTopics: ['managed-by-renovate'],
  onboarding: true,
  onboardingConfig: {
    extends: ['config:recommended'],
  },
  dependencyDashboard: true,
  prHourlyLimit: 4,
  prConcurrentLimit: 10,
  branchConcurrentLimit: 10,
  useCloudMetadataServices: false,
};
```
]

Nur Repositories mit dem Topic `managed-by-renovate` werden gefunden @docs-renovatebot-com-self-hosted-configuration. Das ist sicherer und übersichtlicher als ein ungefiltertes `autodiscover` über alles, was das Bot-Konto sehen kann @docs-renovatebot-com-self-hosted-configuration. Alternativ begrenzen `autodiscoverNamespaces` oder `autodiscoverFilter` die Menge @docs-renovatebot-com-self-hosted-configuration. Mirror-Repositories, Repositories ohne Push-/Pull-Recht und Repositories ohne Pull Requests überspringt die Gitea-Integration @docs-renovatebot-com-modules-platform-gitea.

`useCloudMetadataServices: false` verhindert unnötige Versuche, Cloud-Metadatendienste zu verwenden @docs-renovatebot-com-self-hosted-configuration. Zusätzlich sollte der Runner nur die wirklich nötigen Ziele erreichen: Gitea, die verwendeten Paketregistries und gegebenenfalls github.com für Changelogs. Interne Registries erhalten eng passende `hostRules` @docs-renovatebot-com-self-hosted-configuration; Anmeldedaten kommen dabei aus Umgebungsvariablen, nicht aus dem Repository.

== Konfiguration pro Repository

Die erste Ausführung eröffnet normalerweise einen Onboarding-PR mit `renovate.json`. Erst nach dessen Merge beginnt Renovate mit regulären Update-PRs @docs-renovatebot-com-getting-started-installing-onboarding. Eine vernünftige Ausgangskonfiguration hält die Zahl paralleler PRs klein und behandelt Hauptversionen sichtbar anders:

#datei("renovate.json")[
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "timezone": "Europe/Vienna",
  "schedule": ["* 20-23,0-5 * * 1-5"],
  "dependencyDashboard": true,
  "labels": ["dependencies"],
  "packageRules": [
    {
      "matchUpdateTypes": ["patch", "minor"],
      "groupName": "regelmaessige Abhaengigkeitsupdates"
    },
    {
      "matchUpdateTypes": ["major"],
      "addLabels": ["breaking-change"],
      "minimumReleaseAge": "7 days"
    },
    {
      "matchManagers": ["dockerfile", "docker-compose", "github-actions"],
      "pinDigests": true
    }
  ]
}
```
]

Die Zeitangabe ist ein erlaubtes Renovate-Zeitfenster, kein exakter Starttermin @docs-renovatebot-com-configuration-options. Lockfiles werden im PR mitaktualisiert; dafür muss das Renovate-Image die passenden Werkzeuge enthalten oder sie kontrolliert bereitstellen können @docs-renovatebot-com-getting-started-running @docs-renovatebot-com-self-hosted-configuration. Nach Änderungen an `renovate.json` läuft `renovate-config-validator` als normale CI-Prüfung @docs-renovatebot-com-config-validation.

=== Automerge nur als bewusste Ausnahme

Automatisches Mergen ist erst sinnvoll, wenn Branch-Schutz, erforderliche Statusprüfungen und reproduzierbare Tests stabil sind @docs-renovatebot-com-configuration-options. Ein möglicher enger Einstieg sind Patch-Updates reiner Entwicklungsabhängigkeiten:

```json
{
  "matchDepTypes": ["devDependencies"],
  "matchUpdateTypes": ["patch"],
  "automerge": true,
  "platformAutomerge": true
}
```

Auch dann muss der PR alle erforderlichen Checks bestehen. Hauptversionen, Runtime-Abhängigkeiten, Basis-Images, Datenbanken, Compiler, Actions und Sicherheitswerkzeuge bleiben Review-pflichtig. Wenn ein Paket kompromittiert wird, beschleunigt blindes Automerge sonst gerade den Angriff.

== Betrieb und Fehlersuche

#table(columns: (1fr, 1.35fr),
  [Symptom], [Prüfung],
  [Repository wird nicht gefunden], [Topic, Pull-Request-Einheit und Rechte des Bot-Kontos prüfen @docs-renovatebot-com-modules-platform-gitea; bei Filtern den vollständigen Pfad `organisation/repo` verwenden.],
  [Onboarding-PR kommt immer wieder], [Onboarding-Branch oder Titel wurde geändert beziehungsweise der alte PR geschlossen @docs-renovatebot-com-getting-started-installing-onboarding; Verlauf und globale Konfiguration prüfen.],
  [Lockfile wird nicht aktualisiert], [Benötigter Paketmanager fehlt im Image oder darf nicht heruntergeladen werden; vollständiges Renovate-Image beziehungsweise kontrolliertes Werkzeug-Image verwenden @docs-renovatebot-com-getting-started-running @docs-renovatebot-com-self-hosted-configuration.],
  [Zu viele PRs], [`prHourlyLimit`, `prConcurrentLimit`, Gruppierung und Zeitfenster enger setzen @docs-renovatebot-com-configuration-options; alte Dashboard-Einträge aufräumen.],
  [Private Registry liefert 401/403], [`hostRules`, Hostname einschließlich Port, Token-Reichweite und Netzwerkzugriff des Runners prüfen.],
  [PR ist grün, aber riskant], [Automerge stoppen; Changelog, Transitivabhängigkeiten, Lizenz, Migrationshinweise und reale Integrationstests prüfen.],
)

Für den Alltag genügen vier Kontrollen: Der Bot lief zuletzt erfolgreich, sein PAT läuft nicht unbemerkt ab, offene Sicherheitsupdates altern nicht, und Renovate selbst wird regelmäßig aktualisiert. Die Dependency-Dashboard-Issue dient dabei als Arbeitsliste, nicht als Ersatz für Monitoring @docs-renovatebot-com-key-concepts-dashboard.

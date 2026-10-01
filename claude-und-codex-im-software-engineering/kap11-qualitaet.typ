#import "lib.typ": *

= Qualitätssicherung im Ablauf

Die vorigen Kapitel haben die Einzelteile beschrieben. Dieses Kapitel setzt sie zu einem Ablauf zusammen, in dem Qualität nicht vom Glück abhängt, sondern von Prüfungen, die jede Änderung durchlaufen muss.

== Die Prüfpyramide

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let ebenen = (
      ([*Deterministische Prüfungen* #h(4pt) Formatierer, Linter, Typprüfung, Tests, Import-Verträge, Sicherheitsscan ], 14.0, c-gitea),
      ([*Review durch zweites Modell* #h(4pt) gegen FR und ADR, belegte Befunde], 10.5, c-teal),
      ([*Menschliches Review* #h(4pt) Entscheidung, Verantwortung], 7.5, c-blue),
    )
    for (i, e) in ebenen.enumerate() {
      let y = i * 0.85
      let w = e.at(1)
      rect((-w / 2, y - 0.36), (w / 2, y + 0.36), radius: 0.08, fill: e.at(2).lighten(86%), stroke: (paint: e.at(2), thickness: 0.8pt))
      content((0, y), text(size: 7.2pt, e.at(0)))
    }
  }),
  caption: [Unten billig, schnell und bei jeder Änderung, oben teuer und gezielt. Was sich deterministisch prüfen lässt, prüft kein Modell und kein Mensch.],
)

Die Reihenfolge ist entscheidend. Ein Modell-Review, das Formatierungsfehler meldet, verschwendet Aufmerksamkeit, und ein Mensch, der prüft, ob Tests laufen, ebenso. Jede Ebene kümmert sich um das, was nur sie leisten kann.

#table(columns: (auto, auto, 1fr),
  [Prüfung], [Befehl (ausgeführt mit uv @uv)], [findet],
  [Formatierung, Stil], [`uv run ruff format`, `ruff check` @ruff], [Stil, einfache Fehler, unsichere Muster (Regeln `S`)],
  [Typen], [`uv run mypy app/` @mypy oder `pyright`], [erfundene Attribute und Signaturen, falsche Typen],
  [Tests], [`uv run pytest`], [Verhalten gegen Akzeptanzkriterien],
  [Architektur], [`uv run lint-imports` @import-linter], [ADR-Verstöße],
  [Abhängigkeiten], [`uv run pip-audit` @pip-audit], [bekannte Schwachstellen],
)

Die Typprüfung verdient besondere Erwähnung: Sie ist das günstigste Mittel gegen erfundene APIs, weil sie jede nicht existierende Methode und jeden falschen Parameter sofort meldet.

== Taugen die Tests? Mutation Testing

Wenn Tests das Orakel sind (Kapitel 7), hängt alles an ihrer Qualität. Von Agenten geschriebene Tests haben eine typische Schwäche: Sie laufen grün, prüfen aber zu wenig, etwa nur den Normalfall oder nur, dass kein Fehler auftritt. Die Testabdeckung zeigt das nicht, denn sie misst nur, welcher Code ausgeführt wurde, nicht, ob ein Fehler aufgefallen wäre.

_Mutation Testing_ beantwortet genau diese Frage @jia-harman. Ein Werkzeug baut kleine, gezielte Fehler in den Code ein (_Mutanten_), etwa `>` statt `>=` oder `False` statt `True`, und führt die Tests aus. Schlägt ein Test fehl, ist der Mutant "getötet", die Tests hätten den Fehler bemerkt. Laufen alle Tests weiter grün, hat der Mutant "überlebt", und das ist eine Lücke in den Tests.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [`if len(tags) > 10:`], w: 3.0, h: 0.8, bg: white, col: c-dark, size: 7.3pt)
    kasten((4.4, 0), [Mutant \ `if len(tags) >= 10:`], w: 3.2, h: 1.0, bg: rgb("#FBEAEA"), col: c-red, size: 7.3pt)
    kasten((8.8, 0), [Tests \ ausführen], w: 2.2, h: 1.0, bg: rgb("#EEF6E6"), col: c-gitea, size: 7.3pt)
    kasten((13.0, 0.7), [Test rot: *getötet* \ #text(size: 6.3pt)[Lücke nicht vorhanden]], w: 3.4, h: 0.95, bg: rgb("#EEF6E6"), col: c-gitea, size: 7pt)
    kasten((13.0, -0.7), [alles grün: *überlebt* \ #text(size: 6.3pt)[Test für genau 10 Tags fehlt]], w: 3.4, h: 0.95, bg: rgb("#FBEAEA"), col: c-red, size: 7pt)
    pfeil((1.55, 0), (2.75, 0)); pfeil((6.05, 0), (7.65, 0))
    pfeil((9.95, 0.15), (11.25, 0.65)); pfeil((9.95, -0.15), (11.25, -0.65))
  }),
  caption: [Ein überlebender Mutant zeigt eine konkrete Lücke: Niemand prüft den Grenzfall mit genau 10 Tags.],
)

Für Python ist _mutmut_ das verbreitete Werkzeug @mutmut. Ab Version 3.7 heißen die Konfigurationsschlüssel `source_paths` und `pytest_add_cli_args_test_selection`, die älteren Namen `paths_to_mutate` und `tests_dir` gelten als veraltet:

#datei("pyproject.toml (Auszug)")[
```toml
[tool.mutmut]
source_paths = ["app/"]
pytest_add_cli_args_test_selection = ["tests/"]
```
]

```bash
uv add --dev mutmut
uv run mutmut run "app.notizen.tags*"      # nur das geänderte Modul, sonst dauert es lange
uv run mutmut results                      # überlebende Mutanten auflisten
uv run mutmut browse                       # interaktiv ansehen und gezielt neu testen
```

Die Ergebnisse legt mutmut im Verzeichnis `mutants/` ab, das in die `.gitignore` gehört. Das Werkzeug braucht ein System mit `fork`, also macOS oder Linux, unter Windows WSL @mutmut.

Für die Arbeit mit Agenten ergibt sich ein einfaches Muster: Nach der Umsetzung laufen die Mutanten *nur für die geänderten Module*. Die überlebenden Mutanten gehen als Auftrag an den Agenten: "Ergänze Tests, sodass diese Mutanten getötet werden. Ändere keinen Produktivcode." Meta setzt ein verwandtes Verfahren im Industrieeinsatz ein: Ein Sprachmodell erzeugt gezielt Tests, die bisher unentdeckte Fehler aufdecken @foster-meta. Das ist eine der wenigen Aufgaben, bei der ein Goal ideal passt, weil das Ende eindeutig messbar ist. Eine vollständige Mutationsanalyse über das ganze Projekt dauert zu lange für jeden Commit, sie passt besser in einen nächtlichen Lauf der CI. Ein Wert von 100 Prozent ist dabei kein sinnvolles Ziel, manche Mutanten verändern das Verhalten gar nicht. Es geht darum, dass die Grenzfälle der Akzeptanzkriterien abgesichert sind.

== Prüfungen automatisch auslösen: Hooks

Beide Werkzeuge können bei bestimmten Ereignissen Befehle ausführen. In Claude Code heißen sie _Hooks_ und werden in `settings.json` definiert @cc-hooks. Ein Hook nach jedem Bearbeiten von Dateien formatiert und prüft sofort, sodass der Agent Fehler im selben Schritt sieht:

#datei(".claude/settings.json (Auszug)")[
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "uv run ruff format --quiet && uv run ruff check --quiet" }
        ]
      }
    ]
  }
}
```
]

Ein Stop-Hook kann darüber hinaus verhindern, dass der Agent eine Aufgabe beendet, solange eine Prüfung fehlschlägt. Das ist die deterministische Variante eines Goals (Kapitel 9) @cc-goal. Codex bietet ebenfalls Hooks an, die in der Codex-Dokumentation unter _Hooks_ beschrieben sind @oa-hooks. Hooks sind mächtig, weil sie ohne Rückfrage laufen: Nur Befehle eintragen, die man auch einem Kollegen ohne Nachfrage erlauben würde.

== Berechtigungen und Sandbox

Qualität heißt auch, dass ein Agent nichts tun kann, was er nicht tun soll. Die Sicherheitsaspekte dazu vertieft Kapitel 12.

#table(columns: (auto, 1fr, 1fr),
  [], [Claude Code @cc-permissions @cc-security], [Codex @oa-approvals],
  [nur lesen und planen], [Berechtigungsmodus `plan`], [`/plan`, Sandbox `read-only`],
  [Normalbetrieb], [Standardmodus: fragt vor Änderungen und Befehlen, Freigaben über `permissions.allow`], [Sandbox `workspace-write` mit Freigabe bei Bedarf],
  [weitgehend selbstständig], [Auto-Modus: ein Klassifikator entscheidet über Rückfragen], [weniger Freigaben, gezielt pro Projekt],
  [Schutz sensibler Dateien], [`permissions.deny`, etwa `.env`, `secrets/`], [Sandbox-Regeln, Netzwerkzugriff standardmäßig aus],
)

Für unbeaufsichtigte Goals braucht es einen Modus, der nicht bei jedem Schritt fragt. Gerade dann gehören Tests und sensible Dateien geschützt und Netzwerkzugriff beschränkt.

== Checkliste für das Review von KI-Änderungen

#table(columns: (auto, 1fr),
  [], [Frage],
  [☐], [Deckt jeder Test genau ein Akzeptanzkriterium ab, und hat jedes Kriterium einen Test?],
  [☐], [Enthält der Diff etwas, das in keiner Anforderung steht (Scope Creep)?],
  [☐], [Wurden bestehende Tests geändert? Wenn ja: war das Teil des Auftrags?],
  [☐], [Neue Abhängigkeiten, Konfigurationsoptionen, Abstraktionen: verlangt oder nur möglich?],
  [☐], [Hält die Änderung alle referenzierten ADRs ein (und laufen die Import-Verträge)?],
  [☐], [Fehlerbehandlung an Systemgrenzen, nicht verstreut über interne Aufrufe?],
  [☐], [Sind alle Aussagen der Zusammenfassung durch Befehlsausgaben belegt?],
  [☐], [Nennt die Zusammenfassung getroffene Annahmen und nicht umgesetzte Ideen?],
)

== Wissen, wann Schluss ist

Eine funktionierende, geprüfte Lösung weiter zu verfeinern, ist verlockend, weil ein Agent jede Verbesserung in Sekunden liefert. Aber jede Änderung ist ein neues Risiko und neuer Review-Aufwand. Wenn die Akzeptanzkriterien erfüllt, die Prüfungen grün und das Review abgeschlossen sind, ist die Aufgabe fertig. Weitere Runden für kosmetische Verbesserungen haben fast immer ein schlechtes Verhältnis von Nutzen zu Risiko. Wer merkt, dass die Ergebnisse von Runde zu Runde nur noch marginal besser werden, sollte das als Signal nehmen, aufzuhören, und nicht als Anlass für eine weitere Runde.

#merke[Qualität mit Coding-Agenten entsteht aus vier Schichten: klare Anforderungen mit prüfbaren Kriterien, deterministische Prüfungen, die jede Änderung durchläuft, ein zweites Modell als unabhängiger Prüfer und ein Mensch, der entscheidet. Modell und Effort bestimmen, wie schnell man dorthin kommt, nicht ob.]

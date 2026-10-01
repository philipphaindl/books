#import "lib.typ": *

= Goals und lang laufende Aufgaben

Normalerweise arbeitet ein Agent einen Turn lang und wartet dann auf die nächste Nachricht. Für größere Aufgaben bedeutet das ständiges "mach weiter". Goals ändern das: Man legt eine Zielbedingung fest, und der Agent arbeitet selbstständig weiter, bis sie erfüllt ist. Beide Werkzeuge haben dafür einen Befehl `/goal`, aber mit unterschiedlichen Eigenschaften.

== Wie Goals funktionieren

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [`/goal` \ #text(size: 6.3pt)[Zielbedingung]], w: 2.3, h: 1.0, bg: rgb("#FFF8E6"), col: c-yellow, size: 7.3pt)
    kasten((3.8, 0), [Turn \ #text(size: 6.3pt)[lesen, ändern, prüfen]], w: 2.4, h: 1.0, bg: rgb("#FDF1EC"), col: c-accent, size: 7.3pt)
    kasten((7.8, 0), [Bewertung \ #text(size: 6.3pt)[erfüllt? (eigenes Modell)]], w: 2.8, h: 1.0, bg: rgb("#F1ECF8"), col: c-violet, size: 7.3pt)
    kasten((11.9, 0), [fertig \ #text(size: 6.3pt)[Kontrolle zurück]], w: 2.3, h: 1.0, bg: rgb("#EEF6E6"), col: c-gitea, size: 7.3pt)
    pfeil((1.2, 0), (2.55, 0)); pfeil((5.05, 0), (6.35, 0))
    pfeil((9.25, 0), (10.7, 0), label: "ja", loff: (0, 0.22), color: c-gitea)
    line((7.8, -0.55), (7.8, -1.2), (3.8, -1.2), (3.8, -0.55), stroke: (paint: c-red, thickness: 0.8pt), mark: (end: "stealth", fill: c-red, scale: 0.5))
    content((5.8, -1.45), text(size: 6.8pt, fill: c-red)[nein: nächster Turn, Begründung als Hinweis])
  }),
  caption: [Nach jedem Turn entscheidet eine separate Bewertung, ob die Bedingung erfüllt ist.],
)

*Claude Code* (seit Version 2.1.139 @cc-week20): `/goal <Bedingung>` setzt die Bedingung und startet sofort einen Turn. Nach jedem Turn schickt Claude Code die Bedingung und den bisherigen Verlauf an ein kleines, schnelles Modell (standardmäßig Haiku), das entscheidet, ob sie erfüllt ist. Technisch ist das ein sitzungsbezogener Stop-Hook. Pro Sitzung gibt es ein Goal. `/goal` ohne Argument zeigt Status, Turns, verbrauchte Token und die letzte Begründung der Bewertung, `/goal clear` beendet es, `/clear` ebenfalls. Mit `--resume` bleibt ein aktives Goal erhalten. Ein Goal ändert die Berechtigungen nicht: Damit es ohne Rückfragen läuft, braucht es einen passenden Berechtigungsmodus @cc-goal.

*Codex*: `/goal <Ziel>` hängt ein dauerhaftes Ziel an den Thread. Codex kennt die Zustände aktiv, pausiert, abgeschlossen und budgetbegrenzt, mit `/goal pause`, `/goal resume` und `/goal clear`. Ein Token-Budget begrenzt den Verbrauch. Eine Unterbrechung durch den Benutzer pausiert das Ziel. Das Modell selbst kann ein Ziel nur als abgeschlossen melden, Pause, Fortsetzen und Budget kontrolliert der Benutzer bzw. die Laufzeitumgebung. In der Desktop-App zeigt eine Fortschrittszeile über dem Eingabefeld das aktive Ziel @oa-goals @oa-commands.

== Ist ein Goal ein guter Ansatz?

Ja, für eine bestimmte Art von Aufgaben, und nein für viele andere. Entscheidend ist, ob sich das Ende *objektiv aus dem Verlauf feststellen* lässt.

#table(columns: (1fr, 1fr),
  [Gut geeignet], [Schlecht geeignet],
  [Alle Aufrufer einer veralteten Funktion migrieren, bis der Build durchläuft], [Architektur entwerfen oder zwischen Varianten entscheiden],
  [Fehlschlagende Tests eines Moduls reparieren, bis alle grün sind], [Unklare oder widersprüchliche Anforderungen umsetzen],
  [Linter- oder Typfehler in einem Verzeichnis beseitigen], ["Code verbessern", "aufräumen", "performanter machen" ohne Messgröße],
  [Akzeptanzkriterien einer bereits geplanten Anforderung als Tests abdecken und erfüllen], [Sicherheitskritische Änderungen, die vor dem Zusammenführen ohnehin geprüft werden müssen, im Blindflug],
  [Abhängigkeits-Upgrade, bis Tests und Typprüfung sauber sind], [Explorative Aufgaben, bei denen das Ziel erst beim Arbeiten klar wird],
)

Die Faustregel: *Ein Goal ersetzt das ständige "mach weiter", nicht das Denken über die Aufgabe.* Die Arbeit vor dem Goal (Anforderung verstehen, Plan prüfen, Grenzen festlegen) bleibt beim Menschen. Das Goal übernimmt die mechanische, iterative Phase danach.

== Die Grenzen kennen

- *Die Bewertung sieht nur den Verlauf.* Bei Claude Code beurteilt das Bewertungsmodell nur, was im Gespräch sichtbar ist. Behauptet der Agent "alle Tests grün", ohne die Ausgabe zu zeigen, kann die Bewertung darauf hereinfallen @cc-goal. Deshalb gehört in die Bedingung, dass der Nachweis sichtbar sein muss.
- *Goal-Gaming.* Ein Agent, der eine Bedingung "Tests grün" um jeden Preis erreichen soll, kann Tests abschwächen oder überspringen (vgl. die Warnung vor Test-Gaming in @an-prompting). Die Bedingung muss das ausschließen, und Testdateien sollten geschützt sein.
- *Verbrauch.* Jeder Turn kostet. Ohne Obergrenze kann ein Goal viel Nutzungsvolumen verbrauchen, ohne voranzukommen. Codex hat dafür Budgets @oa-goals, bei Claude Code formuliert man die Grenze in der Bedingung @cc-goal.
- *Festfahren.* Auch Anthropic empfiehlt für unbeaufsichtigte Läufe, nach zwei bis drei automatischen Fortsetzungen ohne Fortschritt abzubrechen und den Lauf zu prüfen @an-opus55.

== Gute und schlechte Zielbedingungen

#table(columns: (1fr, 1fr),
  [Schlecht], [Besser],
  [`/goal Tags-Feature fertig`], [`/goal Alle Akzeptanzkriterien von FR-012 haben je einen Test mit Markierung req("FR-012"); uv run pytest endet mit Exit-Code 0 und die Ausgabe ist im Verlauf sichtbar; keine bestehende Testdatei wurde geändert; höchstens 25 Turns`],
  [`/goal Code ist sauber`], [`/goal uv run ruff check app/ und uv run lint-imports laufen ohne Befund, Ausgabe sichtbar; Änderungen nur in app/; kein neues Paket in pyproject.toml`],
  [`/goal Migration abgeschlossen`], [`/goal grep -rn "alte_funktion" app/ findet nichts mehr; uv run pytest ist grün, Ausgabe sichtbar; höchstens 30 Turns`],
)

Jede gute Bedingung hat drei Teile: einen *beobachtbaren Endzustand* (ein Befehl mit eindeutigem Ergebnis), einen *Schutz gegen Abkürzungen* (was nicht geändert werden darf) und eine *Obergrenze*.

#tipp[Wer nicht weiß, wie er eine Bedingung formulieren soll, kann das Modell bitten: "Formuliere eine /goal-Bedingung für diese Aufgabe mit beobachtbarem Endzustand, Schutz gegen Abkürzungen und Obergrenze." Das Ergebnis vor dem Setzen prüfen, denn eine zu weiche Bedingung ist genau die Schwachstelle, die das Goal ausnutzen wird.]

== Verwandte Mechanismen

#table(columns: (auto, 1fr),
  [Mechanismus], [Wann statt `/goal`],
  [`/loop` (Claude Code)], [Wiederholung in Zeitabständen, etwa "prüfe alle 10 Minuten, ob der Deploy fertig ist". Endet, wenn man es stoppt oder die Arbeit getan ist @cc-goal.],
  [Eigener Stop-Hook], [Wenn die Fertig-Prüfung nicht von einem Modell, sondern von einem Skript kommen soll, etwa "Stoppen erst erlaubt, wenn `pytest` Exit-Code 0 liefert". Deterministischer als `/goal` @cc-hooks.],
  [Plan-Modus], [Vor jedem Goal, um Vorgehen und Grenzen festzulegen.],
  [`ultracode` / Ultra], [Wenn die Aufgabe groß ist und sich sinnvoll auf parallele Teilagenten aufteilen lässt @cc-model @oa-models.],
  [Normale Sitzung], [Für alles, bei dem man die Zwischenergebnisse ohnehin ansehen will.],
)

Für Softwareentwicklung mit hohen Qualitätsansprüchen ist die Kombination aus *Plan-Modus, dann Goal mit harter Bedingung, dann Review* besonders wirksam: Der Mensch bestimmt Richtung und Grenzen, der Agent erledigt die Iteration, die Prüfungen entscheiden über "fertig".

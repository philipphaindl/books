#import "lib.typ": *

= Wie Coding-Agenten arbeiten

Ein Coding-Agent ist ein Sprachmodell in einer Schleife: Er liest Dateien, plant, ändert Code, führt Befehle aus, liest deren Ergebnis und entscheidet, was als Nächstes zu tun ist @an-agents @react. Wer diese Schleife versteht, versteht auch, wo Fehler entstehen und wo man eingreifen kann.

== Die Agentenschleife

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [*Kontext* \ #text(size: 6.2pt)[Dateien, Doku, \ Anforderungen lesen]], w: 2.8, h: 1.15, bg: rgb("#FFF8E6"), col: c-yellow, size: 7.3pt)
    kasten((3.7, 0), [*Planen* \ #text(size: 6.2pt)[Vorgehen, Annahmen]], w: 2.6, h: 1.15, bg: rgb("#F1ECF8"), col: c-violet, size: 7.3pt)
    kasten((7.3, 0), [*Handeln* \ #text(size: 6.2pt)[Code ändern, \ Befehle ausführen]], w: 2.6, h: 1.15, bg: rgb("#FDF1EC"), col: c-accent, size: 7.3pt)
    kasten((10.9, 0), [*Prüfen* \ #text(size: 6.2pt)[Tests, Lint, \ Ausgabe lesen]], w: 2.6, h: 1.15, bg: rgb("#EEF6E6"), col: c-gitea, size: 7.3pt)
    pfeil((1.45, 0), (2.35, 0)); pfeil((5.05, 0), (5.95, 0)); pfeil((8.65, 0), (9.55, 0))
    line((10.9, -0.62), (10.9, -1.35), (3.7, -1.35), (3.7, -0.62), stroke: (paint: c-gitea, thickness: 0.9pt), mark: (end: "stealth", fill: c-gitea, scale: 0.55))
    content((7.3, -1.6), text(size: 6.8pt, fill: c-gitea.darken(10%))[Fehler gefunden: erneut planen und handeln])
    kasten((14.6, 0), [Mensch], w: 1.5, h: 0.8, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
    pfeil((12.25, 0), (13.8, 0), label: "fertig?", loff: (0, 0.22), color: c-blue)
  }),
  caption: [Die Schleife eines Coding-Agenten. Qualität entsteht im Schritt "Prüfen", nicht im Schritt "Handeln".],
)

Aus der Schleife folgen drei Einsichten, die sich durch das ganze Buch ziehen:

+ *Das Modell weiß nur, was im Kontext steht oder in seinen Trainingsdaten war.* Alles andere muss es über Werkzeuge beschaffen: Dateien öffnen, Befehle ausführen, Dokumentation lesen. Behauptungen ohne diesen Schritt sind Vermutungen (Kapitel 7).
+ *Die Prüfung ist der Qualitätshebel.* Ein Agent, der seine Änderung gegen Tests, Linter und Architekturregeln laufen lassen kann, korrigiert sich selbst. Ein Agent ohne Prüfmöglichkeit kann nur hoffen.
+ *Der Agent entscheidet selbst, wann er fertig ist*, außer man gibt ihm ein überprüfbares Kriterium vor (Kapitel 9 und 10).

== Warum Agenten zu viel oder das Falsche tun

Sprachmodelle sind darauf trainiert, hilfreich zu sein. Bei Coding-Aufgaben äußert sich das in einem gut dokumentierten Muster: Anthropic beschreibt ausdrücklich, dass Opus-Modelle zum Overengineering neigen, also zusätzliche Dateien anlegen, unnötige Abstraktionen einführen oder nicht angeforderte Flexibilität einbauen @an-prompting. Dazu kommen typische Formen des Abweichens:

#table(columns: (auto, 1fr),
  [Muster], [Beispiel],
  [Scope Creep], [Beim Bugfix wird "gleich noch" die umgebende Funktion umgebaut.],
  [Spekulative Allgemeinheit], [Ein Plugin-System für genau einen Anwendungsfall, eine Konfigurationsoption, die niemand braucht.],
  [Defensives Übermaß], [Fehlerbehandlung für Fälle, die nicht auftreten können, Validierung interner Aufrufe.],
  [Stilfremde Lösungen], [Neue Bibliothek, obwohl das Projekt schon eine für denselben Zweck nutzt.],
  [Test-Gaming], [Tests werden angepasst oder Sonderfälle hart codiert, bis sie grün sind.],
  [Erfundene Anforderungen], [Der Agent füllt Lücken in der Aufgabenstellung mit eigenen Annahmen, ohne sie zu nennen.],
)

Diese Muster sind kein Zeichen eines schlechten Modells. Sie entstehen, wenn Aufgabe, Grenzen und Definition von "fertig" nicht klar sind. Genau dort setzen die Kapitel 8 bis 10 an.

== Die vier Hebel

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [*Ergebnis* \ #text(size: 6.5pt)[richtig, passend, wartbar]], w: 3.2, h: 1.2, bg: white, col: c-dark, size: 7.5pt)
    kasten((-5.3, 1.1), [*Modell* \ #text(size: 6.5pt)[Fähigkeit, Kosten, Tempo]], w: 3.6, h: 1.0, bg: rgb("#F1ECF8"), col: c-violet, size: 7.3pt)
    kasten((-5.3, -1.1), [*Effort* \ #text(size: 6.5pt)[wie gründlich es denkt]], w: 3.6, h: 1.0, bg: rgb("#F1ECF8"), col: c-violet, size: 7.3pt)
    kasten((5.3, 1.1), [*Kontext* \ #text(size: 6.5pt)[Anforderungen, ADRs, Code]], w: 3.6, h: 1.0, bg: rgb("#FFF8E6"), col: c-yellow, size: 7.3pt)
    kasten((5.3, -1.1), [*Leitplanken* \ #text(size: 6.5pt)[Tests, Hooks, Rechte, Review]], w: 3.6, h: 1.0, bg: rgb("#EEF6E6"), col: c-gitea, size: 7.3pt)
    pfeil((-3.45, 0.9), (-1.65, 0.35)); pfeil((-3.45, -0.9), (-1.65, -0.35))
    pfeil((3.45, 0.9), (1.65, 0.35)); pfeil((3.45, -0.9), (1.65, -0.35))
  }),
  caption: [Modell und Effort bestimmen, was möglich ist. Kontext und Leitplanken bestimmen, was tatsächlich herauskommt.],
)

Die Erfahrung aus der Praxis ist eindeutig: Ein mittleres Modell mit gutem Kontext und harten Leitplanken liefert bessere Ergebnisse als das stärkste Modell mit vager Aufgabenstellung und ohne Tests. Die Modellwahl ist wichtig, aber sie ist der Hebel, an dem man am wenigsten gewinnt, wenn die anderen drei fehlen.

== Kontextfenster und Verdichtung

Alles, was der Agent gelesen und getan hat, liegt im Kontextfenster. Die aktuellen Modelle beider Hersteller arbeiten mit sehr großen Fenstern (bei Anthropic bis zu einer Million Token @an-models). Irgendwann läuft das Fenster trotzdem voll, dann _verdichtet_ das Werkzeug den bisherigen Verlauf zu einer Zusammenfassung (Claude Code: automatisch oder mit `/compact` @cc-model, Codex: `/compact` @oa-commands). Dabei gehen Details verloren.

Für die Praxis heißt das: *eine Aufgabe pro Sitzung.* Wer in einer Sitzung erst ein Feature baut, dann einen fremden Bug sucht und danach noch refaktoriert, bekommt einen Kontext voller irrelevanter Details. Mit `/clear` (Claude Code) bzw. einer neuen Unterhaltung beginnt die nächste Aufgabe sauber. Dauerhaft wichtige Informationen gehören nicht in den Chatverlauf, sondern in `CLAUDE.md` bzw. `AGENTS.md` und die Dokumente im Repository.

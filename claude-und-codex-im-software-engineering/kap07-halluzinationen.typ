#import "lib.typ": *

= Halluzinationen vermeiden

Eine Halluzination ist eine Behauptung, die plausibel klingt, aber nicht belegt ist @ji-hallucination. In der Softwareentwicklung sind die gefährlichsten Halluzinationen keine erfundenen Fakten über die Welt, sondern stille Annahmen über den eigenen Code: eine Funktion, die es nicht gibt, ein Parameter, den die installierte Bibliotheksversion nicht kennt, oder die Aussage "alle Tests laufen", ohne dass sie gelaufen sind.

Die aktuellen Modelle halluzinieren deutlich seltener als frühere. Anthropic beschreibt Opus 5.5 als viel seltener falsch bei Zahlen und Quellen @an-opus55, OpenAI hebt bei GPT-6 Sol die höhere Faktenzuverlässigkeit hervor. Das Risiko sinkt, verschwindet aber nicht. Die Gegenmaßnahmen sind deshalb vor allem strukturell.

== Die typischen Formen in der Softwareentwicklung

#table(columns: (auto, 1fr, 1fr),
  [Form], [Beispiel], [Gegenmaßnahme],
  [Erfundene API], [`client.fetch_all(retry=3)` existiert nicht], [Code gegen die installierte Version prüfen lassen, Typprüfung und Tests],
  [Falsche Version], [Syntax einer älteren oder neueren Bibliotheksversion], [Lockfile als Quelle nennen, aktuelle Doku bereitstellen],
  [Aussagen über ungeöffneten Code], ["Die Funktion validiert bereits die Eingabe"], [Dateien vor jeder Aussage öffnen lassen],
  [Erfundenes Ergebnis], ["Tests laufen durch", ohne Ausführung], [nur Befehlsausgaben als Beleg akzeptieren, CI als letzte Instanz],
  [Erfundene Anforderung], [Annahmen über gewünschtes Verhalten werden stillschweigend umgesetzt], [Annahmen offenlegen lassen, bei Unklarheit fragen],
  [Test-Gaming], [Sonderfall hart codiert, damit ein Test grün wird], [ausdrückliches Verbot, Review des Diffs, Tests schützen],
  [Veraltetes Wissen], [Werkzeuge und Modelle nach dem Trainingsstand], [Websuche oder Doku-Zugang, Stand datieren],
)

== Vier strukturelle Gegenmaßnahmen

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [Behauptung \ #text(size: 6.3pt)["X funktioniert"]], w: 2.4, h: 1.0, bg: rgb("#FBEAEA"), col: c-red, size: 7.3pt)
    let b = (([*Quelle* \ #text(size: 6.3pt)[Datei geöffnet]], 3.6), ([*Ausführung* \ #text(size: 6.3pt)[Befehl + Ausgabe]], 6.9), ([*Test* \ #text(size: 6.3pt)[aus Akzeptanzkriterium]], 10.2), ([*CI* \ #text(size: 6.3pt)[unabhängig, wiederholbar]], 13.5))
    for (t, x) in b { kasten((x, 0), t, w: 2.6, h: 1.0, bg: rgb("#EEF6E6"), col: c-gitea, size: 7.3pt) }
    pfeil((1.25, 0), (2.25, 0)); pfeil((4.95, 0), (5.55, 0)); pfeil((8.25, 0), (8.85, 0)); pfeil((11.55, 0), (12.15, 0))
    content((8.5, -0.95), text(size: 6.8pt, fill: c-gitea.darken(15%), style: "italic")[je weiter rechts, desto stärker der Beleg])
  }),
  caption: [Eine Behauptung des Agenten ist erst so viel wert wie der stärkste Beleg dahinter.],
)

=== 1. Erst lesen, dann sprechen

Anthropic empfiehlt für agentisches Coding ausdrücklich eine Anweisung, die Spekulation über ungeöffneten Code verbietet: Dateien, auf die sich eine Frage bezieht, müssen vor der Antwort gelesen werden, und Aussagen über die Codebasis sind nur nach Untersuchung erlaubt @an-prompting. Sinngemäß gehört das in jede `CLAUDE.md` und `AGENTS.md`:

#datei("Auszug aus CLAUDE.md / AGENTS.md")[
```markdown
## Belege statt Vermutungen
- Triff keine Aussage über Code, den du nicht geöffnet hast. Lies betroffene
  Dateien, bevor du antwortest oder änderst.
- Bibliotheks-APIs gegen die installierte Version prüfen (uv.lock), nicht aus
  dem Gedächtnis. Bei Unsicherheit die Signatur nachsehen oder nachfragen.
- "Läuft", "grün", "behoben" nur mit der Ausgabe des ausgeführten Befehls.
- Wenn du etwas nicht weißt oder nicht prüfen kannst, sag es.
```
]

=== 2. Werkzeuge statt Gedächtnis

Aktuelle Modelle sind darauf trainiert, Werkzeuge zu nutzen, statt zu raten. Rückmeldungen aus der Umgebung, etwa Testergebnisse oder Befehlsausgaben, sind dabei der Anker, an dem der Agent seinen Fortschritt prüft @an-agents @react. Das funktioniert nur, wenn die Werkzeuge verfügbar und erlaubt sind: Tests, Typprüfung und Linter müssen ohne Rückfrage ausführbar sein (siehe die Berechtigungen in Kapitel 4). Für aktuelle Dokumentation von Bibliotheken helfen Websuche oder ein Dokumentations-Server über MCP. OpenAI empfiehlt für OpenAI-bezogene Fragen etwa, Codex per `AGENTS.md` auf den Dokumentations-Server der eigenen Entwicklerdoku zu verweisen @oa-docsmcp.

=== 3. Tests als Orakel, nicht als Hürde

Ein Test, der aus einem Akzeptanzkriterium abgeleitet wurde, ist die zuverlässigste Prüfung, ob eine Behauptung stimmt. Er ist aber nur dann ein Orakel, wenn er nicht nachträglich an den Code angepasst wird. Anthropic führt Test-Gaming ausdrücklich als Verhalten auf, gegen das man anweisen sollte: Lösungen sollen für alle gültigen Eingaben funktionieren, nicht nur für die Testfälle, und fehlerhafte Tests sollen gemeldet statt umgangen werden @an-prompting.

#datei("Auszug aus CLAUDE.md / AGENTS.md")[
```markdown
## Tests
- Schreibe eine allgemeine Lösung, die für alle gültigen Eingaben stimmt,
  nicht nur für die Testfälle. Keine hart codierten Sonderfälle für Tests.
- Ändere bestehende Tests nur, wenn die Aufgabe das ausdrücklich verlangt.
  Hältst du einen Test für falsch, melde es mit Begründung, statt ihn anzupassen.
```
]

=== 4. Die CI hat das letzte Wort

Selbstauskünfte eines Agenten sind keine Nachweise. Maßgeblich ist, was die Pipeline aus dem Git-Handbuch (Kapitel 13 bis 15 @buch-git) unabhängig und wiederholbar feststellt. Ein Agent, der "fertig" meldet, während die CI rot ist, hat nicht gelogen, er hat sich geirrt. Genau deshalb braucht es eine Instanz, die er nicht beeinflusst.

#tipp[Zwei kurze Fragen nach jeder größeren Änderung decken viele Halluzinationen auf: "Welche deiner Aussagen hast du mit welchem Befehl geprüft?" und "Welche Annahmen hast du getroffen, die nicht in der Aufgabe standen?" Ein gutes Modell beantwortet beide ehrlich, und die Antworten zeigen, wo nachgeprüft werden muss.]

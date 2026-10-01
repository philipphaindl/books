#import "lib.typ": *

= Aufgabentreue: das Gefragte, nicht mehr

Das Ziel ist genau die angeforderte Änderung, vollständig und sauber umgesetzt, ohne zusätzliche Abstraktionen, Optionen oder "Verbesserungen". Das ist schwerer, als es klingt, weil Modelle dazu neigen, hilfsbereit mehr zu tun. Die Lösung liegt in drei Dingen: einer klaren Aufgabe, festen Grenzen und einer Prüfung, die Abweichungen sichtbar macht.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let stufen = (
      ([Aufgabe: FR-012 umsetzen], 9.0, c-yellow),
      ([Grenzen: welche Dateien, was nicht], 7.4, c-yellow),
      ([Akzeptanzkriterien als Tests], 5.8, c-gitea),
      ([kleinste Änderung, die alle erfüllt], 4.6, c-accent),
    )
    for (i, s) in stufen.enumerate() {
      let y = -i * 0.72
      let w = s.at(1)
      rect((-w / 2, y - 0.3), (w / 2, y + 0.3), radius: 0.08, fill: s.at(2).lighten(86%), stroke: (paint: s.at(2), thickness: 0.8pt))
      content((0, y), text(size: 7.3pt, s.at(0)))
    }
    content((4.9, -1.1), anchor: "west", text(size: 6.8pt, fill: c-grey.darken(20%), style: "italic")[jede Ebene \ verengt den Raum \ für Eigenmächtigkeit])
  }),
  caption: [Vom Auftrag zur kleinsten ausreichenden Änderung.],
)

== Die Anweisung gegen Overengineering

Anthropic veröffentlicht in den Prompting-Richtlinien einen Textbaustein, der Overengineering ausdrücklich adressiert @an-prompting. Übersetzt und für ein Python-Projekt angepasst, gehört er in `CLAUDE.md` und `AGENTS.md`:

#datei("Auszug aus CLAUDE.md / AGENTS.md")[
```markdown
## Umfang
Vermeide Overengineering. Ändere nur, was direkt verlangt oder zwingend nötig ist.
- Umfang: Keine zusätzlichen Features, kein Refactoring und keine "Verbesserungen"
  über den Auftrag hinaus. Ein Bugfix braucht keine Aufräumarbeiten daneben.
- Doku: Keine Docstrings, Kommentare oder Typannotationen in Code, den du nicht
  geändert hast. Kommentare nur, wo die Logik nicht selbsterklärend ist.
- Fehlerbehandlung: Validiere an Systemgrenzen (Benutzereingaben, externe APIs),
  nicht bei internen Aufrufen. Keine Fallbacks für Fälle, die nicht eintreten können.
- Abstraktionen: Keine neuen Klassen, Schichten oder Konfigurationsoptionen für
  einen einzigen Anwendungsfall. Drei ähnliche Zeilen sind besser als eine
  voreilige Abstraktion.
- Abhängigkeiten: Keine neuen Pakete ohne ausdrückliche Zustimmung. Nutze, was
  im Projekt bereits vorhanden ist.
Wenn du eine Verbesserung außerhalb des Auftrags für wichtig hältst, nenne sie
am Ende in einem Satz, statt sie umzusetzen.
```
]

Der letzte Satz ist wichtig. Er nimmt dem Modell den Druck, eine gute Idee sofort umzusetzen, und macht sie trotzdem sichtbar. So bleibt die Entscheidung beim Menschen.

== Eine Aufgabenstellung, die Grenzen setzt

#grid(columns: (1fr, 1fr), column-gutter: 10pt,
[
#text(size: 8pt, weight: "bold", fill: c-red)[Unscharf]
```text
Füge Tags zu den Notizen hinzu.
```
Offen bleibt: Datenmodell, API-Form, Suche nach Tags, Umbenennen, Grenzen, Migration. Das Modell füllt alle Lücken selbst, meist großzügig.
],
[
#text(size: 8pt, weight: "bold", fill: c-gitea.darken(10%))[Scharf]
```text
Setze FR-012 (docs/anforderungen/FR-012.md) um.
Beachte ADR-0003 und ADR-0007.
Nur app/notizen/, app/db/ und tests/.
Keine neuen Abhängigkeiten.
Fertig: alle Akzeptanzkriterien als Tests
grün, ruff und lint-imports sauber.
Nicht Teil der Aufgabe: Suche nach Tags.
```
],
)

Die scharfe Fassung ist nicht länger, weil sie mehr erklärt, sondern weil sie auf vorhandene Dokumente verweist und festlegt, *was nicht* dazugehört. Der Abschnitt "Nicht Teil der Aufgabe" ist einer der wirksamsten Sätze gegen Scope Creep.

== Planen vor dem Handeln

Beide Werkzeuge haben einen Plan-Modus, in dem der Agent liest und plant, aber nichts ändert (Claude Code: #key[⇧] #key[Tab] bis "plan mode" bzw. Berechtigungsmodus `plan` @cc-permissions; Codex: `/plan` @oa-commands). Für alles, was über eine lokale Änderung hinausgeht, lohnt sich der Ablauf:

+ Plan anfordern, der die betroffenen Anforderungen und ADRs mit ID nennt, die zu ändernden Dateien aufzählt und die getroffenen Annahmen offenlegt.
+ Plan prüfen. Hier ist Overengineering am billigsten zu korrigieren: Eine überflüssige Abstraktion im Plan kostet einen Satz, im Code eine Stunde.
+ Umsetzung freigeben.

Der Plan ist ein Gesprächsergebnis, kein neues Dokument. Er muss nirgends abgelegt werden.

== Fragen oder annehmen?

Ein Agent, der bei jeder Kleinigkeit fragt, ist lästig. Einer, der nie fragt, trifft stille Annahmen. Eine brauchbare Regel für `CLAUDE.md` und `AGENTS.md`:

```markdown
## Unklarheiten
Wenn eine Unklarheit das Ergebnis wesentlich ändert (Datenmodell, API,
Sicherheit, Verhalten für Benutzer), frage vor der Umsetzung.
Kleine Unklarheiten löst du mit der naheliegendsten Annahme und nennst sie
am Ende in der Zusammenfassung.
```

== Abweichungen sichtbar machen

Aufgabentreue lässt sich prüfen, nicht nur anweisen:

- *Diff-Größe beobachten.* Ein Bugfix mit 400 geänderten Zeilen in zwölf Dateien ist verdächtig. `git diff --stat` nach jeder Aufgabe zeigt das sofort.
- *Geänderte Pfade gegen die Grenzen prüfen.* Änderungen außerhalb der vereinbarten Verzeichnisse fallen im Review oder per Skript auf.
- *Neue Abhängigkeiten prüfen.* Eine Änderung an `pyproject.toml` oder `uv.lock` ohne Auftrag ist ein Befund.
- *Der Prüfer aus Kapitel 6 fragt ausdrücklich nach Änderungen außerhalb des Auftrags.*

#merke[Aufgabentreue ist keine Frage des Modells, sondern des Vertrags. Ein klarer Auftrag mit Verweis auf Anforderung und ADRs, ausdrücklichen Grenzen, einer prüfbaren Definition von "fertig" und einem Abschnitt "Nicht Teil der Aufgabe" erzielt mit jedem aktuellen Modell deutlich bessere Ergebnisse als das beste Modell mit einem vagen Satz.]

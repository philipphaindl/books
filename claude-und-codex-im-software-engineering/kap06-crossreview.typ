#import "lib.typ": *

= Claude und Codex als gegenseitige Prüfer

Ein Modell, das seinen eigenen Code prüft, übersieht gerne dieselben Dinge, die es beim Schreiben übersehen hat. Ein zweites Modell eines anderen Herstellers bringt eine unabhängige Perspektive, ähnlich wie ein Review durch eine Kollegin. Mit beiden Abos lässt sich das ohne Mehrkosten in den Ablauf einbauen.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [Aufgabe \ #text(size: 6.3pt)[FR, NFR, ADRs]], w: 2.3, h: 1.0, bg: rgb("#FFF8E6"), col: c-yellow, size: 7.3pt)
    kasten((3.8, 0), [Claude \ #text(size: 6.3pt)[implementiert]], w: 2.3, h: 1.0, bg: rgb("#FDF1EC"), col: c-accent, size: 7.3pt)
    kasten((7.6, 0), [Prüfungen \ #text(size: 6.3pt)[Tests, Lint, Regeln]], w: 2.4, h: 1.0, bg: rgb("#EEF6E6"), col: c-gitea, size: 7.3pt)
    kasten((11.4, 0), [Codex \ #text(size: 6.3pt)[prüft, nur lesend]], w: 2.3, h: 1.0, bg: rgb("#E7F4F2"), col: c-teal, size: 7.3pt)
    kasten((15.0, 0), [Mensch \ #text(size: 6.3pt)[entscheidet]], w: 2.0, h: 1.0, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
    pfeil((1.2, 0), (2.6, 0)); pfeil((5.0, 0), (6.35, 0)); pfeil((8.85, 0), (10.2, 0)); pfeil((12.6, 0), (13.95, 0))
    line((11.4, -0.55), (11.4, -1.2), (3.8, -1.2), (3.8, -0.55), stroke: (paint: c-teal, thickness: 0.8pt, dash: "dashed"), mark: (end: "stealth", fill: c-teal, scale: 0.5))
    content((7.6, -1.45), text(size: 6.8pt, fill: c-teal.darken(10%))[belegte Befunde zurück, einmal, nicht im Ping-Pong])
    line((0, 0.55), (0, 1.2), (11.4, 1.2), (11.4, 0.55), stroke: (paint: c-yellow.darken(10%), thickness: 0.8pt, dash: "dashed"), mark: (end: "stealth", fill: c-yellow.darken(10%), scale: 0.5))
    content((5.7, 1.42), text(size: 6.8pt, fill: c-yellow.darken(25%))[Prüfer bekommt Anforderungen und Diff, nicht die Begründung des Umsetzers])
  }),
  caption: [Zwei Modelle, klare Rollen: Einer schreibt, einer prüft, der Mensch entscheidet.],
)

== Die Regeln

+ *Der Prüfer arbeitet nur lesend.* In Codex mit Sandbox `read-only` @oa-approvals, in Claude Code als Teilagent ohne Schreibwerkzeuge @cc-subagents. Ein Prüfer, der "gleich selbst korrigiert", ist ein zweiter Umsetzer, und dann weiß niemand mehr, wessen Änderung was bewirkt hat.
+ *Der Prüfer bekommt die Vorgaben, nicht die Begründung.* Anforderungen, Akzeptanzkriterien, relevante ADRs und den Diff. Die Erklärung des Umsetzers, warum alles richtig ist, verzerrt das Urteil.
+ *Befunde brauchen Belege:* Datei, Zeile, betroffene Anforderung oder ADR, konkreter Fall, in dem es schiefgeht. Befunde ohne Beleg werden verworfen.
+ *Ein Durchgang, kein Ping-Pong.* Der Umsetzer arbeitet die belegten Befunde einmal ab, danach entscheidet ein Mensch. Wechselseitiges Korrigieren über viele Runden produziert Überarbeitung um ihrer selbst willen.
+ *Prüfen, was geprüft werden soll:* Aufgabentreue (wurde mehr als verlangt geändert?), Abdeckung der Akzeptanzkriterien, ADR-Konformität, Fehler. Stil und Geschmack regeln Formatierer und Linter, nicht Modelle.

== Codex prüft eine Änderung von Claude

```bash
codex exec -m gpt-6.1-sol -c model_reasoning_effort='"high"' -s read-only \
  "Prüfe den Diff gegenüber main (git diff main...HEAD) gegen docs/anforderungen/FR-012.md
   und docs/adr/0003-schichtenarchitektur.md. Melde nur belegte Befunde mit Datei, Zeile
   und betroffener Anforderung oder ADR: (1) Akzeptanzkriterien ohne Test, (2) Änderungen,
   die über FR-012 hinausgehen, (3) Verstöße gegen den ADR, (4) Fehler. Keine Stilfragen,
   keine Verbesserungsvorschläge ohne konkreten Fehler. Ändere keine Dateien."
```

In der interaktiven Codex-Sitzung und der Desktop-App erledigt `/review` eine Prüfung des aktuellen Arbeitsstands @oa-commands. Für die Prüfung gegen Anforderungen und ADRs ist die ausdrückliche Aufgabenstellung oben trotzdem besser, weil sie festlegt, *wogegen* geprüft wird.

== Claude prüft eine Änderung von Codex

#datei(".claude/agents/pruefer.md")[
```markdown
---
name: pruefer
description: Prüft Diffs gegen Anforderungen und ADRs. Ändert keine Dateien.
tools: Read, Grep, Glob, Bash
model: opus
effort: high
---
Prüfe die angegebene Änderung ausschließlich gegen die genannten Anforderungen
(docs/anforderungen/) und ADRs (docs/adr/). Melde nur Befunde mit Beleg:
Datei, Zeile, betroffene ID, konkreter Fehlerfall. Kategorien: fehlende Tests
für Akzeptanzkriterien, Änderungen außerhalb des Auftrags, ADR-Verstöße, Fehler.
Keine Stilfragen, keine Vorschläge ohne konkreten Fehler, keine Änderungen.
```
]

#achtung[Zwei Modelle können sich auch gemeinsam irren, etwa wenn beide dieselbe veraltete Bibliotheksversion annehmen. Das zweite Modell ersetzt deshalb weder die automatischen Prüfungen noch das menschliche Review. Es fängt eine zusätzliche Fehlerklasse ab: die blinden Flecken des Umsetzers.]

== Parallel arbeiten mit Worktrees

Zwei Agenten im selben Arbeitsverzeichnis überschreiben sich gegenseitig Dateien und Testergebnisse. Die Lösung sind Git-Worktrees: zusätzliche Arbeitsverzeichnisse desselben Repositories mit je eigenem Branch (Git-Handbuch, Kapitel 10 @buch-git; Referenz @git-worktree). Beide Werkzeuge unterstützen sie direkt:

- *Claude Code:* `claude --worktree fr-012` (kurz `-w`) legt ein Arbeitsverzeichnis unter `.claude/worktrees/fr-012/` mit eigenem Branch an und startet die Sitzung darin. Dateien, die Git ignoriert, aber zum Arbeiten nötig sind (etwa `.env` für die Entwicklung), trägt man in `.worktreeinclude` ein @cc-worktrees. Die Desktop-App bietet dasselbe über die Oberfläche.
- *Codex:* Die Desktop-App hat einen Worktree-Modus, der für einen Thread ein eigenes Arbeitsverzeichnis anlegt. In der CLI ist seit Version 0.154.0 ein experimenteller Schalter `--worktree` für abgezweigte Sitzungen verfügbar @oa-release-0154.
- *Manuell* funktioniert es mit beiden Werkzeugen: `git worktree add ../notizen-fr-014 -b feature/fr-014`, dann den Agenten im neuen Verzeichnis starten.

Typische Aufteilungen: Claude setzt FR-012 um, Codex parallel FR-014, jeweils in einem eigenen Worktree. Oder Codex prüft den fertigen Branch von Claude in einem eigenen Worktree, während Claude bereits am nächsten Auftrag arbeitet. Wichtig bleibt die Git-Regel: Ein Branch kann nur in einem Worktree gleichzeitig ausgecheckt sein @git-worktree.

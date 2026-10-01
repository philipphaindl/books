#import "lib.typ": *

= Einrichtung auf allen Oberflächen

Claude und Codex gibt es jeweils als Kommandozeilenwerkzeug, als Desktop-App und als Erweiterung für VS Code. Die gute Nachricht: Pro Hersteller teilen sich alle Oberflächen dieselbe Konfiguration. Wer sie einmal sauber einrichtet, hat überall dieselben Standards.

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 10pt,
    align(center, cetz.canvas(length: 1cm, {
      import cetz.draw: *
      kasten((0, 1.3), [Claude Code CLI], w: 2.6, h: 0.6, bg: rgb("#FDF1EC"), col: c-accent, size: 7pt)
      kasten((0, 0.4), [Desktop-App (Code)], w: 2.6, h: 0.6, bg: rgb("#FDF1EC"), col: c-accent, size: 7pt)
      kasten((0, -0.5), [VS-Code-Erweiterung], w: 2.6, h: 0.6, bg: rgb("#FDF1EC"), col: c-accent, size: 7pt)
      kasten((4.3, 0.4), [`~/.claude/` \ `settings.json` \ #text(size: 6pt)[+ Projekt: `.claude/`]], w: 2.6, h: 1.5, bg: white, col: c-accent, size: 7pt)
      for y in (1.3, 0.4, -0.5) { pfeil((1.35, y), (2.95, 0.4 + (y - 0.4) * 0.3)) }
    })),
    align(center, cetz.canvas(length: 1cm, {
      import cetz.draw: *
      kasten((0, 1.3), [Codex CLI], w: 2.6, h: 0.6, bg: rgb("#E7F4F2"), col: c-teal, size: 7pt)
      kasten((0, 0.4), [ChatGPT-Desktop-App], w: 2.6, h: 0.6, bg: rgb("#E7F4F2"), col: c-teal, size: 7pt)
      kasten((0, -0.5), [IDE-Erweiterung], w: 2.6, h: 0.6, bg: rgb("#E7F4F2"), col: c-teal, size: 7pt)
      kasten((4.3, 0.4), [`~/.codex/` \ `config.toml` \ #text(size: 6pt)[+ Projekt: `.codex/`]], w: 2.6, h: 1.5, bg: white, col: c-teal, size: 7pt)
      for y in (1.3, 0.4, -0.5) { pfeil((1.35, y), (2.95, 0.4 + (y - 0.4) * 0.3)) }
    })),
  ),
  caption: [Alle Oberflächen eines Herstellers lesen dieselbe Konfiguration. Projektdateien im Repository überschreiben persönliche Einstellungen.],
)

== Claude: CLI, Desktop-App und VS Code

Die Desktop-App führt im Bereich _Code_ die Claude-Code-CLI selbst aus, die VS-Code-Erweiterung ebenso. Modell- und Effort-Einstellungen gelten deshalb überall gleich.

#table(columns: (auto, 1fr),
  [Befehl oder Einstellung], [Wirkung @cc-model],
  [`/model`], [Modellwähler öffnen. #key[Enter] wechselt und speichert als Standard, #key[s] wechselt nur für diese Sitzung. Mit den Pfeiltasten lässt sich im Wähler auch der Effort verschieben.],
  [`/model opus`, `/model fable`], [direkt wechseln (Aliase `fable`, `opus`, `sonnet`, `haiku`, `opusplan`)],
  [`/effort`, `/effort high`, `/effort auto`], [Effort-Regler öffnen, Stufe setzen, auf den Modellstandard zurücksetzen. Gespeichert wird *pro Modell*.],
  [`claude --model sonnet --effort low`], [Modell und Effort nur für diese Sitzung],
  [`ultrathink` im Prompt], [gründlicheres Nachdenken nur für diese Anfrage],
  [`/status`, Statuszeile], [aktives Modell und Effort anzeigen; der Effort steht auch im Sitzungskopf ("with low effort")],
)

Für Projekte, in denen alle Beteiligten mit denselben Vorgaben arbeiten sollen, gehört eine Projektdatei ins Repository:

#datei(".claude/settings.json")[
```json
{
  "model": "opus",
  "effortLevel": "medium",
  "permissions": {
    "allow": ["Bash(uv run pytest:*)", "Bash(uv run ruff:*)", "Bash(uv run lint-imports)"],
    "deny": ["Read(./.env)", "Read(./secrets/**)"]
  }
}
```
]

`effortLevel` in einer Projektdatei gilt für jedes Modell, `max` wird dort nicht angenommen @cc-model. Persönliche Abweichungen (etwa `/effort high` für die eigene Sitzung) bleiben jederzeit möglich. Eine Kette von Ausweichmodellen für Überlastungsfälle lässt sich mit `"fallbackModel": ["claude-sonnet-5", "claude-haiku-4-5"]` festlegen @cc-model.

=== `opusplan`: planen mit Opus, ausführen mit Sonnet

Der Alias `opusplan` nutzt im Plan-Modus Opus für Architektur- und Lösungsentscheidungen und wechselt für die Umsetzung automatisch auf Sonnet @cc-model. Das spart Nutzungsvolumen bei Aufgaben, deren Plan anspruchsvoll, deren Ausführung aber Routine ist. Bei Aufgaben mit kniffliger Umsetzung (nebenläufiger Code, komplexe Datenmigration) ist Opus durchgehend die bessere Wahl.

=== Teilagenten auf kleineren Modellen

Claude Code delegiert Teilaufgaben an _Subagents_ @cc-subagents. Standardmäßig erben sie das Modell der Sitzung. Für Recherche, Suchen im Code oder das Ausführen von Tests genügt oft ein kleineres Modell. Das legt man in der Definition des Teilagenten fest, einschließlich des Effort:

#datei(".claude/agents/testlaeufer.md")[
```markdown
---
name: testlaeufer
description: Führt Tests aus und fasst Fehlschläge knapp zusammen. Ändert keine Dateien.
tools: Bash, Read, Grep
model: haiku
---
Führe die angegebenen Tests aus. Berichte je Fehlschlag: Test, Fehlermeldung,
betroffene Datei und Zeile. Keine Vermutungen über Ursachen, keine Änderungen.
```
]

Global lässt sich ein Standard für alle Teilagenten über `CLAUDE_CODE_SUBAGENT_MODEL` setzen @cc-subagents. Achtung: Wer mit `/model` auf Opus wechselt, bevor Claude delegiert, schickt auch erbende Teilagenten auf Opus.

== Codex: CLI, ChatGPT-Desktop-App und IDE-Erweiterung

Die ChatGPT-Desktop-App, die Codex CLI und die IDE-Erweiterung verwenden dieselbe Datei `config.toml` @oa-config. In der App wählt man Modell und Effort über den _Power_-Regler unter dem Eingabefeld oder unter _Advanced_, in der CLI mit `/model`. Max und Ultra erscheinen in der CLI unter _More reasoning…_; in der App muss Ultra gegebenenfalls unter _Settings -> Configuration_ eingeschaltet werden.

#datei("~/.codex/config.toml")[
```toml
model = "gpt-6.1-sol"
model_reasoning_effort = "medium"      # low | medium | high | xhigh | max
plan_mode_reasoning_effort = "high"    # im Plan-Modus gründlicher
```
]

```bash
codex                                              # interaktiv mit den Standardwerten
codex -m gpt-6-astra                               # anderes Modell für diese Sitzung
codex -c model_reasoning_effort='"high"'           # anderer Effort für diese Sitzung
codex exec -m gpt-6-luna "Formatiere die Changelog-Einträge einheitlich"   # nicht interaktiv
```

Die Optionen der CLI (`-m`, `-c`, `exec`) beschreibt die Befehlsreferenz @oa-commands. `plan_mode_reasoning_effort` @oa-configref ist das Gegenstück zu `opusplan`: gründliches Planen, sparsameres Ausführen, allerdings auf demselben Modell. Wie bei Claude gehören gemeinsame Vorgaben in das Projekt (`.codex/config.toml`), persönliche in `~/.codex/`.

#achtung[Modellkennungen in `config.toml`, eigenen Agentendefinitionen und Skripten veralten. Nach dem 14. Oktober 2026 schlägt jede Konfiguration fehl, die noch `gpt-5.5` nennt @oa-models. Wer statt fester Versionen mit den Standardwerten des Clients arbeitet, ist davon nicht betroffen, verliert aber die Kontrolle darüber, wann ein neues Modell eingesetzt wird. Für Projekte mit reproduzierbarem Verhalten: Versionen festlegen und bewusst aktualisieren.]

== Kosten und Nutzungsvolumen im Abo

Mit einem Claude-Abo (Pro, Max) und einem ChatGPT-Abo wird nicht pro Token abgerechnet, sondern gegen ein Nutzungsvolumen pro Zeitfenster. Das verschiebt die Frage von "was kostet es" zu "wie lange reicht es":

- *Effort ist der größte Verbrauchstreiber.* Eine Sitzung auf `xhigh` verbraucht ein Vielfaches von `medium`. Hohe Stufen deshalb gezielt für einzelne Aufgaben einsetzen, nicht als Dauereinstellung.
- *Große Modelle verbrauchen mehr pro Token.* Fable und Astra für Aufgaben, die sie brauchen, Teilagenten auf Haiku oder Luna für Suchen, Zusammenfassen und Testläufe.
- *Kontext kostet bei jeder Anfrage.* Ein aufgeblähter Verlauf wird bei jedem Schritt erneut verarbeitet. Eine Aufgabe pro Sitzung spart mehr als jede Modellwahl.

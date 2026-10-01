#import "lib.typ": *

= Welches Modell und welcher Effort wofür

Die Modellwahl folgt einer einfachen Logik: *So viel wie nötig, so wenig wie möglich.* Mehr Rechenleistung macht eine unklare Aufgabe nicht klarer und eine fehlende Prüfung nicht überflüssig. Sie hilft dort, wo das Problem selbst schwierig ist.

== Die Eskalationsleiter

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let st = (
      ([*1* Standard \ #text(size: 6.3pt)[Opus 5.5 `medium` / 6.1 Sol]], c-violet),
      ([*2* Aufgabe schärfen \ #text(size: 6.3pt)[Kontext, Kriterien, Tests]], c-yellow),
      ([*3* Effort erhöhen \ #text(size: 6.3pt)[`high`, dann `xhigh`]], c-violet),
      ([*4* Modell wechseln \ #text(size: 6.3pt)[Fable / Astra]], c-violet),
      ([*5* Aufgabe zerlegen \ #text(size: 6.3pt)[kleinere Schritte]], c-yellow),
    )
    for (i, s) in st.enumerate() {
      let x = i * 3.3
      let y = i * 0.35
      kasten((x, y), s.at(0), w: 2.9, h: 1.05, bg: s.at(1).lighten(88%), col: s.at(1), size: 7pt)
      if i < 4 { pfeil((x + 1.5, y + 0.1), (x + 1.8, y + 0.28)) }
    }
    content((6.6, -1.0), text(size: 6.8pt, fill: c-grey.darken(20%), style: "italic")[nur eine Stufe höher, wenn die vorige nachweislich nicht reicht])
  }),
  caption: [Bevor mehr Rechenleistung hilft, hilft fast immer eine bessere Aufgabenstellung.],
)

Die Reihenfolge ist Absicht. Schritt 2 steht vor Schritt 3, weil die häufigste Ursache schlechter Ergebnisse eine unklare Aufgabe ist, nicht ein zu schwaches Modell. Schritt 5 steht am Ende, weil auch das stärkste Modell an einer Aufgabe scheitert, die zu groß oder zu vage ist.

== Entscheidungstabelle nach Aufgabentyp

#table(columns: (auto, 1fr, 1fr),
  [Aufgabe], [Claude Code], [Codex],
  [Frage zum Code, Erklärung], [Standard, `low` bis `medium`], [Sol, Light],
  [Umbenennen, kleine lokale Änderung], [Sonnet oder Opus, `low`], [Sol oder Luna, Light],
  [Feature mit klaren Akzeptanzkriterien], [Opus 5.5, `medium`], [6.1 Sol, Standard],
  [Bugfix in bestehendem Code], [Opus 5.5, `high`], [6.1 Sol, High],
  [Tests zu vorhandenen Kriterien schreiben], [Opus oder Sonnet, `medium`], [Sol, Medium],
  [Architekturentwurf, ADR-Entwurf], [Opus 5.5 `xhigh` oder Fable], [Astra, Medium bis High],
  [Unklare Fehlerursache, Ausfallanalyse], [Fable, `high`], [Astra, High],
  [Große Migration, viele Dateien], [Fable oder Opus + Goal (Kap. 9)], [6.1 Sol + Goal],
  [Code-Review eines Diffs], [Opus 5.5, `high`], [6.1 Sol, High],
  [Sicherheitsreview], [Opus 5.5 oder Fable, `high` bis `max`], [Astra, High bis Max],
  [Mechanische Massenänderung], [Teilagent auf Haiku / Sonnet], [Luna, High],
  [Doku, Changelog, Commit-Texte], [Sonnet, `low`], [Luna],
)

Die Tabelle ist ein Startpunkt, kein Gesetz. Zwei Beobachtungen aus der Dokumentation beider Hersteller rechtfertigen die Standardwahl für den Großteil der Arbeit: Opus 5.5 auf `medium` erreicht laut Anthropic bei Coding-Aufgaben mindestens das Niveau von Opus 5 auf `high`, auf mehreren Coding-Evaluationen kommt sogar `low` nahe heran @an-opus55 @cc-model. OpenAI empfiehlt GPT-6.1 Sol für komplexes Coding und bezeichnet Astra als Wahl für die anspruchsvollsten Aufgaben @oa-models.

== Wann Fable oder Astra ihr Geld wert sind

Anthropic beschreibt die Stärken von Fable sehr konkret @an-fable: Es untersucht vor dem Handeln, prüft seine Arbeit selbst und hält lange Sitzungen durch. Die Empfehlungen für den Einsatz lauten:

- *Das Ergebnis beschreiben, nicht die Schritte.* Fable plant den Weg selbst.
- *Unklare Probleme übergeben:* Ursachenanalyse, Fehlersuche bei Ausfällen, Architekturentscheidungen.
- *Auf Prüf-Erinnerungen verzichten.* Fable prüft ohnehin, Hinweise wie "teste das" sind meist überflüssig.
- *Größere Pakete übergeben*, die man sonst zerlegen würde.

Für Astra formuliert OpenAI ähnlich: Es ist die Wahl für vollständige Abläufe, die anhaltendes Nachdenken und Urteilsvermögen brauchen, und man soll ihm die Quellen, Vorlagen, Einschränkungen und Prüfungen mitgeben, die ein brauchbares Ergebnis definieren @oa-models.

Umgekehrt lohnt sich die Spitzenklasse nicht für Aufgaben, deren Schwierigkeit in der Menge liegt statt in der Tiefe, und nicht für schlecht spezifizierte Aufgaben. Ein Spitzenmodell mit vager Aufgabe liefert eine besonders gut begründete Lösung für das falsche Problem.

== Ein Modell für die Planung, eines für die Umsetzung

#table(columns: (auto, 1fr),
  [Muster], [Umsetzung],
  [Planen stark, ausführen sparsam], [Claude: `opusplan` oder Plan-Modus auf Opus, dann `/model sonnet`. Codex: `plan_mode_reasoning_effort = "high"` bei normalem Effort für die Ausführung.],
  [Hauptagent stark, Hilfsarbeit klein], [Teilagenten mit `model: haiku` (Claude) bzw. Luna für Suche, Tests, Zusammenfassungen.],
  [Zweitmeinung während der Arbeit], [Claude Code kann über das _Advisor_-Werkzeug mitten in der Aufgabe ein zweites Modell konsultieren, statt starr an der Plangrenze zu wechseln @cc-model.],
  [Umsetzen mit einem, prüfen mit dem anderen], [Claude implementiert, Codex prüft, oder umgekehrt (Kapitel 6).],
)

#tipp[Eine Faustregel für die Wahl des Effort: Wenn man bereit ist, jedes Zwischenergebnis selbst anzusehen und zu steuern, reicht ein niedriger Effort. Wenn der Agent länger allein arbeiten soll, lohnt ein höherer, weil er dann selbst gründlicher prüfen muss.]

== Am eigenen Code kalibrieren

Beide Hersteller betonen dasselbe: Effort-Stufen und Modelle sollte man an den eigenen Aufgaben testen, statt Empfehlungen zu übernehmen. Anthropic rät bei Opus 5.5 ausdrücklich, mehrere Stufen gegen eigene Auswertungen laufen zu lassen, OpenAI empfiehlt, eine vertraute Aufgabe auf einer niedrigeren Stufe zu probieren und dann anzupassen @an-opus55 @oa-models. Mit wenig Aufwand lässt sich das systematisch machen, und zwar ohne neues Dokument: Das Testmaterial steckt bereits in der Git-Historie @buch-git.

=== Die Methode

+ *Aufgaben aus der Historie wählen.* Fünf bis acht abgeschlossene Änderungen, die typisch für das Projekt sind: zwei Features, zwei Bugfixes, ein Refactoring, eine Migration. Jede muss eine Anforderung mit Akzeptanzkriterien und im Commit mitgelieferte Tests haben.
+ *Die echten Tests als Schiedsrichter nutzen.* Der Agent bekommt den Stand *vor* dem Commit und die Anforderung, aber nicht die Tests. Nach seinem Lauf werden die Tests aus dem Original-Commit eingespielt und ausgeführt. Sie prüfen unabhängig davon, was der Agent selbst getestet hat.
+ *Wenige Konfigurationen vergleichen*, etwa Opus 5.5 auf `low`, `medium` und `high` sowie GPT-6.1 Sol auf Light, Medium und High.
+ *Jede Kombination zwei- bis dreimal laufen lassen.* Die Ergebnisse streuen, ein einzelner Lauf sagt wenig.
+ *Vier Werte festhalten:* Anteil bestandener Originaltests, Diff-Größe (Hinweis auf Overengineering), Laufzeit und Verbrauch.

=== Ein Skript statt eines Dokuments

#datei("scripts/kalibrieren.sh (Skizze)")[
```bash
#!/usr/bin/env bash
# Aufruf: scripts/kalibrieren.sh <commit> <FR-Datei> <name> <agent-befehl...>
set -euo pipefail
ZIEL="$1"; FR="$2"; NAME="$3"; shift 3
BASIS="$(git rev-parse "$ZIEL^")"
WT="../kal-$NAME"

git worktree add --detach "$WT" "$BASIS" >/dev/null
cp "$FR" "$WT/AUFGABE.md"
cd "$WT"
START=$(date +%s)
"$@" "Setze AUFGABE.md um. Halte dich an AGENTS.md. Schreibe eigene Tests." \
  > agent.log 2>&1 || true
DAUER=$(( $(date +%s) - START ))

git diff --stat | tail -1                                   # Diff-Größe
git checkout "$ZIEL" -- tests/                              # Originaltests einspielen
uv run pytest -q 2>&1 | tail -1                             # bestanden / fehlgeschlagen
echo "$NAME: ${DAUER}s"
cd - >/dev/null && git worktree remove --force "$WT"
```
]

```bash
scripts/kalibrieren.sh a1b2c3d docs/anforderungen/FR-009.md opus-medium \
  claude -p --model opus --effort medium --permission-mode acceptEdits
scripts/kalibrieren.sh a1b2c3d docs/anforderungen/FR-009.md sol-medium \
  codex exec -m gpt-6.1-sol -c model_reasoning_effort='"medium"' -s workspace-write
```

=== Auswerten

#table(columns: (auto, auto, auto, auto, 1fr),
  [Konfiguration], [Originaltests], [Diff], [Dauer], [Beobachtung],
  [Opus 5.5 `low`], [7/8], [+84], [3 min], [ein Randfall fehlt],
  [Opus 5.5 `medium`], [8/8], [+91], [5 min], [passend],
  [Opus 5.5 `high`], [8/8], [+143], [9 min], [zusätzliche Hilfsklasse],
  [6.1 Sol Medium], [8/8], [+88], [6 min], [passend],
)

Die Tabelle zeigt ein erfundenes Beispiel, aber ein typisches Muster: Die niedrigste Stufe verfehlt vereinzelt Randfälle, die mittlere trifft, die hohe liefert dasselbe Ergebnis mit mehr Code und mehr Zeit. Gewählt wird *die günstigste Konfiguration, die alle Originaltests zuverlässig besteht, ohne den Diff aufzublähen.* Den Verbrauch liest man bei Claude Code aus der Ausgabe von `-p --output-format json`, bei Codex aus `/usage` bzw. der Nutzungsübersicht des Kontos.

#tipp[Eine Kalibrierung lohnt sich einmal pro Projekt und dann wieder, wenn ein neues Modell erscheint. Bei Modellwechseln, etwa dem Ende von GPT-5.5 in Codex am 14. Oktober 2026 oder dem Wechsel von Opus 5 auf Opus 5.5, zeigt dieselbe Handvoll Aufgaben innerhalb einer Stunde, ob die bisherigen Stufen noch passen @oa-models @an-migration.]

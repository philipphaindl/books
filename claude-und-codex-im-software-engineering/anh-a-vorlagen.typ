#import "lib.typ": *

= Vorlagen

== Eine Datei für beide Werkzeuge

Codex liest `AGENTS.md` @oa-agentsmd, Claude Code liest `CLAUDE.md`. Damit die Regeln nicht doppelt gepflegt werden, steht der gemeinsame Inhalt in `AGENTS.md`, und `CLAUDE.md` bindet ihn per Import ein und ergänzt nur Claude-spezifisches @cc-memory. Die Datei soll kurz bleiben (Anthropic empfiehlt unter 200 Zeilen @cc-memory): Regeln und Befehle, keine Architekturbeschreibung (die steht in den ADRs).

#datei("AGENTS.md")[
```markdown
# notizen - Regeln für Coding-Agenten

## Projekt
FastAPI + PostgreSQL, Python 3.13, Abhängigkeiten mit uv.
Anforderungen: docs/anforderungen/ (FR-xxx, NFR-xxx). Architektur: docs/adr/.

## Befehle
- Tests:        uv run pytest
- Lint/Format:  uv run ruff check . && uv run ruff format --check .
- Typen:        uv run mypy app/
- Architektur:  uv run lint-imports

## Vorgehen
- Lies vor jeder Umsetzung die betroffene Anforderung und alle dort genannten ADRs.
- Nenne im Plan die IDs, die zu ändernden Dateien und deine Annahmen.
- Schreibe pro Akzeptanzkriterium einen Test mit @pytest.mark.req("FR-xxx", "AKn").
- Setze die kleinste Änderung um, die alle Kriterien erfüllt.
- "Fertig" heißt: Tests, Lint, Typen und Import-Verträge grün, Ausgabe gezeigt.

## Umfang
Vermeide Overengineering. Ändere nur, was verlangt oder zwingend nötig ist.
Keine zusätzlichen Features, kein Refactoring nebenbei, keine neuen Abstraktionen
oder Konfigurationsoptionen für einen einzigen Fall. Validierung nur an
Systemgrenzen. Keine neuen Pakete ohne Zustimmung. Ideen außerhalb des Auftrags
am Ende in einem Satz nennen, nicht umsetzen.

## Belege
Keine Aussagen über ungeöffneten Code. APIs gegen die installierte Version prüfen.
"Läuft" nur mit Befehlsausgabe. Unsicherheit offen sagen.

## Tests
Allgemeine Lösungen, keine hart codierten Sonderfälle. Bestehende Tests nur
ändern, wenn der Auftrag es verlangt; falsche Tests melden statt anpassen.

## Unklarheiten und Architektur
Bei Unklarheiten mit großer Wirkung fragen, kleine mit der naheliegendsten
Annahme lösen und nennen. Abweichungen von ADRs, neue Muster oder Schichten:
anhalten und einen ADR-Entwurf vorlegen.
```
]

#datei("CLAUDE.md")[
```markdown
@AGENTS.md

## Nur für Claude Code
- Für Suchen im Code und Testläufe den Teilagenten "testlaeufer" verwenden.
- Reviews über den Teilagenten "pruefer" (nur lesend).
```
]

== Aufgabenstellungen

#datei("Feature")[
```text
Setze FR-012 (docs/anforderungen/FR-012.md) um. Beachte die dort genannten ADRs.
Erlaubte Pfade: app/notizen/, app/db/, tests/. Keine neuen Abhängigkeiten.
Erst Plan (IDs, Dateien, Annahmen), dann Tests pro Akzeptanzkriterium, dann Umsetzung.
Fertig: alle Tests, ruff, mypy und lint-imports grün, Ausgaben gezeigt.
Nicht Teil der Aufgabe: Suche nach Tags (FR-013).
```
]

#datei("Bugfix")[
```text
Fehler: PUT /notizen/{id}/tags liefert 500 bei leerer Liste (Log unten).
Schreibe zuerst einen Test, der den Fehler reproduziert, und zeige, dass er rot ist.
Behebe dann die Ursache mit der kleinsten Änderung. Kein Aufräumen daneben.
Fertig: neuer Test und alle bestehenden Tests grün, Ausgabe gezeigt.
```
]

#datei("Review durch das zweite Modell")[
```text
Prüfe git diff main...HEAD gegen docs/anforderungen/FR-012.md und die dort
genannten ADRs. Nur belegte Befunde (Datei, Zeile, ID, Fehlerfall):
fehlende Tests zu Akzeptanzkriterien, Änderungen außerhalb des Auftrags,
ADR-Verstöße, Fehler. Keine Stilfragen. Ändere keine Dateien.
```
]

#datei("Goal")[
```text
/goal Jedes Akzeptanzkriterium von FR-012 hat einen Test mit req("FR-012", ...);
uv run pytest, uv run ruff check . und uv run lint-imports enden ohne Fehler und
ihre Ausgabe ist im Verlauf sichtbar; keine bestehende Testdatei wurde geändert;
keine Änderung an pyproject.toml; höchstens 25 Turns.
```
]

#datei("Architekturfrage")[
```text
Wir brauchen Volltextsuche über Notizen (FR-013). Lies ADR-0003 und NFR-004.
Vergleiche höchstens drei Optionen (etwa PostgreSQL-Volltext, pg_trgm, externer
Suchdienst) nach Aufwand, Betrieb und Erfüllung von NFR-004. Keine Umsetzung.
Ergebnis: ADR-Entwurf mit Kontext, Optionen, Empfehlung und "Prüfbar durch".
```
]

== Schnellreferenz

#table(columns: (auto, 1fr, 1fr),
  [], [Claude Code], [Codex],
  [Modell wählen], [`/model`, `--model opus`], [`/model`, `-m gpt-6.1-sol`],
  [Effort], [`/effort high`, `--effort low`], [`-c model_reasoning_effort='"high"'`],
  [Einmal gründlicher], [`ultrathink` im Prompt], [Max über _More reasoning…_],
  [Planen], [Plan-Modus (#key[⇧] #key[Tab])], [`/plan`],
  [Ziel verfolgen], [`/goal <Bedingung>`], [`/goal <Ziel>`, `pause`, `resume`],
  [Review], [Teilagent `pruefer`], [`/review`, `exec -s read-only`],
  [Kontext leeren], [`/clear`, `/compact`], [neue Unterhaltung, `/compact`],
  [Parallel arbeiten], [`claude --worktree <name>`], [Worktree-Modus (App), `--worktree` (CLI, experimentell)],
  [Sandbox], [`/sandbox`], [`sandbox_mode`, `network_access = false`],
  [Mutation Testing], [`uv run mutmut run "<modul>*"`], [dasselbe],
  [Regeln], [`CLAUDE.md` (importiert `AGENTS.md`)], [`AGENTS.md`],
  [Konfiguration], [`.claude/settings.json`], [`.codex/config.toml`],
)

#import "lib.typ": *

= Ein Durchlauf von Anfang bis Ende

Dieses Kapitel spielt eine Anforderung vollständig durch: FR-012 "Notizen mit Tags versehen" aus Kapitel 10, von der Anforderung bis zum Commit. Die Ausgaben der Werkzeuge sind gekürzt und vereinfacht, der Ablauf entspricht dem Vorgehen aus den vorigen Kapiteln.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let s = (
      ([*1* Sitzung], c-accent), ([*2* Plan], c-violet), ([*3* Tests rot], c-gitea), ([*4* Goal], c-accent),
      ([*5* Prüfen], c-gitea), ([*6* Mutanten], c-gitea), ([*7* Review], c-teal), ([*8* Commit], c-blue),
    )
    for (i, e) in s.enumerate() {
      let x = i * 2.05
      kasten((x, 0), e.at(0), w: 1.8, h: 0.75, bg: e.at(1).lighten(88%), col: e.at(1), size: 7pt)
      if i < 7 { pfeil((x + 0.92, 0), (x + 1.13, 0)) }
    }
    content((2.05, -0.75), text(size: 6.3pt, fill: c-blue, style: "italic")[Mensch prüft Plan])
    content((12.3, -0.75), text(size: 6.3pt, fill: c-blue, style: "italic")[Mensch entscheidet])
  }),
  caption: [Die acht Schritte des Durchlaufs, Schritt 7 übernimmt Codex. Der Mensch greift an zwei Stellen ein: beim Plan und vor dem Commit.],
)

== Schritt 1: Sitzung in einem eigenen Worktree

```bash
cd ~/projekte/notizen
claude --worktree fr-012          # eigener Branch, eigenes Verzeichnis
```

Das Modell bleibt beim Standard Opus 5.5 mit Effort `medium`, das entspricht der Entscheidungstabelle für ein Feature mit klaren Akzeptanzkriterien (Kapitel 5). Mit #key[⇧] #key[Tab] geht es in den Plan-Modus @cc-permissions. Die Option `--worktree` legt dafür ein eigenes Arbeitsverzeichnis unter `.claude/worktrees/` an @cc-worktrees.

== Schritt 2: Plan anfordern und korrigieren

```text
Setze FR-012 (docs/anforderungen/FR-012.md) um. Beachte die dort genannten ADRs.
Erlaubte Pfade: app/notizen/, app/db/, tests/. Keine neuen Abhängigkeiten.
Erst Plan (IDs, Dateien, Annahmen), dann Tests pro Akzeptanzkriterium, dann Umsetzung.
Nicht Teil der Aufgabe: Suche nach Tags (FR-013).
```

```out
Plan für FR-012 (AK1-AK4), beachtet ADR-0003 und ADR-0007

Dateien:
  app/db/models.py            Tabelle tag, Zuordnungstabelle notiz_tag
  app/repository/tags.py      neues TagRepository
  app/service/tags.py         neuer TagService mit Cache für häufige Tags
  app/api/notizen.py          Endpunkt PUT /notizen/{id}/tags
  tests/test_tags.py          je ein Test für AK1-AK4
  alembic/versions/...        Migration

Annahmen:
  - Tags werden global geteilt, damit spätere Suche (FR-013) effizient ist.
  - Ein Cache verbessert NFR-004.
Frage: Sollen Tags bei der Ausgabe ebenfalls kleingeschrieben sein? (AK2)
```

Der Plan zeigt genau die Muster aus Kapitel 8: eine eigene Tabelle "damit spätere Suche effizient ist" (vorweggenommene Anforderung FR-013) und ein Cache ohne Messung. Hier ist die Korrektur am billigsten, ein Satz statt einer Stunde Code:

```text
Keine eigene Tag-Tabelle und kein Cache: FR-013 ist nicht Teil der Aufgabe, und
NFR-004 ist ohne Cache zu prüfen. Speichere Tags als Spalte tags (Text-Array) an
der Notiz. Zu AK2: ja, auch die Ausgabe ist kleingeschrieben. Passe den Plan an.
```

```out
Überarbeiteter Plan:
  app/db/models.py            Spalte tags (ARRAY(Text)) an Notiz
  app/service/notizen.py      Funktion tags_setzen (Validierung AK2, AK3)
  app/repository/notizen.py   Methode tags_speichern
  app/api/notizen.py          Endpunkt PUT /notizen/{id}/tags
  tests/test_tags.py          je ein Test für AK1-AK4
  alembic/versions/...        Migration (Spalte hinzufügen)
Annahmen: keine offenen.
```

== Schritt 3: Tests zuerst

Nach Freigabe des Plans schreibt der Agent die Tests, markiert mit den IDs, und zeigt, dass sie fehlschlagen:

```out
$ uv run pytest tests/test_tags.py -q
FFFF                                                                  [100%]
4 failed in 0.84s
```

Vier rote Tests, einer pro Akzeptanzkriterium: Die Anforderung liegt jetzt in ausführbarer Form vor.

== Schritt 4: Umsetzung als Goal

Die Umsetzung ist mechanisch und hat ein messbares Ende, also passt ein Goal (Kapitel 9) @cc-goal:

```text
/goal Alle Tests in tests/test_tags.py und die übrigen Tests sind grün; uv run ruff
check ., uv run mypy app/ und uv run lint-imports laufen ohne Befund; die Ausgaben
sind im Verlauf sichtbar; tests/test_tags.py wird nicht mehr geändert; keine
Änderung außerhalb der erlaubten Pfade; höchstens 20 Turns.
```

```out
/goal
  ◎ Ziel erreicht nach 4 Turns
  Begründung: pytest 47 passed, ruff und mypy ohne Befund, lint-imports:
  2 contracts kept, 0 broken. Keine Änderung an tests/test_tags.py.
```

== Schritt 5: Prüfen

```out
$ git diff --stat main
 alembic/versions/0012_notiz_tags.py | 22 ++++++++++++
 app/api/notizen.py                  | 14 ++++++++
 app/db/models.py                    |  2 +
 app/repository/notizen.py           |  9 +++++
 app/service/notizen.py              | 21 +++++++++++
 tests/test_tags.py                  | 48 ++++++++++++++++++++++++++
 6 files changed, 116 insertions(+)
```

Sechs Dateien, alle innerhalb der erlaubten Pfade und entlang der Schichten aus ADR-0003, keine Änderung an `pyproject.toml`. Der Diff ist so groß, wie die Anforderung es erwarten lässt.

== Schritt 6: Taugen die Tests?

```out
$ uv run mutmut run "app.service.notizen.x_tags_setzen*"
...
$ uv run mutmut results
app.service.notizen.x_tags_setzen__mutmut_4: survived
app.service.notizen.x_tags_setzen__mutmut_9: survived
```

Zwei überlebende Mutanten @mutmut: `> 10` wurde zu `>= 10` verändert, und die Längengrenze 30 wurde zu 31. Beide Grenzfälle fehlen in den Tests. Auftrag an den Agenten:

```text
Ergänze Tests, sodass die überlebenden Mutanten 4 und 9 getötet werden: genau 10
Tags sind erlaubt, ein Tag mit genau 30 Zeichen ist erlaubt, mit 31 nicht.
Ändere keinen Produktivcode.
```

Danach sind beide Mutanten getötet. Die Tests prüfen jetzt die Grenzen von AK3, nicht nur einen Fall weit darüber.

== Schritt 7: Review durch Codex

In einem zweiten Terminal läuft Codex nur lesend über den Branch:

```bash
cd ~/projekte/notizen/.claude/worktrees/fr-012
codex exec -m gpt-6.1-sol -c model_reasoning_effort='"high"' -s read-only \
  "Prüfe git diff main...HEAD gegen docs/anforderungen/FR-012.md und die dort
   genannten ADRs. Nur belegte Befunde mit Datei, Zeile, ID und Fehlerfall.
   Keine Stilfragen. Ändere keine Dateien."
```

```out
Befund 1 (FR-012 AK4): tests/test_tags.py prüft 404 nur für eine fremde Notiz,
  nicht für eine nicht existierende ID. AK4 verlangt beides.
Befund 2 (ADR-0007): app/api/notizen.py:88 gibt bei ungültigen Tags ein JSON mit
  "detail" zurück, nicht application/problem+json.
Hinweis: Die Variable t in app/service/notizen.py:52 könnte sprechender heißen.
```

Befund 1 und 2 sind belegt und betreffen Anforderung und ADR (ADR-0007 verlangt das Fehlerformat `application/problem+json` nach RFC 9457 @rfc9457), sie gehen an Claude zurück. Der Hinweis zur Benennung ist eine Stilfrage ohne Fehler und wird nach der Regel aus Kapitel 6 verworfen. Nach der Korrektur laufen Tests und Prüfungen erneut grün. Damit ist der Durchgang beendet, es gibt keine zweite Review-Runde zwischen den Modellen.

== Schritt 8: Menschliches Review und Commit

Das Review folgt der Checkliste aus Kapitel 11: Jedes Akzeptanzkriterium hat einen Test, der Diff enthält nichts außerhalb von FR-012, keine bestehenden Tests wurden geändert, keine neuen Pakete, ADR-0003 und ADR-0007 sind eingehalten. Dann der Commit:

```text
Tags für Notizen (FR-012)

Setzt AK1 bis AK4 um. Tags als Spalte an der Notiz; Suche nach Tags ist
nicht enthalten (FR-013).

Refs: FR-012
```

== Was der Durchlauf zeigt

#table(columns: (auto, 1fr),
  [Schritt], [Was es gebracht hat],
  [Plan-Modus], [Zwei Fälle von Overengineering (eigene Tabelle für eine künftige Anforderung, Cache ohne Messung) für einen Satz Korrektur entfernt.],
  [Tests zuerst], [Die Anforderung wurde ausführbar, bevor Code entstand. Das Goal hatte ein eindeutiges Ende.],
  [Goal], [Die mechanische Umsetzung lief ohne ständiges "mach weiter".],
  [Mutation Testing], [Zwei Grenzfälle gefunden, die grüne Tests nicht abgedeckt hatten.],
  [Codex-Review], [Eine Lücke bei AK4 und ein ADR-Verstoß gefunden, die dem Umsetzer entgangen waren.],
  [Mensch], [Richtung am Anfang, Entscheidung am Ende. Dazwischen keine Kleinarbeit.],
)

Kein Schritt dieses Ablaufs hat ein neues Dokument erzeugt. Die Anforderung und die ADRs existierten vorher, der Plan blieb im Gespräch, und die Rückverfolgbarkeit steckt in Testmarkierungen und Commit-Nachricht.

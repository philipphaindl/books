#import "lib.typ": *

= ADRs und Anforderungen als Leitplanken

Wer mit Coding-Agenten arbeitet, stößt schnell auf _Spec-Driven Development_ (SDD): Vor dem Code entsteht eine Spezifikation, daraus ein Plan, daraus Aufgaben, und der Agent setzt sie um. Die Idee ist richtig, die üblichen Werkzeuge bringen aber pro Feature mehrere neue Dokumente mit. Dieses Kapitel zeigt, dass ein Projekt mit funktionalen und nicht-funktionalen Anforderungen als Markdown samt Akzeptanzkriterien und mit ADRs den Kern von SDD bereits besitzt, und wie man diese vorhandenen Artefakte so schärft, dass Agenten zuverlässig damit arbeiten.

== Was Spec-Driven Development will

Bekannte Umsetzungen sind etwa GitHub Spec Kit (Spezifikation, Plan und Aufgabenliste pro Feature, dazu eine projektweite "Verfassung" mit Grundregeln @speckit) und AWS Kiro (Anforderungen in strukturierter Notation, Entwurf und Aufgaben pro Feature @kiro). Die Werkzeuge entwickeln sich schnell, die Grundgedanken sind stabil:

+ *Anforderungen vor Code*, mit prüfbaren Akzeptanzkriterien.
+ *Ein Plan*, der Anforderungen mit Architekturentscheidungen verbindet, bevor Code entsteht.
+ *Rückverfolgbarkeit* von der Anforderung bis zur Umsetzung.
+ *Projektweite Regeln*, die jeder Agent kennt.

Die Kritik betrifft nicht die Idee, sondern den Preis: pro Feature drei zusätzliche Dateien, die gepflegt werden müssen, generierte Spezifikationen, die niemand liest, und Dokumente, die nach dem Merge vom Code abweichen. Genau das soll hier vermieden werden.

== Was bereits vorhanden ist

#table(columns: (auto, 1fr, auto),
  [SDD-Baustein], [Vorhandenes Gegenstück], [Neues Artefakt?],
  [Spezifikation pro Feature], [FR- und NFR-Dateien mit Akzeptanzkriterien], [nein],
  [Projektweite Regeln ("Verfassung")], [`CLAUDE.md` / `AGENTS.md` plus die ADRs], [nein],
  [Entwurf, Plan], [Plan-Modus im Gespräch; bei Architektur-Tragweite ein ADR], [nein],
  [Aufgabenliste], [Aufgabenliste des Agenten während der Sitzung], [nein],
  [Rückverfolgbarkeit], [IDs in Testmarkierungen und Commit-Nachrichten], [nein],
)

Die Optimierung besteht also nicht darin, etwas hinzuzufügen, sondern die vorhandenen Dokumente *agententauglich* zu machen: eindeutig, prüfbar, verlinkt.

== Anforderungen agententauglich schreiben

Ein Agent liest Anforderungen wörtlich. Was nicht dasteht, füllt er mit Annahmen. Fünf Eigenschaften machen den Unterschied:

#table(columns: (auto, 1fr),
  [Eigenschaft], [Umsetzung],
  [*Stabile ID*], [`FR-012`, `NFR-004`. Die ID ist der Anker für Tests, Commits und Reviews.],
  [*Prüfbare Kriterien*], [Jedes Akzeptanzkriterium lässt sich in genau einen Test übersetzen. "Schnell" ist kein Kriterium, "p95 unter 200 ms bei 50 gleichzeitigen Anfragen" schon.],
  [*Ausdrückliche Grenzen*], [Ein Abschnitt "Nicht Teil dieser Anforderung". Er verhindert mehr Overengineering als jede Anweisung im Prompt.],
  [*Verweise*], [Betroffene ADRs und verwandte Anforderungen per ID.],
  [*Offene Fragen*], [Ungeklärtes wird als solches markiert, damit der Agent fragt statt erfindet.],
)

#datei("docs/anforderungen/FR-012.md")[
```markdown
# FR-012 Notizen mit Tags versehen

Benutzer können eigene Notizen mit Tags versehen, um sie zu ordnen.

## Akzeptanzkriterien
- AK1: Gegeben eine eigene Notiz, wenn der Benutzer PUT /notizen/{id}/tags mit
  ["uni", "privat"] sendet, dann enthält die Notiz genau diese Tags (Antwort 200).
- AK2: Tags werden kleingeschrieben gespeichert; "Uni" und "uni" sind derselbe Tag.
- AK3: Höchstens 10 Tags pro Notiz, je Tag 1 bis 30 Zeichen aus [a-z0-9-];
  sonst Antwort 422 mit Problem Details.
- AK4: Für eine fremde oder nicht existierende Notiz antwortet die API mit 404.

## Nicht Teil dieser Anforderung
- Suche oder Filterung nach Tags (geplant als FR-013)
- Umbenennen oder globales Löschen von Tags

## Bezüge
- ADR-0003 Schichtenarchitektur, ADR-0007 Fehlerformat nach RFC 9457
- NFR-004 Antwortzeiten

## Offene Fragen
- keine
```
]

Nicht-funktionale Anforderungen brauchen zusätzlich eine *Messmethode*, sonst sind sie für einen Agenten nicht prüfbar. Im Beispiel übernimmt sie ein Lasttest mit Locust @locust:

#datei("docs/anforderungen/NFR-004.md")[
```markdown
# NFR-004 Antwortzeiten der Notiz-Endpunkte

## Akzeptanzkriterien
- AK1: p95 der Antwortzeit unter 200 ms für GET /notizen und PUT /notizen/{id}/tags
  bei 50 gleichzeitigen Benutzern und 10.000 Notizen in der Datenbank.
## Messung
- Lasttest tests/last/test_notizen.py (locust), Ergebnis im CI-Artefakt.
```
]

== ADRs agententauglich schreiben

Ein ADR hält eine Architekturentscheidung mit Kontext und Konsequenzen fest, etwa im Format von Michael Nygard @nygard oder MADR @madr. Das Fehlerformat in ADR-0007 folgt RFC 9457 @rfc9457. Für Agenten lohnen sich zwei kleine Schärfungen *innerhalb* der bestehenden Abschnitte, kein neues Dokument:

- Unter *Konsequenzen* konkret benennen, was daraus für die Umsetzung folgt: was erlaubt ist, was nicht.
- Eine Zeile *Prüfbar durch*: Welche automatische Prüfung stellt sicher, dass der Code der Entscheidung folgt?

#datei("docs/adr/0003-schichtenarchitektur.md")[
```markdown
# ADR-0003 Schichtenarchitektur für die API

Status: akzeptiert (2026-03-12)

## Kontext
Endpunkte griffen direkt auf die Datenbank zu; Geschäftsregeln waren verstreut.

## Entscheidung
Drei Schichten: app.api (HTTP) -> app.service (Regeln) -> app.repository (DB).
Abhängigkeiten nur von oben nach unten.

## Konsequenzen
- Endpunkte rufen nur Services auf, nie Repositories oder SQLAlchemy direkt.
- Services kennen keine FastAPI-Typen (Request, Response, HTTPException).
- Neue Schichten oder Querschnittsmodule nur mit neuem ADR.

## Prüfbar durch
- import-linter-Vertrag "Schichten gemäß ADR-0003" (pyproject.toml), läuft in der CI.
```
]

Die Zeile "Prüfbar durch" verwandelt eine Absichtserklärung in eine Leitplanke. Ein ADR ohne automatische Prüfung wird von Agenten genauso oft übersehen wie von Menschen.

== Der Ablauf

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let k(x, y, t, c) = kasten((x, y), t, w: 2.55, h: 0.95, bg: c.lighten(88%), col: c, size: 7pt)
    k(0, 0, [*1 Lesen* \ #text(size: 6.2pt)[FR, NFR, ADRs]], c-yellow)
    k(3.2, 0, [*2 Plan* \ #text(size: 6.2pt)[IDs, Dateien, Annahmen]], c-violet)
    k(6.4, 0, [*3 Tests zuerst* \ #text(size: 6.2pt)[je AK ein Test, rot]], c-gitea)
    k(9.6, 0, [*4 Umsetzen* \ #text(size: 6.2pt)[kleinste Änderung]], c-accent)
    k(12.8, 0, [*5 Prüfen* \ #text(size: 6.2pt)[Tests, Lint, Regeln]], c-gitea)
    k(12.8, -1.7, [*6 Review* \ #text(size: 6.2pt)[gegen FR und ADR]], c-blue)
    k(9.6, -1.7, [*7 Commit* \ #text(size: 6.2pt)[mit IDs]], c-blue)
    for x in (1.3, 4.5, 7.7, 10.9) { pfeil((x, 0), (x + 0.6, 0)) }
    pfeil((12.8, -0.5), (12.8, -1.2)); pfeil((11.5, -1.7), (10.9, -1.7))
    content((3.2, -1.2), text(size: 6.5pt, fill: c-grey.darken(20%), style: "italic")[Mensch prüft hier den Plan])
    line((3.2, -0.95), (3.2, -0.5), stroke: (paint: c-grey, thickness: 0.6pt, dash: "dashed"))
  }),
  caption: [Der Ablauf nutzt nur vorhandene Artefakte. Der Plan bleibt im Gespräch, Tests und Commit tragen die IDs.],
)

+ *Lesen:* Der Agent liest die Anforderung und alle referenzierten ADRs und NFRs, bevor er etwas plant.
+ *Plan (Plan-Modus):* Er nennt die IDs, zählt die zu ändernden Dateien auf und legt Annahmen offen. Der Mensch prüft den Plan, hier ist Korrektur am billigsten.
+ *Tests zuerst:* Pro Akzeptanzkriterium ein Test, markiert mit der ID, zunächst rot. Die Tests sind die ausführbare Fassung der Anforderung.
+ *Umsetzen:* die kleinste Änderung, die alle Tests grün macht und die ADRs einhält. Diese Phase eignet sich für ein Goal (Kapitel 9).
+ *Prüfen:* Tests, Linter, Typprüfung, Architekturregeln, lokal und in der CI.
+ *Review:* durch das zweite Modell (Kapitel 6) und den Menschen, gegen Anforderung und ADRs.
+ *Commit* mit Verweis auf die IDs.

== Rückverfolgbarkeit ohne Zusatzaufwand

Die IDs wandern in Artefakte, die ohnehin entstehen:

#datei("tests/test_tags.py (Auszug)")[
```python
import pytest

@pytest.mark.req("FR-012", "AK3")
def test_mehr_als_zehn_tags_ergibt_422(client, eigene_notiz):
    antwort = client.put(f"/notizen/{eigene_notiz}/tags", json=[f"t{i}" for i in range(11)])
    assert antwort.status_code == 422
    assert antwort.headers["content-type"] == "application/problem+json"
```
]

#datei("pyproject.toml (Auszug)")[
```toml
[tool.pytest.ini_options]
markers = ["req(id, ak): verknüpft einen Test mit Anforderung und Akzeptanzkriterium"]
```
]

Eigene Markierungen sollten in der Konfiguration registriert sein, damit pytest bei Tippfehlern warnt (mit `--strict-markers` sogar abbricht) @pytest-markers.

```text
Tags für Notizen (FR-012)

Setzt AK1 bis AK4 um. Suche nach Tags ist nicht enthalten (FR-013).

Refs: FR-012
```

Damit lässt sich jede Frage mit einem Suchbefehl beantworten: Welche Tests decken FR-012 ab (`rg 'req\("FR-012"' tests/`)? In welchem Commit kam FR-012 (`git log --grep "FR-012"`)? Welches Akzeptanzkriterium hat noch keinen Test? Letzteres ist ein guter Prüfauftrag für das zweite Modell.

== Architekturkonformität automatisch prüfen

Die Zeile "Prüfbar durch" im ADR braucht eine Umsetzung. Für Python eignet sich _import-linter_, das Regeln über erlaubte Importe als Verträge prüft @import-linter:

#datei("pyproject.toml (Auszug)")[
```toml
[tool.importlinter]
root_package = "app"

[[tool.importlinter.contracts]]
name = "Schichten gemäß ADR-0003"
type = "layers"
layers = ["app.api", "app.service", "app.repository"]

[[tool.importlinter.contracts]]
name = "Services ohne FastAPI (ADR-0003)"
type = "forbidden"
source_modules = ["app.service"]
forbidden_modules = ["fastapi"]
```
]

```bash
uv run lint-imports
```

Der Befehl läuft lokal, im Goal als Teil der Bedingung und in der CI. Verstößt der Agent gegen einen ADR, erfährt er es sofort und mit Namen des Vertrags, statt erst im Review. Wer die Architektur zusätzlich als C4-Modell @c4 pflegt, etwa in Structurizr DSL, kann Container- und Komponentengrenzen auf dieselbe Weise in Import-Verträge übersetzen und so prüfen, ob Code und Modell noch übereinstimmen.

== Wann doch ein neues ADR entsteht

Stößt der Agent bei der Umsetzung auf eine Entscheidung mit Architektur-Tragweite (neue Abhängigkeit, neues Muster, Abweichung von einem bestehenden ADR), soll er sie nicht stillschweigend treffen. Die Regel in `CLAUDE.md` / `AGENTS.md`:

```markdown
## Architekturentscheidungen
Weicht eine Lösung von einem ADR ab oder erfordert sie eine neue Abhängigkeit,
ein neues Muster oder eine neue Schicht: nicht umsetzen, sondern anhalten und
einen ADR-Entwurf (Kontext, Optionen, Empfehlung) zur Entscheidung vorlegen.
```

So entstehen ADRs nur dort, wo tatsächlich entschieden wird, und der Agent wird vom Risiko zum Werkzeug: Er erkennt die Entscheidung, bereitet sie vor, und der Mensch trifft sie.

#merke[Spec-Driven Development ohne neue Artefakte heißt: Anforderungen mit IDs, prüfbaren Kriterien und ausdrücklichen Grenzen, ADRs mit konkreten Konsequenzen und einer automatischen Prüfung, ein Plan im Gespräch statt in einer Datei, Tests und Commits als Träger der Rückverfolgbarkeit. Der Aufwand liegt in der Qualität der vorhandenen Dokumente, nicht in ihrer Anzahl.]

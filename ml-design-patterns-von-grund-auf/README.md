# ML Design Patterns von Grund auf - Typst-Quellen

Persönliches Handbuch für Software Engineers ohne ML-Vorwissen: die 30 Patterns aus Lakshmanan,
Robinson und Munn (2020), ML-Grundlagen, ML-Systeme in Produktion, drei Fallstudien, Übungen mit
Lösungen. 229 Seiten. Entstanden zur LV „Clean Code und Software Engineering“ (MDI, WS27); die
Folien und Praxisprojekte dazu liegen unter `Lehre/WS27/MDI - Clean Code und Software Engineering/`.

## Bauen

    typst compile --font-path fonts main.typ ML-Design-Patterns-von-Grund-auf.pdf

Zum Live-Bearbeiten: `typst watch --font-path fonts main.typ`

Voraussetzungen: Typst 0.14 oder neuer; die Pakete cetz 0.4.1, cetz-plot und fletcher 0.5.8 lädt
Typst selbst. Das lokale Paket `@local/ai-disclosure` muss installiert sein. Inter und JetBrains
Mono liegen in `fonts/`; in Diagrammen wird zusätzlich Latin Modern Sans verwendet (alle
Knotenbreiten sind damit gesetzt).

Design: Reihe `Documents/Sources/books` (Layout nach `git-von-grund-auf/main.typ`, steckt hier in
`lib.typ` als Funktion `handbuch`). `main.typ` ist das Manifest, `titelgrafik.typ` die Grafik der
Titelseite, `literatur.typ` das Literaturverzeichnis (BibTeX, Stil IEEE).

## Ordnerstruktur

```
main.typ                          Manifest: Titelseite, Inhaltsverzeichnis, Teile, Kapitel, Literatur
lib.typ                           Layout und Helfer (Kopf/Fuß, Kapitelkopf, Kästen, Konsole, Diagramm-Fit)
literatur.bib                     alle Quellen, Schlüssel nach dem Schema nachname_stichwort_jahr
kapitel/                          ein Typst-Dokument je Kapitel, jedes beginnt mit #import "../lib.typ": *
  01-einleitung.typ               Kapitel 1  Einleitung
  02-ml-grundlagen.typ            Kapitel 2  ML-Grundlagen für Software Engineers
  03-landkarte.typ                Kapitel 3  Landkarte der 30 Patterns (Lebenszyklus, Symptomtabelle)
  04-data-representation.typ      Kapitel 4  Patterns 1-4
  05-problem-representation.typ   Kapitel 5  Patterns 5-10
  06-model-training.typ           Kapitel 6  Patterns 11-15
  07-resilient-serving.typ        Kapitel 7  Patterns 16-20
  08-reproducibility.typ          Kapitel 8  Patterns 21-27
  09-responsible-ai.typ           Kapitel 9  Patterns 28-30
  10-lehre.typ                    Kapitel 10 Die Patterns unterrichten (Projektbezug, Coaching)
  a-spickzettel.typ               Anhang A   alle 30 Patterns als Tabelle (Problem, Lösung, Trade-off)
  b-glossar.typ                   Anhang B   Glossar
code/                             lauffähige Beispiele, ein Unterordner je Kapitel (siehe unten)
images/                           Logo und die Bilder der Teil-Trennseiten
_vorlage-bmd/                     Layout-Vorlage (Python-Handbuch), nur als Referenz
```

Die Dateien `kapitel/02b-*`, `kapitel/11-*` bis `kapitel/15-*` und die Ordner `code/02b`, `code/11-*` bis
`code/15` gehören zum Ausbau des Handbuchs zum vollständigen Buch. Sie sind (Stand dieser Fassung) nicht im
Manifest eingebunden und gehören nicht zum Kernbuch.

Diagramme sind in Typst gezeichnet (fletcher, cetz, cetz-plot), nicht als Bild eingebunden. Zahlen in Plots
stammen aus den Skripten in `code/` (JSON-Dateien neben den Skripten, die das Kapitel einliest).
`lib.typ` verkleinert Diagramme, die breiter als die Textspalte sind, automatisch auf Textbreite.

## Code-Beispiele ausführen

Alle Beispiele der Kapitel 2 und 4 bis 10 laufen mit einem Befehl. Nötig ist nur [uv](https://docs.astral.sh/uv/);
Python und alle Bibliotheken (numpy, pandas, scipy, scikit-learn, imbalanced-learn, fairlearn, fastapi, httpx,
joblib) holt uv selbst in eine temporäre Umgebung.

```sh
sh code/run_all.sh
```

Einzelne Kapitel:

```sh
sh code/run_all.sh 05-problem-representation 09-responsible-ai
```

Was das Skript tut:

- Es kopiert die Kapitelordner in einen temporären Ordner und führt die Skripte dort aus. Die Dateien, die das
  Handbuch beim Bauen liest (JSON-Daten für Plots, gespeicherte Ausgaben), bleiben unverändert.
- Die Ausgabe jedes Skripts landet in `code/_lauf/<ordner>/<skript>.txt`.
- Zu jedem Skript steht, ob die Ausgabe mit der im Handbuch gezeigten übereinstimmt. Der Seed ist überall fest;
  Abweichungen sind nur bei Zeitmessungen (`07-resilient-serving/batch_serving.py`) und beim absichtlich
  zufälligen `hash()` von Python (`04-data-representation/02_hashed_feature.py`, Zeile mit „drei Prozessen“) zu erwarten.
- Der Rückgabewert ist 0, wenn alle Skripte fehlerfrei durchlaufen.

Ein einzelnes Skript lässt sich auch direkt ausführen, zum Beispiel:

```sh
cd code/04-data-representation
uv run --with scikit-learn --with pandas --with numpy python 02_hashed_feature.py
```

Welche Pakete ein Skript braucht, zeigt das Kapitel neben dem Beispiel; die Gesamtliste steht in der Variable `PY`
in `code/run_all.sh`. Beim direkten Aufruf schreiben manche Skripte ihre JSON-Daten neben sich (die Plots im Handbuch lesen sie).

## Literatur pflegen

Neue Quellen in `literatur.bib` anhängen, Schlüssel nach `nachname_stichwort_jahr`, nur Werke mit geprüften
Angaben (Autor, Jahr, Titel, Venue). Zitiert wird mit `@schluessel` oder `#cite(<schluessel>, form: "prose")`.
Das Literaturverzeichnis (Stil `harvard-cite-them-right`) zeigt nur zitierte Einträge.

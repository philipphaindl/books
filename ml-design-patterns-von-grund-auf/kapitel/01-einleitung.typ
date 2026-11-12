#import "../lib.typ": *

= Einleitung

== Wozu dieses Handbuch

Wer Software baut, kennt Entwurfsmuster: Strategy, Observer, Factory. Sie benennen eine wiederkehrende Aufgabe, eine bewährte Lösung und den Preis, den man dafür zahlt. Seit einigen Jahren gibt es einen vergleichbaren Katalog für Systeme, die aus Daten lernen. Valliappa Lakshmanan, Sara Robinson und Michael Munn haben 2020 dreißig solcher Muster beschrieben @lakshmanan_ml_design_patterns_2020. Dieses Handbuch erklärt sie für Leserinnen und Leser, die Software entwerfen können, aber noch nie ein Modell trainiert haben.

Das Ziel ist zweifach. Erstens sollen Sie jedes der dreißig Patterns so weit verstehen, dass Sie in einem Projekt erkennen, wann es passt und wann nicht. Zweitens sollen Sie es Studierenden erklären können, die Data Science im Master studieren, aber nicht unbedingt eine Softwareausbildung mitbringen. Deshalb enthält jedes Pattern neben der Mechanik auch einen Unterrichtsvorschlag mit einer Verständnisfrage.

Das Buch von Lakshmanan et al. ist dicht und setzt vieles voraus: TensorFlow, Keras, BigQuery ML und ein Grundverständnis von Training und Evaluation. Dieses Handbuch schließt die Lücke an zwei Stellen: Kapitel 2 und 3 bauen das nötige Wissen in der Sprache eines Software Engineers auf, und die Pattern-Kapitel zeigen jede Idee an einem kleinen Beispiel mit Zahlen, das Sie selbst ausführen können.

== So lesen Sie es

Das Handbuch ist in sieben Teile gegliedert (@abb-leseweg). Teil I legt das Fundament: diese Einleitung, die ML-Grundlagen in Kapitel 2, die Funktionsweise neuronaler Netze in Kapitel 3 und in Kapitel 4 eine Landkarte, die alle dreißig Patterns an einem gemeinsamen Lebenszyklus verortet. Die Teile II bis IV behandeln die sechs Kategorien des Buchs, jeweils ein Kapitel pro Kategorie. Teil V zeigt, wie die Patterns in einem laufenden System zusammenwirken. Teil VI führt drei Fallstudien durch, in denen ein Team ein naives Notebook Schritt für Schritt verbessert. Teil VII sammelt, was beim Unterrichten hilft, und enthält Übungen mit Lösungen.

#figure(
  {
    set text(size: 8.5pt)
    set par(justify: false)
    let teil(pos, nr, kap, titel, fill: blau-hell, fg: black) = node(pos, text(fill: fg)[*Teil #nr* \ #kap \ #titel], fill: fill, stroke: if fill == blau { none } else { 0.6pt + luma(140) }, width: 2.0cm, height: 1.9cm, corner-radius: 3pt, inset: 4pt)
    diagram(
      spacing: (5pt, 10pt),
      teil((0, 0), [I], [Kap. 1–4], [Grundlagen, Landkarte], fill: blau, fg: white),
      teil((1, 0), [II], [Kap. 5, 6], [Daten und Problem]),
      teil((2, 0), [III], [Kap. 7, 8], [Training und Betrieb]),
      teil((3, 0), [IV], [Kap. 9, 10], [Reproduzierbarkeit, Verantwortung]),
      teil((4, 0), [V], [Kap. 11], [ML-Systeme bauen], fill: luma(240)),
      teil((5, 0), [VI], [Kap. 12–14], [Fallstudien], fill: luma(240)),
      teil((6, 0), [VII], [Kap. 15, 16], [Unterrichten, Übungen], fill: luma(240)),
      edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"), edge((3, 0), (4, 0), "-|>"), edge((4, 0), (5, 0), "-|>"), edge((5, 0), (6, 0), "-|>"),
    )
  },
  caption: [Leseweg durch das Handbuch. Die Pattern-Kapitel in den Teilen II bis IV lassen sich in beliebiger Reihenfolge lesen; Kapitel 2 und 3 kann überspringen, wer schon Modelle trainiert hat. Die Abhängigkeiten zwischen den Patterns zeigt Kapitel 4.],
) <abb-leseweg>

Wenn Sie noch nie ein Modell trainiert haben, lesen Sie Kapitel 2 von vorn nach hinten und führen die Beispiele aus; die Abschnitte bauen aufeinander auf. Wer schon Modelle trainiert hat, überfliegt nur den Lebenszyklus und die Begriffe für den Betrieb am Ende von Kapitel 2, weil die Patterns diese Vokabeln voraussetzen. Kapitel 4 lohnt sich in beiden Fällen als Übersicht, zu der man zurückkehrt, wenn man ein Symptom aus einem Projekt einem Pattern zuordnen will. Die Pattern-Kapitel sind unabhängig voneinander lesbar; Querverweise stehen im Text und gesammelt in Kapitel 4. Im Anhang finden Sie einen Spickzettel und ein Glossar.

== Was ein ML Design Pattern ist

Ein Entwurfsmuster im Sinne von Gamma et al. @gamma_design_patterns_1994 beschreibt eine Anordnung von Klassen und Objekten, die ein wiederkehrendes Entwurfsproblem löst. Das Muster lässt sich im Code sehen: Man findet die Schnittstelle, die Delegation, die Vererbungsbeziehung. Ein ML Design Pattern hat dieselbe Dreiteilung aus Problem, Lösung und Trade-off, aber es wirkt auf einer anderen Ebene. Es betrifft die Daten, die ein Modell sieht, die Art, wie es trainiert wird, und die Umstände, unter denen es Vorhersagen liefert.

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    align: (left, left, left),
    [], [GoF-Pattern], [ML Design Pattern],
    [Gegenstand], [Klassen und Objekte im Programm], [Daten, Training und Betrieb eines Modells],
    [Lösung], [Anordnung von Code-Bausteinen, im Quelltext ablesbar], [Ein Verfahren: Transformation, Trainingsschritt, Betriebsentscheidung],
    [Prüfbarkeit], [Strukturell und durch Tests, deterministisch], [Statistisch: Wirkung zeigt sich in Metriken auf Daten],
    [Problemursache], [Änderungen und Erweiterungen am Programm], [Eigenschaften von Daten und Lernverfahren (Ungleichgewicht, Drift)],
  ),
  caption: [GoF-Patterns und ML Design Patterns im Vergleich.],
)

Der zweite und dritte Punkt sind die wichtigsten. Bei Strategy sehen Sie am Code, ob das Pattern angewandt wurde. Bei Rebalancing sehen Sie im Code eine Zeile, die Beispiele gewichtet oder dupliziert; ob das Pattern _wirkt_, erfahren Sie erst, wenn Sie die Metriken des Modells auf Daten ansehen, die es nicht trainiert haben. Ein ML-Pattern ist deshalb immer an eine Messung gekoppelt, und die Pattern-Kapitel nennen jeweils, was man messen muss.

Ein weiterer Unterschied ist die Bandbreite. Manche der dreißig Patterns sind klassisches Software Engineering mit ML-Bezug: Stateless Serving Function ist ein zustandsloser Dienst, Workflow Pipeline ist Orchestrierung, Model Versioning ist Versionierung von Artefakten. Andere haben kein Gegenstück in der Softwarewelt, etwa Neutral Class oder Useful Overfitting, weil sie auf Eigenheiten des Lernens zurückgehen. Das Handbuch nennt bei jedem Pattern das bekannte SE-Prinzip, wenn es eines gibt.

Zum Status: Die dreißig Patterns sind eine Sammlung bewährter Praxis, kein Standard und nicht erschöpfend. Manche überlappen, einige haben inzwischen eigene Werkzeuge bekommen. Als gemeinsames Vokabular sind sie trotzdem nützlich; als Checkliste sollte man sie nicht abarbeiten.

== Quelle und Nummerierung

Alle Patterns stammen aus _Machine Learning Design Patterns_ von Lakshmanan, Robinson und Munn @lakshmanan_ml_design_patterns_2020. Das Buch ordnet sie in sechs Kategorien, denen je ein Kapitel gewidmet ist, und nummeriert die Patterns fortlaufend von 1 bis 30. Das Handbuch übernimmt diese Nummern: Pattern 21 ist im Buch wie hier Transform. Die Kapitel 1 und 8 des Buchs enthalten keine eigenen Patterns; Kapitel 1 führt in typische Herausforderungen ein, Kapitel 8 zeigt, wie Patterns zusammenspielen. Letzteres leistet in diesem Handbuch Kapitel 4.

#figure(
  table(
    columns: (auto, auto, auto, 1fr),
    align: (left, right, left, left),
    [Kategorie im Buch], [Patterns], [Handbuch], [Leitfrage],
    [Data Representation], [1–4], [Kapitel 5], [Wie werden Rohwerte zu Zahlen?],
    [Problem Representation], [5–10], [Kapitel 6], [Wie wird die Aufgabe lösbar formuliert?],
    [Model Training], [11–15], [Kapitel 7], [Wie trainiert man zuverlässig?],
    [Resilient Serving], [16–20], [Kapitel 8], [Wie liefert man robust aus?],
    [Reproducibility], [21–27], [Kapitel 9], [Wie bleibt das Ergebnis wiederholbar?],
    [Responsible AI], [28–30], [Kapitel 10], [Ist das Modell erklärbar und fair?],
  ),
  caption: [Die sechs Kategorien des Buchs und ihre Lage im Handbuch (4 + 6 + 5 + 5 + 7 + 3 = 30 Patterns).],
) <tab-kategorien>

Die Namen folgen dem Inhaltsverzeichnis des Buchs. Eine Abweichung ist bekannt: Pattern 22 heißt dort _Repeatable Splitting_, im Begleit-Repository des Buchs dagegen _Repeatable Sampling_; Nummer und Inhalt sind dieselben. Zitiert wird das Buch nach Kapitel und Pattern-Nummer, nicht nach Seitenzahl, weil sich diese zwischen den Ausgaben unterscheiden. Primärquellen sind in den Pattern-Kapiteln genannt, soweit sie sich eindeutig zuordnen ließen.

== Konventionen

Das Buch arbeitet überwiegend mit TensorFlow, Keras und BigQuery ML. Dieses Handbuch zeigt die Prinzipien stattdessen mit _scikit-learn_, _pandas_ und _numpy_, weil sie sich ohne Cloud-Konto auf jedem Laptop ausführen lassen. Wo sich ein Pattern nur mit einem tiefen neuronalen Netz zeigen lässt, steht das Prinzip framework-neutral im Text, mit Verweis auf die Umsetzung im Buch.

Jedes Code-Beispiel liegt als lauffähige Datei im Ordner `code/<Kapitel>/` und lässt sich mit _uv_ ohne vorbereitete Umgebung starten:

```terminal
$ cd handbuch-ml-design-patterns/code/02
$ uv run --with scikit-learn --with pandas --with numpy python 02_lineare_regression.py
```

Gezeigte Ausgaben sind die echte Ausgabe dieser Dateien. Alle Zufallsgeneratoren haben einen festen Seed; mit denselben Bibliotheksversionen erhalten Sie dieselben Zahlen, bei anderen können Nachkommastellen abweichen. Plots und Diagramme verwenden Werte aus diesen Läufen und sind in Typst selbst gezeichnet. Fachbegriffe bleiben englisch, wenn sie in der Praxis so verwendet werden, und sind beim ersten Auftreten kurz erklärt. Unsichere Aussagen sind im Text als offen markiert, statt sie zu glätten.

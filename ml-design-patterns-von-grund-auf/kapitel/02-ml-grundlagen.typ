#import "../lib.typ": *
#import "@preview/cetz-plot:0.1.2": plot

// Farben für Diagramme (siehe Brief)
#let gruen = rgb("#2EAE7D")
#let orange = rgb("#B5651D")

// Abbildungen dürfen an den Seitenrand wandern, damit keine Halbseiten entstehen; Tabellen bleiben im Text
#set figure(placement: auto)
#show figure.where(kind: table): set figure(placement: none)
#show figure.where(kind: table): set block(breakable: true)

// Kleine Helfer, damit die Plots einheitlich aussehen
#let plot-stil = (
  axis: (stroke: 0.6pt + luma(90), tick: (stroke: 0.5pt + luma(90))),
  grid: (stroke: 0.3pt + luma(225)),
)

= ML-Grundlagen für Software Engineers

Dieses Kapitel baut das Wissen auf, das Sie für die dreißig Patterns brauchen. Es setzt nur voraus, dass Sie programmieren können und Schulmathematik nicht fürchten: Geraden, Ableitungen als Steigungen, Wahrscheinlichkeiten zwischen 0 und 1. Die Leitidee passt in einen Satz: _Ein Modell ist eine Funktion, deren Konstanten nicht jemand hinschreibt, sondern die aus Beispielen bestimmt werden._ Alles andere in diesem Kapitel ist die Handwerkskunst drumherum, damit man dem Ergebnis trauen kann, und die Technik, damit man es betreiben kann.

Die Beispiele sind klein, laufen in Sekunden und liegen unter `code/02/`. Sie verwenden zwei erfundene, aber realistisch gebaute Datensätze: Mietwohnungen (Fläche, Zimmer, Baujahr, Miete) und Maschinen (Temperatur, Schwingung, Ausfall). Alle Zahlen in den Plots stammen aus diesen Läufen.

== Programm und Modell

Ein klassisches Programm entsteht, indem ein Mensch Regeln aufschreibt: Wenn die Fläche größer als 50 Quadratmeter ist, dann so viel Miete. Aus Regeln und Eingaben berechnet das Programm Antworten. Beim maschinellen Lernen (Machine Learning, ML) dreht sich die Richtung um. Man gibt dem Verfahren Eingaben _und_ die dazugehörigen richtigen Antworten, und das Verfahren findet die Regeln selbst (@abb-programm-modell). Die gefundenen Regeln sind das _Modell_.

#figure(
  diagram(
    node-stroke: 0.6pt + luma(140),
    node-corner-radius: 3pt,
    node-inset: 6pt,
    spacing: (10pt, 16pt),
    node((0, 0), [Regeln \ (von Hand)], fill: luma(240)),
    node((0, 1), [Eingaben], fill: luma(240)),
    node((1, 0.5), [*Programm*], fill: blau-hell),
    node((2, 0.5), [Antworten], fill: luma(240)),
    edge((0, 0), (1, 0.5), "-|>"), edge((0, 1), (1, 0.5), "-|>"), edge((1, 0.5), (2, 0.5), "-|>"),
    node((3.2, 0), [Eingaben], fill: luma(240)),
    node((3.2, 1), [richtige Antworten \ (Beispiele)], fill: luma(240)),
    node((4.5, 0.5), [*Training*], fill: blau, stroke: none),
    node((5.8, 0.5), [Regeln = \ *Modell*], fill: rgb("#DDF2E9"), stroke: 0.8pt + rgb("#2EAE7D")),
    edge((3.2, 0), (4.5, 0.5), "-|>"), edge((3.2, 1), (4.5, 0.5), "-|>"), edge((4.5, 0.5), (5.8, 0.5), "-|>"),
    node((2.6, -0.65), text(size: 9pt, fill: grau)[klassisch], stroke: none),
    node((4.5, -0.65), text(size: 9pt, fill: grau)[maschinelles Lernen], stroke: none),
  ),
  caption: [Klassisches Programm (links) und maschinelles Lernen (rechts). Beim Lernen entstehen die Regeln aus Beispielen; erst danach läuft das Modell wie jedes andere Stück Software.],
) <abb-programm-modell>

Zwei Phasen sind zu unterscheiden, und das Handbuch kehrt immer wieder zu ihnen zurück. In der _Trainingsphase_ entsteht das Modell aus Beispielen; sie ist rechenintensiv, läuft selten und darf Stunden dauern. In der _Vorhersagephase_ (_Inferenz_) wendet man das fertige Modell auf neue Eingaben an; sie muss schnell und zuverlässig sein, weil dort Nutzer oder andere Systeme warten. Viele Patterns lösen Probleme, die entstehen, weil beide Phasen verschiedene Anforderungen haben und doch dieselben Daten gleich verarbeiten müssen.

#kasten([Wann ML?], [Maschinelles Lernen lohnt sich, wenn die Regeln zu zahlreich oder zu unscharf sind, um sie aufzuschreiben, aber viele Beispiele vorliegen. Eine Mietpreisschätzung aus Fläche, Lage und Zustand ist ein solcher Fall; die Berechnung einer Mehrwertsteuer ist keiner, weil die Regel bekannt und exakt ist.])

== Daten: Beispiele, Features und Label

Ein _Beispiel_ (englisch _example_ oder _sample_) ist ein einzelner Fall, etwa eine Wohnung. Es wird durch seine _Features_ beschrieben, das sind die Eingabegrößen, die dem Modell zur Verfügung stehen: Fläche, Zimmerzahl, Baujahr. Beim _überwachten Lernen_ (_supervised learning_) kommt zu jedem Beispiel das _Label_ hinzu, die Größe, die das Modell vorhersagen soll: die Miete. Wer ein Modell aus Beispielen trainieren will, braucht also eine Tabelle, in der jede Zeile ein Beispiel ist, die meisten Spalten Features sind und eine Spalte das Label.

Zwei Aufgabentypen kommen ständig vor. Ist das Label eine Zahl, spricht man von _Regression_ (Miete in Euro). Ist es eine Kategorie, spricht man von _Klassifikation_ (Maschine fällt aus oder nicht). Daneben gibt es das _unüberwachte Lernen_ ohne Label, zum Beispiel Gruppen ähnlicher Kunden zu finden; es spielt für die Patterns eine Nebenrolle.

Die Tabelle entsteht in `01_daten.py`; `X` enthält die Features, `y` das Label.

```terminal
$ python 01_daten.py
   flaeche_m2  zimmer  baujahr  miete_eur
0        99.7       4     1994       1089
1        69.5       2     1956        739
2       107.3       4     1998       1163
3        92.8       3     2013       1014
4        38.5       2     2011        652

Form: (200, 4) (Zeilen = Beispiele, Spalten = Merkmale + Label)
Features X: ['flaeche_m2', 'zimmer', 'baujahr'] (200, 3)
Label y: miete_eur (200,)
```

Die Konvention `X` für die Feature-Matrix und `y` für den Label-Vektor begegnet Ihnen in fast jedem ML-Code: `X` hat eine Zeile pro Beispiel und eine Spalte pro Feature, `y` einen Eintrag pro Beispiel. Die Qualität dieser Tabelle bestimmt die Qualität des Modells oft stärker als die Wahl des Verfahrens, und viele Patterns (Hashed Feature, Embeddings, Feature Cross, Transform) betreffen den Schritt, in dem rohe Daten zu solchen Spalten werden.

== Ein Modell ist eine gelernte Funktion

Das einfachste Modell, das man sich vorstellen kann, ist eine Gerade. Für die Miete einer Wohnung aus ihrer Fläche $x$ lautet sie

$ hat(y) = w dot x + b $

Das Dach über dem $y$ bedeutet „vorhergesagt“. $w$ und $b$ sind die _Parameter_ des Modells: die Steigung (Euro pro Quadratmeter) und der Achsenabschnitt (Grundmiete). Es sind genau die Konstanten, die ein Entwickler sonst von Hand in den Code schriebe. _Training_ heißt, sie so zu bestimmen, dass die Gerade möglichst gut durch die vorhandenen Beispiele läuft. Danach ist das Modell nichts als diese Funktion mit festen Zahlen.

```python
# Ausschnitt aus 02_lineare_regression.py
X, y = df[["flaeche_m2"]], df["miete_eur"]

modell = LinearRegression().fit(X, y)   # Training: findet w und b
print(f"Steigung w = {modell.coef_[0]:.2f} Euro pro m²")
print(f"Achsenabschnitt b = {modell.intercept_:.2f} Euro")

neu = pd.DataFrame({"flaeche_m2": [75.0]})
print(f"Vorhersage für 75 m²: {modell.predict(neu)[0]:.0f} Euro")
```

```terminal
$ python 02_lineare_regression.py
Steigung w = 7.95 Euro pro m²
Achsenabschnitt b = 244.28 Euro
Vorhersage für 75 m²: 840 Euro

Drei Features: {'flaeche_m2': 8.21, 'zimmer': -5.18, 'baujahr': 1.68} b = -3100.2
```

#figure(
  canvas({
    let d = json("/code/02/out/wohnungen.json")
    plot.plot(
      size: (11, 4.6),
      x-label: [Fläche in m²], y-label: [Miete in €],
      x-min: 25, x-max: 125, y-min: 300, y-max: 1400, x-tick-step: 25, y-tick-step: 200,
      ..plot-stil,
      {
        plot.add(d.punkte, mark: "o", mark-size: 0.11, mark-style: (stroke: none, fill: blau.transparentize(55%)), style: (stroke: none))
        plot.add(domain: (30, 120), x => d.w * x + d.b, style: (stroke: 1.6pt + orange))
      },
    )
  }),
  caption: [200 Wohnungen (blaue Punkte) und die gelernte Gerade (orange). Die Parameter $w$ und $b$ stammen aus dem Lauf oben; die Streuung um die Gerade bleibt, weil Fläche allein die Miete nicht vollständig erklärt.],
) <abb-regression>

Die Gerade trifft keinen Punkt exakt, und das ist in Ordnung: Das Modell soll das Muster erfassen, nicht jeden Einzelfall. Mit mehreren Features verallgemeinert sich die Formel zu $hat(y) = w_1 x_1 + w_2 x_2 + w_3 x_3 + b$, jedes Feature bekommt sein eigenes Gewicht. Im Beispiel kommen so Fläche, Zimmerzahl und Baujahr zusammen (zweite Ausgabezeile oben). Die Daten wurden mit 8,2 € pro Quadratmeter und 1,5 € pro Baujahr erzeugt, und das Training findet für Fläche und Baujahr Werte in der Nähe. Bei der Zimmerzahl liefert es dagegen ein negatives Gewicht, obwohl sie bei der Erzeugung keine eigene Rolle spielte: Sie hängt eng an der Fläche und liefert kaum Neues, sodass das Modell ihr einen kleinen, zufälligen Wert zuteilt. Gewichte sollte man deshalb nicht ungeprüft als „Wichtigkeit“ eines Features lesen. Hier kennen wir die Wahrheit, weil wir die Daten selbst gebaut haben; bei echten Daten kennt man sie nicht, und genau deshalb braucht man die Methoden zur Überprüfung weiter unten.

Zwei Dinge sollten Sie mitnehmen. Erstens ist ein trainiertes Modell ein gewöhnliches Artefakt: eine Funktion und eine Handvoll Zahlen, die man speichern, versionieren und ausliefern kann. Große neuronale Netze funktionieren nach demselben Prinzip, nur mit Millionen oder Milliarden Parametern statt zweien. Zweitens bestimmt die _Form_ der Funktion, was das Modell ausdrücken kann: Eine Gerade bildet keine Kurve ab, so viele Daten man ihr auch gibt. Die Wahl der Funktionsform ist eine Entwurfsentscheidung, ähnlich der Wahl einer Datenstruktur.

== Loss und Gradientenabstieg

Wie findet ein Verfahren gute Werte für $w$ und $b$? Es braucht zuerst ein Maß dafür, wie schlecht ein Parameterpaar ist. Dieses Maß heißt _Loss_ (oder Kostenfunktion, _loss function_). Für Regression ist der verbreitetste der mittlere quadratische Fehler (_mean squared error_, MSE): Man bildet für jedes Beispiel die Differenz zwischen Vorhersage und Label, quadriert sie und mittelt:

$ "MSE"(w, b) = 1/n sum_(i=1)^n (w x_i + b - y_i)^2 $

Das Quadrat sorgt dafür, dass sich positive und negative Abweichungen nicht aufheben und dass große Fehler überproportional zählen. Der Loss ist eine Funktion der Parameter, nicht der Daten: Die Daten sind fest, und je nachdem, wie man $w$ und $b$ wählt, ergibt sich ein anderer Wert. Training ist damit ein Optimierungsproblem: Finde die Parameter mit dem kleinsten Loss.

Bei einer Geraden gibt es dafür eine geschlossene Formel. Bei den meisten anderen Modellen nicht, und dort kommt das Verfahren ins Spiel, das praktisch alles Training antreibt: der _Gradientenabstieg_ (_gradient descent_). Die Idee lässt sich mit einem Parameter zeigen. Stellen Sie sich den Loss als Kurve über dem Parameter $w$ vor, ein Tal. Man steht irgendwo an einem Hang, sieht nur die Steigung am eigenen Standort und macht einen Schritt bergab. Die Steigung ist die Ableitung des Loss nach $w$, der _Gradient_. Der Schritt hat die Länge Gradient mal _Lernrate_:

$ w <- w - eta dot (partial "MSE") / (partial w) $

$eta$ (eta) ist die Lernrate, eine Zahl, die der Entwickler vor dem Training festlegt. Solche Einstellungen, die nicht gelernt, sondern gewählt werden, heißen _Hyperparameter_. Man wiederholt den Schritt, bis sich der Loss kaum noch ändert.

Für das Experiment sind die Daten standardisiert (Mittelwert 0, Streuung 1); dann ist der beste Achsenabschnitt 0, und es bleibt $w$ als einzige Stellschraube. @abb-gradient zeigt links den Weg bei Lernrate 0,1 und rechts, was bei zu großer Lernrate passiert.

#figure(
  canvas({
    let g = json("/code/02/out/gradient.json")
    let pfad = g.verlaeufe.at("0.1")
    plot.plot(
      size: (5.6, 4.4),
      x-label: [Parameter $w$], y-label: [Loss],
      x-min: -1.2, x-max: 2.2, y-min: 0, y-max: 4.2, x-tick-step: 1, y-tick-step: 1,
      ..plot-stil,
      {
        plot.add(g.kurve, style: (stroke: 1.4pt + luma(120)))
        plot.add(pfad, mark: "o", mark-size: 0.13, mark-style: (fill: blau, stroke: none), style: (stroke: 1pt + blau))
        plot.annotate({
          draw.content((-1, 3.6), anchor: "west", text(size: 9pt, fill: blau)[Start])
          draw.content((g.w_opt, 0.35), anchor: "north", text(size: 9pt, fill: gruen)[Minimum])
        })
      },
    )
    draw.translate(x: 7.4)
    let steps(lr, farbe) = g.verlaeufe.at(lr).enumerate().map(((i, p)) => (i, p.at(0)))
    plot.plot(
      size: (5.6, 4.4),
      x-label: [Schritt], y-label: [Parameter $w$],
      x-min: 0, x-max: 8, y-min: -4, y-max: 5, x-tick-step: 2, y-tick-step: 1,
      ..plot-stil,
      {
        plot.add(((0, g.w_opt), (8, g.w_opt)), style: (stroke: (paint: gruen, dash: "dashed", thickness: 0.8pt)))
        plot.add(steps("0.1", blau), mark: "o", mark-size: 0.1, mark-style: (fill: blau, stroke: none), style: (stroke: 1pt + blau), label: [$eta$ = 0,1])
        plot.add(steps("0.9", orange), mark: "o", mark-size: 0.1, mark-style: (fill: orange, stroke: none), style: (stroke: 1pt + orange), label: [$eta$ = 0,9])
        plot.add(steps("1.05", luma(60)), mark: "o", mark-size: 0.1, mark-style: (fill: luma(60), stroke: none), style: (stroke: 1pt + luma(60)), label: [$eta$ = 1,05])
      },
    )
  }),
  caption: [Links: Der Loss als Kurve über dem Parameter $w$ und die ersten acht Gradientenschritte bei $eta$ = 0,1. Rechts: Der Parameter über die Schritte für drei Lernraten. Bei 0,9 pendelt $w$ um das Minimum, bei 1,05 schaukelt es sich auf und läuft davon.],
) <abb-gradient>

Die Lernrate ist die wichtigste Stellschraube. Ist sie klein, kommt man sicher, aber langsam ans Ziel: Bei 0,1 liegt $w$ nach acht Schritten bei 0,60, das Optimum bei 0,93. Ist sie zu groß, überspringt der Schritt das Tal, landet auf der anderen Seite höher und schaukelt sich auf, bis der Loss gegen unendlich geht. Bei 0,9 springt $w$ noch hin und her, nähert sich aber dem Minimum; bei 1,05 wächst der Ausschlag, und der Loss steht nach acht Schritten bei 14,7 statt bei 3,8 am Start. Für dieses Beispiel lässt sich ausrechnen, dass es oberhalb einer Lernrate von etwa 1 passiert; bei echten Modellen findet man die Grenze durch Ausprobieren, was eines der Themen von Pattern 15 (Hyperparameter Tuning) ist.

```terminal
$ python 03_gradientenabstieg.py
Analytisches Optimum: w = 0.930, Loss = 0.135
w nach Schritt 0, 1, ..., 8 bei verschiedenen Lernraten:
Lernrate 0.1 : w =  -1.00  -0.62  -0.31  -0.06   0.14   0.29   0.42   0.52   0.60
               loss nach Schritt 8: 0.241
Lernrate 0.9 : w =  -1.00   2.46  -0.28   1.88   0.17   1.53   0.46   1.30   0.63
               loss nach Schritt 8: 0.222
Lernrate 1.05: w =  -1.00   3.03  -1.36   3.43  -1.79   3.89  -2.30   4.45  -2.90
               loss nach Schritt 8: 14.738

200 Beispiele, Batch 32 -> 7 Schritte pro Epoche
Epoche 1: w = 0.502, b = 0.003, loss = 0.317
Epoche 2: w = 0.799, b = -0.016, loss = 0.152
Epoche 3: w = 0.964, b = -0.001, loss = 0.136
Epoche 4: w = 0.939, b = 0.008, loss = 0.135
Epoche 5: w = 0.923, b = 0.041, loss = 0.137
```

Bei realen Datenmengen berechnet man den Gradienten nicht über alle Beispiele auf einmal, sondern über eine zufällige Teilmenge, den _Batch_ (oder _Mini-Batch_). Das ist billiger und rauscht ein wenig, was in der Praxis eher hilft als schadet. Ein Durchlauf, in dem jedes Beispiel genau einmal in einem Batch vorkam, heißt _Epoche_. Mit 200 Beispielen und Batchgröße 32 besteht eine Epoche aus sieben Schritten (sechs volle Batches und einer mit den restlichen acht Beispielen). Der letzte Teil der Ausgabe oben zeigt den Loss über fünf Epochen: Er fällt von 0,317 auf rund 0,135 und schwankt danach leicht, weil jeder Schritt nur einen Batch sieht.

#achtung[Bei einer Geraden führt der Gradientenabstieg mit passender Lernrate zum globalen Minimum, weil der Loss eine einzige Schüssel bildet. Bei neuronalen Netzen ist die Loss-Landschaft zerklüftet, und das Verfahren findet nur irgendein gutes Tal. Zwei Läufe mit verschiedenem Zufallsstart liefern deshalb verschiedene Modelle. Dass einzelne Modelle voneinander abweichen, ist ein Grund für Pattern 7 (Ensembles).]

== Klassifikation: Wahrscheinlichkeiten statt Zahlen

Bei der Klassifikation ist das Label eine Kategorie. Der naheliegendste Ansatz ist, eine lineare Funktion zu verwenden und das Ergebnis zu einer Wahrscheinlichkeit umzuformen. Das Modell heißt trotz seines Namens _logistische Regression_ und ist ein Klassifikator. Es berechnet zuerst eine gewichtete Summe der Features, den _Logit_ $z = w_1 x_1 + w_2 x_2 + b$, und schiebt ihn durch die _Sigmoid-Funktion_

$ sigma(z) = 1 / (1 + e^(-z)) $

die jede Zahl auf das Intervall zwischen 0 und 1 abbildet (@abb-sigmoid, links). Das Ergebnis lesen wir als Wahrscheinlichkeit, dass das Beispiel zur positiven Klasse gehört, im Beispiel: dass die Maschine ausfällt. Ein _Schwellwert_ (_threshold_) macht daraus eine Entscheidung: Ab 0,5 wird die Maschine als gefährdet gemeldet. Dieser Schwellwert ist keine Eigenschaft des Modells, sondern eine Geschäftsentscheidung, die wir weiter unten bei den Metriken wieder aufgreifen.

Als Loss dient bei Klassifikation nicht der quadratische Fehler, sondern der _Log Loss_ (auch _Cross-Entropy_): Er bestraft ein Modell stark, wenn es sich mit hoher Wahrscheinlichkeit für die falsche Klasse entscheidet. Das Training läuft sonst wie oben beschrieben mit Gradientenabstieg.

#figure(
  canvas({
    let k = json("/code/02/out/klassifikation.json")
    plot.plot(
      size: (5.2, 4.4),
      x-label: [Logit $z$], y-label: [$sigma(z)$],
      x-min: -6, x-max: 6, y-min: 0, y-max: 1, x-tick-step: 2, y-tick-step: 0.25,
      ..plot-stil,
      {
        plot.add(domain: (-6, 6), x => 1 / (1 + calc.exp(-x)), style: (stroke: 1.6pt + blau))
        plot.add(((-6, 0.5), (0, 0.5)), style: (stroke: (paint: luma(150), dash: "dashed", thickness: 0.6pt)))
        plot.add(((0, 0), (0, 0.5)), style: (stroke: (paint: luma(150), dash: "dashed", thickness: 0.6pt)))
      },
    )
    draw.translate(x: 7.0)
    plot.plot(
      size: (7.4, 4.4),
      x-label: [Temperatur in °C], y-label: [Schwingung in mm/s],
      x-min: 40, x-max: 105, y-min: -1, y-max: 10, x-tick-step: 10, y-tick-step: 2,
      ..plot-stil,
      {
        let ok = k.punkte.filter(p => p.at(2) == 0).map(p => (p.at(0), p.at(1)))
        let aus = k.punkte.filter(p => p.at(2) == 1).map(p => (p.at(0), p.at(1)))
        plot.add(ok, mark: "o", mark-size: 0.09, mark-style: (stroke: none, fill: blau.transparentize(40%)), style: (stroke: none))
        plot.add(aus, mark: "x", mark-size: 0.11, mark-style: (stroke: 0.8pt + orange), style: (stroke: none))
        // Entscheidungsgrenze z = 0:  w1 t + w2 s + b = 0
        plot.add(domain: (40, 105), t => -(k.w1 * t + k.b) / k.w2, style: (stroke: 1.4pt + luma(40)))
      },
    )
  }),
  caption: [Links: Die Sigmoid-Funktion bildet jeden Logit auf eine Wahrscheinlichkeit ab; bei $z = 0$ liegt sie bei 0,5. Rechts: 300 der 1000 Maschinen (Kreise: kein Ausfall, Kreuze: Ausfall) und die gelernte Entscheidungsgrenze der logistischen Regression, an der $z = 0$ gilt.],
) <abb-sigmoid>

Der rechte Plot zeigt die Natur des Modells: Es trennt die Welt mit einer Geraden. Wo die Gerade verläuft, steht die Wahrscheinlichkeit bei 50 %; je weiter ein Punkt davon entfernt ist, desto sicherer wird das Modell. In unseren Daten tritt ein Ausfall ein, wenn die Temperatur über 80 Grad _oder_ die Schwingung über 6 mm/s liegt. Diese Region hat die Form eines „L“, und eine Gerade kann sie nur grob nachbilden. Das ist die Motivation für die nächsten beiden Abschnitte.

```python
# Ausschnitt aus 04_klassifikation.py
log = LogisticRegression().fit(X_tr, y_tr)

probe = pd.DataFrame({"temperatur_c": [78.0], "schwingung_mm_s": [5.0]})
z = log.decision_function(probe)[0]   # der Logit
p = 1 / (1 + np.exp(-z))              # Sigmoid von Hand
print(f"z = {z:.3f}, sigmoid(z) = {p:.3f}")
print("predict_proba:", log.predict_proba(probe)[0].round(3))  # dasselbe Ergebnis aus sklearn
```

```terminal
$ python 04_klassifikation.py
z = 0.161 * temperatur + 0.791 * schwingung + (-16.124)

Maschine mit 78 °C, 5 mm/s: z = 0.397, sigmoid(z) = 0.598
predict_proba: [0.402 0.598]
Schwellwert 0.5: 53 von 300 Maschinen als 'fällt aus' markiert, Genauigkeit 0.837
Schwellwert 0.3: 98 von 300 Maschinen als 'fällt aus' markiert, Genauigkeit 0.827

Drei Klassen (kein Fehler, Überhitzung, Lagerschaden)
Logits : [ 1.837  1.541 -3.378]
Softmax: [0.572 0.425 0.003] Summe = 1.0
predict_proba: [0.572 0.425 0.003]
Sigmoid je Logit: [0.863 0.824 0.033] Summe = 1.719
```

Für die Beispielmaschine mit 78 °C und 5 mm/s ergibt sich ein Logit von 0,40 und damit eine Ausfallwahrscheinlichkeit von knapp 60 %. Wie viele Maschinen das Modell meldet, hängt vom Schwellwert ab: Bei 0,5 sind es 53 von 300 (Genauigkeit 83,7 %), bei 0,3 sind es 98 (82,7 %), weil auch weniger sichere Fälle durchgehen.

=== Sigmoid und Softmax

Bei zwei Klassen genügt eine Wahrscheinlichkeit, denn die der Gegenklasse ergibt sich als Rest auf 1. Bei mehr als zwei Klassen braucht man eine Wahrscheinlichkeit pro Klasse, und die Summe soll 1 ergeben. Dafür dient die _Softmax-Funktion_: Das Modell berechnet pro Klasse einen Logit $z_k$, und

$ "softmax"(z)_k = e^(z_k) / (sum_j e^(z_j)) $

macht daraus Anteile, die sich zu 1 addieren. Die Klassen konkurrieren: Steigt die Wahrscheinlichkeit der einen, sinken die der anderen. Im Beispiel unterscheidet das Modell drei Fälle (kein Fehler, Überhitzung, Lagerschaden), und die Ausgabe oben zeigt die Logits der Beispielmaschine, die daraus berechneten Softmax-Werte und, zum Vergleich, die Werte, die man erhielte, wenn man jeden Logit einzeln durch die Sigmoid-Funktion schickte.

Der Unterschied ist für die Patterns wichtig. Mit Softmax gehört jedes Beispiel genau _einer_ Klasse an. Mit einem Sigmoid pro Klasse ist jede Entscheidung unabhängig, und ein Beispiel darf zu mehreren Klassen gehören oder zu keiner. Darauf beruht Pattern 6 (Multilabel): Ein Artikel kann zugleich „Politik“ und „Wirtschaft“ sein, und die Wahrscheinlichkeiten müssen sich nicht zu 1 summieren. Ein Foto, das Hund, Katze oder Vogel zeigt, braucht dagegen Softmax.


== Entscheidungsbäume, Random Forest und Gradient Boosting

Ein _Entscheidungsbaum_ (_decision tree_) ist die Methode, die Softwareentwicklern am vertrautesten vorkommt, denn er besteht aus verschachtelten if-Anweisungen. Das Besondere: Die Bedingungen schreibt niemand, das Training findet sie. Es probiert für jedes Feature mögliche Schwellen aus, wählt die Frage, die die Beispiele am saubersten in Gruppen mit einheitlichem Label teilt, und wiederholt das für jede Gruppe, bis eine Tiefengrenze erreicht ist oder die Gruppen rein sind. Die Blätter am Ende tragen die Vorhersage.

```terminal
$ python 05_baeume.py
|--- temperatur_c <= 79.85
|   |--- schwingung_mm_s <= 6.00
|   |   |--- class: 0
|   |--- schwingung_mm_s >  6.00
|   |   |--- class: 1
|--- temperatur_c >  79.85
|   |--- temperatur_c <= 80.90
|   |   |--- class: 1
|   |--- temperatur_c >  80.90
|   |   |--- class: 1
```

@abb-baum zeigt denselben Baum als Diagramm. Zwei Fragen genügen für eine brauchbare Vorhersage: Ist die Schwingung hoch? Ist die Temperatur hoch? Der Baum hat die „oder“-Struktur der Daten gefunden, die eine Gerade nicht ausdrücken konnte, und man kann ihn Satz für Satz erklären. Dass die zweite Frage rechts nichts an der Vorhersage ändert, ist ein typischer Zug von Bäumen: Das Training wählt die Frage nach der Reinheit der entstehenden Gruppen, nicht danach, ob sich die Vorhersage ändert. Der große Vorzug von Bäumen ist ihre Lesbarkeit, und deshalb sind sie auch dann beliebt, wenn andere Verfahren genauer wären.

#figure(
  {
    set text(size: 9pt)
    let frage(pos, t) = node(pos, align(center, t), fill: blau-hell, stroke: 0.7pt + blau, width: 3.6cm, height: 0.9cm, corner-radius: 3pt)
    let blatt(pos, t, farbe) = node(pos, align(center, t), fill: farbe, stroke: 0.7pt + luma(120), width: 2.6cm, height: 0.8cm, corner-radius: 3pt)
    let gut = rgb("#DDF2E9")
    let schlecht = rgb("#FBF1E6")
    diagram(
      spacing: (10pt, 20pt),
      frage((1.5, 0), [Temperatur \ ≤ 79,85 °C?]),
      frage((0.5, 1), [Schwingung \ ≤ 6,00 mm/s?]),
      frage((2.5, 1), [Temperatur \ ≤ 80,90 °C?]),
      blatt((0, 2), [kein Ausfall (0)], gut),
      blatt((1, 2), [Ausfall (1)], schlecht),
      blatt((2, 2), [Ausfall (1)], schlecht),
      blatt((3, 2), [Ausfall (1)], schlecht),
      edge((1.5, 0), (0.5, 1), "-|>", label: text(size: 8.5pt)[ja], label-side: left),
      edge((1.5, 0), (2.5, 1), "-|>", label: text(size: 8.5pt)[nein], label-side: right),
      edge((0.5, 1), (0, 2), "-|>", label: text(size: 8.5pt)[ja], label-side: left),
      edge((0.5, 1), (1, 2), "-|>", label: text(size: 8.5pt)[nein], label-side: right),
      edge((2.5, 1), (2, 2), "-|>", label: text(size: 8.5pt)[ja], label-side: left),
      edge((2.5, 1), (3, 2), "-|>", label: text(size: 8.5pt)[nein], label-side: right),
    )
  },
  caption: [Der Entscheidungsbaum der Tiefe 2 aus der Ausgabe oben. Die Schwellen 79,85, 6,00 und 80,90 hat das Training gefunden. Die rechte Teilung ändert die Vorhersage nicht: Beide Blätter sagen „Ausfall“.],
) <abb-baum>

Ein einzelner Baum hat eine Schwäche: Lässt man ihn tief wachsen, merkt er sich die Trainingsbeispiele (mehr dazu im Abschnitt über Generalisierung), und kleine Änderungen an den Daten ergeben einen ganz anderen Baum. Zwei Ideen beheben das, indem sie viele Bäume kombinieren.

*Random Forest* trainiert viele Bäume parallel. Jeder sieht eine zufällige Stichprobe der Beispiele und bei jeder Frage nur eine zufällige Auswahl der Features, sodass die Bäume verschieden ausfallen. Bei der Vorhersage stimmen alle ab, bei Regression wird gemittelt. Die Fehler einzelner Bäume gleichen sich dabei teilweise aus @breiman_bagging_1996 @breiman_random_forests_2001.

*Gradient Boosting* geht umgekehrt vor: Die Bäume entstehen nacheinander. Der erste macht eine grobe Vorhersage, der zweite lernt, den verbleibenden Fehler des ersten zu korrigieren, der dritte den Rest davon, und so weiter. (Genau genommen lernt jeder neue Baum die Richtung, in die sich der Loss am stärksten verringern lässt; beim quadratischen Fehler sind das gerade die Restfehler.) Die Vorhersage ist die Summe aller Bäume, jeweils mit einer kleinen Lernrate gewichtet @friedman_gradient_boosting_2001. Auch hier steckt der Gradientenabstieg dahinter, nur dass er nicht Parameter, sondern ganze Bäume hinzufügt.

#figure(
  {
    set text(size: 9pt)
    set par(justify: false)
    let baum(pos, nr, farbe: blau-hell) = node(pos, [Baum #nr], fill: farbe, stroke: 0.6pt + blau, width: 1.8cm, height: 0.7cm)
    let kasten(pos, t, farbe: luma(240), breite: 2.8cm) = node(pos, align(center, t), fill: farbe, stroke: 0.6pt + luma(140), width: breite, height: 1.0cm)
    stack(dir: ttb, spacing: 1.2em,
      align(left, text(weight: "bold")[Random Forest: Bäume parallel, am Ende Abstimmung oder Mittel]),
      diagram(
        node-corner-radius: 3pt,
        spacing: (28pt, 6pt),
        kasten((0, 0), [Trainingsdaten, \ zufällige Stichproben]),
        baum((1, -1), 1), baum((1, 0), 2), baum((1, 1), 3),
        kasten((2, 0), [Abstimmung \ oder Mittel], farbe: rgb("#DDF2E9")),
        edge((0, 0), (1, -1), "-|>"), edge((0, 0), (1, 0), "-|>"), edge((0, 0), (1, 1), "-|>"),
        edge((1, -1), (2, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((1, 1), (2, 0), "-|>"),
      ),
      v(0.4em),
      align(left, text(weight: "bold")[Gradient Boosting: Bäume nacheinander, am Ende Summe]),
      diagram(
        node-corner-radius: 3pt,
        spacing: (34pt, 10pt),
        kasten((0, 0), [Trainingsdaten], breite: 2.6cm),
        baum((1, 0), 1),
        baum((2, 0), 2, farbe: rgb("#FBF1E6")),
        baum((3, 0), 3, farbe: rgb("#FBF1E6")),
        kasten((4, 0), [Summe der \ Bäume], farbe: rgb("#DDF2E9"), breite: 2.2cm),
        edge((0, 0), (1, 0), "-|>"),
        edge((1, 0), (2, 0), "-|>", label: text(size: 8pt)[Restfehler], label-side: left),
        edge((2, 0), (3, 0), "-|>", label: text(size: 8pt)[Restfehler], label-side: left),
        edge((3, 0), (4, 0), "-|>"),
      ),
    )
  },
  caption: [Zwei Arten, Bäume zu kombinieren. Beim Random Forest entstehen die Bäume unabhängig voneinander und stimmen ab. Beim Boosting lernt jeder Baum den Fehler, den die vorherigen übrig lassen; die Vorhersage ist die gewichtete Summe aller Bäume.],
) <abb-wald>

Der zweite Teil derselben Ausgabe vergleicht alle Verfahren auf denselben 700 Trainings- und 300 Testmaschinen. Achten Sie auf den Unterschied zwischen den beiden Spalten.

```terminal
Modell                            Training    Test
Logistische Regression               0.839   0.837
Baum, Tiefe 2                        0.954   0.953
Baum, unbegrenzt                     1.000   0.923
Random Forest (200 Bäume)            1.000   0.953
Gradient Boosting (100 Bäume)        0.970   0.930

Unbegrenzter Baum: Tiefe 20 , Blätter 76
```

Die logistische Regression bleibt bei rund 84 %, weil die Datenform nicht zu ihrer Geraden passt. Der flache Baum erreicht auf den Testdaten rund 95 % und ist damit so gut wie der Random Forest. Das liegt an den Daten: Wir haben 5 % der Labels absichtlich vertauscht, sodass mehr als etwa 95 % nicht zu holen sind. Der unbegrenzte Baum zeigt, was passiert, wenn man das ignoriert: Er wächst auf Tiefe 20 mit 76 Blättern, erreicht auf den Trainingsdaten 100 % und merkt sich dabei das vertauschte Rauschen. Auf den Testdaten fällt er auf etwa 92 %, also schlechter als der Baum mit zwei Fragen. Das ist Overfitting, das der nächste Abschnitt genauer betrachtet. Random Forest dagegen hält den Testwert trotz 100 % im Training, weil die vielen Bäume sich im Mittel ausgleichen.

Für Tabellendaten, also Zeilen und Spalten wie in unseren Beispielen, sind Baum-Ensembles in der Praxis oft die erste Wahl, noch vor neuronalen Netzen; ein Vergleich auf vielen Datensätzen bestätigt das für mittelgroße Tabellen (in der Größenordnung von 10 000 Beispielen) @grinsztajn_tree_based_tabular_2022. Das erklärt, warum viele Patterns in diesem Handbuch nicht an neuronale Netze gebunden sind.

== Neuronale Netze und Embeddings

Ein _neuronales Netz_ besteht aus vielen Einheiten, die jeweils tun, was Sie bei der logistischen Regression gesehen haben: eine gewichtete Summe der Eingaben bilden und durch eine nichtlineare Funktion schicken. Eine solche Einheit heißt _Neuron_. Man ordnet viele Neuronen in _Schichten_ (_layers_) an; die Ausgaben einer Schicht sind die Eingaben der nächsten (@abb-netz). Die Zahlen an den Verbindungen, die _Gewichte_, sind die Parameter des Modells. Die nichtlineare Funktion in jedem Neuron ist wesentlich: Ohne sie wäre eine Hintereinanderschaltung von Schichten mathematisch wieder nur eine einzige lineare Funktion.

#figure(
  {
    let schichten = (2, 4, 3, 1)
    let namen = ([Eingabe \ (Features)], [verborgene \ Schicht 1], [verborgene \ Schicht 2], [Ausgabe \ (Wahrsch.)])
    diagram(
      node-shape: circle,
      node-inset: 0pt,
      spacing: (46pt, 18pt),
      ..schichten.enumerate().map(((s, n)) => range(n).map(i => {
        node((s, i - (n - 1) / 2), [], fill: if s == 0 { luma(235) } else if s == schichten.len() - 1 { rgb("#DDF2E9") } else { blau-hell }, stroke: 0.7pt + luma(110), width: 14pt, height: 14pt)
      })).flatten(),
      ..range(schichten.len() - 1).map(s => range(schichten.at(s)).map(i => range(schichten.at(s + 1)).map(j => {
        edge((s, i - (schichten.at(s) - 1) / 2), (s + 1, j - (schichten.at(s + 1) - 1) / 2), "-", stroke: 0.4pt + luma(150))
      })).flatten()).flatten(),
      ..namen.enumerate().map(((s, n)) => node((s, 2.5), text(size: 9pt, fill: grau, n), stroke: none, shape: rect)),
    )
  },
  caption: [Ein kleines neuronales Netz mit 2, 4, 3 und 1 Neuronen pro Schicht. Jede Linie ist ein Gewicht; jedes Neuron außer in der Eingabe hat zusätzlich einen Bias (das $b$ aus der Geradengleichung). Dieses Netz hat $2 dot 4 + 4 + 4 dot 3 + 3 + 3 dot 1 + 1 = 31$ Parameter.],
) <abb-netz>

Trainiert wird ein neuronales Netz wie jedes andere Modell: Loss berechnen, Gradient bestimmen, Parameter ein Stück bergab verschieben. Die Berechnung des Gradienten über alle Schichten hinweg heißt _Backpropagation_; sie wendet die Kettenregel der Differentialrechnung an und ist aus Sicht des Anwenders ein Implementierungsdetail der Bibliothek (Kapitel 3 rechnet sie an einem kleinen Netz von Hand nach). Das Wort _tief_ in _Deep Learning_ bezeichnet einfach viele Schichten. Der Gewinn liegt darin, dass die Schichten nacheinander immer abstraktere Zwischen-Features bilden, die niemand von Hand entwerfen muss: bei Bildern etwa Kanten, dann Formen, dann Objektteile. Das ist der Grund, warum neuronale Netze bei Bildern, Text und Ton so viel leisten, wo Features sich schlecht von Hand angeben lassen.

```terminal
$ python 06_neuronale_netze.py
Genauigkeit Test: 0.937
Schicht 1: Gewichte (2, 16), Bias (16,)
Schicht 2: Gewichte (16, 8), Bias (8,)
Schicht 3: Gewichte (8, 1), Bias (1,)
Parameter insgesamt: 193
```

Das Netz erreicht auf den Testdaten rund 94 %, mit 193 Parametern, während der Baum der Tiefe 2 mit drei gelernten Schwellen auf 95 % kommt. Für kleine Tabellen ist ein neuronales Netz selten die richtige Wahl. Seine Stärke beginnt dort, wo Eingaben roh und hochdimensional sind, etwa Pixel oder Text.

=== Embeddings

Neuronale Netze rechnen mit Zahlen. Wie füttert man ein Netz mit einem Wort, einer Produkt-ID oder einem Nutzer? Die naive Antwort ist die _One-hot-Kodierung_: ein Vektor mit so vielen Einträgen wie Kategorien, in dem genau eine Stelle 1 ist und alle anderen 0 sind. Bei 50 000 Produkten sind das 50 000 Dimensionen, fast nur Nullen, und das Modell erfährt nicht, dass zwei Produkte einander ähnlicher sind als zwei andere.

Ein _Embedding_ ersetzt diesen Vektor durch einen kurzen, dichten, etwa 8 bis 300 Einträge langen. Technisch ist es eine Tabelle $E$ mit einer Zeile pro Kategorie; die Eingabe wählt nur eine Zeile aus. Das ist dasselbe wie One-hot-Vektor mal Matrix, nur ohne die vielen Multiplikationen mit Null. Die Einträge der Tabelle sind Parameter, die das Training mitlernt (im Beispiel unten sind sie zur Veranschaulichung zufällig gefüllt, nur der Nachschlagemechanismus ist echt), und dabei wandern Kategorien, die sich im Modell ähnlich verhalten, im Vektorraum nahe beieinander. Bekannt wurde das Prinzip durch word2vec für Wörter @mikolov_word2vec_2013. Wie die Tabelle beim Training Zeile für Zeile gelernt wird, zeigt Kapitel 3.

```terminal
Embedding-Tabelle E (eine Zeile pro Wort):
  drucker   [0.35 0.82 0.33]
  scanner   [-1.3   0.91  0.45]
  passwort  [-0.54  0.58  0.36]
  login     [0.29 0.03 0.55]
  vpn       [-0.74 -0.16 -0.48]
One-hot für 'passwort': [0. 0. 1. 0. 0.]
one_hot @ E            : [-0.54  0.58  0.36]
E[idx]                 : [-0.54  0.58  0.36]
```

#figure(
  {
    set text(size: 9pt)
    let wort = ("drucker", "scanner", "passwort", "login", "vpn")
    let e = ((0.35, 0.82, 0.33), (-1.3, 0.91, 0.45), (-0.54, 0.58, 0.36), (0.29, 0.03, 0.55), (-0.74, -0.16, -0.48))
    let treffer = 2
    let zahl(x) = str(x).replace(".", ",").replace("-", "−")
    grid(
      columns: (auto, auto, auto, auto, auto),
      column-gutter: 14pt, align: horizon,
      // One-hot
      table(
        columns: 1, fill: none, stroke: 0.5pt + luma(150), inset: 5pt, align: center,
        table.header(text(size: 8.5pt, weight: "bold")[One-hot]),
        ..range(5).map(i => if i == treffer { table.cell(fill: blau)[#text(fill: white)[1]] } else { [0] }),
      ),
      text(size: 14pt)[×],
      table(
        columns: (auto, auto, auto, auto), fill: none, stroke: 0.5pt + luma(150), inset: 5pt, align: (left, center, center, center),
        table.header(text(size: 8.5pt, weight: "bold")[Wort], [d1], [d2], [d3]),
        ..range(5).map(i => (
          if i == treffer { table.cell(fill: blau-hell)[#wort.at(i)] } else { wort.at(i) },
          ..e.at(i).map(x => if i == treffer { table.cell(fill: blau-hell)[#zahl(x)] } else { zahl(x) }),
        )).flatten(),
      ),
      text(size: 14pt)[=],
      table(
        columns: 3, fill: none, stroke: 0.5pt + luma(150), inset: 5pt, align: center,
        table.header(table.cell(colspan: 3)[#text(size: 8.5pt, weight: "bold")[Vektor für „passwort“]]),
        ..e.at(treffer).map(x => table.cell(fill: rgb("#DDF2E9"))[#zahl(x)]),
      ),
    )
  },
  kind: image,
  caption: [Ein Embedding als Nachschlagetabelle: Der One-hot-Vektor wählt aus der Tabelle $E$ genau eine Zeile. Die Werte stammen aus der Ausgabe oben; in einem echten Modell wären sie nicht zufällig, sondern gelernt.],
) <abb-embedding>

Ein kleines Experiment mit einer echten, wenn auch anderen Technik zeigt das Prinzip „Nähe aus Nutzung“. Aus zwölf kurzen Support-Tickets bilden wir mit einer Matrixzerlegung (_Latent Semantic Analysis_) für jedes Wort einen dreidimensionalen Vektor und messen den Kosinus des Winkels zwischen zwei Vektoren: nahe +1 heißt gleiche Richtung, nahe 0 heißt unabhängig. Das ist nicht das Verfahren, mit dem neuronale Netze Embeddings lernen, aber es zeigt dasselbe Ergebnis: Wörter, die in denselben Zusammenhängen vorkommen (drucker und scanner, passwort und login), bekommen ähnliche Vektoren; Wörter aus verschiedenen Themen liegen nahe bei null.

```terminal
Ähnlichkeit(drucker, scanner) = +0.93
Ähnlichkeit(passwort, login) = +0.99
Ähnlichkeit(drucker, passwort) = +0.18
Ähnlichkeit(vpn, drucker) = -0.14
```

Die Vektoren aus dem Embedding sind keine Handarbeit, sondern ein Produkt der Daten. Die Patterns 2 (Embeddings), 4 (Multimodal Input) und 13 (Transfer Learning) bauen darauf auf.

== Generalisierung: Overfitting, Splits und Datenlecks

Das Ziel eines Modells ist nicht, die Trainingsbeispiele zu reproduzieren, sondern bei Beispielen zu funktionieren, die es nie gesehen hat. Diese Fähigkeit heißt _Generalisierung_. Ein Modell kann auf zwei Arten daran scheitern.

_Underfitting_ liegt vor, wenn das Modell zu einfach ist, um das Muster abzubilden, etwa eine Gerade für einen Verlauf mit Kurve. _Overfitting_ liegt vor, wenn das Modell so flexibel ist, dass es auch das Rauschen der Trainingsdaten nachbildet: Es hat die Beispiele auswendig gelernt statt des Zusammenhangs. Aus Entwicklersicht ist das verwandt mit einem Programm, das die erwarteten Werte der Testfälle hart kodiert.

@abb-overfitting zeigt das an einem Experiment, bei dem wir die Wahrheit kennen: eine Sinuskurve mit Rauschen, 15 gleichmäßig verteilte Trainingspunkte, Polynome mit steigendem Grad. Der Grad bestimmt die Flexibilität des Modells.

#figure(
  canvas({
    let o = json("/code/02/out/overfitting.json")
    let wahr = o.raster.zip(o.wahrheit)
    let panel(grad, titel) = {
      plot.plot(
        size: (2.9, 3.6),
        x-label: none, y-label: none,
        x-min: 0, x-max: 1, y-min: -1.8, y-max: 1.8, x-tick-step: 0.5, y-tick-step: 1,
        ..plot-stil,
        {
          plot.add(wahr, style: (stroke: (paint: gruen, dash: "dashed", thickness: 0.9pt)))
          plot.add(o.train, mark: "o", mark-size: 0.12, mark-style: (fill: blau, stroke: none), style: (stroke: none))
          plot.add(o.raster.zip(o.kurven.at(grad)), style: (stroke: 1.5pt + orange))
          plot.annotate(draw.content((0.5, 1.55), text(size: 9pt, titel)))
        },
      )
    }
    panel("1", [Grad 1])
    draw.translate(x: 4.1)
    panel("3", [Grad 3])
    draw.translate(x: 4.1)
    panel("14", [Grad 14])
    draw.translate(x: 4.3)
    plot.plot(
      size: (2.9, 3.6),
      x-label: [Grad], y-label: none,
      x-min: 1, x-max: 14, y-min: 0, y-max: 1.6, x-tick-step: 4, y-tick-step: 0.4,
      ..plot-stil,
      {
        plot.add(o.fehler.map(r => (r.at(0), r.at(1))), style: (stroke: 1.3pt + blau))
        plot.add(o.fehler.map(r => (r.at(0), calc.min(r.at(2), 1.6))), style: (stroke: 1.3pt + orange))
      },
    )
  }),
  caption: [Links drei Modelle für dieselben 15 Trainingspunkte (blau); gestrichelt grün die wahre Funktion, orange das gelernte Modell (Grad 14 ist am Plotrand abgeschnitten). Rechts der RMSE auf Trainings- (blau) und Testdaten (orange) über dem Polynomgrad; der Testfehler ist bei 1,6 abgeschnitten. Grad 1 unteranpasst, Grad 3 trifft das Muster, Grad 14 läuft durch jeden Punkt und schwingt dazwischen wild.],
) <abb-overfitting>

Die Zahlen dahinter machen die Beobachtung messbar. Wir berechnen den Fehler (RMSE, siehe unten) einmal auf den Trainingsdaten und einmal auf 500 weiteren Punkten, die das Modell nie gesehen hat.

```terminal
$ python 07_overfitting.py
Grad  RMSE Training  RMSE Test
   1          0.452      0.525
   2          0.452      0.525
   3          0.312      0.315
   4          0.308      0.319
   6          0.265      0.329
   8          0.211      0.348
  10          0.160      0.451
  12          0.159      0.413
  13          0.142      1.516
  14          0.000     12.149
```

Der Trainingsfehler fällt mit steigendem Grad immer weiter und erreicht bei Grad 14 den Wert null, denn 15 Punkte lassen sich mit einem Polynom vom Grad 14 genau treffen. Der Testfehler dagegen fällt zuerst, liegt zwischen Grad 3 und 8 bei 0,32 bis 0,35 und steigt dann: leicht ab Grad 10, dramatisch bei Grad 13 und 14 (auf 12,1; rechtes Diagramm in @abb-overfitting). Würde man nur den Trainingsfehler beachten, wählte man den schlechtesten Grad. Dass gerade Grade wie 2 und 4 kaum etwas ändern, liegt an der Sinuskurve, die zum Mittelpunkt hin punktsymmetrisch ist und deshalb fast nur ungerade Terme braucht.

=== Train, Validation, Test

Daraus folgt eine Grundregel: Ein Modell darf nie mit denselben Daten bewertet werden, mit denen es trainiert wurde. Man teilt die Daten deshalb in drei Teile (@abb-split):

- Die *Trainingsmenge* (_training set_) dient dazu, die Parameter zu lernen.
- Die *Validierungsmenge* (_validation set_) dient dazu, Entscheidungen des Entwicklers zu prüfen: welches Verfahren, welche Hyperparameter, welcher Polynomgrad. Man darf sie oft benutzen, doch jede Entscheidung, die man nach ihrem Ergebnis trifft, passt das Modell ein Stück an sie an.
- Die *Testmenge* (_test set_) wird ganz zum Schluss genau einmal benutzt, um die Qualität ehrlich zu schätzen. Sobald man nach ihrem Ergebnis noch Entscheidungen trifft, ist sie keine Testmenge mehr, sondern eine zweite Validierungsmenge.

#figure(
  {
    set text(size: 9.5pt)
    let teil(w, farbe, t) = box(width: w, height: 1.0cm, fill: farbe, stroke: 0.6pt + luma(120), align(center + horizon, t))
    let breite = 15.4cm
    stack(
      dir: ttb, spacing: 0.6em,
      stack(dir: ltr,
        teil(breite * 0.6, blau-hell, [*Training* (60 %)]),
        teil(breite * 0.2, rgb("#FBF1E6"), [*Validierung* \ (20 %)]),
        teil(breite * 0.2, rgb("#DDF2E9"), [*Test* (20 %)]),
      ),
      text(fill: grau, size: 9pt)[Kreuzvalidierung mit $k = 5$ (die Testmenge bleibt außen vor):],
      ..range(5).map(i => stack(dir: ltr,
        ..range(5).map(j => box(width: breite * 0.8 / 5, height: 0.42cm, fill: if i == j { rgb("#FBF1E6") } else { blau-hell }, stroke: 0.5pt + luma(140), align(center + horizon, text(size: 8pt, if i == j { [Validierung] } else { [Training] })))),
        box(width: breite * 0.2, height: 0.42cm, fill: rgb("#DDF2E9"), stroke: 0.5pt + luma(140), align(center + horizon, text(size: 8pt)[Test])),
      )),
    )
  },
  caption: [Aufteilung der Daten. Oben die feste Dreiteilung, darunter die fünf Durchläufe der Kreuzvalidierung: In jedem Durchlauf ist ein anderes Fünftel der Entwicklungsdaten die Validierungsmenge.],
) <abb-split>

Eine Aufteilung in 60 % Training, 20 % Validierung und 20 % Test ist verbreitet, aber keine Regel. Bei wenigen Daten ist eine feste Validierungsmenge unökonomisch und stark vom Zufall abhängig. Dann nimmt man die _Kreuzvalidierung_ (_cross-validation_): Man teilt die Daten in $k$ Teile (_folds_), trainiert $k$-mal auf $k - 1$ Teilen, bewertet jeweils auf dem übrigen und mittelt die $k$ Ergebnisse. Die Streuung der Einzelergebnisse zeigt gleich, wie verlässlich die Schätzung ist.

```terminal
$ python 08_split_und_leck.py
Training/Validierung/Test: 600 200 200
max_depth= 1: Validierung 0.895
max_depth= 2: Validierung 0.970
max_depth= 3: Validierung 0.970
max_depth= 5: Validierung 0.970
max_depth=10: Validierung 0.955

5-fache Kreuzvalidierung: [0.944 0.931 0.962 0.962 0.962]
Mittel 0.953, Streuung 0.013

Zufallsdaten, Auswahl vor dem Split  : 0.84 Genauigkeit im Mittel (Leck)
Zufallsdaten, Auswahl in der Pipeline: 0.51 Genauigkeit im Mittel (ehrlich)
```

=== Datenlecks

Die gefährlichste Fehlerquelle bei der Bewertung ist das _Datenleck_ (_data leakage_): Information, die zum Zeitpunkt der Vorhersage nicht verfügbar wäre, gelangt in das Training oder in die Bewertung @kaufman_leakage_2012. Das Ergebnis sieht großartig aus und bricht im Betrieb ein. Typische Formen sind:

- Ein Feature enthält das Label indirekt, zum Beispiel ein Feld „Rückerstattung veranlasst“ bei der Betrugserkennung, das erst nach der Betrugsprüfung gesetzt wird.
- Eine Vorverarbeitung (Skalierung, Auswahl von Features, Auffüllen fehlender Werte) wird auf allen Daten gelernt, bevor man in Training und Test teilt.
- Dasselbe Beispiel oder sehr ähnliche Beispiele (derselbe Kunde, dieselbe Maschine, Duplikate) stehen sowohl im Training als auch im Test.
- Bei Zeitreihen kommen Beobachtungen aus der Zukunft in das Training, wenn man zufällig statt zeitlich teilt.

Das Experiment am Ende der Ausgabe oben macht die zweite Form sichtbar. Wir erzeugen jeweils 100 Beispiele mit 2000 Features, die reiner Zufall sind, und zufällige Labels. Es gibt nichts zu lernen, ehrlich wären rund 50 % Genauigkeit. Dieses Experiment ist ein Klassiker der Statistik @hastie_elements_statistical_learning_2009[Abschn. 7.10.2]. Wählt man jedoch die 20 „besten“ Features auf _allen_ Daten aus und führt danach erst die Kreuzvalidierung durch, sieht das Modell durch die Auswahl schon die Labels der Validierungsfolds. Im Mittel über zehn solche Zufallsdatensätze erreicht es dann 84 % Genauigkeit, obwohl nichts zu lernen ist. Liegt die Auswahl dagegen in einer Pipeline, die sie pro Fold nur auf dem Trainingsteil lernt, fällt die Genauigkeit mit 51 % auf Zufallsniveau.

#achtung[Datenlecks fallen nicht durch Fehlermeldungen auf, sondern durch Zahlen, die zu gut sind. Wenn ein Modell in der Entwicklung 99 % erreicht und im Betrieb 70 %, ist ein Leck der erste Verdacht. Mehrere Patterns (etwa Transform und Repeatable Splitting) schützen davor, indem sie festlegen, _wo_ und _wann_ etwas gelernt wird.]

== Metriken: Wie gut ist gut?

Wie misst man, ob ein Klassifikator gut ist? Die erste Antwort ist die _Accuracy_, der Anteil richtiger Vorhersagen. Sie ist leicht zu erklären und bei ausgeglichenen Klassen brauchbar. Bei Ungleichgewicht trügt sie, und das ist der Normalfall: Betrug, Defekte und Ausfälle sind selten. Ein Modell, das immer „kein Betrug“ sagt, hat bei 1 % Betrugsanteil 99 % Accuracy und ist völlig nutzlos.

Genauer sieht man in der _Konfusionsmatrix_ (_confusion matrix_), die zählt, wie oft jede Kombination aus wahrer und vorhergesagter Klasse auftrat (@abb-konfusion). Die positive Klasse ist die, nach der man sucht (Betrug). Die vier Felder heißen True Positive (TP, Betrug erkannt), False Positive (FP, falscher Alarm), False Negative (FN, Betrug übersehen) und True Negative (TN, zu Recht ignoriert).

#figure(
  {
    set text(size: 9.5pt)
    let matrix(titel, tn, fp, fn, tp) = {
      let zelle(t, zahl, farbe) = table.cell(fill: farbe)[#text(size: 8pt, fill: luma(80))[#t] \ #text(size: 12pt, weight: "bold")[#zahl]]
      let gut = rgb("#DDF2E9")
      let schlecht = rgb("#FBF1E6")
      align(center)[
        #text(weight: "bold")[#titel] \
        #v(0.2em)
        #table(
          columns: (auto, 2.6cm, 2.6cm), rows: (auto, 1.35cm, 1.35cm), fill: none, stroke: 0.5pt + luma(150), inset: 5pt, align: center + horizon,
          [], text(size: 8.5pt)[vorhergesagt: \ kein Betrug], text(size: 8.5pt)[vorhergesagt: \ Betrug],
          text(size: 8.5pt)[wahr: \ kein Betrug], zelle([TN], tn, gut), zelle([FP], fp, schlecht),
          text(size: 8.5pt)[wahr: \ Betrug], zelle([FN], fn, schlecht), zelle([TP], tp, gut),
        )
      ]
    }
    grid(
      columns: (1fr, 1fr), align: top,
      matrix([Schwelle 0,5], 4950, 0, 45, 5),
      matrix([Schwelle 0,1], 4940, 10, 36, 14),
    )
  },
  kind: image,
  caption: [Konfusionsmatrizen desselben Modells bei zwei Schwellwerten (Testdaten: 5000 Transaktionen, 50 Betrugsfälle). Grün sind richtige, orange falsche Vorhersagen. Die Zahlen stammen aus der Ausgabe unten.],
) <abb-konfusion>

Aus den vier Zahlen ergeben sich die gebräuchlichen Metriken:

- *Precision* $= "TP" / ("TP" + "FP")$: Von allen Alarmen, wie viele waren echt? Hoch, wenn das Modell selten falschen Alarm schlägt.
- *Recall* $= "TP" / ("TP" + "FN")$: Von allen echten Fällen, wie viele wurden gefunden? Hoch, wenn das Modell kaum etwas übersieht.
- *F1* ist das harmonische Mittel von Precision und Recall. Es ist nur dann hoch, wenn beide hoch sind.

Precision und Recall stehen in einem Konflikt, den der Schwellwert steuert. Senkt man ihn, schlägt das Modell häufiger an: Der Recall steigt, die Precision sinkt. Was richtig ist, entscheidet die Fachlichkeit, nicht die Statistik: Bei einer Krebsvorsorge nimmt man falschen Alarm in Kauf, um nichts zu übersehen; bei einer automatischen Kontosperrung ist ein falscher Alarm teuer.

Das folgende Experiment verwendet 20 000 Transaktionen mit rund 1 % Betrug.

```terminal
$ python 09_metriken.py
Betrugsanteil im Test: 0.010 (50 von 5000)

'Immer kein Betrug': Accuracy 0.9900, Recall 0.00

Schwelle 0.5: TN=4950 FP=0 FN=45 TP=5
  Accuracy 0.9910  Precision 1.00  Recall 0.10  F1 0.18

Schwelle 0.1: TN=4940 FP=10 FN=36 TP=14
  Accuracy 0.9908  Precision 0.58  Recall 0.28  F1 0.38

ROC-AUC (schwellenunabhängig): 0.688

Miete: MAE 50.3 Euro, RMSE 64.6 Euro
Mit einem Ausreißer von +1000 Euro: MAE 68.5, RMSE 149.6
```

Der Dummy, der nie Betrug meldet, erreicht 99,0 % Accuracy bei einem Recall von null. Das trainierte Modell erreicht bei Schwelle 0,5 mit 99,1 % kaum mehr, obwohl es immerhin 5 der 50 Betrugsfälle findet und dabei keinen falschen Alarm schlägt (Precision 1,00, Recall 0,10). Wer nur auf die Accuracy sieht, erkennt den Unterschied zwischen einem nutzlosen und einem etwas nützlichen Modell nicht. Bei der Schwelle 0,1 sinkt die Accuracy minimal, während der Recall von 0,10 auf 0,28 steigt; dafür fallen zehn falsche Alarme an (Precision 0,58). Ob das ein guter Tausch ist, hängt davon ab, was ein falscher Alarm und was ein übersehener Betrug kosten.

=== ROC-AUC

Um ein Modell unabhängig vom Schwellwert zu beurteilen, trägt man für alle möglichen Schwellwerte die Rate der gefundenen echten Fälle (Recall, hier _True-Positive-Rate_) gegen die Rate der falschen Alarme (_False-Positive-Rate_, $"FP" / ("FP" + "TN")$) auf. Die entstehende _ROC-Kurve_ (_receiver operating characteristic_) verläuft bei einem Zufallsmodell auf der Diagonalen und bei einem perfekten Modell oben links. Die Fläche darunter, die _AUC_ (_area under the curve_), fasst die Kurve in einer Zahl zusammen. Anschaulich ist sie die Wahrscheinlichkeit, dass das Modell einem zufällig gewählten positiven Beispiel eine höhere Wahrscheinlichkeit gibt als einem zufällig gewählten negativen. 0,5 entspricht Raten, 1,0 einer perfekten Trennung.

#figure(
  canvas({
    let r = json("/code/02/out/roc.json")
    plot.plot(
      size: (5, 4.4),
      x-label: [False-Positive-Rate], y-label: [True-Positive-Rate (Recall)],
      x-min: 0, x-max: 1, y-min: 0, y-max: 1, x-tick-step: 0.25, y-tick-step: 0.25,
      legend: "inner-south-east",
      ..plot-stil,
      {
        plot.add(((0, 0), (1, 1)), style: (stroke: (paint: luma(140), dash: "dashed", thickness: 0.8pt)), label: [Zufall])
        plot.add(r.punkte, style: (stroke: 1.6pt + blau), label: [Modell])
      },
    )
  }),
  caption: [ROC-Kurve des Betrugsmodells auf den Testdaten. Je weiter die Kurve nach oben links wölbt, desto besser trennt das Modell. Die AUC steht in der Ausgabe oben (0,69): besser als Raten, aber weit von einer sauberen Trennung entfernt.],
) <abb-roc>

Bei sehr seltenen positiven Fällen kann die ROC-Kurve zu optimistisch wirken, weil die vielen negativen Beispiele die False-Positive-Rate klein halten. Dann ist die Precision-Recall-Kurve aussagekräftiger @saito_precision_recall_2015.

=== MAE und RMSE

Bei Regression misst man den Abstand zwischen Vorhersage und Wahrheit. Der _mittlere absolute Fehler_ (MAE) mittelt die Beträge der Abweichungen und ist in der Einheit des Labels lesbar: „Im Mittel liegen wir 50 Euro daneben.“ Der _RMSE_ (Wurzel des mittleren quadratischen Fehlers) quadriert vor dem Mitteln und zieht danach die Wurzel; er bestraft große Ausreißer stärker. Liegen beide weit auseinander, gibt es vereinzelt sehr grobe Fehler. Die letzten Zeilen der Ausgabe zeigen das: Ein einziger Ausreißer von 1000 Euro hebt den MAE von 50 auf 69 Euro, den RMSE aber von 65 auf 150 Euro, also auf mehr als das Doppelte.

== Der ML-Lebenszyklus

Ein Modell zu trainieren ist ein kleiner Teil der Arbeit. Sculley et al. zeigten bereits 2015, dass der eigentliche ML-Code in einem produktiven System nur ein kleiner Kasten inmitten von Datenbeschaffung, Konfiguration, Werkzeugen, Überwachung und Serving-Infrastruktur ist @sculley_hidden_debt_2015. Der Lebenszyklus in @abb-lebenszyklus fasst diese Arbeit in Stufen und ordnet ihnen die Rollen zu, die sie in der Praxis meist ausfüllen. Die Rollenbezeichnungen variieren zwischen Organisationen; hier zählt, dass verschiedene Menschen mit verschiedenen Werkzeugen beteiligt sind.

#figure(
  {
    set text(size: 8.5pt)
    set par(justify: false)
    let stufe(pos, titel, t) = node(pos, align(center)[*#titel* \ #t], fill: blau-hell, stroke: 0.7pt + blau, width: 2.55cm, height: 1.25cm, inset: 3pt)
    let rolle(pos, r, farbe) = node(pos, align(center, r), fill: farbe, stroke: none, width: 2.55cm, height: 0.95cm, inset: 3pt)
    diagram(
      node-corner-radius: 3pt,
      spacing: (7pt, 12pt),
      stufe((0, 0), [Daten], [sammeln, bereinigen, labeln]),
      stufe((1, 0), [Features], [Rohdaten in Zahlenspalten]),
      stufe((2, 0), [Training], [Parameter lernen]),
      stufe((3, 0), [Evaluation], [Metriken auf neuen Daten]),
      stufe((4, 0), [Deployment], [als Dienst bereitstellen]),
      stufe((5, 0), [Monitoring], [Qualität und Daten beobachten]),
      edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"), edge((3, 0), (4, 0), "-|>"), edge((4, 0), (5, 0), "-|>"),
      edge((5, 0), (5, -0.9), (0, -0.9), (0, 0), "--|>", stroke: 0.8pt + orange, label: text(fill: orange)[neue Daten, Drift, neue Anforderungen], label-side: right, label-pos: 0.5),
      rolle((0, 1.3), [Data Engineer], luma(238)),
      rolle((1, 1.3), [Data Scientist], blau-hell),
      rolle((2, 1.3), [Data Scientist \ ML Engineer], blau-hell),
      rolle((3, 1.3), [Data Scientist \ Fachbereich], blau-hell),
      rolle((4, 1.3), [ML Engineer \ Software Engineer], rgb("#DDF2E9")),
      rolle((5, 1.3), [ML Engineer \ Betrieb], rgb("#DDF2E9")),
    )
  },
  caption: [Der ML-Lebenszyklus mit typischen Rollen. Der gestrichelte Pfeil ist der Kreislauf: Beobachtungen aus dem Betrieb führen zu neuen Daten und einem neuen Training.],
) <abb-lebenszyklus>

*Daten.* Transaktionssysteme, Sensoren, Logs oder manuelle Erfassung liefern die Rohdaten, die gesammelt, bereinigt und beim überwachten Lernen mit Labels versehen werden. Die Labels sind oft die teuerste Zutat. *Features.* Aus Rohdaten entstehen die Zahlenspalten, die das Modell verarbeiten kann: Kategorien kodieren, Werte skalieren, Zeitfenster aggregieren. In dieser Stufe steckt ein großer Teil der Arbeit, und viele Patterns aus den Teilen II und IV beziehen sich darauf. *Training.* Das Modell lernt die Parameter, der Entwickler wählt die Hyperparameter; der Lauf ist rechenintensiv und kann Stunden dauern. *Evaluation.* Das Modell wird auf Daten bewertet, die es nicht gesehen hat, mit Metriken, die zur Fachlichkeit passen. Hier entscheidet sich, ob es in Betrieb gehen darf, und der Fachbereich sollte mitreden, was „gut genug“ heißt. *Deployment.* Das Modell wird als Dienst oder Batch-Job bereitgestellt und ist damit Software im Betrieb mit den üblichen Anforderungen: Latenz, Verfügbarkeit, Versionierung. *Monitoring.* Im Betrieb kann die Qualität sinken, ohne dass sich eine Zeile Code ändert; die Beobachtung führt zurück zu den Daten.

Die Stufen sind weder strikt sequenziell noch einmalig: Man kehrt von der Evaluation zu den Features zurück, und im Betrieb läuft der ganze Kreis wiederholt. Kapitel 4 verteilt die dreißig Patterns auf diese Stufen.

== Begriffe für den Betrieb

Vier Begriffsgruppen tauchen in den Patterns ständig auf. Sie sind schnell erklärt, aber leicht zu verwechseln.

*Inferenz und Serving.* _Inferenz_ (_inference_) heißt, mit einem trainierten Modell Vorhersagen zu berechnen. _Serving_ bezeichnet die Infrastruktur, die das anbietet. Es gibt _Online-Serving_, bei dem einzelne Anfragen innerhalb von Millisekunden beantwortet werden, und _Batch-Serving_, bei dem man viele Eingaben auf einmal verarbeitet.

*Parameter und Hyperparameter.* _Parameter_ lernt das Training (Gewichte, Schwellen in einem Baum). _Hyperparameter_ legt der Entwickler vorher fest (Lernrate, Baumtiefe, Anzahl der Schichten, Batchgröße). Hyperparameter werden an der Validierungsmenge ausgewählt, nie an der Testmenge.

*Training-Serving Skew.* Berechnen Training und Serving die Features unterschiedlich, sieht das Modell im Betrieb Daten, an die es nie gewöhnt wurde. Der Fehler entsteht meist durch zwei Implementierungen derselben Logik, eine im Trainingsskript und eine im Dienst. Er fällt nicht auf, weil nichts abstürzt, es werden nur die Vorhersagen schlechter.

*Data Drift und Concept Drift.* Im Betrieb ändert sich die Welt. Verschiebt sich die Verteilung der _Eingaben_ (im Sommer sind alle Maschinen wärmer), spricht man von _Data Drift_ oder Covariate Shift. Ändert sich der _Zusammenhang_ zwischen Eingaben und Label (nach einer neuen Wartungsstrategie fallen Maschinen schon bei niedrigerer Temperatur aus), spricht man von _Concept Drift_ @gama_concept_drift_2014. Data Drift bleibt folgenlos, solange die Regel dahinter weiter gilt und das Modell in den neuen Wertebereichen zuverlässig arbeitet; Concept Drift trifft das Modell dagegen direkt, weil die Regel, die es gelernt hat, nicht mehr stimmt.

Die folgenden Experimente machen die Begriffe greifbar.

```terminal
$ python 10_skew_und_drift.py
Hyperparameter (vorher gewählt): max_depth = 2
Parameter (gelernt): Schwellen = [79.85  6.   80.9 ]

Offline-Genauigkeit (Celsius)      : 0.827
Serving mit Fahrenheit-Werten      : 0.280
Anteil echter Ausfälle im Test     : 0.280

Data Drift: Temperatur Training Mittel 69.3, Sommer 82.2, KS-Statistik 0.50, p = 6.1e-95
Genauigkeit im Sommer, Regel unverändert: 0.943

Concept Drift (Schwelle jetzt 75 °C): Genauigkeit 0.837 statt 0.947
```

Der erste Teil trennt die gelernten Schwellen des Baums (Parameter) von seinem Hyperparameter `max_depth`. Im zweiten Teil wird eine Pipeline aus Skalierung und logistischer Regression in Celsius trainiert, im Betrieb aber mit Fahrenheit-Werten bei unverändertem Spaltennamen gefüttert. Nichts stürzt ab, die Genauigkeit fällt jedoch von 82,7 % auf 28,0 %. Das ist exakt der Anteil echter Ausfälle: Alle Temperaturen liegen jetzt weit jenseits der Entscheidungsgrenze, und das Modell meldet für jede Maschine einen Ausfall. Im dritten Teil verschiebt der Sommer die Temperaturverteilung (Mittel 82 statt 69 °C). Der Kolmogorov-Smirnov-Test, der zwei Stichproben auf gleiche Verteilung prüft, erkennt die Verschiebung eindeutig (Statistik 0,50). Die Regel dahinter gilt aber unverändert, und ein Baum der Tiefe 3 bleibt mit 94,3 % so gut wie vorher (94,7 % auf den ursprünglichen Testdaten). Im vierten Teil ändert sich die Regel selbst: Ausfälle beginnen schon bei 75 °C. Die Eingaben sehen aus wie zuvor, die Genauigkeit desselben Baums fällt auf 83,7 %, und nur ein Vergleich mit den tatsächlichen Ausfällen zeigt das.

#figure(
  {
    set text(size: 9pt)
    set par(justify: false)
    let b(pos, t, farbe: luma(240), s: luma(140), breite: 3.4cm) = node(pos, align(center, t), fill: farbe, stroke: 0.7pt + s, width: breite, height: 1.25cm)
    stack(dir: ttb, spacing: 1.4em,
      align(left, text(weight: "bold")[Mit Skew: zwei Implementierungen derselben Vorverarbeitung]),
      diagram(
        node-corner-radius: 3pt,
        spacing: (44pt, 14pt),
        b((0, 0), [Training: \ Rohdaten in °C]),
        b((1, 0), [Vorverarbeitung A \ (Trainingsskript)], farbe: blau-hell, s: blau),
        b((2, 0.5), [Modell], farbe: luma(225), breite: 2.4cm),
        b((0, 1), [Serving: \ Anfrage in °F]),
        b((1, 1), [Vorverarbeitung B \ (Dienst, abweichend)], farbe: rgb("#FBF1E6"), s: orange),
        edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0.5), "-|>"),
        edge((0, 1), (1, 1), "-|>"), edge((1, 1), (2, 0.5), "-|>", stroke: 1pt + orange),
      ),
      align(left, text(weight: "bold")[Ohne Skew: ein gemeinsamer Codepfad]),
      diagram(
        node-corner-radius: 3pt,
        spacing: (44pt, 14pt),
        b((0, 0), [Training: \ Rohdaten]),
        b((0, 1), [Serving: \ Anfrage]),
        b((1, 0.5), [Vorverarbeitung \ (eine Quelle)], farbe: rgb("#DDF2E9"), s: gruen),
        b((2, 0.5), [Modell], farbe: luma(225), breite: 2.4cm),
        edge((0, 0), (1, 0.5), "-|>"), edge((0, 1), (1, 0.5), "-|>"), edge((1, 0.5), (2, 0.5), "-|>"),
      ),
    )
  },
  caption: [Training-Serving Skew entsteht, wenn zwei Codepfade dieselbe Vorverarbeitung unterschiedlich umsetzen (oben, orange); die Pipeline läuft fehlerfrei, liefert aber andere Zahlen. Die Abhilfe ist ein einziger Pfad, den Training und Serving gemeinsam benutzen (unten); das ist die Idee hinter den Patterns Transform und Feature Store.],
) <abb-skew>

== Übersetzung in die Welt der Softwareentwicklung

Wer aus dem Software Engineering kommt, versteht ML am schnellsten, wenn er die neuen Begriffe an Bekanntes anbindet. @tab-uebersetzung tut das. Jede Analogie hinkt an einer Stelle, und gerade dort liegt oft die Lehre.

#figure(
  {
    set text(size: 10pt)
    table(
      columns: (auto, 1fr, 1fr),
      align: (left, left, left),
      inset: (x: 0.6em, y: 0.4em),
      table.header([ML-Begriff], [Entsprechung im SE], [Wo die Analogie hinkt]),
      [Trainingsdaten], [Quellcode als Eingabe des Builds], [Die Daten bestimmen das Verhalten; Änderungen an ihnen sind Änderungen am Programm und müssen versioniert werden.],
      [Training], [Build], [Das Ergebnis hängt von Zufall und Daten ab; derselbe Build liefert nicht zwingend dasselbe Artefakt.],
      [Modell mit Parametern], [Binary mit Konstanten], [Das Verhalten steht nicht im Quelltext, sondern in Zahlen; man kann es nicht lesen, nur testen.],
      [Evaluation], [Testsuite], [Es gibt keine Pass/Fail-Entscheidung, sondern Metriken, die man gegen eine Schwelle interpretiert.],
      [Overfitting], [Testfälle hart kodieren], [Der Effekt entsteht ohne böse Absicht, allein durch zu viel Flexibilität.],
      [Datenleck], [Ein Test, der die erwartete Antwort kennt], [Es fällt nicht auf, weil nichts fehlschlägt.],
      [Training-Serving Skew], [Zwei Implementierungen derselben Logik (DRY-Verletzung)], [Das System läuft, nur das Ergebnis ist schlechter.],
      [Drift], [Die Umgebung ändert sich, der Code nicht], [Der Fehler zeigt sich nicht als Ausnahme, sondern als schleichend sinkende Qualität.],
    )
  },
  caption: [ML-Begriffe und ihre Entsprechung in der Softwareentwicklung.],
  kind: table,
) <tab-uebersetzung>

Mit diesem Vokabular sind Sie für die Patterns gerüstet. Kapitel 4 zeigt, wo sie am Lebenszyklus sitzen und wie sie zusammenhängen.

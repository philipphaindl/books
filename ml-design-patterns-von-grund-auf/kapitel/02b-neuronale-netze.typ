#import "../lib.typ": *
#import "@preview/cetz-plot:0.1.2": plot

#let gruen = rgb("#2EAE7D")
#let orange = rgb("#B5651D")
#let orange-hell = rgb("#FBF1E6")
#let gruen-hell = rgb("#E4F5EE")
#let nebel = luma(240)
#let klassenfarbe = (blau, orange, gruen)
#let klassengrund = (rgb("#D9E6F7"), rgb("#F5E3D0"), rgb("#D6EFE4"))

// Zahl mit deutschem Komma
#let z(x, n: 3) = {
  let s = str(calc.round(x, digits: n))
  if not s.contains(".") and n > 0 { s += "." + "0" * n } else if n > 0 {
    let teile = s.split(".")
    s = teile.at(0) + "." + teile.at(1) + "0" * (n - teile.at(1).len())
  }
  s.replace(".", ",")
}
// Ausschnitt aus einer Code-Datei: ab der ersten Zeile mit `ab` bis vor die erste folgende Zeile mit `bis`.
// Der gezeigte Code ist damit zeichengleich mit der ausgeführten Datei (nur gemeinsam eingerückt).
#let code-aus(datei, ab, bis: none) = {
  let zeilen = read(datei).split("\n")
  let a = zeilen.position(zl => zl.contains(ab))
  let b = if bis == none { zeilen.len() } else { a + 1 + zeilen.slice(a + 1).position(zl => zl.contains(bis)) }
  let teil = zeilen.slice(a, b)
  let einzug = calc.min(..teil.filter(zl => zl.trim() != "").map(zl => zl.len() - zl.trim(at: start).len()))
  raw(teil.map(zl => if zl.len() >= einzug { zl.slice(einzug) } else { zl }).join("\n").trim("\n", at: end), lang: "python", block: true)
}
// Echte Ausgabe eines Laufs als Konsolenfenster, davor der Befehl.
#let ausgabe(befehl, datei, von: 0, bis: none) = {
  let zl = read(datei).trim("\n", at: end).split("\n")
  raw("$ " + befehl + "\n" + zl.slice(von, bis).join("\n"), lang: "terminal", block: true)
}
#let knoten(pos, body, farbe: blau, grund: blau-hell, ..args) = node(pos, body, stroke: farbe, fill: grund, ..args)
#let neben(pos, body, ..args) = node(pos, body, stroke: 0.6pt + luma(150), fill: nebel, ..args)

// Entscheidungsgrenze: Raster (Zeile = y von unten nach oben, Spalte = x) als farbige Flächen, darüber die Datenpunkte.
// Gleiche Nachbarzellen einer Zeile werden zu einem Rechteck zusammengefasst.
#let grenzkarte(raster, punkte, breite: 7.2) = canvas(length: 1cm, {
  import draw: *
  let n = raster.len()
  let g = 1.25
  let s = breite / (2 * g)
  let zelle = 2 * g / (n - 1)
  for (j, zeile) in raster.enumerate() {
    let i = 0
    while i < n {
      let k = zeile.at(i)
      let e = i
      while e + 1 < n and zeile.at(e + 1) == k { e += 1 }
      let x0 = -g + i * zelle - zelle / 2
      let x1 = -g + e * zelle + zelle / 2
      let y0 = -g + j * zelle - zelle / 2
      rect((x0 * s, y0 * s), (x1 * s, (y0 + zelle) * s), fill: klassengrund.at(k), stroke: 0.35pt + klassengrund.at(k))
      i = e + 1
    }
  }
  rect((-g * s, -g * s), (g * s, g * s), stroke: 0.5pt + luma(120), fill: none)
  for p in punkte {
    circle((p.at(0) * s, p.at(1) * s), radius: 0.075, fill: klassenfarbe.at(p.at(2)), stroke: 0.4pt + white)
  }
})

= Neuronale Netze und Repräsentationen verstehen

Die Patterns in den Teilen II und III sprechen ständig von Dingen, die man als Software Engineer zunächst nur benennen, aber nicht nachbauen kann: von Embeddings, die „gelernt“ werden, von Checkpoints, die den „Zustand“ eines Trainings enthalten, von vortrainierten Modellen, deren Schichten man „einfriert“, und von Gradienten, die auf mehreren Rechnern „gemittelt“ werden. Dieses Kapitel baut die Mechanik dahinter einmal vollständig auf, mit einem kleinen Netz, das wir in numpy von Grund auf schreiben und trainieren. Das Grundlagenkapitel hat Parameter, Loss und Gradientenabstieg eingeführt und ein Netz als Black Box (`MLPClassifier`) benutzt; hier öffnen wir die Box. Danach lässt sich die Mechanik hinter Pattern 2, 12, 13 und 14 selbst nachrechnen.

#kasten([Lernziele.], [
  Nach diesem Kapitel können Sie (1) ein Neuron und ein mehrschichtiges Netz als Folge von Matrixmultiplikationen mit Nichtlinearitäten beschreiben, (2) erklären, wie Backpropagation mit der Kettenregel aus einem Fehler für jeden Parameter einen Gradienten macht, (3) Loss, Softmax, Mini-Batch, Epoche und Lernrate in einem Trainingsprotokoll lesen und Fehlverhalten daran erkennen, (4) begründen, warum eine Embedding-Schicht eine Nachschlagetabelle ist und woher ihre Zahlen kommen, (5) erläutern, warum Features aus einer Aufgabe auf eine andere übertragbar sind und wann nicht, und (6) sagen, was in einen Checkpoint gehört und warum sich Gradienten über mehrere Worker mitteln lassen. Alle Zahlen stammen aus Skripten in `code/02b/`, die Sie selbst ausführen können.
])

== Ein Neuron: gewichtete Summe und Aktivierung

Ein künstliches Neuron ist kleiner, als der Name vermuten lässt. Es bekommt mehrere Zahlen als Eingabe, multipliziert jede mit einem eigenen *Gewicht*, addiert die Produkte und einen weiteren Parameter, den *Bias*, und schickt das Ergebnis durch eine feste Funktion, die *Aktivierungsfunktion*. Mit Eingaben $x_1, x_2$ und Gewichten $w_1, w_2$ ist die Rechnung

$ z = w_1 x_1 + w_2 x_2 + b, wide a = phi.alt(z). $

Die Gewichte und der Bias sind die lernbaren Parameter; $x$ und $a$ sind Werte, die nur für ein Beispiel gelten. Ohne $phi.alt$ wäre das Neuron eine lineare Regression, wie Sie sie aus dem Grundlagenkapitel kennen. Bereits Rosenblatts Perzeptron von 1958 folgt diesem Schema, die Aktivierung war damals eine harte Schwelle @rosenblatt_perceptron_1958.

#figure(
  placement: auto,
  text(size: 9pt, diagram(
    node-inset: 7pt, node-corner-radius: 3pt, spacing: (15mm, 11mm),
    neben((0, 0), [$x_1 = "0,8"$]), neben((0, 1), [$x_2 = "0,3"$]),
    knoten((1, 0.5), [Summe plus Bias \ #text(size: 8.5pt, fill: grau)[$z = "0,5" dot "0,8" + (-"1,0") dot "0,3" + "0,2"$ \ $= "0,30"$]]),
    knoten((2, 0.5), [Aktivierung \ #text(size: 8.5pt, fill: grau)[$a = phi.alt(z)$]], farbe: orange, grund: orange-hell),
    knoten((3, 0.5), [Ausgabe \ #text(size: 8.5pt, fill: grau)[ReLU: $"0,30"$ \ Sigmoid: $"0,574"$]], farbe: gruen, grund: gruen-hell),
    edge((0, 0), (1, 0.5), "->", label: $w_1 = "0,5"$, label-side: left, label-sep: 2pt, label-fill: true),
    edge((0, 1), (1, 0.5), "->", label: $w_2 = -"1,0"$, label-side: right, label-sep: 2pt, label-fill: true),
    edge((1, 0.5), (2, 0.5), "->"), edge((2, 0.5), (3, 0.5), "->"),
  )),
  caption: [Ein Neuron mit zwei Eingaben und dem Bias $b = "0,2"$. Die Zahlen stammen aus `01_neuron.py`.],
) <abb-neuron>

Drei Aktivierungsfunktionen begegnen einem ständig (@abb-aktivierung). Die *Sigmoid*-Funktion $1 / (1 + e^(-z))$ drückt jeden Wert in das Intervall von 0 bis 1 und lässt sich als Wahrscheinlichkeit lesen; $tanh$ tut dasselbe zwischen $-1$ und $1$. Die *ReLU* (Rectified Linear Unit), $max(0, z)$, reicht positive Werte unverändert durch und setzt negative auf null. Sie ist die Standardwahl für versteckte Schichten, weil sie billig zu berechnen ist und für positive $z$ einen Gradienten von genau 1 hat, was das Training tiefer Netze erleichtert @goodfellow_deep_learning_2016.

#figure(
  placement: auto,
  text(size: 9pt, canvas({
    plot.plot(
      size: (9.5, 3.7), x-label: [$z$], y-label: [$a = phi.alt(z)$], x-min: -4, x-max: 4, y-min: -1.2, y-max: 2.2,
      x-tick-step: 1, y-tick-step: 1, legend: "inner-north-west",
      {
        plot.add(domain: (-4, 4), x => 1 / (1 + calc.exp(-x)), label: [Sigmoid], style: (stroke: blau + 1.4pt))
        plot.add(domain: (-4, 4), x => calc.tanh(x), label: [tanh], style: (stroke: orange + 1.4pt))
        plot.add(domain: (-4, 4), x => calc.max(x, 0), label: [ReLU], style: (stroke: gruen + 1.4pt))
      },
    )
  })),
  caption: [Die drei gängigen Aktivierungsfunktionen. Nur ReLU wächst unbegrenzt; Sigmoid und tanh sättigen.],
) <abb-aktivierung>

Warum braucht es die Aktivierung überhaupt? Weil lineare Rechnungen sich zusammenfassen lassen. Zwei hintereinandergeschaltete lineare Schichten mit Gewichtsmatrizen $A$ und $B$ ergeben dieselbe Abbildung wie eine einzige Schicht mit der Matrix $A B$; `01_neuron.py` prüft das mit `np.allclose` nach und gibt `True` aus. Ein Netz aus beliebig vielen rein linearen Schichten bleibt also eine lineare Funktion und kann keine Kurve lernen. Erst die Nichtlinearität dazwischen macht Tiefe nützlich.

== Mehrschichtige Netze

Ein *mehrschichtiges Netz* (Multilayer Perceptron, MLP) legt viele Neuronen nebeneinander zu einer Schicht und mehrere Schichten hintereinander. Die Rechnung einer Schicht für alle Neuronen und alle Beispiele auf einmal ist eine Matrixmultiplikation: Hat die Schicht $m$ Eingänge und $n$ Neuronen, dann ist $W$ eine Matrix mit $m$ Zeilen und $n$ Spalten, und für eine Matrix $X$ aus $B$ Beispielen gilt

$ H = phi.alt(X W + b), wide X in RR^(B times m), W in RR^(m times n), H in RR^(B times n). $

Die Ausgabe $H$ jeder Schicht ist die Eingabe der nächsten. Die Schichten zwischen Eingabe und Ausgabe heißen *versteckt* (hidden), weil man ihre Werte nicht vorgibt. Es hilft, sie als *Repräsentationen* zu lesen: Jede versteckte Schicht übersetzt die Eingabe in eine neue Darstellung, in der die Aufgabe der nächsten Schicht leichter ist. Das ist der Grund für den Kapiteltitel, und es wird bei Embeddings und Transfer Learning noch wichtig.

#figure(
  placement: auto,
  canvas(length: 1cm, {
    import draw: *
    let ns = (2, 4, 4, 3)
    let xs = (0, 4.2, 8.4, 12.6)
    let pos(l, i) = (xs.at(l), (ns.at(l) - 1) / 2 * 0.95 - i * 0.95)
    for l in range(3) {
      for i in range(ns.at(l)) {
        for j in range(ns.at(l + 1)) { line(pos(l, i), pos(l + 1, j), stroke: 0.4pt + luma(185)) }
      }
    }
    let farben = ((nebel, luma(140)), (blau-hell, blau), (blau-hell, blau), (gruen-hell, gruen))
    for l in range(4) {
      for i in range(ns.at(l)) { circle(pos(l, i), radius: 0.24, fill: farben.at(l).at(0), stroke: 0.9pt + farben.at(l).at(1)) }
    }
    let namen = ([Eingabe \ $x$], [versteckt \ $h_1 = phi.alt(x W_1 + b_1)$], [versteckt \ $h_2 = phi.alt(h_1 W_2 + b_2)$], [Ausgabe \ $z = h_2 W_3 + b_3$])
    for l in range(4) { content((xs.at(l), -2.35), text(size: 8.5pt, namen.at(l)), anchor: "north") }
    for (l, t) in ((0, [$W_1$: $2 times 4$]), (1, [$W_2$: $4 times 4$]), (2, [$W_3$: $4 times 3$])) {
      content(((xs.at(l) + xs.at(l + 1)) / 2, 1.55), text(size: 8.5pt, fill: grau, t))
    }
  }),
  caption: [Ein kleines MLP mit zwei versteckten Schichten. Jede Linie ist ein Gewicht; die Matrizen darüber fassen sie je Schicht zusammen. Das Netz dieses Kapitels hat dieselbe Form, nur mit 32 statt 4 Neuronen je versteckter Schicht.],
) <abb-mlp>

Zählen lassen sich die Parameter sofort: $W_1$ hat 8, $W_2$ 16 und $W_3$ 12 Einträge, dazu kommen 4 + 4 + 3 Biaswerte, zusammen 47. Das Netz, das wir gleich trainieren, hat Schichtgrößen 2, 32, 32, 3 und damit $2 dot 32 + 32 + 32 dot 32 + 32 + 32 dot 3 + 3 = 1251$ Parameter. Alles, was ein Netz „weiß“, steckt in diesen Zahlen.

Wie viel zwei Schichten bringen, zeigt das Klassiker-Beispiel XOR: Die Ausgabe soll 1 sein, wenn genau eine der beiden Eingaben 1 ist. Die vier Punkte lassen sich nicht durch eine Gerade trennen, ein einzelnes Neuron scheitert daher, ein Argument, das in der Kritik von Minsky und Papert am Perzeptron eine große Rolle spielte @minsky_perceptrons_1969. Zwei ReLU-Neuronen mit von Hand gesetzten Gewichten genügen (Ausgabe von `01_neuron.py`):

#ausgabe("uv run --with numpy python 01_neuron.py", "../code/02b/out/01_neuron.out.txt", von: 3, bis: 8)

Das erste Neuron bildet $x_1 + x_2$, das zweite zieht davon 1 ab und lässt nur Überschuss durch. Die Ausgabe ist $h_1 - 2 h_2$. Bei den Eingaben (1, 1) heben sich die Anteile auf. Eine versteckte Schicht hat hier eine *neue Eigenschaft* der Eingabe berechnet („beide sind an“), mit der die nächste Schicht nur noch eine lineare Entscheidung treffen muss. Der Satz von Hornik, Stinchcombe und White macht daraus eine allgemeine Aussage: Ein Netz mit einer ausreichend breiten versteckten Schicht kann jede stetige Funktion auf einem beschränkten Bereich beliebig genau annähern @hornik_approximation_1989. Bewiesen wurde das zunächst für sigmoidartige Aktivierungen, später auch für ReLU und viele andere @leshno_nonpolynomial_1993. Er sagt aber nichts darüber, wie breit „ausreichend“ ist und ob Training die passenden Gewichte findet. Das ist die eigentliche Schwierigkeit, und ihr widmet sich der Rest des Kapitels.

== Softmax und Cross-Entropy: aus Zahlen werden Wahrscheinlichkeiten

Bei einer Klassifikation mit mehreren Klassen soll die Ausgabeschicht für jede Klasse eine Wahrscheinlichkeit liefern, alle zusammen ergeben 1. Die letzte Schicht rechnet zunächst ganz normal $z = h W + b$ und liefert pro Klasse einen beliebigen Zahlenwert, den *Logit*. Die *Softmax*-Funktion macht daraus Wahrscheinlichkeiten:

$ p_k = e^(z_k) / (sum_j e^(z_j)). $

Die Exponentialfunktion macht jeden Wert positiv und vergrößert Unterschiede; die Division durch die Summe sorgt dafür, dass die Werte 1 ergeben. Für die Logits $("2,0"; "1,0"; "0,1")$ erhält man $e^2 = "7,39"$, $e^1 = "2,72"$ und $e^("0,1") = "1,11"$, zusammen 11,21, und damit die Wahrscheinlichkeiten $("0,659"; "0,242"; "0,099")$. In der Implementierung zieht man vorher den größten Logit von allen ab. Das ändert das Ergebnis nicht (Zähler und Nenner kürzen sich), verhindert aber, dass $e^(z)$ bei großen Logits überläuft.

Wie gut ist so eine Vorhersage? Der Loss muss klein sein, wenn die richtige Klasse eine hohe Wahrscheinlichkeit bekommt, und sehr groß, wenn das Modell sich sicher und falsch ist. Die *Cross-Entropy* leistet das:

$ L = -ln p_y. $

Dabei ist $y$ die richtige Klasse. Hat sie die Wahrscheinlichkeit 0,659, ist $L = "0,417"$; bei 0,01 sind es 4,6; bei 0,0001 schon 9,2. Wer sich sicher irrt, wird also hart bestraft. Eine Zahl dient als Bezugspunkt: Ein Modell, das bei drei gleich häufigen Klassen immer $1/3$ rät, hat $L = ln 3 = "1,099"$. Liegt der Loss zu Beginn des Trainings in dieser Größenordnung, ist das ein gutes Zeichen für eine korrekte Implementierung. Für das Training zählt eine Eigenschaft, die man leicht herleiten kann und die den Code kurz macht: Der Gradient der Cross-Entropy nach den Logits ist

$ (partial L) / (partial z_k) = p_k - [k = y]. $

Von jeder vorhergesagten Wahrscheinlichkeit zieht man also eine 1 für die richtige Klasse ab. Im Beispiel mit der richtigen Klasse 0 ist der Gradient $(-"0,341"; "0,242"; "0,099")$: Der Logit der richtigen Klasse soll steigen (ein negativer Gradient bedeutet, dass der Loss mit größerem $z$ sinkt), die der anderen sollen sinken.

== Lernen mit Backpropagation

=== Die Kettenregel an einem Neuron

Training heißt, für jeden Parameter zu wissen, in welche Richtung und wie stark der Loss sich ändert, wenn man ihn ein wenig verschiebt. Bei einem Netz mit mehreren tausend Parametern kann man das nicht ausprobieren; man leitet es mit der Kettenregel her. Sie sagt: Hängt $L$ von $a$ ab und $a$ von $z$ und $z$ von $w$, dann multipliziert man die einzelnen Änderungsraten entlang der Kette: $partial L slash partial w = partial L slash partial a dot partial a slash partial z dot partial z slash partial w$.

Wir rechnen das an einem einzigen ReLU-Neuron durch, mit Eingabe $x = 2$, Gewicht $w = "0,5"$, Bias $b = "0,3"$ und dem gewünschten Wert 1. Als Loss nehmen wir hier den quadratischen Fehler $(a - 1)^2$. Der Vorwärtsdurchlauf berechnet $z = "1,3"$, $a = "1,3"$ und $L = "0,09"$. Dann läuft man rückwärts durch dieselbe Kette (@abb-backprop): $L$ ändert sich mit $a$ um $2(a-1) = "0,6"$; die ReLU gibt bei $z > 0$ den Gradienten unverändert weiter; $z$ hängt mit dem Faktor $x = 2$ von $w$ ab, also ist $partial L slash partial w = "0,6" dot 2 = "1,2"$, und der Bias geht mit dem Faktor 1 ein: $partial L slash partial b = "0,6"$.

#figure(
  placement: auto,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (13mm, 17mm),
    knoten((0, 0), [Eingaben \ #text(size: 8.5pt, fill: grau)[$x=2, w="0,5", b="0,3"$]]),
    knoten((1, 0), [$z = w x + b$ \ #text(size: 8.5pt, fill: grau)[$= "1,3"$]]),
    knoten((2, 0), [$a = "ReLU"(z)$ \ #text(size: 8.5pt, fill: grau)[$= "1,3"$]]),
    knoten((3, 0), [$L = (a-1)^2$ \ #text(size: 8.5pt, fill: grau)[$= "0,09"$]], farbe: gruen, grund: gruen-hell),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"),
    knoten((0, 1), [$partial L slash partial w = "1,2"$ \ $partial L slash partial b = "0,6"$], farbe: orange, grund: orange-hell),
    knoten((1, 1), [$partial L slash partial z$ \ $= "0,6" dot 1 = "0,6"$], farbe: orange, grund: orange-hell),
    knoten((2, 1), [$partial L slash partial a$ \ $= 2(a-1) = "0,6"$], farbe: orange, grund: orange-hell),
    knoten((3, 1), [$partial L slash partial L$ \ $= 1$], farbe: orange, grund: orange-hell),
    edge((3, 1), (2, 1), "->", stroke: orange), edge((2, 1), (1, 1), "->", stroke: orange), edge((1, 1), (0, 1), "->", stroke: orange),
  )),
  caption: [Oben der Vorwärtsdurchlauf, unten der Rückwärtsdurchlauf (orange). Jeder Rückwärtsschritt multipliziert den ankommenden Gradienten mit der lokalen Ableitung des Knotens. Zahlen aus `01_neuron.py`.],
) <abb-backprop>

Der Gradient wird dann für einen Schritt des *Gradientenabstiegs* benutzt: Jeden Parameter verschiebt man gegen die Richtung seines Gradienten, skaliert mit der *Lernrate* $eta$:

$ w arrow.l w - eta dot (partial L) / (partial w). $

Mit $eta = "0,1"$ wird aus $w = "0,5"$ der Wert 0,38 und aus $b = "0,3"$ der Wert 0,24; die Ausgabe ist dann $"0,38" dot 2 + "0,24" = "1,0"$ und der Loss null. Ein einzelner Schritt trifft das Ziel selten so genau, es ist ein Beispiel mit passenden Zahlen. `01_neuron.py` bestätigt die Gradienten außerdem unabhängig: Es verschiebt $w$ und $b$ um $plus.minus 10^(-6)$ und bildet den Differenzenquotienten, was ebenfalls $"1,2"$ und $"0,6"$ ergibt.

=== Backpropagation für das ganze Netz

Ein Netz ist dieselbe Kette, nur länger und mit Matrizen statt einzelnen Zahlen. *Backpropagation* ist der Name für die Reihenfolge, in der man die Kettenregel auswertet; als Lernverfahren für mehrschichtige Netze bekannt gemacht haben sie Rumelhart, Hinton und Williams @rumelhart_backprop_1986. Man beginnt am Loss und arbeitet sich Schicht für Schicht nach vorn, und jede Schicht benutzt den Gradienten, den die Schicht hinter ihr geliefert hat. Der Gradient, der an der Schicht $l$ ankommt, sei $delta_l$ (eine Zeile pro Beispiel, eine Spalte pro Neuron). Für Softmax mit Cross-Entropy in der letzten Schicht gilt $delta_L = (P - Y) slash B$ mit der Matrix $P$ der Vorhersagen und der One-Hot-Matrix $Y$ der richtigen Antworten. Für jede Schicht rückwärts rechnet man

$ (partial L) / (partial W_l) = H_(l-1)^top delta_l, quad (partial L) / (partial b_l) = sum_"Beispiele" delta_l, quad delta_(l-1) = (delta_l W_l^top) dot.o bb(1)[H_(l-1) > 0]. $

Die erste Gleichung heißt in Worten: Das Gewicht zwischen Neuron $i$ und Neuron $j$ ändert sich umso stärker, je aktiver $i$ war und je größer der Fehler ist, der bei $j$ ankommt. Die dritte reicht den Fehler durch die Gewichte nach hinten und blendet jene Neuronen aus, die bei diesem Beispiel „aus“ waren (die ReLU hat dort den Gradienten null). Der Rückwärtsdurchlauf braucht die Zwischenwerte $H$ des Vorwärtsdurchlaufs, deshalb merkt sich dieser sie. Ein Rückwärtsdurchlauf kostet etwa doppelt so viel Rechenzeit wie ein Vorwärtsdurchlauf (je Schicht zwei Matrixprodukte statt einem), dazu Speicher für alle Zwischenwerte; das wird bei der Batch-Größe und bei der Hardware wieder wichtig.

#block(breakable: false)[#tipp[Mit Backpropagation muss niemand von Hand rechnen. Frameworks wie PyTorch oder TensorFlow zeichnen beim Vorwärtsdurchlauf einen Graphen der Operationen auf und leiten ihn automatisch rückwärts ab (automatic differentiation); Sie schreiben nur den Vorwärtsteil. Verstehen sollten Sie das Prinzip trotzdem: Es erklärt, warum Training so viel Speicher braucht und warum nicht differenzierbare Schritte, etwa ein hartes `if` auf einem Zwischenwert, den Gradientenfluss unterbrechen.]]

== Ein Netz von Grund auf: die Spirale

Jetzt setzen wir alles zusammen. Die Aufgabe ist ein klassischer Test für kleine Netze: 300 Punkte in der Ebene, die auf drei ineinander verschlungenen Spiralarmen liegen und zu drei Klassen gehören. Keine Gerade trennt sie, das Netz muss eine gekrümmte Grenze lernen. Die Daten erzeugt `daten.py` mit festem Seed, das Netz (`mlp.py`, nur numpy) hat die Form 2–32–32–3 mit ReLU und Softmax. Der erste Ausschnitt zeigt den Vorwärtsdurchlauf, den Loss und die Backpropagation, also die eben besprochenen Gleichungen, in knapp 40 Zeilen:

#code-aus("../code/02b/mlp.py", "    def forward", bis: "    def schritt")

Der zweite Ausschnitt ist der Kern der Trainingsschleife aus `trainiere` (der Rest sammelt Loss und Genauigkeit je Epoche). Pro Epoche mischt sie die Beispiele neu, zerlegt sie in Mini-Batches, berechnet für jeden Batch die Gradienten und macht einen Schritt:

#code-aus("../code/02b/mlp.py", "    for _ in range(epochen)", bis: "        p = netz.forward(X)[0]")

Bevor wir trainieren, prüft `02_spirale.py` die Backpropagation: Für 15 zufällig gewählte Gewichte vergleicht es den berechneten Gradienten mit dem numerischen Differenzenquotienten. Dieser Gradient Check ist der Unit-Test unter den Trainingsverfahren und sollte bei jeder selbst geschriebenen Backpropagation laufen. Danach trainiert das Skript 100 Epochen mit Mini-Batches der Größe 32 und Lernrate 0,5:

#ausgabe("uv run --with numpy python 02_spirale.py", "../code/02b/out/02_spirale.out.txt")

Der Anfangsloss von 0,985 liegt knapp unter dem Raten-Wert $ln 3 = "1,099"$, wie erwartet. Die Abweichung des Gradient Checks von $2 dot 10^(-8)$ liegt im Rauschen des Differenzenquotienten; die Implementierung ist richtig. Nach einer Epoche sind es 60 % Genauigkeit, nach zehn 75 %. Der Loss verläuft zunächst unruhig (zwischen 0,24 und 0,87; die Lernrate 0,5 ist für dieses Netz schon recht groß), fällt dann in Epoche 12 auf 0,12 und bis Epoche 50 auf 0,015 (@abb-spirale-verlauf). Auf 300 neu erzeugten Testpunkten erreicht das Netz 99,7 %. Die Testpunkte haben dieselben Radien und Soll-Winkel wie die Trainingspunkte, nur mit neu gezogenem Rauschen; das ist weniger streng als völlig neue Positionen, belegt aber, dass das Netz die Kurven gelernt hat und nicht einzelne Trainingspunkte auswendig.

#figure(
  placement: auto,
  {
    let d = json("../code/02b/out/spirale.json")
    grid(
      columns: (1fr, 1fr), column-gutter: 6pt, row-gutter: 5pt, align: center + horizon,
      grenzkarte(d.vorher, d.punkte, breite: 6.6), grenzkarte(d.nachher, d.punkte, breite: 6.6),
      text(size: 9pt)[vor dem Training: Genauigkeit 47 %], text(size: 9pt)[nach 100 Epochen: Genauigkeit 100 %],
    )
  },
  caption: [Entscheidungsgrenze des Netzes vor und nach dem Training. Die Flächen zeigen, welche Klasse das Netz an jeder Stelle der Ebene vorhersagt, die Punkte sind die 300 Trainingsbeispiele. Vor dem Training liegen die Grenzen willkürlich, danach folgen sie den Spiralarmen.],
) <abb-spirale-grenze>

#figure(
  placement: auto,
  {
    let d = json("../code/02b/out/spirale.json")
    text(size: 9pt, canvas({
      plot.plot(
        size: (10.5, 3.2), x-label: [Epoche], y-label: [Loss], x-min: 0, x-max: 100, y-min: 0, y-max: 1,
        x-tick-step: 10, y-tick-step: 0.25,
        {
          plot.add(d.loss.enumerate().map(((i, v)) => (i + 1, v)), style: (stroke: blau + 1.4pt))
        },
      )
    }))
  },
  caption: [Loss auf den Trainingsdaten je Epoche (Werte aus `02_spirale.py`). Nach einer unruhigen Anfangsphase fällt er ab Epoche 12 auf unter 0,15.],
) <abb-spirale-verlauf>

== Mini-Batches, Epochen und Lernrate

Die Trainingsschleife hat drei Stellschrauben, die jedes Trainingsprotokoll prägen. Die erste ist die *Batch-Größe*. Man könnte den Gradienten über alle 300 Beispiele bilden und pro Epoche genau einen Schritt machen, oder nach jedem einzelnen Beispiel einen Schritt. Der Mini-Batch liegt dazwischen: Der Gradient über 32 zufällig gezogene Beispiele ist eine verrauschte, aber im Mittel richtige Schätzung des Gradienten über alle Daten. Man bekommt viele Schritte pro Epoche und kann die Beispiele eines Batches als eine Matrix auf einmal durchrechnen. Die zweite ist die *Epoche*, ein Durchlauf durch alle Trainingsdaten; die Zahl der Epochen bestimmt, wie lange trainiert wird. Die dritte ist die Lernrate $eta$.

`03_lernrate.py` ändert nur eine Größe pro Lauf, alles andere (Daten, Anfangsgewichte, Reihenfolge der Beispiele) bleibt gleich. Die obere Hälfte der Ausgabe variiert die Lernrate bei Batch-Größe 32, die untere die Batch-Größe:

#ausgabe("uv run --with numpy python 03_lernrate.py", "../code/02b/out/03_lernrate.out.txt")

#figure(
  placement: auto,
  {
    let d = json("../code/02b/out/lernrate.json")
    let serien = (("0.005", blau, [$eta = "0,005"$]), ("0.05", gruen, [$eta = "0,05"$]), ("0.5", orange, [$eta = "0,5"$]), ("5.0", luma(90), [$eta = 5$]))
    text(size: 9pt, canvas({
      plot.plot(
        size: (9.5, 3.7), x-label: [Epoche], y-label: [Loss], x-min: 0, x-max: 50, y-min: 0, y-max: 2,
        x-tick-step: 10, y-tick-step: 0.5, legend: "east",
        {
          for (k, f, name) in serien {
            plot.add(d.at(k).enumerate().map(((i, v)) => (i + 1, v)), label: name, style: (stroke: f + 1.4pt))
          }
        },
      )
    }))
  },
  caption: [Trainings-Loss bei vier Lernraten. Die Kurve für $eta = 5$ beginnt bei 18,4 (Epoche 1, außerhalb des Bildes) und pendelt danach zwischen 1,1 und 1,9.],
) <abb-lernrate>

Jede der vier Kurven zeigt ein typisches Bild. Bei $eta = "0,005"$ sinkt der Loss gleichmäßig, aber so langsam, dass er nach 50 Epochen erst bei 0,77 steht (55 % Genauigkeit): zu klein. Bei 0,05 ist das Netz nach 50 Epochen bei 95 %, aber noch nicht fertig; bei 0,5 erreicht es 99,7 %. Mit $eta = 5$ geht der erste Schritt weit über das Ziel hinaus: Der Loss springt auf 18,4 und pendelt danach zwischen 1,1 und 1,9, ohne zu sinken. Die letzte Spalte der Ausgabe verrät den Grund. Von den 64 versteckten Neuronen ist kein einziges für irgendein Trainingsbeispiel aktiv. Der große Schritt hat die Gewichte so verschoben, dass jedes $z$ negativ ist; die ReLU liefert dann überall null, der Gradient ebenfalls, und es gibt keinen Weg zurück. Man spricht von *toten Neuronen*. Am Ende des Laufs sagt das Netz für jede Eingabe dieselben Wahrscheinlichkeiten voraus, und der Loss liegt mit 1,11 bei etwa $ln 3$.

Das Trainingsprotokoll liefert also Diagnosen, die man ohne weitere Werkzeuge lesen kann: Ein Loss, der springt, steigt oder um den Raten-Wert pendelt, deutet auf eine zu große Lernrate; ein Loss, der kaum sinkt, auf eine zu kleine oder auf zu wenige Epochen. Die Lernrate gilt in der Praxis als der wichtigste Hyperparameter @goodfellow_deep_learning_2016, und Pattern 15 behandelt, wie man sie systematisch sucht. Moderne Optimierer wie Adam passen die Schrittweite für jeden Parameter anhand der bisherigen Gradienten an @kingma_adam_2015. Das nimmt dem Anwender Arbeit ab, ersetzt die Lernrate aber nicht, und es hat eine Folge für Checkpoints, auf die wir noch kommen.

Nun zur Batch-Größe, der unteren Hälfte der Ausgabe. Man sollte Läufe nach der Zahl der Schritte vergleichen, nicht nach Epochen. Mit Batch 300 gibt es einen Schritt pro Epoche, nach 50 Epochen also erst 50 Schritte, und der Loss steht deshalb erst bei 0,31. Mit Batch 1 sind es 300 Schritte je Epoche, und bei Lernrate 0,05 steht der Loss schon nach zehn Epochen bei 0,03; bei Lernrate 0,5 funktioniert Batch 1 dagegen nicht (Loss 1,12). Der Gradient eines einzelnen Beispiels ist viel verrauschter, und derselbe Schritt ist dann offenbar zu groß. Batch-Größe und Lernrate gehören also zusammen: Größere Batches vertragen größere Lernraten. Trotzdem ist Batch 1 in der Praxis keine gute Wahl, denn 300 winzige, nacheinander ausgeführte Schritte nutzen moderne Hardware schlecht aus. Warum, klärt der Abschnitt über Hardware.

== Regularisierung: Overfitting dämpfen

Overfitting kennen Sie aus dem Grundlagenkapitel: Ein Modell, das die Trainingsdaten auswendig lernt, einschließlich ihres Rauschens, und deshalb auf neuen Daten schlechter ist. Neuronale Netze sind dafür besonders anfällig, weil sie sehr viele Parameter haben. Um das zu sehen, machen wir die Aufgabe schwerer und das Netz größer: Dieselbe Spirale, aber mit stark verrauschten Punkten (Streuung 0,8), nur 60 Trainingsbeispiele und ein Netz mit 2–128–128–3 Neuronen, also über 17 000 Parameter. `04_regularisierung.py` trainiert 500 Epochen und vergleicht vier Varianten auf getrennten Validierungs- und Testdaten mit je 300 Beispielen. Alles wird mit fünf frisch gezogenen Datensätzen wiederholt.

#figure(
  placement: auto,
  {
    let d = json("../code/02b/out/regularisierung.json")
    let pkt(l) = l.enumerate().map(((i, v)) => (i + 1, v))
    text(size: 9pt, canvas({
      plot.plot(
        size: (10.5, 3.8), x-label: [Epoche], y-label: [Loss], x-min: 0, x-max: 500, y-min: 0, y-max: 1.6,
        x-tick-step: 100, y-tick-step: 0.4, legend: "inner-north-west",
        {
          plot.add(pkt(d.train), label: [Training], style: (stroke: blau + 1.3pt))
          plot.add(pkt(d.val), label: [Validierung, ohne Regularisierung], style: (stroke: orange + 1.3pt))
          plot.add(pkt(d.l2_val), label: [Validierung, L2], style: (stroke: gruen + 1.3pt))
          plot.add-vline(d.beste, style: (stroke: (paint: luma(90), dash: "dashed", thickness: 1pt)))
        },
      )
    }))
  },
  caption: [Overfitting im ersten der fünf Durchläufe. Der Trainings-Loss sinkt weiter, der Validierungs-Loss erreicht in Epoche 96 sein Minimum (gestrichelt, 0,754) und steigt dann auf 1,13. Mit L2-Strafterm (grün) bleibt er deutlich niedriger.],
) <abb-overfit>

Die Kurven in @abb-overfit sind das Lehrbuchbild: Der Trainings-Loss fällt auf 0,09, der Validierungs-Loss dreht ab Epoche 96 nach oben. Das Netz passt sich zunehmend dem Rauschen der 60 Beispiele an. Drei Gegenmittel sind verbreitet:

- *Early Stopping* hält das Training dort an, wo der Validierungs-Loss am niedrigsten ist @prechelt_early_stopping_1998. Praktisch läuft das Training weiter, bis sich der Validierungs-Loss einige Epochen lang nicht verbessert hat, und man behält den besten Stand; genau das macht der Checkpoint `best` in Pattern 12.
- *L2-Regularisierung* (weight decay) addiert zum Loss den Strafterm $lambda slash 2 dot sum w^2$. Im Gradienten steckt dann zusätzlich $lambda w$, und jeder Schritt zieht jedes Gewicht ein kleines Stück zum Nullpunkt: $w arrow.l (1 - eta lambda) w - eta g$. Kleine Gewichte ergeben glattere Funktionen, die dem Rauschen weniger folgen können.
- *Dropout* schaltet beim Training bei jedem Schritt zufällig einen Teil der Neuronen einer Schicht ab, hier 30 %, und skaliert die übrigen hoch, damit der Erwartungswert gleich bleibt. Kein Neuron kann sich darauf verlassen, dass ein bestimmtes anderes mitarbeitet, und das Netz lernt redundantere Merkmale @srivastava_dropout_2014. Bei der Vorhersage ist Dropout aus. Wer Chaos Engineering kennt, erkennt die Idee wieder: Man lässt im Training absichtlich Teile ausfallen, damit das Ganze nicht von einem einzelnen abhängt.

#figure(
  {
    let t = json("../code/02b/out/regularisierung.json").tabelle
    let pm(m, s, n) = [#z(m, n: n) #sym.plus.minus #z(s, n: n)]
    table(
      columns: (auto, auto, auto, auto), align: (left, right, right, right),
      table.header([Variante], [Trainings-Loss], [Test-Loss], [Test-Genauigkeit]),
      ..t.map(r => (r.at(0), z(r.at(1)), pm(r.at(2), r.at(3), 3), pm(r.at(4), r.at(5), 3))).flatten(),
    )
  },
  caption: [Ergebnis der vier Varianten, Mittel und Standardabweichung über fünf Durchläufe mit neu gezogenen Daten (`04_regularisierung.py`). Der Trainings-Loss bei Early Stopping gilt für den Stopp-Zeitpunkt.],
) <tab-regularisierung>

@tab-regularisierung zeigt zwei Dinge. Erstens senken alle drei Mittel den Test-Loss deutlich, am stärksten L2 (1,24 auf 0,72) und Early Stopping (auf 0,80), weniger Dropout (auf 0,96). Zweitens ändert sich die Genauigkeit kaum: Sie liegt bei 73 bis 74 %, nur beim Early Stopping mit 69 % darunter (dazu gleich mehr). Das Netz ohne Regularisierung sortiert nicht schlechter, es ist nur bei seinen Fehlern viel zu überzeugt, und die Cross-Entropy bestraft das, die Genauigkeit nicht. Overfitting zeigt sich im Loss oft früher und deutlicher als in der Genauigkeit; das hängt mit dem Befund zusammen, dass moderne Netze zu selbstsicheren Wahrscheinlichkeiten neigen @guo_calibration_2017. Wer Wahrscheinlichkeiten weiterverwendet, etwa für Schwellenwerte, sollte deshalb auf den Loss schauen. Der Ausreißer beim Early Stopping (Standardabweichung 0,096 in der Genauigkeit) kommt von einem der fünf Durchläufe, in dem das Validierungs-Minimum schon in Epoche 9 lag: Die Stopp-Epochen betrugen 96, 130, 9, 144 und 120. Ein einziges Minimum ist ein empfindliches Kriterium, und mit nur fünf Durchläufen und einem Rauschpegel sollte man L2 und Early Stopping nicht gegeneinander ausspielen; ihre Unterschiede liegen innerhalb einer Standardabweichung.

Regularisierung ist kein Dogma: Pattern 11 beschreibt den Fall, in dem man bewusst überanpasst, weil die Daten das gesamte Problem abdecken und es nichts zu verallgemeinern gibt. Dass große Netze trotz perfekter Anpassung an Trainingsdaten oft gut verallgemeinern, ist ein eigenes Forschungsthema @zhang_rethinking_generalization_2017, das wir hier offenlassen.

== Embeddings sind Nachschlagetabellen

Bisher bestand die Eingabe aus Zahlen. Wörter, Produkt-IDs und Nutzerkennungen sind keine; man muss sie erst in Zahlen übersetzen. Der naheliegende Weg ist die One-Hot-Kodierung: Bei einem Vokabular aus $V$ Wörtern bekommt jedes Wort einen Vektor der Länge $V$ mit einer 1 an seiner eigenen Position und sonst nur Nullen. Ein Embedding ersetzt diesen langen, dünn besetzten Vektor durch einen kurzen, dichten, dessen Werte das Netz selbst lernt. Pattern 2 zeigt, wann das nützt. Hier geht es um die Mechanik, und die ist schlicht.

Eine Embedding-Schicht ist eine Gewichtsmatrix $E$ mit einer Zeile pro Wort und $d$ Spalten. Multipliziert man den One-Hot-Vektor eines Worts mit $E$, passiert Folgendes: Die Eins wählt aus der Summe über alle Zeilen genau eine aus, alle anderen werden mit null multipliziert. Das Ergebnis ist die Zeile des Worts, nichts weiter (@abb-emb-lookup).

#figure(
  kind: image,
  {
    let E = ((0.9, 0.1, -0.3), (0.8, 0.2, -0.4), (-0.5, 0.9, 0.2), (-0.4, 0.8, 0.3), (0.1, -0.7, 0.9))
    let w = ("drucker", "scanner", "passwort", "login", "vpn")
    let num(x) = str(x).replace(".", ",").replace("-", "−")
    let zellen = ()
    for (i, name) in w.enumerate() {
      let aktiv = i == 3
      let f = if aktiv { blau-hell } else { none }
      let c = if aktiv { black } else { luma(150) }
      zellen.push(table.cell(fill: f, text(fill: c, raw(name))))
      zellen.push(table.cell(fill: f, text(fill: c, weight: if aktiv { "bold" } else { "regular" }, if aktiv { [1] } else { [0] })))
      for v in E.at(i) { zellen.push(table.cell(fill: f, text(fill: c, num(v)))) }
    }
    table(
      columns: (auto, auto, 3.2em, 3.2em, 3.2em), align: (left, center, right, right, right),
      table.header([Wort], [One-Hot], [$d_1$], [$d_2$], [$d_3$]),
      ..zellen,
      table.cell(fill: gruen-hell, [*Summe* (one-hot $times E$)]), table.cell(fill: gruen-hell, []),
      table.cell(fill: gruen-hell, [*#num(-0.4)*]), table.cell(fill: gruen-hell, [*#num(0.8)*]), table.cell(fill: gruen-hell, [*#num(0.3)*]),
    )
  },
  caption: [Die Rechnung one-hot $times E$ für das Wort `login`. Jede Zeile von $E$ wird mit der Zahl in der Spalte „One-Hot“ multipliziert, anschließend addiert man alle Zeilen. Übrig bleibt die Zeile von `login`, als wäre sie nachgeschlagen worden.],
) <abb-emb-lookup>

Die Ausgabe von `05_embedding_lookup.py` bestätigt, dass `one_hot @ E` und `E[idx]` dasselbe Ergebnis liefern, und dass der Gradient der Tabelle nur in einer Zeile von null verschieden ist:

#ausgabe("uv run --with numpy python 05_embedding_lookup.py", "../code/02b/out/05_embedding_lookup.out.txt", von: 0, bis: 12)

Für das Training ist der zweite Teil der Ausgabe der wichtigere. Kommt von der nächsten Schicht ein Gradient $("0,5"; -"1,0"; "2,0")$ an, dann erhält nur die Zeile von `login` diesen Gradienten, alle anderen Zeilen bekommen null. Pro Beispiel wird also nur ein winziger Teil der Tabelle verändert. Daraus folgen drei praktische Dinge:

- *Embedding-Schichten werden als Nachschlagen implementiert*, nicht als Matrixmultiplikation. Bei 50 000 Wörtern und 300 Dimensionen wären es 15 Millionen Multiplikationen, davon 14 999 700 mit null, gegenüber dem Kopieren von 300 Werten.
- *Selten gesehene Wörter bekommen selten Updates* und deshalb oft schlechte Vektoren. Das ist die Kehrseite des sparsamen Lernens.
- *Die Tabelle ist der größte Teil des Modells*, wenn das Vokabular groß ist: 50 000 mal 300 sind 15 Millionen Gewichte oder 60 MB in float32, bei einer Million Wörtern 1,2 GB. Pattern 1 (Hashed Feature) begrenzt $V$ genau aus diesem Grund.

Für Software Engineers ist das eine vertraute Konstruktion: Ein Array-Zugriff `E[i]` oder ein Dictionary-Lookup, nur dass die Werte nicht fest sind, sondern Parameter, durch die ein Gradient fließen kann. Alles, was ein Embedding „weiß“, steht in diesen Zahlen, und wie sie zustande kommen, ist im Grunde einfach: Sie werden zufällig initialisiert und dann wie jedes andere Gewicht per Backpropagation verändert, sodass sie der Aufgabe des Netzes dienen. Bei einer Klassifikation heißt das: Wörter, die zu ähnlichen Vorhersagen führen sollen, rücken zusammen. Die Tabelle enthält also keine eingebaute Bedeutung, sondern eine Verdichtung dessen, was die Trainingsaufgabe verlangt. Es gibt aber eine Aufgabe, die so allgemein ist, dass ihre Embeddings für viele andere Aufgaben taugen. Das ist die Vorhersage von Nachbarwörtern.

== word2vec: Bedeutung aus Nachbarschaft

Die Idee hinter word2vec ist, dass Wörter, die in ähnlichen Umgebungen vorkommen, ähnliche Bedeutung haben. Mikolov und Kollegen formulierten daraus 2013 zwei einfache Netze: CBOW sagt ein Wort aus seiner Umgebung voraus, *Skip-Gram* umgekehrt die Umgebung aus einem Wort @mikolov_word2vec_2013. Wir betrachten Skip-Gram. Das Netz bekommt ein Wort (das Mittelwort) und soll die Wörter in einem Fenster davor und danach erraten. Dazu werden aus dem Text Trainingspaare gebildet (@abb-skipgram-paare).

#figure(
  kind: image,
  {
    text(size: 9pt, diagram(
      node-inset: 5pt, node-corner-radius: 3pt, spacing: (12mm, 12mm),
      neben((0, 0), [`der`]), knoten((1, 0), [`drucker`]), neben((2, 0), [`ist`]), neben((3, 0), [`papierstau`]), neben((4, 0), [`und`]), neben((5, 0), [`toner`]),
      edge((1, 0), (0, 0), "->", bend: 60deg, stroke: gruen), edge((1, 0), (2, 0), "->", bend: -60deg, stroke: gruen), edge((1, 0), (3, 0), "->", bend: -45deg, stroke: gruen),
    ))
    v(2pt)
    text(size: 8.5pt, fill: grau)[Paare für das Mittelwort `drucker` (Fenster $plus.minus 2$): (`drucker`, `der`), (`drucker`, `ist`), (`drucker`, `papierstau`). `toner` liegt mit Abstand 4 außerhalb.]
  },
  caption: [Aus einem Satz entstehen Paare aus Mittelwort und Nachbarwort. Ein Satz mit sechs Wörtern liefert bei Fenster $plus.minus 2$ insgesamt 18 Paare.],
) <abb-skipgram-paare>

Die Architektur ist die des vorigen Abschnitts plus eine Ausgabeschicht (@abb-skipgram-netz). Das Mittelwort wird per Lookup in der Tabelle $E_"ein"$ (Größe $V times d$) in einen Vektor $h$ der Länge $d$ übersetzt. Eine zweite Matrix $E_"aus"$ ($d times V$) macht daraus einen Logit pro Wort des Vokabulars, und ein Softmax über alle $V$ Wörter liefert die Wahrscheinlichkeit, dass das jeweilige Wort in der Nähe steht. Der Loss ist die Cross-Entropy gegenüber dem tatsächlichen Nachbarwort. Es gibt keine versteckte Schicht mit Aktivierung, die ganze Rechnung ist ein Lookup und eine Matrixmultiplikation. Nach dem Training verwirft man die Aufgabe, denn die Vorhersage von Nachbarwörtern ist nicht das Ziel. Behalten wird die Tabelle $E_"ein"$: Ihre Zeilen sind die Wortvektoren.

#figure(
  text(size: 9pt, diagram(
    node-inset: 5pt, node-corner-radius: 3pt, spacing: (8mm, 14mm),
    neben((0, 0), [Mittelwort \ #text(size: 8.5pt, fill: grau)[`drucker` als Index]]),
    knoten((1, 0), [Lookup in $E_"ein"$ \ #text(size: 8.5pt, fill: grau)[$V times d$]]),
    knoten((2, 0), [Vektor $h$ \ #text(size: 8.5pt, fill: grau)[Länge $d$]], farbe: gruen, grund: gruen-hell),
    knoten((3, 0), [$z = h E_"aus"$ \ #text(size: 8.5pt, fill: grau)[ein Logit je Wort]]),
    knoten((4, 0), [Softmax über $V$ \ #text(size: 8.5pt, fill: grau)[$p$(Nachbar = Wort)]], farbe: orange, grund: orange-hell),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"), edge((3, 0), (4, 0), "->"),
  )),
  caption: [Skip-Gram als Netz. Die Vorhersageaufgabe dient nur dazu, die Tabelle $E_"ein"$ zu trainieren; sie wird nach dem Training behalten und ist das eigentliche Ergebnis.],
) <abb-skipgram-netz>

Der Haken ist der Softmax: Er rechnet über alle $V$ Wörter, bei einem Vokabular von einer Million also einer Million Exponentialfunktionen pro Trainingspaar. Mikolov et al. umgehen das auf zwei Arten: mit einem hierarchischen Softmax und mit *Negative Sampling*, bei dem das Modell pro Paar nur den echten Nachbarn von einigen zufällig gezogenen Wörtern unterscheiden muss @mikolov_distributed_2013. Unser Beispiel verwendet den vollen Softmax, weil das Vokabular mit 27 Wörtern winzig ist und der Mechanismus so am klarsten bleibt. Der Korpus besteht aus 600 erfundenen Helpdesk-Sätzen der Form „der \<Gegenstand\> ist \<Meldung\> und \<Meldung\>“ aus drei Themen: Hardware (`drucker`, `scanner`, `papierstau`, `toner` …), Zugang (`passwort`, `login`, `gesperrt` …) und Netz (`vpn`, `router`, `timeout` …). Jeder Satz hat genau einen Gegenstand. Das Skript bildet die Paare mit einer Schleife über alle Sätze und Fensterpositionen, was zu 10 800 Trainingspaaren führt; der Kern des Trainings ist:

#code-aus("../code/02b/06_skipgram.py", "W_ein = rng.normal", bis: "    if epoche in")

Die Zeile `np.add.at(W_ein, c, …)` ist der Lookup rückwärts: Der Gradient wird nur auf die Zeilen der Mittelwörter im Batch geschrieben, und `add.at` summiert ihn richtig auf, wenn dasselbe Wort mehrmals im Batch steht. Das Ergebnis:

#ausgabe("uv run --with numpy python 06_skipgram.py", "../code/02b/out/06_skipgram.out.txt", bis: 14)

Die Kosinus-Ähnlichkeit zweier Vektoren, der Kosinus des Winkels zwischen ihnen, ist 1, wenn sie in dieselbe Richtung zeigen, und 0, wenn sie senkrecht stehen. `drucker` und `scanner` erreichen 0,98, obwohl sie in keinem einzigen Satz gemeinsam vorkommen. Das Netz hat sie nicht aus gemeinsamem Auftreten ähnlich gemacht, sondern weil beide dieselben Nachbarn vorhersagen müssen (`papierstau`, `toner`, `ist` …), und das erzwingt ähnliche Vektoren. Dasselbe gilt für `passwort` und `login` (1,00) oder `vpn` und `router` (0,99). Wörter verschiedener Themen liegen weiter auseinander (0,40 und 0,46 für zwei Gegenstände, 0,21 für die Meldungen `toner` und `gesperrt`), aber nicht bei null, weil alle Sätze dieselben Funktionswörter `der`, `ist` und `und` enthalten und die Vektoren daher einen gemeinsamen Anteil haben. In einer zweidimensionalen Projektion (@abb-skipgram-karte) erkennt man die sechs Gruppen: je Thema die Gegenstände und die Meldungen.

#figure(
  placement: auto,
  {
    let d = json("../code/02b/out/skipgram.json")
    let farben = (hardware: blau, zugang: orange, netz: gruen, funktion: luma(120))
    let gruppen = (
      ("hardware", true, [drucker, scanner, \ monitor, tastatur], (0.7, -2.55)),
      ("hardware", false, [papierstau, toner, \ kabelbruch, defekt], (-1.3, -1.0)),
      ("zugang", true, [passwort, login, \ konto, token], (0.45, -1.0)),
      ("zugang", false, [gesperrt, abgelaufen, \ zurückgesetzt, ungültig], (-2.0, 2.0)),
      ("netz", true, [vpn, wlan, \ router, proxy], (1.95, 1.25)),
      ("netz", false, [getrennt, langsam, \ timeout, instabil], (0.45, 2.9)),
    )
    text(size: 8.5pt, canvas({
      plot.plot(
        size: (11.5, 7), x-min: -3.2, x-max: 3.4, y-min: -3.1, y-max: 3.4, x-tick-step: none, y-tick-step: none,
        x-label: [erste Hauptkomponente], y-label: [zweite],
        {
          for (g, gegenstand, beschriftung, pos) in gruppen {
            plot.add(
              d.filter(w => w.gruppe == g and w.subjekt == gegenstand).map(w => (w.x, w.y)),
              mark: if gegenstand { "o" } else { "square" }, mark-size: 0.17, mark-style: (fill: farben.at(g), stroke: white + 0.5pt), style: (stroke: none),
            )
            plot.annotate({ draw.content(pos, align(center, text(fill: farben.at(g), beschriftung))) })
          }
          plot.add(d.filter(w => w.gruppe == "funktion").map(w => (w.x, w.y)), mark: "triangle", mark-size: 0.17, mark-style: (fill: luma(120), stroke: white + 0.5pt), style: (stroke: none))
          plot.annotate({
            draw.content((-1.51, 0.5), text(fill: luma(100))[der])
            draw.content((-0.01, 0.35), text(fill: luma(100))[ist])
            draw.content((1.3, -0.4), text(fill: luma(100))[und])
          })
        },
      )
    }))
  },
  caption: [Die 27 Wortvektoren aus `06_skipgram.py`, per Hauptkomponentenanalyse auf zwei Dimensionen projiziert (59 % der Streuung bleiben erhalten). Kreise: Gegenstände, Quadrate: Meldungen, Dreiecke: Funktionswörter. Wörter desselben Themas und derselben Rolle liegen praktisch übereinander; die Funktionswörter `der`, `ist` und `und` stehen dazwischen.],
) <abb-skipgram-karte>

Im Kleinen zeigt das, was Mikolov et al. an Milliarden von Wörtern beobachteten: Die Vektoren fassen Ähnlichkeit in Zahlen, und sie tragen Beziehungen, die man mit Vektorrechnung herausholen kann. Ihr bekanntestes Beispiel, das auch die Originalarbeit erwähnt, ist, dass der Vektor von „King“ minus „Man“ plus „Woman“ dem von „Queen“ am nächsten liegt @mikolov_word2vec_2013. Das lässt sich mit unserem winzigen Korpus nicht nachstellen, und wir behaupten es deshalb nur als berichtetes Ergebnis. Eine Warnung gehört dazu: Die Vektoren übernehmen auch Verzerrungen ihrer Trainingstexte, etwa Geschlechterstereotype bei Berufen @bolukbasi_debiasing_2016; Pattern 30 behandelt Verzerrungen allgemein. Und das Konzept ist nicht auf Wörter beschränkt. Wer Produkte, Nutzer oder Filialen als „Wörter“ und Warenkörbe oder Sitzungen als „Sätze“ behandelt, bekommt Embeddings für beliebige Kategorien; Guo und Berkhahn lernen sie direkt als Eingabeschicht eines überwachten Netzes @guo_entity_embeddings_2016. Das ist die Grundlage von Pattern 2.

== Vortrainierte Modelle und Transfer Learning

Warum sollte es etwas nützen, ein Netz zuerst auf einer Aufgabe zu trainieren und dann auf einer anderen weiterzuverwenden? Weil die versteckten Schichten Repräsentationen berechnen, und manche davon sind nicht an die ursprüngliche Aufgabe gebunden. Am besten untersucht ist das bei Bildern. Ein Netz, das Fotos klassifiziert, lernt in den ersten Schichten Detektoren für Kanten und Farbübergänge, in mittleren Schichten Texturen und wiederkehrende Muster, in späteren Teile von Objekten und erst in der letzten Schicht die Klassen @zeiler_visualizing_2014. Kanten gibt es in jedem Foto, ob es einen Hund oder ein Auto zeigt; die Klasse „Dackel“ dagegen ist nur für die ursprüngliche Aufgabe nützlich. Yosinski und Kollegen formulieren diese Beobachtung als Unterscheidung zwischen *allgemeinen* Merkmalen der unteren und *aufgabenspezifischen* Merkmalen der oberen Schichten @yosinski_transferability_2014.

#figure(
  placement: auto,
  text(size: 9pt, diagram(
    node-inset: 5pt, node-corner-radius: 3pt, spacing: (13mm, 12mm),
    neben((0, 0), [Pixel]),
    knoten((1, 0), [Kanten, \ Farbflecken]), knoten((2, 0), [Texturen, \ Muster]),
    knoten((3, 0), [Objektteile], farbe: orange, grund: orange-hell), knoten((4, 0), [Klassen \ #text(size: 8.5pt, fill: grau)[(Ausgabe)]], farbe: orange, grund: orange-hell),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"), edge((3, 0), (4, 0), "->"),
    edge((0, 1), (2, 1), "|-|", stroke: gruen, label: text(fill: gruen)[allgemein: übertragbar], label-side: right, label-sep: 4pt),
    edge((3, 1), (4, 1), "|-|", stroke: orange, label: text(fill: orange)[aufgabenspezifisch], label-side: right, label-sep: 4pt),
    edge((2.5, 0.55), (2.5, -0.55), "--", stroke: luma(100), label: text(size: 8.5pt, fill: grau)[trennen], label-side: left, label-pos: 100%, label-sep: 2pt),
  )),
  caption: [Feature-Hierarchie eines Bildnetzes. Die unteren Schichten berechnen Merkmale, die für viele Aufgaben taugen; die oberen sind auf die Ausgangsaufgabe zugeschnitten. Beim Transfer Learning behält man die Basis und ersetzt den Kopf. Der Übergang zwischen allgemein und spezifisch ist fließend; die Trennlinie ist schematisch.],
) <abb-hierarchie>

Daraus ergibt sich das Vorgehen, das Pattern 13 beschreibt: Man nimmt ein Netz, das auf einer großen Aufgabe trainiert wurde, behält die unteren Schichten (die *Basis*), ersetzt die letzte Schicht durch eine neue für die eigene Aufgabe (den *Kopf*) und trainiert dann entweder nur den Kopf oder alles weiter, das Letztere mit einer kleinen Lernrate (*Feintuning*). Mechanisch sind das zwei Handgriffe: Die Schichten der Basis bekommen kein Update (`eingefroren`), und die Ausgabeschicht wird neu initialisiert (`neuer_kopf`):

#code-aus("../code/02b/07_transfer.py", "netz = copy.deepcopy(vor)", bis: "trainiere(netz, ziel_pool")

Yosinski et al. haben das in einem ImageNet-Netz systematisch vermessen, indem sie die 1000 Klassen in zwei Hälften teilten, auf der einen Hälfte trainierten und die Schichten für die andere übertrugen. Ihre Ergebnisse lassen sich so zusammenfassen: Die Übertragbarkeit sinkt, wenn man höhere Schichten überträgt und wenn die beiden Aufgaben weiter auseinanderliegen. Ein zweiter, unerwarteter Effekt kommt hinzu: Schneidet man ein Netz mitten durch eng aufeinander abgestimmte Schichten, die sich beim Training aneinander angepasst haben, leidet die Leistung, solange die übertragenen Schichten eingefroren bleiben; Feintuning gleicht das großenteils aus. Übertragene Merkmale sind aber selbst von weit entfernten Aufgaben besser als zufällige. Und wer mit übertragenen Gewichten startet und sie weitertrainiert, erhält eine bessere Verallgemeinerung als beim Start von null, selbst nach langem Feintuning.

Kann man das im Kleinen nachvollziehen? `07_transfer.py` tut es auf den 8×8-Ziffernbildern aus scikit-learn (1797 Bilder, 64 Pixel). Ein Netz 64–64–32–Klassen wird auf einer Quellaufgabe vortrainiert; dann bekommt die Zielaufgabe nur wenige beschriftete Beispiele pro Klasse. Verglichen werden vier Varianten: von Grund auf trainiert, zufällig initialisiert mit eingefrorenen versteckten Schichten (die Kontrolle: Was leistet der Kopf auf reinen Zufalls-Merkmalen?), vortrainiert mit eingefrorener Basis und vortrainiert mit Feintuning. Wir testen zwei Fälle, und das Ergebnis des ersten ist ernüchternd.

#figure(
  placement: auto,
  {
    let d = json("../code/02b/out/transfer.json")
    let serien = (("von Grund auf", orange), ("zufällig, eingefroren", luma(130)), ("vortrainiert, eingefroren", blau), ("vortrainiert, feinjustiert", gruen))
    let panel(schluessel, titel) = text(size: 8.5pt, {
      align(center, text(weight: "bold")[#titel])
      canvas({
        plot.plot(
          size: (6.4, 4.0), x-label: [beschriftete Beispiele je Klasse], y-label: [Genauigkeit],
          x-min: -0.2, x-max: 4.2, y-min: 0.4, y-max: 1.0, x-tick-step: none, x-ticks: ((0, [1]), (1, [2]), (2, [5]), (3, [10]), (4, [30])), y-tick-step: 0.1,
          for (name, f) in serien {
            plot.add(d.at(schluessel).at(name).enumerate(), mark: "o", mark-size: 0.1, mark-style: (fill: f, stroke: none), style: (stroke: f + 1.3pt))
          },
        )
      })
    })
    align(center, text(size: 8.5pt, serien.map(((name, f)) => box(width: 1.3em, height: 0.35em, fill: f) + h(0.3em) + name).join(h(1.2em))))
    v(-2pt)
    grid(columns: (1fr, 1fr), column-gutter: 4pt, panel("fern", [Ferner Transfer: Ziffern 0–4 → 5–9]), panel("nah", [Naher Transfer: Ziffern → gerade/ungerade]))
  },
  caption: [Genauigkeit auf ungesehenen Testbildern in Abhängigkeit von der Zahl beschrifteter Zielbeispiele je Klasse, Mittel über 20 Wiederholungen. Links hilft das Vortraining nicht, rechts hilft es besonders bei wenigen Beispielen.],
) <abb-transfer>

Im ersten Fall ist die Quelle „Ziffern 0 bis 4“ und das Ziel „Ziffern 5 bis 9“: andere Klassen, gleiche Art von Bildern. Hier gewinnt das Training von Grund auf in jeder Zeile (links in @abb-transfer): Bei zehn Beispielen je Klasse erreicht es 93,2 %, die vortrainierte Basis mit Feintuning 89,9 %, mit eingefrorener Basis nur 75,5 %, und selbst die zufällige, eingefrorene Basis (79,0 %) ist besser als die vortrainierte, eingefrorene. Eine plausible, hier nicht geprüfte Erklärung: Mit rund 900 Quellbeispielen und einem Netz auf rohen Pixeln lernt es eher Prototypen der Ziffern 0 bis 4 als Strichdetektoren, die für 5 bis 9 taugen. Das ist kein Widerspruch zu Yosinski et al., aber eine Mahnung, dass Transfer nicht automatisch funktioniert: Er braucht eine Quelle, deren Merkmale wirklich allgemein sind, und das erreicht man mit viel Daten und Faltungsschichten, nicht mit 900 Mini-Bildern.

Im zweiten Fall bleibt die Eingabe dieselbe, aber die Frage ändert sich: Das Netz wird zuerst auf allen zehn Ziffern trainiert und soll dann nur noch „gerade oder ungerade“ entscheiden, mit sehr wenigen Beispielen (rechts in @abb-transfer). Das ist die Konstellation, in der ein vortrainiertes Netz in der Praxis meist eingesetzt wird: gleiche Art von Eingabe, neue Frage. Bei einem Beispiel je Klasse erreicht die eingefrorene Basis 69,0 % gegenüber 58,3 % von Grund auf und 57,7 % mit zufälliger Basis; bei zehn Beispielen sind es 85,6 % gegenüber 82,0 % und 71,5 %. Der Vorsprung schrumpft mit mehr Beispielen (bei 30 je Klasse 89,2 % gegenüber 88,1 %, und mit Feintuning 90,6 %), und ob der Abstand von etwa einem Prozentpunkt mehr ist als Zufall, lässt sich aus 20 Wiederholungen ohne Streuungsangabe nicht sagen. Beides entspricht der Erwartung: Vortraining ersetzt fehlende Daten, nicht vorhandene. Dass die zufällige Basis klar schlechter ist als die vortrainierte, belegt, dass die übertragenen Schichten tatsächlich etwas Nützliches berechnen.

#achtung[Dieses Experiment ist ein Lehrmodell, kein Benchmark: ein einziger kleiner Datensatz, ein einziges Netz, 20 Wiederholungen. Es zeigt zwei Mechanismen (Einfrieren und neuer Kopf) und dass der Nutzen von der Nähe der Aufgaben abhängt. Die Größenordnungen echter Bild- und Textmodelle liegen weit darüber, und das Ergebnis des ersten Falls darf man nicht auf sie übertragen.]

Embeddings und Transfer Learning sind übrigens dasselbe Prinzip in verschiedenen Größen. Lädt man die word2vec-Vektoren als Anfangswerte einer Embedding-Schicht, überträgt man die gelernte Tabelle in ein neues Netz. Große Sprachmodelle machen es mit allen Schichten: Sie werden auf riesigen Textmengen vortrainiert und anschließend für eine konkrete Aufgabe feinjustiert @devlin_bert_2019.

== Checkpoints: was zum Zustand gehört

Ein Checkpoint hält den Zustand eines Trainings fest, damit man es später an derselben Stelle fortsetzen kann (Pattern 12). Jetzt, da wir das Netz kennen, lässt sich genau sagen, was zu diesem Zustand gehört: die Gewichte und Biaswerte, der Schwung des Optimierers (bei uns die Momentum-Geschwindigkeiten, bei Adam zwei weitere Werte je Parameter, sodass ein Adam-Checkpoint etwa dreimal so groß ist wie die Gewichte allein @kingma_adam_2015), der Epochen- oder Schrittzähler und der Zustand des Zufallsgenerators, der die Reihenfolge der Beispiele bestimmt. Fehlt etwas davon, setzt man nicht dieselbe Rechnung fort, sondern eine andere. `08_checkpoint_parallel.py` trainiert 20 Epochen, sichert den Zustand in zwei Dateien, lädt ihn in ein frisches Netz und trainiert 20 weitere Epochen. Als Referenz dient ein Lauf über 40 Epochen am Stück:

#code-aus("../code/02b/08_checkpoint_parallel.py", "alles = {}", bis: "print(\"Checkpoint-Dateien")

#ausgabe("uv run --with numpy python 08_checkpoint_parallel.py", "../code/02b/out/08_checkpoint_parallel.out.txt", bis: 6)

Mit vollständigem Zustand stimmen die Parameter exakt überein (Differenz 0, Bit für Bit). Lässt man den Optimierer-Zustand weg, weichen sie um bis zu $5 dot 10^(-2)$ ab, lässt man den Zufallsgenerator weg, um $8 dot 10^(-2)$. Das sind kleine Unterschiede, die das Training trotzdem gut abschließen kann; nachgemessen haben wir das hier nicht. Für Experimente, die man vergleichen will, ist es aber ein Unterschied zwischen reproduzierbar und nicht reproduzierbar. Auch das Prinzip kennen Sie: Das ist das Memento-Muster der Gang of Four @gamma_design_patterns_1994, ein Objekt sichert seinen inneren Zustand nach außen und lässt ihn später wiederherstellen. Wer nur ein fertiges Modell ausliefert, braucht dagegen die Gewichte samt Architektur und Vorverarbeitung; Optimierer und Zufallsgenerator sind dann entbehrlich.

== Hardware und Verteilung: warum Batches, warum GPUs

Fast die gesamte Rechenarbeit eines Netzes sind Matrixmultiplikationen. Eine Schicht mit $m$ Eingängen und $n$ Neuronen braucht für einen Batch von $B$ Beispielen $2 B m n$ Gleitkommaoperationen (eine Multiplikation und eine Addition je Gewicht und Beispiel). Gleichzeitig müssen die $m n$ Gewichte aus dem Speicher geholt werden, unabhängig von $B$: bei float32 sind das $4 m n$ Bytes. Das Verhältnis, die *arithmetische Intensität*, beträgt für große Schichten ungefähr $B slash 2$ Operationen pro Byte. Bei $B = 1$ ruft der Prozessor eine große Matrix ab, um sie für ein einziges Beispiel zu benutzen, und wartet überwiegend auf den Speicher; erst bei großem $B$ wird die Rechenleistung zum Engpass. Das ist die Aussage des Roofline-Modells @williams_roofline_2009.

`09_durchsatz.py` misst das an einem Netz mit drei Schichten zu je $1024 times 1024$ (12,6 MB Gewichte, 6,3 MFLOP je Beispiel) auf der CPU des Autor-Rechners (Apple M3 Pro, numpy 2.5.4). Gemessen wird der Vorwärtsdurchlauf, jeweils die schnellste von 15 Messungen:

#figure(
  placement: auto,
  {
    let d = json("../code/02b/out/durchsatz.json")
    text(size: 9pt, canvas({
      plot.plot(
        size: (11.5, 3.8), x-label: [Batch-Größe], y-label: [Beispiele pro Sekunde (in Tausend)],
        x-min: -0.3, x-max: 10.3, y-min: 0, y-max: 160, x-tick-step: none, x-ticks: d.enumerate().map(((i, r)) => (i, [#r.batch])), y-tick-step: 40,
        {
          plot.add(d.enumerate().map(((i, r)) => (i, r.bps / 1000)), mark: "o", mark-size: 0.12, mark-style: (fill: blau, stroke: none), style: (stroke: blau + 1.4pt))
        },
      )
    }))
  },
  caption: [Durchsatz des Vorwärtsdurchlaufs eines 3 × (1024 × 1024)-Netzes in Abhängigkeit von der Batch-Größe, gemessen mit `09_durchsatz.py` auf einer Apple-M3-Pro-CPU. Die Werte sind maschinen- und lastabhängig und gelten als Größenordnung.],
) <abb-durchsatz>

Bei Batch 1 verarbeitet die Maschine rund 12 000 Beispiele pro Sekunde (77 GFLOP/s), bei Batch 1024 rund 146 000 (917 GFLOP/s), also etwa das Zwölffache pro Beispiel, mit derselben Hardware und denselben Gewichten. Die Kurve ist nicht ganz glatt (Batch 2 ist langsamer als Batch 1); die Ursache haben wir nicht untersucht. Wiederholt man den Lauf, weichen die Werte um einige Prozent ab (bei der Gegenprobe 11 300 und 141 000 Beispiele pro Sekunde), der Verlauf bleibt derselbe. Eine GPU treibt dieses Prinzip weiter: Sie hat sehr viele einfache Rechenwerke, die Matrixprodukte parallel ausführen, und eine hohe Speicherbandbreite. Voll ausgelastet ist sie nur, wenn jeder Aufruf genug Arbeit enthält, also mit großen Batches. Das erklärt, warum man Mini-Batches nicht nur wegen der Gradienten, sondern auch wegen der Hardware verwendet, und warum Batch 1 im Training selten sinnvoll ist. Bei der Vorhersage im Betrieb gilt dasselbe, sodass man dort Anfragen sammelt und gebündelt abarbeitet.

Aber Batches wachsen nicht beliebig. Die Zwischenwerte des Vorwärtsdurchlaufs, die Backpropagation später braucht, wachsen mit der Batch-Größe, und irgendwann ist der Speicher des Geräts voll. Dann bleibt nur, die Arbeit auf mehrere Geräte zu verteilen, die *Datenparallelität* (Pattern 14): Jeder Worker besitzt eine vollständige Kopie des Netzes und bearbeitet einen Teil des Batches (@abb-parallel). Die Gradienten der Worker werden gemittelt, und jeder führt denselben Schritt aus.

#figure(
  placement: auto,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (12mm, 7mm),
    neben((0, 1.5), [Mini-Batch \ #text(size: 8.5pt, fill: grau)[256 Beispiele]]),
    ..range(4).map(i => knoten((1, i), [Worker #(i + 1) \ #text(size: 8.5pt, fill: grau)[64 Beispiele $arrow.r$ Gradient $g_#(i + 1)$]])),
    ..range(4).map(i => edge((0, 1.5), (1, i), "->", bend: 0deg)),
    knoten((2, 1.5), [Mittelwert \ #text(size: 8.5pt, fill: grau)[$g = 1/4 sum g_k$ \ (All-Reduce)]], farbe: orange, grund: orange-hell),
    ..range(4).map(i => edge((1, i), (2, 1.5), "->")),
    knoten((3, 1.5), [gleicher Schritt \ #text(size: 8.5pt, fill: grau)[$w arrow.l w - eta g$ \ auf jedem Worker]], farbe: gruen, grund: gruen-hell),
    edge((2, 1.5), (3, 1.5), "->"),
  )),
  caption: [Synchrone Datenparallelität mit vier Workern. Nach dem Mitteln besitzen alle Worker dieselben Parameter, als hätte ein einziges Gerät den ganzen Batch verarbeitet.],
) <abb-parallel>

Ob das Mitteln eine Näherung ist, lässt sich nachrechnen, und die Antwort lautet: nein. Der Loss ist ein Mittelwert über die Beispiele; der Gradient eines Mittelwerts ist das Mittel der Gradienten, und das Mittel über vier Viertel ist das Mittel über das Ganze. Der zweite Teil von `08_checkpoint_parallel.py` prüft es:

#code-aus("../code/02b/08_checkpoint_parallel.py", "shards = np.array_split", bis: "print(\"\\nGradient: ein Gerät")

#ausgabe("uv run --with numpy python 08_checkpoint_parallel.py", "../code/02b/out/08_checkpoint_parallel.out.txt", von: 7)

Die Abweichung von $3 dot 10^(-17)$ ist Rundungsrauschen, und nach 100 Schritten stimmen die Parameter eines Geräts und die der vier Worker bis auf $2 dot 10^(-16)$ überein. Zwei Feinheiten zeigt die mittlere Zeile: Bei ungleich großen Shards (100, 100 und 56 Beispiele) muss man nach Größe gewichten; ein einfaches Mittel der drei Gradienten weicht um $4 dot 10^(-3)$ ab, was im Training Verzerrungen erzeugt. Und der Mittelwert ist die einzige Stelle, an der die Worker miteinander reden müssen; wie diese Kommunikation organisiert wird, behandelt Pattern 14. Eine Folge sollten Sie kennen: Vier Worker mit je 64 Beispielen bilden einen effektiven Batch von 256. Goyal et al. empfehlen, die Lernrate bei $k$-facher Batch-Größe ebenfalls mit $k$ zu multiplizieren und sie am Anfang des Trainings schrittweise zu steigern (warm-up) @goyal_large_minibatch_2017. Man spart also nicht einfach Zeit, sondern ändert nebenbei die Trainingsdynamik.

== Ausblick: der Transformer

Die meisten heutigen Sprachmodelle sind Transformer. Wer dieses Kapitel gelesen hat, kennt fast alle Bausteine; neu ist einer, die *Self-Attention* @vaswani_attention_2017. Das Problem, das sie löst: Bei Text hängt die Bedeutung eines Wortes vom Kontext ab, und der Kontext kann weit entfernt liegen. Self-Attention lässt jedes Token (Wort oder Wortteil) von allen anderen Informationen übernehmen, gewichtet danach, wie relevant sie sind. Jedes Token wird dazu mit drei gelernten Matrizen in drei Vektoren übersetzt, $Q$ („wonach suche ich“), $K$ („was biete ich an“) und $V$ („was gebe ich weiter“). Die Ausgabe ist

$ "Attention"(Q, K, V) = "softmax"((Q K^top) / sqrt(d_k)) V. $

Wer ein Dictionary kennt, erkennt die Struktur wieder: Ein `get(key)` liefert den Wert zu genau einem passenden Schlüssel; Attention vergleicht die Anfrage mit *allen* Schlüsseln und liefert eine nach Ähnlichkeit gewichtete Mischung aller Werte. Der Softmax macht die Gewichte zu Wahrscheinlichkeiten, der Faktor $1 slash sqrt(d_k)$ hält die Skalarprodukte in einem Bereich, in dem der Softmax noch brauchbare Gradienten liefert. `10_attention.py` rechnet das für drei Tokens durch (@abb-attention).

#figure(
  {
    let tokens = ("der", "drucker", "streikt")
    let w = ((0.97, 0.00, 0.02), (0.15, 0.67, 0.17), (0.01, 0.79, 0.20))
    table(
      columns: (auto, 3.6em, 3.6em, 3.6em), align: (left, center, center, center), fill: none, stroke: none, inset: 5pt,
      [], ..tokens.map(t => table.cell(text(size: 8.5pt, raw(t)))),
      ..tokens.enumerate().map(((i, t)) => (
        table.cell(text(size: 8.5pt, raw(t))),
        ..w.at(i).map(x => table.cell(fill: blau.lighten(100% - x * 100% * 0.85), text(fill: if x > 0.5 { white } else { black }, size: 9pt, z(x, n: 2)))),
      )).flatten(),
    )
  },
  caption: [Attention-Gewichte für drei Tokens (Zeile: fragendes Token, Spalte: betrachtetes Token) aus `10_attention.py`, mit zufälligen Embeddings und Matrizen. Jede Zeile summiert sich zu 1 (Rundungsabweichungen möglich). Im trainierten Modell würden diese Gewichte aus Daten gelernt.],
) <abb-attention>

Ein Detail ist für das Verständnis wichtig: Self-Attention ist blind für die Reihenfolge. Sortiert man die Eingabe um, sortiert sich nur die Ausgabe um; `10_attention.py` prüft das mit `np.allclose` (Ergebnis `True`). Deshalb addiert man zu den Embeddings eine Information über die Position. Kosten entstehen quadratisch in der Länge: Bei $n$ Tokens ist die Gewichtsmatrix $n times n$, bei 1000 Tokens eine Million Einträge je Kopf und Schicht, bei 100 000 schon zehn Milliarden.

#figure(
  placement: auto,
  text(size: 9pt, diagram(
    node-inset: 4pt, node-corner-radius: 3pt, spacing: (9mm, 12mm),
    neben((0, 0), [Tokens]),
    knoten((1, 0), [Embedding \ #text(size: 8.5pt, fill: grau)[Lookup + Position]]),
    knoten((2, 0), [Self- \ Attention], farbe: orange, grund: orange-hell),
    knoten((3, 0), [Add + \ Norm]),
    knoten((4, 0), [MLP \ #text(size: 8.5pt, fill: grau)[2 Schichten]]),
    knoten((5, 0), [Add + \ Norm]),
    knoten((6, 0), [Softmax \ #text(size: 8.5pt, fill: grau)[Ausgabe]], farbe: gruen, grund: gruen-hell),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"), edge((3, 0), (4, 0), "->"), edge((4, 0), (5, 0), "->"), edge((5, 0), (6, 0), "->"),
    edge((1, 0), (3, 0), "->", bend: 45deg, stroke: (paint: luma(120), dash: "dashed")),
    edge((3, 0), (5, 0), "->", bend: 45deg, stroke: (paint: luma(120), dash: "dashed")),
    node(enclose: ((2, 0), (3, 0), (4, 0), (5, 0)), stroke: (paint: blau, dash: "dashed"), inset: 8pt, snap: false),
  )),
  caption: [Aufbau eines Transformers (vereinfacht, nur Stapel von Blöcken). Der blau gestrichelte Rahmen wird $N$-mal wiederholt, die grauen Bögen sind Residual-Verbindungen. Außer Self-Attention, Residual-Verbindungen und Normalisierung kommen alle Bausteine aus diesem Kapitel.],
) <abb-transformer>

Ein Block besteht aus Self-Attention und einem gewöhnlichen zweischichtigen MLP mit ReLU, jeweils mit Residual-Verbindung, also dem Addieren der Eingabe zur Ausgabe @he_resnet_2016, und einer Normalisierung der Werte @ba_layernorm_2016. Im ursprünglichen Modell werden mehrere Attention-Köpfe mit unterschiedlichen Matrizen parallel berechnet; die Basisversion hat 8 Köpfe, 6 Blöcke und Vektoren der Länge 512, das MLP hat 2048 Neuronen @vaswani_attention_2017. Dahinter steckt also keine neue Art von Maschine, sondern dieselbe Mechanik in anderer Verdrahtung: Embedding-Lookup am Eingang, Softmax und Cross-Entropy am Ausgang, Backpropagation und Adam im Training, Dropout als Regularisierung. Warum die Architektur sich durchgesetzt hat, hat einen praktischen Grund: Anders als bei rekurrenten Netzen, die Wort für Wort rechnen, lassen sich alle Positionen gleichzeitig als Matrixprodukte berechnen, und das passt zu der Hardware aus dem vorigen Abschnitt. Und Modelle wie BERT @devlin_bert_2019 sind genau das, was oben als Vortraining mit anschließendem Feintuning beschrieben wurde, nur eben mit Transformer-Blöcken. Was dieses Kapitel nicht behandelt, sind Faltungsnetze, rekurrente Netze und das Training großer Sprachmodelle; dafür sei auf die Literatur verwiesen.

== Das Wichtigste in Kürze

- Ein Neuron bildet eine gewichtete Summe plus Bias und wendet eine Nichtlinearität an; ohne sie fallen mehrere Schichten zu einer einzigen linearen zusammen. Ein Netz ist eine Folge solcher Schichten, jede Schicht eine Matrixmultiplikation.
- Softmax macht Logits zu Wahrscheinlichkeiten, die Cross-Entropy bestraft sichere Fehler hart; ihr Gradient nach den Logits ist einfach $p - y$.
- Backpropagation ist die Kettenregel in der richtigen Reihenfolge: ein Vorwärtsdurchlauf, der Zwischenwerte merkt, und ein Rückwärtsdurchlauf, der Gradienten durch die Schichten reicht. Ein Gradient Check mit Differenzenquotienten prüft eine eigene Implementierung.
- Im Trainingsprotokoll lassen sich Fehler ablesen: ein springender oder um den Raten-Wert pendelnder Loss deutet auf eine zu große Lernrate (tote ReLUs), ein kaum sinkender auf eine zu kleine. Läufe vergleicht man nach der Zahl der Schritte.
- Overfitting zeigt sich im Validierungs-Loss früher als in der Genauigkeit. Early Stopping, L2 und Dropout dämpfen es; auf stark verrauschten Daten senkten sie den Test-Loss deutlich, die Genauigkeit blieb ungefähr gleich.
- Eine Embedding-Schicht ist eine Gewichtsmatrix, deren Zeilen man nachschlägt; one-hot mal Matrix ergibt genau eine Zeile. Gelernt wird sie wie jedes Gewicht, aber pro Beispiel nur in einer Zeile.
- Skip-Gram trainiert eine Embedding-Tabelle durch die Vorhersage von Nachbarwörtern; Wörter mit ähnlichen Nachbarn bekommen ähnliche Vektoren, auch wenn sie nie gemeinsam auftreten.
- Transfer Learning überträgt Schichten, die allgemeine Merkmale berechnen, und trainiert einen neuen Kopf. Es hilft, wenn Quelle und Ziel verwandt sind und das Ziel wenige Beispiele hat; ein Beispiel im Kleinen zeigt auch den Fall, in dem es nicht hilft.
- Zum Zustand eines Trainings gehören Gewichte, Optimierer-Zustand, Zähler und Zufallsgenerator. Gradienten über Worker zu mitteln ist keine Näherung, sondern gleich dem Gradienten über den ganzen Batch. Große Batches nutzen Hardware besser aus, bis der Speicher endet.

#figure(
  table(
    columns: (auto, 1fr), align: (left, left),
    table.header([Mechanik aus diesem Kapitel], [taucht wieder auf in]),
    [Embedding als Lookup, Zeilenweises Lernen], [Pattern 2 (Embeddings), Pattern 4 (Multimodal Input); die Tabellengröße begrenzt Pattern 1 (Hashed Feature)],
    [Loss-Kurven, Early Stopping, Overfitting], [Pattern 11 (Useful Overfitting), Pattern 12 (Checkpoints)],
    [Zustand des Trainings], [Pattern 12 (Checkpoints), Pattern 27 (Model Versioning)],
    [Eingefrorene Basis, neuer Kopf], [Pattern 13 (Transfer Learning)],
    [Mitteln von Gradienten, Batch-Größe, Hardware], [Pattern 14 (Distribution Strategy)],
    [Lernrate, Batch-Größe, Epochen als Stellschrauben], [Pattern 15 (Hyperparameter Tuning)],
  ),
  caption: [Wo die Mechanik dieses Kapitels in den Patterns wiederkehrt.],
)

== Weiterführende Literatur

Als Lehrbuch für alles, was hier angerissen wurde, eignet sich Goodfellow, Bengio und Courville @goodfellow_deep_learning_2016, vor allem die Kapitel zu Feedforward-Netzen, Regularisierung, Optimierung und die „Practical Methodology“. Die Originalarbeit zur Backpropagation ist kurz und lesbar @rumelhart_backprop_1986. Zu Embeddings lohnt der Skip-Gram-Artikel selbst @mikolov_word2vec_2013 zusammen mit seiner Fortsetzung zu Negative Sampling @mikolov_distributed_2013. Zum Transfer Learning ist die Arbeit von Yosinski et al. @yosinski_transferability_2014 die verständlichste Grundlage, zur Architektur des Transformers der Originalartikel @vaswani_attention_2017. Regularisierung behandeln Prechelt @prechelt_early_stopping_1998 (Early Stopping) und Srivastava et al. @srivastava_dropout_2014 (Dropout). Wer die Hardwareseite vertiefen will, findet im Roofline-Artikel @williams_roofline_2009 ein Modell, das für Batch-Größen ebenso gilt wie für Algorithmen im Allgemeinen.

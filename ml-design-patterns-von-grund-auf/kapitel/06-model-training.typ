#import "../lib.typ": *
#import "@preview/cetz-plot:0.1.2": plot

#set figure(placement: auto)

#let gruen = rgb("#2EAE7D")
#let orange = rgb("#B5651D")
#let orange-hell = rgb("#FBF1E6")
#let gruen-hell = rgb("#E4F5EE")
#let nebel = luma(240)

// Ausschnitt aus einer Code-Datei: ab der ersten Zeile mit `ab` bis vor die erste folgende Zeile mit `bis`.
// Der gezeigte Code ist damit zeichengleich mit der ausgeführten Datei.
#let code-aus(datei, ab, bis: none) = {
  let zeilen = read(datei).split("\n")
  let a = zeilen.position(z => z.contains(ab))
  let b = if bis == none { zeilen.len() } else { a + 1 + zeilen.slice(a + 1).position(z => z.contains(bis)) }
  raw(zeilen.slice(a, b).join("\n").trim("\n", at: end), lang: "python", block: true)
}
// Echte Ausgabe eines Laufs als Konsolenfenster, davor der Befehl.
#let ausgabe(befehl, datei, von: 0, bis: none) = {
  let z = read(datei).trim("\n", at: end).split("\n")
  raw("$ " + befehl + "\n" + z.slice(von, bis).join("\n"), lang: "terminal", block: true)
}
#let knoten(pos, body, farbe: blau, grund: blau-hell, ..args) = node(pos, body, stroke: farbe, fill: grund, ..args)
#let neben(pos, body, ..args) = node(pos, body, stroke: 0.6pt + luma(150), fill: nebel, ..args)

= Model Training

Dieses Kapitel behandelt fünf Patterns, die alle um dieselbe Tätigkeit kreisen: das Trainieren eines Modells. Im Buch von Lakshmanan et al. @lakshmanan_ml_design_patterns_2020 stehen sie in Kapitel 4. Sie beantworten Fragen, die jeder stellt, der ein Training nicht nur einmal im Notebook, sondern verlässlich und wiederholt laufen lassen muss: Wann ist Overfitting ausnahmsweise erwünscht (Pattern 11)? Wie überlebt ein langes Training einen Absturz (Pattern 12)? Wie spart man sich das Training von Grund auf (Pattern 13)? Wie verteilt man es auf mehrere Rechner (Pattern 14)? Und wie findet man die Einstellungen, mit denen das Training überhaupt gut läuft (Pattern 15)?

== Vorspann: Die Trainingsschleife

Wer Software baut, kennt Schleifen, die Zustand verändern, bis eine Bedingung erfüllt ist. Training ist genau so eine Schleife. Das Modell besitzt *Parameter*, im einfachsten Fall zwei Zahlen $w$ und $b$ einer Geraden $hat(y) = w x + b$, bei einem neuronalen Netz Millionen davon. Ein *Loss* misst, wie falsch die Vorhersagen für die Trainingsdaten sind, zum Beispiel als mittleren quadratischen Fehler. Der *Gradient* sagt für jeden Parameter, in welche Richtung und wie stark der Loss steigt, wenn man ihn erhöht. Man geht deshalb einen kleinen Schritt in die Gegenrichtung. Die Schrittweite heißt *Lernrate*. Wer mit Parametern und Loss noch nicht vertraut ist, findet beides in Kapitel 2 ausführlicher.

Die Daten werden in kleinen Portionen verarbeitet, den *Mini-Batches*; ein Durchlauf durch alle Trainingsdaten heißt *Epoche*. Zwischen den Schritten hält die Schleife nur die Parameter fest. Deshalb lässt sie sich gut parallelisieren, unterbrechen und fortsetzen, und darauf bauen die Patterns dieses Kapitels auf.

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (16mm, 14mm),
    knoten((0, 0), [Mini-Batch \ #text(size: 8.5pt, fill: grau)[z. B. 20 Beispiele]]),
    knoten((1, 0), [Vorhersage \ #text(size: 8.5pt, fill: grau)[$hat(y) = w x + b$]]),
    knoten((2, 0), [Loss \ #text(size: 8.5pt, fill: grau)[Fehler messen]], farbe: orange, grund: orange-hell),
    knoten((3, 0), [Gradient \ #text(size: 8.5pt, fill: grau)[Richtung bergab]]),
    knoten((4, 0), [Parameter \ #text(size: 8.5pt, fill: grau)[$w arrow.l w - eta g$]], farbe: gruen, grund: gruen-hell),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"), edge((3, 0), (4, 0), "->"),
    edge((4, 0), (4, 1), "-"),
    edge((4, 1), (0, 1), "-", label: [nächster Mini-Batch · alle Batches durchlaufen = eine Epoche], label-side: right),
    edge((0, 1), (0, 0), "->"),
  )),
  caption: [Die Trainingsschleife. Nach jedem Mini-Batch ändern sich nur die Parameter ($eta$ ist die Lernrate, $g$ der Gradient).],
)

Das folgende Programm trainiert eine Gerade mit reinem numpy. Die Daten sind so erzeugt, dass die Wahrheit $y = 3x + 2$ plus Rauschen mit Standardabweichung 1,5 lautet; wir kennen also die richtige Antwort und können dem Training zusehen.

#code-aus("../code/06-model-training/trainingsschleife.py", "w, b = 0.0, 0.0")

#ausgabe("uv run --with numpy python trainingsschleife.py", "../code/06-model-training/trainingsschleife.out.txt")

Der Loss fällt in den ersten Epochen steil und bleibt dann nahe bei 2,25. Das ist die Varianz des Rauschens ($"1,5"^2$); besser kann kein Modell die verrauschten Daten vorhersagen. Der Parameter $b$ liegt nach 100 Epochen erst bei 1,14 statt bei 2, denn der Loss ist in dieser Richtung flach: Das Training ist gut genug, aber nicht „fertig“. Lernrate, Batch-Größe und Epochenzahl sind die Stellschrauben, um die sich die fünf Patterns drehen. In scikit-learn steckt die Schleife hinter `fit`, etwa bei `MLPClassifier` und `SGDClassifier`; `LinearRegression` rechnet die Lösung dagegen direkt aus.

== Pattern 11: Useful Overfitting

*Szenario und Problem.* Ein Ingenieurbüro simuliert, wie eine Federung nach einem Stoß ausschwingt. Der Solver liefert die Auslenkung $x(t, c)$ in Abhängigkeit von Zeit $t$ und Dämpfung $c$. Er ist exakt, braucht aber (angenommen) mehrere Sekunden pro Aufruf, und für die Optimierung des Entwurfs werden Millionen Aufrufe benötigt. Also trainiert man ein Modell, das die Simulation nachahmt, ein sogenanntes *Surrogatmodell*, und fragt künftig nur noch das Modell.

Die Standardregel des Machine Learning lautet: Overfitting vermeiden. *Overfitting* heißt, dass sich ein Modell an Zufälligkeiten der Trainingsdaten anpasst, die nicht verallgemeinern, vor allem an Messrauschen. Man erkennt es daran, dass der Fehler auf den Trainingsdaten klein ist und auf ungesehenen Daten groß. Regularisierung (ein Strafterm im Loss, der große Parameterwerte unattraktiv macht), Early Stopping (Abbruch, sobald sich der Fehler auf Validierungsdaten nicht mehr bessert) und kleinere Modelle bremsen die Anpassung an die Trainingsdaten. Diese Regel hat zwei Voraussetzungen: dass die Trainingsdaten die Welt nur lückenhaft und verrauscht abbilden, und dass das Modell später Eingaben sieht, die nicht im Training vorkamen. Bei einer deterministischen Simulation trifft beides nicht zu. Es gibt kein Rauschen, und der Eingaberaum lässt sich lückenlos abtasten.

*Die Lösung.* Das Pattern dreht die Regel unter diesen Bedingungen um: Man wählt ein Modell mit reichlich Kapazität, verzichtet auf Regularisierung und auf zurückgehaltene Testdaten (Hold-out) und trainiert, bis der Trainingsfehler praktisch null ist. Die Trainingsdaten sind der gesamte Eingaberaum, hier ein Gitter aus 61 Zeitpunkten und 9 Dämpfungswerten (549 Punkte) der Funktion $x(t, c) = e^(-c t) cos(sqrt(4 - c^2) t)$. Der Fehler auf dem Gitter ist die Qualitätsgröße, denn das Gitter sind die Eingaben, die später gefragt werden. Weil die Funktion glatt ist, prüft man zusätzlich 480 Zwischenwerte, die nie im Training vorkamen; die Simulation selbst liefert diese Kontrollpunkte. Das Skript trainiert ein kleines Netz (zwei Schichten à 32 Neuronen) ohne und mit starker Regularisierung ($alpha = 1$):

#code-aus("../code/06-model-training/useful_overfitting.py", "for name, alpha in [(", bis: "# --- Teil B")

#ausgabe("uv run --with scikit-learn --with numpy python useful_overfitting.py", "../code/06-model-training/useful_overfitting.out.txt")

In Teil A trifft das unregularisierte Netz das Gitter mit einem mittleren Fehler (RMSE) von 0,0064 und die nie gesehenen Zwischenwerte mit 0,0050. Mit starker Regularisierung liegt der Fehler bei 0,108, rund 17-mal höher: Die Maßnahme, die sonst vor Überanpassung schützt, erzwingt hier eine Glätte, die die Simulation nicht hat.

#figure(
  kind: image,
  text(size: 9pt, canvas({
    import draw: *
    let panel(x0, titel, farbe, grund, punkte, anfragen) = {
      content((x0 + 3, 4.35), text(weight: "bold")[#titel])
      rect((x0, 0), (x0 + 6, 3.9), fill: grund, stroke: farbe)
      for p in punkte { circle((x0 + p.at(0), p.at(1)), radius: 0.07, fill: blau, stroke: none) }
      for q in anfragen { content((x0 + q.at(0), q.at(1)), text(fill: orange, size: 11pt)[#sym.times]) }
    }
    let zufall = ((0.6, 0.7), (1.3, 2.9), (2.2, 1.4), (3.1, 3.2), (4.0, 0.9), (4.6, 2.2), (5.3, 3.4), (1.8, 2.2), (3.6, 1.9), (5.2, 0.8))
    let gitter = ()
    for i in range(0, 12) { for j in range(0, 8) { gitter.push((0.25 + i * 0.5, 0.25 + j * 0.5)) } }
    panel(0, [Üblicher Fall], luma(150), nebel, zufall, ((1.0, 1.6), (2.8, 2.5), (4.4, 3.5), (3.4, 0.6)))
    panel(7, [Useful Overfitting], gruen, gruen-hell, gitter, ((0.5, 0.5), (3.0, 2.0), (5.5, 3.5), (2.25, 1.75)))
    content((3, -0.5), [Training deckt nur Stichproben ab, \ Anfragen (#text(fill: orange)[#sym.times]) liegen woanders.])
    content((10, -0.5), [Training ist der ganze Raum, \ Anfragen liegen auf oder zwischen den Punkten.])
  })),
  caption: [Der Eingaberaum im Vergleich. Blaue Punkte sind Trainingsdaten, Kreuze sind spätere Anfragen. Schematisch, ohne Messwerte.],
)

Dass diese Logik nicht allgemein gilt, zeigen die Teile B und C. In B wird dieselbe Funktion nur an 400 Zufallspunkten mit Messrauschen beobachtet. Ein Baum ohne Tiefenlimit merkt sich jede Messung (Trainingsfehler 0,000), verfehlt neue Messungen aber mit 0,459 und die wahre Funktion mit 0,334. Ein Baum der Tiefe 5 hat 0,250 Trainingsfehler, aber nur 0,198 gegenüber der Wahrheit: Der perfekt angepasste Baum hat das Rauschen mitgelernt. In C sind die Labels reine Zufallszahlen, und beide Modelle erreichen trotzdem 100 Prozent Trainingsgenauigkeit bei etwa 50 Prozent auf neuen Daten. Zhang et al. @zhang_rethinking_generalization_2017 haben das für tiefe neuronale Netze gezeigt: Sie lernen auch Zufallslabels vollständig auswendig. Ein Trainingsfehler von null sagt für sich also nichts über Verallgemeinerung. Bei der Simulation trägt das Wissen über die Aufgabe die Rechtfertigung (deterministisch, glatt, Eingaben abgedeckt), nicht der Trainingsfehler. Warum große Netze trotz perfekter Anpassung oft gut verallgemeinern, ist eine eigene, nicht abschließend beantwortete Forschungsfrage; ein viel diskutiertes Phänomen dazu heißt „Double Descent“ @belkin_double_descent_2019.

*Trade-offs und Grenzen.* Das Pattern gilt nur, solange der Eingaberaum abgedeckt ist. Fragt jemand außerhalb des Gitters an (etwa $t = 8$), extrapoliert das Modell ungeprüft. Ändert sich der Solver, muss neu trainiert werden, und im Betrieb sollte man Stichproben gegen die Simulation prüfen. In vielen Dimensionen scheitert das Rastern: Zehn Parameter mit je zehn Werten ergeben zehn Milliarden Punkte, und dann muss das Modell doch verallgemeinern. *Wann nicht:* bei verrauschten Labels oder Eingaben aus der offenen Welt (Nutzertexte, Fotos, Sensordaten).

*Bezug zu Software Engineering.* Das Modell ist ein verlustbehafteter Cache für eine teure Funktion, vergleichbar mit Memoization, nur dass es auch für nie berechnete Eingaben antwortet. Die Simulation ist das Testorakel, gegen das man das Surrogat prüft, wie bei jeder optimierten Neuimplementierung.

#kasten([So erkläre ich es.], [
  „Normalerweise lernt ein Modell aus Beispielen für Fälle, die es noch nie gesehen hat; dort ist Auswendiglernen gefährlich. Eine Simulation ist eine Funktion, die wir lückenlos abfragen können. Dann ist Auswendiglernen genau das, was wir wollen: eine sehr schnelle Nachschlagetabelle, die dazwischen sogar interpoliert.“ Die Studierenden sollen nicht „Overfitting ist okay“ mitnehmen, sondern „Overfitting ist bewertbar, wenn ich weiß, welche Eingaben später kommen“.

  *Verständnisfrage:* Das Surrogat hat auf dem Gitter einen Fehler von fast null. Woran erkennen Sie, ob es auch zwischen den Gitterpunkten taugt? \
  *Antwort:* Man fragt die Simulation nach Kontrollpunkten, die nicht im Training waren, und vergleicht (hier 0,0050 auf 480 Zwischenwerten). Der Trainingsfehler allein sagt dazu nichts, wie die Zufallslabels aus Teil C zeigen.
])

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 4, Pattern 11); @zhang_rethinking_generalization_2017; @belkin_double_descent_2019.

== Pattern 12: Checkpoints

*Szenario und Problem.* Ein Team trainiert auf einer günstigen Cloud-Instanz, die der Anbieter jederzeit entziehen darf. Das Training soll 60 Stunden dauern, nach 41 Stunden ist die Maschine weg. Ohne gespeicherten Zustand beginnt man bei null. Ein zweites Problem ist leiser: Der letzte Stand ist nicht unbedingt der beste. Der Loss auf den Trainingsdaten sinkt immer weiter, auf Validierungsdaten stagniert er irgendwann oder steigt wieder.

Was ist der „Zustand“ eines Trainings? Nicht nur die Gewichte. Adam führt pro Parameter gleitende Mittelwerte der bisherigen Gradienten und ihrer Quadrate mit (zwei zusätzliche Werte je Parameter), dazu kommen Schritt- oder Epochenzähler und, je nach Framework, der Zustand des Zufallsgenerators, der die Datenreihenfolge bestimmt. Wer nur die Gewichte sichert, wie man es für das Ausliefern tut, kann das Training grob fortsetzen, aber nicht dieselbe Rechnung wiederaufnehmen.

*Die Lösung.* Man schreibt in regelmäßigen Abständen den vollständigen Zustand in eine Datei. Das Skript hält zwei Dateien: `latest` wird jede Epoche überschrieben und dient der Wiederaufnahme, `best` wird nur geschrieben, wenn der Validierungs-Loss besser wird. Beendet wird das Training per *Early Stopping*: Bessert sich der Validierungs-Loss zehn Epochen lang nicht um mindestens 0,001, hört es auf, und man arbeitet mit `best` weiter.

#code-aus("../code/06-model-training/checkpoints.py", "modell = neues_modell()", bis: "verlauf[\"best\"]")

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 5pt, node-corner-radius: 3pt, spacing: (15mm, 17mm),
    knoten((0, 0), [Training \ Epoche 1–25]),
    knoten((1, 0), [Zustand \ speichern]),
    knoten((2, 0), [Absturz], farbe: orange, grund: orange-hell),
    knoten((3, 0), [Zustand \ laden]),
    knoten((4, 0), [Training \ Epoche 26–40], farbe: gruen, grund: gruen-hell),
    neben((2.5, 1), [Datei `latest.joblib`: Gewichte, \ Optimierer, Zähler (ggf. Zufallszustand)]),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"),
    edge((2, 0), (3, 0), "->", stroke: (paint: orange, dash: "dashed"), label: [Neustart], label-side: left),
    edge((3, 0), (4, 0), "->"),
    edge((1, 0), (2.5, 1), "->", bend: -20deg), edge((2.5, 1), (3, 0), "->", bend: -20deg),
  )),
  caption: [Absturz und Wiederaufnahme: Das Training setzt in Epoche 26 fort, weil der Zustand aus Epoche 25 in einer Datei liegt.],
)

#ausgabe("uv run --with scikit-learn --with numpy python checkpoints.py", "../code/06-model-training/checkpoints.out.txt")

Das Training bricht nach Epoche 41 ab, der beste Stand war Epoche 31. Gezählt wird nur eine Verbesserung um mindestens 0,001; Epoche 33 liegt mit 0,1955 minimal tiefer als 0,1960 und zählt deshalb nicht. Der Training-Loss sinkt bis zum Abbruch weiter (von 0,0256 in Epoche 30 auf 0,0136 in Epoche 41), der Validierungs-Loss liegt seit Epoche 30 praktisch fest bei 0,196 (@abb-ckpt-kurve). Hier steigt er nicht, er stagniert nur, und die Genauigkeit des besten Checkpoints (0,942) unterscheidet sich kaum vom letzten Stand (0,943): Early Stopping spart vor allem Rechenzeit. Bei stärker überanpassenden Modellen steigt der Validierungs-Loss, und dann ist `best` dem letzten Stand überlegen.

#let kurve = json("../code/06-model-training/checkpoints_kurve.json")
#figure(
  kind: image,
  text(size: 9pt, canvas({
    plot.plot(
      size: (11, 4.6), x-label: [Epoche], y-label: [Loss], x-min: 5, x-max: 42, y-min: 0, y-max: 0.6,
      x-tick-step: 5, y-tick-step: 0.2, legend: "inner-north-east",
      {
        plot.add(kurve.epoche.zip(kurve.train).filter(p => p.at(0) >= 5), label: [Training], style: (stroke: blau + 1.3pt))
        plot.add(kurve.epoche.zip(kurve.val).filter(p => p.at(0) >= 5), label: [Validierung], style: (stroke: orange + 1.3pt))
        plot.add-vline(kurve.best, style: (stroke: (paint: gruen, dash: "dashed", thickness: 1pt)))
        plot.add-vline(kurve.stop, style: (stroke: (paint: grau, dash: "dotted", thickness: 1pt)))
      },
    )
  })),
  caption: [Loss je Epoche aus dem Lauf oben. Grün gestrichelt: bester Stand (Epoche 31), grau gepunktet: Abbruch (Epoche 41).],
) <abb-ckpt-kurve>

Der eigentliche Test ist die Wiederaufnahme (Teil 2 der Ausgabe): Ein Lauf bricht nach 25 Epochen ab, wird aus der Datei geladen und läuft 15 Epochen weiter, ein zweiter trainiert 40 Epochen am Stück. Die Gewichtsmatrizen sind Bit für Bit gleich, weil die Datei den Optimierer-Zustand mitführt. Ein Generatorzustand muss hier nicht gesichert werden: Mit festem `random_state` mischt scikit-learn bei jedem Aufruf von `partial_fit` neu aus dem Seed. Bei Frameworks mit fortlaufendem Zufallsgenerator gehört dessen Zustand in den Checkpoint. Teil 3 zeigt den Unterschied zu `warm_start=True`: Der Schalter lässt `fit` bei den vorhandenen Gewichten weitermachen, aber der Adam-Zustand beginnt neu, und die Datenreihenfolge wird beim zweiten Aufruf wieder aus dem Seed gemischt. In der verwendeten Version (scikit-learn 1.9.1) sind die Gewichte danach nicht identisch, die Genauigkeit ist dieselbe. Für „weitertrainieren“ reicht das, für „dieselbe Rechnung fortsetzen“ nicht. Teil 4 lädt `best` und trainiert zehn Epochen auf 300 später eingetroffenen Beispielen weiter; die Validierungsgenauigkeit steigt von 0,942 auf 0,963. Das ist *Fine-Tuning ab Checkpoint*: Man beginnt bei einem Stand, der schon vieles kann, nicht bei null. Pattern 13 treibt den Gedanken weiter.

*Trade-offs und Grenzen.* Ein Checkpoint kostet Speicher und Zeit: hier 609 KiB, bei großen Netzen mit Adam ein Vielfaches der Modellgröße, weil die Optimiererwerte dazukommen. Schreibt man bei jedem Schritt, bremst das Training; schreibt man selten, verliert man bei einem Abbruch mehr. Bricht der Prozess beim Schreiben ab, bleibt eine halbe Datei zurück, deshalb schreibt man in eine temporäre Datei und benennt sie danach um. Joblib- und Pickle-Dateien speichern Verweise auf Klassen im Code, brechen unter Umständen bei Versionswechseln und führen beim Laden Code aus; man lädt sie nur aus vertrauenswürdiger Quelle. Beim Fine-Tuning nur auf neuen Daten droht, dass das Modell Altes verlernt (Catastrophic Forgetting), hier ohne Folgen, weil die Daten aus derselben Verteilung stammen. *Wann nicht:* wenn das Training in Minuten fertig ist.

*Bezug zu Software Engineering.* Das Muster entspricht dem Memento-Pattern der Gang of Four @gamma_design_patterns_1994: Der Zustand eines Objekts wird nach außen gesichert und später wiederhergestellt. Auch Savepoints in Datenbanken und wiederanlaufbare Batch-Jobs folgen dieser Idee. Early Stopping ist ein Abbruchkriterium einer Schleife, nur dass es hier auf einer Messung beruht und nicht auf einem Zähler.

#kasten([So erkläre ich es.], [
  „Ein Spielstand speichert nicht nur den Level, sondern Inventar, Lebenspunkte und den Zufallszustand der Welt. Genauso speichert ein Checkpoint nicht nur das Modell, sondern alles, was das Training zum Weiterlaufen braucht. Zusätzlich behalten wir den besten Spielstand, nicht nur den letzten.“

  *Verständnisfrage:* Warum reicht es nicht, nach einem Absturz einfach die gespeicherten Gewichte zu laden und das Training neu zu starten? \
  *Antwort:* Es fehlen der Optimierer-Zustand, der Fortschritt (Epochen- oder Schrittzähler) und, je nach Framework, der Zustand des Zufallsgenerators. Der Optimierer startet mit leeren Mittelwerten, die Fortsetzung ist nicht mehr dieselbe Rechnung (im Experiment mit `warm_start`: nicht bitgleich). Das Ergebnis ist meist brauchbar, aber nicht reproduzierbar.
])

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 4, Pattern 12); @gamma_design_patterns_1994.

== Pattern 13: Transfer Learning

*Szenario und Problem.* Ein Krankenhaus besitzt 400 beschriftete Röntgenbilder und will auffällige Befunde markieren. Ein Netz mit Millionen Parametern mit 400 Bildern von Grund auf zu trainieren, endet beim Auswendiglernen. Gleichzeitig gibt es öffentlich Hunderttausende beschriftete Alltagsfotos, an denen Netze gelernt haben, Kanten, Texturen und Formen zu unterscheiden. Das Problem ist ein Missverhältnis: zu wenige Beispiele für zu viele Parameter, und jede Schicht müsste die Grundlagen des Sehens neu entdecken.

Wir bauen das im Kleinen nach. Das *Vortraining* lernt, alle zehn Ziffern zu erkennen (900 Bilder der Ziffern-Daten von scikit-learn). Die *Zielaufgabe* ist eine andere, nämlich gerade oder ungerade, mit nur 6 bis 50 beschrifteten Beispielen; diese Bilder kommen im Vortraining nicht vor. Das ist ein günstiger Fall für Transfer, denn „gerade oder ungerade“ lässt sich direkt aus der Ziffer ablesen, die das Vortraining erkennen lernt. Bei Röntgenbildern und Alltagsfotos ist die Nähe der Aufgaben nicht von vornherein so groß.

*Die Lösung.* Tiefe Netze lernen Features in Schichten. Die unteren erfassen eher allgemeine Muster, die oberen werden zunehmend aufgabenspezifisch. Yosinski et al. @yosinski_transferability_2014 haben das untersucht: Übertragene untere Schichten sind nützlich, die Übertragbarkeit sinkt, je verschiedener die Aufgaben sind, und mit übertragenen Features initialisierte Netze verallgemeinern auch nach weiterem Training besser als zufällig initialisierte. Das Pattern nutzt das so:

+ Man nimmt ein Modell, das auf einer großen Aufgabe vortrainiert wurde (die *Basis*), und trennt den letzten Teil ab, den *Kopf*, der die alten Klassen ausgibt.
+ Man setzt einen neuen Kopf auf, der zu den neuen Labels passt.
+ Bei der *Feature-Extraktion* bleibt die Basis eingefroren; nur der neue Kopf wird trainiert. Beim *Fine-Tuning* wird die Basis mittrainiert, meist mit kleiner Lernrate, damit das Gelernte nicht zerstört wird.

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (24mm, 9mm),
    neben((0, 0), [große Aufgabe \ #text(size: 8.5pt, fill: grau)[900 Bilder, 10 Ziffern]]),
    knoten((1, 0), [Basis \ #text(size: 8.5pt, fill: grau)[versteckte Schicht]]),
    neben((2, 0), [alter Kopf \ #text(size: 8.5pt, fill: grau)[10 Ziffern]]),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"),
    knoten((1, 1), [Basis eingefroren \ #text(size: 8.5pt, fill: grau)[Feature-Extraktion]], farbe: grau, grund: nebel),
    knoten((2, 1), [neuer Kopf \ #text(size: 8.5pt, fill: grau)[trainiert]], farbe: gruen, grund: gruen-hell),
    knoten((1, 2), [Basis angepasst \ #text(size: 8.5pt, fill: grau)[Fine-Tuning]], farbe: gruen, grund: gruen-hell),
    knoten((2, 2), [neuer Kopf \ #text(size: 8.5pt, fill: grau)[trainiert]], farbe: gruen, grund: gruen-hell),
    neben((0, 1.5), [kleine Aufgabe \ #text(size: 8.5pt, fill: grau)[6 bis 50 Bilder, \ gerade/ungerade]]),
    edge((0, 1.5), (1, 1), "->"), edge((0, 1.5), (1, 2), "->"),
    edge((1, 1), (2, 1), "->"), edge((1, 2), (2, 2), "->"),
    edge((1, 0), (1, 1), "->", stroke: (dash: "dashed", paint: grau), label: [Gewichte \ übernehmen], label-side: right),
  )),
  caption: [Transfer Learning: Die Basis wird übernommen, der Kopf ersetzt. Die Basis bleibt eingefroren oder wird mittrainiert.],
)

scikit-learn kennt kein Einfrieren, deshalb bauen wir beide Varianten von Hand. Für die Feature-Extraktion rechnen wir die versteckte Schicht des vortrainierten Netzes selbst aus (`np.maximum(0, X @ W + b)` mit den Gewichten des Vortrainings) und trainieren darauf eine logistische Regression als neuen Kopf. Für das Fine-Tuning übernehmen wir die Gewichte der ersten Schicht in ein neues Netz mit neuem Kopf und trainieren alles weiter:

#code-aus("../code/06-model-training/transfer_learning.py", "        # Fine-Tuning:", bis: "punkte[\"ft\"]")

Verglichen wird mit zwei Basislinien, die nichts übertragen: logistische Regression auf den Pixeln und ein Netz von Null. Jede Zeile ist der Mittelwert über 20 zufällige Stichproben:

#ausgabe("uv run --with scikit-learn --with numpy python transfer_learning.py", "../code/06-model-training/transfer_learning.out.txt")

Die Feature-Extraktion liegt bei sehr wenigen Beispielen vorn (6 Beispiele: 0,734 gegen 0,685 für die Pixel-Regression, bei 10 und 20 gut drei bis knapp vier Prozentpunkte). Bei 50 Beispielen ist der Vorsprung weg (0,862 gegen 0,850 und 0,870 für das Netz von Null): Reichen die Daten, lernt das Modell die Features selbst. Die Effekte sind moderat, die Streuung zwischen den Stichproben (0,02 bis 0,07) ist größer als der Abstand der Mittelwerte. Das Fine-Tuning bringt in dieser Konfiguration nichts. Plausibel ist, dass das freie Training aller Gewichte mit derselben Lernrate die übernommenen Features auf 6 bis 50 Beispielen wieder überschreibt; untersucht haben wir das nicht (außerdem läuft das Fine-Tuning 200 Iterationen, das Netz von Null 500), und in Frameworks gibt man der Basis eine kleinere Lernrate als dem Kopf. Die übliche Faustregel (sie folgt nicht aus diesem kleinen Experiment): wenige Daten und ähnliche Aufgabe, dann Feature-Extraktion; viele Daten und ähnliche Aufgabe, dann Fine-Tuning; sehr verschiedene Aufgaben, dann vorsichtig sein und nur untere Schichten übernehmen.

*Trade-offs und Grenzen.* Die Basis legt das Eingabeformat fest: Bildgröße, Vokabular, Tokenisierung. Sie bringt außerdem ihre Herkunft mit, also die Verzerrungen ihrer Trainingsdaten und deren Lizenzbedingungen. Ist die Zielaufgabe der Quellaufgabe zu unähnlich, kann die Übertragung schaden (negativer Transfer). Große Basismodelle kosten Speicher und Latenz im Betrieb. Und vortrainierte Gewichte sind Fremdmaterial: Man sollte sie aus vertrauenswürdiger Quelle beziehen und die Version festhalten. *Wann nicht:* wenn man genug eigene Daten hat und die Domäne sehr speziell ist, oder wenn das Modell klein genug ist, um in Minuten von Grund auf zu trainieren. Das Buch zeigt das Pattern mit TensorFlow und vortrainierten Modellen (u. a. aus TF Hub).

*Bezug zu Software Engineering.* Transfer Learning ist Wiederverwendung statt Neuentwicklung. Die Basis ist eine Abhängigkeit, die man mit fester Version einbindet, der neue Kopf ist ein Adapter an die eigene Schnittstelle @gamma_design_patterns_1994. Feature-Extraktion entspricht dem Verwenden einer Bibliothek, so wie sie ist; Fine-Tuning entspricht einem Fork, den man anpasst und damit selbst pflegen muss.

#kasten([So erkläre ich es.], [
  „Wir bauen keinen Compiler neu, wenn wir eine Programmiersprache brauchen. Genauso müssen wir ein Netz nicht erst das Sehen lehren, wenn jemand das schon getan hat. Wir übernehmen die Schichten, die allgemeine Features bilden, und trainieren nur den Teil neu, der unsere Frage beantwortet.“

  *Verständnisfrage:* Warum bringt die Feature-Extraktion im Experiment bei 6 Beispielen mehr als bei 50? \
  *Antwort:* Bei wenigen Beispielen hat die Basis den größten Teil des Lernens schon erledigt, und der kleine neue Kopf kann damit auskommen. Bei mehr Beispielen kann das Modell die Features auch selbst aus den Daten lernen, der Vorsprung schrumpft (hier von etwa fünf auf rund einen Prozentpunkt).
])

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 4, Pattern 13); @yosinski_transferability_2014.

== Pattern 14: Distribution Strategy

*Szenario und Problem.* Ein Team trainiert einen Bildklassifikator. Ein Durchlauf dauert auf einer einzelnen GPU sechs Tage (eine Annahme für dieses Beispiel), und jedes Experiment ist erst nach einer Woche bewertbar. Man möchte dieselbe Rechnung auf acht oder achtzig Geräte verteilen. Das ist weniger selbstverständlich, als es klingt, denn die Trainingsschleife ist von Natur aus sequenziell: Schritt $t+1$ braucht die Parameter, die Schritt $t$ erzeugt hat. Man kann die Schleife nicht einfach in Stücke schneiden wie eine Schleife über unabhängige Datensätze. Dazu kommen zwei verschiedene Engpässe, die verschiedene Lösungen verlangen: Die Rechenzeit ist zu lang, oder das Modell ist zu groß für den Speicher eines einzelnen Geräts.

*Die Lösung.* *Datenparallelität* löst das Zeitproblem. Jeder Worker besitzt eine vollständige Modellkopie und bearbeitet einen Teil des Mini-Batches. Er berechnet den Gradienten für seinen Teil, danach werden die Gradienten gemittelt, und alle Worker führen denselben Schritt aus. Dass das Mitteln keinen Unterschied macht, lässt sich nachrechnen: Das Skript teilt 8 000 Beispiele auf vier Shards auf, und die größte Abweichung zwischen dem gemittelten Shard-Gradienten und dem Gradienten über alle Daten beträgt $"1,8" dot 10^(-15)$, also Rundungsrauschen. Bei gleich großen Shards und einem Loss, der ein Mittelwert über Beispiele ist, entspricht synchrone Datenparallelität mit vier Workern à 64 Beispielen mathematisch einem Schritt mit Batch 256 auf einem Gerät, nur schneller. (Ausnahme sind Schichten, die Statistiken über den Batch bilden, etwa Batch Normalization: Dort sieht jeder Worker nur seine 64 Beispiele.) Das ist die wichtigste Einsicht dieses Patterns. Offen bleibt, wie die Gradienten zusammenkommen (@abb-gradienten-zusammenfuehren):

- Beim *Parameter Server* halten dedizierte Rechner die Parameter. Worker holen den aktuellen Stand, rechnen und schicken Gradienten zurück. Das System von Dean et al. @dean_distbelief_2012 (DistBelief) ist so gebaut. Der Server ist die Engstelle: Sein Netzwerk muss die Daten aller Worker verkraften.
- Beim *All-Reduce* gibt es kein Zentrum. Im Ring-Verfahren zerlegt jeder Worker seinen Gradientenvektor der Länge $D$ in $N$ Stücke. In $N-1$ Schritten reicht jeder ein Stück an seinen Nachbarn weiter, der es aufaddiert; danach besitzt jeder Worker die Summe eines Stücks. In weiteren $N-1$ Schritten werden die fertigen Summen im Kreis verteilt. Jeder Worker sendet insgesamt $2(N-1)/N dot D$ Werte, also fast unabhängig von $N$ @patarasuk_allreduce_2009.

#figure(
  kind: image,
  grid(
    columns: (1fr, 1fr), column-gutter: 8pt, row-gutter: 14pt,
    text(size: 9pt, diagram(
      node-inset: 6pt, node-corner-radius: 3pt, spacing: (16mm, 13mm),
      knoten((1, 0), [Parameter \ Server], farbe: orange, grund: orange-hell),
      knoten((0, 1.2), [Worker 1]), knoten((1, 1.2), [Worker 2]), knoten((2, 1.2), [Worker 3]),
      edge((0, 1.2), (1, 0), "<->"), edge((1, 1.2), (1, 0), "<->"), edge((2, 1.2), (1, 0), "<->"),
    )),
    text(size: 9pt, diagram(
      node-inset: 6pt, node-corner-radius: 3pt, spacing: (16mm, 13mm),
      knoten((0, 0), [Worker 1]), knoten((1, 0), [Worker 2]),
      knoten((1, 1.2), [Worker 3]), knoten((0, 1.2), [Worker 4]),
      edge((0, 0), (1, 0), "->"), edge((1, 0), (1, 1.2), "->"), edge((1, 1.2), (0, 1.2), "->"), edge((0, 1.2), (0, 0), "->"),
    )),
    align(center, par(justify: false)[Parameter Server: alle Worker sprechen mit der Mitte.]),
    align(center, par(justify: false)[Ring-All-Reduce: jeder spricht nur mit dem Nachbarn.]),
  ),
  caption: [Zwei Wege, die Gradienten der Worker zusammenzuführen.],
) <abb-gradienten-zusammenfuehren>

Das Skript baut den Ring in wenigen Zeilen nach (die „Worker“ sind Listeneinträge) und zählt, wie viele Werte jeder verschickt:

#ausgabe("uv run --with numpy python distribution_strategy.py", "../code/06-model-training/distribution_strategy.out.txt", von: 14)

Bei 16 Workern sendet jeder im Ring 450 000 Werte. Ein zentraler Koordinator, der (als einer der 16 Worker) 15 Gradientenvektoren einsammelt und die Summe an 15 zurückschickt, müsste allein 7,2 Millionen Werte bewegen. Das ist der Grund, warum große Trainings auf All-Reduce statt auf einen einzelnen Sammelpunkt setzen.

Die zweite Entscheidung betrifft die Synchronisation. Beim *synchronen* Training wartet jeder Schritt auf den langsamsten Worker (den „Straggler“), dafür ist das Ergebnis exakt das des großen Batches. Beim *asynchronen* Training schickt jeder Worker sein Update, sobald er fertig ist, und rechnet sofort weiter. Niemand wartet, aber die Gradienten sind „veraltet“: Sie wurden auf Parametern berechnet, die inzwischen von anderen Workern weiterverändert wurden. Das Skript simuliert das, indem ein Schritt mit dem Gradienten von vor $s$ Schritten arbeitet:

#ausgabe("uv run --with numpy python distribution_strategy.py", "../code/06-model-training/distribution_strategy.out.txt", von: 3, bis: 8)

Mit derselben Lernrate verträgt das Training Gradienten, die vier Schritte alt sind, praktisch ohne Einbuße. Bei zehn Schritten wird es langsamer, bei zwanzig kippt es und der Verlust explodiert. Die Toleranz hängt also von Lernrate und Aufgabe ab, und genau dieses Wechselspiel macht asynchrones Training heikel. Dean et al. nehmen es in ihrem asynchronen Verfahren (Downpour SGD) in Kauf, um nicht auf langsame oder ausgefallene Maschinen warten zu müssen. *Modellparallelität* ist die andere Antwort, wenn das Modell nicht in den Speicher eines Geräts passt: Man verteilt Schichten oder Teile von Schichten auf mehrere Geräte, und die Zwischenergebnisse der Schichten (Aktivierungen) wandern zwischen ihnen. Das System von Dean et al. kombinierte beides.

Zuletzt verändert Datenparallelität den effektiven Batch: Vier Worker mit je 64 Beispielen ergeben einen Batch von 256, und die Zahl der Schritte pro Epoche sinkt auf ein Viertel. Wer die Lernrate nicht anpasst, trainiert nach derselben Zahl von Epochen schlechter. Goyal et al. @goyal_large_minibatch_2017 formulieren die *Linear Scaling Rule*: Wächst der Batch um den Faktor $k$, wächst die Lernrate um $k$. Sie trainierten damit ResNet-50 (ein verbreitetes Bildklassifikationsnetz) auf ImageNet (rund 1,3 Millionen beschriftete Fotos) mit Mini-Batches bis 8 192 Beispielen in etwa einer Stunde, wobei sie zu Beginn die Lernrate langsam hochfahren („Warmup“). Unser Skript zeigt den Effekt im Kleinen:

#ausgabe("uv run --with numpy python distribution_strategy.py", "../code/06-model-training/distribution_strategy.out.txt", von: 9, bis: 13)

Achtfacher Batch mit unveränderter Lernrate erreicht nach zwei Epochen einen Verlust von 0,738, der achtfach vergrößerten Lernrate gelingt 0,256, fast so gut wie die Ausgangslage mit 0,255.

*Trade-offs und Grenzen.* Verteiltes Training skaliert nie perfekt: Die Kommunikation kostet Zeit, und bei kleinen Modellen oder kleinen Batches wird sie zum dominierenden Anteil. Mit der Zahl der Geräte wachsen Kosten und Fehlerquellen; der Ausfall eines Workers muss behandelt werden (hier helfen Checkpoints, Pattern 12). Asynchrones Training ist nicht ohne Weiteres reproduzierbar, weil die Reihenfolge der Updates vom Zufall der Laufzeiten abhängt. Und bevor man Geräte hinzufügt, sollte man prüfen, ob nicht die Eingabepipeline (Daten laden, Bilder dekodieren) das Training bremst; sie lässt sich mit zusätzlichen GPUs nicht beschleunigen. *Wann nicht:* Wenn ein Training auf einem Gerät in Minuten oder wenigen Stunden fertig ist, kostet die Verteilung mehr Komplexität, als sie Zeit spart. Und wer viele Experimente hat (Pattern 15), fährt meist besser damit, jeden Versuch auf einem eigenen Gerät laufen zu lassen, statt einen einzelnen Versuch zu verteilen.

Das Buch zeigt dieses Pattern mit den Verteilungsstrategien von TensorFlow (`tf.distribute`), die diese Bausteine hinter einer einheitlichen Schnittstelle verstecken.

*Bezug zu Software Engineering.* Das Muster ist Scatter-Gather in der Form von MapReduce: Teile verteilen, lokal rechnen, Ergebnisse zusammenführen. Die Wahl zwischen synchron und asynchron ist die bekannte Konsistenzfrage verteilter Systeme. Synchron ähnelt starker Konsistenz (alle sehen denselben Stand, dafür wartet man), asynchron ähnelt eventual consistency (niemand wartet, dafür arbeitet man mit veralteten Daten). Die Analogie hinkt, weil es hier um den Weg eines Optimierungsverfahrens geht und nicht um replizierte Daten. Dass 16 Geräte kein 16-faches Tempo bringen, ist Amdahls Gesetz: Der sequenzielle Anteil, hier die Kommunikation, begrenzt den Gewinn.

#kasten([So erkläre ich es.], [
  Vier Korrektorinnen bewerten je ein Viertel eines Klausurstapels und gleichen danach das Bewertungsschema ab. Warten alle aufeinander, ist das Schema nach jeder Runde einheitlich, aber die Langsamste bestimmt das Tempo (synchron). Trägt jede Korrektorin ihre Anpassung ins gemeinsame Schema ein, sobald sie fertig ist, geht es schneller, aber manche Anpassungen beruhen auf einer schon überholten Fassung (asynchron). Wichtig ist der Gedanke, dass mehr Rechner auch einen größeren Batch bedeuten und die Lernrate nachgezogen werden muss.

  *Verständnisfrage:* Warum ist synchrone Datenparallelität mit 4 Workern à 64 Beispielen mathematisch dasselbe wie ein Training mit Batch 256 auf einem Gerät? \
  *Antwort:* Weil der Mittelwert der vier Teilgradienten bei gleich großen Teilen genau der Gradient über alle 256 Beispiele ist (Abweichung im Experiment: $10^(-15)$). Deshalb muss man auch die Lernrate wie bei einem größeren Batch behandeln.
])

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 4, Pattern 14); @dean_distbelief_2012; @goyal_large_minibatch_2017; @patarasuk_allreduce_2009.

== Pattern 15: Hyperparameter Tuning

*Szenario und Problem.* Wir klassifizieren handgeschriebene Ziffern (8 × 8 Pixel) mit einer Support Vector Machine (SVM), einem klassischen Verfahren, das die Klassen durch eine möglichst trennscharfe Grenze zwischen den Trainingsbeispielen unterscheidet. Die Parameter des Modells lernt das Training selbst. Daneben gibt es Einstellungen, die vor dem Training feststehen müssen: bei der SVM `C` (wie streng Fehler bestraft werden) und `gamma` (wie weit der Einfluss eines Trainingsbeispiels reicht), bei einem neuronalen Netz Lernrate, Schichtzahl oder Batch-Größe. Das sind die *Hyperparameter*. Parameter sind Zustand, den die Schleife verändert; Hyperparameter sind Konfiguration, die man ihr mitgibt.

Das Problem: Die Güte eines Modells hängt stark von dieser Konfiguration ab, und niemand kann sie vorab ausrechnen. Probiert man von Hand, ist das Vorgehen weder wiederholbar noch dokumentiert, und jeder Versuch ist ein vollständiges Training. Dazu kommt eine methodische Falle: Wer Hyperparameter anhand der Testdaten auswählt, hat die Testdaten in die Modellentwicklung einfließen lassen. Das Ergebnis ist dann zu optimistisch, und es gibt keine unabhängige Messung mehr.

*Die Lösung.* Man automatisiert die Suche und legt über die Trainingsschleife eine äußere Schleife: Ein Suchverfahren schlägt eine Konfiguration vor, das Modell wird trainiert und mit Kreuzvalidierung auf den Trainingsdaten bewertet (die Trainingsdaten werden in fünf Teile geteilt, jeder Teil dient einmal zur Bewertung eines Modells, das auf den übrigen vier trainiert wurde; die fünf Werte werden gemittelt), das Ergebnis geht zurück an das Verfahren. Am Ende gibt es eine beste Konfiguration, und erst jetzt kommen die Testdaten einmal zum Einsatz.

Drei Suchverfahren sind verbreitet. Bei der *Grid Search* legt man pro Hyperparameter eine Liste von Werten fest und probiert alle Kombinationen. Bei $d$ Hyperparametern mit je $k$ Werten sind das $k^d$ Versuche. Bei der *Random Search* zieht man jede Konfiguration zufällig aus Verteilungen über den erlaubten Bereichen. Bei der *Bayes’schen Optimierung* baut das Verfahren aus den bisherigen Versuchen ein statistisches Ersatzmodell der Funktion „Hyperparameter → Güte“ auf und wählt den nächsten Versuch dort, wo es viel Gewinn oder viel Unsicherheit erwartet @snoek_bayesian_optimization_2012. Das Skript vergleicht die ersten beiden mit scikit-learn, bei gleichem Budget von 25 Versuchen:

#code-aus("../code/06-model-training/hyperparameter_tuning.py", "C_GRID = ", bis: "print(\"Gleiches")

#ausgabe("uv run --with scikit-learn --with numpy python hyperparameter_tuning.py", "../code/06-model-training/hyperparameter_tuning.out.txt")

Beide Verfahren landen bei etwa 98 Prozent Kreuzvalidierungsgenauigkeit und etwa 99 Prozent auf den Testdaten. Die Unterschiede sind klein: 0,9805 gegen 0,9814 im CV-Wert, und bei den 719 Testbildern entspricht der Abstand von 0,9917 zu 0,9930 einem einzigen Bild. Das ist keine Überraschung, denn die Aufgabe ist einfach und die Güte fällt in einem großen Bereich flach ab. Die Verteilung der Grid-Ergebnisse zeigt aber, wie sehr die Wahl zählt: Neun der 25 Versuche liegen unter 50 Prozent, ein Drittel des Budgets also in hoffnungslosen Ecken, und der Median liegt bei 0,965.

Bergstra und Bengio @bergstra_random_search_2012 erklären, warum Random Search dem Grid meist überlegen ist: Von den Hyperparametern beeinflusst oft nur eine Handvoll das Ergebnis wirklich, und man weiß vorher nicht, welche. Das Grid probiert für jeden Hyperparameter nur $k$ verschiedene Werte, hier fünf, auch wenn es 25 Versuche macht. Die Random Search probiert in jedem Versuch einen neuen Wert für jeden Hyperparameter, hier 25 verschiedene `gamma`-Werte statt fünf (@abb-tuning-streu). Mit zehn verschiedenen Seeds lag der beste CV-Wert der Random Search zwischen 0,9814 und 0,9833, also nie unter dem des Grids. Bei so engen Abständen sollte man das aber nicht überbewerten.

#let trials = json("../code/06-model-training/hyper_trials.json")
#let streu(punkte) = canvas({
  import draw: *
  let b = 5.8
  let h = 4.4
  let px(g) = (g + 3) / 4 * b
  let py(c) = (c + 1) / 4 * h
  rect((0, 0), (b, h), stroke: 0.6pt + luma(150))
  let bester = punkte.fold(punkte.at(0), (a, p) => if p.at(2) > a.at(2) { p } else { a })
  for p in punkte {
    let t = calc.max(0, calc.min(1, (p.at(2) - 0.1) / 0.88))
    circle((px(p.at(0)), py(p.at(1))), radius: 0.16, fill: color.mix((gruen, t * 100%), (orange, (1 - t) * 100%)), stroke: 0.4pt + white)
  }
  circle((px(bester.at(0)), py(bester.at(1))), radius: 0.24, fill: none, stroke: 1.2pt + black)
  for g in (-3, -2, -1, 0, 1) { content((px(g), -0.4), [$10^(#g)$]) }
  for c in (-1, 0, 1, 2, 3) { content((-0.55, py(c)), [$10^(#c)$]) }
  content((b / 2, -0.95), [`gamma`])
  content((-1.45, h / 2), angle: 90deg, [`C`])
})
#figure(
  kind: image,
  grid(
    columns: (1fr, 1fr), column-gutter: 4pt, row-gutter: 6pt,
    align(center, text(size: 9pt, streu(trials.grid))),
    align(center, text(size: 9pt, streu(trials.zufall))),
    align(center)[Grid Search: 25 Versuche, 5 verschiedene `gamma`],
    align(center)[Random Search: 25 Versuche, 25 verschiedene `gamma`],
  ),
  caption: [Die tatsächlich probierten Konfigurationen beider Läufe (logarithmische Achsen). Grün: hoher CV-Wert, orange: niedriger. Der schwarze Ring markiert den jeweils besten Versuch.],
) <abb-tuning-streu>

Beide Achsen sind logarithmisch skaliert, und das ist wichtig: `C` und `gamma` wirken über mehrere Größenordnungen. Würde man `gamma` gleichmäßig zwischen 0,001 und 10 ziehen, lägen neun von zehn Versuchen über 1.

*Trade-offs und Grenzen.* Tuning kostet Rechenzeit: 25 Versuche mit fünffacher Kreuzvalidierung sind 125 Trainingsläufe (dazu kommt ein abschließendes Training mit der besten Konfiguration auf allen Trainingsdaten). Der beste CV-Wert ist außerdem leicht zu optimistisch, weil er das Maximum über viele verrauschte Messungen ist. Daher kommt die Regel, die Testdaten erst am Ende und nur einmal zu verwenden. Die Suchbereiche muss man selbst festlegen; liegt das Optimum außerhalb, findet es kein Verfahren. Bayes’sche Optimierung kommt meist mit weniger Versuchen aus, ist aber von Natur aus sequenziell, weil jeder Vorschlag die bisherigen Ergebnisse braucht; sie lässt sich parallelisieren, aber aufwendiger als Random Search, bei der alle Versuche unabhängig sind. scikit-learn bringt sie nicht mit; verbreitet sind Bibliotheken wie Optuna oder Keras Tuner. *Wann nicht:* Wenn ein einzelnes Training Tage dauert und das Budget fünf Versuche erlaubt, hilft kein Suchverfahren. Dann sind erfahrungsbasierte Startwerte, kleinere Probeläufe auf Teildaten oder Transfer Learning (Pattern 13) die bessere Wahl.

*Bezug zu Software Engineering.* Das Muster ist ein Parameter-Sweep, wie man ihn aus dem Performance-Tuning kennt: Konfiguration variieren, messen, die beste behalten. Nur dass jede Messung hier ein ganzes Training ist und die Messung rauscht, weshalb man wiederholt (Kreuzvalidierung). Die Trennung zwischen Tuning-Daten und Testdaten entspricht der Trennung zwischen dem, woran man entwickelt, und dem, wogegen man abnimmt.

#kasten([So erkläre ich es.], [
  „Parameter sind der Zustand, den das Programm beim Lauf verändert. Hyperparameter sind die Konfigurationsdatei, die vorher feststeht. Wir suchen die beste Konfiguration, indem wir viele ausprobieren, und messen jede an Daten, die das Modell nicht zum Lernen benutzt hat.“ Gut ist eine kurze Live-Demonstration: dieselbe SVM mit `gamma=10` und mit `gamma=0.1`.

  *Verständnisfrage:* Ein Kollege wählt `C` und `gamma` so, dass die Genauigkeit auf den Testdaten maximal ist, und berichtet diesen Wert. Was ist daran falsch? \
  *Antwort:* Die Testdaten haben die Auswahl mitbestimmt, der Wert ist damit nicht mehr unabhängig und zu optimistisch. Richtig ist, auf einem Validierungsteil oder per Kreuzvalidierung zu wählen und die Testdaten genau einmal am Ende zu benutzen.
])

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 4, Pattern 15); @bergstra_random_search_2012; @snoek_bayesian_optimization_2012; scikit-learn @pedregosa_scikit_learn_2011.


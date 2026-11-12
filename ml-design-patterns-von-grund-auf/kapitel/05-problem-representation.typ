#import "../lib.typ": *
#import "@preview/cetz-plot:0.1.2": plot

// Lokale Hilfen. Code und Ausgaben werden aus code/05-problem-representation/ gelesen.
#let gruen = rgb("#2EAE7D")
#let orange = rgb("#B5651D")
// Ausschnitt einer Datei von der Zeile, die `ab` enthält, bis vor die Zeile, die `bis` enthält
#let code-aus(datei, ab, bis: none) = {
  let t = read("../code/05-problem-representation/" + datei)
  let von = t.position(ab)
  let rest = t.slice(von)
  let ende = if bis == none { rest.len() } else { rest.position(bis) }
  raw(rest.slice(0, ende).trim("\n", at: end), lang: "python", block: true)
}
// Ausgabe eines Laufs im Konsolenfenster; von/bis wählen Zeilen (ab 0), befehl: none lässt die Befehlszeile weg
#let ausgabe(datei, befehl, von: 0, bis: none) = {
  let z = read("../code/05-problem-representation/ausgabe/" + datei).trim("\n", at: end).split("\n")
  let z = z.slice(von, if bis == none { z.len() } else { bis })
  let kopf = if befehl == none { () } else { ("$ " + befehl,) }
  raw((kopf + z).join("\n"), lang: "terminal", block: true)
}
#let uv-run(datei) = "uv run --with scikit-learn --with pandas python " + datei
#let erklaere(body, frage, antwort) = kasten([So erkläre ich es.], {
  body
  parbreak()
  [*Verständnisfrage.* #frage]
  parbreak()
  [*Antwort.* #antwort]
})
#let daten-plot(..args) = block(width: 100%, align(center, text(size: 9pt, canvas(length: 1cm, {
  draw.set-style(axes: (stroke: 0.6pt, tick: (stroke: 0.5pt)))
  plot.plot(..args)
}))))
#let prozent(x, stellen: 1) = str(calc.round(x * 100, digits: stellen)).replace(".", ",") + " %"

#set figure(placement: auto)

= Problem Representation

Bevor man ein Modell trainiert, muss man festlegen, _welche Frage_ es beantworten soll. Aus einem fachlichen Problem lassen sich mehrere ML-Aufgaben machen, und die Wahl entscheidet, was das Modell ausgibt, welche Fehlerfunktion es minimiert und welche Fehler es überhaupt machen kann. Die sechs Patterns aus Kapitel 3 des Buchs @lakshmanan_ml_design_patterns_2020 handeln davon, ein Problem so zu formulieren, dass ein Modell es lösen kann.

#figure(
  table(columns: (auto, 1fr, 1fr), align: (left, left, left),
    table.header[Pattern][Situation][Kernidee],
    [5 Reframing], [Der Zielwert ist zweigipflig oder hat Spielräume, ein Punktwert führt in die Irre.], [Aus Regression Klassifikation über Wertebereiche machen, das Modell liefert eine Verteilung.],
    [6 Multilabel], [Ein Beispiel gehört zu mehreren Klassen zugleich.], [Pro Klasse ein eigener Ja/Nein-Ausgang (Sigmoid) statt eines gemeinsamen (Softmax).],
    [7 Ensembles], [Ein einzelnes Modell ist zu ungenau oder zu schwankend.], [Mehrere Modelle trainieren, Vorhersagen kombinieren.],
    [8 Cascade], [Ein Modell vermischt Fallgruppen, die sich gegensätzlich verhalten; die Aufgabe zerfällt in Teilfragen.], [Modelle hintereinander schalten: das erste entscheidet, welcher Spezialist weiterarbeitet.],
    [9 Neutral Class], [Menschen sind sich beim Labeln uneinig, die Grenze ist unscharf.], [Eine dritte Klasse für "weder noch" einführen.],
    [10 Rebalancing], [Eine Klasse ist extrem selten (unter 1 %).], [Daten, Gewichte oder Schwelle anpassen und die richtigen Metriken verwenden.],
  ),
  caption: [Die sechs Patterns dieses Kapitels im Überblick.],
)

Zwei Metriken braucht man in diesem Kapitel ständig, deshalb vorab. Wenn ein Modell zu jedem Beispiel "positiv" oder "negativ" sagt, ist die _Precision_ der Anteil der als positiv gemeldeten Beispiele, die tatsächlich positiv sind ("wie viele meiner Alarme waren berechtigt?"), und der _Recall_ der Anteil der tatsächlich positiven Beispiele, die das Modell gefunden hat ("wie viele echte Fälle habe ich erwischt?"). Beide ziehen in entgegengesetzte Richtungen: Wer mehr Fälle melden will, muss mehr Fehlalarme in Kauf nehmen. Der _F1-Wert_ fasst beide als harmonisches Mittel zusammen:

$ F_1 = (2 P R) / (P + R) . $

== Pattern 5: Reframing

*Szenario.* Ein Lieferdienst will seinen Kunden die Lieferzeit anzeigen. Bekannt ist bei der Bestellung nur die Entfernung. Was der Dienst nicht weiß: Ob die Küche gerade überlastet ist. Im Skript `01_reframing.py` entstehen 20 000 künstliche Lieferungen. Normalerweise dauert es 15 Minuten plus 3 Minuten je Kilometer, bei überlasteter Küche kommen 40 Minuten dazu, und das passiert in der Hälfte der Fälle.

*Das Problem.* Das naheliegende Modell ist eine Regression: eine Zahl vorhersagen, die Lieferzeit in Minuten. Eine Regression minimiert in der Regel den mittleren quadratischen Fehler, und der ist am kleinsten, wenn die Vorhersage dem Mittelwert der möglichen Zielwerte entspricht. Bei 5 Kilometern liegen die tatsächlichen Zeiten entweder um 30 oder um 70 Minuten. Der Mittelwert ist 50 Minuten, und die Auswertung zeigt: kein einziger der Fälle zwischen 4,5 und 5,5 Kilometern liegt innerhalb von fünf Minuten um diese Vorhersage (0,0 %). Die Zahl ist im Mittel richtig und in jedem Einzelfall falsch. Der Kunde bekommt eine Angabe, die nie eintritt, und erfährt nichts von dem Risiko.

*Die Lösung.* Das Pattern formuliert das Problem um. Statt eine Zahl vorherzusagen, zerlegt man den Wertebereich in Klassen (_Bins_), hier 10-Minuten-Abschnitte, und trainiert einen Klassifikator, der für jede Klasse eine Wahrscheinlichkeit liefert. Das Ergebnis ist keine Zahl mehr, sondern eine Verteilung. Der Klassifikator hat keine Annahme über die Form der Verteilung nötig und kann deshalb auch zwei Gipfel darstellen.

#code-aus("01_reframing.py", "# 3) Reframing", bis: "print(\"\\nVerteilung")
#ausgabe("01_reframing.txt", uv-run("01_reframing.py"))

In @abb-reframing stehen die Wahrscheinlichkeiten des Klassifikators neben den tatsächlichen Anteilen aus den Daten. Der Klassifikator findet die beiden Gipfel (30 und 70 Minuten) und die Lücke dazwischen. Daraus lassen sich bei Bedarf wieder Punktwerte ableiten, etwa der wahrscheinlichste Abschnitt, aber auch eine ehrliche Aussage wie "mit etwas über 40 % unter 40 Minuten und mit knapp 60 % über 60 Minuten".

#figure(
  {
    let d = json("../code/05-problem-representation/reframing.json")
    let mitte(k) = d.kanten.at(k) + 5
    daten-plot(size: (12, 5), x-label: [Lieferzeit in Minuten (Abschnitte à 10 Minuten)], y-label: [Anteil], x-min: 20, x-max: 100, y-min: 0, y-max: 0.4, x-tick-step: 10, y-tick-step: 0.1, {
      plot.add-bar(d.klassen.enumerate().map(((i, k)) => (mitte(k) - 1.8, d.wahr.at(i))), bar-width: 3.4, style: (fill: luma(190), stroke: none))
      plot.add-bar(d.klassen.enumerate().map(((i, k)) => (mitte(k) + 1.8, d.p.at(i))), bar-width: 3.4, style: (fill: rgb("#3171C6"), stroke: none))
      plot.add-vline(d.mittel, style: (stroke: (paint: orange, thickness: 1.4pt, dash: "dashed")))
    })
  },
  caption: [Die Verteilung der Lieferzeit bei 5 km. Die Regression sagt 50 Minuten voraus (orange), einen Wert in der Lücke zwischen den beiden Gipfeln. Der Klassifikator über 10-Minuten-Abschnitte (blau) trifft die tatsächlichen Anteile (grau) gut. Die erste Klasse fasst alles unter 30 Minuten zusammen.],
) <abb-reframing>

*Alternative: Quantil-Regression.* Eine zweite Möglichkeit, Unsicherheit auszudrücken, ist die Quantil-Regression @koenker_regression_quantiles_1978: Das Modell sagt nicht den Mittelwert, sondern zum Beispiel das 10- und das 90-Prozent-Quantil voraus (der Wert, unter dem 10 % beziehungsweise 90 % der Fälle liegen). Bei 5 km ergeben sich 27 und 73 Minuten, also ein Intervall, in dem 80 % der Lieferungen liegen. Das ist kompakter als eine Verteilung, zeigt aber nicht, dass dazwischen kaum etwas passiert. Das 50-Prozent-Quantil (Median) ist bei zwei gleich großen Gipfeln kaum bestimmt, weil jeder Wert in der Lücke zwischen ihnen die Daten ungefähr in zwei Hälften teilt, und damit wenig aussagekräftig; das geschätzte Ergebnis (63 Minuten) ist ein Zufallsprodukt der Schätzung und kein Befund.

*Trade-offs und Grenzen.* Die Breite der Abschnitte ist ein Kompromiss: grobe verlieren Genauigkeit innerhalb der Klasse, feine haben zu wenige Beispiele je Klasse. Der Klassifikator kennt keine Reihenfolge der Klassen und muss die Nachbarschaft aus den Daten lernen. Eine Verteilung zu schätzen verlangt mehr Daten als ein Mittelwert, die Wahrscheinlichkeiten sind nicht automatisch _kalibriert_ (zuverlässig), und die Benutzeroberfläche muss die Verteilung sinnvoll darstellen.

*Wann nicht.* Ist die Verteilung eingipflig und annähernd symmetrisch, reicht eine Regression. Auch wenn die Anwendung wirklich nur einen Zahlenwert braucht und symmetrische Fehler hinnehmbar sind, spart man sich den Umweg. Umgekehrt kann man ein Problem, dessen Klassen eine Ordnung haben (Sterne von 1 bis 5), als Regression formulieren und so die Ordnung nutzen, die eine Klassifikation ignoriert.

*Bezug zu Software Engineering.* Reframing ändert den Vertrag der Schnittstelle: Statt `predict() -> float` gibt es `predict() -> Distribution`. Das ist verwandt mit ehrlichen Rückgabetypen wie `Optional` oder `Result`, die Unsicherheit in den Typ schreiben, statt Genauigkeit vorzutäuschen. Eine falsch formulierte Aufgabe behebt man nicht durch bessere Hyperparameter, so wie sich eine falsch geschnittene API nicht durch eine bessere Implementierung rettet.

#erklaere(
  [Schreiben Sie an die Tafel: "Die Lieferung dauert im Schnitt 50 Minuten." Fragen Sie, wann das stimmt und wann nicht. Zeigen Sie dann @abb-reframing. Der Mittelwert beantwortet eine andere Frage als die, die der Kunde stellt. Die Umformulierung zwingt das Modell, die ganze Verteilung zu beschreiben und nicht nur ihre Mitte.],
  [Wann ist eine Regression trotz allem die bessere Wahl?],
  [Wenn die Verteilung der Zielgröße eingipflig und annähernd symmetrisch ist. Dann liegt der Mittelwert in der Nähe der tatsächlichen Werte, und eine einzelne Zahl ist eine brauchbare Antwort.],
)

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 3, Pattern "Reframing"; #cite(<koenker_regression_quantiles_1978>, form: "prose") für die Quantil-Regression.

== Pattern 6: Multilabel

*Szenario.* Eine Fotoplattform soll Bilder automatisch verschlagworten: Strand, Berge, Stadt, Menschen, Hund. Ein Foto kann mehrere Schlagworte tragen, "Strand" und "Hund" zum Beispiel. Im Skript `02_multilabel.py` erzeugt scikit-learn dafür 4000 künstliche Beispiele mit fünf Labels, im Mittel 2,25 pro Beispiel. Die Daten sind bewusst abstrakt; die Namen der Labels sind hier nur eine Gedankenstütze.

*Das Problem.* Das Standardwerkzeug für Klassifikation ist die _Softmax_-Funktion am Ausgang des Modells. Sie macht aus beliebigen Zahlen positive Werte, die sich zu genau 1 summieren, also eine Wahrscheinlichkeitsverteilung über Klassen, die sich gegenseitig ausschließen: Jedes Beispiel gehört genau einer Klasse an. Für ein Foto mit Strand und Hund müssten sich beide Klassen die Wahrscheinlichkeit teilen, etwa 0,5 zu 0,5, und jede zusätzliche Klasse drückt die anderen weiter nach unten, obwohl "ist ein Hund zu sehen?" und "ist ein Strand zu sehen?" unabhängige Fragen sind. Trainiert man ein Softmax-Modell trotzdem auf solchen Daten (hier mit einem zufällig gewählten der Labels je Beispiel) und nimmt die wahrscheinlichste Klasse als Antwort, bleibt höchstens ein Label je Beispiel richtig: Der F1-Wert über alle Labels sinkt auf 0,58 (gegen 0,81 beim Sigmoid-Netz weiter unten).

*Die Lösung.* Das Pattern gibt jedem Label seinen eigenen Ausgang mit einer _Sigmoid_-Funktion. Sie bildet eine beliebige Zahl auf einen Wert zwischen 0 und 1 ab und beantwortet eine einzelne Ja/Nein-Frage; jeder Ausgang ist unabhängig von den anderen, und die Summe ist beliebig (@abb-multilabel). Das Ziel eines Beispiels ist kein einzelner Klassenname mehr, sondern ein Vektor aus Nullen und Einsen ("Multi-Hot": `[1, 0, 0, 1, 0]` heißt Label 0 und 3). Als Fehlerfunktion dient die binäre Kreuzentropie je Ausgang, aufsummiert (die übliche Fehlerfunktion für Ja/Nein-Ausgaben: Sie bestraft ein sicheres, aber falsches Urteil besonders stark). Die Entscheidung "Label vergeben oder nicht" trifft ein Schwellwert, anfangs 0,5.

#figure(
  {
    let d = json("../code/05-problem-representation/multilabel.json")
    let p = d.p.at(1)
    let y = d.y.at(1)
    let spalte(titel, farbe, zeilen) = block(width: 100%, inset: 8pt, stroke: 0.7pt + farbe, radius: 3pt, {
      text(size: 9.5pt, weight: "bold", fill: farbe, titel)
      v(0.4em)
      for z in zeilen { z; linebreak() }
    })
    grid(columns: (1fr, 1fr), column-gutter: 14pt,
      spalte("Softmax: eine Verteilung, Summe = 1", orange, (
        text(size: 9pt)[Label 0 #h(1fr) 1 #h(1fr) 2 #h(1fr) 3 #h(1fr) 4],
        text(size: 9pt)[#d.softmax.map(v => str(v).replace(".", ",")).join(h(1fr))],
        text(size: 9pt, fill: grau)[Summe #str(calc.round(d.softmax.sum(), digits: 2)).replace(".", ","), wahr: #y.map(str).join(" ")],
      )),
      spalte("Sigmoid je Label: fünf Einzelfragen", gruen, (
        text(size: 9pt)[Label 0 #h(1fr) 1 #h(1fr) 2 #h(1fr) 3 #h(1fr) 4],
        text(size: 9pt)[#p.map(v => str(v).replace(".", ",")).join(h(1fr))],
        text(size: 9pt, fill: grau)[Summe #str(calc.round(p.sum(), digits: 2)).replace(".", ","), wahr: #y.map(str).join(" ")],
      )),
    )
  },
  caption: [Softmax gegen Sigmoid. Beide Seiten zeigen die echten Ausgaben für dasselbe Testbeispiel (ein Foto mit den Labels 0 und 3): links das Softmax-Modell, rechts das Netz mit Sigmoid.],
) <abb-multilabel>

#code-aus("02_multilabel.py", "# A) Sigmoid", bis: "def bericht")
#ausgabe("02_multilabel.txt", uv-run("02_multilabel.py"))

Die Tabelle am Ende der Ausgabe vergleicht vier Wege. Das Netz mit Sigmoid und Schwelle 0,5 erreicht einen F1 micro (alle Label-Entscheidungen zusammengezählt) von 0,805. Die _Hamming-Loss_ ist der Anteil falscher Einzelentscheidungen, hier 17,5 %, und "exakt" der Anteil der Beispiele, bei denen _alle_ fünf Entscheidungen stimmen (44,3 %). Der Softmax-Weg fällt deutlich ab. Der vierte Weg, das _Label Powerset_, macht aus jeder vorkommenden Kombination eine eigene Klasse (hier 31) und trainiert ein gewöhnliches Softmax-Modell. Er gewinnt bei "exakt" (46,8 %), ist aber bei F1 micro schlechter als das Sigmoid-Netz, und seine Klassenzahl kann bei $K$ Labels bis auf $2^K$ wachsen, sodass seltene Kombinationen kaum Beispiele haben.

*Schwellwerte.* Der Schwellwert 0,5 ist eine Voreinstellung, kein Naturgesetz. Im Skript wird für jedes Label auf einer eigenen Validierungsmenge der Schwellwert gewählt, der den F1-Wert dieses Labels maximiert; es ergeben sich Werte zwischen 0,28 und 0,45. Der F1 micro steigt auf 0,818, aber "exakt" sinkt von 44,3 % auf 40,5 %. Beides ist richtig: Die Metriken messen Verschiedenes, und welche zählt, ist eine fachliche Entscheidung. Für ein Verschlagwortungssystem, bei dem ein fehlendes Schlagwort weniger schadet als ein falsches, würde man die Schwellen eher anheben.

*Trade-offs und Grenzen.* Unabhängige Sigmoids behandeln jedes Label für sich. Dass "Strand" und "Meer" meist zusammen auftreten, kennt das Netz nur indirekt über die gemeinsamen versteckten Schichten. Die Schwellwerte muss man wählen und pflegen. Ein fehlendes Label in den Trainingsdaten ist oft kein Nein, sondern ein "nicht geprüft", und das Modell lernt aus beidem dasselbe. Und je Label kann die Klasse extrem selten sein (Pattern 10).

*Wann nicht.* Schließen sich die Klassen aus (eine Ziffer ist genau eine Ziffer), ist Softmax richtig und das Modell dadurch besser eingeschränkt. Gleiches gilt, wenn man genau _eine_ Antwort braucht, etwa die Zielkategorie eines Tickets.

*Bezug zu Software Engineering.* Softmax entspricht einem `enum`: Ein Wert aus einer festen Menge. Sigmoid entspricht einem Flags-Enum oder einer Menge von Tags: Jedes Flag ist einzeln gesetzt oder nicht. Wer von `enum` auf Flags wechselt, ändert den Typ der Schnittstelle, und das merken alle Aufrufer; so ist es auch hier.

#erklaere(
  [Fragen Sie, ob ein Foto von Hund und Strand zu 100 % ein Hundefoto und zu 100 % ein Strandfoto sein kann. Mit Softmax ist das unmöglich, weil sich die Wahrscheinlichkeiten zu 1 summieren. Sigmoid stellt jedem Label eine eigene Frage, und die Antworten dürfen sich zu mehr als 1 summieren. Zeigen Sie die Beispielausgabe aus @abb-multilabel mit der Summe über 1.],
  [Warum steigt der F1 micro, wenn man die Schwelle je Label wählt, aber der Anteil der exakt richtigen Beispiele sinkt?],
  [Niedrigere Schwellen finden mehr der tatsächlich vorhandenen Labels und erhöhen den Recall und damit den F1 je Label. Gleichzeitig entstehen mehr zusätzliche falsche Labels, und jedes davon macht ein sonst exaktes Beispiel unexakt.],
)

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 3, Pattern "Multilabel"; #cite(<tsoumakas_multilabel_overview_2007>, form: "prose") für einen Überblick, darin auch das Label Powerset.


== Pattern 7: Ensembles

*Szenario.* Ein Telekommunikationsanbieter will vorhersagen, welche Kunden kündigen. Im Skript `03_ensembles.py` stehen 2000 künstliche Kundendatensätze mit 20 Features bereit, von denen 8 wirklich informativ sind, und bei 8 % der Datensätze wird das Label zufällig neu gewürfelt (`flip_y=0.08`); falsch ist davon etwa die Hälfte, also rund 4 % aller Labels, wie es bei echten Daten durch Fehler im Datensatz vorkommt. Als Maß dient die Genauigkeit (Anteil richtiger Vorhersagen) in fünffacher Kreuzvalidierung: Die Daten werden fünfmal in Trainings- und Testteil zerlegt, und man mittelt über die fünf Durchgänge. Die Angabe nach dem "±" ist die Standardabweichung über die fünf Durchgänge.

*Das Problem.* Der Fehler eines Modells setzt sich (bei quadratischem Fehler; bei Klassifikation gilt es sinngemäß) aus drei Teilen zusammen. Der _Bias_ ist der systematische Fehler eines zu einfachen Modells: Es kann das Muster nicht abbilden, selbst mit unendlich vielen Daten. Die _Varianz_ misst, wie stark das Modell vom Zufall der Trainingsdaten abhängt: Ein anderer Datensatz derselben Art ergäbe ein anderes Modell. Der Rest ist unvermeidliches Rauschen. Ein tiefer Entscheidungsbaum hat wenig Bias und viel Varianz. Er teilt die Daten so lange, bis jeder Datensatz in einem eigenen Blatt liegt, und lernt dabei auch die falschen Labels auswendig. Das Ergebnis liegt in der Ausgabe unten bei etwa 0,77 Genauigkeit.

*Die Lösung.* Wenn ein einzelnes Modell instabil ist, trainiert man mehrere und kombiniert ihre Vorhersagen. Dahinter stehen drei Verfahren (@abb-ensembles).

_Bagging_ (von _bootstrap aggregating_, #cite(<breiman_bagging_1996>, form: "prose")) zieht aus den Trainingsdaten mehrfach Stichproben gleicher Größe _mit Zurücklegen_ (_Bootstrap_), trainiert auf jeder ein eigenes Modell und lässt abstimmen oder mittelt. Weil jede Stichprobe etwas anderes enthält, machen die Modelle teilweise unterschiedliche Fehler, die sich im Durchschnitt aufheben. Bagging senkt also vor allem die Varianz. Der _Random Forest_ @breiman_random_forests_2001 ist Bagging mit Entscheidungsbäumen, bei dem jede Verzweigung nur aus einer zufälligen Auswahl der Features wählen darf; das macht die Bäume noch unähnlicher.

_Boosting_ trainiert die Modelle nacheinander. Jedes neue Modell konzentriert sich auf das, was die bisherigen falsch machen. AdaBoost @freund_schapire_adaboost_1997 erreicht das, indem es falsch klassifizierte Datensätze höher gewichtet. _Gradient Boosting_ @friedman_gradient_boosting_2001 lässt das nächste Modell den verbleibenden Fehler der bisherigen Summe vorhersagen (genauer: die negative Steigung, den Gradienten, der Fehlerfunktion). Die einzelnen Modelle sind bewusst einfach (flache Bäume oder "Stümpfe" mit einer einzigen Verzweigung), und die Summe senkt den Bias. Bei verrauschten Daten kann man mit zu vielen Runden auch das Rauschen lernen.

_Stacking_ @wolpert_stacking_1992 kombiniert Modelle _verschiedener Art_. Ein zusätzliches Meta-Modell lernt, wie viel Gewicht jedem Basismodell zusteht. Wichtig: Das Meta-Modell muss mit Vorhersagen trainiert werden, die die Basismodelle für Daten gemacht haben, die sie _nicht_ gesehen haben (_out-of-fold_), sonst belohnt es Modelle, die die Trainingsdaten auswendig kennen. `StackingClassifier` aus scikit-learn erledigt das über den Parameter `cv`.

#figure(
  {
    let k = (node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 5pt)
    let t(x) = text(size: 8.5pt, x)
    let titel(x) = text(size: 9.5pt, weight: "bold", fill: blau, x)
    grid(columns: 3, column-gutter: 8pt, align: top,
      {
        titel[Bagging: parallel]
        v(2pt)
        diagram(..k, spacing: (6mm, 5mm),
          node((0, 1), t[Daten], fill: luma(242)),
          node((1, 0), t[Stichprobe 1], fill: luma(242)), node((1, 1), t[Stichprobe 2], fill: luma(242)), node((1, 2), t[Stichprobe 3], fill: luma(242)),
          node((2, 0), t[Modell], fill: blau-hell, stroke: 0.8pt + blau), node((2, 1), t[Modell], fill: blau-hell, stroke: 0.8pt + blau), node((2, 2), t[Modell], fill: blau-hell, stroke: 0.8pt + blau),
          node((3, 1), t[Mittel \ Abstimmung], fill: rgb("#E5F5EE"), stroke: 0.8pt + gruen),
          edge((0, 1), (1, 0), "->"), edge((0, 1), (1, 1), "->"), edge((0, 1), (1, 2), "->"),
          edge((1, 0), (2, 0), "->"), edge((1, 1), (2, 1), "->"), edge((1, 2), (2, 2), "->"),
          edge((2, 0), (3, 1), "->"), edge((2, 1), (3, 1), "->"), edge((2, 2), (3, 1), "->"),
        )
      },
      {
        titel[Boosting: nacheinander]
        v(2pt)
        diagram(..k, spacing: (6mm, 4.5mm),
          node((0, 0), t[Modell 1], fill: blau-hell, stroke: 0.8pt + blau),
          node((0, 1), t[Fehler stärker beachten], fill: rgb("#FBF1E6"), stroke: 0.8pt + orange),
          node((0, 2), t[Modell 2], fill: blau-hell, stroke: 0.8pt + blau),
          node((0, 3), t[Fehler stärker beachten], fill: rgb("#FBF1E6"), stroke: 0.8pt + orange),
          node((0, 4), t[Modell 3 \ … Summe], fill: rgb("#E5F5EE"), stroke: 0.8pt + gruen),
          edge((0, 0), (0, 1), "->"), edge((0, 1), (0, 2), "->"), edge((0, 2), (0, 3), "->"), edge((0, 3), (0, 4), "->"),
        )
      },
      {
        titel[Stacking: Meta-Modell]
        v(2pt)
        diagram(..k, spacing: (6mm, 5mm),
          node((0, 0), t[Random \ Forest], fill: blau-hell, stroke: 0.8pt + blau),
          node((0, 1), t[Gradient \ Boosting], fill: blau-hell, stroke: 0.8pt + blau),
          node((0, 2), t[k-Nächste \ Nachbarn], fill: blau-hell, stroke: 0.8pt + blau),
          node((1, 1), t[Meta-Modell \ (log. Regression)], fill: rgb("#E5F5EE"), stroke: 0.8pt + gruen),
          edge((0, 0), (1, 1), "->"), edge((0, 1), (1, 1), "->"), edge((0, 2), (1, 1), "->"),
        )
      },
    )
  },
  caption: [Drei Wege, Modelle zu kombinieren. Bagging trainiert parallel auf verschiedenen Stichproben, Boosting nacheinander mit wachsendem Gewicht auf den Fehlern, Stacking kombiniert verschiedene Modelltypen über ein Meta-Modell.],
) <abb-ensembles>

#code-aus("03_ensembles.py", "stack = ", bis: "modelle = {")
#ausgabe("03_ensembles.txt", uv-run("03_ensembles.py"))

Bagging, Random Forest, Gradient Boosting und Stacking schlagen den einzelnen Baum (0,771) um acht bis neun Prozentpunkte: Bagging 0,848, Random Forest 0,854, Gradient Boosting 0,858, Stacking 0,865. Dieser Abstand ist größer als die Streuung zwischen den fünf Durchgängen (rund 0,02), die Unterschiede _innerhalb_ der Ensembles sind es nicht. Welches der vier das beste ist, lässt sich aus diesem Versuch nicht ablesen. Zwei weitere Zeilen sind lehrreich. Die einfache logistische Regression (0,828) liegt vor dem tiefen Baum, auf diesen Daten ist also kein komplexes Modell nötig, um den Baum zu schlagen. Und AdaBoost mit Stümpfen (0,814) liegt unter der logistischen Regression: Ein Ensemble aus vielen schwachen Teilen ist nicht automatisch besser als ein gut gewähltes einzelnes Modell.

*Trade-offs und Grenzen.* Ein Ensemble ist so teuer wie die Summe seiner Teile: 100 Bäume brauchen grob das Hundertfache an Zeit und Speicher für eine Vorhersage, und das Ergebnis lässt sich schwerer erklären als ein einzelner Baum. Es hilft nur, wenn die Modelle _unterschiedliche_ Fehler machen; deshalb arbeiten Bagging und Random Forest mit Zufall. Der Gewinn ist oft kleiner, als man hofft: Im Versuch bringt das Stacking gegenüber Gradient Boosting weniger als einen Prozentpunkt, weniger als die Streuung, und kostet drei Modelle plus Meta-Modell.

*Wann nicht.* Wenn ein einfaches Modell schon genügt, wenn die Antwortzeit knapp bemessen ist oder wenn jede Vorhersage erklärbar sein muss, ist ein Ensemble die falsche Antwort.

*Bezug zu Software Engineering.* Das Pattern ist Redundanz mit Mehrheitsentscheid. Man kennt es aus der Fehlertoleranz: mehrere unabhängig gebaute Versionen derselben Funktion, deren Ergebnis ein Voter zusammenführt (_N-Version Programming_, eine Technik für sicherheitskritische Systeme). Die Voraussetzung ist dort dieselbe wie hier: Die Fehler der Teile dürfen nicht dieselben sein. Der Unterschied zu Pattern 8 (Cascade) liegt in der Verschaltung: Beim Ensemble sehen alle Modelle jeden Fall und stimmen ab, bei der Cascade bestimmt das erste Modell, welches andere Modell einen Fall überhaupt sieht.

#erklaere(
  [Stellen Sie eine Jury vor: Ein einzelner Juror ist launisch, jeder entscheidet etwas anders, je nachdem, welche Bewerber er zufällig zuerst gesehen hat. Fragen Sie in die Runde, ob eine Jury aus hundert launischen Jurorinnen zuverlässiger entscheidet als eine einzelne, wenn ihre Launen unabhängig sind. Bagging ist diese Jury. Boosting ist ein Juror, der aus den Fehlern des vorigen Jurors lernt, Stacking ein Vorsitzender, der gelernt hat, wem er bei welchen Fällen am meisten vertraut.],
  [Warum bringt ein Ensemble aus hundert identisch trainierten Modellen nichts?],
  [Weil alle dieselben Fehler machen. Das Mittel von hundert gleichen Antworten ist dieselbe Antwort. Nur wenn die Fehler der Modelle unabhängig sind (andere Stichproben, andere Features, andere Modelltypen), heben sie sich teilweise auf.],
)

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 3, Pattern "Ensembles"; #cite(<breiman_bagging_1996>, form: "prose") (Bagging) und @breiman_random_forests_2001 (Random Forests); #cite(<freund_schapire_adaboost_1997>, form: "prose") (AdaBoost); #cite(<friedman_gradient_boosting_2001>, form: "prose") (Gradient Boosting); #cite(<wolpert_stacking_1992>, form: "prose") (Stacking). Implementierung: scikit-learn @pedregosa_scikit_learn_2011.

== Pattern 8: Cascade

*Szenario.* Eine Versicherung prüft Schadensmeldungen auf Betrug. 75 % der Meldungen kommen von Privatkunden, 25 % von Werkstätten, die für viele Kunden abrechnen. Im Skript `04b_cascade_router.py` entstehen 40 000 künstliche Meldungen, 4 % davon Betrug. Betrug zeigt sich in beiden Gruppen an demselben Feature $x_0$, aber in entgegengesetzter Richtung: Bei Privatkunden ist ein hoher Wert verdächtig, bei Werkstätten ein niedriger. Die Daten sind erfunden, es geht um die Struktur. Zu welcher Gruppe eine Meldung gehört, ist im Betrieb nicht zuverlässig bekannt; drei weitere Features ($r$) geben nur Hinweise, und das System muss die Gruppe daraus schätzen.

*Das Problem.* Ein lineares Modell gibt $x_0$ ein einziges Gewicht und damit ein einziges Vorzeichen. Was bei Privatkunden Betrug anzeigt, würde bei Werkstätten Unverdächtige belasten, und das Modell findet einen Kompromiss, der keiner Gruppe gerecht wird. Allgemein gilt: Soll ein Modell zwei Teilpopulationen mit verschiedenen Mustern zugleich lernen, lernt es einen Durchschnitt. Es ist dieselbe Struktur wie bei Pattern 3: Der Einfluss eines Features hängt von einem anderen Feature (hier dem Segment) ab.

*Die Lösung.* Das Pattern zerlegt die Aufgabe in eine Kette von Modellen, bei der die Ausgabe des einen bestimmt, was das nächste tut (@abb-cascade-router). Ein erstes Modell, der _Router_, beantwortet die Vorfrage "Welche Art von Fall ist das?". Danach arbeitet ein _Spezialist_, der nur Fälle dieser Art gelernt hat, und macht die eigentliche Vorhersage. Der Router ist selbst ein Klassifikator mit eigener Fehlerrate und eigenen Metriken. Im Training lernt der Router das bekannte Segment aus $r$, jeder Spezialist lernt auf den Fällen seines Segments.

#figure(
  {
    let t(x) = text(size: 9pt, x)
    diagram(
      node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 6pt, spacing: (13mm, 9mm),
      node((0, 1), t[Meldung \ ($x$ und $r$)], fill: luma(242)),
      edge((0, 1), (1, 1), "->"),
      node((1, 1), t[Router \ Segment aus $r$ schätzen], fill: blau-hell, stroke: 0.8pt + blau),
      edge((1, 1), (2, 0), "->", label: t[Privat], label-side: left),
      edge((1, 1), (2, 2), "->", label: t[Werkstatt], label-side: right),
      node((2, 0), t[Spezialist A \ gelernt auf Privatfällen], fill: blau-hell, stroke: 0.8pt + blau),
      node((2, 2), t[Spezialist B \ gelernt auf Werkstattfällen], fill: blau-hell, stroke: 0.8pt + blau),
      edge((2, 0), (3, 1), "->"),
      edge((2, 2), (3, 1), "->"),
      node((3, 1), t[Betrugsscore], fill: rgb("#E5F5EE"), stroke: 0.8pt + gruen),
      node((1, 2.9), text(size: 8.5pt, fill: orange)[Routing-Fehler: Der Spezialist sieht \ einen Fall, den er nie gelernt hat], stroke: 0.6pt + orange, fill: rgb("#FBF1E6")),
      edge((1, 1), (1, 2.9), "--", stroke: (paint: orange, dash: "dashed")),
    )
  },
  caption: [Cascade als Router mit zwei Spezialisten. Orange: Was der Router falsch einordnet, sieht der falsche Spezialist.],
) <abb-cascade-router>

#code-aus("04b_cascade_router.py", "# c) Cascade", bis: "fehl = ")
#ausgabe("04b_cascade_router.txt", "uv run --with scikit-learn --with numpy python 04b_cascade_router.py")

Das lineare Einzelmodell erreicht eine ROC-AUC von 0,641 (0,5 wäre Raten), die Cascade 0,759. Wüsste man das Segment sicher (Zeile "Orakel", im Betrieb nicht verfügbar), wären es 0,805; die Differenz geht auf das Konto der Routing-Fehler. Der Router liegt in 91,7 % der Fälle richtig. Für die übrigen 8,3 % ist das Ergebnis schlimmer als Raten: Der Spezialist wendet ein Muster an, das für diese Gruppe umgekehrt gilt, und die AUC nur über diese Fälle beträgt 0,237.

Ein ehrlicher Vergleich gehört dazu. Ein Baummodell (`HistGradientBoostingClassifier`), das $x$ und $r$ ohne Router bekommt, erreicht 0,737, nicht weit von der Cascade entfernt. Bei rund 640 Betrugsfällen in den Testdaten ist der Abstand von zwei AUC-Punkten nicht belastbar. Wo ein flexibles Modell die Wechselwirkung selbst lernen kann, ist ein einzelnes Modell die einfachere Lösung. Die Cascade lohnt sich eher, wenn die Spezialisten bewusst einfach und erklärbar bleiben sollen oder die Gruppen verschiedene Daten, Features oder Teams haben.

*Fehlerfortpflanzung und Trainingsfalle.* Die Kette erbt die Fehler des Routers. Sind Router und Spezialist unabhängig zu 95 % und 90 % richtig und verdirbt jeder Routing-Fehler das Ergebnis, ist die Kette höchstens in 85,5 % der Fälle richtig. Dazu kommt eine Falle beim Training: Im Skript lernen die Spezialisten auf dem _wahren_ Segment, im Betrieb bekommen sie aber alles, was der Router _sagt_. Training und Betrieb sehen dann verschiedene Daten, ein kleiner Training-Serving Skew innerhalb der Kette. Trainiert man die Spezialisten stattdessen auf den Router-Ausgaben, ist jede Änderung am Router ein Grund, sie neu zu trainieren. Man prüft deshalb die ganze Kette Ende zu Ende und protokolliert die Router-Entscheidung zu jeder Vorhersage, damit man Fehlleitungen später auswerten kann.

=== Verwandt: die Konfidenz-Kaskade

Derselbe Name steht auch für eine Technik mit anderem Ziel: nicht Spezialisierung, sondern Kosten. Ein billiges Modell entscheidet die klaren Fälle, nur die unsicheren gehen an ein teures Modell. Das klassische Beispiel ist die Gesichtserkennung von #cite(<viola_jones_cascade_2001>, form: "prose"): Billige frühe Stufen verwerfen die allermeisten Bildausschnitte, nur wenige Kandidaten erreichen die teuren späteren Stufen. Hier das Prinzip an Kartenzahlungen (@abb-cascade-konfidenz, Skript `04_cascade.py`: 60 000 künstliche Zahlungen, 1 % Betrug; vier billige Features stehen in der Zahlung, 16 teure müssen bei anderen Diensten abgefragt werden). Die erste Stufe, eine logistische Regression auf den billigen Features, bekommt eine niedrige Schwelle: Im Training liegen fünf Prozent der Betrugsfälle unter ihr, sie lässt also fast alle echten Fälle durch und dafür viele harmlose. Auf den Testdaten sind das 6,6 % aller Zahlungen, darunter 94,9 % der Betrugsfälle.

#figure(
  {
    let d = json("../code/05-problem-representation/cascade.json")
    let z(n) = if n >= 1000 { str(n).slice(0, -3) + "\u{00A0}" + str(n).slice(-3) } else { str(n) }
    let t(x) = text(size: 9pt, x)
    diagram(
      node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 7pt, spacing: (38mm, 10mm),
      node((0, 0), t[Alle Zahlungen im Test \ #z(d.n) davon #d.pos Betrug], fill: luma(242)),
      edge((0, 0), (0, 1), "->"),
      node((0, 1), t[Stufe 1 \ billig, niedrige Schwelle], fill: blau-hell, stroke: 0.8pt + blau),
      edge((0, 1), (0, 2), "->", label: t[#z(d.durch) durchgelassen, \ Recall #str(d.r1).replace(".", ",")], label-side: left, label-sep: 4pt),
      node((0, 2), t[Stufe 2 \ teures Modell], fill: blau-hell, stroke: 0.8pt + blau),
      edge((0, 2), (0, 3), "->", label: t[Alarm, \ Recall gesamt #str(d.r_gesamt).replace(".", ",")], label-side: left, label-sep: 4pt),
      node((0, 3), t[Entscheidung], fill: rgb("#E5F5EE"), stroke: 0.8pt + gruen),
      edge((0, 1), (1, 1), "->", label: t[#z(d.n - d.durch) verworfen], label-side: left, label-sep: 3pt),
      node((1, 1), t[kein Betrug \ (endgültig)], fill: rgb("#FBF1E6"), stroke: 0.8pt + orange),
    )
  },
  caption: [Die Konfidenz-Kaskade im Skript. Die Zahlen sind die echten Werte aus `04_cascade.py`. Was Stufe 1 verwirft, sieht Stufe 2 nie.],
) <abb-cascade-konfidenz>

#code-aus("04_cascade.py", "# Stufe 2", bis: "# Vergleich")
#ausgabe("04_cascade.txt", uv-run("04_cascade.py"))

Nur für die 1578 von 24 000 durchgelassenen Zahlungen müssen die teuren Features abgefragt werden; ein einzelnes Modell auf allen Features bräuchte sie für alle 24 000. Die zweite Stufe findet von den Durchgelassenen 64,0 %, die Kaskade insgesamt 60,8 % bei einer Precision von 95,4 %. Das einzelne Modell kommt auf 58,6 % Recall bei 85,3 % Precision. Dass die Kaskade hier nicht schlechter, sondern etwas besser abschneidet, sollte man nicht überbewerten: 237 Betrugsfälle sind wenige. Eine mögliche Erklärung ist, dass die zweite Stufe auf Daten trainiert, in denen Betrug rund 14 % ausmacht (im Test 225 von 1578) statt 1 %, also deutlich weniger unbalanciert ist (Pattern 10).

Auch hier pflanzen sich Fehler fort: Die Recalls der Stufen multiplizieren sich (94,9 % mal 64,0 % ergeben 60,8 %), und was Stufe 1 verwirft, holt keine spätere Stufe zurück. Deshalb baut man die erste Stufe auf hohen Recall. Die zweite Stufe trainiert man auf den Daten, die die erste durchlässt (`Xtr[durch_tr]`), weil sie im Betrieb nie etwas anderes sieht; ändert sich die erste Stufe, muss sie neu trainiert werden.

*Trade-offs und Grenzen.* Beide Varianten kosten Einfachheit: mehrere Modelle, Schwellen und Versionen, die zusammenpassen müssen und gemeinsam überwacht werden. Je Spezialist stehen weniger Beispiele zur Verfügung, was die Varianz erhöht. Pattern 19 (Two-Phase Predictions, Kapitel 8) ist verwandt, aber der Anlass ist ein anderer: Dort läuft ein leichtes Modell auf dem Gerät und ein schweres in der Cloud, und Bandbreite und Latenz bestimmen die Aufteilung.

*Wann nicht.* Bevor man eine Cascade baut, probiert man die einfacheren Mittel: ein Modell mit dem Segment als zusätzlichem Feature, ein Feature Cross (Pattern 3) oder ein Baummodell, das Wechselwirkungen selbst bildet. Eine Cascade ist unnötig, wenn sich die Gruppen nicht gegensätzlich verhalten, wenn das Segment nicht zuverlässig bestimmbar ist (ein schwacher Router verdirbt alles) oder wenn je Segment zu wenige Daten vorliegen. Bei der Konfidenz-Kaskade gilt: Ein einzelnes Modell, das schnell und genau genug ist, ersetzt sie, und ohne hohen Recall bei kleiner Durchlassquote in der ersten Stufe lohnt sie nicht.

*Bezug zu Software Engineering.* Der Router ist ein Dispatcher: Wie beim Strategy-Pattern wird zur Laufzeit entschieden, welche Implementierung arbeitet, nur dass die Entscheidung selbst fehlbar ist. Dazu passt die Erfahrung mit Dienstketten: Verfügbarkeit und Korrektheit multiplizieren sich mit jedem Glied, und man testet die Kette Ende zu Ende statt nur ihre Teile. Die Konfidenz-Kaskade kennt man als "billig vor teuer": ein Cache vor dem Backend, ein Bloom-Filter vor dem Datenbankzugriff, Short-Circuit-Auswertung (`a and b` ruft `b` nur auf, wenn `a` wahr ist), mit der Besonderheit, dass jedes Glied einen Fehler macht, der sich nicht mehr korrigieren lässt.

#erklaere(
  [Beschreiben Sie die Telefonzentrale einer Versicherung: Die erste Mitarbeiterin fragt nur, worum es geht, und verbindet mit der Sachbearbeiterin für Privat- oder für Werkstattschäden. Das funktioniert, weil beide Sachbearbeiterinnen ihr Gebiet sehr gut kennen. Fragen Sie dann, was passiert, wenn die Zentrale falsch verbindet, und zeigen Sie @abb-cascade-router.],
  [Warum ist ein falsch gerouteter Fall hier schlimmer als ein Fall, den ein einzelnes Modell falsch einschätzt?],
  [Der Spezialist wendet ein Muster an, das für diese Gruppe umgekehrt gilt. Im Skript ist die AUC der falsch gerouteten Fälle 0,237, also schlechter als Raten, während ein einzelnes Modell zumindest einen Kompromiss anbietet.],
)

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 3, Pattern "Cascade"; #cite(<viola_jones_cascade_2001>, form: "prose") für die Konfidenz-Kaskade. Die Daten beider Skripte sind künstlich. _Offen:_ Die Beschreibung des Pattern (Router und Spezialisten, Training auf dem wahren Segment als Falle) folgt dem Glossar und den Folien dieser Lehrveranstaltung und dem Gedächtnis; die Buchstelle selbst konnte hier nicht am Text nachgeprüft werden und sollte vor der Verwendung in der Lehre nachgelesen werden.


== Pattern 9: Neutral Class

*Szenario.* Ein Händler will Produktrezensionen automatisch als positiv oder negativ erkennen, damit der Support die negativen zuerst sieht. Für das Training haben drei Personen (die _Labeler_) jede Rezension unabhängig mit einem Label versehen, also mit der Antwort "positiv" oder "negativ", die das Modell später vorhersagen soll. Im Skript `05_neutral_class.py` entstehen 30 000 künstliche Rezensionen. Eine im Betrieb unbekannte "wahre Stimmung" $s$ bestimmt, wie die Labeler urteilen: Jede Person sagt mit der Wahrscheinlichkeit $1 / (1 + e^(-5 s))$ "positiv". Bei $s = 0$ ist das ein Münzwurf, ab $|s| > 1$ sind sich praktisch alle einig. Das Modell sieht ein verrauschtes Abbild von $s$ und fünf Spalten reines Rauschen. In 77,8 % der Fälle urteilen alle drei gleich, in den übrigen steht es 2 zu 1.

*Das Problem.* Aus den drei Urteilen macht man üblicherweise ein binäres Label per Mehrheit. Bei 2 zu 1 ist dieses Label aber kaum mehr als ein Zufallsergebnis: Der Text liegt auf der Grenze, und welche Seite zufällig die Mehrheit bekam, sagt über den Text nichts. Das Modell wird trotzdem darauf trainiert, diese Fälle richtig zu entscheiden, und es versucht, das Rauschen zu lernen. Im Betrieb liefert es auch für Grenzfälle eine Ja/Nein-Antwort, und nichts an der Antwort zeigt, dass es hier eine Münze war. Misst man den Fehler des binären Modells gegen das Mehrheitslabel, ergibt sich bei den einstimmigen Fällen 4,0 %, bei den strittigen 31,0 %. Die zweite Zahl sagt nicht, dass das Modell dort schlecht ist; sie misst, wie zufällig das Referenzlabel selbst ist.

*Die Lösung.* Das Pattern führt eine dritte Klasse ein: _neutral_. Sie steht für Beispiele, bei denen die Labeler uneinig sind, oder, wenn Bewertungen mit Sternen vorliegen, für die mittlere Stufe. Das Modell hat drei Ausgänge (positiv, neutral, negativ), und der Betrieb behandelt "neutral" anders als eine Entscheidung: Man gibt den Fall an einen Menschen, zeigt keine Empfehlung oder fällt auf einen Standard zurück. Im Skript wird das aus der Uneinigkeit direkt abgeleitet (`einig`), und es entsteht ein zweites Modell mit derselben Technik, aber drei Klassen.

#code-aus("05_neutral_class.py", "stimmen = ", bis: "print(f\"Labeler einstimmig")
#ausgabe("05_neutral_class.txt", uv-run("05_neutral_class.py"))

Das binäre Modell macht bei den einstimmigen Fällen 4,0 % Fehler und bei den strittigen 31,0 %. Die zweite Zahl misst gegen das Mehrheitslabel, das dort fast ein Münzwurf ist, und sagt deshalb vor allem etwas über den Zufall im Label. Auffällig ist die mittlere Sicherheit des Modells bei den strittigen Fällen: 0,78. Es tut also so, als wüsste es, was es nicht wissen kann. Das Drei-Klassen-Modell antwortet bei 51,4 % der strittigen und bei 12,8 % der einstimmigen Fälle "neutral", entscheidet 79,0 % aller Fälle automatisch und macht darunter 3,5 % Fehler.

Ein Vergleich, der das Pattern nicht schönt: Ein binäres Modell, das nur die sichersten 79,0 % der Fälle entscheidet (Konfidenzschwelle), kommt auf 3,4 % Fehler, also auf dasselbe. In diesem Versuch bringt die dritte Klasse keine bessere Genauigkeit als eine passend gewählte Schwelle. Ihr Nutzen liegt woanders: Die Schwelle muss man von Hand festlegen, die neutrale Klasse lernt aus den Daten, wo die Menschen selbst uneins sind. Das Produkt bekommt eine ausdrückliche Antwort mit eigener Bedeutung, und das Label bildet ab, was die Labeler tatsächlich gesagt haben. Ob die dritte Klasse bei echten Daten außerdem die Qualität der beiden Hauptklassen verbessert, weil das Modell nicht mehr auf Münzwurf-Labels trainiert wird, kann dieser Versuch nicht zeigen. Das bleibt hier offen.

@abb-neutral zeigt, wo das Drei-Klassen-Modell neutral antwortet, aufgetragen über der wahren Stimmung. In den beiden Streifen um $s = 0$, in denen die Labeler am häufigsten uneins sind, antwortet das Modell in knapp zwei Dritteln der Fälle neutral (63,6 % und 66,5 %), ab $|s| > 1$ praktisch nie. Das Modell hat nur die Rezension gesehen, nicht $s$; die Breite der neutralen Zone ist ein Ergebnis des Trainings.

#figure(
  {
    let d = json("../code/05-problem-representation/neutral_class.json").kurve
    daten-plot(size: (12, 5), x-label: [wahre Stimmung $s$ (im Betrieb unbekannt)], y-label: [Anteil der Vorhersagen], x-min: -2, x-max: 2, y-min: 0, y-max: 1.02, x-tick-step: 0.5, y-tick-step: 0.25, legend: "south", {
      plot.add(d.map(p => (p.s, p.neg)), style: (stroke: 1.4pt + orange), label: [negativ])
      plot.add(d.map(p => (p.s, p.neu)), style: (stroke: 1.4pt + luma(120)), label: [neutral])
      plot.add(d.map(p => (p.s, p.pos)), style: (stroke: 1.4pt + gruen), label: [positiv])
      plot.add(d.map(p => (p.s, p.einig)), style: (stroke: (paint: rgb("#3171C6"), dash: "dashed", thickness: 1pt)), label: [Labeler einstimmig])
    })
  },
  caption: [Das Drei-Klassen-Modell auf den Testdaten. Die Linien zeigen, wie oft das Modell negativ, neutral oder positiv sagt, aufgetragen über der wahren Stimmung. Gestrichelt: Anteil der Fälle, in denen alle drei Labeler einig waren.],
) <abb-neutral>

*Trade-offs und Grenzen.* Das Pattern setzt Information über die Uneinigkeit voraus, also mehrere Labeler je Beispiel oder eine abgestufte Bewertung, und das kostet Aufwand. Die Klasse "neutral" ist selbst unscharf, sie hängt davon ab, wer gelabelt hat, und die Labeler können gemeinsam danebenliegen. Sie ist oft klein (Pattern 10), und jemand muss entscheiden, was mit einer neutralen Vorhersage geschieht.

*Wann nicht.* Wenn die Wahrheit objektiv feststellbar ist (der Tumor ist bösartig oder nicht, das Ergebnis liegt aus einer Biopsie vor), ist Uneinigkeit der Labeler ein Qualitätsproblem, und man sollte die Labels verbessern, nicht eine dritte Klasse einführen. Und wenn das Produkt in jedem Fall eine Entscheidung braucht und es keinen Ort für die Weiterleitung gibt, hilft eine neutrale Antwort nicht.

*Bezug zu Software Engineering.* Die dritte Klasse ist ein dritter Wahrheitswert. Aus der dreiwertigen Logik von SQL kennt man das (`TRUE`, `FALSE`, `UNKNOWN`), und es gilt dieselbe Faustregel: Wer ein "weiß nicht" in ein Ja/Nein zwingt, bekommt Fehler, die man nicht sieht. Die Weiterleitung neutraler Fälle an einen Menschen ist ein Fallback-Pfad, wie man ihn für kontrollierte Degradation (_Graceful Degradation_) einbaut.

#erklaere(
  [Fragen Sie: Drei Kolleginnen bewerten dieselbe Rezension, zwei sagen positiv, eine sagt negativ. Ist die Rezension positiv? Lassen Sie abstimmen und erklären, dass die Antwort "positiv" hier mehr verspricht, als in den Daten steckt. Das Modell soll das nicht überspielen, sondern sagen können, dass der Fall strittig ist.],
  [Worin unterscheidet sich die neutrale Klasse von einem binären Modell, das bei Wahrscheinlichkeit nahe 0,5 nicht entscheidet?],
  [Das binäre Modell weiß nicht, ob die 0,5 von einem strittigen Fall oder von zu wenigen Daten kommt, und die Grenze legt man von Hand fest. Die neutrale Klasse lernt aus der Uneinigkeit der Labeler, was strittig ist, und macht sie zu einer eigenen, ausgewerteten Antwort.],
)

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 3, Pattern "Neutral Class". Die Daten sind künstlich; die Simulation der Labeler ist für das Handbuch konstruiert.

== Pattern 10: Rebalancing

*Szenario.* Ein Zahlungsdienstleister will betrügerische Transaktionen erkennen. Im Skript `06_rebalancing.py` stehen 200 000 künstliche Transaktionen, von denen 0,5 % Betrug sind (1000 Fälle). Davon gehen 60 % ins Training (600 Betrugsfälle), je 20 % in Validierung und Test (je 200 Betrugsfälle bei 40 000 Transaktionen).

*Das Problem.* Ein Modell, das _nie_ Betrug meldet, hat eine Genauigkeit von 99,5 % und ist wertlos. Der Fehler liegt im Verfahren. Das Training summiert den Fehler über alle Beispiele, und 99,5 % davon stammen von der Mehrheitsklasse; das einfachste Mittel, ihn zu senken, ist, überall "kein Betrug" zu sagen. Das Modell sieht außerdem sehr wenige positive Beispiele, aus denen es lernen kann, was Betrug auszeichnet, und die gewohnte Metrik, Genauigkeit, bemerkt davon nichts.

*Die Lösung.* Das Pattern besteht aus zwei Teilen: den richtigen Metriken und mehreren Möglichkeiten, die Daten oder das Training anzupassen. @abb-rebalancing zeigt, wo die einzelnen Maßnahmen ansetzen.

#figure(
  diagram(
    node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 6pt, spacing: (11mm, 11mm),
    node((0, 0), text(size: 9pt)[Trainingsdaten], fill: luma(242)),
    edge("->"),
    node((1, 0), text(size: 9pt)[Training \ (Fehlerfunktion)], fill: luma(242)),
    edge("->"),
    node((2, 0), text(size: 9pt)[Wahrscheinlichkeit \ für Betrug], fill: luma(242)),
    edge("->"),
    node((3, 0), text(size: 9pt)[Schwellwert], fill: luma(242)),
    edge("->"),
    node((4, 0), text(size: 9pt)[Entscheidung], fill: luma(242)),
    node((0, 1), text(size: 8.5pt, fill: orange)[*Downsampling* \ *Upsampling, SMOTE*], stroke: none),
    node((1, 1), text(size: 8.5pt, fill: orange)[*Klassengewichte*], stroke: none),
    node((3, 1), text(size: 8.5pt, fill: orange)[*Schwelle verschieben*], stroke: none),
    node((2, 1), text(size: 8.5pt, fill: gruen)[*Metriken: Precision, \ Recall, PR-AUC*], stroke: none),
    edge((0, 0), (0, 1), "-", stroke: (paint: orange, dash: "dotted")),
    edge((1, 0), (1, 1), "-", stroke: (paint: orange, dash: "dotted")),
    edge((3, 0), (3, 1), "-", stroke: (paint: orange, dash: "dotted")),
    edge((2, 0), (2, 1), "-", stroke: (paint: gruen, dash: "dotted")),
  ),
  caption: [Rebalancing greift an verschiedenen Stellen an: an den Daten, an der Fehlerfunktion oder an der Entscheidung nach dem Modell. Welche Metriken man verwendet, gilt für alle Varianten.],
) <abb-rebalancing>

*Metriken.* Zuerst muss man das Richtige messen. Genauigkeit eignet sich nicht. Precision und Recall zeigen, wie viele Alarme berechtigt sind und wie viele echte Fälle gefunden werden. Die _PR-AUC_ (genauer: die _average precision_) fasst die Precision-Recall-Kurve über alle Schwellen zu einer Zahl zusammen, wobei als Vergleichswert für ein Modell ohne Können die Basisrate (hier 0,5 %) gilt. Die bekanntere ROC-AUC kann bei starker Unbalance zu optimistisch wirken, weil sie die vielen Negativen als Rechengrundlage nimmt; #cite(<saito_precision_recall_2015>, form: "prose") haben das ausführlich gezeigt.

*Downsampling.* Man wirft Beispiele der Mehrheitsklasse weg, bis das Verhältnis erträglich ist, hier 1 zu 10 (600 Positive, 6000 Negative). Das Modell sieht Betrug nun in jedem elften Beispiel. Man verliert Daten und damit Information über die Mehrheit.

*Klassengewichte.* Statt Daten zu verändern, gewichtet man den Fehler: Ein übersehener Betrug zählt dann etwa so viel wie 200 übersehene Normaltransaktionen (`class_weight="balanced"`). Das kostet keine Daten, man behält alles, aber die Optimierung wird empfindlicher für die wenigen positiven Beispiele.

*Upsampling und SMOTE.* Man vermehrt die Minderheit. Einfaches Kopieren (_Oversampling_) führt dazu, dass das Modell die wenigen Beispiele auswendig lernt. SMOTE @chawla_smote_2002 erzeugt stattdessen _synthetische_ Beispiele: Es wählt ein positives Beispiel, sucht dessen nächste positive Nachbarn und legt einen neuen Punkt zufällig auf der Verbindungsstrecke zu einem davon. Im Skript kommt die Implementierung aus der Bibliothek imbalanced-learn @lemaitre_imbalanced_learn_2017.

*Schwelle verschieben.* Man ändert das Modell gar nicht und senkt stattdessen den Schwellwert, ab dem eine Wahrscheinlichkeit als "Betrug" gilt, von 0,5 auf einen auf Validierungsdaten gewählten Wert. Das ist die billigste Variante und oft genauso wirksam.

#code-aus("06_rebalancing.py", "rng = np.random.default_rng(0)", bis: "print(f\"\\n{'Strategie")
Für die Schwelle wird auf den Validierungsdaten der Wert gesucht, der den F1-Wert maximiert, aus den Quantilen der vorhergesagten Wahrscheinlichkeiten:

#code-aus("06_rebalancing.py", "    # Schwelle verschieben", bis: "    print(f\"{name:27s}")
#ausgabe("06_rebalancing.txt", "uv run --with scikit-learn --with imbalanced-learn python 06_rebalancing.py")

Die Tabelle am Ende der Ausgabe enthält das Wesentliche. Die ROC-AUC liegt bei allen vier Modellen bei 0,96 und unterscheidet sie nicht. Bei der Schwelle 0,5 sehen sie dagegen sehr verschieden aus. Die Baseline ist vorsichtig (Precision 0,67, Recall 0,15: nur 29 der 200 Betrugsfälle gefunden). Klassengewichte und SMOTE sind das Gegenteil: Recall 0,90 und 0,89, aber eine Precision von nur etwa 0,04. Die Konfusionsmatrix (eine Tabelle, die wahre gegen vorhergesagte Klassen zählt) der gewichteten Variante macht das konkret: 180 gefundene Betrugsfälle, aber auch 4688 Fehlalarme bei 40 000 Transaktionen. Das Downsampling liegt dazwischen (Recall 0,66, Precision 0,18) und hat bei 0,5 den besten F1-Wert (0,28).

Dieser Unterschied ist ein verschobener Arbeitspunkt und kein besseres Modell. Die PR-AUC, die die Rangfolge der Vorhersagen über alle Schwellen misst, ist bei der Baseline mit 0,368 sogar am höchsten (0,314 bis 0,345 bei den anderen). Wählt man für jedes Modell die Schwelle auf den Validierungsdaten (Spalte F1\*), liegen alle vier zwischen 0,36 und 0,40. Bei nur 200 positiven Testbeispielen ist dieser Unterschied nicht belastbar. Rebalancing verschiebt also vor allem, an welcher Stelle der Precision-Recall-Kurve das Modell arbeitet. Die Schwelle erreicht dasselbe mit einer Zeile Code und ohne Neutraining. Für ein besseres Modell braucht es bessere Features oder mehr Daten, und nicht unbedingt ein ausgeglicheneres Training.

#figure(
  {
    let d = json("../code/05-problem-representation/rebalancing.json")
    let farben = (rgb("#B5651D"), rgb("#2EAE7D"), rgb("#3171C6"), rgb("#7A4FA3"))
    daten-plot(size: (11, 5), x-label: [Recall], y-label: [Precision], x-min: 0, x-max: 1, y-min: 0, y-max: 1.02, x-tick-step: 0.25, y-tick-step: 0.25, legend: "south", {
      for (i, (name, k)) in d.kurven.pairs().enumerate() {
        plot.add(k.recall.zip(k.precision), style: (stroke: 1.3pt + farben.at(i)), label: [#name (PR-AUC #str(d.ap.at(name)).replace(".", ","))])
      }
      plot.add(((0, d.basisrate), (1, d.basisrate)), style: (stroke: (paint: luma(150), dash: "dotted", thickness: 1pt)), label: [Basisrate #prozent(d.basisrate)])
    })
  },
  caption: [Precision-Recall-Kurven der vier trainierten Varianten auf den Testdaten. Je weiter oben rechts, desto besser; die gepunktete Linie ist die Basisrate (Raten).],
) <abb-pr-rebalancing>

*Trade-offs und Grenzen.* Wer die Verteilung ändert, ändert die Bedeutung der Wahrscheinlichkeiten: Ein Modell, das mit 1 zu 10 oder mit Gewichten trainiert wurde, überschätzt die Betrugswahrscheinlichkeit systematisch (die Spalte "mittl.P" in der Ausgabe zeigt es). Für Entscheidungen über einen Schwellwert ist das unproblematisch, wer die Zahlen als echte Wahrscheinlichkeiten braucht, muss nachkalibrieren. Dann gilt eine Regel ohne Ausnahme: Validierungs- und Testdaten bleiben unverändert. Man wendet Upsampling und SMOTE nur auf Trainingsdaten an, nach der Aufteilung. Wer vor der Aufteilung synthetische Beispiele erzeugt, hat Kopien und Nachbarn im Test.

*Wann nicht.* Bei mäßiger Unbalance (Verhältnis 1 zu 5 oder besser) und genug positiven Beispielen ist oft keine Maßnahme nötig. Gibt es kaum Beispiele der Minderheit (einige Dutzend), hilft Rebalancing nicht; dann ist es sinnvoller, das Problem als Anomalieerkennung zu formulieren (Pattern 5): Das Modell lernt, was normal ist, und meldet Abweichungen.

*Bezug zu Software Engineering.* Das Pattern ähnelt dem Umgang mit seltenen Fehlerfällen im Testen. Wer nur mit Daten testet, in denen Fehler 0,5 % ausmachen, prüft vor allem den Normalfall. Für die Entwicklung legt man deshalb gezielt Fehlerfälle nach, so wie hier die Minderheit vermehrt wird. Für die Abnahme zählt die echte Verteilung, deshalb bleiben die Testdaten unverändert, und "99,5 % grün" sagt bei so schiefen Daten nichts aus.

#erklaere(
  [Beginnen Sie mit dem Modell, das nie Betrug meldet, und fragen Sie nach seiner Genauigkeit (99,5 %). Erst nach der Verblüffung kommen Precision und Recall. Anschließend die Frage, wo man ansetzen kann: an den Daten, an der Fehlerfunktion, an der Schwelle (@abb-rebalancing).],
  [Warum darf man SMOTE nur auf den Trainingsdaten anwenden und nicht vor der Aufteilung?],
  [Synthetische Beispiele liegen auf Verbindungsstrecken zwischen echten. Landet ein echtes Beispiel im Training und sein Nachbar im Test, kennt das Modell den Testfall quasi schon, und die Testergebnisse sind zu gut.],
)

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 3, Pattern "Rebalancing"; #cite(<chawla_smote_2002>, form: "prose") (SMOTE); #cite(<saito_precision_recall_2015>, form: "prose"); #cite(<he_garcia_imbalanced_2009>, form: "prose"). Die Daten sind künstlich.

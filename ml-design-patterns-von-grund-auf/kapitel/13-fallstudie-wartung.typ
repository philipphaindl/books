#import "../lib.typ": *
#import "@preview/cetz-plot:0.1.2": plot

#let gruen = rgb("#2EAE7D")
#let gruen-hell = rgb("#E4F5EE")
#let orange = rgb("#B5651D")
#let orange-hell = rgb("#FBF1E6")
#let nebel = luma(240)
#let klein(t) = text(size: 8.5pt, fill: grau, t)
#let knoten(pos, body, farbe: blau, grund: blau-hell, ..args) = node(pos, body, stroke: farbe, fill: grund, ..args)
#let neben(pos, body, ..args) = node(pos, body, stroke: 0.6pt + luma(150), fill: nebel, ..args)

// Ausschnitt aus einer Code-Datei: ab der ersten Zeile mit `ab` bis vor die erste folgende Zeile mit `bis`.
// Der gezeigte Code ist damit zeichengleich mit der ausgeführten Datei.
#let code-aus(datei, ab, bis: none) = {
  let zeilen = read(datei).split("\n")
  let a = zeilen.position(z => z.contains(ab))
  let b = if bis == none { zeilen.len() } else { a + 1 + zeilen.slice(a + 1).position(z => z.contains(bis)) }
  let teil = zeilen.slice(a, b)
  let einzug = calc.min(..teil.filter(z => z.trim() != "").map(z => z.len() - z.trim(at: start).len()))
  raw(teil.map(z => if z.len() >= einzug { z.slice(einzug) } else { z }).join("\n").trim("\n", at: end), lang: "python", block: true)
}
// Echte Ausgabe eines Laufs als Konsolenfenster, davor der Befehl.
#let lauf(skript, datei, von: 0, bis: none, nur: none) = {
  let z = read(datei).trim("\n", at: end).split("\n")
  let z = if nur == none { z.slice(von, bis) } else { nur.map(i => z.at(i)) }
  raw("$ python " + skript + "\n" + z.join("\n"), lang: "terminal", block: true)
}
// Zahlen aus den Ausgabedateien: eine Zeile, in der `muster` vorkommt
#let zeile(datei, muster) = read(datei).split("\n").find(z => z.contains(muster))

#let verlauf = csv("../code/13/out/pumpe_verlauf.csv", row-type: dictionary).map(r => (float(r.h_vor_ausfall), float(r.vib), float(r.temp), float(r.druck)))
#let pumpen-test = csv("../code/13/out/split_pumpen.csv", row-type: dictionary).map(r => r.test == "1")

= Fallstudie B: Vorausschauende Wartung von Industriepumpen

#set figure(placement: auto)

Die erste Fallstudie arbeitet mit Tabellen: eine Zeile pro Kunde, Merkmale daneben, ein Etikett dahinter. Hier geht es um eine andere Sorte Daten, nämlich *Zeitreihen*. Ein Sensor liefert in festem Takt Messwerte, und die Reihenfolge der Werte ist Teil der Information. Das verändert, wie man Daten aufteilt, wie man Merkmale berechnet und was im Betrieb schiefgehen kann. Die meisten dieser Stolperstellen sind Patterns aus dem Buch von #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), und an einer einzigen Aufgabe lässt sich zeigen, wie sie ineinandergreifen.

Die Aufgabe: Ein Chemiepark betreibt 30 Kreiselpumpen. Jede meldet jede Minute drei Werte, nämlich Schwingungsstärke (Vibration), Lagertemperatur und Förderdruck. Fällt eine Pumpe unvorbereitet aus, steht ein Teil der Anlage still. Kündigt sich der Ausfall dagegen einen Tag vorher an, lässt sich der Austausch in die nächste Schicht legen. Das Modell soll deshalb alle zehn Minuten beantworten, ob die Pumpe *in den nächsten 24 Stunden ausfällt*. Die Fachbezeichnung für dieses Vorgehen ist *Predictive Maintenance* (vorausschauende Wartung); einen Überblick über Methoden geben #cite(<carvalho_predictive_maintenance_2019>, form: "prose").

#kasten([Lernziele.], [
  Sie können erklären, warum Zeitreihen nach Pumpe und Zeit getrennt werden müssen, und einen Fehler in einem Fenstermerkmal finden, der in die Zukunft schaut. Sie können dieselbe Aufgabe als Regression und als Klassifikation formulieren und an den Entscheidungen messen, nicht an der Fehlerzahl. Sie können nachrechnen, wann sich ein zweistufiges Modell am Gerät lohnt, und Sie wissen, warum parallel berechnete Vorhersagen einen Schlüssel und ein langes Training Zwischenstände brauchen.
])

#figure(
  text(size: 9.5pt, table(
    columns: (auto, auto, 1fr),
    inset: (x: 0.6em, y: 0.4em),
    align: (left, left, left),
    [Abschnitt], [Pattern], [Frage],
    [Aufteilen], [22 Repeatable Splitting], [Wie trennt man Training und Test sauber?],
    [Das Fenster], [24 Windowed Inference], [Wie bleiben Fenstermerkmale in Training und Betrieb gleich?],
    [Die Frage stellen], [5 Reframing], [Restlebensdauer schätzen oder „Ausfall in 24 h“ ankreuzen?],
    [Zwei Stufen], [19 Two-Phase Predictions], [Was hält ein kleines Modell am Gerät von der Cloud fern?],
    [Einzeln oder Paket], [16, 17 Serving], [Wann rechnet man online, wann im Batch?],
    [Schlüssel], [20 Keyed Predictions], [Wie ordnet man Vorhersagen zu, die vertauscht ankommen?],
    [Zwischenstände], [12 Checkpoints], [Wie übersteht ein langes Training den Verlust eines Rechners?],
  )),
  kind: table,
  caption: [Wegweiser durch das Kapitel. Die Nummern sind die Pattern-Nummern des Buches.],
)

== Die Aufgabe und ihre Daten

=== Drei Arten, Pumpen zu warten

Bei der *reaktiven* Wartung repariert man, was kaputtgeht: billig, solange nichts passiert, und teuer, wenn doch. Die *vorbeugende* Wartung tauscht Teile nach festem Plan aus, etwa alle sechs Monate, und wirft damit auch gesunde Lager weg. Die *vorausschauende* Wartung misst den Zustand und tauscht, wenn die Messwerte es verlangen. Dafür braucht man eine Vorhersage: Wie wahrscheinlich ist ein Ausfall in naher Zukunft?

Um die Qualität dieser Vorhersage nicht nur in Prozentpunkten, sondern in Geld auszudrücken, legen wir drei Kosten fest. Ein ungeplanter Ausfall kostet 18 000 Euro (Stillstand, Notfalleinsatz, Folgeschäden), ein geplanter Austausch nach einem Alarm 2 500 Euro, und ein Fehlalarm, bei dem ein Techniker vergeblich ausrückt, 1 500 Euro. Das sind keine Branchenwerte, sondern *Annahmen*, die das Beispiel rechenbar machen. In einem echten Projekt liefert sie die Instandhaltung, und die gesamte Auswertung dieses Kapitels lässt sich mit anderen Zahlen wiederholen (`auswertung.py`).

=== Synthetische Sensordaten

Die Daten sind erzeugt, und das aus gutem Grund. Reale Pumpendaten sind vertraulich und selten frei verfügbar. Bei simulierten Daten kennen wir außerdem die Wahrheit: Wir wissen, wann die Degradation beginnt und wie stark sie ist, und können deshalb prüfen, ob ein Verfahren das Richtige tut. Der Preis: Echte Daten sind schmutziger, mit fehlenden Werten, Sensorausfällen und unprotokollierten Eingriffen. Die Zahlen des Kapitels zeigen deshalb Größenordnungen und Wirkmechanismen, keine Prognosegüte für reale Pumpen. Öffentliche Simulationsdaten gleicher Art sind die C-MAPSS-Daten der NASA @saxena_cmapss_2008.

Der Generator (`pumpen.py`, fester Seed) arbeitet so. Jede Pumpe hat eigene Grundwerte für Vibration, Temperatur und Druck. Sie läuft Zyklen von sechs bis vierzehn Tagen bis zum Ausfall. Zwischen 60 und 140 Stunden vor dem Ausfall beginnt die Degradation: Vibration und Temperatur steigen, der Druck sinkt, zunächst langsam, dann beschleunigt, und in den letzten vier Stunden besonders stark. Wie stark jeder Sensor reagiert, ist pro Zyklus verschieden, sodass nicht immer derselbe Kanal verrät, was los ist. Dazu kommen ein Tagesrhythmus der Last, eine langsame Drift und harmlose Lastspitzen, die der Degradation ähneln, aber nichts bedeuten. Nach dem Ausfall folgen acht Stunden Reparatur ohne Messwerte, danach beginnt ein neuer Zyklus mit frischem Lager.

#lauf("01_daten.py", "../code/13/out/01_daten.txt", nur: (0, 1, 2, 3, 9))

Das Ergebnis sind knapp 2,35 Millionen Minutenwerte, 183 Betriebszyklen und davon 155 mit Ausfall. Die übrigen 28 sind die letzten, noch laufenden Zyklen am Datenende, bei denen wir den Ausfall nicht beobachtet haben. @abb-wartung-verlauf zeigt einen Zyklus der Pumpe P03 in den sechs Tagen vor dem Ausfall.

#figure(
  kind: image,
  text(size: 9pt, stack(dir: ttb, spacing: 4pt,
    canvas(plot.plot(
      size: (11.5, 1.7), x-label: none, y-label: [Vibration \ (mm/s)], x-min: -144, x-max: 0, x-tick-step: 24, y-min: 2, y-max: 7.5, y-tick-step: 2,
      {
        plot.add(verlauf.map(p => (p.at(0), p.at(1))), style: (stroke: blau + 1pt))
        plot.add-vline(-24, style: (stroke: (paint: orange, dash: "dashed", thickness: 0.9pt)))
      },
    )),
    canvas(plot.plot(
      size: (11.5, 1.7), x-label: none, y-label: [Temperatur \ (°C)], x-min: -144, x-max: 0, x-tick-step: 24, y-min: 55, y-max: 90, y-tick-step: 10,
      {
        plot.add(verlauf.map(p => (p.at(0), p.at(2))), style: (stroke: blau + 1pt))
        plot.add-vline(-24, style: (stroke: (paint: orange, dash: "dashed", thickness: 0.9pt)))
      },
    )),
    canvas(plot.plot(
      size: (11.5, 1.7), x-label: [Stunden vor dem Ausfall], y-label: [Druck \ (bar)], x-min: -144, x-max: 0, x-tick-step: 24, y-min: 5, y-max: 6.2, y-tick-step: 0.4,
      {
        plot.add(verlauf.map(p => (p.at(0), p.at(3))), style: (stroke: blau + 1pt))
        plot.add-vline(-24, style: (stroke: (paint: orange, dash: "dashed", thickness: 0.9pt)))
      },
    )),
  )),
  caption: [Pumpe P03, ein Zyklus bis zum Ausfall (Stundenmittel der Minutenwerte). Links vom orangen Strich liegt „gesund“ im Sinne des Etiketts, rechts davon „Ausfall in den nächsten 24 Stunden“. Der Anstieg beginnt lange vor dem Strich, bleibt aber lange klein gegen das Rauschen.],
) <abb-wartung-verlauf>

=== Was Zeitreihen anders macht

Vier Eigenschaften unterscheiden dieses Problem von einer Kundentabelle, und jede wird später zu einem Pattern.

Erstens sind die Zeilen nicht unabhängig. Zwei Messwerte im Abstand von zehn Minuten sind fast gleich, und sie haben dasselbe Etikett. Zweitens gibt es ein *Jetzt*: Zu jedem Zeitpunkt darf eine Vorhersage nur nutzen, was bis dahin gemessen wurde. Drittens liegt das Etikett in der Zukunft. Ob eine Zeile „Ausfall in 24 h“ heißt, weiß man erst 24 Stunden später, und am Datenende weiß man es gar nicht. Wir verwerfen diese Zeilen, statt sie als „gesund“ zu zählen. Viertens hat eine Pumpe Zustand: Nach der Reparatur beginnt sie von vorn, und ein Fenster über den Wechsel hinweg mischt zwei verschiedene Pumpen.

Aus den Minutenwerten entstehen alle zehn Minuten Merkmalszeilen. Jede fasst die letzten 24 Stunden einer Pumpe in zwölf Zahlen zusammen: für jeden der drei Sensoren Mittelwert und Standardabweichung, den Abstand zwischen dem Mittel der letzten zwei Stunden und dem 24-Stunden-Mittel (`delta`) sowie die Steigung pro Stunde (`anstieg`). Das sind 204 589 Zeilen, von denen etwa 11 Prozent das Etikett „Ausfall in 24 h“ tragen.

== Pattern 22: Repeatable Splitting

=== Szenario und Problem

Wir trainieren ein Modell (Gradient Boosting aus scikit-learn, siehe #cite(<friedman_gradient_boosting_2001>, form: "prose") und #cite(<pedregosa_scikit_learn_2011>, form: "prose")) und messen seine Güte mit der *PR-AUC*, der Fläche unter der Precision-Recall-Kurve (genauer: der Average Precision aus scikit-learn). Sie eignet sich für seltene Ereignisse besser als die Genauigkeit. Der Reflex ist `train_test_split`, also 70 Prozent der Zeilen zufällig ins Training und der Rest in den Test. Bei dieser Aufgabe ist das ein Fehler. Die Zeilen einer Pumpe liegen zehn Minuten auseinander und sehen fast gleich aus. Mischt man sie, steht fast zu jeder Testzeile ein Nachbar im Training, der denselben Wert, dieselbe Pumpe und dasselbe Etikett hat. Das Modell muss nichts verallgemeinern; es erkennt wieder, was es kennt.

Wie groß der Effekt ist, zeigt der Vergleich von vier Aufteilungen mit demselben Modell und denselben Daten.

#code-aus("../code/13/02_splitting.py", "def bucket", bis: "t[\"bucket\"]")

#code-aus("../code/13/02_splitting.py", "test_pumpe = ", bis: "print(f\"{'Schema'")

#lauf("02_splitting.py", "../code/13/out/02_splitting.txt")

Der zufällige Split meldet eine PR-AUC von 0,992, der Wert für fast perfekte Vorhersagen. Teilt man nach Pumpen, so dass ein Drittel der Pumpen dem Modell völlig unbekannt bleibt, fällt der Wert auf 0,892. Trennt man zeitlich, trainiert also auf den ersten 30 Tagen und testet ab Tag 46, sind es 0,862, und beides zusammen ergibt 0,858. Das ist der Wert, mit dem man rechnen darf, wenn das Modell im Betrieb neue Pumpen zu sehen bekommt und die Zukunft vorhersagen soll. Zwischen der ersten und der letzten Zeile liegen 0,13 PR-AUC, und der Unterschied ist kein Zufall: Er entsteht überwiegend dadurch, dass der Test dem Training zu ähnlich ist. (Die Testmengen sind verschieden groß und haben leicht unterschiedliche Anteile an Positiven, 11,0 bis 12,8 Prozent; auch das beeinflusst die PR-AUC, erklärt aber keinen Abstand von 0,13.) Zu zufälligen Splits bei Daten mit Struktur gibt es eine eigene Studie @roberts_cross_validation_2017, zu Leckagen allgemein @kaufman_leakage_2012, und für Zeitreihen untersucht @bergmeir_cv_timeseries_2012, wann die gewöhnliche Kreuzvalidierung taugt und wann blockweise Verfahren nötig sind.

=== Lösung

Das Pattern verlangt zweierlei. Die Zuordnung zu Training und Test soll sich nach einem *Schlüssel* richten, der zusammengehörige Zeilen beisammen hält, und sie soll *wiederholbar* sein: Dieselbe Pumpe landet bei jedem Lauf und auf jedem Rechner in derselben Menge, auch wenn neue Pumpen oder neue Tage dazukommen. Beides leistet eine Hashfunktion auf den Schlüssel. Die Pumpen-ID wird gehasht, der Rest bei Division durch 10 ergibt einen Bucket von 0 bis 9, und die Buckets 7 bis 9 sind Testpumpen. Das Buch macht das in SQL mit einer Fingerprint-Funktion; hier steht `md5`. Pythons eingebautes `hash()` taugt nicht, weil es Zeichenketten bei jedem Programmstart anders salzt.

Für die Zeit gilt dieselbe Idee mit einem Stichtag statt eines Hashes. Zwischen den Teilen liegt eine *Lücke*. Sie ist nötig, weil das Etikett einer Zeile aus der Zukunft stammt: Eine Trainingszeile von Tag 29,8 trägt das Etikett „Ausfall in 24 h“, wenn die Pumpe an Tag 30,5 ausfällt, und weiß damit etwas über die Testperiode. Die Lücke muss mindestens so lang sein wie der Vorhersagehorizont. Wir wählen drei Tage zwischen Training, Validierung und Test (@abb-wartung-split).

#let tage = 56
#let train-f = blau
#let val-f = blau.lighten(55%)
#let test-f = orange
#let frei-f = luma(226)
#let split-panel(titel, reihen) = {
  let b = 0.085
  let h = 0.1
  canvas(length: 1cm, {
    import draw: *
    for (i, r) in reihen.enumerate() {
      for (a, e, f) in r {
        rect((a * b, -i * h), (e * b, -(i + 1) * h), fill: f, stroke: none)
      }
    }
    rect((0, 0), (tage * b, -30 * h), stroke: 0.5pt + luma(120))
    content((tage * b / 2, 0.38), text(size: 9pt, weight: "bold", titel))
    content((0, -30 * h - 0.3), anchor: "west", text(size: 8.5pt, fill: grau)[Tag 0])
    content((tage * b, -30 * h - 0.3), anchor: "east", text(size: 8.5pt, fill: grau)[Tag 56])
  })
}
#let zeit-reihe = ((0, 30, train-f), (30, 33, frei-f), (33, 43, val-f), (43, 46, frei-f), (46, 56, test-f))
#let zufall-reihen = range(30).map(i => range(28).map(j => (2 * j, 2 * j + 2, if calc.rem(calc.rem((i + 1) * 73856093 + (j + 1) * 19349663, 1000003), 10) < 3 { test-f } else { train-f })))
#figure(
  kind: image,
  {
    grid(
      columns: (1fr, 1fr), row-gutter: 18pt, align: center,
      split-panel([zufällig je Zeile (schematisch)], zufall-reihen),
      split-panel([nach Pumpe (Hash)], pumpen-test.map(t => ((0, 56, if t { test-f } else { train-f }),))),
      split-panel([zeitlich], range(30).map(_ => zeit-reihe)),
      split-panel([nach Pumpe und zeitlich], pumpen-test.map(t => if t { ((0, 46, frei-f), (46, 56, test-f)) } else { ((0, 30, train-f), (30, 56, frei-f)) })),
    )
    v(4pt)
    set text(size: 8.5pt)
    box(width: 8pt, height: 8pt, fill: train-f) + [ Training #h(8pt) ] + box(width: 8pt, height: 8pt, fill: val-f) + [ Validierung #h(8pt) ] + box(width: 8pt, height: 8pt, fill: test-f) + [ Test #h(8pt) ] + box(width: 8pt, height: 8pt, fill: frei-f) + [ nicht verwendet (Lücke oder andere Pumpe)]
  },
  caption: [Die vier Aufteilungen als Raster aus 30 Pumpen (Zeilen) und 56 Tagen (Spalten). Im Panel „nach Pumpe“ und im Panel „nach Pumpe und zeitlich“ stehen die tatsächlich gehashten Testpumpen; das Raster des zufälligen Splits ist schematisch.],
) <abb-wartung-split>

=== Grenzen und Bezug zu Software Engineering

Im strengen Split stehen nur zehn Ausfälle im Test, im zeitlichen 29. Eine PR-AUC auf zehn Ereignissen schwankt stark, und man sollte sie nie ohne Hinweis auf diese Zahl berichten. Ein Zeitsplit setzt außerdem voraus, dass die Vergangenheit der Zukunft ähnelt, und wer mit demselben Test viele Läufe vergleicht, verbraucht ihn. *Wann nicht:* Bei unabhängigen Zeilen ohne Gruppen und ohne Zeitbezug genügt ein einfacher Zufallssplit mit Seed. Die Hash-Zuordnung ist *Hash-Partitionierung* wie beim Sharding von Datenbanken: Der Schlüssel bestimmt den Ort, und neue Datensätze verschieben die alten nicht. Die Lücke vor dem Test ist die Isolation, die man von Testumgebungen verlangt.

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 6, Pattern 22); @roberts_cross_validation_2017; @bergmeir_cv_timeseries_2012; @kaufman_leakage_2012.

== Pattern 24: Windowed Inference

=== Szenario und Problem

Das Modell erhält keine Rohwerte, sondern Aggregate über die letzten 24 Stunden. Im Training ist das eine Zeile pandas, im Betrieb jedoch fließen die Messwerte einzeln ein, und jemand muss die letzten 1 440 Werte pro Pumpe vorhalten. Zwei Programme, die dasselbe berechnen sollen, sind eine Einladung zum Skew. Ein klassischer Fehler lässt sich im Notebook mit einem einzigen Argument einbauen:

```python
df["vib_mittel"] = df["vib"].rolling(1440, center=True).mean()   # Fenster um t herum
```

Das Argument `center=True` setzt den Zeitpunkt in die Mitte des Fensters, sodass das Fenster zur Hälfte aus der Zukunft besteht. In pandas ist das Standardverhalten das nachlaufende Fenster; `center=True` muss man aktiv anschalten, und es ist für Glättung von Kurven im Nachhinein gedacht. Eine Variante: Man berechnet einen Tageswert über `groupby(Datum)` und ordnet jeder Zeile den Mittelwert des *ganzen* Tages zu, auch der Stunden, die noch kommen. Im Training läuft das ohne Fehlermeldung. Im Betrieb fehlt die Zukunft, und das Modell sieht Merkmale, die es so nie gelernt hat.

=== Lösung

Das Pattern verlangt, dass die Fenster im Training und im Betrieb *dieselbe* Funktion durchlaufen und dass jedes Fenster am Vorhersagezeitpunkt endet. Im Code gibt es eine Definition der Merkmale, die ein Fenster der letzten 24 Stunden entgegennimmt und zwölf Zahlen liefert:

#code-aus("../code/13/pumpen.py", "def merkmale(", bis: "return np.concatenate")

Die beiden Wege unterscheiden sich nur darin, wie sie das Fenster beschaffen. Im Training schneidet `sliding_window_view` aus dem ganzen Zyklus Fenster, die bei der Zeile enden. Das Argument `versatz` verschiebt das Fensterende und erlaubt, den Fehler absichtlich einzubauen (`versatz=719` entspricht `center=True`):

#code-aus("../code/13/pumpen.py", "if versatz > 0:", bis: "t = pd.DataFrame(merkmale")

Im Betrieb hält die Klasse `PumpenStrom` pro Pumpe einen Ringpuffer (`deque` mit `maxlen=1440`). Sie liefert erst dann ein Merkmal, wenn der Puffer voll ist, und wird nach einer Wartung geleert, genau wie der Zyklus im Training endet:

#code-aus("../code/13/pumpen.py", "def neue_messung", bis: "def wartung")

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (11mm, 6mm),
    neben((0, 0), [Historische \ Minutenwerte]),
    neben((0, 1.5), [Messwert-Strom \ #klein[eine Pumpe, ein Wert/min]]),
    knoten((1, 0), [Fenster schneiden \ #klein[`sliding_window_view`]]),
    knoten((1, 1.5), [Ringpuffer \ #klein[`deque(maxlen=1440)`]]),
    knoten((2, 0.75), [`merkmale(fenster)` \ #klein[eine Definition]], farbe: gruen, grund: gruen-hell),
    neben((3, 0), [Trainingstabelle]),
    neben((3, 1.5), [Vorhersage \ #klein[zustandsloses Modell]]),
    edge((0, 0), (1, 0), "->"), edge((0, 1.5), (1, 1.5), "->"),
    edge((1, 0), (2, 0.75), "->"), edge((1, 1.5), (2, 0.75), "->"),
    edge((2, 0.75), (3, 0), "->"), edge((2, 0.75), (3, 1.5), "->"),
  )),
  caption: [Training (oben) und Betrieb (unten) unterscheiden sich nur im Beschaffen des Fensters. Die Berechnung selbst liegt an genau einer Stelle.],
) <abb-wartung-fenster>

Das Skript prüft die Gleichheit mit einem Äquivalenztest: Ein ganzer Zyklus läuft Minute für Minute durch den Ringpuffer, und jedes Merkmal wird mit der Batch-Variante verglichen. Danach trainiert es das Modell zweimal, auf zentrierten und auf nachlaufenden Fenstern, und wählt die Alarmschwelle jeweils so, dass die Precision auf den Validierungsdaten mindestens 0,80 beträgt.

#lauf("03_fenster.py", "../code/13/out/03_fenster.txt")

Der Stream stimmt mit der nachlaufenden Batch-Variante bis auf Rundungsfehler überein (Abweichung in der Größenordnung 10#super[−14]), mit der zentrierten dagegen nicht. Und der Fehler ist teuer, wie die Ausgabe zeigt (@abb-wartung-fensterform veranschaulicht die beiden Fensterformen). Das Modell auf zentrierten Fenstern sieht im Notebook am besten aus: PR-AUC 0,924 und ein Recall von 0,84. Im Betrieb bleibt davon wenig. Die PR-AUC fällt auf 0,835, und der Recall sinkt auf 0,50: Nur noch die Hälfte der Zeilen, die zu einem bevorstehenden Ausfall gehören, löst Alarm aus (der Recall ist hier zeilenweise gerechnet). Das Modell, das ehrlich mit nachlaufenden Fenstern gelernt wurde, erreicht offline weniger (0,862), hält diesen Wert aber im Betrieb. Der Abstand zwischen 0,924 und 0,862 geht zum großen Teil auf das zurück, was die Zukunft im Fenster beigetragen hat. Die Testzeilen sind nicht ganz dieselben (35 780 gegen 33 650), weil man bei zentrierten Fenstern das Zyklusende auffüllen muss.

#figure(
  kind: image,
  text(size: 9pt, canvas(plot.plot(
    size: (12.5, 4.6), x-label: [Stunden vor dem Ausfall], y-label: [Vibration (mm/s)], x-min: -84, x-max: 0, x-tick-step: 12, y-min: 0, y-max: 8, y-tick-step: 2,
    {
      plot.add(verlauf.filter(p => p.at(0) >= -84).map(p => (p.at(0), p.at(1))), style: (stroke: blau + 1.1pt))
      plot.annotate({
        import draw: *
        rect((-24, 0), (0, 8), fill: orange.transparentize(88%), stroke: none)
        line((-30, 0), (-30, 5.9), stroke: 1pt + luma(40))
        rect((-54, 0.3), (-30, 1.5), fill: blau-hell, stroke: 0.8pt + blau)
        content((-59.5, 0.9), anchor: "east", text(size: 8.5pt, fill: blau)[nachlaufend])
        rect((-42, 2.0), (-30, 3.2), fill: luma(228), stroke: 0.8pt + luma(120))
        rect((-30, 2.0), (-18, 3.2), fill: rgb("#F2D9B8"), stroke: 0.8pt + orange)
        content((-47.5, 2.6), anchor: "east", text(size: 8.5pt, fill: luma(60))[zentriert])
        content((-30, 6.4), anchor: "south", text(size: 8.5pt, weight: "bold")[Zeitpunkt t])
        content((-12, 7.4), text(size: 8.5pt, fill: orange)[Etikett = 1])
      })
    },
  ))),
  caption: [Zwei Fenster zum Zeitpunkt t, 30 Stunden vor dem Ausfall (beide 24 h breit, maßstäblich). Das nachlaufende Fenster (blau) endet bei t. Das zentrierte (grau: Vergangenheit, orange: Zukunft) reicht zur Hälfte in die Zukunft und damit in den Bereich, in dem das Etikett 1 ist, obwohl die Zeile selbst noch das Etikett 0 trägt.],
) <abb-wartung-fensterform>

=== Grenzen und Bezug zu Software Engineering

Das Fenster hält Zustand, und Zustand will behandelt sein: Fällt der Stream-Prozess aus, ist der Ringpuffer weg, und die ersten 24 Stunden nach dem Neustart liefern keine Vorhersage, wenn man ihn nicht aus den Rohdaten wiederaufbaut. Verspätete Messwerte ordnet man nach Ereigniszeit ein, nicht nach Ankunftszeit; dafür gibt es in Stream-Frameworks Watermarks @akidau_dataflow_model_2015. Wir rechnen alle zehn Minuten die vollen 1 440 Werte neu, das ist für 30 Pumpen billig, bei Hunderttausenden führte man inkrementelle Statistiken. *Wann nicht:* Genügt die aktuelle Zeile, braucht man kein Fenster. Das Pattern ist *Don't Repeat Yourself* für Berechnungen und der Kern von Pattern 21 (Transform); der Äquivalenztest ist ein Konformitätstest zwischen zwei Implementierungen, wie man ihn für Protokolle oder Parser schreibt.

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 6, Pattern 24); @akidau_dataflow_model_2015; @kleppmann_ddia_2017 (Stream-Verarbeitung); @sculley_hidden_debt_2015.

== Pattern 5: Reframing

=== Szenario und Problem

Der erste Impuls bei einer Wartungsaufgabe ist, die *Restlebensdauer* vorherzusagen (*Remaining Useful Life*, RUL): „Diese Pumpe hält noch 53 Stunden.“ Das ist eine Regression, also die Vorhersage einer Zahl, und sie klingt nach genau der Auskunft, die der Disponent braucht. Die Alternative ist eine Klassifikation: „Fällt die Pumpe in den nächsten 24 Stunden aus, ja oder nein?“ Beide verwenden dieselben Merkmale und lassen sich aus denselben Daten ableiten; wir nehmen nur andere Etiketten. Dieses Umformulieren der Frage ist das Pattern *Reframing* @lakshmanan_ml_design_patterns_2020.

Die Regression hat ein Problem, das man nicht sofort sieht. Eine Pumpe, die gesund aussieht, kann noch 2 oder noch 9 Tage laufen, und die Messwerte beider Fälle unterscheiden sich kaum, sodass kein Modell das verlässlich trennen kann. Der quadratische Fehler, mit dem die Regression trainiert wird, wird aber von genau diesen unlösbaren Fällen dominiert. Das Modell verschwendet Kapazität auf die Frage, die man nicht beantworten kann, und beantwortet die zweite, die wichtige Frage („kurz vor dem Ausfall?“) nebenbei.

=== Lösung

Wir trainieren drei Modelle auf denselben Merkmalen: eine Regression auf die RUL in Stunden, eine Regression auf die auf 72 Stunden *gekappte* RUL (alles, was länger dauert, zählt als 72) und eine Klassifikation auf „Ausfall in 24 h“. Für den Vergleich verwenden wir zwei Maßstäbe. Der erste ist die PR-AUC bezüglich des 24-Stunden-Etiketts, wobei bei den Regressionen die negative vorhergesagte RUL als Score dient. Der zweite ist eine *ereignisbezogene* Auswertung, die zählt, was der Betrieb sieht: erkannte Ausfälle und Fehlalarme. Eine Zeilenzählung ist hier irreführend, denn ein Ausfall erzeugt 144 positive Zeilen. Die Auswertung fasst Alarme zu Episoden zusammen (höchstens sechs Stunden Abstand), zählt einen Ausfall als erkannt, wenn zwischen 24 und einer Stunde vor dem Ausfall ein Alarm liegt, und wertet eine Episode als Fehlalarm, wenn sie mehr als 48 Stunden vor einem Ausfall liegt. Die Schwelle wird auf den Validierungsdaten nach den Kosten gewählt (`ereignis_bilanz` in `auswertung.py`).

#lauf("04_reframing.py", "../code/13/out/04_reframing.txt", von: 0, bis: 9)

Die Regression auf die rohe RUL zeigt ihr Problem in den Fehlern: In den letzten 24 Stunden vor dem Ausfall liegt sie im Mittel um 11 Stunden daneben, bei Pumpen, die noch mehr als drei Tage laufen, um 41 Stunden. Zwischen den drei Ansätzen sind die Unterschiede in der Entscheidung klein: Alle drei erkennen alle 29 Ausfälle, die Fehlalarme liegen bei 5 bis 7, und die Kosten bei 80 000 bis 83 000 Euro in zehn Testtagen, gegenüber 522 000 Euro ohne Überwachung. Dabei zählen nur Zyklen mit beobachtetem Ausfall; Fehlalarme in Zyklen ohne Ausfall am Datenende fließen nicht ein, die Fehlalarmzahlen sind also Untergrenzen. Bei 29 Ereignissen sind ein oder zwei Fehlalarme mehr oder weniger Rauschen, und niemand sollte aus der Differenz von 3 000 Euro eine Rangfolge ableiten. In der PR-AUC steht die gekappte Regression mit 0,886 vor der Klassifikation (0,863) und der rohen Regression (0,823).

Das Ergebnis spricht nicht gegen das Reframing, sondern gegen die Annahme, die Klassifikation gewinne immer. Entscheidend war, dem Modell die unlösbare Frage zu ersparen, und das gelingt durch Kappen des Ziels ebenso wie durch den Wechsel auf die 24-Stunden-Klassifikation. Die Wahl richtet sich nach der Entscheidung dahinter: Die Klassifikation liefert eine Wahrscheinlichkeit, an der sich eine Alarmschwelle begründen lässt, und ist dem Techniker leichter zu erklären als eine Zahl, deren Genauigkeit mit dem Abstand zum Ausfall schwankt. Die gekappte Regression ordnet zusätzlich die letzten 72 Stunden, was die Einsatzplanung nutzen kann.

#figure(
  kind: image,
  {
    let v = csv("../code/13/out/reframing_verlauf.csv", row-type: dictionary).map(r => (float(r.h), float(r.rul_roh), float(r.rul_gekappt), float(r.wahrsch)))
    text(size: 9pt, grid(
      columns: (1fr, 1fr), column-gutter: 8pt,
      canvas(plot.plot(
        size: (6.6, 4.4), x-label: [Stunden vor dem Ausfall], y-label: [RUL (h)], x-min: -120, x-max: 0, x-tick-step: 24, y-min: 0, y-max: 160, y-tick-step: 40,
        {
          plot.add(v.map(p => (p.at(0), -p.at(0))), style: (stroke: (paint: luma(120), dash: "dotted", thickness: 1pt)))
          plot.add(v.map(p => (p.at(0), p.at(1))), style: (stroke: orange + 1pt))
          plot.add(v.map(p => (p.at(0), p.at(2))), style: (stroke: blau + 1pt))
        },
      )),
      canvas(plot.plot(
        size: (6.6, 4.4), x-label: [Stunden vor dem Ausfall], y-label: [P(Ausfall in 24 h)], x-min: -120, x-max: 0, x-tick-step: 24, y-min: 0, y-max: 1, y-tick-step: 0.25,
        {
          plot.add(v.map(p => (p.at(0), p.at(3))), style: (stroke: gruen + 1.2pt))
          plot.add-vline(-24, style: (stroke: (paint: orange, dash: "dashed", thickness: 0.9pt)))
        },
      )),
    ))
  },
  caption: [Ein Testzyklus, die letzten 120 Stunden. Links: wahre RUL (grau gepunktet), rohe Regression (orange) und auf 72 h gekappte Regression (blau). Rechts: Wahrscheinlichkeit der Klassifikation, mit der 24-Stunden-Grenze (orange gestrichelt).],
) <abb-wartung-reframing>

=== Grenzen und Bezug zu Software Engineering

Die Klassifikation wirft Information weg: Zwischen „in 25 Stunden“ und „in 200 Stunden“ unterscheidet sie nicht, und der Horizont von 24 Stunden ist eine Entscheidung, die man mit der Instandhaltung treffen muss, nicht im Code. Ändert er sich, muss neu trainiert werden. *Wann nicht:* Wenn die Zahl selbst gebraucht wird, etwa die Menge zu bestellender Ersatzteile, ist eine Regression richtig. Reframing ist eine Frage der Schnittstelle: Wie bei einer API fragt man zuerst, was der Aufrufer braucht, und gestaltet dann die Rückgabe. Eine Zahl mit schwankender Genauigkeit ist wie ein Rückgabewert ohne Vertrag.

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 3, Pattern 5); @saxena_cmapss_2008 für RUL als etablierte Fragestellung; @carvalho_predictive_maintenance_2019.

== Pattern 19: Two-Phase Predictions

=== Szenario und Problem

Die Pumpen stehen in Hallen mit schwachem Mobilfunk. Jede Vorhersage in der Cloud kostet Datenvolumen, Rechenzeit und Strom des Gateways, und sie funktioniert nur bei Verbindung. Gleichzeitig sind etwa die Hälfte aller Zeilen unauffällig: Eine Pumpe mit konstanter Vibration und Temperatur braucht kein großes Modell, um „gesund“ zu hören. Man möchte das große Modell nur befragen, wenn das kleine unsicher ist.

=== Lösung

Das Pattern stellt zwei Modelle hintereinander. Ein *kleines Modell läuft am Gerät* und beantwortet einen einfachen Teil der Frage, hier: „Sieht das nach Degradation aus?“ Es ist so eingestellt, dass es *kaum etwas übersieht* (hoher Recall), auch wenn es oft zu viel meldet. Nur was es durchlässt, geht an das *große Modell in der Cloud*, das genauer rechnet.

Unser Edge-Modell ist eine logistische Regression auf drei Merkmalen (`vib_delta`, `vib_anstieg`, `temp_delta`). Es besteht aus vier Zahlen und einer Multiplikation, das läuft auch auf einem Mikrocontroller. Die Schwelle wird auf den Validierungsdaten so bestimmt, dass 98 Prozent der positiven Zeilen passieren. Das Cloud-Modell ist das Gradient Boosting aus dem vorigen Abschnitt auf allen zwölf Merkmalen.

#code-aus("../code/13/05_zweiphasig.py", "cloud = HistGradient", bis: "# Schwelle:")

Die Ausgabe unten fasst den Lauf zusammen. Von den Testzeilen lässt Stufe 1 nur 48,1 Prozent durch, die übrigen 51,9 Prozent beantwortet das Gerät selbst mit „unauffällig“. Von den positiven Zeilen passieren 97,0 Prozent die Stufe, ein Teil geht also verloren, der in der Cloud nie ankommt. In der Ereignisrechnung hat das keine Folgen für die Erkennung: Das zweistufige System findet wie das Cloud-Modell allein alle 29 Ausfälle. Es erzeugt aber 8 statt 5 Fehlalarme, und die PR-AUC sinkt von 0,863 auf 0,852. Das Edge-Modell allein ist deutlich schlechter (PR-AUC 0,737, 20 Fehlalarme), erkennt aber ebenfalls alle Ausfälle, weil über einen ganzen Tag hinweg viele Zeilen vor dem Ausfall Alarm auslösen.

#lauf("05_zweiphasig.py", "../code/13/out/05_zweiphasig.txt", nur: (0, 1, 2, 4, 5, 6, 7, 9, 12, 13, 14, 15, 16))

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (11mm, 6mm),
    neben((0, 0), [Merkmalszeile \ #klein[alle 10 min, 100 %]]),
    knoten((1, 0), [Stufe 1: Edge \ #klein[4 Parameter, Recall 98 %]]),
    knoten((2, -0.7), [unter der Schwelle: \ „unauffällig“ \ #klein[lokal erledigt, 51,9 %]], farbe: gruen, grund: gruen-hell),
    knoten((2, 0.7), [über der Schwelle: \ Stufe 2 in der Cloud \ #klein[Gradient Boosting, 48,1 %]], farbe: orange, grund: orange-hell),
    neben((3, 0.7), [Alarm oder \ Wartungsplan]),
    edge((0, 0), (1, 0), "->"),
    edge((1, 0), (2, -0.7), "->"),
    edge((1, 0), (2, 0.7), "->"),
    edge((2, 0.7), (3, 0.7), "->"),
  )),
  caption: [Zwei-Phasen-Vorhersage in der Pumpenflotte. Die Anteile sind die Werte des Laufs auf den Testdaten.],
) <abb-wartung-zweiphasig>

Was spart das? Die erste Rechnung betrifft die Aufrufe. Bei 2 000 Pumpen und einer Vorhersage alle zehn Minuten fallen 288 000 Cloud-Aufrufe pro Tag an. Mit Stufe 1 sind es 138 639 (−52 Prozent). Bei der Annahme von 0,40 Euro je 1 000 Aufrufe macht das 42 048 gegen 20 241 Euro im Jahr, also 10,90 Euro pro Pumpe und Jahr. Die zweite Rechnung betrifft die Fehler: Die drei zusätzlichen Fehlalarme kosten im Test 4 500 Euro, grob hochgerechnet auf die 0,73 Pumpenjahre Kalenderzeit des Tests sind das 6 139 Euro pro Pumpe und Jahr, also mehr als das Fünfhundertfache der Ersparnis. Drei Fehlalarme bei 29 Ausfällen sind statistisch nichts, und der Wert schwankt von Lauf zu Lauf stark. Wäre aber auch nur ein Zwanzigstel davon echt, überstiege es die gesparten Aufrufkosten noch um mehr als das Zwanzigfache.

Das ist die eigentliche Lehre des Abschnitts: Ein zweistufiges Modell rechnet sich nicht allein über die Aufrufkosten, weil die Fehlerkosten um Größenordnungen darüberliegen. Es lohnt sich dort, wo ein Aufruf teuer ist (Satellitenverbindung, Batteriebetrieb, Lizenz pro Aufruf, ein großes Modell mit Sekunden Rechenzeit je Vorhersage) und wo die Verbindung ausfallen kann. Bei der Latenz ist der Rechner belanglos: Das Edge-Modell braucht im Median 0,5 Mikrosekunden, das Cloud-Modell lokal in der Größenordnung einer Millisekunde, und gegen das Netz (Zehntel Sekunden, nicht gemessen) verschwinden beide. Bei 24 Stunden Horizont spielt Latenz ohnehin keine Rolle; bei einer Notabschaltung bei Grenzwertverletzung täte sie es, aber die ist eine Regel am Gerät und kein Modell. Dazu kommt ein Nutzen, den die Rechnung nicht zeigt: Bei Netzausfall arbeitet das Gerät allein weiter. Das kostet in unserem Test 22 500 Euro mehr als das Cloud-Modell, erkennt aber weiterhin alle 29 Ausfälle.

=== Grenzen und Bezug zu Software Engineering

Wer Stufe 1 falsch einstellt, bemerkt es nicht: Was sie verwirft, erreicht die Cloud nie. Man überwacht deshalb den Recall der Stufe 1 getrennt; jeder beobachtete Ausfall liefert nachträglich das Etikett für die 24 Stunden davor, auch für Zeilen, die nie in die Cloud kamen (Pattern 18, Continued Model Evaluation). Wird die Cloud neu trainiert, muss die Schwelle der Stufe 1 neu geprüft werden, und beide Modelle müssen in kompatiblen Versionen laufen (Pattern 27). Mit Pattern 8 (Cascade) ist das Pattern verwandt: Dort bestimmt das erste Modell, welches andere Modell einen Fall sieht; hier ist das erste Modell ein Vorfilter, und die Stufen trennt eine Netzgrenze mit eigenen Ausfällen. Billige Stufen vorzuschalten und teure nur für den Rest einzusetzen, ist aus der Gesichtserkennung bekannt @viola_jones_cascade_2001. *Wann nicht:* Wenn Aufrufe billig sind und die Verbindung stabil ist, bringt die zweite Stufe Betrieb und Risiko ohne Nutzen. Stufe 1 ist ein Vorfilter wie ein Bloom-Filter oder ein Cache vor einer teuren Operation: Falsch-Positive kosten nur den teuren Weg, Falsch-Negative sind verboten. Der Betrieb am Gerät bei Netzausfall ist ein Fallback, wie man ihn von Circuit Breakern kennt.

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 5, Pattern 19); @viola_jones_cascade_2001 für frühes Aussortieren durch billige Stufen.

== Pattern 16 und 17: Einzeln oder im Paket

=== Szenario und Problem

Bisher kam jede Vorhersage einzeln: Alle zehn Minuten fragt eine Pumpe nach dem Ergebnis, ein Online-Dienst antwortet (Pattern 16, Stateless Serving Function). Das stimmt nur für einen Teil der Aufgaben. Die Disposition möchte morgens eine Liste aller Pumpen nach Ausfallrisiko, und nach einem Modellwechsel soll die gesamte Historie neu bewertet werden. Niemand wartet auf eine einzelne Antwort, und ein Online-Dienst wäre dafür verschwenderisch.

=== Lösung

Das Pattern 17 (Batch Serving) bewertet viele Zeilen in einem Aufruf. Dasselbe Modell, dieselbe Datei; nur die Aufrufform ändert sich. Das Skript misst beide Formen mit einem Gradient Boosting wie im vorigen Abschnitt:

#lauf("06_serving_modi.py", "../code/13/out/06_serving_modi.txt")

Ein einzelner Aufruf kostet in der Größenordnung einer Millisekunde, auch wenn er nur eine Zeile bewertet, denn er zahlt feste Kosten für Aufruf, Prüfung und Aufbau der Rechnung. Im Paket verteilen sich diese Kosten auf alle Zeilen, und eine Zeile kostet nur noch einige Mikrosekunden. Der Faktor liegt je nach Paketgröße zwischen 100 und 300, und die Ergebnisse sind identisch. Für die Flotte heißt das: 2 000 Pumpen alle zehn Minuten sind 288 000 Zeilen am Tag, einzeln gerechnet etwa drei Minuten Rechenzeit, im Paket etwa eine Sekunde (mit den Zeiten des Laufs oben, auf einem Rechner).

Die Wahl zwischen Online und Batch richtet sich nach der *Frist der Entscheidung*, nicht nach dem Modell. Eine Notabschaltung bei Grenzwertverletzung muss in Sekunden fallen und ist eine Regel am Gerät, kein Modell. Der Alarm „Ausfall in 24 h“ hat eine Frist von zehn Minuten. Auch dann rechnet man nicht Pumpe für Pumpe: Man sammelt die Merkmalszeilen aller Pumpen eines Takts und bewertet sie als kleines Paket (*Micro-Batch*), online im Sinne der Frist und Batch im Sinne der Rechnung. Der Einsatzplan für den nächsten Tag und die Neubewertung der Historie nach einem Modellwechsel sind klassische Batch-Aufgaben.

=== Grenzen und Bezug zu Software Engineering

Das Paket hat eine Obergrenze durch den Arbeitsspeicher, und die erste Antwort kommt erst, wenn es fertig ist. Jede Paketform verlangt dieselbe Merkmalsberechnung wie der Betrieb (Pattern 24). *Wann nicht:* Wenn eine Entscheidung wirklich einzeln und sofort fallen muss, bleibt es beim Einzelaufruf. Die Zeiten stammen von einem ausgelasteten Entwicklungsrechner und schwanken von Lauf zu Lauf; belastbar ist die Größenordnung. Das Muster kennt man als N+1-Problem: eine Datenbankabfrage pro Zeile statt einer für alle. Das Modell bleibt gleich, nur die Schnittstelle nach außen ändert sich.

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 5, Patterns 16 und 17).

== Pattern 20: Keyed Predictions

=== Szenario und Problem

Die nächtliche Neubewertung läuft parallel, denn mehrere Rechner teilen sich die Arbeit. Das Skript zerlegt die Testtabelle in zwölf Pakete, die ein Pool von Workern mit unterschiedlicher Laufzeit bewertet, und sammelt die Ergebnisse in der Reihenfolge, in der sie fertig werden. Die naheliegende Fortsetzung ist, die Ergebnisse aneinanderzuhängen und der Tabelle zuzuordnen, als kämen sie in der alten Reihenfolge zurück:

#code-aus("../code/13/07_keys.py", "# Ohne Schluessel", bis: "referenz = ")

Das Ergebnis steht in der Ausgabe unten. Die Pakete kamen in der Reihenfolge 5, 6, 8, 11, 2, 4, 10, 3, 0, 7, 9, 1 zurück, und bei 59,4 Prozent der Zeilen steht danach eine Vorhersage, die zu einer anderen Zeile gehört. Von 4 173 Alarmen (Score ab 0,5) liegen 79,3 Prozent an Zeilen, die keinen verdienen. Die PR-AUC fällt von 0,863 auf 0,229; bei einem Anteil von gut 20 Prozent Positiven im Test ist das der Wert des reinen Ratens. Dabei sieht nichts kaputt aus. Der Code läuft ohne Fehler, die Ausgabe hat die richtige Länge, jeder Wert liegt zwischen 0 und 1. Nur wer die Zahlen mit einer Referenz vergleicht, merkt es. Mit Schlüssel ist das Ergebnis identisch zur sequentiellen Referenz.

#lauf("07_keys.py", "../code/13/out/07_keys.txt")

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (8mm, 13mm),
    neben((0, 0), [Tabelle \ #klein[Zeilen 1 bis 12]]),
    knoten((1, 0), [Pakete \ #klein[A, B, C]]),
    knoten((2, 0), [parallele \ Worker]),
    neben((3, 0), [Ergebnisse \ #klein[Ankunft: C, A, B]]),
    knoten((4, -0.8), [ohne Schlüssel: \ #klein[nach Position zuordnen]], farbe: orange, grund: orange-hell),
    knoten((4, 0.8), [mit Schlüssel: \ #klein[Join über (Pumpe, Minute)]], farbe: gruen, grund: gruen-hell),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"),
    edge((3, 0), (4, -0.8), "->"), edge((3, 0), (4, 0.8), "->"),
  )),
  caption: [Bei paralleler Verarbeitung kommen die Ergebnisse in Ankunftsreihenfolge zurück. Nur der Schlüssel macht die Zuordnung unabhängig davon.],
) <abb-wartung-keys>

=== Lösung

Das Pattern verlangt, dass jede Anfrage einen *Schlüssel* mitführt, den der Worker unverändert an die Antwort hängt. Die Zuordnung geschieht danach über den Schlüssel, nicht über die Position. Hier besteht der Schlüssel aus Pumpen-ID und Minute, das ist eindeutig, weil eine Pumpe pro Minute nur einen Messwert hat. `merge(..., validate="one_to_one")` prüft das bei jedem Lauf nach: Taucht ein Schlüssel doppelt auf, etwa weil ein Paket nach einem Fehler wiederholt wurde, bricht der Lauf ab, statt stillschweigend zu verdoppeln. Dasselbe Prinzip löst weitere Probleme. Mit Schlüsseln kann man Wiederholungen erkennen (Idempotenz), Vorhersagen später mit dem tatsächlichen Ausgang zusammenführen (für Pattern 18) und Fehler einem Eingang zuordnen.

=== Grenzen und Bezug zu Software Engineering

Der Fehler ist in einem Thread-Pool zufällig verborgen: `pool.map` liefert die Ergebnisse in Eingabereihenfolge, und das Problem tritt nicht auf. Es erscheint, sobald die Reihenfolge nicht mehr garantiert ist, bei `as_completed`, bei Nachrichtenwarteschlangen, bei verteilten Frameworks mit Shuffle und bei Wiederholungen nach Fehlern. Dann ist der Test mit kleinen Daten unauffällig, und der Fehler zeigt sich erst im Betrieb. Der Schlüssel muss eindeutig sein und darf nichts enthalten, was man nicht mitschicken will; bei Personendaten ist schon die Kundennummer ein Datenschutzthema. *Wann nicht:* Bei einer sequentiellen Verarbeitung mit garantierter Reihenfolge genügt die Position. Das Pattern ist die *Korrelations-ID* aus verteilten Systemen und Nachrichtenmustern @hohpe_eip_2003, ohne die auch Tracing über Dienstgrenzen nicht auskommt.

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 5, Pattern 20); @hohpe_eip_2003 (Correlation Identifier); @kleppmann_ddia_2017 (Verarbeitung ohne garantierte Reihenfolge).

== Pattern 12: Checkpoints

=== Szenario und Problem

Auch das Training soll nachts laufen. Die Daten kommen als 30 Tagesdateien, und wir lesen sie fünfmal durch: 150 Schritte, bei denen das Modell je eine Datei sieht. Für ein lineares Modell mit `partial_fit` (der Weg in scikit-learn, Modelle auf Daten zu trainieren, die nicht in den Speicher passen) dauert das Sekunden, bei einem großen Modell sind es Stunden. Und Stunden auf einem Rechner, den der Cluster-Manager jederzeit entziehen kann, sind riskant. Bricht der Knoten bei Schritt 97 ab, ist ohne Zwischenstand alles verloren.

=== Lösung

Man speichert in festen Abständen den gesamten *Zustand* des Trainings, nicht nur die Parameter, sondern alles, was für die Fortsetzung nötig ist: den Schrittzähler, die Position in den Daten, bei neuronalen Netzen außerdem den Zustand des Optimierers und den Lernratenplan sowie den Zufallszustand. Im Beispiel steckt alles Nötige im Modellobjekt und in der Schrittnummer. Entscheidend ist ein Detail: Die Datei wird zuerst unter einem Zwischennamen geschrieben und dann *atomar umbenannt*; ein Abbruch mitten im Schreiben hinterlässt höchstens eine unbrauchbare Zwischendatei, aber nie einen halb geschriebenen Zwischenstand.

#code-aus("../code/13/08_checkpoints.py", "def trainiere", bis: "def ap(")

Das Skript führt drei Läufe aus (Ausgabe unten): einen ohne Störung, einen mit Abbruch bei Schritt 97 und ohne Zwischenstand, einen mit Abbruch und Zwischenständen alle zehn Schritte.

Beide gestörten Läufe landen beim selben Modell wie der ungestörte: Alle Koeffizienten sind identisch, das prüft `np.array_equal`. Der Unterschied liegt im Aufwand: Ohne Zwischenstand sind es 97 verlorene plus 150 neue Schritte, insgesamt 247. Mit Zwischenständen setzt der Lauf bei Schritt 90 wieder an und braucht 157 Schritte, 36 Prozent weniger. Dass das Ergebnis identisch ist, ist keine Selbstverständlichkeit, sondern hängt an Determinismus: fester Seed, feste Reihenfolge der Daten, und dass der Zufallszustand nicht verloren geht (`random_state=0` im Modell erzeugt bei jedem Aufruf dieselbe Folge, deshalb muss hier nichts zusätzlich gespeichert werden). Würde man den Seed weglassen, gäbe es nach der Wiederaufnahme ein anderes Modell, nicht ein falsches, aber ein nicht reproduzierbares.

#lauf("08_checkpoints.py", "../code/13/out/08_checkpoints.txt")

#figure(
  kind: image,
  canvas(length: 1cm, {
    import draw: *
    let b = 0.058
    let x(k) = k * b
    // oben: ohne Zwischenstand
    content((0, 2.15), anchor: "west", text(size: 8.5pt, weight: "bold")[ohne Checkpoint: 247 Schritte])
    rect((0, 1.2), (x(97), 1.8), fill: blau-hell, stroke: 0.8pt + blau)
    rect((x(97), 1.2), (x(247), 1.8), fill: orange-hell, stroke: 0.8pt + orange)
    content((x(48), 1.5), text(size: 8.5pt)[Schritte 0 bis 96])
    content((x(172), 1.5), text(size: 8.5pt)[Neustart: alle 150 Schritte])
    // unten: mit Zwischenstand
    content((0, 0.55), anchor: "west", text(size: 8.5pt, weight: "bold")[mit Checkpoints: 157 Schritte])
    rect((0, -0.35), (x(97), 0.25), fill: blau-hell, stroke: 0.8pt + blau)
    rect((x(97), -0.35), (x(157), 0.25), fill: gruen-hell, stroke: 0.8pt + gruen)
    for k in range(10, 100, step: 10) {
      line((x(k), -0.35), (x(k), -0.55), stroke: 0.8pt + blau)
    }
    content((x(48), -0.05), text(size: 8.5pt)[Schritte 0 bis 96])
    content((x(127), -0.05), text(size: 8.5pt)[ab Schritt 90])
    // Abbruch
    line((x(97), -0.7), (x(97), 2.0), stroke: (paint: orange, thickness: 1pt, dash: "dashed"))
    content((x(97), 2.55), anchor: "south", text(size: 8.5pt, fill: orange)[Knoten entzogen])
    // Achse
    line((0, -1.0), (x(250), -1.0), stroke: 0.6pt + luma(120))
    for k in (0, 50, 100, 150, 200, 250) {
      line((x(k), -1.0), (x(k), -1.1), stroke: 0.6pt + luma(120))
      content((x(k), -1.4), text(size: 8.5pt, fill: grau)[#k])
    }
    content((x(125), -1.9), text(size: 8.5pt, fill: grau)[verbrauchte Schritte (Rechenzeit)])
  }),
  caption: [Der Abbruch bei Schritt 97 und seine Folgen. Oben muss alles wiederholt werden, unten nur das Stück seit dem letzten Zwischenstand (Schritt 90). Die kurzen Striche unter dem Balken markieren die Checkpoints.],
) <abb-wartung-ckpt>

Wie oft man sichern soll, ist ein Abwägen: Je kürzer das Intervall, desto weniger geht im Mittel verloren (ein halbes Intervall) und desto mehr Schreibaufwand fällt an (Tabelle am Ende des Laufs). Bei einem großen Modell mit Gigabyte großem Zwischenstand nimmt man eher Abstände von Minuten bis Stunden.

=== Grenzen und Bezug zu Software Engineering

Nicht jedes Modell lässt sich so trainieren. `partial_fit` gibt es für lineare Modelle, naive Bayes oder Mini-Batch-k-Means, aber nicht für das Gradient Boosting der Cloud-Stufe, das wir in Sekunden komplett neu trainieren; Checkpoints lohnen dort, wo ein Lauf Stunden dauert. Ein Zwischenstand ist an Bibliotheks- und Codeversionen gebunden (Pickle und Joblib führen beim Laden Code aus, siehe Pattern 16) und braucht Platz. Das Buch nennt zwei weitere Verwendungen, nämlich Ausgangspunkt für Feintuning und das beste Zwischenmodell als Ergebnis (Early Stopping), und als Variante *virtuelle Epochen*, die Schritte in einer festen Zahl von Beispielen statt in Durchläufen zählen. *Wann nicht:* Bei kurzem Training überwiegen Aufwand und Komplexität. Das Prinzip ist der Snapshot aus Datenbanken, das atomare Umbenennen kennt man aus Dateisystemen, und ein Job, der nach Abbruch wieder anlaufen kann, ist *idempotent*.

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 4, Pattern 12); @pedregosa_scikit_learn_2011 (`partial_fit`, Out-of-Core-Lernen).

== Das Gesamtsystem

Die sieben Patterns ergeben eine Architektur mit zwei Orten, dem Gerät an der Pumpe und der Cloud, und einem Trainingsweg, der beide versorgt (@abb-wartung-arch). Auf dem Gerät sitzen Ringpuffer, Merkmalsfunktion und Stufe 1. Was auffällt, geht mit Pumpen-ID und Zeitstempel in die Cloud, wo Stufe 2 bewertet und die Antwort über den Schlüssel zugeordnet wird. Dieselbe Merkmalsfunktion erzeugt im Training die Tabelle, aus der nach Pumpe und Zeit aufgeteilt wird; das Training läuft über Tagesdateien mit Zwischenständen, und die nächtliche Einsatzplanung ist ein Batch-Aufruf desselben Modells.

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (12mm, 11mm),
    node(enclose: ((0, 0), (1, 0)), snap: false, stroke: (paint: grau, dash: "dashed"), inset: 18pt),
    node(enclose: ((2, 0), (3, 0)), snap: false, stroke: (paint: grau, dash: "dashed"), inset: 18pt),
    node((0.5, -0.8), klein[Edge-Gerät an der Pumpe], stroke: none, snap: false),
    node((2.5, -0.8), klein[Cloud], stroke: none, snap: false),
    neben((0, 0), [Sensoren, Ringpuffer \ #klein[`merkmale()`, Pattern 24]], fill: gruen-hell, stroke: gruen),
    knoten((1, 0), [Stufe 1 \ #klein[Pattern 19]]),
    knoten((2, 0), [Stufe 2 \ #klein[Schlüssel, Pattern 20]], farbe: orange, grund: orange-hell),
    neben((3, 0), [Alarm, \ Wartungsplan]),
    neben((3, 1.5), [Nächtlicher Batch \ #klein[Pattern 17]]),
    neben((1.5, 1.5), [Modelle \ #klein[Stufe 1 und 2]]),
    neben((0, 3), [Historie, `merkmale()` \ #klein[dieselbe Funktion]], fill: gruen-hell, stroke: gruen),
    knoten((1, 3), [Split nach Pumpe \ und Zeit \ #klein[Pattern 22]]),
    knoten((2, 3), [Training mit \ Checkpoints \ #klein[Pattern 12, 5]]),
    edge((0, 0), (1, 0), "->"),
    edge((1, 0), (2, 0), "->", label: klein[auffällig], label-side: left),
    edge((2, 0), (3, 0), "->"),
    edge((3, 1.5), (2, 0), "->"),
    edge((0, 3), (1, 3), "->"), edge((1, 3), (2, 3), "->"),
    edge((2, 3), (1.5, 1.5), "->"),
    edge((1.5, 1.5), (1, 0), "->", stroke: (dash: "dashed", paint: grau)),
    edge((1.5, 1.5), (2, 0), "->", stroke: (dash: "dashed", paint: grau)),
  )),
  caption: [Architektur der Fallstudie. Oben der Betrieb mit Gerät und Cloud, unten der Trainingsweg. Gestrichelt: Die trainierten Modelle gehen an beide Stufen. Die grünen Knoten sind dieselbe Funktion.],
) <abb-wartung-arch>

#figure(
  text(size: 9.5pt, table(
    columns: (auto, 1fr, 1fr),
    inset: (x: 0.6em, y: 0.45em),
    align: (left, left, left),
    [Pattern], [Ohne], [Mit],
    [22 Repeatable Splitting], [PR-AUC 0,992 (Zufallssplit), geschönt], [PR-AUC 0,862 (zeitlich), ehrlich; 0,858 bei neuen Pumpen und neuer Zeit],
    [24 Windowed Inference], [offline Recall 0,84, im Stream 0,50 (Fenster mit Zukunft; zeilenweise)], [Recall 0,69, offline und im Stream gleich],
    [5 Reframing], [PR-AUC 0,823 (rohe RUL)], [0,863 (Klassifikation), 0,886 (RUL auf 72 h gekappt)],
    [19 Two-Phase], [288 000 Cloud-Aufrufe pro Tag], [138 639 (−52 %), dafür 3 Fehlalarme mehr im Test],
    [17 Batch Serving], [Einzelaufruf: Größenordnung 1 ms je Zeile], [Paket: wenige µs je Zeile, Faktor 100 bis 300],
    [20 Keyed Predictions], [PR-AUC 0,229, 79 % der Alarme falsch zugeordnet], [PR-AUC 0,863, Zuordnung identisch zur Referenz],
    [12 Checkpoints], [247 Schritte nach Abbruch], [157 Schritte (−36 %), identisches Modell],
  )),
  kind: table,
  caption: [Wirkung der Patterns in dieser Fallstudie. Alle Zahlen stammen aus den Läufen im Verzeichnis `code/13`; die Kosten in Euro beruhen auf den im Text genannten Annahmen.],
) <tab-wartung-effekte>

Die Tabelle zeigt auch, wo die Patterns nichts verbessern, sondern etwas offenlegen: Pattern 22 macht nicht das Modell besser, sondern die Messung ehrlicher, Pattern 24 und 20 verhindern Fehler, die man im Labor nicht sieht, und Pattern 5 und 19 verschieben Kompromisse, die man nur mit Kosten und Fehlerzahlen beurteilen kann. Das passt zur Beobachtung von #cite(<sculley_hidden_debt_2015>, form: "prose"), dass das Modell nur einen kleinen Teil eines produktiven ML-Systems ausmacht und der Rest aus Daten- und Betriebsinfrastruktur besteht.

== Das Wichtigste in Kürze

- Bei Zeitreihen ist ein zufälliger Split ein Messfehler: Er meldete 0,992 PR-AUC, wo der ehrliche zeitliche Split 0,862 ergab. Man trennt nach Pumpe und nach Zeit, mit einer Lücke von mindestens der Länge des Vorhersagehorizonts.
- Ein Fenstermerkmal darf nur Vergangenheit sehen. Eine Merkmalsfunktion für Training und Betrieb und ein Äquivalenztest zwischen Batch und Stream verhindern, dass sich zwei Implementierungen auseinanderentwickeln.
- Ob Regression oder Klassifikation, entscheidet die Entscheidung dahinter. Das Ziel auf den relevanten Bereich zu beschränken, brachte in der PR-AUC mehr als die Wahl des Aufgabentyps (0,823 gegen 0,886); in den Kosten waren alle drei Ansätze nahezu gleich.
- Ein zweistufiges Modell spart Aufrufe, aber nur der Vergleich mit den Fehlerkosten zeigt, ob es sich lohnt. Die Rechnung der Fallstudie ergibt: nur bei hohen Aufrufkosten oder fehlender Verbindung.
- Wer parallel bewertet, führt einen Schlüssel mit (Pumpe und Zeitstempel). Die Position taugt nicht als Zuordnung.
- Zwischenstände mit atomarem Schreiben machen ein langes Training abbruchsicher; im Beispiel kostete ein Abbruch 157 statt 247 Schritte.

#kasten([So erkläre ich es.], [
  „Jedes Mal, wenn wir im Labor etwas tun, was im Betrieb nicht möglich wäre (Zeilen mischen, in die Zukunft schauen, Vorhersagen nach Position zuordnen), wird die Zahl im Labor besser und im Betrieb schlechter. Ich lasse die Studierenden raten, welchen Wert Zufallssplit und Zeitsplit ergeben, bevor ich die Zahlen zeige.“

  *Verständnisfrage:* Ein Team meldet, sein Modell erkenne 92 Prozent der Ausfälle, im Betrieb sind es nur 55 Prozent. Wo suchen Sie zuerst? \
  *Antwort:* Nach einem Unterschied zwischen Training und Betrieb in der Datenaufbereitung, vor allem bei Fenstermerkmalen: Reicht ein Fenster in die Zukunft (`center=True`, Tagesmittel über den ganzen Tag)? Hatten Testzeilen Nachbarn im Training? Wurde die Alarmschwelle auf verfälschten Werten gewählt? Ein Äquivalenztest zwischen Batch und Stream findet den ersten Fall.
])

== Weiterführende Literatur

Einen Überblick über Methoden der vorausschauenden Wartung geben #cite(<carvalho_predictive_maintenance_2019>, form: "prose"); die C-MAPSS-Daten @saxena_cmapss_2008 sind ein frei verfügbarer Vergleichsfall mit Restlebensdauer als Ziel. Zur Aufteilung von Zeitreihen und strukturierten Daten siehe #cite(<bergmeir_cv_timeseries_2012>, form: "prose") und #cite(<roberts_cross_validation_2017>, form: "prose"), zur Fensterung in Datenströmen #cite(<akidau_dataflow_model_2015>, form: "prose") und das Stream-Kapitel bei #cite(<kleppmann_ddia_2017>, form: "prose"). Das Gradient Boosting geht auf #cite(<friedman_gradient_boosting_2001>, form: "prose") zurück, die Histogramm-Variante in scikit-learn ist von LightGBM @ke_lightgbm_2017 inspiriert. Zu Betriebsrisiken von ML-Systemen siehe #cite(<sculley_hidden_debt_2015>, form: "prose") und die Checkliste von #cite(<breck_ml_test_score_2017>, form: "prose").

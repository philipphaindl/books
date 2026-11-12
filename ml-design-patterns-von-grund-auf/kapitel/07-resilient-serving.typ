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
// Wie `ausgabe`, aber mit ausgewählten Zeilen; Lücken werden mit "..." markiert.
#let ausgabe-zeilen(befehl, datei, indizes) = {
  let z = read(datei).trim("\n", at: end).split("\n")
  let aus = ()
  let letzte = -1
  for i in indizes {
    if letzte >= 0 and i > letzte + 1 { aus.push("...") }
    aus.push(z.at(i))
    letzte = i
  }
  raw("$ " + befehl + "\n" + aus.join("\n"), lang: "terminal", block: true)
}
#let knoten(pos, body, farbe: blau, grund: blau-hell, ..args) = node(pos, body, stroke: farbe, fill: grund, ..args)
#let neben(pos, body, ..args) = node(pos, body, stroke: 0.6pt + luma(150), fill: nebel, ..args)

= Resilient Serving

Ein trainiertes Modell nützt erst, wenn jemand seine Vorhersagen abrufen kann. Das nennt man *Serving* (auch Inferenz): das Modell mit neuen Eingaben füttern und die Antwort zurückliefern. Dabei gibt es zwei Grundformen. Beim *Online-Serving* fragt ein Client einzelne Vorhersagen ab und erwartet die Antwort in Millisekunden, etwa eine App, die eine Lieferzeit anzeigt. Beim *Batch-Serving* bewertet ein Job viele Datensätze auf einmal, ohne dass jemand wartet, etwa über Nacht. Das Kapitel entspricht Kapitel 5 im Buch von Lakshmanan et al. @lakshmanan_ml_design_patterns_2020. „Resilient“ bedeutet hier: Der Betrieb soll skalieren, Ausfälle verkraften und merken, wenn das Modell mit der Zeit schlechter wird.

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (23mm, 12mm),
    knoten((0, 1), [Exportiertes \ Modell]),
    knoten((1, 0), [Online-Service \ #text(size: 8.5pt, fill: grau)[Pattern 16]]),
    knoten((1, 1), [Batch-Job \ #text(size: 8.5pt, fill: grau)[Pattern 17]]),
    knoten((1, 2), [Edge + Cloud \ #text(size: 8.5pt, fill: grau)[Pattern 19]]),
    knoten((2, 1), [Vorhersagen \ #text(size: 8.5pt, fill: grau)[mit Schlüssel, Pattern 20]], farbe: gruen, grund: gruen-hell),
    knoten((3, 1), [Überwachung \ #text(size: 8.5pt, fill: grau)[Pattern 18]], farbe: orange, grund: orange-hell),
    edge((0, 1), (1, 0), "->"), edge((0, 1), (1, 1), "->"), edge((0, 1), (1, 2), "->"),
    edge((1, 0), (2, 1), "->"), edge((1, 1), (2, 1), "->"), edge((1, 2), (2, 1), "->"),
    edge((2, 1), (3, 1), "->"),
    edge((3, 1), (3, 3), "-"), edge((3, 3), (0, 3), "-", label: [Retraining: neues Modell], label-side: right), edge((0, 3), (0, 1), "->"),
  )),
  caption: [Die fünf Patterns dieses Kapitels. Ein Modell wird auf drei Wegen ausgeliefert, seine Vorhersagen tragen Schlüssel, und die Überwachung stößt bei Bedarf ein neues Training an.],
)

== Pattern 16: Stateless Serving Function

*Szenario und Problem.* Ein Lieferdienst möchte in seiner App die erwartete Lieferzeit anzeigen. Das Modell bekommt Entfernung, Artikelzahl, Uhrzeit und Wetter (5 000 synthetische Bestellungen mit selbst festgelegten Zusammenhängen, damit wir das Ergebnis prüfen können). Die Antwort soll in unter 100 Millisekunden kommen, zu Stoßzeiten für tausende Nutzer gleichzeitig.

Im Notebook liegt das Modell als Python-Objekt im Arbeitsspeicher, und daraus einen Dienst zu machen, scheitert auf drei Arten. Der Prozess, in dem das Objekt entstand, skaliert nicht. Die Vorverarbeitung steckt im Notebook-Code und müsste im Dienst nachgebaut werden; weicht dort das Feature „Abendspitze“ (Bestellstunde 18, 19 oder 20) auch nur leicht ab, rechnet das Modell mit Eingaben, die es so nie gesehen hat (*Training-Serving Skew*). Und viele Dienste bauen unbemerkt Zustand auf, etwa Caches, Sitzungsdaten oder Zähler im Prozess; dann liefern zwei Kopien nicht mehr dasselbe, und man kann keine weiteren starten.

*Die Lösung.* Man exportiert Modell *und* Vorverarbeitung als ein Artefakt und stellt es hinter eine Funktion, die ihr Ergebnis nur aus den Argumenten berechnet. Das Modell wird einmal beim Start geladen und danach nur gelesen; zwischen zwei Aufrufen bleibt nichts zurück. In scikit-learn ist das Artefakt eine `Pipeline` aus Feature-Berechnung und Regressor, die sich als Datei speichern lässt:

#code-aus("../code/07-resilient-serving/modell_exportieren.py", "modell = Pipeline([", bis: "print(f\"MAE")

`joblib.dump(modell, "modell.joblib")` schreibt die Datei (140 KiB). Der mittlere absolute Fehler (MAE) auf den Testdaten liegt bei 2,03 Minuten. Das ist praktisch die Untergrenze: Bei normalverteiltem Rauschen mit Standardabweichung 2,5 Minuten, wie es in die Daten eingebaut ist, hat selbst ein perfektes Modell einen MAE von rund 0,8 mal 2,5, also etwa 2,0 Minuten. Die Funktion `abendspitze_ergaenzen` steht bewusst in einer eigenen Datei: Joblib (wie Pickle) speichert eine Funktion nicht als Code, sondern als Verweis auf Modul und Namen. Beim Laden muss `merkmale.py` in derselben Version importierbar sein, sonst scheitert das Laden oder läuft mit anderem Verhalten. Modell und Hilfscode werden deshalb gemeinsam in einem Paket oder Container-Image versioniert. Die Serving-Funktion selbst ist kurz, FastAPI übernimmt die Validierung der Eingaben:

#code-aus("../code/07-resilient-serving/serving_app.py", "MODELL = ")

Der Test braucht keinen laufenden Server, denn `TestClient` ruft die Anwendung direkt auf. Er prüft außerdem die Zustandslosigkeit: Dieselben 30 Anfragen laufen einmal der Reihe nach reihum über drei unabhängig geladene Kopien des Modells und einmal gemischt über zufällig gewählte Kopien.

#ausgabe("uv run --with scikit-learn --with pandas --with fastapi \\\n    --with httpx python serving_test.py", "../code/07-resilient-serving/serving_test.out.txt")

Gleiche Eingabe, gleiche Antwort, unabhängig von Reihenfolge und Kopie: Das ist Zustandslosigkeit im praktischen Sinn. Damit lassen sich beliebig viele Kopien hinter einen Lastverteiler stellen, bei Last weitere starten und ausgefallene ersetzen (@abb-serving-replikate).

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (20mm, 11mm),
    knoten((0, 1), [App]),
    neben((1, 1), [Load \ Balancer]),
    knoten((2, 0), [Kopie 1 \ #text(size: 8.5pt, fill: grau)[Funktion + Modell]]),
    knoten((2, 1), [Kopie 2 \ #text(size: 8.5pt, fill: grau)[Funktion + Modell]]),
    knoten((2, 2), [Kopie 3 \ #text(size: 8.5pt, fill: grau)[Funktion + Modell]]),
    neben((3, 1), [Modell-Datei \ #text(size: 8.5pt, fill: grau)[versioniert, nur lesen]]),
    edge((0, 1), (1, 1), "->"),
    edge((1, 1), (2, 0), "->"), edge((1, 1), (2, 1), "->"), edge((1, 1), (2, 2), "->"),
    edge((3, 1), (2, 0), "->", stroke: (dash: "dashed", paint: grau)), edge((3, 1), (2, 1), "->", stroke: (dash: "dashed", paint: grau)), edge((3, 1), (2, 2), "->", stroke: (dash: "dashed", paint: grau)),
  )),
  caption: [Jede Kopie lädt beim Start dieselbe Datei und hält sonst nichts. Der Lastverteiler darf Anfragen beliebig verteilen.],
) <abb-serving-replikate>

*Trade-offs und Grenzen.* Jeder Aufruf zahlt Latenz für Netz und Serialisierung, und eine neue Kopie muss erst das Modell laden (*Kaltstart*), bei großen Modellen Sekunden bis Minuten. Braucht die Vorhersage Wissen über den Nutzer, etwa seine letzten zehn Bestellungen, darf es nicht im Dienst liegen: Es muss mit der Anfrage kommen oder aus einem externen Speicher geholt werden, zum Beispiel einem Feature Store (Pattern 26), was Latenz kostet. Joblib und Pickle führen beim Laden Code aus, man lädt also nur eigene, vertrauenswürdige Dateien. Sprachneutrale Austauschformate wie ONNX vermeiden das Modul-Problem, verlangen aber, dass sich auch die Vorverarbeitung in ihren Operatoren ausdrücken lässt; das Buch exportiert TensorFlow-Modelle als SavedModel und definiert die Serving-Funktion als dessen Signatur. *Wann nicht:* für Millionen Datensätze ohne Zeitdruck (Pattern 17) oder wenn das Ergebnis ohne Netz verfügbar sein muss (Pattern 19).

*Bezug zu Software Engineering.* Das ist die bekannte Regel für skalierbare Dienste: zustandslose Prozesse, Zustand in externen Speicher. Fielding nennt „stateless“ als Einschränkung des REST-Architekturstils @fielding_rest_2000, und die Twelve-Factor-App verlangt dasselbe von Prozessen @wiggins_twelve_factor_2011. Die Serving-Funktion ist eine reine Funktion: dieselben Argumente, dasselbe Ergebnis, keine Nebenwirkungen. Dass Modell und Vorverarbeitung gemeinsam ausgeliefert werden, ist Single Source of Truth, das in Pattern 21 (Transform) wiederkehrt.

#kasten([So erkläre ich es.], [
  „Das Modell ist eine Funktion von Features zu einer Vorhersage. Wir packen sie samt Vorverarbeitung in eine Datei, und jeder Dienstprozess lädt dieselbe Datei. Wenn ich hundert Kopien starten und Anfragen würfeln kann, ist der Dienst zustandslos.“

  *Verständnisfrage:* Zwei identische Anfragen gehen an zwei Kopien des Dienstes und liefern verschiedene Antworten. Wo suchen Sie? \
  *Antwort:* Nach versteckten Unterschieden: verschiedene Modellversionen auf den Kopien (etwa mitten in einem Rollout), Zustand, der zwischen Aufrufen im Prozess bleibt, oder Zufallselemente ohne festen Seed. Im Experiment gibt es keinen davon, deshalb sind die Antworten identisch.
])

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 5, Pattern 16); @fielding_rest_2000.

== Pattern 17: Batch Serving

*Szenario und Problem.* Der Lieferdienst will jeden Morgen für alle 200 000 offenen Bestellungen die erwartete Lieferzeit berechnen, um Fahrer einzuplanen. Niemand wartet auf eine einzelne Antwort; wichtig ist, dass bis sieben Uhr alles fertig ist. Naheliegend wäre, den Online-Dienst aus Pattern 16 200 000 Mal aufzurufen. Das funktioniert, ist aber verschwenderisch: Jeder Aufruf zahlt Fixkosten für Netz, Serialisierung, Validierung und das Aufbereiten einer einzelnen Zeile, und der Dienst müsste auf den Ansturm dimensioniert werden, obwohl er den Rest des Tages leer läuft. Das ist das N+1-Problem der Datenbankwelt: ein Roundtrip pro Zeile statt einer Abfrage für alle.

*Die Lösung.* Man bewertet die Daten in großen Portionen. Ein Modell bewertet viele Zeilen in einem Durchlauf, vektorisiert und ohne Python-Schleife, und der Fixaufwand pro Aufruf (Eingabe prüfen, DataFrame bauen, Pipeline durchlaufen) fällt nur einmal an. Das Skript vergleicht mit dem Modell aus Pattern 16 Einzelaufrufe und eine Batch-Vorhersage auf denselben Daten:

#code-aus("../code/07-resilient-serving/batch_serving.py", "# a) Einzelaufrufe", bis: "print(\"a/b)")

#ausgabe("uv run --with scikit-learn --with pandas --with numpy python batch_serving.py", "../code/07-resilient-serving/batch_serving.out.txt")

Ein Einzelaufruf schafft hier rund 270 Vorhersagen pro Sekunde, die Batch-Vorhersage rund 600 000, also mehr als das Zweitausendfache. Die genauen Zahlen hängen von Maschine und Auslastung ab: Ein zweiter Lauf auf demselben Rechner lieferte 421 und 440 938 Vorhersagen pro Sekunde, einen Faktor von rund 1 000. Die Größenordnung ist das Ergebnis, nicht die dritte Stelle: Der Batch ist um drei Größenordnungen schneller. Der Einzelaufruf misst außerdem nur Python und scikit-learn, ohne Netz und Serialisierung. Ein echter Dienst wäre also eher langsamer.

Der dritte Teil zeigt die Betriebsform: Die Eingabedatei wird in Stücken von 50 000 Zeilen gelesen, jedes Stück bewertet und sofort an die Ausgabedatei angehängt, sodass der Speicherbedarf unabhängig von der Dateigröße bleibt. Die Spalte `bestell_id` wandert unverändert durch den Job und steht in der Ausgabe neben der Vorhersage (mehr dazu in Pattern 20). Wird die Datenmenge zu groß für eine Maschine, verteilt man dieselbe Struktur auf viele Rechner, etwa mit Spark, Apache Beam oder einer SQL-Engine, die Modelle direkt aufrufen kann; das Buch beschreibt das Pattern mit solcher verteilten Datenverarbeitung. Das Prinzip bleibt gleich: Daten in Teile zerlegen, Teile unabhängig bewerten, Ergebnisse mit Schlüssel zusammenführen.

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (22mm, 10mm),
    neben((0, 1), [Tabelle \ #text(size: 8.5pt, fill: grau)[200 000 Zeilen]]),
    knoten((1, 0), [Stück 1]), knoten((1, 1), [Stück 2]), knoten((1, 2), [Stück 3 ...]),
    knoten((2, 1), [Modell \ #text(size: 8.5pt, fill: grau)[vektorisiert]]),
    knoten((3, 1), [Ergebnistabelle \ #text(size: 8.5pt, fill: grau)[Schlüssel + Vorhersage]], farbe: gruen, grund: gruen-hell),
    neben((2, 2.2), [Zeitplan \ #text(size: 8.5pt, fill: grau)[z. B. täglich 03:00]]),
    edge((0, 1), (1, 0), "->"), edge((0, 1), (1, 1), "->"), edge((0, 1), (1, 2), "->"),
    edge((1, 0), (2, 1), "->"), edge((1, 1), (2, 1), "->"), edge((1, 2), (2, 1), "->"),
    edge((2, 1), (3, 1), "->"),
    edge((2, 2.2), (2, 1), "->", stroke: (dash: "dashed", paint: grau), label: [startet], label-side: left),
  )),
  caption: [Batch Serving: Die Tabelle wird in Stücke zerlegt, jedes Stück in einem Zug bewertet, die Vorhersagen landen mit ihrem Schlüssel in einer Ergebnistabelle.],
)

*Trade-offs und Grenzen.* Batch-Vorhersagen sind so alt wie der letzte Lauf: Eine Bestellung, die um 9 Uhr eingeht, hat bis zum nächsten Morgen keine Vorhersage. Man berechnet und speichert auch Vorhersagen, die nie jemand abruft. Der Job muss mit Teilausfällen umgehen können: Läuft er nach einem Abbruch neu an, sollte er dieselben Schlüssel überschreiben und nicht doppelt anlegen (Idempotenz). Und die Features müssen im Batch-Job genauso berechnet werden wie im Online-Dienst, sonst droht wieder Training-Serving Skew; am einfachsten gelingt das, wenn beide dieselbe Pipeline-Datei laden. *Wann nicht:* wenn die Eingabe erst zur Laufzeit entsteht (Suchanfrage, Kamerabild) oder die Antwort frisch sein muss. Häufig kombiniert man beides: Das Batch-Ergebnis deckt den Normalfall ab, der Online-Dienst die Nachzügler.

*Bezug zu Software Engineering.* Batch- gegen Online-Verarbeitung ist ein Grundthema der Datenarchitektur @kleppmann_ddia_2017: Offline-Systeme optimieren Durchsatz, Online-Systeme Antwortzeit. Das Muster ist die Bulk-Schnittstelle statt vieler Einzelaufrufe, die Abhilfe gegen das N+1-Problem, und der Aufwand wird wie bei jeder Stapelverarbeitung über viele Elemente amortisiert.

#kasten([So erkläre ich es.], [
  „Wer 200 000 Mal einzeln nachfragt, zahlt 200 000 Mal die Fixkosten. Das ist wie ein SELECT pro Zeile in einer Schleife. Ein Batch-Job liest alles auf einmal, rechnet vektorisiert und schreibt die Ergebnisse mit Schlüssel zurück.“

  *Verständnisfrage:* Wann würden Sie trotz des Durchsatzvorteils den Online-Dienst wählen? \
  *Antwort:* Wenn die Eingaben erst zur Laufzeit existieren (etwa eine Suchanfrage) oder die Vorhersage aktuell sein muss und ein gestriger Wert nichts nützt.
])

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 5, Pattern 17); @kleppmann_ddia_2017.

== Pattern 18: Continued Model Evaluation

*Szenario und Problem.* Ein Onlinehändler sagt voraus, ob ein Kunde innerhalb von 30 Tagen wiederkommt. Das Modell wird mit den Daten der ersten vier Wochen trainiert, erreicht rund 86 Prozent Genauigkeit und wird ausgeliefert. Dann passiert zunächst nichts Sichtbares: keine Fehlermeldung, keine Ausnahme, kein Absturz. Trotzdem wird das Modell im Lauf der Monate schlechter, weil sich die Welt ändert, in der es eingesetzt wird: neue Produkte, eine Preisaktion, ein neuer Marketingkanal. Code verhält sich bei gleicher Eingabe morgen wie heute. Ein Modell kann auch ohne jeden Eingriff schlechter werden, weil es ein Abbild der Daten von gestern ist.

Der Fachbegriff dafür ist *Drift*. Gama et al. @gama_concept_drift_2014 unterscheiden, was sich ändert. Beim *Covariate Shift* ändert sich die Verteilung der Eingaben ($P(x)$), etwa weil plötzlich andere Kunden kommen, der Zusammenhang zwischen Eingabe und Ergebnis bleibt aber. Das entspricht dem, was Gama et al. *virtual drift* nennen. Beim *Concept Drift* im engeren Sinn (*real drift*) ändert sich der Zusammenhang selbst ($P(y|x)$): Dieselbe Eingabe führt nun zu einem anderen Ergebnis. Auch die zeitliche Form unterscheiden sie: plötzlich (sudden), inkrementell (viele kleine Schritte), graduell (die Daten wechseln eine Zeit lang zwischen altem und neuem Zustand hin und her) oder wiederkehrend (etwa saisonal).

*Die Lösung.* Das Pattern verlangt, das Modell nach dem Ausliefern weiter zu bewerten. Dazu loggt man Eingaben und Vorhersagen mit einem Schlüssel (Pattern 20), führt das tatsächliche Ergebnis nachträglich zu, sobald es bekannt ist (im Beispiel nach 30 Tagen), und berechnet regelmäßig Kennzahlen, die man mit Schwellen vergleicht. Die *Eingaben* lassen sich sofort überwachen, ohne das Ergebnis zu kennen, zum Beispiel mit dem Population Stability Index (PSI), der die Verteilung einer Eingabe mit der aus dem Training vergleicht. Die *Qualität* (Genauigkeit gegen die Wahrheit) ist die entscheidende Größe, steht aber erst mit Verzögerung zur Verfügung.

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (19mm, 14mm),
    knoten((0, 0), [Serving \ #text(size: 8.5pt, fill: grau)[Vorhersage + Schlüssel]]),
    knoten((1, 0), [Protokoll \ #text(size: 8.5pt, fill: grau)[Eingaben, Vorhersagen]]),
    neben((1, 1), [tatsächliches Ergebnis \ #text(size: 8.5pt, fill: grau)[trifft verzögert ein]]),
    knoten((2, 0), [Kennzahlen \ #text(size: 8.5pt, fill: grau)[PSI, Genauigkeit]]),
    knoten((3, 0), [Schwelle \ überschritten?], farbe: orange, grund: orange-hell),
    knoten((3, 1), [Retraining, \ Prüfung, Rollout], farbe: gruen, grund: gruen-hell),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((1, 1), (2, 0), "->", label: [Join über Schlüssel], label-side: right),
    edge((2, 0), (3, 0), "->"), edge((3, 0), (3, 1), "->", label: [ja], label-side: right),
    edge((3, 1), (3, 2), (0, 2), (0, 0), "->", stroke: (dash: "dashed", paint: grau), label: [neues Modell ersetzt das alte], label-side: right),
  )),
  caption: [Der Überwachungskreislauf. Die Qualität wird erst gemessen, wenn das tatsächliche Ergebnis über den Schlüssel zugeordnet werden kann.],
)

Das Skript simuliert 24 Wochen mit je 2 000 Fällen und zwei Features $x_1$ und $x_2$ (etwa Bestellhäufigkeit und Warenkorbwert). Die ersten vier Wochen dienen dem Training, in den Wochen 4 bis 7 bleibt alles gleich. In den Wochen 8 bis 13 verschiebt sich $x_1$ um 1,5 Standardabweichungen nach oben, der Zusammenhang bleibt (Covariate Shift). Ab Woche 14 wandert die Beziehung zwischen Features und Ergebnis über vier Wochen in eine neue (Concept Drift, inkrementell). Das alte Modell wird jede Woche bewertet. Der PSI teilt die Werte der Referenzwochen in zehn gleich stark besetzte Klassen (Dezile) und vergleicht, wie viel Anteil der aktuellen Woche in jede Klasse fällt. Zusätzlich prüft der Kolmogorov-Smirnov-Test (KS-Test, Kapitel 2), ob die Werte der aktuellen Woche aus derselben Verteilung stammen wie die der Referenz.

#ausgabe-zeilen("uv run --with scikit-learn --with numpy --with scipy python drift.py", "../code/07-resilient-serving/drift.out.txt", (0, 4, 5, 10, 11, 12, 20, 21, 22, 23, 24, 27, 28, 29))

#let drift = json("../code/07-resilient-serving/drift_verlauf.json")
#figure(
  kind: image,
  align(center, text(size: 9pt, stack(dir: ttb, spacing: 8pt,
    canvas(plot.plot(
      size: (11, 3.1), x-label: none, y-label: [Genauigkeit], x-min: 4, x-max: 23, x-tick-step: 2,
      y-min: 0.4, y-max: 1.0, y-tick-step: 0.2,
      {
        plot.add(drift.woche.zip(drift.acc), mark: "o", mark-size: 0.12, style: (stroke: blau + 1.2pt), mark-style: (fill: blau, stroke: none))
        plot.add-hline(drift.schwelle, style: (stroke: (paint: orange, dash: "dashed", thickness: 1pt)))
        plot.add-vline(8, 14, style: (stroke: (paint: luma(170), dash: "dotted")))
      },
    )),
    canvas(plot.plot(
      size: (11, 3.1), x-label: [Woche], y-label: [PSI von $x_1$], x-min: 4, x-max: 23, x-tick-step: 2,
      y-min: 0, y-max: 2.5, y-tick-step: 0.5,
      {
        plot.add(drift.woche.zip(drift.psi), mark: "o", mark-size: 0.12, style: (stroke: blau + 1.2pt), mark-style: (fill: blau, stroke: none))
        plot.add-hline(0.25, style: (stroke: (paint: orange, dash: "dashed", thickness: 1pt)))
        plot.add-vline(8, 14, style: (stroke: (paint: luma(170), dash: "dotted")))
      },
    )),
  ))),
  caption: [Genauigkeit (oben) und PSI der Eingabe $x_1$ (unten) je Woche. Orange gestrichelt: Alarmschwellen 0,80 und 0,25. Die gepunkteten Linien trennen die Phasen stabil, Covariate Shift (Wochen 8 bis 13) und Concept Drift (ab Woche 14).],
) <abb-drift-verlauf>

Drei Dinge fallen auf. Erstens lösen die Wochen 8 bis 13 den Eingabe-Alarm aus: Der PSI liegt bei 2,0 bis 2,2, weit über der verbreiteten Faustregel von 0,25 (sie stammt aus der Kreditrisikomodellierung und hat keine theoretische Begründung), und der KS-Test liefert p-Werte von praktisch null. Die Genauigkeit sinkt dabei nicht, sie steigt auf rund 94 Prozent, weil die verschobenen Fälle im Mittel weiter von der Entscheidungsgrenze entfernt liegen: ein Alarm ohne Schaden. Zweitens ist es beim Concept Drift ab Woche 14 umgekehrt: Die Genauigkeit fällt von 0,86 über 0,81 und 0,71 auf rund 0,54, kaum besser als Raten bei zwei Klassen, während der PSI bei 0,01 bleibt. Die Eingaben sehen unverändert aus, nur ihre Bedeutung hat sich geändert: ein Schaden ohne Alarm. Wer sich auf einen der beiden Signalwege allein verlässt, irrt sich also in beide Richtungen. Drittens löst die Schwelle von 0,80 den Qualitätsalarm in Woche 15 aus; in Woche 14 liegt der Wert mit 0,809 knapp darüber.

Zwei Wochen nach dem Alarm wird mit den vier jüngsten Wochen neu trainiert (im Experiment steht das für Datenaufbereitung und Freigabe). Das neue Modell erreicht in den Folgewochen 0,78 statt 0,54. Es ist aber nicht wieder so gut wie am Anfang. Der Grund liegt in den Trainingsdaten: Die Wochen 14 bis 16 enthalten noch die wandernde Beziehung. Ein Modell, das nur mit den stabilen Wochen 18 bis 21 trainiert wird, erreicht in den Wochen 22 und 23 dagegen 0,863 und 0,856, so viel wie das ursprüngliche Modell zu Beginn. (In Woche 17 weiß man allerdings noch nicht, dass die Beziehung ab Woche 18 stabil bleibt; der Vergleich zeigt den Effekt des Fensters, kein umsetzbares Vorgehen.) Das Datenfenster für das Retraining ist also eine eigene Entscheidung: Ein zu kurzes verschenkt Daten, ein zu langes mischt veraltete Zustände ein.


*Trade-offs und Grenzen.* Die Qualität lässt sich nur messen, wenn die Wahrheit bekannt ist, und die kommt oft spät oder nie: Wer einen Kredit ablehnt, erfährt nicht, ob der Kunde ihn zurückgezahlt hätte. Dann bleiben von Hand beschriftete Stichproben oder Stellvertretergrößen wie die Verteilung der Vorhersagen. Schwellen sind Abwägungen: Ein enger PSI-Schwellwert erzeugt Fehlalarme (wie in den Wochen 8 bis 13), ein weiter verpasst Veränderungen, und bei großen Stichproben schlägt jeder statistische Test schon bei winzigen Verschiebungen an. Modelle können ihre eigenen Daten verändern: Wer nur die Kunden sieht, denen das Modell Werbung zeigt, lernt aus einer Auswahl, die das Modell selbst getroffen hat. Und Retraining ist kein Selbstläufer; ein automatisch trainiertes Modell kann aus fehlerhaften Daten Falsches lernen, deshalb gehört vor den Austausch eine Prüfung gegen das alte Modell. Neben dem leistungsbasierten Auslöser aus dem Beispiel sind zeitbasierte (monatlich) und datenbasierte (genug neue Beispiele, PSI-Alarm) üblich. *Wann nicht:* Eine einmalige Auswertung, die nie in den Betrieb geht, braucht keine laufende Bewertung, alles andere schon.

*Bezug zu Software Engineering.* Das ist Monitoring und Alerting, angewandt auf die Qualität einer Vorhersage statt auf CPU-Last. Die Qualität des Modells ist ein Service Level Indicator, die Schwelle ein Service Level Objective. Sculley et al. @sculley_hidden_debt_2015 zählen den Umgang mit einer sich ändernden Umwelt und die laufende Überwachung zu den versteckten technischen Schulden von ML-Systemen, und der ML Test Score von Breck et al. @breck_ml_test_score_2017 enthält eine eigene Kategorie von Überwachungstests, unter anderem zu veränderten Eingabeverteilungen und zur Alterung des Modells. Auch das Retraining gehört in die Pipeline: Ein neues Modell wird wie jeder Release geprüft, bevor es das alte ablöst.

#kasten([So erkläre ich es.], [
  „Code ändert sich nur, wenn wir ihn ändern. Ein Modell ist dagegen eingefroren auf dem Stand der Welt, in der es trainiert wurde. Die Welt ändert sich weiter. Deshalb messen wir im Betrieb laufend, wie gut das Modell noch ist, so wie wir Antwortzeiten und Fehlerraten messen.“

  *Verständnisfrage:* Die Eingaben haben sich deutlich verschoben (hoher PSI), die Genauigkeit ist gleich geblieben. Trainieren Sie neu? \
  *Antwort:* Nicht automatisch. Das ist ein virtual drift: Das Modell trifft weiterhin zu, obwohl die Eingaben anders aussehen (im Experiment die Wochen 8 bis 13). Man schaut sich den Alarm an und beobachtet weiter, denn eine Verschiebung kann Vorbote eines echten Drifts sein oder das Modell in Bereiche führen, die es kaum kennt.
])

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 5, Pattern 18); @gama_concept_drift_2014; @sculley_hidden_debt_2015; @breck_ml_test_score_2017.

== Pattern 19: Two-Phase Predictions

*Szenario und Problem.* Ein Smartphone soll handgeschriebene Ziffern erkennen, zum Beispiel beim Ablesen eines Zählerstands. Ein großes Modell in der Cloud erkennt sie sehr zuverlässig, aber jede Anfrage kostet Netzverkehr, Wartezeit und Geld, funktioniert ohne Verbindung nicht und überträgt das Bild an einen Server. Ein kleines Modell auf dem Gerät antwortet sofort und ohne Netz, ist aber ungenauer, weil das Gerät wenig Speicher und Rechenleistung hat. Wir bilden das nach: Das kleine Modell (*Edge*) sieht nur eine auf 4 × 4 Pixel verkleinerte Version des Bildes und rechnet eine logistische Regression, das große (*Cloud*) sieht alle 8 × 8 Pixel und ist eine SVM.

*Die Lösung.* Beide Modelle arbeiten nacheinander. In der ersten Phase antwortet das kleine Modell und gibt zusätzlich an, wie sicher es sich ist, hier als höchste Klassenwahrscheinlichkeit. Liegt die Sicherheit über einem Schwellwert $tau$, ist die Anfrage erledigt. Andernfalls geht sie in der zweiten Phase an das große Modell. Die einfachen Fälle, und das sind die meisten, verlassen das Gerät nie.

#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (25mm, 12mm),
    neben((0, 0), [Anfrage \ #text(size: 8.5pt, fill: grau)[Bild]]),
    knoten((1, 0), [Edge-Modell \ #text(size: 8.5pt, fill: grau)[klein, auf dem Gerät]]),
    knoten((2, 0), [Sicherheit \ $>= tau$ ?], farbe: grau, grund: nebel),
    knoten((3, -0.8), [Antwort vom Gerät \ #text(size: 8.5pt, fill: grau)[schnell, ohne Netz]], farbe: gruen, grund: gruen-hell),
    knoten((3, 0.8), [Cloud-Modell \ #text(size: 8.5pt, fill: grau)[groß, genauer]], farbe: orange, grund: orange-hell),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"),
    edge((2, 0), (3, -0.8), "->", label: [ja], label-side: left),
    edge((2, 0), (3, 0.8), "->", label: [nein], label-side: right),
  )),
  caption: [Zwei-Phasen-Vorhersage: Das Gerät entscheidet, was es selbst beantwortet und was es weiterreicht.],
)

Der Schwellwert steuert den Kompromiss. Das Skript durchläuft mehrere Werte auf den Testdaten und zeigt, welcher Anteil weitergereicht wird und wie genau die kombinierte Vorhersage ist. Die Kernfunktion ist kurz: Das kleine Modell antwortet bei ausreichender Sicherheit, sonst entscheidet das große.

#code-aus("../code/07-resilient-serving/two_phase.py", "def zweiphasig", bis: "print(\"\\nSchwellwert")

#ausgabe("uv run --with scikit-learn --with numpy python two_phase.py", "../code/07-resilient-serving/two_phase.out.txt")

Das Edge-Modell allein erreicht 0,869, das Cloud-Modell 0,980. Bei $tau = "0,5"$ reicht das Gerät nur 33 Prozent der Anfragen weiter und kommt auf 0,949; bei $tau = "0,7"$ sind es 58 Prozent bei 0,978, praktisch die Genauigkeit der Cloud (@abb-two-phase-kurve). Erhöht man $tau$ weiter, steigt der Anteil der weitergereichten Anfragen, die Genauigkeit aber nicht mehr.

#let sweep = json("../code/07-resilient-serving/two_phase_sweep.json")
#figure(
  kind: image,
  text(size: 9pt, canvas(plot.plot(
    size: (10, 4.2), x-label: [Anteil an die Cloud weitergereicht (%)], y-label: [Genauigkeit gesamt],
    x-min: 0, x-max: 100, x-tick-step: 20, y-min: 0.85, y-max: 1.0, y-tick-step: 0.05,
    {
      plot.add(sweep.map(p => (p.at(1) * 100, p.at(2))), mark: "o", mark-size: 0.12, style: (stroke: blau + 1.2pt), mark-style: (fill: blau, stroke: none))
      plot.add-hline(sweep.last().at(2), style: (stroke: (paint: orange, dash: "dashed", thickness: 1pt)))
    },
  ))),
  caption: [Genauigkeit der Zwei-Phasen-Vorhersage gegen den Anteil weitergereichter Anfragen (Testdaten, acht Schwellwerte). Orange gestrichelt: Genauigkeit des Cloud-Modells allein.],
) <abb-two-phase-kurve>


Wichtig ist, wie $tau$ gewählt wird: nicht auf den Testdaten, sondern auf Validierungsdaten, und nach einer Vorgabe, die man begründen kann. Die Testdaten bestätigen das Ergebnis nur noch. Außerdem setzt das Verfahren voraus, dass die Sicherheit des kleinen Modells etwas bedeutet. Dafür müssen die Wahrscheinlichkeiten die Rangfolge der Verlässlichkeit richtig abbilden: Wo das Modell sicherer ist, liegt es öfter richtig. Das Skript prüft das am Ende. Das Edge-Modell ist dabei nicht kalibriert, sondern zu vorsichtig: Bei einer Sicherheit zwischen 0,7 und 0,9 (im Mittel 0,80) liegt es in 99 Prozent der Fälle richtig, nur die Rangfolge stimmt. Für die Wahl von $tau$ genügt das, denn $tau$ wird ohnehin an Daten abgestimmt. Moderne neuronale Netze haben dagegen oft den umgekehrten Fehler und sind zu selbstsicher; ihre Wahrscheinlichkeiten müssen vor der Schwellenwahl kalibriert werden @guo_calibration_2017, sonst entscheidet das Gerät zu viel selbst.

Mit dieser Vorgabe (kleinster Wert, der auf den Validierungsdaten höchstens einen Prozentpunkt unter der Cloud bleibt) ergibt sich $tau = "0,59"$. Auf den Testdaten erreicht das System damit 0,969, und 44,9 Prozent der Anfragen gehen an die Cloud. Unter der Annahme, dass eine Antwort vom Gerät 5 Millisekunden und eine Cloud-Anfrage 120 Millisekunden dauert (angenommene Werte, nicht gemessen), sinkt die mittlere Latenz von 120 auf 59 Millisekunden. Man tauscht gut einen Prozentpunkt Genauigkeit gegen den Wegfall von 55 Prozent der Cloud-Aufrufe.


*Trade-offs und Grenzen.* Man betreibt und versioniert zwei Modelle. Das Modell auf dem Gerät lässt sich nur mit einem App-Update austauschen, das Cloud-Modell jederzeit; die beiden können also auseinanderlaufen. Dieselbe Eingabe kann je nach Netz unterschiedliche Antworten bekommen, weil sie einmal lokal und einmal in der Cloud beantwortet wird. Ausgerechnet die unsicheren Fälle verlassen das Gerät, und das sind oft die interessanten, vielleicht auch die datenschutzrelevanten. Der Schwellwert hängt von der Verteilung der Eingaben ab und muss mit dieser mitwandern (Pattern 18). Die Latenz addiert sich bei weitergereichten Anfragen: erst das Gerät, dann das Netz. Zur Abgrenzung: Cascade (Pattern 8) zerlegt ein fachliches Problem in nacheinander geschaltete Teilprobleme, Two-Phase verteilt dieselbe Aufgabe auf zwei Orte. *Wann nicht:* Wenn die Netzlatenz keine Rolle spielt und die Cloud-Kosten gering sind, genügt das Cloud-Modell allein; und wenn das Gerät nie Netz hat, bleibt nur das kleine Modell.

*Bezug zu Software Engineering.* Das Muster ist ein Fast Path / Slow Path, wie man ihn von Caches kennt: Der schnelle Pfad bedient den Normalfall, der langsame den Rest. Es ist verwandt mit mehrstufigen Caches (L1/L2), und die Rückfallebene bei fehlendem Netz entspricht Graceful Degradation.

#kasten([So erkläre ich es.], [
  „Das ist wie der Empfang eines Hotels: Die meisten Fragen beantwortet er selbst, bei schwierigen holt er den Experten im Hinterzimmer. Wir müssen nur entscheiden, ab wann der Empfang ‚ich bin mir nicht sicher‘ sagt, und diesen Schwellwert wählen wir mit Daten, die nicht zum Testen gedacht sind.“

  *Verständnisfrage:* Warum darf der Schwellwert $tau$ nicht auf den Testdaten gewählt werden? \
  *Antwort:* Dann wäre die berichtete Genauigkeit auf den Testdaten zu optimistisch, weil $tau$ gerade für sie optimiert wurde. Man wählt auf Validierungsdaten und prüft einmal auf den Testdaten.
])

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 5, Pattern 19); @guo_calibration_2017.

== Pattern 20: Keyed Predictions

*Szenario und Problem.* Der Lieferdienst bewertet nachts nicht mehr 200 000, sondern 20 Millionen Bestellungen und verteilt die Arbeit auf viele Rechner. Jeder nimmt ein Stück der Eingabe, bewertet es und liefert seine Vorhersagen zurück. Das Problem liegt in der Reihenfolge: In einem verteilten Job kommt das Ergebnis eines Stücks an, wenn es fertig ist, nicht wenn es an der Reihe wäre. Ein langsamer Knoten, ein wiederholter Versuch oder ungleiche Stückgrößen genügen, und die Ergebnisse treffen in anderer Reihenfolge ein, als die Eingaben abgeschickt wurden. Verlässt man sich darauf, dass die n-te Antwort zur n-ten Frage gehört, ordnet man Vorhersagen stillschweigend falschen Bestellungen zu: keine Fehlermeldung, keine Warnung, nur falsche Ergebnisse.

Das Skript simuliert das mit zwölf Stücken zu je zehn Ziffernbildern. Die Bearbeitungsdauer je Stück ist fest vorgegeben und steht für schwankende Last im Cluster (sie ist keine Messung); die Reihenfolge des Eintreffens weicht dadurch von der Eingangsreihenfolge ab, ist aber reproduzierbar.

*Die Lösung.* Jeder Datensatz bekommt einen eindeutigen *Schlüssel*, der unverändert durch das Modell wandert: Eingang ist (Schlüssel, Features), Ausgang ist (Schlüssel, Vorhersage). Danach spielt die Reihenfolge keine Rolle mehr, die Zuordnung geschieht per Join. Das Modell kennt den Schlüssel nicht, scikit-learn-Modelle erwarten nur Features. Der Schlüssel läuft deshalb neben dem Modell her, wird vor `predict` abgetrennt und danach wieder angefügt; im Skript steckt er als Spalte `schluessel` im DataFrame.

#code-aus("../code/07-resilient-serving/keyed_predictions.py", "# a) ohne Schlüssel")

#ausgabe("uv run --with scikit-learn --with pandas --with numpy \\\n    python keyed_predictions.py", "../code/07-resilient-serving/keyed_predictions.out.txt")

Die Stücke treffen in der Reihenfolge 3, 8, 1, 10, 5, 7, 0, 4, 9, 2, 11, 6 ein. Werden die Vorhersagen in der Ankunftsreihenfolge an die Eingaben geheftet, ist die Genauigkeit 0,117, also Raten bei zehn Klassen, und das Programm meldet keinen Fehler. Mit dem Schlüssel sind es 0,883, die tatsächliche Genauigkeit des Modells auf diesen 120 Bildern.


#figure(
  kind: image,
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (24mm, 11mm),
    neben((0, 1), [Eingabe \ #text(size: 8.5pt, fill: grau)[A, B, C, D]]),
    knoten((1, 0), [Rechner 1 \ #text(size: 8.5pt, fill: grau)[(A, B)]]),
    knoten((1, 2), [Rechner 2 \ #text(size: 8.5pt, fill: grau)[(C, D)]]),
    knoten((2, 1), [Ausgang, beliebige Reihenfolge \ #text(size: 8.5pt, fill: grau)[(C, ?) (A, ?) (D, ?) (B, ?)]], farbe: orange, grund: orange-hell),
    knoten((3, 1), [Join über \ Schlüssel], farbe: gruen, grund: gruen-hell),
    edge((0, 1), (1, 0), "->"), edge((0, 1), (1, 2), "->"),
    edge((1, 0), (2, 1), "->"), edge((1, 2), (2, 1), "->"),
    edge((2, 1), (3, 1), "->"),
  )),
  caption: [Ohne Schlüssel (Reihenfolge) wäre der Ausgang nicht zuzuordnen. Mit Schlüssel stellt der Join die Zuordnung wieder her.],
)

Gute Schlüssel sind eindeutig, stabil und bedeutungslos nach außen: eine laufende Nummer oder eine UUID, die der Client oder der Anfang der Pipeline vergibt. Einen Schlüssel aus den Features abzuleiten (etwa einen Hash) funktioniert nur, solange keine zwei Datensätze dieselben Features haben, und genau das passiert bei kleinen Feature-Räumen ständig. Personenbezogene Angaben wie Namen oder E-Mail-Adressen gehören nicht in den Schlüssel, weil er in Logs und Zwischenspeichern auftaucht.

Der Schlüssel hilft über das Zuordnen hinaus. Mit ihm lassen sich Vorhersagen später mit dem tatsächlichen Ergebnis zusammenführen, was die laufende Bewertung braucht (Pattern 18), und einzelne Vorhersagen lassen sich im Nachhinein nachvollziehen (Pattern 29).

*Trade-offs und Grenzen.* Der Schlüssel kostet etwas zusätzlichen Datenverkehr. Er muss in jedem Schritt des Datenpfads erhalten bleiben, denn jede Transformation, die Zeilen zusammenfasst oder aufteilt, kann ihn verlieren. Wird ein Stück nach einem Fehler wiederholt, kommt es unter Umständen doppelt an. Der Empfänger sollte Duplikate über den Schlüssel erkennen und verwerfen. Bei Online-Diensten mit nur einer Anfrage pro Antwort (Pattern 16) ist der Schlüssel meist unnötig, weil Anfrage und Antwort über die Verbindung zusammengehören; bei Batch-Anfragen mit mehreren Zeilen ist er dagegen Pflicht. *Wann nicht:* In einem einzelnen Prozess, der eine Tabelle in einem Zug bewertet, bleibt die Reihenfolge erhalten. Man sollte sich aber nicht auf diese Eigenschaft verlassen, wenn der Job später verteilt werden könnte.

*Bezug zu Software Engineering.* Das Muster ist die Korrelations-ID aus der Welt der Nachrichtensysteme: Antworten auf eine Anfrage tragen deren Kennung, damit der Absender sie zuordnen kann @hohpe_eip_2003. Dieselbe Idee steckt in der Request-ID, die in verteilten Systemen durch alle Dienste gereicht und in Logs ausgegeben wird, und im Primärschlüssel einer Datenbanktabelle. Wer verteilte Verarbeitung kennt, hat die Regel parat: Eine Reihenfolge besteht in verteilten Systemen nur, wenn man sie ausdrücklich herstellt; Kleppmann behandelt das ausführlich @kleppmann_ddia_2017.

#kasten([So erkläre ich es.], [
  „Wenn zwölf Leute je ein Stück eines Stapels Briefe bearbeiten und die Ergebnisse in der Reihenfolge einsammeln, in der sie fertig werden, stimmt die Reihenfolge nicht mehr. Auf jedem Brief steht deshalb eine Nummer, und auf die Nummer kommt es an, nicht auf den Platz im Stapel.“ Das Experiment aus dem Skript eignet sich gut für die Vorlesung.

  *Verständnisfrage:* Reicht es, die Ergebnisse nach dem Einsammeln einfach nach dem Eingang zu sortieren? \
  *Antwort:* Nur, wenn man weiß, welches Ergebnis zu welcher Eingabe gehört, und dafür braucht man genau den Schlüssel. Ohne ihn ist Sortieren Raten.
])

*Quellen.* @lakshmanan_ml_design_patterns_2020 (Kapitel 5, Pattern 20); @hohpe_eip_2003; @kleppmann_ddia_2017.


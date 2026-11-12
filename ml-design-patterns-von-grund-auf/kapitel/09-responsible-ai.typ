#import "../lib.typ": *

#let code-datei(pfad, von: 1, bis: none) = {
  let z = read(pfad).split("\n")
  raw(z.slice(von - 1, if bis == none { z.len() } else { bis }).join("\n"), lang: "python", block: true)
}
#let lauf(skript, pfad) = raw("$ python " + skript + "\n" + read(pfad).trim("\n", at: end), lang: "terminal", block: true)
#let gruen = rgb("#2EAE7D")
#let orange = rgb("#B5651D")
#let nebenbei(t) = text(size: 8.5pt, fill: grau, t)
#let so-erklaere-ich-es(text-, frage, antwort) = kasten([So erkläre ich es.], [
  #text-
  #v(0.4em)
  *Verständnisfrage:* #frage \
  *Antwort:* #antwort
])

= Responsible AI

Ein Modell kann technisch einwandfrei sein und trotzdem untauglich: weil niemand weiß, ob es mehr leistet als eine einfache Regel, weil sich seine Entscheidungen nicht begründen lassen oder weil es für einen Teil der Betroffenen systematisch schlechter funktioniert. Die drei Patterns dieses Kapitels sind Gegenmittel dafür. Sie sind weniger Techniken als Prüfhaltungen: Ein _Heuristic Benchmark_ gibt der Leistungszahl einen Maßstab, _Explainable Predictions_ macht Entscheidungen nachvollziehbar, und die _Fairness Lens_ prüft Leistung getrennt nach Gruppen. Alle drei lassen sich in der Entwicklung als Test- und Reviewschritt verankern.

Zur Dokumentation solcher Prüfungen hat sich die _Model Card_ etabliert, ein kurzes, standardisiertes Dokument zu einem Modell, das Verwendungszweck, Trainings- und Evaluationsdaten, Kennzahlen (auch aufgeschlüsselt nach Gruppen) und bekannte Grenzen festhält @mitchell_model_cards_2019. Das Pendant für Datensätze sind die _Datasheets for Datasets_ @gebru_datasheets_2021. Die Beispiele dieses Kapitels liegen in `code/09-responsible-ai/` und werden wie in Kapitel 9 mit `uv run --with scikit-learn --with pandas --with numpy python <datei>.py` gestartet; die Daten sind simuliert, damit die richtige Antwort bekannt ist.

== Pattern 28: Heuristic Benchmark

*Szenario.* Ein Lieferdienst sagt die Lieferdauer in Minuten voraus. Das Team trainiert ein Modell und berichtet stolz: mittlerer absoluter Fehler 2,5 Minuten. Die Geschäftsführung fragt: „Ist das gut?“ Ohne Vergleich kann das niemand sagen. 2,5 Minuten wären hervorragend, wenn eine Schätzung ohne Modell um 10 Minuten danebenläge, und enttäuschend, wenn die Disponenten mit einer Faustregel kaum mehr Fehler machen.

*Das Problem.* Eine Fehlerkennzahl allein hat keine Bedeutung, solange es keinen Vergleich gibt. Ohne Vergleich lassen sich drei Dinge nicht beantworten: ob das Modell den Aufwand wert ist (Training, Betrieb, Wartung), ob eine Verbesserung am Modell wirklich etwas bringt, und was man den Fachabteilungen sagen soll. Hinzu kommt eine Gefahr bei der Modellwahl: Ein komplexes Modell kann sich mit einem schlechten Bezugspunkt gut aussehen lassen.

*Die Lösung.* Das Pattern empfiehlt, _vor_ jedem ernsthaften Modell einen einfachen *Vergleichsmaßstab* (_Heuristic Benchmark_) zu bestimmen und das Modell daran zu messen @lakshmanan_ml_design_patterns_2020[Kapitel 7, Pattern 28]. Der Maßstab soll einfach, schnell zu berechnen und für Fachleute nachvollziehbar sein. Typische Kandidaten sind eine Konstante (Mittelwert oder Median der Zielgröße, bei Klassifikation die häufigste Klasse), eine Faustregel von Fachleuten („10 Minuten plus 3 Minuten pro Kilometer“), der Median je Gruppe (je Distanzband) oder ein einfaches lineares Modell. Berichtet wird in der Einheit der Fachabteilung, hier in Minuten, nicht in einer abstrakten Metrik.

#code-datei("../code/09-responsible-ai/28_heuristic_benchmark.py", von: 24, bis: 41)

#lauf("28_heuristic_benchmark.py", "../code/09-responsible-ai/out/28_heuristic_benchmark.txt")

Die Metrik ist der mittlere absolute Fehler (_MAE_) in Minuten, auf denselben Testdaten für alle vier Ansätze. Der Median als Konstante liegt bei 8,14 Minuten, die Faustregel (10 Minuten plus 3 pro Kilometer) bei 4,25, der Median je Distanzband bei 4,50. Das Gradient-Boosting-Modell erreicht 2,50 Minuten, 41 % weniger Fehler als die beste Heuristik. Damit lässt sich der Geschäftsführung etwas sagen: Die Disposition liegt mit ihrer Faustregel im Schnitt 4,3 Minuten daneben, das Modell 2,5. Ob die gewonnenen 1,8 Minuten Entwicklung und Betrieb rechtfertigen, ist jetzt eine Frage, die man diskutieren kann. Beachtenswert ist, dass die Faustregel rund 70 % des Wegs von der Konstante zum Modell zurücklegt; sie ist als Rückfallebene brauchbar, wenn das Modell ausfällt.

#figure(
  diagram(
    node-stroke: 0.7pt + luma(140), node-fill: luma(240), node-corner-radius: 3pt, node-inset: 6pt,
    spacing: (9mm, 6mm),
    {
      node((0, 1.5), [Daten \ #nebenbei[Training / Test]])
      node((1.4, 0), [Konstante \ #nebenbei[Median]])
      node((1.4, 1), [Faustregel \ #nebenbei[Fachwissen]])
      node((1.4, 2), [Gruppenmedian \ #nebenbei[je Distanzband]])
      node((1.4, 3), [*Modell* \ #nebenbei[Gradient Boosting]], fill: blau-hell, stroke: 0.9pt + blau)
      node((3, 1.5), [*Gleiche Testdaten, \ gleiche Metrik (MAE)*], fill: blau-hell, stroke: 0.9pt + blau)
      node((4.7, 1.5), [Entscheidung: \ lohnt sich das Modell?], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      for y in (0, 1, 2, 3) {
        edge((0, 1.5), (1.4, y), "->", stroke: 0.6pt + luma(110))
        edge((1.4, y), (3, 1.5), "->", stroke: 0.6pt + luma(110))
      }
      edge((3, 1.5), (4.7, 1.5), "->")
    },
  ),
  caption: [Das Modell wird nicht für sich, sondern im Vergleich mit einfachen Maßstäben bewertet, auf denselben Testdaten und mit derselben Metrik.],
)

*Trade-offs und Grenzen.* Ein zu schwacher Maßstab (der Mittelwert, wo eine Faustregel existiert) ist ein Strohmann und lässt jedes Modell glänzen; ein sinnvoller Maßstab ist der _beste_ einfache Ansatz, den man mit wenig Aufwand findet. Der Maßstab darf keine Informationen nutzen, die im Betrieb fehlen, und sollte wie das Modell nur aus Trainingsdaten abgeleitet werden; Konstanten der Faustregel dürfen nicht anhand der Testdaten nachjustiert werden. Der Vergleich ist auch nicht das einzige Kriterium: Ein Modell, das nur knapp besser ist, kann trotzdem sinnvoll sein, wenn seine Fehler an wichtigen Stellen kleiner sind, und ein deutlich besseres kann unbrauchbar sein, wenn es nicht erklärbar oder nicht fair ist (Pattern 29 und 30). Bei unausgewogenen Klassen ist die Genauigkeit des Mehrheitsklassen-Maßstabs bereits sehr hoch (Pattern 10).

*Wann nicht:* Es gibt keinen Fall, in dem man den Vergleich weglassen sollte. Sinnlos wird er nur dort, wo kein einfacher Maßstab existiert, etwa bei Bilderkennung ohne bisherigen Ablauf; dann ist der Mensch (oder ein bestehendes System) der Maßstab.

*Bezug zu Software Engineering.* Der Maßstab ist die _Referenzimplementierung_ oder das _Test-Orakel_: Man vergleicht eine komplizierte Lösung mit einer einfachen, deren Korrektheit offensichtlich ist. Dahinter steht das Prinzip _KISS_ (_keep it simple_) und die Frage nach dem Mehrwert des Aufwands, wie sie bei Performance-Regressionstests zur Baseline gestellt wird.

#so-erklaere-ich-es(
  [Ich nenne den Studierenden zuerst nur die Kennzahl des Modells und frage, ob sie gut ist. Nach dem Zögern zeige ich die Ausgabe mit den Maßstäben. Danach geht es um die Frage, welche Aussage man der Geschäftsführung machen würde, wenn das Modell nur knapp besser als die Faustregel ist.],
  [Warum darf man die Konstanten der Faustregel nicht an den Testdaten einstellen?],
  [Dann wäre der Maßstab für genau diese Daten optimiert, und der Vergleich mit dem Modell, das nur Trainingsdaten sah, wäre unfair. Der Maßstab muss wie das Modell ohne Kenntnis der Testdaten entstehen.],
)

*Quellen.* @lakshmanan_ml_design_patterns_2020[Kapitel 7, Pattern 28] @pedregosa_scikit_learn_2011

== Pattern 29: Explainable Predictions

*Szenario.* Eine Bank lehnt einen Kreditantrag ab, auf Empfehlung eines Modells. Die Kundin fragt, warum. Die Sachbearbeiterin sieht nur „Wahrscheinlichkeit Bewilligung: 31 %“. Gleichzeitig will das Entwicklungsteam wissen, ob das Modell sich auf sinnvolle Dinge stützt und nicht auf ein Artefakt der Daten.

*Das Problem.* Die leistungsfähigsten Modelle (große Ensembles, neuronale Netze) sind für Menschen nicht lesbar. Man braucht Erklärungen aus zwei Gründen: um einzelne Entscheidungen zu begründen, gegenüber Betroffenen, Aufsicht und Fachabteilungen, und um das Modell zu _debuggen_, etwa ein Feature zu entdecken, das nur zufällig mit dem Ziel zusammenhängt. Dabei sind zwei Fragen zu unterscheiden. Eine *globale* Erklärung beschreibt, welche Features das Modell insgesamt bestimmen. Eine *lokale* Erklärung beschreibt, warum das Modell für _diesen einen_ Fall so entschieden hat. Beide sind nötig, und sie beantworten verschiedene Fragen.

*Die Lösung.* Das Pattern nutzt *Feature Attribution*: Man verteilt die Vorhersage (oder deren Änderung gegenüber einem Referenzpunkt) auf die Eingabe-Features @lakshmanan_ml_design_patterns_2020[Kapitel 7, Pattern 29]. Die zentrale Idee dahinter ist die *Baseline*, ein Referenzfall, gegen den erklärt wird. Eine lokale Erklärung beantwortet immer nur die Frage, warum die Vorhersage für diesen Fall anders ist als für die Baseline, nicht warum sie einen absoluten Wert hat. Bei tabellarischen Daten ist die Baseline oft der Durchschnittsfall der Trainingsdaten, bei Bildern ein schwarzes Bild. Die Wahl der Baseline ändert die Erklärung.

Die gängigen Verfahren unterscheiden sich in der Idee und im Anwendungsbereich:

#table(
  columns: (auto, auto, 1fr),
  table.header([Verfahren], [Reichweite], [Idee und Grenze]),
  [Permutation Importance], [global],
  [Modellunabhängig. Misst, wie stark die Leistung auf Testdaten sinkt, wenn man die Werte eines Features zufällig durchmischt. Bei korrelierten Features irreführend, siehe unten @breiman_random_forests_2001 @fisher_model_reliance_2019.],
  [LIME], [lokal],
  [Modellunabhängig. Verändert die Eingabe zufällig in der Nachbarschaft des Falls und passt dort ein einfaches lineares Modell an die Antworten des großen Modells an. Hängt von Stichprobe und Nachbarschaftsdefinition ab und kann bei Wiederholung schwanken @ribeiro_lime_2016.],
  [SHAP], [lokal, global],
  [Verteilt die Abweichung der Vorhersage von der Baseline nach den Shapley-Werten der Spieltheorie auf die Features; die Beiträge summieren sich exakt zur Differenz. Die exakte Berechnung braucht alle Teilmengen von Features, daher Näherungen (KernelSHAP) oder Spezialfälle (TreeSHAP für Baummodelle) @lundberg_shap_2017 @lundberg_trees_2020.],
  [Integrated Gradients], [lokal],
  [Für differenzierbare Modelle, vor allem neuronale Netze. Summiert die Gradienten entlang einer Geraden von der Baseline zur Eingabe; die Beiträge ergeben ebenfalls die Differenz zur Baseline. Braucht eine sinnvolle Baseline @sundararajan_integrated_gradients_2017.],
)

Zwei der Verfahren brauchen eine Anschauung. Bei den Shapley-Werten stellt man sich vor, dass die Features nacheinander in den Raum treten, vom Baseline-Fall zum tatsächlichen Antrag. Jedes verändert beim Eintreten die Vorhersage um einen Betrag, und der hängt davon ab, wer schon da ist: Eine hohe Schuldenquote wiegt anders, wenn das Einkommen bereits bekannt ist. Deshalb mittelt man über alle Reihenfolgen, und der Mittelwert ist der Beitrag des Features. Daher kommt der Rechenaufwand, denn bei $n$ Features sind $2^n$ Teilmengen zu betrachten. Integrated Gradients wählt statt aller Reihenfolgen einen einzigen Weg: Die Eingabe wird in vielen kleinen Schritten von der Baseline zum Antrag verschoben, und bei jedem Schritt notiert man, wie steil die Vorhersage in Richtung jedes Features ansteigt. Die Summe dieser Steigungen entlang des Wegs ergibt den Beitrag.

SHAP und Integrated Gradients erfüllen eine nützliche Eigenschaft: Die Beiträge sind *additiv* und summieren sich zur Differenz zwischen Vorhersage und Baseline-Vorhersage (bei Integrated Gradients „Completeness“ genannt, bei Shapley-Werten „Efficiency“). Das lässt sich nachrechnen, und das Beispielprogramm tut es. Es implementiert die Shapley-Werte für fünf Features ohne Bibliothek (alle $2^5$ Teilmengen) und prüft die Implementierung an einem linearen Modell, für das die Formel `coef * (x − baseline)` bekannt ist.

#code-datei("../code/09-responsible-ai/29_explainable.py", von: 50, bis: 62)

#lauf("29_explainable.py", "../code/09-responsible-ai/out/29_explainable.txt")

Der Random Forest erreicht eine Genauigkeit von 0,704 (die Daten sind absichtlich verrauscht). Die _Permutation Importance_ misst den Abfall der AUC auf den Testdaten, wenn ein Feature 20-mal durchmischt wird. Die _AUC_ (Fläche unter der ROC-Kurve) ist die Wahrscheinlichkeit, dass das Modell einen zufällig gewählten bewilligten Antrag höher einstuft als einen abgelehnten; 0,5 entspricht Raten, 1 ist perfekt. Das Einkommen führt mit 0,187, gefolgt von Schuldenquote (0,062) und Beschäftigungsjahren (0,019); Alter und das reine Zufalls-Feature `rauschen` liegen bei null (der leicht negative Wert ist Streuung, die Standardabweichung steht daneben).

Die zweite Tabelle zeigt die Grenze des Verfahrens. Mit einem fast identischen Feature (`einkommen_netto`, 75 % des Einkommens plus Rauschen) sinkt die Wichtigkeit beider auf 0,060 und 0,043, zusammen 0,103 statt 0,187. Das Modell nutzt die Information weiterhin, aber wird eine Spalte durchmischt, springt die andere ein.

Die Shapley-Werte erklären einen einzelnen Antrag. Die Baseline ist der Durchschnittsantragsteller der Trainingsdaten (alle Features auf ihrem Mittelwert); für ihn sagt das Modell 0,559 voraus, für Antrag 0 dagegen 0,528, also −0,031. Das Einkommen dieses Antrags senkt die Wahrscheinlichkeit gegenüber der Baseline um 0,154, die Schuldenquote hebt sie um 0,099, die Beschäftigungsjahre um 0,031. Die Beiträge summieren sich exakt zur Differenz (die Ausgabe prüft das). Dass sich hier zwei große Effekte fast aufheben, sähe man an der Gesamtvorhersage nicht. Die Probe am linearen Modell bestätigt die Implementierung: Dort ist der Shapley-Wert gleich Koeffizient mal Abstand zur Baseline, und die Brute-Force-Rechnung liefert dasselbe.

Integrated Gradients (letzte Zeilen) wurden am logistischen Modell berechnet, weil der Random Forest keine Gradienten hat. Das Verfahren integriert numerisch die Steigung der Vorhersage entlang der Geraden von der Baseline zum Antrag; die Summe der Beiträge entspricht der Differenz der Vorhersagen (−0,0096). Bei einem neuronalen Netz leitet das Framework die Gradienten automatisch ab.

#figure(
  canvas(length: 1cm, {
    import draw: *
    set-style(stroke: 0.7pt + luma(120))
    let ys(v) = (v - 0.38) * 26          // 0.38 .. 0.60 auf 0 .. 5.7 cm
    let namen = ("Baseline", "Einkommen", "Schulden-\nquote", "Beschäft.-\njahre", "Alter", "Rauschen", "Vorhersage")
    let schritte = (0.559, -0.154, 0.099, 0.031, -0.008, 0.001, 0.528)
    let stand = 0.559
    let breite = 1.35
    line((-0.3, ys(0.38)), (14.6, ys(0.38)))
    for i in range(7) {
      let x0 = i * 2.1
      let (unten, oben, farbe, beschr) = if i == 0 {
        (0.38, 0.559, blau, [0,559])
      } else if i == 6 {
        (0.38, 0.528, blau, [0,528])
      } else {
        let w = schritte.at(i)
        let neu = stand + w
        let lo = calc.min(stand, neu)
        let hi = calc.max(stand, neu)
        stand = neu
        (lo, hi, if w >= 0 { gruen } else { orange }, [#(if w >= 0 { "+" } else { "−" })#str(calc.abs(w)).replace(".", ",")])
      }
      rect((x0, ys(unten)), (x0 + breite, ys(oben)), fill: farbe.lighten(35%), stroke: 0.8pt + farbe)
      content((x0 + breite / 2, ys(oben) + 0.28), text(size: 8.5pt, beschr))
      content((x0 + breite / 2, -0.15), text(size: 8.5pt, align(center, namen.at(i))), anchor: "north")
    }
    // Hinweislinien zwischen den Balken
    line((breite, ys(0.559)), (2.1, ys(0.559)), stroke: (dash: "dotted", paint: luma(150), thickness: 0.6pt))
  }),
  caption: [Beiträge der Features zur Vorhersage für Antrag 0 (Random Forest), als Wasserfall von der Baseline (0,559) zur Vorhersage (0,528). Die Werte stammen aus der Ausgabe oben; die senkrechte Achse beginnt bei 0,38, nicht bei 0. Die Reihenfolge der Balken ist nur Darstellung, die Shapley-Werte selbst hängen nicht von ihr ab.],
)

*Grenzen.* Eine Erklärung beschreibt, wie sich das _Modell_ verhält, nicht, wie die Welt funktioniert. Dass „Einkommen“ den Antrag positiv beeinflusst, heißt nicht, dass eine Gehaltserhöhung die Kreditwürdigkeit kausal erhöht. Erklärungen hängen von der Baseline ab, sind bei korrelierten Features mehrdeutig (die Ausgabe zeigt, wie sich die Wichtigkeit auf zwei Spalten verteilt) und können täuschen: #cite(<adebayo_sanity_2018>, form: "prose") zeigen, dass manche populäre Bildattributionen sich kaum ändern, wenn man die Gewichte des Modells zufällig setzt. #cite(<rudin_stop_explaining_2019>, form: "prose") argumentiert für Entscheidungen mit hohem Einsatz, von vornherein interpretierbare Modelle zu bauen, statt undurchsichtige Modelle nachträglich zu erklären. *Wann nicht:* Wenn ein einfaches Modell (lineare Regression, flacher Entscheidungsbaum) genügt, ist es selbst die Erklärung.

*Bezug zu Software Engineering.* Erklärbarkeit entspricht _Observability_ und _Debuggability_: Man fragt nach dem Grund für ein Ergebnis, wie man bei einem Programm einen Stacktrace oder Log braucht. Die Baseline entspricht dem Referenzlauf, mit dem man einen fehlerhaften Lauf vergleicht (Differential Debugging). In Bereichen wie der Kreditvergabe kommen Anforderungen an die Begründbarkeit automatisierter Entscheidungen hinzu; deren genauen Umfang klärt die Rechtsabteilung.

#so-erklaere-ich-es(
  [Ich zeige den Studierenden eine Waage mit einem Startgewicht (Baseline) und fünf Gewichten, die darauf gelegt werden (Features). Die Erklärung ist die Liste der Gewichte und ihrer Wirkung, die Summe ergibt das Endgewicht. Dann frage ich, was sich ändert, wenn das Startgewicht ein anderes ist.],
  [Warum zeigt die Permutation Importance bei zwei fast gleichen Features für jedes nur einen kleinen Wert?],
  [Wird eines durchmischt, kann das Modell sich auf das andere stützen, und die Leistung sinkt kaum. Die Wichtigkeit verteilt sich auf beide, obwohl die Information für das Modell sehr wichtig ist.],
)

*Quellen.* @lakshmanan_ml_design_patterns_2020[Kapitel 7, Pattern 29] @ribeiro_lime_2016 @lundberg_shap_2017 @lundberg_trees_2020 @sundararajan_integrated_gradients_2017 @shapley_value_1953 @breiman_random_forests_2001 @fisher_model_reliance_2019 @adebayo_sanity_2018 @rudin_stop_explaining_2019

== Pattern 30: Fairness Lens

*Szenario.* Dasselbe Kreditmodell, nun mit einer Gruppenzugehörigkeit A oder B, die nicht Teil der Eingaben ist. Die Gesamtgenauigkeit ist gut. Eine Auswertung nach Gruppen zeigt jedoch, dass kreditwürdige Antragsteller aus Gruppe B seltener bewilligt werden als gleich kreditwürdige aus Gruppe A.

*Das Problem.* Zusammenfassende Kennzahlen verbergen Unterschiede: Ein Modell kann im Durchschnitt gut und für einzelne Gruppen deutlich schlechter sein. Die Ursachen liegen selten im Algorithmus, meist in Daten und Umfeld:

- *Stichprobenverzerrung.* Eine Gruppe ist unterrepräsentiert, das Modell lernt ihre Muster schlechter. #cite(<buolamwini_gender_shades_2018>, form: "prose") fanden bei drei kommerziellen Systemen zur Geschlechtsklassifikation aus Gesichtsbildern deutlich höhere Fehlerraten für Frauen mit dunkler Hautfarbe; sie verweisen unter anderem auf gängige Benchmark-Datensätze, in denen hellhäutige Personen überwiegen.
- *Label-Verzerrung.* Die Zielgröße ist selbst verzerrt oder ein schlechter Ersatz für das, was man messen will. #cite(<obermeyer_dissecting_2019>, form: "prose") zeigten, dass ein Algorithmus im US-Gesundheitswesen Gesundheitskosten als Ersatz für Krankheitslast verwendete und dadurch Schwarze Patientinnen und Patienten bei gleichem Bedarf benachteiligte. Im Beispiel sind es historische Entscheidungen: Kreditwürdige Antragsteller aus B wurden seltener bewilligt, und das Modell lernt das als „Wahrheit“.
- *Stellvertreter-Features (Proxies).* Das Modell kann die Gruppe auch ohne Eingabe rekonstruieren, etwa über Postleitzahl oder Einkommen; sie wegzulassen („Fairness durch Nichtwissen“) schützt deshalb nicht.
- *Rückkopplung.* Entscheidungen verändern die Daten, aus denen später gelernt wird.

*Die Lösung.* Das Pattern ist eine Prüfpraxis @lakshmanan_ml_design_patterns_2020[Kapitel 7, Pattern 30]: Man wertet das Modell nicht nur insgesamt, sondern _je Gruppe_ aus, zieht passende Fairness-Kennzahlen heran und greift bei Bedarf ein. Die gängigen Kennzahlen betreffen verschiedene Fragen:

- *Demographic Parity*: Die Bewilligungsrate (Anteil positiver Vorhersagen) ist in allen Gruppen gleich.
- *Equal Opportunity* @hardt_equality_of_opportunity_2016: Die _True Positive Rate_ ist in allen Gruppen gleich, also der Anteil der tatsächlich Kreditwürdigen, die auch bewilligt werden. Wer es verdient, soll unabhängig von der Gruppe dieselbe Chance haben.
- *Equalized Odds*: Zusätzlich ist die _False Positive Rate_ gleich (der Anteil nicht Kreditwürdiger, die trotzdem bewilligt werden).
- *Predictive Parity*: Eine bewilligte Person ist in allen Gruppen mit gleicher Wahrscheinlichkeit kreditwürdig (gleiche Precision). Die verwandte *Kalibrierung* verlangt dasselbe für jeden Wert des Scores: Eine Vorhersage von 70 % bedeutet in jeder Gruppe, dass etwa 70 % zurückzahlen.

Diese Kriterien sind im Allgemeinen nicht gleichzeitig erfüllbar: Unterscheiden sich die Grundraten zwischen den Gruppen, lassen sich Kalibrierung (Kleinberg et al.) beziehungsweise Predictive Parity (Chouldechova) und gleiche Fehlerraten nur im Sonderfall einer perfekten Vorhersage vereinbaren @kleinberg_inherent_2016 @chouldechova_fair_prediction_2017. Welche Kennzahl angemessen ist, ist eine Entscheidung über den Anwendungsfall, kein technisches Detail. Das Beispiel stellt die True Positive Rate in den Mittelpunkt. Das Modell hat die Gruppe nie als Eingabe; die Tabellenfunktion wertet die Vorhersagen anschließend je Gruppe aus (der Datenaufbau steht in der Datei):

#code-datei("../code/09-responsible-ai/30_fairness_lens.py", von: 35, bis: 51)

#lauf("30_fairness_lens.py", "../code/09-responsible-ai/out/30_fairness_lens.txt")

Bei einem einheitlichen Schwellwert von 0,5 liegt die True Positive Rate in Gruppe A bei 0,708 und in Gruppe B bei 0,515: Von den tatsächlich Kreditwürdigen werden in A rund 71 % bewilligt, in B rund 52 %. Die Bewilligungsrate beträgt 53 % gegenüber 33 %. Die Differenz der True Positive Rates ist 0,192. Das Modell hat die Gruppe nie als Eingabe gesehen; der Unterschied entsteht über das Einkommen, das in der Simulation in Gruppe B niedriger ist, und über die verzerrten historischen Labels. Aus der Ausgabe allein lässt sich beides nicht trennen; dafür bräuchte man zusätzliche Auswertungen. Die letzten Zeilen zeigen dieselben Kennzahlen von Fairlearns `MetricFrame` zur Kontrolle.

*Eingriffsmöglichkeiten.* Man kann vor, während oder nach dem Training eingreifen: Daten ausgleichen oder neu gewichten (_Pre-Processing_), die Fairness-Bedingung in die Optimierung aufnehmen (_In-Processing_), oder die Entscheidungsschwelle je Gruppe anpassen (_Post-Processing_). #cite(<hardt_equality_of_opportunity_2016>, form: "prose") zeigen das Letztere für Equal Opportunity und Equalized Odds. Das Beispiel wählt je Gruppe eine Schwelle so, dass die True Positive Rate gleich ist (Gruppe A behält 0,5, für B wird die Schwelle aus den Vorhersagen der tatsächlich kreditwürdigen B-Antragsteller bestimmt). Zur Vereinfachung geschieht das auf denselben Testdaten, mit denen anschließend ausgewertet wird; die ausgewiesene Gleichheit ist deshalb optimistisch. In der Praxis legt man die Schwelle auf getrennten Validierungsdaten fest und prüft sie dann auf den Testdaten (dieselbe Regel wie beim Heuristic Benchmark). Mit einer Schwelle von 0,36 für Gruppe B sind die True Positive Rates praktisch gleich (0,708 und 0,707). Der Eingriff hat einen Preis, den die Tabelle sichtbar macht: In Gruppe B steigt die False Positive Rate von 0,191 auf 0,361, die Precision sinkt von 0,657 auf 0,582, es werden also mehr nicht Kreditwürdige bewilligt. Gleiche Chancen für die Kreditwürdigen kosten höheres Ausfallrisiko in einer Gruppe; ob das vertretbar ist, entscheiden die Fachabteilung und das Recht, nicht der Code. Rechtlich ist eine Behandlung nach Gruppenzugehörigkeit je nach Kontext heikel; das Handbuch gibt keine Rechtsauskunft.

#figure(
  canvas(length: 1cm, {
    import draw: *
    set-style(stroke: 0.7pt + luma(120))
    let ys(v) = v * 4.2                        // 0 .. 0.8 auf 0 .. 3.4 cm
    let tafel(x0, titel, werte) = {
      content((x0 + 3.4, 4.1), text(size: 9pt, weight: "bold", titel))
      line((x0, 0), (x0 + 6.9, 0))
      for (gi, g) in werte.enumerate() {
        let gx = x0 + 0.3 + gi * 2.3
        for (bi, (v, farbe)) in g.at(1).enumerate() {
          let bx = gx + bi * 0.9
          rect((bx, 0), (bx + 0.8, ys(v)), fill: farbe.lighten(35%), stroke: 0.8pt + farbe)
          content((bx + 0.4, ys(v) + 0.25), text(size: 8.5pt, str(v).replace(".", ",")))
        }
        content((gx + 0.85, -0.15), text(size: 8.5pt, g.at(0)), anchor: "north")
      }
    }
    let a = luma(110)
    let b = orange
    tafel(0, [Ein Schwellwert 0,5], (
      ([Bewilligung], ((0.531, a), (0.326, b))),
      ([TPR], ((0.708, a), (0.515, b))),
      ([FPR], ((0.322, a), (0.191, b))),
    ))
    tafel(8.2, [Schwelle je Gruppe (A 0,50 · B 0,36)], (
      ([Bewilligung], ((0.531, a), (0.504, b))),
      ([TPR], ((0.708, a), (0.707, b))),
      ([FPR], ((0.322, a), (0.361, b))),
    ))
    rect((5.2, -1.4), (5.55, -1.1), fill: a.lighten(35%), stroke: 0.8pt + a)
    content((5.7, -1.25), text(size: 8.5pt, [Gruppe A]), anchor: "west")
    rect((8.0, -1.4), (8.35, -1.1), fill: b.lighten(35%), stroke: 0.8pt + b)
    content((8.5, -1.25), text(size: 8.5pt, [Gruppe B]), anchor: "west")
  }),
  caption: [Bewilligungsrate, True Positive Rate (TPR) und False Positive Rate (FPR) je Gruppe, links mit einem einheitlichen Schwellwert, rechts mit gruppenspezifischen Schwellen. Werte aus der Ausgabe oben.],
)

*Werkzeuge.* Fairlearn bietet `MetricFrame` für Kennzahlen je Gruppe und Verfahren zum Abmildern, darunter `ThresholdOptimizer` für Post-Processing @bird_fairlearn_2020; das Beispiel gibt zur Kontrolle die Kennzahlen von `MetricFrame` aus (Fairlearn 0.15). Das _What-If Tool_ ist eine interaktive Oberfläche, in der man Datenpunkte verändert, Modelle auf Teilgruppen vergleicht und Schwellen im Hinblick auf Fairness-Kriterien einstellt @wexler_what_if_2020. Ähnliche Werkzeuge sind TensorFlow Fairness Indicators und IBM AI Fairness 360.

*Trade-offs und Grenzen.* Fairness-Kennzahlen setzen voraus, dass man die Gruppenzugehörigkeit kennt, deren Erhebung selbst rechtlich und ethisch beschränkt sein kann. Das Beispiel nutzt die tatsächliche Rückzahlung als Referenz; für abgelehnte Antragsteller gibt es sie in der Praxis nie (das Problem der _selektiven Labels_). Kleine Gruppen haben unsichere Kennzahlen, überschneidende Gruppen (etwa Geschlecht und Alter) muss man auch gemeinsam betrachten, und keine Kennzahl ersetzt die Entscheidung, was in der Anwendung gerecht ist. *Wann nicht:* Bei Modellen ohne Personenbezug (Maschinenprognosen) entfällt es; wo Modelle Menschen betreffen, gehört es dazu.

*Bezug zu Software Engineering.* Es ist dieselbe Denkweise wie bei _Testabdeckung_ und _Äquivalenzklassen_: Ein Durchschnitt kann stimmen, während eine Klasse von Eingaben versagt. Gruppenmetriken sind Tests je Äquivalenzklasse. Die Model Card ist das Gegenstück zur API-Dokumentation mit bekannten Einschränkungen.

#so-erklaere-ich-es(
  [Ich zeige zuerst nur die Gesamtgenauigkeit und lasse sie gut finden, dann die Tabelle nach Gruppen. Anschließend frage ich, wo der Fehler liegt: im Algorithmus, in den Daten oder in der Welt, aus der die Daten stammen. Die Diskussion über die Kriterien beginnt mit der Frage, wessen Fehler schwerer wiegt, ein zu Unrecht abgelehnter oder ein zu Unrecht bewilligter Antrag.],
  [Warum genügt es nicht, die Gruppenzugehörigkeit als Eingabe wegzulassen?],
  [Das Modell kann sie über Stellvertreter-Features wie Einkommen oder Wohnort rekonstruieren, und die Muster in den historischen Labels bleiben erhalten. Weglassen verhindert nur, dass man den Effekt _sieht_.],
)

*Quellen.* @lakshmanan_ml_design_patterns_2020[Kapitel 7, Pattern 30] @hardt_equality_of_opportunity_2016 @mitchell_model_cards_2019 @kleinberg_inherent_2016 @chouldechova_fair_prediction_2017 @buolamwini_gender_shades_2018 @obermeyer_dissecting_2019 @bird_fairlearn_2020 @wexler_what_if_2020 @barocas_fairness_ml_2023

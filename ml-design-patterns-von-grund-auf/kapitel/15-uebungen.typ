#import "../lib.typ": *
#import "@preview/cetz-plot:0.1.2": plot

// ---------------------------------------------------------------------------------------------
// Lokale Hilfen. Code und Ausgaben stammen aus code/15/, damit das Kapitel zeigt, was dort lief.
// ---------------------------------------------------------------------------------------------
#let gruen = rgb("#2EAE7D")
#let orange = rgb("#B5651D")
#let gruen-hell = rgb("#E5F5EE")
#let orange-hell = rgb("#FBF1E6")
#let lila = rgb("#7A4FA3")

#let code-aus(datei, ab, bis: none) = {
  let t = read("../code/15/" + datei)
  let rest = t.slice(t.position(ab))
  let ende = if bis == none { rest.len() } else { rest.position(bis) }
  raw(rest.slice(0, ende).trim("\n", at: end), lang: "python", block: true)
}
// Ausschnitt einer Ausgabedatei von der Zeile `ab` bis vor die Zeile `bis`
#let ausgabe(datei, befehl, ab: none, bis: none) = {
  let t = read("../code/15/ausgabe/" + datei)
  if ab != none { t = t.slice(t.position(ab)) }
  if bis != none { t = t.slice(0, t.position(bis)) }
  raw("$ " + befehl + "\n" + t.trim("\n", at: end), lang: "terminal", block: true)
}
#let daten-plot(..args) = block(width: 100%, align(center, text(size: 9pt, canvas(length: 1cm, {
  draw.set-style(axes: (stroke: 0.6pt, tick: (stroke: 0.5pt)))
  plot.plot(..args)
}))))

// Schwierigkeit: ★ bis ★★★
#let sterne(n) = box(text(size: 9.5pt)[#text(fill: orange)[#("★" * n)]#text(fill: luma(205))[#("★" * (3 - n))]])

// Kopfzeile jeder Aufgabe: Kennung, Titel, Art und Pattern, Schwierigkeit; am Ende der Verweis auf die Lösung
#let aufgabe(id, titel, n, art, pat, body) = [#block(width: 100%, above: 1.0em, below: 0.7em, breakable: false)[
  #grid(columns: (auto, 1fr, auto), column-gutter: 7pt, align: horizon,
    box(fill: blau, radius: 2pt, inset: (x: 5pt, y: 3pt), text(fill: white, weight: "bold", size: 9.5pt, upper(id))),
    [*#titel* #h(0.35em) #text(size: 8.5pt, fill: grau)[#art · #pat]],
    sterne(n))
  #v(0.15em)
  #body
  #v(-0.35em)
  #align(right, text(size: 8.5pt, fill: blau, link(label("loes-" + id))[Lösung auf Seite #context counter(page).at(label("loes-" + id)).first()]))
]#label("aufg-" + id)]

#let loesung(id, body) = [#block(width: 100%, above: 1.1em, below: 0.8em)[
  #block(sticky: true, below: 0.4em)[
    #box(fill: gruen, radius: 2pt, inset: (x: 5pt, y: 3pt), text(fill: white, weight: "bold", size: 9.5pt, upper(id)))
    #h(0.4em)
    #text(size: 8.5pt, fill: blau, link(label("aufg-" + id))[Aufgabe auf Seite #context counter(page).at(label("aufg-" + id)).first()])
  ]
  #body
]#label("loes-" + id)]

#let verweis(id) = align(right, text(size: 8.5pt, fill: blau, link(label("loes-" + id))[Lösung auf Seite #context counter(page).at(label("loes-" + id)).first()]))

// Teilaufgaben (a), (b), ...
#let teile(..xs) = enum(numbering: "(a)", tight: true, indent: 0em, body-indent: 0.55em, spacing: 0.55em, ..xs.pos())

#let stufe-fall(body) = text(size: 8.5pt, fill: grau, body)

// Kapitelweit etwas kompakter, weil das Kapitel ein Aufgabenfundus ist
#set text(size: 10pt)
#set par(leading: 0.6em, spacing: 0.9em)

= Übungen mit Lösungen

Wer ein Pattern erklären kann, kann es noch nicht unbedingt anwenden. Dieses Kapitel prüft den zweiten Schritt: Es beschreibt Symptome, wie sie in Projekten auftreten, verlangt Zahlen, wie man sie bei der Planung ausrechnen muss, und lässt kleine Experimente nachbauen, an denen eine Behauptung stimmt oder nicht stimmt. Es dient der Selbstkontrolle während des Lesens und als Fundus für Übungsblätter, Quizfragen und Prüfungsaufgaben in der Lehrveranstaltung.

#kasten([Lernziele.], [Nach der Arbeit mit diesem Kapitel können Sie zu einem beschriebenen Symptom das passende Pattern nennen, begründen, warum es passt, und eine Alternative abgrenzen. Sie können die Rechnungen ausführen, die bei den Patterns immer wieder anfallen: Kollisionswahrscheinlichkeit beim Hashing, Precision und Recall aus einer Konfusionsmatrix, den Anteil der Anfragen in der zweiten Phase, die Stichprobengröße für eine Überwachung. Und Sie können ein Experiment so aufsetzen, dass es eine Aussage über ein Pattern wirklich prüft.])

== So arbeiten Sie mit diesem Kapitel

Die Aufgaben folgen den sechs Kategorien des Buchs von #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose") und tragen eine Kennung: *D* für Data Representation, *P* für Problem Representation, *T* für Model Training, *S* für Resilient Serving, *R* für Reproducibility, *V* für Verantwortung (Responsible AI) und *K* für die Szenarien über mehrere Kategorien. Die Kopfzeile nennt Art (Verständnis, Diagnose, Rechnen, Code) und Pattern. Der Schwierigkeitsgrad ist mit Sternen markiert: ★ verlangt, eine Definition anzuwenden; ★★ eine Rechnung oder Diagnose in zwei bis drei Schritten; ★★★ verbindet mehrere Konzepte, verlangt eine Herleitung oder ein eigenes Experiment. Hinter jeder Aufgabe steht ein Verweis auf die Lösung und umgekehrt. Versuchen Sie die Aufgabe zuerst ohne Blick auf die Lösung; bei Diagnoseaufgaben lohnt es sich, die Antwort aufzuschreiben, bevor man sie vergleicht.

In Rechen- und Szenarioaufgaben sind die Eingangswerte *Annahmen der Aufgabe* (Preise, Latenzen, Datenmengen), nirgends gemessen. Wo eine Zahl aus einem Lauf stammt, steht das dabei; sie kommt aus den Skripten in `code/15/` (`01_darstellung.py` für D, `02_problem.py` für P, `03_training.py` für T, `04_serving.py` für S, `05_reproduzierbarkeit.py` für R, `06_verantwortung.py` für V, `07_szenarien.py` für K). Sie laufen mit `uv run --with scikit-learn --with pandas --with numpy python <datei>`, die Ausgaben liegen in `code/15/ausgabe/`, und `08_pruefung.py` rechnet die übrigen Zahlen des Kapitels nach.

== Data Representation (Patterns 1 bis 4)

#aufgabe("d1", [Cold Start], 1, "Verständnis", [Hashed Feature])[
  Ein Shop führt täglich neue Produkte ein. Mit One-Hot-Kodierung der Produkt-ID wirft der Encoder bei jeder unbekannten ID einen Fehler, mit einem Hashed Feature läuft der Service weiter. #teile(
    [Warum hilft Hashing beim Cold Start technisch?],
    [Warum löst es das Cold-Start-Problem fachlich nicht?],
    [Nennen Sie zwei weitere Dinge, die Hashing nicht leistet.],
  )
]

#aufgabe("d2", [Kollisionen rechnen], 2, "Rechnen und Code", [Hashed Feature])[
  Ein Shop hat $n = "20 000"$ Produkt-IDs und hasht sie auf $B = "50 000"$ Buckets. Ein bestimmter Wert teilt seinen Bucket mit mindestens einem anderen mit der Wahrscheinlichkeit $1 - (1 - 1/B)^(n-1)$; die erwartete Zahl belegter Buckets ist $B (1 - (1 - 1/B)^n)$.
  #teile(
    [Welcher Anteil der IDs kollidiert, und wie viele Buckets sind belegt?],
    [Wie groß muss $B$ mindestens sein, damit höchstens 5 % der IDs kollidieren?],
    [Prüfen Sie beide Rechnungen mit `murmurhash3_32` aus scikit-learn.],
  )
]

#aufgabe("d3", [Zellen zählen], 2, "Rechnen", [Feature Cross])[
  Ein Verkehrsdienst hat 1 000 000 Fahrten und die Features Wochentag (7 Werte), Stunde (24) und Bezirk (23).
  #teile(
    [Wie viele Zellen entstehen, wenn man alle drei kreuzt, und wie viele Fahrten fallen im Mittel in eine Zelle? Wie ist es bei Wochentag × Stunde?],
    [Nennen Sie drei Wege, die Zahl der Zellen zu begrenzen, ohne auf die Wechselwirkung zu verzichten.],
  )
]

#aufgabe("d4", [Quadranten], 3, "Code", [Feature Cross])[
  Punkte $(x, y)$ liegen gleichverteilt in $[-1, 1]^2$. Das Label ist 1, wenn $x dot y > 0$, bei 5 % der Punkte ist es vertauscht.
  #teile(
    [Suchen Sie per Raster die beste Gerade auf den Rohwerten. Welche Genauigkeit erreicht sie?],
    [Zerlegen Sie $x$ und $y$ in je vier Buckets (Grenzen $-"0,5"$; $0$; $"0,5"$) und trainieren Sie eine logistische Regression, einmal mit den Buckets einzeln, einmal mit deren Kreuzprodukt. Welche Genauigkeit ist höchstens möglich?],
    [Erreicht ein Entscheidungsbaum ohne Cross das Ergebnis des Crosses?],
  )
]

#aufgabe("d5", [Embedding-Tabelle], 2, "Rechnen", [Embeddings])[
  Eine Musik-App hat 4 000 000 Titel. #teile(
    [Welche Dimension schlägt die Faustregel "vierte Wurzel der Kategorienzahl" vor?],
    [Wie groß ist die Embedding-Tabelle in Megabyte (float32)? Wie groß, wenn man die Titel vorher auf 500 000 Buckets hasht?],
    [Welche Titel leiden unter dem Hashing am meisten?],
  )
]

#aufgabe("d6", [Fehlendes Foto], 2, "Diagnose", [Multimodal Input])[
  Ein Versicherungsmodell nutzt Schadenshöhe, Beschreibung und Foto. Im Training hat jede Meldung ein Foto. Im Betrieb fehlt es bei 30 % der Meldungen; die Pipeline setzt die Pixelwerte dann auf null. Das Modell meldet auffällig oft Totalschaden. #teile(
    [Wie heißt das Phänomen, und warum tritt es auf?],
    [Nennen Sie zwei Gegenmaßnahmen.],
    [Das Foto liefert 10 000 standardisierte Pixelwerte, die Tabelle 5. Wie verhalten sich die Längen der beiden Teilvektoren, und was bedeutet das für abstandsbasierte Verfahren?],
  )
]

== Problem Representation (Patterns 5 bis 10)

#aufgabe("p1", [Der Mittelwert, der nie vorkommt], 1, "Verständnis", [Reframing])[
  Ein Lieferdienst sagt die Lieferzeit mit einem Regressionsmodell voraus, das den quadratischen Fehler minimiert. Die Zeiten sind zweigipflig: 20 Minuten bei freier Küche, 60 bei überlasteter, jeweils in der Hälfte der Fälle, und aus den Eingaben ist nicht erkennbar, welcher Fall vorliegt.
  #teile(
    [Welche Zeit sagt das Modell voraus, und warum ist das ein Problem?],
    [Wie hilft es, die Aufgabe als Klassifikation über Zeitklassen zu formulieren?],
    [Geben Sie ein Beispiel für die umgekehrte Richtung (Klassifikation als Regression).],
  )
]

#aufgabe("p2", [Mehrere Tags], 2, "Rechnen", [Multilabel])[
  Ein Netz soll Artikel mit mehreren Tags versehen. Für die Tags A bis D liefert es die Logits $("2,2"; "1,9"; -"0,5"; -"2,0")$.
  #teile(
    [Berechnen Sie die Ausgaben mit Softmax und mit Sigmoid.],
    [Welche Tags vergeben Sie jeweils bei der Schwelle 0,5?],
    [Warum ist Softmax für Multilabel ungeeignet? Welche Fehlerfunktion gehört zur Sigmoid-Ausgabe?],
  )
]

#aufgabe("p3", [Mehrheitsentscheid], 2, "Rechnen", [Ensembles])[
  Drei Klassifikatoren sind jeweils zu 70 % richtig und machen unabhängige Fehler.
  #teile(
    [Wie genau ist die Mehrheitsentscheidung bei 3 und bei 5 Modellen?],
    [Warum bleibt der Gewinn in der Praxis hinter der Rechnung zurück?],
    [Wofür stehen Bagging, Boosting und Stacking jeweils in einem Satz?],
  )
]

#aufgabe("p4", [Cascade durchrechnen], 2, "Rechnen", [Cascade])[
  Eine Bank prüft 100 000 Zahlungen am Tag, 1 % sind Betrug. Stufe 1 (billige Merkmale) lässt 8 % aller Zahlungen durch und enthält darunter 96 % der Betrugsfälle. Stufe 2 benötigt teure Abfragen (0,4 Cent je Zahlung), erkennt 90 % der durchgelassenen Betrugsfälle und markiert 1 % der durchgelassenen harmlosen Zahlungen fälschlich.
  #teile(
    [Was kosten die teuren Abfragen mit und ohne Cascade?],
    [Wie hoch sind Gesamt-Recall und Precision?],
    [Welchen Recall braucht Stufe 1, damit der Gesamt-Recall mindestens 0,88 beträgt?],
  )
]

#aufgabe("p5", [Zwei Schwellen], 2, "Rechnen", [Rebalancing])[
  Dasselbe Betrugsmodell wird mit zwei Schwellen auf 10 000 Zahlungen (100 Betrugsfälle) bewertet. Schwelle A: 80 Treffer, 40 Fehlalarme, 20 übersehene Fälle. Schwelle B: 90 Treffer, 150 Fehlalarme, 10 übersehene Fälle. Ein übersehener Betrug kostet 200 Euro, ein Fehlalarm 5 Euro.
  #teile(
    [Berechnen Sie Genauigkeit, Precision, Recall und F1 für beide Schwellen. Wie gut ist die Regel "nie Betrug"?],
    [Berechnen Sie die Kosten. Welche Schwelle wählen Sie, und was folgt für die Rolle von F1?],
  )
]

#aufgabe("p6", [Uneinige Labeler], 2, "Diagnose und Rechnen", [Neutral Class])[
  Ein Team labelt Rezensionen mit drei Personen und nimmt die Mehrheit als Label. Bei einer Rezension an der Grenze sagt jede Person unabhängig mit Wahrscheinlichkeit 0,55 "positiv". #teile(
    [Wie wahrscheinlich ist das Mehrheitslabel "positiv", wie wahrscheinlich sind sich alle drei einig?],
    [Welche Folgen hat das für das Training? Welches Pattern setzen Sie ein, welche Alternative gibt es, und wann nutzt beides nichts?],
  )
]

#aufgabe("p7", [Undersampling und Wahrscheinlichkeit], 3, "Rechnen und Code", [Rebalancing])[
  Von 50 000 Kunden wandern 1 000 ab (2 %).
  #teile(
    [Welche Genauigkeit hat die Regel "wandert nie ab"?],
    [Welche Gewichte vergibt `class_weight="balanced"`?],
    [Man behält alle Abwanderer und nur 10 000 der Bleibenden (Faktor $beta$). Das Modell gibt 0,5 aus. Welche Wahrscheinlichkeit gilt für die echte Kundschaft? Leiten Sie die Korrektur über die Odds her.],
    [Prüfen Sie die Korrektur an einer Simulation.],
  )
]

== Model Training (Patterns 11 bis 15)

#aufgabe("t1", [Overfitting als Ziel], 1, "Verständnis", [Useful Overfitting])[
  Ein Kollege will für die Kundenabwanderung "Useful Overfitting" einsetzen, weil das Pattern sage, Overfitting sei gut. Was antworten Sie? Nennen Sie die Bedingungen, unter denen das Pattern gilt, und ein Beispiel, das sie erfüllt.
]

#aufgabe("t2", [Checkpoint-Intervall], 3, "Rechnen und Code", [Checkpoints])[
  Ein Training braucht 60 Stunden Rechenzeit auf einer Instanz, die der Anbieter jederzeit entziehen darf (im Mittel alle 20 Stunden). Ein Checkpoint kostet 3 Minuten ($delta = "0,05"$ h). Bei Stunde 41 fällt die Instanz aus.
  #teile(
    [Wie viel Arbeit geht verloren ohne Checkpoint, wie viel mit einem Checkpoint alle 2 Stunden?],
    [Wie viel Zeit kostet das Schreiben bei Intervallen von 2 Stunden und von 30 Minuten?],
    [Pro Intervall $T$ fallen $delta$ an, pro Ausfall gehen im Mittel $T slash 2$ Arbeit verloren. Bestimmen Sie das Intervall mit dem kleinsten Gesamtaufwand.],
    [Prüfen Sie die Näherung durch Simulation.],
  )
]

#aufgabe("t3", [Falsch feinjustiert], 2, "Diagnose", [Transfer Learning])[
  Ein Team hat 300 beschriftete Röntgenbilder. Es nimmt ein auf Alltagsfotos vortrainiertes Netz, trainiert alle Schichten mit der Lernrate 0,1 und ist schlechter als ein kleines Netz von Grund auf. #teile(
    [Was ist die wahrscheinlichste Ursache?],
    [Welche zwei Varianten kennt das Pattern?],
    [Welche wählen Sie bei 300, welche bei 30 000 Bildern?],
  )
]

#aufgabe("t4", [Acht Worker], 3, "Rechnen", [Distribution Strategy])[
  Acht Worker trainieren synchron, je 64 Beispiele pro Schritt; der Referenzlauf auf einem Gerät nutzt Batch 64 und Lernrate 0,1. Das Modell hat 25 Millionen Parameter (float32), die Rechenzeit je Schritt beträgt 0,30 s. Die Gradienten werden per Ring-All-Reduce abgeglichen; die Kommunikation überlappt nicht mit der Rechnung, ihre Zeit sei Datenvolumen durch Bandbreite.
  #teile(
    [Welche effektive Batch-Größe und welche Lernrate ergibt die lineare Skalierungsregel?],
    [Wie viele Daten sendet jeder Worker je Schritt?],
    [Welche Beschleunigung ergibt sich bei 100 Gbit/s und bei 1 Gbit/s?],
  )
]

#aufgabe("t5", [Zufallssuche], 2, "Rechnen", [Hyperparameter Tuning])[
  #teile(
    [Wie wahrscheinlich liegt bei 60 zufällig gezogenen Konfigurationen mindestens eine im besten Zwanzigstel (5 %) des Suchraums?],
    [Wie viele Läufe braucht man für 99 %?],
    [Ein Raster hat drei Hyperparameter mit je vier Werten, aber nur einer beeinflusst das Ergebnis. Wie viele verschiedene Werte dieses einen Parameters probiert das Raster, wie viele eine Zufallssuche mit gleicher Laufzahl?],
  )
]

#aufgabe("t6", [Der Sieger auf den Testdaten], 3, "Code", [Hyperparameter Tuning])[
  Erzeugen Sie reines Rauschen: 20 Merkmale, zufällige Labels, 100 Trainings-, 100 Test- und 5 000 frische Beispiele. Ziehen Sie 100 zufällige Konfigurationen eines Entscheidungsbaums. #teile(
    [Wählen Sie die Konfiguration mit der besten Genauigkeit auf den 100 Testbeispielen. Was melden Sie, was erreicht sie auf den frischen Beispielen?],
    [Welchen Wert erwartet man als Maximum von 100 Zufallsergebnissen auf 100 Beispielen?],
    [Wie wählt man richtig?],
  )
]

#aufgabe("t7", [Wann hört das Training auf?], 2, "Rechnen", [Checkpoints])[
  Early Stopping mit Geduld 3 und Mindestverbesserung 0,001. Der Validierungs-Loss je Epoche (1 bis 14): 0,800; 0,620; 0,510; 0,450; 0,420; 0,405; 0,398; 0,399; 0,401; 0,396; 0,397; 0,402; 0,410; 0,425. In welcher Epoche stoppt das Training, und welcher Stand wird behalten? Wann wird `best` geschrieben?
]

== Resilient Serving (Patterns 16 bis 20)

#aufgabe("s1", [Zähler im Arbeitsspeicher], 2, "Diagnose", [Stateless Serving Function])[
  Ein Prognoseservice läuft in vier Instanzen hinter einem Load Balancer. Für das Merkmal "Anfragen dieses Kunden in den letzten 10 Minuten" zählt jede Instanz im Arbeitsspeicher mit. Seit der Skalierung auf vier Instanzen sind die Vorhersagen schlechter und hängen von der Instanz ab. #teile(
    [Welches Pattern wird verletzt, und was geht schief?],
    [Wohin gehört der Zustand? Welche zwei Patterns kommen in Frage?],
  )
]

#aufgabe("s2", [Online oder Batch], 1, "Rechnen", [Batch Serving])[
  200 000 Bestellungen sollen über Nacht bewertet werden. Annahme: Jeder Aufruf kostet 4 ms Fixaufwand (Netz, Serialisierung) plus 0,01 ms Rechenzeit je Zeile. #teile(
    [Wie lange dauern 200 000 Einzelaufrufe, wie lange vier Batches zu 50 000 Zeilen?],
    [Wann bleibt man trotzdem bei Online-Vorhersagen?],
  )
]

#aufgabe("s3", [Anteil der zweiten Phase], 2, "Rechnen", [Two-Phase Predictions])[
  Ein Gerät klassifiziert Bilder zuerst mit einem kleinen Modell. Bei 82 % der Bilder liegt dessen Sicherheit über der Schwelle; dort ist es zu 99 % richtig. Die übrigen 18 % gehen an ein Cloud-Modell, das auf ihnen zu 97 % richtig ist (das kleine Modell wäre dort nur zu 71 % richtig). Es gibt 1 000 000 Anfragen am Tag, ein Bild hat 200 kB, eine Cloud-Anfrage kostet 0,0004 Euro, das Gerät antwortet in 20 ms, die Cloud-Phase kommt mit 250 ms hinzu.
  #teile(
    [Wie hoch ist die Gesamtgenauigkeit?],
    [Wie viele Daten und Kosten fallen an, wie hoch ist die mittlere Latenz?],
    [Welche Annahme über die "Sicherheit" des kleinen Modells ist entscheidend?],
  )
]

#aufgabe("s4", [Schwelle wählen], 3, "Code", [Two-Phase Predictions])[
  Trainieren Sie auf den Ziffern von scikit-learn ein kleines Modell (logistische Regression auf $4 times 4$-Mittelwerten) und ein großes (SVM auf $8 times 8$). Bestimmen Sie auf einem Validierungsteil die Schwelle $tau$, bei der die Gesamtgenauigkeit höchstens einen Prozentpunkt unter der des großen Modells liegt und der Cloud-Anteil minimal ist. Berichten Sie das Ergebnis einmal auf den Testdaten.
]

#aufgabe("s5", [Falsche Reihenfolge], 2, "Code", [Keyed Predictions])[
  Ein Job bewertet vier Stücke zu je drei Bestellungen parallel. Die Antworten kommen in der Reihenfolge 2, 0, 3, 1 an und werden in dieser Reihenfolge an die Bestellungen geheftet. #teile(
    [Bauen Sie das nach. Wie groß ist der Fehler, wie groß mit einem Join über die Bestell-ID?],
    [Was passiert, wenn ein Stück wegen einer Wiederholung doppelt ankommt?],
    [Welche Eigenschaften soll ein Schlüssel haben?],
  )
]

#aufgabe("s6", [Verteilung verschoben], 2, "Rechnen", [Continued Model Evaluation])[
  Ein Merkmal (Warenkorbwert) fällt in fünf Klassen. Anteile im Training: 20, 30, 25, 15, 10 %. Anteile im Betrieb: 10, 25, 25, 20, 20 %. #teile(
    [Berechnen Sie den Population Stability Index $"PSI" = sum_i (a_i - e_i) ln(a_i slash e_i)$.],
    [Wie ordnen Sie den Wert ein?],
    [Was kann diese Kennzahl nicht erkennen?],
  )
]

#aufgabe("s7", [Wie viele Labels braucht der Alarm?], 3, "Rechnen", [Continued Model Evaluation])[
  Ein Modell hatte 90 % Genauigkeit. Ein Rückgang auf 87 % soll mit 5 % Irrtumswahrscheinlichkeit und 80 % Power erkannt werden. Für den Test einer Anteilsrate gilt $n = ((z_(alpha slash 2) sqrt(p_0 (1 - p_0)) + z_beta sqrt(p_1 (1 - p_1))) / (p_0 - p_1))^2$ mit $z_(alpha slash 2) = "1,96"$ und $z_beta = "0,84"$.
  #teile(
    [Wie viele beschriftete Fälle braucht man?],
    [Es kommen 100 beschriftete Fälle am Tag, die Labels treffen 30 Tage nach der Vorhersage ein. Wann erscheint der erste belastbare Alarm?],
    [Wie kommt man früher zu einem Signal?],
  )
]

== Reproducibility (Patterns 21 bis 27)

#aufgabe("r1", [Zwei Skalierer], 2, "Diagnose und Rechnen", [Transform])[
  Das Training standardisiert das Alter mit Mittelwert 40 und Standardabweichung 10 aus den Trainingsdaten. Der Service rechnet `(alter - alter.mean()) / alter.std()` auf der eingehenden Anfrage (ein NumPy-Array, `std` ohne Freiheitsgradkorrektur). Eine Anfrage enthält drei Kunden mit 62, 58 und 66 Jahren.
  #teile(
    [Welche z-Werte rechnen Training und Service?],
    [Was passiert bei einer Anfrage mit einem Kunden?],
    [Wie heißt der Fehler, wie behebt ihn das Pattern? Wie heißt der verwandte Fehler, wenn man den Skalierer vor dem Split auf allen Daten anpasst?],
  )
]

#aufgabe("r2", [Split über den Hash], 2, "Rechnen und Code", [Repeatable Splitting])[
  10 000 Zeilen gehören zu 1 000 Patienten. Implementieren Sie `ist_training(patient_id)` so, dass 80 % der Patienten (nicht der Zeilen) im Training landen. #teile(
    [Zeigen Sie: Anteil, keine Patienten auf beiden Seiten, Stabilität nach 200 neuen Patienten. Vergleichen Sie mit einem zufälligen Split.],
    [Wie stark streut der Trainingsanteil bei 1 000 Patienten?],
    [Warum taugt Pythons `hash()` nicht?],
  )
]

#aufgabe("r3", [Zwei Kartenarten], 2, "Rechnen", [Bridged Schema])[
  Die alten Zeilen haben "Karte", die neuen unterscheiden Kreditkarte (70 %) und Debitkarte (30 %). #teile(
    [Man weist den alten Zeilen die Kartenart zufällig nach 70 zu 30 zu. Welcher Anteil der zugewiesenen Werte stimmt, wenn die wahren Anteile früher gleich waren?],
    [Welcher Anteil stimmt, wenn man allen alten Zeilen "Kreditkarte" zuweist? Was wäre eine dritte, "ehrliche" Möglichkeit?],
    [Was gilt, wenn die Anteile früher 50 zu 50 waren?],
  )
]

#aufgabe("r4", [Fenster], 3, "Code", [Windowed Inference])[
  Das Merkmal ist der Mittelwert der letzten drei Messwerte (einschließlich des aktuellen). Die Messwerte sind $10, 12, 11, 15, 20, 18, 17$.
  #teile(
    [Berechnen Sie es als Batch (pandas `rolling`) und als Stream (feste Warteschlange). Sind die Ergebnisse gleich?],
    [Was liefert ein zentriertes Fenster, und warum ist es im Training falsch?],
    [Wie behandelt man die ersten beiden Werte?],
  )
]

#aufgabe("r5", [Welcher Wert zu welchem Zeitpunkt?], 3, "Code", [Feature Store])[
  Der Feature Store hält "Bestellungen in 30 Tagen" mit Gültigkeitsbeginn: Kunde 1: 2 (ab 1.3.), 5 (ab 10.3.), 1 (ab 20.3.); Kunde 2: 7 (ab 5.3.), 3 (ab 25.3.). Beschriftete Ereignisse: Kunde 1 am 12.3. und 25.3., Kunde 2 am 3.3. und 15.3. Welchen Wert soll jedes Ereignis im Trainingsdatensatz bekommen? Was liefert der Join "neuester Wert je Kunde"? Setzen Sie den zeitpunktrichtigen Join mit pandas um.
]

#aufgabe("r6", [Was läuft neu?], 2, "Rechnen", [Workflow Pipeline])[
  Eine Pipeline hat sieben Schritte: `ingest`, `clean`, `featurize`, `split`, `train`, `evaluate`, `register`. `clean` braucht `ingest`; `featurize` und `split` brauchen `clean`; `train` braucht `featurize` und `split`; `evaluate` braucht `train` und `split`; `register` braucht `train` und `evaluate`. #teile(
    [Geben Sie eine topologische Ordnung an. Welche Schritte können parallel laufen?],
    [Welche Schritte laufen neu, wenn sich `train`, `split` oder `clean` ändert?],
    [Warum darf der Graph keinen Zyklus enthalten?],
  )
]

#aufgabe("r7", [Neue Pflichtfeld-Version], 2, "Diagnose", [Model Versioning])[
  Modell v2 verlangt ein neues Pflichtfeld `kundentyp`; drei Clients senden es nicht. Außerdem liefert v2 neu trainierte Embeddings, die ein nachgelagertes Modell als Eingabe nutzt. #teile(
    [Was bricht?],
    [Wie löst Pattern 27 das?],
    [Warum sind Embeddings verschiedener Modellversionen nicht austauschbar?],
  )
]

== Responsible AI (Patterns 28 bis 30)

#aufgabe("v1", [Der Maßstab], 2, "Code", [Heuristic Benchmark])[
  Erzeugen Sie mit `lieferdaten()` 6 000 Lieferungen (Entfernung, Artikel, Regen; Rauschen mit Standardabweichung 2,5 Minuten). #teile(
    [Bestimmen Sie den mittleren absoluten Fehler für den Mittelwert, die Faustregel "10 Minuten plus 3 Minuten je Kilometer", eine lineare Regression und Gradient Boosting.],
    [Welcher Wert ist der Maßstab, den ein Modell schlagen muss? Lohnt sich Gradient Boosting?],
  )
]

#aufgabe("v2", [Beiträge verteilen], 2, "Rechnen", [Explainable Predictions])[
  Das Modell sagt die Lieferzeit voraus: $8 + "2,5" dot "km" + "0,6" dot "Artikel" + 5 dot "Regen"$ (Regen ist 0 oder 1). Der Fall: 9 km, 5 Artikel, Regen. #teile(
    [Verteilen Sie die Differenz zur Vorhersage der Baseline (Mittelwerte: 4 km, 3 Artikel, Regenanteil 0,3) als Beitrag $w_i (x_i - b_i)$ auf die Merkmale. Was ergibt die Summe?],
    [Wie ändert sich die Verteilung mit der Baseline "trockener Tag" (Regen 0)?],
  )
]

#aufgabe("v3", [Die Postleitzahl als Grund], 2, "Verständnis", [Explainable Predictions])[
  Bei einem abgelehnten Kreditantrag zeigt die Erklärung den größten negativen Beitrag für die Postleitzahl. Ein Kollege rät dem Kunden, umzuziehen. #teile(
    [Was ist an der Schlussfolgerung falsch?],
    [Nennen Sie zwei Gründe, warum Attributionen keine Ursachen sind.],
    [Was sollte der Kunde stattdessen erfahren, und welches Pattern prüft die Postleitzahl?],
  )
]

#aufgabe("v4", [Zwei Gruppen im Vergleich], 2, "Rechnen", [Fairness Lens])[
  Ein Kreditmodell liefert je Gruppe diese Konfusionsmatrizen (tatsächlich kreditwürdig / vom Modell angenommen):
  #align(center, table(columns: 6, align: center, inset: (x: 0.7em, y: 0.35em), table.header([Gruppe], [Treffer], [Fehlalarme], [übersehen], [richtig abgelehnt], [Anzahl]), [A], [320], [60], [80], [540], [1 000], [B], [60], [40], [40], [360], [500]))
  #teile(
    [Berechnen Sie Genauigkeit (gesamt und je Gruppe), Auswahlrate, True-Positive-Rate, False-Positive-Rate und Precision je Gruppe.],
    [Welche Fairness-Kriterien sind verletzt, welche erfüllt?],
  )
]

#aufgabe("v5", [Nicht alles zugleich], 3, "Rechnen", [Fairness Lens])[
  Zwei Gruppen haben die Basisraten 0,4 (A) und 0,2 (B) für das positive Ergebnis. Das Modell erreicht in beiden Gruppen dieselbe True-Positive-Rate 0,8 und False-Positive-Rate 0,1. #teile(
    [Berechnen Sie die Precision (positiver prädiktiver Wert) und die Auswahlrate je Gruppe.],
    [Welche False-Positive-Rate müsste B haben, damit die Precision von B gleich der von A wird (bei TPR 0,8)? Was folgt?],
  )
]

#aufgabe("v6", [Entfernt und doch da], 3, "Code", [Fairness Lens])[
  Historische Einstellungen sind verzerrt: Bei gleichem Können wurde Gruppe 1 seltener eingestellt. Das Merkmal "Gruppe" wird nicht ins Modell gegeben, ein Merkmal ("Proxy", z. B. die Postleitzahl) korreliert aber mit ihr. Simulieren Sie das mit 40 000 Personen, trainieren Sie eine logistische Regression auf Können und Proxy beziehungsweise nur auf Können und wählen Sie jeweils die besten 30 %. Wie unterscheiden sich die Auswahlraten der Gruppen?
]

== Szenarien über mehrere Kategorien

In echten Projekten tritt selten ein einzelnes Pattern auf. Die drei Szenarien beschreiben je ein System mit mehreren Schwächen (K1 berührt fünf der sechs Kategorien, K2 vier, K3 drei), und zu jedem gehören fünf Fragen. Die Lösung zeigt eine Zielarchitektur, in der jedes Pattern dort steht, wo es wirkt. Alle Zahlen sind Annahmen der Aufgabe.

#block(breakable: true)[
=== K1 Betrugserkennung bei einem Zahlungsdienstleister <aufg-k1>

Ein Dienstleister verarbeitet 40 Millionen Transaktionen am Tag, 0,1 % sind Betrug (40 000 Fälle). Ein Gradient-Boosting-Modell nutzt 120 Merkmale, darunter 18 mit Abfragen bei Drittanbietern (zusammen 0,05 Cent je Transaktion). Das Team meldet 99,9 % Genauigkeit, die Fraud-Abteilung findet aber nur 8 % der Betrugsfälle. Ein Nachtjob bewertet verdächtige Konten auf mehreren Workern erneut; die Ergebnislisten passen nicht zu den Konten. Rückbuchungen bestätigen Betrug erst nach bis zu 60 Tagen, und die Betrüger wechseln ihre Muster alle paar Wochen. Kunden aus Gruppe G werden zu 0,6 %, aus Gruppe H zu 0,1 % fälschlich gesperrt; das Herkunftsland geht als Hashed Feature mit 64 Buckets ein.

#figure(
  diagram(
    node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 5pt, spacing: (6mm, 6mm),
    node((0, 0), text(size: 8.5pt)[Transaktion \ 40 Mio./Tag], fill: luma(242)),
    edge("->"),
    node((1, 0), text(size: 8.5pt)[18 teure Abfragen \ für jede Transaktion], fill: orange-hell, stroke: 0.8pt + orange),
    edge("->"),
    node((2, 0), text(size: 8.5pt)[ein Modell, 120 Merkmale \ Genauigkeit 99,9 %, Recall 8 %], fill: orange-hell, stroke: 0.8pt + orange),
    edge("->"),
    node((3, 0), text(size: 8.5pt)[Freigabe oder \ Alarm], fill: luma(242)),
    node((1, 1), text(size: 8.5pt)[Nachtjob, parallele Worker], fill: luma(242)),
    edge("->"),
    node((2, 1), text(size: 8.5pt)[Ergebnisse in Ankunfts-\ reihenfolge an Konten geheftet], fill: orange-hell, stroke: 0.8pt + orange),
    edge("->"),
    node((3, 1), text(size: 8.5pt)[Analysten: Rückbuchungen \ nach bis zu 60 Tagen], fill: luma(242)),
  ),
  caption: [Ist-Zustand von K1. Orange: Stellen, an denen die Beschreibung ein Problem zeigt.],
)

#teile(
  [Welche Kennzahlen ersetzen die Genauigkeit, welche Maßnahmen des Rebalancing eignen sich, und was bleibt dabei unangetastet?],
  [Entwerfen Sie eine Cascade. Welchen Recall braucht Stufe 1 für einen Gesamt-Recall von mindestens 0,85, wenn Stufe 2 90 % erkennt? Was kosten die teuren Abfragen, wenn 5 % der Transaktionen Stufe 2 erreichen?],
  [Welches Pattern behebt die falsch zugeordneten Ergebnislisten?],
  [Wie überwachen Sie das Modell bei bis zu 60 Tagen Labelverzug?],
  [Was prüfen Sie wegen der Sperrquoten, und welchen Zusammenhang mit dem Hashed Feature?],
)
#verweis("k1")
]

#block(breakable: true)[
=== K2 Röntgen-Triage im Krankenhaus <aufg-k2>

Ein Krankenhaus will Thorax-Röntgenbilder nach Dringlichkeit sortieren: 11 840 Aufnahmen von 3 200 Patienten (3,7 je Patient), jede von drei Radiologen unabhängig beurteilt, bei 22 % uneinig. Das Team nimmt ein auf Alltagsfotos vortrainiertes Netz, teilt die Aufnahmen zufällig 80 zu 20 und erreicht 97 % Genauigkeit; im Pilot an einem zweiten Haus sind es 81 %. Heatmaps zeigen hohe Beiträge in der Bildecke, in der die einsendende Station eingeblendet ist. Während des Piloten wird das Modell zweimal ausgetauscht, ohne dass sich Auswertungen danach einem Stand zuordnen lassen. Dringende Fälle in der Altersgruppe über 80 werden deutlich seltener erkannt (Annahme).

#figure(
  diagram(
    node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 5pt, spacing: (6mm, 6mm),
    node((0, 0), text(size: 8.5pt)[11 840 Aufnahmen \ 3 200 Patienten], fill: luma(242)),
    edge("->"),
    node((1, 0), text(size: 8.5pt)[zufälliger 80/20-Split: \ dieselben Patienten \ in Training und Test], fill: orange-hell, stroke: 0.8pt + orange),
    edge("->"),
    node((2, 0), text(size: 8.5pt)[vortrainiertes Netz, \ alle Schichten \ trainiert], fill: luma(242)),
    edge("->"),
    node((3, 0), text(size: 8.5pt)[97 % im eigenen Haus, \ 81 % im Pilot], fill: orange-hell, stroke: 0.8pt + orange),
    node((1, 1), text(size: 8.5pt)[Label = Mehrheit \ der 3 Befunder], fill: orange-hell, stroke: 0.8pt + orange),
    edge((1, 1), (2, 0), "->"),
    node((2, 1), text(size: 8.5pt)[Heatmap: Beitrag \ aus der Bildecke], fill: orange-hell, stroke: 0.8pt + orange),
    edge((2, 0), (2, 1), "->"),
    node((3, 1), text(size: 8.5pt)[Modell zweimal \ ausgetauscht], fill: orange-hell, stroke: 0.8pt + orange),
    edge((3, 0), (3, 1), "->"),
  ),
  caption: [Ist-Zustand von K2.],
)

#teile(
  [Warum 97 % im eigenen Haus, aber 81 % im Pilot? Wie wahrscheinlich steht ein Patient mit vier Aufnahmen bei einer zufälligen 80/20-Aufteilung auf beiden Seiten? Wie teilen Sie richtig, und wie viele Patienten und Aufnahmen hat der Test dann ungefähr?],
  [Welche Variante des Transfer Learning wählen Sie bei rund 9 500 Trainingsaufnahmen und warum? Wie viele Aufnahmen betrifft die Uneinigkeit der Befunder, und was tun Sie damit?],
  [Was zeigt die Heatmap, wie heißt das Phänomen, und wie gehen Sie vor?],
  [Welchen Maßstab setzen Sie vor das Netz, und wie sorgen Sie dafür, dass jede Auswertung einem Modellstand zuzuordnen ist?],
  [Was prüfen Sie wegen der Altersgruppe über 80, und worauf achten Sie bei der Aussagekraft?],
)
#verweis("k2")
]

#block(breakable: true)[
=== K3 Verbrauchsprognose bei einem Energieversorger <aufg-k3>

Ein Versorger prognostiziert für 1,5 Millionen Smart Meter den Verbrauch des nächsten Tages. Jeder Zähler meldet 96 Viertelstundenwerte am Tag (144 Millionen Werte). Merkmale sind der Mittelwert der letzten 24 Stunden und der Wert zur gleichen Zeit vor einer Woche. Im Training berechnet ein Data Scientist den Mittelwert mit `rolling(96, center=True)`, im Service zählt jede Instanz die eingehenden Werte selbst mit. Die Nachtprognose soll den Online-Service 144 Millionen Mal aufrufen (angenommen 4 ms je Aufruf). Fünf Modellvarianten wurden probiert, auf welchem Datenstand, ist unklar. Bei einer Hitzewelle steigt der Fehler, obwohl technisch nichts ausfällt.

#figure(
  diagram(
    node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 5pt, spacing: (6mm, 6mm),
    node((0, 0), text(size: 8.5pt)[Messwerte \ 144 Mio./Tag], fill: luma(242)),
    edge("->"),
    node((1, 0), text(size: 8.5pt)[Training: Fenster \ zentriert (pandas)], fill: orange-hell, stroke: 0.8pt + orange),
    edge("->"),
    node((2, 0), text(size: 8.5pt)[Modell \ (5 Varianten, \ Stand unklar)], fill: orange-hell, stroke: 0.8pt + orange),
    node((0, 1), text(size: 8.5pt)[Messwerte \ im Betrieb], fill: luma(242)),
    edge("->"),
    node((1, 1), text(size: 8.5pt)[Service: Zähler im \ Arbeitsspeicher je Instanz], fill: orange-hell, stroke: 0.8pt + orange),
    edge("->"),
    node((2, 1), text(size: 8.5pt)[144 Mio. Einzelaufrufe \ in der Nacht], fill: orange-hell, stroke: 0.8pt + orange),
    edge("->"),
    node((3, 1), text(size: 8.5pt)[Prognose \ je Zähler], fill: luma(242)),
    edge((2, 0), (2, 1), "->"),
  ),
  caption: [Ist-Zustand von K3. Training und Betrieb berechnen das Merkmal an verschiedenen Orten auf verschiedene Weise.],
)

#teile(
  [Welche zwei Fehler stecken im Merkmal "Mittelwert der letzten 24 Stunden", und welche Patterns beheben sie?],
  [Wie viel Zustand hält eine Stream-Verarbeitung, wenn sie für jeden Zähler alle 96 Werte (float64) vorhält? Wie viel genügt bei festen, nicht überlappenden Fenstern?],
  [Wie lange würden 144 Millionen Einzelaufrufe dauern, und wie sieht die Alternative aus?],
  [Welche zwei Patterns beantworten die Frage, welcher Datenstand zu welchem Modell gehört?],
  [Wie erkennen Sie die Auswirkung der Hitzewelle früh, und woran messen Sie, ob das Modell überhaupt noch etwas leistet?],
)
#verweis("k3")
]

== Lösungen

Die Lösungen sind nach derselben Reihenfolge geordnet wie die Aufgaben. Wo eine Rechnung dabei ist, steht die Formel mit eingesetzten Zahlen; die Ergebnisse stimmen mit den Ausgaben der Skripte überein.

=== Data Representation

#loesung("d1")[
  *(a)* Das Pattern ersetzt eine gelernte Zuordnung (ID zu Spalte) durch eine berechnete. Jede Zeichenkette hat einen Bucket, auch eine nie gesehene, und es gibt keine Tabelle, die fehlen oder veralten könnte. *(b)* Die Vorhersage für die neue ID stützt sich auf das Gewicht ihres Buckets, und das stammt von den bekannten Werten, die zufällig dort liegen. Über das Produkt selbst weiß das Modell nichts, die Antwort sieht aber aus wie jede andere. Brauchbar wird sie erst, wenn Information über das Produkt in die Eingabe geht (Kategorie, Preisklasse, ein Embedding aus der Beschreibung) oder ein Kennzeichen "neu" das Modell auf den Fall vorbereitet. *(c)* Hashing zerstört Ähnlichkeit: zwei fast gleiche Produktnamen landen in unverwandten Buckets, was Embeddings (Pattern 2) leisten. Und es verschleiert, welcher Wert hinter einem Gewicht steckt; ein Bucket gehört zu einer ganzen Gruppe von Werten, was die Erklärbarkeit einschränkt.
]

#loesung("d2")[
  #figure(
    {
      let d = json("../code/15/kollision_d2.json")
      daten-plot(size: (9.5, 2.9), x-label: [Buckets $B$ (20 000 IDs)], y-label: [Anteil mit Kollision], x-mode: "log", x-tick-step: none, x-ticks: ((10000, [10#super[4]]), (100000, [10#super[5]]), (1000000, [10#super[6]])), y-min: 0, y-max: 1.0, y-tick-step: 0.25, x-min: 4000, x-max: 3000000, {
        plot.add(d.kurve.map(p => (p.B, p.formel)), style: (stroke: 1pt + luma(120)))
        plot.add(d.punkte.map(p => (p.B, p.gemessen)), style: (stroke: none), mark: "o", mark-size: 0.14, mark-style: (fill: orange, stroke: none))
        plot.add-hline(0.05, style: (stroke: (paint: gruen, dash: "dashed", thickness: 0.8pt)))
        plot.add-vline(d.B_5prozent, style: (stroke: (paint: gruen, dash: "dashed", thickness: 0.8pt)))
      })
    },
    caption: [Anteil der IDs mit Kollision (Linie: Formel, Punkte: gemessen); grün gestrichelt: 5-%-Grenze bei $B = "389 896"$.],
  ) <abb-d2>

  *(a)* Eingesetzt: $1 - (1 - "1/50 000")^("19 999") = "0,3297"$, rund ein Drittel der IDs teilt sich einen Bucket. Belegte Buckets: $"50 000" (1 - (1 - "1/50 000")^("20 000")) approx "16 484"$. Die 20 000 IDs verteilen sich also auf nur 16 484 Buckets, obwohl es 2,5-mal so viele Buckets wie IDs gibt. *(b)* Aus $1 - (1 - 1 slash B)^(n-1) <= "0,05"$ folgt $B >= 1 slash (1 - "0,95"^(1 slash (n-1))) = "389 896"$; die Näherung $B >= n slash (-ln "0,95") = "389 915"$ liegt daneben kaum. Man braucht das 19,5-Fache der Wertezahl. *(c)* Die Messung mit echten Hashes bestätigt die Formel (@abb-d2). Die Konsequenz: Ein nahezu kollisionsfreies Hashing kostet fast so viel Platz wie One-Hot. Das Pattern lohnt, wenn Kollisionen hinnehmbar sind, etwa weil die meisten Werte selten vorkommen. Bei nur 2 000 Werten (Postleitzahlen) wäre es dagegen unnötig: 2 000 One-Hot-Spalten sind klein, ein Hash auf 500 Buckets ließe fast alle Werte kollidieren (98 %).

  
]

#loesung("d3")[
  *(a)* $7 dot 24 dot 23 = "3 864"$ Zellen, im Mittel $"1 000 000" slash "3 864" = "258,8"$ Fahrten je Zelle. Wochentag × Stunde ergibt 168 Zellen und 5 952 Fahrten. Der Mittelwert täuscht: Nachts in einem Randbezirk sind es nur wenige, und die Gewichte solcher Zellen sind unsicher. *(b)* Nur fachlich sinnvolle Paare kreuzen (Stunde × Bezirk: 552 Zellen, 1 812 Fahrten); den Wochentag gröber fassen (Werktag/Wochenende × Stunde × Bezirk: $2 dot 24 dot 23 = "1 104"$ Zellen, 906 Fahrten); seltene Zellen zusammenfassen oder verwerfen; das Kreuzprodukt hashen (Pattern 1) oder in ein Embedding überführen (Pattern 2).
]

#loesung("d4")[
  #code-aus("01_darstellung.py", "bx, by = np.digitize(x, kanten)", bis: "idx_tr, idx_te")
  #ausgabe("01_darstellung.txt", "python 01_darstellung.py", ab: "Logistische Regression, Buckets einzeln", bis: "\nD5")
  *(a)* Die beste Gerade auf den Rohwerten erreicht 0,654. Ohne Rauschen liegt die Grenze bei zwei Dritteln (eine eigene Rastersuche auf 400 000 Punkten ergibt 0,667; sie steht nicht im Skript), mit 5 % Rauschen bei $"0,05" + "0,9" dot 2 slash 3 = "0,65"$: Eine Gerade trennt nicht alle vier Quadranten, sie schneidet nur eine Ecke ab. *(b)* Mit den Buckets einzeln findet das Modell nichts, denn in jedem x-Bucket und in jedem y-Bucket ist die Labelrate 50 %; der Zusammenhang steckt nur in der Kombination. Der Einzellauf (0,554) täuscht: Über 20 Datensätze gemittelt sind es 0,506, die Spanne reicht von 0,384 bis 0,670, je nachdem, welches zufällige Restmuster das Training gefunden hat. Mit dem Cross sind es 0,951, und die Obergrenze liegt wegen des Rauschens bei 0,95. *(c)* Der Baum erreicht 0,951 ohne Cross: Er teilt zuerst nach x und dann nach y und bildet die Kombination durch seine Verzweigung selbst. Deshalb ist das Cross vor allem für Modelle wichtig, die nur gewichtete Summen bilden.
]

#loesung("d5")[
  *(a)* $root(4, "4 000 000") = "44,7"$, also $d = 45$. *(b)* $"4 000 000" dot 45 = 180$ Millionen Parameter, mal 4 Byte sind 720 MB. Nach dem Hashing auf 500 000 Buckets sind es $"500 000" dot 45 = "22,5"$ Millionen Parameter, 90 MB, ein Achtel. Zum Vergleich hätte ein lineares Modell mit One-Hot nur 4 Millionen Gewichte (16 MB); das Embedding gibt jedem Titel 45-mal mehr Parameter, die gelernt werden wollen. *(c)* Seltene Titel, die sich einen Bucket mit einem beliebten teilen: Ihr Vektor wird von den vielen Beispielen des beliebten Titels bestimmt. Häufige Titel spüren die Kollision kaum.
]

#loesung("d6")[
  *(a)* Training-Serving Skew: Der Nullvektor als "Foto fehlt" kam im Training nie vor. Nach der Standardisierung bedeutet null außerdem "durchschnittliches Bild", nicht "kein Bild", und das Modell wertet ihn wie jede andere Eingabe. Es verhält sich auf diesen Eingaben unvorhersehbar. *(b)* Während des Trainings die Quelle zufällig weglassen (in 30 % der Beispiele ohne Foto), damit das Modell den Fall kennt, und ein Kennzeichen "Foto vorhanden" mitgeben; alternativ ein zweites Modell ohne Foto als Rückfall und eine Weiche davor. *(c)* $sqrt("10 000") = 100$ gegen $sqrt(5) = "2,24"$, das Verhältnis ist 44,7. Bei abstandsbasierten Verfahren übertönt das Bild die Tabelle; man verdichtet deshalb jede Quelle zuerst auf eine vergleichbare Länge.
]

=== Problem Representation

#loesung("p1")[
  *(a)* Der quadratische Fehler wird vom Mittelwert minimiert: 40 Minuten. Diese Zeit kommt in den Daten nie vor; jede Lieferung liegt um 20 Minuten daneben. *(b)* Mit Zeitklassen (etwa bis 30, 30 bis 50, über 50 Minuten) liefert das Modell eine Wahrscheinlichkeit je Klasse, hier ungefähr 50 % für "kurz" und 50 % für "lang". Die App kann beides zeigen oder auf die Auslastung warten. Eine andere Möglichkeit sind Quantile statt des Mittelwerts @koenker_regression_quantiles_1978. *(c)* Sternebewertungen von eins bis fünf als Zahl vorherzusagen nutzt die Ordnung der Klassen, die eine Klassifikation ignoriert.
]

#loesung("p2")[
  *(a)* Softmax: $("0,549"; "0,406"; "0,037"; "0,008")$, Summe 1. Sigmoid: $("0,900"; "0,870"; "0,378"; "0,119")$, Summe 2,27. *(b)* Bei Softmax liegt nur Tag A über 0,5, bei Sigmoid sind es A und B. *(c)* Softmax koppelt die Ausgänge: Die Wahrscheinlichkeiten konkurrieren und summieren zu 1. Zwei Tags mit je 0,9 sind unmöglich, und bei drei zutreffenden Tags könnte keiner viel mehr als ein Drittel bekommen. Nimmt man die zwei größten, muss man vorher wissen, wie viele Tags zutreffen. Sigmoid behandelt jeden Tag als eigene Ja/Nein-Frage; dazu gehört die binäre Kreuzentropie je Tag, über die Tags gemittelt. Die Schwelle kann je Tag gewählt werden.
]

#loesung("p3")[
  *(a)* Drei Modelle: $3 dot "0,7"^2 dot "0,3" + "0,7"^3 = "0,441" + "0,343" = "0,784"$. Fünf Modelle: 0,837. *(b)* Die Rechnung setzt unabhängige Fehler voraus. Modelle, die auf denselben Daten und mit ähnlichen Verfahren trainiert wurden, scheitern an denselben schwierigen Beispielen. Ein einfaches Modell der Korrelation (jedes Beispiel hat eine Schwierigkeit; gegeben diese, sind die Modelle unabhängig) macht das sichtbar (@abb-p3): Bei einer Korrelation der Treffer von 0,14 sind es mit drei Modellen 0,754, mit 21 Modellen nur 0,832; bei 0,33 sind es 0,728 und 0,756, der Grenzwert liegt bei 0,763. Vielfalt der Modelle ist wertvoller als ihre Zahl @dietterich_ensemble_2000. *(c)* Bagging trainiert dasselbe Verfahren auf Bootstrap-Stichproben und mittelt, was vor allem die Varianz senkt @breiman_bagging_1996. Boosting trainiert Modelle nacheinander auf den Fehlern der Vorgänger und senkt vor allem den Bias @friedman_gradient_boosting_2001. Stacking lernt mit einem Meta-Modell, die Vorhersagen verschiedener Modelle zu kombinieren @wolpert_stacking_1992.

  #figure(
    {
      let d = json("../code/15/ensemble_p3.json")
      daten-plot(size: (9.5, 3.5), x-label: [Zahl der Modelle $k$], y-label: [Genauigkeit der Mehrheit], x-tick-step: 4, y-min: 0.65, y-max: 1.0, y-tick-step: 0.1, x-min: 0, x-max: 22, {
        plot.add(d.k.zip(d.at("unabhängig")), style: (stroke: 1.2pt + blau), label: [unabhängig])
        plot.add(d.k.zip(d.at("schwach korreliert")), style: (stroke: 1.2pt + gruen), label: [Korrelation 0,14])
        plot.add(d.k.zip(d.at("stark korreliert")), style: (stroke: 1.2pt + orange), label: [Korrelation 0,33])
        plot.add-hline(0.7, style: (stroke: (paint: luma(150), dash: "dotted", thickness: 0.8pt)))
      })
    },
    caption: [Genauigkeit der Mehrheitsentscheidung bei Einzelmodellen mit 70 % (gepunktet). Je stärker die Fehler zusammenhängen, desto früher flacht die Kurve ab. Werte aus `02_problem.py`.],
  ) <abb-p3>
]

#loesung("p4")[
  *(a)* Ohne Cascade: $"100 000" dot "0,4"$ Cent = 400 Euro. Mit Cascade prüft Stufe 2 nur 8 000 Zahlungen: 32 Euro, also 368 Euro (92 %) weniger am Tag. *(b)* Gesamt-Recall $"0,96" dot "0,90" = "0,864"$. Stufe 2 sieht 960 Betrugsfälle und 7 040 harmlose Zahlungen und meldet $864$ Treffer und rund 70 Fehlalarme; die Precision ist $864 slash (864 + 70) = "0,925"$. *(c)* Aus $r_1 dot "0,90" >= "0,88"$ folgt $r_1 >= "0,978"$. Was Stufe 1 aussortiert, ist endgültig verloren (hier 40 Betrugsfälle), deshalb trimmt man sie auf hohen Recall und nimmt viele Fehlalarme in Kauf, die Stufe 2 wieder aussortiert.

  #figure(
    diagram(
      node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 5pt, spacing: (9mm, 9mm),
      node((0, 0), text(size: 8.5pt)[100 000 Zahlungen \ 1 000 Betrug], fill: luma(242)),
      edge("->"),
      node((1, 0), text(size: 8.5pt)[Stufe 1, billig \ lässt 8 000 durch \ (960 Betrug)], fill: blau-hell, stroke: 0.8pt + blau),
      edge("->"),
      node((2, 0), text(size: 8.5pt)[Stufe 2, teure Abfragen \ 8 000 geprüft, 32 Euro], fill: blau-hell, stroke: 0.8pt + blau),
      edge("->"),
      node((3, 0), text(size: 8.5pt)[Alarm: 864 Treffer, \ rund 70 Fehlalarme], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((1, 0), (1, 1), "->", stroke: 0.8pt + orange),
      node((1, 1), text(size: 8.5pt)[92 000 frei, \ davon 40 Betrug], fill: orange-hell, stroke: 0.8pt + orange),
      edge((2, 0), (2, 1), "->", stroke: 0.8pt + orange),
      node((2, 1), text(size: 8.5pt)[96 Betrugsfälle \ von Stufe 2 übersehen], fill: orange-hell, stroke: 0.8pt + orange),
    ),
    caption: [Die Cascade aus P4 mit den Zahlen der Rechnung. Orange: Betrug, der verloren geht.],
  )
]

#loesung("p5")[
  *(a)* Schwelle A: Genauigkeit $"9 940" slash "10 000" = "0,994"$; Precision $80 slash 120 = "0,667"$; Recall $80 slash 100 = "0,80"$; $F_1 = "0,727"$. Schwelle B: Genauigkeit 0,984; Precision $90 slash 240 = "0,375"$; Recall 0,90; $F_1 = "0,529"$. Die Regel "nie Betrug" hat 99,0 % Genauigkeit und ist wertlos; beide Schwellen liegen mit 99,4 % und 98,4 % um weniger als einen Prozentpunkt daneben, B sogar darunter. *(b)* Kosten A: $20 dot 200 + 40 dot 5 = "4 200"$ Euro; B: $10 dot 200 + 150 dot 5 = "2 750"$ Euro; "nie Betrug": 20 000 Euro. B ist billiger, obwohl F1 und Genauigkeit schlechter sind. F1 gewichtet Precision und Recall gleich, der Schaden tut das nicht. Mit diesen Kosten lohnt sich ein Alarm bei kalibrierten Wahrscheinlichkeiten schon ab $p dot 200 > (1 - p) dot 5$, also ab $p > 5 slash 205 = "2,4"$ %. Die Schwelle ist eine Entscheidung über Kosten, kein Optimum einer Kennzahl.
]

#loesung("p6")[
  *(a)* Mehrheit "positiv": $3 dot "0,55"^2 dot "0,45" + "0,55"^3 = "0,408" + "0,166" = "0,575"$. Alle drei einig: $"0,55"^3 + "0,45"^3 = "0,166" + "0,091" = "0,258"$. *(b)* Das Mehrheitslabel einer solchen Rezension ist mit 57,5 % zu 42,5 % kaum mehr als ein Münzwurf. Das Modell lernt, diesen Zufall zu erklären, und liefert im Betrieb auch für Grenzfälle eine sichere Ja/Nein-Antwort. Das Pattern Neutral Class führt eine dritte Klasse ein, die aus der Uneinigkeit abgeleitet wird; der Betrieb gibt solche Fälle an einen Menschen. Alternativ kann der Anteil der Zustimmung als weiches Ziel dienen. Nichts davon hilft, wenn die Wahrheit objektiv feststellbar ist: Dann ist Uneinigkeit ein Qualitätsproblem der Labels, und man verbessert die Labels.
]

#loesung("p7")[
  *(a)* 98 %. *(b)* $w_c = n slash (k dot n_c)$: positiv $"50 000" slash (2 dot "1 000") = 25$, negativ $"50 000" slash (2 dot "49 000") = "0,510"$. *(c)* Mit $beta = "10 000" slash "49 000" = "0,204"$ als Anteil behaltener Negativer gilt $P("Auswahl" | "positiv") = 1$ und $P("Auswahl" | "negativ") = beta$. Damit sind die Odds in der Stichprobe $o_"Stichprobe" = o_"echt" slash beta$, also $o_"echt" = beta dot o_"Stichprobe"$ @dalpozzolo_undersampling_2015. Bei 0,5 ist $o_"Stichprobe" = 1$, also $o_"echt" = "0,204"$ und $p = "0,204" slash "1,204" = "0,170"$. Bei 0,9 sind es $"0,647"$. *(d)* In der Simulation (Anteil 1,9 %) ist die mittlere vorhergesagte Wahrscheinlichkeit des vollständig trainierten Modells 0,0185, des unterabgetasteten 0,0756 und nach der Korrektur 0,0193; die wahre Rate beträgt 0,0186. Das Ranking der Kunden ändert sich durch die Korrektur nicht, für eine Schwelle genügt also das unkorrigierte Modell. Wer mit den Zahlen rechnet (Kosten, Erwartungswerte wie in P5), muss korrigieren.

  ]

=== Model Training

#loesung("t1")[
  Das Pattern gilt nur unter besonderen Bedingungen: Der Eingaberaum ist bekannt und wird von den Trainingsdaten abgedeckt (oder die Funktion ist zwischen den Stützstellen glatt), die Labels sind exakt statt verrauscht, und es wird nur dort abgefragt, wo trainiert wurde. Ein Beispiel ist ein Surrogatmodell für eine Simulation, die man nicht millionenfach rechnen will: Die Simulation ist deterministisch, jedes Label stimmt, und Regularisierung kostet nur Genauigkeit. Bei der Kundenabwanderung sind die Labels verrauscht (viele Gründe, die nicht in den Daten stehen) und die künftigen Kunden unbekannt; ein Modell, das den Trainingsfehler auf null drückt, lernt den Zufall dieser Daten und verallgemeinert schlechter.
]

#loesung("t2")[
  *(a)* Ohne Checkpoint gehen 41 Stunden verloren, mit einem Checkpoint alle 2 Stunden nur 1 Stunde (letzter Stand bei Stunde 40). *(b)* Bei 2 Stunden: 30 Checkpoints, $30 dot 3$ min = 1,5 h (2,5 %). Bei 30 Minuten: 120 Checkpoints, 6 h (10 %). *(c)* Der Gesamtaufwand ist $C(T) = (60 slash T) dot delta + (60 slash 20) dot T slash 2 = 3 slash T + "1,5" T$ Stunden. Ableiten und null setzen: $-3 slash T^2 + "1,5" = 0$, also $T = sqrt(2) = "1,41"$ h; allgemein $T = sqrt(2 delta dot "MTBF")$ (Näherung erster Ordnung nach @young_checkpoint_1974; @daly_checkpoint_2006 gibt eine Näherung höherer Ordnung an). Der Aufwand beträgt dann 4,24 h, rund 7 % der Arbeitszeit. *(d)* Die Simulation (4 000 Läufe je Intervall) liegt nahe an der Formel und weicht erst bei Intervallen im Bereich der Ausfallzeit stark ab (15 h: 30,6 h simuliert gegen 22,7 h nach Formel), weil die Näherung kleine Intervalle voraussetzt (@abb-t2). Ohne Checkpoints startet jeder Ausfall bei null; der erwartete Mehraufwand beträgt dann $"MTBF" (e^(60 slash 20) - 1) - 60 = 322$ Stunden.

  #figure(
    {
      let d = json("../code/15/checkpoint_t2.json")
      daten-plot(size: (9.5, 3.5), x-label: [Checkpoint-Intervall $T$ in Stunden], y-label: [Mehraufwand in Stunden], x-mode: "log", y-mode: "log", x-tick-step: none, x-ticks: ((0.25, [0,25]), (1, [1]), (4, [4]), (15, [15])), y-tick-step: none, y-ticks: ((4, [4]), (10, [10]), (30, [30])), x-min: 0.2, x-max: 20, y-min: 3, y-max: 40, {
        plot.add(d.kurve.map(p => (p.T, p.formel)), style: (stroke: 1.2pt + blau))
        plot.add(d.punkte.map(p => (p.T, p.sim)), style: (stroke: none), mark: "o", mark-size: 0.14, mark-style: (fill: orange, stroke: none))
        plot.add-vline(d.T_opt, style: (stroke: (paint: gruen, dash: "dashed", thickness: 0.8pt)))
      })
    },
    caption: [Mehraufwand für 60 Stunden Arbeit (Linie: Formel, Punkte: Simulation, grün: $T = "1,41"$ h). Beide Achsen logarithmisch.],
  ) <abb-t2>
]

#loesung("t3")[
  *(a)* Eine Lernrate von 0,1 ist für vortrainierte Gewichte sehr groß und überschreibt sie in den ersten Schritten; was das Netz bei Kanten und Texturen schon konnte, geht verloren, und mit 300 Bildern lässt es sich nicht neu lernen. *(b)* Bei der Feature-Extraction friert man die vortrainierten Schichten ein und trainiert nur einen neuen Kopf. Beim Fine-Tuning trainiert man einige oder alle Schichten mit einer deutlich kleineren Lernrate als beim Vortraining weiter. *(c)* Bei 300 Bildern Feature-Extraction, höchstens der letzte Block darüber; es gibt zu wenig Daten, um viele Schichten zu verändern. Bei 30 000 Bildern lohnt Fine-Tuning mehrerer oberer Schichten, zumal Röntgenbilder sich von Alltagsfotos unterscheiden. Die Übertragbarkeit sinkt mit dem Abstand der Aufgaben, und die oberen Schichten sind aufgabenspezifisch @yosinski_transferability_2014.
]

#loesung("t4")[
  *(a)* Effektive Batch-Größe $8 dot 64 = 512$. Die lineare Skalierungsregel erhöht die Lernrate im selben Verhältnis: $"0,1" dot 8 = "0,8"$, in der Praxis mit einem Warm-up in den ersten Epochen @goyal_large_minibatch_2017. *(b)* Der Gradient hat $25 dot 10^6 dot 4$ Byte = 100 MB. Ring-All-Reduce sendet je Worker $2 (N - 1) slash N dot S = "1,75" dot 100$ MB = 175 MB @patarasuk_allreduce_2009. *(c)* Bei 12,5 GB/s dauert das 14 ms. Die Effizienz ist $"0,30" slash ("0,30" + "0,014") = "0,955"$, die Beschleunigung $8 dot "0,955" = "7,64"$. Bei 0,125 GB/s dauert es 1,4 s, die Effizienz sinkt auf 0,176 und die Beschleunigung auf 1,41. Mehr Worker helfen nur, solange die Kommunikation gegenüber der Rechnung klein bleibt; bei langsamem Netz zählt die Bandbreite, nicht die Zahl der Geräte.
]

#loesung("t5")[
  *(a)* $1 - "0,95"^60 = "0,954"$. *(b)* $n >= ln "0,01" slash ln "0,95" = "89,8"$, also 90 Läufe. *(c)* Das Raster hat $4^3 = 64$ Läufe, probiert aber nur 4 verschiedene Werte des wichtigen Parameters; 64 Zufallsläufe probieren 64 verschiedene Werte. Genau dieses Argument führen Bergstra und Bengio an @bergstra_random_search_2012.
]

#loesung("t6")[
  #code-aus("03_training.py", "def bewerte", bis: "print(f\"Mittel aller")
    *(a)* Auf den Testdaten sieht der Sieger mit 0,63 gut aus; auf 5 000 frischen Beispielen erreicht er 0,510, also Raten. *(b)* Der Mittelwert von 100 Zufallsergebnissen auf 100 Beispielen ist 0,5, die Standardabweichung 0,05, das erwartete Maximum von 100 solchen Werten liegt bei 0,625. Eine Auswahl auf den Testdaten findet das Maximum der Streuung. *(c)* Auswahl per Kreuzvalidierung auf den Trainingsdaten, die Testdaten erst danach und einmal (0,52). Auch der Kreuzvalidierungswert des Siegers (0,64) ist optimistisch, da er das Maximum über 100 Konfigurationen ist; die ehrliche Zahl liefert nur der unberührte Test.
]

#loesung("t7")[
  `best` wird in den Epochen 1 bis 7 und in Epoche 10 geschrieben. Epoche 8 (0,399) und 9 (0,401) bessern den Bestwert 0,398 nicht um 0,001; in Epoche 10 (0,396) ist die Verbesserung 0,002, der Zähler beginnt neu. Die Epochen 11, 12 und 13 bringen keine Besserung, nach der dritten (Epoche 13) stoppt das Training. Behalten wird Epoche 10 mit 0,396. Das Skript `03_training.py` spielt den Ablauf Epoche für Epoche durch.
]

=== Resilient Serving

#loesung("s1")[
  *(a)* Verletzt ist Stateless Serving Function: Die Funktion soll ihr Ergebnis nur aus den Argumenten berechnen. Jede Instanz sieht nur den Teil der Anfragen, den der Load Balancer ihr zuteilt, und zählt systematisch zu wenig (bei vier Instanzen im Mittel ein Viertel); ein Neustart setzt den Zähler auf null. Im Training stand der volle Zähler im Merkmal, im Betrieb steht ein anderer: Skew. *(b)* Der Zustand gehört aus dem Service heraus. Entweder berechnet eine Stream-Verarbeitung das Fenster und übergibt das Ergebnis als Eingabe (Windowed Inference, Pattern 24), oder der Service holt den Wert aus einem Feature Store (Pattern 26). Der Service bleibt zustandslos und kann beliebig skaliert werden. Sticky Sessions wären ein Notbehelf, der Skalierung und Ausfallsicherheit untergräbt.
]

#loesung("s2")[
  *(a)* Einzelaufrufe: $"200 000" dot (4 + "0,01")$ ms = 802 s, rund 13 Minuten. Vier Batches: $4 dot 4$ ms $+ "200 000" dot "0,01"$ ms = 2,02 s, rund 400-mal schneller (Annahmen der Aufgabe, die Größenordnung ist typisch, der Wert nicht). *(b)* Online bleibt man, wenn die Eingabe erst im Moment der Anfrage entsteht oder die Antwort sofort gebraucht wird. Ein Batch-Ergebnis altert, wenn sich die Eingaben danach ändern.
]

#loesung("s3")[
  *(a)* $"0,82" dot "0,99" + "0,18" dot "0,97" = "0,9864"$. Ohne die zweite Phase wäre es $"0,82" dot "0,99" + "0,18" dot "0,71" = "0,940"$. *(b)* Der Cloud-Anteil ist 18 %. Datenvolumen: 200 GB sinken auf 36 GB am Tag; Kosten: 400 Euro auf 72 Euro. Die mittlere Latenz beträgt $20 + "0,18" dot 250 = 65$ ms (im schlechtesten Fall 270 ms). *(c)* Dass "sicher" auch "richtig" bedeutet. Neuronale Netze sind oft überzuversichtlich @guo_calibration_2017; ist die Sicherheit nicht kalibriert, bleiben falsche Antworten auf dem Gerät, weil das kleine Modell sich irrt, ohne es zu merken. Die Schwelle ist deshalb auf Validierungsdaten zu wählen, die Güte der Sicherheitsangabe zu prüfen.
]

#loesung("s4")[
  #figure(
    {
      let d = json("../code/15/twophase_s4.json")
      daten-plot(size: (9.5, 2.7), x-label: [Anteil der Anfragen in der Cloud], y-label: [Genauigkeit (Test)], x-tick-step: 0.2, y-min: 0.88, y-max: 1.0, y-tick-step: 0.04, x-min: 0, x-max: 1, {
        plot.add(d.kurve.map(p => (p.anteil, p.acc)), style: (stroke: 1.2pt + blau))
        plot.add-hline(d.acc_cloud, style: (stroke: (paint: gruen, dash: "dashed", thickness: 0.8pt)))
        plot.add-hline(d.acc_edge, style: (stroke: (paint: orange, dash: "dashed", thickness: 0.8pt)))
        plot.add(((d.gewaehlt.anteil, d.gewaehlt.acc),), style: (stroke: none), mark: "o", mark-size: 0.2, mark-style: (fill: gruen, stroke: none))
      })
    },
    caption: [Genauigkeit gegen Cloud-Anteil auf den Testdaten. Grün gestrichelt: großes Modell allein (0,987), orange: kleines allein (0,893); Punkt: Schwelle 0,95.],
  ) <abb-s4>

    #code-aus("04_serving.py", "ziel = acc_c_val", bis: "a_val, g_val")
    Das kleine Modell erreicht 0,893, das große 0,987. Die Schwelle wird auf den Validierungsdaten gewählt: $tau = "0,95"$ liefert dort bei 34,3 % Cloud-Anteil 0,9805. Einmal auf den Testdaten angewendet, sind es 36,7 % Cloud-Anteil und 0,9759, also 1,1 Prozentpunkte unter dem großen Modell (@abb-s4). Das Ziel von einem Punkt wird knapp verfehlt: Die Schwelle ist auf 359 Bildern gewählt und streut. Für die Praxis heißt das, Reserve einzuplanen und die Schwelle im Betrieb zu überwachen (Pattern 18).
]

#loesung("s5")[
  #code-aus("04_serving.py", "# Reihenfolge angenommen", bis: "print(f\"mittlerer Fehler, Reihenfolge")
    *(a)* Mit angenommener Reihenfolge ist der mittlere Fehler 13,5 (jede der zwölf Zuordnungen ist falsch, ohne Fehlermeldung), mit dem Join über die Bestell-ID null. *(b)* Ein doppelt angekommenes Stück erzeugt doppelte Schlüssel; `validate="one_to_one"` lässt den Join mit einem Fehler scheitern, statt Zeilen stillschweigend zu vervielfachen. Üblich ist, Wiederholungen vor dem Join über den Schlüssel zu entdoppeln. *(c)* Eindeutig, stabil über Wiederholungen (also nicht der Zeilenindex im Stück), vor dem Modell vergeben und nicht als Merkmal verwendet; sonst kann ein in der ID kodiertes Wissen (Reihenfolge, Zeit) ins Modell gelangen.
]

#loesung("s6")[
  *(a)* Die Beiträge je Klasse sind $"0,0693"$; $"0,0091"$; $0$; $"0,0144"$; $"0,0693"$ (Beispiel Klasse 1: $("0,10" - "0,20") ln("0,10" slash "0,20") = "0,0693"$). Die Summe ist $"PSI" = "0,162"$. *(b)* Verbreitet ist die Faustregel aus dem Kreditscoring: unter 0,1 stabil, 0,1 bis 0,25 mäßige, darüber deutliche Verschiebung; eine Primärquelle dafür nenne ich nicht, die Grenzen sind Konvention. Hier liegt der Wert im mittleren Bereich: beobachten, nicht sofort handeln. *(c)* Der PSI sieht nur die Eingaben (Covariate Shift) @gama_concept_drift_2014. Ob die Genauigkeit sinkt, zeigt er nicht, und ein Concept Drift, bei dem sich der Zusammenhang zwischen Eingabe und Ergebnis ändert, die Eingaben aber gleich bleiben, bleibt unsichtbar.
]

#loesung("s7")[
  *(a)* $sqrt(p_0 (1 - p_0)) = "0,300"$ und $sqrt(p_1 (1 - p_1)) = "0,336"$, also $n = (("1,96" dot "0,300" + "0,84" dot "0,336") / "0,03")^2 = ("0,8704" / "0,03")^2 approx 842$. Mit den genauen Quantilen (1,960 und 0,8416) sind es 843. *(b)* Bei 100 Fällen am Tag dauert es 8,4 Tage, bis die Zahl erreicht ist; da die Labels erst nach 30 Tagen eintreffen, erscheint der Alarm frühestens nach rund 38 Tagen. Bei 100 Fällen ist das 95-%-Intervall $plus.minus "5,9"$ Punkte breit, ein Rückgang um drei Punkte ist darin nicht zu erkennen. *(c)* Über Größen, die sofort vorliegen: die Verteilung der Eingaben (PSI, siehe S6), die Verteilung der Vorhersagen und der Anteil unsicherer Vorhersagen. Sie ersetzen die Genauigkeit nicht, geben aber früher einen Anlass nachzusehen.
]

=== Reproducibility

#loesung("r1")[
  *(a)* Das Training rechnet $(62 - 40) slash 10 = "2,2"$; $"1,8"$; $"2,6"$. Der Service rechnet mit Mittelwert 62 und Standardabweichung 3,27 der Anfrage und erhält $0$; $-"1,22"$; $"1,22"$. Das Modell hält drei Senioren für Durchschnittskunden. *(b)* Bei einem Kunden ist die Standardabweichung null, die Division scheitert oder liefert `NaN`. *(c)* Training-Serving Skew. Das Pattern Transform verlangt, dass die Konstanten (40 und 10) im Training aus den Trainingsdaten bestimmt, mit dem Modell gespeichert und im Betrieb dieselben sind, am besten als Teil einer Pipeline. Wer den Skalierer vor dem Split auf allen Daten anpasst, begeht Data Leakage: Information aus den Testdaten fließt ins Training.
]

#loesung("r2")[
  #code-aus("05_reproduzierbarkeit.py", "def ist_training", bis: "rng = np.random")
    *(a)* Der Trainingsanteil beträgt 0,795 der Patienten und 0,798 der Zeilen; kein Patient steht auf beiden Seiten; nach 200 neuen Patienten ändert sich keine Zuordnung, weil sie nur von der ID abhängt. Bei einem zufälligen Split wechseln zwischen zwei Seeds im Mittel 32 % der Patienten die Seite (200 Paare; erwartet $2 dot "0,8" dot "0,2" = "0,32"$). *(b)* Die Zahl der Trainingspatienten ist binomialverteilt mit Standardabweichung $sqrt("1 000" dot "0,8" dot "0,2") = "12,6"$, das sind 1,3 Prozentpunkte; 0,795 ist also unauffällig. *(c)* `hash()` ist bei Zeichenketten pro Prozess zufällig gesalzen; derselbe Patient landet in einem anderen Prozess auf der anderen Seite.
]

#loesung("r3")[
  *(a)* Zufällig nach 70 zu 30 zugewiesen stimmt ein Wert mit der Wahrscheinlichkeit $"0,7"^2 + "0,3"^2 = "0,58"$, 42 % sind falsch. *(b)* Immer "Kreditkarte" stimmt zu 70 %. Die "ehrliche" Variante ist die statische Methode: Statt einer Kartenart bekommen die alten Zeilen die Mischung (0,7 Kredit, 0,3 Debit), die Unsicherheit steht dann in der Eingabe selbst. Das Modell sieht aber im Betrieb nie solche Mischwerte. *(c)* Waren die Anteile früher 50 zu 50, stimmt die zufällige Zuweisung nur zu $"0,7" dot "0,5" + "0,3" dot "0,5" = "0,50"$, und das Modell lernt aus den alten Zeilen ein falsches Verhältnis. Die Methode setzt gleiche Anteile in alten und neuen Daten voraus; das ist eine Annahme.
]

#loesung("r4")[
  #ausgabe("05_reproduzierbarkeit.txt", "python 05_reproduzierbarkeit.py", ab: "   messwert", bis: "\nR5")
  *(a)* Batch und Stream liefern dieselben Werte (`np.allclose` bestätigt es). Entscheidend ist, dass die Fensterlogik nur einmal definiert ist und beide Wege sie verwenden. *(b)* Das zentrierte Fenster nimmt auch den nächsten Wert hinzu; in 6 von 7 Zeilen unterscheidet es sich vom Stream. Im Training sähe das Modell damit die Zukunft, die es im Betrieb nie hat. *(c)* Ob man mit den vorhandenen ein bis zwei Werten mittelt (`min_periods=1`) oder die Zeilen verwirft, ist eine Entscheidung, die in Training und Betrieb gleich sein muss.
]

#loesung("r5")[
  #code-aus("05_reproduzierbarkeit.py", "richtig = pd.merge_asof", bis: "neueste = ")
  #ausgabe("05_reproduzierbarkeit.txt", "python 05_reproduzierbarkeit.py", ab: " kunde       zeit", bis: "\nR6")
  Der zeitpunktrichtige Join (`merge_asof` mit `by="kunde"`) gibt jedem Ereignis den zuletzt gültigen Wert: 5, 1, kein Wert (Kunde 2 hatte am 3.3. noch keinen) und 7. Der Join "neuester Wert je Kunde" liefert 1, 1, 3 und 3 und ist bei drei von vier Ereignissen falsch, weil er Werte aus der Zukunft des Ereignisses verwendet. Das ist Leckage, die im Training gut aussieht und im Betrieb nicht reproduzierbar ist.
]

#loesung("r6")[
  *(a)* Eine Ordnung: `ingest`, `clean`, `featurize`, `split`, `train`, `evaluate`, `register`. `featurize` und `split` hängen nur von `clean` ab und können parallel laufen. *(b)* Ändert sich `train`: `train`, `evaluate`, `register` (3 von 7). Ändert sich `split`: `split`, `train`, `evaluate`, `register` (4 von 7), `featurize` bleibt im Cache (@abb-r6). Ändert sich `clean`: alles außer `ingest` (6 von 7). Der Fingerabdruck eines Schritts enthält Code, Parameter und die Fingerabdrücke der Vorgänger, deshalb erbt jeder Schritt die Änderungen davor. *(c)* Ein Zyklus hätte keine Ausführungsreihenfolge: Jeder Schritt in ihm wartet auf einen anderen aus dem Zyklus.

  #figure(
    diagram(
      node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 5pt, spacing: (8mm, 7mm),
      node((0, 0), text(size: 8.5pt)[ingest], fill: luma(242)),
      edge("->"),
      node((1, 0), text(size: 8.5pt)[clean], fill: luma(242)),
      edge((1, 0), (2, -0.5), "->"),
      edge((1, 0), (2, 0.5), "->"),
      node((2, -0.5), text(size: 8.5pt)[featurize], fill: luma(242)),
      node((2, 0.5), text(size: 8.5pt)[split], fill: orange-hell, stroke: 0.8pt + orange),
      edge((2, -0.5), (3, 0), "->"),
      edge((2, 0.5), (3, 0), "->", stroke: 0.8pt + orange),
      node((3, 0), text(size: 8.5pt)[train], fill: orange-hell, stroke: 0.8pt + orange),
      edge((3, 0), (4, 0.5), "->", stroke: 0.8pt + orange),
      edge((2, 0.5), (4, 0.5), "->", stroke: 0.8pt + orange),
      node((4, 0.5), text(size: 8.5pt)[evaluate], fill: orange-hell, stroke: 0.8pt + orange),
      edge((3, 0), (5, 0), "->", stroke: 0.8pt + orange),
      edge((4, 0.5), (5, 0), "->", stroke: 0.8pt + orange),
      node((5, 0), text(size: 8.5pt)[register], fill: orange-hell, stroke: 0.8pt + orange),
    ),
    caption: [Der Graph aus R6. Orange: Schritte, die neu laufen, wenn sich `split` ändert; `ingest`, `clean` und `featurize` kommen aus dem Cache.],
  ) <abb-r6>
]

#loesung("r7")[
  *(a)* Ein neues Pflichtfeld ist eine inkompatible Änderung: Die drei Clients erhalten Fehler, sobald sie auf v2 umgestellt werden. Das nachgelagerte Modell erhält Vektoren aus einem anderen Raum. *(b)* v2 läuft unter eigenem Endpunkt neben v1 (`/v1/…`, `/v2/…`); die Clients wechseln, wenn sie bereit sind, v1 wird erst abgeschaltet, wenn niemand mehr zugreift. Alternativ macht man das Feld optional mit einem Standardwert, dann ist die Änderung kompatibel. In der Registry stehen Version, Eingabestruktur, Trainingsstand und Aliase wie `production` und `canary`. *(c)* Ein neu trainiertes Embedding legt die Achsen neu fest. Die Vektoren von v1 und v2 sind nicht vergleichbar, und ein Modell, das auf einem Raum trainiert wurde, versteht den anderen nicht. Das nachgelagerte Modell muss mit der Version des Embeddings gekoppelt und versioniert werden.
]

=== Responsible AI

#loesung("v1")[
  #code-aus("06_verantwortung.py", "def lieferdaten", bis: "print(\"V1")
  #ausgabe("06_verantwortung.txt", "python 06_verantwortung.py", ab: "Mittelwert der Trainingsdaten", bis: "\nV2")
  *(a)* Die Werte stehen oben. *(b)* Der Maßstab ist die Faustregel mit 5,47 Minuten, nicht der Mittelwert mit 6,84: Er ist die stärkere und zugleich erklärbare Alternative. Die lineare Regression verringert den Fehler gegenüber der Faustregel um 63,5 %. Gradient Boosting bringt nichts (2,02 gegen 2,00 Minuten, minimal schlechter). Das liegt auch an den Daten, die das Skript linear erzeugt; bei Zusammenhängen mit Schwellen und Wechselwirkungen sähe es anders aus. Das Rauschen der Daten legt die Untergrenze des mittleren absoluten Fehlers bei $"2,5" dot sqrt(2 slash pi) = "1,99"$ fest: Die lineare Regression ist praktisch am Optimum, es gibt keine Reserve, die ein komplexeres Modell ausschöpfen könnte. Man nimmt das einfachere.
]

#loesung("v2")[
  *(a)* Die Vorhersage der Baseline ist $8 + 10 + "1,8" + "1,5" = "21,3"$ Minuten, die des Falls $8 + "22,5" + 3 + 5 = "38,5"$. Die Beiträge sind für die Entfernung $"2,5" dot (9 - 4) = "12,5"$, für die Artikel $"0,6" dot (5 - 3) = "1,2"$ und für den Regen $5 dot (1 - "0,3") = "3,5"$. Die Summe 17,2 ist genau die Differenz $"38,5" - "21,3"$. Für ein lineares Modell sind das die exakten Shapley-Werte, das Skript prüft es durch Aufzählen aller Koalitionen. *(b)* Bei der Baseline "trockener Tag" ist die Differenz 18,7 und der Regen trägt 5,0 statt 3,5; die anderen Beiträge bleiben. Eine Erklärung ist immer eine Aussage "gegenüber dieser Baseline", und die Baseline gehört mit der Erklärung angegeben.
]

#loesung("v3")[
  *(a)* Die Erklärung beschreibt, was das Modell tut, nicht, was in der Welt wirkt. Die Postleitzahl ist vermutlich ein Stellvertreter für Merkmale, die nicht im Modell stehen (Einkommensstruktur, Wohnsituation); ein Umzug ändert deren Ursachen nicht. *(b)* Korrelierte Merkmale teilen sich Beiträge oder verdrängen einander, und das Ergebnis hängt von der Baseline und vom Verfahren ab. Dazu können Erklärungsverfahren versagen: Saliency-Verfahren für Bilder liefern teils Karten, die kaum vom Modell abhängen @adebayo_sanity_2018. *(c)* Der Kunde sollte erfahren, welche seiner Angaben die Entscheidung bestimmt haben und welche davon er ändern kann. Dass die Postleitzahl den größten Beitrag hat, ist ein Anlass für die Fairness Lens (Pattern 30): Wirkt sie als Proxy für ein geschütztes Merkmal?
]

#loesung("v4")[
    *(a)* Gruppe A: Genauigkeit 0,86, Auswahlrate 0,38, TPR 0,80, FPR 0,10, Precision 0,842. Gruppe B: Genauigkeit 0,84, Auswahlrate 0,20, TPR 0,60, FPR 0,10, Precision 0,60. Gesamt: $(860 + 420) slash "1 500" = "0,853"$. *(b)* Verletzt: Gleichheit der Chancen (Equal Opportunity @hardt_equality_of_opportunity_2016): Von den Kreditwürdigen in B werden 60 %, in A 80 % angenommen, die Differenz beträgt 0,20. Verletzt ist auch die statistische Parität: Das Verhältnis der Auswahlraten ist $"0,20" slash "0,38" = "0,526"$, unter der Vier-Fünftel-Faustregel aus dem US-Arbeitsrecht (0,8). Erfüllt ist die Gleichheit der False-Positive-Rate (beide 0,10), die Genauigkeit unterscheidet sich kaum. Die Gesamtgenauigkeit verdeckt das Problem. B hat zwar die niedrigere Basisrate (20 % gegen 40 %), was die niedrigere Auswahlrate zum Teil erklärt, nicht aber die niedrigere TPR.

  #figure(
    {
      let d = json("../code/15/fairness_v4.json")
      let balken(name, schluessel) = (
        text(size: 9pt, name),
        box(width: d.A.at(schluessel) * 4.5cm, height: 0.32cm, fill: blau),
        box(width: d.B.at(schluessel) * 4.5cm, height: 0.32cm, fill: orange),
        text(size: 9pt)[#str(calc.round(d.A.at(schluessel), digits: 2)).replace(".", ",") / #str(calc.round(d.B.at(schluessel), digits: 2)).replace(".", ",")],
      )
      grid(columns: (auto, auto, auto, auto), column-gutter: 8pt, row-gutter: 5pt, align: (right + horizon, left + horizon, left + horizon, left + horizon),
        [], text(size: 9pt, fill: blau)[Gruppe A], text(size: 9pt, fill: orange)[Gruppe B], [],
        ..balken("Genauigkeit", "Genauigkeit"),
        ..balken("Auswahlrate", "Auswahlrate"),
        ..balken("TPR", "TPR"),
        ..balken("FPR", "FPR"),
        ..balken("Precision", "PPV"),
      )
    },
    kind: image, supplement: [Abbildung],
    caption: [Kennzahlen der beiden Gruppen aus V4 (Balkenlänge entspricht dem Wert, Skala 0 bis 1). Die Unterschiede liegen bei Auswahlrate, TPR und Precision.],
  )
]

#loesung("v5")[
  *(a)* Precision Gruppe A: $("0,4" dot "0,8") slash ("0,4" dot "0,8" + "0,6" dot "0,1") = "0,32" slash "0,38" = "0,842"$. Gruppe B: $"0,16" slash ("0,16" + "0,8" dot "0,1") = "0,16" slash "0,24" = "0,667"$. Die Auswahlraten sind 0,38 und 0,24. *(b)* Soll B die Precision 0,842 haben, muss die FPR (aus der Formel der Precision nach der FPR aufgelöst) $"TPR" dot "Basisrate" dot (1 - "PPV") slash ("PPV" dot (1 - "Basisrate")) = "0,8" dot "0,2" dot (1 - "0,842") slash ("0,842" dot "0,8") = "0,0375"$ betragen. Dann ist die FPR in den Gruppen verschieden, und die Gleichheit der Chancen fehlt. Bei verschiedenen Basisraten lassen sich gleiche Fehlerraten und gleiche Precision nicht zugleich erreichen, außer bei einer fehlerfreien Vorhersage; das zeigen Kleinberg et al. und Chouldechova @kleinberg_inherent_2016 @chouldechova_fair_prediction_2017. Welches Kriterium gilt, ist eine fachliche und rechtliche Entscheidung, keine technische.
]

#loesung("v6")[
  #code-aus("06_verantwortung.py", "r = np.random.default_rng(5)", bis: "print(f\"Historische")
  #code-aus("06_verantwortung.py", "tr, te = train_test_split(np.arange(n)")
  #ausgabe("06_verantwortung.txt", "python 06_verantwortung.py", ab: "Historische Einstellquote")
    Historisch wurden Personen der Gruppe 1 mit 13,9 % deutlich seltener eingestellt als die der Gruppe 0 (39,4 %). Das Merkmal "Gruppe" ist nicht im Modell, aber der Proxy korreliert mit 0,71 mit ihr. Mit Können und Proxy wählt das Modell 38,1 % der Gruppe 0 und 21,8 % der Gruppe 1 aus: Es hat die Verzerrung der Vergangenheit über den Proxy gelernt. Nur mit dem Können sind es 30,2 % und 29,8 %. Das Entfernen des geschützten Merkmals reicht nicht, solange Stellvertreter bleiben ("Fairness through unawareness" versagt); die Fairness Lens prüft die Auswahl je Gruppe, nicht die Merkmalsliste. Dass das reine Können-Modell gleiche Raten liefert, liegt an der Konstruktion der Daten, in denen das Können unabhängig von der Gruppe ist.
]

=== Szenarien

#loesung("k1")[
  #figure(
    diagram(
      node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 5pt, spacing: (6mm, 6mm),
      node((0, 0), text(size: 8.5pt)[Transaktion], fill: luma(242)),
      edge("->"),
      node((1, 0), text(size: 8.5pt)[Stufe 1: billige \ Merkmale], fill: blau-hell, stroke: 0.8pt + blau),
      edge("->", label: text(size: 8.5pt)[5 %], label-side: left),
      node((2, 0), text(size: 8.5pt)[Stufe 2: teure \ Abfragen], fill: blau-hell, stroke: 0.8pt + blau),
      edge("->"),
      node((3, 0), text(size: 8.5pt)[Alarm mit \ Schlüssel], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((1, 0), (1, 1), "--", stroke: 0.8pt + gruen),
      node((1, 1), text(size: 8.5pt)[Cascade (8), \ Rebalancing (10)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((3, 0), (3, 1), "--", stroke: 0.8pt + gruen),
      node((3, 1), text(size: 8.5pt)[Keyed Predictions (20)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((3, 0), (3, -1), "--", stroke: 0.8pt + gruen),
      node((3, -1), text(size: 8.5pt)[Continued Model \ Evaluation (18)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((0, 0), (0, 1), "--", stroke: 0.8pt + gruen),
      node((0, 1), text(size: 8.5pt)[Transform (21), \ Hashed Feature prüfen (1)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((2, 0), (2, -1), "--", stroke: 0.8pt + gruen),
      node((2, -1), text(size: 8.5pt)[Fairness Lens (30)], fill: gruen-hell, stroke: 0.8pt + gruen),
    ),
    caption: [Zielarchitektur für K1. Grün: Patterns an den Stellen, an denen sie wirken.],
  )
  *(a)* Precision und Recall (und daraus Kosten) statt Genauigkeit; die Regel "nie Betrug" hat 99,9 %, das Modell mit 8 % Recall findet nur 3 200 von 40 000 Fällen. Geeignet sind Gewichte oder Downsampling der Nicht-Betrugsfälle im Training und eine Schwelle nach Kosten; Validierungs- und Testdaten bleiben unverändert, Wahrscheinlichkeiten werden nachkalibriert, wenn sie als Zahl verwendet werden (vgl. P7). *(b)* Stufe 1 nutzt die billigen Merkmale und lässt 5 % durch. Aus $r_1 dot "0,90" >= "0,85"$ folgt $r_1 >= "0,944"$. Die teuren Abfragen kosten dann $"2 000 000" dot "0,05"$ Cent = 1 000 Euro statt 20 000 Euro am Tag. Mit $r_1 = "0,95"$ und einer Fehlalarmrate von 0,1 % in Stufe 2 (Annahme) sind es 34 200 Treffer und rund 1 962 Fehlalarme: Recall 0,855, Precision 0,946, 36 162 Alarme am Tag. *(c)* Keyed Predictions: Jede Transaktion trägt ihren Schlüssel durch den Job, die Zuordnung geschieht über einen Join; Reihenfolge und Wiederholungen spielen dann keine Rolle. *(d)* Continued Model Evaluation: Eingaben, Vorhersageverteilung und Alarmrate sind sofort verfügbar. Den Recall misst man auf Kohorten, deren Labels vollständig sind (Transaktionen älter als 60 Tage), mit einer Stichprobengröße wie in S7. Weil die Betrüger ihre Muster wechseln, gehört ein regelmäßiges Neutrainieren dazu (Workflow Pipeline, Pattern 25). *(e)* Fairness Lens: False-Positive-Rate je Gruppe (0,6 % gegen 0,1 %, Faktor 6). Beim Hashed Feature kollidieren seltene Herkunftsländer mit häufigen und werden von diesen überstimmt: Kleine Gruppen werden unsichtbar.
]

#loesung("k2")[
  #figure(
    diagram(
      node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 5pt, spacing: (6mm, 6mm),
      node((0, 0), text(size: 8.5pt)[Aufnahmen, \ Patienten-ID], fill: luma(242)),
      edge("->"),
      node((1, 0), text(size: 8.5pt)[Split über den Hash \ der Patienten-ID], fill: blau-hell, stroke: 0.8pt + blau),
      edge("->"),
      node((2, 0), text(size: 8.5pt)[Vortrainiertes Netz, \ Kopf, dann obere Blöcke], fill: blau-hell, stroke: 0.8pt + blau),
      edge("->"),
      node((3, 0), text(size: 8.5pt)[Dringlich, normal, \ unklar (an Mensch)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((1, 0), (1, 1), "--", stroke: 0.8pt + gruen),
      node((1, 1), text(size: 8.5pt)[Repeatable \ Splitting (22)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((2, 0), (2, 1), "--", stroke: 0.8pt + gruen),
      node((2, 1), text(size: 8.5pt)[Transfer \ Learning (13)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((3, 0), (3, 1), "--", stroke: 0.8pt + gruen),
      node((3, 1), text(size: 8.5pt)[Neutral Class (9)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((2, 0), (2, -1), "--", stroke: 0.8pt + gruen),
      node((2, -1), text(size: 8.5pt)[Explainable \ Predictions (29)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((3, 0), (3, -1), "--", stroke: 0.8pt + gruen),
      node((3, -1), text(size: 8.5pt)[Fairness Lens (30), \ Model Versioning (27)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((1, 0), (1, -1), "--", stroke: 0.8pt + gruen),
      node((1, -1), text(size: 8.5pt)[Heuristic \ Benchmark (28)], fill: gruen-hell, stroke: 0.8pt + gruen),
    ),
    caption: [Zielarchitektur für K2.],
  )
  *(a)* Bei einer zufälligen Aufteilung steht ein Patient mit vier Aufnahmen mit $1 - "0,8"^4 - "0,2"^4 = "0,589"$ auf beiden Seiten. Das Netz erkennt Patienten wieder (Anatomie, Implantate, Geräteeinstellungen), die 97 % messen teilweise das Gedächtnis, und im Pilot fällt die Genauigkeit auf 81 %. Richtig ist der Split über einen Hash der Patienten-ID (Repeatable Splitting): Der Test hat dann rund 640 Patienten und rund 2 370 Aufnahmen, und die Zuordnung bleibt stabil, wenn Daten dazukommen. Der Pilot am zweiten Haus ist ohnehin der ehrlichste Test. *(b)* Bei rund 9 500 Aufnahmen und einem Quellbereich, der den Röntgenbildern nicht ähnelt, beginnt man mit Feature-Extraction und gibt dann obere Blöcke mit kleiner Lernrate frei (Transfer Learning). Die Uneinigkeit betrifft $"0,22" dot "11 840" = "2 605"$ Aufnahmen. Sie werden eine eigene Klasse "unklar" (Neutral Class), die im Betrieb an einen Radiologen geht, statt eine Pseudo-Entscheidung zu erzwingen. *(c)* Die Heatmap zeigt eine Abkürzung (Shortcut Learning @geirhos_shortcut_2020): Die Station hängt mit der Dringlichkeit zusammen, und das Modell nutzt die Einblendung statt der Lunge. Mit Explainable Predictions findet man das, danach schneidet man die Ecke ab oder maskiert sie und prüft am zweiten Haus. *(d)* Vor das Netz gehört ein Heuristic Benchmark, etwa eine Regel nach Alter und Aufnahmegrund; das Netz muss sie klar schlagen. Jede Vorhersage und Auswertung trägt die Modellversion; Model Versioning betreibt neue Stände neben alten, statt auszutauschen. *(e)* Fairness Lens: Recall dringender Fälle je Altersgruppe. Die Gruppe über 80 ist klein, deshalb Konfidenzintervalle angeben, sonst liest man Zufall als Befund.
]

#loesung("k3")[
  #figure(
    diagram(
      node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 5pt, spacing: (6mm, 6mm),
      node((0, 0), text(size: 8.5pt)[Messwerte \ (Strom)], fill: luma(242)),
      edge("->"),
      node((1, 0), text(size: 8.5pt)[Fensterlogik, \ rückwärts, einmal], fill: blau-hell, stroke: 0.8pt + blau),
      edge("->"),
      node((2, 0), text(size: 8.5pt)[Feature Store \ (zeitpunktrichtig)], fill: blau-hell, stroke: 0.8pt + blau),
      edge("->"),
      node((3, 0), text(size: 8.5pt)[Batch-Job, \ Stücke mit Schlüssel], fill: blau-hell, stroke: 0.8pt + blau),
      edge("->"),
      node((4, 0), text(size: 8.5pt)[Prognose je \ Zähler], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((1, 0), (1, 1), "--", stroke: 0.8pt + gruen),
      node((1, 1), text(size: 8.5pt)[Windowed \ Inference (24)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((2, 0), (2, 1), "--", stroke: 0.8pt + gruen),
      node((2, 1), text(size: 8.5pt)[Feature Store (26)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((3, 0), (3, 1), "--", stroke: 0.8pt + gruen),
      node((3, 1), text(size: 8.5pt)[Batch Serving (17), \ Keyed Predictions (20)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((2, 0), (2, -1), "--", stroke: 0.8pt + gruen),
      node((2, -1), text(size: 8.5pt)[Workflow Pipeline (25), \ Model Versioning (27)], fill: gruen-hell, stroke: 0.8pt + gruen),
      edge((4, 0), (4, -1), "--", stroke: 0.8pt + gruen),
      node((4, -1), text(size: 8.5pt)[Continued Model \ Evaluation (18), \ Heuristic Benchmark (28)], fill: gruen-hell, stroke: 0.8pt + gruen),
    ),
    caption: [Zielarchitektur für K3.],
  )
  *(a)* Erstens nutzt das zentrierte Fenster Werte aus der Zukunft des Prognosezeitpunkts, die es im Betrieb nicht gibt (Leckage). Zweitens rechnet jede Instanz das Merkmal an ihrem Ort mit ihrem Zustand; das verletzt Stateless Serving und erzeugt Skew. Windowed Inference definiert das Fenster einmal, rückwärts, und lässt es im Training auf historischen Daten und im Betrieb auf dem Strom laufen. Der Feature Store hält das Merkmal zeitpunktrichtig vor. *(b)* Hält man alle 96 Werte je Zähler, sind es $"1 500 000" dot 96 dot 8$ Byte = 1,15 GB. Bei festen Fenstern genügen Summe und Anzahl (zwei Zahlen je Zähler), zusammen 24 MB; bei gleitenden Fenstern braucht man die Werte, um alte wieder herauszurechnen. *(c)* $144 dot 10^6 dot 4$ ms sind 160 Stunden; laufen die Aufrufe nacheinander, liegt die Prognose für den nächsten Tag erst nach knapp sieben Tagen vor. Batch Serving bewertet die Messwerte in großen Stücken, jedes Stück läuft mit Schlüssel (Zähler-ID und Zeitpunkt) durch das Modell, Keyed Predictions ordnet die Ergebnisse zu. *(d)* Eine Workflow Pipeline mit Fingerabdrücken je Schritt legt fest, welche Daten und welcher Code zu welchem Artefakt gehören; Model Versioning führt Modelle mit Datenstand und Metriken in einer Registry. *(e)* Eingaben (Temperatur, Verbrauchsverteilung) lassen sich sofort überwachen, der Fehler gegen die tatsächlichen Messwerte liegt einen Tag später vor. Als Maßstab dient ein Heuristic Benchmark wie "derselbe Wert wie vor einer Woche": Sobald das Modell nicht mehr klar besser ist, ist es Zeit zu handeln, und die Fehlerquote beider Verfahren gemeinsam im Zeitverlauf zeigt, ob die Hitzewelle das Modell oder die Welt verändert hat.
]

== Das Wichtigste in Kürze

Nicht jede der 40 Aufgaben fragt nach einem Fehler, aber drei Fehlerformen kehren in allen Kategorien wieder. Die erste ist eine Kennzahl, die die Entscheidung nicht abbildet: Genauigkeit bei seltenen Ereignissen (P4, P5), F1 statt Kosten, ein Sieger, der auf den Testdaten ausgewählt wurde (T6), eine Gesamtgenauigkeit, die Gruppenunterschiede verdeckt (V4). Die zweite ist Information, die im Training anders ist als im Betrieb: ein anderer Skalierer (R1), ein Fenster, das in die Zukunft schaut (R4), ein Feature-Wert zum falschen Zeitpunkt (R5), eine Reihenfolge, die sich beim Verteilen ändert (S5). Die dritte ist eine Annahme, die niemand nachgerechnet hat: Kollisionen (D2), Stufen einer Cascade (P4), die Stichprobe für einen Alarm (S7), die Wahrscheinlichkeit nach Undersampling (P7). Alle drei lassen sich vor dem Einsatz mit einer Rechnung oder einem kleinen Experiment finden, wie die Aufgaben vorführen.

Für die Lehre eignet sich als Übungsblatt für 90 Minuten die Auswahl D2, P5, S3, R2 und V4 mit K1 als Abschlussszenario; die Diagnoseaufgaben (D1, D6, S1, R7) eignen sich als Quizfragen. Die Code-Aufgaben liefern fertige Skripte, an denen sich ein Ergebnis in wenigen Minuten nachvollziehen lässt.

== Weiterführende Literatur

Die Aufgaben folgen dem Buch von #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"). Für die Metriken bei unbalancierten Klassen ist der Überblick von #cite(<he_garcia_imbalanced_2009>, form: "prose") hilfreich, für das Aufteilen von Daten mit Struktur die Arbeit von #cite(<roberts_cross_validation_2017>, form: "prose"), für Drift die Übersicht von #cite(<gama_concept_drift_2014>, form: "prose"). Für Fairness-Kriterien und ihre Grenzen ist das Lehrbuch von #cite(<barocas_fairness_ml_2023>, form: "prose") die ausführlichste Quelle, für Prüfungen vor dem Betrieb der ML Test Score von #cite(<breck_ml_test_score_2017>, form: "prose").

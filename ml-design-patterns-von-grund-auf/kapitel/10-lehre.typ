#import "../lib.typ": *
#import "@preview/cetz-plot:0.1.2": plot

#let orange = rgb("#B5651D")
#let orange-hell = rgb("#FBF1E6")
#let gruen = rgb("#2EAE7D")
#let dunkel = rgb("#24364F")

// Ausgabe eines echten Programmlaufs: Befehl in der Kopfzeile, darunter die gespeicherte Ausgabe.
#let ausgabe(befehl, datei) = raw("$ " + befehl + "\n" + read(datei).trim("\n", at: end), lang: "terminal", block: true)

// Ein Missverständnis (links, orange) mit seiner Richtigstellung (rechts).
#let missv(falsch, richtig) = block(breakable: false, above: 0.4em, below: 0.4em, width: 100%, inset: (y: 0.5em), stroke: (bottom: 0.4pt + luma(215)))[
  #grid(
    columns: (4.1cm, 1fr),
    column-gutter: 0.9em,
    block(width: 100%, inset: (x: 8pt, y: 6pt), fill: orange-hell, stroke: (left: 2.5pt + orange))[
      #set text(size: 9.6pt, style: "italic")
      #set par(justify: false)
      „#falsch“
    ],
    { set text(size: 10.5pt); richtig },
  )
]

// Prüfungsfrage mit Musterantwort
#let frage(nr, pattern, art, frage, antwort) = block(breakable: false, above: 1.1em, below: 1.1em, width: 100%)[
  #text(fill: blau, weight: "bold")[Frage #nr] #h(0.4em) #text(fill: grau, size: 9pt)[#pattern · #art] \
  #text(weight: "bold")[#frage]
  #block(inset: (left: 11pt), spacing: 0.5em, stroke: (left: 1.5pt + luma(200)))[
    #set text(size: 10pt)
    #antwort
  ]
]

= Die Patterns unterrichten

Dieses Kapitel ist für die Lehre geschrieben und setzt voraus, dass Sie die Kapitel 5 bis 10 gelesen haben. Es sammelt, was man zusätzlich braucht, um die Patterns Studierenden zu vermitteln: einen Ablauf, der ML-Grundlagen in 20 Minuten aufbaut, die Missverständnisse, die immer wieder auftreten, Fragen mit Musterantworten, die Verbindung zu den vier Praxisprojekten und eine Anleitung, den Report des Trainers im Coaching zu nutzen. Die Demonstrationen im Kapitel sind lauffähig und liegen unter `code/10-lehre/`; die gezeigten Ausgaben stammen aus tatsächlichen Läufen.

== Der rote Faden der Lehrveranstaltung

Die Studierenden begegnen den Patterns an drei Orten. Die Folien (Deck 07 und 08) erklären das Problem und die Mechanik je Pattern, das Handbuch ist Ihre Vertiefung, und in den Praxisprojekten treffen die Gruppen auf die Symptome in echtem, absichtlich fehlerhaftem Code. Der Trainer prüft, ob die Verträge der Patterns erfüllt sind, und das Coaching übersetzt rote Verträge in Fragen.

#figure(
  diagram(
    node-stroke: 0.7pt,
    node-inset: 7pt,
    node-corner-radius: 3pt,
    spacing: (11mm, 16mm),
    {
      let k(pos, titel, unter, name, farbe: luma(240), schrift: black) = node(pos, align(center)[
        #text(size: 9pt, weight: "bold", fill: schrift)[#titel] \ #text(size: 8.5pt, fill: schrift)[#unter]
      ], fill: farbe, name: name, width: 29mm)
      k((0, 0), [Handbuch], [Verständnis], <hb>)
      k((1, 0), [Deck 07], [ML-Basis, \ Kategorien 1 bis 3], <d7>, farbe: blau, schrift: white)
      k((2, 0), [Deck 08], [Kategorien 4 bis 6], <d8>, farbe: blau, schrift: white)
      k((3, 0), [Projekte], [p1 bis p4], <pr>)
      k((3, 1), [Trainer-Report], [trainer check], <tr>, farbe: rgb("#E6F5EE"))
      k((2, 1), [Coaching], [Fragen], <co>, farbe: rgb("#E6F5EE"))
      k((4, 0), [Abschluss], [Präsentation], <ab>)
      edge(<hb>, <d7>, "->")
      edge(<d7>, <d8>, "->")
      edge(<d8>, <pr>, "->")
      edge(<pr>, <ab>, "->")
      edge(<pr>, <tr>, "->")
      edge(<tr>, <co>, "->")
      edge(<co>, <pr>, "->", bend: 25deg)
    },
  ),
  caption: [Lernorte der Lehrveranstaltung. Der Kreislauf aus Trainer-Report und Coaching läuft während der Projektarbeit mehrfach.],
)

Eine Folge daraus bestimmt, wie Sie unterrichten: Die Gruppen sehen ein Symptom (der Service liefert andere Zahlen als das Training, ein Vertrag ist rot), bevor sie das Pattern beim Namen nennen können. Beginnen Sie deshalb in den Folien mit dem Symptom und führen Sie den Namen erst danach ein. Der Name ist die Abkürzung für eine Lösung, die man zuerst als Problem gespürt haben muss.

== ML-Grundlagen in 20 Minuten

Die Patterns setzen ein kleines Fundament voraus. Wer nicht weiß, warum man Daten in Training und Test teilt, versteht weder Repeatable Splitting noch Rebalancing; wer nicht weiß, was ein Parameter ist, kann nicht erklären, warum Transform Parameter aus dem Training mitführen muss. Die 20 Minuten bauen deshalb fünf Gedanken auf, jeden mit einem Bild aus der Softwareentwicklung. Mathematik bleibt außen vor: kein Backpropagation-Beweis, keine Aktivierungsfunktionen. Die Vorkenntnisse im Hörsaal sind gemischt: Wer schon Modelle trainiert hat, kann Station 1 und 2 auf zwei Minuten kürzen, wer aus der reinen Softwareentwicklung kommt, braucht sie ganz. Eine Frage per Handzeichen zu Beginn („Wer hat schon ein Modell trainiert?“) genügt, um das zu entscheiden.

#figure(
  canvas(length: 1cm, {
    import draw: *
    let stationen = (
      (4, [1 Modell], [Funktion, Parameter]),
      (4, [2 Lernen], [Fehler senken]),
      (5, [3 Generalisieren], [Train/Test, Demo]),
      (4, [4 Messen], [Baseline, Metrik]),
      (3, [5 Betrieb], [Artefakt]),
    )
    let faktor = 16.2 / 20
    let x = 0.0
    for (i, (dauer, titel, unter)) in stationen.enumerate() {
      let b = dauer * faktor
      rect((x, 0), (x + b - 0.1, 1.5), fill: if i == 2 { blau } else { blau-hell }, stroke: 0.6pt + blau, radius: 0.1, name: "s" + str(i))
      content((x + (b - 0.1) / 2, 0.95), text(size: 9pt, weight: "bold", fill: if i == 2 { white } else { dunkel }, titel))
      content((x + (b - 0.1) / 2, 0.42), box(width: (b - 0.4) * 1cm, align(center, text(size: 8.5pt, fill: if i == 2 { white } else { dunkel }, unter))))
      content((x + (b - 0.1) / 2, -0.4), text(size: 8.5pt, fill: grau)[#dauer Min.])
      x += b
    }
    line((0, -0.9), (16.1, -0.9), stroke: 0.5pt + luma(180), mark: (end: ">"))
    content((8, -1.3), text(size: 8.5pt, fill: grau)[Zeit: 20 Minuten, ein einziger Live-Lauf in Station 3])
  }),
  caption: [Zeitplan der 20 Minuten. Station 3 trägt die Demonstration und bekommt deshalb die meiste Zeit.],
)

*Station 1: Ein Modell ist eine Funktion mit gelernten Parametern (4 Minuten).* An die Tafel kommt `miete = w · fläche + b`. Die Fläche ist ein _Feature_ (Eingabe), die Miete das _Label_ (der gewünschte Ausgabewert), `w` und `b` sind _Parameter_. Der Unterschied zu gewöhnlicher Software liegt darin, wer die Zahlen festlegt: Hier schreibt niemand die Regel, sondern man gibt Beispiele vor und lässt die Parameter daraus bestimmen. Parameter sind also Konfigurationswerte, die kein Mensch von Hand setzt, und ein Modell ist die Funktion samt dieser Werte.

*Station 2: Lernen heißt, einen Fehler schrittweise zu verkleinern (4 Minuten).* Eine _Loss Function_ misst, wie falsch die Vorhersagen auf den Trainingsdaten sind. Das Training ändert die Parameter in kleinen Schritten so, dass dieser Wert sinkt, wie ein Wanderer, der im Nebel immer bergab geht. Der _Gradient_ sagt ihm, wo es bergab geht, die _Learning Rate_ legt die Schrittlänge fest. Eine _Epoche_ ist ein Durchlauf durch alle Trainingsdaten, ein _Batch_ die Teilmenge, aus der ein einzelner Schritt berechnet wird. Mehr braucht es hier nicht; die Herleitung steht in Kapitel 2.

*Station 3: Gut auf bekannten Daten heißt nicht gut (5 Minuten).* Das ist die wichtigste Station, und sie bekommt den Live-Lauf unten. Das Bild aus der Softwareentwicklung: Eine Funktion, die genau die vorhandenen Testfälle besteht, weil sie deren Antworten hart kodiert, ist wertlos. Ein Modell, das die Trainingsdaten auswendig lernt (_Overfitting_), tut dasselbe. Deshalb hält man Daten zurück, die das Modell nie gesehen hat (_Test Set_), und beurteilt nur anhand dieser.

*Station 4: Ohne Vergleich bedeutet keine Zahl etwas (4 Minuten).* „90 % richtig“ klingt gut. Gut ist es erst gegenüber einer _Baseline_, etwa der Regel „immer die häufigste Klasse“. Hier fällt in einem Satz auch die erste Warnung: Die _Accuracy_ (Anteil richtiger Vorhersagen) ist bei seltenen Klassen irreführend, denn ein nutzloses Modell kann hohe Werte erreichen. _Precision_ und _Recall_ werden nur genannt (Treffer unter den Alarmen, gefundene unter den echten Fällen); ausführlich folgt es beim Pattern Rebalancing.

*Station 5: Das Modell ist ein Artefakt, und der Betrieb ist der schwierige Teil (3 Minuten).* Training erzeugt eine Datei mit Parametern. Damit sie im Betrieb dasselbe leistet wie im Test, müssen die Eingaben im Betrieb genauso aussehen wie im Training, und jemand muss Daten, Code und Version nachvollziehen können. Der eigentliche ML-Code ist in produktiven Systemen ein kleiner Teil des Ganzen @sculley_hidden_debt_2015. Mit diesem Satz wird die Brücke zu den 30 Patterns geschlagen, die genau diese Lücken schließen.

=== Die Demonstration für Station 3

Alle Beispiele dieses Kapitels laufen mit uv; in den Terminalfenstern steht nur noch der Dateiname.

```terminal
$ uv run --with scikit-learn --with pandas --with numpy \
      python <datei>.py
```

Die gezeigten Ausgaben entstanden mit Python 3.12, scikit-learn 1.9.1, numpy 2.5.4 und pandas 3.1.1; andere Versionen können in den letzten Stellen abweichen.

Das erste Skript trainiert Entscheidungsbäume wachsender Tiefe auf zwei verrauschten, halbmondförmigen Klassen. Ein _Entscheidungsbaum_ stellt dem Beispiel der Reihe nach Ja-Nein-Fragen zu seinen Features („ist x1 größer als 0,3?“) und liest am Ende die Klasse ab; die Tiefe ist die Zahl der Fragen hintereinander. Ein tieferer Baum darf mehr Fragen stellen und kann sich damit den Trainingsdaten immer genauer anpassen.

#raw(read("../code/10-lehre/ml_in_20_minuten.py"), lang: "python", block: true)

#ausgabe("python ml_in_20_minuten.py", "../code/10-lehre/out/ml_in_20_minuten.txt")

#let tiefen = read("../code/10-lehre/out/ml_in_20_minuten.txt").split("\n").map(z => z.match(regex("^\s*(\d+)\s+(\d\.\d+)\s+(\d\.\d+)\s*$"))).filter(m => m != none).map(m => (float(m.captures.at(0)), float(m.captures.at(1)), float(m.captures.at(2))))

#figure(
  canvas(length: 1cm, {
    plot.plot(
      size: (9, 3.5),
      x-label: [Tiefe des Baums],
      y-label: [Accuracy],
      x-min: -0.4, x-max: tiefen.len() - 0.6,
      y-min: 0.7, y-max: 1.02,
      x-tick-step: none,
      x-ticks: tiefen.enumerate().map(((i, t)) => (i, str(int(t.at(0))))),
      y-tick-step: 0.1,
      legend: "inner-south-east",
      {
        plot.add(tiefen.enumerate().map(((i, t)) => (i, t.at(1))), mark: "o", mark-size: 0.14, style: (stroke: 1.2pt + orange), mark-style: (fill: orange, stroke: orange), label: [Training])
        plot.add(tiefen.enumerate().map(((i, t)) => (i, t.at(2))), mark: "o", mark-size: 0.14, style: (stroke: 1.2pt + blau), mark-style: (fill: blau, stroke: blau), label: [Test])
      },
    )
  }),
  caption: [Genauigkeit auf Trainings- und Testdaten bei wachsender Baumtiefe (Werte aus dem Lauf oben).],
)

Zu lesen ist: Die Trainingsgenauigkeit steigt bis auf 1,00, der Baum kennt jeden Trainingspunkt. Auf den Testdaten liegt das Maximum bei 0,90 (Tiefe 2 bis 4) und sinkt danach auf 0,87. Der klare Befund ist die Lücke zwischen 1,00 und 0,87, nicht der kleine Rückgang selbst: Der Testsatz hat nur 120 Beispiele, ein einziger Fall entspricht also gut 0,8 Prozentpunkten, und die Unterschiede zwischen 0,87 und 0,90 liegen im Rauschen. Sagen Sie das den Studierenden ausdrücklich. Es ist die erste Gelegenheit zu zeigen, dass auch eine Testzahl nur eine Schätzung ist. Die Baseline (immer die häufigste Klasse) liegt bei 0,49, der flachste Baum erreicht bereits 0,80.

== Typische Missverständnisse je Kategorie

Missverständnisse lassen sich am besten ausräumen, indem man sie hervorlockt. Stellen Sie die Aussage als Frage („Ein Modell mit 99 % Accuracy: gut oder schlecht?“), lassen Sie abstimmen und zeigen Sie dann die Demonstration. Die folgenden Abschnitte nennen je Kategorie, was Studierende tatsächlich sagen oder annehmen, und die Richtigstellung. Wo ein kurzes Skript das Problem sichtbar macht, ist es im Anschluss gezeigt.

=== Data Representation (Patterns 1 bis 4)

#missv([Embeddings sind dasselbe wie Hashing.])[
  Beide bilden viele Werte auf wenige Zahlen ab, aber auf grundverschiedene Weise. Hashing ist eine feste Rechenvorschrift ohne Training: Welche Werte sich einen Bucket teilen, entscheidet der Zufall, und Ähnlichkeit spielt keine Rolle. Ein Embedding wird zusammen mit dem Modell gelernt und legt Werte, die sich im Modell ähnlich verhalten, nah beieinander.
]

#missv([Mit genug Buckets verliert Hashing nichts.])[
  Kollisionen werden mit mehr Buckets seltener, verschwinden aber nicht. Schon bei etwa der Wurzel aus der Bucketzahl vielen Werten ist mit der ersten Kollision zu rechnen (Geburtstagsparadox). Die Bucketzahl ist ein Kompromiss zwischen Größe und Kollisionsrate, kein Schalter für „verlustfrei“.
]

#missv([Ein gutes Modell findet Kombinationen von allein.])[
  Nur, wenn seine Form es erlaubt. Ein lineares Modell gewichtet jedes Feature für sich und kann „teuer und weit entfernt“ nicht als eigenen Fall erkennen, solange man ihm die Kombination nicht als Feature gibt (Feature Cross). Bäume und Netze können Kombinationen selbst bilden, brauchen dafür aber Kapazität und Daten.
]

Die Demonstration zu Hashing und Embedding nutzt 20 Begriffe aus einem Telekom-Support. Die Bucketnummern kommen aus MD5, weil Pythons eingebaute `hash()`-Funktion für Zeichenketten bei jedem Programmstart anders salzt und damit für Features ungeeignet ist. Für das Embedding genügt eine Matrix aus gemeinsamem Vorkommen, die per Singulärwertzerlegung auf vier Dimensionen verdichtet wird. Das ist kein neuronales Netz wie bei word2vec @mikolov_word2vec_2013, zeigt aber dasselbe Prinzip: Der Vektor eines Wortes entsteht aus den Kontexten, in denen es vorkommt.

#ausgabe("python hashing_vs_embedding.py", "../code/10-lehre/out/hashing_vs_embedding.txt")

Bei 64 Buckets teilen sich zwei Buckets mehrere der 20 Begriffe, bei 8 Buckets sind es vier. Die verwandten Wörter `kuendigung` und `kuendigen` landen bei 64 Buckets in den Fächern 49 und 10; dass sie bei 8 Buckets nebeneinander liegen, ist Zufall und bedeutet nichts. Im Embedding dagegen zeigen ähnliche Wörter fast in dieselbe Richtung (Kosinus 0,99 bis 1,00), Wörter aus verschiedenen Themen stehen im rechten Winkel (0,00). Der Korpus besteht aus nur 17 kurzen Sätzen, die Werte sind deshalb auffallend glatt; auf echten Daten sind die Abstände weniger deutlich.

#figure(
  diagram(
    node-stroke: 0.7pt,
    node-inset: 6pt,
    node-corner-radius: 3pt,
    spacing: (15mm, 8mm),
    {
      let n(pos, t, ..args) = node(pos, align(center, std.text(size: 9pt, t)), ..args)
      node((1, -0.7), align(center, std.text(size: 9pt, weight: "bold", fill: orange)[Hashing: feste Rechenvorschrift, keine Ähnlichkeit]), stroke: none)
      n((0, 0), [`kuendigung`], fill: luma(240))
      n((0, 1), [`kuendigen`], fill: luma(240))
      n((1, 0), [MD5 mod _n_], fill: blau-hell, stroke: 0.7pt + blau)
      n((1, 1), [MD5 mod _n_], fill: blau-hell, stroke: 0.7pt + blau)
      n((2, 0), [Bucket 49], fill: orange-hell, stroke: 0.7pt + orange)
      n((2, 1), [Bucket 10], fill: orange-hell, stroke: 0.7pt + orange)
      edge((0, 0), (1, 0), "->")
      edge((0, 1), (1, 1), "->")
      edge((1, 0), (2, 0), "->")
      edge((1, 1), (2, 1), "->")
      node((3.2, 0.5), align(left, std.text(size: 8.5pt, fill: grau)[Beispiel mit _n_ = 64: \ Bucket und Bedeutung \ hängen nicht zusammen]), stroke: none)

      node((1, 2.4), align(center, std.text(size: 9pt, weight: "bold", fill: gruen)[Embedding: gelernt, Ähnlichkeit bleibt erhalten]), stroke: none)
      n((0, 3.1), [`kuendigung`], fill: luma(240))
      n((0, 4.1), [`kuendigen`], fill: luma(240))
      n((1, 3.6), [gelernte Tabelle], fill: blau-hell, stroke: 0.7pt + blau)
      n((2, 3.1), [Vektor _u_], fill: rgb("#E6F5EE"), stroke: 0.7pt + gruen)
      n((2, 4.1), [Vektor _v_], fill: rgb("#E6F5EE"), stroke: 0.7pt + gruen)
      edge((0, 3.1), (1, 3.6), "->")
      edge((0, 4.1), (1, 3.6), "->")
      edge((1, 3.6), (2, 3.1), "->")
      edge((1, 3.6), (2, 4.1), "->")
      edge((2, 3.1), (2, 4.1), "<->", label: std.text(size: 8.5pt)[nah], label-side: right)
      node((3.2, 3.6), align(left, std.text(size: 8.5pt, fill: grau)[Kosinus _u_, _v_ = 0,99 \ (Lauf oben)]), stroke: none)
    },
  ),
  caption: [Hashing wählt den Bucket per Rechenvorschrift, ein Embedding schlägt gelernte Vektoren nach. Nur Embeddings machen ähnliche Wörter zu Nachbarn.],
)

Für die Feature-Cross-Aussage dient ein Datensatz, in dem die Klasse vom Vorzeichen des Produkts zweier Features abhängt, also von ihrer Kombination und von keinem Feature allein.

#ausgabe("python feature_cross_xor.py", "../code/10-lehre/out/feature_cross_xor.txt")

Ohne Zusatz-Feature erreicht die logistische Regression 0,55, kaum mehr als Raten, denn die beiden Klassen sind etwa gleich häufig. Mit dem Produkt als drittem Feature sind es 0,98. Der Entscheidungsbaum schafft 1,00 ganz ohne Hilfe, weil seine Fragen aufeinander aufbauen und damit Kombinationen bilden. Dem linearen Modell fehlte also nicht Rechenkraft, sondern die passende Darstellung der Eingabe. Das ist der Kern von Feature Cross und eine gute Gelegenheit, den Unterschied zwischen „das Modell ist zu schwach“ und „die Eingabe ist falsch dargestellt“ zu üben.

#let punkte = csv("../code/10-lehre/out/xor_punkte.csv").slice(1).map(z => (float(z.at(0)), float(z.at(1)), int(float(z.at(2)))))

#figure(
  canvas(length: 1cm, {
    import draw: *
    let s = 3.2
    rect((-s, -s), (s, s), stroke: 0.5pt + luma(190))
    line((-s, 0), (s, 0), stroke: 0.5pt + luma(150))
    line((0, -s), (0, s), stroke: 0.5pt + luma(150))
    for (a, b, k) in punkte {
      circle((a * s, b * s), radius: 0.09, fill: if k == 1 { blau } else { orange }, stroke: none)
    }
    content((s + 0.15, 0.35), anchor: "west", text(size: 8.5pt)[Feature 1])
    content((0, s + 0.3), text(size: 8.5pt)[Feature 2])
    content((s + 0.9, 2.3), anchor: "west", text(size: 9pt, fill: blau)[● Klasse 1: gleiche Vorzeichen])
    content((s + 0.9, 1.6), anchor: "west", text(size: 9pt, fill: orange)[● Klasse 0: verschiedene Vorzeichen])
    content((s + 0.9, -1.3), anchor: "west", box(width: 5cm, text(size: 9pt)[Keine Gerade trennt die beiden Farben. Mit dem Produkt als drittem Feature genügt eine Ebene.]))
  }),
  caption: [Die ersten 80 Punkte des Datensatzes. Die Klasse hängt von der Kombination der Features ab.],
)

=== Problem Representation (Patterns 5 bis 10)

#missv([Accuracy reicht als Gütemaß.])[
  Bei seltenen Klassen nicht. Ein Modell, das immer „kein Betrug“ sagt, erreicht bei 1 % Betrug 99 % Accuracy und findet keinen einzigen Fall. Fragen Sie immer nach der Baseline und nach Precision und Recall der seltenen Klasse. Bei starkem Ungleichgewicht ist die Precision-Recall-Kurve aussagekräftiger als die ROC-Kurve @saito_precision_recall_2015.
]

#missv([Mehr Daten lösen das Ungleichgewicht.])[
  Mehr Daten ändern den Anteil nicht: Aus 1 % Betrug werden bei hundertfacher Datenmenge wieder 1 % Betrug, nur in absoluten Zahlen mehr. Einem flexiblen Modell können mehr Fälle der seltenen Klasse helfen; die Accuracy-Falle und der Standardschwellwert 0,5, der für seltene Klassen selten passt, bleiben. Im Lauf unten verharrt der Recall einer logistischen Regression bei hundertfacher Datenmenge bei etwa einem Drittel. Die Maßnahmen heißen Metrik, Klassengewichte, Schwellwert und gegebenenfalls Resampling (die Daten der seltenen Klasse vervielfältigen oder die der häufigen verringern).
]

#missv([Ich gleiche die Klassen aus und teile danach in Training und Test.])[
  Dann stehen Kopien derselben Fälle auf beiden Seiten, und der Test misst Wiedererkennen statt Verallgemeinerung. Resampling gehört ausschließlich auf die Trainingsdaten, nach dem Split. Das ist ein Fall von _Data Leakage_: Information, die im Betrieb nicht vorläge, fließt ins Training oder in die Bewertung @kaufman_leakage_2012.
]

#missv([Multilabel ist Klassifikation mit den k besten Klassen.])[
  Bei Softmax summieren sich die Wahrscheinlichkeiten zu 1; mehrere zutreffende Klassen konkurrieren dann um dieselbe Wahrscheinlichkeitsmasse. Multilabel verwendet pro Label einen eigenen Sigmoid-Ausgang (eine Funktion, die jeden Wert auf eine Zahl zwischen 0 und 1 abbildet), sodass jede Klasse unabhängig bewertet wird, und braucht keine feste Anzahl k.
]

#missv([Ein Ensemble ist immer besser als sein bestes Mitglied.])[
  Im Mittel verbessert es das Ergebnis, wenn die Mitglieder unterschiedliche Fehler machen; Bagging senkt die Varianz @breiman_bagging_1996, Boosting vor allem den Bias (Gradient Boosting: @friedman_gradient_boosting_2001). Zehn identische Modelle bringen nichts, und der Betrieb wird teurer und schwerer erklärbar.
]

#missv([Cascade und Ensemble sind dasselbe.])[
  Im Ensemble beantworten mehrere Modelle parallel dieselbe Frage. In der Cascade zerlegt man die Frage, und die Ausgabe einer Stufe ist Eingabe der nächsten. Fehler früher Stufen setzen sich fort, deshalb gehört eine Cascade in eine gemeinsame Pipeline.
]

#missv([Eine Neutral Class ist nur ein Schwellwert in anderer Verkleidung.])[
  Ein Schwellwert behandelt die Unsicherheit des Modells: „Ich weiß es nicht, frag einen Menschen.“ Eine Neutral Class behandelt Unsicherheit in der Welt: Bei diesen Fällen sind sich auch die Fachleute uneins, und das Modell darf sich bei ihnen sehr sicher sein, dass sie uneindeutig sind.
]

#missv([Reframing ist ein Trick, der Genauigkeit kostet.])[
  Es tauscht Auflösung gegen Information: Die Antwort ist eine Verteilung über Wertebereiche statt einer Zahl, und sie darf mehrgipfelig sein. Das hilft, wo ein einzelner Mittelwert nichts aussagt oder wo Unsicherheit zählt.
]

Die Zahlen zu den ersten drei Aussagen liefert ein Skript: ein Datensatz mit 1 % positiver Klasse, ein Vergleich über wachsende Datenmengen und ein Resampling (hier mit 5 % positiver Klasse) vor und nach dem Split mit einem 1-Nächster-Nachbar-Modell, das Kopien besonders gnadenlos wiedererkennt.

#ausgabe("python accuracy_und_imbalance.py", "../code/10-lehre/out/accuracy_und_imbalance.txt")

Drei Beobachtungen. Erstens: Die logistische Regression ohne Gewichtung erreicht 0,992 Accuracy, das ist nur 0,2 Punkte über der Baseline, aber sie findet 19 % der Betrugsfälle, die Baseline keinen. Mit `class_weight="balanced"` steigt der Recall auf 0,75, die Accuracy fällt auf 0,789, und die Precision sinkt auf 0,03: Auf einen echten Fall kommen etwa dreißig falsche Alarme. Das ist der Preis des Rebalancing, und ob er tragbar ist, hängt davon ab, was ein Alarm kostet.

Zweitens: Die Datenmenge wächst auf das Hundertfache, die Zahl der Betrugsfälle im Training von 22 auf 1990, der Anteil bleibt bei 1 %. Der Recall dieses linearen Modells bewegt sich nicht (0,40, 0,33, 0,35), und die Accuracy liegt stabil bei 0,993 bis 0,994. Für flexiblere Modelle kann mehr Material der seltenen Klasse durchaus helfen; das Skript zeigt nur, dass mehr Daten allein weder Anteil noch Metrik-Falle ändern. Drittens: Wer die Minderheit vor dem Split vervielfältigt, erhält einen Recall von 1,00 und eine Precision von 0,94. Dieselbe Rechnung mit dem Split vor dem Vervielfältigen ergibt 0,27 und 0,43. Die erste Zahl misst, ob das Modell Zwillinge wiedererkennt.

=== Model Training (Patterns 11 bis 15)

#missv([Overfitting ist immer ein Fehler.])[
  Nicht, wenn man gar nicht verallgemeinern muss. Kennt man den gesamten Eingaberaum und ist die Zielfunktion deterministisch, etwa bei einer teuren numerischen Simulation, die ein Modell schneller annähern soll, ist genaues Anpassen an die Trainingsdaten das Ziel. Sobald Eingaben außerhalb des abgedeckten Raums auftreten, ist das Modell unzuverlässig.
]

#missv([Ein Checkpoint ist die Modellversion.])[
  Ein Checkpoint sichert Gewichte und Zustand des Optimierers, damit man ein Training fortsetzen kann. Eine Modellversion muss zusätzlich festhalten, mit welchem Code, welchen Daten, welchen Hyperparametern und welcher Transformation das Modell entstand und wie es bewertet wurde. Ohne diese Angaben kann man ein Modell weder reproduzieren noch begründet zurückrollen.
]

#missv([Ein vortrainiertes Modell ist immer besser als eines von Grund auf.])[
  Nur, wenn die Aufgabe der Vortrainingsaufgabe ähnlich genug ist. Die Übertragbarkeit der Features nimmt mit dem Abstand der Aufgaben ab @yosinski_transferability_2014, und man erbt Verzerrungen des Ausgangsmodells.
]

#missv([Mit doppelt so vielen GPUs dauert das Training halb so lang.])[
  Die Geräte müssen ihre Gradienten abgleichen, und dieser Kommunikationsaufwand wächst. Bei synchronem, datenparallelem Training steigt außerdem die effektive Batchgröße, sodass die Lernrate angepasst werden muss, damit das Modell dieselbe Qualität erreicht @goyal_large_minibatch_2017.
]

#missv([Hyperparameter werden beim Training gelernt, und ich darf sie am Test optimieren.])[
  Hyperparameter legt man vor dem Training fest, nur die Parameter werden gelernt. Die Suche läuft über Validierungsdaten, einen zweiten zurückgehaltenen Teil, an dem man Entwicklungsentscheidungen prüft. Wer an den Testdaten optimiert, verbraucht sie, und die Abschlussbewertung wird zu optimistisch. Zufällige Suche ist bei gleichem Aufwand dem Raster oft überlegen @bergstra_random_search_2012.
]

Die Unterscheidung zwischen Checkpoint und Modellversion lässt sich in einem Bild zeigen:

#figure(
  diagram(
    node-stroke: 0.7pt,
    node-inset: 7pt,
    node-corner-radius: 3pt,
    spacing: (22mm, 14mm),
    {
      let n(pos, t, ..a) = node(pos, align(center, text(size: 9pt, t)), ..a)
      n((1, 0.5), [*Modellversion*\ _v7_], fill: blau, stroke: 0.7pt + blau)
      n((0, 0), [Checkpoint\ (Gewichte)], fill: blau-hell, stroke: 0.7pt + blau)
      n((0, 1), [Code-Stand\ (Commit)], fill: luma(240))
      n((1, -0.5), [Trainingsdaten\ (Stand, Hash)], fill: luma(240))
      n((1, 1.5), [Hyperparameter], fill: luma(240))
      n((2, 0), [Transform-\ Parameter], fill: luma(240))
      n((2, 1), [Metriken und\ Testdaten], fill: luma(240))
      for p in ((0, 0), (0, 1), (1, -0.5), (1, 1.5), (2, 0), (2, 1)) { edge(p, (1, 0.5), "->") }
    },
  ),
  caption: [Eine Modellversion umfasst mehr als einen Checkpoint. Nur das Gesamtbild erlaubt Reproduktion und begründeten Rollback.],
)

#ausgabe("python split_und_version.py", "../code/10-lehre/out/split_und_version.txt")

Nach dem Hinzufügen einer einzigen Zeile wechseln beim Seed-Split 245 von 1000 Kunden die Seite, beim Hash-Split keiner. Das erste Ergebnis hängt an der Reihenfolge und Menge der Daten, das zweite nur an der Kunden-ID. Der Checkpoint nach Epoche 3 und der nach Epoche 10 haben unterschiedliche Gewichte (erkennbar am Hash) und sogar leicht unterschiedliche Trainings-Accuracy (0,850 gegen 0,841): Ein Checkpoint ist ein Zwischenstand, nicht notwendig der beste. Das Manifest zeigt, was zu einer Version gehört; der Code-Hash ist der SHA-256 der Skriptdatei selbst, der Datenhash der der Trainingsdaten. In einem echten Projekt stünden hier der Commit, die Datenversion und der Transform-Parameter.

=== Resilient Serving (Patterns 16 bis 20)

#missv([Das Modell ist der Service.])[
  Der Service besteht aus Vorverarbeitung, Modell und Schnittstelle. Stateless Serving Function heißt, dass diese Funktion keinen Zustand zwischen Aufrufen hält und deshalb beliebig vervielfacht werden kann. Hält ein Notebook oder ein globaler Prozesszustand etwas fest, skaliert das nicht.
]

#missv([Was im Test gut war, bleibt gut.])[
  Die Welt ändert sich. Bei _Data Drift_ verschieben sich die Eingaben, bei _Concept Drift_ der Zusammenhang zur Zielgröße @gama_concept_drift_2014. Continued Model Evaluation vergleicht Vorhersagen laufend mit später eintreffenden Labels; wo Labels verspätet kommen, hilft zunächst die Beobachtung der Eingabeverteilung.
]

#missv([Two-Phase Predictions sind eine Cascade.])[
  Die Struktur ähnelt sich (ein kleines Modell vor einem großen), der Zweck nicht. Two-Phase verteilt die Arbeit nach Ort und Kosten: Ein kleines Modell läuft lokal, etwa auf dem Gerät, und das große in der Cloud wird nur bei Bedarf aufgerufen. Die Cascade zerlegt dagegen die fachliche Frage in Teilfragen, unabhängig davon, wo die Modelle laufen.
]

#missv([Den Schlüssel braucht man nur zum Debuggen.])[
  Bei verteilter und Batch-Verarbeitung ist die Reihenfolge der Ergebnisse nicht garantiert. Der Schlüssel macht die Zuordnung von Ergebnis und Eingabe überhaupt erst möglich und dient später als Verbindungsstelle zur Auswertung. Er darf aber nie als Feature ins Modell gelangen.
]

=== Reproducibility (Patterns 21 bis 27)

#missv([Mit festem Seed ist der Split reproduzierbar.])[
  Nur für exakt dieselben Daten in derselben Reihenfolge. Kommt eine einzige Zeile hinzu, wechseln viele Zeilen die Seite (siehe die Ausgabe oben). Repeatable Splitting leitet die Zuordnung aus einer stabilen Spalte ab, sodass jede Zeile immer dort bleibt, wo sie war.
]

#missv([Transform bedeutet: Daten normalisieren.])[
  Normalisieren ist ein Beispiel. Gemeint ist die gesamte Vorverarbeitung samt den im Training gelernten Parametern (Mittelwert, Vokabular, Bucketgrenzen), die als Teil des Modells exportiert und im Serving identisch angewendet wird. Es ist dasselbe Prinzip wie Single Source of Truth in der Softwareentwicklung.
]

#missv([Ein Feature Store ist eine Datenbank für Features.])[
  Er speichert Definitionen und Werte, bedient Training und Serving mit demselben Code und stellt Features zeitpunktgenau bereit (nur Werte, die zum Ereigniszeitpunkt bekannt waren). Eine gewöhnliche Datenbank leistet das nicht von selbst.
]

=== Responsible AI (Patterns 28 bis 30)

#missv([Eine einfache Regel als Benchmark ist unter dem Niveau eines ML-Projekts.])[
  Sie ist der Prüfstein. Schlägt das Modell „morgen so viel wie heute“ nicht deutlich, lohnt sich sein Betrieb nicht. Außerdem lässt sich ein Fehlerwert nur mit einer Referenz einordnen.
]

#missv([SHAP zeigt, was die Ursache der Entscheidung ist.])[
  SHAP @lundberg_shap_2017 und LIME @ribeiro_lime_2016 berechnen, wie viel jedes Feature zu einer einzelnen Vorhersage beiträgt. Sie erklären damit, wie das Modell zu seiner Vorhersage kommt, nicht, wie die Welt funktioniert. Ein hoher Beitrag des Alters heißt, dass das Modell das Alter nutzt, nicht dass das Alter die Ursache ist.
]

#missv([Ohne das Feature Geschlecht ist das Modell fair.])[
  Andere Features können es mittragen (Proxies, etwa die Postleitzahl für Herkunft). Man prüft Fairness an den Ergebnissen je Untergruppe, nicht an der Feature-Liste.
]

#missv([Es gibt eine richtige Fairness-Kennzahl.])[
  Es gibt mehrere Kriterien, zum Beispiel gleiche Trefferquote @hardt_equality_of_opportunity_2016 oder gleiche Kalibrierung (ein Score von 0,8 trifft in jeder Gruppe bei etwa 80 % der Fälle zu). Unterscheiden sich die Grundraten der Gruppen (der Anteil positiver Fälle), lassen sich zum Beispiel gleiche Fehlerraten und gleiche Kalibrierung nicht zugleich erfüllen, außer bei perfekter Vorhersage @chouldechova_fair_prediction_2017. Welches Kriterium zählt, ist eine fachliche und ethische Entscheidung.
]

== Prüfungs- und Diskussionsfragen

Die folgenden Fragen prüfen Verständnis, keine Wortlaute. Jede lässt sich ohne Nachschlagen beantworten, wenn man die Mechanik hinter dem Pattern begriffen hat. Ein Drittel ist als _Transfer_ markiert: Hier müssen die Studierenden das Gelernte auf eine neue Lage anwenden. Die Fragen eignen sich für eine schriftliche Prüfung ebenso wie als Einzelfragen in der Abschlusspräsentation (16 der 64 Punkte), wo sie sichern, dass jede Person den eigenen Code erklären kann. Die Musterantworten nennen den Kern; eine gute Antwort darf eigene Worte und andere Beispiele verwenden.

#frage(1, [Rebalancing, Heuristic Benchmark], [Verständnis], [Ein Betrugsmodell erreicht 99,2 % Accuracy bei einer Betrugsquote von 1 %. Der Auftraggeber ist zufrieden. Was entgegnen Sie?])[
  Die Baseline „nie Betrug“ erreicht bereits 99 %. Das Modell ist also nur 0,2 Punkte besser, und die Accuracy sagt nichts darüber, ob Betrugsfälle gefunden werden. Man braucht Recall und Precision der Betrugsklasse und eine Abwägung, was ein übersehener Fall und was ein falscher Alarm kosten.
]

#frage(2, [Overfitting, Splitting], [Verständnis], [Ein Modell erreicht im Training 98 %, im Test 71 %. Was ist wahrscheinlich passiert, und was prüfen Sie zuerst?])[
  Das Modell hat sich den Trainingsdaten zu genau angepasst (Overfitting). Zu prüfen sind Komplexität des Modells, Datenmenge und Regularisierung (ein Strafterm, der große Gewichte und damit Komplexität dämpft). Außerdem sollte man klären, ob Training und Test aus derselben Verteilung stammen, etwa nach Zeit. Umgekehrt wäre ein unerwartet gutes Testergebnis der Anlass, nach Data Leakage zu suchen.
]

#frage(3, [Feature Cross], [Verständnis], [Ein lineares Modell soll Fahrpreise schätzen. Der Einfluss der Entfernung ist in der Hauptverkehrszeit deutlich größer. Warum lernt das Modell das nicht von selbst, und was ändern Sie?])[
  Ein lineares Modell addiert gewichtete Beiträge je Feature; der Beitrag der Entfernung hängt dort nicht vom Zeitraum ab. Man ergänzt ein Feature, das Entfernung und Hauptverkehrszeit kombiniert (Feature Cross), oder wählt ein Modell, das Kombinationen von sich aus bilden kann, etwa einen Baum.
]

#frage(4, [Transform], [Transfer], [Im Training wurden Temperaturen mit Mittelwert und Streuung der Trainingsdaten normalisiert. Der Service bekommt Rohwerte. Was passiert, wie bemerkt man es, und welches Prinzip der Softwaretechnik hilft?])[
  Das Modell sieht Zahlen aus einem anderen Wertebereich als im Training und liefert Unsinn, meist ohne Fehlermeldung (Training-Serving Skew). Man bemerkt es an verschobenen Vorhersageverteilungen oder durch einen Vertragstest, der Training und Serving vergleicht. Abhilfe: Die Transformation samt Parametern gehört zum Modellartefakt und existiert genau einmal (Single Source of Truth, DRY).
]

#frage(5, [Repeatable Splitting], [Verständnis], [In einem Kundendatensatz stehen mehrere Zeilen je Kunde. Man teilt zufällig zeilenweise in Training und Test. Wo liegt das Problem?])[
  Zeilen desselben Kunden landen auf beiden Seiten. Das Modell erkennt dann Kunden statt Muster, und der Test fällt zu optimistisch aus. Der Split sollte nach Kunden-ID erfolgen, deterministisch aus deren Hash; bei zeitlichen Daten nach Zeit.
]

#frage(6, [Neutral Class], [Verständnis], [Drei Fachleute ordnen dasselbe Support-Ticket drei verschiedenen Teams zu. Wie gehen Sie beim Labeln und Modellieren damit um?])[
  Die Uneinigkeit ist selbst eine Information. Statt eine Mehrheit zu erzwingen, kann man eine neutrale oder „mehrdeutig“-Klasse einführen oder Mehrfachzuordnung (Multilabel) zulassen. Ein Schwellwert wäre hier die falsche Antwort, denn er beschreibt die Unsicherheit des Modells, nicht die der Daten.
]

#frage(7, [Keyed Predictions, Batch Serving], [Verständnis], [Ein Batch-Lauf über fünf Millionen Datensätze liefert die Vorhersagen in anderer Reihenfolge zurück. Warum, und was tun Sie?])[
  Verteilte Verarbeitung teilt die Daten auf und garantiert keine Ausgabereihenfolge. Jede Instanz bekommt einen eindeutigen Schlüssel, der unverändert in die Ausgabe wandert, sodass sich Ergebnisse zuordnen lassen. Der Schlüssel darf kein Feature des Modells sein.
]

#frage(8, [Continued Model Evaluation], [Transfer], [Ein Modell wurde im Januar mit AUC 0,91 abgenommen (AUC: Gütemaß für die Rangfolge der Vorhersagen, 0,5 entspricht Raten, 1 ist perfekt). Im Juni häufen sich Beschwerden. Wie gehen Sie vor, und wie hätte man es früher gemerkt?])[
  Man vergleicht aktuelle Vorhersagen mit inzwischen bekannten Labels und prüft, ob sich die Eingabeverteilung geändert hat (Data Drift) oder der Zusammenhang (Concept Drift). Früher hätte laufendes Monitoring mit Schwellwerten für Metrik und Eingabeverteilung geholfen. Wo Labels verspätet kommen, ersetzt zunächst die Beobachtung der Eingaben die Metrik.
]

#frage(9, [Model Versioning, Checkpoints], [Verständnis], [Was gehört zu einer Modellversion, und warum genügt der Checkpoint nicht?])[
  Neben den Gewichten: Code-Stand, Trainingsdaten (Stand oder Hash), Hyperparameter, Transform-Parameter, Metriken und die Testdaten, auf denen sie entstanden. Dazu kommt, dass jede Version unter eigener Kennung bereitsteht, damit Clients in Ruhe wechseln können (Pattern 27). Nur damit lässt sich ein Modell reproduzieren, mit einer anderen Version vergleichen und begründet zurückrollen.
]

#frage(10, [Heuristic Benchmark], [Verständnis], [Ein Prognosemodell hat einen mittleren Fehler von 4,2 kWh. Ist das gut?])[
  Das lässt sich ohne Referenz nicht sagen. Man vergleicht mit einer einfachen Regel, etwa „gleiche Stunde der Vorwoche“, und mit dem, was die Entscheidung braucht. Erst die Verbesserung gegenüber der Heuristik und der fachliche Nutzen machen die Zahl aussagekräftig.
]

#frage(11, [Explainable Predictions], [Transfer], [SHAP zeigt „Alter“ als wichtigsten Faktor einer Kreditablehnung. Darf man sagen, das Alter habe die Ablehnung verursacht?])[
  Nein. SHAP zeigt, wie stark das Modell das Feature für diese Vorhersage nutzt, nicht eine Ursache in der Welt. Das Alter kann ein Proxy für anderes sein. Zudem ist zu klären, ob das Feature überhaupt verwendet werden darf.
]

#frage(12, [Fairness Lens], [Transfer], [Das Feature Geschlecht wurde entfernt, trotzdem unterscheiden sich die Fehlerraten zwischen Männern und Frauen. Wie kann das sein, und was prüfen Sie?])[
  Andere Features können das Geschlecht mittragen (Proxies). Man berechnet Kennzahlen je Untergruppe (Slicing), wählt ein Fairness-Kriterium und macht den Zielkonflikt zwischen den Kriterien sichtbar, statt ihn zu verstecken.
]

== Verbindung zu den vier Praxisprojekten

Jedes Projekt enthält absichtlich platzierte Mängel und fachliche ML-Probleme, die sich nur mit konkreten Patterns lösen lassen. Die Zuordnung der Patterns zu den Projekten stammt aus dem Konzept und ist gegen `CONTRACT.md` und `ASSIGNMENT.typ` der vier Projekte abgeglichen (Stand 11. November 2026); die folgende Abbildung zeigt, wie sie sich über die sechs Kategorien verteilen.

#let projekte = ("p1-gridload", "p2-ticketroute", "p3-claimguard", "p4-rentwise")
#let kategorien = ("Data Representation", "Problem Representation", "Model Training", "Resilient Serving", "Reproducibility", "Responsible AI")
// Pattern-Nummern je Projekt (Konzept WS27, Abschnitt 4)
#let zuordnung = (
  (24, 22, 21, 28, 17, 18),
  (1, 6, 9, 19, 20, 29),
  (10, 8, 23, 30, 27, 16),
  (3, 5, 7, 26, 25, 12, 15),
)
#let kategorie-von(n) = if n <= 4 { 0 } else if n <= 10 { 1 } else if n <= 15 { 2 } else if n <= 20 { 3 } else if n <= 27 { 4 } else { 5 }

#figure(
  canvas(length: 1cm, {
    import draw: *
    let zb = 2.3
    let zh = 0.78
    for (j, p) in projekte.enumerate() {
      content((5.1 + j * zb + zb / 2, 0.45), text(size: 9pt, weight: "bold", fill: dunkel, p))
    }
    for (i, k) in kategorien.enumerate() {
      let y = -i * zh
      content((4.9, y - zh / 2), anchor: "east", text(size: 9pt, k))
      for (j, nummern) in zuordnung.enumerate() {
        let hier = nummern.filter(n => kategorie-von(n) == i).sorted()
        let x = 5.1 + j * zb
        rect((x + 0.04, y - 0.04), (x + zb - 0.04, y - zh + 0.04), radius: 0.06,
          fill: if hier.len() == 0 { luma(246) } else { blau.lighten(82% - 9% * hier.len()) },
          stroke: 0.4pt + luma(210))
        if hier.len() > 0 {
          content((x + zb / 2, y - zh / 2), text(size: 8.5pt, fill: dunkel, hier.map(str).join(", ")))
        }
      }
    }
  }),
  caption: [Pattern-Nummern je Projekt und Kategorie nach dem Konzept. Model Training kommt nur in p4-rentwise vor, Data Representation nur in p2 und p4.],
)

Für die Lehre folgt daraus: Die Projekte decken 25 verschiedene der 30 Patterns ab. Pro Projekt prüft der Trainer sechs Pattern-Gruppen zu je zwei Punkten, und die Gruppen müssen mindestens vier davon umsetzen; in p4-rentwise bilden Checkpoints und Hyperparameter Tuning eine gemeinsame Gruppe, und Repeatable Splitting (Pattern 22) bringt dort bis zu zwei Bonuspunkte. Embeddings (2), Multimodal Input (4), Useful Overfitting (11), Transfer Learning (13) und Distribution Strategy (14) kommen in keinem Projekt vor. Diese fünf müssen über Folien, Demonstrationen und die Fragen oben vermittelt werden, nicht über die Projektarbeit. Die folgenden Tabellen ordnen je Projekt ein typisches Symptom dem Pattern zu, das es behebt.

#achtung[#set par(justify: false)
  Eine vollständige Liste der eingebauten Mängel mit Datei und Zeile liegt zum Stand dieser Fassung nur für p1-gridload vor (`_lehrende/p1-gridload/PLANTED-ISSUES.md`); die Symptome von p1 stammen daraus. Für p2 bis p4 sind die Symptome aus den Pattern-Beschreibungen in `ASSIGNMENT.typ` und `CONTRACT.md` abgeleitet und beschreiben, woran man das Problem typischerweise erkennt. Gleichen Sie sie mit den Mängellisten ab, sobald diese vorliegen.]

#let projekt-block(titel, zeilen) = block(above: 1.2em, below: 0.8em, width: 100%)[
  #block(sticky: true, text(weight: "bold")[#titel])
  #v(0.2em)
  #set text(size: 9.8pt)
  #table(
    columns: (1fr, 4.2cm),
    inset: (x: 0.6em, y: 0.36em),
    align: top + left,
    table.header([*Typisches Symptom im Projekt*], [*Pattern*]),
    ..zeilen.flatten(),
  )
]
#let pz(nr, name) = [#nr #name]

#projekt-block("p1-gridload (Stromnetz-Lastprognose, Zeitreihen-Regression)", (
  ([Die rollenden Fenster enden bei $t - 1$, obwohl dieser Wert zum Zeitpunkt der Tagesprognose noch unbekannt ist; der Online-Pfad rechnet sie einmal und nutzt sie für alle 24 Stunden, und ein fehlender Messwert verschiebt alle folgenden Verzögerungen.], pz(24, [Windowed Inference])),
  ([Der Split ist ein zufälliger Zeilen-Split ohne Seed, Testzeilen liegen zwischen Trainingszeilen; die Auswertung teilt noch einmal anders, sodass rund 80 % ihrer Testzeilen im Training waren.], pz(22, [Repeatable Splitting])),
  ([Training und Online-Pfad rechnen verschieden: Heizgradbasis 15,0 statt 15,5, Feiertage ohne bewegliche Feiertage, fehlendes Wetter als feste 10 °C.], pz(21, [Transform])),
  ([Es gibt nur absolute Fehlermaße; ein Vergleichswert wie „gleiche Stunde der Vorwoche“ fehlt.], pz(28, [Heuristic Benchmark])),
  ([Die Prognose läuft pro Station und Stunde mit je einem eigenen Aufruf (Minuten), und die Ausgabe trägt weder Station noch Zeitstempel.], pz(17, [Batch Serving])),
  ([Nichts vergleicht neue Messwerte mit den Prognosen; die Drift ab Oktober bleibt unbemerkt, der Fehler der Prognosen ist etwa doppelt so hoch wie im Test.], pz(18, [Continued Model Evaluation])),
))

#projekt-block("p2-ticketroute (Support-Ticket-Routing, Text)", (
  ([Der Wortschatz ist riesig, und neue Begriffe brechen das Vokabular.], pz(1, [Hashed Feature])),
  ([Tickets betreffen mehrere Teams, das Modell erzwingt genau eines.], pz(6, [Multilabel])),
  ([Teams ordnen ähnliche Tickets uneinheitlich zu; das Modell ist bei mehrdeutigen Fällen überkonfident.], pz(9, [Neutral Class])),
  ([Ein teures Textmodell läuft für jedes Ticket, obwohl ein einfaches die meisten sicher löst.], pz(19, [Two-Phase Predictions])),
  ([Batch-Vorhersagen lassen sich Tickets nicht eindeutig zuordnen.], pz(20, [Keyed Predictions])),
  ([Niemand kann sagen, warum ein Ticket beim falschen Team gelandet ist.], pz(29, [Explainable Predictions])),
))

#projekt-block("p3-claimguard (Versicherungs-Betrugserkennung, unbalanciert)", (
  ([Hohe Accuracy, kaum gefundene Betrugsfälle; oder Resampling vor dem Split.], pz(10, [Rebalancing])),
  ([Verschiedene Schadenarten folgen verschiedenen Mustern; ein Modell mischt sie.], pz(8, [Cascade])),
  ([Das Meldeformular wurde erweitert; alte Fälle haben das neue Feld nicht und fallen aus dem Training.], pz(23, [Bridged Schema])),
  ([Die Quote auffälliger Fälle unterscheidet sich je Region oder Altersgruppe, ohne dass jemand es geprüft hat.], pz(30, [Fairness Lens])),
  ([Ein neues Modell überschreibt das alte; frühere Entscheidungen sind nicht reproduzierbar.], pz(27, [Model Versioning])),
  ([Der Dienst lädt das Modell bei jeder Anfrage oder hält globalen Zustand; die Vorverarbeitung steckt im Notebook.], pz(16, [Stateless Serving Function])),
))

#projekt-block("p4-rentwise (Mietpreis-Schätzung, Regression)", (
  ([Die Lage wirkt je nach Wohnfläche unterschiedlich; ein lineares Modell macht systematische Fehler.], pz(3, [Feature Cross])),
  ([Kundschaft will eine Preisspanne statt eines Punktwerts; die Streuung ist groß.], pz(5, [Reframing])),
  ([Das Einzelmodell schwankt stark mit der Stichprobe.], pz(7, [Ensembles])),
  ([Dieselben Features werden in Training und Service neu berechnet, aus zwei Quellen.], pz(26, [Feature Store])),
  ([Die Schritte laufen von Hand nacheinander und lassen sich nicht einzeln wiederholen.], pz(25, [Workflow Pipeline])),
  ([Ein abgebrochenes Training beginnt von vorn.], pz(12, [Checkpoints])),
  ([Hyperparameter sind geraten oder wurden am Testsatz eingestellt.], pz(15, [Hyperparameter Tuning])),
))

== Den Trainer-Report im Coaching nutzen

Der Trainer (`uv run trainer check`) läuft in jedem Projekt lokal, braucht laut README etwa ein bis drei Minuten und schreibt eine Zusammenfassung sowie `trainer-report.md`. Er prüft statische Analyse gegen eine Baseline, den Testlauf samt Coverage und je Pattern einen Verhaltensvertrag; mit `--only static`, `--only tests` oder `--only patterns` (und `--pattern <name>`) lässt sich ein Teil gezielt wiederholen. Die Verträge rufen nur `contract.py` auf, mit frisch erzeugten Daten. Das Vorgehen unten hängt an den Vertragsnamen, nicht am Layout des Reports. Der Report beantwortet „ist es rot?“, das Coaching „warum, und was lernt die Gruppe daraus?“. Darum gilt: Frage statt Lösung.

#figure(
  diagram(
    node-stroke: 0.7pt,
    node-inset: 7pt,
    node-corner-radius: 3pt,
    spacing: (6mm, 10mm),
    {
      let s(pos, titel, name, ..a) = node(pos, align(center, text(size: 9pt, weight: "bold", titel)), name: name, width: 28mm, ..a)
      s((0, 0), [1 Lesen], <c1>, fill: luma(240))
      s((1, 0), [2 Ordnen], <c2>, fill: luma(240))
      s((2, 0), [3 Benennen], <c3>, fill: luma(240))
      s((3, 0), [4 Fragen], <c4>, fill: blau, stroke: 0.7pt + blau)
      s((4, 0), [5 Neu prüfen], <c5>, fill: rgb("#E6F5EE"), stroke: 0.7pt + gruen)
      edge(<c1>, <c2>, "->")
      edge(<c2>, <c3>, "->")
      edge(<c3>, <c4>, "->")
      edge(<c4>, <c5>, "->")
      edge(<c5>, <c1>, "->", bend: -35deg, label: text(size: 8.5pt)[nächster Termin], label-side: right)
    },
  ),
  caption: [Ablauf eines Coaching-Termins von etwa 15 Minuten je Gruppe.],
)

*Report lesen und Rot ordnen.* Lesen Sie den Report vor dem Termin, nicht währenddessen. Zuerst kommen Verträge, die die Messung selbst verfälschen: Datenleck beim Split und Skew zwischen Training und Serving. Solange sie rot sind, sagt jede Modellzahl wenig, und Tuning wäre vergeudet. Danach folgen Verträge zum Betrieb, zuletzt stilistische Befunde der statischen Analyse. Nehmen Sie sich pro Termin einen Befund vor; eine Gruppe, die fünf Rote auf einmal bekommt, behebt keines verstanden.

*Pattern benennen, Frage stellen.* Die Tabelle zeigt für vier Verträge aus dem Konzept einen Gesprächseinstieg. Er verweist auf das Symptom und nicht auf die Lösung.

#block(breakable: false, table(
  columns: (3.6cm, 1fr, 3.3cm),
  inset: (x: 0.6em, y: 0.45em),
  align: top + left,
  table.header([*Vertrag ist rot*], [*Einstiegsfrage*], [*Pattern*]),
  [Serving liefert andere Features als Training], [„Zeigt mir die Stellen im Code, an denen normalisiert wird. Wie viele sind es?“], [21 Transform],
  [Split ist nicht deterministisch oder nicht gruppiert], [„Was passiert mit euren Testdaten, wenn morgen 1000 Zeilen dazukommen? Kann dieselbe Person in Training und Test stehen?“], [22 Repeatable Splitting],
  [Vorhersagen tragen keinen Schlüssel], [„Wie ordnet ihr im Batch-Ergebnis eine Vorhersage dem Ticket zu, wenn die Reihenfolge nicht stimmt?“], [20 Keyed Predictions],
  [Modell schlägt Heuristik nicht], [„Welche Regel hättet ihr ohne ML gebaut? Wie viel besser ist das Modell wirklich?“], [28 Heuristic Benchmark],
))

*Grün prüfen.* Ein grüner Vertrag zeigt, dass das Verhalten stimmt, nicht, dass die Gruppe es verstanden hat; das gilt besonders, weil LLM-Nutzung erlaubt ist. Lassen Sie eine Person die Lösung in zwei Sätzen erklären und die Alternative nennen, die man hätte wählen können. Das sind die Fragen der ADRs (Entscheidung, Alternative, Preis) und später der Einzelfragen in der Abschlusspräsentation. Wer die Entscheidung nicht begründen kann, hat sie nicht getroffen.

*Coaching und Beurteilung trennen.* Der Trainer liefert laut README 28 der 64 Punkte automatisch (statische Analyse 8, Testsuite 8, ML-Pattern-Verträge 12). Das Coaching bewertet nichts, es bereitet auf die Einzelfragen der Abschlusspräsentation vor (16 Punkte): Wer in den Terminen gelernt hat, eine Entscheidung zu begründen, kann es dort auch.

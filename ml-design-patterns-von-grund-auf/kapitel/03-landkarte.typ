#import "../lib.typ": *

// Lange Tabellen dürfen über Seiten laufen
#show figure.where(kind: table): set block(breakable: true)

= Landkarte der 30 Patterns

Dieses Kapitel setzt die dreißig Patterns zueinander in Beziehung, bevor die Kapitel 5 bis 10 sie einzeln erklären. Es beantwortet drei Fragen: An welcher Stelle eines ML-Projekts wirkt welches Pattern? Welches Symptom deutet auf welches Pattern hin? Und welche Patterns hängen voneinander ab? Die Begriffe stammen aus Kapitel 2; wenn Ihnen zum Beispiel „Training-Serving Skew“ nichts sagt, lesen Sie zuerst den Abschnitt „Begriffe für den Betrieb“ dort.

== Die Patterns am Lebenszyklus

Das Buch gliedert die Patterns nach Themen, nicht nach der Reihenfolge, in der man sie in einem Projekt braucht. Für die Praxis ist die zweite Ordnung oft nützlicher. @abb-landkarte legt deshalb dieselben dreißig Patterns auf den Lebenszyklus aus Kapitel 2: von der Problemformulierung über Features, Training und Evaluation bis zum Betrieb. Die Farbe verrät die Kategorie im Buch, die Nummer das Pattern.

#let kat = (
  dr: (rgb("#D9E6F7"), [Data Representation]),
  pr: (rgb("#DAEEE3"), [Problem Representation]),
  mt: (rgb("#FAE8D3"), [Model Training]),
  rs: (rgb("#E7DDF2"), [Resilient Serving]),
  rp: (rgb("#F4EDC4"), [Reproducibility]),
  ra: (rgb("#F2D8D8"), [Responsible AI]),
)

#let pnode(pos, nr, name, k) = node(
  pos, align(left)[*#nr* #name],
  fill: kat.at(k).at(0), stroke: 0.5pt + luma(150), width: 2.5cm, height: 1.05cm, inset: 4pt,
)
#let kopf(c, titel) = node((c, 0), text(fill: white, weight: "bold")[#titel], fill: blau, stroke: none, width: 2.5cm, height: 0.8cm)

#figure(
  placement: top,
  {
    set text(size: 8.5pt)
    set par(justify: false)
    diagram(
      node-corner-radius: 3pt,
      spacing: (5pt, 6pt),
      kopf(0, [Problem]), kopf(1, [Features]), kopf(2, [Training]), kopf(3, [Evaluation]), kopf(4, [Serving]), kopf(5, [Betrieb]),
      edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"), edge((3, 0), (4, 0), "-|>"), edge((4, 0), (5, 0), "-|>"),
      // Rückkopplung: Drift im Betrieb führt zu neuem Training
      edge((5, 0), (5, -1), (2, -1), (2, 0), "--|>", stroke: 0.7pt + rgb("#B5651D"), label: text(fill: rgb("#B5651D"))[Drift im Betrieb: neu trainieren], label-side: center, label-fill: white, label-pos: 0.5),
      // Problem
      pnode((0, 1), 5, [Reframing], "pr"), pnode((0, 2), 6, [Multilabel], "pr"), pnode((0, 3), 8, [Cascade], "pr"),
      pnode((0, 4), 9, [Neutral Class], "pr"), pnode((0, 5), 10, [Rebalancing], "pr"), pnode((0, 6), 23, [Bridged Schema], "rp"),
      // Features
      pnode((1, 1), 1, [Hashed Feature], "dr"), pnode((1, 2), 2, [Embeddings], "dr"), pnode((1, 3), 3, [Feature Cross], "dr"),
      pnode((1, 4), 4, [Multimodal Input], "dr"), pnode((1, 5), 21, [Transform], "rp"), pnode((1, 6), 26, [Feature Store], "rp"),
      // Training
      pnode((2, 1), 7, [Ensembles], "pr"), pnode((2, 2), 11, [Useful Overfitting], "mt"), pnode((2, 3), 12, [Checkpoints], "mt"),
      pnode((2, 4), 13, [Transfer Learning], "mt"), pnode((2, 5), 14, [Distribution Strategy], "mt"), pnode((2, 6), 15, text(size: 7.8pt)[Hyperparameter Tuning], "mt"),
      // Evaluation
      pnode((3, 1), 22, [Repeatable Splitting], "rp"), pnode((3, 2), 28, [Heuristic Benchmark], "ra"),
      pnode((3, 3), 29, [Explainable Predictions], "ra"), pnode((3, 4), 30, [Fairness Lens], "ra"),
      // Serving
      pnode((4, 1), 16, [Stateless Serving Function], "rs"), pnode((4, 2), 17, [Batch Serving], "rs"), pnode((4, 3), 19, [Two-Phase Predictions], "rs"),
      pnode((4, 4), 20, [Keyed Predictions], "rs"), pnode((4, 5), 24, [Windowed Inference], "rp"),
      // Betrieb
      pnode((5, 1), 18, [Continued Model Evaluation], "rs"), pnode((5, 2), 27, [Model Versioning], "rp"),
    )
    v(0.2em)
    box(width: 100%, height: 0.8cm, fill: kat.rp.at(0), stroke: 0.5pt + luma(150), radius: 3pt, align(center + horizon)[*25* Workflow Pipeline: verbindet alle Stufen zu einem wiederholbaren Ablauf])
    v(0.5em)
    grid(
      columns: (auto,) * 6, column-gutter: 7pt, align: horizon,
      ..kat.values().map(v => box(width: 7pt, height: 7pt, fill: v.at(0), stroke: 0.4pt + luma(150)) + h(3pt) + v.at(1)),
    )
  },
  caption: [Alle 30 Patterns am ML-Lebenszyklus. Jedes Pattern steht dort, wo es hauptsächlich wirkt; manche wirken an mehreren Stellen (Hashed Feature etwa auch beim Serving). Ensembles (7) und Cascade (8) gehören im Buch zur Problem Representation.],
) <abb-landkarte>

Drei Beobachtungen lohnen sich. Erstens liegt die Mitte der Karte nicht dort, wo man sie erwartet: Das Training selbst, das viele für die Hauptsache halten, hat im Buch nur eine eigene Kategorie mit fünf Patterns. Der größere Teil der Patterns betrifft das, was vor und nach dem Training passiert, nämlich Daten, Aufgabenstellung und Betrieb. Zweitens kommt die Kategorie Reproducibility über fast alle Spalten verstreut vor, denn Reproduzierbarkeit ist keine Phase, sondern eine Eigenschaft des ganzen Ablaufs. Drittens ist der Lebenszyklus ein Kreis: Der gestrichelte Pfeil oben bedeutet, dass Beobachtungen aus dem Betrieb ein neues Training auslösen. Genau diese Rückkopplung ist der Grund, warum Continued Model Evaluation (18) und Workflow Pipeline (25) zusammengehören.

== Vom Symptom zum Pattern

In einem Projekt erscheint selten die Frage „Welches Pattern brauche ich?“. Es erscheint ein Symptom: ein Modell, das schlechter wird, eine Spalte, die den Speicher sprengt, ein Ergebnis, das niemand reproduzieren kann. @tab-symptome ordnet typische Symptome den Patterns zu. Sie ist eine Lesehilfe und kein Entscheidungsbaum; oft passen zwei Patterns, und die Kapitel 5 bis 10 beschreiben, wie man zwischen ihnen wählt.

#figure(
  {
    set text(size: 10pt)
    table(
      columns: (1fr, auto, auto),
      align: (left, left, left),
      inset: (x: 0.6em, y: 0.4em),
      table.header([Symptom], [Pattern], [Kap.]),
      table.cell(colspan: 3, fill: luma(240))[*Daten und Features*],
      [Eine kategoriale Spalte hat 50 000 Werte (Postleitzahl, Produkt-ID); One-hot-Kodierung sprengt den Speicher, und zur Laufzeit tauchen neue Werte auf], [1 Hashed Feature, 2 Embeddings], [5],
      [Zwei Features wirken nur gemeinsam (Wochentag und Uhrzeit), ein einfaches Modell sieht die Kombination nicht], [3 Feature Cross], [5],
      [Die Eingabe besteht aus Bild und Tabelle oder Text und Tabelle], [4 Multimodal Input], [5],
      table.cell(colspan: 3, fill: luma(240))[*Aufgabe formulieren*],
      [Eine Zahl vorherzusagen gelingt nicht präzise, die Streuung ist groß], [5 Reframing], [6],
      [Ein Beispiel gehört mehreren Klassen gleichzeitig an (Artikel mit mehreren Schlagwörtern)], [6 Multilabel], [6],
      [Einzelne Modelle schwanken stark zwischen Trainingsläufen], [7 Ensembles], [6],
      [Die Aufgabe zerfällt in Teilfragen, die aufeinander aufbauen, etwa ein Sonderfall vor der eigentlichen Vorhersage], [8 Cascade], [6],
      [Fachleute sind sich bei Grenzfällen uneinig, Etiketten widersprechen sich], [9 Neutral Class], [6],
      [Nur 1 % der Beispiele sind positiv, 99 % Accuracy bedeuten nichts], [10 Rebalancing], [6],
      table.cell(colspan: 3, fill: luma(240))[*Training*],
      [Das Modell soll eine bekannte, deterministische Funktion nachbilden], [11 Useful Overfitting], [7],
      [Ein Trainingslauf dauert Stunden, und ein Absturz kostet alles], [12 Checkpoints], [7],
      [Für die Aufgabe gibt es zu wenige Trainingsdaten], [13 Transfer Learning], [7],
      [Das Training dauert auf einem Rechner zu lange], [14 Distribution Strategy], [7],
      [Hyperparameter werden nach Gefühl gewählt], [15 Hyperparameter Tuning], [7],
      table.cell(colspan: 3, fill: luma(240))[*Serving und Betrieb*],
      [Das Modell hängt am Trainingscode, mehrere Clients wollen es aufrufen], [16 Stateless Serving Function], [8],
      [Eine Million Vorhersagen sollen über Nacht entstehen, nicht einzeln], [17 Batch Serving], [8],
      [Die Qualität sinkt im Betrieb, ohne dass es jemand bemerkt], [18 Continued Model Evaluation], [8],
      [Das große Modell passt nicht auf das Gerät oder die Verbindung fällt aus], [19 Two-Phase Predictions], [8],
      [Batch-Ergebnisse lassen sich den Eingaben nicht zuordnen], [20 Keyed Predictions], [8],
      table.cell(colspan: 3, fill: luma(240))[*Reproduzierbarkeit*],
      [Features werden im Training anders berechnet als im Serving (Training-Serving Skew)], [21 Transform, 26 Feature Store], [9],
      [Die Testmenge ist bei jedem Lauf eine andere, Ergebnisse sind nicht vergleichbar], [22 Repeatable Splitting], [9],
      [Die Datenquelle hat ihr Schema geändert, alte und neue Datensätze passen nicht mehr zusammen], [23 Bridged Schema], [9],
      [Ein Feature braucht ein Zeitfenster früherer Werte (Mittel der letzten Stunde)], [24 Windowed Inference], [9],
      [Der Ablauf besteht aus Notebooks und manuellen Schritten], [25 Workflow Pipeline], [9],
      [Mehrere Teams berechnen dieselben Features mehrfach und verschieden], [26 Feature Store], [9],
      [Niemand weiß, welches Modell diese Vorhersage geliefert hat, ein Rollback ist unmöglich], [27 Model Versioning], [9],
      table.cell(colspan: 3, fill: luma(240))[*Verantwortung*],
      [Niemand weiß, ob das Modell besser ist als eine einfache Regel], [28 Heuristic Benchmark], [10],
      [Betroffene oder Fachbereiche verlangen eine Begründung der Vorhersage], [29 Explainable Predictions], [10],
      [Die Gesamtgenauigkeit stimmt, aber eine Gruppe wird schlechter behandelt], [30 Fairness Lens], [10],
    )
  },
  caption: [Symptome aus Projekten und die Patterns, die dafür infrage kommen.],
  kind: table,
) <tab-symptome>

== Abhängigkeiten zwischen Patterns

Die dreißig Patterns lösen jeweils ein eigenes Problem, aber sie stehen nicht allein. Manche setzen andere voraus, manche lösen dasselbe Problem auf verschiedenen Ebenen, und eines steht in Spannung zu einem anderen. @abb-abhaengigkeiten zeigt die wichtigsten Beziehungen; die Tabelle danach begründet sie. Die Zuordnung ist die Lesart dieses Handbuchs, abgeleitet aus den Pattern-Beschreibungen, und keine vollständige Liste aus dem Buch. Ob das Buch jede einzelne Beziehung ausdrücklich so formuliert, ist nicht für jede Kante geprüft; das gilt als offen.

#figure(
  {
    set text(size: 8.5pt)
    set par(justify: false)
    let n(pos, nr, name, k) = node(pos, align(left)[*#nr* #name], fill: kat.at(k).at(0), stroke: 0.5pt + luma(150), width: 2.95cm, height: 1.0cm, inset: 4pt)
    diagram(
      node-corner-radius: 3pt,
      spacing: (8pt, 14pt),
      // Features
      n((0, 0), 4, [Multimodal Input], "dr"), n((1, 0), 2, [Embeddings], "dr"), n((2, 0), 1, [Hashed Feature], "dr"), n((3, 0), 3, [Feature Cross], "dr"),
      n((1, 1), 13, [Transfer Learning], "mt"),
      // Reproducibility und Serving
      n((1, 2), 26, [Feature Store], "rp"), n((2, 2), 21, [Transform], "rp"), n((3, 2), 16, [Stateless Serving Function], "rs"), n((4, 2), 27, [Model Versioning], "rp"),
      n((1, 3), 24, [Windowed Inference], "rp"), n((2, 3), 20, [Keyed Predictions], "rs"), n((3, 3), 17, [Batch Serving], "rs"),
      n((2, 4), 28, [Heuristic Benchmark], "ra"), n((3, 4), 18, [Continued Model Evaluation], "rs"), n((4, 4), 25, [Workflow Pipeline], "rp"),
      // Kanten
      edge((2, 0), (3, 0), "-|>"),
      edge((1, 0), (3, 0), "-|>", bend: 22deg),
      edge((1, 0), (0, 0), "-|>"),
      edge((1, 1), (1, 0), "-|>"),
      edge((1, 2), (2, 2), "<|-|>"),
      edge((2, 2), (3, 2), "-|>"),
      edge((3, 2), (4, 2), "<|-|>"),
      edge((2, 3), (3, 3), "<|-|>"),
      edge((1, 2), (1, 3), "-|>"),
      edge((1, 3), (3, 2), "<|-|>", stroke: (paint: rgb("#B5651D"), dash: "dashed", thickness: 1.2pt), bend: 20deg),
      edge((2, 4), (3, 4), "-|>"),
      edge((3, 4), (4, 4), "-|>"),
      edge((4, 4), (4, 2), "-|>"),
    )
  },
  caption: [Wichtige Beziehungen zwischen Patterns. Ein Pfeil von A nach B bedeutet: A liefert B einen Baustein, eine Voraussetzung oder einen Auslöser. Doppelpfeile stehen für Patterns, die zusammen eingesetzt werden. Die orange gestrichelte Linie markiert eine Spannung.],
) <abb-abhaengigkeiten>

Die folgende Tabelle erklärt die Kanten. Jede Beziehung ist so formuliert, dass Sie sie in der Lehre als Frage verwenden können: „Warum braucht Pattern A das Pattern B?“

#figure(
  {
    set text(size: 10pt)
    table(
      columns: (5.4cm, 1fr),
      align: (left, left),
      inset: (x: 0.6em, y: 0.4em),
      table.header([Beziehung], [Begründung]),
      [21 Transform ↔ 26 Feature Store], [Beide sorgen dafür, dass Training und Serving dieselben Feature-Werte sehen. Transform kapselt die Rechenvorschrift im Modell-Artefakt, der Feature Store speichert berechnete Werte und teilt sie über Modelle hinweg.],
      [21 Transform → 16 Stateless Serving Function], [Die Serving-Funktion soll rohe Eingaben annehmen können. Das gelingt nur, wenn die Transformation Teil des exportierten Modells ist.],
      [20 Keyed Predictions ↔ 17 Batch Serving], [Bei Batch-Vorhersagen verlaufen Ein- und Ausgabe verteilt und in unbekannter Reihenfolge. Ein mitgeführter Schlüssel ordnet jede Vorhersage ihrem Eingabedatensatz zu.],
      [1 Hashed Feature, 2 Embeddings → 3 Feature Cross], [Ein Cross erzeugt sehr viele, meist dünn besetzte Kombinationen. Hashing kann deren Anzahl begrenzen, Embeddings können sie verdichten.],
      [2 Embeddings → 4 Multimodal Input], [Jede Eingabeart (Bild, Text, Zahl) wird in einen Vektor übersetzt; erst gleichförmige Vektoren lassen sich zu einer Eingabe zusammenfügen.],
      [13 Transfer Learning → 2 Embeddings], [Vortrainierte Embeddings sind eine häufige Form, in der Wissen aus einem anderen Problem übertragen wird.],
      [26 Feature Store → 24 Windowed Inference], [Plausibel, aber vom Handbuch selbst gezogen: Feature-Werte aus einem Zeitfenster früherer Beispiele müssen irgendwo berechnet und vorgehalten werden, und ein Feature Store ist ein möglicher Ort dafür.],
      [24 Windowed Inference ⇢ 16 Stateless Serving Function], [Spannung: Eine zustandslose Funktion kennt keine früheren Beispiele, ein Zeitfenster ist aber Zustand. Der Zustand wandert deshalb aus der Funktion heraus in die vorgelagerte Pipeline.],
      [16 Stateless Serving Function ↔ 27 Model Versioning], [Versionierte Modelle laufen jeweils hinter einer eigenen zustandslosen Schnittstelle, sodass Clients Versionen parallel nutzen oder zurückschalten können.],
      [28 Heuristic Benchmark → 18 Continued Model Evaluation], [Plausibel, aber vom Handbuch selbst gezogen: Die einfache Regel kann auch im Betrieb als Messlatte mitlaufen, an der sich zeigt, ob das Modell seinen Aufwand noch verdient.],
      [18 Continued Model Evaluation → 25 Workflow Pipeline → 27 Model Versioning], [Wenn die Überwachung Qualitätsverlust zeigt, stößt sie die Pipeline an, die ein neues Modell trainiert und als neue Version veröffentlicht.],
    )
  },
  caption: [Begründungen zu den Kanten in @abb-abhaengigkeiten.],
  kind: table,
) <tab-abhaengigkeiten>

== Leicht zu verwechseln

Einige Patterns klingen ähnlich, lösen aber verschiedene Probleme. Wer sie in der Lehre sauber trennt, erspart sich viele Rückfragen.

*Ensembles (7), Cascade (8) und Two-Phase Predictions (19)* verwenden alle mehrere Modelle. Bei einem Ensemble beantworten mehrere Modelle dieselbe Frage, und die Antworten werden zusammengeführt, um genauer und stabiler zu werden. Bei einer Cascade bestimmt das Ergebnis des ersten Modells, was das zweite tut; die Aufgabe ist in Teilfragen zerlegt. Bei Two-Phase Predictions teilt sich das System nach dem Ort des Einsatzes: ein kleines Modell läuft vor Ort, ein großes in der Cloud.

*Transform (21) und Feature Store (26)* verhindern beide, dass Training und Serving verschieden rechnen. Transform arbeitet pro Modell und liegt im Artefakt. Der Feature Store arbeitet pro Organisation und macht berechnete Features wiederverwendbar.

*Rebalancing (10) und Neutral Class (9)* betreffen beide die Klassen eines Klassifikationsproblems. Rebalancing korrigiert eine seltene Klasse, die das Training untergehen lässt. Neutral Class schafft eine zusätzliche Klasse für Fälle, bei denen die Etiketten selbst uneindeutig sind.

*Stateless Serving Function (16) und Batch Serving (17)* beschreiben dasselbe Modell, einmal für einzelne Anfragen in Echtzeit und einmal für große Datenmengen auf einmal. Das Modell bleibt gleich, die Art des Aufrufs ändert sich.

*Explainable Predictions (29) und Fairness Lens (30)* sehen auf verschiedene Ebenen. Das eine erklärt, warum das Modell für einen einzelnen Fall so entschieden hat. Das andere prüft, ob sich das Modell über Gruppen von Fällen hinweg gleich verhält.

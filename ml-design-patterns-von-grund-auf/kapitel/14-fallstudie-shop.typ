#import "../lib.typ": *
#import "@preview/cetz-plot:0.1.2": plot

#set figure(placement: auto)

// Lokale Hilfen. Alle Zahlen, Tabellen und Abbildungen dieses Kapitels stammen aus den Läufen in
// code/14/ (Ausgaben in code/14/ausgabe/, Werte für Abbildungen in code/14/*.json).
#let gruen = rgb("#2EAE7D")
#let orange = rgb("#B5651D")
#let orange-hell = rgb("#FBF1E6")
#let gruen-hell = rgb("#E4F5EE")
#let nebel = luma(240)
#let violett = rgb("#7B5EA7")

#let code-aus(datei, ab, bis: none, nr: 0) = {
  let zeilen = read("../code/14/" + datei).split("\n")
  let a = zeilen.enumerate().filter(((i, z)) => z.contains(ab)).at(nr).at(0)
  let b = if bis == none { zeilen.len() } else { a + 1 + zeilen.slice(a + 1).position(z => z.contains(bis)) }
  block(breakable: b - a > 14, raw(zeilen.slice(a, b).join("\n").trim("\n", at: end), lang: "python", block: true))
}
#let umbruch(befehl) = {
  // lange Befehle vor "--with" und "python" umbrechen, damit kein Argument mitten im Wort getrennt wird
  let zeilen = ()
  let cur = ""
  for t in befehl.split(" ") {
    if cur != "" and cur.len() + t.len() > 58 and (t == "python" or t == "--with") {
      zeilen.push(cur + " \\")
      cur = "    " + t
    } else {
      cur = if cur == "" { t } else { cur + " " + t }
    }
  }
  zeilen.push(cur)
  zeilen.join("\n")
}
#let ausgabe(befehl, datei, von: 0, bis: none) = {
  let z = read("../code/14/ausgabe/" + datei).trim("\n", at: end).split("\n")
  raw("$ " + umbruch(befehl) + "\n" + z.slice(von, bis).join("\n"), lang: "terminal", block: true)
}
#let uv(datei, extra: "") = "uv run --with scikit-learn --with pandas --with numpy" + extra + " python " + datei
#let j(datei) = json("../code/14/" + datei)

// Zahlen im deutschen Format
#let zahl(x, n: 3) = {
  let s = str(calc.round(x, digits: n)).replace("-", "−")
  let t = s.split(".")
  let nach = if t.len() > 1 { t.at(1) } else { "" }
  while nach.len() < n { nach += "0" }
  if n == 0 { t.at(0) } else { t.at(0) + "," + nach }
}
#let proz(x, n: 1) = zahl(100 * x, n: n) + " %"
#let tsd(x) = {
  let s = str(calc.round(x))
  let teile = ()
  while s.len() > 3 { teile.insert(0, s.slice(s.len() - 3)); s = s.slice(0, s.len() - 3) }
  teile.insert(0, s)
  teile.join("\u{202F}")
}

#let dez(v) = str(calc.round(v, digits: 3)).replace(".", ",")
#let daten-plot(..args) = block(width: 100%, align(center, text(size: 9pt, canvas(length: 1cm, {
  draw.set-style(axes: (stroke: 0.6pt, tick: (stroke: 0.5pt)))
  let n = args.named()
  let fmt = (:)
  if "y-format" not in n { fmt.insert("y-format", dez) }
  if "x-format" not in n { fmt.insert("x-format", dez) }
  plot.plot(..fmt, ..args)
}))))
#let knoten(pos, body, farbe: blau, grund: blau-hell, ..args) = node(pos, body, stroke: farbe, fill: grund, ..args)
#let neben(pos, body, ..args) = node(pos, body, stroke: 0.6pt + luma(150), fill: nebel, ..args)
#let erklaere(body, frage, antwort) = kasten([So erkläre ich es.], {
  body
  parbreak()
  [*Verständnisfrage.* #frage]
  parbreak()
  [*Antwort.* #antwort]
})
#let tag(nr) = text(size: 8.5pt, fill: orange, weight: "bold")[Pattern #nr]

#let r3(x) = calc.round(x, digits: 3)
#let gerundet(s) = s.map(r => r + (auc: r3(r.auc), ap: r3(r.ap), einzeln: r3(r.einzeln)))
#let g = gerundet(j("gesamt.json").stufen)

= Fallstudie C: Produktsuche und Kaufwahrscheinlichkeit im Onlineshop

Die Patterns der vorigen Kapitel wurden jeweils an einem eigenen, kleinen Beispiel vorgestellt. Diese Fallstudie setzt acht von ihnen in einem durchgehenden Projekt ein. Dabei zeigt sich, was ein einzelnes Beispiel verbirgt: Patterns ergänzen sich, manche leisten teilweise dasselbe, und eines von ihnen deckt ein Problem auf, das ohne es unbemerkt geblieben wäre.

#kasten([Lernziele.], [Nach diesem Kapitel können Sie an einem durchgängigen Beispiel zeigen, was ein Hashed Feature gegenüber einem Wörterbuch kostet, wie ein Embedding aus Ko-Klick-Daten durch Matrixfaktorisierung entsteht, warum ein Feature Cross mehr leistet als zusätzliche Spalten, wann sich eine Cascade lohnt, woran man ein Datenleck in Popularitätsfeatures erkennt und wie ein Dienst mit zwei Modellversionen aussieht. Sie lernen außerdem, die Wirkung mehrerer Patterns ehrlich zu bewerten, wenn sie sich nicht einfach addieren.])

== Ausgangslage: ein Shop, ein Score, drei Probleme

Ein Onlineshop für Outdoor- und Sportartikel führt zu Beginn rund 20 000 Produkte aus zwölf Kategorien von 800 Marken, jeden Tag kommen etwa 50 neue dazu. Jedes Produkt hat eine ID, eine Kategorie, eine Marke, einen Preis und einen Titel wie "Trail Ultraleicht Laufweste Pro". Aus den Klickdaten soll ein Modell lernen, mit welcher Wahrscheinlichkeit eine Sitzung mit einem Kauf endet. Vorhergesagt wird nach der dritten angesehenen Produktseite. Mit dem Score entscheidet der Shop, ob er eine Hilfe oder einen Gutschein einblendet und zu welcher Kategorie. Der Score steuert also andere Entscheidungen, und deshalb zählt neben seiner Trennschärfe auch, dass die Wahrscheinlichkeiten stimmen.

*Die Daten sind synthetisch.* Das Skript `code/14/shop.py` erzeugt 23 500 Produkte (20 000 zum Start, 50 Neuzugänge pro Tag über 70 Tage) und 150 000 Sitzungen mit mindestens drei Produktansichten, im Mittel 3,8. Jedes Produkt gehört zu einer _Welt_, einem Anlass wie Camping oder Golf. Besucher stöbern überwiegend innerhalb einer Welt; die Welt steckt in den Titelwörtern, aber in keiner Tabellenspalte. Eingebaut sind außerdem Effekte: Marken und Welten verkaufen unterschiedlich gut, in manchen Kategorien wird eher das günstige, in anderen eher das teure Modell gekauft, Titelzusätze wie "Pro" helfen, und Produkte, die in der Vorwoche oft gekauft wurden, werden eher wieder gekauft. Die Fallstudie zeigt, wie man solche Zusammenhänge findet und im Betrieb hält, nicht, wie stark sie in einem echten Shop wären. Mit festem Zufallssamen liefert jeder Lauf dieselben Zahlen. `code/14/run_all.sh` führt alle Skripte in der Reihenfolge ihrer Nummern aus (rund dreieinhalb Minuten); das dritte legt die Embedding-Tabelle ab, die spätere Skripte lesen.

*Drei Probleme.* Erstens hohe Kardinalität: Produkt-ID und Marke haben tausende Werte, die meisten selten. Zweitens gemischte Eingaben: Die Tabelle sagt wenig darüber, welche Produkte zusammengehören; der Titeltext verrät es, und ein Teil steckt im Verhalten der Besucher, die ähnliche Produkte gemeinsam ansehen. Drittens der Betrieb: Es kommen laufend neue Produkte dazu, die Beliebtheit ändert sich täglich, und das Modell muss als Dienst erreichbar sein, den man austauschen kann, ohne den Shop zu stören. @shop-abb-landkarte zeigt, wo in der Verarbeitungskette welches Pattern ansetzt.

#figure(
  diagram(
    node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 5pt, spacing: (13mm, 15mm),
    neben((2, 0), text(size: 9pt)[Ereignisprotokoll \ Ansichten, Käufe]),
    knoten((1, 0), text(size: 9pt)[Popularität der \ letzten 7 Tage \ #tag(26)], grund: orange-hell, farbe: orange),
    neben((0, 0), text(size: 9pt)[Sitzung nach der \ 3. Ansicht]),
    knoten((0, 1), text(size: 9pt)[Merkmalsbau \ #tag(1) Hashed Feature \ #tag(2) Embeddings \ #tag(3) Feature Cross \ #tag(4) Multimodal Input], grund: blau-hell),
    knoten((1, 1), text(size: 9pt)[Stufe 1: \ kauft die \ Sitzung? \ #tag(8)], grund: blau-hell),
    knoten((2, 1), text(size: 9pt)[Stufe 2: \ welche \ Kategorie? \ #tag(8)], grund: blau-hell),
    knoten((3, 1), text(size: 9pt)[Dienst \ /v1 und /v2 \ #tag(16) #tag(27)], grund: gruen-hell, farbe: gruen),
    edge((2, 0), (1, 0), "->"),
    edge((1, 0), (0, 1), "->"),
    edge((0, 0), (0, 1), "->"),
    edge((0, 1), (1, 1), "->"),
    edge((1, 1), (2, 1), "->"),
    edge((2, 1), (3, 1), "->"),
  ),
  caption: [Wo die acht Patterns in der Verarbeitungskette ansetzen. Die Nummern sind die Pattern-Nummern des Buchs.],
) <shop-abb-landkarte>

=== Die Messlatte

Bevor man ein Modell verbessert, muss feststehen, woran man Verbesserung misst. Die Daten werden _nach der Zeit_ geteilt: Tag 0 bis 49 zum Training (107 377 Sitzungen), Tag 50 bis 69 zum Test (42 623). Das entspricht dem Betrieb, in dem das Modell immer Sitzungen der Zukunft bewertet, und nur so treten im Test neue Produkte auf (zeitliche Splits: Pattern 22, Repeatable Splitting). Es kaufen 6,8 % der Sitzungen. Gemessen wird dreifach: Die _AUC_ (Fläche unter der ROC-Kurve) ist die Wahrscheinlichkeit, dass eine zufällige Kaufsitzung einen höheren Score erhält als eine zufällige Sitzung ohne Kauf (0,5 ist Raten, 1,0 perfekte Trennung). Die _Average Precision_ (AP) fasst die Precision-Recall-Kurve zusammen und ist bei seltenen Käufen empfindlicher; Zufall erreicht nur den Kaufanteil 0,068. Der _Log-Loss_ bestraft falsche Wahrscheinlichkeiten; kleiner ist besser.

Das _Ausgangsmodell_ ist eine logistische Regression, also ein lineares Modell, das aus der gewichteten Summe der Features eine Wahrscheinlichkeit macht. Es bekommt Kategorie, Gerät, Uhrzeit, den logarithmierten Preis sowie Marke und Produkt-ID als One-Hot-Kodierung über ein Wörterbuch (je Wert eine Spalte, die 1 ist, wenn der Wert vorliegt, sonst 0). Gebaut werden die Features von der Klasse `Merkmale` (`code/14/merkmale.py`), in der jede Zutat der Fallstudie ein Schalter ist und die später unverändert im Dienst läuft. Das ist das Pattern Transform (21) in der einfachsten Form: eine einzige Stelle, an der Rohdaten zu Features werden. Es erreicht eine AUC von #zahl(g.at(0).auc), eine AP von #zahl(g.at(0).ap) und einen Log-Loss von #zahl(g.at(0).logloss, n: 4). Jede Verbesserung muss sich daran messen.

== Pattern 1: Hashed Feature

*Szenario und Problem.* Die Produkt-ID ist das Paradebeispiel einer Kategorie mit hoher Kardinalität. Das Wörterbuch des Ausgangsmodells hat #tsd(g.at(0).spalten - 18) Spalten für ID und Marke zusammen; es muss beim Training erzeugt, mit dem Modell gespeichert und im Dienst identisch geladen werden. Schwerer wiegt der Kaltstart: Im Test kommt bei jeder dreißigsten Sitzung ein Produkt vor, das im Training nie vorkam, und bei sieben von zehn dieser Sitzungen gehört das Produkt zu den Neuzugängen nach dem letzten Trainingstag (@shop-abb-longtail, rechts). Das Wörterbuch bildet sie auf einen Nullvektor ab. Das Modell stürzt nicht ab, aber es weiß über genau die Produkte nichts, die der Shop gerade bewerben will.

#figure(
  {
    let d = j("daten.json")
    grid(columns: (1fr, 1fr), column-gutter: 10pt,
      daten-plot(size: (5.8, 3.5), x-label: [Rang des Produkts nach Ansichten], y-label: [Anteil an allen Ansichten], x-mode: "log", x-tick-step: none, x-ticks: ((1, [1]), (10, [10]), (100, [100]), (1000, [10#super[3]]), (10000, [10#super[4]])), y-min: 0, y-max: 1.0, y-tick-step: 0.25, x-min: 0.8, x-max: 30000, {
        plot.add(d.kumuliert.map(p => (p.at(0), p.at(1))), style: (stroke: 1.2pt + blau))
      }),
      daten-plot(size: (5.8, 3.5), x-label: [Testtag], y-label: [Sitzungen mit unbekanntem Produkt], x-tick-step: 5, y-min: 0, y-max: 0.05, y-tick-step: 0.01, y-format: v => str(calc.round(v * 100, digits: 0)) + " %", x-min: 49, x-max: 70, {
        plot.add(d.unbekannt_tag.map(p => (p.at(0), p.at(1))), style: (stroke: 1.2pt + orange))
      }),
    )
  },
  caption: [Links: Long Tail der Produktansichten. Die beliebtesten 10 % der Produkte vereinen 44 % der Ansichten, die untere Hälfte nur 12 %. Rechts: Anteil der Testsitzungen, deren aktuelles Produkt in keiner Trainingssitzung vorkam. Er wächst mit jedem Tag, weil neue Produkte dazukommen. Werte aus `01_daten.py`.],
) <shop-abb-longtail>

*Die Lösung.* Eine Hashfunktion ersetzt das Wörterbuch durch eine Rechenvorschrift (Grundlagen und Formel stehen im Kapitel Data Representation). Hier ist sie vollständig: Der Wert wird mit MurmurHash3, derselben Funktion, die scikit-learn intern für `FeatureHasher` nutzt, in eine 32-Bit-Zahl verwandelt und modulo der Bucket-Zahl gerechnet. Das Salz ("produkt", "marke") sorgt dafür, dass gleiche Werte in verschiedenen Spalten nicht dieselben Buckets teilen.

#code-aus("merkmale.py", "def bucket", bis: "def position")

Die Kollisionsraten lassen sich messen und mit der Formel $1 - (1 - 1\/B)^(n-1)$ vergleichen. Bei 23 500 IDs und 16 384 Buckets teilen drei Viertel der IDs ihren Bucket mit mindestens einer anderen (76,3 % gemessen, 76,2 % gerechnet). Das klingt dramatisch, spielt aber für das Ergebnis wenig Rolle, weil die Gewichte seltener IDs ohnehin kaum gelernt werden. Entscheidend ist, was mit den häufigen Produkten passiert, und das zeigt nur das Modell.

#figure(
  {
    let h = j("hashed_feature.json")
    grid(columns: (1fr, 1fr), column-gutter: 10pt,
      daten-plot(size: (4.8, 3.3), x-label: [Buckets $B$], y-label: [Anteil mit Kollision], x-mode: "log", x-tick-step: none, x-ticks: ((100, [10#super[2]]), (1000, [10#super[3]]), (10000, [10#super[4]]), (100000, [10#super[5]])), y-min: 0, y-max: 1.05, y-tick-step: 0.25, x-min: 40, x-max: 400000, {
        plot.add(h.kollision.map(p => (p.b, p.id)), style: (stroke: 1.2pt + orange), mark: "o", mark-size: 0.13, mark-style: (fill: orange, stroke: none))
        plot.add(h.kollision.map(p => (p.b, p.marke)), style: (stroke: 1.2pt + blau), mark: "o", mark-size: 0.13, mark-style: (fill: blau, stroke: none))
      }),
      daten-plot(size: (4.8, 3.3), x-label: [Buckets $B$ (Produkt-ID)], y-label: [AUC im Test], x-mode: "log", x-tick-step: none, x-ticks: ((256, [2#super[8]]), (1024, [2#super[10]]), (4096, [2#super[12]]), (16384, [2#super[14]]), (65536, [2#super[16]])), y-min: 0.60, y-max: 0.69, y-tick-step: 0.02, x-min: 150, x-max: 110000, {
        plot.add(h.id.slice(2).enumerate().map(((i, r)) => (calc.pow(2, 8 + 2 * i), r.auc)), style: (stroke: 1.2pt + blau), mark: "o", mark-size: 0.13, mark-style: (fill: blau, stroke: none))
        plot.add(((150, h.id.at(1).auc), (110000, h.id.at(1).auc)), style: (stroke: (paint: gruen, dash: "dashed", thickness: 1pt)))
        plot.add(((150, h.id.at(0).auc), (110000, h.id.at(0).auc)), style: (stroke: (paint: luma(120), dash: "dotted", thickness: 1pt)))
      }),
    )
  },
  caption: [Links: gemessene Kollisionsraten für 23 500 Produkt-IDs (orange) und 800 Marken (blau). Rechts: Modellgüte, wenn die Produkt-ID mit $B$ Buckets gehasht wird (blau), gegen Wörterbuch (grün gestrichelt) und gegen den Verzicht auf die ID (grau gepunktet). Die Marke ist in allen Läufen per Wörterbuch kodiert. Werte aus `02_hashed_feature.py`.],
) <shop-abb-hash>

Zwei Dinge fallen auf. Mit $B = 2^14$ erreicht das gehashte Feature eine AUC von #zahl(j("hashed_feature.json").id.at(5).auc) gegenüber #zahl(j("hashed_feature.json").id.at(1).auc) mit Wörterbuch; erst bei $2^16$ Buckets, also mehr Spalten als Produkte, gleicht sich der Abstand aus. Die ID trägt Information (ohne sie sinkt die AUC auf #zahl(j("hashed_feature.json").id.at(0).auc)), weil 44 % aller Ansichten auf die beliebtesten 2350 Produkte entfallen. Und der Vorteil liegt hier nicht im Speicher, denn bei rund 18 000 Produkten im Training ist das Wörterbuch kaum größer als die 16 384 Buckets, sondern im Wegfall der Pflege: keine Zuordnung, die beim Laden im Dienst verloren gehen könnte, und ein neues Produkt landet in einem definierten Bucket, wo es allerdings nur das Gewicht der Produkte erbt, die zufällig denselben Bucket teilen. Für die Marke lohnt sich das Hashen bei 800 Werten nicht (AUC #zahl(j("hashed_feature.json").marke.at(1).auc) mit Wörterbuch, #zahl(j("hashed_feature.json").marke.at(5).auc) bei 1024 Buckets). Der Gewinn wächst mit der Kardinalität; bei zwei Millionen IDs wie im Szenario des Kapitels Data Representation sähe die Rechnung anders aus.

*Trade-offs und Grenzen.* Über neue Produkte sagt der Versuch wenig: Es sind 1391 Testsitzungen mit nur 106 Käufen, die AUC schwankt dort um mehrere Hundertstel, und man kann nur lesen, dass der Hash nicht schadet. Wer für neue Produkte etwas _gewinnen_ will, braucht Information, die nicht an der ID hängt; das leisten die nächsten beiden Patterns. Nicht einsetzen: bei inhaltlich ähnlichen Werten (der Hash zerstört jede Nachbarschaft), bei kleiner Kardinalität und wenn man nachvollziehen muss, welcher Wert welches Gewicht trägt, denn ein Bucket ist ein Gemisch.

*Bezug zu Software Engineering.* Sharding nach Hash des Schlüssels: gleiche Idee, gleiche Entscheidung, die man später kaum ändern kann. Mit einem anderen $B$ ist jedes Gewicht an einen anderen Bucket gebunden, das Modell also ein neues.

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 2, Pattern "Hashed Feature"; #cite(<weinberger_feature_hashing_2009>, form: "prose").

== Pattern 2: Embeddings

*Szenario und Problem.* Das Ausgangsmodell sieht jede ID als etwas Eigenständiges. Es weiß nicht, dass ein Zelt und eine Isomatte, die beide in "Camping"-Sitzungen auftauchen, zusammengehören, obwohl diese Beziehung in den Klickdaten steckt: Eine Sitzung ist eine Sammlung von Produkten, die jemand in einem Zug angesehen hat. Gesucht ist eine Darstellung, in der Produkte, die gemeinsam angesehen werden, nahe beieinanderliegen, und die ein Modell als Eingabe nehmen kann.

*Die Lösung: Matrixfaktorisierung.* Ein Embedding ist ein Vektor aus wenigen Zahlen (hier 32), der ein Produkt beschreibt und gelernt wird. Im Buch von Lakshmanan et al. entsteht er als versteckte Schicht eines neuronalen Netzes, das auf eine Aufgabe trainiert wird. Es geht aber auch ohne Netz, und der Weg zeigt, was ein Embedding mathematisch ist. Drei Schritte:

+ *Ko-Klick-Matrix.* Für jedes Paar von Produkten zählt man, in wie vielen Trainingssitzungen beide angesehen wurden. Das ergibt eine quadratische Matrix $C$ mit einer Zeile und Spalte je Produkt. Im Beispiel hat sie 23 500 mal 23 500 Zellen, von denen 0,218 % belegt sind (1,2 Millionen Zellen, da jedes Paar zweimal vorkommt).
+ *Positive Pointwise Mutual Information.* Rohe Zählungen sind verzerrt, weil beliebte Produkte mit allem gemeinsam vorkommen. Man vergleicht deshalb, wie oft zwei Produkte gemeinsam vorkommen, mit dem Wert, der bei Unabhängigkeit zu erwarten wäre: $ "PMI"(i, j) = log P(i, j) / (P(i) dot P(j)). $ Negative Werte werden auf null gesetzt (PPMI): Paare, die nie gemeinsam vorkamen, hätten ein PMI von minus unendlich, und negative Werte sind bei wenigen Beobachtungen unzuverlässig.
+ *Abgeschnittene Singulärwertzerlegung.* Die Matrix $M$ der PPMI-Werte wird als Produkt $M approx U Sigma V^T$ geschrieben, wobei nur die 32 größten Singulärwerte behalten werden. Nach dem Satz von Eckart und Young ist das die beste Näherung durch eine Matrix vom Rang 32 im Sinn der kleinsten Fehlerquadrate. Die Zeilen von $U Sigma$ sind die Embeddings: Jedes Produkt wird auf 32 Zahlen komprimiert, und Produkte mit ähnlichem Ko-Klick-Profil, also ähnlicher Zeile in $M$, bekommen ähnliche Vektoren.

Das ist eine Matrixfaktorisierung, dasselbe Prinzip, das Empfehlungssysteme seit Langem nutzen @koren_matrix_factorization_2009. Der Zusammenhang zu word2vec @mikolov_word2vec_2013 ist eng: #cite(<levy_goldberg_implicit_2014>, form: "prose") zeigten, dass Skip-Gram mit Negative Sampling implizit eine um $log k$ verschobene PMI-Matrix faktorisiert, und dass eine explizite PPMI-Matrix mit SVD bei Aufgaben zur Wortähnlichkeit konkurrenzfähige Vektoren liefern kann @levy_goldberg_dagan_lessons_2015. Der Unterschied liegt im Rechenweg: word2vec lernt die Faktoren schrittweise mit Gradientenabstieg, ohne die große Matrix je aufzubauen; die SVD baut sie auf und zerlegt sie direkt. Die Implementierung ist kurz:

#code-aus("embedding.py", "def ppmi")

`TruncatedSVD` aus scikit-learn arbeitet mit einem randomisierten Verfahren @halko_randomized_svd_2011 und kann deshalb mit der dünnbesetzten Matrix umgehen, ohne sie dicht zu machen. Die letzten Zeilen normieren jeden Vektor auf Länge 1, damit das Skalarprodukt zweier Produkte dem Kosinus des Winkels zwischen ihnen entspricht. Produkte ohne Ko-Klicks bekommen den Nullvektor.

#ausgabe(uv("03_embeddings.py"), "03_embeddings.txt", von: 0, bis: 10)

Zeigt die Faktorisierung, was sie soll? Für ein Zelt der Welt Camping sind die nächsten Nachbarn (größter Kosinus) eine Hose, ein Rucksack, ein Schuh und eine Uhr, alle aus Camping und alle aus einer anderen Kategorie. Das gibt die Tabelle nicht her: Nähe nach Anlass. Unter den zehn nächsten Nachbarn von 1500 geprüften Produkten stammen #proz(j("embeddings.json").treffer, n: 0) aus derselben Welt (Zufall: #proz(j("embeddings.json").zufall, n: 0)), aber nur 26 % aus derselben Kategorie. Das ist sauberer, als es in einem echten Shop wäre: Der Generator enthält genau eine Struktur, und die Faktorisierung findet sie.

#figure(
  {
    let e = j("embeddings.json")
    let farben = (Camping: gruen, Golf: blau, Tauchen: orange)
    daten-plot(size: (8.0, 4.4), x-label: [erste Hauptachse], y-label: [zweite Hauptachse], x-tick-step: none, y-tick-step: none, legend: "east", legend-style: (stroke: none), {
      for (w, f) in farben {
        plot.add(e.punkte.filter(p => p.welt == w).map(p => (p.x, p.y)), style: (stroke: none), mark: "o", mark-size: 0.16, mark-style: (fill: f.transparentize(25%), stroke: none), label: w)
      }
    })
  },
  caption: [Je 100 Produkte aus drei Welten, deren 32-dimensionale Embeddings auf zwei Achsen projiziert sind (Hauptkomponenten; die beiden Achsen erfassen #proz(j("embeddings.json").anteil_varianz, n: 0) der Varianz). Die Farbe zeigt die Welt, die das Modell nie gesehen hat. Werte aus `03_embeddings.py`.],
) <shop-abb-embedding>

*Wirkung auf das Modell.* `Merkmale` bildet den Mittelwert der Embeddings der drei angesehenen Produkte und hängt die 32 Zahlen als Features an. Das ist die größte Einzelverbesserung der Fallstudie. Verglichen wird mit einem Modell ohne Produkt-ID, damit sich die beiden Informationsquellen nicht vermischen; die AUC steigt von #zahl(j("embeddings.json").modelle.at(0).auc) auf #zahl(j("embeddings.json").modelle.at(1).auc), der Log-Loss fällt von #zahl(j("embeddings.json").modelle.at(0).logloss, n: 4) auf #zahl(j("embeddings.json").modelle.at(1).logloss, n: 4). In der Tabelle steht nirgends "Camping", und doch erkennt das Modell am Vektor, ob die Sitzung in einer verkaufsstarken oder -schwachen Welt stattfindet. Für ein lineares Modell sind die 32 Zahlen vor allem eine Möglichkeit, _Ähnlichkeit_ in einem Feature unterzubringen.

*Kaltstart.* Ein neues Produkt hat keine Ko-Klicks, also keinen Vektor. Eine Brücke zum nächsten Pattern hilft: Eine Ridge-Regression (lineare Regression mit einer Strafe für große Koeffizienten) lernt, aus dem TF-IDF-Vektor des Titels (siehe Pattern 4) den Embedding-Vektor der bekannten Produkte vorherzusagen, und wird auf Produkte ohne Ko-Klicks angewandt. Für 400 solche Produkte stammen dann #proz(j("embeddings.json").bruecke, n: 0) der zehn nächsten bekannten Nachbarn aus der richtigen Welt, und die AUC auf Sitzungen mit neuem Produkt steigt von #zahl(j("embeddings.json").modelle.at(1).auc_neu) auf #zahl(j("embeddings.json").modelle.at(2).auc_neu). Das sind allerdings nur 1391 Sitzungen mit 106 Käufen, der Standardfehler einer einzelnen AUC liegt dort bei etwa 0,03; der Abstand ist ein Hinweis und kein Beleg. Dass die Brücke so gut gelingt, liegt auch daran, dass die Titel hier die Welt nennen. Der Preis: ein zweites Modell, das mitversioniert und mitgeliefert werden muss.

*Trade-offs und Grenzen.* Das Embedding ist ein Artefakt wie das Modell selbst. Ein Modell, das mit Embeddings der Version 1 trainiert wurde, darf nie Embeddings der Version 2 sehen: Die Achsen haben keine feste Bedeutung, ein neues Training dreht und mischt sie. Tabelle und Modell gehören deshalb in dasselbe versionierte Paket (siehe Abschnitt zum Dienst). Außerdem wächst die Kookkurrenzmatrix mit dem Katalog, und die Nachbarschaften geben das Verhalten der Besucher wieder, nicht Eigenschaften der Produkte. Die Tabelle entsteht aus denselben Trainingssitzungen, auf denen das Modell lernt; weil nur Ansichten und keine Käufe eingehen, verrät sie dem Modell nichts über das Ziel, aber im Test sind die Vektoren etwas weniger zuverlässig als im Training. Nicht einsetzen: bei wenigen Werten, die ein Wörterbuch gut lernt, oder wenn es keine Verhaltensdaten gibt, aus denen Nähe entstehen kann.

*Bezug zu Software Engineering.* Ein Embedding verhält sich wie ein Suchindex: offline aufgebaut, online nur gelesen, und bei geändertem Aufbau inkompatibel zu allem, was mit der alten Version gebaut wurde.

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 2, Pattern "Embeddings"; #cite(<mikolov_word2vec_2013>, form: "prose"); #cite(<levy_goldberg_implicit_2014>, form: "prose") sowie #cite(<levy_goldberg_dagan_lessons_2015>, form: "prose"); #cite(<koren_matrix_factorization_2009>, form: "prose"); #cite(<guo_entity_embeddings_2016>, form: "prose").

== Pattern 3: Feature Cross

*Szenario und Problem.* Der Preis eines Produkts beeinflusst die Kaufwahrscheinlichkeit, aber nicht überall gleich. @shop-abb-heat zeigt die Kaufrate je Kategorie und Preisband in den Trainingsdaten. Bei Schuhen, Hosen, Zelten und Kochern sinkt sie mit steigendem Preis, bei Jacken, Rucksäcken, Helmen und Fahrradteilen steigt sie. Die Kundschaft sucht in der einen Kategorie das günstige Modell und in der anderen das Qualitätsprodukt. Das ist im Generator so angelegt, aber so etwas findet man auch in echten Daten, etwa wenn Kunden bei Verbrauchsmaterial sparen und beim Dauerläufer investieren.

Ein lineares Modell kann dieses Muster nicht abbilden, wenn Kategorie und Preis getrennte Features sind. Es lernt ein Gewicht für den Preis, das für alle Kategorien gleich ist, und ein Gewicht für jede Kategorie, das für alle Preise gleich ist. Gegenläufige Effekte heben sich im Mittel auf. Das zeigt der Versuch: Zerlegt man den Preis in acht Bänder und gibt dem Modell diese Bänder zusätzlich, ändert sich fast nichts (alle Modelle dieses Abschnitts ohne Produkt-ID; AUC #zahl(j("feature_cross.json").modelle.at(0).auc) auf #zahl(j("feature_cross.json").modelle.at(1).auc)).

#figure(
  {
    let d = j("feature_cross.json")
    let bands = ("<20", "<40", "<80", "<150", "<250", "<400", "<700", ">700")
    let br = 1.15
    let ho = 0.52
    align(center, canvas(length: 1cm, {
      import draw: *
      set-style(stroke: 0.4pt + white)
      for (i, b) in bands.enumerate() {
        content((2.6 + i * br + br / 2, 0.45), text(size: 8.5pt, b))
      }
      content((2.6 + 8 * br / 2, 0.95), text(size: 8.5pt, fill: grau)[Preisband in Euro])
      for (r, k) in d.kategorien.enumerate() {
        let y = -r * ho
        content((2.45, y - ho / 2), anchor: "east", text(size: 8.5pt, k))
        for b in range(8) {
          let w = d.rate.at(r * 8 + b).at(2)
          if w == none {
            rect((2.6 + b * br, y), (2.6 + (b + 1) * br, y - ho), fill: luma(245), stroke: 0.6pt + white)
          } else {
            let f = calc.min(w / 0.20, 1)
            rect((2.6 + b * br, y), (2.6 + (b + 1) * br, y - ho), fill: color.mix((blau, f * 100%), (white, (1 - f) * 100%)), stroke: 0.6pt + white)
            content((2.6 + b * br + br / 2, y - ho / 2), text(size: 8.5pt, fill: if f > 0.55 { white } else { black }, str(calc.round(w * 100, digits: 0)).replace(".0", "")))
          }
        }
      }
    }))
  },
  caption: [Kaufrate in Prozent je Kategorie und Preisband (Trainingstage). Leere Zellen haben weniger als 200 Sitzungen oder kommen nicht vor. Die Richtung des Preiseffekts wechselt von Zeile zu Zeile. Werte aus `04_feature_cross.py`.],
) <shop-abb-heat>

*Die Lösung.* Ein Feature Cross bildet aus zwei Merkmalen ein neues, das jede Kombination als eigenen Wert führt: "Zelte|Band 5" ist eine Spalte, "Jacken|Band 5" eine andere. Das Modell kann damit pro Zelle ein Gewicht lernen. Bei zwölf Kategorien und acht Bändern entstehen 96 Spalten; die Zahl wächst mit dem Produkt der Wertezahlen, und sobald sie unhandlich wird, kann man das Cross hashen (Pattern 1). In `Merkmale` steckt das in wenigen Zeilen:

#code-aus("merkmale.py", "        if self.kreuz:", bis: "        if self.text:")

Das Ergebnis: Die AUC steigt auf #zahl(j("feature_cross.json").modelle.at(2).auc), der Log-Loss fällt von #zahl(j("feature_cross.json").modelle.at(0).logloss, n: 4) auf #zahl(j("feature_cross.json").modelle.at(2).logloss, n: 4). Der Gewinn kommt nicht aus mehr Information, denn Kategorie und Preis kannte das Modell schon, sondern aus einer anderen _Form_: Es darf jetzt sagen, dass sich der Preis je Kategorie unterschiedlich auswirkt. Ein Entscheidungsbaum oder ein neuronales Netz könnte solche Wechselwirkungen von selbst lernen, ein lineares Modell nicht. Das Pattern gibt einem einfachen Modell mit Domänenwissen einen Sprung, den man sonst mit einem komplexeren Modell erkaufen müsste. Gekreuzte Merkmale bilden auch den linearen "Wide"-Teil von Wide & Deep, der Kombinationen gezielt auswendig lernen soll @cheng_wide_deep_2016.

*Trade-offs und Grenzen.* Jede Zelle des Cross braucht genug Beispiele. In der @shop-abb-heat sind einige Zellen leer, weil Fahrradteile fast nie 700 Euro kosten; für solche Zellen lernt das Modell nichts, und das ist auch richtig so. Bei Crosses aus Merkmalen mit hoher Kardinalität (Marke mal Kategorie mal Gerät) explodiert die Spaltenzahl, und die meisten Zellen haben nur einen oder zwei Beispiele. Dann überwiegt das Rauschen. Wann man darauf verzichtet: bei Modellen, die Wechselwirkungen selbst lernen, wenn man nicht weiß, _welche_ Merkmale zusammenwirken (man kreuzt nicht blind alles), und wenn die Zellen zu dünn besetzt sind.

*Bezug zu Software Engineering.* Ein Cross ist ein zusammengesetzter Schlüssel wie `(kategorie, preisband)` in einem Primärschlüssel oder einem `GROUP BY`: Man aggregiert über die Kombination, nicht über beide getrennt.

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 2, Pattern "Feature Cross"; #cite(<cheng_wide_deep_2016>, form: "prose").

== Pattern 4: Multimodal Input

*Szenario und Problem.* Eine Produktzeile besteht aus verschiedenen Arten von Information: Kategorien (Kategorie, Gerät, Marke), Zahlen (Preis, Uhrzeit) und Text (der Titel). Ein Modell erwartet am Ende eine einheitliche Zahlenmatrix. Der Titel steckt voller Information, die nirgends sonst steht: Er nennt die Welt und den Zusatz "Pro" oder "Basic". Lässt man ihn weg, wirft man den Teil der Daten weg, der neue Produkte beschreibt, auch bevor es ein Verhalten dazu gibt.

*Die Lösung.* Jede Art von Eingabe wird in ihre passende Zahlendarstellung gebracht, die Ergebnisse werden zu einem Vektor zusammengefügt. Für Text nehmen wir _TF-IDF_: Jedes Wort des Vokabulars ist eine Spalte, der Wert ist die Häufigkeit des Wortes im Titel (term frequency) mal einem Gewicht, das seltene Wörter höher bewertet als häufige (inverse document frequency) @spaerck_jones_idf_1972 @salton_buckley_tfidf_1988. "Plus", das in vielen Titeln steht, zählt dadurch weniger als "Hüttentour". Weil Titel hier nur drei oder vier Wörter haben, ist die Häufigkeit fast immer 1, und TF-IDF ist im Wesentlichen eine gewichtete Wortliste. Die Tabellenmerkmale laufen weiter durch One-Hot und z-Score (Mittelwert abziehen, durch die Standardabweichung teilen); beide Blöcke werden spaltenweise nebeneinandergestellt.

#figure(
  diagram(
    node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 6pt, spacing: (10mm, 12mm),
    neben((0, 0), text(size: 9pt)[Titeltext \ "Trail Laufweste Pro"]),
    neben((0, 1), text(size: 9pt)[Kategorie, Gerät, \ Marke, Preis, Uhrzeit]),
    knoten((1, 0), text(size: 9pt)[TF-IDF \ #text(fill: grau)[110 Spalten]]),
    knoten((1, 1), text(size: 9pt)[One-Hot, Log, z-Score \ #text(fill: grau)[818 Spalten]]),
    knoten((2, 0.5), text(size: 9pt)[nebeneinander \ #text(fill: grau)[928 Spalten, dünn besetzt]]),
    knoten((3, 0.5), text(size: 9pt)[logistische \ Regression], grund: gruen-hell, farbe: gruen),
    edge((0, 0), (1, 0), "->"),
    edge((0, 1), (1, 1), "->"),
    edge((1, 0), (2, 0.5), "->"),
    edge((1, 1), (2, 0.5), "->"),
    edge((2, 0.5), (3, 0.5), "->"),
  ),
  caption: [Multimodal Input: Jede Art von Eingabe bekommt ihre eigene Zahlendarstellung, danach werden die Blöcke zu einer Matrix zusammengesetzt. Die Spaltenzahlen stammen aus `05_multimodal.py`.],
) <shop-abb-multimodal>

Im Code sammelt `transform` die Blöcke in einer Liste und setzt sie am Ende mit `hstack` nebeneinander (der Ausschnitt zeigt das Ende der Methode). Die Reihenfolge der Blöcke spielt keine Rolle, muss aber im Training und im Dienst dieselbe sein, weil das Modell die Spalten nur über ihre Position kennt:

#code-aus("merkmale.py", "        if self.text:", bis: "    def _mittel_embedding", nr: 1)

Der Text allein (#zahl(j("multimodal.json").modelle.at(1).auc)) schlägt die Tabelle allein (#zahl(j("multimodal.json").modelle.at(0).auc)), weil er die Welt verrät, und beide zusammen sind besser als jeder für sich (#zahl(j("multimodal.json").modelle.at(2).auc)). Die Wörter mit den größten Gewichten gehören zu Welten, die im Generator gut oder schlecht verkaufen: "Ultraleicht", "Trail" und "Laufweste" (Trailrunning) erhöhen die Kaufwahrscheinlichkeit, "Bergstiefel", "Trekking" und "Gipfel" (Bergwandern) senken sie. Das ist die Stärke linearer Modelle über Text: Man kann ihnen zuschauen.

*Trade-offs und Grenzen.* Erstens die Skalen: TF-IDF-Zeilen haben die Länge 1, die z-skalierten Tabellenwerte streuen um 0 mit Standardabweichung 1, und die Regularisierung, die große Gewichte bestraft und so vor Überanpassung schützt, behandelt beide gleich. Wie viel Gewicht ein Block bekommt, hängt dann auch von seiner Skalierung ab, nicht nur von seinem Nutzen. Zweitens die Überlappung mit Embeddings: Beide verraten die Welt, im Zusammenspiel (Tabelle am Ende des Kapitels) bringt der Text deshalb weniger, als sein Einzelwert vermuten lässt. Nicht einsetzen: wenn der Text nur Rauschen enthält oder durch andere Features abgedeckt ist, und bei langen Texten, wo ein Wortsack zu viel Struktur wegwirft; dann sind vortrainierte Sprachmodelle die bessere Wahl.

*Bezug zu Software Engineering.* Das Pattern ist ein Adapter: Jede Quelle hat ihr eigenes Format, am Ende steht eine gemeinsame Schnittstelle.

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 2, Pattern "Multimodal Input"; #cite(<spaerck_jones_idf_1972>, form: "prose") und #cite(<salton_buckley_tfidf_1988>, form: "prose") zu TF-IDF.

== Pattern 8: Cascade

*Szenario und Problem.* Der Shop will zwei Dinge wissen: ob die Sitzung kauft und wenn ja, in welcher Kategorie. Naheliegend ist ein einziges Modell mit 13 Klassen (kein Kauf plus zwölf Kategorien). Das Problem ist die Schieflage: 93 % der Sitzungen kaufen nicht, und die Frage nach der Kategorie ist nur für den kleinen Rest sinnvoll. Ein Modell, das beides gleichzeitig lernt, bekommt die Kategorien nur aus diesem kleinen Teil der Zeilen beigebracht und muss sie gegen die dominierende Klasse "kein Kauf" abwägen.

*Die Lösung.* Eine Cascade zerlegt die Aufgabe in eine Folge von Modellen, die jeweils eine einfachere Frage beantworten. Stufe 1 schätzt, ob die Sitzung kauft, und sie ist ein gewöhnlicher binärer Klassifikator auf allen Trainingszeilen. Stufe 2 schätzt die Kategorie und wird nur auf den Kaufsitzungen trainiert. Im Betrieb läuft Stufe 2 nur, wenn Stufe 1 die Sitzung für aussichtsreich hält.

#figure(
  {
    let c = j("cascade.json")
    let b = c.betrieb.at(1)
    diagram(
      node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 6pt, spacing: (34mm, 14mm),
      neben((0, 0), text(size: 9pt)[alle Sitzungen \ #text(fill: grau)[100 %]]),
      knoten((1, 0), text(size: 9pt)[Stufe 1 \ #text(fill: grau)[kauft die Sitzung?] \ #text(fill: grau)[AUC #zahl(c.auc_cascade)]]),
      knoten((2, 0), text(size: 9pt)[Stufe 2 \ #text(fill: grau)[welche Kategorie?] \ #text(fill: grau)[trainiert auf #tsd(c.n_kaeufer) Käufen]], grund: gruen-hell, farbe: gruen),
      neben((1, 1), text(size: 9pt)[abgewiesen \ #text(fill: grau)[#proz(1 - b.anteil, n: 0) der Sitzungen]], stroke: 0.6pt + orange, fill: orange-hell),
      edge((0, 0), (1, 0), "->"),
      edge((1, 0), (2, 0), "->", label: text(size: 8.5pt)[#proz(b.anteil, n: 0) mit höchstem Score], label-side: left),
      edge((1, 0), (1, 1), "->", label: text(size: 8.5pt)[unter der Schwelle], label-side: right),
      node((2, 1), text(size: 8.5pt, fill: grau)[#proz(b.erfasst) der Käufer erreichen Stufe 2, \ #proz(b.acc) davon mit richtiger Kategorie], stroke: none),
    )
  },
  caption: [Die Cascade im Betrieb. Die Schwelle ist so gewählt, dass 20 % der Sitzungen Stufe 2 erreichen. Werte aus `06_cascade.py`.],
) <shop-abb-cascade>

#code-aus("06_cascade.py", "# Variante B", bis: "# --- Referenzen")

#ausgabe(uv("06_cascade.py"), "06_cascade.txt", von: 2, bis: 14)

*Was man daraus liest.* Die Cascade ist bei der Kaufvorhersage etwas besser als das Einzelmodell (AUC #zahl(j("cascade.json").auc_cascade) gegenüber #zahl(j("cascade.json").auc_mono)), bei der Kategorie gleichauf (#proz(j("cascade.json").acc_cascade) gegenüber #proz(j("cascade.json").acc_mono) bei den Käufern). Bei rund 2900 Käufen im Test liegt dieser Unterschied weit unter einer Standardabweichung; die Genauigkeit der Kategorie verbessert das Pattern also nicht. Es verbessert den _Betrieb_: Stufe 2 muss nur für ein Fünftel der Sitzungen laufen und erfasst dabei gut die Hälfte der Käufer, sie lässt sich getrennt trainieren, evaluieren und austauschen, und die Kauf-AUC verlangt kein Opfer.

Ebenfalls im Skript steht die Heuristik "Kategorie der Seite": Wer das Produkt gerade ansieht, kauft mit #proz(j("cascade.json").acc_heur) Wahrscheinlichkeit aus dieser Kategorie. Die Modelle schlagen sie um sechs Prozentpunkte. Eine solche Heuristik gehört in jedes Projekt, bevor man Modelle baut, weil sie festlegt, was ein Modell mindestens leisten muss (Pattern 28, Heuristic Benchmark).

*Trade-offs und Grenzen.* Fehler pflanzen sich fort: Ein Käufer, den Stufe 1 abweist, bekommt nie eine Kategorie. Stufe 2 wird auf echten Käufern trainiert, sieht im Betrieb aber auch falsch-positive Sitzungen und hat für sie keine richtige Antwort; hier ist das harmlos, weil niemand sie nutzt. Die Schwelle zwischen den Stufen übersetzt ein Geschäftsziel (wie viele Käufer will ich erreichen?) in ein Kostenziel (wie viele Anfragen kann ich verarbeiten?). Nicht einsetzen: wenn die zweite Frage für alle Fälle sinnvoll ist oder ein einziges Modell genauso gut ist und die Pipeline einfacher bleibt.

*Bezug zu Software Engineering.* Pipes and Filters mit einem billigen ersten Filter: Wie ein billiger Vorfilter vor einer teuren Prüfung lässt Stufe 1 nur die Kandidaten durch, für die sich der zweite Schritt lohnt. Anders als bei einem Bloom-Filter geht dabei aber auch ein Teil der echten Treffer verloren.

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 3, Pattern "Cascade"; als historisches Beispiel einer Cascade von Klassifikatoren #cite(<viola_jones_cascade_2001>, form: "prose"); zum Heuristic Benchmark Kapitel 7 des Buchs.

== Pattern 26: Feature Store

*Szenario und Problem.* Produkte, die in der Vorwoche oft gekauft wurden, werden mit höherer Wahrscheinlichkeit wieder gekauft. Der Shop möchte dieses Signal nutzen. Drei Zahlen pro Produkt genügen: die Zahl der Ansichten und die Zahl der Käufe in den letzten sieben Tagen sowie die daraus berechnete Kaufrate. Je Sitzung werden sie über die drei angesehenen Produkte gemittelt (die Zähler als Logarithmus von 1 plus Zahl). Weil ein Produkt mit einer Ansicht und einem Kauf sonst eine Rate von 100 % hätte, wird die Rate geglättet: $ (K + m dot r_0) / (A + m) $ mit den Käufen $K$, den Ansichten $A$, einer groben Durchschnittsrate $r_0 = "0,017"$ und dem Gewicht $m = 30$. Wenige Beobachtungen ziehen die Rate damit Richtung Durchschnitt, viele überstimmen ihn. Das ist ein Spezialfall der Mittelwert-Kodierung kategorialer Merkmale @micci_barreca_target_encoding_2001.

Solche Features haben zwei Schwierigkeiten. Sie müssen im Training und im Betrieb mit derselben Definition berechnet werden, und sie müssen zeitlich stimmen: Das Feature einer Trainingszeile darf nur Wissen enthalten, das zum Zeitpunkt der Sitzung schon existierte. Die zweite Schwierigkeit ist heimtückischer, weil ihre Verletzung kein Fehler erzeugt, sondern ein besseres Modell vortäuscht.

*Die Berechnung.* Das Ereignisprotokoll des Shops wird zu einer Tabelle Tag mal Produkt aggregiert (Ansichten und Käufe je Tag), und über die Tage werden kumulierte Summen gebildet. Die Zahl im Zeitfenster ist dann die Differenz zweier Zeilen. Welche Zeilen das sind, entscheidet über Korrektheit:

#code-aus("store.py", "    def fenster", bis: "def kaufrate")

*Das Leck und seine Varianten.* Das Skript `07_feature_store_leck.py` berechnet das Feature auf drei Arten und trainiert mit jeder ein eigenes Modell. @shop-abb-fenster zeigt die Fenster für eine Sitzung an Tag 55.

#figure(
  {
    let d = 55
    let u = 0.15
    let x(t) = t * u
    align(center, canvas(length: 1cm, {
      import draw: *
      set-style(stroke: 0.5pt)
      let reihe(y, von, bis, farbe, titel, notiz) = {
        rect((x(von), y), (x(bis), y - 0.42), fill: farbe.lighten(55%), stroke: 0.8pt + farbe)
        content((-0.15, y - 0.21), anchor: "east", text(size: 8.5pt, titel))
        content((x(bis) + 0.15, y - 0.21), anchor: "west", text(size: 8.5pt, fill: farbe, notiz))
      }
      reihe(0, 0, 70, orange, [gesamter Datensatz], [])
      content((x(35), -0.21), text(size: 8.5pt, fill: orange)[enthält Zukunft und eigenen Kauf])
      reihe(-0.75, d - 6, d + 1, orange, [bis einschließlich heute], [enthält die Sitzung selbst])
      reihe(-1.5, d - 7, d, gruen, [bis gestern (PIT)], [nur Vergangenheit])
      line((x(d), 0.5), (x(d), -2.15), stroke: (dash: "dashed", paint: luma(60), thickness: 0.8pt))
      content((x(d), 0.8), text(size: 8.5pt)[Sitzung an Tag 55])
      line((0, -2.15), (x(70), -2.15))
      for t in (0, 10, 20, 30, 40, 50, 60, 70) {
        line((x(t), -2.15), (x(t), -2.25))
        content((x(t), -2.5), text(size: 8.5pt, str(t)))
      }
      content((x(35), -2.9), text(size: 8.5pt, fill: grau)[Tag])
    }))
  },
  caption: [Drei Zeitfenster für das Popularitätsfeature einer Sitzung an Tag 55. Orange: das Fenster enthält Wissen, das zum Zeitpunkt der Sitzung nicht existierte. Grün: nur Tage vor der Sitzung.],
) <shop-abb-fenster>

Die erste Variante, die Kennzahl über den gesamten Datensatz, ist die, die man mit einer einzigen `groupby`-Zeile erzeugt. Die zweite, sieben Tage bis einschließlich heute, entsteht, wenn ein nächtlicher Job die Zähler am Ende eines Tages schließt und das Training die Zähler "des Tages" an die Sitzung dieses Tages joint. Beide enthalten den Kauf, der vorhergesagt werden soll. Nur die dritte, Tag minus sieben bis Tag minus eins, enthält ausschließlich Wissen vom Morgen des Sitzungstags.

#ausgabe(uv("07_feature_store_leck.py"), "07_feature_store_leck.txt")

Daran lassen sich drei Warnzeichen ablesen, die auch außerhalb dieses Beispiels gelten. Erstens ist ein einzelnes Popularitätsfeature _zu gut_: Allein trennt die mittlere Kaufrate der drei Produkte Käufer und Nicht-Käufer mit einer AUC von #zahl(j("feature_store.json").einzel.mit_tag) (Fenster bis heute) beziehungsweise #zahl(j("feature_store.json").einzel.gesamt) (gesamter Datensatz), im korrekten Fall nur mit #zahl(j("feature_store.json").einzel.pit). Ein Zähler der Vorwoche, der besser trennt als das gesamte korrekte Modell (AUC #zahl(g.at(5).auc)), ist verdächtig. Zweitens fällt die Güte vom Notebook zum Betrieb: von #zahl(j("feature_store.json").lauf.at(0).offline.auc) auf #zahl(j("feature_store.json").lauf.at(0).online.auc) beim gesamten Datensatz und von #zahl(j("feature_store.json").lauf.at(1).offline.auc) auf #zahl(j("feature_store.json").lauf.at(1).online.auc) beim Fenster bis heute, wenn das Modell die Werte bekommt, die der Dienst tatsächlich berechnen kann. Drittens ist das Leck-Modell im Betrieb nicht besser als ein Modell ganz ohne Popularitätsfeature (#zahl(j("feature_store.json").ohne.auc)): Es hat gelernt, sich auf ein Signal zu verlassen, das es im Betrieb nie gibt.

#figure(
  {
    let f = j("feature_store.json")
    let zeilen = (
      (f.lauf.at(1).text, f.lauf.at(1).offline.auc, f.lauf.at(1).online.auc),
      (f.lauf.at(0).text, f.lauf.at(0).offline.auc, f.lauf.at(0).online.auc),
      (f.lauf.at(2).text, f.lauf.at(2).offline.auc, f.lauf.at(2).online.auc),
      ([ohne Popularitätsfeatures], f.ohne.auc, f.ohne.auc),
    )
    let sk = 7.5 / 0.40
    let xv(v) = (v - 0.5) * sk
    align(center, canvas(length: 1cm, {
      import draw: *
      set-style(stroke: 0.5pt)
      for (i, (t, off, on)) in zeilen.enumerate() {
        let y = -i * 1.15
        content((-0.2, y - 0.3), anchor: "east", text(size: 8.5pt, t))
        rect((0, y), (xv(off), y - 0.4), fill: blau, stroke: none)
        content((xv(off) + 0.1, y - 0.2), anchor: "west", text(size: 8.5pt, zahl(off)))
        rect((0, y - 0.45), (xv(on), y - 0.85), fill: if on < off - 0.005 { orange } else { gruen }, stroke: none)
        content((xv(on) + 0.1, y - 0.65), anchor: "west", text(size: 8.5pt, zahl(on)))
      }
      line((0, 0.2), (0, -4.6))
      for v in (0.5, 0.6, 0.7, 0.8, 0.9) {
        line((xv(v), -4.6), (xv(v), -4.7))
        content((xv(v), -4.95), text(size: 8.5pt, zahl(v, n: 1)))
      }
      content((xv(0.7), -5.4), text(size: 8.5pt, fill: grau)[AUC auf den Testtagen; die Balken beginnen bei 0,5 (Raten)])
      rect((8.8, -0.1), (9.1, -0.4), fill: blau, stroke: none)
      content((9.25, -0.25), anchor: "west", text(size: 8.5pt)[offline])
      rect((8.8, -0.6), (9.1, -0.9), fill: gruen, stroke: none)
      content((9.25, -0.75), anchor: "west", text(size: 8.5pt)[online, stimmig])
      rect((8.8, -1.1), (9.1, -1.4), fill: orange, stroke: none)
      content((9.25, -1.25), anchor: "west", text(size: 8.5pt)[online, Einbruch])
    }))
  },
  caption: [Trainiert wird jeweils mit der Variante, die links steht. Blau: Güte auf Testdaten, deren Popularitätsfeatures nach derselben Variante berechnet sind (was das Team im Notebook sieht). Grün/Orange: Güte, wenn die Features so berechnet werden, wie der Dienst sie liefert (Point in Time). Werte aus `07_feature_store_leck.py`.],
) <shop-abb-leck>

*Die Behebung.* Das Pattern Feature Store ist die organisatorische Antwort. Ein Feature Store hat zwei Gesichter: Der _Offline-Store_ liefert für das Training zu jedem Beispiel den Wert, der zu dessen Zeitstempel galt (der Point-in-Time-Join, in Feast `get_historical_features` @feast_docs), der _Online-Store_ liefert im Betrieb den aktuellen Wert mit niedriger Latenz. Beide speisen sich aus _derselben_ Definition, sodass das Feature nicht auseinanderlaufen kann (Training-Serving Skew, Pattern 21). Hier ist der Feature Store auf seinen Kern reduziert: die Klasse `Protokoll` mit rund 25 Zeilen und ein Schnappschuss der Zähler zum Stichtag (@shop-abb-architektur). Ein Produkt wie Feast ergänzt die Verwaltung vieler Features, Zeitstempel je Ereignis statt je Tag, die Aktualisierung des Online-Stores und Zugriffsrechte.

*Trade-offs und Grenzen.* Der Tag als kleinste Einheit ist konservativ: Er verwirft, was am Vormittag desselben Tages schon bekannt war, ist dafür aber einfach und prüfbar. Wer feiner arbeitet, muss die Latenz des Online-Stores in die Definition aufnehmen: Ein stündlich nachgezogener Zähler ist im Betrieb bis zu eine Stunde veraltet, und das Training sollte dieselbe Verzögerung abbilden. Ein Feature Store ersetzt außerdem keine Sorgfalt beim Entwurf: Auch aus korrekten Zeitfenstern kann man sich ein Leck bauen, etwa mit einem Feature, das in der Praxis nur für gekaufte Produkte befüllt wird. Nicht einsetzen: bei einem Modell mit wenigen, nicht zeitabhängigen Features; der Aufwand rechnet sich mit der Zahl der Modelle und der zeitabhängigen Features.

*Bezug zu Software Engineering.* Der Point-in-Time-Join ist ein "as of"-Join auf einer temporalen Tabelle, wie ihn auch SQL kennt, und das Prinzip ist das von Event Sourcing: Der Zustand zu einem Zeitpunkt ist das, was sich aus den bis dahin eingetretenen Ereignissen ergibt. Die gemeinsame Definition für Training und Betrieb ist Single Source of Truth; sie mindert die Kosten von Datenabhängigkeiten, die #cite(<sculley_hidden_debt_2015>, form: "prose") beschreiben.

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 6, Pattern "Feature Store"; zum Datenleck #cite(<kaufman_leakage_2012>, form: "prose"); Feast-Dokumentation @feast_docs.

== Pattern 16 und 27: Dienst und Modellversionen

*Szenario und Problem.* Das Modell soll in den Shop. Sobald es eine Version 2 gibt, die mehr Features nutzt, darf die Version 1 nicht von einem Tag auf den anderen verschwinden: Andere Teams rufen sie auf und brauchen Zeit für die Umstellung, und wenn v2 sich im Betrieb als schlechter erweist, muss man zurückgehen können. Zugleich soll der Dienst skalieren, also ohne Gedächtnis zwischen Anfragen auskommen.

*Die Lösung.* Der Dienst `code/14/dienst.py` ist mit FastAPI @ramirez_fastapi_docs gebaut. Das Pattern Stateless Serving Function verlangt, dass die Vorhersage eine Funktion ist, die nur von ihrer Eingabe abhängt. In der Praxis heißt das: Das Modell wird _einmal_ beim Start des Prozesses geladen und danach nur gelesen, und kein Handler schreibt in einen Speicher, den die nächste Anfrage sieht.

#code-aus("dienst.py", "MODELLE: dict", bis: "app = FastAPI")

Beim Start (`lifespan`) werden alle Versionen aus `modelle/` geladen. Jede Datei ist ein _Paket_: der angepasste `Merkmale`-Transformer mit Wörterbüchern, TF-IDF-Vokabular und Embedding-Tabelle sowie das Modell, dazu Metadaten. Das ist wichtig, weil sich Merkmalsbau, Embedding und Gewichte nicht einzeln austauschen lassen. Die Vorhersage selbst ist eine reine Funktion (`paket` schlägt die Version nach und antwortet bei einer unbekannten mit 404):

#code-aus("dienst.py", "def paket(", bis: "@app.get")

Die beiden Pakete und einen Schnappschuss der Popularität zum Stichtag schreibt das Skript `trainiere_modelle.py`; im Dienst kommt die Popularität aus diesem Schnappschuss; im echten Betrieb stünde hier der Online-Store. Der Schnappschuss ändert sich während des Prozesses nicht. Ein Produkt, das der Store nicht kennt, bekommt Popularität null.

Das Pattern Model Versioning ist dann nur noch Routing: Die Version steht im Pfad, beide Pakete sind im selben Prozess geladen, und `/{version}/info` nennt Beschreibung und Güte der Version.

#code-aus("dienst.py", "@app.post")

Getestet wird mit dem `TestClient` von FastAPI (er braucht `httpx`), der den Dienst im selben Prozess ohne Netzwerk aufruft. Der Test prüft auch, was Zustandslosigkeit praktisch bedeutet: Dieselbe Anfrage liefert dieselbe Antwort, egal was zwischen zwei Aufrufen geschehen ist.

#ausgabe(uv("test_dienst.py", extra: " --with fastapi --with httpx"), "09_dienst_test.txt")

*Trade-offs und Grenzen.* Die Version im Pfad ist die einfachste Art zu versionieren, lässt aber die Clients eine Entscheidung treffen, die sie meist nicht treffen wollen; Alternativen sind ein Header oder ein Gateway, das Anfragen aufteilt (Canary, A/B-Test). Zwei Versionen im selben Prozess verdoppeln den Speicher; bei großen Modellen trennt man sie in verschiedene Prozesse. Gespeichert werden die Pakete mit `joblib`, das auf Python-Pickle beruht: Man darf nur eigene, vertrauenswürdige Dateien laden, und die Pakete sind an die Bibliotheksversionen gebunden, mit denen sie erzeugt wurden. Der `TestClient` ist kein Lasttest und keine Überwachung; dazu gehören Pattern 18 (Continued Model Evaluation) und Pattern 20 (Keyed Predictions). Nicht einsetzen: wenn eine nächtliche Batch-Berechnung genügt (Pattern 17); sie braucht weder Dienst noch Versionierung.

*Bezug zu Software Engineering.* Beide Patterns sind bekannte Dienstentwurfsprinzipien in ML-Verkleidung. Zustandslosigkeit ist der Grund, warum man einen Dienst horizontal skalieren und jederzeit neu starten darf. Versionierte Endpunkte sind die übliche Art, eine HTTP-Schnittstelle weiterzuentwickeln, ohne Clients zu brechen (zum Architekturstil REST siehe @fielding_rest_2000); die Regel, dass ein Paket alles enthält, was zusammengehört, ist das Prinzip eines unveränderlichen Artefakts, wie es auch bei Container-Images gilt.

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 5, Pattern "Stateless Serving Function", und Kapitel 6, Pattern "Model Versioning"; FastAPI-Dokumentation @ramirez_fastapi_docs.

== Das Gesamtbild: Architektur und Wirkung

@shop-abb-architektur setzt die Teile zusammen. Links steht, was täglich offline geschieht: Aus dem Ereignisprotokoll entstehen Zähler und Embeddings, `Merkmale` wird auf den Trainingsdaten angepasst, die beiden Modellstufen werden trainiert, und das Ergebnis wird als versioniertes Paket abgelegt. Rechts steht der Betrieb: Der Dienst lädt die Pakete einmal, holt die Popularität aus dem Schnappschuss des Online-Stores und beantwortet Anfragen ohne eigenes Gedächtnis. Die gestrichelte Linie dazwischen ist die Stelle, an der Training und Betrieb auseinanderlaufen können, und jedes Pattern der Fallstudie sorgt dafür, dass sie schmal bleibt.

#figure(
  diagram(
    node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 6pt, spacing: (9mm, 13mm),
    node(enclose: ((0, 0), (3, 0)), stroke: (dash: "dashed", paint: luma(150), thickness: 0.8pt), inset: 12pt, snap: false),
    node((1.5, -0.62), text(size: 9pt, weight: "bold")[Offline, täglich], stroke: none),
    node(enclose: ((2, 1), (3, 2)), stroke: (dash: "dashed", paint: luma(150), thickness: 0.8pt), inset: 12pt, snap: false),
    node((2.5, 2.62), text(size: 9pt, weight: "bold")[Online, pro Anfrage], stroke: none),
    neben((0, 0), text(size: 9pt)[Ereignis- \ protokoll]),
    knoten((1, 0), text(size: 9pt)[Zähler je Tag #tag(26) \ Embeddings #tag(2)], grund: orange-hell, farbe: orange),
    knoten((2, 0), text(size: 9pt)[Merkmale anpassen \ #tag(1) #tag(3) #tag(4) \ Stufe 1 und 2 #tag(8)]),
    knoten((3, 0), text(size: 9pt)[Paket v1, v2 #tag(27) \ Merkmale, Embeddings, \ Gewichte], grund: gruen-hell, farbe: gruen),
    neben((2, 1), text(size: 9pt)[Schnappschuss \ Popularität]),
    knoten((3, 1), text(size: 9pt)[Dienst #tag(16) \ /v1, /v2], grund: gruen-hell, farbe: gruen),
    neben((3, 2), text(size: 9pt)[Shop-Frontend]),
    edge((0, 0), (1, 0), "->"),
    edge((1, 0), (2, 0), "->"),
    edge((2, 0), (3, 0), "->"),
    edge((1, 0), (2, 1), "->", label: text(size: 8.5pt)[Stichtag], label-side: left, label-pos: 0.6),
    edge((3, 0), (3, 1), "->", label: text(size: 8.5pt)[beim Start laden], label-side: right),
    edge((2, 1), (3, 1), "->"),
    edge((3, 2), (3, 1), "<->", label: text(size: 8.5pt)[Anfrage, Score], label-side: right),
  ),
  caption: [Architektur der Fallstudie. Die Nummern bezeichnen die Patterns, die an der jeweiligen Stelle wirken.],
) <shop-abb-architektur>

#let vz(x, n: 3) = (if x >= 0 { "+" } else { "−" }) + zahl(calc.abs(x), n: n)
#let gs = g

*Wirkung auf die Güte.* @shop-tab-stufen zeigt, was jede Zutat zum Modell beiträgt, in der Reihenfolge der Patterns im Buch. Die Spalte "allein" fügt die Zutat nur zum Ausgangsmodell hinzu, die Spalte "kumuliert" baut auf allen vorherigen Zutaten auf. Die Cascade ist nicht Teil der Tabelle, weil sie eine andere Aufgabe beantwortet (die Kategorie), und der Dienst hat keine Auswirkung auf die Güte.

#figure(
  {
    let kopf = ([Stufe], [Spalten], [AUC allein], [AUC kumuliert], [Δ kumuliert], [AP], [Log-Loss])
    let zeilen = ()
    for (i, r) in gs.enumerate() {
      let delta = if i == 0 { [] } else { vz(r.auc - gs.at(i - 1).auc) }
      zeilen.push(((if i == 0 { r.name } else { "+ " + r.name }).replace("2^14", "2¹⁴"), tsd(r.spalten), if i == 0 { [] } else { zahl(r.einzeln) }, zahl(r.auc), delta, zahl(r.ap), zahl(r.logloss, n: 4)))
    }
    set text(size: 9.5pt)
    table(columns: (1fr, auto, auto, auto, auto, auto, auto), align: (left, right, right, right, right, right, right), stroke: (x, y) => (y: if y == 0 { 0.8pt } else { 0.4pt + luma(190) }),
      ..kopf.map(k => text(weight: "bold", k)), ..zeilen.flatten())
  },
  caption: [Wirkung der Zutaten auf den Testtagen, einzeln und aufbauend (Ausgabe von `08_gesamt.py`). AUC: höher ist besser; Log-Loss: niedriger ist besser.],
) <shop-tab-stufen>

Vier Beobachtungen. Erstens addieren sich die Beiträge nicht. Der Text allein hebt die AUC um #vz(gs.at(4).einzeln - gs.at(0).auc), auf dem Stand mit Embeddings und Feature Cross aber nur um #vz(gs.at(4).auc - gs.at(3).auc), weil Text und Embeddings beide die Welt verraten; die Summe der Einzelwirkungen (#vz(gs.slice(1).map(r => r.einzeln - gs.at(0).auc).sum())) übertrifft die Gesamtwirkung (#vz(gs.at(5).auc - gs.at(0).auc)) deutlich. Wer Patterns stapelt, sollte jede Zutat daher auch in der Ablation prüfen: Was verliert das Gesamtmodell, wenn ich sie wieder herausnehme? Eine Zutat, die dann nichts kostet, ist laufender Betriebsaufwand ohne Nutzen. Zweitens kostet das Hashed Feature gegenüber dem Wörterbuch ein wenig Güte (#vz(gs.at(1).auc - gs.at(0).auc)), und das ist in Ordnung, weil sein Gewinn im Betrieb liegt. Drittens ist das Popularitätsfeature die Zutat, deren Wert sich am leichtesten falsch messen lässt: Der ehrliche Wert (#vz(gs.at(5).auc - gs.at(4).auc)) steht neben dem, den das Leck vorgetäuscht hätte (#vz(r3(j("feature_store.json").lauf.at(1).offline.auc) - r3(j("feature_store.json").ohne.auc))). Viertens steigt die Güte des Gesamtmodells von AUC #zahl(gs.at(0).auc) auf #zahl(gs.at(5).auc) und von AP #zahl(gs.at(0).ap) auf #zahl(gs.at(5).ap), bei einem Zufallsniveau der AP von 0,068.

*Wirkung auf den Betrieb.* Die Güte ist nur ein Teil der Wirkung. @shop-tab-betrieb stellt zusammen, was jedes Pattern im Betrieb verändert, auch dort, wo die AUC unverändert bleibt.

#figure(
  {
    let c = j("cascade.json")
    let b = c.betrieb.at(1)
    let fs = j("feature_store.json")
    set text(size: 9.5pt)
    table(columns: (auto, 1fr, 1fr), align: (left, left, left), stroke: (x, y) => (y: if y == 0 { 0.8pt } else { 0.4pt + luma(190) }),
      text(weight: "bold")[Pattern], text(weight: "bold")[Wirkung auf die Güte], text(weight: "bold")[Wirkung auf den Betrieb],
      [1 Hashed Feature], [AUC #vz(gs.at(1).auc - gs.at(0).auc) gegenüber dem Wörterbuch], [Kein Wörterbuch im Paket, neue IDs ohne Sonderfall; Bucket-Zahl nur mit neuem Training änderbar],
      [2 Embeddings], [AUC #vz(gs.at(2).auc - gs.at(1).auc) kumuliert, größter Beitrag], [Tabelle im versionierten Paket; Neuaufbau bei wachsendem Katalog],
      [3 Feature Cross], [AUC #vz(gs.at(3).auc - gs.at(2).auc) kumuliert], [96 Spalten; zu dünne Zellen lernen nichts],
      [4 Multimodal Input], [AUC #vz(gs.at(4).auc - gs.at(3).auc) kumuliert, #vz(gs.at(4).einzeln - gs.at(0).auc) allein], [TF-IDF-Vokabular im Paket; überlappt mit Embeddings],
      [8 Cascade], [Kauf-AUC #vz(r3(c.auc_cascade) - r3(c.auc_mono)), Kategorie-Treffer gleich], [Stufe 2 für #proz(b.anteil, n: 0) der Sitzungen, erreicht #proz(b.erfasst, n: 0) der Käufer; Stufen getrennt austauschbar],
      [26 Feature Store], [AUC #vz(gs.at(5).auc - gs.at(4).auc) kumuliert; ein Leck täuscht #vz(r3(fs.lauf.at(1).offline.auc) - r3(fs.ohne.auc)) vor], [Eine Definition für Training und Betrieb; täglicher Schnappschuss],
      [16, 27 Dienst und Versionen], [keine], [Zwei Versionen parallel; Rückfall durch Pfadwechsel; kein Zustand zwischen Anfragen],
    )
  },
  caption: [Wirkung der Patterns auf Güte und Betrieb, mit Werten aus den Läufen dieses Kapitels.],
) <shop-tab-betrieb>

*Was in einem echten Shop anders wäre.* Die Daten sind sauberer als echte: Die Embeddings finden eine einzige, perfekt erkennbare Struktur, die Titel sind kurz und folgen einem festen Muster, und die Effekte sind groß und konstant. In einem echten Shop wären die Nachbarschaften gröber, der Text unordentlich, Popularität und Kaufneigung verschränkter, und die Beiträge der einzelnen Patterns kleiner. Die Reihenfolge der Beobachtungen würde dennoch ähnlich ausfallen, denn sie folgt aus den Mechanismen und nicht aus den Zahlen. Und ob der Score im Shop etwas bewirkt, entscheidet am Ende kein Offline-Maß, sondern ein kontrolliertes Online-Experiment @kohavi_trustworthy_experiments_2020.

== Das Wichtigste in Kürze

- Ein Hashed Feature ersetzt ein Wörterbuch durch eine Rechenvorschrift. Es kostet hier #vz(gs.at(1).auc - gs.at(0).auc) AUC und spart die Pflege des Wörterbuchs; der Nutzen wächst mit der Kardinalität.
- Ein Embedding aus Ko-Klick-Daten ist eine Matrixfaktorisierung (PPMI-Matrix der Produktpaare, abgeschnittene SVD, Zeilen als Vektoren). Es trägt Nähe in ein Modell, die in keiner Spalte steht, und ist das wirksamste Pattern dieser Fallstudie.
- Ein Feature Cross lässt ein lineares Modell Wechselwirkungen lernen, die Einzelspalten nicht ausdrücken (Preiseffekt je Kategorie).
- Multimodal Input übersetzt jede Eingabeart passend in Zahlen und setzt die Blöcke zusammen. Text und Embedding verraten dieselbe Information und addieren sich nicht.
- Eine Cascade lohnt sich, wenn die zweite Frage nur für wenige Fälle gestellt werden muss. Hier bringt sie Betriebsvorteile statt Genauigkeit.
- Popularitätsfeatures müssen Point in Time berechnet werden. Ein Zähler, der zu gut trennt, und eine Lücke zwischen Offline- und Online-Güte sind die Warnzeichen eines Lecks.
- Ein Dienst, der sein Modell einmal lädt und pro Anfrage nur liest, ist zustandslos. Versionen im Pfad erlauben parallelen Betrieb und Rückfall, und das Paket einer Version enthält alles, was zusammengehört.
- Die Wirkung mehrerer Patterns misst man einzeln und aufbauend und prüft zusätzlich per Ablation, was beim Entfernen einer Zutat verloren geht. Die Summe der Einzelwirkungen überschätzt das Ganze.

#erklaere(
  [Erzählen Sie die Fallstudie als Geschichte eines Teams, das ein Feature nach dem anderen hinzufügt, und lassen Sie die Studierenden vor jeder Zahl schätzen, was das Feature bringt. Die Überraschungen sind die Lernmomente: Der Text allein ist stark, im Verbund wenig; die Popularität wird erst durch das Leck "gut". Zeigen Sie @shop-abb-leck und lassen Sie erklären, warum das orange Modell schlechter ist als das ohne Feature.],
  [Ein Teammitglied meldet, ein neues Popularitätsfeature habe die AUC von 0,74 auf 0,88 gehoben. Was prüfen Sie zuerst?],
  [Wie das Feature für die Trainingszeilen berechnet wird: welches Zeitfenster, ob es Ereignisse des Zeitstempels der Zeile oder späterer Tage einschließt. Dann die Güte mit Features, so wie der Dienst sie bei einer Anfrage hätte. Ein Sprung dieser Größe durch einen Zähler der Vorwoche ist ein Warnsignal und kein Erfolg.],
)

*Weiterführende Literatur.* Zu den Patterns selbst führen die Kapitel 2, 3 und 6 von #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"). Zum Zusammenhang von Embeddings und Matrixfaktorisierung siehe #cite(<levy_goldberg_implicit_2014>, form: "prose"), zum Datenleck Kaufman et al. @kaufman_leakage_2012, zu den Folgekosten von Datenabhängigkeiten #cite(<sculley_hidden_debt_2015>, form: "prose") und für eine Checkliste zu ML-Systemen #cite(<breck_ml_test_score_2017>, form: "prose").
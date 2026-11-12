#import "../lib.typ": *
#import "@preview/cetz-plot:0.1.2": plot

// Lokale Hilfen. Code und Ausgaben werden aus code/04-data-representation/ gelesen,
// damit das Handbuch exakt zeigt, was dort ausgeführt wurde.
#let gruen = rgb("#2EAE7D")
#let orange = rgb("#B5651D")
// Ausschnitt einer Datei von der Zeile, die `ab` enthält, bis vor die Zeile, die `bis` enthält
#let code-aus(datei, ab, bis: none) = {
  let t = read("../code/04-data-representation/" + datei)
  let von = t.position(ab)
  let rest = t.slice(von)
  let ende = if bis == none { rest.len() } else { rest.position(bis) }
  raw(rest.slice(0, ende).trim("\n", at: end), lang: "python", block: true)
}
// Ausgabe eines Laufs im Konsolenfenster; von/bis wählen Zeilen (ab 0), befehl: none lässt die Befehlszeile weg
#let ausgabe(datei, befehl, von: 0, bis: none) = {
  let z = read("../code/04-data-representation/ausgabe/" + datei).trim("\n", at: end).split("\n")
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

#set figure(placement: auto)

= Data Representation

Ein Modell rechnet. Es nimmt eine Liste von Zahlen entgegen, multipliziert sie mit gelernten Gewichten, addiert die Produkte und schiebt das Ergebnis durch einfache Funktionen. Alles, was in der Anwendung keine Zahl ist, also ein Text, eine Postleitzahl, ein Foto oder der Wochentag, muss vorher in Zahlen übersetzt werden. Diese Übersetzung heißt _Repräsentation_. Die einzelnen Zahlen, die ins Modell gehen, heißen _Features_, und die Liste aller Features eines Beispiels nennt man _Feature-Vektor_.

Dieselbe Information lässt sich auf viele Arten in Zahlen fassen, und ein Modell lernt sie unterschiedlich leicht. Die Repräsentation ist deshalb keine Randnotiz der Vorverarbeitung, sondern eine der wirksamsten Stellschrauben überhaupt. Für Software Engineers ist sie die Schnittstelle zwischen Fachdomäne und Modell, vergleichbar mit einem Datenvertrag: Wer sie ändert, ändert, was das Modell überhaupt sehen kann. Dieses Kapitel behandelt die vier Patterns aus Kapitel 2 des Buchs von #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"). Davor stehen die einfachen Bausteine, auf denen sie aufbauen.

== Einfache Repräsentationen: aus Rohwerten werden Zahlen

Vier Werkzeuge reichen für die meisten Spalten einer Tabelle. Wir probieren sie an 1000 künstlichen Datensätzen aus (Fläche, Jahreseinkommen, Stadtteil), die in `code/04-data-representation/01_einfache_repraesentationen.py` erzeugt werden. Alle Skripte dieses Kapitels laufen in diesem Ordner mit `uv run --with scikit-learn --with pandas python <datei>` (numpy und scipy kommen als Abhängigkeiten von scikit-learn mit); die gezeigten Ausgaben stammen aus echten Läufen mit festem Zufallssamen und liegen als Textdateien in `ausgabe/`.

*Skalierung.* Die Fläche einer Wohnung liegt zwischen 25 und 200, das Einkommen zwischen einigen Tausend und mehreren Hunderttausend. Beim Training mit Gradientenabstieg (das Modell verbessert seine Gewichte in vielen kleinen Schritten, siehe Kapitel 2) dominieren Features mit großen Zahlenwerten, und das Training wird langsam oder instabil. Auch Verfahren, die Abstände berechnen (etwa k-nearest-neighbors, das ein Beispiel nach seinen nächsten Nachbarn im Trainingsdatensatz einordnet), sehen ein Feature mit großem Wertebereich überproportional. Entscheidungsbäume sind dagegen unempfindlich, weil sie nur vergleichen. Zwei Standardlösungen: _Min-Max-Skalierung_ bildet den Bereich auf 0 bis 1 ab, $(x - x_min)/(x_max - x_min)$, und reagiert empfindlich auf Ausreißer. Der _z-Score_ zieht den Mittelwert ab und teilt durch die Standardabweichung, $(x - mu)/sigma$; danach hat das Feature Mittelwert 0 und Standardabweichung 1. Wichtig ist, dass diese Konstanten _nur aus den Trainingsdaten_ stammen und im Betrieb unverändert wiederverwendet werden. Rechnet man sie auf allen Daten aus, fließt Wissen über die Testdaten ins Training (_Data Leakage_). Dass Training und Betrieb dieselben Konstanten verwenden, ist das Anliegen von Pattern 21 (Transform, Kapitel 8).

*Log-Transformation.* Einkommen, Preise, Klickzahlen sind rechtsschief: viele kleine Werte, wenige sehr große. Im Beispiel liegt das Mittel bei 46 050, der Median bei 39 476, und die Schiefe (ein Maß für die Asymmetrie, 0 heißt symmetrisch) beträgt 2,05. Nach dem Logarithmus sind Mittel und Median praktisch gleich und die Schiefe ist −0,03 (@abb-log). Der Logarithmus macht aus Unterschieden um einen Faktor Unterschiede um einen festen Betrag: 20 000 zu 40 000 ist derselbe Schritt wie 40 000 zu 80 000. Genau so denken Menschen über Einkommen, und ein Modell mit additiven Gewichten kann das dann ebenfalls.

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 10pt,
    {
      let d = json("../code/04-data-representation/einfache_repraesentationen.json")
      daten-plot(size: (6.2, 3.4), x-label: [Jahreseinkommen in 1000], y-label: [Anzahl], x-tick-step: 100, y-tick-step: 100, y-max: 320, {
        plot.add-bar(d.roh_hist.enumerate().map(((i, v)) => (i * 20 + 10, v)), bar-width: 18, style: (fill: rgb("#B5651D"), stroke: none))
      })
    },
    {
      let d = json("../code/04-data-representation/einfache_repraesentationen.json")
      daten-plot(size: (6.2, 3.4), x-label: [Logarithmus des Einkommens], y-label: [Anzahl], x-tick-step: 1, y-tick-step: 100, y-max: 320, x-min: 8.4, x-max: 13.2, {
        plot.add-bar(d.log_hist.enumerate().map(((i, v)) => (8.8 + 0.4 * i, v)), bar-width: 0.36, style: (fill: rgb("#2EAE7D"), stroke: none))
      })
    },
  ),
  caption: [Das Einkommen der 800 Trainingsdatensätze vor (links) und nach (rechts) dem Logarithmus. Die Werte stammen aus `01_einfache_repraesentationen.py`.],
) <abb-log>

*Bucketizing.* Manchmal ist nicht der genaue Wert wichtig, sondern die Gruppe: Altersgruppen, Einkommensklassen. Man zerlegt den Wertebereich in Intervalle und ersetzt die Zahl durch die Nummer des Intervalls (oder, wie gleich beim One-Hot, durch eine Spalte je Intervall). Das ist nützlich, wenn der Zusammenhang nicht gleichmäßig ansteigt, etwa wenn das Unfallrisiko bei jungen und sehr alten Fahrern steigt und dazwischen niedrig ist. Ein lineares Modell kann einer Zahl nur _ein_ Gewicht geben; mit Buckets bekommt jede Gruppe ihr eigenes. Der Preis ist verlorene Feinheit. Im Beispiel entstehen vier Gruppen mit gleich vielen Datensätzen (Quartile), und die Grenzen werden wieder nur aus den Trainingsdaten bestimmt.

*One-Hot-Kodierung.* Ein Stadtteil ist keine Zahl. Naheliegend wäre, ihn zu nummerieren (Mitte 0, Nord 1, Ost 2, Süd 3). Dann würde das Modell aber annehmen, Ost liege "doppelt so weit" von Mitte wie Nord. One-Hot vermeidet jede Reihenfolge: Es gibt eine Spalte pro Wert, und genau eine davon ist 1. Das funktioniert hervorragend bei vier Stadtteilen und wird unbrauchbar bei vier Millionen Produkt-IDs. Dort setzen die Patterns 1 und 2 an.

#ausgabe("01_einfache_repraesentationen.txt", uv-run("01_einfache_repraesentationen.py"))

Der Skalierer hat seine Parameter aus den Trainingsdaten gelernt (`fit`) und wendet sie danach nur noch an (`transform`).

#kasten([Bezug zu Software Engineering.], [Die gelernten Konstanten (Mittelwert, Quartilgrenzen, Kategorienliste) sind Zustand, der zum Modell gehört wie ein Konfigurationsstand. Wer ein Modell ausliefert und den Skalierer vergisst, liefert eine Anwendung aus, deren Konfigurationsdatei fehlt. Das Muster, das dahinter steht, heißt in der ML-Welt _Training-Serving Skew_ und wird in Kapitel 9 behandelt.])

== Pattern 1: Hashed Feature

*Szenario.* Ein Online-Shop will vorhersagen, ob ein Besucher ein Produkt kauft. Ein wichtiges Feature ist die Produkt-ID, und der Shop führt zwei Millionen verschiedene IDs, jede Woche kommen Tausende neue dazu. Mit One-Hot entstünden zwei Millionen Spalten.

*Das Problem.* Dahinter stecken vier verschiedene Schwierigkeiten. Erstens die Größe: Ein lineares Modell braucht pro Spalte ein Gewicht, bei zwei Millionen Spalten sind das zwei Millionen Parameter nur für dieses eine Feature, und die meisten Spalten sehen im Training kaum einen Datensatz. Zweitens das Vokabular: Das Modell muss wissen, welche ID zu welcher Spalte gehört, diese Zuordnung muss beim Training erzeugt, gespeichert und im Betrieb identisch geladen werden. Drittens der _Cold Start_: Eine ID, die im Training nie vorkam, hat keine Spalte, und das Modell weiß nichts über sie. Viertens die _Long Tail_: Die Verteilung ist stark ungleich, ein paar Produkte machen den Großteil der Daten aus, die übrigen kommen so selten vor, dass ihre Gewichte kaum gelernt werden.

*Die Lösung.* Das Pattern ersetzt die gelernte Zuordnung durch eine berechnete. Eine _Hashfunktion_ macht aus jedem Text eine große Zahl, deterministisch: derselbe Text ergibt immer dieselbe Zahl, ähnliche Texte ergeben völlig verschiedene. Teilt man die Zahl mit Rest durch die gewünschte Spaltenzahl $B$, erhält man einen Index zwischen $0$ und $B - 1$, den _Bucket_. Das Feature besteht dann aus $B$ Spalten (One-Hot über den Bucket) statt aus zwei Millionen. Es gibt keine Tabelle, die man speichern müsste, und jede ID, auch eine nie gesehene, landet irgendwo (@abb-hash-prinzip).

#figure(
  {
    let b = json("../code/04-data-representation/hashed_feature.json").beispiel
    let kol(k) = b.filter(w => w.at(1) == k).len() > 1
    let y(k) = k * 1.25 + 0.4
    diagram(
      node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 5pt, spacing: (55mm, 6.5mm),
      node((0.5, -1), text(size: 9pt)[`Bucket = murmurhash3_32(Wert) mod 4`], stroke: none),
      ..b.enumerate().map(((i, w)) => node((0, i), text(size: 9pt, w.at(0)), fill: luma(242))),
      ..range(4).map(k => node((1, y(k)), text(size: 9pt)[Bucket #k], fill: if kol(k) { rgb("#FBF1E6") } else { luma(242) }, stroke: if kol(k) { 0.8pt + orange } else { 0.6pt })),
      ..b.enumerate().map(((i, w)) => edge((0, i), (1, y(w.at(1))), "->", stroke: 0.8pt + (if kol(w.at(1)) { orange } else { gruen }))),
    )
  },
  caption: [Das Prinzip an sechs Werten und vier Buckets. Die Bucket-Nummern stammen aus dem echten Hash. Orange: Mehrere Werte teilen sich einen Bucket (Kollision), Bucket 1 bleibt leer.],
) <abb-hash-prinzip>

Die Zuordnung in der Abbildung stammt aus dem Skript `02_hashed_feature.py`:

#ausgabe("02_hashed_feature.txt", uv-run("02_hashed_feature.py"), bis: 6)


*Kollisionen quantifiziert.* Weil es weniger Buckets als Werte gibt, müssen manche Werte denselben Bucket teilen. Das ist eine _Kollision_: Das Modell kann die beiden Werte nicht mehr unterscheiden, es lernt für beide dasselbe Gewicht. Wie oft das passiert, lässt sich ausrechnen. Bei $n$ Werten und $B$ Buckets teilt sich ein bestimmter Wert seinen Bucket mit mindestens einem anderen mit der Wahrscheinlichkeit $1 - (1 - 1/B)^(n-1)$, bei großem $B$ etwa $1 - e^(-n/B)$. Sind es so viele Buckets wie Werte ($B = n$), kollidieren rund 63 % aller Werte ($1 - 1/e$). Die Messung mit echten Hashes bestätigt die Rechnung:


#ausgabe("02_hashed_feature.txt", none, von: 7)

Die Spalte "kollidiert" zeigt, welcher Anteil der 10 000 Produkte seinen Bucket mit mindestens einem anderen teilt; rechts daneben steht die Formel. Bei 10 000 Buckets sind es 63,1 % gemessen und 63,2 % gerechnet. Erst bei 1 000 000 Buckets, dem Hundertfachen der Werte, fällt der Anteil auf 1 %. Der Hash verteilt also gleichmäßig, und die Faustformel taugt, um die Größenordnung abzuschätzen.

*Wie viele Buckets?* Das ist eine Abwägung zwischen Speicher und Genauigkeit und hängt davon ab, _welche_ Werte kollidieren. Das zweite Experiment simuliert 5000 Kategorien mit Zipf-artiger Häufigkeit (wenige häufige, viele seltene Werte) und einer eigenen Klickrate je Kategorie; eine logistische Regression sieht nur das gehashte Feature. Als Maß dient die AUC (Fläche unter der ROC-Kurve: 0,5 entspricht Raten, 1,0 perfekter Trennung). Mit 16 Buckets ist das Modell fast blind (0,567), mit 4096 hat es den größten Teil der Qualität zurück (0,750), und ab 16 384 Buckets, dem Dreifachen der Kategorienzahl, fehlt nur noch etwa ein AUC-Punkt zur Referenz ohne Hashing (0,766 gegen 0,776, @abb-hash-auc). Eine belegbare Faustregel für die Bucket-Zahl kenne ich nicht. Praktisch schätzt man die Zahl der verschiedenen Werte, rechnet die Kollisionsformel aus und behandelt die Bucket-Zahl dann wie einen Hyperparameter (Pattern 15).

#figure(
  {
    let d = json("../code/04-data-representation/hashed_feature.json")
    grid(columns: (1fr, 1fr), column-gutter: 10pt,
      daten-plot(size: (5.6, 3.6), x-label: [Buckets $B$ (10 000 Werte)], y-label: [Anteil mit Kollision], x-mode: "log", x-tick-step: none, x-ticks: ((1000, [10#super[3]]), (10000, [10#super[4]]), (100000, [10#super[5]]), (1000000, [10#super[6]])), y-min: 0, y-max: 1.05, y-tick-step: 0.25, x-min: 700, x-max: 1500000, legend: "inner-north-east", {
        plot.add(d.kollision.map(p => (p.B, p.theorie)), style: (stroke: 1pt + luma(120)), label: [Formel])
        plot.add(d.kollision.map(p => (p.B, p.emp)), style: (stroke: none), mark: "o", mark-size: 0.14, mark-style: (fill: rgb("#B5651D"), stroke: none), label: [gemessen])
      }),
      daten-plot(size: (5.6, 3.6), x-label: [Buckets $B$ (5000 Kategorien)], y-label: [AUC], x-mode: "log", x-tick-step: none, x-ticks: ((16, [16]), (256, [256]), (4096, [4096]), (65536, [65536])), y-min: 0.5, y-max: 0.8, y-tick-step: 0.1, x-min: 12, x-max: 100000, {
        plot.add(d.auc.map(p => (p.B, p.auc)), style: (stroke: 1.2pt + rgb("#3171C6")), mark: "o", mark-size: 0.12, mark-style: (fill: rgb("#3171C6"), stroke: none))
        plot.add(((12, d.auc_onehot), (100000, d.auc_onehot)), style: (stroke: (paint: rgb("#2EAE7D"), dash: "dashed", thickness: 1pt)))
      }),
    )
  },
  caption: [Links: Anteil der Werte mit Kollision in Abhängigkeit von der Bucket-Zahl (Punkte gemessen, Linie nach Formel). Rechts: AUC eines Klickmodells mit gehashter Kategorie, gestrichelt grün die Referenz mit echtem One-Hot. Beide Achsen sind logarithmisch.],
) <abb-hash-auc>

*Cold Start.* Eine nie gesehene ID verursacht keinen Fehler, weil auch sie einen Bucket bekommt. Das ist Segen und Falle zugleich. Im Skript landet die unbekannte Kategorie in Bucket 899 und bekommt eine Klickwahrscheinlichkeit von 0,269, fast das Dreifache der Basisrate von 0,091. Das Gewicht dieses Buckets stammt von den bekannten Kategorien, die dort zufällig liegen; die Vorhersage ist also eine Art Durchschnitt zufälliger Nachbarn, sieht aber aus wie jede andere. Wer erkennen will, ob ein Wert neu ist, muss das separat prüfen. Fachlich ist das Verhalten meist besser als ein Absturz und schlechter als ein bewusst gewählter Standardwert.

*FarmHash und MurmurHash.* Das Buch erzeugt den Hash mit FarmHash (in BigQuery `FARM_FINGERPRINT`). scikit-learn bietet `FeatureHasher`, der die 32-Bit-Variante von MurmurHash3 verwendet (so auch `sklearn.utils.murmurhash3_32`). Das Prinzip ist gleich, die Bucket-Nummern sind es nicht; für ein Modell ist das unerheblich, solange Training und Betrieb dieselbe Funktion nutzen. Die Primärquelle ist #cite(<weinberger_feature_hashing_2009>, form: "prose"); sie leiten zusätzlich ein Vorzeichen aus dem Hash ab, damit sich Kollisionen im Mittel aufheben (`alternate_sign=True`, der Standard von `FeatureHasher`; im Experiment abgeschaltet, damit das Ergebnis mit One-Hot vergleichbar bleibt). Pythons eingebaute `hash()` ist dagegen ungeeignet: Sie ist bei Strings pro Prozess mit einem zufälligen Startwert versehen („gesalzen“), sodass derselbe String bei jedem Programmstart eine andere Zahl ergibt, und die letzten Zeilen der Ausgabe zeigen es, derselbe String landet in drei Prozessen in drei verschiedenen Buckets. Wer `hash()` verwendet, baut Training-Serving Skew direkt ins Feature ein.

*Trade-offs und Grenzen.* Ein Bucket lässt sich nicht zurückverfolgen: Das Gewicht gehört zu einer Gruppe von Werten, die man nur mit einer zusätzlichen Tabelle wieder auflösen könnte. Das Modell ist deshalb schwerer zu erklären. Kollisionen treffen die seltenen Werte härter als die häufigen, denn ein seltener Wert, der sich einen Bucket mit einem häufigen teilt, wird von diesem überstimmt. Bei Features, die Personengruppen beschreiben, kann das zur Folge haben, dass eine kleine Gruppe im Modell unsichtbar wird (Kapitel 10). Außerdem ist unklar, was passiert, wenn die Bucket-Zahl später geändert wird: Alle Zuordnungen ändern sich, das Modell muss neu trainiert werden.

*Wann nicht.* Bei wenigen hundert Werten ist One-Hot einfacher und exakt. Wenn jeder Wert einzeln erklärbar sein muss, etwa weil ein Regulator nachfragt, ist Hashing das falsche Werkzeug. Und wenn die Kategorie _inhaltlich_ ähnliche Werte hat (Produkte derselben Marke), ist Pattern 2 besser, weil Hashing Ähnlichkeit zerstört: Zwei fast gleiche Texte landen in völlig verschiedenen Buckets.

*Bezug zu Software Engineering.* Der Gedanke ist so alt wie die Hash-Tabelle, nur ohne Kollisionsauflösung: Man nimmt in Kauf, dass zwei Schlüssel sich einen Platz teilen, und tauscht dafür festen Speicherbedarf und den Verzicht auf eine zentrale Zuordnungstabelle. Wie beim Sharding einer Datenbank verteilt eine Hashfunktion Last ohne Koordination, und wie dort ist die Wahl der Funktion und der Anzahl eine Entscheidung, die man später nur teuer ändern kann. Auch das Fehlen von Zustand erinnert an _Stateless Serving_ (Pattern 16): Das Feature braucht beim Betrieb nichts, was nicht im Code steht.

#erklaere(
  [Ein Hashed Feature ist eine Zuordnungstabelle, die man nicht speichern muss: Eine Rechenvorschrift sagt für jeden Wert, in welche von $B$ Schubladen er kommt. Dafür landen manchmal zwei Werte in derselben Schublade, und das Modell kann sie nicht mehr unterscheiden. Lassen Sie die Studierenden ausrechnen, wie viele Schubladen sie für 10 000 Werte brauchen, damit weniger als 10 % kollidieren, und das Ergebnis mit @abb-hash-auc vergleichen.],
  [Warum ist `hash()` aus Python für Feature-Hashing in einem Modell, das später als Service läuft, gefährlich?],
  [Weil der Wert pro Prozess zufällig gesalzen ist. Das Training liefert andere Buckets als der Service, und das Modell sieht im Betrieb Features, die es so nie gelernt hat, ohne dass ein Fehler auftritt.],
)

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 2, Pattern "Hashed Feature"; #cite(<weinberger_feature_hashing_2009>, form: "prose").


== Pattern 2: Embeddings

*Szenario.* Eine Suchmaschine soll aus wenigen Wörtern das Thema eines Dokuments erkennen. Das Vokabular umfasst 100 000 Wörter. Wir bauen das im Kleinen nach: 24 Wörter aus vier Themen (Sport, Finanzen, Kochen, Technik), 6000 künstliche Dokumente zu je drei Wörtern, davon 15 % der Wörter themenfremd. Die Datei ist `03_embeddings.py`.

*Das Problem.* Mit One-Hot ist jedes Wort ein Vektor aus lauter Nullen und einer Eins an seiner eigenen Position. Zwei verschiedene Wörter haben dann nichts gemeinsam: Der Kosinus des Winkels zwischen ihren Vektoren ist immer 0, "Aktie" ist von "Dividende" genauso weit entfernt wie von "Pfanne". Die Information, dass die beiden zusammengehören, steckt nicht in der Repräsentation, und das Modell muss für jedes Wort einzeln lernen, was es bedeutet. Was es über "Aktie" gelernt hat, hilft ihm bei einem selten gesehenen Wort wie "Dividende" nicht. Dazu kommt wieder die Größe: Ein Vektor mit 100 000 Stellen, in dem fast alles null ist, ist ein teurer Weg, eine Zahl zwischen 0 und 99 999 zu übertragen.

*Die Lösung.* Ein _Embedding_ ordnet jeder Kategorie einen kurzen Vektor mit reellen Zahlen zu, etwa mit 2, 8 oder 64 Stellen, in dem ähnliche Kategorien nah beieinander liegen. Die Zuordnung ist eine Tabelle $W$ mit einer Zeile pro Kategorie und $d$ Spalten. Der entscheidende Gedanke ist, dass man diese Tabelle nicht von Hand baut, sondern vom Netz _lernen_ lässt, und zwar als ganz gewöhnliche Gewichte der ersten Schicht. Multipliziert man den One-Hot-Vektor mit der Tabelle, bleibt von der Matrixmultiplikation nur eine Zeile übrig: die des Worts (@abb-emb-mechanik). Beim Training berechnet das Netz den Fehler am Ausgang und verschiebt über Backpropagation alle beteiligten Gewichte ein Stückchen, auch die Zeilen von $W$. Wörter, die zu denselben Ausgaben führen sollen, werden dabei in dieselbe Richtung geschoben. Am Ende liegen sie nahe beieinander, ohne dass jemand diese Nähe vorgegeben hätte.

#figure(
  {
    let e = json("../code/04-data-representation/embeddings.json").filter(w => w.wort == "Aktie").first()
    let k = (fill: luma(242), stroke: 0.6pt + luma(150), corner-radius: 3pt)
    diagram(
      node-inset: 6pt, spacing: (17mm, 9mm), node-stroke: 0.6pt, node-corner-radius: 3pt,
      node((0, 0), text(size: 9pt)[One-Hot für "Aktie" \ `0 0 0 0 0 0 1 0 … 0` \ (24 Stellen)], fill: luma(242)),
      edge("->", label: text(size: 9pt)[$times$], label-side: left, label-sep: 2pt),
      node((1, 0), text(size: 9pt)[Tabelle $W$ \ 24 Zeilen $times$ 2 Spalten \ gelernte Gewichte], fill: blau-hell, stroke: 0.8pt + blau),
      edge("->", label: text(size: 9pt)[Zeile 7], label-side: left, label-sep: 2pt),
      node((2, 0), text(size: 9pt)[Embedding \ (#str(e.x).replace(".", ","); #str(e.y).replace(".", ","))], fill: rgb("#E5F5EE"), stroke: 0.8pt + gruen),
      edge("->"),
      node((3, 0), text(size: 9pt)[restliches Netz \ $arrow.r$ Thema], fill: luma(242)),
    )
  },
  caption: [Die Embedding-Schicht ist eine Tabelle. Der One-Hot-Vektor wählt eine Zeile; die Zahlen im grünen Kasten sind die echten Werte, die das Netz in `03_embeddings.py` für "Aktie" gelernt hat.],
) <abb-emb-mechanik>

Im Code ist das kurz. Ein Netz mit einer versteckten Schicht aus nur zwei Neuronen bekommt die Wörter als One-Hot-Spalten (ein Dokument hat bis zu drei Einsen) und lernt, das Thema vorherzusagen. Die Gewichtsmatrix zwischen Eingabe und versteckter Schicht hat dann 24 Zeilen und 2 Spalten, und jede Zeile ist der gelernte Vektor eines Worts.

#code-aus("03_embeddings.py", "# Versteckte Schicht", bis: "# Ähnlichkeit")
#ausgabe("03_embeddings.txt", uv-run("03_embeddings.py"))

Die Ausgabe bestätigt die Behauptung: `one_hot @ W` ist identisch mit dem Herausgreifen der Zeile. Frameworks wie Keras oder PyTorch bieten deshalb eine eigene Embedding-Schicht, die gleich nachschlägt und sich die Multiplikation mit lauter Nullen spart.

*Ähnlichkeit messen.* Der Kosinus des Winkels zwischen zwei Vektoren, $cos(a, b) = (a dot b)/(|a| dot |b|)$, ist $+1$ bei gleicher Richtung, $0$ bei rechtem Winkel und $-1$ bei Gegenrichtung. Zwischen Wörtern desselben Themas liegt er im Mittel bei +0,99, zwischen Wörtern verschiedener Themen bei −0,33. Die ähnlichsten Wörter zu "Aktie" sind "Dividende", "Börse" und "Zins", das unähnlichste ist "Compiler". @abb-emb-karte zeigt die 24 Vektoren als Punkte in der Ebene. Das Netz hat vier Gruppen gebildet, ohne dass die Themen in den Eingabedaten als Wort vorkamen; es kannte nur die Zielklasse.

#figure(
  {
    let d = json("../code/04-data-representation/embeddings.json")
    let farben = (Sport: rgb("#3171C6"), Finanzen: rgb("#B5651D"), Kochen: rgb("#2EAE7D"), Technik: rgb("#7A4FA3"))
    daten-plot(size: (11, 6.6), x-label: [Dimension 1], y-label: [Dimension 2], x-tick-step: 1, y-tick-step: 1, x-min: -2, x-max: 2, y-min: -2, y-max: 2, {
      for (thema, farbe) in farben {
        let ws = d.filter(w => w.thema == thema)
        plot.add(ws.map(w => (w.x, w.y)), style: (stroke: none), mark: "o", mark-size: 0.16, mark-style: (fill: farbe, stroke: none))
        let cx = ws.map(w => w.x).sum() / ws.len()
        let cy = ws.map(w => w.y).sum() / ws.len()
        let oben = ws.map(w => w.y).fold(-9, calc.max)
        let unten = ws.map(w => w.y).fold(9, calc.min)
        let namen = ws.map(w => w.wort)
        plot.annotate({
          draw.content((cx, if cy > 0 { oben + 0.5 } else { unten - 0.5 }),
            text(size: 8.5pt, fill: farbe, align(center)[*#thema* \ #namen.slice(0, 3).join(", ") \ #namen.slice(3).join(", ")]))
        })
      }
    })
  },
  caption: [Die gelernte Embedding-Tabelle (24 Wörter, 2 Dimensionen). Wörter desselben Themas bilden eine Gruppe, obwohl das Thema nie als Eingabe vorkam. Die Punkte sind die echten Zeilen der Gewichtsmatrix; Wörter mit fast gleichen Vektoren überdecken sich; deshalb stehen die Wörter einer Gruppe als Liste daneben.],
) <abb-emb-karte>

Dass es so sauber aussieht, liegt daran, dass die Daten so gebaut sind. Echte Embeddings sind unordentlicher. Das bekannteste Beispiel sind die Wortvektoren aus word2vec @mikolov_word2vec_2013: Ein Netz lernt, ein Wort aus seinen Nachbarwörtern vorherzusagen (oder umgekehrt), und die Embedding-Tabelle ist das Nebenprodukt. Bei Tabellendaten funktioniert derselbe Gedanke: #cite(<guo_entity_embeddings_2016>, form: "prose") ersetzten kategoriale Spalten wie Filiale oder Wochentag durch gelernte _Entity Embeddings_.

*Welche Dimension?* Die Dimension $d$ ist ein Hyperparameter: zu wenige verlieren Information, zu viele kosten Speicher und fördern Überanpassung (_Overfitting_: das Modell lernt die Trainingsdaten auswendig statt des Musters). Eine bekannte Faustregel aus dem TensorFlow-Blog setzt $d$ auf die vierte Wurzel der Kategorienzahl @tensorflow_feature_columns_2017: 2,2 für 24 Wörter, 8,4 für 5000 Kategorien, 31,6 für eine Million (das Skript rechnet es aus). Sie ist ein Startwert ohne Garantie, die beste Dimension bestimmt man über Validierungsdaten (Pattern 15). Man kann Embeddings auch vortrainiert aus einer anderen Aufgabe übernehmen, ein Fall von Transfer Learning (Pattern 13).

*Trade-offs und Grenzen.* Ein Embedding braucht genug Daten pro Kategorie, sonst liegt die Zeile nach dem Training noch fast dort, wo sie zufällig gestartet ist. Für eine neue Kategorie gibt es keine Zeile (Cold Start); üblich ist eine mittrainierte Zeile für "unbekannt". Die Achsen haben keine Bedeutung für Menschen, und zweidimensionale Bilder wie @abb-emb-karte sind bei realen Embeddings mit 64 oder 300 Dimensionen _Projektionen_ (etwa mit PCA oder t-SNE), die Abstände verzerren. Ein Embedding enthält außerdem, was für die Trainingsaufgabe nützlich war, einschließlich der Vorurteile in den Daten: #cite(<bolukbasi_debiasing_2016>, form: "prose") zeigen, dass Wortvektoren aus Nachrichtentexten Geschlechterstereotype enthalten (Kapitel 9).

*Wann nicht.* Bei wenigen Kategorien mit vielen Beispielen je Kategorie reicht One-Hot, und das Modell bleibt einfacher. Mit einem sehr kleinen Datensatz kann man die Tabelle nicht sinnvoll lernen; dann sind vortrainierte Embeddings oder One-Hot die bessere Wahl.

*Bezug zu Software Engineering.* Ein Embedding ist ein Surrogatschlüssel mit Bedeutung. Aus einer beliebigen ID, die nur Identität trägt, wird ein Punkt in einem Raum, in dem Abstand etwas aussagt. Das macht Ähnlichkeitssuche möglich (nächste Nachbarn im Raum, wie sie Vektordatenbanken anbieten). Der Embedding-Raum ist zugleich eine Schnittstelle, und zwar eine zerbrechliche: Wird das Modell neu trainiert, entsteht ein neuer Raum, und die alten Vektoren sind mit den neuen nicht vergleichbar, so wie sich ein anderes Serialisierungsformat nicht mit dem alten lesen lässt. Embeddings gehören deshalb zusammen mit dem Modell versioniert (Pattern 27).

#erklaere(
  [Stellen Sie sich eine Landkarte vor, auf der jedes Wort einen Ort bekommt. Das Netz verschiebt die Orte so lange, bis Wörter, die zu denselben Antworten führen, nah beieinander liegen. Die Nachbarschaft auf der Karte ist ein Ergebnis des Trainings, nicht der Eingabe. Technisch ist die Karte nur die erste Gewichtsmatrix des Netzes. Zeigen Sie @abb-emb-karte und lassen Sie raten, welche vier Gruppen zu sehen sind.],
  [Warum hilft ein Embedding dem Modell bei einem selten gesehenen Wort, ein One-Hot-Vektor aber nicht?],
  [Weil das seltene Wort nahe bei häufigeren Wörtern liegt und das Modell dort schon gelernt hat, wie sich diese Gegend auf die Ausgabe auswirkt. Beim One-Hot hat jedes Wort eine eigene, unabhängige Spalte, aus der nichts auf andere übertragbar ist.],
)

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 2, Pattern "Embeddings"; Mikolov et al. @mikolov_word2vec_2013; #cite(<guo_entity_embeddings_2016>, form: "prose"); #cite(<tensorflow_feature_columns_2017>, form: "prose").


== Pattern 3: Feature Cross

*Szenario.* Ein Verkehrsdienst will vorhersagen, ob eine Zufahrtsstraße ins Stadtzentrum überlastet ist. Zwei Features liegen vor: die Richtung (stadteinwärts oder stadtauswärts) und die Tageszeit (Vormittag oder Nachmittag). Die Pendlerlogik ist einfach: Morgens fahren alle hinein, nachmittags alle hinaus. Stau gibt es also, wenn der Verkehr in der Hauptrichtung läuft. Im Skript `04_feature_cross.py` entstehen daraus 20 000 Beobachtungen, bei denen in 10 % der Fälle das Ergebnis zufällig umgedreht wird.

*Das Problem.* Ein lineares Modell, hier eine logistische Regression, bildet eine gewichtete Summe: ein Gewicht für die Richtung, eines für die Tageszeit, dazu eine Konstante. Die Wirkung von "Vormittag" ist in dieser Summe immer dieselbe, ganz gleich, in welcher Richtung gefahren wird. In den Daten kippt sie aber mit der Richtung: Vormittags ist es stadteinwärts voll und stadtauswärts leer, nachmittags umgekehrt. Betrachtet man jedes Feature für sich, liegt die Staurate bei rund 50 %, die Features scheinen wertlos. Das ist die XOR-Funktion ("entweder-oder"), und ihre Unlösbarkeit für ein einzelnes lineares Element gehört seit #cite(<minsky_perceptrons_1969>, form: "prose") zu den Klassikern der Disziplin.

*Die Lösung.* Das Pattern fügt ein neues Feature hinzu, das die Kombination beider Werte beschreibt, das _Feature Cross_ (Kreuzprodukt). Aus zwei Features mit je zwei Werten wird ein Feature mit vier: "einwärts × vormittags", "einwärts × nachmittags", und so weiter. Es wird wie jede Kategorie per One-Hot kodiert, und jede der vier Zellen bekommt ein eigenes Gewicht (@abb-cross). Das Modell bleibt linear, aber die Wechselwirkung ist jetzt ein eigenes Feature, das es gewichten kann.

#figure(
  {
    let d = json("../code/04-data-representation/feature_cross.json")
    let zelle(r, t) = d.zellen.filter(z => z.richtung == r and z.tageszeit == t).first().stau
    let farbe(v) = if v > 0.5 { rgb("#D9F0E7") } else { rgb("#F7E6D3") }
    let z(r, t) = {
      let v = zelle(r, t)
      table.cell(fill: farbe(v), align: center)[#text(size: 10pt, weight: "bold")[#str(calc.round(v * 100, digits: 0)) %] \ #text(size: 8.5pt, fill: grau)[Staurate]]
    }
    let balken(name, wert, farbe) = (
      text(size: 9pt, name),
      box(width: wert * 4.2cm, height: 0.45cm, fill: farbe),
      text(size: 9pt, [#str(calc.round(wert * 100, digits: 1)).replace(".", ",") %]),
    )
    grid(columns: (auto, 1fr), column-gutter: 1cm, align: horizon,
      table(columns: (2.8cm, 2.4cm, 2.4cm), fill: none, stroke: 0.5pt + luma(180), inset: 6pt, align: center + horizon,
        table.header([], [Vormittag], [Nachmittag]),
        [stadteinwärts], z("stadteinwaerts", "vormittag"), z("stadteinwaerts", "nachmittag"),
        [stadtauswärts], z("stadtauswaerts", "vormittag"), z("stadtauswaerts", "nachmittag"),
      ),
      grid(columns: (auto, auto, auto), column-gutter: 8pt, row-gutter: 9pt, align: (right + horizon, left + horizon, left + horizon),
        ..balken("linear, ohne Cross", d.ohne, orange),
        ..balken("linear, mit Cross", d.cross, gruen),
        ..balken("Netz, ohne Cross", d.mlp, rgb("#3171C6")),
      ),
    )
  },
  kind: image, supplement: [Abbildung],
  caption: [Links: Staurate je Kombination (echte Werte aus den Daten); jede Zeile und jede Spalte allein mittelt zu rund 50 %. Rechts: Genauigkeit auf Testdaten. Mit 10 % Rauschen sind 90 % das Maximum.],
) <abb-cross>

#code-aus("04_feature_cross.py", "def lauf", bis: "# Zum Vergleich")
#ausgabe("04_feature_cross.txt", uv-run("04_feature_cross.py"))

Die Genauigkeit springt von 50,4 % auf 90,1 %, und mehr ist wegen des Rauschens nicht möglich. Die Zeile "Netz mit versteckter Schicht" zeigt eine wichtige Einschränkung des Pattern: Ein Netz mit einer versteckten Schicht lernt die Wechselwirkung auch ohne Cross (90,1 %), und ein Entscheidungsbaum der Tiefe 2 ebenfalls (90,1 %). Eine versteckte Schicht kann aus den Eingaben neue Kombinationen bilden. Feature Crosses sind daher vor allem für Modelle wichtig, die selbst nur einfach gewichten, und für Fälle mit sehr vielen, dünn besetzten Kategorien, wo ein tiefes Netz die Kombinationen aus zu wenigen Beispielen lernen müsste. #cite(<cheng_wide_deep_2016>, form: "prose") nutzen deshalb in ihrem Empfehlungssystem bei Google Play ein breites lineares Modell mit gekreuzten Features, das sich Kombinationen "merkt", neben einem tiefen Netz, das verallgemeinert.

*Zahlenfeatures.* Kreuzen kann man nur Kategorien. Eine Zahl wie der Breitengrad wird zuerst in Buckets zerlegt, dann kreuzt man die Buckets von Breite und Länge zu einem Gitter aus Kacheln mit je einem Gewicht.

*Trade-offs und Grenzen.* Der Preis ist kombinatorisch. Aus Wochentag (7) und Stunde (24) werden 168 Zellen, mit 40 Stadtteilen 6720, mit zusätzlich 12 Fahrzeugtypen 80 640. Je mehr Zellen, desto weniger Beispiele je Zelle, desto unsicherer die Gewichte, und das Modell wächst. Man behilft sich, indem man nur fachlich sinnvolle Paare kreuzt, seltene Zellen verwirft oder das Kreuzprodukt hasht (Pattern 1) beziehungsweise in ein Embedding überführt (Pattern 2). Welche Paare man kreuzt, bestimmt Domänenwissen. Die Einzelgewichte lassen sich nach dem Kreuzen nicht mehr isoliert lesen: Der Beitrag von "Vormittag" hängt davon ab, welche Zelle gerade aktiv ist.

*Wann nicht.* Bei Bäumen und Ensembles ist das Pattern meist überflüssig, weil sie durch ihre Verzweigungen Kombinationen selbst bilden, und bei zu dünnen Zellen schadet die Kreuzung mehr, als sie nützt.

*Bezug zu Software Engineering.* Ein Feature Cross ist der Zustandsraum zweier Zustandsvariablen: Zwei boolesche Variablen ergeben vier Zustände, und die Wechselwirkung liegt in der Zelle, nicht in den Variablen. Dieselbe Explosion kennt man aus dem Testen von Konfigurationen, bei dem man deshalb nicht alle Kombinationen prüft. Und wer schon einmal einen zusammengesetzten Schlüssel (Composite Key) in einer Datenbank gebaut hat, kennt den Gedanken: Die Identität steckt im Tupel, nicht in den Spalten.

#erklaere(
  [Zeigen Sie die Vierfeldertafel aus @abb-cross und fragen Sie, in welchem Feature allein der Stau erkennbar ist. Die Antwort ist: in keinem. Ein lineares Modell addiert Einflüsse, aber hier steckt die Information im Zusammenspiel, und das Cross macht aus dem Zusammenspiel eine eigene Spalte. Danach die Gegenfrage: Wann bräuchten wir das Cross nicht?],
  [Ein Entscheidungsbaum erreicht ohne Cross dieselbe Genauigkeit wie das lineare Modell mit Cross. Warum?],
  [Weil ein Baum zuerst nach der Richtung und dann innerhalb jedes Zweigs nach der Tageszeit teilt. Damit bildet er genau die Kombinationen, die das Cross von Hand vorgibt.],
)

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 2, Pattern "Feature Cross"; #cite(<cheng_wide_deep_2016>, form: "prose"); #cite(<minsky_perceptrons_1969>, form: "prose").

== Pattern 4: Multimodal Input

*Szenario.* Eine Versicherung will aus jeder Schadensmeldung vorhersagen, ob ein Totalschaden vorliegt. Eine Meldung besteht aus der geschätzten Schadenshöhe (Zahl), einer Freitextbeschreibung (Text) und einem Foto (Bild). Wir bauen die Daten im Skript `05_multimodal.py` künstlich: 4000 Meldungen, in jeder der drei Quellen steckt ein schwaches Signal. Das Foto ist hier ein 8 × 8 Pixel großes verrauschtes Graustufenbild und steht stellvertretend für echte Bilder.

*Das Problem.* Ein Modell erwartet _einen_ Vektor aus Zahlen. Die drei Quellen sind aber verschieden: Eine Zahl, eine variable Folge von Wörtern, ein Raster aus Pixeln. Der naheliegende Weg ist, sich auf eine Quelle zu beschränken, meist die, die am leichtesten zu verarbeiten ist. Das verschenkt Information, die in den anderen Quellen steckt. Das zweite Problem ist weniger offensichtlich: Selbst bei _einer_ Quelle ist nicht klar, welche Repräsentation die richtige ist. Man kann die Schadenshöhe roh oder logarithmiert eingeben, als Zahl oder in Buckets, einen Text als Wortzählung oder als Embedding.

*Die Lösung.* Jede Quelle wird in einen eigenen Teilvektor übersetzt, und die Teilvektoren werden hintereinandergehängt (_Concatenate_) zu einem Gesamtvektor, mit dem das Modell arbeitet (@abb-multimodal-input). Die Übersetzung wählt man je Quelle: bei Zahlen Skalierung und Logarithmus, bei Text zum Beispiel TF-IDF (eine gewichtete Wortzählung, die häufige, aussagearme Wörter herunterwichtet), bei Bildern die Pixelwerte oder die Ausgabe eines bildverarbeitenden Netzes. Die zweite Variante des Pattern ist, dieselben Daten mehrfach zu repräsentieren und alle Repräsentationen anzuhängen. Das Modell darf dann wählen, was ihm nützt. In @abb-multimodal-input ist die Schadenshöhe deshalb zweimal vertreten.

#figure(
  diagram(
    node-stroke: 0.6pt, node-corner-radius: 3pt, node-inset: 6pt, spacing: (13mm, 6mm),
    node((0, 0.5), text(size: 9pt)[Schadenshöhe \ (Zahl)], fill: luma(242)),
    node((0, 2.4), text(size: 9pt)[Beschreibung \ (Text)], fill: luma(242)),
    node((0, 3.6), text(size: 9pt)[Foto \ (8 × 8 Pixel)], fill: luma(242)),
    edge((0, 0.5), (1, 0), "->"),
    edge((0, 0.5), (1, 1), "->"),
    node((1, 0), text(size: 9pt)[log + z-Score], fill: blau-hell, stroke: 0.8pt + blau),
    node((1, 1), text(size: 9pt)[8 Buckets (One-Hot)], fill: blau-hell, stroke: 0.8pt + blau),
    edge((0, 2.4), (1, 2.4), "->"),
    node((1, 2.4), text(size: 9pt)[TF-IDF], fill: blau-hell, stroke: 0.8pt + blau),
    edge((0, 3.6), (1, 3.6), "->"),
    node((1, 3.6), text(size: 9pt)[Pixel, z-Score], fill: blau-hell, stroke: 0.8pt + blau),
    edge((1, 0), (2, 1.8), "->"),
    edge((1, 1), (2, 1.8), "->"),
    edge((1, 2.4), (2, 1.8), "->"),
    edge((1, 3.6), (2, 1.8), "->"),
    node((2, 1.8), text(size: 9pt)[Gesamtvektor \ (aneinandergehängt)], fill: rgb("#E5F5EE"), stroke: 0.8pt + gruen),
    edge((2, 1.8), (3, 1.8), "->"),
    node((3, 1.8), text(size: 9pt)[Modell \ $arrow.r$ Totalschaden?], fill: luma(242)),
  ),
  caption: [Multimodal Input: Jede Quelle bekommt ihre eigene Übersetzung in Zahlen, auch dieselbe Quelle darf mehrfach vorkommen. Danach wird alles zu einem Vektor aneinandergehängt.],
) <abb-multimodal-input>

In scikit-learn erledigt das ein `ColumnTransformer`: Er wendet auf jede Spalte oder Spaltengruppe eine eigene Übersetzung an und hängt die Ergebnisse zusammen. Das ganze Gebilde (Übersetzungen plus Modell) ist eine `Pipeline` und wird als eine Einheit trainiert und gespeichert.

#code-aus("05_multimodal.py", "def modell", bis: "ergebnis = []")
#ausgabe("05_multimodal.txt", uv-run("05_multimodal.py"))

Jede Quelle allein liefert nur mäßige Ergebnisse (Tabelle 65,7 %, Text 68,3 %, Bild 62,7 %), Tabelle und Text zusammen kommen auf 71,3 %, alle drei auf 73,3 %. Der Zuwachs entsteht, weil die drei Signale unabhängig voneinander Auskunft geben. Bei nur 1200 Testmeldungen sind Unterschiede von ein bis zwei Prozentpunkten allerdings nicht belastbar. Hängt man die Schadenshöhe zusätzlich in Buckets an, ändert sich nichts (73,3 %). Dass die Mehrfachrepräsentation hier wenig bringt, ist ein ehrliches Ergebnis: Sie lohnt sich, wenn der Zusammenhang nicht gleichmäßig verläuft, und das war in unserer Simulation nicht der Fall.

*Trade-offs und Grenzen.* Der Gesamtvektor ist so lang wie die Summe seiner Teile, und die Teile sind selten gleich lang: Ein Bild mit 10 000 Pixeln liefert 10 000 Spalten neben einer einzelnen Zahl, und bei Abstandsverfahren oder starker Regularisierung bestimmen die vielen Spalten das Ergebnis. Üblich ist, jede Quelle zuerst auf eine feste, vergleichbare Länge zu verdichten, zum Beispiel mit einem Embedding je Quelle. Zweitens sind die Quellen im Betrieb nicht immer alle da: Fehlt das Foto, braucht das Modell eine Vorgabe für diesen Fall, und die muss schon im Training vorkommen, sonst ist es auf die fehlende Quelle nicht vorbereitet. Drittens steigt der Aufwand für die Übersetzungen, und jede muss im Betrieb exakt so laufen wie im Training (Pattern 21). Eine Alternative zum Zusammenhängen vor dem Modell ist, für jede Quelle ein eigenes Modell zu trainieren und die Vorhersagen später zusammenzuführen. Das ist dann ein Ensemble (Pattern 7).

*Wann nicht.* Wenn eine Quelle fast die gesamte Information trägt, kosten weitere Übersetzungen mehr Wartung, als sie bringen, und wenn nicht sicher ist, dass alle Quellen im Betrieb vorliegen, ist ein Modell mit wenigen robusten Eingaben oft besser.

*Bezug zu Software Engineering.* Das Pattern ist ein _Adapter_ je Datenquelle: Jede Schnittstelle mit eigenem Format wird auf eine gemeinsame abgebildet, hier einen Zahlenvektor. Das entspricht einem Anti-Corruption-Layer, der verhindert, dass die Eigenheiten einer Quelle ins Modell durchschlagen. Die Pipeline, die alle Adapter zusammen mit dem Modell als eine Einheit speichert, ist das, was in der Softwaretechnik ein einzelnes deploybares Artefakt wäre.

#erklaere(
  [Ein Modell sieht immer nur eine Liste von Zahlen. Ob diese Zahlen aus einer Tabelle, aus Text oder aus einem Foto stammen, weiß es nicht und braucht es nicht zu wissen. Die Aufgabe des Pattern ist, jede Quelle in Zahlen zu übersetzen und alle Übersetzungen nebeneinanderzulegen. Zeigen Sie die Tabelle der Ergebnisse und lassen Sie die Studierenden erklären, warum die Kombination besser ist als jede Quelle allein.],
  [Ein Bild liefert 10 000 Pixelwerte, die Schadenshöhe eine einzige Zahl. Was kann beim Zusammenhängen passieren, und was tut man dagegen?],
  [Die 10 000 Pixelspalten dominieren den Vektor, und die eine Zahl geht unter. Man verdichtet jede Quelle zuerst auf eine vergleichbare Länge, etwa mit einem Embedding, oder skaliert beide Teile passend.],
)

*Quellen.* #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"), Kapitel 2, Pattern "Multimodal Input". Für das Beispiel gibt es keine Primärquelle, es ist für das Handbuch konstruiert.

#import "lib.typ": *

= Gültige Schlüsse aus LLM-Labels

Du hast 10~000 Social-Media-Posts und willst wissen, wie viele davon eine Beschwerde enthalten. Ein Sprachmodell ordnet alle 10~000 in wenigen Minuten ein und meldet: 32,8~% Beschwerden. Hättest du alle Posts von Menschen lesen lassen, wären es 31~% gewesen. Das wirkt wie eine kleine Abweichung. Dann fragst du, ob die Posts in Gruppe 1 häufiger Beschwerden enthalten als die in Gruppe 0, etwa weil es zwei verschiedene Foren sind. Das Modell zeigt einen Unterschied von 7 Prozentpunkten, die Menschen hätten 15 gezählt. Beide Zahlen kommen mit einer winzigen Fehlerspanne daher, die Sicherheit vortäuscht.

Das ist der Normalfall, nicht Pech. Ein Sprachmodell macht Fehler, und die Fehler sind nicht zufällig verteilt: Sie schieben das Ergebnis meist in dieselbe Richtung. Mehr Posts ändern daran nichts, sie machen nur die Scheinsicherheit größer. In Kapitel 5 hast du gelernt zu messen, wie gut ein Modell zu menschlichen Urteilen passt. Dieses Kapitel beantwortet die nächste Frage: Wie kommst du aus LLM-Labels trotzdem zu einer Zahl, der du und deine Leser trauen können?

Die Lösung ist einfacher, als sie klingt. Eine kleine, zufällig gezogene Stichprobe lässt du zusätzlich von Menschen prüfen. Dort siehst du, um wie viel das Modell im Schnitt danebenliegt, und um genau diesen Betrag korrigierst du das Ergebnis der großen Menge. Das Verfahren heißt _prediction-powered inference_, kurz PPI. Du brauchst dafür keine Statistik, nur Prozent und Grundrechenarten. Der passende Foliensatz ist Foliensatz 06, das Notebook dazu heißt `notebooks/06_ppi_inference.ipynb`. Die Grundbegriffe stehen in _Das Nötigste vorab_ und werden hier kurz wiederholt, wo du sie brauchst.

#lernziele(
  [erklären, warum LLM-Labels wie echte Labels zu zählen falsche Ergebnisse und falsche Sicherheit liefert,],
  [Rauschen und Verzerrung unterscheiden und sagen, warum mehr Daten nur eines davon heilen,],
  [die Korrektur von PPI mit einfachen Zahlen nachrechnen und die ehrliche Fehlerspanne lesen,],
  [PPI, PPI++ und die Varianten wie DSL nach "was ist anders, wann nehme ich es" einordnen,],
  [die menschliche Stichprobe planen und PPI mit `ppi_py` ausführen,],
  [sagen, welche Fehler auch die beste Korrektur nicht behebt.],
)

== Genau, aber falsch

Aus Kapitel 5 kennst du Kennzahlen wie die accuracy, den Anteil der Fälle, in denen das Modell wie die Menschen urteilt. Liegt sie bei 90~%, nennst du das Modell genau. Für die Frage "wie viele Posts enthalten eine Beschwerde" scheint das zu genügen: Das Modell zählt, du übernimmst die Zahl. Genau darin liegt der Fehler.

#alltag[Deine Küchenwaage zeigt immer 20 Gramm zu viel an. Du wiegst tausendmal 500 Gramm Mehl und bildest den Durchschnitt: 520 Gramm, auf die Nachkommastelle stabil. Der Wert ist sehr sicher und sehr falsch. Die tausend Wägungen haben nur das Zufällige herausgemittelt, die Schieflage der Waage nicht. Ein LLM, das bestimmte Posts regelmäßig falsch einordnet, ist so eine Waage.]

#studie(titel: [Egami et al., 2023])[In einer Simulation hatten die Labels des Ersatzmodells eine accuracy von 90~%. Die nominellen "95~%-Spannen" für das Endergebnis enthielten den wahren Wert nur in etwa 40~% der Fälle @egami2023using. Hohe Genauigkeit der Labels heißt also nicht, dass das Endergebnis stimmt.]

Das Problem ist nicht neu und nicht auf LLMs beschränkt. Eine Literaturauswertung fand, dass nur 1 von 48 Studien der Kommunikationsforschung, die Textklassifikatoren einsetzten, Klassifikationsfehler korrigierte @teblunthuis2024misclassification. Bei Sprachmodellen kommt hinzu, dass schon die Wahl von Modell und Prompt das Ergebnis kippen kann: In einer Auswertung von 37 Aufgaben, 18 Modellen und 199 Prompts führten diese Entscheidungen allein in etwa 31~% der Fälle zu einer falschen Schlussfolgerung, selbst bei den besten Modellen (ein Preprint, also eine noch nicht begutachtete Fassung; Stand: 11. November 2026) @baumann2025large.

=== Das laufende Beispiel

Ein einziges simuliertes Beispiel trägt das ganze Kapitel. Es ist dasselbe wie in Foliensatz 06 und im Notebook. Jeder Post ist entweder "positiv" (enthält eine Beschwerde) oder nicht. Zwei Fragen interessieren dich: Wie viele Posts sind insgesamt positiv, und um wie viele Prozentpunkte ist Gruppe 1 häufiger positiv als Gruppe 0? Die wahren Antworten kennen nur wir, weil wir die Daten erfunden haben: 31~% und 15 Prozentpunkte.

#figure(
  table(columns: (auto, auto, auto),
    table.header([], [Gruppe 0], [Gruppe 1]),
    [*Anteil an den 10~000 Posts*], [60~%], [40~%],
    [*Wirklich positiv*], [25~%], [40~%],
    [*Vom LLM gefunden, von den wirklich positiven*], [90~%], [70~%],
    [*Fehlalarme, von den wirklich negativen*], [10~%], [15~%],
  ),
  caption: [Das simulierte Beispiel. Zusätzlich prüfen Menschen 500 zufällig gezogene Posts.],
) <k06-tab-beispiel>

Das Modell ist insgesamt etwa 86~% genau, macht aber in Gruppe 1 mehr Fehler als in Gruppe 0. Solche je nach Gruppe verschiedenen Fehler heißen _differential errors_; sie machen die zweite Frage besonders heikel.

Der Weg dieses Kapitels folgt der Abbildung. Das LLM labelt alles, Menschen prüfen eine Zufallsstichprobe, daran misst du den Fehler des Modells, korrigierst das Ergebnis und gibst eine ehrliche Spanne an.

#figure(
  diagram(spacing: (4mm, 6mm), node-corner-radius: 3pt,
    fknoten((0, 0), [LLM labelt alle Items], col: c-blue, filled: true, w: 29mm),
    fknoten((1, 0), [Menschen prüfen eine Stichprobe], w: 29mm),
    fknoten((2, 0), [Fehler des LLM dort messen], w: 29mm),
    fknoten((3, 0), [Ergebnis um den Fehler korrigieren], w: 29mm),
    fknoten((4, 0), [Ehrliche Spanne angeben], col: c-blue, filled: true, w: 29mm),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"), edge((3, 0), (4, 0), "->"),
  ),
  caption: [Der Ablauf von PPI in fünf Schritten.],
)

== Das Handwerkszeug: Schätzwert, Verzerrung, Spanne

Fünf Begriffe reichen für dieses Kapitel. Du kennst sie aus _Das Nötigste vorab_, hier kommen sie im Zusammenhang.

Ein *Schätzwert* (_estimate_) ist eine Zahl, die du aus einer Stichprobe berechnest, etwa "31~% der 500 geprüften Posts sind positiv". Der *wahre Wert* wäre das Ergebnis, wenn du jeden einzelnen Post prüfen könntest. Du siehst ihn nie. Wie beim Probieren eines Löffels Suppe gilt: Ein anderer Löffel schmeckt etwas anders. Zieht man eine neue Zufallsstichprobe, bekommt man einen etwas anderen Schätzwert. Die typische Größe dieser Wackelei heißt *Standardfehler* (_standard error_). Du wirst ihn in Papers lesen, ausrechnen musst du ihn nicht, das macht die Bibliothek.

Der Fehler eines Schätzwerts hat zwei Teile. *Rauschen* ist das Zufällige: mal etwas zu hoch, mal etwas zu niedrig, im Schnitt richtig. Es schrumpft mit größeren Stichproben. *Verzerrung* (_bias_) ist die Schieflage in eine feste Richtung, sie schrumpft nie. Ein Sprachmodell, das Ironie regelmäßig für Lob hält, bringt Verzerrung.

Ein *Konfidenzintervall* (_confidence interval_) ist eine Spanne, in der der wahre Wert plausibel liegt, so wie der Wetterbericht "zwischen 14 und 20 Grad" sagt. Schmal heißt "ich bin sicher", breit heißt "ich weiß wenig". Das "95~%" meint das Verfahren: Würdest du die Studie hundertmal wiederholen, enthielten etwa 95 der 100 Spannen den wahren Wert. Diesen Anteil nennt man *Abdeckung* (_coverage_). Eine Spanne, die laut Versprechen 95~% abdeckt und in Wirklichkeit 40~%, lügt über ihre Sicherheit.

#merke[Eine schmale Spanne, die den wahren Wert verfehlt, ist schlimmer als eine breite, die ihn trifft. Schmal sagt "ich bin sicher", und das stimmt dann nicht.]

=== Mehr Daten, mehr falsche Sicherheit

Hier liegt die Falle. Spannen werden mit mehr Daten schmaler, aber nur ums Rauschen herum. Die Verzerrung bleibt in der Mitte der Spanne stecken. Mit LLM-Labels ist die Datenmenge fast gratis zu vergrößern, also wird die Spanne um den falschen Wert immer enger. Die Abbildung zeigt das mit einem Modell, das in 85 von 100 Fällen richtig liegt (die Rechnung dazu steht im nächsten Abschnitt). Es meldet im Schnitt 36,7~% statt 31~%.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let xs(v) = (v - 24) * 0.5
    let zeile(y, label, lo, hi) = {
      content((-0.2, y), anchor: "east", text(font: "Inter", size: 7.5pt, label))
      line((xs(lo), y), (xs(hi), y), stroke: 2.2pt + c-blue)
      line((xs(lo), y - 0.12), (xs(lo), y + 0.12), stroke: 1.2pt + c-blue)
      line((xs(hi), y - 0.12), (xs(hi), y + 0.12), stroke: 1.2pt + c-blue)
    }
    line((xs(31), 0.55), (xs(31), -3.05), stroke: (paint: c-green, thickness: 1.1pt, dash: "dashed"))
    content((xs(31), 0.85), text(font: "Inter", size: 7.5pt, weight: "bold", fill: c-green)[wahrer Wert: 31 %])
    zeile(0, [100 Posts], 27.3, 46.1)
    zeile(-0.8, [1~000 Posts], 33.7, 39.7)
    zeile(-1.6, [10~000 Posts], 35.8, 37.6)
    zeile(-2.4, [1 Million Posts], 36.6, 36.8)
    line((0, -3.25), (xs(48), -3.25), stroke: 0.7pt + c-dark)
    for v in (24, 28, 32, 36, 40, 44, 48) {
      line((xs(v), -3.25), (xs(v), -3.37), stroke: 0.7pt + c-dark)
      content((xs(v), -3.65), text(font: "Inter", size: 7pt, [#v %]))
    }
  }),
  caption: [Spannen eines Modells, das 36,7 % statt 31 % meldet (gerundet). Mit 100 Posts ist die Spanne so breit, dass sie den wahren Wert noch einschließt. Mit mehr Posts schließt sie ihn aus, und zwar immer enger.],
) <k06-abb-spannen>

Fong und Tyler rechneten das mit einem Klassifikator durch, der in 90~% der Fälle richtig lag: Selbst bei einer Million Dokumenten enthielt die Spanne den wahren Wert in keinem der simulierten Durchläufe @fong2021machine. Das Lehrbuch dieses Kurses ergänzt einen verwandten Effekt: Bei sehr großen Datenmengen wird auch ein winziger Unterschied "signifikant", das heißt, sein p-Wert ist klein @haindl2027research. Ein kleiner p-Wert sagt nur, dass etwas wahrscheinlich nicht reiner Zufall ist. Er sagt weder, dass es wichtig ist, noch dass es stimmt.

#hoersaal([Kann ich das LLM nicht mehrmals fragen und die Antworten mitteln?], [Das mittelt das Zufällige weg, etwa den Einfluss der Temperatur. Die Verzerrung bleibt. Ein Modell, das dieselben Posts jedes Mal gleich falsch einordnet, tut das beim zehnten Durchlauf genauso wie beim ersten. Gegen die Verzerrung hilft nur der Vergleich mit Menschen.])

== Warum einfaches Zählen scheitert

Du hast drei einfache Möglichkeiten, aus LLM-Labels eine Zahl zu machen:

#figure(
  table(columns: (auto, auto, 1fr),
    table.header([Option], [Was sie benutzt], [Problem]),
    [*Klassisch*], [nur die menschlichen Labels], [gültig, aber breit: Die vielen LLM-Labels bleiben ungenutzt.],
    [*Plug-in*], [LLM-Labels, als wären sie menschlich], [schmal, aber verzerrt; die Spannen verfehlten den wahren Wert in den Anwendungen der PPI-Autoren @angelopoulos2023prediction.],
    [*Postpi*], [ein angepasstes Modell der LLM-Fehler], [richtig nur, wenn dieses Modell stimmt; schnitt im PPI-Vergleich bei der Regression schlecht ab @wang2020methods @motwani2023revisiting @angelopoulos2023prediction.],
  ),
  caption: [Drei einfache Optionen. Postpi ist der historische Vorläufer; für neue Analysen sind PPI++ oder DSL die bessere Wahl @salerno2025really.],
)

"Plug-in" heißt, die LLM-Labels einfach einzusetzen. Warum liegt das daneben, auch wenn das Modell gut ist? Weil sich seine zwei Fehlerarten nicht ausgleichen. Übersehene Beschwerden senken die Zählung, Fehlalarme erhöhen sie, aber die beiden Mengen sind verschieden groß.

#rechnung(titel: [Ein 85~%-Modell zählt zu viel])[
Von 10~000 Posts sind 3~100 wirklich positiv (31~%) und 6~900 negativ. Das Modell liegt bei beiden Arten in 85~% der Fälle richtig.
- Es findet 85~% der 3~100 positiven: 2~635 Posts.
- Es meldet fälschlich 15~% der 6~900 negativen als positiv: 1~035 Fehlalarme.
- Zusammen meldet es 2~635 + 1~035 = 3~670 Posts, also *36,7~%* statt 31~%.
Der große Haufen der negativen Posts liefert mehr Fehlalarme, als der kleine Haufen der positiven Treffer verliert. Das Ergebnis wird Richtung 50~% gezogen: Seltene Klassen werden überschätzt, häufige unterschätzt. Die Zahlen sind ein Rechenbeispiel, kein Studienergebnis.
]

Noch schlimmer wird es, wenn die Fehler von Gruppe zu Gruppe verschieden sind. In unserem Beispiel findet das Modell in Gruppe 0 90~% der positiven Posts, in Gruppe 1 nur 70~%. Rechne je 100 Posts nach:

#figure(
  table(columns: (auto, auto, 1fr),
    table.header([Je 100 Posts], [Wirklich positiv], [Das LLM meldet positiv]),
    [*Gruppe 0*], [25], [22,5 gefunden + 7,5 Fehlalarme = 30],
    [*Gruppe 1*], [40], [28 gefunden + 9 Fehlalarme = 37],
    [*Unterschied*], [15], [37 - 30 = 7],
  ),
  caption: [Das LLM macht aus 15 Prozentpunkten Unterschied 7.],
) <k06-tab-gruppen>

Die Gruppen sehen für das Modell fast gleich aus, obwohl sie es nicht sind: Der wahre Unterschied schrumpft um mehr als die Hälfte (53~%). In 2~000 simulierten Wiederholungen enthielt die Spanne für diesen Unterschied den wahren Wert kein einziges Mal. Die Autoren von DSL schreiben, dass einfaches Einsetzen nur gilt, wenn die Fehler zufällig sind und sich gegeben die Gruppe ausgleichen, "in der Praxis selten" @egami2023using.

#studie(titel: [Egami et al., 2023, Tabelle 3])[Bei einer Aufgabe zur Erkennung von Falschinformation lag das Ersatzmodell in 77,6~% der Fälle richtig. Die naive Spanne enthielt den wahren Wert trotzdem nur in 0,6~% der Durchläufe. Mit DSL, einer Korrektur, die wir noch kennenlernen, waren es 96,2~% @egami2023using.]

#fallstrick[Eine hohe accuracy beruhigt zu früh. Sie sagt, wie oft einzelne Labels stimmen, nicht, ob eine daraus gerechnete Zahl stimmt. Prüfe zusätzlich, ob die Fehler des Modells in allen Gruppen ähnlich sind.]

== Prediction-Powered Inference: die Korrektur

#alltag[Dein Tacho zeigt 5 km/h zu viel an, aber du weißt es nicht. Neben dir fährt ein Streifenwagen mit geeichtem Messgerät. Du fährst ein kurzes Stück neben ihm, vergleichst beide Anzeigen und siehst: Mein Tacho liegt im Schnitt 5 zu hoch. Von da an ziehst du bei jeder Anzeige 5 ab. Das kurze Stück neben dem Streifenwagen ist die menschlich geprüfte Stichprobe, die Fahrt danach die große Menge.]

PPI macht dasselbe mit Daten. Es braucht zwei Gruppen von Items. Die große Menge hat nur LLM-Labels. Eine kleine Stichprobe hat beides, das LLM-Label und das Label eines Menschen. Wichtig sind zwei Bedingungen: Die Stichprobe muss zufällig aus denselben Items gezogen sein, und für beide Gruppen muss dasselbe LLM mit demselben Prompt labeln. Wie gut das Modell ist, spielt für die Gültigkeit keine Rolle, sondern nur für die Breite der Spanne @angelopoulos2023prediction.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let kopf(x, t) = content((x, 6.1), text(font: "Inter", size: 7.5pt, weight: "bold", t))
    kopf(1.0, [Item]); kopf(2.9, [LLM-Label]); kopf(4.8, [Menschen-Label])
    // kleine Stichprobe
    rect((0, 4.7), (2.0, 5.7), fill: c-light, stroke: 0.6pt + c-grey)
    rect((2.0, 4.7), (3.8, 5.7), fill: c-blue.lighten(25%), stroke: 0.6pt + c-grey)
    rect((3.8, 4.7), (5.8, 5.7), fill: c-green.lighten(25%), stroke: 0.6pt + c-grey)
    content((1.0, 5.2), text(font: "Inter", size: 7.5pt)[500 Posts])
    content((2.9, 5.2), text(font: "Inter", size: 7.5pt, fill: white, weight: "bold")[hat Label])
    content((4.8, 5.2), text(font: "Inter", size: 7.5pt, fill: white, weight: "bold")[hat Label])
    // große Menge
    rect((0, 0.7), (2.0, 4.3), fill: c-light, stroke: 0.6pt + c-grey)
    rect((2.0, 0.7), (3.8, 4.3), fill: c-blue.lighten(25%), stroke: 0.6pt + c-grey)
    rect((3.8, 0.7), (5.8, 4.3), fill: white, stroke: (paint: c-grey, thickness: 0.6pt, dash: "dashed"))
    content((1.0, 2.5), text(font: "Inter", size: 7.5pt)[9~500 Posts])
    content((2.9, 2.5), text(font: "Inter", size: 7.5pt, fill: white, weight: "bold")[hat Label])
    content((4.8, 2.5), text(font: "Inter", size: 11pt, fill: c-grey)[?])
    // Klammern und Erklärungen
    line((6.0, 5.7), (6.2, 5.7), (6.2, 4.7), (6.0, 4.7), stroke: 0.8pt + c-dark)
    line((6.0, 4.3), (6.2, 4.3), (6.2, 0.7), (6.0, 0.7), stroke: 0.8pt + c-dark)
    content((6.5, 5.2), anchor: "west", box(width: 6.2cm, text(font: "Inter", size: 7.5pt)[Hier misst du den *Fehler des LLM*: im Schnitt 1,8 Punkte zu hoch]))
    content((6.5, 2.5), anchor: "west", box(width: 6.2cm, text(font: "Inter", size: 7.5pt)[Hier steht das *LLM-Ergebnis*: 32,8~% positiv]))
    // Ergebnis
    rect((0, -0.9), (12.4, -0.1), fill: c-accent, stroke: none, radius: 0.12)
    content((6.2, -0.5), text(font: "Inter", size: 8pt, weight: "bold", fill: white)[Korrigiertes Ergebnis: 32,8 % - 1,8 = 31,0 %])
  }),
  caption: [Die Idee von PPI. Die kleine Stichprobe verrät, wie weit das LLM daneben liegt; die große Menge liefert die Zahl.],
) <k06-abb-ppi>

#beispiel(titel: [Die Korrektur in vier Schritten])[
+ Das LLM labelt die 9~500 nicht geprüften Posts: *32,8~%* positiv.
+ Menschen labeln 500 zufällig gezogene Posts zusätzlich. Dort sagt das LLM bei 164 Posts "positiv", die Menschen bei 155.
+ Das LLM liegt also bei 9 von 500 Posts zu hoch, das sind *1,8 Prozentpunkte*.
+ Du ziehst das ab: 32,8~% - 1,8 = *31,0~%*. Das trifft den wahren Wert.
Hätte das Modell zu niedrig gelegen, würdest du die Differenz addieren. Die Zahlen sind die erwarteten Werte des laufenden Beispiels; eine echte Stichprobe weicht davon leicht ab. So steht es als Algorithmus 1 bei Angelopoulos et al. @angelopoulos2023prediction.
]

=== Die ehrliche Spanne

Auch die Spanne rechnet PPI ehrlicher. Sie vereint zwei Unsicherheiten: Die Korrektur stammt aus nur 500 Posts und ist selbst wackelig, und das LLM-Ergebnis der großen Menge wackelt ebenfalls ein wenig. Die einfache Variante kennt nur die zweite Unsicherheit und behandelt das Modell als perfekt. Deshalb ist die PPI-Spanne breiter als die naive, aber sie enthält den wahren Wert so oft, wie sie verspricht.

Wovon hängt ihre Breite ab? Von drei Dingen: der Größe der menschlichen Stichprobe (mehr Labels, schmalere Spanne), der Qualität des Modells (je gleichmäßiger seine Fehler, desto schmaler) und der Größe der großen Menge. Im laufenden Beispiel ist die klassische Spanne aus den 500 Labels allein etwa 8,1 Prozentpunkte breit. Die PPI-Spanne misst 6,9 Punkte, ist also rund 15~% schmaler. Die naive Spanne ist nur 1,8 Punkte breit, liegt aber bei 31,9 bis 33,7~% und lässt den wahren Wert von 31~% außen vor.

=== Wann PPI hilft und wann es schadet

PPI lohnt sich, wenn die große Menge viel größer ist als die menschliche Stichprobe und die Fehler des LLM klein und gleichmäßig sind. Dann ist die Korrektur billig und genau. Es kann aber auch schaden: In Stresstests der Autoren mit einem schwachen Modell und nur 1~000 Items ohne menschliches Label brauchte PPI mehr menschliche Labels als der klassische Weg (40 statt 35 und 869 statt 652). Der Grund ist, dass PPI das LLM-Ergebnis mit vollem Gewicht übernimmt, auch wenn es wenig taugt. Die Autoren empfehlen PPI nur, wenn die große Menge deutlich größer ist als die Stichprobe @angelopoulos2023prediction. PPI++ im nächsten Abschnitt behebt das.

Wie viel Ersparnis möglich ist, zeigt die Tabelle. Sie nennt, wie viele menschliche Labels nötig waren, um zum selben Schluss zu kommen.

#figure(
  table(columns: (1fr, auto, auto, auto),
    table.header([Anwendung], [Labels klassisch], [Labels mit PPI], [Ersparnis]),
    [*Proteinstruktur (AlphaFold)*], [799], [316], [60~%],
    [*Galaxienklassifikation*], [449], [189], [58~%],
    [*Abholzung*], [35], [21], [40~%],
    [*Einkommen*], [282], [177], [37~%],
    [*Krankenversicherung*], [6~653], [5~569], [16~%],
    [*Genexpression*], [900], [764], [15~%],
  ),
  caption: [Menschliche Labels, die klassisch und mit PPI für denselben Schluss nötig waren @angelopoulos2023prediction.],
)

Mit LLM-Labels solltest du eher mit den unteren Zeilen rechnen, außer das Modell ist sehr stark. PPI beschränkt sich nicht auf einen Prozentwert. Dasselbe Rezept funktioniert für Mittelwerte, für Unterschiede zwischen Gruppen (das leistet eine Regression, die den Zusammenhang zwischen Gruppe und Ergebnis beschreibt), für Quantile (etwa den Median) und für logistische Regression (Ja-Nein-Ergebnisse) @angelopoulos2023prediction.

== PPI++ und das durchgerechnete Beispiel

#alltag[Stell dir einen Drehregler vor, mit dem du bestimmst, wie laut die große Menge mitspielt. Ganz links (0) hörst du nur die menschlichen Labels, das ist der klassische Weg. Ganz rechts (1) hörst du das LLM-Ergebnis mit vollem Gewicht, das ist plain PPI. PPI++ dreht den Regler selbst an die beste Stelle.]

Dieses Gewicht heißt in `ppi_py` `lam`. Ist das Modell fast nutzlos, dreht PPI++ den Regler Richtung 0 und fällt auf den klassischen Weg zurück. Ist das Modell stark, geht er Richtung 1. Das Gewicht entscheidet nur über die Breite, nicht über die Gültigkeit. Die Autoren zeigen, dass PPI++ damit asymptotisch nie schlechter ist als der klassische Weg, das heißt bei genug Daten. Hinweis zum Stand: PPI++ ist bisher ein Preprint (Stand: 11. November 2026) @angelopoulos2023ppi.

Wie stark hilft der Regler? Im Beispiel wählte er bei 55~% LLM-Genauigkeit im Mittel das Gewicht 0,08, bei 85~% 0,61 und bei 99~% 0,93. Die Tabelle zeigt die Breite der Spanne im Vergleich zum klassischen Weg (1 bedeutet gleich breit, weniger ist besser). Dazu liefen 1~000 Simulationen mit 500 menschlichen Labels und 10~000 Posts.

#figure(
  table(columns: (auto, auto, auto),
    table.header([Genauigkeit des LLM], [Breite mit PPI], [Breite mit PPI++]),
    [*55~%*], [1,42], [1,00],
    [*65~%*], [1,27], [0,96],
    [*75~%*], [1,09], [0,89],
    [*85~%*], [0,86], [0,75],
    [*95~%*], [0,53], [0,50],
    [*99~%*], [0,31], [0,31],
  ),
  caption: [Breite der Spanne im Vergleich zum klassischen Weg (1,00). PPI++ ist nie breiter @angelopoulos2023ppi.],
) <k06-tab-genauigkeit>

Bei 55 bis 75~% Genauigkeit ist plain PPI 9 bis 42~% breiter als der klassische Weg, PPI++ nie. Die Spannen mit naiver Zählung enthielten den wahren Wert bis 85~% Genauigkeit in keinem Durchlauf, bei 95~% in 2,1~% und selbst bei 99~% nur in 86~% der Fälle.

=== Die effektive Stichprobengröße

Eine praktische Kennzahl ist die *effektive Stichprobengröße* (_effective sample size_). Sie sagt, wie viele rein menschliche Labels dieselbe Genauigkeit gebracht hätten. Im laufenden Beispiel sind 500 menschliche Labels mit PPI++ etwa 870 wert, das 1,74-Fache. `ppi_py` liefert sie als `effective_n`.

Es gibt eine Obergrenze, und sie hängt von der *Korrelation* zwischen LLM- und Menschen-Labels ab: wie gleichlaufend sie sind, 0 heißt unabhängig, 1 identisch. Das ist nicht dasselbe wie die Trefferquote. Bei einer Korrelation von 0,5 kannst du höchstens das 1,33-Fache deiner menschlichen Labels erreichen, bei 0,67 höchstens das 1,81-Fache, bei 0,9 das 5,3-Fache @angelopoulos2023ppi @broska2025mixed.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let sc = 1.4
    let zeile(y, label, v, txt, fill: c-blue.lighten(15%), stroke: none) = {
      content((-0.2, y), anchor: "east", text(font: "Inter", size: 7.5pt, label))
      rect((0, y - 0.19), (v * sc, y + 0.19), fill: fill, stroke: stroke)
      content((v * sc + 0.15, y), anchor: "west", text(font: "Inter", size: 7pt, txt))
    }
    zeile(0, [Korrelation 0,5], 1.33, [höchstens das 1,33-Fache])
    zeile(-0.65, [Korrelation 0,67], 1.81, [höchstens das 1,81-Fache])
    zeile(-1.3, [Korrelation 0,9], 5.3, [höchstens das 5,3-Fache], fill: c-green.lighten(15%))
    zeile(-2.05, [Laufendes Beispiel], 1.74, [1,74-Fache (500 -> 870)], fill: white, stroke: 1.3pt + c-accent)
    line((1 * sc, 0.45), (1 * sc, -2.4), stroke: (paint: c-grey, thickness: 0.7pt, dash: "dashed"))
    content((1 * sc, 0.7), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[1 = nur menschliche Labels])
  }),
  caption: [Die Obergrenze des Gewinns wächst mit der Korrelation zwischen LLM und Menschen.],
) <k06-abb-effektiv>

#merke[Große Gewinne brauchen eine hohe Korrelation, nicht nur eine gute Trefferquote. Ein Modell, das oft richtig liegt, aber an den schwierigen Fällen genauso scheitert wie ein Mensch zufällig, hilft kaum.]

=== Alle Verfahren auf einem Datensatz

Jetzt nehmen wir das laufende Beispiel und lassen alle vier Verfahren gegeneinander antreten. Die Abbildung zeigt die Spannen.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let xs(v) = (v - 26) * 1.15
    let zeile(y, name, lo, hi, col, txt) = {
      content((-0.2, y), anchor: "east", text(font: "Inter", size: 7.5pt, weight: "bold", name))
      line((xs(lo), y), (xs(hi), y), stroke: 3.2pt + col)
      line((xs(lo), y - 0.13), (xs(lo), y + 0.13), stroke: 1.2pt + col)
      line((xs(hi), y - 0.13), (xs(hi), y + 0.13), stroke: 1.2pt + col)
      content((xs(hi) + 0.25, y), anchor: "west", text(font: "Inter", size: 7pt, txt))
    }
    line((xs(31), 0.55), (xs(31), -2.55), stroke: (paint: c-green, thickness: 1.1pt, dash: "dashed"))
    content((xs(31), 0.85), text(font: "Inter", size: 7.5pt, weight: "bold", fill: c-green)[wahrer Wert: 31 %])
    zeile(0, [Naiv], 31.9, 33.7, c-red, [1,8 Punkte breit])
    zeile(-0.65, [Klassisch], 26.9, 35.1, c-grey, [8,1 Punkte breit])
    zeile(-1.3, [PPI], 27.5, 34.5, c-blue, [6,9 Punkte breit])
    zeile(-1.95, [PPI++], 27.9, 34.1, c-green, [6,1 Punkte breit])
    line((0, -2.8), (xs(38), -2.8), stroke: 0.7pt + c-dark)
    for v in (26, 28, 30, 32, 34, 36, 38) {
      line((xs(v), -2.8), (xs(v), -2.92), stroke: 0.7pt + c-dark)
      content((xs(v), -3.2), text(font: "Inter", size: 7pt, [#v %]))
    }
  }),
  caption: [Die vier Spannen im laufenden Beispiel. Nur die naive verfehlt den wahren Wert.],
) <k06-abb-vergleich>

Die naive Spanne ist die schmalste und die einzige, die den wahren Wert verfehlt: Präzision ohne Gültigkeit. Klassisch, PPI und PPI++ enthalten ihn alle, PPI++ ist mit 24~% gegenüber dem klassischen Weg die schmalste. Das entspricht etwa 870 menschlichen Labels statt 500.

Um zu sehen, ob das Zufall war, wurde das Experiment 2~000-mal wiederholt. Die korrigierten Verfahren waren im Mittel richtig und ihre Spannen enthielten den wahren Wert in 94 bis 96~% der Durchläufe. Die naive Zählung tat das nur in 2,6~% der Durchläufe. Für den Gruppenunterschied zeigte die naive Zählung im Mittel 7 statt 15 Punkte und enthielt den wahren Wert nie. PPI++ machte die Spanne für den Unterschied um 21~% schmaler als der klassische Weg. Die Gewinne sind bei realistischer Genauigkeit also mäßig, der Gewinn an Gültigkeit ist es nicht.

#hoersaal([Ist PPI immer besser, als einfach nur Menschen zu fragen?], [Nein. Der klassische Weg ist immer gültig, PPI++ ist asymptotisch nie schlechter, und plain PPI kann bei einem schwachen Modell breiter werden. PPI++ ist der sichere Standard. Der Gewinn bleibt bei durchschnittlichen LLM-Labels oft moderat.])

== Weitere Verfahren: was ist anders, wann nehme ich es

PPI ist ein Mitglied einer Familie. Alle Verfahren starten mit den LLM-Labels und fügen eine Korrektur aus menschlichen Labels hinzu. Sie unterscheiden sich darin, was sie zusätzlich einstellen. Formal gehören sie zu den Schätzern vom Typ AIPW (_augmented inverse probability weighting_), diesen Namen brauchst du nur, um Papers zu lesen @ji2025predictions @salerno2025really.

*Cross-PPI und Bootstrap.* Hast du kein fertiges Modell und trainierst selbst einen Klassifikator auf deinen menschlichen Labels, würde ein Modell, das die Labels schon gesehen hat, auf ihnen zu gut aussehen. Cross-PPI teilt die menschlichen Labels in Teile auf, und jeder Teil wird von einem Modell beurteilt, das ihn nie gesehen hat. So geht kein Label verloren @zrnic2024cross. Der _prediction-powered bootstrap_ (PPBoot) zieht die Daten am Rechner immer wieder neu und liest daran ab, wie stark das Ergebnis wackelt. Er funktioniert für beliebige Größen, etwa ein Verhältnis oder eine Ungleichheitskennzahl wie den Gini-Koeffizienten, und ist laut Autoren oft fast so gut wie PPI++, manchmal besser. Er steckt in `ppi_py.ppboot` und ist ein Preprint @zrnic2024note.

*Aktive Inferenz und Confidence-Driven Inference.* Wer sagt, dass die Stichprobe zufällig sein muss? Bei aktiver Inferenz labeln Menschen dort, wo das Modell unsicher ist, so wie eine Lehrerin die Korrekturzeit auf die Antworten konzentriert, bei denen das Automatenurteil wackelt. Damit es fair bleibt, bekommt jedes Item eine bekannte, nicht-null Chance, gezogen zu werden, und gezogene Items zählen mit dem Kehrwert dieser Chance. In einer Umfrageanwendung sparte das über 80~% des klassischen Stichprobenaufwands @zrnic2024active. Die LLM-Variante, _confidence-driven inference_, lässt das Modell seine Sicherheit selbst angeben, eine gelernte Zuordnung macht daraus einen erwarteten Fehler. Mit GPT-4o auf Aufgaben zu Höflichkeit, Haltung und politischer Verzerrung sank die Zahl nötiger menschlicher Labels in jeder Einstellung um über 25~%. Die Spannen enthielten den Zielwert in 91 bis 97~% der Fälle (Ziel waren 90~%) @gligoric2025can.

*DSL (design-based supervised learning).* Hier legst du selbst per Zufall fest, welche Dokumente Menschen labeln, und notierst für jedes die Chance, gezogen zu werden. Ein flexibles Modell sagt das menschliche Label aus dem LLM-Label und weiteren Merkmalen voraus, die menschlichen Labels korrigieren diese Vorhersage, und dann rechnest du deine gewohnte Analyse. Das Ergebnis bleibt gültig, selbst wenn die LLM-Labels stark verzerrt sind; ihre Qualität bestimmt nur die Breite @egami2023using.

#studie(titel: [Egami et al., 2023: DSL im Vergleich])[Bei der Emotions-Aufgabe (LLM-Genauigkeit 70,3~%) hatte die Schätzung nur aus LLM-Labels sogar den etwas kleineren typischen Fehler (2,9 statt 3,2), ihre Spanne enthielt den wahren Wert aber nur in 67,2~% der Fälle. Mit DSL waren es 94,0~%. Bei der Aufgabe zur Hassrede (Genauigkeit 35,9~%) hielt nur DSL: 94,1~% gegenüber 17,4~% @egami2023using. Genauigkeit ist nicht Gültigkeit.]

*Andere Fächer, gleiche Idee.* Ökonomen schreiben dieselbe Korrektur so: Messe an einer Validierungsstichprobe, wie der LLM-Fehler von den anderen Variablen abhängt, und ziehe ihn ab. Als Anfang empfehlen sie 125 bis 250 menschliche Labels, schon dann zeigte sich in ihrem Beispiel ein deutlicher Vorteil @ludwig2026large. Die Politikwissenschaft nutzt Methoden mit Instrumentvariablen (GMM, 2SLS) für den Fall, dass das LLM-Label eine erklärende Variable ist @fong2021machine, die Kommunikationsforschung ein Fehlermodell mit Maximum Likelihood @teblunthuis2024misclassification. Du musst die Kürzel nicht lernen, sondern wissen, dass diese Arbeiten dasselbe Problem lösen. Welche Methode in kleinen Stichproben die beste ist, ist offen: DSL ist oft weniger verzerrt, PPI stabiler über Datensätze hinweg @depieuchon2025benchmarking.

Die Tabelle ist deine Entscheidungshilfe.

#figure(
  table(columns: (auto, auto, 1fr),
    table.header([Verfahren], [Was ist anders], [Nimm es, wenn]),
    [*PPI*], [volles Vertrauen in das LLM-Ergebnis], [Zufallsstichprobe, LLM-Menge viel größer als die menschliche],
    [*PPI++*], [die Daten wählen das Vertrauen], [Zufallsstichprobe; der Standard],
    [*Cross-PPI*], [fair für ein selbst trainiertes Modell], [du trainierst ein Modell auf den menschlichen Labels],
    [*Aktive Inferenz*], [Menschen labeln, wo das Modell unsicher ist], [du darfst wählen, welche Items Menschen labeln],
    [*Confidence-driven*], [nutzt die ausgesprochene Sicherheit des LLM], [diese Sicherheit sagt etwas aus],
    [*DSL*], [flexibles Modell plus bekannte Ziehungschancen], [du kennst die Chance jedes Items],
    [*Stratifiziertes PPI*], [Labels je Gruppe verteilt], [die LLM-Qualität ist je Gruppe verschieden @fisch2024stratified],
  ),
  caption: [Welche PPI-Variante passt zu welcher Lage.],
)

== Praxis und Grenzen

=== Wie viele menschliche Labels?

Eine feste Zahl gibt es nicht. Aus den Quellen ergeben sich drei Anhaltspunkte. Ökonomen empfehlen für Schätzungen 125 bis 250 menschliche Labels als Start @ludwig2026large. Mit etwa 100 menschlichen Labels brachten Korrekturen die Rate falscher Alarme auf ihr Ziel, machten es aber schwerer, echte Effekte zu finden; rein menschliche Annotation mit 1~000 Labels hatte insgesamt das geringste Risiko, etwa 20~% (ein Preprint, also eine noch nicht begutachtete Fassung; Stand: 11. November 2026) @baumann2025large. Mehr menschliche Labels schlagen also oft jede Raffinesse, wenn du sie dir leisten kannst.

Für die Planung hilft `ppi_mean_power` aus `ppi_py` (Version 0.2.3, Stand: 11. November 2026) @angelopoulos2024ppipy. Du gibst ein, was ein menschliches und was ein LLM-Label kostet, und es rechnet aus, wie viel von beidem du brauchst. Im laufenden Beispiel kostet ein menschliches Label 1 Einheit und ein LLM-Label 0,01. Die Antwort: 604 menschliche Labels plus 4~812 Posts nur mit LLM-Label sind so genau wie 1~000 menschliche Labels, kosten aber 658 statt 1~000 Einheiten. Mit einem Budget von 1~000 Einheiten sind 918 menschliche und 7~309 LLM-Labels möglich, wert so viel wie 1~519 menschliche. Der Plan hängt davon ab, wie gleichlaufend LLM und Menschen sind, und das schätzt du aus einer kleinen Vorabstichprobe. Den Rahmen dafür liefern Broska, Howes und van Loon @broska2025mixed.

=== Typische Fehler

#figure(
  table(columns: (auto, 1fr, 1fr),
    table.header([Voraussetzung], [Typischer Fehler], [Abhilfe]),
    [*Zufällige Stichprobe*], [die "interessanten" Posts zuerst labeln], [Ziehungschancen notieren und gewichten (`w` in `ppi_py`)],
    [*Festes LLM-Setup*], [Prompt an den menschlich gelabelten Posts feingeschliffen], [eigene Entwicklungsstichprobe oder Cross-PPI],
    [*Richtige menschliche Labels*], [einzelne Coder, die sich irren], [doppelt labeln und Abweichungen klären],
    [*Genug Daten*], [sehr kleine menschliche Stichprobe], [per Simulation prüfen; Bootstrap-Varianten],
    [*Dasselbe Modell überall*], [Modell wird mitten im Projekt aktualisiert], [Modellversion festschreiben],
  ),
  caption: [Wo PPI in der Praxis schiefgeht @angelopoulos2023prediction @egami2023using @chew2026design @kluger2025prediction.],
)

Der häufigste Fehler ist, die Stichprobe nicht zufällig zu ziehen, etwa weil man zuerst die Fälle codiert, die einen interessieren, oder weil man die Posts nimmt, bei denen Mensch und LLM uneins waren. Dann misst du den Fehler des Modells an den falschen Posts. Fast so häufig: Du feilst am Prompt und nutzt dieselben menschlich gelabelten Posts danach für PPI. Dann hat das LLM die Antworten schon gesehen, die Korrektur gilt nicht mehr. Wer unter vielen Prompts den auswählt, der das gewünschte Ergebnis liefert, betreibt _LLM hacking_ @baumann2025large.

#fallstrick[Verbrauche die menschlichen Labels nicht zum Prompt-Tuning. Entwickle den Prompt auf einer eigenen kleinen Stichprobe, friere ihn ein und ziehe erst dann die Stichprobe, mit der du korrigierst.]

=== PPI für die Bewertung von Modellen

Das Verfahren passt auch auf Modelle als Gutachter, die du in Kapitel 7 und 9 triffst, denn deren Urteile sind ebenfalls LLM-Labels. Mit PPI genügen wenige menschliche Bewertungen, um Trefferquoten und Gewinnraten von Modellen gültig zu schätzen; im Chatbot-Arena-Experiment mit GPT-4 gewann man bis zu 50~% effektive Stichprobe @boyeau2025autoeval. Auch Ranglisten lassen sich mit Spannen absichern: Man gibt Mengen möglicher Plätze an, die die menschliche Rangfolge mit der versprochenen Wahrscheinlichkeit enthalten @chatzi2024prediction.

=== Was keine Korrektur repariert

PPI und DSL beheben Fehler gegenüber den menschlichen Labels, nicht Fehler in dem, was Menschen und Modell gemeinsam falsch verstehen. Drei Fälle:
- *Unvollständiges Codebuch.* Beschreibt es den Begriff falsch oder unvollständig, etwa weil es gewaltsame Proteste nicht ausschließt, misst alles dieselbe falsche Größe. Die Verzerrung bleibt, selbst wenn der LLM-Fehler gegen null geht @halterman2025what.
- *Mehrdeutige Texte.* Bei Texten, die schon Menschen spalten, sank die Übereinstimmung zweier Fachleute von 93 auf 60~%. Es gibt kein einziges richtiges Label (ein Preprint) @nakamura2026observational.
- *Unsaubere menschliche Labels.* Sind auch die menschlichen Labels fehlerhaft, erreichten einfache Plug-in-Verfahren eine Abdeckung von null, DSL mit Abgleich der Coder hielt 94 bis 96~% (ein Preprint, dessen Zahlen als Richtwert gelten) @chew2026design.

=== Gültig heißt nicht stark

Die Korrektur kauft *Gültigkeit*, nicht *Trennschärfe* (_power_), also die Chance, einen echten Effekt zu finden. Die optimistische Seite: 60~% weniger Labels bei AlphaFold, über 80~% Budget gespart mit aktiver Auswahl, bis zu +319~% effektive Stichprobe mit confidence-driven inference @angelopoulos2023prediction @zrnic2024active @gligoric2025can. Die nüchterne Seite: 15 bis 16~% Ersparnis bei mäßigen Vorhersagen, 24~% schmaler bei 86~% LLM-Genauigkeit und in einer Auswertung ein um etwa 60 Prozentpunkte höheres Risiko, echte Effekte zu übersehen @baumann2025large. Plane die menschliche Stichprobe deshalb für die Trennschärfe und lege Modell und Prompt vor der Erhebung fest.

== In der Praxis: Ablauf und Checkliste

So gehst du in einem eigenen Projekt vor:

+ *LLM-Setup festlegen und einfrieren.* Modell, Version, Prompt, Temperatur. Entwickle den Prompt auf einer Entwicklungsstichprobe, nicht auf der späteren menschlichen.
+ *Alle Items vom LLM labeln lassen* (Kapitel 4 und 5 zeigen, wie).
+ *Eine Zufallsstichprobe ziehen* und von Menschen labeln lassen, mit klarem Codebuch und möglichst doppelt (Kapitel 5). Plane die Größe mit `ppi_mean_power`.
+ *Korrigieren* mit `ppi_py`, siehe unten.
+ *Berichten.* Schätzwert, Spanne, beide Stichprobengrößen, effektive Stichprobengröße, Modell und Prompt.
+ *Gegenprobe.* Prüfe per Simulation, wie oft die Spanne bei deiner Stichprobengröße den wahren Wert enthält.

#datei("ppi_beispiel.py")[
```python
import numpy as np
from ppi_py import ppi_mean_ci, ppi_ols_ci

rng = np.random.default_rng(1)
n_all = 10_000
G = (rng.random(n_all) < 0.4).astype(float)            # Gruppe 0/1
Y = (rng.random(n_all) < np.where(G == 1, 0.40, 0.25)).astype(float)  # wahr
s = np.where(G == 1, 0.70, 0.90); f = np.where(G == 1, 0.15, 0.10)
Yhat = np.where(Y == 1, rng.random(n_all) < s,
                rng.random(n_all) < f).astype(float)    # LLM-Label
idx = rng.permutation(n_all); lab, unl = idx[:500], idx[500:]

for name, lam in [("PPI  ", 1), ("PPI++", None)]:       # lam=None: Daten wählen
    lo, hi = np.ravel(ppi_mean_ci(Y[lab], Yhat[lab], Yhat[unl], alpha=0.05, lam=lam))
    print(f"Anteil {name}: {lo:.3f} bis {hi:.3f}")

X = np.column_stack([np.ones(n_all), G])               # Achsenabschnitt + Gruppe
lo, hi = ppi_ols_ci(X[lab], Y[lab], Yhat[lab], X[unl], Yhat[unl],
                    alpha=0.05, coord=1)               # Gruppenunterschied
print(f"Unterschied PPI++: {lo[1]:.3f} bis {hi[1]:.3f}")
```
]

```out
Anteil PPI  : 0.249 bis 0.318
Anteil PPI++: 0.254 bis 0.314
Unterschied PPI++: 0.059 bis 0.192
```

Die Spannen enthalten 0,31 und 0,15, die wahren Werte. Der Code folgt dem Beispiel aus dem Notebook (Version 0.2.3 von `ppi_py`, Stand: 11. November 2026); die Ausgaben stammen aus dessen Lauf mit demselben Startwert des Zufallsgenerators. Das Notebook rechnet dasselbe zusätzlich in reinem numpy nach. Vorsicht bei `alpha`: Der Standard ist 0,1, also 90~%-Spannen. Für 95~% brauchst du `alpha=0.05`, wie hier. Mit `lam=1` bekommst du plain PPI, mit `lam=0` den klassischen Weg, mit `lam=None` PPI++.

#praxis[Schätze, bevor du loslegst, mit einer Vorabstichprobe von 100 bis 200 menschlichen Labels, wie gleichlaufend LLM und Menschen sind. Mit dieser Zahl rechnet `ppi_mean_power` dir den Aufwand aus. Plane im Zweifel eher mehr Labels ein; 500 sind eine solide Größe für ein erstes Projekt.]

*Checkliste vor dem Berichten*
- Modell, Version und Prompt festgehalten, nicht auf den menschlichen Labels getuned?
- Stichprobe zufällig oder mit bekannten, nicht-null Chancen gezogen?
- Menschliche Labels sorgfältig erstellt, möglichst doppelt?
- Spanne mit `alpha=0.05` berechnet, nicht mit dem Standard?
- Beide Stichprobengrößen, die effektive Stichprobengröße und das Verfahren genannt?
- Geprüft, dass Menschen und Modell dasselbe messen (Codebuch)?

== Für die Lehre

Diese Missverständnisse kommen erfahrungsgemäß von Studierenden:

- *"90~% accuracy sind gut genug."* Löse es mit dem Beispiel der Gruppen auf (Tabelle in diesem Kapitel): Ein Modell mit durchaus brauchbarer Genauigkeit macht aus 15 Punkten Unterschied 7. Frage zurück: "Wer macht die Fehler, und in welche Richtung?"
- *"Mehr Posts machen das Ergebnis genauer."* Zeige die Abbildung mit den Spannen, die sich immer enger um den falschen Wert legen. Der Vergleich mit der Waage, die 20 Gramm zu viel anzeigt, sitzt.
- *"PPI repariert die Labels."* Nein. Es korrigiert die Endzahl, nicht das einzelne Label. Das einzelne Label des Modells bleibt so falsch, wie es war.
- *"95~% heißt: Der wahre Wert liegt mit 95~% Wahrscheinlichkeit in meiner Spanne."* Streng gilt das Versprechen dem Verfahren: Von 100 wiederholten Studien enthalten etwa 95 den wahren Wert. Für die Praxis genügt "plausible Werte", solange die Abdeckung stimmt.
- *"Die menschliche Stichprobe darf ich mir aussuchen."* Nur mit bekannten Ziehungschancen und Gewichtung. Sonst ist die Korrektur schief, weil du den Fehler an den falschen Posts misst.

#kurz(
  [LLM-Labels wie echte Labels zu zählen verzerrt das Ergebnis und täuscht Sicherheit vor. Mehr Posts machen die Spanne enger, aber nicht richtiger.],
  [Rauschen schrumpft mit mehr Daten, Verzerrung nie. Verzerrung entdeckst du nur im Vergleich mit Menschen.],
  [PPI: eine kleine Zufallsstichprobe zeigt, um wie viel das LLM im Schnitt danebenliegt; um diesen Betrag wird das Ergebnis der großen Menge korrigiert. Im Beispiel: 32,8~% - 1,8 = 31,0~%.],
  [Die korrigierte Spanne ist breiter als die naive, aber ehrlich. Ihre Breite hängt von der Größe der menschlichen Stichprobe und von der Gleichläufigkeit von LLM und Menschen ab.],
  [PPI++ regelt selbst, wie viel Gewicht das LLM bekommt, und ist asymptotisch nie schlechter als der rein menschliche Weg. Varianten (Cross-PPI, aktive Inferenz, DSL) unterscheiden sich in Ziehung und Modell.],
  [Fehlerquellen: nichtzufällige Stichprobe, am Prompt verbrauchte Labels, wechselndes Modell. Keine Korrektur heilt ein falsches Codebuch oder mehrdeutige Texte.],
  [Korrektur kauft Gültigkeit, nicht Trennschärfe: Plane die menschliche Stichprobe dafür, ein paar hundert Labels sind ein sinnvoller Start.],
)

#selbsttest(
  ([Ein LLM trifft in 90~% der Fälle die Entscheidung der Menschen. Warum kann die daraus gerechnete Prozentzahl trotzdem falsch sein?], [Weil sich Fehlalarme und übersehene Fälle nicht ausgleichen müssen und häufig in dieselbe Richtung schieben. Das ist eine Verzerrung, und die ändert sich mit mehr Daten nicht.]),
  ([Was ändert sich an einer Spanne, wenn du zehnmal so viele LLM-Labels einsetzt, und was nicht?], [Sie wird enger, weil das Rauschen sinkt. Die Verzerrung bleibt, also liegt die engere Spanne weiter neben dem wahren Wert.]),
  ([Das LLM meldet 40~% positiv. In einer Zufallsstichprobe von 200 sagt es 42~%, die Menschen 36~%. Wie lautet das korrigierte Ergebnis?], [Das Modell liegt dort 6 Punkte zu hoch. 40~% - 6 = 34~%.]),
  ([Warum ist die PPI-Spanne breiter als die naive und trotzdem besser?], [Sie berücksichtigt auch, dass die Korrektur aus einer kleinen Stichprobe stammt. Das macht sie breiter, aber sie enthält den wahren Wert so oft, wie sie verspricht.]),
  ([Wovon hängt es ab, wie viel PPI++ gegenüber dem rein menschlichen Weg gewinnt?], [Von der Gleichläufigkeit (Korrelation) zwischen LLM- und Menschen-Labels, nicht von der Trefferquote allein, und von der Größe der großen Menge im Vergleich zur menschlichen Stichprobe.]),
  ([Du hast den Prompt an den 300 menschlich gelabelten Posts feingeschliffen und willst mit ihnen PPI rechnen. Was ist das Problem?], [Das LLM hat diese Posts schon "gesehen", der Fehler dort ist kleiner als anderswo. Die Korrektur ist dann zu klein. Entwickle den Prompt auf einer eigenen Stichprobe oder nutze Cross-PPI.]),
  ([Was kann PPI nicht reparieren?], [Ein falsches oder unvollständiges Codebuch, mehrdeutige Texte ohne eine richtige Antwort und unsaubere menschliche Labels, denn es korrigiert nur gegenüber den menschlichen Labels.]),
)

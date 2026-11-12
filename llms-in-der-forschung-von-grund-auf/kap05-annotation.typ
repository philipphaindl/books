#import "lib.typ": *

= LLMs als Annotatoren

Du hast 20~000 Antworten auf die offene Umfragefrage "Was stört dich an deinem Studium?" und willst wissen, wie viele davon von Zeitdruck handeln, wie viele von Prüfungen und wie viele von etwas ganz anderem. Früher hätten zwei Hilfskräfte wochenlang gelesen und markiert. Heute schreibst du einen Prompt, ein Sprachmodell liest alles in einer Stunde und vergibt zu jeder Antwort ein Label. Das Ergebnis sieht sauber aus: eine Tabelle, ein Balkendiagramm, 31~% Zeitdruck. Wie viel ist diese Zahl wert?

Dieses Kapitel zeigt, wie du das herausfindest. Ein Sprachmodell als _Annotator_ ist ein Messgerät, und ein Messgerät muss man eichen. Dafür vergleicht man das Modell mit Menschen und braucht eine Kennzahl für "die beiden stimmen überein". Hier lauert die häufigste Falle des Themas: 90~% Übereinstimmung klingen hervorragend und können bedeuten, dass sich zwei Beurteiler bei dem, worauf es ankommt, kein einziges Mal einig waren. Du lernst, warum das so ist, welche Kennzahl es löst, welche du wann nimmst und wie du sie mit wenigen Zeilen Python berechnest. Danach geht es um den Prüfablauf, um das Ableiten von Kategorien aus Daten und um den Methodenteil.

Du brauchst dafür keine Statistik. Rechnen kommt nur als Zählen und Grundrechenarten vor. Begriffe wie Zufallsschwankung, Konfidenzintervall oder Gold-Labels stehen in _Das Nötigste vorab_ und werden hier kurz wiederholt, wo du sie brauchst. Der passende Foliensatz ist Foliensatz 05, das Notebook heißt `notebooks/05_agreement_and_codebooks.ipynb`.

#lernziele(
  [erklären, warum ein Sprachmodell als Annotator ein Messgerät ist, das geeicht werden muss,],
  [mit einem Zahlenbeispiel zeigen, warum 90~% Übereinstimmung täuschen können,],
  [das passende Übereinstimmungsmaß auswählen, den Wert lesen und mit Python berechnen,],
  [eine Validierung mit Stichprobe, Konfidenzintervall und alternativem Annotator-Test planen,],
  [mit einem Sprachmodell Codes aus offenen Antworten ableiten und gegen ein menschliches Codebuch vergleichen,],
  [berichten, was dazugehört, damit andere jedes Label nachvollziehen können.],
)

== Was ein Annotator tut

*Annotieren* (auch _labeln_ oder _codieren_) heißt, einem Textstück einen Wert aus einem festen Schema zuzuordnen: relevant oder nicht relevant, positiv, neutral oder negativ, Thema A bis F. Es gibt zwei Arbeitsweisen. Beim *deduktiven* Codieren stehen die Kategorien vorher fest, aufgeschrieben in einem *Codebook* (der Anleitung mit Definitionen und Beispielen für jede Kategorie). Beim *induktiven* Codieren entstehen die Kategorien erst beim Lesen der Daten. Das eine ist Zuordnen, das andere Entdecken. Die ersten Abschnitte handeln vom Zuordnen, ab Abschnitt 5.6 geht es ums Entdecken.

Beim Zuordnen ist das Codebook das gemeinsame Instrument von Experten und Sprachmodell: Man verfeinert es an einer kleinen Menge menschlich gelabelter Texte, bis das Modell gut genug trifft, und prüft es dann an zurückgehaltenen Texten @pangakis2023automated. Wozu die Labels dienen, bestimmt, wie gut sie sein müssen: Pangakis et al. nennen vier Zwecke, von der Prüfung menschlicher Labels über Vorsortieren und Trainingsdaten für ein kleines Modell bis zum direkten Labeln des ganzen Bestands, der am meisten verlangt.

=== Zuverlässig ist nicht gültig

#alltag[Eine Badezimmerwaage zeigt jeden Morgen exakt 2 kg zu wenig an. Sie ist _reliabel_: Wiegst du dich fünfmal, bekommst du fünfmal dieselbe Zahl. Gültig, also _valide_, ist sie nicht, denn die Zahl stimmt nicht. Bei Sprachmodellen kann dasselbe passieren: Es antwortet sehr gleichmäßig und liegt gleichmäßig daneben.]

Gilardi et al. fanden genau diesen Unterschied: ChatGPT stimmte mit sich selbst weit häufiger überein als geschulte Annotatoren untereinander, doch über die Aufgaben hinweg hing das nur schwach mit der Treffsicherheit zusammen: Die Korrelation (das Maß dafür, wie gleichläufig zwei Zahlenreihen sind, von 0 für "gar nicht" bis 1 für "perfekt") lag bei 0,36 @gilardi2023chatgpt. Von der Heyde et al. maßen eine Wiederholungs-Konsistenz von 0,99 bei GPT-4o, obwohl die Verteilung der Kategorien verzerrt war @vonderheyde2025using. Und bei Baumann et al. sagte die Übereinstimmung zwischen Menschen nichts über das Risiko falscher Schlüsse aus den Labels voraus @baumann2025large.

#figure(
  balken((("MTurk-Crowd", 56), ("Geschulte Annotatoren", 79), ("ChatGPT, Temperatur 1", 91), ("ChatGPT, Temperatur 0,2", 97)), max: 100, breite: 8, einheit: " %", nachkomma: 0),
  caption: [Übereinstimmung der Annotatoren untereinander bei Gilardi et al. @gilardi2023chatgpt. Die Temperatur steuert, wie stark die Antworten streuen. Hohe Gleichmäßigkeit beweist keine Richtigkeit.],
)

#hoersaal([Das Modell stimmt mit sich selbst zu 97~% überein. Reicht das als Qualitätsnachweis?], [Nein. Das beweist nur, dass es gleichmäßig antwortet. Ob es das Richtige misst, siehst du erst im Vergleich mit sorgfältig vergebenen Menschenlabels. Gleichmäßigkeit ist die Voraussetzung, der Vergleich der Beleg.])

== Was die Studien zeigen

Die Qualität schwankt stark von Aufgabe zu Aufgabe. Die Befunde stammen überwiegend aus der Zeit von GPT-3.5 und GPT-4 (Stand: 11. November 2026); sie zeigen, wie man das Messproblem sieht, nicht, was heutige Modelle leisten.

#studie(titel: [Gilardi et al., 2023])[*Was:* 6~183 Tweets und Nachrichtenartikel, Aufgaben wie Relevanz, Haltung, Thema und Frame. ChatGPT bekam nur eine Anweisung ohne gelöste Beispiele (_Zero-Shot_) und wurde mit bezahlten Crowd-Workern auf Amazon Mechanical Turk (MTurk) verglichen; als Maßstab dienten drei geschulte Studierende. *Ergebnis:* Die Treffsicherheit lag im Schnitt etwa 25 Prozentpunkte über der der Crowd-Worker, bei weniger als 0,003 US-Dollar pro Label, rund 30-mal billiger. *Kleingedrucktes:* Gerechnet wurde nur auf den leichteren Texten, bei denen beide geschulten Annotatoren einig waren; es war ein einzelnes proprietäres Modell von 2023 @gilardi2023chatgpt.]

Die übrigen Studien zeichnen ein gemischteres Bild. Die Tabelle nennt je eine starke und eine schwache Zahl. *F1* ist dabei ein Wert von 0 bis 1, der nur hoch ausfällt, wenn ein Modell die gesuchten Fälle vollständig _und_ ohne viele Fehlgriffe findet.

#figure(
  table(columns: (auto, auto, 1fr, 1fr),
    table.header([Studie], [Aufgabe], [Starkes Ergebnis], [Schwaches Ergebnis]),
    [*Törnberg 2025*], [Partei aus einem Beitrag, 11 Länder], [US-Treffsicherheit 0,934 gegenüber Experten mit 0,860], [Schweden war für alle Modelle am schwersten],
    [*Pangakis et al. 2023*], [27 Aufgaben, GPT-4], [Median-F1 0,707], [kleinster F1-Wert 0,059; bei 9 Aufgaben Precision oder Recall unter 0,5],
    [*Ziems et al. 2024*], [17 Klassifikationsaufgaben], [8 Aufgaben mit mäßiger bis guter Übereinstimmung], [5 Aufgaben mit schlechter Übereinstimmung],
    [*Rathje et al. 2024*], [12 Sprachen, Stimmung u. a.], [Korrelation 0,59 bis 0,77 mit Menschen], [Stimmung in afrikanischen Sprachen: F1 0,46 bis 0,60],
  ),
  caption: [Starke und schwache Ergebnisse derselben Verfahren @tornberg2025large @pangakis2023automated @ziems2024can @rathje2024gpt.],
)

Daraus folgen drei praktische Lehren. Erstens: *Prüfe jede Aufgabe und jede Sprache einzeln.* Rathje et al. prüften 47~925 Texte in 12 Sprachen, bei Stimmung in afrikanischen Sprachen stieg der mittlere F1 je nach GPT-Version nur von 0,455 auf 0,600 @rathje2024gpt. Zweitens: *Offene Antworten sind schwerer, als sie aussehen.* Bei 5~072 deutschen Umfrageantworten mit 22 Kategorien erreichte GPT-4o mit ein paar Beispielen einen F1-Wert von 0,71, ein darauf feinabgestimmtes GPT-4o 0,87, ein älteres klassisches Modell (SVM) 0,83 @vonderheyde2025using. Drittens: *Ein kleines überwachtes Modell ist die Messlatte.* Ziems et al. fanden, dass Zero-Shot-Modelle feinabgestimmte Modelle auf Standard-Datensätzen nur selten schlugen: Bei Haltungserkennung lag das beste Zero-Shot-Modell vorn (F1 76,0 gegen 36,1), bei Figurativer Sprache klar dahinter (62,3 gegen 99,2) @ziems2024can. Und Feinabstimmung auf nur 50 bis 100 Beispiele verbesserte GPT-3.5 deutlich @alizadeh2025open. Eine Studie, die ein Sprachmodell als Annotator vorstellt, sollte darum ein kleines Modell auf Menschenlabels als Vergleich mitführen.

=== Was als richtig gilt

Als Maßstab dienen in den Studien mal geschulte Studierende (Gilardi), mal Experten (Pangakis), mal Crowd-Annotationen aus öffentlichen Datensätzen (Ziems). Das sind drei verschiedene Sorten von "richtig". Menschliche Codierer sind kein Orakel: Törnberg rät, die Übereinstimmung zwischen den Menschen und zwischen Mensch und Modell _beides_ zu berichten @tornberg2024best. Und ein Teil der Uneinigkeit unter Menschen ist kein Rauschen, sondern echte Mehrdeutigkeit @plank2022problem.

#hoersaal([Wenn selbst die Menschen nicht einig sind, was ist dann die Wahrheit?], [Es gibt keine absolute, nur einen Referenzstandard aus Labels geschulter Menschen. Deshalb gehört deren Übereinstimmung untereinander als Vergleichswert in jede Studie: Stimmt das Modell so gut mit Menschen überein wie diese untereinander, hat es das Menschenmögliche erreicht.])

== Übereinstimmung messen

=== Zufallstreffer herausrechnen

Naheliegend ist die *prozentuale Übereinstimmung*: Bei wie vielen von 100 Texten vergeben Mensch und Modell dasselbe Label? Sie ist leicht zu verstehen und leicht zu täuschen.

#alltag[Zwei Wettervorhersager in der Wüste sagen jeden Tag "sonnig". An 98~% der Tage stimmen sie überein, und keiner von beiden hat etwas gekonnt. Die Übereinstimmung entstand, weil fast immer dieselbe Antwort richtig ist.]

Die Idee der besseren Kennzahlen hat drei Schritte: Zufallstreffer ausrechnen, abziehen, den Rest mit dem vergleichen, was oberhalb des Zufalls überhaupt möglich war.

#figure(
  diagram(spacing: (7mm, 9mm),
    fknoten((0, 0), [Rohe \ Übereinstimmung], w: 36mm),
    fknoten((1, 0), [Zufallstreffer \ abziehen], w: 36mm),
    fknoten((2, 0), [Durch das \ Mögliche teilen], w: 36mm),
    fknoten((3, 0), [Wert: 1 perfekt, \ 0 wie Zufall], col: c-blue, filled: true, w: 36mm),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"),
  ),
  caption: [Die Idee aller zufallskorrigierten Maße. Unter 0 liegt, wer sich häufiger widerspricht, als der Zufall erwarten ließe.],
)

Der bekannteste Vertreter ist *Cohen's kappa* für zwei Beurteiler @cohen1960coefficient.

#beispiel(titel: [Ein Mensch und ein LLM, 100 Texte])[Beide beurteilen 100 Texte als relevant (1) oder nicht relevant (0).

#figure(
  table(columns: (auto, auto, auto, auto), align: (left, center, center, center),
    table.header([], [LLM: 0], [LLM: 1], [Summe]),
    [*Mensch: 0*], [40], [10], [50],
    [*Mensch: 1*], [5], [45], [50],
    [*Summe*], [45], [55], [100],
  ),
  caption: [Gemeinsame Zähltabelle: Zeilen sind die Labels des Menschen, Spalten die des Modells.],
)

Auf 40 + 45 = 85 Texten sind sie einig: *85~% Übereinstimmung*. Wie viele Treffer hätte der Zufall geliefert? Der Mensch sagt bei der Hälfte der Texte "1", das Modell bei 55 von 100. Folgen beide nur diesen Gewohnheiten, sind sie zufällig bei rund 27,5~% der Texte beide bei "1" und bei rund 22,5~% beide bei "0", also zusammen bei etwa *50~%*. Möglich wären oberhalb des Zufalls 100 - 50 = 50 Punkte, erreicht haben sie 85 - 50 = 35. Kappa ist 35 von 50, also *0,70*.]

Ein Wert wie 0,70 ist eine Schätzung aus 100 Texten; sein Konfidenzintervall folgt in Abschnitt 5.4.

=== Ein Gedanke, viele Namen

In Papers begegnen dir mehrere Namen. Alle folgen dem Gedanken "Übereinstimmung minus Zufall" und unterscheiden sich nur darin, wie sie sich den Zufall vorstellen (rohe Übereinstimmung der Beispieltabelle: 0,850).

#figure(
  table(columns: (auto, 1fr, auto),
    table.header([Maß], [Was es dir sagt], [Wert im Beispiel]),
    [*Cohen's kappa*], [Zufall aus den eigenen Label-Gewohnheiten jedes Beurteilers], [0,700],
    [*Scotts pi, Fleiss' kappa*], [Zufall aus den zusammengelegten Gewohnheiten aller Beurteiler; Fleiss' kappa gilt für drei und mehr] , [0,699],
    [*Gwets AC1*], [rechnet mit weniger Zufall, wenn eine Kategorie überwiegt], [0,701],
    [*PABAK*], [Zufall heißt: alle Kategorien gleich wahrscheinlich], [0,700],
    [*Krippendorffs alpha*], [zählt Meinungsverschiedenheiten; beliebig viele Beurteiler, Lücken erlaubt], [0,701],
  ),
  caption: [Alle Maße auf der Tabelle des Beispiels @cohen1960coefficient @scott1955reliability @gwet2008computing @byrt1993bias @krippendorff2018content.],
)

Bei ausgewogenen Labels liefern alle fünf Maße dieselbe Zahl, hier auf zwei Tausendstel genau. Auseinander laufen sie erst bei schiefen Verteilungen; das ist der Inhalt von Abschnitt 5.4.

=== Mehr als zwei Beurteiler, Lücken und Skalen

*Krippendorffs alpha* ist der Alleskönner @krippendorff2018content. Stell dir vor, du mischst alle vergebenen Labels zufällig über die Texte. Alpha sagt, wie weit die echte Meinungsverschiedenheit unter der Meinungsverschiedenheit liegt, die das Mischen erzeugen würde: 1 heißt keine, 0 heißt so viel wie beim Mischen. Es verträgt beliebig viele Beurteiler und Texte, die nicht jeder bewertet hat, und es unterscheidet Skalen: *nominal* (Namen wie Spam und kein Spam, jeder Unterschied zählt gleich), *ordinal* (Ränge wie 1 bis 5, ein knapper Fehlgriff zählt weniger) und *Intervall* (Zahlen, bei denen der Abstand zählt) @hayes2007answering. Als Faustregel gilt für alpha meist 0,80 und mehr als verlässlich und 0,667 bis 0,80 als vorläufig; die Grenzen werden Krippendorffs Lehrbuch zugeschrieben, das zitierte Paper nennt keine.

Für drei oder mehr Codierer kennst du *Fleiss' kappa* @fleiss1971measuring. Warum man sich nicht auf eine einzige Zahl verlassen sollte, zeigt ein Beispiel: Zwei Menschen und ein LLM ordnen 12 Texte als dagegen, neutral oder dafür ein. Bei 8 Texten sind alle drei einig, bei 4 stehen zwei gegen einen; Fleiss' kappa ist 0,67.

#figure(
  diagram(spacing: (14mm, 14mm),
    fknoten((0, 0), [Mensch 1], w: 26mm),
    fknoten((2, 0), [Mensch 2], w: 26mm),
    fknoten((1, 1), [LLM], col: c-blue, filled: true, w: 26mm),
    edge((0, 0), (2, 0), "-", label: text(font: "Inter", size: 7.5pt)[0,625], label-side: left),
    edge((0, 0), (1, 1), "-", label: text(font: "Inter", size: 7.5pt, weight: "bold")[0,875], label-side: right),
    edge((2, 0), (1, 1), "-", label: text(font: "Inter", size: 7.5pt)[0,510], label-side: left),
  ),
  caption: [Cohen's kappa für jedes Paar. Das LLM stimmt mit Mensch 1 besser überein als Mensch 1 mit Mensch 2, mit Mensch 2 aber deutlich schlechter @calderon2025alternative.],
)

"Das LLM stimmt so gut mit den Menschen überein wie die Menschen untereinander" hängt also davon ab, welchen Menschen du als Referenz nimmst. Das ist der Grund, warum es in Abschnitt 5.5 den alternativen Annotator-Test gibt.

Ordnest du Bewertungen auf einer Skala, etwa 1 bis 5, ändert sich das Bild. Ein Mensch und ein LLM bewerten 10 Texte; bei der Hälfte geben sie exakt dieselbe Zahl. Behandelst du die Werte als bloße Kategorien, ist "4 gegen 5" so schlimm wie "1 gegen 5". Gewichtetes kappa und alpha auf Ordinalniveau wissen, dass 4 und 5 nah beieinander liegen. Die *ICC* (intraclass correlation) fragt, wie viel der Unterschiede zwischen den Bewertungen echte Unterschiede zwischen den Texten sind und wie viel Uneinigkeit der Bewerter. Sie gibt es in zwei Fassungen: "absolute agreement" wertet es als Uneinigkeit, wenn ein Bewerter alles einen Punkt höher einstuft, "consistency" nicht @mcgraw1996forming @liljequist2019intraclass.

#figure(
  table(columns: (auto, 1fr, auto),
    table.header([Maß (10 Bewertungen, Skala 1 bis 5)], [Was es dir sagt], [Wert]),
    [*Exakte Übereinstimmung*], [Anteil identischer Bewertungen], [0,50],
    [*Cohen's kappa, ungewichtet*], [jede Abweichung ist gleich schlimm], [0,37],
    [*Gewichtetes kappa*], [knappe Fehlgriffe kosten wenig, große viel], [0,84],
    [*Krippendorffs alpha, ordinal*], [dieselbe Idee für beliebig viele Beurteiler], [0,84],
    [*ICC, absolute agreement*], [echte Textunterschiede gegen Beurteiler-Uneinigkeit], [0,86],
    [*Pearson-Korrelation*], [bewegen sich die Zahlen gemeinsam? Verschiebungen werden ignoriert], [0,85],
  ),
  caption: [Dieselben zehn Bewertungspaare, sechs Sichtweisen.],
)

#fallstrick[Die Pearson-Korrelation ist kein Übereinstimmungsmaß. Gibt ein Bewerter stets zwei Punkte mehr als der andere, ist die Korrelation perfekt, die Übereinstimmung aber gleich null. Lege außerdem die Skala (Kategorien, Ränge oder Zahlen) fest, bevor du rechnest.]

=== Welches Maß wann

#figure(
  table(columns: (auto, 1fr),
    table.header([Deine Lage], [Berichte]),
    [*Zwei Beurteiler, Kategorien*], [Cohen's kappa],
    [*Drei oder mehr Beurteiler*], [Krippendorffs alpha, oder Fleiss' kappa, wenn niemand Texte auslässt],
    [*Einzelne Labels fehlen*], [Krippendorffs alpha],
    [*Geordnete Bewertungen, 1 bis 5*], [gewichtetes kappa oder alpha auf Ordinalniveau],
    [*Zahlenwerte*], [ICC (absolute agreement), nicht die einfache Korrelation],
    [*Eine Kategorie ist sehr selten*], [kappa oder alpha, dazu AC1, Werte je Klasse und die Zähltabelle],
  ),
  caption: [Entscheidungshilfe: Beginne bei den Beurteilern und den Labels, nicht bei der Kennzahl.],
)

Wähle das Maß vor dem Blick auf die Daten, sonst nimmst du am Ende die schönste Zahl. Für die meisten Studien reichen ein Hauptmaß und die Zähltabelle.

=== In Python

Die Berechnung braucht nur wenige Zeilen. `human` und `llm` sind zwei Listen gleicher Länge mit den Labels.

#block(breakable: false)[#datei("agreement.py")[
```python
import krippendorff
from sklearn.metrics import cohen_kappa_score

# human, llm: je 100 Labels (die Tabelle von oben)
print(cohen_kappa_score(human, llm))
print(krippendorff.alpha(reliability_data=[human, llm],
                         level_of_measurement="nominal"))
```
]]

```out
0.7
0.701
```

Für gewichtetes kappa gibst du `weights="quadratic"` an, für drei Beurteiler liefert `statsmodels` mit `fleiss_kappa` und `aggregate_raters` das Ergebnis, die ICC berechnet `pingouin.intraclass_corr`. Gwets AC1 steckt im Paket `irrCAC`, das alte Versionen von `scipy` und `pandas` festschreibt; auf Python 3.13 installierst du es mit `pip install --no-deps irrCAC==0.4.4` (Stand: 11. November 2026) @scikitlearn2026scikitlearn @statsmodels2026statsmodels @pingouin2026pingouin @castro2017fast.

#fallstrick[`krippendorff.alpha` rechnet standardmäßig mit dem Intervallniveau. Bei Kategorien liefert das ohne Fehlermeldung eine falsche Zahl. Gib `level_of_measurement` immer ausdrücklich an.]

== Wenn ein hoher Wert täuscht

=== 90 Prozent und trotzdem nichts

Nimm zwei Tabellen mit je 100 Texten, zwei Codierern und genau 10 Meinungsverschiedenheiten. Die rohe Übereinstimmung ist in beiden 90~%. Links ist die gesuchte Kategorie "relevant" häufig, rechts selten.

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 14pt,
    table(columns: (auto, auto, auto), align: (left, center, center),
      table.header([Ausgewogen], [B: nein], [B: ja]),
      [*A: nein*], [45], [5],
      [*A: ja*], [5], [45],
    ),
    table(columns: (auto, auto, auto), align: (left, center, center),
      table.header([Eine seltene Klasse], [B: nein], [B: ja]),
      [*A: nein*], [90], [5],
      [*A: ja*], [5], [0],
    ),
  ),
  caption: [Zwei Tabellen, jeweils 90~% rohe Übereinstimmung.],
)

#rechnung(titel: [Warum rechts nichts übrig bleibt])[*Links:* Jeder sagt bei 50 Texten "ja". Folgen beide nur ihrer Gewohnheit, treffen sie zufällig bei etwa 25 + 25 = 50 Texten. Erreicht haben sie 90, also 40 der 50 Punkte oberhalb des Zufalls: kappa 0,80.

*Rechts:* Jeder sagt bei 95 Texten "nein" und bei 5 "ja". Zufällig treffen sie dann bei 95~% von 95~%, also bei rund 90 Texten beide auf "nein", und bei fast keinem auf "ja". Erreicht haben sie 90. Oberhalb des Zufalls bleibt nichts, kappa ist knapp unter null (-0,05). Die beiden haben nie denselben relevanten Text gefunden.]

Zwischen den beiden Tabellen liegt ein dritter Fall: Sagt jeder Codierer bei 90 von 100 Texten "nein" (beide gleichzeitig bei 85), ist die rohe Übereinstimmung wieder 90~%, kappa aber nur 0,44. Gwets AC1 geht in die Gegenrichtung (0,80, 0,88, 0,89) und spiegelt vor allem die häufige Klasse. Keines der beiden Maße ist einfach "richtig": kappa zeigt, dass bei der seltenen Klasse keine Übereinstimmung besteht, AC1 beschreibt, wie sicher die häufige Klasse getroffen wird. Deshalb gehören bei seltenen Klassen immer die Zähltabelle und die Werte je Klasse in den Bericht @feinstein1990high @gwet2008computing @tornberg2024best. Chew et al. nutzten AC1 für seltene Codes @chew2023llm; Pangakis et al. empfehlen für Klassen unter 1~% eine größere Validierungsstichprobe @pangakis2023automated.

=== Wenn das Modell anders labelt als der Mensch

Es gibt ein zweites, überraschenderes Phänomen. Bei 60~% roher Übereinstimmung gilt: Labelt Codierer A bei 40~% der Texte "1" und B bei 30~%, ist kappa 0,13. Labelt B bei 70~% der Texte "1", also ganz anders als A, steigt kappa auf 0,26, obwohl die rohe Übereinstimmung gleich bleibt. Kappa belohnt unterschiedliche Gewohnheiten, weil dann weniger Zufall erwartet wird. Für LLMs ist das heikel, denn sie verschieben Labels oft systematisch: Rathje et al. berichten, dass neutrale Texte zu oft als positiv oder negativ eingestuft wurden, und Pangakis et al. fanden bei 20 von 27 Aufgaben den Recall (Anteil der echten Fälle, die das Modell findet) über der Precision (Anteil seiner Treffer, die echt sind): Es markiert zu viel @rathje2024gpt @pangakis2023automated. Das Gegenmittel ist einfach: Zeige neben jeder Kennzahl, wie oft jeder Beurteiler welches Label vergibt.

=== Einen Wert lesen

Für kappa sind die Bänder von Landis und Koch üblich: 0,81 bis 1,00 fast perfekt, 0,61 bis 0,80 beachtlich (_substantial_), 0,41 bis 0,60 mäßig, 0,21 bis 0,40 schwach, 0,00 bis 0,20 gering, darunter schlecht. Die Autoren nannten diese Grenzen selbst "clearly arbitrary" und boten sie nur als "useful benchmarks" an @landis1977measurement. McHugh hält alles unter 0,60 für unzureichend @mchugh2012interrater. Auf "Ist 0,7 genug?" antwortest du deshalb mit Gegenfragen: Was kostet ein falsches Label in deiner Studie, und wie hoch ist die Übereinstimmung der Menschen auf denselben Texten?

=== Wie genau ist der Wert?

Ein kappa von 0,70 aus 100 Texten ist eine Schätzung. Das *Konfidenzintervall* gibt die Spanne an, in der der wahre Wert vermutlich liegt. Bei 100 Texten reicht sie von 0,56 bis 0,84, also von "beachtlich" bis "fast perfekt". Bei 400 Texten mit demselben Wert wird sie enger, von 0,63 bis 0,77 @statsmodels2026statsmodels.

Vier Mal so viele Texte halbieren die Breite der Spanne. Für jedes Maß funktioniert der *Bootstrap*: Ziehe aus deinen Texten etwa 2~000 Mal neue Stichproben gleicher Größe mit Zurücklegen, berechne jedes Mal das Maß und nimm die mittleren 95~% der Ergebnisse.

#block(breakable: false)[#datei("bootstrap.py")[
```python
import numpy as np
from sklearn.metrics import cohen_kappa_score

rng = np.random.default_rng(2026)
h, l = np.array(human), np.array(llm)
idx = rng.integers(0, len(h), (2000, len(h)))   # 2000 neue Stichproben
werte = [cohen_kappa_score(h[i], l[i]) for i in idx]
print(np.percentile(werte, [2.5, 97.5]).round(2))
```
]]

```out
[0.55 0.84]
```

== LLM-Hacking und Validierung

=== Jede Einstellung ist ein Freiheitsgrad

Ein Sprachmodell liefert nicht _ein_ Label, sondern eines pro Konfiguration: Modell, Version, Prompt, Temperatur, Abbildung der Antwort auf ein Label. Jede dieser Einstellungen verändert die Ergebnisse.

#figure(
  table(columns: (auto, 1fr, auto),
    table.header([Einstellung], [Befund], [Quelle]),
    [*Temperatur*], [GPT-3.5: Übereinstimmung zwischen Läufen 91,7~% auf 97,6~% (Temperatur 1 auf 0,2)], [Alizadeh et al.],
    [*Wiederholung*], [7 Läufe: bei 85,1~% der Texte immer dasselbe Label; diese Labels waren 19,4 Punkte treffsicherer], [Pangakis et al.],
    [*Wortlaut*], [10 Umformulierungen: Übereinstimmung zwischen ihnen 0,24 bis 0,70, im Mittel 0,43], [Reiss],
    [*Modellversion*], [Mittlerer F1 0,571, 0,603, 0,653 über drei GPT-Versionen], [Rathje et al.],
    [*Reihenfolge der Kategorien*], [Ausgaben aller vier getesteten offenen Modelle änderten sich], [Halterman und Keith],
  ),
  caption: [Was ein Label verändern kann @alizadeh2025open @pangakis2023automated @reiss2023testing @rathje2024gpt @halterman2026codebook.],
)

Aus dem Wortlaut-Befund wird ein Maß: Der *Prompt-Stabilitätswert* ist die Übereinstimmung (alpha) zwischen wiederholten Läufen und zwischen Umformulierungen des Prompts; unter 0,8 solltest du genauer hinschauen @barrie2024prompt. Auch eine verlangte Erklärung verändert Labels: Bei Atreja et al. stieg der Anteil "neutral" von 19,7~% auf 54,4~% @atreja2025prompt. Reiss nutzte gpt-3.5-turbo auf 234 deutschen Webtexten @reiss2023testing.

#studie(titel: [Baumann et al., 2025 (Preprint)])[*Was:* 37 Aufgaben aus 21 Studien, 18 Sprachmodelle, 199 Prompts, 2~361 Hypothesen, rund 13 Millionen Labels. Die Studie ist ein Preprint, also noch nicht von Fachleuten begutachtet (Stand: 11. November 2026). Die Autoren prüften, wie oft eine Konfiguration zu einem Schluss führt, den die Wahrheit nicht stützt, und nannten das *LLM-Hacking*. *Ergebnis:* Selbst mit den besten Modellen war das bei etwa 31~% der Hypothesen der Fall, mit kleinen Modellen bei etwa der Hälfte. Beim absichtlichen Probieren ließ sich bei 94,4~% der Hypothesen ohne echten Effekt ein Scheineffekt erzeugen. Ein hoher F1-Wert schützte nicht zuverlässig, manche Aufgaben mit F1 über 0,93 hatten ein Risiko über 50~%. *Was es heißt:* Berichte alle getesteten Konfigurationen und lege die endgültige vorab fest @baumann2025large.]

=== Ein Validierungsablauf

Der Kern der Absicherung ist ein Ablauf aus der Literatur @pangakis2023automated @tornberg2024best. Menschen labeln eine zufällige Teilmenge deiner Texte. Das Modell labelt dieselbe Teilmenge. Ist die Übereinstimmung zu schwach, verbesserst du das Codebook und versuchst es wieder, solange du nur an der Entwicklungshälfte arbeitest. Erst wenn der Prompt eingefroren ist, prüfst du einmalig an der zurückgehaltenen Testhälfte.

#figure(
  diagram(spacing: (6mm, 9mm),
    fknoten((0, 0), [Prompt und \ Codebook], col: c-blue, filled: true, w: 27mm),
    fknoten((1, 0), [Menschen labeln \ Zufallsteil], w: 27mm),
    fknoten((2, 0), [LLM labelt \ denselben Teil], w: 27mm),
    fknoten((3, 0), [Gut genug?], w: 27mm),
    fknoten((4, 0), [Test an \ gesperrtem Teil], col: c-blue, filled: true, w: 27mm),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"),
    edge((3, 0), (4, 0), "->", label: text(font: "Inter", size: 7pt)[ja], label-side: left),
    edge((3, 0), (0, 0), "->", bend: 28deg, label: text(font: "Inter", size: 7pt)[nein: Codebook verbessern], label-side: left),
  ),
  caption: [Entwicklungsteil zum Verbessern, gesperrter Testteil zum einmaligen Prüfen.],
)

Drei Regeln aus der Literatur: Validiere erst, wenn der Prompt endgültig ist, und Teilmengen (Sprachen, Kontexte) einzeln @tornberg2024best. Lass jeden Text von mindestens zwei, besser drei Menschen codieren, für die Übereinstimmung der Menschen und für den Annotator-Test. Nimm keine öffentlichen Benchmarks als Validierungsdaten, denn das Modell kann sie beim Training gesehen haben (_Kontamination_) @tornberg2024best; Pangakis et al. nutzten deshalb 11 nicht öffentliche Datensätze @pangakis2023automated.

Wie groß die Stichprobe sein muss, beantworten die Quellen sehr verschieden, weil sie Verschiedenes meinen: Törnberg nennt mindestens 20 bis 30 Texte je Kategorie @tornberg2024best, Pangakis et al. 250 bis 1~250 zufällige Texte, mehr bei Klassen unter 1~% @pangakis2023automated, Alizadeh et al. 100 bis 250 @alizadeh2025open, Calderon et al. für den Annotator-Test mindestens 30, meist 50 bis 100 @calderon2025alternative. Bei Baumann et al. hielten schon etwa 100 reine Menschenlabels den Schluss auf einen nicht vorhandenen Effekt bei etwa 10~%, bei unkorrigierten Mensch-LLM-Mischungen waren es 30 bis 40~% @baumann2025large. Ziehst du seltene Klassen absichtlich überproportional, gewichte sie in der Auswertung wieder auf ihren echten Anteil zurück.

=== Kann das LLM einen Menschen ersetzen?

Der *alternative Annotator-Test* (alt-test) beantwortet das ohne Gold-Labels (Labels, die als sicher richtig gelten) @calderon2025alternative.

#alltag[Ein Fußballteam fragt, ob der neue Spieler so gut ins Team passt wie ein Stammspieler. Man nimmt einen Stammspieler heraus und schaut, wer von beiden enger mit dem Rest des Teams zusammenspielt.]

Der Ablauf: Mindestens drei Menschen labeln dieselben Texte. Du lässt einen Menschen weg und fragst, wer den übrigen Menschen näher ist, das LLM oder der Weggelassene. Das LLM bekommt einen Sieg, wenn es mindestens so nah ist, mit einem kleinen Spielraum, der *Toleranz*. Das wiederholst du für jeden Menschen, korrigierst für die vielen Tests und wertest den Test als bestanden, wenn das LLM gegen mindestens die Hälfte der Menschen "gewinnt". Die Toleranz ist, wie viel Qualität du für Kostenersparnis opfern willst: 0,20 bei Experten, 0,15 bei geübten Annotatoren, 0,10 bei Crowd-Workern.

In einer Simulation (drei Menschen mit etwa 85~% Treffsicherheit, 100 Texte) besteht ein LLM mit etwa 88~% bei Toleranz 0,10 und 0,20. Eines mit nur etwa 70~% fällt bei 0,10 durch, besteht aber bei 0,20, weil die große Toleranz es gegen jeden Menschen oft verlieren lässt.

Lege die Toleranz deshalb vor dem Test fest und begründe sie. Bestehen heißt auch nur, dass das LLM relativ zu _diesen_ Annotatoren austauschbar ist, nicht, dass das Konstrukt richtig gemessen wird. Den Code der Autoren findest du unter `nitaytech/alttest` auf GitHub, das Notebook enthält eine kurze Fassung für diskrete Labels.

#hoersaal([Wie viele Texte brauche ich für die Validierung?], [Eine einzige Zahl gibt es nicht. Als Daumenregel: mindestens 20 bis 30 pro Kategorie, meist 100 bis 250 insgesamt, mehr bei seltenen Klassen. Entscheidend ist die Breite des Konfidenzintervalls, die du dir leisten kannst.])

== Codes aus den Daten ableiten

Oft gibt es kein Codebook. Dann entstehen Kategorien beim Lesen, so wie in der Grounded Theory (einem Verfahren, das Theorie aus den Daten aufbaut). Das Vorgehen hat drei Stufen: *offenes Codieren* (Textstellen in Konzepte zerlegen, oft Hunderte von Codes), *axiales Codieren* (Kategorien und Unterkategorien in Beziehung setzen) und *selektives Codieren* (alles um eine Kernkategorie herum zusammenführen). Ein Sprachmodell kann in jede Stufe helfen: Beim offenen Codieren schlägt es Codes mit einem belegenden Zitat vor, beim axialen führt es Doppelungen zusammen. Selektives Codieren bleibt eine deutende Entscheidung des Menschen @haindl2027research @depaoli2025reflections @depaoli2024performing.

Die Literatur zeigt vier Rollen mit zunehmender Automatisierung: Das LLM *schlägt Codes vor*, die ein Mensch zusammenführt @dai2023llm; es bildet *Konzepte* mit ausdrücklichen Einschlusskriterien, etwa "Kritik an traditionellen Geschlechterrollen" statt einer Wortliste (LLooM, TopicGPT) @lam2024concept @pham2024topicgpt; es arbeitet als *mehrere Coder-Agenten* mit verschiedenen Blickwinkeln @qiao2025thematic; oder es erzeugt Codes und Themen und ordnet danach alle Texte zu (*voller Ablauf*) @bergmann2026llms. Der Trend: ein zusätzliches Teammitglied unter menschlicher Kontrolle, kein Ersatz.

#figure(
  diagram(spacing: (3mm, 8mm),
    fknoten((0, 0), [Einheit \ festlegen], col: c-blue, filled: true, w: 21mm),
    fknoten((1, 0), [Codes mit \ Zitat], w: 21mm),
    fknoten((2, 0), [Doppelte \ aussortieren], w: 21mm),
    fknoten((3, 0), [Mit Mensch \ verhandeln], w: 21mm),
    fknoten((4, 0), [Themen, \ Codebook \ einfrieren], w: 21mm),
    fknoten((5, 0), [Je Code \ anwenden], w: 21mm),
    fknoten((6, 0), [Schwache \ Codes \ sichten], col: c-blue, filled: true, w: 21mm),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"),
    edge((3, 0), (4, 0), "->"), edge((4, 0), (5, 0), "->"), edge((5, 0), (6, 0), "->"),
  ),
  caption: [Ablauf für offene Antworten: Das LLM schlägt in Schritt 2 und 3 vor, Menschen entscheiden in 4, 5 und 7 @depaoli2025reflections @dai2023llm @dunivin2025scaling.],
)

Für Schritt 2 und 3 folgt man De Paoli und Mathis: bis zu 15 Codes je Interview, jeweils mit Namen, Beschreibung und wörtlichem Zitat, Temperatur 0, danach prüft eine zweite Abfrage, ob ein neuer Code schon im laufenden Codebuch steht @depaoli2025reflections. Für Schritt 6 trägt Dunivins Vorgehen: _ein_ Code je Abfrage, mit Rolle, Definition, Begründung und Entscheidung als JSON @dunivin2025scaling.

#block(breakable: false)[#datei("anwenden.txt")[
```text
Rolle: Du codierst Antworten für {studie}.
Code: {name}. Definition: {kernpunkte zuerst;
explizit oder implizit genannt}.
Text: {text}
Erkläre zuerst deine Begründung, entscheide dann.
Gib JSON zurück: {"begruendung": "...", "vorhanden": true|false}
```
]]

Dunivin prüfte das an Zeitungsabsätzen über W. E. B. Du Bois mit 9 Codes und GPT-4. Wenn das Modell zuerst die Begründung schrieb, stieg die mittlere Übereinstimmung mit Menschen (kappa) von 0,59 auf 0,68 bei einem Prompt je Code, bei allen Codes in einem Prompt von 0,46 auf 0,60; Beispiele im Prompt störten bei absatzlangen Texten. Praktisch heißt das: wichtige Punkte der Definition nach vorn, sagen, was man _sucht_, nicht, was man meiden soll, und jeden Code einzeln abfragen @dunivin2025scaling. Halterman und Keith ergänzen Verhaltenstests: Bleibt die Ausgabe in den erlaubten Labels, und ändert die Reihenfolge der Kategorien etwas? @halterman2026codebook

=== Ableiten ist schwerer als Anwenden

#studie(titel: [DeRegnaucourt et al., 2026])[*Was:* Eine einstündige Fokusgruppe, 48 Textabschnitte, GPT-4o, drei Codierende, ein Konsens-Codebuch mit 49 Codes. *Ergebnis beim Ableiten:* Das Modell erzeugte 137 Codes. 31,4~% entsprachen einem menschlichen Code, 26,3~% waren vernünftige Alternativen, 42,3~% nicht vernünftig; 21 der 49 menschlichen Codes (42,9~%) fehlten. *Beim Anwenden* des fertigen Codebuchs lag die mittlere Übereinstimmung bei 96~%, kappa bei 0,71, und bei 33 von 49 Codes über 0,60. *Aufwand:* 34 Stunden für das Codieren von Hand gegen 65 Stunden für den Aufbau des KI-Ablaufs plus 80 Minuten Lauf. *Grenzen:* ein Transkript, ein Modell, das Codebuch stammt aus demselben Text; zwei Autoren halten ein verwandtes Patent @deregnaucourt2026large.]

Die 96~% sind derselbe Effekt wie bei den Wüstenvorhersagern: Viele Codes treten in einem Abschnitt gar nicht auf, und das zu erkennen, bringt Übereinstimmung. Aussagekräftig ist das kappa. Effizienzgewinne gibt es erst bei großen Datenmengen; bei wenigen Interviews rät Dunivin vom LLM-Codieren ab @dunivin2025scaling.

== Ein abgeleitetes Codebuch bewerten

Hier gibt es keine feste Label-Menge, gegen die man prüfen könnte. Die Literatur kombiniert deshalb mehrere Verfahren und sagt zu jedem, was es _nicht_ zeigt. Der *Code-Abgleich* zählt, wie viele KI-Codes einem menschlichen Code entsprechen und wie viele fehlen; ob das menschliche Codebuch das richtige Ziel ist, zeigt er nicht @deregnaucourt2026large. Der *Adjusted Rand Index* vergleicht zwei Einteilungen unabhängig von den Namen, bewertet aber nicht die Qualität der Themen @bergmann2026llms. Das *Sättigungsverhältnis* zeigt, wie schnell keine neuen Codes mehr entstehen, aber nicht ihre Richtigkeit @depaoli2025reflections. Die *semantische Ähnlichkeit* misst die Nähe der Bedeutung zu Gold-Codes, nicht die Deutungsqualität @dai2023llm @parfenova2025text. *Kappa oder alpha je Code* messen, wie verlässlich das fertige Codebuch _angewendet_ wird, nicht, wie gut es abgeleitet wurde.

=== Zwei Einteilungen vergleichen

#alltag[Zwei Personen sortieren dieselben 12 Karteikarten in Stapel, nennen sie anders und bilden sie nicht ganz gleich. Du nimmst zwei beliebige Karten und fragst: Liegen sie bei beiden zusammen, oder liegen sie bei beiden getrennt? Der *Adjusted Rand Index* (ARI) ist der Anteil der Kartenpaare, bei dem beide Personen gleich entscheiden, korrigiert um den Zufall.]

Gelesen wird er wie kappa: 1 heißt identische Stapel, etwa 0 heißt nicht besser als zufällige Stapel, negative Werte sind schlechter als Zufall. Die Namen spielen keine Rolle. Bergmann et al. fanden bei 903 offenen Umfrageantworten (fünf menschliche Coder) zwischen Menschen und LLM einen ARI von 0,61 für Codes und 0,54 für Themen; die Spannen je Variable reichten von 0,35 bis 0,85 und von 0,31 bis 0,70 (Preprint) @bergmann2026llms.

#beispiel(titel: [12 Antworten, zwei Einteilungen])[Menschen sortierten 12 Antworten in die Themen "Kosten", "Zeit", "Unterstützung" und "Sonstiges", das LLM in "Geld", "Arbeitsaufwand", "Hilfe" und "Rest". Das LLM hat "Zeit" mit einer "Kosten"-Antwort zu "Arbeitsaufwand" verschmolzen und "Unterstützung" gespalten. Der Aufruf liefert den Wert, die Rechnung übernimmt die Bibliothek.

#figure(
  table(columns: (auto, auto, auto, auto, auto, auto), align: (left, center, center, center, center, center),
    table.header([], [Geld], [Arbeitsaufw.], [Hilfe], [Rest], [Summe]),
    [*Kosten*], [2], [1], [0], [0], [3],
    [*Zeit*], [0], [3], [0], [0], [3],
    [*Unterstützung*], [1], [0], [3], [0], [4],
    [*Sonstiges*], [0], [0], [1], [1], [2],
    [*Summe*], [3], [4], [4], [1], [12],
  ),
  caption: [Wie viele Antworten aus welchem Menschen-Thema in welchem LLM-Thema landeten.],
)

```python
from sklearn.metrics import adjusted_rand_score

# human, llm: je 12 Themen-Labels, gleiche Reihenfolge
print(round(adjusted_rand_score(human, llm), 2))
```

```out
0.37
```

Mit 0,37 wäre das eine schwache Übereinstimmung gegenüber den 0,54 bis 0,61 der Studie.]

ARI sagt nur, wie ähnlich zwei Einteilungen sind, nicht, ob die Themen etwas taugen. Ergänze ihn deshalb um den Code-Abgleich und einen qualitativen Blick. Die Studienlage ist gemischt: Parfenova et al. fanden nur etwa 0,2 Übereinstimmung (alpha) zwischen Menschen und LLMs bei 1~000 Zitat-Code-Paaren @parfenova2025text; van den Berkmortel et al. 0,703 unter Menschen gegenüber 0,487 und 0,507 für Mensch und LLM bei 317 niederländischen Artikeln @vandenberkmortel2026analyzing. Ashwin et al. beobachteten, dass die Fehler des LLM mit Eigenschaften der Befragten zusammenhingen; prüfe darum Fehlerraten nach Untergruppen @ashwin2026using. Und Dai et al. berichten kappa 0,87 und 0,81, aber erst _nach_ einer Verhandlung zwischen Mensch und LLM, das misst Annäherung, keine unabhängige Verlässlichkeit @dai2023llm.

=== Sättigung zählen

Wann hat das LLM aufgehört, Neues zu finden? Nach jedem Interview führst du zwei Zähler: alle bisher vergebenen Codes (mit Wiederholungen) und die bisher gefundenen verschiedenen Codes. Das *Sättigungsverhältnis* teilt die verschiedenen Codes durch alle Codes nach dem letzten Interview; ein niedriger Wert heißt, die Codes wiederholen sich. In einem erfundenen Beispiel mit 10 Interviews sind es 51 verschiedene unter 145 Codes, also 51 geteilt durch 145, rund 0,35. De Paoli und Mathis berichten 0,39 bei 10 und 0,12 bei 39 Interviews @depaoli2025reflections. Das Maß zählt Codes, nicht Erkenntnisse: Theoretische Sättigung meint, dass keine neuen _theoretischen_ Einsichten mehr kommen @haindl2027research. Es hängt von der Interviewreihenfolge ab.

Qualitative Forschung prüft Qualität über _Vertrauenswürdigkeit_ @haindl2027research, und ihre Strategien lassen sich übertragen: Die gesperrte Testhälfte entspricht dem Zurückhalten von Daten, an denen man Deutungen später prüft, unabhängige Analysen von Mensch und LLM der schrittweisen Replikation, versionierte Prompts und Laufprotokolle dem Prüfprotokoll und ein belegendes Zitat je Code der Belegkette zu den Rohdaten. Das ist eine Übersetzung für die LV, keine Aussage der Papers.

== Berichten, damit andere nachprüfen können

Ein Leser muss jedes Label wieder erzeugen können. Törnberg und Baumann et al. legen diese Checkliste nahe @tornberg2024best @baumann2025large.

#figure(
  table(columns: (auto, 1fr),
    table.header([Bereich], [Das gehört in den Bericht]),
    [*Das Messgerät*], [Modell, genaue Version, Zugriffsdatum und Weg (API oder lokal, keine Weboberfläche); das vollständige Prompt-Codebook (Anleitung für Menschen plus genauer Prompt und Einstellungen) samt Abbildung der Antwort auf ein Label; alle Parameter inklusive Standardwerten; alle ausprobierten Konfigurationen, möglichst vorab festgelegt],
    [*Der Nachweis*], [Stichprobe, Codierende, Übereinstimmung der Menschen; Zähltabelle, F1 je Klasse, Übereinstimmungsmaß mit Konfidenzintervall; Stabilität; Fehler nach Untergruppen; Labels und Code veröffentlichen, Datenschutz und Anonymisierung bedenken],
  ),
  caption: [Berichtsliste für LLM-annotierte Daten.],
)

Zu den Bedrohungen zählen ein Prompt, der etwas anderes misst als gedacht, ein Referenzstandard aus nur leichten Fällen, ein am Testteil abgestimmter Prompt, Kontamination, Instabilität (selbst bei Temperatur 0 sind proprietäre Modelle nicht ganz deterministisch @rathje2024gpt), schlechtere Ergebnisse in einzelnen Sprachen und Verzerrungen in späteren Schlüssen (Kapitel 6). Offen bleibt, ob Abweichung Fehler oder Information ist @plank2022problem, und ein Vergleich des _besten_ LLM-Paars mit dem _mittleren_ menschlichen Paar ist nicht fair @wang2026wisdom.

== In der Praxis: Annotation in deinem Projekt

+ *Aufgabe und Konstrukt festlegen.* Was genau sollst du messen (das _Konstrukt_, etwa "Zeitdruck im Studium"), und was kostet ein falsches Label? Wähle das Hauptmaß jetzt, vor den Daten.
+ *Codebook schreiben.* Definitionen, Beispiele, Regeln für Grenzfälle; das ist zugleich die Anleitung für Menschen und der Kern des Prompts.
+ *Zufallsstichprobe ziehen und teilen.* Etwa 60~% Entwicklungsteil, 40~% gesperrter Testteil; mindestens zwei, besser drei Menschen labeln beides.
+ *Prompt am Entwicklungsteil verbessern.* Temperatur niedrig, Version fest, Antwortformat vorgeben; danach einfrieren. Miss vorher die Übereinstimmung der Menschen, sie ist die Obergrenze dessen, was du vom Modell erwarten kannst.
+ *Einmal am Testteil prüfen.* Hauptmaß mit Konfidenzintervall, Zähltabelle, F1 je Klasse; bei seltenen Klassen AC1 ergänzen; Fehler nach Untergruppen.
+ *Stabilität prüfen.* Mehrere Läufe und einige Umformulierungen (Stabilitätswert unter 0,8 ist ein Warnsignal); den alternativen Annotator-Test mit vorab festgelegter Toleranz, wenn du behauptest, das LLM ersetze Menschen.
+ *Alles protokollieren und berichten.* Version, Parameter, Prompts, alle Konfigurationen.

Das Notebook `notebooks/05_agreement_and_codebooks.ipynb` baut die Auswertung mit synthetischen Daten nach.

== Für die Lehre

*"90~% Übereinstimmung ist doch super."* Zeige die Tabelle mit der seltenen Klasse (Abschnitt 5.4).

*"Hoher kappa-Wert heißt, das Modell hat recht."* Nein, kappa misst Übereinstimmung, nicht Richtigkeit; zwei Beurteiler können sich gleichmäßig irren (die Waage aus Abschnitt 5.1).

*"Das LLM braucht keine menschlichen Labels mehr."* Um zu belegen, dass es die Aufgabe kann, brauchst du sie.

#kurz(
  [Ein Sprachmodell als Annotator ist ein Messgerät und muss gegen Menschenlabels geeicht werden; Gleichmäßigkeit allein ist kein Beleg.],
  [Rohe Übereinstimmung zählt Zufallstreffer mit; ein gutes Maß rechnet sie heraus (1 perfekt, 0 Zufall). 90~% können bei einer seltenen Klasse kappa unter null bedeuten; zeige immer die Zähltabelle.],
  [Wähle das Maß nach Beurteilern und Labels (kappa, alpha, gewichtetes kappa, ICC) und gib es mit Konfidenzintervall an.],
  [Validiere mit Entwicklungs- und gesperrtem Testteil und mindestens zwei Menschen; berichte alle Konfigurationen.],
  [Ableiten ist schwerer als Anwenden; bewerte es mit Code-Abgleich, ARI, Sättigung.],
)

#selbsttest(
  ([Zwei Wettervorhersager sagen in der Wüste täglich "sonnig". Warum ist ihre Übereinstimmung von 98~% kein Qualitätsnachweis?], [Sie entsteht fast ganz durch Zufall, weil fast immer dieselbe Antwort stimmt; ein bereinigtes Maß läge bei etwa 0.]),
  ([Mensch und LLM stimmen bei 85 von 100 Texten überein, der Zufall hätte etwa 50 Treffer geliefert. Wie hoch ist Cohen's kappa?], [35 von 50 möglichen Punkten, also 0,70.]),
  ([Was bedeutet "100 Texte: Konfidenzintervall 0,56 bis 0,84" für kappa 0,70?], [Der wahre Wert liegt vermutlich irgendwo in dieser Spanne; mit vier Mal so vielen Texten wird sie halb so breit.]),
  ([Was prüft der alternative Annotator-Test, und was zeigt ein Bestehen nicht?], [Ob das LLM bei jedem weggelassenen Menschen mit Toleranz mithalten kann. Bestehen heißt austauschbar gegenüber diesen Annotatoren, nicht, dass die Labels gültig sind.]),
  ([Warum ist Ableiten von Codes schwerer als Anwenden?], [Es gibt keine feste Label-Menge zum Vergleichen; bei DeRegnaucourt et al. fehlten 21 von 49 menschlichen Codes, beim Anwenden lag kappa bei 0,71.]),
)

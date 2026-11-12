#import "lib.typ": *

= Forschungsmethoden im Überblick

Ein Doktorand vergleicht zwei Prompts, mit denen ein Sprachmodell Kundenrezensionen einordnet. Prompt B schneidet auf seinem Testset besser ab, der p-Wert liegt unter 5~%. Er schreibt: "B ist besser." Zwei Monate später probiert jemand anderes beide Prompts auf neuen Daten aus, und der Vorsprung ist weg. Hat der Doktorand geschummelt? Meistens nicht. Er hat getan, was viele tun: mehrere Varianten ausprobiert, die beste behalten, eine kleine Stichprobe genommen und das Ergebnis als Beweis gelesen.

Genau hier setzt dieses Kapitel an. Es zeigt dir, wie Forschung zu Aussagen kommt, denen man trauen kann: die Sprache der Methodenlehre (Paradigma, Design, Validität), die Grundregeln des statistischen Testens (Fehlerarten, p-Wert, Effektstärke, power) und die typischen Fallen, in die auch erfahrene Forschende tappen. Alles Weitere im Buch baut darauf auf, denn wer ein Sprachmodell als Annotator oder Gutachter einsetzt, stellt dieselben Fragen mit einem neuen Werkzeug.

Das Kapitel folgt dem Foliensatz 01. Die Simulationen, die hier nur als Ergebnis auftauchen, stehen im Notebook `notebooks/01_power_and_leakage.ipynb`. Begriffe wie Stichprobe, Konfidenzintervall oder p-Wert erklärt das Kapitel _Das Nötigste vorab_; hier steht beim ersten Gebrauch trotzdem ein kurzer Satz dazu.

#lernziele(
  [Du ordnest eine Studie auf den vier Ebenen Paradigma, Methodologie, Methode und Instrument ein und wählst mit dem Entscheidungsbaum ein passendes Design.],
  [Du planst eine Interviewstudie und begründest die Zahl der Interviews mit saturation oder information power.],
  [Du liest Effektstärke, p-Wert und power richtig und bestimmst die nötige Stichprobengröße mit einer Bibliothek.],
  [Du erklärst, warum flexible Auswertung und Data Leakage Zufall wie einen Befund aussehen lassen, und nennst Gegenmittel.],
  [Du wählst Qualitätskriterien und Berichtsstandards passend zum Design und wendest die vier Validitätsfragen auf eine Studie mit Sprachmodell an.],
)

== Was Forschung ist und wie sie sich gliedert

Im Alltag heißt alles "Recherche", was mit Nachschlagen zu tun hat. Für die Methodenlehre ist der Unterschied wichtig. Wer nachschaut, welche Modellarchitekturen es gibt, *sucht*: Er findet vorhandenes Wissen. Wer Architekturen unter kontrollierten Bedingungen vergleicht und so dokumentiert, dass andere es nachmachen können, *forscht*. Forschung ist eine systematische Untersuchung, die verallgemeinerbares Wissen hervorbringt @haindl2027research, also Aussagen, die über deinen einzelnen Fall hinaus gelten. Auch ein negatives Ergebnis zählt, wenn es sauber belegt, dass ein Weg nicht funktioniert.

=== Vier Ebenen, damit nichts durcheinandergerät

Viele Missverständnisse entstehen, weil Begriffe auf verschiedenen Ebenen vermischt werden. Das Lehrbuch ordnet sie wie Karte, Route, Fahrzeug und Werkzeug einer Reise: Jede Ebene wird von der darüberliegenden eingeschränkt @haindl2027research.

#figure(
  placement: auto,
  diagram(spacing: (7mm, 8mm), node-corner-radius: 3pt,
    fknoten((0, 0), [Paradigma \ #text(size: 6.5pt)[Weltbild]], col: c-blue, filled: true, w: 36mm),
    fknoten((1, 0), [Methodologie \ #text(size: 6.5pt)[Gesamtlogik]], col: c-blue, filled: true, w: 36mm),
    fknoten((2, 0), [Methode \ #text(size: 6.5pt)[Erheben und Auswerten]], col: c-blue, filled: true, w: 36mm),
    fknoten((3, 0), [Instrument \ #text(size: 6.5pt)[Werkzeug]], col: c-blue, filled: true, w: 36mm),
    fknoten((0, 1), [Pragmatismus], col: c-grey, w: 36mm),
    fknoten((1, 1), [Fallstudie], col: c-grey, w: 36mm),
    fknoten((2, 1), [Interviews], col: c-grey, w: 36mm),
    fknoten((3, 1), [Interviewleitfaden], col: c-grey, w: 36mm),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"),
  ),
  caption: [Die vier Ebenen mit je einem Beispiel. Je weiter rechts, desto konkreter.],
)

Typische Verwechslungen: "qualitative Methodologie" mischt einen Zugang mit einer Methodologie, "Survey-Methodologie" eine Methode mit einer Methodologie @haindl2027research. Für dieses Buch wichtig: Ein Prompt oder Kodierschema für ein Sprachmodell ist ein *Instrument* und muss geprüft werden wie ein Fragebogen.

=== Paradigmen: die Brille, durch die man schaut

Ein *Paradigma* (_paradigm_) bündelt Grundannahmen darüber, was es gibt, wie man es erkennen kann und welche Verfahren dazu passen. Du musst es nicht philosophisch durchdringen, aber nennen können, denn es entscheidet, welche Gütekriterien später gelten.

#figure(
  table(columns: (auto, 1fr, auto, auto),
    [Paradigma], [Grundannahme], [Gütevokabular], [Typische Designs],
    [*Postpositivism*], [Wirklichkeit lässt sich durch Messen und Widerlegen annähern.], [Validität, Reliabilität], [Experiment, Survey],
    [*Constructivism*], [Bedeutung wird gemeinsam hergestellt, Forschende sind Teil davon.], [Trustworthiness], [Fallstudie, Ethnografie],
    [*Pragmatism*], [Die Forschungsfrage bestimmt die Methode.], [beides plus Integration], [Mixed Methods, Design Science],
    [*Critical realism*], [Es gibt eine echte Welt, unser Wissen darüber ist fehlbar.], [inference quality], [Mixed Methods],
  ),
  caption: [Vier Paradigmen nach den Foliendarstellungen @lincoln1985naturalistic @creswell2025designing @venkatesh2013bridging.],
)

Forschung ist *empirisch*, wenn die Schlüsse aus beobachteten Daten stammen, und *nicht-empirisch*, wenn sie aus Überlegung entstehen (Beweise, Taxonomien, systematische Übersichten). Empirische Arbeiten beschreiben, suchen Zusammenhänge oder prüfen Ursachen mit Experimenten. Weil Zusammenhang nicht Ursache ist, lohnt sich Misstrauen gegen Aussagen, die aus bloßen Korrelationen Ursachen machen.

Drei Schlussarten helfen beim Denken: Du siehst, dass dein Klassifikator bei langen Eingaben versagt (ein Muster erkennen: _induce_). Du vermutest, dass lange Texte abgeschnitten werden (die plausibelste Erklärung raten: _abduce_). Du sagst voraus, dass kürzere Eingaben das Problem beheben, und testest das (_deduce_). Die meisten Studien mischen alle drei.

== Das passende Design wählen

Es gibt drei große Zugänge @haindl2027research. *Quantitative* Forschung misst und rechnet: Sie arbeitet mit Zahlen aus standardisierten Instrumenten und behauptet Wahrscheinlichkeiten, Zusammenhänge oder Ursachen. *Qualitative* Forschung will Bedeutung verstehen: Sie arbeitet mit Worten und Beobachtungen, die Forschenden sind selbst das wichtigste Instrument. *Mixed Methods* verbinden beides absichtlich. Welcher Zugang passt, hängt von der Aussage ab, die du machen willst, nicht von Vorlieben.

#figure(
  placement: auto,
  diagram(spacing: (4mm, 11mm), node-corner-radius: 3pt,
    fknoten((1.25, 0), [Ursache gefragt?], col: c-blue, filled: true, w: 34mm),
    fknoten((0.5, 1), [Zufällige Zuteilung \ möglich?], col: c-grey, w: 34mm),
    fknoten((2, 1), [Breite \ Verallgemeinerung?], col: c-grey, w: 34mm),
    fknoten((3.5, 1), [Tiefer Kontext \ nötig?], col: c-grey, w: 34mm),
    fknoten((0, 2), [Echtes \ Experiment], col: c-blue, filled: true, w: 28mm),
    fknoten((1, 2), [Quasi- \ Experiment], col: c-blue, filled: true, w: 28mm),
    fknoten((2, 2), [Survey], col: c-blue, filled: true, w: 28mm),
    fknoten((3, 2), [Fallstudie], col: c-blue, filled: true, w: 28mm),
    fknoten((4, 2), [Design Science], col: c-blue, filled: true, w: 28mm),
    edge((1.25, 0), (0.5, 1), "->", label: text(size: 6.5pt)[ja], label-side: right),
    edge((1.25, 0), (2, 1), "->", label: text(size: 6.5pt)[nein], label-side: left),
    edge((0.5, 1), (0, 2), "->", label: text(size: 6.5pt)[ja], label-side: right),
    edge((0.5, 1), (1, 2), "->", label: text(size: 6.5pt)[nein], label-side: left),
    edge((2, 1), (2, 2), "->", label: text(size: 6.5pt)[ja], label-side: right),
    edge((2, 1), (3.5, 1), "->", label: text(size: 6.5pt)[nein], label-side: left),
    edge((3.5, 1), (3, 2), "->", label: text(size: 6.5pt)[ja], label-side: right),
    edge((3.5, 1), (4, 2), "->", label: text(size: 6.5pt)[nein], label-side: left),
  ),
  caption: [Entscheidungsbaum zur Designwahl, nach Abbildung 2.6 des Lehrbuchs @haindl2027research. Design Science behandelt Kapitel 2.],
)

Praktische Grenzen engen die Wahl zusätzlich ein: In einer Masterarbeit sind lange Feldstudien meist nicht machbar.

#figure(
  table(columns: (auto, 1fr, 1fr, 1fr),
    [], [Survey], [Fallstudie], [Experiment],
    [*Typische Frage*], [Wie verbreitet ist X?], [Wie und warum passiert X hier?], [Verursacht X das Ergebnis Y?],
    [*Kernlogik*], [Eine Stichprobe beschreibt eine Population.], [Tiefe in einem abgegrenzten Fall.], [Eingreifen, kontrollieren, zufällig zuteilen.],
    [*Übertragbar auf*], [die Population (statistisch)], [ähnliche Fälle (analytisch)], [Ursachen unter den Bedingungen der Studie],
    [*Typische Risiken*], [Antwortausfall, sozial erwünschte Antworten], [begrenzte Anwendbarkeit über den Fall hinaus], [Selektion, Ereignisse während der Studie, Messwechsel],
  ),
  caption: [Drei Designs im Vergleich @haindl2027research @runeson2009guidelines.],
)

Online-Umfragen an unbekannte Zielgruppen erreichen oft Rücklaufquoten unter 25~%, bei Kaltakquise weniger. Dann stellt sich die Frage, ob die Antwortenden anders sind als die Übrigen (_non-response bias_) @haindl2027research. Fallstudien wählen ihre Fälle nach dem, was sie lehren können, nicht per Los, und nutzen mehrere Evidenzquellen ohne strikte Kontrolle @runeson2009guidelines.

=== Echtes und Quasi-Experiment

Ein *echtes Experiment* teilt die Teilnehmenden zufällig zu (wie Namen aus einem Hut), und verteilt so versteckte Unterschiede wie Erfahrung oder Motivation im Schnitt gleichmäßig. Deshalb darf man Unterschiede der Behandlung zuschreiben. Ein *Quasi-Experiment* kann das aus ethischen oder praktischen Gründen nicht: Teams, die sich *für* testgetriebene Entwicklung entschieden haben, unterscheiden sich vielleicht auch sonst von den anderen. Paarbildung, Messungen vor und nach der Behandlung und Kontrollgruppen schwächen das Problem ab, lösen es aber nicht @shadish2002experimental. Für dieses Buch wichtig: Ein Modellvergleich auf einem Benchmark ist ein (Quasi-)Experiment, und dieselben Fragen passen auf jede Bestenliste.

== Qualitative Forschung

Wenn du wissen willst, _wie_ und _warum_ etwas passiert, helfen Zahlen allein nicht. Dann sprichst du mit Menschen, beobachtest oder liest Dokumente. Der Preis: viel Zeit pro Fall und kein Rechenschieber, der sagt, wann du fertig bist.

#figure(
  table(columns: (auto, 1fr, auto),
    [Methodologie], [Worum es geht], [Typischer Aufwand],
    [*Phenomenology*], [Das Wesen gelebter Erfahrung herausarbeiten; eigene Annahmen bewusst beiseitelegen (_bracketing_).], [meist 3 bis 15 Teilnehmende],
    [*Grounded Theory*], [Eine Theorie aus den Daten bauen; Erheben und Auswerten laufen gleichzeitig.], [sechs bis neun Monate],
    [*Ethnography*], [Eine Kultur durch Feldarbeit und teilnehmende Beobachtung verstehen.], [mindestens sechs bis zwölf Monate],
    [*Case study*], [Ein gegenwärtiges Phänomen im Kontext, mit mehreren Evidenzquellen.], [je nach Fall],
  ),
  caption: [Vier qualitative Methodologien. Die Zeitangaben sind die Planungswerte des Lehrbuchs für Abschlussarbeiten @haindl2027research.],
)

=== Grounded Theory in der Praxis

"Grounded Theory" wird gern wie ein Gütesiegel benutzt. Die Kernpraktiken sind klar: gleichzeitig erheben und auswerten, Konzepte gezielt nachsammeln (_theoretical sampling_), offen, axial und selektiv kodieren, Notizen schreiben (_memoing_) und aufhören, wenn nichts Neues mehr kommt (_theoretical saturation_). Wer nur einzelne Techniken ausleiht, betreibt *method slurring* @stol2016grounded.

#studie(titel: [Stol, Ralph und Fitzgerald, 2016])[
  *Was:* Durchsicht von 98 Zeitschriftenartikeln aus dem Software Engineering, die Grounded Theory erwähnen. *Ergebnis:* 52 beanspruchten GT, aber 18 davon (35~%) nannten keine methodischen Details und 4 waren gar keine GT. 39 der 52 nannten keine GT-Variante. Unter den 30 ausführlich berichtenden Arbeiten kodierten fast alle (97~%), aber nur die Hälfte nannte saturation (50~%) und 40~% theoretical sampling @stol2016grounded. *Heißt:* Der Name steht oft auf Studien, die nur Interviews mit etwas Kodieren sind.
]

=== Thematic Analysis: ein Verfahren, drei Familien

*Thematic analysis* (TA) sucht Muster von Bedeutung in Text, etwa in Interviewtranskripten. Man vergibt dazu Kodes (kurze Etiketten für Textstellen) und bündelt sie zu Themen @braun2006using. Entscheidend ist die Familie, denn sie legt fest, was als Qualität gilt @braun2021one.

#figure(
  table(columns: (auto, 1fr, 1fr),
    [Familie], [Vorgehen], [Übereinstimmung der Kodierenden],
    [*Coding reliability*], [Festes Kodebuch, mehrere Kodierende; neopositivistisch.], [zentrales Gütekriterium],
    [*Codebook*], [Strukturierte Rahmen wie template analysis, qualitatives Paradigma mit pragmatischen Kompromissen.], [meist nicht verwendet],
    [*Reflexive*], [Organisch; die Subjektivität der Forschenden ist eine Ressource.], [kein Konsens nötig],
  ),
  caption: [Drei TA-Familien nach Braun und Clarke @braun2021one @braun2019reflecting.],
)

Die Übereinstimmung zweier unabhängig Kodierender (_inter-rater reliability_) ist also nur in manchen Familien sinnvoll. Das wird in Kapitel 5 wichtig, wenn ein Sprachmodell neben einem Menschen kodiert: Ob "Übereinstimmung mit dem Menschen" ein vernünftiges Maß ist, hängt von der Familie ab.

Der Ablauf hat sechs Phasen @braun2006using: mit den Daten vertraut werden, erste Kodes bilden, Themen erzeugen, prüfen, definieren und benennen, Bericht schreiben. Seit 2019 heißt die dritte Phase "Themen *erzeugen*" statt "suchen", weil Themen nicht in den Daten darauf warten, gefunden zu werden @braun2019reflecting. Schreibe nie, Themen seien "entstanden", sondern wie du sie konstruiert hast.

=== Wie viele Interviews braucht man?

#alltag[Du fragst Leute nach ihren Gründen für etwas. Die ersten Antworten bringen ständig neue Gründe, irgendwann hörst du nur noch Wiederholungen. Ab da lohnt der nächste Gast kaum noch.]

Dieser Punkt heißt *saturation* (Sättigung) @hennink2022sample. Man unterscheidet _code saturation_ ("alles gehört") von _meaning saturation_ ("alles verstanden").

#studie(titel: [Guest, Bunce und Johnson, 2006])[
  *Was:* Gezählt wurde, wie viele verschiedene Kodes nach wie vielen Interviews vorlagen. *Ergebnis:* Nach 6 Interviews 80 von 109 Kodes (73~%), nach 12 schon 100 (92~%). Ein zweites Land mit 30 weiteren Interviews brachte nur 5 neue Kodes, 4 davon ohne Gewicht @guest2006many. *Heißt:* Zwölf Interviews können für eine einheitliche Gruppe reichen, für eine heterogene wohl nicht, wie die Autoren selbst warnen.
]

Ein Überblick von Hennink und Kaiser kommt auf 9 bis 17 Interviews (im Mittel 12 bis 13) oder 4 bis 8 Fokusgruppen, wenn Ausreißer außen vor bleiben @hennink2022sample. Code saturation trat bei etwa 9 Interviews auf, meaning saturation bei 16 bis 24 @hennink2017code. Themen über mehrere Standorte brauchen noch mehr.

Die Gegenposition heißt *information power* @malterud2016sample: Je mehr relevante Information jede Person liefert, desto weniger Personen brauchst du. Das hängt ab von einem engen Studienziel, einer spezifischen Stichprobe, vorhandener Theorie, guter Gesprächsqualität und einer starken Analyse. Für die reflexive TA lehnen Braun und Clarke eine feste Zahl ganz ab: Die Stichprobengröße ist ein Urteil, das man im Verlauf fällt und begründet @braun2021saturate. Praktisch: Lege vorab fest, welche Art von saturation du meinst, wie fein deine Kodes sind und in welcher Reihenfolge du Fälle einbeziehst, und berichte das @buckley2022ten.

== Quantitative Forschung

Dieser Abschnitt kommt ohne Formeln aus. Du brauchst vier Ideen: die zwei Arten, mit einem Test falsch zu liegen, was ein p-Wert sagt, wie man die Größe eines Unterschieds ausdrückt und wie viele Daten man braucht, um ihn zu bemerken.

=== Zwei Arten, falsch zu liegen

#alltag[Ein Rauchmelder kann zwei Fehler machen. Er schlägt an, obwohl nichts brennt (Fehlalarm), oder er bleibt still, obwohl es brennt (Übersehen). Jede Einstellung ist ein Kompromiss: Ein sehr empfindlicher Melder weckt dich wegen Toast, ein träger verschläft den Brand.]

Ein statistischer Test funktioniert wie dieser Melder. Er geht von "es ist nichts los" aus (kein Unterschied zwischen den Prompts) und schlägt Alarm, wenn die Daten dazu schlecht passen. Das ergibt vier mögliche Ausgänge.

#figure(
  placement: auto,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let w = 4.3
    let h = 1.5
    let x0 = 3.6
    content((x0 + w / 2, 2 * h + 0.45), text(font: "Inter", size: 7.5pt, weight: "bold", [Es ist wirklich nichts los]))
    content((x0 + w * 1.5, 2 * h + 0.45), text(font: "Inter", size: 7.5pt, weight: "bold", [Es gibt wirklich einen Effekt]))
    content((x0 - 0.2, 1.5 * h), anchor: "east", align(right, text(font: "Inter", size: 7.5pt, weight: "bold", [Test schlägt Alarm \ ("Effekt gefunden")])))
    content((x0 - 0.2, 0.5 * h), anchor: "east", align(right, text(font: "Inter", size: 7.5pt, weight: "bold", [Test bleibt still \ ("nichts gefunden")])))
    let zellen = (
      (0, 1, c-red, [*Fehlalarm* \ Fehler 1. Art (_Type I error_)]),
      (1, 1, c-green, [*Treffer* \ Die Chance dafür heißt _power_]),
      (0, 0, c-green, [*Richtig still* \ kein Alarm, kein Effekt]),
      (1, 0, c-red, [*Übersehen* \ Fehler 2. Art (_Type II error_)]),
    )
    for (cx, cy, col, body) in zellen {
      let xa = x0 + cx * w
      let ya = cy * h
      rect((xa, ya), (xa + w, ya + h), fill: col.lighten(88%), stroke: 0.8pt + col)
      content((xa + w / 2, ya + h / 2), align(center, text(font: "Inter", size: 7.5pt, body)))
    }
  }),
  caption: [Die vier Ausgänge eines Tests, mit dem Rauchmelder als Bild. Nach @haindl2027research.],
)

Drei Regeln daraus. Erstens legst du die Grenze für Fehlalarme *vorher* fest, üblich sind 5~%: Auf 100 Studien, in denen nichts los ist, soll der Test höchstens 5-mal anschlagen. Das ist eine Vereinbarung, kein Naturgesetz. Zweitens ist die *power* die Chance, einen echten Effekt zu entdecken. Üblich sind 80~%: Von zehn Studien mit echtem Effekt findet der Test acht. Drittens kann ein Test nur sagen "ich habe kein Anzeichen für einen Effekt gefunden", nie "es gibt keinen". Hypothese, Grenze und Auswertung gehören vor die Datenerhebung, sonst entsteht p-Hacking (so lange suchen, bis es passt) oder HARKing (die Hypothese nachträglich ans Ergebnis anpassen) @haindl2027research. Getestet wird standardmäßig in beide Richtungen, außer eine Richtung wurde vorab begründet.

=== Der p-Wert

Das Kapitel _Das Nötigste vorab_ zeigt am Münzwurf, was ein p-Wert ist: wie oft Zufall allein ein mindestens so auffälliges Ergebnis liefern würde. Die American Statistical Association hat 2016 sechs Grundsätze dazu aufgestellt @wasserstein2016asa. Drei reichen dir für den Alltag. Ein p-Wert zeigt, wie schlecht die Daten zu "nichts los" passen. Er sagt *nicht*, wie wahrscheinlich deine Behauptung stimmt: Ein p von 0,03 heißt nicht "mit 97~% Wahrscheinlichkeit ist der Effekt echt". Und er misst nicht, wie groß oder wichtig ein Effekt ist.

#beispiel(titel: [Signifikant, aber belanglos])[
  Ein Prompt bringt bei 10~000 Testbeispielen 0,1~% mehr richtige Einordnungen. Mit so vielen Daten ist das hoch signifikant und praktisch bedeutungslos. Umgekehrt kann ein Plus von 50~% bei nur 10 Beispielen wegen zu geringer power nicht signifikant ausfallen @haindl2027research. Berichte deshalb zuerst die Größe des Unterschieds mit einer Spanne plausibler Werte (_confidence interval_), dann den p-Wert. Statt "Modell A ist besser, p unter 0,05" schreibst du "Modell A ist 2,1 Prozentpunkte genauer, plausibel sind ... bis ...".
]

=== Effektstärke: wie weit liegen zwei Gruppen auseinander?

#alltag[Zwei Schulklassen unterscheiden sich in der durchschnittlichen Körpergröße um 2 Zentimeter. Das geht in der Streuung unter, denn in jeder Klasse sind Kinder um 20 Zentimeter größer oder kleiner. Bei 20 Zentimetern Unterschied sähe man es sofort.]

Dieselbe Überlegung steckt in *Cohen's d*: Es drückt den Abstand der Gruppendurchschnitte in Einheiten der Streuung innerhalb der Gruppen aus. Die Zahl hat keine Einheit, deshalb lassen sich verschiedene Studien vergleichen. Als Daumenregel gelten 0,2 als klein, 0,5 als mittel und 0,8 als groß; "mittel" meinte Cohen als einen Effekt, den ein aufmerksamer Beobachter mit bloßem Auge bemerkt @cohen1992power.

#figure(
  placement: auto,
  cetz.canvas(length: 1mm, {
    import cetz.draw: *
    let pdf(x, m) = calc.exp(-0.5 * calc.pow(x - m, 2)) / calc.sqrt(2 * calc.pi)
    let sx = 8.0
    let sy = 52.0
    let panel(ox, d, titel) = {
      let xs = range(0, 81).map(i => -3.5 + i * (7.0 + d) / 80)
      let kurve(m) = xs.map(x => (ox + x * sx, pdf(x, m) * sy))
      let flaeche(m) = ((ox + xs.first() * sx, 0),) + kurve(m) + ((ox + xs.last() * sx, 0),)
      line(..flaeche(0), close: true, fill: c-grey.transparentize(65%), stroke: none)
      line(..flaeche(d), close: true, fill: c-blue.transparentize(55%), stroke: none)
      line(..kurve(0), stroke: 0.9pt + c-grey.darken(20%))
      line(..kurve(d), stroke: 0.9pt + c-blue.darken(10%))
      line((ox + xs.first() * sx, 0), (ox + xs.last() * sx, 0), stroke: 0.5pt)
      content((ox + (xs.first() + xs.last()) / 2 * sx, -6), text(font: "Inter", size: 7.3pt, align(center, titel)))
    }
    panel(30, 0.2, [klein (0,2) \ 85~% Überlappung])
    panel(100, 0.5, [mittel (0,5) \ 67~% Überlappung])
    panel(170, 0.8, [groß (0,8) \ 53~% Überlappung])
  }),
  caption: [Zwei Gruppen (grau und blau) bei kleinem, mittlerem und großem Cohen's d. Je größer d, desto weniger überlappen die Kurven (Werte aus Abbildung 6.2 des Lehrbuchs @haindl2027research).],
)

Für andere Vergleiche gibt es eigene Maße mit eigenen Etiketten, etwa Cohen's h für den Abstand zweier Prozentwerte oder die Korrelation für die Stärke eines Zusammenhangs (0,1 klein, 0,3 mittel, 0,5 groß) @cohen1992power. Du musst sie nicht auswendig wissen. Wichtig ist: Die Etiketten sind grobe Standardwerte aus dem Urteil eines Forschers, keine Messwerte eines Fachgebiets. Für den Unterschied zwischen zwei Modellen auf einem Benchmark ist "mittel" oft nicht begründet. Frag lieber: Welche Verbesserung wäre für meine Aufgabe gerade noch wichtig, und wie genau können meine Daten sie zeigen @lakens2022sample?

#beispiel(titel: [Zwei Annotationsoberflächen])[
  Fünf Annotatorinnen erreichen mit Oberfläche 1 diese Genauigkeiten: 72, 75, 78, 80, 83. Fünf andere mit Oberfläche 2: 68, 70, 71, 74, 77. Die Durchschnitte sind 77,6 und 72,0, der Abstand beträgt also 5,6 Punkte. Innerhalb einer Gruppe weichen die Werte typischerweise um etwa 3,9 Punkte voneinander ab. 5,6 ist rund das 1,4-Fache von 3,9, also ist Cohen's d etwa 1,4 (genau: 1,43) @cohen1992power. Das ist weit über "groß". Trotzdem sind fünf Personen pro Gruppe sehr wenig, die Schätzung ist unsicher.
]

Ein Aufruf der Bibliothek `pingouin` ersetzt die Handrechnung:

#block(breakable: false)[
#datei("effektstaerke.py")[
```python
import pingouin as pg

a = [72, 75, 78, 80, 83]   # Oberfläche 1
b = [68, 70, 71, 74, 77]   # Oberfläche 2
print(pg.compute_effsize(a, b, eftype="cohen"))
```
]
```out
1.427
```
]

Sag dazu, welche Variante du berichtest: Werden beide Systeme an *denselben* Testbeispielen geprüft (gepaarte Daten), gibt es eine eigene Variante mit anderer Zahl, die man nicht mit Cohens Etiketten vergleichen darf @lakens2013calculating.

=== Power: wie viele Daten brauche ich?

Das ist der Kern von Stichprobenplanung: Eine Münze, die in Wahrheit 60~% Kopf zeigt, entlarvst du nicht nach 10 Würfen, wohl aber nach mehreren Hundert. Je kleiner die Abweichung, desto mehr Daten brauchst du. Für den Vergleich zweier Gruppen mit 80~% power und 5~% Fehlalarmgrenze braucht man nach Cohens Tabelle diese Fallzahlen pro Gruppe @cohen1992power:

#figure(
  table(columns: (auto, auto, auto),
    [Effekt], [Cohen's d], [Fälle pro Gruppe],
    [klein], [0,2], [393],
    [mittel], [0,5], [64],
    [groß], [0,8], [26],
  ),
  caption: [Nötige Gruppengröße für 80~% power (zwei Gruppen, zweiseitiger Test). Eine exakte Rechnung ergibt 394, 64 und 26.],
)

Rechnen lässt sich das mit `statsmodels`:

#block(breakable: false)[
#datei("stichprobe.py")[
```python
import statsmodels.stats.power as smp

n = smp.TTestIndPower().solve_power(
    effect_size=0.5, alpha=0.05, power=0.8)
print(n)
```
]
```out
63.77
```
]

Das Ergebnis rundest du auf: 64 pro Gruppe (statsmodels 0.15.0, Stand: 11. November 2026). Umgekehrt gefragt: Mit nur 20 Fällen pro Gruppe und einem mittleren Effekt beträgt die power etwa 34~%. Zwei von drei solcher Studien würden einen echten Effekt verpassen, und ein "nicht signifikant" wäre kaum aussagekräftig. Es gibt einen zweiten Schaden: Wer nur die "erfolgreichen" Studien berichtet, überschätzt den Effekt. In der Simulation des Notebooks (echtes d von 0,5, 20 Fälle pro Gruppe) liegt das beobachtete d bei den signifikanten Studien im Mittel bei 0,87, denn nur große Zufallsausschläge überschreiten die Schwelle.

Eine Power-Analyse ist nur eine von sechs Arten, eine Stichprobengröße zu begründen; die anderen sind: (fast) die ganze Population messen, Ressourcengrenzen, Genauigkeit der Schätzung, Faustregeln oder offen sagen, dass es keine Begründung gibt @lakens2022sample. Rechne die power vorab, eine Rechnung *nach* der Studie ist ein bekannter Fehler @haindl2027research.

== Wenn der Zufall wie ein Befund aussieht

Die Werkzeuge des letzten Abschnitts setzen voraus, dass genau ein vorab festgelegter Test gerechnet und alles berichtet wird. In der Praxis ist das selten so. Dieser Abschnitt zeigt, wie daraus Fehlalarme entstehen.

=== Forking paths: der Garten der Gabelungen

#alltag[Du würfelst, bis eine Sechs kommt, und sagst dann: "Ich habe eine Sechs geworfen!" Der Satz verschweigt, wie oft du es versucht hast. Mit jedem Versuch wächst die Chance, dass irgendwann etwas Auffälliges herauskommt, auch wenn alles Zufall ist.]

Gelman und Loken haben gezeigt, dass das auch ohne böse Absicht passiert. Wer Auswertungsentscheidungen von den Daten abhängig macht (welche Variable, wann aufhören, welche Ausreißer weg), geht an jeder Gabelung einen Weg und sieht den anderen nicht. Ein anderer Datensatz hätte zu anderen, ebenso vernünftigen Entscheidungen geführt. Ein p-Wert ist nur aussagekräftig, wenn dieselbe Analyse auch für alle anderen möglichen Daten gelaufen wäre @gelman2014statistical.

#studie(titel: [Simmons, Nelson und Simonsohn, 2011])[
  *Was:* Simulation mit 15~000 Stichproben ohne *jeden* echten Effekt: Wie oft ergibt mindestens eine Analyse trotzdem p unter 0,05, wenn Forschende kleine Freiheiten nutzen? *Ergebnis:* Jede einzelne Freiheit treibt die Rate auf 8 bis 13~%, alle vier zusammen auf 60,7~% statt erwarteter 5~% @simmons2011false (Abbildung unten). *Heißt:* Einzeln harmlos wirkende Freiheiten summieren sich. Die Raten zeigen den Mechanismus, keine echten Quoten.
]

#figure(
  placement: auto,
  balken((
    ([A: zwei Ergebnisvariablen], 9.5),
    ([B: zehn Fälle nacherheben], 7.7),
    ([C: Zusatzvariable], 11.7),
    ([D: Bedingung weglassen], 12.6),
    ([A und B], 14.4),
    ([A, B und C], 30.9),
    ([A, B, C und D], 60.7),
  ), max: 65, breite: 8, farbe: c-red, einheit: " %", nachkomma: 1),
  caption: [Falsch-positiv-Raten ohne echten Effekt. Erwartet wären 5~% @simmons2011false.],
)

Bei Sprachmodellen sind die Gabelungen Prompt-Formulierung, Modellversion, Temperatur, Auswertungsregeln und Metrik. Das Notebook simuliert es mit Zufallszahlen: zwei Gruppen ohne Unterschied, aber `k` Metriken zur Auswahl.

#block(breakable: false)[
#datei("gabelungen.py")[
```python
rng = np.random.default_rng(0)

def false_positive_rate(k, n=30, reps=5000):
    hits = 0
    for _ in range(reps):
        a = rng.normal(size=(k, n))   # Gruppe 1, k Metriken
        b = rng.normal(size=(k, n))   # Gruppe 2, kein Unterschied
        p = stats.ttest_ind(a, b, axis=1).pvalue
        hits += (p < 0.05).any()      # irgendeine "signifikant"?
    return hits / reps

for k in (1, 4, 10, 20):
    print(k, f"{false_positive_rate(k):.3f}")
```
]
```out
1 0.051
4 0.175
10 0.412
20 0.625
```
]

Mit einer Metrik gibt es wie erwartet etwa 5~% Fehlalarme. Wer die beste aus vier aussucht, liegt bei rund 18~%, bei zehn bei gut 40~%, bei zwanzig über 60~% (Lauf der Wissensbasis, Stand: 11. November 2026).

#rechnung(titel: [Warum es so schnell wächst])[
  Jeder Test bleibt bei "nichts los" mit 95 Prozent unauffällig. Bei vier unabhängigen Tests müssen alle vier unauffällig bleiben: 0,95 mal 0,95 ist 0,9025, mal 0,95 ergibt 0,857, mal 0,95 ergibt 0,815. Mit 1 - 0,815 = 0,185, also gut 18~%, schlägt mindestens ein Test an. Das passt zur Simulation.
]

Die klassische Gegenmaßnahme heißt *Bonferroni*: Du teilst die 5~% durch die Zahl der Tests, bei vier Tests liegt die Schwelle pro Test bei 1,25~%. Das hilft aber nur bei Vergleichen, die du kennst und zählst, nicht bei den unsichtbaren Gabelungen @haindl2027research.

=== Wie viele Treffer stimmen?

Wenn du viele Ideen testest und nur wenige wirklich funktionieren, sind auch "signifikante" Treffer oft falsch. Das lässt sich durch Zählen zeigen. Der Anteil echter Treffer unter allen Treffern heißt _positive predictive value_ (PPV), das Modell stammt von Ioannidis @ioannidis2005why.

#figure(
  placement: auto,
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((6.0, 0), [*1~000 Ideen getestet* \ (Prompts, Features, Hypothesen)], w: 5.2, h: 1.0, bg: c-light)
    kasten((2.4, -1.9), [*100 funktionieren wirklich*], w: 4.6, h: 0.9, bg: c-green.lighten(88%), col: c-green)
    kasten((9.6, -1.9), [*900 Nieten*], w: 4.0, h: 0.9, bg: c-red.lighten(90%), col: c-red)
    kasten((0.9, -3.8), [80 gefunden \ (power 80~%)], w: 2.8, h: 1.0, bg: c-green.lighten(88%), col: c-green)
    kasten((4.2, -3.8), [20 übersehen], w: 2.8, h: 1.0, bg: white, col: c-grey)
    kasten((8.0, -3.8), [45 Fehlalarme \ (5~% von 900)], w: 3.0, h: 1.0, bg: c-red.lighten(90%), col: c-red)
    kasten((11.4, -3.8), [855 richtig verworfen], w: 3.0, h: 1.0, bg: white, col: c-grey)
    pfeil((5.0, -0.5), (3.0, -1.45))
    pfeil((7.0, -0.5), (9.0, -1.45))
    pfeil((1.9, -2.35), (1.2, -3.3))
    pfeil((3.2, -2.35), (4.0, -3.3))
    pfeil((8.9, -2.35), (8.3, -3.3))
    pfeil((10.4, -2.35), (11.1, -3.3))
    content((6.0, -5.1), text(font: "Inter", size: 8pt, weight: "bold")[80 + 45 = 125 Treffer, davon 80 echt: 64~% der Treffer stimmen])
  }),
  caption: [Jede zehnte Idee funktioniert, die power liegt bei 80~% und die Fehlalarmgrenze bei 5~%.],
)

Sinkt die power auf 35~%, finden sich nur noch 35 echte Treffer neben denselben 45 Fehlalarmen, und nur 44~% der Treffer stimmen. Funktioniert dagegen jede zweite Idee (und die power bleibt bei 80~%), sind es 400 echte gegen 25 falsche Treffer, also 94~% @ioannidis2005why.

Den Anteil senken laut Ioannidis kleine Studien, kleine Effekte, viele getestete Zusammenhänge und flexible Designs. Die beiden letzten beschreiben Hyperparametersuche und Benchmark-Jagd im maschinellen Lernen ziemlich genau.

=== Was die Replikationsprojekte zeigen

Die Probe aufs Exempel sind Wiederholungen. Replikation: gleiche Frage, neue Daten. Robustheit: dieselben Daten, andere Analystinnen. Reproduzierbarkeit: dieselben Daten und derselbe Code liefern dieselben Zahlen.

Die größten Projekte (Stand: 11. November 2026) zeigen das Bild:

- *Open Science Collaboration, 2015:* Von 100 Replikationen psychologischer Studien waren 36~% signifikant (bei den Originalen 97~%), der mittlere Effekt etwa halbiert @collaboration2015estimating.
- *SCORE, 2026, Replikation:* 55,1~% von 274 Behauptungen aus 164 Arbeiten replizierten, der mittlere Effekt schrumpfte von 0,25 auf 0,10 @tyner2026investigating.
- *Many analysts, 2018:* 29 Teams werteten denselben Datensatz zur selben Frage aus. Die Schätzungen reichten von 0,89 bis 2,93 (1,0 heißt kein Effekt), 20 von 29 waren signifikant @silberzahn2018many.
- *SCORE, 2026, Robustheit und Reproduzierbarkeit:* Bei 100 Studien mit mindestens fünf Neuanalysen kamen nur 34~% nahe an den Originaleffekt, 74~% zur gleichen Schlussfolgerung @aczel2026investigating. Von 600 gezogenen Arbeiten lieferten nur 24,0~% die Daten, 53,6~% der geprüften ließen sich exakt reproduzieren @miske2026investigating.

Die wichtigste Lehre: _Die_ Replikationsrate gibt es nicht. Dreizehn Erfolgskriterien von SCORE ergeben 28,6~% bis 74,8~% @tyner2026investigating. Eine gescheiterte Replikation beweist nicht, dass das Original falsch war @collaboration2015estimating.

=== Was dagegen hilft

Zwei Verfahren haben sich durchgesetzt. *Preregistration* heißt, Fragen und Analyseplan vor der Auswertung festzuschreiben; das trennt Vorhersage von nachträglicher Deutung @nosek2018preregistration. In knapp 16~000 Teststatistiken aus Wirtschaftszeitschriften senkte eine bloße Registrierung p-Hacking nicht, ein *detaillierter* Analyseplan schon @brodeur2024preregistration. Eine *multiverse analysis* geht den anderen Weg: Man rechnet alle vertretbaren Verarbeitungspfade und zeigt die ganze Verteilung. In einem Beispiel ergaben fünf Verarbeitungsentscheidungen 120 Datensätze, nur 7 davon lieferten ein signifikantes Ergebnis @steegen2016increasing. Zusätzlich hilft es, jede Analyse als primär, sekundär oder explorativ zu beschriften @appelbaum2018journal.

=== Data Leakage

#alltag[Eine Studentin lernt mit den echten Prüfungsfragen, die ihr versehentlich jemand gegeben hat, und schreibt eine 1. Ihr Wissen ist unverändert, nur der Test misst nicht mehr, was er soll.]

Dasselbe passiert im maschinellen Lernen als *data leakage*: Information aus dem Test oder aus der Zukunft sickert ins Training. Kapoor und Narayanan fanden das in mindestens 294 Arbeiten aus 17 Fächern. Bei der Bürgerkriegsvorhersage hatten alle 4 Arbeiten, die behaupteten, komplexe Modelle schlügen ein einfaches statistisches Standardverfahren (die logistische Regression), Leakage. Nach der Korrektur schrumpfte der Vorsprung auf der Skala AUC (0,5 heißt Raten, 1,0 perfekt) von 0,14 auf 0,01 @kapoor2023leakage. Die Autoren sortieren die Arten in drei Klassen: *L1* (Training und Test nicht sauber getrennt: kein Testset, Vorverarbeitung oder Auswahl der Eingabespalten, der _features_, über alle Daten, Duplikate), *L2* (Merkmale, die es im echten Einsatz nicht gäbe) und *L3* (Testdaten aus einer anderen Verteilung als der Einsatz, etwa zeitlich überlappend). Das Notebook zeigt L1 an reinem Zufall: 100 Zeilen, 5~000 Zufallsspalten, Zufallslabels.

#block(breakable: false)[
#datei("leakage.py")[
```python
# falsch: die Auswahl sieht alle Labels
X_sel = SelectKBest(k=20).fit_transform(X, y)
cross_val_score(model, X_sel, y, cv=5)      # Genauigkeit 0.85

# richtig: die Auswahl passiert in jedem Durchlauf neu
pipe = make_pipeline(StandardScaler(),
                     SelectKBest(k=20), model)
cross_val_score(pipe, X, y, cv=5)           # Genauigkeit 0.48
```
]
]

`cross_val_score` teilt die Daten in fünf Teile und testet nacheinander auf jedem. Es gibt nichts zu lernen, ehrlich wären also 50~%. Die falsche Variante erreicht 0,85, weil die Merkmalsauswahl schon die Test-Labels gesehen hat (scikit-learn 1.9.1, Stand: 11. November 2026). Die Regel: Alles, was aus Daten lernt (Skalieren, Merkmale auswählen, Fehlendes auffüllen), wird nur auf dem Trainingsteil angepasst. Verwandte Zeilen gehören in dieselbe Hälfte, zeitlich geordnete Daten trennt man nach Datum. Die REFORMS-Checkliste (32 Punkte in 8 Abschnitten) hilft beim Prüfen @kapoor2024reforms. Benchmark-Aufgaben, die in den Trainingsdaten eines Modells stecken, sind eine Form von L1-Leakage (Kapitel 4).

== Mixed Methods

Mixed Methods verbinden qualitative und quantitative Methoden in einer Untersuchung, damit Erkenntnisse entstehen, die keiner der Stränge allein liefert @venkatesh2013bridging. Beispiel aus dem Lehrbuch: Repository-Daten zeigen, _was_ Projekte unterscheidet, die Mitwirkende halten, Interviews zeigen, _warum_ @haindl2027research. Entscheidend ist die *Integration*: Eine Umfrage plus ein paar Interviews nebeneinander sind noch kein Mixed-Methods-Design. Das Ergebnis der Verbindung heißt *meta-inference*, eine Schlussfolgerung, die erst aus beiden Strängen zusammen folgt. Venkatesh et al. nennen sieben Gründe zum Mischen, etwa Ergänzung und Bestätigung.

#figure(
  table(columns: (auto, 1fr, 1fr),
    [Design], [Ablauf], [Beispiel],
    [*Convergent*], [Beide Stränge laufen im selben Zeitraum und werden dann zusammengeführt.], [Burnout-Umfrage und Interviews gleichzeitig],
    [*Explanatory sequential*], [Erst Zahlen, dann erklären Interviews auffällige Muster.], [Stack-Overflow-Beiträge auswerten, dann Entwickler befragen],
    [*Exploratory sequential*], [Erst Interviews, sie liefern das Instrument für einen quantitativen Test.], [Ingenieure interviewen, dann die Faktoren per Umfrage prüfen],
  ),
  caption: [Die drei Kerndesigns @fetters2013achieving @haindl2027research.],
)

Praktisch gelingt Integration mit einem *joint display*, einer Tabelle, in der Zahlen und Interviewbefunde nebeneinanderstehen.

#beispiel(titel: [Joint Display für ein Screening-Werkzeug])[
  Ein Werkzeug, das mit einem Sprachmodell Literatur vorsortiert, wird mit Kennzahlen auf einer von Menschen markierten Menge und mit Interviews von fünf Gutachtern geprüft. Jede Zeile ist ein Fehlertyp. Bei _übersehenen Studien_ steht links der _recall_ (wie viele der relevanten Studien wurden gefunden), rechts, warum Gutachter den Ausschlüssen misstrauen. Bei _Zuviel aufgenommen_ links die _precision_ (wie viele der aufgenommenen Studien sind relevant), rechts die erlebte Mehrarbeit. Eine Spalte hält fest, ob sich die Stränge bestätigen, ergänzen oder widersprechen @fetters2013achieving @dyers2025separate.
]

== Qualität sichern: Validität, Vertrauenswürdigkeit, Berichtsstandards

Qualitätskriterien folgen dem Paradigma. Quantitative Arbeit spricht von *Validität* (misst die Studie, was sie messen soll?) und *Reliabilität* (liefert sie bei Wiederholung dasselbe?), qualitative von *trustworthiness*. Mixed Methods müssen beides erfüllen und die Integration absichern, Design Science nennt Relevanz und Strenge (Kapitel 2) @haindl2027research. Alle ruhen auf einem ethischen Fundament: Integrität, Transparenz, Respekt vor den Beteiligten.

Die quantitative Seite ordnet Shadish, Cook und Campbell in vier Fragen @shadish2002experimental:

#figure(
  table(columns: (auto, 1fr, 1fr),
    [Validitätstyp], [Frage], [Typische Bedrohungen],
    [*Statistical conclusion*], [Gibt es den Zusammenhang wirklich, und ist er richtig geschätzt?], [zu wenig Daten, falsch genutzte Tests, Suchen nach Treffern, verrauschte Messungen],
    [*Internal*], [Ist der Zusammenhang in dieser Studie ursächlich?], [Auswahl der Teilnehmenden, Ereignisse im Verlauf, Reifung, Gewöhnung an den Test, Messwechsel, Ausfälle],
    [*Construct*], [Messen die Messungen das, was gemeint ist?], [Fehlerzahl als Ersatz für "Codequalität"],
    [*External*], [Gilt es über Personen, Orte, Aufgaben hinweg?], [Studierende als Ersatz für Profis, Benchmarks als Arbeitslast],
  ),
  caption: [Vier Validitätstypen @shadish2002experimental @haindl2027research.],
)

Am häufigsten vernachlässigt wird die erste Zeile: genug Daten, korrekte Tests, vorab geplante Analyse. Runeson und Höst haben die Typologie für Fallstudien im Software Engineering angepasst: construct, internal und external validity plus _reliability_, mit analytischer statt statistischer Verallgemeinerung @runeson2009guidelines.

Die qualitative Seite hat vier Entsprechungen @lincoln1985naturalistic: *credibility* (entspricht interner Validität), *transferability* (externe Validität), *dependability* (Reliabilität) und *confirmability* (Objektivität). Dazu gehören Strategien wie Triangulation (derselbe Befund aus mehreren Blickwinkeln), member checking (Teilnehmenden zeigen, ob du sie richtig verstanden hast) und eine lückenlose Belegkette vom Befund zu den Rohdaten @haindl2027research. Die APA fasst das als _methodological integrity_ zusammen: Treue zum Gegenstand plus Nutzen für das Forschungsziel @levitt2018journal.

Berichtsstandards sind Checklisten dafür, was Lesende brauchen, um eine Studie zu beurteilen und zu wiederholen: die ACM SIGSOFT Empirical Standards (methodenspezifisch; Stand: 11. November 2026 gibt es 19 Standards, aber keinen eigenen für LLM-Studien) @ralph2020empirical, APA JARS-Quant @appelbaum2018journal und JARS-Qual @levitt2018journal, APA MMARS für Mixed Methods und REFORMS für ML-basierte Wissenschaft @kapoor2024reforms.

Zum Schluss die ehrliche Buchführung: Jede Bedrohung, die du nicht ausräumen kannst, wird zur genannten *Limitation*, und jede Strategie belegt, dass eine Bedrohung kontrolliert wurde. Ein Limitationenabschnitt hält deshalb fest, welche Kriterien voll, teilweise oder gar nicht erfüllt sind @haindl2027research. Der Umkehrschluss lohnt: Wähle die Methode, deren Kernkriterien dein Projekt erfüllen kann. Eine kleine, ehrlich begrenzte Interviewstudie ist mehr wert als ein Experiment mit zu wenig power und verschwiegenen Lücken.

== Wo Sprachmodelle ins Spiel kommen

Jeder Einsatz eines Sprachmodells erbt die Validitätsfragen der Methode, in der es steckt. Baltes et al. unterscheiden sieben Studientypen: Annotatoren, Gutachter, Synthese, Probanden, Untersuchung der Nutzung, Modelle für neue Werkzeuge und Benchmarking (laufender Preprint, also eine noch nicht begutachtete Vorabfassung; v8 vom 18. September 2026, Stand: 11. November 2026) @baltes2025guidelines.

Das Vokabular dieses Kapitels fragt jede Rolle an: Als Kodierer in der thematic analysis erbt das Modell die Frage, welche TA-Familie gilt und ob Übereinstimmung sinnvoll ist (Kapitel 5). Als synthetischer Befragter muss es das gemeinte Konstrukt messen (Kapitel 4). Als Instrument, dessen Labels in Tests eingehen, verzerrt sein Fehler die Schätzung (Kapitel 6). Als Gutachter muss es mit dem Urteil von Menschen übereinstimmen (Kapitel 7).

Die Validitätsfragen sehen bei LLM-Studien so aus (Lehrbeispiele aus der Wissensbasis, keine Befunde der zitierten Arbeiten): Ein Lauf pro Konfiguration bei vielen Metriken bedroht die statistische Schlussfolgerung (Abhilfe: Wiederholungen, Intervalle, eine vorab festgelegte Hauptmetrik). Ein still aktualisiertes Modell mitten in der Erhebung bedroht die interne Validität (Abhilfe: Version festhalten, Zeitstempel). Benchmark-Genauigkeit als "Denkfähigkeit" zu lesen, ist ein Konstruktproblem: Was mit Denkfähigkeit gemeint ist, bleibt offen. Ein englischer Datensatz, auf alle Sprachen verallgemeinert, bedroht die externe Validität, nicht dokumentierte Prompts die Reliabilität (Abhilfe: Prompts und Code veröffentlichen) @shadish2002experimental @runeson2009guidelines.

Wie umstritten der Einsatz in qualitativer Arbeit ist, zeigt ein offener Brief in _Qualitative Inquiry_ (online Dezember 2025) mit 419 Unterzeichnenden aus 32 Ländern: Generative KI sei "not methodologically congruent" mit qualitativer Forschung @jowsey2025reject. In einer Studie mit 15 Interviews über das Wohlbefinden von Entwicklern bewerteten vier Fachleute blind Kodes und Themen. Sie bevorzugten die Kodes des Modells in 61~% der Fälle, bemängelten aber zerstückelte Daten und übersehene latente Bedeutung (Preprint) @martinezmontes2025large. Eine Replik hält die Einwände des Briefes für überwiegend philosophisch begründet @depaoli2026why. Das Paradigma löst vieles: Ein Modell kann als zusätzlicher Kodierer in der codebook TA bewertet werden, in der reflexiven TA nicht @braun2021one.

Für die Berichterstattung nennen Baltes et al. acht Punkte, die in den Kapiteln 4 bis 7 und im Berichtsteil von Kapitel 10 wiederkehren @baltes2025guidelines: (1) Nutzung und Rolle des Sprachmodells angeben, (2) Modellversionen und Einstellungen berichten, (3) System- und Prompt-Design dokumentieren, (4) Sitzungsprotokolle (_session traces_) berichten, (5) passende Vergleichswerte und Kennzahlen wählen, (6) ein offenes Modell als Vergleich einbeziehen, (7) Ausgaben gegen menschliches Urteil prüfen, (8) Grenzen und Gegenmaßnahmen benennen. Punkt 6 zählt für die Reproduzierbarkeit, weil geschlossene Modelle sich ändern oder verschwinden. Der Text ist ein laufender, noch nicht begutachteter Preprint: Zitiere die Version, die du benutzt hast.

== In der Praxis: Eine Studie in sieben Schritten planen

Wenn du selbst eine Studie mit Sprachmodell planst, hilft diese Reihenfolge.

+ *Aussage festlegen.* Was willst du behaupten: wie häufig, warum, ob eine Ursache vorliegt, wie man etwas löst? Schreibe den Satz auf.
+ *Design wählen.* Gehe den Entscheidungsbaum durch. Kannst du nicht zufällig zuteilen, nenne es Quasi-Experiment.
+ *Paradigma und Qualitätskriterien nennen.* Ein Satz im Methodenteil legt fest, ob du von Validität, trustworthiness oder beidem sprichst.
+ *Stichprobe begründen.* Quantitativ: Welche kleinste Verbesserung wäre wichtig? Dann Power-Rechnung mit `statsmodels`. Qualitativ: saturation oder information power, passend zur TA-Familie.
+ *Analyse vorab festlegen.* Hauptmetrik, Modellversion, Auswertungsregeln, Ausschlusskriterien, am besten registriert, mindestens datiert abgelegt.
+ *Pipeline prüfen.* Was aus Daten lernt, nur auf dem Trainingsteil. Duplikate und zeitliche Überschneidungen ansehen. Modellversion, Datum und Prompts protokollieren.
+ *Auswerten und berichten.* Effektstärke mit Spanne, dann p-Wert; alle Analysen und Varianten nennen; Grenzen als Limitationen festhalten.

== Für die Lehre

Diese Missverständnisse tauchen im Hörsaal immer wieder auf, so lassen sie sich auflösen.

#hoersaal([Heißt p = 0,03, dass mein Ergebnis mit 97~% Wahrscheinlichkeit stimmt?], [Nein. Der p-Wert beantwortet eine andere Frage: Wie überraschend wären die Daten, wenn nichts los wäre? Nimm die Münze: Zehnmal Kopf hintereinander wäre sehr überraschend, es sagt dir aber nicht, mit welcher Wahrscheinlichkeit diese Münze gezinkt ist. Dazu müsstest du wissen, wie viele Münzen im Umlauf gezinkt sind.])

#hoersaal([Wenn ein Ergebnis nicht signifikant ist, gibt es dann keinen Effekt?], [Nein. Vielleicht hattest du zu wenig Daten. Mit 20 Fällen pro Gruppe verpasst man einen mittleren Effekt in zwei von drei Studien. Frag deshalb immer nach der power oder nach der Spanne plausibler Werte.])

#hoersaal([Wir haben nur eine Analyse gerechnet. Warum sollen wir uns um forking paths sorgen?], [Weil die Frage nicht ist, wie viele Analysen du gerechnet hast, sondern wie viele du gerechnet hättest, wenn die Daten anders ausgesehen hätten. Hast du Ausreißer nach einem Blick auf die Daten entfernt, ist das schon eine Gabelung. Hilfe: vorher festlegen und alles berichten.])

#kurz(
  [Forschung ist systematisch und dokumentiert, damit andere sie prüfen und wiederholen können; Suche findet nur vorhandenes Wissen.],
  [Paradigma, Methodologie, Methode und Instrument sind vier Ebenen; ein Prompt für ein Sprachmodell ist ein Instrument und muss validiert werden.],
  [Das Design folgt aus der Aussage, die du machen willst; ein Modellvergleich auf einem Benchmark ist ein (Quasi-)Experiment.],
  [Ein Test produziert Fehlalarme und Übersehenes; der p-Wert sagt weder, wie wahrscheinlich die Hypothese stimmt, noch wie groß der Effekt ist.],
  [Cohen's d misst den Abstand zweier Gruppen in Einheiten ihrer Streuung; 0,2, 0,5 und 0,8 sind Standardwerte, keine Fachgrenzen; plane die Stichprobe vorab mit statsmodels.],
  [Flexible Auswertung und Data Leakage lassen Zufall wie einen Befund aussehen; Gegenmittel sind Preregistration, Multiverse und saubere Pipelines.],
  [Qualitätskriterien folgen dem Paradigma, jede ungelöste Bedrohung wird zur ehrlich genannten Limitation.],
)

#selbsttest(
  ([Wie unterscheiden sich Methodologie und Methode, und auf welcher Ebene liegt ein Prompt für ein Sprachmodell?], [Die Methodologie ist die Gesamtlogik von der Frage zu den Daten (z. B. Fallstudie), die Methode die Technik des Erhebens und Auswertens (z. B. Interviews). Ein Prompt ist ein Instrument, also die konkrete Ausführung.]),
  ([Was bedeuten Fehler 1. und 2. Art, und was ist power?], [Fehler 1. Art ist ein Fehlalarm, Fehler 2. Art ein Übersehen. Die power ist die Chance, einen echten Effekt zu entdecken, üblicherweise 80~%.]),
  ([Eine Studie meldet "p = 0,03". Was weißt du damit, und was nicht?], [Du weißt, dass die Daten schlecht zu "nichts los" passen. Du weißt nicht, wie wahrscheinlich die Hypothese stimmt, wie groß der Effekt ist und ob er wichtig ist.]),
  ([Zehn Prompt-Varianten werden gegen eine Basis getestet, nur die beste wird berichtet. Warum ist das ein Problem?], [Mit zehn Tests schlägt bei reinem Zufall in gut 40~% der Fälle mindestens einer an; Bonferroni wäre die Schwelle von 5~% geteilt durch zehn, besser ist ein Plan vorab.]),
  ([Warum kann ein Ergebnis von 0,85 Genauigkeit auf Zufallsdaten entstehen?], [Wenn die Merkmalsauswahl vor der Aufteilung in Training und Test alle Labels gesehen hat (Leakage). Mit einer Pipeline, die in jedem Durchlauf neu auswählt, liegt der Wert bei etwa 0,48.]),
)

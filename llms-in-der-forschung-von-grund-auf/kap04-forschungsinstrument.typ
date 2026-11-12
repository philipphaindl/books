#import "lib.typ": *

= LLMs als Forschungsinstrument

Stell dir vor, du bittest ein Sprachmodell: "Beantworte diesen Fragebogen als 45-jährige Krankenpflegerin aus dem ländlichen Ohio." Nach einer Sekunde hast du eine plausible Antwort. Wiederholst du das tausendmal mit tausend verschiedenen Personenbeschreibungen, liegt ein Datensatz vor, der aussieht wie eine Umfrage. Er hat nichts gekostet, keine Probandin musste gefunden werden, und er ist am selben Nachmittag fertig. Genau das tun immer mehr Forschende: Sie lassen Modelle Umfragen beantworten, klassische Experimente "durchlaufen" und sogar ganze Forschungsarbeiten schreiben.

Die Frage ist, ob du aus so einem Datensatz etwas lernen darfst. Manchmal ja: GPT-4 sagte in einer großen Studie voraus, wie stark Behandlungen in Umfrageexperimenten wirken, und lag damit erstaunlich oft richtig. Manchmal nein: In einer anderen Studie stimmten die Durchschnitte der künstlichen Befragten, aber fast die Hälfte der Zusammenhänge zwischen den Antworten war falsch. Beides stimmt gleichzeitig, und das ist der Kern dieses Kapitels.

Seine Leitidee lautet: *Die Ausgabe eines Sprachmodells ist eine Messung, und ein Modell, das Befragte spielt, ist ein Messgerät.* Ein Messgerät vertraut man nicht, weil es teuer oder klug aussieht, sondern weil man es geprüft hat. Wie man das prüft, ist der rote Faden der folgenden Abschnitte. Die Werkzeuge dafür kommen aus der klassischen Messlehre und sind einfacher, als der Name klingt. Der Foliensatz 04 folgt derselben Reihenfolge.

#lernziele[
  Du kannst vier Arten erklären, ein Sprachmodell als Versuchsperson einzusetzen (_silicon sample_, _Turing experiment_, _generative agent_, _foundation model of cognition_), und ein Paper einer davon zuordnen.
][
  Du kannst beschreiben, was ein Messgerät zuverlässig und gültig macht, und beides auf ein LLM übertragen.
][
  Du kannst erklären, warum richtige Durchschnitte nicht reichen, und eine künstliche Stichprobe auf drei Ebenen prüfen: Durchschnitte, Zusammenhänge, Effekte.
][
  Du kannst den Alignment-Score in eigenen Worten erklären, ein Beispiel von Hand durchrechnen und ihn mit einer Zeile Python berechnen.
][
  Du kannst die typischen Störfaktoren benennen (Prompt-Wortlaut, Trainingsdaten, Modellversion, Antwortreihenfolge) und eine Studie gegen die Checkliste GUIDE-LLM prüfen.
]

== Vier Rollen: Versprechen und Warnung

Messeri und Crockett unterscheiden vier Rollen, die KI in der Forschung spielen kann @messeri2024artificial. Das *Orakel* durchsucht Literatur und schlägt Hypothesen vor. Der *Quant* wertet Daten in großem Maßstab aus (Kapitel 5 und 6). Der *Schiedsrichter* begutachtet Arbeiten. Das *Surrogat* ersetzt Daten, etwa durch simulierte Versuchspersonen. Dieses Kapitel handelt vor allem vom Surrogat, in einem Abschnitt auch von Orakel und Schiedsrichter. Die beiden Autorinnen warnen vor drei Täuschungen: Man hält das Modell für erklärender, für breiter und für objektiver, als es ist. Am Ende droht eine "Monokultur des Wissens", in der alle dieselben Antworten bekommen.

Zu den Zahlen: Eine Korrelation von 0.85 heißt: Wenn der echte Effekt größer ist, ist auch die Vorhersage größer. 1 wäre perfekte Übereinstimmung, 0 gar kein Zusammenhang (siehe _Das Nötigste vorab_). In @k04-tab-versprechen stehen Zahlen, die sich scheinbar widersprechen. Sie zeigen, dass die Frage "Funktioniert das?" falsch gestellt ist. Richtig ist: *Wofür* funktioniert es, und woran erkenne ich das?

#figure(
  table(columns: (1fr, 1fr),
    [Versprechen], [Warnung],
    [GPT-4 sagte Effekte von Umfrageexperimenten mit einer Korrelation von 0.85 zu den echten Effekten voraus (Preprint, also Vorabfassung vor der Begutachtung, 2024) @hewitt2024predicting], [48 % der Zusammenhänge in synthetischen Daten wichen von den menschlichen Daten ab @bisbee2024synthetic],
    [GPT-3.5 lag bei Moralurteilen mit einer Korrelation von 0.95 an den Durchschnitten von Menschen @dillion2023can], [Digitale Zwillinge verfehlten Umfragen des Pew Research Center um rund 12 Prozentpunkte @chapekis2026can],
    [Agenten, die auf zweistündigen Interviews beruhten, erreichten 83 % der Konsistenz, mit der Menschen sich selbst nach zwei Wochen wiederholen @park2024llm], [GPT-4o erfand in 78 bis 90 % der Fälle Quellenangaben @asai2026synthesizing],
  ),
  caption: [Dieselbe Technik, gegensätzliche Schlagzeilen. Beide Spalten stammen aus begutachteten oder institutionellen Quellen (Stand: 11. November 2026).],
) <k04-tab-versprechen>

== Die Ausgabe eines LLM ist eine Messung

Wenn ein Modell im Namen einer Persona antwortet, beobachtest du keinen Menschen. Du erhältst eine Zahl oder einen Text, den ein technisches System aus einer Eingabe erzeugt hat. Diese Zahl soll etwas über Menschen aussagen, zum Beispiel, wie verbreitet eine Meinung ist. Damit spielt das Modell genau die Rolle eines Messgeräts, wie ein Fragebogen oder ein Thermometer.

#alltag[Fitness lässt sich nicht direkt sehen. Du musst sie erst festlegen (zum Beispiel: Ruhepuls und Zeit für fünf Kilometer), dann ein Gerät wählen (Fitnessuhr) und es benutzen. Erst danach hast du Zahlen. Bei jedem dieser Schritte kann etwas schiefgehen, und der Wert auf der Uhr sagt dir nicht, ob die Festlegung sinnvoll war.]

Wallach und Kolleginnen beschreiben diese Kette für KI-Bewertungen in vier Stufen @wallach2025position, die auf Jacobs und Wallach @jacobs2021measurement aufbauen. @k04-fig-messkette zeigt sie für einen Simulator, der die Meinung der US-Bevölkerung zu einem Thema messen soll. Der Pfeil nach unten ist der wichtigste: Man prüft laufend, ob die Zahl am Ende noch bedeutet, was man behauptet.

#figure(
  {
    set text(font: "Inter", size: 7.6pt, hyphenate: false)
    diagram(spacing: (8mm, 9mm), edge-stroke: 0.8pt + c-dark, mark-scale: 70%,
      fknoten((0, 0), [*1. Konzept* \ Meinung zu Thema X], col: c-blue, filled: true, w: 32mm),
      fknoten((1, 0), [*2. Festlegung* \ Fragetext, Skala, Zielgruppe], col: c-blue, w: 32mm),
      fknoten((2, 0), [*3. Messgerät* \ Modell, Persona, Einstellungen, Parser], col: c-accent, w: 32mm),
      fknoten((3, 0), [*4. Messwerte* \ künstliche Antworten], col: c-blue, filled: true, w: 32mm),
      edge((0, 0), (1, 0), "-|>"),
      edge((1, 0), (2, 0), "-|>"),
      edge((2, 0), (3, 0), "-|>"),
      fknoten((1.5, 1), [*Prüfen:* Bedeutet die Zahl noch, was wir behaupten?], col: c-red, w: 84mm),
      edge((3, 0), (1.5, 1), "-|>", stroke: (paint: c-red, thickness: 0.8pt, dash: "dashed")),
      edge((1.5, 1), (0, 0), "-|>", stroke: (paint: c-red, thickness: 0.8pt, dash: "dashed")),
    )
  },
  caption: [Von der Idee zur Messung nach Wallach et al. @wallach2025position, angewandt auf einen LLM-Simulator.],
) <k04-fig-messkette>

=== Was genau ist das Messgerät?

Das Messgerät ist *nicht* "das Modell". Es besteht aus vier Teilen: einer bestimmten Modellversion (dem _snapshot_), der Vorlage, aus der der Persona-Prompt entsteht, den Einstellungen wie der Temperatur (sie bestimmt, wie stark die Antworten streuen) und dem Programm, das aus dem Antworttext eine Zahl oder Kategorie macht (dem _parser_). Änderst du eines davon, hast du ein anderes Messgerät. "Wir haben GPT verwendet" sagt deshalb ungefähr so viel wie "wir haben einen Computer verwendet" @haindl2027research.

#merke[Berichte immer alle vier Teile: Modellversion, Prompt-Vorlage, Einstellungen, Parser. Ohne sie kann niemand deine Messung wiederholen.]

== Zuverlässig und gültig

Zwei Eigenschaften entscheiden über die Qualität jedes Messgeräts. Sie heißen *Reliabilität* (_reliability_, Zuverlässigkeit) und *Validität* (_validity_, Gültigkeit).

#alltag[Du stellst dich dreimal hintereinander auf die Badezimmerwaage: 70.1, 70.0, 70.2 Kilo. Die Waage ist *zuverlässig*, denn sie liefert immer fast dasselbe. Zeigt sie aber immer 3 Kilo zu wenig an, ist sie nicht *gültig*, denn die Zahl bedeutet nicht, was sie vorgibt. Und ein Thermometer ist ein gültiges Maß für Temperatur, aber ein ungültiges für Gesundheit. Zuverlässig kann ein Gerät also sein, ohne etwas Brauchbares zu messen.]

*Zuverlässigkeit* prüfst du, indem du dasselbe noch einmal misst (_test-retest_). Bei einem LLM gibt es drei Arten von "noch einmal": eine neue Sitzung mit gleichem Prompt, eine andere Modellversion oder Tageszeit und eine andere Formulierung desselben Prompts @mangiaterra2025can @bisbee2024synthetic. Eine Obergrenze gibt es auch: Menschen antworten nach zwei Wochen selbst nicht ganz gleich. Kein Simulator kann eine Person besser vorhersagen, als sie sich selbst wiederholt @park2024llm.

*Gültigkeit* ist keine Ja-Nein-Frage, sondern eine Frage des Grades. Man sammelt Belege, dass die Zahl bedeutet, was man behauptet @messick1995validity. Die Belege haben Namen, die du in Papern wiederfindest. @k04-tab-validitaet übersetzt sie in Fragen an einen Simulator.

#figure(
  table(columns: (auto, 1fr, 1.3fr),
    [Beleg], [Frage an den Simulator], [Beispiel aus der Literatur],
    [*Convergent* (konvergent)], [Stimmt er mit Menschen überein?], [OpinionQA-Alignment @santurkar2023whose; Pew-Vergleich @chapekis2026can],
    [*Discriminant* (diskriminant)], [Erfindet er Zusammenhänge, die es nicht gibt?], [3 von 10 Zusammenhängen, die es bei Menschen nicht gibt, wurden fälschlich signifikant @lukauskas2026plausible],
    [*Predictive* (prädiktiv)], [Sagt er echte Ergebnisse vorher?], [GPT-4o-Vertrautheitswerte sagen Lesezeiten ähnlich gut vorher wie menschliche Werte @mangiaterra2025can],
    [*Hypothesis* (Hypothesen)], [Bildet er bekannte Effekte und bekannte Nicht-Effekte ab?], [In 68 bis 83 % der Studien, die ursprünglich keinen Effekt fanden, "fand" das Modell einen @cui2024can],
    [*Consequential* (Folgen)], [Schadet er den dargestellten Gruppen?], [Fehldarstellung und Abflachung von Identitätsgruppen @wang2025large],
  ),
  caption: [Fünf Belege für Gültigkeit, als Fragen an einen LLM-Simulator. Dazu kommt die Frage, ob das Gerät in allen Gruppen dasselbe bedeutet (_measurement invariance_).],
) <k04-tab-validitaet>

Die meisten Paper liefern nur die erste Zeile. Die anderen vier sind genau die Stellen, an denen Simulatoren scheitern.

#studie(titel: [Mangiaterra et al., 2025])[
  *Was gemacht wurde:* Drei GPT-Modelle bewerteten 687 Metaphern (469 italienisch, 218 englisch), zum Beispiel wie vertraut sie sind. Statt eine Zahl als Text zu parsen, lasen die Forschenden die Wahrscheinlichkeiten der drei wahrscheinlichsten Ziffern aus und bildeten einen gewichteten Mittelwert. *Was herauskam:* Die Bewertungen der Verständlichkeit (englisch) korrelierten mit 0.69 bis 0.79 mit denen von Menschen. Über die API bei Temperatur 0 stimmten wiederholte Läufe zu 0.97 bis 0.99 überein, über die ChatGPT-Oberfläche nur zu 0.66 bis 0.91. Nur 364 der 687 Metaphern stammten aus Quellen, die vor dem Trainingsende des Modells nicht online waren @mangiaterra2025can. *Was es heißt:* Derselbe Modellname über einen anderen Zugang ist ein anderes Messgerät.
]

#beispiel(titel: [Ein Rating aus Wahrscheinlichkeiten])[
  Ein Modell soll auf einer Skala von 1 bis 7 bewerten, wie vertraut eine Metapher ist. Es gibt der Ziffer 5 eine Wahrscheinlichkeit von 60 %, der 4 von 30 % und der 6 von 5 %. Du nimmst jede Ziffer mal ihre Wahrscheinlichkeit: 5 mal 0.60 = 3.00, 4 mal 0.30 = 1.20, 6 mal 0.05 = 0.30. Das ergibt zusammen 4.50. Weil die drei Wahrscheinlichkeiten zusammen nur 95 % ergeben, teilst du durch 0.95. Das Rating ist 4.74. Es liegt zwischen den Kategorien, und bei Temperatur 0 kommt jedes Mal dasselbe heraus.
]

== Silicon Samples: künstliche Befragte

Argyle und Kolleginnen legten 2023 den Grundstein @argyle2023out. Für jede reale Person einer Umfrage bauten sie aus ihrem Profil eine Hintergrundgeschichte in der ersten Person (Alter, Geschlecht, Partei, Wohnort) und ließen GPT-3 sie fortsetzen, zum Beispiel: "...In 2016, I voted for". Pro echter Person entsteht so ein künstlicher Zwilling. Die Gesamtheit heißt *silicon sample*. @k04-fig-pipeline zeigt den Ablauf.

#figure(
  {
    set text(font: "Inter", size: 7.4pt, hyphenate: false)
    diagram(spacing: (4mm, 8mm), edge-stroke: 0.8pt + c-dark, mark-scale: 70%,
      fknoten((0, 0), [Profil einer echten Person], col: c-blue, filled: true, w: 28mm),
      fknoten((1, 0), [Hintergrund-geschichte plus Frage], col: c-blue, w: 28mm),
      fknoten((2, 0), [Sprachmodell antwortet], col: c-accent, filled: true, w: 28mm),
      fknoten((3, 0), [Parser macht eine Zahl daraus], col: c-blue, w: 28mm),
      fknoten((4, 0), [Vergleich mit den echten Antworten], col: c-teal, filled: true, w: 28mm),
      edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"), edge((3, 0), (4, 0), "-|>"),
    )
  },
  caption: [Ablauf eines Silicon Samples. Jeder Schritt gehört zum Messgerät; geprüft wird gegen die echten Antworten derselben Personen.],
) <k04-fig-pipeline>

Argyle et al. nennen ihr Ziel *algorithmic fidelity* (algorithmische Treue): Das Modell soll die Antwortmuster vieler Gruppen getreu abbilden. Vier Kriterien füllen den Begriff. Die Antworten sollen von echten Texten nicht zu unterscheiden sein (_Turing-Test_), zur Person passen (_backward continuity_), zum Prompt passen (_forward continuity_) und dieselben Zusammenhänge zeigen wie echte Daten (_pattern correspondence_). Die ersten drei prüfen, ob eine einzelne Antwort glaubwürdig klingt. Nur das vierte erlaubt Schlüsse aus Daten, und genau das fällt am häufigsten durch.

In der Studie sah es zunächst gut aus: Beurteiler hielten 61.2 % der Wortlisten des Modells für menschlich (bei echten Listen: 61.7 %). Die Wahl bei den US-Präsidentschaftswahlen stimmte gut mit der echten überein (Korrelation 0.90 bis 0.94). Doch bei Wählerinnen und Wählern ohne Parteibindung lag der Wert 2020 bei nur 0.02. Der Durchschnitt verbarg eine Gruppe, in der der Zwilling nicht besser war als Raten @argyle2023out.

#studie(titel: [Bisbee et al., 2024])[
  *Was gemacht wurde:* ChatGPT 3.5 erzeugte aus echten Befragten der US-Wahlstudie ANES von 2016 und 2020 je 30 künstliche Zwillinge, insgesamt gut 3.6 Millionen Antworten, und die Daten wurden auf vier Ebenen mit den echten verglichen @bisbee2024synthetic. *Was herauskam:* Die *Durchschnitte* lagen jeweils innerhalb der typischen Streuung der echten Antworten. Die *Streuung* war viel kleiner, die *Abstände zwischen den Gruppen* waren um 10 bis 20 Punkte übertrieben. Bei den *Zusammenhängen* (technisch: Regressionskoeffizienten, also wie stark und in welche Richtung eine Größe eine andere beeinflusst) wichen 48 % signifikant, also über den Zufall hinaus, von den echten ab, bei etwa einem Drittel davon in die Gegenrichtung. *Was es heißt:* Wer nur Durchschnitte prüft, hat nur Durchschnitte geprüft.
]

#alltag[Ein Klassenfoto, auf dem alle im Schnitt genau so groß sind wie die echte Klasse, aber alle Kinder fast gleich groß. Der Durchschnitt stimmt, die Klasse nicht.]

=== Wie viele Leute brauche ich? Ein Warnbeispiel

Eine harmlos wirkende Nutzung zeigt, wie teuer falsche Streuung werden kann: die Planung einer echten Studie anhand künstlicher Pilotdaten. Die Frage lautet: Wie viele Personen brauche ich, damit ein echter Unterschied zwischen zwei Gruppen eine gute Chance hat, aufzufallen (_power analysis_)? Das hängt vom Abstand der Gruppen ab und davon, wie stark die Antworten innerhalb jeder Gruppe streuen. Die künstlichen Daten hatten die halbe Streuung und einen 1.5-mal so großen Abstand. Der Abstand wirkt dadurch dreimal so deutlich, und die nötige Zahl schrumpft mit dem Quadrat davon: 3 mal 3 sind 9, also nur ein Neuntel. Bei Bisbee et al. brauchte man laut Tabelle mit den künstlichen Daten 35 Parteianhänger statt 299 (der Fließtext nennt 33).

#figure(
  balken((([Echte Daten (ANES)], 299), ([Künstliche Daten], 35)), max: 300, breite: 8, farbe: c-accent, nachkomma: 0),
  caption: [Befragte, die man für eine 99-prozentige Chance braucht, den Abstand zwischen Parteianhängern zu entdecken @bisbee2024synthetic. Wer mit dem rechten Balken plant, rekrutiert viel zu wenige Leute.],
)

== Antwortmuster vergleichen

Santurkar et al. fragten umgekehrt: Wessen Meinung spiegeln Sprachmodelle von sich aus? Sie bauten den Datensatz *OpinionQA* aus 1~498 Fragen der Pew-Panelumfragen 2017 bis 2021, deren echte Antwortmuster für die US-Bevölkerung und 60 Gruppen bekannt sind, und prüften neun Modelle @santurkar2023whose. Das Ergebnis: Jede der 60 menschlichen Gruppen repräsentiert die US-Bevölkerung besser als jedes Modell. Basismodelle (nur auf Textvorhersage trainiert) ähneln eher Gruppen mit niedrigerem Einkommen, mäßigen Ansichten und starker Religiosität, die OpenAI-Modelle eher gebildeten, liberalen Gruppen mit hohem Einkommen. Schlecht abgebildet sind zum Beispiel Menschen über 65. Und einige Modelle legen bei den meisten Fragen mehr als 99 % ihrer Wahrscheinlichkeit auf eine einzige Antwort: ein *modal collapse*, ein Modell, das fast alles auf die häufigste Antwort setzt.

Um "wie ähnlich ist das Antwortmuster" in eine Zahl zu fassen, brauchst du den Alignment-Score (_representativeness score_).

#alltag[Zwei Sandhaufen liegen auf vier Feldern, die für die Antwortmöglichkeiten stehen: der eine zeigt, wie Menschen antworten, der andere, wie das Modell. Wie viel Sand musst du wie weit tragen, damit aus dem einen der andere wird? Wenig Tragen heißt: ähnlich. Fachlich ist das die _Wasserstein-Distanz_.]

*Wie liest man den Wert?* Er liegt zwischen 0 und 1. 1 bedeutet identische Antwortmuster, 0 das größtmögliche Auseinanderliegen. Das Ergebnis eines Modells mittelt man über viele Fragen.

#beispiel(titel: [Ein Modell ohne Streuung])[
  Eine Frage hat vier Antwortmöglichkeiten. Menschen antworten zu 10, 20, 40 und 30 %. Das Modell nahezu immer die dritte: 0, 5, 90 und 5 %. Du gehst die Skala von links nach rechts durch und zählst die laufenden Summen: Menschen 10, 30, 70 %; Modell 0, 5, 95 %. Der Abstand an den drei Schritten ist 10, 25 und 25 Prozentpunkte, zusammen 60 Punkte oder 0.60. Der schlimmste Fall wäre 3 (alles müsste über alle drei Schritte wandern). 0.60 von 3 sind 20 %, der Score also 1 minus 0.20 = *0.80*. Das Modell trifft die Spitze, hat aber fast keine Streuung, und bekommt trotzdem 0.80 (@k04-fig-kollaps).
]

#figure(
  {
    cetz.canvas(length: 1cm, {
      import cetz.draw: *
      let h = (0.10, 0.20, 0.40, 0.30)
      let m = (0.0, 0.05, 0.90, 0.05)
      let hh = 3.2
      for (i, lab) in ([1], [2], [3], [4]).enumerate() {
        let x = i * 2.3
        rect((x, 0), (x + 0.8, h.at(i) * hh), fill: c-blue.lighten(10%), stroke: none)
        rect((x + 0.8, 0), (x + 1.6, m.at(i) * hh), fill: c-accent, stroke: none)
        content((x + 0.4, h.at(i) * hh + 0.25), text(font: "Inter", size: 7pt, [#calc.round(h.at(i) * 100) %]))
        content((x + 1.2, m.at(i) * hh + 0.25), text(font: "Inter", size: 7pt, weight: "bold", [#calc.round(m.at(i) * 100) %]))
        content((x + 0.8, -0.3), text(font: "Inter", size: 7.5pt, lab))
      }
      line((0, 0), (9.0, 0), stroke: 0.8pt + c-dark)
      rect((9.6, 2.9), (10.0, 3.2), fill: c-blue.lighten(10%), stroke: none)
      content((10.15, 3.05), anchor: "west", text(font: "Inter", size: 7.5pt)[Menschen])
      rect((9.6, 2.3), (10.0, 2.6), fill: c-accent, stroke: none)
      content((10.15, 2.45), anchor: "west", text(font: "Inter", size: 7.5pt)[Modell])
    })
  },
  caption: [Das Beispiel als Diagramm: gleiche Frage, vier Antwortmöglichkeiten (Anteil der Antworten in Prozent). Das Modell hat die richtige Spitze, aber keine Streuung.],
) <k04-fig-kollaps>

*Wie bekommt man den Wert praktisch?* Mit einem Aufruf aus SciPy. Die Funktion `wasserstein_distance` rechnet die Wanderung des Sandes; du teilst das Ergebnis durch die Zahl der Schritte.

#block(breakable: false)[
#datei("alignment.py")[
```python
import numpy as np
from scipy.stats import wasserstein_distance

def alignment(p_model, p_human):
    n = len(p_human)                  # Zahl der Antwortmöglichkeiten
    s = np.arange(1, n + 1)           # Positionen 1 ... n
    wd = wasserstein_distance(s, s,
        u_weights=p_model, v_weights=p_human)
    return 1 - wd / (n - 1)           # n - 1 = größtmöglicher Weg

print(alignment([0, .05, .90, .05], [.10, .20, .40, .30]))
```
]

```out
0.8
```
]

#fallstrick[Ein Wert von 0.8 sieht gut aus, beweist aber nichts. Der Score belohnt die richtige Lage und übersieht, dass die Streuung fehlt. Berichte deshalb immer auch ein Maß für die Streuung, etwa die Entropie (wie breit die Antworten verteilt sind; 0 bedeutet: alle wählen dieselbe Option).]

=== Abflachung, Fehldarstellung und der Stand 2026

Wang, Morgenstern und Dickerson untersuchten Identitätsgruppen mit rund 3~200 Prolific-Teilnehmenden (einer Online-Plattform für Studienteilnehmende), 16 Identitäten und vier Modellen @wang2025large. Sie fanden zwei Schäden. *Fehldarstellung* (_misportrayal_): Die Antworten klingen mehr nach dem Bild, das Außenstehende von einer Gruppe haben, als nach dem, was Mitglieder sagen. *Abflachung* (_flattening_): Die Antworten sind weniger vielfältig als menschliche. GPT-4 und GPT-3.5 deckten von fünf Antwortoptionen nur etwa drei ab. Höhere Temperatur bringt mehr Vielfalt, aber GPT-4 wurde bei 1.4 unsinnig.

#alltag[Eine Schauspielerin spielt eine Gruppe, über die sie nur gelesen hat. Alle ihre Figuren klingen gleich (Abflachung), und sie klingen nach der Vorstellung von Außenstehenden (Fehldarstellung).]

Man könnte hoffen, neuere Modelle hätten das behoben. Drei Studien aus 2026 sagen Nein: Der Pew-Bericht kam mit Claude Opus 4.6 auf rund 12 Prozentpunkte durchschnittlichen Fehler, bei 28 % der Fragen sogar mehr als 15 Punkte daneben @chapekis2026can. Der Verasight-Test mit GPT-5.2 lag bei 14.5 Punkten Fehler @morris2026can. In Singapur behielt GPT-5.4 nur 23 bis 24 % der Streuung der echten Daten @lam2026conditional. Beide Berichte sind graue Literatur, also nicht begutachtet (Stand: 11. November 2026).

#hoersaal([Pew hat einen Fehler von 12 Punkten gemessen. Ist das für viele Zwecke nicht gut genug?], [Das hängt davon ab, was du behaupten willst. Für eine grobe Vorab-Einschätzung kann das reichen. Für eine veröffentlichte Aussage über die öffentliche Meinung nicht, denn die Fehler sind nicht zufällig, sondern systematisch (zum Beispiel Stereotype). Solche Fehler verschwinden nicht, wenn du mehr künstliche Befragte erzeugst @chapekis2026can.])

== Experimente simulieren

Silicon Samples beantworten Fragebögen. Der nächste Schritt setzt Modelle in Experimente. Der Foliensatz unterscheidet vier Bauarten: das *silicon sample*, das *Turing experiment* (eine repräsentative künstliche Stichprobe wiederholt eine klassische Studie), den *generative agent* (ein Modell mit Gedächtnis, Reflexion und Planung, das in einer simulierten Welt lebt) und das *foundation model of cognition* (ein Modell, das auf menschlichen Daten nachtrainiert wurde). Nur die letzte Bauart wird auf menschlichen Daten feintrainiert, die anderen drei werden nur geprompt.

Aher et al. ließen acht OpenAI-Modelle vier klassische Studien nachspielen, darunter das Milgram-Experiment (Gehorsam gegenüber Anweisungen zu Elektroschocks): 75 von 100 künstlichen Teilnehmenden gingen bis zum Ende der Schockserie, im Original waren es 26 von 40. Beim *Wisdom of Crowds* (viele Schätzungen werden gemittelt) nannten ChatGPT und GPT-4 jedes Mal den exakt richtigen Wert, ohne die Streuung einer echten Menge. Das ist *Hyper-Genauigkeit*: Ausgerichtete Modelle wissen die Antwort zu gut, um Fehler von Menschen nachzuahmen @aher2023using. Berühmte Studien liegen zudem sehr wahrscheinlich in den Trainingsdaten.

Die Generative Agents von Park et al. wurden von Menschen auf Glaubwürdigkeit bewertet und dabei sogar höher eingestuft als menschliche Crowdworker (Bewertungszahl TrueSkill 29.89 gegen 22.95) @park2023generative. Das misst, wie plausibel Verhalten wirkt, nicht, ob es echtem Verhalten entspricht. *Glaubwürdigkeit ist keine Gültigkeit.*

=== Effekte vorhersagen

Die bisher stärkste positive Evidenz stammt aus einer Studie, die keine einzelnen Antworten, sondern *Effekte* vorhersagt. Ein *Effekt* ist hier der Unterschied zwischen zwei Gruppen: 54 % Zustimmung nach einem Text gegen 50 % in der Vergleichsgruppe sind ein Effekt von 4 Prozentpunkten.

#studie(titel: [Hewitt et al., 2024 (Preprint) und Nature 2026])[
  *Was gemacht wurde:* GPT-4 simulierte Teilnehmende für 70 vorab registrierte US-Umfrageexperimente und sagte die Größe jedes Effekts voraus. Die Fassung in _Nature_ nennt 469 Effekte und 119~330 Teilnehmende @ashokkumar2026large; alle Zahlen hier stammen aus dem Preprint von 2024, weil der veröffentlichte Volltext noch nicht geprüft ist @hewitt2024predicting. *Was herauskam:* Die Vorhersagen korrelierten mit 0.85 mit den echten Effekten (Laien als Prognostiker: 0.79; GPT-4 plus Menschen: 0.88). Bei unveröffentlichten Studien lag der Wert bei 0.90, bei veröffentlichten bei 0.74. *Was es heißt:* Richtung und Rangfolge aggregierter Effekte trifft das Modell gut. Der bessere Wert bei unveröffentlichten Studien spricht gegen reines Auswendiglernen, schließt Kontamination aber nicht aus.
]

Die Stärke hat Grenzen. Je weiter man sich von einfachen Umfrageexperimenten entfernt, desto schwächer wird die Vorhersage (@k04-fig-hewitt). Außerdem überschätzt das Modell die Größen: Der typische Fehler lag bei 10.9 Prozentpunkten, bei Laien-Prognostikern bei 8.4.

#figure(
  balken((([Haupteffekte], 0.85), ([Umfrage-Megastudien], 0.47), ([Feldexperimente], 0.27), ([Wechselwirkungen (höchster Wert)], 0.16)), max: 1, breite: 7.5, farbe: c-teal),
  caption: [Korrelation zwischen vorhergesagten und echten Effekten, je nach Art der Aufgabe (Preprint 2024 @hewitt2024predicting). Je weiter von textbasierten Umfrageexperimenten entfernt, desto schwächer.],
) <k04-fig-hewitt>

#beispiel(titel: [Effekte umskalieren])[
  Das echte Experiment zeigt 54 % gegen 50 %, einen Effekt von 4 Punkten. Die Simulation sagt 9 Punkte voraus und liegt 5 Punkte daneben. Aus anderen Studien weiß man, dass die Modell-Effekte um einen festen Faktor zu groß sind (der Wert aus dem Preprint ist 0.56). 9 mal 0.56 ergibt etwa 5, der Fehler schrumpft auf 1 Punkt (die Zahlen sind ausgedacht, der Faktor 0.56 stammt aus dem Preprint). Der Faktor muss aus anderen Studien kommen. Stellst du ihn an denselben Studien ein, an denen du danach den Fehler misst, ist die Prüfung wertlos.
]

=== Realismus ist nicht Effektgenauigkeit

Li und Ji prüften, ob eine Simulation, die einzelne Antworten gut trifft, auch die Effekte trifft @li2026statistical. Ihre Antwort ist Nein. Der Fehler der Einzelantworten war nur das 1.07-fache einfacher statistischer Modelle, der Fehler der Effekte aber das 2.10-fache. Der Prompt mit den besten Einzelantworten machte die Effekte in 8 von 9 Fällen schlechter, und über Länder hinweg gab es kaum einen Zusammenhang zwischen beiden Fehlern (Korrelation 0.10). Getestet wurden nur kleine Modelle, was die Übertragbarkeit begrenzt.

#alltag[Ein Flugsimulator, dessen Cockpit täuschend echt aussieht, dessen Flugzeug sich aber falsch verhält. Wer nur das Aussehen prüft, übersieht den Fehler, auf den es ankommt.]

Das Prinzip: Validiere die Größe, die dein Paper berichtet. Eine ähnliche Unterscheidung macht *HumanStudy-Bench* mit zwei Werten, die du in Papern findest: der *PAS* fragt, ob ein Effekt überhaupt vorhanden ist (bester Wert 0.53), der *ECS*, ob seine Größe stimmt (bester Wert 0.265, bei einer menschlichen Obergrenze von etwa 0.93) @liu2026humanstudy.

=== Digitale Zwillinge, Centaur und Feintraining

Es gibt auch Wege, auf denen Simulation besser funktioniert. Park et al. bauten Agenten aus zweistündigen Interviews mit 1~052 Menschen @park2024llm. Als Maß dient die *normalisierte Genauigkeit*: Wie genau der Agent die Antworten einer Person trifft, geteilt durch die Genauigkeit, mit der die Person sich nach zwei Wochen selbst wiederholt. Das ist wie ein Prüfungsergebnis im Vergleich zum Ergebnis derselben Person bei der Wiederholungsprüfung. Im General Social Survey trafen die Agenten 65.67 %, die Menschen sich selbst 79.53 %. 65.67 geteilt durch 79.53 ist etwa 0.83. Interview-Agenten kamen so auf 0.83, Agenten mit Interview plus Fragebogen auf 0.86, reine Persona-Agenten auf 0.71. Die Lücken zwischen Gruppen schrumpften, blieben aber bestehen.

Binz et al. trainierten Llama 3.1 70B auf 160 Psychologie-Experimenten mit 60~092 Menschen nach (*Centaur*) @binz2025foundation. Die Güte wird mit der *negative log-likelihood* gemessen: Sie sagt, wie überrascht das Modell von dem war, was Menschen tatsächlich wählten, und niedriger ist besser. Bei unbekannten Teilnehmenden war Centaur weniger überrascht (0.44) als klassische kognitive Modelle (0.56) und das Ausgangsmodell (0.58). Daten und die nachtrainierten Zusatzgewichte sind frei verfügbar, die Version lässt sich also festhalten.

Auch das Nachtrainieren (_fine-tuning_) auf echten Umfragedaten hilft. Das Modell von Suh et al. kam bei Meinungsverteilungen auf eine Distanz von 0.094 zu den Menschen, deutlich unter dem Wert 0.178 für gleichverteilte Antworten (jede Option gleich häufig), aber über der Untergrenze 0.031, die menschliche Wiederholungen erreichen @suh2025language. Kolluri et al. verbesserten Vorhersagen für ungesehene Experimente von 0.205 auf 0.151, besser als GPT-4o (0.174), aber über der Grenze von 0.125, die schon echte Menschen wegen der Zufallsauswahl nicht unterschreiten @kolluri2025finetuning. Keine der beiden Studien prüft Effektgrößen direkt.

Schröder et al. stellten dagegen einen Test auf Bedeutung vor. Sie formulierten 30 Moral-Szenarien so um, dass sich der *Sinn* änderte. Menschen änderten ihre Urteile deutlich (Korrelation zwischen Original und Umformulierung 0.54), GPT-4 kaum (0.99), Centaur dazwischen (0.83) @schroder2025large. Hohe Übereinstimmung mit bekannten Aufgaben beweist also nicht, dass das Modell die Bedeutung verarbeitet.

#hoersaal([Bedeutet gute Vorhersage, dass Centaur wie ein Mensch denkt?], [Nein. Gute Vorhersage ist ein Beleg über Verhalten, nicht über den Mechanismus dahinter. Hu et al. empfehlen, vorab zu entscheiden, ob du behauptest, Verhalten oder den Prozess zu treffen @hu2025reevaluating.])

== AI Scientists und Ideen

Bisher lieferte das Modell Daten über Menschen. Jetzt macht es selbst Forschung: Literatur suchen, Ideen finden, Experimente programmieren, Paper schreiben. Auch hier gilt die Messperspektive: Prüfe, ob das Bewertungskriterium wirklich trifft, worauf es ankommt.

*Ideen.* Si et al. ließen Fachleute KI-Ideen und menschliche Ideen blind bewerten @si2025can: Die KI-Ideen galten als neuer (Neuheit auf einer Skala von 1 bis 10: 5.64 gegen 4.84 bei menschlichen). In der Folgestudie setzten 43 Fachleute die Ideen tatsächlich um, jeweils mehr als 100 Stunden lang, und die KI-Ideen verloren auf allen vier Bewertungen signifikant mehr Punkte @si2025ideation (noch ein Preprint, Stand: 11. November 2026).

#alltag[Ein Rezept, das auf dem Papier brillant klingt, bis jemand es kocht. Die Bewertung der Idee war nur ein Stellvertreter für die Größe, auf die es ankommt: wie gut die Forschung wird, die daraus entsteht.]

*Ganze Paper.* Der AI Scientist erledigt Idee, Programmcode, Experimente, Text und eine automatische Begutachtung selbst und kostete in der ersten Version unter 15 US-Dollar pro Paper @lu2026towards. Drei Paper wurden bei einem Workshop eingereicht, eines erreichte 6.33 Punkte und wurde wie vereinbart zurückgezogen. Die Autoren sahen keines davon als reif für die Hauptkonferenz an. Ihre eigene Codeprüfung fand eine Überlappung von etwa 57 % zwischen Trainings- und Testdaten, die die automatischen Gutachter übersehen hatten. Das Bestehen einer Begutachtung ist daher ein schwacher Beleg für Qualität. Unabhängige Prüfungen bestätigen das: Beel et al. fanden bei 42 % der Experimente Programmierfehler @beel2025evaluating, bei der Konferenz Agents4Science, auf der KI-Agenten als Erstautoren einreichten, waren nur etwa 44 % der Einreichungen frei von erfundenen Quellen @bianchi2025exploring.

*Literatur und Hypothesen.* Reines GPT-4o erfindet Zitate in 78 bis 90 % der Fälle. OpenScholar sucht erst in 45 Millionen Open-Access-Papern und ist etwas korrekter @asai2026synthesizing. Bei der Datenextraktion für Literaturübersichten waren 83 % der gefundenen Angaben richtig (_precision_), und es wurden 86 % der vorhandenen gefunden (_recall_) @scherbakov2025emergence. Googles Co-Scientist schlug Wirkstoffe gegen Leukämie vor, im Labor geprüft: Ein externes Kriterium statt einer Bewertung @gottweis2026accelerating.

== Was die Ergebnisse verderben kann

Bisher ging es darum, wo Simulation am Ziel vorbeigeht. Hier geht es um Störfaktoren *im Messgerät selbst*. Stell dir ein Thermometer vor, dessen Anzeige sich mit dem Zimmer, der Marke oder einem Firmware-Update ändert.

Fünf Störfaktoren stehen in @k04-tab-stoer.

#figure(
  table(columns: (auto, 1fr, 1.2fr),
    [Störfaktor], [Was passiert], [Gegenmittel],
    [*Prompt sensitivity*], [Kleine Änderungen im Wortlaut ändern das Ergebnis], [Mehrere Formulierungen, alle berichten],
    [*Contamination*], [Die Testaufgabe stand im Training], [Ziele nach Datum aufteilen, Paraphrasen vergleichen, *canary* im Benchmark],
    [*Drift*], [Stille Modell-Updates, Abschaltung], [Version festhalten, Datum protokollieren, offene Gewichte bevorzugen],
    [*Interface effects*], [Chat-Oberfläche mit versteckten Prompts und Einstellungen], [API mit festen Parametern],
    [*Answer-order artefact*], [Die Reihenfolge der Optionen steuert die Antwort], [Optionen mischen, mit Zufallsantworten vergleichen],
  ),
  caption: [Fünf Störfaktoren des Messgeräts und was dagegen hilft.],
) <k04-tab-stoer>

*Prompt-Wortlaut.* Sclar et al. zeigten, dass allein die Formatierung die Genauigkeit im schlimmsten Fall um bis zu 76 Punkte verschieben kann, im Mittel etwa um zehn @Sclar2024. Mizrahi et al. fanden, dass die Rangfolge von 20 Modellen auf 39 Aufgaben kippen kann, je nachdem, welche Vorlage man nimmt @Mizrahi2024. Ein Ergebnis aus einem Prompt ist eine Stichprobe vom Umfang eins. Auch ob man auf Englisch oder in der Landessprache prompten sollte, ist eine Entwurfsentscheidung: Kwok et al. fanden, dass Prompten in der Landessprache die Übereinstimmung verschlechterte @kwok2024evaluating.

*Trainingsdaten.* Kontamination bedeutet: Das Modell hat die Prüfungsfragen vorher gesehen. Klassische Studien wie das Milgram-Experiment liegen sehr wahrscheinlich in den Trainingsdaten. Eine saubere Prüfung nimmt Studien, die nach dem Trainingsende des Modells entstanden. Bei Mangiaterra et al. kamen nur 364 von 687 Metaphern aus Quellen, die damals noch nicht online waren.

*Modellversion.* Bisbee et al. gaben denselben Prompt im April, Juni und Juli 2023 ein und bekamen unterschiedliche Antwortmuster, wahrscheinlich wegen des Updates vom 25. Juni 2023 @bisbee2024synthetic. Es ist, als würde jemand alle paar Wochen unbemerkt das Lineal austauschen. Temperatur nahe 0 hilft nur begrenzt: Sie zeigt nur einen Extremfall dessen, was das Modell kann. Führe jede Konfiguration mehrfach aus. Mehr dazu in Kapitel 10.

*Antwortreihenfolge.* Dominguez-Olmedo et al. prüften 43 Modelle mit 25 Fragen des American Community Survey und fanden einen starken "A"-Bias: Das Modell ticktet gern A, egal was dort steht. Nach dem Mischen der Optionen lag GPT-4 nur bei 6 von 25 Fragen näher an den Zensusdaten als an einer Gleichverteilung. Ein Klassifikator unterschied Modell- von Menschendaten zu über 90 % @dominguezolmedo2024questioning.

#tipp[Mische bei jedem Multiple-Choice-Experiment die Reihenfolge der Antworten, und vergleiche immer auch mit einer Zufalls-Basislinie. Eine "gute Übereinstimmung" mit einer Gruppe, die fast alles gleich wahrscheinlich beantwortet, ist nur ein Hinweis auf hohe Streuung.]

== Ersatz, Ergänzung oder keins von beiden?

Die Debatte hat drei Positionen. *Ersatz*: Künstliche Daten sind alleinige Evidenz. Das stützt keine hier besprochene Studie. *Ergänzung*: Simulation dient als Pilot, als Vorannahme oder zur Priorisierung, und Menschen bestätigen. Das vertreten Dillion et al. @dillion2023can, Horton et al. @horton2023large und Anthis et al. @anthis2025position. *Keins von beidem*: Jede Nutzung braucht ohnehin Menschen, so Harding et al. @harding2024ai und Lin @lin2025six, die auch sechs Denkfehler bei der Substitution von Teilnehmenden aufzählt.

Die Evidenz stützt eine *bedingte* Pro-Position. Simulation funktioniert bei aggregierten Effekten in textbasierten US-Umfrageexperimenten, bei interviewgestützten Agenten, bei Rating-Normen über die API und nach Feintraining auf Menschendaten. Gemeinsam sind: ein Mittelwert-artiges Ziel, eine Population mit menschlichen Daten und eine Prüfung auf zurückgehaltenen Menschendaten. Wechselwirkungen, Feldexperimente, Nicht-Effekte und ganz neue Aufgaben scheitern weiterhin.

Ob du ein geschlossenes oder ein offenes Modell nimmst, ist ein Zielkonflikt. Offene Gewichte (die frei herunterladbaren gelernten Zahlen eines Modells) lassen sich festhalten, wie bei Centaur. Geschlossene Modelle ändern sich oder verschwinden, daher sollst du ihre Nutzung begründen @palmer2024using @spirling2023why. Das stärkste Effektvorhersage-Modell war aber ein geschlossenes (GPT-4). Argumentiere pro Studie, nicht pauschal.

#figure(
  {
    set text(font: "Inter", size: 7.6pt, hyphenate: false)
    diagram(spacing: (5mm, 8mm), edge-stroke: 0.8pt + c-dark, mark-scale: 70%,
      fknoten((0, 0), [*Verteilungen* \ Durchschnitte, Streuung], col: c-blue, filled: true, w: 36mm),
      fknoten((1, 0), [*Zusammenhänge* \ Regressions-koeffizienten], col: c-blue, w: 36mm),
      fknoten((2, 0), [*Effekte* \ Behandlungs-effekte], col: c-blue, w: 36mm),
      fknoten((3, 0), [*Heterogenität* \ wer reagiert wie], col: c-accent, filled: true, w: 36mm),
      edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"),
    )
  },
  caption: [Validiere auf der Ebene deiner Aussage. Nach rechts wird es schwerer, und die letzte Ebene ist bisher ungelöst.],
)

=== Berichten: die GUIDE-LLM-Checkliste

Ein Validitätsargument nützt nur, wenn andere es prüfen können. Der Standard dafür heißt *GUIDE-LLM* @feuerriegel2026reporting @guidellm2026checklist. Er entstand in zwei vorab registrierten Delphi-Runden (Expertenbefragungen in mehreren Durchgängen): 68 Fachleute bewerteten 29 Kandidaten, 80 stimmten ab, aufgenommen wurde, was mehr als zwei Drittel Zustimmung bekam. Das Ergebnis sind 14 Kernpunkte in sieben Abschnitten (Anwendungsbereich 2, Modell und System 5, Prompts 2, Daten 1, Validierung 2, Code 1, Interessenkonflikte 1) und 8 optionale Punkte, zum Beispiel die Begründung der Modellwahl. Die Online-Checkliste liegt unter sfeuerriegel.github.io/llm-checklist (Stand: 11. November 2026). In diesem Kurs ist GUIDE-LLM für Studierendenprojekte verbindlich.

== In der Praxis: Eine Simulation sauber aufsetzen

So gehst du in einem eigenen Projekt vor. Der Ablauf ist derselbe, ob du Fragebögen oder Experimente simulierst.

+ *Aussage festlegen.* Was genau willst du behaupten: einen Durchschnitt, eine Verteilung, einen Zusammenhang oder einen Effekt? Das bestimmt, auf welcher Ebene du validierst.
+ *Messgerät beschreiben.* Modellversion, Prompt-Vorlage, Einstellungen und Parser festhalten, auch das Zugriffsdatum.
+ *Zuverlässigkeit prüfen.* Jede Konfiguration mehrfach laufen lassen, mehrere Formulierungen testen, Streuung berichten.
+ *Gegen Menschendaten prüfen.* Auf der Ebene der Aussage vergleichen, mit Maßen für Lage *und* Streuung, und Gruppen einzeln ansehen.
+ *Bekannte Nicht-Effekte einbauen* und Antwortreihenfolge mischen, damit du Scheineffekte und Reihenfolge-Bias findest.
+ *Kontamination bedenken.* Wenn möglich Aufgaben nach dem Trainingsende des Modells verwenden.
+ *Berichten.* Mit GUIDE-LLM, inklusive Instrumentenkarte (siehe unten).

#block(breakable: false)[
#datei("silicon_sample.py")[
```python
def persona_prompt(age, gruppe, item):
    return (f"Du bist {age} Jahre alt und {gruppe}.\n"
            f'Stimmst du zu: "{item}"?\n'
            "Antworte nur mit einer Zahl von 1 bis 5.")

def parse_likert(text):
    ziffern = [c for c in text if c in "12345"]
    return int(ziffern[0]) if ziffern else None  # Fehler zählen!

def sample(personas, item, call_llm, runs=5):
    antworten = []
    for p in personas:
        for _ in range(runs):                    # mehrfach fragen
            text = call_llm(persona_prompt(p["age"], p["gruppe"], item))
            antworten.append(parse_likert(text))
    return antworten
```
]
]

Aus den Antworten zählst du die Anteile je Option aus und vergleichst sie mit den echten, zum Beispiel mit `alignment()` von oben. Das Notebook `notebooks/04_silicon_sampling_validity.ipynb` spielt das mit synthetischen Daten durch (Foliensatz 04, letzte Folie im Abschnitt Silicon Samples). Die "echte" Seite bleibt dort synthetisch, es zeigt also die Mechanik, nicht die Gültigkeit eines echten Modells.

#praxis[Lege eine *Instrumentenkarte* an und gib sie jedem Bericht bei: Modellversion, Zugriffsdatum und -weg, Temperatur und weitere Einstellungen, exakte Prompts, Zahl der Wiederholungen, Parser, Zuverlässigkeitsmaße. Wird das Modell abgeschaltet, macht sie deine Arbeit noch interpretierbar @haindl2027research.]

== Für die Lehre

Diese Missverständnisse tauchen im Hörsaal immer wieder auf.

- *"Hohe Korrelation heißt gültig."* Die Korrelation von Durchschnitten sagt nichts über Verteilungen oder Zusammenhänge; im Notebook ist sie hoch, während sonst alles falsch ist. Zeig zuerst die 0.95 bei Dillion et al., dann die Umformulierungsstudie.
- *"Alignment 0.8 bedeutet: passt."* Das Beispiel mit dem Modell ohne Streuung zeigt, dass auch ein fast sinnloses Modell 0.80 erreicht. Ohne Streuungsmaß ist die Zahl nicht lesbar.
- *"Mehr künstliche Befragte machen es genauer."* Sie verkleinern nur den Zufallsfehler, nicht die systematische Verzerrung. Ein enges Intervall um einen falschen Wert ist keine Gültigkeit.
- *"Temperatur 0 macht es reproduzierbar."* Innerhalb einer Version über die API ja, über die Zeit und andere Zugänge nein.

#hoersaal([Darf ich in meiner Masterarbeit synthetische Befragte verwenden?], [Ja, als Pilot, zur Itementwicklung oder als Vorannahme, und immer mit einer menschlichen Stichprobe, die die Schlüsse trägt. Beschreibe das Messgerät vollständig und berichte offen, wo es versagt. Als einzige Evidenz für einen Effekt tragen synthetische Daten nach heutigem Stand nicht @chapekis2026can @li2026statistical.])

#hoersaal([Ist das alles nicht übertrieben vorsichtig? Bei Menschen gibt es doch auch Messfehler.], [Richtig, und die Messperspektive behandelt beide gleich. Der Unterschied liegt in der Art der Fehler. Bei Menschen schrumpft der Stichprobenfehler mit mehr Leuten, und es gibt Korrekturverfahren für bekannte Verzerrungen. Beim Simulator schrumpfen die systematischen Fehler nicht mit mehr künstlichen Befragten, und sie können sich ohne Ankündigung ändern. Deshalb braucht jede Studie ihre eigene menschliche Prüfung.])

#kurz[
  Ein Modell, das Befragte spielt, ist ein Messgerät; seine Ausgaben sind Messungen und brauchen Belege für Zuverlässigkeit und Gültigkeit.
][
  Das Messgerät besteht aus Modellversion, Prompt-Vorlage, Einstellungen und Parser; ändert sich einer, ist es ein anderes.
][
  Richtige Durchschnitte reichen nicht: Prüfe auf der Ebene deiner Aussage (Verteilung, Zusammenhang, Effekt), denn Streuung und Zusammenhänge fallen oft durch.
][
  Der Alignment-Score misst, wie ähnlich zwei Antwortmuster sind (1 = gleich); ein Modell ohne Streuung kann trotzdem 0.80 erreichen, also immer die Streuung mit berichten.
][
  Realismus ist nicht Effektgenauigkeit, und Glaubwürdigkeit ist keine Gültigkeit.
][
  Prompt-Wortlaut, Trainingsdaten, Modellversion, Zugangsweg und Antwortreihenfolge sind Störfaktoren; mische, wiederhole, protokolliere.
][
  Nutze LLM-Ausgaben als Pilot oder Vorannahme, nie als alleinige Quelle eines berichteten Effekts, und berichte mit GUIDE-LLM.
]

#selbsttest(
  ([Aus welchen vier Teilen besteht ein LLM-Messgerät, und warum reicht "wir haben GPT verwendet" nicht?], [Modellversion, Prompt-Vorlage, Einstellungen (zum Beispiel Temperatur) und Parser. Ändert sich ein Teil, ist es ein anderes Messgerät, daher muss man alle vier berichten.]),
  ([Erkläre mit der Badezimmerwaage den Unterschied zwischen Zuverlässigkeit und Gültigkeit.], [Zeigt die Waage dreimal fast dasselbe, ist sie zuverlässig. Zeigt sie immer 3 Kilo zu wenig, ist sie nicht gültig: Die Zahl bedeutet nicht, was sie vorgibt. Zuverlässig kann ein Gerät sein, ohne etwas Brauchbares zu messen.]),
  ([Das Modell trifft die Durchschnitte, aber nicht die Zusammenhänge. Nenne zwei Beispiele aus dem Kapitel.], [Bisbee et al.: Durchschnitte innerhalb der typischen Streuung, aber 48 % der Regressionskoeffizienten wichen ab, bei etwa einem Drittel davon in die Gegenrichtung. Argyle et al.: Gesamtkorrelation 0.90 bis 0.94, aber 0.02 bei Wählern ohne Parteibindung.]),
  ([Menschen antworten zu 10, 20, 40 und 30 %, ein Modell zu 0, 5, 90 und 5 %. Rechne den Alignment-Score aus.], [Laufende Summen: Menschen 10, 30, 70; Modell 0, 5, 95. Abstände 10, 25, 25, zusammen 60 Punkte = 0.60. Schlimmster Fall 3. Score = 1 minus 0.60 geteilt durch 3 = 0.80. Trotzdem ist das Modell fast ohne Streuung.]),
  ([Warum ist eine Simulation, die einzelne Antworten gut trifft, nicht automatisch gut für Effekte?], [Li und Ji: Der Prompt mit den besten Einzelantworten machte die Effekte in 8 von 9 Fällen schlechter. Realismus und Effektgenauigkeit sind verschiedene Ziele; validiere die Größe, die du berichtest.]),
  ([Nenne drei Störfaktoren des Messgeräts und je ein Gegenmittel.], [Prompt-Wortlaut (mehrere Formulierungen), Drift (Version festhalten, Datum protokollieren), Antwortreihenfolge (Optionen mischen). Auch möglich: Kontamination (Aufgaben nach dem Trainingsende), Interface-Effekte (API mit festen Parametern).]),
  ([Warum ist "ein KI-Paper hat die Workshop-Begutachtung bestanden" ein schwacher Beleg?], [Der Bewertungsvorgang ist nur ein Stellvertreter für Qualität. Die Autoren fanden selbst 57 % Überlappung zwischen Trainings- und Testdaten, die die Gutachter übersehen hatten.]),
)

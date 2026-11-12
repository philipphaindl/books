#import "lib.typ": *

= Bias messen

Du lässt ein Sprachmodell Bewerbungen vorsortieren. Es lädt von 100 Bewerbungen aus Gruppe A 60 zum Gespräch ein, von 100 Bewerbungen aus Gruppe B nur 40. Liegt das an den Bewerbungen, am Modell oder am Zufall? Sobald ein Sprachmodell in deiner Forschung etwas einordnet, sortiert oder bewertet, ist es ein Messinstrument. Misst es für manche Gruppen von Menschen strenger oder ungenauer als für andere, ist jeder Gruppenvergleich auf seinen Ausgaben schief. Das ist zuerst ein Problem der Messqualität und erst danach eines der Ethik.

Beispiele: ein Annotator, der Beiträge in afroamerikanischem Englisch häufiger als toxisch markiert, ein Screener, der bei identischem Lebenslauf je nach Vorname anders entscheidet, ein Gutachter, der Antworten erkennbar geflüchteter Verfasserinnen schlechter bewertet. Das Feld ist unübersichtlich: Es gibt Dutzende Kennzahlen und Benchmarks mit fehlerhaften Testfällen @blodgett2021stereotyping, und Modelle, die auf direkte Fragen vorbildlich neutral antworten, entscheiden trotzdem stereotyp, wenn die Gruppe nur indirekt sichtbar ist @bai2025explicitly @hofmann2024ai.

Dieses Kapitel ordnet das Feld und bleibt dabei bei Zählen und Vergleichen. Es begleitet Foliensatz 08 und das Notebook `notebooks/08_bias_metrics.ipynb`; die formale Fassung steht im großen Handbuch.

#lernziele[
  erklären, warum Bias in einer LLM-Pipeline ein Messproblem ist, und Schäden durch Darstellung von Schäden durch Entscheidungen unterscheiden,
][
  eine Bias-Metrik einer der vier Familien zuordnen und sagen, was sie dir sagt und was nicht,
][
  Gruppenfairness-Zahlen für einen LLM-Screener durch Zählen ausrechnen und mit Unsicherheit lesen,
][
  ein Namenstausch-Audit mit Kontrollbedingung planen und das Ergebnis deuten,
][
  prüfen, ob eine Bias-Messung misst, was sie zu messen vorgibt, und einordnen, was der EU AI Act verlangt.
]

== Bias als Messproblem

#alltag[Eine Badezimmerwaage zeigt bei einer Person zwei Kilo zu viel an, bei der anderen stimmt sie. Bei einer Person fällt das nicht auf. Vergleichst du die beiden, ist das Ergebnis falsch. Ein LLM, das für Gruppen unterschiedlich misst, ist diese Waage.]

Gemeint ist immer *sozialer Bias*, nicht der systematische Fehler aus _Das Nötigste vorab_: eine ungleiche Behandlung oder ein ungleiches Ergebnis zwischen sozialen Gruppen, das aus historischen und strukturellen Machtunterschieden stammt @gallegos2024bias. Bei Sprachmodellen zeigt er sich in dem, was das Modell über Gruppen sagt, und in dem, was es für Gruppen entscheidet.

In vielen Studien steht das Modell mitten in einer Kette (@k08-fig-pipeline): Es etikettiert Daten, sortiert Dokumente oder urteilt über Antworten, und am Ende steht ein Vergleich von Gruppen. Ein gruppenabhängiger Fehler läuft ungebremst bis in die Forschungsaussage. Wie real das ist: Bei acht wertausgerichteten Modellen (nachträglich auf erwünschtes Verhalten trainiert) zeigten 19 von 21 getesteten Stereotypen noch Spuren @bai2025explicitly. Nach einer kleinen Änderung fielen im Mittel 45,75~% der fünf bestplatzierten Lebensläufe aus der Spitzengruppe @seshadri2025small. Und in vier Bias-Benchmarks waren je nach Benchmark nur 0 bis 58~% der geprüften Testfälle frei von Fehlern @blodgett2021stereotyping.

#figure(
  diagram(spacing: (3mm, 9mm), edge-stroke: 0.8pt,
    fknoten((0, 0), [Daten über \ Menschen], col: c-grey, w: 29mm),
    edge("-|>"),
    fknoten((1, 0), [LLM etikettiert, \ sortiert, urteilt], col: c-blue, filled: true, w: 29mm),
    edge("-|>"),
    fknoten((2, 0), [Labels und \ Scores], col: c-grey, w: 29mm),
    edge("-|>"),
    fknoten((3, 0), [Vergleich \ der Gruppen], col: c-grey, w: 29mm),
    edge("-|>"),
    fknoten((4, 0), [Forschungs- \ aussage], col: c-dark, filled: true, w: 29mm),
    fknoten((1, 1), [Hier kann der Fehler \ von der Gruppe abhängen], col: c-accent, w: 40mm),
    edge((1, 0), (1, 1), "-", stroke: (paint: c-accent, thickness: 0.6pt, dash: "dashed")),
  ),
  caption: [Das Modell als Teil des Messinstruments. Ein gruppenabhängiger Fehler an dieser Stelle verfälscht alles danach.],
) <k08-fig-pipeline>

=== Zwei Arten von Schaden

Bevor du eine Zahl wählst, musst du wissen, welchen Schaden du messen willst @gallegos2024bias. *Repräsentationale Schäden* entstehen in dem, was ein Modell sagt: Stereotype, abwertende Sprache, das Unsichtbarmachen einer Gruppe. *Allokative Schäden* entstehen dort, wo etwas verteilt wird: Einladungen, Kredite, Plätze. Die erste Art misst du an Assoziationen und Texten, die zweite an Entscheidungsraten. Eine Durchsicht von 146 Arbeiten zeigte, wie unscharf das oft bleibt: 21~% nannten allokative Schäden als Motivation, nur vier schlugen Techniken dafür vor @blodgett2020language. Schreibe daher in einem Satz auf, welcher Schaden für wen gemeint ist.

=== Vier Familien von Metriken

Gallegos et al. ordnen Metriken danach, was sie lesen; für Pipelines kommt eine vierte Familie dazu, die Entscheidungen @gallegos2024bias. Vektoren und Wahrscheinlichkeiten setzen Einblick ins Modell voraus, den viele kommerzielle Schnittstellen nicht bieten; Hofmann et al. mussten GPT-4 deshalb aus einigen Analysen ausschließen @hofmann2024ai. Die ersten beiden Familien messen _intrinsisch_ (im Modell), die anderen beiden _extrinsisch_ (an dem, was am Ende herauskommt).

#figure(
  kind: table, supplement: [Tabelle],
  table(columns: (auto, 1fr, auto, auto),
    [Familie], [Frage, die sie beantwortet], [Misst], [Schaden],
    [Einbettung], [Liegen manche Gruppen in der Wortkarte des Modells näher an stereotypen Wörtern?], [intrinsisch], [Darstellung],
    [Wahrscheinlichkeit], [Hält das Modell den stereotypen Satz für wahrscheinlicher als sein Gegenstück?], [intrinsisch], [Darstellung],
    [Text und Antworten], [Antwortet oder schreibt das Modell anders, wenn sich nur die Gruppe ändert?], [extrinsisch], [Darstellung],
    [Entscheidung], [Bekommen Gruppen unterschiedlich oft ein Ja oder werden sie unterschiedlich oft falsch eingestuft?], [extrinsisch], [Verteilung],
  ),
  caption: [Die vier Familien von Bias-Metriken.],
)

Hinter vielen Tauschtests steckt eine Grundidee, die *Invarianz*: Ändert sich nur die Gruppe im Text, darf sich die Ausgabe nicht ändern, wie bei einem Vorspiel hinter einem Vorhang, bei dem die Jury nicht sieht, wer spielt.

== Wortkarten und Satzwahrscheinlichkeiten

Die erste Gruppe von Metriken liest Bias aus dem Inneren eines Modells. Sie braucht keine Testpersonen, sagt aber am wenigsten über Folgen im Alltag.

=== WEAT: liegen Namen näher bei Karriere oder bei Familie?

#alltag[Stell dir eine Landkarte vor, auf der jedes Wort einen Ort hat. Wörter, die in ähnlichen Zusammenhängen vorkommen, liegen nahe beieinander, wie Geschäfte derselben Art in einer Straße. Liegen männliche Vornamen näher bei "Karriere" und "Gehalt" und weibliche näher bei "Familie" und "Kinder", hat das Modell eine Verbindung gelernt, die in den Trainingstexten steckt.]

Diese Karte heißt _embedding_ (Einbettung): Jedes Wort ist ein Punkt, und der Abstand sagt, wie ähnlich sich Wörter sind. Der *Word Embedding Association Test* (WEAT) von Caliskan et al. macht daraus eine Messung @caliskan2017semantics. Er überträgt den Implicit Association Test der Psychologie, bei dem Menschen Begriffe schneller sortieren, wenn die Kombination zu ihren Assoziationen passt; an die Stelle der Reaktionszeit tritt der Abstand auf der Karte.

#figure(
  cetz.canvas(length: 0.85cm, {
    import cetz.draw: *
    circle((9.0, 5.3), radius: (2.7, 1.6), fill: c-green.lighten(85%), stroke: (paint: c-green, thickness: 0.8pt, dash: "dashed"))
    circle((2.7, 2.0), radius: (2.7, 1.6), fill: c-blue.lighten(85%), stroke: (paint: c-blue, thickness: 0.8pt, dash: "dashed"))
    for (pos, lab) in (((9.0, 5.8), "Karriere"), ((10.4, 4.9), "Gehalt"), ((7.9, 4.8), "Büro")) {
      circle(pos, radius: 0.1, fill: c-green, stroke: none)
      content((pos.at(0), pos.at(1) + 0.45), text(font: "Inter", size: 7.5pt, weight: "bold", fill: c-green.darken(10%), lab))
    }
    for (pos, lab) in (((2.6, 2.9), "Familie"), ((3.9, 1.5), "Zuhause"), ((1.4, 1.5), "Kinder")) {
      circle(pos, radius: 0.1, fill: c-blue, stroke: none)
      content((pos.at(0), pos.at(1) + 0.45), text(font: "Inter", size: 7.5pt, weight: "bold", fill: c-blue.darken(10%), lab))
    }
    for (pos, lab, dx, anc) in (((6.4, 3.6), "John", -0.25, "east"), ((5.6, 5.0), "Paul", -0.25, "east"), ((5.4, 2.3), "Amy", 0.25, "west")) {
      circle(pos, radius: 0.1, fill: c-dark, stroke: none)
      content((pos.at(0) + dx, pos.at(1)), anchor: anc, text(font: "Inter", size: 7.5pt, fill: c-dark, lab))
    }
    line((6.4, 3.6), (7.9, 4.8), stroke: (paint: c-dark, thickness: 0.6pt, dash: "dotted"))
    line((5.4, 2.3), (3.9, 1.5), stroke: (paint: c-dark, thickness: 0.6pt, dash: "dotted"))
  }),
  caption: [Eine erfundene Wortkarte. John liegt näher an "Büro" als an "Zuhause", Amy umgekehrt. Echte Karten haben hunderte Dimensionen, die Idee ist dieselbe.],
) <k08-fig-wortkarte>

So geht der Test: Für jeden Namen fragst du, ob er im Schnitt näher an den Karriere-Wörtern oder an den Familien-Wörtern liegt. Das ergibt eine Zahl pro Name. Dann vergleichst du die männlichen mit den weiblichen Namen. Die *Effektstärke* (_effect size_) sagt, wie viele "typische Streuungen" die beiden Gruppen auseinanderliegen. Null heißt kein Unterschied, je größer, desto stärker die Assoziation.

#rechnung(titel: [WEAT mit vier Namen])[
  Die Zahl pro Name sei "Neigung zu Karriere": John 0,10, Paul 0,06, Amy -0,02, Lisa 0,02 (erfundene Zahlen).

  + Mittelwert der männlichen Namen: (0,10 + 0,06) geteilt durch 2 = 0,08. Der weiblichen: (-0,02 + 0,02) geteilt durch 2 = 0,00.
  + Abstand der Mittelwerte: 0,08.
  + Typische Streuung aller vier Werte (die Standardabweichung): etwa 0,05.
  + Effektstärke: 0,08 geteilt durch 0,05, also etwa 1,55.

  Ein Schütteltest prüft, ob das Zufall sein kann: Die vier Namen werden zufällig neu in zwei Paare aufgeteilt. Dafür gibt es nur 6 Möglichkeiten, der p-Wert kann also nie unter 1 von 6 fallen. Aus vier Wörtern lässt sich keine Signifikanz ableiten.
]

Caliskan et al. fanden mit Wortvektoren aus Webtexten die Ergebnisse des menschlichen Tests wieder, teils deutlich stärker: 1,81 für Karriere gegen Familie bei männlichen und weiblichen Namen, bei Menschen 0,72 @caliskan2017semantics. Der *SEAT* von May et al. überträgt das auf Satzmodelle; seine Autoren berichten von "suspicious patterns of sensitivity", also auffälligen Schwankungen @may2019measuring. Rechnen musst du das nicht von Hand:

#datei("weat.py")[```python
import numpy as np

def aehnlich(a, b):          # wie nah liegen zwei Wörter auf der Karte?
    return a @ b / (np.linalg.norm(a) * np.linalg.norm(b))

def neigung(wort, karriere, familie):   # näher bei Karriere als bei Familie?
    k = np.mean([aehnlich(wort, w) for w in karriere])
    f = np.mean([aehnlich(wort, w) for w in familie])
    return k - f

def weat(maenner, frauen, karriere, familie):
    nm = [neigung(w, karriere, familie) for w in maenner]
    nf = [neigung(w, karriere, familie) for w in frauen]
    streuung = np.std(nm + nf, ddof=1)  # typische Abweichung aller Werte
    return (np.mean(nm) - np.mean(nf)) / streuung
```]

Berichte, wie du die Streuung gerechnet hast: Es gibt zwei leicht verschiedene Arten, und mit der anderen kommt im Beispiel 1,79 statt 1,55 heraus. Das Ergebnis hängt außerdem stark an den Wortlisten; das Notebook zeigt, wie ein ausgetauschtes Attributwort die Effektstärke bewegt.

=== CrowS-Pairs und StereoSet: welchen Satz hält das Modell für wahrscheinlicher?

Die zweite Methode fragt, wie wahrscheinlich ein Sprachmodell einen Satz findet. Man legt ihm zwei Sätze vor, die sich nur in der genannten Gruppe unterscheiden, einen stärker und einen schwächer stereotypisierenden. Wählt es systematisch den stereotypen, ist das ein Hinweis auf Bias.

*CrowS-Pairs* enthält 1508 solche Paare zu neun Bias-Typen im US-Kontext, etwa 14,5~% davon sind absichtlich umgekehrt @nangia2020crows. Der Wert ist der Anteil der Paare, bei denen das Modell den stereotypen Satz bevorzugt. Ideal ist 50, ein Münzwurf. BERT, RoBERTa und ALBERT erreichen 60,5, 64,1 und 67,0 @nangia2020crows. Bewertet werden dabei nur die Wörter, die in beiden Sätzen gleich bleiben, damit nicht einfach der häufigere Name gewinnt. Das Maß ist für maskierte Modelle entworfen, die ausgeblendete Wörter erraten (wie BERT); bei reinen Chat-Modellen nimmt man oft die Wahrscheinlichkeit des ganzen Satzes. Das ist eine andere Metrik, deren Zahlen du nicht mit den Originalwerten vergleichen darfst.

*StereoSet* löst ein Problem, das CrowS-Pairs offenlässt: Ein Modell, das Unsinn produziert, könnte trotzdem die ideale 50 treffen. Deshalb gibt es zu jedem Satzanfang drei Endungen, eine stereotype, eine anti-stereotype und eine sinnlose, insgesamt 16\u{202F}995 Tests @nadeem2021stereoset. Daraus entstehen drei Werte:

- `lms`: Wie oft bevorzugt das Modell eine sinnvolle statt der sinnlosen Endung? Ideal 100.
- `ss`: Wie oft bevorzugt es die stereotype gegenüber der anti-stereotypen? Ideal 50.
- `icat`: Beides in einer Zahl, nur hoch, wenn das Modell gut ist _und_ der `ss` nahe an 50 liegt.

GPT-2 small hat `lms` 83,6 und `ss` 56,4. Der `ss` liegt 6,4 Punkte von den fairen 50 entfernt, das sind 12,8~% des größtmöglichen Abstands. Um diesen Anteil wird der `lms` gekürzt: 83,6 mal 0,872 ergibt 72,9 (die Studie nennt 73,0 aus ungerundeten Werten). Bei größeren GPT-2-Modellen steigt der `ss` von 56,4 auf 60,1 und `icat` sinkt von 73,0 auf 70,5: Sie sind bessere Sprachmodelle, aber stereotyper @nadeem2021stereoset.

#fallstrick[`icat` bestraft jede Abweichung von 50 gleich stark, auch in die andere Richtung: Ein Modell, das immer die anti-stereotype Endung wählt, bekommt denselben Wert wie eines, das immer die stereotype wählt. Das ist eine Wertentscheidung, und die Autoren räumen ein, dass eine Vorliebe für manche Stereotype vernünftig sein kann @nadeem2021stereoset.]

== Texte und Antworten

Chat-Modelle misst man am natürlichsten an dem, was sie ausgeben, ohne Blick ins Modellinnere: mit Aufgaben, deren Antwort eindeutig auswertbar ist (BBQ), oder mit freien Texten, die man erst durch Zählen oder einen zweiten Klassifikator in Zahlen übersetzt.

=== BBQ: Rätsel mit fehlenden Hinweisen

Der *Bias Benchmark for QA* (BBQ) ist der wichtigste einzelne Benchmark für Instruktionsmodelle, also auf Anweisungen trainierte Chat-Modelle: 58\u{202F}492 Beispiele aus 325 Schablonen, neun soziale Dimensionen plus zwei Überschneidungen @parrish2022bbq. Jedes Beispiel ist ein Rätsel mit zwei Personen und einer Frage, in zwei Fassungen.

#beispiel(titel: [Ein BBQ-Item im Stil der Vorlage])[
  _Ein Großvater und seine Enkelin standen vor dem Fahrkartenautomaten. Wer hatte Schwierigkeiten mit der Bedienung?_ (Erfundenes Beispiel im Stil von BBQ.)

  *Mehrdeutig:* Der Text sagt nichts darüber, wer Schwierigkeiten hatte. Richtig ist "unbekannt". Wer eine Person nennt, rät, typischerweise nach einem Stereotyp.

  *Eindeutig:* Ein Zusatzsatz sagt, wer es war. Jetzt gibt es eine richtige Antwort, und BBQ prüft, ob das Stereotyp sie überstimmt.
]

Jede Frage gibt es auch in nicht-negativer Form ("Wer kam gut zurecht?"), damit eine allgemeine Vorliebe nicht als Bias durchgeht.

Der Bias-Wert lässt sich zählen. Zuerst streichst du alle Antworten "unbekannt". Von den übrigen zählst du, wie viele dem Stereotyp folgen. Die Hälfte ist neutral; damit 0 neutral heißt, wird die Skala auf den Bereich von -1 bis +1 gestreckt. Im mehrdeutigen Kontext wird der Wert zusätzlich mit dem Anteil der Fälle multipliziert, in denen das Modell nicht "unbekannt" gesagt hat: Wer selten rät, kann auch wenig Schaden anrichten.

#rechnung(titel: [BBQ-Wert im mehrdeutigen Kontext])[
  1000 Fragen. Das Modell antwortet 700-mal "unbekannt", also in 70~% der Fälle richtig. Von den übrigen 300 Antworten folgen 210 dem Stereotyp, das sind 70~%.

  + Bei 70~% statt 50~% liegt der Wert nach der Streckung auf 0,40 (50~% ergäbe 0, 100~% ergäbe 1).
  + Das Modell hat in 30~% der Fälle geraten. Also 0,40 mal 0,30 gleich 0,12.
]

Welche Antworten die offiziellen Auswerteskripte in den Anteil einrechnen, konnte nicht geprüft werden (Stand: 11. November 2026); schau ins BBQ-Repository, bevor du Zahlen aus verschiedenen Arbeiten vergleichst.

Parrish et al. testeten mehrere Frage-Antwort-Modelle @parrish2022bbq. Die beste Gesamtgenauigkeit hatte UnifiedQA mit 77,8~%, die schlechteste RoBERTa-Base mit 61,4~%; Zufall liegt bei 33,3~%, Menschen erreichen 95,7~%. Im mehrdeutigen Kontext kam kein Modell über 67,5~%, und wenn sie falsch lagen, folgten sie in 56 bis 77~% der Fälle dem Stereotyp. Selbst im eindeutigen Kontext waren sie bis zu 3,4 Punkte besser, wenn die richtige Antwort zum Stereotyp passte: ein Messfehler, der von der Gruppe abhängt.

BBQ eignet sich gut für eine Übung: Daten laden, ein offenes Modell fragen, Antworten zählen.

=== Freie Texte: zählen oder klassifizieren

Bei offenen Texten braucht es erst eine Zahl. Gallegos et al. sammeln Standardmaße @gallegos2024bias. Viele nutzen einen Klassifikator, ein zweites Modell, das Texte nach Stimmung oder Giftigkeit bewertet. Übersetzt in Alltagsfragen:

#figure(
  kind: table, supplement: [Tabelle],
  table(columns: (auto, 1fr),
    [Maß], [Was es dir sagt],
    [Expected maximum toxicity], [Wie giftig ist der schlimmste von mehreren Texten zu einem Prompt?],
    [Score parity], [Bekommen Texte über eine Gruppe im Schnitt höhere Klassifikatorwerte?],
    [Counterfactual sentiment bias], [Verschiebt sich die Bandbreite der Stimmungswerte, wenn nur die Gruppe im Prompt wechselt?],
    [HONEST], [Wie oft enthalten Vervollständigungen verletzende Wörter aus einer festen Liste?],
  ),
  caption: [Metriken auf generiertem Text.],
)

*BOLD* liefert 23\u{202F}679 Satzanfänge aus Wikipedia zu 43 Gruppen @dhamala2021bold. Die Autoren prüften ihre Maße gegen Urteile von Menschen: Ein Wert aus der Wortwahl ("neigt der Text zu weiblichen oder männlichen Wörtern?") stimmte sehr gut überein (0,92), die Stimmungs- und Giftigkeitswerte eines zweiten Modells mit 0,52 und 0,58 deutlich schlechter. *HolisticBias* liefert fast 600 Gruppenbezeichnungen für Tauschtests @smith2022sorry.

Die Lehre gilt für alle klassifikatorbasierten Maße: Sie erben die Fehler des Klassifikators. Für Giftigkeit war das lange die Perspective API, die laut Ankündigung nur bis 31. Dezember 2026 aktiv bleibt (Stand: 11. November 2026). Eine Übersicht über 241 Arbeiten fand, dass sich Ergebnisse änderten, als das Modell ohne Ankündigung neu trainiert wurde @hartmann2026bye. Schreibe deshalb Klassifikator und Version in deinen Bericht und archiviere die Rohwerte.



== Gruppenfairness bei Entscheidungen

Sobald ein Ergebnis in ein Ja oder Nein mündet, wird aus der Frage "Was sagt das Modell?" die Frage "Wer bekommt was?". Dafür gibt es die klassischen Kriterien der Fairness-Forschung @barocas2023fairness. Man braucht nur Zählen und Teilen.

#alltag[Vor einem Lokal stehen zwei Schlangen. Der Türsteher lässt aus Schlange A 60 von 100 Leuten herein und aus Schlange B 40 von 100. Ob das fair ist, hängt von der Frage ab: der Anteil insgesamt, der Anteil unter denen, die sich benehmen würden, oder ob seine Einschätzung für alle dasselbe bedeutet.]

=== Zählen mit zwei Gruppen

Im einfachsten Fall hast du von jeder Gruppe 100 Bewerbungen und zählst die Einladungen.

#beispiel(titel: [60 gegen 40])[
  Gruppe A: 60 von 100 Bewerbungen eingeladen, 60~%. Gruppe B: 40 von 100, 40~%.

  - Der Anteil der Einladungen heißt *Selektionsrate* (_selection rate_): 0,60 und 0,40.
  - Der Abstand der Raten ist die *Demographic-Parity-Differenz*: 20 Prozentpunkte. Ideal wäre 0.
  - Das Verhältnis der kleineren zur größeren Rate ist das *Disparate-Impact-Verhältnis*: 40 geteilt durch 60 gleich 0,67. Ideal wäre 1.
  - Die aus dem US-Arbeitsrecht bekannte *Vier-Fünftel-Regel* verlangt mindestens 0,8. Hier wird sie verfehlt @barocas2023fairness.
]

Bei mehr als zwei Gruppen nimmst du die höchste und die niedrigste Rate. Diese Zahlen sagen nur, wie viele ein Ja bekommen, nicht, ob die Gruppen gleich qualifiziert sind. Mit Gold-Labels (siehe _Das Nötigste vorab_) zählst du zwei weitere Raten: unter den wirklich Qualifizierten den Anteil, der eingeladen wird (_true positive rate_, TPR), und unter den Unqualifizierten den Anteil, der fälschlich eingeladen wird (_false positive rate_, FPR).

#beispiel(titel: [Ein LLM-Screener mit je 300 Bewerbungen])[
  In beiden Gruppen sind 100 qualifiziert und 200 nicht.

  #table(columns: (auto, auto, auto),
    [], [Gruppe A], [Gruppe B],
    [Eingeladen insgesamt], [90 von 300 = 0,30], [72 von 300 = 0,24],
    [TPR: Qualifizierte, eingeladen], [80 von 100 = 0,80], [70 von 100 = 0,70],
    [FPR: Unqualifizierte, eingeladen], [10 von 200 = 0,05], [2 von 200 = 0,01],
  )

  Unterschied der Selektionsraten: 0,30 - 0,24 = 0,06. Verhältnis 0,24 geteilt durch 0,30 = 0,80, also genau auf der Vier-Fünftel-Schwelle. Unter den Qualifizierten beträgt der Unterschied 0,10, unter den Unqualifizierten 0,04. Die *Equalized-Odds-Differenz* nimmt standardmäßig den größeren der beiden Werte, hier 0,10; Fairlearn kennt auch den Mittelwert (0,07), also nenne immer dazu, welche Variante du berichtest.
]

Hinter den Zahlen stehen drei Ideen von Fairness @barocas2023fairness @hardt2016equality:

#figure(
  kind: table, supplement: [Tabelle],
  table(columns: (auto, 1fr, auto),
    [Kriterium], [In Worten], [Zählt],
    [Independence (demographic parity)], [Jede Gruppe bekommt gleich oft ein Ja.], [Selektionsraten],
    [Separation (equalized odds)], [Unter Qualifizierten gleich oft ein Ja, unter Unqualifizierten gleich oft ein irrtümliches Ja.], [TPR und FPR],
    [Equal opportunity], [Nur die Qualifizierten zählen: gleich oft ein Ja.], [nur TPR],
    [Sufficiency (calibration)], [Ein bestimmter Score bedeutet für alle Gruppen dasselbe.], [Score gegen Ergebnis],
  ),
  caption: [Fairness-Kriterien für Entscheidungen.],
)

=== Ist der Unterschied echt?

Die 0,06 stammen aus nur 300 Bewerbungen je Gruppe, eine zweite Charge hätte einen anderen Wert gebracht. Wie stark er schwankt, zeigt ein *Konfidenzintervall* (siehe _Das Nötigste vorab_). Für die 0,06 reicht es von etwa -0,01 bis 0,13 und schließt 0 ein. Aus diesem Audit allein folgt also weder Alarm noch Entwarnung.

Praktisch bekommst du das Intervall durch einen *Bootstrap*: Du ziehst aus jeder Gruppe zufällig 300 Bewerbungen mit Zurücklegen, berechnest den Unterschied neu, wiederholst das 1000-mal und nimmst die mittleren 95~% der Ergebnisse. Einen wahren Unterschied von 0,06 entdeckt man mit 300 Personen je Gruppe nur in etwa 38~% der Fälle, mit 1000 in etwa 86~% (Näherung aus dem großen Handbuch). Echte LLM-Einstellungsaudits finden Lücken von nur 1,60 bis 3,78 Prozentpunkten @an2024large und brauchen große Stichproben.

=== Alles zugleich geht nicht

Man würde gern alle Kriterien erfüllen. Das geht nicht. Kleinberg et al. und Chouldechova haben unabhängig gezeigt, dass sich Kalibrierung und gleiche Fehlerraten ausschließen, sobald sich die Gruppen im Anteil der tatsächlich Qualifizierten unterscheiden @Kleinberg2017 @Chouldechova2017; Barocas et al. fassen die ganze Familie solcher Ergebnisse zusammen @barocas2023fairness.

#alltag[Zwei Klassen schreiben dieselbe Prüfung, aber in einer sitzen zufällig mehr starke Schüler. Mit einer einzigen Mindestpunktzahl erreichst du nicht zugleich, dass in beiden Klassen gleich viele bestehen, dass unter den Starken gleich viele bestehen und dass "bestanden" überall dasselbe bedeutet.]

Das Hindernis liegt in der Welt, nicht in der Technik. Du musst ein Kriterium wählen, eine ethische und politische Entscheidung darüber, welcher Fehler im jeweiligen Zusammenhang am meisten zählt @haindl2027research. Sie hat auch einen Preis, wie eine Fallstudie mit Kreditscores zeigt.

#figure(
  balken((([Gruppenblinder Schwellenwert], 99.3), ([Equal opportunity], 92.8), ([Equalized odds], 80.2), ([Demographic parity], 69.8)), max: 100, breite: 8, farbe: c-teal, einheit: " %", nachkomma: 1),
  caption: [Kreditscore-Fallstudie von Hardt et al.: Anteil des maximalen Gewinns, den die jeweilige Vorgabe übrig lässt @hardt2016equality.],
)

=== Die Zahlen selbst berechnen

Die Kennzahlen sind in wenigen Zeilen pandas gerechnet. Für die Lehre ist das besser als eine Bibliothek, weil sichtbar bleibt, wie größte und kleinste Rate verglichen werden; das Notebook prüft die Handrechnung gegen Fairlearn.

#datei("fairness.py")[```python
import pandas as pd

def group_rates(df, group="group", y="y_true", yhat="y_pred"):
    g = df.groupby(group)
    sr  = g[yhat].mean()                              # Selektionsrate
    tpr = df[df[y] == 1].groupby(group)[yhat].mean()  # Qualifizierte, eingeladen
    fpr = df[df[y] == 0].groupby(group)[yhat].mean()  # Unqualifizierte, eingeladen
    return pd.DataFrame({"SR": sr, "TPR": tpr, "FPR": fpr})

def fairness_summary(r):
    return {"DP_diff":    r.SR.max() - r.SR.min(),
            "DI_ratio":   r.SR.min() / r.SR.max(),
            "EOpp_diff":  r.TPR.max() - r.TPR.min(),
            "EOdds_diff": max(r.TPR.max() - r.TPR.min(),
                              r.FPR.max() - r.FPR.min())}
```]

Für das Screener-Beispiel gibt `fairness_summary` 0,06, 0,8, 0,1 und 0,1 zurück.

#block(breakable: false)[#hoersaal([Unser Screener erfüllt die Vier-Fünftel-Regel. Ist er damit in Ordnung?],
[Nein, nicht automatisch. Die Regel prüft nur die Einladungsquoten, nichts über Fehlerraten und nichts über Unsicherheit. Im Beispiel hält sie gerade noch, und trotzdem werden qualifizierte Bewerber aus Gruppe B seltener erkannt.])]

== Audits: gleiche Bewerbung, anderer Name

Gruppenfairness-Zahlen vergleichen verschiedene Menschen. Ein Unterschied kann deshalb auch daran liegen, dass die Bewerbungen tatsächlich verschieden sind. Ein kontrafaktisches Audit schaltet diese Erklärung aus: Du legst dem System dieselbe Eingabe zweimal vor und änderst nur ein Merkmal, das die Gruppe verrät.

#alltag[Du schickst zwei identische Bewerbungen ab. Nur der Name ist ein anderer. Wird die eine eingeladen und die andere nicht, kann es nicht an der Qualifikation liegen.]

Das Verfahren stammt aus der Arbeitsmarktforschung und heißt Korrespondenz- oder gepaartes Audit @haindl2027research. Es ist ein Experiment, in dem das geschützte Merkmal die einzige Stellschraube ist, mit den Pflichten jedes Experiments: andere Einflüsse kontrollieren, genug Fälle, passende Statistik. Ein Namenstausch greift nur in einen Hinweis im Text ein, nicht in das Merkmal selbst, und nähert sich der kontrafaktischen Fairness von Kusner et al. nur an @kusner2017counterfactual.

#figure(
  diagram(spacing: (8mm, 5mm), edge-stroke: 0.7pt,
    fknoten((0, 1), [Lebenslauf \ (Inhalt fest)], col: c-dark, filled: true, w: 24mm),
    fknoten((1, 0), [Name aus \ Gruppe A], col: c-blue, w: 24mm),
    fknoten((1, 1), [Name aus \ Gruppe B], col: c-accent, w: 24mm),
    fknoten((1, 2), [anderer Name \ aus Gruppe A], col: c-grey, w: 24mm),
    edge((0, 1), (1, 0), "-|>"), edge((0, 1), (1, 1), "-|>"), edge((0, 1), (1, 2), "-|>"),
    fknoten((2, 1), [dasselbe LLM, \ mehrere Prompts, \ mehrere Läufe], col: c-violet, filled: true, w: 32mm),
    edge((1, 0), (2, 1), "-|>"), edge((1, 1), (2, 1), "-|>"), edge((1, 2), (2, 1), "-|>"),
    fknoten((3, 0), [A gegen B: \ Namenseffekt], col: c-accent, w: 30mm),
    fknoten((3, 2), [A gegen A: \ Grundrauschen], col: c-grey, w: 30mm),
    edge((2, 1), (3, 0), "-|>"), edge((2, 1), (3, 2), "-|>"),
  ),
  caption: [Ablauf eines Namenstausch-Audits. Der Tausch innerhalb derselben Gruppe zeigt, wie stark die Entscheidung schon ohne Gruppensignal schwankt.],
) <k08-fig-audit>

Der Ablauf: Du nimmst eine Eingabe, änderst genau ein Gruppensignal (Name, Dialekt oder Pronomen), schickst beide Fassungen mit demselben Prompt mehrfach an dasselbe Modell, wiederholst das über viele Eingaben und prüfst, ob der Unterschied mehr als Zufall ist.

=== Was Audits gefunden haben

Der Dialekt ist ein besonders sauberer Auslöser: Hofmann et al. legten Modellen Texte in afroamerikanischem Englisch (AAE) und die bedeutungsgleiche Übersetzung in standardisiertes Englisch vor, ohne je die Ethnie zu erwähnen. Gemessen wird, wie viel wahrscheinlicher das Modell ein Merkmal nach dem AAE-Text findet als nach dem Zwilling, gemittelt über 2019 Paare.

Die Studie prüfte 12 Modellversionen (GPT-2, RoBERTa, T5, GPT-3.5, GPT-4) @hofmann2024ai. Die verdeckten Stereotype über AAE-Sprecher waren negativer als alle je erhobenen menschlichen Stereotype über Afroamerikaner, die offenen dagegen positiver. In hypothetischen Strafprozessen verurteilten die Modelle AAE-Sprecher in 68,7~% der Fälle, Sprecher von Standardenglisch in 62,1~%; die Todesstrafe gab es in 27,7~% gegenüber 22,8~%. Feedback-Training machte die offenen Stereotype günstiger, mit unklarer Wirkung auf die verdeckten. Ausrichtung kann Bias also verstecken, statt ihn zu beseitigen.

Bei Einstellungsentscheidungen ist das Bild uneinheitlich. An et al. fanden bei Zu- und Absage-E-Mails Unterschiede der Zusagerate von 1,60 bis 3,78 Punkten, und die Rangfolge der Gruppen änderte sich mit der Schablone @an2024large. Armstrong et al. sahen bei identischen Lebensläufen weiß klingende Namen höher bewertet @armstrong2024silicon. Wilson und Caliskan fanden weiß klingende Namen in 85,1~% der Tests bevorzugt, doch das Muster kehrte sich um, als die Namenshäufigkeit angeglichen wurde @wilson2024gender. Bei rund 361\u{202F}000 bewerteten Lebensläufen lagen Kandidatinnen vorn und schwarze Männer hinten, an einer Schwelle um etwa 1 bis 3 Punkte der Einstellungswahrscheinlichkeit @an2025measuring.

Das zeigt einen Mechanismus: Winzige Score-Unterschiede werden zu spürbaren Unterschieden bei der Auswahl, sobald eine Schwelle angelegt wird. Und Seshadri et al. zeigten, dass nicht jeder Unterschied Bias ist: Auch Änderungen ohne Gruppenbezug, wie Leerzeichen, warfen im Ranking viele Lebensläufe aus der Spitze, bei einem Modell sogar 72,76~% @seshadri2025small.

#fallstrick[Ohne Kontrollbedingung verwechselst du Empfindlichkeit mit Bias. Paare jede Änderung mit Gruppenbezug mit einer ohne: Namenstausch innerhalb der Gruppe, Tippfehler, Leerzeichen. Bias ist erst der Unterschied zwischen beiden Bedingungen, und zwar in einer festen Richtung.]

=== Auswerten: wer wurde nur mit welchem Namen eingeladen?

Ein Audit erzeugt Paare, also zählst du Paare, und zwar nur die, in denen die Entscheidungen auseinandergehen: eingeladen nur mit dem A-Namen oder nur mit dem B-Namen. Ohne Namenseffekt sind beide Fälle gleich häufig, das prüft der *McNemar-Test*.

#beispiel(titel: [Das Notebook-Audit])[
  400 simulierte Lebensläufe, jeder dreimal bewertet: mit einem A-Namen, einem B-Namen und einem anderen A-Namen als Kontrolle. Der Namenseffekt für B ist eingebaut. *A gegen B:* 41 Lebensläufe nur mit dem A-Namen eingeladen, 15 nur mit dem B-Namen, p-Wert 0,00069. *A gegen Kontrolle:* 27 gegen 21, p-Wert 0,47. Die Zahl der Wechsel ist in beiden Fällen ähnlich (14~% und 12~% der Lebensläufe); der Bias zeigt sich nicht in der Zahl, sondern in der Schieflage.
]

#datei("mcnemar.py")[```python
import pandas as pd
from statsmodels.stats.contingency_tables import mcnemar

# Entscheidung je Lebenslauf: 1 = eingeladen, jeweils mit A-Name und B-Name
tabelle = pd.crosstab(entscheidung_a, entscheidung_b).values
ergebnis = mcnemar(tabelle, exact=True)
print(ergebnis.pvalue)     # klein = die Schieflage ist kaum Zufall
```]

Bei vielen Gruppen und Modellen findet man fast zwangsläufig irgendwo einen "signifikanten" Unterschied; korrigiere deshalb, zum Beispiel nach Benjamini-Hochberg @seshadri2025small.

=== Explizit, implizit, Gutachter und Annotatoren

Bai et al. entwickelten Tests ohne Zugriff aufs Modellinnere @bai2025explicitly. Im Wortassoziationstest ordnet das Modell Wörter einem Namen zu, und du zählst, wie oft jeder Name die zu seiner Gruppe stereotyp passenden Wörter bekommt (ohne Bias die Hälfte der Zeit). Beispiel: "Emily" bekommt 7 von 8 Wörtern ihrer Gruppe (0,875), "Jamal" 6 von 8 (0,75). Addiere beides und ziehe 1 ab, den Wert ohne Bias: 0,875 + 0,75 - 1 = 0,625, auf einer Skala von -1 bis +1. Bei GPT-4 stieg mit jeder Stufe mehr Assoziations-Bias die Chance einer diskriminierenden Entscheidung auf das 2,68-Fache; "Chance" meint hier das Wettverhältnis, 3 zu 1 heißt drei diskriminierende Entscheidungen auf eine unauffällige @bai2025explicitly.

*discrim-eval* kombiniert 70 Entscheidungsszenarien mit 9 Altersstufen, 3 Geschlechtern und 5 Gruppen (9450 Prompts) und misst mit einer Regression (ein Verfahren, das den Einfluss einzelner Merkmale herausrechnet), wie weit ein Ja gegenüber der Basisperson (weiß, 60 Jahre, männlich) verschoben ist: 0 heißt nichts, negativ benachteiligt, +1,0 hebt eine Ja-Chance von 50~% auf etwa 73~%. Die Arbeit ist ein Preprint (eine noch nicht begutachtete Vorabfassung), und die Autoren raten selbst davon ab, Modelle für solche Entscheidungen einzusetzen @tamkin2023evaluating.

In deiner Forschung ist das Modell oft Instrument, als Annotator (Kapitel 5) oder Gutachter (Kapitel 7). Ye et al. messen für Gutachter zwei Zahlen @ye2024justice. Die *Robustness Rate* (RR) sagt, wie oft das Urteil bleibt, wenn man einen Identitätshinweis einfügt. Die *Consistency Rate* (CR) sagt, wie oft es bleibt, wenn man einfach noch einmal fragt. Die RR ist nur im Vergleich mit der CR lesbar, denn schon Rauschen kippt Urteile; erst eine RR deutlich unter der CR zeigt, dass der Hinweis selbst wirkt. Für Identitätshinweise lag die RR zwischen 0,68 und 0,91 @ye2024justice. Außerdem bevorzugten Sprachmodelle LLM-geschriebene Produkttexte in 89~% der Fälle, Menschen in einer kleinen Pilotstudie nur in 36~% @laurito2025ai. Persona-Prompts ("Du bist eine 45-jährige Frau ...") taugen nicht als Ersatz für fehlende Annotatorengruppen: Bei Menschen zeigten 46~% der Kombinationen aus Annotierenden- und Zielgruppe signifikanten Bias, bei Persona-Modellen nur 3,33~% @giorgi2025human.



== Wann eine Bias-Messung etwas misst

Bisher haben wir Zahlen ausgerechnet. Ob sie etwas bedeuten, ist eine andere Frage.

Blodgett et al. betrachten einen Benchmark als Messmodell: Aus beobachtbaren Eigenschaften (Testsätzen) wird ein nicht beobachtbares Konstrukt wie "Stereotypisierung" erschlossen @blodgett2021stereotyping. Trenne die *Konzeptualisierung* (was meinen wir genau?) von der *Operationalisierung* (welche Testfälle, welche Zahl?) und frage für beide, ob sie klar, valide und reliabel sind. Validität prüfst du dreifach @goldfarbtarrant2023prompt: sagt der Wert Verhalten in der Anwendung voraus (prädiktiv), sind die Testsätze realistische Sprache (ökologisch), und könnte die Messung selbst schaden (konsequenziell)? Sie fanden in je rund 100 Testfällen aus vier Benchmarks Fehler wie ungültige Änderungen, nicht vergleichbare Gruppen und unnatürlichen Text. Fehlerfrei waren bei Winogender 58~%, bei WinoBias 38~% und 22~% (je nach Variante), bei StereoSet 6~% und 0~% und bei CrowS-Pairs 3~%. Unterschiede von wenigen Punkten zwischen Modellen solltest du daher nicht als Befund verkaufen.

Goldfarb-Tarrant et al. fanden über Hunderte Modelle, Aufgaben und Sprachen "keine verlässliche Korrelation" zwischen Metriken im Modell und Ergebnissen in Anwendungen @goldfarbtarrant2021intrinsic, Delobelle et al. raten von einbettungsbasierten Maßen ab @delobelle2022measuring, und Lum et al. fanden zwischen einfachen Wortvorhersage-Tests und realistischen Texten wie Gutenachtgeschichten keinen Zusammenhang: Das am wenigsten verzerrte Modell nach den einfachen Tests zu wählen war ungefähr so gut wie Zufall @lum2025bias. Dagegen sagte bei Bai et al. innerhalb von GPT-4 der Assoziationswert Entscheidungen voraus, pro Prompt mäßig (0,36 auf einer Skala bis 1), nach Stereotypen gemittelt stark (0,72) @bai2025explicitly. Für dich gilt: Miss dort, wo die Entscheidung fällt, und behandle Werte aus dem Modellinneren höchstens als Warnsignal.

Auch Fragebögen sind zerbrechlich: Beim Political Compass Test drehten umformulierte Anweisungen bei bis zu 23 von 62 Aussagen die Mehrheitsposition um @rottger2024political. Besser sind realistische Aufgaben wie IssueBench mit 2,49 Millionen Schreibaufträgen @rottger2026issuebench; OpinionQA vergleicht, ob die Mischung der Modellantworten zu der von realen Gruppen passt (1 heißt perfekte Übereinstimmung) @santurkar2023whose.

Fast alle Benchmarks setzen außerdem als Ideal voraus, dass die Gruppe keine Rolle spielen soll (50 bei CrowS-Pairs und `ss`, 0 bei BBQ). Wang et al. zeigen, dass das nicht immer stimmt: Manche Zusammenhänge, etwa im Recht, verlangen Unterschiede, und gängiges Debiasing (Versuche, Bias aus Modellen herauszutrainieren) kann nach hinten losgehen @wang2025fairness. Auch die Richtung zählt: Bei Hochschulzulassungen bevorzugten Modelle Bewerber mit niedrigem sozioökonomischem Status @nghiem2025rich. Ob das gewollt ist, ist keine Statistikfrage.

Delobelle et al. sichteten 146 Arbeiten zu Bias-Maßen @delobelle2024metrics. Bei 20~% fehlte eine klare Motivation, bei 25~% ein verständliches Konstrukt, 47~% nannten keine beabsichtigte Verwendung, und nur 28 Arbeiten sprachen überhaupt über Reliabilität. Ein Bericht über eine Bias-Messung braucht daher mindestens fünf Dinge: Motivation, Konstrukt (getrennt vom Maß), Idealwert mit Begründung, beabsichtigte Verwendung und Reliabilität über Prompts, Zufallswerte und Modellversionen. Die Checkliste im nächsten Abschnitt führt das weiter.

== Regulierung: was der EU AI Act verlangt

Für Hochrisiko-Anwendungen wird die Bias-Untersuchung zur Rechtspflicht. Die folgenden Angaben haben den Stand 11. November 2026 und gehören vor jedem Einsatz in der Lehre erneut geprüft.

Grundlage ist die Verordnung (EU) 2024/1689 vom 13. Juni 2024 @eu2024regulation. Ihr Artikel 10 regelt die Daten für Hochrisiko-Systeme. Trainings-, Validierungs- und Testdaten müssen auf mögliche Verzerrungen untersucht werden, die die Gesundheit und Sicherheit von Personen beeinträchtigen, sich negativ auf Grundrechte auswirken oder zu verbotener Diskriminierung führen können (Art. 10 Abs. 2 lit. f). Dazu müssen "geeignete Maßnahmen" ergriffen werden, um solche Verzerrungen zu erkennen, zu verhindern und abzuschwächen (lit. g). Die Daten sollen außerdem relevant, hinreichend repräsentativ und so weit wie möglich fehlerfrei und vollständig sein (Abs. 3) @eu2024regulation. Bemerkenswert ist, was fehlt: Der Artikel nennt *keine Metrik und keinen Schwellenwert*. Ob du Demographic Parity, Equalized Odds oder die Vier-Fünftel-Regel nimmst, entscheidest du und begründest es.

Die Verordnung (EU) 2026/1744 vom 8. Juli 2026, der Digital Omnibus, wurde am 24. Juli 2026 veröffentlicht und trat am 27. Juli 2026 in Kraft @eu2026regulation. Für Bias-Messung sind zwei Änderungen wichtig. Erstens wurde Art. 10 Abs. 5 gestrichen und durch einen neuen Art. 4a ersetzt. Danach dürfen Anbieter von Hochrisiko-Systemen ausnahmsweise besondere Kategorien personenbezogener Daten verarbeiten, soweit das für die Erkennung und Korrektur von Verzerrungen unbedingt erforderlich ist, unter sechs Bedingungen: Andere Daten, auch synthetische oder anonymisierte, würden nicht genügen; die Weiterverwendung ist technisch begrenzt und gesichert, etwa durch Pseudonymisierung; der Zugriff ist streng und dokumentiert; es gibt keine Weitergabe an Dritte; die Daten werden gelöscht, sobald die Verzerrung korrigiert ist oder die Speicherfrist endet; und die Notwendigkeit ist schriftlich begründet. Für andere KI-Systeme erweitert Absatz 2 die Möglichkeit, ohne eine Pflicht zur Bias-Erkennung zu begründen @eu2026regulation. Zweitens ändern sich die Fristen:

#figure(
  kind: table, supplement: [Tabelle],
  table(columns: (auto, 1fr),
    [Datum], [Was gilt],
    [2. Februar 2025], [Kapitel I und II der Verordnung gelten.],
    [2. Dezember 2026], [Neue Verbote in Art. 5 gelten.],
    [2. Dezember 2027], [Die Anforderungen für Hochrisiko-Systeme nach Anhang III gelten, einschließlich Art. 10.],
    [2. August 2028], [Dasselbe für Produkte nach Anhang I.],
  ),
  caption: [Geltungsbeginn nach dem Digital Omnibus (Stand: 11. November 2026) @eu2026regulation. Der Erwägungsgrund 40 nennt verzögerte Normen, Leitlinien und nationale Behörden als Grund für die Verschiebung.],
)

Anhang III Nummer 4 Buchstabe a nennt Systeme, die für die Einstellung oder Auswahl von Personen gedacht sind, besonders um Bewerbungen zu analysieren und zu filtern und Bewerber zu bewerten (konsolidierte Fassung, Stand: 11. November 2026). Der Screener aus dem Abschnitt über Gruppenfairness fällt darunter, die Bias-Untersuchung nach Art. 10 ist damit ab 2. Dezember 2027 verlangt. Die Metriken und Audit-Designs dieses Kapitels sind die technischen Mittel; welche du nimmst, sagt der Act nicht.

#hoersaal([Warum lassen wir das geschützte Merkmal nicht einfach weg? Dann kann das Modell doch nicht diskriminieren.],
[Das ist _fairness through unawareness_, und sie scheitert aus zwei Gründen. Die Gruppe steckt in Stellvertretern wie Namen oder Dialekt @hofmann2024ai. Und du brauchst das Merkmal, um Bias zu messen, denn ohne Gruppe gibt es keine Rate je Gruppe. Deshalb erlaubt Art. 4a unter strengen Bedingungen die Verarbeitung sensibler Daten für diesen Zweck.])

== In der Praxis: Bias in einem eigenen Projekt messen

So gehst du vor, wenn dein Projekt ein Modell etwas entscheiden oder bewerten lässt:

+ *Schaden benennen:* in einem Satz, für wen, als Darstellung oder Verteilung.
+ *Messpunkt wählen:* dort, wo die Entscheidung fällt; Wortkarten-Maße sind höchstens Warnsignal.
+ *Maß und Idealwert festlegen:* Selektionsrate, Fehlerraten oder Tauschtest, begründet, mit dem, was du dafür aufgibst.
+ *Stellvertreter begründen:* mindestens etwa 50 Namen je Gruppe, Namenshäufigkeit kontrollieren.
+ *Mit Kontrolle messen:* zu jeder Änderung mit Gruppenbezug eine ohne, etwa ein Namenstausch innerhalb der Gruppe oder ein Leerzeichen.
+ *Mehrere Schablonen verwenden:* mindestens drei, und die Streuung zwischen ihnen berichten.
+ *Unsicherheit angeben:* Konfidenzintervalle, Korrektur bei vielen Vergleichen, Stichprobengröße vorab abschätzen.
+ *Alles festhalten:* Modellversion, Temperatur, Datum, Klassifikator samt Version, Prompts, Rohausgaben, dazu die Einschränkungen.

Als Werkzeuge reichen pandas zum Zählen und Fairlearn 0.15.0 zum Gegenprüfen. AIF360 0.6.1 gibt es seit April 2024 ohne neues Release, LangFair 0.8.0 deckt LLM-nahe Bewertung ab @bouchard2025langfair (Stand: 11. November 2026). BBQ und discrim-eval (CC-BY-4.0) sowie CrowS-Pairs (CC-BY-SA-4.0) liegen auf der Plattform Hugging Face.

Bei einem Bezahl-Dienst wächst die Zahl der Aufrufe schnell (Namen mal Schablonen mal Lebensläufe); teste erst klein. Für synthetische Lebensläufe brauchst du in der Regel keine Ethikkommission; sobald echte sensible Daten verarbeitet werden oder Menschen belastende Inhalte beurteilen, gelten die Regeln der Forschung mit Menschen @haindl2027research.

== Für die Lehre

Diese Missverständnisse kommen erfahrungsgemäß vor:

- *"Ein niedriger Wert auf einem Standardbenchmark heißt fair."* Zeige die Zahlen zu den fehlerhaften Testfällen und den Befund, dass die Auswahl nach einfachen Tests so gut wie Zufall war @blodgett2021stereotyping @lum2025bias.
- *"Mit besseren Modellen lässt sich Fairness vollständig erreichen."* Das Hindernis liegt in der Welt, nicht in der Technik.
- *"Der AI Act schreibt eine Metrik vor."* Zeige den Wortlaut von Art. 10: Untersuchung und Maßnahmen, keine Zahl.

#hoersaal([Ein Namenstausch verrät doch mehr als die Ethnie, etwa den sozialen Status. Ist er dann überhaupt ein gültiges Experiment?],
[Die Kritik ist berechtigt und alt @barocas2023fairness; bei Sprachmodellen kommt die Namenshäufigkeit hinzu @wilson2024gender. Gültig bleibt die Aussage "das System behandelt Profile mit Name X anders als mit Name Y". Problematisch ist erst der Schluss auf Ethnie als Ursache. Gute Audits kontrollieren die Häufigkeit und nehmen viele Namen je Gruppe.])


#kurz[
  Bias in einer LLM-Pipeline ist ein Messfehler, der von der Gruppe abhängt.
][
  Es gibt vier Familien von Metriken; je näher am Entscheidungspunkt, desto mehr sagt ein Maß über Schaden.
][
  Fairness-Kennzahlen sind Zählen und Teilen; die Kriterien lassen sich nicht alle zugleich erfüllen, die Wahl ist eine Wertentscheidung.
][
  Ein Audit tauscht nur ein Gruppensignal und braucht eine Kontrolle, sonst verwechselst du Empfindlichkeit mit Bias.
][
  Der EU AI Act verlangt eine Untersuchung möglicher Verzerrungen ab 2. Dezember 2027 (Anhang III), aber keine bestimmte Metrik (Stand: 11. November 2026).
]

#selbsttest(
  ([Warum ist Bias in einer LLM-Pipeline ein Messproblem und nicht nur eine Frage der Ethik?], [Weil ein Modell, das für Gruppen unterschiedlich genau misst, jeden Gruppenvergleich auf seinen Ausgaben verfälscht.]),
  ([Gruppe A: 55 von 100 eingeladen, Gruppe B: 44 von 100. Rechne Unterschied und Verhältnis aus und beurteile mit der Vier-Fünftel-Regel.], [Unterschied 11 Prozentpunkte, Verhältnis 44 geteilt durch 55 gleich 0,8: genau an der Schwelle. Fehlerraten und Unsicherheit bleiben offen.]),
    ([Warum kannst du aus 41 gegen 15 Wechseln beim Namenstausch nicht sofort auf Bias schließen?], [Ohne Kontrolle weißt du nicht, wie viele Wechsel ohnehin durch Rauschen entstehen. Erst der Tausch innerhalb der Gruppe (27 gegen 21) zeigt, dass die Schieflage größer ist.]),
  ([Was bedeutet StereoSet-`ss` von 50, und warum reicht das allein nicht?], [Das Modell wählt stereotype und anti-stereotype Endung gleich oft. Ob es Sprache versteht, sagt das nicht; deshalb gibt es `lms` und `icat`.]),
  ([Was verlangt Art. 10 des EU AI Act zu Bias, und was nicht?], [Untersuchung und geeignete Maßnahmen, ab 2. Dezember 2027 für Anhang-III-Systeme wie CV-Screening. Eine Metrik schreibt er nicht vor.]),
)

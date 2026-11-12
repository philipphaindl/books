#import "lib.typ": *

= LLM-as-a-Judge

Du hast ein System gebaut, das Fragen aus Dokumenten beantwortet, und willst wissen, ob die zweite Version besser ist als die erste. Es gibt 2000 Testfragen und keine einzige "richtige" Antwort zum Abgleichen, nur freie Texte. Menschen können 2000 Antworten bewerten, aber langsam und teuer. Einfache Textvergleiche wie BLEU und ROUGE stimmen bei offenen Antworten schlecht mit dem Urteil von Menschen überein @liu2023geval @zheng2023judging. Also bittest du ein zweites Sprachmodell: "Welche der beiden Antworten ist besser, und warum?" Das ist _LLM-as-a-Judge_: ein Sprachmodell als Richter.

Das funktioniert überraschend gut. GPT-4 stimmte auf dem Benchmark MT-Bench in über 80 % der Fälle mit den Präferenzen von Menschen überein @zheng2023judging, und Richter-Modelle sortieren heute die Ranglisten von Arena-Hard-Auto und AlpacaEval @li2025crowdsourced @dubois2024length. Es hat aber einen Haken: Der Richter ist selbst ein Messgerät, und Messgeräte haben Fehler. Seine Fehler streuen nicht zufällig, sondern zeigen immer in dieselbe Richtung. Wer ihn ungeprüft einsetzt, misst vielleicht Länge statt Qualität oder die Vorliebe des Richters für Texte, die wie er selbst klingen.

Dieses Kapitel zeigt, wie du einen Richter baust, wie du ihn gegen Menschen prüfst und wie du seine typischen Fehler gezielt aufspürst, nämlich indem du Antworten vertauschst und erneut bewertest. Es endet mit einer Checkliste, die du in einer Abschlussarbeit oder Studie abarbeiten kannst. Der passende Foliensatz ist Foliensatz 07, das Notebook dazu heißt `notebooks/07_judge_validation.ipynb`.

#lernziele(
  [Du wählst Format, Referenz und Aufbau eines Judge-Prompts für eine Bewertungsaufgabe.],
  [Du misst, wie gut ein Richter mit Menschen übereinstimmt, und erkennst, wann "90 % Übereinstimmung" täuscht.],
  [Du testest einen Richter auf Position-, Längen- und Selbstvorliebe, indem du Antworten vertauschst und neu bewertest.],
  [Du kennst die wichtigsten Gegenmittel und weißt, wie viel menschliche Arbeit ein Richter höchstens spart.],
  [Du liest eine Arena-Rangliste kritisch und erklärst, warum ein Platz mehr oder weniger nicht viel sagt.],
  [Du arbeitest ein Validierungsprotokoll für einen Richter Schritt für Schritt ab.],
)

== Der Richter ist ein Messgerät

#alltag[Du kaufst eine neue Küchenwaage. Sie zeigt 500 Gramm an, und du glaubst es erst, nachdem du ein Päckchen Mehl mit bekanntem Gewicht daraufgelegt hast. Zeigt sie dann immer 30 Gramm zu viel an, kannst du das einrechnen. Zeigt sie mal zu viel, mal zu wenig, ist sie schwerer zu retten.]

Ein Richter-Modell ist wie diese Waage. Seine Punktzahl ist eine Messung von etwas Abstraktem, etwa "Hilfsbereitschaft" oder "Treue zur Quelle", und keine Tatsache. Messungen haben Fehler, und bei Richtern sind sie systematisch: Er bevorzugt zum Beispiel lange Antworten, und zwar bei jeder einzelnen. Ein Fehler in einer festen Richtung verschwindet nicht, wenn du mehr Antworten bewerten lässt. Du bekommst dann nur eine sicherer klingende falsche Zahl.

Dazu kommt ein Zirkelschluss, den man _circular validation_ nennt: Ein starker Richter kann dieselben blinden Flecken haben wie das System, das er bewertet. Dann findet er dessen Fehler nicht, weil er sie selbst macht. Chehbouni und Kollegen nennen die verbreitete Begeisterung für Richter-Modelle deshalb voreilig, weil vier Annahmen kaum geprüft werden: Der Richter ersetzt Menschen, er ist fähig, er skaliert, und er ist günstig @chehbouni2025neither. Bavaresco und Kollegen fassen die Konsequenz zusammen: Ein LLM sollte sorgfältig gegen Urteile von Menschen validiert werden, bevor man es als Bewerter einsetzt @bavaresco2025llms. Genau das lernst du hier.

== Einen Richter bauen

=== Eine, zwei oder viele Antworten

Die erste Entwurfsentscheidung ist, wie viele Antworten der Richter auf einmal sieht.

#figure(
  table(columns: (auto, auto, 1fr, 1fr),
    [Format], [Antworten], [Der Richter liefert], [Hauptrisiko],
    [_Pointwise_], [eine], [eine Punktzahl für diese Antwort allein], [Ganzzahlen erzeugen viele Gleichstände],
    [_Pairwise_], [zwei], [die bessere Antwort oder ein Unentschieden], [Positionseffekt: die Reihenfolge beeinflusst das Urteil],
    [_Listwise_], [drei oder mehr], [eine Rangfolge oder eine Auswahl], [weniger konsistent als paarweise (GPT-4o 0,68 gegenüber 0,76)],
  ),
  caption: [Die drei Eingabeformate eines Richters @li2025generation @zheng2023judging @liu2023geval @shi2025judging.],
)

Nimm _pairwise_, wenn du zwei Systeme vergleichen willst; dieses Format nutzen Chatbot Arena, AlpacaEval und Arena-Hard-Auto @chiang2024chatbot @li2025crowdsourced. Nimm _pointwise_ mit einer Rubrik, wenn du ein absolutes Qualitätsniveau brauchst, etwa "Treue 4 von 5". Zheng und Kollegen nennen das "single answer grading" @zheng2023judging.

=== Was der Richter zusätzlich bekommt

Ohne Zusatz sieht der Richter nur die Frage und die Antwort (_reference-free_, zum Beispiel G-Eval @liu2023geval). Du kannst ihm mehr mitgeben: eine Musterlösung (_reference-guided_, etwa bei Mathe), eine Rubrik mit einer Beschreibung für jede Punktestufe (_rubric-based_, so trainierten Kim und Kollegen Prometheus @kim2024prometheus) oder eine Checkliste mit Ja/Nein-Fragen, wobei die Punktzahl der Anteil der Ja-Antworten ist (_checklist-based_, TICK @cook2024ticking). Sogar ein Agent, der Dateien öffnet, kann Richter sein (_Agent-as-a-Judge_ @zhuge2025agent).

#studie(titel: [Zheng et al., 2023])[
  *Was:* GPT-4 benotete zehn Rechenaufgaben, also 20 Urteile. *Ergebnis:* Mit dem Standard-Prompt lag es in 14 von 20 Fällen falsch, mit Schritt-für-Schritt-Denken (_chain-of-thought_) in 6 von 20, mit einer Musterlösung in 3 von 20 @zheng2023judging. *Das heißt:* Eine richtige Referenz hilft stark.
]

Der Haken: Die Referenz muss stimmen. Krumdick und Kollegen (eine noch nicht begutachtete Vorab-Fassung, ein _Preprint_) ließen GPT-4o die Musterlösung selbst erzeugen. Bei den Aufgaben, die GPT-4o falsch beantwortet hatte, stimmte der Richter mit seiner eigenen Referenz kaum mit Experten überein (Cohens kappa 0,16), ohne Referenz etwas besser (0,30) und mit einer Referenz von Menschen sehr gut (0,83). Auch eine nur fast richtige Referenz schadet: Bei Aufgaben, die GPT-4o richtig gelöst hatte, sank kappa von 0,46 ohne Referenz auf 0,21 @krumdick2025free. Kappa erklären wir gleich ausführlich; hier genügt: 0 heißt "nicht besser als Raten", 1 heißt "perfekt". Die Moral lautet, dass der Richter genau dort versagt, wo er die Aufgabe selbst nicht lösen kann.

=== Der Judge-Prompt in vier Teilen

Ein guter Judge-Prompt hat vier Bausteine. Die *Rubrik* nennt ein Kriterium und beschreibt in einem Satz jede Punktestufe, damit der Richter keine eigene Skala erfindet. Die *Skala* ist kurz, etwa 1 bis 5. Die *Begründung zuerst* zwingt den Richter, erst Belege zu schreiben und dann zu bewerten; so bewertet er nicht aus dem Bauch heraus, und Wang und Kollegen steigerten damit die Übereinstimmung mit Menschen @wang2024large. Die *strukturierte Ausgabe* ist JSON, das dein Code lesen kann.

#figure(
  diagram(
    spacing: (7mm, 0mm), node-corner-radius: 3pt,
    fknoten((0, 0), [Aufgabe \ und Antwort], w: 30mm),
    fknoten((1, 0), [Prompt mit Rubrik, \ Skala, Begründung \ zuerst], col: c-accent, filled: true, w: 40mm),
    fknoten((2, 0), [Richter-LLM], col: c-blue, filled: true, w: 26mm),
    fknoten((3, 0), [JSON mit Begründung \ und Punktzahl], w: 38mm),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"),
  ),
  caption: [Der Weg einer Bewertung: Die Qualität steckt im Prompt, das Ergebnis muss dein Code lesen können.],
)

#block(breakable: false)[#datei("judge.py")[
```python
import json

JUDGE_PROMPT = """Bewerte die TREUE der Antwort zur Quelle.
Quelle: {source}
Antwort: {answer}
1 = erfindet Fakten, die nicht in der Quelle stehen.
3 = überwiegend belegt, eine Aussage ohne Beleg.
5 = jede Aussage ist durch die Quelle belegt.
Schreibe zuerst zwei Sätze Begründung.
Antworte dann nur mit JSON:
{{"begruendung": "...", "score": 1}}"""

def judge(source, answer, ask_llm):
    prompt = JUDGE_PROMPT.format(source=source, answer=answer)
    raw = ask_llm(prompt)          # dein API-Aufruf, Temperatur niedrig
    try:
        return json.loads(raw)["score"]
    except (ValueError, KeyError):
        return None                # unlesbar: zählen und nachsehen
```
]]

`ask_llm` steht für deinen Aufruf an ein Modell deiner Wahl. Zähle, wie oft `None` herauskommt, denn eine hohe Quote heißt, dass der Prompt nachgebessert werden muss. Few-Shot-Beispiele im Prompt (eine kurze Zahl bewerteter Beispiele) hoben bei Zheng und Kollegen die Konsistenz von GPT-4 auf MT-Bench von 65,0 % auf 77,5 % @zheng2023judging. Eine Besonderheit von G-Eval: Gibt dir die Schnittstelle die Wahrscheinlichkeiten der Ziffern, gewichtest du jede Punktzahl damit @liu2023geval. Ist der Richter zu 5 % für die 1, zu 10 % für die 2, zu 20 % für die 3, zu 40 % für die 4 und zu 25 % für die 5, ergibt das 3,70 statt der glatten 4, und Gleichstände verschwinden. Zitiere für G-Eval keinen einzelnen Wert für "Fluency", denn arXiv-Fassung und EMNLP-Fassung weichen voneinander ab.

Rechne damit, dass sich deine Kriterien beim Ausprobieren ändern. Shankar und Kollegen beobachteten, dass Nutzer Kriterien erst beim Bewerten von Ergebnissen entdecken ("criteria drift") @shankar2024validates. Bewerte deshalb vor dem Einfrieren der Rubrik selbst 20 oder mehr Antworten.

=== Welche Arten von Richtern es gibt

Der klassische Richter ist ein _prompted_ Allzweckmodell wie GPT-4 oder GPT-4-Turbo. Daneben gibt es feinabgestimmte Richter wie JudgeLM (7B bis 33B) und Prometheus 2, die auf Bewertungsdaten trainiert wurden @zhu2025judgelm @kim2024prometheus2. Ein _Panel_ aus mehreren kleinen Modellen stimmt per Mehrheit ab (PoLL @verga2024replacing). _Reward-Modelle_ geben jeder Antwort nur eine Zahl @lambert2025rewardbench. _Reasoning-Richter_ wie o3-mini, J1 oder RM-R1 denken vor dem Urteil nach @tan2025judgebench @whitehouse2026j1 @chen2026rmr1. Modellnamen veralten schnell; die Entwurfsfragen davor bleiben (Stand: 11. November 2026).

== Wie gut ist der Richter? Meta-Evaluation

_Meta-Evaluation_ heißt, den Richter selbst zu bewerten, wie man einen Rauchmelder mit echtem Rauch testet. Dafür gibt es drei Vergleichspunkte, die verschiedene Fragen beantworten:

- *Menschliche Labels:* Sagt der Richter Antwort für Antwort dasselbe wie Menschen? Beispiel: der Datensatz JUDGE-BENCH.
- *Objektive Richtigkeit:* Wählt er die nachweislich richtige Antwort? Beispiel: JudgeBench @tan2025judgebench.
- *Systemebene:* Ordnet er ganze Modelle so wie Menschen? Beispiel: Vergleich mit den Rängen der Chatbot Arena.

Die drei können stark auseinanderlaufen. Ein Richter kann auf einer Ebene gut aussehen und auf einer anderen schlecht @gu2024survey @bavaresco2025llms.

=== Übereinstimmung jenseits des Zufalls

Der erste Reflex lautet: "Wie oft sagt der Richter dasselbe wie der Mensch?" Das ist die _percent agreement_. Sie täuscht, sobald eine Antwort häufig ist.

#alltag[Zwei Freunde beantworten 100 Fragen mit "stimmt" oder "stimmt nicht". Beide sagen bei den meisten "stimmt". Auch ohne gemeinsames Wissen träfen sie deshalb sehr oft zufällig dieselbe Antwort. Eine hohe Übereinstimmung beweist dann wenig.]

Die Lösung heißt *Cohens kappa*. Es fragt: Um wie viel besser als der reine Zufall stimmen die beiden überein, gegeben ihre üblichen Gewohnheiten? Der Wert 0 heißt "nicht besser als Zufall", 1 heißt "perfekt". Scotts pi ist ein enger Verwandter, der die Gewohnheiten beider Beurteiler zusammenwirft und dadurch etwas strenger wird, wenn sie unterschiedlich oft "stimmt" sagen. Krippendorffs alpha tut dasselbe für mehr als zwei Beurteiler (Kapitel 5).

#beispiel(titel: [100 Antworten, doppelt bewertet])[
  Ein Mensch und ein LLM-Richter beurteilen 100 Antworten als richtig oder falsch. Bei 60 sagen beide "richtig", bei 20 beide "falsch", bei 15 sagt der Richter "richtig", der Mensch "falsch", bei 5 umgekehrt. Sie stimmen also in 80 von 100 Fällen überein. Klingt gut.
]

#rechnung(titel: [Warum aus 80 Prozent 0,53 werden])[
  Der Richter sagt 75-mal "richtig", der Mensch 65-mal. Allein durch diese Gewohnheiten würden sie zufällig bei etwa 57 von 100 Antworten übereinstimmen (genauer: 57,5). Tatsächlich stimmen sie bei 80 überein, also 22,5 Antworten mehr als der Zufall. Übrig war ohnehin nur Platz für 100 minus 57,5 gleich 42,5 Antworten. Dass der Richter 22,5 davon schafft, ergibt 22,5 geteilt durch 42,5, also etwa *0,53*. Scotts pi kommt auf etwa 0,52.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let w = 14
    let seg(a, b, col, lab, ly) = {
      rect((a * w / 100, 0), (b * w / 100, 0.9), fill: col, stroke: white)
      content(((a + b) / 2 * w / 100, -0.45 - ly), text(font: "Inter", size: 7pt, lab))
    }
    seg(0, 57.5, c-grey.lighten(55%), [durch Zufall zu erwarten: 57,5], 0)
    seg(57.5, 80, c-green, [mehr als Zufall: 22,5], 0.55)
    seg(80, 100, c-red.lighten(30%), [uneinig: 20], 0)
    content((0, 1.35), anchor: "west", text(font: "Inter", size: 7.5pt, weight: "bold", [100 Antworten: Übereinstimmung 80, davon nur 22,5 mehr als Zufall -> kappa 0,53]))
  }),
  caption: [Warum 80 % Übereinstimmung nach Abzug des Zufalls nur noch kappa 0,53 ergeben. Konstruiertes Beispiel.],
)

*Lesen:* Landis und Koch haben Bänder vorgeschlagen: bis 0,20 gering (_slight_), 0,21 bis 0,40 schwach (_fair_), 0,41 bis 0,60 mittel (_moderate_), 0,61 bis 0,80 erheblich (_substantial_), über 0,80 fast perfekt (_almost perfect_) @Landis1977. Das ist eine Konvention, kein Gesetz. Was reicht, hängt von der Aufgabe und davon ab, was bei einem Fehler auf dem Spiel steht @haindl2027research.

*Praktisch:* In Python genügt die Bibliothek scikit-learn. Dazu kommt die _Nachsicht_ (_leniency_): Wie viele der Fehler gehen in die "zu großzügige" Richtung? In unserem Beispiel sind es 15 von 20 Fehlern, also 0,75, und das Ergebnis sagt: Dieser Richter ist zu nett.

#block(breakable: false)[#datei("agreement.py")[
```python
from sklearn.metrics import cohen_kappa_score, confusion_matrix

# human, judge: Arrays mit 1 (richtig) oder 0 (falsch)
agree = (human == judge).mean()               # Prozent-Übereinstimmung
kappa = cohen_kappa_score(human, judge)       # jenseits des Zufalls
tn, fp, fn, tp = confusion_matrix(human, judge).ravel()
leniency = fp / (fp + fn)                     # Anteil "zu großzügig"
print(round(agree, 2), round(kappa, 2), round(leniency, 2))
```
]]

*Wo es schiefgeht:* Du berechnest nur die Prozentzahl. Berichte immer kappa mit der Vierfeldertafel (Kapitel 0), und zwar pro Aufgabentyp.

=== Wenn Prozent täuschen: zwei Studien

#studie(titel: [Thakur et al., 2025])[
  *Was:* 400 TriviaQA-Fragen, 9 Modelle als "Prüflinge", 13 Richter. Drei Menschen kamen auf Scotts pi 96,2, die Aufgabe ist für sie leicht. *Ergebnis:* Die besten Richter lagen etwa 8 Punkte darunter. Llama-3 8B hatte pi 59, obwohl die Prozent-Übereinstimmung "deutlich über 80 %" lag. Selbst bei über 90 % Übereinstimmung lagen die vergebenen Punktzahlen teils um mehr als 10 Punkte daneben. Die Nachsicht reichte von 0,19 (JudgeLM-7B) bis 0,99 (Llama-2 70B) @thakur2025judging. *Das heißt:* Bei härteren Aufgaben dürfte es schlechter aussehen, so die Autoren.
]

Zahlen verschiedener Studien lassen sich oft nicht vergleichen. Zheng und Kollegen fanden bei GPT-4 85 % Übereinstimmung mit Menschen, wenn man Unentschieden weglässt, und 66 % mit Unentschieden; Mensch gegen Mensch lag bei 81 % und 63 % @zheng2023judging. Das "über 80 %" gilt also für Stimmen ohne Gleichstand auf einem Benchmark. Über 20 Datensätze von JUDGE-BENCH hinweg lag der durchschnittliche kappa-Wert von GPT-4o nur bei 0,28 @bavaresco2025llms.

=== Rangkorrelation: stimmt die Reihenfolge?

#begriff[Rangkorrelation (Spearman)][Du sortierst zwei Listen, etwa die Modelle nach Richter-Punkten und nach Menschen-Punkten, und prüfst, ob die Reihenfolge gleich ist. 1 heißt gleiche Reihenfolge, 0 heißt kein Zusammenhang, -1 heißt umgekehrte Reihenfolge.]

Sie ist ein Maß für ganze Rangfolgen, nicht für einzelne Antworten. Dieser Unterschied ist die zweite große Falle. Thakur und Kollegen zeigten, dass die grobe Zeichenkette-Suche "enthält die Antwort" einzelne Antworten schlecht bewertet (pi 0,64 gegenüber 0,88 für das beste Modell), die neun Prüflinge aber fast genau wie Menschen ordnet (Rangkorrelation 0,99) @thakur2025judging. Umgekehrt erreicht MT-Bench mit den Rängen von Menschen 89,9 % Rangkorrelation, trennt aber nur 22,6 % der Modellpaare sicher voneinander @li2025crowdsourced. Typischer Fehler in Papers: Eine hohe Korrelation auf Systemebene soll einzelne Labels rechtfertigen. Prüfe immer auf der Ebene, auf der deine Behauptung gilt.

=== Übereinstimmung ist nicht Richtigkeit

Auch ein hoher kappa-Wert beweist nicht, dass der Richter recht hat; ein Richter, der dieselben Fehler macht wie die Menschen, stimmt trotzdem überein. JudgeBench prüft deshalb gegen die objektive Wahrheit: 350 Antwortpaare, jeweils eine nachweislich richtige und eine nachweislich falsche, jedes Paar in beiden Reihenfolgen. Bewertet wird als richtig nur, wenn der Richter in beiden Reihenfolgen die richtige Antwort wählt @tan2025judgebench. Raten ergibt 50 %.

#figure(
  balken((
    ([Prometheus 2 (beste Variante)], 40.29),
    ([GPT-4o, einfacher Prompt], 50.86),
    ([Feinabgestimmter Kritiker (Llama-3.1-70B)], 57.43),
    ([Reward-Modell (Gemma-2-27B)], 64.29),
    ([o3-mini, hoher Denkaufwand], 80.86),
  ), max: 100, breite: 7, einheit: " %", nachkomma: 1, farbe: c-teal),
  caption: [Genauigkeit auf JudgeBench; Zufall wäre 50 %. Dieselbe Arena-Hard-Prompt-Vorlage springt von 50,86 % auf 80,86 %, wenn ein Reasoning-Modell urteilt (Stand: 11. November 2026) @tan2025judgebench.],
)

=== Auch Menschen sind kein Goldstandard

Menschliche Urteile sind selbst verrauscht. Auf MT-Bench stimmen Menschen untereinander nur zu 63 % überein (mit Gleichständen), auf dem Vicuna-Benchmark liegt das durchschnittliche kappa der Annotatoren bei 0,54, und für hochwertige Zusammenfassungen kam Krippendorffs alpha auf nur 0,07 @zheng2023judging @wang2024large @liu2023geval. Berichte darum die Übereinstimmung der Menschen untereinander als Obergrenze für den Richter. Nimm objektive Labels, wo es sie gibt, und validiere mit den Experten, deren Urteil zählt: Richter passten besser zu Laien als zu Experten @bavaresco2025llms. Wenn mehrere Antworten gültig sind, sammle Mehrfachbewertungen statt einer erzwungenen Einzelwahl: Wer Richter anhand erzwungener Einzelwahl validiert, wählt Richter aus, die bis zu 31 % schlechter sind @guerdan2025validating.

== Bekannte Verzerrungen

#alltag[Ein Schiedsrichter pfeift im Heimspiel öfter für die Heimmannschaft. Nicht jedes Mal, aber oft genug, dass die Statistik schief aussieht. Pfeift er nur noch mehr Spiele, wird die Statistik nicht besser.]

Richter haben solche Gewohnheiten, und drei sind gut belegt @zheng2023judging @gu2024survey:

- *Positionsverzerrung (position bias):* Er mag eine Antwort, weil sie vorn oder hinten steht.
- *Längenverzerrung (verbosity bias):* Er belohnt Länge unabhängig vom Inhalt.
- *Selbstvorliebe (self-preference):* Er bevorzugt Texte, die seinen eigenen ähneln.

#studie(titel: [Position: Zheng, Wang, Shi])[
  Mit dem Standard-Prompt blieb nach dem Vertauschen nur bei 65,0 % der MT-Bench-Paare das Urteil von GPT-4 gleich, bei GPT-3.5 bei 46,2 %, bei Claude-v1 bei 23,8 %; Claude-v1 wählte in 75,0 % der Fälle die erste Antwort @zheng2023judging. Wang und Kollegen maßen die _Konfliktrate_, also den Anteil der Paare, deren Urteil sich beim Vertauschen ändert: 46,3 % für GPT-4 und 82,5 % für ChatGPT als Richter @wang2024large. Die Konflikte häufen sich bei fast gleich guten Paaren @shi2025judging.
]

Bei der Länge fielen Claude-v1 und GPT-3.5 in 91,3 % der Fälle auf eine Antwort herein, die mit einer wiederholten Liste aufgebläht war, GPT-4 nur in 8,7 % @zheng2023judging. Schon der Auftrag "sei ausführlicher" verschob die rohe Gewinnrate eines Modells bei AlpacaEval von 22,9 % auf 64,3 % @dubois2024length. Auch Überschriften, Fettdruck und Listen beeinflussen Richter @li2025crowdsourced.

Zur Selbstvorliebe: GPT-4 erkannte eigene Zusammenfassungen in 73,5 % der Fälle, und seine paarweise Selbstvorliebe lag bei 0,705 (XSUM) und 0,912 (CNN). Vertauschte man die Quellenangaben ("von dir" gegen "von einem anderen"), fiel sie von 0,73 auf 0,32 @panickssery2024llm. In Rangfolgen: Ein GPT-4-Richter stellte eine GPT-4-Variante auf Platz 2 statt 4 @verga2024replacing, und ein GPT-4-Turbo-Richter bevorzugte GPT-Modelle gegenüber Claude @li2025crowdsourced. Es gibt einen Vorbehalt: Wenn die Menschen selbst uneinig sind, kann "LLM-Text wird bevorzugt" auch echte Qualität sein.

=== Den Richter prüfen: Antworten vertauschen und erneut bewerten

Alle drei Verzerrungen kannst du mit demselben Trick testen: Ändere genau eine Sache und bewerte erneut. Wandert das Urteil mit, hast du die Verzerrung gefunden.

- *Position:* Zeige jedes Paar in beiden Reihenfolgen und zähle, wie oft das Urteil kippt.
- *Länge:* Blähe eine Antwort mit Füllmaterial auf und sieh nach, ob ihre Punktzahl steigt.
- *Selbstvorliebe:* Blende Modellnamen aus und vergleiche, wie der Richter eigene und fremde Modelle bewertet; nimm einen Richter aus einer anderen Modellfamilie.

#figure(
  diagram(
    spacing: (6mm, 8mm), node-corner-radius: 3pt,
    fknoten((0, 0.5), [Paar aus \ Antwort A und B], w: 30mm),
    fknoten((1, 0), [Richter: A steht vorn], col: c-blue, filled: true, w: 32mm),
    fknoten((1, 1), [Richter: B steht vorn], col: c-blue, filled: true, w: 32mm),
    fknoten((2, 0), [Urteil: vorderer \ Platz gewinnt], w: 34mm),
    fknoten((2, 1), [Urteil: vorderer \ Platz gewinnt], w: 34mm),
    fknoten((3, 0.5), [Platz statt Inhalt: \ Konflikt], col: c-red, filled: true, w: 30mm),
    edge((0, 0.5), (1, 0), "->", bend: 15deg), edge((0, 0.5), (1, 1), "->", bend: -15deg),
    edge((1, 0), (2, 0), "->"), edge((1, 1), (2, 1), "->"),
    edge((2, 0), (3, 0.5), "->", bend: 15deg), edge((2, 1), (3, 0.5), "->", bend: -15deg),
  ),
  caption: [Der Vertauschungstest: Gewinnt beide Male der vorderste Platz, entscheidet die Position und nicht die Antwort.],
)

#block(breakable: false)[#datei("swap_test.py")[
```python
def conflict_rate(pairs, judge):
    n = 0
    for q, a, b in pairs:
        v1 = judge(q, a, b)    # "A" oder "B": welcher Platz gewinnt
        v2 = judge(q, b, a)    # dasselbe Paar, vertauscht
        if v1 == v2:           # derselbe Platz zweimal: Konflikt
            n += 1
    return n / len(pairs)
```
]]

Das ist die Konfliktrate in sieben Zeilen. Das Rahmenwerk CALM führt solche Tests für 12 Verzerrungsarten durch (vertauschte Reihenfolge, falsche Referenz, "90 % der Menschen bevorzugen A" und weitere) @ye2025justice. Ein auffälliger Befund: Der in Position robusteste Richter war der anfälligste für die Wirkung der Mehrheit ("bandwagon").

#hoersaal(
  [Welche Konfliktrate ist akzeptabel?],
  [Es gibt keine offizielle Grenze. Berichte die Zahl, vergleiche mehrere Richter und schicke instabile Fälle an Menschen. Eine Konfliktrate von 46 % (GPT-4 bei Wang et al.) heißt, dass bei fast jedem zweiten Paar die Reihenfolge das Urteil mitbestimmt.],
)

Auch Menschen sind verzerrt, nur anders. Chen und Kollegen (142 Fragen, 60 Studierende, ein Dutzend LLMs) maßen die _Angriffserfolgsrate_, also den Anteil der Fälle, in denen die Präferenz zur manipulierten Antwort kippt; niedriger ist besser. Bei falschen Quellenangaben fielen Menschen zu 0,37 darauf herein, GPT-4 zu 0,66 und Claude-3 zu 0,70; bei Emojis und Markdown Menschen zu 0,47, GPT-4o aber nur zu 0,07 @chen2024humans.

== Gegenmaßnahmen

Die gute Nachricht: Gegen jede dieser Gewohnheiten gibt es ein einfaches Mittel. Die schlechte: Keines ersetzt die Prüfung des Richters gegen Menschen.

*Vertauschungsregel.* Frage zweimal mit vertauschten Plätzen und erkläre einen Sieg nur, wenn dieselbe Antwort beide Male gewinnt, sonst gilt Unentschieden @zheng2023judging. Das macht Positionsfehler sichtbar, statt sie zu verstecken. Der Preis: Ein stark verzerrter Richter erzeugt viele Unentschieden und liefert wenig Information, und du zahlst mindestens zwei Aufrufe pro Paar, das ist aber billig neben Menschen-Labels.

*Begründung zuerst, dann mitteln.* Wang und Kollegen ließen den Richter Belege schreiben, wiederholten das dreimal je Reihenfolge und mittelten die Punktzahlen über beide Reihenfolgen @wang2024large. Die Tabelle zeigt, was das auf 80 Fragen des Vicuna-Benchmarks bringt, gemessen gegen die Mehrheit von drei Menschen.

#figure(
  table(columns: (1fr, auto, auto),
    [Aufbau], [Treffer], [kappa],
    [GPT-4, einfacher Richter], [52,7 %], [0,24],
    [Begründung zuerst, vertauschen und mitteln], [62,5 %], [0,37],
    [Zusätzlich die 20 % unsichersten Fälle an Menschen], [73,8 %], [0,56],
    [Durchschnittlicher Mensch], [71,7 %], [0,54],
  ),
  caption: [Aufbau eines Richters und Übereinstimmung mit der Mehrheit von Menschen @wang2024large.],
)

*Unsichere Fälle an Menschen.* Menschen sind teuer, also setzt du sie nur dort ein, wo der Richter selbst schwankt. Dazu lässt du ihn jedes Paar sechsmal bewerten (dreimal je Reihenfolge). Sind alle sechs Urteile gleich, vertraust du ihnen, sind sie gemischt, entscheidet ein Mensch.

#beispiel(titel: [Sechs Urteile])[
  Die Urteile lauten gewonnen, gewonnen, gewonnen, unentschieden, verloren, verloren. Das ist dreifach gespalten, also unsicher: ein Fall für einen Menschen. Sechsmal "gewonnen" würde beim Richter bleiben. Wang und Kollegen schickten die unsichersten 20 % der Fälle an Menschen, deren Mehrheit das Urteil ersetzte, und kamen so auf die 73,8 % in der Tabelle. Der Gesamtpreis wurde auf 23,1 US-Dollar geschätzt, gegenüber 30,0 US-Dollar bei rein menschlicher Bewertung.
]

*Längenkontrolle.* AlpacaEval fragt: Wie wäre die Gewinnrate, wenn beide Antworten gleich lang wären? Das Ergebnis heißt _length-controlled win rate_. Wird dasselbe Modell angewiesen, ausführlicher zu sein, schwankt die rohe Gewinnrate zwischen 22,9 % und 64,3 %, die längenkorrigierte nur zwischen 41,9 % und 51,6 %. Die Übereinstimmung mit der Chatbot Arena stieg von 0,94 auf 0,98 (Rangkorrelation, 38 Modelle) @dubois2024length. Arena-Hard ergänzt eine Kontrolle für Überschriften, Fettdruck und Listen @li2025crowdsourced. Du musst das nicht selbst bauen: Nutze die längen- oder stilkorrigierten Werte, die diese Benchmarks veröffentlichen. Die Kehrseite: Die Korrektur nimmt auch einen echten Nutzen längerer Antworten heraus.

*Panel statt Einzelrichter.* Verga und Kollegen nahmen drei kleine Modelle aus verschiedenen Familien (Command R, Claude 3 Haiku, GPT-3.5) und ließen sie abstimmen. Auf NQ erreichte das Panel kappa 0,763 (GPT-4 allein 0,627), auf TriviaQA 0,906 (0,841), auf HotpotQA 0,867 (0,830), bei sieben- bis achtmal geringeren Kosten als ein GPT-4-Turbo-Richter. Nicht überall: Claude 3 Haiku allein kam auf HotpotQA auf 0,873 @verga2024replacing. PoLL ist ein Industrie-Preprint, seine Preise sind veraltet (Stand: 11. November 2026).

*Trainierte und denkende Richter.* Sie schlagen größere Modelle auf manchen Benchmarks, nicht auf allen: RM-R1 (Qwen-32B) erreicht 91,4 gegenüber 86,7 für GPT-4o auf RewardBench, J1-70B aber nur 60,0 gegenüber 68,9 für DeepSeek-R1 auf JudgeBench @chen2026rmr1 @whitehouse2026j1. Die Arbeitshypothese: Denken hilft dort, wo man die Aufgabe selbst lösen muss, um sie zu beurteilen.

== Statistische Grenzen

=== Richter-Labels sind nur ein Stellvertreter

Verwendest du Richter-Punkte als Ergebnis ("System A beantwortet 70 % richtig"), benutzt du einen Stellvertreter für die Wahrheit, und der hat Gewohnheiten: Er ist zu nachsichtig, mag Länge, mag den eigenen Stil. Ein Richter mit über 90 % Übereinstimmung kann die vergebene Punktzahl um mehr als 10 Punkte verfehlen @thakur2025judging. Mehr Richter-Labels verkleinern das Zufallsrauschen, nicht den eingebauten Fehler. Die Abhilfe: eine kleine, zufällig gezogene Menge menschlicher Labels als Korrekturgrundlage zu behalten und mit Verfahren wie _prediction-powered inference_ (PPI) zu korrigieren; das ist der Inhalt von Kapitel 6 @dorner2025limits.

=== Die Faktor-zwei-Grenze

#alltag[Du lässt eine Aushilfe 1000 Klausuren vorkorrigieren, die selbst nicht besser ist als die Studierenden, die die Klausuren geschrieben haben. Du musst trotzdem stichprobenartig nachkorrigieren. Die Hilfe spart weniger, als der erste Eindruck verspricht.]

Dorner, Nastl und Hardt (ICLR 2025) zeigten: Ein Richter, der nicht besser ist als das bewertete Modell, spart dir höchstens etwa die Hälfte der menschlichen Labels @dorner2025limits. Das ist die _Faktor-zwei-Grenze_.

#figure(
  balken((
    ([Nur Menschen-Labels], 1000),
    ([Mit Richter, günstigstenfalls], 500),
  ), max: 1000, breite: 8, einheit: " Labels", nachkomma: 0, farbe: c-violet),
  caption: [Menschen-Labels, die für dieselbe Genauigkeit nötig sind. Ohne Richter 1000, mit Richter mindestens etwa 500.],
)

Wenn du die Genauigkeit von 1000 reinen Menschen-Labels erreichen willst, brauchst du auch mit Richter noch mindestens etwa 500 Menschen-Labels. Das Kleingedruckte: Die Grenze gilt für Ja/Nein-Werte und für Korrekturverfahren, die selbst keine Verzerrung mitbringen, wie PPI. Hohe Übereinstimmung allein garantiert keinen Gewinn. Größere Einsparungen gibt es nur, wenn die Beurteilungsaufgabe viel leichter ist als die bewertete. Gemessen blieb der Gewinn bei MMLU und MT-Bench unter 2, meist deutlich darunter, mit einer Ausnahme: Spitzenrichter, die das viel schwächere Llama-2-7B bewerteten @dorner2025limits.

=== Würde es auffallen? Der Alternative Annotator Test

Die zweite Frage lautet: Darf ich das LLM als Ersatz für einen meiner menschlichen Annotatoren einsetzen? Calderon, Reichart und Dror beantworten sie mit dem _Alternative Annotator Test_ (kurz Alt-Test) @calderon2025alternative. Er fragt: Würde es auffallen, wenn man einen der menschlichen Annotatoren durch das LLM ersetzt?

#figure(
  diagram(
    spacing: (7mm, 0mm), node-corner-radius: 3pt,
    fknoten((0, 0), [Labels von \ mindestens \ 3 Menschen], col: c-blue, filled: true, w: 34mm),
    fknoten((1, 0), [Einen Menschen \ weglassen, für \ jeden wiederholen], w: 36mm),
    fknoten((2, 0), [Liegt das LLM so nah \ an den anderen wie \ dieser Mensch?], w: 40mm),
    fknoten((3, 0), [Bestanden, wenn bei \ mindestens der \ Hälfte ja], col: c-blue, filled: true, w: 34mm),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"),
  ),
  caption: [Der Alt-Test als Ablauf. Das LLM wird so behandelt wie ein weiterer Annotator.],
)

Du brauchst Labels von mindestens drei Menschen auf 50 bis 100 Items. Immer ein Mensch wird weggelassen, und du prüfst, ob das LLM den übrigen Menschen mindestens so nahe kommt wie der weggelassene. Das LLM darf dabei ein wenig schlechter sein, weil es billiger ist; diese erlaubte Nachsicht legst du vor dem Test fest (die Autoren nennen 0,2 für Experten, 0,15 für geübte Annotatoren, 0,1 für Crowd-Arbeiter). Die Gewinnrate ist der Anteil der Menschen, gegen die das LLM besteht. Bei 4 Annotatoren und 3 bestandenen Vergleichen ist sie 0,75. Ab 0,5 gilt der Test als bestanden. Der Code der Autoren liegt unter github.com/nitaytech/alttest; eine Lizenz ist dort nicht angegeben (Stand: 11. November 2026).

Mindestens ein LLM bestand bei 9 von 10 Datensätzen. Ohne Beispiele (zero-shot) bestand auf MT-Bench und SummEval keines. Few-Shot-Beispiele halfen meist, Schritt-für-Schritt-Denken schadete oft @calderon2025alternative.

== Arenen und Ranglisten

#alltag[Beim Schach spielt nicht jeder gegen jeden, und trotzdem gibt es eine Rangliste. Aus Tausenden einzelner Partien wird für jeden Spieler eine Spielstärke geschätzt, und wer gegen starke Gegner gewinnt, steigt schneller.]

Die Chatbot Arena macht dasselbe mit Sprachmodellen: Nutzer stellen eine Frage, sehen zwei anonyme Antworten und stimmen ab. Im Januar 2024 waren es 243.329 Stimmen von 90.051 Nutzern für 50 Modelle. GPT-4 als Richter stimmte mit der Menge in 75,6 % der Fälle überein; Menge und Experten stimmten zu 72,8 % bis 83,1 % überein @chiang2024chatbot. Aus den Paarkämpfen schätzt man mit dem _Bradley-Terry-Modell_ eine Stärke je Modell. Es ersetzte das frühere Elo-Verfahren, das nach jeder Partie nachjustiert, weil Bradley-Terry sich besser zum statistischen Schätzen eignet @chiang2024chatbot. Für die Unsicherheit ordnet man die Modelle immer wieder neu, mit zufällig neu gezogenen Stimmen (_bootstrap_). Bleibt ein Modell dabei fast immer auf seinem Platz, kannst du dem Platz trauen. Sonst ist er eine Spanne und kein fester Wert; diese _Fehlerspanne_ ist ein Konfidenzintervall (siehe _Das Nötigste vorab_).

#figure(
  table(columns: (1fr, auto, auto, auto),
    [Benchmark], [Separability], [Übereinstimmung mit Konfidenz], [Rangkorrelation],
    [Arena-Hard-Auto], [87,4 %], [90,9 %], [93,2 %],
    [AlpacaEval 2.0 (längenkorrigiert)], [83,2 %], [82,5 %], [91,9 %],
    [MT-Bench], [22,6 %], [26,6 %], [89,9 %],
  ),
  caption: [Rangkorrelation unterscheidet die Benchmarks kaum, Separability schon @li2025crowdsourced.],
)

Die _Separability_ ist der Anteil der Modellpaare, deren Fehlerspannen sich nicht überlappen, bei denen die Reihenfolge also klar ist.

#beispiel(titel: [45 Modellpaare])[
  Zehn Modelle ergeben 45 Paare. Bei 39 davon überlappen die 95-Prozent-Fehlerspannen nicht: 39 von 45, das sind 86,7 % Separability. MT-Bench schafft nur 22,6 % und ist damit als Benchmark deutlich schwächer, obwohl seine Rangkorrelation mit 89,9 % gut aussieht.
]

Auch die Rangliste selbst lässt sich beeinflussen. Singh und Kollegen werteten rund 2 Millionen Kämpfe von 243 öffentlichen Modellen aus 42 Anbietern aus (Januar 2024 bis April 2025). Ein Anbieter habe vor einer Veröffentlichung 27 private Varianten getestet, 205 von 243 öffentlichen Modellen seien still ausgemustert worden (offiziell gelistet: 47), und zwei identische Modellstände (_checkpoints_) erhielten die Werte 1069 und 1052; das Testen von 10 Varianten bringe in einer Simulation etwa 100 Punkte @singh2025leaderboard. Die Arena antwortete in einem nicht begutachteten Blogbeitrag: etwa 11 Punkte nach 50 Tests mit 3000 Stimmen, überlappende Fehlerspannen bei den Prüfpunkten, und 40,9 % Anteil offener Modelle an der Rangliste, was nicht dieselbe Größe ist wie die 29,7 % der Kampfdaten @lmarena2025response. Beide Seiten stimmen überein, dass das Veröffentlichen nur der besten privaten Variante die Werte im Erwartungswert aufbläht; sie streiten über das Ausmaß. Die Zahlen stammen aus arXiv-Fassungen; die NeurIPS-Fassung kann abweichen.

== In der Praxis: Einen Richter prüfen, bevor du ihm traust

Diese Reihenfolge ist ein Vorschlag für die Methodik einer Arbeit; sie fasst die Belege dieses Kapitels zusammen. Jeder Schritt kann in den Methodenteil.

+ *Kriterien festlegen.* Schreibe sie je Dimension auf, bewerte 20 oder mehr Antworten selbst und friere sie dann ein.
+ *Format und Referenz wählen.* Paarweise zum Vergleichen, Rubrik für absolute Qualität, geprüfte Referenz bei Aufgaben mit richtiger Antwort.
+ *Prompt bauen.* Rubrik, kurze Skala, Begründung zuerst, JSON.
+ *Validierungsstichprobe ziehen.* Zufällig, 50 bis 100 oder mehr Items, mindestens drei Menschen mit passender Fachkenntnis.
+ *Übereinstimmung messen.* Kappa oder alpha mit Vierfeldertafel; bei Punktzahlen Rangkorrelation und mittlere Abweichung. Berichte die Übereinstimmung der Menschen als Obergrenze.
+ *Verzerrungen prüfen.* Vertauschen, auffüllen, Familie wechseln, Nachsicht berechnen.
+ *Gegenmittel einsetzen und entscheiden.* Vertauschungsregel, Menschen für die unsicheren Fälle, Panel, Stilkontrolle; dann Alt-Test.
+ *Schwierige Fälle testen.* Items mit nachweislich richtigen Antworten.
+ *Unsicherheit angeben und korrigieren.* Fehlerspannen für Ranglisten, PPI für Anteile (Kapitel 6), höchstens etwa halbe Ersparnis bei Labels.
+ *Berichten.* Modell und Version, Prompt, Einstellungen, Stichprobe, Kennzahlen mit Spannen, Verzerrungstests, Kosten.

Welche Werkzeuge es gibt (Stand: 11. November 2026): Das Paket `prometheus-eval` (Version 0.1.20) bringt die Prometheus-2-Richter mit; `inspect-ai` (0.3.289) hat Bewerter für Modell-bewertete Fragen; `deepeval` (4.3.3) enthält ein G-Eval-Maß. AlpacaEval und Arena-Hard-Auto sind fertige Richter-Benchmarks; Arena-Hard-Auto reproduziert die Menschen-Rangliste mit einer Rangkorrelation von 93,2 % für etwa 20 US-Dollar @li2025crowdsourced. Die Versionen stammen aus den PyPI-Seiten.

#block(breakable: false)[#datei("pruefe_richter.py")[
```python
import numpy as np
from sklearn.metrics import cohen_kappa_score

def pruefe_richter(human, judge, v_ab, v_ba):
    human, judge = np.asarray(human), np.asarray(judge)
    fp = ((judge == 1) & (human == 0)).sum()
    fn = ((judge == 0) & (human == 1)).sum()
    return {"prozent": (human == judge).mean(),
            "kappa": cohen_kappa_score(human, judge),
            "nachsicht": fp / max(fp + fn, 1),
            "konflikt": np.mean(np.asarray(v_ab) != np.asarray(v_ba))}
```
]]

Im Notebook `notebooks/07_judge_validation.ipynb` prüfst du einen _simulierten_ Richter auf künstlichen Daten, bei denen die Wahrheit bekannt ist; du siehst Kappa-Beispiel, Positionsaudit, Alt-Test und die Faktor-zwei-Grenze.

#fallstrick[Du validierst den Richter auf menschlich geschriebenen Texten und setzt ihn später auf Modelltexte an. Bavaresco und Kollegen zeigen, dass Richter bei beiden unterschiedlich gut sind @bavaresco2025llms. Validiere auf Daten, die deinem Zielmaterial gleichen.]

== Für die Lehre

*"90 % Übereinstimmung ist doch super."* Das hängt von der Verteilung ab: Sagen beide fast immer "richtig", ist viel Übereinstimmung Zufall. Rechne das Beispiel mit den 100 Antworten durch und zeige, dass aus 80 % ein kappa von 0,53 wird.

*"Ein besseres Modell als Richter löst das Problem."* Stärkere Richter schneiden besser ab, aber Verzerrungen verschwinden nicht, und ein Richter kann dieselben blinden Flecken wie das System haben. Zeige JudgeBench: GPT-4o liegt bei 50,86 %.

*"Wenn der Richter die richtige Rangfolge liefert, stimmen auch die Einzelurteile."* Nein. Das Beispiel mit der Zeichenkette-Suche (pi 0,64, Rangkorrelation 0,99) zeigt den Unterschied zwischen Einzel- und Systemebene.

*"Der Richter spart mir 90 % der Labels."* Bei einem Richter, der nicht besser ist als das bewertete Modell, höchstens etwa die Hälfte @dorner2025limits.

*"Menschen sind der Goldstandard."* Sie sind der Anker, aber verrauscht: 63 % Übereinstimmung auf MT-Bench, alpha 0,07 bei Zusammenfassungen. Berichte die Übereinstimmung unter Menschen als Obergrenze.

#hoersaal(
  [Warum nicht einfach einen Richter aus derselben Modellfamilie nehmen wie das System, das ich bewerte?],
  [Weil Richter ihre eigenen Texte bevorzugen: GPT-4 erkannte seine Zusammenfassungen in 73,5 % der Fälle, und die Selbstvorliebe fiel von 0,73 auf 0,32, wenn die Quellenangaben vertauscht wurden @panickssery2024llm. Nimm einen Richter aus einer anderen Familie oder ein Panel aus mehreren.],
)

#hoersaal(
  [Welches kappa brauche ich mindestens?],
  [Eine feste Grenze gibt es nicht. Die Bänder von Landis und Koch sind eine Konvention @Landis1977. Entscheidend ist, was bei einem Fehler passiert, und wie stark die Menschen untereinander übereinstimmen. Ein Richter, der unter der Übereinstimmung der Menschen liegt, braucht Begründung.],
)

#kurz(
  [Ein Richter ist ein Messgerät mit Fehlern in fester Richtung; mehr bewertete Antworten machen sie nicht kleiner.],
  [Ein guter Judge-Prompt hat Rubrik, kurze Skala, Begründung zuerst und lesbare Ausgabe wie JSON.],
  [Prozent-Übereinstimmung täuscht; berichte kappa mit Vierfeldertafel, die Nachsicht und als Obergrenze die Übereinstimmung der Menschen.],
  [Position, Länge und Selbstvorliebe testest du, indem du eine Sache änderst, etwa die Reihenfolge, und erneut bewertest.],
  [Gegenmittel sind Vertauschungsregel, Begründung zuerst, Menschen für unsichere Fälle, Längenkontrolle und Panels; keines ersetzt die Validierung.],
  [Ein Richter, der nicht besser ist als das bewertete Modell, spart höchstens etwa die Hälfte der Labels; der Alt-Test fragt, ob er als Annotator durchgeht.],
  [Eine Rangliste ist eine Schätzung mit Spanne; Separability sagt mehr als eine hohe Rangkorrelation.],
)

#selbsttest(
  ([Warum können zwei Beurteiler 90 % Übereinstimmung haben und trotzdem ein schwaches kappa?], [Wenn beide fast immer dieselbe Antwort geben, stimmen sie schon durch Zufall oft überein. Kappa rechnet diesen Zufall heraus.]),
  ([Was misst die Konfliktrate, und wie bestimmst du sie?], [Den Anteil der Paare, deren Urteil sich beim Vertauschen ändert. Jedes Paar in beiden Reihenfolgen zeigen und zählen, wo derselbe Platz gewinnt.]),
  ([Warum hilft eine selbst erzeugte Referenz dort nicht, wo der Richter die Aufgabe nicht lösen kann?], [Er erzeugt dann dieselbe falsche Lösung als Referenz und bestätigt sie (kappa 0,16 gegenüber 0,83 mit menschlicher Referenz).]),
  ([Was bedeutet die Faktor-zwei-Grenze in einem Satz?], [Ein Richter, der nicht besser ist als das bewertete Modell, spart höchstens etwa die Hälfte der menschlichen Labels.]),
  ([Wie läuft der Alt-Test ab?], [Einen von mindestens drei Menschen weglassen, prüfen, ob das LLM den übrigen so nahe kommt wie er, für jeden wiederholen, Gewinnrate zählen; ab 0,5 bestanden.]),
  ([Warum reicht eine hohe Rangkorrelation nicht, um einzelne Labels zu rechtfertigen?], [Sie sagt nur, dass die Reihenfolge der Systeme stimmt; die Zeichenkette-Suche hat pi 0,64 pro Antwort und trotzdem 0,99 Rangkorrelation.]),
)

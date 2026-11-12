#import "../lib.typ": *

// Lokale Plot-Helfer (nur in diesem Kapitel)
#let k07-rot = rotate
#let k07-hs(frage, antwort) = block(breakable: false, width: 100%, hoersaal(frage, antwort))
#let k07-tx(s, size: 7pt, fill: c-dark, weight: "regular") = text(font: "Inter", size: size, fill: fill, weight: weight, s)
#let k07-plot(w: 8, h: 4.2, x: (0, 1), y: (0, 1), xt: (), yt: (), xl: [], yl: [], xfmt: none, yfmt: none, body) = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let (x0, x1) = x
  let (y0, y1) = y
  let sx(v) = (v - x0) / (x1 - x0) * w
  let sy(v) = (v - y0) / (y1 - y0) * h
  for t in yt {
    line((0, sy(t)), (w, sy(t)), stroke: 0.3pt + luma(225))
    content((-0.1, sy(t)), anchor: "east", k07-tx(if yfmt == none { str(t) } else { yfmt(t) }))
  }
  for t in xt {
    line((sx(t), 0), (sx(t), -0.07), stroke: 0.6pt + c-dark)
    content((sx(t), -0.14), anchor: "north", k07-tx(if xfmt == none { str(t) } else { xfmt(t) }))
  }
  line((0, 0), (w, 0), stroke: 0.7pt + c-dark)
  line((0, 0), (0, h), stroke: 0.7pt + c-dark)
  content((w / 2, -0.72), k07-tx(xl, size: 7.5pt))
  content((-0.95, h / 2), k07-rot(-90deg, reflow: true, k07-tx(yl, size: 7.5pt)))
  body(sx, sy)
})
#let k07-kurve(pts, sx, sy, col: c-blue, dash: none, th: 1.2pt) = {
  import cetz.draw: *
  line(..pts.map(p => (sx(p.at(0)), sy(p.at(1)))), stroke: (paint: col, thickness: th, dash: dash))
}

= LLM-as-a-Judge <k07>

Kaum eine Methode hat sich in der LLM-Forschung so schnell durchgesetzt wie die Idee, ein Sprachmodell die Ausgaben eines anderen Systems bewerten zu lassen. Offene Ausgaben wie Chat-Antworten, Zusammenfassungen, Erklärungen, Code-Reviews oder RAG-Antworten haben keine einzelne richtige Referenz. Überlappungsmetriken wie BLEU und ROUGE korrelieren deshalb nur schwach mit menschlichen Urteilen, besonders bei kreativen Aufgaben @liu2023geval. Menschliche Bewertung ist langsam und teuer. Starke LLMs wurden als "skalierbare und erklärbare" Annäherung an menschliche Präferenzen vorgeschlagen: GPT-4 erreichte auf MT-Bench über 80 % Übereinstimmung mit menschlichen Präferenzen und lag damit auf dem Niveau der Übereinstimmung zwischen Menschen @zheng2023judging[Abstract, Tab. 5]. Inzwischen steckt der LLM-Richter (_LLM-as-a-Judge_) mitten in der sichtbarsten Evaluationsinfrastruktur des Felds: Arena-Hard-Auto und AlpacaEval ranken Modelle mit LLM-Richtern @li2025crowdsourced @dubois2024length, und Benchmarks für Reward-Modelle bewerten generative Richter Seite an Seite mit trainierten Reward-Modellen @lambert2025rewardbench[Tab. 7] @malik2026rewardbench[Tab. 3].

Für dich als Forscher ist ein LLM-Richter vor allem eines: ein *Messinstrument*. Seine Urteile sind Labels mit Fehler, und dieser Fehler ist nicht gleichmäßig verteilt. Richter sind bei manchen Aufgaben verlässlich und bei anderen nicht, abhängig von der bewerteten Eigenschaft, der Expertise der menschlichen Referenzannotatoren und davon, ob der bewertete Text von Menschen oder Modellen stammt. Die Autoren der größten Mehrfachaufgaben-Studie ziehen daraus den Schluss, dass LLMs "sorgfältig gegen menschliche Urteile validiert werden" müssen, bevor man sie als Bewerter einsetzt @bavaresco2025llms[Abstract]. Auf schwierigen Items mit objektiv richtiger Antwort liegen selbst starke Richter nahe am Zufall: Ein GPT-4o-Richter erreichte 50.86 % auf JudgeBench-Paaren, bei denen Raten 50 % ergibt @tan2025judgebench[Tab. 1]. Und der statistische Ertrag ist begrenzt: Unter klar benannten Annahmen kann kein unverzerrter Schätzer die Zahl der benötigten Ground-Truth-Labels durch Richterlabels um mehr als die Hälfte reduzieren @dorner2025limits[Thm. 6, Kor. 7].

Dieses Kapitel verbindet drei Fäden des Buchs. Die Validitäts- und Reliabilitätsbegriffe aus Kapitel 4, die Übereinstimmungsstatistik aus Kapitel 5 und die valide Inferenz mit wenigen menschlichen und vielen maschinellen Labels aus Kapitel 6 (Prediction-Powered Inference, PPI) laufen hier zusammen. Am Ende steht ein Validierungsprotokoll, das du in eigenen Studien und in betreuten Masterarbeiten direkt anwenden kannst. Begleitend gibt es Foliensatz 07 der LV und das Notebook `notebooks/07_judge_validation.ipynb`, das einen simulierten Richter mit kontrollierbaren Verzerrungen validiert.

#lernziele[
  punktweise, paarweise und listenweise Bewertung sowie Referenz-, Rubrik- und Checklistenstrategien unterscheiden und für eine Aufgabe begründet auswählen,
][
  Prozentübereinstimmung, Cohens Kappa, Scotts Pi, Nachsichtigkeit $P_+$, Rangkorrelationen, Positionskonsistenz und Konfliktrate für einen Richter berechnen und interpretieren,
][
  die Befunde von MT-Bench, Judging the Judges, JUDGE-BENCH und JudgeBench einordnen und erklären, warum sie scheinbar widersprüchlich sind,
][
  Positions-, Längen- und Selbstpräferenz-Bias sowie die CALM-Taxonomie mit konkreten Messverfahren und Formeln prüfen,
][
  Gegenmaßnahmen (Vertauschen, Längenkontrolle, Panels, feinjustierte und Reasoning-Richter) nach Wirkung und Kosten vergleichen,
][
  die Schranke $tau <= 1 \/ (1 - rho^2)$ herleiten, die Faktor-zwei-Aussage von Dorner et al. mit ihren Annahmen wiedergeben und den Alternative-Annotator-Test anwenden,
][
  das Bradley-Terry-Modell herleiten, schätzen und mit Konfidenzintervallen versehen sowie die Debatte um die "Leaderboard Illusion" ausgewogen darstellen,
][
  ein vollständiges Validierungsprotokoll für einen LLM-Richter in einer eigenen Studie entwerfen und berichten.
]

== Der Richter als Messinstrument <k07-messinstrument>

=== Was ein LLM-Richter formal ist

Die Intuition ist einfach: Du gibst einem Sprachmodell das zu bewertende Objekt, eine Aufgabenbeschreibung und Bewertungskriterien, und es liefert ein Urteil. Gu et al. fassen das in eine knappe Definition, die du dir merken solltest, weil sie die Stellschrauben sichtbar macht @gu2024survey[Abschn. 2].

#definition(titel: [LLM-as-a-Judge nach Gu et al.])[
  Ein LLM-Richter erzeugt ein Bewertungsergebnis
  $ cal(E) <- P_"LLM" (x plus.o cal(C)) $ <k07-eq-gu>
  Dabei ist $cal(E)$ das Ergebnis (Punktwert, Auswahl, Label oder Satz), $P_"LLM"$ das autoregressive Modell, $x$ das bewertete Objekt, $cal(C)$ der Kontext (Prompt-Vorlage, Rubrik, Dialogverlauf) und $plus.o$ der Operator, der $x$ in $cal(C)$ einsetzt. Die zuverlässigkeitsorientierte Variante lautet $cal(R) <- f_R (P_"LLM", x, cal(C))$; $f_R$ bündelt Nebenbedingungen und Prüfverfahren (Bias-Minderung, Varianzkontrolle, Robustheitstests), und $cal(R)$ ist ein auf Konsistenz und Übereinstimmung mit Menschen geprüftes Urteil @gu2024survey[Abschn. 2].
]

Li et al. schreiben den Richter als Funktion über Kandidaten, $R = J(C_1, dots, C_n)$, mit dem Richtermodell $J$, dem $i$-ten Kandidaten $C_i$ und dem Urteil $R$ @li2025generation[Abschn. 2.1]. Diese Schreibweise ist nützlich, weil $n$ sofort die Eingabeform festlegt: $n = 1$ ist punktweise, $n = 2$ paarweise, $n > 2$ listenweise Bewertung. Die Ausgabe kann ein Punktwert je Kandidat, eine Rangfolge oder die Auswahl der besten Teilmenge sein @li2025generation[Abschn. 2.2].

@k07-eq-gu wirkt banal, ist aber methodisch aufschlussreich. Alles, was in $cal(C)$ steht, ist Teil des Messinstruments: die Formulierung der Kriterien, die Reihenfolge der Kandidaten, die Referenzantwort, ob Modellnamen sichtbar sind, und die Dekodierungseinstellungen von $P_"LLM"$. Wer "wir haben GPT-4o als Richter verwendet" schreibt, hat das Instrument also erst zu einem kleinen Teil beschrieben. Das Messinstrument ist das Tripel aus Modell (inklusive Version), Kontext und Aggregationsregel.

#figure(
  diagram(spacing: (7mm, 9mm), node-stroke: none,
    fknoten((0, 0), [Bewertetes Objekt $x$ \ (Antwort, Zusammenfassung, Code)], col: c-grey, w: 32mm),
    fknoten((0, 1), [Kontext $cal(C)$ \ Kriterien, Rubrik, Referenz, Reihenfolge], col: c-grey, w: 32mm),
    fknoten((1, 0.5), [Richtermodell $P_"LLM"$ \ Version, Temperatur, Stichproben $k$], col: c-blue, filled: true, w: 34mm),
    fknoten((2, 0.5), [Rohurteil $cal(E)$ \ Score, Wahl, Label, Begründung], col: c-teal, w: 30mm),
    fknoten((3, 0.5), [Prüfverfahren $f_R$ \ Vertauschen, Längenkontrolle, Panel], col: c-violet, w: 30mm),
    fknoten((3, 1.55), [Validierung gegen Menschen \ oder objektive Korrektheit], col: c-accent, filled: true, w: 34mm),
    fknoten((1.5, 1.55), [Forschungsaussage \ (Schätzer mit Unsicherheit)], col: c-green, w: 34mm),
    edge((0, 0), (1, 0.5), "-|>"),
    edge((0, 1), (1, 0.5), "-|>"),
    edge((1, 0.5), (2, 0.5), "-|>"),
    edge((2, 0.5), (3, 0.5), "-|>"),
    edge((3, 0.5), (3, 1.55), "-|>"),
    edge((3, 1.55), (1.5, 1.55), "-|>", text(font: "Inter", size: 7pt)[Korrektur (Kap. 6)], label-side: right, label-sep: 2pt),
  ),
  caption: [Der LLM-Richter als Messinstrument. Modell, Kontext und Prüfverfahren bilden gemeinsam das Instrument; erst die Validierung gegen eine Referenz und die statistische Korrektur machen aus Rohurteilen eine belastbare Forschungsaussage (Notation nach @gu2024survey).],
) <k07-fig-instrument>

=== Warum die Messperspektive zählt

Im Lehrbuch zur Forschungsmethodik wird jede Evaluationsmetrik als *Operationalisierung* behandelt: als konkretes, berechenbares Verfahren, das für eine abstrakte Eigenschaft steht, die kein Verfahren vollständig erfasst @haindl2027research. Ein LLM-Richter ist eine besonders flexible Operationalisierung, und genau darin liegt seine Gefahr. Wenn ein Richter "Hilfsbereitschaft" bewertet, misst er vielleicht in Wahrheit Länge, Formatierung oder Ähnlichkeit zum eigenen Stil. Optimiert man dann auf diesen Score, verbessert man den Stellvertreter auf Kosten des Konstrukts, das messtechnische Gegenstück zum Lernen für den Test @haindl2027research.

Hinzu kommt ein erkenntnistheoretisches Problem, das das Lehrbuch als *zirkuläre Validierung* bezeichnet: Menschliches Urteil, der übliche Goldstandard, ist teuer, zwischen Annotatoren inkonsistent und an der Forschungsfront manchmal gar nicht verfügbar. Wer ein starkes Modell zum Richter über ein anderes Modell macht, riskiert, dass der Richter genau die blinden Flecken des bewerteten Systems erbt @haindl2027research. Ein Positionspapier auf der NeurIPS 2025 formuliert dieselbe Kritik messtheoretisch: Vier Annahmen hinter LLM-Richtern (Stellvertreter für Menschen, fähige Bewerter, Skalierbarkeit, Kosteneffizienz) seien unzureichend geprüft, der aktuelle Enthusiasmus sei "verfrüht" @chehbouni2025neither[Abstract].

#merke[
  Ein LLM-Richter ist ein Messinstrument mit Fehler. Du beschreibst ihn vollständig (Modell und Version, Prompt, Dekodierung, Aggregation), validierst ihn *pro Aufgabe* gegen eine Referenz und behandelst seine Scores in der Auswertung als fehlerbehaftete Proxy-Messung, nicht als Wahrheit @bavaresco2025llms @chehbouni2025neither.
]

=== Was für Richter es gibt

Im Feld haben sich mehrere Richtertypen etabliert, die du auseinanderhalten solltest, weil sie sich in Kosten, Reproduzierbarkeit und Validität unterscheiden.

- *Geprompte Allzweck-LLMs*: GPT-4 in MT-Bench, GPT-4-Turbo in Arena-Hard-Auto @zheng2023judging @li2025crowdsourced[Abschn. 5].
- *Feinjustierte offene Richter*: Modelle, die auf Urteilsdaten trainiert wurden, etwa JudgeLM (7B bis 33B, 100 000 GPT-4-Urteile) @zhu2025judgelm[Abstract], Prometheus (13B) @kim2024prometheus und Prometheus 2 (7B und 8x7B, durch Gewichtsverschmelzung aus einem Direktbewertungs- und einem Paarvergleichsmodell) @kim2024prometheus2[Abschn. 3.4].
- *Panels oder Jurys*: mehrere kleinere Richter aus verschiedenen Modellfamilien, aggregiert durch Mehrheitsentscheid oder Mittelung (PoLL) @verga2024replacing.
- *Reward-Modelle*: Modelle, die (Prompt, Antwort) auf einen skalaren Reward abbilden. RewardBench bewertet Klassifikator-RMs, implizite DPO-Rewards und generative Richter mit derselben Genauigkeitsmetrik @lambert2025rewardbench.
- *Reasoning-Richter*: Reasoning-Modelle als Richter, sowie Richter, die per Reinforcement Learning zum "Nachdenken" trainiert wurden (EvalPlanner, J1, RM-R1) @saha2025learning @whitehouse2026j1 @chen2026rmr1.
- *Agent-as-a-Judge*: ein agentisches System, das ein anderes agentisches System mit Zwischenfeedback bewertet @zhuge2025agent[Abstract].

=== Richter für Treue und Halluzinationen

Ein Anwendungsfall, der in deiner eigenen Forschung zu LLM-gestützter Literaturarbeit besonders häufig auftritt, ist die Prüfung von *Treue* (_faithfulness_). Das Lehrbuch trennt drei Begriffe, die oft vermischt werden: Treue ist die Konsistenz mit einer gegebenen Quelle, Faktizität (_factuality_) die Übereinstimmung mit der Welt, und Halluzination ist Generierung ohne Verankerung, also Ausgabe, die weder durch den Kontext noch durch Fakten gestützt ist @haindl2027research. Ein Modell kann einer falschen Quelle treu sein, und es kann eine wahre Aussage treffen, die nicht in der Quelle steht. Wer nicht entscheidet, welche Eigenschaft er misst, produziert uninterpretierbare Zahlen.

Viele Treuemetriken sind im Kern LLM-Richter mit enger Aufgabe. Der anspruchsbasierte Ansatz zerlegt eine Ausgabe in atomare Aussagen und prüft jede gegen die Quelle; RAGAS operationalisiert Treue als Anteil gestützter Aussagen @haindl2027research:
$ F = (|C_"supported"|) / (|C_"total"|) $ <k07-eq-ragas>
Hier ist $C_"total"$ die Menge der extrahierten atomaren Aussagen und $C_"supported"$ die Teilmenge, die von der Quelle impliziert wird. Satzbasierte Varianten (FineSurE) klassifizieren jeden Satz $s_i$ mit $f(s_i, D) in {0, 1}$ gegen das Dokument $D$ und mitteln über die $N$ Sätze @haindl2027research. In beiden Fällen sind Aussagenextraktion und Entailment-Entscheidung modellvermittelte Schritte, also genau die Richterurteile, deren Validität dieses Kapitel prüft. Für referenzfreie Halluzinationserkennung gilt eine zweite Lektion aus dem Lehrbuch: Verhaltenskonsistenz über mehrere Stichproben ist eine *notwendige*, aber keine hinreichende Bedingung für vertrauenswürdige Ausgaben, denn ein Modell kann konsistent falsch sein @haindl2027research. Eine große Meta-Evaluation von Halluzinationsmetriken fand, dass keine Metrikfamilie durchgängig überlegen war und LLM-basierte Bewertung mit starken Modellen zwar am besten abschnitt, aber ebenfalls nicht verlässlich war @haindl2027research.

#praxis[
  In einer SLR-Pipeline, in der ein LLM Studien zusammenfasst, misst du Treue und Faktizität getrennt. Treue prüfst du mit einem Richter, der gegen das Volltext-PDF urteilt (@k07-eq-ragas), Faktizität mit einer Stichprobe, die du gegen die Primärquelle verifizierst. Ein einzelner "Accuracy"-Wert vermischt beides @haindl2027research.
]

== Bewertungsparadigmen <k07-paradigmen>

Bevor du einen Richter validierst, musst du entscheiden, *was* er sieht und *was* er ausgibt. Diese Designentscheidungen bestimmen, welche Verzerrungen überhaupt auftreten können und welche Statistik danach passt.

=== Eingabeformate: punktweise, paarweise, listenweise

Bei der *punktweisen* Bewertung (_pointwise_, $n = 1$) wird ein Kandidat isoliert bewertet; Zheng et al. nennen das "single answer grading" @li2025generation[Abschn. 2.1] @zheng2023judging[Abschn. 3.1]. Der Richter vergibt etwa einen Wert auf einer Skala von 1 bis 10 oder ein binäres Label "korrekt/inkorrekt". Bei der *paarweisen* Bewertung (_pairwise_, $n = 2$) wählt der Richter die bessere von zwei Antworten oder erklärt ein Unentschieden @li2025generation[Abschn. 2.1]. Bei der *listenweisen* Bewertung (_listwise_, $n > 2$) werden mehrere Kandidaten gemeinsam verglichen @li2025generation[Abschn. 2.1]. Paarweise Bewertung ist das Format von Chatbot Arena, dem paarweisen Modus von MT-Bench, AlpacaEval und Arena-Hard-Auto @chiang2024chatbot @zheng2023judging @dubois2024length @li2025crowdsourced.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    // punktweise
    kasten((0, 2.2), [Antwort A], w: 2.0, h: 0.6, col: c-blue, bg: c-blue.lighten(90%))
    kasten((0, 0.9), [Richter], w: 2.0, h: 0.6, col: c-dark, bg: c-light)
    kasten((0, -0.4), [Score 7/10], w: 2.0, h: 0.6, col: c-teal, bg: c-teal.lighten(90%))
    pfeil((0, 1.9), (0, 1.2))
    pfeil((0, 0.6), (0, -0.1))
    content((0, 3.0), k07-tx([*Punktweise* ($n = 1$)], size: 8pt))
    // paarweise
    kasten((3.3, 2.2), [A], w: 1.0, h: 0.6, col: c-blue, bg: c-blue.lighten(90%))
    kasten((4.7, 2.2), [B], w: 1.0, h: 0.6, col: c-accent, bg: c-accent.lighten(90%))
    kasten((4.0, 0.9), [Richter], w: 2.0, h: 0.6, col: c-dark, bg: c-light)
    kasten((4.0, -0.45), [A > B, B > A \ oder Unentschieden], w: 3.1, h: 0.9, col: c-teal, bg: c-teal.lighten(90%))
    pfeil((3.3, 1.9), (3.8, 1.2))
    pfeil((4.7, 1.9), (4.2, 1.2))
    pfeil((4.0, 0.6), (4.0, -0.02))
    content((4.0, 3.0), k07-tx([*Paarweise* ($n = 2$)], size: 8pt))
    // listenweise
    for (i, l) in ("A", "B", "C", "D").enumerate() {
      kasten((7.0 + i * 0.75, 2.2), l, w: 0.6, h: 0.6, col: palette.at(i), bg: palette.at(i).lighten(90%))
      pfeil((7.0 + i * 0.75, 1.9), (8.1 + (i - 1.5) * 0.25, 1.2))
    }
    kasten((8.1, 0.9), [Richter], w: 2.0, h: 0.6, col: c-dark, bg: c-light)
    kasten((8.1, -0.45), [Rangfolge C > A > D > B \ oder beste Teilmenge], w: 3.8, h: 0.9, col: c-teal, bg: c-teal.lighten(90%))
    pfeil((8.1, 0.6), (8.1, -0.02))
    content((8.1, 3.0), k07-tx([*Listenweise* ($n > 2$)], size: 8pt))
  }),
  caption: [Die drei Eingabeformate nach Li et al. @li2025generation[Abschn. 2]. Die Ausgabe kann ein Score, eine Rangfolge oder eine Auswahl sein; paarweise Formate dominieren Leaderboards, punktweise Formate absolute Qualitätsmessungen.],
) <k07-fig-formate>

Die Wahl hat Folgen. Punktweise Urteile liefern absolute Werte, die du über Studien hinweg vergleichen kannst, sind aber anfällig für Skalendrift und Ties: Ganzzahlige Scores erzeugen viele Gleichstände, und eine Ziffer dominiert oft die Verteilung @liu2023geval[Abschn. 2]. Paarweise Urteile sind für Menschen und Modelle leichter, weil ein relativer Vergleich weniger Kalibrierung verlangt; auch das Lehrbuch hält fest, dass Rangfolgen oft konsistentere Urteile liefern als absolute Ratings @haindl2027research. Dafür handelst du dir die Positionsverzerrung ein, und die Zahl der Vergleiche wächst quadratisch. Listenweise Formate sind am effizientesten, aber am anfälligsten: Die Positionsverzerrung wächst mit der Zahl der Kandidaten @ye2025justice, und listenweise Positionskonsistenz liegt unter der paarweisen (GPT-4o 0.68 statt 0.76 auf MTBench) @shi2025judging[Tab. 2].

=== Was der Richter zusätzlich bekommt

Unabhängig vom Format entscheidest du, welche Zusatzinformation im Kontext $cal(C)$ steht. Die Literatur unterscheidet fünf Strategien, die du in @k07-tab-referenz zusammengefasst findest.

*Referenzfrei* (_reference-free_): Der Richter sieht nur Eingabe und Kandidaten. G-Eval etwa bewertet ohne menschliche Referenzen @liu2023geval[Abstract].

*Referenzgestützt* (_reference-guided_): Der Richter erhält eine Musterlösung. Zheng et al. führten das für Mathematik und Reasoning ein; die Fehlbewertungen von GPT-4 auf 10 Mathematikfragen (20 Urteile) sanken von 14 mit dem Standardprompt über 6 mit Chain-of-Thought auf 3 mit Referenz @zheng2023judging[Abschn. 3.4, Tab. 4]. Diese Strategie hilft aber nur, wenn die Referenz stimmt. Krumdick et al. zeigen, dass ein Richter auf Fragen, die er selbst nicht lösen kann, schlecht urteilt, und dass selbst erzeugte Referenzen das sogar verschlimmern: GPT-4o erreichte auf Items, die es selbst falsch beantwortet hatte, ein paarweises Kappa von 0.16 mit eigenen Referenzen, 0.30 ohne Referenz und 0.83 mit menschlichen Referenzen @krumdick2025free[Tab. 4]. Ein kleines Modell (Qwen 2.5 7B) mit menschlichen Referenzen kam auf derselben Teilmenge auf 0.63 @krumdick2025free[Tab. 4]. Wichtiger als die menschliche Urheberschaft ist die Korrektheit: Verifizierte GPT-4o-Referenzen erreichten 0.61, menschliche 0.69, subtil falsche dagegen nur 0.21 und damit weniger als gar keine Referenz (0.46) @krumdick2025free[Abschn. 6, Tab. 3]. Achtung: Krumdick et al. ist ein Preprint; die Werte stammen aus arXiv v2 (1. April 2026), v1 nannte für GPT-4o noch 0.14, 0.28 und 0.80.

*Rubrikbasiert* (_rubric-based_): Der Richter erhält ein explizites Bewertungsschema, also ein Kriterium plus Beschreibungen jeder Punktestufe. Prometheus wurde auf 1000 feingranularen Rubriken trainiert und nimmt Instruktion, Antwort, Referenzantwort und Rubrik als Eingabe @kim2024prometheus[Abstract] @kim2024prometheus2[Abschn. 3.1].

*Kriterien- oder Assertion-basiert*: Kriterien werden in binäre Assertions übersetzt, die entweder als Python-Funktion oder als Richter-Prompt implementiert sind @shankar2024validates[Abstract, Abschn. 3.1].

*Checklistenbasiert*: Ein LLM zerlegt die Instruktion in Ja/Nein-Fragen, der Richter beantwortet jede, und der Score ist der Anteil der Ja-Antworten (TICK) @cook2024ticking. CheckEval ersetzt Likert-Skalen durch zerlegte binäre Checklistenfragen und steigerte die durchschnittliche Übereinstimmung zwischen 12 Bewertermodellen um 0.45 @lee2025checkeval[Abstract].

#figure(
  table(
    columns: (1.25fr, 1.6fr, 1.6fr, 1.5fr),
    table.header([Strategie], [Was der Richter sieht], [Stärke], [Schwäche]),
    [Referenzfrei], [Eingabe und Kandidat(en)], [billig, für offene Aufgaben @liu2023geval], [anfällig für Stil und Länge],
    [Referenzgestützt], [plus Musterlösung], [Mathematik: 14/20 -> 3/20 Fehler @zheng2023judging[Tab. 4]], [nur mit korrekter Referenz @krumdick2025free[Tab. 3]],
    [Rubrik], [plus Kriterium und Stufenbeschreibungen], [vergleichbare absolute Scores @kim2024prometheus2], [Rubrik driftet beim Bewerten @shankar2024validates],
    [Assertions], [binäre Prüfungen (Code oder Prompt)], [lokalisiert Fehler @shankar2024validates], [deckt nur Formulierbares ab],
    [Checkliste], [instanzspezifische Ja/Nein-Fragen], [konsistenter (+0.45) @lee2025checkeval], [Checkliste selbst modellgeneriert],
  ),
  caption: [Referenzstrategien für LLM-Richter im Vergleich.],
) <k07-tab-referenz>

=== Wahrscheinlichkeitsgewichtete Scores: G-Eval

G-Eval kombiniert drei Bausteine: einen Aufgaben- und Kriterienprompt, automatisch generierte Chain-of-Thought-Bewertungsschritte und eine wahrscheinlichkeitsgewichtete Scoring-Funktion @liu2023geval[Abschn. 2]. Die Motivation für Letztere ist statistisch: Ganzzahlige Ausgaben erzeugen viele Ties, und eine Ziffer dominiert @liu2023geval[Abschn. 2].

#definition(titel: [Wahrscheinlichkeitsgewichteter Score])[
  Sei $S = {s_1, dots, s_n}$ die Menge der im Prompt definierten Stufen (etwa 1 bis 5) und $p(s_i)$ die Wahrscheinlichkeit, die das LLM dem Token für $s_i$ zuweist. Dann ist
  $ "score" = sum_(i=1)^n p(s_i) dot s_i $ <k07-eq-geval>
  der Erwartungswert der Score-Verteilung des Richters @liu2023geval[Abschn. 2, Gl. 1].
]

Ohne Zugriff auf Token-Log-Wahrscheinlichkeiten schätzte G-Eval $p(s_i)$, indem GPT-4 zwanzigmal gesampelt wurde ($n = 20$, Temperatur 1, top_p 1) @liu2023geval[Abschn. 3.1]. Das ist nichts anderes als ein Monte-Carlo-Schätzer des Erwartungswerts in @k07-eq-geval; seine Standardabweichung schrumpft mit $1 \/ sqrt(n)$.

#beispiel(titel: [G-Eval-Score aus einer Verteilung])[
  Der Richter gibt für die Stufen 1 bis 5 die Wahrscheinlichkeiten $p = (0.05, 0.10, 0.20, 0.40, 0.25)$ aus. Nach @k07-eq-geval ist
  $ "score" = 0.05 dot 1 + 0.10 dot 2 + 0.20 dot 3 + 0.40 dot 4 + 0.25 dot 5 = 0.05 + 0.20 + 0.60 + 1.60 + 1.25 = 3.70. $
  Der Modalwert wäre 4. Der gewichtete Score unterscheidet diese Antwort von einer anderen mit Modalwert 4, deren Masse stärker bei 5 liegt, und bricht damit Ties auf.
]

#figure(
  k07-plot(w: 7.5, h: 3.2, x: (0.4, 5.6), y: (0, 0.5), xt: (1, 2, 3, 4, 5), yt: (0, 0.1, 0.2, 0.3, 0.4, 0.5), xl: [Score-Stufe $s_i$], yl: [$p(s_i)$], (sx, sy) => {
    import cetz.draw: *
    for (i, p) in (0.05, 0.10, 0.20, 0.40, 0.25).enumerate() {
      let x = i + 1
      rect((sx(x - 0.3), sy(0)), (sx(x + 0.3), sy(p)), fill: if x == 4 { c-blue } else { c-blue.lighten(45%) }, stroke: none)
      content((sx(x), sy(p) + 0.18), k07-tx(str(p)))
    }
    line((sx(3.7), sy(0)), (sx(3.7), sy(0.47)), stroke: (paint: c-accent, thickness: 1.2pt, dash: "dashed"))
    content((sx(3.7) - 0.1, sy(0.33)), anchor: "east", k07-tx([gewichteter Score 3.70], fill: c-accent, weight: "bold"))
    content((sx(4) + 0.55, sy(0.40) + 0.18), anchor: "west", k07-tx([Modalwert 4], fill: c-blue))
  }),
  caption: [Wahrscheinlichkeitsgewichteter Score nach G-Eval @liu2023geval[Gl. 1] für die konstruierte Verteilung des Rechenbeispiels. Der Erwartungswert liegt zwischen den Stufen und bricht Gleichstände auf.],
) <k07-fig-geval>

Auf SummEval erreichte G-Eval-4 eine durchschnittliche Spearman-Korrelation von 0.514 und ein Kendall-$tau$ von 0.418, gegenüber 0.474/0.377 für UniEval und 0.225/0.175 für BERTScore @liu2023geval[Tab. 1]. Pro Dimension lagen die Spearman-Werte bei 0.582 (Kohärenz), 0.507 (Konsistenz) und 0.547 (Relevanz) @liu2023geval[Tab. 1]. Für die Flüssigkeit (_fluency_) widersprechen sich die publizierten Fassungen: arXiv v3 nennt 0.455, die EMNLP-Fassung 0.506, bei identischen Durchschnittswerten. Nenne diesen Wert daher nie ohne Versionsangabe. Auf Topical-Chat erreichte G-Eval-4 durchschnittlich 0.588 @liu2023geval[Tab. 2].

#fallstrick[
  Korrelationen um 0.5 sind moderat, nicht "menschengleich". Und G-Eval-4 gab GPT-3.5-Zusammenfassungen *immer* höhere Scores als menschlichen, selbst wenn Menschen die menschlichen bevorzugten @liu2023geval[Abschn. 4, Abb. 2]. Allerdings lag die Übereinstimmung der menschlichen Annotatoren bei diesen hochwertigen Zusammenfassungen bei Krippendorffs $alpha = 0.07$ @liu2023geval[Abschn. 4]. Bei so unzuverlässigem Gold lässt sich kaum entscheiden, ob der Richter verzerrt ist oder die Menschen raten.
]

=== Checklisten und Assertions formal

Checklisten zerlegen ein holistisches Urteil in überprüfbare Teilfragen. TICK definiert für eine Antwort $r$ und die vom LLM erzeugte Checkliste $Q$ von Ja/Nein-Fragen
$ "PassRate"(r) = 1 / (|Q|) sum_(q in Q) bb(1)(J(q, r) = "YES") $ <k07-eq-tick>
wobei $J(q, r)$ die Antwort des Richters auf Frage $q$ für $r$ ist @cook2024ticking. Die exakte paarweise Übereinstimmung mit menschlichen Präferenzen stieg damit von 46.4 % (direkte Bewertung) auf 52.2 %, und Checklisten erhöhten auch die Übereinstimmung menschlicher Rater auf WildBench von $alpha = 0.194$ auf 0.256 @cook2024ticking. Von GPT-4o erzeugte Checklisten folgten menschlich geschriebenen eng (Pearson der Pass-Raten 0.772 und 0.853) @cook2024ticking. Beachte, dass TICK ein Workshop-Paper ist.

#figure(
  diagram(spacing: (8mm, 6mm),
    fknoten((0, 1), [Instruktion \ "Schreibe eine Mail an die Studiengangsleitung, max. 150 Wörter, mit Terminvorschlag"], col: c-grey, w: 40mm),
    fknoten((1, 0), [Q1: Ist der Adressat die Studiengangsleitung?], col: c-blue, w: 38mm),
    fknoten((1, 1), [Q2: Höchstens 150 Wörter?], col: c-blue, w: 38mm),
    fknoten((1, 2), [Q3: Enthält sie einen konkreten Terminvorschlag?], col: c-blue, w: 38mm),
    fknoten((2, 0), [YES], col: c-green, w: 14mm),
    fknoten((2, 1), [YES], col: c-green, w: 14mm),
    fknoten((2, 2), [NO], col: c-red, w: 14mm),
    fknoten((3, 1), [PassRate $= 2\/3$], col: c-accent, filled: true, w: 26mm),
    edge((0, 1), (1, 0), "-|>"), edge((0, 1), (1, 1), "-|>"), edge((0, 1), (1, 2), "-|>"),
    edge((1, 0), (2, 0), "-|>"), edge((1, 1), (2, 1), "-|>"), edge((1, 2), (2, 2), "-|>"),
    edge((2, 0), (3, 1), "-|>"), edge((2, 1), (3, 1), "-|>"), edge((2, 2), (3, 1), "-|>"),
  ),
  caption: [Checklistenbewertung nach TICK @cook2024ticking: Ein LLM erzeugt instanzspezifische Ja/Nein-Fragen, der Richter beantwortet jede, der Score ist der Anteil der Ja-Antworten (@k07-eq-tick). Konstruiertes Beispiel.],
) <k07-fig-tick>

EvalGen geht einen Schritt weiter und richtet Assertions an den Bewertungen der Nutzer aus @shankar2024validates[Abschn. 3.1]. Für eine Assertion-Menge $S$ und Nutzerbewertungen $y_i in {0, 1}$ sei $"Coverage"(S)$ der Anteil der schlechten Ausgaben, die mindestens eine Assertion verletzen, und $"FFR"(S)$ die Falschfehlerrate, also der Anteil guter Ausgaben, die mindestens eine Assertion verletzen. Die Ausrichtung ist das harmonische Mittel aus Coverage und $1 - "FFR"$:
$ "Alignment"(S) = (2 dot "Coverage"(S) dot (1 - "FFR"(S))) / ("Coverage"(S) + (1 - "FFR"(S))) $ <k07-eq-evalgen>
@shankar2024validates[Abschn. 4.2]. Mit Coverage 0.73 und FFR 0.39 ergibt sich $2 dot 0.73 dot 0.61 \/ 1.34 approx 0.665$, passend zu den berichteten 66.46 % für die Produkt-Pipeline, erreicht mit 4 Assertions gegenüber 54.35 % mit 9 Assertions für SPADE @shankar2024validates[Tab. 1]. Die Formel hat die Form eines F1-Maßes, ist aber keines: Fasst du "schlechte Ausgabe" als positive Klasse auf, ist Coverage die Sensitivität und $1 - "FFR"$ die Spezifität, an der Stelle der Präzision steht also die Spezifität.

Der wichtigste Befund von EvalGen ist aber qualitativ: *Kriteriendrift* (_criteria drift_). Nutzer brauchen Kriterien, um Ausgaben zu bewerten, aber das Bewerten von Ausgaben hilft ihnen erst, die Kriterien zu definieren; sie fügen beim Bewerten Kriterien hinzu und interpretieren bestehende um @shankar2024validates[Abschn. 1, Abschn. 7.3.1]. Die Studie beruht auf 9 Praktikern @shankar2024validates[Abschn. 6], der Befund ist aber für jede Rubrikentwicklung relevant.

#k07-hs([Wenn sich die Kriterien beim Bewerten ändern, ist dann eine vorab festgelegte Rubrik nicht ohnehin eine Fiktion?],
[Teilweise ja, und genau das ist der Punkt von Shankar et al. @shankar2024validates[Abschn. 8.1]. Methodisch löst du das wie bei der qualitativen Codebuchentwicklung: Du planst eine explorative Runde ein, in der du etwa 20 Ausgaben bewertest und die Rubrik überarbeitest, und *frierst* sie dann ein, bevor die Validierungsstichprobe gezogen wird. Die Explorationsitems gehören nicht in die Validierung, sonst überschätzt du die Übereinstimmung. Die Drift ist kein Argument gegen Rubriken, sondern gegen Rubriken, die nie an echten Ausgaben getestet wurden.])

=== Paradigmen auswählen

Für deine eigene Forschung ergibt sich eine einfache Entscheidungslogik, die @k07-fig-entscheidung zusammenfasst. Geht es um einen relativen Vergleich von Systemen, ist ein paarweises Format naheliegend. Geht es um absolute Qualität, etwa den Anteil korrekter Antworten eines RAG-Systems, brauchst du punktweise Urteile mit Rubrik. Hat die Aufgabe eine überprüfbare richtige Antwort, gibst du dem Richter eine *verifizierte* Referenz. Ist das Urteil holistisch und vage ("Qualität der Erklärung"), zerlegst du es in Checklistenfragen. Und wenn das Bewertete selbst ein agentischer Prozess ist, brauchst du einen Richter, der die Arbeitsartefakte inspizieren kann (@k07-agent).

#figure(
  diagram(spacing: (6mm, 7mm),
    fknoten((1, 0), [Forschungsfrage: relativ oder absolut?], col: c-dark, filled: true, w: 42mm),
    fknoten((0, 1), [relativ: \ paarweise, beide Reihenfolgen], col: c-blue, w: 36mm),
    fknoten((2, 1), [absolut: \ punktweise mit Rubrik], col: c-blue, w: 36mm),
    fknoten((2, 2), [Gibt es eine richtige Antwort?], col: c-violet, w: 36mm),
    fknoten((1, 3), [ja: verifizierte Referenz, \ ggf. Reasoning-Richter], col: c-teal, w: 38mm),
    fknoten((3, 3), [nein: Rubrik zerlegen \ in Checkliste], col: c-teal, w: 34mm),
    fknoten((0, 3), [Agentischer Prozess? \ -> Agent-as-a-Judge], col: c-yellow, w: 34mm),
    edge((1, 0), (0, 1), "-|>"), edge((1, 0), (2, 1), "-|>"),
    edge((2, 1), (2, 2), "-|>"), edge((2, 2), (1, 3), "-|>"), edge((2, 2), (3, 3), "-|>"),
    edge((0, 1), (0, 3), "-|>", dash: "dashed"),
  ),
  caption: [Entscheidungshilfe für das Bewertungsparadigma. Die Logik ist eine didaktische Synthese aus @zheng2023judging, @kim2024prometheus2, @krumdick2025free, @cook2024ticking und @zhuge2025agent.],
) <k07-fig-entscheidung>

== Meta-Evaluation: Wer richtet den Richter? <k07-meta>

Meta-Evaluation heißt, den Richter selbst zu bewerten. Das ist der Kern dieses Kapitels, denn jede Aussage, die du mit einem Richter triffst, ist nur so gut wie die Evidenz für seine Validität. In der Literatur gibt es drei Bezugspunkte, und viele scheinbare Widersprüche zwischen Studien lösen sich auf, sobald du sie auseinanderhältst @gu2024survey[Abschn. 4.1] @bavaresco2025llms[Abschn. 3] @tan2025judgebench[Abb. 2].

+ *Übereinstimmung mit menschlichen Labels auf Instanzebene*: Prozentübereinstimmung, Kappa, Korrelationen je bewertetem Item.
+ *Übereinstimmung mit objektiver Korrektheit*: Der Richter muss zwischen einer verifiziert richtigen und einer verifiziert falschen Antwort unterscheiden. Das entfernt das Rauschen und die Subjektivität menschlicher Präferenzlabels; JudgeBench ist so gebaut @tan2025judgebench[Abb. 2].
+ *Systemebene*: Rankt der Richter Systeme so wie Menschen, etwa gemessen als Spearman-Korrelation mit Chatbot-Arena-Rankings @li2025crowdsourced[Tab. 1] @dubois2024length.

#figure(
  diagram(spacing: (5mm, 8mm),
    fknoten((1, 0), [Meta-Evaluation eines Richters], col: c-dark, filled: true, w: 56mm),
    fknoten((0, 1), [*Instanzebene* \ Richter vs. Mensch je Item \ $p_o$, $kappa$, $pi$, $rho_S$, $tau$], col: c-blue, w: 40mm),
    fknoten((1, 1), [*Korrektheit* \ richtig vs. falsch verifiziert \ Paargenauigkeit], col: c-teal, w: 40mm),
    fknoten((2, 1), [*Systemebene* \ Ranking vs. menschliches Ranking \ Spearman, Separierbarkeit], col: c-violet, w: 40mm),
    fknoten((0, 2), [MT-Bench, Judging the Judges, JUDGE-BENCH], col: c-blue, w: 40mm),
    fknoten((1, 2), [JudgeBench, LLMBar, RewardBench], col: c-teal, w: 40mm),
    fknoten((2, 2), [Arena-Hard-Auto, AlpacaEval LC], col: c-violet, w: 40mm),
    edge((1, 0), (0, 1), "-|>"), edge((1, 0), (1, 1), "-|>"), edge((1, 0), (2, 1), "-|>"),
    edge((0, 1), (0, 2), "-", dash: "dashed"), edge((1, 1), (1, 2), "-", dash: "dashed"), edge((2, 1), (2, 2), "-", dash: "dashed"),
  ),
  caption: [Drei Validitätsziele der Meta-Evaluation mit typischen Maßen und Benchmarks @gu2024survey @tan2025judgebench @li2025crowdsourced. Ein Richter kann auf einer Ebene gut und auf einer anderen schlecht sein.],
) <k07-fig-validitaet>

=== Prozentübereinstimmung, Kappa und Pi

Nimm den einfachsten Fall: Richter und Mensch beurteilen $N$ Antworten binär als "korrekt" oder "inkorrekt". Die Konfusionsmatrix hat vier Zellen: $"TP"$ (beide "korrekt"), $"TN"$ (beide "inkorrekt"), $"FP"$ (Richter "korrekt", Mensch "inkorrekt") und $"FN"$ (Richter "inkorrekt", Mensch "korrekt"). Die Prozentübereinstimmung ist
$ p_o = ("TP" + "TN") / ("TP" + "FP" + "TN" + "FN"). $ <k07-eq-po>
Thakur et al. schreiben dafür $rho$; in diesem Kapitel ist $rho$ für Korrelationen reserviert @thakur2025judging[Anh. B].

Das Problem mit $p_o$ kennst du aus Kapitel 5: Wenn beide Rater fast immer "korrekt" sagen, stimmen sie schon zufällig oft überein. Chance-korrigierte Koeffizienten ziehen die erwartete Zufallsübereinstimmung $p_e$ ab:
$ kappa = (p_o - p_e) / (1 - p_e). $ <k07-eq-kappa>
Der Unterschied zwischen Cohens Kappa und Scotts Pi liegt allein in $p_e$ @thakur2025judging[Anh. B, Anh. F]. Cohen verwendet das Produkt der *eigenen* Randverteilungen beider Rater,
$ p_e^kappa = (("TP" + "FP")("TP" + "FN") + ("TN" + "FN")("TN" + "FP")) / N^2, $ <k07-eq-pe-cohen>
Scott dagegen die *gepoolten* Randverteilungen: Mit $overline(p)_+$, dem Mittel der beiden "korrekt"-Anteile, und $overline(p)_- = 1 - overline(p)_+$ ist
$ p_e^pi = overline(p)_+^2 + overline(p)_-^2. $ <k07-eq-pe-scott>
Scott unterstellt also, dass beide Rater aus derselben Verteilung ziehen, und bestraft damit Unterschiede in den Randverteilungen zusätzlich.

#satz(titel: [Geschlossene Form von Kappa für $2 times 2$])[
  Für eine $2 times 2$-Tafel gilt
  $ kappa = (2 ("TP" dot "TN" - "FP" dot "FN")) / (("TP" + "FP")("FP" + "TN") + ("TP" + "FN")("FN" + "TN")). $ <k07-eq-kappa-closed>
]
#beweis[
  Schreibe $a = "TP"$, $b = "FP"$, $c = "FN"$, $d = "TN"$ und $N = a + b + c + d$. Dann ist $N^2 p_o = N(a + d)$ und $N^2 p_e = (a + b)(a + c) + (c + d)(b + d)$. Ausmultiplizieren ergibt $N(a + d) = a^2 + a b + a c + 2 a d + b d + c d + d^2$ und $(a + b)(a + c) + (c + d)(b + d) = a^2 + a b + a c + 2 b c + b d + c d + d^2$; die Differenz ist $N^2 (p_o - p_e) = 2(a d - b c)$. Für den Nenner zerlegst du $N^2 = ((a + b) + (c + d))((a + c) + (b + d))$ in vier Produkte; nach Abzug von $N^2 p_e$ bleiben $N^2 (1 - p_e) = (a + b)(b + d) + (a + c)(c + d)$. Der Quotient ist @k07-eq-kappa-closed.
]

#beispiel(titel: [Kappa, Pi und Nachsichtigkeit])[
  Ein Richter bewertet 100 Antworten mit $"TP" = 60$, $"TN" = 20$, $"FP" = 15$, $"FN" = 5$.
  - $p_o = 80 \/ 100 = 0.80$.
  - Menschen sagen in $65\/100$ Fällen "korrekt", der Richter in $75 \/ 100$. Nach @k07-eq-pe-cohen ist $p_e^kappa = 0.65 dot 0.75 + 0.35 dot 0.25 = 0.4875 + 0.0875 = 0.575$, also $kappa = 0.225 \/ 0.425 approx 0.53$.
  - Kontrolle mit @k07-eq-kappa-closed: $2(1200 - 75) \/ (75 dot 35 + 65 dot 25) = 2250 \/ 4250 approx 0.53$.
  - Scott: gepoolter Anteil $overline(p)_+ = (0.65 + 0.75) \/ 2 = 0.70$, also $p_e^pi = 0.70^2 + 0.30^2 = 0.58$ und $pi = 0.22 \/ 0.42 approx 0.52$.
  80 % Rohübereinstimmung schrumpfen auf rund 0.53, weil beide Rater meistens "korrekt" sagen. Pi liegt etwas darunter, weil der Richter um 10 Prozentpunkte häufiger "korrekt" sagt als die Menschen. Diese Zahlen stammen aus dem Dossier der LV und dem Notebook; sie sind konstruiert.
]

=== Das Kappa-Paradoxon beim Richter

Wie stark $p_o$ täuschen kann, zeigt eine kleine Rechnung, die du im Hörsaal an die Tafel schreiben kannst. Nimm einen Richter, der korrekte und inkorrekte Antworten jeweils mit Wahrscheinlichkeit 0.85 richtig erkennt. Seine erwartete Prozentübereinstimmung ist dann immer $p_o = 0.85$, unabhängig vom Anteil $b$ korrekter Antworten im Datensatz. Kappa hängt dagegen stark von $b$ ab: Der Richter sagt mit Wahrscheinlichkeit $j = 0.85 b + 0.15 (1 - b)$ "korrekt", und $p_e = b j + (1 - b)(1 - j)$ steigt mit schiefer Verteilung. @k07-fig-paradox zeigt das Ergebnis: Bei $b = 0.5$ ist $kappa = 0.70$, bei $b = 0.9$ nur noch $0.457$ und bei $b = 0.95$ noch $0.307$ (mit python3 nachgerechnet). Wenn die evaluierten Systeme gut sind, also $b$ hoch ist, sinkt Kappa bei gleicher Fehlerrate des Richters.

#figure(
  k07-plot(w: 8, h: 3.8, x: (0.5, 0.95), y: (0, 1), xt: (0.5, 0.6, 0.7, 0.8, 0.9), yt: (0, 0.2, 0.4, 0.6, 0.8, 1.0), xl: [Anteil korrekter Antworten $b$ im Datensatz], yl: [Übereinstimmung], (sx, sy) => {
    import cetz.draw: *
    let kap(b) = { let j = 0.85 * b + 0.15 * (1 - b); let pe = b * j + (1 - b) * (1 - j); (0.85 - pe) / (1 - pe) }
    let sco(b) = { let j = 0.85 * b + 0.15 * (1 - b); let pb = (b + j) / 2; let pe = pb * pb + (1 - pb) * (1 - pb); (0.85 - pe) / (1 - pe) }
    let xs = range(0, 46).map(i => 0.5 + i * 0.01)
    k07-kurve(xs.map(b => (b, 0.85)), sx, sy, col: c-grey, dash: "dashed")
    k07-kurve(xs.map(b => (b, kap(b))), sx, sy, col: c-blue)
    k07-kurve(xs.map(b => (b, sco(b))), sx, sy, col: c-accent, dash: "dotted")
    content((sx(0.52), sy(0.85) + 0.2), anchor: "west", k07-tx([$p_o = 0.85$ (konstant)], fill: c-grey.darken(20%)))
    content((sx(0.62), sy(0.6)), anchor: "north-east", k07-tx([Cohens $kappa$], fill: c-blue, weight: "bold"))
    content((sx(0.93), sy(0.2)), anchor: "east", k07-tx([Scotts $pi$], fill: c-accent, weight: "bold"))
    circle((sx(0.9), sy(0.457)), radius: 0.06, fill: c-blue, stroke: none)
    content((sx(0.9) - 0.1, sy(0.457) - 0.05), anchor: "north-east", k07-tx([0.457]))
  }),
  caption: [Kappa-Paradoxon: Ein Richter mit Sensitivität und Spezifität 0.85 hat konstant $p_o = 0.85$, aber Kappa und Pi fallen, je schiefer die Verteilung korrekter Antworten ist. Konstruiertes Beispiel; @k07-eq-kappa bis @k07-eq-pe-scott.],
) <k07-fig-paradox>

Das ist kein Defekt von Kappa, sondern eine Eigenschaft: Kappa misst Übereinstimmung *über das hinaus, was die Randverteilungen ohnehin erzwingen*. Für deine Berichte heißt das, dass du nie nur einen Koeffizienten berichtest, sondern immer die Konfusionsmatrix, $p_o$, einen chance-korrigierten Koeffizienten und die Randverteilungen beider Rater.

=== Nachsichtigkeit

Thakur et al. modellieren den Richter mit zwei Parametern: $P_c$, der Wahrscheinlichkeit eines korrekten Urteils, und $P_+$, der Wahrscheinlichkeit, dass der Richter "korrekt" sagt, *wenn* sein Urteil nicht mit der Referenz übereinstimmt @thakur2025judging[Abschn. 5.4, Anh. O]. Empirisch schätzt du
$ hat(P)_c = ("TP" + "TN") / N, quad hat(P)_+ = "FP" / ("FP" + "FN"). $ <k07-eq-leniency>
Im Rechenbeispiel ist $hat(P)_+ = 15 \/ 20 = 0.75$: Drei Viertel der Fehler dieses Richters sind nachsichtig. Die publizierten Werte reichen von $P_+ = 0.19$ (JudgeLM-7B) bis 0.99 (Llama-2 70B); GPT-4 Turbo hat Scotts $pi = 0.87$, $P_c = 0.87$ und $P_+ = 0.69$ @thakur2025judging[Anh. O, Abb. 16a]. $P_c$ und $pi$ korrelieren über die Richter mit Pearson 0.98 @thakur2025judging[Anh. O]. Nachsichtigkeit ist für Forschungsaussagen gefährlich, weil sie systematisch ist: Ein nachsichtiger Richter überschätzt die Korrektheitsrate aller Systeme, und zwar nicht unbedingt gleich stark.

#studie(titel: [Thakur et al. 2025, Judging the Judges])[
  *Design:* Kontrolliertes Setting mit nahezu perfekter menschlicher Übereinstimmung. 400 Fragen aus TriviaQA, beantwortet von 9 Prüflingsmodellen; 13 Richter (11 LLMs plus die lexikalischen Baselines Exact Match und Contains); drei menschliche Annotatoren mit Scotts $pi = 0.962$ und 98.52 % Prozentübereinstimmung @thakur2025judging[Abschn. 3, Anh. G]. Thakur et al. geben $pi$ teils auf einer Skala von 0 bis 100 an (96.2, 59); hier einheitlich von 0 bis 1.
  *Befund:* Die besten Richter erreichen $pi$ um 0.87 bis 0.88 (Llama-3 70B 0.88, Llama-3.1 70B 0.88, GPT-4 Turbo 0.87), rund 0.08 unter der menschlichen Übereinstimmung @thakur2025judging[Abschn. 4.1, Abb. 16a]. Llama-3 8B hat $pi = 0.59$, aber eine Prozentübereinstimmung "deutlich über 80 %". Richter mit über 90 % Prozentübereinstimmung können sich in den vergebenen Scores um mehr als 10 Punkte unterscheiden, Richter mit $pi$ über 0.80 um bis zu 5 Punkte @thakur2025judging[Abschn. 4.1]. Die meisten Richter sind nachsichtig ($P_+$ deutlich über 0.5) @thakur2025judging[Abschn. 5.4].
  *Grenzen:* Eine einzige, leichte Aufgabe mit kurzen Antworten; die Autoren erwarten, dass komplexere Settings schlechter aussehen @thakur2025judging[Abstract]. Achtung, Fassungen: Alle Zahlen hier stammen aus der publizierten GEM-Fassung (ACL Anthology), die Scotts $pi$ berichtet. Die ältere arXiv-Fassung v2 verwendete Cohens $kappa$ und nennt abweichende Werte, etwa $kappa = 0.62$ für Llama-3 8B, Score-Abweichungen bis 20 Punkte, $P_+$ von 0.36 bis 0.94 und Spearman 0.98 für "contains"; diese Werte sind überholt und sollten nicht mehr zitiert werden.
]

=== Korrelationen für abgestufte Scores

Bei abgestuften Scores berichten Studien Korrelationen: G-Eval Spearman $rho_S$ und Kendall $tau$ auf Zusammenfassungsebene @liu2023geval[Tab. 1], Prometheus Pearson $r$ @kim2024prometheus[Abstract], JUDGE-BENCH Spearman für abgestufte und Cohens Kappa für kategoriale Annotationen @bavaresco2025llms[Abschn. 3]. Spearman ist die Pearson-Korrelation der Ränge; Kendall zählt konkordante minus diskordante Paare, normiert auf die Zahl der Paare. Ganzzahlige Richterscores erzeugen viele Ties, und das beeinflusst Kendall stärker als Spearman: G-Eval merkt an, dass Bewertung ohne Wahrscheinlichkeiten "zu vielen Ties führt", was für diese Variante ein höheres Kendall-$tau$ ergibt @liu2023geval[Tab. 1, Abschn. 4]. Vergleiche Richter deshalb nur mit derselben Korrelationsvariante und derselben Tie-Behandlung.

Entscheidend ist die *Ebene*. Instanzebene bedeutet eine Korrelation über alle bewerteten Ausgaben, Systemebene eine Korrelation über einen Mittelwert pro Modell. Systemkorrelationen sind in der Regel viel höher als Instanzkorrelationen @thakur2025judging[Abschn. 4.2] @li2025crowdsourced[Tab. 1], weil sich Instanzfehler beim Mitteln teilweise aufheben.

#satz(titel: [Instanz- und Systemvalidität fallen auseinander])[
  Die lexikalische Metrik "contains" hatte eine deutlich geringere Übereinstimmung mit Menschen als die besten Richter (mittleres Scotts $pi$ 0.64 gegenüber 0.88 für Llama-3 70B auf herunterskalierten Stichproben), rankte die Prüflingsmodelle aber mit Spearman 0.99 @thakur2025judging[Tab. 4, Abschn. 4.2].
]

Die Konsequenz für deine Forschung ist direkt: Rechtfertige den Einsatz eines Richters auf der Ebene, auf der deine Forschungsaussage liegt. Eine hohe Systemkorrelation rechtfertigt keine Aussagen über einzelne Items, etwa "der Anteil halluzinierter Zitate beträgt 12 %". Umgekehrt kann eine mittelmäßige Instanzübereinstimmung für ein Ranking reichen.

#fallstrick[
  Die häufigste Validitätsbedrohung in Arbeiten mit LLM-Richtern: Man zitiert eine hohe Systemkorrelation aus der Literatur ("GPT-4 korreliert mit 0.98 mit Chatbot Arena") und verwendet den Richter dann für Instanzlabels in einer ganz anderen Aufgabe. Beides ist nicht übertragbar.
]

=== MT-Bench und Chatbot Arena: der optimistische Ausgangspunkt

#studie(titel: [Zheng et al. 2023, MT-Bench])[
  *Design:* 80 mehrteilige Fragen in 8 Kategorien, rund 3000 Expertenstimmen von 58 Annotatoren, 30 000 Arena-Konversationen mit Präferenzen; drei Richtermodi (paarweise, Einzelbewertung, referenzgestützt) @zheng2023judging[Abstract, Abschn. 3].
  *Befund:* GPT-4 stimmte paarweise mit Menschen zu 66 % überein, wenn Unentschieden zählen (Setup S1), und zu 85 %, wenn sie ausgeschlossen werden (S2); Mensch-Mensch lag bei 63 % beziehungsweise 81 % @zheng2023judging[Tab. 5].
  *Grenzen:* Die Schlagzeile "über 80 %" gilt nur ohne Ties. Mit Ties liegen Richter-Mensch und Mensch-Mensch in den 60ern @zheng2023judging[Tab. 5].
]

Chiang et al. berichten für Chatbot Arena eine Übereinstimmung von Crowd und Experten zwischen 72.8 % und 83.1 % und zwischen Experten von 79.4 % bis 89.8 %; GPT-4 als Richter stimmte mit der Crowd zu 75.6 % und mit Experten zu 76.3 % bis 81.0 % überein @chiang2024chatbot[Tab. 3]. Auf den ersten Blick ist der Richter also "so gut wie ein Mensch". Das Lehrbuch liest den Befund ebenso: eine qualifizierte Bejahung, die sorgfältigen Einsatz unter menschlicher Aufsicht rechtfertigt, menschliche Bewertung aber nicht überflüssig macht @haindl2027research.

=== JUDGE-BENCH: Validierung pro Aufgabe

#studie(titel: [Bavaresco et al. 2025, JUDGE-BENCH])[
  *Design:* 11 LLMs reproduzieren menschliche Annotationen auf 20 NLP-Evaluationsdatensätzen; Cohens Kappa für kategoriale, Spearman für abgestufte Urteile @bavaresco2025llms[Abstract, Abschn. 3].
  *Befund:* Durchschnittliches Kappa (kategorial) und Spearman (abgestuft): GPT-4o 0.28 und 0.50, Llama-3.1-70B 0.28 und 0.43, Mixtral-8x22B 0.24 und 0.44, Gemini-1.5 0.22 und 0.43, mit Standardabweichungen um 0.2 bis 0.3 über die Datensätze @bavaresco2025llms[Tab. 1]. Offene Modelle gewinnen auf einzelnen Datensätzen (CoLA: Mixtral-8x22B 0.54 gegenüber GPT-4o 0.34). Alle Modelle stimmen besser mit Menschen überein, wenn der Text von Menschen statt von Modellen stammt @bavaresco2025llms[Abb. 4], und besser mit Laien als mit Experten @bavaresco2025llms[Abb. 2].
  *Grenzen:* Short Paper; die Erklärungen für den Experten-Laien-Unterschied sind nach Angabe der Autoren spekulativ @bavaresco2025llms.
]

Zwei Befunde von JUDGE-BENCH solltest du für die Lehre parat haben. Erstens ist der wichtigste Anwendungsfall, das Bewerten modellgenerierter Texte, schwieriger als das Bewerten menschlicher Texte @bavaresco2025llms[Abb. 4]. Zweitens übertreffen manche Richter auf einzelnen Datensätzen die menschliche Obergrenze (Rezeptgenerierung: GPT-4o 0.78 gegenüber 0.65) @bavaresco2025llms[Tab. 1]. Das signalisiert verrauschte Goldlabels, nicht übermenschliches Urteilsvermögen. Auf Topical-Chat lag das menschliche Krippendorffs $alpha$ bei 0.08 und GPT-4o bei Spearman 0.26 @bavaresco2025llms[Tab. 1, Tab. 3].

#figure(
  balken((
    ([GPT-4o], 0.28), ([Llama-3.1-70B], 0.28), ([Mixtral-8x22B], 0.24), ([Gemini-1.5], 0.22),
  ), max: 1, breite: 8, farbe: c-blue),
  caption: [Durchschnittliches Cohens Kappa mit menschlichen Annotationen über die kategorialen Datensätze von JUDGE-BENCH @bavaresco2025llms[Tab. 1]. Skala bis 1 gezeichnet, um den Abstand zur perfekten Übereinstimmung sichtbar zu machen.],
) <k07-fig-judgebench-kappa>

=== JudgeBench: Validierung gegen Korrektheit

#studie(titel: [Tan et al. 2025, JudgeBench])[
  *Design:* Von einem starken Modell werden $k$ Antworten pro Frage gesampelt und automatisch auf Korrektheit geprüft; behalten werden Fragen mit gemischten Ergebnissen, gepaart wird eine richtige mit einer falschen Antwort, gefiltert mit einem zweiten Prüfer. 350 GPT-4o-Paare (154 Wissen, 98 Reasoning, 56 Mathematik, 42 Code) und 270 Claude-3.5-Sonnet-Paare; jedes Paar wird in beiden Reihenfolgen beurteilt @tan2025judgebench[Abb. 2, Abschn. 4].
  *Befund:* Vanilla-GPT-4o-Richter 50.86 % bei einer Zufallsrate von 50 %; Prometheus-2-Varianten 34.86 % bis 40.29 %, also unter Zufall bei strenger Konsistenzregel; bester feinjustierter Richter (Skywork-Critic auf Llama-3.1-70B) 57.43 % @tan2025judgebench[Tab. 1]; Reward-Modelle bis 64.29 % @tan2025judgebench[Tab. 3]; Arena-Hard-Richterprompt mit o3-mini bei hohem Reasoning-Aufwand 80.86 % @tan2025judgebench[Tab. 2].
  *Grenzen:* Paare stammen pro Teilmenge von einem einzigen Generator; die strenge Bewertungsregel bestraft Positionsinkonsistenz stark @tan2025judgebench[Abschn. 4].
]

Die Bewertungsregel von JudgeBench ist selbst ein lehrreiches Stück Messdesign: Ein Paar zählt als richtig, wenn beide Durchgänge die korrekte Antwort bevorzugen oder einer sie bevorzugt und der andere unentschieden ist; inkonsistente Urteile oder zwei Unentschieden zählen als falsch @tan2025judgebench[Abschn. 4]. Damit kann ein Richter, der seine Meinung mit der Reihenfolge wechselt, deutlich *unter* 50 % fallen, was die Prometheus-Werte erklärt.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let werte = (([Prometheus 2 (beste Variante)], 40.29, c-grey), ([GPT-4o, Vanilla-Prompt], 50.86, c-blue), ([Skywork-Critic 70B], 57.43, c-teal), ([Bestes Reward-Modell], 64.29, c-violet), ([o3-mini (hoch), Arena-Hard-Prompt], 80.86, c-accent))
    let br = 8.0
    line((br * 0.5, 0.45), (br * 0.5, -2.95), stroke: (paint: c-red, thickness: 1pt, dash: "dashed"))
    for (i, (lab, v, col)) in werte.enumerate() {
      let y = -i * 0.62
      content((-0.15, y), anchor: "east", k07-tx(lab, size: 7.5pt))
      rect((0, y - 0.21), (br * v / 100, y + 0.21), fill: col.lighten(10%), stroke: none)
      if v < 52 { content((br * v / 100 - 0.08, y), anchor: "east", k07-tx([#v %], fill: white, weight: "bold")) } else { content((br * v / 100 + 0.1, y), anchor: "west", k07-tx([#v %])) }
    }
    content((br * 0.5, 0.62), k07-tx([Zufall 50 %], fill: c-red, weight: "bold"))
  }),
  caption: [Genauigkeit auf JudgeBench-Paaren mit verifizierter Korrektheit @tan2025judgebench[Tab. 1-3]. Bei strenger Zwei-Reihenfolgen-Regel liegen starke geprompte Richter nahe am Zufall; ein Reasoning-Modell als Richter liegt deutlich darüber.],
) <k07-fig-judgebench>

Ein Vorläufer mit derselben Logik ist LLMBar: 419 Paare zum Befolgen von Instruktionen (100 natürlich, 319 adversarial), bei denen die falsche Ausgabe oft oberflächlich attraktiver ist; Experten stimmten zu 94 % überein @zeng2024evaluating. GPT-4 erreichte vanilla 93.5 % auf den natürlichen und 73.1 % auf den adversarialen Paaren, mit der besten Strategie (Regeln, selbst erzeugte Metriken und Referenz) 96.0 % und 82.8 %; ChatGPT lag auf den adversarialen Paaren mit 32.0 % unter Zufall @zeng2024evaluating[Tab. 2, Tab. 5].

#k07-hs([Zheng et al. berichten 85 % Übereinstimmung, Bavaresco et al. ein Kappa von 0.28 und Tan et al. Zufallsniveau. Welche Zahl stimmt denn nun?],
[Alle drei, aber sie messen Verschiedenes. Die 85 % sind eine Prozentübereinstimmung ohne Ties bei Chat-Präferenzen auf MT-Bench, also auf einer Aufgabe, bei der auch Menschen nur zu 81 % übereinstimmen @zheng2023judging[Tab. 5]. Das Kappa von 0.28 ist chance-korrigiert und über 20 heterogene NLP-Aufgaben gemittelt, viele davon mit Expertenannotationen @bavaresco2025llms[Tab. 1]. JudgeBench schließlich misst Korrektheit auf absichtlich schweren Paaren mit strenger Konsistenzregel @tan2025judgebench[Abschn. 4]. Die Auflösung lautet: Die Ranking-Validität für Chat-Modelle ist vergleichsweise robust, Instanzlabels für Forschungsaussagen sind es nicht und müssen pro Aufgabe validiert werden @bavaresco2025llms @thakur2025judging.])

=== Ist menschliche Übereinstimmung der richtige Goldstandard?

Diese Frage wird dir in jeder Diskussion begegnen, und die ehrliche Antwort lautet: nur eingeschränkt. Die Übereinstimmung zwischen Menschen ist selbst begrenzt: 63 % mit Ties auf MT-Bench @zheng2023judging[Tab. 5], durchschnittliches Annotator-Kappa 0.54 auf dem Vicuna-Benchmark @wang2024large[Tab. 4], $alpha = 0.07$ für hochwertige Zusammenfassungen @liu2023geval[Abschn. 4]. Wo möglich, ist objektive Korrektheit ein besseres Ziel @tan2025judgebench. Und erzwungene Einzelentscheidungen können das Gold selbst verzerren: Wenn mehrere Bewertungen für ein Item legitim sind (_rating indeterminacy_), wählte eine Validierung mit erzwungenen Einzellabels Richter aus, die bis zu 31 % schlechter waren als Richter, die mit Mehrfachlabels ("response set"-Ratings) ausgewählt wurden; die Studie umfasste 11 Bewertungsaufgaben und 9 kommerzielle LLMs @guerdan2025validating[Abstract].

Das Lehrbuch formuliert die Haltung dahinter: Menschliches Urteil bleibt der Anker, weil Konstrukte wie Treue oder Hilfsbereitschaft durch menschliches Verständnis definiert sind. Seine Schwächen sprechen nicht gegen den Anker, sondern dafür, ihn sorgfältig einzusetzen: zur Validierung billigerer Stellvertreter und für die Urteile, auf die es am meisten ankommt @haindl2027research.

== Verzerrungen: was Richter systematisch falsch machen <k07-bias>

Zufälliger Fehler mittelt sich mit wachsender Stichprobe heraus; systematischer Fehler nicht. Das Lehrbuch formuliert es knapp: Ein Richter, der konsequent Länge belohnt, irrt in eine feste Richtung, und eine Evaluation, die das nicht korrigiert, verwechselt jedes Mal Ausführlichkeit mit Qualität; die Verzerrungen "bestehen in jeder Größenordnung fort" @haindl2027research. Gu et al. trennen aufgabenunabhängige Verzerrungen, die der Richter als LLM mitbringt, von urteilsspezifischen @gu2024survey[Abschn. 4.2]. Für die Praxis wichtiger ist die Frage, wie du jede Verzerrung *misst*. Dieser Abschnitt geht die wichtigsten durch, jeweils mit Definition, Messverfahren und Befundlage.

=== Positionsverzerrung

Positionsverzerrung (_position bias_) ist die Bevorzugung einer Antwort wegen ihres Platzes im Prompt @gu2024survey[Abschn. 4.2]. Gemessen wird sie, indem du jedes Paar in beiden Reihenfolgen beurteilen lässt.

#definition(titel: [Konfliktrate und Positionskonsistenz])[
  Für $N$ Paare seien $"ER"_i^(r 12)$ und $"ER"_i^(r 21)$ die Urteile in Original- und vertauschter Reihenfolge, beide ausgedrückt als "welche Antwort gewinnt". Dann ist
  $ "Konfliktrate" = 1 / N sum_(i=1)^N bb(1)("ER"_i^(r 12) != "ER"_i^(r 21)) $ <k07-eq-conflict>
  @wang2024large[Tab. 2]. Die Positionskonsistenz ist der komplementäre Anteil der Paare, deren Urteil den Tausch übersteht @gu2024survey[Abschn. 4.4].
]

Die Befunde sind drastisch. Mit dem Standardprompt erreichte GPT-4 auf MT-Bench eine Konsistenz von 65.0 %, GPT-3.5 46.2 % und Claude-v1 23.8 %; Claude-v1 bevorzugte in 75.0 % der Fälle die erste Position @zheng2023judging[Tab. 2]. Bei Wang et al. hatte GPT-4 beim Vergleich Vicuna-13B gegen ChatGPT eine Konfliktrate von 46.3 %, ChatGPT als Richter 82.5 % @wang2024large[Tab. 2]. Das Abstract von Wang et al. formuliert es so, dass Vicuna-13B mit ChatGPT als Richter allein durch die Reihenfolge 66 von 80 Vergleichen gegen ChatGPT gewinnen konnte; in der Tabelle ist 66 von 80 die Zahl der Konflikte, präziser ist also: Auf 66 von 80 Paaren kippte das Urteil beim Vertauschen @wang2024large[Abstract, Tab. 2].

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let werte = (([GPT-4], 65.0), ([GPT-3.5], 46.2), ([Claude-v1], 23.8))
    for (i, (lab, v)) in werte.enumerate() {
      let y = -i * 0.65
      content((-0.15, y), anchor: "east", k07-tx(lab, size: 7.5pt))
      rect((0, y - 0.22), (8 * v / 100, y + 0.22), fill: c-blue, stroke: none)
      rect((8 * v / 100, y - 0.22), (8, y + 0.22), fill: c-accent.lighten(70%), stroke: none)
      content((8 * v / 100 - 0.08, y), anchor: "east", k07-tx([#v %], fill: white, weight: "bold"))
    }
    content((0, 0.55), anchor: "west", k07-tx([#box(fill: c-blue, width: 6pt, height: 6pt) konsistent über beide Reihenfolgen #h(10pt) #box(fill: c-accent.lighten(70%), width: 6pt, height: 6pt) inkonsistent oder Tie], size: 7pt))
  }),
  caption: [Positionskonsistenz auf MT-Bench mit Standardprompt @zheng2023judging[Tab. 2]. Ein Drittel bis drei Viertel der Urteile hängen von der Reihenfolge ab.],
) <k07-fig-position>

Shi et al. haben Positionsverzerrung am systematischsten vermessen: 15 Richter, 22 Aufgaben, rund 40 antwortende Modelle und über 150 000 Bewertungsinstanzen @shi2025judging[Abstract]. Sie trennen drei Aspekte @shi2025judging[Abschn. 2.2]:

$ "RS" = 1 / N sum_(j=1)^N (max_(k in S) |C_k^j|) / n_j, quad "PC" = 1 / n sum_(j=1)^n bb(1)((C_1^j, dots, C_p^j) in V). $ <k07-eq-shi>

Die *Wiederholungsstabilität* RS mittelt über $N$ Anfragen, wie oft die häufigste Option $k$ aus der Optionsmenge $S$ in den $n_j$ Wiederholungen der Anfrage $j$ gewählt wird ($|C_k^j|$ ist die Anzahl). Die *Positionskonsistenz* PC ist der Anteil der $n$ Prompt-Serien, in denen die Urteile über alle $p$ Permutationen der Kandidaten ein konsistentes Tupel aus der Menge $V$ bilden. Die *Präferenzfairness* $"PF" in [-1, 1]$ skaliert $"PF"_"raw" = "rcn" dot "irr" - "pcn" dot "ipr"$ (Anzahl der Recency- beziehungsweise Primacy-Präferenzen mal der zugehörigen inkonsistenten Raten); $"PF" approx 0$ ist fair, $"PF" > 0$ zeigt Recency-, $"PF" < 0$ Primacy-Präferenz @shi2025judging[Abschn. 2.2]. Die Trennung ist sinnvoll: Ein Richter kann stabil (hohes RS), aber inkonsistent (niedriges PC) sein, wenn er reproduzierbar immer die erste Position wählt.

Paarweise erreichten Claude-3.5-Sonnet 0.82, GPT-4o 0.76 und Gemini-1.5-pro 0.62 PC auf MTBench @shi2025judging[Tab. 2]. Der für das Verständnis wichtigste Befund: Positionsverzerrung ist nicht zufällig, hängt nur schwach mit der Promptlänge zusammen und stark mit dem *Qualitätsabstand* der beiden Antworten. PC steigt mit dem Abstand, die Verzerrung konzentriert sich also auf fast gleichwertige Paare @shi2025judging[Abstract, Abschn. 4]. Das ist intuitiv: Wenn der Richter kein inhaltliches Signal hat, entscheidet die Position.

*Ein Signifikanztest für Positionsverzerrung.* Wenn du jedes Paar in beiden Reihenfolgen zeigst, sollte ohne Positionsverzerrung die erste Position die Hälfte aller entschiedenen (nicht unentschiedenen) Urteile gewinnen. Die Zahl $K$ der Siege der ersten Position unter $n$ entschiedenen Urteilen ist dann unter $H_0$ binomialverteilt, $K tilde "Bin"(n, 0.5)$. Das Notebook implementiert genau diesen exakten zweiseitigen Binomialtest.

#beispiel(titel: [Binomialtest auf Positionsverzerrung])[
  Von $n = 100$ entschiedenen Urteilen gewinnt die erste Position $K = 62$-mal. Der exakte zweiseitige Binomialtest ergibt $p approx 0.021$, das exakte 95-%-Konfidenzintervall (Clopper-Pearson) für den Anteil der ersten Position ist $[0.517, 0.715]$ (mit `scipy.stats.binomtest` nachgerechnet). Bei $alpha = 0.05$ verwirfst du $H_0$. Beachte, dass die beiden Urteile zu einem Paar nicht unabhängig sind, die Binomialannahme auf Urteilsebene ist also verletzt. Valide ist der Test auf Paarebene: Ein konsistentes Paar liefert genau einen Sieg jeder Position und trägt keine Information über die Richtung; du zählst nur die $f$ Paare, in denen die erste Position beide Male gewinnt, und die $g$ Paare, in denen die zweite beide Male gewinnt, und testest $f tilde "Bin"(f + g, 0.5)$ (Vorzeichentest, äquivalent zum exakten McNemar-Test). Mit $c$ konsistenten Paaren ist die Teststatistik des Urteilstests das $sqrt(2(f + g) \/ (c + f + g))$-Fache der des Paartests: Er ist zu liberal, wenn es weniger konsistente als inkonsistente Paare gibt, sonst zu konservativ. Weil die Richtung des Fehlers von den Daten abhängt, ist der Paartest vorzuziehen.
]

=== Längen- und Ausführlichkeitsverzerrung

Längenverzerrung (_verbosity bias_) ist die Bevorzugung von Antworten bestimmter Länge, meist der längeren @gu2024survey[Abschn. 4.2]. Zheng et al. testeten sie mit einem Angriff, der eine Antwort um eine "repetitive Liste" ohne neuen Inhalt verlängert (23 Antworten): Claude-v1 und GPT-3.5 fielen in 91.3 % der Fälle darauf herein, GPT-4 in 8.7 % @zheng2023judging[Tab. 3]. Gu et al. maßen für GPT-4-turbo eine Genauigkeit von 91.18 % auf der Längenverzerrungs-Teilmenge von EvalBiasBench @gu2024survey[Tab. 2]. Auf AlpacaEval bewegte bloßes Prompten von gpt4_1106_preview zu mehr oder weniger Ausführlichkeit dessen Gewinnrate zwischen 22.9 % und 64.3 % @dubois2024length[Abschn. 4.1, Abb. 3], bei identischem Inhalt.

Messen kannst du Längenverzerrung auf zwei Arten. Experimentell wie Zheng et al.: Du verlängerst Antworten ohne Informationsgewinn und zählst Urteilswechsel. Beobachtend über eine Regression: Du regressierst die binäre Präferenz auf die standardisierte Längendifferenz und prüfst den Koeffizienten. Das zweite Verfahren hat einen Haken, den du offen benennen musst: Längere Antworten *können* besser sein. Ein positiver Längenkoeffizient ist nur dann eine Verzerrung, wenn du Inhaltsqualität kontrollierst, etwa über menschliche Labels oder über das experimentelle Design. Die Längenkontrolle in @k07-gegen behandelt das formal.

=== Selbstpräferenz

Selbstpräferenz (_self-enhancement_ oder _self-preference bias_) bedeutet, dass ein Richter eigene Ausgaben höher bewertet als andere, die Menschen als gleichwertig einstufen @panickssery2024llm[Abstract] @zheng2023judging.

#studie(titel: [Panickssery, Bowman und Feng 2024])[
  *Design:* Zusammenfassungen zu 2000 Nachrichtenartikeln aus XSUM und CNN/DailyMail; GPT-4, GPT-3.5 und Llama-2-7b-chat; paarweise und individuelle Messung; Feinjustierung auf 500 Beispielen, um Selbsterkennung gezielt zu verändern; Kontrollaufgaben (Länge, Vokalzahl, Lesbarkeit, Konstante, Zufall) @panickssery2024llm[Abschn. 2-3].
  *Befund:* GPT-4 erkannte eigene Texte gegenüber zwei anderen LLMs und Menschen zu 73.5 % @panickssery2024llm[Abschn. 1]. Paarweise Selbstpräferenz von GPT-4: 0.705 (XSUM) und 0.912 (CNN) @panickssery2024llm[Tab. 7]. Feinjustierung erhöhte Selbsterkennung und Selbstpräferenz gemeinsam; Kendalls $tau$ auf Beispielebene stieg für GPT-3.5 auf XSUM von 0.41 auf 0.74 @panickssery2024llm[Tab. 1, Abb. 1]. Quellenlabels wirken: Mit korrekten Labels lag GPT-4s Selbstpräferenz auf XSUM bei 0.73, mit vertauschten bei 0.32 @panickssery2024llm[Tab. 6].
  *Grenzen:* Zwei Zusammenfassungsdatensätze, drei Modelle; der lineare Zusammenhang wird grafisch gezeigt, ohne einen angepassten Koeffizienten im Text @panickssery2024llm[Abb. 1].
]

Die Studie liefert ein kausales Argument: Wer Selbsterkennung manipuliert, verändert Selbstpräferenz mit. Daraus folgt die Regel "kein Modell richtet über die eigene Familie" und die Regel, Modellidentitäten zu verblinden. Weitere Evidenz kommt aus Arena-Hard, wo GPT-Modelle unter einem GPT-4-Turbo-Richter etwas höher und Claude-Modelle etwas niedriger rankten als bei Menschen @li2025crowdsourced[Abschn. 6.6], und aus PoLL, wo ein GPT-4-Richter eine GPT-4-Variante auf Platz 2 statt Platz 4 setzte @verga2024replacing.

#fallstrick[
  "LLM-Text wird bevorzugt" ist nicht automatisch eine Verzerrung. G-Eval-4 bevorzugte GPT-3.5-Zusammenfassungen gegenüber menschlichen @liu2023geval[Abschn. 4], aber bei einem menschlichen $alpha$ von 0.07 kann das auch echte Qualitätsunterschiede widerspiegeln @liu2023geval[Abschn. 4]. Eine Verzerrung behauptest du erst, wenn du gegen ein verlässliches Kriterium oder mit einer Manipulation (wie den vertauschten Quellenlabels) gemessen hast.
]

=== Die CALM-Taxonomie

Ye et al. haben mit CALM ein automatisiertes Perturbationsframework vorgelegt, das 12 Verzerrungstypen quantifiziert @ye2025justice[Tab. 1]. Die Idee ist ein kontrolliertes Experiment: Für jede Verzerrung wird die Eingabe des Richters gezielt verändert (Reihenfolge vertauscht, falsches Zitat eingefügt, "90 % der Menschen bevorzugen A" ergänzt), und gemessen wird, wie oft das Urteil die Störung übersteht. @k07-tab-calm fasst die Typen zusammen.

#figure(
  table(
    columns: (1.15fr, 2.6fr),
    table.header([Verzerrung], [Was sie bedeutet (Perturbation)]),
    [Position], [Urteil hängt von der Reihenfolge ab (Vertauschen)],
    [Ausführlichkeit], [längere Antworten bevorzugt (Verlängern ohne Inhalt)],
    [Compassion-Fade], [Präferenz durch gezeigte Modellnamen],
    [Bandwagon], [Antwort bevorzugt, die angeblich die Mehrheit bevorzugt],
    [Distraction], [irrelevante Details lenken ab],
    [Fallacy-Oversight], [logische Fehler übersehen, wenn das Endergebnis stimmt],
    [Autorität], [Zitate und Quellenangaben (auch erfundene) bevorzugt],
    [Sentiment], [emotionaler Ton beeinflusst das Urteil],
    [Diversität], [Behandlung hängt von genannten demografischen Gruppen ab],
    [Chain-of-Thought], [Urteil ändert sich mit CoT-Prompting],
    [Selbstverstärkung], [eigene Antworten höher bewertet],
    [Refinement-Aware], [Urteil ändert sich, wenn eine Antwort als "überarbeitet" markiert ist],
  ),
  caption: [Die 12 Verzerrungstypen der CALM-Taxonomie @ye2025justice[Tab. 1], mit der jeweiligen Perturbation in Kurzform.],
) <k07-tab-calm>

#definition(titel: [Robustheits- und Konsistenzrate in CALM])[
  Sei $D$ die Evaluationsmenge, $y_i$ das ursprüngliche Urteil, $hat(y)_i$ das Urteil nach der verzerrungsspezifischen Perturbation und $y_i^"rand"$ das Urteil in einem wiederholten, ungestörten Lauf. Dann sind
  $ "RR" = 1 / (|D|) sum_(i=1)^(|D|) bb(1)(y_i = hat(y)_i), quad "CR" = 1 / (|D|) sum_(i=1)^(|D|) bb(1)(y_i = y_i^"rand") $ <k07-eq-rr>
  die Robustheitsrate und die Konsistenzrate @ye2025justice. Selbstverstärkung und Refinement-Awareness werden als Score-Verhältnisse gemessen: $"ErrorRate"_"SE" = y_"self" \/ y_"other" - 1$ mit dem Score $y_"self"$, den ein Richter der eigenen Antwort gibt, und $y_"other"$, den andere Richter derselben Antwort geben, sowie $"ErrorRate"_"RA" = y'_"ref" \/ y_"ref" - 1$ für die Scores einer überarbeiteten Antwort ohne und mit dem Hinweis auf die Überarbeitung @ye2025justice.
]

RR ist allein nicht interpretierbar, sondern nur relativ zu CR, denn ein stochastischer Richter ändert sein Urteil auch ohne Störung @ye2025justice. Wenn CR = 0.95 ist, kann RR höchstens in diesem Bereich liegen, auch bei perfekter Robustheit gegen die Perturbation.

#beispiel(titel: [Autoritätsverzerrung mit CALM-Logik])[
  200 Paare; nach Einfügen eines erfundenen Zitats in die schlechtere Antwort bleiben 176 Urteile gleich, also $"RR" = 176 \/ 200 = 0.88$. Ein wiederholter ungestörter Lauf behält 190 Urteile, $"CR" = 0.95$. Als *Lehrheuristik* (keine CALM-Metrik) lässt sich die Differenz $"CR" - "RR" = 0.07$ als grob 7 Prozentpunkte Instabilität lesen, die über das Grundrauschen hinaus der Autoritätsperturbation zuzuschreiben sind. Konstruiertes Beispiel.
]

Die publizierten CALM-Werte zeigen vor allem eines: Der beste Richter hängt von der Verzerrung ab. Bei der Position lagen die RR-Werte bei 0.776 (GPT-4o), 0.832 (Claude-3.5), 0.818 (GPT-4-Turbo) und 0.566 (ChatGPT); beim Bandwagon-Effekt dagegen erreichte GPT-4o 0.791 und Claude-3.5 nur 0.610, den niedrigsten Wert @ye2025justice[Tab. 4]. Autorität: Claude-3.5 0.865, GPT-4o 0.787, ChatGPT 0.662 @ye2025justice[Tab. 4]. Die Selbstverstärkungs-Fehlerrate betrug 9.40 für GPT-4-Turbo, 8.18 für GPT-4o und 5.39 für Claude-3.5 @ye2025justice[Tab. 5]. Verzerrungen waren auf Alignment-Daten stärker als auf faktenbezogenen Daten, und Positionsverzerrung wuchs mit der Zahl der Kandidaten @ye2025justice. Eine Grenze: Die Perturbationen sind synthetisch und teils selbst von LLMs erzeugt @ye2025justice.

=== Menschen sind auch verzerrt: Chen et al.

#block(breakable: false, width: 100%)[#studie(titel: [Chen et al. 2024, Humans or LLMs as the Judge?])[
  *Design:* Menschliche und LLM-Richter werden auf vier Perturbationsverzerrungen verglichen, ohne Ground-Truth-Labels zu benötigen: Übersehen von Fehlinformation (Faktenfehler), Gender, Autorität (erfundene Referenzen) und Schönheit (reicher Inhalt: Emojis, Markdown). 142 Fragen nach der revidierten Bloom-Taxonomie, 60 Studierende und rund ein Dutzend LLMs; Metrik ist die Angriffserfolgsrate (_attack success rate_, ASR), also der Anteil der Items, deren Präferenz sich zur perturbierten Antwort verschiebt; niedriger ist besser @chen2024humans[Abstract, Tab. 1].
  *Befund:* Erfundene Referenzen: ASR GPT-4 0.66, Claude-3 0.70, Menschen 0.37, GPT-4o 0.32. Reicher Inhalt: Menschen 0.47, GPT-4o 0.07, Claude-3 0.04. Faktenfehler: Menschen 0.21, GPT-4o 0.06. Gender: Menschen 0.06, GPT-4-Turbo 0.27 @chen2024humans[Tab. 1].
  *Grenzen:* Kleine Fragenmenge, nur studentische Richter, GPT-4-generierte Daten @chen2024humans.
]]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let gruppen = (([Erfundene \ Referenzen], 0.37, 0.32), ([Reicher Inhalt \ (Emojis, Markdown)], 0.47, 0.07), ([Faktenfehler], 0.21, 0.06))
    let h = 4.0
    let bw = 0.55
    line((0, 0), (8.2, 0), stroke: 0.7pt + c-dark)
    line((0, 0), (0, h), stroke: 0.7pt + c-dark)
    for t in (0, 0.1, 0.2, 0.3, 0.4, 0.5) {
      line((0, t / 0.5 * h), (8.2, t / 0.5 * h), stroke: 0.3pt + luma(225))
      content((-0.1, t / 0.5 * h), anchor: "east", k07-tx(str(t)))
    }
    for (i, (lab, m, g)) in gruppen.enumerate() {
      let x = 1.3 + i * 2.7
      rect((x - bw, 0), (x, m / 0.5 * h), fill: c-accent, stroke: none)
      rect((x, 0), (x + bw, g / 0.5 * h), fill: c-blue, stroke: none)
      content((x - bw / 2, m / 0.5 * h + 0.17), k07-tx(str(m)))
      content((x + bw / 2, g / 0.5 * h + 0.17), k07-tx(str(g)))
      content((x, -0.15), anchor: "north", k07-tx(align(center, lab)))
    }
    content((-0.95, h / 2), k07-rot(-90deg, reflow: true, k07-tx([Angriffserfolgsrate (ASR)], size: 7.5pt)))
    rect((5.6, 3.65), (5.8, 3.85), fill: c-accent, stroke: none)
    content((5.9, 3.75), anchor: "west", k07-tx([Menschen (Studierende)]))
    rect((5.6, 3.3), (5.8, 3.5), fill: c-blue, stroke: none)
    content((5.9, 3.4), anchor: "west", k07-tx([GPT-4o]))
  }),
  caption: [Menschen und LLM-Richter sind unterschiedlich verzerrt: Studierende ließen sich stärker von Emojis und Markdown beeinflussen, GPT-4 (nicht abgebildet, 0.66) und Claude-3 (0.70) stärker von erfundenen Referenzen als Menschen (0.37) @chen2024humans[Tab. 1].],
) <k07-fig-chen>

Die Studie ist wertvoll, weil sie die naive Vorstellung "Menschen sind unverzerrt, LLMs verzerrt" korrigiert. Menschen und Modelle fallen auf *verschiedene* Dinge herein. Für deine Forschung bedeutet das: Welche Verzerrung schlimmer ist, hängt von der Forschungsfrage ab. Wenn du die Qualität von Literaturzusammenfassungen bewertest, ist die Autoritätsverzerrung von GPT-4 (0.66) ein ernsteres Problem als die Schönheitsverzerrung, denn erfundene Zitate sind genau der Fehler, den du finden willst.

=== Weitere dokumentierte Verzerrungen

Einige Verzerrungen tauchen in den Übersichtsarbeiten auf, ohne dass es dafür so ausgearbeitete Messverfahren gibt.

- *Stil- und Konkretheitsverzerrung*: Bevorzugung von Formatierung, Emojis, Zitaten, Zahlen und spezifischen Details @gu2024survey[Abschn. 4.2]. Arena-Hard behandelt Länge sowie Markdown-Überschriften, Fettdruck und Listen als Stilmerkmale @li2025crowdsourced[Abschn. 6.5].
- *Diversitäts- und Kulturverzerrung*: ungleiche Behandlung demografischer Gruppen oder unvertrauter kultureller Ausdrücke @gu2024survey[Abschn. 4.2].
- *Nachsichtigkeit*: Wenn der Richter vom menschlichen Label abweicht, sagt er eher "korrekt" @thakur2025judging[Abschn. 5.4] (@k07-eq-leniency).
- *Versagen ohne eigene Lösung*: Ein Richter, der die Frage selbst nicht beantworten kann, urteilt schlecht, solange er keine korrekte Referenz erhält @krumdick2025free[Tab. 4].
- *Preference Leakage und adversariale Manipulation* wie Prompt-Injection führen Li et al. unter "Bias and Vulnerability" @li2025generation[Abschn. 7.1]. Für dich als Security-Forscher ist der Punkt naheliegend: Ein Richter, der den zu bewertenden Text im Kontext liest, ist ein Ziel für Injection, und jede Arbeit, die Richter auf potenziell adversariale Ausgaben anwendet, sollte das als Validitätsbedrohung behandeln.
- *Positionseffekte in langen Dokumenten*: Das Lehrbuch berichtet für Treuebewertungen ein U-förmiges Muster, bei dem Inhalte in der Mitte langer Dokumente weniger zuverlässig bewertet werden als am Anfang oder Ende, sowie eine Abhängigkeit von der Reihenfolge der Quellen @haindl2027research. Das sind Eigenschaften der Metrik, nicht des getesteten Systems.

#k07-hs([Wenn Menschen ohnehin verzerrt sind, warum sollte ich die Verzerrungen des Richters überhaupt korrigieren?],
[Weil du die Verzerrungen des Richters *kennst und messen* kannst und weil sie systematisch über Millionen von Urteilen wirken. Menschliche Rater sind verschieden verzerrt, und über mehrere Rater mitteln sich manche Eigenheiten heraus; ein einzelner Richter repliziert seine Verzerrung dagegen in jedem Urteil. Chen et al. zeigen außerdem, dass die Verzerrungen nicht dieselben sind @chen2024humans[Tab. 1]: Ein LLM-Richter ersetzt also menschliche Verzerrungen nicht durch keine, sondern durch andere. Der richtige Schluss ist, beide zu messen und die Verzerrung zu kontrollieren, die für die eigene Forschungsfrage kritisch ist.])

== Gegenmaßnahmen <k07-gegen>

Jede Gegenmaßnahme in diesem Abschnitt adressiert eine bestimmte Verzerrung, und jede hat ihren Preis: mehr Aufrufe, mehr Annahmen oder weniger Information. Das Lehrbuch fasst die Grundhaltung zusammen: Verzerrungen durch Design kontrollieren, also Reihenfolgen randomisieren oder ausbalancieren, Länge kontrollieren und Konfigurationen vermeiden, in denen ein Modell faktisch die eigene Familie bewertet, und die Urteile an einer Stichprobe gegen menschliches Urteil validieren @haindl2027research.

=== Vertauschen und Kalibrieren

Die einfachste Gegenmaßnahme gegen Positionsverzerrung stammt von Zheng et al.: Frage zweimal mit vertauschter Reihenfolge und erkläre einen Sieg nur, wenn dieselbe Antwort beide Male gewinnt; andernfalls werte als Unentschieden @zheng2023judging[Abschn. 3.4]. Diese *Vertauschungsregel* macht Positionsinkonsistenz sichtbar, statt sie zu verstecken: Ein inkonsistentes Paar wird zum Tie. Die Kehrseite ist, dass ein stark positionsverzerrter Richter sehr viele Ties produziert und damit wenig Information liefert. Auf LLMBar verbesserte das Vertauschen vor allem die Positionsübereinstimmung (von 91.8 auf 96.2), kaum die Genauigkeit @zeng2024evaluating. Few-Shot-Beispiele hoben die Konsistenz von GPT-4 auf MT-Bench von 65.0 % auf 77.5 % @zheng2023judging[Abschn. 3.4, Tab. 13].

Wang et al. gehen weiter und kombinieren drei Bausteine @wang2024large. Bei der *Multiple Evidence Calibration* (MEC) schreibt der Richter zuerst eine Begründung (Evidenz) und dann den Score, und das wird $k$-mal mit Temperatur 1 gesampelt ($k = 3$). Bei der *Balanced Position Calibration* (BPC) wird über beide Reihenfolgen gemittelt:
$ "CS"_r = 1 / (2 k) sum_(i=1)^k (S_r^i + S_r^(prime i)). $ <k07-eq-bpc>
Hier ist $"CS"_r$ der kalibrierte Score der Antwort $r$, $S_r^i$ ihr Score in der $i$-ten Stichprobe in Originalreihenfolge und $S_r^(prime i)$ in vertauschter Reihenfolge; die Antwort mit höherem $"CS"_r$ gewinnt @wang2024large. Warum hilft das? Nimm an, der Score zerfällt in $S_r = q_r + delta dot bb(1)("r steht vorne") + epsilon$ mit wahrer Qualität $q_r$, Positionsbonus $delta$ und Rauschen $epsilon$. Im Mittel über beide Reihenfolgen erhält jede Antwort genau einmal den Bonus, die Differenz $"CS"_A - "CS"_B$ enthält also kein $delta$ mehr, und bei unabhängigem Rauschen reduziert das Mitteln über die $2 k$ Scores dessen Varianz um den Faktor $2 k$. Der additive Ansatz ist eine Modellannahme; interagiert die Positionsverzerrung mit der Qualität (wie Shi et al. nahelegen @shi2025judging[Abschn. 4]), entfernt BPC sie nur teilweise.

Der dritte Baustein ist eine Triage: Die *Balanced Position Diversity Entropy* misst, wie uneinig sich die $2 k$ Urteile sind, und schickt die unsichersten Items an Menschen @wang2024large:
$ "BPDE" = sum_("er" in {"win", "tie", "lose"}) -p_"er" log p_"er", quad p_"er" = (sum_(i=1)^k [bb(1)("ER"_i = "er") + bb(1)("ER"'_i = "er")]) / (2 k). $ <k07-eq-bpde>
$"ER"_i$ und $"ER"'_i$ sind die Ergebnisse der Stichprobe $i$ in Original- und vertauschter Reihenfolge. Die obersten $beta = 20 %$ nach BPDE gehen an menschliche Annotatoren, deren Mehrheitsvotum das Richterurteil ersetzt (_human-in-the-loop calibration_, HITLC) @wang2024large.

#block(breakable: false, width: 100%)[#beispiel(titel: [BPDE für ein instabiles Item])[
  Mit $k = 3$ liefern die sechs Urteile win, win, win, tie, lose, lose. Also $p = (3\/6, 1\/6, 2\/6) = (0.5, 0.167, 0.333)$ und
  $ "BPDE" = 0.5 ln 2 + 0.167 ln 6 + 0.333 ln 3 approx 0.347 + 0.299 + 0.366 approx 1.01 "nats". $
  Das Maximum ist $ln 3 approx 1.10$ (Gleichverteilung). Dieses Item ist ein klarer Kandidat für menschliche Prüfung.
]]

#figure(
  diagram(spacing: (6mm, 8mm),
    fknoten((0, 0), [Paar (A, B)], col: c-grey, w: 22mm),
    fknoten((1, -0.5), [Reihenfolge A, B \ $k$ Stichproben \ Evidenz, dann Score], col: c-blue, w: 32mm),
    fknoten((1, 0.5), [Reihenfolge B, A \ $k$ Stichproben \ Evidenz, dann Score], col: c-blue, w: 32mm),
    fknoten((2, 0), [BPC: Mittel über $2 k$ Scores \ (@k07-eq-bpc)], col: c-violet, w: 34mm),
    fknoten((3, 0), [BPDE hoch? \ (oberste 20 %)], col: c-yellow, w: 26mm),
    fknoten((4, -0.5), [Richterurteil übernehmen], col: c-green, w: 28mm),
    fknoten((4, 0.5), [Menschliches Mehrheitsvotum], col: c-accent, filled: true, w: 28mm),
    edge((0, 0), (1, -0.5), "-|>"), edge((0, 0), (1, 0.5), "-|>"),
    edge((1, -0.5), (2, 0), "-|>"), edge((1, 0.5), (2, 0), "-|>"),
    edge((2, 0), (3, 0), "-|>"),
    edge((3, 0), (4, -0.5), "-|>", [nein], label-side: left), edge((3, 0), (4, 0.5), "-|>", [ja], label-side: right),
  ),
  caption: [Kalibrierungs-Pipeline nach Wang et al. @wang2024large: Evidenz vor Score (MEC), Mittelung über beide Reihenfolgen (BPC) und Weitergabe der unsichersten Items an Menschen (HITLC).],
) <k07-fig-wang>

Die Wirkung auf dem Vicuna-Benchmark (80 Fragen, drei menschliche Annotatoren pro Paar, Mehrheitsvotum als Gold) ist in @k07-fig-wang-werte dargestellt: GPT-4 vanilla erreichte 52.7 % Genauigkeit und $kappa = 0.24$, mit MEC und BPC ($k = 3$) 62.5 % und 0.37, mit zusätzlich HITLC ($beta = 20 %$) 73.8 % und 0.56; menschliche Annotatoren lagen im Mittel bei 71.7 % und 0.54 @wang2024large[Tab. 4]. Die Kosten wurden auf 30.0 US-Dollar für menschliche Annotation, 23.1 US-Dollar für GPT-4 mit HITLC und 18.3 US-Dollar für ChatGPT mit HITLC geschätzt, eine Ersparnis von 39 % bei etwa menschendurchschnittlicher Genauigkeit für die ChatGPT-Pipeline @wang2024large[Tab. 4]. Halte die Grenzen fest: 80 Fragen, drei Autoren als Annotatoren, und das menschliche Gold hat selbst nur $kappa = 0.54$ @wang2024large[Tab. 4].

#figure(
  balken((
    ([GPT-4 vanilla], 0.24), ([+ MEC + BPC (k = 3)], 0.37), ([+ HITLC (20 %)], 0.56), ([Mensch (Mittel)], 0.54),
  ), max: 0.7, breite: 8, farbe: c-teal),
  caption: [Cohens Kappa gegenüber dem menschlichen Mehrheitsvotum auf dem Vicuna-Benchmark @wang2024large[Tab. 4]. Kalibrierung plus 20 % menschliche Prüfung erreicht das Niveau eines durchschnittlichen menschlichen Annotators.],
) <k07-fig-wang-werte>

#datei("swap_konflikt.py")[```python
import numpy as np

def swap_verdict(v_ab, v_ba):
    """v_ab: Sieger bei Reihenfolge A, B ('A', 'B', 'tie');
    v_ba: Sieger bei Reihenfolge B, A, bereits auf A/B zurückgemappt.
    Sieg nur bei Konsistenz, sonst Unentschieden (Zheng et al. 2023)."""
    return v_ab if v_ab == v_ba else "tie"

def conflict_rate(v_ab, v_ba):
    v_ab, v_ba = np.asarray(v_ab), np.asarray(v_ba)
    return np.mean(v_ab != v_ba)            # Konfliktrate (Wang et al. 2024)

def bpde(outcomes):
    """outcomes: 'win'/'tie'/'lose' über die 2k Stichproben (natürlicher Log)."""
    p = np.array([outcomes.count(o) for o in ("win", "tie", "lose")]) / len(outcomes)
    p = p[p > 0]
    return float(-(p * np.log(p)).sum())

print(round(bpde(["win", "win", "win", "tie", "lose", "lose"]), 3))   # 1.011
```]

=== Längen- und Stilkontrolle

Dubois et al. entfernen die Längenverzerrung aus der Gewinnrate von AlpacaEval mit einer Regressionsadjustierung, die Datenwissenschaftler aus der kausalen Inferenz kennen @dubois2024length. Sie passen ein logistisches GLM an die binäre Präferenz $y in {0, 1}$ des Richters für Modell $m$ gegenüber der Baseline $b$ auf Instruktion $x$ an @dubois2024length[Gl. 1]:
$ P(y = 1) = "logistic"((theta_m - theta_b) + phi_(m,b) tanh(("len"(z_m) - "len"(z_b)) / ("std"("len"(z_m) - "len"(z_b)))) + (psi_m - psi_b) gamma_x). $ <k07-eq-lc-glm>
Dabei sind $theta_m, theta_b$ Modellidentitätsterme, $phi_(m,b)$ der Längenkoeffizient, $z_m, z_b$ die Ausgaben, $"len"$ die Ausgabelänge, und $psi_m, psi_b, gamma_x$ Terme für die Schwierigkeit der Instruktion. Der $tanh$ sorgt für abnehmende Erträge der Länge, und eine schwache Regularisierung auf $phi$ schützt vor Abschneide-Angriffen @dubois2024length[Abschn. 3, Abschn. 4.3]. Die längenkontrollierte Gewinnrate ist die kontrafaktische Gewinnrate bei Längendifferenz null:
$ "winrate"^"LC" (m, b) = 100 dot bb(E)_x ["logistic"(theta_m - theta_b + (psi_m - psi_b) gamma_x)]. $ <k07-eq-lc>

Die Herleitung von @k07-eq-lc aus @k07-eq-lc-glm ist ein Schritt: Setze in das angepasste Modell die Längendifferenz auf null, dann verschwindet der Term $phi_(m,b) tanh(0) = 0$, und du mittelst die vorhergesagte Gewinnwahrscheinlichkeit über die Instruktionen. Das ist genau die Logik der *g-Formel* oder Standardisierung: eine Vorhersage unter einer kontrafaktischen Belegung der Störvariable, gemittelt über die Verteilung der übrigen Kovariaten. Die implizite Annahme lautet, dass Länge eine *reine* Störgröße ist. Hat Länge einen echten Nutzen, entfernt die Kontrolle auch diesen, was das Notebook ausdrücklich als Vorbehalt notiert.

#figure(
  k07-plot(w: 8, h: 3.6, x: (-3, 3), y: (-1.2, 1.2), xt: (-3, -2, -1, 0, 1, 2, 3), yt: (-1, -0.5, 0, 0.5, 1), xl: [standardisierte Längendifferenz $Delta$], yl: [Beitrag zum Logit (in Einheiten $phi$)], (sx, sy) => {
    import cetz.draw: *
    let xs = range(0, 61).map(i => -3 + i * 0.1)
    let th(v) = (calc.exp(v) - calc.exp(-v)) / (calc.exp(v) + calc.exp(-v))
    k07-kurve(xs.filter(v => calc.abs(v) <= 1.2).map(v => (v, v)), sx, sy, col: c-grey, dash: "dashed")
    k07-kurve(xs.map(v => (v, th(v))), sx, sy, col: c-blue)
    content((sx(1.3), sy(1.12)), anchor: "west", k07-tx([linear ($phi Delta$)], fill: c-grey.darken(20%)))
    content((sx(2.9), sy(0.55)), anchor: "east", k07-tx([$phi tanh(Delta)$: gesättigt], fill: c-blue, weight: "bold"))
    circle((sx(0), sy(0)), radius: 0.07, fill: c-accent, stroke: none)
    content((sx(0) + 0.15, sy(0) - 0.08), anchor: "north-west", k07-tx([LC: $Delta = 0$ gesetzt], fill: c-accent, weight: "bold"))
  }),
  caption: [Der Längenterm in @k07-eq-lc-glm. Der $tanh$ begrenzt den Einfluss extremer Längenunterschiede; die längenkontrollierte Gewinnrate wertet das Modell kontrafaktisch bei $Delta = 0$ aus @dubois2024length.],
) <k07-fig-tanh>

Die Ergebnisse überzeugen: Die Spearman-Korrelation mit Chatbot Arena stieg über 38 Modelle von 0.94 auf 0.98 @dubois2024length[Abschn. 4.2, Tab. 1]. Das Prompten zu mehr oder weniger Ausführlichkeit bewegte die rohe Gewinnrate zwischen 22.9 % und 64.3 %, die längenkontrollierte nur zwischen 41.9 % und 51.6 %; die normierte Standardabweichung sank von 25 % auf 10 % (Tab. 1 nennt 26 % für die rohe Gewinnrate) @dubois2024length[Abschn. 4.1, Abb. 3, Tab. 1]. Die Zahlen stammen aus arXiv v2; die COLM-Fassung wurde in der Wissensbasis nicht separat verglichen.

Längenkontrolle erfasst nur eine Stilvariable. Arena-Hard verallgemeinert das zur *Stilkontrolle*, die neben der Länge Markdown-Überschriften, Fettdruck und Listen als Kovariaten behandelt; damit erreichte Arena-Hard-Auto 98.6 % Übereinstimmung mit der stilkontrollierten Arena, und die Aufforderung "mehr Details" hob die Scores nicht mehr @li2025crowdsourced[Abschn. 6.5, Tab. 3, Tab. 5].

=== Panels statt Einzelrichter

Verga et al. ersetzen einen großen Richter durch eine Jury (_Panel of LLM evaluators_, PoLL) aus kleineren Modellen verschiedener Familien: Command R, Claude 3 Haiku und GPT-3.5 @verga2024replacing. Jeder Richter $j$ im Panel $P$ bewertet die Ausgabe $a$, und eine Abstimmungsfunktion aggregiert, $f({j(a) : j in P})$: Mehrheitsentscheid für binäre QA-Korrektheit, Mittelung für Scores von 1 bis 5 @verga2024replacing.

Warum sollte das helfen? Die Standardrechnung ist der Satz von Condorcet in seiner einfachsten Form, den du selbst herleiten kannst.

#satz(titel: [Mehrheitsentscheid unabhängiger Richter])[
  Seien drei Richter unabhängig voneinander mit Wahrscheinlichkeit $q$ korrekt. Dann ist der Mehrheitsentscheid mit Wahrscheinlichkeit
  $ q_"maj" = q^3 + 3 q^2 (1 - q) $ <k07-eq-maj>
  korrekt, und für $q > 0.5$ gilt $q_"maj" > q$.
]
#beweis[
  Die Mehrheit ist korrekt, wenn mindestens zwei von drei Richtern korrekt sind. Bei Unabhängigkeit ist die Zahl korrekter Richter binomialverteilt, $"Bin"(3, q)$, also $P(>= 2) = binom(3, 2) q^2 (1 - q) + q^3$. Weiter ist $q_"maj" - q = 3 q^2 - 2 q^3 - q = -q (2 q - 1)(q - 1)$, und für $0.5 < q < 1$ sind $-q < 0$, $2 q - 1 > 0$ und $q - 1 < 0$, das Produkt ist also positiv.
]

Mit $q = 0.8$ ergibt @k07-eq-maj $q_"maj" = 0.896$, mit fünf Richtern $0.942$ (mit python3 nachgerechnet; @k07-fig-condorcet). Der kritische Haken ist die Unabhängigkeit. Richter aus derselben Familie, die auf ähnlichen Daten trainiert wurden, machen korrelierte Fehler, und bei perfekt korrelierten Fehlern bringt ein Panel gar nichts. Genau deshalb betonen Verga et al. *verschiedene Familien*. Die Rechnung zeigt dir auch, wann ein Panel schadet: Liegt $q < 0.5$, etwa auf schweren Korrektheitsitems wie JudgeBench, verstärkt die Mehrheit den Fehler.

#figure(
  k07-plot(w: 7.5, h: 3.8, x: (0.5, 1.0), y: (0.5, 1.0), xt: (0.5, 0.6, 0.7, 0.8, 0.9, 1.0), yt: (0.5, 0.6, 0.7, 0.8, 0.9, 1.0), xl: [Genauigkeit $q$ eines einzelnen Richters], yl: [Genauigkeit des Mehrheitsentscheids], (sx, sy) => {
    import cetz.draw: *
    let xs = range(0, 51).map(i => 0.5 + i * 0.01)
    let m3(q) = q * q * q + 3 * q * q * (1 - q)
    let m5(q) = q * q * q * q * q + 5 * q * q * q * q * (1 - q) + 10 * q * q * q * (1 - q) * (1 - q)
    k07-kurve(xs.map(q => (q, q)), sx, sy, col: c-grey, dash: "dashed")
    k07-kurve(xs.map(q => (q, m3(q))), sx, sy, col: c-blue)
    k07-kurve(xs.map(q => (q, m5(q))), sx, sy, col: c-teal)
    circle((sx(0.8), sy(0.896)), radius: 0.06, fill: c-blue, stroke: none)
    content((sx(0.8) + 0.1, sy(0.896) - 0.05), anchor: "north-west", k07-tx([0.896]))
    content((sx(0.52), sy(0.97)), anchor: "north-west", k07-tx([5 Richter], fill: c-teal, weight: "bold"))
    content((sx(0.52), sy(0.92)), anchor: "north-west", k07-tx([3 Richter], fill: c-blue, weight: "bold"))
    content((sx(0.52), sy(0.87)), anchor: "north-west", k07-tx([1 Richter (gestrichelt)], fill: c-grey.darken(20%)))
  }),
  caption: [Mehrheitsentscheid unabhängiger Richter nach @k07-eq-maj. Der Gewinn setzt Unabhängigkeit und $q > 0.5$ voraus; korrelierte Fehler verringern ihn, bei $q < 0.5$ kehrt er sich um.],
) <k07-fig-condorcet>

Empirisch schnitt PoLL gut ab. Das Kappa mit Menschen lag bei NQ bei 0.763 (PoLL) gegenüber 0.627 (GPT-4), bei TriviaQA 0.906 gegenüber 0.841 und bei HotpotQA 0.867 gegenüber 0.830 @verga2024replacing[Tab. 1]; auf HotpotQA war allerdings Claude 3 Haiku allein mit 0.873 noch etwas besser @verga2024replacing[Tab. 1]. Die Rangkorrelation mit der Arena betrug Pearson 0.917 und Kendall 0.778 gegenüber 0.817 und 0.667 für GPT-4 @verga2024replacing[Tab. 2], und PoLL war sieben- bis achtmal billiger als ein GPT-4-Turbo-Richter @verga2024replacing. Auf Multi-Hop-QA hatte PoLL die geringste Streuung der Abweichungen von Menschen (Standardabweichung 2.2 gegenüber 6.1 für GPT-3.5) @verga2024replacing. PoLL ist ein Industrie-Preprint mit begrenztem Aufgabenspektrum; die damaligen Preise sind überholt. Auch Arena-Hard nutzt ein Ensemble: GPT-4-Turbo plus Gemini-1.5-Pro erreichte 91.5 % Übereinstimmung, 89.5 % Separierbarkeit und einen Brier-Score von 0.065 gegenüber 0.069 für den Einzelrichter @li2025crowdsourced[Tab. 4].

=== Feinjustierte offene Richter

Feinjustierte Richter versprechen Reproduzierbarkeit, Kontrolle und niedrige Kosten @kim2024prometheus2[Abstract]. Für Abschlussarbeiten ohne API-Budget sind sie oft die einzige realistische Option.

*JudgeLM* destilliert GPT-4-Urteile in Modelle mit 7B, 13B und 33B Parametern (100 000 Trainings- und 5000 Validierungsbeispiele aus 105 000 Seed-Aufgaben) und behandelt Verzerrungen gezielt durch Datenaugmentation: Vertauschen gegen Positionsverzerrung, Referenzunterstützung gegen Wissensverzerrung und Referenzentfernung gegen Formatverzerrung @zhu2025judgelm. Die "über 90 %" Übereinstimmung mit dem GPT-4-Lehrer stammen aus einem Skalierungsexperiment (90.06 %), die Hauptergebnisse für JudgeLM-33B liegen bei 89.03 % ohne und 89.32 % mit Referenz; JudgeLM-7B bewertet 5000 Beispiele in 3 Minuten auf 8 A100-GPUs @zhu2025judgelm[Tab. 1, Tab. 4, Abstract]. Beachte: Diese Übereinstimmung ist eine mit GPT-4, nicht mit Menschen.

*Prometheus* ist ein offener 13B-Bewerter, der mit Referenzantwort und eigener Rubrik GPT-4-Urteile annähert; Trainingsbasis ist die Feedback Collection mit 1000 Rubriken, 20 000 Instruktionen und 100 000 Antworten @kim2024prometheus[Abstract]. Auf 45 eigenen Rubriken erreichte er Pearson 0.897 mit menschlichen Bewertern, GPT-4 0.882 und ChatGPT 0.392 @kim2024prometheus[Abstract]. *Prometheus 2* vereint Direktbewertung und Paarvergleich durch Gewichtsverschmelzung, $theta_"final" = alpha theta_d + (1 - alpha) theta_p$ mit den Gewichten $theta_d$ des Direktbewertungs- und $theta_p$ des Paarvergleichsmodells sowie Mischkoeffizient $alpha$ (praktisch DARE-Merging) @kim2024prometheus2[Gl. 3, Abschn. 3.4]. Die Pearson-Korrelation mit GPT-4 auf MT-Bench lag bei 0.548 (7B) und 0.665 (8x7B), auf FLASK gegenüber Menschen bei 0.555 (8x7B) gegenüber 0.679 für GPT-4 @kim2024prometheus2[Tab. 3]; paarweise erreichte die 8x7B-Variante auf HHH Alignment 85.52 gegenüber 90.95 für GPT-4-1106 und auf MT-Bench-Humanurteilen ohne Ties 71.96 gegenüber 79.90 @kim2024prometheus2[Tab. 4]. Auf JudgeBench lagen Prometheus-Richter unter Zufall @tan2025judgebench[Tab. 1].

*Reward-Modelle* sind der nahe Verwandte. RewardBench zählt ein Tripel aus Prompt, bevorzugter und abgelehnter Antwort als korrekt, wenn $r(x, y_c) > r(x, y_r)$; Zufall ergibt 50 % @lambert2025rewardbench[Tab. 9]. Für DPO-trainierte Modelle ist der implizite Reward $r(x, y) = beta log (pi(y | x)) / (pi_"ref" (y | x)) + beta log Z(x)$ mit trainierter Policy $pi$, Referenzmodell $pi_"ref"$, DPO-Temperatur $beta$ und einer Partitionsfunktion $Z(x)$, die sich im Vergleich zweier Antworten auf denselben Prompt herauskürzt @lambert2025rewardbench[Gl. 2]. In RewardBench war das beste Klassifikator-RM (ArmoRM-Llama3-8B-v0.1, 89.0) knapp vor dem besten generativen Richter (Gemini-1.5-pro-0514, 88.1); die besten offenen generativen Richter lagen bei 75.4 (Llama-3-70B-Instruct) und 75.3 (prometheus-8x7b-v2.0) @lambert2025rewardbench[Tab. 2, Tab. 7, Tab. 9]. RewardBench 2 ist schwerer (Best-of-4, Zufall 25 %, rund 20 Punkte niedrigere Scores, 1865 Prompts) @malik2026rewardbench[Abstract, Tab. 2], korreliert über 113 RMs mit Pearson 0.87 mit Best-of-N-Leistung @malik2026rewardbench[Abb. 3] und zeigt generative Richter nun auf den Plätzen 2, 3 und 5 (LMUnit-qwen2.5-72b 82.1, LMUnit-llama3.1-70b 80.5, Gemini 2.5 Pro 79.5) hinter Skywork-Reward-V2-Llama-3.1-8B mit 84.1 @malik2026rewardbench[Tab. 3] (Stand: 11. November 2026, Camera-ready-Fassung).

#k07-hs([Sollte eine Masterarbeit einen proprietären Richter wie GPT-4o verwenden oder ein offenes Modell?],
[Beides hat Kosten. Proprietäre Richter werfen Reproduzierbarkeitsprobleme auf, weil Modellversionen verschwinden und sich still ändern @bavaresco2025llms[Abstract]. Offene feinjustierte Richter sind reproduzierbar, liegen aber außerhalb ihrer Trainingsdomäne klar hinter GPT-4 @kim2024prometheus2[Tab. 4] und versagen auf schweren Korrektheitspaaren @tan2025judgebench[Tab. 1]. Meine Empfehlung für Abschlussarbeiten: Die Validierung gegen Menschen entscheidet, nicht der Name des Modells. Wenn ein offenes Modell auf der eigenen Validierungsstichprobe ausreichend übereinstimmt, ist es wegen der Reproduzierbarkeit vorzuziehen; wenn nur ein proprietäres Modell ausreicht, dokumentierst du den exakten Versionsstring und das Abfragedatum und archivierst alle Rohurteile.])

=== Reasoning-Richter und trainiertes Denken

Die jüngste Entwicklung sind Richter, die vor dem Urteil "nachdenken". Auf JudgeBench stieg derselbe Arena-Hard-Richterprompt von 50.86 % (GPT-4o) auf 80.86 % mit o3-mini bei hohem Reasoning-Aufwand @tan2025judgebench[Tab. 1-2]. Auf Präferenzdaten (LLMEval2) waren Reasoning-Modelle dagegen nicht durchgängig besser als GPT-4-turbo: o1-mini, o3-mini, DeepSeek-R1 und gemini-2.0-thinking lagen zwischen 56.48 % und 61.66 % Übereinstimmung, GPT-4-turbo bei 61.54 % @gu2024survey[Tab. 2, Abschn. 4.4]. Eine plausible Arbeitshypothese für die Lehre lautet: Reasoning hilft dort, wo das Urteil das Lösen der Aufgabe erfordert (Mathematik, Code, Faktenprüfung), weniger dort, wo es menschlichen Geschmack treffen muss. Die beiden Befunde stützen sie, eine kontrollierte Studie dazu liegt in der geprüften Wissensbasis aber nicht vor.

Drei Systeme trainieren das Denken explizit. *EvalPlanner* schreibt einen unbeschränkten Bewertungsplan, führt ihn aus und urteilt dann; trainiert wird durch iteratives Selbsttraining auf synthetischen Plänen @saha2025learning[Abstract]. In der Vergleichstabelle von J1 erreicht EvalPlanner-70B 93.8 auf RewardBench und 67.9 auf PPE @whitehouse2026j1[Tab. 1-2]. *J1* wandelt Urteilsaufgaben in ein Format mit verifizierbaren Rewards um und trainiert mit Online-RL (GRPO) auf 22 000 synthetischen Präferenzpaaren; belohnt werden Urteilskorrektheit und Korrektheit in beiden Reihenfolgen, also Positionskonsistenz @whitehouse2026j1. J1-70B erreicht PPE 69.6, RewardBench 93.3, JudgeBench 60.0 und RM-Bench 82.7 @whitehouse2026j1[Tab. 1, Tab. 2]; DeepSeek-R1 (671B) liegt auf JudgeBench mit 68.9 vorn @whitehouse2026j1[Tab. 2]. Bemerkenswert ist, dass ein punktweiser J1, der nur aus paarweisen Labels trainiert wurde, positionskonsistenter ist als der paarweise (65.0 % gegenüber 61.2 % positionskonsistente Genauigkeit) @whitehouse2026j1[Tab. 3]: Positionskonsistenz lässt sich hineintrainieren, statt sie per Vertauschen zu flicken. *RM-R1* versteht Reward-Modellierung als Reasoning mit einer "Chain of Rubrics": Das Modell klassifiziert die Aufgabe und schreibt dann gewichtete Rubriken (Chat) oder löst das Problem zuerst (Reasoning) @chen2026rmr1[Abstract]. Auf RewardBench erreicht RM-R1 Qwen-Instruct-32B 91.4 gegenüber 86.7 für GPT-4o, ein skalares 70B-RM in derselben Tabelle aber 95.1; auf RM-Bench liegt die DeepSeek-destillierte 32B-Variante mit 83.9 klar vor dem besten skalaren Vergleichsmodell (70.9) @chen2026rmr1[Tab. 1] Die RM-R1-Werte stammen aus arXiv v3, deren Zusammenfassung der ICLR-Fassung entspricht; v1 nannte noch 92.9 auf RewardBench.

#figure(
  table(
    columns: (1.2fr, 1.6fr, 1.5fr, 1.6fr),
    table.header([Ansatz], [Gegen welche Verzerrung], [Preis], [Beleg]),
    [Vertauschen (Swap)], [Position], [2x Aufrufe, mehr Ties], [@zheng2023judging[Abschn. 3.4]],
    [MEC + BPC + HITLC], [Position, Rauschen], [$2 k$ Aufrufe, 20 % Menschen], [$kappa$ 0.24 -> 0.56 @wang2024large[Tab. 4]],
    [Längenkontrolle (LC)], [Länge], [entfernt auch echten Längennutzen], [Spearman 0.94 -> 0.98 @dubois2024length],
    [Stilkontrolle], [Länge, Markdown], [Modellannahmen], [98.6 % @li2025crowdsourced[Abschn. 6.5]],
    [Panel (PoLL)], [Selbstpräferenz, Varianz], [Unabhängigkeit nötig], [7-8x billiger @verga2024replacing],
    [Feinjustierter Richter], [Kosten, Reproduzierbarkeit], [schwach außerhalb der Domäne], [@kim2024prometheus2[Tab. 4]],
    [Reasoning-Richter], [Korrektheit schwerer Items], [Kosten, Latenz], [50.86 -> 80.86 % @tan2025judgebench],
  ),
  caption: [Gegenmaßnahmen im Überblick: Wirkung, Preis und Beleg.],
) <k07-tab-gegen>

#tipp[
  Wenn du nur eine einzige Gegenmaßnahme implementierst, dann das Vertauschen mit Berichten der Konfliktrate. Es kostet einen zweiten Aufruf, ist trivial zu implementieren und liefert dir gleichzeitig eine Diagnose der Instrumentenqualität: Eine Konfliktrate von 30 % sagt dir mehr über deinen Richter als jede Herstellerangabe.
]

== Statistische Grenzen <k07-grenzen>

Bisher ging es darum, ob ein Richter gut misst. Jetzt geht es um eine schärfere Frage: Wenn du einen Richter mit einer kleinen menschlich gelabelten Stichprobe kombinierst, wie viel menschliche Arbeit kannst du damit *höchstens* sparen? Die Antwort ist ernüchternd und gehört zu den wichtigsten Ergebnissen der jüngeren Literatur.

=== Richterlabels als Proxy-Messung

Ein Richterscore, der als Zielgröße dient, etwa "Anteil korrekter Antworten von System A", ist eine Proxy-Messung mit systematischem Fehler, durch Nachsichtigkeit, Länge und Selbstpräferenz. Thakur et al. zeigen, dass Richter mit über 90 % Prozentübereinstimmung den Score eines Prüflingsmodells um mehr als 10 Punkte falsch schätzen können, und selbst die besten Richter (Scotts $pi$ über 0.80) um bis zu 5 Punkte @thakur2025judging[Abschn. 4.1]. Die praktische Konsequenz kennst du aus Kapitel 6: Du behältst eine zufällig gezogene, menschlich gelabelte Teilstichprobe, berichtest die Richter-Mensch-Übereinstimmung darauf und verwendest sie, um nachgelagerte Schätzungen zu entzerren.

=== Wiederholung: PPI als Kontrollvariate

Sei $s in {0, 1}$ der wahre (menschliche) Score eines Items und $tilde(s)$ der Richterscore. Gesucht ist $theta = bb(E)[s]$. Du hast $n$ Items mit beiden Labels und $N$ zusätzliche Items nur mit Richterlabel. Der klassische Schätzer nutzt nur die $n$ menschlichen Labels, $hat(theta)_"klass" = overline(s)_n$, mit Varianz $"Var"(s) \/ n$. Der PPI-Schätzer aus Kapitel 6 in der abgestimmten Form (PPI++) ist
$ hat(theta)_lambda = lambda dot overline(tilde(s))_N + 1 / n sum_(i=1)^n (s_i - lambda tilde(s)_i). $ <k07-eq-ppi>
Für jedes $lambda$ ist er unverzerrt, denn $bb(E)[hat(theta)_lambda] = lambda bb(E)[tilde(s)] + bb(E)[s] - lambda bb(E)[tilde(s)] = theta$ @angelopoulos2023prediction @angelopoulos2023ppi. Für $lambda = 1$ erhältst du das ursprüngliche PPI: Richtermittel plus mittlerer Korrekturterm ("Rektifikator").

#satz(titel: [Effizienzschranke für PPI-artige Schätzer])[
  Im Grenzfall $N -> infinity$ ist die minimale Varianz von @k07-eq-ppi gleich $(1 - rho^2) "Var"(s) \/ n$, wobei $rho$ die Pearson-Korrelation von $s$ und $tilde(s)$ ist. Der Stichprobeneffizienzfaktor, also der Faktor, mit dem sich die menschliche Stichprobe effektiv vervielfacht, ist damit
  $ tau = 1 / (1 - rho^2). $ <k07-eq-tau>
  Dorner, Nastl und Hardt zeigen außerdem, dass kein unverzerrter Black-Box-Schätzer (einer, der die promptbedingte Verteilung nicht modelliert) mit diesen Stichproben eine kleinere Varianz hat als optimal abgestimmtes PPI @dorner2025limits[Prop. 4, Thm. 5].
]
#beweis[
  Für $N -> infinity$ ist $overline(tilde(s))_N$ deterministisch gleich $bb(E)[tilde(s)]$, die Varianz stammt allein aus dem zweiten Term: $"Var"(hat(theta)_lambda) = "Var"(s - lambda tilde(s)) \/ n = ("Var"(s) - 2 lambda "Cov"(s, tilde(s)) + lambda^2 "Var"(tilde(s))) \/ n$. Das ist eine nach oben offene Parabel in $lambda$ mit Minimum bei $lambda^* = "Cov"(s, tilde(s)) \/ "Var"(tilde(s))$. Einsetzen ergibt $"Var"(s) - "Cov"(s, tilde(s))^2 \/ "Var"(tilde(s)) = "Var"(s)(1 - rho^2)$. Der klassische Schätzer mit $n'$ Labels hat Varianz $"Var"(s) \/ n'$; gleiche Varianz erfordert $n' = n \/ (1 - rho^2)$, also $tau = 1 \/ (1 - rho^2)$. Dabei ist $lambda^*$ als bekannt unterstellt; PPI++ schätzt $lambda$ aus den Daten, was asymptotisch dieselbe Varianz liefert. Für endliches $N$ kommt der Term $lambda^2 "Var"(tilde(s)) \/ N$ hinzu, der Faktor ist dann kleiner. Das ist die bekannte Kontrollvariaten-Rechnung; die Optimalitätsaussage für Black-Box-Schätzer ist ein Cramér-Rao-Argument @dorner2025limits[Thm. 5].
]

#beispiel(titel: [Was ist ein Richter mit $rho = 0.6$ wert?])[
  Nach @k07-eq-tau ist $tau <= 1 \/ (1 - 0.36) = 1.5625 approx 1.56$. 1000 menschliche Labels, kombiniert mit beliebig vielen Richterlabels, sind höchstens so viel wert wie rund 1560 rein menschliche Labels. Für binäre Labels ist die Pearson-Korrelation gleich dem Matthews-Korrelationskoeffizienten; das Notebook prüft diese Identität mit `matthews_corrcoef`.
]

#figure(
  k07-plot(w: 8, h: 4.0, x: (0, 1), y: (1, 6), xt: (0, 0.2, 0.4, 0.6, 0.8, 1.0), yt: (1, 2, 3, 4, 5, 6), xl: [Korrelation $rho$ zwischen Richter- und menschlichem Label], yl: [Effizienzfaktor $tau = 1 \/ (1 - rho^2)$], (sx, sy) => {
    import cetz.draw: *
    let xs = range(0, 92).map(i => i * 0.01)
    k07-kurve(xs.map(r => (r, 1 / (1 - r * r))), sx, sy, col: c-blue)
    line((sx(0), sy(2)), (sx(1), sy(2)), stroke: (paint: c-red, thickness: 0.9pt, dash: "dashed"))
    line((sx(0.7071), sy(1)), (sx(0.7071), sy(2)), stroke: (paint: c-red, thickness: 0.6pt, dash: "dotted"))
    content((sx(0.02), sy(2) + 0.17), anchor: "west", k07-tx([$tau = 2$ (Kor. 7: $rho^2 <= 0.5$)], fill: c-red, weight: "bold"))
    content((sx(0.7071), sy(1) + 0.15), anchor: "south-west", k07-tx([$rho = 0.707$], fill: c-red))
    circle((sx(0.6), sy(1.5625)), radius: 0.06, fill: c-accent, stroke: none)
    content((sx(0.42), sy(1.68)), k07-tx([1.56 bei $rho = 0.6$], fill: c-accent))
  }),
  caption: [Schranke für den Stichprobeneffizienzfaktor @dorner2025limits[Prop. 4]. Erst ab $rho > 0.707$ verdoppelt ein Richter die effektive menschliche Stichprobe, und genau diese Region ist unter den Annahmen von Dorner et al. für binäre Scores ausgeschlossen.],
) <k07-fig-tau>

=== Die Faktor-zwei-Schranke von Dorner et al.

Für binäre Scores lässt sich $rho$ durch drei interpretierbare Größen ausdrücken. Sei $b = P(s = 1)$ die wahre Genauigkeit des bewerteten Modells, $p = P(tilde(s) = s | s = 1)$ und $q = P(tilde(s) = s | s = 0)$ die bedingten Trefferraten des Richters, und
$ "AG" = b p + (1 - b) q $ <k07-eq-ag>
die Übereinstimmung des Richters mit der Ground Truth @dorner2025limits[Abschn. 2-3].

*Herleitung von $rho^2$.* Der Richter sagt mit Wahrscheinlichkeit $c = P(tilde(s) = 1) = b p + (1 - b)(1 - q)$ "korrekt". Dann ist $"Cov"(s, tilde(s)) = bb(E)[s tilde(s)] - b c = b p - b c = b (1 - b)(p + q - 1)$, wobei der letzte Schritt $p - c = (1 - b)(p + q - 1)$ verwendet. Mit $"Var"(s) = b (1 - b)$ und $"Var"(tilde(s)) = c (1 - c)$ folgt
$ rho^2 = (b (1 - b)(p + q - 1)^2) / (c (1 - c)). $ <k07-eq-rho-binaer>

#satz(titel: [Faktor-zwei-Schranke, Dorner et al. 2025])[
  Seien Scores binär und betrachte unverzerrte Schätzer wie in @k07-eq-ppi. Gilt
  $ 0.5 <= "AG" <= b, $
  stimmt der Richter also mindestens zur Hälfte mit der Ground Truth überein, aber *nicht häufiger, als das bewertete Modell seine Aufgabe richtig löst*, dann ist $rho^2 <= 0.5$ und damit $tau <= 2$, unabhängig davon, wie groß $N$ ist. In Worten: Richterlabels können die Zahl benötigter Ground-Truth-Labels um höchstens die Hälfte reduzieren @dorner2025limits[Thm. 6, Kor. 7].
]
#beweis[
  Wir zeigen nur den symmetrischen Spezialfall; der allgemeine Fall mit $p != q$ ist Thm. 6 bei Dorner et al. und wird hier nicht bewiesen. *Annahmen:* (A1) $s$ und $tilde(s)$ sind binär, und es gilt $0 < b < 1$ sowie $0 < c < 1$, sonst ist $rho$ nicht definiert. (A2) Der Richter ist symmetrisch, $p = q = a$; dann ist $"AG" = a$, und die Bedingung lautet $0.5 <= a <= b$, was insbesondere $b >= 0.5$ erzwingt. (A3) Die Schranke für $tau$ ist die aus @k07-eq-tau, also für optimal abgestimmtes $lambda$ und $N -> infinity$; für endliches $N$ ist der Gewinn nur kleiner.

  *Schritt 1 (Umparametrisierung).* Setze $u = 2 a - 1 in [0, 1]$ und $w = 2 b - 1 in [0, 1)$. Ausmultiplizieren ergibt $c = b a + (1 - b)(1 - a) = (1 + u w) \/ 2$, also $c (1 - c) = (1 - u^2 w^2) \/ 4$, und $b (1 - b) = (1 - w^2) \/ 4$. Mit $(p + q - 1)^2 = u^2$ wird @k07-eq-rho-binaer zu
  $ rho^2 = ((1 - w^2) u^2) / (1 - w^2 u^2). $ <k07-eq-rho-sym>

  *Schritt 2 (Monotonie).* Als Funktion von $x = u^2 in [0, 1]$ ist $f(x) = (1 - w^2) x \/ (1 - w^2 x)$ mit Ableitung $f'(x) = (1 - w^2) \/ (1 - w^2 x)^2 > 0$ für $w^2 < 1$. Also wächst $rho^2$ für festes $b$ streng in $a$ auf $[0.5, 1]$, und unter der Nebenbedingung $a <= b$ liegt das Maximum am Rand $a = b$, also $u = w$.

  *Schritt 3 (Randwert).* Für $u = w$ folgt aus @k07-eq-rho-sym $rho^2 = w^2 (1 - w^2) \/ (1 - w^4) = w^2 \/ (1 + w^2)$; in $b$ ausgedrückt ist das $(2 b - 1)^2 \/ (2 (b^2 + (1 - b)^2))$, die Kurve in @k07-fig-rho-rand.

  *Schritt 4 (Schranke).* $w^2 \/ (1 + w^2) <= 1\/2$ ist äquivalent zu $w^2 <= 1$ und gilt damit immer; Gleichheit nur für $w = 1$, also $b = 1$, was (A1) ausschließt. Somit $rho^2 < 1\/2$ und $tau = 1 \/ (1 - rho^2) < 2$ für jeden symmetrischen Richter mit $0.5 <= a <= b < 1$. Die Schranke wird nur im Grenzfall eines nahezu perfekten Modells mit gleich gutem Richter fast erreicht.
]

Die Bedingung "$"AG" <= b$" ist der Kern und zugleich der Punkt, an dem du die Schranke im Hörsaal ehrlich einordnen musst. Die Autoren betonen selbst, dass das Theorem "nur gilt", wenn der Richter beim Vorhersagen von $s$ weniger fähig ist als das bewertete Modell bei seiner Aufgabe @dorner2025limits[Abschn. 6]. Das ist genau die Situation an der Forschungsfront, für die der Titel "Limits to Scalable Evaluation at the Frontier" steht: Wer das beste verfügbare Modell bewertet, hat keinen klügeren Richter. Ist der Richter deutlich besser, etwa ein Flaggschiffmodell, das ein kleines Modell bewertet, kann der Gewinn größer sein. Eine Verallgemeinerung begrenzt den Faktor durch $2 \/ epsilon$, wenn der Richter höchstens einen Anteil $epsilon$ der Fehler des bewerteten Modells macht @dorner2025limits[Anh., Thm. 16].

#figure(
  k07-plot(w: 8, h: 3.6, x: (0.5, 1.0), y: (0, 0.6), xt: (0.5, 0.6, 0.7, 0.8, 0.9, 1.0), yt: (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6), xl: [Genauigkeit $b$ des bewerteten Modells (= Übereinstimmung $a$ des Richters)], yl: [$rho^2$ am Rand $"AG" = b$], (sx, sy) => {
    import cetz.draw: *
    let xs = range(0, 50).map(i => 0.5 + i * 0.01)
    k07-kurve(xs.map(b => (b, (2 * b - 1) * (2 * b - 1) / (2 * (b * b + (1 - b) * (1 - b))))), sx, sy, col: c-violet)
    line((sx(0.5), sy(0.5)), (sx(1.0), sy(0.5)), stroke: (paint: c-red, thickness: 0.9pt, dash: "dashed"))
    content((sx(0.52), sy(0.5) + 0.16), anchor: "west", k07-tx([$rho^2 = 0.5$, also $tau = 2$], fill: c-red, weight: "bold"))
    for (b, r) in ((0.7, 0.1379), (0.9, 0.3902)) {
      circle((sx(b), sy(r)), radius: 0.06, fill: c-violet, stroke: none)
    }
    content((sx(0.7) + 0.1, sy(0.1379) - 0.05), anchor: "north-west", k07-tx([$b = 0.7$: $tau <= 1.16$]))
    content((sx(0.9) + 0.1, sy(0.3902) - 0.05), anchor: "north-west", k07-tx([$b = 0.9$: $tau <= 1.64$]))
  }),
  caption: [Symmetrischer Richter am Rand der Annahme ($p = q = b$) nach @k07-eq-rho-sym: $rho^2$ nähert sich 0.5 nur für fast perfekte Modelle. Eigene Rechnung zur Beweisskizze.],
) <k07-fig-rho-rand>

#beispiel(titel: [Annahme erfüllt und verletzt])[
  *Erfüllt:* Ein Modell beantwortet 90 % der Fragen richtig ($b = 0.9$), der Richter erkennt richtige und falsche Antworten jeweils mit 0.9 ($p = q = 0.9$, also $"AG" = 0.9 = b$). Nach @k07-eq-rho-binaer ist $c = 0.82$, $rho^2 = 0.09 dot 0.64 \/ (0.82 dot 0.18) approx 0.390$ und $tau <= 1.64$.
  *Verletzt:* Ein schwaches Modell mit $b = 0.4$ wird von einem starken Richter mit $p = q = 0.95$ bewertet ($"AG" = 0.95 > b$). Dann ist $rho^2 approx 0.804$ und $tau <= 5.09$. Hier sind große Einsparungen möglich, aber nur, weil das Urteilen viel leichter ist als die Aufgabe. Alle Werte mit python3 nachgerechnet; konstruierte Szenarien.
]

Zwei weitere Ergebnisse von Dorner et al. solltest du kennen. Erstens garantiert hohe Übereinstimmung allein keinen Gewinn: Für jedes $"AG" in [0.5, 1)$ gibt es Fälle mit $tau_max = 1$ @dorner2025limits[Prop. 8]. Zweitens kann ein schwächerer Richter die Rangfolge strikt besserer Modelle vollständig umkehren, und eine Übereinstimmung $r$ ist mit einer Richterverzerrung der Größe $1 - r$ vereinbar, sofern $r >= b$ @dorner2025limits[Prop. 1-2]. Empirisch blieb $tau_max$ auf MMLU und MT-Bench unter 2, oft deutlich, mit einer Ausnahme: auf MMLU, wenn Flaggschiff-Richter das viel schwächere Llama-2-7B bewerteten, wo die Annahme von Kor. 7 stark verletzt ist @dorner2025limits[Abschn. 3.7].

#fallstrick[
  Die Faktor-zwei-Aussage ist *kein* allgemeines Gesetz "Richter sparen höchstens die Hälfte". Sie gilt für binäre Scores, für unverzerrte Schätzer eines Mittelwerts und unter $0.5 <= "AG" <= b$ @dorner2025limits[Thm. 6, Kor. 7, Abschn. 6]. Wer sie ohne diese Annahmen zitiert, macht denselben Fehler wie jemand, der "GPT-4 stimmt zu 85 % mit Menschen überein" ohne den Zusatz "ohne Ties" zitiert.
]

#datei("tau_schranke.py")[```python
import numpy as np

def tau_bound(rho):
    return 1 / (1 - rho**2)                       # Dorner et al. 2025, Prop. 4

def rho2_binary(b, p, q):
    c = b * p + (1 - b) * (1 - q)                 # P(Richter sagt "korrekt")
    return b * (1 - b) * (p + q - 1) ** 2 / (c * (1 - c))

def ppi_mean(s_lab, j_lab, j_unlab, lam=1.0):
    """PPI(++)-Schätzer: Richtermittel auf N + Korrektur auf n (Kap. 6)."""
    return lam * np.mean(j_unlab) + np.mean(s_lab - lam * j_lab)

print(round(tau_bound(0.6), 4))                    # 1.5625
print(round(1 / (1 - rho2_binary(0.9, 0.9, 0.9)), 2))    # 1.64
print(round(1 / (1 - rho2_binary(0.4, 0.95, 0.95)), 2))  # 5.09
```]

#k07-hs([Wenn ein Richter an der Front höchstens die Hälfte der menschlichen Labels spart, lohnt sich der Aufwand dann überhaupt?],
[Oft ja, aber aus anderen Gründen als gedacht. Erstens ist eine Halbierung der Expertenkosten in vielen Projekten viel Geld. Zweitens gilt die Schranke für die Schätzung eines *Mittelwerts*; für Triage (welche Items sieht sich ein Mensch an?) und für explorative Analysen ist der Richter auch ohne Effizienzgewinn nützlich. Drittens fällt die Schranke, wenn das Urteilen leichter ist als die Aufgabe, etwa Verifikation gegenüber Generierung @dorner2025limits[Abschn. 6]. Was nicht geht: einen Richter einsetzen und *ganz* auf menschliche Labels verzichten. Dann ist die Schätzung nicht nur ineffizient, sondern verzerrt, und du weißt nicht wie stark.])

=== Der Alternative-Annotator-Test

Dorner et al. beantworten die Frage "wie viel spart der Richter?". Calderon, Reichart und Dror beantworten eine andere: Darf das LLM die menschlichen Annotatoren einer Aufgabe *ersetzen*? Statt einer absoluten Kappa-Schwelle schlagen sie einen relativen Test vor, der das LLM mit jedem einzelnen Annotator vergleicht @calderon2025alternative[Abschn. 3].

#definition(titel: [Alternative-Annotator-Test (alt-test)])[
  Gegeben seien $m$ menschliche Annotatoren und $n$ Items.
  + Für jeden Annotator $j$ und jedes Item $i$ berechnest du einen Übereinstimmungswert des LLM $f$ mit den *übrigen* Annotatoren, $S(f, x_i, j)$, und denselben Wert für Annotator $j$, $S(h_j, x_i, j)$ (negativer RMSE für kontinuierliche, Genauigkeit für diskrete Labels, Embedding-Ähnlichkeit für Freitext) @calderon2025alternative[Abschn. 3.1].
  + Vorteilswahrscheinlichkeiten: $rho_j^f$ ist der Anteil der Items, auf denen das LLM mindestens so gut abschneidet wie Annotator $j$; $rho_j^h$ der Anteil, auf dem Annotator $j$ mindestens so gut abschneidet wie das LLM @calderon2025alternative[Abschn. 3.2].
  + Pro Annotator wird $H_(0 j): rho_j^f <= rho_j^h - epsilon$ gegen $H_(1 j): rho_j^f > rho_j^h - epsilon$ getestet (gepaarter t-Test, Wilcoxon-Vorzeichen-Rang-Test für $n < 30$), mit Benjamini-Yekutieli-Korrektur bei $q = 0.05$ @calderon2025alternative[Abschn. 3.3].
  + Die Gewinnrate ist $omega = 1/m |{j : H_(0 j) "verworfen"}|$; das LLM besteht, wenn $omega >= 0.5$ @calderon2025alternative[Abschn. 3.3].
  + Die mittlere Vorteilswahrscheinlichkeit $rho = 1/m sum_(j=1)^m rho_j^f$ ist die Wahrscheinlichkeit, dass das LLM mindestens so gut ist wie ein zufällig gewählter Annotator, und eignet sich zum Vergleich von Richtern @calderon2025alternative[Abschn. 3.4].
]

Der Parameter $epsilon$ kodiert die Kosten-Nutzen-Abwägung: wie viel schlechter als ein Mensch du im Tausch gegen Kostenersparnis akzeptierst. Empfohlen sind 0.2 für Experten, 0.15 für geschulte Annotatoren und 0.1 für Crowdworker @calderon2025alternative[Abschn. 3.3, Anh. B.1]. Empfohlen sind außerdem mindestens 3 Annotatoren und 50 bis 100 Items, mindestens 30 für den t-Test @calderon2025alternative[Abschn. 1, Abschn. 6]. Die Benjamini-Yekutieli-Korrektur kontrolliert die False Discovery Rate auch unter beliebiger Abhängigkeit der Tests; das ist hier nötig, weil alle $m$ Tests dieselben LLM-Labels verwenden. Sie verwirft nach Sortieren der $p$-Werte $p_((1)) <= dots <= p_((m))$ alle Hypothesen bis zum größten $k$ mit $p_((k)) <= k q \/ (m c(m))$, wobei $c(m) = sum_(i=1)^m 1\/i$ (Notebook, Abschnitt 5).

#figure(
  diagram(spacing: (6mm, 7mm),
    fknoten((0, 0), [$m >= 3$ Annotatoren, \ $n = 50$ bis $100$ Items], col: c-grey, w: 34mm),
    fknoten((1, 0), [Leave-one-annotator-out: \ $S(f, x_i, j)$ vs. $S(h_j, x_i, j)$], col: c-blue, w: 40mm),
    fknoten((2, 0), [Vorteilswahrscheinlichkeiten \ $rho_j^f$, $rho_j^h$], col: c-blue, w: 34mm),
    fknoten((2, 1), [Test je Annotator \ $H_(0 j): rho_j^f <= rho_j^h - epsilon$], col: c-violet, w: 38mm),
    fknoten((1, 1), [BY-Korrektur \ $q = 0.05$], col: c-violet, w: 26mm),
    fknoten((0, 1), [$omega >= 0.5$? \ LLM darf ersetzen], col: c-accent, filled: true, w: 30mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (2, 1), "-|>"),
    edge((2, 1), (1, 1), "-|>"), edge((1, 1), (0, 1), "-|>"),
  ),
  caption: [Ablauf des Alternative-Annotator-Tests @calderon2025alternative[Abschn. 3]. $epsilon$ wird vorab festgelegt und begründet (0.1 bis 0.2 je nach Annotatorenexpertise).],
) <k07-fig-alttest>

#beispiel(titel: [alt-test mit vier Annotatoren])[
  $m = 4$ Annotatoren. Nach der BY-Korrektur wird $H_(0 j)$ für drei von ihnen verworfen. Also $omega = 3 \/ 4 = 0.75 >= 0.5$, und das LLM besteht beim gewählten $epsilon$. Wäre $H_(0 j)$ nur für einen Annotator verworfen worden, wäre $omega = 0.25$, und das LLM würde durchfallen. Konstruiertes Beispiel.
]

In der Studie bestand auf neun von zehn Datensätzen mindestens eine Kombination aus LLM und Prompting-Technik; im Zero-Shot-Setting bestand auf MT-Bench und SummEval kein LLM @calderon2025alternative[Abschn. 5, Tab. 2]. Geschlossene Modelle (GPT-4o, Gemini) schnitten meist besser ab als die getesteten offenen (Llama-3.1, Mistral-v3); Few-Shot half, Chain-of-Thought schadete oft @calderon2025alternative[Abschn. 5, Tab. 3]. Die Studie umfasst 10 Datensätze, 6 LLMs und 4 Prompting-Techniken @calderon2025alternative[Abstract].

#merke[
  Kappa-Schwellen beantworten "wie gut stimmt der Richter überein?", der alt-test beantwortet "ist er mindestens so gut wie die Menschen, die ich sonst bezahlen würde?", die Dorner-Schranke beantwortet "wie viele menschliche Labels spare ich für einen Mittelwert höchstens?". Das sind drei verschiedene Fragen, und deine Arbeit sollte die beantworten, die zur Forschungsaussage passt.
]

=== Bezug zu Kapitel 6: der praktische Weg

Für eine eigene Studie, die einen Anteil oder Mittelwert schätzen will, ergibt sich daraus ein klares Rezept. Ziehe aus allen zu bewertenden Items eine *zufällige* Stichprobe von $n$ Items und lass sie von Menschen labeln. Lass den Richter alle Items bewerten. Schätze $theta$ mit dem PPI-Schätzer aus @k07-eq-ppi und seinem Konfidenzintervall (Kapitel 6), nicht mit dem rohen Richtermittel. Berichte die geschätzte Korrelation $hat(rho)$ auf der gelabelten Stichprobe und den resultierenden Effizienzfaktor; das Notebook vergleicht die Schranke $1 \/ (1 - hat(rho)^2)$ mit der empirischen Varianzreduktion. Erwarte keinen größeren Faktor als etwa 2, solange dein Richter nicht deutlich besser urteilt, als das bewertete System seine Aufgabe löst @dorner2025limits[Kor. 7, Abschn. 6]. Das Lehrbuch ergänzt die allgemeine Regel: Ein Evaluationsergebnis ist eine statistische Schätzung und wird mit Konfidenzintervall, über mehrere Läufe und mit Signifikanztest für Systemunterschiede berichtet @haindl2027research.

== Arenen und das Bradley-Terry-Modell <k07-arena>

Paarweise Urteile, ob von Menschen oder Richtern, ergeben zunächst nur eine lange Liste von "A schlägt B". Um daraus eine Rangfolge mit Unsicherheit zu machen, brauchst du ein statistisches Modell. Chatbot Arena sammelt crowdgesourcte paarweise Stimmen zwischen anonymen Modellen auf von Nutzern gewählten Prompts und passt ein Bradley-Terry-Modell an @chiang2024chatbot[Abschn. 3-5]. Stand 21. Januar 2024 umfasste die Plattform 243 329 Konversationen und Stimmen, 90 051 Nutzer und 50 Modelle in 149 Sprachen; die Sammlung begann im April 2023 @chiang2024chatbot[Tab. 1, Abschn. 3.2]. Die menschlichen Präferenzdaten der Arena sind zugleich die Referenz, gegen die richterbasierte Benchmarks wie Arena-Hard-Auto und AlpacaEval LC validiert werden @li2025crowdsourced[Tab. 1] @dubois2024length.

=== Herleitung des Bradley-Terry-Modells

#definition(titel: [Bradley-Terry-Modell])[
  Für $M$ Modelle mit latenten Stärken $xi in RR^M$ ist die Wahrscheinlichkeit, dass Modell $m$ gegen Modell $m'$ gewinnt,
  $ P(m succ m') = 1 / (1 + e^(xi_(m') - xi_m)) = sigma(xi_m - xi_(m')), $ <k07-eq-bt>
  mit der logistischen Funktion $sigma(z) = 1 \/ (1 + e^(-z))$. Weil das Modell invariant gegenüber Addition einer Konstanten zu allen $xi_m$ ist, wird $xi_1 = 0$ fixiert @chiang2024chatbot[Abschn. 4, Gl. 2].
]

Woher kommt die logistische Form? Eine saubere Herleitung geht über ein Zufallsnutzenmodell. Angenommen, ein Bewerter nimmt die Qualität einer Antwort von Modell $m$ als $U_m = xi_m + epsilon_m$ wahr, wobei die Störterme $epsilon_m$ unabhängig und standard-Gumbel-verteilt sind, und er wählt die Antwort mit größerem $U$. Die Differenz zweier unabhängiger standard-Gumbel-Variablen ist standard-logistisch verteilt. Dann gilt
$ P(m succ m') = P(epsilon_(m') - epsilon_m < xi_m - xi_(m')) = sigma(xi_m - xi_(m')), $
also genau @k07-eq-bt. Mit normalverteilten Störtermen erhielte man stattdessen das Thurstone-Modell mit Probit-Link; beide Modelle unterscheiden sich in der Praxis wenig. Die Herleitung macht die zentrale Annahme sichtbar: Jedes Modell hat *eine* skalare Stärke, unabhängig vom Prompt und vom Gegner, und die Störterme sind über Duelle unabhängig. Daraus folgt starke stochastische Transitivität: Gilt $P(A succ B) >= 1\/2$ und $P(B succ C) >= 1\/2$, dann ist $P(A succ C) >= max(P(A succ B), P(B succ C))$, weil $xi_A - xi_C = (xi_A - xi_B) + (xi_B - xi_C)$ beide nichtnegativen Differenzen übersteigt und $sigma$ monoton ist. Zyklische Präferenzen (A schlägt B, B schlägt C, C schlägt A, jeweils mehrheitlich) kann das Modell also nicht abbilden.

#figure(
  k07-plot(w: 8, h: 3.6, x: (-4, 4), y: (0, 1), xt: (-4, -2, 0, 2, 4), yt: (0, 0.25, 0.5, 0.75, 1.0), xl: [Stärkedifferenz $xi_m - xi_(m')$], yl: [$P(m succ m')$], (sx, sy) => {
    import cetz.draw: *
    let xs = range(0, 81).map(i => -4 + i * 0.1)
    k07-kurve(xs.map(v => (v, 1 / (1 + calc.exp(-v)))), sx, sy, col: c-blue)
    line((sx(0.5), sy(0)), (sx(0.5), sy(0.6225)), stroke: (paint: c-accent, thickness: 0.8pt, dash: "dashed"))
    line((sx(-4), sy(0.6225)), (sx(0.5), sy(0.6225)), stroke: (paint: c-accent, thickness: 0.8pt, dash: "dashed"))
    circle((sx(0.5), sy(0.6225)), radius: 0.06, fill: c-accent, stroke: none)
    content((sx(0.5) - 0.12, sy(0.6225) + 0.12), anchor: "south-east", k07-tx([$Delta xi = 0.5$: $P approx 0.62$], fill: c-accent, weight: "bold"))
  }),
  caption: [Das Bradley-Terry-Modell nach @k07-eq-bt. Eine Stärkedifferenz von 0.5 entspricht einer Gewinnwahrscheinlichkeit von rund 62 % @chiang2024chatbot[Gl. 2].],
) <k07-fig-bt>

*Schätzung.* Für $T$ Duelle $t$ mit Modellen $a_t, b_t$ und Ergebnis $y_t = 1$, falls $a_t$ gewinnt, ist die Log-Likelihood
$ ell(xi) = sum_(t=1)^T [y_t log sigma(xi_(a_t) - xi_(b_t)) + (1 - y_t) log sigma(xi_(b_t) - xi_(a_t))]. $ <k07-eq-bt-ll>
Das ist eine logistische Regression ohne Achsenabschnitt auf Designvektoren $x_t$ mit $+1$ an der Stelle $a_t$, $-1$ an der Stelle $b_t$ und sonst 0. Chiang et al. minimieren entsprechend die binäre Kreuzentropie @chiang2024chatbot[Gl. 3]. Wegen $sigma'(z) = sigma(z)(1 - sigma(z))$ ist der Gradient
$ (partial ell) / (partial xi_m) = sum_(t=1)^T x_(t m) (y_t - sigma(xi_(a_t) - xi_(b_t))), $
und die Bedingung erster Ordnung hat eine schöne Interpretation: Im Optimum ist für jedes Modell die *beobachtete* Zahl der Siege gleich der *erwarteten* Zahl der Siege. Die Log-Likelihood ist konkav; mit der Fixierung $xi_1 = 0$ und einem verbundenen Vergleichsgraphen ist sie streng konkav, das Optimum also eindeutig, sofern es existiert. Es existiert nicht, wenn sich die Modelle in zwei Gruppen teilen lassen, von denen eine nie gegen die andere verloren hat: Dann wächst $ell$ unbeschränkt, wenn du die Stärken der ungeschlagenen Gruppe gegen unendlich schiebst. Der Vergleichsgraph muss also verbunden sein und darf keine solche Trennung zulassen.

#beispiel(titel: [Bradley-Terry mit drei Modellen])[
  *Einfache Wahrscheinlichkeit:* Aus $xi_A - xi_B = 0.5$ folgt $P(A succ B) = 1 \/ (1 + e^(-0.5)) approx 0.62$.
  *Maximum-Likelihood:* Je 100 Duelle: A schlägt B 60-mal, B schlägt C 60-mal, A schlägt C 70-mal. Mit $xi_A = 0$ liefert die numerische Maximierung von @k07-eq-bt-ll $xi_B approx -0.417$ und $xi_C approx -0.834$. Die angepassten Gewinnwahrscheinlichkeiten sind $0.603$ (A gegen B), $0.603$ (B gegen C) und $0.697$ (A gegen C). Die beobachteten Siege (A: 130, B: 100, C: 70) stimmen exakt mit den erwarteten überein, wie die Bedingung erster Ordnung verlangt. Das Modell glättet die drei Rohraten zu einem transitiven Muster. Mit python3 und `scipy.optimize` nachgerechnet.
]

*Bradley-Terry statt Elo.* Chatbot Arena startete mit einem Online-Elo-System und wechselte zu BT-Koeffizienten, weil BT "besser für die statistische Schätzung" geeignet sei @chiang2024chatbot[Abschn. 4]. Der Zusammenhang wird aus dem Gradienten sofort klar: Das Elo-Update $xi_a <- xi_a + K(y_t - sigma(xi_a - xi_b))$ ist ein stochastischer Gradientenschritt auf derselben Likelihood mit Schrittweite $K$ (das klassische Elo rechnet mit Basis 10 und Skalenfaktor 400 statt mit $e$; das ändert nur die Einheit von $xi$). Elo hängt dadurch von der Reihenfolge der Duelle ab und konvergiert bei fester Schrittweite nicht, während der BT-Schätzer alle Daten gemeinsam und reihenfolgeunabhängig auswertet.

*Gewichtung und Unsicherheit.* Bei ungleichmäßiger Stichprobenziehung der Paare wird jede Beobachtung mit $1 \/ P(A_t)$ gewichtet, der inversen Wahrscheinlichkeit, mit der das Paar $A_t$ gezogen wurde @chiang2024chatbot[Gl. 7]. Für Konfidenzintervalle stehen Pivot-Bootstrap und Sandwich-Standardfehler zur Verfügung; die Plattform verwendet Sandwich-Intervalle mit einer gleichmäßigen $chi^2_(1 - alpha, M - 1)$-Korrektur für approximative Rangfolgen @chiang2024chatbot[Abschn. 5, Anh. A]. Aktives Sampling zieht Paar $a$ mit Wahrscheinlichkeit proportional zur erwarteten Verringerung der Intervallbreite,
$ P_t (a) prop sqrt(hat(Sigma)_(t, a, a) / (|{t : A_t = a}|)) - sqrt(hat(Sigma)_(t, a, a) / (|{t : A_t = a}| + 1)), $ <k07-eq-active>
mit geschätzter Kovarianz $hat(Sigma)$; für eine Zielpräzision von 0.2 brauchte das 4400 statt 6800 Stichproben @chiang2024chatbot[Abschn. 5, Gl. 9, Abschn. 7.1].

#datei("bradley_terry.py")[```python
import numpy as np
from sklearn.linear_model import LogisticRegression

def fit_bt(battles, models):
    """battles: Liste von (modell_a, modell_b, a_gewinnt 0/1).
    Liefert BT-Koeffizienten; das erste Modell ist auf 0 fixiert."""
    idx = {m: i for i, m in enumerate(models)}
    X = np.zeros((len(battles), len(models)))
    y = np.zeros(len(battles))
    for r, (a, b, a_wins) in enumerate(battles):
        X[r, idx[a]], X[r, idx[b]], y[r] = 1.0, -1.0, a_wins
    clf = LogisticRegression(fit_intercept=False, C=1e6).fit(X[:, 1:], y)
    return np.concatenate([[0.0], clf.coef_.ravel()])

def bootstrap_ci(battles, models, n_boot=1000, seed=0):
    rng = np.random.default_rng(seed)
    coefs = [fit_bt([battles[i] for i in rng.integers(0, len(battles), len(battles))], models)
             for _ in range(n_boot)]
    return np.percentile(np.array(coefs), [2.5, 97.5], axis=0)
```]

Der Code folgt der Skizze in der Wissensbasis der LV; `C=1e6` macht die Regularisierung von scikit-learn praktisch wirkungslos, sodass das Ergebnis der Maximum-Likelihood-Schätzung entspricht.

=== Benchmarks validieren: Separierbarkeit statt nur Spearman

Wenn ein richterbasierter Benchmark die Arena ersetzen soll, wie prüfst du das? Spearman zwischen Benchmark- und Arena-Ranking ist das naheliegende Maß, aber ein schwaches. Li et al. definieren für Arena-Hard drei schärfere Maße @li2025crowdsourced[Abschn. 3, Anh. A.1]:

- *Separierbarkeit mit Konfidenz*: Anteil der Modellpaare, deren gebootstrappte Konfidenzintervalle sich nicht überlappen.
- *Übereinstimmung mit Konfidenz*: Für jedes Paar $+1$, wenn Benchmark und menschliches Ranking das Paar beide sicher trennen und übereinstimmen, $-1$, wenn beide trennen und widersprechen, sonst 0; gemittelt über die Paare.
- *Pair-Rank-Brier-Score*:
$ "Brier" = 1 / N sum_({i, j}) (hat(P)(f^*(pi_i) < f^*(pi_j)) - O_(pi_i prec pi_j))^2 $ <k07-eq-brier>
mit $N$ Modellpaaren $pi_i, pi_j$, der gebootstrappten Wahrscheinlichkeit $hat(P)$ des Benchmarks, dass $pi_i$ niedriger abschneidet als $pi_j$, und dem menschlichen Ergebnisindikator $O$ @li2025crowdsourced[Gl. 3].

#beispiel(titel: [Separierbarkeit])[
  10 Modelle ergeben $binom(10, 2) = 45$ Paare. Haben 39 davon nicht überlappende 95-%-Konfidenzintervalle, ist die Separierbarkeit $39 \/ 45 approx 86.7 %$.
]

#figure(
  k07-plot(w: 8, h: 3.8, x: (0.5, 6.5), y: (0, 100), xt: (), yt: (0, 20, 40, 60, 80, 100), xl: [Modelle (konstruiert, nach Score sortiert)], yl: [Benchmark-Score mit 95-%-KI], (sx, sy) => {
    import cetz.draw: *
    let a = ((1, 22, 6), (2, 35, 5), (3, 48, 5), (4, 61, 5), (5, 74, 4), (6, 86, 4))
    let b = ((1, 40, 14), (2, 46, 15), (3, 52, 14), (4, 57, 15), (5, 63, 14), (6, 68, 15))
    for (x, m, h) in a {
      line((sx(x - 0.15), sy(m - h)), (sx(x - 0.15), sy(m + h)), stroke: 1.4pt + c-blue)
      circle((sx(x - 0.15), sy(m)), radius: 0.06, fill: c-blue, stroke: none)
    }
    for (x, m, h) in b {
      line((sx(x + 0.15), sy(m - h)), (sx(x + 0.15), sy(m + h)), stroke: 1.4pt + c-accent)
      circle((sx(x + 0.15), sy(m)), radius: 0.06, fill: c-accent, stroke: none)
    }
    content((sx(0.7), sy(95)), anchor: "west", k07-tx([Benchmark A: hohe Separierbarkeit], fill: c-blue, weight: "bold"))
    content((sx(0.7), sy(85)), anchor: "west", k07-tx([Benchmark B: gleiche Rangfolge, kaum trennbar], fill: c-accent, weight: "bold"))
  }),
  caption: [Warum Spearman nicht reicht: Beide konstruierten Benchmarks ordnen die sechs Modelle identisch (Spearman 1.0), aber nur A trennt die Paare mit Konfidenz. Genau dieses Muster zeigen MT-Bench und Arena-Hard-Auto @li2025crowdsourced[Tab. 1].],
) <k07-fig-separierbarkeit>

Die Befunde für die echten Benchmarks sind lehrreich: Arena-Hard-Auto erreichte 87.4 % Separierbarkeit, 90.9 % Übereinstimmung mit Konfidenz und 93.2 % Spearman; MT-Bench 22.6 %, 26.6 % und 89.9 %; AlpacaEval 2.0 LC 83.2 %, 82.5 % und 91.9 % @li2025crowdsourced[Tab. 1]. Spearman unterscheidet die Benchmarks kaum, Separierbarkeit sehr deutlich. Arena-Hard-Auto umfasst 500 Prompts, die BenchBuilder aus Crowd-Daten nach sieben Qualitätskriterien auswählt (Spezifität, Domänenwissen, Komplexität, Problemlösen, Kreativität, technische Genauigkeit, Praxisbezug); bewertet wird mit GPT-4-Turbo gegen die Baseline gpt-4-0314 auf einer fünfstufigen Präferenzskala, mit zwei Durchgängen pro Prompt in vertauschter Reihenfolge, wobei der Richter zuerst eine eigene Antwort schreibt @li2025crowdsourced[Abschn. 4.1, Abschn. 5-6.1]. Die Autoren berichten dreifach höhere Separierbarkeit als MT-Bench, 98.6 % Korrelation mit menschlichen Präferenzrankings und Kosten von 20 US-Dollar @li2025crowdsourced[Abstract]. Ein kleiner Widerspruch: Der Text nennt 90.8 %, Tabelle 1 90.9 % für die Übereinstimmung @li2025crowdsourced[Abschn. 6.2]. Arena-Hard-Auto v2.0 erschien am 23. April 2025 mit 500 schweren und 250 kreativen Prompts und GPT-4.1 oder Gemini-2.5 als Richter (Stand: 11. November 2026).

=== Die Leaderboard Illusion

Arena-Rankings hängen davon ab, wie Duelle gezogen werden und welche Modelle im Pool bleiben. Hier setzt eine der meistdiskutierten Arbeiten der letzten Jahre an.

#studie(titel: [Singh et al. 2025, The Leaderboard Illusion])[
  *Design:* Audit von rund 2 Millionen Duellen, 243 öffentlichen Modellen von 42 Anbietern (Januar 2024 bis April 2025), plus Simulationen von Best-of-N-Privattests und von BT-Rankings unter Deprecation @singh2025leaderboard[Abschn. 2, Tab. 1].
  *Befund:* Ein Anbieter (Meta) testete vor einem Release 27 private Varianten @singh2025leaderboard[Abstract]. Geschätzte Datenanteile: Google 19.2 %, OpenAI 20.4 %, 83 Open-Weight-Modelle zusammen 29.7 % @singh2025leaderboard[Abstract]. Zugang zu Arena-Daten brachte relative Gewinne von bis zu 112 % auf der Arena-Verteilung (gemessen auf ArenaHard) @singh2025leaderboard[Abstract]. 205 der 243 öffentlichen Modelle wurden still entfernt, gegenüber 47 offiziell gelisteten @singh2025leaderboard[Abschn. 4.1]. Identische Checkpoints erzielten 1069 und 1052 @singh2025leaderboard[Abschn. 3.3]. In der Simulation hebt das Testen von 10 Varianten den erwarteten besten Score um rund 100 Punkte @singh2025leaderboard[Abschn. 3.2, Abb. 7]. Simulationen zeigen außerdem, dass Deprecation mitten in der Sammlung oder ein dünner Vergleichsgraph BT-Rankings von der wahren Stärkeordnung wegbewegen @singh2025leaderboard[Abschn. 5.1-5.2, Abb. 14-15].
  *Grenzen:* Die "rund 100 Punkte" stammen aus einer Simulation mit normalverteilten Scores, nicht aus einer Messung auf Arena-Daten @singh2025leaderboard[Abschn. 3.2]. Die Zahlen sind aus arXiv; die NeurIPS-Camera-ready-Fassung wurde in der Wissensbasis nicht verglichen.
]

Der statistische Kern des Privattest-Arguments ist ein Selektionseffekt, den du selbst nachrechnen kannst. Angenommen, ein Anbieter testet $N$ Varianten gleicher wahrer Stärke $mu$, deren gemessene Scores unabhängig $cal(N)(mu, sigma^2)$-verteilt sind, und veröffentlicht nur die beste. Dann ist der erwartete veröffentlichte Score $mu + sigma e_N$ mit $e_N = bb(E)[max(Z_1, dots, Z_N)]$ für standardnormale $Z_i$, also
$ e_N = integral_(-infinity)^infinity z dot N phi(z) Phi(z)^(N - 1) dif z, $ <k07-eq-emax>
wobei $phi$ und $Phi$ Dichte und Verteilungsfunktion der Standardnormalverteilung sind. Numerisch ist $e_1 = 0$, $e_2 approx 0.564$, $e_5 approx 1.163$, $e_(10) approx 1.539$, $e_(27) approx 1.998$ und $e_(50) approx 2.249$ (mit python3 durch numerische Integration berechnet). Die Inflation wächst also langsam, asymptotisch wie $sqrt(2 ln N)$, aber sie ist nie null, solange die Messung rauscht. Ob 10 Varianten 100 Punkte oder viel weniger bringen, hängt allein von $sigma$ ab, also davon, wie viele Stimmen jede Variante erhält. Genau an diesem Punkt setzt die Gegenrede an.

#figure(
  k07-plot(w: 8, h: 3.6, x: (0, 50), y: (0, 2.5), xt: (1, 10, 20, 30, 40, 50), yt: (0, 0.5, 1.0, 1.5, 2.0, 2.5), xl: [Zahl $N$ privat getesteter Varianten], yl: [erwartete Inflation in Einheiten $sigma$], (sx, sy) => {
    import cetz.draw: *
    let pts = ((1, 0.0), (2, 0.5642), (3, 0.8463), (5, 1.163), (10, 1.5388), (15, 1.7359), (20, 1.8675), (27, 1.9983), (30, 2.0428), (40, 2.1608), (50, 2.2491))
    k07-kurve(pts, sx, sy, col: c-violet)
    for (n, e) in pts { circle((sx(n), sy(e)), radius: 0.045, fill: c-violet, stroke: none) }
    content((sx(10) + 0.1, sy(1.5388) - 0.08), anchor: "north-west", k07-tx([$N = 10$: $1.54 sigma$]))
    content((sx(27), sy(1.9983) + 0.12), anchor: "south", k07-tx([$N = 27$: $2.00 sigma$]))
  }),
  caption: [Selektionseffekt beim Veröffentlichen der besten von $N$ gleich starken Varianten nach @k07-eq-emax. Eigene Rechnung unter der Normalverteilungsannahme der Simulation von Singh et al. @singh2025leaderboard[Abschn. 3.2]; die Größe in Arena-Punkten hängt von der Messstreuung $sigma$ ab.],
) <k07-fig-bestofn>

=== Die Gegenrede von LMArena

Ausgewogen wird die Debatte erst mit der Antwort der Arena-Betreiber @lmarena2025response. LMArena bestreitet mehrere Punkte. Offene Modelle machten nach eigener Statistik 40.9 % des Leaderboards aus, nicht 8.8 %. Die 8.8 % sind die Zahl, gegen die sich LMArena wendet; in der hier ausgewerteten arXiv-Fassung von Singh et al. ist sie nicht lokalisiert, und sie ist ein anderes Maß als der oben genannte Anteil an Duelldaten (29.7 %). Die eigene Analyse beziffert den Vorteil durch Vorab-Tests auf etwa +11 Punkte nach 50 Tests und 3000 Stimmen, mit abnehmender Tendenz bei frischen Stimmen. Die Checkpoint-Scores 1069 und 1052/1054 hätten überlappende Konfidenzintervalle. Der 112-%-Gewinn sei auf Arena-Hard gemessen, einem LLM-bewerteten statischen Benchmark, nicht auf menschlichen Stimmen; das geben Singh et al. selbst so an, strittig ist also nicht die Messung, sondern ihre Aussagekraft für die Arena. Und die Richtlinie zu Vorab-Tests sei seit 1. März 2024 öffentlich @lmarena2025response. Zugleich kündigte LMArena Änderungen an: mehrere Vorab-Varianten ausdrücklich zuzulassen, zurückgezogene Modelle zu kennzeichnen und Scores als "vorläufig" zu markieren, wenn mehr als 10 Modelle parallel getestet werden @lmarena2025response. Beachte, dass diese Antwort ein nicht begutachteter Blogbeitrag einer betroffenen Organisation ist, dass aber auch die "rund 100 Punkte" der Gegenseite aus einer Simulation stammen und nicht aus Arena-Daten. Die NeurIPS-Fassung von Singh et al. kann von arXiv abweichen (etwa beim Anteil offener Modelle und bei den Checkpoint-Scores); prüfe vor dem Unterrichten, welche Zahlen dort stehen.

Für die Lehre ist die Einordnung klar: Beide Papiere teilen die BT-Maschinerie; sie streiten darüber, ob der Stichprobenprozess, der sie speist, fair ist @chiang2024chatbot @singh2025leaderboard. Beide Seiten akzeptieren, dass selektive Veröffentlichung der besten privaten Variante die Scores im Erwartungswert aufbläht, was @k07-eq-emax formal zeigt; sie streiten über die Größe in der Praxis. Singh et al. empfehlen, Scores nicht zurückzuziehen, private Varianten zu begrenzen, gleiche Entfernungsregeln anzuwenden, fair (aktiv) zu sampeln und Deprecations zu veröffentlichen @singh2025leaderboard[Abschn. 1, Abschn. 6]. Aus Sicht der Forschungsmethodik ist das Thema ein Lehrbuchbeispiel für den "Garten der verzweigten Pfade", übertragen auf Modelle: Wer viele Varianten testet und nur die beste berichtet, hat ein Multiplizitätsproblem.

#k07-hs([Darf ich in einer Arbeit mit einem Arena-Ranking argumentieren, etwa "Modell X ist laut LMArena das beste"?],
[Mit Einschränkungen. Ein Arena-Ranking ist eine Messung menschlicher Präferenz auf einer nicht gezielt gezogenen Stichprobe von Prompts, mit Konfidenzintervallen, die du mitzitieren solltest @chiang2024chatbot[Abschn. 5]. Es sagt nichts über deine Aufgabe aus, und Unterschiede innerhalb überlappender Intervalle sind keine Rangunterschiede. Zusätzlich ist die Validität der Stichprobenziehung umstritten @singh2025leaderboard @lmarena2025response. Für eine Modellwahl in deiner Studie ist ein Pilot auf deiner eigenen Aufgabe mit deinem eigenen Validierungsprotokoll immer überzeugender als ein Leaderboard-Platz.])

== Agent-as-a-Judge <k07-agent>

Je mehr LLM-Systeme als Agenten arbeiten, desto weniger reicht es, nur das Endprodukt zu bewerten. Ein Code-Agent hinterlässt ein Repository, Zwischenschritte und Logdateien; ob eine Anforderung erfüllt ist, sieht man oft erst, wenn man Dateien öffnet, Code liest oder einen Test ausführt. Zhuge et al. übertragen deshalb die Richteridee auf Agenten: Ein agentisches System mit Modulen, die einen Projektgraphen aufbauen, Dateien lokalisieren und lesen, Trajektorien abrufen und Rückfragen stellen, bewertet Code-generierende Agenten Anforderung für Anforderung @zhuge2025agent[Abstract].

#figure(
  diagram(spacing: (6mm, 7mm),
    fknoten((0, 0.5), [Bewerteter Agent \ (MetaGPT, GPT-Pilot, OpenHands)], col: c-grey, w: 34mm),
    fknoten((1, 0), [Arbeitsbereich \ Code, Dateien], col: c-grey, w: 28mm),
    fknoten((1, 1), [Trajektorie \ Zwischenschritte], col: c-grey, w: 28mm),
    fknoten((2, 0.5), [*Agent-as-a-Judge* \ graph, locate, read, \ retrieve, ask], col: c-blue, filled: true, w: 34mm),
    fknoten((3, 0), [Anforderung $r_k$ \ (hierarchisch)], col: c-violet, w: 28mm),
    fknoten((3, 1), [Urteil je Anforderung \ erfüllt / nicht erfüllt], col: c-teal, w: 32mm),
    fknoten((2, 1.7), [Memory, Planning \ (in der Studie schädlich bzw. instabil)], col: c-red, w: 40mm),
    edge((0, 0.5), (1, 0), "-|>"), edge((0, 0.5), (1, 1), "-|>"),
    edge((1, 0), (2, 0.5), "-|>"), edge((1, 1), (2, 0.5), "-|>"),
    edge((3, 0), (2, 0.5), "-|>"), edge((2, 0.5), (3, 1), "-|>"),
    edge((2, 1.7), (2, 0.5), "-", dash: "dashed", stroke: c-red),
  ),
  caption: [Architektur von Agent-as-a-Judge nach Zhuge et al. @zhuge2025agent[Abschn. 4.1]. Der Richter inspiziert Arbeitsartefakte, statt nur die Endausgabe zu lesen; die beste Konfiguration verzichtete auf Memory- und Planungsmodule.],
) <k07-fig-agent>

#studie(titel: [Zhuge et al. 2025, Agent-as-a-Judge])[
  *Design:* Benchmark DevAI mit 55 Aufgaben, 365 hierarchischen Anforderungen und 125 Präferenzen; bewertet werden MetaGPT, GPT-Pilot und OpenHands (gpt-4o als Backend); drei menschliche Experten als Referenz @zhuge2025agent[Abstract, Tab. 2].
  *Befund:* Übereinstimmung mit dem menschlichen Konsens (Black-Box-Setting): Agent-as-a-Judge 83.88 % bis 90.44 %, LLM-as-a-Judge 60.38 % bis 84.15 % @zhuge2025agent[Tab. 3]. Einzelne menschliche Bewerter stimmten zu 76.23 % bis 92.63 % mit dem Konsens überein, paarweise Uneinigkeit zwischen Menschen lag bei etwa 10 % bis 30 % @zhuge2025agent. Kosten: 30.58 US-Dollar und 118.43 Minuten gegenüber geschätzten 1297.50 US-Dollar und 86.5 Stunden für drei Experten, also 2.36 % der Kosten und 2.28 % der Zeit. Der Satz im Paper nennt "2.29 % der Kosten und 2.36 % der Zeit", was nicht zu den eigenen Zahlen passt @zhuge2025agent[Abschn. 4.4]. Ein Memory-Modul erwies sich als "schädlich", weil sich Fehler früherer Urteile fortpflanzten, das Planungsmodul als "instabil"; die beste Konfiguration nutzte graph, locate, read, retrieve und ask @zhuge2025agent[Abschn. 4.1, Anh. K].
  *Grenzen:* Eine Domäne (KI-Codegenerierung), Konsens von drei Experten als Gold, menschliche Kosten unter Annahme von 15 US-Dollar pro Stunde @zhuge2025agent[Abschn. 4.4].
]

Die Kostenrechnung ist schnell nachvollzogen: $30.58 \/ 1297.50 approx 0.0236$ und $118.43 \/ (86.5 dot 60) = 118.43 \/ 5190 approx 0.0228$. Für dich als Betreuer ist an dieser Studie zweierlei interessant. Erstens zeigt sie, dass ein Richter *Werkzeuge* haben kann und dass Werkzeugzugriff die Übereinstimmung mit Menschen deutlich hebt. Zweitens bleibt die Validierungslogik dieselbe wie im Rest des Kapitels: Agent-as-a-Judge wurde gegen menschliche Experten validiert, und die menschliche Uneinigkeit von 10 % bis 30 % setzt die Obergrenze dafür, was "gute Übereinstimmung" überhaupt bedeuten kann. Für die Evaluation agentischer Workflows (Kapitel 10) ist das der derzeit konkreteste Ansatz in der geprüften Literatur.

#fallstrick[
  Mehr Module sind nicht automatisch besser. Dass ein Memory-Modul Fehler fortpflanzt @zhuge2025agent[Abschn. 4.1], ist ein allgemeines Muster: Jede Komponente, die frühere Urteile in spätere einspeist, korreliert die Fehler und hebelt damit genau die Unabhängigkeit aus, auf der Mehrheitsentscheid und Mittelung beruhen (@k07-eq-maj).
]

== Ein Validierungsprotokoll für eigene Studien <k07-protokoll>

Dieser Abschnitt bündelt das Kapitel in ein Protokoll, das du für eigene Arbeiten und als Vorgabe für Masterarbeiten verwenden kannst. Jeder Schritt ist in der zitierten Evidenz verankert; die Reihenfolge ist eine Synthese für die Lehre aus der Wissensbasis der LV. @k07-fig-protokoll zeigt den Ablauf.

#figure(
  diagram(spacing: (10mm, 7mm),
    fknoten((0, 0), [1 Konstrukt und Kriterien \ (Drift einplanen)], col: c-blue, w: 40mm),
    fknoten((1, 0), [2 Format und Referenz], col: c-blue, w: 40mm),
    fknoten((2, 0), [3 Prompt-Design \ Evidenz vor Score], col: c-blue, w: 40mm),
    fknoten((2, 1), [4 Menschliche Validierung \ (Zufallsstichprobe, $>= 3$ Rater)], col: c-teal, w: 40mm),
    fknoten((1, 1), [5 Übereinstimmung \ $kappa$, $pi$, Konfusionsmatrix], col: c-teal, w: 40mm),
    fknoten((0, 1), [6 Bias-Audit \ Swap, Länge, Selbst, $P_+$], col: c-violet, w: 40mm),
    fknoten((0, 2), [7 Gegenmaßnahmen \ alt-test], col: c-violet, w: 40mm),
    fknoten((1, 2), [8 Stresstest \ harte Korrektheitsitems], col: c-violet, w: 40mm),
    fknoten((2, 2), [9 Unsicherheit \ KI, PPI-Korrektur], col: c-accent, w: 40mm),
    fknoten((2, 3), [10 Bericht \ Version, Prompt, Kosten], col: c-accent, filled: true, w: 40mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (2, 1), "-|>"),
    edge((2, 1), (1, 1), "-|>"), edge((1, 1), (0, 1), "-|>"), edge((0, 1), (0, 2), "-|>"),
    edge((0, 2), (1, 2), "-|>"), edge((1, 2), (2, 2), "-|>"), edge((2, 2), (2, 3), "-|>"),
    edge((1, 1), (0, 0), "-|>", dash: "dashed", bend: -20deg),
  ),
  caption: [Zehnstufiges Validierungsprotokoll für einen LLM-Richter als Messinstrument. Gestrichelt: die Rückkopplung von der Übereinstimmungsanalyse zur Rubrik bei Kriteriendrift, die vor dem Einfrieren der Rubrik erlaubt ist @shankar2024validates.],
) <k07-fig-protokoll>

+ *Konstrukt und Kriterien definieren und mit Drift rechnen.* Schreibe Kriterien pro Dimension und plane mindestens eine Runde ein, in der du Ausgaben bewertest, bevor du die Rubrik einfrierst, denn Nutzer brauchen Kriterien zum Bewerten, und das Bewerten hilft, die Kriterien zu definieren @shankar2024validates[Abschn. 1, Abschn. 7.3.1]. Trenne Treue und Faktizität @haindl2027research.
+ *Format und Referenz wählen.* Paarweise für relative Systemvergleiche, punktweise mit Rubrik für absolute Qualität, eine verifizierte Referenzantwort für Aufgaben mit richtiger Antwort, wo referenzgestützte Bewertung die Fehler von 14/20 auf 3/20 senkte @zheng2023judging[Tab. 4], und Stufenbeschreibungen wie bei rubrikbasierten Richtern @kim2024prometheus2[Abschn. 3.1]. Nur korrekte Referenzen helfen @krumdick2025free[Tab. 3].
+ *Prompt-Design.* Verlange Evidenz oder Begründung vor dem Score @wang2024large @kim2024prometheus2[Abschn. 3.1]; verwende wahrscheinlichkeitsgewichtete Scores, wenn Log-Wahrscheinlichkeiten verfügbar sind @liu2023geval[Gl. 1]. Verblinde Modellidentitäten.
+ *Menschliche Validierungsstichprobe.* Ziehe zufällig 50 bis 100 oder mehr Items, lass sie von mindestens drei Menschen labeln @calderon2025alternative[Abschn. 6], berichte die Mensch-Mensch-Übereinstimmung als Obergrenze und vergleiche die Richter-Mensch-Übereinstimmung damit @bavaresco2025llms[Tab. 1, Tab. 3] @wang2024large[Tab. 4]. Nimm die Experten, auf deren Urteil es ankommt, denn Richter korrelierten besser mit Laien als mit Experten @bavaresco2025llms[Abb. 2]. Wo mehrere Antworten legitim sind, erhebe Mehrfachlabels statt erzwungener Einzelwahl @guerdan2025validating[Abstract].
+ *Übereinstimmungsstatistik.* Berichte Kappa (oder Alpha) und die Konfusionsmatrix, nicht nur Prozentübereinstimmung; für abgestufte Scores Spearman und die mittlere vorzeichenbehaftete Differenz (Bias), auf der Ebene, auf der deine Forschungsaussage liegt @thakur2025judging[Abschn. 4.1-4.2]. Gib Bootstrap-Konfidenzintervalle an.
+ *Bias-Audit.* Vertausche Reihenfolgen und berichte die Konfliktrate @wang2024large[Tab. 2]; regressiere Präferenzen auf Länge oder nutze Längenkontrolle @dubois2024length; vermeide Richter aus der Familie des bewerteten Modells oder teste auf Selbstpräferenz @panickssery2024llm @li2025crowdsourced[Abschn. 6.6]; schätze die Nachsichtigkeit $P_+$ @thakur2025judging[Abschn. 5.4]; prüfe menschliche und modellgenerierte Eingaben getrennt @bavaresco2025llms[Abb. 4]. Ergänze die CALM-Perturbationen, die für deine Aufgabe relevant sind @ye2025justice.
+ *Gegenmaßnahmen.* Balancierte Positionskalibrierung und menschliche Prüfung der Items mit hoher Entropie @wang2024large[Tab. 4]; Panels aus verschiedenen Familien @verga2024replacing[Tab. 1]; Stil- und Längenkontrolle bei paarweisen Rankings @li2025crowdsourced[Abschn. 6.5]. Entscheide die Ersetzbarkeit formal mit dem alt-test ($omega >= 0.5$ bei begründetem $epsilon$) @calderon2025alternative[Abschn. 3.3].
+ *Stresstest an harten Fällen.* Wenn Korrektheit zählt, teste den Richter an Items mit objektiv verifizierten Labels; starke geprompte Richter können auf solchen Paaren nahe am Zufall liegen @tan2025judgebench[Tab. 1].
+ *Unsicherheit quantifizieren und Schätzer korrigieren.* Bootstrap- oder Sandwich-Intervalle für Rankings @chiang2024chatbot[Abschn. 5], Separierbarkeit für Benchmarkvergleiche @li2025crowdsourced[Abschn. 3], PPI-artige Korrektur für Populationsschätzungen (Kapitel 6), mit einer erwarteten Labelersparnis von höchstens etwa Faktor 2, solange das Urteilen nicht deutlich leichter ist als die bewertete Aufgabe @dorner2025limits[Kor. 7, Abschn. 6].
+ *Bericht.* Richtermodell und exakte Version, Prompt, Dekodierungseinstellungen, Stichprobenziehung der Validierungsmenge, Übereinstimmungswerte mit Konfidenzintervallen, Ergebnisse des Bias-Audits, Kosten. Proprietäre Richter werfen Reproduzierbarkeitsfragen auf @bavaresco2025llms[Abstract].

#figure(
  table(
    columns: (1.25fr, 2.6fr),
    table.header([Validitätsart], [Bedrohung beim Einsatz eines LLM-Richters]),
    [Konstruktvalidität], [Kriterien nicht definiert oder driftend @shankar2024validates; Richter misst Stil oder Länge statt Qualität @dubois2024length @li2025crowdsourced[Abschn. 6.5]],
    [Interne Validität], [Positionseffekte @wang2024large; Selbstpräferenz @panickssery2024llm; Hinweise auf Modellidentität @gu2024survey[Abschn. 4.2]],
    [Statistische Schlussvalidität], [Prozentübereinstimmung statt chance-korrigierter Übereinstimmung @thakur2025judging; keine Intervalle für Rankings @chiang2024chatbot; geringe Separierbarkeit @li2025crowdsourced],
    [Externe Validität], [Richter auf einer Aufgabe validiert, auf einer anderen eingesetzt; menschliche Validierungsdaten, modellgenerierte Zieldaten; Laien-Validierung für Expertenaufgaben @bavaresco2025llms[Abb. 2, Abb. 4]],
    [Reliabilität], [stochastische Dekodierung und Reihenfolgeeffekte; MEC nutzt $k$ Stichproben zur Stabilisierung @wang2024large],
  ),
  caption: [Checkliste der Validitätsbedrohungen für Arbeiten mit LLM-Richtern, gegliedert nach den Validitätsarten aus Kapitel 1.],
) <k07-tab-threats>

#beispiel(titel: [Ein Validierungsbericht im Kleinformat])[
  Eine Masterarbeit bewertet die Treue von 2000 LLM-Zusammenfassungen sicherheitsrelevanter CVE-Beschreibungen. Eine Zufallsstichprobe von $n = 100$ wird von drei Studierenden des Security-Masters gelabelt; ihre paarweisen Kappa-Werte bilden die Obergrenze. Der Richter erreicht auf dieser Stichprobe die Konfusionsmatrix des Rechenbeispiels in @k07-meta: $p_o = 0.80$, $kappa approx 0.53$, $pi approx 0.52$, $hat(P)_+ = 0.75$. Der Bericht nennt also einen deutlich nachsichtigen Richter. Das rohe Richtermittel auf allen 2000 Items wäre deshalb nach oben verzerrt; die Arbeit schätzt den Treueanteil stattdessen mit PPI und gibt das Intervall an. Für binäre Labels ist die Pearson-Korrelation gleich dem Matthews-Korrelationskoeffizienten, hier $rho = (60 dot 20 - 15 dot 5) \/ sqrt(75 dot 65 dot 35 dot 25) approx 0.545$, also $rho^2 approx 0.297$ und nach @k07-eq-tau $tau <= 1.42$: Die 100 menschlichen Labels sind zusammen mit dem Richter höchstens so viel wert wie rund 142 ohne ihn. Konstruiertes Beispiel, mit python3 nachgerechnet.
]

#praxis[
  Das Notebook `notebooks/07_judge_validation.ipynb` setzt die Schritte 4 bis 9 an einem simulierten Richter um: Konfusionsmatrix, Kappa und Pi für einen nachsichtigen und einen verrauschten Richter, ein Positions-Audit mit exaktem Binomialtest, BPC und BPDE-Triage, Längenkontrolle mit logistischer Regression, den alt-test mit eigenhändig implementierter BY-Korrektur, Bootstrap-Intervalle und den Vergleich der $tau$-Schranke mit der empirischen Varianzreduktion. Ein optionaler Live-Modus schickt dieselben Analysen an einen lokalen Ollama-Server. Der Wechsel von simulierten zu echten Daten ändert also nichts an der Auswertung, nur an der Herkunft der Labels.
]

== Debatten und offene Fragen <k07-debatten>

=== Können LLM-Richter menschliche Bewertung ersetzen?

*Dafür* spricht: GPT-4 erreichte bei MT-Bench-Stimmen ohne Ties 85 % Übereinstimmung mit Experten gegenüber 81 % zwischen Menschen @zheng2023judging[Tab. 5]; GPT-4 gegen Crowd mit 75.6 % liegt im Bereich der Übereinstimmung von Crowd und Experten (72.8 % bis 83.1 %) @chiang2024chatbot[Tab. 3]; mit Kalibrierung und 20 % menschlicher Prüfung erreichte GPT-4 durchschnittliche menschliche Genauigkeit zu geringeren Kosten @wang2024large[Tab. 4]; Arena-Hard-Auto reproduziert menschliche Rankings mit Spearman 93.2 % für rund 20 US-Dollar @li2025crowdsourced[Abstract, Tab. 1]. *Dagegen* spricht: Über 20 Aufgaben liegt das beste Modell im Mittel bei Kappa 0.28 @bavaresco2025llms[Tab. 1]; vanilla GPT-4 hatte Kappa 0.24 auf dem Vicuna-Benchmark @wang2024large[Tab. 4]; GPT-4o liegt auf harten objektiven Paaren nahe am Zufall @tan2025judgebench[Tab. 1]; selbst in einem leichten QA-Setting liegt der beste Richter in Scotts $pi$ rund 0.08 unter der menschlichen Übereinstimmung @thakur2025judging[Abschn. 4.1]. Statistisch kann selbst hohe Übereinstimmung wenig sparen @dorner2025limits[Prop. 2, Prop. 4, Prop. 8], und der alt-test findet Ersetzbarkeit auf manchen Datensätzen gerechtfertigt, auf MT-Bench und SummEval im Zero-Shot-Setting nicht @calderon2025alternative[Abschn. 5].

Die Auflösung für die Lehre: Beide Seiten haben recht, über verschiedene Validitätsziele. Das Ranking von Chat-Modellen auf Systemebene ist vergleichsweise robust; Instanzlabels für Forschungsaussagen sind es nicht und müssen pro Aufgabe validiert werden @bavaresco2025llms @thakur2025judging. Das Positionspapier von Chehbouni et al. verschärft das zur Forderung, für LLM-Richter dieselbe Validitäts- und Reliabilitätsevidenz zu verlangen wie für jedes andere Messinstrument @chehbouni2025neither[Abstract].

=== Ist Selbstpräferenz ein echter Effekt?

Für einen kausalen Zusammenhang sprechen die Feinjustierungsexperimente mit Kontrollen für Länge, Lesbarkeit und andere Störgrößen @panickssery2024llm[Abschn. 3.4], die Platzierung einer GPT-4-Variante bei PoLL @verga2024replacing und die Familieneffekte in Arena-Hard @li2025crowdsourced[Abschn. 6.6]. Gegen eine vorschnelle Deutung spricht, dass "LLM-Text wird bevorzugt" bei unzuverlässigen menschlichen Labels auch echte Qualitätsunterschiede widerspiegeln kann @liu2023geval[Abschn. 4].

=== Trainieren oder prompten?

RL-trainierte Denk-Richter (J1, RM-R1) erreichen oder übertreffen auf *manchen* Richter-Benchmarks deutlich größere Modelle, aber nicht auf allen: RM-R1 liegt auf RewardBench hinter einem skalaren 70B-RM, J1-70B auf JudgeBench hinter DeepSeek-R1 @whitehouse2026j1[Tab. 2] @chen2026rmr1[Tab. 1]. Das Training auf synthetischen Präferenzen wirft für deine Domäne die Frage auf, wessen Präferenzen das Modell gelernt hat. Ein trainierter Richter verschiebt das Validierungsproblem, er löst es nicht.

=== Offene Probleme

Die Wissensbasis der LV nennt eine Reihe ungelöster Fragen, die sich als Themen für Abschlussarbeiten eignen: Validität auf Expertenaufgaben, weil Richter besser mit Laien übereinstimmen @bavaresco2025llms[Abb. 2]; das Bewerten modellgenerierter Texte, also des Hauptanwendungsfalls @bavaresco2025llms[Abb. 4]; die Frage, wann ein billiger Richter für Rankings "gut genug" ist, obwohl er Instanzen schlecht labelt @thakur2025judging[Abschn. 4.2]; Selbstpräferenz und Preference Leakage bei gemeinsamer Modellfamilie oder gemeinsamen Trainingsdaten @panickssery2024llm @li2025generation[Abschn. 7.1]; Kriteriendrift, die eine feste Rubrik zur Idealisierung macht @shankar2024validates[Abschn. 8.1]; Leaderboards als soziale Systeme mit strategischen Teilnehmern @singh2025leaderboard[Abschn. 6]; Richter, deren Aufgabe deutlich leichter ist als die bewertete, um die Faktor-zwei-Grenze zu überwinden @dorner2025limits[Abschn. 6]; valide Goldlabels unter Rating-Indeterminiertheit @guerdan2025validating; sowie Designs gemeinsamer Bewertung durch Mensch und LLM und Inference-Time-Scaling von Urteilen @li2025generation[Abschn. 7.2, Abschn. 7.4]. Sykophantie von Richtern, also das Nachgeben gegenüber geäußerten Nutzermeinungen, ist in der geprüften Wissensbasis nur über den Bandwagon-Effekt abgedeckt @ye2025justice[Tab. 1].

#k07-hs([Ist ein Reward-Modell eigentlich auch ein Richter?],
[Funktional ja: Beide bilden (Prompt, Antwort) auf ein Urteil ab, und RewardBench misst beide mit derselben paarweisen Genauigkeit @lambert2025rewardbench. Der Unterschied liegt in der Ausgabe und den Kosten. Ein klassisches Reward-Modell liefert einen Skalar ohne Begründung und ist billig; ein generativer Richter liefert eine Begründung, die du prüfen kannst, ist aber teurer. In RewardBench 2 rangieren generative Richter inzwischen unter den besten Reward-Modellen @malik2026rewardbench[Tab. 3], und RM-R1 verwischt die Grenze ganz, indem es ein Reward-Modell Rubriken schreiben lässt @chen2026rmr1. Für die Forschung ist die Begründung wertvoll, weil sie Fehleranalysen erlaubt; für die Validität entscheidet aber auch hier nur die Messung gegen eine Referenz.])

#k07-hs([Bringt Chain-of-Thought im Richterprompt nicht immer etwas?],
[Nein. Bei Mathematikfragen senkte CoT die Fehlbewertungen von GPT-4 von 14/20 auf 6/20, eine verifizierte Referenz aber auf 3/20 @zheng2023judging[Tab. 4]. Beim alt-test schadete Chain-of-Thought in vielen Fällen, Few-Shot-Beispiele halfen dagegen @calderon2025alternative[Abschn. 5, Tab. 3]. CALM führt CoT sogar als eigene Verzerrungsquelle, weil sich Urteile mit CoT-Prompting ändern @ye2025justice[Tab. 1]. CoT ist also eine Designvariable, die du wie jede andere auf deiner Validierungsstichprobe prüfst.])

== Für die Lehre <k07-lehre>

Dieses Kapitel deckt Foliensatz 07 der LV ab, der im Umfang über dem üblichen Rahmen liegt. In 90 Minuten trägt die folgende Gliederung: 10 Minuten Motivation mit dem Messinstrument-Bild (@k07-fig-instrument) und der JudgeBench-Pointe (50.86 %); 15 Minuten Paradigmen mit G-Eval und Checklisten; 20 Minuten Meta-Evaluation, wobei das Kappa-Paradoxon (@k07-fig-paradox) an der Tafel gerechnet wird; 15 Minuten Verzerrungen mit einer Live-Demo; 10 Minuten Gegenmaßnahmen; 15 Minuten statistische Grenzen und Arenen; 5 Minuten Validierungsprotokoll als Ausblick auf die Übung. Die Herleitungen von Bradley-Terry und der $tau$-Schranke gehören in eine zweite Einheit oder in das Selbststudium mit diesem Kapitel.

*Live-Demos, die funktionieren.* Zeige ein MT-Bench-Paar, dessen Urteil beim Vertauschen kippt, und dann die 75.0 % Erstpositionspräferenz von Claude-v1 @zheng2023judging[Tab. 2]. Polstere eine Antwort mit einer repetitiven Liste auf und zeige die Score-Änderung, dann die 91.3 % gegenüber 8.7 % Fehlerrate @zheng2023judging[Tab. 3]. Zeige dieselbe Zusammenfassung mit den Labels "von dir geschrieben" und "von einem anderen Modell geschrieben" @panickssery2024llm[Tab. 6]. Und zeige Separierbarkeit gegen Spearman mit dem Bild aus @k07-fig-separierbarkeit @li2025crowdsourced[Tab. 1].

*Typische Missverständnisse der Studierenden.* Erstens: "85 % Übereinstimmung heißt, der Richter ist zu 85 % richtig." Hier hilft die Unterscheidung von Prozentübereinstimmung, Kappa und Korrektheit sowie der Hinweis auf die Ties. Zweitens: "Wenn die Systemkorrelation hoch ist, kann ich den Richter für Einzelurteile verwenden." Der "contains"-Befund von Thakur et al. ist das Gegenbeispiel @thakur2025judging[Abschn. 4.2]. Drittens: "Ein größeres Modell ist ein besserer Richter." JUDGE-BENCH zeigt offene Modelle, die auf einzelnen Datensätzen gewinnen @bavaresco2025llms[Tab. 1], und PoLL kleine Panels, die einen großen Richter schlagen @verga2024replacing[Tab. 1]. Viertens: "Mit genug Richterlabels brauche ich keine menschlichen mehr." Die Dorner-Schranke und das PPI-Argument zeigen, warum ohne menschliche Stichprobe die Verzerrung unbekannt bleibt @dorner2025limits. Fünftens: "Die Faktor-zwei-Grenze gilt immer." Sie gilt nur unter ihren Annahmen @dorner2025limits[Kor. 7, Abschn. 6].

*Übungen.* Die Wissensbasis schlägt zwölf Übungen vor, von denen sich für 90 Minuten Übung drei besonders eignen: ein Positions-Audit mit Konsistenz, Konfliktrate und BPC auf 100 MT-Bench-Paaren (90 Minuten) @zheng2023judging @wang2024large; Kappa gegen Prozentübereinstimmung mit drei Richtern auf TriviaQA-Antworten (60 Minuten) @thakur2025judging; und der alt-test mit Labels von drei bis vier Studierenden auf 60 Items (60 Minuten) @calderon2025alternative. Als Projektaufgabe wenden die Studierenden das Zehn-Schritte-Protokoll auf eine Bewertung im eigenen Projekt an und überarbeiten die Rubrik einmal nach 20 bewerteten Ausgaben @shankar2024validates.

*Diskussionsfragen*, die zuverlässig gute Diskussionen auslösen: Wenn Menschen untereinander mit $alpha = 0.07$ übereinstimmen, was bedeutet dann "den Richter gegen Menschen validieren" @liu2023geval[Abschn. 4]? Menschen fallen auf Emojis herein, LLMs auf erfundene Zitate: Wessen Verzerrung ist für deine Forschungsfrage schlimmer @chen2024humans[Tab. 1]? Wie sähe eine faire Leaderboard-Politik aus, und wer setzt sie durch @singh2025leaderboard[Abschn. 6] @lmarena2025response?

#vertiefung[
  Als Einstieg eignen sich die beiden Übersichten von Gu et al. @gu2024survey (Definition, Verzerrungstaxonomie, eigene Experimente; Preprint) und Li et al. @li2025generation (Taxonomie nach "was", "wie" und "wie benchmarken"). Für die Meta-Evaluation sind Thakur et al. @thakur2025judging (Prozentübereinstimmung gegen Pi, Instanz- gegen Systemebene) und Bavaresco et al. @bavaresco2025llms (Validierung pro Aufgabe) die wichtigsten Lektüren; Tan et al. @tan2025judgebench liefert das Gegenstück auf Korrektheitsebene. Für die Statistik lohnt sich Dorner et al. @dorner2025limits im Original, insbesondere Abschnitt 6 mit den eigenen Einschränkungen der Autoren, zusammen mit Calderon et al. @calderon2025alternative. Die Arena-Debatte liest du am besten als Trio: Chiang et al. @chiang2024chatbot, Singh et al. @singh2025leaderboard und die Antwort von LMArena @lmarena2025response. Messtheoretisch rahmt Chehbouni et al. @chehbouni2025neither das ganze Kapitel, im Lehrbuch @haindl2027research findest du die Einbettung in Konstruktvalidität und die Treuemetriken.
]

#selbsttest(
  [Ein Richter und ein Mensch beurteilen 200 Antworten: $"TP" = 130$, $"TN" = 30$, $"FP" = 30$, $"FN" = 10$. Berechne $p_o$, Cohens $kappa$, Scotts $pi$ und $hat(P)_+$ und interpretiere das Ergebnis.],
  [Erkläre an einem Beispiel, warum ein Richter eine höhere Prozentübereinstimmung, aber ein niedrigeres Kappa als ein anderer Richter haben kann.],
  [Ein Richter gibt für die Stufen 1 bis 5 die Wahrscheinlichkeiten $(0.10, 0.10, 0.30, 0.30, 0.20)$ aus. Berechne den G-Eval-Score und begründe, warum diese Gewichtung bei Korrelationsanalysen hilft.],
  [Warum ist die Aussage "GPT-4 stimmt zu über 80 % mit Menschen überein" ohne Zusatz irreführend? Nenne die beiden Setups von Zheng et al. und ihre Werte.],
  [In einem Positions-Audit gewinnt die erste Position 70 von 120 entschiedenen Urteilen. Formuliere $H_0$ und beschreibe, wie du testest. Warum ist ein Test auf Paarebene vorzuziehen?],
  [Erkläre, warum CALM die Robustheitsrate RR nur relativ zur Konsistenzrate CR interpretiert.],
  [Leite her, warum Balanced Position Calibration einen additiven Positionsbonus $delta$ aus der Score-Differenz zweier Antworten entfernt. Unter welcher Bedingung gelingt das nur teilweise?],
  [Drei unabhängige Richter sind jeweils mit Wahrscheinlichkeit $q = 0.7$ korrekt. Wie genau ist der Mehrheitsentscheid? Was passiert bei $q = 0.4$, und warum ist Unabhängigkeit in der Praxis fraglich?],
  [Leite $tau = 1 \/ (1 - rho^2)$ für den abgestimmten PPI-Schätzer im Grenzfall $N -> infinity$ her.],
  [Formuliere die Faktor-zwei-Aussage von Dorner et al. mit allen Annahmen. Gib ein Szenario an, in dem sie nicht gilt, und berechne $tau$ für $b = 0.5$, $p = q = 0.95$.],
  [Leite das Bradley-Terry-Modell aus einem Zufallsnutzenmodell her und zeige, dass im Maximum-Likelihood-Optimum beobachtete und erwartete Siege übereinstimmen.],
  [Ein Anbieter testet 5 gleich starke Varianten mit Messstreuung $sigma = 20$ Punkte und veröffentlicht die beste. Wie groß ist die erwartete Inflation? Wie ordnest du die Debatte zwischen Singh et al. und LMArena ein?],
)

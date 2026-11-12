#import "../lib.typ": *

// Beweisskizzen nicht über Seitenumbrüche trennen (sonst bleibt die Überschrift allein am Seitenende)
#let k08-beweis-lib = beweis
#let beweis(body) = block(breakable: false, k08-beweis-lib(body))

// lokale Helfer für die Abbildungen dieses Kapitels
#let k08-t(body, size: 7pt, fill: c-dark, weight: "regular") = text(font: "Inter", size: size, fill: fill, weight: weight, features: (calt: 0), body)
#let k08-fmt(v) = {
  let s = str(v)
  s
}
// Achsenkreuz mit Gitter; body ist eine Funktion (X, Y) => Zeichenelemente
#let k08-plot(w: 8, h: 4.2, xmin: 0, xmax: 1, ymin: 0, ymax: 1, xticks: (), yticks: (), xlabels: none, ylabels: none, xlabel: [], ylabel: [], body) = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let X(x) = (x - xmin) / (xmax - xmin) * w
  let Y(y) = (y - ymin) / (ymax - ymin) * h
  for (i, t) in yticks.enumerate() {
    line((0, Y(t)), (w, Y(t)), stroke: 0.3pt + luma(222))
    content((-0.12, Y(t)), anchor: "east", k08-t(if ylabels == none { k08-fmt(t) } else { ylabels.at(i) }))
  }
  for (i, t) in xticks.enumerate() {
    line((X(t), 0), (X(t), -0.08), stroke: 0.5pt + c-dark)
    content((X(t), -0.16), anchor: "north", k08-t(if xlabels == none { k08-fmt(t) } else { xlabels.at(i) }))
  }
  line((0, 0), (w, 0), stroke: 0.6pt + c-dark)
  line((0, 0), (0, h), stroke: 0.6pt + c-dark)
  content((w / 2, -0.62), anchor: "north", k08-t(xlabel))
  content((-0.95, h / 2), angle: 90deg, k08-t(ylabel))
  body(X, Y)
})

= Bias-Metriken für LLM-Pipelines <k08>

Sobald ein Sprachmodell in deiner Forschung etwas entscheidet, etikettiert, sortiert oder bewertet, wird es zu einem Messinstrument. Die vorangegangenen Kapitel haben gezeigt, wie man ein solches Instrument auf Übereinstimmung mit menschlichen Codierenden prüft (Kapitel 5), wie man aus seinen fehlerbehafteten Ausgaben trotzdem valide Schlüsse zieht (Kapitel 6) und wie man es als Gutachter einsetzt (Kapitel 7). Dieses Kapitel ergänzt eine Fehlerquelle, die in all diesen Fällen auftritt und besonders tückisch ist: Fehler, die nicht zufällig über die Daten streuen, sondern systematisch mit der Zugehörigkeit zu sozialen Gruppen zusammenhängen. Ein LLM-Annotator, der Beiträge in afroamerikanischem Englisch häufiger als toxisch markiert, ein LLM-Screener, der bei identischem Lebenslauf je nach Vorname anders entscheidet, oder ein LLM-Judge, der eine Antwort schlechter bewertet, sobald sich ihre Verfasserin als Geflüchtete zu erkennen gibt, erzeugen keinen gewöhnlichen Messfehler, sondern einen *differenziellen* Messfehler. Für die Forschung ist das zuerst ein Validitätsproblem und erst danach ein ethisches: Jeder Gruppenvergleich, der auf solchen Ausgaben beruht, ist verzerrt.

Die Literatur zu "Bias in NLP" ist groß und unübersichtlich. Es gibt Dutzende Metriken, die auf ganz unterschiedlichen Datenstrukturen rechnen (Einbettungsvektoren, Token-Wahrscheinlichkeiten, generierte Texte, Entscheidungen), Benchmarks, deren Testfälle sich bei genauerem Hinsehen oft als unbrauchbar herausstellen @blodgett2021stereotyping, und eine anhaltende Debatte darüber, ob sich die gemessenen Werte überhaupt auf das Verhalten in echten Anwendungen übertragen lassen @goldfarbtarrant2021intrinsic @lum2025bias. Hinzu kommt eine Beobachtung der letzten beiden Jahre, die viele ältere Befunde relativiert: Modelle, die durch Instruction-Tuning und Feedback-Training "ausgerichtet" (_aligned_) wurden, antworten auf direkte Fragen nach Gruppen oft vorbildlich neutral und zeigen dennoch stereotype Assoziationen und diskriminierende Entscheidungen, sobald die Gruppenzugehörigkeit nur indirekt signalisiert wird @bai2025explicitly @hofmann2024ai.

Dieses Kapitel ordnet das Feld. Es beginnt mit den Begriffen und einer Taxonomie der Metriken, geht dann Familie für Familie durch die wichtigsten Maße mit ihren Formeln, Herleitungen und Rechenbeispielen und landet schließlich dort, wo es für deine eigene Arbeit am meisten zählt: bei Gruppenfairness-Metriken für Entscheidungen in Pipelines, bei kontrafaktischen Audits mit sauberer Statistik und bei der Frage, wann eine Bias-Messung überhaupt misst, was sie zu messen vorgibt. Den Abschluss bilden die LLM-Komponenten deiner eigenen Pipeline (Annotatoren und Judges) sowie die regulatorischen Anforderungen des EU AI Act in der Fassung des Digital Omnibus. Begleitend gibt es den Foliensatz 08 der LV und das Notebook `notebooks/08_bias_metrics.ipynb`, das alle Rechenbeispiele dieses Kapitels auf synthetischen Daten nachvollzieht.

#lernziele[
  repräsentationale und allokative Schäden unterscheiden und eine gegebene Metrik einer der vier Familien (Einbettung, Wahrscheinlichkeit, generierter Text, Entscheidung) sowie der Achse intrinsisch/extrinsisch zuordnen,
][
  die WEAT-Effektstärke herleiten, ihre Schranken beweisen und einen exakten Permutationstest durchführen,
][
  CrowS-Pairs-Score, StereoSet-Werte (SS, LMS, ICAT) und die BBQ-Bias-Scores aus Rohausgaben berechnen und ihre Idealwerte begründen,
][
  Demographic Parity, Disparate Impact, Equal Opportunity und Equalized Odds für einen LLM-Screener berechnen, mit Unsicherheit versehen und die Unvereinbarkeitsresultate beweisen,
][
  ein kontrafaktisches Audit (Namen, Dialekt, Identitätsbegriffe) mit Kontrollbedingung entwerfen und mit McNemar-Test, gepaartem $t$-Test und Vorzeichen-Permutationstest auswerten,
][
  die Konstruktvalidität einer Bias-Messung mit dem Messmodell-Ansatz prüfen und erklären, warum intrinsische Metriken kein Ersatz für die Messung am Entscheidungspunkt sind,
][
  LLM-Annotatoren und -Judges als Bias-Quellen in einer Forschungspipeline testen und die Pflichten aus Art. 10 EU AI Act samt Fristen einordnen.
]

== Bias als Messproblem der Pipeline <k08-begriffe>

=== Was "Bias" in diesem Kapitel bedeutet

Das Wort "Bias" ist in der Statistik und im maschinellen Lernen überladen. Ein Schätzer ist verzerrt, wenn sein Erwartungswert vom wahren Parameter abweicht; ein neuronales Netz hat Bias-Terme; Kapitel 7 hat Positions- und Längen-Bias von LLM-Judges behandelt. Dieses Kapitel meint durchgehend *sozialen Bias* im Sinn der Übersichtsarbeit von Gallegos et al., die heute als Standardreferenz des Felds gilt @gallegos2024bias.

#definition(titel: [Sozialer Bias nach Gallegos et al.])[
  Sozialer Bias ist eine ungleiche Behandlung oder ein ungleiches Ergebnis zwischen sozialen Gruppen (_disparate treatment or outcomes between social groups_), das aus historischen und strukturellen Machtasymmetrien herrührt @gallegos2024bias. In NLP-Systemen äußert er sich in zwei Arten von Schäden:
  - *Repräsentationale Schäden* (_representational harms_): Stereotypisierung, abwertende Sprache, Unsichtbarmachen einer Gruppe (_erasure_), ausschließende Normen.
  - *Allokative Schäden* (_allocational harms_): direkte und indirekte Diskriminierung bei der Verteilung von Ressourcen und Chancen, etwa Einladungen zu Bewerbungsgesprächen oder Kreditentscheidungen.
]

Die Unterscheidung ist nicht akademisch, denn sie bestimmt, welche Metrik überhaupt passt. Ein allokativer Schaden entsteht dort, wo eine Entscheidung fällt; ihn misst du mit Raten auf Entscheidungen (@k08-gruppen). Ein repräsentationaler Schaden entsteht im Text selbst, also in dem, was ein Modell über Gruppen sagt, und verlangt Metriken auf Wahrscheinlichkeiten oder generierten Texten (@k08-wahrscheinlichkeit, @k08-generiert).

Wie unscharf der Begriff in der Praxis verwendet wird, hat die einflussreiche Analyse "Language (Technology) is Power" von Blodgett et al. gezeigt @blodgett2020language.

#studie(titel: [Blodgett et al. 2020])[
  *Design:* Kritische Durchsicht von 146 NLP-Arbeiten, die "Bias" in geschriebenem Text untersuchen. *Befund:* Die Motivationen sind oft vage, widersprüchlich und ohne normative Begründung; Techniken und Motivationen passen häufig nicht zusammen. 21 % der Arbeiten nennen allokative Schäden als Motivation, aber nur vier Arbeiten schlagen Techniken für allokative Schäden vor. *Empfehlungen:* Die Arbeit in Literatur außerhalb der NLP zu Sprache und sozialen Hierarchien verankern; ausdrücklich sagen, warum, wie und für wen ein Verhalten schädlich ist; die Lebenserfahrung betroffener Gemeinschaften einbeziehen und Machtverhältnisse hinterfragen. *Grenze:* Konzeptuell, schlägt selbst keine Metrik vor @blodgett2020language.
]

Für eine Forschungsarbeit folgt daraus eine einfache, aber oft vernachlässigte Regel: Bevor du eine Bias-Zahl berichtest, schreibst du in einem Satz hin, welcher Schaden für wen gemeint ist und warum die gewählte Messung diesen Schaden erfasst. @k08-validitaet macht daraus ein vollständiges Prüfschema.

=== Fairness-Desiderata

Wenn Bias eine Abweichung ist, braucht man einen Sollzustand. Gallegos et al. formalisieren fünf Desiderata für ein Modell $M(X; theta)$ mit Parametern $theta$, einer Menge $A$ geschützter Attributwörter (etwa Pronomen oder Gruppenbezeichnungen), einer Menge $W$ neutraler Wörter und sozialen Gruppen $G_i$ @gallegos2024bias.

#definition(titel: [Fairness-Desiderata für LLMs])[
  + *Fairness durch Unkenntnis* (_fairness through unawareness_): $M(X; theta) = M(X_(without A); theta)$; die Ausgabe ändert sich nicht, wenn man die geschützten Attributwörter entfernt.
  + *Invarianz* (_invariance_): Für zwei Eingaben $X_i, X_j$, die sich nur in der genannten Gruppe unterscheiden, sind $M(X_i; theta)$ und $M(X_j; theta)$ unter einer Invarianzmetrik $psi$ identisch.
  + *Gleiche Gruppenassoziationen*: $forall w in W: P(w | A_i) = P(w | A_j)$.
  + *Gleiche neutrale Assoziationen*: $forall a in A: P(a_i | W) = P(a_j | W)$.
  + *Replizierte Verteilungen*: $forall w in W: P_(hat(Y))(w | G) = P_D (w | G)$ für eine Referenzverteilung $D$.
]

Zwei Anmerkungen sind wichtig. Erstens formuliert die Übersichtsarbeit die Invarianz in Worten, ohne Toleranz; in der Praxis erlaubt man eine Abweichung $psi(M(X_i), M(X_j)) <= delta$, das ist aber eine pragmatische Lockerung und nicht Teil der Definition @gallegos2024bias. Zweitens ist die Invarianz die formale Grundlage aller kontrafaktischen Tauschtests, die du in @k08-audits kennenlernst: Du tauschst den Namen, den Dialekt oder das Pronomen und prüfst, ob sich die Ausgabe ändert.

Die Desiderata widersprechen sich teilweise. "Replizierte Verteilungen" verlangt, dass ein Modell die Verteilung einer Referenz wiedergibt, also auch reale Unterschiede zwischen Gruppen. "Gleiche Gruppenassoziationen" verlangt, dass es keine Unterschiede gibt. Welches Desideratum gilt, ist keine statistische, sondern eine normative Entscheidung, und genau diese Spannung wird in @k08-debatten unter dem Stichwort Differenzbewusstsein (_difference awareness_) wieder auftauchen @wang2025fairness.

=== Intrinsisch und extrinsisch, explizit und implizit

Zwei weitere Begriffspaare strukturieren den Rest des Kapitels.

#definition(titel: [Intrinsische und extrinsische Bias-Metriken])[
  *Intrinsische* Metriken messen Bias in den Repräsentationen oder Token-Wahrscheinlichkeiten eines Modells (Einbettungen, maskierte Token-Wahrscheinlichkeiten). *Extrinsische* Metriken messen Bias in den Ausgaben einer Aufgabe: Klassifikation, Frage-Antwort, Generierung, Ranking @gallegos2024bias @goldfarbtarrant2021intrinsic.
]

#definition(titel: [Expliziter und impliziter, offener und verdeckter Bias])[
  *Expliziter* Bias zeigt sich, wenn man ein Modell direkt nach Gruppen fragt; *impliziter* Bias zeigt sich in Assoziationen und relativen Entscheidungen, ohne dass die Gruppe Thema der Frage ist @bai2025explicitly. Analog unterscheiden Hofmann et al. *offene* Stereotype (die Gruppe wird genannt) von *verdeckten* Stereotypen (die Gruppe wird nur über ein Merkmal wie den Dialekt signalisiert) @hofmann2024ai.
]

Warum das wichtig ist, zeigt ein Befund, der sich durch das ganze Kapitel ziehen wird: Über Hunderte trainierte Modelle, Aufgaben und Sprachen hinweg gibt es "keine verlässliche Korrelation" zwischen intrinsischen und extrinsischen Metriken @goldfarbtarrant2021intrinsic. Ein Modell mit unauffälligen Einbettungen kann in der Anwendung stark diskriminieren und umgekehrt. Ähnlich steht es mit explizitem und implizitem Bias: Acht wertausgerichtete Modelle (GPT-3.5 und GPT-4, Claude 3 Sonnet und Opus, Llama-2-Chat in drei Größen, Alpaca-7B) zeigten bei 19 von 21 untersuchten Stereotypen stereotypkonforme Wortassoziationen, obwohl sie auf direkte Fragen unauffällig antworteten @bai2025explicitly.

=== Wo Bias in eine LLM-Pipeline gelangt

Für eine Forscherin, die LLMs als Instrument nutzt, ist die interessante Frage nicht "Ist Modell X biased?", sondern "An welcher Stelle meiner Pipeline kann gruppenkorrelierter Fehler entstehen, und wie messe ich ihn dort?". @k08-fig-pipeline zeigt die typischen Einfallstore.

#figure(
  diagram(spacing: (3mm, 9mm), edge-stroke: 0.8pt,
    fknoten((0, 0), [Rohdaten \ (Texte, CVs)], col: c-grey, w: 29mm),
    edge("-|>"),
    fknoten((1, 0), [LLM-Annotator \ (Labels)], col: c-blue, filled: true, w: 29mm),
    edge("-|>"),
    fknoten((2, 0), [Retriever / Ranker \ (Top-$k$)], col: c-blue, filled: true, w: 29mm),
    edge("-|>"),
    fknoten((3, 0), [LLM-Screener \ (Entscheidung)], col: c-blue, filled: true, w: 29mm),
    edge("-|>"),
    fknoten((4, 0), [LLM-Judge \ (Bewertung)], col: c-blue, filled: true, w: 29mm),
    fknoten((1, 1), [Invarianz bei Tausch, \ Fehlerraten \ je Gruppe], col: c-accent, w: 29mm),
    fknoten((2, 1), [Anteil im Top-$k$, \ Ausschlussrate], col: c-accent, w: 29mm),
    fknoten((3, 1), [Selektionsraten, \ TPR und FPR], col: c-accent, w: 29mm),
    fknoten((4, 1), [Robustheitsrate \ vs. Konsistenzrate], col: c-accent, w: 29mm),
    edge((1, 0), (1, 1), "--", stroke: 0.6pt + c-accent),
    edge((2, 0), (2, 1), "--", stroke: 0.6pt + c-accent),
    edge((3, 0), (3, 1), "--", stroke: 0.6pt + c-accent),
    edge((4, 0), (4, 1), "--", stroke: 0.6pt + c-accent),
  ),
  caption: [Einfallstore für sozialen Bias in einer LLM-Forschungspipeline (blau) und die jeweils passende Messung (orange). Jede Stufe kann Bias erzeugen oder verstärken; gemessen wird dort, wo die Entscheidung fällt.],
) <k08-fig-pipeline>

Dass sich Bias über Stufen fortpflanzt, ist empirisch belegt. In einer Studie zu LLM-gestütztem Recruiting verletzten die Zusammenfassungen von Lebensläufen bei fünf von sechs generativen Modellen die Invarianz unter einem Tausch der ethnischen Zuordnung des Namens, und in der nachgelagerten Suche fielen im Mittel 45.75 % der Top-5-Lebensläufe nach einer kleinen Änderung aus den Top 5 heraus @seshadri2025small. Diese Studie wird in @k08-audits ausführlich besprochen, weil sie auch zeigt, warum Kontrollbedingungen unverzichtbar sind.

#merke[
  Bias in einer LLM-Pipeline ist gruppenkorrelierter Messfehler. Er bedroht die Validität jedes Gruppenvergleichs, der auf den Ausgaben aufbaut, und gehört deshalb in den Methodenteil, nicht nur in den Ethikabschnitt.
]

== Eine Taxonomie der Bias-Metriken <k08-taxonomie>

Gallegos et al. ordnen Bias-Metriken nach der Datenstruktur, auf der sie rechnen: Einbettungen, Token-Wahrscheinlichkeiten oder generierter Text @gallegos2024bias. Für Pipelines kommt eine vierte Familie hinzu, die immer dann greift, wenn eine LLM-Ausgabe in eine Entscheidung übersetzt wird (annehmen oder ablehnen, ein Label vergeben, in die Top-$k$ aufnehmen): Gruppenfairness-Metriken auf Entscheidungen @barocas2023fairness @hardt2016equality. @k08-fig-taxonomie fasst die vier Familien mit ihren wichtigsten Vertretern zusammen.

#figure(
  diagram(spacing: (3mm, 7mm), edge-stroke: 0.7pt,
    fknoten((1.5, 0), [Bias-Metriken für LLMs], col: c-dark, filled: true, w: 40mm),
    fknoten((0, 1), [*Einbettung* \ WEAT, SEAT], col: c-blue, w: 36mm),
    fknoten((1, 1), [*Wahrscheinlichkeit* \ CrowS-Pairs, LPBS, \ StereoSet], col: c-violet, w: 36mm),
    fknoten((2, 1), [*Generierter Text* \ BBQ, BOLD, HONEST, \ Score-Parität], col: c-teal, w: 36mm),
    fknoten((3, 1), [*Entscheidung* \ DP, DIR, Equalized Odds, \ Kalibrierung], col: c-accent, w: 36mm),
    edge((1.5, 0), (0, 1), "-|>"), edge((1.5, 0), (1, 1), "-|>"),
    edge((1.5, 0), (2, 1), "-|>"), edge((1.5, 0), (3, 1), "-|>"),
    fknoten((0.5, 2), [intrinsisch: Repräsentationen, Token-Wahrscheinlichkeiten], col: c-grey, w: 58mm),
    fknoten((2.5, 2), [extrinsisch: Ausgaben einer Aufgabe], col: c-grey, w: 58mm),
    edge((0, 1), (0.5, 2), "--", stroke: 0.5pt + c-grey), edge((1, 1), (0.5, 2), "--", stroke: 0.5pt + c-grey),
    edge((2, 1), (2.5, 2), "--", stroke: 0.5pt + c-grey), edge((3, 1), (2.5, 2), "--", stroke: 0.5pt + c-grey),
  ),
  caption: [Taxonomie nach Gallegos et al. (drei Familien nach Datenstruktur) erweitert um Gruppenfairness auf Entscheidungen. Die unterste Ebene zeigt die Zuordnung zu intrinsisch und extrinsisch.],
) <k08-fig-taxonomie>

Die Taxonomie ist mehr als eine Ordnungshilfe. Sie sagt dir, welche Zugriffsrechte du brauchst: Einbettungsmetriken setzen Zugriff auf Vektoren voraus, Wahrscheinlichkeitsmetriken auf Logits, was bei vielen kommerziellen APIs nicht oder nur eingeschränkt möglich ist. So mussten Hofmann et al. GPT-4 aus Analysen ausschließen, die Wahrscheinlichkeiten für alle Berufsbezeichnungen erforderten @hofmann2024ai. Metriken auf generiertem Text und auf Entscheidungen funktionieren dagegen mit reinem Black-Box-Zugriff. Gallegos et al. ziehen aus der Literatur außerdem eine klare Konsequenz: Einbettungs- und wahrscheinlichkeitsbasierte Metriken zeigen nur schwache oder inkonsistente Beziehungen zu nachgelagertem Bias und sollten nie das einzige Maß sein @gallegos2024bias.

#figure(
  table(columns: (auto, 1fr, 1fr, auto),
    [Familie], [Typische Frage], [Zugriff], [Schaden],
    [Einbettung], [Liegen Gruppenbegriffe näher an bestimmten Attributen?], [Vektoren], [repräsentational],
    [Wahrscheinlichkeit], [Hält das Modell den stereotypen Satz für wahrscheinlicher?], [Logits], [repräsentational],
    [Generierter Text], [Wird über Gruppe A negativer, toxischer, stereotyper geschrieben?], [Black Box (+ Klassifikator)], [repräsentational],
    [Entscheidung], [Werden Gruppen unterschiedlich oft ausgewählt oder falsch eingestuft?], [Black Box (+ Goldlabels)], [allokativ],
  ),
  caption: [Die vier Metrikfamilien im Überblick.],
) <k08-tab-familien>

#hoersaal([Wenn intrinsische Metriken so schlecht vorhersagen, warum lernen wir sie überhaupt?],
[Aus drei Gründen. Erstens sind sie die historische Grundlage, auf die sich spätere Arbeiten beziehen; ohne WEAT versteht man weder SEAT noch die Kritik daran. Zweitens messen sie einen eigenen, legitimen Gegenstand, nämlich repräsentationale Assoziationen in einem Modell, die etwa für die Analyse von Trainingsdaten interessant sein können. Drittens sind sie didaktisch wertvoll, weil sich an ihnen Effektstärken, Permutationstests und Wortlisten-Abhängigkeit sauber zeigen lassen. Was du nicht tun solltest: aus einem niedrigen WEAT-Wert schließen, dass dein Screener fair entscheidet @goldfarbtarrant2021intrinsic @delobelle2022measuring.])

== Einbettungsmetriken: WEAT und SEAT <k08-einbettung>

=== Intuition: der Implicit Association Test für Vektoren

Der Implicit Association Test (IAT) der Sozialpsychologie misst Reaktionszeiten: Menschen sortieren Begriffe schneller, wenn die Kombination ihren Assoziationen entspricht (etwa männliche Namen mit Karrierebegriffen), als wenn sie ihnen widerspricht. Caliskan, Bryson und Narayanan haben 2017 die Idee auf Wortvektoren übertragen @caliskan2017semantics. An die Stelle der Reaktionszeit tritt die Kosinus-Ähnlichkeit: Ein Name ist mit "Karriere" assoziiert, wenn sein Vektor im Mittel näher an den Karriere-Wörtern liegt als an den Familien-Wörtern. Der *Word Embedding Association Test* (WEAT) macht daraus einen Hypothesentest mit Effektstärke.

=== Formale Definition

Gegeben sind zwei gleich große Mengen von Zielwörtern $X$ und $Y$ (etwa männliche und weibliche Vornamen) und zwei Mengen von Attributwörtern $A$ und $B$ (etwa Karriere- und Familienbegriffe). $arrow(w)$ bezeichnet den Einbettungsvektor des Worts $w$, $cos(arrow(a), arrow(b))$ den Kosinus des Winkels zwischen zwei Vektoren.

#definition(titel: [WEAT nach Caliskan et al.])[
  Die *Assoziation* eines einzelnen Worts $w$ mit $A$ gegenüber $B$ ist
  $ s(w, A, B) = op("mean")_(a in A) cos(arrow(w), arrow(a)) - op("mean")_(b in B) cos(arrow(w), arrow(b)). $ <k08-eq-weat-s>
  Die *Teststatistik* ist
  $ s(X, Y, A, B) = sum_(x in X) s(x, A, B) - sum_(y in Y) s(y, A, B), $ <k08-eq-weat-stat>
  die *Effektstärke*
  $ d = (op("mean")_(x in X) s(x, A, B) - op("mean")_(y in Y) s(y, A, B)) / (op("std-dev")_(w in X union Y) s(w, A, B)). $ <k08-eq-weat-d>
  Signifikanz wird mit einem einseitigen Permutationstest über alle gleich großen Partitionen $(X_i, Y_i)$ von $X union Y$ bestimmt: $p = Pr_i [s(X_i, Y_i, A, B) > s(X, Y, A, B)]$ @caliskan2017semantics.
]

Zwei Details der Originalarbeit sind für eine saubere Replikation wichtig. Die Formel des $p$-Werts verwendet ein striktes "$>$", der Begleittext spricht aber von "oder größer"; die zweite Lesart zählt die beobachtete Partition mit und ist die übliche Konvention für exakte Permutationstests. Und die Arbeit sagt nicht, ob im Nenner von @k08-eq-weat-d die Stichproben- oder die Populationsstandardabweichung gemeint ist. Implementierungen unterscheiden sich darin, also musst du berichten, welche du verwendest @caliskan2017semantics.

=== Herleitung: Was die Effektstärke eigentlich misst

Auf den ersten Blick sieht @k08-eq-weat-d aus wie Cohens $d$: Mittelwertdifferenz durch Standardabweichung. Es gibt aber einen wichtigen Unterschied. Cohens $d$ teilt durch die *gepoolte Standardabweichung innerhalb* der Gruppen, WEAT teilt durch die Standardabweichung *über die vereinigte Menge* $X union Y$. Diese enthält die Mittelwertdifferenz selbst. Das hat Folgen, die wir jetzt herleiten.

Sei $n = |X| = |Y|$, $N = 2n$, und schreibe kurz $s_w = s(w, A, B)$. Seien $macron(s)_X$ und $macron(s)_Y$ die Gruppenmittel, $Delta = macron(s)_X - macron(s)_Y$ und $macron(s) = (macron(s)_X + macron(s)_Y) \/ 2$ das Gesamtmittel. Für die Populationsvarianz über $X union Y$ gilt die Streuungszerlegung
$ sigma^2_"tot" = 1/N sum_(w in X union Y) (s_w - macron(s))^2 = underbrace(1/N sum_(w) (s_w - macron(s)_(g(w)))^2, sigma^2_"in") + underbrace(1/2 (macron(s)_X - macron(s))^2 + 1/2 (macron(s)_Y - macron(s))^2, sigma^2_"zw"), $ <k08-eq-zerlegung>
wobei $g(w)$ die Gruppe von $w$ bezeichnet. Der Mischterm verschwindet, weil die Abweichungen vom jeweiligen Gruppenmittel sich innerhalb jeder Gruppe zu null summieren. Wegen $macron(s)_X - macron(s) = Delta \/ 2$ und $macron(s)_Y - macron(s) = -Delta \/ 2$ ist $sigma^2_"zw" = Delta^2 \/ 4$. Definieren wir die Effektstärke "innerhalb" als $d_"in" = Delta \/ sigma_"in"$ (das ist Cohens $d$ mit Populationsvarianzen), folgt für die WEAT-Effektstärke mit Populationsstandardabweichung
$ d_"pop" = Delta / sqrt(sigma^2_"in" + Delta^2 \/ 4) = d_"in" / sqrt(1 + d_"in"^2 \/ 4). $ <k08-eq-dpop>

#satz(titel: [Schranken der WEAT-Effektstärke])[
  Mit Populationsstandardabweichung gilt $|d_"pop"| <= 2$, mit Stichprobenstandardabweichung ($N - 1$ im Nenner) $|d| <= 2 sqrt((N - 1) \/ N)$. Ist $Delta != 0$, wird die Schranke genau dann erreicht, wenn alle Wörter innerhalb jeder Zielmenge dieselbe Assoziation haben ($sigma_"in" = 0$).
]

#beweis[
  Für $sigma_"in" > 0$ folgt aus @k08-eq-dpop $|d_"pop"| = |d_"in"| \/ sqrt(1 + d_"in"^2 \/ 4) < |d_"in"| \/ sqrt(d_"in"^2 \/ 4) = 2$. Für $sigma_"in" = 0$ und $Delta != 0$ ist $sigma_"tot" = |Delta| \/ 2$ und damit $|d_"pop"| = 2$ exakt. Die Stichprobenstandardabweichung ist $s_"tot" = sigma_"tot" sqrt(N \/ (N - 1))$, also $d = d_"pop" sqrt((N - 1) \/ N)$. Da $d_"pop"$ maximal den Wert 2 annimmt, und zwar genau bei $sigma_"in" = 0$, folgt die zweite Aussage.
]

Der Satz hat praktische Konsequenzen. Für die kleinste denkbare Liste mit zwei Wörtern je Zielmenge ($N = 4$) ist das Maximum $2 sqrt(3 \/ 4) approx 1.73$, für vier Wörter je Menge ($N = 8$) ist es $sqrt(3.5) approx 1.87$. Effektstärken aus kurzen und langen Wortlisten sind daher nicht direkt vergleichbar, und die von Caliskan et al. berichteten Werte um $d = 1.8$ liegen nahe an der theoretischen Obergrenze. Außerdem ist $d$ nicht linear in $d_"in"$: Die Funktion in @k08-eq-dpop sättigt, sodass große Unterschiede zwischen Modellen auf der WEAT-Skala gestaucht erscheinen (@k08-fig-dsaett).

#figure(
  k08-plot(w: 8.5, h: 3.6, xmin: 0, xmax: 8, ymin: 0, ymax: 2.2, xticks: (0, 1, 2, 3, 4, 5, 6, 7, 8), yticks: (0, 0.5, 1, 1.5, 2),
    xlabel: [Effektstärke innerhalb der Gruppen $d_"in"$ (Cohen)], ylabel: [WEAT-Effektstärke $d_"pop"$],
    (X, Y) => {
      import cetz.draw: *
      line((X(0), Y(2)), (X(8), Y(2)), stroke: (paint: c-red, thickness: 0.7pt, dash: "dashed"))
      content((X(8), Y(2) + 0.18), anchor: "south-east", k08-t(fill: c-red)[Obergrenze 2])
      line(..range(0, 81).map(i => { let x = i / 10; (X(x), Y(x / calc.sqrt(1 + x * x / 4))) }), stroke: 1.2pt + c-blue)
      line(..range(0, 23).map(i => { let x = i / 10; (X(x), Y(x)) }), stroke: (paint: c-grey, thickness: 0.7pt, dash: "dotted"))
      content((X(2.3) + 0.1, Y(2.15)), anchor: "west", k08-t(fill: c-grey)[$d_"pop" = d_"in"$])
      circle((X(4), Y(1.789)), radius: 0.07, fill: c-accent, stroke: none)
      content((X(4) + 0.15, Y(1.789) - 0.1), anchor: "north-west", k08-t(fill: c-accent)[Rechenbeispiel: $d_"in" = 4$, $d_"pop" = 1.79$])
    }),
  caption: [Zusammenhang zwischen Cohens $d$ (innerhalb der Gruppen) und der WEAT-Effektstärke nach @k08-eq-dpop. Die WEAT-Skala sättigt bei 2; große Unterschiede werden gestaucht.],
) <k08-fig-dsaett>

=== Der Permutationstest und seine Auflösungsgrenze

Unter der Nullhypothese, dass die Zuordnung der Zielwörter zu $X$ und $Y$ für ihre Assoziation keine Rolle spielt, ist jede der $binom(N, n)$ gleich großen Partitionen gleich wahrscheinlich. Der exakte $p$-Wert ist der Anteil der Partitionen, deren Statistik mindestens so groß ist wie die beobachtete.

#satz(titel: [Kleinster erreichbarer $p$-Wert])[
  Zählt man die beobachtete Partition mit, ist der kleinste erreichbare einseitige $p$-Wert eines exakten WEAT-Permutationstests $1 \/ binom(N, n)$.
]

#beweis[
  Die beobachtete Partition selbst erfüllt $s(X_i, Y_i) >= s(X, Y)$, also ist der Zähler mindestens 1; der Nenner ist die Anzahl aller Partitionen $binom(N, n)$.
]

Für $N = 4$ sind das $binom(4, 2) = 6$ Partitionen und $p >= 1 \/ 6$, für $N = 8$ sind es 70 Partitionen und $p >= 0.0143$, erst für acht Wörter je Menge ($N = 16$) gibt es 12 870 Partitionen und damit eine feine Auflösung. Mit der strikten Formel der Originalarbeit wäre bei extremer Beobachtung formal $p = 0$ möglich, was offensichtlich unsinnig ist. Bei großen Listen wird nicht mehr vollständig aufgezählt, sondern eine Zufallsstichprobe von Partitionen gezogen. `scipy.stats.permutation_test` kann beides: Mit `n_resamples=np.inf` zählt es exakt auf (so prüft das Notebook die eigene Aufzählung gegen SciPy), mit endlichem `n_resamples` zieht es zufällige Partitionen.

#beispiel(titel: [WEAT von Hand])[
  Die Assoziationswerte seien bereits berechnet: $s(x_1) = 0.10$, $s(x_2) = 0.06$, $s(y_1) = -0.02$, $s(y_2) = 0.02$.

  *Mittelwerte:* $macron(s)_X = 0.08$, $macron(s)_Y = 0.00$, also $Delta = 0.08$.

  *Stichproben-SD* über $\{0.10, 0.06, -0.02, 0.02\}$: Gesamtmittel $0.04$, Abweichungsquadrate $0.0036 + 0.0004 + 0.0036 + 0.0004 = 0.008$, geteilt durch $N - 1 = 3$ ergibt $0.002667$, Wurzel $0.0516$. Damit $d = 0.08 \/ 0.0516 approx 1.55$.

  *Populations-SD:* $sqrt(0.008 \/ 4) = 0.0447$, also $d_"pop" approx 1.79$. Kontrolle über @k08-eq-dpop: $sigma_"in" = 0.02$ in beiden Gruppen, $d_"in" = 0.08 \/ 0.02 = 4$, $d_"pop" = 4 \/ sqrt(1 + 4) = 1.789$.

  *Permutationstest:* Die Teststatistik ist $s(X, Y) = 0.16 - 0.00 = 0.16$. Die sechs Partitionen liefern die Werte $-0.16, -0.08, 0, 0, 0.08, 0.16$. Nur die beobachtete erreicht $0.16$, also $p = 1 \/ 6 approx 0.167$. Das ist der kleinste mögliche Wert, und er ist nicht signifikant, obwohl die Effektstärke nahe am Maximum liegt.
]

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 10pt,
    k08-plot(w: 5.4, h: 2.4, xmin: -0.04, xmax: 0.12, ymin: 0, ymax: 2, xticks: (-0.04, 0, 0.04, 0.08, 0.12), yticks: (),
      xlabel: [Assoziation $s(w, A, B)$], ylabel: [],
      (X, Y) => {
        import cetz.draw: *
        for v in (0.10, 0.06) { circle((X(v), Y(1.4)), radius: 0.1, fill: c-blue, stroke: none) }
        for v in (-0.02, 0.02) { circle((X(v), Y(0.6)), radius: 0.1, fill: c-accent, stroke: none) }
        line((X(0.08), Y(1.1)), (X(0.08), Y(1.7)), stroke: 0.7pt + c-blue)
        line((X(0), Y(0.3)), (X(0), Y(0.9)), stroke: 0.7pt + c-accent)
        content((X(0.12), Y(1.4)), anchor: "east", k08-t(fill: c-blue)[$X$])
        content((X(0.12), Y(0.6)), anchor: "east", k08-t(fill: c-accent)[$Y$])
      }),
    k08-plot(w: 5.4, h: 2.4, xmin: -0.2, xmax: 0.2, ymin: 0, ymax: 2.5, xticks: (-0.16, -0.08, 0, 0.08, 0.16), yticks: (0, 1, 2),
      xlabel: [Statistik $s(X_i, Y_i, A, B)$], ylabel: [Anzahl],
      (X, Y) => {
        import cetz.draw: *
        for (v, n) in ((-0.16, 1), (-0.08, 1), (0, 2), (0.08, 1), (0.16, 1)) {
          rect((X(v) - 0.25, Y(0)), (X(v) + 0.25, Y(n)), fill: if v == 0.16 { c-accent } else { c-blue.lighten(40%) }, stroke: none)
        }
        content((X(0.16), Y(1) + 0.12), anchor: "south", k08-t(fill: c-accent)[beobachtet])
      }),
  ),
  caption: [WEAT-Rechenbeispiel. Links: Assoziationswerte der Zielwörter mit Gruppenmitteln (senkrechte Striche). Rechts: exakte Permutationsverteilung über alle sechs Partitionen; nur die beobachtete erreicht 0.16, daher $p = 1\/6$.],
) <k08-fig-weat>

=== Befunde: Caliskan et al.

#studie(titel: [Caliskan et al. 2017])[
  *Design:* Replikation klassischer IAT-Befunde auf GloVe-Einbettungen (Common Crawl) und word2vec; Einführung von WEAT und WEFAT (einer Variante, die die Assoziation einzelner Wörter mit realen Größen korreliert). *Befunde:* Effektstärken (in Klammern die menschlichen IAT-Werte): Blumen vs. Insekten mit angenehm vs. unangenehm $d = 1.50$ (1.35); europäisch- vs. afroamerikanisch klingende Namen mit angenehm vs. unangenehm $d = 1.41$ (1.17); männliche vs. weibliche Namen mit Karriere vs. Familie $d = 1.81$ (0.72); Mathematik vs. Kunst mit männlichen vs. weiblichen Begriffen $d = 1.06$ (0.82). Die Geschlechtsassoziation von Berufsbezeichnungen korreliert mit dem Frauenanteil in 50 US-Berufen mit $r = 0.90$, $p < 10^(-18)$. *Grenzen:* Statische Einbettungen; Abhängigkeit von den Wortlisten; spätere Arbeiten zeigen eine schwache Verbindung zu nachgelagertem Bias @caliskan2017semantics @goldfarbtarrant2021intrinsic.
]

Die Korrelation von $r = 0.90$ mit Arbeitsmarktstatistiken ist der Grund, warum WEAT so einflussreich wurde: Sie zeigt, dass Einbettungen nicht zufällige Artefakte, sondern die statistische Struktur der Sprache abbilden, aus der sie gelernt wurden. Ob man das als "Bias" oder als "korrekte Abbildung der Welt" bezeichnet, hängt wiederum davon ab, welches Desideratum man zugrunde legt: Unter "replizierten Verteilungen" wäre ein solches Modell geradezu erwünscht.

=== SEAT: der Schritt zu Satzencodern

Kontextuelle Modelle liefern keine festen Wortvektoren. May et al. haben WEAT deshalb auf Satzrepräsentationen übertragen: Ziel- und Attributwörter werden in "semantisch gebleichte" Schablonen wie "This is [WORD]." eingesetzt, und statt des Wortvektors nimmt man die Satzrepräsentation, etwa das [CLS]-Token @may2019measuring @gallegos2024bias. Die Formeln bleiben identisch. Die Ergebnisse für ELMo, BERT und weitere Encoder waren gemischt, und die Autoren berichten selbst von "verdächtigen Mustern der Empfindlichkeit", die nahelegen, dass die Annahmen des Tests im Allgemeinen nicht gelten @may2019measuring.

#fallstrick[
  WEAT und SEAT hängen stark von den gewählten Wortlisten ab. Delobelle et al. zeigen, dass Bias-Metriken für vortrainierte Sprachmodelle oft miteinander unvereinbar sind und empfindlich auf Schablonen, Seed-Wörter und die Wahl der Einbettung reagieren @delobelle2022measuring. Im Notebook verschiebt der Austausch eines einzigen von vier Attributwörtern die Effektstärke auf Spielzeugvektoren von 0.55 auf bis zu 0.99. Berichte deshalb immer die vollständigen Wortlisten und eine Sensitivitätsanalyse.
]

#datei("weat.py")[```python
import itertools
import numpy as np

def weat_effect_size(s_x, s_y, ddof=1):
    """Effektstärke d; ddof=1 Stichproben-SD, ddof=0 Populations-SD."""
    s_all = np.r_[s_x, s_y]
    return (np.mean(s_x) - np.mean(s_y)) / np.std(s_all, ddof=ddof)

def weat_permutation_p(s_x, s_y):
    """Exakter einseitiger p-Wert, beobachtete Partition mitgezählt."""
    s_all = np.r_[s_x, s_y]
    observed = np.sum(s_x) - np.sum(s_y)
    total = s_all.sum()
    stats = [2 * s_all[list(c)].sum() - total
             for c in itertools.combinations(range(len(s_all)), len(s_x))]
    return np.mean(np.array(stats) >= observed - 1e-12)

s_x, s_y = np.array([0.10, 0.06]), np.array([-0.02, 0.02])
print(weat_effect_size(s_x, s_y, 1), weat_effect_size(s_x, s_y, 0),
      weat_permutation_p(s_x, s_y))
```]

```out
1.5491933384829668 1.7888543819998317 0.16666666666666666
```

Der Trick in `weat_permutation_p` verdient eine Erklärung: Für eine Partition mit Zielmenge $X_i$ gilt $s(X_i, Y_i) = sum_(X_i) s_w - (T - sum_(X_i) s_w) = 2 sum_(X_i) s_w - T$ mit der Gesamtsumme $T$. Man muss also nur über die Teilmengen der Größe $n$ iterieren.

#hoersaal([WEAT liefert $d = 1.81$ für Karriere und Familie, der menschliche IAT nur 0.72. Sind die Einbettungen also "sexistischer" als Menschen?],
[Nein, diese Folgerung ist nicht gedeckt. Die beiden Effektstärken stehen auf verschiedenen Skalen: Der IAT misst Reaktionszeitunterschiede einzelner Personen, WEAT misst Kosinus-Unterschiede über eine kleine Menge von Wörtern, und die WEAT-Skala ist nach oben beschränkt und sättigt (siehe den Satz zu den Schranken). Zudem hängt der WEAT-Wert an den konkreten Wortlisten. Caliskan et al. stellen die Werte nebeneinander, um zu zeigen, dass die *Richtung* der Assoziationen repliziert wird, nicht um Stärken zu vergleichen @caliskan2017semantics.])

== Wahrscheinlichkeitsmetriken: CrowS-Pairs und StereoSet <k08-wahrscheinlichkeit>

Wahrscheinlichkeitsbasierte Metriken fragen nicht, wo ein Wort im Vektorraum liegt, sondern welchen von zwei Sätzen das Modell für wahrscheinlicher hält. Die Grundidee ist das *minimale Paar*: zwei Sätze, die sich nur in den Wörtern unterscheiden, die die Gruppe kennzeichnen. Bevorzugt das Modell systematisch die stereotype Variante, ist das ein Hinweis auf repräsentationalen Bias.

=== CrowS-Pairs

CrowS-Pairs enthält 1508 per Crowdsourcing erstellte minimale Paare zu neun Bias-Typen im US-Kontext; etwa 14.5 % der Paare sind anti-stereotyp formuliert @nangia2020crows. Jedes Paar besteht aus einem stärker stereotypisierenden Satz $S_1$ und einem schwächer stereotypisierenden Satz $S_2$. Beide Sätze werden in *unveränderte* Token $U$ (gemeinsam) und *veränderte* Token $M$ (die Gruppenwörter) zerlegt.

#definition(titel: [CrowS-Pairs-Score])[
  Für einen Satz $S$ ist die Pseudo-Log-Likelihood der unveränderten Token
  $ "score"(S) = sum_(i = 0)^(|C|) log P(u_i in U | U_(without u_i), M, theta), $ <k08-eq-crows>
  wobei $u_i$ das im Schritt $i$ maskierte unveränderte Token ist, $U_(without u_i)$ die übrigen unveränderten Token bezeichnet, $M$ nie maskiert wird und $theta$ die Modellparameter sind. Die im Paper gedruckte obere Grenze $|C|$ bezeichnet die Anzahl der unveränderten Token. Die *Metrik* ist der Prozentsatz der Paare mit $"score"(S_1) > "score"(S_2)$; der Idealwert ist 50, höhere Werte bedeuten stärkere Stereotypisierung @nangia2020crows.
]

Der Kniff liegt darin, *nur die unveränderten Token* zu maskieren und auf die Gruppenwörter zu bedingen. Würde man stattdessen die Wahrscheinlichkeit der Gruppenwörter vergleichen, gewänne einfach der häufigere Name: "John" ist im Trainingskorpus häufiger als "Shaniqua", unabhängig von jedem Stereotyp. Durch das Bedingen auf $M$ wird die unterschiedliche Vorkommenshäufigkeit der Gruppenwörter kontrolliert @nangia2020crows. Gallegos et al. bezeichnen das Maß als CrowS-Pairs Score (CPS) @gallegos2024bias.

#studie(titel: [Nangia et al. 2020])[
  *Design:* 1508 minimale Paare, neun Bias-Typen, maskierte Sprachmodelle. *Befunde:* Gesamtwerte BERT 60.5, RoBERTa 64.1, ALBERT 67.0 (ideal 50); alle Modelle in allen Kategorien verzerrt, etwa Religion 71.4 / 71.4 / 75.2 und Behinderung 61.7 / 71.7 / 81.7. *Grenzen laut Autoren:* nur US-Kontext; Metrik nur für maskierte Modelle; ein niedriger Score beweist nicht, dass ein Modell unverzerrt ist; einige ungültige Testfälle; nicht darauf trainieren @nangia2020crows.
]

Für autoregressive Modelle ist die Pseudo-Log-Likelihood nicht definiert. Die Autoren nennen die Entwicklung von Metriken, mit denen sich autoregressive Modelle auf CrowS-Pairs testen lassen, ausdrücklich als künftige Arbeit @nangia2020crows. In der Praxis verwendet man die Log-Likelihood des ganzen Satzes. Das ist eine *andere Metrik*: Sie bedingt nicht mehr auf die Gruppenwörter und ist daher anfällig für genau den Häufigkeitseffekt, den das Original ausschalten wollte. Zahlen aus beiden Varianten sind nicht vergleichbar, und du musst angeben, welche du verwendet hast.

#beispiel(titel: [Ist 60.5 von 50 verschieden?])[
  Behandelt man die 1508 Paare als unabhängige Bernoulli-Versuche, ist der Standardfehler eines Anteils von 50 % gleich $sqrt(0.25 \/ 1508) = 0.0129$, also 1.29 Prozentpunkte. BERTs 60.5 % liegt damit $z = (0.605 - 0.5) \/ 0.0129 approx 8.2$ Standardfehler über dem Idealwert. Die Unabhängigkeitsannahme ist allerdings fragwürdig, weil viele Paare aus ähnlichen Schablonen stammen, und Blodgett et al. kritisieren gerade, dass Benchmarks dieser Art ohne Signifikanztests und mit gleichgewichteten, teils ungültigen Paaren berichtet werden @blodgett2021stereotyping. Pro Kategorie ist die Stichprobe deutlich kleiner und das Intervall entsprechend breiter.
]

=== Log-Probability Bias Score

Eine Variante für Schablonen mit einem einzigen geschützten Attributwort ist der Log-Probability Bias Score @gallegos2024bias:
$ "LPBS"(S) = log p_(a_i) / p_("prior"_i) - log p_(a_j) / p_("prior"_j). $ <k08-eq-lpbs>
Dabei ist $p_(a_i)$ die Wahrscheinlichkeit des Attributworts $a_i$ (etwa "he") in einer Schablone mit Zielwort (etwa "[MASK] is a nurse") und $p_("prior"_i)$ dieselbe Wahrscheinlichkeit, wenn auch das Zielwort maskiert ist. Die Normierung mit dem Prior korrigiert die Grundhäufigkeit von $a_i$: Wenn "he" generell häufiger vorhergesagt wird, ist das kein Pflegeberuf-spezifischer Effekt.

=== StereoSet: Stereotyp und Sprachmodellqualität gemeinsam

StereoSet adressiert ein Problem, das bei CrowS-Pairs offen bleibt: Ein Modell, das Unsinn produziert, kann einen idealen Score von 50 erreichen. Jeder *Context Association Test* (CAT) besteht deshalb aus einem Kontext und drei Optionen: einer stereotypen, einer anti-stereotypen und einer sinnlosen Assoziation @nadeem2021stereoset. Der Datensatz umfasst 16 995 CATs (8498 intrasentence, 8497 intersentence) zu 321 Zielbegriffen in vier Domänen (Geschlecht, Beruf, Ethnie, Religion) @nadeem2021stereoset.

#definition(titel: [StereoSet-Kennzahlen])[
  - *Language Modeling Score* (lms): Anteil der Fälle, in denen das Modell eine sinnvolle (stereotype oder anti-stereotype) gegenüber der sinnlosen Assoziation bevorzugt. Ideal 100.
  - *Stereotype Score* (ss): Anteil der Fälle, in denen das Modell die stereotype gegenüber der anti-stereotypen Assoziation bevorzugt. Ideal 50.
  - *Idealized CAT Score*:
  $ "icat" = "lms" dot min("ss", 100 - "ss") / 50. $ <k08-eq-icat>
  Ideal 100; ein Zufallsmodell hat lms 50, ss 50 und damit icat 50 @nadeem2021stereoset.
]

Die Konstruktion von @k08-eq-icat lässt sich aus drei Forderungen ableiten. Erstens soll ein perfektes Modell (lms 100, ss 50) den Wert 100 erhalten. Zweitens soll ein Modell, das immer die stereotype *oder* immer die anti-stereotype Option wählt (ss 100 oder ss 0), den Wert 0 erhalten. Drittens soll der Wert linear in lms sein. Der Faktor $min("ss", 100 - "ss") \/ 50$ ist die einfachste Funktion, die bei ss $= 50$ gleich 1 und bei ss $in {0, 100}$ gleich 0 ist und symmetrisch um 50 liegt: eine Zeltfunktion (@k08-fig-icat).

#beispiel(titel: [ICAT für GPT-2])[
  GPT-2 small erreicht lms 83.6 und ss 56.4 @nadeem2021stereoset. Dann ist
  $ "icat" = 83.6 dot min(56.4, 43.6) / 50 = 83.6 dot 0.872 = 72.9. $
  Das Paper berichtet 73.0, gerechnet aus den ungerundeten Werten. Für GPT-2 medium (lms 85.9, ss 58.2) ergibt sich $85.9 dot 41.8 \/ 50 = 71.8$ (berichtet 71.7), für GPT-2 large (lms 88.3, ss 60.1) $88.3 dot 39.9 \/ 50 = 70.5$ (berichtet 70.5).
]

#figure(
  k08-plot(w: 9, h: 3.8, xmin: 0, xmax: 100, ymin: 0, ymax: 100, xticks: (0, 25, 50, 75, 100), yticks: (0, 25, 50, 75, 100),
    xlabel: [Stereotype Score ss], ylabel: [icat],
    (X, Y) => {
      import cetz.draw: *
      for (lms, col) in ((100, c-grey), (88.3, c-blue), (85.9, c-violet), (83.6, c-teal)) {
        line((X(0), Y(0)), (X(50), Y(lms)), (X(100), Y(0)), stroke: (paint: col, thickness: if lms == 100 { 0.8pt } else { 0.7pt }, dash: if lms == 100 { "dashed" } else { none }))
      }
      for (ss, ic, col) in ((56.4, 72.9, c-teal), (58.2, 71.8, c-violet), (60.1, 70.5, c-blue)) {
        circle((X(ss), Y(ic)), radius: 0.08, fill: col, stroke: white + 0.5pt)
      }
      for (i, (col, lab)) in ((c-grey, [lms 100 (ideal)]), (c-teal, [GPT-2 small: lms 83.6, ss 56.4]), (c-violet, [GPT-2 medium: lms 85.9, ss 58.2]), (c-blue, [GPT-2 large: lms 88.3, ss 60.1])).enumerate() {
        line((9.4, 3.6 - i * 0.4), (9.9, 3.6 - i * 0.4), stroke: (paint: col, thickness: 1pt, dash: if i == 0 { "dashed" } else { none }))
        if i > 0 { circle((9.65, 3.6 - i * 0.4), radius: 0.07, fill: col, stroke: none) }
        content((10.0, 3.6 - i * 0.4), anchor: "west", k08-t(fill: col.darken(10%), lab))
      }
    }),
  caption: [ICAT als Zeltfunktion des Stereotype Score für feste lms; jeder Punkt liegt auf dem Zelt seiner eigenen lms. Die drei GPT-2-Größen werden mit wachsender Größe bessere Sprachmodelle (höhere lms), aber stereotyper (ss steigt), sodass icat fällt.],
) <k08-fig-icat>

#studie(titel: [Nadeem et al. 2021])[
  *Design:* 16 995 CATs, vier Domänen, Crowdsourcing; Vergleich mehrerer vortrainierter Modelle. *Befunde:* Bei GPT-2 steigt ss mit der Modellgröße (56.4, 58.2, 60.1), lms ebenso (83.6, 85.9, 88.3), icat fällt (73.0, 71.7, 70.5). *Grenzen laut Autoren:* Die Crowdworker waren überwiegend unter 50; Stereotype sind subjektiv; manche Aussagen sind sachlich falsch; eine Präferenz für manche Stereotype kann vernünftig sein @nadeem2021stereoset.
]

Das Muster "größer heißt stereotyper" ist eine der bekanntesten Aussagen der Bias-Literatur. Bevor du es in einer Vorlesung als gesichert präsentierst, lohnt der Blick auf die Messqualität: Blodgett et al. haben Stichproben aus vier Fairness-Benchmarks auf Fehlerquellen untersucht und fanden, dass nur 6 % der intrasentence- und 0 % der intersentence-Tests von StereoSet sowie 3 % der Tests von CrowS-Pairs frei von allen Fallstricken waren @blodgett2021stereotyping. @k08-validitaet geht darauf ein.

#fallstrick[
  ICAT bestraft Abweichungen von ss $= 50$ *symmetrisch*. Ein Modell, das konsequent anti-stereotyp antwortet, bekommt denselben Wert wie eines, das konsequent stereotyp antwortet. Das ist eine normative Entscheidung, keine mathematische Notwendigkeit, und die StereoSet-Autoren räumen selbst ein, dass eine Präferenz für manche Stereotype vernünftig sein kann @nadeem2021stereoset. Die Idealwerte 50 (CrowS-Pairs, ss) und 0 (BBQ) kodieren nach unserer Einschätzung durchgängig die Annahme, das Ziel sei "kein Einfluss der Gruppenbegriffe". Dass solche gewünschten Ergebnisse oft gar nicht ausgesprochen werden, zeigen Goldfarb-Tarrant et al.: In 22 % der untersuchten Bias-Tests war das gewünschte Ergebnis unklar @goldfarbtarrant2023prompt.
]

== Generierte Texte und Frage-Antwort-Aufgaben <k08-generiert>

Für moderne Chat-Modelle sind Metriken auf generierten Ausgaben die natürliche Wahl, weil sie keinen Zugriff auf das Modellinnere brauchen. Sie zerfallen in zwei Gruppen: strukturierte Aufgaben mit eindeutig auswertbarer Antwort (BBQ) und offene Generierung, die erst durch Zählen oder einen Klassifikator in Zahlen übersetzt werden muss (BOLD, HolisticBias).

=== BBQ: Bias in Frage-Antwort-Aufgaben

Der *Bias Benchmark for QA* (BBQ) ist für die Arbeit mit Instruktionsmodellen der wichtigste einzelne Benchmark @parrish2022bbq. Er umfasst 58 492 Beispiele aus 325 Schablonen über neun soziale Dimensionen sowie zwei intersektionale Kategorien (Ethnie mal Geschlecht, Ethnie mal sozioökonomischer Status) @parrish2022bbq. Der Kern des Designs ist die Paarung jeder Frage mit zwei Kontexten (@k08-fig-bbq):

- Im *mehrdeutigen* Kontext enthält der Text nicht genug Information, um die Frage zu beantworten; die korrekte Antwort ist "unbekannt". Wer hier eine Person auswählt, muss auf etwas anderes als den Text zurückgreifen, typischerweise auf ein Stereotyp.
- Im *eindeutigen* Kontext liefert ein Zusatzsatz die Antwort. Hier prüft BBQ, ob ein Stereotyp die korrekte Antwort überstimmt.

Zusätzlich gibt es jede Frage in negativer Polarität ("Wer war schlecht in Mathe?") und nicht-negativer Polarität ("Wer war gut in Mathe?"), damit sich eine generelle Präferenz für eine Person nicht als Bias tarnen kann.

#figure(
  diagram(spacing: (7mm, 6mm), edge-stroke: 0.7pt,
    fknoten((1, 0), [Schablone mit zwei Personen \ (Zielgruppe, Nicht-Zielgruppe)], col: c-dark, filled: true, w: 50mm),
    fknoten((0, 1), [*mehrdeutiger Kontext* \ korrekt: "unbekannt"], col: c-blue, w: 40mm),
    fknoten((2, 1), [*eindeutiger Kontext* \ korrekt: aus dem Text], col: c-teal, w: 40mm),
    edge((1, 0), (0, 1), "-|>"), edge((1, 0), (2, 1), "-|>"),
    fknoten((0, 2), [negative Frage / \ nicht-negative Frage], col: c-grey, w: 40mm),
    fknoten((2, 2), [negative Frage / \ nicht-negative Frage], col: c-grey, w: 40mm),
    edge((0, 1), (0, 2), "-|>"), edge((2, 1), (2, 2), "-|>"),
    fknoten((0, 3), [Genauigkeit, $s_"AMB"$], col: c-accent, filled: true, w: 40mm),
    fknoten((2, 3), [Genauigkeit, $s_"DIS"$], col: c-accent, filled: true, w: 40mm),
    edge((0, 2), (0, 3), "-|>"), edge((2, 2), (2, 3), "-|>"),
  ),
  caption: [Aufbau eines BBQ-Items: jede Schablone in zwei Kontexten und zwei Frage-Polaritäten. Ausgewertet werden Genauigkeit und Bias-Score getrennt nach Kontexttyp.],
) <k08-fig-bbq>

#definition(titel: [BBQ-Bias-Scores])[
  Im eindeutigen Kontext ist
  $ s_"DIS" = 2 (n_"biased" / n_"non-UNKNOWN") - 1, $ <k08-eq-sdis>
  im mehrdeutigen Kontext
  $ s_"AMB" = (1 - "accuracy") s_"DIS". $ <k08-eq-samb>
  Dabei ist $n_"biased"$ die Anzahl der Ausgaben, die dem untersuchten Bias entsprechen (die Zielgruppe bei negativen, die Nicht-Zielgruppe bei nicht-negativen Fragen), $n_"non-UNKNOWN"$ die Anzahl der Ausgaben, die nicht "unbekannt" lauten, und accuracy die Genauigkeit im mehrdeutigen Kontext. Wertebereich $[-1, 1]$; 0 bedeutet keinen gemessenen Bias, positive Werte entsprechen dem untersuchten Bias @parrish2022bbq.
]

Die Form $2q - 1$ in @k08-eq-sdis ist eine lineare Umskalierung des Anteils $q = n_"biased" \/ n_"non-UNKNOWN"$ von $[0, 1]$ auf $[-1, 1]$: Bei $q = 0.5$ verteilen sich die Nicht-unbekannt-Antworten gleichmäßig, und der Score ist 0. Der Faktor $(1 - "accuracy")$ in @k08-eq-samb gewichtet den Bias mit dem Anteil der Fälle, in denen das Modell überhaupt eine Person nennt. Ein Modell, das im mehrdeutigen Kontext fast immer korrekt "unbekannt" sagt, kann zwar unter den wenigen restlichen Antworten stark verzerrt sein, richtet aber insgesamt wenig Schaden an.

#achtung[
  Die Originalarbeit schreibt in @k08-eq-samb den Score $s_"DIS"$. Für den Bericht von $s_"AMB"$ wird der Anteil in der Klammer jedoch üblicherweise über die Ausgaben im *mehrdeutigen* Kontext berechnet, so auch im folgenden Rechenbeispiel. Ob die Analyse-Skripte des BBQ-Repositorys genau so vorgehen, konnte für dieses Buch nicht geprüft werden (Stand: 11. November 2026). Prüfe die Skripte, bevor du Zahlen aus verschiedenen Arbeiten vergleichst.
]

#beispiel(titel: [BBQ-Scores])[
  *Mehrdeutiger Kontext:* 1000 Fragen; das Modell antwortet 700-mal "unbekannt" (accuracy $= 0.70$). Von den 300 übrigen Antworten entsprechen 210 dem Bias. Anteil $210 \/ 300 = 0.70$, innerer Score $2 dot 0.70 - 1 = 0.40$, also $s_"AMB" = 0.30 dot 0.40 = 0.12$.

  *Eindeutiger Kontext:* 1000 Fragen, 950 Antworten nennen eine Person, 520 davon entsprechen dem Bias (gleich ob korrekt oder nicht). Dann $s_"DIS" = 2 dot 520 \/ 950 - 1 = 0.095$.

  Beide Werte sind klein, aber nicht gleich zu interpretieren: $s_"AMB" = 0.12$ heißt, dass das Modell in mehrdeutigen Situationen in 30 % der Fälle rät und dabei überwiegend stereotyp rät.
]

#studie(titel: [Parrish et al. 2022])[
  *Design:* 58 492 Beispiele, Multiple-Choice mit drei Optionen (zwei Personen und "unbekannt"), mehrere QA-Modelle. *Befunde:* Beste Gesamtgenauigkeit UnifiedQA (RACE-Format) 77.8 %, schlechteste RoBERTa-Base 61.4 %, Zufall 33.3 %, Menschen 95.7 %. Die Genauigkeit im mehrdeutigen Kontext lag bei keinem Modell über 67.5 %. Falsche Antworten im mehrdeutigen Kontext entsprachen je nach Modell in 56 % bis 77 % der Fälle dem Bias. Im eindeutigen Kontext war die Genauigkeit bis zu 3.4 Punkte höher, wenn die richtige Antwort zum Stereotyp passte, bei Geschlecht über 5 Punkte. *Grenzen:* US-englischer Kontext, schablonenhafter Text, Multiple-Choice-Format @parrish2022bbq.
]

Der letzte Befund ist methodisch der interessanteste: Selbst wenn der Text die Antwort eindeutig vorgibt, ist das Modell besser, wenn diese Antwort zum Stereotyp passt. Das ist ein klassischer Fall differenziellen Messfehlers. Die Daten stehen unter CC-BY-4.0 (Stand: 11. November 2026) und sind über Hugging Face ladbar, was BBQ zur ersten Wahl für eine Übung mit einem offenen Instruktionsmodell macht.

=== Metriken auf offener Generierung

Für offene Generierung haben Gallegos et al. eine Formelsammlung zusammengestellt @gallegos2024bias. Bezeichne $hat(cal(Y))$ die Menge der Generierungen, $c(dot)$ einen Klassifikatorscore (Sentiment, Toxizität, Regard), $C(a, hat(Y))$ die Anzahl des Attributworts $a$ in einer Generierung $hat(Y)$ und $I(dot)$ die Indikatorfunktion. @k08-tab-gentext zeigt die wichtigsten Maße.

#figure(
  table(columns: (auto, 1fr),
    [Metrik], [Formel und Bedeutung],
    [Co-occurrence-Bias], [$log P(w | A_i) \/ P(w | A_j)$ für ein neutrales Wort $w$],
    [Demografische Repräsentation], [$"DR"(G_i) = sum_(a_i in A_i) sum_(hat(Y) in hat(cal(Y))) C(a_i, hat(Y))$, verglichen über Gruppen, etwa mit einer Gleichverteilung],
    [Stereotype Assoziationen], [$"ST"(w)_i = sum_(a_i in A_i) sum_(hat(Y)) C(a_i, hat(Y)) I(C(w, hat(Y)) > 0)$],
    [Expected Maximum Toxicity], [$"EMT"(hat(cal(Y))) = max_(hat(Y) in hat(cal(Y))) c(hat(Y))$, in der Praxis über Prompts gemittelt],
    [Score-Parität], [$|EE[c(hat(Y)_i, i) | A = i] - EE[c(hat(Y)_j, j) | A = j]|$],
    [Kontrafaktischer Sentiment-Bias], [$W_1 (P(c(hat(Y)_i) | A = i), P(c(hat(Y)_j) | A = j))$, Wasserstein-1-Abstand der Sentimentverteilungen kontrafaktischer Prompts],
    [HONEST], [Anteil der Top-$k$-Vervollständigungen, die im Lexikon HurtLex stehen],
  ),
  caption: [Metriken auf generiertem Text nach Gallegos et al. @gallegos2024bias.],
) <k08-tab-gentext>

Der Wasserstein-Abstand in der kontrafaktischen Sentiment-Metrik ist bewusst gewählt: Anders als eine Mittelwertdifferenz erfasst er auch Unterschiede in der Form der Verteilung. Zwei Gruppen können denselben mittleren Sentimentwert haben, während eine Gruppe deutlich mehr sehr negative Texte erhält. Für eindimensionale Verteilungen ist $W_1$ gleich der Fläche zwischen den beiden Verteilungsfunktionen, was die Berechnung einfach macht.

=== BOLD und HolisticBias

#studie(titel: [Dhamala et al. 2021 (BOLD)])[
  *Design:* 23 679 Prompts aus Satzanfängen der englischen Wikipedia zu 43 Gruppen in fünf Domänen: Beruf 10 195 (18 Gruppen), Geschlecht 3204 (2), Ethnie 7657 (4), Religion 639 (7), politische Ideologie 1984 (12). Modelle BERT, GPT-2 und CTRL; Wikipedia-Text als Vergleich. Fünf Metrikfamilien: Sentiment, Toxizität, Regard, psycholinguistische Normen, Gender-Polarität. *Befunde:* Die meisten Modelle sind verzerrter als die Wikipedia-Basis, besonders gegenüber historisch benachteiligten Gruppen. Nur 6.57 % der Berufsgenerierungen sind geschlechtlich markiert, die meisten Berufe männlich verzerrt (Verhältnis männlich zu weiblich 3.18 bei GPT-2, 1.25 bei BERT). Prompts zu Afroamerikanern liefern die höchsten Werte für negatives Sentiment (0.08154) und Toxizität (0.00297); weniger als 0.5 % aller Texte sind toxisch. *Validierung:* Gender-Polarität korreliert mit menschlichen Urteilen mit Spearman 0.9186 (Wavg) und 0.9126 (Max), Sentiment nur mit 0.5163, Toxizität mit 0.5839. *Grenze:* Wikipedia ist keine faire Basis, weil ihre Autorenschaft demografisch verzerrt ist @dhamala2021bold.
]

Die Gender-Polarität von BOLD ist ein schönes Beispiel für eine transparente, klassifikatorfreie Metrik. Jedes Wort $w_i$ einer Generierung erhält die Projektion
$ b_i = (arrow(w)_i dot arrow(g)) / (norm(arrow(w)_i) norm(arrow(g))), quad arrow(g) = arrow("she") - arrow("he"), $ <k08-eq-bold-b>
berechnet in hart entzerrten word2vec-Einbettungen. Der Text erhält
$ "Gender-Wavg" = (sum_i op("sgn")(b_i) b_i^2) / (sum_i |b_i|); $ <k08-eq-bold-wavg>
Werte $<= -0.25$ gelten als männlich, Werte $>= 0.25$ als weiblich; Gender-Max nimmt stattdessen das Wort mit dem größten $|b_i|$ @dhamala2021bold. Die Gewichtung mit $|b_i|$ sorgt dafür, dass stark polarisierte Wörter den Ausschlag geben und die vielen neutralen Wörter mit $b_i approx 0$ kaum zählen.

#beispiel(titel: [Gender-Wavg])[
  Ein kurzer Text enthält drei Wörter mit nennenswerter Projektion: $b = (0.30, -0.10, 0.05)$. Zähler: $0.09 - 0.01 + 0.0025 = 0.0825$; Nenner: $0.30 + 0.10 + 0.05 = 0.45$. Gender-Wavg $= 0.183$, also unter der Schwelle 0.25: Der Text gilt als neutral, obwohl ein Wort deutlich weiblich konnotiert ist. Gender-Max würde mit $b = 0.30$ als weiblich einstufen.
]

Die Validierungszahlen von BOLD tragen eine Lehre, die über den Benchmark hinausgeht: Sobald eine Metrik von einem fremden Klassifikator abhängt (Sentiment, Toxizität, Regard), erbt sie dessen Fehler, und die Übereinstimmung mit menschlichen Urteilen sinkt deutlich. Klassifikatorbasierte Metriken sind das schwache Glied.

HolisticBias von Smith et al. setzt bei der Auswahl der Gruppenbegriffe an: Fast 600 Deskriptoren über 13 demografische Achsen wurden in einem partizipativen Prozess mit Fachleuten und Community-Mitgliedern zusammengestellt und zu über 450 000 Satz-Prompts kombiniert @smith2022sorry. Damit ließen sich zuvor unentdeckte Verzerrungen in den Token-Wahrscheinlichkeiten von Sprachmodellen messen @smith2022sorry. Für dich ist HolisticBias vor allem eine Quelle von Identitätsbegriffen für kontrafaktische Tauschtests im großen Maßstab.

=== Das Ende der Perspective API

#praxis[
  Die Perspective API war über Jahre der De-facto-Standard für Toxizitätsmessung und steckt in vielen Bias-Metriken (Expected Maximum Toxicity, Score-Parität, BOLD-Toxizität). Laut offizieller Ankündigung bleibt der Dienst bis 31. Dezember 2026 aktiv; Anfragen zu Nutzung und Kontingenten wurden nur bis Februar 2026 bearbeitet (Stand: 11. November 2026). Eine Übersicht über 241 Arbeiten, die Perspective nutzen oder untersuchen, fand überzogene Behauptungen und Ergebnisse, die sich änderten, als das Modell ohne Ankündigung neu trainiert wurde; Gruppenunterschiede waren messbar, aber nicht erklärbar. Die Autoren veröffentlichen Perspective-Scores für 5.9 Millionen Textausschnitte aus 77 Datensätzen und formulieren zehn Anforderungen an eine Messinfrastruktur, die dem Feld selbst gehört @hartmann2026bye. Für deine Arbeit heißt das: Klassifikatorversion fixieren und berichten, Rohscores archivieren, und für neue Projekte ein lokal laufendes, versioniertes Modell verwenden.
]

=== Meinungs- und politischer Bias

Eine eigene Unterfamilie von Metriken auf generiertem Text betrifft Meinungen. Santurkar et al. vergleichen die Antwortverteilung eines Modells mit den Verteilungen von 60 demografischen US-Gruppen auf 1498 Fragen aus 15 Wellen des Pew American Trends Panel @santurkar2023whose. Ihr Repräsentativitätsmaß ist
$ cal(A)(D_1, D_2; Q) = 1/(|Q|) sum_(q in Q) [1 - (W D(D_1(q), D_2(q))) / (N - 1)], $ <k08-eq-opinionqa>
wobei $D_1(q)$ und $D_2(q)$ die Antwortverteilungen von Modell und Gruppe auf Frage $q$ sind, $W D$ der 1-Wasserstein-Abstand auf den als ganze Zahlen kodierten ordinalen Antworten und $N$ die Anzahl der Antwortoptionen ohne Verweigerung. Die Division durch $N - 1$ normiert, denn der größte mögliche Wasserstein-Abstand auf ${1, dots, N}$ ist $N - 1$ (alle Masse an einem Ende gegen alle am anderen).

#beispiel(titel: [Repräsentativität einer Frage])[
  Vier ordinale Optionen, Modell $D_1 = (0.1, 0.2, 0.3, 0.4)$, Gruppe $D_2 = (0.4, 0.3, 0.2, 0.1)$. Die Verteilungsfunktionen sind $(0.1, 0.3, 0.6, 1)$ und $(0.4, 0.7, 0.9, 1)$; der Wasserstein-Abstand ist die Summe der Absolutdifferenzen $0.3 + 0.4 + 0.3 = 1.0$. Repräsentativität $1 - 1.0 \/ 3 = 0.667$.
]

Santurkar et al. fanden kein Modell, das die US-Befragten insgesamt repräsentiert; die mit Feedback trainierten OpenAI-Modelle lagen näher an liberalen, einkommensstarken, gut gebildeten und nicht religiösen Gruppen, Basismodelle näher an einkommensschwächeren, moderaten und konservativen Gruppen @santurkar2023whose.

Wie zerbrechlich Fragebogenmessungen bei LLMs sind, zeigen Röttger et al. am Political Compass Test mit 62 Aussagen @rottger2024political. Ohne erzwungene Antwort geben manche Modelle kaum gültige Antworten (Llama 2 7b nur 6.5 %); Paraphrasen der Anweisung erzeugen widersprüchliche Positionen bei 14 von 62 (Mistral) und 23 von 62 (GPT-3.5) Aussagen; offene Antworten kehren die Mehrheitsposition bei 19 von 62 (GPT-3.5) und 23 von 62 (Mistral) Aussagen um @rottger2024political. Die Konsequenz der Autoren: in realistischen Nutzungsszenarien messen, Robustheit prüfen, Aussagen lokal halten. IssueBench setzt das um und misst Einseitigkeit bei Schreibassistenz auf 2.49 Millionen Prompts aus 3900 Schablonen und 212 politischen Themen; der Issue-Bias war verbreitet, über Modelle sehr ähnlich, und alle Modelle lagen bei einem Teil der Themen näher an den Meinungen von Wählern der US-Demokraten als der Republikaner @rottger2026issuebench.

#hoersaal([Ein Modell weigert sich, die Political-Compass-Fragen zu beantworten. Ist es dann neutral?],
[Die Verweigerung sagt nur, dass dieses Messinstrument bei diesem Modell nicht funktioniert. Röttger et al. zeigen, dass erzwungene Antworten ein Artefakt des Formats sind und dass offene Antworten oft eine andere Position zeigen @rottger2024political. Ob ein Modell politisch einseitig ist, misst man besser dort, wo es eingesetzt wird, etwa beim Verfassen von Texten zu politischen Themen @rottger2026issuebench. Dasselbe Muster kennst du von expliziten und impliziten Messungen: Neutrales Antwortverhalten auf direkte Fragen schließt verzerrte Assoziationen nicht aus @bai2025explicitly.])

== Gruppenfairness für Entscheidungen in Pipelines <k08-gruppen>

Sobald eine Stufe deiner Pipeline eine binäre Entscheidung trifft (zum Gespräch einladen, als toxisch markieren, in die Top-$k$ aufnehmen), stehen dir die Kriterien der klassischen Fairness-Literatur zur Verfügung. Sie sind präzise definiert, gut verstanden und direkt auf allokative Schäden bezogen. Gerade deshalb lohnt es sich, sie sauber herzuleiten, einschließlich der Ergebnisse, die zeigen, dass sie nicht alle zugleich erfüllbar sind.

=== Notation und die drei Grundkriterien

Wir folgen Barocas, Hardt und Narayanan @barocas2023fairness. $A$ ist das Gruppenmerkmal, $Y in {0, 1}$ das wahre Ergebnis (etwa "qualifiziert"), $R$ ein Score und $hat(Y) in {0, 1}$ die Entscheidung. Die *Basisrate* einer Gruppe ist $p_a = PP{Y = 1 | A = a}$.

#definition(titel: [Unabhängigkeit, Separation, Suffizienz])[
  - *Unabhängigkeit* (_independence_, Demographic Parity): $A perp R$; für eine binäre Entscheidung $PP{hat(Y) = 1 | A = a} = PP{hat(Y) = 1 | A = b}$.
  - *Separation* (_separation_, Equalized Odds): $R perp A | Y$; für eine binäre Entscheidung gleiche Richtig-positiv-Raten (TPR) und Falsch-positiv-Raten (FPR) in allen Gruppen @barocas2023fairness @hardt2016equality:
  $ PP{hat(Y) = 1 | A = 0, Y = y} = PP{hat(Y) = 1 | A = 1, Y = y}, quad y in {0, 1}. $ <k08-eq-eodds>
  - *Equal Opportunity* ist die Abschwächung auf $y = 1$, also nur gleiche TPR @hardt2016equality.
  - *Suffizienz* (_sufficiency_): $Y perp A | R$; Kalibrierung je Gruppe verlangt $PP{Y = 1 | R = r, A = a} = r$ @barocas2023fairness.
]

Die drei Kriterien entsprechen drei verschiedenen Intuitionen. Unabhängigkeit sagt: Jede Gruppe soll im gleichen Anteil ausgewählt werden, egal wie die Qualifikationen verteilt sind. Separation sagt: Unter den tatsächlich Qualifizierten soll jede Gruppe gleich oft erkannt werden, und unter den nicht Qualifizierten gleich oft fälschlich ausgewählt. Suffizienz sagt: Ein Score von 0.7 soll für jede Gruppe dasselbe bedeuten. Das Lehrbuch formuliert die Spannung mit Kalibrierung, gleicher Falsch-positiv-Rate und gleicher Falsch-negativ-Rate als drei jeweils verteidigbare Forderungen @haindl2027research.

=== Skalare Kennzahlen

Für Berichte braucht man Zahlen. Sei $"SR"_a = PP{hat(Y) = 1 | A = a}$ die *Selektionsrate* der Gruppe $a$.

#definition(titel: [Kennzahlen der Gruppenfairness])[
  $ Delta_"DP" = max_a "SR"_a - min_a "SR"_a, quad "DIR" = (min_a "SR"_a) / (max_a "SR"_a), $ <k08-eq-dp>
  $ Delta_"TPR" = max_a "TPR"_a - min_a "TPR"_a, quad Delta_"EOdds" = max(Delta_"TPR", Delta_"FPR"). $ <k08-eq-deltas>
  $Delta_"DP"$ ist die Demographic-Parity-Differenz, DIR das Disparate-Impact-Verhältnis, $Delta_"TPR"$ die Equal-Opportunity-Differenz, $Delta_"FPR" = max_a "FPR"_a - min_a "FPR"_a$ die analoge Lücke der Falsch-positiv-Raten und $Delta_"EOdds"$ die Equalized-Odds-Differenz in der Variante "schlechtester Fall".
]

Die Verhältnisregel $"SR"_a \/ "SR"_b >= 1 - epsilon$ mit $epsilon = 0.2$ entspricht der aus dem US-Arbeitsrecht bekannten "80-Prozent-Regel" (_four-fifths rule_) @barocas2023fairness. Fairlearn definiert `demographic_parity_difference` als Differenz zwischen größter und kleinster Selektionsrate; `equalized_odds_difference` liefert mit `agg='worst_case'` das Maximum aus TPR- und FPR-Lücke, mit `agg='mean'` deren Mittel (Fairlearn 0.15.0, Stand: 11. November 2026). Bei mehr als zwei Gruppen verdichtet die Max-min-Form alle Gruppen auf das extremste Paar; das ist eine Konvention, die du berichten musst.

=== Das Rechenbeispiel: ein LLM-Screener

#beispiel(titel: [LLM-Lebenslauf-Screener])[
  Je Gruppe gibt es 300 Bewerbungen, davon 100 qualifiziert und 200 nicht qualifiziert. Der Screener lädt in Gruppe $a$ 80 Qualifizierte und 10 nicht Qualifizierte ein (90 Einladungen), in Gruppe $b$ 70 und 2 (72 Einladungen).

  *Selektionsraten:* $"SR"_a = 90 \/ 300 = 0.30$, $"SR"_b = 72 \/ 300 = 0.24$. Also $Delta_"DP" = 0.06$ und $"DIR" = 0.24 \/ 0.30 = 0.80$, genau an der Vier-Fünftel-Schwelle.

  *Fehlerraten:* $"TPR"_a = 80 \/ 100 = 0.80$, $"TPR"_b = 0.70$; $"FPR"_a = 10 \/ 200 = 0.05$, $"FPR"_b = 2 \/ 200 = 0.01$. Also $Delta_"TPR" = 0.10$, $Delta_"FPR" = 0.04$ und $Delta_"EOdds" = 0.10$ (schlechtester Fall) beziehungsweise 0.07 (Mittel).

  *Unsicherheit:* Der Standardfehler der Differenz zweier unabhängiger Anteile ist $sqrt(0.30 dot 0.70 \/ 300 + 0.24 dot 0.76 \/ 300) = 0.0362$. Das 95-%-Intervall $0.06 plus.minus 1.96 dot 0.0362$ reicht von $-0.011$ bis $0.131$ und schließt 0 ein.
]

Das Beispiel hat zwei Pointen. Erstens erfüllt der Screener die Vier-Fünftel-Regel gerade noch, verletzt aber Equal Opportunity deutlich: Qualifizierte aus Gruppe $b$ werden um 10 Prozentpunkte seltener erkannt. Welches Kriterium gilt, entscheidet über das Urteil. Zweitens ist selbst die Selektionsratendifferenz mit 300 Personen je Gruppe statistisch nicht von null zu unterscheiden. Kleine Audits stützen selten starke Aussagen, weder Alarm noch Entwarnung.

#figure(
  k08-plot(w: 10, h: 3.6, xmin: 0, xmax: 9, ymin: 0, ymax: 1, xticks: (1, 4, 7), xlabels: ([Selektionsrate], [TPR], [FPR]), yticks: (0, 0.2, 0.4, 0.6, 0.8, 1), ylabels: ([0], [0.2], [0.4], [0.6], [0.8], [1]),
    xlabel: [], ylabel: [Rate],
    (X, Y) => {
      import cetz.draw: *
      let data = ((1, 0.30, 0.24, 300), (4, 0.80, 0.70, 100), (7, 0.05, 0.01, 200))
      for (x, va, vb, n) in data {
        for (dx, v, col) in ((-0.45, va, c-blue), (0.45, vb, c-accent)) {
          rect((X(x + dx) - 0.35, Y(0)), (X(x + dx) + 0.35, Y(v)), fill: col.lighten(20%), stroke: none)
          let se = calc.sqrt(v * (1 - v) / n)
          let lo = calc.max(0, v - 1.96 * se)
          let hi = v + 1.96 * se
          line((X(x + dx), Y(lo)), (X(x + dx), Y(hi)), stroke: 0.7pt + c-dark)
          line((X(x + dx) - 0.1, Y(lo)), (X(x + dx) + 0.1, Y(lo)), stroke: 0.7pt + c-dark)
          line((X(x + dx) - 0.1, Y(hi)), (X(x + dx) + 0.1, Y(hi)), stroke: 0.7pt + c-dark)
          content((X(x + dx) + 0.22, Y(v) + 0.04), anchor: "south-west", k08-t(size: 6.5pt)[#str(calc.round(v, digits: 2)).replace(regex("^(\\d\\.\\d)$"), m => m.text + "0")])
        }
      }
      rect((X(8.0), Y(0.92)), (X(8.25), Y(0.97)), fill: c-blue.lighten(20%), stroke: none)
      content((X(8.3), Y(0.945)), anchor: "west", k08-t[$a$])
      rect((X(8.0), Y(0.82)), (X(8.25), Y(0.87)), fill: c-accent.lighten(20%), stroke: none)
      content((X(8.3), Y(0.845)), anchor: "west", k08-t[$b$])
    }),
  caption: [Rechenbeispiel LLM-Screener: Raten je Gruppe mit 95-%-Wald-Intervallen. Die Selektionsraten unterscheiden sich wenig und mit überlappenden Intervallen; die Lücke bei der TPR ist größer, beruht aber auf nur 100 Qualifizierten je Gruppe.],
) <k08-fig-screener>

Wie groß müsste das Audit sein? Für die wahren Selektionsraten 0.30 und 0.24 ist die halbe Intervallbreite $1.96 sqrt((0.21 + 0.1824) \/ n)$. @k08-fig-power zeigt sie zusammen mit der approximativen Teststärke $Phi(0.06 \/ "SE" - 1.96)$ eines zweiseitigen 5-%-Tests: Bei 100 Personen je Gruppe erkennt man die Lücke nur mit 16 % Wahrscheinlichkeit, bei 300 mit 38 %, bei 1000 mit 86 %, erst bei 3000 praktisch sicher. Das Notebook bestätigt den analytischen Standardfehler mit einem stratifizierten Bootstrap (0.0344 gegenüber 0.0362 analytisch).

#figure(
  k08-plot(w: 9, h: 3.4, xmin: 2, xmax: 3.5, ymin: 0, ymax: 1, xticks: (2, 2.477, 3, 3.477), xlabels: ([100], [300], [1000], [3000]), yticks: (0, 0.25, 0.5, 0.75, 1),
    xlabel: [Personen je Gruppe $n$ (log. Skala)], ylabel: [Teststärke / Halbbreite],
    (X, Y) => {
      import cetz.draw: *
      let pts = range(0, 61).map(i => 2 + i * 1.5 / 60)
      let se(n) = calc.sqrt((0.21 + 0.1824) / n)
      let phi(z) = 1 / (1 + calc.exp(-1.702 * z))
      line(..pts.map(l => (X(l), Y(phi(0.06 / se(calc.pow(10, l)) - 1.96)))), stroke: 1.2pt + c-blue)
      line(..pts.map(l => (X(l), Y(calc.min(1, 1.96 * se(calc.pow(10, l)) / 0.06 * 0.5)))), stroke: (paint: c-accent, thickness: 1.1pt, dash: "dashed"))
      line((X(2), Y(0.5)), (X(3.5), Y(0.5)), stroke: (paint: c-grey, thickness: 0.5pt, dash: "dotted"))
      line((9.4, 3.2), (9.9, 3.2), stroke: 1.2pt + c-blue)
      content((10.0, 3.2), anchor: "west", k08-t(fill: c-blue)[Teststärke für $Delta_"DP" = 0.06$])
      line((9.4, 2.75), (9.9, 2.75), stroke: (paint: c-accent, thickness: 1.1pt, dash: "dashed"))
      content((10.0, 2.75), anchor: "west", k08-t(fill: c-accent)[Halbbreite des 95-%-KI \ (0.5 entspricht 0.06)])
    }),
  caption: [Planung eines Screener-Audits. Durchgezogen: approximative Teststärke, eine wahre Differenz der Selektionsraten von 0.06 zu entdecken (logistische Näherung der Normalverteilung). Gestrichelt: halbe Breite des 95-%-Intervalls, so skaliert, dass 0.5 der Effektgröße 0.06 entspricht. Ab etwa 420 Personen je Gruppe ist die Halbbreite kleiner als der Effekt; für 80 % Teststärke braucht es etwa 860.],
) <k08-fig-power>

=== Unvereinbarkeitsresultate

Die zentrale theoretische Einsicht dieses Abschnitts ist, dass sich die Kriterien in realistischen Situationen gegenseitig ausschließen. Barocas, Hardt und Narayanan fassen die Ergebnisse in mehreren Propositionen zusammen @barocas2023fairness: Wenn $A$ und $Y$ abhängig sind, können Unabhängigkeit und Suffizienz nicht zugleich gelten; für binäres $Y$, bei dem weder $A$ noch $R$ unabhängig von $Y$ ist, können Unabhängigkeit und Separation nicht zugleich gelten; und Separation und Suffizienz schließen sich aus, wenn alle Ereignisse positive Wahrscheinlichkeit haben und $A$ von $Y$ abhängt. Kleinberg, Mullainathan und Raghavan haben die Unvereinbarkeit von Kalibrierung und ausgeglichenen Fehlerraten formal bewiesen, Chouldechova hat sie unabhängig am Beispiel der Rückfallprognose gezeigt; erfüllbar sind alle Kriterien nur bei gleichen Basisraten oder perfekter Vorhersage @Kleinberg2017 @Chouldechova2017 @haindl2027research. Zwei dieser Aussagen lassen sich mit wenigen Zeilen elementarer Wahrscheinlichkeitsrechnung beweisen.

#satz(titel: [Unabhängigkeit und Separation])[
  Sei $hat(Y)$ eine binäre Entscheidung, die Separation erfüllt, mit gemeinsamen Raten $"TPR"$ und $"FPR"$ in allen Gruppen. Dann gilt für jede Gruppe
  $ "SR"_a = "FPR" + ("TPR" - "FPR") p_a. $ <k08-eq-sr-basis>
  Unterscheiden sich die Basisraten zweier Gruppen, kann $hat(Y)$ Unabhängigkeit nur erfüllen, wenn $"TPR" = "FPR"$, also wenn die Entscheidung von $Y$ unabhängig und damit nutzlos ist.
]

#beweis[
  Nach dem Satz von der totalen Wahrscheinlichkeit ist $"SR"_a = PP{hat(Y) = 1 | Y = 1, A = a} p_a + PP{hat(Y) = 1 | Y = 0, A = a} (1 - p_a) = "TPR" dot p_a + "FPR" (1 - p_a)$, was @k08-eq-sr-basis ergibt. Gleichheit $"SR"_a = "SR"_b$ bedeutet $("TPR" - "FPR")(p_a - p_b) = 0$. Bei $p_a != p_b$ folgt $"TPR" = "FPR"$, das heißt $PP{hat(Y) = 1 | Y = 1} = PP{hat(Y) = 1 | Y = 0}$ in jeder Gruppe, also $hat(Y) perp Y$.
]

Der zweite Satz verbindet die Fehlerraten mit dem positiven Vorhersagewert $"PPV" = PP{Y = 1 | hat(Y) = 1}$, also mit der binären Form der Suffizienz. Er ist der Kern von Chouldechovas Argument.

#satz(titel: [Fehlerraten, Vorhersagewert und Basisrate])[
  Für jede Gruppe mit Basisrate $p$, $0 < p < 1$, und $"PPV" > 0$ gilt
  $ "FPR" = p / (1 - p) dot (1 - "PPV") / "PPV" dot (1 - "FNR"), $ <k08-eq-chould>
  mit der Falsch-negativ-Rate $"FNR" = 1 - "TPR"$. Haben zwei Gruppen gleichen PPV und gleiche FNR, aber verschiedene Basisraten, so müssen sich ihre FPR unterscheiden.
]

#beweis[
  Sei $m$ die Gruppengröße. Dann gibt es $m p$ Positive, davon $"TP" = m p (1 - "FNR")$ richtig erkannt. Aus $"PPV" = "TP" \/ ("TP" + "FP")$ folgt $"FP" = "TP" (1 - "PPV") \/ "PPV"$. Teilen durch die Anzahl der Negativen $m (1 - p)$ ergibt $"FPR" = p (1 - "FNR")(1 - "PPV") \/ ((1 - p) "PPV")$. Der Faktor $p \/ (1 - p)$ ist streng monoton in $p$; bei festem PPV und FNR folgt aus $p_a != p_b$ also $"FPR"_a != "FPR"_b$, sofern $"PPV" < 1$ und $"FNR" < 1$.
]

#beispiel(titel: [Fehlerraten-Identität am Screener])[
  Im Screener ist $p_a = p_b = 1 \/ 3$, also $p \/ (1 - p) = 0.5$. Gruppe $a$: $"PPV" = 80 \/ 90 = 0.889$, $"FNR" = 0.2$, also $"FPR" = 0.5 dot (0.111 \/ 0.889) dot 0.8 = 0.05$. Gruppe $b$: $"PPV" = 70 \/ 72 = 0.972$, $"FNR" = 0.3$, also $"FPR" = 0.5 dot (2 \/ 70) dot 0.7 = 0.01$. Beides stimmt mit der direkten Rechnung überein.

  Nun eine Variante mit *verschiedenen* Basisraten: $p_a = 0.4$, $p_b = 0.2$, und der Screener sei in beiden Gruppen gleich präzise ($"PPV" = 0.8$) und erkenne gleich viele Qualifizierte ($"FNR" = 0.2$). Dann ist $"FPR"_a = (0.4 \/ 0.6) dot 0.25 dot 0.8 = 0.133$, aber $"FPR"_b = 0.25 dot 0.25 dot 0.8 = 0.05$. Gleiche Präzision und gleiche Trefferquote erzwingen also ungleiche Falsch-positiv-Raten.
]

#figure(
  k08-plot(w: 9, h: 3.6, xmin: 0, xmax: 0.6, ymin: 0, ymax: 0.4, xticks: (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6), yticks: (0, 0.1, 0.2, 0.3, 0.4),
    xlabel: [Basisrate $p$ der Gruppe], ylabel: [erzwungene FPR],
    (X, Y) => {
      import cetz.draw: *
      for (ppv, col, lab, lx) in ((0.7, c-red, [PPV 0.7], 0.5), (0.8, c-blue, [PPV 0.8], 0.55), (0.9, c-teal, [PPV 0.9], 0.55)) {
        let pts = range(1, 61).map(i => i / 100).filter(p => p / (1 - p) * (1 - ppv) / ppv * 0.8 <= 0.4)
        line(..pts.map(p => (X(p), Y(p / (1 - p) * (1 - ppv) / ppv * 0.8))), stroke: 1.1pt + col)
        let lp = pts.last()
        content((X(lp) + 0.08, Y(lp / (1 - lp) * (1 - ppv) / ppv * 0.8)), anchor: "west", k08-t(fill: col, lab))
      }
      for (p, f) in ((0.2, 0.05), (0.4, 0.1333)) {
        circle((X(p), Y(f)), radius: 0.07, fill: c-accent, stroke: none)
      }
      content((X(0.2), Y(0.05) + 0.15), anchor: "south", k08-t(fill: c-accent)[$b$])
      content((X(0.4) - 0.1, Y(0.1333) + 0.1), anchor: "south-east", k08-t(fill: c-accent)[$a$])
    }),
  caption: [Nach @k08-eq-chould erzwungene Falsch-positiv-Rate als Funktion der Basisrate bei fester $"FNR" = 0.2$ für drei Werte des PPV. Wer PPV und FNR über Gruppen gleich hält, muss bei verschiedenen Basisraten verschiedene FPR in Kauf nehmen (Punkte: Variante des Rechenbeispiels).],
) <k08-fig-unvereinbar>

#merke[
  Es gibt keine neutrale, technisch korrekte Definition von Fairness, die man nur finden und optimieren müsste. Die Wahl zwischen Unabhängigkeit, Separation und Suffizienz ist eine ethische und politische Entscheidung darüber, welcher Fehler im jeweiligen Kontext am meisten zählt. Lege offen, welches Kriterium deine Studie verwendet, begründe es mit Blick auf die Anwendung und benenne, was du dafür aufgibst @haindl2027research @barocas2023fairness.
]

=== Nachbearbeitung und ihr Preis

Hardt, Price und Srebro zeigen, dass sich aus jedem Score $R$ allein mit Kenntnis von $(R, A)$ ein abgeleiteter Prädiktor konstruieren lässt, der Equalized Odds oder Equal Opportunity erfüllt, praktisch durch gruppenspezifische (und für Equalized Odds teils randomisierte) Schwellen @hardt2016equality. In ihrer Fallstudie zu FICO-Kreditscores erreichte eine gemeinsame, gruppenblinde Schwelle 99.3 % des maximalen Gewinns (relativ zur unbeschränkten gewinnmaximierenden Lösung mit 100 %), Equal Opportunity 92.8 %, Equalized Odds 80.2 % und Demographic Parity 69.8 % @hardt2016equality.

Das Notebook zeigt denselben Mechanismus auf einem synthetischen Screener mit drei Gruppen, deren Qualifikationsquoten sich unterscheiden (0.45, 0.25, 0.30) und deren Scores für zwei Gruppen nach unten verschoben sind. Mit einer gemeinsamen Schwelle ergeben sich $Delta_"DP" = 0.188$, $"DIR" = 0.537$ und $Delta_"TPR" = 0.130$. Gruppenspezifische Schwellen, die die Selektionsraten angleichen, drücken $Delta_"DP"$ auf praktisch null, lassen aber eine TPR-Lücke von 0.127 bestehen. Schwellen, die die TPR angleichen, schließen die Equal-Opportunity-Lücke (0.003), öffnen aber wieder eine Selektionsratenlücke von 0.092. Die Genauigkeit ändert sich dabei kaum (0.803, 0.793, 0.802). Genau das sagt @k08-eq-sr-basis voraus.

#block(breakable: false)[#datei("fairness.py")[```python
import pandas as pd

def group_rates(df, group="group", y="y_true", yhat="y_pred"):
    g = df.groupby(group)
    sr  = g[yhat].mean()                              # Selektionsrate
    tpr = df[df[y] == 1].groupby(group)[yhat].mean()  # Richtig-positiv-Rate
    fpr = df[df[y] == 0].groupby(group)[yhat].mean()  # Falsch-positiv-Rate
    return pd.DataFrame({"SR": sr, "TPR": tpr, "FPR": fpr})

def fairness_summary(r):
    return {"DP_diff":    r.SR.max() - r.SR.min(),
            "DI_ratio":   r.SR.min() / r.SR.max(),
            "EOpp_diff":  r.TPR.max() - r.TPR.min(),
            "EOdds_diff": max(r.TPR.max() - r.TPR.min(),
                              r.FPR.max() - r.FPR.min())}
```]]

Die Kennzahlen sind in wenigen Zeilen pandas implementiert. Für die Lehre ist das der bessere Weg als eine Bibliothek, weil die Max-min-Aggregation sichtbar bleibt und keine Versionsdrift entsteht; das Notebook prüft die Handrechnung gegen Fairlearn 0.15.0.

#fallstrick[
  Bootstrappe bei zwei Gruppen die *vorzeichenbehaftete* Differenz $"SR"_a - "SR"_b$, nicht die Max-min-Statistik. Diese ist nie negativ, ihr Perzentilintervall kann 0 daher nie enthalten, und bei mehr als zwei Gruppen ist ihre Bootstrap-Verteilung nach oben verzerrt. Berichte vorzeichenbehaftete paarweise Differenzen oder behandle ein Intervall der Max-min-Statistik nur als Beschreibung der Variabilität.
]

#hoersaal([Unser Screener erfüllt die 80-Prozent-Regel. Ist er damit rechtlich und ethisch in Ordnung?],
[Nein, in beiderlei Hinsicht nicht automatisch. Die Regel ist eine Verhältnis-Lockerung des Unabhängigkeitskriteriums @barocas2023fairness und sagt nichts über Fehlerraten: Im Rechenbeispiel liegt das Verhältnis genau bei 0.80, aber Qualifizierte aus Gruppe $b$ werden um 10 Punkte seltener erkannt. Außerdem ist ein Punktwert ohne Unsicherheit wenig wert; das Intervall der Differenz reicht hier von $-0.011$ bis $0.131$. Und der EU AI Act schreibt keine Metrik und keine Schwelle vor, sondern verlangt eine Untersuchung möglicher Verzerrungen und angemessene Maßnahmen (@k08-regulierung).])

#hoersaal([Warum nicht einfach das geschützte Merkmal weglassen? Dann kann das Modell doch nicht diskriminieren.],
[Das ist Fairness durch Unkenntnis @gallegos2024bias, und sie scheitert bei LLMs aus zwei Gründen. Erstens steckt die Gruppenzugehörigkeit in Stellvertretern: Namen, Dialekt, Wohnort, Vereinsmitgliedschaften. Hofmann et al. zeigen, dass schon der Dialekt allein verdeckte Vorurteile auslöst, ohne dass Ethnie je erwähnt wird @hofmann2024ai. Zweitens brauchst du das Merkmal, um Bias überhaupt *messen* zu können; ohne Gruppenzugehörigkeit kannst du keine Rate je Gruppe berechnen. Genau deshalb erlaubt der neue Art. 4a des AI Act unter strengen Bedingungen die Verarbeitung sensibler Daten zur Bias-Erkennung.])

== Kontrafaktische Audits <k08-audits>

Gruppenfairness-Metriken vergleichen *verschiedene* Personen aus verschiedenen Gruppen. Ein Unterschied in den Selektionsraten kann deshalb auch daran liegen, dass sich die Bewerbungen der Gruppen tatsächlich unterscheiden. Kontrafaktische Audits beseitigen dieses Problem durch Konstruktion: Man legt dem System *dieselbe* Eingabe zweimal vor und verändert nur ein Merkmal, das die Gruppe signalisiert. Jeder systematische Unterschied in der Ausgabe ist dann diesem Merkmal zuzuschreiben.

=== Von der Korrespondenzstudie zum LLM-Audit

Das Lehrbuch beschreibt das Design als *Korrespondenz-* oder *gepaartes Audit*: Die Forscherin konstruiert Eingaben, die bis auf ein geschütztes Merkmal identisch sind, etwa zwei Profile, die sich nur in einem ethnisch konnotierten Namen unterscheiden, und vergleicht die Antworten des Systems @haindl2027research. Das ist ein kontrolliertes Experiment mit dem geschützten Merkmal als manipulierter Variable; es erbt dessen Stärke (eine kausale Aussage über ungleiche Behandlung) und dessen Pflichten (Kontrolle von Störgrößen, ausreichende Stichprobe, passende Statistik) @haindl2027research. Algorithmen-Audits dieser Art sind ein eigenes methodisches Teilgebiet mit eigener Ethik @Sandvig2014. Das klassische Vorbild aus der Arbeitsmarktforschung ist die Lebenslaufstudie von Bertrand und Mullainathan, die nach der Zusammenfassung bei Barocas et al. für weiß klingende Namen etwa 50 % mehr Rückrufe fand @barocas2023fairness.

Formal approximiert ein Tauschtest die Invarianz aus @k08-begriffe und die Idee der kontrafaktischen Fairness von Kusner et al. @gallegos2024bias @kusner2017counterfactual:
$ P(hat(Y)_(A <- a)(U) = y | X = x, A = a) = P(hat(Y)_(A <- a')(U) = y | X = x, A = a) $ <k08-eq-cf>
für alle $y$ und alle erreichbaren $a'$. Dabei bezeichnet $hat(Y)_(A <- a')(U)$ die Vorhersage in der kontrafaktischen Welt, in der das Merkmal auf $a'$ gesetzt wird, und $U$ die latenten Hintergrundvariablen eines strukturellen Kausalmodells. Ein Namenstausch ist eine praktische, *nicht kausale* Annäherung: Er greift in einen textuellen Stellvertreter ein, nicht in das Merkmal eines Kausalmodells.

#figure(
  diagram(spacing: (8mm, 5mm), edge-stroke: 0.7pt,
    fknoten((0, 1), [Lebenslauf $i$ \ (Inhalt fix)], col: c-dark, filled: true, w: 24mm),
    fknoten((1, 0), [Name Gruppe A], col: c-blue, w: 24mm),
    fknoten((1, 1), [Name Gruppe B], col: c-accent, w: 24mm),
    fknoten((1, 2), [anderer Name \ Gruppe A (Kontrolle)], col: c-grey, w: 24mm),
    edge((0, 1), (1, 0), "-|>"), edge((0, 1), (1, 1), "-|>"), edge((0, 1), (1, 2), "-|>"),
    fknoten((2, 1), [LLM-Screener \ $times$ mehrere Schablonen \ $times$ Wiederholungen], col: c-violet, filled: true, w: 30mm),
    edge((1, 0), (2, 1), "-|>"), edge((1, 1), (2, 1), "-|>"), edge((1, 2), (2, 1), "-|>"),
    fknoten((3, 0), [A vs. B: \ McNemar, gepaarter $t$], col: c-accent, w: 34mm),
    fknoten((3, 2), [A vs. Kontrolle: \ Rauschboden], col: c-grey, w: 34mm),
    edge((2, 1), (3, 0), "-|>"), edge((2, 1), (3, 2), "-|>"),
  ),
  caption: [Design eines kontrafaktischen Namenstausch-Audits. Jeder Lebenslauf dient als seine eigene Kontrolle; der Tausch innerhalb derselben Gruppe misst, wie stark Entscheidungen schon ohne demografisches Signal schwanken.],
) <k08-fig-audit>

=== Namensbasierte Audits im Recruiting

Das Recruiting ist das am besten untersuchte Anwendungsfeld, und es ist zugleich ein Hochrisikobereich nach EU AI Act (@k08-regulierung). Die Studien unterscheiden sich in Größe, Pipelinestufe und Ergebnisrichtung, was sie zusammen lehrreich macht.

#studie(titel: [An et al. 2024])[
  *Design:* 300 Vornamen (je 50 für weiß, schwarz, hispanisch mal weiblich, männlich), 820 Prompt-Schablonen (4 Qualifikationsniveaus mal 5 Formulierungen mal 41 Rollen, nämlich 40 Berufe und eine unspezifizierte Rolle); Modelle Mistral-7B-Instruct, Llama-2 7B, 13B, 70B und GPT-3.5-Turbo. Die Modelle schreiben Entscheidungs-E-Mails, die ein SVM-Klassifikator (F1 etwa 0.98) als Zu- oder Absage etikettiert. Permutationstests mit 5000 Permutationen, kombiniert nach Fisher. *Befunde:* Max-min-Lücken der Zusagerate von 1.60 (Llama-2-70B) bis 3.78 (GPT-3.5) Prozentpunkten, statistisch signifikant; hispanische männliche Namen in vielen Settings am niedrigsten; die Rangfolge der Gruppen ändert sich mit der Schablone. *Grenzen:* drei Gruppen, binäres Geschlecht, keine asiatischen Namen mangels Namensdaten, keine Lebensläufe @an2024large.
]

#studie(titel: [Armstrong et al. 2024])[
  *Design:* gpt-3.5-turbo-1106; 32 Namen (2 Geschlechter mal 4 ethnische Gruppen mal 4), 10 Berufe. Studie 1: identische Lebensläufe, Bewertung auf 1 bis 100 unter drei Prompts (Rating, Interview, Hiring), je 50 Durchläufe, insgesamt 48 000 Scores. Studie 2: 320 generierte Lebensläufe, manuell codiert. *Befunde:* Unter dem Rating-Prompt bewerteten das Modell weiß konnotierte Namen höher als asiatische ($beta = -1.141$), schwarze ($-0.910$) und hispanische ($-0.752$). Generierte Lebensläufe enthielten für Frauen weniger Berufserfahrung ($beta = -16.260$) und für asiatische und hispanische Namen Hinweise auf Migration ($chi^2(3) = 61.65$ für Sprachangaben). *Grenzen:* kleine Namensmenge, eine Modellversion @armstrong2024silicon.
]

#studie(titel: [An et al. 2025])[
  *Design:* Etwa 361 000 Lebensläufe mit zufällig zugewiesenen Identitäten für Einstiegsjobs, fünf LLMs (GPT-3.5 Turbo, GPT-4o, Gemini 1.5 Flash, Claude 3.5 Sonnet, Llama 3-70b). *Befunde:* Kandidatinnen erhalten höhere, schwarze männliche Kandidaten niedrigere Scores als vergleichbare Kandidaten; an einer Schwelle entspricht das etwa 1 bis 3 Prozentpunkten Unterschied in der Einstellungswahrscheinlichkeit @an2025measuring. Im Preprint (nur GPT-3.5) lagen die Unterschiede bei $-0.303$ (schwarz, männlich) und $+0.452$ (weiblich) Punkten auf einer Skala von 0 bis 100; an einer Schwelle von 80 Punkten bedeutete das $-1.4$ Prozentpunkte für schwarze gegenüber weißen Männern. Die Zahlen der publizierten Fassung können abweichen. *Grenzen:* synthetische Lebensläufe @an2025measuring.
]

Die letzte Studie illustriert einen Mechanismus, den du dir merken solltest: Winzige Score-Unterschiede, Bruchteile eines Punkts auf einer 100-Punkte-Skala, werden zu spürbaren Allokationsunterschieden, sobald eine Schwelle angewendet wird, weil die Schwelle in einen dicht besetzten Bereich der Scoreverteilung fällt.

#studie(titel: [Wilson und Caliskan 2024])[
  *Design:* Retrieval-Stufe: drei Massive-Text-Embedding-Modelle (E5-mistral-7b-instruct, GritLM-7B, SFR-Embedding-Mistral) ordnen 554 Lebensläufe 571 Stellenbeschreibungen in 9 Berufen zu; 120 nach Häufigkeit kontrollierte Namen. *Befunde:* Weiß konnotierte Namen wurden in 85.1 % der Tests bevorzugt (schwarz konnotierte in 8.6 %), männliche in 51.9 % (weibliche in 11.1 %), weiße gegenüber schwarzen männlichen Namen in 100 % der Tests. Bei exakter Angleichung der Namenshäufigkeit kehrte sich das Muster um: schwarz konnotierte Namen in 51.9 %, weiß konnotierte in 22.2 % bevorzugt. *Grenze:* Namenshäufigkeit ist eine starke Störgröße @wilson2024gender.
]

#studie(titel: [Seshadri et al. 2025])[
  *Design:* Zwei Pipelinestufen: Zusammenfassung von Lebensläufen durch sechs generative LLMs (GPT-4o, Command-R, Mixtral 8x7B, Mistral Large, Llama 3.1 8B, Llama 3.3 70B) und Ranking durch vier Einbettungsmodelle; 525 synthetische und 1175 reale Lebensläufe, 154 Stellenanzeigen; Namenstausch (schwarz, weiß mal weiblich, männlich, je 100 Namen) plus Tausch innerhalb der Gruppe und nicht-demografische Änderungen. *Befunde:* Die Zusammenfassungen verletzen die Invarianz unter ethnischem Namenstausch bei allen Modellen außer Command-R (Mixtral 8x7B 16.76 %); Geschlechtstausch fast ohne Effekt. Im Retrieval fallen im Mittel 45.75 % der Top-5 nach einer Änderung heraus; bei embed-english-v3.0 ist die Gruppe weiblich, weiß in 48.05 % der Fälle die bestplatzierte, männlich, schwarz in 3.90 %. Doch auch nicht-demografische Änderungen wie Leerzeichen erzeugen vergleichbare Empfindlichkeit, bei mistral-embed 72.76 % Top-5-Ausschluss. *Grenzen:* Englisch, binäres Geschlecht, zwei ethnische Gruppen, synthetische und schiefe Daten @seshadri2025small.
]

#fallstrick[
  Ohne Kontrollbedingung verwechselst du Sprödigkeit mit Bias. Wenn schon ein Leerzeichen 72.76 % der Top-5 austauscht @seshadri2025small, sagt eine hohe Ausschlussrate nach Namenstausch allein nichts über Diskriminierung. Paare jede demografische Störung mit einer nicht-demografischen: Tausch innerhalb der Gruppe, Tippfehler, Leerzeichen. Bias ist erst die *Differenz* zwischen beiden Bedingungen, und zwar in einer systematischen Richtung.
]

Dass Bias nicht immer die historisch benachteiligte Gruppe trifft, zeigt eine Studie zu Hochschulzulassungen: Auf 30 000 synthetischen Bewerberprofilen und mit 5 Millionen Prompts bevorzugten Qwen 2, Mistral v0.3, Gemma 2 und Llama 3.1 konsistent Bewerber mit niedrigem sozioökonomischem Status, auch bei gleicher akademischer Leistung, und der Modus mit Begründung verstärkte dies @nghiem2025rich. Die *Richtung* eines Bias ist eine empirische Frage, ob sie erwünscht ist, eine normative.

=== Dialekt als verdeckter Auslöser

Die vielleicht wichtigste Audit-Studie der letzten Jahre arbeitet nicht mit Namen, sondern mit Sprache. Hofmann et al. übertragen das sozialpsychologische Matched-Guise-Verfahren auf LLMs: Das Modell sieht einen Text in afroamerikanischem Englisch (AAE) oder in standardisiertem amerikanischem Englisch (SAE) in einer Schablone wie `A person who says " t " tends to be`, und man vergleicht die Wahrscheinlichkeit von Eigenschafts-, Berufs- oder Urteilstoken $x$. Ethnie wird nie erwähnt @hofmann2024ai.

#definition(titel: [Assoziationsscore des Matched Guise Probing])[
  Im bedeutungsgleichen Setting mit Paaren aus AAE-Text $t_a^i$ und seiner SAE-Übersetzung $t_s^i$, Schablone $v$ und $n = |T_a| = |T_s|$:
  $ q(x; v, theta) = 1/n sum_(i = 1)^n log (p(x | v(t_a^i); theta)) / (p(x | v(t_s^i); theta)). $ <k08-eq-mgp>
  Im nicht bedeutungsgleichen Setting mit unabhängigen Stichproben ist
  $ q(x; v, theta) = log (sum_(i = 1)^n p(x | v(t_a^i); theta)) / (sum_(i = 1)^n p(x | v(t_s^i); theta)), $ <k08-eq-mgp2>
  also der Logarithmus des Verhältnisses der mittleren Wahrscheinlichkeiten. Positives $q$ bedeutet stärkere Assoziation von $x$ mit AAE @hofmann2024ai.
]

#block(breakable: false)[#studie(titel: [Hofmann et al. 2024])[
  *Design:* 2019 AAE-Tweets, jeweils gepaart mit einer SAE-Übersetzung, plus nicht gepaarte Stichproben; 12 Modellversionen von GPT-2, RoBERTa, T5, GPT-3.5 und GPT-4. *Befunde:* Die verdeckten Stereotype über AAE-Sprechende sind negativer als jemals erhobene menschliche Stereotype über Afroamerikaner, die offenen dagegen positiver. AAE wird mit Berufen geringeren Prestiges assoziiert ($beta = -7.8$, $R^2 = 0.193$, $F(1, 63) = 15.1$, $P < 0.001$). In hypothetischen Strafprozessen verurteilen die Modelle AAE-Sprechende in 68.7 % der Fälle gegenüber 62.1 % bei SAE ($chi^2(1, N = 96) = 184.7$) und verhängen die Todesstrafe in 27.7 % gegenüber 22.8 % ($chi^2(1, N = 144) = 425.4$), beide $P < 0.001$; der Todesstrafen-Effekt gilt für alle Modelle außer T5. Größere Modelle zeigen weniger offene, aber stärkere verdeckte Vorurteile. Training mit menschlichem Feedback macht die offenen Stereotype günstiger (mittlere Favorabilität 0.221 ohne, 1.047 mit Feedback-Training, $P < 0.001$), hat aber keinen klaren Effekt auf die verdeckten ($P = 0.3$ für Stärke, $P = 0.6$ für Ungünstigkeit). *Grenzen:* hypothetische Entscheidungsaufgaben; Wahrscheinlichkeitszugriff nötig, daher GPT-4 aus mehreren Analysen ausgeschlossen @hofmann2024ai.
]]

#figure(
  balken((([Verurteilung, AAE], 68.7), ([Verurteilung, SAE], 62.1), ([Todesstrafe, AAE], 27.7), ([Todesstrafe, SAE], 22.8)), max: 80, breite: 8, farbe: c-violet, einheit: " %", nachkomma: 1),
  caption: [Matched Guise Probing in hypothetischen Strafprozessen: Anteil der Urteile je Dialekt bei identischem Inhalt (Daten aus @hofmann2024ai). Die Gruppe wird nie genannt, nur der Dialekt variiert.],
) <k08-fig-hofmann>

Hofmanns Design ist die Schablone für jedes kontrafaktische Stellvertreter-Audit: Inhalt konstant halten, nur den Stellvertreter variieren (Dialekt, Name, Pronomen), Ausgabeverteilungen vergleichen. Der Befund zum Feedback-Training ist eine ernste Warnung an alle, die sich auf die Ausrichtung kommerzieller Modelle verlassen: Ausrichtung kann Bias verstecken, statt ihn zu beseitigen.

=== Entscheidungsaufgaben mit Regressionsmodell: discrim-eval

Tamkin et al. haben einen Test für Diskriminierung bei folgenreichen Ja/Nein-Entscheidungen (Finanzierung, Wohnen und Ähnliches) vorgeschlagen @tamkin2023evaluating. 70 Entscheidungsszenarien werden mit 9 Altersstufen, 3 Geschlechtern und 5 ethnischen Gruppen kombiniert, also $70 dot 9 dot 3 dot 5 = 9450$ Prompts, einmal mit explizit genannter Demografie und einmal implizit über Namen @tamkin2023evaluating. Ausgewertet wird mit einem gemischten Modell
$ y = X beta + Z u + epsilon, quad y = op("logit")[p_"norm"("yes")], quad p_"norm"("yes") = (p("yes")) / (p("yes") + p("no")), $ <k08-eq-discrim>
mit festen Effekten $X$ (Alter z-standardisiert, Dummies für Geschlecht und Ethnie), zufälligen Effekten $Z$ für den Fragetyp und Frage-mal-Demografie-Interaktionen und Fehler $epsilon$. Der *Diskriminierungsscore* einer Gruppe ist ihr geschätzter fester Effekt relativ zur Basis (weiß, 60 Jahre, männlich): 0 heißt keine Diskriminierung, negativ Benachteiligung, positiv Bevorzugung @tamkin2023evaluating.

#beispiel(titel: [Diskriminierungsscore auf der Wahrscheinlichkeitsskala])[
  Liegt die Basis bei $p("yes") = 0.5$, also Logit 0, entspricht ein Score von $+1.0$ einer mittleren Wahrscheinlichkeit von $1 \/ (1 + e^(-1)) = 0.731$, wie Tamkin et al. angeben @tamkin2023evaluating. Ein Score von $-0.5$ entspräche $1 \/ (1 + e^(0.5)) = 0.378$. Wegen der Nichtlinearität der logistischen Funktion ist derselbe Score bei einer Basis nahe 0 oder 1 ein kleinerer Unterschied in Prozentpunkten.
]

Der Vorteil gegenüber rohen Annahmequoten liegt darin, dass das Regressionsmodell die unterschiedliche Schwierigkeit der Szenarien ausgleicht und Standardfehler liefert. Für Claude 2.0 fanden die Autoren positive Diskriminierung für nicht weiße und nicht männliche Gruppen relativ zur Basis (stärker bei expliziter Demografie) und negative für Alter über 60; Prompt-Interventionen wie "Diskriminierung ist illegal" oder "Ignoriere die Demografie" senkten die Scores auf etwa 0.15 bei etwa 92 % Korrelation mit den Standardentscheidungen @tamkin2023evaluating. Der Datensatz steht unter CC-BY-4.0 auf Hugging Face (Stand: 11. November 2026). Die Arbeit liegt nur als Preprint vor, und die Autoren befürworten den Einsatz von LLMs für solche Entscheidungen ausdrücklich nicht @tamkin2023evaluating.

=== Implizite Assoziationen in ausgerichteten Modellen

Für Modelle ohne Zugriff auf Einbettungen oder Wahrscheinlichkeiten haben Bai et al. zwei promptbasierte Analoga zum IAT entwickelt @bai2025explicitly. Beim *LLM Word Association Test* ordnet das Modell Attributwörter Gruppenbegriffen zu; der Bias ist
$ "bias" = (N(s_a, X_a)) / (N(s_a, X_a) + N(s_a, X_b)) + (N(s_b, X_b)) / (N(s_b, X_a) + N(s_b, X_b)) - 1, $ <k08-eq-bai>
wobei $N(s, X)$ zählt, wie viele Wörter aus $X$ dem Gruppenbegriff $s$ zugeordnet werden, $s_a, s_b$ Begriffe für die Gruppen $a$ und $b$ (etwa Namen) und $X_a, X_b$ die stereotyp mit $a$ beziehungsweise $b$ assoziierten Attribute sind. Wertebereich $[-1, 1]$, 0 ist unverzerrt. Beim *LLM Relative Decision Test* ordnet das Modell zwei Kandidaten zwei kontrastierenden Optionen zu; eine Entscheidung zählt als diskriminierend, wenn sie dem Stereotyp folgt, und der Mittelwert liegt in $[0, 1]$ mit 0.5 als unverzerrt @bai2025explicitly.

#beispiel(titel: [LLM Word Association Test])[
  Der Name "Emily" (Gruppe $a$) wird 7 von 8 mit $a$ assoziierten Wörtern zugeordnet, der Name "Jamal" (Gruppe $b$) 6 von 8 mit $b$ assoziierten. Dann ist $"bias" = 7 \/ 8 + 6 \/ 8 - 1 = 0.625$. Bei zufälliger Zuordnung wären beide Brüche im Mittel 0.5 und der Bias 0.
]

#studie(titel: [Bai et al. 2025])[
  *Design:* 8 wertausgerichtete Modelle, 4 Kategorien (Ethnie, Geschlecht, Religion, Gesundheit), 21 Stereotype, 33 600 Prompts. *Befunde:* Assoziations-Bias signifikant über 0 ($t(33 thin 599) = 76.39$, $p < 0.001$), Entscheidungs-Bias über 0.5 ($t(26 thin 528) = 36.25$, $p < 0.001$); stereotypkonforme Assoziationen bei 19 von 21 Stereotypen. Die Modelle verweigerten etwa 20 % der Entscheidungsprompts, aber 0 % der Assoziationsprompts. In der GPT-4-Analyse vervielfachte eine Einheit mehr Assoziations-Bias die Chance einer diskriminierenden Entscheidung um etwa 2.68 ($b = 0.986$, 95-%-KI $[0.753, 1.219]$). Relative Entscheidungen (zwei Kandidaten) lösten mehr Bias aus als absolute (ein Profil). Auf Promptebene korrelierte der Assoziations-Bias mit einem einbettungsbasierten Bias mit $r = 0.36$, nach Stereotypen aggregiert mit 0.72 @bai2025explicitly.
]

Lee und Lai übertragen die Idee auf Reasoning-Modelle: Statt der Reaktionszeit des IAT zählen sie die Reasoning-Token in assoziationskompatiblen und -inkompatiblen Sortieraufgaben @lee2025implicit. Vier von fünf Modellen verbrauchten bei inkompatiblen Aufgaben mehr Token (für o3-mini mit $d = 0.53$ bis 1.26 in 9 von 10 Tests, für DeepSeek-R1 $d = 0.12$ bis 0.72 in 8 von 10), Claude 3.7 Sonnet zeigte umgekehrte oder inkonsistente Muster und die höchste Verweigerungsrate (21.33 %) @lee2025implicit. Die Arbeit ist ein Preprint, und die im Text genannte mittlere Tokensteigerung für o3-mini lässt sich aus den Tabellen nicht exakt reproduzieren; sprich vorsichtig von "etwa der Hälfte mehr".

=== Statistik für gepaarte Audits

Ein kontrafaktisches Audit erzeugt *gepaarte* Daten: Für jeden Lebenslauf $i$ liegen zwei Entscheidungen oder zwei Scores vor. Die Auswertung muss diese Paarung nutzen, sonst verschenkt sie den größten Vorteil des Designs. Wir behandeln den Fall binärer Entscheidungen und den Fall stetiger Scores.

*Binäre Entscheidungen: der McNemar-Test.* Für $n$ Lebensläufe ergibt sich eine $2 times 2$-Tafel der gepaarten Entscheidungen (@k08-tab-mcnemar). Die Zellen $a$ und $d$ enthalten die übereinstimmenden Paare, $b$ die Fälle, in denen nur mit dem Namen der Gruppe A eingeladen wurde, und $c$ die umgekehrten.

#figure(
  table(columns: (auto, auto, auto, auto),
    [], [B-Name: eingeladen], [B-Name: nicht eingeladen], [Summe],
    [A-Name: eingeladen], [$a$], [$b$], [$a + b$],
    [A-Name: nicht eingeladen], [$c$], [$d$], [$c + d$],
    [Summe], [$a + c$], [$b + d$], [$n$],
  ),
  caption: [Gepaarte Entscheidungen eines Namenstausch-Audits.],
) <k08-tab-mcnemar>

Die Einladungsquoten sind $(a + b) \/ n$ mit A-Namen und $(a + c) \/ n$ mit B-Namen; ihre Differenz ist $(b - c) \/ n$. Die übereinstimmenden Paare $a$ und $d$ fallen heraus: Sie tragen keine Information über einen Namenseffekt.

#satz(titel: [Exakter McNemar-Test])[
  Unter der Nullhypothese gleicher Einladungswahrscheinlichkeit (marginale Homogenität) und bei unabhängigen Paaren gilt, bedingt auf die Anzahl diskordanter Paare $m = b + c$: $b ~ "Bin"(m, 1\/2)$. Der exakte zweiseitige $p$-Wert ist
  $ p = min(1, 2 sum_(i = 0)^(min(b, c)) binom(m, i) 2^(-m)). $ <k08-eq-mcnemar>
  Für großes $m$ ist $(b - c)^2 \/ (b + c)$ approximativ $chi^2$-verteilt mit einem Freiheitsgrad.
]

#beweis[
  Seien $pi_(10)$ und $pi_(01)$ die Wahrscheinlichkeiten der beiden diskordanten Zellen. Die Differenz der Einladungswahrscheinlichkeiten ist $(pi_(11) + pi_(10)) - (pi_(11) + pi_(01)) = pi_(10) - pi_(01)$, die Nullhypothese also $pi_(10) = pi_(01)$. Gegeben, dass ein Paar diskordant ist, fällt es dann mit Wahrscheinlichkeit $pi_(10) \/ (pi_(10) + pi_(01)) = 1\/2$ in die Zelle $b$. Bei unabhängigen Paaren ist $b$ bedingt auf $m$ binomialverteilt, woraus @k08-eq-mcnemar als zweiseitiger Binomialtest folgt. Die Normalapproximation $z = (b - m\/2) \/ sqrt(m\/4) = (b - c) \/ sqrt(b + c)$ liefert quadriert die $chi^2$-Statistik.
]

#beispiel(titel: [McNemar im Notebook-Audit])[
  Das Notebook simuliert 400 Lebensläufe, jeweils dreimal von einem stochastischen Screener bewertet: mit einem A-Namen, einem B-Namen und einem anderen A-Namen als Kontrolle; der Namenseffekt für B beträgt $-2$ Punkte bei einem Laufrauschen mit Standardabweichung 4.

  *A gegen B:* $b = 41$, $c = 15$, $m = 56$. Exakter Test: $p = 0.00069$. Approximativ: $(41 - 15)^2 \/ 56 = 12.07$, $p = 0.00051$; mit Stetigkeitskorrektur $(|b - c| - 1)^2 \/ m = 11.16$.

  *A gegen Kontrolle:* $b = 27$, $c = 21$, $m = 48$, exakter Test $p = 0.47$.

  Bemerkenswert: Die Flip-Rate (Anteil diskordanter Paare) ist mit 14 % gegenüber 12 % in beiden Bedingungen ähnlich. Der Bias zeigt sich nicht in der Anzahl der Wechsel, sondern in ihrer *Asymmetrie*.
]

#figure(
  k08-plot(w: 10, h: 3.2, xmin: 10, xmax: 46, ymin: 0, ymax: 0.12, xticks: (10, 15, 20, 25, 28, 30, 35, 41, 45), yticks: (0, 0.04, 0.08, 0.12),
    xlabel: [Anzahl $b$ der Paare "nur mit A-Name eingeladen" bei $m = 56$ diskordanten Paaren], ylabel: [Wahrscheinlichkeit],
    (X, Y) => {
      import cetz.draw: *
      for k in range(10, 47) {
        let pr = calc.binom(56, k) / calc.pow(2.0, 56)
        let col = if k >= 41 or k <= 15 { c-accent } else { c-blue.lighten(30%) }
        rect((X(k) - 0.1, Y(0)), (X(k) + 0.1, Y(pr)), fill: col, stroke: none)
      }
      line((X(41), Y(0)), (X(41), Y(0.06)), stroke: (paint: c-accent, thickness: 0.8pt))
      content((X(41), Y(0.062)), anchor: "south", k08-t(fill: c-accent)[beobachtet $b = 41$])
      content((X(12.5), Y(0.03)), anchor: "south", k08-t(fill: c-accent)[$b <= 15$])
    }),
  caption: [Nullverteilung $"Bin"(56, 1\/2)$ des McNemar-Tests im Notebook-Audit. Die orange markierten Ränder ($b <= 15$ oder $b >= 41$) bilden zusammen den zweiseitigen exakten $p$-Wert 0.00069.],
) <k08-fig-mcnemar>

*Stetige Scores: gepaarter $t$-Test und Vorzeichen-Permutation.* Liefert der Screener einen Score (etwa 0 bis 100), analysiert man die Differenzen $d_i = s_i^B - s_i^A$. Der gepaarte $t$-Test verwendet $t = macron(d) \/ (s_d \/ sqrt(n))$ mit $n - 1$ Freiheitsgraden. Robuster ist der *Vorzeichen-Permutationstest*: Unter der Nullhypothese ist jede Differenz symmetrisch um 0 verteilt, also ist jedes Vorzeichenmuster gleich wahrscheinlich. Man zieht zufällige Vorzeichen $epsilon_i in {-1, +1}$, berechnet $1/n sum_i epsilon_i d_i$ und vergleicht mit dem beobachteten Mittel. Im Notebook ergibt sich für B gegen A $macron(d) = -2.017$ Punkte, 95-%-KI $[-2.567, -1.468]$, $t = -7.215$; die Kontrolle liefert $macron(d) = -0.003$ mit $p = 0.99$.

Der Grund für die hohe Teststärke gepaarter Designs ist die Varianz. Für unabhängige Stichproben ist die Varianz der Mittelwertdifferenz $(sigma_A^2 + sigma_B^2) \/ n$, für gepaarte $(sigma_A^2 + sigma_B^2 - 2 rho sigma_A sigma_B) \/ n$. Weil derselbe Lebenslauf zweimal bewertet wird, ist die Korrelation $rho$ hoch: Im Notebook stammt der Großteil der Scorevarianz aus der Qualität des Lebenslaufs (Standardabweichung 12), nur ein kleiner Teil aus dem Laufrauschen (4). Die Paarung entfernt den ersten Anteil vollständig.

#block(breakable: false)[#datei("mcnemar.py")[```python
import math
import numpy as np

def mcnemar_exact(dec_1, dec_2):
    """Exakter zweiseitiger McNemar-Test für gepaarte 0/1-Entscheidungen."""
    b = int(np.sum((dec_1 == 1) & (dec_2 == 0)))
    c = int(np.sum((dec_1 == 0) & (dec_2 == 1)))
    m = b + c
    if m == 0:
        return b, c, 1.0
    tail = sum(math.comb(m, i) for i in range(min(b, c) + 1)) / 2**m
    return b, c, min(1.0, 2 * tail)

def sign_flip_test(x, y, n_perm=5000, seed=0):
    d = np.asarray(y) - np.asarray(x)
    signs = np.random.default_rng(seed).choice([-1, 1], size=(n_perm, len(d)))
    null = (signs * d).mean(axis=1)
    return (1 + np.sum(np.abs(null) >= abs(d.mean()))) / (n_perm + 1)
```]]

*Schablonen als Zufallsfaktor und multiples Testen.* Zwei weitere Probleme machen aus einem sauberen Einzeltest ein schwieriges Gesamturteil. Erstens die Promptabhängigkeit: Bei An et al. ändert sich die Rangfolge der Gruppen mit der Schablone @an2024large, bei Bai et al. lösen relative Formate mehr Bias aus als absolute @bai2025explicitly, und Röttger et al. zeigen Positionswechsel unter Paraphrase @rottger2024political. Eine Bias-Schätzung aus einer einzigen Schablone hat unbekannte Reliabilität. Die Abhilfe ist, Schablonen als Zufallsfaktor zu behandeln: mehrere Schablonen verwenden, die Varianz zwischen ihnen berichten und den Effekt mit einem gemischten Modell schätzen, wie es discrim-eval für Fragetypen tut @tamkin2023evaluating. Zweitens multiples Testen: Wer sechs Gruppen paarweise und über mehrere Modelle vergleicht, findet bei $alpha = 0.05$ fast sicher irgendwo einen "signifikanten" Unterschied. Seshadri et al. korrigieren deshalb nach Benjamini-Hochberg @seshadri2025small. Da die Lücken in LLM-Recruiting-Audits oft nur wenige Prozentpunkte betragen (1.60 bis 3.78 Punkte bei An et al. @an2024large), brauchen solche Audits große Stichproben; unterdimensionierte Audits erzeugen falschen Alarm ebenso wie falsche Entwarnung.

#tipp[
  Audit-Rezept für eine Abschlussarbeit: mindestens 50 Namen je Gruppe, mindestens drei Schablonen, eine Kontrollbedingung mit Tausch innerhalb der Gruppe, Permutations- oder McNemar-Test, Konfidenzintervalle, Varianz über Schablonen und eine Korrektur für multiples Testen. Fixiere Modellversion, Temperatur und Datum. Das Notebook enthält einen ausgeschalteten Live-Modus für ein lokales Modell; mit 12 gepaarten Entscheidungen ist er ein Rauchtest der Pipeline, kein Audit.
]

Für teure Black-Box-Modelle lohnt sich ein Blick auf aktive Audits. Hartmann et al. formulieren das Audit als Schätzung eines Unsicherheitsintervalls für eine Fairnessmetrik (etwa $Delta"AUC"$ zwischen Gruppen) und wählen Anfragen gezielt aus einem Versionsraum von Surrogatmodellen aus; auf CivilComments benötigte ihr Verfahren BAFA bei $epsilon = 0.02$ 144 statt 5956 Anfragen (bis zu 40-mal weniger als stratifiziertes Sampling) @hartmann2026audit. Das verbindet Bias-Audits mit den Inferenzverfahren aus Kapitel 6.

#hoersaal([Namen signalisieren doch mehr als Ethnie, etwa sozialen Status oder Alter. Ist ein Namenstausch dann überhaupt ein valides Experiment?],
[Die Kritik ist berechtigt und alt: Schon für menschliche Korrespondenzstudien weisen Barocas et al. darauf hin, dass Namen mehr als Ethnie signalisieren und dass ein Merkmalstausch nicht immer ein sinnvolles Kontrafaktum erzeugt @barocas2023fairness. Bei LLMs kommt die Namenshäufigkeit hinzu: Wilson und Caliskan fanden eine Umkehr ihres Befunds, sobald die Häufigkeit exakt angeglichen wurde @wilson2024gender. Das Experiment bleibt valide für die Aussage "das System behandelt Profile mit Name X anders als mit Name Y". Problematisch wird erst der Schluss auf "Ethnie" als Ursache. Gute Audits kontrollieren deshalb Häufigkeit, verwenden viele Namen je Gruppe und formulieren ihre Aussage auf der Ebene des Stellvertreters.])

== Validität der Messung: biased rulers <k08-validitaet>

Bis hierher haben wir Metriken definiert und berechnet. Ob die Zahlen etwas bedeuten, ist eine andere Frage. Die methodische Literatur der letzten fünf Jahre hat sich weg von neuen Benchmarks und hin zur Prüfung der Messung selbst bewegt @delobelle2024metrics @harvey2025understanding. Für dich als Methodiker ist das der vertrauteste Teil des Kapitels, denn hier gelten die Begriffe aus Kapitel 1: Konstrukt, Operationalisierung, Reliabilität, Validität.

=== Bias-Benchmarks als Messmodelle

Blodgett et al. fassen einen Bias-Benchmark als *Messmodell* auf, das ein nicht beobachtbares Konstrukt (etwa Stereotypisierung) aus beobachtbaren Eigenschaften erschließt @blodgett2021stereotyping. Man muss die *Konzeptualisierung* des Konstrukts von seiner *Operationalisierung* (Testfälle plus aggregierende Metrik) trennen und für beide fragen, ob sie klar formuliert, valide und reliabel sind (@k08-fig-messmodell).

#figure(
  align(center, diagram(spacing: (4mm, 7mm), edge-stroke: 0.7pt,
    fknoten((0, 0), [Schaden \ (für wen, warum?)], col: c-red, w: 34mm),
    fknoten((1, 0), [Konstrukt \ z. B. Stereotypisierung], col: c-violet, filled: true, w: 36mm),
    fknoten((2, 0), [Operationalisierung \ Testfälle + Metrik], col: c-blue, filled: true, w: 36mm),
    fknoten((3, 0), [Score \ z. B. ss = 60.1], col: c-dark, filled: true, w: 30mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"),
    fknoten((1, 1), [*Konzeptualisierung:* Machtverhältnisse, sinnlose Stereotype, Anti- vs. Nicht-Stereotyp], col: c-grey, w: 36mm),
    fknoten((2, 1), [*Operationalisierung:* ungültige Störungen, unvergleichbare Gruppen, unnatürlicher Text], col: c-grey, w: 36mm),
    edge((1, 0), (1, 1), "--", stroke: 0.5pt + c-grey), edge((2, 0), (2, 1), "--", stroke: 0.5pt + c-grey),
  )) + v(4pt) + block(width: 92%, fill: c-accent.lighten(88%), stroke: 0.8pt + c-accent, radius: 3pt, inset: 6pt,
    align(center, text(font: "Inter", size: 7.8pt)[*Validitätsevidenz:* prädiktiv (sagt der Score Verhalten in der Anwendung voraus?), ökologisch (realistische Sprache?), konsequenziell (schadet die Messung selbst?)])),
  caption: [Bias-Messung als Messmodell nach Blodgett et al. mit den Validitätstypen nach Goldfarb-Tarrant et al. @blodgett2021stereotyping @goldfarbtarrant2023prompt.],
) <k08-fig-messmodell>

#studie(titel: [Blodgett et al. 2021 ("Stereotyping Norwegian Salmon")])[
  *Design:* Inventar von Fallstricken in vier Fairness-Benchmarks (StereoSet, CrowS-Pairs, WinoBias, Winogender); etwa 100 zufällig gezogene Tests je Datensatz (120 für Winogender), annotiert von vier Autorinnen und Autoren. *Befunde:* Fallstricke der Konzeptualisierung (Machtverhältnisse ignoriert, bedeutungslose Stereotype, Verwechslung von Anti- und Nicht-Stereotyp, unpassende Stereotype) und der Operationalisierung (ungültige Störungen, unvergleichbare Gruppen, logische Fehler, unnatürlicher Text, ungleiche Basislinien). Hinzu kommen Probleme auf Ebene von Datensatz und Metrik: Gleichgewichtung der Paare, Aggregationsannahmen, fehlende Signifikanztests. *Grenzen:* Annotation durch die Autoren, stichprobenbasiert @blodgett2021stereotyping.
]

#figure(
  balken((([Winogender], 58), ([WinoBias-Syntax], 38), ([WinoBias-Knowledge], 22), ([StereoSet intra], 6), ([CrowS-Pairs], 3), ([StereoSet inter], 0)), max: 100, breite: 8, farbe: c-teal, einheit: " %", nachkomma: 0),
  caption: [Anteil der stichprobenartig geprüften Testfälle ohne jeden Fallstrick je Benchmark (Daten aus @blodgett2021stereotyping, Tabelle 1).],
) <k08-fig-blodgett>

Der Titel der Arbeit verweist auf ein reales Testpaar, in dem "norwegischer Lachs" als Gruppe stereotypisiert wird, ein Beispiel für ein bedeutungsloses Stereotyp. Die Zahlen in @k08-fig-blodgett sind ernüchternd: Bei StereoSet und CrowS-Pairs ist praktisch jedes geprüfte Item fehlerhaft. Das macht die Benchmarks nicht wertlos, aber es verbietet, Unterschiede von wenigen Punkten zwischen Modellen als Befund zu verkaufen.

=== Intrinsisch ist nicht extrinsisch

Die zweite große Validitätsfrage betrifft die prädiktive Validität: Sagt eine Bias-Metrik das Verhalten in der Anwendung voraus?

#studie(titel: [Goldfarb-Tarrant et al. 2021])[
  *Design:* Hunderte trainierte Modelle über Aufgaben und Sprachen; Vergleich von einbettungsbasierten (intrinsischen) mit Anwendungsmetriken (extrinsischen). *Befund:* "Keine verlässliche Korrelation zwischen diesen Metriken, die in allen Szenarien über Aufgaben und Sprachen hinweg hält"; Empfehlung, extrinsische Messungen zu priorisieren; Veröffentlichung eines Testsets für Gender-Bias bei Hassrede-Erkennung. *Grenze:* vor der LLM-Ära (statische und kontextuelle Einbettungen) @goldfarbtarrant2021intrinsic.
]

#studie(titel: [Delobelle et al. 2022 ("Measuring Fairness with Biased Rulers")])[
  *Design:* Katalog von 13 intrinsischen Maßen; Korrelation intrinsischer Metriken mit drei extrinsischen (BiasInBios, WinoBias, Skew) auf Modellen der BERT-Familie. *Befunde:* Die Metriken sind oft unvereinbar und hängen stark von Schablonen, Seed-Wörtern und der Wahl der Einbettung ab; "keine greifbare Evidenz", dass intrinsischer mit extrinsischem Bias zusammenhängt. Empfehlung: einbettungsbasierte Metriken vermeiden, stattdessen eine Mischung nicht-einbettungsbasierter intrinsischer Maße plus nachgelagerte Evaluation @delobelle2022measuring.
]

Für LLMs haben Lum et al. diese Lücke 2025 bestätigt. Sie verglichen drei Next-Word-Metriken für Geschlecht-Beruf-Bias ("Trick-Tests" mit Ein-Wort-Ausgaben) mit Messungen in drei realistischen Kontexten (Gute-Nacht-Geschichten für Kinder, Nutzerpersonas, Englisch-Übungen) und fanden keinen bedeutsamen statistischen Zusammenhang; das am wenigsten verzerrte Modell nach Trick-Tests auszuwählen war ungefähr so verlässlich wie Zufall @lum2025bias. Das Gegenargument liefern Bai et al.: Innerhalb der GPT-4-Analysen sagte promptbasierter Assoziations-Bias diskriminierende Entscheidungen voraus (Chancenverhältnis etwa 2.68) @bai2025explicitly. Die Versöhnung: Assoziationsmaße können innerhalb einer Modellfamilie und für relative Entscheidungen informativ sein, ersetzen aber nicht die Messung der Entscheidung selbst.

#merke[
  Miss Bias dort, wo die Entscheidung fällt. Eine intrinsische Metrik ist höchstens ein Frühwarnsignal; als Beleg für die Fairness einer Pipeline taugt sie nicht @goldfarbtarrant2021intrinsic @delobelle2022measuring @lum2025bias.
]

=== Was Bias-Tests zu messen vorgeben

Goldfarb-Tarrant et al. haben 90 promptbasierte Bias-Tests aus 77 Arbeiten danach annotiert, was sie messen wollen und wie @goldfarbtarrant2023prompt. Das gewünschte Ergebnis war in 22 % der Tests unklar; 68 % testeten nur vorgelagerte Sprachmodelle; 82 % nutzten ausschließlich Identitätsbegriffe, Pronomen oder Namen als Stellvertreter; 71 % begründeten die demografischen Begriffe nicht; 87 % waren nur auf Englisch; 42 % testeten nur ein Modell @goldfarbtarrant2023prompt. Ihre Empfehlungen: das gewünschte Ergebnis und seinen Bezug zum Schaden angeben, Stellvertreter begründen und prädiktive, ökologische und konsequenzielle Validität prüfen @goldfarbtarrant2023prompt.

Delobelle et al. führen 2024 den Begriff der *Handlungsrelevanz* (_actionability_) ein: der Grad, in dem die Ergebnisse eines Maßes informierte Handlungen ermöglichen @delobelle2024metrics. Die fünf Desiderata sind Motivation, zugrunde liegendes Bias-Konstrukt, Wertebereich und Idealwert, beabsichtigte Verwendung und Reliabilität. In 146 untersuchten Arbeiten fehlte bei 20 % eine klare Motivation, bei 25 % eine verständliche Konstruktdefinition, und 24 % vermischten Konstrukt und Operationalisierung, oft indem sie Bias über WEAT definierten. 77 % nannten einen Idealwert, aber nur 32 % davon interpretierten ihn; 47 % nannten keine beabsichtigte Verwendung; nur 28 Arbeiten diskutierten überhaupt einen Aspekt der Reliabilität @delobelle2024metrics.

#figure(
  table(columns: (auto, 1fr),
    [Abschnitt], [Inhalt],
    [Motivation], [Welcher Schaden, für wen, in welcher Anwendung?],
    [Konstrukt], [Was genau ist mit "Bias" gemeint (Stereotypisierung, ungleiche Fehlerraten, ...)?],
    [Operationalisierung], [Stellvertreter (Namen, Dialekt, Begriffe) mit Begründung, Schablonen, Metrik, Idealwert mit Begründung],
    [Beabsichtigte Verwendung], [Modellauswahl, Monitoring, Freigabe; Geltungsbereich (Sprache, Gruppen)],
    [Reliabilität], [Varianz über Schablonen und Paraphrasen, Seeds, Modellversion, Datum],
    [Validitätsevidenz], [prädiktiv, ökologisch, konsequenziell],
    [Unsicherheit], [Konfidenzintervalle, Korrektur für multiples Testen, Teststärke],
  ),
  caption: [Berichtsschema für Bias-Audits, abgeleitet aus den Desiderata von Delobelle et al. und den Empfehlungen von Goldfarb-Tarrant et al. @delobelle2024metrics @goldfarbtarrant2023prompt.],
) <k08-tab-bericht>

Eine qualitative Studie mit 12 Praktikerinnen und Praktikern ergänzt das Bild: Öffentliche Instrumente zur Messung repräsentationaler Schäden sind in der Praxis oft unbrauchbar, weil sie nicht messen, was gebraucht wird, oder wegen praktischer und institutioneller Hürden @harvey2025understanding. Die Konsequenz für Forschungsarbeiten: Bias-Tests aus dem konkreten Anwendungsfall ableiten, statt einen Standardbenchmark zu übernehmen.

#hoersaal([Wenn fast alle Benchmark-Items fehlerhaft sind, warum werden StereoSet und CrowS-Pairs dann noch in Modellkarten berichtet?],
[Weil sie billig, bekannt und vergleichbar sind, und weil Vergleichbarkeit mit Validität verwechselt wird. Ein Benchmark kann als grobes Warnsignal dienen, wenn ein Modell extrem auffällt. Für feine Rangordnungen zwischen Modellen fehlt ihm die Messqualität @blodgett2021stereotyping, und für Aussagen über Anwendungen fehlt die prädiktive Validität @lum2025bias. Wer in einer Arbeit solche Zahlen berichtet, sollte die Fallstricke benennen und eine anwendungsnahe Messung danebenstellen.])

== LLM-Annotatoren und LLM-Judges als Bias-Quelle <k08-komponenten>

Bisher war das LLM der Untersuchungsgegenstand. In deiner Forschung ist es oft das Instrument: Es annotiert Daten (Kapitel 5) oder bewertet Ausgaben anderer Systeme (Kapitel 7). Dann wird sein Bias zum Bias deiner Ergebnisse, und zwar unsichtbar, solange du ihn nicht eigens prüfst.

=== Identitätshinweise und LLM-Judges

Ye et al. haben im Rahmen von CALM zwölf Bias-Arten von LLM-Judges systematisch quantifiziert, darunter Position, Länge, Autorität, Sentiment und "Diversität", also eingefügte Identitätshinweise @ye2024justice. Ihre zwei Kennzahlen sind einfach:
$ "RR" = 1/(|D|) sum_i I(y_i = hat(y)_i), quad "CR" = 1/(|D|) sum_i I(y_i = y_i^"rand"). $ <k08-eq-rrcr>
Die *Robustheitsrate* RR vergleicht das ursprüngliche Urteil $y_i$ mit dem Urteil $hat(y)_i$ nach Einfügen eines Bias-Auslösers (etwa "Als geflüchtete Frau ..."), die *Konsistenzrate* CR vergleicht zwei ungestörte Läufe und ist damit der Rauschboden @ye2024justice. Für Identitätshinweise lag RR zwischen 0.679 (ChatGPT) und 0.914 (Claude-3.5) @ye2024justice.

#fallstrick[
  RR allein ist kein Bias-Maß. Ein Judge, der bei Temperatur 0.7 schon ohne jede Störung 12 % seiner Urteile ändert, hat $"CR" = 0.88$, und eine RR von 0.86 ist dann kaum auffällig. Interpretiere RR immer relativ zu CR; erst eine RR deutlich unter der CR zeigt Empfindlichkeit für den eingefügten Hinweis. Das ist dieselbe Logik wie die Kontrollbedingung im Namenstausch-Audit; im Notebook ergeben sich genau diese Werte ($"RR" = 0.86$, $"CR" = 0.88$), und erst der McNemar-Test zeigt die Asymmetrie.
]

Eine zweite Form des Judge-Bias betrifft die Herkunft eines Textes. Laurito et al. legten LLMs Paare von Beschreibungen desselben Objekts vor, eine von Menschen, eine von einem LLM geschrieben, in beiden Reihenfolgen @laurito2025ai. Die LLMs zeigten eine konsistente Tendenz, die LLM-geschriebene Option zu bevorzugen; bei Produktbeschreibungen von GPT-4 wählten LLM-Selektoren sie in 89 % der Fälle, menschliche Bewertende in einer kleinen Pilotstudie nur in 36 % @laurito2025ai. Qualitätssignale können die Autoren nicht ausschließen. Für LLM-gestützte Begutachtung, Screening oder Ranking heißt das: Maschinell unterstützte Einreichungen haben einen strukturellen Vorteil.

=== Persona-Prompting von Annotatoren

Eine verbreitete Idee ist, LLM-Annotatoren über eine Persona ("Du bist eine 45-jährige schwarze Frau") die Perspektive bestimmter Gruppen einnehmen zu lassen. Die Evidenz dagegen ist deutlich.

#studie(titel: [Giorgi et al. 2025])[
  *Design:* Measuring-Hate-Speech-Korpus mit etwa 135.6 Tausend Labels von 8472 Annotierenden zu 39 565 Beiträgen; Llama-3-8B-Instruct, Phi-3-mini, SOLAR-10.7B (Hauptanalyse) und Starling-LM-7B mit Persona-Prompts. *Befunde:* Bei Menschen zeigen 46 % der 1950 Kombinationen aus Annotierenden- und Zielgruppe signifikanten Bias, beim Persona-LLM nur 3.33 %; die Bias-Intensitäten von LLM und Menschen sind unkorreliert ($r = -0.105$), die Prävalenzen korrelieren mit $r = 0.491$. *Grenzen:* ein Korpus, nur Persona-Prompting @giorgi2025human.
]

Orlikowski et al. zeigen auf fünf subjektiven Annotationsaufgaben, dass auch Feinabstimmung daran wenig ändert: Die Gewinne stammen vor allem aus dem Lernen des Verhaltens einzelner Annotierender, die Modelle lernen "wenig bedeutsame Verbindung zwischen Soziodemografie und Annotation" @orlikowski2025beyond. Und ohne jede demografische Bedingung ist ein LLM-Judge nicht neutral: Bei 23 offenen Modellen stimmten unbedingte Urteile am besten mit weißen, akademisch gebildeten Annotierenden überein; demografische Bedingung half 10 von 11 Basismodellen, aber nur 5 von 12 Instruktionsmodellen und verschlechterte bei Offensivität die Übereinstimmung mit schwarzen Annotierenden ($-0.074$) @occhipinti2026llm. Diese Arbeit ist ein Preprint.

#figure(
  diagram(spacing: (4mm, 6mm), edge-stroke: 0.7pt,
    fknoten((0, 0), [1. Goldstandard mit \ Gruppenmerkmal], col: c-blue, w: 34mm),
    fknoten((1, 0), [2. Fehlerraten und \ Kappa je Gruppe], col: c-blue, w: 34mm),
    fknoten((2, 0), [3. Tausch (RR) und \ Wiederholung (CR)], col: c-blue, w: 36mm),
    fknoten((3, 0), [4. Herkunftstausch \ Mensch / LLM], col: c-blue, w: 34mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"),
    fknoten((1.5, 1), [5. Entscheidung: für Gruppenvergleiche freigeben, \ mit Korrektur nutzen (Kapitel 6) oder ersetzen], col: c-accent, filled: true, w: 90mm),
    edge((3, 0), (1.5, 1), "-|>", bend: 15deg),
  ),
  caption: [Prüfprotokoll für LLM-Annotatoren und -Judges, bevor ihre Ausgaben in Gruppenvergleiche eingehen.],
) <k08-fig-protokoll>

#praxis[
  In einer Studie, die mit einem LLM-Annotator Hassrede in Kommentaren verschiedener Communities vergleicht, ist der Gruppenunterschied in den Labels die Zielgröße. Ist die Falsch-positiv-Rate des Annotators für eine Community höher, misst die Studie zum Teil den Annotator. Eine Goldstandard-Stichprobe *je Gruppe* ist deshalb Pflicht; mit ihr lässt sich der differenzielle Fehler nicht nur feststellen, sondern mit den Verfahren aus Kapitel 6 auch korrigieren.
]

#hoersaal([Dürfen wir Persona-LLMs als Ersatz für unterrepräsentierte Annotierendengruppen verwenden, wenn wir keine echten Personen finden?],
[Nach heutigem Stand nein, jedenfalls nicht mit dem Anspruch, deren Perspektive abzubilden. Persona-LLMs reproduzieren kaum die gruppenspezifischen Muster echter Annotierender @giorgi2025human, Feinabstimmung lernt eher Individuen als Gruppen @orlikowski2025beyond, und demografische Bedingung kann die Übereinstimmung mit Minderheitengruppen sogar verschlechtern @occhipinti2026llm. Wer es dennoch tut, muss das als Limitation benennen und darf die Ergebnisse nicht als Gruppenperspektive interpretieren.])

== Regulierung: EU AI Act und Digital Omnibus <k08-regulierung>

Für Hochrisiko-Anwendungen wird die Bias-Untersuchung zur Rechtspflicht. Die folgenden Angaben haben den Stand 11. November 2026 und sind vor jedem Einsatz in der Lehre erneut zu prüfen.

=== Artikel 10: Daten-Governance

Grundlage ist die Verordnung (EU) 2024/1689 vom 13. Juni 2024, veröffentlicht im Amtsblatt am 12. Juli 2024 @eu2024regulation. Artikel 10 regelt die Daten-Governance für Hochrisiko-KI-Systeme. Nach Absatz 2 Buchstabe f unterliegen Trainings-, Validierungs- und Testdatensätze einer Untersuchung im Hinblick auf mögliche Verzerrungen, die die Gesundheit und Sicherheit von Personen beeinträchtigen, sich negativ auf Grundrechte auswirken oder zu einer nach Unionsrecht verbotenen Diskriminierung führen können, insbesondere wenn Ausgaben künftige Eingaben beeinflussen. Buchstabe g verlangt geeignete Maßnahmen, um die so identifizierten Verzerrungen zu erkennen, zu verhindern und abzuschwächen @eu2024regulation. Nach Absatz 3 müssen die Datensätze relevant, hinreichend repräsentativ und so weit wie möglich fehlerfrei und vollständig sein @eu2024regulation.

Bemerkenswert ist, was Artikel 10 *nicht* sagt: Er nennt keine Metrik und keine Schwelle. Demographic Parity, Equalized Odds oder eine Vier-Fünftel-Regel sind technische Entscheidungen des Anbieters, die im Lichte der Unvereinbarkeitsresultate begründet werden müssen.

=== Der Digital Omnibus

Die Verordnung (EU) 2026/1744 vom 8. Juli 2026 (Digital Omnibus on AI) wurde am 24. Juli 2026 im Amtsblatt veröffentlicht und trat am 27. Juli 2026 in Kraft @eu2026regulation. Für Bias-Messung sind drei Änderungen wichtig.

- *Sensible Daten zur Bias-Erkennung:* Artikel 10 Absatz 5 wird gestrichen und durch einen neuen Artikel 4a ersetzt. Nach Absatz 1 dürfen Anbieter von Hochrisikosystemen ausnahmsweise besondere Kategorien personenbezogener Daten verarbeiten, soweit dies für Erkennung und Korrektur von Verzerrungen nach Art. 10 Abs. 2 lit. f und g unbedingt erforderlich ist, unter den Bedingungen (a) bis (f): andere Daten, auch synthetische oder anonymisierte, würden nicht genügen; technische Beschränkungen der Weiterverwendung und Sicherheitsmaßnahmen nach dem Stand der Technik wie Pseudonymisierung; strenge, dokumentierte Zugriffskontrollen; keine Übermittlung an Dritte; Löschung, sobald die Verzerrung korrigiert ist oder die Speicherfrist endet; Aufzeichnungen zur Begründung der Erforderlichkeit @eu2026regulation. Absatz 2 erstreckt diese Ausnahme auf Anbieter und Betreiber anderer KI-Systeme und -Modelle sowie auf Betreiber von Hochrisikosystemen, ohne eine Pflicht zur Bias-Erkennung zu begründen @eu2026regulation.
- *Geltungsbeginn:* Der geänderte Art. 113 lässt die Kapitel I und II ab 2. Februar 2025 gelten, neue Verbote in Art. 5 ab 2. Dezember 2026. Die Hochrisiko-Anforderungen von Kapitel III Abschnitte 1 bis 3, einschließlich Artikel 10, gelten ab *2. Dezember 2027* für Systeme nach Anhang III (Art. 6 Abs. 2) und ab *2. August 2028* für Produktsysteme nach Anhang I (Art. 6 Abs. 1). Erwägungsgrund 40 belässt den 2. August 2026 als allgemeines Datum und begründet die Verschiebung mit verzögerten Normen, Leitlinien und nationalen Behörden @eu2026regulation.
- *KI-Kompetenz:* Artikel 4 wurde von einer Pflicht, KI-Kompetenz sicherzustellen, in eine Pflicht umgeschrieben, Maßnahmen zu ihrer Förderung zu treffen, ohne ein bestimmtes Niveau zu garantieren @eu2026regulation (dazu Kapitel 10).

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let w = 14.8
    // maßstäblich: x = 0.3 + Tage seit 13.6.2024 * 13.9 / 1511 (1511 Tage bis 2.8.2028)
    let X(t) = 0.3 + t * 13.9 / 1511
    rect((X(1267), -0.06), (w - 0.2, 0.06), fill: c-accent.lighten(60%), stroke: none)
    line((0, 0), (w, 0), stroke: 1.2pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.6))
    // (Tag, Beschriftungs-x, Datum, Text, Farbe, Seite)
    let ev = (
      (0, 0.9, [13.6.2024], [VO 2024/1689 \ erlassen], c-blue, 1),
      (234, X(234), [2.2.2025], [Kapitel I-II \ gelten], c-blue, -1),
      (755, 6.35, [8.7.2026], [Digital Omnibus \ VO 2026/1744], c-violet, 1),
      (774, 6.55, [27.7.2026], [Omnibus in Kraft \ (ABl. 24.7.)], c-violet, -1),
      (902, 8.75, [2.12.2026], [neue Verbote \ Art. 5], c-blue, 1),
      (931, 9.35, [31.12.2026], [Ende Perspective \ API (kein Recht)], c-grey, -1),
      (1267, X(1267), [2.12.2027], [Art. 10 gilt für \ Anhang III (z. B. \ CV-Screening)], c-accent, 1),
      (1511, 13.85, [2.8.2028], [Art. 10 gilt für \ Anhang I], c-accent, -1),
    )
    for (t, lx, d, lab, col, side) in ev {
      let x = X(t)
      line((x, side * 0.13), (x, side * 0.32), (lx, side * 0.55), stroke: 0.5pt + col)
      circle((x, 0), radius: 0.09, fill: col, stroke: white + 0.7pt)
      content((lx, side * 0.6), anchor: if side > 0 { "south" } else { "north" },
        align(center, text(font: "Inter", size: 6.6pt, fill: col.darken(15%))[#text(weight: "bold", d) \ #lab]))
    }
    // Jahresskala
    let yb = -1.85
    line((0, yb), (w - 0.3, yb), stroke: 0.5pt + c-grey)
    for t in (0, 202, 567, 932, 1297, 1511) {
      line((X(t), yb - 0.08), (X(t), yb + 0.08), stroke: 0.5pt + c-grey)
    }
    for (a, b, j) in ((0, 202, [2024]), (202, 567, [2025]), (567, 932, [2026]), (932, 1297, [2027]), (1297, 1511, [2028])) {
      content(((X(a) + X(b)) / 2, yb - 0.1), anchor: "north", text(font: "Inter", size: 6.4pt, fill: c-grey.darken(10%), j))
    }
  }),
  caption: [Maßstäblicher Zeitstrahl der für Bias-Messung relevanten Daten des EU AI Act in der Fassung des Digital Omnibus (Stand: 11. November 2026) @eu2024regulation @eu2026regulation. Die Punkte liegen taggenau auf der Achse, die Beschriftungen sind bei eng beieinanderliegenden Daten seitlich versetzt; unten die Jahresskala. Orange hinterlegt: Geltung von Art. 10 für Anhang-III-Systeme. Grau: das Ende der Perspective API als Infrastruktur-Termin, kein Rechtsdatum @hartmann2026bye.],
) <k08-fig-zeitstrahl>

=== Ein Fall: der LLM-Screener als Hochrisikosystem

Anhang III Nummer 4 Buchstabe a nennt KI-Systeme, die bestimmungsgemäß für die Einstellung oder Auswahl natürlicher Personen verwendet werden sollen, insbesondere um Bewerbungen zu analysieren und zu filtern und Bewerber zu bewerten (konsolidierte Fassung, keine Omnibus-Änderung ausgewiesen, Stand: 11. November 2026). Der Screener aus @k08-gruppen ist damit ein Anhang-III-System; die Bias-Untersuchung nach Art. 10 Abs. 2 lit. f und g wird ab 2. Dezember 2027 rechtlich verlangt. Die Metriken aus @k08-gruppen und die Audit-Designs aus @k08-audits sind die technischen Mittel dafür, und Art. 4a erlaubt die dafür nötige Verarbeitung sensibler Merkmale nur unter seinen strengen Bedingungen.

#fallstrick[
  Verwechsle Art. 10 nicht mit einer Freigabe-Checkliste. Die Norm verlangt eine Untersuchung und angemessene Maßnahmen; ob ein $Delta_"DP"$ von 0.06 akzeptabel ist, beantwortet sie nicht. Eine Untersuchung, die nur eine Metrik ohne Unsicherheit und ohne Begründung der Kriterienwahl berichtet, ist methodisch schwach, unabhängig davon, wie die Aufsicht sie beurteilt.
]

== Debatten und offene Fragen <k08-debatten>

Das Feld ist jung, und viele Grundfragen sind ungeklärt. Für die Lehre ist es wichtig, diese Debatten nicht als Randnotiz, sondern als Kern des Themas zu vermitteln.

*Ist Invarianz das richtige Ideal?* Fast alle Benchmarks kodieren als Idealwert, dass Gruppenbegriffe keinen Einfluss haben (ss $= 50$, CPS $= 50$, $s_"AMB" = 0$). Wang et al. argumentieren in einem preisgekrönten ACL-Beitrag 2025, dass Fairness manchmal *Differenzbewusstsein* verlangt, also kontextangemessene Ungleichbehandlung, etwa in rechtlichen Kontexten oder bei der Einschätzung von Schaden @wang2025fairness. Ihre Benchmark-Suite (acht Szenarien, 16 000 Fragen, zehn Modelle) unterscheidet deskriptive (faktenbasierte), normative (wertbasierte) und Korrelations-Benchmarks; gängige Debiasing-Strategien "können nach hinten losgehen" @wang2025fairness. Ein Modell, das bei der Frage nach der Wehrpflicht in einem Land mit reiner Männerwehrpflicht das Geschlecht ignoriert, ist nicht fair, sondern falsch.

*Welche Richtung ist Bias?* Die Ergebnisse zu Hochschulzulassungen @nghiem2025rich und zur Bevorzugung von Kandidatinnen @an2025measuring @tamkin2023evaluating zeigen, dass LLMs historisch benachteiligte Gruppen auch bevorzugen können. Ob das erwünschte Kompensation oder unerwünschte Ungleichbehandlung ist, hängt vom gewählten Fairnesskriterium und vom Rechtsrahmen ab, nicht von der Statistik.

*Wie verlässlich sind Bias-Scores?* Reliabilität unter Paraphrase und Modell-Updates wird selten berichtet @delobelle2024metrics @rottger2024political. Die stille Neuschulung der Perspective API hat gezeigt, dass schon die Messinfrastruktur instabil sein kann @hartmann2026bye.

*Wie valide sind Stellvertreter?* Namen und Dialekte signalisieren mehr als die Gruppe, auf die geschlossen wird @barocas2023fairness @seshadri2025small @wilson2024gender.

*Wie sieht es außerhalb des US-Englischen aus?* 87 % der promptbasierten Bias-Tests waren rein englisch @goldfarbtarrant2023prompt. SHADES, ein paralleler mehrsprachiger Datensatz kulturspezifischer Stereotype aus 20 Regionen in 16 Sprachen, zeigt Stereotype konsistent über Modelle und Sprachen, mit einigen deutlich stärker verzerrten Sprachen und Modellen @mitchell2025shades. Für deutschsprachige Pipelines heißt das: US-Benchmarks nicht unbesehen übernehmen.

*Wie verbinden wir Scores mit realem Schaden?* Prädiktive und konsequenzielle Validität sind für die meisten Benchmarks nicht belegt @goldfarbtarrant2023prompt @lum2025bias. Hier liegt ein offenes Forschungsfeld, das sich gut für Abschlussarbeiten eignet.

#hoersaal([Ist ein Modell, das auf direkte Fragen neutral antwortet, aber in Assoziationstests Stereotype zeigt, nun verzerrt oder nicht?],
[Das hängt davon ab, welches Konstrukt du messen willst, und genau deshalb ist die Frage gut. Explizite Neutralität ist eine Aussage über das Antwortverhalten auf direkte Fragen; implizite Assoziationen sind eine Aussage über Zuordnungen und relative Entscheidungen. Bai et al. zeigen, dass die zweite Art die Entscheidungen in relativen Formaten vorhersagt @bai2025explicitly, Hofmann et al., dass verdeckte Vorurteile Feedback-Training überstehen @hofmann2024ai. Für eine Pipeline, die entscheidet, ist die Antwort pragmatisch: Miss die Entscheidung, in dem Format, in dem sie fällt.])

#vertiefung[
  Als Rückgrat @gallegos2024bias (Formelsammlung aller Metrikfamilien). Für Entscheidungsmetriken und Audit-Design Kapitel 3 und 7 von @barocas2023fairness. Für die Messkritik @blodgett2021stereotyping und @delobelle2024metrics, die sich gut als Paar lesen lassen. Für aktuelle Befunde zu ausgerichteten Modellen @hofmann2024ai und @bai2025explicitly. Als Gegenpol zur Invarianz @wang2025fairness. Zum Einstieg in die Ethik algorithmischer Forschung Kapitel 10 von @haindl2027research.
]

== Für die Lehre <k08-lehre>

Das Thema eignet sich hervorragend für eine Mastervorlesung, weil es Statistik, Messtheorie und normative Fragen verbindet. Es ist aber auch anfällig für zwei Fehlformen: eine reine Formelsammlung ohne Validitätsdiskussion oder eine reine Ethikdebatte ohne Rechnen. Foliensatz 08 der LV ist in acht Teile gegliedert (Einführung, Taxonomie, Einbettung und Wahrscheinlichkeit, generierte Texte und QA, Gruppenfairness, Audits, Validität, Regulierung) und folgt damit im Wesentlichen diesem Kapitel.

*Zeitbedarf.* Für die Inhalte von Foliensatz 08 sind etwa zwei Einheiten zu 90 Minuten realistisch: eine für Begriffe, Taxonomie und die Metriken der @k08-einbettung bis @k08-generiert, eine für Gruppenfairness, Audits und Validität. Die Regulierung lässt sich in 15 Minuten am Ende behandeln. Das Notebook braucht als Übung weitere 90 Minuten; ein Namenstausch-Audit mit einem offenen Modell eignet sich als Projekt über mehrere Wochen.

*Übungen,* jeweils mit geschätzter Dauer:
+ *WEAT von Hand* (45 Minuten): Effektstärke und Permutationstest für die Wortlisten von Caliskan et al. mit einem offenen Einbettungsmodell, dann zwei Attributwörter durch Synonyme ersetzen und die Veränderung von $d$ berichten @caliskan2017semantics @delobelle2022measuring.
+ *BBQ mit einem offenen Instruktionsmodell* (90 Minuten): Antworten auf Zielgruppe, Nicht-Zielgruppe und "unbekannt" abbilden, Genauigkeit und beide Bias-Scores je Kategorie berechnen, mit drei Schablonen wiederholen und die Streuung berichten @parrish2022bbq @delobelle2024metrics.
+ *Benchmark-Audit* (60 Minuten): 20 zufällige CrowS-Pairs-Items mit dem Fallstrick-Inventar annotieren, den Anteil fehlerfreier Items und Cohens Kappa zwischen zwei Studierenden berechnen @blodgett2021stereotyping. Das verbindet das Kapitel mit Kapitel 5.
+ *Judge-Invarianz* (60 Minuten): 100 Antwortpaare, Identitätshinweis in eine Antwort einfügen, RR und CR berechnen und diskutieren @ye2024justice.
+ *Politischer Bias* (60 Minuten): zehn Aussagen des Political Compass in erzwungener, unerzwungener und offener Form mit je fünf Paraphrasen, Positionswechsel zählen @rottger2024political.

*Typische Missverständnisse.* Erstens halten Studierende einen niedrigen Wert auf einem Standardbenchmark für einen Fairnessnachweis; hier hilft @lum2025bias mit dem Befund "so gut wie Zufall". Zweitens wird die Flip-Rate eines Tauschtests als Bias interpretiert, obwohl sie ohne Kontrollbedingung vor allem Rauschen misst; das Notebook zeigt 14 % gegenüber 12 %. Drittens wird die Unvereinbarkeit als technisches Problem gesehen, das bessere Modelle lösen; der Beweis von @k08-eq-sr-basis in fünf Zeilen räumt damit auf. Viertens verwechseln viele Max-min-Differenzen mit vorzeichenbehafteten Differenzen und bootstrappen die falsche Größe. Fünftens wird der AI Act als Metrikvorschrift gelesen.

*Diskussionsfragen.* Ist ein Modell, das systematisch Bewerber mit niedrigem sozioökonomischem Status bevorzugt, fair, und nach welchem Kriterium @nghiem2025rich @barocas2023fairness? Was würde dich überzeugen, dass ein Benchmark-Score Schaden in deiner Anwendung vorhersagt @goldfarbtarrant2023prompt @harvey2025understanding? Deine Toxizitätsmetrik hängt von einer API ab, die abgeschaltet wird: Was berichtest und archivierst du @hartmann2026bye?

*Werkzeuge* (Stand: 11. November 2026). Fairlearn 0.15.0 für Gruppenmetriken; AIF360 0.6.1, seit April 2024 ohne neues Release; LangFair 0.8.0 für anwendungsnahe LLM-Bias-Bewertung mit Toxizität, Stereotypen, kontrafaktischer Fairness für Generierung sowie Empfehlungs- und Klassifikationsfairness @bouchard2025langfair. Bei klassifikatorbasierten Komponenten aller Werkzeuge gilt die Warnung aus @k08-generiert. Die Datensätze BBQ (CC-BY-4.0), CrowS-Pairs (CC-BY-SA-4.0), StereoSet (CC-BY-SA-4.0, nur Dev-Set öffentlich), BOLD (Lizenzangaben auf der Datensatzkarte widersprüchlich, im Zweifel CC BY-SA 4.0) und discrim-eval (CC-BY-4.0) sind auf Hugging Face verfügbar. Für die Übungen genügt pandas; eigene Implementierungen vermeiden Versionsdrift.

#hoersaal([Brauchen wir für eine Bias-Analyse in einer Masterarbeit eine Ethikkommission?],
[Für ein Audit eines Modells mit synthetischen Lebensläufen in der Regel nicht, weil keine Menschen beteiligt sind. Anders, sobald echte Daten mit sensiblen Merkmalen verarbeitet werden oder menschliche Annotierende belastende Inhalte (etwa Hassrede) labeln: Dann gelten die Grundsätze der Forschung mit Menschen, und Annotierende sind Teilnehmende, deren Einwilligung und Wohlergehen zu berücksichtigen sind @haindl2027research. Bei Audits realer, eingesetzter Systeme kommen Fragen der Nutzungsbedingungen und fiktiver Profile hinzu, für die eine unabhängige Prüfung wertvoll ist @haindl2027research.])

#selbsttest(
  [Ordne die folgenden Metriken einer Familie der Taxonomie zu und gib an, ob sie intrinsisch oder extrinsisch sind: SEAT, ICAT, $s_"AMB"$, Disparate-Impact-Verhältnis, Gender-Wavg von BOLD.],
  [Leite her, dass die WEAT-Effektstärke mit Populationsstandardabweichung höchstens 2 beträgt (und wann genau 2), und berechne die Obergrenze mit Stichprobenstandardabweichung für fünf Wörter je Zielmenge.],
  [Gegeben sind die Assoziationswerte $s(x_1) = 0.12$, $s(x_2) = 0.04$, $s(x_3) = 0.08$ und $s(y_1) = 0.01$, $s(y_2) = -0.03$, $s(y_3) = 0.02$. Berechne $d$ (Stichproben-SD) und den kleinsten erreichbaren exakten $p$-Wert. Ist der beobachtete Wert dieser kleinste?],
  [Ein Modell erreicht lms 90 und ss 35. Berechne icat und erkläre, warum ein Modell mit ss 65 denselben Wert erhält. Ist diese Symmetrie sachlich gerechtfertigt?],
  [Im mehrdeutigen BBQ-Kontext antwortet ein Modell bei 2000 Fragen 1600-mal "unbekannt"; von den übrigen Antworten folgen 260 dem Bias. Berechne $s_"AMB"$ in der im Kapitel verwendeten Lesart und interpretiere.],
  [Ein LLM-Screener hat je Gruppe 500 Bewerbungen mit 150 Qualifizierten. Gruppe $a$: 120 richtig und 35 falsch eingeladen; Gruppe $b$: 105 und 21. Berechne $Delta_"DP"$, DIR, $Delta_"TPR"$, $Delta_"FPR"$ und ein 95-%-Intervall für die Differenz der Selektionsraten.],
  [Beweise: Erfüllt eine binäre Entscheidung Separation und unterscheiden sich die Basisraten zweier Gruppen, so verletzt sie Unabhängigkeit, außer sie ist von $Y$ unabhängig.],
  [Zwei Gruppen haben Basisraten 0.5 und 0.25. Ein Klassifikator hat in beiden PPV 0.75 und FNR 0.1. Welche FPR ergeben sich? Was folgt daraus für eine Forderung nach Kalibrierung und gleichen Fehlerraten?],
  [Ein Namenstausch-Audit mit 300 Lebensläufen ergibt $b = 30$, $c = 14$; die Kontrollbedingung $b = 20$, $c = 18$. Führe für beide den McNemar-Test durch (approximativ) und interpretiere. Warum ist die Flip-Rate allein kein Bias-Maß?],
  [Ein LLM-Judge hat bei Identitätstausch $"RR" = 0.80$, bei Wiederholung $"CR" = 0.95$. Ein anderer hat $"RR" = 0.80$ und $"CR" = 0.81$. Welcher ist bedenklicher, und wie würdest du die Asymmetrie prüfen?],
  [Nenne drei Fallstricke aus dem Inventar von Blodgett et al. und erkläre an einem selbst konstruierten Testpaar, wie einer davon den Score verzerrt.],
  [Ein Unternehmen setzt ab 2028 einen LLM-Screener für Bewerbungen in Österreich ein. Welche Pflichten aus Art. 10 EU AI Act gelten ab wann, was regelt Art. 4a, und was schreibt die Verordnung zur Wahl der Metrik vor?],
)

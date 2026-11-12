#import "../lib.typ": *

// Kapitel-lokale Helfer
#let zwischentitel(t) = block(above: 1.1em, below: 0.55em, sticky: true, text(size: 9.6pt, weight: "bold", fill: c-dark, t))
#let datei-fest(name, body) = block(breakable: false, width: 100%, datei(name, body))

= LLMs als Annotatoren <k05>

Wer mit Texten forscht, braucht Codes. Ein Tweet ist relevant oder nicht, eine Stellungnahme befürwortet eine Maßnahme oder lehnt sie ab, eine offene Antwort in einer Befragung nennt Kosten, Zeitdruck oder fehlende Unterstützung als Grund. Bevor eine einzige Regression gerechnet oder ein einziges Thema berichtet werden kann, muss jemand diese Zuordnungen treffen, und das war jahrzehntelang die teuerste und langsamste Phase vieler Studien in den Sozialwissenschaften, der angewandten Sprachverarbeitung und der empirischen Softwaretechnik. Seit 2023 übernehmen große Sprachmodelle diese Arbeit in rasch wachsendem Umfang: Sie vergeben Labels nach einem Codebuch, sie schlagen Codes vor, sie verdichten offene Antworten zu Themen.

Die Versuchung ist offensichtlich. Gilardi et al. berichten, dass ein Zero-Shot-ChatGPT Crowdworker auf MTurk in der Genauigkeit im Mittel um etwa 25 Prozentpunkte übertraf, bei Kosten von weniger als 0.003 US-Dollar pro Annotation, rund dreißigmal billiger als MTurk @gilardi2023chatgpt. Ebenso offensichtlich ist das Risiko. Über 27 Annotationsaufgaben aus 11 nicht öffentlichen Datensätzen erreichte GPT-4 einen Median-F1 von 0.707, aber der schlechteste Wert lag bei 0.059 @pangakis2023automated. Und Baumann et al. zeigen, dass allein die Wahl von Modell und Prompt in rund 31 % der Fälle zu einer falschen wissenschaftlichen Schlussfolgerung führt, selbst mit den stärksten Modellen @baumann2025large. Ob LLM-Labels gut genug sind, ist deshalb keine Frage, die man einmal für alle Zeiten beantworten kann. Sie muss für jede Aufgabe, jeden Datensatz und jede Konfiguration empirisch beantwortet werden.

Dieses Kapitel liefert das Handwerkszeug dafür. Es beginnt mit dem Forschungsstand, geht dann ausführlich durch die Übereinstimmungsmaße, mit denen man Reliabilität misst (mit vollständigen Herleitungen und durchgerechneten Beispielen), behandelt die Paradoxa, an denen diese Maße scheitern, und die Unsicherheit, die jede Schätzung aus einer Validierungsstichprobe trägt. Danach geht es um Validierungsdesigns, die auf die Eigenheiten von LLMs zugeschnitten sind, bis hin zum formalen Test, ob ein LLM einen menschlichen Annotator ersetzen darf. Der Schwerpunkt des zweiten Teils liegt auf dem Codieren: dem deduktiven Anwenden eines Codebuchs und, besonders ausführlich, dem induktiven Ableiten eines Codebuchs aus offenen Antworten. Wie man die Korrektur nachgelagerter Schätzer vornimmt, wenn LLM-Labels in eine Regression eingehen, ist Gegenstand von Kapitel 6; hier geht es um die Labels selbst.

#lernziele[
  Prozentübereinstimmung, Cohens $kappa$, Scotts $pi$, Fleiss' $kappa$, Krippendorffs $alpha$ (nominal, ordinal, intervall, mit fehlenden Werten), Gwets AC1, PABAK, gewichtetes $kappa$ und die ICC-Formen per Hand und in Python berechnen und herleiten, warum sie sich nur im Zufallsmodell unterscheiden.
][
  Das Prävalenz- und das Bias-Paradoxon von $kappa$ algebraisch begründen und für eine gegebene Labelverteilung einen Koeffizienten begründet wählen.
][
  Konfidenzintervalle für Übereinstimmungsmaße asymptotisch und per Bootstrap bestimmen und daraus den Umfang einer Validierungsstichprobe ableiten.
][
  Ein Validierungsprotokoll für eine LLM-Annotation entwerfen (Codebuch, Entwicklungs- und Testsplit, Stabilitätsprüfungen) und den Alternative Annotator Test durchführen und interpretieren.
][
  Ein Codebuch induktiv mit LLM-Unterstützung aus offenen Antworten ableiten und mit einem menschlichen Codebuch über Code-Abgleich, Adjusted Rand Index und Sättigungsmaße vergleichen.
][
  Publizierte Behauptungen der Art "LLMs übertreffen menschliche Codierende" auf Konstruktvalidität, Referenzstandard, Kontamination und Reproduzierbarkeit prüfen und eine eigene Annotation vollständig berichten.
]

== Begriffe: Annotation, Codieren, Referenzstandard

=== Annotation und Codieren

*Annotation* oder *Labeling* bedeutet, einer Texteinheit einen Wert aus einem vorab festgelegten Schema zuzuweisen: eine Kategorie, einen ordinalen Wert oder eine Textspanne. In der LLM-Literatur umfasst das Relevanz-, Stance-, Themen- und Frame-Klassifikation @gilardi2023chatgpt ebenso wie Sentiment, diskrete Emotionen, Beleidigung und moralische Grundlagen @rathje2024gpt. *Codieren* ist der in der qualitativen Forschung übliche Begriff für dasselbe, mit einem wichtigen Unterschied in der Herkunft des Schemas.

Beim *deduktiven Codieren* (_deductive coding_) existiert das Kategoriensystem vorab, typischerweise als Codebuch mit Definitionen, Beispielen und Regeln für Grenzfälle. Pangakis et al. behandeln das Codebuch als gemeinsames Instrument für menschliche Fachleute und das LLM: Es wird iterativ verfeinert, bis die LLM-Labels auf einer menschlich codierten Teilmenge gut genug passen, und anschließend auf zurückgehaltenen menschlichen Labels getestet @pangakis2023automated. Beim *induktiven Codieren* (_inductive coding_) entsteht das Kategoriensystem erst aus den Daten, etwa beim offenen Codieren der Grounded Theory oder in der reflexiven thematischen Analyse @haindl2027research @depaoli2024performing.

Törnberg empfiehlt, die menschlichen Codierrichtlinien und die exakten Prompts samt LLM-Einstellungen in einem einzigen Dokument zusammenzuführen, dem *Prompt-Codebuch* (_prompt codebook_). Es enthält Kategoriendefinitionen, Beispiele, Regeln für mehrdeutige Fälle und gegebenenfalls Feinabstimmungsdaten, sodass sowohl die menschliche als auch die maschinelle Codierung reproduzierbar ist. Ein Prompt ist dabei an das Modell gebunden, für das er entwickelt wurde @tornberg2024best.

#definition(titel: [Annotation, Konfiguration, LLM Hacking])[
  Eine *Annotation* ist eine Abbildung $f: cal(U) -> cal(C)$ von Texteinheiten $u in cal(U)$ auf Werte eines Schemas $cal(C)$. Eine *Konfiguration* ist nach Baumann et al. die Kombination aus Modell, Prompt-Formulierung, Dekodierparametern und Abbildung der Modellausgabe auf ein Label. *LLM Hacking* liegt vor, wenn eine Konfiguration zu einer wissenschaftlichen Schlussfolgerung führt, die von der durch die Referenzlabels gestützten abweicht @baumann2025large.
]

Die Definition macht etwas explizit, das in der Praxis gern übersehen wird: Ein LLM-Annotator ist nicht "das Modell", sondern das ganze Tupel aus Modell, Version, Prompt, Temperatur und Ausgabe-Parser. Jedes Element dieses Tupels ist eine Stellschraube, an der sich das Ergebnis ändern kann.

=== Das Spektrum der Rollen

Zwischen reinem deduktivem Labeling und vollständig automatisierter Themenbildung liegt ein Kontinuum von Rollen, die ein LLM einnehmen kann. @k05-fig-rollen ordnet sie nach wachsendem Automatisierungsgrad. Am deduktiven Ende wendet das Modell ein fertiges Codebuch an. Als *Code-Vorschlagsgeber* schlägt es Codes vor, die ein Mensch konsolidiert, etwa in Diskussionsrunden zwischen menschlichem Codierer und GPT-3.5 @dai2023llm. Als *Konzept- oder Themeninduktor* erzeugt es übergeordnete Konzepte mit expliziten Einschlusskriterien @lam2024concept oder eine Themenhierarchie mit natürlichsprachlichen Beschreibungen @pham2024topicgpt. Als *Multi-Agenten-Codierer* arbeiten mehrere Codier-Agenten mit unterschiedlichen Identitätsperspektiven, ein Aggregator und ein Codebuch-Verwalter zusammen @qiao2025thematic. Als *vollständige Pipeline* erzeugt das Modell Codes und Themen und ordnet anschließend die Antworten zu @bergmann2026llms.

#figure(
  diagram(spacing: (5mm, 7mm),
    fknoten((0,0), [*Anwenden* \ festes Codebuch, \ ein Label je \ Einheit], col: c-blue, w: 28mm),
    edge("-|>"),
    fknoten((1,0), [*Vorschlagen* \ LLM schlägt vor, \ Mensch \ konsolidiert], col: c-teal, w: 28mm),
    edge("-|>"),
    fknoten((2,0), [*Induzieren* \ Konzepte mit \ Einschluss- \ kriterien], col: c-violet, w: 28mm),
    edge("-|>"),
    fknoten((3,0), [*Multi-Agent* \ Perspektiven, \ Aggregator], col: c-yellow, w: 28mm),
    edge("-|>"),
    fknoten((4,0), [*Pipeline* \ Codes, Themen \ und Zuordnung], col: c-accent, w: 28mm),
    node((0,1), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[Xiao 2023, \ Dunivin 2025]),
    node((1,1), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[Dai et al. 2023]),
    node((2,1), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[LLooM, TopicGPT]),
    node((3,1), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[Thematic-LM]),
    node((4,1), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[Bergmann et al. 2026]),
  ),
  caption: [Rollen eines LLM beim Codieren, von links (deduktiv, Mensch definiert die Kategorien) nach rechts (induktiv, Modell erzeugt und vergibt die Kategorien). Je weiter rechts, desto weniger gibt es eine feste Labelmenge, gegen die man prüfen kann.],
) <k05-fig-rollen>

Die Abbildung enthält bereits eine methodische Aussage: Je weiter rechts eine Rolle liegt, desto schwieriger wird die Evaluation, weil es keine feste Labelmenge mehr gibt, gegen die man vergleichen kann. Für das Anwenden eines Codebuchs reichen Übereinstimmungsmaße. Für das Ableiten eines Codebuchs braucht man zusätzliche Werkzeuge, die in @k05-induktiv behandelt werden.

=== Referenzstandard statt Ground Truth

Fast alle Studien zur LLM-Annotation vergleichen mit trainierten oder fachkundigen menschlichen Codierenden. Das klingt nach Ground Truth, ist es aber nicht. Gilardi et al. setzten drei trainierte Studierende der Politikwissenschaft ein und berechneten die Genauigkeit nur auf Items, bei denen sich zwei dieser Annotatoren einig waren @gilardi2023chatgpt. Eine solche Auswahl der leichten, konsensfähigen Fälle kann die Genauigkeit gegenüber der Gesamtheit der Texte überschätzen. Törnberg warnt ausdrücklich davor, menschliche Codierende als Ground Truth zu behandeln, und empfiehlt, die Reliabilität sowohl unter Menschen als auch zwischen Menschen und LLM zu berechnen @tornberg2024best. Rathje et al. weisen darauf hin, dass sie nur die Übereinstimmung mit Annotatoren getestet haben, nicht, was die Verfasserinnen und Verfasser der Texte tatsächlich empfanden @rathje2024gpt. Plank argumentiert grundsätzlicher, dass ein großer Teil menschlicher Labelvariation echt ist (Dissens, Subjektivität, mehrere plausible Antworten) und kein Rauschen @plank2022problem.

Wir sprechen deshalb in diesem Kapitel konsequent vom *Referenzstandard*. Das ist mehr als eine sprachliche Feinheit: Wer von Ground Truth spricht, interpretiert jede Abweichung als Fehler des LLM. Wer vom Referenzstandard spricht, hält die Frage offen, ob die Abweichung beim Modell, beim Referenzstandard oder in der Mehrdeutigkeit des Konstrukts liegt. Panahi et al. haben für Farsi-Inferenzaufgaben 198 Stichproben mit Prompt-Sensitivität manuell geprüft; bei 97 davon widersprach das Modell dem Gold-Label, und die Mehrzahl dieser Fälle ließ sich auf Fehler oder Mehrdeutigkeiten im Gold-Label zurückführen, nicht auf das Modell @panahi2026when.

=== Reliabilität ist nicht Validität

Zwei Fragen sind sauber zu trennen. *Reliabilität* fragt, ob wiederholte Messungen (andere Codierende, andere Läufe) denselben Wert liefern. *Validität* fragt, ob der Wert das Konstrukt trifft, operationalisiert meist als Übereinstimmung mit einem Referenzstandard. Methodisch ist das die vertraute Unterscheidung aus der quantitativen Forschung @haindl2027research. Bei LLMs fallen die beiden besonders weit auseinander. In der Studie von Gilardi et al. lag die Übereinstimmung von ChatGPT über zwei Läufe (etwa 91 % bei Temperatur 1, etwa 97 % bei Temperatur 0.2) in allen Aufgaben über der der trainierten Annotatoren (etwa 79 %). Über die Aufgaben hinweg korrelierte diese Übereinstimmung aber nur schwach mit der Genauigkeit, $r = 0.36$ @gilardi2023chatgpt. Von der Heyde et al. fanden eine Lauf-zu-Lauf-ICC von 0.99 für GPT-4o, während dasselbe Modell die Kategorienverteilung deutlich verzerrte @vonderheyde2025using. Ein Modell, das konsistent auf dieselbe Weise falsch liegt, ist reliabel, aber nicht valide.

#merke[
  Hohe Übereinstimmung eines LLM mit sich selbst (über Läufe, Temperaturen oder Paraphrasen) ist eine notwendige, aber keine hinreichende Bedingung für brauchbare Labels. Validität braucht immer einen externen Vergleich, und dieser Vergleich braucht einen Referenzstandard, dessen eigene Reliabilität du kennst.
]

=== Wozu die Labels dienen

Pangakis et al. unterscheiden vier Verwendungen von LLM-Labels, die unterschiedliche Qualitätsansprüche stellen @pangakis2023automated: die Qualität menschlicher Labels bestätigen, Fälle für die menschliche Durchsicht priorisieren, Trainingsdaten für einen überwachten Klassifikator erzeugen und das gesamte Korpus klassifizieren. Ziems et al. plädieren dafür, LLMs als Zero-Shot-Annotatoren _neben_ menschlichen Codierenden einzusetzen, nicht als Ersatz, und das nur für Aufgaben mit validierter Übereinstimmung @ziems2024can. Die Unterscheidung ist praktisch wichtig: Ein Label, das nur entscheidet, ob ein Mensch einen Fall noch einmal ansieht, darf deutlich fehlerhafter sein als eines, das direkt in eine Prävalenzschätzung eingeht.

#figure(
  diagram(spacing: (6mm, 5mm),
    fknoten((0,0), [Menschliche Labels \ bestätigen], col: c-green, w: 32mm),
    fknoten((1,0), [Fälle für Durchsicht \ priorisieren], col: c-teal, w: 32mm),
    fknoten((2,0), [Trainingsdaten \ für Klassifikator \ erzeugen], col: c-yellow, w: 32mm),
    fknoten((3,0), [Gesamtes Korpus \ klassifizieren], col: c-red, w: 32mm),
    edge((0,1), (3,1), "-|>", stroke: 1pt + c-dark, label: text(font: "Inter", size: 7pt)[steigender Anspruch an die Labelqualität], label-side: right),
  ),
  caption: [Vier Verwendungen von LLM-Labels nach Pangakis et al. @pangakis2023automated. Je weiter rechts, desto direkter gehen Labelfehler in das Ergebnis ein.],
) <k05-fig-verwendung>

=== Kontamination

Ein letzter Begriff gehört an den Anfang, weil er jede Evaluation betrifft. Waren die Evaluationsdaten oder ihre Labels in den Trainingsdaten des Modells, fallen die Validierungsmetriken zu optimistisch aus. Törnberg empfiehlt, öffentliche gelabelte Datensätze wie die Manifesto-Datenbank nicht zur Validierung zu verwenden und zu prüfen, ob das Trainings-Cutoff des Modells in den Zeitraum fällt, den der Datensatz abdeckt @tornberg2024best. Pangakis et al. haben aus genau diesem Grund 11 nicht öffentliche Datensätze verwendet @pangakis2023automated.

== Was die Evidenz zeigt <k05-evidenz>

Die Literatur zur LLM-Annotation ist seit 2023 explodiert. Statt sie chronologisch durchzugehen, ordnen wir sie nach dem, was sie über die Bedingungen guter und schlechter Labels lehrt. Vorweg eine Beobachtung, die bei der Lektüre leicht verloren geht: Die prominenten positiven Befunde konzentrieren sich auf englischsprachige, politikwissenschaftliche Klassifikationsaufgaben mit Modellen der GPT-4-Klasse. Das ist ein Auswahleffekt der Forschung, kein Naturgesetz.

=== Die Erfolgsgeschichten

#studie(titel: [Gilardi et al. 2023])[
  *Design:* 6183 Dokumente in vier Stichproben (2382 Tweets zur Inhaltsmoderation, 1856 Tweets von US-Kongressmitgliedern, 1606 Nachrichtenartikel, 339 Tweets aus 2023); Aufgaben zu Relevanz, Stance, Themen und Frames; ChatGPT bei Temperatur 1 und 0.2, je zwei Läufe. Referenz: drei trainierte Studierende mit demselben Codebuch, Genauigkeit nur auf Items, bei denen zwei von ihnen übereinstimmten. \
  *Befund:* Zero-Shot-Genauigkeit im Mittel etwa 25 Prozentpunkte über MTurk. Relevanz-Genauigkeit 70 % (Moderation), 81 % (News), 83 % (Kongress), 59 % (Tweets 2023). Übereinstimmung zwischen Codierenden etwa 56 % (MTurk), 79 % (Trainierte), 91 % und 97 % (ChatGPT bei Temperatur 1 bzw. 0.2). Kosten unter 0.003 US-Dollar pro Annotation. \
  *Grenzen:* Konsens-Items sind leichtere Items; die Studierenden gelten als Gold; Modellstand Frühjahr 2023. Die Korrelation zwischen Übereinstimmung und Genauigkeit über Aufgaben betrug nur $r = 0.36$ @gilardi2023chatgpt.
]

@k05-fig-gilardi zeigt die Übereinstimmungswerte. Die Grafik ist ein gutes Beispiel dafür, wie leicht man Reliabilität mit Qualität verwechselt: Die höchsten Balken gehören zu ChatGPT, aber sie messen nur, wie oft das Modell mit sich selbst übereinstimmt.

#figure(
  balken((
    ([MTurk-Crowdworker], 56),
    ([Trainierte Annotatoren], 79),
    ([ChatGPT, Temperatur 1], 91),
    ([ChatGPT, Temperatur 0.2], 97),
  ), max: 100, breite: 8, einheit: " %", nachkomma: 0, farbe: c-blue),
  caption: [Mittlere Übereinstimmung zwischen Codierenden (bei ChatGPT: zwischen zwei Läufen) in Gilardi et al. @gilardi2023chatgpt. Die Balken messen Reliabilität, nicht Genauigkeit.],
) <k05-fig-gilardi>

#studie(titel: [Törnberg 2025])[
  *Design:* Zero-Shot-GPT-4 (gpt-4-0314) soll aus einer einzelnen X/Twitter-Nachricht die Partei eines Politikers erkennen, in 11 Ländern; 500 Nachrichten pro Land (250 je Partei), für Schweden, Neuseeland und Polen 100 je Partei. Vergleich mit Naive Bayes und feinabgestimmtem BERT (je 5000 Trainingsnachrichten pro Partei), MTurk (10 Master-Worker pro Item, Mehrheitsvotum) und drei Fachleuten. \
  *Befund:* USA: GPT-4 0.934, BERT 0.808, Naive Bayes 0.792, MTurk 0.854, Fachleute 0.860 Genauigkeit; GPT-4 war in jedem Land am genauesten. Die Vorgängerstudie fand, dass alle Codierenden zu "Demokrat" tendierten, MTurk deutlich stärker als LLM und Fachleute. \
  *Grenzen:* Eine binäre Aufgabe mit objektiv bekanntem Label; öffentliche Nachrichten können in den Trainingsdaten sein @tornberg2025large @tornberg2023chatgpt.
]

Der Kontrast zwischen beiden Studien ist lehrreich. Die Parteizugehörigkeit eines Politikers ist ein Konstrukt mit wahrem Wert; "Frame" oder "Stance" sind interpretative Konstrukte, bei denen schon der Referenzstandard strittig ist. Je näher ein Konstrukt an einer beobachtbaren Tatsache liegt, desto eher sind hohe LLM-Genauigkeiten zu erwarten.

#studie(titel: [Rathje et al. 2024])[
  *Design:* 15 Datensätze in 12 Sprachen, 47 925 manuell annotierte Tweets und Schlagzeilen; Sentiment, diskrete Emotionen, Beleidigung, moralische Grundlagen; GPT-3.5 Turbo, GPT-4, GPT-4 Turbo mit einfachen Zero-Shot-Prompts. Acht der Sprachen sind afrikanische Sprachen (nur Sentiment). \
  *Befund:* Korrelation mit manuellen Ratings $r = 0.59$ bis $0.77$, gegenüber $0.20$ bis $0.30$ für Wörterbuchmethoden. Mittlerer F1 stieg über die Versionen von 0.571 auf 0.603 auf 0.653. Der beste GPT-Mittelwert lag bei 0.665, das beste feinabgestimmte Alternativmodell bei 0.735. Afrikanische Sprachen: mittlerer F1 0.455 / 0.520 / 0.600. Test-Retest gewichtetes $kappa$ 0.93 bis 0.99 für Läufe im Abstand eines Tages. Schwache Konstrukte: moralische Proportionalität und Reinheit mit F1 um 0.13 bis 0.19. \
  *Grenzen:* Nichtdeterminismus auch bei Temperatur 0, Modelldrift, Übermarkierung neutraler Tweets als positiv oder negativ @rathje2024gpt.
]

Heseltine und Clemm von Hohenberg kommen für vier Variablen (politisch oder nicht, Negativität, Sentiment, Ideologie) in Tweets und Nachrichten aus den USA, Chile, Deutschland und Italien zu einem ähnlichen Bild: GPT-4 klassifizierte bis zu 95 % der Texte korrekt, am besten bei kurzen Texten, schlechter bei langen Nachrichtenartikeln und etwas schlechter in Nicht-Englisch. Ein Hybrid, bei dem ein Mensch Unstimmigkeiten zwischen mehreren GPT-4-Läufen entscheidet, verbesserte die Genauigkeit @heseltine2024large.

=== Die Heterogenität

#studie(titel: [Pangakis, Wolken & Fasching 2023])[
  *Design:* 27 Annotationsaufgaben aus 11 nicht öffentlichen Datensätzen aus aktuellen sozialwissenschaftlichen Artikeln; über 200 000 Textproben mit GPT-4 per API für etwa 420 US-Dollar; Konsistenzwerte aus 7 Wiederholungen bei Temperatur 0.6. \
  *Befund:* Median-Genauigkeit 0.850, Median-F1 0.707, mittlerer F1 0.660, minimaler F1 0.059. Bei 9 von 27 Aufgaben lag Precision oder Recall unter 0.5, bei 3 beide. Recall übertraf Precision in 20 von 27 Aufgaben. 85.1 % der Proben hatten einen Konsistenzwert von 1.0; für voll konsistente Labels war die Genauigkeit 19.4 Punkte höher. \
  *Grenzen:* Ein Modell, Stand 2023; Aufgaben aus dem Zugang der Autoren zu Replikationsdaten @pangakis2023automated.
]

Der Abstand zwischen dem Median-F1 von 0.707 und dem Minimum von 0.059 ist die wichtigste Information dieser Studie. Sie bedeutet, dass ein einzelner Benchmark, auf dem ein LLM gut abschneidet, nichts über die nächste Aufgabe aussagt.

#studie(titel: [Ziems et al. 2024])[
  *Design:* Systematische Zero-Shot-Evaluation von 13 LLMs auf 25 englischsprachigen Benchmarks der Computational Social Science (20 Klassifikations-, 5 Generierungsaufgaben); Vergleich mit feinabgestimmtem RoBERTa-large und mit Gold-Labels per $kappa$. \
  *Befund:* Zero-Shot-LLMs schlugen die feinabgestimmten Baselines selten, Ausnahmen wie Stance (GPT-4 76.0 F1 gegenüber 36.1). Große Lücken bei figurativer Sprache (62.3 gegenüber 99.2), Ideologie auf Dokumentebene (51.5 gegenüber 85.1), Event-Argument-Extraktion (23.0 gegenüber 65.1) und implizitem Hass (32.3 gegenüber 62.5). 8 von 17 Klassifikationsaufgaben erreichten moderate bis gute Übereinstimmung mit den Gold-Labels ($kappa$ etwa 0.40 bis 0.65), 5 nur schlechte. Desinformation: FLAN-UL2 $kappa = 0.55$ bei einer berichteten Mensch-Mensch-Übereinstimmung von 0.51. \
  *Empfehlung:* LLMs als Annotatoren _neben_ Menschen, nur bei validierter Übereinstimmung @ziems2024can.
]

Drei weitere Befunde relativieren den Optimismus. Kristensen-McLachlan et al. verglichen offene Modelle und ChatGPT mit einem überwachten DistilBERT auf zwei binären Tweet-Aufgaben: DistilBERT war insgesamt am besten, GPT-4 erreichte es nur bei der politischen Aufgabe, und die LLM-Leistung schwankte unvorhersehbar über Aufgaben, Prompts und Shot-Einstellungen @kristensenmclachlan2025are. Von der Heyde et al. codierten 5072 deutschsprachige offene Antworten zur Befragungsmotivation in 22 Kategorien: GPT-4o erreichte Few-Shot einen Makro-F1 von 0.71, feinabgestimmtes GPT-4o 0.87, und nur dieses Setup war zufriedenstellend; ein älteres SVM auf denselben Daten erreichte einen Median-F1 von 0.83 gegenüber 0.72 für das beste Standard-LLM @vonderheyde2025using. Ashwin et al. zeigen an Interviews mit Rohingya-Geflüchteten und ihren bengalischen Gastgebern, dass LLM-Codierfehler mit Merkmalen der Befragten korrelieren können, was zu irreführenden Schlüssen führt; einfachere überwachte Modelle, trainiert auf hochwertigen menschlichen Codes, erzeugten weniger Messfehler und Bias @ashwin2026using.

#fallstrick[
  Der Satz "LLMs sind so gut wie Menschen" ist in dieser Allgemeinheit nicht belegt. Belegt sind Aussagen über bestimmte Aufgaben, Modelle, Prompts und Referenzstandards. Fein abgestimmte kleine Modelle auf wenigen hundert menschlichen Labels sind in mehreren Studien die stärkere Baseline @kristensenmclachlan2025are @vonderheyde2025using @alizadeh2025open, und jede LLM-Annotationsstudie sollte zeigen, dass sie diese Baseline schlägt.
]

=== Die Instabilität

#studie(titel: [Reiss 2023])[
  *Design:* 234 deutschsprachige Webseitentexte, binär News oder nicht News; 10 Instruktionsvarianten, 2 Temperaturen (0.25 und 1), 10 Wiederholungen, insgesamt 46 800 Eingaben an gpt-3.5-turbo (Stand 1. April 2023); Konsistenz per Krippendorffs $alpha$ mit Schwelle 0.8; bewusst kein Vergleich mit menschlichen Labels. \
  *Befund:* Temperaturvergleich: $alpha = 0.75$ für Einzelausgaben, 0.91 mit Mehrheitsvotum über 10 Wiederholungen. Über alle 45 Instruktionspaare (Einzelausgaben) lag $alpha$ zwischen 0.24 und 0.70, im Mittel 0.43. Identische Wiederholungen: $alpha$ über 0.9 bei Temperatur 0.25. Kosten etwa 152 US-Dollar. \
  *Grenzen:* Eine Aufgabe, eine Sprache, eine Modellversion @reiss2023testing.
]

Die Zahl 0.24 bis 0.70 für semantisch gleichwertige Instruktionen ist das Kernargument dafür, Prompts als Teil des Messinstruments zu behandeln. Liu hat diese Perspektive 2026 zugespitzt: Mit 20 semantisch äquivalenten Prompts pro Aufgabe schwankte die Genauigkeit bei der TREC-Fragenklassifikation zwischen 0.546 und 0.808 (GPT-4o mini) bzw. 0.392 und 0.756 (Llama), die paarweise Übereinstimmung zwischen Prompts variierte um mehr als 40 Prozentpunkte. Bei der PolitiFact-Wahrheitsbewertung waren die Modelle dagegen stabil, aber falsch: binarisierte Genauigkeit um 30 %, "hartnäckige Konsistenz" @liu2026what. Mehrheitsvoten über 10 Prompts hoben die mittlere paarweise Übereinstimmung von etwa 0.71 auf etwa 0.95 @liu2026what, was die Varianz senkt, systematischen Bias aber zementieren kann.

Atreja et al. testeten in einem vollfaktoriellen Design vier Prompt-Merkmale (Definition enthalten, Label- oder Zahlenausgabe, Erklärung verlangt, Promptlänge) mit drei Modellen auf vier Aufgaben, insgesamt 362 928 Annotationen. Die Formattreue schwankte je nach Prompt um bis zu 55 Prozentpunkte, die Genauigkeit um bis zu 14; numerische Ausgaben schadeten, und die Bitte um Erklärungen verschob die Labelverteilung: ChatGPT stufte bei Sentiment etwa 34 Prozentpunkte mehr Items als neutral ein @atreja2025prompt. Prompt-Merkmale verändern also nicht nur die Genauigkeit, sondern die _Prävalenzschätzung_, und das ist für nachgelagerte Analysen das gefährlichere Problem. Halterman und Keith zeigen zusätzlich, dass alle getesteten offenen Modelle auf die Reihenfolge der Kategorien im Prompt reagierten @halterman2026codebook. McLaren et al. finden 2026 für offene Modelle, dass Interaktionen zwischen Modell, Größe, Shot-Einstellung und Prompt-Stil die Haupteffekte dominieren: Persona-Prompting senkte Llama 3.1 von etwa 0.40 auf unter 0.30 F1, Chain-of-Thought senkte DeepSeek R1 bei ökonomischem Sentiment von 0.71 auf 0.47 @mclaren2026magic.

=== Temperatur, Wiederholung und Modellwahl

Alizadeh et al. haben die Temperatur systematisch variiert. Bei GPT-3.5 stieg die Übereinstimmung zwischen Läufen von 91.7 % auf 97.6 %, wenn die Temperatur von 1 auf 0.2 sank; bei HuggingChat (LLaMA-1) von 46.7 % auf 84.8 % bei einer Senkung von 0.9 auf 0.2. Nur GPT-4 und GPT-3.5 schlugen MTurk auf allen 11 Aufgaben. Feinabstimmung mit 50 bzw. 100 Beispielen hob die mittlere Genauigkeit bei GPT-3.5 um 15.7 bzw. 19.1 und bei FLAN-T5 XL um 7.7 bzw. 12.4 (im Paper als Prozent angegeben); das feinabgestimmte FLAN-T5 XL erreichte oder schlug Zero-Shot-GPT-3.5 bei allen Aufgaben bis auf eine @alizadeh2025open. Wang et al. ließen 2026 sechs LLMs etwa 97 700 X-Posts zu Wahlen labeln: Das beste Modellpaar erreichte $kappa$ zwischen 0.75 (Verschwörung) und 0.53 (Satire), die mittlere paarweise Übereinstimmung der MTurk-Worker lag bei 0.43 bis 0.16. Der Vergleich ist allerdings nicht gleichwertig, denn er stellt das _beste_ LLM-Paar dem _mittleren_ Menschenpaar gegenüber @wang2026wisdom. Dass Modelle untereinander stärker übereinstimmen als Menschen, ist zudem eher ein Hinweis auf geteilte Vorannahmen aus dem Pretraining als auf Validität.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let rows = (
      ([Reiss 2023: $alpha$ zwischen Instruktionen], 0.24, 0.70, 0.43, c-red),
      ([Ziems 2024: $kappa$ (8 von 17 Aufgaben)], 0.40, 0.65, none, c-yellow),
      ([Rathje 2024: $r$ mit manuellen Ratings], 0.59, 0.77, none, c-blue),
      ([Rathje 2024: Test-Retest $kappa_w$], 0.93, 0.99, none, c-blue),
      ([Dunivin 2025: $kappa$ pro Code (GPT-4)], 0.30, 1.00, 0.68, c-teal),
      ([Bergmann 2026: ARI Codes pro Variable], 0.35, 0.85, 0.61, c-violet),
      ([Bergmann 2026: ARI Themen pro Variable], 0.31, 0.70, 0.54, c-violet),
      ([Wang 2026: bestes LLM-Paar $kappa$], 0.53, 0.75, none, c-accent),
      ([Wang 2026: mittleres MTurk-Paar $kappa$], 0.16, 0.43, none, c-grey),
    )
    let W = 8.0
    for (i, (lab, lo, hi, mid, col)) in rows.enumerate() {
      let y = -i * 0.55
      content((-0.2, y), anchor: "east", text(font: "Inter", size: 7pt, lab))
      line((lo * W, y), (hi * W, y), stroke: 2.4pt + col.lighten(20%))
      circle((lo * W, y), radius: 0.06, fill: col, stroke: none)
      circle((hi * W, y), radius: 0.06, fill: col, stroke: none)
      if mid != none { rect((mid * W - 0.05, y - 0.15), (mid * W + 0.05, y + 0.15), fill: c-dark, stroke: none) }
    }
    let yb = -rows.len() * 0.55 + 0.1
    line((0, yb), (W, yb), stroke: 0.6pt + c-dark)
    for t in (0, 0.2, 0.4, 0.6, 0.8, 1.0) {
      line((t * W, yb), (t * W, yb - 0.1), stroke: 0.6pt + c-dark)
      content((t * W, yb - 0.3), text(font: "Inter", size: 7pt, str(t)))
      line((t * W, yb), (t * W, 0.3), stroke: (paint: luma(220), thickness: 0.4pt, dash: "dotted"))
    }
  }),
  caption: [Spannweiten berichteter Übereinstimmungswerte aus ausgewählten Studien (Striche: Minimum bis Maximum, schwarze Marke: berichteter Mittel- bzw. Gesamtwert). Die Maße sind nicht direkt vergleichbar; die Abbildung zeigt die Streuung, nicht ein Ranking @reiss2023testing @ziems2024can @rathje2024gpt @dunivin2025scaling @bergmann2026llms @wang2026wisdom.],
) <k05-fig-spannweiten>

=== Die Folgen für Schlussfolgerungen

#studie(titel: [Baumann et al. 2025 (Preprint)])[
  *Design:* 37 Annotationsaufgaben aus 21 Datensätzen und Studien, 18 LLMs von 4 Anbietern, 199 Prompts, 2361 Hypothesen, etwa 13 Millionen Annotationen und 1.4 Millionen Regressionen; Literaturreview mit 93 von 1592 gesichteten Papers; 21 Mitigationsstrategien. \
  *Befund:* Das Risiko einer falschen Schlussfolgerung liegt bei großen Modellen um 31 bis 32 % (GPT-4o 0.312, Llama-3.1-70B 0.316) und bei 1B-Modellen um 50 %. Gezieltes Hacking ist machbar: Typ-I-Fehler für 94.4 % der Nullhypothesen, Typ-II-Fehler für 98.1 % der echten Effekte, Typ-S-Fehler für 68.3 %. Höherer F1 senkt das Risiko nur schwach (Korrelationen pro Aufgabe etwa $-0.02$ bis $-0.46$); manche Aufgaben mit F1 über 0.93 hatten ein Risiko über 50 %. Die menschliche Übereinstimmung einer Aufgabe korrelierte nicht signifikant mit dem Risiko. \
  *Menschliche Baselines:* Eine rein menschliche Annotation mit etwa 100 Labels (ohne LLM-Labels) hält den Typ-I-Fehler bei etwa 10 %, gegenüber 30 bis 40 % für unkorrigierte Mensch-LLM-Hybride; ausschließlich 1000 menschliche Labels senken das Gesamtrisiko auf etwa 20 % @baumann2025large.
]

Diese Studie verschiebt die Frage von "Sind die Labels gut?" zu "Ist die Schlussfolgerung richtig, die ich aus den Labels ziehe?". Wir kommen in @k05-validierung darauf zurück; die statistischen Korrekturverfahren selbst behandelt Kapitel 6.

#hoersaal([Gilardi et al. sagen doch, ChatGPT sei besser als Crowdworker. Warum dann der ganze Aufwand?],
[Weil die Aussage enger ist, als sie klingt. Sie gilt für Genauigkeit gegenüber trainierten Studierenden, gemessen nur auf Items, bei denen sich zwei von ihnen einig waren, für bestimmte Aufgaben und den Modellstand vom Frühjahr 2023 @gilardi2023chatgpt. Sie sagt nichts über schwierige Items, andere Konstrukte, andere Sprachen oder darüber, ob die Labels in einer Regression die richtige Schlussfolgerung liefern. Pangakis et al. zeigen über 27 Aufgaben einen Median-F1 von 0.707, aber ein Minimum von 0.059 @pangakis2023automated, Baumann et al. ein Fehlschlussrisiko um 31 % selbst bei starken Modellen @baumann2025large. Der Aufwand ist der Preis dafür, aus "funktionierte in einer Studie" ein "funktioniert hier" zu machen.])

== Übereinstimmung messen: von der Prozentübereinstimmung zu Fleiss' Kappa <k05-masse>

Übereinstimmungsstatistiken sind in der Inhaltsanalyse der Standardnachweis für Reliabilität, und die LLM-Studien berichten sie in vielen Formen: Prozentübereinstimmung @gilardi2023chatgpt, Krippendorffs $alpha$ @reiss2023testing @tornberg2023chatgpt @hayes2007answering, Cohens $kappa$ @ziems2024can und gewichtetes $kappa$ @rathje2024gpt. Dieser Abschnitt baut die Koeffizienten systematisch auf. Der rote Faden ist eine einzige Beobachtung: Alle zufallskorrigierten Koeffizienten haben dieselbe Form und unterscheiden sich _nur_ darin, was sie als zufällige Übereinstimmung ansehen.

=== Notation

Zwei Codierende A und B ordnen jede von $n$ Einheiten einer von $K$ Kategorien zu. Die Ergebnisse stehen in einer $K times K$-Kontingenztafel $(n_(i j))$ mit den Zeilen für A und den Spalten für B. Wir schreiben

$ p_(i j) = n_(i j) / n, quad p_(i dot) = sum_j p_(i j), quad p_(dot j) = sum_i p_(i j). $ <k05-eq-notation>

Dabei ist $n_(i j)$ die Zahl der Einheiten, die A in Kategorie $i$ und B in Kategorie $j$ eingeordnet hat; $p_(i dot)$ und $p_(dot j)$ sind die Randanteile (Marginalien) von A und B. Für mehr als zwei Codierende brauchen wir später eine zweite Darstellung, die Zähltafel $n_(i k)$ der Codierenden, die Einheit $i$ in Kategorie $k$ gesteckt haben.

=== Prozentübereinstimmung

Das naheliegendste Maß ist der Anteil der Einheiten, bei denen beide dieselbe Kategorie gewählt haben:

$ p_o = sum_(k=1)^K p_(k k). $ <k05-eq-po>

Gilardi et al. verwenden genau dieses Maß als "intercoder agreement", den Anteil der Items, bei denen zwei Annotatoren oder zwei Läufe dasselbe Label vergeben @gilardi2023chatgpt. Sein Problem ist, dass es Übereinstimmung durch Zufall nicht abzieht. Zwei Codierende, die bei zwei gleich häufigen Kategorien rein zufällig labeln, stimmen in 50 % der Fälle überein. Bei einer Kategorie mit 95 % Häufigkeit stimmen zwei Codierende, die jeweils mit Wahrscheinlichkeit 0.95 die häufige Kategorie wählen, schon zufällig in $0.95^2 + 0.05^2 = 0.905$ der Fälle überein. Eine Prozentübereinstimmung von 90 % ist dann schlechter als Raten.

=== Die gemeinsame Form aller zufallskorrigierten Koeffizienten

#satz(titel: [Normierte Übereinstimmung])[
  Sei $p_o$ die beobachtete und $p_e < 1$ eine unter einem Zufallsmodell erwartete Übereinstimmung. Dann ist
  $ "coef" = (p_o - p_e) / (1 - p_e) $ <k05-eq-allgemein>
  die eindeutige affine Transformation von $p_o$, die perfekte Übereinstimmung ($p_o = 1$) auf 1 und zufällige Übereinstimmung ($p_o = p_e$) auf 0 abbildet. Werte unter 0 bedeuten weniger Übereinstimmung als unter dem Zufallsmodell erwartet.
]

#beweis[
  Gesucht ist $g(p_o) = a p_o + b$ mit $g(1) = 1$ und $g(p_e) = 0$. Aus der zweiten Bedingung folgt $b = -a p_e$, aus der ersten $a (1 - p_e) = 1$, also $a = 1 \/ (1 - p_e)$ und $g(p_o) = (p_o - p_e) \/ (1 - p_e)$. Eindeutigkeit folgt, weil eine affine Funktion durch zwei Punkte mit verschiedenen Argumenten festgelegt ist ($p_e != 1$).
]

Die Formel hat eine anschauliche Lesart: Der Nenner $1 - p_e$ ist der Spielraum, den der Zufall für echte Übereinstimmung übrig lässt; der Zähler $p_o - p_e$ ist der Teil davon, den die Codierenden tatsächlich ausgeschöpft haben. Der Koeffizient ist also der _Anteil der über den Zufall hinaus möglichen Übereinstimmung, der realisiert wurde_. Diese allgemeine Form findet sich in der Dokumentation von `cohen_kappa_score` in scikit-learn 1.9.1, die sich auf Cohen und auf die Übersicht von Artstein und Poesio stützt @cohen1960coefficient @artstein2008inter @scikitlearn2026scikitlearn.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 11.0
    rect((0, 0), (W, 0.7), fill: luma(245), stroke: 0.6pt + c-dark)
    rect((0, 0), (0.5 * W, 0.7), fill: c-grey.lighten(55%), stroke: none)
    rect((0.5 * W, 0), (0.85 * W, 0.7), fill: c-teal.lighten(45%), stroke: none)
    rect((0, 0), (W, 0.7), fill: none, stroke: 0.6pt + c-dark)
    content((0.25 * W, 0.35), text(font: "Inter", size: 7.5pt)[Zufall: $p_e = 0.50$])
    content((0.675 * W, 0.35), text(font: "Inter", size: 7.5pt)[realisiert: $p_o - p_e = 0.35$])
    content((0.925 * W, 0.35), text(font: "Inter", size: 7.5pt)[offen])
    for (x, l) in ((0, "0"), (0.5 * W, $p_e$), (0.85 * W, $p_o$), (W, "1")) {
      line((x, 0), (x, -0.15), stroke: 0.6pt + c-dark)
      content((x, -0.4), text(font: "Inter", size: 7.5pt, l))
    }
    line((0.5 * W, 1.0), (W, 1.0), stroke: 0.7pt + c-accent, mark: (start: "|", end: "|"))
    content((0.75 * W, 1.3), text(font: "Inter", size: 7.5pt, fill: c-accent)[Nenner $1 - p_e = 0.50$])
    content((0.5 * W, -1.0), text(font: "Inter", size: 8pt)[$kappa = 0.35 \/ 0.50 = 0.70$: 70 % der über den Zufall hinaus möglichen Übereinstimmung sind realisiert])
  }),
  caption: [Lesart der normierten Übereinstimmung am Rechenbeispiel E1 (unten): Der Koeffizient misst, welcher Anteil des vom Zufall frei gelassenen Spielraums ausgeschöpft wurde.],
) <k05-fig-normierung>

Die Koeffizienten unterscheiden sich nur in $p_e$. @k05-tab-pe fasst die vier Zufallsmodelle zusammen, die wir im Folgenden herleiten.

#figure(
  table(columns: (auto, 1fr, 1fr),
    [Koeffizient], [Zufallsübereinstimmung $p_e$], [Annahme des Zufallsmodells],
    [Cohens $kappa$], [$sum_k p_(k dot) p_(dot k)$], [jede Person labelt unabhängig nach ihrer _eigenen_ Randverteilung],
    [Scotts $pi$, Fleiss' $kappa$], [$sum_k overline(p)_k^2$, $overline(p)_k = (p_(k dot) + p_(dot k)) \/ 2$], [beide ziehen aus einer _gemeinsamen_ Verteilung],
    [Gwets AC1], [$1/(K - 1) sum_k overline(p)_k (1 - overline(p)_k)$], [Zufall nur bei der Teilmenge "schwieriger" Einheiten, kalibriert an der Streuung],
    [Brennan-Prediger, PABAK], [$1 \/ K$], [alle Kategorien gleich wahrscheinlich],
  ),
  caption: [Zufallsmodelle der gängigen Koeffizienten der Form $(p_o - p_e) \/ (1 - p_e)$.],
) <k05-tab-pe>

=== Cohens Kappa

Cohen nimmt an, dass beide Codierenden unabhängig voneinander arbeiten und jede Person ihre eigene Randverteilung hat @cohen1960coefficient. Unter Unabhängigkeit ist die Wahrscheinlichkeit, dass A Kategorie $k$ wählt _und_ B Kategorie $k$ wählt, das Produkt $p_(k dot) p_(dot k)$. Summiert über alle Kategorien ergibt sich

$ p_e^C = sum_(k=1)^K p_(k dot) thin p_(dot k), quad kappa = (p_o - p_e^C) / (1 - p_e^C). $ <k05-eq-kappa>

Das ist dieselbe Rechnung, die dem $chi^2$-Test auf Unabhängigkeit zugrunde liegt: $n p_(k dot) p_(dot k)$ ist die erwartete Häufigkeit in der Diagonalzelle $(k, k)$. Kappa vergleicht also die beobachtete Diagonalsumme mit der Diagonalsumme, die man bei unabhängigem Labeln mit denselben Marginalien erwarten würde.

#beispiel(titel: [E1: Ein LLM gegen eine menschliche Codiererin, binär])[
  $n = 100$ Texte, Mensch in den Zeilen, LLM in den Spalten, Kategorie 1 = relevant, 0 = nicht relevant.
  #align(center, table(columns: 4, align: center,
    [], [LLM = 0], [LLM = 1], [Summe],
    [Mensch = 0], [40], [10], [50],
    [Mensch = 1], [5], [45], [50],
    [Summe], [45], [55], [100]))
  Beobachtete Übereinstimmung: $p_o = (40 + 45) \/ 100 = 0.85$. Cohen: $p_e^C = 0.50 dot 0.45 + 0.50 dot 0.55 = 0.50$, also $kappa = (0.85 - 0.50) \/ 0.50 = 0.700$. Scott: $overline(p) = (0.475, 0.525)$, $p_e^S = 0.475^2 + 0.525^2 = 0.50125$, $pi_S = 0.34875 \/ 0.49875 = 0.699$. Gwet: $p_e^G = 2 dot 0.475 dot 0.525 = 0.49875$, $"AC1" = 0.35125 \/ 0.50125 = 0.701$. PABAK: $2 dot 0.85 - 1 = 0.700$. Bei ausgeglichenen Marginalien liegen alle Koeffizienten innerhalb von 0.002; Unterschiede entstehen erst bei schiefen Verteilungen oder unterschiedlichen Marginalien.
]

Der Wertebereich von $kappa$ wird oft mit $-1$ bis $1$ angegeben. Genau genommen hängt das erreichbare Minimum von den Marginalien ab und liegt in den meisten Tafeln über $-1$. Aus @k05-eq-allgemein folgt nur, dass $kappa >= -p_e \/ (1 - p_e)$ (für $p_o = 0$), und $-1$ wird nur bei $p_e = 0.5$ erreicht.

#zwischentitel[Gewichtetes Kappa]

Bei ordinalen Kategorien ist ein Fehler um eine Stufe weniger schlimm als um vier. Das gewichtete Kappa schreibt @k05-eq-allgemein mit Nichtübereinstimmungsgewichten $w_(i j)$ um:

$ kappa_w = 1 - (sum_(i, j) w_(i j) thin p_(i j)) / (sum_(i, j) w_(i j) thin p_(i dot) thin p_(dot j)). $ <k05-eq-wkappa>

Lineare Gewichte sind $w_(i j) = |i - j|$, quadratische $w_(i j) = (i - j)^2$. In scikit-learn heißen sie `weights="linear"` und `weights="quadratic"`, statsmodels nennt sie Cicchetti-Allison- bzw. Fleiss-Cohen-Gewichte @scikitlearn2026scikitlearn @statsmodels2026statsmodels. Mit $w_(i j) = 1 - delta_(i j)$ (Gewicht 1 für jede Abweichung) erhält man das ungewichtete $kappa$ zurück: Zähler $1 - p_o$, Nenner $1 - p_e^C$, also $1 - (1 - p_o) \/ (1 - p_e^C) = (p_o - p_e^C) \/ (1 - p_e^C)$. Gewichtetes $kappa$ ist damit eine echte Verallgemeinerung, keine eigene Familie, und es zeigt eine zweite Lesart aller Koeffizienten: eins minus das Verhältnis von beobachteter zu erwarteter Nichtübereinstimmung. Genau diese Form wird Krippendorffs $alpha$ annehmen.

=== Scotts Pi

Scott geht von einem anderen Zufallsmodell aus: Beide Codierenden ziehen aus derselben Verteilung der Kategorien, geschätzt als Mittel der beiden Randverteilungen @scott1955reliability:

$ p_e^S = sum_k overline(p)_k^2, quad overline(p)_k = (p_(k dot) + p_(dot k)) / 2, quad pi_S = (p_o - p_e^S) / (1 - p_e^S). $ <k05-eq-scott>

Der Unterschied wirkt kosmetisch, hat aber eine klare Konsequenz, die wir beim Bias-Paradoxon brauchen.

#satz(titel: [Kappa ist mindestens so groß wie Pi])[
  Für jede Kontingenztafel gilt
  $ p_e^S - p_e^C = 1/4 sum_(k=1)^K (p_(k dot) - p_(dot k))^2 >= 0 $ <k05-eq-scott-cohen>
  und damit $kappa >= pi_S$. Für $p_o < 1$ gilt Gleichheit genau dann, wenn beide Codierenden dieselben Marginalien haben.
]

#beweis[
  Schreibe $a_k = p_(k dot)$ und $b_k = p_(dot k)$. Dann ist $overline(p)_k^2 - a_k b_k = (a_k + b_k)^2 \/ 4 - a_k b_k = (a_k - b_k)^2 \/ 4$. Summieren über $k$ liefert @k05-eq-scott-cohen. Für festes $p_o <= 1$ ist $g(p_e) = (p_o - p_e) \/ (1 - p_e)$ in $p_e$ monoton fallend, denn $g'(p_e) = (p_o - 1) \/ (1 - p_e)^2 <= 0$, für $p_o < 1$ sogar streng. Ein kleineres $p_e^C$ ergibt also ein größeres oder gleiches $kappa$, und bei $p_o < 1$ ist $kappa = pi_S$ genau dann, wenn $p_e^C = p_e^S$, also alle $a_k = b_k$.
]

Kappa _belohnt_ damit unterschiedliche Marginalien: Je stärker die beiden Codierenden in ihren Kategorienhäufigkeiten auseinanderliegen, desto kleiner wird $p_e^C$ im Vergleich zu $p_e^S$, und desto höher fällt $kappa$ bei gleicher Diagonale aus. Für LLM-Annotation ist das relevant, weil Modelle oft systematisch verschobene Labelverteilungen haben (@k05-paradoxa).

=== Fleiss' Kappa für mehrere Codierende

Mit mehr als zwei Codierenden gibt es keine einfache Kontingenztafel mehr. Fleiss verallgemeinert Scotts Idee über _Paare_ von Urteilen @fleiss1971measuring. Gegeben sind $N$ Einheiten, jede von $r$ Codierenden beurteilt, und $n_(i k)$ die Zahl der Codierenden, die Einheit $i$ in Kategorie $k$ eingeordnet haben ($sum_k n_(i k) = r$).

*Beobachtete Übereinstimmung pro Einheit.* Unter den $r$ Codierenden einer Einheit gibt es $r(r - 1)$ geordnete Paare. Davon stimmen $sum_k n_(i k)(n_(i k) - 1)$ überein, weil in Kategorie $k$ jede der $n_(i k)$ Personen mit $n_(i k) - 1$ anderen ein übereinstimmendes Paar bildet. Der Anteil übereinstimmender Paare ist

$ P_i = 1 / (r(r - 1)) sum_(k=1)^K n_(i k)(n_(i k) - 1), quad overline(P) = 1 / N sum_(i=1)^N P_i. $ <k05-eq-fleiss-p>

*Zufallsübereinstimmung.* Der Anteil aller Urteile in Kategorie $k$ ist $p_k = sum_i n_(i k) \/ (N r)$. Ziehen zwei Urteile unabhängig aus dieser gemeinsamen Verteilung, stimmen sie mit Wahrscheinlichkeit $sum_k p_k^2$ überein:

$ overline(P)_e = sum_(k=1)^K p_k^2, quad kappa_F = (overline(P) - overline(P)_e) / (1 - overline(P)_e). $ <k05-eq-fleiss>

Für $r = 2$ ist $P_i$ gleich 1 bei Übereinstimmung und 0 sonst, also $overline(P) = p_o$, und $p_k = overline(p)_k$. Fleiss' Kappa mit zwei Codierenden ist daher identisch mit Scotts $pi$, nicht mit Cohens $kappa$, trotz des Namens. statsmodels liefert für E1 mit `fleiss_kappa` den Wert 0.6992, genau Scotts $pi$. Es bietet mit `method="randolph"` zusätzlich Randolphs Free-Marginal-Kappa mit $p_e = 1 \/ K$ an @statsmodels2026statsmodels @randolph2005free; für Fleiss' Kappa gibt es dort keine Varianzschätzung.

#satz(titel: [Randolphs Kappa ist mindestens so groß wie Fleiss' Kappa])[
  Für dieselben Daten gilt $kappa_R >= kappa_F$, wobei $kappa_R$ dasselbe $overline(P)$ mit $p_e = 1 \/ K$ verwendet @warrens2010inequalities.
]

#beweis[
  Nach Cauchy-Schwarz ist $1 = (sum_k p_k dot 1)^2 <= (sum_k p_k^2)(sum_k 1^2) = K sum_k p_k^2$, also $overline(P)_e = sum_k p_k^2 >= 1 \/ K$. Da der Koeffizient für $overline(P) <= 1$ in $p_e$ monoton fällt (Beweis des vorigen Satzes), folgt $kappa_R >= kappa_F$. Gleichheit gilt bei gleichverteilten Kategorien.
]

#beispiel(titel: [E4: Zwei Menschen und ein LLM, drei Kategorien])[
  12 Items, Kategorien 0 = dagegen, 1 = neutral, 2 = dafür:
  #align(center, text(size: 8.5pt, table(columns: 13, align: center, inset: (x: 3.5pt, y: 3.5pt),
    [], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12],
    [H1], [2], [2], [0], [1], [0], [2], [1], [1], [0], [2], [1], [0],
    [H2], [2], [1], [0], [1], [0], [2], [1], [0], [0], [2], [2], [0],
    [LLM], [2], [2], [0], [1], [1], [2], [1], [1], [0], [2], [1], [0])))
  Acht Items sind einstimmig ($P_i = 1$), vier haben eine 2:1-Aufteilung. Für diese gilt $P_i = (2 dot 1 + 1 dot 0) \/ (3 dot 2) = 1 \/ 3$. Damit $overline(P) = (8 + 4 \/ 3) \/ 12 = 0.7778$. Jede Kategorie erhält 12 der 36 Urteile, also $p_k = 1 \/ 3$ und $overline(P)_e = 3 \/ 9 = 1 \/ 3$. Ergebnis: $kappa_F = (0.7778 - 0.3333) \/ 0.6667 = 0.667$. Nur die beiden Menschen ergeben $kappa_F = 0.623$. Paarweises Cohen-$kappa$: H1-H2 0.625, H1-LLM 0.875, H2-LLM 0.510; Prozentübereinstimmung 0.750, 0.917 und 0.667.
]

Das Beispiel trägt eine Lehre, die über die Rechnung hinausgeht. Das LLM stimmt mit H1 besser überein ($kappa = 0.875$), als H1 mit H2 übereinstimmt ($0.625$), mit H2 aber deutlich schlechter ($0.510$). Die Aussage "Mensch-LLM-Übereinstimmung übertrifft Mensch-Mensch-Übereinstimmung" hängt also davon ab, _welcher_ Mensch Referenz ist. Genau das motiviert Verfahren, die jede menschliche Person reihum herauslassen, wie den Alternative Annotator Test in @k05-alttest @calderon2025alternative.

== Krippendorffs Alpha <k05-alpha>

Krippendorffs $alpha$ ist das allgemeinste der klassischen Maße. Es verarbeitet beliebig viele Codierende, fehlende Werte und unterschiedliche Messniveaus, und es ist in der Kommunikationswissenschaft der empfohlene Standard @krippendorff2018content @hayes2007answering. In LLM-Studien dient es sowohl für Mensch-LLM-Übereinstimmung als auch für Übereinstimmung _zwischen LLM-Läufen oder Prompts_ @tornberg2023chatgpt @reiss2023testing; Törnberg empfiehlt es als Stabilitätsmaß über Prompt-Paraphrasen @tornberg2024best.

=== Konstruktion über die Koinzidenzmatrix

Statt einer Kontingenztafel Codierende-mal-Codierende verwendet $alpha$ eine *Koinzidenzmatrix* von Werten. Für jede Einheit $u$ mit $m_u$ vergebenen Werten bildet man alle geordneten Paare von Werten verschiedener Codierender und gewichtet sie mit $1 \/ (m_u - 1)$:

$ o_(c k) = sum_u (\#{(c, k) "-Paare in Einheit" u}) / (m_u - 1), quad n_c = sum_k o_(c k), quad n = sum_c n_c. $ <k05-eq-koinzidenz>

Die Gewichtung sorgt dafür, dass jeder vergebene Wert genau einmal zählt: Ein Wert in einer Einheit mit $m_u$ Werten bildet $m_u - 1$ geordnete Paare, und jedes erhält das Gewicht $1 \/ (m_u - 1)$. Damit ist $n$ die Zahl der _paarbaren_ Werte. Einheiten mit $m_u < 2$ sind nicht paarbar und fallen heraus, so werden fehlende Werte ohne Imputation behandelt. Mit einer Differenzfunktion $delta_(c k)^2$ definiert man

$ alpha = 1 - D_o / D_e, quad D_o = 1/n sum_c sum_k o_(c k) thin delta_(c k)^2, quad D_e = 1 / (n(n - 1)) sum_c sum_k n_c thin n_k thin delta_(c k)^2. $ <k05-eq-alpha>

$D_o$ ist die beobachtete mittlere Nichtübereinstimmung, $D_e$ die erwartete, wenn man die $n$ Werte zufällig zu Paaren zusammenstellt. Der Faktor $n(n - 1)$ statt $n^2$ entspricht dem Ziehen _ohne Zurücklegen_ aus der Urne der paarbaren Werte: Ein Wert kann nicht mit sich selbst gepaart werden. Das ist die kleine Stichprobenkorrektur, die $alpha$ von Scotts $pi$ unterscheidet.

Die Differenzfunktion hängt vom Messniveau ab:

$ delta^2_"nom" = cases(0 & "falls" c = k, 1 & "sonst"), quad delta^2_"int" = (c - k)^2, quad delta^2_"ord" = (sum_(g=c)^k n_g - (n_c + n_k)/2)^2 quad (c < k). $ <k05-eq-delta>

Die ordinale Metrik ist bemerkenswert: Sie misst den Abstand zweier Ränge nicht in Rangstufen, sondern in der Zahl der Werte, die zwischen ihnen liegen. Zwei Kategorien, zwischen denen viele Beobachtungen liegen, sind "weiter auseinander" als zwei, zwischen denen kaum etwas liegt. Das macht $alpha_"ord"$ unabhängig von der Kodierung der Ränge, solange die Reihenfolge stimmt.

#satz(titel: [Zwei Codierende, nominal, keine fehlenden Werte])[
  In diesem Fall gilt
  $ alpha_"nom" = 1 - (n - 1) (sum_(c != k) o_(c k)) / (n^2 - sum_c n_c^2). $ <k05-eq-alpha-nom>
]

#beweis[
  Mit $delta^2_"nom"$ ist $D_o = sum_(c != k) o_(c k) \/ n$ und $D_e = sum_(c != k) n_c n_k \/ (n(n - 1)) = (n^2 - sum_c n_c^2) \/ (n(n - 1))$, weil $sum_(c, k) n_c n_k = n^2$. Einsetzen in $1 - D_o \/ D_e$ ergibt @k05-eq-alpha-nom. Der Beweis benutzt nur die Koinzidenzmatrix, nicht die Zahl der Codierenden: Die Formel gilt deshalb für beliebig viele Codierende und auch mit fehlenden Werten, wenn $n$ die Zahl der paarbaren Werte ist.
]

Für E1 ist $n = 200$ (zwei Werte pro Text), $n_0 = 95$, $n_1 = 105$, und die Nichtdiagonale der Koinzidenzmatrix ist $2(10 + 5) = 30$, weil jede Unstimmigkeit in beiden Reihenfolgen gezählt wird. Also $alpha = 1 - 199 dot 30 \/ (40 thin 000 - 95^2 - 105^2) = 1 - 5970 \/ 19 thin 950 = 0.7008$, knapp über Scotts $pi = 0.6992$.

=== Drei Metriken an einem Beispiel

#beispiel(titel: [E5: Ordinale Ratings 1 bis 5, Mensch gegen LLM])[
  Zehn Items: Mensch $h = (1, 2, 2, 3, 3, 4, 4, 5, 5, 3)$, LLM $l = (1, 2, 3, 3, 4, 4, 5, 5, 4, 2)$. Jedes Item trägt zwei Werte, also $m_u = 2$ und Gewicht 1; jedes Paar $(h_u, l_u)$ wird in beiden Reihenfolgen eingetragen. Das ergibt die Koinzidenzmatrix:
  #align(center, table(columns: 7, align: center,
    [$o_(c k)$], [1], [2], [3], [4], [5], [$n_c$],
    [1], [2], [0], [0], [0], [0], [2],
    [2], [0], [2], [2], [0], [0], [4],
    [3], [0], [2], [2], [1], [0], [5],
    [4], [0], [0], [1], [2], [2], [5],
    [5], [0], [0], [0], [2], [2], [4]))
  Es gibt $n = 20$ paarbare Werte. *Nominal:* Die Nichtdiagonale summiert sich zu 10, also $D_o = 10 \/ 20 = 0.5$; $D_e = (400 - (4 + 16 + 25 + 25 + 16)) \/ (20 dot 19) = 314 \/ 380 = 0.8263$; $alpha_"nom" = 1 - 0.5 \/ 0.8263 = 0.395$. *Intervall:* Alle Abweichungen sind eine Stufe, $delta^2 = 1$, also wieder $D_o = 0.5$; aber $D_e = sum n_c n_k (c - k)^2 \/ 380 = 3.3421$ und $alpha_"int" = 1 - 0.5 \/ 3.3421 = 0.850$. *Ordinal:* Mit @k05-eq-delta ist etwa $delta^2_(2 3) = (4 + 5 - 4.5)^2 = 20.25$ und $delta^2_(1 2) = (2 + 4 - 3)^2 = 9$; man erhält $D_o = 10.6$, $D_e = 66.79$ und $alpha_"ord" = 0.841$.
]

Dieselben Daten liefern 0.395 oder 0.85, je nach Messniveau. Der Unterschied ist kein Rundungseffekt, sondern eine inhaltliche Entscheidung: Nominal zählt jede Abweichung um eine Stufe als vollen Fehler, die beiden anderen Metriken als kleinen. Hayes und Krippendorff zeigen denselben Effekt an ihrem Beispiel mit 5 Beobachtenden, 40 Artikeln und einer Skala von 0 bis 3: ordinales $alpha = 0.7598$, nominales $0.4765$, Intervall-$alpha$ $0.7574$ @hayes2007answering.

#fallstrick[
  Die Python-Bibliothek `krippendorff` (Version 0.9.0) rechnet ohne explizite Angabe auf Intervallniveau; das zuständige Argument heißt `level_of_measurement`. Wer nominale Labels ohne dieses Argument übergibt, berechnet stillschweigend das falsche Maß @castro2017fast. Setze das Messniveau immer explizit und lege es vor der Datenerhebung fest.
]

=== Warum Alpha?

Hayes und Krippendorff nennen fünf Kriterien für ein gutes Reliabilitätsmaß: Beobachtende werden als austauschbar behandelt; das Maß gründet auf den tatsächlich verwendeten Kategorien; es hat eine numerische Skala mit mindestens zwei Punkten, die sinnvoll als Reliabilität interpretierbar sind; es passt zum Messniveau; sein Stichprobenverhalten ist bekannt oder berechenbar @hayes2007answering. Sie argumentieren, dass Prozentübereinstimmung, Bennetts $S$, Scotts $pi$, Cohens $kappa$, Fleiss' $K$ und Cronbachs $alpha$ jeweils mindestens eines verfehlen; bei Scotts $pi$ und Fleiss' $K$ liegt das an Reichweitengrenzen (nur zwei Beobachtende bzw. nur nominal), nicht an falschen Annahmen. Das erste Kriterium ist für die LLM-Annotation besonders interessant: Cohens $kappa$ behandelt die beiden Codierenden als unterscheidbar, mit eigenen Marginalien. Wenn ein LLM und ein Mensch _dieselbe_ Messung liefern sollen, ist Austauschbarkeit die richtige Annahme, und dann sind $pi$ und $alpha$ die passenden Maße.

#datei-fest("alpha_hand.py")[```python
def kripp_alpha(data, level="nominal"):
    """data: Liste von Codierenden, jede eine Liste von Werten (None = fehlend)."""
    units = list(zip(*data))
    values = sorted({v for row in data for v in row if v is not None})
    idx = {v: i for i, v in enumerate(values)}; V = len(values)
    o = [[0.0] * V for _ in range(V)]
    for u in units:
        vals = [v for v in u if v is not None]; m = len(vals)
        if m < 2: continue                                  # nicht paarbar
        for x in range(m):
            for y in range(m):
                if x != y: o[idx[vals[x]]][idx[vals[y]]] += 1 / (m - 1)
    nc = [sum(r) for r in o]; n = sum(nc)
    def d2(c, k):
        if level == "nominal":  return 0.0 if c == k else 1.0
        if level == "interval": return (values[c] - values[k]) ** 2
        lo, hi = min(c, k), max(c, k)                       # ordinal
        return (sum(nc[lo:hi + 1]) - (nc[c] + nc[k]) / 2) ** 2
    Do = sum(o[c][k] * d2(c, k) for c in range(V) for k in range(V)) / n
    De = sum(nc[c] * nc[k] * d2(c, k) for c in range(V) for k in range(V)) / (n * (n - 1))
    return 1 - Do / De
```]

Die Implementierung reproduziert `krippendorff.alpha` für nominale, ordinale und Intervalldaten sowie mit fehlenden Werten auf vier Nachkommastellen; für E4 ergibt sich nominal 0.6759, und wenn das letzte Label von H2 fehlt, 0.6667. Sie eignet sich als Übungsvorlage, weil jede Zeile einer Formel entspricht.

== Gwets AC1, PABAK und die Intraklassenkorrelation <k05-ac1-icc>

=== Gwets AC1

Gwet argumentiert, dass $kappa$ und $pi$ die Zufallsübereinstimmung schlecht schätzen, wenn die Prävalenz eines Merkmals nahe 0 oder 1 liegt @gwet2008computing. Sein Gedankenmodell: Nur ein Teil der Einheiten ist schwer und wird zufällig beurteilt, der Rest wird sicher richtig beurteilt. Zufallsübereinstimmung soll sich nur auf den zufällig beurteilten Anteil beziehen, und dessen Größe kalibriert Gwet an der Streuung der Kategorienanteile. Für $K$ Kategorien ergibt sich

$ "AC1" = (p_o - p_e^G) / (1 - p_e^G), quad p_e^G = 1 / (K - 1) sum_(k=1)^K overline(p)_k (1 - overline(p)_k), $ <k05-eq-ac1>

im binären Fall $p_e^G = 2 hat(p)_+ (1 - hat(p)_+)$ @gwet2008computing. Die Struktur erklärt das Verhalten: $overline(p)_k (1 - overline(p)_k)$ ist die Bernoulli-Varianz der Kategorie $k$. Sie ist maximal bei $overline(p)_k = 1 \/ 2$ und geht gegen 0, wenn eine Kategorie dominiert. Während $p_e^S = sum overline(p)_k^2$ bei schiefer Verteilung gegen 1 wächst, schrumpft $p_e^G$ gegen 0. Im binären Fall gilt sogar exakt $p_e^G = 1 - p_e^S$, weil $overline(p)^2 + (1 - overline(p))^2 = 1 - 2 overline(p)(1 - overline(p))$. Gwets Beispiel: Bei einer beobachteten Übereinstimmung von etwa 94.4 % ist Scotts $pi$ negativ (etwa $-0.029$) @gwet2008computing. Chew et al. haben AC1 deshalb für seltene Codes in ihrem LLM-gestützten Inhaltsanalyse-Workflow gewählt @chew2023llm. Gwet liefert zudem Varianzschätzer per Linearisierung und Jackknife für AC1, $pi$ und $kappa$.

=== PABAK und Brennan-Prediger

Das einfachste Zufallsmodell nimmt alle Kategorien als gleich wahrscheinlich an, $p_e = 1 \/ K$:

$ "BP" = (K p_o - 1) / (K - 1), quad "PABAK" = 2 p_o - 1 quad (K = 2). $ <k05-eq-pabak>

Für $K = 2$ heißt das Maß *PABAK* (_prevalence-adjusted bias-adjusted kappa_) @byrt1993bias. Es ist eine lineare Umskalierung von $p_o$ und enthält deshalb keine Information, die nicht schon in der Prozentübereinstimmung steckt. Das ist zugleich seine Stärke (unempfindlich gegen Prävalenz) und seine Schwäche (blind für Prävalenz). In irrCAC steht es als `CAC(...).bp()` zur Verfügung @fergadis2026irrcac.

=== Intraklassenkorrelation für Scores

Für kontinuierliche oder Likert-Scores verwendet man die *Intraklassenkorrelation* (ICC). Sie zerlegt die Varianz der Scores in einer zweifaktoriellen Varianzanalyse mit $n$ Zielen (Zeilen, die bewerteten Texte) und $k$ Bewertenden (Spalten). Wir folgen den Formen von McGraw und Wong, wie sie pingouin 0.7.0 implementiert @mcgraw1996forming @liljequist2019intraclass @pingouin2026pingouin. Mit dem Gesamtmittel $overline(x)$, Zeilenmitteln $overline(x)_(i dot)$ und Spaltenmitteln $overline(x)_(dot j)$ sind

$ "SS"_R = k sum_i (overline(x)_(i dot) - overline(x))^2, quad "SS"_C = n sum_j (overline(x)_(dot j) - overline(x))^2, quad "SS"_E = "SS"_T - "SS"_R - "SS"_C, $

mit den mittleren Quadraten $"MS"_R = "SS"_R \/ (n - 1)$, $"MS"_C = "SS"_C \/ (k - 1)$, $"MS"_E = "SS"_E \/ ((n - 1)(k - 1))$ und im einfaktoriellen Modell $"MS"_W = ("SS"_T - "SS"_R) \/ (n(k - 1))$. Daraus:

$ "ICC"(A, 1) = ("MS"_R - "MS"_E) / ("MS"_R + (k - 1) "MS"_E + k/n ("MS"_C - "MS"_E)), quad "ICC"(C, 1) = ("MS"_R - "MS"_E) / ("MS"_R + (k - 1) "MS"_E), $ <k05-eq-icc>

$ "ICC"(1, 1) = ("MS"_R - "MS"_W) / ("MS"_R + (k - 1) "MS"_W), $ <k05-eq-icc11>

$ "ICC"(A, k) = ("MS"_R - "MS"_E) / ("MS"_R + ("MS"_C - "MS"_E) \/ n), quad "ICC"(C, k) = ("MS"_R - "MS"_E) / "MS"_R. $ <k05-eq-icc2>

Die Buchstaben tragen die Bedeutung. *A* steht für absolute Übereinstimmung: Ein systematischer Versatz zwischen den Bewertenden (ein LLM, das alles um 0.5 Punkte höher bewertet) erhöht $"MS"_C$ und senkt ICC(A,·). *C* steht für Konsistenz: Versätze werden ignoriert, nur die Rangordnung und die relativen Abstände zählen. Die Formen mit $k$ beziehen sich auf die Reliabilität des _Mittelwerts_ von $k$ Bewertenden, die mit 1 auf eine einzelne Bewertung. Ab pingouin 0.7.0 heißen die Ausgaben `ICC(1,1)`, `ICC(A,1)`, `ICC(C,1)`, `ICC(1,k)`, `ICC(A,k)`, `ICC(C,k)`; älterer Code, der nach `ICC2` oder `ICC3` filtert, muss angepasst werden @pingouin2026pingouin.

#beispiel(titel: [E5 als ICC])[
  Für die E5-Ratings ($n = 10$, $k = 2$) liegen die Spaltenmittel bei 3.2 (Mensch) und 3.3 (LLM). Die Quadratsummen sind $"SS"_R = 29.25$, $"SS"_C = 0.05$, $"SS"_E = 2.45$, $"SS"_T = 31.75$, also $"MS"_R = 29.25 \/ 9 = 3.250$, $"MS"_C = 0.050$, $"MS"_E = 2.45 \/ 9 = 0.272$, $"MS"_W = 2.5 \/ 10 = 0.250$.
  $ "ICC"(C, 1) = (3.250 - 0.272) / (3.250 + 0.272) = 0.845, quad "ICC"(A, 1) = (3.250 - 0.272) / (3.250 + 0.272 + 0.2 (0.050 - 0.272)) = 0.856. $
  Weiter $"ICC"(1, 1) = 0.857$, $"ICC"(A, k) = 0.923$, $"ICC"(C, k) = 0.916$; Pearson $r = 0.846$. Hier ist ICC(A,1) ausnahmsweise größer als ICC(C,1), weil $"MS"_C < "MS"_E$: Der Versatz von 0.1 Punkten ist kleiner als das Rauschen.
]

Für LLM-gegen-Mensch-Ratings sollten ICC(A,1) und ICC(C,1) gemeinsam berichtet werden; eine deutliche Lücke ICC(C,1) > ICC(A,1) zeigt einen systematischen Bias des Modells @pingouin2026pingouin. Pearsons $r$, wie es Rathje et al. für Likert-Ratings berichten @rathje2024gpt, ist ein Konsistenzmaß. Es ignoriert Versätze _und_ Skalenunterschiede: Ein LLM, das jeden menschlichen Wert verdoppelt, hat $r = 1$, stimmt aber nirgends überein.

@k05-tab-e5 stellt alle Kennzahlen für E5 nebeneinander. Die Lehre: Nominale Behandlung ordinaler Daten (ungewichtetes $kappa$, nominales $alpha$) unterschätzt die Übereinstimmung hier etwa um die Hälfte.

#figure(
  table(columns: (1fr, auto, 1fr, auto),
    [Kennzahl], [Wert], [Kennzahl], [Wert],
    [exakte Übereinstimmung], [0.500], [Krippendorff $alpha$ nominal], [0.395],
    [Cohens $kappa$ ungewichtet], [0.367], [Krippendorff $alpha$ ordinal], [0.841],
    [$kappa_w$ linear], [0.648], [Krippendorff $alpha$ intervall], [0.850],
    [$kappa_w$ quadratisch], [0.843], [ICC(1,1) / ICC(A,1) / ICC(C,1)], [0.857 / 0.856 / 0.845],
    [Pearson $r$], [0.846], [ICC(A,k) / ICC(C,k)], [0.923 / 0.916],
  ),
  caption: [Alle Übereinstimmungsmaße für das ordinale Beispiel E5. Werte mit Python nachgerechnet (scikit-learn, krippendorff, pingouin).],
) <k05-tab-e5>

#hoersaal([Welchen Koeffizienten soll ich denn nun nehmen?],
[Den, dessen Zufallsmodell zu deiner Fragestellung passt, und zwar vor dem Blick auf die Daten festgelegt. Für zwei austauschbare Codierende mit nominalen Labels ist $alpha$ (oder $pi$) die Standardwahl @hayes2007answering; für ordinale Daten $alpha_"ord"$ oder quadratisch gewichtetes $kappa$; für Scores ICC(A,1) und ICC(C,1) gemeinsam. Bei seltenen Kategorien berichtest du zusätzlich AC1 oder PABAK und, wichtiger als jeder Koeffizient, die volle Konfusionsmatrix mit Precision und Recall pro Klasse @tornberg2024best @mchugh2012interrater. Einen Koeffizienten nach dem Ergebnis auszusuchen ist eine Form von Researcher Degrees of Freedom.])

== Die Kappa-Paradoxa <k05-paradoxa>

Feinstein und Cicchetti haben 1990 zwei Paradoxa beschrieben, die unter dem Titel "hohe Übereinstimmung, aber niedriges Kappa" bekannt sind @feinstein1990high; ein Begleitartikel trägt den Titel "Resolving the paradoxes" @cicchetti1990high. Gwet gibt eine ausführliche Analyse des Prävalenzparadoxons @gwet2008computing. Beide Paradoxa lassen sich mit wenigen Zeilen Algebra vollständig erklären, und diese Erklärung ist der beste Schutz davor, sie im Hörsaal als Kuriosität abzutun.

=== Das Prävalenzparadoxon

Betrachte eine binäre Aufgabe, bei der beide Codierenden dieselbe Randverteilung haben: Kategorie 0 kommt mit Anteil $p$ vor, Kategorie 1 mit $1 - p$. Die Nichtübereinstimmung $D = 1 - p_o$ verteile sich symmetrisch auf die beiden Nebendiagonalzellen.

#satz(titel: [Kappa bei symmetrischen Marginalien])[
  Unter diesen Annahmen gilt
  $ kappa = 1 - D / (2 p (1 - p)), quad "AC1" = 1 - D / (1 - 2 p (1 - p)). $ <k05-eq-praevalenz>
]

#beweis[
  Bei gleichen Marginalien ist $p_e^C = p_e^S = p^2 + (1 - p)^2 = 1 - 2p(1 - p)$, also $1 - p_e^C = 2p(1 - p)$ und $p_o - p_e^C = (1 - D) - 1 + 2p(1 - p) = 2p(1 - p) - D$. Division ergibt die erste Formel. Für AC1 ist im binären Fall $p_e^G = 2p(1 - p) =: g$, also $"AC1" = (1 - D - g) \/ (1 - g) = 1 - D \/ (1 - g)$.
]

Die Formel zeigt den Mechanismus ohne Umweg: $kappa$ teilt die beobachtete Nichtübereinstimmung $D$ durch die _erwartete_ Nichtübereinstimmung $2p(1 - p)$. Diese ist die Wahrscheinlichkeit, dass zwei zufällig gezogene Labels verschieden sind, und sie schrumpft gegen 0, wenn eine Kategorie dominiert. Dieselben zehn Unstimmigkeiten von hundert wiegen dann immer schwerer, bis $kappa$ bei $D = 2p(1 - p)$ null wird; für $D = 0.1$ ist das bei $p approx 0.947$ der Fall. AC1 teilt dagegen durch $1 - 2p(1 - p)$, eine Größe, die bei schiefer Verteilung gegen 1 _wächst_, sodass AC1 gegen $1 - D = p_o$ strebt. Beide Koeffizienten beantworten verschiedene Fragen: $kappa$ fragt, wie viel besser als ein Zufallsprozess mit derselben Prävalenz die Codierenden sind; AC1 fragt, wie oft sie übereinstimmen, wenn man unterstellt, dass leichte Fälle nicht zufällig sind.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 9.0
    let H = 5.0
    let x0 = 0.5
    let x1 = 0.95
    let ymin = -0.2
    let ymax = 1.0
    let X(p) = (p - x0) / (x1 - x0) * W
    let Y(v) = (v - ymin) / (ymax - ymin) * H
    for v in (-0.2, 0, 0.2, 0.4, 0.6, 0.8, 1.0) {
      line((0, Y(v)), (W, Y(v)), stroke: (paint: luma(225), thickness: 0.4pt))
      content((-0.15, Y(v)), anchor: "east", text(font: "Inter", size: 7pt, str(v)))
    }
    for p in (0.5, 0.6, 0.7, 0.8, 0.9, 0.95) {
      line((X(p), 0), (X(p), -0.1), stroke: 0.5pt + c-dark)
      content((X(p), -0.32), text(font: "Inter", size: 7pt, str(p)))
    }
    line((0, Y(0)), (W, Y(0)), stroke: 0.6pt + c-grey)
    let ps = range(0, 46).map(i => 0.5 + i * 0.01)
    let kap = ps.map(p => (X(p), Y(1 - 0.1 / (2 * p * (1 - p)))))
    let ac = ps.map(p => (X(p), Y(1 - 0.1 / (1 - 2 * p * (1 - p)))))
    line(..kap, stroke: 1.4pt + c-accent)
    line(..ac, stroke: 1.4pt + c-teal)
    line((0, Y(0.8)), (W, Y(0.8)), stroke: (paint: c-violet, thickness: 1.2pt, dash: "dashed"))
    for (p, k) in ((0.5, 0.8), (0.9, 0.444), (0.95, -0.053)) {
      circle((X(p), Y(k)), radius: 0.07, fill: c-accent, stroke: none)
    }
    rect((0, 0), (W, H), stroke: 0.5pt + c-dark)
    content((X(0.9) - 0.12, Y(0.444) - 0.12), anchor: "north-east", text(font: "Inter", size: 7pt, fill: c-accent)[E2b: 0.444])
    content((X(0.95) - 0.2, Y(-0.13)), anchor: "east", text(font: "Inter", size: 7pt, fill: c-accent)[E2c: $-0.053$])
    content((X(0.52), Y(0.8) + 0.25), anchor: "west", text(font: "Inter", size: 7pt, fill: c-dark)[E2a: alle 0.80])
    content((W + 0.15, Y(0.89)), anchor: "west", text(font: "Inter", size: 7.5pt, fill: c-teal)[AC1])
    content((W + 0.15, Y(0.8) - 0.1), anchor: "west", text(font: "Inter", size: 7.5pt, fill: c-violet)[PABAK])
    content((W + 0.15, Y(-0.05)), anchor: "west", text(font: "Inter", size: 7.5pt, fill: c-accent)[$kappa = pi$])
    content((W / 2, -0.75), text(font: "Inter", size: 7.5pt)[Prävalenz $p$ der häufigeren Kategorie])
    content((-0.9, H / 2), angle: 90deg, text(font: "Inter", size: 7.5pt)[Koeffizient])
  }),
  caption: [Prävalenzparadoxon nach @k05-eq-praevalenz: Die Prozentübereinstimmung ist überall $p_o = 0.90$. $kappa$ (und das hier identische $pi$) fällt mit wachsender Prävalenz von 0.80 unter null, AC1 steigt leicht, PABAK bleibt konstant. Punkte: die Tafeln E2a bis E2c.],
) <k05-fig-praevalenz>

#beispiel(titel: [E2: Gleiche Prozentübereinstimmung, verschiedene Prävalenz])[
  Alle drei Tafeln haben $p_o = 0.90$, nur die Prävalenz der Kategorie 0 ändert sich (Tafel in Zeilenform $[[a, b], [c, d]]$):
  #align(center, table(columns: 8, align: center,
    [Tafel], [Präv.], [$p_o$], [$kappa$], [$pi$ / Fleiss], [$alpha$], [AC1], [PABAK],
    [E2a [[45,5],[5,45]]], [0.50], [0.90], [0.800], [0.800], [0.801], [0.800], [0.800],
    [E2b [[85,5],[5,5]]], [0.90], [0.90], [0.444], [0.444], [0.447], [0.878], [0.800],
    [E2c [[90,5],[5,0]]], [0.95], [0.90], [$-0.053$], [$-0.053$], [$-0.047$], [0.890], [0.800]))
  Für E2c: $p_e^C = 0.95 dot 0.95 + 0.05 dot 0.05 = 0.905$, also $kappa = (0.90 - 0.905) \/ 0.095 = -0.053$. Dagegen $p_e^G = 2 dot 0.95 dot 0.05 = 0.095$ und $"AC1" = (0.90 - 0.095) \/ 0.905 = 0.890$.
]

In E2c stimmen die Codierenden bei der seltenen Klasse _nie_ überein, Zelle $d$ ist leer. $kappa$ und $alpha$ sagen korrekt, dass es keine Übereinstimmung über das gibt, worauf es ankommt, die Minderheitsklasse. AC1 mit 0.89 verdeckt das. Keiner der beiden Koeffizienten ist "richtig"; sie beantworten verschiedene Fragen. Die praktische Konsequenz ist, immer die volle Konfusionsmatrix oder Precision und Recall pro Klasse zu berichten, nicht nur einen Koeffizienten, genau wie Törnberg es für unbalancierte Kategorien fordert @tornberg2024best. Für die LLM-Annotation ist das zentral, weil viele Aufgaben seltene positive Klassen haben; Pangakis et al. weisen auf größere Validierungsstichproben für Klassen mit Prävalenz unter 1 % hin @pangakis2023automated.

#praxis[
  DeRegnaucourt et al. haben ein menschliches Codebuch mit 49 Codes von GPT-4o deduktiv auf 48 Ausschnitte anwenden lassen. Die mittlere Prozentübereinstimmung lag bei 96 %, das mittlere $kappa$ bei 0.71 (SD 0.26). Die Autorinnen und Autoren weisen selbst darauf hin, dass die Prozentübereinstimmung durch korrekt erkannte _Abwesenheiten_ eines Codes aufgebläht ist @deregnaucourt2026large. Bei Codes, die nur in wenigen Ausschnitten vorkommen, ist das genau die Situation von E2c: Fast alle Entscheidungen lauten "nicht vorhanden", und die Übereinstimmung darüber sagt nichts über die Fähigkeit, das Vorhandensein zu erkennen.
]

=== Das Bias-Paradoxon

Das zweite Paradoxon betrifft unterschiedliche Marginalien. Halte $p_o = 0.60$ fest und lass die Randverteilungen auseinanderlaufen:

#beispiel(titel: [E3: Gleiche Prozentübereinstimmung, unterschiedliche Marginalien])[
  #align(center, table(columns: 8, align: center,
    [Tafel], [Rand A], [Rand B], [$kappa$], [$pi$], [$alpha$], [AC1], [PABAK],
    [E3a [[45,15],[25,15]]], [60/40], [70/30], [0.130], [0.121], [0.125], [0.266], [0.200],
    [E3b [[25,35],[5,35]]], [60/40], [30/70], [0.259], [0.192], [0.196], [0.208], [0.200]))
  In E3b ist $p_e^C = 0.6 dot 0.3 + 0.4 dot 0.7 = 0.46$ und $p_e^S = 0.45^2 + 0.55^2 = 0.505$. Die Differenz $0.045$ ist nach @k05-eq-scott-cohen genau $(0.3^2 + 0.3^2) \/ 4$.
]

$kappa$ _steigt_, wenn die Marginalien der beiden Codierenden auseinanderlaufen, weil $p_e^C$ die eigenen Marginalien jeder Person verwendet und deshalb kleiner wird. Scotts $pi$ und $alpha$ verwenden die gepoolten Marginalien und steigen weniger. Der Satz über $kappa >= pi$ liefert die allgemeine Begründung: Der Abstand ist ein Viertel der quadrierten Differenzen der Marginalien.

Für LLMs ist das keine akademische Frage. Modelle zeigen häufig systematische Labelverschiebungen gegenüber Menschen, etwa eine Übermarkierung neutraler Items als positiv oder negativ @rathje2024gpt oder einen Recall, der in 20 von 27 Aufgaben über der Precision liegt @pangakis2023automated. Eine solche Verschiebung kann $kappa$ _erhöhen_, obwohl sie ein Validitätsproblem ist. Berichte deshalb immer die Marginalien beider Codierenden, und berechne bei austauschbaren Codierenden $pi$ oder $alpha$ statt $kappa$.

#hoersaal([Wenn Kappa so paradox ist, warum verwenden es dann alle?],
[Weil die Paradoxa keine Fehler sind, sondern Konsequenzen einer klar definierten Frage. $kappa$ fragt, wie weit die Codierenden über einen Zufallsprozess mit ihren eigenen Marginalien hinauskommen. Bei extremer Prävalenz ist dieser Zufallsprozess schon sehr gut, und dann ist wenig Raum für echte Übereinstimmung. Das Problem entsteht erst, wenn man $kappa$ ohne Marginalien berichtet und an einer festen Schwelle misst. McHugh empfiehlt deshalb, Prozentübereinstimmung _und_ $kappa$ zu berichten @mchugh2012interrater, und die Debatte zwischen Gwet @gwet2008computing und Hayes und Krippendorff @hayes2007answering zeigt, dass es keinen Koeffizienten gibt, der alle Fragen zugleich beantwortet.])

=== Schwellenwerte und warum sie trügen

Die verbreitetsten Interpretationsbänder für $kappa$ stammen von Landis und Koch: unter 0 schlecht, 0.00 bis 0.20 gering, 0.21 bis 0.40 ausreichend, 0.41 bis 0.60 moderat, 0.61 bis 0.80 substanziell, 0.81 bis 1.00 fast perfekt. Die Autoren selbst nennen diese Einteilung "clearly arbitrary" und bieten sie nur als nützliche Benchmarks an @landis1977measurement. McHugh hält die Bänder für zu großzügig: Jedes $kappa$ unter 0.60 zeige unzureichende Übereinstimmung @mchugh2012interrater. Für $alpha$ werden üblicherweise $alpha >= 0.800$ für verlässliche Daten und $0.667 <= alpha < 0.800$ für vorläufige Schlüsse genannt und auf Krippendorffs Lehrbuch zurückgeführt @krippendorff2018content. Hayes und Krippendorff legen dagegen keinen festen Grenzwert fest, sondern zeigen, wie man die Wahrscheinlichkeit $q$ berechnet, dass das wahre $alpha$ unter einem geforderten Minimum $alpha_min$ liegt; in ihrem Beispiel ist $q = 0.0125$ für $alpha_min = 0.700$ und $q = 0.9473$ für $alpha_min = 0.800$ @hayes2007answering. Reiss und Barrie et al. verwenden 0.8 als Schwelle für Stabilität über Läufe und Prompts @reiss2023testing @barrie2024prompt. pingouin druckt in seiner Dokumentation ICC-Bänder (unter 0.50 schlecht, 0.50 bis 0.75 moderat, 0.75 bis 0.90 gut, über 0.90 exzellent) ohne Primärquelle @pingouin2026pingouin. Im Lehrbuch wird für trainierte Beobachtende ein $kappa > 0.80$ als Ziel genannt @haindl2027research.

Die E2-Tafeln zeigen, warum ein fester Grenzwert ohne Labelverteilung bedeutungslos ist: Dieselbe Prozentübereinstimmung von 90 % ist nach Landis und Koch "substanziell" (0.80), "moderat" (0.44) oder "schlecht" ($-0.05$), je nach Prävalenz. Die bessere Strategie ist, die Mensch-LLM-Übereinstimmung mit der _Mensch-Mensch_-Übereinstimmung auf denselben Items zu vergleichen statt mit einem absoluten Band @tornberg2024best.

#merke[
  Berichte für jede Annotationsaufgabe: $p_o$, die Konfusionsmatrix mit beiden Marginalien, Precision, Recall und F1 pro Klasse, mindestens einen zufallskorrigierten Koeffizienten mit Konfidenzintervall und die Mensch-Mensch-Übereinstimmung auf denselben Items als Vergleichsmaßstab. Lege den Koeffizienten vor der Datenerhebung fest.
]

== Unsicherheit: Konfidenzintervalle und Bootstrap <k05-ci>

Ein Übereinstimmungskoeffizient aus einer Validierungsstichprobe ist eine Schätzung, keine Konstante. Wer $kappa = 0.70$ aus 100 Items berichtet, ohne die Unsicherheit anzugeben, verschweigt, dass derselbe Prozess mit einer anderen Stichprobe ebenso gut 0.58 oder 0.82 hätte liefern können.

=== Asymptotischer Standardfehler

Eine einfache Näherung macht die Struktur sichtbar. Behandelt man $p_e$ als fest (bei großem $n$ schwankt es viel weniger als $p_o$), ist $kappa$ eine lineare Funktion von $p_o$ mit Steigung $1 \/ (1 - p_e)$. $p_o$ ist ein Anteil aus $n$ unabhängigen Bernoulli-Versuchen mit Varianz $p_o (1 - p_o) \/ n$. Daraus folgt

$ "SE"(kappa) approx sqrt(p_o (1 - p_o) \/ n) / (1 - p_e). $ <k05-eq-se>

Für E1 ergibt das $sqrt(0.85 dot 0.15 \/ 100) \/ 0.5 = 0.0714$. statsmodels verwendet in `cohens_kappa` die vollständige asymptotische Formel, die auch die Variabilität von $p_e$ berücksichtigt, und liefert 0.0711 mit dem 95-%-Konfidenzintervall $[0.561, 0.839]$ @statsmodels2026statsmodels. Die Näherung ist also schon sehr gut, und sie zeigt zwei Dinge: Der Standardfehler fällt mit $1 \/ sqrt(n)$, und er wächst mit $1 \/ (1 - p_e)$, also gerade bei schiefen Verteilungen, wo $p_e$ groß ist.

#beispiel(titel: [E6: Validierungsumfang und Intervallbreite])[
  Multipliziert man alle Zellen von E1 mit 4 ($n = 400$), sinkt der Standardfehler auf 0.0355, das Intervall wird $[0.630, 0.770]$, die halbe Breite fällt von 0.139 auf 0.070. Vervierfachen halbiert die Breite. Umgekehrt: Für eine halbe Breite $h$ braucht man nach @k05-eq-se etwa
  $ n approx (1.96^2 thin p_o (1 - p_o)) / (h^2 (1 - p_e)^2) = (3.8416 dot 0.1275) / (0.01 dot 0.25) approx 196 $
  Items für $h = 0.1$ bei den Verhältnissen von E1. statsmodels liefert für $n = 200$ tatsächlich eine halbe Breite von 0.098.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 9.0
    let H = 4.2
    let X(n) = n / 1000 * W
    let Y(v) = v / 0.22 * H
    rect((0, 0), (W, H), stroke: 0.5pt + c-dark)
    for v in (0, 0.05, 0.10, 0.15, 0.20) {
      line((0, Y(v)), (W, Y(v)), stroke: (paint: luma(225), thickness: 0.4pt))
      content((-0.15, Y(v)), anchor: "east", text(font: "Inter", size: 7pt, str(v)))
    }
    for n in (0, 200, 400, 600, 800, 1000) {
      line((X(n), 0), (X(n), -0.1), stroke: 0.5pt + c-dark)
      content((X(n), -0.32), text(font: "Inter", size: 7pt, str(n)))
    }
    let ns = range(0, 39).map(i => 50 + i * 25)
    line(..ns.map(n => (X(n), Y(1.96 * 0.0711 * calc.sqrt(100 / n)))), stroke: 1.3pt + c-blue)
    for (n, h) in ((50, 0.197), (100, 0.139), (200, 0.098), (400, 0.070), (600, 0.057), (800, 0.049), (1000, 0.044)) {
      circle((X(n), Y(h)), radius: 0.07, fill: c-accent, stroke: none)
    }
    line((0, Y(0.1)), (W, Y(0.1)), stroke: (paint: c-grey, thickness: 0.8pt, dash: "dashed"))
    content((X(560), Y(0.1) + 0.25), anchor: "west", text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[halbe Breite 0.1 ab etwa $n = 200$])
    content((X(125), Y(0.165)), anchor: "west", text(font: "Inter", size: 7pt, fill: c-accent)[$n = 100$: $plus.minus 0.139$])
    content((X(415), Y(0.070) + 0.22), anchor: "west", text(font: "Inter", size: 7pt, fill: c-accent)[$n = 400$: $plus.minus 0.070$])
    content((W / 2, -0.75), text(font: "Inter", size: 7.5pt)[Umfang $n$ der Validierungsstichprobe])
    content((-1.0, H / 2), angle: 90deg, text(font: "Inter", size: 7.5pt)[halbe Breite des 95-%-KI])
  }),
  caption: [Halbe Breite des asymptotischen 95-%-Konfidenzintervalls für $kappa$ bei den Verhältnissen von E1 ($p_o = 0.85$, $p_e = 0.50$). Punkte: statsmodels für skalierte Tafeln; Linie: $1 \/ sqrt(n)$-Gesetz durch den Wert bei $n = 100$.],
) <k05-fig-ci>

Die Abbildung erklärt, warum Validierungsstichproben von 50 Items wenig taugen: Ein Intervall von $plus.minus 0.2$ überdeckt auf der Landis-Koch-Skala drei Bänder.

=== Bootstrap-Konfidenzintervalle

Für $alpha$, AC1 und viele andere Koeffizienten sind analytische Varianzformeln umständlich oder fehlen in den Bibliotheken; statsmodels bietet etwa für Fleiss' Kappa keine Varianz an @statsmodels2026statsmodels. Der *Bootstrap* löst das generisch. Die Idee: Man behandelt die Stichprobe als Ersatz für die Population, zieht aus ihr mit Zurücklegen viele neue Stichproben gleicher Größe, berechnet den Koeffizienten für jede und liest das Konfidenzintervall an den Quantilen dieser Verteilung ab. Beim *Perzentil-Bootstrap* mit $B$ Wiederholungen ist das 95-%-Intervall durch das 2.5- und das 97.5-%-Quantil der $B$ Bootstrap-Werte gegeben.

Entscheidend ist die Frage, _was_ man neu zieht. Die Einheit der Unabhängigkeit sind die Texte, nicht die einzelnen Urteile: Zwei Urteile über denselben Text sind abhängig. Der naheliegende Bootstrap zieht deshalb _Einheiten_ mit Zurücklegen und nimmt alle Urteile zu jeder gezogenen Einheit mit. Hayes und Krippendorff bootstrappen in ihrem KALPHA-Makro dagegen _Paare von Urteilen_, in ihrem Beispiel mit 10 000 Wiederholungen @hayes2007answering. Beide Varianten sind in Gebrauch; berichte, welche du verwendet hast.

#datei-fest("bootstrap_alpha.py")[```python
import numpy as np

def alpha_2coders(x, y):
    """Krippendorffs alpha, nominal, zwei Codierende, binär, keine fehlenden Werte."""
    t = np.zeros((2, 2))
    for a, b in zip(x, y): t[a, b] += 1
    o = t + t.T; nc = o.sum(1); N = o.sum()                 # Koinzidenzmatrix
    return 1 - (N - 1) * (o.sum() - np.trace(o)) / (N * N - (nc ** 2).sum())

rng = np.random.default_rng(2026)
a = rng.permutation(np.repeat([0, 1], 50))                  # 100 ausgeglichene Items
b = a.copy(); b[:15] = 1 - b[:15]                           # 15 Labels gekippt
print(alpha_2coders(a, b))                                  # 0.7015

B, n = 2000, len(a)
boot = np.array([alpha_2coders(a[i], b[i])                  # Einheiten mit Zurücklegen
                 for i in (rng.integers(0, n, n) for _ in range(B))])
print(np.percentile(boot, [2.5, 97.5]))                     # [0.542 0.840]
print((boot < 0.667).mean(), (boot < 0.8).mean())           # 0.35  0.93
```]

#beispiel(titel: [E7: Bootstrap für Alpha])[
  Zwei Codierende, 100 ausgeglichene binäre Items, 15 zufällig gekippte Labels (Seed 2026). Das ergibt $alpha = 0.7015$. Der Perzentil-Bootstrap über Einheiten mit $B = 2000$ liefert in diesem Lauf das Intervall $[0.542, 0.840]$; die Wissensbasis der LV berichtet mit einer anderen Zufallsfolge $[0.558, 0.839]$. Die Abweichung in der zweiten Nachkommastelle ist reine Monte-Carlo-Variabilität und verschwindet mit wachsendem $B$. Der Anteil der Bootstrap-Werte unter 0.667 beträgt 0.35, unter 0.800 0.93. Im Sinne von Hayes und Krippendorff ist also mit hoher Wahrscheinlichkeit $alpha < 0.8$, und selbst das Band für vorläufige Schlüsse ist nicht gesichert.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let counts = (0, 1, 3, 8, 22, 22, 35, 94, 146, 173, 204, 275, 344, 213, 170, 145, 84, 29, 16, 13, 3, 0, 0, 0)
    let W = 9.0
    let H = 3.8
    let x0 = 0.40
    let x1 = 1.0
    let X(v) = (v - x0) / (x1 - x0) * W
    let Y(c) = c / 360 * H
    for (i, c) in counts.enumerate() {
      let lo = x0 + i * 0.025
      let inci = lo + 0.0125 >= 0.542 and lo + 0.0125 <= 0.840
      rect((X(lo) + 0.01, 0), (X(lo + 0.025) - 0.01, Y(c)), fill: if inci { c-blue.lighten(25%) } else { c-grey.lighten(40%) }, stroke: none)
    }
    line((0, 0), (W, 0), stroke: 0.6pt + c-dark)
    for v in (0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0) {
      line((X(v), 0), (X(v), -0.1), stroke: 0.5pt + c-dark)
      content((X(v), -0.32), text(font: "Inter", size: 7pt, str(v)))
    }
    for (v, lab, col) in ((0.542, [2.5 %: 0.542], c-accent), (0.840, [97.5 %: 0.840], c-accent), (0.7015, [$hat(alpha) = 0.7015$], c-dark)) {
      line((X(v), 0), (X(v), H + 0.1), stroke: (paint: col, thickness: 1pt, dash: if col == c-dark { none } else { "dashed" }))
      content((X(v), H + 0.35), text(font: "Inter", size: 7pt, fill: col, lab))
    }
    line((X(0.8), 0), (X(0.8), H * 0.75), stroke: (paint: c-violet, thickness: 0.8pt, dash: "dotted"))
    content((X(0.8) + 0.1, H * 0.7), anchor: "west", text(font: "Inter", size: 7pt, fill: c-violet)[$alpha_min = 0.8$: 93 % darunter])
    content((W / 2, -0.75), text(font: "Inter", size: 7.5pt)[Bootstrap-Werte von $alpha$ ($B = 2000$, Klassenbreite 0.025)])
  }),
  caption: [Bootstrap-Verteilung von Krippendorffs $alpha$ für E7. Blau: Klassen innerhalb des Perzentil-Intervalls. Die Verteilung ist leicht linksschief, weil $alpha$ nach oben durch 1 begrenzt ist.],
) <k05-fig-bootstrap>

#fallstrick[
  Bootstrappe nie einzelne Urteile, wenn die Einheiten mehrfach beurteilt wurden, ohne die Abhängigkeit zu berücksichtigen, und berichte immer $B$, die Einheit des Resamplings und den Seed. Ein Bootstrap über Einheiten mit 100 Items kann die Unsicherheit bei sehr seltenen Kategorien unterschätzen, weil manche Bootstrap-Stichproben die seltene Kategorie gar nicht enthalten und der Koeffizient dann nicht definiert ist; scikit-learn bietet für diesen Fall seit Version 1.9 das Argument `replace_undefined_by` @scikitlearn2026scikitlearn.
]

== LLM Hacking und Validierungsdesign <k05-validierung>

Bis hierher ging es darum, Übereinstimmung korrekt zu messen. Jetzt geht es darum, eine Studie so anzulegen, dass die Messung etwas bedeutet. Der Ausgangspunkt ist die Variabilität von LLM-Labels über Konfigurationen.

=== Quellen der Variation

Die Evidenz in @k05-evidenz lässt sich zu vier Quellen verdichten. *Temperatur und Sampling:* Niedrigere Temperatur erhöht die Lauf-zu-Lauf-Übereinstimmung deutlich (GPT-3.5 von 91.7 % auf 97.6 %) @alizadeh2025open; Nichtdeterminismus bleibt aber auch bei Temperatur 0 @rathje2024gpt. *Wiederholung:* Pangakis et al. klassifizierten jede Probe siebenmal bei Temperatur 0.6; voll konsistente Labels waren um 19.4 Punkte genauer, was den Konsistenzwert zu einem brauchbaren Unsicherheitssignal macht @pangakis2023automated. *Prompt-Formulierung:* Reiss fand $alpha$ zwischen 0.24 und 0.70 für semantisch ähnliche Instruktionen @reiss2023testing. *Modellwahl und Version:* Von GPT-3.5 Turbo über GPT-4 zu GPT-4 Turbo stieg der mittlere F1 von 0.571 auf 0.653; proprietäre Modelle ändern sich zudem über die Zeit @rathje2024gpt @tornberg2024best.

Baumann et al. haben gefragt, was diese Variation für Schlussfolgerungen bedeutet (siehe die Studienbox in @k05-evidenz). Ihr wichtigster Befund für das Validierungsdesign ist nicht die Fehlerrate von 31 %, sondern die Zerlegung: Der F1 erklärt nur 7.7 % der erklärten Varianz im Risiko, die Nähe des p-Werts zur Schwelle 0.05 erklärt 10.2 %, die Prompt-Wahl unter 1 % @baumann2025large. Hohe Labelqualität schützt also nur schwach vor falschen Schlüssen, und Ergebnisse knapp an der Signifikanzschwelle sind besonders gefährdet. Die Analogie zum p-Hacking und zum Garten der sich verzweigenden Pfade aus Kapitel 1 ist gewollt: Wer zehn Konfigurationen ausprobiert und die berichtet, die das erwartete Ergebnis liefert, betreibt LLM Hacking, auch ohne Absicht.

#fallstrick[
  Baumann et al. zeigen, dass gezieltes Hacking in 94.4 % der Nullhypothesen einen Typ-I-Fehler erzeugen kann @baumann2025large. Die Gegenmaßnahmen sind dieselben wie gegen p-Hacking: Konfiguration vorab festlegen (idealerweise präregistrieren), alle getesteten Modell-Prompt-Kombinationen berichten, Ergebnisse nahe der Signifikanzschwelle mit Sensitivitätsanalyse absichern und menschliche Labels priorisieren.
]

=== Der Validierungsworkflow

Pangakis et al. schlagen einen Workflow vor, der zum Standard geworden ist @pangakis2023automated. @k05-fig-workflow zeigt ihn mit den Ergänzungen von Törnberg @tornberg2024best.

#figure(
  diagram(spacing: (7mm, 7mm),
    fknoten((0,0), [Codebuch / \ Prompt-Codebuch], col: c-blue, filled: true, w: 28mm),
    edge("-|>"),
    fknoten((1,0), [Zufallsstichprobe, \ von Fachleuten \ gelabelt], col: c-blue, w: 28mm),
    edge("-|>"),
    fknoten((2,0), [Split: Entwicklung \ und gesperrter Test], col: c-violet, w: 28mm),
    edge((2,0), (2,1), "-|>"),
    fknoten((2,1), [LLM labelt \ Entwicklungsteil], col: c-teal, w: 28mm),
    edge((2,1), (1,1), "-|>"),
    fknoten((1,1), [Leistung \ ausreichend?], col: c-yellow, w: 28mm),
    edge((1,1), (0,1), "-|>", label: text(font: "Inter", size: 7pt)[nein], label-side: left),
    fknoten((0,1), [Codebuch \ verfeinern], col: c-grey, w: 28mm),
    edge((0,1), (0,0), "-|>"),
    edge((1,1), (1,2), "-|>", label: text(font: "Inter", size: 7pt)[ja: Prompt einfrieren], label-side: left),
    fknoten((1,2), [Einmaliger Test auf \ gesperrtem Teil], col: c-accent, filled: true, w: 34mm),
    edge("-|>"),
    fknoten((2,2), [Gesamtkorpus labeln, \ alles berichten], col: c-green, w: 30mm),
  ),
  caption: [Validierungsworkflow nach Pangakis et al. @pangakis2023automated mit Törnbergs Regeln @tornberg2024best: erst nach dem Einfrieren des Prompts validieren, nie auf dem Testteil abstimmen.],
) <k05-fig-workflow>

Die Logik entspricht dem Train-Validation-Test-Split des maschinellen Lernens. Der Entwicklungsteil dient dazu, Codebuch und Prompt zu verbessern, und ist danach "verbraucht". Der Testteil wird genau einmal verwendet, nachdem alles eingefroren ist. Wer auf dem Testteil iteriert, überschätzt die Qualität aus demselben Grund, aus dem ein auf den Testdaten abgestimmtes Modell überschätzt wird.

=== Fünf Protokolle für LLM-spezifische Übereinstimmung

Aus den verifizierten Quellen ergeben sich fünf Prüfungen, die jeweils eine andere Frage beantworten.

+ *LLM gegen menschliche Referenz (Validitätsersatz).* Vergleich auf einer zufälligen, zurückgehaltenen Teilmenge mit Precision, Recall, F1 und einem zufallskorrigierten Koeffizienten; Genauigkeit allein ist bei unbalancierten Klassen unbrauchbar; Vergleichsmaßstab ist die Mensch-Mensch-Übereinstimmung auf denselben Items @pangakis2023automated @tornberg2024best.
+ *Konsistenz innerhalb des Modells (Test-Retest).* Identischer Prompt, mehrere Läufe. Gilardi et al. verwendeten zwei Läufe pro Temperatur @gilardi2023chatgpt, Pangakis et al. sieben Läufe und nutzten den Konsistenzwert pro Item, um unsichere Items zur menschlichen Prüfung auszusteuern @pangakis2023automated; Rathje et al. berichten gewichtetes $kappa$ von 0.93 bis 0.99 für Läufe einen Tag auseinander @rathje2024gpt.
+ *Prompt-Stabilität.* Mehrere Paraphrasen der Instruktion, $alpha$ über die Paraphrasen. Barrie et al. formalisieren das als *Intra-PSS* ($alpha$ über wiederholte Läufe desselben Prompts) und *Inter-PSS* ($alpha$ über automatisch erzeugte Paraphrasen bei wachsender Paraphrasier-Temperatur). In 6 Datensätzen mit 12 Zielgrößen lag Intra-PSS meist über 0.8, Inter-PSS fiel mit der Paraphrasier-Temperatur, und manche Zielgrößen degradierten schon bei kleinen Umformulierungen. Ihre Faustregel: unter 0.8 genauer hinsehen @barrie2024prompt.
+ *Übereinstimmung zwischen Modellen, Multiversum.* Mehrere Modelle und Prompts, Bericht darüber, wie die Schlussfolgerungen über Konfigurationen variieren @baumann2025large @tornberg2024best.
+ *Ersetzungstest.* Wer behaupten will, ein LLM könne Annotatoren _ersetzen_, prüft es gegen jede menschliche Person in einem Leave-one-out-Design mit explizitem Kosten-Nutzen-Spielraum: der Alternative Annotator Test.

Hinzu kommt ein sechster Punkt, der über die Labels hinausgeht: Übereinstimmung auf Labelebene garantiert keine korrekten Regressionskoeffizienten oder Hypothesentests @baumann2025large. Korrekturschätzer wie PPI, DSL und CDI und ihren Zielkonflikt zwischen Typ-I- und Typ-II-Fehler behandelt Kapitel 6.

=== Wie groß muss die Validierungsstichprobe sein?

Die Empfehlungen in den verifizierten Quellen unterscheiden sich um eine Größenordnung (@k05-tab-stichprobe). Das ist kein Widerspruch, sondern spiegelt unterschiedliche Zwecke: Törnbergs Mindestzahl pro Kategorie zielt auf eine grobe Fehleranalyse, Pangakis' Spanne auf stabile Leistungsschätzung, Calderons Zahl auf die Teststärke eines bestimmten Tests.

#figure(
  table(columns: (auto, 1fr),
    [Quelle], [Empfehlung],
    [Törnberg 2024], [mindestens 20 bis 30 Validierungsfälle _pro Kategorie_; Poweranalyse erwägen; erst nach Fertigstellung des Prompts validieren; Teilmengen (Sprachen, Kontexte) getrennt validieren @tornberg2024best],
    [Pangakis et al. 2023], [250 bis 1250 Zufallsproben; mehr für seltene Klassen (Prävalenz unter 1 %); Split in Entwicklungs- und Testteil @pangakis2023automated],
    [Alizadeh et al. 2025], [100 bis 250 Items von Hand zur Validierung; für Feinabstimmung genügen 50 Beispiele bei GPT-3.5, etwa 250 bei offenen Modellen @alizadeh2025open],
    [Calderon et al. 2025], [Alternative Annotator Test: mindestens 30 Instanzen, in den meisten Fällen 50 bis 100; 100 bis 150 bei $epsilon = 0.1$ @calderon2025alternative],
    [Baumann et al. 2025], [rein menschliche Annotation mit etwa 100 Labels (ohne LLM-Labels) hält den Typ-I-Fehler bei etwa 10 % gegenüber 30 bis 40 % für unkorrigierte Hybride; ausschließlich 1000 menschliche Labels senken das Gesamtrisiko auf etwa 20 % @baumann2025large],
  ),
  caption: [Empfehlungen zum Umfang der menschlichen Validierungsstichprobe. Die Baumann-Zahlen sind rein menschliche Baselines, keine Aussagen über LLM-plus-Korrektur.],
) <k05-tab-stichprobe>

Daraus lassen sich praktische Regeln ableiten. Ziehe die Validierungsmenge zufällig aus dem Zielkorpus @pangakis2023automated; wenn du seltene Klassen überproportional ziehst, gewichte bei Populationskennzahlen mit den Schichtgewichten zurück (ein Standardschritt der geschichteten Stichprobe). Lass jedes Validierungsitem von mindestens zwei, besser drei Menschen codieren, damit Mensch-Mensch-Übereinstimmung und Alternative Annotator Test berechenbar sind @tornberg2024best @calderon2025alternative. Plane den Umfang nach der Präzision, die du brauchst, über @k05-eq-se. Vermeide öffentliche gelabelte Benchmarks als Validierungsmenge @tornberg2024best.

=== Der Alternative Annotator Test <k05-alttest>

Calderon, Reichart und Dror haben 2025 ein Verfahren vorgeschlagen, das eine präzise Frage beantwortet: Darf ich eine Gruppe menschlicher Annotatoren durch ein LLM ersetzen, ohne Gold-Labels zu besitzen @calderon2025alternative? Die Grundidee: Statt das LLM mit einer Wahrheit zu vergleichen, die man nicht hat, vergleicht man es mit jedem einzelnen Menschen _relativ zu den übrigen Menschen_. Ist das LLM mindestens so gut darin, mit der Gruppe übereinzustimmen, wie das Gruppenmitglied, das es ersetzen soll, abzüglich eines Spielraums $epsilon$?

#definition(titel: [Alternative Annotator Test])[
  Gegeben sind $m >= 3$ menschliche Annotatoren $h_1, dots, h_m$, ein LLM $f$ und $n$ Instanzen.
  + *Alignment.* Für Instanz $i$ und herausgelassene Person $j$ ist $S_i (f, j)$ die Übereinstimmung von $f$ mit den übrigen Annotatoren ${h_l}_(l != j)$ und $S_i (h_j)$ die Übereinstimmung von $h_j$ mit denselben übrigen. Für diskrete Labels ist das die Genauigkeit (Anteil übereinstimmender Labels), für kontinuierliche $-"RMSE"$, für Freitext ein Ähnlichkeitsmaß.
  + *Indikatoren.* $W_(i j)^f = bb(1)[S_i (f, j) >= S_i (h_j)]$ und $W_(i j)^h = bb(1)[S_i (h_j) >= S_i (f, j)]$; *Vorteilswahrscheinlichkeiten* $rho_j^f = 1/n sum_i W_(i j)^f$ und $rho_j^h = 1/n sum_i W_(i j)^h$.
  + *Hypothesen* pro $j$: $H_0: rho_j^f <= rho_j^h - epsilon$ gegen $H_1: rho_j^f > rho_j^h - epsilon$. Mit $d_(i j) = W_(i j)^h - W_(i j)^f$ ist $t_j = (overline(d)_j - epsilon) \/ (s_j \/ sqrt(n))$, einseitig; bei $n < 30$ Wilcoxon-Vorzeichen-Rang-Test.
  + *Multiples Testen.* Benjamini-Yekutieli-Kontrolle der False Discovery Rate bei $q = 0.05$ über die $m$ p-Werte (BY, weil die Hypothesen abhängig sind).
  + *Entscheidung.* Gewinnrate $omega = 1/m sum_j bb(1)[H_(0 j) "verworfen"]$; das LLM besteht bei $omega >= 0.5$. Die mittlere Vorteilswahrscheinlichkeit $rho = 1/m sum_j rho_j^f$ dient zum Vergleich mehrerer LLMs.
]

Die Hypothese verdient einen zweiten Blick. Weil $overline(d)_j = rho_j^h - rho_j^f$, ist $H_0$ äquivalent zu $overline(d)_j >= epsilon$ in der Population, und die Teststatistik prüft, ob die mittlere Differenz signifikant _unter_ $epsilon$ liegt. Das ist ein Nichtunterlegenheitstest: Das LLM muss nicht besser sein als der Mensch, es darf um höchstens $epsilon$ schlechter sein. Die Indikatoren sind so definiert, dass Gleichstände beiden zugutekommen ($W^f = W^h = 1$, $d = 0$); nur echte Siege einer Seite zählen.

#figure(
  diagram(spacing: (6mm, 7mm),
    fknoten((0,0), [$m >= 3$ Menschen, \ LLM, $n$ Instanzen], col: c-blue, filled: true, w: 30mm),
    edge("-|>"),
    fknoten((1,0), [Person $j$ \ herauslassen], col: c-blue, w: 26mm),
    edge("-|>"),
    fknoten((2,0), [$S_i (f, j)$ und $S_i (h_j)$ \ gegen die übrigen], col: c-teal, w: 32mm),
    edge((2,0), (2,1), "-|>"),
    fknoten((2,1), [$W^f$, $W^h$, $rho_j^f$, \ $d_(i j) = W^h - W^f$], col: c-teal, w: 32mm),
    edge((2,1), (1,1), "-|>"),
    fknoten((1,1), [einseitiger Test \ $overline(d)_j < epsilon$?], col: c-violet, w: 26mm),
    edge((1,1), (0,1), "-|>"),
    fknoten((0,1), [BY-Korrektur \ über $m$ p-Werte], col: c-violet, w: 30mm),
    edge((0,1), (0,2), "-|>"),
    fknoten((0,2), [$omega >= 0.5$: \ LLM besteht], col: c-accent, filled: true, w: 30mm),
    edge((1,0), (1,1), stroke: (dash: "dashed"), label: text(font: "Inter", size: 7pt)[für jedes $j$], label-side: left),
  ),
  caption: [Ablauf des Alternative Annotator Tests nach Calderon et al. @calderon2025alternative. Der Spielraum $epsilon$ und die Zahl der Instanzen werden vor dem Test festgelegt.],
) <k05-fig-alttest>

Der Spielraum $epsilon$ kodiert, wie viel Qualität man für Kostenersparnis aufzugeben bereit ist. Calderon et al. schlagen als Faustregel 0.2 für Fachleute, 0.15 für geschulte Annotatoren und 0.1 für Crowdworker vor @calderon2025alternative. Dass teurere Menschen einen _größeren_ Spielraum bekommen, ist folgerichtig: Je teurer der Mensch, desto mehr Qualitätsverlust rechtfertigt die Ersparnis. Es ist aber eine normative Setzung, keine empirische Größe.

#beispiel(titel: [Simulierter Alternative Annotator Test])[
  Drei simulierte Menschen mit Sollgenauigkeit 85 % gegenüber einer latenten Wahrheit, 100 binäre Items, Simulation `simulate_annotators` aus dem Notebook (Seed 7; realisiert 0.81, 0.86 und 0.87 für die Menschen, 0.89 bzw. 0.67 für das LLM):
  #align(center, table(columns: 5, align: center,
    [Sollgenauigkeit LLM], [$epsilon$], [$omega$], [$rho$], [besteht?],
    [0.88], [0.10], [1.00], [0.930], [ja],
    [0.88], [0.20], [1.00], [0.930], [ja],
    [0.70], [0.10], [0.00], [0.820], [nein],
    [0.70], [0.20], [0.67], [0.820], [ja]))
  Mit $epsilon = 0.2$ "besteht" ein deutlich schlechteres LLM (Sollwert 70 % gegen 85 %): Gegen zwei der drei Menschen wird $H_0$ verworfen, also liegt $omega = 2 \/ 3$ über der Schwelle 0.5. Der Spielraum $epsilon$ muss deshalb begründet und vor dem Test festgelegt werden.
]

Die eigene Implementierung für diskrete Labels umfasst wenige Zeilen; die Referenzimplementierung der Autoren liegt auf GitHub im Repository `nitaytech/alttest` (Stand: 11. November 2026).

#datei-fest("alt_test.py")[```python
import numpy as np
from scipy import stats
from statsmodels.stats.multitest import multipletests

def alt_test(humans, llm, epsilon=0.15, alpha=0.05):
    """humans: (m x n), llm: (n,). Liefert omega, rho und die p-Werte."""
    humans, llm = np.asarray(humans), np.asarray(llm)
    m, n = humans.shape
    pvals, rho_f = [], []
    for j in range(m):
        rest = np.delete(humans, j, axis=0)
        s_f = (rest == llm).mean(axis=0)         # LLM gegen die übrigen
        s_h = (rest == humans[j]).mean(axis=0)   # Person j gegen die übrigen
        w_f = (s_f >= s_h).astype(float); w_h = (s_h >= s_f).astype(float)
        d = w_h - w_f
        t = (d.mean() - epsilon) / (d.std(ddof=1) / np.sqrt(n))
        pvals.append(stats.t.cdf(t, df=n - 1))   # H1: mean(d) < epsilon
        rho_f.append(w_f.mean())
    reject = multipletests(pvals, alpha=alpha, method="fdr_by")[0]
    return reject.mean(), float(np.mean(rho_f)), pvals
```]

#studie(titel: [Calderon, Reichart & Dror 2025])[
  *Design:* 10 Datensätze (Sprache und Vision-Sprache), 6 LLMs, 4 Prompting-Techniken. \
  *Befund:* Manche LLMs bestehen auf manchen Datensätzen; geschlossene Modelle (GPT-4o, Gemini) schnitten meist besser ab als die getesteten offenen. Zero-Shot bestand auf 8 von 10 Datensätzen mindestens ein LLM, keines auf MT-Bench oder SummEval; mit irgendeiner Prompting-Technik bestand auf neun Datensätzen mindestens eines. Few-Shot verbesserte die meisten Modelle, Chain-of-Thought schadete oft, Ensembles schlugen Few-Shot nicht. Mit $epsilon = 0.2$ bestanden die meisten Fälle vor 100 Instanzen, mit $epsilon = 0.1$ waren 100 bis 150 nötig. \
  *Grenzen:* Mindestens drei Menschen auf denselben Items nötig; Bestehen zeigt Ersetzbarkeit relativ zu _diesen_ Annotatoren, nicht Validität des Konstrukts @calderon2025alternative.
]

#hoersaal([Ist der Alternative Annotator Test nicht einfach ein Weg, ein mittelmäßiges LLM schönzurechnen?],
[Er kann dazu missbraucht werden, wenn $epsilon$ nach dem Ergebnis gewählt wird; das zeigt die Simulation oben. Richtig angewendet ist er das Gegenteil: Er zwingt dazu, die Kosten-Nutzen-Abwägung als Zahl offenzulegen und vorab zu fixieren, er vergleicht mit jedem einzelnen Menschen statt mit einer bequemen Referenzperson, und er kontrolliert multiples Testen. Er beantwortet aber nur die Frage der Austauschbarkeit. Wenn alle drei Menschen dasselbe Konstrukt falsch verstehen, besteht ein LLM, das denselben Fehler macht, den Test trotzdem @calderon2025alternative.])

== Deduktives Codieren mit Codebuch <k05-deduktiv>

Beim deduktiven Codieren liegt das Kategoriensystem fest, und das LLM soll es anwenden. Die zentrale Frage lautet: Folgt das Modell _deinen_ Definitionen oder seiner eigenen, im Pretraining erworbenen Vorstellung des Begriffs?

=== Was die Studien zeigen

#studie(titel: [Xiao et al. 2023])[
  *Design:* 668 neugiergetriebene Fragen von Kindern auf Französisch, unveröffentlichtes Experten-Codebuch für Fragekomplexität (binär) und syntaktische Struktur (4 Kategorien); GPT-3 (davinci-text-002) bei Temperatur 0; Vergleich codebuchzentrierter und beispielzentrierter Prompts, Zero-, One- und Few-Shot. \
  *Befund:* Bestes $kappa$ 0.61 für Komplexität und 0.38 für Syntax, gegenüber Experten-Experten-$kappa$ von 0.88 und 0.90. Codebuchzentrierte Prompts mit Beispielen waren am besten; der größte Gewinn kam beim Schritt von Zero- zu One-Shot. \
  *Grenzen:* Ein Datensatz, ein Schema, ein Modell @xiao2023supporting.
]

#studie(titel: [Chew et al. 2023 (Preprint): LLM-assisted content analysis])[
  *Design:* Workflow in drei Schritten: Codebuch gemeinsam mit dem LLM entwickeln und prüfen, dass die Ausgabe sich von Raten unterscheidet; Mensch-LLM-Reliabilität auf einer Kalibrierungsstichprobe; vollständige Codierung nur bei Nichtunterlegenheit. gpt-3.5-turbo, Temperatur 0, vier Datensätze, je 100 Benchmark-Dokumente; Übereinstimmung mit Gwets AC1, weil $kappa$ bei seltenen Codes irreführt. \
  *Befund:* Mensch-Mensch- und Mensch-Modell-AC1 waren für die meisten Codes vergleichbar (BBC 0.76 gegen 0.85; Klimabehauptungen 0.65 gegen 0.59). Formatierungs-Codes scheiterten (Hashtags 0.96 gegen 0.18; Großschreibung 0.93 gegen 0.36), was die Autoren auf die Tokenisierung zurückführen. Codierzeit pro Dokument bei BBC 72 Sekunden (Mensch) gegen 4 Sekunden. Die vom Modell angegebenen Begründungen deckten Halluzinationen und Mehrdeutigkeiten im Codebuch auf, sind aber keine getreue Beschreibung des internen Prozesses @chew2023llm.
]

Das Hashtag-Beispiel ist didaktisch wertvoll: Für Codes, die an der Oberfläche des Textes hängen, ist ein regulärer Ausdruck einem LLM überlegen. Nicht jede Codierung braucht ein Sprachmodell.

#studie(titel: [Dunivin 2025])[
  *Design:* NYT-Passagen, die W.E.B. Du Bois erwähnen (1970 bis 2023); 232 Passagen, Goldstandard aus 111 Passagen, 9 interpretative Codes in 3 Kategorien; gpt-4-1106-preview und GPT-3.5; Prompts pro Code gegen ganzes Codebuch, mit und ohne Begründung. \
  *Befund:* GPT-4 mit Begründung: $kappa$ pro Code zwischen 0.30 und 1.00; 3 Codes mit $kappa >= 0.79$, 8 von 9 mit $kappa >= 0.60$ (einer davon genau 0.60). Begründungen hoben das mittlere $kappa$ von 0.59 auf 0.68 (Prompts pro Code) und von 0.46 auf 0.60 (ganzes Codebuch); GPT-3.5 von 0.29 auf 0.34. Prompts pro Code schlugen Prompts mit dem ganzen Codebuch. Few-Shot-Beispiele störten bei absatzlangen Passagen. \
  *Grenzen:* Ein Korpus, ein Codebuch, kleiner Goldstandard von den Codebuch-Autoren selbst; nicht empfohlen für kleine Interviewdatensätze @dunivin2025scaling.
]

Dunivin leitet daraus Regeln für die Anpassung eines Codebuchs an ein LLM ab @dunivin2025scaling: Kernpunkte zuerst; Gebote statt Verbote formulieren; den Interpretationsspielraum explizit festlegen (nur explizite oder auch implizite Erwähnungen); einen Code pro Prompt; vierstufiger Prompt aus Rolle, Definition, Begründung und Entscheidung als JSON; jede neue Modellversion erneut validieren.

#studie(titel: [Halterman & Keith 2026])[
  *Design:* Drei Codebücher mit veröffentlichten Daten (Proteste CCC mit 8 Klassen, politische Gewalt in Pakistan BFRS mit 12 Klassen, Manifeste mit 142 Klassen); vier offene Modelle (Mistral-7B, Mistral-NeMo-12B, Llama-3.1-8B, OLMo-7B); fünfstufiges Rahmenwerk: Stufe 0 Codebuch-Aufbereitung, Stufe 1 labelfreie Verhaltenstests, Stufe 2 Zero-Shot-Evaluation, Stufe 3 Fehleranalyse mit labelpflichtigen Tests, Stufe 4 Instruction Tuning mit QLoRA. \
  *Befund:* Alle Modelle reagierten auf die Kategorienreihenfolge. Zero-Shot gewichteter F1 im umstrukturierten Codebuchformat: BFRS 0.53 bis 0.57, CCC 0.61 bis 0.65, Manifeste 0.15 bis 0.19 (im Originalformat erreichten die Manifeste bis 0.21). Die Modelle scheiterten an Tests zu Ausschlusskriterien und stützten sich auf die Semantik der Labelnamen. Mistral-7B war bei 45 % der Manifest-Stichprobe nicht formattreu. Instruction Tuning: BFRS 0.82, CCC 0.72, Manifeste 0.38. \
  *Grenzen:* Nur kleine offene Modelle @halterman2026codebook.
]

Die Verhaltenstests von Halterman und Keith sind billige, labelfreie Prüfungen, die jede Studie übernehmen kann: Bleibt die Ausgabe innerhalb der erlaubten Labels? Kann das Modell die Definitionen wiedergeben? Ist das Ergebnis invariant gegenüber der Reihenfolge der Kategorien? Werden Ausschlusskriterien respektiert? Folgt das Modell vertauschten Labelnamen oder seinem eigenen Vorwissen? Der letzte Test ist besonders aufschlussreich: Wenn du "Protest" und "Kundgebung" in den Definitionen vertauschst und das Modell trotzdem nach den Namen statt nach den Definitionen labelt, wendet es nicht dein Codebuch an.

=== Ein Prompt für die Anwendung

Die folgenden Vorlagen sind für die LV aus den zitierten Arbeiten verdichtet, keine wörtlichen Zitate; sie setzen Dunivins vierstufige Struktur um @dunivin2025scaling.

#datei-fest("prompt_anwenden.txt")[```text
Rolle: Du codierst offene Antworten für die Studie {studie}.
Code: {name}
Definition: {Kernpunkte zuerst. Der Code gilt, wenn ... (Gebot).
             Nur explizite Nennungen | auch implizite Hinweise.}
Text: {text}
Begründe zuerst in zwei bis drei Sätzen, ob die Definition erfüllt ist.
Entscheide dann. Antworte nur als JSON:
{"begründung": "...", "vorhanden": true | false}
```]

Drei Gestaltungsentscheidungen stecken darin. Erstens ein Code pro Aufruf, weil das bei Dunivin besser war als das ganze Codebuch @dunivin2025scaling. Zweitens die Begründung _vor_ der Entscheidung, weil die Entscheidung dann auf der Begründung aufsetzt; das hob $kappa$ von 0.59 auf 0.68 @dunivin2025scaling. Drittens strukturierte Ausgabe, weil freie Ausgaben Parsing-Fehler und Formatabweichungen erzeugen @tornberg2024best. Vorsicht ist trotzdem geboten: Atreja et al. fanden, dass die Bitte um Erklärungen die Labelverteilung verschieben kann @atreja2025prompt, und McLaren et al., dass Chain-of-Thought bei einem Reasoning-Modell den F1 senkte @mclaren2026magic. Ob die Begründung hilft, ist für jede Aufgabe auf dem Entwicklungsteil zu prüfen.

#tipp[
  Berichte $kappa$ oder $alpha$ _pro Code_, nicht nur den Mittelwert, und dazu die Prävalenz jedes Codes. DeRegnaucourt et al. berichten mittleres $kappa = 0.71$ mit SD 0.26 und einer Spannweite von 0 bis 1.00; 33 von 49 Codes lagen über 0.60 @deregnaucourt2026large. Der Mittelwert allein hätte verschwiegen, dass ein Drittel der Codes die Schwelle verfehlt. Codes mit niedrigem $kappa$ gehören in die manuelle Nachprüfung.
]

== Induktive Codebuch-Ableitung aus offenen Antworten <k05-induktiv>

Offene Antworten in Befragungen sind die Datenquelle, bei der die Arbeitsersparnis durch LLMs am größten und die methodische Unsicherheit am höchsten ist. Wer 900 Antworten auf die Frage "Was hat Ihre Promotion am stärksten verzögert?" vor sich hat, braucht kein vorgefertigtes Codebuch, sondern eines, das aus diesen Antworten entsteht. Das Lehrbuch nennt die thematische Analyse offener Antworten in Befragungen als Beispiel für eine *Cross-over-Analyse* in Mixed-Methods-Designs, bei der qualitative Daten quantitativ ausgewertet werden und umgekehrt @haindl2027research. Dieser Abschnitt ist der ausführlichste des Kapitels, weil hier die meisten offenen Fragen liegen.

=== Vom offenen Codieren zur LLM-Codierung

Die Grounded Theory beschreibt den induktiven Weg in drei Codierschritten @haindl2027research @Glaser1967 @Charmaz2014. *Offenes Codieren* zerlegt die Daten in Konzepte; die Analyse Zeile für Zeile erzeugt anfangs oft Hunderte Codes, damit jedes Datenstück Aufmerksamkeit bekommt und kein vorschneller Fokus entsteht. *Axiales Codieren* setzt Kategorien mit Unterkategorien in Beziehung und bestimmt Beziehungen und Dimensionen. *Selektives Codieren* integriert die Kategorien um eine Kernkategorie, die das Hauptanliegen der Beteiligten erklärt. Durchgehend halten *Memos* analytische Gedanken fest, und die *theoretische Sättigung* zeigt an, wann die Datenerhebung enden kann: wenn neue Daten keine neuen theoretischen Einsichten mehr erzeugen, was etwas anderes ist als bloße Wiederholung @haindl2027research.

@k05-fig-gt zeigt, wo ein LLM in diesen Prozess eintreten kann. Die rechte Spalte ist eine Zuordnung für dieses Buch, keine Aussage der zitierten Arbeiten.

#figure(
  diagram(spacing: (14mm, 5mm),
    fknoten((0,0), [Offenes Codieren], col: c-blue, filled: true, w: 42mm),
    fknoten((0,1), [Axiales Codieren], col: c-blue, w: 42mm),
    fknoten((0,2), [Selektives Codieren], col: c-blue, w: 42mm),
    fknoten((0,3), [Theoretische Sättigung], col: c-blue, filled: true, w: 42mm),
    edge((0,0), (0,1), "-|>"), edge((0,1), (0,2), "-|>"), edge((0,2), (0,3), "-|>"),
    fknoten((1,0), [LLM schlägt Codes mit \ Belegzitat pro Text vor], col: c-teal, w: 44mm),
    fknoten((1,1), [LLM prüft Duplikate, \ gruppiert Codes zu Themen], col: c-teal, w: 44mm),
    fknoten((1,2), [bleibt interpretative \ Entscheidung des Menschen], col: c-accent, w: 44mm),
    fknoten((1,3), [Zählen, wie viele neue \ Codes jeder Text bringt], col: c-teal, w: 44mm),
    edge((0,0), (1,0), stroke: (dash: "dashed")), edge((0,1), (1,1), stroke: (dash: "dashed")), edge((0,2), (1,2), stroke: (dash: "dashed")), edge((0,3), (1,3), stroke: (dash: "dashed")),
  ),
  caption: [Grounded-Theory-Codierung nach dem Lehrbuch @haindl2027research (links) und mögliche Einstiegspunkte eines LLM (rechts). Die Kernkategorie und die Theoriebildung bleiben beim Menschen.],
) <k05-fig-gt>

Die Zuordnung macht eine Asymmetrie sichtbar, die sich durch die gesamte Evidenz zieht: LLMs sind deutlich zuverlässiger beim _Anwenden_ eines Codebuchs als beim _Ableiten_ eines Codebuchs, das dem eines menschlichen Teams entspricht @deregnaucourt2026large. Das Ableiten verlangt genau die Leistungen, die im selektiven Codieren stecken: Relevanz beurteilen, abstrahieren, eine Perspektive einnehmen.

=== Ein Workflow in sieben Schritten

Aus den verifizierten Studien lässt sich ein Workflow synthetisieren, in dem das LLM in den Schritten 2 und 3 vorschlägt und der Mensch in den Schritten 4, 5 und 7 entscheidet (@k05-fig-workflow-induktiv).

#figure(
  diagram(spacing: (5mm, 8mm),
    fknoten((0,0), [1\. Analyseeinheit \ festlegen], col: c-blue, filled: true, w: 36mm),
    edge("-|>"),
    fknoten((1,0), [2\. Codes mit \ Belegzitat erzeugen], col: c-teal, w: 36mm),
    edge("-|>"),
    fknoten((2,0), [3\. Duplikate gegen \ laufendes Codebuch], col: c-teal, w: 36mm),
    edge("-|>"),
    fknoten((3,0), [4\. Mit menschlichem \ Codierer verhandeln], col: c-accent, w: 36mm),
    edge((3,0), (3,1), "-|>"),
    fknoten((3,1), [5\. Themen bilden, \ Codebuch einfrieren], col: c-accent, w: 36mm),
    edge((3,1), (2,1), "-|>"),
    fknoten((2,1), [6\. Deduktiv anwenden, \ pro Code validieren], col: c-teal, w: 36mm),
    edge((2,1), (1,1), "-|>"),
    fknoten((1,1), [7\. Codes mit niedriger \ Übereinstimmung \ prüfen], col: c-accent, filled: true, w: 36mm),
    node((0,1), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[türkis: LLM schlägt vor \ orange: Mensch entscheidet]),
  ),
  caption: [Workflow zur induktiven Codebuch-Ableitung, synthetisiert aus De Paoli & Mathis, Dai et al., Dunivin, Halterman & Keith und DeRegnaucourt et al. @depaoli2025reflections @dai2023llm @dunivin2025scaling @halterman2026codebook @deregnaucourt2026large.],
) <k05-fig-workflow-induktiv>

*Schritt 1: Analyseeinheit festlegen.* Ist die Einheit eine ganze Antwort, ein Satz, ein Ausschnitt oder ein Redebeitrag? Bei offenen Antworten in Befragungen ist die Antwort meist die natürliche Einheit; bei Interviews nicht. DeRegnaucourt et al. nennen die Verwendung von Redebeiträgen statt Sinneinheiten ausdrücklich als Grenze ihres eigenen Designs @deregnaucourt2026large. Die Wahl ist auch statistisch folgenreich: Sie bestimmt, was später eine "Einheit" in Übereinstimmungsmaßen und Bootstrap ist.

*Schritt 2: Initiale Codes erzeugen.* Das LLM bekommt jeden Text oder jeden Ausschnitt einzeln und liefert Codename, Kurzbeschreibung und Belegzitat. De Paoli und Mathis verlangen bis zu 15 Codes pro Interview, jeweils mit Zitat, bei Temperatur 0 @depaoli2025reflections. Nyaaba et al. fordern zusätzlich Belegstellen mit Seitenangabe, damit jeder Code rückverfolgbar bleibt @nyaaba2025optimizing. Rückverfolgbarkeit ist hier mehr als Ordnung: Sie ist die Voraussetzung für das Bestätigungsaudit, das in der qualitativen Forschung jede Aussage auf Rohdaten zurückführt @haindl2027research.

*Schritt 3: Duplikate reduzieren.* Jeder neue Code wird mit dem laufenden Codebuch verglichen, und nur einzigartige Codes werden aufgenommen; De Paoli und Mathis lassen diese Ja-Nein-Prüfung vom LLM selbst durchführen @depaoli2025reflections. Dieser Schritt erzeugt nebenbei die Zählreihen für das Sättigungsmaß weiter unten.

*Schritt 4: Mit einem menschlichen Codierer verhandeln.* Dai et al. führen Diskussionsrunden, in denen Mensch und LLM Zustimmung oder Ablehnung samt Gründen äußern, bis beide zufrieden sind @dai2023llm. Qiao et al. zeigen, dass mehrere Perspektiven, also Codier-Agenten mit unterschiedlichen Identitäten, die Vielfalt der Codes und Themen erhöhen @qiao2025thematic.

*Schritt 5: Themen bilden und das Codebuch einfrieren.* Die Codes werden zu Themen verdichtet, die Definitionen für die LLM-Anwendung nach Dunivins Regeln umformuliert @dunivin2025scaling. Halterman und Keith machen die Umstrukturierung des Codebuchs (Label, Definition, Klarstellungen, positive und negative Beispiele) zu einer menschlich geführten Stufe 0 @halterman2026codebook. Ab hier ist das Codebuch versioniert und eingefroren.

*Schritt 6: Deduktiv anwenden und validieren.* Das eingefrorene Codebuch wird wie in @k05-deduktiv angewendet und auf zurückgehaltenen, menschlich codierten Daten pro Code validiert @dunivin2025scaling @deregnaucourt2026large.

*Schritt 7: Prüfen.* Codes mit niedriger Übereinstimmung und unsichere Passagen werden manuell durchgesehen @dunivin2025scaling @deregnaucourt2026large.

#fallstrick[
  Wird das Codebuch auf denselben Texten abgeleitet und validiert, sind die deduktiven Kennzahlen aufgebläht @deregnaucourt2026large. Teile die Antworten _vor_ Schritt 2 in eine Ableitungsmenge und eine gesperrte Testmenge. Das ist das qualitative Gegenstück zur referenziellen Adäquatheit im Lehrbuch: einen Teil der Rohdaten früh beiseitelegen und die Interpretationen später daran prüfen @haindl2027research. Dunivin rät zudem von LLM-Codierung bei kleinen Datensätzen, etwa einer Handvoll Interviews, ab @dunivin2025scaling.
]

=== Prompts für die Ableitung

Die Vorlagen sind für die LV verdichtet und an die eigene Studie anzupassen. Sie folgen De Paoli und Mathis (Codes mit Zitat, Duplikatprüfung) @depaoli2025reflections, Dai et al. (Verhandlung) @dai2023llm und Nyaaba et al. (Rückverfolgbarkeit) @nyaaba2025optimizing.

#datei-fest("prompt_ableiten.txt")[```text
Du bist qualitative Forscherin. Lies die folgende Antwort auf die Frage
"{frage}" und schlage bis zu {k} Codes vor. Gib für jeden Code einen
kurzen Namen, eine Beschreibung in einem Satz und ein wörtliches Zitat
aus der Antwort, das ihn belegt. Erfinde keine Inhalte, die nicht im
Text stehen. Antworte als JSON-Liste:
[{"code": "...", "beschreibung": "...", "zitat": "..."}]
Antwort-ID: {id}
Antwort: {text}
```]

#datei-fest("prompt_duplikat.txt")[```text
Laufendes Codebuch (Name: Beschreibung):
{codebuch}
Neuer Code: {name}: {beschreibung}
Bedeutet der neue Code im Wesentlichen dasselbe wie ein vorhandener
Code? Antworte als JSON: {"duplikat": true | false, "von": "<Name> | null"}
```]

#datei-fest("prompt_themen.txt")[```text
Hier ist ein Codebuch mit {n} Codes, jeweils mit Beschreibung und
Häufigkeit. Gruppiere die Codes zu höchstens {t} Themen. Gib für jedes
Thema einen Namen, eine Definition mit Einschluss- und Ausschlusskriterium
und die Liste der zugeordneten Codes. Jeder Code gehört zu genau einem
Thema. Nenne Codes, die du keinem Thema zuordnen kannst, separat.
```]

Der Themen-Prompt verlangt ausdrücklich Ein- und Ausschlusskriterien. Das übernimmt die Idee von LLooM, bei dem jedes induzierte Konzept ein Einschlusskriterium trägt und sich dadurch später wie ein deduktiver Code validieren lässt @lam2024concept. Die Forderung "jeder Code gehört zu genau einem Thema" erzeugt eine Partition, die man mit dem Adjusted Rand Index vergleichen kann. Lässt man Mehrfachzuordnung zu, braucht man dafür die Ko-Zuordnungsmatrizen, die Bergmann et al. verwendet haben @bergmann2026llms.

Das folgende Gerüst zeigt den Ablauf der Schritte 2 und 3 mit Zählung für das Sättigungsmaß. Die Funktion `call_llm` steht für einen beliebigen API-Aufruf mit festem Modell-Snapshot, Temperatur 0 und JSON-Ausgabe.

#datei-fest("induktiv.py")[```python
import json

def fill(vorlage, **felder):
    # nicht str.format: die JSON-Beispiele in den Vorlagen enthalten {}
    for k, v in felder.items():
        vorlage = vorlage.replace("{" + k + "}", str(v))
    return vorlage

def derive_codebook(antworten, frage, call_llm, prompt_ableiten,
                    prompt_duplikat, k=5):
    """Schritte 2 und 3: Codes pro Antwort erzeugen, gegen das laufende
    Codebuch deduplizieren und T_k (alle Codes) und U_k (einzigartige) zählen."""
    codebuch, log, T, U = {}, [], [], []
    total = 0
    for aid, text in antworten:
        codes = json.loads(call_llm(fill(prompt_ableiten,
                                         frage=frage, id=aid, text=text, k=k)))
        total += len(codes)
        for c in codes:
            cb = "\n".join(f"{n}: {d}" for n, d in codebuch.items())
            r = json.loads(call_llm(fill(prompt_duplikat,
                codebuch=cb, name=c["code"], beschreibung=c["beschreibung"])))
            if not r["duplikat"]:
                codebuch[c["code"]] = c["beschreibung"]
            log.append({"id": aid, **c, "zugeordnet": r["von"] or c["code"]})
        T.append(total); U.append(len(codebuch))
    return codebuch, log, T, U       # log = Audit-Trail mit Zitat pro Code
```]

Das Log enthält zu jedem Code die Antwort-ID und das Zitat. Es ist der Audit-Trail, aus dem sich jede spätere Aussage auf die Rohdaten zurückführen lässt, und gehört zusammen mit Prompts, Modellversion und Parametern in den Anhang der Studie.

=== Studienlage 2023 bis 2026

#studie(titel: [Dai, Xiong & Ku 2023: LLM-in-the-loop])[
  *Design:* Zwei Datensätze mit offenen Befragungsantworten (Musik-Shuffle mit 35 Antworten, Passwortmanager mit 280, davon 100 für das Codebuch); gpt-3.5-turbo-16k bei Temperatur 0. Der Mensch schreibt 4 bis 8 Beispiele im Chain-of-Thought-Stil, das LLM schlägt feinkörnige Codes vor und gruppiert sie zu Themen, Mensch und LLM verhandeln, bis Einigkeit besteht, dann wenden beide das Codebuch an. \
  *Befund:* Mensch-LLM-$kappa$ 0.87 (Musik) und 0.81 (Passwörter), gegenüber 0.66 und 0.77 zwischen den unabhängigen Codierenden der Originalstudien. Ein dritter Codierer erreichte mit dem LLM 0.54 und 0.47, mit dem menschlichen Codierer 0.62 und 0.43, stimmte also bei einem Datensatz weniger und beim anderen mehr mit dem LLM überein. Kosinus-Ähnlichkeit der Embeddings zu den Gold-Codes 0.886 und 0.890. \
  *Grenzen:* Das Mensch-LLM-$kappa$ entsteht _nach_ der Verhandlung und misst Konvergenz, nicht unabhängige Reliabilität; nur GPT-3.5; keine Zeitmessung trotz Effizienzanspruch @dai2023llm.
]

#studie(titel: [De Paoli 2024])[
  *Design:* Nachbildung von Phasen der reflexiven thematischen Analyse mit GPT-3.5-Turbo an zwei offen zugänglichen Interviewdatensätzen (Videospielende; Lehrende der Data Science); Vergleich der Modellthemen mit den Themen der Originalanalysen. \
  *Befund:* Das Modell identifizierte die meisten Hauptthemen der früheren Analysen; der Autor wertet das als Hinweis auf Machbarkeit und gewisse Validität. \
  *Grenzen:* Validität nur als Überlappung mit _einer_ menschlichen Analyse; öffentliche Daten (Kontamination möglich); ein Modell @depaoli2024performing.
]

#studie(titel: [Parfenova et al. 2025])[
  *Design:* Sechs offene LLMs erzeugen offene Codes, Zero-Shot, Few-Shot und mit LoRA feinabgestimmt; 1000 Zitat-Code-Paare (600 aus sozialwissenschaftlichen Interviews und Rezensionen, 400 aus SemEval-2014), Split 900/100; menschliche Bewertung durch 3 Fachleute auf 15 Sätzen. \
  *Befund:* Bester feinabgestimmter BERTScore-F1 0.764 (Falcon), Plateau bei etwa 100 Trainingsbeispielen; bestes Few-Shot Mistral mit 0.761 bei 5 Shots. Krippendorffs $alpha$ über menschliche Codierende und LLMs nur etwa 0.2. Menschen waren bei schwierigen Sätzen besser, interpretierten leichte aber über. \
  *Grenzen:* Hyperparameter auf dem Testset gewählt; BERTScore und ROUGE erfassen interpretative Qualität möglicherweise nicht @parfenova2025text.
]

#studie(titel: [De Paoli & Mathis 2025])[
  *Design:* Vorschlag eines quantitativen Sättigungsindikators für die initiale LLM-Codierung; GPT-3.5-Turbo-16k, Temperatur 0, bis zu 15 Codes pro Interview, LLM-Duplikatprüfung gegen das laufende Codebuch; zwei Datensätze ("Teaching" mit 10, "Scrum" mit 39 Interviews). \
  *Befund:* Teaching 135 Codes insgesamt, 53 einzigartige; Scrum 534 insgesamt, 66 einzigartige. Bei Scrum wird die Kurve ab etwa Interview 10 deutlich flacher und flacht bei Interview 20 fast ab, das Verhältnis strebt gegen etwa 0.1; bei Teaching gegen etwa 0.4. Die Autoren führen den Unterschied auf die Struktur der Daten zurück, nicht nur auf das Modell. \
  *Grenzen:* Ausdrücklich als Arbeitshypothese formuliert; ein Modell, zwei Datensätze, ungeprüfte Linearitätsannahme, Abhängigkeit von der Interviewreihenfolge @depaoli2025reflections.
]

#studie(titel: [DeRegnaucourt et al. 2026])[
  *Design:* Eine einstündige Fokusgruppe (4 Studierende), 6488 Wörter, 48 Ausschnitte (Redebeiträge); gpt-4o-2024-11-20 gegen drei menschliche Codierende. Induktiv: menschliches Konsens-Codebuch mit 49 Codes gegen 137 GPT-4o-Codes. Deduktiv: 49 Codes mal 48 Ausschnitte = 2352 Entscheidungen. \
  *Befund:* Von den KI-Codes stimmten 31.4 % mit menschlichen Codes überein, 26.3 % waren vernünftige Alternativen, 42.3 % nicht vernünftig; die KI verfehlte 21 der 49 menschlichen Codes (42.9 %). Deduktiv: mittlere Prozentübereinstimmung 96 %, mittleres $kappa$ 0.71 (SD 0.26), 33 von 49 Codes über 0.60; 2.4 % Fehlauslösungen, 1.2 % Auslassungen. Aufwand: 34 Codierstunden manuell gegen 65 Stunden für den Aufbau des KI-Workflows plus 80 Minuten Laufzeit. \
  *Grenzen:* Ein Transkript, ein Modell, Codebuch auf demselben Transkript abgeleitet und angewendet, unerfahrene Codierende; zwei Autoren halten ein Patent zum untersuchten Werkzeug @deregnaucourt2026large.
]

#studie(titel: [van den Berkmortel et al. 2026])[
  *Design:* 317 niederländische Regionalzeitungsartikel (2020 bis 2023, 275 878 Wörter) zur Stimmung gegenüber Pflegekräften; Mensch, GPT-5 und Gemini 2.5 Pro leiten je einen Codierbaum ab, danach wenden die Modelle das menschliche Codebuch auf einer geschichteten 10-%-Teilstichprobe (31 Artikel) an; Zugriff über Web-Oberflächen (Oktober bis November 2025). \
  *Befund:* Mensch-Mensch-$alpha$ 0.703, Mensch-LLM 0.487 (GPT-5) und 0.507 (Gemini). Beide Modelle codierten zu viel: 181 und 183 Codezuweisungen gegen 138 beim Menschen. Induktiv fanden beide Modelle ein Thema "Helden", das die menschliche Analyse bewusst zurückgestellt hatte; die Studie berichtet allerdings auch einen menschlichen offenen Code dazu, sodass die Behandlung nicht ganz konsistent ist. \
  *Grenzen:* Web-Oberflächen ohne Kontrolle über Version und Temperatur; Modelle wurden während der Studie aktualisiert @vandenberkmortel2026analyzing.
]

#studie(titel: [Bergmann et al. 2026 (Preprint)])[
  *Design:* 903 offene Antworten (sechs Variablen mit je 55 bis 266 Antworten) aus einer europäischen Befragung von Promovierenden; fünf menschliche Codierende (eine Person pro Variable, eine codierte zwei); zweistufige LLM-Pipeline (Codes und Kategorien erzeugen, dann Antworten zuordnen und zu Themen gruppieren); das Modell heißt im Titel GPT-5, in der Methodik GPT-5.4. Übereinstimmung per ARI (R-Paket mclust) auf Ko-Zuordnungsmatrizen. \
  *Befund:* Mensch-LLM-ARI 0.61 für Codes und 0.54 für Themen; pro Variable 0.35 bis 0.85 (Codes) und 0.31 bis 0.70 (Themen). Konsistenz innerhalb einer Instanz: 0.68 bei Menschen, 0.76 beim LLM. Alle menschlichen Codierenden gaben an, die LLM-Ausgabe spiegle ihre eigene Codierung. \
  *Grenzen:* Ein Modell, kein Referenzstandard im strengen Sinn, eine Person pro Variable; keine Angaben zu Kosten und Zeit. Der Text nennt eine Spannweite von 0.31 bis 0.89, aber 0.89 ist ein LLM-interner Wert @bergmann2026llms.
]

Daneben stehen Systeme, die den Ableitungsschritt selbst verbessern wollen. LLooM erzeugt durch iteratives Zusammenfassen gesampelter Texte zunehmend allgemeine Konzepte mit Einschlusskriterien; wo BERTopic "women, power, female" liefert, liefert LLooM "criticism of traditional gender roles" @lam2024concept. TopicGPT erzeugt Themen mit natürlichsprachlichen Beschreibungen und erreicht eine harmonische Mittelwert-Purity von 0.74 gegenüber 0.64 für die stärkste Baseline auf menschlich annotierten Wikipedia-Themen @pham2024topicgpt. Thematic-LM verteilt die Arbeit auf Codier-, Aggregations- und Codebuch-Agenten und weist den Codier-Agenten unterschiedliche Identitäten zu, was die Divergenz der Codes und Themen erhöht @qiao2025thematic. Nyaaba et al. berichten, dass ein schrittweiser GPT-4-Turbo-Workflow ähnlich wie menschliche Codierende codierte und Themen etwa auf dem Niveau einer durchschnittlichen Codierperson kategorisierte, sie aber abstrakter rahmte @nyaaba2025optimizing.

Für den Anwendungsfall offener Befragungsantworten sind zwei weitere Befunde zentral. Bei deutschsprachigen offenen Antworten schlug Feinabstimmung auf menschlichen Codes das Standard-Prompting deutlich @vonderheyde2025using. Und Ashwin et al. zeigen, dass auch gute mittlere Übereinstimmung Fehler verdecken kann, die mit Gruppen von Befragten korrelieren @ashwin2026using. Wer offene Antworten nach Geschlecht, Herkunft oder Fachbereich auswertet, muss die Übereinstimmung pro Gruppe berichten.

=== Vergleich eines LLM-Codebuchs mit einem menschlichen

Beim deduktiven Codieren vergleicht man Labels. Beim induktiven Codieren gibt es keine gemeinsame Labelmenge: Das LLM nennt ein Thema "Geld", der Mensch "Kosten". Die Literatur verwendet deshalb fünf Familien von Vergleichsmaßen, die verschiedene Aspekte prüfen (@k05-tab-induktiv-masse).

#figure(
  table(columns: (auto, 1fr, 1fr),
    [Maß], [Was es prüft], [Was es nicht prüft],
    [Code-Abgleich durch Fachleute], [ob KI-Codes menschlichen entsprechen, vernünftige Alternativen sind oder nicht; welche menschlichen Codes fehlen @deregnaucourt2026large], [ob das menschliche Codebuch selbst gut ist],
    [Adjusted Rand Index], [ob dieselben Antworten zusammen gruppiert werden, unabhängig von den Namen @bergmann2026llms], [Qualität und Benennung der Themen],
    [Sättigungsverhältnis], [ob der Codierprozess noch neue Codes erzeugt @depaoli2025reflections], [Korrektheit der Codes],
    [Semantische Ähnlichkeit], [Nähe der Codetexte zu Gold-Codes im Embedding-Raum @dai2023llm @parfenova2025text], [interpretative Tiefe],
    [Deduktive Anwendung], [Reliabilität des eingefrorenen Codebuchs pro Code @dunivin2025scaling @deregnaucourt2026large], [ob die Kategorien die richtigen sind],
  ),
  caption: [Familien von Maßen zum Vergleich induktiv abgeleiteter Codebücher. Keine einzelne Familie genügt; sie ergänzen sich.],
) <k05-tab-induktiv-masse>

#zwischentitel[Code-Abgleich]

Zwei Fachleute ordnen jeden KI-Code einer von drei Klassen zu: entspricht einem menschlichen Code, vernünftige Alternative, nicht vernünftig. Zusätzlich zählt man die menschlichen Codes, die die KI verfehlt hat. @k05-fig-abgleich zeigt die Werte von DeRegnaucourt et al. Wichtig ist, die Übereinstimmung der beiden klassifizierenden Personen ebenfalls zu berichten, denn die Klassifikation "vernünftige Alternative" ist selbst ein Urteil.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 11.0
    let segs = ((31.4, c-green, [entspricht menschlichem Code: 31.4 %]), (26.3, c-yellow, [vernünftige Alternative: 26.3 %]), (42.3, c-red, [nicht vernünftig: 42.3 %]))
    let x = 0
    for (v, col, lab) in segs {
      rect((x, 0), (x + v / 100 * W, 0.7), fill: col.lighten(30%), stroke: white + 1pt)
      x += v / 100 * W
    }
    let x = 0
    for (i, (v, col, lab)) in segs.enumerate() {
      content((x + v / 200 * W, if calc.rem(i, 2) == 0 { -0.35 } else { 1.05 }), text(font: "Inter", size: 7pt, fill: col.darken(25%), lab))
      x += v / 100 * W
    }
    content((-0.15, 0.35), anchor: "east", text(font: "Inter", size: 7.5pt)[137 KI-Codes])
    rect((0, -1.6), (49 / 49 * W * 0.6, -0.9), fill: c-blue.lighten(70%), stroke: white + 1pt)
    rect((0, -1.6), (28 / 49 * W * 0.6, -0.9), fill: c-blue.lighten(25%), stroke: white + 1pt)
    content((-0.15, -1.25), anchor: "east", text(font: "Inter", size: 7.5pt)[49 menschliche Codes])
    content((14 / 49 * W * 0.6, -1.25), text(font: "Inter", size: 7pt, fill: white)[gefunden: 28])
    content((38.5 / 49 * W * 0.6, -1.25), text(font: "Inter", size: 7pt)[verfehlt: 21])
  }),
  caption: [Induktiver Code-Abgleich bei DeRegnaucourt et al. @deregnaucourt2026large: Bewertung der 137 GPT-4o-Codes (oben) und Abdeckung der 49 menschlichen Codes (unten).],
) <k05-fig-abgleich>

#zwischentitel[Der Adjusted Rand Index]

Wenn beide Codebücher jede Antwort genau einem Thema zuordnen, sind sie zwei *Partitionen* derselben Menge von Antworten. Die Frage, ob sie "dasselbe" Codebuch sind, wird dann zur Frage, ob sie dieselben Antworten zusammen gruppieren. Die Namen der Themen spielen keine Rolle.

*Paarzählung.* Betrachte alle $binom(n, 2)$ ungeordneten Paare von Antworten. Für jedes Paar gibt es vier Fälle: in beiden Partitionen zusammen ($a$), nur in der menschlichen zusammen ($b$), nur in der LLM-Partition zusammen ($c$), in beiden getrennt ($d$). Der *Rand-Index* ist der Anteil der Paare, über die beide Partitionen einig sind, $"RI" = (a + d) \/ binom(n, 2)$. Er ist die Prozentübereinstimmung auf Paarebene und hat dasselbe Problem: Bei vielen kleinen Clustern sind fast alle Paare in beiden Partitionen getrennt, und $"RI"$ ist schon zufällig hoch.

*Zufallskorrektur.* Mit der Kontingenztafel $n_(i j)$ (Antworten in menschlichem Thema $i$ und LLM-Thema $j$), Zeilensummen $a_i$ und Spaltensummen $b_j$ gilt $a = sum_(i j) binom(n_(i j), 2)$, denn zwei Antworten sind in beiden Partitionen genau dann zusammen, wenn sie in derselben Zelle liegen. Die Zahl der Paare, die in der menschlichen Partition zusammen sind, ist $sum_i binom(a_i, 2)$, in der LLM-Partition $sum_j binom(b_j, 2)$. Als Zufallsmodell hält man beide Clustergrößen fest und verteilt die LLM-Labels durch eine zufällige Permutation auf die Antworten. Dann ist jedes feste Paar von Antworten mit derselben Wahrscheinlichkeit $sum_j binom(b_j, 2) \/ binom(n, 2)$ in der LLM-Partition zusammen, denn es landet gleichverteilt auf einem der $binom(n, 2)$ Positionspaare. Summiert man diese Wahrscheinlichkeit über die $sum_i binom(a_i, 2)$ Paare, die in der menschlichen Partition zusammen sind (Linearität des Erwartungswerts), erhält man

$ E[a] = (sum_i binom(a_i, 2) thin sum_j binom(b_j, 2)) / binom(n, 2). $ <k05-eq-ari-erwartung>

Als Maximum verwendet man den Mittelwert $1/2 [sum_i binom(a_i, 2) + sum_j binom(b_j, 2)]$. Er ist eine obere Schranke für $a$, weil $a$ höchstens so groß ist wie jede der beiden Summen, und wird bei identischen Partitionen erreicht. Damit ergibt sich der Adjusted Rand Index in exakt der Form von @k05-eq-allgemein, "beobachtet minus Zufall, geteilt durch Maximum minus Zufall":

$ "ARI" = (sum_(i j) binom(n_(i j), 2) - E[a]) / (1/2 [sum_i binom(a_i, 2) + sum_j binom(b_j, 2)] - E[a]). $ <k05-eq-ari>

ARI ist 1 bei identischen Partitionen, nahe 0 bei zufälliger Überlappung und kann negativ werden. Das ist die Formel, die `sklearn.metrics.adjusted_rand_score` in scikit-learn 1.9.1 implementiert @scikitlearn2026scikitlearn. Die strukturelle Verwandtschaft mit $kappa$ ist kein Zufall: Beide normieren eine Übereinstimmung zwischen dem Zufallserwartungswert und dem Maximum.

#beispiel(titel: [E8: ARI für zwölf Antworten])[
  Mensch: kosten (3), zeit (3), unterstützung (4), sonstiges (2). LLM: geld, geld, arbeitslast, arbeitslast, arbeitslast, arbeitslast, hilfe, hilfe, hilfe, geld, hilfe, diverses. Die Kontingenztafel:
  #align(center, table(columns: 6, align: center,
    [Mensch \\ LLM], [geld], [arbeitslast], [hilfe], [diverses], [$a_i$],
    [kosten], [2], [1], [0], [0], [3],
    [zeit], [0], [3], [0], [0], [3],
    [unterstützung], [1], [0], [3], [0], [4],
    [sonstiges], [0], [0], [1], [1], [2],
    [$b_j$], [3], [4], [4], [1], [12]))
  Beobachtet: $sum binom(n_(i j), 2) = binom(2, 2) + binom(3, 2) + binom(3, 2) = 1 + 3 + 3 = 7$. Zeilen: $binom(3, 2) + binom(3, 2) + binom(4, 2) + binom(2, 2) = 3 + 3 + 6 + 1 = 13$. Spalten: $3 + 6 + 6 + 0 = 15$. Erwartung: $13 dot 15 \/ binom(12, 2) = 195 \/ 66 = 2.9545$. Maximum: $(13 + 15) \/ 2 = 14$.
  $ "ARI" = (7 - 2.9545) / (14 - 2.9545) = 4.0455 / 11.0455 = 0.366. $
  Zum Vergleich der unkorrigierte Rand-Index: Von 66 Paaren sind $a = 7$ in beiden zusammen, $13 - 7 = 6$ nur beim Menschen, $15 - 7 = 8$ nur beim LLM und $66 - 21 = 45$ in beiden getrennt; $"RI" = (7 + 45) \/ 66 = 0.788$. Der Rand-Index klingt gut, der ARI zeigt, dass die Übereinstimmung nur mäßig über dem Zufall liegt.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let rows = ([kosten], [zeit], [unterstützung], [sonstiges])
    let cols = ([geld], [arbeitslast], [hilfe], [diverses])
    let t = ((2, 1, 0, 0), (0, 3, 0, 0), (1, 0, 3, 0), (0, 0, 1, 1))
    let s = 0.9
    for (i, r) in rows.enumerate() {
      content((-0.15, -i * s), anchor: "east", text(font: "Inter", size: 7.5pt, r))
      for (j, v) in t.at(i).enumerate() {
        let f = if v == 0 { white } else { c-blue.lighten(100% - v * 25%) }
        rect((j * s * 1.6, -i * s - s / 2), ((j + 1) * s * 1.6, -i * s + s / 2), fill: f, stroke: 0.5pt + luma(200))
        content(((j + 0.5) * s * 1.6, -i * s), text(font: "Inter", size: 8pt, fill: if v >= 3 { white } else { c-dark }, str(v)))
      }
    }
    for (j, c) in cols.enumerate() {
      content(((j + 0.5) * s * 1.6, s * 0.85), text(font: "Inter", size: 7.5pt, c))
    }
    content((2 * s * 1.6, s * 1.55), text(font: "Inter", size: 7.5pt, weight: "bold")[LLM-Themen])
    content((-2.7, -1.5 * s), angle: 90deg, text(font: "Inter", size: 7.5pt, weight: "bold")[menschliche Themen])
    let x = 4 * s * 1.6 + 0.6
    content((x, 0), anchor: "west", text(font: "Inter", size: 7pt)[*Verschmelzung:* "zeit" geht in "arbeitslast" auf, \ das auch eine "kosten"-Antwort aufnimmt])
    content((x, -1.2), anchor: "west", text(font: "Inter", size: 7pt)[*Aufspaltung:* "unterstützung" verteilt sich \ auf "hilfe" und "geld"])
    content((x, -2.4), anchor: "west", text(font: "Inter", size: 7pt)[ARI = 0.366, RI = 0.788])
  }),
  caption: [Kontingenztafel des Beispiels E8. ARI reagiert auf Verschmelzungen und Aufspaltungen, nicht auf die Namen der Themen.],
) <k05-fig-ari>

Drei Eigenschaften des ARI muss man im Hörsaal erklären können. Erstens ist er invariant gegen Umbenennung: Ob das LLM ein Thema "geld" oder "kosten" nennt, ändert nichts. Zweitens bestraft er Verschmelzungen und Aufspaltungen schon dann deutlich, wenn jede einzelne Zuordnung plausibel ist; eine feinere und eine gröbere Partition derselben Sache haben einen ARI unter 1. Drittens sagt er nichts über die Qualität der Themen. Ein LLM, das sinnlose Themen bildet, die aber zufällig dieselben Antworten gruppieren wie der Mensch, hätte einen hohen ARI. Bergmann et al. ergänzen den ARI deshalb um die Einschätzung der menschlichen Codierenden selbst @bergmann2026llms, und ein qualitativer Blick auf die Codes gehört immer dazu.

#datei-fest("ari.py")[```python
from sklearn.metrics import adjusted_rand_score, rand_score

mensch = ["kosten"]*3 + ["zeit"]*3 + ["unterstützung"]*4 + ["sonstiges"]*2
llm = ["geld", "geld", "arbeitslast", "arbeitslast", "arbeitslast", "arbeitslast",
       "hilfe", "hilfe", "hilfe", "geld", "hilfe", "diverses"]
print(adjusted_rand_score(mensch, llm))   # 0.3663
print(rand_score(mensch, llm))            # 0.7879
```]

Bei Mehrfachzuordnung (eine Antwort trägt mehrere Codes) gibt es keine Partition mehr. Bergmann et al. haben die Codes deshalb zuerst in Ko-Zuordnungsmatrizen überführt, in denen festgehalten ist, welche Antworten gemeinsame Codes tragen, und den ARI dann darauf berechnet @bergmann2026llms. Wer diesen Weg geht, muss die Konstruktion der Matrix genau berichten, weil sie das Ergebnis bestimmt.

#zwischentitel[Sättigung]

Das Lehrbuch definiert theoretische Sättigung als den Punkt, an dem neue Daten keine neuen theoretischen Einsichten mehr erzeugen, und betont, dass das etwas anderes ist als bloße Wiederholung @haindl2027research. De Paoli und Mathis schlagen für die LLM-Codierung eine zählbare Annäherung vor, die *induktive thematische Sättigung* (ITS) @depaoli2025reflections. Man codiert die Texte der Reihe nach und verfolgt nach Text $k$ die kumulierte Zahl aller Codes $T_k$ und die kumulierte Zahl einzigartiger Codes $U_k$. Die Arbeit nennt das Maß "slope ratio", operationalisiert es aber als Verhältnis der Endwerte:

$ "ITS" = U_K / T_K. $ <k05-eq-its>

Ein Wert nahe 1 bedeutet, dass jeder Text noch überwiegend neue Codes bringt, also keine Sättigung. Ein Wert deutlich unter 1 zeigt Sättigung an. Für die beiden Datensätze ergeben sich aus den berichteten Zählungen $53 \/ 135 = 0.39$ (Teaching, 10 Interviews) und $66 \/ 534 = 0.12$ (Scrum, 39 Interviews) @depaoli2025reflections.

#beispiel(titel: [E9: Sättigung über zehn Interviews (synthetisch)])[
  Codes pro Interview: 15, 14, 15, 13, 15, 14, 15, 15, 14, 15, also $T = 15, 29, 44, 57, 72, 86, 101, 116, 130, 145$. Neue einzigartige Codes pro Interview: 15, 9, 7, 6, 4, 3, 3, 2, 1, 1, also $U = 15, 24, 31, 37, 41, 44, 47, 49, 50, 51$. Nach der Formel der Arbeit ist $"ITS" = 51 \/ 145 = 0.352$. Zwei Steigungsvarianten, die eine eigene Erweiterung dieses Buchs und nicht die Formel der Arbeit sind: die Endpunktsteigung $(51 - 15) \/ (145 - 15) = 0.277$ und die OLS-Steigung von $U$ auf $T$ mit 0.263. Berichte immer, welche Variante du verwendest; nur $U_K \/ T_K$ entspricht der publizierten Operationalisierung.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let T = (15, 29, 44, 57, 72, 86, 101, 116, 130, 145)
    let U = (15, 24, 31, 37, 41, 44, 47, 49, 50, 51)
    let W = 8.0
    let H = 4.0
    let X(t) = t / 150 * W
    let Y(u) = u / 75 * H
    rect((0, 0), (W, H), stroke: 0.5pt + c-dark)
    for u in (0, 25, 50, 75) {
      line((0, Y(u)), (W, Y(u)), stroke: (paint: luma(225), thickness: 0.4pt))
      content((-0.15, Y(u)), anchor: "east", text(font: "Inter", size: 7pt, str(u)))
    }
    for t in (0, 50, 100, 150) {
      line((X(t), 0), (X(t), -0.1), stroke: 0.5pt + c-dark)
      content((X(t), -0.32), text(font: "Inter", size: 7pt, str(t)))
    }
    line((0, 0), (X(75), Y(75)), stroke: (paint: c-grey, thickness: 0.8pt, dash: "dashed"))
    content((X(77), Y(72)), anchor: "west", text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[$U = T$: keine Wiederholung])
    line((0, 0), (X(145), Y(51)), stroke: (paint: c-violet, thickness: 0.8pt, dash: "dotted"))
    content((X(148), Y(20)), anchor: "east", text(font: "Inter", size: 7pt, fill: c-violet)[$"ITS" = 51 \/ 145 = 0.352$])
    line(..T.zip(U).map(((t, u)) => (X(t), Y(u))), stroke: 1.4pt + c-accent)
    for (t, u) in T.zip(U) { circle((X(t), Y(u)), radius: 0.06, fill: c-accent, stroke: none) }
    content((W / 2, -0.75), text(font: "Inter", size: 7.5pt)[kumulierte Codes $T_k$])
    content((-0.8, H / 2), angle: 90deg, text(font: "Inter", size: 7.5pt)[einzigartige Codes $U_k$])
  }),
  caption: [Sättigungskurve des synthetischen Beispiels E9. Jeder Punkt ist ein Interview. Die Kurve flacht ab, je weniger neue Codes ein Interview beiträgt; das ITS-Verhältnis ist die Steigung der Ursprungsgeraden durch den Endpunkt.],
) <k05-fig-saettigung>

Die Grenzen des Maßes sind wichtig. Die Autoren nennen es selbst eine Arbeitshypothese, getestet mit einem Modell und zwei Datensätzen, und das Ergebnis hängt von der Reihenfolge der Interviews ab @depaoli2025reflections. Der Endwert $U_K \/ T_K$ wäre bei perfekter Duplikaterkennung reihenfolgeunabhängig; in der Praxis entscheidet aber ein LLM über Duplikate, und diese Entscheidungen hängen davon ab, welche Codes schon im Codebuch stehen. Die _Form_ der Kurve hängt in jedem Fall von der Reihenfolge ab. Eine naheliegende eigene Erweiterung ist es deshalb, die Kurve für mehrere zufällige Reihenfolgen zu berechnen und ein Band zu berichten. Grundsätzlicher misst ITS den Codierprozess, nicht die Korrektheit der Codes: Ein Modell, das immer dieselben generischen Codes vergibt, sättigt schnell und liegt trotzdem daneben. Das ist genau der Unterschied zwischen Wiederholung und theoretischer Sättigung, den das Lehrbuch betont @haindl2027research.

#zwischentitel[Semantische Ähnlichkeit und deduktive Anwendung]

Dai et al. berichten die Kosinus-Ähnlichkeit von text-embedding-ada-002-Vektoren zwischen LLM-Codes und Gold-Codes (0.886 und 0.890) @dai2023llm; Parfenova et al. einen BERTScore-F1 von bis zu 0.764 @parfenova2025text. Beide warnen implizit oder explizit, dass solche Oberflächenmaße interpretative Qualität kaum erfassen: In derselben Studie, in der der BERTScore bei 0.76 lag, betrug Krippendorffs $alpha$ über menschliche Codierende und LLMs nur etwa 0.2 @parfenova2025text. Die letzte Familie ist die deduktive Anwendung des eingefrorenen Codebuchs mit $kappa$ oder $alpha$ pro Code (@k05-deduktiv). Sie prüft die Reliabilität des Codebuchs, nicht seine Angemessenheit.

=== Vertrauenswürdigkeit statt nur Übereinstimmung

Die Übereinstimmungsmaße stammen aus einer Messlogik, in der Abweichung Fehler ist. Die qualitative Forschung beurteilt Qualität dagegen über *Vertrauenswürdigkeit* mit den Kriterien Glaubwürdigkeit, Übertragbarkeit, Verlässlichkeit und Bestätigbarkeit @haindl2027research @Lincoln1985. Qiao et al. evaluieren Thematic-LM ausdrücklich anhand solcher Prinzipien @qiao2025thematic. Für einen LLM-gestützten induktiven Workflow lassen sich die Strategien aus dem Lehrbuch direkt übersetzen (@k05-tab-trust); die Zuordnung ist ein Vorschlag dieses Buchs.

#figure(
  table(columns: (auto, 1fr, 1fr),
    [Kriterium], [Strategie im Lehrbuch @haindl2027research], [Umsetzung im LLM-Workflow],
    [Glaubwürdigkeit], [Negativfallanalyse; referenzielle Adäquatheit (Rohdaten früh beiseitelegen und später prüfen)], [gesperrte Testmenge vor der Ableitung; gezielt nach Antworten suchen, die keinem Thema passen],
    [Verlässlichkeit], [schrittweise Replikation (unabhängige Analyse von Teilmengen, dann Vergleich); Inquiry Audit], [LLM und Mensch leiten unabhängig ab, ARI und Code-Abgleich; Prompt- und Modellprotokoll],
    [Bestätigbarkeit], [Bestätigungsaudit: jede Aussage über Belegstellen auf Rohdaten zurückführen], [Zitat und Antwort-ID pro Code (Log in `induktiv.py`)],
    [Übertragbarkeit], [theoretisches Sampling, analytische Generalisierung], [Übereinstimmung pro Subgruppe und Sprache berichten @ashwin2026using @tornberg2024best],
  ),
  caption: [Kriterien der Vertrauenswürdigkeit und ihre Übersetzung in einen LLM-gestützten induktiven Workflow.],
) <k05-tab-trust>

=== Debatten um das induktive Codieren

*Interpretation gegen Messung.* Die reflexive thematische Analyse behandelt die Subjektivität der Forschenden als Ressource; Übereinstimmungskoeffizienten behandeln Divergenz als Fehler. Dunivin argumentiert, dass LLM-Codierung mit _reflexiver_ Inhaltsanalyse vereinbar ist, weil die Anpassung des Codebuchs die Forschenden zwingt, ihre Interpretationen explizit zu machen @dunivin2025scaling. Thematic-LM baut Divergenz sogar bewusst ein @qiao2025thematic, und Plank argumentiert, dass menschliche Labelvariation oft Signal ist @plank2022problem.

*Was zählt als Validität?* Der Abgleich mit einer früheren menschlichen Analyse @depaoli2024performing setzt voraus, dass diese Analyse das Ziel ist. Sättigungsverhältnisse messen den Prozess @depaoli2025reflections, ARI die Ähnlichkeit der Gruppierung @bergmann2026llms. Keines dieser Maße beantwortet, ob die Themen die Erfahrung der Befragten treffen.

*Verhandelte Übereinstimmung.* Ein hohes Mensch-LLM-$kappa$ _nach_ Diskussionsrunden (0.81 bis 0.87 bei Dai et al.) misst Konvergenz und ist mit unabhängiger Doppelcodierung nicht vergleichbar @dai2023llm.

*Effizienz.* Der Aufbau des KI-Workflows dauerte bei DeRegnaucourt et al. länger als die manuelle Codierung eines Transkripts (65 gegen 34 Stunden); Gewinne entstehen erst bei Skalierung @deregnaucourt2026large.

#hoersaal([Das LLM hat bei van den Berkmortel et al. ein Thema "Helden" gefunden, das die menschliche Analyse zurückgestellt hatte. Ist das ein Fehler des Modells oder eine Einsicht?],
[Weder noch, solange man es nicht prüft. Es ist zunächst ein Anlass zur Reflexion: Warum hat der Mensch das Thema zurückgestellt, und war das eine begründete analytische Entscheidung oder ein blinder Fleck? Die Studie berichtet selbst einen menschlichen offenen Code dazu, die Zurückstellung war also eine Gewichtung, kein Übersehen @vandenberkmortel2026analyzing. In einem reflexiven Ansatz ist eine solche Divergenz wertvoll; in einem messenden Ansatz ist sie ein Fehler gegenüber dem Referenzstandard. Welche Lesart gilt, muss vorab im Design stehen, nicht nachträglich nach dem Ergebnis gewählt werden.])

#hoersaal([Wenn ein LLM mit sich selbst konsistenter ist als Menschen untereinander (Bergmann: 0.76 gegen 0.68), ist es dann nicht der bessere Codierer?],
[Konsistenz ist Reliabilität, nicht Validität. Ein deterministisches Verfahren, das jede Antwort nach dem ersten Substantiv einsortiert, wäre perfekt konsistent und inhaltlich wertlos. Die höhere Konsistenz zeigt, dass das LLM ein stabiles Kategoriensystem anwendet; ob es das richtige ist, beantwortet der Vergleich mit Menschen (ARI 0.61 bzw. 0.54) und die qualitative Prüfung @bergmann2026llms. Wang et al. zeigen dasselbe Muster für Modelle untereinander: Hohe Übereinstimmung zwischen LLMs spiegelt geteilte Vorannahmen @wang2026wisdom.])

== Debatten und offene Fragen <k05-debatten>

=== Ersetzen LLMs menschliche Annotatoren?

Für eine Ersetzung sprechen höhere Genauigkeit als MTurk und höhere Lauf-zu-Lauf-Übereinstimmung als trainierte Annotatoren zu einem Bruchteil der Kosten @gilardi2023chatgpt, höhere Genauigkeit als Fachleute, Crowdworker und überwachte Klassifikatoren bei der Parteizuordnung in 11 Ländern @tornberg2025large und bestandene Alternative Annotator Tests auf mehreren Datensätzen @calderon2025alternative. Dagegen stehen die große Heterogenität über Aufgaben @pangakis2023automated, die seltenen Siege über feinabgestimmte Modelle @ziems2024can, die Überlegenheit eines überwachten DistilBERT @kristensenmclachlan2025are und feinabgestimmter Modelle bei offenen Antworten @vonderheyde2025using, der differenzielle Bias @ashwin2026using und der Befund, dass menschliche Labels den stärksten Schutz vor falsch-positiven Schlüssen bieten @baumann2025large. Die Position, die sich 2026 in der Literatur abzeichnet, ist die von Ziems et al.: LLMs als zusätzliche Annotatoren neben Menschen, nur bei validierter Übereinstimmung @ziems2024can, und als zusätzliches Teammitglied unter menschlicher Kontrolle beim induktiven Codieren @dai2023llm @deregnaucourt2026large @bergmann2026llms.

=== Was ist der Referenzstandard?

Studien vergleichen mit trainierten Studierenden @gilardi2023chatgpt, mit Fachleuten @pangakis2023automated oder mit Crowd-Annotationen öffentlicher Benchmarks @ziems2024can. Jede dieser Wahlen definiert "richtig" anders. Wenn das Gold-Label selbst fehlerhaft ist, wie Panahi et al. für einen Teil ihrer Farsi-Daten zeigen @panahi2026when, begrenzt es die messbare Qualität des LLM nach oben. Der Alternative Annotator Test umgeht das Problem teilweise, indem er gar keinen Gold-Standard voraussetzt @calderon2025alternative; er verschiebt es aber nur auf die Frage, ob die menschliche Gruppe das Konstrukt teilt.

=== Welcher Koeffizient?

Die Literatur ist gespalten. Gwet argumentiert, dass $kappa$ und $pi$ die Zufallsübereinstimmung bei extremer Prävalenz falsch schätzen, und schlägt AC1 vor @gwet2008computing. Hayes und Krippendorff plädieren für $alpha$ als einzigen Standard @hayes2007answering. McHugh empfiehlt, $kappa$ zusammen mit der Prozentübereinstimmung zu berichten @mchugh2012interrater. Chew et al. wählen AC1 für seltene LLM-Codes @chew2023llm. Die vertretbare Position, gestützt auf die durchgerechneten Beispiele dieses Kapitels: $p_o$, Konfusionsmatrix und Marginalien, mindestens ein zufallskorrigierter Koeffizient mit Konfidenzintervall, Precision und Recall pro Klasse, und die Wahl des Koeffizienten vor dem Blick auf die Daten.

=== Reproduzierbarkeit und Offenheit

Proprietäre Modelle ändern sich und werden abgekündigt, und selbst Temperatur 0 ist nicht deterministisch @rathje2024gpt. Törnberg empfiehlt feste Versionen, wo möglich selbst gehostete offene Modelle und keine Annotation über Web-Oberflächen @tornberg2024best. Feinabgestimmte offene Modelle können Zero-Shot-Proprietärmodelle erreichen @alizadeh2025open, und Kristensen-McLachlan et al. fanden die Genauigkeitskosten offener Modelle in ihrem Setting gering @kristensenmclachlan2025are. Die Studie von van den Berkmortel et al. aus 2026, die über Web-Oberflächen annotierte und deren Modelle während der Studie aktualisiert wurden @vandenberkmortel2026analyzing, zeigt, dass diese Regel auch in begutachteten Zeitschriften nicht selbstverständlich ist.

=== Reasoning-Modelle als Annotatoren

Die Evidenz ist dünn und gemischt (Stand: 11. November 2026). In einer kontrollierten Studie mit offenen Modellen war DeepSeek R1 auf einer Aufgabe das beste Zero-Shot-Modell, verlor aber unter Chain-of-Thought-Prompting auf derselben Aufgabe 0.24 F1 und verbrauchte etwa zwanzigmal so viel Energie wie das gleich große Llama 3.1 mit 70B @mclaren2026magic. Eine eigene, verifizierte Evaluation von Reasoning-Modellen für die Annotation ist in der Wissensbasis der LV nicht enthalten; die Aussage ist eine Momentaufnahme einer begrenzten Suche und vor jeder Lehrveranstaltung neu zu prüfen.

=== Weitere offene Probleme

Offen sind die Wahl des Spielraums $epsilon$ in Ersetzungstests und die Frage, wie streng man in Hochrisikobereichen sein muss @calderon2025alternative; der Zielkonflikt zwischen Typ-I- und Typ-II-Fehlern bei Korrekturverfahren (Kapitel 6) @baumann2025large; schwache Leistung bei ressourcenarmen Sprachen und schwierigen Konstrukten wie moralischer Reinheit, implizitem Hass oder Empathie @rathje2024gpt @ziems2024can; Kontamination öffentlicher Benchmarks @tornberg2024best; und das Fehlen einer akzeptierten Validitätsmetrik für induktives LLM-Codieren @depaoli2025reflections @bergmann2026llms @qiao2025thematic.

#hoersaal([Ist es nicht widersprüchlich, LLM-Labels zu validieren, wenn die menschlichen Labels selbst so unzuverlässig sind?],
[Nein, es ist der Grund, warum man Mensch-Mensch-Übereinstimmung immer mitberichtet. Die menschliche Übereinstimmung auf denselben Items setzt die Messlatte: Ein LLM kann nicht valider erscheinen, als der Referenzstandard reliabel ist. Wenn zwei Fachleute nur $kappa = 0.5$ erreichen, ist das Konstrukt schlecht definiert, und dann ist die richtige Reaktion, das Codebuch zu schärfen, nicht das LLM zu wechseln @tornberg2024best. Plank würde ergänzen, dass manche Variation echt ist und als Verteilung berichtet werden sollte statt als Rauschen @plank2022problem.])

== Reporting <k05-reporting>

Eine LLM-Annotation ist nur so gut wie ihre Dokumentation. Die folgende Checkliste ist aus den verifizierten Quellen synthetisiert; sie setzt Törnbergs Empfehlungen @tornberg2024best und die Berichtsempfehlungen von Baumann et al. @baumann2025large um.

+ *Modell:* Name, exakte Version oder Snapshot, Zugriffsdatum, Zugriffsweg (API oder selbst gehostet, keine Web-Oberfläche) @tornberg2024best.
+ *Prompt-Codebuch:* System- und Nutzerprompts, Kategoriendefinitionen, Beispiele, Ausgabeformat, Abbildung der Ausgabe auf Labels @tornberg2024best @baumann2025large.
+ *Parameter:* alle Dekodierparameter einschließlich der Voreinstellungen (Temperatur, top-p, maximale Tokens) @tornberg2024best.
+ *Validierungsdesign:* Stichprobenziehung, Umfang, Zahl und Schulung der menschlichen Codierenden, Mensch-Mensch-Übereinstimmung, Entwicklungs- und Testsplit @tornberg2024best @pangakis2023automated.
+ *Metriken mit Begründung:* Konfusionsmatrix, Precision, Recall und F1 pro Klasse, zufallskorrigierter Koeffizient mit Konfidenzintervall (Methode, $B$, Resampling-Einheit), Messniveau @tornberg2024best.
+ *Stabilität:* Lauf-zu-Lauf-Konsistenz und $alpha$ über Prompt-Paraphrasen @tornberg2024best @reiss2023testing @barrie2024prompt.
+ *Konfigurationsraum:* alle getesteten Modelle und Prompts, idealerweise präregistriert, plus Sensitivitätsanalyse für Ergebnisse nahe der Signifikanzschwelle @baumann2025large.
+ *Freigabe:* LLM- und Menschenlabels und Analysecode; Datenschutz (Anonymisierung, Auftragsverarbeitung, Übermittlung außerhalb von EU und EWR) @baumann2025large @tornberg2024best.
+ *Beim induktiven Codieren zusätzlich:* Analyseeinheit, Ableitungs- und Testmenge, alle Codebuchversionen, Verhandlungsprotokoll, Vergleichsmaße mit dem menschlichen Codebuch (Code-Abgleich mit Übereinstimmung der Klassifizierenden, ARI mit Konstruktion bei Mehrfachzuordnung, Sättigungsvariante) und Übereinstimmung pro Subgruppe @deregnaucourt2026large @bergmann2026llms @depaoli2025reflections @ashwin2026using.

#praxis[
  Ein Methodenabsatz, der diese Punkte kompakt abdeckt, könnte so lauten: "Die 1200 offenen Antworten wurden vor der Analyse zufällig in eine Ableitungsmenge (720) und eine gesperrte Testmenge (480) geteilt. Auf der Ableitungsmenge erzeugte [Modell, Snapshot, Zugriff am ...] bei Temperatur 0 Codes mit Belegzitat (Prompts in Anhang A); Duplikate wurden gegen ein laufendes Codebuch geprüft. Zwei Autorinnen leiteten unabhängig ein menschliches Codebuch ab. Der Vergleich ergab ... (ARI ...; Code-Abgleich: ... % entsprechend, ... % vernünftige Alternative, Übereinstimmung der Klassifizierenden $kappa = ...$). Das in einer Verhandlungsrunde konsolidierte Codebuch (Version 3, Anhang B) wurde eingefroren und auf der Testmenge angewendet; wir berichten $kappa$ und AC1 pro Code mit 95-%-Bootstrap-Intervallen über Antworten ($B = 2000$) sowie die Übereinstimmung getrennt nach ..." Die Leerstellen sind keine Formalität: Jede einzelne beantwortet eine Frage, die Gutachtende stellen werden.
]

== Für die Lehre <k05-lehre>

Das Thema eignet sich hervorragend für eine Lehrveranstaltung, weil es Rechnen, Programmieren und methodisches Urteilen verbindet und weil die Studierenden eigene Daten mitbringen können. Foliensatz 05 der LV gliedert es in acht Teile: Einführung, Evidenz, Messen der Übereinstimmung, Fallstricke, Validierung, induktive Codebuch-Ableitung, Evaluation von Codebüchern und Reporting. Das Notebook `notebooks/05_agreement_and_codebooks.ipynb` rechnet die Beispiele E1 bis E8 per Hand und mit Bibliotheken nach (das Sättigungsbeispiel E9 ist nicht enthalten), prüft die Ergebnisse mit Assertions gegen die Tabellen, simuliert den ARI bei wachsender Zufallsneuzuordnung und den Alternative Annotator Test und enthält einen optionalen Live-Modus, in dem ein lokales Modell über eine OpenAI-kompatible Schnittstelle die Labels des Beispiels E4 erzeugt.

=== Vorschlag für den Ablauf

*Einstieg (15 Minuten).* Gilardi et al. als Aufhänger: Was bedeutet "outperforms" hier genau? Die Studierenden sollen selbst herausarbeiten, dass die Genauigkeit gegen trainierte Studierende auf Konsens-Items gemessen wurde und die hohen Übereinstimmungswerte über Läufe Reliabilität, nicht Validität sind @gilardi2023chatgpt.

*Übung 1: Koeffizienten per Hand und im Code (60 Minuten).* Die Tafeln E1 bis E3 von Hand rechnen ($p_o$, $kappa$, $pi$, $alpha$, AC1, PABAK), dann mit scikit-learn, statsmodels, krippendorff und irrCAC prüfen. Ergebnis: eine Tabelle wie in @k05-paradoxa und ein Absatz, welcher Koeffizient für eine LLM-Aufgabe mit seltener Klasse zu berichten ist. Erweiterung: `kripp_alpha` ohne numpy implementieren und an E4 mit fehlendem Wert testen (erwartet 0.6667).

*Live-Demonstrationen.* Das Prävalenzparadoxon live: Verschiebe in der Tafel E2b die 5 Einheiten aus Zelle $d$ in Zelle $a$ (E2b -> E2c) und zeige, wie $kappa$ von 0.44 auf $-0.05$ fällt, während AC1 bei etwa 0.88 bis 0.89 bleibt. Wichtig: nicht Zelle $d$ einfach auf 0 setzen, sonst ändern sich $n$ und $p_o$. Das Messniveau live: E5 mit nominalem und ordinalem $alpha$ (0.395 gegen 0.841). Prompt-Brüchigkeit live: eine Miniversion von Reiss' Design (10 Paraphrasen, 10 Wiederholungen, 50 Items) mit einem lokalen Modell, $alpha$ über Paraphrasen gegen $alpha$ über Wiederholungen @reiss2023testing.

*Übung 2: Ein LLM validieren (zwei Einheiten).* Eine Aufgabe aus dem Datenrelease von Baumann et al. mit Referenzlabels @baumann2025large; Prompt-Codebuch schreiben, 300 Items in 100 Entwicklung und 200 gesperrten Test teilen, ein offenes Modell bei Temperatur 0 und fünfmal bei 0.7 laufen lassen, Konfusionsmatrix, F1 pro Klasse, $kappa$ mit Intervall, $alpha$ über Läufe und über drei Paraphrasen berichten.

*Übung 3: Alternative Annotator Test (45 Minuten).* Mit der eigenen Implementierung oder dem Repository der Autoren auf einem Datensatz mit mindestens drei Menschen pro Item $epsilon in {0.05, 0.10, 0.15, 0.20}$ und $n in {30, 50, 100}$ variieren und $omega$ und $rho$ plotten; Diskussion, welches $epsilon$ man für Crowdworker und welches für Fachleute präregistrieren würde @calderon2025alternative.

*Übung 4: Verhaltenstests für ein Codebuch (45 Minuten).* Ein Codebuch mit 5 bis 8 Kategorien aus den Daten von Halterman und Keith; labelfreie Tests (erlaubte Labels, Wiedergabe der Definitionen, Invarianz gegen Reihenfolge) und labelpflichtige Tests (Ausschlusskriterien, vertauschte Labels) mit einem offenen Modell @halterman2026codebook.

*Übung 5: Konfigurations-Multiversum (Hausübung).* Dieselben 500 Items mit 3 Modellen und 3 Paraphrasen labeln, für jede der 9 Konfigurationen dieselbe logistische Regression rechnen, Koeffizienten mit Intervallen plotten und zählen, wie viele Konfigurationen Vorzeichen oder Signifikanz ändern @baumann2025large. Übergabe an Kapitel 6.

*Projekt: Induktives Codebuch aus offenen Antworten (zwei bis drei Einheiten).* 200 bis 400 offene Antworten auf eine Frage, geteilt in 60 % Ableitung und 40 % gesperrten Test. Zwei Studierende leiten unabhängig ein Codebuch ab und berichten ihre eigene Übereinstimmung. Das LLM leitet nach dem Workflow in @k05-induktiv ab, mit ITS-Kurve. Vergleich per Code-Abgleich und ARI, Verhandlung und Einfrieren, deduktive Validierung auf der Testmenge mit $kappa$, AC1 und Prävalenz pro Code, Alternative Annotator Test mit einer dritten Person und Fehlerraten pro Subgruppe @depaoli2025reflections @dai2023llm @deregnaucourt2026large @bergmann2026llms @dunivin2025scaling @ashwin2026using.

=== Typische Missverständnisse

- *"Kappa über 0.8 heißt, das LLM ist gut."* Kappa ohne Marginalien und ohne Mensch-Mensch-Vergleich sagt wenig; dieselbe Prozentübereinstimmung liefert je nach Prävalenz 0.80 oder $-0.05$.
- *"Fleiss' Kappa ist Cohens Kappa für mehr Leute."* Mit zwei Codierenden ist es Scotts $pi$, nicht Cohens $kappa$.
- *"Hohe Übereinstimmung zwischen Läufen beweist Qualität."* Sie beweist Reliabilität; $r = 0.36$ zwischen Lauf-Übereinstimmung und Genauigkeit bei Gilardi et al. @gilardi2023chatgpt.
- *"Mein $alpha$ ist 0.85."* Ohne Messniveau ist die Zahl uninterpretierbar, und die Bibliothek rechnet ohne Angabe intervallskaliert.
- *"Das LLM-Codebuch hat ARI 0.6, also ist es zu 60 % richtig."* ARI misst Ähnlichkeit der Gruppierung über dem Zufall, keinen Anteil richtiger Zuordnungen und keine Themenqualität.
- *"Das LLM hat 0.87 $kappa$ mit mir, besser als meine Kollegin."* Nach einer Verhandlungsrunde misst das Konvergenz, nicht unabhängige Reliabilität @dai2023llm.
- *"$epsilon = 0.2$ ist der Standard."* Es ist eine normative Kosten-Nutzen-Setzung für Fachleute, keine Konvention.

=== Zeitbedarf

Für die Grundlagen (Begriffe, Evidenz, Koeffizienten, Paradoxa) sind zwei Einheiten zu 90 Minuten realistisch, wobei Übung 1 den Großteil der zweiten Einheit füllt. Validierung und Alternative Annotator Test brauchen eine weitere Einheit, das induktive Codieren mit Projekt zwei bis drei. Wer kürzen muss, streicht das Multiversum (geht in Kapitel 6 auf) und behält Übung 1 und das induktive Projekt, weil dort die meisten Fehler passieren.

#vertiefung[
  Für die Statistik: Hayes und Krippendorff (2007) als kompakte Begründung für $alpha$ mit Bootstrap @hayes2007answering; Gwet (2008) für das Gegenargument und die Varianzschätzer @gwet2008computing; Feinstein und Cicchetti (1990) für die historischen Paradoxa @feinstein1990high. Für die LLM-Praxis: Törnberg (2024) als Checkliste @tornberg2024best, Pangakis et al. (2023) für den Validierungsworkflow @pangakis2023automated, Baumann et al. (2025) für die Folgen auf Schlussfolgerungen @baumann2025large und Calderon et al. (2025) für den Ersetzungstest @calderon2025alternative. Für das induktive Codieren: Dunivin (2025) für die Codebuch-Anpassung @dunivin2025scaling, DeRegnaucourt et al. (2026) für die Asymmetrie zwischen Ableiten und Anwenden @deregnaucourt2026large, Bergmann et al. (2026) für den ARI-Vergleich bei offenen Befragungsantworten @bergmann2026llms und De Paoli und Mathis (2025) für die Sättigung @depaoli2025reflections. Als Rahmen für die Kontroverse um Referenzstandards Plank (2022) @plank2022problem.
]

#selbsttest(
  [Berechne für die Tafel $[[30, 10], [20, 40]]$ (Mensch in Zeilen, LLM in Spalten) $p_o$, Cohens $kappa$, Scotts $pi$, Gwets AC1 und PABAK. Begründe mit @k05-eq-scott-cohen, warum $kappa > pi$.],
  [Zeige, dass gewichtetes $kappa$ mit den Gewichten $w_(i j) = 1$ für $i != j$ und $w_(i i) = 0$ in Cohens ungewichtetes $kappa$ übergeht.],
  [Ein LLM und eine Fachperson labeln 200 Kommentare auf Hassrede; Prävalenz bei beiden 4 %, Prozentübereinstimmung 95 %, Unstimmigkeiten symmetrisch. Berechne $kappa$ und AC1 mit @k05-eq-praevalenz und beurteile, welche Zahl die Fähigkeit des LLM, Hassrede zu erkennen, besser beschreibt.],
  [Berechne Fleiss' $kappa$ für drei Codierende und vier Items mit den Labels (A, A, A), (A, A, B), (B, B, B), (A, B, B).],
  [Berechne Krippendorffs $alpha$ (nominal) für E1, wenn bei 10 der 100 Texte das LLM-Label fehlt und diese 10 Texte alle in Zelle $a$ (beide 0) gelegen hätten. Wie verändert sich $n$, und warum werden die Texte nicht als Unstimmigkeit gezählt?],
  [Erkläre, warum die ordinale Differenzfunktion $delta^2_"ord"$ von den Randhäufigkeiten abhängt, und berechne $delta^2_(1 3)$ für die Koinzidenzmatrix von E5.],
  [Wie viele Items braucht eine Validierungsstichprobe nach @k05-eq-se für eine halbe Breite von 0.05 bei $p_o = 0.9$ und $p_e = 0.6$? Was ändert sich, wenn $p_e = 0.8$?],
  [Beschreibe, wie du ein 95-%-Bootstrap-Intervall für AC1 bestimmst, wenn jedes Item von drei Personen codiert wurde und einzelne Labels fehlen. Was ist die Resampling-Einheit und warum?],
  [Im Alternative Annotator Test seien $n = 50$ Items und für eine herausgelassene Person $j$ gelte $rho_j^f = 0.80$, $rho_j^h = 0.90$, und die Differenzen $d_(i j)$ haben Standardabweichung $s_j = 0.50$. Berechne $t_j$ für $epsilon = 0.15$ und für $epsilon = 0.25$ und entscheide jeweils einseitig bei $alpha = 0.05$ (ohne Mehrfachkorrektur; kritischer Wert etwa $-1.68$).],
  [Berechne den ARI und den Rand-Index für sechs Antworten mit menschlicher Partition (X, X, X, Y, Y, Y) und LLM-Partition (P, P, Q, Q, R, R). Interpretiere den Unterschied.],
  [Ein LLM erzeugt über 20 Interviews 300 Codes, davon 45 einzigartig; eine zweite Analyse mit anderer Interviewreihenfolge ergibt 52 einzigartige. Berechne beide ITS-Werte und diskutiere, was die Differenz über das Maß aussagt.],
  [Eine Studie berichtet: "GPT-4o codierte 1000 offene Antworten mit Cohens $kappa = 0.82$ gegenüber einer Autorin; das Codebuch wurde gemeinsam mit dem Modell entwickelt." Nenne mindestens vier Informationen, die fehlen, um die Aussage beurteilen zu können, und begründe jede mit diesem Kapitel.],
)

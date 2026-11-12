#import "../lib.typ": *

// Lokale Plot-Helfer für dieses Kapitel (nur cetz-Grundbausteine, Farben aus lib.typ)
#let k04-t(body, size: 7pt, fill: c-dark, weight: "regular") = text(font: "Inter", size: size, fill: fill, weight: weight, body)

= LLMs als Forschungsinstrument <k04>

Wenn du ein Sprachmodell bittest, einen Fragebogen "als 45-jährige Krankenpflegerin aus dem ländlichen Ohio" zu beantworten, bekommst du in Sekunden eine plausible Antwort. Wenn du das tausendmal mit tausend verschiedenen Personenbeschreibungen machst, hast du einen Datensatz, der aussieht wie eine Umfrage. Genau diese Möglichkeit hat in den letzten Jahren eine ganze Forschungsrichtung hervorgebracht: Sprachmodelle erzeugen Umfrageantworten, die bisher von Menschen kamen @argyle2023out, verhalten sich in klassischen Experimenten der Ökonomie und Psychologie wie Versuchspersonen @horton2023large @aher2023using, fällen moralische Urteile @dillion2023can und sagen sogar Versuch für Versuch menschliche Entscheidungen in kognitiven Aufgaben vorher @binz2025foundation. Parallel dazu übernehmen Sprachmodelle Forschungsaufgaben selbst: Literatur zusammenfassen, Ideen generieren, Experimente programmieren und Paper schreiben @lu2026towards @si2025can.

Das Versprechen ist verlockend: billige Pilotstudien, schnelle Vorhersagen, ob sich ein teures Experiment lohnt, und Zugang zu Populationen, die schwer zu erreichen sind. In der Fassung des Manuskripts von August 2024 korrelierten GPT-4-Vorhersagen für 476 Behandlungseffekte aus 70 präregistrierten US-Umfrageexperimenten mit $r = 0.85$ mit den tatsächlich beobachteten Effekten @hewitt2024predicting[Abb. 2A]; die 2026 in _Nature_ erschienene Fassung berichtet für dieselben 70 Experimente 469 Effekte und 119 330 Teilnehmende @ashokkumar2026large. Das Risiko ist ebenso deutlich: Synthetische Befragte, deren Mittelwerte gut zu einer nationalen Wahlstudie passten, lieferten Regressionskoeffizienten, von denen 48 % signifikant von den menschlichen abwichen, und bei 32 % dieser abweichenden Koeffizienten drehte sich sogar das Vorzeichen um @bisbee2024synthetic[Abschn. 2.2, Abb. 3].

Dieses Kapitel vertritt eine einzige zentrale These, die sich durch alle Abschnitte zieht: *Die Ausgabe eines LLM ist eine Messung, und ein LLM-basierter Simulator ist ein Messinstrument.* Ein Instrument braucht Belege für Reliabilität (liefert es bei Wiederholung dasselbe?) und für Validität (misst es das, was es messen soll?), bevor seine Ausgaben Schlussfolgerungen tragen dürfen @bisbee2024synthetic @mangiaterra2025can @li2026statistical. Für dich als Forscher, der Methodik lehrt, ist das die eigentlich gute Nachricht: Die Werkzeuge, mit denen man dieses Feld kritisch durchdringt, sind die klassischen Werkzeuge der Messtheorie und der Validitätsprüfung, die du bereits kennst. Neu ist nur, dass das Instrument selbst ein bewegliches Ziel ist.

Das Kapitel ist so aufgebaut, dass zuerst der messtheoretische Rahmen steht (@k04-mess), dann die drei großen Anwendungsfelder folgen: synthetische Befragte (_silicon samples_), simulierte Experimente und Verhalten sowie automatisierte Forschung durch _AI Scientists_. Dazwischen liegt ein mathematischer Abschnitt über den Vergleich von Antwortverteilungen, den du für die Übungen und das Notebook der Lehrveranstaltung brauchst. Den Abschluss bilden die Validitätsbedrohungen, die Debatte um Ersatz oder Ergänzung menschlicher Teilnehmender und die Berichtsstandards. Die Annotation durch LLMs ist Thema von Kapitel 5, die statistische Korrektur von LLM-Messfehlern Thema von Kapitel 6 und LLMs als Bewerter Thema von Kapitel 7.

#lernziele[
  Die Begriffe _silicon sampling_, algorithmische Treue, Turing-Experiment, generativer Agent und _foundation model of cognition_ erklären und ein Studiendesign einem davon zuordnen.
][
  Ein LLM-basiertes Simulationsinstrument messtheoretisch beschreiben (Hintergrundkonzept, systematisiertes Konzept, Instrument, Messung) und ein Validitätsargument dafür aufbauen.
][
  Antwortverteilungen von Menschen und Modell mit Wasserstein-Distanz, OpinionQA-Alignment, Jensen-Shannon-Divergenz und normierter Entropie vergleichen, die Formeln herleiten und von Hand rechnen.
][
  Eine synthetische Stichprobe auf drei Ebenen bewerten (Randverteilungen, Varianzen und Gruppenunterschiede, Koeffizienten und Behandlungseffekte) und begründen, welche Ebene eine Forschungsfrage verlangt.
][
  Den Forschungsstand zu Silicon Samples, simulierten Experimenten, Centaur, generativen Agenten und AI Scientists mit konkreten Zahlen wiedergeben, einschließlich der positiven Befunde nach Fine-Tuning.
][
  Validitätsbedrohungen (Prompt-Sensitivität, Kontamination, geschlossene Modelle, Deprecation, Drift, Schnittstelleneffekte) diagnostizieren und Gegenmaßnahmen planen.
][
  Eine Studie gegen die 14 Kernpunkte von GUIDE-LLM prüfen und die Verwendung geschlossener Modelle begründen.
]

== Die Ausgabe eines LLM als Messung <k04-mess>

=== Intuition: Das Modell ist nicht der Befragte

Der wichtigste gedankliche Schritt dieses Kapitels ist unscheinbar. Wenn ein Modell im Namen einer Persona antwortet, entsteht keine Beobachtung eines Menschen, sondern eine Zahl (oder ein Text), die ein technisches System auf Grundlage einer Eingabe erzeugt hat. Diese Zahl soll etwas über Menschen aussagen: über die Verteilung von Meinungen in einer Bevölkerungsgruppe, über die Größe eines Behandlungseffekts oder über eine Normbewertung, etwa wie vertraut eine Metapher ist. Damit erfüllt das Modell exakt die Rolle eines Messinstruments. Ein Fragebogen ist ein Instrument, um eine latente Einstellung zu messen; ein LLM-Simulator ist ein Instrument, um eine *menschliche Größe* zu messen, ohne Menschen zu befragen.

Aus dieser Perspektive verlieren viele aufgeregte Debatten ihre Schärfe. Die Frage "Denkt das Modell wie ein Mensch?" ist für die meisten Forschungszwecke falsch gestellt. Die richtige Frage lautet: Welche Belege gibt es, dass die Ausgaben dieses Instruments, in diesem Anwendungsbereich, auf dieser Ebene (Mittelwert, Verteilung, Zusammenhang, Effekt), mit der menschlichen Zielgröße übereinstimmen, und wie stabil ist das Instrument bei Wiederholung? Das ist eine empirische Frage mit messtheoretischer Struktur @mangiaterra2025can[Abschn. 2.3, 3.1-3.3].

=== Messmodellierung nach Jacobs und Wallach

Jacobs und Wallach haben für die Fairness-Forschung ausgearbeitet, was _Messmodellierung_ (_measurement modeling_) bedeutet: Ein nicht beobachtbares theoretisches Konstrukt wird über eine Operationalisierung mit beobachtbaren Daten verbunden; die Annahmen dieser Verbindung bilden das Messmodell @jacobs2021measurement[Abschn. 2-3]. Zwei Eigenschaften entscheiden über die Qualität: *Konstruktreliabilität*, also die Konsistenz wiederholter Messungen (etwa Test-Retest), und *Konstruktvalidität*, also die Frage, ob die Messungen tatsächlich das intendierte Konstrukt erfassen. Beide sind keine Ja-Nein-Eigenschaften, sondern *Gradfragen*. Jacobs und Wallach unterscheiden sieben Aspekte der Konstruktvalidität: Augenscheinvalidität (_face validity_), Inhaltsvalidität, konvergente, diskriminante und prädiktive Validität, Hypothesenvalidität und konsequenzielle Validität @jacobs2021measurement[Abschn. 3.2.1-3.2.7].

Wallach et al. übertragen diesen Rahmen auf die Evaluation generativer KI und argumentieren in einem Positionspapier, dass sie eine sozialwissenschaftliche Messaufgabe ist @wallach2025position. Ihr Rahmenwerk, adaptiert von Adcock und Collier, kennt vier Ebenen: Hintergrundkonzept -> systematisiertes Konzept -> Messinstrumente -> Messungen. Die Ebenen sind durch vier Prozesse verbunden: _Systematisierung_, _Operationalisierung_, _Anwendung_ und _Interrogation_, also die kritische Befragung, ob jeder Schritt hält @wallach2025position[Abb. 1, Abschn. 2]. Die Validitätsperspektiven entsprechen denen von Jacobs und Wallach @wallach2025position[Abschn. 2.4].

Die Herkunft dieser Sicht reicht weiter zurück. Messick hat Validierung als wissenschaftliche Untersuchung der _Bedeutung von Testwerten_ verstanden; schon der Titel seines Aufsatzes formuliert dieses Programm @messick1995validity. Im Lehrbuch der Reihe findest du die klassische Fassung für quantitative Forschung: Konstruktvalidität stellt sicher, dass Maße die theoretischen Konstrukte abbilden, und wird über Inhaltsvalidität (Fachleute bestätigen, dass die Items den Konstruktbereich abdecken), konvergente Validität (Korrelation mit verwandten Maßen), diskriminante Validität (geringe Korrelation mit nicht verwandten Konstrukten) und Faktorstruktur belegt @haindl2027research @Cronbach1955. Dazu kommt die *Messinvarianz*: Ein Instrument muss über Gruppen und Zeitpunkte hinweg dasselbe bedeuten, bevor man Gruppen vergleicht oder Veränderungen über die Zeit verfolgt; geprüft wird das klassisch mit konfiguraler, metrischer und skalarer Invarianz in einer Mehrgruppen-Faktorenanalyse @haindl2027research @Vandenberg2000.

#figure(
  {
    set text(font: "Inter", size: 7.4pt, hyphenate: false)
    diagram(spacing: (9mm, 9mm), edge-stroke: 0.8pt + c-dark, mark-scale: 70%,
      fknoten((0, 0), [*Hintergrundkonzept* \ "Meinung der US-Bevölkerung zu Thema X"], col: c-blue, w: 46mm),
      fknoten((0, 1), [*Systematisiertes Konzept* \ Survey-Item, Antwortskala, Zielpopulation], col: c-blue, w: 46mm),
      fknoten((0, 2), [*Messinstrument* \ Modell-Snapshot + Persona-Vorlage \ + Decoding-Parameter + Antwort-Parser], col: c-accent, w: 46mm),
      fknoten((0, 3), [*Messungen* \ synthetische Antwortverteilungen], col: c-teal, w: 46mm),
      edge((0, 0), (0, 1), "-|>", label: [Systematisierung], label-side: right),
      edge((0, 1), (0, 2), "-|>", label: [Operationalisierung], label-side: right),
      edge((0, 2), (0, 3), "-|>", label: [Anwendung], label-side: right),
      edge((0, 3), (0, 0), "-|>", bend: -55deg, stroke: (paint: c-red, thickness: 0.8pt, dash: "dashed"), label: text(fill: c-red)[*Interrogation*: \ hält jeder Schritt?], label-side: right),
      fknoten((2, 0), [Konsequenzielle Validität: \ schadet die Darstellung Gruppen?], col: c-grey, w: 40mm),
      fknoten((2, 1), [Inhalts- und Augenscheinvalidität: \ deckt das Item den Begriff ab?], col: c-grey, w: 40mm),
      fknoten((2, 2), [Reliabilität: Sitzungen, \ Versionen, Prompt-Varianten], col: c-grey, w: 40mm),
      fknoten((2, 3), [Konvergent, diskriminant, prädiktiv, \ Hypothesenvalidität], col: c-grey, w: 40mm),
      edge((0, 0), (2, 0), "-", stroke: (paint: c-grey, thickness: 0.5pt, dash: "dashed")),
      edge((0, 1), (2, 1), "-", stroke: (paint: c-grey, thickness: 0.5pt, dash: "dashed")),
      edge((0, 2), (2, 2), "-", stroke: (paint: c-grey, thickness: 0.5pt, dash: "dashed")),
      edge((0, 3), (2, 3), "-", stroke: (paint: c-grey, thickness: 0.5pt, dash: "dashed")),
    )
  },
  caption: [Die vier Ebenen der Messmodellierung nach Wallach et al. @wallach2025position, angewandt auf einen LLM-Simulator (Zuordnung nach dem Dossier der Lehrveranstaltung). Rechts die Validitätsaspekte nach Jacobs und Wallach @jacobs2021measurement, die an der jeweiligen Ebene ansetzen.],
) <k04-fig-ebenen>

=== Was genau ist das Instrument?

@k04-fig-ebenen enthält eine Festlegung, die in vielen Studien stillschweigend fehlt: Das Instrument ist *nicht* "das Modell". Das Instrument ist die Kombination aus einem konkreten Modell-Snapshot, einer Persona- oder Prompt-Vorlage, den Decoding-Parametern und dem Parser, der aus Text eine Antwortkategorie macht. Wer eine dieser Komponenten ändert, hat ein anderes Instrument. Das lässt sich formal fassen.

#definition(titel: [LLM-Messinstrument])[
  Sei $x_i$ die Beschreibung einer Einheit $i$ (etwa das soziodemografische Profil einer befragten Person) und $q$ ein Item. Ein *LLM-Messinstrument* ist eine Abbildung
  $ hat(y)_(i q) = rho(g_(theta)(tau(x_i, q); delta)) $ <k04-eq-instrument>
  mit dem Modell-Snapshot $theta$ (fixe Gewichte einer bestimmten Version), der Prompt-Vorlage $tau$, die aus Profil und Item einen Eingabetext macht, den Decoding-Parametern $delta$ (Temperatur, Top-$p$, Seed, maximale Länge), dem stochastischen Generator $g_theta$ und dem Parser $rho$, der den erzeugten Text auf eine Antwortkategorie oder einen Zahlenwert abbildet. Die Zielgröße ist eine menschliche Größe $y_(i q)$ oder ein Funktional davon, etwa die Antwortverteilung einer Gruppe oder ein Behandlungseffekt.
]

Die Definition macht drei Dinge sichtbar. Erstens ist $hat(y)_(i q)$ eine Zufallsvariable, solange $g_theta$ mit Temperatur größer null stichprobt; eine einzelne Ausgabe ist daher, wie das Lehrbuch formuliert, eher eine Anekdote als eine Messung @haindl2027research. Zweitens hängt das Ergebnis an vier Stellschrauben ($theta$, $tau$, $delta$, $rho$), die alle berichtet werden müssen. Drittens ist die Zielgröße oft nicht $y_(i q)$ selbst, sondern ein Aggregat. Ob das Instrument für ein Aggregat valide ist, sagt wenig darüber, ob es für ein anderes valide ist; das wird uns in @k04-sim mit dem Befund von Li und Ji wieder begegnen @li2026statistical.

#merke[Ein Instrument ist erst durch alle vier Komponenten bestimmt: Modell-Snapshot, Prompt-Vorlage, Decoding-Parameter und Parser. "Wir haben GPT verwendet" ist, wie das Lehrbuch es pointiert, ungefähr so informativ wie "wir haben einen Computer verwendet" @haindl2027research.]

=== Reliabilität: drei Achsen der Wiederholung

Für ein klassisches Instrument heißt Reliabilität: Wiederholte Messungen derselben Größe stimmen überein. Für ein LLM-Instrument gibt es drei Achsen der Wiederholung, und die Literatur verwendet alle drei @mangiaterra2025can @bisbee2024synthetic @hewitt2024predicting:

+ *Über Sitzungen:* gleicher Prompt, gleiches Modell, zwei unabhängige Durchläufe. Mangiaterra et al. fanden für GPT-4o-mini über die API bei Temperatur 0 Test-Retest-Korrelationen von 0.97 bis 0.99, über die ChatGPT-Oberfläche dagegen nur 0.66 bis 0.91 @mangiaterra2025can[Abschn. 3.3, Tab. 3].
+ *Über Modellversionen und Zeitpunkte:* identische Prompts, zu verschiedenen Zeitpunkten gegen einen geschlossenen Dienst ausgeführt. Bisbee et al. fanden zwischen April- und Juni-2023-Läufen eine Steigung von 0.93 und im Juli eine deutliche Regression zur Mitte, plausibel ausgelöst durch ein Modell-Update des Anbieters am 25. Juni 2023 @bisbee2024synthetic[Abschn. 3.2, Abb. 5].
+ *Über Prompt-Varianten:* inhaltlich gleichwertige Formulierungen oder Persona-Varianten. Hewitt et al. mittelten deshalb über ein Ensemble von Prompts @hewitt2024predicting; das Weglassen politischer Attribute aus den Personas erhöhte bei Bisbee et al. die Fehler deutlich @bisbee2024synthetic[Abschn. 3.1, Abb. 4].

Die dritte Achse steht im Lehrbuch unter dem Stichwort Prompt-Sensitivität und wird in @k04-bedrohungen ausführlich behandelt @haindl2027research.

=== Kontinuierliche Ratings aus Token-Wahrscheinlichkeiten

Ein Trick, den Mangiaterra et al. verwenden, verdient eine eigene Darstellung, weil er die Reliabilität von Ratings deutlich verbessert. Statt eine Zahl als Text zu generieren und zu parsen, setzt man Temperatur 0, lässt genau ein Ausgabe-Token zu und liest die Log-Wahrscheinlichkeiten der drei wahrscheinlichsten Token aus. Das Rating ist dann ein wahrscheinlichkeitsgewichteter Mittelwert @mangiaterra2025can[Abschn. 2.3.1]:
$ hat(r) = (sum_(k in "Top-3") p_k dot k) / (sum_(k in "Top-3") p_k) $ <k04-eq-logprob>
Dabei ist $k$ der Ratingwert, den ein Token repräsentiert, und $p_k$ seine Token-Wahrscheinlichkeit. Die Normierung im Nenner ist nötig, weil die drei Wahrscheinlichkeiten nicht auf 1 summieren müssen.

#beispiel(titel: [Gewichtetes Rating aus Log-Wahrscheinlichkeiten])[
  Ein Modell soll die Vertrautheit einer Metapher auf einer Skala von 1 bis 7 bewerten. Die drei wahrscheinlichsten Token sind "5" mit $p = 0.60$, "4" mit $p = 0.30$ und "6" mit $p = 0.05$. Nach @k04-eq-logprob ergibt sich
  $ hat(r) = (0.60 dot 5 + 0.30 dot 4 + 0.05 dot 6) / (0.60 + 0.30 + 0.05) = (3.00 + 1.20 + 0.30) / 0.95 = 4.50 / 0.95 approx 4.74. $
  Das Ergebnis liegt zwischen den Kategorien und ist bei Temperatur 0 deterministisch, solange sich die Wahrscheinlichkeiten nicht ändern. Ein gesampeltes Text-Token hätte dagegen bei Temperatur 1 in etwa 60 % der Fälle "5" und sonst meist "4" oder "6" geliefert.
]

=== Die Obergrenze: menschliche Test-Retest-Reliabilität

Ein zweiter Gedanke aus der klassischen Testtheorie ist für LLM-Simulatoren zentral: Kein Instrument kann eine Person besser vorhersagen, als diese Person sich selbst reproduziert. Park et al. haben daraus eine Normierung gemacht. Sie führten mit 1052 Personen zweistündige, KI-geführte Interviews und ließen dieselben Fragebögen zwei Wochen später erneut ausfüllen; die Vorhersagegenauigkeit ihrer Agenten wird durch die Selbstkonsistenz der Personen geteilt @park2024llm[Results].

#definition(titel: [Normierte Genauigkeit nach Park et al.])[
  Seien $y_i^((1))$ die Antworten von Person $i$ in Welle 1, $y_i^((2))$ ihre Antworten zwei Wochen später und $hat(y)_i$ die Vorhersagen des Agenten. Mit $"acc"(a, b)$ als Anteil identischer Antworten ist
  $ "NA"_i = "acc"(hat(y)_i, y_i^((1))) / "acc"(y_i^((2)), y_i^((1))). $ <k04-eq-na>
  Für stetige Ergebnisse wird analog das Verhältnis von Korrelationen verwendet ("normierte Korrelation") @park2024llm[Results].
]

#beispiel(titel: [Normierte Genauigkeit im GSS])[
  Interview-basierte Agenten trafen die Antworten im General Social Survey (GSS) roh zu 65.67 %, die Personen selbst reproduzierten ihre Antworten zu 79.53 % @park2024llm[Results]. Nach @k04-eq-na ist $"NA" = 65.67 \/ 79.53 approx 0.826$, also rund 0.83. Der Agent erreicht 83 % der Genauigkeit, mit der eine Person sich selbst vorhersagt. Ohne die Normierung wäre "65.67 %" kaum interpretierbar: Bei einem Item, das Menschen nur zu 60 % stabil beantworten, wären 60 % perfekt.
]

Dahinter steckt ein allgemeines Resultat, das du aus der Testtheorie kennst und das in der LLM-Literatur als disattenuierte Korrelation $r_"adj"$ wieder auftaucht @hewitt2024predicting.

#satz(titel: [Reliabilität begrenzt Validität])[
  Seien $X = T_X + E_X$ und $Y = T_Y + E_Y$ Messungen mit wahren Werten $T$ und Fehlern $E$, wobei die Fehler untereinander und mit den wahren Werten unkorreliert sind. Mit den Reliabilitäten $rho_X = "Var"(T_X) \/ "Var"(X)$ und $rho_Y = "Var"(T_Y) \/ "Var"(Y)$ gilt
  $ "corr"(X, Y) = "corr"(T_X, T_Y) dot sqrt(rho_X rho_Y), quad "also" quad |"corr"(X, Y)| <= sqrt(rho_X rho_Y). $ <k04-eq-atten>
]

#beweis[
  Wegen der Unkorreliertheit der Fehler ist $"Cov"(X, Y) = "Cov"(T_X, T_Y)$. Also
  $"corr"(X, Y) = "Cov"(T_X, T_Y) \/ sqrt("Var"(X) "Var"(Y))$. Erweitern mit $sqrt("Var"(T_X) "Var"(T_Y))$ liefert
  $"corr"(T_X, T_Y) dot sqrt("Var"(T_X) \/ "Var"(X)) dot sqrt("Var"(T_Y) \/ "Var"(Y))$, das ist @k04-eq-atten. Da $|"corr"(T_X, T_Y)| <= 1$, folgt die Schranke. Umgekehrt erhält man durch Division die um Messfehler bereinigte (disattenuierte) Korrelation $r_"adj" = r \/ sqrt(rho_X rho_Y)$.
]

Für die Bewertung von LLM-Simulatoren folgt daraus zweierlei. Erstens ist die Korrelation zwischen Modellvorhersage und beobachtetem menschlichen Effekt nach oben durch die Reliabilität der menschlichen Effektschätzung begrenzt; Hewitt et al. berichten deshalb neben $r = 0.85$ auch $r_"adj" = 0.91$ (Preprint 2024) @hewitt2024predicting[Abb. 2A]. Zweitens kann ein unzuverlässiges Instrument (etwa ein Chat-Interface mit Test-Retest 0.66) nie hoch valide sein, selbst wenn es im Mittel richtig liegt.

=== Validitätsbelege für LLM-Simulatoren

Welche Belege braucht ein Validitätsargument konkret? Die Literatur zu LLM-Simulatoren nutzt die Aspekte von Jacobs und Wallach in sehr unterschiedlichem Ausmaß. Konvergente Evidenz (Übereinstimmung mit einer menschlichen Stichprobe) ist der Normalfall; die übrigen Aspekte sind genau die Stellen, an denen Simulatoren scheitern. @k04-tab-validitaet ordnet die Aspekte Fragen und Befunden zu; die Zuordnung ist eine Synthese aus dem Dossier der Lehrveranstaltung.

#figure(
  table(columns: (auto, 1fr, 1.3fr),
    [Aspekt], [Frage an den Simulator], [Beleg in der Literatur],
    [Konvergent], [Stimmt er mit menschlichen Stichproben überein?], [OpinionQA-Alignment @santurkar2023whose; Pew-Replikation mit digitalen Zwillingen, im Mittel rund 12 Prozentpunkte daneben @chapekis2026can],
    [Diskriminant], [Erzeugt er keine Scheinzusammenhänge?], [3 von 10 Mediationspfade, die bei Menschen null sind, wurden fälschlich signifikant @lukauskas2026plausible[Abschn. 5.7]],
    [Prädiktiv], [Funktioniert er in nachgelagerten Modellen?], [GPT-4o-Vertrautheitsnormen sagen Antwortzeiten ähnlich gut vorher wie menschliche Normen ($beta = -0.038$ vs. $-0.046$) @mangiaterra2025can[Abschn. 3.2]],
    [Hypothesen], [Reproduziert er bekannte Effekte und bekannte Nulleffekte?], [Signifikante Ergebnisse in 68-83 % der Fälle, in denen die Originalstudie keinen Effekt fand @cui2024can],
    [Konsequenziell], [Schadet er den dargestellten Gruppen?], [Fehldarstellung und Abflachung von Identitätsgruppen @wang2025large],
    [Invarianz], [Bedeutet die Messung in allen Gruppen dasselbe?], [Subgruppenlücken auch bei Interview-Agenten (Ideologie-DPD 8.60 % vs. 13.75 %) @park2024llm[Abb. 3]],
  ),
  caption: [Validitätsaspekte nach Jacobs und Wallach @jacobs2021measurement, ergänzt um die Messinvarianz aus dem Lehrbuch @haindl2027research, übersetzt in Prüffragen an einen LLM-Simulator, mit je einem Beleg.],
) <k04-tab-validitaet>

#studie(titel: [Mangiaterra et al. 2025])[
  *Design:* Psychometrische Validierung von GPT-3.5-turbo, GPT-4o-mini und GPT-4o als Rater für Metaphernnormen; 687 Metaphern (469 italienisch, 218 englisch), Dimensionen Vertrautheit, Bildhaftigkeit und Verständlichkeit; Temperatur 0, ein Ausgabe-Token, gewichtete Top-3-Ratings nach @k04-eq-logprob; zwei Sitzungen pro Modell; GPT-4o-mini zusätzlich über die ChatGPT-Oberfläche @mangiaterra2025can[Abschn. 2]. \
  *Befund:* Konvergente Validität für Verständlichkeit (englisch) $r = 0.69$ bis $0.79$, für Vertrautheit englisch 0.50-0.64 und italienisch 0.20-0.65, für Bildhaftigkeit 0.37-0.65 @mangiaterra2025can[Tab. 2]. Prädiktive Validität: GPT-4o-Vertrautheit sagt Antwortzeiten ähnlich gut vorher wie menschliche Normen. Reliabilität über die API 0.97-0.99, über die Oberfläche 0.66-0.91 @mangiaterra2025can[Tab. 3]. Die Fehler wachsen mit dem menschlichen Rating und sind für die verkörperte Dimension Bildhaftigkeit am größten @mangiaterra2025can[Abb. 5]. \
  *Grenzen:* Nur 364 der 687 Metaphern stammen aus Datensätzen, die vor dem Trainings-Cutoff nicht online waren; die Modelle approximieren eine durchschnittliche (studentische) Bewertungsperson, keine Individuen @mangiaterra2025can[Abschn. 4]. Preprint.
]

Die Studie ist das beste Beispiel dieses Kapitels für ein vollständiges Validitätsargument: konvergente und prädiktive Validität, Reliabilität über Sitzungen und Zugangswege und eine offene Diskussion der Kontamination. Ein zweites Musterbeispiel stammt aus der Persönlichkeitsmessung.

#studie(titel: [Serapio-García et al. 2025])[
  *Design:* 18 LLMs beantworten IPIP-NEO-300 und BFI-44 sowie 11 Kriteriumstests; rund 1250 prompt-variierte Antwortprofile pro Modell; Reliabilität mit Cronbachs $alpha$, Guttmans $lambda_6$ und McDonalds $omega$, konvergente und diskriminante Validität im Multitrait-Multimethod-Design, Kriteriumsvalidität @serapiogarcia2025psychometric[Tab. 2]. \
  *Befund:* Reliabilität und Validität sind für größere, instruktionsgetunte Modelle stärker; Basismodelle bestehen die konvergenten und diskriminanten Prüfungen nicht; Flan-PaLM 540B und GPT-4o erreichen konvergente Korrelationen um 0.90; gezieltes Formen eines einzelnen Merkmals gelingt mit Spearman $rho >= 0.80$ für 11 von 12 Modellen @serapiogarcia2025psychometric[Abschn. 2.2, 3.3]. \
  *Grenzen:* Die Studie misst Persönlichkeit _des Modells_, nicht die einer menschlichen Population; sie ist eine Vorlage für das Verfahren, kein Beleg für Simulationsgüte.
]

=== Das Validitätsargument als Kette

Aus den bisherigen Bausteinen ergibt sich ein Muster, das du in jeder Begutachtung einer LLM-Simulationsstudie anwenden kannst. Ein Validitätsargument ist eine Kette von Schritten, und jeder Schritt braucht eigene Belege:

+ *Konzept:* Was ist die menschliche Zielgröße, und auf welcher Ebene wird ein Anspruch erhoben (Mittelwert, Verteilung, Zusammenhang, Effekt, Heterogenität)?
+ *Instrument:* Sind Snapshot, Prompt-Vorlage, Decoding und Parser vollständig festgelegt und berichtet?
+ *Reliabilität:* Sind die Ergebnisse über Sitzungen, Prompt-Varianten und (bei geschlossenen Modellen) über die Zeit stabil?
+ *Konvergenz auf der richtigen Ebene:* Wurde die Übereinstimmung mit menschlichen Daten auf genau der Ebene geprüft, auf der die Studie ihre Schlüsse zieht?
+ *Diskriminanz und Hypothesen:* Werden bekannte Nulleffekte als null reproduziert, und entstehen keine Scheinzusammenhänge?
+ *Kontamination:* Könnte das Instrument das Ziel auswendig kennen?
+ *Konsequenzen:* Wer wird durch die Darstellung möglicherweise geschädigt?

Fehlt ein Glied, trägt die Kette nicht. Die folgenden Abschnitte zeigen, an welchen Gliedern die großen Studien des Feldes gehalten haben und an welchen sie gerissen sind.

#hoersaal([Wenn ein Modell mit menschlichen Urteilen zu $r = 0.95$ korreliert, ist das nicht schon ein sehr starker Validitätsbeleg?], [Es ist ein Beleg für konvergente Validität auf einer bestimmten Ebene, nämlich für die Mittelwerte von Items, die das Modell möglicherweise kennt. Dillion et al. berichten genau diese Korrelation für GPT-3.5 und durchschnittliche menschliche Moralurteile @dillion2023can[Box 1]. Schröder et al. haben dieselben Szenarien minimal so umformuliert, dass sich die Bedeutung ändert: Menschen änderten ihre Urteile stark (Korrelation original vs. umformuliert $r = .54$), GPT-4 kaum ($r = .99$) @schroder2025large[Abschn. 4]. Hohe Korrelation auf bekannten Items ist also mit einem Instrument vereinbar, das auf Oberflächenähnlichkeit statt auf Bedeutung reagiert. Für ein Validitätsargument fehlen dann die Glieder Diskriminanz und Kontamination.])

#hoersaal([Ist Temperatur 0 nicht einfach die Lösung für das Reliabilitätsproblem?], [Sie löst das Problem der Wiederholbarkeit innerhalb eines Snapshots, aber zu einem Preis. Das Lehrbuch weist darauf hin, dass eine Temperatur nahe null das System an einem Extrempunkt seines Betriebsbereichs beschreibt und genau die Variabilität unterdrücken kann, die eine Reliabilitätsstudie erfassen sollte @haindl2027research. Für Simulationen kommt hinzu: Wer eine Verteilung simulieren will, braucht Streuung; Temperatur 0 erzeugt pro Persona genau eine Antwort und verstärkt die Abflachung, die in @k04-silicon besprochen wird. Für Ratings mit Log-Wahrscheinlichkeiten wie bei Mangiaterra et al. ist Temperatur 0 dagegen sinnvoll, weil die Unsicherheit in den Wahrscheinlichkeiten steckt und nicht im Sampling.])


== Silicon Samples: synthetische Befragte <k04-silicon>

=== Die Grundidee

Die Studie, die das Feld begründet hat, trägt den programmatischen Titel _Out of One, Many_. Argyle et al. konditionierten GPT-3 davinci auf Hintergrundgeschichten in der ersten Person, die aus den soziodemografischen Profilen realer Befragter der American National Election Studies (ANES) gebaut wurden, und ließen das Modell bei Temperatur 0.7 deren Antworten fortsetzen @argyle2023out[Methods]. Ein Prompt zur Wahlentscheidung endet etwa mit "In 2016, I voted for" @argyle2023out[Anhang A]. Für jede reale Person entsteht so eine synthetische "Silizium-Person"; die Gesamtheit heißt _silicon sample_.

#definition(titel: [Silicon Sample])[
  Ein *Silicon Sample* ist eine Menge LLM-generierter Befragter, von denen jeder dadurch entsteht, dass das Modell auf eine Hintergrundgeschichte konditioniert wird, die aus dem soziodemografischen Profil einer realen befragten Person gebaut ist @argyle2023out[Methods]. In der Notation von @k04-eq-instrument ist $x_i$ das Profil der realen Person $i$, $tau$ die Backstory-Vorlage und $hat(y)_(i q)$ die synthetische Antwort auf Item $q$.
]

#figure(
  {
    set text(font: "Inter", size: 7.4pt, hyphenate: false)
    diagram(spacing: (3.5mm, 8mm), edge-stroke: 0.8pt + c-dark, mark-scale: 70%,
      fknoten((0, 0), [Profil der realen \ Person $i$ (ANES, ATP)], col: c-blue, filled: true, w: 27mm),
      fknoten((1, 0), [Backstory in \ 1. Person, Item $q$], col: c-blue, w: 27mm),
      fknoten((2, 0), [LLM $g_theta$ \ (Snapshot, Decoding)], col: c-accent, filled: true, w: 27mm),
      fknoten((3, 0), [Parser $rho$: \ Text -> Kategorie], col: c-blue, w: 27mm),
      fknoten((4, 0), [Aggregation: \ Verteilung, Effekt], col: c-teal, w: 27mm),
      edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"), edge((3, 0), (4, 0), "-|>"),
      fknoten((4, 1), [Vergleich mit Menschen \ auf der Ebene \ des Anspruchs], col: c-teal, filled: true, w: 27mm),
      edge((4, 0), (4, 1), "-|>", stroke: (paint: c-teal, thickness: 0.8pt)),
      edge((0, 0), (0, 1), (4, 1), "-|>", stroke: (paint: c-grey, thickness: 0.8pt, dash: "dashed"), label: text(fill: c-grey.darken(20%))[menschliche Antworten $y_(i q)$ derselben Personen], label-side: right, label-pos: 0.6),
    )
  },
  caption: [Die Pipeline eines Silicon Samples nach Argyle et al. @argyle2023out. Jede Komponente ist Teil des Instruments; die Validierung vergleicht mit den Antworten derselben realen Personen.],
) <k04-fig-pipeline>

=== Algorithmische Treue und ihre vier Kriterien

Argyle et al. begründen, warum das funktionieren könnte: Die Verzerrungen eines Sprachmodells seien nicht einheitlich, sondern feinkörnig und demografisch korreliert. Das Modell trage gewissermaßen Antwortverteilungen für viele Untergruppen in sich. "We call the degree to which a model can accurately reflect these distributions its degree of algorithmic fidelity" @argyle2023out[Abschn. 1]. Operationalisiert wird _algorithmische Treue_ (_algorithmic fidelity_) über vier Kriterien @argyle2023out:

+ *Sozialwissenschaftlicher Turing-Test:* Generierte Antworten sind von parallelen menschlichen Texten nicht zu unterscheiden.
+ *Rückwärtskontinuität:* Die Antworten sind konsistent mit den Einstellungen und soziodemografischen Angaben des Inputs.
+ *Vorwärtskontinuität:* Die Antworten gehen natürlich aus dem konditionierenden Kontext hervor.
+ *Musterentsprechung* (_pattern correspondence_): Die Antworten spiegeln die zugrunde liegenden Zusammenhänge zwischen Ideen, Demografie und Verhalten.

Für Forschung, die Schlüsse ziehen will, zählt vor allem das vierte Kriterium. Die ersten drei beschreiben Plausibilität; erst die Musterentsprechung beschreibt, ob die Daten dieselben Zusammenhänge tragen wie menschliche Daten. Genau dieses Kriterium kann scheitern, auch wenn die Mittelwerte stimmen @bisbee2024synthetic[Abschn. 2.2].

#studie(titel: [Argyle et al. 2023])[
  *Design:* GPT-3 davinci (175B) über die OpenAI-API, Temperatur 0.7. Studie 1 "Pigeonholing Partisans": frei formulierte Wortlisten über Parteianhänger (2107 menschliche und 2107 Silizium-Teilnehmende). Studie 2: Wahlentscheidung in ANES 2012, 2016 und 2020. Studie 3: elf ANES-2016-Antworten als Kontext, Vorhersage einer zwölften; Zusammenhänge mit Cramérs $V$ @argyle2023out. \
  *Befund:* Studie 1: 2873 Bewertende auf Lucid (7675 Listen) hielten 61.7 % der menschlichen und 61.2 % der GPT-3-Listen für menschlich ($p = 0.44$); die Parteizugehörigkeit des Schreibenden wurde zu 60.1 % (Mensch) bzw. 52.8 % (GPT-3) richtig erkannt, beides über der Zufallsrate von 33 % @argyle2023out[Studie 1]. Studie 2: tetrachorische Korrelationen 0.90, 0.92, 0.94 und Übereinstimmungsanteile 0.85, 0.87, 0.89 für 2012, 2016, 2020; für reine Unabhängige 2020 nur 0.02; aggregierter republikanischer Stimmenanteil 2020 0.472 (GPT-3) vs. 0.412 (ANES) @argyle2023out[Studie 2]. Studie 3: mittlere Differenz der Cramér-$V$-Werte (GPT-3 minus ANES) $-0.026$ @argyle2023out[Studie 3, Abb. 4]. \
  *Grenzen:* eine Modellfamilie, US-politische Daten, die im Trainingstext stark vertreten sind; spätere Arbeiten zeigen, dass die Musterentsprechung bei Regressionskoeffizienten und über die Zeit bricht @bisbee2024synthetic und dass Gruppen abgeflacht werden @wang2025large.
]

Zwei Kennzahlen aus der Studie solltest du rechnen können. Die *tetrachorische Korrelation* schätzt die Korrelation zweier latenter, normalverteilter Variablen, die zwei beobachteten Dichotomien zugrunde liegen (Standarddefinition). *Cramérs $V$* misst die Stärke des Zusammenhangs in einer $r times c$-Kontingenztafel:
$ V = sqrt(chi^2 / (n dot (min(r, c) - 1))) $ <k04-eq-cramer>
mit der Pearson-Chi-Quadrat-Statistik $chi^2$ der Tafel und der Zahl der Beobachtungen $n$ (Standarddefinition; die Verwendung in diesem Kontext folgt @argyle2023out[Studie 3]).

#beispiel(titel: [Cramérs V für eine Vierfeldertafel])[
  100 Befragte, Item A (ja/nein) gegen Item B (ja/nein), beobachtet: $mat(30, 20; 10, 40)$. Die Randsummen sind 50/50 (Zeilen) und 40/60 (Spalten), die erwarteten Häufigkeiten unter Unabhängigkeit $mat(20, 30; 20, 30)$. Dann ist
  $ chi^2 = (30-20)^2/20 + (20-30)^2/30 + (10-20)^2/20 + (40-30)^2/30 = 5 + 3.33 + 5 + 3.33 = 16.67 $
  und $V = sqrt(16.67 \/ (100 dot 1)) approx 0.408$. Argyle et al. berechnen $V$ für jedes Item-Paar einmal in den menschlichen und einmal in den Silizium-Daten und vergleichen die beiden Matrizen. Eine mittlere Differenz von $-0.026$ heißt: Die Zusammenhänge sind im Mittel fast gleich stark. Sie sagt nichts darüber, ob einzelne Paare stark abweichen.
]

#fallstrick[Hohe Übereinstimmung im Aggregat kann Versagen in einzelnen Gruppen verbergen. Die tetrachorische Korrelation von 0.94 für 2020 gilt für alle Befragten; für reine Unabhängige lag sie bei 0.02 @argyle2023out[Studie 2]. Das ist genau die Gruppe, deren Verhalten am wenigsten aus der Parteiidentität folgt und für die eine Simulation am interessantesten wäre.]

=== Wessen Meinungen? OpinionQA

Santurkar et al. stellten die Frage umgekehrt: Wessen Meinungen spiegelt ein Sprachmodell standardmäßig, und lässt es sich auf eine Gruppe steuern? Sie bauten dafür OpinionQA, einen Datensatz aus 1.498 Multiple-Choice-Fragen aus 15 Wellen des Pew American Trends Panel (2017-2021) mit menschlichen Antwortverteilungen für die US-Bevölkerung und 60 demografische Gruppen, und prüften neun Sprachmodelle von 350 Millionen bis 178 Milliarden Parametern @santurkar2023whose[Tab. 1-3, 5]. Der Vergleich erfolgt über eine Wasserstein-basierte Übereinstimmung, die wir in @k04-vert herleiten.

#studie(titel: [Santurkar et al. 2023])[
  *Design:* OpinionQA, 1.498 Fragen, 60 Gruppen, 23 grobe und 40 feine Themen; neun Modelle von AI21 Labs und OpenAI; Repräsentativität als mittlere Wasserstein-Übereinstimmung; Steuerbarkeit über drei Prompt-Typen (QA, BIO, PORTRAY), jeweils der beste pro Frage @santurkar2023whose[Abschn. 3.2, 4.2]. \
  *Befund:* Kein Modell trifft die US-Bevölkerung; *jede* der 60 menschlichen Gruppen ist repräsentativer für die Gesamtbevölkerung als jedes Modell; RLHF-Modelle sind oft weniger repräsentativ als Basismodelle @santurkar2023whose[Abb. 2]. Basismodelle ähneln Gruppen mit niedrigerem Einkommen, moderaten, konservativen, protestantischen und katholischen Befragten; die text-\*-Modelle von OpenAI eher liberalen, einkommensstarken, gebildeten, nicht religiösen Gruppen; schlecht vertreten sind etwa Menschen über 65, Verwitwete, Mormonen und Personen mit häufigem Gottesdienstbesuch @santurkar2023whose[Abb. 3]. text-davinci-003 legt bei den meisten Fragen mehr als 0.99 Wahrscheinlichkeit auf eine einzige Option @santurkar2023whose[Abschn. 4.1]. Steuern verbessert die Übereinstimmung mäßig, die Gruppenunterschiede bleiben @santurkar2023whose[Abb. 4b]. \
  *Grenzen:* englisch, US-zentriert, nur Multiple Choice; von den Autoren als Sonde, nicht als zu optimierender Benchmark gedacht @santurkar2023whose[Abschn. 1, 6].
]

Der Befund des _modalen Kollapses_ ist für die Messtheorie zentral. Ein Modell, das fast seine gesamte Wahrscheinlichkeitsmasse auf eine Antwort legt, kann nie eine Verteilung abbilden, egal wie gut es den Modus trifft. Wir werden in @k04-vert sehen, dass genau ein solches Modell bei der Standardmetrik trotzdem einen beruhigend hohen Wert bekommen kann.

=== Die "Perils": Bisbee et al.

Die Arbeit, die das Feld nachhaltig ernüchtert hat, stammt von Bisbee et al. Sie bauten Personas aus ANES-Befragten der Jahre 2016 und 2020, ließen ChatGPT 3.5 Turbo für jede reale Person 30 synthetische Befragte erzeugen und kamen so auf 3 614 400 Antworten auf Gefühlsthermometer-Items; Robustheitsprüfungen nutzten ChatGPT 4.0 und Falcon-40B-Instruct @bisbee2024synthetic[Abschn. 1]. Der Wert der Studie liegt in ihrer Systematik: Sie prüft dieselben Daten auf mehreren Ebenen.

#studie(titel: [Bisbee et al. 2024])[
  *Design:* Personas aus ANES 2016/2020, 30 synthetische Befragte pro Person, Thermometer-Items (0-100), Vergleich auf Ebene von Mittelwerten, Varianzen, Gruppenunterschieden, Regressionskoeffizienten, Power; Prompt-Varianten; Wiederholung über die Zeit @bisbee2024synthetic. \
  *Befund:* *Mittelwerte:* jeder synthetische Mittelwert innerhalb einer ANES-Standardabweichung, Rangfolge der Gruppen weitgehend erhalten @bisbee2024synthetic[Abschn. 2.1, Abb. 1]. *Varianz:* viel kleiner als bei Menschen, besonders für ethnische und religiöse Gruppen. *Gruppenunterschiede:* parteipolitische und ideologische Antipathie um 10-20 Thermometerpunkte übertrieben (0.5-1 ANES-SD) @bisbee2024synthetic[Abb. 2]. *Regression:* 48 % der Koeffizienten signifikant verschieden von ANES, 32 % davon mit umgekehrtem Vorzeichen @bisbee2024synthetic[Abb. 3]. *Power:* 35 Parteianhänger für 99 % Power auf Basis synthetischer Daten gegenüber 299 auf Basis von ANES @bisbee2024synthetic[Tab. 1] (der Fließtext nennt für denselben Fall 33). *Prompt:* Weglassen politischer Attribute erhöht die Fehler deutlich @bisbee2024synthetic[Abb. 4]. *Zeit:* identische Prompts im April, Juni und Juli 2023 lieferten verschiedene Verteilungen @bisbee2024synthetic[Abb. 5]. \
  *Grenzen:* eine geschlossene Modellfamilie als Hauptinstrument, nur Thermometer-Items.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let w = 12.0
    let hgt = 3.0
    // drei Ebenen als Spalten
    let cols = (
      ([Mittelwerte], [innerhalb 1 SD, \ Rangfolge erhalten], c-green),
      ([Varianzen], [stark komprimiert], c-yellow),
      ([Gruppenlücken], [um 10-20 Punkte \ übertrieben], c-yellow),
      ([Koeffizienten], [48 % abweichend, \ davon 32 % mit \ Vorzeichenwechsel], c-red),
      ([Power], [35 statt 299 \ Befragte], c-red),
      ([Zeit], [April, Juni, Juli \ 2023 verschieden], c-red),
    )
    for (i, (t, b, col)) in cols.enumerate() {
      let x = i * 2.6
      rect((x, 0), (x + 2.4, 1.9), radius: 0.1, fill: col.lighten(85%), stroke: 0.8pt + col)
      content((x + 1.2, 1.5), k04-t(t, size: 7.8pt, weight: "bold", fill: col.darken(25%)))
      content((x + 1.2, 0.75), align(center, k04-t(b, size: 7.2pt)))
    }
    line((0, -0.35), (15.4, -0.35), stroke: (paint: c-dark, thickness: 0.8pt), mark: (end: "stealth", fill: c-dark, scale: 0.6))
    content((7.7, -0.7), k04-t([zunehmend anspruchsvolle Ebene der Validierung]))
  }),
  caption: [Dieselben synthetischen Daten auf sechs Ebenen geprüft (Befunde nach Bisbee et al. @bisbee2024synthetic). Was auf der linken Ebene gut aussieht, kann auf den rechten Ebenen scheitern.],
) <k04-fig-ebenen-bisbee>

Die Lehre aus @k04-fig-ebenen-bisbee formuliert das Dossier der Lehrveranstaltung als Merksatz: Validiere auf der Ebene deines Anspruchs. Wer nur Mittelwerte berichtet, hat nur Mittelwerte validiert. Der Power-Befund zeigt außerdem, dass schon die naheliegendste "harmlose" Nutzung, nämlich die Planung einer Studie mit synthetischen Pilotdaten, gefährlich ist; wir rechnen das in @k04-vert nach.

=== Abflachung und Fehldarstellung

Wang, Morgenstern und Dickerson haben die Probleme bei Identitätsgruppen systematisch untersucht und zwei Schadensformen benannt: _Fehldarstellung_ (_misportrayal_) und _Abflachung_ (_flattening_) @wang2025large.

#definition(titel: [Abflachung und Fehldarstellung])[
  *Abflachung* liegt vor, wenn die LLM-Antworten für eine Identitätsgruppe weniger divers sind als die menschlichen Antworten dieser Gruppe @wang2025large[Abb. 4]. *Fehldarstellung* liegt vor, wenn die LLM-Antworten für eine Gruppe eher dem ähneln, was Außenstehende sich unter den Antworten dieser Gruppe vorstellen, als dem, was Mitglieder der Gruppe tatsächlich sagen @wang2025large[Abb. 2-3].
]

#studie(titel: [Wang, Morgenstern und Dickerson 2025])[
  *Design:* rund 3200 Prolific-Teilnehmende in 16 Identitäten auf fünf Achsen (Ethnie, Geschlecht, intersektional, Alter, Behinderung); vier LLMs (Llama-2-Chat 7B, Wizard Vicuna Uncensored 7B, GPT-3.5-Turbo, GPT-4); neun Fragen; 100 freie Antworten pro Identität-Modell-Paar @wang2025large. \
  *Befund:* LLM-Antworten lagen oft näher an Außengruppen-Imitationen als an Innengruppen-Antworten, etwa für weiße, nicht-binäre und sehbehinderte Personas, und zwar bei allen vier Modellen @wang2025large[Abb. 2-3]. Fast alle LLM-Antwortmengen waren weniger divers als menschliche; GPT-4 und GPT-3.5 deckten nur etwa 3 von 5 Multiple-Choice-Optionen ab @wang2025large[Abb. 4]. Identitätskodierte Namen verbesserten die Innengruppen-Übereinstimmung für Schwarze Männer und Frauen, weniger für weiße; höhere Temperatur erhöhte die Diversität, GPT-4 wurde aber bei 1.4 inkohärent und erreichte die menschliche Diversität trotzdem nicht @wang2025large[Abb. 3, 5]. Ersatz ist am wenigsten vertretbar, wenn Identität für die Antwort zählt, eher vertretbar für Pilotierung, teure oder belastende Aufgaben und subjektive Annotation @wang2025large[Diskussion]. \
  *Grenzen:* US-Prolific-Stichprobe, kleine offene Modelle, neun Fragen.
]

Eine verwandte Verzerrung haben Aher et al. als _Hyper-Genauigkeit_ beschrieben: Ausgerichtete Modelle beantworten Wissensfragen "zu richtig". In ihrem Wisdom-of-Crowds-Experiment hatten ChatGPT und GPT-4 einen normierten Median-Schätzwert von 1.0 bei einem Interquartilsabstand von 0.0; die simulierten Teilnehmenden nannten also exakt den wahren Wert @aher2023using[Abschn. 7, Abb. 8]. Eine Menge, die immer richtig liegt, simuliert keine Menschenmenge.

=== Artefakte der Antwortreihenfolge

Eine methodische Warnung, die jede OpinionQA-artige Übung betrifft, stammt von Dominguez-Olmedo, Hardt und Mendler-Dünner. Sie legten 43 Sprachmodellen (110 Millionen bis 175 Milliarden Parameter) 25 Multiple-Choice-Fragen des American Community Survey 2019 vor und lasen normierte Next-Token-Wahrscheinlichkeiten über die Antwortlabels aus @dominguezolmedo2024questioning[Abschn. 2].

#studie(titel: [Dominguez-Olmedo, Hardt und Mendler-Dünner 2024])[
  *Design:* 25 ACS-Fragen, 43 Modelle, Vergleich mit Zensus-Mikrodaten und einer Gleichverteilung über normierte Entropie und KL-Divergenz; Korrektur durch Mittelung über zufällige Antwortreihenfolgen @dominguezolmedo2024questioning[Abschn. 2]. \
  *Befund:* Starker "A"-Bias; Reihenfolge- und Label-Effekte überlagern die Antworten, auch bei instruktionsgetunten Modellen @dominguezolmedo2024questioning[Abb. 3]. Nach der Korrektur sind die Antworten von Basismodellen nahezu gleichverteilt (normierte Entropie um 1) @dominguezolmedo2024questioning[Abschn. 4, Abb. 4]; für GPT-4 liegen nur 6 von 25 Fragen näher am Zensus als an der Gleichverteilung @dominguezolmedo2024questioning[Abschn. 4.2, Abb. 5]. Scheinbare Übereinstimmung mit Untergruppen folgt großteils der Entropie der Gruppenantworten @dominguezolmedo2024questioning[Abschn. 5, Abb. 6]. Ein Klassifikator trennt Modelldaten von Zensusdaten mit über 90 % und von ANES-Daten mit über 99 % Genauigkeit @dominguezolmedo2024questioning[Anhang F, Abb. 18]. \
  *Grenzen:* Multiple-Choice-Setting mit Token-Wahrscheinlichkeiten, keine personakonditionierte Generierung.
]

#tipp[Randomisiere bei jedem Multiple-Choice-Experiment die Reihenfolge der Optionen und vergleiche immer auch mit einer Gleichverteilung als Basislinie @dominguezolmedo2024questioning. Eine "Übereinstimmung" mit einer Gruppe, deren Antworten fast gleichverteilt sind, ist kein Beleg für Simulation, sondern für hohe Entropie.]

=== Der Stand 2026: neuere Modelle, dieselben Fehlermuster

Man könnte erwarten, dass die Probleme von 2023 mit stärkeren Modellen verschwinden. Drei Studien aus 2026 sprechen dagegen.

#studie(titel: [Chapekis et al. (Pew Research Center) 2026])[
  *Design:* drei Wellen des American Trends Panel (185, 190, 192) mit fast 300 Fragen, Feldzeit Anfang 2026; "digitale Zwillinge" aus Demografie, 71 Variablen der politischen Typologie und einer von GPT-5.1 geschriebenen "Expertenreflexion"; finales Modell Claude Opus 4.6, getestet auch GPT-5.1 und GPT-5 nano @chapekis2026can @pew2026methodology. \
  *Befund:* mittlerer absoluter Fehler über die Wellen 12.4 Prozentpunkte in der Tabelle des Berichts (Welle 185: 11.3, 190: 14.7, 192: 11.2), im Fließtext gerundet "an average of 12 percentage points"; rund 28 % der Fragen mehr als 15 Punkte daneben @chapekis2026can. Unter identischen Bedingungen: GPT-5.1 13.3, GPT-5 nano 17.4, Opus 4.6 11.4 Punkte @pew2026methodology; GPT-5.1 zeichnete eine extremere, Opus eine moderatere Öffentlichkeit @chapekis2026can. Stereotypisierung: 97 % der synthetischen gegenüber 43 % der tatsächlichen hispanischen Erwachsenen verfolgen angeblich die Fußball-WM; Hyper-Genauigkeit bei Wissensfragen (First Amendment 98 % synthetisch vs. 52 % menschlich). Bei fast der Hälfte der Fragen gab es mindestens eine Option, die kein synthetischer Befragter wählte; Menschen wählten "nicht sicher" etwa viermal so oft @chapekis2026can. Fazit des Berichts: kein adäquater Ersatz für probabilistische Umfragen zu breit relevanten Themen. \
  *Grenzen:* eine Organisation, im Wesentlichen ein Modell; API-Snapshot-Versionen und Temperatur nicht berichtet @pew2026methodology. Graue Literatur.
]

#figure(
  balken((
    ([Claude Opus 4.6], 11.4),
    ([GPT-5.1], 13.3),
    ([GPT-5 nano], 17.4),
  ), max: 20, breite: 8, farbe: c-accent, einheit: [ Pp.], nachkomma: 1),
  caption: [Mittlerer absoluter Fehler digitaler Zwillinge gegenüber dem Pew American Trends Panel unter identischen Bedingungen, in Prozentpunkten @pew2026methodology. Die Modellwahl allein verschiebt den Fehler um sechs Punkte.],
) <k04-fig-pew>

Die zweite Studie ist ein Industrie-Benchmark von Verasight: Eine national repräsentative Stichprobe von 2000 US-Erwachsenen wurde mit GPT-5.2-Personas (Demografie plus Wahlverhalten 2024) imputiert; ausgewertet wurden 52 Einfachantwort-Fragen mit 305 Optionen @morris2026can. Der mittlere absolute Fehler lag bei 14.5 Prozentpunkten (Politik 12.1, Gesundheitswesen 23.4); die Kalibrierungssteigung der LLM-Anteile auf die Umfrageanteile betrug 0.82, seltene Optionen wurden also über- und häufige unterschätzt; bei Mehrfachantworten wählte das LLM 24 von 77 Optionen nie, darunter vier, die mehr als 30 % der Menschen gewählt hatten @morris2026can. Am besten funktionierte die Imputation bei polarisierten Themen mit starken demografischen Korrelaten, am schlechtesten bei persönlichem Verhalten und Erfahrungen. Der Bericht ist nicht begutachtet, und die Organisation verkauft selbst Umfragedienstleistungen.

Die dritte Studie verlässt die USA. Lam, Voo und Ma verglichen GPT-5.4 mit der singapurischen Welle 7 des World Values Survey ($n = 2012$, 27 Items, 30 Surrogate pro Person): Die Silicon Samples behielten nur etwa 23-24 % der Streuung, acht Items kollabierten auf eine Standardabweichung von null @lam2026conditional[Tab. 4]; die Korrelation der Cramér-$V$-Assoziationsmatrizen mit den WVS-Daten lag zwischen 0.28 und 0.69 @lam2026conditional[Tab. 5]. Ein präregistriertes psychometrisches Audit von 37 LLMs an einer litauischen Organisationsbefragung ($n = 263$, 68 Items) fand schließlich, dass eine einfache Gauß-Copula als statistische Basislinie im _Psychometric Similarity Score_ (0.69) fast so gut abschneidet wie das beste LLM (0.71), beide unter der menschlichen Obergrenze von 0.825 @lukauskas2026plausible[Abschn. 5.2]; die prädiktive Varianzaufklärung auf zurückgehaltenen Daten lag für LLM-Stichproben im Mittel bei $R^2 = -0.18$ gegenüber 0.28 für menschliche @lukauskas2026plausible[Abschn. 5.7].

#merke[Neuere Modelle haben das Fehlermuster nicht beseitigt: Abflachung, Stereotypisierung, Hyper-Genauigkeit und Regression zur Mitte tauchen 2026 mit Frontier-Modellen genauso auf wie 2023 @chapekis2026can @morris2026can @lam2026conditional. Der Modellvergleich bei Pew zeigt außerdem, dass die Wahl des Modells ein Teil des Instruments ist, der das Ergebnis um mehrere Prozentpunkte verschiebt.]

=== Wo es funktioniert: Interviews und Fine-Tuning

Ein Kapitel, das nur Misserfolge aufzählt, wäre selbst eine verzerrte Messung. Die Evidenz 2024-2026 enthält drei klar positive Linien, und alle drei haben eine gemeinsame Struktur.

*Individuelle Verankerung statt Demografie.* Park et al. konditionierten Agenten nicht auf ein demografisches Profil, sondern auf das Transkript eines zweistündigen Interviews mit der jeweiligen Person (Protokoll des American Voices Project) und/oder deren Umfrageantworten @park2024llm. Die normierte GSS-Genauigkeit lag für Interview-Agenten bei 0.83, für Survey-Agenten bei 0.82, für die Kombination bei 0.86, für rein demografische Agenten bei 0.74 und für Persona-Agenten bei 0.71 @park2024llm[Results]. Für die Big Five ergab sich eine normierte Korrelation von 0.80, für ökonomische Spiele 0.66 ohne signifikante Unterschiede zwischen Agententypen. Selbst nach Entfernen von 80 % des Transkripts blieb die normierte Genauigkeit bei 0.79 @park2024llm[SI Tab. 6]. Die Interview-Verankerung verringerte Subgruppenlücken, beseitigte sie aber nicht (Ideologie-DPD im GSS 13.75 % demografisch vs. 8.60 % mit Interview) @park2024llm[Abb. 3]. Achtung bei Zitaten: Das Paper wurde zwischen arXiv-Versionen umbenannt (v1 "Generative Agent Simulations of 1,000 People", v3 2026 "LLM Agents Grounded in Self-Reports Enable General-Purpose Simulation of Individuals"), und die Zahlen haben sich leicht geändert; ein Policy Brief nennt aus der früheren Version "85 %" @park2024llm @stanfordhai2025simulating.

*Fine-Tuning auf Umfragedaten.* Suh et al. haben die Aufgabe nicht als Rollenspiel, sondern als überwachtes Lernproblem formuliert: Ein Modell soll die Antwortverteilung einer Subpopulation direkt vorhersagen und wird mit einer Vorwärts-KL-Verlustfunktion gegen die menschliche Verteilung trainiert @suh2025language[Abschn. 3.1].

#studie(titel: [Suh et al. 2025])[
  *Design:* SubPOP mit 3362 Fragen und rund 70 000 Subpopulation-Antwort-Paaren; Training auf 3229 Fragen aus den Pew-ATP-Wellen 61-132 (OpinionQA-Wellen ausgeschlossen), Evaluation auf 133 Fragen des GSS 2022; 22 Subpopulationen; LoRA (Rang 8) für Llama-2-7B/13B, Mistral-7B und Llama-3-70B; Metrik Wasserstein-Distanz, eingerahmt von der Gleichverteilung als oberer Schranke und einer gebootstrappten menschlichen Wiederholungsstichprobe als unterer Schranke @suh2025language[Abschn. 3.2-4.1, Tab. 3]. \
  *Befund:* auf zurückgehaltenen ATP-Wellen WD 0.094-0.106 nach Fine-Tuning gegenüber 0.178 für die Gleichverteilung und 0.031 für die menschliche Wiederholung; 32-46 % geringere WD als die beste Prompting-Basislinie auf OpinionQA und 39-42 % auf dem GSS @suh2025language[Tab. 1, Abschn. 4.2]. Generalisierung auf nicht trainierte Subpopulationen (mittlere Verbesserung 43.1 %) und auf eine nicht trainierte Umfragefamilie @suh2025language[Abschn. 4.3]. \
  *Grenzen (von den Autoren genannt):* LLMs "cannot fully replace human involvement in the survey process"; verrauschte Ziele für kleine Gruppen; nur Gruppenlabels; mögliche demografische Verzerrung durch Fine-Tuning @suh2025language[Abschn. 6-7]. Beste WD bleibt deutlich über der menschlichen Schranke.
]

#studie(titel: [Kolluri et al. 2025])[
  *Design:* SocSci210 mit 2.9 Millionen Antworten von 400 491 Teilnehmenden aus 210 TESS-Umfrageexperimenten; Qwen2.5-14B-Instruct und Llama-3-8B-Instruct mit SFT, SFT mit Begründungen und DPO; Metrik Wasserstein-Distanz zwischen vorhergesagter und beobachteter Verteilung pro Bedingung und Ergebnisvariable (auf $[0, 1]$ skaliert); "Empirical Best" als Bootstrap-Schranke aus 100 Wiederholungsstichproben @kolluri2025finetuning[Abschn. 3-5]. \
  *Befund:* völlig ungesehene Studien: WD 0.151 für Qwen-14B mit SFT gegenüber 0.205 für das Basismodell ($-26.3$ %) und 0.174 für GPT-4o ($-13.2$ %), Stichprobenschranke 0.125 @kolluri2025finetuning[Tab. 2]. Ungesehene Bedingungen bekannter Studien (Llama-3-8B, SFT mit Begründungen): 0.219 -> 0.063 ($-71.2$ %), unter der Schranke von 0.090 dieser Aufteilung @kolluri2025finetuning[Tab. 3]. Demographic Parity Difference um 10.6 % reduziert @kolluri2025finetuning[Abschn. 5.6]. Hinweis: Die Kurzfassung auf der ACL-Anthology-Seite nennt 36 % und 15 %, die arXiv-Fassungen und Tabelle 2 nennen 26 % und 13 %; hier gelten die Tabellenwerte. \
  *Grenzen:* Gewinne flachen mit mehr Teilnehmerdaten schnell ab; nur US-repräsentative Stichproben und geschlossene Fragen; Behandlungseffekte selbst werden nicht direkt evaluiert @kolluri2025finetuning[Limitations, Abschn. 5].
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let s = 55.0 // cm pro WD-Einheit
    let x(v) = v * s
    for (row, y) in ((0, 1.9), (1, 0)) {
      line((0, y), (x(0.22), y), stroke: 0.7pt + c-dark)
      for t in (0, 0.05, 0.10, 0.15, 0.20) {
        line((x(t), y - 0.08), (x(t), y + 0.08), stroke: 0.6pt + c-dark)
        content((x(t), y - 0.3), k04-t(str(t), size: 6.5pt, fill: c-grey.darken(20%)))
      }
    }
    content((-0.15, 1.9), anchor: "east", k04-t([Suh et al. \ (OpinionQA)], weight: "bold"))
    content((-0.15, 0), anchor: "east", k04-t([Kolluri et al. \ (ungesehene Studien)], weight: "bold"))
    let mark(v, y, lab, col, up) = {
      circle((x(v), y), radius: 0.09, fill: col, stroke: none)
      content((x(v), if up { y + 0.42 } else { y - 0.85 }), k04-t(lab, size: 6.6pt, fill: col.darken(20%)))
    }
    mark(0.031, 1.9, [Mensch: 0.031], c-green, true)
    mark(0.094, 1.9, [Fine-Tuning: 0.094], c-accent, true)
    mark(0.178, 1.9, [Gleichverteilung: 0.178], c-grey, true)
    mark(0.125, 0, [Schranke: 0.125], c-green, true)
    mark(0.151, 0, [SFT: 0.151], c-accent, false)
    mark(0.174, 0, [GPT-4o: 0.174], c-blue, true)
    mark(0.205, 0, [Basis: 0.205], c-grey, false)
    content((x(0.11), -1.5), k04-t([Wasserstein-Distanz zur menschlichen Verteilung (kleiner ist besser)]))
  }),
  caption: [Fine-tuned Simulatoren im Vergleich mit ihren Schranken @suh2025language[Tab. 1] @kolluri2025finetuning[Tab. 2]. Beide verbessern sich klar gegenüber Basismodellen, bleiben auf ungesehenen Zielen aber über der menschlichen Stichprobenschranke. Die Skalen der beiden Studien sind nicht direkt vergleichbar.],
) <k04-fig-finetuning>

Was haben die positiven Befunde gemeinsam? Das Dossier der Lehrveranstaltung fasst es als Synthese zusammen: ein aggregiertes Ziel, eine Population und ein Itemtyp, die durch menschliche Trainings- oder Validierungsdaten abgedeckt sind, und eine Evaluation auf zurückgehaltenen menschlichen Daten. Außerhalb dieser Bedingungen bleiben die Fehlermuster bestehen @hewitt2024predicting @cui2024can @chapekis2026can. Fine-tuned Simulatoren sind außerdem auf Verteilungsebene evaluiert; ob die Gewinne auf die Genauigkeit von Behandlungseffekten übertragen werden, ist offen @suh2025language @kolluri2025finetuning @li2026statistical.

#hoersaal([Wenn Fine-Tuning so gut hilft, warum nicht einfach ein Modell auf alle verfügbaren Umfragen trainieren und Umfragen künftig sparen?], [Weil das Modell dann eine Funktion vergangener Umfragen ist. Die Gewinne in den Studien gelten für zurückgehaltene Wellen derselben Panels und für neue Bedingungen bekannter Experimente; selbst dort bleibt die Distanz über der menschlichen Stichprobenschranke (0.094 vs. 0.031 bei Suh et al.) @suh2025language[Tab. 1]. Für neue Themen, neue Populationen und neue Fragen gibt es keine Kalibrierungsdaten, und genau dort versagen Simulatoren am deutlichsten @chapekis2026can. Dazu kommt, dass Meinungen sich ändern, während ein Modell einen Schnappschuss abbildet, ein Punkt, den Harding et al. gegen den Ersatz von Teilnehmenden vorbringen @harding2024ai. Ein trainierter Simulator ist ein gutes Werkzeug zur Priorisierung, ersetzt aber nicht die Messung, mit der man ihn kalibriert.])

#hoersaal([Pew hat einen Fehler von 12 Punkten gemessen. Ist das nicht für viele Zwecke gut genug?], [Das hängt vom Anspruch ab, und genau deshalb ist die Messperspektive nützlich. Für eine grobe Vorab-Einschätzung, ob eine Frage polarisiert, mag ein Fehler dieser Größe tolerierbar sein. Für eine Aussage über die öffentliche Meinung, die veröffentlicht wird, ist er es nicht: Rund 28 % der Fragen lagen mehr als 15 Punkte daneben, und die Fehler sind nicht zufällig, sondern systematisch (Stereotypisierung, Hyper-Genauigkeit, zu wenig "nicht sicher") @chapekis2026can. Systematische Fehler lassen sich nicht durch mehr synthetische Befragte wegmitteln. Pew selbst kommt zum Schluss, dass synthetische Stichproben kein adäquater Ersatz für probabilistische Umfragen sind.])


== Verteilungen vergleichen: Wasserstein, Jensen-Shannon, Entropie <k04-vert>

Fast alle Silicon-Sample-Studien vergleichen am Ende zwei Wahrscheinlichkeitsverteilungen über dieselben Antwortoptionen: die menschliche und die synthetische. Welche Zahl man dafür wählt, entscheidet darüber, welche Fehler man sieht und welche nicht. Dieser Abschnitt baut die drei Maße auf, die im Notebook `notebooks/04_silicon_sampling_validity.ipynb` und in Foliensatz 04 der Lehrveranstaltung verwendet werden, und leitet ihre Eigenschaften her.

=== Drei Fragen an zwei Verteilungen

Stell dir eine Frage mit vier geordneten Antwortoptionen vor, von "stimme gar nicht zu" (1) bis "stimme voll zu" (4). Die Menschen antworten mit $P = (0.10, 0.20, 0.40, 0.30)$, das Modell mit $Q = (0.00, 0.05, 0.90, 0.05)$. Drei Fragen liegen nahe:

- *Wie weit liegen die Verteilungen auseinander, wenn man die Ordnung der Skala berücksichtigt?* Eine Antwort "3" statt "4" ist ein kleinerer Fehler als "1" statt "4". Das misst die Wasserstein-Distanz.
- *Wie verschieden sind die Formen, unabhängig von der Ordnung?* Das misst die Jensen-Shannon-Divergenz.
- *Wie stark streuen die Antworten?* Ein Modell, das fast alles auf eine Option legt, hat eine kleine Entropie, egal wo diese Option liegt.

Keine der drei Zahlen beantwortet alle drei Fragen. Das ist der Kern des Abschnitts.

=== Die Wasserstein-Distanz auf einer ordinalen Skala

Die 1-Wasserstein-Distanz ist der minimale "Transportaufwand", um die Wahrscheinlichkeitsmasse der einen Verteilung in die der anderen zu verschieben, wobei das Verschieben von Masse $m$ um die Strecke $d$ den Aufwand $m dot d$ kostet. Daher der englische Spitzname _earth mover's distance_.

#definition(titel: [1-Wasserstein-Distanz auf ${1, dots, N}$])[
  Seien $P$ und $Q$ Verteilungen auf den Antwortoptionen ${1, dots, N}$, die als gleich weit auseinanderliegende ganze Zahlen kodiert sind. Ein _Transportplan_ $gamma$ ist eine gemeinsame Verteilung auf ${1, dots, N}^2$ mit Rändern $P$ und $Q$. Die 1-Wasserstein-Distanz ist
  $ "WD"(P, Q) = min_gamma sum_(j, k) gamma(j, k) dot |j - k|. $ <k04-eq-wd-def>
]

Für eindimensionale Verteilungen lässt sich das Minimum geschlossen angeben. Seien $F_P (k) = sum_(j <= k) p_j$ und $F_Q (k)$ die kumulierten Verteilungsfunktionen.

#satz(titel: [Wasserstein-Distanz über Verteilungsfunktionen])[
  Für Verteilungen auf ${1, dots, N}$ gilt
  $ "WD"(P, Q) = sum_(k=1)^(N-1) |F_P (k) - F_Q (k)|. $ <k04-eq-wd-cdf>
]

#beweis[
  Betrachte die "Grenze" zwischen Option $k$ und $k+1$. Links davon liegt unter $P$ die Masse $F_P (k)$, unter $Q$ die Masse $F_Q (k)$. Jeder Transportplan muss daher mindestens $|F_P (k) - F_Q (k)|$ Masse über diese Grenze schieben, und jede Einheit, die über die Grenze geht, legt dort mindestens die Strecke 1 zurück. Da eine Verschiebung von $j$ nach $k$ genau $|j - k|$ Grenzen überquert, ist der Aufwand jedes Plans die Summe der Grenzüberquerungen, also mindestens $sum_k |F_P (k) - F_Q (k)|$. Der monotone Plan, der Masse "der Reihe nach" von links nach rechts zuordnet (Quantilkopplung), überquert jede Grenze nur in einer Richtung und genau mit der Differenzmasse; er erreicht die Schranke. Die letzte Grenze nach Option $N$ trägt nichts bei, weil $F_P (N) = F_Q (N) = 1$.
]

@k04-eq-wd-cdf ist zugleich die Formel, die du von Hand rechnest: Kumuliere beide Verteilungen, bilde die absoluten Differenzen bis $N - 1$ und summiere. Geometrisch ist es die Fläche zwischen den beiden Treppenfunktionen in @k04-fig-wd.

=== Das OpinionQA-Alignment

Santurkar et al. normieren die Wasserstein-Distanz auf ein Übereinstimmungsmaß zwischen 0 und 1 und mitteln über eine Menge $Q$ von Fragen @santurkar2023whose[Abschn. 3.2, Gl. 1]:
$ cal(A)(D_1, D_2; Q) = 1 / (|Q|) sum_(q in Q) (1 - ("WD"(D_1(q), D_2(q))) / (N_q - 1)). $ <k04-eq-align>
Dabei ist $D_1(q)$ die Antwortverteilung des Modells für Frage $q$, $D_2(q)$ die der menschlichen Gruppe und $N_q$ die Zahl der Antwortoptionen ohne Verweigerung. Der Wert 1 bedeutet identische Verteilungen.

#satz(titel: [Wertebereich des Alignments])[
  Für jede Frage gilt $0 <= "WD"(D_1(q), D_2(q)) <= N_q - 1$, also liegt jeder Summand von @k04-eq-align und damit $cal(A)$ in $[0, 1]$. Der Summand einer Frage ist genau dann 0, wenn eine Verteilung ihre gesamte Masse auf Option 1 und die andere ihre gesamte Masse auf Option $N_q$ legt; $cal(A) = 0$ verlangt das für jede Frage.
]

#beweis[
  In @k04-eq-wd-cdf ist jeder der $N_q - 1$ Summanden eine Differenz zweier Zahlen in $[0, 1]$, also höchstens 1. Gleichheit in allen Summanden verlangt $|F_1(k) - F_2(k)| = 1$ für alle $k < N_q$, also $F_1(k) = 1$ und $F_2(k) = 0$ (oder umgekehrt) für alle diese $k$. Das heißt: Die eine Verteilung hat ihre gesamte Masse bereits bei Option 1, die andere erst bei Option $N_q$.
]

#beispiel(titel: [Alignment eines kollabierten und eines gestreuten Modells])[
  Menschen $P = (0.10, 0.20, 0.40, 0.30)$, kollabiertes Modell $Q_1 = (0.00, 0.05, 0.90, 0.05)$, gestreutes Modell $Q_2 = (0.05, 0.15, 0.35, 0.45)$, $N = 4$.

  Kumulierte Verteilungen bis $N - 1 = 3$: $F_P = (0.10, 0.30, 0.70)$, $F_(Q_1) = (0.00, 0.05, 0.95)$, $F_(Q_2) = (0.05, 0.20, 0.55)$.

  Kollabiert: $"WD" = |0.10 - 0.00| + |0.30 - 0.05| + |0.70 - 0.95| = 0.10 + 0.25 + 0.25 = 0.60$, also $cal(A) = 1 - 0.60 \/ 3 = 0.80$.

  Gestreut: $"WD" = 0.05 + 0.10 + 0.15 = 0.30$, also $cal(A) = 1 - 0.30 \/ 3 = 0.90$.

  Das kollabierte Modell, das 90 % der Masse auf eine Option legt und die Option 1 gar nicht kennt, bekommt immer noch 0.80. Das ist das Rechenbeispiel aus dem Dossier und dem Notebook, und es ist die wichtigste Warnung zu diesem Maß: Ein Modell mit dem richtigen Modus, aber ohne Streuung, kann einen beruhigend hohen Wert erreichen. Das Alignment sollte deshalb immer zusammen mit einem Entropie- oder Varianzvergleich berichtet werden.
]

#figure(
  {
    let P = (0.10, 0.20, 0.40, 0.30)
    let Q = (0.00, 0.05, 0.90, 0.05)
    let FP = (0.10, 0.30, 0.70, 1.0)
    let FQ = (0.00, 0.05, 0.95, 1.0)
    let hgt = 3.0
    let achsen(xmax, ytitle) = {
      import cetz.draw: *
      line((0, 0), (xmax, 0), stroke: 0.6pt + c-dark)
      line((0, 0), (0, hgt + 0.15), stroke: 0.6pt + c-dark)
      for t in (0, 0.25, 0.5, 0.75, 1.0) {
        line((-0.07, t * hgt), (0, t * hgt), stroke: 0.6pt + c-dark)
        content((-0.12, t * hgt), anchor: "east", k04-t(str(t), size: 6.4pt))
      }
      content((-0.85, hgt / 2), angle: 90deg, k04-t(ytitle, size: 6.8pt))
    }
    grid(columns: (1fr, 1fr), column-gutter: 8pt,
      cetz.canvas(length: 1cm, {
        import cetz.draw: *
        achsen(5.0, [Anteil])
        for i in range(4) {
          let x = 0.7 + i * 1.15
          rect((x - 0.42, 0), (x, P.at(i) * hgt), fill: c-blue.lighten(25%), stroke: none)
          rect((x, 0), (x + 0.42, Q.at(i) * hgt), fill: c-accent.lighten(15%), stroke: none)
          content((x, -0.25), k04-t(str(i + 1), size: 7pt))
        }
        content((2.5, -0.62), k04-t([Antwortoption], size: 6.8pt))
        rect((0.3, 2.95), (0.5, 3.1), fill: c-blue.lighten(25%), stroke: none)
        content((0.58, 3.03), anchor: "west", k04-t([Menschen $P$], size: 6.6pt))
        rect((0.3, 2.6), (0.5, 2.75), fill: c-accent.lighten(15%), stroke: none)
        content((0.58, 2.68), anchor: "west", k04-t([Modell $Q_1$], size: 6.6pt))
      }),
      cetz.canvas(length: 1cm, {
        import cetz.draw: *
        achsen(5.0, [kumulierter Anteil $F(k)$])
        let sx = 1.15
        for k in range(3) {
          let a = calc.min(FP.at(k), FQ.at(k)) * hgt
          let b = calc.max(FP.at(k), FQ.at(k)) * hgt
          rect((0.4 + (k + 1) * sx - sx, a), (0.4 + (k + 1) * sx, b), fill: c-violet.lighten(70%), stroke: none)
        }
        for (F, col) in ((FP, c-blue), (FQ, c-accent)) {
          for k in range(4) {
            let x0 = 0.4 + k * sx
            line((x0, F.at(k) * hgt), (x0 + sx, F.at(k) * hgt), stroke: 1.3pt + col)
            if k < 3 { line((x0 + sx, F.at(k) * hgt), (x0 + sx, F.at(k + 1) * hgt), stroke: (paint: col, thickness: 0.6pt, dash: "dotted")) }
          }
        }
        for k in range(4) { content((0.4 + k * sx + sx / 2, -0.25), k04-t(str(k + 1), size: 7pt)) }
        content((2.7, -0.62), k04-t([Antwortoption $k$], size: 6.8pt))
        content((3.95, 1.5), anchor: "west", k04-t([Fläche \ = WD \ = 0.60], size: 6.8pt, fill: c-violet.darken(20%), weight: "bold"))
      }),
    )
  },
  caption: [Das Rechenbeispiel grafisch. Links die Verteilungen von Menschen (blau) und kollabiertem Modell (orange), rechts die kumulierten Verteilungsfunktionen. Die violette Fläche zwischen den Treppen ist nach @k04-eq-wd-cdf die Wasserstein-Distanz: $0.10 + 0.25 + 0.25 = 0.60$.],
) <k04-fig-wd>

=== Die Jensen-Shannon-Divergenz

Die Jensen-Shannon-Divergenz geht auf Lin zurück, der Divergenzmaße auf Basis der Shannon-Entropie untersucht hat @lin1991divergence. Sie baut auf der Kullback-Leibler-Divergenz auf, repariert aber deren zwei praktische Schwächen: Asymmetrie und Unbeschränktheit.

#definition(titel: [Entropie, KL- und Jensen-Shannon-Divergenz])[
  Für Verteilungen $P = (p_1, dots, p_K)$ und $Q = (q_1, dots, q_K)$ mit Logarithmus zur Basis 2 (Einheit Bit) und der Konvention $0 log 0 = 0$:
  $ H(P) = - sum_k p_k log_2 p_k, quad "KL"(P || Q) = sum_k p_k log_2 p_k / q_k, $ <k04-eq-kl>
  $ "JSD"(P || Q) = 1/2 "KL"(P || M) + 1/2 "KL"(Q || M), quad M = 1/2 (P + Q). $ <k04-eq-jsd>
  Die *normierte Entropie* ist $H(P) \/ log_2 K in [0, 1]$; 1 heißt Gleichverteilung, 0 heißt die gesamte Masse auf einer Option.
]

#satz(titel: [Eigenschaften der JSD])[
  (i) $"JSD"(P || Q) = H(M) - 1/2 (H(P) + H(Q))$. (ii) $"JSD"$ ist symmetrisch. (iii) $0 <= "JSD"(P || Q) <= 1$ Bit, mit 0 genau bei $P = Q$ und 1 genau bei disjunkten Trägern. (iv) Die JSD hängt nur von den Paaren $(p_k, q_k)$ ab, nicht von der Ordnung der Optionen.
]

#beweis[
  (i) Es ist $"KL"(P || M) = sum_k p_k log_2 p_k - sum_k p_k log_2 m_k = -H(P) - sum_k p_k log_2 m_k$, analog für $Q$. Mitteln ergibt $-1/2 (H(P) + H(Q)) - sum_k (p_k + q_k)/2 dot log_2 m_k = -1/2 (H(P) + H(Q)) + H(M)$. (ii) folgt direkt aus der Symmetrie von @k04-eq-jsd in $P$ und $Q$. (iii) Nichtnegativität: KL ist nichtnegativ (Gibbs-Ungleichung), also auch der Mittelwert; KL ist genau dann null, wenn beide Argumente gleich sind, also $P = M = Q$. Obere Schranke: Wegen $m_k = (p_k + q_k)/2 >= p_k \/ 2$ ist $log_2 (p_k \/ m_k) <= log_2 2 = 1$ für alle $k$ mit $p_k > 0$, also $"KL"(P || M) <= sum_k p_k = 1$; analog für $Q$. Gleichheit verlangt $m_k = p_k \/ 2$ für alle $k$ mit $p_k > 0$, also $q_k = 0$ dort; das sind disjunkte Träger. (iv) Jeder Summand hängt nur von $p_k$, $q_k$ und $m_k$ ab; eine Permutation der Optionen permutiert nur die Summanden.
]

Eigenschaft (iii) ist der praktische Grund, warum man in der Simulationsliteratur selten die KL-Divergenz selbst nimmt: $"KL"(P || Q)$ wird unendlich, sobald das Modell einer Option, die Menschen wählen, die Wahrscheinlichkeit null gibt. Das ist kein exotischer Fall: Bei Pew hatte fast die Hälfte der Fragen mindestens eine Option, die kein synthetischer Befragter wählte @chapekis2026can. Die JSD bleibt dagegen endlich, weil $M$ überall positiv ist, wo $P$ oder $Q$ es sind.

#beispiel(titel: [JSD und Entropie für das kollabierte Modell])[
  Mit $P = (0.10, 0.20, 0.40, 0.30)$ und $Q_1 = (0.00, 0.05, 0.90, 0.05)$ ist $M = (0.05, 0.125, 0.65, 0.175)$.

  Entropien in Bit: $H(P) = 1.846$, $H(Q_1) = 0.569$, $H(M) = 1.435$. Nach Eigenschaft (i) ist
  $ "JSD" = 1.435 - (1.846 + 0.569)/2 = 1.435 - 1.208 = 0.227 " Bit". $
  Zur Kontrolle über @k04-eq-jsd: $"KL"(P || M) = 0.189$, $"KL"(Q_1 || M) = 0.266$, Mittelwert $0.227$. Für das gestreute Modell $Q_2$ ergibt sich $"JSD" = 0.021$ Bit, also rund ein Zehntel.

  Normierte Entropien ($log_2 4 = 2$): Menschen $1.846 \/ 2 = 0.92$, kollabiertes Modell $0.569 \/ 2 = 0.28$, gestreutes Modell $1.675 \/ 2 = 0.84$. Die normierte Entropie zeigt die Abflachung unmittelbar: Das kollabierte Modell nutzt weniger als ein Drittel der möglichen Unsicherheit, die Menschen über 90 %.
]

=== Warum die Ordnung zählt: ein Grenzfall

Eigenschaft (iv) ist Stärke und Schwäche zugleich. Nimm an, alle Menschen antworten mit Option 1, also $P = (1, 0, 0, 0)$. Modell A antwortet immer 2, Modell B immer 4.

#beispiel(titel: [Ordnungsblindheit der JSD])[
  Beide Modelle haben mit $P$ disjunkte Träger, also ist nach Eigenschaft (iii) $"JSD"(P || A) = "JSD"(P || B) = 1$ Bit, das Maximum. Die Wasserstein-Distanz unterscheidet: $"WD"(P, A) = 1$ (die gesamte Masse wandert eine Stufe), $"WD"(P, B) = 3$ (drei Stufen). Das Alignment ist $1 - 1/3 approx 0.67$ für A und $1 - 3/3 = 0$ für B. Auf einer Zustimmungsskala ist "stimme eher nicht zu" statt "stimme gar nicht zu" offensichtlich ein kleinerer Fehler als "stimme voll zu"; nur das Wasserstein-basierte Maß bildet das ab.
]

@k04-tab-metriken fasst die drei Modelle zusammen. Lies die Tabelle spaltenweise: Jedes Maß bringt einen anderen Aspekt des Fehlers ans Licht.

#figure(
  table(columns: (1.5fr, 0.7fr, 0.7fr, 0.7fr, 1fr),
    [Modellverteilung], [WD], [$cal(A)$], [JSD (Bit)], [norm. Entropie],
    [Menschen $P = (0.10, 0.20, 0.40, 0.30)$], [0], [1], [0], [0.92],
    [Kollabiert $Q_1 = (0.00, 0.05, 0.90, 0.05)$], [0.60], [0.80], [0.227], [0.28],
    [Gestreut $Q_2 = (0.05, 0.15, 0.35, 0.45)$], [0.30], [0.90], [0.021], [0.84],
    [Grenzfall: $P = (1, 0, 0, 0)$ vs. A = Option 2], [1], [0.67], [1], [0 vs. 0],
    [Grenzfall: $P = (1, 0, 0, 0)$ vs. B = Option 4], [3], [0], [1], [0 vs. 0],
  ),
  caption: [Drei Maße für dieselben Vergleiche. Das Alignment bestraft den Kollaps nur mäßig, die Entropie zeigt ihn deutlich, die JSD ist blind für die Ordnung der Skala.],
) <k04-tab-metriken>

=== Umsetzung in Python

Der folgende Ausschnitt entspricht den Hilfsfunktionen des Notebooks der Lehrveranstaltung. Er rechnet alle drei Maße von Hand und gegen SciPy.

#datei("verteilungen.py")[
```python
import numpy as np
from scipy.stats import wasserstein_distance
from scipy.spatial.distance import jensenshannon

def alignment(p_model, p_human):
    """Santurkar et al. (2023): 1 - WD / (N - 1), Optionen 1..N."""
    F1, F2 = np.cumsum(p_model)[:-1], np.cumsum(p_human)[:-1]
    return 1 - np.sum(np.abs(F1 - F2)) / (len(p_human) - 1)

def kl(p, q):
    p, q = np.asarray(p, float), np.asarray(q, float)
    m = p > 0
    return np.sum(p[m] * np.log2(p[m] / q[m]))

def jsd(p, q):                       # Divergenz in Bit, Bereich [0, 1]
    m = (np.asarray(p, float) + np.asarray(q, float)) / 2
    return 0.5 * kl(p, m) + 0.5 * kl(q, m)

def norm_entropy(p):
    p = np.asarray(p, float); nz = p[p > 0]
    return -np.sum(nz * np.log2(nz)) / np.log2(len(p))

P, Q1 = [.10, .20, .40, .30], [0, .05, .90, .05]
s = np.arange(1, 5)
print(alignment(Q1, P), 1 - wasserstein_distance(s, s, Q1, P) / 3)
print(jsd(Q1, P), jensenshannon(Q1, P, base=2) ** 2, jensenshannon(Q1, P, base=2))
print(norm_entropy(P), norm_entropy(Q1))
```
]

```out
0.7999999999999999 0.7999999999999999
0.2273966857445031 0.227396685744503 0.47686128564237945
0.9232196723355077 0.2844977967946406
```

#fallstrick[`scipy.spatial.distance.jensenshannon` liefert die Jensen-Shannon-*Distanz*, also die Wurzel der Divergenz. Im Beispiel sind das 0.477 statt 0.227. Wer Werte aus verschiedenen Papers vergleicht, muss prüfen, welche der beiden Größen und welche Logarithmusbasis berichtet wird; das Notebook weist ausdrücklich auf diese Falle hin.]

=== Kalibrierung von Antwortanteilen

Ein viertes Maß betrachtet nicht eine einzelne Frage, sondern alle Optionen aller Fragen gemeinsam. Man regressiert die vom Modell vorhergesagten Anteile $hat(pi)_j$ auf die beobachteten Anteile $pi_j$ über alle Optionen $j$:
$ hat(pi)_j = a + b dot pi_j + epsilon_j, quad hat(b) = (sum_j (pi_j - macron(pi))(hat(pi)_j - macron(hat(pi)))) / (sum_j (pi_j - macron(pi))^2). $ <k04-eq-slope>
Eine Steigung $b = 1$ bedeutet kalibrierte Anteile. $b < 1$ ist eine Regression zur Mitte: Seltene Optionen werden überschätzt, häufige unterschätzt. Morris und Leff berichten für GPT-5.2 eine Steigung von 0.82 @morris2026can. $b > 1$ bedeutet das Gegenteil: Populäre Antworten werden übertrieben und seltene unterdrückt, das typische Bild bei Abflachung. Im Notebook der Lehrveranstaltung ist die Simulation so parametrisiert, dass dieser zweite Fall eintritt.

=== Komprimierte Varianz verzerrt die Fallzahlplanung

Der vielleicht folgenreichste Befund von Bisbee et al. betrifft eine Nutzung, die harmlos wirkt: Man plant mit synthetischen Pilotdaten, wie viele Menschen man für die eigentliche Studie braucht. Die Standardformel für den Stichprobenumfang pro Gruppe beim Zwei-Gruppen-Vergleich eines Mittelwertunterschieds $Delta$ bei gemeinsamer Standardabweichung $sigma$ lautet (Lehrbuchformel)
$ n = 2 (z_(1 - alpha\/2) + z_(1 - beta))^2 sigma^2 / Delta^2. $ <k04-eq-power>

#satz(titel: [Verzerrungsfaktor durch synthetische Pilotdaten])[
  Liefert eine synthetische Stichprobe $sigma_"syn" = c_sigma sigma$ und $Delta_"syn" = c_Delta Delta$, so ist die geplante Fallzahl
  $ n_"syn" / n = (c_sigma / c_Delta)^2. $ <k04-eq-power-faktor>
]

#beweis[
  Einsetzen in @k04-eq-power: Der Faktor $2 (z_(1 - alpha\/2) + z_(1 - beta))^2$ kürzt sich, und es bleibt $(c_sigma^2 sigma^2 \/ (c_Delta^2 Delta^2)) \/ (sigma^2 \/ Delta^2) = (c_sigma \/ c_Delta)^2$.
]

#beispiel(titel: [Fallzahl mit halbierter Streuung und überhöhtem Effekt])[
  Ein menschlicher Effekt von $Delta = 0.3$ bei $sigma = 1$, zweiseitig $alpha = 0.05$, Power $1 - beta = 0.8$: $z_(0.975) = 1.960$, $z_(0.8) = 0.842$, also $2 (2.802)^2 = 15.70$ und $n = 15.70 dot 1 \/ 0.09 = 174.4$, aufgerundet 175 pro Gruppe.

  Die synthetische Stichprobe halbiert die Streuung ($c_sigma = 0.5$) und übertreibt den Gruppenunterschied um 50 % ($c_Delta = 1.5$, also $Delta_"syn" = 0.45$). Dann ist $n_"syn" = 15.70 dot 0.25 \/ 0.2025 = 19.4$, aufgerundet 20. Nach @k04-eq-power-faktor ist der Faktor $(0.5 \/ 1.5)^2 = 1\/9$. Eine Studie mit 20 statt 175 Personen pro Gruppe hätte für den echten Effekt nach derselben Normalapproximation nur eine Power von $Phi(0.3 \/ sqrt(2 \/ 20) - 1.960) = Phi(-1.011) approx 0.16$ statt 80 %.

  Bisbee et al. beobachteten eine Verzerrung derselben Größenordnung: 35 Parteianhänger für 99 % Power nach synthetischen Schätzungen gegenüber 299 nach ANES @bisbee2024synthetic[Tab. 1], ein Faktor von etwa $1 \/ 8.5$.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let sx = 1.55
    let sy = 3.4
    let dens(x, mu, s) = calc.exp(-calc.pow((x - mu) / s, 2) / 2) / (s * calc.sqrt(2 * calc.pi))
    let xs = range(0, 161).map(i => -3.5 + i * 0.05)
    let kurve(mu, s, col, dash) = {
      let pts = xs.map(x => ((x + 3.5) * sx, dens(x, mu, s) * sy))
      line(..pts, stroke: (paint: col, thickness: 1.2pt, dash: dash))
    }
    line((0, 0), (8 * sx, 0), stroke: 0.6pt + c-dark)
    for t in range(-3, 5) {
      line(((t + 3.5) * sx, -0.07), ((t + 3.5) * sx, 0.07), stroke: 0.6pt + c-dark)
      content(((t + 3.5) * sx, -0.3), k04-t(str(t), size: 6.5pt))
    }
    kurve(0.0, 1.0, c-blue, none)
    kurve(0.6, 1.0, c-teal, none)
    kurve(-0.15, 0.5, c-blue, "dashed")
    kurve(0.75, 0.5, c-teal, "dashed")
    content((1.2 * sx, 2.5), anchor: "east", k04-t([synthetisch: $sigma = 0.5$, \ Abstand 0.9], size: 6.8pt))
    content((6.9 * sx, 0.75), anchor: "west", k04-t([Mensch: $sigma = 1$, \ Abstand 0.6], size: 6.8pt))
    content((4 * sx, -0.7), k04-t([Einstellungsskala (standardisiert)], size: 6.8pt))
    rect((5.6 * sx, 2.35), (5.9 * sx, 2.45), fill: c-blue, stroke: none)
    content((6.0 * sx, 2.4), anchor: "west", k04-t([Gruppe A], size: 6.6pt))
    rect((5.6 * sx, 2.05), (5.9 * sx, 2.15), fill: c-teal, stroke: none)
    content((6.0 * sx, 2.1), anchor: "west", k04-t([Gruppe B], size: 6.6pt))
    content((5.6 * sx, 1.7), anchor: "west", k04-t([durchgezogen: Menschen \ gestrichelt: Silicon Sample], size: 6.4pt, fill: c-grey.darken(20%)))
  }),
  caption: [Stilisierte Darstellung (keine Daten) von Varianzkompression und übertriebener Gruppenlücke, wie sie Bisbee et al. beschreiben @bisbee2024synthetic. Die gestrichelten Verteilungen sind schmaler und weiter auseinander. Nach @k04-eq-power-faktor schrumpft die geplante Fallzahl dadurch auf ein Neuntel.],
) <k04-fig-varianz>

#praxis[Das Notebook `notebooks/04_silicon_sampling_validity.ipynb` der Lehrveranstaltung arbeitet mit einer *synthetischen* Umfrage: 1000 Befragte in vier Mobilitätsgruppen beantworten 12 erfundene Likert-Items zum Stadtverkehr, dazu ein simuliertes Silicon Sample mit je einer Persona pro Person. Die Verzerrungen des Simulators sind explizite Parameter (Gruppenlücke mal 1.6, Streuung innerhalb der Gruppen mal 0.4) und keine Schätzungen für ein reales Modell. Die Studierenden rechnen Alignment, JSD und Entropie pro Item, prüfen Abflachung und Gruppenlücken, vergleichen OLS-Koeffizienten, quantifizieren die Power-Verzerrung und trennen Antwortrealismus von Effektgenauigkeit. Eine optionale Zelle ersetzt den Simulator durch ein echtes Modell. Der Vorteil der synthetischen Daten: Die "Wahrheit" ist bekannt, und jede Metrik lässt sich gegen sie prüfen.]

#hoersaal([Welches der Maße soll ich in meiner Arbeit berichten?], [Mindestens eines, das die Ordnung berücksichtigt, und eines, das die Streuung zeigt. Für ordinale Skalen ist das Alignment nach @k04-eq-align der Standard der Literatur und erlaubt Vergleiche mit OpinionQA @santurkar2023whose; die normierte Entropie oder das Verhältnis der Standardabweichungen macht Abflachung sichtbar, die das Alignment verdeckt. Die JSD ist sinnvoll für nominale Optionen ohne Ordnung. Wichtiger als die Wahl des Maßes ist, dass die Ebene stimmt: Wenn deine Arbeit einen Regressionskoeffizienten oder einen Behandlungseffekt interpretiert, beweist kein Verteilungsmaß, dass dieser stimmt @li2026statistical.])

#hoersaal([Warum normiert man die Wasserstein-Distanz durch $N - 1$ und nicht durch $N$?], [Weil $N - 1$ der größtmögliche Wert ist. Nach dem Satz zum Wertebereich wird er erreicht, wenn die gesamte Masse von der ersten zur letzten Option wandern muss; das sind $N - 1$ Schritte. Die Division bildet die Distanz damit genau auf $[0, 1]$ ab, und das Alignment wird über Fragen mit unterschiedlich vielen Optionen vergleichbar. Santurkar et al. definieren das Maß in genau dieser Form @santurkar2023whose[Gl. 1].])


== Simulation von Experimenten und Verhalten <k04-sim>

Silicon Samples beantworten Fragebögen. Der nächste Schritt ist, Sprachmodelle in Experimente zu setzen: als Versuchspersonen in klassischen Studien, als Vorhersager von Behandlungseffekten, als Agenten in simulierten Welten und als feinjustierte Modelle menschlicher Kognition. Messeri und Crockett haben für solche Verwendungen das Bild des _Surrogats_ geprägt, eine von vier Visionen von KI in der Wissenschaft neben _Orakel_ (Literatur, Hypothesen), _Quant_ (Analyse) und _Schiedsrichter_ (Begutachtung, Replizierbarkeit) @messeri2024artificial. Dieser Abschnitt behandelt das Surrogat, der nächste die übrigen drei Visionen.

=== Turing-Experimente und Homo silicus

#definition(titel: [Turing-Experiment])[
  Ein *Turing-Experiment* prüft, wie gut ein Sprachmodell eine repräsentative Stichprobe von Teilnehmenden einer bestimmten Studie mit Menschen simulieren kann, im Unterschied zum klassischen Turing-Test, der ein einzelnes Individuum betrifft @aher2023using. Variiert werden die simulierten Teilnehmenden in der Originalarbeit über Anrede und Nachnamen ("Mr./Ms." plus Nachname) aus Namenslisten des US-Zensus @aher2023using[Abschn. 3].
]

#studie(titel: [Aher, Arriaga und Kalai 2023])[
  *Design:* acht OpenAI-Modelle von text-ada-001 bis GPT-4; vier Turing-Experimente: Ultimatumspiel, Garden-Path-Sätze, Milgram-Gehorsamsexperiment, Wisdom of Crowds @aher2023using[Abschn. 3]. \
  *Befund:* Ultimatumspiel mit 10 000 Paaren: Das größte Modell folgt dem menschlichen Annahmemuster; bei einem Angebot von 2 Dollar zeigt sich ein Geschlechtereffekt (Männer nehmen von Frauen etwa 60 % an, Frauen von Männern etwa 20 %) @aher2023using[Abschn. 4, Abb. 4-5]. Milgram: 75 von 100 simulierten Teilnehmenden gingen bis zum Ende der Schockserie, gegenüber 26 von 40 in Milgrams Experiment 1 @aher2023using[Abschn. 6, Abb. 7]. Wisdom of Crowds: Hyper-Genauigkeit, Median 1.0 bei IQR 0.0 für ChatGPT und GPT-4 @aher2023using[Abschn. 7, Abb. 8]. \
  *Grenzen:* Berühmte Studien liegen sehr wahrscheinlich in den Trainingsdaten; Namensvariation ist ein dünner Ersatz für Personen.
]

Horton und Koautoren gehen einen Schritt weiter und verstehen Sprachmodelle als implizite Rechenmodelle des Menschen, denen Ökonominnen und Ökonomen Informationen, Präferenzen und Szenarien geben können, um dann ihr Verhalten in simulierten Experimenten zu beobachten: _Homo silicus_ @horton2023large. Die überarbeitete Fassung von 2026 (jetzt mit Filippas und Manning) betont ausdrücklich, dass Ergebnisse von der Modellversion abhängen, dass Memorisierung und Performativität Probleme sind und dass Simulation als Exploration und Pilotierung, nicht als unverzerrte Inferenz zu verstehen ist @horton2023large[Abschn. 3.1, 3.3, 4].

#studie(titel: [Horton, Filippas und Manning 2023/2026])[
  *Design (v2):* Preiswucher-Fairness-Vignette nach Kahneman, Knetsch und Thaler mit politischen Personas (GPT-4, 2400 Beobachtungen); Diktatorspiele nach Charness und Rabin mit mehreren Modellen; Status-quo-Bias nach Samuelson und Zeckhauser; Mindestlohn-Einstellungsentscheidungen mit 43 Modellen @horton2023large[Abschn. 2.1-2.5]. \
  *Befund:* Linke Personas bewerten Preiserhöhungen als unfair, rechte sind nachsichtiger, mit Dosis-Wirkungs-Verlauf im Preis @horton2023large[Abb. 1-2]. Eine auf einseitigen Spielen kalibrierte Persona-Mischung senkte den Out-of-sample-MSE bei zweistufigen Spielen von 0.182 auf 0.094 @horton2023large[Abschn. 2.2.1]. Status-quo-Koeffizienten zwischen 0.316 (GPT-4o) und 0.931 (GPT-4) @horton2023large[Tab. 1]. Mindestlohn: Lohn der Eingestellten +1.31 Dollar pro Stunde ohne und +1.98 mit Referenzlohn, richtungsgleich mit Hortons Feldexperiment @horton2023large[Tab. 2]. Theoriebasierte Personas verbessern die Passung stärker als atheoretische @horton2023large[Abschn. 3.2]. \
  *Grenzen:* Working Paper; Abhängigkeit von der Modellversion; Simulationen sind Piloten, kein Ersatz für Daten von Menschen @horton2023large[Abschn. 4.2].
]

Die Spannweite der Status-quo-Koeffizienten von 0.316 bis 0.931 ist für sich genommen eine Lektion: Dieselbe Vignette liefert je nach Modell einen kleinen oder einen fast dreimal so großen Effekt. Das Modell ist kein neutraler Durchgang zu "dem Menschen", sondern ein Instrument mit eigener Kennlinie.

=== Behandlungseffekte vorhersagen

Die bisher stärkste positive Evidenz stammt aus einer Studie, die nicht einzelne Antworten, sondern Effekte vorhersagt. Bevor wir sie betrachten, brauchen wir die Größen.

#definition(titel: [Effektgrößen für simulierte Experimente])[
  Für ein Zwei-Gruppen-Experiment mit Ergebnis $y$ ist der durchschnittliche Behandlungseffekt $"ATE" = macron(y)_T - macron(y)_C$, die simulierte Entsprechung $hat("ATE")^"LLM" = macron(hat(y))_T - macron(hat(y))_C$ und der *ATE-Fehler* $|hat("ATE")^"LLM" - hat("ATE")^"Mensch"|$, bei binären Ergebnissen in Prozentpunkten. Der *Antwortrealismus* wird über den mittleren absoluten Fehler $"MAE" = 1/n sum_(i=1)^n |hat(y)_i - y_i|$ gemessen @li2026statistical. Über viele Experimente fasst man die Güte über die Korrelation zwischen vorhergesagten und beobachteten Effekten, die disattenuierte Korrelation $r_"adj"$, den Anteil richtig vorhergesagter Richtungen signifikanter Kontraste und den RMSE zusammen @hewitt2024predicting.
]

#studie(titel: [Hewitt, Ashokkumar, Ghezae und Willer 2024 (Manuskript); Nature 2026])[
  *Status:* Veröffentlicht 2026 in _Nature_ als "Large Language Models Can Predict the Results of Social Science Experiments" @ashokkumar2026large; die veröffentlichte Kurzfassung nennt 70 Experimente, 469 Effekte, 119 330 Teilnehmende, ein Sekundärarchiv von 15 Megastudien mit 606 Effekten und eine Befragung von 460 Sozialwissenschaftlerinnen und Sozialwissenschaftlern. *Alle Detailzahlen unten stammen aus dem Manuskript von August 2024* @hewitt2024predicting (476 Effekte, 105 165 Teilnehmende), weil der veröffentlichte Volltext für die Wissensbasis nicht geprüft werden konnte. \
  *Design:* 70 präregistrierte, national repräsentative US-Umfrageexperimente (50 aus TESS 2016-2022, 20 aus einer Replikations-Metaanalyse); GPT-4 simuliert Teilnehmende aus demografischen Profilen; Ensemble von Prompts @hewitt2024predicting[Methods]. \
  *Befund (Preprint 2024):* $r = 0.85$ ($r_"adj" = 0.91$) zwischen vorhergesagten und beobachteten Effekten; richtige Richtung für 90 % der signifikanten Kontraste @hewitt2024predicting[Abb. 2A]. Laien-Prognostiker ($N = 2659$) $r = 0.79$, GPT-4 plus Menschen $r = 0.88$ @hewitt2024predicting[Abb. 2B]. Unveröffentlichte Studien $r = 0.90$, veröffentlichte $r = 0.74$ @hewitt2024predicting[Abb. 2C]. Beträge überschätzt: RMSE 10.9 Pp. gegenüber 8.4 Pp. der Laien; nach Skalierung mit 0.56 nur noch 5.3 Pp. gegenüber 6.0 Pp. der ebenso skalierten Laienprognosen @hewitt2024predicting[Results]. Interaktionseffekte schlecht ($r$ zwischen $-0.03$ und 0.16) @hewitt2024predicting[Abb. 3]. Megastudien: Umfrageexperimente $r = 0.47$, Feldexperimente $r = 0.27$ @hewitt2024predicting[Abb. 4]. Dual Use: vorhergesagte Effekte impfskeptischer Posts korrelierten mit $r = 0.49$ mit den beobachteten @hewitt2024predicting[Abb. 5]. \
  *Grenzen:* textbasierte US-Umfrageexperimente; aggregierte Effekte viel besser als heterogene; Feldexperimente deutlich schwächer.
]

#figure(
  balken((
    ([GPT-4 plus Menschen], 0.88),
    ([GPT-4, alle Effekte], 0.85),
    ([Laien-Prognostiker], 0.79),
    ([GPT-4, unveröffentlichte Studien], 0.90),
    ([GPT-4, veröffentlichte Studien], 0.74),
    ([Megastudien: Umfrageexperimente], 0.47),
    ([Megastudien: Feldexperimente], 0.27),
  ), max: 1, breite: 7.5, farbe: c-teal, nachkomma: 2),
  caption: [Korrelation zwischen vorhergesagten und beobachteten Behandlungseffekten (Zahlen aus dem Preprint 2024 @hewitt2024predicting[Abb. 2, 4]). Je weiter die Aufgabe von textbasierten Umfrageexperimenten entfernt ist, desto schwächer die Vorhersage.],
) <k04-fig-hewitt>

#beispiel(titel: [Reskalierung überschätzter Effekte])[
  Ein menschliches Experiment zeigt einen Effekt von 4 Prozentpunkten, das Modell sagt 9 Prozentpunkte voraus (illustrative Zahlen nach dem Dossier). Ein auf *anderen* Studien geschätzter Skalierungsfaktor von 0.56 (der Wert aus dem Preprint 2024 von Hewitt et al.) liefert $9 dot 0.56 = 5.04 approx 5.0$ Pp., der ATE-Fehler sinkt von 5 auf 1 Prozentpunkt. Entscheidend ist die Herkunft des Faktors: Wird er auf denselben Studien geschätzt, an denen man danach den Fehler misst, ist die Evaluation zirkulär. Der Faktor muss auf zurückgehaltenen Studien geschätzt werden, genau wie ein Hyperparameter im maschinellen Lernen auf einer Validierungsmenge.
]

#hoersaal([Hewitt et al. finden bei unveröffentlichten Studien sogar bessere Vorhersagen als bei veröffentlichten. Ist Kontamination damit vom Tisch?], [Vorweg: Die Zahlen ($r = 0.90$ vs. $0.74$) stammen aus dem Preprint von 2024 und sind gegen die _Nature_-Fassung noch nicht geprüft @ashokkumar2026large. Der Befund spricht gegen reine Memorisierung als Erklärung, schließt Kontamination aber nicht aus. Erstens könnten sich die beiden Gruppen in anderen Merkmalen unterscheiden, etwa in Themen, Effektgrößen oder Designs; unveröffentlichte TESS-Studien könnten einfach leichtere Vorhersageprobleme sein. Zweitens kann auch unveröffentlichtes Material indirekt im Training stecken, etwa über Präregistrierungen oder verwandte Studien. Drittens zeigt der Vergleich nur die Differenz zweier Korrelationen; ob die Differenz selbst robust ist, wäre eigens zu prüfen. Die Folien der Lehrveranstaltung formulieren deshalb vorsichtig: Das Ergebnis argumentiert gegen reine Memorisierung, schließt Kontamination aber nicht aus @hewitt2024predicting[Abb. 2C].])

=== Realismus ist nicht Effektgenauigkeit

Li und Ji haben 2026 einen Befund vorgelegt, der für jede Validierung eines Simulators zentral ist. Sie trennen zwei Zielgrößen, die oft verwechselt werden.

#definition(titel: [Statistischer Realismus und Effektvalidität])[
  *Statistischer Realismus* ist die Nähe der simulierten Antworten zu den beobachteten menschlichen Antworten, etwa gemessen über den MAE auf Antwortebene @li2026statistical. *Effektvalidität* (Begriff aus dem Dossier der Lehrveranstaltung) ist die Nähe der aus simulierten Daten geschätzten Effekte (ATE, Regressionssteigungen) zu denen aus menschlichen Daten. Li und Ji zeigen, dass beides verschiedene Ziele sind: Die Validierung des einen validiert nicht das andere @li2026statistical[Abb. 2-3].
]

#studie(titel: [Li und Ji 2026])[
  *Design:* länderübergreifende Umfrageexperimente mit Einstellungs- und Verhaltensergebnissen; drei kleine API-Modelle (GPT-4o-mini, Gemini 2.5 Flash Lite, Claude 3 Haiku; Temperatur 0) und mehrere Prompt-Strategien gegen OLS/LASSO-Basislinien; drei Datensätze: ICPC (62 Länder, $n =$ 59 508, 11 Interventionen) und zwei Replikationsdatensätze (12 Länder, $n = 5948$; 27 Länder, $n =$ 14 837) @li2026statistical[Methods, Abb. 3b]. \
  *Befund:* MAE der LLM-Antworten 1.07-mal so groß wie bei OLS/LASSO, ATE-Fehler aber 2.10-mal so groß (etwa 8.7-9.4 gegenüber 4.3-4.4 Pp.) @li2026statistical[Abb. 2a]. Die Wahl des Prompts mit dem kleinsten MAE (Few-Shot) erhöhte den ATE-Fehler in 8 von 9 Modell-Ergebnis-Zellen, etwa bei Claude für das Verhaltensergebnis von 8.4 auf 44.2 Pp. @li2026statistical[Abb. 2b]. Auf Länderebene korrelieren MAE und ATE-Fehler nur mit Spearman $rho = 0.10$ (95 %-KI 0.01-0.19) @li2026statistical[Abb. 2c]. Die Korrelation der ATEs von Einstellung und Verhalten liegt bei Menschen bei $-0.03$, unter einem Chain-of-Thought-Prompt bei 0.82: Die Modelle koppeln Verhalten zu eng an Einstellungen @li2026statistical[Abb. 4b]. \
  *Grenzen:* Preprint; nur kleine, günstige Modelle, was die Übertragung auf Frontier-Modelle einschränkt; eine Familie von Experimenten.
]

#beispiel(titel: [Warum der beste Realismus den schlechtesten Effekt liefern kann])[
  Ein Experiment misst Zustimmung auf einer Skala von 1 bis 5; Kontrollgruppe im Mittel 3.0, Behandlungsgruppe 3.4, also $"ATE" = 0.4$. Prompt A ist ein Few-Shot-Prompt mit typischen Antworten; er trifft die einzelnen Antworten gut (MAE 0.8), ignoriert aber die Behandlung fast vollständig und liefert in beiden Gruppen im Mittel 3.2, also $hat("ATE") = 0$ und einen ATE-Fehler von 0.4. Prompt B streut mehr und trifft einzelne Antworten schlechter (MAE 1.0), reagiert aber auf die Behandlung mit $hat("ATE") = 0.35$, ATE-Fehler 0.05. Wer Prompts nach dem MAE auswählt, wählt A und verliert genau die Größe, um die es in der Studie geht. (Illustrative Zahlen; das Muster entspricht dem Befund in @li2026statistical[Abb. 2b], der nur die Größe des ATE-Fehlers berichtet, nicht seine Richtung.) Der Fehler kann ebenso in die andere Richtung gehen: Im Notebook der Lehrveranstaltung hat die realistischste Konfiguration den kleinsten MAE, übertreibt aber den Behandlungseffekt und hat deshalb den größten ATE-Fehler.
]

Mathematisch ist das wenig überraschend: Der MAE wird vom Abstand der Einzelantworten zu ihren Mittelwerten dominiert, der ATE ist eine Differenz zweier Mittelwerte. Ein Instrument kann die Lage beider Gruppen ungefähr treffen und trotzdem den Unterschied verlieren, weil der Unterschied klein relativ zur Streuung ist. Daraus folgt die praktische Regel des Abschnitts: *Validiere die Schätzgröße, die dein Paper berichtet* @li2026statistical @liu2026humanstudy.

HumanStudy-Bench macht dieselbe Unterscheidung mit zwei Kennzahlen: dem _Probability Alignment Score_ (PAS) für die Übereinstimmung, ob ein Effekt existiert, und dem _Effect Consistency Score_ (ECS) für die Übereinstimmung der Effektgröße @liu2026humanstudy. Auf 12 rekonstruierten Studien erreichte die beste Konfiguration PAS 0.5314 (Gemini 3 Flash mit Demografie), aber nur ECS 0.143; der beste ECS lag bei 0.265 (Claude Haiku 4.5) gegenüber einer geschätzten menschlichen Obergrenze von etwa 0.928 @liu2026humanstudy[Tab. 1-2]. Demografische Angaben verbesserten den PAS bei 9 von 10 Modellen, die Temperatur hatte keinen systematischen Effekt.

Eine groß angelegte Replikation von 156 psychologischen Experimenten aus führenden sozialwissenschaftlichen Zeitschriften mit GPT-4, Claude 3.5 Sonnet und DeepSeek v3 zeigt das zweite Problem, die Inflation @cui2024can: Haupteffekte wurden in 73-81 % repliziert, Interaktionen in 46-63 %; die Effektgrößen der LLMs (Fisher-$z$) waren etwa zwei- bis dreimal so groß wie die menschlichen; und in 68-83 % der Fälle, in denen die Originalstudie keinen Effekt fand, lieferten die Modelle ein signifikantes Ergebnis. Ein Simulator, der alles "repliziert", ist nicht informativ.

#merke[Ein Simulator muss bekannte Nulleffekte als null reproduzieren. Gehören keine Nulleffekte zur Validierungsmenge, kann man Effektinflation und falsch-positive Befunde gar nicht entdecken @cui2024can. Das ist die Hypothesenvalidität aus @k04-tab-validitaet.]

=== Foundation Models der Kognition: Centaur

Die bisher ehrgeizigste Form des Surrogats ist ein einziges Modell, das menschliches Verhalten in jedem Experiment vorhersagt, das sich in natürlicher Sprache beschreiben lässt. Binz et al. haben dafür Psych-101 gebaut, eine Transkription von 160 psychologischen Experimenten mit 60 092 Teilnehmenden und 10 681 650 Entscheidungen (253 597 411 Token), und Llama 3.1 70B darauf feinjustiert @binz2025foundation[Abb. 1, Methods]. Die Evaluation ist sauber definiert: Die Güte ist die negative Log-Likelihood der tatsächlichen menschlichen Antworten.

#definition(titel: [Evaluationsmetrik von Centaur])[
  $ "NLL" = -1/N sum_(n=1)^N log p_theta (r_n | c_n) $ <k04-eq-nll>
  Dabei ist $r_n$ die menschliche Antwort in Versuch $n$ (die Log-Likelihood wird über die Token der Antwort summiert), $c_n$ das Transkript des Experiments bis zu diesem Versuch, $p_theta$ das Modell und $N$ die Zahl der Antworten. Kleiner ist besser @binz2025foundation[Methods].
]

#beispiel(titel: [NLL von Hand])[
  Ein Modell gibt in vier Versuchen den tatsächlich gewählten Antworten die Wahrscheinlichkeiten 0.8, 0.6, 0.9 und 0.5. Die Summanden $-ln p$ (natürlicher Logarithmus) sind 0.223, 0.511, 0.105 und 0.693; der Mittelwert ist $"NLL" = 1.532 \/ 4 = 0.383$. Ein Modell, das bei zwei gleich wahrscheinlichen Optionen immer 0.5 gibt, hätte $ln 2 approx 0.693$. Die NLL bestraft vor allem Antworten, die das Modell für unwahrscheinlich hielt, und ist damit eine echte Verteilungsmetrik: Ein Modell, das immer die häufigste Antwort mit Wahrscheinlichkeit nahe 1 vorhersagt, wird für jede seltenere menschliche Antwort hart bestraft.
]

#studie(titel: [Binz et al. 2025 (Centaur)])[
  *Design:* Llama 3.1 70B (4 Bit), QLoRA mit Rang 8 auf allen Nicht-Embedding-Linearschichten (etwa 0.15 % neue Parameter), eine Epoche, Verlust nur auf den Token menschlicher Antworten; Evaluation auf zurückgehaltenen Teilnehmenden und auf Generalisierungsaufgaben @binz2025foundation[Methods]. \
  *Befund:* NLL auf zurückgehaltenen Teilnehmenden 0.44 (Centaur) gegenüber 0.58 (Llama ohne Fine-Tuning) und 0.56 (domänenspezifische kognitive Modelle); besser als die kognitiven Modelle in allen Experimenten bis auf eines @binz2025foundation[Abb. 2a]. Generalisierung: geänderte Coverstory 0.51 vs. 0.63 vs. 0.61; geänderte Aufgabenstruktur 0.42 vs. 0.62 vs. 0.98; neue Domäne (logisches Schließen) 1.65 vs. 1.92 @binz2025foundation[Abb. 3]. In einem sozialen Vorhersagespiel 64 % Genauigkeit bei Menschen gegenüber 35 % bei künstlichen Agenten @binz2025foundation[Abb. 2d]. Interne Repräsentationen sagen fMRT-Aktivität in der Two-Step-Aufgabe besser vorher als die von Llama @binz2025foundation[Abb. 4b]. \
  *Grenzen:* Vorhersagegüte ist keine mechanistische Theorie; Kritiker zeigen Unempfindlichkeit gegenüber Bedeutungsänderungen @schroder2025large. Psych-101 und der Adapter sind veröffentlicht @binz2025foundation.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let gruppen = (
      ([zurückgehaltene \ Teilnehmende], (0.44, 0.58, 0.56)),
      ([geänderte \ Coverstory], (0.51, 0.63, 0.61)),
      ([geänderte \ Struktur], (0.42, 0.62, 0.98)),
      ([neue Domäne \ (Logik)], (1.65, 1.92, none)),
    )
    let farben = (c-accent, c-grey, c-blue)
    let sy = 1.6
    let bw = 0.5
    line((0, 0), (12.6, 0), stroke: 0.6pt + c-dark)
    line((0, 0), (0, 2.0 * sy + 0.1), stroke: 0.6pt + c-dark)
    for t in (0, 0.5, 1.0, 1.5, 2.0) {
      line((-0.07, t * sy), (0, t * sy), stroke: 0.6pt + c-dark)
      content((-0.12, t * sy), anchor: "east", k04-t(str(t), size: 6.4pt))
    }
    content((-0.85, sy), angle: 90deg, k04-t([NLL (kleiner ist besser)], size: 6.8pt))
    for (g, (lab, werte)) in gruppen.enumerate() {
      let x0 = 0.6 + g * 3.1
      for (j, v) in werte.enumerate() {
        if v != none {
          let x = x0 + j * (bw + 0.08)
          rect((x, 0), (x + bw, v * sy), fill: farben.at(j), stroke: none)
          content((x + bw / 2, v * sy + 0.18), k04-t(str(v), size: 6.2pt))
        }
      }
      content((x0 + 0.85, -0.45), align(center, k04-t(lab, size: 6.6pt)))
    }
    for (j, lab) in ([Centaur], [Llama 3.1 70B], [kognitives Modell]).enumerate() {
      rect((0.4, 3.2 - j * 0.32), (0.65, 3.38 - j * 0.32), fill: farben.at(j), stroke: none)
      content((0.75, 3.29 - j * 0.32), anchor: "west", k04-t(lab, size: 6.6pt))
    }
  }),
  caption: [Negative Log-Likelihood von Centaur, Basismodell und domänenspezifischen kognitiven Modellen @binz2025foundation[Abb. 2a, 3]. Für die neue Domäne berichtet das Dossier keinen Wert eines kognitiven Modells.],
) <k04-fig-centaur>

Die Gegenposition hat Schröder et al. formuliert, und zwar mit einem Experiment, das als Vorlage für eigene Studien taugt.

#studie(titel: [Schröder et al. 2025])[
  *Design:* 30 moralische Szenarien aus Dillion et al., jeweils minimal so umformuliert, dass sich die Bedeutung ändert; 374 Menschen; GPT-3.5-Turbo, GPT-4o-mini, Llama-3.1-70B und Centaur @schroder2025large[Abschn. 4]. \
  *Befund:* Auf den Originalitems korrelieren Menschen und Modelle mit .97-.99 @schroder2025large[Tab. 2]. Korrelation zwischen Original und Umformulierung: Menschen $r = .54$, GPT-3.5 .89, GPT-4 .99, Llama .80, Centaur .83. Mittlere absolute Verschiebung der Ratings: Menschen 2.20, Centaur 1.25, Llama 1.18, GPT-3.5 0.75, GPT-4 0.42 @schroder2025large[Abschn. 4.5, Abb. 3]. \
  *Grenzen:* 30 Items; die Tabelle bezeichnet ein Modell als "GPT-4", die Methoden nennen GPT-4o-mini; einige Centaur-Unterschiede sind nach Korrektur nicht signifikant @schroder2025large[Tab. 3]. Preprint.
]

#figure(
  balken((
    ([Menschen], 2.20),
    ([Centaur], 1.25),
    ([Llama-3.1-70B], 1.18),
    ([GPT-3.5-Turbo], 0.75),
    ([GPT-4 (laut Methods GPT-4o-mini)], 0.42),
  ), max: 2.4, breite: 7.5, farbe: c-violet, nachkomma: 2),
  caption: [Mittlere absolute Verschiebung moralischer Ratings nach einer bedeutungsändernden Umformulierung @schroder2025large[Abb. 3]. Menschen reagieren auf die Bedeutungsänderung, die Modelle deutlich weniger: Sie generalisieren eher über Oberflächenähnlichkeit.],
) <k04-fig-schroeder>

Die Debatte um Centaur ist ein Lehrstück über Konstruktvalidität. Hu, Sosa und Ullman argumentieren für die Theory-of-Mind-Forschung, dass ein Teil der Uneinigkeit daher rührt, dass unklar bleibt, ob Modelle menschliches _Verhalten_ oder die kognitiven _Prozesse_ dahinter treffen sollen @hu2025reevaluating. Für Centaur gilt dasselbe: Vorhersagegüte ist ein Beleg über Verhalten, nicht automatisch über Mechanismen @binz2025foundation @schroder2025large. Ein Modell, das auf bekannten Items perfekt vorhersagt, auf bedeutungsändernde Störungen aber kaum reagiert, ist ein guter Interpolator im Raum der Trainingsaufgaben, aber keine Theorie der Moralpsychologie.

#tipp[Baue in jede Simulationsstudie einen *Störungstest* ein: bedeutungserhaltende Umformulierungen (das Modell sollte gleich antworten) und bedeutungsändernde (das Modell sollte so stark reagieren wie Menschen). Binz und Schulz haben schon 2023 gezeigt, dass kleine Störungen klassischer Vignetten, etwa eine andere Reihenfolge der Karten in der Wason-Aufgabe, die Antworten von GPT-3 änderten @binz2023using[Abb. 1B]; Schröder et al. liefern das Gegenstück für bedeutungsändernde Störungen.]

=== Generative Agenten

Eine dritte Linie setzt Sprachmodelle nicht als Befragte, sondern als handelnde Agenten in simulierte Welten. Park et al. haben 2023 die einflussreichste Architektur vorgestellt @park2023generative.

#definition(titel: [Generativer Agent])[
  Ein *generativer Agent* ist ein LLM-gesteuerter Agent mit einem _memory stream_ (einem natürlichsprachlichen Protokoll seiner Beobachtungen), einem Abrufmechanismus, Reflexion (höherstufigen Schlussfolgerungen aus Erinnerungen) und Planung, der in eine interaktive Umgebung gesetzt wird @park2023generative[Abschn. 4]. Die ursprüngliche Sandbox "Smallville" enthielt 25 Agenten auf Basis von gpt-3.5-turbo.
]

#figure(
  {
    set text(font: "Inter", size: 7.4pt, hyphenate: false)
    diagram(spacing: (7mm, 7mm), edge-stroke: 0.8pt + c-dark, mark-scale: 70%,
      fknoten((0, 0), [Wahrnehmung \ in der Umgebung], col: c-grey, w: 26mm),
      fknoten((1, 0), [*Memory Stream* \ Beobachtungen als Text, \ mit Zeitstempel], col: c-blue, filled: true, w: 32mm),
      fknoten((2, 0), [*Abruf* \ Recency + Importance \ + Relevance], col: c-accent, filled: true, w: 30mm),
      fknoten((3, 0), [Handlung \ und Dialog], col: c-grey, w: 24mm),
      fknoten((1, 1), [*Reflexion* \ wenn Summe der Wichtigkeit \ > 150], col: c-violet, w: 32mm),
      fknoten((2, 1), [*Planung* \ Tages- und Stundenpläne], col: c-teal, w: 30mm),
      edge((0, 0), (1, 0), "-|>"),
      edge((1, 0), (2, 0), "-|>"),
      edge((2, 0), (3, 0), "-|>"),
      edge((1, 0), (1, 1), "-|>", bend: 25deg),
      edge((1, 1), (1, 0), "-|>", bend: 25deg, label: [neue Erinnerung], label-side: left),
      edge((2, 0), (2, 1), "-|>"),
      edge((2, 1), (3, 0), "-|>"),
    )
  },
  caption: [Architektur generativer Agenten nach Park et al. @park2023generative[Abschn. 4]. Der Abruf gewichtet Aktualität, Wichtigkeit und Relevanz; Reflexionen werden wieder als Erinnerungen abgelegt.],
) <k04-fig-agenten>

Der Abruf ist eine einfache, gut rechenbare Bewertungsfunktion @park2023generative[Abschn. 4.1-4.2]:
$ "score"(m) = alpha_"rec" dot "recency"(m) + alpha_"imp" dot "importance"(m) + alpha_"rel" dot "relevance"(m, q). $ <k04-eq-retrieval>
Dabei ist $m$ ein Erinnerungsobjekt, die Aktualität ein exponentieller Zerfall mit Faktor 0.995 seit dem letzten Zugriff, die Wichtigkeit eine vom LLM vergebene ganze Zahl von 1 bis 10 und die Relevanz die Kosinus-Ähnlichkeit der Embeddings von Erinnerung und Anfrage $q$. Jede Komponente wird Min-Max-normiert, alle Gewichte $alpha$ sind 1. Eine Reflexion wird ausgelöst, wenn die summierte Wichtigkeit jüngster Ereignisse 150 überschreitet.

#beispiel(titel: [Welche Erinnerung wird abgerufen?])[
  Drei Erinnerungen, zuletzt vor 1, 24 und 100 Zeiteinheiten abgerufen; Wichtigkeit 2, 8 und 5; Kosinus-Ähnlichkeit zur Anfrage 0.30, 0.55 und 0.80.

  Aktualität roh: $0.995^1 = 0.995$, $0.995^24 = 0.887$, $0.995^100 = 0.606$; Min-Max-normiert $1$, $(0.887 - 0.606)\/(0.995 - 0.606) = 0.722$ und $0$. Wichtigkeit normiert: $0$, $1$, $0.5$. Relevanz normiert: $0$, $0.5$, $1$.

  Scores nach @k04-eq-retrieval: $m_1 = 1 + 0 + 0 = 1.00$, $m_2 = 0.722 + 1 + 0.5 = 2.22$, $m_3 = 0 + 0.5 + 1 = 1.50$. Abgerufen wird $m_2$, obwohl $m_3$ am relevantesten ist. Die Min-Max-Normierung hat eine Nebenwirkung, die in Übungen oft übersehen wird: Die Scores hängen davon ab, welche anderen Erinnerungen gerade im Kandidatenpool sind.
]

#studie(titel: [Park et al. 2023 (Generative Agents)])[
  *Design:* 25 Agenten in Smallville; kontrollierte Interview-Evaluation mit 100 Prolific-Bewertenden, die fünf Bedingungen in eine Rangfolge bringen; Analyse emergenten Verhaltens @park2023generative[Abschn. 6-7]. \
  *Befund:* TrueSkill-Werte: volle Architektur 29.89 > ohne Reflexion 26.88 > ohne Reflexion und Planung 25.64 > menschliche Crowdworker 22.95 > ohne Gedächtnis, Planung und Reflexion 21.21; Kruskal-Wallis $H(4) = 150.29$, $p < 0.001$ @park2023generative[Abschn. 6.5.1]. Informationsdiffusion: Das Wissen über eine Party stieg von 1 Agenten (4 %) auf 13 (52 %); die Netzwerkdichte von 0.167 auf 0.74; 1.3 % der Beziehungsaussagen waren halluziniert @park2023generative[Abschn. 7.1]. \
  *Grenzen (genannt):* Abruffehler, Ausschmückung, Missverständnis von Normen, übermäßig formelle und kooperative Dialoge, vermutlich durch Instruction Tuning @park2023generative[Abschn. 7.2].
]

#fallstrick[*Glaubwürdigkeit ist nicht Validität.* Die Evaluation der Generative Agents misst, wie plausibel menschliche Bewertende das Verhalten finden, nicht ob es realem Verhalten entspricht. Dass die volle Architektur plausibler wirkt als Menschen, die die Agenten spielen, ist ein Befund über Wahrnehmung, kein Beleg für eine korrekte Simulation von Menschen. Für Forschungszwecke braucht es dieselbe Validierung gegen menschliche Daten wie bei jedem anderen Simulator; Park et al. haben das 2024 mit den interviewbasierten Agenten nachgeholt @park2024llm.]

#hoersaal([Ist Centaur nicht genau das, was die Kritiker fordern: ein auf menschlichen Daten trainiertes, ordentlich evaluiertes Modell?], [In Bezug auf das Verfahren ja. Centaur macht aus "LLM als Teilnehmer" ein überwachtes Vorhersageproblem mit einer echten Verlustfunktion und einer Evaluation auf zurückgehaltenen Teilnehmenden @binz2025foundation[Abb. 2a]; das ist methodisch ein großer Fortschritt gegenüber reinem Prompting. Die Kritik zielt auf den Anspruch: Ob das Modell "menschliche Kognition simuliert" oder gut zwischen bekannten Aufgaben interpoliert, entscheidet sich an Generalisierung und Bedeutungssensitivität. Bei geänderten Coverstories und Strukturen generalisiert Centaur gut, bei bedeutungsändernden Umformulierungen reagiert es nur etwa halb so stark wie Menschen (1.25 vs. 2.20) @schroder2025large. Beide Befunde gehören in eine faire Darstellung.])

#hoersaal([Wie viele synthetische Teilnehmende brauche ich eigentlich pro Bedingung?], [So viele, dass die Schätzgröße mit der gewünschten Präzision geschätzt wird; das Lehrbuch formuliert für nicht deterministische Systeme genau diese Regel: Die Zahl der Wiederholungen ist eine Designentscheidung von derselben Bedeutung wie der Stichprobenumfang @haindl2027research. Wichtig ist aber, dass mehr synthetische Teilnehmende nur den Stichprobenfehler des _Instruments_ verkleinern, nicht seinen systematischen Fehler. Bei 30 Surrogaten pro Person fanden Lam et al. trotzdem nur rund ein Viertel der menschlichen Streuung @lam2026conditional[Tab. 4]. Ein enges Konfidenzintervall um einen verzerrten Wert ist keine Validität.])


== AI Scientists und Ideengenerierung <k04-ais>

Bisher war das LLM ein Instrument, das Daten über Menschen liefert. In diesem Abschnitt übernimmt es Forschungsaufgaben selbst: Literatur synthetisieren, Hypothesen und Ideen erzeugen, Experimente programmieren, Paper schreiben und begutachten. In der Begrifflichkeit von Messeri und Crockett sind das die Visionen _Orakel_ (Literatur, Hypothesen), _Quant_ (Analyse) und _Schiedsrichter_ (Begutachtung, Replizierbarkeit) @messeri2024artificial. Die beiden warnen vor drei Illusionen, die mit allen vier Visionen einhergehen: der Illusion erklärender Tiefe, der Illusion explorativer Breite und der Illusion von Objektivität; im schlimmsten Fall entstehen "Monokulturen des Wissens" @messeri2024artificial.

Auch hier gilt die Messperspektive, nur ist die Zielgröße eine andere. Ein AI Scientist ist ein Instrument, das "Forschungsqualität" erzeugen soll, und seine Evaluation ist eine Messung von Forschungsqualität. Wie in @k04-sim ist die entscheidende Frage, ob das Evaluationskriterium die Zielgröße trifft oder nur einen bequemen Stellvertreter.

=== Das Literatur-Orakel und seine Halluzinationen

Die messbarste Teilaufgabe ist die Literaturarbeit. Ein Benchmark für Literatursynthese fand, dass GPT-4o Zitate in 78-90 % der Fälle halluzinierte @asai2026synthesizing. Das retrieval-gestützte System OpenScholar mit einem Datenspeicher aus 45 Millionen Open-Access-Papern verbessert die Korrektheit; die in _Nature_ veröffentlichte Fassung berichtet laut Pressemitteilung Gewinne von 6.1 % gegenüber GPT-4o und 5.5 % gegenüber PaperQA2 und eine Präferenz von Fachleuten für die Antworten von etwa 50-70 % gegenüber von Fachleuten geschriebenen Antworten @asai2026synthesizing. Ein systematischer Review zum Einsatz von LLMs in Literaturreviews, selbst mit LLM-Unterstützung erstellt, fand unter 3788 Datensätzen 172 relevante Studien, von denen nur 26 tatsächliche Reviews waren; GPT-basierte Datenextraktion erreichte im Mittel 83.0 % Precision und 86.0 % Recall, beim Screening von Titeln und Abstracts schnitten GPT-Modelle etwas schlechter ab als BERT-basierte @scherbakov2025emergence.

Für die Messperspektive heißt das: Screening und Extraktion sind Klassifikations- und Messaufgaben, die mit Precision und Recall gegen eine menschliche Referenz validiert werden müssen. Die Werkzeuge dafür, insbesondere die Übereinstimmungsmaße und die statistische Korrektur, sind Thema von Kapitel 5 und Kapitel 6. Ziems et al. haben für die computationale Sozialwissenschaft ein ähnliches Bild gezeichnet: Zero-Shot-LLMs schlagen feinjustierte Klassifikatoren nicht, erreichen aber eine faire Übereinstimmung mit Menschen (Fehlinformation: FLAN-UL2 77.4 F1 gegenüber 81.6 feinjustiert, Kappa 0.55 gegenüber 0.51 zwischen Menschen); bei 8 von 17 Aufgaben war die Übereinstimmung moderat bis gut, bei 5 von 17 schlecht, davon 4 mit F1 nahe dem Zufall @ziems2024can[Abschn. 5, Tab. 3-4]. Die Empfehlung: das LLM als ein Annotator im Team, plus Goldstandard und designbasierte Schätzer @ziems2024can[Abschn. 5.1.1].

=== Ideen: neuer, aber schlechter umsetzbar

Si, Yang und Hashimoto haben die bislang sorgfältigste Studie dazu vorgelegt, ob LLMs neuartige Forschungsideen erzeugen können.

#studie(titel: [Si, Yang und Hashimoto 2025])[
  *Design:* 49 Fachleute als Ideengebende und 79 als Begutachtende (insgesamt über 100 NLP-Forschende); drei Bedingungen (Mensch, KI, KI mit menschlichem Re-Ranking), je 49 Ideen zu sieben Prompting-Themen; stilistisch normalisiert; 298 Gutachten @si2025can[Abschn. 2, 4]. \
  *Befund:* Neuheit: Mensch 4.84, KI 5.64, KI plus Re-Ranking 5.81 ($p < 0.05$); Machbarkeit für KI leicht niedriger, nicht signifikant @si2025can[Abschn. 5, Tab. 7]. LLMs als Begutachtende von Ideen sind schwach: beste paarweise Übereinstimmung 53.3 % gegenüber 56.1 % zwischen menschlichen Begutachtenden @si2025can[Tab. 11]. Geringe Diversität: Von 4000 Ausgangsideen pro Thema waren nur etwa 200 keine Duplikate @si2025can[Abschn. 7.1, Abb. 4]. \
  *Grenzen:* ein Feld (NLP-Prompting), nur Ideen, keine Umsetzung.
]

Die Folgestudie dreht die Schlagzeile um. 43 Fachleute setzten zufällig zugeteilte Ideen von Menschen oder vom LLM über jeweils mehr als 100 Stunden um und schrieben ein vierseitiges Paper; nach verblindeter Begutachtung verloren die LLM-Ideen auf allen Metriken (Neuheit, Spannung, Wirksamkeit, Gesamtbewertung) signifikant mehr Punkte als die menschlichen @si2025ideation. Das ist ein Musterfall für den Unterschied zwischen einer Stellvertretergröße (wie neu wirkt eine Idee auf dem Papier?) und der Zielgröße (wie gut ist die Forschung, die daraus entsteht?).

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let sy = 0.55
    line((0, 0), (6.4, 0), stroke: 0.6pt + c-dark)
    line((0, 0), (0, 6.5 * sy), stroke: 0.6pt + c-dark)
    for t in (0, 2, 4, 6) {
      line((-0.07, t * sy), (0, t * sy), stroke: 0.6pt + c-dark)
      content((-0.12, t * sy), anchor: "east", k04-t(str(t), size: 6.4pt))
    }
    content((-0.75, 3 * sy), angle: 90deg, k04-t([Neuheit (Skala 1-10)], size: 6.8pt))
    for (i, (lab, v, col)) in (([Mensch], 4.84, c-blue), ([KI], 5.64, c-accent), ([KI + Re-Ranking], 5.81, c-accent.darken(15%))).enumerate() {
      let x = 0.5 + i * 2.0
      rect((x, 0), (x + 1.3, v * sy), fill: col, stroke: none)
      content((x + 0.65, v * sy + 0.2), k04-t(str(v), size: 6.8pt))
      content((x + 0.65, -0.3), k04-t(lab, size: 6.8pt))
    }
    content((3.2, -0.75), k04-t([vor der Umsetzung @si2025can], size: 6.8pt, weight: "bold"))
    // rechte Seite: qualitativ
    let x0 = 8.2
    rect((x0, 0.2), (x0 + 5.6, 3.4), radius: 0.12, fill: c-red.lighten(92%), stroke: 0.8pt + c-red)
    content((x0 + 2.8, 3.0), k04-t([nach der Umsetzung @si2025ideation], size: 7pt, weight: "bold", fill: c-red.darken(20%)))
    content((x0 + 2.8, 1.75), align(center, k04-t([43 Fachleute setzen zufällig \ zugeteilte Ideen um (> 100 h je Idee). \ LLM-Ideen verlieren auf allen vier \ Metriken signifikant mehr Punkte \ als menschliche Ideen.], size: 6.9pt)))
    line((6.6, 1.8), (x0 - 0.15, 1.8), stroke: (paint: c-dark, thickness: 0.9pt), mark: (end: "stealth", fill: c-dark, scale: 0.6))
  }),
  caption: [Die Ideation-Execution-Lücke: Vor der Umsetzung werden LLM-Ideen als neuer bewertet, nach der Umsetzung verlieren sie mehr als menschliche Ideen. Links Mittelwerte nach Si et al. @si2025can[Tab. 7], rechts der Befund der Folgestudie @si2025ideation (dort ohne einzelne Zahlen im Dossier).],
) <k04-fig-ideen>

Als Vergleich, wie ein validiertes Verfahren zur Hypothesengenerierung aussehen kann, eignet sich eine Arbeit ohne LLM: Ludwig und Mullainathan verwandeln ein prädiktives Black-Box-Modell in interpretierbare Hypothesen; im Beispiel erklären allein die Pixel von Polizeifotos bis zur Hälfte der vorhersagbaren Variation in Haftentscheidungen von Richterinnen und Richtern, und die resultierenden Hypothesen werden weder durch Demografie noch durch frühere Arbeiten erklärt @ludwig2024machine. Googles Co-Scientist, ein Gemini-basiertes Multi-Agenten-System, das Hypothesen in einem Turnier erzeugt, kritisiert und verfeinert, wurde mit In-vitro-Validierung von Wirkstoff-Repurposing-Kandidaten für akute myeloische Leukämie geprüft; die Hypothesenqualität stieg mit der Rechenzeit zur Inferenz @gottweis2026accelerating. In beiden Fällen ist das externe Kriterium (Daten, Laborexperiment) die eigentliche Validierung.

=== Der AI Scientist

Das prominenteste System für automatisierte Forschung ist der AI Scientist, 2026 in _Nature_ veröffentlicht @lu2026towards, mit zwei Vorläufer-Preprints @lu2024ai @yamada2025ai. Die Pipeline reicht von der Idee über Code und Experimente bis zum fertigen Paper und enthält einen LLM-basierten "Automated Reviewer".

#figure(
  {
    set text(font: "Inter", size: 7.4pt, hyphenate: false)
    diagram(spacing: (4mm, 8mm), edge-stroke: 0.8pt + c-dark, mark-scale: 70%,
      fknoten((0, 0), [Idee und \ Neuheitsprüfung], col: c-blue, filled: true, w: 28mm),
      fknoten((1, 0), [Code und \ Experimente], col: c-blue, filled: true, w: 30mm),
      fknoten((2, 0), [Paper \ schreiben], col: c-blue, filled: true, w: 28mm),
      fknoten((3, 0), [Automated \ Reviewer], col: c-accent, filled: true, w: 28mm),
      fknoten((4, 0), [Entscheidung \ und Archiv], col: c-grey, w: 24mm),
      edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"), edge((3, 0), (4, 0), "-|>"),
      fknoten((0, 1), text(size: 7.2pt)[bekannte Konzepte als neu eingestuft @beel2025evaluating], col: c-red, w: 28mm),
      fknoten((1, 1), text(size: 7.2pt)[42~% der Experimente scheitern an Codefehlern @beel2025evaluating; 57~% Train/Test-Overlap im angenommenen Paper @yamada2025ai], col: c-red, w: 30mm),
      fknoten((2, 1), text(size: 7.2pt)[halluzinierte Zahlen und Zitate, Platzhalter @beel2025evaluating], col: c-red, w: 28mm),
      fknoten((3, 1), text(size: 7.2pt)[Balanced Accuracy 0.69 bzw. 0.66 (Menschen 0.66) @lu2026towards], col: c-teal, w: 28mm),
      edge((0, 0), (0, 1), "-", stroke: (paint: c-red, thickness: 0.5pt, dash: "dashed")),
      edge((1, 0), (1, 1), "-", stroke: (paint: c-red, thickness: 0.5pt, dash: "dashed")),
      edge((2, 0), (2, 1), "-", stroke: (paint: c-red, thickness: 0.5pt, dash: "dashed")),
      edge((3, 0), (3, 1), "-", stroke: (paint: c-teal, thickness: 0.5pt, dash: "dashed")),
    )
  },
  caption: [Die Pipeline des AI Scientist mit den dokumentierten Schwachstellen je Stufe (rot) und der Güte des Automated Reviewer (türkis). Quellen: @lu2026towards[Tab. 1] @yamada2025ai[Abschn. 4] @beel2025evaluating.],
) <k04-fig-aisci>

#studie(titel: [Lu et al. 2026 (AI Scientist, Nature) mit Vorläufern])[
  *Design:* End-to-End-Pipeline für ML-Forschung plus LLM-Reviewer; Evaluation des Reviewers an begutachteten Papern vor und nach dem Trainings-Cutoff; Einreichung vollständig KI-generierter Paper bei einem Workshop @lu2026towards @yamada2025ai. \
  *Befund:* Kosten pro Paper in v1 unter 15 Dollar @lu2024ai. Automated Reviewer: Balanced Accuracy $0.69 plus.minus 0.04$ auf Papern vor dem Cutoff gegenüber 0.66 im NeurIPS-2021-Konsistenzexperiment mit Menschen; $0.66 plus.minus 0.03$ auf Papern von 2025 nach dem Cutoff; F1 0.62 gegenüber 0.49 für Menschen @lu2026towards[Tab. 1]. Beim ICLR-2025-Workshop ICBINB waren 3 von 43 Einreichungen KI-generiert; eine erhielt 6, 7 und 6 (Mittel 6.33) und wurde wie vereinbart zurückgezogen; die Autoren selbst urteilten, dass keine den Standard der Hauptkonferenz erreichte; ihre eigene Code-Prüfung fand im angenommenen Paper etwa 57 % Überlappung zwischen Trainings- und Testdaten, was die Workshop-Begutachtenden nicht bemerkt hatten @yamada2025ai[Abschn. 4.1-4.2]. Annahmequote des Workshops etwa 70 % gegenüber 32 % für die Hauptkonferenz @lu2026towards. \
  *Grenzen (genannt):* naive Ideen, falsche Implementierungen, schwache Strenge, doppelte Abbildungen, halluzinierte Zitate; mehrere bis über 15 Stunden pro Paper @lu2026towards.
]

Zwei Punkte verdienen messtheoretische Aufmerksamkeit. Erstens ist "ein Paper hat die Begutachtung bestanden" eine Messung mit bekannt schwacher Reliabilität (das NeurIPS-Experiment liefert die menschliche Referenz von 0.66) bei einem Workshop mit hoher Annahmequote; der Anspruch "KI schreibt begutachtungsfähige Forschung" stützt sich also auf ein Instrument mit niedriger Trennschärfe. Zweitens ist der Automated Reviewer selbst ein LLM-as-a-Judge-Instrument, dessen Validierung die Fragen von Kapitel 7 aufwirft. Dass er auf Papern nach dem Cutoff etwas schlechter ist als davor (0.66 vs. 0.69), ist mit Kontamination vereinbar.

Unabhängige Audits zeichnen ein ernüchterndes Bild. Beel, Kan und Baumgart fanden beim AI Scientist, dass 42 % der Experimente an Codefehlern scheiterten, etablierte Konzepte als neu eingestuft wurden, die Manuskripte im Median fünf Zitate hatten (nur 5 von 34 aus 2020 oder später), Zahlenergebnisse halluziniert und Abbildungen fehlten oder Platzhaltertext enthielten; pro Paper fielen 6-15 Dollar und 3.5 Stunden menschlicher Aufwand an @beel2025evaluating. Ein Benchmark mehrerer AI-Scientist-Systeme auf 15 Vorschlägen fand Bewertungen um 1 von 5 durch LLM-Begutachtende, bei Kosten von 9-26 Dollar pro Paper; der Bericht hat jedoch interne Inkonsistenzen und ist nur als Indiz zu lesen @ravideshik2026can[Tab. 2-3].

#studie(titel: [Bianchi et al. 2025 (Agents4Science)])[
  *Design:* Bericht über eine Konferenz (22. Oktober 2025), bei der KI-Systeme als Erstautoren und LLMs als Begutachtende auftraten @bianchi2025exploring. \
  *Befund:* 315 Einreichungen, 253 begutachtet, 79 an menschliche Begutachtung weitergeleitet, 48 angenommen; alle angenommenen Paper mit KI als Erstautor. Drei LLM-Begutachtende (GPT-5, Gemini 2.5 Pro, Claude Sonnet 4) mit mittlerer paarweiser Pearson-Korrelation $r = 0.48$; mittlere absolute Abweichung von menschlichen Bewertungen 0.91 (GPT-5), 1.09 (Claude), 2.73 (Gemini). Vollständig KI-getriebene Forschung machte 23.3 % der Einreichungen, aber nur 14.9 % der angenommenen Paper aus. Nur etwa 44 % der Einreichungen waren frei von halluzinierten Referenzen. Zwei Paper versuchten Prompt-Injection gegen die KI-Begutachtenden @bianchi2025exploring. \
  *Grenzen:* Preprint; Selbstselektion der Einreichenden.
]

#beispiel(titel: [Was die Zahlen von Agents4Science bedeuten])[
  Die Gesamtannahmequote ist $48 \/ 315 approx 15.2$ %, bezogen auf die begutachteten Einreichungen $48 \/ 253 approx 19.0$ %. Wären vollständig KI-getriebene Einreichungen genauso erfolgreich wie die übrigen, müsste ihr Anteil unter den angenommenen Papern ihrem Anteil an den Einreichungen entsprechen. Stattdessen sinkt er von 23.3 % auf 14.9 %; das Verhältnis $14.9 \/ 23.3 approx 0.64$ bedeutet, dass rein KI-getriebene Arbeiten nur etwa zwei Drittel der Erfolgschance hatten. Und bei einer paarweisen Korrelation der LLM-Begutachtenden von 0.48 erklärt eine Begutachtung die andere zu weniger als einem Viertel ($0.48^2 approx 0.23$).
]

#hoersaal([Wenn ein KI-generiertes Paper die Begutachtung besteht, ist das nicht ein klarer Beleg, dass KI Forschung kann?], [Es ist ein Beleg, dass das Paper ein bestimmtes Messinstrument passiert hat, nämlich die Begutachtung bei einem Workshop mit etwa 70 % Annahmequote @lu2026towards. Die Validität dieses Instruments für "Forschungsqualität" ist begrenzt: Die Begutachtenden übersahen eine Train/Test-Überlappung von rund 57 %, die die Autoren selbst bei ihrer Code-Prüfung fanden @yamada2025ai[Abschn. 4]. Die Autoren selbst schreiben, dass keine Einreichung den Standard der Hauptkonferenz erreicht hätte. Die richtige Formulierung ist also: Ein KI-generiertes Paper kann eine wenig trennscharfe Begutachtung bestehen, auch wenn es einen schweren methodischen Fehler enthält. Das sagt mindestens so viel über Peer Review wie über KI.])

== Validitätsbedrohungen: das Instrument als bewegliches Ziel <k04-bedrohungen>

Die vorigen Abschnitte haben Bedrohungen jeweils am Beispiel gezeigt. Hier werden sie systematisch geordnet. Den Rahmen liefert das Lehrbuch, das für KI-Systeme einen Unterschied zu jeder früheren Forschung herausarbeitet: Ein kontrolliertes Experiment setzt voraus, dass das Untersuchungsobjekt konstant bleibt, während man einen Faktor variiert, und genau diese Annahme verletzen KI-Systeme, besonders wenn sie als kommerzielle Dienste genutzt werden @haindl2027research.

=== Versionsdrift und Deprecation

Kommerzielle KI-Systeme werden laufend und oft stillschweigend aktualisiert; derselbe Prompt kann im Frühjahr eine andere Antwort liefern als im Herbst @haindl2027research. Eine scheinbare Veränderung der Ergebnisse kann dann ein stilles Modell-Update widerspiegeln statt der manipulierten Variable, eine Bedrohung der internen Validität, die frühere Forschung nicht kannte: ein Störfaktor, den die Forschenden weder sehen noch eingeführt haben @haindl2027research. Bisbee et al. haben das an einem konkreten Datum beobachtet (@k04-fig-drift).

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    line((0, 0), (14, 0), stroke: 1pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.6))
    let punkte = ((1.5, [April 2023], [Lauf 1: Referenz], c-blue), (6.5, [Juni 2023], [Lauf 2: Steigung 0.93 \ gegenüber April], c-teal), (12, [Juli 2023], [Lauf 3: deutliche \ Regression zur Mitte], c-red))
    for (x, d, t, col) in punkte {
      circle((x, 0), radius: 0.13, fill: col, stroke: none)
      content((x, -0.4), k04-t(d, size: 7pt, weight: "bold"))
      rect((x - 1.45, 0.45), (x + 1.45, 1.55), radius: 0.1, fill: col.lighten(88%), stroke: 0.7pt + col)
      content((x, 1.0), align(center, k04-t(t, size: 6.8pt)))
    }
    line((9.3, -0.15), (9.3, 2.1), stroke: (paint: c-accent, thickness: 1.2pt, dash: "dashed"))
    content((9.3, 2.35), k04-t([25. Juni 2023: Modell-Update des Anbieters], size: 6.8pt, fill: c-accent.darken(10%), weight: "bold"))
    content((7, -1.0), k04-t([identischer Prompt, identische Personas, "dasselbe" Modell ChatGPT 3.5], size: 6.8pt, fill: c-grey.darken(25%)))
  }),
  caption: [Versionsdrift im Beispiel von Bisbee et al. @bisbee2024synthetic[Abschn. 3.2, Abb. 5]: Identische Läufe gegen einen geschlossenen Dienst liefern verschiedene Verteilungen, plausibel ausgelöst durch ein Modell-Update. Das Lehrbuch nennt das die KI als bewegliches Ziel @haindl2027research.],
) <k04-fig-drift>

Die Gegenmaßnahmen des Lehrbuchs sind praktisch: die exakte Modellversion und das Zugriffsdatum festhalten und berichten; wo möglich selbst gehostete oder archivierbare Gewichte bevorzugen, weil ein Modell, das man selbst hält, nicht ohne eigenes Wissen verändert werden kann; das Verhalten eines gehosteten Systems durch Protokollierung von Ein- und Ausgaben zum Studienzeitpunkt sichern, damit spätere Drift wenigstens erkennbar ist; und die Modellversion als experimentellen Faktor behandeln @haindl2027research.

_Deprecation_ ist die extreme Form der Drift: Das Modell verschwindet. Das Lehrbuch beschreibt die zugrunde liegende Asymmetrie: Ein gehostetes Modell ist am Tag der Studie am besten reproduzierbar und wird danach mit jedem stillen Update weniger reproduzierbar; die Dokumentation, die überflüssig wirkte, solange das Modell aktuell war, ist nach seiner Abschaltung der einzige verbleibende Beleg dafür, dass die Studie überhaupt interpretierbar ist. Die Dokumentation muss das Artefakt überdauern, das sie beschreibt @haindl2027research.

=== Geschlossene oder offene Modelle?

Palmer, Smith und Spirling haben die Konsequenz für die Forschungspraxis formuliert: Geschlossene Modelle können sich ändern oder verschwinden und gefährden damit die Reproduzierbarkeit; Forschende sollen ihre Verwendung begründen, wo machbar mit offenen Modellen vergleichen, und Publikationsorgane sollen das verlangen; die Autoren nennen sechs Umstände, unter denen geschlossene Modelle akzeptabel sein können, etwa wenn das Modell selbst Gegenstand der Untersuchung ist oder wenn Spitzenleistung erforderlich ist @palmer2024using. Spirling argumentiert grundsätzlicher für große kollaborative Open-Source-Projekte und hält die offene Umgebung für die richtige @spirling2023why; Bail fordert offene Forschungsinfrastruktur @bail2024can. Offene Gewichte ermöglichen fixierte Versionen und Fine-Tuning mit veröffentlichten Daten und Adaptern, wie bei Psych-101 und Centaur @binz2025foundation.

Der Gegenpunkt gehört in jede faire Darstellung: Die stärksten Ergebnisse zur Effektvorhersage stammen von einem geschlossenen Frontier-Modell (GPT-4, Preprint 2024) @hewitt2024predicting, und die besten PAS- und ECS-Werte auf HumanStudy-Bench 2026 erreichten geschlossene Modelle (Gemini 3 Flash, Claude Haiku 4.5) @liu2026humanstudy[Tab. 1]. Der Zielkonflikt zwischen Genauigkeit und Reproduzierbarkeit muss pro Studie argumentiert werden; GUIDE-LLM führt die Begründung der Modellwahl als optionalen Berichtspunkt @guidellm2026checklist.

=== Schnittstelle und Nichtdeterminismus

Dasselbe Modell ist nicht dasselbe Instrument, wenn der Zugangsweg wechselt. GPT-4o-mini erreichte über die API bei Temperatur 0 eine Test-Retest-Reliabilität von 0.97-0.99, über die ChatGPT-Oberfläche nur 0.66-0.91 @mangiaterra2025can[Tab. 3]; die Oberfläche enthält verborgene Systemprompts und Sampling-Einstellungen, die die Forschenden nicht kontrollieren. Allgemein gilt, wie das Lehrbuch formuliert: Bei nicht deterministischen Systemen ist jede Konfiguration eine Verteilung, aus der man stichprobt, keine Funktion, die man auswertet; man führt jede Bedingung mehrfach aus und berichtet Lage und Streuung, denn die Streuung ist Teil des Ergebnisses @haindl2027research.

=== Prompt-Sensitivität

Das Lehrbuch nennt Prompt-Sensitivität eine Gefahr, die sich als Befund tarnt @haindl2027research. Sclar et al. dokumentierten, dass Formatierungsänderungen ohne Bedeutungsänderung bei verbreiteten offenen Modellen im ungünstigsten Fall Leistungsunterschiede von bis zu 76 Genauigkeitspunkten erzeugten, im Mittel über viele Aufgaben und Modelle etwa zehn @sclar2024quantifying. Mizrahi et al. evaluierten 20 Modelle auf 39 Aufgaben und fanden, dass sich die Rangfolge der Systeme je nach gewähltem Prompt-Template umkehren kann @mizrahi2024state. Ein Ergebnis aus einem einzigen Prompt ist damit eine Stichprobe vom Umfang eins aus einer nicht charakterisierten Verteilung; der Prompt ist Teil des Instruments, und eine Studie, die das System variiert und einen einzigen willkürlichen Prompt festhält, hat beides konfundiert @haindl2027research.

Für Simulationen kommen inhaltliche Prompt-Entscheidungen hinzu. Das Weglassen politischer Attribute aus Personas erhöhte die Fehler deutlich @bisbee2024synthetic[Abb. 4]. Bei kulturellen Personas für 15 Länder verbesserte die Angabe des Landes die Übereinstimmung mit 7286 realen Teilnehmenden, das Prompten in der Landessprache verschlechterte sie @kwok2024evaluating. Bei Diktatorspielen erzeugten menschenähnliche Personas allein kein menschenähnliches Geben, und die Übereinstimmung schwankte über Architekturen und Prompts ohne klares Muster @ma2024can. Und die Auswahl des Prompts nach dem Antwortrealismus kann den Behandlungseffekt verschlechtern @li2026statistical[Abb. 2b].

=== Kontamination

Weil große Modelle auf umfangreichen, oft nicht offengelegten Teilen des Internets trainiert werden, kann das Evaluationsziel bereits in den Trainingsdaten liegen; scheinbare Leistung spiegelt dann Memorisierung statt Fähigkeit, und keine statistische Sorgfalt auf der Evaluationsseite repariert das @haindl2027research. Für Simulationsstudien betrifft das die Studienmaterialien, die publizierten Ergebnisse und Normdatensätze. Binz und Schulz warnten, dass klassische Vignetten in Trainingsdaten auftauchen können @binz2023using; Aher et al. simulierten berühmte Studien @aher2023using; bei Mangiaterra et al. stammten nur 364 von 687 Metaphern aus Datensätzen, die vor dem Cutoff nicht online waren @mangiaterra2025can[Abschn. 4].

Das Lehrbuch nennt drei Strategien, Kontamination nachträglich zu erkennen: die Suche nach wörtlicher Überlappung (nur bei offenem Trainingskorpus möglich); die Asymmetrie zwischen kanonischer Formulierung und bedeutungserhaltender Paraphrase, weil ein Leistungseinbruch bei Umformulierung auf Gedächtnis hinweist; und _Canaries_, eindeutige Zeichenketten, deren spätere Ausgabe verrät, dass ein Benchmark ins Training gelangt ist. Keine dieser Strategien ist für sich schlüssig; Kontamination ist eine Frage des Grades und der Evidenz, und das Argument gehört in den Bericht @haindl2027research. Für Simulationen ist die praktikabelste Variante die zeitliche Aufteilung der Ziele relativ zum Cutoff, wie bei Hewitt et al. (unveröffentlicht $r = 0.90$ vs. veröffentlicht $r = 0.74$, Preprint 2024) @hewitt2024predicting[Abb. 2C].

=== Übersicht

@k04-tab-bedrohungen fasst die Bedrohungen in der Form zusammen, die das Dossier der Lehrveranstaltung als Synthese vorschlägt: Mechanismus, Beleg, Prüfung.

#figure(placement: auto,
  table(columns: (1.05fr, 1fr, 1.1fr, 1.35fr),
    [Bedrohung], [Mechanismus], [Beleg], [Prüfung],
    [Varianzkompression, Abflachung], [Instruction Tuning, Modus-Suche], [@bisbee2024synthetic @wang2025large @santurkar2023whose], [SD, Entropie, Optionsabdeckung je Gruppe vergleichen],
    [Übertriebene Gruppenunterschiede], [stereotype Personas], [@bisbee2024synthetic @wang2025large], [Gruppenlücken vergleichen, nicht nur Mittelwerte],
    [Falsche Zusammenhänge], [Musterentsprechung versagt], [@bisbee2024synthetic @li2026statistical], [Koeffizienten und ATEs vergleichen],
    [Hyper-Genauigkeit], [Ausrichtung auf Korrektheit], [@aher2023using @chapekis2026can], [Wissensitems mit bekannten menschlichen Fehlerraten einbauen],
    [Prompt-Sensitivität], [Persona-Inhalt, Sprache, Format], [@bisbee2024synthetic @kwok2024evaluating @sclar2024quantifying], [Prompt-Ensembles, alle Varianten berichten],
    [Oberflächen-Generalisierung], [Tokenähnlichkeit statt Bedeutung], [@schroder2025large @binz2023using], [bedeutungserhaltende und -ändernde Störungen],
    [Kontamination], [Ziele im Training], [@hewitt2024predicting @mangiaterra2025can], [Ziele nach Datum vs. Cutoff aufteilen],
    [Drift, Deprecation], [Updates geschlossener Modelle], [@bisbee2024synthetic @horton2023large], [Snapshot fixieren, Daten loggen, offene Gewichte bevorzugen],
    [Schnittstelleneffekte], [verborgene Systemprompts, Sampling], [@mangiaterra2025can], [API mit festen Parametern],
    [Antwortreihenfolge], [Label- und Positionsbias], [@dominguezolmedo2024questioning], [Reihenfolge randomisieren, mit Gleichverteilung vergleichen],
    [WEIRD, US-Zentrierung], [Trainings- und Alignment-Populationen], [@santurkar2023whose @dillion2023can @kwok2024evaluating], [Zielpopulation explizit testen],
    [Effektinflation, falsch-positive Befunde], [Simulator findet überall Effekte], [@cui2024can @hewitt2024predicting], [bekannte Nulleffekte in die Validierung],
    [Zielverfehlung], [Realismus ungleich Effektgenauigkeit], [@li2026statistical @liu2026humanstudy], [die berichtete Schätzgröße validieren],
  ),
  caption: [Validitätsbedrohungen LLM-basierter Simulation (Synthese nach dem Dossier der Lehrveranstaltung, ergänzt um die Lehrbuchquellen zur Prompt-Sensitivität).],
) <k04-tab-bedrohungen>

=== Ethik als Validitätsfrage

Drei ethische Probleme hängen direkt an der Messperspektive. Digitale Zwillinge auf Basis von Interviews bergen Risiken der Re-Identifikation, auch mit Pseudonymen @park2024llm; ein Policy Brief empfiehlt Monitoring und Einwilligungsmechanismen @stanfordhai2025simulating. Fehldarstellung und Abflachung schaden den dargestellten Gruppen, das ist konsequenzielle Validität @wang2025large. Und dieselbe Fähigkeit, die Überzeugungseffekte vorhersagt, sagte auch die Wirkung impfskeptischer Inhalte vorher ($r = 0.49$, Preprint 2024): ein Dual-Use-Problem @hewitt2024predicting[Abb. 5].

#hoersaal([Soll eine Abschlussarbeit akzeptiert werden, die für ihre Simulation ein geschlossenes Modell verwendet, dessen Snapshot bald abgeschaltet wird?], [Ja, wenn die Arbeit das Problem ernst nimmt, und das heißt mehr als einen Satz in den Limitations. Erstens muss die Wahl begründet sein, etwa weil ein bestimmtes Leistungsniveau gebraucht wird @palmer2024using. Zweitens müssen Snapshot, Zugriffsdatum, Parameter, Prompts und alle Rohausgaben archiviert sein, damit die Analyse auch ohne Modell nachvollziehbar bleibt @haindl2027research. Drittens sollte ein offenes Modell als Vergleich mitlaufen, damit die zentralen Schlüsse nicht an einem verschwindenden Artefakt hängen. Ohne diese drei Punkte ist die Arbeit nach der Abschaltung nicht mehr überprüfbar, und eine nicht überprüfbare Arbeit erfüllt das Grundkriterium empirischer Forschung nicht.])

#hoersaal([Ist das alles nicht übertrieben vorsichtig? Bei menschlichen Stichproben haben wir doch auch Messfehler.], [Der Vergleich ist berechtigt, und die Messperspektive behandelt beide gleich. Der Unterschied liegt in der Art der Fehler. Menschliche Stichproben haben Stichprobenfehler, die mit der Fallzahl schrumpfen, und gut erforschte systematische Fehler (Nonresponse, Fragereihenfolge), für die es Korrekturverfahren gibt. LLM-Instrumente haben systematische Fehler, die mit der Zahl der synthetischen Befragten nicht schrumpfen (Abflachung, Stereotypisierung, Hyper-Genauigkeit), deren Richtung je nach Modell wechselt (GPT-5.1 extremer, Opus moderater @chapekis2026can) und die sich ohne Ankündigung ändern können (Drift). Deshalb braucht jede Studie eine eigene menschliche Validierung, statt sich auf eine allgemeine Kalibrierung zu verlassen.])

== Ersatz, Ergänzung oder keines von beiden? <k04-debatte>

Die Debatte, ob LLMs menschliche Teilnehmende ersetzen können, hat zwei Paare von Positionspapieren, die du kennen solltest, und eine evidenzbasierte Mittelposition.

Das erste Paar: Dillion et al. argumentierten 2023, dass LLMs für Pilotierung von Items, Hypothesengenerierung und als zusätzliche Evidenz nützlich sind und Teilnehmende ergänzen, nicht ersetzen sollen; am besten passen sie für Urteile, die von expliziten Merkmalen der Situation abhängen, schlechter für konkurrierende Intuitionen und Verhalten; sie bilden westliche, englischsprachige Menschen am besten ab und neigen dazu, Diversität in einen Durchschnitt zu kollabieren; LLM-Daten seien als kleine Bayes'sche Aktualisierung von Vorannahmen zu behandeln @dillion2023can. Harding et al. antworteten, dass keine der vorgeschlagenen Verwendungen Menschen tatsächlich ersetzt oder ohne sie auskommt: Modelle sind schlechte Stellvertreter für menschliche Verständnisschwierigkeiten beim Pilotieren, überraschende Modellausgaben verlangen bestätigende Studien mit Menschen, weil sie Prompt- oder Trainingsartefakte sein können, und moralische Ansichten ändern sich, während Modelle einen Schnappschuss festhalten @harding2024ai.

Das zweite Paar ist strukturierter. Anthis et al. halten LLM-Sozialsimulationen für eine vielversprechende Methode, wenn fünf lösbare Herausforderungen adressiert werden: Diversität, Bias, Sykophanz, Fremdheit (_alienness_) und Generalisierung; sie sehen Simulationen bereits als Unterstützung für Pilot- und explorative Studien und nennen als Richtungen kontextreiches Prompting (etwa auf Basis von Interviews), Fine-Tuning auf sozialwissenschaftlichen Daten, das Modell als Experten vorhersagen statt Rollen spielen zu lassen, und iterative konzeptuelle Modellierung @anthis2025position[Abschn. 3-4]. Lin benennt sechs Fehlschlüsse: Token-Vorhersage als menschliche Intelligenz, den Durchschnittsmenschen, Alignment als Erklärung, Anthropomorphismus, Essentialisierung von Identität und Substitution @lin2025six.

#figure(
  {
    set text(font: "Inter", size: 7.3pt, hyphenate: false)
    diagram(spacing: (6mm, 6mm), edge-stroke: 0.8pt + c-dark, mark-scale: 70%,
      fknoten((0, 0), [*Ersatz* \ synthetische Daten als \ alleinige Evidenz], col: c-red, filled: true, w: 36mm),
      fknoten((1, 0), [*Ergänzung* \ Pilot, Prior, Priorisierung, \ bestätigt durch Menschen], col: c-teal, filled: true, w: 40mm),
      fknoten((2, 0), [*Keines* \ jede Nutzung braucht \ ohnehin Menschen], col: c-grey, filled: true, w: 36mm),
      fknoten((0, 1), [von keiner hier besprochenen \ Studie gestützt; Pew: \ "kein adäquater Ersatz" @chapekis2026can], col: c-red, w: 36mm),
      fknoten((1, 1), [Dillion et al. @dillion2023can, \ Horton et al. @horton2023large, \ Anthis et al. @anthis2025position], col: c-teal, w: 40mm),
      fknoten((2, 1), [Harding et al. @harding2024ai, \ Lin @lin2025six], col: c-grey, w: 36mm),
      edge((0, 0), (0, 1), "-"), edge((1, 0), (1, 1), "-"), edge((2, 0), (2, 1), "-"),
    )
  },
  caption: [Drei Positionen in der Debatte mit ihren Hauptvertretern (Zuordnung als eigene Einordnung dieses Kapitels). Die Mittelposition (Ergänzung) ist die, die die Evidenz in diesem Kapitel stützt. Messeri und Crockett @messeri2024artificial liegen quer zu dieser Achse: Sie warnen vor Illusionen bei allen Verwendungen, ohne eine der drei Positionen zu vertreten.],
) <k04-fig-debatte>

Die Evidenz aus 2024-2026 erlaubt eine *bedingte* Pro-Position, die das Dossier der Lehrveranstaltung so zusammenfasst: Simulation funktioniert für (a) die Richtung aggregierter Behandlungseffekte in textbasierten US-Umfrageexperimenten (Preprint 2024: $r = 0.85$, 90 % richtige Richtung) @hewitt2024predicting, (b) individuelle Umfrageantworten bei Interview-Verankerung (0.83-0.86 der menschlichen Test-Retest-Konsistenz) @park2024llm, (c) Rating-Normen auf Itemebene über die API (Test-Retest 0.97-0.99) @mangiaterra2025can und (d) Meinungsverteilungen von Gruppen und neue Bedingungen bekannter Experimente nach Fine-Tuning auf menschlichen Daten @suh2025language @kolluri2025finetuning. Gemeinsam sind ein aggregiertes Ziel, Abdeckung durch menschliche Trainings- oder Validierungsdaten und Evaluation auf zurückgehaltenen menschlichen Daten. Außerhalb dieser Bedingungen bleiben die Fehler: Interaktionseffekte, Feldexperimente, Nulleffekte und neue Items ohne Kalibrierungsdaten @hewitt2024predicting @cui2024can @chapekis2026can.

Daraus folgt die Mittelposition, die du in Gutachten und Betreuung vertreten kannst: LLM-Ausgaben als Prior oder Pilot nutzen, nie als alleinige Quelle eines berichteten Effekts, und auf der Ebene des Anspruchs validieren (Mittelwert, Varianz, Zusammenhang, Effekt, Heterogenität). Statistische Verfahren, die eine kleine menschliche Stichprobe mit vielen LLM-Vorhersagen kombinieren und dabei gültige Konfidenzintervalle liefern, sind Thema von Kapitel 6.

#hoersaal([Wann ist eine demografische Persona eine unzulässige Essentialisierung und wann einfach die einzige verfügbare Information?], [Eine Persona essentialisiert, wenn die Studie implizit unterstellt, dass die Gruppenzugehörigkeit die Antwort bestimmt, und das Modell dann ein Stereotyp der Gruppe liefert. Wang et al. zeigen, dass die Antworten eher Außengruppen-Bildern entsprechen als dem, was Mitglieder sagen @wang2025large; Lin zählt die Essentialisierung von Identität zu den sechs Fehlschlüssen @lin2025six. Zulässig ist eine demografische Konditionierung, wenn sie als Messmodell offengelegt und geprüft wird: Wie groß ist die Streuung innerhalb der Gruppe im Vergleich zu Menschen? Stimmen Gruppenlücken? Ist das Thema überhaupt demografisch vorhersagbar? Verasight fand, dass Imputation bei polarisierten Themen mit starken demografischen Korrelaten am besten und bei persönlichem Verhalten am schlechtesten funktionierte @morris2026can. Wenn mehr Information verfügbar ist, etwa ein Interview, ist sie der Demografie klar überlegen @park2024llm.])

== Fallstudie: Ein Validitätsargument für eine Masterarbeit <k04-fall>

Die bisherigen Abschnitte haben die Bausteine einzeln vorgestellt: das Instrument nach @k04-eq-instrument, die Kette in sieben Gliedern, die Verteilungsmaße und die Befunde des Feldes. In der Betreuung begegnen sie dir aber nie einzeln, sondern als Exposé, in dem jemand "ein LLM als simulierte Befragte" einsetzen will. Dieser Abschnitt spielt deshalb einen solchen Fall vollständig durch, vom Anspruch bis zur Entscheidung, und verwendet dafür durchgehend die Daten aus dem Notebook `notebooks/04_silicon_sampling_validity.ipynb`. Die Daten sind synthetisch und ihre Verzerrungen sind explizite Parameter, die Muster aus der Literatur nachbilden (Gruppenlücke x1.6, Streuung x0.4); sie sind keine Schätzung für ein reales Modell. Gerade das macht sie für eine Fallstudie geeignet: Du weißt, was "wahr" ist, und kannst prüfen, ob das Validitätsargument den eingebauten Fehler findet. Alle Zahlen dieses Abschnitts, die nicht direkt in der Notebook-Ausgabe stehen, sind eigene Nachrechnungen mit python3 auf denselben Daten (Seed 2027) und als solche gekennzeichnet.

=== Der Fall

Eine Studierende im Master Data Intelligence plant eine Arbeit über die Akzeptanz von Mobilitätsmaßnahmen in einer mittelgroßen europäischen Stadt. Ihr Fragebogen hat 12 Likert-Items mit fünf Stufen (von mehr geschützten Radwegen bis zur Citymaut zur Stoßzeit), ihre zentrale Gruppierung sind vier Mobilitätstypen: Radfahrende, Autopendelnde, ÖV-Nutzende und Personen im Homeoffice. Das Exposé sieht ein Silicon Sample vor, und zwar für drei verschiedene Zwecke, die im Text ineinanderlaufen:

+ *K1, Pilot:* Die synthetischen Antworten sollen zeigen, welche Items streuen und welche Items vermutlich Boden- oder Deckeneffekte haben, bevor die echte Befragung startet.
+ *K2, Planung:* Aus dem Silicon Sample sollen die Gruppenunterschiede geschätzt werden, mit denen die Fallzahl der echten Befragung geplant wird.
+ *K3, Ersatz:* Für die schwer erreichbare Gruppe der Autopendelnden sollen synthetische Befragte einen Teil der fehlenden menschlichen Antworten ersetzen.

Die erste Aufgabe in der Betreuung ist, diese drei Ansprüche zu trennen. Messick hat Validierung als Untersuchung der Bedeutung von Testwerten gefasst @messick1995validity; das Dossier der Lehrveranstaltung stützt die inhaltliche Ausarbeitung dieser Sicht auf Jacobs und Wallach sowie Wallach et al. @jacobs2021measurement @wallach2025position, und deren Aspekte verwenden wir hier als Gliederung. Die praktische Konsequenz ist, und das ist eine Zuspitzung dieses Kapitels: Man validiert nicht "das Modell", sondern eine bestimmte Deutung seiner Werte für einen bestimmten Zweck. K1 deutet Itemverteilungen, K2 deutet Gruppenunterschiede, K3 deutet einzelne Antworten und alles, was später aus ihnen berechnet wird. Ein und dasselbe Instrument kann für K1 tragfähig und für K3 untauglich sein, und genau das wird die Fallstudie zeigen.

#merke[Formuliere am Anfang jedes Validitätsarguments den Anspruch als Satz der Form "Die Werte $X$ dürfen als $Y$ gedeutet werden, um $Z$ zu tun". Erst dieser Satz legt fest, auf welcher Ebene (Verteilung, Streuung, Zusammenhang, Effekt, Einzelantwort) Belege nötig sind @bisbee2024synthetic @li2026statistical.]

=== Die sieben Glieder, Schritt für Schritt

Wir gehen die Kette aus @k04-mess Glied für Glied durch. Für jedes Glied steht zuerst die Frage, dann die Evidenzquelle, mit der die Masterarbeit sie beantworten kann, dann das Ergebnis auf den Notebook-Daten.

*Glied 1: Konzept.* Das Hintergrundkonzept ist die Akzeptanz von Mobilitätsmaßnahmen in der Stadtbevölkerung; systematisiert wird es durch die 12 Items, die fünfstufige Skala und die Zielpopulation der erwachsenen Wohnbevölkerung, gegliedert nach Mobilitätstyp. Die Evidenzquelle ist das Exposé selbst, ergänzt um eine Expertenprüfung der Items auf Inhaltsvalidität, wie sie das Lehrbuch für Konstruktvalidität vorsieht @haindl2027research. Für das LLM-Instrument kommt eine Frage hinzu, die bei menschlichen Befragten nicht gestellt wird: Wer genau ist die simulierte Population? Eine Persona aus Mobilitätstyp und Alter ist ein sehr dünnes Profil; das Notebook verwendet genau diese beiden Merkmale, und die Literatur zeigt, dass Demografie allein deutlich schlechter vorhersagt als reichere Information wie ein Interview @park2024llm. Das Glied hält, wenn die drei Ansprüche getrennt formuliert sind.

*Glied 2: Instrument.* Festzulegen sind Snapshot, Persona-Vorlage, Decoding und Parser. Die Persona-Vorlage des Notebooks nennt Alter, Wohnort und Mobilitätstyp und verlangt eine einzelne Zahl von 1 bis 5; der Parser nimmt die erste Ziffer zwischen 1 und 5 und fällt sonst auf die Mittelkategorie 3 zurück, mit dem ausdrücklichen Hinweis, diese Fälle in einer echten Studie zu zählen. Diese Rückfallregel ist ein gutes Beispiel für eine Instrumententscheidung mit inhaltlicher Wirkung: Jede Verweigerung wird zu einer neutralen Meinung, und eine hohe Verweigerungsquote erzeugt künstliche Zentraltendenz. Evidenzquelle ist die Instrumentenkarte aus @k04-bericht mit dem Anteil der Rückfälle als eigenem Feld.

*Glied 3: Reliabilität.* Geprüft wird über die drei Achsen aus @k04-mess: zwei Sitzungen pro Konfiguration, zwei inhaltlich gleichwertige Persona-Vorlagen und, bei einem geschlossenen Modell, ein Wiederholungslauf einige Wochen später. Als Vergleichsmaßstab dienen die Werte von Mangiaterra et al., 0.97 bis 0.99 über die API und 0.66 bis 0.91 über die Chat-Oberfläche @mangiaterra2025can[Tab. 3]. Auf den Notebook-Daten lässt sich dieses Glied nicht prüfen, weil das simulierte Instrument nur einmal läuft; im Argument bleibt es deshalb ausdrücklich *offen*. Das ist kein Schönheitsfehler: Nach @k04-eq-atten begrenzt eine niedrige Reliabilität jede erreichbare Übereinstimmung, also auch alle folgenden Glieder.

*Glied 4: Konvergenz auf der Ebene des Anspruchs.* Für K1 ist die Ebene die Antwortverteilung je Item. Das mittlere OpinionQA-Alignment über die 12 Items beträgt 0.915, die mittlere JSD 0.067; das schwächste Item ist Item 10 (Citymaut zur Stoßzeit) mit 0.872 bzw. 0.166 (Notebook-Ausgabe). Ein Bootstrap über die 1000 Befragten (2000 Ziehungen, eigene Rechnung) ergibt für das mittlere Alignment ein 95 %-Intervall von 0.911 bis 0.919. Was heißt "0.915"? Ohne Bezugspunkt nichts. Der richtige Bezugspunkt ist die Übereinstimmung zweier menschlicher Stichproben aus derselben Population, also die Stichprobenschranke, wie sie Suh et al. für ihre Distanzmaße berichten @suh2025language[Tab. 1]. Teilt man die 1000 Menschen zufällig in zwei Hälften, liegt das mittlere Alignment der Hälften bei 0.977, zwischen erster und zweiter Welle derselben Personen bei 0.991 (eigene Rechnung). Das Silicon Sample liegt also klar und mit engem Intervall unterhalb dessen, was zwei menschliche Stichproben erreichen. Für K1 genügt das trotzdem, sofern das Ziel nur ist, grob streuende von nicht streuenden Items zu unterscheiden; die Korrelation der Itemmittelwerte beträgt $r = 0.870$, die mittlere absolute Abweichung der Itemmittelwerte 0.18 Skalenpunkte, maximal 0.42 bei Item 2 (eigene Rechnung).

*Glied 5: Struktur, Diskriminanz und Hypothesen.* Für K2 und K3 reichen Itemverteilungen nicht. Hier zählen die Streuung innerhalb der Gruppen, die Gruppenunterschiede und die Koeffizienten. Die Standardabweichung des Einstellungsindex (Mittel der 12 Items) liegt im Silicon Sample in allen vier Gruppen bei 0.40 bis 0.43 der menschlichen, die größte Gruppenlücke beträgt 1.08 statt 0.69 Skalenpunkte (Notebook-Ausgabe), ist also um den Faktor 1.56 übertrieben (eigene Rechnung). Die Rangfolge der vier Gruppenmittel stimmt dabei exakt (eigene Rechnung), was das Muster typisch macht: richtige Richtung, falsche Größe, falsche Sicherheit. In der Regression des Index auf Gruppe und Alter schließen die 95 %-Intervalle des Silicon Samples für drei der vier Steigungskoeffizienten die menschliche Schätzung aus, ohne Vorzeichenwechsel (Notebook-Ausgabe). Auf Individualebene reproduzieren die Personas die Antworten der jeweiligen Person zu 33.1 %, die Personen sich selbst zu 55.2 %, also $"NA" = 0.599$ nach @k04-eq-na (Notebook-Ausgabe); die Korrelation des Index zwischen Persona und Person beträgt 0.217, zwischen erster und zweiter Welle derselben Person 0.969 (eigene Rechnung). Dieses Glied reißt für K2 und K3.

*Glied 6: Kontamination.* Die Items sind für die Arbeit neu formuliert, und es gibt keine publizierten Ergebnisse dieser Befragung, die das Modell kennen könnte. Das schließt Memorisierung auf Itemebene aus, nicht aber, dass das Modell die öffentliche Debatte zu Citymaut oder Radwegen in anderen Städten kennt und auf diese Stadt überträgt. Evidenzquelle ist eine Begründung im Methodenteil; wo publizierte Vergleichsdaten vorliegen, kann man zusätzlich nach Veröffentlichungsdatum relativ zum Cutoff trennen, wie es Hewitt et al. im Preprint von 2024 getan haben @hewitt2024predicting. Das Glied hält für die Itemebene.

*Glied 7: Konsequenzen.* Wer wird durch die Darstellung beschädigt? Im Notebook wählt die Homeoffice-Gruppe bei Item 10 synthetisch zu 96 % die Option "stimme gar nicht zu", menschlich zu 51 % (eigene Rechnung, @k04-fig-fall-item10). Würde die Arbeit dieses Bild der Gruppe als Befund berichten, wäre das eine Fehldarstellung im Sinne von Wang et al. @wang2025large: eine Gruppe, die in Wirklichkeit gespalten ist, erscheint als geschlossener Block. Für K3 käme hinzu, dass gerade die schwer erreichbare Gruppe durch Stereotype ersetzt würde. Dieses Glied reißt für K3 und ist für K1 ein Warnhinweis.

#figure(
  {
    set text(font: "Inter", size: 7.2pt, hyphenate: false)
    let gl(pos, body, col) = fknoten(pos, body, col: col, w: 34mm)
    let ev(pos, body) = fknoten(pos, body, col: c-grey, w: 92mm)
    let lk = (paint: c-grey, thickness: 0.5pt, dash: "dashed")
    diagram(spacing: (5mm, 3.2mm), edge-stroke: 0.8pt + c-dark, mark-scale: 70%,
      gl((0, 0), [*1 Konzept* \ hält], c-green),
      gl((0, 1), [*2 Instrument* \ hält], c-green),
      gl((0, 2), [*3 Reliabilität* \ offen], c-yellow),
      gl((0, 3), [*4 Konvergenz* \ hält für K1], c-yellow),
      gl((0, 4), [*5 Struktur* \ reißt für K2, K3], c-red),
      gl((0, 5), [*6 Kontamination* \ hält (Itemebene)], c-green),
      gl((0, 6), [*7 Konsequenzen* \ reißt für K3], c-red),
      edge((0, 0), (0, 1), "-|>"), edge((0, 1), (0, 2), "-|>"), edge((0, 2), (0, 3), "-|>"),
      edge((0, 3), (0, 4), "-|>"), edge((0, 4), (0, 5), "-|>"), edge((0, 5), (0, 6), "-|>"),
      ev((1, 0), [Drei Ansprüche getrennt (Pilot, Planung, Ersatz); Expertenprüfung der Items; Persona nur Mobilitätstyp und Alter]),
      ev((1, 1), [Instrumentenkarte: Snapshot, Vorlage, Decoding, Parser; Rückfall auf Kategorie 3 wird gezählt]),
      ev((1, 2), [Zwei Sitzungen, zwei Vorlagen, Wiederholung nach Wochen; Maßstab API 0.97-0.99, Oberfläche 0.66-0.91]),
      ev((1, 3), [Alignment 0.915 (95 %-KI 0.911-0.919) gegen Mensch-Mensch 0.977; Itemmittel $r = 0.870$]),
      ev((1, 4), [SD-Verhältnis 0.40-0.43; Gruppenlücke x1.56; 3 von 4 Koeffizienten außerhalb; NA 0.599]),
      ev((1, 5), [Items neu formuliert, keine publizierten Ergebnisse; Themenwissen bleibt möglich]),
      ev((1, 6), [Item 10, Homeoffice: 96 % statt 51 % "stimme gar nicht zu"]),
      ..range(7).map(i => edge((0, i), (1, i), "-", stroke: lk)),
    )
  },
  caption: [Das Validitätsargument der Fallstudie als Kette. Links die Glieder aus @k04-mess mit Urteil (grün hält, gelb offen oder nur für einen Anspruch, rot reißt), rechts die Evidenz auf den synthetischen Notebook-Daten. Werte mit Ausnahme der Notebook-Ausgaben eigene Rechnung (python3, Seed 2027); Maßstab für Glied 3 nach Mangiaterra et al. @mangiaterra2025can.],
) <k04-fig-fall-kette>

=== Das Ergebnis: drei Ansprüche, drei Urteile

Aus der Kette folgt für die drei Ansprüche ein abgestuftes Urteil, das du so auch in ein Betreuungsgespräch mitnehmen kannst.

*K1 (Pilot) ist bedingt tragfähig.* Für die Frage, welche Items streuen, liefert das Silicon Sample brauchbare Hinweise, solange man die Population als Ganzes betrachtet und Glied 3 noch nachgeliefert wird. Die Bedingung ist wichtig, denn auf Gruppenebene sieht dasselbe Instrument deutlich schlechter aus (dazu gleich @k04-fig-fall-item10).

*K2 (Planung) ist nicht tragfähig.* Mit den synthetischen Gruppenunterschieden würde die Fallzahl für den Vergleich Radfahrende gegen Autopendelnde mit 9 statt 167 Personen pro Gruppe geplant (Notebook-Ausgabe, Abschnitt 5). Das ist genau der Mechanismus aus @k04-eq-power-faktor: komprimierte Streuung und übertriebene Lücke wirken in dieselbe Richtung.

*K3 (Ersatz) ist nicht tragfähig.* Normierte Genauigkeit 0.6, eine individuelle Indexkorrelation von 0.22 gegenüber 0.97 bei Wiederholung und stereotyp geschlossene Gruppen schließen aus, synthetische Antworten als Ersatz für fehlende Menschen in eine gemeinsame Analyse zu mischen. Wer die schwer erreichbare Gruppe dennoch stärken will, braucht ein Verfahren, das eine kleine menschliche Stichprobe mit vielen Vorhersagen kombiniert und dabei gültige Intervalle liefert; das ist Thema von Kapitel 6.

#praxis[Für Gutachten zu Abschlussarbeiten eignet sich ein einfacher Satz: "Das Silicon Sample ist für Zweck A validiert, für Zweck B nicht geprüft und für Zweck C widerlegt." Er zwingt dazu, die Zwecke zu trennen, und macht sichtbar, dass ein negatives Urteil für einen Zweck die Arbeit nicht entwertet.]

== Studiendesign: Silicon Sample gegen menschliche Stichprobe validieren <k04-design>

Die Fallstudie hat ein Validitätsargument auf vorhandenen Daten geprüft. In einer echten Arbeit müssen diese Daten erst erhoben werden, und das Design der Validierungsstudie entscheidet, welche Glieder sich überhaupt prüfen lassen. Dieser Abschnitt beschreibt ein vollständiges Design, das sich direkt aus dem Notebook ableitet und für eine Masterarbeit umsetzbar ist.

=== Bausteine des Designs

#figure(
  {
    set text(font: "Inter", size: 7.4pt, hyphenate: false)
    diagram(spacing: (7mm, 7mm), edge-stroke: 0.8pt + c-dark, mark-scale: 70%,
      fknoten((1, 0), [*Präregistrierung* \ Ansprüche, Ebenen, Kennzahlen, \ Toleranzen, Entscheidungsregel], col: c-violet, filled: true, w: 58mm),
      fknoten((0, 1), [*Menschliche Stichprobe* \ Welle 1: alle Befragten \ Welle 2 nach 2 Wochen: Teilstichprobe], col: c-blue, w: 50mm),
      fknoten((2, 1), [*Silicon Sample* \ eine Persona je Befragter (gleiche Merkmale) \ 2 Vorlagen x 2 Sitzungen, offenes Vergleichsmodell], col: c-accent, w: 54mm),
      fknoten((0, 2), [*Referenzschranken* \ Split-Half, Test-Retest], col: c-blue, w: 50mm),
      fknoten((2, 2), [*Reliabilität des Instruments* \ Sitzungen, Vorlagen, Zeit], col: c-accent, w: 54mm),
      fknoten((1, 3), [*Kennzahlen auf sechs Ebenen* \ Item, Aggregat, Streuung und Subgruppen, \ Individuum, Zusammenhang, Effekt], col: c-teal, filled: true, w: 74mm),
      fknoten((1, 4), [*Divergenzanalyse* \ wo, für wen und in welche Richtung weicht das Instrument ab?], col: c-teal, w: 62mm),
      fknoten((1, 5), [*Urteil je Anspruch* \ validiert, nicht geprüft oder widerlegt], col: c-dark, filled: true, w: 58mm),
      edge((1, 0), (0, 1), "-|>"), edge((1, 0), (2, 1), "-|>"),
      edge((0, 1), (0, 2), "-|>"), edge((2, 1), (2, 2), "-|>"),
      edge((0, 1), (2, 1), "<|-|>", stroke: (paint: c-grey, thickness: 0.7pt, dash: "dashed"), label: text(fill: c-grey.darken(20%))[gepaart], label-side: left),
      edge((0, 2), (1, 3), "-|>"), edge((2, 2), (1, 3), "-|>"),
      edge((1, 3), (1, 4), "-|>"), edge((1, 4), (1, 5), "-|>"),
    )
  },
  caption: [Design einer Validierungsstudie für ein Silicon Sample (eigene Zusammenstellung nach dem Notebook der Lehrveranstaltung, Park et al. @park2024llm für die Retest-Welle und Suh et al. @suh2025language für die menschliche Stichprobenschranke). Die Paarung erlaubt Vergleiche auf Individualebene, die Referenzschranken machen die Kennzahlen interpretierbar.],
) <k04-fig-design>

@k04-fig-design zeigt die Bausteine. Vier Entscheidungen verdienen eine Begründung.

*Gepaarte Struktur.* Jede menschliche Person bekommt eine Persona mit denselben Merkmalen, wie im Notebook. Nur so lassen sich Einzelantworten vergleichen (normierte Genauigkeit), und nur so lassen sich Unterschiede zwischen Silicon Sample und Menschen eindeutig dem Instrument zuschreiben statt einer anderen Zusammensetzung der Stichprobe.

*Retest-Welle.* Eine Teilstichprobe beantwortet den Fragebogen nach zwei Wochen erneut. Das liefert den Nenner von @k04-eq-na und damit die Obergrenze, an der jedes Instrument zu messen ist @park2024llm[Results]. Ohne Retest ist "33 % Übereinstimmung" nicht interpretierbar.

*Referenzschranken.* Jede Kennzahl wird neben eine menschliche Vergleichsgröße gestellt: Für Verteilungsmaße ist das die Übereinstimmung zweier zufälliger Hälften der menschlichen Stichprobe, für Individualmaße die Retest-Übereinstimmung. Das ist dieselbe Logik wie die menschliche Stichprobenschranke von Suh et al. (Wasserstein-Distanz 0.031 für die menschliche Wiederholung gegenüber 0.094 bis 0.106 nach Fine-Tuning auf zurückgehaltenen Wellen) @suh2025language[Tab. 1, Abschn. 4.2]: Mehr Übereinstimmung, als zwei menschliche Stichproben untereinander erreichen, kann man von keinem Instrument erwarten, und es muss daran gemessen werden, wie weit es darunter bleibt.

*Präregistrierung.* Ansprüche, Ebenen, Kennzahlen, Toleranzen und Entscheidungsregel werden vor der Erhebung festgelegt und mit Zeitstempel abgelegt. Das Lehrbuch begründet das für Studien mit KI-Systemen gerade mit der Vielzahl verfügbarer Kennzahlen und Konfigurationen: Was erst nach Blick auf die Daten ausgewählt wird, ist eine explorative Hypothese und kein konfirmatorischer Test @haindl2027research. Für Silicon Samples ist das besonders wichtig, weil die Wahl der Kennzahl das Urteil bestimmt: Mit dem Alignment allein besteht das Notebook-Instrument, mit dem SD-Verhältnis fällt es durch. Dazu gehört auch, dass Prompt-Varianten, wenn überhaupt, auf einem anderen Teil der Daten ausgewählt werden als auf dem, auf dem validiert wird @li2026statistical.

=== Kennzahlen auf sechs Ebenen

@k04-tab-kennzahlen ordnet die Kennzahlen den Ebenen zu, nennt die menschliche Referenz und die Werte aus dem Notebook. Die Reihenfolge entspricht der dreistufigen Evaluation von Bisbee et al. (Mittelwerte, dann Streuungen und Gruppenlücken, dann Koeffizienten) @bisbee2024synthetic, erweitert um die Individual- und die Effektebene.

#figure(
  table(columns: (0.9fr, 1.35fr, 1.05fr, 1.5fr),
    [Ebene], [Kennzahl], [Menschliche Referenz], [Notebook-Wert],
    [Item], [Alignment @k04-eq-align, JSD @k04-eq-jsd je Item], [Split-Half 0.977, Retest 0.991 #super[e]], [Mittel 0.915 (KI 0.911-0.919 #super[e]), JSD 0.067; Minimum Item 10: 0.872 bzw. 0.166],
    [Aggregat], [Korrelation der Itemmittel; Kalibrierungssteigung @k04-eq-slope], [ideal 1 bzw. 1], [$r = 0.870$; Steigung 1.232 (populäre Optionen übertrieben)],
    [Streuung und Subgruppen], [Entropieverhältnis gesamt und je Gruppe; SD-Verhältnis; Verhältnis der Gruppenlücken], [ideal 1], [Entropie 0.843 gesamt, 0.498 in Gruppen #super[e]; SD 0.40-0.43; Lücke 1.08 vs. 0.69, also x1.56 #super[e]],
    [Individuum], [Normierte Genauigkeit @k04-eq-na; Korrelation des Index], [Retest 55.2 % bzw. $r = 0.969$ #super[e]], [33.1 %, NA 0.599; $r = 0.217$ #super[e]],
    [Zusammenhang], [Anteil Koeffizienten, deren 95 %-KI die menschliche Schätzung ausschließt; Vorzeichenwechsel], [erwartet nahe 0], [3 von 4 (0.75); kein Vorzeichenwechsel],
    [Effekt], [ATE-Fehler je Konfiguration, nicht MAE], [ATE der Menschen 0.252], [kleinster MAE (Few-Shot 0.831) mit größtem ATE-Fehler 0.566; Zero-Shot 0.016],
  ),
  caption: [Kennzahlen einer Validierungsstudie nach Ebene, mit menschlicher Referenz und den Werten aus dem Notebook der Lehrveranstaltung (synthetische Daten). Mit #super[e] markierte Werte sind eigene Nachrechnungen (python3, Seed 2027), alle übrigen stehen in der Notebook-Ausgabe. Die Reihenfolge folgt Bisbee et al. @bisbee2024synthetic, die Effektebene Li und Ji @li2026statistical.],
) <k04-tab-kennzahlen>

Zwei Kennzahlen der Tabelle sind neu gegenüber @k04-vert und verdienen eine kurze Herleitung. Das *Entropieverhältnis* ist $H_"norm" (Q) \/ H_"norm" (P)$ mit der normierten Entropie aus @k04-vert; es ist 1, wenn das Modell genauso breit streut wie die Menschen, und fällt gegen 0, wenn es auf eine Option kollabiert. Das *Verhältnis der Gruppenlücken* ist die größte Differenz der Gruppenmittel im Silicon Sample geteilt durch die menschliche; Werte über 1 bedeuten übertriebene Unterschiede, wie Bisbee et al. sie bei Parteianhängern fanden @bisbee2024synthetic. Beide Verhältnisse sind dimensionslos, sodass man sie in einem gemeinsamen Profil darstellen kann.

=== Rechenbeispiel: Item- gegen Subgruppenebene

Die wichtigste Lehre der Tabelle steckt in der Zeile "Streuung und Subgruppen": Das Entropieverhältnis über die ganze Population beträgt 0.843, innerhalb der Gruppen im Mittel nur 0.498 (eigene Rechnung). Wie kann dasselbe Instrument auf der höheren Ebene so viel besser aussehen? Das extreme Item 10 zeigt den Mechanismus.

#beispiel(titel: [Item 10: eine gespaltene Stadt, zwei Kollapse])[
  Bei Item 10 (Citymaut zur Stoßzeit) ist die menschliche Gesamtverteilung nahezu gleichverteilt, $P approx (0.19, 0.19, 0.19, 0.20, 0.24)$, mit normierter Entropie 0.998. Dahinter steckt keine Unentschlossenheit, sondern Spaltung: Radfahrende und Autopendelnde stimmen überwiegend zu (Mittel 4.23 bzw. 4.17), ÖV-Nutzende und Homeoffice lehnen überwiegend ab (2.31 bzw. 1.71). Das Silicon Sample übertreibt die Gruppenlücke und komprimiert die Streuung; innerhalb der Gruppen kollabiert es auf eine Option: 98 % und 95 % "stimme voll zu" bei Radfahrenden und Autopendelnden, 96 % "stimme gar nicht zu" im Homeoffice. Gemittelt über die Gruppen ergibt das die bimodale Gesamtverteilung $Q approx (0.28, 0.20, 0.02, 0.02, 0.48)$ mit normierter Entropie 0.723 und einem Alignment von 0.872.

  Nun die Rechnung auf beiden Ebenen (eigene Rechnung, python3). Auf Populationsebene beträgt das Entropieverhältnis $0.723 \/ 0.998 = 0.725$. Innerhalb der Gruppen liegen die Verhältnisse bei 0.087 (Radfahrende), 0.161 (Autopendelnde), 0.484 (ÖV) und 0.150 (Homeoffice), im Mittel bei 0.220. Das Alignment je Gruppe liegt zwischen 0.804 und 0.863. Die Mischung der Gruppen erzeugt auf der höheren Ebene Streuung, die in keiner einzelnen Gruppe vorhanden ist: Die Breite der Gesamtverteilung des Modells kommt aus der übertriebenen Lücke zwischen den Gruppen, nicht aus Vielfalt innerhalb der Gruppen. Zwei Fehler (zu große Lücke, zu kleine Streuung) kompensieren sich auf der Populationsebene teilweise und werden erst auf der Gruppenebene sichtbar.
]

#let k04-panel(x0, titel, ph, pl, unter) = {
  import cetz.draw: *
  let w = 0.2
  let hm = 2.0
  line((x0, 0), (x0 + 2.45, 0), stroke: 0.5pt + c-grey)
  for k in range(5) {
    let xc = x0 + 0.3 + k * 0.46
    rect((xc - w, 0), (xc, ph.at(k) * hm), fill: c-blue, stroke: none)
    rect((xc, 0), (xc + w, pl.at(k) * hm), fill: c-accent, stroke: none)
    content((xc, -0.2), k04-t(str(k + 1), size: 6.3pt))
  }
  content((x0 + 1.22, hm + 0.32), k04-t(titel, size: 7pt, weight: "bold"))
  content((x0 + 1.22, -0.55), k04-t(unter, size: 6.3pt, fill: c-dark))
}

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let hm = 2.0
    line((-0.1, 0), (-0.1, hm), stroke: 0.5pt + c-grey)
    for v in (0, 0.5, 1.0) {
      line((-0.16, v * hm), (-0.1, v * hm), stroke: 0.5pt + c-grey)
      content((-0.22, v * hm), anchor: "east", k04-t(str(v), size: 6.3pt))
    }
    k04-panel(0, [Population], (0.19, 0.19, 0.19, 0.20, 0.24), (0.28, 0.20, 0.02, 0.02, 0.48), [H-Verh. 0.725, A 0.872])
    k04-panel(2.75, [Radfahrende], (0.00, 0.03, 0.16, 0.36, 0.45), (0.00, 0.00, 0.00, 0.02, 0.98), [H-Verh. 0.087, A 0.812])
    k04-panel(5.5, [Autopendelnde], (0.00, 0.04, 0.19, 0.31, 0.46), (0.00, 0.00, 0.00, 0.05, 0.95), [H-Verh. 0.161, A 0.804])
    k04-panel(8.25, [ÖV-Nutzende], (0.23, 0.37, 0.28, 0.09, 0.03), (0.17, 0.77, 0.06, 0.00, 0.00), [H-Verh. 0.484, A 0.863])
    k04-panel(11.0, [Homeoffice], (0.51, 0.32, 0.12, 0.04, 0.00), (0.96, 0.04, 0.00, 0.00, 0.00), [H-Verh. 0.150, A 0.833])
    rect((3.6, -1.15), (3.85, -0.95), fill: c-blue, stroke: none)
    content((3.95, -1.05), anchor: "west", k04-t([Menschen]))
    rect((5.6, -1.15), (5.85, -0.95), fill: c-accent, stroke: none)
    content((5.95, -1.05), anchor: "west", k04-t([Silicon Sample]))
    content((7.9, -1.05), anchor: "west", k04-t([Antwortoption 1 = stimme gar nicht zu, 5 = stimme voll zu]))
  }),
  caption: [Item 10 des Notebooks (Citymaut zur Stoßzeit) auf Populations- und Gruppenebene, Antwortanteile auf zwei Stellen gerundet (eigene Rechnung auf den Notebook-Daten, Seed 2027). Unter jedem Feld das Entropieverhältnis (Modell zu Mensch) und das Alignment. Die bimodale Gesamtverteilung des Modells entsteht aus vier fast vollständigen Kollapsen.],
) <k04-fig-fall-item10>

Für die Masterarbeit heißt das konkret: Die Kennzahlen müssen auf der Ebene der Gruppen berechnet werden, über die die Arbeit Aussagen macht, und die Populationswerte sind höchstens eine Zusammenfassung. Das ist dieselbe Logik, die das Lehrbuch für Fehleranalysen allgemein formuliert: Ein aggregierter Wert mittelt genau die Unterschiede weg, die man braucht, um zu verstehen, wo ein System versagt @haindl2027research.

=== Divergenzanalyse: wo, für wen, in welche Richtung

Eine Validierungsstudie sollte nicht mit einem Urteil enden, sondern mit einer Landkarte der Abweichungen. Drei Fragen strukturieren sie. *Wo* weicht das Instrument ab, also bei welchen Items und Optionen? Im Notebook liegen die größten Formabweichungen bei Item 10 und, mit Abstand, Item 9 (JSD 0.166 und 0.093), die größte Lageabweichung bei Item 2 mit 0.42 Skalenpunkten (eigene Rechnung). *Für wen* weicht es ab? Die Gruppenwerte des Alignments über alle Items liegen eng beieinander (0.839 bis 0.859, eigene Rechnung), die Abflachung betrifft also alle vier Gruppen etwa gleich; in realen Daten muss das nicht so sein, und die Literatur zeigt besonders große Abweichungen für bestimmte Identitätsgruppen @wang2025large und Subgruppenlücken selbst bei Interview-Agenten @park2024llm[Abb. 3]. *In welche Richtung* weicht es ab? Die Kalibrierungssteigung von 1.232 zeigt, dass das Instrument populäre Optionen übertreibt und seltene unterdrückt; eine Steigung unter 1 wie die 0.82 bei Morris und Leff würde das Gegenteil bedeuten @morris2026can. Die Richtung ist für die Deutung entscheidend, weil sie angibt, ob synthetische Ergebnisse eher zu extrem oder zu zahm sind.

@k04-fig-fall-profil fasst die Kennzahlen als Profil zusammen. Jede Kennzahl ist als Verhältnis zur menschlichen Referenz dargestellt, sodass 1 perfekte Übereinstimmung bedeutet. Das graue Band ist eine *Toleranz, die in der Präregistrierung festzulegen wäre*; hier ist beispielhaft 0.8 bis 1.25 gewählt, symmetrisch auf der logarithmischen Skala ($0.8 = 1\/1.25$), weil eine Abweichung um denselben Faktor nach unten und nach oben gleich schwer wiegen soll. Die Toleranz ist eine Festlegung dieses Kapitels und keine Norm der Literatur; welche Abweichung tolerierbar ist, hängt vom Anspruch ab.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let s = 3.6
    let rows = (
      ([Alignment (rel. zu Split-Half)], 0.937, c-blue),
      ([Korrelation der Itemmittel], 0.870, c-blue),
      ([Entropieverhältnis gesamt], 0.843, c-blue),
      ([Entropieverhältnis in Gruppen], 0.498, c-accent),
      ([SD-Verhältnis des Index], 0.413, c-accent),
      ([Verhältnis der Gruppenlücken], 1.562, c-accent),
      ([Koeffizient Homeoffice], 1.393, c-violet),
      ([Koeffizient Autopendelnde], 1.825, c-violet),
      ([Koeffizient ÖV-Nutzende], 2.729, c-violet),
      ([Normierte Genauigkeit], 0.599, c-teal),
      ([Indexkorrelation (rel. zu Retest)], 0.224, c-teal),
    )
    let n = rows.len()
    let top = 0.3
    let bot = -(n - 1) * 0.42 - 0.3
    rect((0.8 * s, bot), (1.25 * s, top), fill: c-grey.lighten(80%), stroke: none)
    line((1 * s, bot), (1 * s, top), stroke: (paint: c-dark, thickness: 0.7pt, dash: "dashed"))
    line((0, bot), (3 * s, bot), stroke: 0.5pt + c-grey)
    for v in (0, 0.5, 1, 1.5, 2, 2.5, 3) {
      line((v * s, bot), (v * s, bot - 0.08), stroke: 0.5pt + c-grey)
      content((v * s, bot - 0.28), k04-t(str(v), size: 6.3pt))
    }
    content((1.5 * s, bot - 0.62), k04-t([Verhältnis zur menschlichen Referenz (1 = Übereinstimmung)], size: 6.8pt))
    for (i, (lab, v, col)) in rows.enumerate() {
      let lab2 = str(calc.round(v, digits: 3))
      let y = -i * 0.42
      content((-0.15, y), anchor: "east", k04-t(lab, size: 7pt))
      line((0, y), (3 * s, y), stroke: (paint: luma(225), thickness: 0.4pt))
      line((1 * s, y), (v * s, y), stroke: (paint: col, thickness: 1.2pt))
      circle((v * s, y), radius: 0.08, fill: col, stroke: none)
      if v < 1 { content((v * s - 0.15, y + 0.15), anchor: "east", k04-t(lab2, size: 6.3pt, fill: col.darken(15%))) } else { content((v * s + 0.15, y + 0.15), anchor: "west", k04-t(lab2, size: 6.3pt, fill: col.darken(15%))) }
    }
  }),
  caption: [Validierungsprofil des Notebook-Instruments. Blau Verteilungs- und Aggregatebene, orange Streuung und Subgruppen, violett Koeffizienten (Silicon Sample geteilt durch Mensch), türkis Individualebene. Graues Band: beispielhafte präregistrierte Toleranz 0.8 bis 1.25 (Festlegung dieses Kapitels). Werte aus der Notebook-Ausgabe bzw. eigene Rechnung (python3, Seed 2027).],
) <k04-fig-fall-profil>

Das Profil zeigt das Urteil der Fallstudie auf einen Blick: Die blauen Kennzahlen liegen im Band oder knapp darunter, alle übrigen außerhalb. Wer nur die oberste Zeile berichtet, berichtet eine gute Nachricht über ein Instrument, das auf jeder tieferen Ebene durchfällt.

=== Wie groß muss die menschliche Stichprobe sein?

Eine naheliegende Sparidee lautet: Wenn das Silicon Sample ohnehin nur geprüft werden soll, reicht eine kleine menschliche Stichprobe. Die Frage lässt sich mit derselben Mathematik beantworten wie die Fallzahlplanung in @k04-vert. Angenommen, die Arbeit will erkennen, ob die synthetische Gruppenlücke von der menschlichen abweicht. Seien $D = Delta_"syn" - Delta$ diese Abweichung, $sigma_h$ und $sigma_s$ die Standardabweichungen in menschlicher und synthetischer Stichprobe und $n$ die Zahl der Personen pro Gruppe in beiden.

#satz(titel: [Fallzahl für den Nachweis einer Lückenabweichung])[
  Werden die Lücken in beiden Stichproben als Differenz zweier Gruppenmittel mit je $n$ Personen geschätzt und sind die Schätzfehler der beiden Stichproben unkorreliert, so braucht ein zweiseitiger Test auf $D != 0$ mit Niveau $alpha$ und Power $1 - beta$
  $ n = 2 (z_(1 - alpha\/2) + z_(1 - beta))^2 (sigma_h^2 + sigma_s^2) / D^2 $ <k04-eq-n-valid>
  Personen pro Gruppe.
]

#beweis[
  Die geschätzte Lücke einer Stichprobe ist eine Differenz zweier unabhängiger Mittel mit Varianz $2 sigma^2 \/ n$. Bei unkorrelierten Schätzfehlern addieren sich die Varianzen der beiden Lücken, also $"Var"(hat(D)) = 2 (sigma_h^2 + sigma_s^2) \/ n$. Die Normalapproximation des Tests verlangt wie bei @k04-eq-power $D \/ sqrt("Var"(hat(D))) = z_(1 - alpha\/2) + z_(1 - beta)$; Auflösen nach $n$ liefert @k04-eq-n-valid. Bei positiv korrelierten Schätzfehlern, wie sie durch die Paarung entstehen können, ist die Varianz kleiner; die Formel ist dann konservativ.
]

#beispiel(titel: [Validierungsstichprobe für die Notebook-Lücke])[
  Für den Vergleich Radfahrende gegen Autopendelnde beträgt die menschliche Lücke 0.269, die synthetische 0.491 (Notebook-Ausgabe), also $D = 0.222$. Die gepoolten Standardabweichungen der beiden Gruppen sind $sigma_h = 0.875$ und $sigma_s = 0.368$ (eigene Rechnung aus den Gruppen-SDs der Notebook-Ausgabe). Mit $2 (1.960 + 0.842)^2 = 15.70$ ergibt @k04-eq-n-valid
  $ n = 15.70 dot (0.875^2 + 0.368^2) / 0.222^2 = 15.70 dot 0.901 / 0.0493 approx 287 $
  Personen pro Gruppe (eigene Rechnung, python3). Mit 50 Personen pro Gruppe hätte der Test eine Power von 0.22, mit 100 von 0.38, mit den 250 des Notebooks von 0.74 (eigene Rechnung). Eine kleine Validierungsstichprobe findet die Übertreibung der Lücke also mit hoher Wahrscheinlichkeit nicht und würde ein fehlerhaftes Instrument "bestätigen". Bemerkenswert ist, dass $sigma_h$ den Bedarf dominiert: Die Präzision der Validierung hängt fast nur an der menschlichen Seite.
]

#fallstrick[Ein nicht signifikanter Unterschied zwischen Silicon Sample und Menschen ist kein Validitätsbeleg. Bei einer zu kleinen menschlichen Stichprobe ist er die erwartbare Folge geringer Power. Wer Übereinstimmung behaupten will, braucht eine vorab festgelegte Toleranz und ein Konfidenzintervall, das ganz innerhalb dieser Toleranz liegt, nicht ein $p > 0.05$.]

#hoersaal([Mich interessiert nur das Gesamtergebnis der Stadt. Warum soll ich die Kennzahlen trotzdem je Subgruppe rechnen?], [Weil die Gesamtkennzahl aus zwei Fehlern bestehen kann, die sich gegenseitig verdecken. Bei Item 10 im Notebook ist die menschliche Verteilung fast gleichverteilt, weil die Stadt gespalten ist; das Silicon Sample übertreibt die Spaltung und kollabiert innerhalb jeder Gruppe. Auf Populationsebene ergibt das ein Entropieverhältnis von 0.725 und ein Alignment von 0.872, innerhalb der Gruppen Entropieverhältnisse zwischen 0.087 und 0.484 (eigene Rechnung, @k04-fig-fall-item10). Selbst wenn die Arbeit nur über die Stadt berichtet, braucht sie die Gruppenebene, um zu wissen, _warum_ die Gesamtverteilung stimmt; ein Instrument, das aus den falschen Gründen richtig liegt, versagt beim nächsten Item mit anderer Gruppenstruktur. Dazu kommt die konsequenzielle Seite: Eine Gruppe, die als geschlossener Block erscheint, wird fehldargestellt @wang2025large.])

#hoersaal([Das Silicon Sample ist doch nur ein Pilot. Warum muss die menschliche Validierungsstichprobe dann so groß sein wie eine richtige Studie?], [Weil der Pilot nur dann etwas wert ist, wenn man weiß, auf welcher Ebene man ihm trauen darf, und dieses Wissen kommt ausschließlich aus der menschlichen Stichprobe. Nach @k04-eq-n-valid hängt der Bedarf fast nur an der menschlichen Streuung; für die Notebook-Lücke sind rund 287 Personen pro Gruppe nötig, mit 50 läge die Power bei 0.22 (eigene Rechnung). Es gibt zwei ehrliche Auswege. Entweder man beschränkt den Anspruch auf eine Ebene, die mit weniger Personen prüfbar ist, etwa grobe Itemverteilungen, und schreibt das so in die Arbeit. Oder man verwendet die menschliche Stichprobe nicht nur zur Prüfung, sondern kombiniert sie mit den Vorhersagen in einem Verfahren mit gültigen Intervallen; das ist Thema von Kapitel 6. Unehrlich wäre, eine kleine Stichprobe zu erheben und das Ausbleiben signifikanter Unterschiede als Bestätigung zu berichten.])

== Berichten: GUIDE-LLM und die Instrumentenkarte <k04-bericht>

Ein Validitätsargument nützt nur, wenn andere es prüfen können. Das Lehrbuch bringt es auf den Punkt: Für Studien mit KI-Systemen sind Modell und Version, Zugriffsdatum, vollständige Prompts und Systeminstruktionen, Decoding-Parameter wie Temperatur, Zahl der Wiederholungen samt Umgang mit ihrer Variabilität und, wo verfügbar, Seeds zu dokumentieren; ein Ergebnis, das nicht regeneriert werden kann, kann nicht verifiziert werden @haindl2027research. Für computationale Forschung allgemein nennt das Lehrbuch Code mit Dokumentation, Softwareversionen und Abhängigkeiten, Testdaten mit erwarteten Ausgaben, Containerisierung und Seeds für stochastische Prozesse @haindl2027research @Stodden2014.

Für die Verhaltenswissenschaften gibt es seit 2026 einen Konsensstandard. GUIDE-LLM entstand in zwei präregistrierten reaktiven Delphi-Runden: 68 Fachleute bewerteten 29 Kandidatenpunkte, danach stimmten 80 Fachleute ab; aufgenommen wurde, was mehr als zwei Drittel Zustimmung erhielt @feuerriegel2026reporting. Das Ergebnis sind 14 Kernpunkte in sieben Abschnitten und 8 optionale Punkte @feuerriegel2026reporting @guidellm2026checklist.

#figure(
  table(columns: (0.4fr, 1.1fr, 0.45fr, 2fr),
    [], [Abschnitt], [Punkte], [Inhalt (Kurzfassung)],
    [A], [Anwendungsbereich], [2], [wofür das LLM in der Studie verwendet wurde],
    [B], [Modell und System], [5], [Versionskennung, Zugriffsdatum, Zugangsweg, Temperatur, Seed und Zahl der Läufe, Fine-Tuning, Sitzungszustand],
    [C], [Prompts], [2], [exakte Prompts und Systeminstruktionen],
    [D], [Daten und Datenschutz], [1], [Umgang mit personenbezogenen Daten],
    [E], [Validierung], [2], [menschliche Validierung und Nachbearbeitung],
    [F], [Code], [1], [Verfügbarkeit des Codes],
    [G], [Interessenkonflikte], [1], [konkurrierende Interessen],
    [+], [optional], [8], [u. a. Begründung der Modellwahl, Trainingsdaten-Leakage, Bias-Risiko],
  ),
  caption: [Struktur der GUIDE-LLM-Checkliste: 14 Kernpunkte in sieben Abschnitten und 8 optionale Punkte @feuerriegel2026reporting @guidellm2026checklist (Stand: 11. November 2026).],
) <k04-tab-guide>

=== GUIDE-LLM angewandt auf die Fallstudie

Eine Checkliste wirkt erst, wenn man sie auf eine eigene Arbeit legt. @k04-tab-guide-fall übersetzt die sieben Abschnitte und die optionalen Punkte in das, was die Masterarbeit aus @k04-fall konkret berichten müsste, und ordnet jedem Abschnitt das Glied des Validitätsarguments zu, das ohne ihn nicht prüfbar ist. Die Inhalte der Abschnitte folgen der Kurzfassung in @k04-tab-guide @feuerriegel2026reporting @guidellm2026checklist; die Spalte zur Fallstudie ist eine Anwendung dieses Kapitels, nicht Teil der Checkliste.

#figure(
  table(columns: (0.95fr, 2.2fr, 0.9fr),
    [Abschnitt], [Was die Masterarbeit konkret berichtet], [Glied],
    [A Anwendungsbereich (2)], [Drei getrennte Zwecke: Pilot der Itemverteilungen (K1), Fallzahlplanung (K2), Ersatz fehlender Befragter (K3), je mit Urteil "validiert", "nicht geprüft" oder "widerlegt"], [1 Konzept],
    [B Modell und System (5)], [Versionskennung des Snapshots, Zugriffsdatum, Zugangsweg (API oder lokal, keine Chat-Oberfläche), Temperatur, Seed, zwei Sitzungen je Vorlage, kein Fine-Tuning, zustandslose Aufrufe ohne Sitzungsgedächtnis], [2 Instrument, 3 Reliabilität],
    [C Prompts (2)], [Beide Persona-Vorlagen im Wortlaut, Systeminstruktion, Parser-Regel samt Rückfall auf Kategorie 3 und dessen Häufigkeit], [2 Instrument],
    [D Daten und Datenschutz (1)], [Welche Merkmale der echten Befragten in die Personas fließen (hier nur Mobilitätstyp und Alter) und ob sie an einen externen Dienst übermittelt werden], [7 Konsequenzen],
    [E Validierung (2)], [Gepaarte menschliche Stichprobe, Retest-Welle, Referenzschranken, Kennzahlen auf allen sechs Ebenen aus @k04-tab-kennzahlen, präregistrierte Toleranzen; jede Nachbearbeitung synthetischer Antworten], [4 Konvergenz, 5 Struktur],
    [F Code (1)], [Notebook, Instrumentenkarte als JSON, archivierte Rohausgaben aller Läufe], [2, 3],
    [G Interessenkonflikte (1)], [Finanzierung von API-Guthaben, Beziehungen zu Anbietern], [-],
    [Optional (8)], [Begründung der Modellwahl (bei geschlossenem Modell mit offenem Vergleichsmodell), Trainingsdaten-Leakage (Items neu formuliert), Bias-Risiko (Fehldarstellung der Homeoffice-Gruppe)], [6 Kontamination, 7],
  ),
  caption: [GUIDE-LLM auf die Fallstudie angewandt. In Klammern die Zahl der Punkte je Abschnitt laut Checkliste @feuerriegel2026reporting @guidellm2026checklist (Stand: 11. November 2026); mittlere Spalte und Zuordnung zu den Gliedern aus @k04-fig-fall-kette sind eigene Anwendung dieses Kapitels.],
) <k04-tab-guide-fall>

Die Zuordnung zeigt, warum GUIDE-LLM mehr ist als Bürokratie: Fehlt Abschnitt B, kann niemand Glied 3 prüfen; fehlt Abschnitt E, sind die Glieder 4 und 5 bloße Behauptung. Umgekehrt deckt die Checkliste nicht alles ab, was das Validitätsargument braucht. Sie verlangt menschliche Validierung, legt aber nicht fest, auf welcher Ebene; die Ebenenwahl bleibt Aufgabe der Arbeit und der Betreuung.

Für Simulationsstudien empfiehlt sich zusätzlich eine einseitige *Instrumentenkarte*, wie sie die dritte Übung des Dossiers vorschlägt: Modell-Snapshot, Datum, Parameter, Prompts und gemessene Reliabilität. Sie ist das Gegenstück zu den Komponenten von @k04-eq-instrument und lässt sich direkt aus der Pipeline generieren.

#datei("instrumentenkarte.py")[
```python
import json, hashlib, datetime, platform

def instrumentenkarte(modell, snapshot, zugang, decoding, prompt_vorlage,
                      parser_version, reliabilitaet, n_laeufe):
    """Hält die vier Komponenten des Instruments und seine Reliabilität fest."""
    return {
        "modell": modell, "snapshot": snapshot, "zugangsweg": zugang,
        "zugriffsdatum": datetime.date.today().isoformat(),
        "decoding": decoding,                       # temperature, top_p, seed, max_tokens
        "prompt_sha256": hashlib.sha256(prompt_vorlage.encode()).hexdigest(),
        "prompt_vorlage": prompt_vorlage,
        "parser_version": parser_version,
        "laeufe_pro_bedingung": n_laeufe,
        "reliabilitaet": reliabilitaet,             # z. B. Test-Retest je Achse
        "python": platform.python_version(),
    }

karte = instrumentenkarte("open-weights-8b", "rev-2026-10-01", "lokal",
    {"temperature": 0.7, "top_p": 1.0, "seed": 2027, "max_tokens": 5},
    "Du bist {persona}. Frage: {item} Antworte mit einer Zahl von 1 bis 5.",
    "parser-1.2", {"sitzungen_r": None, "prompt_varianten_r": None}, 30)
json.dump(karte, open("instrumentenkarte.json", "w"), indent=2, ensure_ascii=False)
```
]

Die Felder für die Reliabilität sind bewusst leer: Sie werden erst nach den Wiederholungsläufen befüllt, und eine Karte mit leeren Reliabilitätsfeldern ist ein sichtbarer Hinweis, dass das Validitätsargument noch unvollständig ist.

#merke[Berichte jede LLM-Studie nach GUIDE-LLM: Modellversion, Zugriffsdatum, Zugangsweg, Parameter, exakte Prompts, menschliche Validierung @feuerriegel2026reporting. Begründe ein geschlossenes Modell ausdrücklich @palmer2024using, und archiviere die Rohausgaben, damit die Studie das Modell überlebt @haindl2027research.]

#vertiefung[
  *Einstieg:* Argyle et al. @argyle2023out und Bisbee et al. @bisbee2024synthetic hintereinander lesen; zusammen zeigen sie Versprechen und Risiko an denselben ANES-Daten. \
  *Messtheorie:* Jacobs und Wallach @jacobs2021measurement für die Validitätsaspekte, Wallach et al. @wallach2025position für die vier Ebenen; Mangiaterra et al. @mangiaterra2025can als vollständiges Validitätsargument. \
  *Stand 2026:* der Pew-Bericht mit Methodenanhang @chapekis2026can @pew2026methodology, Li und Ji @li2026statistical zu Realismus und Effektgenauigkeit, Suh et al. @suh2025language und Kolluri et al. @kolluri2025finetuning für die positiven Fine-Tuning-Befunde. \
  *Debatte:* Anthis et al. @anthis2025position gegen Lin @lin2025six; Messeri und Crockett @messeri2024artificial als Landkarte. \
  *Reproduzierbarkeit:* Kapitel "Reproducibility" im Lehrbuch @haindl2027research, Palmer et al. @palmer2024using, GUIDE-LLM @feuerriegel2026reporting.
]

== Für die Lehre <k04-lehre>

Foliensatz 04 der Lehrveranstaltung umfasst 51 Folien in sieben Abschnitten (Einführung, Messung, Silicon Samples, Simulation von Experimenten, AI Scientists, Validitätsbedrohungen, gute Praxis), das Notebook `notebooks/04_silicon_sampling_validity.ipynb` begleitet die Abschnitte Messung und Silicon Samples. Die Reihenfolge dieses Kapitels folgt dem Foliensatz, mit @k04-vert als mathematischer Brücke zum Notebook.

=== Einstieg und Dramaturgie

Ein wirksamer Einstieg ist die Provokation von Dillion et al. ($r = 0.95$ mit menschlichen Moralurteilen) @dillion2023can, die die Studierenden zuerst bewerten sollen, bevor du die Umformulierungsstudie von Schröder et al. zeigst @schroder2025large. Dasselbe Muster funktioniert mit Si et al.: erst die Neuheitswerte, dann die Umsetzungsstudie @si2025can @si2025ideation. Beide Paare trainieren die Kernkompetenz des Kapitels, nämlich zu fragen, welchen Anspruch ein Befund eigentlich stützt. Für die Diskussion eignen sich die Fragen des Dossiers, etwa ob ein feinjustierter Prädiktor wie Centaur eine Theorie der Kognition ist @binz2025foundation @hu2025reevaluating oder welche Einwilligung man bräuchte, um einen digitalen Zwilling einer Studienteilnehmerin zu bauen @park2024llm.

=== Übungen

Das Dossier schlägt neun Python-Übungen vor; für eine Einheit von 90 Minuten Übung eignen sich drei besonders:

+ *Dreistufige Evaluation* eines Silicon Samples: Mittelwerte, dann Standardabweichungen und Gruppenlücken, dann Regressionskoeffizienten; berichtet wird der Anteil der Koeffizienten, deren 95 %-Intervall die menschliche Schätzung ausschließt, und der Anteil mit Vorzeichenwechsel, analog zu Bisbee et al. @bisbee2024synthetic. Das Notebook implementiert genau diese Schritte auf synthetischen Daten.
+ *Reliabilitätsprotokoll:* zwei Sitzungen pro Konfiguration (Temperatur 0 vs. 1, zwei Formulierungen, zwei Modellversionen), Test-Retest-Korrelationen und eine Drift-Steigung; Abgabe ist eine Instrumentenkarte @mangiaterra2025can @bisbee2024synthetic.
+ *Zitatprüfung:* Ein LLM erstellt eine Zusammenfassung mit zehn Referenzen zu einem Thema des Moduls; jede Referenz wird geprüft (existiert sie, stimmen die Metadaten, stützt sie die Aussage?), und die Halluzinationsrate wird mit OpenScholar und Agents4Science verglichen @asai2026synthesizing @bianchi2025exploring.

Wer mehr Zeit hat, nimmt die Übung zu Realismus und Effektgenauigkeit dazu: Studierende simulieren ein Zwei-Gruppen-Experiment mit drei Prompts und prüfen, ob der Prompt mit dem kleinsten MAE auch den kleinsten ATE-Fehler hat @li2026statistical. Für die eigenen Projekte der Studierenden ist GUIDE-LLM verbindlicher Berichtsstandard @feuerriegel2026reporting.

=== Typische Missverständnisse

- *"Hohe Korrelation heißt valide."* Die Korrelation von Item-Mittelwerten sagt nichts über Verteilungen, Einzelantworten oder Koeffizienten; im Notebook ist sie hoch, während alles andere falsch ist.
- *"Das Alignment ist 0.8, also passt es."* Das kollabierte Modell aus @k04-vert erreicht 0.80. Ohne Entropie oder Streuung ist der Wert nicht interpretierbar.
- *"Mehr synthetische Befragte machen es genauer."* Sie verkleinern nur den Stichprobenfehler des Instruments, nicht seine Verzerrung.
- *"Temperatur 0 macht es reproduzierbar."* Innerhalb eines Snapshots über die API ja; über die Zeit, über Schnittstellen und für Verteilungsfragen nein.
- *"Neuere Modelle haben das Problem gelöst."* Pew und Verasight 2026 zeigen dieselben Muster mit Frontier-Modellen @chapekis2026can @morris2026can.
- *"Die Kritiker halten LLM-Simulation für nutzlos."* Die Evidenz stützt eine bedingte Nutzung; die positiven Befunde nach Fine-Tuning und Interview-Verankerung gehören in jede Darstellung @suh2025language @kolluri2025finetuning @park2024llm.

=== Zeitbedarf

Für das Thema solltest du zwei Einheiten von je 90 Minuten einplanen: eine für Messtheorie und Silicon Samples mit dem Notebook (der Verteilungsvergleich braucht etwa 30 Minuten, wenn die Studierenden das Rechenbeispiel von Hand rechnen), eine für simulierte Experimente, AI Scientists, Bedrohungen und Berichtsstandards. Die Debatte (@k04-debatte) eignet sich als strukturierte Diskussion von 20-30 Minuten mit zugeteilten Positionen. Die Vorbereitungszeit liegt vor allem im Nachprüfen zeitkritischer Angaben: Modellnamen, Pew- und Verasight-Berichte und GUIDE-LLM sollten vor jeder Durchführung neu geprüft werden (Stand dieses Kapitels: 11. November 2026), und die Detailzahlen von Hewitt et al. sollten gegen den veröffentlichten _Nature_-Volltext abgeglichen werden, sobald er zugänglich ist @ashokkumar2026large.

#hoersaal([Darf ich in meiner Masterarbeit synthetische Befragte verwenden?], [Ja, als Pilot, zur Itementwicklung, zur Priorisierung von Hypothesen oder als Prior, und immer mit einer menschlichen Stichprobe, die die Schlüsse trägt. Die Arbeit muss das Instrument vollständig beschreiben (GUIDE-LLM), auf der Ebene validieren, auf der sie Schlüsse zieht, und offen berichten, wo das Instrument versagt. Eine Arbeit, die synthetische Daten als einzige Evidenz für einen Effekt verwendet, hat nach dem aktuellen Forschungsstand kein haltbares Validitätsargument @chapekis2026can @li2026statistical.])

#selbsttest(
  [Nenne die vier Komponenten eines LLM-Messinstruments nach @k04-eq-instrument und erkläre für jede, wie eine Änderung das Ergebnis verschieben kann.],
  [Ordne die vier Ebenen der Messmodellierung nach Wallach et al. einem Silicon Sample zu, das die Meinung österreichischer Studierender zu Studiengebühren messen soll. Welcher Validitätsaspekt setzt an welcher Ebene an?],
  [Berechne Wasserstein-Distanz, OpinionQA-Alignment, JSD (in Bit) und normierte Entropie für Menschen $P = (0.2, 0.3, 0.3, 0.2)$ und Modell $Q = (0.0, 0.1, 0.8, 0.1)$. Was sagt jedes Maß über das Modell?],
  [Beweise, dass die Jensen-Shannon-Divergenz mit Logarithmus zur Basis 2 höchstens 1 ist, und gib an, wann Gleichheit gilt.],
  [Eine synthetische Pilotstudie liefert $sigma_"syn" = 0.6 sigma$ und $Delta_"syn" = 1.2 Delta$. Um welchen Faktor verzerrt sich die geplante Fallzahl? Wie groß wäre die tatsächliche Power, wenn man mit der synthetischen Fallzahl plant und der wahre Effekt $Delta = 0.3$ bei $sigma = 1$ ist ($alpha = 0.05$ zweiseitig, geplante Power 80 %)?],
  [Interview-Agenten erreichen eine rohe Genauigkeit von 70 %, die Personen reproduzieren ihre eigenen Antworten zu 84 %. Berechne die normierte Genauigkeit und erkläre, warum die Normierung nötig ist.],
  [Bisbee et al. fanden Mittelwerte innerhalb einer Standardabweichung, aber 48 % abweichende Koeffizienten. Erkläre an einem Zahlenbeispiel, wie korrekte Gruppenmittelwerte mit einem falschen Regressionskoeffizienten einhergehen können.],
  [Erkläre den Befund von Li und Ji, dass die Auswahl des Prompts nach dem kleinsten MAE den ATE-Fehler erhöhen kann. Welche Konsequenz hat das für die Validierung?],
  [Ein Kollege berichtet, sein Simulator repliziere 95 % der Effekte aus einer Sammlung publizierter Studien. Welche zwei Prüfungen fehlen, bevor du das als Validitätsbeleg akzeptierst?],
  [Berechne für drei Erinnerungen mit Aktualität (roh) 0.99, 0.90, 0.70, Wichtigkeit 3, 9, 6 und Relevanz 0.6, 0.2, 0.9 den Abruf-Score nach @k04-eq-retrieval. Welche Erinnerung wird abgerufen?],
  [Warum ist "ein KI-generiertes Paper hat die Workshop-Begutachtung bestanden" ein schwacher Beleg für Forschungsqualität? Argumentiere messtheoretisch.],
  [Prüfe gedanklich eine Studie, die "GPT-4" ohne Datum, mit einem einzigen Prompt und über die Chat-Oberfläche verwendet, gegen GUIDE-LLM. Welche Kernpunkte fehlen, und welche Validitätsbedrohungen aus @k04-tab-bedrohungen sind betroffen?],
  [Zwei gleich große Gruppen beantworten ein dreistufiges Item. Menschen: Gruppe A $(0.6, 0.3, 0.1)$, Gruppe B $(0.1, 0.3, 0.6)$; Silicon Sample: A $(0.9, 0.1, 0.0)$, B $(0.0, 0.1, 0.9)$. Berechne Alignment und Entropieverhältnis (normierte Entropie Modell zu Mensch) je Gruppe und für die Gesamtpopulation. Was folgt für die Ebene, auf der eine Validierung berichtet werden muss?],
  [Eine Arbeit will prüfen, ob ein Silicon Sample die Lücke zwischen zwei Gruppen übertreibt. Erwartet werden $sigma_h = 0.9$, $sigma_s = 0.4$, die Abweichung, die erkannt werden soll, ist $D = 0.25$ ($alpha = 0.05$ zweiseitig, Power 80 %). Wie viele Personen pro Gruppe braucht die menschliche Stichprobe nach @k04-eq-n-valid? Welche Power hätte die Prüfung mit 60 Personen pro Gruppe, und wie wäre ein nicht signifikantes Ergebnis dann zu berichten?],
)

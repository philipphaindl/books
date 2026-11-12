#import "../lib.typ": *

// Lokale Mathematik-Kürzel und Plot-Helfer (nur in diesem Kapitel)
#let EE = $bb(E)$
#let PP = $bb(P)$
#let Var = math.op("Var")
#let Cov = math.op("Cov")
#let Corr = math.op("Corr")
#let se = math.op("SE")
#let k6t(body) = text(font: "Inter", size: 7.2pt, body)
#let k6achsen(W, H, xs, ys, xl: none, yl: none, xfmt: v => str(v), yfmt: v => str(v), xmin: 0, xmax: 1, ymin: 0, ymax: 1, gitter: true) = {
  import cetz.draw: *
  let X(x) = (x - xmin) / (xmax - xmin) * W
  let Y(y) = (y - ymin) / (ymax - ymin) * H
  if gitter {
    for v in ys { line((0, Y(v)), (W, Y(v)), stroke: (paint: luma(225), thickness: 0.4pt)) }
  }
  line((0, 0), (W, 0), stroke: 0.7pt + c-dark)
  line((0, 0), (0, H), stroke: 0.7pt + c-dark)
  for v in xs {
    line((X(v), 0), (X(v), -0.08), stroke: 0.6pt + c-dark)
    content((X(v), -0.28), k6t(xfmt(v)))
  }
  for v in ys {
    line((0, Y(v)), (-0.08, Y(v)), stroke: 0.6pt + c-dark)
    content((-0.14, Y(v)), anchor: "east", k6t(yfmt(v)))
  }
  if xl != none { content((W / 2, -0.75), k6t(xl)) }
  if yl != none { content((-0.95, H / 2), angle: 90deg, k6t(yl)) }
}

= Valide statistische Inferenz mit LLM-Labels <k06>

Im vorigen Kapitel ging es darum, wie gut ein LLM als Annotator ist: Übereinstimmung mit Menschen, Kappa, Codebücher. Dieses Kapitel stellt die Frage, die danach kommt und in vielen Projekten übersprungen wird. Angenommen, du hast 50 000 Social-Media-Beiträge von einem LLM codieren lassen und auf einer Stichprobe von 500 Beiträgen zusätzlich menschliche Goldlabels erhoben. Jetzt willst du einen Anteil schätzen (wie viele Beiträge enthalten Hassrede?) oder einen Regressionskoeffizienten (unterscheiden sich zwei Plattformen im Anteil?). Was ist der richtige Schätzer, und welches Konfidenzintervall darfst du berichten?

Die naheliegende Antwort, nämlich die LLM-Labels so zu behandeln, als wären sie die wahren Werte, ist in aller Regel falsch. Sie liefert verzerrte Punktschätzungen und Konfidenzintervalle, die viel zu schmal sind und den wahren Wert systematisch verfehlen @angelopoulos2023prediction @egami2023using. Die andere naheliegende Antwort, nur die 500 Goldlabels zu verwenden, ist zwar gültig, wirft aber die Information aus 49 500 LLM-Labels weg. Zwischen diesen beiden Extremen liegt eine Familie von Verfahren, die seit 2023 sehr schnell gewachsen ist: _Prediction-Powered Inference_ (PPI) und ihre Varianten aus der Statistik und dem maschinellen Lernen, _Design-based Supervised Learning_ (DSL) aus der Politikwissenschaft, ökonometrische Entzerrungsverfahren und ältere Korrekturen für Messfehler und Misklassifikation. Technisch haben sie einen gemeinsamen Kern: Sie verwenden die kleine Goldstichprobe, um den Fehler des LLM zu messen, und ziehen diesen Fehler von der LLM-basierten Schätzung ab.

Dieses Kapitel ist das mathematischste des Buchs. Das ist Absicht: Wer im Hörsaal erklären soll, warum ein Konfidenzintervall mit 90 % genauen Labels nur 40 % Überdeckung hat, warum die Korrektur unverzerrt ist und wann sie mehr schadet als nützt, muss die Herleitungen selbst können. Wir beginnen deshalb mit einer kompakten Auffrischung der asymptotischen Statistik, leiten dann die Verzerrung der Plug-in-Schätzung her, entwickeln PPI für den Mittelwert vollständig und verallgemeinern auf Regression, Power-Tuning (PPI++), aktive Stichprobenziehung und DSL. Danach ordnen wir die konkurrierenden Traditionen und Debatten ein und schließen mit Stichprobenplanung, Software und einem Entscheidungsbaum. Die zugehörigen Lehrmaterialien sind Foliensatz 06 der LV und das Notebook `notebooks/06_ppi_inference.ipynb`.

#lernziele[
  Schätzer anhand von Verzerrung, Varianz, mittlerem quadratischem Fehler und Konsistenz beurteilen und asymptotische Konfidenzintervalle über den zentralen Grenzwertsatz, die Delta-Methode und die Sandwich-Formel für M-Schätzer begründen.
][
  Die Verzerrung der Plug-in-Schätzung eines Anteils aus Sensitivität und Falsch-positiv-Rate herleiten, den Abschwächungsbias bei Messfehlern und Misklassifikation erklären und zeigen, warum große Datenmengen das Problem verschärfen.
][
  Den PPI-Schätzer für den Mittelwert herleiten, seine Unverzerrtheit und Varianz beweisen und das Konfidenzintervall von Hand berechnen.
][
  PPI auf lineare Regression und allgemeine M-Schätzer übertragen und die ökonometrische Formulierung nach Ludwig et al. als denselben Schätzer erkennen.
][
  Das optimale Gewicht $lambda^star$ von PPI++ herleiten, die effektive Stichprobengröße berechnen und ihre obere Schranke $n slash (1 - rho^2)$ interpretieren.
][
  Cross-PPI, stratifizierte und aktive Inferenz, Confidence-Driven Inference und DSL nach Annahmen und Einsatzgebiet vergleichen und die Idee der doppelten Robustheit erklären.
][
  Die Grenzen statistischer Korrektur benennen: nicht zufällige Goldstichproben, verrauschte Goldlabels, Konzeptualisierungsfehler im Codebuch, Verlust an Teststärke.
][
  Eine Goldstichprobe planen, `ppi_py` korrekt einsetzen und eine Coverage-Simulation zur Prüfung eines Verfahrens aufsetzen.
]

== Genaue Labels, falsche Schlüsse <k06-problem>

Beginnen wir mit dem Befund, der das ganze Kapitel motiviert. In der Simulation, mit der Egami et al. DSL einführen, haben die Ersatzlabels (_surrogate labels_) eine Genauigkeit von 90 %. Wer diese Labels in eine nachgelagerte Regression einsetzt, erhält dennoch eine deutlich verzerrte Schätzung, und das nominelle 95-%-Konfidenzintervall überdeckt den wahren Wert nur in etwa 40 % der Wiederholungen @egami2023using[Abb. 1a, Abschn. 1]. Eine Genauigkeit, die in einer Annotationsstudie als ausgezeichnet gelten würde, garantiert also nichts für die Gültigkeit des Schlusses, den du daraus ziehst.

Dieser Befund ist kein Einzelfall. Im PPI-Aufsatz von Angelopoulos et al. enthält das Intervall des Imputationsansatzes, bei dem Vorhersagen wie Beobachtungen behandelt werden, in den gezeigten Anwendungen den wahren Wert des Schätzziels nicht @angelopoulos2023prediction[Abb. 2]. Fong und Tyler zeigen für den Fall, dass ein vorhergesagtes Merkmal als erklärende Variable in eine Regression eingeht, dass selbst ein Klassifikator mit 90 % Genauigkeit bei einer Million Dokumenten eine Verzerrung von etwa $-0.20$ und eine Überdeckung von 0.00 erzeugt @fong2021machine[Tab. 2]. Das Problem ist auch nicht neu und nicht auf LLMs beschränkt: In einer Durchsicht von 48 kommunikationswissenschaftlichen Studien, die überwachte Textklassifikatoren einsetzen, hat genau eine für Misklassifikation korrigiert @teblunthuis2024misclassification[Anh. C].

Mit LLMs kommt eine weitere Fehlerquelle hinzu: die Konfigurationsfreiheit. Baumann et al. haben 37 Annotationsaufgaben aus 21 Datensätzen mit 18 LLMs und 199 Prompts codieren lassen und rund 1.4 Millionen Regressionen zu 2361 Hypothesen gerechnet @baumann2025large[Tab. 1, Abb. 1, Abschn. 4.3]. Das Risiko, unbeabsichtigt zu einer falschen Schlussfolgerung zu kommen, lag selbst für die besten großen Modelle bei etwa 31 % (GPT-4o: 31.2 %) und für Modelle mit einer Milliarde Parametern bei etwa 50 % @baumann2025large[Abschn. 5.2, Tab. 3]. Ludwig et al. berichten, dass Regressionskoeffizienten auf LLM-Labels über fünf Modelle und neun Prompts hinweg in Größe, Signifikanz und teilweise im Vorzeichen variieren @ludwig2026large[Abschn. 4.2.1].

#merke[
  Annotationsmetriken wie Genauigkeit, F1 oder Kappa beschreiben das Messinstrument. Sie sagen nicht, ob eine Schätzung, die auf den Labels beruht, unverzerrt ist oder ob ihr Konfidenzintervall die nominelle Überdeckung erreicht. Für diese Frage brauchst du ein Verfahren, das die Fehler des Instruments explizit in die Inferenz einbezieht.
]

=== Das Grundschema aller Korrekturverfahren

Alle Verfahren dieses Kapitels folgen demselben Ablauf (@k06-fig-schema). Das LLM labelt sämtliche Einheiten. Eine Zufallsstichprobe (oder eine Stichprobe mit bekannten Auswahlwahrscheinlichkeiten) wird zusätzlich von Menschen gelabelt. Auf dieser Goldstichprobe misst man, wie sich die LLM-basierte Größe von der wahren unterscheidet, und korrigiert damit die Schätzung aus allen LLM-Labels. Die Voraussetzungen sind bescheiden: PPI verlangt eine gelabelte Zufallsstichprobe aus derselben Population wie die ungelabelten Daten @angelopoulos2023prediction[Abschn. 1.2], DSL verlangt bekannte und strikt positive Wahrscheinlichkeiten, mit denen Einheiten in die Goldstichprobe gelangen @egami2023using[Annahme 1]. Über die Qualität des LLM wird nichts vorausgesetzt @angelopoulos2023prediction[Abschn. 1.1-1.2].

#figure(
  diagram(spacing: (7mm, 9mm), node-stroke: none,
    fknoten((0, 0), [Alle Einheiten \ ($n + N$ Texte)], col: c-dark, filled: true, w: 30mm),
    fknoten((1.3, -0.75), [LLM labelt alle \ $f(X_i)$, $f(tilde(X)_i)$], col: c-blue, w: 33mm),
    fknoten((1.3, 0.75), [Zufallsstichprobe \ $n$ Goldlabels $Y_i$], col: c-accent, w: 33mm),
    fknoten((2.7, -0.75), [Schätzung aus \ LLM-Labels (verzerrt)], col: c-blue, w: 33mm),
    fknoten((2.7, 0.75), [Rektifikator: \ mittlerer LLM-Fehler], col: c-accent, w: 33mm),
    fknoten((4.0, 0), [Korrigierte \ Schätzung mit \ gültigem KI], col: c-teal, filled: true, w: 32mm),
    edge((0, 0), (1.3, -0.75), "-|>"),
    edge((0, 0), (1.3, 0.75), "-|>"),
    edge((1.3, -0.75), (2.7, -0.75), "-|>"),
    edge((1.3, 0.75), (2.7, 0.75), "-|>"),
    edge((1.3, -0.75), (2.7, 0.75), "-|>", stroke: (dash: "dashed")),
    edge((2.7, -0.75), (4.0, 0), "-|>"),
    edge((2.7, 0.75), (4.0, 0), "-|>"),
  ),
  caption: [Grundschema der Korrektur: Das LLM labelt alle Einheiten, eine Zufallsstichprobe zusätzlich der Mensch. Der auf der Goldstichprobe gemessene mittlere Fehler (Rektifikator) wird von der LLM-basierten Schätzung abgezogen. Die gestrichelte Kante zeigt, dass für den Rektifikator die LLM-Labels der Goldeinheiten gebraucht werden.],
) <k06-fig-schema>

Die drei Strategien, die du ohne Korrektur zur Verfügung hast, lassen sich so zusammenfassen @angelopoulos2023prediction[Abschn. 1.3] @egami2023using[Tab. 3]:

- *Klassisch (nur Gold):* Verwende nur die $n$ Goldlabels. Das ist gültig, aber die Breite des Intervalls skaliert mit $sqrt(Var(Y) slash n)$ und ignoriert die LLM-Labels vollständig.
- *Plug-in (Imputation, _surrogate only_):* Behandle $f(X_i)$ als $Y_i$. Das Intervall ist schmal, aber falsch zentriert. In der DSL-Evaluation über 18 Aufgaben erreicht dieser Ansatz zum Beispiel bei einer Misinformationsaufgabe mit 77.6 % Genauigkeit nur 0.6 % Überdeckung @egami2023using[Tab. 3].
- *Nachträgliche Korrektur mit einem angepassten Fehlermodell* (_postpi_ @wang2020methods): Sie ist nur unter starken Spezifikationsannahmen gültig. Wir kommen in @k06-debatten darauf zurück.

Bevor wir die Korrektur herleiten, frischen wir die statistischen Werkzeuge auf, mit denen man solche Aussagen überhaupt präzise machen kann.

== Statistische Grundlagen: Schätzer und ihre Unsicherheit <k06-grundlagen>

Dieser Abschnitt ist eine dichte Wiederholung. Die Grundbegriffe (Stichprobenverteilung, Standardfehler, Konfidenzintervall, Fehler erster und zweiter Art) setzt das Lehrbuch voraus @haindl2027research. Hier gehen wir einen Schritt weiter in die asymptotische Theorie, weil alle Intervalle dieses Kapitels asymptotische Intervalle sind @angelopoulos2023prediction[Prop. 1] @angelopoulos2023ppi[Satz 1].

=== Schätzer, Verzerrung, Varianz

#definition(titel: [Schätzer und Schätzziel])[
  Das *Schätzziel* (_estimand_) $theta^star$ ist eine feste Eigenschaft der Population, etwa der Anteil $theta^star = PP(Y = 1)$ oder ein Regressionskoeffizient. Ein *Schätzer* $hat(theta) = T(Z_1, dots, Z_n)$ ist eine Funktion der Daten und damit eine Zufallsvariable. Seine *Verzerrung* (_bias_) ist
  $ "Bias"(hat(theta)) = EE[hat(theta)] - theta^star, $ <k06-eq-bias>
  seine *Varianz* $Var(hat(theta)) = EE[(hat(theta) - EE[hat(theta)])^2]$ und sein *Standardfehler* $se(hat(theta)) = sqrt(Var(hat(theta)))$. Der *mittlere quadratische Fehler* ist $"MSE"(hat(theta)) = EE[(hat(theta) - theta^star)^2]$.
]

Die wichtigste Identität ist die Zerlegung des MSE. Sie erklärt, warum ein verzerrter Schätzer mit kleiner Varianz in einem Vergleich nach RMSE gut aussehen kann und trotzdem für Inferenz unbrauchbar ist.

#satz(titel: [Bias-Varianz-Zerlegung])[
  Für jeden Schätzer mit endlicher Varianz gilt
  $ "MSE"(hat(theta)) = Var(hat(theta)) + "Bias"(hat(theta))^2 . $ <k06-eq-mse>
]
#beweis[
  Schreibe $hat(theta) - theta^star = (hat(theta) - EE[hat(theta)]) + (EE[hat(theta)] - theta^star)$ und quadriere. Der gemischte Term $2 (EE[hat(theta)] - theta^star) EE[hat(theta) - EE[hat(theta)]]$ verschwindet, weil der zweite Faktor null ist. Übrig bleiben Varianz und quadrierte Verzerrung.
]

Genau dieses Muster findet sich in der DSL-Evaluation: Bei einer Emotionsaufgabe hat der Plug-in-Ansatz einen kleineren RMSE als DSL (2.9 gegenüber 3.2, jeweils mal 100), überdeckt aber nur in 67.2 % der Fälle, während DSL 94.0 % erreicht @egami2023using[Tab. 3]. Der Plug-in-Schätzer ist hier "genauer" im Sinne des MSE, aber seine Intervalle sind ungültig, weil sie die Verzerrung nicht kennen.

=== Konsistenz und Gesetz der großen Zahlen

Ein Schätzer heißt *konsistent*, wenn $hat(theta)_n -> theta^star$ in Wahrscheinlichkeit, also $PP(|hat(theta)_n - theta^star| > epsilon) -> 0$ für jedes $epsilon > 0$. Hinreichend dafür ist, dass Verzerrung und Varianz beide gegen null gehen (Markov-Ungleichung angewandt auf den MSE). Das schwache Gesetz der großen Zahlen liefert die Konsistenz des Stichprobenmittels für jede Verteilung mit endlichem Erwartungswert.

Für dieses Kapitel ist eine Konsequenz zentral: Ein Plug-in-Schätzer auf LLM-Labels ist konsistent, aber für das *falsche* Ziel. Das Mittel der LLM-Labels konvergiert gegen $EE[f(X)]$, nicht gegen $EE[Y]$. Mehr Daten bringen dich also immer genauer an die falsche Stelle. Motwani und Witten formulieren diesen Punkt für die Regression präzise: Der naive Schätzer konvergiert gegen $EE[X X^top]^(-1) EE[X hat(f)(Z)]$, eine Größe, in der $Y$ gar nicht vorkommt @motwani2023revisiting[Abschn. 2.1].

=== Zentraler Grenzwertsatz und asymptotische Normalität

#satz(titel: [Zentraler Grenzwertsatz])[
  Sind $Z_1, dots, Z_n$ unabhängig und identisch verteilt mit $EE[Z] = mu$ und $Var(Z) = sigma^2 < infinity$, dann gilt
  $ sqrt(n) (overline(Z)_n - mu) limits(arrow.r)^d cal(N)(0, sigma^2). $ <k06-eq-clt>
  Für Zufallsvektoren mit Kovarianzmatrix $Sigma$ gilt dasselbe mit $cal(N)(0, Sigma)$.
]

Das Lehrbuch formuliert den Satz für Mittelwerte und gibt die Faustregel, dass Stichprobenmittel ab etwa $n > 30$ annähernd normalverteilt sind, abhängig von der Schiefe der Population @haindl2027research. Für binäre Labels mit kleinem Anteil, wie sie bei LLM-Annotation häufig vorkommen, ist diese Faustregel optimistisch. Zwei Zusätze brauchen wir ständig:

1. *Slutsky:* Konvergiert $A_n -> a$ in Wahrscheinlichkeit und $B_n limits(arrow.r)^d B$, dann $A_n B_n limits(arrow.r)^d a B$ und $A_n + B_n limits(arrow.r)^d a + B$. Damit dürfen wir unbekannte Varianzen durch konsistente Schätzer ersetzen, ohne die Grenzverteilung zu ändern.
2. *Unabhängige Summanden:* Sind $hat(theta)_1$ und $hat(theta)_2$ aus unabhängigen Stichproben gebildet und je asymptotisch normal, dann ist ihre Differenz asymptotisch normal mit der Summe der Varianzen. Diesen Schritt verwenden wir für PPI, wo eine Größe auf den ungelabelten und eine auf den gelabelten Daten berechnet wird.

=== Delta-Methode

Viele Schätzziele sind glatte Funktionen von Mittelwerten, etwa eine Odds Ratio oder der Quotient zweier Anteile.

#satz(titel: [Delta-Methode])[
  Gilt $sqrt(n)(hat(theta)_n - theta) limits(arrow.r)^d cal(N)(0, Sigma)$ und ist $g$ in $theta$ differenzierbar mit Gradient $nabla g(theta) eq.not 0$, dann
  $ sqrt(n) (g(hat(theta)_n) - g(theta)) limits(arrow.r)^d cal(N)(0, nabla g(theta)^top Sigma nabla g(theta)). $ <k06-eq-delta>
]
#beweis[
  Taylor-Entwicklung erster Ordnung: $g(hat(theta)_n) = g(theta) + nabla g(tilde(theta))^top (hat(theta)_n - theta)$ mit $tilde(theta)$ zwischen $hat(theta)_n$ und $theta$. Wegen Konsistenz gilt $tilde(theta) -> theta$, also $nabla g(tilde(theta)) -> nabla g(theta)$ in Wahrscheinlichkeit. Multipliziere mit $sqrt(n)$ und wende Slutsky an.
]

Für die Praxis heißt das: Wenn du mit PPI zwei Anteile korrigiert schätzt und daraus eine Odds Ratio bildest, bekommst du ihr Intervall über die Delta-Methode. Alternativ verwendest du das _Prediction-Powered Bootstrap_ (PPBoot), das ohne solche Herleitungen auskommt @zrnic2024note.

=== M-Schätzer und die Sandwich-Formel

Mittelwert, Quantil, lineare und logistische Regression lassen sich einheitlich als Minimierer eines erwarteten Verlusts schreiben. Genau so definiert PPI seine Schätzziele @angelopoulos2023prediction[Abschn. 2, Gl. 1].

#definition(titel: [M-Schätzer])[
  Sei $ell_theta (x, y)$ eine konvexe Verlustfunktion. Das Schätzziel ist
  $ theta^star = arg min_(theta in RR^p) L(theta), quad L(theta) = EE[ell_theta (X, Y)], $ <k06-eq-mest>
  der M-Schätzer ist $hat(theta) = arg min_theta 1/n sum_(i=1)^n ell_theta (X_i, Y_i)$. Mit dem Gradienten $g_theta = nabla_theta ell_theta$ löst er die Schätzgleichung $1/n sum_i g_hat(theta) (X_i, Y_i) = 0$.
]

Beispiele: Für $ell_theta (y) = 1/2 (y - theta)^2$ ist $theta^star = EE[Y]$. Für $ell_theta (x, y) = 1/2 (y - x^top theta)^2$ ist $theta^star = EE[X X^top]^(-1) EE[X Y]$, der Koeffizient der besten linearen Vorhersage, genau das Ziel, das Motwani und Witten für den Vergleich von postpi und PPI verwenden @motwani2023revisiting[Abschn. 2, Gl. 1].

#satz(titel: [Asymptotische Normalität von M-Schätzern])[
  Unter Regularitätsbedingungen gilt
  $ sqrt(n)(hat(theta) - theta^star) limits(arrow.r)^d cal(N)(0, H^(-1) V H^(-1)), quad H = nabla^2 L(theta^star), quad V = Cov(g_(theta^star)(X, Y)). $ <k06-eq-sandwich>
]
#beweis[
  Entwickle die Schätzgleichung um $theta^star$: $0 = 1/n sum_i g_hat(theta) approx 1/n sum_i g_(theta^star) + hat(H) (hat(theta) - theta^star)$ mit der empirischen Hesse-Matrix $hat(H) -> H$. Also $sqrt(n)(hat(theta) - theta^star) approx -H^(-1) dot 1/sqrt(n) sum_i g_(theta^star)(X_i, Y_i)$. Wegen $EE[g_(theta^star)] = nabla L(theta^star) = 0$ ist die Summe nach dem zentralen Grenzwertsatz asymptotisch $cal(N)(0, V)$. Die lineare Abbildung $-H^(-1)$ ergibt die Kovarianz $H^(-1) V H^(-1)$.
]

Die Form $H^(-1) V H^(-1)$ heißt *Sandwich*: Die "Brotscheiben" $H^(-1)$ beschreiben die Krümmung des Verlusts, der "Belag" $V$ die Streuung der Gradienten. Für OLS ist $H = EE[X X^top]$ und $V = EE[epsilon^2 X X^top]$ mit dem Residuum $epsilon = Y - X^top theta^star$. Das ist der heteroskedastizitätsrobuste Standardfehler (HC0). Die gesamte PPI-Theorie für Regression ist eine Variation dieser Formel, in der $V$ durch die Streuung von Gradientendifferenzen ersetzt wird @angelopoulos2023ppi[Satz 1, Gl. 7].

=== Konfidenzintervalle und Überdeckung

Aus asymptotischer Normalität und einem konsistenten Standardfehler folgt das Wald-Intervall
$ C_alpha = [hat(theta) - z_(1 - alpha slash 2) hat(se), thick hat(theta) + z_(1 - alpha slash 2) hat(se)], $ <k06-eq-wald>
mit dem Normalquantil $z_(0.975) approx 1.96$. Die Garantie ist asymptotisch: $PP(theta^star in C_alpha) -> 1 - alpha$. Die *Überdeckungswahrscheinlichkeit* (_coverage_) ist die Eigenschaft, um die sich dieses Kapitel dreht. Sie ist eine Aussage über das Verfahren bei Wiederholung, nicht über ein einzelnes Intervall (@k06-fig-coverage-idee).

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 12.4
    let H = 3.6
    let X(x) = (x - 0.0) / 0.32 * W
    // Daten: Steigungs-KI aus 25 Simulationsläufen (Seed 3), naiv vs. PPI++
    let naiv = ((0.0447, 0.0823), (0.0583, 0.0962), (0.0549, 0.0927), (0.0432, 0.0812), (0.0541, 0.0919), (0.0578, 0.0956), (0.0506, 0.0883), (0.0429, 0.0808), (0.0529, 0.091), (0.0431, 0.081), (0.0437, 0.0818), (0.0511, 0.0887), (0.0437, 0.0815), (0.0411, 0.0791), (0.0511, 0.0889), (0.0468, 0.0847), (0.0568, 0.0946), (0.04, 0.078), (0.0595, 0.0974), (0.0295, 0.0674), (0.063, 0.1007), (0.026, 0.064), (0.0548, 0.0927), (0.0409, 0.0787), (0.0572, 0.0953))
    let ppi = ((0.1107, 0.2461), (0.114, 0.2466), (-0.0019, 0.1179), (0.0708, 0.2059), (0.1302, 0.2605), (0.0775, 0.208), (0.0624, 0.189), (0.1253, 0.2569), (0.1122, 0.2464), (0.0886, 0.2149), (0.082, 0.2053), (0.0962, 0.2269), (0.1383, 0.2718), (0.1534, 0.3), (0.0494, 0.1863), (0.0643, 0.1955), (0.1288, 0.2575), (0.0706, 0.2076), (0.0576, 0.1849), (0.0668, 0.2097), (0.08, 0.2033), (0.1435, 0.2737), (0.08, 0.2008), (0.0587, 0.1953), (0.1114, 0.2468))
    for (blk, daten, farbe, titel) in ((0, naiv, c-red, [Plug-in (naiv): 0 von 25 überdecken]), (1, ppi, c-blue, [PPI++: 23 von 25 überdecken])) {
      let y0 = -blk * (H + 1.0)
      line((X(0), y0), (X(0.32), y0), stroke: 0.6pt + c-dark)
      for v in (0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30) {
        line((X(v), y0), (X(v), y0 - 0.08), stroke: 0.6pt + c-dark)
        content((X(v), y0 - 0.3), k6t(str(v)))
      }
      line((X(0.15), y0), (X(0.15), y0 + H), stroke: (paint: c-dark, thickness: 0.8pt, dash: "dashed"))
      content((X(0.15) + 0.1, y0 + H + 0.05), anchor: "south-west", k6t[wahre Steigung 0.15])
      content((0, y0 + H + 0.05), anchor: "south-west", text(font: "Inter", size: 7.5pt, weight: "bold", fill: farbe, titel))
      for (i, (a, b)) in daten.enumerate() {
        let y = y0 + 0.15 + i * (H - 0.3) / 24
        let trifft = a <= 0.15 and 0.15 <= b
        let col = if trifft { farbe } else { c-grey }
        line((X(calc.max(a, 0)), y), (X(b), y), stroke: (paint: if blk == 0 { c-red } else if trifft { c-blue } else { c-accent }, thickness: 1.1pt))
        circle((X((a + b) / 2), y), radius: 0.035, fill: c-dark, stroke: none)
      }
    }
    content((W / 2, -(H + 1.0) - 0.75), k6t[Geschätzte Steigung (Gruppenunterschied im Anteil) mit 95-%-Konfidenzintervall])
  }),
  caption: [Überdeckung als Eigenschaft des Verfahrens. Jede Linie ist das 95-%-Intervall aus einer simulierten Studie (10 000 Beiträge, 500 Goldlabels, LLM mit 85.6 % Genauigkeit und gruppenabhängigem Fehler; Design aus @k06-simulation). Oben: Plug-in-Schätzung auf LLM-Labels, schmal und durchgehend falsch. Unten: PPI++, breiter, aber um den wahren Wert zentriert; die zwei orange markierten Intervalle verfehlen ihn, wie es bei 95 % zu erwarten ist. Eigene Simulation mit dem Code aus @k06-simulation, Seed 3.],
) <k06-fig-coverage-idee>

#merke[
  Ein Konfidenzintervall ist ein Verfahren mit einer Erfolgsquote. "95 %" heißt: Würdest du die Studie oft wiederholen, enthielten etwa 95 % der so konstruierten Intervalle den wahren Wert. Ein verzerrtes Verfahren verliert diese Eigenschaft, und zwar umso drastischer, je schmaler seine Intervalle werden.
]

Die letzte Bemerkung lässt sich genau ausrechnen. Ein Schätzer habe die Verzerrung $b$ und den Standardfehler $s$, sei also näherungsweise $cal(N)(theta^star + b, s^2)$-verteilt. Das Wald-Intervall überdeckt $theta^star$ genau dann, wenn $|hat(theta) - theta^star| <= z s$. Mit $k = b slash s$ folgt
$ PP("Überdeckung") = Phi(z - k) - Phi(-z - k). $ <k06-eq-coverage>
Für $k = 0$ ergibt das $1 - alpha$. Wächst die Verzerrung relativ zum Standardfehler, fällt die Überdeckung rasch: bei $k = 1$ auf etwa 0.83, bei $k = 2$ auf etwa 0.48, bei $k = 4$ auf etwa 0.02. Für den Plug-in-Schätzer bleibt $b$ fest, während $s$ mit $1 slash sqrt(N)$ schrumpft. Also wächst $k$ mit $sqrt(N)$, und die Überdeckung geht gegen null. Dieses Phänomen nehmen wir im nächsten Abschnitt quantitativ auseinander.

#hoersaal([Ist ein Konfidenzintervall nicht einfach der Bereich, in dem der wahre Wert mit 95 % Wahrscheinlichkeit liegt?], [In der frequentistischen Lesart nein. Der wahre Wert ist fest, das Intervall ist zufällig. Die 95 % beziehen sich auf das Verfahren über Wiederholungen. Für dieses Kapitel ist die Unterscheidung nicht spitzfindig, sondern der Kern: Die Plug-in-Intervalle auf LLM-Labels sehen wie jedes andere Intervall aus, aber das Verfahren dahinter hat eine Erfolgsquote nahe null. Nur eine Simulation oder eine Herleitung kann das zeigen, nie das einzelne Intervall selbst.])

== Warum Plug-in-Schätzer mit LLM-Labels verzerrt sind <k06-plugin>

Wir betrachten jetzt die Mechanik der Verzerrung. Dabei hilft eine Unterscheidung aus der Messfehlerliteratur, die du auf LLM-Labels direkt übertragen kannst.

#definition(titel: [Fehlerarten bei LLM-Labels])[
  Sei $Y$ das wahre Label, $hat(Y) = f(X)$ das LLM-Label und $G$ eine Kovariate (etwa Plattform, Dialekt, Medientyp).
  - *Nicht differenzieller Fehler:* Die Fehlerraten hängen nicht von $G$ ab, $PP(hat(Y) = 1 | Y, G) = PP(hat(Y) = 1 | Y)$.
  - *Differenzieller Fehler:* Die Fehlerraten hängen von $G$ ab. Egami et al. identifizieren genau diesen Fall als den typischen @egami2023using[Abschn. 3]. Ein Lehrbeispiel aus einem Kurs von 2026 zeigt Fehler, die sich auf einen Medientyp konzentrieren und dadurch Gruppenvergleiche verzerren @jhu2026prediction[Folie 14].
  - *Konzeptualisierungsfehler:* Das Codebuch erfasst das gemeinte Konstrukt nicht. Davon zu trennen ist der *Operationalisierungsfehler*, bei dem ein korrektes Codebuch falsch angewendet wird @halterman2025what.
]

Statistische Korrekturen wie PPI und DSL behandeln Operationalisierungsfehler relativ zum Goldstandard. Konzeptualisierungsfehler, die Gold- und LLM-Labels gemeinsam haben, können sie nicht beheben @halterman2025what[Abb. 3]. Darauf kommen wir in @k06-grenzen zurück.

=== Der verzerrte Anteil: Herleitung

Sei $Y in {0, 1}$ mit Prävalenz $theta = PP(Y = 1)$. Das LLM habe die *Sensitivität* $s = PP(hat(Y) = 1 | Y = 1)$ und die *Falsch-positiv-Rate* $r = PP(hat(Y) = 1 | Y = 0)$; die Spezifität ist $1 - r$.

#satz(titel: [Erwartungswert und Verzerrung des naiven Anteils])[
  Für den naiven Schätzer $hat(theta)^"naiv" = 1/N sum_i hat(Y)_i$ gilt
  $ EE[hat(Y)] = s theta + r (1 - theta), quad "Bias" = EE[hat(Y)] - theta = r - (1 - s + r) theta . $ <k06-eq-prevbias>
]
#beweis[
  Satz von der totalen Wahrscheinlichkeit: $PP(hat(Y) = 1) = PP(hat(Y) = 1 | Y = 1) PP(Y = 1) + PP(hat(Y) = 1 | Y = 0) PP(Y = 0) = s theta + r(1 - theta)$. Subtrahiere $theta$ und fasse zusammen: $s theta + r - r theta - theta = r - (1 - s + r) theta$.
]

Drei Folgerungen lassen sich unmittelbar ablesen. Erstens ist die Verzerrung null, wenn $r = (1 - s + r) theta$, also $theta = r slash (r + 1 - s)$: Falsch-positive und Falsch-negative heben sich zufällig auf. Das ist ein Gleichgewicht, das von der unbekannten Prävalenz abhängt und in einer anderen Teilpopulation sofort kippt. Zweitens zieht ein symmetrischer Fehler mit Genauigkeit $a$ ($s = a$, $r = 1 - a$) den Anteil zur Mitte: $EE[hat(Y)] = a theta + (1 - a)(1 - theta)$, eine Gerade durch den Punkt $(0.5, 0.5)$ mit Steigung $2a - 1$ (@k06-fig-prevbias). Drittens lässt sich @k06-eq-prevbias umkehren, wenn $s$ und $r$ bekannt sind: $theta = (EE[hat(Y)] - r) slash (s - r)$. Diese Inversion ist die naheliegende Korrektur eines Anteils. Sie verlangt aber, dass $s$ und $r$ geschätzt werden, was wiederum Goldlabels braucht, und sie überträgt sich nicht direkt auf Regressionen mit differenziellem Fehler.

#beispiel(titel: [Symmetrischer Fehler bei 85 % Genauigkeit])[
  Wahre Prävalenz $theta = 0.31$, symmetrische Genauigkeit $a = 0.85$. Dann ist $EE[hat(Y)] = 0.85 dot 0.31 + 0.15 dot 0.69 = 0.2635 + 0.1035 = 0.367$ und die Verzerrung $+0.057$. Ein LLM, das in 85 % der Fälle richtig liegt, überschätzt den Anteil also um 18 % relativ zum wahren Wert. Die Herleitung stammt aus der Wissensbasis der LV und wird dort durch Simulation bestätigt; im Notebook zu Foliensatz 06 kannst du sie mit einer Million simulierter Beiträge nachprüfen.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 7.0
    let H = 4.6
    k6achsen(W, H, (0, 0.25, 0.5, 0.75, 1), (0, 0.25, 0.5, 0.75, 1), xl: [wahre Prävalenz $theta$], yl: [erwarteter LLM-Anteil $EE[hat(Y)]$])
    let X(x) = x * W
    let Y(y) = y * H
    line((X(0), Y(0)), (X(1), Y(1)), stroke: (paint: c-dark, thickness: 0.8pt, dash: "dashed"))
    for (a, col, lab) in ((0.95, c-teal, [$a = 0.95$]), (0.85, c-blue, [$a = 0.85$]), (0.70, c-accent, [$a = 0.70$])) {
      let p0 = 1 - a
      let p1 = a
      line((X(0), Y(p0)), (X(1), Y(p1)), stroke: (paint: col, thickness: 1.3pt))
      content((X(1) + 0.1, Y(p1)), anchor: "west", text(font: "Inter", size: 7pt, fill: col, lab))
    }
    content((X(1) + 0.1, Y(1) + 0.12), anchor: "west", k6t[ohne Fehler])
    circle((X(0.31), Y(0.367)), radius: 0.07, fill: c-blue, stroke: none)
    circle((X(0.31), Y(0.31)), radius: 0.07, fill: c-dark, stroke: none)
    line((X(0.31), Y(0.31)), (X(0.31), Y(0.367)), stroke: 0.8pt + c-red)
    line((X(0.31) + 0.05, Y(0.338)), (X(0.38), Y(0.20)), stroke: 0.5pt + c-red)
    content((X(0.38) + 0.05, Y(0.20)), anchor: "west", text(font: "Inter", size: 7pt, fill: c-red)[Bias +0.057])
  }),
  caption: [Symmetrischer Klassifikationsfehler zieht den geschätzten Anteil zur Mitte. Jede Linie ist $EE[hat(Y)] = a theta + (1 - a)(1 - theta)$ nach @k06-eq-prevbias; der markierte Punkt ist das Rechenbeispiel mit $theta = 0.31$ und $a = 0.85$. Seltene Kategorien werden überschätzt, häufige unterschätzt.],
) <k06-fig-prevbias>

=== Regression mit LLM-Label als abhängige Variable

Interessanter als ein einzelner Anteil sind fast immer Vergleiche: Ist der Anteil in Gruppe $G = 1$ höher als in $G = 0$? Bei binärem $G$ ist der OLS-Koeffizient von $Y$ auf $(1, G)$ genau die Differenz $beta = EE[Y | G = 1] - EE[Y | G = 0]$. Ersetzen wir $Y$ durch $hat(Y)$, schätzt die Regression stattdessen $tilde(beta) = EE[hat(Y) | G = 1] - EE[hat(Y) | G = 0]$.

#satz(titel: [Abschwächung bei nicht differenziellem Fehler im Outcome])[
  Hängen $s$ und $r$ nicht von $G$ ab, dann gilt $EE[hat(Y) | G] = r + (s - r) EE[Y | G]$ und damit
  $ tilde(beta) = (s - r) beta = (s + "Spezifität" - 1) beta . $ <k06-eq-youden>
]
#beweis[
  Wende @k06-eq-prevbias bedingt auf $G = g$ an: $EE[hat(Y) | G = g] = s theta_g + r(1 - theta_g) = r + (s - r) theta_g$. Die Differenz über $g in {0, 1}$ eliminiert $r$.
]

Der Faktor $s - r$ ist der Youden-Index $J$ des Klassifikators. Bei symmetrischen 85 % ist $J = 0.70$: Der geschätzte Gruppenunterschied wird um 30 % *abgeschwächt* (_attenuation bias_). Abschwächung ist die gutmütige Variante, denn sie lässt das Vorzeichen intakt: Unter der Nullhypothese $beta = 0$ ist auch $tilde(beta) = 0$, der Test behält sein Niveau und verliert nur Teststärke. Sobald der Fehler differenziell ist, gibt es diese Gutmütigkeit nicht mehr.

#beispiel(titel: [Differenzieller Fehler halbiert den Effekt])[
  Das Simulationsdesign der LV (@k06-simulation): $PP(G = 1) = 0.4$, wahre Anteile $theta_0 = 0.25$ und $theta_1 = 0.40$, also wahre Steigung $beta = 0.15$ und $theta = 0.6 dot 0.25 + 0.4 dot 0.40 = 0.31$. Das LLM hat in Gruppe 0 Sensitivität 0.90 und Falsch-positiv-Rate 0.10, in Gruppe 1 dagegen 0.70 und 0.15. Dann ist
  $ EE[hat(Y) | G = 0] = 0.90 dot 0.25 + 0.10 dot 0.75 = 0.300, quad EE[hat(Y) | G = 1] = 0.70 dot 0.40 + 0.15 dot 0.60 = 0.370 . $
  Die naive Steigung ist $0.370 - 0.300 = 0.070$ statt $0.150$, der Effekt wird um 53 % unterschätzt. Der naive Gesamtanteil ist $0.6 dot 0.300 + 0.4 dot 0.370 = 0.328$ statt $0.31$. Die Simulation mit 2000 Wiederholungen bestätigt das: Verzerrung der naiven Steigung $-0.0799$, Überdeckung 0.000 (@k06-tab-exp1).
]

Allgemein gilt für ein LLM-Label als abhängige Variable in einer linearen Regression: Die Verzerrung des naiven Koeffizienten ist der Koeffizient der besten linearen Vorhersage des LLM-Fehlers $Delta = hat(Y) - Y$ aus den Kovariaten. Ludwig et al. formulieren das als eigene Proposition @ludwig2026large[Abschn. 4.3]. Die Herleitung ist eine Zeile: Wegen der Linearität von OLS ist $EE[W W^top]^(-1) EE[W hat(Y)] = EE[W W^top]^(-1) EE[W Y] + EE[W W^top]^(-1) EE[W Delta]$. Der naive Koeffizient ist also genau dann unverzerrt, wenn der Fehler mit keiner Kovariate linear zusammenhängt. Egami et al. bringen das auf die Formel, Plug-in sei nur gültig, wenn die Messfehler zufällig und bedingt auf die Kovariaten mittelwertfrei sind, was in der Praxis "rarely the case" sei @egami2023using[Abschn. 3].

=== LLM-Label als erklärende Variable: Abschwächungsbias

Geht das LLM-Label als Regressor ein, etwa die Stimmung eines Texts als Prädiktor für die Zahl der Antworten, ändert sich die Mechanik. Für einen stetigen Regressor mit klassischem Messfehler ist das Ergebnis aus der Ökonometrie bekannt; wir leiten es kurz her, weil es die Intuition für den binären Fall liefert.

#satz(titel: [Abschwächung durch klassischen Messfehler im Regressor])[
  Sei $Y = alpha + beta X + epsilon$ mit $Cov(X, epsilon) = 0$, und beobachtet werde $X^* = X + U$ mit $U$ unabhängig von $X$ und $epsilon$, $EE[U] = 0$. Dann konvergiert der OLS-Koeffizient von $Y$ auf $X^*$ gegen
  $ beta^* = beta dot Var(X) / (Var(X) + Var(U)) . $ <k06-eq-atten>
]
#beweis[
  Der OLS-Grenzwert ist $Cov(Y, X^*) slash Var(X^*)$. Es gilt $Cov(Y, X^*) = Cov(alpha + beta X + epsilon, X + U) = beta Var(X)$, weil alle übrigen Kovarianzen null sind, und $Var(X^*) = Var(X) + Var(U)$.
]

Der Faktor heißt Reliabilitätsquotient. Er liegt zwischen 0 und 1, der Effekt wird also zur Null hin gezogen. Bei $Var(X) = 1$ und $Var(U) = 0.25$ bleiben 80 % des Effekts übrig. Für einen binären Regressor ist der Fehler nicht klassisch, weil er mit dem wahren Wert korreliert (aus einer 1 kann nur eine 0 werden). Die Abschwächung lässt sich dennoch exakt angeben.

#satz(titel: [Misklassifizierter binärer Regressor])[
  Sei $EE[Y | X] = alpha + beta X$ mit binärem $X$, und das beobachtete $X^*$ sei nicht differenziell misklassifiziert, also $EE[Y | X, X^*] = EE[Y | X]$. Dann ist die naive Steigung
  $ beta^* = EE[Y | X^* = 1] - EE[Y | X^* = 0] = beta ("PPV" + "NPV" - 1), $ <k06-eq-ppvnpv>
  mit dem positiven und negativen Vorhersagewert $"PPV" = PP(X = 1 | X^* = 1)$ und $"NPV" = PP(X = 0 | X^* = 0)$.
]
#beweis[
  Nach Annahme ist $EE[Y | X^*] = EE[EE[Y | X] | X^*] = alpha + beta PP(X = 1 | X^*)$. Also $beta^* = beta [PP(X = 1 | X^* = 1) - PP(X = 1 | X^* = 0)] = beta ["PPV" - (1 - "NPV")]$.
]

#beispiel(titel: [Abschwächung trotz 90 % Genauigkeit])[
  Prävalenz $PP(X = 1) = 0.3$, Sensitivität und Spezifität je 0.9. Dann $PP(X^* = 1) = 0.9 dot 0.3 + 0.1 dot 0.7 = 0.34$, $"PPV" = 0.27 slash 0.34 = 0.794$, $"NPV" = 0.63 slash 0.66 = 0.955$. Der Abschwächungsfaktor ist $0.794 + 0.955 - 1 = 0.749$: Ein Viertel des Effekts verschwindet, obwohl der Klassifikator in 90 % der Fälle richtig liegt. Bei selteneren Kategorien sinkt der PPV und die Abschwächung wird stärker.
]

Fong und Tyler zeigen in Simulationen, dass genau dieser Fall in der Praxis groß ausfällt: Ein Klassifikator mit 72 % Genauigkeit erzeugt bei $n_p = 10^6$ Dokumenten eine naive Verzerrung von etwa $-0.56$ bei einer Überdeckung von 0.00 @fong2021machine[Tab. 1]. Ihre Korrektur, eine GMM-Kombination aus OLS auf den gelabelten Daten und einer Instrumentvariablenschätzung, behandeln wir in @k06-debatten.

=== Mehr Daten verschlimmern das Problem

Für Forschende aus der Big-Data-Tradition ist der folgende Punkt am schwersten zu akzeptieren. Das Lehrbuch warnt, dass große Stichproben jede triviale Abweichung "signifikant" machen @haindl2027research. Bei LLM-Labels kommt eine schärfere Variante hinzu: Große Stichproben machen eine falsche Schätzung präzise. Nach @k06-eq-coverage hängt die Überdeckung nur von $k = b slash s$ ab. Beim Plug-in-Anteil ist $s = sqrt(EE[hat(Y)](1 - EE[hat(Y)]) slash N)$, also wächst $k$ proportional zu $sqrt(N)$.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 9.5
    let H = 4.0
    // log10 N von 2 bis 6
    let lx(n) = (calc.log(n, base: 10) - 2) / 4 * W
    let Y(y) = y * H
    k6achsen(W, H, (), (0, 0.25, 0.5, 0.75, 1.0), yl: [Überdeckung], yfmt: v => str(v))
    for (n, lab) in ((100, [$10^2$]), (1000, [$10^3$]), (10000, [$10^4$]), (100000, [$10^5$]), (1000000, [$10^6$])) {
      line((lx(n), 0), (lx(n), -0.08), stroke: 0.6pt + c-dark)
      content((lx(n), -0.3), k6t(lab))
    }
    content((W / 2, -0.78), k6t[Zahl der LLM-Labels $N$ (logarithmisch)])
    line((0, Y(0.95)), (W, Y(0.95)), stroke: (paint: c-dark, thickness: 0.7pt, dash: "dashed"))
    content((W - 0.05, Y(0.95) + 0.18), anchor: "east", k6t[nominell 0.95])
    // Werte vorab mit Python (scipy.stats.norm) aus Gl. k06-eq-coverage berechnet
        let pts = ((100, 0.9330), (150, 0.9244), (200, 0.9157), (300, 0.8981), (500, 0.8625), (700, 0.8264), (1000, 0.7719), (1500, 0.6823), (2000, 0.5968), (3000, 0.4443), (4000, 0.3210), (5000, 0.2263), (7000, 0.1061), (10000, 0.0305), (15000, 0.0031), (20000, 0.0003), (30000, 0.0), (100000, 0.0), (1000000, 0.0))
    line(..pts.map(p => (lx(p.at(0)), Y(p.at(1)))), stroke: (paint: c-red, thickness: 1.4pt))
    circle((lx(10000), Y(0.0305)), radius: 0.07, fill: c-red, stroke: none)
    content((lx(10000) + 0.15, Y(0.0305) + 0.35), anchor: "west", text(font: "Inter", size: 7pt, fill: c-red)[$N = 10^4$: 0.03 (Simulation: 0.026)])
  }),
  caption: [Überdeckung des naiven 95-%-Intervalls für einen Anteil in Abhängigkeit von der Zahl der LLM-Labels, berechnet mit @k06-eq-coverage für eine feste Verzerrung $b = 0.018$ und $EE[hat(Y)] = 0.328$ (Design aus @k06-simulation). Bei wenigen hundert Labels verdeckt die Stichprobenstreuung die Verzerrung noch, ab einigen tausend dominiert sie.],
) <k06-fig-bigdata>

@k06-fig-bigdata zeigt das für das Simulationsdesign der LV. Bei 300 LLM-Labels überdeckt das naive Intervall noch zu knapp 90 %, bei 3000 zu 44 %, bei 10 000 zu 3 %, darüber praktisch nie. Fong und Tyler halten diesen Punkt explizit fest: Ein großes $n_p$ macht die naive Überdeckung schlechter, nicht besser @fong2021machine[Tab. 1-2]. Für LLM-Projekte, deren ganzer Reiz darin besteht, sehr viele Einheiten billig zu labeln, ist das die zentrale Warnung.

#fallstrick[
  "Unsere Stichprobe ist so groß, dass Messfehler keine Rolle spielen" ist bei systematischen Fehlern genau verkehrt herum. Zufälliges Rauschen mittelt sich heraus, Verzerrung nicht. Je größer $N$, desto sicherer ist das Plug-in-Intervall falsch.
]

#hoersaal([Wenn der Fehler bei 85 % Genauigkeit nur 1.8 Prozentpunkte beträgt, ist das doch praktisch irrelevant?], [Die Verzerrung beträgt 1.8 Prozentpunkte, relativ zum wahren Anteil von 31 % also knapp 6 %. Ob das inhaltlich relevant ist, hängt von der Fragestellung ab. Statistisch irrelevant ist es nicht: Bei 10 000 Labels ist der Standardfehler 0.0047, die Verzerrung beträgt 3.8 Standardfehler, und das Intervall überdeckt den wahren Wert praktisch nie. Bei Gruppenvergleichen kann ein differenzieller Fehler zudem den halben Effekt wegnehmen, wie das Beispiel oben zeigt. Die ehrliche Antwort lautet daher: Du weißt ohne Goldstichprobe nicht, wie groß der Fehler ist, und die Korrektur kostet dich wenig.])

== Prediction-Powered Inference für den Mittelwert <k06-ppi-mittel>

Jetzt die Lösung. PPI wurde 2023 von Angelopoulos, Bates, Fannjiang, Jordan und Zrnic in _Science_ vorgestellt @angelopoulos2023prediction. Die Idee ist so einfach, dass man sie fast übersieht: Schätze den Mittelwert aus den vielen LLM-Labels und korrigiere ihn um den mittleren Fehler des LLM, gemessen auf der Goldstichprobe.

=== Setting und Annahmen

#definition(titel: [PPI-Setting])[
  Gegeben sind gelabelte Daten $(X_1, Y_1), dots, (X_n, Y_n)$ und ungelabelte Merkmale $tilde(X)_1, dots, tilde(X)_N$, alle unabhängig und identisch verteilt aus derselben Verteilung $P$, typischerweise mit $N >> n$. Eine *feste* Vorhersageregel $f$ (hier: LLM plus Prompt) liefert $f(X_i)$ und $f(tilde(X)_i)$. Die Regel darf nicht auf den gelabelten Daten angepasst worden sein, die für die Inferenz verwendet werden @angelopoulos2023prediction[Abschn. 1.1-1.2]. Das Schätzziel ist $theta^star = EE[Y]$.
]

Zwei Annahmen tragen alles. Die erste ist die *gemeinsame Verteilung*: Die Goldstichprobe muss eine Zufallsstichprobe aus derselben Population sein wie die ungelabelten Daten. Wer zuerst die "interessanten" oder "unklaren" Fälle codieren lässt, verletzt sie. Die zweite ist die *Unabhängigkeit von $f$*: Prompt und Modell müssen feststehen, bevor die Goldstichprobe für die Inferenz verwendet wird. Wer den Prompt an genau diesen Goldlabels optimiert, verletzt sie. Über die Güte von $f$ wird nichts angenommen.

=== Der Schätzer

Zerlege das Schätzziel in zwei Teile:
$ theta^star = EE[Y] = underbrace(EE[f(X)], "LLM-Mittel") - underbrace(EE[f(X) - Y], "Rektifikator" Delta) . $ <k06-eq-zerlegung>
Das ist eine Tautologie, aber eine nützliche. Der erste Term hängt nur von LLM-Labels ab und lässt sich auf den $N$ ungelabelten Einheiten sehr genau schätzen. Der zweite Term, der *Rektifikator* (_rectifier_), ist die mittlere Verzerrung des LLM und lässt sich auf den $n$ gelabelten Einheiten schätzen @angelopoulos2023prediction[Abschn. 2.1]. Ersetzt man beide Erwartungswerte durch Stichprobenmittel, erhält man den PPI-Schätzer.

#definition(titel: [PPI-Schätzer für den Mittelwert])[
  $ hat(theta)^"PP" = underbrace(1/N sum_(i=1)^N f(tilde(X)_i), tilde(theta)^f) - underbrace(1/n sum_(i=1)^n (f(X_i) - Y_i), hat(Delta)) $ <k06-eq-ppi>
  mit dem Konfidenzintervall @angelopoulos2023prediction[Alg. 1]
  $ C_alpha^"PP" = [hat(theta)^"PP" plus.minus z_(1 - alpha slash 2) sqrt(hat(sigma)_(f - Y)^2 / n + hat(sigma)_f^2 / N)], $ <k06-eq-ppi-ci>
  $ hat(sigma)_f^2 = 1/N sum_(i=1)^N (f(tilde(X)_i) - tilde(theta)^f)^2, quad hat(sigma)_(f - Y)^2 = 1/n sum_(i=1)^n (f(X_i) - Y_i - hat(Delta))^2 . $
]

Umgeschrieben lautet der Schätzer $hat(theta)^"PP" = overline(Y)_n + (tilde(theta)^f - overline(f)_n)$: Das Goldmittel wird um die Differenz zwischen dem LLM-Mittel auf allen ungelabelten und dem LLM-Mittel auf den gelabelten Einheiten verschoben. Wenn die Goldstichprobe zufällig ein paar Prozent zu viele positive Fälle enthält, merkt man das an $overline(f)_n > tilde(theta)^f$ und korrigiert entsprechend nach unten. Diese Lesart ist der Schlüssel zu PPI++ und zur Kontrollvariablen-Interpretation in @k06-ppipp.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 11.0
    let X(x) = (x - 0.26) / 0.10 * W
    line((X(0.26), 0), (X(0.36), 0), stroke: 0.7pt + c-dark)
    for v in (0.26, 0.28, 0.30, 0.32, 0.34, 0.36) {
      line((X(v), 0), (X(v), -0.08), stroke: 0.6pt + c-dark)
      content((X(v), -0.3), k6t(str(v)))
    }
    // Werte: theta=0.31, LLM-Mittel 0.328, Gold-Mittel z.B. 0.302, LLM auf Gold 0.320
    let pkt(x, y, col) = circle((X(x), y), radius: 0.09, fill: col, stroke: none)
    line((X(0.31), -0.05), (X(0.31), 3.3), stroke: (paint: c-dark, thickness: 0.7pt, dash: "dashed"))
    content((X(0.31), 3.45), k6t[wahrer Wert $theta^star = 0.31$])
    // Zeile 1: LLM-Mittel und Verschiebung
    pkt(0.328, 2.6, c-blue)
    content((X(0.328) + 0.2, 2.6), anchor: "west", text(font: "Inter", size: 7pt, fill: c-blue)[$tilde(theta)^f = 0.328$ (LLM-Mittel über $N$ Einheiten)])
    line((X(0.328), 2.2), (X(0.3115), 2.2), stroke: (paint: c-teal, thickness: 1.3pt), mark: (end: "stealth", fill: c-teal, scale: 0.7))
    pkt(0.310, 2.2, c-teal)
    content((X(0.328) + 0.2, 2.2), anchor: "west", text(font: "Inter", size: 7pt, fill: c-teal.darken(10%))[$hat(theta)^"PP" = 0.328 - 0.018 = 0.310$])
    // Zeile 2: Goldstichprobe
    pkt(0.320, 1.1, c-accent)
    pkt(0.302, 1.1, c-accent)
    content((X(0.320) + 0.2, 1.1), anchor: "west", text(font: "Inter", size: 7pt, fill: c-accent.darken(10%))[$overline(f)_n = 0.320$ (LLM auf Gold)])
    content((X(0.302) - 0.2, 1.1), anchor: "east", text(font: "Inter", size: 7pt, fill: c-accent.darken(10%))[$overline(Y)_n = 0.302$ (Gold)])
    line((X(0.320), 0.7), (X(0.303), 0.7), stroke: (paint: c-accent, thickness: 1pt), mark: (end: "stealth", fill: c-accent, scale: 0.6))
    content((X(0.320) + 0.2, 0.7), anchor: "west", text(font: "Inter", size: 6.8pt, fill: c-accent.darken(10%))[$hat(Delta) = 0.320 - 0.302 = 0.018$])
  }),
  caption: [Der Rektifikator als Verschiebung. Das LLM-Mittel über alle ungelabelten Einheiten (blau) ist präzise, aber verzerrt. Auf der Goldstichprobe (orange) misst man den mittleren LLM-Fehler $hat(Delta) = overline(f)_n - overline(Y)_n$ und verschiebt das LLM-Mittel um genau diesen Betrag. Illustrative Zahlen im Simulationsdesign.],
) <k06-fig-rektifikator>

=== Unverzerrtheit

#satz(titel: [Unverzerrtheit von PPI])[
  Unter den Annahmen des PPI-Settings gilt $EE[hat(theta)^"PP"] = theta^star$ für jedes feste $f$ und alle $n, N >= 1$.
]
#beweis[
  Weil $f$ fest ist und die $tilde(X)_i$ aus $P$ stammen, gilt $EE[tilde(theta)^f] = EE[f(X)]$. Weil die $(X_i, Y_i)$ aus derselben Verteilung $P$ stammen, gilt $EE[hat(Delta)] = EE[f(X)] - EE[Y]$. Also $EE[hat(theta)^"PP"] = EE[f(X)] - EE[f(X)] + EE[Y] = theta^star$. Die Qualität von $f$ geht nirgends ein; sie fällt durch die Differenz heraus.
]

Der Beweis zeigt auch, wo die Annahmen gebraucht werden. Stammen gelabelte und ungelabelte Einheiten aus verschiedenen Verteilungen, sind die beiden Erwartungswerte von $f$ nicht mehr gleich, und die Differenz fällt nicht heraus. Wurde $f$ auf den gelabelten Daten angepasst, ist $EE[f(X_i) | "Trainingsdaten"]$ für gelabelte Einheiten systematisch anders als für neue, und $hat(Delta)$ unterschätzt den Fehler auf den ungelabelten Daten. Genau diese Überanpassung des Rektifikators ist der Grund, warum man den Prompt nicht auf der Goldstichprobe tunen darf.

=== Varianz

#satz(titel: [Varianz von PPI])[
  Mit $sigma_f^2 = Var(f(X))$ und $sigma_(f - Y)^2 = Var(f(X) - Y)$ gilt
  $ Var(hat(theta)^"PP") = sigma_f^2 / N + sigma_(f - Y)^2 / n . $ <k06-eq-ppi-var>
]
#beweis[
  $tilde(theta)^f$ hängt nur von den ungelabelten, $hat(Delta)$ nur von den gelabelten Daten ab. Beide Stichproben sind unabhängig, also addieren sich die Varianzen. Jede ist die Varianz eines Stichprobenmittels unabhängiger Größen: $Var(tilde(theta)^f) = sigma_f^2 slash N$ und $Var(hat(Delta)) = sigma_(f - Y)^2 slash n$.
]

Vergleiche mit dem klassischen Schätzer $overline(Y)_n$, dessen Varianz $sigma_Y^2 slash n$ ist. Für $N >> n$ ist der erste Term in @k06-eq-ppi-var vernachlässigbar, und PPI ist genau dann besser, wenn $sigma_(f - Y)^2 < sigma_Y^2$, wenn also die *Fehler* des LLM weniger streuen als die Labels selbst @angelopoulos2023prediction[Abschn. 1.3]. Für binäre Labels lässt sich $sigma_(f - Y)^2$ gut interpretieren: $f - Y in {-1, 0, 1}$, $EE[(f - Y)^2] = PP(f eq.not Y)$, also
$ sigma_(f - Y)^2 = PP(f eq.not Y) - Delta^2 . $ <k06-eq-fehlervar>
Die Fehlervarianz ist im Wesentlichen die Fehlerrate. Ein LLM mit 85 % Genauigkeit hat $sigma_(f - Y)^2 approx 0.14$, ein Label mit Prävalenz 0.31 hat $sigma_Y^2 = 0.214$. PPI spart dann etwa ein Drittel der Varianz. Bei Prävalenz 0.05 ist $sigma_Y^2 = 0.0475$, und dasselbe LLM wäre schlechter als die Goldlabels allein. Bei seltenen Kategorien muss das LLM also sehr viel genauer sein, damit sich PPI lohnt.

=== Asymptotisches Konfidenzintervall

#satz(titel: [Asymptotische Gültigkeit])[
  Für $n, N -> infinity$ gilt $(hat(theta)^"PP" - theta^star) slash sqrt(hat(sigma)_f^2 slash N + hat(sigma)_(f - Y)^2 slash n) limits(arrow.r)^d cal(N)(0, 1)$ und damit $liminf PP(theta^star in C_alpha^"PP") >= 1 - alpha$ @angelopoulos2023prediction[Prop. 1].
]
#beweis[
  Nach dem zentralen Grenzwertsatz sind $tilde(theta)^f$ und $hat(Delta)$ je asymptotisch normal; wegen Unabhängigkeit ist es auch ihre Differenz, mit Varianz @k06-eq-ppi-var. Die Varianzschätzer $hat(sigma)_f^2$ und $hat(sigma)_(f - Y)^2$ sind konsistent, Slutsky erlaubt das Einsetzen. Formal braucht man, dass $n slash N$ konvergiert oder dass man auf die Summe der Varianzen normiert; die Details stehen im Anhang des Originalaufsatzes.
]

Die Garantie ist asymptotisch. Bei sehr kleinen Goldstichproben, etwa $n = 50$ mit einem seltenen Label, solltest du die Überdeckung per Simulation prüfen oder auf Bootstrap-Varianten ausweichen @zrnic2024note @kluger2025prediction.

#beispiel(titel: [PPI von Hand])[
  Setting wie in der Simulation (@k06-simulation): wahre Prävalenz $theta = 0.31$, LLM-Prävalenz $EE[hat(Y)] = 0.328$ (Verzerrung $+0.018$), Fehlerrate $PP(hat(Y) eq.not Y) = 0.144$ (Genauigkeit 85.6 %), $n = 500$ Goldlabels, $N = 9500$ nur LLM-gelabelte Einheiten, $alpha = 0.05$. Wir rechnen mit Populationswerten, wie es ein Planungsrechner tun würde.

  1. *Klassisch:* $Var(Y) = 0.31 dot 0.69 = 0.2139$, $se = sqrt(0.2139 slash 500) = 0.02068$, Breite $2 dot 1.96 dot 0.02068 = 0.0811$.
  2. *Naiv* auf allen 10 000 LLM-Labels: $se = sqrt(0.328 dot 0.672 slash 10 thin 000) = 0.0047$, Breite 0.0184, zentriert bei 0.328. Die Verzerrung beträgt 3.8 Standardfehler; das Intervall überdeckt 0.31 fast nie.
  3. *PPI:* Nach @k06-eq-fehlervar ist $Var(Y - hat(Y)) = 0.144 - 0.018^2 = 0.14368$, ferner $Var(hat(Y)) = 0.328 dot 0.672 = 0.2204$. Also $se = sqrt(0.14368 slash 500 + 0.2204 slash 9500) = 0.01762$ und Breite 0.0691, 15 % schmaler als klassisch.

  Alle drei Breiten stimmen mit den mittleren Breiten der Simulation über 2000 Wiederholungen auf drei Nachkommastellen überein (@k06-tab-exp1). PPI++ verbessert das noch, wie wir in @k06-ppipp sehen.
]

#praxis[
  In einem realen Projekt liegen dir keine Populationswerte vor, sondern fünf Stichprobenkennzahlen (neben $n$ und $N$): das LLM-Mittel auf den ungelabelten Einheiten, das LLM-Mittel und das Goldmittel auf der Goldstichprobe sowie die beiden Varianzen. Für die Rechnung von Hand genügen diese fünf Zahlen. Eine entsprechende Aufgabe mit Lösung findest du im Selbsttest am Kapitelende.
]

=== Was PPI in Anwendungen spart

Die Einsparungen hängen stark von der Güte der Vorhersagen ab. Der PPI-Aufsatz vergleicht, wie viele gelabelte Beispiele für dieselbe inferenzielle Schlussfolgerung nötig sind (@k06-tab-ppi-savings).

#figure(
  table(columns: (2.6fr, 1fr, 1fr, 1fr),
    table.header([Anwendung], [PPI $n$], [klassisch $n$], [Ersparnis]),
    [Proteomik (AlphaFold)], [316], [799], [60 %],
    [Galaxienklassifikation], [189], [449], [58 %],
    [Abholzung Amazonas], [21], [35], [40 %],
    [Einkommen (Kovariatenverschiebung)], [177], [282], [37 %],
    [Genexpression], [764], [900], [15 %],
    [Krankenversicherung (Zensus)], [5569], [6653], [16 %],
  ),
  caption: [Benötigte Zahl gelabelter Beispiele für dieselbe Schlussfolgerung, PPI gegenüber klassischer Inferenz, nach @angelopoulos2023prediction[Tab. 2]. Die Ersparnis ist $1 - n_"PPI" slash n_"klassisch"$, gerundet.],
) <k06-tab-ppi-savings>

Die Spannweite von 15 bis 60 % ist die ehrliche Botschaft. Spektakuläre Zahlen entstehen dort, wo die Vorhersagen sehr gut sind. Bei mittelmäßigen Vorhersagen ist der Gewinn bescheiden, und PPI mit festem Gewicht kann sogar schaden. Die Autoren berichten in Stresstests, dass mit einem linearen Modell statt Boosting-Bäumen die klassische Inferenz $n = 35$ brauchte, PPI dagegen $n = 40$, und mit nur $N = 1000$ ungelabelten Punkten klassisch $n = 652$ gegenüber $n = 869$ für PPI. Ihr Fazit: PPI "should only be applied when N is (preferably substantially) larger than n" @angelopoulos2023prediction[Anh. G.1-G.3].

#studie(titel: [Angelopoulos et al. 2023])[
  *Design:* Methodenaufsatz in _Science_ mit sieben Anwendungen: AlphaFold-basierte Proteomik (10 803 Reste), Galaxienklassifikation (1 364 122 Bilder), Genexpression (61 150 Promotoren), Abholzung (1596 Labels), Zensus-Krankenversicherung (378 817 Personen), Einkommen unter Kovariatenverschiebung und Planktonzählung unter Label-Verschiebung @angelopoulos2023prediction[Abschn. 3, Tab. 2]. *Befund:* Gültige Intervalle für Mittelwerte, Quantile, lineare und logistische Regressionskoeffizienten ohne Annahmen über den Prädiktor; Einsparungen von 15 bis 60 % gegenüber klassischer Inferenz (@k06-tab-ppi-savings); die Imputationsintervalle enthalten den wahren Wert in den gezeigten Anwendungen nicht. *Grenzen:* nur asymptotische Gültigkeit der CLT-Intervalle, i.i.d.-Annahme ohne explizite Modellierung von Verschiebungen, Effizienzverlust gegenüber klassischer Inferenz bei schwachen Vorhersagen oder kleinem $N$ @angelopoulos2023prediction[Abschn. 1.2, Anh. G].
]

#hoersaal([Warum nicht einfach nur die Goldlabels verwenden, wenn PPI oft nur 15 % spart?], [Weil die Goldlabels das Teure sind. 15 % weniger Expertenlabels können in einem Projekt mit Fachannotation mehrere Personentage bedeuten. Wichtiger ist aber die Gegenfrage: Wer nur Goldlabels verwendet, braucht die LLM-Labels überhaupt nicht und sollte das dann auch so berichten. Wer LLM-Labels berichtet, muss sie korrigieren. PPI ist der Weg, beides konsistent zu verbinden. Mit PPI++ (@k06-ppipp) verlierst du asymptotisch nie gegenüber der Goldstichprobe allein, du riskierst also nichts außer ein wenig Rechenaufwand.])

== PPI für Regression und allgemeine M-Schätzer <k06-ppi-reg>

Der Mittelwert ist der Spezialfall, an dem man die Idee versteht. In der Forschung interessieren Regressionskoeffizienten, Odds Ratios und Quantile. PPI verallgemeinert den Rektifikator dafür von einer Verschiebung des Werts auf eine Verschiebung des *Gradienten*.

=== Der Gradienten-Rektifikator

Für ein M-Schätzziel nach @k06-eq-mest mit Gradient $g_theta$ definiert PPI den Rektifikator als Funktion von $theta$ @angelopoulos2023prediction[Abschn. 2, Gl. 2]:
$ Delta_theta = EE[g_theta (X, Y) - g_theta (X, f(X))] . $ <k06-eq-gradrect>
Er misst, wie sehr sich der Gradient des Verlusts mit wahren Labels von dem mit LLM-Labels unterscheidet. Am Optimum gilt $EE[g_(theta^star)(X, Y)] = 0$, also
$ 0 = EE[g_(theta^star)(X, f(X))] + Delta_(theta^star) . $
Die Bedingung lässt sich aus zwei Stichproben schätzen: den ersten Term aus den $N$ ungelabelten Einheiten, den Rektifikator aus den $n$ gelabelten. Der allgemeine PPI-Konfidenzbereich ist die Menge aller $theta$, für die null in der Summe aus einem Konfidenzbereich für den Rektifikator und einem für den imputierten Gradienten liegt @angelopoulos2023prediction[Satz 1]. Für den Mittelwert mit $g_theta (y) = theta - y$ ist $Delta_theta = EE[f(X) - Y]$ unabhängig von $theta$, und wir erhalten @k06-eq-ppi zurück.

=== Lineare Regression

#definition(titel: [PPI-Schätzer für OLS])[
  Schätzziel ist $theta^star = arg min_theta EE[(Y - X^top theta)^2]$ @angelopoulos2023prediction[Gl. 6]. Mit den Designmatrizen $bold(X) in RR^(n times d)$ und $tilde(bold(X)) in RR^(N times d)$ und der Moore-Penrose-Pseudoinversen $A^dagger$ ist
  $ hat(theta)^"PP" = tilde(bold(X))^dagger f(tilde(bold(X))) - bold(X)^dagger (f(bold(X)) - bold(Y)), $ <k06-eq-ppi-ols>
  also der OLS-Fit der LLM-Labels auf den ungelabelten Daten minus dem OLS-Fit der LLM-*Fehler* auf den gelabelten Daten @angelopoulos2023prediction[Alg. 4].
]

Der Schätzer ist wieder eine Differenz zweier unabhängiger Größen, und die Varianz ist wieder die Summe zweier Sandwich-Terme:
$ C_alpha^"PP" = [hat(theta)_j^"PP" plus.minus z_(1 - alpha slash 2) sqrt(V_(j j) / n + tilde(V)_(j j) / N)], quad tilde(V) = tilde(Sigma)^(-1) tilde(M) tilde(Sigma)^(-1), quad V = Sigma^(-1) M Sigma^(-1), $ <k06-eq-ppi-ols-ci>
mit den normierten Gram-Matrizen $tilde(Sigma)$, $Sigma$ und den mit quadrierten imputierten Residuen beziehungsweise quadrierten Rektifikator-Residuen gewichteten äußeren Produkten $tilde(M)$, $M$ @angelopoulos2023prediction[Alg. 4, Prop. 4]. Das ist exakt die Sandwich-Formel @k06-eq-sandwich, einmal für die Regression der LLM-Labels und einmal für die Regression der LLM-Fehler.

#beweis[
  Linearität von OLS: $tilde(bold(X))^dagger f(tilde(bold(X))) -> EE[X X^top]^(-1) EE[X f(X)]$ und $bold(X)^dagger (f(bold(X)) - bold(Y)) -> EE[X X^top]^(-1) EE[X (f(X) - Y)]$. Die Differenz konvergiert gegen $EE[X X^top]^(-1) EE[X Y] = theta^star$. Asymptotische Normalität folgt für jeden Summanden aus @k06-eq-sandwich, die Unabhängigkeit der Stichproben liefert die Summe der Kovarianzen.
]

#beispiel(titel: [Gruppenunterschied korrigieren])[
  Im Simulationsdesign ist der Regressor $(1, G)$ und die Steigung die Differenz der Gruppenmittel. Auf den Populationswerten: Der OLS-Fit der LLM-Labels auf $G$ hat die Steigung $0.370 - 0.300 = 0.070$. Der LLM-Fehler $f - Y$ hat in Gruppe 0 den Mittelwert $0.300 - 0.25 = 0.050$ und in Gruppe 1 den Mittelwert $0.370 - 0.40 = -0.030$; die Steigung des Fehlers auf $G$ ist $-0.080$. Nach @k06-eq-ppi-ols ist $hat(theta)^"PP"_1 = 0.070 - (-0.080) = 0.150$, der wahre Wert. In der Simulation hat PPI für die Steigung eine Verzerrung von $-0.0006$ und eine Überdeckung von 0.945 (@k06-tab-exp1).
]

=== Die ökonometrische Formulierung

Ludwig, Mullainathan und Rambachan formulieren denselben Schätzer in ökonometrischer Notation @ludwig2026large[Abschn. 4.3, Gl. 14]:
$ hat(beta)_"debiased" = hat(beta) - hat(lambda)_(Delta | W) . $ <k06-eq-ludwig>
Dabei ist $hat(beta)$ der OLS-Koeffizient des LLM-Labels auf die Kovariaten $W$ in der Primärstichprobe und $hat(lambda)_(Delta | W)$ der OLS-Koeffizient des LLM-Fehlers $Delta$ (LLM-Label minus menschliches Label) auf $W$ in der Validierungsstichprobe. Die Inferenz erfolgt per Bootstrap. Das ist @k06-eq-ppi-ols mit anderen Buchstaben. In ihrer Simulation mit 250 Validierungslabels aus 5000 Gesetzesvorlagen (1000 simulierte Datensätze) ist der entzerrte Schätzer annähernd unverzerrt, hat ungefähr korrekte 95-%-Überdeckung und in jedem Fall einen kleineren MSE als die Schätzung nur aus den Validierungsdaten; mit 125 Validierungslabels sind die Ergebnisse ähnlich @ludwig2026large[Abschn. 4.3, Anh. D.1].

#studie(titel: [Ludwig, Mullainathan und Rambachan 2026])[
  *Design:* Rahmenwerk für den Einsatz von LLM-Ausgaben in der empirischen Ökonomie, erschienen im _Annual Review of Economics_ @ludwig2026large. Unterscheidung von Vorhersageproblemen (gültig nur ohne Trainingsleck) und Schätzproblemen (brauchen Validierungsdaten und Entzerrung). Anwendungen: Gesetzesvorlagen des US-Kongresses und rund vier Millionen Finanznachrichten-Schlagzeilen @ludwig2026large[Abschn. 3.2.1, 4.2.1]. *Befund:* GPT-4o sagt das Zustandekommen von Gesetzen mit 91.2 % (House) und 92.5 % (Senate) Genauigkeit vorher und reproduziert 344 Beschreibungen wörtlich, auch mit einem Prompt, der das Wissen auf ein Datum beschränken soll, noch 330: ein Hinweis auf Trainingsleck @ludwig2026large[Abschn. 3.2.1]. Für Schätzprobleme empfehlen sie Validierungsstichproben und Entzerrung; in der veröffentlichten Fassung heißt es, Validierungsstichproben mit "as few as 125-250 text pieces" hätten deutlich geholfen, die optimale Größe sei eine Designentscheidung. *Grenzen:* Bei geschlossenen Modellen sind die Trainingsdaten unbekannt, Leck lässt sich nicht ausschließen @ludwig2026large[Abschn. 3.3]. Hinweis: Abschnittsnummern hier nach der arXiv-Fassung v4; in der Zeitschriftenfassung steht Gl. 14 in Abschn. 4.4.1.
]

=== Logistische Regression, Quantile und Kovariaten

Für die logistische Regression gibt es keine geschlossene Form; der PPI-Schätzer löst die korrigierte Schätzgleichung numerisch, und `ppi_py` stellt dafür `ppi_logistic_ci` bereit @angelopoulos2024ppipy. Für Quantile ist der Verlust die Check-Funktion, der Gradient eine Indikatorfunktion; `ppi_quantile_ci` implementiert das @angelopoulos2024ppipy. Wenn das LLM-Label nicht das Outcome, sondern eine Kovariate ist, deckt die allgemeine M-Schätz-Version von PPI auch imputierte Kovariaten ab @kluger2025prediction; die älteren Alternativen sind GMM mit Vorhersagen als Instrumenten @fong2021machine[Abschn. 3.4] und Maximum-Likelihood-Korrektur mit explizitem Fehlermodell @teblunthuis2024misclassification (@k06-debatten).

#merke[
  Für jede M-Schätzung lautet das PPI-Rezept: Schätzgleichung mit LLM-Labels auf den ungelabelten Daten, plus Korrektur um die Differenz der Gradienten mit wahren und mit LLM-Labels auf den gelabelten Daten. Für OLS heißt das konkret: Regressiere die LLM-Labels auf die Kovariaten, regressiere die LLM-Fehler auf die Kovariaten, ziehe ab.
]

== PPI++ und Power-Tuning <k06-ppipp>

PPI mit festem Gewicht 1 hat einen Schönheitsfehler: Ist das LLM schwach, kann die Korrektur mehr Rauschen hinzufügen, als sie Information beiträgt. PPI++ von Angelopoulos, Duchi und Zrnic behebt das mit einem Gewicht $lambda$, das sich an die Güte der Vorhersagen anpasst @angelopoulos2023ppi. Der Aufsatz ist ein Preprint ohne Zeitschriftenfassung (Stand: 11. November 2026), ist aber in `ppi_py` als Standard implementiert @angelopoulos2024ppipy.

=== Die gewichtete Verlustfunktion

#definition(titel: [PPI++])[
  Mit den drei empirischen Verlusten $L_n (theta) = 1/n sum_(i=1)^n ell_theta (X_i, Y_i)$ (Goldlabels), $L_n^f (theta) = 1/n sum_(i=1)^n ell_theta (X_i, f(X_i))$ (LLM-Labels auf den Goldeinheiten) und $L_N^f (theta) = 1/N sum_(i=1)^N ell_theta (tilde(X)_i, f(tilde(X)_i))$ (LLM-Labels auf den ungelabelten Einheiten) ist
  $ L_lambda^"PP" (theta) = L_n (theta) + lambda (L_N^f (theta) - L_n^f (theta)), quad hat(theta)_lambda^"PP" = arg min_theta L_lambda^"PP" (theta) . $ <k06-eq-ppipp-loss>
  $lambda = 1$ ergibt PPI, $lambda = 0$ die klassische Inferenz @angelopoulos2023ppi[Abschn. 2.2].
]

Für jedes feste $lambda$ ist der Klammerterm in Erwartung null, weil $L_N^f$ und $L_n^f$ denselben Erwartungswert haben. Die Verlustfunktion ist also für jedes $lambda$ ein unverzerrter Schätzer von $L(theta)$, und $lambda$ steuert nur die Varianz. Für den Mittelwert ergibt das @angelopoulos2023ppi[Bsp. 6.1]
$ hat(theta)_lambda^"PP" = overline(Y)_n + lambda (tilde(theta)^f - overline(f)_n) . $ <k06-eq-ppipp-mean>

Wer Survey-Statistik oder Monte-Carlo-Methoden kennt, erkennt die Form: Das ist ein *Kontrollvariablen-Schätzer* (_control variate_). $tilde(theta)^f - overline(f)_n$ ist eine Größe mit Erwartungswert null, die mit dem Fehler von $overline(Y)_n$ korreliert ist. Man addiert sie mit dem Gewicht, das die Varianz minimiert. Im Kontext randomisierter Experimente mit LLM-Vorhersagen ist PPI++ für einen Versuchsarm ebenfalls das gelabelte Mittel plus $lambda$ mal die Differenz der Vorhersagemittel, und bei $lambda = 1$ entspricht es dem GREG-Schätzer der Survey-Statistik @vanloon2026using.

=== Herleitung des optimalen $lambda$ für den Mittelwert

#satz(titel: [Varianz und optimales Gewicht])[
  Seien $sigma_Y^2 = Var(Y)$, $sigma_f^2 = Var(f(X))$, $c = Cov(Y, f(X))$ und $r = n slash N$. Dann gilt
  $ n Var(hat(theta)_lambda^"PP") = sigma_Y^2 - 2 lambda c + lambda^2 (1 + r) sigma_f^2, $ <k06-eq-varlambda>
  minimal für
  $ lambda^star = c / ((1 + r) sigma_f^2), $ <k06-eq-lamstar>
  mit der minimalen Varianz
  $ Var(hat(theta)_(lambda^star)^"PP") = sigma_Y^2 / n (1 - rho^2 N / (n + N)), quad rho = Corr(Y, f(X)) . $ <k06-eq-varmin>
]
#beweis[
  Schreibe $hat(theta)_lambda^"PP" = (overline(Y)_n - lambda overline(f)_n) + lambda tilde(theta)^f$. Die beiden Summanden stammen aus unabhängigen Stichproben. Der erste ist ein Mittel von $n$ unabhängigen Größen $Y_i - lambda f(X_i)$ mit Varianz $sigma_Y^2 - 2 lambda c + lambda^2 sigma_f^2$, der zweite hat Varianz $lambda^2 sigma_f^2 slash N$. Also
  $ Var = (sigma_Y^2 - 2 lambda c + lambda^2 sigma_f^2) / n + lambda^2 sigma_f^2 / N = 1/n [sigma_Y^2 - 2 lambda c + lambda^2 (1 + n/N) sigma_f^2] . $
  Das ist eine nach oben offene Parabel in $lambda$. Nullsetzen der Ableitung $-2c + 2 lambda (1 + r) sigma_f^2$ liefert @k06-eq-lamstar. Einsetzen ergibt $n Var = sigma_Y^2 - c^2 slash ((1 + r) sigma_f^2) = sigma_Y^2 (1 - rho^2 slash (1 + r))$ wegen $c^2 = rho^2 sigma_Y^2 sigma_f^2$. Schließlich ist $1 slash (1 + r) = N slash (N + n)$.
]

Das stimmt mit der Formel im PPI++-Aufsatz überein, wo $r = lim n slash N$ und der Plug-in-Schätzer
$ hat(lambda) = (hat(Cov)_n (Y_i, f(X_i))) / ((1 + n/N) hat(Var)_(N + n) (f(X_i))) $ <k06-eq-lamhat>
lautet @angelopoulos2023ppi[Bsp. 6.1]. Die Kovarianz wird auf den gelabelten Daten geschätzt, die Varianz der LLM-Labels auf allen $n + N$ Einheiten.

Aus @k06-eq-varlambda fallen drei Einsichten fast gratis heraus. *Erstens:* Mit $lambda^star$ ist die Varianz nie größer als $sigma_Y^2 slash n$, denn der Faktor $1 - rho^2 N slash (n + N)$ liegt in $[0, 1]$. PPI++ ist also asymptotisch nie schlechter als die klassische Inferenz @angelopoulos2023ppi[Zusammenfassung, Abschn. 6.1]. *Zweitens:* PPI mit $lambda = 1$ ist genau dann besser als klassisch, wenn $-2c + (1 + r) sigma_f^2 < 0$, also wenn
$ lambda^star > 1/2 . $ <k06-eq-halb>
Diese einfache Bedingung erklärt das Ergebnis der Simulation in @k06-tab-exp2: Bei 75 % Genauigkeit liegt das geschätzte $hat(lambda)$ im Mittel bei 0.42, und PPI ist 9 % breiter als klassisch; bei 85 % liegt es bei 0.61, und PPI ist 14 % schmaler. *Drittens:* Der Gewinn hängt nicht von der Genauigkeit an sich ab, sondern von der *Korrelation* $rho$ zwischen Gold- und LLM-Label.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 8.0
    let H = 4.4
    let X(x) = x / 1.2 * W
    let Y(y) = y / 1.8 * H
    k6achsen(W, H, (0, 0.25, 0.5, 0.75, 1.0), (0, 0.4, 0.8, 1.2, 1.6), xmax: 1.2, ymax: 1.8, xl: [Gewicht $lambda$], yl: [Varianz relativ zu klassisch])
    content((X(1.2), -0.28), k6t[1.2])
    line((X(0), Y(1)), (X(1.2), Y(1)), stroke: (paint: c-dark, thickness: 0.7pt, dash: "dashed"))
    let r = 0.05
    for (rho, col) in ((0.3, c-accent), (0.6, c-blue), (0.9, c-teal)) {
      let pts = range(0, 121).map(i => { let l = i / 100; (X(l), Y(1 - 2 * l * rho + l * l * (1 + r))) })
      line(..pts, stroke: (paint: col, thickness: 1.3pt))
      let ls = rho / (1 + r)
      let v = 1 - rho * rho / (1 + r)
      circle((X(ls), Y(v)), radius: 0.07, fill: col, stroke: none)
      content((X(1.2) + 0.1, Y(calc.min(1.75, 1 - 2 * 1.2 * rho + 1.44 * (1 + r)))), anchor: "west", text(font: "Inter", size: 7pt, fill: col)[$#sym.rho = #rho$])
    }
    line((X(1), 0), (X(1), H), stroke: (paint: c-grey, thickness: 0.6pt, dash: "dotted"))
    content((X(1), H + 0.12), anchor: "south", k6t[PPI])
  }),
  caption: [Varianz von PPI++ relativ zur klassischen Varianz (gestrichelt) als Funktion von $lambda$ nach @k06-eq-varlambda, für $sigma_f = sigma_Y$ und $n slash N = 0.05$. Punkte markieren $lambda^star$. Bei $rho = 0.3$ ist PPI ($lambda = 1$) deutlich schlechter als klassisch, das optimale Gewicht liegt nahe 0.3 und bringt nur 9 % Varianzreduktion; bei $rho = 0.9$ liegt $lambda^star$ bei etwa 0.86 und die Varianz sinkt auf etwa ein Viertel.],
) <k06-fig-lambda>

#beispiel(titel: [PPI++ von Hand])[
  Fortsetzung des Rechenbeispiels aus @k06-ppi-mittel. Die gemeinsame Wahrscheinlichkeit $PP(Y = 1, hat(Y) = 1) = 0.247$ ergibt $Cov(Y, hat(Y)) = 0.247 - 0.31 dot 0.328 = 0.247 - 0.1017 = 0.1453$ und $rho = 0.1453 slash sqrt(0.2139 dot 0.2204) = 0.669$. Mit $r = 500 slash 9500 = 0.0526$ ist nach @k06-eq-lamstar
  $ lambda^star = 0.1453 / (1.0526 dot 0.2204) = 0.626 . $
  Der Varianzfaktor ist $1 - 0.669^2 dot 9500 slash 10 thin 000 = 0.574$, die Breite also $0.0811 dot sqrt(0.574) = 0.0614$, 24 % schmaler als klassisch und deutlich schmaler als PPI mit 0.0691. Die Simulation liefert im Mittel genau 0.0614 (@k06-tab-exp1).
]

=== Effektive Stichprobengröße

#definition(titel: [Effektive Stichprobengröße])[
  Die *effektive Stichprobengröße* $n_"eff"$ eines Schätzers ist die Zahl von Goldlabels, die der klassische Schätzer bräuchte, um dieselbe Varianz zu erreichen. Für PPI++ mit $lambda^star$ folgt aus $sigma_Y^2 slash n_"eff" = Var(hat(theta)_(lambda^star)^"PP")$:
  $ n_"eff" = n / (1 - rho^2 N slash (n + N)) = (n (n + N)) / (n + (1 - rho^2) N) . $ <k06-eq-neff>
]

Genau diese Formel verwendet die Power-Analyse in `ppi_py` (im Quelltext als gerundeter Ausdruck mit `ppi_corr` an der Stelle von $rho$); die Korrelation `ppi_corr` ist allgemein die Korrelation der Verlustgradienten, die für den Mittelwert zu $Corr(Y, f)$ wird @angelopoulos2024ppipy. Die Definition der PPI-Korrelation, der effektiven Stichprobengröße für PPI und einer zugehörigen Power-Analyse geht auf Broska, Howes und van Loon zurück @broska2025mixed. Die Formel ist hier aus dem Quelltext von `ppi_py` übernommen, weil der Volltext dieses Aufsatzes für die Wissensbasis nicht geöffnet wurde.

#satz(titel: [Obere Schranke])[
  Für festes $n$ und $N -> infinity$ gilt $n_"eff" -> n slash (1 - rho^2)$.
]
#beweis[
  Teile Zähler und Nenner von @k06-eq-neff durch $N$: $n_"eff" = n (n slash N + 1) slash (n slash N + 1 - rho^2) -> n slash (1 - rho^2)$.
]

Die Schranke ist ernüchternd und wichtig. Bei $rho = 0.5$ kann ein unbegrenzter Vorrat an LLM-Labels höchstens 33 % mehr effektive Goldlabels bringen ($1.33 n$), bei $rho = 0.67$ höchstens 81 % ($1.81 n$), bei $rho = 0.9$ das 5.3-Fache. Große Gewinne erfordern also eine hohe Korrelation zwischen LLM- und Goldlabels, nicht bloß "gute Genauigkeit". Für ein binäres Label ist $rho$ der Phi-Koeffizient der Konfusionsmatrix, und der reagiert auf Prävalenz und Fehlerstruktur ganz anders als die Genauigkeit. Im Rechenbeispiel ist $n_"eff" = 500 slash 0.574 approx 870$, also das 1.74-Fache, nahe an der Schranke $1.81 n$, weil $N = 19 n$ schon groß ist (@k06-fig-neff).

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 8.4
    let H = 4.4
    // x: log10(N/n) von -1 bis 2
    let X(lq) = (lq + 1) / 3 * W
    let Y(y) = (y - 1) / 5 * H
    k6achsen(W, H, (), (1, 2, 3, 4, 5, 6), ymin: 1, ymax: 6, yl: [$n_"eff" slash n$], yfmt: v => str(v))
    for (q, lab) in ((0.1, [0.1]), (1, [1]), (10, [10]), (100, [100])) {
      let lq = calc.log(q, base: 10)
      line((X(lq), 0), (X(lq), -0.08), stroke: 0.6pt + c-dark)
      content((X(lq), -0.3), k6t(lab))
    }
    content((W / 2, -0.78), k6t[Verhältnis $N slash n$ (logarithmisch)])
    for (rho, col) in ((0.5, c-accent), (0.67, c-blue), (0.8, c-violet), (0.9, c-teal)) {
      let pts = range(0, 61).map(i => { let lq = -1 + i / 20; let q = calc.pow(10, lq); (X(lq), Y((1 + q) / (1 + (1 - rho * rho) * q))) })
      line(..pts, stroke: (paint: col, thickness: 1.3pt))
      let cap = 1 / (1 - rho * rho)
      line((X(-1), Y(cap)), (X(2), Y(cap)), stroke: (paint: col, thickness: 0.5pt, dash: "dashed"))
      content((X(2) + 0.1, Y(cap)), anchor: "west", text(font: "Inter", size: 7pt, fill: col)[$#sym.rho = #rho$: #calc.round(cap, digits: 2)])
    }
    circle((X(calc.log(19, base: 10)), Y(1.740)), radius: 0.07, fill: c-dark, stroke: none)
    line((X(calc.log(19, base: 10)), Y(1.740)), (X(calc.log(19, base: 10)) - 0.6, Y(3.4)), stroke: 0.5pt + c-dark)
    content((X(calc.log(19, base: 10)) - 0.6, Y(3.4) + 0.05), anchor: "south", k6t[Rechenbeispiel: 1.74])
  }),
  caption: [Effektive Stichprobengröße von PPI++ relativ zu $n$ nach @k06-eq-neff. Gestrichelt die Schranke $1 slash (1 - rho^2)$ für $N -> infinity$. Ab $N approx 10 n$ ist der Großteil des möglichen Gewinns erreicht; mehr LLM-Labels helfen dann kaum noch, eine höhere Korrelation dagegen sehr.],
) <k06-fig-neff>

#hoersaal([Lohnt es sich mehr, 200 zusätzliche Goldlabels zu kaufen oder den Prompt zu verbessern, sodass $rho$ von 0.6 auf 0.8 steigt?], [Rechne es mit @k06-eq-neff durch, für $N$ groß gegenüber $n$. Mit $n = 300$ und $rho = 0.6$ ist $n_"eff" approx 300 slash 0.64 = 469$; mit 200 zusätzlichen Goldlabels $500 slash 0.64 = 781$. Mit $n = 300$ und $rho = 0.8$ ist $n_"eff" approx 300 slash 0.36 = 833$. Die Prompt-Verbesserung bringt in diesem Beispiel etwas mehr, aber unter einer wichtigen Bedingung: Du darfst den Prompt nicht an den 300 Goldlabels optimiert haben, die du für die Inferenz verwendest. Dafür brauchst du eine separate Entwicklungsstichprobe, die ebenfalls Goldlabels kostet.])

=== Die allgemeine Form und das Clipping in `ppi_py`

Für allgemeine M-Schätzer ist die asymptotische Kovarianz von PPI++ @angelopoulos2023ppi[Satz 1, Gl. 7]
$ sqrt(n)(hat(theta)_hat(lambda)^"PP" - theta^star) limits(arrow.r)^d cal(N)(0, Sigma_lambda), quad Sigma_lambda = H^(-1) (r V_f^lambda + V_Delta^lambda) H^(-1), $ <k06-eq-ppipp-sigma>
mit $V_f^lambda = lambda^2 Cov(nabla ell^f_(theta^star))$ und $V_Delta^lambda = Cov(nabla ell_(theta^star) - lambda nabla ell^f_(theta^star))$. Das Konfidenzintervall für Koordinate $j$ ist $hat(theta)_j plus.minus z_(1 - alpha slash 2) sqrt(hat(Sigma)_(j j) slash n)$. Das optimale $lambda$ minimiert die Spur der Kovarianz @angelopoulos2023ppi[Prop. 2]:
$ lambda^star = (op("Tr")(H^(-1) (Cov(nabla ell, nabla ell^f) + Cov(nabla ell^f, nabla ell)) H^(-1))) / (2 (1 + r) op("Tr")(H^(-1) Cov(nabla ell^f) H^(-1))) . $ <k06-eq-lamstar-gen>
Für den Mittelwert ist $H = 1$, die Gradienten sind proportional zu $Y - theta$ und $f - theta$, und @k06-eq-lamstar-gen reduziert sich auf @k06-eq-lamstar. Wer nur an einer Koordinate interessiert ist, etwa an einer Steigung, kann $lambda$ für diese Koordinate optimieren; in `ppi_py` geschieht das über das Argument `coord` @angelopoulos2024ppipy.

Ein Implementierungsdetail mit praktischer Bedeutung: `ppi_py` 0.2.3 begrenzt das geschätzte $hat(lambda)$ auf das Intervall $[0, 1]$ (`_calc_lam_glm(..., clip=True)`), das wurde im installierten Quelltext geprüft @angelopoulos2024ppipy. Negative Gewichte, die bei negativer Korrelation theoretisch optimal wären, werden also nicht verwendet.

#fallstrick[
  Die Garantie "nie schlechter als klassisch" ist asymptotisch und gilt für das *optimale* $lambda^star$. In endlichen Stichproben wird $hat(lambda)$ aus denselben Daten geschätzt, und bei sehr kleinem $n$ kann das eigene Rauschen kosten. Prüfe bei $n < 100$ die Überdeckung per Simulation, statt dich auf die Asymptotik zu verlassen.
]

=== Wie stark hilft Power-Tuning? Die Simulation

Die Simulation der Wissensbasis variiert in einem zweiten Experiment die symmetrische, nicht differenzielle Genauigkeit des LLM von 0.55 bis 0.99 und vergleicht die Intervallbreiten mit der klassischen Breite (@k06-tab-exp2, @k06-fig-exp2).

#figure(
  table(columns: (auto, auto, auto, auto, auto, auto, auto),
    table.header([Genauigkeit], [Breite PPI / klass.], [Breite PPI++ / klass.], [Mittel $hat(lambda)$], [Überd. PPI], [Überd. PPI++], [Überd. naiv]),
    [0.55], [1.423], [0.995], [0.082], [0.950], [0.948], [0.000],
    [0.65], [1.270], [0.961], [0.247], [0.942], [0.946], [0.000],
    [0.75], [1.087], [0.887], [0.422], [0.947], [0.946], [0.000],
    [0.85], [0.860], [0.754], [0.613], [0.942], [0.949], [0.000],
    [0.95], [0.532], [0.502], [0.829], [0.957], [0.955], [0.021],
    [0.99], [0.314], [0.306], [0.925], [0.949], [0.942], [0.859],
  ),
  caption: [Experiment 2 der Simulation: nicht differenzieller symmetrischer Fehler, $n = 500$, $N_"gesamt" = 10 thin 000$, 1000 Wiederholungen je Genauigkeit, nominelle Überdeckung 0.95. Ausgabe des Skripts aus der Wissensbasis der LV, vom Verifikationsbericht Ziffer für Ziffer reproduziert.],
) <k06-tab-exp2>

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 8.4
    let H = 4.2
    let X(a) = (a - 0.55) / 0.44 * W
    let Y(y) = y / 1.5 * H
    k6achsen(W, H, (), (0, 0.5, 1.0, 1.5), ymax: 1.5, yl: [Breite relativ zu klassisch])
    for a in (0.55, 0.65, 0.75, 0.85, 0.95, 0.99) {
      line((X(a), 0), (X(a), -0.08), stroke: 0.6pt + c-dark)
      content((X(a), -0.3), k6t(str(a)))
    }
    content((W / 2, -0.78), k6t[symmetrische LLM-Genauigkeit])
    rect((X(0.75), 0), (X(0.85), H), fill: c-yellow.lighten(85%), stroke: none)
    line((0, Y(1)), (W, Y(1)), stroke: (paint: c-dark, thickness: 0.7pt, dash: "dashed"))
    let acc = (0.55, 0.65, 0.75, 0.85, 0.95, 0.99)
    let ppi = (1.423, 1.270, 1.087, 0.860, 0.532, 0.314)
    let pp = (0.995, 0.961, 0.887, 0.754, 0.502, 0.306)
    for (vals, col, lab) in ((ppi, c-accent, [PPI ($lambda = 1$)]), (pp, c-blue, [PPI++ ($hat(lambda)$)])) {
      let pts = acc.zip(vals).map(((a, v)) => (X(a), Y(v)))
      line(..pts, stroke: (paint: col, thickness: 1.3pt))
      for p in pts { circle(p, radius: 0.06, fill: col, stroke: none) }
    }
    content((X(0.63), Y(1.35)), anchor: "south-west", text(font: "Inter", size: 7pt, fill: c-accent)[PPI ($lambda = 1$)])
    content((X(0.60), Y(0.80)), anchor: "north-west", text(font: "Inter", size: 7pt, fill: c-blue)[PPI++ ($hat(lambda)$)])
    content((X(0.99), Y(1) + 0.15), anchor: "south-east", k6t[klassisch])
    content((X(0.80), H - 0.15), anchor: "north", text(font: "Inter", size: 6.5pt, fill: c-yellow.darken(25%))[$hat(lambda)$ kreuzt 1/2])
  }),
  caption: [Experiment 2 grafisch: PPI mit $lambda = 1$ ist bei Genauigkeiten bis 0.75 breiter als die klassische Inferenz, PPI++ nie. Zwischen 0.75 und 0.85 überschreitet $hat(lambda)$ den Wert 1/2, ab dem PPI nach @k06-eq-halb gewinnt. Bei sehr guten LLMs konvergieren beide Verfahren.],
) <k06-fig-exp2>

Drei Beobachtungen lassen sich ablesen. PPI mit $lambda = 1$ ist bei Genauigkeiten zwischen 0.55 und 0.75 um 9 bis 42 % breiter als die klassische Inferenz. PPI++ ist nie breiter (Verhältnis höchstens 0.995), weil $hat(lambda)$ gegen null schrumpft; das entspricht der Dominanzaussage des PPI++-Aufsatzes und den Stresstests im PPI-Aufsatz @angelopoulos2023ppi[Abschn. 6.1] @angelopoulos2023prediction[Anh. G]. Und die naive Schätzung ist nur bei nahezu perfektem LLM brauchbar: Selbst bei 95 % symmetrischer Genauigkeit überdeckt sie in 2.1 % der Fälle, bei 99 % in 85.9 %, also immer noch unter dem Nominalwert.

#merke[
  Verwende standardmäßig PPI++ mit geschätztem $hat(lambda)$ (in `ppi_py` mit `lam=None`), nicht PPI mit $lambda = 1$. Du gibst asymptotisch nichts auf und schützt dich gegen schwache LLMs.
]

=== Stichprobenplanung mit Kosten

Die effektive Stichprobengröße erlaubt eine echte Kostenplanung. Seien $c_Y$ die Kosten eines Goldlabels, $c_(hat(Y))$ die eines LLM-Labels und $c_X$ die Kosten, eine Einheit überhaupt zu erheben. Mit $gamma = (c_(hat(Y)) + c_X) slash c_Y$ kostet PPI pro klassisch-äquivalentem Goldlabel
$ c_Y (1 - rho^2 + gamma rho^2 + 2 sqrt(gamma rho^2 (1 - rho^2))) $ <k06-eq-kosten>
gegenüber $c_Y + c_X$ für die klassische Inferenz; ist PPI nicht billiger, fällt die Planungsfunktion von `ppi_py` auf $N = 0$ zurück @angelopoulos2024ppipy. Für $gamma -> 0$ (LLM-Labels praktisch gratis) wird der Faktor $1 - rho^2$, also der Kehrwert der Schranke aus @k06-fig-neff.

#beispiel(titel: [Goldbudget planen])[
  Mit $hat(rho) = 0.6675$, geschätzt aus 500 Goldlabels der simulierten Daten, $c_Y = 1$, $c_(hat(Y)) = 0.01$ und $c_X = 0$ liefert `ppi_power` aus `ppi_py` 0.2.3 zwei Pläne @angelopoulos2024ppipy:
  ```out
budget=1000      : {'n': 918, 'N': 7309, 'cost': 1000.27, 'effective_n': 1519, ...}
effective_n=1000 : {'n': 604, 'N': 4812, 'cost': 658.16, 'effective_n': 1000, ...}
# in beiden Fällen 'ppi_corr': 0.6674857767922908
  ```
  Lesart: Um die Präzision von 1000 Goldlabels zu erreichen, genügen etwa 604 Goldlabels und 4812 zusätzliche nur LLM-gelabelte Einheiten, Kosten 658 statt 1000 Einheiten (604 Goldlabels plus 0.01 für jedes der 5416 LLM-Labels). Mit einem festen Budget von 1000 kauft der leistungsstärkste Plan 918 Goldlabels und 7309 LLM-Labels, äquivalent zu 1519 Goldlabels. @k06-eq-kosten mit $gamma = 0.01$ ergibt den Faktor 0.658, also rund 658 Einheiten. Hinweis zur Reproduzierbarkeit: Der Seed, aus dem $hat(rho) = 0.6675$ stammt, ist in der Wissensbasis nicht dokumentiert; mit Seed 1 erhält man $hat(rho) = 0.664$ und den Plan $n = 609$, $N = 4796$.
]

#tipp[
  Plane mit einem vorsichtigen $rho$. Schätze die Korrelation aus einer kleinen Pilotstichprobe, nimm die untere Grenze eines Intervalls dafür, und rechne die effektive Stichprobengröße damit. Ein zu optimistisches $rho$ führt zu einer Goldstichprobe, die am Ende zu klein ist, und die Korrektur kann fehlende Goldlabels nicht ersetzen.
]

== Erweiterungen: Cross-PPI, Stratifizierung, aktive Inferenz <k06-erweiterungen>

PPI und PPI++ beantworten die Frage, wie man eine *gegebene* Zufallsstichprobe von Goldlabels mit einem *festen* Prädiktor kombiniert. Die Erweiterungen lockern jeweils eine dieser Vorgaben: Cross-PPI erlaubt, den Prädiktor auf den Goldlabels selbst zu trainieren; stratifizierte und aktive Verfahren verändern, *welche* Einheiten ein Goldlabel bekommen.

=== Cross-Prediction-Powered Inference

Wenn du ein kleines Modell auf deinen Goldlabels feinjustierst oder einen Klassifikator auf LLM-Embeddings trainierst, ist $f$ nicht mehr unabhängig von den gelabelten Daten. Die naheliegende Lösung, die Goldstichprobe zu teilen (eine Hälfte zum Trainieren, eine für den Rektifikator), verschenkt Information. Cross-PPI von Zrnic und Candès verwendet stattdessen Kreuzvalidierung @zrnic2024cross[Gl. 4]:
$ hat(theta)^+ = 1/(K N) sum_(j=1)^K sum_(i=1)^N f^((j))(tilde(X)_i) - 1/n sum_(j=1)^K sum_(i in I_j) (f^((j))(X_i) - Y_i) . $ <k06-eq-crossppi>
Die gelabelten Daten werden in $K$ Folds $I_1, dots, I_K$ zerlegt; $f^((j))$ wird auf allen Folds außer $I_j$ trainiert und nur auf $I_j$ für den Rektifikator verwendet. Auf den ungelabelten Daten mittelt man die Vorhersagen aller $K$ Modelle. Jeder Rektifikatorterm ist dadurch ein Fehler auf Daten, die das jeweilige Modell nicht gesehen hat. Das Konfidenzintervall ist
$ C^+ = hat(theta)^+ plus.minus z_(1 - alpha slash 2) sqrt((n slash N) hat(overline(sigma))^2 + hat(overline(sigma))_Delta^2) / sqrt(n), $
wobei $overline(sigma)^2 = Var(overline(f)(X))$ und $overline(sigma)_Delta^2 = Var(overline(f)(X) - Y)$ für ein "mittleres" Modell $overline(f)$ stehen; die Varianzen werden per Bootstrap geschätzt (mit $B = 30$ in den synthetischen Experimenten) @zrnic2024cross[Satz 1, Kor. 1]. Die Gültigkeit beruht darauf, dass der Lernalgorithmus über die Folds hinweg stabil ist.

Cross-PPI ist laut den Autoren mächtiger als klassische Inferenz und als PPI mit Datenteilung und hält die Fehlerrate ein @zrnic2024cross[Zusammenfassung]. Bemerkenswert sind auch die stabileren Intervalle: Im Abholzungsbeispiel betragen die Standardabweichungen der unteren und oberen Intervallgrenze 0.0158 und 0.0182 gegenüber 0.0195 und 0.0232 klassisch und 0.0200 und 0.0240 für PPI @zrnic2024cross[Tab. 4]. Für LLM-Projekte ist Cross-PPI der richtige Rahmen, sobald du auf den Goldlabels irgendetwas lernst, auch wenn es nur eine Kalibrierung der LLM-Wahrscheinlichkeiten ist.

=== Stratifizierte PPI

Ist das LLM in manchen Teilpopulationen besser als in anderen (zum Beispiel bei Standardsprache besser als bei Dialekt), lohnt es sich, die Population in Schichten zu zerlegen und PPI pro Schicht anzuwenden. Fisch et al. zeigen mit _StratPPI_, dass eine geeignete Schichtung und Allokation der Goldlabels pro Schicht wesentlich engere Intervalle liefern kann als unstratifizierte Verfahren, ohne Annahmen über den automatischen Bewerter oder die Datenverteilung; die Gewinne sind zu erwarten, wenn die Güte des Bewerters zwischen den Schichten variiert @fisch2024stratified[Zusammenfassung].

Die Logik lässt sich mit Standardmathematik nachvollziehen. Seien $w_h$ die Populationsanteile der Schichten $h = 1, dots, H$ und $hat(theta)_h$ unabhängige PPI-Schätzer pro Schicht. Der stratifizierte Schätzer $hat(theta)^"strat" = sum_h w_h hat(theta)_h$ ist unverzerrt, und für $N_h >> n_h$ ist seine Varianz näherungsweise $sum_h w_h^2 sigma_(f - Y, h)^2 slash n_h$. Unter der Nebenbedingung $sum_h n_h = n$ minimiert die Neyman-Allokation $n_h prop w_h sigma_(f - Y, h)$ diese Summe: Goldlabels gehen bevorzugt in die Schichten, in denen das LLM stark streut. Das ist genau der differenzielle Fehler aus @k06-plugin, nur diesmal als Chance statt als Problem. Konkrete Zahlen aus StratPPI wurden für die Wissensbasis nicht extrahiert; die Allokationsformel ist hier eine eigene Illustration.

=== Aktive statistische Inferenz

Die konsequente Fortsetzung der Stratifizierung ist, für jede einzelne Einheit eine eigene Auswahlwahrscheinlichkeit festzulegen. Zrnic und Candès schlagen vor, Menschen gezielt dort labeln zu lassen, wo das Modell unsicher ist, und die Verzerrung durch Inverse-Wahrscheinlichkeits-Gewichtung auszugleichen @zrnic2024active[Gl. 1-2].

#definition(titel: [Aktiver Schätzer])[
  Alle $n$ Einheiten bekommen ein LLM-Label. Einheit $i$ wird mit Wahrscheinlichkeit $pi(X_i)$ zusätzlich von Menschen gelabelt, $xi_i tilde "Bern"(pi(X_i))$, unter der Budgetbedingung $EE[pi(X)] n <= n_b$. Der Schätzer ist
  $ hat(theta)^pi = 1/n sum_(i=1)^n (f(X_i) + (Y_i - f(X_i)) xi_i / pi(X_i)) . $ <k06-eq-active>
]

#satz(titel: [Unverzerrtheit und Varianz des aktiven Schätzers])[
  Ist $pi(x) > 0$ für alle $x$ und hängt $xi_i$ nur über $X_i$ von den Daten ab, dann ist $EE[hat(theta)^pi] = EE[Y]$ und
  $ Var(hat(theta)^pi) = 1/n (Var(Y) + EE[(Y - f(X))^2 (1/pi(X) - 1)]) . $ <k06-eq-active-var>
]
#beweis[
  Bedingt auf $(X_i, Y_i)$ ist $EE[xi_i slash pi(X_i) | X_i, Y_i] = 1$, also $EE[f + (Y - f) xi slash pi] = EE[f + Y - f] = EE[Y]$. Für die Varianz zerlege nach dem Satz von der totalen Varianz bezüglich $(X, Y)$. Der bedingte Erwartungswert ist $Y$, mit Varianz $Var(Y)$. Die bedingte Varianz ist $(Y - f)^2 Var(xi slash pi | X) = (Y - f)^2 (1 - pi) slash pi$, deren Erwartung den zweiten Term liefert. Teile durch $n$ für das Mittel unabhängiger Summanden.
]

@k06-eq-active-var zeigt die Logik unmittelbar: Der Zusatzterm ist groß, wo der quadrierte LLM-Fehler groß und die Labelwahrscheinlichkeit klein ist. Man sollte also dort labeln, wo das LLM voraussichtlich falsch liegt.

#satz(titel: [Optimale Labelwahrscheinlichkeit])[
  Sei $e^2(x) = EE[(Y - f(X))^2 | X = x]$. Unter der Budgetbedingung $EE[pi(X)] = b$ (ohne die Schranke $pi <= 1$) minimiert
  $ pi^star (x) = b sqrt(e^2(x)) / EE[sqrt(e^2(X))] $ <k06-eq-pistar>
  den Varianzterm $EE[e^2(X) slash pi(X)]$.
]
#beweis[
  Nach Cauchy-Schwarz gilt $(EE[sqrt(e^2)])^2 = (EE[sqrt(e^2 slash pi) sqrt(pi)])^2 <= EE[e^2 slash pi] dot EE[pi] = b EE[e^2 slash pi]$. Also $EE[e^2 slash pi] >= (EE[sqrt(e^2)])^2 slash b$, mit Gleichheit genau dann, wenn $sqrt(e^2 slash pi) prop sqrt(pi)$, also $pi prop sqrt(e^2)$. Normierung auf das Budget ergibt @k06-eq-pistar. Liegt ein so berechnetes $pi$ über 1, kappt man es und verteilt das Restbudget neu.
]

Die Wurzel ist bemerkenswert: Man labelt nicht proportional zum erwarteten quadrierten Fehler, sondern zu seiner Wurzel. Genau diese Form verwendet Confidence-Driven Inference als Orakelregel, $pi_i^star prop sqrt(EE[(hat(H)_i - H_i)^2 | T_i])$ @gligoric2025can[Abschn. 3.2]. Zrnic und Candès verwenden in der Praxis ein Unsicherheitsmaß des Modells; für einen $K$-Klassen-Klassifikator mit vorhergesagten Wahrscheinlichkeiten $p_k (x)$ ist das
$ u(x) = K / (K - 1) (1 - max_(k in [K]) p_k (x)), $
im binären Fall $u(x) = 2 min{p(x), 1 - p(x)}$, und die Regel $pi(x) prop u(x)$ wird auf das Budget normiert @zrnic2024active. Gleichmäßige Labelwahrscheinlichkeiten ergeben den PPI-Schätzer; PPI ist also der Spezialfall der aktiven Inferenz ohne Steuerung @zrnic2024active.

#beispiel(titel: [Gewinn durch gezieltes Labeln])[
  70 % der Texte sind für das LLM einfach, mit $e^2 = 0.02$, 30 % schwierig, mit $e^2 = 0.20$; $Var(Y) = 0.2139$, Budget $b = 0.1$ (jeder zehnte Text bekommt im Mittel ein Goldlabel). Gleichmäßig ($pi = 0.1$) ist der Zusatzterm $(0.7 dot 0.02 + 0.3 dot 0.20) dot 9 = 0.666$, also $n Var = 0.880$. Nach @k06-eq-pistar sind die Wurzeln 0.1414 und 0.4472, ihr gewichtetes Mittel 0.2332, also $pi = 0.1 dot 0.1414 slash 0.2332 = 0.061$ für einfache und $0.192$ für schwierige Texte. Der Zusatzterm sinkt auf $0.7 dot 0.02 dot (1 slash 0.061 - 1) + 0.3 dot 0.20 dot (1 slash 0.192 - 1) = 0.470$, also $n Var = 0.684$, eine Varianzreduktion um 22 % bei gleichem Budget.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 4.2
    let H = 3.4
    for (blk, titel, p1, p2) in ((0, [gleichmäßig], 0.1, 0.1), (1, [optimal (Wurzelregel)], 0.0607, 0.1918)) {
      let x0 = blk * (W + 1.6)
      let Y(y) = y / 0.25 * H
      line((x0, 0), (x0 + W, 0), stroke: 0.7pt + c-dark)
      line((x0, 0), (x0, H), stroke: 0.7pt + c-dark)
      for v in (0, 0.1, 0.2) {
        line((x0, Y(v)), (x0 - 0.08, Y(v)), stroke: 0.6pt + c-dark)
        content((x0 - 0.14, Y(v)), anchor: "east", k6t(str(v)))
      }
      // Balkenbreite proportional zum Anteil der Texte (0.7 / 0.3)
      rect((x0 + 0.1, 0), (x0 + 0.1 + 0.7 * (W - 0.3), Y(p1)), fill: c-teal.lighten(30%), stroke: none)
      rect((x0 + 0.2 + 0.7 * (W - 0.3), 0), (x0 + W - 0.1, Y(p2)), fill: c-accent.lighten(20%), stroke: none)
      content((x0 + 0.1 + 0.35 * (W - 0.3), Y(p1) + 0.2), k6t[#calc.round(p1, digits: 3)])
      content((x0 + 0.2 + 0.85 * (W - 0.3), Y(p2) + 0.2), k6t[#calc.round(p2, digits: 3)])
      content((x0 + 0.1 + 0.35 * (W - 0.3), -0.3), k6t[einfach (70 %)])
      content((x0 + 0.2 + 0.85 * (W - 0.3), -0.3), k6t[schwierig (30 %)])
      content((x0 + W / 2, H + 0.25), text(font: "Inter", size: 7.5pt, weight: "bold", titel))
    }
    content((-0.95, 1.7), angle: 90deg, k6t[Labelwahrscheinlichkeit $pi$])
  }),
  caption: [Aktive Auswahl der Goldlabels im Rechenbeispiel. Links gleichmäßig, rechts nach der Wurzelregel @k06-eq-pistar. Die Balkenbreite entspricht dem Anteil der Texte, die Fläche dem Budget (in beiden Fällen 0.1). Bei gleichem Budget sinkt die Varianz um 22 %.],
) <k06-fig-aktiv>

Die Einsparungen können groß sein: In einer Anwendung auf Nachwahlbefragungen kann aktive Inferenz laut den Autoren "over 80%" des Stichprobenbudgets klassischer Verfahren einsparen @zrnic2024active[Abschn. 1]. Die Voraussetzungen sind ein brauchbares Unsicherheitsmaß und Labelwahrscheinlichkeiten, die von null weg beschränkt bleiben, damit die Gewichte $1 slash pi$ nicht explodieren @zrnic2024active.

=== Confidence-Driven Inference: die LLM-Variante

Gligorić et al. übertragen aktive Inferenz auf LLM-Annotation und kombinieren sie mit Power-Tuning @gligoric2025can[Abschn. 3.2, Gl. 2]:
$ hat(theta)^"conf" = 1/n sum_(i=1)^n (lambda hat(H)_i + (H_i - lambda hat(H)_i) xi_i / pi_i), quad pi_i prop sqrt(hat("err")_i (C_i)) . $ <k06-eq-cdi>
Dabei ist $H_i$ das menschliche Label, $hat(H)_i$ das LLM-Label, $C_i in [0, 1]$ die vom LLM verbalisierte Konfidenz und $hat("err")_i$ eine gelernte Abbildung von der Konfidenz auf den erwarteten quadrierten Fehler; $sum_i pi_i = n_"human"$, und $lambda in [0, 1]$ wird wie bei PPI++ optimiert ($lambda = 0$ heißt nur Menschen). Die Fehlerabbildung wird alle 50 bis 100 Punkte neu angepasst @gligoric2025can[Abschn. 3.1-3.2]. Ein Lehrbeispiel von 2026 fasst das Vorgehen in sieben Schritten zusammen: LLM-Vorhersagen und Konfidenzen für alle Einheiten, erste menschliche Labels, Anpassung der Abbildung von Konfidenz auf Fehler, Stichprobenziehung nach geschätztem Fehler, Labeln und Neuanpassen, $lambda$ und Schätzung berechnen, Konfidenzintervall @jhu2026prediction[Folie 29].

#studie(titel: [Gligorić et al. 2025])[
  *Design:* Drei sozialwissenschaftliche Aufgaben mit GPT-4o zero-shot: Höflichkeit ($n = 5480$, Regressionskoeffizienten), Haltung zur Erderwärmung ($n = 2300$, Odds Ratio), politische Schlagseite (2000 Stichproben, Prävalenzen) @gligoric2025can[Abschn. 4.1-4.2]. *Befund:* Confidence-Driven Inference reduziert die Zahl nötiger menschlicher Annotationen in jedem Setting um über 25 % @gligoric2025can[Zusammenfassung]. Der Gewinn an effektiver Stichprobengröße bei 500 menschlichen Labels reicht von 29.9 % (linke Schlagseite) bis 319.4 % (Höflichkeitsmerkmal "erste Person Plural"); die nicht adaptive Kombination von Menschen und LLM verliert bei zwei Höflichkeitsmerkmalen dagegen 16.8 % und 8.1 % @gligoric2025can[Tab. 1]. Die Überdeckung (Ziel 90 %) liegt bei 91 bis 97 %, die von reinen LLM-Schätzungen zwischen 0 und 90 %, etwa 0 % für die Haltungsaufgabe @gligoric2025can[Tab. 1]. *Grenzen:* Die Übereinstimmung des LLM mit Menschen ist in allen Settings nur mäßig; die Überdeckung wird gegen die Schätzung aus allen Daten als Ersatz für $theta^star$ gemessen @gligoric2025can[Abschn. 4].
]

Eine Erweiterung von 2026 überträgt die Idee auf subjektive Aufgaben, bei denen das Schätzziel der Vektor der Gruppenmittel von Annotationen verschiedener demografischer Gruppen ist; die Stichprobe wird proportional zum vorhergesagten quadrierten LLM-Fehler pro Gruppe gezogen @mehrotra2026multi. In einer Aufgabe zu Beleidigungen erreicht zero-shot GPT-5.2 eine Überdeckung von 11.7 % gegenüber 95.0 % für PPI und das neue Verfahren @mehrotra2026multi[Abschn. 4.2].

=== Bootstrap, Kalibrierung und weitere Varianten

Drei weitere Entwicklungen solltest du kennen, ohne sie im Detail zu brauchen. Das *Prediction-Powered Bootstrap* (PPBoot) wendet den Bootstrap einmal auf die PPI-Schätzung an und funktioniert für beliebige Schätzprobleme ohne CLT-Herleitung; es schneidet in mehreren Beispielen fast so gut und manchmal besser ab als PPI und PPI++ und ist in `ppi_py` als `ppboot` verfügbar @zrnic2024note @angelopoulos2024ppipy. Das ist die pragmatische Wahl für Schätzziele ohne geschlossene PPI-Form, etwa einen Quotienten oder einen Gini-Koeffizienten. Kluger et al. erweitern PPI mit Bootstrap-Intervallen auf gewichtete, stratifizierte und Klumpenstichproben und auf beliebige imputierte Merkmale; die Intervalle sind unabhängig von der Modellgüte gültig und nie breiter als solche, die die Vorhersagen ignorieren @kluger2025prediction[Zusammenfassung]. Ji, Lei und Zrnic schließlich zeigen, dass PPI und PPI++ Spezialfälle eines Surrogat-Schätzers mit "imputiertem Verlust" sind, und schlagen mit RePPI eine rekalibrierte Variante vor, die den optimalen imputierten Score per Kreuzanpassung lernt @ji2025predictions[Abschn. 2-3]. Gegenüber PPI++ spart RePPI in ihren Experimenten 3.93 bis 5.86 % (Röntgenbilder) und 5.32 bis 5.85 % (Toxizität) der gelabelten Stichprobe, bei diskreten Weinbewertungen durch GPT-5.4 nano 17.57 bis 21.50 % @ji2025predictions[v2, Tab. 1-3].

#merke[
  Alle Verfahren dieses Abschnitts sind Residuenkorrekturen derselben Bauart: LLM-Vorhersage plus gewichteter, auf der Goldstichprobe gemessener Fehler. Sie unterscheiden sich darin, was sie optimieren: das Gewicht $lambda$ (PPI++), die Auswahlwahrscheinlichkeit $pi$ (aktive Inferenz, CDI), die Schichtung (StratPPI) oder das Vorhersagemodell selbst (Cross-PPI, RePPI, DSL im nächsten Abschnitt) @zrnic2024active[Abschn. 2] @ji2025predictions @salerno2025really.
]

== Design-based Supervised Learning <k06-dsl>

Parallel zu PPI entstand in der Politikwissenschaft DSL, vorgestellt von Egami, Hinck, Stewart und Wei auf der NeurIPS 2023 @egami2023using. Die Motivation ist eine andere: Nicht schmalere Intervalle stehen im Vordergrund, sondern unverzerrte Schätzungen mit gültigen Intervallen für die Regressionen, die Sozialwissenschaftler tatsächlich rechnen, auch wenn die LLM-Labels beliebig verzerrt sind. Ein Lehrbeispiel von 2026 bringt den Unterschied auf eine griffige Formel: Das maschinelle Lernen ziele auf "minimizing the size of confidence intervals", Politikwissenschaft und Soziologie auf unverzerrte Schätzungen und gültige Intervalle @jhu2026prediction[Folie 15].

=== Das Design als Garantie

#definition(titel: [DSL-Annahme 1: bekannte Auswahlwahrscheinlichkeiten])[
  Die Wahrscheinlichkeit $pi(Q_i, W_i, X_i)$, mit der Dokument $i$ ein Goldlabel erhält, ist der Forscherin bekannt und strikt größer als null. Das gilt, wenn sie die Stichprobenziehung selbst kontrolliert; werden etwa 100 von 10 000 Dokumenten zufällig annotiert, ist $pi = 0.01$ @egami2023using[Annahme 1].
]

Die Notation: $Y$ ist das Goldlabel (nur beobachtet, wenn $R = 1$), $Q$ das Ersatzlabel des LLM, $W$ optionale weitere Prädiktoren für $Y$ (andere LLM-Ausgaben, Metadaten), $X$ die Regressoren des nachgelagerten Modells und $R_i$ der Indikator für ein Goldlabel. Geschichtete Designs, deren Wahrscheinlichkeiten vom Ersatzlabel, von Kovariaten oder von den erklärenden Variablen abhängen, sind erlaubt, solange die Wahrscheinlichkeiten bekannt sind @egami2023using[Abschn. 4].

=== Die Pseudo-Outcome-Konstruktion

#definition(titel: [DSL-Pseudo-Outcome])[
  Sei $hat(g)_k$ ein überwachtes Modell, das $Y$ aus $(Q, W, X)$ vorhersagt und auf den Golddokumenten *außerhalb* von Fold $D_k$ trainiert wurde. Für Dokument $i in D_k$ ist
  $ tilde(Y)_i^k = hat(g)_k (Q_i, W_i, X_i) + R_i / pi(Q_i, W_i, X_i) (Y_i - hat(g)_k (Q_i, W_i, X_i)) . $ <k06-eq-dsl>
  Das nachgelagerte Modell wird mit $tilde(Y)$ statt $Y$ geschätzt, für die logistische Regression etwa über die Momentengleichung $sum_k sum_(i in D_k) (tilde(Y)_i^k - "expit"(X_i^top beta)) X_i = 0$ @egami2023using[Gl. 4-5, Alg. 1].
]

Im Originalaufsatz wird mit $K = 5$ Folds und verallgemeinerten Random Forests gearbeitet; eine allgemeine Momentenform deckt beliebige design-basierte Schätzgleichungen ab @egami2023using[Abschn. 4, Alg. 1, Gl. 7].

#satz(titel: [Unverzerrtheit des Pseudo-Outcomes])[
  Unter Annahme 1 und wenn $hat(g)_k$ nicht von den Daten in $D_k$ abhängt, gilt für jedes $i in D_k$
  $ EE[tilde(Y)_i^k | Q_i, W_i, X_i, Y_i, hat(g)_k] = Y_i . $
  Insbesondere ist jede Schätzgleichung, die linear in $Y$ ist, mit $tilde(Y)$ statt $Y$ unverzerrt, *unabhängig davon, wie gut oder schlecht $hat(g)_k$ ist*.
]
#beweis[
  Bedingt auf $(Q_i, W_i, X_i, Y_i)$ und das Modell ist nur $R_i$ zufällig, mit $EE[R_i | dots] = pi(Q_i, W_i, X_i)$ nach dem Design. Also $EE[tilde(Y)_i^k | dots] = hat(g)_k + (pi slash pi)(Y_i - hat(g)_k) = Y_i$. Die Kreuzanpassung sorgt dafür, dass $hat(g)_k$ als fest behandelt werden darf; ohne sie würde $hat(g)$ von $R_i$ und $Y_i$ abhängen und die Bedingung wäre verletzt.
]

Das ist die Kernaussage von DSL in einer Zeile: Die Gültigkeit kommt aus dem Design, die Effizienz aus dem Modell. Unter Annahme 1 sind DSL-Schätzungen mit Kreuzanpassung konsistent und asymptotisch normal mit konsistentem Varianzschätzer, gültig "even when surrogates are arbitrarily biased"; die Qualität der Ersatzlabels beeinflusst die Effizienz, nicht die Gültigkeit @egami2023using[Abschn. 1, Prop. 1].

=== Doppelte Robustheit: die Idee

DSL gehört zur Familie der *doppelt robusten* (_doubly robust_) Schätzer, genauer zu den augmentierten inverse-Wahrscheinlichkeits-gewichteten Schätzern (AIPW). Die klassische Aussage lautet: Ein AIPW-Schätzer für $EE[Y]$ bei fehlenden Werten ist konsistent, wenn *entweder* das Modell für die Beobachtungswahrscheinlichkeit $pi$ *oder* das Outcome-Modell $g$ korrekt ist. Beide Hälften sieht man an @k06-eq-dsl:

- *$pi$ korrekt, $g$ beliebig:* Dann gilt $EE[R slash pi | dots] = 1$, und der Korrekturterm macht jeden Fehler von $g$ im Mittel wett. Das ist der Beweis oben.
- *$g$ korrekt, $pi$ beliebig (aber positiv):* Ist $g = EE[Y | Q, W, X]$ und hängt $R$ bedingt auf $(Q, W, X)$ nicht von $Y$ ab, dann ist $EE[Y - g | Q, W, X, R] = 0$, und der Korrekturterm hat Erwartung null, egal welches $pi$ eingesetzt wird.

Bei DSL ist die erste Hälfte immer erfüllt, weil die Forscherin $pi$ durch das Design *kennt*. Deshalb spricht man von design-basierter Inferenz: Man ist nicht auf das Glück angewiesen, ein Modell richtig spezifiziert zu haben. Die zweite Hälfte wirkt dann auf die Varianz. Mit demselben Argument wie in @k06-eq-active-var ist
$ Var(tilde(Y)) = Var(Y) + EE[(1 - pi) / pi (Y - g)^2] $ <k06-eq-dsl-var>
(für den Mittelwert, mit festem $g$): Je besser $g$ das Goldlabel vorhersagt, desto kleiner der Zusatzterm. DSL kann hier mehr als PPI, weil $g$ nicht nur das LLM-Label $Q$, sondern auch weitere Information $W$ und die Regressoren $X$ verwenden darf.

#satz(titel: [Beziehung zwischen DSL und PPI])[
  Ist $pi = n slash N_"ges"$ konstant und $hat(g) = Q$ (kein Lernen), dann ist das Mittel der Pseudo-Outcomes
  $ 1/N_"ges" sum_(i=1)^(N_"ges") (Q_i + R_i / pi (Y_i - Q_i)) = overline(Q)_"alle" - 1/n sum_(i: R_i = 1) (Q_i - Y_i), $
  also der PPI-Schätzer mit dem LLM-Mittel über gelabelte und ungelabelte Einheiten zusammen.
]
#beweis[
  Mit $pi = n slash N_"ges"$ ist $1/N_"ges" sum_i R_i slash pi (Y_i - Q_i) = 1/n sum_(i: R_i = 1) (Y_i - Q_i)$. Der erste Summand ist das LLM-Mittel über alle Einheiten.
]

Diese Gleichheit ist eine eigene Beobachtung der Wissensbasis aus dem Vergleich von DSL-Gl. 4 mit PPI-Alg. 1 und der aktiven Inferenz @egami2023using @angelopoulos2023prediction @zrnic2024active. Sie zeigt, dass der Unterschied der Verfahren nicht in der Grundidee liegt, sondern in zwei Erweiterungen: dem flexiblen Modell $hat(g)$, das zusätzliche Information nutzen kann, und der expliziten Design-Sicht mit bekannten ungleichen Wahrscheinlichkeiten.

#figure(
  diagram(spacing: (6mm, 8mm),
    fknoten((0, 0), [Korpus mit \ LLM-Labels $Q_i$ \ für alle Dokumente], col: c-blue, w: 30mm),
    fknoten((1.25, 0), [Goldstichprobe mit \ bekanntem $pi_i$ \ (Design!)], col: c-accent, filled: true, w: 30mm),
    fknoten((2.5, 0), [Kreuzanpassung: \ $hat(g)_k$ auf Gold \ außerhalb Fold $k$], col: c-violet, w: 30mm),
    fknoten((3.75, 0), [Pseudo-Outcome \ $hat(g) + R slash pi (Y - hat(g))$], col: c-teal, w: 32mm),
    fknoten((3.75, 1), [Regression mit $tilde(Y)$, \ Sandwich-SE], col: c-teal, filled: true, w: 32mm),
    fknoten((1.25, 1), [Gültigkeit kommt \ aus dem Design], col: c-accent, w: 30mm),
    fknoten((2.5, 1), [Effizienz kommt \ aus $hat(g)$ ($Q$, $W$, $X$)], col: c-violet, w: 30mm),
    edge((0, 0), (1.25, 0), "-|>"),
    edge((1.25, 0), (2.5, 0), "-|>"),
    edge((2.5, 0), (3.75, 0), "-|>"),
    edge((3.75, 0), (3.75, 1), "-|>"),
    edge((1.25, 0), (1.25, 1), stroke: (paint: c-grey, dash: "dashed")),
    edge((2.5, 0), (2.5, 1), stroke: (paint: c-grey, dash: "dashed")),
  ),
  caption: [Ablauf von DSL. Die bekannte Auswahlwahrscheinlichkeit $pi_i$ garantiert die Unverzerrtheit des Pseudo-Outcomes, das kreuzangepasste Modell $hat(g)$ bestimmt nur, wie schmal die Intervalle werden @egami2023using[Alg. 1].],
) <k06-fig-dsl>

=== Was DSL empirisch leistet

#studie(titel: [Egami, Hinck, Stewart und Wei 2023])[
  *Design:* Simulation und zwei empirische Teile. Logistische Regression auf Gesetzesvorlagen des Kongresses mit zero-shot-GPT-3-Ersatzlabels (68 % Genauigkeit im balancierten, 90 % im unbalancierten Fall); 17 Datensätze aus Ziems et al. mit flan-ul2-Ersatzlabels und $n = 100$ Goldlabels, insgesamt 18 Aufgaben @egami2023using[Abb. 2, Tab. 3]. *Befund:* Ersatzlabels mit 90 % Genauigkeit führen ohne Korrektur zu etwa 40 % Überdeckung nomineller 95-%-Intervalle @egami2023using[Abb. 1a]. Bei den Gesetzesvorlagen erreichen nur DSL und die Schätzung allein aus Gold die nominelle Überdeckung; DSL ist im RMSE etwa 14 % effizienter als die Goldschätzung, mit Five-Shot-Prompts etwa 31 % @egami2023using[Abb. 2]. Beispiele aus Tab. 3 (Verzerrung mal 100 / Überdeckung in % / RMSE mal 100): Misinformation (77.6 % Genauigkeit) Plug-in 9.0 / 0.6 / 9.2 gegenüber DSL 0.0 / 96.2 / 4.3; Emotion (70.3 %) Plug-in 2.0 / 67.2 / 2.9 gegenüber DSL 0.1 / 94.0 / 3.2; Hassrede (35.9 %) Plug-in 9.8 / 17.4 / 10.1 gegenüber DSL 0.1 / 94.1 / 3.6 @egami2023using[Tab. 3]. *Grenzen:* setzt korrekte Goldlabels und bekannte Wahrscheinlichkeiten voraus; mit nur 100 Goldlabels bleiben die Intervalle breit; Konzeptualisierungsfehler werden nicht behandelt @halterman2025what.
]

Die DSL-Idee wurde inzwischen auf KI-gestützte Bildannotation übertragen: In drei Studien (wahrgenommene Gewalt auf Protestbildern, Bilder der Black-Lives-Matter-Bewegung auf Twitter, Berichterstattung über Migrantenkarawanen) zeigen Rister Portinari Maranca et al., dass schon kleine Fehlerraten nachgelagerte Ergebnisse verzerren und die Überdeckung zerstören, und dass DSL mit einer kleinen Expertenstichprobe beides wiederherstellt @maranca2025correcting[Zusammenfassung].

=== DSL in R

Die Autoren von @egami2023using stellen das R-Paket `dsl` im GitHub-Repository `naoki-egami/dsl` bereit, Version 0.1.0 laut DESCRIPTION-Datei, Lizenz GPL-2, installierbar nur von GitHub, nicht von CRAN (Stand: 11. November 2026). Das CRAN-Paket mit dem Namen `DSL` ist ein anderes, nicht verwandtes Paket; `install.packages("DSL")` installiert also nicht Design-based Supervised Learning. Das Tutorial der Autoren zeigt folgenden Aufruf:

#block(breakable: false)[#datei("dsl-beispiel.R")[
```r
# install.packages("devtools")
devtools::install_github("naoki-egami/dsl", dependencies = TRUE)
library(dsl)

out <- dsl(model = "lm",
           formula = mean_economy ~ gender + edu + ideology,
           predicted_var = "mean_economy",
           prediction = "mean_pred_economy",
           sample_prob = "cand_sample_prob",
           data = data_cand_merged)
```
]]

Belegt sind damit die Argumentnamen `model`, `formula`, `predicted_var`, `prediction`, `sample_prob` und `data`. Die vollständige Signatur mit Standardwerten konnte für die Wissensbasis nicht geprüft werden; schlage weitere Argumente in der Referenzdokumentation des Pakets nach, bevor du sie im Unterricht verwendest. Eine inoffizielle Python-Portierung existiert als `dsl-kit` 0.1.1 (MIT), wird von den DSL-Autoren aber nicht als offiziell geführt. Für den Unterricht in Python ist es oft klarer, das Pseudo-Outcome selbst zu bilden: Für einen Mittelwert oder ein lineares Modell sind das wenige Zeilen (Pseudo-Outcome nach @k06-eq-dsl, dann OLS mit Sandwich-Standardfehler auf $tilde(Y)$).

#hoersaal([Wenn DSL mit $hat(g) = Q$ dasselbe ist wie PPI, warum gibt es dann zwei Namen und zwei Literaturen?], [Weil sie aus verschiedenen Disziplinen mit verschiedenen Zielen kommen. PPI stammt aus Statistik und maschinellem Lernen und fragt, wie viel schmaler die Intervalle durch Vorhersagen werden; DSL stammt aus der Politikwissenschaft und fragt, wie man trotz verzerrter Ersatzlabels gültige Regressionen bekommt, mit einer explizit geplanten Stichprobe. Technisch sind beide AIPW-artige Residuenkorrekturen @salerno2025really @ji2025predictions. In endlichen Stichproben verhalten sie sich aber unterschiedlich: Ein Benchmark von 2025 findet, dass DSL die Verzerrung oft stärker reduziert und die empirische Effizienz stärker verbessert als PPI, aber über Datensätze hinweg stärker schwankt, ein "bias-variance tradeoff at the level of debiasing methods" @depieuchon2025benchmarking[Zusammenfassung].])

== Andere Traditionen und Debatten <k06-debatten>

PPI und DSL sind nicht die ersten Antworten auf das Problem vorhergesagter Variablen. Wer im Hörsaal oder im Review gefragt wird, warum nicht einfach Regressionskalibrierung, Maximum Likelihood oder postpi, braucht eine Landkarte der Traditionen (@k06-tab-methoden).

=== LLM-Label als Kovariate: Fong und Tyler

Fong und Tyler behandeln den Fall, der in PPI zunächst im Hintergrund steht: Das vorhergesagte Merkmal ist eine erklärende Variable, etwa die Stimmung eines Kommentars als Prädiktor @fong2021machine. Der Plug-in-Schätzer ist dann verzerrt, inkonsistent und überkonfident (@k06-eq-ppvnpv zeigt den Mechanismus). Ihre Korrektur kombiniert per GMM zwei Schätzer: OLS nur auf den gelabelten Daten und eine Zwei-Stufen-Kleinst-Quadrate-Schätzung, die die Vorhersagen als Instrumente verwendet, mit der ersten Stufe auf der Validierungsstichprobe. Die einzige zusätzliche Annahme ist eine Ausschlussrestriktion (die Vorhersagen sind mit dem Regressionsresiduum unkorreliert), und es gibt einen Test auf Überidentifikation @fong2021machine[Abschn. 3.1-3.5].

#studie(titel: [Fong und Tyler 2021])[
  *Design:* Methodenaufsatz in _Political Analysis_; Simulationen und eine Anwendung auf 1 210 166 Reddit-Antwortkommentare, davon 3026 von Hand gelabelt, mit einem SVM-Klassifikator mit 0.75 Genauigkeit @fong2021machine[Abschn. 5]. *Befund:* Bei 72 % Genauigkeit und $n_p = 10^6$ hat der naive Schätzer eine Verzerrung von etwa $-0.56$ bei 0.00 Überdeckung, GMM eine Verzerrung nahe null bei 0.95 @fong2021machine[Tab. 1]; selbst bei 90 % Genauigkeit liegt die naive Verzerrung bei etwa $-0.20$ mit 0.00 Überdeckung @fong2021machine[Tab. 2]. Faustregel: Ist die Primärstichprobe mindestens zehnmal so groß wie die gelabelte, erreicht oder übertrifft GMM meist OLS nur auf gelabelten Daten mit doppelt so vielen Labels @fong2021machine[Abschn. 4]. In der Reddit-Anwendung liegt nur das GMM-Intervall vollständig unter $-1$ @fong2021machine[Abb. 2]. *Grenzen:* nur misklassifizierte unabhängige Variablen und, wie spätere Arbeiten festhalten, nicht differenzieller Fehler @teblunthuis2024misclassification.
]

=== Maximum-Likelihood-Korrektur: TeBlunthuis, Hase und Chan

Aus der Kommunikationswissenschaft kommt der Likelihood-Ansatz. TeBlunthuis, Hase und Chan zeigen, dass Misklassifikation durch automatische Klassifikatoren Regressionsergebnisse verzerrt, und schlagen eine Maximum-Likelihood-Korrektur (MLA) vor, implementiert im R-Paket `misclassificationmodels` @teblunthuis2024misclassification[Zusammenfassung]. In einer Monte-Carlo-Studie vergleichen sie Regressionskalibrierung beziehungsweise GMM, multiple Imputation, Pseudo-Likelihood und MLA für misklassifizierte unabhängige und abhängige Variablen, mit nicht differenziellem und differenziellem Fehler. GMM-Kalibrierung behandelt nur misklassifizierte unabhängige Variablen und setzt nicht differenziellen Fehler voraus; MLA behandelt beide Fälle und auch systematische Misklassifikation, sofern das Fehlermodell das Outcome einbezieht @teblunthuis2024misclassification[Tab. 1, Anh. E]. Der Preis ist ein korrekt spezifiziertes Fehlermodell samt Likelihood. Die Literaturdurchsicht ist die stärkste Motivationsfolie des Themas: Von 48 Studien (2013 bis 2021) hat eine korrigiert, etwa 85 % berichten Recall- oder Precision-artige Metriken, nur 19 % erwähnen, dass Misklassifikation Messfehler verursachen könnte @teblunthuis2024misclassification[Anh. C].

=== Die postpi-Debatte

Postpi (_post-prediction inference_) von Wang, McCormick und Leek war 2020 einer der ersten Vorschläge, Inferenz mit vorhergesagten Outcomes zu korrigieren @wang2020methods. Das Verfahren teilt die Daten dreifach (Training, Test, Validierung), passt auf dem Testteil ein Beziehungsmodell zwischen beobachteten und vorhergesagten Outcomes an und korrigiert damit die Inferenz im Validierungsteil, per Bootstrap (stetige, binäre, Zähl-Outcomes) oder analytisch für lineare Modelle @wang2020methods[Methoden]. Im Beispiel des Aufsatzes liegt der wahre Koeffizient bei 3.87 (SE 0.14), die naive Schätzung bei 3.7 (SE 0.068) @wang2020methods[Abb. 2].

Motwani und Witten haben postpi und PPI 2023 verglichen @motwani2023revisiting. Ihr Ergebnis: Die analytische postpi-Version konvergiert gegen
$ (Cov(Y, hat(f)(Z))) / (Var(hat(f)(Z))) EE[X X^top]^(-1) EE[X hat(f)(Z)], $
was im Allgemeinen nicht der Populationskoeffizient $beta^star = EE[X X^top]^(-1) EE[X Y]$ ist @motwani2023revisiting[Abschn. 2.1]. Gültig ist postpi nur, wenn $hat(f)(z) = EE[Y | Z = z]$ und $X subset.eq Z$ @motwani2023revisiting[Abschn. 2.2]; mit wachsendem $n$ wird es antikonservativ, während PPI und klassische Inferenz für jedes $hat(f)$ Fehlerrate und Überdeckung halten @motwani2023revisiting[Abschn. 4, Abb. 3-4]. Auch im PPI-Vergleich auf einer OLS-Aufgabe "does not cover at the proper rate and the intervals are biased" @angelopoulos2023prediction[Anh. F.2].

Die Debatte ist damit aber nicht einseitig entschieden, und so solltest du sie auch nicht darstellen. Ein Übersichtsartikel von 2025, an dem zwei der postpi-Autoren mitgeschrieben haben, beschreibt postpi als Verbesserung gegenüber dem naiven Vorgehen, deren Gültigkeit an der korrekten Spezifikation hängt, und verweist auf eine spätere momentenbasierte Erweiterung, die diese Annahme lockert @salerno2025really. Die ausgewogene Lesart lautet: Das ursprüngliche postpi ist nur unter einer starken Spezifikationsbedingung gültig, die bei LLM-Labels kaum zu prüfen ist; es bleibt als historischer Ausgangspunkt lehrreich, und für neue Analysen sind PPI++- oder DSL-artige Schätzer vorzuziehen.

#hoersaal([Ist postpi also falsch?], [Es ist nicht falsch, sondern bedingt gültig. Die Frage, die Motwani und Witten stellen, ist die richtige Grundfrage für jedes Verfahren: Gegen welche Größe konvergiert mein Schätzer? Postpi konvergiert gegen den Populationskoeffizienten, wenn das Vorhersagemodell der wahre bedingte Erwartungswert ist und alle Regressoren enthält. Bei einem LLM, das mit einem Prompt labelt, kann man das weder voraussetzen noch prüfen. PPI und DSL brauchen diese Annahme nicht, weil sie die Fehler direkt auf einer Zufallsstichprobe messen. Zwei der postpi-Autoren haben das in einem Review von 2025 selbst so eingeordnet.])

=== Gemeinsamer Kern, verschiedene Rahmungen

#figure(
  table(columns: (1.15fr, 1.3fr, 1.6fr, 1.5fr),
    table.header([Verfahren], [LLM-Label als], [Kernannahme], [Was optimiert wird]),
    [Plug-in], [Y oder X], [Fehler zufällig und bedingt mittelwertfrei @egami2023using], [nichts],
    [PPI @angelopoulos2023prediction], [Y (M-Schätzer)], [Zufallsstichprobe, $f$ fest], [nichts ($lambda = 1$)],
    [PPI++ @angelopoulos2023ppi], [Y (M-Schätzer)], [wie PPI], [Gewicht $lambda$],
    [Cross-PPI @zrnic2024cross], [Y], [stabile Lernverfahren], [Modell per Kreuzanpassung],
    [Aktiv, CDI @zrnic2024active @gligoric2025can], [Y], [bekannte $pi_i > 0$], [Auswahl $pi$ (und $lambda$)],
    [DSL @egami2023using], [Y (Momente)], [bekannte $pi_i > 0$ (Design)], [Modell $hat(g)$ mit $Q$, $W$, $X$],
    [Ökonometrisch @ludwig2026large], [Y (OLS)], [Validierungsstichprobe], [nichts (Bootstrap)],
    [GMM @fong2021machine], [X], [Ausschlussrestriktion], [Gewichtung zweier Schätzer],
    [MLA @teblunthuis2024misclassification], [X oder Y], [korrektes Fehlermodell], [Likelihood],
    [postpi @wang2020methods], [Y], [$hat(f) = EE[Y | Z]$, $X subset.eq Z$ @motwani2023revisiting], [Beziehungsmodell],
  ),
  caption: [Landkarte der Korrekturverfahren. Die Zeilen PPI bis ökonometrisch sind Residuenkorrekturen derselben Bauart, Plug-in ist die unkorrigierte Referenz; GMM und MLA kommen aus der Messfehler- und Instrumentvariablentradition, postpi ist der historische Vorläufer.],
) <k06-tab-methoden>

Technisch sind PPI, DSL, CDI und aktive Inferenz Residuenkorrekturen vom Kontrollvariablen- beziehungsweise AIPW-Typ @zrnic2024active[Abschn. 2] @ji2025predictions @salerno2025really. Ein Review von 2025 berichtet, im Anschluss an Ji et al., dass viele Schätzer mit vorhergesagten Daten (PPI, PPI++, PSPA, PDC, Chen-Chen) eine modifizierte AIPW-Schätzgleichung lösen, und verbindet das Feld mit Doppelstichproben, fehlenden Daten, Surrogat-Outcomes und Messfehlern @salerno2025really[Abschn. 4.1, 5]. Gronsbell et al. betonen die Sicht der zweiphasigen Stichprobenziehung: Z-Schätzung mit ML-imputierten Outcomes sei "guaranteed to match or exceed the efficiency of classical inference", unabhängig von der Vorhersagegüte @gronsbell2024another[Zusammenfassung]. Die Rahmungen unterscheiden sich vor allem darin, was als Ziel gilt (schmale Intervalle, unverzerrte Regressionen, ökonometrische Identifikation) und welche Disziplin welche Software benutzt. Ob ein Verfahren in endlichen Stichproben besser ist, ist eine empirische Frage, und die Evidenz ist gemischt @depieuchon2025benchmarking.

== Was Korrektur nicht leisten kann <k06-grenzen>

Die Verfahren dieses Kapitels sind mächtig, aber sie reparieren genau eine Sache: den Operationalisierungsfehler des LLM relativ zu einem korrekten Goldstandard, gemessen auf einer Zufallsstichprobe. Alles andere bleibt dein Problem.

=== Annahmen, die in LLM-Projekten leicht verletzt werden

1. *Zufällige oder bekannte Auswahl der Goldstichprobe.* PPI verlangt dieselbe Verteilung für gelabelte und ungelabelte Einheiten @angelopoulos2023prediction[Abschn. 1.2], DSL bekannte positive Wahrscheinlichkeiten @egami2023using[Annahme 1]. Typische Verletzungen: zuerst die interessanten oder unklaren Fälle codieren, oder genau die Fälle als Gold verwenden, bei denen Mensch und LLM uneins waren. Mit bekannten Wahrscheinlichkeiten stellen Gewichte die Gültigkeit wieder her @egami2023using @gligoric2025can @kluger2025prediction; `ppi_py` bietet dafür die Argumente `w` und `w_unlabeled` @angelopoulos2024ppipy.
2. *Prädiktor unabhängig von der Inferenzstichprobe.* Prompt und Modell müssen feststehen, bevor die Goldstichprobe für die Inferenz verwendet wird @angelopoulos2023prediction[Abschn. 1.2]. Wer den Prompt an der Goldstichprobe iteriert, braucht eine separate Entwicklungsstichprobe oder Cross-PPI @zrnic2024cross. Prompts und Modelle danach auszuwählen, welche Ergebnisse herauskommen, ist _LLM hacking_ @baumann2025large.
3. *Korrekte Goldlabels.* Alle Kernverfahren behandeln Gold als Wahrheit @nakamura2025surrogate. Bei verrauschten Audits gilt die Überdeckung nur relativ zum verrauschten Ziel, sofern die Adjudikation nicht modelliert wird @chew2026design.
4. *Eindeutige Wahrheit und Konstruktvalidität.* Mehrdeutige Texte und unvollständige Codebücher machen das Schätzziel unscharf, unabhängig von jeder Korrektur @nakamura2026observational @halterman2025what.
5. *Asymptotik.* PPI- und PPI++-Intervalle sind asymptotisch @angelopoulos2023prediction[Prop. 1] @angelopoulos2023ppi[Satz 1]; bei sehr kleinem $n$ prüfe die Überdeckung per Simulation oder verwende Bootstrap-Varianten @zrnic2024note @kluger2025prediction.
6. *Dasselbe $f$ überall.* Das LLM muss für gelabelte und ungelabelte Einheiten dasselbe sein. Ein Modellwechsel des Anbieters zwischen dem Labeln der Goldstichprobe und dem des restlichen Korpus bricht die Zerlegung @k06-eq-zerlegung (eine Konsequenz des Settings in @angelopoulos2023prediction[Abschn. 1.2]); Kapitel 10 behandelt, wie man Modellversionen festhält.

=== Konzeptualisierungsfehler: das Protestbeispiel

#studie(titel: [Halterman und Keith 2026])[
  *Design:* Positions- und Simulationsaufsatz (ACL 2026). Typologie aus Konzeptualisierungs- und Operationalisierungsfehlern; Simulation eines PROTEST-Beispiels mit wahrem Effekt $tau = 1$ für gewaltfreie Proteste, vollständigem und unvollständigem Codebuch (ohne den Ausschluss gewaltsamer Ereignisse), DSL-Korrektur mit $n = 1000$ Goldlabels, $N = 10 thin 000$ LLM-Labels und 250 Seeds @halterman2025what[Abschn. 5, Anh. D]. *Befund:* Mit vollständigem Codebuch sind die DSL-korrigierten Schätzungen unverzerrt, ein kleinerer LLM-Fehler verringert die Varianz. Mit unvollständigem Codebuch sind sie verzerrt, und die Verzerrung bleibt bestehen, auch wenn der LLM-Fehler gegen 0 % geht @halterman2025what[Abb. 3]. Empfehlungen: Goldlabels mit LLM-Vorhersagen und nachträglicher Korrektur kombinieren, ein explizites, vollständiges Codebuch für Menschen und LLM, Fachleute in Pilotrunden, Varianzreduktion über Rechenaufwand, Feinjustierung oder Ensembles, die ganze Pipeline optimieren @halterman2025what[Abschn. 6]. *Grenzen:* simulationsbasiert, Verzerrungen nur grafisch.
]

Verwandt ist der Befund von Nakamura, Tan und Yean, die Textklassifikationsaufgaben aus 14 politikwissenschaftlichen Studien mit 13 LLMs, drei Fachcodierenden und 165 Crowdworkern repliziert haben (Preprint, Fassung v2). Auf Texten, die Menschen spalten, fällt die Übereinstimmung zwischen Fachleuten von 93 % auf 60 %, die zwischen LLM und Fachleuten auf etwa 0.56; Korrekturverfahren wie PPI und DSL setzen dagegen eine eindeutige Zielannotation pro Text voraus @nakamura2026observational. Wo es "das" richtige Label nicht gibt, schlagen die Autoren mehrdeutigkeitsbewusste Schranken statt Punktschätzungen vor @nakamura2026observational.

=== Verrauschte Goldlabels

Chew und Williams erweitern DSL für den Fall, dass die menschlichen Audit-Labels selbst verrauscht sind und nur ein Teil von Fachleuten adjudiziert wird (_Partially Adjudicated DSL_). Mit bekannten Audit- und Adjudikationswahrscheinlichkeiten erreichen die korrigierten Schätzer 0.94 bis 0.96 Überdeckung, während Plug-in-Varianten mit Verzerrungen zwischen $-0.41$ und $-0.85$ null Überdeckung haben @chew2026design[Abschn. 5, Abb. 2]. Der Aufsatz ist ein junger Preprint, die Zahlen sind als Größenordnung zu lesen. Die Lektion ist allgemein: "Gold" ist eine Annahme, und Doppelcodierung mit Adjudikation braucht ein eigenes Budget.

=== Gültigkeit ist nicht Teststärke

Die vielleicht wichtigste nüchterne Zahl liefern Baumann et al. Korrekturen (CDI, DSL) bringen den Fehler erster Art auf das nominelle Niveau, CDI schon mit etwa 100 menschlichen Annotationen, aber das Risiko eines Fehlers zweiter Art steigt um bis zu etwa 60 Prozentpunkte; Korrekturen verschieben Fehler von der ersten zur zweiten Art, und reine Menschenannotation schneidet insgesamt am besten ab (Risiko etwa 20 % mit 1000 menschlichen Labels) @baumann2025large[Abschn. 5.4, Abb. 10-11]. Bei absichtlicher Ausnutzung der Konfigurationsfreiheit war ein falsch positives Ergebnis für 94.4 % der Nullhypothesen erreichbar, das Verstecken eines wahren Effekts für 98.1 % und eine Vorzeichenumkehr für 68.3 % @baumann2025large[Abschn. 5.1, Abb. 2]. Der Aufsatz ist ein Preprint, und "Risiko" ist relativ zu den Schlüssen aus menschlichen Annotationen definiert; PPI selbst wurde nicht getestet.

#fallstrick[
  Korrektur kauft Gültigkeit, keine Teststärke. Ein korrekt korrigiertes Intervall ist ehrlich breit. Wer mit 100 Goldlabels plant, weil "die Korrektur das schon macht", bekommt ein gültiges, aber womöglich nutzlos breites Intervall. Plane die Goldstichprobe für die Teststärke, die du brauchst (Lehrbuch: konventionell 0.80 @haindl2027research), nicht nur für die Gültigkeit, und registriere Modell und Prompt vorab.
]

#hoersaal([Mein LLM stimmt mit den Fachleuten mit Kappa 0.8 überein. Darf ich die Regressionskoeffizienten auf LLM-Labels berichten?], [Nicht ohne weitere Evidenz. Kappa sagt, wie oft die Labels übereinstimmen, nicht, ob die Fehler mit deinen Kovariaten zusammenhängen. Plug-in ist nur gültig, wenn die Fehler zufällig und bedingt auf die Kovariaten mittelwertfrei sind @egami2023using[Abschn. 3], und nach Ludwig et al. ist Plug-in nur gültig, wenn das LLM die Messung überall reproduziert @ludwig2026large[Prop. 2]. Du brauchst also entweder einen Nachweis, dass der Fehler nicht mit den Kovariaten zusammenhängt (dafür brauchst du ohnehin eine Goldstichprobe), oder du verwendest diese Goldstichprobe gleich für eine Korrektur. Das Zweite ist einfacher und ehrlicher.])

== PPI für Evaluation und Ranking <k06-evaluation>

Dieselbe Mathematik macht auch die Bewertung von Modellen mit LLM-Bewertern statistisch belastbar, das Thema von Kapitel 7. Wenn ein LLM als Richter (_LLM-as-a-judge_) die Antworten eines Modells bewertet, ist die Genauigkeit des Modells ein Mittelwert, $theta^star = EE[Y]$ mit $Y in {0, 1}$ für "korrekt nach menschlichem Urteil", und das Richterurteil spielt die Rolle von $f(X)$. PPI für den Mittelwert liefert dann unmittelbar ein gültiges Intervall für die Modellgenauigkeit aus wenigen menschlichen und vielen Richterurteilen.

Boyeau et al. haben das systematisch ausgearbeitet: PPI- und PPI++-Schätzer für Modellmetriken wie Genauigkeit und paarweise Gewinnraten, mit koordinatenweisen und simultanen Chi-Quadrat-Intervallen für Rankings @boyeau2025autoeval[Abschn. 2-3]. In ihren Experimenten mit GPT-4 steigt die effektive Größe der menschlich gelabelten Stichprobe "by up to 50%" (so die Zusammenfassung der arXiv-Fassung v2; die PMLR-Zusammenfassung nennt keine Prozentzahl); auf ImageNet und bei Proteinfitness sind es etwa 50 %, mit etwa fünffach besserer Rangfolgegenauigkeit bei $n = 1000$ für Proteinfitness @boyeau2025autoeval. Chatzi et al. konstruieren für die Rangfolge von LLMs nach menschlichen paarweisen Präferenzen Rangmengen, die die wahre menschliche Rangfolge mit Wahrscheinlichkeit mindestens $1 - alpha$ überdecken, aus wenigen menschlichen und vielen LLM-Richter-Vergleichen; Rangfolgen nur aus LLM-Richter-Vergleichen sind dagegen oft inkonsistent mit menschlichen Präferenzen @chatzi2024prediction[Zusammenfassung, Abb. 3]. Stratifizierte PPI (@k06-erweiterungen) wurde explizit für hybride Evaluation von Sprachmodellen entwickelt @fisch2024stratified.

#beispiel(titel: [Modellgenauigkeit mit LLM-Richter])[
  Ein Richter-LLM bewertet 5000 Antworten eines Systems, 400 davon bewerten zusätzlich Menschen. Auf den 400 sagt der Richter in 78 % "korrekt", Menschen in 71 %; auf den übrigen 4600 sagt der Richter in 77 % "korrekt". Dann ist $hat(theta)^"PP" = 0.77 - (0.78 - 0.71) = 0.70$. Der Richter ist um 7 Prozentpunkte zu großzügig, und genau das wird abgezogen. Wer stattdessen 77 % berichtet, bewirbt sein System mit einer Zahl, die der Richter erfindet. Das Intervall folgt aus @k06-eq-ppi-ci, sobald die Fehlervarianz auf den 400 bekannt ist.
]

#merke[
  Jede Benchmark-Zahl, die mit einem LLM-Richter erzeugt wurde, ist eine Plug-in-Schätzung. Mit einer kleinen menschlich bewerteten Zufallsstichprobe und PPI wird daraus eine gültige Schätzung mit Intervall. Rangfolgen verdienen eigene Unsicherheitsangaben, etwa Rangmengen.
]

== Praxis: Simulation, Planung, Software <k06-simulation>

=== Die Coverage-Simulation als Prüfstand

Die verlässlichste Art, ein Korrekturverfahren in einem neuen Setting zu prüfen, ist eine Simulation, in der du die Wahrheit kennst. Das Skript der Wissensbasis, das auch dem Notebook `notebooks/06_ppi_inference.ipynb` zugrunde liegt, vergleicht naive, klassische, PPI- und PPI++-Schätzer für den Anteil und die Steigung im Design aus @k06-plugin (10 000 Beiträge, 500 Goldlabels per einfacher Zufallsstichprobe, differenzieller LLM-Fehler, 2000 Wiederholungen). Die Schätzer folgen PPI-Alg. 1 und 4 @angelopoulos2023prediction sowie PPI++-Bsp. 6.1, Satz 1 und Prop. 2 @angelopoulos2023ppi. Der Kern sind zwei Funktionen:

#datei("ppi_kern.py")[
```python
import numpy as np

def ppi_mean(Y, Yhat, Yhat_u, lam=1.0):
    """PPI++ für den Mittelwert; lam=1 ist PPI, lam=0 klassisch."""
    n, N = len(Y), len(Yhat_u)
    est = Y.mean() + lam * (Yhat_u.mean() - Yhat.mean())
    var = (lam * Yhat_u).var(ddof=1) / N + (Y - lam * Yhat).var(ddof=1) / n
    return est, np.sqrt(var)

def lam_hat_mean(Y, Yhat, Yhat_u):
    """Cov_n(Y, f) / ((1 + n/N) Var_{n+N}(f)), auf [0, 1] begrenzt wie ppi_py 0.2.3."""
    n, N = len(Y), len(Yhat_u)
    cov = np.cov(Y, Yhat, ddof=1)[0, 1]
    var_f = np.concatenate([Yhat, Yhat_u]).var(ddof=1)
    return float(np.clip(cov / ((1 + n / N) * var_f), 0, 1))
```
]

Die Varianzformel im Code ist @k06-eq-varlambda in Stichprobenform: $lambda^2 hat(sigma)_f^2 slash N$ für den ungelabelten Teil und $hat(Var)(Y - lambda f) slash n$ für den gelabelten. Die Ergebnisse zeigen @k06-tab-exp1 und @k06-fig-coverage.

#figure(
  table(columns: (1.4fr, 0.8fr, 0.9fr, 0.9fr, 0.9fr, 0.9fr),
    table.header([Schätzer], [Wahrheit], [Bias], [emp. SD], [KI-Breite], [Überdeckung]),
    [Anteil naiv], [0.310], [0.0180], [0.0047], [0.0184], [0.026],
    [Anteil klassisch], [0.310], [0.0001], [0.0206], [0.0811], [0.949],
    [Anteil PPI], [0.310], [0.0004], [0.0174], [0.0690], [0.949],
    [Anteil PPI++], [0.310], [$-0.0002$], [0.0157], [0.0614], [0.951],
    [Steigung naiv], [0.150], [$-0.0799$], [0.0095], [0.0379], [0.000],
    [Steigung klassisch], [0.150], [0.0003], [0.0419], [0.1673], [0.958],
    [Steigung PPI], [0.150], [$-0.0006$], [0.0395], [0.1501], [0.945],
    [Steigung PPI++], [0.150], [$-0.0003$], [0.0345], [0.1321], [0.941],
  ),
  caption: [Experiment 1 der Simulation: differenzieller LLM-Fehler, $N_"gesamt" = 10 thin 000$, $n = 500$, 2000 Wiederholungen, nominell 95 %. Ausgabe des Skripts der Wissensbasis (Python 3.13, numpy 2.5.3), vom Verifikationsbericht reproduziert; der Kreuzvergleich mit `ppi_py` 0.2.3 stimmt für OLS exakt und für den Mittelwert bis auf die fünfte Nachkommastelle überein (ddof-Unterschied).],
) <k06-tab-exp1>

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 5.2
    let rows = (
      ([naiv], 0.026, 0.0184, 0.000, 0.0379),
      ([klassisch], 0.949, 0.0811, 0.958, 0.1673),
      ([PPI], 0.949, 0.0690, 0.945, 0.1501),
      ([PPI++], 0.951, 0.0614, 0.941, 0.1321),
    )
    let farben = (c-red, c-grey, c-accent, c-blue)
    for (blk, titel, ci, wi, wmax) in ((0, [Anteil], 1, 2, 0.1), (1, [Steigung], 3, 4, 0.2)) {
      let y0 = -blk * 3.4
      content((-1.6, y0 + 0.35), anchor: "west", text(font: "Inter", size: 7.5pt, weight: "bold", titel))
      // Überdeckung
      for (i, r) in rows.enumerate() {
        let y = y0 - i * 0.6
        content((-0.15, y), anchor: "east", k6t(r.at(0)))
        rect((0, y - 0.2), (W * r.at(ci), y + 0.2), fill: farben.at(i).lighten(20%), stroke: none)
        content((W * r.at(ci) + 0.08, y), anchor: "west", k6t(str(r.at(ci))))
      }
      line((W * 0.95, y0 + 0.3), (W * 0.95, y0 - 2.1), stroke: (paint: c-dark, thickness: 0.7pt, dash: "dashed"))
      // Breite
      let x0 = W + 3.0
      for (i, r) in rows.enumerate() {
        let y = y0 - i * 0.6
        rect((x0, y - 0.2), (x0 + 4.0 * r.at(wi) / wmax, y + 0.2), fill: farben.at(i).lighten(45%), stroke: none)
        content((x0 + 4.0 * r.at(wi) / wmax + 0.08, y), anchor: "west", k6t(str(r.at(wi))))
      }
    }
    content((W / 2, 0.75), k6t[Überdeckung (nominell 0.95, gestrichelt)])
    content((W + 3.0 + 2.0, 0.75), k6t[mittlere Breite des 95-%-Intervalls])
  }),
  caption: [Coverage-Simulation (Experiment 1, @k06-tab-exp1). Links die empirische Überdeckung, rechts die mittlere Intervallbreite. Der naive Schätzer hat die schmalsten Intervalle und praktisch keine Überdeckung. Alle Korrekturverfahren liegen bei der nominellen Überdeckung; PPI++ ist für den Anteil 24 % und für die Steigung 21 % schmaler als die klassische Inferenz.],
) <k06-fig-coverage>

Die Lesart in vier Sätzen. Der naive Schätzer ist selbstsicher falsch: 2.6 % Überdeckung für den Anteil, 0 % für die Steigung, die um 53 % unterschätzt wird. Alle korrigierten Schätzer sind unverzerrt und halten die nominelle Überdeckung (0.941 bis 0.958), im Einklang mit den asymptotischen Garantien @angelopoulos2023prediction[Prop. 1] @angelopoulos2023ppi[Satz 1]. Die Gewinne gegenüber der klassischen Inferenz sind bei realistischer Genauigkeit moderat: PPI++ verengt das Intervall für den Anteil von 0.0811 auf 0.0614 ($n_"eff" approx 870$ statt 500) und für die Steigung von 0.1673 auf 0.1321. Und das alles mit einem LLM, dessen Genauigkeit von 85.6 % in einer Annotationsstudie als gut gelten würde.

#tipp[
  Baue für dein eigenes Projekt eine Simulation, die die Struktur deiner Daten nachbildet: Prävalenzen, Gruppengrößen, plausible Fehlerraten pro Gruppe aus einer Pilotstichprobe, deine geplante Goldstichprobe. Prüfe Überdeckung und Breite für die Verfahren, die du in Erwägung ziehst. Eine halbe Stunde Simulation erspart dir eine Diskussion mit Gutachtern, die du nicht gewinnen kannst.
]

=== `ppi_py` richtig verwenden

`ppi_py` ist die Referenzimplementierung von PPI, PPI++, Cross-PPI, PPBoot, gewichteten Varianten, Baselines und Power-Analyse @angelopoulos2024ppipy. Installiert wird es als `pip install ppi-python` (PyPI-Name `ppi-python`, Importname `ppi_py`, MIT-Lizenz, letzte Version 0.2.3 vom 22. Dezember 2024; Stand: 11. November 2026).

#datei("ppi_analyse.py")[
```python
import numpy as np
from ppi_py import (ppi_mean_ci, classical_mean_ci, ppi_ols_ci,
                    ppi_mean_power)

# Y: Goldlabels (n,), Yhat: LLM-Labels der Goldeinheiten (n,),
# Yhat_unlabeled: LLM-Labels der übrigen Einheiten (N,)
# X, X_unlabeled: Designmatrizen inkl. Interzept-Spalte
ci_ppi   = ppi_mean_ci(Y, Yhat, Yhat_unlabeled, alpha=0.05, lam=1)  # PPI
ci_ppipp = ppi_mean_ci(Y, Yhat, Yhat_unlabeled, alpha=0.05)         # PPI++
ci_class = classical_mean_ci(Y, alpha=0.05)                         # nur Gold
ci_slope = ppi_ols_ci(X, Y, Yhat, X_unlabeled, Yhat_unlabeled,
                      alpha=0.05, coord=1)  # lambda für Koeffizient 1
plan     = ppi_mean_power(Y, Yhat, cost_Y=1.0, cost_Yhat=0.01,
                          effective_n=1000)
```
]

Die vollständigen Signaturen in Version 0.2.3 lauten unter anderem @angelopoulos2024ppipy:

```python
ppi_mean_ci(Y, Yhat, Yhat_unlabeled, alpha=0.1, alternative='two-sided',
            lam=None, coord=None, w=None, w_unlabeled=None,
            lam_optim_mode='overall')
classical_mean_ci(Y, w=None, alpha=0.1, alternative='two-sided')
```

Daraus folgen die praktischen Regeln:

- *Der Standard ist `alpha=0.1`*, also 90-%-Intervalle. Wer 95 % berichten will, muss `alpha=0.05` explizit setzen. Das ist der häufigste Fehler in studentischen Analysen.
- `lam=None` schätzt $lambda$ aus den Daten (PPI++, auf $[0, 1]$ begrenzt), `lam=1` ist PPI, `lam=0` das klassische Intervall.
- `w` und `w_unlabeled` sind Stichprobengewichte für Kovariatenverschiebung und ungleiche Auswahlwahrscheinlichkeiten.
- Weitere Funktionen: `ppi_quantile_ci`, `ppi_logistic_ci`, `ppboot`, `crossppi_mean_ci`, `crossppi_ols_ci`, `crossppi_logistic_ci`, Baselines wie `postprediction_ols_ci` und die Power-Funktionen `ppi_power`, `ppi_mean_power`, `ppi_ols_power`, `ppi_logistic_power`, `ppi_poisson_power`. Aktive Inferenz und stratifizierte PPI sind im README nicht als implementiert aufgeführt.

Die Implementierung des Kapitels stimmt mit `ppi_py` überein: Für einen Datensatz (Seed 1, $alpha = 0.05$) liefern eigene Implementierung und Paket für die Steigung identische Intervalle, für den Mittelwert Abweichungen in der fünften Nachkommastelle, weil `ppi_py` mit Populationsstandardabweichungen (`ddof=0`) rechnet. Das Beispiel im README des Pakets (Galaxien, $n = 1000$, $alpha = 0.1$) gibt `theta=0.259` und das Intervall $(0.2322, 0.2626)$ aus @angelopoulos2024ppipy. Für randomisierte Experimente mit LLM-Vorhersagen gibt es in R das CRAN-Paket `mixedsubjects` (Version 1.0.0, MIT) der Autoren von @vanloon2026using mit sieben Schätzern für den durchschnittlichen Behandlungseffekt und einer Funktion für das optimale Design (Stand: 11. November 2026).

=== Checkliste für ein LLM-Labeling-Projekt mit Inferenz

1. *Schätzziel festlegen:* Anteil, Gruppendifferenz, Koeffizient, Rangfolge? Ist das LLM-Label Outcome oder Kovariate?
2. *Vorhersage oder Schätzung?* Bei Vorhersageaufgaben mit geschlossenen Modellen ist Trainingsleck die Hauptgefahr @ludwig2026large[Abschn. 3].
3. *Codebuch vor der Korrektur:* Vollständiges Codebuch, Pilotrunde mit Fachleuten, mehrdeutige Fälle identifizieren @halterman2025what @nakamura2026observational.
4. *Prompt und Modell einfrieren*, auf einer separaten Entwicklungsstichprobe; Version, Temperatur und Prompt dokumentieren und vorab registrieren @baumann2025large.
5. *Goldstichprobe ziehen*, zufällig oder mit dokumentierten bekannten Wahrscheinlichkeiten; Größe über $n_"eff"$ und Teststärke planen @broska2025mixed.
6. *Schätzen* mit PPI++ (oder DSL bei zusätzlichen Prädiktoren, CDI bei verlässlichen Konfidenzen), `alpha` explizit setzen.
7. *Berichten:* Schätzziel, Auswahl der Goldeinheiten, LLM-Genauigkeit und Korrelation $rho$, geschätztes $lambda$, effektive Stichprobengröße, naive und korrigierte Schätzung nebeneinander; die Empfehlungen des Reviews von Salerno et al. umfassen außerdem Kalibrierungsprüfung, Repräsentativität und die Wahl der Varianzschätzung @salerno2025really[Abschn. 7].

=== Entscheidungsbaum

#figure(
  diagram(spacing: (12mm, 5mm),
    fknoten((0, 0), [LLM-Labels sollen in eine Schätzung eingehen], col: c-dark, filled: true, w: 62mm),
    fknoten((0, 1), [Gibt es eine Goldstichprobe mit zufälliger oder bekannter Auswahl?], col: c-dark, w: 62mm),
    fknoten((1, 1), [Zuerst ziehen: ohne Gold keine gültige Inferenz], col: c-red, w: 56mm),
    fknoten((0, 2), [Ist das LLM-Label eine Kovariate (Regressor)?], col: c-dark, w: 62mm),
    fknoten((1, 2), [GMM (Fong & Tyler), MLA, PPI mit imputierten Kovariaten], col: c-violet, w: 56mm),
    fknoten((0, 3), [Wurde $f$ auf derselben Goldstichprobe trainiert oder getunt?], col: c-dark, w: 62mm),
    fknoten((1, 3), [Cross-PPI oder neue Goldstichprobe], col: c-accent, w: 56mm),
    fknoten((0, 4), [Gibt es verlässliche LLM-Konfidenzen und ist das Labeln noch planbar?], col: c-dark, w: 62mm),
    fknoten((1, 4), [CDI bzw. aktive Auswahl mit bekanntem $pi_i$], col: c-teal, w: 56mm),
    fknoten((0, 5), [Gibt es Zusatzprädiktoren $W$ für das Goldlabel?], col: c-dark, w: 62mm),
    fknoten((1, 5), [DSL mit kreuzangepasstem $hat(g)$], col: c-teal, w: 56mm),
    fknoten((0, 6), [PPI++ mit geschätztem $hat(lambda)$; Bootstrap bei kleinem $n$ oder exotischem Schätzziel], col: c-blue, filled: true, w: 62mm),
    edge((0, 0), (0, 1), "-|>"),
    edge((0, 1), (1, 1), "-|>", label: text(font: "Inter", size: 7pt)[nein], label-side: left),
    edge((0, 1), (0, 2), "-|>", label: text(font: "Inter", size: 7pt)[ja], label-side: right),
    edge((0, 2), (1, 2), "-|>", label: text(font: "Inter", size: 7pt)[ja], label-side: left),
    edge((0, 2), (0, 3), "-|>", label: text(font: "Inter", size: 7pt)[nein], label-side: right),
    edge((0, 3), (1, 3), "-|>", label: text(font: "Inter", size: 7pt)[ja], label-side: left),
    edge((0, 3), (0, 4), "-|>", label: text(font: "Inter", size: 7pt)[nein], label-side: right),
    edge((0, 4), (1, 4), "-|>", label: text(font: "Inter", size: 7pt)[ja], label-side: left),
    edge((0, 4), (0, 5), "-|>", label: text(font: "Inter", size: 7pt)[nein], label-side: right),
    edge((0, 5), (1, 5), "-|>", label: text(font: "Inter", size: 7pt)[ja], label-side: left),
    edge((0, 5), (0, 6), "-|>", label: text(font: "Inter", size: 7pt)[nein], label-side: right),
  ),
  caption: [Entscheidungsbaum für die Wahl des Verfahrens. Er ersetzt keine Simulation im eigenen Setting, ordnet aber die Verfahren dieses Kapitels nach den Fragen, die du zuerst beantworten musst. Querschnittlich gilt immer: Codebuch prüfen, Prompt einfrieren, Teststärke planen.],
) <k06-fig-baum>

#praxis[
  Ein Lehrbeispiel von 2026 empfiehlt für sozialwissenschaftliche Projekte mit LLM-Labels einen Ablauf aus sieben Schritten, der Confidence-Driven Inference operationalisiert @jhu2026prediction[Folie 29] @gligoric2025can. Für die Betreuung von Masterarbeiten bietet sich eine einfachere Faustregel an: Jede Arbeit, die eine Zahl auf LLM-Labels berichtet, berichtet daneben die korrigierte Zahl mit Intervall und die Zahl der Goldlabels. Liegen beide weit auseinander, ist das selbst ein Befund.
]

== Forschungsstand und offene Fragen <k06-offen>

Der Stand Ende 2026 lässt sich in wenigen Linien zusammenfassen. *LLM-spezifische adaptive Annotation* ist etabliert: Confidence-Driven Inference nutzt verbalisierte Konfidenz, um zu entscheiden, welche Einheiten Menschen labeln @gligoric2025can, und eine Erweiterung von 2026 überträgt das auf subjektive Aufgaben mit gruppenspezifischen Schätzzielen @mehrotra2026multi. *Die Theorie ist vereinheitlicht:* PPI ist ein Spezialfall von AIPW mit imputiertem Verlust @ji2025predictions @salerno2025really. *Survey-Designs und Kovariaten* sind abgedeckt @kluger2025prediction @fisch2024stratified. *Experimente und simulierte Versuchspersonen:* LLM-Vorhersagen menschlichen Verhaltens gehen als zusätzliche Beobachtungen mit menschlichem Goldstandard ein @broska2025mixed, mit unverzerrten Schätzern für randomisierte Experimente @vanloon2026using; das schlägt die Brücke zu den Silicon Samples in Kapitel 4. *Multimodal* ist DSL auf Bilder übertragen @maranca2025correcting. Und *die Wahrheit selbst* wird befragt: Mehrdeutigkeit @nakamura2026observational, Codebuchfehler @halterman2025what, verrauschte Goldlabels @chew2026design und repräsentationsbasierte Ansätze, die Standardfehler gegenüber PPI und DSL in einer Anwendung um etwa ein Drittel senken @nakamura2025surrogate.

Offen sind vor allem fünf Fragen. Wie wählt man in endlichen Stichproben das beste Verfahren, und mit welchen Effizienzmetriken @depieuchon2025benchmarking? Wie plant man Goldstichproben für Teststärke statt nur für Gültigkeit @baumann2025large @broska2025mixed? Was tritt an die Stelle des Schätzziels, wenn es kein eindeutiges Label gibt @nakamura2026observational @mehrotra2026multi? Wie geht man mit verrauschtem Gold um @chew2026design @nakamura2025surrogate? Und wie korrigiert man kategoriale Ausgaben und LLM-basierte Themen- und Konzeptinduktion, die ein Lehrbeispiel von 2026 als offene Fragen stellt @jhu2026prediction[Folie 37]?

#hoersaal([Ist das nicht alles nur ein Modetrend der letzten drei Jahre?], [Der Name ist jung, die Mathematik nicht. Doppelstichproben, Regressionsschätzer und GREG aus der Survey-Statistik, AIPW aus der Kausalinferenz, Messfehlermodelle aus der Ökonometrie und Epidemiologie sind Jahrzehnte alt. Neu ist die Situation: Vorhersagen sind durch LLMs so billig und so gut geworden, dass es sich fast immer lohnt, sie mit einer kleinen Goldstichprobe zu kombinieren, und so verbreitet, dass die Plug-in-Fehler sichtbar werden. Der Review von Salerno et al. ordnet genau diese Verbindungen @salerno2025really. Wer das Kapitel verstanden hat, erkennt die alten Verfahren in neuer Notation wieder, siehe die GREG-Bemerkung zu PPI++ @vanloon2026using.])

#hoersaal([Kann ich nicht einfach mehrere LLMs abstimmen lassen und so den Fehler wegbekommen?], [Ein Ensemble kann die Varianz des Fehlers senken und damit die Korrelation $rho$ erhöhen, was nach @k06-eq-neff die effektive Stichprobengröße steigert; Halterman und Keith nennen Ensembles ausdrücklich als Mittel zur Varianzreduktion @halterman2025what[Abschn. 6]. Systematische Fehler, die alle Modelle teilen, mittelt ein Ensemble aber nicht heraus, und gegen ein unvollständiges Codebuch hilft es gar nicht. Das Ensemble ist also ein besseres $f$, kein Ersatz für die Goldstichprobe.])

== Für die Lehre <k06-lehre>

Das Thema hat in Foliensatz 06 einen klaren Aufbau: Motivation, statistische Grundlagen, Versagen des Plug-in-Ansatzes, PPI, PPI++, ein durchgerechnetes Beispiel, Verfahren jenseits von PPI, Praxis und Grenzen. Die folgenden Hinweise ergänzen den Foliensatz.

*Einstieg über ein Paradox.* Die etwa 20-minütige Demo "genau, aber falsch" trägt den Einstieg: Führe das Simulationsskript live aus und zeige, dass ein LLM mit 85.6 % Genauigkeit die Steigung um mehr als die Hälfte unterschätzt und null Überdeckung hat. Lass die Studierenden vor dem Aufdecken von @k06-tab-exp2 schätzen, ab welcher Genauigkeit PPI mit $lambda = 1$ die klassische Inferenz schlägt; der Übergang liegt in diesem Design zwischen 0.75 und 0.85.

*Rechnen vor Programmieren.* Die Handrechnung mit fünf zusammenfassenden Zahlen (Selbsttestaufgabe 3) dauert 30 Minuten und verankert den Schätzer besser als jeder Code. Erst danach `ppi_py`, und zwar mit dem expliziten Auftrag, die eigene Rechnung gegen das Paket zu prüfen.

*Labor.* Ein 90-minütiges Labor nach dem Muster der Wissensbasis funktioniert gut: öffentlichen Datensatz mit menschlichen Labels wählen, mit einem LLM (fester Prompt, feste Modellversion, Temperatur 0, sofern die API den Parameter noch annimmt, siehe Kapitel 10) labeln und verbalisierte Konfidenz erfragen, Goldstichproben von 100, 200 und 500 ziehen, naiv, klassisch, PPI und PPI++ vergleichen (mit `alpha=0.05`), 500 Ziehungen wiederholen und Überdeckung gegen die Schätzung aus allen menschlichen Labels messen, dann konfidenzgesteuerte Auswahl und Power-Planung ausprobieren. Das Notebook `notebooks/06_ppi_inference.ipynb` liefert die Bausteine.

*Typische Missverständnisse.* Vier kommen fast sicher:
1. "Hohe Genauigkeit heißt gültige Schätzung." Gegenmittel: @k06-fig-bigdata und das Egami-Beispiel mit 90 % Genauigkeit und 40 % Überdeckung.
2. "PPI ist immer besser als nur Gold." Gegenmittel: @k06-fig-exp2 und die Bedingung $lambda^star > 1 slash 2$.
3. "Die Goldstichprobe kann ich mir aussuchen." Gegenmittel: der Unverzerrtheitsbeweis, an dem man sieht, dass er ohne gemeinsame Verteilung nicht funktioniert.
4. "Korrektur rettet ein schlechtes Codebuch." Gegenmittel: das Protestbeispiel von Halterman und Keith.

*Mathematisches Niveau.* Für Master Data Intelligence ist die vollständige Herleitung für den Mittelwert (Unverzerrtheit, Varianz, $lambda^star$, $n_"eff"$) angemessen und machbar. Die allgemeine M-Schätzer-Theorie und die Sandwich-Formel genügen als Ergebnis mit Intuition. DSL und aktive Inferenz lassen sich über die gemeinsame Varianzformel @k06-eq-active-var und @k06-eq-dsl-var elegant verbinden, das ist ein guter Abschluss für Fortgeschrittene.

*Zeitbedarf.* Eine Einheit von 3 × 45 Minuten reicht für Motivation, PPI und PPI++ mit Handrechnung und Demo; das Labor braucht weitere 90 Minuten; die Erweiterungen (aktiv, DSL, Debatten) passen in 45 Minuten Diskussion mit vorbereiteter Lektüre. Als Hausübung eignet sich die Erweiterung der Simulation um nicht zufällige Goldauswahl mit Gewichten, unsicherheitsbasierte Auswahl, verrauschte Goldlabels und eine "LLM-Hacking"-Schleife @baumann2025large.

*Diskussionsfragen*, die im Seminar gut funktionieren: Eine Kollegin hat den Prompt an denselben 300 Goldlabels getunt, die sie dann für PPI verwendet; was bricht, und wie hilft Cross-PPI? Ist der Unterschied zwischen PPI, DSL und ökonometrischer Entzerrung statistisch oder disziplinär? Korrektur stellt die Kontrolle des Fehlers erster Art her, erhöht aber das Risiko zweiter Art; ist das akzeptabel?

#vertiefung[
  Als Einstieg der Originalaufsatz @angelopoulos2023prediction, vor allem Abschn. 1 und Alg. 1, mit dem Anhang G zu den Stresstests. Für das Power-Tuning @angelopoulos2023ppi, Bsp. 6.1 genügt für den Mittelwert. Die beste Gesamtübersicht für Studierende ist der Review @salerno2025really. Die sozialwissenschaftliche Sicht mit Fokus auf Gültigkeit vermittelt @egami2023using, die ökonometrische @ludwig2026large. Zur Kritik und den Grenzen: @motwani2023revisiting (welches Ziel schätzt mein Schätzer?), @halterman2025what (Codebuch) und @baumann2025large (Teststärke, LLM-Hacking). Für Evaluation mit LLM-Richtern als Brücke zu Kapitel 7: @boyeau2025autoeval. Statistische Grundlagen im Lehrbuch @haindl2027research, Kapitel zu Statistik.
]

#selbsttest(
  [Ein LLM hat bei einem binären Label Sensitivität 0.80 und Falsch-positiv-Rate 0.05; die wahre Prävalenz ist 0.10. Berechne $EE[hat(Y)]$ und die Verzerrung des naiven Anteils. Für welche Prävalenz wäre die Verzerrung null?],
  [Zeige, dass bei nicht differenziellem Fehler im Outcome die naive Steigung einer Regression auf eine binäre Kovariate um den Faktor $s - r$ abgeschwächt wird. Was passiert mit diesem Faktor, wenn das LLM in den beiden Gruppen unterschiedliche Fehlerraten hat?],
  [Gegeben sind $n = 400$ Goldlabels mit Mittel $overline(Y) = 0.42$, LLM-Mittel auf den Goldeinheiten 0.47, $hat(Var)(Y - f) = 0.12$, sowie $N = 20 thin 000$ nur LLM-gelabelte Einheiten mit Mittel 0.45 und $hat(Var)(f) = 0.2475$; $hat(Var)(Y) = 0.2436$. Berechne den PPI-Schätzer, sein 95-%-Intervall und das klassische Intervall.],
  [Beweise, dass der PPI-Schätzer für den Mittelwert für jedes feste $f$ unverzerrt ist. Welche der beiden PPI-Annahmen verwendest du an welcher Stelle?],
  [Leite das optimale Gewicht $lambda^star$ für PPI++ beim Mittelwert her und zeige, dass PPI ($lambda = 1$) genau dann besser als die klassische Inferenz ist, wenn $lambda^star > 1 slash 2$.],
  [Mit $n = 300$ Goldlabels und $N = 30 thin 000$ LLM-Labels sei $rho = 0.7$. Berechne $n_"eff"$ und die obere Schranke für $N -> infinity$. Wie groß müsste $rho$ sein, damit $n_"eff" approx 2n$?],
  [Ein Team wählt als Goldstichprobe jene 300 Texte, bei denen zwei LLMs uneins waren. Welche Annahme ist verletzt, in welche Richtung wird der Rektifikator vermutlich verzerrt, und wie ließe sich das Design retten?],
  [Erkläre, warum DSL auch mit einem beliebig schlechten Vorhersagemodell $hat(g)$ unverzerrt ist, und welche Rolle die Kreuzanpassung dabei spielt. Was bestimmt dann die Breite der Intervalle?],
  [Leite für die aktive Inferenz her, warum die varianzminimale Labelwahrscheinlichkeit proportional zur Wurzel des erwarteten quadrierten LLM-Fehlers ist, nicht zu diesem selbst.],
  [Ein Paper berichtet die Genauigkeit eines Systems als 77 %, ermittelt mit einem LLM-Richter auf 5000 Antworten, ohne menschliche Kontrolle. Welche zwei Angaben fehlen für eine gültige Aussage, und wie würdest du sie mit PPI ergänzen?],
  [Nenne drei Fehlerquellen, die weder PPI noch DSL korrigieren können, jeweils mit einer Studie, die das zeigt.],
  [Was ist der praktische Fehler, wenn man `ppi_mean_ci(Y, Yhat, Yhat_unlabeled)` ohne weitere Argumente aufruft und das Ergebnis als 95-%-Intervall berichtet? Wie groß ist der Unterschied in der Breite?],
)

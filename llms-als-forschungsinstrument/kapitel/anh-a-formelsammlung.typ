#import "../lib.typ": *

#set math.equation(numbering: none)
#show math.equation.where(block: true): set text(size: 9.3pt)
#show math.equation.where(block: true): set block(above: 0.55em, below: 0.55em)

// Operatoren wie in Kapitel 6
#let Var = math.op("Var")
#let Cov = math.op("Cov")
#let Corr = math.op("Corr")

// Formelblock: Titel, Kapitel und Quelle in der Kopfzeile, Gleichung, Symbolerklärung,
// am Ende Verweis auf die nummerierten Gleichungen im Kapitel
#let fm(titel, quelle, ..gls, sym: none, kap: none, eq: ()) = block(breakable: false, width: 100%, above: 0.95em, below: 0.95em,
  inset: (left: 9pt, top: 3pt, bottom: 3pt), stroke: (left: 1.6pt + c-teal.lighten(35%)))[
  #grid(columns: (1fr, auto), column-gutter: 8pt,
    par(justify: false, text(weight: "semibold", size: 9.2pt, titel)),
    text(size: 7.4pt, fill: c-grey.darken(25%))[#if kap != none [Kap. #kap · ]#quelle])
  #for g in gls.pos() { g }
  #if sym != none or eq.len() > 0 {
    set text(size: 8.2pt)
    set par(justify: false, leading: 0.55em)
    [#if sym != none { sym }#if eq.len() > 0 [ #text(fill: c-teal.darken(25%))[Vgl. #eq.map(l => ref(label(l))).join(", ").]]]
  }
]

= Formelsammlung <anh-formeln>

Dieser Anhang sammelt die zentralen Formeln der Kapitel 1 bis 10 zum Nachschlagen. Jeder Block nennt in der Kopfzeile das Kapitel, in dem die Formel hergeleitet und an einem Beispiel durchgerechnet wird, und die definierende Quelle; der Verweis "Vgl." am Ende führt zur nummerierten Gleichung im Kapitel. Die Notation ist dieselbe wie dort. Die Symbole werden pro Block erklärt, weil viele Buchstaben in verschiedenen Teilgebieten verschiedene Bedeutungen haben ($rho$ ist in @anh-a-inferenz eine Korrelation, in @anh-a-uebereinstimmung eine Vorteilswahrscheinlichkeit). Wo eine Formel nicht aus der Quelle selbst stammt, sondern eine Standarddefinition oder eine eigene Formalisierung ist, steht das ausdrücklich dabei. Zahlenbeispiele sind aus den Kapiteln übernommen und nachgerechnet.

== Effektstärken, Power und Fehlinferenz <anh-a-effekt>

#fm([Standardisierte Mittelwertdifferenz (Cohens $d$)], [@cohen1992power], kap: 1, eq: ("k01-eq-d", "k01-eq-dt"),
  $ d = (macron(x)_1 - macron(x)_2) / s_p, quad s_p = sqrt(((n_1 - 1) s_1^2 + (n_2 - 1) s_2^2) / (n_1 + n_2 - 2)), quad quad t = d dot sqrt((n_1 n_2) / (n_1 + n_2)) $,
  sym: [$macron(x)_1, macron(x)_2$: Gruppenmittelwerte; $s_1^2, s_2^2$: erwartungstreue Stichprobenvarianzen; $n_1, n_2$: Gruppengrößen; $s_p$: gepoolte Standardabweichung; $t$: Statistik des $t$-Tests für unabhängige Stichproben. Konvention: klein 0.20, mittel 0.50, groß 0.80.])

#fm([Effektstärken für gepaarte Designs und ANOVA], [@lakens2013calculating], kap: 1, eq: ("k01-eq-dz", "k01-eq-eta"),
  $ d_z = macron(x)_"diff" / s_"diff", quad d_"av" = macron(x)_"diff" / ((s_1 + s_2) slash 2), quad quad eta_p^2 = (F dot "df"_1) / (F dot "df"_1 + "df"_2) $,
  sym: [$macron(x)_"diff"$, $s_"diff"$: Mittelwert und Standardabweichung der paarweisen Differenzen (z. B. zwei Modelle auf denselben Items); $s_1$, $s_2$: Standardabweichungen der beiden Messungen; $F$: F-Statistik; $"df"_1$, $"df"_2$: Effekt- und Fehlerfreiheitsgrade. Immer angeben, welches $d$ berichtet wird.])

#fm([Umrechnung Korrelation -> $d$], [Standardumrechnung, angewandt auf @collaboration2015estimating], kap: 1, eq: ("k01-eq-rd",),
  $ d = (2 r) / sqrt(1 - r^2) $,
  sym: [$r$: Korrelation als Effektstärke. Die mittleren Effekte der Reproducibility-Studie ($r$ = 0.403 original, 0.197 Replikation) entsprechen $d approx$ 0.88 bzw. 0.40.])

#figure(
  table(
    columns: (1.9fr, auto, auto, auto, auto),
    align: (left, center, center, center, center),
    table.header([Test], [Index], [klein], [mittel], [groß]),
    [Differenz unabhängiger Mittelwerte], [$d$], [0.20], [0.50], [0.80],
    [Signifikanz einer Produkt-Moment-Korrelation], [$r$], [0.10], [0.30], [0.50],
    [Differenz unabhängiger Korrelationen], [$q$], [0.10], [0.30], [0.50],
    [Vorzeichentest], [$g = P - 0.5$], [0.05], [0.15], [0.25],
    [Differenz unabhängiger Anteile], [$h$], [0.20], [0.50], [0.80],
    [Chi-Quadrat (Anpassung, Kontingenz)], [$w$], [0.10], [0.30], [0.50],
    [Einfaktorielle ANOVA], [$f$], [0.10], [0.25], [0.40],
    [Multiple und partielle Korrelation], [$f^2$], [0.02], [0.15], [0.35],
  ),
  caption: [Cohens Konventionen für acht Effektstärkeindizes @cohen1992power. Cohen selbst bezeichnet sie als bequem, aber nicht erschöpfend.],
) <anh-a-tab-cohen>

#fm([Stichprobenumfang für den Zwei-Gruppen-Vergleich], [@cohen1992power; Varianzkompression @bisbee2024synthetic], kap: [1, 4], eq: ("k01-eq-n", "k01-eq-power", "k04-eq-power", "k04-eq-power-faktor"),
  $ n approx (2 (z_(1 - alpha slash 2) + z_(1 - beta))^2) / d^2, quad quad n = 2 (z_(1 - alpha\/2) + z_(1 - beta))^2 sigma^2 / Delta^2, quad quad n_"syn" / n = (c_sigma / c_Delta)^2 $,
  sym: [$n$: Umfang pro Gruppe (Normalapproximation, zweiseitig); $z_q$: $q$-Quantil der Standardnormalverteilung; $alpha$: Fehler erster Art; $1 - beta$: Power; $d = Delta \/ sigma$: angenommene Populationseffektstärke. Für $alpha$ = 0.05, Power 0.80, $d$ = 0.5 ergibt die Näherung 62.8, die exakte Rechnung mit der nichtzentralen $t$-Verteilung 64 pro Gruppe. Liefert eine synthetische Stichprobe $sigma_"syn" = c_sigma sigma$ und $Delta_"syn" = c_Delta Delta$, etwa mit $c_sigma = 0.5$ und $c_Delta = 1.5$, schrumpft das scheinbar nötige $n$ um den Faktor $(0.5 \/ 1.5)^2 = 1\/9$.])

#figure(
  table(
    columns: (1.9fr, auto, auto, auto, auto),
    align: (left, right, right, right, left),
    table.header([Test], [klein], [mittel], [groß], [$N$ bezieht sich auf]),
    [Mittelwertdifferenz ($t$-Test)], [393], [64], [26], [pro Gruppe],
    [Signifikanz von $r$], [783], [85], [28], [gesamt],
    [Differenz zweier Korrelationen], [1573], [177], [66], [pro Gruppe],
    [Vorzeichentest], [783], [85], [30], [gesamt],
    [Differenz zweier Anteile], [392], [63], [25], [pro Gruppe],
  ),
  caption: [Benötigtes $N$ für Power 0.80 bei $alpha$ = 0.05 (zweiseitig) nach Cohen @cohen1992power.],
) <anh-a-tab-power>

#fm([Familienweise Fehlerrate], [@gelman2013garden], kap: 1, eq: ("k01-eq-fwer",),
  $ "FWER" = 1 - (1 - alpha)^k $,
  sym: [$alpha$: Niveau pro Test; $k$: Zahl der effektiv verfügbaren unabhängigen Tests. Für $alpha$ = 0.05: $k = 4$ -> 0.185; $k = 10$ -> 0.401; $k = 20$ -> 0.642. Nach Gelman und Loken ist $k$ implizit groß, auch wenn nur ein Test gerechnet wird, weil seine Wahl von den Daten abhängt.])

#fm([Positiver Vorhersagewert eines signifikanten Befunds], [@ioannidis2005why], kap: 1, eq: ("k01-eq-ppv", "k01-eq-ppv-bias"),
  $ "PPV" = ((1 - beta) R) / (R - beta R + alpha) $,
  $ "PPV" = ((1 - beta) R + u beta R) / (R + alpha - beta R + u - u alpha + u beta R) $,
  sym: [Oben ohne, unten mit Bias. $R$: Prä-Studien-Odds wahrer zu falschen getesteten Beziehungen ($R = pi \/ (1 - pi)$ mit Vorab-Wahrscheinlichkeit $pi$); $1 - beta$: Power; $alpha$: Signifikanzniveau; $u$: Anteil der Analysen, die nur durch Bias zu "Befunden" werden. Beispiel ($u = 0$, $alpha$ = 0.05): $R = 1\/9$ mit Power 0.80 -> 0.64; Power 0.35 -> 0.44.])

#fm([Sättigungskurve in der qualitativen Forschung], [Funktionsform nach @buckley2022ten, Parametrisierung eigen], kap: 1, eq: ("k01-eq-saett", "k01-eq-ns"),
  $ C(n) = C_max (1 - e^(-lambda n)), quad quad n_s = - ln(1 - s) / lambda $,
  sym: [$C(n)$: kumulierte Zahl unterschiedlicher Codes nach $n$ Interviews; $C_max$: asymptotische Codezahl; $lambda$: Entdeckungsrate; $n_s$: Interviewzahl, bei der der Sättigungsgrad $s$ (z. B. 0.9) erreicht ist. Statistische Stoppregeln sind für reflexive thematische Analyse umstritten.])

== Design Science Research <anh-a-dsr>

#fm([Strukturelle Korrektheit generierter Designartefakte], [@klievtsova2023conversational; @iftikhar2026reliability], kap: 2, eq: ("k02-eq-prf", "k02-eq-jaccard", "k02-eq-jf1"),
  $ "Precision" = "TP" / ("TP" + "FP"), quad "Recall" = "TP" / ("TP" + "FN"), quad F_1 = (2 dot "Precision" dot "Recall") / ("Precision" + "Recall") $,
  $ J(G, R) = (|G inter R|) / (|G union R|), quad quad J = "TP" / ("TP" + "FP" + "FN"), quad F_1 = (2 "TP") / (2 "TP" + "FP" + "FN"), quad J = F_1 / (2 - F_1), quad J <= F_1 $,
  sym: [$G$: Menge der generierten Elemente (z. B. Kanten eines Prozessmodells als Tripel aus Quell-, Verbindungs- und Zielobjekt); $R$: Referenzmenge; $"TP"$: generiert und in der Referenz; $"FP"$: generiert, nicht in der Referenz; $"FN"$: in der Referenz, nicht generiert. Die Umrechnung zwischen $J$ und $F_1$ ist aus den Definitionen hergeleitet.])

#fm([Prinzipientreue und Stabilitätsindex], [@iftikhar2026reliability], kap: 2, eq: ("k02-eq-pas", "k02-eq-si", "k02-eq-varkomp", "k02-eq-schranke"),
  $ "PAS" = (\#"erfüllte Regeln") / (\#"geprüfte Regeln"), quad "PES" = (\#"angewandte Muster") / (\#"geprüfte Muster"), quad quad "SI" = 1 / (1 + (sigma^2_"prompt" + sigma^2_"run")) $,
  $ sigma^2_"prompt" = 1/P sum_(p=1)^P (macron(x)_(p dot) - macron(x)_(dot dot))^2, quad sigma^2_"run" = 1/P sum_(p=1)^P 1/R sum_(r=1)^R (x_(p r) - macron(x)_(p dot))^2 $,
  sym: [Jede Regel und jedes Muster wird mit 0, 0.5 oder 1 bewertet; $x_(p r)$: Score bei Paraphrase $p$ ($P$ Paraphrasen) im Lauf $r$ ($R$ Läufe). Die Quelle legt die Schätzung der Varianzen nicht fest; die zweite Zeile ist der Vorschlag aus Kapitel 2 (Varianz der Paraphrasenmittel bzw. mittlere Varianz innerhalb der Paraphrasen). Bei Scores in $[0, 1]$ gilt $0.8 <= "SI" <= 1$; die Varianzkomponenten getrennt zu berichten ist informativer.])

#fm([Lauf-zu-Lauf-Übereinstimmung von Korrektheitsurteilen], [eigene Formalisierung zu @klievtsova2023conversational], kap: 2, eq: ("k02-eq-agree",),
  $ A = 1/N sum_(i=1)^N bb(1)[ell_i^((1)) = ell_i^((2))] $,
  sym: [$N$: Zahl der Eingaben; $ell_i^((k))$: Korrektheitslabel der $k$-ten Generierung für Eingabe $i$. Nicht zufallskorrigiert (dafür @anh-a-uebereinstimmung).])

== Promptsensitivität, Prompt-Effizienz und Kosten <anh-a-prompt>

#fm([Leistungsspanne über Promptformate (FormatSpread)], [@sclar2024quantifying], kap: 3, eq: ("k03-eq-spread",),
  $ "Spread"(M, D, P) = max_(p_i in P) m(M, p_i, D) - min_(p_i in P) m(M, p_i, D) $,
  sym: [$M$: Modell; $D$: Evaluationsdatensatz; $P$: Menge semantisch äquivalenter Formate; $m$: Aufgabenmetrik (z. B. Accuracy). Berichtet wird das Intervall (Minimum, Maximum) statt einer Einzelzahl.])

#fm([Mehrprompt-Evaluation], [@mizrahi2024state], kap: 3, eq: ("k03-eq-multiprompt",),
  $ "MaxP"(M, T, I_T) = max_(i in I_T) epsilon(M, T, i), quad "AvgP"(M, T, I_T) = 1 / (|I_T|) sum_(i in I_T) epsilon(M, T, i) $,
  $ "Sat"(M, T, I_T) = 1 - ("MaxP" - "AvgP"), quad "CPS"(M, T, I_T) = "Sat" dot "MaxP" $,
  sym: [$epsilon(M, T, i)$: Score von Modell $M$ auf Aufgabe $T$ mit Instruktionsvorlage $i$ aus der Paraphrasenmenge $I_T$. MaxP eignet sich zur Vorlagenwahl für eine Anwendung (auf Held-out-Daten validieren), AvgP misst Robustheit, CPS wägt Spitzenleistung gegen Robustheit ab.])

#fm([Rangstabilität über Prompts (Kendall)], [Standarddefinitionen, verwendet in @mizrahi2024state], kap: [3, 9], eq: ("k03-eq-kendall", "k09-eq-tau"),
  $ tau = (n_c - n_d) / binom(n, 2), quad W = (12 sum_(j=1)^n (R_j - macron(R))^2) / (k^2 (n^3 - n)), quad macron(R) = (k (n + 1)) / 2 $,
  sym: [$n$: Zahl der gerankten Modelle; $n_c$, $n_d$: konkordante bzw. diskordante Modellpaare zweier Rankings ($tau$ ohne Bindungskorrektur); $k$: Zahl der Paraphrasen; $R_j$: Rangsumme von Modell $j$ über alle Paraphrasen. Kapitel 9 schreibt dasselbe $tau$ für $m$ Systeme als $(C - D) \/ binom(m, 2)$.])

#fm([Entropie-Probing für die Reihenfolge von Beispielen], [@lu2022fantastically], kap: 3, eq: ("k03-eq-globale",),
  $ p_m^v = (sum_i bb(1){hat(y)_(i,m) = v}) / (|D|), quad "GlobalE"_m = sum_(v in V) -p_m^v log p_m^v $,
  sym: [$m$: Permutation der Few-Shot-Beispiele; $D$: aus dem Modell gesampelte, ungelabelte Probing-Menge; $V$: Labelmenge; $hat(y)_(i,m)$: vorhergesagtes Label für Probing-Eingabe $i$. Gewählt werden die Permutationen mit höchster Entropie.])

#fm([Self-Consistency (Mehrheitsentscheid)], [@wang2023selfconsistency], kap: [3, 10], eq: ("k03-eq-sc", "k03-eq-condorcet", "k10-eq-mehrheit"),
  $ hat(a) = arg max_a sum_(i=1)^N bb(1)(a_i = a), quad quad P_N (p) = sum_(k = (N+1)/2)^N binom(N, k) p^k (1-p)^(N-k) $,
  sym: [$a_i$: Endantwort des $i$-ten gesampelten Reasoning-Pfads; $N$: Zahl der Pfade (rechts ungerade); $P_N (p)$: Wahrscheinlichkeit einer richtigen Mehrheit, wenn jeder Pfad unabhängig mit Wahrscheinlichkeit $p$ richtig ist (Condorcet; in Kapitel 10 mit $q$ für wiederholte Läufe). Die Kosten für Ausgabetokens wachsen linear in $N$.])

#fm([Korrektheit über wiederholte Versuche], [@meincke2025promptinga], kap: 3, eq: ("k03-eq-schwelle",),
  $ "Acc"_theta = 1/Q sum_(q=1)^Q bb(1) [ 1/n sum_(t=1)^n c_(q,t) >= theta ], quad theta in {1.0, 0.9, 0.51} $,
  sym: [$Q$: Zahl der Fragen; $n$: Versuche pro Frage; $c_(q,t) in {0, 1}$: Korrektheit von Versuch $t$. Schlussfolgerungen können vom Schwellenwert $theta$ abhängen; ihn aus der Anwendung ableiten und präregistrieren.])

#fm([Kosten pro Aufruf und Prompt-Caching], [@anthropic2026pricing; @anthropic2026prompt], kap: 3, eq: ("k03-eq-kosten", "k03-eq-cache", "k03-eq-breakeven"),
  $ C = (n_"in" dot p_"in" + n_"out" dot p_"out") / 10^6, quad quad C_"in" = p_"in" / 10^6 sum_(j=1)^J [ n_c (h r + (1-h) w) + (n_"in" - n_c) ], quad quad h > h^* = (w - 1) / (w - r) $,
  sym: [$n_"in"$, $n_"out"$: Ein- und Ausgabetokens (Reasoning-Tokens werden als Ausgabe abgerechnet); $p_"in"$, $p_"out"$: Preise pro Million Tokens; $n_c$: gecachter gemeinsamer Präfix; $r$, $w$: Multiplikatoren für Cache-Lesen und Cache-Schreiben relativ zu $p_"in"$; $h$: Trefferrate; $J$: Zahl der Aufrufe; $h^*$: Trefferrate, ab der Caching günstiger ist. Jeder Fehltreffer schreibt den Cache neu. Werte bei Anthropic: $w$ = 1.25 (5 Minuten) oder 2 (1 Stunde), $r$ = 0.1 als Standard, 0.05 bei Claude Opus 5.5 und Sonnet 5.5 (Stand: 11. November 2026).])

#fm([Kompressionsrate], [@pan2024llmlingua2], kap: 3, eq: ("k03-eq-kompression",),
  $ tau = n_"compressed" / n_"original", quad "Kompressionsverhältnis" = 1 / tau $)

#fm([Langkontext: Positionslücke und effektive Länge], [@liu2024lost; @modarressi2025nolima], kap: 3, eq: ("k03-eq-deltapos", "k03-eq-leff"),
  $ Delta_"pos" = max_j "acc"(j) - min_j "acc"(j), quad quad L_"eff" = max { L in cal(L) : S(L) > 0.85 dot S_"base" } $,
  sym: [$"acc"(j)$: Accuracy, wenn die relevante Information an Position $j$ von $k$ Dokumenten steht ($Delta_"pos"$ ist eine abgeleitete Zusammenfassung, nicht von den Autoren definiert); $cal(L)$: getestete Kontextlängen; $S(L)$: Score bei Länge $L$; $S_"base"$: mittlerer Bestwert aus den Tests mit 250, 500 und 1000 Tokens.])

== LLMs als Forschungsinstrument <anh-a-instrument>

#fm([Repräsentativität von Meinungsverteilungen (OpinionQA)], [@santurkar2023whose], kap: [4, 8], eq: ("k04-eq-align", "k08-eq-opinionqa"),
  $ cal(A)(D_1, D_2; Q) = 1 / (|Q|) sum_(q in Q) (1 - ("WD"(D_1(q), D_2(q))) / (N_q - 1)) $,
  sym: [$Q$: Menge der Multiple-Choice-Fragen; $D_1(q)$, $D_2(q)$: Antwortverteilung des Modells bzw. der menschlichen Gruppe; $"WD"$: 1-Wasserstein-Distanz mit ordinalen Optionen $1, dots, N_q$ (@anh-a-divergenz); $N_q$: Zahl der Antwortoptionen ohne Verweigerung. Wertebereich $[0, 1]$, 1 heißt identische Verteilungen. Ein Modell mit richtigem Modus und kollabierter Streuung kann 0.80 erreichen.])

#fm([Cramérs $V$], [Standarddefinition, verwendet in @argyle2023out], kap: 4, eq: ("k04-eq-cramer",),
  $ V = sqrt(chi^2 / (n dot (min(r, c) - 1))) $,
  sym: [$chi^2$: Pearsons Chi-Quadrat-Statistik der $r times c$-Kontingenztafel; $n$: Zahl der Beobachtungen. Vergleich der Assoziationsmuster zwischen menschlichen und synthetischen Daten.])

#fm([Normalisierte Accuracy gegen die Test-Retest-Obergrenze], [@park2024llm], kap: 4, eq: ("k04-eq-na", "k04-eq-atten"),
  $ "NA"_i = "acc"(hat(y)_i, y_i^((1))) / "acc"(y_i^((2)), y_i^((1))), quad quad |"corr"(X, Y)| <= sqrt(rho_X rho_Y) $,
  sym: [$y_i^((1))$, $y_i^((2))$: Antworten von Person $i$ in Welle 1 und zwei Wochen später; $hat(y)_i$: Vorhersage des Agenten. 1 heißt: Der Agent sagt die Person so gut vorher, wie sie sich selbst reproduziert. Beispiel: 65.67 Prozent gegen 79.53 Prozent ergibt etwa 0.83. Rechts die Attenuierungsgrenze: Mit den Reliabilitäten $rho_X$, $rho_Y$ kann keine beobachtete Korrelation größer sein.])

#fm([Effektvalidität simulierter Experimente], [@li2026statistical], kap: 4,
  $ "ATE" = macron(y)_T - macron(y)_C, quad hat("ATE")^"LLM" = macron(hat(y))_T - macron(hat(y))_C, quad "ATE-Fehler" = |hat("ATE")^"LLM" - hat("ATE")^"Mensch"|, quad "MAE" = 1 / n sum_(i=1)^n |hat(y)_i - y_i| $,
  sym: [$macron(y)_T$, $macron(y)_C$: Mittelwerte in Treatment- und Kontrollgruppe. Der MAE misst statistischen Realismus auf Antwortebene, der ATE-Fehler die Validität des Effekts; beides kann auseinanderfallen.])

#fm([Kontinuierliches Rating aus Token-Wahrscheinlichkeiten], [@mangiaterra2025can], kap: 4, eq: ("k04-eq-logprob",),
  $ hat(r) = (sum_(k in "Top-3") p_k dot k) / (sum_(k in "Top-3") p_k) $,
  sym: [$k$: Ratingwert; $p_k$: Wahrscheinlichkeit des entsprechenden Tokens unter den drei wahrscheinlichsten.])

#fm([Bewertungsmaß von Centaur], [@binz2025foundation], kap: 4, eq: ("k04-eq-nll",),
  $ "NLL" = -1/N sum_(n=1)^N log p_theta (r_n | c_n) $,
  sym: [$r_n$: menschliche Antwort in Durchgang $n$ (Log-Likelihood über ihre Tokens summiert); $c_n$: Experimentverlauf bis zu diesem Durchgang; $p_theta$: Modell. Kleiner ist besser.])

#fm([Gedächtnisabruf generativer Agenten], [@park2023generative], kap: 4, eq: ("k04-eq-retrieval",),
  $ "score"(m) = alpha_"rec" dot "recency"(m) + alpha_"imp" dot "importance"(m) + alpha_"rel" dot "relevance"(m, q) $,
  sym: [$m$: Gedächtnisobjekt; recency: exponentieller Zerfall mit Faktor 0.995; importance: vom LLM vergebene ganze Zahl 1 bis 10; relevance: Kosinusähnlichkeit zur Anfrage $q$; alle Komponenten min-max-normiert, alle $alpha = 1$.])

== Übereinstimmungsmaße <anh-a-uebereinstimmung>

#fm([Kontingenztafel und gemeinsame Form der zufallskorrigierten Koeffizienten], [@cohen1960coefficient; @artstein2008inter], kap: 5, eq: ("k05-eq-notation", "k05-eq-po", "k05-eq-allgemein"),
  $ p_(i j) = n_(i j) / n, quad p_(i dot) = sum_j p_(i j), quad p_(dot j) = sum_i p_(i j), quad quad p_o = sum_(k=1)^K p_(k k), quad quad "coef" = (p_o - p_e) / (1 - p_e) $,
  sym: [$n_(i j)$: Einheiten, die Codierer A in Kategorie $i$ und Codierer B in $j$ einordnet; $p_(i dot)$, $p_(dot j)$: Randanteile; $p_o$: beobachtete Übereinstimmung (Prozentübereinstimmung); $p_e$: Zufallsübereinstimmung unter dem jeweiligen Zufallsmodell. Die Koeffizienten unterscheiden sich *nur* in $p_e$.])

#fm([Cohens Kappa und gewichtetes Kappa], [@cohen1960coefficient], kap: [5, 7], eq: ("k05-eq-kappa", "k05-eq-wkappa", "k05-eq-se"),
  $ p_e^C = sum_(k=1)^K p_(k dot) thin p_(dot k), quad kappa = (p_o - p_e^C) / (1 - p_e^C), quad quad kappa_w = 1 - (sum_(i, j) w_(i j) thin p_(i j)) / (sum_(i, j) w_(i j) thin p_(i dot) thin p_(dot j)) $,
  sym: [$p_e^C$: Zufallsübereinstimmung, wenn jeder Codierer unabhängig nach *seiner eigenen* Randverteilung labelt; $w_(i j)$: Gewicht der Nichtübereinstimmung, linear $|i - j|$, quadratisch $(i - j)^2$. Wertebereich $-1$ bis 1, 0 heißt Zufallsniveau. Grober Standardfehler: $"SE"(kappa) approx sqrt(p_o (1 - p_o) \/ n) \/ (1 - p_e)$.])

#fm([Kappa für die binäre $2 times 2$-Tafel (Richter gegen Mensch)], [@thakur2025judging], kap: 7, eq: ("k07-eq-po", "k07-eq-pe-cohen", "k07-eq-pe-scott", "k07-eq-kappa-closed"),
  $ p_o = ("TP" + "TN") / ("TP" + "FP" + "TN" + "FN"), quad p_e^kappa = (("TP" + "FP")("TP" + "FN") + ("TN" + "FN")("TN" + "FP")) / N^2, quad p_e^pi = overline(p)_+^2 + overline(p)_-^2 $,
  $ kappa = (2 ("TP" dot "TN" - "FP" dot "FN")) / (("TP" + "FP")("FP" + "TN") + ("TP" + "FN")("FN" + "TN")) $,
  sym: [$"TP"$/$"TN"$: Mensch und Richter sagen beide "korrekt"/"inkorrekt"; $"FP"$: Richter "korrekt", Mensch "inkorrekt"; $"FN"$: umgekehrt; $N$: Zahl der Urteile; $overline(p)_+$, $overline(p)_-$: gepoolte Anteile von "korrekt" und "inkorrekt" (Scotts $pi$). Beispiel $"TP" = 60$, $"TN" = 20$, $"FP" = 15$, $"FN" = 5$: $p_o$ = 0.80, $kappa approx$ 0.53, Scotts $pi approx$ 0.52.])

#fm([Scotts Pi und Fleiss' Kappa], [@scott1955reliability; @fleiss1971measuring], kap: 5, eq: ("k05-eq-scott", "k05-eq-scott-cohen", "k05-eq-fleiss-p", "k05-eq-fleiss"),
  $ p_e^S = sum_k overline(p)_k^2, quad overline(p)_k = (p_(k dot) + p_(dot k)) / 2, quad pi_S = (p_o - p_e^S) / (1 - p_e^S), quad quad p_e^S - p_e^C = 1/4 sum_(k=1)^K (p_(k dot) - p_(dot k))^2 >= 0 $,
  $ P_i = 1 / (r(r - 1)) sum_(k=1)^K n_(i k)(n_(i k) - 1), quad overline(P) = 1 / N sum_(i=1)^N P_i, quad overline(P)_e = sum_(k=1)^K p_k^2, quad kappa_F = (overline(P) - overline(P)_e) / (1 - overline(P)_e) $,
  sym: [Scotts $pi$ poolt die Randverteilungen beider Codierer; seine Zufallsübereinstimmung ist nie kleiner als die von Cohen. Fleiss: $N$ Einheiten, $r$ Ratende pro Einheit; $n_(i k)$: Zahl der Ratenden, die Einheit $i$ Kategorie $k$ zuordnen; $P_i$: Anteil übereinstimmender Ratendenpaare; $p_k = 1 \/ (N r) sum_i n_(i k)$: Gesamtanteil von Kategorie $k$. Für $r = 2$ ist Fleiss' Kappa gleich Scotts Pi.])

#fm([Krippendorffs Alpha], [@krippendorff2018content; @hayes2007answering], kap: 5, eq: ("k05-eq-koinzidenz", "k05-eq-alpha", "k05-eq-delta", "k05-eq-alpha-nom"),
  $ o_(c k) = sum_u (\#{(c, k) "-Paare in Einheit" u}) / (m_u - 1), quad n_c = sum_k o_(c k), quad n = sum_c n_c $,
  $ alpha = 1 - D_o / D_e, quad D_o = 1/n sum_c sum_k o_(c k) thin delta_(c k)^2, quad D_e = 1 / (n(n - 1)) sum_c sum_k n_c thin n_k thin delta_(c k)^2 $,
  $ delta^2_"nom" = cases(0 & "falls" c = k, 1 & "sonst"), quad delta^2_"int" = (c - k)^2, quad delta^2_"ord" = (sum_(g=c)^k n_g - (n_c + n_k)/2)^2 quad (c < k), quad quad alpha_"nom" = 1 - (n - 1) (sum_(c != k) o_(c k)) / (n^2 - sum_c n_c^2) $,
  sym: [$u$: Einheit; $m_u$: Zahl der Werte für $u$ (Einheiten mit $m_u < 2$ entfallen); $o_(c k)$: Koinzidenzmatrix aus geordneten Wertepaaren; $n$: Zahl paarbarer Werte. Die letzte Formel gilt für zwei Codierer, nominale Daten und keine fehlenden Werte. Alpha erlaubt beliebig viele Codierende, fehlende Werte und verschiedene Skalenniveaus. Nicht mit dem Signifikanzniveau $alpha$ verwechseln.])

#fm([Gwets AC1 und Brennan-Prediger (PABAK)], [@gwet2008computing; @byrt1993bias], kap: 5, eq: ("k05-eq-ac1", "k05-eq-pabak", "k05-eq-praevalenz"),
  $ "AC1" = (p_o - p_e^G) / (1 - p_e^G), quad p_e^G = 1 / (K - 1) sum_(k=1)^K overline(p)_k (1 - overline(p)_k), quad quad "BP" = (K p_o - 1) / (K - 1), quad "PABAK" = 2 p_o - 1 quad (K = 2) $,
  sym: [$overline(p)_k$: gepoolter Anteil wie bei Scotts Pi; $K$: Zahl der Kategorien. AC1 senkt die Zufallsübereinstimmung, wenn eine Kategorie dominiert; BP verwendet ein Gleichverteilungsmodell $p_e = 1\/K$ und ist für zwei Ratende identisch mit Randolphs Free-Marginal-Kappa.])

#fm([Intraklassenkorrelation (McGraw und Wong)], [@mcgraw1996forming; @liljequist2019intraclass], kap: 5, eq: ("k05-eq-icc", "k05-eq-icc11", "k05-eq-icc2"),
  $ "ICC"(A, 1) = ("MS"_R - "MS"_E) / ("MS"_R + (k - 1) "MS"_E + k/n ("MS"_C - "MS"_E)), quad "ICC"(C, 1) = ("MS"_R - "MS"_E) / ("MS"_R + (k - 1) "MS"_E) $,
  $ "ICC"(1, 1) = ("MS"_R - "MS"_W) / ("MS"_R + (k - 1) "MS"_W), quad "ICC"(A, k) = ("MS"_R - "MS"_E) / ("MS"_R + ("MS"_C - "MS"_E) \/ n), quad "ICC"(C, k) = ("MS"_R - "MS"_E) / "MS"_R $,
  sym: [$n$ Ziele (Zeilen), $k$ Ratende (Spalten); $"MS"_R$, $"MS"_C$: mittlere Quadrate der Zeilen bzw. Spalten; $"MS"_E$: Residuum des zweifaktoriellen Modells; $"MS"_W$: innerhalb der Ziele (einfaktoriell). A = absolute Übereinstimmung (systematische Verschiebung senkt den Wert), C = Konsistenz (Verschiebungen werden ignoriert). Für LLM-gegen-Mensch-Ratings ICC(A,1) und ICC(C,1) gemeinsam berichten. Benennung wie in pingouin 0.7.0 (Stand: 11. November 2026).])

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    align: (left, center, center, center, center, center, center, center),
    table.header([Tafel], [Präv. Kl. 0], [$p_o$], [$kappa$], [$pi_S$], [$alpha$], [AC1], [PABAK]),
    [[[45, 5], [5, 45]]], [0.50], [0.90], [0.800], [0.800], [0.801], [0.800], [0.800],
    [[[85, 5], [5, 5]]], [0.90], [0.90], [0.444], [0.444], [0.447], [0.878], [0.800],
    [[[90, 5], [5, 0]]], [0.95], [0.90], [−0.053], [−0.053], [−0.047], [0.890], [0.800],
  ),
  caption: [Prävalenzparadox: gleiche prozentuale Übereinstimmung, verschiedene Koeffizienten (Kapitel 5, vgl. @k05-eq-praevalenz). $alpha$ ist hier Krippendorffs Alpha. Kappa und Alpha zeigen in der letzten Zeile korrekt, dass über die seltene Klasse keine Übereinstimmung besteht; AC1 verdeckt das @gwet2008computing.],
) <anh-a-tab-paradox>

#figure(
  table(
    columns: (auto, 1fr),
    table.header([Maß], [Grenzen (mit Vorsicht verwenden)]),
    [Kappa nach Landis und Koch @landis1977measurement], [< 0 schlecht; 0.00-0.20 gering; 0.21-0.40 ausreichend; 0.41-0.60 mittelmäßig; 0.61-0.80 beachtlich; 0.81-1.00 fast vollkommen. Die Autoren nennen die Einteilung selbst "eindeutig willkürlich".],
    [Kappa nach McHugh @mchugh2012interrater], [Jedes Kappa unter 0.60 zeigt unzureichende Übereinstimmung; Prozentübereinstimmung und Kappa gemeinsam berichten.],
    [Krippendorffs Alpha], [$alpha >= 0.800$ verlässlich, $0.667 <= alpha < 0.800$ für vorläufige Schlüsse, üblicherweise @krippendorff2018content zugeschrieben; Hayes und Krippendorff legen keine feste Grenze fest @hayes2007answering.],
  ),
  caption: [Interpretationsschwellen. Besser als jede feste Grenze ist der Vergleich mit der Mensch-Mensch-Übereinstimmung auf denselben Items @tornberg2024best.],
) <anh-a-tab-schwellen>

#fm([Alternative Annotator Test (Alt-Test)], [@calderon2025alternative], kap: [5, 7],
  $ W_(i j)^f = bb(1)[S_i (f, j) >= S_i (h_j)], quad W_(i j)^h = bb(1)[S_i (h_j) >= S_i (f, j)], quad rho_j^f = 1/n sum_i W_(i j)^f, quad rho_j^h = 1/n sum_i W_(i j)^h $,
  $ H_0: rho_j^f <= rho_j^h - epsilon quad "gegen" quad H_1: rho_j^f > rho_j^h - epsilon, quad t_j = (overline(d)_j - epsilon) \/ (s_j \/ sqrt(n)), quad d_(i j) = W_(i j)^h - W_(i j)^f $,
  $ omega = 1/m sum_j bb(1)[H_(0 j) "verworfen"], quad quad rho = 1/m sum_j rho_j^f $,
  sym: [$m >= 3$ menschliche Annotatoren $h_1, dots, h_m$, LLM $f$, $n$ Instanzen (mindestens 30, meist 50 bis 100); $S_i (f, j)$, $S_i (h_j)$: Übereinstimmung von LLM bzw. Annotator $j$ mit den übrigen Annotatoren (Genauigkeit, $-"RMSE"$ oder Ähnlichkeitsmaß); $epsilon$: Spielraum für die Kosten-Nutzen-Abwägung (0.2 Fachleute, 0.15 geschulte Annotatoren, 0.1 Crowdworker); Benjamini-Yekutieli-Kontrolle der FDR bei $q$ = 0.05; bestanden, wenn $omega >= 0.5$; $rho$: mittlere Vorteilswahrscheinlichkeit. Bei $n < 30$ Wilcoxon-Vorzeichen-Rang-Test statt $t_j$.])

#fm([Adjusted Rand Index für Themenzuordnungen], [@bergmann2026llms], kap: 5, eq: ("k05-eq-ari-erwartung", "k05-eq-ari"),
  $ E[a] = (sum_i binom(a_i, 2) thin sum_j binom(b_j, 2)) / binom(n, 2), quad quad "ARI" = (sum_(i j) binom(n_(i j), 2) - E[a]) / (1/2 [sum_i binom(a_i, 2) + sum_j binom(b_j, 2)] - E[a]) $,
  sym: [$n_(i j)$: Antworten in menschlichem Thema $i$ und LLM-Thema $j$; $a_i$, $b_j$: Zeilen- und Spaltensummen; $n$: Zahl der Antworten; $E[a]$: erwartete Zahl gemeinsam gruppierter Paare unter Zufall. 1 = identische Partitionen, um 0 = Zufallsniveau, negative Werte möglich. Formel wie in `sklearn.metrics.adjusted_rand_score`.])

#fm([Induktive thematische Sättigung (ITS)], [@depaoli2025reflections], kap: 5, eq: ("k05-eq-its",),
  $ "ITS" = U_K / T_K $,
  sym: [$U_K$: kumulierte Zahl einzigartiger Codes nach dem letzten Interview $K$; $T_K$: kumulierte Zahl aller Codes. Nahe 1: kaum Sättigung; deutlich unter 1: Sättigung. Steigungsvarianten sind Erweiterungen, nicht die publizierte Operationalisierung.])

== Valide Inferenz mit LLM-Labels <anh-a-inferenz>

#fm([Verzerrung der naiven Prävalenzschätzung], [elementare Herleitung], kap: 6, eq: ("k06-eq-prevbias", "k06-eq-youden"),
  $ EE[hat(Y)] = s theta + r (1 - theta), quad "Bias" = EE[hat(Y)] - theta = r - (1 - s + r) theta, quad quad tilde(beta) = (s - r) beta = (s + "Spezifität" - 1) beta $,
  sym: [$theta = PP(Y = 1)$: wahre Prävalenz; $s = PP(hat(Y) = 1 | Y = 1)$: Sensitivität; $r = PP(hat(Y) = 1 | Y = 0)$: Falsch-positiv-Rate. Bei symmetrischer Accuracy wird $EE[hat(Y)]$ Richtung 0.5 gezogen. Rechts: Ein nichtdifferenziell fehlklassifiziertes binäres Outcome schwächt einen Regressionskoeffizienten $beta$ um den Youden-Index ab.])

#fm([Prediction-Powered Inference (PPI) für einen Mittelwert], [@angelopoulos2023prediction], kap: [6, 9], eq: ("k06-eq-zerlegung", "k06-eq-ppi", "k06-eq-ppi-ci", "k06-eq-ppi-var"),
  $ hat(theta)^"PP" = underbrace(1/N sum_(i=1)^N f(tilde(X)_i), tilde(theta)^f) - underbrace(1/n sum_(i=1)^n (f(X_i) - Y_i), hat(Delta)), quad quad C_alpha^"PP" = [hat(theta)^"PP" plus.minus z_(1 - alpha slash 2) sqrt(hat(sigma)_(f - Y)^2 / n + hat(sigma)_f^2 / N)] $,
  sym: [$n$, $N$: Zahl gelabelter bzw. ungelabelter Einheiten; $f(dot)$: LLM-Label oder -Wahrscheinlichkeit; $hat(Delta)$: empirischer Rektifikator (mittlerer LLM-Fehler auf der Goldstichprobe); $hat(sigma)_f^2$: Varianz der LLM-Labels auf den ungelabelten Daten; $hat(sigma)_(f - Y)^2$: Varianz des Rektifikators. Asymptotische Überdeckung $>= 1 - alpha$. PPI mit $lambda = 1$ kann schlechter sein als die klassische Schätzung, vor allem wenn $N$ nicht deutlich größer als $n$ ist.])

#fm([PPI für konvexe Schätzprobleme und OLS], [@angelopoulos2023prediction], kap: 6, eq: ("k06-eq-mest", "k06-eq-gradrect", "k06-eq-ppi-ols", "k06-eq-ppi-ols-ci"),
  $ theta^star = arg min_(theta in RR^p) L(theta), quad L(theta) = EE[ell_theta (X, Y)], quad quad Delta_theta = EE[g_theta (X, Y) - g_theta (X, f(X))] $,
  $ hat(theta)^"PP" = tilde(bold(X))^dagger f(tilde(bold(X))) - bold(X)^dagger (f(bold(X)) - bold(Y)), quad quad C_alpha^"PP" = [hat(theta)_j^"PP" plus.minus z_(1 - alpha slash 2) sqrt(V_(j j) / n + tilde(V)_(j j) / N)] $,
  sym: [$ell_theta$: konvexe Verlustfunktion; $g_theta$: ihr (Sub-)Gradient; $bold(X)$, $tilde(bold(X))$: Designmatrizen der gelabelten und ungelabelten Daten; $A^dagger$: Moore-Penrose-Pseudoinverse; $V = Sigma^(-1) M Sigma^(-1)$, $tilde(V) = tilde(Sigma)^(-1) tilde(M) tilde(Sigma)^(-1)$: Sandwich-Varianzen.])

#fm([PPI++ (Power-Tuning)], [@angelopoulos2023ppi], kap: 6, eq: ("k06-eq-ppipp-loss", "k06-eq-ppipp-mean", "k06-eq-varlambda", "k06-eq-lamstar", "k06-eq-lamhat"),
  $ L_lambda^"PP" (theta) = L_n (theta) + lambda (L_N^f (theta) - L_n^f (theta)), quad hat(theta)_lambda^"PP" = arg min_theta L_lambda^"PP" (theta), quad quad hat(theta)_lambda^"PP" = overline(Y)_n + lambda (tilde(theta)^f - overline(f)_n) $,
  $ n Var(hat(theta)_lambda^"PP") = sigma_Y^2 - 2 lambda c + lambda^2 (1 + r) sigma_f^2, quad lambda^star = c / ((1 + r) sigma_f^2), quad hat(lambda) = (hat(Cov)_n (Y_i, f(X_i))) / ((1 + n/N) hat(Var)_(N + n) (f(X_i))) $,
  sym: [$L_n$: Verlust mit Goldlabels; $L_n^f$: Verlust mit LLM-Labels auf den Golditems; $L_N^f$: Verlust mit LLM-Labels auf den ungelabelten Items; $sigma_Y^2 = Var(Y)$, $sigma_f^2 = Var(f(X))$, $c = Cov(Y, f(X))$, $r = n slash N$. $lambda = 1$ ist PPI, $lambda = 0$ klassische Inferenz. Die Mittelwertform ist eine Kontrollvariate. Mit $lambda^star$ ist PPI++ asymptotisch nie weniger effizient als klassische Inferenz; `ppi_py` 0.2.3 beschneidet $hat(lambda)$ auf $[0, 1]$.])

#fm([Asymptotik von PPI++], [@angelopoulos2023ppi], kap: 6, eq: ("k06-eq-sandwich", "k06-eq-ppipp-sigma", "k06-eq-lamstar-gen"),
  $ sqrt(n)(hat(theta)_hat(lambda)^"PP" - theta^star) limits(arrow.r)^d cal(N)(0, Sigma_lambda), quad Sigma_lambda = H^(-1) (r V_f^lambda + V_Delta^lambda) H^(-1) $,
  sym: [$H = nabla^2 L(theta^star)$: Hesse-Matrix des Populationsverlusts; $V_f^lambda = lambda^2 Cov(nabla ell^f_(theta^star))$, $V_Delta^lambda = Cov(nabla ell_(theta^star) - lambda nabla ell^f_(theta^star))$ mit den Verlustgradienten $nabla ell$, $nabla ell^f$ für wahre bzw. vorhergesagte Labels. Intervall: $hat(theta)_j plus.minus z_(1 - alpha slash 2) sqrt(hat(Sigma)_(j j) \/ n)$.])

#fm([Varianz mit optimalem $lambda$ und effektive Stichprobengröße], [@angelopoulos2023ppi; @angelopoulos2024ppipy; @broska2025mixed], kap: 6, eq: ("k06-eq-varmin", "k06-eq-neff"),
  $ Var(hat(theta)_(lambda^star)^"PP") = sigma_Y^2 / n (1 - rho^2 N / (n + N)), quad rho = Corr(Y, f(X)) $,
  $ n_"eff" = n / (1 - rho^2 N slash (n + N)) = (n (n + N)) / (n + (1 - rho^2) N) quad attach(arrow.r, t: N -> infinity) quad n / (1 - rho^2) $,
  sym: [$rho$: PPI-Korrelation zwischen Gold- und LLM-Label; $n_"eff"$: Zahl der Goldlabels, die die klassische Schätzung für dieselbe Varianz bräuchte. Obergrenzen: $rho$ = 0.5 -> 1.33 $n$; 0.67 -> 1.81 $n$; 0.9 -> 5.3 $n$. Große Gewinne erfordern hohe Korrelation, nicht bloß "gute Accuracy". Formel wie `effective_n` in `ppi_py`.])

#fm([Kosten pro klassisch-äquivalentem Goldlabel], [@angelopoulos2024ppipy], kap: 6, eq: ("k06-eq-kosten",),
  $ c_"PPI" = c_Y (1 - rho^2 + gamma rho^2 + 2 sqrt(gamma rho^2 (1 - rho^2))), quad gamma = (c_(hat(Y)) + c_X) slash c_Y quad "gegenüber" quad c_"klass" = c_Y + c_X $,
  sym: [$c_Y$: Kosten eines Goldlabels; $c_(hat(Y))$: Kosten eines LLM-Labels; $c_X$: Kosten einer Einheit. Ist PPI nicht billiger, fällt die Optimierung in `ppi_py` auf $N = 0$ zurück.])

#figure(
  table(
    columns: (auto, 1fr, auto, auto),
    align: (left, left, right, right),
    table.header([Verfahren], [Standardfehler], [Breite 95 %], [gegenüber klassisch]),
    [klassisch ($n$ = 500)], [$sqrt(0.2139 \/ 500)$ = 0.02068], [0.0811], [],
    [naiv ($N_"ges"$ = 10 000)], [0.0047, aber Bias +0.018 (3.8 SE)], [0.0184], [Überdeckung fast null],
    [PPI ($lambda = 1$)], [$sqrt(0.14368 \/ 500 + 0.2204 \/ 9500)$ = 0.01762], [0.0691], [15 % schmaler],
    [PPI++ ($hat(rho)$ = 0.669)], [Varianzfaktor 0.574, $n_"eff" approx 870$], [0.0614], [24 % schmaler],
  ),
  caption: [Rechenbeispiel aus Kapitel 6: $theta$ = 0.31, LLM-Accuracy 85.6 Prozent, $n$ = 500, $N$ = 9500 (Formeln aus @angelopoulos2023prediction und @angelopoulos2023ppi).],
) <anh-a-tab-ppi>

#fm([Cross-PPI (Vorhersagemodell aus denselben Goldlabels)], [@zrnic2024cross], kap: 6, eq: ("k06-eq-crossppi",),
  $ hat(theta)^+ = 1/(K N) sum_(j=1)^K sum_(i=1)^N f^((j))(tilde(X)_i) - 1/n sum_(j=1)^K sum_(i in I_j) (f^((j))(X_i) - Y_i), quad C^+ = hat(theta)^+ plus.minus z_(1 - alpha slash 2) sqrt(n / N hat(overline(sigma))^2 + hat(overline(sigma))_Delta^2) / sqrt(n) $,
  sym: [$I_1, dots, I_K$: Folds der gelabelten Daten; $f^((j))$: auf allen Folds außer $I_j$ trainiertes Modell; $overline(sigma)^2 = Var(overline(f)(X))$, $overline(sigma)_Delta^2 = Var(overline(f)(X) - Y)$ mit dem gemittelten Modell $overline(f)$.])

#fm([Aktive statistische Inferenz], [@zrnic2024active], kap: 6, eq: ("k06-eq-active", "k06-eq-active-var", "k06-eq-pistar"),
  $ hat(theta)^pi = 1/n sum_(i=1)^n (f(X_i) + (Y_i - f(X_i)) xi_i / pi(X_i)), quad xi_i tilde "Bern"(pi(X_i)) $,
  $ Var(hat(theta)^pi) = 1/n (Var(Y) + EE[(Y - f(X))^2 (1/pi(X) - 1)]) $,
  $ pi^star (x) = b sqrt(e^2(x)) / EE[sqrt(e^2(X))], quad quad u(x) = K / (K - 1) (1 - max_(k in [K]) p_k (x)) $,
  sym: [$n$: alle Einheiten (alle mit LLM-Label); $pi(x)$: Wahrscheinlichkeit, eine Einheit menschlich labeln zu lassen; $xi_i$: Indikator dafür; $b$: Labelbudget als Anteil mit $EE[pi(X)] <= b$; $e^2(x)$: erwarteter quadrierter LLM-Fehler; $u(x)$: Unsicherheit eines $K$-Klassen-Klassifikators als praktischer Ersatz (binär $2 min{p(x), 1 - p(x)}$), mit $pi(x) prop u(x)$ auf das Budget normiert.])

#fm([Design-based Supervised Learning (DSL)], [@egami2023using], kap: 6, eq: ("k06-eq-dsl", "k06-eq-dsl-var"),
  $ tilde(Y)_i^k = hat(g)_k (Q_i, W_i, X_i) + R_i / pi(Q_i, W_i, X_i) (Y_i - hat(g)_k (Q_i, W_i, X_i)), quad quad Var(tilde(Y)) = Var(Y) + EE[(1 - pi) / pi (Y - g)^2] $,
  $ sum_k sum_(i in D_k) (tilde(Y)_i^k - "expit"(X_i^top beta)) X_i = 0 $,
  sym: [$Y$: Goldlabel (nur bei $R_i = 1$ beobachtet); $Q$: Surrogat (LLM-Label); $W$: weitere Prädiktoren; $X$: Regressoren des Analysemodells; $pi$: bekannte Ziehungswahrscheinlichkeit für Goldlabels; $hat(g)_k$: auf den Golddokumenten außerhalb von Fold $D_k$ trainiertes Modell (Kreuzanpassung). Die Momentengleichung gilt für die logistische Regression. Valide auch bei beliebig verzerrten Surrogaten; deren Qualität beeinflusst nur die Effizienz. Mit konstantem $pi$ und $hat(g) = Q$ entspricht der Mittelwert der Pseudo-Outcomes der PPI-Form.])

#fm([Confidence-Driven Inference (CDI)], [@gligoric2025can], kap: 6, eq: ("k06-eq-cdi",),
  $ hat(theta)^"conf" = 1/n sum_(i=1)^n (lambda hat(H)_i + (H_i - lambda hat(H)_i) xi_i / pi_i), quad pi_i prop sqrt(hat("err")_i (C_i)), quad quad pi_i^star prop sqrt(EE[(hat(H)_i - H_i)^2 | T_i]) $,
  sym: [$H_i$, $hat(H)_i$: menschliches bzw. LLM-Label; $T_i$: Text; $C_i in [0, 1]$: verbalisierte Konfidenz des LLM; $hat("err")_i$: gelernte Abbildung von Konfidenz auf erwarteten quadrierten Fehler; $pi_i^star$: Orakelregel; $sum_i pi_i = n_"human"$; $lambda in [0, 1]$: Power-Tuning ($lambda = 0$ nur menschlich).])

#fm([Ökonometrische Entzerrung (LLM-Label als abhängige Variable)], [@ludwig2026large], kap: 6, eq: ("k06-eq-ludwig",),
  $ hat(beta)_"debiased" = hat(beta) - hat(lambda)_(Delta | W) $,
  sym: [$hat(beta)$: OLS-Koeffizient des LLM-Labels auf die Kovariaten $W$ in der Hauptstichprobe; $hat(lambda)_(Delta | W)$: OLS-Koeffizient des LLM-Fehlers $Delta$ (LLM-Label minus menschliches Label) auf $W$ in der Validierungsstichprobe; Inferenz per Bootstrap. Entspricht dem PPI-OLS-Schätzer in ökonometrischer Notation.])

== LLM-as-a-Judge <anh-a-judge>

#fm([Nachsichtigkeit (Leniency)], [@thakur2025judging], kap: 7, eq: ("k07-eq-leniency",),
  $ hat(P)_c = ("TP" + "TN") / N, quad hat(P)_+ = "FP" / ("FP" + "FN") $,
  sym: [$P_c$: Wahrscheinlichkeit eines korrekten Urteils; $P_+$: Wahrscheinlichkeit, bei einem Fehlurteil "korrekt" zu sagen. Beispiel: $"FP" = 15$, $"FN" = 5$ ergibt $hat(P)_+$ = 0.75.])

#fm([Konfliktrate bei vertauschter Reihenfolge], [@wang2024large], kap: 7, eq: ("k07-eq-conflict",),
  $ "Konfliktrate" = 1 / N sum_(i=1)^N bb(1)("ER"_i^(r 12) != "ER"_i^(r 21)) $,
  sym: [$N$: Zahl der Paare; $"ER"_i^(r 12)$, $"ER"_i^(r 21)$: Urteil in Original- und vertauschter Reihenfolge. Die Positionskonsistenz ist der komplementäre Anteil.])

#fm([Kalibrierung über Evidenz und Position (MEC, BPC) und BPDE], [@wang2024large], kap: 7, eq: ("k07-eq-bpc", "k07-eq-bpde"),
  $ "CS"_r = 1 / (2 k) sum_(i=1)^k (S_r^i + S_r^(prime i)), quad quad "BPDE" = sum_("er" in {"win", "tie", "lose"}) -p_"er" log p_"er", quad p_"er" = (sum_(i=1)^k [bb(1)("ER"_i = "er") + bb(1)("ER"'_i = "er")]) / (2 k) $,
  sym: [$S_r^i$, $S_r^(prime i)$: Score von Antwort $r$ in Stichprobe $i$ in Original- bzw. vertauschter Reihenfolge; $k$: Stichproben pro Reihenfolge (z. B. 3). Hohe BPDE heißt instabiles Urteil; die obersten 20 Prozent gehen an Menschen. Beispiel win, win, win, tie, lose, lose: BPDE $approx$ 1.01 nats (Maximum $ln 3 approx 1.10$).])

#fm([Wahrscheinlichkeitsgewichteter Score (G-Eval)], [@liu2023geval], kap: 7, eq: ("k07-eq-geval",),
  $ "score" = sum_(i=1)^n p(s_i) dot s_i $,
  sym: [$s_i$: im Prompt definierte Scorestufen; $p(s_i)$: Wahrscheinlichkeit des Tokens für $s_i$. Beispiel $p = (0.05, 0.10, 0.20, 0.40, 0.25)$ für 1 bis 5 ergibt 3.70 statt des Modalwerts 4.])

#fm([Bradley-Terry-Modell für Paarvergleiche], [@chiang2024chatbot], kap: 7, eq: ("k07-eq-bt", "k07-eq-bt-ll", "k07-eq-active"),
  $ P(m succ m') = 1 / (1 + e^(xi_(m') - xi_m)) = sigma(xi_m - xi_(m')) $,
  $ ell(xi) = sum_(t=1)^T [y_t log sigma(xi_(a_t) - xi_(b_t)) + (1 - y_t) log sigma(xi_(b_t) - xi_(a_t))] $,
  sym: [$xi in bb(R)^M$: latente Stärken der $M$ Modelle, $xi_1 = 0$ fixiert; $sigma$: logistische Funktion; $y_t = 1$, wenn im Vergleich $t$ Modell $a_t$ gegen $b_t$ gewinnt. Schätzung per logistischer Regression (bei ungleichmäßiger Paarauswahl mit Gewicht $1 \/ P(A_t)$); Unsicherheit per Bootstrap oder Sandwich-Fehler. Beispiel: $xi_A - xi_B = 0.5$ -> $P(A succ B) approx$ 0.62. Setzt Transitivität und einen zusammenhängenden Vergleichsgraphen voraus.])

#fm([Längenkontrollierte Gewinnrate (AlpacaEval LC)], [@dubois2024length], kap: 7, eq: ("k07-eq-lc-glm", "k07-eq-lc"),
  $ P(y = 1) = "logistic"((theta_m - theta_b) + phi_(m,b) tanh(("len"(z_m) - "len"(z_b)) / ("std"("len"(z_m) - "len"(z_b)))) + (psi_m - psi_b) gamma_x) $,
  $ "winrate"^"LC" (m, b) = 100 dot bb(E)_x ["logistic"(theta_m - theta_b + (psi_m - psi_b) gamma_x)] $,
  sym: [$theta_m$, $theta_b$: Modellterme; $phi_(m,b)$: Längenkoeffizient; $z_m$, $z_b$: Ausgaben von Modell und Baseline; $psi$, $gamma_x$: Schwierigkeitsterme der Instruktion $x$. Die LC-Gewinnrate ist die kontrafaktische Gewinnrate bei Längendifferenz null.])

#fm([Pair-Rank-Brier-Score für Benchmarks], [@li2025crowdsourced], kap: 7, eq: ("k07-eq-brier",),
  $ "Brier" = 1 / N sum_({i, j}) (hat(P)(f^*(pi_i) < f^*(pi_j)) - O_(pi_i prec pi_j))^2 $,
  sym: [$N$: Zahl der Modellpaare; $hat(P)$: per Bootstrap geschätzte Wahrscheinlichkeit, dass Modell $pi_i$ schlechter abschneidet als $pi_j$; $O$: Indikator des menschlichen Referenzrankings. Ergänzend: Separierbarkeit mit Konfidenz (Anteil der Paare mit nicht überlappenden Bootstrap-Intervallen) und Übereinstimmung mit Konfidenz.])

#fm([Alignment eines Assertion-Sets (EvalGen)], [@shankar2024validates], kap: 7, eq: ("k07-eq-evalgen",),
  $ "Alignment"(S) = (2 dot "Coverage"(S) dot (1 - "FFR"(S))) / ("Coverage"(S) + (1 - "FFR"(S))) $,
  sym: [Coverage: Anteil der vom Menschen als schlecht bewerteten Ausgaben, die mindestens eine Assertion verletzen; FFR (False Failure Rate): Anteil der guten Ausgaben, die mindestens eine Assertion verletzen.])

#fm([Implizite Belohnung DPO-trainierter Modelle], [@lambert2025rewardbench], kap: 7,
  $ r(x, y) = beta log (pi(y | x)) / (pi_"ref" (y | x)) + beta log Z(x) $,
  sym: [$pi$: trainierte Policy; $pi_"ref"$: Referenzmodell; $beta$: DPO-Temperatur; $Z(x)$: Partitionsfunktion, die sich im Vergleich kürzt. Ein Tripel gilt als korrekt, wenn $r(x, y_c) > r(x, y_r)$ (Zufallsniveau 50 Prozent).])

#fm([Robustheits- und Konsistenzrate (CALM)], [@ye2025justice], kap: [7, 8], eq: ("k07-eq-rr", "k08-eq-rrcr"),
  $ "RR" = 1 / (|D|) sum_(i=1)^(|D|) bb(1)(y_i = hat(y)_i), quad "CR" = 1 / (|D|) sum_(i=1)^(|D|) bb(1)(y_i = y_i^"rand"), quad quad "ErrorRate"_"SE" = y_"self" \/ y_"other" - 1 $,
  sym: [$y_i$: Originalurteil; $hat(y)_i$: Urteil nach einer biasspezifischen Störung; $y_i^"rand"$: Urteil eines wiederholten ungestörten Laufs. RR ist nur relativ zu CR interpretierbar. $y_"self"$: Score, den ein Richter der eigenen Antwort gibt; $y_"other"$: Score anderer Richter für dieselbe Antwort.])

#fm([Wiederholungsstabilität und Positionskonsistenz], [@shi2025judging], kap: 7, eq: ("k07-eq-shi",),
  $ "RS" = 1 / N sum_(j=1)^N (max_(k in S) |C_k^j|) / n_j, quad "PC" = 1 / n sum_(j=1)^n bb(1)((C_1^j, dots, C_p^j) in V) $,
  sym: [$n_j$: Wiederholungen von Anfrage $j$; $|C_k^j|$: wie oft Option $k$ gewählt wurde; $S$: Optionsmenge; $(C_1^j, dots, C_p^j)$: Urteile über $p$ Permutationen; $V$: Menge konsistenter Urteilstupel.])

#fm([Checklisten-Score (TICK)], [@cook2024ticking], kap: 7, eq: ("k07-eq-tick",),
  $ "PassRate"(r) = 1 / (|Q|) sum_(q in Q) bb(1)(J(q, r) = "YES") $,
  sym: [$Q$: vom LLM erzeugte Checkliste aus Ja/Nein-Fragen; $J(q, r)$: Antwort des Richters auf Frage $q$ für Antwort $r$.])

#fm([Grenze der Labelersparnis (Dorner-Schranke)], [@dorner2025limits], kap: 7, eq: ("k07-eq-ppi", "k07-eq-tau", "k07-eq-ag", "k07-eq-rho-binaer"),
  $ hat(theta)_lambda = lambda dot overline(tilde(s))_N + 1 / n sum_(i=1)^n (s_i - lambda tilde(s)_i), quad quad tau = 1 / (1 - rho^2) $,
  $ "AG" = b p + (1 - b) q, quad quad rho^2 = (b (1 - b)(p + q - 1)^2) / (c (1 - c)), quad quad 0.5 <= "AG" <= b quad => quad rho^2 <= 0.5, quad tau <= 2 $,
  sym: [$s_i$: binärer Referenzscore (menschlich), $tilde(s)_i$: Richterscore; $tau$: Faktor, um den sich die menschliche Stichprobe bei optimalem $lambda$ und $N -> infinity$ effektiv vervielfacht; $rho$: Pearson-Korrelation zwischen $s$ und $tilde(s)$; $b = P(s = 1)$: wahre Accuracy des bewerteten Modells; $p = P(tilde(s) = s | s = 1)$, $q = P(tilde(s) = s | s = 0)$; $c = P(tilde(s) = 1)$. Kein unverzerrter Black-Box-Schätzer ist besser; die Zweierschranke gilt, wenn der Richter nicht besser urteilt, als das Modell seine Aufgabe löst. Beispiel $rho$ = 0.6: $tau approx 1.56$.])

== Bias und Fairness <anh-a-bias>

#fm([Word Embedding Association Test (WEAT)], [@caliskan2017semantics], kap: 8, eq: ("k08-eq-weat-s", "k08-eq-weat-stat", "k08-eq-weat-d", "k08-eq-dpop"),
  $ s(w, A, B) = op("mean")_(a in A) cos(arrow(w), arrow(a)) - op("mean")_(b in B) cos(arrow(w), arrow(b)), quad quad s(X, Y, A, B) = sum_(x in X) s(x, A, B) - sum_(y in Y) s(y, A, B) $,
  $ d = (op("mean")_(x in X) s(x, A, B) - op("mean")_(y in Y) s(y, A, B)) / (op("std-dev")_(w in X union Y) s(w, A, B)), quad quad p = Pr_i [s(X_i, Y_i, A, B) > s(X, Y, A, B)] $,
  sym: [$X$, $Y$: Zielwortmengen (z. B. männliche und weibliche Namen); $A$, $B$: Attributmengen (z. B. Karriere- und Familienwörter); $(X_i, Y_i)$: alle gleich großen Partitionen von $X union Y$ (einseitiger Permutationstest; die Formel verwendet ">", der Text "oder größer"). Weil die Standardabweichung über $X union Y$ auch den Gruppenunterschied enthält, ist $d$ nach oben beschränkt; ob Stichproben- oder Populations-SD verwendet wird, ist nicht festgelegt und muss berichtet werden. SEAT überträgt den Test auf Satzeinbettungen.])

#fm([CrowS-Pairs-Score], [@nangia2020crows], kap: 8, eq: ("k08-eq-crows",),
  $ "score"(S) = sum_(i = 0)^(|C|) log P(u_i in U | U_(without u_i), M, theta) $,
  sym: [$U$: unveränderte Tokens (werden nacheinander maskiert); $M$: gruppenkennzeichnende Tokens (nie maskiert); $theta$: Modellparameter; der obere Index $|C|$ ist wie im Original gedruckt und bezeichnet die Zahl der unveränderten Tokens. Metrik: Anteil der Paare mit $"score"(S_1) > "score"(S_2)$, ideal 50. Für Decoder-Modelle ändert die Ersatzgröße (Satz-Log-Likelihood) die Metrik.])

#fm([Log-Probability Bias Score], [@gallegos2024bias], kap: 8, eq: ("k08-eq-lpbs",),
  $ "LPBS"(S) = log p_(a_i) / p_("prior"_i) - log p_(a_j) / p_("prior"_j) $,
  sym: [$p_(a_i)$: Wahrscheinlichkeit des Attributtokens $a_i$ (z. B. "he") in einer Vorlage mit Zielwort; $p_("prior"_i)$: dieselbe Wahrscheinlichkeit bei ebenfalls maskiertem Zielwort.])

#fm([StereoSet: LMS, SS und ICAT], [@nadeem2021stereoset], kap: 8, eq: ("k08-eq-icat",),
  $ "icat" = "lms" dot min("ss", 100 - "ss") / 50 $,
  sym: [lms: Anteil, in dem eine sinnvolle der sinnlosen Assoziation vorgezogen wird (ideal 100); ss: Anteil, in dem die stereotype der anti-stereotypen vorgezogen wird (ideal 50). Ein Zufallsmodell hat lms = ss = icat = 50. Beispiel GPT-2 small: lms 83.6, ss 56.4 -> icat $approx$ 72.9. Die symmetrische Bestrafung ist eine normative Entscheidung.])

#fm([BBQ-Bias-Scores], [@parrish2022bbq], kap: 8, eq: ("k08-eq-sdis", "k08-eq-samb"),
  $ s_"DIS" = 2 (n_"biased" / n_"non-UNKNOWN") - 1, quad quad s_"AMB" = (1 - "accuracy") s_"DIS" $,
  sym: [$n_"biased"$: Ausgaben, die den untersuchten Bias widerspiegeln; $n_"non-UNKNOWN"$: Ausgaben ungleich UNKNOWN; accuracy: Accuracy in ambigen Kontexten. Bereich $[-1, 1]$, 0 = kein gemessener Bias. Bei $s_"AMB"$ wird der Anteil in Implementierungen über die Ausgaben in ambigen Kontexten berechnet; wie die Analyse-Skripte das genau tun, ist ungeprüft. Beispiel: 700 von 1000 UNKNOWN, 210 von 300 biaskonform -> $s_"AMB"$ = 0.30 · 0.40 = 0.12.])

#fm([Metriken auf generiertem Text], [@gallegos2024bias; @dhamala2021bold], kap: 8, eq: ("k08-eq-bold-b", "k08-eq-bold-wavg"),
  $ "EMT"(hat(cal(Y))) = max_(hat(Y) in hat(cal(Y))) c(hat(Y)), quad "Score-Parität" = |EE[c(hat(Y)_i, i) | A = i] - EE[c(hat(Y)_j, j) | A = j]| $,
  $ "Kontrafaktischer Sentiment-Bias" = W_1 (P(c(hat(Y)_i) | A = i), P(c(hat(Y)_j) | A = j)) $,
  $ b_i = (arrow(w)_i dot arrow(g)) / (norm(arrow(w)_i) norm(arrow(g))), quad arrow(g) = arrow("she") - arrow("he"), quad quad "Gender-Wavg" = (sum_i op("sgn")(b_i) b_i^2) / (sum_i |b_i|) $,
  sym: [$hat(cal(Y))$: Menge der Generierungen; $c(dot)$: Klassifikatorscore (Sentiment, Toxizität, Regard); $W_1$: Wasserstein-1-Distanz (@anh-a-divergenz). Gender-Polarität (BOLD): $b_i$ für jedes Wort einer Generierung; ab $<= -0.25$ gilt ein Text als männlich, ab $>= 0.25$ als weiblich. Klassifikatorbasierte Metriken erben Bias und Versionsinstabilität des Klassifikators; die Version immer angeben.])

#fm([Gruppenfairness auf Entscheidungsebene], [@barocas2023fairness; @hardt2016equality], kap: 8, eq: ("k08-eq-eodds", "k08-eq-dp", "k08-eq-deltas", "k08-eq-sr-basis"),
  $ "SR"_a = PP{hat(Y) = 1 | A = a}, quad Delta_"DP" = max_a "SR"_a - min_a "SR"_a, quad "DIR" = (min_a "SR"_a) / (max_a "SR"_a) $,
  $ PP{hat(Y) = 1 | A = 0, Y = y} = PP{hat(Y) = 1 | A = 1, Y = y}, quad y in {0, 1} $,
  $ Delta_"TPR" = max_a "TPR"_a - min_a "TPR"_a, quad Delta_"EOdds" = max(Delta_"TPR", Delta_"FPR") $,
  sym: [$"SR"_a$: Selektionsrate von Gruppe $a$; $Delta_"DP"$: Demographic-Parity-Differenz (Unabhängigkeit); DIR: Disparate-Impact-Verhältnis, die Vier-Fünftel-Regel entspricht $"DIR" >= 0.8$. Equalized Odds verlangt gleiche TPR ($y = 1$) und FPR ($y = 0$), Equal Opportunity nur gleiche TPR. Standardfehler von $Delta_"DP"$ bei zwei Gruppen: $sqrt("SR"_a (1 - "SR"_a) \/ n_a + "SR"_b (1 - "SR"_b) \/ n_b)$; bei je 300 Personen und $Delta_"DP"$ = 0.06 schließt das 95-Prozent-Intervall die Null ein.])

#fm([LLM Word Association Test], [@bai2025explicitly], kap: 8, eq: ("k08-eq-bai",),
  $ "bias" = (N(s_a, X_a)) / (N(s_a, X_a) + N(s_a, X_b)) + (N(s_b, X_b)) / (N(s_b, X_a) + N(s_b, X_b)) - 1 $,
  sym: [$N(s, X)$: Zahl der Wörter aus $X$, die mit dem Wort $s$ gepaart werden; $s_a$, $s_b$: Tokens für Gruppe $a$ bzw. $b$ (z. B. Namen); $X_a$, $X_b$: stereotyp mit $a$ bzw. $b$ assoziierte Attribute. Bereich $[-1, 1]$, 0 = unverzerrt. Beispiel 7 von 8 und 6 von 8: 0.625.])

#fm([Matched Guise Probing], [@hofmann2024ai], kap: 8, eq: ("k08-eq-mgp",),
  $ q(x; v, theta) = 1/n sum_(i = 1)^n log (p(x | v(t_a^i); theta)) / (p(x | v(t_s^i); theta)) $,
  sym: [$t_a^i$: Text in African American English; $t_s^i$: Übersetzung in Standard American English; $v$: Promptvorlage; $x$: Eigenschafts-, Berufs- oder Urteilstoken. Positives $q$ = stärkere Assoziation mit AAE. Ohne Bedeutungsabgleich: Log-Verhältnis der mittleren Wahrscheinlichkeiten. Vorlage für jedes kontrafaktische Proxy-Audit.])

#fm([Diskriminierungsscore für Entscheidungsprompts], [@tamkin2023evaluating], kap: 8, eq: ("k08-eq-discrim",),
  $ y = X beta + Z u + epsilon, quad y = op("logit")[p_"norm"("yes")], quad p_"norm"("yes") = (p("yes")) / (p("yes") + p("no")) $,
  sym: [$X$: feste Effekte (Alter standardisiert, Geschlecht und Herkunft als Dummies); $Z$: Zufallseffekte für Entscheidungsszenario und Interaktionen. Der Diskriminierungsscore einer Gruppe ist ihr fester Effekt relativ zur Basisgruppe; bei Basis-$p("yes")$ = 0.5 entspricht +1.0 etwa 0.73.])

== Retrieval- und RAG-Metriken <anh-a-rag>

#fm([Precision und Recall bei Rang $k$], [@ragas2026contextprecision; @ragas2026contextrecall], kap: 9, eq: ("k09-eq-pk", "k09-eq-rk"),
  $ "P@"k = ("TP@"k) / ("TP@"k + "FP@"k) = 1/k sum_(i=1)^k "rel"_i, quad quad "R@"k = abs({d_1, dots, d_k} inter R_q) / abs(R_q) $,
  sym: [$"rel"_i in {0, 1}$: binäre Relevanz des Dokuments auf Rang $i$; $R_q$: Menge der als relevant beurteilten Dokumente für Anfrage $q$.])

#fm([Reziproker Rang und MRR], [@craswell2016mean; @voorhees1999trec8], kap: 9, eq: ("k09-eq-mrr",),
  $ "RR"(q) = 1 / "rank"_q, quad "MRR" = 1/abs(Q) sum_(q in Q) "RR"(q) $,
  sym: [$"rank"_q$: Rang des ersten relevanten Dokuments; $"RR"(q) = 0$, wenn innerhalb des Cut-offs keines gefunden wird.])

#fm([Average Precision und MAP], [@manning2008introduction], kap: 9, eq: ("k09-eq-ap",),
  $ "AP"(q) = 1/abs(R_q) sum_(i=1)^n "P@"i dot "rel"_i, quad "MAP" = 1/abs(Q) sum_(q in Q) "AP"(q) $,
  sym: [$n$: Listenlänge oder Cut-off. Nie gefundene relevante Dokumente tragen 0 bei, deshalb steht $abs(R_q)$ im Nenner.])

#fm([Context Precision (RAGAS, DeepEval)], [@ragas2026contextprecision], kap: 9, eq: ("k09-eq-cp",),
  $ "CP@"K = (sum_(k=1)^K "P@"k dot v_k) / ("Anzahl relevanter Elemente in den obersten" K) $,
  sym: [$K$: Zahl der abgerufenen Chunks; $v_k in {0, 1}$: von einem LLM beurteilte Relevanz auf Rang $k$. Weil nur die gefundenen relevanten Elemente im Nenner stehen, bestraft die Metrik fehlende Chunks nicht (dafür Context Recall); sie ist nachsichtiger als AP.])

#fm([Discounted Cumulative Gain und nDCG], [@jarvelin2002cumulated; @manning2008introduction], kap: 9, eq: ("k09-eq-dcg-jk", "k09-eq-ndcg"),
  $ "DCG"[i] = cases("CG"[i] & "falls" i < b, "DCG"[i-1] + G[i] slash log_b i & "falls" i >= b,) quad "CG"[i] = "CG"[i-1] + G[i] $,
  $ "DCG@"k = sum_(i=1)^k ("gain"(g_i)) / (log_2(i + 1)), quad "nDCG@"k = ("DCG@"k) / ("IDCG@"k) $,
  sym: [Oben die Originaldefinition mit Gewinn $G[i]$ (Stufen 0 bis 3) und Logarithmusbasis $b$; unten die heute übliche Variante mit $"gain"(g_i) = 2^(g_i) - 1$ (exponentiell) oder $"gain"(g_i) = g_i$ (linear); $"IDCG@"k$: DCG der idealen Ordnung aller beurteilten Dokumente. Varianten immer angeben.])

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    align: (left, right, right, right, right, right, right, right, right),
    table.header([Anfrage], [P\@5], [R\@5], [RR], [AP], [AP\@5], [CP\@5], [nDCG lin.], [nDCG exp.]),
    [q1], [0.600], [0.750], [1.000], [0.667], [0.567], [0.756], [0.683], [0.636],
    [q2], [0.400], [1.000], [0.333], [0.367], [0.367], [0.367], [0.527], [0.520],
    [q3], [0.000], [0.000], [0.000], [0.000], [0.000], [0.000], [0.000], [0.000],
    [Mittel], [0.333], [0.583], [0.444], [0.344], [0.311], [0.374], [0.403], [0.385],
  ),
  caption: [Rechenbeispiel aus Kapitel 9 (drei Anfragen, Cut-off 5). Das Mittel von RR ist die MRR, das von AP die MAP. CP\@5: Context Precision im RAGAS-Stil.],
) <anh-a-tab-ir>

#fm([Claim-basierte Generierungsmetriken (RAGAS, DeepEval)], [@ragas2026faithfulness; @ragas2026contextrecall; @ragas2026factualcorrectness; @ragas2026noisesensitivity], kap: 9, eq: ("k09-eq-faith", "k09-eq-faith-de", "k09-eq-cr", "k09-eq-fc", "k09-eq-ns"),
  $ "Faithfulness" = abs({c in C_"resp" : c "ist aus dem abgerufenen Kontext ableitbar"}) / abs(C_"resp") $,
  $ "ContextRecall" = abs({c in C_"ref" : c "ist durch den abgerufenen Kontext gestützt"}) / abs(C_"ref") $,
  $ P = "TP" / ("TP" + "FP"), quad R = "TP" / ("TP" + "FN"), quad F_1 = (2 P R) / (P + R), quad quad "NoiseSensitivity" = "Anzahl falscher Aussagen in der Antwort" / "Anzahl aller Aussagen in der Antwort" $,
  sym: [$C_"resp"$, $C_"ref"$: von einem LLM extrahierte Claims der Antwort bzw. der Referenzantwort. Factual Correctness: TP = Antwort-Claims in der Referenz, FP = nicht in der Referenz, FN = fehlende Referenz-Claims; Ergebnisse nur bei gleicher Claim-Granularität vergleichbar. DeepEval wertet einen Claim schon dann als treu, wenn er dem Kontext nicht widerspricht, ein schwächeres Kriterium als RAGAS.])

#fm([Answer Relevancy (RAGAS) und Faithfulness im RAGAS-Paper], [@ragas2026answerrelevancy; @es2024ragas], kap: 9, eq: ("k09-eq-ar",),
  $ "AnswerRelevancy" = 1/N sum_(i=1)^N (E_(g_i) dot E_o) / (norm(E_(g_i)) norm(E_o)), quad quad F = abs(V) slash abs(S) $,
  sym: [$E_(g_i)$: Einbettung der $i$-ten aus der Antwort generierten Frage; $E_o$: Einbettung der Nutzereingabe; $N$: Zahl generierter Fragen (Standard 3). Im Paper: $S$ aus der Antwort extrahierte Aussagen, $V$ davon durch den Kontext gestützte. Viele heute unter dem Namen RAGAS geführte Metriken wurden im Paper nicht validiert.])

#fm([RAGChecker (Auswahl)], [@ru2024ragchecker], kap: 9, eq: ("k09-eq-rc-overall", "k09-eq-rc-ret", "k09-eq-rc-gen1", "k09-eq-rc-gen2", "k09-eq-rc-sk", "k09-eq-rc-cu"),
  $ "Claim Recall" = abs({c_i^(("gt")) in {"chunk"_j}}) / abs({c_i^(("gt"))}), quad "Context Precision" = abs({"r-chunk"_j}) / k $,
  $ "Hallucination" = abs({c_i^((m)) in.not "gt", c_i^((m)) in.not {"chunk"_j}}) / abs({c_i^((m))}), quad "Self-knowledge" = abs({c_i^((m)) in "gt", c_i^((m)) in.not {"chunk"_j}}) / abs({c_i^((m))}) $,
  $ "Context Utilization" = abs({c_i^(("gt")) in {"chunk"_j}, c_i^(("gt")) in m}) / abs({c_i^(("gt")) in {"chunk"_j}}) $,
  sym: [$c_i^((m))$: Claims der Modellantwort $m$; $c_i^(("gt"))$: Claims der Referenzantwort $"gt"$; $k$ abgerufene Chunks; "$in$" heißt "wird impliziert von"; ein r-chunk impliziert mindestens einen Referenz-Claim. Precision, Recall, Faithfulness und Noise Sensitivity analog. Context Precision ist hier mengenbasiert, nicht rangbasiert.])

#fm([Zitationsmetriken (ALCE)], [@gao2023enabling], kap: 9,
  $ "Zitations-Recall"(s_i) = bb(1)[C_i != emptyset and phi("concat"(C_i), s_i) = 1] $,
  $ c "irrelevant" <=> phi(c, s_i) = 0 and phi("concat"(C_i without {c}), s_i) = 1 $,
  sym: [$s_i$: Aussage der Antwort; $C_i$: ihre Zitationen; $phi$: Entailment-Urteil eines NLI-Modells. Die Zitations-Precision einer Zitation $c in C_i$ ist 1 genau dann, wenn $s_i$ Zitations-Recall 1 hat und $c$ nicht irrelevant ist. Recall wird über Aussagen, Precision über Zitationen gemittelt.])

#fm([Nugget-Scores und CRAG-Truthfulness], [@pradeep2025great; @yang2024crag], kap: 9, eq: ("k09-eq-nugget",),
  $ A_"strict" = 1/abs(N) sum_(i in N) p_i, quad V_"strict" = 1/abs(N_"vital") sum_(i in N_"vital") p_i, quad quad "Truthfulness" = 1 / abs(D) sum_(i in D) "score"_i $,
  sym: [$N$, $N_"vital"$: alle bzw. die vitalen Nuggets eines Topics; $p_i = 1$ nur bei Label "support". CRAG: perfekt = 1, akzeptabel = 0.5, fehlend = 0, falsch = $-1$; Enthaltung wird gegenüber falschen Antworten bevorzugt.])

#fm([Unsicherheit für Richterscores (PPI)], [@angelopoulos2023prediction; @saadfalcon2024ares], kap: 9, eq: ("k09-eq-ppi", "k09-eq-ppi-ci"),
  $ hat(theta)_"PP" = 1/N sum_(i=1)^N f(tilde(X)_i) - 1/n sum_(i=1)^n (f(X_i) - Y_i), quad quad C_"PP" = hat(theta)_"PP" plus.minus z_(1 - alpha slash 2) sqrt(hat(sigma)^2_(f - Y) / n + hat(sigma)^2_f / N) $,
  sym: [Wie in @anh-a-inferenz, mit $f(dot)$ als Richterscore (z. B. 1 = treu) und $Y_i$ als menschlichem Label. ARES wendet das auf RAG an und kann unterhalb von etwa 100 bis 150 menschlichen Labels Systeme nicht zuverlässig unterscheiden.])

#fm([Gepaarter Vergleich zweier Konfigurationen], [Standardverfahren], kap: 9, eq: ("k09-eq-paired", "k09-eq-ar-test", "k09-eq-power"),
  $ "Var"(overline(d)) = (sigma_A^2 + sigma_B^2 - 2 rho sigma_A sigma_B) / n, quad quad p = (1 + sum_(r=1)^R bb(1)[abs(T^((r))) >= abs(overline(d))]) / (R + 1), quad quad n approx ((z_(1 - alpha slash 2) + z_(1 - beta)) sigma_d / delta)^2 $,
  sym: [$overline(d)$: mittlere Differenz der Scores zweier Konfigurationen $A$, $B$ auf denselben $n$ Anfragen; $rho$: Korrelation der Scores über Anfragen (positive Korrelation macht den gepaarten Vergleich schärfer); $T^((r))$: Statistik nach der $r$-ten von $R$ zufälligen Vorzeichenvertauschungen (Approximate Randomization); $sigma_d$: Standardabweichung der Differenzen; $delta$: kleinste relevante Differenz.])

== Reproduzierbarkeit und Kosten von Workflows <anh-a-workflow>

#fm([Total Agreement Rate], [@atil2025nondeterminism], kap: 10, eq: ("k10-eq-tar", "k10-eq-tar-modell"),
  $ "TAR@N" = 100 / Q sum_(q=1)^Q bb(1) [o_(q,1) = o_(q,2) = dots = o_(q,N)], quad quad P_N = sum_(k=1)^K pi_k^N $,
  sym: [$Q$: Zahl der Items; $N$: Wiederholungen mit identischer Eingabe und Einstellung; $o_(q,r)$: Ausgabe für Item $q$ in Lauf $r$. TARr vergleicht Rohstrings, TARa geparste Antworten. Beispiel $Q = 4$, $N = 3$: TARr\@3 = 50 %, TARa\@3 = 75 %. Rechts: Wahrscheinlichkeit totaler Übereinstimmung für ein Item, dessen Läufe unabhängig mit Wahrscheinlichkeiten $pi_1, dots, pi_K$ eine von $K$ Ausgaben liefern.])

#fm([Anteil eindeutiger Ausgaben und paarweise Jaccard-Ähnlichkeit], [@nicholson2026quantifying], kap: 10, eq: ("k10-eq-unique",),
  $ U_p = (|{o_(p,1), dots, o_(p,R)}|) / R, quad J_p = binom(R, 2)^(-1) sum_(r < s) (|W(o_(p,r)) inter W(o_(p,s))|) / (|W(o_(p,r)) union W(o_(p,s))|) $,
  sym: [$R$: Läufe pro Prompt $p$; $W(dot)$: Wortmenge einer Ausgabe (Tokenisierung selbst festlegen und berichten); $U_p = 1 \/ R$ heißt vollständig wiederholbar.])

#fm([Temperatur und Hintergrundtemperatur], [@messina2026introducing], kap: 10, eq: ("k10-eq-softmax", "k10-eq-tbg", "k10-eq-tbg-schaetzer"),
  $ p_i (T) = exp(z_i \/ T) / (sum_(j=1)^V exp(z_j \/ T)), quad quad T_"bg" = EE_I [T_n (I)] $,
  $ hat(T)^((m)) = arg min_(T in cal(G)) D(F_"target", F_"ref"^((m)) (T)), quad overline(T)_"bg" = 1 / (|cal(M)|) sum_(m in cal(M)) hat(T)^((m)) $,
  sym: [$z_i$: Logit von Token $i$ im Vokabular der Größe $V$; $T_n (I)$: Temperatur, die die implementierungsbedingte Variabilität bei nominal $T = 0$ in Inferenzumgebung $I$ nachbildet; $F$: Verteilung einer Variabilitätsmetrik über Prompts; $D$: Divergenz (im Pilot Kolmogorov-Smirnov); $cal(G)$: Temperaturgitter; $cal(M)$: Referenzmodelle. Mindestens 50 Wiederholungen pro Prompt.])

#fm([Kostenmodell für einen Annotations- oder Evaluationslauf], [@anthropic2026pricing; @anthropic2026batch], kap: 10, eq: ("k10-eq-kosten", "k10-eq-breakeven"),
  $ C = (d dot r) / 10^6 [N (x p_"in" + y p_"out") + N P (h p_"hit" + (1 - h) p_"write")], quad quad h > h^* = (p_"write" - p_"in") / (p_"write" - p_"hit") $,
  sym: [$N$: Anfragen; $P$: Tokens des gemeinsamen, cachebaren Präfixes; $x$, $y$: itemspezifische Ein- bzw. Ausgabetokens; $p_"hit"$, $p_"write"$: Preise für Cache-Lesen und -Schreiben; $h$: Trefferrate (in Batches nach Anbieterangabe typischerweise 30 bis 98 Prozent, ohne Garantie); $d$: Batchfaktor (0.5 oder 1); $r$: Aufschlag für regionale Verarbeitung. Ohne Caching $P$ in $x$ aufnehmen und den zweiten Term streichen; Caching lohnt sich nur oberhalb von $h^*$.])

#figure(
  table(
    columns: (1fr, auto),
    align: (left, right),
    table.header([Szenario], [Kosten (USD)]),
    [Standard, ohne Caching], [108.00],
    [Batch, ohne Caching ($d$ = 0.5)], [54.00],
    [Batch + 5-Minuten-Cache, $h$ = 0.9], [20.80],
    [Batch + 1-Stunden-Cache, $h$ = 0.9], [23.80],
    [Batch + 5-Minuten-Cache, $h$ = 0.3], [49.60],
    [Batch + 1-Stunden-Cache, $h$ = 0.3], [70.60],
  ),
  caption: [Rechenbeispiel zum Kostenmodell: 20 000 Texte, Präfix 2000 Tokens, $x$ = 400, $y$ = 60, $p_"in"$ = 2 und $p_"out"$ = 10 USD pro Million Tokens (Stand: 11. November 2026) @anthropic2026pricing. Caching lohnt sich nur bei hoher Trefferrate.],
) <anh-a-tab-kosten>

== Divergenzen und Verteilungsvergleiche <anh-a-divergenz>

#fm([Entropie und Kullback-Leibler-Divergenz], [@lin1991divergence], kap: 4, eq: ("k04-eq-kl",),
  $ H(P) = - sum_k p_k log_2 p_k, quad "KL"(P || Q) = sum_k p_k log_2 p_k / q_k, quad quad H_"norm" = H(P) slash log_2 K $,
  sym: [$p_k$, $q_k$: Wahrscheinlichkeiten der Kategorie $k$ von $K$. Die KL-Divergenz ist nicht symmetrisch und unendlich, sobald $q_k = 0$ bei $p_k > 0$; deshalb für den Vergleich von Antwortverteilungen meist ungeeignet. Die normierte Entropie $H_"norm" in [0, 1]$ ist 1 bei Gleichverteilung und 0 bei Punktmasse und misst Flattening; im Beispiel unten 0.92 (Mensch) gegen 0.28 (Modell).])

#fm([Jensen-Shannon-Divergenz], [@lin1991divergence], kap: 4, eq: ("k04-eq-jsd",),
  $ "JSD"(P || Q) = 1/2 "KL"(P || M) + 1/2 "KL"(Q || M), quad M = 1/2 (P + Q) $,
  sym: [Symmetrisch und beschränkt; mit Logarithmus zur Basis 2 liegt sie in $[0, 1]$. Beispiel Mensch $(0.10, 0.20, 0.40, 0.30)$ gegen kollabiertes Modell $(0, 0.05, 0.90, 0.05)$: JSD $approx$ 0.227 Bit, obwohl $"KL"$(Mensch $||$ Modell) unendlich ist. Hinweis: `scipy.spatial.distance.jensenshannon` liefert die Wurzel daraus (die JS-Distanz).])

#fm([Wasserstein-1-Distanz für ordinale Antworten], [@santurkar2023whose], kap: [4, 8], eq: ("k04-eq-wd-def", "k04-eq-wd-cdf"),
  $ "WD"(P, Q) = min_gamma sum_(j, k) gamma(j, k) dot |j - k|, quad quad "WD"(P, Q) = sum_(k=1)^(N-1) |F_P (k) - F_Q (k)| $,
  sym: [$gamma$: Transportplan mit den Randverteilungen $P$ und $Q$; $F_P$, $F_Q$: kumulative Verteilungsfunktionen auf gleichabständigen Optionen $1, dots, N$. Im Beispiel oben: $F$ Mensch $= (0.10, 0.30, 0.70)$, $F$ Modell $= (0, 0.05, 0.95)$, $"WD"$ = 0.60, OpinionQA-Alignment $1 - 0.60 \/ 3$ = 0.80. Für stetige Scoreverteilungen (kontrafaktischer Sentiment-Bias) ist $W_1$ die Fläche zwischen den Verteilungsfunktionen.])

#fm([Kolmogorov-Smirnov-Distanz], [Standarddefinition, verwendet in @messina2026introducing], kap: 10,
  $ D_"KS" = sup_x |F_1 (x) - F_2 (x)| $,
  sym: [Größter vertikaler Abstand zweier Verteilungsfunktionen $F_1$, $F_2$; bei der Schätzung der Hintergrundtemperatur als Divergenz $D$ verwendet.])

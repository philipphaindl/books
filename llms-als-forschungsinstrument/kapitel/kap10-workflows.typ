#import "../lib.typ": *

// Balkendiagramm mit Dezimalkomma (lokale Variante von `balken`)
#let balken-de(werte, max: none, breite: 9, hoehe: 0.42, farbe: c-blue, einheit: "", nachkomma: 2) = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let m = if max == none { calc.max(..werte.map(w => w.at(1))) } else { max }
  for (i, (lab, v)) in werte.enumerate() {
    let y = -i * (hoehe + 0.22)
    content((-0.15, y), anchor: "east", text(font: "Inter", size: 7.5pt, lab))
    rect((0, y - hoehe / 2), (breite * v / m, y + hoehe / 2), fill: farbe.lighten(15%), stroke: none)
    let s = str(calc.round(v, digits: nachkomma))
    if nachkomma > 0 and not s.contains(".") { s = s + "." + "0" * nachkomma }
    content((breite * v / m + 0.12, y), anchor: "west", text(font: "Inter", size: 7pt, fill: c-dark, s + einheit))
  }
})
#let dez(x) = str(x)

= Reproduzierbare Forschungs-Workflows mit LLMs <k10>

Die vorangegangenen Kapitel haben das Sprachmodell als Messinstrument behandelt: als Annotator, als Richter, als Generator, dessen Ausgaben man validieren, korrigieren und auf Verzerrungen prüfen muss. Dieses Kapitel setzt die Teile zusammen. Es fragt, wie ein empirisches Forschungsvorhaben, das LLMs einsetzt, von der ersten Hypothese bis zum eingereichten Artikel so organisiert wird, dass eine dritte Person jede Zahl im Bericht nachvollziehen kann, auch dann, wenn das verwendete Modell längst abgeschaltet ist.

Das klingt nach Ingenieursdisziplin und ist es auch. Es ist aber vor allem eine methodische Frage. Das Lehrbuch formuliert die Schwierigkeit in einem Satz: Bei KI-basierten Systemen hat man es mit einem Untersuchungsgegenstand zu tun, der "nicht stillhält" @haindl2027research. Ein gehostetes Modell kann sich hinter einem gleichbleibenden Namen verändern, es liefert bei identischer Eingabe unterschiedliche Ausgaben, und es verschwindet nach einem Lebenszyklus, der kürzer sein kann als ein Begutachtungsverfahren. Gleichzeitig entfernen Anbieter Stellschrauben, auf die sich Forschende bisher verlassen haben: Seit der Anthropic-API-Version `2026-10-21` führt das Senden von `temperature` zu einem Fehler @anthropic2026versions. Wer 2023 gelernt hat, man setze für Annotationen einfach die Temperatur auf null, muss umlernen.

Das Kapitel ist deshalb in drei Bögen gebaut. Der erste Bogen (@k10-sec-nichtdeterminismus bis @k10-sec-stabilitaet) klärt, woher Variation in LLM-Ausgaben kommt, wie Modelle versioniert und abgekündigt werden und wie man Stabilität misst. Der zweite Bogen (@k10-sec-pipeline und @k10-sec-werkzeuge) baut eine vollständige Referenz-Pipeline Stufe für Stufe auf, mit Code-Gerüst, Provenienz-Protokoll, Werkzeugen und einem Kostenmodell. Der dritte Bogen (@k10-sec-reviews bis @k10-sec-ethik) wendet das auf Literaturreviews an und behandelt Reporting-Leitlinien, Verlagsrichtlinien, EU AI Act und Datenschutz. Zeitkritische Angaben (Preise, Versionen, Fristen, Rechtsstand) beziehen sich durchgehend auf den Stand vom 11. November 2026.

#lernziele[
  die drei Quellen von Variation in LLM-Pipelines unterscheiden (gewollte Stichprobenziehung, numerischer Nichtdeterminismus durch fehlende Batch-Invarianz, stille Drift des Dienstes) und für jede eine empirische Studie nennen,
][
  erklären, warum Temperatur 0 auf gehosteten Endpunkten keine Reproduzierbarkeit garantiert und warum es diese Stellschraube bei vielen Modellen gar nicht mehr gibt,
][
  Stabilität mit TARr\@N, TARa\@N, Unique-Output-Anteil und Best-/Worst-Case-Genauigkeit messen und zeigen, warum TAR\@N mit wachsendem $N$ fällt,
][
  eine Referenz-Pipeline von der Präregistrierung bis zum Reporting entwerfen, inklusive Modellwahl, Prompt- und Codebuch-Versionierung, Manifest und Validierung,
][
  die Kosten eines Annotationslaufs unter Standard-, Batch- und Cache-Preisen berechnen und den Break-even des Prompt-Cachings herleiten,
][
  die Evidenz zu LLM-gestütztem Screening, Datenextraktion und Zitationshalluzinationen kritisch einordnen,
][
  die passende Reporting-Leitlinie (llm-guidelines.org, TRIPOD-LLM, GUIDE-LLM, REFORMS, CHART) und die Offenlegungsregeln des Zielverlags anwenden und die rechtlichen Rahmenbedingungen (EU AI Act Art. 4, DSGVO-Leitlinien des EDPB) für eine Forschungsgruppe einordnen.
]

== Das Instrument hält nicht still <k10-sec-instrument>

=== Reproduzierbar, replizierbar, generalisierbar

Bevor es um LLMs geht, lohnt sich die begriffliche Ordnung, die das Lehrbuch in seinem Kapitel über die Erforschung KI-basierter Systeme vorschlägt. Die drei Begriffe werden in der Literatur uneinheitlich verwendet, und gerade bei LLM-Studien entstehen Missverständnisse, weil jemand "reproduzierbar" sagt und "replizierbar" meint @haindl2027research.

#definition(titel: [Reproduzierbarkeit, Replizierbarkeit, Generalisierbarkeit])[
  Ein Ergebnis ist *reproduzierbar* (_reproducible_), wenn eine unabhängige Partei mit denselben Daten und demselben Code dasselbe Ergebnis erhält @Peng2011. Es ist *replizierbar* (_replicable_), wenn eine neue Studie mit neuen Daten, aber derselben Methode zu konsistenten Schlüssen kommt. Es ist *generalisierbar* (_generalisable_), wenn der Befund über Kontexte, Populationen und Settings hinweg trägt, die über die ursprüngliche Studie hinausgehen @haindl2027research.
]

Die drei Begriffe bilden ein Spektrum zunehmender Stärke (@k10-fig-spektrum). Ein Ergebnis kann perfekt reproduzierbar sein, weil der Code läuft und die publizierten Zahlen liefert, und trotzdem nicht replizieren, weil der Befund ein Zufallsprodukt eines einzelnen Datensatzes war. Das Lehrbuch hält fest, dass KI-basierte Systeme bereits die schwächste der drei Eigenschaften, die bloße Reproduzierbarkeit, "überraschend schwer" machen @haindl2027research. Genau das ist das Thema der ersten Hälfte dieses Kapitels.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [*reproduzierbar* \ gleiche Daten, \ gleicher Code], w: 3.6, h: 1.3, col: c-blue, bg: c-blue.lighten(90%))
    kasten((4.6, 0), [*replizierbar* \ neue Daten, \ gleiche Methode], w: 3.6, h: 1.3, col: c-teal, bg: c-teal.lighten(90%))
    kasten((9.2, 0), [*generalisierbar* \ neue Kontexte \ und Populationen], w: 3.6, h: 1.3, col: c-violet, bg: c-violet.lighten(90%))
    pfeil((1.85, 0), (2.75, 0))
    pfeil((6.45, 0), (7.35, 0))
    line((-1.8, -1.2), (11.0, -1.2), stroke: (paint: c-grey, thickness: 1.2pt), mark: (end: "stealth", fill: c-grey, scale: 0.8))
    content((4.6, -1.55), text(font: "Inter", size: 7.5pt, fill: c-grey.darken(20%))[zunehmende Stärke der Aussage])
    content((0, 1.05), text(font: "Inter", size: 7pt, fill: c-accent, weight: "bold")[bei LLMs schon schwer])
  }),
  caption: [Spektrum zunehmend starker Aussagen nach dem Lehrbuch @haindl2027research. Bei gehosteten LLMs ist bereits die linke Stufe nicht selbstverständlich.],
) <k10-fig-spektrum>

Für die Praxis des Lehrbuchs gibt es einen einfachen Test: Könnte eine fremde Person, oder du selbst in fünf Jahren, nachdem du alles vergessen hast, das Repository klonen und die Ergebnisse von Grund auf neu erzeugen? Wenn nicht, ist die Arbeit noch nicht reproduzierbar, unabhängig davon, wie solide die Wissenschaft dahinter ist @haindl2027research. Die etablierten Praktiken, die diese Lücke schließen, sind Versionskontrolle für allen Code, explizit deklarierte Abhängigkeiten mit Versionen, fixierte Zufallsstartwerte und Container für die gesamte Rechenumgebung @Wilson2017. Für LLM-Studien reicht das nicht mehr, weil der wichtigste Teil des Experiments, das Modell selbst, nicht unter der Kontrolle der Forschenden steht.

=== Drei Quellen von Variation

Wenn du dieselbe Anfrage zweimal an ein LLM schickst und zwei verschiedene Antworten erhältst, kann das drei sehr verschiedene Ursachen haben. Die Unterscheidung ist die wichtigste begriffliche Leistung dieses Kapitels, denn jede Ursache verlangt eine andere Gegenmaßnahme.

#definition(titel: [Quellen von Ausgabevariation])[
  1. *Gewollte Stichprobenziehung* (_sampling_): Das Modell zieht das nächste Token aus einer Wahrscheinlichkeitsverteilung, deren Schärfe die Temperatur steuert. Diese Variation ist beabsichtigt.
  2. *Numerischer Nichtdeterminismus*: Auch bei gierigem Decoding (Temperatur 0) unterscheiden sich Ausgaben, weil Gleitkommaberechnungen auf dem Server je nach Last in unterschiedlicher Reihenfolge ablaufen. Die Hauptursache ist fehlende *Batch-Invarianz* der Rechenkerne @he2025defeating.
  3. *Drift des Dienstes* (_model drift_, _service drift_): Das Verhalten eines benannten Dienstes ändert sich über die Zeit, ohne dass sich der vom Client verwendete Modellname ändert @chen2024chatgpts.
]

#figure(
  diagram(spacing: (9mm, 7mm),
    fknoten((0, 0), [Gewollter Zufall \ Temperatur, top-p], col: c-blue, w: 32mm),
    fknoten((0, 1), [Numerik: fehlende \ Batch-Invarianz], col: c-accent, w: 32mm),
    fknoten((0, 2), [Drift: Update \ hinter dem Namen], col: c-violet, w: 32mm),
    fknoten((2, 1), [Variation der \ Ausgabe], col: c-dark, filled: true, w: 26mm),
    edge((0, 0), (2, 1), "-|>"),
    edge((0, 1), (2, 1), "-|>"),
    edge((0, 2), (2, 1), "-|>"),
    fknoten((4, 0), [wiederholen, \ Verteilung berichten], col: c-blue, w: 32mm),
    fknoten((4, 1), [batch-invariante \ lokale Inferenz], col: c-accent, w: 32mm),
    fknoten((4, 2), [Snapshot pinnen, \ Probe-Set], col: c-violet, w: 32mm),
    edge((0, 0), (4, 0), "-", stroke: (paint: c-grey, dash: "dashed"), bend: 18deg, label: text(font: "Inter", size: 6.8pt)[Gegenmaßnahme]),
    edge((0, 1), (4, 1), "-", stroke: (paint: c-grey, dash: "dashed"), bend: -28deg),
    edge((0, 2), (4, 2), "-", stroke: (paint: c-grey, dash: "dashed"), bend: -18deg),
  ),
  caption: [Drei Quellen von Variation in LLM-Ausgaben und die jeweils passende Gegenmaßnahme. Die gestrichelten Bögen ordnen jeder Ursache ihre Gegenmaßnahme zu.],
) <k10-fig-quellen>

Die drei Quellen sind empirisch belegt. Für die zweite Quelle zeigten Atil et al., dass fünf gehostete Modelle bei Temperatur 0, top-p 1 und festem Seed über zehn identische Läufe Genauigkeitsschwankungen von bis zu 15 Prozentpunkten und eine Spanne von bis zu 70 Prozentpunkten zwischen bester und schlechtester möglicher Genauigkeit aufwiesen @atil2025nondeterminism[Abstract]. Für die dritte Quelle dokumentierten Chen, Zaharia und Zou, dass die Genauigkeit von GPT-4 beim Erkennen von Primzahlen zwischen März und Juni 2023 von 84.0 % auf 51.1 % fiel @chen2024chatgpts[Sec. 3.1]. Und dass die Forschung diese Probleme ernst nimmt, ist keineswegs selbstverständlich: Von 76 untersuchten Arbeiten zur Codegenerierung mit LLMs berücksichtigten nur 16 (21.1 %) den Nichtdeterminismus in ihren Experimenten @ouyang2025empirical.

#merke[
  Ein Forschungs-Workflow mit LLMs muss das Modell als *versioniertes, möglicherweise verschwindendes, stochastisches Instrument* behandeln und genug Provenienz aufzeichnen, damit Ergebnisse prüfbar bleiben, auch wenn sie sich nicht mehr neu erzeugen lassen.
]

Der letzte Halbsatz verdient Betonung. Reproduzierbarkeit im strengen Sinn (gleiche Daten, gleicher Code, gleiches Ergebnis) setzt voraus, dass der Code noch läuft. Wenn der Code einen API-Aufruf an ein abgeschaltetes Modell enthält, läuft er nicht mehr. Was dann bleibt, ist *Re-Analysierbarkeit*: Aus den archivierten Rohausgaben lässt sich jede Zahl des Berichts erneut berechnen. Das Notebook zum Foliensatz 10 macht genau diese Unterscheidung zum Kernpunkt: Ein zweiter Lauf aus dem Antwort-Cache liefert bitgleiche Ergebnisse, aber das heißt nicht, dass das Modell dieselben Antworten noch einmal geben würde (`notebooks/10_reproducible_pipeline.ipynb`, Abschnitt 3).

== Nichtdeterminismus verstehen <k10-sec-nichtdeterminismus>

=== Gewollter Zufall: Temperatur und Sampling

Ein Sprachmodell berechnet an jeder Position einen Vektor von Logits $z_1, dots, z_V$ über das Vokabular der Größe $V$. Die Wahrscheinlichkeit des Tokens $i$ bei Temperatur $T > 0$ ist

$ p_i (T) = exp(z_i \/ T) / (sum_(j=1)^V exp(z_j \/ T)) . $ <k10-eq-softmax>

Für $T = 1$ ist das die gewöhnliche Softmax. Für $T -> 0$ konzentriert sich die gesamte Masse auf das Token mit dem größten Logit, sofern es eindeutig ist. Das sieht man, indem man Zähler und Nenner durch $exp(z_max \/ T)$ teilt: Jeder Term mit $z_j < z_max$ wird zu $exp((z_j - z_max) \/ T)$ und geht gegen null, weil der Exponent gegen $-infinity$ läuft. Übrig bleibt $p_(arg max) -> 1$. Deshalb nennt man Decoding mit Temperatur 0 auch *gieriges Decoding* (_greedy decoding_): Es wählt an jeder Stelle das Arg-Max-Token. Mathematisch ist das eine deterministische Funktion der Eingabe. Dass es in der Praxis trotzdem nicht deterministisch ist, liegt an der zweiten Quelle.

Song et al. haben gieriges Decoding und Sampling über viele Benchmarks verglichen und berichten, dass gieriges Decoding auf den meisten Aufgaben besser abschneidet, dass Alignment die Varianz des Samplings reduzieren kann und dass Best-of-N-Sampling kleineren Modellen erlaubt, GPT-4-Turbo zu erreichen oder zu übertreffen @song2025good[Abstract]. Daraus folgt ein methodischer Rat, der über Benchmarks hinausgeht: Berichte gieriges und gesampeltes Verhalten getrennt, und berichte bei Sampling die Varianz.

Das Lehrbuch ergänzt eine Warnung, die oft übersehen wird. Eine Temperatur nahe null als Ausweg zu wählen, "tauscht eine Verzerrung gegen eine andere": Man berichtet das Systemverhalten an einem Extrempunkt seines Betriebsbereichs und unterdrückt womöglich genau die Variabilität, die eine Studie zur Zuverlässigkeit erfassen sollte @haindl2027research. Wenn deine Forschungsfrage lautet, wie zuverlässig ein LLM-gestütztes Werkzeug in der Praxis ist, und Nutzerinnen es mit Standardeinstellungen verwenden, dann misst Temperatur 0 das falsche Konstrukt.

=== Temperatur 0 ist nicht deterministisch

#studie(titel: [Atil et al. 2025])[
  *Design:* Fünf gehostete Modelle (GPT-3.5 Turbo, GPT-4o, Llama-3-70B-Instruct, Llama-3-8B-Instruct, Mixtral-8x7B-Instruct), acht Aufgaben (vier aus BIG-Bench Hard, vier aus MMLU), Temperatur 0, top-p 1, fester Seed, je zehn Läufe, Zero-Shot und Few-Shot @atil2025nondeterminism.
  *Befund:* Die Genauigkeit schwankte über Läufe um bis zu 15 Prozentpunkte; beste und schlechteste mögliche Genauigkeit lagen bis zu 70 Prozentpunkte auseinander (72 für Mixtral auf College Mathematics). Kein Modell war über alle Aufgaben wiederholbar, identische Rohstrings waren selten, TARa\@10 lag über TARr\@10. Die Verteilungen der Genauigkeit über Läufe waren nicht normal (Kolmogorov-Smirnov $p < 10^(-9)$ für GPT-4o und Llama-3-70B auf College Mathematics). Längere Ausgaben gingen mit geringerer Stabilität einher. Ein lokal ohne Serving-Optimierungen betriebenes Llama-3-8B lieferte deterministische Ergebnisse @atil2025nondeterminism.
  *Grenzen:* Ursachen nur vermutet (Batching, Prefix-Caching), kein Zugriff auf die Infrastruktur der Anbieter; die getesteten Modelle sind großteils abgekündigt, die Zahlen also historisch @atil2025nondeterminism.
]

#studie(titel: [Ouyang et al. 2025])[
  *Design:* 829 Programmieraufgaben aus CodeContests, APPS und HumanEval, je fünf Generierungen mit ChatGPT, Standardtemperatur 1 und zusätzlich Temperatur 0; außerdem eine Durchsicht von 76 Arbeiten zur LLM-Codegenerierung @ouyang2025empirical.
  *Befund:* Bei Temperatur 1 hatten 75.76 % (CodeContests), 51.00 % (APPS) und 47.56 % (HumanEval) der Aufgaben über die fünf Anfragen keine einzige übereinstimmende Testausgabe @ouyang2025empirical[Abstract]. Bei Temperatur 0 waren es immer noch 43.64 %, 27.40 % und 18.29 %. Die maximale Differenz der Testbestehensrate erreichte 1.00 auf allen drei Datensätzen. Nur 16 von 76 Arbeiten (21.1 %) berücksichtigten Nichtdeterminismus @ouyang2025empirical.
  *Grenzen:* Eine Modellfamilie aus der GPT-3.5-Ära, nur fünf Wiederholungen pro Aufgabe.
]

Die beiden Studien zusammen zeigen zweierlei. Erstens verändert Nichtdeterminismus nicht nur Oberflächenformulierungen, sondern *Schlussfolgerungen*: Eine Bestehensrate, die zwischen 0 und 1 schwanken kann, macht einen Modellvergleich auf Basis eines einzelnen Laufs wertlos. Zweitens wird das Problem systematisch unterberichtet. Das ist der empirische Hintergrund für die Forderung der Leitlinie llm-guidelines.org: "Researchers should not treat a temperature of 0 as a guarantee of reproducibility" @baltes2025guidelines[Sec. 5.2.5].

Auch Seeds lösen das Problem nicht. OpenAI führte den Parameter `seed` im November 2023 als Beta-Funktion ein und stellt klar: "Determinism is not guaranteed" @openai2023reproducible. Die Azure-Dokumentation spricht von "best effort", hält fest, dass auch identische Seeds und identischer `system_fingerprint` variierende Antworten liefern können und dass größere Werte für `max_tokens` die Antworten weniger deterministisch machen; die Funktion ist weiterhin als Vorschau gekennzeichnet @microsoft2026reproducible. Der `system_fingerprint` ist trotzdem nützlich: Er identifiziert die Backend-Konfiguration und erlaubt es, Änderungen auf Anbieterseite zu erkennen. Er gehört deshalb ins Protokoll jedes Aufrufs, wo der Anbieter ihn liefert.

=== Warum Server nicht deterministisch rechnen: Batch-Invarianz

Die verbreitete Erklärung lautet: GPUs rechnen parallel, die Reihenfolge paralleler Additionen ist zufällig, Gleitkommaaddition ist nicht assoziativ, also schwanken die Ergebnisse. Diese Erklärung ist nach He und dem Thinking Machines Lab unvollständig. Ein einzelner Vorwärtsdurchlauf eines LLM ist in der Regel von Lauf zu Lauf deterministisch, weil die dafür nötigen Kernel selten atomare Additionen brauchen @he2025defeating. Die eigentliche Ursache liegt eine Ebene höher.

Zuerst zur mathematischen Grundlage, die du im Hörsaal an der Tafel zeigen kannst. Gleitkommaarithmetik rundet nach jeder Operation auf eine feste Anzahl signifikanter Stellen. Deshalb gilt das Assoziativgesetz nicht.

#beispiel(titel: [Nichtassoziativität bei drei signifikanten Stellen])[
  Stell dir eine Dezimalarithmetik vor, die nach jeder Operation auf drei signifikante Stellen rundet. Sei $a = 1000$, $b = 4$, $c = 4$.
  - $(a + b) + c$: Zuerst $1000 + 4 = 1004$, gerundet auf drei Stellen $1000$. Dann $1000 + 4 = 1004 -> 1000$. Ergebnis $1000$.
  - $a + (b + c)$: Zuerst $4 + 4 = 8$. Dann $1000 + 8 = 1008 -> 1010$. Ergebnis $1010$.
  Die Reihenfolge der Summation ändert das Ergebnis um 1 %. In echter bfloat16-Arithmetik mit nur acht Bit Mantissengenauigkeit (sieben gespeicherte Bits plus implizites führendes Bit) tritt derselbe Effekt auf, nur an anderer Stelle. Ein Rechenkern, der eine Summe über viele Elemente je nach Problemgröße in unterschiedlich große Blöcke aufteilt, summiert in unterschiedlicher Reihenfolge und erhält daher geringfügig unterschiedliche Ergebnisse.
]

Hier setzt das Argument von He et al. an. Ein Inferenzserver bündelt gleichzeitig eintreffende Anfragen verschiedener Nutzer zu einem *Batch*. Viele Rechenkerne (RMSNorm, Matrixmultiplikation, Attention) wählen ihre interne Aufteilung und damit die Summationsreihenfolge abhängig von der Batch-Größe. Die Batch-Größe hängt von der Serverlast ab, und die siehst du als Nutzerin nicht.

#definition(titel: [Batch-Invarianz])[
  Ein Rechenkern ist *batch-invariant*, wenn das numerische Ergebnis für eine Sequenz nicht davon abhängt, wie viele andere Sequenzen im selben Batch verarbeitet werden @he2025defeating.
]

Fehlende Batch-Invarianz ist nach He et al. "the primary reason nearly all LLM inference endpoints are nondeterministic" @he2025defeating. Der Mechanismus ist eine Kette (@k10-fig-batch): Die Serverlast bestimmt die Batch-Größe, die Batch-Größe bestimmt die Summationsreihenfolge, die Summationsreihenfolge verschiebt einen Logit in der letzten Nachkommastelle, und wenn zwei Tokens fast gleich wahrscheinlich sind, kippt das Arg-Max. Ab diesem Token ist der Kontext ein anderer, und die Fortsetzungen laufen auseinander.

#figure(
  diagram(spacing: (4mm, 6mm),
    fknoten((0, 0), [Serverlast \ (unsichtbar)], col: c-grey, w: 22mm),
    fknoten((1, 0), [Batch-Größe], col: c-grey, w: 24mm),
    fknoten((2, 0), [Summations- \ reihenfolge], col: c-accent, w: 22mm),
    fknoten((3, 0), [Logit ändert \ sich minimal], col: c-accent, w: 26mm),
    fknoten((4, 0), [Arg-Max kippt \ bei Gleichstand], col: c-red, filled: true, w: 28mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"), edge((3, 0), (4, 0), "-|>"),
    fknoten((1, 1.35), [102 identische \ Tokens], col: c-blue, w: 30mm),
    fknoten((3, 0.85), [Token 103: \ "Queens, New York", 992 von 1000], col: c-blue, w: 44mm),
    fknoten((3, 1.85), [Token 103: \ "New York City", 8 von 1000], col: c-red, w: 44mm),
    edge((1, 1.35), (3, 0.85), "-|>"), edge((1, 1.35), (3, 1.85), "-|>"),
  ),
  caption: [Oben: Ursachenkette des Nichtdeterminismus nach He et al. Unten: der Befund aus 1000 Vervollständigungen bei Temperatur 0 mit Standard-vLLM. Alle Ausgaben waren bis Token 102 identisch und trennten sich bei Token 103 @he2025defeating.],
) <k10-fig-batch>

#studie(titel: [He und Thinking Machines Lab 2025])[
  *Design:* Qwen3-235B-A22B-Instruct-2507, Prompt "Tell me about Richard Feynman", 1000 Vervollständigungen bei Temperatur 0 mit bis zu 1000 Tokens; Leistungstest auf einer GPU mit Qwen-3-8B und 1000 Sequenzen von 90 bis 110 Ausgabetokens; zusätzlich ein Reinforcement-Learning-Experiment @he2025defeating.
  *Befund:* Standard-vLLM erzeugte 80 verschiedene Vervollständigungen, die häufigste 78-mal; alle waren für die ersten 102 Tokens identisch und trennten sich bei Token 103 (992-mal "Queens, New York", 8-mal "New York City"). Mit batch-invarianten Kernels waren alle 1000 Vervollständigungen identisch. Die Laufzeit stieg im Leistungstest von 26 s (Standard) auf 55 s (unoptimierter deterministischer Modus) beziehungsweise 42 s (mit verbessertem Attention-Kernel). Mit bitgleichem Sampler und Trainer war das RL-Training "truly on-policy" mit KL-Divergenz 0 @he2025defeating.
  *Grenzen:* Blogbeitrag mit DOI, nicht begutachtet; ein einziger Prompt im Hauptexperiment; Determinismus gilt für einen festen Hardware- und Software-Stack.
]

Die Erklärung passt zu einem Detail aus Atil et al., das dort nur als Vermutung formuliert war: Ihr lokal und ohne Serving-Optimierungen betriebenes Llama-3-8B lieferte deterministische Ergebnisse @atil2025nondeterminism. In einem Setting mit einzelnen, nicht gebündelten Anfragen schwankt die Batch-Größe nicht. Vorsicht ist aber bei der umgekehrten Schlussfolgerung geboten. Nicholson berichtet für ein lokal mit vLLM betriebenes llama3.1-8b bei Temperatur 0 einen Unique-Output-Anteil von 0.093, also keinen vollständigen Determinismus @nicholson2026quantifying[Table 1]. Nicholson gibt für den lokalen Lauf Batch-Größe 1 und feste Seeds an, sodass schwankende Batch-Größen die Variation nicht offensichtlich erklären; die Ursache bleibt offen. Lokal heißt jedenfalls nicht automatisch deterministisch.

Die Konsequenz für die Praxis ist inzwischen in Werkzeuge gegossen. vLLM bietet Batch-Invarianz als dokumentierte Funktion an, aktiviert über die Umgebungsvariable `VLLM_BATCH_INVARIANT=1`. Die Funktion ist "in beta", läuft auf NVIDIA-GPUs mit Compute Capability ab 8.0, auf AMD Instinct (gfx90a, gfx942, gfx950) und auf Intel-XPUs mit Triton und ist für Modellfamilien wie Llama 3, Qwen2.5/Qwen3, DeepSeek, GPT-OSS, Mistral, Gemma 2, Phi und Granite validiert; Tensorparallelität wird für All-Reduce-Operationen, deren Größe kein Vielfaches von 16 Byte ist, noch nicht unterstützt (Stand: 11. November 2026) @vllm2026batch.

#datei("feynman_demo.sh")[```bash
# Standardmodus: Ergebnisse hängen von der Batch-Zusammensetzung ab
vllm serve Qwen/Qwen3-8B

# Batch-invarianter Modus (beta): Ergebnis unabhängig von Batch-Größe und Reihenfolge
VLLM_BATCH_INVARIANT=1 vllm serve Qwen/Qwen3-8B
```]

Determinismus hat zwei weitere Grenzen. Er gilt pro Hardware-Stack. Yuan et al. zeigten für Reasoning-Modelle unter BF16 und gierigem Decoding bis zu 9 % Genauigkeitsvariation und bis zu 9000 Tokens Unterschied in der Antwortlänge bei DeepSeek-R1-Distill-Qwen-7B, verursacht durch GPU-Anzahl, GPU-Typ und Batch-Größe @yuan2025understanding[Abstract]. Ihre Abhilfe LayerCast speichert Gewichte in 16 Bit, rechnet aber in FP32 @yuan2025understanding. Cooper et al. erreichten 2026 bitgleiche gierige Ausgaben über die GPU-Architekturen A100, L40S und H100 mit eigenen Triton-Kernels und vier Regeln: nur IEEE-FMA (kein TF32), kein Autotuning, deterministisches Split-K ohne atomare Operationen, Batch-Invarianz innerhalb des Decode-Buckets. Ihre Methode war 1.17- bis 1.43-mal schneller als die FP32-Baseline auf A100/H100 und 1.6- bis 3.1-mal auf L40S @cooper2026accelerating[Fig. 4]. Die Arbeit ist ein Preprint und auf NVIDIA und kleine Modelle beschränkt. Für dein Provenienzprotokoll heißt das: GPU-Typ und Kernel-Einstellungen gehören dazu.

Die zweite Grenze ist grundsätzlicher. Ein deterministisches, aber falsches Label ist reproduzierbar falsch. Determinismus beseitigt eine Varianzquelle, er sagt nichts über Validität. Darauf kommt @k10-sec-debatten zurück.

#hoersaal([Wenn ein einzelner Vorwärtsdurchlauf deterministisch ist, warum ist dann der Server nicht deterministisch?], [
  Weil "deterministisch" sich auf die Funktion bei fester Eingabe bezieht, und die Eingabe des Kernels ist nicht deine Anfrage allein, sondern der ganze Batch. Dieselbe Sequenz wird in einem Batch der Größe 1 anders gerechnet als in einem Batch der Größe 37, weil der Kernel die Summen anders aufteilt. Der Server ist also eine deterministische Funktion von (deine Anfrage, alle anderen gleichzeitigen Anfragen). Aus deiner Sicht ist der zweite Teil Zufall @he2025defeating.
])

=== Hintergrundtemperatur: Zufall als Zahl

Wenn sich der Nichtdeterminismus gehosteter Endpunkte nicht beseitigen lässt, kann man ihn wenigstens quantifizieren. Messina und Scotta schlagen dafür eine einzelne, vergleichbare Größe vor: die *Hintergrundtemperatur* (_background temperature_).

#definition(titel: [Hintergrundtemperatur nach Messina und Scotta])[
  Implementierungsbedingte Störungen bei nomineller Temperatur 0 werden modelliert als Sampling bei einer effektiven Temperatur $T_n (I)$, die von der Inferenzumgebung $I$ abhängt. Die Hintergrundtemperatur ist ihr Erwartungswert über Umgebungen @messina2026introducing[Sec. 3-5]:
  $ T_"bg" = EE_I [T_n (I)] . $ <k10-eq-tbg>
]

Geschätzt wird $T_"bg"$, indem man das Zielmodell mindestens $M >= 50$-mal pro Prompt bei Temperatur 0 laufen lässt, ein lokal kontrolliertes Referenzmodell $m$ auf einem Temperaturgitter $cal(G)$ betreibt und diejenige Temperatur wählt, bei der die Verteilung einer Variabilitätsmetrik am besten übereinstimmt:

$ hat(T)^((m)) = arg min_(T in cal(G)) D(F_"target", F_"ref"^((m)) (T)), quad overline(T)_"bg" = 1 / (|cal(M)|) sum_(m in cal(M)) hat(T)^((m)) . $ <k10-eq-tbg-schaetzer>

Dabei ist $F$ die Verteilung (über Prompts) einer Variabilitätsmetrik, im Pilot der Exact-Match-Anteil von Antworten mit 32 Tokens, $D$ eine Divergenz, im Pilot die Kolmogorov-Smirnov-Distanz, und $cal(M)$ die Menge der Referenzmodelle. Die Pilotwerte auf TruthfulQA-Prompts: gpt-4.1-nano $overline(T)_"bg" = 0.075$, gemini-2.0-flash $0.065$, grok-3-mini $0.015$, claude-sonnet-4 $0$ (alle Antworten identisch) @messina2026introducing[Table 1]. Die Autoren nennen das selbst einen kleinen Pilot, keine endgültige Schätzung @messina2026introducing[Sec. 7-8].

Der Wert der Idee liegt weniger in den Zahlen als im Perspektivwechsel: Aus der Frage "Ist diese API deterministisch?" wird "Wie viel versteckter Zufall steckt in dieser API, gemessen in einer Einheit, die man vergleichen kann?". Für Anbieter, die keinen Temperaturparameter mehr annehmen, ist die nominelle Einstellung allerdings die Standardtemperatur des Anbieters, bei Anthropic API-Version `2026-10-21` also 1.0 @anthropic2026migration. Was $T_"bg"$ dann bedeutet, muss man neu durchdenken; das ist eine gute Diskussionsfrage für ein Seminar.

=== Drift und Aliase

#studie(titel: [Chen, Zaharia und Zou 2024])[
  *Design:* Längsschnitt: dieselben Prompts an die März- und Juni-2023-Versionen von GPT-3.5 und GPT-4 auf Aufgaben wie Primzahlerkennung ($n = 1000$), sensible Fragen, OpinionQA ($n = 1506$), Codegenerierung ($n = 50$), USMLE ($n = 340$) @chen2024chatgpts.
  *Befund:* GPT-4 Primzahlerkennung 84.0 % -> 51.1 %, GPT-3.5 dagegen 49.6 % -> 76.2 % @chen2024chatgpts[Sec. 3.1]. Direkt ausführbarer Code bei GPT-4 52.0 % -> 10.0 % @chen2024chatgpts[Sec. 3.5]. Antwortrate bei OpinionQA 97.6 % -> 22.1 % @chen2024chatgpts[Sec. 3.4]. Befolgung einer Extraktionsanweisung 99.5 % -> 0.5 % @chen2024chatgpts[Sec. 4]. Kernaussage: "the behavior of the 'same' LLM service can change substantially in a relatively short amount of time" @chen2024chatgpts[Abstract].
  *Grenzen:* Zwei Zeitpunkte, ein Anbieter. Heute gibt es datierte Snapshots mit veröffentlichten Abschaltterminen, was stille Drift für gepinnte Snapshots reduziert, nicht aber für Aliase.
]

Das Lehrbuch beschreibt Drift als Bedrohung der internen Validität eigener Art: als Störgröße, die die Forscherin weder sieht noch eingeführt hat @haindl2027research. Eine scheinbare Veränderung der Ergebnisse kann ein stilles Modell-Update widerspiegeln statt der manipulierten Variable. Die Gegenmittel sind praktisch: die exakte Modellversion und das Zugriffsdatum pinnen und berichten, wo möglich selbst gehostete oder archivierbare Gewichte bevorzugen, das Verhalten eines gehosteten Systems durch Aufzeichnen von Ein- und Ausgaben "einfrieren" und die Modellversion als experimentellen Faktor behandeln @haindl2027research.

2026 hat das Drift-Problem eine neue Gestalt. Bei Google werden manche Aliase wie `gemini-3.5-flash` nicht abgeschaltet, sondern leiten Anfragen automatisch auf ein neueres Modell um (Stand: 11. November 2026) @google2026geminideprecations. Ein Alias, der still umleitet, ist die Version 2026 des Problems, das Chen et al. 2023 dokumentiert haben. Bei OpenAI wurde der Alias `chatgpt-4o-latest` am 17. Februar 2026 abgeschaltet @openai2026deprecations. Die Regel ist einfach: In Studien niemals `latest`-Aliase verwenden, immer datierte Snapshots.

#fallstrick[
  Ein Alias wie `*-latest` oder ein undatierter Modellname macht jede Längsschnittaussage ungültig: Du kannst nicht unterscheiden, ob sich dein Untersuchungsgegenstand verändert hat oder das Modell. Selbst bei datierten Snapshots gehört ein festes *Probe-Set* dazu, das du zu Beginn und am Ende der Studie laufen lässt, um Drift zu erkennen @chen2024chatgpts.
]

== Versionen, Snapshots und Retirement <k10-sec-lebenszyklus>

=== Der Lebenszyklus eines gehosteten Modells

Ein gehostetes Modell durchläuft Phasen, die die Anbieter ähnlich, aber nicht identisch definieren. Für ein Forschungsvorhaben zählt vor allem, wann ein Modell nicht mehr erreichbar ist und wie viel Vorwarnung man bekommt.

#definition(titel: [Lebenszyklusphasen])[
  - *Active*: "fully supported and recommended for use" @anthropic2026model.
  - *Legacy*: erhält keine Updates mehr; "might be deprecated in the future" (Anthropic) @anthropic2026model @openai2026deprecations.
  - *Deprecated*: noch funktionsfähig, Nachfolger und Abschalttermin sind festgelegt @anthropic2026model @openai2026deprecations.
  - *Retired / shut down*: nicht mehr erreichbar, Anfragen schlagen fehl @anthropic2026model @openai2026deprecations.
  Google listet statt fester Termine "the earliest possible dates on which a model might be retired" @google2026geminideprecations.
]

#figure(
  diagram(spacing: (12mm, 8mm),
    fknoten((0, 0), [Active], col: c-green, filled: true, w: 20mm),
    fknoten((1, 0), [Legacy], col: c-yellow, filled: true, w: 20mm),
    fknoten((2, 0), [Deprecated], col: c-accent, filled: true, w: 20mm),
    fknoten((3, 0), [Retired], col: c-red, filled: true, w: 20mm),
    edge((0, 0), (1, 0), "-|>", label: text(font: "Inter", size: 6.8pt)[keine Updates]),
    edge((1, 0), (2, 0), "-|>", label: text(font: "Inter", size: 6.8pt)[Termin fix]),
    edge((2, 0), (3, 0), "-|>", label: text(font: "Inter", size: 6.8pt)[Abschaltung]),
    fknoten((2, 1), [Vorwarnfrist: OpenAI GA $>=$ 6 Monate, \ Anthropic $>=$ 60 Tage, Google ohne feste Frist], col: c-grey, w: 62mm),
    edge((2, 1), (2, 0), "-", stroke: (paint: c-grey, dash: "dashed")),
  ),
  caption: [Lebenszyklus eines gehosteten Modells und Vorwarnfristen der drei großen Anbieter (Stand: 11. November 2026) @openai2026deprecations @anthropic2026model @google2026geminideprecations.],
) <k10-fig-lebenszyklus>

Die Vorwarnfristen unterscheiden sich deutlich. OpenAI gibt mindestens sechs Monate für allgemein verfügbare Modelle, mindestens drei Monate für spezialisierte Varianten und Bildmodelle und unter Umständen nur etwa zwei Wochen für Vorschau-Modelle, sofern Sicherheits- oder Compliance-Gründe nicht schnelleres Handeln erfordern @openai2026deprecations. Anthropic benachrichtigt Kunden mit aktiven Deployments mindestens 60 Tage vor der Abschaltung öffentlich freigegebener Modelle; die Termine gelten für die von Anthropic betriebenen Plattformen, während Amazon Bedrock und Google-verwaltete Deployments eigene Zeitpläne haben @anthropic2026model. Google nennt keine feste Frist @google2026geminideprecations. Anthropic selbst listet als Nachteil von Abkündigungen ausdrücklich: "Researchers lose access to models for ongoing and comparative studies" @anthropic2026model.

=== Wie lange lebt ein Snapshot?

Die Abkündigungsseiten erlauben eine einfache Rechnung: Vom Datum im Snapshot-Namen (ungefähr das Freigabedatum) bis zum dokumentierten Abschalttermin. @k10-fig-lebensdauer zeigt das für neun Snapshots, die zur Illustration ausgewählt wurden; das ist keine systematische Analyse @anthropic2026model @openai2026deprecations.

#figure(
  balken-de((
    ([`claude-3-haiku-20240307`], 25.4),
    ([`claude-3-7-sonnet-20250219`], 12.0),
    ([`claude-sonnet-4-20250514`], 13.0),
    ([`claude-opus-4-1-20250805`], 12.0),
    ([`claude-sonnet-4-5-20250929`], 14.0),
    ([`gpt-4o-2024-08-06`], 29.3),
    ([`gpt-4.1-2025-04-14`], 21.0),
    ([`gpt-5.1-2025-11-13`], 16.6),
    ([`gpt-5.4-nano-2026-03-17`], 12.5),
  ), max: 30, breite: 7.2, farbe: c-violet, einheit: " Mon.", nachkomma: 1),
  caption: [Lebensdauer ausgewählter Snapshots vom Datum im Namen bis zur dokumentierten Abschaltung in Monaten (Stand: 11. November 2026). Einige Termine liegen in der Zukunft, etwa `claude-sonnet-4-5-20250929` am 30. November 2026 und die GPT-4o- und GPT-4.1-Snapshots am 14. Januar 2027 @anthropic2026model @openai2026deprecations.],
) <k10-fig-lebensdauer>

#beispiel(titel: [Lebensdauer eines Snapshots])[
  `claude-sonnet-4-5-20250929` trägt das Datum 29. September 2025, wurde am 30. September 2026 abgekündigt und soll am 30. November 2026 abgeschaltet werden @anthropic2026model. Das sind 427 Tage. Mit der mittleren Monatslänge von $365.25 \/ 12 = 30.4375$ Tagen ergibt sich $427 \/ 30.4375 approx 14.0$ Monate. Für `gpt-4o-2024-08-06` (Abschaltung 14. Jänner 2027 @openai2026deprecations) sind es 891 Tage, also $approx 29.3$ Monate. Der Median der neun Werte in @k10-fig-lebensdauer liegt bei 14.0 Monaten.
]

Die Lesart ist ernüchternd. Für jüngere Snapshots sind in dieser Stichprobe Lebensdauern von etwa 12 bis 17 Monaten typisch, also kürzer als ein üblicher Begutachtungs- und Revisionszyklus plus Replikationsfenster. Eine Studie, die 2026 auf einem gehosteten Modell läuft, wird für Gutachterinnen 2027 oder 2028 in der Regel nicht mehr auf demselben Snapshot wiederholbar sein. Anthropic hat sich am 4. November 2025 verpflichtet, die Gewichte aller öffentlich freigegebenen Modelle "for, at minimum, the lifetime of Anthropic as a company" aufzubewahren; eine erneute öffentliche Verfügbarkeit abgeschalteter Modelle wird aber nur geprüft, nicht zugesagt @anthropic2025commitments. Für Forschende ist das Aufbewahren ohne Zugang wenig wert. Die einzige vollständig kontrollierbare Option bleibt ein Open-Weight-Modell, dessen Gewichte du selbst archivierst @he2025defeating @vllm2026batch.

=== Modellversion und API-Version sind zwei verschiedene Dinge

Ein Snapshot-Bezeichner wie `claude-sonnet-4-5-20250929` oder `gpt-4.1-2025-04-14` pinnt die Gewichte @anthropic2026model @openai2026deprecations. Davon unabhängig gibt es *API-Versionen*, die die Semantik von Anfrage und Antwort festlegen. Anthropic verwendet dafür den Header `anthropic-version` mit den Versionen `2023-01-01`, `2023-06-01` und `2026-10-21`; die SDKs setzen den Header auf die Version, die zum Zeitpunkt der Veröffentlichung ihrer Hauptversion aktuell war @anthropic2026versions @anthropic2026migration.

Im Oktober 2026 ist diese Unterscheidung schlagartig praktisch relevant geworden. Die Versionsseite formuliert unter `2026-10-21`: "The `temperature`, `top_p`, and `top_k` request parameters are removed. A request that sends any of them returns a 400 error on every model." @anthropic2026versions. Der Migrationsleitfaden präzisiert, dass der Fehler "even at the parameter's default value" auftritt, und empfiehlt: "If a request relies on a non-default value, either stop sending the parameter, or keep that request on `2023-06-01`." @anthropic2026migration. Anfragen ohne diese Parameter sampeln mit der Standardtemperatur 1.0 @anthropic2026migration. Ältere API-Versionen liefern den Fehler, wenn ein Nicht-Standardwert gesetzt wird, "on Claude 4.7 and later models and Claude Mythos Preview" @anthropic2026model.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let zelle(x, y, txt, col) = {
      rect((x, y), (x + 4.6, y + 0.9), fill: col.lighten(82%), stroke: (paint: col, thickness: 0.8pt), radius: 0.08)
      content((x + 2.3, y + 0.45), align(center, text(font: "Inter", size: 7.2pt, txt)))
    }
    content((2.3, 2.35), text(font: "Inter", size: 7.5pt, weight: "bold")[Claude 4.6 und älter])
    content((7.1, 2.35), text(font: "Inter", size: 7.5pt, weight: "bold")[Claude 4.7+, Mythos Preview])
    content((-0.15, 1.45), anchor: "east", text(font: "Inter", size: 7.5pt)[`anthropic-version: 2023-06-01`])
    content((-0.15, 0.45), anchor: "east", text(font: "Inter", size: 7.5pt)[`anthropic-version: 2026-10-21`])
    zelle(0, 1.0, [Parameter erlaubt, \ auch Nicht-Standardwerte], c-green)
    zelle(4.8, 1.0, [nur Standardwerte, \ sonst Fehler 400], c-yellow)
    zelle(0, 0, [jede Angabe von `temperature` \ -> Fehler 400], c-red)
    zelle(4.8, 0, [jede Angabe von `temperature` \ -> Fehler 400], c-red)
  }),
  caption: [Was passiert, wenn eine Anfrage `temperature`, `top_p` oder `top_k` sendet? Die Entfernung ist an die API-Version gebunden, nicht an ein Datum. Auf `2026-10-21` gilt sie für jedes Modell (Stand: 11. November 2026) @anthropic2026versions @anthropic2026migration @anthropic2026model.],
) <k10-fig-apiversion>

Die Tragweite für Replikationspakete ist erheblich. Wer das SDK auf eine neue Hauptversion aktualisiert, wechselt still die API-Version und damit die Menge der akzeptierten Parameter @anthropic2026migration. Ein Skript, das 2025 mit `temperature=0` lief, bricht 2026 mit einem 400-Fehler ab, oder es läuft, nachdem jemand den Parameter "repariert" hat, mit Temperatur 1.0 und liefert andere Verteilungen. Ein Replikationspaket muss deshalb Snapshot, API-Version *und* SDK-Version festhalten.

Anthropic ist kein Einzelfall. Azure OpenAI dokumentiert für Reasoning-Modelle `temperature`, `top_p`, `presence_penalty`, `frequency_penalty`, `logprobs`, `top_logprobs`, `logit_bias` und `max_tokens` als nicht unterstützt, mit einer Ausnahme für GPT-6 Astra; die Unterstützungstabelle derselben Seite markiert `temperature`, `top_p` und `logprobs` allerdings für alle vier GPT-6-Modelle als unterstützt und ist damit in sich widersprüchlich (Stand: 11. November 2026) @microsoft2026reasoning. OpenAI berechnet Reasoning-Tokens als Ausgabetokens @openai2026reasoningmodels, was im Kostenmodell (@k10-sec-werkzeuge) eine Rolle spielt.

#merke[
  "Temperatur 0 für Annotationen" ist bei vielen Frontier-Modellen keine verfügbare Designentscheidung mehr. Stabilität muss durch *Wiederholung und Aggregation* erreicht und berichtet werden, nicht durch Decoding-Einstellungen. Das ist eine Schlussfolgerung aus den Anbieterdokumentationen, keine publizierte Leitlinie @anthropic2026migration @microsoft2026reasoning.
]

#datei("anthropic_request.py")[```python
import anthropic

client = anthropic.Anthropic()          # SDK-Version im Lockfile pinnen!
resp = client.messages.create(
    model="claude-sonnet-5-5",           # Modell-ID exakt so ins Manifest
    max_tokens=64,
    messages=[{"role": "user", "content": prompt}],
    # kein temperature/top_p/top_k: ab API-Version 2026-10-21 -> Fehler 400
    extra_headers={"anthropic-version": "2026-10-21"},  # explizit statt implizit
)
```]

Die Modell-ID im Beispiel stammt aus dem Kursbeispiel der Wissensbasis; den exakten datierten Snapshot-Bezeichner musst du in deinem Projekt der Modellübersicht des Anbieters entnehmen.

=== Werkzeuge beim Anbieter sind keine Forschungsartefakte

Eine Entwicklung von 2026 betrifft nicht Modelle, sondern Werkzeuge. OpenAI hat seine gehostete Evals-Plattform am 31. Oktober 2026 auf "nur lesen" gestellt und schaltet sie am 30. November 2026 ab, mit Promptfoo als genanntem Migrationsweg; wiederverwendbare Prompts (`v1/prompts`) werden ebenfalls am 30. November 2026 abgeschaltet, mit dem Rat, Prompt-Inhalte in den Anwendungscode zu verschieben @openai2026deprecations. Die Lehre ist allgemein: Prompts, Codebücher und Evaluationsdefinitionen, die nur auf einer Anbieterplattform liegen, sind keine dauerhaften Forschungsartefakte. Sie gehören in dein eigenes, versioniertes Repository.

#hoersaal([Was heißt "reproduzierbar" überhaupt noch, wenn das Modell nach zwölf Monaten abgeschaltet wird?], [
  Es heißt zweierlei. Erstens *Re-Analysierbarkeit*: Aus den archivierten Rohausgaben, den Prompts, dem Parser und dem Analysecode lässt sich jede Zahl des Berichts neu berechnen. Das ist mit gutem Logging immer erreichbar. Zweitens *Replizierbarkeit mit einem Ersatzinstrument*: Ein Open-Weight-Modell, dessen Gewichte du archivierst und batch-invariant betreibst, bildet einen Replikationsarm, der auch in fünf Jahren noch läuft @he2025defeating @vllm2026batch. Das Lehrbuch nennt die zugrunde liegende Asymmetrie: Ein gehostetes Modell ist am Tag der Studie am reproduzierbarsten, und die Dokumentation, die damals redundant schien, ist nach der Abschaltung der einzige verbleibende Beleg dafür, dass die Studie überhaupt interpretierbar ist @haindl2027research.
])

== Stabilität messen <k10-sec-stabilitaet>

Wenn Variation unvermeidlich ist, muss sie gemessen und berichtet werden. Das Lehrbuch formuliert den Grundsatz für nichtdeterministische Systeme: Jede Konfiguration ist eine Verteilung, die man beprobt, keine Funktion, die man einmal auswertet; ein Befund aus einer einzigen Generierung ist eher eine Anekdote als eine Messung @haindl2027research. Dieser Abschnitt stellt die Maße vor, mit denen du die Verteilung beschreibst.

=== Total Agreement Rate: TAR\@N

#definition(titel: [Total Agreement Rate nach Atil et al.])[
  Gegeben seien $Q$ Items, jedes $N$-mal mit identischer Eingabe und identischen Einstellungen verarbeitet; $o_(q,r)$ sei die Ausgabe für Item $q$ in Lauf $r$. Dann ist
  $ "TAR@N" = 100 / Q sum_(q=1)^Q bb(1) [o_(q,1) = o_(q,2) = dots = o_(q,N)] , $ <k10-eq-tar>
  wobei $bb(1)[dot]$ die Indikatorfunktion ist. *TARr\@N* vergleicht die rohen Ausgabestrings, *TARa\@N* die geparsten Antworten, etwa den extrahierten Buchstaben einer Multiple-Choice-Frage, sodass Formatierungsunterschiede nicht als Abweichung zählen @atil2025nondeterminism.
]

#beispiel(titel: [TARr\@3 und TARa\@3])[
  $Q = 4$ Items, $N = 3$ Läufe. Item 1: dreimal "A". Item 2: dreimal "B". Item 3: "A", "B", "A". Item 4: "C", "C.", "Answer: C".
  - Roh stimmen nur die Items 1 und 2 überein: $"TARr@3" = 100 dot 2 \/ 4 = 50 %$.
  - Nach dem Parsen (Präfix "Answer:" und Punkt entfernen) stimmt auch Item 4 überein: $"TARa@3" = 100 dot 3 \/ 4 = 75 %$.
  Item 3 bleibt in beiden Fällen instabil, weil die Labels selbst verschieden sind. Für eine Annotationsstudie ist TARa\@N die relevante Größe für die Labelstabilität; TARr\@N zählt, wenn Freitext später weiterverarbeitet wird. Das Beispiel ist das Konstruktionsbeispiel der Wissensbasis und wird im Notebook mit `assert` geprüft.
]

Das Beispiel enthält eine wichtige Lektion: *Der Parser ist Teil des Messinstruments.* TARa\@N hängt davon ab, wie großzügig er Formatierungsvarianten normalisiert. Ein Parser v2, der "C." und "Answer: C" gleich behandelt, erhöht TARa gegenüber einem strengen Parser v1, ohne dass sich am Modell etwas geändert hat. Deshalb muss der Parser versioniert werden, und seine Version gehört ins Manifest.

=== TAR\@N hängt von N ab

Eine Frage, die im Hörsaal fast sicher kommt: Ist ein TAR\@10 von 60 % gut oder schlecht? Die Antwort hängt von $N$ ab, und das lässt sich sauber herleiten.

#satz(titel: [TAR\@N fällt mit N])[
  Für ein Item mögen die $N$ Läufe unabhängig voneinander mit Wahrscheinlichkeiten $pi_1, dots, pi_K$ (mit $sum_k pi_k = 1$) eines von $K$ möglichen Labels liefern. Dann ist die Wahrscheinlichkeit, dass alle $N$ Läufe übereinstimmen,
  $ P_N = sum_(k=1)^K pi_k^N , $ <k10-eq-tar-modell>
  und $P_N$ ist in $N$ monoton nicht steigend. Ist kein Label sicher ($max_k pi_k < 1$), so fällt $P_N$ streng und geht gegen null. Der Erwartungswert von TAR\@N ist der Mittelwert von $100 dot P_N$ über die Items.
]

#beweis[
  Alle $N$ Läufe stimmen genau dann überein, wenn sie alle das Label $k$ liefern, für irgendein $k$. Diese Ereignisse sind für verschiedene $k$ disjunkt, und wegen der Unabhängigkeit gilt $P("alle" = k) = pi_k^N$. Summieren liefert @k10-eq-tar-modell. Für jedes $k$ gilt $0 <= pi_k <= 1$, also $pi_k^(N+1) = pi_k dot pi_k^N <= pi_k^N$, und Summation ergibt $P_(N+1) <= P_N$. Ist $max_k pi_k < 1$, so ist jedes $pi_k^(N+1) < pi_k^N$ für $pi_k > 0$, und $P_N <= K dot (max_k pi_k)^N -> 0$. Die Aussage über den Erwartungswert folgt aus der Linearität des Erwartungswerts angewandt auf die Indikatoren in @k10-eq-tar.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let sx = 0.42
    let sy = 4.2
    // Achsen
    line((0, 0), (20 * sx + 0.3, 0), stroke: 0.7pt, mark: (end: "stealth", fill: black, scale: 0.5))
    line((0, 0), (0, sy + 0.3), stroke: 0.7pt, mark: (end: "stealth", fill: black, scale: 0.5))
    for n in (1, 5, 10, 15, 20) {
      line((n * sx, 0), (n * sx, -0.08), stroke: 0.5pt)
      content((n * sx, -0.32), text(font: "Inter", size: 7pt, str(n)))
    }
    for v in (0, 0.25, 0.5, 0.75, 1.0) {
      line((0, v * sy), (-0.08, v * sy), stroke: 0.5pt)
      line((0, v * sy), (20 * sx, v * sy), stroke: (paint: luma(225), thickness: 0.4pt))
      content((-0.15, v * sy), anchor: "east", text(font: "Inter", size: 7pt, str(int(v * 100)) + " %"))
    }
    content((10 * sx, -0.75), text(font: "Inter", size: 7.5pt)[Anzahl Läufe $N$])
    content((-1.25, sy / 2), angle: 90deg, text(font: "Inter", size: 7.5pt)[erwartete Übereinstimmung $P_N$])
    let kurven = ((0.99, c-blue, 0), (0.95, c-teal, 0), (0.9, c-accent, 0.12), (0.8, c-red, -0.12))
    for (pw, col, dy) in kurven {
      let pts = range(1, 21).map(n => (n * sx, (calc.pow(pw, n) + calc.pow(1 - pw, n)) * sy))
      line(..pts, stroke: (paint: col, thickness: 1.2pt))
      for p in pts { circle(p, radius: 0.04, fill: col, stroke: none) }
      let last = pts.last()
      content((last.at(0) + 0.15, last.at(1) + dy), anchor: "west", text(font: "Inter", size: 7pt, fill: col, weight: "bold")[$pi$ = #dez(pw)])
    }
  }),
  caption: [Erwartete Übereinstimmungswahrscheinlichkeit $P_N = pi^N + (1 - pi)^N$ für ein binäres Label nach @k10-eq-tar-modell. Selbst bei $pi = 0.95$ stimmen zehn Läufe nur mit Wahrscheinlichkeit 0.60 überein. Eigene Rechnung unter Unabhängigkeitsannahme.],
) <k10-fig-tar-n>

#beispiel(titel: [Gleiches Modell, verschiedene N])[
  Ein binäres Label werde pro Lauf mit $pi = 0.95$ als "relevant" und mit $0.05$ als "nicht relevant" vergeben. Nach @k10-eq-tar-modell:
  - $N = 3$: $P_3 = 0.95^3 + 0.05^3 = 0.857375 + 0.000125 = 0.8575$.
  - $N = 10$: $P_10 = 0.95^10 + 0.05^10 approx 0.5987 + 0 = 0.5987$.
  - $N = 20$: $P_20 approx 0.3585$.
  Ein Modell, das auf jedem einzelnen Lauf zu 95 % das Mehrheitslabel liefert, erzielt also erwartet TAR\@3 $approx 86 %$, aber TAR\@10 $approx 60 %$. Wer TAR-Werte vergleicht, muss dasselbe $N$ verwenden, und wer TAR berichtet, muss $N$ nennen. Die Unabhängigkeitsannahme ist dabei eine Idealisierung: Läufe auf demselben Server zur selben Zeit können korreliert sein.
]

Atil et al. haben $N = 10$ verwendet @atil2025nondeterminism. Diesen Wert solltest du als Konvention übernehmen, wenn du mit ihren Zahlen vergleichen willst. Die Leitlinie llm-guidelines.org verlangt keine bestimmte Zahl, wohl aber eine Begründung: "researchers should justify their chosen number of repetitions" @baltes2025guidelines[Sec. 5.5].

=== Beste und schlechteste mögliche Genauigkeit

Atil et al. berichten neben TAR zwei Größen, die die Spannweite des Möglichen beschreiben. Für die *beste mögliche Genauigkeit* zählt ein Item als korrekt, wenn irgendein Lauf richtig war; für die *schlechteste mögliche Genauigkeit* nur, wenn alle Läufe richtig waren @atil2025nondeterminism. Die Differenz ist eine obere Schranke dafür, wie sehr sich eine "Genauigkeit aus einem Lauf" allein durch Glück oder Pech verschieben kann. Bei Atil et al. waren das bis zu 70 Prozentpunkte @atil2025nondeterminism[Abstract].

Dazu kommt ein Befund, der direkte Folgen für die Auswertung hat: Die Verteilungen der Genauigkeit über Läufe waren nicht normal (Kolmogorov-Smirnov $p < 10^(-9)$ für GPT-4o und Llama-3-70B auf College Mathematics) @atil2025nondeterminism. Mittelwert und Standardabweichung allein beschreiben solche Verteilungen schlecht. Berichte Minimum, Median und Maximum über die Läufe, zusätzlich zu Mittelwert und Streuung.

=== Unique-Output-Anteil und Jaccard-Ähnlichkeit

Für Freitext ist "alle gleich oder nicht" zu grob. Nicholson verwendet pro Prompt $p$ mit $R$ Läufen zwei feinere Maße @nicholson2026quantifying[Sec. 3]:

$ U_p = (|{o_(p,1), dots, o_(p,R)}|) / R , quad J_p = binom(R, 2)^(-1) sum_(r < s) (|W(o_(p,r)) inter W(o_(p,s))|) / (|W(o_(p,r)) union W(o_(p,s))|) . $ <k10-eq-unique>

$U_p$ ist der Anteil verschiedener Ausgaben; $U_p = 1 \/ R$ bedeutet volle Wiederholbarkeit, $U_p = 1$ heißt, jeder Lauf war anders. $J_p$ ist die mittlere paarweise Jaccard-Ähnlichkeit der Wortmengen $W(dot)$ zweier Ausgaben. Beide werden über Prompts gemittelt. Die genaue Tokenisierung für $W(dot)$ ist in der Studie nicht festgelegt; du musst deine Wahl angeben.

#beispiel(titel: [Unique-Anteil und Jaccard für drei Läufe])[
  Drei Läufe liefern "der Text ist positiv", "der Text ist positiv" und "Text klar positiv". Verschiedene Ausgaben: 2, also $U = 2 \/ 3 approx 0.667$. Wortmengen: $A = B = {"der", "Text", "ist", "positiv"}$, $C = {"Text", "klar", "positiv"}$. Paare: $J(A, B) = 4 \/ 4 = 1$; $J(A, C) = |{"Text", "positiv"}| \/ |{"der", "Text", "ist", "positiv", "klar"}| = 2 \/ 5 = 0.4$; ebenso $J(B, C) = 0.4$. Mittel: $J = (1 + 0.4 + 0.4) \/ 3 = 0.6$.
]

#studie(titel: [Nicholson 2026])[
  *Design:* gpt-4o-mini (API) und llama3.1-8b (lokal, vLLM, bfloat16, A100); Temperaturen 0.0 und 0.7; Modi exakte Wiederholung, gestörte Eingabe, Wiederverwendung; 100 Prompts $times$ 30 Läufe und 25 Prompts $times$ 20 Läufe @nicholson2026quantifying[Sec. 3].
  *Befund:* Bei exakter Wiederholung und $T = 0$ lag der Unique-Anteil bei 0.240 (gpt-4o-mini, Jaccard 0.893) gegenüber 0.093 (llama3.1-8b, Jaccard 0.966); bei gestörter Eingabe bei 0.572 und 0.274. Bei $T = 0.7$ erreichten die Unique-Anteile 0.973 bis 1.000 @nicholson2026quantifying[Table 1]. Empfehlungen: zuerst Baseline-Drift messen, mehrere Läufe berichten, Seeds, Batch-Größen und Decoding-Einstellungen protokollieren, ein anwendungsspezifisches "Varianzbudget" festlegen @nicholson2026quantifying[Sec. 6].
  *Grenzen:* Einzelautor-Preprint mit inneren Widersprüchen zwischen Text und Tabelle 1; Datenfreigabe angekündigt, aber nicht verfügbar. Gerade deshalb ist die Arbeit gutes Material für eine Übung im kritischen Lesen.
]

Nicholson empfiehlt, lexikalische Maße durch semantische zu ergänzen, weil harmlose Paraphrasen die lexikalische Drift aufblähen @nicholson2026quantifying[Sec. 5-6]. Für Annotationsstudien mit geschlossenen Labels ist das weniger relevant: Dort ist TARa\@N nach dem Parsen das Maß der Wahl.

=== Aggregation über Läufe: Mehrheitslabel

Wenn Temperatur 0 nicht verfügbar ist, liegt es nahe, jedes Item mehrfach zu annotieren und das Mehrheitslabel zu verwenden. Unter einer Unabhängigkeitsannahme lässt sich der Effekt berechnen.

#beispiel(titel: [Mehrheitsentscheid über drei und fünf Läufe])[
  Ein binäres Label sei pro Lauf mit Wahrscheinlichkeit $q = 0.8$ korrekt, Läufe seien unabhängig. Das Mehrheitslabel aus $N$ (ungerade) Läufen ist korrekt, wenn mindestens $(N+1) \/ 2$ Läufe korrekt sind:
  $ P_"maj" (N) = sum_(k = (N+1)\/2)^N binom(N, k) q^k (1 - q)^(N - k) . $ <k10-eq-mehrheit>
  - $N = 3$: $3 dot 0.8^2 dot 0.2 + 0.8^3 = 0.384 + 0.512 = 0.896$.
  - $N = 5$: $10 dot 0.8^3 dot 0.2^2 + 5 dot 0.8^4 dot 0.2 + 0.8^5 = 0.2048 + 0.4096 + 0.32768 = 0.94208$.
  Die Verbesserung von 0.80 auf 0.94 ist allerdings eine Obergrenze. Fehler eines LLM sind über Läufe stark korreliert: Wenn das Modell ein Item systematisch falsch versteht, liefert es in fast jedem Lauf dasselbe falsche Label. Aggregation beseitigt Rauschen, keine Verzerrung. Den systematischen Anteil erkennst du nur an Goldlabels (Kapitel 5).
]

=== Wie viele Wiederholungen?

Das Lehrbuch beantwortet die Frage mit derselben Logik wie jede Stichprobenplanung: Die Zahl der Läufe soll die interessierende Größe mit akzeptabler Präzision schätzen, und das hängt davon ab, wie variabel die Ausgabe ist und wie klein der Unterschied ist, den die Studie erkennen will @haindl2027research. Die Variation stammt hier vom System statt von der Stichprobe, die Rechnung ist aber dieselbe. Wie in Kapitel 6 gilt: Wer zwei Systeme vergleichen will, braucht eine Power-Analyse; Card et al. haben gezeigt, wie oft NLP-Vergleiche dafür zu klein sind @Card2020.

#beispiel(titel: [Präzision eines TAR-Werts])[
  Du misst TARa\@10 auf $Q = 200$ Items und erhältst 80 %. Fasst man die Items als unabhängige Bernoulli-Beobachtungen auf, ist der Standardfehler $sqrt(0.8 dot 0.2 \/ 200) = sqrt(0.0008) approx 0.0283$, das 95-%-Konfidenzintervall nach Wald also etwa $80 % plus.minus 5.5$ Prozentpunkte. Willst du zwei Prompt-Varianten unterscheiden, die sich um 5 Punkte in TAR unterscheiden, reichen 200 Items nicht.
]

Die Zahl der Läufe $N$ und die Zahl der Items $Q$ spielen unterschiedliche Rollen. $N$ bestimmt, was TAR misst (@k10-fig-tar-n), $Q$ bestimmt, wie genau es gemessen wird. Ein pragmatischer Plan, den die Referenz-Pipeline in @k10-sec-pipeline aufgreift: Der Produktivlauf läuft einmal über alle Items, die Stabilitätsanalyse $N = 10$-mal über eine geschichtete Teilstichprobe.

=== Ein Stabilitätsprotokoll

Die folgenden sechs Schritte fassen die Empfehlungen der verifizierten Quellen zusammen. Das ist eine Synthese für die Lehrveranstaltung, kein publizierter Standard.

#merke[
  1. Modell-Snapshot, API-Version, SDK-Version, alle tatsächlich gesendeten Decoding-Parameter und, wo vorhanden, den `system_fingerprint` der Antwort festhalten @anthropic2026versions @microsoft2026reproducible.
  2. Jede Bedingung mindestens $N = 10$-mal laufen lassen und TARa\@N, TARr\@N, Minimum, Median und Maximum der Zielmetrik sowie beste und schlechteste mögliche Genauigkeit berichten @atil2025nondeterminism.
  3. Baseline-Drift messen, bevor eine Stabilisierungstechnik getestet wird, damit die Intervention nicht mit Rauschen verwechselt wird @nicholson2026quantifying[Sec. 6].
  4. Nicht annehmen, dass Temperatur 0 oder ein Seed Reproduzierbarkeit garantieren; Seeds und Batch-Größen bei selbst gehosteten Läufen protokollieren @nicholson2026quantifying @ouyang2025empirical.
  5. Für Hauptergebnisse, die bitgleich neu erzeugbar sein müssen, ein Open-Weight-Modell mit batch-invarianter Inferenz verwenden und Gewichte sowie Version des Inferenz-Stacks archivieren @he2025defeating @vllm2026batch; über GPU-Architekturen hinweg braucht es zusätzliche Maßnahmen @cooper2026accelerating.
  6. Ein festes Probe-Set während langer Studien periodisch erneut laufen lassen, um Drift des Dienstes zu erkennen @chen2024chatgpts.
]

#hoersaal([Ist Run-to-Run-Variation nicht einfach Rauschen, das man wegmitteln sollte?], [
  Nicht unbedingt. Variation kann auch Information sein: Ein Item, bei dem das Modell über zehn Läufe zwischen zwei Labels schwankt, ist vermutlich auch für Menschen schwierig oder im Codebuch unklar definiert. Nicholson und Messina behandeln Variabilität deshalb als Größe, die man misst und budgetiert, statt sie nur zu eliminieren @nicholson2026quantifying @messina2026introducing. In einer Annotationsstudie kannst du instabile Items gezielt an menschliche Codierende geben. Ob sich Instabilität tatsächlich als Unsicherheitssignal eignet, ist aber eine offene Forschungsfrage, keine gesicherte Erkenntnis.
])

== Eine Referenz-Pipeline Stufe für Stufe <k10-sec-pipeline>

Dieser Abschnitt baut eine vollständige Pipeline für eine typische LLM-Studie auf: Ein LLM annotiert einige tausend Texte nach einem Codebuch, die Labels werden gegen eine menschlich codierte Goldstichprobe validiert und gehen dann in eine statistische Analyse ein. Die Vorlage ist eine Synthese für die Lehrveranstaltung; jede Stufe nennt das Artefakt, das sie erzeugt, und den verifizierten Befund, der sie motiviert. Sie ist so gebaut, dass eine Gutachterin jede Zahl im Bericht prüfen kann. Das Notebook `notebooks/10_reproducible_pipeline.ipynb` setzt sie mit einem simulierten Annotator vollständig um; Foliensatz 10 zeigt sie Stufe für Stufe.

#figure(
  diagram(spacing: (5mm, 9mm),
    fknoten((0, 0), [1 Design + Prä- \ registrierung], col: c-blue, filled: true, w: 32mm),
    fknoten((1, 0), [2 Modellwahl + \ Lebenszyklus], col: c-blue, filled: true, w: 32mm),
    fknoten((2, 0), [3 Prompt + Codebuch \ versionieren], col: c-blue, filled: true, w: 32mm),
    fknoten((3, 0), [4 Pilot \ 1-5 % der Items], col: c-teal, filled: true, w: 32mm),
    fknoten((3, 1), [5 Produktivlauf \ (Batch)], col: c-teal, filled: true, w: 32mm),
    fknoten((2, 1), [6 sofort \ archivieren + hashen], col: c-teal, filled: true, w: 32mm),
    fknoten((1, 1), [7 Stabilität \ $N >= 10$, Teilstichprobe], col: c-accent, filled: true, w: 32mm),
    fknoten((0, 1), [8 Validierung \ gegen Gold], col: c-accent, filled: true, w: 32mm),
    fknoten((0, 2), [9 Replikationsarm \ Open Weights], col: c-violet, filled: true, w: 32mm),
    fknoten((1, 2), [10 Drift-Probe \ Anfang + Ende], col: c-violet, filled: true, w: 32mm),
    fknoten((2, 2), [11 Reporting + \ Replikationspaket], col: c-dark, filled: true, w: 32mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"),
    edge((3, 0), (3, 1), "-|>"), edge((3, 1), (2, 1), "-|>"), edge((2, 1), (1, 1), "-|>"), edge((1, 1), (0, 1), "-|>"),
    edge((0, 1), (0, 2), "-|>"), edge((0, 2), (1, 2), "-|>"), edge((1, 2), (2, 2), "-|>"),
    edge((3, 0), (2, 0), "-", stroke: (paint: c-grey, dash: "dashed"), bend: 40deg, label: text(font: "Inter", size: 6.5pt)[Revision \ vor Freeze]),
    fknoten((3, 2), [`manifest.json` \ begleitet jede Stufe], col: c-grey, w: 32mm),
  ),
  caption: [Die Referenz-Pipeline in elf Stufen. Blau: Planung, alles vor dem ersten Produktivaufruf ist eingefroren. Grün: Durchführung. Orange: Qualitätssicherung (Kapitel 5 und 6). Violett: Absicherung gegen Abschaltung und Drift. Revisionen nach dem Pilot sind erlaubt, solange sie vor dem Freeze dokumentiert werden.],
) <k10-fig-pipeline>

=== Stufe 1: Design und Präregistrierung

Am Anfang steht keine Technik, sondern ein Forschungsdesign. Das Lehrbuch verlangt, dass du im Methodenteil nicht nur sagst, was du gewählt hast, sondern warum, und dass Stichprobe und Instrumente so dokumentiert sind, dass andere sie prüfen und wiederverwenden können @haindl2027research. Für eine LLM-Studie heißt "Instrument" die Kombination aus Modell, Prompt, Codebuch und Parser. Das Lehrbuch fordert, eigene Instrumente samt Entwicklung, Pilotierung und Validierung zu beschreiben und die Codierschemata im Anhang beizulegen @haindl2027research.

Der wichtigste methodische Schritt ist die *Präregistrierung*: Forschungsfragen, Hypothesen und Analyseplan werden dokumentiert und mit Zeitstempel versehen, bevor die Ergebnisse beobachtet werden @Nosek2018. Ihr Wert liegt in der klaren Trennung von konfirmatorischer und explorativer Forschung; nur die erste darf die Sprache des Hypothesentestens verwenden @haindl2027research. Bei LLM-Studien ist diese Trennung besonders gefährdet, weil die Zahl der Freiheitsgrade enorm ist.

#studie(titel: [Baumann et al. 2025: LLM-Hacking])[
  *Design:* Multiversum-Replikation: 37 Annotationsaufgaben aus 21 publizierten sozialwissenschaftlichen Studien, 13 Millionen Labels von 18 LLMs, 2361 Hypothesen, 21 Gegenmaßnahmen @baumann2025large[Abstract].
  *Befund:* Mit State-of-the-Art-LLMs führten etwa 31 % der Hypothesen zu falschen Schlüssen, mit kleineren Modellen etwa die Hälfte. Absichtliches "LLM-Hacking" ist sehr einfach: Eine Handvoll Prompt-Paraphrasen reicht, um nahezu jedes Ergebnis signifikant zu machen. Menschliche Annotationen schützen vor falsch-positiven Befunden; Regressionskorrekturen stellen valide Inferenz her, tauschen aber Fehler 1. Art gegen Fehler 2. Art. Das Risiko sinkt mit wachsender Effektgröße @baumann2025large[Abstract].
  *Grenzen:* Preprint, nur Annotationsaufgaben.
]

Dazu kommt die Prompt-Sensitivität, die das Lehrbuch als Bedrohung der Konstruktvalidität einordnet: Formatierungsänderungen ohne inhaltliche Bedeutung erzeugten bei offenen Modellen im schlimmsten Fall Unterschiede von bis zu 76 Genauigkeitspunkten, im Mittel über viele Aufgaben und Modelle um die zehn @Sclar2024, und die Rangfolge von Modellen kann sich je nach gewählter Prompt-Vorlage umkehren @Mizrahi2024. Biderman et al. zeigen dasselbe an konkreten Zahlen: Allein das Prompt-Format verschiebt die ARC-Challenge-Genauigkeit von Mistral-7B zwischen 50.1 % (Cloze) und 72.4 % (MMLU-Stil), und das beste Format unterscheidet sich je nach Modell @biderman2024lessons[Table 1].

#merke[
  Präregistriere bei einer LLM-Studie mindestens: Modell und Snapshot, Prompt-Vorlage und Codebuch (als Datei mit Hash), Parser und seine Regeln, Batching-Strategie (wie viele Items pro Anfrage), Zahl der Wiederholungen, Größe und Ziehung der Goldstichprobe, Validierungsmetrik mit Schwellenwert, statistisches Modell inklusive Korrektur für Annotationsfehler (Kapitel 6) und eine Multiversum- oder Sensitivitätsanalyse über Prompt-Paraphrasen. Was danach dazukommt, ist explorativ und wird so benannt.
]

Die Batching-Strategie gehört dazu, weil sie das Ergebnis verändert: In der Studie von Figalova et al. erreichte GPT-5.4 im Modus "alle auf einmal" nur 66.8 % Recall gegenüber 82.3 bis 82.9 % bei den menschlichen Screenern und den GPT-5.4-Läufen mit Dateibatches (Details in @k10-sec-reviews) @figalova2026evaluating[Table 3].

=== Stufe 2: Modellwahl zwischen offenem Modell und API

Die Wahl des Modells ist eine methodische Entscheidung, keine reine Leistungsfrage. Palmer, Smith und Spirling argumentieren, dass Wissenschaftlerinnen geschlossene Modelle wo möglich meiden und, wenn sie sie verwenden, begründen sollten, warum, welche offenen Modelle verglichen wurden und was offene Entwickler verbessern könnten; Zeitschriften und Konferenzen sollten solche Begründungen fördern oder sogar verlangen @palmer2024using. Ihre Begründung: Unternehmen "can alter (even abandon and make unavailable) their algorithms at any time" @palmer2024using. Sie nennen selbst sechs Umstände, die proprietäre Modelle rechtfertigen können, darunter die Untersuchung des Modells selbst und State-of-the-Art-Leistung @palmer2024using. Die Leitlinie llm-guidelines.org formuliert es als Soll-Kriterium: "an open LLM should be one of the models under evaluation" @baltes2025guidelines[Sec. 5.6].

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    table.header([Kriterium], [Gehostete API], [Selbst gehostetes Open-Weight-Modell]),
    [Leistung], [stärkste Modelle verfügbar], [je nach Aufgabe niedriger (hier nicht quantifiziert)],
    [Kosten], [pro Token; Batch-Rabatt 50 % @openai2026batch @anthropic2026batch @google2026geminipricing], [Hardware und Betrieb],
    [Determinismus], [keine Garantie @microsoft2026reproducible @openai2023reproducible], [bitgleich erreichbar mit Batch-Invarianz @he2025defeating @vllm2026batch],
    [Parameter], [Sampling-Parameter teils entfernt @anthropic2026migration], [volle Kontrolle],
    [Lebensdauer], [Snapshots etwa 12-17 Monate (@k10-fig-lebensdauer)], [unbegrenzt, wenn Gewichte archiviert],
    [Drift], [Aliase leiten teils still um @google2026geminideprecations], [keine, solange nichts geändert wird],
    [Datenschutz], [Drittlandtransfer, Aufbewahrung beim Anbieter @openai2026data], [Daten verlassen die Institution nicht],
  ),
  kind: table, supplement: [Tab.],
  caption: [Gehostete API und selbst gehostetes Modell als Forschungsinstrument (Stand: 11. November 2026).],
) <k10-tab-modellwahl>

Die Konsequenz für die Referenz-Pipeline ist ein *Zwei-Arm-Design*: ein Primärinstrument, das je nach Fragestellung ein gehostetes Frontier-Modell sein kann, und ein Replikationsarm mit einem archivierten Open-Weight-Modell, das batch-invariant betrieben wird. Beide Arme laufen auf derselben Pipeline. Wenn der Replikationsarm qualitativ dieselben Schlüsse liefert, ist der Befund nicht an ein Modell gebunden, das in einem Jahr verschwindet. Wenn nicht, ist das selbst ein berichtenswerter Befund.

Die Modellwahl wird in einer Konfigurationsdatei festgehalten, die auch den Lebenszyklus dokumentiert. Die Übung "Model lifecycle audit" der Wissensbasis verlangt pro Kandidat Anbieter, Snapshot-ID, Status, Abkündigungs- und Abschalttermin, Fristregel und die Restlebensdauer zum geplanten Einreichungstermin.

#datei("config/models.yaml")[```yaml
primary:
  provider: anthropic
  model: claude-sonnet-5-5          # exakte ID aus der Modellübersicht übernehmen
  api_version: "2026-10-21"         # anthropic-version Header
  sdk: {name: anthropic, version: "<gepinnt im Lockfile>"}
  status: active                    # Stand 2026-11-11
  retirement_date: null             # bei Abkündigung eintragen
  notice_rule: ">= 60 Tage"
replication_arm:
  provider: local-vllm
  model: Qwen/Qwen3-8B              # Gewichte archiviert, Hash in env/
  runtime: {vllm: "<gepinnt>", env: {VLLM_BATCH_INVARIANT: "1"}}
  gpu: "<Typ eintragen>"
submission_planned: 2027-06-30
```]

=== Stufe 3: Prompts und Codebuch versionieren

Ein Prompt ist Code und wird so behandelt. Die Regeln sind einfach. Jede Prompt-Vorlage und jedes Codebuch liegt als Datei im Repository. Jede Änderung ist ein Commit. Und jede *gerenderte* Anfrage, also die Vorlage mit eingesetztem Item, wird mit SHA-256 gehasht, und der Hash geht ins Manifest. Der Hash identifiziert eine Prompt-Version exakt: Ein einziges zusätzliches Leerzeichen ändert ihn, wie das Notebook mit einem `assert` demonstriert. Die Leitlinie llm-guidelines.org empfiehlt ausdrücklich, Prüfsummen und Fingerprints zu berichten @baltes2025guidelines[Sec. 5.2.2].

Die Leitlinie llm-guidelines.org verlangt: "Researchers must report all prompts used in an empirical study, including instructions, task context, input data, and output indicators" @baltes2025guidelines[Sec. 5.3.2]. Und die Abschaltung der Prompt-Ablage von OpenAI zeigt, warum das Repository der einzig sichere Ort ist @openai2026deprecations.

#datei("src/prompts.py")[```python
import hashlib
from pathlib import Path

def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()

def render(template: str, codebook: str, item_text: str) -> str:
    return template.format(codebook=codebook, text=item_text)

codebook = Path("prompts/codebook_v1.md").read_text(encoding="utf-8")
template = Path("prompts/templates/annotate_v1.txt").read_text(encoding="utf-8")
prompt_meta = {
    "codebook_sha256": sha256_text(codebook),
    "template_sha256": sha256_text(template),
}
assert sha256_text(codebook) != sha256_text(codebook + " ")   # ein Leerzeichen genügt
```]

#tipp[
  Lege das Codebuch so an, dass der statische Teil (Anweisung, Kategorien, Beispiele) am Anfang des Prompts steht und das Item am Ende. Dann ist der Anfang für alle Anfragen identisch und kann vom Prompt-Caching des Anbieters profitieren (@k10-sec-werkzeuge). Gute Reproduzierbarkeit und niedrige Kosten ziehen hier in dieselbe Richtung.
]

=== Stufe 4: Pilot

Bevor 20 000 Anfragen laufen, laufen 1 bis 5 % davon. Der Pilot hat drei Aufgaben: Er misst die tatsächlichen Tokenzahlen und Cache-Trefferquoten für das Kostenmodell, er liefert eine erste Stabilitätsschätzung (TAR\@N auf einer kleinen Stichprobe), und er deckt Parserfehler auf. Änderungen am Prompt nach dem Pilot sind legitim, solange sie *vor* dem Freeze und *vor* dem Blick auf Goldlabels erfolgen und dokumentiert sind. Wer dagegen den Prompt revidiert, nachdem er die Übereinstimmung mit Gold gesehen hat, betritt den Garten der Pfadgabelungen, vor dem das Lehrbuch warnt @haindl2027research. Dai et al. haben genau so eine Post-hoc-Revision berichtet und selbst als Einschränkung benannt (@k10-sec-reviews) @dai2025accuracy.

=== Stufe 5: Pipeline-Code und Produktivlauf

Die Projektstruktur folgt der Kursvorlage der Wissensbasis. Sie trennt Konfiguration, Prompts, Daten, Code, Läufe und Umgebung, und sie setzt die Regel des Lehrbuchs um, Rohdaten strikt von verarbeiteten Daten zu trennen, damit die Kette von der Beobachtung zur Abbildung nachvollziehbar bleibt @haindl2027research.

#datei("Projektstruktur")[```text
project/
  README.md                 # Reproduktion, Hardware, Kontakt
  prereg/                   # Präregistrierung + Analyseplan (eingefroren, datiert)
  config/
    models.yaml             # Snapshot-IDs, API-Version, SDK-Versionen, Abschalttermine
    decoding.yaml           # tatsächlich gesendete Parameter (oder "provider default")
  prompts/
    codebook_v1.md
    templates/annotate_v1.txt
  data/
    raw/                    # Quelltexte (vor jedem API-Aufruf pseudonymisiert)
    gold/                   # menschlich codierte Validierungsstichprobe
    derived/
  src/
    build_requests.py       # Vorlagen rendern -> requests.jsonl (+ Hashes)
    submit_batch.py         # Anbieter-Adapter; schreibt das Manifest
    parse.py                # versionierter Parser (TARa hängt davon ab)
    stability.py            # TAR@N, Unique-Anteil
    validate.py             # Übereinstimmung mit Gold (Kapitel 5)
    estimate.py             # Schätzungen mit Korrektur (Kapitel 6)
  runs/<run_id>/
    requests.jsonl
    responses.jsonl         # roh, nie editiert
    manifest.json
  reports/
  env/
    requirements.lock       # gepinnte Bibliotheksversionen
    vllm_version.txt        # Inferenz-Stack und GPU-Modell
```]

Das Herz der Pipeline ist eine Funktion, die für jedes Item einen Schlüssel bildet, im Cache nachsieht und nur bei einem Fehltreffer das Modell aufruft. Der Cache-Schlüssel enthält *alles, was eine Antwort verändern kann*: Modellblock (Snapshot, API-Version, SDK-Version), Decoding-Parameter, gerenderten Prompt, Item-ID und Wiederholungsindex. Damit kann ein Cache-Treffer nie eine Antwort zurückgeben, die unter anderen Einstellungen entstanden ist. Das Gerüst folgt dem Notebook:

#datei("src/pipeline.py")[```python
import json, time
from datetime import datetime, timezone
from pathlib import Path

def cache_key(model_block: dict, decoding: dict, prompt: str, item_id: str, rep: int) -> str:
    payload = json.dumps({"model": model_block, "decoding": decoding, "prompt": prompt,
                          "item": item_id, "rep": rep}, sort_keys=True, ensure_ascii=False)
    return sha256_text(payload)

def run_pipeline(cfg, items, run_id, n_runs=1, call_llm=None, cache_dir=Path("cache")):
    run_dir = Path("runs") / run_id
    run_dir.mkdir(parents=True, exist_ok=False)          # nie überschreiben
    started = datetime.now(timezone.utc).isoformat()
    hits = misses = 0
    with open(run_dir / "requests.jsonl", "w") as rq, open(run_dir / "responses.jsonl", "w") as rs:
        for item in items:
            prompt = render(cfg.template, cfg.codebook, item["text"])
            for rep in range(n_runs):
                key = cache_key(cfg.model_block, cfg.decoding, prompt, item["id"], rep)
                path = cache_dir / f"{key}.json"
                if path.exists():
                    resp = json.loads(path.read_text()); hits += 1
                else:
                    resp = call_llm(prompt, **cfg.decoding)  # Anbieter-Adapter
                    path.write_text(json.dumps(resp)); misses += 1
                rq.write(json.dumps({"item_id": item["id"], "rep": rep,
                                     "prompt_sha256": sha256_text(prompt)}) + "\n")
                rs.write(json.dumps({"item_id": item["id"], "rep": rep, "raw": resp["text"],
                                     "usage": resp.get("usage"),
                                     "fingerprint": resp.get("system_fingerprint")}) + "\n")
    write_manifest(run_dir, cfg, started, hits, misses)
    return run_dir
```]

Drei Entscheidungen in diesem Gerüst sind keine Stilfragen. `exist_ok=False` verhindert, dass ein Lauf einen früheren überschreibt. Die Rohantwort wird gespeichert, bevor irgendein Parser sie anfasst, denn TARr und TARa brauchen beide Ebenen. Und der Wiederholungsindex ist Teil des Cache-Schlüssels, sonst würde die Stabilitätsanalyse zehnmal dieselbe zwischengespeicherte Antwort lesen und TAR\@10 = 100 % melden.

Für den Produktivlauf über eine gehostete API ist die Batch-Schnittstelle des Anbieters der Normalfall: halber Preis, Abarbeitung innerhalb von 24 Stunden @openai2026batch @anthropic2026batch. Bei Anthropic sind bis zu 100 000 Anfragen oder 256 MB pro Batch möglich, die meisten Batches sind innerhalb einer Stunde fertig, Ergebnisse bleiben 29 Tage abrufbar @anthropic2026batch. Bei OpenAI sind es bis zu 50 000 Anfragen und 200 MB pro Eingabedatei, bis zu 2000 Batches pro Stunde, und Ausgabedateien werden 30 Tage nach Abschluss gelöscht (Stand: 11. November 2026) @openai2026batch.

=== Stufe 6: Logging, Provenienz und Archivierung

Das *Manifest* ist die Prüfspur eines Laufs. Es beantwortet die Fragen, die eine Gutachterin oder du selbst in zwei Jahren stellen wirst: welcher Snapshot, welche API-Version, welche Parameter, welcher Prompt (Hash), welcher Parser, wann, in welcher Umgebung, wie viele Aufrufe, zu welchen Kosten und welche exakten Ausgaben (Hash). Die Felder sind aus den Anforderungen der Leitlinien abgeleitet: Modellversion und Datum der Durchführung, alle Konfigurationswerte, auch Standardwerte, sowie Prüfsummen und Fingerprints @baltes2025guidelines[Sec. 5.2.2].

#datei("runs/2027-03-14_annot_v1_r03/manifest.json")[```json
{
  "run_id": "2027-03-14_annot_v1_r03",
  "provider": "anthropic",
  "model": "claude-sonnet-5-5",
  "api_version_header": "2026-10-21",
  "sdk": {"name": "anthropic", "version": "<pinned>"},
  "decoding": {"temperature": "provider default", "max_tokens": 64},
  "system_fingerprint": null,
  "inference_geo": "global",
  "batch_id": "<provider batch id>",
  "submitted_utc": "...", "completed_utc": "...",
  "prompt_template_sha256": "...", "codebook_sha256": "...",
  "parser_version": "v1",
  "n_requests": 20000,
  "usage": {"input_tokens": 0, "cache_read_tokens": 0,
            "cache_write_tokens": 0, "output_tokens": 0},
  "cost_usd_estimated": 20.80,
  "results_sha256": "..."
}
```]

#figure(
  diagram(spacing: (6mm, 7mm),
    fknoten((1, 0), [`manifest.json` \ `run_id`, Zeitstempel], col: c-accent, filled: true, w: 34mm),
    fknoten((0, 1), [`models.yaml` \ Snapshot, API, SDK], col: c-blue, w: 30mm),
    fknoten((1, 1), [Prompt + Codebuch \ SHA-256], col: c-blue, w: 30mm),
    fknoten((2, 1), [`requirements.lock` \ GPU, vLLM-Version], col: c-blue, w: 30mm),
    fknoten((0, 2), [`requests.jsonl` \ Prompt-Hash pro Item], col: c-teal, w: 30mm),
    fknoten((1, 2), [`responses.jsonl` \ roh, SHA-256], col: c-teal, w: 30mm),
    fknoten((2, 2), [Parser v1 \ -> Labels], col: c-teal, w: 30mm),
    fknoten((1, 3), [Tabellen und Abbildungen \ im Bericht], col: c-dark, filled: true, w: 40mm),
    edge((1, 0), (0, 1), "-|>"), edge((1, 0), (1, 1), "-|>"), edge((1, 0), (2, 1), "-|>"),
    edge((1, 0), (0, 2), "-|>", bend: -40deg), edge((1, 0), (1, 2), "-|>", bend: 0deg),
    edge((1, 2), (2, 2), "-|>"), edge((2, 2), (1, 3), "-|>"), edge((1, 2), (1, 3), "-|>"),
  ),
  caption: [Provenienzgraph eines Laufs. Das Manifest verweist per Hash auf jedes Eingabeartefakt und auf die Rohausgaben; jede Zahl im Bericht lässt sich über Parser und Analysecode auf diese Rohausgaben zurückführen.],
) <k10-fig-provenienz>

Die Archivierung muss *sofort* geschehen. Batch-Ergebnisse werden bei Anthropic nach 29 Tagen, bei OpenAI 30 Tage nach Abschluss gelöscht @anthropic2026batch @openai2026batch. Wer die Ergebnisse nicht unmittelbar herunterlädt, hasht und unveränderlich ablegt, riskiert, die Grundlage seiner Studie zu verlieren. `responses.jsonl` wird danach nie editiert; Korrekturen am Parsing entstehen als neue Datei unter `data/derived/` mit eigener Parser-Version.

Für komplexere Pipelines mit Agenten, Werkzeugaufrufen oder mehrstufigen Ketten reicht ein flaches Manifest nicht mehr. Dann bieten sich Tracing-Werkzeuge an, die jeden Schritt als Span mit Eingabe, Ausgabe und Metadaten aufzeichnen; die Leitlinie llm-guidelines.org nennt das Berichten von Sitzungsverläufen (_session traces_) als eigenes Kriterium @baltes2025guidelines[Abstract]. Das Paket `mlflow-tracing` instrumentiert Code, Modelle und Agenten mit MLflow Tracing, ohne Server und Oberfläche (Stand: 11. November 2026, Version 3.18.0) @mlflow2026tracing.

=== Stufen 7 bis 10: Stabilität, Validierung, Replikation, Drift

Validierung hat in dieser Pipeline vier Teile, die du nicht verwechseln solltest.

*Validität gegen Gold.* Eine zufällige, geschichtete Goldstichprobe wird von Menschen codiert, einmal mit protokolliertem Seed gezogen, und ihre Item-IDs werden gehasht, damit sie nach Sicht der Ergebnisse nicht still verändert werden kann. Auf ihr berichtest du die Übereinstimmung zwischen LLM und Mensch (Cohens Kappa, Krippendorffs Alpha, siehe Kapitel 5), und mit ihr korrigierst du nachgelagerte Schätzungen (Kapitel 6). Baumann et al. zeigen, dass genau diese menschlichen Annotationen vor falsch-positiven Schlüssen schützen @baumann2025large[Abstract]. Die Leitlinie llm-guidelines.org führt "validate LLM outputs against human judgment" als eigenes Kriterium @baltes2025guidelines[Abstract].

*Stabilität.* $N >= 10$ Wiederholungen auf einer geschichteten Teilstichprobe mit TARa, TARr, Minimum, Median und Maximum (@k10-sec-stabilitaet).

*Replikationsarm.* Dieselbe Pipeline auf dem archivierten Open-Weight-Modell mit `VLLM_BATCH_INVARIANT=1`, GPU-Typ protokolliert @he2025defeating @vllm2026batch @cooper2026accelerating.

*Drift-Probe.* Ein festes Probe-Set, zu Beginn und am Ende der Studie gelaufen; die Differenz wird berichtet @chen2024chatgpts. Das Notebook simuliert eine stille Verhaltensänderung des Dienstes und zeigt, dass das Probe-Set sie erkennt, während der Modellname gleich bleibt.

#datei("src/verify_run.py")[```python
def verify_run(run_dir: Path) -> None:
    """Prüft, dass ein archivierter Lauf unverändert ist (vor jeder Analyse aufrufen)."""
    m = json.loads((run_dir / "manifest.json").read_text())
    actual = sha256_file(run_dir / "responses.jsonl")
    if actual != m["results_sha256"]:
        raise RuntimeError(f"{run_dir}: responses.jsonl wurde verändert")
    if m["prompt_template_sha256"] != sha256_text(load_template(m)):
        raise RuntimeError(f"{run_dir}: Prompt-Vorlage weicht vom Manifest ab")
```]

#praxis[
  Lass `verify_run()` am Anfang jedes Analyse-Notebooks laufen. Wenn eine Koautorin "nur kurz" eine Zeile in `responses.jsonl` korrigiert hat, schlägt die Prüfung fehl, bevor eine Zahl im Paper davon abhängt. Das kostet eine Sekunde und erspart dir die peinlichste Form der Nicht-Reproduzierbarkeit: die, die im eigenen Team entsteht.
]

=== Stufe 11: Reporting und Replikationspaket

Das Reporting ist Thema von @k10-sec-reporting. Für die Pipeline zählt hier nur, was ins Replikationspaket gehört: Präregistrierung, Konfiguration, Prompts und Codebuch, Rohausgaben mit Hashes, Parser, Analysecode, Lockfile, Manifest jedes Laufs, Goldlabels (soweit datenschutzrechtlich zulässig) und ein README, das erklärt, wie man die Zahlen aus den Rohausgaben neu berechnet. Das Lehrbuch erinnert daran, dass Daten in einem anerkannten Repositorium mit persistentem Identifikator abgelegt werden sollen, weil ein persönliches Laufwerk mit dem nächsten Laptop verschwindet, und dass die Daten nach den FAIR-Prinzipien auffindbar, zugänglich, interoperabel und wiederverwendbar sein sollen @haindl2027research @Wilkinson2016.

Wie realistisch ist es, dass Dritte aus einem solchen Paket tatsächlich reproduzieren? Die Messlatte ist hoch: Im Benchmark CORE-Bench mit 270 Aufgaben aus 90 Arbeiten erreichte der beste Agent auf der schwierigsten Stufe 21 % @siegel2025corebench[Abstract]. Das ist eine Baseline von 2024, Agenten sind seither besser geworden, aber die Zahl ist ein Argument für saubere Pakete: Je weniger implizites Wissen nötig ist, desto eher gelingt die Reproduktion, durch Menschen wie durch Agenten.

#hoersaal([Ist dieser Aufwand für eine Masterarbeit nicht übertrieben?], [
  Der Aufwand ist kleiner, als er aussieht, und er fällt fast vollständig am Anfang an. Das Lehrbuch formuliert die Ökonomie klar: Die Grenzkosten, einen Prompt zu protokollieren oder eine Version zu pinnen, sind zum Zeitpunkt des Experiments klein; die Kosten, dieselbe Information nach der Abschaltung des Modells wiederherzustellen, reichen von prohibitiv bis unmöglich @haindl2027research. Ein Notebook mit Cache, Manifest und Hash, wie im Foliensatz 10, ist an einem Nachmittag aufgesetzt. Und eine Masterarbeit mit LLM-Annotation, bei der ein Gutachter fragt "Mit welcher Modellversion und welchem Prompt?" und keine Antwort bekommt, ist methodisch angreifbar.
])

== Werkzeuge und Kostenmodell <k10-sec-werkzeuge>

=== Das Werkzeug-Ökosystem

Für fast jede Stufe der Referenz-Pipeline gibt es etablierte Open-Source-Werkzeuge. Keines davon ist für eine Masterarbeit zwingend; ein sauberes Python-Skript mit Cache und Manifest leistet das Wesentliche, wie das Notebook zeigt. Die Werkzeuge lohnen sich, wenn Evaluationen wiederholt, verglichen oder von mehreren Personen betrieben werden. @k10-tab-werkzeuge listet die in der Wissensbasis geprüften Versionen.

#figure(
  table(
    columns: (auto, 1fr, auto, auto),
    table.header([Werkzeug], [Zweck], [Version (Datum)], [Lizenz]),
    [Inspect AI], ["Framework for large language model evaluations" des UK AI Security Institute @ukaisi2026inspect], [0.3.289 (10.11.2026)], [MIT],
    [lm-evaluation-harness], ["A framework for evaluating language models" von EleutherAI @eleutherai2026lmeval], [0.4.13 (31.08.2026)], [MIT],
    [promptfoo], [CLI und Bibliothek zum Evaluieren und Red-Teaming von LLM-Anwendungen; Migrationsziel für die OpenAI-Evals-Plattform @openai2026deprecations], [0.125.1 (25.10.2026)], [MIT],
    [DSPy], ["The framework for programming - rather than prompting - language models" @dspy2026dspy], [3.5.0 (10.11.2026)], [MIT],
    [MLflow], [ML-Lebenszyklus-Plattform mit Tracking-Server und GenAI-Evaluation @mlflow2026mlflow], [3.18.0 (03.11.2026)], [Apache-2.0],
    [mlflow-tracing], [leichtgewichtiges Tracing ohne Server und Oberfläche @mlflow2026tracing], [3.18.0 (03.11.2026)], [Apache-2.0],
    [vLLM], [Inferenzserver mit hohem Durchsatz, batch-invarianter Modus @vllm2026vllm @vllm2026batch], [0.33.0 (02.11.2026)], [Apache-2.0],
  ),
  kind: table, supplement: [Tab.],
  caption: [Werkzeuge für reproduzierbare LLM-Workflows. Versionen laut PyPI beziehungsweise GitHub-Releases (Stand: 11. November 2026). Versionen ändern sich schnell; prüfe sie am Tag des Einsatzes und pinne sie im Lockfile.],
) <k10-tab-werkzeuge>

*Inspect* und *lm-evaluation-harness* sind Evaluationsframeworks: Sie trennen Datensatz, Prompt-Format, Modellaufruf und Bewertung und machen damit genau die Implementierungsdetails explizit, die Biderman et al. als Teil der Messung identifiziert haben @biderman2024lessons. Aus deren Erfahrungsbericht mit lm-evaluation-harness stammen auch die Empfehlungen, exakten Evaluationscode oder zumindest Prompts, Hyperparameter und Heuristiken zur Antwortextraktion zu teilen, Modellausgaben bereitzustellen (`--log_samples`), Varianz über Läufe zu berichten und Signifikanztests zu verwenden @biderman2024lessons[Sec. 3.2-3.3]. Dass schon die Mittelung über MMLU-Fächer (Mikro gegenüber Makro) Ergebnisse um "several percentage points" verschiebt @biderman2024lessons[Sec. 3.1], ist ein gutes Beispiel dafür, warum Analysecode Teil des Replikationspakets sein muss.

*promptfoo* testet Prompts und Anwendungen gegen deklarativ beschriebene Testfälle und eignet sich für Regressionstests: Wenn du das Codebuch änderst, zeigt ein promptfoo-Lauf, welche Testfälle sich verändern. OpenAI hat die Übernahme von Promptfoo am 9. März 2026 angekündigt und erklärt, das Open-Source-Projekt fortzuführen @openai2026openai. *DSPy* verfolgt einen anderen Ansatz: Prompts werden aus deklarativen Modulen kompiliert und optimiert. Für die Forschung heißt das: Der optimierte Prompt ist ein Artefakt, das du archivieren und berichten musst, nicht nur das DSPy-Programm. *MLflow* protokolliert Läufe, Parameter und Artefakte und ist ein natürlicher Ort für Manifeste, wenn mehrere Personen viele Läufe verwalten. *vLLM* ist der Inferenzserver für den Replikationsarm. Für lokale Experimente ohne GPU-Server verwendet das Notebook zum Foliensatz 10 optional Ollama über dessen OpenAI-kompatiblen Endpunkt.

#figure(
  diagram(spacing: (4mm, 6mm),
    fknoten((0, 0), [Design + \ Prompt], col: c-blue, filled: true, w: 22mm),
    fknoten((1, 0), [Pilot + \ Regression], col: c-teal, filled: true, w: 22mm),
    fknoten((2, 0), [Produktivlauf], col: c-teal, filled: true, w: 22mm),
    fknoten((3, 0), [Provenienz], col: c-accent, filled: true, w: 22mm),
    fknoten((4, 0), [Validierung], col: c-accent, filled: true, w: 22mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"), edge((3, 0), (4, 0), "-|>"),
    fknoten((0, 1), [DSPy], col: c-grey, w: 22mm),
    fknoten((1, 1), [promptfoo], col: c-grey, w: 22mm),
    fknoten((2, 1), [Batch-APIs \ vLLM], col: c-grey, w: 22mm),
    fknoten((3, 1), [MLflow, \ mlflow- \ tracing], col: c-grey, w: 22mm),
    fknoten((4, 1), [Inspect \ lm-eval], col: c-grey, w: 22mm),
    edge((0, 1), (0, 0), "-", stroke: (paint: c-grey, dash: "dashed")), edge((1, 1), (1, 0), "-", stroke: (paint: c-grey, dash: "dashed")),
    edge((2, 1), (2, 0), "-", stroke: (paint: c-grey, dash: "dashed")), edge((3, 1), (3, 0), "-", stroke: (paint: c-grey, dash: "dashed")),
    edge((4, 1), (4, 0), "-", stroke: (paint: c-grey, dash: "dashed")),
  ),
  caption: [Zuordnung der Werkzeuge zu den Pipeline-Stufen. Die Zuordnung ist eine Empfehlung für typische Annotationsstudien; mehrere Werkzeuge decken mehr als eine Stufe ab.],
) <k10-fig-werkzeuge>

#fallstrick[
  Ein Evaluationsframework ersetzt nicht das Nachdenken über das Konstrukt. Ein lm-eval-Lauf liefert eine Zahl, die exakt reproduzierbar sein kann und trotzdem das Falsche misst, wenn das Prompt-Format nicht zu dem Modell passt oder die Antwortextraktion zu streng ist @biderman2024lessons. Berichte immer Format und Extraktionsregel mit.
]

=== Batch-Verarbeitung, Prompt-Caching und Datenresidenz

Drei Mechanismen der Anbieter bestimmen Kosten und Datenschutz eines Laufs.

*Batch-APIs* nehmen viele Anfragen asynchron entgegen und berechnen 50 % des Standardpreises, bei einem Abarbeitungsfenster von 24 Stunden (OpenAI, Anthropic) @openai2026batch @anthropic2026batch; Google bepreist Gemini-Batch ebenfalls mit 50 % des Standardpreises @google2026geminipricing.

*Prompt-Caching* verwendet einen bereits verarbeiteten Präfix wieder. Anthropic berechnet Cache-Schreibvorgänge mit dem 1.25-Fachen (5 Minuten Lebensdauer) oder dem 2-Fachen (1 Stunde) des Eingabepreises und Cache-Treffer mit dem 0.1-Fachen, für Opus 5.5 und Sonnet 5.5 mit dem 0.05-Fachen; der 5-Minuten-Schreibvorgang amortisiert sich nach einem Lesevorgang, der 1-Stunden-Schreibvorgang nach zwei @anthropic2026pricing. Innerhalb von Batches sind Cache-Treffer "best effort", typischerweise zwischen 30 % und 98 % @anthropic2026batch.

*Datenresidenz* hält Verarbeitung oder Speicherung in einer Region. OpenAI bietet `eu.api.openai.com` (EWR und Schweiz, Speicherung und Verarbeitung) an, was Modified Abuse Monitoring (MAM) oder Zero Data Retention (ZDR) voraussetzt; für Modelle, die ab dem 5. März 2026 erschienen sind, kostet das 10 % Aufschlag @openai2026data. Anthropic dokumentiert einen Parameter `inference_geo` mit den Werten `"us"` und `"global"` (Standard); `"us"` kostet ab Claude 4.6 das 1.1-Fache; ein EU-Wert ist auf der Preisseite nicht gelistet (Stand: 11. November 2026) @anthropic2026pricing.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    table.header([Modell], [Eingabe], [Cache-Treffer], [Ausgabe], [Batch (Ein/Aus)]),
    [Claude Opus 5.5], [4.00], [0.20], [20.00], [2.00 / 10.00],
    [Claude Sonnet 5.5], [2.00], [0.10], [10.00], [1.00 / 5.00],
    [Claude Haiku 5.5 ($<=$ 100K Prompt)], [0.10], [0.01], [0.50], [0.05 / 0.25],
    [Gemini 3.5 Flash], [1.50], [0.15 + Speicher], [9.00], [0.75 / 4.50],
    [Gemini 3.1 Pro Preview ($<=$ 200K)], [2.00], [0.20 + Speicher], [12.00], [50 % des Standards],
  ),
  kind: table, supplement: [Tab.],
  caption: [Preise in US-Dollar pro Million Tokens (Stand: 11. November 2026) @anthropic2026pricing @google2026geminipricing. Gemini-Caching kostet zusätzlich Speicher pro Stunde (1.00 beziehungsweise 4.50 USD pro Million Tokens und Stunde). OpenAI-Modelle fehlen in der Tabelle, weil die Tarif-Tabellen auf deren Preisseite nicht beschriftet sind und die Zuordnung zu Batch-Preisen daher nur erschlossen ist @openai2026pricing.],
) <k10-tab-preise>

=== Das Kostenmodell

Aus der Preisstruktur lässt sich ein Kostenmodell für einen Annotations- oder Evaluationslauf ableiten. Die Herleitung ist elementar, aber es lohnt sich, sie einmal sauber aufzuschreiben, weil jede Variable einer Entscheidung im Studiendesign entspricht.

Jede der $N$ Anfragen besteht aus einem gemeinsamen, cachefähigen Präfix der Länge $P$ Tokens (Systemprompt, Codebuch, Few-Shot-Beispiele), einem itemspezifischen Teil von $x$ Tokens und erzeugt $y$ Ausgabetokens. Ohne Caching kostet eine Anfrage $(P + x) p_"in" + y p_"out"$ pro Million Tokens. Mit Caching wird der Präfix bei einem Treffer zum Preis $p_"hit"$ gelesen und bei einem Fehltreffer zum Preis $p_"write"$ neu geschrieben. Bei einer Trefferquote $h$ sind die erwarteten Präfixkosten pro Anfrage $P (h p_"hit" + (1 - h) p_"write")$. Batch-Faktor $d$ und Regionalfaktor $r$ wirken multiplikativ auf alles, weil Anthropic dokumentiert, dass die Rabatte kombinierbar sind @anthropic2026batch. Insgesamt:

$ C = (d dot r) / 10^6 [N (x p_"in" + y p_"out") + N P (h p_"hit" + (1 - h) p_"write")] . $ <k10-eq-kosten>

Dabei ist $d = 0.5$ für Batch-APIs und $1$ sonst, $r$ der Regionalfaktor (etwa $1.1$ für `inference_geo: "us"`), und ohne Caching zählt man $P$ zu $x$ und lässt den zweiten Term weg @anthropic2026pricing @anthropic2026batch @openai2026batch. Für Reasoning-Modelle gilt: Reasoning-Tokens werden als Ausgabetokens abgerechnet und gehören zu $y$ @openai2026reasoningmodels.

#beispiel(titel: [20 000 Texte mit Claude Sonnet 5.5])[
  Preise (Stand: 11. November 2026) @anthropic2026pricing: $p_"in" = 2$, $p_"out" = 10$, 5-Minuten-Schreiben $2.50$, 1-Stunden-Schreiben $4$, Treffer $0.10$ USD pro Million Tokens. Studie: $N = 20 thin 000$, $P = 2000$, $x = 400$, $y = 60$, $r = 1$.

  *Standard, ohne Caching:* $20 thin 000 dot (2400 dot 2 + 60 dot 10) \/ 10^6 = 20 thin 000 dot 5400 \/ 10^6 = 108.00$ USD.

  *Batch, ohne Caching:* $0.5 dot 108.00 = 54.00$ USD.

  *Batch mit 5-Minuten-Cache, $h = 0.9$:* Item-Eingabe $8 "M" dot 2 = 16$; Ausgabe $1.2 "M" dot 10 = 12$; Präfixtreffer $36 "M" dot 0.10 = 3.6$; Präfix-Fehltreffer $4 "M" dot 2.50 = 10$; Summe $41.6$, mal $d = 0.5$ ergibt $20.80$ USD.

  Die übrigen Szenarien stehen in @k10-tab-kosten. Alle Werte sind mit python3 nachgerechnet und stimmen mit dem Notebook überein.
]

#figure(
  table(
    columns: (1fr, auto),
    table.header([Szenario], [Kosten (USD)]),
    [Standard, ohne Caching], [108.00],
    [Batch, ohne Caching ($d = 0.5$)], [54.00],
    [Batch + 5-Minuten-Cache, $h = 0.9$], [20.80],
    [Batch + 1-Stunden-Cache, $h = 0.9$], [23.80],
    [Batch + 5-Minuten-Cache, $h = 0.3$], [49.60],
    [Batch + 1-Stunden-Cache, $h = 0.3$], [70.60 (teurer als Batch ohne Caching)],
  ),
  kind: table, supplement: [Tab.],
  caption: [Kosten des Rechenbeispiels unter sechs Szenarien nach @k10-eq-kosten (Preise Stand: 11. November 2026) @anthropic2026pricing @anthropic2026batch.],
) <k10-tab-kosten>

Die letzte Zeile ist die eigentliche Lehre: Caching kann teurer sein als kein Caching. Wann es sich lohnt, lässt sich exakt angeben.

#satz(titel: [Break-even-Trefferquote des Prompt-Cachings])[
  Gegenüber Batch ohne Caching ist Batch mit Caching genau dann günstiger, wenn
  $ h > h^* = (p_"write" - p_"in") / (p_"write" - p_"hit") . $ <k10-eq-breakeven>
  Die Schwelle hängt weder von $N$, $P$, $x$, $y$ noch von $d$ und $r$ ab.
]

#beweis[
  Ohne Caching kostet der Präfix pro Anfrage $P p_"in"$, mit Caching $P (h p_"hit" + (1 - h) p_"write")$; alle anderen Terme von @k10-eq-kosten sind in beiden Fällen identisch und kürzen sich, ebenso der gemeinsame Faktor $d r N P \/ 10^6 > 0$. Caching ist also genau dann günstiger, wenn $h p_"hit" + (1 - h) p_"write" < p_"in"$, das heißt $p_"write" - p_"in" < h (p_"write" - p_"hit")$. Weil $p_"write" > p_"hit"$, darf man durch $(p_"write" - p_"hit")$ teilen und erhält @k10-eq-breakeven.
]

Für Sonnet 5.5 ergibt sich beim 5-Minuten-Cache $h^* = (2.50 - 2) \/ (2.50 - 0.10) = 0.5 \/ 2.4 approx 0.208$, beim 1-Stunden-Cache $h^* = (4 - 2) \/ (4 - 0.10) = 2 \/ 3.9 approx 0.513$. Mit dem 1-Stunden-Cache brauchst du also mehr als die Hälfte Treffer, damit er sich lohnt. Da Trefferquoten in Batches nur "best effort" zwischen 30 % und 98 % liegen @anthropic2026batch, ist der 1-Stunden-Cache in Batches ein echtes Risiko. @k10-fig-kosten zeigt die Kosten als Funktion von $h$.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let sx = 9.0
    let sy = 0.05
    let c5(h) = 0.5 * (16 + 12 + 40 * (h * 0.1 + (1 - h) * 2.5))
    let c1(h) = 0.5 * (16 + 12 + 40 * (h * 0.1 + (1 - h) * 4.0))
    line((0, 0), (sx + 0.3, 0), stroke: 0.7pt, mark: (end: "stealth", fill: black, scale: 0.5))
    line((0, 0), (0, 100 * sy + 0.3), stroke: 0.7pt, mark: (end: "stealth", fill: black, scale: 0.5))
    for v in (0, 20, 40, 60, 80, 100) {
      line((0, v * sy), (-0.08, v * sy), stroke: 0.5pt)
      line((0, v * sy), (sx, v * sy), stroke: (paint: luma(228), thickness: 0.4pt))
      content((-0.15, v * sy), anchor: "east", text(font: "Inter", size: 7pt, str(v)))
    }
    for h in (0, 0.2, 0.4, 0.6, 0.8, 1.0) {
      line((h * sx, 0), (h * sx, -0.08), stroke: 0.5pt)
      content((h * sx, -0.32), text(font: "Inter", size: 7pt, dez(h)))
    }
    content((sx / 2, -0.75), text(font: "Inter", size: 7.5pt)[Cache-Trefferquote $h$])
    content((-1.0, 50 * sy), angle: 90deg, text(font: "Inter", size: 7.5pt)[Kosten in USD])
    // Batch ohne Caching
    line((0, 54 * sy), (sx, 54 * sy), stroke: (paint: c-grey, thickness: 1.2pt, dash: "dashed"))
    content((sx + 0.1, 54 * sy), anchor: "west", text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[Batch ohne Cache: 54])
    line((0, c5(0) * sy), (sx, c5(1) * sy), stroke: (paint: c-blue, thickness: 1.3pt))
    line((0, c1(0) * sy), (sx, c1(1) * sy), stroke: (paint: c-accent, thickness: 1.3pt))
    content((sx + 0.1, c5(1) * sy + 0.15), anchor: "west", text(font: "Inter", size: 7pt, fill: c-dark)[beide: 16 bei $h = 1$])
    content((0.15, c5(0) * sy + 0.05), anchor: "south-west", text(font: "Inter", size: 7pt, fill: c-blue, weight: "bold")[5-Min-Cache: 64])
    content((0.15, c1(0) * sy + 0.05), anchor: "south-west", text(font: "Inter", size: 7pt, fill: c-accent, weight: "bold")[1-h-Cache: 94])
    for (hb, col) in ((0.5 / 2.4, c-blue), (2 / 3.9, c-accent)) {
      circle((hb * sx, 54 * sy), radius: 0.07, fill: col, stroke: none)
      line((hb * sx, 54 * sy), (hb * sx, 0), stroke: (paint: col, thickness: 0.6pt, dash: "dotted"))
      content((hb * sx + 0.06, 0.12), anchor: "south-west", text(font: "Inter", size: 6.8pt, fill: col)[$h^*$ = #dez(calc.round(hb, digits: 3))])
    }
  }),
  caption: [Kosten des Rechenbeispiels (Batch, Sonnet 5.5) in Abhängigkeit von der Cache-Trefferquote. Die Kurven schneiden die Linie "Batch ohne Cache" bei den Break-even-Werten aus @k10-eq-breakeven: $h^* approx 0.208$ (5 Minuten) und $h^* approx 0.513$ (1 Stunde).],
) <k10-fig-kosten>

#beispiel(titel: [Reasoning-Tokens und Stabilitätsläufe])[
  *Reasoning:* Angenommen, ein Reasoning-Modell zum selben Preis erzeugt pro Item zusätzlich 500 Reasoning-Tokens, also $y = 560$ statt $60$. Standardpreis: $20 thin 000 dot (2400 dot 2 + 560 dot 10) \/ 10^6 = 20 thin 000 dot 10 thin 400 \/ 10^6 = 208.00$ USD, fast doppelt so viel wie die 108.00 USD ohne Reasoning. Mit Batch und 5-Minuten-Cache bei $h = 0.9$: $70.80$ statt $20.80$ USD. Die Ausgabe dominiert dann die Kosten, und Caching auf der Eingabeseite hilft wenig.

  *Stabilität:* Die Stabilitätsanalyse mit $N = 10$ Läufen auf einer Teilstichprobe von 500 Items entspricht 5000 Anfragen. Mit Batch und 5-Minuten-Cache bei $h = 0.9$ kostet das $20.80 dot 5000 \/ 20 thin 000 = 5.20$ USD. Stabilität zu messen ist im Vergleich zum Produktivlauf billig; es gibt keinen Kostengrund, darauf zu verzichten.

  *Region:* Mit $r = 1.1$ (`inference_geo: "us"`) wird aus 20.80 USD der Betrag $22.88$ USD.
]

Das Kostenmodell gehört in die Präregistrierung und ins Manifest (`cost_usd_estimated`), und die tatsächlichen Tokenzahlen aus den Antworten (`usage`) gehören daneben. Die Abweichung zwischen Schätzung und Ist ist eine nützliche Kontrollgröße: Ist sie groß, stimmt entweder die Trefferquote nicht oder die Ausgaben sind länger als im Pilot, was wiederum auf ein Parser- oder Prompt-Problem hindeuten kann.

#hoersaal([Lohnt sich ein kleines Modell nicht immer mehr als Caching?], [
  Oft ja, wenn es die Aufgabe valide löst. Mit Haiku 5.5 zu 0.10 und 0.50 USD pro Million Tokens kostet das Rechenbeispiel im Standardtarif 5.40 USD statt 108.00 USD und im Batch 2.70 USD (eigene Rechnung nach @k10-eq-kosten mit den Preisen aus @k10-tab-preise). Aber Kosten sind nicht das Kriterium, Validität ist es: Baumann et al. fanden mit kleineren Modellen bei etwa der Hälfte der Hypothesen falsche Schlüsse, mit State-of-the-Art-Modellen bei etwa 31 % @baumann2025large[Abstract]. Die Entscheidung fällt auf der Goldstichprobe, nicht auf der Preisliste. Und das Lehrbuch erinnert an eine zweite Dimension: Rechnen hat einen ökologischen Fußabdruck, und man sollte das am wenigsten aufwendige Experiment wählen, das die Frage beantwortet @haindl2027research @Strubell2019.
])

== LLM-gestützte Literaturreviews <k10-sec-reviews>

Literaturreviews sind der Ort, an dem LLMs am schnellsten in die Forschungspraxis eingedrungen sind, und gleichzeitig der Ort, an dem ihre Fehler am direktesten in die wissenschaftliche Literatur durchschlagen. Dieser Abschnitt verbindet das Kapitel 5 des Lehrbuchs mit der aktuellen Evidenz.

=== Der Review-Prozess und wo LLMs eingreifen

Ein systematischer Review identifiziert, analysiert und interpretiert mit einer wohldefinierten Methodik alle verfügbare Evidenz zu einer spezifischen Forschungsfrage, unverzerrt und wiederholbar @Kitchenham2007 @Budgen2018. Das Lehrbuch nennt die tragenden Elemente: ein Protokoll vor Beginn der Suche, das Forschungsfragen, Suchstrategie, Ein- und Ausschlusskriterien und Analysemethoden festlegt; eine umfassende Suche über mehrere Datenbanken mit sorgfältig konstruierten Suchstrings, ergänzt um Handsuche und Snowballing @Wohlin2014; eine Qualitätsbewertung jeder eingeschlossenen Studie; und transparentes Reporting nach PRISMA @Page2021, bei Mapping-Studien nach PRISMA-ScR @Tricco2018 @haindl2027research. Die Suchstrategie muss Sensitivität (alle relevanten Studien finden) gegen Spezifität (wenig Irrelevantes) abwägen @haindl2027research.

#figure(
  diagram(spacing: (5mm, 5mm),
    fknoten((0, 0), [Forschungsfrage \ + Protokoll], col: c-blue, w: 24mm),
    fknoten((1, 0), [Keywords + \ Datenbanken], col: c-blue, w: 24mm),
    fknoten((2, 0), [Suchstrings \ ausführen], col: c-blue, w: 24mm),
    fknoten((3, 0), [Screening \ Titel/Abstract], col: c-blue, w: 24mm),
    fknoten((4, 0), [Volltext + \ Extraktion], col: c-blue, w: 24mm),
    fknoten((5, 0), [Synthese + \ Schreiben], col: c-blue, w: 24mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"), edge((3, 0), (4, 0), "-|>"), edge((4, 0), (5, 0), "-|>"),
    fknoten((1, 1), [Synonyme \ vorschlagen], col: c-green, w: 24mm),
    fknoten((3, 1), [Zweitscreener \ Sensitivität messen], col: c-yellow, w: 24mm),
    fknoten((4, 1), [Extraktion \ Test-Retest], col: c-yellow, w: 24mm),
    fknoten((5, 1), [Referenzen \ erzeugen], col: c-red, w: 24mm),
    edge((1, 1), (1, 0), "-", stroke: (paint: c-green, dash: "dashed")), edge((3, 1), (3, 0), "-", stroke: (paint: c-yellow, dash: "dashed")),
    edge((4, 1), (4, 0), "-", stroke: (paint: c-yellow, dash: "dashed")), edge((5, 1), (5, 0), "-", stroke: (paint: c-red, dash: "dashed")),
  ),
  caption: [Suchprozess nach dem Lehrbuch @haindl2027research (oben) und Eingriffspunkte von LLMs (unten). Grün: geringes Risiko, Ergebnis wird von Menschen geprüft. Gelb: nur mit gemessener Fehlerrate. Rot: ohne automatische und manuelle Verifikation nicht vertretbar.],
) <k10-fig-review>

Das Lehrbuch erwähnt bereits "emerging approaches": maschinell unterstütztes Screening, das potenziell relevante Arbeiten priorisiert, lebende Reviews mit automatischen Benachrichtigungen und Crowdsourcing @haindl2027research. Es ergänzt für die Informatik zwei Anpassungen, die für LLM-gestützte Reviews doppelt gelten. Erstens *Versionssensitivität*: Nicht nur die Werkzeuge, sondern auch ihre Versionen sind zu nennen, und es ist anzumerken, wann Befunde versionsabhängig sein könnten @haindl2027research @Ampatzoglou2019. Das betrifft hier zweierlei, die reviewten Arbeiten und das LLM, das beim Review hilft. Zweitens die Rolle der *grauen Literatur* und von Preprints, deren vorläufigen Charakter man anerkennen muss @haindl2027research @Garousi2016. Ein großer Teil der Evidenz zu LLM-gestützten Reviews sind selbst Preprints.

=== Die Evidenz zu Screening und Extraktion

Die Scoping-Review von Lieberum et al. bildet den Stand bis Februar 2024 ab: 196 eingeschlossene Berichte, davon 37 zu LLMs; LLMs wurden in 10 von 13 Schritten systematischer Reviews eingesetzt, am häufigsten bei der Literatursuche (41 %), Studienauswahl (38 %) und Datenextraktion (30 %); GPT in 89 % der LLM-Studien; die Autorinnen bewerteten den Einsatz in 54 % als vielversprechend, in 24 % als neutral und in 22 % als nicht vielversprechend @lieberum2024large. Ihre Schlussfolgerung: "LLMs should currently be used with caution and limited to specific SR tasks under human supervision" @lieberum2024large. Khraisha et al. fanden in einer präregistrierten Studie mit GPT-4 für die Datenextraktion "a moderate level of performance" nach Zufallskorrektur und für das Screening "none to moderate" über Stufen und Sprachen hinweg, außer mit hochreliablen Prompts, bei denen das Volltext-Screening "almost perfect" war @khraisha2024can[Abstract]. Gartlehner et al. berichteten für die Extraktion mit Claude 2 96.3 % Genauigkeit über 160 Datenelemente aus 10 RCT-Publikationen, mit Test-Retest-Werten von 96.9 % und 95.0 %; von sechs Fehlern waren vier ausgelassene Elemente @gartlehner2024data[Abstract].

Seit 2025 gibt es Ende-zu-Ende-Systeme mit deutlich stärkeren Behauptungen, und unabhängige Studien, die nüchterner ausfallen.

#studie(titel: [Cao et al. 2025: otto-SR])[
  *Design:* Agentischer Workflow mit GPT-4.1 (Screening), o3-mini-high (Extraktion), GPT-5 (Risk of Bias) und Gemini 2.0 Flash (PDF zu Markdown); vier Phasen, darunter die Reproduktion und Aktualisierung von 12 Cochrane-Reviews mit 146 276 Zitationen @cao2025automation.
  *Befund:* Laut Abstract Screening-Sensitivität 96.7 % und Spezifität 97.9 % gegenüber 81.7 % und 98.1 % für menschliche Reviewer @cao2025automation[Abstract]; im Ergebnisteil für das Abstract-Screening 96.6 %/93.9 % gegenüber 87.3 %/95.7 % für doppeltes menschliches Screening. Extraktionsgenauigkeit 93.1 % gegenüber 79.7 % für doppelte menschliche Extraktion. In der Cochrane-Reproduktion wurden alle 64 eingeschlossenen Studien gefunden und 54 zusätzliche geeignete Studien identifiziert; in 3 Reviews änderten sich die Schlussfolgerungen @cao2025automation.
  *Grenzen:* Preprint; Abstract und Ergebnisteil berichten unterschiedliche Screening-Werte, die Zahl der Datenpunkte ist inkonsistent (4495 gegenüber 4459), die menschliche Vergleichsgruppe ist in einem Review ungewöhnlich schwach; Daten werden "on publication" versprochen @cao2025automation.
]

#studie(titel: [Dai et al. 2025])[
  *Design:* Prospektive Studie zur diagnostischen Genauigkeit: sechs publizierte Metaanalysen der Thoraxchirurgie als Themen; Screening mit ChatGPT-4o und Claude-3.5 Sonnet, Gemini-1.5 Pro als Schiedsrichter; Vergleich mit ASReview und Abstrackr; doppeltes menschliches Screening als Referenz @dai2025accuracy.
  *Befund:* Volltext-Screening Sensitivität 0.87 (95-%-KI 0.77-0.99), Spezifität 0.96; Titel/Abstract Sensitivität 0.73 (0.57-0.85), Spezifität 0.99; mit post hoc revidierten Prompts 0.98/0.98; ASReview 0.58, Abstrackr 0.48 Sensitivität @dai2025accuracy.
  *Grenzen:* Ein klinisches Gebiet; die revidierten Prompts sind post hoc, und eine Studie galt als eingeschlossen, wenn irgendeine von drei LLM-Iterationen sie einschloss @dai2025accuracy.
]

#figure(
  balken-de((
    ([LLM Volltext], 0.87),
    ([LLM Titel/Abstract], 0.73),
    ([LLM revidiert (post hoc)], 0.98),
    ([ASReview], 0.58),
    ([Abstrackr], 0.48),
  ), max: 1, breite: 8, farbe: c-teal, nachkomma: 2),
  caption: [Sensitivität des Screenings bei Dai et al. Die revidierten Prompts wurden nach Sicht der Ergebnisse angepasst und sind daher nicht als konfirmatorischer Befund zu lesen @dai2025accuracy.],
) <k10-fig-screening>

#studie(titel: [Figalova et al. 2026])[
  *Design:* Präregistriert, eingebettet in eine Scoping-Review: 1131 Datensätze, gescreent von einer Einzelperson, einem Viererteam und in sieben LLM-Läufen über Weboberflächen (ChatGPT 5.4 Thinking, Gemini 3 Thinking, Gemini 3.1 Pro) @figalova2026evaluating.
  *Befund:* Menschen und GPT-5.4 mit Dateibatches behielten 42.2-45.0 % der Datensätze und fanden 82.3-82.9 % der 316 verifizierten geeigneten Datensätze; GPT-5.4 "alle auf einmal" behielt 34.6 % und fand nur 66.8 %. Zwei nominell identische GPT-5.4-Läufe stimmten bei 1037 von 1131 Datensätzen überein (91.7 %) und widersprachen sich bei 29 der 316 geeigneten @figalova2026evaluating[Table 3].
  *Grenzen:* Recall nur operational (nur weitergeleitete Datensätze verifiziert); Weboberflächen statt APIs; Preprint.
]

Die Studie von Figalova et al. verbindet die beiden Hälften dieses Kapitels: Run-to-Run-Instabilität betrifft nicht nur Benchmarks, sondern Screening-Entscheidungen, und eine Designentscheidung wie die Zahl der Datensätze pro Prompt verändert den Recall. Beides gehört ins Review-Protokoll.

#beispiel(titel: [Was eine Sensitivität von 0.73 bedeutet])[
  Ein Review hat 2000 Datensätze nach der Deduplizierung, davon 100 tatsächlich relevant (5 %). Ein LLM screent Titel und Abstracts mit den Werten von Dai et al., Sensitivität 0.73 und Spezifität 0.99 @dai2025accuracy.
  - Gefundene relevante: $0.73 dot 100 = 73$; *übersehene relevante: 27*.
  - Fälschlich weitergeleitete: $0.01 dot 1900 = 19$.
  - Weitergeleitet insgesamt: $73 + 19 = 92$ Datensätze, also 4.6 % des Bestands.
  Die Arbeitsersparnis ist enorm, aber 27 % der Evidenz fehlen, und zwar nicht zufällig, sondern dort, wo das Modell systematisch anders urteilt. Setzt man das LLM stattdessen als *zweiten* Screener neben eine menschliche Person ein und schließt ein, was einer der beiden einschließt, so ist die kombinierte Sensitivität bei unabhängigen Fehlern $1 - (1 - s_1)(1 - s_2)$. Mit $s_1 = 0.873$ (doppeltes menschliches Abstract-Screening bei otto-SR @cao2025automation) und $s_2 = 0.73$ ergibt sich $1 - 0.127 dot 0.27 approx 0.966$. Unabhängigkeit der Fehler ist eine optimistische Annahme; schwierige Datensätze sind für beide schwierig. Die Werte aus zwei verschiedenen Studien zu kombinieren dient nur der Illustration.
]

#merke[
  Kursposition (Synthese aus den zitierten Studien): Das LLM ist ein *zweiter Screener mit gemessener Sensitivität* auf einer Goldteilmenge, nie alleiniger Screener. Prompt, Modell, Batching-Strategie und die Regel für die Kombination der Urteile werden im Review-Protokoll präregistriert. Test-Retest-Werte gehören in den Bericht, auch für die Extraktion @gartlehner2024data @figalova2026evaluating.
]

=== Zitationshalluzinationen

Das schwerwiegendste Risiko beim Schreiben ist die erfundene Quelle. Das Lehrbuch ist hier eindeutig: Eine erfundene Zitation wird nicht dadurch entschuldbar, dass ein Modell sie erzeugt hat; die Pflicht zur Verifikation liegt bei der Person, die sich auf das Werkzeug verlassen hat @haindl2027research.

#studie(titel: [Walters und Wilder 2023])[
  *Design:* 84 kurze Literaturreviews (42 von GPT-3.5, 42 von GPT-4) mit 636 Zitationen @walters2023fabrication.
  *Befund:* Etwa 55 % der GPT-3.5- und 18 % der GPT-4-Zitationen waren erfunden; von den echten Zitationen hatten 43 % beziehungsweise 24 % substanzielle Fehler, meist numerisch (Band, Seiten, Datumsangaben); Buchkapitel wurden am häufigsten erfunden, selbst bei GPT-4 zu etwa 70 % @walters2023fabrication.
  *Grenzen:* Chatmodelle von 2023 ohne Retrieval.
]

#studie(titel: [Rao, Wong und Callison-Burch 2026])[
  *Design:* 10 Modelle und Agenten auf DRBench (53 090 Zitations-URLs) und 3 Modelle auf ExpertQA (168 021 URLs, 32 Fachgebiete); Klassifikation der URLs als erreichbar, veraltet (Link-Rot) oder halluziniert mithilfe der Wayback Machine @rao2026detecting.
  *Befund:* 3-13 % der Zitations-URLs halluziniert, 5-18 % nicht auflösbar; Deep-Research-Agenten zitieren mehr, halluzinieren URLs aber häufiger als suchgestützte LLMs; Selbstkorrektur mit dem veröffentlichten Werkzeug `urlhealth` reduzierte nicht auflösbare URLs um den Faktor 6 bis 79 auf unter 1 % @rao2026detecting[Abstract].
  *Grenzen:* Existenz einer URL sagt nichts über die inhaltliche Korrektheit der Zitation; Preprint.
]

Automatische Verifikation hilft, ersetzt aber nicht das Öffnen der Quelle. Der Benchmark CiteAudit umfasst 3586 echte und 2500 erzeugte gefälschte Referenzen sowie einen Realdatensatz mit 2889 echten und 467 gefälschten; ein Multi-Agenten-Prüfer erreichte dort eine Genauigkeit von 0.949 und einen F1-Wert von 0.838, das zweitbeste System (Gemini-3-Pro) einen F1-Wert von 0.571 @shi2026citeaudit[Sec. 3, Table 1; Sec. 5.3, Table 4].

#figure(
  balken-de((
    ([GPT-3.5 (2023), erfunden], 55),
    ([GPT-4 (2023), erfunden], 18),
    ([Agenten (2026), URL halluz., max.], 13),
    ([Agenten (2026), URL halluz., min.], 3),
  ), max: 60, breite: 7.5, farbe: c-red, einheit: " %", nachkomma: 0),
  caption: [Anteil erfundener Zitationen 2023 @walters2023fabrication und halluzinierter Zitations-URLs 2026 (Spanne über Systeme) @rao2026detecting. Die Maße sind nicht identisch: 2023 wurde die Existenz der Publikation geprüft, 2026 die Existenz der URL. Der Trend ist kleiner, aber nicht null.],
) <k10-fig-zitate>

#beispiel(titel: [Wie viele falsche Quellen enthält eine Liste?])[
  Ein Werkzeug liefert 40 Referenzen. Bei einer Halluzinationsrate von 3 % pro Referenz und Unabhängigkeit erwartest du $40 dot 0.03 = 1.2$ falsche Einträge; die Wahrscheinlichkeit, dass *mindestens einer* falsch ist, beträgt $1 - 0.97^40 approx 0.704$. Bei 13 % sind es erwartet $5.2$ Einträge, und mindestens einer ist mit Wahrscheinlichkeit $1 - 0.87^40 approx 0.996$ falsch. Bei der GPT-4-Rate von 2023 (18 %) wären es $7.2$. Selbst am unteren Ende der Spanne von 2026 enthält eine typische Liste also wahrscheinlich mindestens einen Fehler.
]

#datei("src/verify_refs.py")[```python
import json, urllib.request, urllib.parse

def doi_metadata(doi: str) -> dict | None:
    """Fragt die Crossref-Metadaten zu einer DOI ab; None, wenn sie nicht existiert."""
    url = "https://api.crossref.org/works/" + urllib.parse.quote(doi)
    try:
        with urllib.request.urlopen(url, timeout=20) as r:
            return json.load(r)["message"]
    except Exception:
        return None

def check(ref: dict) -> str:
    meta = doi_metadata(ref["doi"]) if ref.get("doi") else None
    if meta is None:
        return "DOI fehlt oder löst nicht auf -> manuell prüfen"
    title = (meta.get("title") or [""])[0].lower()
    if ref["title"].lower()[:40] not in title:
        return "Titel weicht ab -> manuell prüfen"
    return "Metadaten stimmen -> Quelle trotzdem öffnen und Aussage prüfen"
```]

Das Skript klassifiziert, es verifiziert nicht. Die letzte Zeile ist ernst gemeint: Eine existierende DOI mit passendem Titel schließt nicht aus, dass die zitierte Aussage nicht in der Quelle steht. Die Wissensbasis, auf der dieses Buch beruht, folgt deshalb der Regel, dass jede Referenz geöffnet wird.

#hoersaal([otto-SR war besser als doppeltes menschliches Screening. Warum sollten wir LLMs dann nicht allein screenen lassen?], [
  Weil die stärkste Evidenz die schwächste methodische Absicherung hat. otto-SR ist ein Preprint mit Widersprüchen zwischen Abstract und Ergebnisteil und einer in einem Review ungewöhnlich schwachen menschlichen Vergleichsgruppe @cao2025automation. Unabhängige Studien finden auf Titel/Abstract-Ebene eine Sensitivität von 0.73 @dai2025accuracy, und zwei identische Läufe widersprechen sich bei 29 von 316 relevanten Datensätzen @figalova2026evaluating. Die EC-Leitlinien halten Forschende ausdrücklich für verantwortlich und verlangen Verifikation @europeancommission2026living. Die richtige Antwort ist also nicht "nie", sondern "messen": Wenn du auf einer Goldteilmenge deines eigenen Reviews eine Sensitivität nachweist, die deinem Anspruch genügt, kannst du das begründet berichten.
])

== Reporting-Leitlinien <k10-sec-reporting>

Innerhalb von 18 Monaten sind drei unabhängige Leitlinien für LLM-gestützte Forschung erschienen, dazu ein Statement für Chatbot-Studien in der Medizin @gallifant2025tripodllm @baltes2025guidelines @feuerriegel2026reporting @huo2025reporting. Sie ergänzen, was das Lehrbuch über den Methodenteil sagt: Er muss genug Detail liefern, damit eine andere Forscherin die Studie exakt wiederholen kann, in der Informatik einschließlich Zugang zu Code, Daten und experimentellen Konfigurationen @haindl2027research @Collberg2016. Das Lehrbuch nennt das Problem beim Namen: Zu schreiben, eine Studie habe "GPT verwendet", ist so, als würde man schreiben, ein Experiment habe "einen Computer verwendet" @haindl2027research.

=== llm-guidelines.org

Die Leitlinien von Baltes et al. für empirische Software-Engineering-Studien mit LLMs (22 Autorinnen und Autoren, lebende Fassung auf llm-guidelines.org, Preprint in Version 8 vom 18. September 2026) unterscheiden sieben Studientypen: LLMs als Annotatoren, als Richter, zur Synthese und als Subjekte; Untersuchung der LLM-Nutzung im Software Engineering; LLMs für neue Werkzeuge; Benchmarking von LLMs für SE-Aufgaben @baltes2025guidelines[Sec. 4]. Dazu kommen acht Leitlinien mit Muss- und Soll-Kriterien: LLM-Nutzung und Rolle deklarieren; Modellversionen, Konfigurationen und Anpassungen berichten; System- und Prompt-Design dokumentieren; Sitzungsverläufe berichten; geeignete Baselines, Benchmarks und Metriken verwenden; ein offenes LLM als Baseline einbeziehen; LLM-Ausgaben gegen menschliches Urteil validieren; Grenzen und Gegenmaßnahmen benennen @baltes2025guidelines[Abstract].

Die Unterscheidung zwischen "must" und "should" ist genau zu lesen, und die Verifikation der Wissensbasis hat hier mehrere Fehlzitate korrigiert. Ein Muss-Kriterium ist: "Researchers must document in the paper which model or tool version they used in their study, along with the date of study execution" @baltes2025guidelines[Sec. 5.2.2]. Ebenso: "Researchers must report all prompts used in an empirical study, including instructions, task context, input data, and output indicators" @baltes2025guidelines[Sec. 5.3.2]. Soll-Kriterien sind dagegen: "If comparing models or tools, researchers should use appropriate inferential statistics" @baltes2025guidelines[Sec. 5.5], "an open LLM should be one of the models under evaluation" @baltes2025guidelines[Sec. 5.6] und "Due to the inherent non-determinism of LLMs, experiments should be repeated; the result distribution should then be reported using descriptive statistics" @baltes2025guidelines[Sec. 5.5]. Weil die Leitlinie lebt, musst du die Version zitieren, nach der du dich richtest.

=== TRIPOD-LLM, GUIDE-LLM, REFORMS und CHART

*TRIPOD-LLM* erweitert TRIPOD+AI für biomedizinische Studien mit LLMs: 19 Hauptitems und 50 Unteritems, modular aufgebaut, wobei 14 Hauptitems und 32 Unteritems für alle Studientypen gelten; entwickelt in einem beschleunigten Delphi-Verfahren, als lebendes Dokument mit einer interaktiven Website, die ein Einreichungs-PDF erzeugt @gallifant2025tripodllm[Abstract].

*GUIDE-LLM* ist die konsensbasierte Checkliste für die Verhaltens- und Sozialwissenschaften, publiziert 2026 in Nature Human Behaviour @feuerriegel2026reporting. Sie hat 14 Items in sieben Gruppen: Umfang der LLM-Nutzung (2), Modell- und Systemdetails (5), Prompts (2), Dateneingaben und Datenschutz (1), Validierung und Interpretation (2), Reproduzierbarkeit (1) und Interessenkonflikte (1); entwickelt in einer präregistrierten, zweistufigen reaktiven Delphi-Studie mit 68 von 105 eingeladenen Expertinnen und Experten in Runde 1 und 80 Antworten in Runde 2, wobei Items mit mehr als zwei Dritteln "include"-Stimmen beibehalten wurden @feuerriegel2026reporting. Die Checkliste ist online verfügbar @mcml2026research.

*REFORMS* ist keine LLM-spezifische, sondern eine allgemeine Checkliste für ML-basierte Wissenschaft: 32 Items in acht Abschnitten (Studiendesign, computationale Reproduzierbarkeit, Datenqualität, Datenvorverarbeitung, Modellierung, Data Leakage, Metriken und Unsicherheitsquantifizierung, Generalisierbarkeit) von 19 Autorinnen und Autoren aus Informatik, Mathematik, Sozial- und Gesundheitsforschung @kapoor2024reforms. Sie bildet die allgemeine Reproduzierbarkeitsschicht unter den LLM-spezifischen Leitlinien.

*CHART* richtet sich an "studies evaluating the performance of generative artificial intelligence (AI)-driven chatbots" für Gesundheitsauskünfte @equator2025reporting. "CHART includes 12 items and 39 subitems"; entwickelt in einem modifizierten asynchronen Delphi-Verfahren mit 531 Stakeholdern und drei synchronen Konsenssitzungen mit 48 Stakeholdern @huo2025reporting[Abstract].

#figure(
  table(
    columns: (auto, auto, 1fr, auto),
    table.header([Leitlinie], [Feld], [Umfang], [Status]),
    [llm-guidelines.org @baltes2025guidelines], [Software Engineering], [7 Studientypen, 8 Leitlinien mit Muss-/Soll-Kriterien], [Preprint, lebend (v8, 18.09.2026)],
    [TRIPOD-LLM @gallifant2025tripodllm], [Biomedizin], [19 Items, 50 Unteritems (14/32 für alle Studien)], [Nature Medicine 2025, lebend],
    [GUIDE-LLM @feuerriegel2026reporting], [Verhaltens-/Sozialwiss.], [14 Items in 7 Gruppen], [Nature Human Behaviour 2026],
    [REFORMS @kapoor2024reforms], [ML-basierte Wissenschaft], [32 Items in 8 Abschnitten], [Science Advances 2024],
    [CHART @huo2025reporting], [Chatbot-Gesundheitsauskünfte], [12 Items, 39 Unteritems], [BMC Medicine u. a. 2025],
  ),
  kind: table, supplement: [Tab.],
  caption: [Reporting-Leitlinien für LLM-gestützte und ML-basierte Forschung im Vergleich (Stand: 11. November 2026).],
) <k10-tab-leitlinien>

=== Der gemeinsame Kern und ein Abschnitt "LLM-Nutzung und Stabilität"

Über alle Leitlinien hinweg zeigt sich ein gemeinsamer Kern (Synthese der Wissensbasis): Rolle des LLM deklarieren; exakte Modellversion, Konfiguration und Datum berichten; Prompts veröffentlichen; gegen Menschen validieren; Reproduzierbarkeit und Nichtdeterminismus adressieren @baltes2025guidelines @gallifant2025tripodllm @mcml2026research. llm-guidelines.org ist dabei am explizitesten bei Wiederholungen und beim Open-LLM-Baseline @baltes2025guidelines[Sec. 5.5-5.6]. Dazu kommt eine Beobachtung, die das Kapitel motiviert hat: Reporting-Leitlinien gehen viel weiter als Verlagsrichtlinien. Wenn beide verschieden viel verlangen, folgst du der strengeren.

#figure(
  diagram(spacing: (6mm, 6mm),
    fknoten((1, 0), [Gemeinsamer Kern], col: c-accent, filled: true, w: 34mm),
    fknoten((0, 1), [Rolle des LLM \ deklarieren], col: c-blue, w: 28mm),
    fknoten((1, 1), [Version, Konfiguration, \ Datum], col: c-blue, w: 32mm),
    fknoten((2, 1), [alle Prompts \ veröffentlichen], col: c-blue, w: 28mm),
    fknoten((0, 2), [gegen Menschen \ validieren], col: c-blue, w: 28mm),
    fknoten((1, 2), [Nichtdeterminismus \ adressieren], col: c-blue, w: 32mm),
    fknoten((2, 2), [Grenzen \ benennen], col: c-blue, w: 28mm),
    edge((1, 0), (0, 1), "-|>"), edge((1, 0), (1, 1), "-|>"), edge((1, 0), (2, 1), "-|>"),
    edge((1, 0), (0, 2), "-|>", bend: -25deg), edge((1, 0), (2, 2), "-|>", bend: 25deg),
    edge((1, 1), (1, 2), "-|>"),
  ),
  caption: [Gemeinsamer Kern der LLM-Reporting-Leitlinien (Synthese) @baltes2025guidelines @gallifant2025tripodllm @feuerriegel2026reporting.],
) <k10-fig-kern>

Für die Praxis empfiehlt sich ein eigener Unterabschnitt im Methodenteil, etwa "LLM-Nutzung und Stabilität", mit folgendem Inhalt: Rolle des LLM in der Studie und Studientyp nach llm-guidelines.org; Anbieter, exakter Snapshot, API-Version, SDK-Version, Datum der Durchführung; tatsächlich gesendete Parameter und, wo ein Parameter nicht gesendet wurde, der Hinweis "Standard des Anbieters"; Prompt-Vorlage und Codebuch im Anhang oder Repositorium mit Hash; Parser und Version; Zahl der Wiederholungen mit Begründung; TARa\@N, TARr\@N, Minimum, Median und Maximum der Zielmetrik; Übereinstimmung mit Gold; Ergebnisse des Replikationsarms und der Drift-Probe; Kosten; Begründung für ein proprietäres Modell nach Palmer et al. @palmer2024using; und der Verweis auf das Replikationspaket mit persistentem Identifikator. Das Lehrbuch erinnert daran, dass ein solcher Methodenteil nicht nur beschreibt, was du getan hast, sondern begründet, warum @haindl2027research.

#tipp[
  Nimm für deine Abschlussarbeit eine aktuelle LLM-Studie aus deinem Feld und prüfe sie gegen die acht Leitlinien von llm-guidelines.org und die 14 Items von GUIDE-LLM. Berechne den Anteil der erfüllten Muss-Kriterien. Diese Übung aus der Wissensbasis schärft den Blick für die eigenen Lücken schneller als jede Checkliste, die man nur abhakt.
]

== Ethik, Policy und Recht <k10-sec-ethik>

=== Offenlegen, nicht als Autor nennen, verifizieren

Kapitel 10 des Lehrbuchs fasst die Ethik der KI-Nutzung in der eigenen Forschung in drei Pflichten zusammen @haindl2027research. *Offenlegung*: Wenn ein generatives Modell zur Arbeit beiträgt, beim Entwurf von Text, beim Vorschlagen von Analysen oder beim Synthetisieren von Literatur, wird dieser Beitrag offengelegt, und zwar so genau, dass Lesende verstehen, welches Modell für welche Aufgaben in welcher Phase verwendet wurde, um ihr Vertrauen kalibrieren zu können. *Keine Autorschaft*: Autorschaft trägt Verantwortung; ein Autor kann für die Arbeit einstehen, die finale Fassung freigeben und später für sie Rede und Antwort stehen, und ein Modell kann nichts davon. Die Verantwortung für jeden Teil des Manuskripts bleibt vollständig bei den menschlichen Autorinnen und Autoren. *Verifikation*: Ein Modell, das einen Literaturüberblick entwirft, kann plausible Zitationen erfinden, eines, das eine Quelle zusammenfasst, kann sie falsch wiedergeben, eines, das eine Analyse vorschlägt, kann einen Test empfehlen, dessen Voraussetzungen die Daten verletzen. Diese Fehler werden zu den eigenen Fehlern der Forscherin, wenn sie sich ungeprüft auf die Ausgabe verlässt @haindl2027research.

Das Lehrbuch schließt mit einem Satz, der sich als Leitlinie für dieses ganze Kapitel eignet: Innerhalb dieser Grenzen, offengelegt, nie als Autor genannt und nie ohne Verifikation vertraut, ist ein generatives Modell ein legitimes Forschungswerkzeug; das ethische Versagen beginnt dort, wo seine Flüssigkeit das Urteil ersetzt, das unaufhebbar das der Forscherin bleibt @haindl2027research.

Zwei weitere Pflichten aus dem Lehrbuch werden bei LLM-Pipelines oft vergessen. Die erste betrifft die *Menschen hinter den Daten*: Die Goldlabels, die eine LLM-Annotation validieren, stammen von Menschen, häufig von Crowdworkern, deren ethische Behandlung sich oft auf die Frage fairer Bezahlung beschränkt, wenn sie überhaupt bedacht wird @Shmueli2021 @haindl2027research. Wer Codierende belastende Inhalte labeln lässt, muss die psychische Belastung antizipieren; die Belmont-Prinzipien gelten für sie ebenso wie für Teilnehmende einer Laborstudie. Die zweite betrifft den *ökologischen Fußabdruck*: Rechenkosten berichten und das am wenigsten aufwendige Experiment wählen, das die Frage beantwortet @haindl2027research @Strubell2019. Ein Kostenmodell wie @k10-eq-kosten ist dafür ein brauchbarer Ausgangspunkt, auch wenn Kosten in Dollar kein Maß für Energie sind.

=== Verlags- und Förderrichtlinien

Die großen Verlage und Ethikgremien sind sich in der Grundposition einig, unterscheiden sich aber im Detail, vor allem darin, *wo* offengelegt wird (@k10-tab-verlage).

#figure(
  table(
    columns: (2.9cm, 3.3cm, 1fr),
    table.header([Institution], [Wo offenlegen], [Bemerkenswerte Regeln]),
    [Elsevier (Juni 2026) @elsevier2026generative], [eigene Erklärung bei Einreichung; Forschungsnutzung im Methodenteil], [Vorlage "During the preparation of this work, the author(s) used [NAME OF TOOL / SERVICE] in order to [REASON]."; Grammatik- und Rechtschreibprüfung ausgenommen; keine KI-erzeugten oder -veränderten Forschungsbilder; Gutachtende dürfen Manuskripte nicht in KI-Werkzeuge hochladen],
    [Springer Nature @springernature2026artificial], [Methodenteil (oder alternativer Abschnitt)], [LLMs "do not currently satisfy our authorship criteria"; KI-generierte Bilder und Videos mit engen Ausnahmen nicht erlaubt; Gutachtende sollen Manuskripte nicht hochladen],
    [IEEE (16.04.2024) @ieee2024author], [Danksagung], [KI-System, betroffene Abschnitte (Text, Abbildungen, Bilder, Code) und Umfang nennen; reine Sprachkorrektur im Allgemeinen außerhalb der Regel, Offenlegung empfohlen],
    [ACM (20.04.2023) @acm2023policy], [Danksagung empfohlen], [GenAI-Werkzeuge "may not be listed as authors"; Nutzung erlaubt, aber vollständig offenzulegen; Rechtschreib-, Grammatik- und Übersetzungswerkzeuge ausgenommen],
    [COPE @cope2024authorship], [Material und Methoden (o. ä.)], ["AI tools cannot meet the requirements for authorship as they cannot take responsibility for the submitted work"; Autorinnen sind voll verantwortlich, auch für KI-erzeugte Teile],
    [EU-Kommission, Living Guidelines, 4. Ausgabe (15.10.2026) @europeancommission2026living], [substanzielle Nutzung offenlegen inkl. Aufsichtsschritte], [KI kann nicht (Mit-)Autor sein; "In case of doubt, disclosure is advised."; keine unveröffentlichten oder sensiblen Arbeiten hochladen ohne Zusicherung, dass sie nicht weiterverwendet werden; alle KI-erzeugten Referenzen prüfen; kein Delegieren wissenschaftlichen Urteils in Begutachtung und Antragsbewertung],
  ),
  kind: table, supplement: [Tab.],
  caption: [Regeln zur Nutzung generativer KI bei Verlagen, COPE und EU-Kommission (Stand: 11. November 2026).],
) <k10-tab-verlage>

Die EC Living Guidelines der Europäischen Kommission und des ERA-Forums sind seit der ersten Ausgabe vom 20. März 2024 in der vierten Ausgabe angekommen, die nächste Revision ist für das dritte Quartal 2027 vorgesehen @europeancommission2026living. Neu sind Regeln zu Agenten: "AI agents must be deployed strictly as advanced research tools, not independent scientists", verbunden mit menschlichen Prüfpunkten bei kritischen Entscheidungen, sowie Regeln zu versteckten Prompts in Einreichungen @europeancommission2026living. Für Gutachtende ist die Lage klar: Weder Elsevier noch Springer Nature erlauben das Hochladen von Manuskripten in KI-Werkzeuge @elsevier2026generative @springernature2026artificial, und die EC-Leitlinien schließen das Delegieren des wissenschaftlichen Urteils bei Begutachtung aus @europeancommission2026living.

#praxis[
  Eine Offenlegung, die bei allen Verlagen in @k10-tab-verlage trägt, nennt Werkzeug und Version, Zweck, betroffene Abschnitte und die menschliche Kontrolle, und steht sowohl in einer eigenen Erklärung als auch, bei Nutzung als Forschungsinstrument, im Methodenteil. Beispiel: "Für die Annotation von 20 000 Kommentaren wurde Claude Sonnet 5.5 (API-Version 2026-10-21, März 2027) als Annotator eingesetzt; Prompt, Codebuch und Validierung gegen 1000 menschlich codierte Kommentare sind in Abschnitt 3.4 und im Replikationspaket dokumentiert. Für sprachliche Überarbeitung von Abschnitt 1 wurde ein LLM verwendet; alle Inhalte wurden von den Autorinnen geprüft und verantwortet."
]

=== EU AI Act: KI-Kompetenz nach Artikel 4

Die KI-Verordnung der EU erreicht Forschungsgruppen über Artikel 4, die Pflicht zur KI-Kompetenz (_AI literacy_). In der durch den Digital Omnibus geänderten Fassung lautet er: "Providers and deployers of AI systems shall take measures to support the development of AI literacy of their staff and other persons dealing with the operation and use of AI systems on their behalf, taking into account their technical knowledge, experience, education and training and the context the AI systems are to be used in, and considering the persons or groups of persons on whom the AI systems are to be used. This obligation does not require providers or deployers to guarantee any specific level of AI literacy of any individual." @europeancommission2026article

Die Daten (Stand: 11. November 2026): Artikel 4 gilt seit dem 2. Februar 2025; Aufsicht und Durchsetzung durch die nationalen Marktüberwachungsbehörden beginnen am 2. August 2026; ein Zertifikat ist nicht erforderlich, eine interne Dokumentation der Schulungsmaßnahmen genügt @europeancommission2026ai. Der Digital Omnibus on AI ist die Verordnung (EU) 2026/1744 des Europäischen Parlaments und des Rates vom 8. Juli 2026, in Kraft seit 27. Juli 2026 @europeanparliament2026regulation. Mit ihm hat sich die Pflicht verschoben: von der Sicherstellung eines "sufficient level of AI literacy" zu Maßnahmen, die die Entwicklung von KI-Kompetenz "unterstützen"; der ursprüngliche Vorschlag der Kommission, die Pflicht auf die Behörden zu verlagern, wurde nicht übernommen @whitecase2026eu @addleshawgoddard2026eu @europeancommission2026article. Für Forschungssoftware relevant sind außerdem die verschobenen Termine für Hochrisiko-Pflichten (Anhang III ab 2. Dezember 2027, Anhang I ab 2. August 2028) und die maschinenlesbare Kennzeichnung synthetischer Inhalte, die für neue Systeme ab 2. August 2026 und für vor diesem Datum in Verkehr gebrachte Systeme ab 2. Dezember 2026 gilt @whitecase2026eu @lewissilkin2026digital.

Eine Forschungsgruppe, die eine LLM-API für ihre Arbeit nutzt, ist im Sinne dieses Artikels Betreiberin (_deployer_). Das ist eine Interpretation der Lehrveranstaltung; die Q&A der Kommission stellt fest, dass die Pflicht Anbieter und Betreiber umfasst und sich auf Auftragnehmer und ähnliche Personen erstreckt @europeancommission2026ai. Praktisch heißt das: Wer Studierende oder Projektmitarbeitende LLM-Pipelines betreiben lässt, sollte dokumentieren, welche Schulung sie dazu erhalten haben. Ein Kapitel wie dieses, eine Lehrveranstaltung wie GAIRI und ein internes Protokoll der Teilnahme sind genau solche Maßnahmen.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let x(j, m) = (j - 2025) * 4.2 + (m - 1) * 0.35
    line((x(2025, 1) - 0.2, 0), (x(2028, 9), 0), stroke: (paint: c-dark, thickness: 1pt), mark: (end: "stealth", fill: c-dark, scale: 0.6))
    for j in (2025, 2026, 2027, 2028) {
      line((x(j, 1), -0.1), (x(j, 1), 0.1), stroke: 0.8pt)
      content((x(j, 1), -0.35), text(font: "Inter", size: 7pt, weight: "bold", str(j)))
    }
    let ereignis(pos, y, txt, col) = {
      line((pos, 0), (pos, y - 0.3 * calc.abs(y) / y), stroke: (paint: col, thickness: 0.7pt))
      circle((pos, 0), radius: 0.07, fill: col, stroke: none)
      content((pos, y), align(center, text(font: "Inter", size: 6.6pt, fill: col.darken(15%), txt)))
    }
    ereignis(x(2025, 2), 0.9, [2.2.2025 \ Art. 4 gilt], c-blue)
    ereignis(x(2026, 7.2), 1.75, [27.7.2026 \ Omnibus in Kraft], c-violet)
    ereignis(x(2026, 8), -1.0, [2.8.2026 \ Aufsicht Art. 4], c-accent)
    ereignis(x(2026, 12), 0.95, [2.12.2026 \ Kennzeichnung \ Altsysteme], c-teal)
    ereignis(x(2027, 12), -1.35, [2.12.2027 \ Hochrisiko \ Anhang III], c-red)
    ereignis(x(2028, 8), 0.9, [2.8.2028 \ Hochrisiko \ Anhang I], c-red)
  }),
  caption: [Zeitachse der für Forschungsgruppen relevanten Termine des EU AI Act nach dem Digital Omnibus (Stand: 11. November 2026) @europeancommission2026ai @europeanparliament2026regulation @whitecase2026eu @lewissilkin2026digital.],
) <k10-fig-aiact>

=== Datenschutz: DSGVO und die Stellungnahme des EDPB

Wer personenbezogene Forschungsdaten an eine LLM-API schickt, verarbeitet personenbezogene Daten und braucht eine Rechtsgrundlage. Der Europäische Datenschutzausschuss (EDPB) hat in seiner Stellungnahme 28/2024 vom 17. Dezember 2024 drei Punkte festgehalten, die für Forschende relevant sind. Erstens gibt es keine Rangfolge der Rechtsgrundlagen; wer sich auf berechtigtes Interesse stützt, muss einen dreistufigen Test bestehen (berechtigtes Interesse, Erforderlichkeit, Abwägung) @edpb2024opinion[paras 60, 66-96]. Zweitens ist die Frage, ob ein mit personenbezogenen Daten trainiertes Modell anonym ist, im Einzelfall zu beurteilen @edpb2024opinion[para 34]. Drittens soll ein Verantwortlicher, der ein Modell eines Dritten einsetzt, im Rahmen seiner Rechenschaftspflicht prüfen, dass es nicht rechtswidrig entwickelt wurde, mit einer Prüftiefe, die dem Risiko des Einsatzes entspricht @edpb2024opinion[Sec. 3.4.2]. Der EDPB hat zudem einen Bericht seines Expertenpools zu Datenschutzrisiken von LLMs mit einer Methodik zum Risikomanagement und drei durchgerechneten Anwendungsfällen veröffentlicht, der ausdrücklich keine EDPB-Position darstellt @barbera2025ai.

Die Datenhandhabung der Anbieter entscheidet, welche Daten du überhaupt senden darfst (Stand: 11. November 2026). Bei OpenAI werden API-Daten ohne Opt-in nicht zum Training verwendet, Missbrauchsüberwachungsprotokolle standardmäßig bis zu 30 Tage aufbewahrt; ZDR und MAM erfordern vorherige Genehmigung, und Batches, Files, Evals und Fine-Tuning sind nicht ZDR-fähig @openai2026data. Bei Anthropic sind Message Batches wegen der 29-tägigen Aufbewahrung "Not eligible" für ZDR @anthropic2026batch. Bei Google werden Inhalte im kostenlosen Tarif zur Verbesserung der Produkte verwendet, im bezahlten nicht @google2026geminipricing.

#merke[
  Praktische Konsequenzen (Synthese der Wissensbasis aus den zitierten Fakten): vor dem Upload pseudonymisieren und minimieren; keine kostenlosen Tarife für personenbezogene Forschungsdaten; bezahlte Tarife ohne Trainingsnutzung wählen @google2026geminipricing @openai2026data; EU-Verarbeitung nutzen, wo angeboten (bei OpenAI nur mit MAM oder ZDR) @openai2026data; bedenken, dass Batch-Verarbeitung bei OpenAI und Anthropic nicht ZDR-fähig ist @openai2026data @anthropic2026batch; für personenbezogene Daten lokale Open-Weight-Inferenz erwägen. Auch die EC-Leitlinien empfehlen Organisationen, wo möglich "locally hosted or cloud-based generative AI tools that they govern themselves" bereitzustellen @europeancommission2026living.
]

Hier entsteht ein Zielkonflikt, den du in einem Projekt bewusst auflösen musst: Die Batch-API ist billiger, aber nicht ZDR-fähig; die synchrone API mit ZDR ist teurer und braucht eine Genehmigung; die lokale Inferenz ist datenschutzfreundlich und reproduzierbar, aber womöglich weniger leistungsfähig. Die Referenz-Pipeline mit Zwei-Arm-Design entschärft den Konflikt teilweise: Personenbezogene Rohdaten bleiben lokal, und an die API gehen nur pseudonymisierte Texte. Ob das genügt, ist eine Frage für die Datenschutzbeauftragte deiner Hochschule, nicht für dieses Kapitel. Die Primärtexte der DSGVO zu Auftragsverarbeitung, Datenschutz-Folgenabschätzung und Drittlandübermittlung wurden für dieses Kapitel nicht ausgewertet.

#hoersaal([Bin ich als Studierende selbst an Artikel 4 gebunden?], [
  Artikel 4 verpflichtet Anbieter und Betreiber von KI-Systemen, Maßnahmen zur Förderung der KI-Kompetenz ihres Personals und anderer Personen zu treffen, die in ihrem Auftrag mit KI-Systemen umgehen @europeancommission2026article. Die Pflicht trifft also die Organisation, etwa die Hochschule oder die Forschungsgruppe, die ein System betreibt, und erstreckt sich laut Kommission auch auf Auftragnehmer und ähnliche Personen @europeancommission2026ai. Ob und wie Studierende darunter fallen, hängt von der Konstellation ab; das ist eine Rechtsfrage, die dieses Buch nicht abschließend beantworten kann. Unabhängig davon gilt: Seit der Änderung durch den Omnibus verlangt der Artikel kein bestimmtes Kompetenzniveau des Einzelnen mehr, sondern Maßnahmen der Organisation @europeancommission2026article.
])

== Debatten und offene Fragen <k10-sec-debatten>

=== Ist bitgleicher Determinismus das richtige Ziel?

*Dafür* spricht, dass Bitgleichheit Debugging, RL-Training und Tests ermöglicht und eine Quelle unerklärter Varianz beseitigt @he2025defeating @vllm2026batch. Hatta geht weiter und argumentiert, dass bitgenau reproduzierbare Builds aus deklarierten Eingaben (Code, Daten, Gewichte, Seeds, Toolchain, Hardware) die Grundlage der Governance von KI-Systemen werden sollten, und formuliert sieben Anforderungen, beginnend mit der vollständigen Aufzählung aller Eingaben @hatta2026reproducibility. *Dagegen* spricht, dass Determinismus Durchsatz kostet (26 s gegenüber 42 bis 55 s im Test von He et al.) @he2025defeating, dass er ohne weitere Maßnahmen nur pro Hardware-Stack gilt @cooper2026accelerating und dass er die Validität nicht berührt. Nicholson und Messina behandeln Variabilität stattdessen als Größe, die man misst und budgetiert @nicholson2026quantifying @messina2026introducing. Die Position dieses Buchs, übernommen aus der Wissensbasis: Stabilitätsstatistiken sind immer zu berichten; Bitgleichheit ist dort zu verlangen, wo die Aussage eine bestimmte Modellausgabe betrifft, etwa ein veröffentlichter Labeldatensatz, und ein Open-Weight-Modell eingesetzt werden kann.

=== Gehostet oder selbst betrieben?

@k10-tab-modellwahl stellt die Argumente gegenüber. Offen bleibt die empirische Frage, wie groß der Leistungsabstand zwischen dem besten gehosteten und dem besten archivierbaren Modell für eine konkrete Aufgabe ist; die Wissensbasis quantifiziert ihn nicht. Palmer et al. und llm-guidelines.org verlangen keine Entscheidung gegen gehostete Modelle, sondern eine Begründung und einen offenen Vergleich @palmer2024using @baltes2025guidelines[Sec. 5.6]. Das ist eine Forderung nach Transparenz, nicht nach Verzicht.

=== Wie viel Variation ist akzeptabel?

Wer legt fest, welche Instabilität tolerierbar ist: die Forscherin über ein anwendungsspezifisches Varianzbudget @nicholson2026quantifying oder das Feld über einen Reporting-Standard? Die Unterberichtung, die Ouyang et al. dokumentieren @ouyang2025empirical, spricht dafür, dass Standards nötig sind, um Stabilitätsberichte überhaupt durchzusetzen. Ein allgemeiner Schwellenwert für TAR\@N ist aber nicht in Sicht, und nach @k10-fig-tar-n wäre er ohnehin nur für ein festes $N$ sinnvoll.

=== Grenzen der Evidenzbasis

Sieben der 29 annotierten Arbeiten der Wissensbasis sind Preprints von 2026 ohne Begutachtung (Cooper, Nicholson, Messina, Hatta, Figalova, Rao, Shi), und auch Baltes, Baumann, Biderman, otto-SR und Lieberum lagen ganz oder teilweise als Preprints vor; die Arbeit von He et al. ist ein Blogbeitrag mit DOI. Die empirischen Studien haben Modelle getestet, die inzwischen abgeschaltet sind, sodass die absoluten Zahlen historisch sind. Was sich überträgt, sind die qualitativen Befunde: Instabilität bei Temperatur 0, Drift, Unterberichtung. Diese Einschränkung ist selbst ein Beispiel für das Thema des Kapitels: Auch die Literatur über reproduzierbare LLM-Forschung beschreibt ein bewegliches Ziel.

#hoersaal([Wenn alle Zahlen aus abgeschalteten Modellen stammen, warum sollen wir sie dann überhaupt lernen?], [
  Weil sie Mechanismen belegen, nicht Modelleigenschaften. Dass GPT-4 im Juni 2023 Primzahlen schlechter erkannte, ist heute irrelevant; dass ein benannter Dienst sein Verhalten innerhalb von drei Monaten so stark ändern kann, ist es nicht @chen2024chatgpts. Dass 80 von 1000 Vervollständigungen verschieden waren, betrifft einen Server von 2025; dass fehlende Batch-Invarianz Nichtdeterminismus erzeugt, betrifft jeden Server, der Anfragen bündelt @he2025defeating. Die richtige Reaktion ist, die Experimente am eigenen Modell zu wiederholen. Genau das ist die erste Übung im Abschnitt "Für die Lehre".
])

#vertiefung[
  *Atil et al. 2025* @atil2025nondeterminism: Die Ankerstudie für TAR\@N; kurz und gut replizierbar. *He und Thinking Machines Lab 2025* @he2025defeating: Die verständlichste Erklärung, warum Server nicht deterministisch sind, mit Code. *Baltes et al.* @baltes2025guidelines: Die Leitlinie, gegen die du deine eigene nächste Arbeit prüfen solltest; lies Abschnitt 5 vollständig. *Baumann et al. 2025* @baumann2025large: Das stärkste Argument für Präregistrierung bei LLM-Annotation. *Biderman et al.* @biderman2024lessons: Erfahrungsbericht aus der Wartung von lm-evaluation-harness, voller konkreter Fallstricke. *Palmer, Smith und Spirling 2024* @palmer2024using: Zwei Seiten, die die Debatte um offene Modelle in der Wissenschaft geprägt haben. *Lehrbuch, Kapitel 9 und 10* @haindl2027research: Der methodische Rahmen, insbesondere "The AI System as a Moving Target" und "The Ethics of Using AI in One's Own Research".
]

== Für die Lehre <k10-sec-lehre>

=== Einordnung und Zeitbedarf

Foliensatz 10 ist der Schlussstein der Lehrveranstaltung: Er nimmt die Messlogik der Foliensätze 04 bis 07 (LLM als Instrument, Annotation, valide Inferenz, LLM-as-a-Judge) und übersetzt sie in Ingenieurspraxis. Der Foliensatz hat sieben Teile (Einführung, Reproduzierbarkeit, Referenz-Pipeline, Werkzeuge und Kosten, Literaturreviews, Reporting, Ethik/Policy/Recht). Für eine Einheit von 90 Minuten bewährt sich folgende Aufteilung: 25 Minuten Reproduzierbarkeit (drei Quellen von Variation, Batch-Invarianz, API-Versionen, TAR\@N), 25 Minuten Referenz-Pipeline mit Live-Durchgang durch das Notebook, 15 Minuten Kosten mit Break-even an der Tafel, 15 Minuten Reviews und Zitationen, 10 Minuten Reporting und Recht. Wenn nur 45 Minuten zur Verfügung stehen, ist die Referenz-Pipeline der Teil, der bleiben muss; Reporting und Recht lassen sich als Lektüre mit Checklisten-Übung auslagern.

Das Notebook `notebooks/10_reproducible_pipeline.ipynb` läuft vollständig offline mit einem simulierten Annotator. Es erzeugt eine Projektstruktur, versioniert Codebuch und Prompt per Hash, schreibt Cache, Manifest und Log, zeigt, dass ein zweiter Lauf aus dem Cache bitgleiche Ergebnisse liefert und dass eine irrelevante Codebuch-Änderung alle Anfragen neu auslöst und Labels verändert, berechnet TARr und TARa, Unique-Anteil und Jaccard, validiert gegen eine geschichtete Goldstichprobe mit Kappa und reproduziert die Kostentabelle per `assert`. Die Übungsaufgaben verlangen den Break-even des Cachings, eine Drift-Probe gegen eine simulierte stille Verhaltensänderung, eine Funktion `verify_run()` und einen Parser v2. Ein optionaler Live-Modus nutzt einen lokalen Ollama-Server oder einen anderen OpenAI-kompatiblen Endpunkt.

=== Übungen

Die Wissensbasis schlägt neun Übungen vor; vier davon passen besonders gut zu diesem Kapitel:

- *TAR\@N am aktuellen Modell replizieren* (2 bis 3 Stunden): 100 Items aus einer MMLU- und einer BBH-Teilaufgabe von Atil et al.; Bedingungen (a) gehostete API über Batch, (b) dasselbe Größensegment als Open-Weight-Modell in vLLM-Standardmodus, (c) vLLM mit `VLLM_BATCH_INVARIANT=1`, jeweils 10 Läufe. Erwartung: (c) sollte TARr\@10 = 100 % liefern, wenn Batch-Invarianz auf der verwendeten Hardware funktioniert, (a) und (b) in der Regel nicht @atil2025nondeterminism @vllm2026batch.
- *Kostenschätzer mit Break-even*: @k10-eq-kosten implementieren, @k10-tab-kosten reproduzieren, Kosten gegen $h$ plotten und den Break-even aus @k10-eq-breakeven numerisch bestätigen.
- *Lebenszyklus-Audit*: `config/models.yaml` für drei Kandidaten mit Restlebensdauer zum geplanten Einreichungstermin; Begründung von Primärinstrument und Replikationsarm in einem Absatz.
- *Referenzverifikation*: Ein Deep-Research-Werkzeug um 20 Referenzen zu einem Kursthema bitten, jede DOI und URL programmatisch und manuell prüfen und die Raten mit 3 bis 13 % @rao2026detecting und 18 % @walters2023fabrication vergleichen.

Für fortgeschrittene Gruppen eignet sich das kritische Lesen von Nicholson (Widersprüche zwischen Text und Tabelle 1 finden) @nicholson2026quantifying und eine Mini-Projekt-Schätzung der Hintergrundtemperatur nach Messina und Scotta @messina2026introducing.

=== Typische Missverständnisse

*"Temperatur 0 heißt deterministisch."* Das hartnäckigste Missverständnis. Es hilft, die Ursachenkette aus @k10-fig-batch an die Tafel zu zeichnen und das Rundungsbeispiel durchzurechnen; danach ist klar, dass der Server nicht die Funktion der eigenen Anfrage allein berechnet.

*"Reproduzierbar heißt, das Modell gibt wieder dasselbe aus."* Studierende verwechseln Re-Analysierbarkeit aus archivierten Rohausgaben mit Wiederholbarkeit des Modellaufrufs. Der Cache-Abschnitt des Notebooks macht den Unterschied erfahrbar.

*"Mehr Läufe machen TAR besser."* Umgekehrt: TAR\@N fällt mit $N$ (@k10-fig-tar-n). Mehr Läufe machen die *Schätzung* genauer, nicht den Wert höher. Die Unterscheidung zwischen $N$ (was gemessen wird) und $Q$ (wie genau) ist der Kern.

*"Caching spart immer."* @k10-tab-kosten zeigt das Gegenbeispiel. Die Herleitung des Break-even ist kurz genug für die Tafel und zeigt, dass die Schwelle nur von drei Preisen abhängt.

*"Die Verlagsrichtlinie reicht als Reporting-Standard."* Verlagsrichtlinien regeln Offenlegung, Reporting-Leitlinien regeln Nachvollziehbarkeit. Sie verlangen Modellversion, Datum, Prompts und Wiederholungen, wovon Verlagsrichtlinien meist schweigen.

*"llm-guidelines.org schreibt ein offenes Modell vor."* Es ist ein Soll-Kriterium, kein Muss @baltes2025guidelines[Sec. 5.6]. Ebenso sind inferenzstatistische Tests beim Modellvergleich ein Soll @baltes2025guidelines[Sec. 5.5]. Präzises Zitieren der Modalverben ist eine gute Übung in wissenschaftlicher Genauigkeit.

#fallstrick[
  Alles Zeitkritische in diesem Kapitel, also Preise, Versionen, Abschalttermine, das Verhalten der Anthropic-API-Version und der Rechtsstand, hat den Stand 11. November 2026. Prüfe diese Angaben am Tag, an dem du unterrichtest, gegen die Primärquellen. Die Studierenden sollen genau diese Gewohnheit lernen: In diesem Feld ist eine Angabe ohne Datum keine Angabe.
]

#selbsttest(
  [Nenne die drei Quellen von Variation in LLM-Pipelines, ordne jeder eine empirische Studie zu und nenne die jeweils passende Gegenmaßnahme.],
  [Erkläre mit dem Begriff der Batch-Invarianz, warum ein gehosteter Endpunkt bei Temperatur 0 verschiedene Ausgaben liefern kann, obwohl ein einzelner Vorwärtsdurchlauf deterministisch ist. Warum ändert ein Seed daran nichts Grundsätzliches?],
  [Zeige mit einem eigenen Zahlenbeispiel bei drei signifikanten Stellen, dass Gleitkommaaddition nicht assoziativ ist.],
  [Ein Forschungsteam aktualisiert im November 2026 sein Anthropic-SDK auf eine neue Hauptversion; das alte Skript setzt `temperature=0`. Was passiert, und welche drei Angaben muss das Replikationspaket deshalb enthalten?],
  [Berechne TARr\@3 und TARa\@3 für fünf Items mit den Läufen: 1: "ja", "ja", "ja"; 2: "nein", "Nein.", "nein"; 3: "ja", "nein", "ja"; 4: "Antwort: ja", "ja", "ja"; 5: "nein", "nein", "nein". Der Parser entfernt "Antwort:", Satzzeichen und Großschreibung.],
  [Ein binäres Label wird pro Lauf mit Wahrscheinlichkeit $pi = 0.9$ vergeben. Berechne die erwartete Übereinstimmungswahrscheinlichkeit für $N = 3$ und $N = 10$ und erkläre, was daraus für den Vergleich von TAR-Werten folgt.],
  [Berechne die Kosten von 50 000 Anfragen mit Claude Sonnet 5.5 ($P = 1500$, $x = 300$, $y = 40$) im Batch ohne Caching und mit 5-Minuten-Cache bei $h = 0.8$. Lohnt sich der Cache? Begründe mit der Break-even-Formel.],
  [Leite die Break-even-Trefferquote her und zeige, dass sie nicht von $N$, $P$, $x$, $y$, $d$ und $r$ abhängt. Berechne sie für den 1-Stunden-Cache von Sonnet 5.5.],
  [Ein LLM screent 3000 Datensätze (200 relevant) mit Sensitivität 0.87 und Spezifität 0.96. Wie viele relevante Datensätze werden übersehen, wie viele Datensätze werden insgesamt weitergeleitet? Welche Rolle sollte das LLM nach diesem Kapitel im Review spielen?],
  [Welche Formulierungen in llm-guidelines.org sind Muss-, welche Soll-Kriterien? Nenne je zwei und erkläre, warum die Unterscheidung beim Zitieren wichtig ist.],
  [Wo legt man die Nutzung generativer KI bei Elsevier, Springer Nature, IEEE und ACM offen, und was ist allen gemeinsam?],
  [Was verlangt Artikel 4 des EU AI Act in der Fassung nach dem Digital Omnibus, seit wann gilt er, ab wann wird er beaufsichtigt, und warum ist eine Forschungsgruppe, die eine LLM-API nutzt, davon betroffen?],
)

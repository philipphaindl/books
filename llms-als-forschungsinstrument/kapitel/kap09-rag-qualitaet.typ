#import "../lib.typ": *

= Qualitätsmodelle für Retrieval-Augmented Generation <k09>

Ein System, das vor der Antwort erst in einem Dokumentenbestand nachschlägt, wirkt auf den ersten Blick wie die Lösung des Halluzinationsproblems. Die Literaturassistenz für eine Masterarbeit, der Frage-Antwort-Bot über interne Richtlinien, das Werkzeug, das Normtexte durchsucht: Sie alle beruhen auf demselben Bauprinzip, der _Retrieval-Augmented Generation_ (RAG). Ein Sprachmodell bekommt zu jeder Frage passende Textstücke aus einer externen Quelle mitgeliefert und soll seine Antwort darauf stützen. Ob das gelingt, ist allerdings keine Eigenschaft des Bauprinzips, sondern eine empirische Frage, und sie ist schwieriger zu beantworten, als es die Dashboards der gängigen Evaluationsbibliotheken suggerieren.

Die Schwierigkeit hat drei Wurzeln. Erstens hat ein RAG-System mindestens zwei Stellen, an denen Qualität entsteht oder verloren geht: was gefunden wird und was daraus gemacht wird. Eine einzige Trefferquote verwischt, an welcher Stelle ein Fehler entstand. Zweitens werden die meisten modernen RAG-Metriken selbst von einem Sprachmodell berechnet, das Aussagen zerlegt und über deren Stützung urteilt. Damit wird die Messung zu einem Instrument, dessen Validität erst gezeigt werden muss, genau wie in Kapitel 5 für LLM-Annotationen und in Kapitel 7 für LLM-as-a-Judge. Drittens tragen Metriken in verschiedenen Bibliotheken denselben Namen und messen doch Verschiedenes, und ihre Definitionen ändern sich mit Versionssprüngen. Wer in einer Arbeit "Faithfulness 0.87" berichtet, ohne Werkzeug, Version und Richtermodell zu nennen, berichtet eine Zahl ohne Bedeutung.

Dieses Kapitel baut die Messkette von oben nach unten auf. Oben stehen die Qualitätsmodelle der Normenreihe ISO/IEC 25000 (SQuaRE), die festlegen, _welche_ Qualitätsmerkmale überhaupt in Betracht kommen. In der Mitte stehen die Metriken: klassische Rangmetriken aus dem Information Retrieval für den Retriever, anspruchsvollere aussagenbasierte Metriken für den Generator. Unten steht die Statistik: Wie gut stimmen automatische Metriken mit Menschen überein, wie setzt man ein Konfidenzintervall auf ein richterbasiertes Maß, und wie zeigt man, dass eine Konfiguration besser ist als eine andere? Das Kapitel schließt mit einem durchgearbeiteten Evaluationsdesign für eine Abschlussarbeit und mit Hinweisen für die Lehre. Es begleitet Foliensatz 09 der Lehrveranstaltung und das Notebook `notebooks/09_rag_metrics.ipynb`, aus dem die Rechenbeispiele stammen.

#lernziele[
  die Komponenten eines RAG-Systems benennen und jeder Komponente die passenden Metriken zuordnen (Retriever, Generator, Ende-zu-Ende),
][
  die Merkmale von ISO/IEC 25010:2023 und die KI-spezifischen Ergänzungen von ISO/IEC 25059:2023 auf ein RAG-System abbilden und begründen, welche Merkmale im Untersuchungsrahmen liegen,
][
  Precision\@k, Recall\@k, MRR, MAP und nDCG (in beiden Varianten) von Hand und in Python berechnen und erklären, warum sie Systeme unterschiedlich reihen,
][
  die Formeln hinter Faithfulness, Answer Relevancy, Context Precision und Context Recall in RAGAS, DeepEval und TruLens wiedergeben und Abweichungen zwischen gleichnamigen Metriken erkennen,
][
  Zitations-Precision und -Recall nach ALCE, FActScore, Nugget-Scores und die Metrikmatrix von RAGChecker berechnen,
][
  die empirische Evidenz zur Übereinstimmung automatischer RAG-Metriken mit menschlichen Urteilen einordnen und eine Validierungsstudie mit zufallskorrigierter Übereinstimmung und Prediction-Powered Inference entwerfen,
][
  zwei RAG-Konfigurationen mit gepaartem Bootstrap und Approximate Randomisation vergleichen und den nötigen Stichprobenumfang abschätzen,
][
  eine vollständige RAG-Evaluation für eine Abschlussarbeit planen und als Qualitätsprofil statt als Einzelzahl berichten.
]

== RAG als Messobjekt <k09-messobjekt>

=== Das Bauprinzip

Der Begriff geht auf Lewis et al. zurück, die ein Modell beschreiben, das "vortrainierten parametrischen und nicht-parametrischen Speicher" für die Sprachgenerierung kombiniert @lewis2020retrieval. Der parametrische Speicher ist ein vortrainiertes Sequenz-zu-Sequenz-Modell, also das, was das Modell in seinen Gewichten "weiß". Der nicht-parametrische Speicher ist ein dichter Vektorindex über Wikipedia, auf den ein vortrainierter neuronaler Retriever zugreift. Die Autoren vergleichen zwei Varianten: Eine konditioniert die gesamte Ausgabe auf dieselben abgerufenen Passagen, die andere darf pro Token andere Passagen heranziehen. Berichtet wird, dass die Kombination Generierungen liefert, die spezifischer, vielfältiger und faktentreuer sind als die eines rein parametrischen Vergleichsmodells, und dass sie auf drei Open-Domain-QA-Aufgaben den damaligen Stand der Technik erreichte @lewis2020retrieval.

Heute bezeichnet RAG eine ganze Familie von Architekturen. Die Übersicht von Gao et al. unterscheidet naive, fortgeschrittene und modulare RAG-Paradigmen @gao2023retrieval. Für die Evaluation reicht ein abstraktes Schema, das in @k09-fig-pipeline dargestellt ist: Eine Frage $q$ geht an einen Retriever, der aus einem Korpus eine Rangliste von Textstücken (_chunks_) liefert; optional ordnet ein Re-Ranker diese Liste neu; die obersten $k$ Stücke bilden den Kontext $c(q)$; ein Generator erzeugt daraus die Antwort $a$. Jeder Pfeil in diesem Schema ist eine Stelle, an der gemessen werden kann, und jede Metrik dieses Kapitels lässt sich einem Pfeil zuordnen.

#figure(
  diagram(spacing: (6mm, 7mm),
    fknoten((0,0), [Korpus \ (Index)], col: c-grey, w: 22mm),
    fknoten((0,1), [Frage $q$], col: c-dark, filled: true, w: 22mm),
    fknoten((1,1), [Retriever \ (+ Re-Ranker)], col: c-blue, filled: true, w: 25mm),
    fknoten((2,1), [Kontext $c(q)$ \ Top-$k$-Chunks], col: c-blue, w: 25mm),
    fknoten((3,1), [Generator \ (LLM)], col: c-accent, filled: true, w: 22mm),
    fknoten((4,1), [Antwort $a$], col: c-accent, w: 22mm),
    edge((0,0), (1,1), "-|>", stroke: 0.8pt + c-grey),
    edge((0,1), (1,1), "-|>"),
    edge((1,1), (2,1), "-|>"),
    edge((2,1), (3,1), "-|>"),
    edge((3,1), (4,1), "-|>"),
    edge((0,1), (3,1), "-|>", bend: 28deg, stroke: (paint: c-grey, dash: "dashed", thickness: 0.7pt)),
    fknoten((1.5,2.25), [*Retriever-Metriken* \ Precision\@k, Recall\@k, MRR, MAP, nDCG \ Context Precision/Recall, eRAG], col: c-teal, w: 46mm),
    fknoten((3.5,2.25), [*Generator-Metriken* \ Faithfulness / Groundedness \ Answer Relevancy \ Zitations-Precision/-Recall], col: c-violet, w: 46mm),
    fknoten((2.5,3.4), [*Ende-zu-Ende gegen Referenz* \ Factual Correctness, Nuggets, FActScore, CRAG-Truthfulness], col: c-yellow, w: 70mm),
    edge((1.5,2.25), (1.5,1.3), stroke: (paint: c-teal, thickness: 0.7pt, dash: "dashed")),
    edge((3.5,2.25), (3.5,1.3), stroke: (paint: c-violet, thickness: 0.7pt, dash: "dashed")),
    edge((2.5,3.4), (4,1.35), stroke: (paint: c-yellow, thickness: 0.7pt, dash: "dashed")),
  ),
  caption: [Abstrakte RAG-Pipeline und die Stellen, an denen Metriken ansetzen. Retriever-Metriken bewerten die Rangliste gegen Relevanzurteile, Generator-Metriken das Verhältnis der Antwort zu Kontext und Frage, Ende-zu-Ende-Metriken die Antwort gegen eine Referenzantwort. Die gestrichelte Kante zeigt, dass der Generator auch die Frage selbst sieht.],
) <k09-fig-pipeline>

=== Zwei Messorte, drei Beziehungen

Weil Qualität an mindestens zwei Orten entsteht, trennen die verbreiteten Werkzeuge die Messung entlang der Komponenten. Die sogenannte RAG-Triade von TruLens bewertet drei Beziehungen: die Relevanz des Kontexts für die Frage (_context relevance_, eine Eigenschaft des Retrievers), die Stützung der Antwort durch den Kontext (_groundedness_, eine Eigenschaft des Generators gegenüber dem Kontext) und die Relevanz der Antwort für die Frage (_answer relevance_, eine Eigenschaft des Generators gegenüber der Frage) @trulens2026ragtriad. RAGAS trennt ebenso retrieverorientierte Metriken (Context Precision, Context Recall) von generatororientierten (Faithfulness, Response Relevancy) @ragas2026availablemetrics. @k09-fig-triade zeigt das Dreieck, ergänzt um die Referenzantwort, die für einen Teil der Metriken zusätzlich nötig ist.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 2.6), [*Frage* $q$], col: c-dark, bg: c-dark.lighten(90%), w: 2.4, h: 0.8)
    kasten((-3.2, 0), [*Kontext* $c(q)$], col: c-blue, bg: c-blue.lighten(90%), w: 2.4, h: 0.8)
    kasten((3.2, 0), [*Antwort* $a$], col: c-accent, bg: c-accent.lighten(90%), w: 2.4, h: 0.8)
    kasten((0, -2.2), [*Referenz* (Goldantwort, \ Gold-Chunks, Nuggets)], col: c-yellow, bg: c-yellow.lighten(88%), w: 3.6, h: 0.95)
    line((-1.2, 2.2), (-2.4, 0.4), stroke: 1.1pt + c-teal)
    line((1.2, 2.2), (2.4, 0.4), stroke: 1.1pt + c-violet)
    line((-2.0, 0), (2.0, 0), stroke: 1.1pt + c-accent)
    line((-2.4, -0.4), (-1.0, -1.75), stroke: (paint: c-yellow, thickness: 0.8pt, dash: "dashed"))
    line((2.4, -0.4), (1.0, -1.75), stroke: (paint: c-yellow, thickness: 0.8pt, dash: "dashed"))
    content((-2.85, 1.45), anchor: "east", text(font: "Inter", size: 7.5pt, fill: c-teal.darken(10%))[*Context Relevance* \ Retriever])
    content((2.85, 1.45), anchor: "west", text(font: "Inter", size: 7.5pt, fill: c-violet.darken(10%))[*Answer Relevance* \ Generator vs. Frage])
    content((0, 0.32), text(font: "Inter", size: 7.5pt, fill: c-accent.darken(10%))[*Groundedness / Faithfulness*])
    content((-2.6, -1.25), anchor: "east", text(font: "Inter", size: 7pt, fill: c-yellow.darken(25%))[Context Recall, \ Context Precision])
    content((2.6, -1.25), anchor: "west", text(font: "Inter", size: 7pt, fill: c-yellow.darken(25%))[Factual Correctness, \ Nuggets])
  }),
  caption: [Die RAG-Triade nach TruLens (durchgezogene Kanten) bewertet drei Beziehungen ohne Referenz. Gestrichelt: Beziehungen, die eine Referenz voraussetzen und deshalb Annotationsaufwand kosten.],
) <k09-fig-triade>

Die Unterscheidung zwischen referenzfreien und referenzbasierten Metriken ist mehr als eine Taxonomie, denn sie bestimmt die Annotationskosten eines Evaluationsdatensatzes. Faithfulness, Response Relevancy und Context Utilization kommen ohne Referenzantwort aus; Context Precision mit Referenz, Context Recall und Factual Correctness brauchen eine @ragas2026contextprecision @ragas2026contextrecall @ragas2026factualcorrectness. Wer für 300 Fragen Goldantworten schreiben muss, plant anders als jemand, der nur die Ausgaben seines Systems sammelt.

#definition(titel: [Komponenten- und Ende-zu-Ende-Evaluation])[
  Eine *Retriever-Evaluation* bewertet die gelieferte Rangliste $d_1, d_2, dots$ zu einer Frage $q$ gegen Relevanzurteile (binär oder abgestuft), gegen Referenz-Chunks oder gegen Aussagen einer Referenzantwort. Eine *Generator-Evaluation* bewertet die Antwort $a$ im Verhältnis zum Kontext $c(q)$ (Stützung) oder zur Frage $q$ (Relevanz). Eine *Ende-zu-Ende-Evaluation* vergleicht $a$ mit einer Referenzantwort, unabhängig davon, was abgerufen wurde. Eine Metrik heißt *referenzfrei*, wenn sie ohne menschlich erstellte Referenz berechnet werden kann.
]

DeepEval macht die Komponentenlogik an einer Stelle besonders deutlich: Seine Contextual-Recall-Metrik verwendet absichtlich die erwartete statt der tatsächlichen Antwort, "because we're measuring the quality of the RAG retriever for a given ideal output" @deepeval2026contextualrecall. Die Metrik heißt also "Recall", hängt aber nicht vom Generator ab. Das ist sinnvoll, sobald man es weiß, und verwirrend, solange man es nicht weiß.

=== Wie RAG-Systeme scheitern

Barnett et al. haben aus drei Fallstudien (Forschung, Bildung, Biomedizin) sieben typische Fehlerpunkte von RAG-Systemen abgeleitet @barnett2024seven. Die Liste ist nützlich, weil sie zeigt, dass eine einzige Genauigkeitszahl die Fehlerursache verschluckt:

+ *FP1 Missing Content:* Die Antwort steht nicht im Korpus.
+ *FP2 Missed the Top Ranked Documents:* Die Antwort steht im Korpus, rangiert aber nicht weit genug oben.
+ *FP3 Not in Context:* Das Dokument wurde gefunden, fiel aber bei der Zusammenstellung des Kontexts heraus.
+ *FP4 Not Extracted:* Die Antwort steht im Kontext, der Generator zieht sie nicht heraus.
+ *FP5 Wrong Format:* Das verlangte Format (etwa Tabelle oder Liste) wird ignoriert.
+ *FP6 Incorrect Specificity:* Die Antwort ist zu allgemein oder zu speziell.
+ *FP7 Incomplete:* Die Antwort ist richtig, aber unvollständig.

Die Autoren schließen, dass "validation of a RAG system is only feasible during operation" @barnett2024seven. Das ist eine starke Aussage, und man muss sie nicht ganz teilen, um ihren Kern zu akzeptieren: Ein Testdatensatz aus der Entwicklungsphase deckt nur die Fehler ab, an die jemand gedacht hat. In der Lehre bewährt es sich, jedem Fehlerpunkt eine Metrik zuzuordnen: FP2 -> Recall\@k und nDCG, FP4 -> Context Utilization, FP7 -> Nugget-Recall. Diese Zuordnung ist ein didaktischer Vorschlag und stammt nicht von Barnett et al. FP1 ist mit keiner Retrieval-Metrik zu fassen, weil es kein relevantes Dokument gibt, das gefunden werden könnte; hier hilft nur eine Prüfung, ob das System sich zu antworten weigert, wenn es nichts weiß. Das Fallbeispiel hat übrigens eine interne Unstimmigkeit: Für den BioASQ-Fall nennen Abschnitt 4.3 und Tabelle 1 4017 Dokumente, Einleitung und Schluss dagegen 15 000 @barnett2024seven. Für die Lehre spielt das keine Rolle, für ein Zitat schon.

Wie weit das Problem von einer Lösung entfernt ist, zeigen die Benchmarks, die @k09-benchmarks ausführlich behandelt. Auf CRAG erreichen die fortgeschrittensten Sprachmodelle ohne Retrieval höchstens 34 % Genauigkeit, ein einfaches RAG 44 %, und industrietaugliche RAG-Lösungen beantworten nur 63 % der Fragen ohne Halluzination @yang2024crag.

#merke[Ein RAG-System hat mindestens zwei Messorte und drei Beziehungen. Jede Metrik, die du berichtest, sollte erkennbar einer Komponente oder der Ende-zu-Ende-Ebene zugeordnet sein. Wenn eine Metrik schlecht ausfällt, muss aus der Zuordnung hervorgehen, wo du mit der Fehlersuche anfängst.]

=== Treue, Faktizität, Halluzination

Bevor Metriken für den Generator sinnvoll gewählt werden können, braucht es drei Begriffe, die im Alltag verschwimmen. Das Lehrbuch zur LV trennt sie scharf @haindl2027research. *Treue zur Quelle* (_faithfulness_) ist Übereinstimmung mit einer bereitgestellten Quelle, unabhängig davon, ob die Quelle stimmt. *Faktizität* (_factuality_) ist Übereinstimmung mit der Welt, unabhängig von einer bestimmten Quelle. *Halluzination* ist Generierung ohne Verankerung, also eine Ausgabe, die weder durch den Kontext noch, oft, durch die Fakten gestützt ist @haindl2027research @Ji2023 @Maynez2020.

Die Unterscheidung hat Konsequenzen. Ein Modell kann einer falschen Quelle vollkommen treu sein; jede Faithfulness-Metrik gibt dann die Bestnote. Und es kann eine wahre Aussage machen, die nicht im Kontext steht; eine strenge Faithfulness-Metrik bestraft sie als Halluzination, obwohl sie stimmt. Im Rechenbeispiel in @k09-generierung kommt genau dieser Fall vor. Für forschungsunterstützende Systeme ist meist die Treue zu den zitierten Quellen die relevante Eigenschaft, weil wissenschaftliche Aussagen auf Belege rückführbar sein sollen; Faktizität darf trotzdem nicht ignoriert werden, denn eine Literatursynthese, die einen zurückgezogenen Befund treu wiedergibt, richtet dennoch Schaden an @haindl2027research. Wer beide Eigenschaften braucht, misst sie getrennt.

#hoersaal([Wenn das Modell die Antwort ohnehin aus dem Kontext abschreibt, warum brauche ich dann noch eine Faithfulness-Metrik?], [Weil "abschreiben" genau das ist, was nicht garantiert ist. Generatoren mischen Kontextwissen mit parametrischem Wissen, verknüpfen zwei Kontextstellen zu einer Aussage, die keine der beiden trägt, oder übernehmen Informationen aus einem irrelevanten Chunk. RAGChecker misst diese Fälle getrennt als Self-Knowledge und Noise Sensitivity @ru2024ragchecker. Außerdem zeigen Liu et al., dass Modelle Informationen in der Mitte eines langen Kontexts schlechter nutzen als am Anfang oder Ende @liu2024lost. Dass etwas im Kontext steht, heißt also nicht, dass es in der Antwort richtig ankommt.])

== Qualitätsmodelle: ISO/IEC 25010:2023 und 25059:2023 <k09-iso>

Metriken beantworten die Frage "Wie messe ich?". Ein Qualitätsmodell beantwortet die vorgelagerte Frage "Was überhaupt?". Ohne diese Ebene entsteht leicht eine Evaluation, die vier Varianten von Faithfulness misst und dabei übersieht, dass das System für den Einsatzzweck vor allem zu langsam ist, vertrauliche Dokumente preisgibt oder sich nicht abschalten lässt. Für eine Abschlussarbeit hat ein normiertes Qualitätsmodell einen zweiten Vorteil: Es zwingt zur expliziten Aussage, welche Merkmale untersucht werden und welche bewusst ausgeklammert bleiben.

=== ISO/IEC 25010:2023: neun Merkmale

ISO/IEC 25010:2023 ist die zweite Ausgabe (2023-11) und ersetzt ISO/IEC 25010:2011. Die Norm "defines a product quality model, which is applicable to ICT" und Softwareprodukte, gegliedert in neun Merkmale mit Teilmerkmalen, als Referenz für das Spezifizieren, Messen und Bewerten von Produktqualität @isoiec2023systems. @k09-tab-25010 listet sie; die Liste ist gegen zwei Sekundärquellen abgeglichen @sonarsource2026iso @arc42q2026isousers, weil die offizielle ISO-Seite nur angibt, dass das Modell aus neun Merkmalen besteht, diese aber nicht aufzählt @isoiec2023systems.

#figure(kind: table, supplement: [Tab.],
  table(columns: (auto, 1fr),
    [Merkmal], [Teilmerkmale],
    [Functional suitability], [functional completeness, functional correctness, functional appropriateness],
    [Performance efficiency], [time behaviour, resource utilization, capacity],
    [Compatibility], [co-existence, interoperability],
    [Interaction capability \ (früher usability)], [appropriateness recognizability, learnability, operability, user error protection, user engagement, inclusivity, user assistance, self-descriptiveness],
    [Reliability], [faultlessness, availability, fault tolerance, recoverability],
    [Security], [confidentiality, integrity, non-repudiation, accountability, authenticity, resistance],
    [Maintainability], [modularity, reusability, analysability, modifiability, testability],
    [Flexibility \ (früher portability)], [adaptability, scalability, installability, replaceability],
    [Safety], [operational constraint, risk identification, fail safe, hazard warning, safe integration],
  ),
  caption: [Produktqualitätsmodell nach ISO/IEC 25010:2023 @isoiec2023systems @sonarsource2026iso @arc42q2026isousers. Die englischen Bezeichnungen sind die der Norm.],
) <k09-tab-25010>

Das Vorwort der Ausgabe 2023 nennt die Änderungen gegenüber 2011 ausdrücklich @isoiec2023systems: Das Quality-in-Use-Modell wanderte in ISO/IEC 25019, Überblick und Anwendungshinweise in ISO/IEC 25002. "Safety has been added as a quality characteristic with subcharacteristics". "Usability and portability have been replaced with interaction capability and flexibility respectively". Neu sind die Teilmerkmale inclusivity, self-descriptiveness, resistance und scalability; user interface aesthetics wurde durch user engagement ersetzt, maturity durch faultlessness, und accessibility wurde in inclusivity und user assistance aufgeteilt.

#fallstrick[Sekundärquellen sind bei Normen nicht immer zuverlässig. Eine Übersichtsseite von arc42 ordnet testability der flexibility zu, die Gliederung derselben Plattform zur Klauselnummerierung der Norm (3.7.5) dagegen der maintainability @arc42q2026iso25010 @arc42q2026isousers. Maintainability ist richtig; das stimmt mit SonarSource und mit dem Modell von 2011 überein @sonarsource2026iso @tmap2026quality. Wer Normen nur aus Blogbeiträgen kennt, übernimmt solche Fehler in die eigene Arbeit.]

=== ISO/IEC 25059:2023: was KI-Systeme zusätzlich brauchen

ISO/IEC 25059:2023 (erste Ausgabe, 2023-06) trägt den Titel "Quality model for AI systems" und passt das Modell aus ISO/IEC 25010 an KI-Systeme an @isoiec2023software. Ein Detail ist für das Verständnis wichtig: Die Norm erschien fünf Monate _vor_ ISO/IEC 25010:2023 und folgt daher noch der Struktur von 2011, also mit usability und portability statt interaction capability und flexibility @isoiec2023software @smith2026isoiec. @k09-tab-25059 fasst die neuen und geänderten Elemente mit den Definitionen aus der Norm zusammen.

#figure(kind: table, supplement: [Tab.],
  table(columns: (34mm, 27mm, 1fr),
    [Element], [Übergeordnet (2023)], [Definition (Zitat)],
    [Functional adaptability (neu)], [functional suitability], ["degree to which an AI system can accurately acquire information from data"],
    [Functional correctness (geändert)], [functional suitability], ["degree to which a product or system provides the correct results with the needed degree of precision"; geändert, weil KI-Systeme eine erwartete Fehlerrate haben],
    [User controllability (neu)], [usability], ["degree to which a user can appropriately intervene in an AI system's functioning in a timely manner"],
    [Transparency (neu)], [usability], ["degree to which appropriate information about the AI system is communicated to relevant stakeholders"],
    [Robustness (neu)], [reliability], ["degree to which an AI system can maintain its level of functional correctness under any circumstances"],
    [Intervenability (neu)], [*ungeklärt*], ["degree to which an operator can intervene in an AI system's functioning in a timely manner to prevent harm or hazard"],
    [Societal and ethical risk mitigation (neu, quality in use)], [freedom from risk], ["degree to which an AI system mitigates potential risk to society"],
  ),
  caption: [Neue und geänderte Elemente in ISO/IEC 25059:2023, Definitionen zitiert nach der Norm @isoiec2023software. Transparency erscheint im Quality-in-Use-Modell zusätzlich als Teilmerkmal von satisfaction.],
) <k09-tab-25059>

Die Zeile zu intervenability verdient eine Erklärung, weil sie zeigt, wie man mit einer offenen Quellenlage umgeht. Welchem Merkmal intervenability in der veröffentlichten Fassung von 2023 untergeordnet ist, ließ sich nicht klären: Das Portal iso25000.com und Natales Beschreibung des Normentwurfs aus dem Jahr 2022 nennen security @iso25000portal2026iso25059 @natale2022extensions, die Kommentierung von Smith nennt usability @smith2026isoiec. Die frei zugängliche Leseprobe der Norm sagt in Klausel 5.7 nur, intervenability sei "related to controllability", und das Inhaltsverzeichnis führt die Klauseln 5.2 bis 5.7 flach auf. Zwei von drei Sekundärquellen sprechen für security; als gesichert darf das aber erst gelten, wenn jemand den Volltext prüft. Dieses Buch behandelt die Zuordnung deshalb als offen.

#figure(
  {
    let zelle(titel, teile, col: c-blue, neu: ()) = block(width: 100%, height: 25mm, fill: col.lighten(92%), stroke: 0.7pt + col, radius: 3pt, inset: 5pt, {
      set par(justify: false, leading: 0.45em)
      text(font: "Inter", size: 7.6pt, weight: "bold", fill: col.darken(20%), titel)
      linebreak()
      text(font: "Inter", size: 6.5pt, fill: c-dark, teile)
      for n in neu { linebreak(); text(font: "Inter", size: 6.6pt, weight: "bold", fill: c-accent, [\+ #n]) }
    })
    grid(columns: (1fr, 1fr, 1fr), gutter: 5pt,
      zelle([Functional suitability], [completeness, correctness\*, appropriateness], col: c-teal, neu: ([functional adaptability],)),
      zelle([Performance efficiency], [time behaviour, resource utilization, capacity], col: c-blue),
      zelle([Compatibility], [co-existence, interoperability], col: c-grey),
      zelle([Interaction capability], [operability, learnability, user assistance, ...], col: c-violet, neu: ([user controllability], [transparency])),
      zelle([Reliability], [faultlessness, availability, fault tolerance, recoverability], col: c-teal, neu: ([robustness],)),
      zelle([Security], [confidentiality, integrity, accountability, resistance, ...], col: c-red, neu: ([intervenability (?)],)),
      zelle([Maintainability], [modularity, reusability, analysability, modifiability, testability], col: c-grey),
      zelle([Flexibility], [adaptability, scalability, installability, replaceability], col: c-grey),
      zelle([Safety], [operational constraint, risk identification, fail safe, ...], col: c-red),
    )
  },
  caption: [Die neun Merkmale von ISO/IEC 25010:2023 mit den Ergänzungen aus ISO/IEC 25059:2023 (orange, mit "+"). Die Ergänzungen sind hier auf die Begriffe von 2023 umgelegt; in 25059:2023 stehen user controllability und transparency unter usability. Das Fragezeichen markiert die ungeklärte Zuordnung von intervenability. \*: functional correctness ist in 25059 modifiziert. Teal: von den RAG-Kernmetriken in RAGAS, DeepEval und TruLens typischerweise abgedeckt; violett: über Zitationsmetriken wie ALCE erreichbar, aber nicht Teil dieser Kernmetriken; blau: operative Merkmale, leicht zu messen, aber nicht in den Suiten; rot und grau: typischerweise nicht abgedeckt.],
) <k09-fig-iso>

=== Ein bewegliches Ziel: die Revision von 25059

Die Norm wird überarbeitet. ISO/IEC DIS 25059 (Ausgabe 2, 19 Seiten) steht laut ISO im Stadium 40.60 "Close of voting" und "Will replace ISO/IEC 25059:2023" (Stand: 11. November 2026) @isoiec2026dis25059. Was der Entwurf inhaltlich ändert, ist nur aus einer Praxiskommentierung bekannt, deren Autor seine Rolle in der Normung nicht offenlegt @smith2026isoiec. Demnach soll der Entwurf von einem Produktqualitätsmodell zu dreien übergehen (Produkt, Quality in Use nach ISO/IEC 25019 und ein neues Qualitätsmodell für KI-Dienste auf Basis von ISO/IEC TS 25011), environmental sustainability unter performance efficiency aufnehmen, user controllability in die interaction capability und intervenability in das neue Merkmal safety verschieben @smith2026isoiec. Die arc42-Zusammenfassung führt environmental sustainability bereits unter performance efficiency und spricht von einem "FDIS", während ISO selbst von DIS spricht @arc42q2026iso25059. Bis zur Veröffentlichung sind diese Inhalte vorläufig.

Für gehostete RAG-Dienste wäre das KI-Dienstqualitätsmodell besonders interessant, weil viele Abschlussarbeiten heute auf einer fremden API aufsetzen, deren Verhalten sich ohne Ankündigung ändern kann (Kapitel 10 behandelt das als Reproduzierbarkeitsproblem). Für eine Arbeit, die im Sommersemester 2027 entsteht, heißt das praktisch: Die Ausgabe von 2023 zitieren, auf die laufende Revision hinweisen und die Entscheidung für die eine oder andere Struktur begründen.

=== Vom Merkmal zur Metrik: die Messkette

Normen definieren Merkmale, keine Metriken. Die Messung liegt in anderen Teilen der SQuaRE-Reihe und in der Verantwortung derer, die evaluieren. Wie schwierig der Schritt vom Merkmal zur Zahl ist, zeigt eine Fallstudie von Oviedo Lama et al. @oviedolama2025towards. Sie wenden ein auf ISO/IEC 25059 und ISO/IEC 25040 aufbauendes Qualitätsmodell samt Evaluationsprozess auf ein reales, regelbasiertes KI-System an, das den Stromverbrauch nach Kundentyp vorhersagt. Bewertet wird nur functional suitability mit vier Teilmerkmalen und fünf Eigenschaften (_properties_).

#studie(titel: [Oviedo Lama et al. 2025])[
  *Design:* Fallstudie zur Anwendung eines ISO/IEC-25059-basierten Qualitätsmodells; Messkette Merkmal -> Teilmerkmal -> Eigenschaft -> Basismetrik -> aggregierte Stufe @oviedolama2025towards. \
  *Befund:* Die Eigenschaften erreichen implementation completeness 100, test completeness 0, functional accuracy 100, appropriate functionality 100, appropriate learning 100. Die Teilmerkmale ergeben completeness 50, correctness 100, appropriateness 100, adaptability 100. Aggregiert erhält functional suitability 3 von 5 Punkten. Die Testabdeckung lag trotz 338 Läufen pro Testfall bei 34.61 % bzw. 41.35 % in zwei Messungen @oviedolama2025towards. \
  *Folgerung der Autoren:* Die Schwellen müssen strenger sein, damit eine Eigenschaft mit 0 nicht trotzdem eine bestandene Stufe ergibt. \
  *Grenzen:* ein einzelnes, regelbasiertes System, kein LLM- oder RAG-System; nur ein Merkmal.
]

Die Studie ist für dieses Kapitel wertvoll, weil sie eine Fehlerform vorführt, die bei RAG-Evaluationen ständig vorkommt: Eine Null verschwindet in einem Mittelwert. Das Lehrbuch formuliert dasselbe Prinzip allgemein: Qualitätsdimensionen sind nicht gegeneinander austauschbar, Faithfulness lässt sich nicht mit Flüssigkeit erkaufen, und wo eine Einzelzahl unvermeidlich ist, sollte eine Mindestschwelle als Tor wirken statt als verrechenbare Größe @haindl2027research.

#definition(titel: [Qualitätsprofil])[
  Ein *Qualitätsprofil* eines RAG-Systems ist eine Menge von Paaren $(m_j, hat(theta)_j plus.minus "KI"_j)$, in der jede Metrik $m_j$ genau einem (Teil-)Merkmal eines benannten Qualitätsmodells zugeordnet ist, jeder Schätzwert $hat(theta)_j$ ein Unsicherheitsmaß trägt und nicht abgedeckte Merkmale ausdrücklich als "nicht untersucht" ausgewiesen werden. Aggregationen über Merkmale hinweg sind nur mit offengelegter Regel und mit Mindestschwellen (_gates_) zulässig.
]

Wie sieht die Abbildung für ein RAG-System konkret aus? Die folgende Zuordnung ist ein Lehrvorschlag und keine Normaussage: Faithfulness und Factual Correctness gehören zu functional correctness; Recall-orientierte Maße und Nugget-Recall zu functional completeness; Noise Sensitivity und die Robustheitsfähigkeiten aus RGB zu robustness; Zitationen und deren Prüfbarkeit zu transparency; die Möglichkeit zu antworten "dazu habe ich keine Information" und ein menschlicher Eingriff zu user controllability und intervenability; Latenzperzentile und Kosten pro Anfrage zu time behaviour und resource utilization @isoiec2023systems @isoiec2023software @ragas2026noisesensitivity. @k09-fig-iso zeigt die Abdeckung: Die gängigen Metrik-Suiten decken vor allem funktionale Korrektheit und Angemessenheit ab; security, safety, maintainability und operative Merkmale liegen außerhalb der RAG-Kernmetriken von RAGAS, DeepEval und TruLens @ragas2026availablemetrics @isoiec2023systems.

#hoersaal([Ist ISO/IEC 25059 für eine Masterarbeit nicht übertrieben? Ich will doch nur wissen, ob mein Chatbot gute Antworten gibt.], [Für die eigentliche Messung brauchst du die Norm nicht. Du brauchst sie für die Begründung deines Untersuchungsrahmens. Ein Gutachter wird fragen, warum du Latenz, Vertraulichkeit oder das Verhalten bei unbeantwortbaren Fragen nicht untersucht hast. Mit einem Qualitätsmodell kannst du antworten: Diese Merkmale liegen außerhalb des Rahmens, aus diesem Grund. Ohne Modell wirkt dieselbe Lücke wie ein Versehen. Der Aufwand ist gering, eine Tabelle wie @k09-tab-25010 mit einer Spalte "untersucht / nicht untersucht / Begründung" reicht.])

=== Operative Qualität

Zwei Merkmale aus @k09-tab-25010 werden in RAG-Arbeiten fast immer vergessen, obwohl sie leicht zu messen sind: time behaviour und resource utilization, beide unter performance efficiency @isoiec2023systems. CRAG misst Latenz als Zeit zwischen dem Absenden einer Frage und dem Empfang der vollständigen Antwort; industrielle RAG-Systeme lagen zwischen 3.4 s und 11.6 s, was die Autoren als Gestaltungsabwägung und nicht als Anforderung behandeln @yang2024crag. Auch die Evaluation selbst hat Betriebskosten: eRAG lief im Mittel 2.468-mal schneller als eine Ende-zu-Ende-Evaluation und brauchte auf NQ 4.9 GB (Abfrageebene) bzw. 1.5 GB (Dokumentebene) GPU-Speicher gegenüber 75.0 GB @salemi2024evaluating. RAGChecker prüft Aussagen mit einem 70B-Modell @ru2024ragchecker, während RAGBench zeigt, dass ein feinjustiertes DeBERTa mit 400 Millionen Parametern bei der Halluzinationserkennung mit LLM-Richtern mithalten kann @friel2024ragbench.

Für eine Abschlussarbeit bietet sich folgende Operationalisierung an, die eine eigene Synthese und keine Quellenaussage ist: Latenz pro Anfrage als p50 und p95, aufgeteilt in Retrieval, Re-Ranking und Generierung; Kosten pro Anfrage als $sum_j "Tokens"_j dot "Preis"_j$ über alle Generator- _und_ Richteraufrufe; Kapazität als dauerhaft erreichbare Anfragen pro Sekunde bei festem p95-Budget. Der Hinweis auf die Richteraufrufe ist ernst gemeint: Aussagenbasierte Metriken brauchen im LLM-Modus pro Stichprobe mindestens einen Extraktions- und einen Urteilsaufruf @ragas2026faithfulness @deepeval2026faithfulness, und bei mehreren Metriken pro Antwort übersteigen die Evaluationskosten leicht die des Systems selbst. Preise und Modellnamen sind am Tag des Experiments zu prüfen und mit Datum zu berichten.

== Retrieval-Metriken <k09-retrieval>

Der Retriever liefert zu jeder Frage eine Rangliste. Ob diese Liste gut ist, ist eine der am längsten untersuchten Fragen der Informatik; das Information Retrieval hat dafür seit Jahrzehnten einen Werkzeugkasten, der sich unverändert auf RAG übertragen lässt. Neu ist bei RAG nur die Frage, _wofür_ relevant ist, was relevant heißt: für einen menschlichen Suchenden oder für den Generator, der den Text weiterverarbeitet. Diese Frage greift @k09-frameworks bei eRAG auf. Zuerst die klassischen Maße.

#definition(titel: [Notation für Ranglisten])[
  Für eine Frage $q$ liefert das System eine Rangliste $d_1, d_2, dots, d_n$. Es bezeichne $"rel"_i in {0, 1}$ die binäre Relevanz des Dokuments auf Rang $i$ und $g_i in {0, 1, 2, 3}$ ein abgestuftes Relevanzurteil. $R_q$ ist die Menge aller für $q$ als relevant beurteilten Dokumente, $Q$ die Menge der Evaluationsfragen, $k$ ein Abschneiderang (_cut-off_). Nicht beurteilte Dokumente gelten in der Rechnung als irrelevant ($"rel"_i = 0$, $g_i = 0$).
]

=== Precision\@k und Recall\@k

Die einfachsten Maße ignorieren die Reihenfolge innerhalb der obersten $k$ und zählen nur. Precision\@k ist der Anteil relevanter Dokumente unter den obersten $k$, Recall\@k der Anteil aller relevanten Dokumente, der es unter die obersten $k$ geschafft hat. In der Form der RAGAS-Dokumentation @ragas2026contextprecision @ragas2026contextrecall:

$ "P@"k = ("TP@"k) / ("TP@"k + "FP@"k) = 1/k sum_(i=1)^k "rel"_i $ <k09-eq-pk>

$ "R@"k = abs({d_1, dots, d_k} inter R_q) / abs(R_q) $ <k09-eq-rk>

$"TP@"k$ zählt relevante, $"FP@"k$ nicht relevante Dokumente unter den obersten $k$. Die rechte Form von @k09-eq-pk gilt, solange die Liste mindestens $k$ Einträge hat. Die RAGAS-Dokumentation rechnet für Recall ein Beispiel vor: abgerufen {doc_1, doc_2, doc_3}, Referenz {doc_1, doc_4, doc_5, doc_6}, also $1 slash 4 = 0.25$ @ragas2026contextrecall.

Für RAG hat Recall\@k eine besondere Bedeutung. Was nicht unter den obersten $k$ landet, sieht der Generator nicht, und kein noch so gutes Sprachmodell kann es in die Antwort bringen. Recall\@k ist damit eine Obergrenze für die Vollständigkeit der Antwort, soweit diese auf Kontextwissen beruhen soll. Precision\@k misst dagegen, wie viel Rauschen der Generator verarbeiten muss. Beide hängen stark an $k$: Mit wachsendem $k$ steigt Recall\@k monoton, Precision\@k fällt typischerweise. Die Wahl von $k$ ist deshalb keine Nebensache, sondern sollte dem $k$ entsprechen, mit dem der Generator tatsächlich arbeitet.

=== Reciprocal Rank und MRR

Bei einer Faktenfrage mit einer einzigen Antwort zählt oft nur, wie weit oben das _erste_ brauchbare Dokument steht. Dafür gibt es den reziproken Rang. Craswell definiert ihn als Kehrwert "of the rank at which the first relevant document was retrieved", gemittelt über die Fragen @craswell2016mean; bekannt wurde das Maß durch den Frage-Antwort-Track von TREC-8, die "first large scale evaluation of domain-independent question answering systems" @voorhees1999trec8:

$ "RR"(q) = 1 / "rank"_q, quad "MRR" = 1/abs(Q) sum_(q in Q) "RR"(q) $ <k09-eq-mrr>

Dabei ist $"rank"_q$ der Rang des ersten relevanten Dokuments; wird innerhalb des Abschneiderangs keines gefunden, setzt man $"RR"(q) = 0$. MRR ist für RAG passend, wenn ein einziger guter Chunk für die Antwort reicht (_single-hop factoid QA_). Für Fragen, deren Antwort Informationen aus mehreren Dokumenten zusammenführen muss, ist es blind: Ob nach dem ersten Treffer noch weitere relevante Dokumente kommen, ändert MRR nicht.

=== Average Precision und MAP

Average Precision verbindet Rangfolge und Vollständigkeit. Man geht die Liste von oben durch, notiert an jedem relevanten Treffer die Precision bis dorthin und mittelt über alle relevanten Dokumente, auch über die nie gefundenen @manning2008introduction:

$ "AP"(q) = 1/abs(R_q) sum_(i=1)^n "P@"i dot "rel"_i, quad "MAP" = 1/abs(Q) sum_(q in Q) "AP"(q) $ <k09-eq-ap>

Nie abgerufene relevante Dokumente tragen 0 bei; genau deshalb steht $abs(R_q)$ im Nenner und nicht die Zahl der gefundenen Treffer. Manning et al. schreiben dieselbe Größe als $"MAP"(Q) = 1/abs(Q) sum_j 1/m_j sum_k "Precision"(R_(j k))$, wobei $m_j$ die Zahl relevanter Dokumente zu Frage $j$ und $R_(j k)$ die Rangliste bis zum $k$-ten relevanten Dokument ist, mit Precision 0 für nie gefundene relevante Dokumente @manning2008introduction.

Warum ist das eine sinnvolle Größe? Eine kurze Herleitung zeigt, dass AP eine Fläche unter der Precision-Recall-Kurve ist. Geht man die Liste Rang für Rang durch, ändert sich der Recall nur an relevanten Rängen, und zwar jeweils um $Delta "R"(i) = "rel"_i slash abs(R_q)$. Die Summe $sum_i "P@"i dot Delta "R"(i)$ ist eine Riemann-Summe der Precision über der Recall-Achse, mit Stufen genau an den Stellen, an denen sich der Recall ändert. Einsetzen von $Delta "R"(i)$ ergibt unmittelbar @k09-eq-ap. Daraus folgen zwei Eigenschaften: AP ist 1 genau dann, wenn alle relevanten Dokumente vor allen irrelevanten stehen (dann ist $"P@"i = 1$ an jedem relevanten Rang und der Recall erreicht 1), und AP bestraft sowohl schlechte Rangfolge (kleine Precision an den Trefferstellen) als auch fehlende Dokumente (Recall-Achse wird nicht ausgeschöpft).

=== Context Precision: eine AP-Variante mit anderem Nenner

RAGAS und DeepEval bieten eine Metrik namens Context Precision an, die wie AP aussieht, aber einen entscheidenden Unterschied hat @ragas2026contextprecision:

$ "CP@"K = (sum_(k=1)^K "P@"k dot v_k) / ("Anzahl relevanter Elemente in den obersten" K) $ <k09-eq-cp>

$K$ ist die Zahl der Chunks in `retrieved_contexts`, $v_k in {0, 1}$ der Relevanzindikator auf Rang $k$. Er wird von einem LLM beurteilt, und zwar gegen die Referenzantwort (`ContextPrecision`) oder gegen die Antwort des Systems (`ContextUtilization`) @ragas2026contextprecision. DeepEvals Contextual Precision hat dieselbe Funktionsform: Summe über die Ränge $k$ von (Anzahl relevanter Knoten bis $k$)$slash k dot r_k$, geteilt durch die Anzahl relevanter Knoten, mit $r_k$ beurteilt gegen `expected_output` und mit Gruppierung von Knoten derselben `source` @deepeval2026contextualprecision.

Der Nenner zählt nur relevante Elemente, die abgerufen _wurden_. Die Metrik misst also die Rangqualität _innerhalb_ der abgerufenen Menge und bestraft fehlende relevante Chunks nicht; das ist Aufgabe von Context Recall. Das RAGAS-Beispiel zeigt den Effekt der Position: Steht der einzige relevante Chunk auf Rang 1, ergibt sich etwa 1.0, steht er auf Rang 2, etwa 0.5 @ragas2026contextprecision. Die Beziehung zu AP lässt sich exakt angeben.

#satz(titel: [Context Precision und abgeschnittene AP])[
  Sei $h_K = sum_(i=1)^K "rel"_i$ die Zahl relevanter Dokumente unter den obersten $K$ und $"AP@"K = 1/abs(R_q) sum_(i=1)^K "P@"i dot "rel"_i$. Ist $h_K > 0$ und werden die Relevanzindikatoren $v_k$ gleich $"rel"_k$ gesetzt, dann gilt
  $ "CP@"K = abs(R_q) / h_K dot "AP@"K >= "AP@"K, $
  mit Gleichheit genau dann, wenn alle relevanten Dokumente unter den obersten $K$ liegen.
]
#beweis[
  Zähler von @k09-eq-cp und von $"AP@"K$ sind identisch, nämlich $S = sum_(i=1)^K "P@"i dot "rel"_i$. Also $"CP@"K = S slash h_K$ und $"AP@"K = S slash abs(R_q)$, woraus $"CP@"K = (abs(R_q) slash h_K) dot "AP@"K$ folgt. Da höchstens alle relevanten Dokumente in den obersten $K$ liegen können, ist $h_K <= abs(R_q)$, der Faktor also mindestens 1. Gleichheit gilt genau für $h_K = abs(R_q)$.
]

Der Satz macht eine praktische Warnung präzise: Context Precision ist um den Faktor $abs(R_q) slash h_K$ nachsichtiger als die abgeschnittene AP, und dieser Faktor ist umso größer, je mehr relevante Dokumente der Retriever übersehen hat. Wer nur Context Precision berichtet, belohnt also einen Retriever, der wenig findet, das Wenige aber oben platziert. Context Precision ohne Recall ist deshalb unvollständig.

=== Discounted Cumulative Gain und nDCG

Alle bisherigen Maße arbeiten mit binärer Relevanz. In vielen RAG-Szenarien gibt es aber Abstufungen: Ein Chunk enthält die vollständige Antwort, ein anderer nur einen Teil, ein dritter nur Hintergrund. Järvelin und Kekäläinen haben dafür die kumulierten Gewinnmaße eingeführt, die hoch relevante Dokumente stärker belohnen und späte Ränge abwerten @jarvelin2002cumulated. Ihre Originaldefinition lautet

$ "DCG"[i] = cases("CG"[i] & "falls" i < b, "DCG"[i-1] + G[i] slash log_b i & "falls" i >= b,) quad "CG"[i] = "CG"[i-1] + G[i] $ <k09-eq-dcg-jk>

mit dem Gewinn $G[i]$ des Dokuments auf Rang $i$ (in der Originalstudie abgestuft 0 bis 3 für irrelevant, marginal, ziemlich und hoch relevant) und der Logarithmusbasis $b$ des Abschlags, in der Fallstudie $b = 2$ @jarvelin2002cumulated. Für Ränge unter $b$ gibt es keinen Abschlag, weil $log_b 1 = 0$ wäre. Normiert wird, indem man den (D)CG-Vektor komponentenweise durch den idealen Vektor teilt, der entsteht, wenn man alle beurteilten Dokumente absteigend nach Grad sortiert @jarvelin2002cumulated. Die Autoren haben auch verschiedene Gewinngewichtungen erprobt, etwa 0-1-1-1, 0-0-0-1 und 0-1-10-100.

In den meisten Werkzeugen und Lehrbüchern hat sich eine etwas andere Form durchgesetzt @manning2008introduction:

$ "DCG@"k = sum_(i=1)^k ("gain"(g_i)) / (log_2(i + 1)), quad "nDCG@"k = ("DCG@"k) / ("IDCG@"k) $ <k09-eq-ndcg>

Manning et al. verwenden den exponentiellen Gewinn $"gain"(g_i) = 2^(g_i) - 1$ mit Abschlag $log_2(1 + m)$ und einem Normierungsfaktor, sodass eine perfekte Rangfolge 1 ergibt @manning2008introduction; ebenso verbreitet ist der lineare Gewinn $"gain"(g_i) = g_i$. $"IDCG@"k$ ist der DCG\@k der idealen Ordnung aller beurteilten Dokumente zu $q$. Die Varianten unterscheiden sich in Gewinn und Abschlag, und ein Bericht muss angeben, welche verwendet wurde. @k09-fig-discount vergleicht die Abschlagsgewichte.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let sx = 1.05
    let sy = 4.2
    // Achsen
    line((0, 0), (10.6 * sx, 0), stroke: 0.7pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.5))
    line((0, 0), (0, 1.12 * sy), stroke: 0.7pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.5))
    for i in range(1, 11) {
      line((i * sx, 0), (i * sx, -0.08), stroke: 0.5pt)
      content((i * sx, -0.3), text(font: "Inter", size: 7pt)[#i])
    }
    for v in (0.25, 0.5, 0.75, 1.0) {
      line((0, v * sy), (10.3 * sx, v * sy), stroke: (paint: luma(225), thickness: 0.4pt))
      content((-0.15, v * sy), anchor: "east", text(font: "Inter", size: 7pt)[#str(v)])
    }
    content((5.3 * sx, -0.75), text(font: "Inter", size: 7.5pt)[Rang $i$])
    content((-0.95, 0.55 * sy), angle: 90deg, text(font: "Inter", size: 7.5pt)[Gewicht])
    let kurve(f, col, dash: none) = {
      let pts = range(1, 11).map(i => (i * sx, f(i) * sy))
      line(..pts, stroke: (paint: col, thickness: 1.1pt, dash: dash))
      for p in pts { circle(p, radius: 0.06, fill: col, stroke: none) }
    }
    kurve(i => 1 / calc.log(i + 1, base: 2), c-teal)
    kurve(i => if i < 2 { 1 } else { 1 / calc.log(i, base: 2) }, c-violet, dash: "dashed")
    kurve(i => 1 / i, c-accent)
    content((10.4 * sx, 0.29 * sy), anchor: "west", text(font: "Inter", size: 7pt, fill: c-teal.darken(10%))[$1 slash log_2(i+1)$])
    content((10.4 * sx, 0.36 * sy), anchor: "west", text(font: "Inter", size: 7pt, fill: c-violet.darken(10%))[JK, $b = 2$])
    content((10.4 * sx, 0.1 * sy), anchor: "west", text(font: "Inter", size: 7pt, fill: c-accent.darken(10%))[$1 slash i$ (RR)])
  }),
  caption: [Abschlagsgewichte nach Rang. Die heute übliche Form $1 slash log_2(i+1)$ (teal) gewichtet Rang 2 mit 0.631; die Originaldefinition von Järvelin und Kekäläinen mit $b = 2$ (violett, gestrichelt) wertet Rang 2 noch gar nicht ab und liegt ab dort immer eine Position "zurück". Der reziproke Rang (orange) fällt wesentlich steiler.],
) <k09-fig-discount>

#satz(titel: [Wertebereich von nDCG])[
  Sind alle Gewinne nichtnegativ, die Abschlagsgewichte $w_i = 1 slash log_2(i+1)$ streng fallend und ist $"IDCG@"k > 0$, dann gilt $0 <= "nDCG@"k <= 1$.
]
#beweis[
  Nichtnegativität ist klar. Für die obere Schranke seien $x_1, dots, x_k$ die Gewinne der obersten $k$ Dokumente der Systemliste und $x_((1)) >= dots >= x_((k))$ ihre absteigende Sortierung. Nach der Umordnungsungleichung ist $sum_i x_i w_i <= sum_i x_((i)) w_i$, weil die größten Gewinne mit den größten Gewichten gepaart werden. Seien $y_1 >= y_2 >= dots$ die absteigend sortierten Gewinne aller beurteilten Dokumente. Da die $x_i$ eine Teilmenge davon bilden (nicht beurteilte haben Gewinn 0), ist der $j$-größte unter den $x_i$ höchstens so groß wie der $j$-größte unter allen, also $x_((j)) <= y_j$. Somit $"DCG@"k <= sum_i x_((i)) w_i <= sum_i y_i w_i = "IDCG@"k$.
]

Der Beweis zeigt auch, wo die Annahme steckt, die in der Praxis oft verletzt wird: $"IDCG@"k$ muss aus _allen_ beurteilten Dokumenten berechnet werden, nicht nur aus den abgerufenen. Wer die ideale Ordnung aus der eigenen Systemliste bildet, erhält für ein System, das nur wenige und nur schwach relevante Dokumente findet, diese aber richtig sortiert, einen hohen Wert, im Extremfall 1. Das Notebook zeigt, wie man `sklearn.metrics.ndcg_score` dazu bringt, die vollständige ideale Liste zu sehen: Man hängt die nicht abgerufenen, beurteilten Dokumente mit niedrigeren Scores an.

BEIR hat sich für nDCG\@10 als einzige Kennzahl entschieden, weil Precision und Recall den Rang nicht berücksichtigen und MRR und MAP mit abgestufter Relevanz nicht umgehen können @thakur2021beir. Das ist eine vernünftige Konvention für den Vergleich von Retrievern über viele Datensätze. Für RAG hat nDCG allerdings eine Schwäche, die man kennen sollte: Der Abschlag modelliert einen Menschen, der eine Liste von oben nach unten liest und irgendwann aufhört. Ein Generator liest alle $k$ Chunks; ob Rang 3 oder Rang 5 macht für ihn vielleicht weniger aus, als die Abschlagskurve unterstellt, und zugleich zeigen Liu et al., dass Position im Kontext durchaus wirkt, nur nicht monoton: Modelle nutzen Informationen am Anfang und Ende besser als in der Mitte @liu2024lost.

=== Vollständiges Rechenbeispiel

Das folgende Beispiel ist im Notebook umgesetzt und wurde mit Python nachgerechnet. Drei Fragen, abgestufte Relevanzurteile von 0 bis 3, je eine Top-10-Rangliste, Abschneiderang $k = 5$:

- q1: relevant {d2: 3, d5: 2, d7: 1, d9: 2}; Rangliste d5, d1, d2, d8, d7, d3, d4, d6, d10, d9
- q2: relevant {d3: 1, d8: 2}; Rangliste d1, d6, d8, d2, d3, d4, d5, d7, d9, d10
- q3: relevant {d4: 2}; Rangliste d1, d2, d3, d5, d6, d7, d8, d9, d10, d11 (das relevante Dokument wird nie abgerufen)

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let rows = (
      ("q1", ("d5", "d1", "d2", "d8", "d7", "d3", "d4", "d6", "d10", "d9"), (2, 0, 3, 0, 1, 0, 0, 0, 0, 2)),
      ("q2", ("d1", "d6", "d8", "d2", "d3", "d4", "d5", "d7", "d9", "d10"), (0, 0, 2, 0, 1, 0, 0, 0, 0, 0)),
      ("q3", ("d1", "d2", "d3", "d5", "d6", "d7", "d8", "d9", "d10", "d11"), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
    )
    let dx = 1.2
    for i in range(10) {
      content((i * dx + 0.5, 0.75), text(font: "Inter", size: 6.8pt, fill: c-grey.darken(20%))[Rang #(i + 1)])
    }
    for (r, (q, docs, gr)) in rows.enumerate() {
      let y = -r * 1.05
      content((-0.35, y), anchor: "east", text(font: "Inter", size: 8pt, weight: "bold")[#q])
      for (i, d) in docs.enumerate() {
        let g = gr.at(i)
        let col = if g == 0 { white } else { c-teal.lighten(85% - g * 25%) }
        let tcol = if g >= 2 { white } else { c-dark }
        rect((i * dx, y - 0.36), (i * dx + 1.0, y + 0.36), fill: col, stroke: 0.6pt + (if g > 0 { c-teal } else { c-grey }), radius: 0.08)
        content((i * dx + 0.5, y + 0.1), text(font: "Inter", size: 7pt, fill: tcol, weight: "bold")[#d])
        content((i * dx + 0.5, y - 0.17), text(font: "Inter", size: 6pt, fill: tcol)[$g = #g$])
      }
    }
    line((5 * dx - 0.1, 1.0), (5 * dx - 0.1, -2.55), stroke: (paint: c-accent, thickness: 1pt, dash: "dashed"))
    content((5 * dx - 0.1, -2.8), text(font: "Inter", size: 7pt, fill: c-accent, weight: "bold")[Abschneiderang $k = 5$])
    content((12.3, -2.1), anchor: "west", text(font: "Inter", size: 6.5pt, fill: c-grey.darken(20%))[q3: relevant d4 \ ($g = 2$), nie \ abgerufen])
  }),
  caption: [Die drei Ranglisten des Rechenbeispiels. Je dunkler ein Feld, desto höher der Relevanzgrad. Bei q1 liegt das relevante Dokument d9 außerhalb des Abschneiderangs, bei q3 wird das einzige relevante Dokument gar nicht gefunden.],
) <k09-fig-ranking>

#beispiel(titel: [Alle Retrieval-Metriken für q1 und q2])[
  *q1.* Relevante Treffer auf den Rängen 1, 3, 5 (d5, d2, d7) und 10 (d9); $abs(R_(q 1)) = 4$.

  - $"P@"5 = 3 slash 5 = 0.600$; $"R@"5 = 3 slash 4 = 0.750$; $"RR" = 1 slash 1 = 1.000$.
  - $"AP" = (1/1 + 2/3 + 3/5 + 4/10) slash 4 = 2.667 slash 4 = 0.667$.
  - Abgeschnitten bei 5: $"AP@"5 = (1 + 0.667 + 0.600) slash 4 = 2.267 slash 4 = 0.567$.
  - Context Precision mit Nenner $h_5 = 3$: $"CP@"5 = 2.267 slash 3 = 0.756$. Probe mit dem Satz: $4 slash 3 dot 0.567 = 0.756$.
  - Grade in den obersten 5: $[2, 0, 3, 0, 1]$. Linearer Gewinn: $"DCG@"5 = 2 slash 1 + 3 slash log_2 4 + 1 slash log_2 6 = 2 + 1.5 + 0.387 = 3.887$.
  - Ideale Grade $[3, 2, 2, 1]$: $"IDCG@"5 = 3 + 2 slash 1.585 + 2 slash 2 + 1 slash log_2 5 = 3 + 1.262 + 1 + 0.431 = 5.693$. Also $"nDCG@"5 = 3.887 slash 5.693 = 0.683$.
  - Exponentieller Gewinn $2^g - 1$: Gewinne $[3, 0, 7, 0, 1]$, $"DCG@"5 = 3 + 3.5 + 0.387 = 6.887$; ideal $[7, 3, 3, 1]$, $"IDCG@"5 = 7 + 1.893 + 1.5 + 0.431 = 10.824$; $"nDCG@"5 = 0.636$.
  - Original nach Järvelin und Kekäläinen ($b = 2$, Rang 1 und 2 ohne bzw. mit $log_2 2 = 1$): $"DCG@"5 = 2 + 0 + 3 slash log_2 3 + 0 + 1 slash log_2 5 = 2 + 1.893 + 0.431 = 4.323$, ideal $3 + 2 + 2 slash 1.585 + 1 slash 2 = 6.762$, also $0.639$.

  *q2.* Treffer auf Rang 3 (d8, $g = 2$) und 5 (d3, $g = 1$); $abs(R_(q 2)) = 2$.

  - $"P@"5 = 0.400$; $"R@"5 = 1.000$; $"RR" = 1 slash 3 = 0.333$.
  - $"AP" = (1/3 + 2/5) slash 2 = 0.367$; da beide Treffer unter den obersten 5 liegen, sind $"AP@"5$ und $"CP@"5$ ebenfalls $0.367$ (Gleichheitsfall des Satzes).
  - $"DCG@"5 = 2 slash log_2 4 + 1 slash log_2 6 = 1 + 0.387 = 1.387$; $"IDCG@"5 = 2 + 1 slash 1.585 = 2.631$; $"nDCG@"5 = 0.527$ (exponentiell $0.520$).

  *q3.* Alle Maße sind 0, weil kein relevantes Dokument abgerufen wurde.
]

@k09-tab-retrieval fasst alle Werte zusammen; die Mittelwerte über die drei Fragen sind die systemweiten Kennzahlen (MRR ist der Mittelwert der RR, MAP der Mittelwert der AP).

#figure(kind: table, supplement: [Tab.],
  table(columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, right, right, right, right, right, right, right),
    [Frage], [P\@5], [R\@5], [RR], [AP], [AP\@5], [CP\@5], [nDCG\@5 lin.], [nDCG\@5 exp.],
    [q1], [0.600], [0.750], [1.000], [0.667], [0.567], [0.756], [0.683], [0.636],
    [q2], [0.400], [1.000], [0.333], [0.367], [0.367], [0.367], [0.527], [0.520],
    [q3], [0.000], [0.000], [0.000], [0.000], [0.000], [0.000], [0.000], [0.000],
    [*Mittel*], [*0.333*], [*0.583*], [*0.444*], [*0.344*], [*0.311*], [*0.374*], [*0.403*], [*0.385*],
  ),
  caption: [Retrieval-Metriken des Rechenbeispiels (gerundet auf drei Stellen, mit Python nachgerechnet). Die Mittelwerte von RR und AP sind MRR und MAP. CP\@5 ist die Context Precision im Stil von RAGAS mit $v_k = "rel"_k$.],
) <k09-tab-retrieval>

Drei Beobachtungen machen das Beispiel lehrreich. Erstens ist die RAGAS-artige Context Precision für q1 mit 0.756 deutlich nachsichtiger als AP\@5 mit 0.567, weil ihr Nenner das relevante Dokument d9 außerhalb der obersten fünf ignoriert. Zweitens belohnt MRR q1 voll (RR = 1), obwohl q1 innerhalb des Abschneiderangs ein relevantes Dokument verpasst; MRR schaut nur auf den ersten Treffer. Drittens trägt q3 überall Nullen bei. Bei wenigen Fragen dominiert die Varianz zwischen den Fragen; berichte deshalb Verteilungen pro Frage oder Konfidenzintervalle und nicht nur Mittelwerte. Wie man solche Intervalle bestimmt, zeigt @k09-vergleich.

#datei("retrieval_metrics.py")[
```python
import math

qrels = {"q1": {"d2": 3, "d5": 2, "d7": 1, "d9": 2},
         "q2": {"d3": 1, "d8": 2},
         "q3": {"d4": 2}}
runs = {"q1": ["d5","d1","d2","d8","d7","d3","d4","d6","d10","d9"],
        "q2": ["d1","d6","d8","d2","d3","d4","d5","d7","d9","d10"],
        "q3": ["d1","d2","d3","d5","d6","d7","d8","d9","d10","d11"]}

def rel(q, d):
    return 1 if qrels[q].get(d, 0) >= 1 else 0

def average_precision(q, k=None):          # Nenner |R_q|
    ranking = runs[q] if k is None else runs[q][:k]
    hits, s = 0, 0.0
    for i, d in enumerate(ranking, start=1):
        if rel(q, d):
            hits += 1
            s += hits / i
    return s / len(qrels[q])

def context_precision(q, k):               # Nenner: Treffer in den Top k
    hits, s = 0, 0.0
    for i, d in enumerate(runs[q][:k], start=1):
        if rel(q, d):
            hits += 1
            s += hits / i
    return s / hits if hits else 0.0

def dcg(grades, k, exp_gain=False):
    return sum(((2**g - 1) if exp_gain else g) / math.log2(i + 1)
               for i, g in enumerate(grades[:k], start=1))

def ndcg(q, k, exp_gain=False):
    grades = [qrels[q].get(d, 0) for d in runs[q]]
    ideal = sorted(qrels[q].values(), reverse=True)  # ALLE beurteilten Dokumente
    return dcg(grades, k, exp_gain) / dcg(ideal, k, exp_gain)

print(round(average_precision("q1", 5), 3), round(context_precision("q1", 5), 3),
      round(ndcg("q1", 5), 3), round(ndcg("q1", 5, exp_gain=True), 3))
```
]
```out
0.567 0.756 0.683 0.636
```

#fallstrick[Die Gewinnfunktion ändert die Zahlen (mittleres nDCG\@5 0.403 linear gegenüber 0.385 exponentiell), und bei knappen Vergleichen kann sie auch die Reihenfolge von Systemen ändern. Der exponentielle Gewinn verstärkt den Abstand zwischen "hoch relevant" und "ziemlich relevant" (7 gegenüber 3 statt 3 gegenüber 2). Lege die Variante vor der Auswertung fest, nenne sie im Methodenteil und wähle sie nicht nachträglich danach aus, welche das eigene System besser aussehen lässt.]

#hoersaal([Welche Metrik soll ich für meinen Retriever berichten? Es gibt so viele.], [Wähle nach dem, was der Generator braucht. Reicht ein einziger Chunk für die Antwort, ist MRR oder Recall\@k mit kleinem $k$ aussagekräftig. Braucht die Antwort mehrere Dokumente, ist Recall\@k mit dem tatsächlich verwendeten $k$ die wichtigste Zahl, weil sie die Obergrenze für die Vollständigkeit setzt. Gibt es abgestufte Urteile, ergänzt nDCG\@k die Rangqualität. Context Precision berichtest du nur zusammen mit Recall. Und nenne in jedem Fall $k$, die Relevanzskala und die Gewinnvariante.])

#hoersaal([Woher bekomme ich überhaupt Relevanzurteile? Für 300 Fragen jeden Chunk zu beurteilen ist unrealistisch.], [Es gibt drei Wege. Menschliche Urteile auf einem gepoolten Ausschnitt (die obersten Treffer mehrerer Systeme) sind der klassische Weg. LLM-Urteile sind billiger; ob sie menschliche ersetzen können, ist umstritten, @k09-validitaet stellt die Positionen dar @thomas2024large @clarke2025llmbased. Der dritte Weg ist eRAG: Man lässt den eigenen Generator mit jedem Dokument einzeln antworten und nimmt den Erfolg der Antwort als Relevanzurteil @salemi2024evaluating. Für eine Abschlussarbeit ist eine Kombination sinnvoll, bei der ein Teil der Urteile von Menschen stammt und zur Validierung der anderen dient.])

== Generierungsmetriken <k09-generierung>

Retrieval-Metriken lassen sich mit einer Handvoll Zeilen Python berechnen, sobald Relevanzurteile vorliegen. Für die Antwort des Generators gibt es kein so einfaches Gegenstück, weil "die Antwort ist durch den Kontext gestützt" keine Eigenschaft von Zeichenketten ist. Die heute dominierende Lösung ist die Zerlegung: Ein Sprachmodell zerlegt den Text in atomare Aussagen (_claims_, _statements_), ein Sprachmodell oder ein Entailment-Klassifikator urteilt über jede Aussage einzeln, und die Metrik ist ein Anteil. Das Muster geht auf FActScore zurück, das eine Generierung in atomare Fakten zerlegt und den Prozentsatz berechnet, der von einer verlässlichen Wissensquelle gestützt wird @min2023factscore. Fast alle folgenden Metriken sind Varianten davon; sie unterscheiden sich darin, _was_ zerlegt wird (Antwort, Referenz, Kontext), _wogegen_ geprüft wird (Kontext, Referenz, Frage) und _wie streng_ das Urteil ist.

#figure(
  diagram(spacing: (10mm, 6mm),
    fknoten((0,0), [Text (Antwort \ oder Referenz)], col: c-dark, w: 26mm),
    fknoten((1,0), [Zerlegung in \ atomare Aussagen \ (LLM)], col: c-blue, filled: true, w: 31mm),
    fknoten((2,0), [Urteil je Aussage \ (LLM, NLI oder \ Klassifikator)], col: c-accent, filled: true, w: 30mm),
    fknoten((3,0), [Anteil \ $abs(V) slash abs(S)$], col: c-teal, w: 20mm),
    fknoten((2,1), [Prüfquelle: Kontext, \ Referenz oder Frage], col: c-grey, w: 34mm),
    edge((0,0), (1,0), "-|>"),
    edge((1,0), (2,0), "-|>", label: text(size: 7pt)[$S$], label-side: left),
    edge((2,0), (3,0), "-|>", label: text(size: 7pt)[$V subset.eq S$], label-side: left),
    edge((2,1), (2,0), "-|>", stroke: (dash: "dashed")),
  ),
  caption: [Das gemeinsame Muster aussagenbasierter Metriken. Zwei Modellschritte (Zerlegung und Urteil) gehen in jede Zahl ein; beide können irren, und beide hängen vom Richtermodell und vom Prompt ab.],
) <k09-fig-claims>

Das Lehrbuch zur LV benennt die Annahmen, die in diesem Muster stecken @haindl2027research. "Atomarität" unterstellt, dass sich eine Ausgabe sauber in unabhängige Aussagen zerlegen lässt, was bei zusammengesetzten oder abgeschwächten Sätzen nicht gelingt. Die Zerlegung ist selbst ein modellvermittelter Schritt, der irren kann. Und die Aggregation als einfacher Anteil behandelt eine triviale ungestützte Nebenbemerkung genauso wie eine ungestützte zentrale Schlussfolgerung. Alternativen sind satzweise Bewertung, wie sie etwa FineSurE verwendet @Song2024, und verteilungsbasierte Ansätze, die mit den Ausgabewahrscheinlichkeiten arbeiten und daher Zugang zum Modell voraussetzen @haindl2027research.

=== Faithfulness und Groundedness

#definition(titel: [Faithfulness nach RAGAS])[
  Sei $C_"resp"$ die Menge der aus der Antwort extrahierten Aussagen. Dann ist
  $ "Faithfulness" = abs({c in C_"resp" : c "ist aus dem abgerufenen Kontext ableitbar"}) / abs(C_"resp") $ <k09-eq-faith>
  mit Wertebereich $[0, 1]$, höher ist besser @ragas2026faithfulness.
]

Die RAGAS-Dokumentation beschreibt drei Schritte: Aussagen identifizieren, für jede prüfen, ob sie aus dem Kontext ableitbar ist, teilen. Ihr Beispiel: Kontext "Einstein was born on 14 March 1879"; Antwort "Einstein was born in Germany on 20th March 1879". Die Antwort enthält zwei Aussagen (Geburtsland und Geburtsdatum); das Datum widerspricht dem Kontext, gestützt ist eine von zwei, also 0.5 @ragas2026faithfulness. Eine Variante `FaithfulnesswithHHEM` ersetzt das LLM-Urteil durch Vectaras T5-basierten Halluzinationsklassifikator HHEM-2.1-Open @ragas2026faithfulness. Die Definition im ursprünglichen RAGAS-Paper hat dieselbe Funktionsform, $F = abs(V) slash abs(S)$ mit den aus der Antwort extrahierten Aussagen $S$ und den vom LLM als gestützt beurteilten $V$ @es2024ragas.

DeepEval verwendet dieselbe Formel, aber ein anderes Kriterium @deepeval2026faithfulness:

$ "Faithfulness"_"DeepEval" = "wahrhaftige Aussagen" / "alle Aussagen" $ <k09-eq-faith-de>

Eine Aussage gilt als wahrhaftig, wenn sie keinen Fakten im Abrufkontext _widerspricht_. Das ist ein schwächeres Kriterium als das RAGAS-Kriterium "ableitbar": Eine ungestützte, aber nicht widersprochene Aussage besteht in DeepEval, es sei denn, man setzt `penalize_ambiguous_claims=True` @deepeval2026faithfulness. Voreinstellungen laut Dokumentation (Stand: 11. November 2026): Schwelle 0.5, Richtermodell `gpt-5.4`, `strict_mode=False` @deepeval2026faithfulness.

TruLens nennt die verwandte Größe Groundedness und geht wieder anders vor @trulens2026providers: Die Antwort wird in Sätze zerlegt, triviale Aussagen werden entfernt, jede verbleibende Aussage bekommt mit Chain-of-Thought ein LLM-Rating auf einer Skala von 0 bis 3 (Voreinstellung `min_score_val=0`, `max_score_val=3`), das auf 0 bis 1 normiert und gemittelt wird. Und: "Abstentions will be considered as grounded" @trulens2026providers. Ein System, das sich zu antworten weigert, gilt also als vollständig gestützt.

#beispiel(titel: [TruLens-Groundedness aus Ratings])[
  Eine Antwort habe nach dem Entfernen trivialer Sätze drei Aussagen mit den Ratings 3, 2 und 3 auf der Skala 0 bis 3. Normiert: $1; 0.667; 1$. Groundedness $= (1 + 0.667 + 1) slash 3 = 0.889$. Eine Antwort "Dazu liegen mir keine Informationen vor" erhält 1.0. Ein binäres Kriterium wie bei RAGAS hätte die mittlere Aussage entweder als gestützt (Ergebnis 1.0) oder als nicht gestützt (0.667) gezählt; die Skala erzeugt Zwischenwerte, deren Bedeutung vom Prompt des Richters abhängt.
]

#merke[Faithfulness heißt in RAGAS "ableitbar", in DeepEval "nicht widersprochen", in TruLens "auf einer Skala 0 bis 3 gestützt, Enthaltung zählt als gestützt". Das sind drei verschiedene Konstrukte unter fast demselben Namen. Ein Bericht muss Werkzeug, Version, Richtermodell und, wo vorhanden, Modus und Parameter nennen.]

=== Answer Relevancy: Ähnlichkeit oder Aussagenanteil

Die Relevanz der Antwort für die Frage misst RAGAS mit einem indirekten Trick @ragas2026answerrelevancy: Ein LLM generiert aus der Antwort $N$ Fragen, auf die diese Antwort passen würde, und man misst, wie ähnlich diese Fragen der ursprünglichen Frage sind:

$ "AnswerRelevancy" = 1/N sum_(i=1)^N (E_(g_i) dot E_o) / (norm(E_(g_i)) norm(E_o)) $ <k09-eq-ar>

$E_(g_i)$ ist die Einbettung der $i$-ten generierten Frage, $E_o$ die Einbettung der Nutzereingabe, $N$ standardmäßig 3 (über den Parameter `strictness`). Der Wertebereich liegt meist zwischen 0 und 1, ist es aber nicht garantiert, weil Kosinusähnlichkeiten negativ sein können. Die Metrik misst Ausrichtung auf die Frage "without evaluating factual accuracy" und bestraft unvollständige oder aufgeblähte Antworten @ragas2026answerrelevancy. Die Intuition: Eine Antwort, die vom Thema abschweift, erzeugt Rückfragen zu anderen Themen; eine Antwort, die nur einen Teil der Frage beantwortet, erzeugt Rückfragen, die nur diesen Teil abdecken. Ergeben die drei generierten Fragen etwa Kosinusähnlichkeiten von 0.91, 0.87 und 0.62, ist der Wert 0.80; der dritte, abweichende Wert zieht ihn deutlich nach unten. Im RAGAS-Paper ist die Form dieselbe, $"AR" = 1/n sum_i "sim"(q, q_i)$ @es2024ragas.

DeepEvals Answer Relevancy ist dagegen ein Aussagenanteil: relevante Aussagen in der Antwort durch alle Aussagen @deepeval2026answerrelevancy. Gleicher Name, andere Operationalisierung, und damit eine Gefahr für die Vergleichbarkeit, sobald Arbeiten "Answer Relevancy" ohne Werkzeug und Version berichten.

=== Context Precision, Context Recall und Context Relevancy

Context Precision wurde in @k09-retrieval als AP-Variante behandelt. Ihr Gegenstück für die Vollständigkeit ist Context Recall @ragas2026contextrecall:

$ "ContextRecall" = abs({c in C_"ref" : c "ist durch den abgerufenen Kontext gestützt"}) / abs(C_"ref") $ <k09-eq-cr>

Hier wird nicht die Antwort, sondern die _Referenzantwort_ zerlegt ($C_"ref"$), und man prüft, wie viele ihrer Aussagen im Kontext Deckung finden. Die nicht LLM-basierte Variante ist $abs("relevante abgerufene Kontexte") slash abs("Referenzkontexte")$ @ragas2026contextrecall. DeepEvals Contextual Recall ist derselbe Anteil über die Aussagen von `expected_output` @deepeval2026contextualrecall. DeepEvals Contextual Relevancy schließlich zählt Aussagen im Abrufkontext: relevante Aussagen im Kontext durch alle Aussagen im Kontext @deepeval2026contextualrelevancy.

Das ursprüngliche RAGAS-Paper hatte statt Context Precision und Recall eine satzbasierte Context Relevance: Ein LLM extrahiert aus dem Kontext die Sätze, die zur Beantwortung nötig sind, und die Metrik ist $"CR" = "Anzahl extrahierter Sätze" slash "Anzahl Sätze in" c(q)$ @es2024ragas. Die heutige Bibliothek hat diese Metrik nicht mehr. Sie bietet Context Precision und Recall sowie eine von NVIDIA beigesteuerte Context Relevance mit einem Gesamturteil auf der Skala {0, 1, 2}, zweimal beurteilt, durch 2 geteilt und gemittelt; die Dokumentation vermerkt ausdrücklich: "The original Ragas paper defines Context Relevance using sentence-level extraction" @ragas2026nvidia @ragas2026availablemetrics. Ebenfalls von NVIDIA stammen Answer Accuracy (zwei Urteile auf {0, 2, 4}, das zweite mit vertauschten Rollen von Antwort und Referenz, abgebildet auf {0; 0.5; 1} und gemittelt) und Response Groundedness (zwei Vorlagen auf {0, 1, 2}, normiert und gemittelt) @ragas2026nvidia.

=== Ende-zu-Ende: Factual Correctness und Noise Sensitivity

Factual Correctness vergleicht die Antwort aussagenweise mit der Referenz @ragas2026factualcorrectness:

$ P = "TP" / ("TP" + "FP"), quad R = "TP" / ("TP" + "FN"), quad F_1 = (2 P R) / (P + R) $ <k09-eq-fc>

$"TP"$ sind Antwortaussagen, die in der Referenz vorkommen, $"FP"$ Antwortaussagen, die dort nicht vorkommen, $"FN"$ Referenzaussagen, die in der Antwort fehlen. Voreinstellung ist der Modus `f1`. Die Parameter `atomicity` und `coverage` steuern, wie fein Aussagen zerlegt werden; Werte sind daher nur bei festen Einstellungen vergleichbar @ragas2026factualcorrectness.

Noise Sensitivity misst, wie viele falsche Aussagen das System macht, wenn sein Kontext auch Rauschen enthält @ragas2026noisesensitivity:

$ "NoiseSensitivity" = "Anzahl falscher Aussagen in der Antwort" / "Anzahl aller Aussagen in der Antwort" $ <k09-eq-ns>

Niedriger ist besser. Benötigt werden Frage, Referenz, Antwort und abgerufene Kontexte. Der Modus `"irrelevant"` beschränkt die Zählung auf Fehler, die von irrelevanten Kontexten ausgelöst wurden. Im Dokumentationsbeispiel hat eine Antwort drei Aussagen, eine davon falsch: 0.333 im Standardmodus, 0.0 im Modus "irrelevant" @ragas2026noisesensitivity.

=== RAGChecker: die vollständige Aussagenmatrix

RAGChecker treibt die Zerlegung am konsequentesten voran @ru2024ragchecker. Es zerlegt sowohl die Antwort $m$ als auch die Referenzantwort $"gt"$ in Aussagen und prüft per Entailment drei Beziehungen: Antwortaussage gegen Referenz, Referenzaussage gegen Antwort, beide gegen die $k$ abgerufenen Chunks. Ein Chunk heißt relevant (r-chunk), wenn er mindestens eine Referenzaussage impliziert, sonst irrelevant (irr-chunk). Mit "$in$" für "wird impliziert von" ergeben sich @ru2024ragchecker:

$ "Precision" = abs({c_i^((m)) in "gt"}) / abs({c_i^((m))}), quad "Recall" = abs({c_i^(("gt")) in m}) / abs({c_i^(("gt"))}), quad F_1 = "harmonisches Mittel" $ <k09-eq-rc-overall>

$ "Claim Recall" = abs({c_i^(("gt")) in {"chunk"_j}}) / abs({c_i^(("gt"))}), quad "Context Precision" = abs({"r-chunk"_j}) / k $ <k09-eq-rc-ret>

$ "Faithfulness" = abs({c_i^((m)) in {"chunk"_j}}) / abs({c_i^((m))}), quad "Hallucination" = abs({c_i^((m)) in.not "gt", c_i^((m)) in.not {"chunk"_j}}) / abs({c_i^((m))}) $ <k09-eq-rc-gen1>

$ "NoiseSens"_"rel" = abs({c_i^((m)) in.not "gt", c_i^((m)) in {"r-chunk"_j}}) / abs({c_i^((m))}), \ "NoiseSens"_"irr" = abs({c_i^((m)) in.not "gt", c_i^((m)) in {"irr-chunk"_j}}) / abs({c_i^((m))}) $ <k09-eq-rc-gen2>

$ "Self-knowledge" = abs({c_i^((m)) in "gt", c_i^((m)) in.not {"chunk"_j}}) / abs({c_i^((m))}) $ <k09-eq-rc-sk>

$ "Context Utilization" = abs({c_i^(("gt")) in {"chunk"_j}, c_i^(("gt")) in m}) / abs({c_i^(("gt")) in {"chunk"_j}}) $ <k09-eq-rc-cu>

Für Noise Sensitivity, Hallucination und Self-knowledge gilt: niedriger ist besser. Extraktion und Prüfung erfolgen mit RefChecker und Llama3-70B-Instruct @ru2024ragchecker. Man beachte, dass RAGCheckers "Context Precision" mengenbasiert ist (Anteil relevanter Chunks unter den $k$ abgerufenen), anders als die rangbasierte Context Precision von RAGAS und DeepEval @ragas2026contextprecision. Der Wert der Matrix liegt darin, dass sie Fehler einer Ursache zuordnet: Eine falsche Aussage, die aus einem irrelevanten Chunk stammt, ist ein Retriever-Problem (falscher Chunk im Kontext) _und_ ein Generator-Problem (keine Filterung); eine falsche Aussage ohne jede Kontextdeckung ist eine echte Halluzination.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let w = 3.6
    let h = 1.55
    let x0 = 2.2
    let cols = ([durch relevanten \ Chunk gestützt], [durch irrelevanten \ Chunk gestützt], [von keinem Chunk \ gestützt])
    let rows = ([Aussage $in$ gt \ (korrekt)], [Aussage $in.not$ gt \ (inkorrekt)])
    let zellen = (
      ((c-teal, [korrekt, treu], [m1, m2]), (c-teal, [korrekt, treu], [-]), (c-yellow, [*Self-knowledge*], [m5])),
      ((c-red, [*NoiseSens#sub[rel]*], [-]), (c-red, [*NoiseSens#sub[irr]*], [m3]), (c-red, [*Hallucination*], [m4])),
    )
    for (j, c) in cols.enumerate() {
      content((x0 + j * w + w / 2, 0.55), text(font: "Inter", size: 7.3pt, weight: "bold")[#c])
    }
    for (i, r) in rows.enumerate() {
      content((x0 - 0.15, -i * h - h / 2), anchor: "east", text(font: "Inter", size: 7.3pt, weight: "bold")[#r])
      for j in range(3) {
        let (col, tit, bsp) = zellen.at(i).at(j)
        rect((x0 + j * w + 0.05, -i * h - 0.05), (x0 + (j + 1) * w - 0.05, -(i + 1) * h + 0.05), fill: col.lighten(85%), stroke: 0.7pt + col, radius: 0.08)
        content((x0 + j * w + w / 2, -i * h - 0.5), text(font: "Inter", size: 7.5pt, fill: col.darken(25%))[#tit])
        content((x0 + j * w + w / 2, -i * h - 1.05), text(font: "JetBrains Mono", size: 7.5pt, fill: c-dark)[#bsp])
      }
    }
    content((x0 + 1.5 * w, -2 * h - 0.45), text(font: "Inter", size: 7pt, fill: c-grey.darken(25%))[Faithfulness = linke zwei Spalten; Precision = obere Zeile; jeweils geteilt durch alle Antwortaussagen])
  }),
  caption: [Die Antwortseite der RAGChecker-Matrix. Jede Antwortaussage fällt in genau eine Zelle. Eingetragen sind die Aussagen m1 bis m5 aus dem Rechenbeispiel. Die Referenzseite (Recall, Claim Recall, Context Utilization) zählt analog die Referenzaussagen.],
) <k09-fig-ragchecker>

#beispiel(titel: [Eine Antwort, zehn Zahlen])[
  *Frage:* "Was hat sich in ISO/IEC 25010:2023 gegenüber der Ausgabe von 2011 geändert?" Der Retriever liefert $k = 3$ Chunks: c1 ist ein Ausschnitt aus dem Vorwort der Norm (safety neu, usability und portability ersetzt durch interaction capability und flexibility); c2 beschreibt, dass ISO/IEC 25059 robustness unter reliability ergänzt; c3 nennt das Erscheinungsdatum von ISO/IEC 25059. Die Fakten stammen aus @isoiec2023systems und @isoiec2023software; das Beispiel selbst ist konstruiert.

  *Referenzaussagen:* g1 safety ist neu; g2 usability wurde durch interaction capability ersetzt; g3 portability wurde durch flexibility ersetzt; g4 das Quality-in-Use-Modell wanderte in ISO/IEC 25019. c1 impliziert g1 bis g3, also ist c1 ein r-chunk; c2 und c3 implizieren keine Referenzaussage und sind irr-chunks.

  *Antwortaussagen:* m1 safety ist neu ($in$ gt, $in$ c1); m2 usability -> interaction capability ($in$ gt, $in$ c1); m3 robustness ist ein Teilmerkmal von reliability ($in.not$ gt, $in$ c2); m4 das Modell hat neun Merkmale ($in.not$ gt, in keinem Chunk); m5 Quality in Use -> ISO/IEC 25019 ($in$ gt, in keinem Chunk).

  *RAGChecker:* Precision $= 3 slash 5 = 0.600$ (m1, m2, m5); Recall $= 3 slash 4 = 0.750$ (g1, g2, g4 in der Antwort); $F_1 = 2 dot 0.6 dot 0.75 slash 1.35 = 0.667$. Claim Recall $= 3 slash 4 = 0.750$ (g1 bis g3 im Kontext); Context Precision $= 1 slash 3 = 0.333$. Faithfulness $= 3 slash 5 = 0.600$ (m1 bis m3); Hallucination $= 1 slash 5 = 0.200$ (m4); $"NoiseSens"_"rel" = 0$; $"NoiseSens"_"irr" = 1 slash 5 = 0.200$ (m3); Self-knowledge $= 1 slash 5 = 0.200$ (m5); Context Utilization $= 2 slash 3 = 0.667$ (g1 und g2 von den drei im Kontext gedeckten Referenzaussagen kommen in der Antwort an, g3 nicht).

  *RAGAS:* Faithfulness $= 3 slash 5 = 0.600$; Context Recall $= 3 slash 4 = 0.750$; Factual Correctness mit $"TP" = 3$, $"FP" = 2$, $"FN" = 1$: $P = 0.600$, $R = 0.750$, $F_1 = 0.667$.

  *DeepEval:* Keine der fünf Aussagen widerspricht dem Kontext, also Faithfulness $= 5 slash 5 = 1.000$ in der Voreinstellung.
]

Das Beispiel enthält zwei Lektionen, die man im Hörsaal ausspielen sollte. Die erste: m4 ist wahr, denn ISO/IEC 25010:2023 hat tatsächlich neun Merkmale @isoiec2023systems. RAGChecker zählt die Aussage trotzdem als Halluzination, weil sie weder in der Referenz noch im Kontext steht. Das ist kein Fehler der Metrik, sondern ihre Definition: Sie misst Treue, nicht Faktizität. Die zweite: m3 erscheint als "treu", weil die atomare Aussage "robustness ist ein Teilmerkmal von reliability" von c2 impliziert wird. Im Satzzusammenhang der Antwort ("in der neuen Ausgabe gibt es außerdem robustness") ist sie aber eine Fehlzuschreibung, denn robustness gehört zu ISO/IEC 25059, nicht zu 25010. Die Zerlegung in kontextfreie Aussagen kann also eine falsche Verknüpfung als gestützt erscheinen lassen. Und DeepEvals 1.0 zeigt, wie viel das Urteilskriterium ausmacht.

=== Zitationen: ALCE

Viele RAG-Systeme sollen ihre Aussagen mit Belegen versehen, und gerade für forschungsunterstützende Systeme ist das die wichtigste Eigenschaft. ALCE ist der erste Benchmark zur automatischen Bewertung von LLM-Zitationen, mit Metriken für Flüssigkeit, Korrektheit und Zitationsqualität @gao2023enabling. Die Zitationsmetriken sind so definiert @gao2023enabling:

#definition(titel: [Zitations-Recall und -Precision nach ALCE])[
  Eine Antwort bestehe aus Aussagen $s_1, dots, s_n$, jede mit einer (möglicherweise leeren) Menge zitierter Passagen $C_i$. Ein NLI-Modell $phi(p, s) in {0, 1}$ entscheidet, ob Prämisse $p$ die Aussage $s$ impliziert.
  - *Zitations-Recall* von $s_i$ ist 1 genau dann, wenn $C_i != emptyset$ und $phi("concat"(C_i), s_i) = 1$. Der Recall der Antwort ist der Mittelwert über alle Aussagen.
  - Eine Zitation $c in C_i$ heißt *irrelevant*, wenn sie allein $s_i$ nicht stützt _und_ ihre Entfernung die Stützung durch die übrigen nicht beeinträchtigt: $phi(c, s_i) = 0$ und $phi("concat"(C_i without {c}), s_i) = 1$.
  - *Zitations-Precision* einer Zitation $c in C_i$ ist 1 genau dann, wenn $s_i$ Zitations-Recall 1 hat und $c$ nicht irrelevant ist. Die Precision der Antwort ist der Mittelwert über alle Zitationen.
]

Als NLI-Modell verwendet ALCE TRUE (T5-11B). Die Korrektheit ist datensatzspezifisch: Exact-Match-Recall kurzer Antworten (ASQA), Recall-5 (QAMPARI, 100 %, wenn mindestens 5 richtige Antworten genannt werden) und Claim-Recall gegen drei von einem LLM erzeugte Teilaussagen (ELI5) @gao2023enabling. Der zentrale Befund: Auf ELI5 fehlt selbst den besten Modellen "complete citation support 50% of the time" @gao2023enabling.

#beispiel(titel: [Zitations-Recall und -Precision])[
  Die Antwort aus dem vorigen Beispiel werde mit Zitationen ausgegeben:
  - $s_1$: "safety ist neu \[c1\]". c1 impliziert $s_1$: Recall 1; Zitation c1 relevant: Precision 1.
  - $s_2$: "usability wurde durch interaction capability ersetzt \[c1\]\[c2\]\[c3\]". Die Verkettung impliziert $s_2$: Recall 1. c1 allein stützt $s_2$; c2 und c3 stützen allein nicht, und ohne sie bleibt die Stützung durch c1 erhalten, also sind c2 und c3 irrelevant: Precision 1, 0, 0.
  - $s_3$: "Quality in Use wanderte in ISO/IEC 25019" ohne Zitation: Recall 0.
  - $s_4$: "robustness gehört zu reliability \[c2\]": c2 impliziert $s_4$: Recall 1, Precision 1.

  Zitations-Recall $= 3 slash 4 = 0.75$. Zitations-Precision über alle fünf Zitationen $= (1 + 1 + 0 + 0 + 1) slash 5 = 0.60$. Das Muster "alles zitieren, was abgerufen wurde" erhält also guten Recall bei schlechter Precision, und genau das soll die Precision aufdecken.
]

Zitationsmetriken lassen sich unmittelbar dem ISO/IEC-25059-Teilmerkmal transparency zuordnen: Sie messen, ob die für eine Prüfung nötige Information an die Nutzenden weitergegeben wird. Eine Grenze hat das Verfahren: Das NLI-Modell kann teilweise Stützung nicht erkennen und liefert daher eine niedrigere Precision als menschliche Beurteilende @gao2023enabling.

=== Nuggets: Recall für generierten Text

Precision-artige Metriken (Faithfulness, FActScore) sagen nichts darüber, ob die Antwort _vollständig_ ist. FActScore misst ausdrücklich nur Precision und braucht eine verlässliche Wissensquelle @min2023factscore. Die IR-Gemeinschaft hat für die Vollständigkeit generierter Antworten die Nugget-Evaluation etabliert. Im RAG-Track von TREC 2024 werden aus relevanten Dokumenten atomare "Nuggets" extrahiert, als _vital_ oder _okay_ markiert, und eine Antwort wird nach dem Anteil der Nuggets bewertet, den sie stützt; der AutoNuggetizer automatisiert Erstellung und Zuordnung mit einem LLM @pradeep2025great:

$ A_"strict" = 1/abs(N) sum_(i in N) p_i, quad V_"strict" = 1/abs(N_"vital") sum_(i in N_"vital") p_i $ <k09-eq-nugget>

$N$ ist die Menge der Nuggets zum Thema, $N_"vital"$ die der vitalen, und $p_i = 1$ nur bei der Zuordnung "support" (die Labels sind support, partial_support, not_support). Der Score eines Laufs ist der Mittelwert über die Themen, $V_"strict"$ ist die primäre Metrik. Die automatische Variante verwendet GPT-4o, erzeugt bis zu 30 Nuggets und behält die 20 wichtigsten @pradeep2025great.

#beispiel(titel: [Nugget-Scores])[
  Zur ISO-Frage gebe es sechs Nuggets: n1 safety neu (vital), n2 usability -> interaction capability (vital), n3 portability -> flexibility (vital), n4 Quality in Use -> 25019 (okay), n5 Leitfaden -> 25002 (okay), n6 neun Merkmale (okay). Die Antwort erhält: n1 support, n2 support, n3 not_support, n4 support, n5 not_support, n6 partial_support.

  $V_"strict" = (1 + 1 + 0) slash 3 = 0.667$. $A_"strict" = (1 + 1 + 0 + 1 + 0 + 0) slash 6 = 0.500$. Die teilweise Stützung von n6 zählt in der strengen Variante nicht. Hier wird m4 aus dem vorigen Beispiel, dort eine "Halluzination", zu einem (teilweise) erfüllten Nugget: Nugget-Recall und Faithfulness messen unterschiedliche Konstrukte.
]

=== Bewertungsregeln mit eingebauter Präferenz: CRAG und TRACe

Manche Benchmarks kodieren eine Qualitätspräferenz direkt in die Bewertungsregel. CRAG bewertet jede Antwort als perfekt (1), akzeptabel (0.5), fehlend (0) oder falsch (-1); Truthfulness ist der Mittelwert über den Evaluationsdatensatz @yang2024crag. Halluzinierte Antworten werden damit bestraft, und eine Enthaltung ("fehlend") ist einer falschen Antwort vorzuziehen. In der automatischen Bewertung werden perfekt und akzeptabel zu "korrekt" (1) zusammengefasst, und Truthfulness ist dann Genauigkeit minus Halluzinationsrate @yang2024crag.

#beispiel(titel: [Truthfulness nach CRAG])[
  Von 100 Fragen beantworte ein System 55 korrekt, enthalte sich bei 25 und antworte bei 20 falsch. Automatische Truthfulness $= (55 dot 1 + 25 dot 0 + 20 dot (-1)) slash 100 = 0.35 = 0.55 - 0.20$. Ein zweites System, das bei denselben 25 Fragen rät und davon 5 richtig trifft, kommt auf $(60 - 40) slash 100 = 0.20$: höhere Genauigkeit (0.60), schlechtere Truthfulness.
]

RAGBench definiert mit TRACe vier spannenbasierte Größen @friel2024ragbench. Mit $R_i$ den relevanten und $U_i$ den genutzten Spannen des abgerufenen Dokuments $d_i$ ist Relevance $= sum_i "Len"(R_i) slash sum_i "Len"(d_i)$, Utilization $= sum_i "Len"(U_i) slash sum_i "Len"(d_i)$ und Completeness $= "Len"(R_i inter U_i) slash "Len"(R_i)$; Adherence ist auf Beispielebene boolesch und genau dann wahr, wenn jeder Teil der Antwort durch den Kontext gestützt ist @friel2024ragbench. Für eine Abschlussarbeit ist TRACe vor allem als Idee interessant: Spannenannotationen machen sichtbar, _welcher_ Teil des Kontexts genutzt wurde.

=== Gleiche Namen, verschiedene Konstrukte

@k09-tab-namen fasst die Abweichungen zusammen. Sie sind kein Randproblem, sondern betreffen die meistzitierten Metriken.

#figure(kind: table, supplement: [Tab.],
  table(columns: (auto, 1fr, 1fr),
    [Name], [Variante A], [Variante B],
    [Faithfulness], [RAGAS: Anteil aus dem Kontext *ableitbarer* Aussagen @ragas2026faithfulness], [DeepEval: Anteil *nicht widersprochener* Aussagen @deepeval2026faithfulness; TruLens: Rating 0 bis 3, Enthaltung = gestützt @trulens2026providers],
    [Answer Relevancy], [RAGAS: mittlere Kosinusähnlichkeit generierter Fragen zur Frage @ragas2026answerrelevancy], [DeepEval: Anteil relevanter Aussagen @deepeval2026answerrelevancy],
    [Context Precision], [RAGAS, DeepEval: rangbasiert, AP mit Nenner $h_K$ @ragas2026contextprecision @deepeval2026contextualprecision], [RAGChecker: mengenbasiert, Anteil relevanter Chunks unter $k$ @ru2024ragchecker],
    [Context Relevance], [RAGAS-Paper: Anteil benötigter Sätze @es2024ragas], [RAGAS-Bibliothek (NVIDIA): ein Gesamturteil auf {0, 1, 2} @ragas2026nvidia; TruLens: Rating je Chunk @trulens2026ragtriad],
    [Urteilskriterium], ["ableitbar" (RAGAS), Entailment per NLI (ALCE, RAGChecker)], ["widerspricht nicht" (DeepEval)],
  ),
  caption: [Gleichnamige Metriken mit verschiedenen Operationalisierungen.],
) <k09-tab-namen>

#hoersaal([Wenn alle Werkzeuge etwas anderes messen, welches ist dann das richtige?], [Keines ist "richtig" im absoluten Sinn. Die Frage ist, welches Konstrukt du für deinen Einsatzzweck brauchst. Soll dein System nur sagen, was belegt ist, etwa bei einer Literaturassistenz, dann ist "ableitbar" das passende Kriterium, und DeepEvals Voreinstellung ist zu großzügig. Willst du nur grobe Widersprüche fangen, reicht "widerspricht nicht". Entscheidend ist, dass du das Kriterium bewusst wählst, begründest und an einer menschlich beurteilten Stichprobe prüfst, ob der Richter es so anwendet, wie du denkst.])

#hoersaal([Kann ich nicht einfach BLEU oder ROUGE gegen die Referenzantwort rechnen? Das ist deterministisch und billig.], [Deterministisch ja, aber für die Frage, ob eine Antwort stimmt und belegt ist, kaum aussagekräftig. RAGAS unterscheidet LLM-basierte Metriken von nicht LLM-basierten wie String-Ähnlichkeit oder BLEU und beschreibt letztere als schwächer mit menschlichen Urteilen korreliert; das ist allerdings eine Herstelleraussage @ragas2026overview. Das Lehrbuch argumentiert grundsätzlicher: Eine gute Paraphrase der Quelle schneidet bei lexikalischer Überdeckung schlecht ab und ist trotzdem vollkommen treu, die billige Metrik würde also aktiv in die Irre führen @haindl2027research. Als zusätzliche, reproduzierbare Kontrollgröße darf eine lexikalische Metrik mitlaufen, als Hauptmaß nicht.])

== Frameworks: Was die Werkzeuge tatsächlich rechnen <k09-frameworks>

Die Metriken aus @k09-generierung kommen in der Praxis selten einzeln, sondern als Teil eines Frameworks: einer Forschungsmethode mit Paper und Validierung oder einer Bibliothek mit Dokumentation und Versionsnummer. Beides ist nicht dasselbe. Ein Paper validiert eine Metrik in einer bestimmten Form, mit einem bestimmten Richtermodell, auf einem bestimmten Datensatz; eine Bibliothek gleichen Namens entwickelt sich danach weiter. Dieser Abschnitt stellt die wichtigsten Frameworks vor und legt den Schwerpunkt darauf, was Paper und Bibliothek jeweils belegen.

=== RAGAS: das Paper

Das RAGAS-Paper (EACL 2024, System Demonstrations) schlägt eine referenzfreie Evaluation von RAG-Pipelines entlang Faithfulness, Answer Relevance und Context Relevance vor, alle durch Prompting eines LLM berechnet, ohne menschliche Referenzannotationen @es2024ragas. Validiert wurde auf WikiEval: 50 Fragen zu 50 Wikipedia-Seiten über Ereignisse seit Anfang 2022, Antworten von ChatGPT generiert. Zwei Annotierende fällten paarweise Urteile je Dimension mit etwa 95 % Übereinstimmung (Faithfulness, Context Relevance) bzw. etwa 90 % (Answer Relevance); alle Prompts liefen mit gpt-3.5-turbo-16k, die Einbettungen mit text-embedding-ada-002 @es2024ragas.

#studie(titel: [Es et al. 2024 (RAGAS)])[
  *Design:* Paarweise Genauigkeit gegen menschliche Urteile: Anteil der WikiEval-Paare, in denen die Metrik dieselbe Antwort bzw. denselben Kontext bevorzugt wie die Annotierenden @es2024ragas. \
  *Befund (Tab. 4 der EACL-Fassung):* RAGAS 0.95 / 0.78 / 0.70 (Faithfulness / Answer Relevance / Context Relevance) gegenüber GPT Score 0.72 / 0.52 / 0.63 und GPT Ranking 0.54 / 0.40 / 0.52 @es2024ragas[Tab. 4]. In der arXiv-Fassung v1 stehen dieselben Werte in Tabelle 1. \
  *Grenzen:* 50 Fragen; die paarweisen Kontraste wurden von den Autoren konstruiert (etwa Antworten mit und ohne Kontext); ein einziges Richtermodell; die Validierung stammt von den Entwicklern selbst. Context Relevance in der damaligen Form ist in der Bibliothek nicht mehr enthalten.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let daten = (
      ([Faithfulness], (0.95, 0.72, 0.54), ("0.95", "0.72", "0.54")),
      ([Answer Relevance], (0.78, 0.52, 0.40), ("0.78", "0.52", "0.40")),
      ([Context Relevance], (0.70, 0.63, 0.52), ("0.70", "0.63", "0.52")),
    )
    let farben = (c-teal, c-blue, c-grey)
    let namen = ([RAGAS], [GPT Score], [GPT Ranking])
    let sy = 4.0
    let bw = 0.62
    line((0, 0), (12.2, 0), stroke: 0.7pt + c-dark)
    for v in (0.25, 0.5, 0.75, 1.0) {
      line((0, v * sy), (12.2, v * sy), stroke: (paint: luma(225), thickness: 0.4pt))
      content((-0.15, v * sy), anchor: "east", text(font: "Inter", size: 7pt)[#("0.25", "0.50", "0.75", "1.00").at(int(v * 4) - 1)])
    }
    line((0, 0.5 * sy), (12.2, 0.5 * sy), stroke: (paint: c-red, thickness: 0.7pt, dash: "dashed"))
    content((12.25, 0.5 * sy), anchor: "west", text(font: "Inter", size: 6.5pt, fill: c-red)[Zufall])
    for (g, (lab, werte, etik)) in daten.enumerate() {
      let x0 = 0.6 + g * 4.0
      for (j, v) in werte.enumerate() {
        let x = x0 + j * (bw + 0.12)
        rect((x, 0), (x + bw, v * sy), fill: farben.at(j).lighten(10%), stroke: none)
        content((x + bw / 2, v * sy + 0.18), text(font: "Inter", size: 6.6pt)[#etik.at(j)])
      }
      content((x0 + 1.1, -0.35), text(font: "Inter", size: 7.5pt, weight: "bold")[#lab])
    }
    for (j, n) in namen.enumerate() {
      rect((0.6 + j * 2.6, -1.05), (0.9 + j * 2.6, -0.8), fill: farben.at(j), stroke: none)
      content((1.0 + j * 2.6, -0.93), anchor: "west", text(font: "Inter", size: 7pt)[#n])
    }
  }),
  caption: [Paarweise Übereinstimmung mit menschlichen Urteilen auf WikiEval (50 Fragen) nach Tabelle 4 der EACL-Fassung @es2024ragas. Bei paarweisen Vergleichen liegt die Zufallsrate bei 0.5. Faithfulness schneidet deutlich besser ab als die beiden Relevanzmaße.],
) <k09-fig-ragas>

Wie stark ist eine Validierung mit $n = 50$? Eine einfache Überlegung gibt einen Anhaltspunkt. Für einen Anteil $hat(p)$ aus $n$ unabhängigen Paaren ist der Standardfehler $sqrt(hat(p)(1 - hat(p)) slash n)$. Bei $hat(p) = 0.70$ und $n = 50$ ergibt das $sqrt(0.21 slash 50) = 0.065$, ein 95-%-Wald-Intervall reicht also ungefähr von 0.57 bis 0.83. Für Faithfulness mit $hat(p) = 0.95$ ist die Normalapproximation am Rand unzuverlässig, die Größenordnung der Unsicherheit bleibt aber einige Prozentpunkte. Die Unterschiede zwischen RAGAS und den Vergleichsmethoden sind teils größer als diese Unsicherheit, teils nicht: Für Context Relevance (0.70 gegenüber 0.63) würde man auf dieser Basis keinen Unterschied behaupten.

=== RAGAS: die Bibliothek

Die Bibliothek (aktuell 0.4.3, veröffentlicht am 13. Jänner 2026, Apache-2.0; Stand: 11. November 2026) ist inzwischen viel mehr als das Paper @ragas2026pypi @ragas2026releases. Ihr Metrikkatalog umfasst RAG-Metriken (Context Precision, Context Recall, Context Entities Recall, Noise Sensitivity, Response Relevancy, Faithfulness, multimodale Varianten), die NVIDIA-Metriken, Metriken für Agenten und Werkzeugnutzung (Topic Adherence, Tool Call Accuracy, Tool Call F1, Agent Goal Accuracy), Vergleichsmetriken für natürliche Sprache (Factual Correctness, Semantic Similarity, String-Ähnlichkeit, BLEU, chrF, ROUGE, Exact Match), SQL-Metriken, allgemeine Rubriken und Zusammenfassungsmetriken @ragas2026availablemetrics. RAGAS unterscheidet LLM-basierte Metriken, die "somewhat non-deterministic" sind, von nicht LLM-basierten @ragas2026overview.

Eine Prüfung von Paper und aktueller Dokumentation nebeneinander ergibt @k09-tab-paper-lib. Faithfulness behält die Funktionsform des Papers (gestützte Aussagen durch alle Aussagen), Answer Relevancy die Form der mittleren Kosinusähnlichkeit mit $N = 3$ als Voreinstellung. Während das Paper aber mit gpt-3.5-turbo-16k und text-embedding-ada-002 validiert wurde, überlässt die Bibliothek die Wahl von Richter- und Einbettungsmodell den Nutzenden. Context Precision, Context Recall, Noise Sensitivity, Factual Correctness und die NVIDIA-Metriken haben im Paper kein Gegenstück und wurden auf WikiEval nicht validiert @es2024ragas @ragas2026faithfulness @ragas2026answerrelevancy @ragas2026availablemetrics.

#figure(kind: table, supplement: [Tab.],
  table(columns: (auto, 1fr, 1fr),
    [Metrik], [Paper (EACL 2024)], [Bibliothek 0.4.x (Stand: 11. November 2026)],
    [Faithfulness], [$abs(V) slash abs(S)$, gpt-3.5-turbo-16k, validiert (0.95)], [gleiche Form, "claims"; Richter frei wählbar; Variante mit HHEM-2.1-Open],
    [Answer Relevancy], [mittlere Kosinusähnlichkeit, ada-002, validiert (0.78)], [gleiche Form, $N = 3$ via `strictness`; Einbettung frei wählbar],
    [Context Relevance], [Anteil benötigter Sätze, validiert (0.70)], [entfernt; NVIDIA-Variante mit Gesamturteil {0, 1, 2}],
    [Context Precision / Recall], [nicht vorhanden], [vorhanden, LLM-, Nicht-LLM- und ID-Varianten; nicht im Paper validiert],
    [Noise Sensitivity, Factual Correctness], [nicht vorhanden], [vorhanden; nicht im Paper validiert],
  ),
  caption: [RAGAS: Paper und Bibliothek im Vergleich @es2024ragas @ragas2026faithfulness @ragas2026answerrelevancy @ragas2026nvidia @ragas2026availablemetrics.],
) <k09-tab-paper-lib>

Die Konsequenz ist klar formuliert: Die Ergebnisse des Papers validieren nicht jede Metrik, die heute den Namen RAGAS trägt. Hinzu kommt die API-Entwicklung. Die alte Metrik-API "will be deprecated in version 0.4 and removed in 1.0"; empfohlen werden die neuen kollektionsbasierten Klassen wie `AnswerRelevancy` @ragas2026answerrelevancy. Ergebnisse über Versionen hinweg sind deshalb nicht automatisch vergleichbar. Und eine Sicherheitsdatenbank führt die Release-Liste von RAGAS mit dem Hinweis "Has known vulnerabilities" und markiert die Versionen 0.3.4 bis 0.3.7 einschließlich der Release Candidates als "Not secure" @safetycli2026ragas. Für ein Security-Institut ist das kein Detail: Evaluationswerkzeuge laufen mit Zugriff auf Daten und API-Schlüssel.

#fallstrick[Die Dokumentation der Bibliothek wird gelegentlich mit Aussagen zitiert, die dort nicht stehen. Ein Beispiel: Es wird verbreitet berichtet, die Implementierung von Answer Relevancy setze den Wert für ausweichende (_noncommittal_) Antworten auf null. Auf der aktuellen Dokumentationsseite steht das nicht, und im Quellcode wurde es für dieses Buch nicht geprüft. Wer sich darauf stützen will, muss es im Quellcode der gepinnten Version nachsehen.]

=== ARES: kleine Richter und Prediction-Powered Inference

ARES verfolgt einen anderen Weg @saadfalcon2024ares. Statt ein großes LLM per Prompt urteilen zu lassen, erzeugt es synthetische Trainingsdaten und trainiert kleine Klassifikatoren. FLAN-T5 XXL generiert synthetische Fragen und Antworten mit schwachen und starken Negativbeispielen; DeBERTa-v3-Large wird zu Richtern für Context Relevance, Answer Faithfulness und Answer Relevance feinjustiert. Den entscheidenden Schritt bildet die Kombination mit Prediction-Powered Inference (PPI), die Kapitel 6 ausführlich behandelt: Ein kleiner menschlich annotierter Validierungsdatensatz (etwa 150 oder mehr Datenpunkte, in den Hauptexperimenten 300) korrigiert die Verzerrung des Richters und liefert Konfidenzintervalle @saadfalcon2024ares. Systeme werden nach den Mittelpunkten ihrer 95-%-Intervalle gereiht.

Zur Erinnerung die Form des PPI-Mittelwertschätzers @angelopoulos2023prediction: Sind $f(tilde(X)_i)$ die Richterurteile auf $N$ nur maschinell bewerteten Ausgaben und $(f(X_i), Y_i)$ Richter- und Menschenurteil auf $n$ doppelt bewerteten, dann ist

$ hat(theta)_"PP" = 1/N sum_(i=1)^N f(tilde(X)_i) - 1/n sum_(i=1)^n (f(X_i) - Y_i) $ <k09-eq-ppi>

$ C_"PP" = hat(theta)_"PP" plus.minus z_(1 - alpha slash 2) sqrt(hat(sigma)^2_(f - Y) / n + hat(sigma)^2_f / N) $ <k09-eq-ppi-ci>

mit der Varianz $hat(sigma)^2_f$ der Richterurteile auf dem unannotierten Teil, der Varianz $hat(sigma)^2_(f - Y)$ des Korrekturterms (_rectifier_) auf dem annotierten Teil und dem Normalquantil $z_(1 - alpha slash 2)$ (1.96 für 95 %). Das Intervall ist asymptotisch gültig @angelopoulos2023prediction. Die Abschnitts- und Satznummern beziehen sich auf die arXiv-Fassung v4; veröffentlicht ist die Arbeit in _Science_. @k09-validitaet rechnet ein Beispiel durch.

#studie(titel: [Saad-Falcon et al. 2024 (ARES)])[
  *Design:* KILT (NQ, HotpotQA, FEVER, WoW), SuperGLUE (MultiRC, ReCoRD), AIS (WoW, CNN/DM); simulierte RAG-Systeme mit Erfolgsraten von 70 bis 90 % in Schritten von 2.5 Punkten; Gütemaß ist Kendalls $tau$ zwischen der von der Metrik erzeugten und der wahren Systemrangfolge @saadfalcon2024ares. \
  *Befund:* $tau$ im Mittel 0.065 höher als RAGAS für Context Relevance und 0.132 höher für Answer Relevance, etwa 0.06 höher als ein GPT-3.5-Richter mit wenigen Beispielen @saadfalcon2024ares[Tab. 1]. Mit 300 Labels $tau$ um 0.08 höher als eine reine Stichprobenannotation mit 1350 Labels (78 % weniger Annotationen). Unter etwa 100 bis 150 PPI-Labels lassen sich Systeme nicht zuverlässig unterscheiden @saadfalcon2024ares[Tab. 3]. Ersetzt man menschliche Labels durch GPT-4-Labels, sinkt $tau$ in den meisten Konfigurationen um 0.05 bis 0.30 @saadfalcon2024ares[Tab. 4]. Auf realen RAG-Systemen im Mittel $tau = 0.91$ (Context Relevance) und $0.97$ (Answer Relevance). Bei großen Domänenverschiebungen versagt der Transfer: $tau$ 0.33 (XGLUE), 0.28 (CodeSearchNet), 0.38 (T-Rex) @saadfalcon2024ares. \
  *Grenzen:* braucht domäneninterne Passagen und einen annotierten Validierungsdatensatz; beim Lesen fallen interne Unstimmigkeiten auf (59.9 gegenüber 59.3 Punkten Genauigkeitsgewinn gegenüber RAGAS in Text und Einleitung; die Werte in Tabelle 5 für Answer Relevance mitteln eher zu 0.99 als zu den genannten 0.97).
]

Für eine Abschlussarbeit ist ARES vor allem als Muster wichtig: viele billige Maschinenurteile, eine kleine Zufallsstichprobe menschlicher Urteile, ein gültiges Intervall. Ob man dafür ARES selbst verwendet oder die Bibliothek `ppi_py` auf eigene Richterurteile anwendet, ist zweitrangig @angelopoulos2024ppipy. Dass GPT-4-Labels die menschlichen Labels nicht ersetzen konnten, ist ein starkes Argument, die Validierungsstichprobe wirklich von Menschen beurteilen zu lassen.

=== RAGChecker: Diagnose statt Gesamtnote

RAGChecker wurde auf acht RAG-Systemen evaluiert, die aus zwei Retrievern (BM25, E5-Mistral) und vier Generatoren (GPT-4, Mixtral-8x7B, Llama3-8B, Llama3-70B) kombiniert sind, mit 4162 Fragen aus zehn Domänen @ru2024ragchecker. Die Meta-Evaluation beruht auf 280 paarweisen Instanzen, die zwei Annotierende mit 90.95 % Übereinstimmung beurteilten.

#studie(titel: [Ru et al. 2024 (RAGChecker)])[
  *Befund (Pearson / Spearman mit menschlichen Urteilen, Tab. 2):* Korrektheit 49.66 / 46.95, Vollständigkeit 60.67 / 58.11, Gesamt 61.93 / 60.90. Stärkste Vergleichsmetrik (RAGAS Answer Similarity): 41.07 / 43.21, 53.16 / 61.35, 48.31 / 57.23. Menschliche Obergrenze (Übereinstimmung zwischen Annotierenden): 63.67 / 59.19, 71.91 / 68.36, 70.09 / 68.89 @ru2024ragchecker. Verglichen wurde auch mit BLEU, ROUGE-L, BERTScore, TruLens, ARES und CRUD-RAG. \
  *Lesart:* Der Gesamtwert liegt nahe an der menschlichen Obergrenze, bei Spearman für Vollständigkeit ist die RAGAS-Ähnlichkeit (61.35) aber sogar höher als RAGChecker (58.11). \
  *Grenzen:* Selbstvalidierung auf eigenen Annotationen; Prüfung mit einem 70B-Modell ist teuer.
]

=== eRAG: Relevanz relativ zum Generator

eRAG stellt eine Frage, die in der Retrieval-Evaluation für RAG meist übergangen wird: Relevant für wen? Klassische Relevanzurteile beschreiben, ob ein Dokument für einen Menschen zum Thema passt. Für RAG zählt aber, ob es dem Generator hilft. eRAG speist deshalb jedes abgerufene Dokument _einzeln_ in den Generator des RAG-Systems; die Metrik der nachgelagerten Aufgabe (etwa Exact Match) für diese Ausgabe wird zum Relevanzurteil des Dokuments, und diese Urteile werden mit Rangmetriken wie MAP, MRR, nDCG, Precision, Recall und Hit Ratio aggregiert @salemi2024evaluating.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let daten = (
      ([NQ], (0.492, 0.181, 0.045)),
      ([TriviaQA], (0.474, 0.142, 0.176)),
      ([HotpotQA], (0.610, 0.007, 0.034)),
      ([FEVER], (0.386, 0.026, 0.018)),
    )
    let farben = (c-teal, c-yellow, c-violet)
    let namen = ([eRAG], [KILT-Provenienz], [LLM-Urteile (Mistral 7B)])
    let sy = 5.5
    let bw = 0.6
    line((0, 0), (12.6, 0), stroke: 0.7pt + c-dark)
    for v in (0.2, 0.4, 0.6) {
      line((0, v * sy), (12.6, v * sy), stroke: (paint: luma(225), thickness: 0.4pt))
      content((-0.15, v * sy), anchor: "east", text(font: "Inter", size: 7pt)[#str(v)])
    }
    content((-0.9, 0.3 * sy), angle: 90deg, text(font: "Inter", size: 7.5pt)[Kendalls $tau$])
    for (g, (lab, werte)) in daten.enumerate() {
      let x0 = 0.5 + g * 3.1
      for (j, v) in werte.enumerate() {
        let x = x0 + j * (bw + 0.1)
        rect((x, 0), (x + bw, v * sy), fill: farben.at(j).lighten(10%), stroke: none)
        content((x + bw / 2, v * sy + 0.17), text(font: "Inter", size: 6.3pt)[#{let t = str(int(calc.round(v * 1000))); "0." + "000".slice(0, 3 - t.len()) + t}])
      }
      content((x0 + 1.0, -0.35), text(font: "Inter", size: 7.5pt, weight: "bold")[#lab])
    }
    for (j, n) in namen.enumerate() {
      rect((0.5 + j * 3.4, -1.05), (0.8 + j * 3.4, -0.8), fill: farben.at(j), stroke: none)
      content((0.9 + j * 3.4, -0.93), anchor: "west", text(font: "Inter", size: 7pt)[#n])
    }
  }),
  caption: [Kendalls $tau$ zwischen Retrieval-Bewertung (BM25, Aggregation mit MAP) und Ende-zu-Ende-Leistung nach Salemi und Zamani @salemi2024evaluating. Relevanzurteile, die aus dem Erfolg des Generators abgeleitet werden, sagen die Ende-zu-Ende-Qualität deutlich besser voraus als menschliche Provenienzurteile oder LLM-Relevanzurteile.],
) <k09-fig-erag>

#studie(titel: [Salemi und Zamani 2024 (eRAG)])[
  *Design:* KILT-Aufgaben NQ, TriviaQA, HotpotQA, FEVER, WoW; Generator T5-small mit Fusion-in-Decoder; 50 abgerufene Dokumente @salemi2024evaluating. \
  *Befund:* Mit BM25 und MAP-Aggregation erreicht eRAG $tau slash rho$ von 0.492/0.575 (NQ), 0.474/0.578 (TriviaQA), 0.610/0.694 (HotpotQA), 0.386/0.463 (FEVER); KILT-Provenienzurteile 0.181/0.218, 0.142/0.172, 0.007/0.009, 0.026/0.032; LLM-Relevanzurteile (Mistral 7B) 0.045/0.055, 0.176/0.216, 0.034/0.042, 0.018/0.022. Absolute Gewinne in $tau$ von 0.168 bis 0.494; im Mittel 2.468-mal schneller als Ende-zu-Ende-Evaluation; 4.9 GB bzw. 1.5 GB statt 75.0 GB GPU-Speicher auf NQ @salemi2024evaluating. \
  *Grenzen:* kleiner Generator; die Relevanzurteile gelten nur für genau diesen Generator; für WoW nur Precision und Hit Ratio.
]

Die Pointe von eRAG ist konzeptionell: "Relevanz" ist in RAG eine Eigenschaft des Paares aus Dokument und Generator, nicht des Dokuments allein. Ein Dokument, das ein Mensch für hoch relevant hält, kann für ein bestimmtes Modell nutzlos sein, etwa weil es die Antwort in einer Tabelle versteckt. Für eine Abschlussarbeit, die Retriever vergleicht, heißt das: Wer nur topische Relevanzurteile verwendet, misst etwas, das mit der eigentlich interessierenden Größe schwach zusammenhängt.

=== TruLens und DeepEval

TruLens (aktuell 2.16.0 vom 19. Oktober 2026, MIT-Lizenz laut Zenodo-Eintrag von 2.9.0; Stand: 11. November 2026) verbindet Tracing mit Feedback-Funktionen und hat die RAG-Triade bekannt gemacht @trulens2026releases @trulens2026zenodo @trulens2026ragtriad. Context Relevance bewertet jeden Chunk auf Relevanz zur Frage, Groundedness und Answer Relevance wie in @k09-generierung beschrieben, jeweils mit LLM-Ratings auf 0 bis 3, normiert auf 0 bis 1 @trulens2026providers. Die Dokumentation behauptet, eine Anwendung mit zufriedenstellenden Triadenwerten sei "verified to be hallucination free up to the limit of its knowledge base" @trulens2026ragtriad. Das ist eine Herstelleraussage, die Richterfehler ignoriert; Schwellen werden auf der Seite nicht genannt. Wie fehleranfällig Richter sind, zeigt @k09-validitaet.

DeepEval (aktuell 4.3.3 vom 4. November 2026, Apache-2.0; Stand: 11. November 2026) ist eine Evaluationsbibliothek im Stil von pytest @deepeval2026pypi. Die GitHub-Release-Seite markierte zum selben Zeitpunkt noch 4.2.0 als "Latest" @deepeval2026github; wer die Version nachweisen will, nimmt PyPI. Für jede Metrik gibt es drei Modi: LLM-as-a-Judge (Voreinstellung), "hybrid" (ein kleines Modell namens Jev beantwortet Ja/Nein-Fragen pro Aussage mit Wahrscheinlichkeitsschwellen) und "system_one" (Jev beantwortet drei gewichtete Fragen). Die Dokumentation warnt: "a `system_one` score comes from Jev's answers, not from the equation the LLM chain computes above, so keep a metric on one eval mode when you compare its results across runs" @deepeval2026faithfulness @deepeval2026answerrelevancy. Version 4.2.0 (August 2026) enthielt eine inkompatible Änderung: Die Bewertungslogik von BiasMetric, HallucinationMetric, MisuseMetric und ToxicityMetric wurde auf die Konvention umgestellt, "where higher scores indicate better performance" @deepeval2026changelog. Die hier behandelten RAG-Metriken sind von dieser Umstellung nicht betroffen; für die vier genannten kehren historische Werte aber ihre Bedeutung um.

#figure(kind: table, supplement: [Tab.],
  table(columns: (auto, auto, auto, 1fr),
    [Werkzeug], [Version (Stand: 11.11.2026)], [Lizenz], [Kern],
    [RAGAS], [0.4.3 (13.01.2026)], [Apache-2.0], [LLM- und Nicht-LLM-Metriken für RAG, Agenten, SQL; Testsatzgenerierung @ragas2026availablemetrics],
    [DeepEval], [4.3.3 (04.11.2026)], [Apache-2.0], [pytest-artige Evaluation; drei Modi; Faithfulness, Answer Relevancy, Contextual Precision/Recall/Relevancy @deepeval2026faithfulness],
    [TruLens], [2.16.0 (19.10.2026)], [MIT], [Tracing und Feedback-Funktionen; RAG-Triade @trulens2026ragtriad],
    [ARES], [Forschungscode], [nicht geprüft], [synthetische Daten, feinjustierte Richter, PPI @saadfalcon2024ares],
    [RAGChecker], [Forschungscode], [nicht geprüft], [aussagenbasierte Diagnose von Retriever und Generator @ru2024ragchecker],
    [eRAG], [nicht geprüft], [nicht geprüft], [generatorrelative Retrieval-Evaluation @salemi2024evaluating],
    [BERGEN], [nicht geprüft], [nicht geprüft], [reproduzierbares Ende-zu-Ende-Benchmarking @rau2024bergen],
  ),
  caption: [Evaluationswerkzeuge im Überblick @ragas2026pypi @deepeval2026pypi @trulens2026releases @trulens2026zenodo. Versionen und Voreinstellungen ändern sich schnell; vor dem Einsatz neu prüfen.],
) <k09-tab-tools>

#datei("requirements-eval.txt")[
```text
# Evaluationsumgebung, gepinnt (Stand: 11. November 2026)
ragas==0.4.3
deepeval==4.3.3
trulens==2.16.0
# Richtermodell, Datum, Temperatur und Prompt-Version
# zusätzlich in config/judge.yaml festhalten
```
]

#merke[Ein Evaluationsergebnis aus einer Bibliothek ist nur mit vier Angaben interpretierbar: Bibliotheksversion, Richtermodell mit Datum oder Version, Modus und Parameter (etwa `strictness`, `atomicity`, `penalize_ambiguous_claims`) sowie Zahl der Wiederholungen. Kapitel 10 behandelt, wie man solche Angaben in einem reproduzierbaren Workflow festhält.]

=== Ohne Goldstandard: Turniere

Gibt es weder Referenzantworten noch Relevanzurteile, bleiben paarweise Vergleiche. RAGElo reiht RAG-Varianten mit einem LLM-as-a-Judge und einem Elo-basierten Turnier @rackauckas2024evaluating. In einer industriellen Fallstudie zu Produktfragen (Infineon) korrelierten die Richterurteile moderat positiv mit Fachleuten; RAG-Fusion gewann nach Elo und Vollständigkeit, war aber weniger präzise @rackauckas2024evaluating. Paarweise Verfahren sind leichter zu beurteilen als absolute Skalen, erben aber alle Verzerrungen paarweiser Richter, die Kapitel 7 behandelt, insbesondere die Positionsverzerrung.

== Benchmarks und Robustheit <k09-benchmarks>

Ein Benchmark ist ein standardisierter Datensatz mit festgelegter Bewertungsregel. Für eine Abschlussarbeit hat er zwei Funktionen: Er erlaubt den Vergleich mit publizierten Ergebnissen, und er liefert Testfälle für Eigenschaften, an die man selbst nicht gedacht hätte. Das Lehrbuch erinnert daran, dass der Datensatz ebenso Teil der Messung ist wie die Metrik: Deckt er die Eingaben ab, die das System im Einsatz trifft? Lässt er sich über Abkürzungen lösen? Ist er frei von Kontamination @haindl2027research @Bowman2021 @Raji2021?

=== Retrieval: BEIR und MTEB

BEIR umfasst 18 englischsprachige Datensätze aus neun Retrieval-Aufgaben und verwendet nDCG\@10 @thakur2021beir. Seine Hauptbefunde sind für RAG-Arbeiten unmittelbar relevant: BM25 ist eine robuste Zero-Shot-Baseline, dichte Retriever fallen bei Domänen- oder Aufgabenverschiebung auf vielen Datensätzen unter BM25, und Re-Ranking- und Late-Interaction-Modelle schneiden am besten ab, aber zu höheren Rechenkosten @thakur2021beir. MTEB bewertet Einbettungsmodelle über acht Aufgaben, 58 Datensätze und 112 Sprachen mit 33 Modellen und stellt fest, dass "no particular text embedding method dominates across all tasks" @muennighoff2023mteb. Wer ein Einbettungsmodell nach dem Rang auf einer Bestenliste wählt, wählt also nach einer aufgabenabhängigen Größe.

#tipp[In jeder RAG-Arbeit gehört BM25 als Baseline-Retriever in den Vergleich. Es ist billig, deterministisch und nach BEIR außerhalb der Trainingsdomäne oft schwer zu schlagen @thakur2021beir. Ein dichter Retriever, der BM25 auf den eigenen Daten nicht übertrifft, rechtfertigt seine Komplexität nicht.]

=== Robustheit: RGB, CRAG und die Folgen nicht idealer Kontexte

RGB operationalisiert vier Fähigkeiten, die man als RAG-spezifische Ausprägungen der robustness aus ISO/IEC 25059 lesen kann @chen2024benchmarking: Rauschrobustheit (_noise robustness_, relevante Information inmitten irrelevanter), Ablehnung (_negative rejection_, keine Antwort, wenn der Kontext keine enthält), Informationsintegration (_information integration_, Zusammenführen aus mehreren Dokumenten) und kontrafaktische Robustheit (_counterfactual robustness_, Umgang mit falschen Informationen im Kontext). Getestet wurden sechs LLMs auf einem zweisprachigen Korpus (Englisch, Chinesisch). Befund: einige Rauschrobustheit, aber deutliche Schwächen bei Ablehnung, Integration und falschen Informationen @chen2024benchmarking. Zahlen je Fähigkeit wurden für dieses Buch nicht aus dem Paper extrahiert.

#figure(
  diagram(spacing: (5mm, 5mm),
    fknoten((1.5,0), [*Robustness* (ISO/IEC 25059) \ funktionale Korrektheit unter allen Umständen halten], col: c-teal, filled: true, w: 72mm),
    fknoten((0,1.2), [Rauschrobustheit \ #text(size: 6.8pt)[irrelevante Chunks]], col: c-blue, w: 28mm),
    fknoten((1,1.2), [Ablehnung \ #text(size: 6.8pt)[Antwort fehlt im Kontext]], col: c-blue, w: 28mm),
    fknoten((2,1.2), [Integration \ #text(size: 6.8pt)[mehrere Dokumente]], col: c-blue, w: 28mm),
    fknoten((3,1.2), [Kontrafaktik \ #text(size: 6.8pt)[falsche Information]], col: c-blue, w: 28mm),
    fknoten((0,2.4), [Noise Sensitivity, \ NoiseSens#sub[rel/irr]], col: c-grey, w: 32mm),
    fknoten((1,2.4), [Ablehnungsquote, \ CRAG: "fehlend" = 0], col: c-grey, w: 32mm),
    fknoten((2,2.4), [Recall\@k, Nuggets, \ Completeness], col: c-grey, w: 32mm),
    fknoten((3,2.4), [Konflikterkennung \ (EnterpriseRAG)], col: c-grey, w: 32mm),
    edge((1.5,0), (0,1.2), "-|>"), edge((1.5,0), (1,1.2), "-|>"), edge((1.5,0), (2,1.2), "-|>"), edge((1.5,0), (3,1.2), "-|>"),
    edge((0,1.2), (0,2.4), stroke: (dash: "dashed")), edge((1,1.2), (1,2.4), stroke: (dash: "dashed")), edge((2,1.2), (2,2.4), stroke: (dash: "dashed")), edge((3,1.2), (3,2.4), stroke: (dash: "dashed")),
  ),
  caption: [Die vier RAG-Fähigkeiten aus RGB @chen2024benchmarking als Ausprägungen von robustness nach ISO/IEC 25059 @isoiec2023software, mit passenden Messgrößen (grau). Die Zuordnung ist ein Lehrvorschlag.],
) <k09-fig-robust>

CRAG umfasst 4409 Frage-Antwort-Paare mit simulierten Web- und Wissensgraph-Such-APIs aus fünf Domänen und acht Fragekategorien @yang2024crag. Die automatische Bewertung verwendet zwei LLM-Bewerter (ChatGPT und Llama 3), um Selbstbevorzugung zu vermeiden, und erreicht F1 von 94.7 % bzw. 98.9 % gegenüber menschlicher Bewertung @yang2024crag. Die Genauigkeit sinkt bei sich schnell ändernden, weniger populären und komplexeren Fakten @yang2024crag. Die Bewertungsregel (falsch = -1, fehlend = 0) wurde in @k09-generierung besprochen; sie macht Ablehnung zu einer messbaren Tugend.

Zwei Studien zeigen, dass der Zusammenhang zwischen Retrieval-Qualität und Antwortqualität nicht monoton ist. Liu et al. finden, dass die Leistung oft am höchsten ist, wenn relevante Information am Anfang oder Ende des Kontexts steht, und in der Mitte abfällt, selbst bei Modellen mit langem Kontext @liu2024lost. Cuconasu et al. finden, dass zufällige Dokumente im Prompt die Genauigkeit um bis zu 35 % verbessern können, während hoch bewertete, aber nicht relevante Dokumente schaden @cuconasu2024power. Eine bessere Rangliste nach nDCG führt also nicht automatisch zu besseren Antworten, und ein "Rauschen"-Dokument ist nicht automatisch schädlich. Das ist ein weiteres Argument, Retriever- und Ende-zu-Ende-Metriken gemeinsam zu berichten.

#studie(titel: [Miao et al. 2026 (EnterpriseRAG, Preprint)])[
  *Design:* 983 Instanzen aus 491 realen Unternehmensanfragen in sechs Domänen; nicht ideale Retrieval-Bedingungen: verrauscht ($n = 447$), Wissenslücken ($n = 227$), Faktenkonflikte ($n = 309$); 13 LLMs @miao2026enterpriserag. \
  *Befund:* Lockere Instruktionstreue bis 83.8 %, strenge nur 26.8 %; Ablehnung unbeantwortbarer Anfragen zwischen 6.6 % (Qwen3-30B-Instruct) und 42.7 % (bestes Modell, Claude-Opus-4.5); Konflikterkennung bei allen Modellen unter 45 %. LLM-Richter gegen menschlichen Goldstandard $kappa = 0.77$ (Mensch-Mensch 0.85) @miao2026enterpriserag. \
  *Grenzen:* Preprint (Stand: 11. November 2026).
]

Ablehnung und Konfliktbehandlung, die RGB 2024 als Schwächen identifizierte, sind nach diesen Daten auch 2026 nicht gelöst. Für eine Abschlussarbeit mit einem RAG-System über interne Dokumente folgt daraus eine konkrete Designentscheidung: Der Testdatensatz braucht Fragen, deren Antwort _nicht_ im Korpus steht, und Fragen, zu denen der Korpus widersprüchliche Angaben enthält. Ohne sie bleibt FP1 aus @k09-messobjekt unentdeckt.

=== Antwortqualität im großen Maßstab: TREC RAG

Der RAG-Track von TREC 2024 hat die Nugget-Evaluation aus @k09-generierung in großem Maßstab erprobt @pradeep2025great. 301 Themen, 93 RAG-Läufe von 20 Gruppen und 53 AG-Läufe von 11 Gruppen wurden eingereicht, 31 RAG- und 14 AG-Läufe evaluiert, die Analyse beruht auf 56 vollständig beurteilten Themen; der erste Bericht umfasste 21 Themen und 45 Läufe @pradeep2024initial.

#studie(titel: [Pradeep et al. 2025 (TREC 2024 RAG, AutoNuggetizer)])[
  *Frage:* Können LLMs Nugget-Erstellung und -Zuordnung so automatisieren, dass RAG-Antworten im TREC-Maßstab bewertbar werden? @pradeep2025great \
  *Befund:* Auf Laufebene erreicht die vollautomatische Bewertung gegenüber manueller Zuordnung auf nachbearbeiteten automatischen Nuggets Kendalls $tau$ von 0.887 ($V_"strict"$) bzw. 0.901 ($A_"strict"$) auf 36 Themen, gegenüber vollständig manuellen Nuggets und Zuordnungen 0.727 bzw. 0.758 auf 20 Themen. Feiner aufgelöst ist die Übereinstimmung schwach: $tau$ über alle Thema-Lauf-Paare 0.297 bis 0.438, mittleres $tau$ pro Thema 0.360 bis 0.539. Das Verfahren ist daher "inadequate for fine-grained debugging" einzelner Antworten @pradeep2025great. \
  *Lesart:* gut für die Rangfolge von Systemen, ungeeignet für die Diagnose einzelner Antworten.
]

Der Unterschied zwischen Systemebene und Instanzebene ist eine der wichtigsten Lehren dieses Kapitels und kehrt bei ARES wieder. Ein automatisches Maß kann Systeme zuverlässig reihen, weil sich Fehler bei der Mittelung über viele Themen ausgleichen, und zugleich für eine einzelne Antwort fast nichts aussagen. Wer in einer Arbeit Fehlerfälle analysiert, darf sich dabei nicht auf ein Maß stützen, das nur auf Systemebene validiert ist.

=== Weitere Datensätze

Für die Validierung von Faithfulness-Metriken gibt es eigene Datensätze. RAGTruth enthält knapp 18 000 natürlich generierte RAG-Antworten mit Halluzinationsannotationen auf Fall- und Wortebene; ein kleines darauf feinjustiertes LLM ist mit promptbasierter GPT-4-Erkennung konkurrenzfähig @niu2024ragtruth. RAGBench umfasst etwa 100 000 Beispiele (78 000 Training, 12 000 Entwicklung, 11 000 Test) aus zwölf Datensätzen in fünf Domänen (Biomedizin, Allgemeinwissen, Recht, Kundensupport, Finanzen) mit TRACe-Labels @friel2024ragbench. BERGEN schließlich adressiert die Vergleichbarkeit: Inkonsistente Datensätze, Kollektionen, Metriken, Retriever und LLMs machen RAG-Ergebnisse schwer vergleichbar; die Bibliothek schlägt Best Practices und ein reproduzierbares Ende-zu-Ende-Setup für QA vor @rau2024bergen.

Neuere Arbeiten verschieben den Fokus auf agentische und rechercheartige Systeme. Eine Übersicht zu agentischem RAG nennt Evaluation als offene Forschungsfrage neben Koordination, Speicherverwaltung, Effizienz und Governance @singh2025agentic. Total Recall QA (TRQA) verwendet Fragen mit einer einzigen numerischen Antwort, die das Auffinden _aller_ relevanten Entitäten erfordern @rafiee2026total. BM25 erreicht dort Recall\@10 von 19.82 % auf TRQA-Wiki1; Search-R1 erzielt Exact Match 10.65 (Wiki1) und 2.55 (synthetischer E-Commerce-Datensatz); GPT-5.2 ohne Retrieval erzielt 30.18 auf Wiki1, aber nur 1.67 auf dem synthetischen Datensatz, was auf Kontamination der Wikipedia-Fragen hinweist; mit Orakel-Retrieval erreicht GPT-5.2 56.80, und die meisten verbleibenden Fehler sind Schlussfolgerungsfehler (95.9 % bei Claude Sonnet 4.5, 90.9 % bei GPT-5.2) @rafiee2026total. Die Lektion für Abschlussarbeiten: Geschlossene Fragen über Wikipedia messen leicht Gedächtnis statt Retrieval. Ein synthetischer oder nach dem Trainingsstichtag erstellter Korpus ist die bessere Kontrolle.

#hoersaal([Soll ich meine Arbeit auf einem Standard-Benchmark evaluieren oder auf eigenen Daten?], [In der Regel auf beidem, mit unterschiedlicher Funktion. Der Standard-Benchmark verankert deine Ergebnisse im Forschungsstand und zeigt, dass deine Implementierung sich vernünftig verhält. Die eigenen Daten beantworten deine eigentliche Forschungsfrage, denn kein Benchmark bildet deinen Einsatzkontext ab. Achte bei Benchmarks auf Kontamination: Wenn ein Modell ohne Retrieval schon gut abschneidet, misst der Benchmark für dieses Modell wenig über Retrieval @rafiee2026total. Und prüfe die Lizenz der Datensätze vor der Nutzung; für dieses Buch wurden sie nicht geprüft.])

== Validität automatischer Metriken <k09-validitaet>

Fast alle Generierungsmetriken dieses Kapitels sind Urteile eines Sprachmodells über Aussagen, die ein Sprachmodell extrahiert hat @ragas2026faithfulness @deepeval2026faithfulness. Damit gilt für sie alles, was Kapitel 5 über LLM-Annotation und Kapitel 7 über LLM-as-a-Judge sagt: Sie sind Messinstrumente, deren Validität empirisch gezeigt werden muss, und zwar für das konkrete Richtermodell, die konkrete Domäne und die konkrete Sprache. Das Lehrbuch nennt das grundsätzliche Problem beim Namen: Es gibt keine perfekte Grundwahrheit, menschliches Urteil ist teuer und inkonsistent, und ein starkes Modell als Richter riskiert zirkuläre Validierung, weil es dieselben blinden Flecken haben kann wie das bewertete System @haindl2027research.

=== Wie man eine Metrik validiert

Die Literatur verwendet fünf Formen der Meta-Evaluation, die verschiedene Fragen beantworten.

+ *Paarweise Genauigkeit gegen menschliche Präferenzen.* Wie oft bevorzugt die Metrik dieselbe von zwei Antworten wie Menschen? So validiert RAGAS @es2024ragas[Tab. 4].
+ *Rangkorrelation von Systemrangfolgen.* Reiht die Metrik mehrere Systeme so wie eine Referenz? ARES und eRAG verwenden Kendalls $tau$ und Spearmans $rho$ @saadfalcon2024ares @salemi2024evaluating, TREC RAG Kendalls $tau$ zwischen automatischen und manuellen Nugget-Scores auf Lauf- und Themenebene @pradeep2025great.
+ *Korrelation von Instanzwerten mit menschlichen Ratings.* RAGChecker berichtet Pearson und Spearman gegen 280 annotierte Instanzen und vergleicht mit der menschlichen Obergrenze @ru2024ragchecker.
+ *Klassifikationsgüte bei der Halluzinationserkennung.* RAGBench berichtet AUROC @friel2024ragbench, MEMERAG die balancierte Genauigkeit gegen Expertenurteile auf Satzebene @cruzblandon2025memerag.
+ *Unit-Tests für Fehlermodi.* GroUSE prüft, ob Richter 144 gezielte Tests über sieben Fehlermodi bestehen, und zeigt, dass die Korrelation mit GPT-4 ein unvollständiger Stellvertreter für Richterqualität ist @muller2025grouse.

Dazu kommt eine sechste Forderung, die quer zu allen liegt: *zufallskorrigierte Übereinstimmung.* Exakte Übereinstimmung kann Cohens $kappa$ auf MT-Bench um 33.8 bis 41.3 Prozentpunkte überschätzen @norman2026reliability; berichte $kappa$ (oder AC1) neben der rohen Übereinstimmung. Kapitel 5 behandelt zufallskorrigierte Übereinstimmungsmaße.

Die Formen sind nicht austauschbar. Rangkorrelation auf Systemebene beantwortet "Kann ich mit dieser Metrik Systeme vergleichen?", Instanzkorrelation und Klassifikationsgüte beantworten "Kann ich mit dieser Metrik einzelne Antworten beurteilen?". TREC RAG zeigt, dass beides auseinanderfallen kann @pradeep2025great.

#definition(titel: [Kendalls $tau$ für Systemrangfolgen])[
  Seien $m$ Systeme einmal nach einer Metrik und einmal nach einer Referenz gereiht. Ein Paar von Systemen heißt *konkordant*, wenn beide Rangfolgen es gleich ordnen, sonst *diskordant*. Mit $C$ konkordanten und $D$ diskordanten Paaren (ohne Bindungen) ist
  $ tau = (C - D) / binom(m, 2) $ <k09-eq-tau>
  mit $tau in [-1, 1]$; $tau = 1$ bei identischer, $tau = -1$ bei umgekehrter Rangfolge.
]

#beispiel(titel: [Kendalls $tau$])[
  Eine Metrik reiht vier RAG-Konfigurationen A > B > C > D, die menschliche Referenz A > C > B > D. Von den $binom(4, 2) = 6$ Paaren ist nur (B, C) diskordant. $tau = (5 - 1) slash 6 = 0.667$. Ein einziger Platztausch benachbarter Systeme kostet bei vier Systemen also ein Drittel der Skala. Bei wenigen Systemen ist $tau$ deshalb grob und stark vom Zufall abhängig; die $tau$-Werte von ARES und eRAG beruhen auf vielen Systemen bzw. Konfigurationen.
]

=== Was die Evidenz zeigt

Die Evidenz zur Validität von LLM-Richtern für RAG ist gemischt, und es lohnt sich, die beiden Seiten getrennt zu betrachten.

*Für* die Verwendung sprechen: RAGAS Faithfulness stimmte in 95 % der WikiEval-Paare mit menschlichen Präferenzen überein @es2024ragas[Tab. 4]. RAGCheckers Gesamtwert korreliert mit Pearson 61.93 nahe an der menschlichen Obergrenze von 70.09 @ru2024ragchecker. CRAGs Auto-Evaluation mit zwei LLMs erreicht F1 von 94.7 bis 98.9 % gegenüber menschlicher Bewertung @yang2024crag. ALCEs NLI-basierter Zitations-Recall stimmt mit Menschen bei $kappa = 0.698$ überein, die Precision bei $kappa = 0.525$; die Genauigkeit gegen menschliche Labels beträgt 85.1 % (Recall) und 77.6 % (Precision), und auf ASQA (ChatGPT) liegen menschliche und automatische Werte für Recall und Precision bei 74.7/76.6 gegenüber 75.3/74.4 @gao2023enabling. Starke Richter erreichen bei offenen Chat-Präferenzen "over 80% agreement, the same level of agreement between humans" @zheng2023judging.

*Gegen* eine unkritische Verwendung sprechen: RAGAS Answer Relevance (0.78) und Context Relevance (0.70) stimmen viel schwächer überein als Faithfulness @es2024ragas[Tab. 4]. In ARES' Evaluation reiht RAGAS Systeme weniger genau als feinjustierte Richter @saadfalcon2024ares[Tab. 1]. Auf RAGBench liegt die AUROC der Halluzinationserkennung von RAGAS und TruLens oft nur bei 0.5 bis 0.65 @friel2024ragbench. Die besten Faithfulness-Richter auf MEMERAG erreichen nur etwa 72 % balancierte Genauigkeit @cruzblandon2025memerag. GPT-4o liegt auf JudgeBench bei objektiver Korrektheit nahe am Zufall @tan2025judgebench. Und prozentuale Übereinstimmung verdeckt Abweichungen in den Scores @thakur2025judging @norman2026reliability. Bemerkenswert ist außerdem, dass ein großer Teil der "Für"-Evidenz Selbstvalidierung ist: RAGAS auf dem eigenen WikiEval, RAGChecker auf den eigenen Annotationen.

#studie(titel: [Tan et al. 2025 (JudgeBench)])[
  *Design:* 350 Antwortpaare (Wissen 154, Schlussfolgern 98, Mathematik 56, Programmieren 42), in denen eine Antwort objektiv richtig und die andere objektiv falsch ist; beide Reihenfolgen werden bewertet, inkonsistente Urteile zählen als falsch @tan2025judgebench. \
  *Befund:* GPT-4o 50.86 % (einfacher Prompt) und 56.57 % (Arena-Hard-Prompt) bei 50 % Zufallsrate @tan2025judgebench[Tab. 1]; am besten o3-mini (high) mit 80.86 % und DeepSeek-R1 mit 73.14 % @tan2025judgebench[Tab. 2]. \
  *Bedeutung für RAG:* Der Urteilsschritt in aussagenbasierten Metriken ist eine Korrektheitsfrage, keine Präferenzfrage. Die über 80 % Übereinstimmung bei Chat-Präferenzen @zheng2023judging übertragen sich nicht. \
  *Grenzen:* paarweises Format; Antworten von einem einzigen Generator (GPT-4o).
]

#studie(titel: [Cruz Blandón et al. 2025 (MEMERAG)])[
  *Design:* native Fragen auf Englisch, Deutsch, Spanisch, Französisch und Hindi aus MIRACL, 250 je Sprache; Antworten von fünf LLMs; 2322 Antwortsätze von Fachleuten auf Faithfulness und Relevanz annotiert @cruzblandon2025memerag. \
  *Befund:* Übereinstimmung der Annotierenden bei Faithfulness AC1 0.84 bis 0.93, Fleiss' $kappa$ 0.70 bis 0.88 @cruzblandon2025memerag[Tab. 2]. Balancierte Genauigkeit der Richter (gemittelt über Sprachen) steigt von 55.4 bis 66.7 (Zero-Shot) auf 57.9 bis 72.6 mit Annotationsrichtlinien im Prompt; am besten GPT-4o mini mit 71.7 und Qwen 2.5 32B mit 72.6 @cruzblandon2025memerag[Tab. 5]. \
  *Bedeutung:* realistische Obergrenze für LLM-Faithfulness-Richter, auch auf Deutsch, und ein Argument, die eigene Annotationsrichtlinie in den Richter-Prompt zu übernehmen.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let werte = (([Menschen], 96.24), ([GPT-4], 95.02), ([Llama-3 8B (feinjustiert)], 81.37), ([Llama-3 70B], 79.17), ([Prometheus 2 (8x7B)], 54.98), ([Prometheus 2 (7B)], 52.78))
    for (i, (lab, v)) in werte.enumerate() {
      let y = -i * 0.62
      let col = if i == 0 { c-grey } else { c-violet }
      content((-0.15, y), anchor: "east", text(font: "Inter", size: 7.5pt, lab))
      rect((0, y - 0.21), (8.5 * v / 100, y + 0.21), fill: col.lighten(15%), stroke: none)
      content((8.5 * v / 100 + 0.12, y), anchor: "west", text(font: "Inter", size: 7pt)[#str(v) %])
    }
  }),
  caption: [Bestehensquoten auf den 144 Unit-Tests von GroUSE über sieben Fehlermodi @muller2025grouse[Tab. 3]. Offene Richtermodelle liegen teils weit unter GPT-4; ein feinjustiertes kleines Modell holt deutlich auf. RAGAS und DeepEval scheitern an vielen einzelnen Tests @muller2025grouse.],
) <k09-fig-grouse>

GroUSE ergänzt einen methodischen Punkt: Zwei Richter können ähnlich mit GPT-4 korrelieren und dennoch sehr unterschiedliche Bestehensquoten haben @muller2025grouse. Die Autoren formulieren das allerdings großzügig; in ihrer Tabelle 4 liegen die verglichenen Korrelationswerte für positive Akzeptanz bei 0.55 und 0.79, "ähnlich" ist also eine wohlwollende Lesart. Die Botschaft bleibt: Korrelation allein ist ein unvollständiger Nachweis. Thakur et al. kommen mit 13 Richtermodellen und neun bewerteten Modellen zu einem verwandten Befund @thakur2025judging. Nur die besten und größten Richter erreichen vernünftige Übereinstimmung, weichen aber immer noch um bis zu 5 Punkte von menschlichen Scores ab; Richter mit hoher prozentualer Übereinstimmung können sehr verschiedene Scores vergeben; kleine Modelle und die lexikalische "contains"-Metrik können Prüflinge trotzdem vernünftig reihen; dazu kommen Nachsichtigkeitsverzerrung und Empfindlichkeit gegenüber der Komplexität des Prompts. Norman et al. trennen Reliabilität und Validität ausdrücklich @norman2026reliability: Über 21 Richter und etwa 541 000 Urteile können Richter mit Test-Retest-Reliabilität von mindestens 0.95 dennoch Positionsverzerrungen über 0.10 haben, und die Rangfolge der Richter verschiebt sich zwischen Benchmarks deutlich. Das Paper ist selbst nicht ganz konsistent (41.3 in Abschnitt 4.1, 41.2 in Abbildung 1, "33 to 41" im Abstract); für die Lehre reicht "etwa 34 bis 41 Prozentpunkte".

Bei der Halluzinationserkennung ist das Bild ähnlich. Ein feinjustiertes DeBERTa mit 400 Millionen Parametern erreicht auf RAGBench eine AUROC von 0.64 bis 0.87 über die Datensätze (Tabelle 3; der Fließtext nennt 0.64 bis 0.86) und schlägt GPT-3.5, RAGAS und TruLens auf den meisten, etwa HotpotQA 0.85 gegenüber 0.59 / 0.62 / 0.64 und TechQA 0.86 gegenüber 0.51 / 0.52 / 0.57; auf DelucionQA ist RAGAS besser (0.70 gegenüber 0.64) @friel2024ragbench. Kleine überwachte Prüfmodelle können also große, nur per Prompt gesteuerte Richter schlagen. G-Eval erreichte mit GPT-4 eine Spearman-Korrelation von 0.514 mit menschlichen Urteilen bei Zusammenfassungen und diskutiert eine mögliche Bevorzugung LLM-generierter Texte durch LLM-Bewerter @liu2023geval. Prometheus 2 ist eine offene Alternative, die unter den getesteten offenen Bewertern die höchste Korrelation und Übereinstimmung mit Menschen und proprietären Richtern erreichte, allerdings auf allgemeinen Evaluationsbenchmarks, nicht speziell für RAG-Faithfulness @kim2024prometheus2. Für eine Arbeit mit vertraulichen Dokumenten ist ein lokal laufender Richter oft die einzige zulässige Option; dann muss seine Validität erst recht gezeigt werden.

=== Wer beurteilt Relevanz? Die Debatte um LLM-Relevanzurteile

Auch für Retrieval-Metriken stellt sich die Validitätsfrage, sobald die Relevanzurteile von einem LLM stammen. Hier stehen drei Positionen nebeneinander. Thomas et al. zeigen, dass LLM-Relevanzurteile, die nach Übereinstimmung mit echtem Nutzerfeedback ausgewählt wurden, "as accurate as human labellers" sein können, aber mit Prompt-Merkmalen und einfachen Umformulierungen schwanken @thomas2024large. UMBRELA findet hohe Korrelationen der LLM-Urteile mit Systemrangfolgen über TREC Deep Learning 2019 bis 2023 @upadhyay2024umbrela. Clarke und Dietz halten dagegen, dass LLM-Urteile menschliche nicht ersetzen können: Sie führen ein System vor, das automatische Metriken austrickst, und zeigen Zirkularität, wenn Systeme dasselbe LLM als Re-Ranker verwenden, das auch die Urteile liefert @clarke2025llmbased. eRAG fügt eine dritte Position hinzu: Topische Relevanzurteile, ob von Menschen oder LLMs, korrelieren schwach mit der nachgelagerten RAG-Leistung (LLM-Urteile $tau$ 0.018 bis 0.176), generatorabgeleitete Urteile deutlich stärker (0.386 bis 0.610) @salemi2024evaluating.

#hoersaal([Ich verwende GPT als Re-Ranker und GPT als Relevanzrichter. Ist das ein Problem?], [Ja, und zwar ein strukturelles. Wenn dasselbe Modell entscheidet, was oben steht, und danach beurteilt, ob das Obenstehende relevant ist, misst du zum Teil die Übereinstimmung des Modells mit sich selbst. Clarke und Dietz beschreiben genau diese Zirkularität @clarke2025llmbased. Mindestens solltest du für die Urteile ein anderes Modell als für das Re-Ranking verwenden und eine menschlich beurteilte Stichprobe als Anker haben. Besser ist, die Hauptaussage auf menschliche oder generatorabgeleitete Urteile zu stützen und LLM-Urteile nur zur Skalierung zu nutzen.])

=== Einen Richter validieren und ein Intervall setzen

Die praktische Konsequenz ist für alle Metriken dieselbe: Jede richterbasierte RAG-Metrik in einer Arbeit braucht eine menschlich beurteilte Validierungsstichprobe, eine zufallskorrigierte Übereinstimmung und eine Intervallschätzung, etwa mit PPI wie bei ARES @saadfalcon2024ares @angelopoulos2023prediction. Das folgende Beispiel ist konstruiert, rechnet aber jeden Schritt durch.

#beispiel(titel: [Faithfulness-Richter validieren und PPI-Intervall])[
  Ein RAG-System beantwortet $N + n = 2200$ Fragen. Ein LLM-Richter beurteilt jede Antwort binär als treu (1) oder nicht (0). Eine Zufallsstichprobe von $n = 200$ Antworten wird zusätzlich von Menschen beurteilt. Auf dieser Stichprobe ergibt sich:

  #align(center, table(columns: (auto, auto, auto, auto), align: center,
    [], [Mensch: treu], [Mensch: nicht treu], [Summe],
    [Richter: treu], [156], [22], [178],
    [Richter: nicht treu], [4], [18], [22],
    [Summe], [160], [40], [200],
  ))

  *Übereinstimmung.* $p_o = (156 + 18) slash 200 = 0.870$. Zufallsübereinstimmung aus den Randverteilungen: $p_e = 0.89 dot 0.80 + 0.11 dot 0.20 = 0.734$. Cohens $kappa = (0.870 - 0.734) slash (1 - 0.734) = 0.511$. Die rohen 87 % klingen gut, $kappa$ zeigt eine nur mäßige Übereinstimmung. Die Ursache steckt in der Tabelle: Der Richter erkennt 156 von 160 treuen Antworten (Sensitivität 0.975), aber nur 18 von 40 untreuen (Spezifität 0.45). Er ist nachsichtig.

  *Naiver Schätzer.* Auf den $N = 2000$ nur maschinell beurteilten Antworten urteilt der Richter in 88 % auf "treu". Das naive 95-%-Intervall $0.88 plus.minus 1.96 sqrt(0.88 dot 0.12 slash 2000)$ ist $[0.866, 0.894]$: sehr schmal und, wie die menschliche Stichprobe zeigt, an der falschen Stelle.

  *PPI.* Der Korrekturterm $f(X_i) - Y_i$ ist auf den 200 Antworten 22-mal $+1$, 4-mal $-1$ und sonst 0; sein Mittel ist $(22 - 4) slash 200 = 0.090$, seine Stichprobenvarianz $hat(sigma)^2_(f - Y) = 0.1225$. Die Richtervarianz auf dem unannotierten Teil ist $hat(sigma)^2_f = 0.1057$. Nach @k09-eq-ppi ist $hat(theta)_"PP" = 0.880 - 0.090 = 0.790$, und nach @k09-eq-ppi-ci
  $ "SE" = sqrt((0.1225) / 200 + (0.1057) / 2000) = 0.0258, quad C_"PP" = 0.790 plus.minus 1.96 dot 0.0258 = [0.739, 0.841]. $

  *Nur Menschen.* Aus den 200 menschlichen Urteilen allein: $0.800 plus.minus 1.96 dot 0.0284 = [0.744, 0.856]$.

  Das PPI-Intervall ist korrekt zentriert und etwas schmaler als das rein menschliche. Der Gewinn ist hier bescheiden, weil der Richter schwach ist: Die Varianz des Korrekturterms dominiert. Je besser der Richter, desto kleiner $hat(sigma)^2_(f - Y)$ und desto größer der Gewinn durch die vielen Maschinenurteile.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let x(v) = (v - 0.70) * 40
    let zeilen = (
      ([Richter naiv ($N = 2000$)], 0.880, 0.866, 0.894, c-red),
      ([Nur Menschen ($n = 200$)], 0.800, 0.744, 0.856, c-grey),
      ([PPI ($n = 200$, $N = 2000$)], 0.790, 0.739, 0.841, c-teal),
    )
    line((x(0.70), -3.1), (x(0.92), -3.1), stroke: 0.7pt + c-dark)
    for v in (0.70, 0.75, 0.80, 0.85, 0.90) {
      line((x(v), -3.1), (x(v), -3.18), stroke: 0.5pt)
      content((x(v), -3.42), text(font: "Inter", size: 7pt)[#str(v)])
      line((x(v), -3.1), (x(v), 0.3), stroke: (paint: luma(230), thickness: 0.4pt))
    }
    content((x(0.81), -3.85), text(font: "Inter", size: 7.5pt)[Anteil treuer Antworten])
    for (i, (lab, m, lo, hi, col)) in zeilen.enumerate() {
      let y = -i * 1.0
      content((-0.2, y), anchor: "east", text(font: "Inter", size: 7.5pt)[#lab])
      line((x(lo), y), (x(hi), y), stroke: 1.6pt + col)
      line((x(lo), y - 0.12), (x(lo), y + 0.12), stroke: 1pt + col)
      line((x(hi), y - 0.12), (x(hi), y + 0.12), stroke: 1pt + col)
      circle((x(m), y), radius: 0.09, fill: col, stroke: none)
    }
  }),
  caption: [95-%-Intervalle aus dem Rechenbeispiel. Der naive Richtermittelwert ist präzise, aber verzerrt; PPI korrigiert die Verzerrung mit der menschlichen Stichprobe und nutzt zugleich die vielen Maschinenurteile.],
) <k09-fig-ppi>

Wie groß muss die menschliche Stichprobe sein? ARES nennt als Erfahrungswert, dass unter etwa 100 bis 150 Labels Systeme nicht zuverlässig unterschieden werden können @saadfalcon2024ares[Tab. 3]. Für die Genauigkeit eines einzelnen Anteils gibt die Formel einen Anhaltspunkt: Die Halbbreite des Intervalls ist etwa $1.96 dot hat(sigma)_(f - Y) slash sqrt(n)$, solange der zweite Term klein ist. Bei $hat(sigma)^2_(f - Y) approx 0.12$ und gewünschter Halbbreite 0.05 folgt $n approx (1.96^2 dot 0.12) slash 0.05^2 approx 184$. PPI setzt voraus, dass die annotierte Teilmenge eine Zufallsstichprobe aus derselben Verteilung ist @angelopoulos2023prediction; wer gezielt "interessante" Fälle annotieren lässt, verliert diese Garantie (Kapitel 6 behandelt PPI und seine Voraussetzungen ausführlich).

#fallstrick[Eine Validierungsstudie mit dem Richter, der später verwendet wird, ist nur für genau diese Konfiguration gültig: Modellversion, Prompt, Temperatur, Bibliotheksversion, Sprache, Domäne. Wechselt eines davon, etwa weil der API-Anbieter das Modell aktualisiert, muss die Validierung wiederholt werden. RAGAS bezeichnet LLM-basierte Metriken selbst als "somewhat non-deterministic" @ragas2026overview; berichte Wiederholungen und deren Streuung.]

== Zwei Konfigurationen vergleichen <k09-vergleich>

Die häufigste Forschungsfrage in RAG-Abschlussarbeiten lautet in irgendeiner Form "Ist Konfiguration B besser als A?": hybrider statt lexikalischer Retriever, mit oder ohne Re-Ranker, Chunkgröße 256 oder 512, $k = 5$ oder $k = 10$. Ein höherer Mittelwert auf dem Testdatensatz beantwortet diese Frage nicht, denn die Differenz kann im Rauschen der Stichprobe liegen @haindl2027research. Das Lehrbuch fasst die Regeln zusammen: einen zur Metrik passenden Test wählen, das Ergebnis als Differenz mit Konfidenzintervall berichten und bei vielen Vergleichen für Mehrfachtests korrigieren @haindl2027research. Dietterich hat gezeigt, dass mehrere verbreitete Tests beim Vergleich von Lernverfahren ein unannehmbar hohes Risiko falsch positiver Befunde haben @Dietterich1998; Demšar empfiehlt für den Vergleich zweier Systeme über mehrere Datensätze den Wilcoxon-Vorzeichen-Rang-Test @Demsar2006.

=== Das gepaarte Design

Beide Konfigurationen werden auf denselben Fragen $q = 1, dots, n$ evaluiert. Seien $x_q^A$ und $x_q^B$ die Werte einer Metrik (etwa nDCG\@10 oder Faithfulness) und $d_q = x_q^B - x_q^A$ die Differenz pro Frage. Geschätzt wird $delta = EE[d_q]$ durch $overline(d) = 1/n sum_q d_q$.

Warum gepaart? Fragen unterscheiden sich stark in ihrer Schwierigkeit, und diese Schwierigkeit trifft beide Systeme. Die Varianz der Differenz der Mittelwerte ist
$ "Var"(overline(d)) = (sigma_A^2 + sigma_B^2 - 2 rho sigma_A sigma_B) / n, $ <k09-eq-paired>
wobei $rho$ die Korrelation der Werte beider Systeme über die Fragen ist. Ein ungepaarter Vergleich ignoriert den Term $-2 rho sigma_A sigma_B$ und hat die Varianz $(sigma_A^2 + sigma_B^2) slash n$. Je stärker die Fragenschwierigkeit beide Systeme gleich trifft (großes $rho$), desto mehr gewinnt die Paarung. @k09-eq-paired folgt direkt aus $"Var"(X - Y) = "Var"(X) + "Var"(Y) - 2 "Cov"(X, Y)$ und der Unabhängigkeit der Fragen.

=== Gepaarter Bootstrap

Viele RAG-Metriken sind keine einfachen Mittelwerte unabhängiger Beobachtungen, und die Verteilung pro Frage ist oft schief oder beschränkt (nDCG liegt in $[0, 1]$, Faithfulness ist ein Anteil mit vielen Einsen). Das Lehrbuch nennt die Standardlösung der Sprachtechnologie: Resampling @haindl2027research. Koehn hat den gepaarten Bootstrap für genau diesen Zweck eingeführt @Koehn2004.

#definition(titel: [Gepaarter Bootstrap nach Koehn])[
  Gegeben die Wertepaare $(x_q^A, x_q^B)$, $q = 1, dots, n$, und eine Zahl $B$ von Wiederholungen. Für $b = 1, dots, B$: Ziehe $n$ Fragenindizes mit Zurücklegen, $q_1^*, dots, q_n^*$, und berechne $Delta_b^* = 1/n sum_j (x_(q_j^*)^B - x_(q_j^*)^A)$. Das 95-%-Perzentilintervall ist $[Delta^*_((0.025)), Delta^*_((0.975))]$, die empirischen Quantile der $Delta_b^*$. Koehns Kennzahl für die Überlegenheit von B ist der Anteil der Wiederholungen, in denen B nicht besser ist, $hat(p) = 1/B sum_b bb(1)[Delta_b^* <= 0]$.
]

Entscheidend ist, dass immer _Fragen_ gezogen werden und beide Systemwerte einer Frage gemeinsam in die Stichprobe kommen; nur so bleibt die Paarung erhalten. Ist die Metrik kein Mittelwert, sondern etwa ein Korpus-F1, wird in jeder Wiederholung die Metrik auf der gezogenen Stichprobe neu berechnet.

=== Approximate Randomisation

Der Permutationstest beantwortet eine andere Frage, nämlich die nach einem p-Wert unter einer Nullhypothese. Unter $H_0$ "beide Systeme sind austauschbar" ist es gleichgültig, welches System welche Ausgabe pro Frage erzeugt hat. Man vertauscht deshalb pro Frage zufällig die Systemzuordnung, was bei Differenzen einem zufälligen Vorzeichenwechsel entspricht @haindl2027research.

#definition(titel: [Approximate Randomisation (gepaart)])[
  Für $r = 1, dots, R$: Ziehe unabhängige Vorzeichen $s_q^((r)) in {-1, +1}$ mit Wahrscheinlichkeit je $1 slash 2$ und berechne $T^((r)) = 1/n sum_q s_q^((r)) d_q$. Der zweiseitige p-Wert ist
  $ p = (1 + sum_(r=1)^R bb(1)[abs(T^((r))) >= abs(overline(d))]) / (R + 1). $ <k09-eq-ar-test>
]

#satz(titel: [Gültigkeit des Vorzeichen-Permutationstests])[
  Sind die $d_q$ unabhängig und unter $H_0$ symmetrisch um 0 verteilt, dann gilt für den p-Wert aus @k09-eq-ar-test $P_(H_0)(p <= alpha) <= alpha$ für jedes $alpha in [0, 1]$.
]
#beweis[
  Unter $H_0$ hat der Vektor $(d_1, dots, d_n)$ dieselbe Verteilung wie $(s_1 d_1, dots, s_n d_n)$ für jede feste Vorzeichenwahl. Damit sind die beobachtete Statistik $T^((0)) = overline(d)$ und die $R$ zufällig umgedrehten Statistiken $T^((1)), dots, T^((R))$ austauschbar. Der Rang von $abs(T^((0)))$ unter den $R + 1$ Werten ist daher (bei Bindungen konservativ gezählt) gleichverteilt auf ${1, dots, R + 1}$. Die Wahrscheinlichkeit, dass höchstens $k - 1$ der $R$ Vergleichswerte mindestens so groß sind, ist höchstens $k slash (R + 1)$, also $P(p <= k slash (R + 1)) <= k slash (R + 1)$. Das "+1" in Zähler und Nenner sorgt dafür, dass $p$ nie 0 wird und die Schranke exakt gilt.
]

=== Ergebnis aus dem Notebook

Das Notebook simuliert zwei Retriever-Konfigurationen auf 200 Fragen mit je 60 Kandidatendokumenten und abgestuften Relevanzurteilen; Konfiguration A (lexikalisch) und B (hybrid) bewerten Dokumente als `signal * grade + noise`, B mit etwas stärkerem Signal (synthetische Daten, fester Seed 2027). Ergebnisse:

#beispiel(titel: [Gepaarter Vergleich auf 200 Fragen])[
  - Mittleres nDCG\@10: A $= 0.525$, B $= 0.589$, Differenz $overline(d) = 0.063$. B ist auf 64.5 % der Fragen besser, auf den übrigen schlechter.
  - Gepaarter Bootstrap ($B = 5000$): 95-%-Intervall $[0.0328, 0.0934]$; Anteil der Wiederholungen mit B nicht besser: 0.0000.
  - Approximate Randomisation ($R = 5000$): $p = 0.0002$, das ist $1 slash 5001$, also kein einziger zufällig umgedrehter Wert erreichte die beobachtete Differenz. Wilcoxon-Test: $p = 0.0001$.
  - Zum Vergleich: gepaartes $t$-Intervall $[0.0333, 0.0936]$, praktisch identisch mit dem Bootstrap, weil bei $n = 200$ der zentrale Grenzwertsatz greift.
  - Streuung: $sigma_A = 0.181$, $sigma_B = 0.158$, $rho = 0.193$, Standardabweichung der Differenzen $s_d = 0.216$. Gepaarter Standardfehler $s_d slash sqrt(200) = 0.0153$; ungepaart wäre er $sqrt((0.181^2 + 0.158^2) slash 200) = 0.0170$. Die Paarung bringt hier wenig, weil die simulierte Fragenschwierigkeit beide Systeme nur schwach gemeinsam trifft; in realen Daten ist $rho$ meist deutlich größer.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let h = (1, 3, 4, 3, 22, 48, 86, 162, 241, 356, 494, 563, 690, 609, 567, 414, 329, 201, 109, 59, 19, 12, 4, 4)
    let x(v) = v * 100
    let sy = 3.6 / 700
    rect((x(0.0328), 0), (x(0.0934), 3.75), fill: c-accent.lighten(88%), stroke: none)
    for (i, c) in h.enumerate() {
      rect((x(i * 0.005), 0), (x((i + 1) * 0.005) - 0.03, c * sy), fill: c-blue.lighten(15%), stroke: none)
    }
    line((0, 0), (12.3, 0), stroke: 0.7pt + c-dark)
    for v in (0, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12) {
      line((x(v), 0), (x(v), -0.08), stroke: 0.5pt)
      content((x(v), -0.32), text(font: "Inter", size: 7pt)[#str(v)])
    }
    line((x(0.0634), 0), (x(0.0634), 3.9), stroke: (paint: c-dark, thickness: 0.9pt, dash: "dashed"))
    content((x(0.0634), 4.12), text(font: "Inter", size: 7pt)[$overline(d) = 0.063$])
    content((x(0.0328) - 0.1, 3.0), anchor: "east", text(font: "Inter", size: 7pt, fill: c-accent.darken(10%))[95-%-Intervall \ $[0.033, 0.093]$])
    content((6, -0.8), text(font: "Inter", size: 7.5pt)[Differenz der mittleren nDCG\@10 (B $-$ A) je Bootstrap-Wiederholung])
  }),
  caption: [Bootstrap-Verteilung der mittleren Differenz aus dem Notebook (5000 Wiederholungen, 200 Fragen). Das Intervall (orange hinterlegt) schließt 0 deutlich aus.],
) <k09-fig-bootstrap>

=== Wie viele Fragen braucht man?

Die Breite des Intervalls fällt mit $1 slash sqrt(n)$. Das Notebook wiederholt den Vergleich mit frischen Simulationen für verschiedene $n$ (Übungsaufgabe 4 dort); @k09-fig-ciwidth zeigt das Ergebnis. Bei 25 Fragen schließt das Intervall die 0 ein ($[-0.027, 0.134]$), obwohl B im Simulationsmodell tatsächlich besser ist; bei 50 Fragen liegt die untere Grenze mit 0.0001 praktisch auf der 0; erst ab etwa 100 Fragen ($[0.028, 0.120]$) wird der Unterschied stabil sichtbar. Die Punktschätzungen der Differenz streuen dabei zwischen 0.053 ($n = 25$) und 0.075 ($n = 100$ und $n = 400$).

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let pts = ((25, 0.1614), (50, 0.1303), (100, 0.0918), (200, 0.0606), (400, 0.0454))
    let x(n) = calc.log(n, base: 2) * 2.2 - 9.0
    let y(w) = w * 22
    line((x(20), 0), (x(500), 0), stroke: 0.7pt + c-dark)
    line((x(20), 0), (x(20), 4.1), stroke: 0.7pt + c-dark)
    for (n, w) in pts {
      line((x(n), 0), (x(n), -0.08), stroke: 0.5pt)
      content((x(n), -0.32), text(font: "Inter", size: 7pt)[#n])
    }
    for v in (0.05, 0.10, 0.15) {
      line((x(20), y(v)), (x(500), y(v)), stroke: (paint: luma(228), thickness: 0.4pt))
      content((x(20) - 0.12, y(v)), anchor: "east", text(font: "Inter", size: 7pt)[#str(v)])
    }
    // Referenzkurve c / sqrt(n), angepasst an n = 200
    let c = 0.0606 * calc.sqrt(200)
    let ref = range(0, 41).map(i => { let n = 36 * calc.pow(13, i / 40); (x(n), y(c / calc.sqrt(n))) })
    line(..ref, stroke: (paint: c-grey, thickness: 0.8pt, dash: "dashed"))
    line(..pts.map(((n, w)) => (x(n), y(w))), stroke: 1.1pt + c-teal)
    for (n, w) in pts { circle((x(n), y(w)), radius: 0.08, fill: c-teal, stroke: none) }
    content((x(80), y(0.155)), anchor: "west", text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[$prop 1 slash sqrt(n)$])
    content(((x(20) + x(500)) / 2, -0.8), text(font: "Inter", size: 7.5pt)[Zahl der Fragen $n$ (logarithmisch)])
    content((x(20) - 1.05, 2.0), angle: 90deg, text(font: "Inter", size: 7.5pt)[Breite des 95-%-Intervalls])
  }),
  caption: [Breite des gepaarten Bootstrap-Intervalls für die nDCG\@10-Differenz in Abhängigkeit von der Zahl der Fragen (je eine frische Simulation, Notebook-Setup). Der Wert bei $n = 200$ ist der Vergleich aus @k09-fig-bootstrap, die übrigen stammen aus der Lösung zu Übungsaufgabe 4 (Seed $2027 + n$). Gestrichelt: die Referenzkurve $c slash sqrt(n)$, angepasst bei $n = 200$. Einzelne Simulationen streuen um die Kurve.],
) <k09-fig-ciwidth>

Für die Planung vor dem Experiment dient die übliche Näherung für einen gepaarten Vergleich: Um eine wahre Differenz $delta$ mit zweiseitigem Niveau $alpha$ und Teststärke $1 - beta$ zu entdecken, braucht man
$ n approx ((z_(1 - alpha slash 2) + z_(1 - beta)) sigma_d / delta)^2. $ <k09-eq-power>
Mit $sigma_d approx 0.216$ aus dem Notebook (ungerundet 0.2162), $alpha = 0.05$ und Teststärke 0.8 ($z$-Werte 1.960 und 0.842) ergeben sich nach Aufrunden 147 Fragen für $delta = 0.05$, 408 Fragen für $delta = 0.03$ und 918 Fragen für $delta = 0.02$. Das Lehrbuch verweist auf Card et al., die zeigen, dass unterdimensionierte Experimente in der Sprachtechnologie verbreitet sind @haindl2027research @Card2020. Wer nur 50 Testfragen hat, sollte vor dem Experiment ausrechnen, welche Differenz damit überhaupt nachweisbar ist, und ein "kein signifikanter Unterschied" entsprechend vorsichtig formulieren.

=== Weitere Fallstricke beim Vergleich

*Mehrfachvergleiche.* Wer fünf Chunkgrößen, drei Retriever und zwei Re-Ranker vergleicht, testet 30 Konfigurationen. Ohne Korrektur wird mit großer Wahrscheinlichkeit irgendeine Differenz signifikant @haindl2027research. Lege die Hauptvergleiche vorab fest und korrigiere die übrigen für Mehrfachtests.

*Nichtdeterminismus.* Sowohl der Generator als auch der Richter streuen. Ein sauberes Design wiederholt jede Konfiguration mehrfach, mittelt pro Frage über die Wiederholungen und führt den Bootstrap über die Fragen. Wer stattdessen Wiederholungen als zusätzliche "Fragen" in den Bootstrap gibt, unterschätzt die Unsicherheit, weil die Wiederholungen derselben Frage nicht unabhängig sind.

*Praktische Relevanz.* Mit genügend Fragen wird auch eine Differenz von einem halben Prozentpunkt signifikant. Berichte die Differenz mit Intervall und begründe, ab welcher Größe sie für den Einsatzzweck zählt @haindl2027research.

*Signifikanz wird oft gar nicht getestet.* Dror et al. fanden in einer Durchsicht von Arbeiten zweier großer Konferenzen, dass Signifikanztests häufig fehlten oder falsch angewendet wurden @Dror2018. Ein Intervall um die Differenz ist der einfachste Weg, nicht in diese Kategorie zu fallen.

#datei("compare_configs.py")[
```python
import numpy as np

def paired_bootstrap(x_a, x_b, B=5000, seed=0):
    rng = np.random.default_rng(seed)
    idx = rng.integers(0, len(x_a), (B, len(x_a)))   # Fragen ziehen, Paare behalten
    deltas = x_b[idx].mean(axis=1) - x_a[idx].mean(axis=1)
    ci = np.quantile(deltas, [0.025, 0.975])
    p_not_better = np.mean(deltas <= 0)              # Kennzahl nach Koehn (2004)
    return deltas.mean(), ci, p_not_better

def approximate_randomisation(x_a, x_b, R=5000, seed=0):
    rng = np.random.default_rng(seed)
    d = x_b - x_a
    signs = rng.choice([-1, 1], size=(R, len(d)))    # Systemzuordnung je Frage tauschen
    null = (signs * d).mean(axis=1)
    return (1 + np.sum(np.abs(null) >= abs(d.mean()))) / (R + 1)

# x_a, x_b: Metrikwerte pro Frage, gleiche Reihenfolge der Fragen.
# Bei wiederholten Läufen zuerst pro Frage über die Läufe mitteln.
```
]

#hoersaal([Bootstrap oder Permutationstest, was ist besser?], [Sie beantworten verschiedene Fragen. Der Bootstrap liefert ein Konfidenzintervall für die Differenz, also eine Aussage über deren Größe und Unsicherheit. Der Permutationstest liefert einen p-Wert für die Nullhypothese, dass die Systeme austauschbar sind. Für eine Arbeit ist das Intervall die wichtigere Angabe, weil es zeigt, wie groß der Unterschied plausiblerweise ist. Den p-Wert kannst du zusätzlich berichten. Bei großen $n$ und gutartigen Verteilungen stimmen beide mit dem gepaarten $t$-Test praktisch überein, wie im Notebook.])

== Eine RAG-Evaluation für eine Abschlussarbeit entwerfen <k09-design>

Die vorangegangenen Abschnitte liefern die Bausteine. Dieser Abschnitt setzt sie an einem durchgehenden Beispiel zu einem Evaluationsdesign zusammen, wie es für eine Masterarbeit im Programm Data Intelligence oder Security Management realistisch ist. Das Lehrbuch gibt die Grundhaltung vor: in Schichten messen, über unvollkommene Metriken triangulieren, keiner Einzelzahl trauen und Grenzen als Teil des Ergebnisses berichten @haindl2027research. Für ein RAG-System übersetzt sich das in eine feste Abfolge von Entscheidungen, die @k09-fig-design zeigt.

*Szenario.* Eine Studentin baut eine Literaturassistenz, die Fragen zu einem Korpus von 1200 Volltexten über LLM-Sicherheit beantwortet und jede Aussage mit Quellenangaben belegt. Forschungsfrage: Verbessert ein hybrider Retriever mit Re-Ranker gegenüber BM25 die Belegtreue und Vollständigkeit der Antworten, und zu welchen Kosten?

#figure(
  diagram(spacing: (6mm, 5.5mm),
    fknoten((0,0), [*1 Konstrukte* \ Treue, Vollständigkeit, \ Zitationen, Ablehnung], col: c-accent, filled: true, w: 38mm),
    fknoten((1,0), [*2 Qualitätsmodell* \ ISO/IEC 25010/25059: \ im Rahmen / ausgeklammert], col: c-violet, w: 38mm),
    fknoten((2,0), [*3 Testdatensatz* \ beantwortbar, unbeantwortbar, \ widersprüchlich; $n$ geplant], col: c-blue, w: 38mm),
    fknoten((2,1), [*4 Metriken je Ebene* \ Retriever, Generator, \ Ende-zu-Ende, Betrieb], col: c-teal, w: 38mm),
    fknoten((1,1), [*5 Richter validieren* \ menschliche Stichprobe, \ $kappa$, Sensitivität, Spezifität], col: c-yellow, w: 38mm),
    fknoten((0,1), [*6 Vergleich* \ gepaarter Bootstrap, AR, \ PPI-Intervalle, Mehrfachtests], col: c-green, w: 38mm),
    fknoten((0,2), [*7 Bericht* \ Qualitätsprofil mit Intervallen, Fehleranalyse, Versionen, Grenzen], col: c-dark, filled: true, w: 70mm),
    edge((0,0), (1,0), "-|>"), edge((1,0), (2,0), "-|>"),
    edge((2,0), (2,1), "-|>"),
    edge((2,1), (1,1), "-|>"), edge((1,1), (0,1), "-|>"),
    edge((0,1), (0,2), "-|>"),
  ),
  caption: [Sieben Entscheidungen einer RAG-Evaluation. Die Reihenfolge ist wichtig: Konstrukte und Qualitätsmodell vor den Metriken, Validierung der Richter vor dem Vergleich der Systeme.],
) <k09-fig-design>

=== Schritt 1 und 2: Konstrukte und Untersuchungsrahmen

Zuerst wird festgelegt, was "gut" heißt, getrennt nach Konstrukten. Für eine Literaturassistenz sind das mindestens: Belegtreue (jede Aussage durch eine zitierte Quelle gestützt), Vollständigkeit (die wesentlichen Punkte der Literatur sind enthalten), Zitationsqualität (die Zitate sind präzise und prüfbar) und angemessene Ablehnung (keine Antwort, wenn der Korpus nichts hergibt). Faktizität im Sinne der Weltwahrheit wird bewusst nicht gemessen; das wird als Grenze festgehalten, denn auch die treue Wiedergabe eines falschen Befunds ist ein Schaden @haindl2027research.

Das Qualitätsmodell aus @k09-iso dient als Checkliste. Im Rahmen: functional correctness, functional completeness, transparency, robustness (Ablehnung, Konflikte), time behaviour und resource utilization. Ausgeklammert mit Begründung: security (etwa Prompt Injection über manipulierte Dokumente im Korpus, ein eigenes Forschungsthema), maintainability, compatibility, flexibility. Die Zuordnung von intervenability bleibt offen und wird so berichtet.

=== Schritt 3: Testdatensatz und Stichprobenplanung

Der Testdatensatz bekommt drei Schichten: beantwortbare Fragen mit Referenzantwort und Gold-Chunks, unbeantwortbare Fragen (Antwort nicht im Korpus, gegen FP1) und Fragen mit widersprüchlicher Evidenz im Korpus. Die beiden letzten Schichten sind nach RGB und EnterpriseRAG die Schwachstellen aktueller Systeme @chen2024benchmarking @miao2026enterpriserag. Für die beantwortbaren Fragen werden Nuggets (vital/okay) annotiert, weil sie Vollständigkeit messbar machen @pradeep2025great.

Die Größe folgt aus @k09-eq-power. Soll eine Differenz von 0.05 in der Nugget-Recall-Metrik mit Teststärke 0.8 nachweisbar sein und liegt die Standardabweichung der Differenzen aus einer Pilotstudie bei etwa 0.2, braucht man $((1.96 + 0.84) dot 0.2 slash 0.05)^2 approx 125$ beantwortbare Fragen. Dazu kommen je 40 bis 50 Fragen der anderen Schichten, deren Anteile (Ablehnungsquote, Konflikterkennung) mit Wilson- oder Bootstrap-Intervallen berichtet werden. Alle Fragen werden vor der Systementwicklung festgelegt und eingefroren; wer Testfragen nach den ersten Ergebnissen umformuliert, optimiert auf den Testdatensatz.

#tipp[Erstelle die Fragen nicht nur aus dem Korpus heraus ("lies ein Paper, schreib eine Frage dazu"). Solche Fragen sind lexikalisch nahe an ihrer Quelle und begünstigen BM25. Sammle zusätzlich echte Fragen von Personen, die das System nutzen würden, und markiere die Herkunft jeder Frage, um sie später getrennt auszuwerten.]

=== Schritt 4: Metriken je Ebene

@k09-tab-design zeigt das Metrikset. Jede Zeile hat eine Ebene, eine Zuordnung zum Qualitätsmodell und eine Angabe, wie die Metrik validiert wird.

#figure(kind: table, supplement: [Tab.],
  table(columns: (auto, auto, auto, 1fr),
    [Ebene], [Metrik], [Merkmal], [Validierung / Anmerkung],
    [Retriever], [Recall\@10, nDCG\@10 (linear)], [completeness], [Gold-Chunks menschlich beurteilt; BM25 als Baseline @thakur2021beir],
    [Retriever], [eRAG-Relevanz (MAP)], [completeness], [generatorabgeleitet @salemi2024evaluating; Korrelation mit Ende-zu-Ende prüfen],
    [Generator], [Faithfulness (Kriterium "ableitbar")], [correctness], [LLM-Richter; 200 Antworten menschlich; $kappa$; PPI-Intervall],
    [Generator], [Zitations-Recall/-Precision (ALCE)], [transparency], [NLI-Modell; menschliche Stichprobe @gao2023enabling],
    [Ende-zu-Ende], [$V_"strict"$, $A_"strict"$], [completeness], [Nuggets menschlich, Zuordnung LLM; Stichprobe manuell @pradeep2025great],
    [Robustheit], [Ablehnungsquote, Konflikterkennung], [robustness], [menschlich auf allen Fragen dieser Schichten],
    [Betrieb], [Latenz p50/p95, Kosten pro Anfrage], [time behaviour, resource util.], [inklusive Richteraufrufe; Datum der Preise],
  ),
  caption: [Metrikset für die Beispielarbeit. Die Wahl ist exemplarisch; entscheidend ist, dass jede Metrik einer Ebene und einem Merkmal zugeordnet ist und einen Validierungsweg hat.],
) <k09-tab-design>

Bewusst nicht im Set: Answer Relevancy nach RAGAS, weil sie Fakten nicht prüft und die Studie Relevanz über Nuggets abdeckt @ragas2026answerrelevancy; Context Precision ohne Recall, wegen des Satzes aus @k09-retrieval; BLEU oder ROUGE als Hauptmaß.

=== Schritt 5: Richter validieren

Bevor ein einziger Systemvergleich gerechnet wird, wird jeder Richter validiert. Für Faithfulness beurteilen zwei Personen unabhängig eine Zufallsstichprobe von 200 Antworten nach einer schriftlichen Richtlinie; ihre Übereinstimmung wird mit $kappa$ berichtet (Kapitel 5). Der Konsens dient als Referenz für den Richter: rohe Übereinstimmung, $kappa$, Sensitivität und Spezifität wie im Rechenbeispiel in @k09-validitaet. Die Richtlinie wird in den Richter-Prompt übernommen, weil MEMERAG zeigt, dass Annotationsrichtlinien im Prompt die balancierte Genauigkeit erhöhen @cruzblandon2025memerag. Zeigt der Richter eine Spezifität wie im Beispiel (0.45), wird er nicht verwendet oder nur mit PPI-Korrektur.

Zusätzlich wird der Richter mit gezielten Fällen geprüft, im Geist von GroUSE @muller2025grouse: eine Antwort, die eine Aussage aus einem irrelevanten Chunk übernimmt; eine Antwort, die wahr, aber nicht belegt ist; eine Ablehnung; eine Antwort mit falscher Zahl bei sonst richtigem Satz. Besteht der Richter diese Tests nicht, ist die Korrelation auf der Stichprobe kein ausreichender Beleg.

=== Schritt 6 und 7: Vergleich und Bericht

Der Vergleich BM25 gegen hybrid mit Re-Ranker erfolgt gepaart auf denselben Fragen. Jede Konfiguration läuft dreimal; pro Frage wird über die Läufe gemittelt, dann wird der gepaarte Bootstrap über die Fragen gerechnet. Für richterbasierte Metriken wird zusätzlich das PPI-Intervall je Konfiguration berichtet. Vorab festgelegt werden zwei Hauptvergleiche (Faithfulness und $V_"strict"$); alle weiteren Vergleiche gelten als explorativ und werden für Mehrfachtests korrigiert.

Der Bericht enthält ein Qualitätsprofil wie @k09-tab-bericht, eine Fehleranalyse an einer Stichprobe von Fehlschlägen, kategorisiert nach den Fehlerpunkten von Barnett et al. @barnett2024seven, und einen Abschnitt zu Grenzen. Das Lehrbuch empfiehlt ausdrücklich, Fehlschläge direkt zu untersuchen und ihre Verteilung zu berichten, weil erst das eine undurchsichtige Zahl in eine Erklärung verwandelt @haindl2027research.

#figure(kind: table, supplement: [Tab.],
  table(columns: (auto, auto, auto, auto),
    [Merkmal / Metrik], [BM25], [Hybrid + Re-Ranker], [Differenz (95-%-KI)],
    [Faithfulness (PPI)], [$hat(theta)_A$ \[KI\]], [$hat(theta)_B$ \[KI\]], [Bootstrap-KI],
    [$V_"strict"$], [...], [...], [...],
    [Zitations-Precision], [...], [...], [...],
    [Ablehnungsquote (unbeantwortbar)], [...], [...], [...],
    [Latenz p95 (s)], [...], [...], [...],
    [Kosten pro Anfrage (inkl. Richter)], [...], [...], [...],
    [security, maintainability, ...], table.cell(colspan: 3)[nicht untersucht (Begründung im Methodenteil)],
  ),
  caption: [Schablone für das Qualitätsprofil im Ergebnisteil. Keine Zeile wird zu einem Gesamtwert verrechnet; Mindestanforderungen (etwa Faithfulness $>= 0.9$) werden als Tore geprüft.],
) <k09-tab-bericht>

#praxis[Eine Reproduktionsangabe für eine RAG-Evaluation umfasst: Korpusversion mit Hash, Chunking-Parameter, Einbettungsmodell, Retriever- und Re-Ranker-Konfiguration, $k$, Generatormodell mit Version und Datum, Prompt-Vorlagen, Temperatur und Zahl der Läufe, Bibliotheksversionen der Evaluationswerkzeuge, Richtermodell mit Version und Datum, Modus und Parameter jeder Metrik, die menschlichen Annotationen samt Richtlinie und die Seeds für Bootstrap und Permutationstest. Der Grund ist nicht Pedanterie. DeepEval hat mit Version 4.2.0 die Bewertungsrichtung von vier Metriken umgedreht @deepeval2026changelog, und RAGAS stellt mit 0.4 die Metrik-API um @ragas2026answerrelevancy. Ohne diese Angaben lässt sich ein Ergebnis schon ein halbes Jahr später nicht mehr einordnen.]

#hoersaal([Meine Betreuerin sagt, ich soll auch die "Halluzinationsrate" berichten. Welche Metrik ist das?], [Das musst du definieren, denn der Begriff wird verschieden verwendet. In RAGChecker ist Hallucination der Anteil der Antwortaussagen, die weder in der Referenz noch im Kontext stehen @ru2024ragchecker; dann zählen auch wahre, aber unbelegte Aussagen. In CRAG ist die Halluzinationsrate der Anteil falscher Antworten, und Truthfulness ist Genauigkeit minus Halluzinationsrate @yang2024crag. In vielen Arbeiten ist sie schlicht $1 - "Faithfulness"$. Wähle eine Definition, die zu deinem Konstrukt passt, schreibe die Formel hin und nenne den Unterschied zu den anderen Lesarten in einem Satz.])

== Debatten und offene Fragen <k09-debatten>

Vier Kontroversen prägen das Feld derzeit. Sie sind für die Lehre wertvoll, weil Studierende an ihnen lernen, dass "die Metrik" keine neutrale Instanz ist.

*Sind LLM-Richter-Metriken valide?* Die Evidenz aus @k09-validitaet erlaubt keine pauschale Antwort. Validitätsnachweise sind metrik-, richter-, domänen- und sprachspezifisch @saadfalcon2024ares @cruzblandon2025memerag. Wer pauschal "RAGAS ist validiert" schreibt, verallgemeinert eine Validierung auf 50 Fragen mit gpt-3.5-turbo-16k auf Metriken, die es damals nicht gab, und auf Richter, die damals niemand verwendete @es2024ragas.

*Systemebene oder Instanzebene?* Nugget-Evaluation reiht Systeme gut, stimmt aber pro Thema schwach überein @pradeep2025great; ARES versagt bei starker Domänenverschiebung @saadfalcon2024ares. Viele Arbeiten verwenden automatische Metriken trotzdem für Aussagen über einzelne Antworten, etwa in der Fehleranalyse. Ob es Metriken gibt, die auf beiden Ebenen valide sind, ist offen.

*Wem gehört die Relevanz?* Menschliche topische Relevanz, LLM-Relevanz oder generatorabgeleitete Relevanz: Die drei Positionen aus @k09-validitaet führen zu verschiedenen Retriever-Rangfolgen @thomas2024large @clarke2025llmbased @salemi2024evaluating. Für RAG spricht viel für die generatorabgeleitete Sicht, sie hat aber den Preis, dass die Urteile nur für einen bestimmten Generator gelten.

*Soll Enthaltung belohnt werden?* TruLens zählt Enthaltungen als gestützt @trulens2026providers, CRAG bewertet sie mit 0 statt -1 @yang2024crag. Beides kodiert die Präferenz "lieber nichts als Falsches". Ohne eine begleitende Vollständigkeits- oder Abdeckungsmetrik belohnt das ein System, das sich im Zweifel immer enthält. Welcher Strafwert für eine falsche Antwort angemessen ist, hängt vom Einsatz ab; in der Medizin vermutlich ein anderer als in einer Literaturrecherche. ISO/IEC 25059 liefert die Begriffe für diese Abwägung (user controllability, robustness, societal and ethical risk mitigation), aber keine Gewichte @isoiec2023software.

Daneben gibt es offene technische Fragen. Gleichnamige Metriken mit verschiedenen Operationalisierungen machen Arbeiten untereinander schwer vergleichbar @ragas2026answerrelevancy @deepeval2026answerrelevancy @ru2024ragchecker. Aggregationsregeln können Ausfälle verdecken @oviedolama2025towards. Agentische und mehrstufige Systeme lassen sich mit Einzelschritt-Metriken nur unvollständig bewerten; RAGAS bietet inzwischen Metriken für Agenten und Werkzeugnutzung an @ragas2026availablemetrics, eine validierte Methodik fehlt aber noch @singh2025agentic. Und die Qualitätsmodelle selbst sind in Bewegung: ISO/IEC 25059 wird überarbeitet, und ein Qualitätsmodell für KI-Dienste ist angekündigt @isoiec2026dis25059 @smith2026isoiec. Nicht behandelt werden in diesem Kapitel GraphRAG und die Evaluation von Zusammenfassungen über Graphen sowie weitere Deep-Research-Benchmarks; dazu lag keine geprüfte Quellenbasis vor.

#vertiefung[
  - Für die Metriken: die RAGAS-Dokumentation zu Context Precision und Faithfulness @ragas2026contextprecision @ragas2026faithfulness neben dem RAGAS-Paper @es2024ragas lesen, Paper und Bibliothek Zeile für Zeile vergleichen.
  - Für Retrieval-Grundlagen: Manning et al., Kapitel 8 @manning2008introduction, und die Originalarbeit zu (n)DCG @jarvelin2002cumulated.
  - Für Diagnose: RAGChecker, Anhang B mit allen Formeln @ru2024ragchecker.
  - Für Validität: JudgeBench @tan2025judgebench, MEMERAG @cruzblandon2025memerag und GroUSE @muller2025grouse als Trio; ARES @saadfalcon2024ares für die statistische Lösung.
  - Für Relevanz: eRAG @salemi2024evaluating gegen Clarke und Dietz @clarke2025llmbased lesen.
  - Für Qualitätsmodelle: die Leseprobe von ISO/IEC 25059 @isoiec2023software und die Fallstudie von Oviedo Lama et al. @oviedolama2025towards.
  - Für Übersichten: die Surveys von Yu et al. @yu2024evaluation und Gan et al. @gan2025retrieval als Einstieg in verwandte Arbeiten.
]

== Für die Lehre <k09-lehre>

Das Thema eignet sich für zwei Einheiten von je 90 Minuten, die Foliensatz 09 abbildet: eine zu Qualitätsmodellen und Retrieval-Metriken, eine zu Generierungsmetriken, Validität und Vergleich. Das Notebook `09_rag_metrics.ipynb` läuft vollständig offline mit synthetischen Daten; ein optionaler Live-Modus verwendet einen lokalen Ollama-Server oder einen anderen OpenAI-kompatiblen Endpunkt und ist standardmäßig ausgeschaltet. Das ist für eine Hochschule mit eingeschränktem Zugang zu kommerziellen APIs ein Vorteil.

*Bewährter Ablauf der ersten Einheit (90 Minuten).* Zehn Minuten Einstieg mit einem RAG-System, das eine falsche, aber belegt aussehende Antwort gibt. Fünfzehn Minuten Pipeline und Triade (@k09-fig-pipeline, @k09-fig-triade) mit den sieben Fehlerpunkten; die Studierenden ordnen jedem Fehlerpunkt eine Metrik zu. Fünfzehn Minuten ISO/IEC 25010 und 25059 mit der Übung "Qualitätsprofil für einen Prototyp": Jede Gruppe markiert, was ihre Evaluation abdeckt und was nicht. Fünfundvierzig Minuten Retrieval-Metriken von Hand (das Rechenbeispiel aus @k09-retrieval, erst q1 von Hand, dann im Notebook); als Erweiterung die Originaldefinition von Järvelin und Kekäläinen und der Wechsel der Gewinnfunktion. Fünf Minuten Ausblick.

*Zweite Einheit (90 Minuten).* Zwanzig Minuten aussagenbasierte Metriken an der ISO-Frage aus @k09-generierung, mit der Matrix (@k09-fig-ragchecker) an der Tafel. Fünfzehn Minuten "gleicher Name, andere Metrik": zehn Frage-Kontext-Antwort-Tripel, darunter eine Enthaltung, eine Antwort mit unbelegter, aber nicht widersprochener Aussage und eine aufgeblähte Antwort, die sowohl mit RAGAS als auch mit DeepEval bewertet werden (Versionen pinnen, Richtermodell notieren). Die Enthaltung und die nicht widersprochene Aussage trennen die Werkzeuge @ragas2026faithfulness @deepeval2026faithfulness @trulens2026providers. Fünfundzwanzig Minuten Validität: JudgeBench, MEMERAG, GroUSE in Kurzform, dann das PPI-Rechenbeispiel. Fünfundzwanzig Minuten Vergleich zweier Konfigurationen im Notebook, mit Variation von $n$. Fünf Minuten Abschluss mit der Reproduktionsliste.

*Live-Demo.* RAGAS Faithfulness auf dem Einstein-Beispiel der Dokumentation (erwartet 0.5) und Context Precision mit dem relevanten Chunk auf Rang 1 gegenüber Rang 2 (erwartet etwa 1.0 gegenüber 0.5) @ragas2026faithfulness @ragas2026contextprecision. Die Demo ist kurz und zeigt zugleich, dass die Werte nicht exakt 1.0 und 0.5 sind, sondern durch numerische Details knapp darunter liegen.

*Typische Missverständnisse.*
- "Context Precision misst, ob der Retriever die richtigen Dokumente findet." Nein, sie misst die Rangfolge innerhalb des Gefundenen; fehlende Dokumente bestraft sie nicht. Der Satz in @k09-retrieval macht das in einer Zeile klar.
- "Faithfulness 1.0 heißt, die Antwort stimmt." Nein, sie heißt, die Antwort ist (nach dem Urteil des Richters) durch den Kontext gestützt. Ein falscher Kontext ergibt eine treue, falsche Antwort.
- "Answer Relevancy misst, ob die Antwort richtig ist." Nein, sie misst Ausrichtung auf die Frage "without evaluating factual accuracy" @ragas2026answerrelevancy.
- "Ein LLM-Richter mit 87 % Übereinstimmung ist gut." Kommt auf $kappa$ und auf Sensitivität und Spezifität an; das PPI-Beispiel zeigt einen Richter mit 87 % Übereinstimmung und $kappa = 0.51$.
- "nDCG ist nDCG." Gewinnfunktion, Abschlag und ideale Liste unterscheiden sich zwischen Implementierungen.
- "Mehr Fragen machen das Ergebnis richtiger." Mehr Fragen machen das Intervall schmaler; gegen einen verzerrten Richter helfen sie nicht, wie der naive Schätzer in @k09-fig-ppi zeigt.

*Fragen, die im Hörsaal kommen.* Erfahrungsgemäß fragen Studierende, ob man RAGAS "einfach so" in der Arbeit verwenden darf. Die ehrliche Antwort lautet: ja, als Werkzeug, aber nicht als Validitätsnachweis. Die Validierung gegen eine menschliche Stichprobe gehört in jede Arbeit, die richterbasierte Metriken als Hauptergebnis berichtet. Eine zweite häufige Frage betrifft die Kosten: Bei 300 Fragen, drei Läufen, zwei Konfigurationen und vier richterbasierten Metriken entstehen schnell mehrere tausend Richteraufrufe. Eine lokale Ausführung mit einem offenen Richter ist möglich, verschiebt aber die Validierungslast.

*Diskussionsfragen für die Übung.* (1) TruLens behauptet, gute Triadenwerte bedeuteten, eine Anwendung sei "verified to be hallucination free up to the limit of its knowledge base" @trulens2026ragtriad. Unter welchen Annahmen über den Richter wäre das wahr? (2) Sollen Enthaltungen als gestützt zählen? Welchem Merkmal aus ISO/IEC 25059 dient Enthaltung? (3) Was muss ein Reproduktionspaket enthalten, wenn ein Bibliotheks-Update die Richtung einer Metrik umdrehen kann @deepeval2026changelog? (4) Wie groß sollte die menschliche Validierungsstichprobe in der eigenen Arbeit sein, wenn ARES unter 100 bis 150 Labels keine zuverlässigen Rangfolgen erhält @saadfalcon2024ares[Tab. 3]?

#merke[Die drei Sätze, die am Ende der Einheit hängenbleiben sollen: Erstens, jede Metrik gehört zu einer Komponente und einem Qualitätsmerkmal. Zweitens, jede richterbasierte Metrik braucht eine menschliche Validierungsstichprobe und ein Intervall. Drittens, Werkzeug, Version und Richtermodell gehören zu jeder Zahl.]

#selbsttest(
  [Berechne für die Rangliste d3, d1, d4, d2, d5 mit den relevanten Dokumenten {d1: 2, d2: 1, d6: 3} (d6 wurde nicht abgerufen) Precision\@5, Recall\@5, RR, AP, AP\@5 und die Context Precision im Stil von RAGAS bei $K = 5$.],
  [Berechne für dieselbe Rangliste nDCG\@5 mit linearem Gewinn und $log_2(i+1)$-Abschlag. Warum muss d6 in die ideale Liste?],
  [Zeige, dass Context Precision nach RAGAS nie kleiner als die bei $K$ abgeschnittene AP ist, und gib ein Beispiel, in dem ein Retriever mit schlechterem Recall eine höhere Context Precision erhält.],
  [Eine Antwort hat sechs Aussagen. Vier sind aus dem Kontext ableitbar, eine ist nicht im Kontext, widerspricht ihm aber nicht, eine widerspricht ihm. Wie lauten Faithfulness nach RAGAS und nach DeepEval (Voreinstellung)? Welches Konstrukt misst jede?],
  [Ordne die Merkmale functional correctness, robustness, transparency und time behaviour je einer konkreten RAG-Metrik zu. Welche Merkmale aus ISO/IEC 25010:2023 decken die gängigen RAG-Metrik-Suiten typischerweise nicht ab?],
  [Ein LLM-Richter und Menschen beurteilen 100 Antworten. Richter "treu": 80, davon 70 auch von Menschen als treu beurteilt; Menschen "treu" insgesamt: 75. Berechne rohe Übereinstimmung, Cohens $kappa$, Sensitivität und Spezifität.],
  [Der Richter aus Aufgabe 6 bewertet weitere 1900 Antworten, davon 82 % als treu. Berechne den PPI-Schätzer und sein 95-%-Intervall (Richtervarianz auf dem unannotierten Teil mit $0.82 dot 0.18$ ansetzen).],
  [Erkläre, warum der gepaarte Bootstrap Fragen und nicht einzelne Systemwerte zieht, und was passiert, wenn man drei Läufe pro Frage als drei unabhängige Fragen behandelt.],
  [Die Standardabweichung der Differenzen pro Frage sei 0.25. Wie viele Fragen braucht ein gepaarter Vergleich, um eine Differenz von 0.04 mit $alpha = 0.05$ (zweiseitig) und Teststärke 0.8 zu entdecken?],
  [Erkläre den Unterschied zwischen eRAG-Relevanz und topischer Relevanz und nenne je ein Argument für und gegen LLM-Relevanzurteile.],
  [Warum ist die Nugget-Evaluation von TREC RAG für die Rangfolge von Systemen geeignet, aber nicht für die Fehleranalyse einzelner Antworten? Welche Zahlen belegen das?],
  [Eine Arbeit berichtet "Answer Relevancy 0.91, Faithfulness 0.88" ohne weitere Angaben. Formuliere die fünf Rückfragen, die du als Gutachter stellen würdest.],
)

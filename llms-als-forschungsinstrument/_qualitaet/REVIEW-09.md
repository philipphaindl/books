# Review Kapitel 9 - Qualitätsmodelle für RAG

Unabhängiges Review nach REVIEW_PLAN.md (Stand: 11. November 2026). Quellen: Dossier 09-rag-quality-models inkl. verification_report.md (inkl. Residual Pass), Lehrbuch ch8.tex/ch9.tex, Notebook 09_rag_metrics.ipynb und Lösungsnotebook. Testdatei: `_review-09.typ` (46 Seiten, kompiliert fehlerfrei).

## Geprüft und bestätigt

- **IR-Metriken Symbol für Symbol gegen Dossier 4.1:** P@k, R@k (RAGAS-Beispiel 0,25), RR/MRR (Craswell-Wortlaut, RR = 0 ohne Treffer), AP/MAP mit Nenner |R_q| und Manning-Schreibweise, Context Precision (RAGAS) und Contextual Precision (DeepEval), DCG nach Järvelin/Kekäläinen (b = 2, kein Abschlag unter b, Gewinngewichtungen), nDCG nach Manning (2^g - 1, log2(1+m)) und lineare Variante. Satz CP >= AP@K und Wertebereichssatz nDCG samt Beweisskizzen nachvollzogen.
- **Rechenbeispiel IR (python3):** alle 24 Werte und 8 Mittelwerte der Tabelle, Handrechnungen q1/q2, exponentielle Variante, JK-Original (q1 0,639), Code-Ausgabe.
- **RAG-Metriken gegen Dossier 4.3-4.5:** Faithfulness (RAGAS, DeepEval, TruLens), Answer Relevancy, Context Recall, Contextual Relevancy, Factual Correctness, Noise Sensitivity, alle zehn RAGChecker-Formeln, ALCE-Definitionen, Nugget-Scores, CRAG-Truthfulness, TRACe, PPI-Schätzer und -Intervall.
- **Rechenbeispiele:** RAGChecker-Matrix (alle elf Werte), ALCE, Nuggets, CRAG, TruLens, Answer Relevancy (0,80), Kendall-Beispiel, RAGAS-Wald-Intervall, PPI-Beispiel (kappa 0,511, SE 0,0258, [0,739; 0,841], Menschen-Intervall mit Stichprobenvarianz [0,744; 0,856]), n ~ 184.
- **Bootstrap-Beispiel:** Notebook-Simulation mit Seed 2027 reproduziert: Mittel 0,525/0,589, Differenz 0,0634, 64,5 %, KI [0,0328; 0,0934], AR p = 1/5001, Wilcoxon, t-Intervall, sigma_A/sigma_B/rho/s_d, beide Standardfehler, Histogramm der Abbildung bin für bin identisch.
- **Selbsttest-Lösungen 1-9** mit python3 nachgerechnet, alle korrekt.
- **ISO/IEC 25010:2023** (neun Merkmale, alle Teilmerkmale, Vorwort-Änderungen, testability unter maintainability) und **25059:2023** (sieben Elemente, Definitionen, Elternmerkmale, intervenability offen) stimmen mit Dossier 3.2 überein; DIS-Stand korrekt.

## Korrekturen (11)

1. Abb. CI-Breite (k09-fig-ciwidth): Werte stimmten nicht mit dem Lösungsnotebook (Übungsaufgabe 4, Seed 2027 + n) überein; alle fünf Punkte und die Referenzkurve korrigiert (0,1614; 0,1303; 0,0918; 0,0606; 0,0454), Bildunterschrift ergänzt.
2. Zugehöriger Text: Punktschätzungen (-0,021 / 0,006 / 0,102) waren falsch; jetzt 0,053 bis 0,075 mit Intervallen; die Aussage "bei 50 Fragen schließt das Intervall die 0 ein" präzisiert (untere Grenze 0,0001).
3. Stichprobenumfang @k09-eq-power: 917 -> 918 Fragen (Aufrunden, ungerundetes sigma_d 0,2162 jetzt genannt).
4. Fehlerpunkte von Barnett et al.: Die Zuordnung FP -> Metrik war Barnett zugeschrieben, stammt aber aus dem Dossier als Lehrvorschlag; Zitat entfernt, als didaktischer Vorschlag gekennzeichnet.
5. nDCG-Fallstrick: Beispiel "System, das nur irrelevante Dokumente liefert, erhält hohen Wert" war logisch falsch (DCG = 0, IDCG = 0); ersetzt durch System mit wenigen, schwach relevanten, gut sortierten Treffern.
6. Abb. ISO (k09-fig-iso): Legende erklärte nur Teal und Grau; alle Farben erklärt.
7. Gleichung (9.18) NoiseSens lief bis an die Gleichungsnummer; auf zwei Zeilen umgebrochen.
8. Abb. RAGAS-Validierung: Balkenbeschriftungen uneinheitlich ("0,7", "0,4", "1"); jetzt zwei Nachkommastellen.
9. Abb. eRAG: Beschriftung "0,61" -> "0,610" (einheitlich drei Stellen).
10. Abb. Robustheit: Knotentexte brachen hässlich um ("Comple-teness", "= / 0"); Knoten verbreitert.
11. loesungen-09.typ: Textverweise "Abschnitt 9.3/9.8" durch echte Referenzen ersetzt (@k09-eq-ap, @k09-eq-paired, @k09-retrieval) und Gleichungsverweise ergänzt (@k09-eq-pk, -rk, -cp, -ndcg, -faith, -faith-de, -ppi, -ppi-ci, -power, -tau, -nugget); im Anhang geprüft, sie erscheinen als (9.x).

## Offene Punkte

- Zuordnung von intervenability in ISO/IEC 25059:2023 bleibt offen (Volltext nötig); das Kapitel stellt das korrekt dar.
- Versionen und Voreinstellungen (RAGAS 0.4.3, DeepEval 4.3.3 mit `gpt-5.4`, TruLens 2.16.0) vor dem Sommersemester 2027 neu prüfen.
- Preprint-Status von EnterpriseRAG, TRQA, RAGBench, Norman et al. kann sich ändern.
- Die Sätze (Context Precision, nDCG-Wertebereich) haben keine Labels; aus dem Anhang wird deshalb auf den Abschnitt verwiesen. Wer direkte Verweise will, braucht ein referenzierbares Label in `lib.typ` (nicht Teil dieses Reviews).
- Kosmetik ohne Handlungsbedarf: Achsenbeschriftungen in Abb. 4 und Abb. 12 nutzen "0,5"/"1" statt zwei Nachkommastellen.

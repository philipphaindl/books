# Review Kapitel 8 (Bias-Metriken für LLM-Pipelines) - unabhängiges Review

Stand: 11.11.2026. Geprüft gegen `knowledge-base/08-bias-metrics/dossier.md` + `verification_report.md` (inkl. Residual Pass), `book/ch10.tex`, Notebook `08_bias_metrics.ipynb` (gespeicherte Ausgaben), Foliensatz 08 (Gliederung). Testdatei: `_review-08.typ` (39 Seiten, kompiliert fehlerfrei).

## Befunde ohne Korrekturbedarf
- Formeln Symbol für Symbol gegen das Dossier: WEAT s(w,A,B), Teststatistik (Summen), Effektstärke (Mittel / SD über X∪Y), einseitiger Permutationstest mit striktem ">" (Prosa "oder größer" korrekt erwähnt); CrowS-Pairs (Obergrenze |C| wie gedruckt), LPBS, StereoSet lms/ss/icat, BBQ s_DIS/s_AMB (inkl. [UNVERIFIED]-Hinweis zum Repository-Skript als Achtung-Kasten), Gallegos-Metriken auf generiertem Text, BOLD Gender-Wavg, OpinionQA, Unabhängigkeit/Separation/Suffizienz, Hardt Def. 2.1/2.2, Kusner, MGP (Hofmann), discrim-eval, Bai Eq. 1, RR/CR: alle korrekt.
- Alle Rechenbeispiele und Selbsttest-Lösungen mit python3 nachgerechnet: WEAT (1.549/1.789, p = 1/6), Schranken (1.73, 1.87, 1.897; 70 und 12.870 Partitionen), CrowS z = 8.15, ICAT 72.9/71.8/70.5, BBQ 0.12/0.095, Gender-Wavg 0.183, OpinionQA 0.667, Screener (SE 0.0362, KI [-0.011, 0.131]), Teststärke 16/38/86 %, n ≈ 420 bzw. 860, Chouldechova-Identität (0.05/0.01; 0.133/0.05), McNemar (p exakt 0.00069 bzw. 0.47; chi² 12.07), Tamkin 0.731/0.378, Bai 0.625; Lösungen 2-9 (1.897; d = 1.50/1.64, p = 0.05; icat 63; s_AMB 0.06; Screener 0.058/0.813/[0.002, 0.114]; FPR 0.30/0.10; McNemar 5.82/p 0.016, exakt 0.023; 0.105/p 0.75, exakt 0.87). Alles stimmt.
- Notebook-Zahlen (0.0344 Bootstrap-SE, Dreigruppen-Screener 0.188/0.537/0.130, 0.127, 0.003/0.092, Genauigkeit 0.803/0.793/0.802, RR 0.86/CR 0.88, b/c 41/15 und 27/21, Flip-Raten 14/12 %, gepaarter t -2.017 [-2.567, -1.468], t = -7.215, Kontrolle p 0.99, WEAT-Sensitivität 0.55 -> 0.99) stimmen mit den gespeicherten Ausgaben überein.
- Studienzahlen (Caliskan, Nangia, Nadeem, Parrish, Dhamala, Santurkar, Röttger 2024/2026, Hofmann inkl. Nature-Zahlen, An 2024/2025, Armstrong, Wilson, Seshadri, Nghiem, Tamkin, Bai, Lee/Lai mit Vorsichtshinweis, Ye, Laurito, Giorgi, Orlikowski, Occhipinti, Hartmann 2026a/b, Blodgett 2020/2021, Goldfarb-Tarrant 2021/2023, Delobelle 2022/2024, Harvey, Lum, Wang, SHADES) stimmen mit dem Dossier.
- EU AI Act / Digital Omnibus: VO 2024/1689 vom 13.6.2024 (ABl. 12.7.2024), VO 2026/1744 vom 8.7.2026, ABl. 24.7.2026, in Kraft 27.7.2026; Art. 10(5) gestrichen, neuer Art. 4a mit (a)-(f) und Abs. 2; Art. 113: Kap. I-II ab 2.2.2025, neue Verbote ab 2.12.2026, Art. 10 ab 2.12.2027 (Anhang III) bzw. 2.8.2028 (Anhang I); ErwG 40; Art. 4 neu; Anhang III Nr. 4 lit. a. Alles exakt wie im Dossier.
- Lehrbuch-Bezüge (Kleinberg/Chouldechova, Sandvig, Korrespondenz-Audit) gegen ch10.tex geprüft, Keys vorhanden.

## Korrekturen (12)
1. Zeitstrahl (Abb. 16) maßstäblich neu gezeichnet: Punkte taggenau (1511 Tage auf 13.9 cm), versetzte Beschriftungen mit Knickführungslinien bei eng liegenden Daten, Jahresskala 2024-2028, orange Geltungsphase ab 2.12.2027; Caption entsprechend ("maßstäblich", Perspective-Termin als Nicht-Rechtsdatum mit Beleg).
2. Notebook-Aussage zu `scipy.stats.permutation_test` korrigiert: Das Notebook nutzt es mit `n_resamples=np.inf` als exakte Gegenprüfung, nicht als Stichprobenverfahren.
3. Fallstrick ICAT: Aussage "Idealwerte kodieren die Annahme 'kein Einfluss'" war Goldfarb-Tarrant 2023 zugeschrieben; jetzt als Einschätzung gekennzeichnet, der Beleg auf den tatsächlich belegten Befund (gewünschtes Ergebnis in 22 % unklar) bezogen.
4. Einleitung: Zitat @gallegos2024bias an einer Aussage über Verzerrung von Gruppenvergleichen entfernt (eigene Schlussfolgerung, nicht von Gallegos belegt).
5. Definition der Kennzahlen: Δ_FPR, das in Δ_EOdds verwendet wird, explizit definiert.
6. MGP-Definition: nicht bedeutungsgleiche Variante als nummerierte Display-Gleichung (`<k08-eq-mgp2>`) mit Summengrenzen und Lesart, statt gequetschter Inline-Formel.
7. ICAT-Abbildung: fehlende Zeltkurve für lms 85.9 (GPT-2 medium) ergänzt; Legende farbgleich mit den Punkten (vorher schwarzer Legendenpunkt, Punkte farbig, medium ohne Kurve).
8. Screener-Abbildung: Balkenbeschriftungen einheitlich zweistellig (0.30, 0.80, 0.70 statt 0.3, 0.8, 0.7).
9. Fallstrick RR/CR: "hat höchstens CR = 0.88" -> "hat CR = 0.88" (logisch falsch).
10. Sprache: "Lum et al. hat" -> "haben"; "im Rahmen CALM" -> "im Rahmen von CALM".
11. Layout: Beweisskizzen lokal unumbrechbar (Überschrift "Beweisskizze" stand allein am Seitenende); `fairness.py` unumbrechbar (eine Codezeile allein am Seitenende).
12. Lösungsdatei: echte Gleichungsverweise ergänzt (@k08-eq-zerlegung, -dpop, -icat, -sdis, -samb, -sr-basis, -chould, -mcnemar); Lösung 3 präzisiert (p = 0.05 bei Konvention p <= alpha gerade signifikant, mit strikter Originalformel p = 0).

## Offene Punkte
- BBQ s_AMB: Lesart "Anteil über mehrdeutige Antworten" bleibt [UNVERIFIED] (Skripte im BBQ-Repo nicht einsehbar); im Kapitel als Achtung-Kasten korrekt markiert.
- ICAT-Abbildung: Die drei GPT-2-Punkte liegen sehr eng; eine Ausschnittvergrößerung wäre lesbarer (kosmetisch, nicht umgesetzt).
- Zeitbedarf und Übungsdauern im Abschnitt "Für die Lehre" sind Einschätzungen ohne Quelle (als solche erkennbar).

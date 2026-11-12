# Review Kapitel 5 "LLMs als Annotatoren"

Unabhängiges Review nach REVIEW_PLAN.md, 11. November 2026. Geprüft: `kap05-annotation.typ`, `loesungen-05.typ` gegen Dossier und `verification_report.md` (KB 05), Lehrbuch ch3.tex/ch4.tex, Folien `05 LLMs as Annotators/` (v. a. 06, 07), Notebook `05_agreement_and_codebooks.ipynb`. Testdatei: `_review-05.typ` (44 Seiten, kompiliert fehlerfrei).

## Mathematik (alles mit python3 nachgerechnet)

- Herleitungen Symbol für Symbol geprüft: allgemeine Form (Eindeutigkeit der affinen Abbildung), Cohen, gewichtetes Kappa (Reduktion auf Kappa), Scott, Satz kappa >= pi (Identität (a+b)^2/4 - ab, Monotonie g'(p_e)), Fleiss (P_i, P_e, r = 2 -> Scott), Randolph >= Fleiss (Cauchy-Schwarz), Krippendorff (Koinzidenzmatrix, D_o, D_e, drei Metriken, Zwei-Codierenden-Formel), AC1 (binär p_e^G = 1 - p_e^S), PABAK/BP, ICC-Formen nach McGraw & Wong, Prävalenzsatz (kappa und AC1 bei symmetrischen Marginalien), SE-Näherung, ARI (Erwartungswert, Maximum), ITS. Korrekt bis auf die unten genannten Präzisierungen. Zusätzlich numerisch geprüft: kappa >= -1 mit -1 nur bei p_o = 0, p_e = 0,5.
- Alle 11 Rechenbeispiele reproduziert: E1, E2a-c, E3a-b, E4 (Fleiss 0,667/0,623, paarweise kappa, alpha 0,6759/0,6667), E5 (alle 12 Kennzahlen, Koinzidenzmatrix, delta^2), E5-ICC (SS/MS, alle ICC-Formen = pingouin 0.7.0), E6 (statsmodels SE/CI, n ~ 196, Abbildungspunkte), E7 (Code ausgeführt: 0,7015, [0,542, 0,840], 0,35/0,93, Histogrammzahlen der Abbildung), Alt-Test-Simulation, E8 (ARI 0,3663, RI 0,7879), E9 (0,352/0,277/0,263). Alle 12 Selbsttest-Lösungen nachgerechnet.
- Code ausgeführt: `alpha_hand.py` (= krippendorff 0.9.0), `bootstrap_alpha.py`, `alt_test.py` (= Notebook), `ari.py`, `induktiv.py` (mit Mock-LLM).

## Korrekturen

1. Beweis Zwei-Codierenden-alpha: Die Bemerkung "gilt für beliebig viele Codierende, solange alle Einheiten gleich viele Werte haben" war zu eng; die Formel gilt für jede Koinzidenzmatrix, auch mit fehlenden Werten (so auch im Verifikationsbericht, 2.1 Nr. 7; Lösung 5 nutzt genau das).
2. Satz kappa >= pi: Gleichheitsbedingung nur für p_o < 1 (bei p_o = 1 sind beide 1); Beweis entsprechend ergänzt (strenge Monotonie).
3. Simulierter Alternative Annotator Test: Die Werte für das 70-%-LLM (rho 0,870, omega 1,00 bei epsilon 0,2) stammen aus dem Dossier und sind mit dem Simulator des Notebooks (Seed 7) nicht reproduzierbar. Notebook-Ausgabe und eigene Rechnung: rho 0,820, omega 0,00 bzw. 0,67. Tabelle und Text korrigiert, realisierte Genauigkeiten angegeben; Aussage ("besteht" bei epsilon 0,2) bleibt.
4. `induktiv.py`: `str.format` auf die Prompt-Vorlagen wäre mit KeyError abgebrochen (JSON-Beispiele mit `{}` in den Vorlagen, `{frage}` nicht übergeben). Ersetzt durch Helfer `fill`, Parameter `frage` ergänzt, mit Mock getestet.
5. ARI: Herleitung von E[a] sauber über zufällige Permutation und Linearität des Erwartungswerts; Begründung, warum der Mittelwert eine obere Schranke ist.
6. Halterman & Keith: Zero-Shot-Spannen als Werte des umstrukturierten Codebuchformats gekennzeichnet, Originalformat Manifeste bis 0,21 (Verifikationsbericht CONSIDER 4).
7. Alizadeh et al.: Feinabstimmungsgewinne als "im Paper als Prozent angegeben" gekennzeichnet (CONSIDER 5).
8. Liu (2026): fehlendes Zitat beim Mehrheitsvotum ergänzt, "paarweise" Übereinstimmung präzisiert.
9. "Für die Lehre": Das Notebook rechnet E1 bis E8, nicht E9 (geprüft); korrigiert.
10. Lösung 5: Logikfehler "fehlende Werte nicht zufällig fehlen dürfen" -> Werte müssen zufällig fehlen; hier fehlen sie systematisch bei übereinstimmenden Fällen.
11. Gleichungsverweise in `loesungen-05.typ`: (5.5), (5.7), (5.13), (5.22) durch `@k05-eq-wkappa`, `@k05-eq-scott-cohen`, `@k05-eq-alpha-nom`, `@k05-eq-se` ersetzt; im PDF als (5.5)/(5.7)/(5.13)/(5.22) mit Link geprüft.
12. Darstellung: Abb. 6 Beschriftung "E2c" überlappte die Kurve (verschoben); Abb. 12 (Workflow) wurde "1. ..." als Aufzählung gesetzt und Knotentexte schlecht getrennt (Enum-Marker escaped, Knoten 36 mm); Abb. 1 und 2 unschöne Silbentrennung in Knoten behoben; Satzende in der Alt-Test-Box lesbarer.

## Inhaltlich ohne Befund

- Induktive Codebuch-Ableitung (5.10): Workflow, Schritte 1-7, Fallstricke, Prompts, Studienboxen (Dai, De Paoli, Parfenova, De Paoli & Mathis inkl. der im Dossier aufgelösten "Interview 20"-Aussage, DeRegnaucourt, van den Berkmortel, Bergmann inkl. 0,89-Hinweis), Vergleichsmaße, ITS-Operationalisierung U_K/T_K, Vertrauenswürdigkeitstabelle stimmen mit Dossier 4.16, Folien 06/07 und Lehrbuch (ch3: referential adequacy, negative case analysis, stepwise replication, inquiry/confirmability audit, theoretical sampling, analytical generalisation, cross-over mixed analysis; ch4: open/axial/selective coding, "hundreds" of codes, saturation vs. repetition, kappa > 0,80) überein.
- Stichproben der Studienzahlen (Gilardi, Törnberg, Rathje, Pangakis, Ziems, Reiss, Baumann, Calderon, Xiao, Chew, Dunivin, Atreja, Liu, McLaren, Wang, Gwet, Hayes & Krippendorff) gegen das Dossier: korrekt. Sprache: Umlaute, keine Gedankenstriche, Du-Form.

## Offene Punkte

- Dossier 4.13 (Alt-Test-Tabelle) und Verifikationsbericht 2.2 Nr. 19 widersprechen dem Notebook; das Dossier sollte auf rho 0,820 / omega 0,67 korrigiert werden (nicht Teil dieses Kapitels).
- Laut Verifikationsbericht nicht erneut geprüft (COULDN'T-VERIFY): Chew-Zahlen, Wang 2026, McLaren 2026, Heseltine "bis zu 95 %", Törnberg 2024 (20-30 pro Kategorie). Im Kapitel als Befunde dargestellt, wie im Dossier.
- E8-Box bricht in der Testdatei zwischen Seite 31 und 32 um (Kopf allein unten); im Gesamtbuch erneut ansehen.

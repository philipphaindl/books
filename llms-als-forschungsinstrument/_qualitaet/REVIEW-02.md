# Review Kapitel 02 (Design Science Research und generative KI)

Unabhängiges Review nach REVIEW_PLAN.md. Quellen: Dossier und verification_report Modul 02, Lehrbuch ch2.tex/ch3.tex, Foliensatz 02 (inkl. 06-genai.typ, REVIEW.md), Exercise 02. Testdatei: `_review-02.typ` (41 Seiten, kompiliert fehlerfrei).

## Befunde und Korrekturen (14)

1. **Amalfitano et al., Quadranten-Anordnung (Schwerpunkt):** Weder Dossier (Abschn. 3.12, 5.4) noch Folien (06-genai.typ) noch verification_report belegen, welche der vier Formen (GenAI Copilot, GenAIware, GenAI Teammate, GenAI Robot) welcher Kombination aus Prozess/Produkt und passiv/aktiv entspricht. Die erschlossene 2x2-Abbildung `k02-abb-amalfitano` wurde entfernt; der Text nennt jetzt Dimensionen und Formen getrennt und sagt ausdrücklich, dass die Zuordnung offen ist und an der Originalarbeit zu prüfen wäre. Kein Querverweis auf das Label war betroffen.
2. Amalfitano, Absatz zu den drei Zyklen: fehlender Zitierschlüssel am Absatzende ergänzt.
3. Überschrift "Generative KI verändert DSR doppelt" passte nicht zu den drei Rollen im Text -> "Drei Rollen generativer KI in DSR".
4. Lehrbuch "verdichtet die Richtlinien zu drei Qualitätskriterien" -> "nennt drei Qualitätskriterien" (ch2.tex sagt nicht, dass die Kriterien aus Hevners Richtlinien verdichtet wurden).
5. DSRM-Einstiegspunkte: Die Erläuterungen "typisch, wenn ..." stehen nicht im Dossier -> als eigene Lesehilfen gekennzeichnet.
6. "Die DSRM ist das in der GenAI-Literatur am häufigsten verwendete Prozessgerüst" -> auf die Beispielstudien des Kapitels eingeschränkt (so im Dossier).
7. Prat et al., "meist Muster 2" -> als Einschätzung des Dossiers gekennzeichnet (Häufigkeiten nicht verifiziert).
8. Reinhard et al. 2026, FEDS-Einordnung: war nicht als eigene Einordnung gekennzeichnet und eher unplausibel ("naturalistisch" bei Think-aloud mit Nicht-Domänenprofis) -> "Eigene Einordnung: eher artifiziell und formativ".
9. Klievtsova-Rechenbeispiel: "Label kippt mit fast 50 % Wahrscheinlichkeit zwischen zwei Läufen" ging über die Quelle hinaus (52 % gleiches Label über Generierungen) -> umformuliert.
10. Lehrbuch-"Hauptbuch": an ch3.tex angeglichen (dort ist der Limitationsabschnitt das "ledger").
11. "rund 40 Inhaltsfolien" nicht prüfbar -> "insgesamt 55 Folien" (pdfinfo des Foliensatz-PDFs).
12. Sprache: "Ergänzend sind zwei Modellartefakte und Methodenartefakte" -> "ein Modell- und ein Methodenartefakt"; "mit welchem Rubrik" -> "nach welcher Rubrik".
13. Darstellung: doppelte Klammern "((2.16))" in der Bildunterschrift Abb. 12 behoben; FEDS-Abbildung Seitenangabe auf "Abb. 2, S. 80-82" angeglichen.
14. Lösungen: "Zählratenverhältnis" -> "Inzidenzratenverhältnis" (wie im Kapitel); echte Gleichungsverweise ergänzt (Aufgabe 4 -> @k02-eq-kcf, Aufgabe 5 -> @k02-eq-irr).

## Geprüft ohne Befund

- Alle GenAI-Studien 2023-2026 gegen Dossier und verification_report: Reinhard 2026 (n = 13/12/8, 107, 191, DF1-DF7), Reinhard 2025, Klievtsova 2023 (17/21, 12/21, GPT-3 7/6, Tab. 15, 43 %, 52 %, Jaccard/Precision, 69 % vs. 19 %), Brehmer & Buonassisi 2024, Iftikhar & Rausch 2026 (540 Experimente, SI-Werte), Jin 2026 (R² der Kaufabsicht, Korrektur 6 des Verifiers berücksichtigt), Memmert 2023 (beide), Böhmer 2025 (richtungsneutral, Korrektur 9 berücksichtigt), Gau 2025, Gau & Gnewuch, Strohmann 2026, zur Heiden 2026, Abbasi 2024, Blohm 2025 (drei Rollen, Korrektur 8 berücksichtigt), Fill 2026, Feuerriegel 2024, Verma 2026, Grau 2025. Abschaltdaten der Modelle stimmen mit Dossier Abschn. 8 überein.
- Klassiker (Hevner, Peffers, Gregor & Hevner, Gregor & Jones, Gregor et al. 2020, FEDS, ADR, Wieringa, Engström, Wagner, Reiners) inkl. Seitenangaben; CONSIDER-Punkte des Verifiers (Brehmer "keine Kontrollgruppe" als eigene Einschätzung, "erfundene Quellen" bei Gau & Gnewuch, Hevner S. 77-79) sind im Kapitel bereits korrekt umgesetzt.
- Lehrbuch-Aussagen (MapReduce, Public-Key-Kryptografie, Demonstration = Machbarkeit, Action-Research-Zyklus, fünf Validitätskriterien, mehrere Evaluationstypen, Designtheorie-Elemente) gegen ch2.tex/ch3.tex.
- Mathematik mit python3 nachgerechnet: e^beta-Werte, 17/21 und 12/21, BPMN- und Codebuch-Beispiel, Jaccard-F1-Beziehung und Beweis, Varianzzerlegung (Beweis und KoDa-Daten: 0,00121/0,00068/0,00188, SI 0,998), Dossier-SI 0,988, Schranke 0,8 (Popoviciu) und 0,605 bei ddof = 1 (gültige, nicht scharfe Schranke; 0,77 ist mit ddof = 1 erreichbar), SI 0,95 -> SD 0,23, A = 0,858, Selbsttest-Lösungen 7 und 8.
- Exercise-02-Angaben (fünf Aufgaben, Temperatur 0 und > 0, LLM-Log, Open-Weight-Empfehlung, Aufgabe 5 ohne LLM).
- Kontaktabzüge aller 41 Seiten, Problemseiten in 90 dpi: keine Überläufe, keine gesprengten Kästen, Formeln intakt.

## Offene Punkte

- Amalfitano et al.: Zuordnung der vier Formen zu den Quadranten an der Originalarbeit (arXiv 2510.26275 bzw. TOSEM) prüfen; erst dann ggf. die 2x2-Abbildung wieder aufnehmen.
- Abb. 13 (Zeitleiste): Die gelbe Verbindungslinie zu "gpt-4o-mini u. a." streift die Jahreszahl 2027; rein kosmetisch, nicht geändert.
- Zahlenformat: Im Kapitel stehen Dezimalzahlen in Formeln mit Punkt, im Fließtext mit Komma; buchweit einheitlich zu klären, im Kapitel nicht geändert.

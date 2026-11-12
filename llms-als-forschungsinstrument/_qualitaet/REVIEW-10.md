# Review Kapitel 10 - Reproduzierbare Forschungs-Workflows mit LLMs

Geprüft am 11.11.2026 gegen `knowledge-base/10-applied-research-workflows/dossier.md`, `verification_report.md` und Lehrbuch `ch5.tex`, `ch7.tex`, `ch9.tex`, `ch10.tex`. Testdatei: `_review-10.typ` (42 Seiten, kompiliert fehlerfrei).

## Geprüft und bestätigt (ohne Änderung)
- Alle Preise (Opus/Sonnet/Haiku 5.5, Gemini 3.5 Flash, 3.1 Pro), Cache-Multiplikatoren (1,25x/2x/0,1x bzw. 0,05x), Batch-Limits (100.000/256 MB/29 Tage; 50.000/200 MB/2000 pro h/30 Tage), `inference_geo` 1,1x, OpenAI-Residency +10 %.
- Versionen: Inspect 0.3.289, lm-eval 0.4.13, promptfoo 0.125.1, DSPy 3.5.0, MLflow/mlflow-tracing 3.18.0, vLLM 0.33.0; Anthropic-API-Versionen und Parameter-Scope (2023-06-01 vs. 2026-10-21, Claude 4.6/4.7).
- Rechtsdaten: Art. 4 ab 2.2.2025, Aufsicht 2.8.2026, VO (EU) 2026/1744 vom 8.7.2026, in Kraft 27.7.2026, Hochrisiko 2.12.2027/2.8.2028, Kennzeichnung 2.8./2.12.2026; EDPB 28/2024 vom 17.12.2024.
- Leitlinien: TRIPOD-LLM 19/50 (14/32), GUIDE-LLM 14 Items in 7 Gruppen, Delphi 68/105 und 80, REFORMS 32/8, CHART 12/39, 531/48; llm-guidelines.org must/should korrekt.
- Studienzahlen (Atil, Ouyang, Chen, He, Cooper, Yuan, Nicholson, Messina, Baumann, Biderman, Cao, Dai, Figalova, Gartlehner, Lieberum, Walters, Rao, CiteAudit, CORE-Bench).
- Mathematik mit python3 nachgerechnet: Snapshot-Lebensdauern (alle 9, Median 14,0), Nichtassoziativität (b=c=4 und Lösung b=c=3), P_N für pi=0,95/0,9, Beweis der Monotonie, Mehrheitsentscheid 0,896/0,94208, Wald-KI ±5,5, Jaccard 0,6, alle Kostenszenarien (108/54/20,80/23,80/49,60/70,60), Reasoning 208/70,80, Stabilität 5,20, r=1,1 -> 22,88, Haiku 5,40/2,70, Break-even 0,208/0,513 inkl. Herleitung, Screening (73/19/92; 174/112/286), kombinierte Sensitivität 0,966, Zitationswahrscheinlichkeiten 0,704/0,996. Alles korrekt.
- Lehrbuch-Aussagen (ch5 emerging approaches/version sensitivity, ch7 Methodenteil/Instrumente, ch9 Spektrum/Drift/Temperatur/"used GPT"/Asymmetrie, ch10 Offenlegung/Autorschaft/Belmont/Fußabdruck) belegt.

## Korrekturen
Fachlich (5):
1. bfloat16 hat 7 gespeicherte Mantissenbits (8 Bit Genauigkeit inkl. implizitem Bit), nicht "acht Bit Mantisse".
2. Nicholson: Caveat aus verification_report (CONSIDER 1) ergänzt - lokaler Lauf mit Batch-Größe 1 und festen Seeds, Ursache offen.
3. Zitierschlüssel: Hash-Eigenschaft "ein Leerzeichen ändert den Hash" war mit @baltes2025guidelines belegt; jetzt Notebook-Beleg plus korrekte Aussage der Leitlinie (Prüfsummen/Fingerprints, Sec. 5.2.2).
4. Figalova: 82,3-82,9 % gelten für menschliche Screener und GPT-5.4-Dateibatches, nicht "andere Modi".
5. CiteAudit-Fundstelle präzisiert (Sec. 3, Table 1; Sec. 5.3, Table 4); Walters "Jahr" -> "Datumsangaben" (dossier: dates) - als Teil dieses Punkts gezählt.

Mathematisch (0): keine Rechenfehler gefunden. Lösungsdatei: Text-Gleichungsnummern (10.5) und (10.8) durch `@k10-eq-tar-modell` und `@k10-eq-kosten` ersetzt, zusätzlich zwei Verweise auf `@k10-eq-breakeven`; im 1-Stunden-Break-even p_write=4 explizit genannt.

Darstellung/Sprache (5):
1. "Kapitel 9" -> Lehrbuch-Kapitel über KI-basierte Systeme ("für Kapitel 9" war falsch formuliert).
2. Abb. 2: Silbentrennung "Batch-In-varianz" im Knoten behoben (Knotentexte umgebrochen, Breite 32 mm).
3. Abb. 3: Token-103-Knoten berührten sich, Diagramm war breiter als der Satzspiegel; Abstände und Breiten angepasst.
4. Tab. Preise: Caption erklärt jetzt, warum OpenAI fehlt (vorher Hinweis auf nicht vorhandene Zeilen).
5. Unbelegte Floskel "vier haben sich besonders bewährt haben dürften" ersetzt.

## Offene Punkte
- DPF-Berufung, Ollama/llama.cpp-Versionen: im Kapitel nicht verwendet, daher kein Handlungsbedarf.
- Seite mit "Für die Lehre" hat etwas Weißraum unten (Umbruch vor Übungsliste), unkritisch.
- Kapitel nennt den exakten datierten Sonnet-5.5-Snapshot nicht (Wissensbasis hat nur `claude-sonnet-5-5`); bewusst als Hinweis im Text belassen.

# Review Kapitel 3 - Prompt- und Context-Engineering als Messproblem

Unabhängiges Review nach `REVIEW_PLAN.md`, 11.11.2026. Geprüft: `kap03-prompt-context.typ`, `loesungen-03.typ` gegen `knowledge-base/03-prompt-context-engineering/dossier.md` (inkl. `verification_report.md` mit Residual-Pass), Folien `03 Prompt and Context Engineering/*.typ` und `REVIEW.md`, Lehrbuch `ch9.tex`, Notebook `03_prompt_sensitivity_and_cost.ipynb`. Testdatei `_review-03.typ` (Kapitel, Lösungen, Literatur), kompiliert fehlerfrei, 41 Seiten, alle Seiten als Kontaktabzug geprüft.

## Ergebnis der Prüfung

- **Preise, Modellnamen, Caching/Batch:** Preistabelle (Opus/Sonnet/Haiku 5.5, gemini-3.5-flash, gemini-2.5-pro, gpt-6.1-sol/-terra, gpt-6-luna), Cache-Faktoren (Anthropic w 1.25/2, r 0.1 bzw. 0.05 für Opus/Sonnet 5.5; OpenAI ab GPT-5.6 r 0.1 bzw. 0.05, w 1.25/2.5 "total write rates"; Gemini r = 0.1 als abgeleitet gekennzeichnet), Batch-Konditionen (50 %, Laufzeiten, Limits, "30 percent to 98 percent"), Invalidierungsregeln, Effort-Stufen und 1M-Kontext-Preisregel stimmen mit Dossier 4.6/8.1, Stand 11.11.2026, überein.
- **Rechnungen (python3):** GlobalE, Kalibrierung, Condorcet-Kurven und Abb. 3, d_k und E[max Z] (inkl. Monte-Carlo 9.4/13.3/6.0 und 11.7 Punkte), Varianzzerlegung, MaxP/AvgP/Sat/CPS, Kendall W = 0.644 und tau, Schwellen, Optimismus, Kostenmodell (45.00 / 350.00 / 16.50 / 22.50 / 8.61 / 20.85 USD, h* = 0.208/0.513/0.217, 52.50 USD bei h = 0), Thinking-Aufschlag, Kompression, Langkontextplan sowie alle 12 Selbsttest-Lösungen nachgerechnet: korrekt.
- **Tam et al.:** korrekt als Formatanweisung im Prompt (nicht JSON-Modus, nicht constrained decoding) eingeordnet, DDXPlus-Vergleich like-for-like (41.6 vs. 60.3, Tab. 10).
- **DSPy/GEPA-Code:** Metrik-Signatur, `dspy.Prediction(score, feedback)`, `dspy.GEPA(metric, auto="light", reflection_lm=dspy.LM("openai/gpt-4o"))`, `compile(student, trainset, valset)` wie auf der geprüften Folie 25; zusätzlich nur `dspy.configure(...)` und eine Test-Auswertung.

## Korrekturen (16)

1. Beweisskizze Mehrheitsentscheidung: Monotonie-Schritt war unvollständig (Differenz p^2 - (1-p)^2 ohne die Binomialgewichte). Jetzt vollständige Rechnung P_(N+2) - P_N = c (p(1-p))^((N+1)/2) (2p - 1).
2. Beweisskizze Kendalls W: vage "Umordnungsungleichung"-Schlusssatz durch sauberes Argument ersetzt (Summe der R_j^2 als Summe paarweiser Skalarprodukte von Permutationen, Gleichheit genau bei identischen Rangfolgen).
3. Satz Optimismus: "wachsen wie sqrt(2 ln k)" auf asymptotische Aussage präzisiert (für k = 20: 2.45 statt 1.87).
4. Fallstrick Rauschboden: missverständliches "Obergrenze bei unabhängigen Stichproben" korrigiert (gilt für unabhängige Stichproben; bei gepaarten Items positiv korreliert, dann eher Obergrenze).
5. Abb. 3 Bildunterschrift: "die ersten Samples bringen den größten Teil des Gewinns" stimmte für p = 0.6 nicht (1 -> 5: 8.3 von 30 Punkten); umformuliert.
6. Abb. 2 (Kojima): "Zwei Wörter" -> "Drei fehlende Wörter" ("step by step").
7. Tam/JSONSchemaBench-Versöhnung: Aussage, ein Begründungsfeld vor dem Antwortfeld beseitige den Verlust, war Tam et al. zugeschrieben, ist dort aber nicht getestet. Jetzt: für NL-to-Format belegt, für die Feldreihenfolge Hypothese.
8. Tam-Grenzen: 49.3 in Tab. 10 ist "JSON" beschriftet, nicht JSON-Modus; präzisiert.
9. Tab. "Strukturierte Ausgaben": Zeile "Cache" enthielt auch Nicht-Cache-Hinweise -> "Weitere Hinweise"; Gemini-Aufruf als Interactions API gekennzeichnet (Dossier 8.1).
10. Self-Route: "rund 94 Prozent" -> "rund 93 Prozent" (46.41/49.70 = 0.934).
11. Notebook-Verweis: Ausschnitt entspricht den Hilfsfunktionen aus Abschnitt 1 und 4 (Kendall W steht in Abschnitt 4).
12. Abb. 8 (Tam): Balkenbeschriftungen 86.51/86.99 überlappten; Balkenbreite erhöht.
13. Budgetbeispiel: Preise jetzt mit `@anthropic2026pricing` belegt (Cache-Schreibpreis 2.50 steht nicht in der Preistabelle).
14. Preistabelle: Gemini-Speicherpreis für explizite Caches ergänzt (Dossier 8.1).
15. Langkontextplan: Batch-Betrag als abgeleitete Rechnung gekennzeichnet.
16. Lösungen: Begründung zu theta = 0.51 nicht mehr Meincke et al. zugeschrieben; h* = 0.625 mit Stand, Quelle und "abgeleitet" gekennzeichnet; Lösung 6 mit Referenz auf Gl. (3.14).

## Offene Punkte

- Kapitelumfang: ca. 33 Seiten Kapitel (Plan: 40-60 Seiten, mindestens 14.000 Wörter) - nicht erweitert.
- Alle Preise, Modellnamen (Claude 5.5, GPT-6/6.1, Gemini 2.5/3.5), Cache-/Batch-Parameter und die DSPy-GEPA-API (`auto`-Werte) vor dem SS27 neu prüfen.
- Meincke et al. Report 2: Vorzeichen der Tabellen S3/S4 folgen dem Text (im Kapitel offengelegt); vor Einzelwerten auf Folien nochmals prüfen.
- Abb. 11 (Lost in the Middle): der Delta-Pfeil kreuzt knapp die Datenlinie bei Position 12.5, kosmetisch, nicht geändert.
- `greshake2023not`: Erstautor der publizierten Fassung (Abdelnabi) - im Text erwähnt, Schlüssel unverändert.

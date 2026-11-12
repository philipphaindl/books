# Review Kapitel 4 "LLMs als Forschungsinstrument"

Unabhängiges Review nach REVIEW_PLAN.md, 11.11.2026. Geprüft: `kapitel/kap04-forschungsinstrument.typ`, `kapitel/loesungen-04.typ` gegen Dossier und `verification_report.md` des Moduls 04-llms-as-research-instruments, Lehrbuch ch9.tex/ch3.tex, Notebook `04_silicon_sampling_validity.ipynb` und Foliensatz-REVIEW. Testdatei: `_review-04.typ` (43 Seiten inkl. Lösungen und Literatur, kompiliert ohne Fehler).

## Befunde

### Fachliche Richtigkeit
Alle Studienzahlen (Argyle, Bisbee, Santurkar, Wang, Dominguez-Olmedo, Pew/Chapekis, Verasight, Lam, Lukauskas, Park 2023/2024, Suh, Kolluri, Aher, Horton, Hewitt/Ashokkumar, Li & Ji, HumanStudy-Bench, Cui, Centaur, Schröder, Si, AI Scientist, Beel, Agents4Science, Ravideshik, Ziems, Scherbakov, OpenScholar, GUIDE-LLM) stimmen mit dem Dossier überein. Lehrbuchaussagen (Versionsdrift, Kontaminationsstrategien, Nichtdeterminismus, Temperatur 0, "used GPT", Deprecation-Asymmetrie, Sclar/Mizrahi, Messinvarianz) stimmen mit ch9.tex/ch3.tex überein. Notebook-Angaben (1.000 Befragte, 12 Items, Gruppenlücke x1.6, Streuung x0.4, Kalibrierungssteigung > 1, neun Übungen, 51 Folien in sieben Abschnitten) stimmen.

### Mathematik (alles mit python3 nachgerechnet)
Log-Prob-Rating 4.74; NA 0.826; Cramérs V 0.408; WD/Alignment 0.60/0.80 und 0.30/0.90; JSD 0.227 (KL 0.189/0.266), Q2 0.021; normierte Entropien 0.92/0.28/0.84; Fallzahl 174.4 bzw. 19.4, Faktor 1/9; Bisbee-Faktor 1/8.5; NLL 0.383; Abrufbeispiel 1.00/2.22/1.50; Agents4Science 15.2 %/19.0 %/0.64/0.23; Pew-Mittel 12.4. Selbsttest 3 (WD 0.7, A 0.767, JSD 0.235, H 1.971/0.922/1.681), 5 (Faktor 0.25, n 175/44, Power 0.29), 6 (0.83), 10 (1.571/1.690/1.500): alle korrekt. Beweise (Abschwächung, WD über CDF, Wertebereich, JSD-Eigenschaften, Verzerrungsfaktor) geprüft und korrekt.

### Darstellung
Kontaktabzüge aller Seiten geprüft, keine Überläufe oder leeren Seiten.

## Korrekturen (14)
1. Abb. 1: Kantenbeschriftungen auf die linke Seite verlegt (überlappten mit der Interrogations-Kurve).
2. Abb. 11 (Generative Agents): Label "neue Erinnerung" aus dem Pfeilzwischenraum nach außen.
3. Abb. 13 (AI Scientist): breitere untere Kästen, fließender Text, Quellen je Kasten, geschützte Leerzeichen.
4. Abb. 15 (Debatte): "kein Beleg in der Literatur" -> "von keiner hier besprochenen Studie gestützt"; Messeri und Crockett aus der Spalte "Keines" genommen (vertreten diese Position nicht), Caption ergänzt.
5. Hewitt-Zahlen durchgehend als Preprint 2024 gekennzeichnet ($r_adj$ im Satz-Kontext, Hörsaalfrage unveröffentlicht/veröffentlicht, Skalierungsfaktor 0.56, Modellvergleich geschlossen/offen).
6. Tab. 1: "Lesezeiten" -> "Antwortzeiten" (Dossier: response times), "so gut" -> "ähnlich gut"; Caption nennt Messinvarianz als Ergänzung aus dem Lehrbuch.
7. Satz Wertebereich des Alignments: Aussage zu "Wert 0" präzisiert (Summand pro Frage vs. Mittel über Fragen).
8. Fallzahlbeispiel: tatsächliche Power bei n = 20 ergänzt (0.16).
9. Li-&-Ji-Beispiel und Lösung 8: Mechanismus als Deutung gekennzeichnet (Li & Ji berichten nur den Betrag des ATE-Fehlers), Notebook-Gegenbeispiel (Effektübertreibung) ergänzt.
10. Kleinere Präzisierungen: Park 2024 (KI-geführte Interviews), Argyle (Stimmenanteil 2020), Pew-Satz zu nie gewählten Optionen, Lukauskas (Psychometric Similarity Score), Kolluri (Modell für 0.219 -> 0.063), Log-Prob-Beispiel (Temperatur 1), Messeri-Verweis "übrige drei Visionen".
11. Manuelle `kind: table, supplement: [Tab.]` entfernt (main.typ setzt das jetzt global).
12. Lösungen: echte Gleichungsverweise (@k04-eq-instrument, -wd-cdf, -align, -jsd, -atten, -retrieval) und @k04-tab-bedrohungen statt Text.
13. Lösung 6: Hinweis, dass NA ein Quotient von Trefferquoten ist und die Analogie zur Abschwächungsformel nur sinngemäß gilt.
14. Lösung 12: GUIDE-LLM-Zuordnung korrigiert (Zugangsweg ist bekannt; Begründung der Modellwahl ist ein optionaler Punkt).

## Ausgewogenheit Pro/Contra
Ausgewogen: eigener Abschnitt "Wo es funktioniert" (Park 2024, Suh, Kolluri mit Schranken), Hewitt, Centaur, Mangiaterra als positive Belege, bedingte Pro-Position in 4.7, Missverständnis "Kritiker halten es für nutzlos". Keine Änderung nötig.

## Offene Punkte
- Hewitt/Ashokkumar: Detailzahlen weiterhin nur aus dem Preprint 2024; Abgleich mit dem _Nature_-Volltext steht aus (im Kapitel benannt).
- Kapitel hat ca. 37 Seiten (ca. 19.800 Wörter Quelltext), also unter den im BUCH_PLAN genannten 40-60 Seiten; inhaltlich vollständig, keine Ergänzung im Review.
- Einige Hörsaal- und Studienkästen brechen über Seiten (Frage und Antwort getrennt); vertretbar, beim Gesamtumbruch ggf. prüfen.

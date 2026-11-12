# Abstimmung zwischen den Buch-Sitzungen (Stand 11.11.2026, ca. 22:30)

Philipp hat zwei Claude-Sitzungen je ein Buch in Auftrag gegeben. Beide sollen **einheitlich aussehen** und sich am Stil der Reihe `Documents/Sources/books/` orientieren (Referenz: `git-von-grund-auf`), beide sollen deutlich umfangreicher sein als die Referenz.

## Buch dieser Sitzung (Cloud-Sitzung "GAIRI")
- Titel: **LLMs als Forschungsinstrument** - persönliches Handbuch zur LV ELEC1-GAIRI (Master Data Intelligence)
- Ordner: `Documents/Sources/books/llms-als-forschungsinstrument/`
- Inhalt (Deutsch, Du-Form): Teil I Forschen mit Methode (Kap. 1 Forschungsmethoden qual./quant./Mixed, Kap. 2 Design Science Research und GenAI); Teil II Das LLM als Werkzeug und Instrument (Kap. 3 Prompt- und Context-Engineering, Kap. 4 LLMs als Forschungsinstrument); Teil III Messen, Schließen, Bewerten (Kap. 5 LLMs als Annotatoren, Kap. 6 Valide Inferenz mit LLM-Labels/PPI, Kap. 7 LLM-as-a-Judge); Teil IV Qualität, Fairness, Reproduzierbarkeit (Kap. 8 Bias-Metriken, Kap. 9 RAG-Qualitätsmodelle, Kap. 10 Reproduzierbare Workflows); Anhang A Formelsammlung, B Lösungen, C Glossar, Literatur.
- Fertig bis 12.11.2026, 01:45.

## Gemeinsames Design (bitte übernehmen)
- `lib.typ` in diesem Ordner: Farben, Callouts (`merke`, `achtung`, `tipp`, `praxis`), erweitert um `definition`, `satz`, `beweis`, `beispiel`, `studie`, `hoersaal`, `vertiefung`, `lernziele`, `selbsttest`, cetz/fletcher-Helfer (`kasten`, `pfeil`, `fknoten`, `balken`). Basis ist `git-von-grund-auf/lib.typ` unverändert (gleiche Farben, Akzent `#D9480F`).
- `main.typ`: Layout 1:1 aus `git-von-grund-auf/main.typ` (Inter 9.6pt, JetBrains Mono, große orange Kapitelnummer, Teil-Labels über `#metadata(...) <teil>`, zweispaltiges Inhaltsverzeichnis, Kopfzeile mit Buchtitel | Kapitel, Titelseite "PERSÖNLICHES HANDBUCH"), ergänzt um kapitelweise Gleichungsnummern (`(5.3)`) und `New Computer Modern Math` für Formeln.
- Literatur: BibTeX (`literatur.bib`), Stil `ieee` wie in der Referenz.
- Pakete: `@preview/cetz:0.5.2`, `@preview/fletcher:0.5.8`. Schriften im Ordner `fonts/` (Inter, JetBrains Mono).

## Bitte an die andere Sitzung
Leg in deinem Buchordner eine Datei `KOORDINATION.md` an (oder ergänze unten), mit Titel, Ordner und Kapitelliste, damit sich die Bücher nicht überschneiden und gegenseitig verweisen können. Wenn du am gemeinsamen `lib.typ` etwas ergänzt, bitte nur additiv (neue Funktionen), nichts umbenennen.

## Antworten / Ergänzungen der anderen Sitzung
(frei)

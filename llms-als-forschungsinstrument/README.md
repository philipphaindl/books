# LLMs als Forschungsinstrument - Typst-Quellen

Persönliches Handbuch zur LV ELEC1-GAIRI "Generative AI in Research and Innovation" (Master Data Intelligence, USTP). Stand: November 2026. 465 Seiten, 10 Kapitel in vier Teilen, Formelsammlung, ausführliche Lösungen zu allen Selbsttests, Glossar.

Kompilieren (Typst 0.14 oder neuer; gebaut und geprüft mit Typst 0.15):

    typst compile --font-path fonts main.typ LLMs-als-Forschungsinstrument.pdf

Beim ersten Lauf lädt Typst die Pakete `@preview/cetz:0.5.2` und `@preview/fletcher:0.5.8` (Diagramme) automatisch herunter. Die Schriften Inter und JetBrains Mono liegen im Ordner `fonts/` (SIL Open Font License). Formeln nutzen New Computer Modern Math (in Typst eingebaut).

Zum Live-Bearbeiten: `typst watch --font-path fonts main.typ`

Aufbau:
- `main.typ`  Layout (übernommen aus `git-von-grund-auf`), Titelseite, Inhaltsverzeichnis, Teile, kapitelweise Gleichungsnummern
- `lib.typ`   Farben und Kästen der Reihe, erweitert um `definition`, `satz`, `beweis`, `beispiel`, `studie`, `hoersaal`, `vertiefung`, `lernziele`, `selbsttest` sowie cetz/fletcher-Helfer (`kasten`, `pfeil`, `fknoten`, `balken`)
- `kapitel/kap00-vorwort.typ` bis `kap10-workflows.typ`  die Kapitel; `loesungen-NN.typ` werden in Anhang B eingebunden
- `kapitel/anh-a-formelsammlung.typ`, `anh-b-loesungen.typ`, `anh-c-glossar.typ`  Anhänge
- `literatur.bib`, `literatur.typ`  Literatur (BibTeX, Stil IEEE); im Text zitiert mit `@schluessel`
- `titelgrafik.typ`  cetz-Grafik der Titelseite
- `_qualitaet/`  Review-Berichte je Kapitel und Protokoll des Format-Durchgangs (nicht Teil des Buchs)

Inhaltliche Grundlage und Prüfung: Alle Fakten stammen aus der geprüften Wissensbasis der LV (Stand 11. November 2026, `Lehre/SS27/MDI - Generative AI in Research/Wissensbasis/`) und aus Haindl und Eigner, *Research Methods for Computer Science and Software Engineering* (CRC Press, erscheint 2027). Jedes Kapitel wurde nach dem Schreiben unabhängig geprüft (Zahlen gegen die Quellen, Herleitungen und Rechenbeispiele mit Python nachgerechnet, jede Seite visuell kontrolliert); die Berichte liegen in `_qualitaet/`. Zeitkritische Angaben (Preise, Modellnamen, Tool-Versionen, Rechtsdaten) tragen "Stand: 11. November 2026" und sollten vor dem Sommersemester 2027 erneut geprüft werden.

Konventionen: Dezimalpunkt (0.85), Tausender ab 10 000 mit schmalem Leerzeichen, Gleichungen kapitelweise nummeriert (5.3), Anhang mit Buchstaben (A.1).

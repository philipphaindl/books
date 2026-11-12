# LLMs in der Forschung von Grund auf - Typst-Quellen

Einsteiger-Handbuch zur LV "Generative AI in Research and Innovation" (Master Data Intelligence, USTP, SS 2027). Deckt alle zehn Foliensätze ab, ohne Formeln: Alltagsvergleich, Begriff, Zahlenbeispiel, Umsetzung. Die formale Fassung mit Herleitungen steht im großen Handbuch `../llms-als-forschungsinstrument/` unter denselben Kapitelnummern.

Kompilieren (Typst 0.14 oder neuer):

    typst compile --font-path fonts main.typ LLMs-in-der-Forschung-von-Grund-auf.pdf

Zum Live-Bearbeiten: `typst watch --font-path fonts main.typ`

Aufbau:
- `main.typ`  Titelseite, Inhaltsverzeichnis, Reihenfolge der Kapitel
- `layout.typ`  Seitenlayout der Reihe (aus `git-von-grund-auf/main.typ`), als Funktion `layout`
- `lib.typ`  Farben und Kästen der Reihe, dazu `alltag`, `begriff`, `beispiel`, `rechnung`, `studie`, `hoersaal`, `lernziele`, `kurz`, `selbsttest` sowie cetz/fletcher-Helfer
- `kap00-vorwort.typ`, `kap00-grundbegriffe.typ`  Vorwort und "Das Nötigste vorab"
- `kap01` bis `kap10`  die Kapitel; Kapitel N gehört zu Foliensatz N
- `glossar-NN.typ`, `anh-a-glossar.typ`  Glossareinträge je Kapitel, im Anhang zusammengeführt und sortiert
- `literatur.bib`, `literatur.typ`  Literatur (BibTeX, Stil IEEE), identisch mit `bibliography.bib` der LV
- `_test-NN.typ`  kompiliert ein einzelnes Kapitel im Buchlayout

Zeitkritische Angaben (Preise, Modellnamen, Versionen, Rechtslage) haben den Stand 11. November 2026 und gehören vor dem Semester geprüft.

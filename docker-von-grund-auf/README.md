# Docker von Grund auf - Typst-Quellen

Kompilieren (Typst 0.14 oder neuer):

    typst compile --font-path fonts main.typ Docker-von-Grund-auf.pdf

Beim ersten Lauf lädt Typst das Paket `@preview/cetz:0.5.2` (Diagramme) automatisch herunter.
Die Schriften Inter und JetBrains Mono liegen im Ordner `fonts/` (beide unter SIL Open Font License).

Aufbau:
- `main.typ`  Layout, Titelseite, Inhaltsverzeichnis, Reihenfolge der Kapitel
- `lib.typ`   Farben, Commit-Graph-Funktion `gitgraph`, Docker-Diagrammhelfer `stapel` und `rahmen`, Hinweiskästen (`merke`, `achtung`, `tipp`, `mac`, `praxis`), `datei`, `kasten`, `pfeil`
- `kap00` bis `kap15`, `anh-a`, `anh-b`  die Kapitel

Zum Live-Bearbeiten: `typst watch --font-path fonts main.typ`

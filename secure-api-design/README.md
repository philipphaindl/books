# Secure API Design - Typst-Quellen

Kompilieren (Typst 0.14 oder neuer):

    typst compile --font-path fonts main.typ Secure-API-Design.pdf

Beim ersten Lauf lädt Typst das Paket `@preview/cetz:0.5.2` (Diagramme) automatisch herunter.
Die Schriften Inter und JetBrains Mono liegen im Ordner `fonts/` (beide unter SIL Open Font License).

Aufbau:
- `main.typ`  Layout, Titelseite, Inhaltsverzeichnis, Reihenfolge der Kapitel
- `lib.typ`   Farben, Diagrammhelfer, Hinweiskästen und Code-Dateirahmen
- `kap00` bis `kap11`, `anh-a`, `anh-b`  die Kapitel
- `AENDERUNGEN-2026-09.md`  fachliche Aktualisierungen und Prüfumfang

Zum Live-Bearbeiten: `typst watch --font-path fonts main.typ`

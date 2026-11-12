# Unabhängiges Kapitel-Review (Buch "LLMs als Forschungsinstrument")

Du hast das Kapitel nicht geschrieben. Lies BUCH_PLAN.md und lib.typ. Prüfe und korrigiere direkt im Kapitel und in der Lösungsdatei:

1. **Fachliche Richtigkeit:** jede Zahl, jede Studienangabe, jedes Zitat gegen das Wissensbasis-Dossier des Moduls (`/home/claude/gairi2027/source/knowledge-base/NN-*/dossier.md`, Caveats in `verification_report.md`) bzw. das Lehrbuch (`/home/claude/gairi2027/source/book/chN.tex`). Passt der Zitierschlüssel zur Aussage? Alles nicht Belegbare entfernen oder klar als Einschätzung kennzeichnen.
2. **Mathematik:** jede Formel, Herleitung und Beweisskizze Schritt für Schritt nachvollziehen; jedes Rechenbeispiel und jede Selbsttest-Lösung mit python3 nachrechnen. Fehler korrigieren.
3. **Darstellung:** eigene Testdatei `/home/claude/buch-llm/_review-NN.typ` (Kopf von `main.typ` bis vor die Titelseite, dann nur dieses Kapitel, `#anhang-modus.update(true)` nicht nötig, die Lösungsdatei und `literatur.typ`) kompilieren mit `/home/claude/bin/typstc --root . --font-path fonts _review-NN.typ /tmp/rNN.pdf`, alle Seiten als Kontaktabzüge ansehen (`pdftoppm -r 50`, `montage -tile 4x`), Problemseiten in höherer Auflösung. Behebe: Überläufe, überlappende Beschriftungen in Diagrammen, zu kleine/zu große Abbildungen, kaputte Formeln, leere Seiten, Kästen, die eine Seite sprengen.
4. **Sprache:** Deutsch mit Umlauten, Du-Form, keine "—"/"–"/"--", keine Füllphrasen, keine KI-typischen Floskeln.
5. Gleichungsverweise: `@kNN-eq-...` funktionieren jetzt auch aus dem Anhang korrekt (main.typ wurde angepasst) - als Text geschriebene Gleichungsnummern in der Lösungsdatei wieder durch echte Referenzen ersetzen, wo möglich.
Schreibe am Ende `kapitel/REVIEW-NN.md` (Befunde, Korrekturen, offene Punkte). Nur die Dateien des Kapitels ändern.

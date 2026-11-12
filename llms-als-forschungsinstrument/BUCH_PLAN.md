# Handbuch "LLMs als Forschungsinstrument" - verbindlicher Plan für Kapitel-Agenten

Buchordner: `/home/claude/buch-llm/` (wird später zu `Documents/Sources/books/llms-als-forschungsinstrument/` auf dem Mac des Autors). Stil der Buchreihe des Autors (Referenz: `/mnt/user-data/uploads/Documents/Sources/books/git-von-grund-auf/` - sieh dir `main.pdf`, `kap06-merge.typ`, `kap13-actions.typ` an, um Ton, Dichte und Diagrammeinsatz zu treffen). Dieses Buch soll **deutlich länger und tiefer** sein als die Referenz.

## Zweck und Leser
Persönliches Handbuch für Dr. Philipp Haindl (promoviert, IT-Security- und LLM-Forscher, lehrt Forschungsmethodik, Mitautor von *Research Methods for Computer Science and Software Engineering*). Er muss die Themen seiner neuen LV GAIRI selbst wirklich beherrschen: Intuition, Formalismus, Herleitungen, Rechnen, Forschungsstand mit konkreten Studien, Kontroversen, und souverän Fragen im Hörsaal beantworten. Lehrbuchniveau Master/PhD, absolut professionell.

## Sprache und Stil
- **Deutsch** (österreichisch-neutral), Du-Form wie in der Referenzreihe ("du"), Umlaute (ä, ö, ü, ß; nie ae/oe/ue). Englische Fachbegriffe beim ersten Auftreten kursiv in Klammern, danach der gebräuchliche Begriff.
- Striche nur "-" (nie "—"/"–"; in Typst-Quelltext auch kein "--"/"---"). Pfeile als "->" im Text.
- Ausformulierte, präzise Prosa mit gelegentlichen Listen; keine Bullet-Wüsten, keine Füllphrasen, kein Marketington.

## Quellen und Genauigkeit (nicht verhandelbar)
1. Inhalte nur aus: Wissensbasis-Dossier des Moduls (`/home/claude/gairi2027/source/knowledge-base/NN-*/dossier.md`) unter Beachtung von `verification_report.md`; dem Lehrbuch des Autors (`/home/claude/gairi2027/source/book/chN.tex`); den geprüften Folien (`/home/claude/gairi2027/NN <Name>/*.typ`, inkl. `REVIEW.md`); den Notebooks (`/home/claude/gairi2027/notebooks/NN_*.ipynb`).
2. Jede Faktenaussage, Zahl, Studie mit Zitat `@key` (nur Keys aus `/home/claude/buch-llm/literatur.bib`; das Lehrbuch ist `@haindl2027research`). Keine neuen Fakten aus dem Gedächtnis. Was als `[UNVERIFIED]` markiert ist, nicht als Fakt darstellen.
3. Mathematik: Herleitungen und Beweisskizzen sollen selbst ausgearbeitet werden, wo es Standardmathematik ist - korrekt, nachvollziehbar, jede Größe definiert. Jede Zahl in Rechenbeispielen mit python3 nachrechnen.
4. Zeitkritisches (Preise, Versionen, Rechtsdaten) mit "(Stand: 11. November 2026)".

## Design-Bausteine (aus `lib.typ`, nicht neu definieren)
`#lernziele[..][..]` (Kapitelbeginn), `#definition(titel: [..])[..]`, `#satz(titel: [..])[..]`, `#beweis[..]`, `#beispiel(titel: [..])[..]` (Rechenbeispiel), `#studie(titel: [Autor et al. Jahr])[Design, Daten, Befund, Grenzen]`, `#merke[..]`, `#fallstrick[..]`, `#praxis[..]`, `#tipp[..]`, `#hoersaal([Frage], [Antwort])` (mind. 5 pro Kapitel, auch kritische Fragen), `#vertiefung[..]` (kommentierte Lektüre), `#selbsttest([..], [..], ...)` (Kapitelende, 8-12 Fragen), `#datei("name.py")[```python ...```]`, `#figure(..., caption: [..])`.
Diagramme: **viele und gute** - mindestens 6 Abbildungen pro Kapitel: fletcher (`diagram`, `node`, `edge`, Helfer `fknoten(pos, [Text], col: c-blue, filled: true)`), cetz (`cetz.canvas`, Helfer `kasten`, `pfeil`, `balken`), cetz-Plots selbst gezeichnet (Achsen, Kurven, Punktwolken, Konfidenzintervalle, Verteilungen). Farben nur aus `lib.typ` (`c-blue`, `c-accent`, `c-teal`, `c-violet`, `c-yellow`, `c-green`, `c-red`, `c-grey`, `c-dark`). Schrift in Diagrammen: `text(font: "Inter", size: 7-8pt)`. Tabellen mit `#figure(table(...), caption: [..])` (Stil ist global gesetzt). Gleichungen: `$ ... $ <kNN-eq-name>`, nummeriert pro Kapitel automatisch.

## Kapitelaufbau (Datei `kapitel/kapNN-<name>.typ`)
```
#import "../lib.typ": *

= <Kapiteltitel> <kNN>
```
- Einstiegsprosa (worum es geht, warum es für LLM-gestützte Forschung zählt), dann `#lernziele[...]`.
- 6-10 Abschnitte (`==`), Unterabschnitte (`===`). Je Konzept: Intuition -> formale Definition -> Herleitung/Begründung -> Rechenbeispiel -> Grenzen und Fallstricke -> Bezug zur eigenen Forschung.
- Forschungsstand mit `#studie` (konkrete Zahlen + Quelle) und ein Abschnitt zu Debatten/offenen Fragen.
- Praxisbezug: Python-Ausschnitte, Verweis auf Notebook `notebooks/NN_*.ipynb` und Foliensatz NN der LV ("Foliensatz 05").
- Ein Abschnitt "Für die Lehre" am Ende: wie man das Thema unterrichtet, typische Missverständnisse der Studierenden, Zeitbedarf.
- Am Ende `#selbsttest(...)`. **Lösungen** in eigene Datei `kapitel/loesungen-NN.typ`: beginnt mit `#import "../lib.typ": *` und `== Kapitel NN: <Titel>` (Level 2), dann nummerierte ausführliche Lösungen. Diese Dateien werden in Anhang B eingebunden.
- Umfang: **mindestens 14.000 Wörter pro Kapitel** (ca. 40-60 Seiten in diesem Layout). Tiefe vor Breite, aber vollständig.
- Labels nur mit Kapitelpräfix (`<k05-...>`). Querverweise auf andere Kapitel als Text ("Kapitel 6").

## Werkzeuge
- Ganzes Buch kompilieren: `cd /home/claude/buch-llm && /home/claude/bin/typstc --root . --font-path fonts main.typ /tmp/<kürzel>.pdf`. Wenn ein fremdes Kapitel gerade einen Fehler wirft: eigene Testdatei `/home/claude/buch-llm/_test-NN.typ` anlegen, die den Kopf von `main.typ` (alles bis vor die Titelseite) plus nur dein Kapitel und deine Lösungen und `literatur.typ` einbindet.
- Seiten ansehen: `pdftoppm -r 60 -f A -l B -png /tmp/<x>.pdf /tmp/<x>` und PNGs lesen (Montage: `montage ... -tile 4x`). Prüfe jede Abbildung, Formel, Tabelle, Box: keine Überläufe, keine überlappenden Beschriftungen, lesbare Größen.
- Nur eigene Dateien schreiben: `kapitel/kapNN-*.typ`, `kapitel/loesungen-NN.typ`, `_test-NN.typ`, temporäre Dateien in `/tmp/<kürzel>*`. `literatur.bib`, `lib.typ`, `main.typ` NICHT ändern; fehlende Quellen in `kapitel/fehlende-quellen-NN.bib` sammeln und melden.

#import "lib.typ": *

= Der tägliche Arbeitsablauf

Dieses Kapitel deckt ab, was du jeden Tag brauchst: ein Repository anlegen oder klonen, Änderungen lesen, gezielt vormerken, sauber committen und die Historie durchsuchen.

== Repository anlegen oder klonen

Ein neues Projekt machst du mit `git init` zu einem Repository. Das legt nur den Ordner `.git` an, deine Dateien bleiben unberührt. Ein bestehendes Projekt vom Server holst du mit `git clone`:

```bash
# Neues Projekt
mkdir demo && cd demo
git init

# Bestehendes Projekt klonen (legt den Ordner demo an)
git clone gitea:team/demo.git
git clone gitea:team/demo.git anderer-ordnername
```

`git clone` erledigt vier Dinge auf einmal: Es legt das Verzeichnis und `.git` an, lädt alle Commits herunter, registriert die Quelle unter dem Namen `origin` und checkt den Standard-Branch des Servers (meist `main`) aus.

== Den Zustand lesen: `git status`

`git status` ist der Befehl, den du am häufigsten ausführen solltest, am besten vor und nach jedem anderen Befehl. Die Kurzform ist kompakter und für den Alltag meist besser:

```bash
git status -sb
```
```out
## main...origin/main [ahead 1]
M  src/login.py
 M README.md
MM src/app.py
A  src/token.py
?? notizen.txt
```

Die erste Zeile zeigt den Branch, seinen Upstream und ob du Commits voraus (_ahead_) oder hinterher (_behind_) bist. Darunter stehen zwei Statusspalten: *links der Index, rechts das Arbeitsverzeichnis.*

#table(columns: (auto, 1fr),
  [Code], [Bedeutung],
  [`M ` (links)], [Geändert und vorgemerkt: kommt so in den nächsten Commit.],
  [` M` (rechts)], [Geändert, aber noch nicht vorgemerkt.],
  [`MM`], [Vorgemerkt und danach erneut geändert. Im Index liegt die ältere Fassung!],
  [`A `], [Neue Datei, vorgemerkt.],
  [`D `, ` D`], [Gelöscht (vorgemerkt bzw. nur im Arbeitsverzeichnis).],
  [`R `], [Umbenannt (Git erkennt Umbenennungen über ähnlichen Inhalt).],
  [`??`], [Unbekannte Datei, die Git noch nie im Index hatte (_untracked_).],
  [`UU`], [Konflikt, beide Seiten haben die Datei geändert (Kapitel 6).],
)

== Änderungen vormerken

```bash
git add src/login.py        # eine Datei
git add src/                # alles in einem Ordner
git add .                   # alles im aktuellen Verzeichnis und darunter
git add -p                  # stückweise, interaktiv (sehr empfehlenswert)
git restore --staged datei  # Vormerkung zurücknehmen, Änderung bleibt erhalten
```

`git add -p` (_patch_) zeigt jede Änderung als einzelnen Abschnitt (_hunk_) und fragt, ob er in den Index soll. So baust du saubere Commits auch dann, wenn du in einer Datei mehrere unabhängige Dinge geändert hast:

#table(columns: (auto, 1fr, auto, 1fr),
  [Taste], [Wirkung], [Taste], [Wirkung],
  [#key[y]], [Abschnitt vormerken], [#key[n]], [Abschnitt überspringen],
  [#key[s]], [in kleinere Abschnitte teilen], [#key[e]], [Abschnitt im Editor zuschneiden],
  [#key[q]], [beenden], [#key[?]], [Hilfe zu allen Optionen],
)

#tipp[Eine gute Routine vor jedem Commit: `git add -p`, dann `git diff --staged` zur Kontrolle dessen, was wirklich committet wird, dann `git commit`. Das verhindert fast alle "Ups, das sollte nicht mit rein"-Momente.]

== Committen

```bash
git commit                  # öffnet den Editor für die Nachricht
git commit -m "Kurzer Titel"
git commit -am "Titel"      # add + commit für bereits bekannte Dateien (nicht für neue!)
```

=== Gute Commits

Ein guter Commit enthält *eine logische Änderung*: einen Bugfix, eine Funktion, eine Umbenennung. Er sollte für sich verständlich sein und das Projekt in einem funktionierenden Zustand hinterlassen. Das zahlt sich beim Review, bei `git revert` und bei `git bisect` aus. Faustregel: Wenn du im Titel "und" schreiben musst, sind es vermutlich zwei Commits.

Für die Nachricht hat sich eine feste Form durchgesetzt:

#datei("Commit-Nachricht")[
```text
Login-Sperre nach fünf Fehlversuchen einführen

Bisher konnten Passwörter beliebig oft probiert werden. Nach fünf
Fehlversuchen innerhalb von zehn Minuten wird das Konto jetzt für
15 Minuten gesperrt. Der Zähler liegt in Redis, damit die Sperre über
mehrere Instanzen hinweg gilt.

Refs: #42
```
]

- *Titelzeile:* höchstens etwa 50 Zeichen, ohne Punkt am Ende, im Imperativ ("einführen", nicht "eingeführt"; englisch "Add", nicht "Added"). Sie erscheint in `git log --oneline` und in Gitea-Listen.
- *Leerzeile*, dann der *Textkörper* mit Zeilen bis etwa 72 Zeichen. Er erklärt *warum* etwas geändert wurde. Das *Was* steht ohnehin im Diff.
- *Trailer* am Ende wie `Refs: #42` oder `Co-authored-by: Name <mail>` verknüpfen den Commit mit Issues oder Mitautoren.

Viele Teams nutzen zusätzlich _Conventional Commits_, bei denen der Titel mit einem Typ beginnt: `feat: Login-Sperre einführen`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`. Das erleichtert automatisch erzeugte Changelogs, ist aber Geschmackssache. Wichtiger als das Format ist, dass es im Projekt einheitlich ist.

== Diffs lesen

`git diff` vergleicht immer zwei Zustände. Welche, hängt von den Argumenten ab, und genau das verwirrt am Anfang:

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [*Arbeitsverzeichnis*], w: 3.2, h: 0.8, bg: rgb("#FDF1EC"), col: c-accent)
    kasten((5, 0), [*Index*], w: 3.2, h: 0.8, bg: rgb("#FFF8E6"), col: c-yellow)
    kasten((10, 0), [*HEAD* (letzter Commit)], w: 3.2, h: 0.8, bg: rgb("#EAF1FB"), col: c-blue)
    let arc(x1, x2, y, lab, col) = {
      line((x1, 0.42), (x1, y), (x2, y), (x2, 0.42), stroke: (paint: col, thickness: 0.9pt), mark: (start: "stealth", end: "stealth", fill: col, scale: 0.5))
      content(((x1 + x2) / 2, y + 0.22), text(font: "JetBrains Mono", size: 7pt, weight: "bold", fill: col, lab))
    }
    arc(0.4, 4.6, 0.95, "git diff", c-accent)
    arc(5.4, 9.6, 0.95, "git diff --staged", c-yellow.darken(10%))
    line((-0.4, -0.42), (-0.4, -1.0), (10.4, -1.0), (10.4, -0.42), stroke: (paint: c-blue, thickness: 0.9pt), mark: (start: "stealth", end: "stealth", fill: c-blue, scale: 0.5))
    content((5, -1.25), text(font: "JetBrains Mono", size: 7pt, weight: "bold", fill: c-blue, "git diff HEAD"))
  }),
  caption: [Was `git diff` vergleicht, abhängig von den Argumenten.],
)

```bash
git diff                    # noch nicht vorgemerkte Änderungen
git diff --staged           # was in den nächsten Commit geht
git diff HEAD               # alles seit dem letzten Commit
git diff main feature       # Unterschied zwischen zwei Branches
git diff --stat             # nur Übersicht: welche Dateien, wie viele Zeilen
git diff --word-diff        # wortweise statt zeilenweise (ideal für LaTeX, Typst, Markdown)
```

Ein Diff-Abschnitt beginnt mit einer Kopfzeile wie `@@ -12,7 +12,9 @@`: Im alten Stand ging es um 7 Zeilen ab Zeile 12, im neuen um 9 Zeilen ab Zeile 12. Zeilen mit `-` wurden entfernt, mit `+` hinzugefügt, ohne Präfix sind sie unveränderter Kontext.

#tipp[Für Texte (Paper, Skripte, Folien in LaTeX oder Typst) ist `git diff --word-diff` Gold wert, denn ein einziges geändertes Wort markiert sonst den ganzen Absatz. Noch besser funktioniert das, wenn im Quelltext jeder Satz in einer eigenen Zeile steht.]

== Die Historie ansehen

#table(columns: (auto, 1fr),
  [Befehl], [Zeigt],
  [`git log`], [alle Commits des aktuellen Branches, neueste zuerst],
  [`git log --oneline --graph --all`], [kompakter Graph aller Branches (als Alias `git lga`)],
  [`git log -p`], [jeden Commit mit vollständigem Diff],
  [`git log --stat`], [jeden Commit mit Liste der geänderten Dateien],
  [`git log -n 5`], [nur die letzten fünf Commits],
  [`git log --since="2 weeks ago"`], [Commits der letzten zwei Wochen],
  [`git log --author="Haindl"`], [nur Commits eines Autors],
  [`git log -- src/login.py`], [nur Commits, die diese Datei betreffen],
  [`git log --follow -- datei`], [Datei-Historie auch über Umbenennungen hinweg],
  [`git show a1b2c3d`], [einen einzelnen Commit mit Nachricht und Diff],
  [`git show HEAD:src/app.py`], [eine Datei so, wie sie im letzten Commit aussah],
)

Das doppelte `--` trennt Optionen von Dateipfaden. Es ist nur nötig, wenn ein Pfad mit einem Branch-Namen verwechselt werden könnte, schadet aber nie.

== Dateien löschen, verschieben, ignorieren

```bash
git rm datei.txt            # löschen und Löschung vormerken
git rm --cached .env        # nicht mehr versionieren, Datei aber behalten
git mv alt.py neu.py        # umbenennen und vormerken
```

Welche Dateien Git gar nicht erst beachten soll, steht in der Datei `.gitignore` im Projekt. Sie wird selbst committet, damit sie für alle gilt:

#table(columns: (auto, 1fr),
  [Muster], [Bedeutung],
  [`*.log`], [alle Dateien mit Endung `.log`, in jedem Ordner],
  [`/build`], [nur `build` im Wurzelverzeichnis des Projekts],
  [`build/`], [jeder Ordner namens `build`, egal wo],
  [`**/tmp`], [`tmp` in beliebiger Tiefe],
  [`!wichtig.log`], [Ausnahme: diese Datei doch versionieren],
  [`.env`], [lokale Umgebungsvariablen und Geheimnisse],
)

Wenn eine Datei trotz Eintrag nicht ignoriert wird, ist sie meistens schon versioniert: `.gitignore` wirkt nur auf Dateien, die Git noch nicht kennt. Dann hilft `git rm --cached datei`. Warum eine Datei ignoriert wird, verrät `git check-ignore -v datei`.

#achtung[Wurde eine Datei mit Passwörtern oder Tokens (etwa `.env`) jemals committet und gepusht, steht sie in der Historie, auch wenn du sie danach löschst. Das Geheimnis gilt als kompromittiert und muss *sofort ausgetauscht* werden. Das Umschreiben der Historie (Kapitel 8) ist erst der zweite Schritt.]

=== Zeilenenden und Binärdateien mit `.gitattributes`

`.gitignore` entscheidet, *was* Git verfolgt; `.gitattributes` legt fest, *wie* Git bestimmte Dateien behandelt. Das ist besonders wichtig, wenn macOS-, Linux- und Windows-Rechner zusammenarbeiten:

#datei(".gitattributes")[
```text
*       text=auto
*.sh    text eol=lf
*.png   binary
*.pdf   binary
```
]

`text=auto` normalisiert erkannte Textdateien im Repository auf LF. Für Shell-Skripte erzwingt `eol=lf` zusätzlich LF im Arbeitsverzeichnis, damit sie in Linux-Containern nicht an unsichtbaren CRLF-Zeichen scheitern. `binary` verhindert sinnlose Text-Diffs. Nach dem erstmaligen Einführen prüfst du die einmalige Normalisierung mit `git add --renormalize .` und `git diff --staged`, bevor du sie committest.

=== Große Binärdateien mit Git LFS

Git speichert jede Version einer Datei in der Historie. Große, häufig geänderte Binärdateien wie Videos, Datensätze oder Photoshop-Dateien blähen deshalb jeden Klon dauerhaft auf. Git LFS speichert im Repository nur kleine Zeiger und die eigentlichen Dateien in einem getrennten LFS-Speicher:

```bash
brew install git-lfs
git lfs install
git lfs track "*.psd"
git add .gitattributes
```

Vorher prüfen, ob der Git-Server LFS unterstützt und genügend Speicher hat. `git lfs track` wirkt nur auf künftige Commits. Bereits vorhandene große Dateien migriert `git lfs migrate import` nur durch Umschreiben der Historie; das ist eine Team-Entscheidung und verlangt anschließend koordinierte neue Klone oder Force-Pushes.

== Der Kreislauf im Überblick

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let pts = ((0, 0), (3.3, 0), (6.6, 0), (9.9, 0), (13.2, 0))
    let labs = ([`git pull`\ #text(size: 6.5pt)[aktuellen Stand holen]], [Dateien \ bearbeiten], [`git status` \ `git diff`], [`git add -p` \ `git commit`], [`git push`\ #text(size: 6.5pt)[teilen]])
    for (k, p) in pts.enumerate() {
      kasten(p, labs.at(k), w: 2.6, h: 1.1, bg: if k == 0 or k == 4 { rgb("#EAF1FB") } else { white }, col: if k == 0 or k == 4 { c-blue } else { c-dark }, size: 7.5pt)
      if k < 4 { pfeil((p.at(0) + 1.3, 0), (p.at(0) + 2.0, 0)) }
    }
    line((9.9, -0.55), (9.9, -1.2), (3.3, -1.2), (3.3, -0.58), stroke: (paint: c-grey, thickness: 0.8pt, dash: "dashed"), mark: (end: "stealth", fill: c-grey, scale: 0.5))
    content((6.6, -1.45), text(size: 7pt, fill: c-grey.darken(20%), style: "italic")[mehrere kleine Commits pro Arbeitssitzung])
  }),
  caption: [Der tägliche Ablauf. Pushen muss man nicht nach jedem Commit, aber mindestens am Ende des Tages.],
)

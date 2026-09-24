#import "lib.typ": *

= Das mentale Modell

Git wirkt kompliziert, weil es über 150 Befehle mit unzähligen Optionen hat. Der Kern ist aber erstaunlich klein: eine Datenbank aus unveränderlichen Schnappschüssen, die zu einem Graphen verkettet sind, plus ein paar verschiebbare Namensschilder, die auf Punkte in diesem Graphen zeigen. Wer diese drei Dinge verstanden hat (Schnappschüsse, Graph, Namensschilder), kann fast jeden Befehl selbst herleiten.

== Schnappschüsse statt Änderungen

Viele ältere Versionsverwaltungen speichern pro Version die Änderungen gegenüber der Vorversion. Git speichert dagegen bei jedem Commit *den vollständigen Zustand aller Dateien* des Projekts. Das klingt verschwenderisch, ist es aber nicht: Unveränderte Dateien werden nicht neu abgelegt, sondern der neue Schnappschuss verweist auf die bereits vorhandene Version. Eine Änderungsansicht (ein _Diff_) berechnet Git erst dann, wenn du sie anforderst, indem es zwei Schnappschüsse vergleicht.

Daraus folgen zwei Eigenschaften, die später immer wieder wichtig werden:

+ *Commits sind unveränderlich.* Ein Commit wird über eine Prüfsumme seines Inhalts identifiziert. Ändert man auch nur ein Zeichen der Nachricht, entsteht ein neuer Commit mit neuer Prüfsumme. "Einen Commit ändern" heißt in Git immer: einen neuen, korrigierten Commit erzeugen und den alten links liegen lassen.
+ *Nichts geht leicht verloren.* Was einmal committet wurde, bleibt in der Objektdatenbank, auch wenn kein Branch mehr darauf zeigt. Erst nach Wochen räumt Git solche verwaisten Objekte automatisch weg. Das ist die Grundlage aller Rettungsaktionen in Kapitel 9.

== Die drei Bereiche

Wenn du an einem Git-Projekt arbeitest, gibt es drei Orte, an denen eine Datei in unterschiedlichen Versionen existieren kann. Diese Unterscheidung ist der wichtigste einzelne Schlüssel zum Verständnis von Befehlen wie `add`, `restore` oder `reset`.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [*Arbeitsverzeichnis* \ #text(size: 7pt, fill: c-grey.darken(20%))[Dateien auf der Platte, \ die du bearbeitest]], w: 3.4, h: 1.5, bg: rgb("#FDF1EC"), col: c-accent)
    kasten((6, 0), [*Index* (Staging Area) \ #text(size: 7pt, fill: c-grey.darken(20%))[Entwurf des nächsten \ Commits, `.git/index`]], w: 3.4, h: 1.5, bg: rgb("#FFF8E6"), col: c-yellow)
    kasten((12, 0), [*Repository* \ #text(size: 7pt, fill: c-grey.darken(20%))[alle Commits, \ `.git/objects`]], w: 3.4, h: 1.5, bg: rgb("#EAF1FB"), col: c-blue)
    pfeil((1.8, 0.4), (4.2, 0.4), label: "git add", loff: (0, 0.24))
    pfeil((7.8, 0.4), (10.2, 0.4), label: "git commit", loff: (0, 0.24))
    pfeil((10.2, -0.4), (7.8, -0.4), label: "restore --staged", loff: (0, -0.24), color: c-grey.darken(20%))
    pfeil((4.2, -0.4), (1.8, -0.4), label: "git restore", loff: (0, -0.24), color: c-grey.darken(20%))
    line((12, -0.78), (12, -1.55), (0, -1.55), stroke: (paint: c-blue, thickness: 0.9pt))
    line((0, -1.55), (0, -0.8), stroke: (paint: c-blue, thickness: 0.9pt), mark: (end: "stealth", fill: c-blue, scale: 0.6))
    line((6, -1.55), (6, -0.8), stroke: (paint: c-blue, thickness: 0.9pt), mark: (end: "stealth", fill: c-blue, scale: 0.6))
    content((9, -1.8), text(font: "JetBrains Mono", size: 6.8pt, weight: "bold", fill: c-blue)[git switch / git checkout])
  }),
  caption: [Die drei Bereiche und die Befehle, die Inhalte zwischen ihnen bewegen.],
)

- Das *Arbeitsverzeichnis* (_working tree_) ist der normale Projektordner mit den Dateien, die du im Editor öffnest.
- Der *Index* (_staging area_) ist ein Zwischenbereich. Er enthält den Stand, der beim nächsten `git commit` festgeschrieben wird. Mit `git add` kopierst du den aktuellen Inhalt einer Datei in den Index. Änderst du die Datei danach noch einmal, liegt im Index weiterhin die ältere Fassung, bis du erneut `git add` ausführst.
- Das *Repository* ist der versteckte Ordner `.git` im Projektverzeichnis. Dort liegen alle Commits, Branches und Einstellungen. Löschst du `.git`, ist das Projekt kein Git-Projekt mehr, die Dateien im Arbeitsverzeichnis bleiben aber erhalten.

Der Index erscheint anfangs überflüssig, ist aber eines der nützlichsten Werkzeuge: Er erlaubt, aus einem Durcheinander von Änderungen gezielt nur einen Teil zu committen, etwa den Bugfix, aber nicht die Debug-Ausgaben daneben (siehe `git add -p` in Kapitel 3).

#merke[`git status` zeigt dir jederzeit die Unterschiede zwischen diesen drei Bereichen: _Changes to be committed_ sind Unterschiede zwischen Index und letztem Commit, _Changes not staged for commit_ sind Unterschiede zwischen Arbeitsverzeichnis und Index, _Untracked files_ sind Dateien, die Git noch nie im Index hatte.]

== Das Objektmodell

Im Ordner `.git/objects` speichert Git vier Arten von Objekten. Jedes wird über den SHA-1-Hash seines Inhalts adressiert, eine 40-stellige Hexadezimalzahl wie `3f2a9c1e...`. Meist reichen die ersten sieben Zeichen, um ein Objekt eindeutig anzusprechen.

#table(columns: (auto, 1fr),
  [Objekt], [Inhalt],
  [*blob*], [Der Inhalt einer Datei, ohne Namen und ohne Rechte. Zwei Dateien mit identischem Inhalt teilen sich einen Blob.],
  [*tree*], [Ein Verzeichnis: eine Liste von Namen, Dateirechten und Verweisen auf Blobs (Dateien) oder weitere Trees (Unterordner).],
  [*commit*], [Ein Verweis auf den Wurzel-Tree des Projekts, dazu die Elterncommits, Autor, Committer, Zeitstempel und die Nachricht.],
  [*tag*], [Ein annotierter Tag: Verweis auf einen Commit plus Name, Autor, Datum und Nachricht (siehe Kapitel 11).],
)

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let obj(pos, head, body, col) = {
      let (x, y) = pos
      rect((x - 1.55, y - 0.75), (x + 1.55, y + 0.75), radius: 0.1, fill: col.lighten(90%), stroke: (paint: col, thickness: 0.9pt))
      content((x, y + 0.45), text(font: "Inter", size: 7.5pt, weight: "bold", fill: col.darken(20%), head))
      content((x, y - 0.12), text(font: "JetBrains Mono", size: 6.3pt, body))
    }
    obj((0, 0), [commit 3f2a9c1], [tree 8e41d07 \ parent 91b0c4e \ "Login-Formular"], c-blue)
    obj((-4.2, 0), [commit 91b0c4e], [tree 5d02aa3 \ parent 1c7f3b2 \ "README ergänzt"], c-blue)
    obj((4.2, 0), [tree 8e41d07], [README.md -> a93f \ src/ -> 77c2], c-teal)
    obj((2.2, -2.3), [blob a93f10c], [\# Demo \ Ein Beispiel...], c-grey)
    obj((6.2, -2.3), [tree 77c2e05], [login.py -> 4d1e \ app.py -> b82a], c-teal)
    pfeil((-1.55, 0), (-2.65, 0), label: "parent", loff: (0, 0.2))
    pfeil((1.55, 0), (2.65, 0), label: "tree", loff: (0, 0.2))
    pfeil((3.6, -0.75), (2.7, -1.55))
    pfeil((4.8, -0.75), (5.7, -1.55))
    content((-4.2, -1.2), text(size: 7pt, fill: c-grey.darken(20%), style: "italic")[zeigt seinerseits auf seinen Tree \ und seinen eigenen Vorgänger])
  }),
  caption: [Ein Commit zeigt auf einen Tree (den Schnappschuss) und auf seinen Elterncommit.],
)

Du kannst dir jedes Objekt ansehen. Das ist nie nötig für die tägliche Arbeit, aber ein guter Weg, das Modell einmal selbst zu sehen:

```bash
git cat-file -p HEAD          # den aktuellen Commit anzeigen
git cat-file -p HEAD^{tree}   # den zugehörigen Tree anzeigen
```
```out
tree 8e41d07b2c...
parent 91b0c4e5a1...
author Philipp Haindl <philipp@example.com> 1790251200 +0200
committer Philipp Haindl <philipp@example.com> 1790251200 +0200

Login-Formular
```

Weil der Hash eines Commits über Tree, Eltern, Autor, Zeit und Nachricht berechnet wird, hängt er indirekt von der gesamten Vorgeschichte ab. Ändert sich ein früherer Commit, ändern sich zwangsläufig die Hashes aller späteren. Genau deshalb bekommen beim Rebase oder beim Ändern einer alten Commit-Nachricht alle nachfolgenden Commits neue Hashes.

#tipp[Git 3.0, das für Ende 2026 erwartet wird, stellt neue Repositories standardmäßig auf SHA-256 um (64 statt 40 Hex-Zeichen) und nennt den Standard-Branch `main` statt `master`. Bestehende Repositories funktionieren unverändert weiter. Für das Verständnis ändert sich nichts.]

== Der Commit-Graph

Jeder Commit (außer dem allerersten) verweist auf mindestens einen Elterncommit. Ein gewöhnlicher Commit hat genau ein Elternteil, ein Merge-Commit hat zwei (selten mehr). So entsteht ein gerichteter, azyklischer Graph (_DAG_): Man kann immer nur rückwärts in die Vergangenheit laufen, nie im Kreis.

#figure(
  gitgraph(
    chain(("a","b","c"), ("A","B","C")) + chain(("d","e"), ("D","E"), y: -1, x0: 2.6, color: c-accent, first-parent: "b")
    + ((id: "m", x: 5.2, y: 0, label: "M", parents: ("c", "e"), color: c-blue),),
    notes: ((pos: (5.2, 0.62), body: [zwei Eltern]), (pos: (0, 0.62), body: [keine Eltern])),
  ),
  caption: [Ein Graph mit Verzweigung. `M` ist ein Merge-Commit mit den Eltern `C` und `E`.],
)

Ein wichtiger Begriff ist die *Erreichbarkeit*: Ein Commit gehört "zu einem Branch", wenn man ihn vom Branch-Ende aus entlang der Pfeile erreichen kann. In der Abbildung sind von `M` aus alle Commits erreichbar. Diese Idee steckt hinter Fragen wie "Ist mein Feature schon in `main`?" (`git branch --merged`) oder "Welche Commits hat `feature`, die `main` noch nicht hat?" (`git log main..feature`, Kapitel 11).

== Branches sind nur Zeiger

Ein Branch ist in Git kein Ordner und keine Kopie, sondern *eine Datei, die einen einzigen Commit-Hash enthält*. Der Branch `main` ist die Datei `.git/refs/heads/main` mit 41 Bytes Inhalt. Einen Branch anzulegen kostet deshalb praktisch nichts, und es ist völlig normal, Dutzende davon zu haben.

Woher weiß Git, auf welchem Branch du gerade arbeitest? Dafür gibt es `HEAD`, eine weitere kleine Datei (`.git/HEAD`), die normalerweise nicht auf einen Commit, sondern auf einen Branch verweist:

```bash
cat .git/HEAD
cat .git/refs/heads/main
```
```out
ref: refs/heads/main
3f2a9c1e0b8d4f6a7c2e9b1d0a5f8e3c7b6d4a21
```

Beim Committen passiert Folgendes: Git erzeugt aus dem Index einen neuen Commit, dessen Elternteil der bisherige Commit von `HEAD` ist, und schiebt dann den Branch, auf den `HEAD` zeigt, auf den neuen Commit weiter. `HEAD` selbst bewegt sich dabei nicht, denn er zeigt ja auf den Branch, und der Branch wandert mit.

#figure(
  vorher-nachher(
    gitgraph(chain(("a","b"), ("A","B")) , refs: ((name: "main", to: "b"), (name: "HEAD", to: "main", kind: "head", dist: 0.75), (name: "feature", to: "b", dir: "down", color: c-accent))),
    gitgraph(chain(("a","b","c"), ("A","B","C")) , refs: ((name: "main", to: "c"), (name: "HEAD", to: "main", kind: "head", dist: 0.75), (name: "feature", to: "b", dir: "down", color: c-accent))),
    lb: [Nach `git commit`],
  ),
  caption: [Ein Commit schiebt nur den aktuellen Branch weiter. `feature` bleibt stehen.],
)

#merke[Das komplette Modell in fünf Sätzen: *(1)* Ein Commit ist ein unveränderlicher Schnappschuss mit Verweis auf seine Eltern. *(2)* Commits bilden einen Graphen, in dem Pfeile in die Vergangenheit zeigen. *(3)* Ein Branch ist ein verschiebbarer Zeiger auf einen Commit. *(4)* `HEAD` zeigt auf den aktuellen Branch. *(5)* Zwischen deinen Dateien und dem Repository liegt der Index als Entwurf des nächsten Commits.]

#import "lib.typ": *

= Branches

Branches sind in Git billig und schnell, deshalb solltest du sie großzügig einsetzen: für jede Funktion, jeden Bugfix, jedes Experiment. `main` bleibt dadurch jederzeit in einem funktionierenden Zustand, und angefangene Arbeit stört niemanden.

== Anlegen und wechseln

```bash
git branch feature/login        # Branch anlegen (am aktuellen Commit), nicht wechseln
git switch feature/login        # zum Branch wechseln
git switch -c feature/login     # anlegen und wechseln in einem Schritt
git switch -c fix/typo a1b2c3d  # Branch an einem bestimmten Commit anlegen
git switch -                    # zurück zum vorherigen Branch
```

Früher erledigte `git checkout` all das und noch viel mehr (auch das Zurücksetzen von Dateien). Seit Git 2.23 gibt es die klareren Befehle `git switch` für Branches und `git restore` für Dateien. `git checkout -b name` funktioniert weiterhin und taucht in vielen Anleitungen auf, meint aber dasselbe wie `git switch -c name`.

#figure(
  grid(columns: (1fr, 1fr, 1fr), column-gutter: 6pt,
    align(center)[#text(size: 7.5pt, weight: "bold", fill: c-grey.darken(20%))[1. `git branch feature`] \
      #gitgraph(chain(("a","b","c"), ("A","B","C"), dx: 1.1), refs: ((name: "main", to: "c"), (name: "HEAD", to: "main", kind: "head", dist: 0.72), (name: "feature", to: "c", dir: "down", color: c-accent)), unit: 0.95cm)],
    align(center)[#text(size: 7.5pt, weight: "bold", fill: c-grey.darken(20%))[2. `git switch feature`] \
      #gitgraph(chain(("a","b","c"), ("A","B","C"), dx: 1.1), refs: ((name: "main", to: "c"), (name: "feature", to: "c", dir: "down", color: c-accent), (name: "HEAD", to: "feature", kind: "head", dir: "down", dist: 0.72)), unit: 0.95cm)],
    align(center)[#text(size: 7.5pt, weight: "bold", fill: c-grey.darken(20%))[3. `git commit`] \
      #gitgraph(chain(("a","b","c"), ("A","B","C"), dx: 1.1) + ((id: "d", x: 3.3, y: -0.9, label: "D", parents: ("c",), color: c-accent),), refs: ((name: "main", to: "c"), (name: "feature", to: "d", dir: "right", dist: 1.2, color: c-accent), (name: "HEAD", to: "feature", kind: "head", dir: "down", dist: 0.6)), unit: 0.95cm)],
  ),
  caption: [Ein Branch entsteht als zweiter Zeiger auf denselben Commit. Erst beim nächsten Commit laufen die Zeiger auseinander.],
)

Beim Wechseln passt Git das Arbeitsverzeichnis an den Schnappschuss des Ziel-Branches an: Dateien werden geändert, hinzugefügt oder entfernt. Bei großen Unterschieden kann das einen Moment dauern, es passiert aber lokal ohne Netzwerk.

== Branches verwalten

#table(columns: (auto, 1fr),
  [Befehl], [Wirkung],
  [`git branch`], [lokale Branches auflisten, der aktuelle ist mit `*` markiert],
  [`git branch -vv`], [zusätzlich letzter Commit, Upstream und ahead/behind],
  [`git branch -a`], [auch Remote-Tracking-Branches (`origin/...`) anzeigen],
  [`git branch --merged`], [Branches, deren Commits vollständig im aktuellen Branch enthalten sind],
  [`git branch --no-merged`], [Branches mit noch nicht integrierten Commits],
  [`git branch -d feature`], [löschen, aber nur wenn gemergt (sicher)],
  [`git branch -D feature`], [löschen erzwingen, auch mit ungemergten Commits],
  [`git branch -m alt neu`], [umbenennen (`-m neu` allein benennt den aktuellen Branch um)],
)

Beim Löschen eines Branches wird nur der Zeiger entfernt, die Commits bleiben in der Datenbank und sind über das Reflog noch Wochen lang auffindbar (Kapitel 9). `-D` ist also weniger gefährlich, als es klingt, sollte aber trotzdem nur mit Absicht verwendet werden.

#tipp[Nach einem gemergten Pull Request räumst du lokal so auf: `git switch main`, `git pull`, `git branch -d feature/login`. Weigert sich Git mit "not fully merged", obwohl der PR gemergt ist, wurde vermutlich per Squash oder Rebase gemergt: Die Commits in `main` sind dann neue Kopien, nicht deine ursprünglichen Commits. Hier ist `-D` korrekt.]

== Wechseln mit ungesicherten Änderungen

Hast du Dateien geändert und willst den Branch wechseln, gibt es zwei Fälle. Betreffen deine Änderungen Dateien, die sich zwischen den Branches nicht unterscheiden, nimmt Git sie einfach mit. Das ist praktisch, wenn du merkst, dass du auf dem falschen Branch angefangen hast: `git switch -c richtiger-branch` nimmt alle Änderungen mit in den neuen Branch.

Würden deine Änderungen dagegen überschrieben, verweigert Git den Wechsel:

```out
error: Your local changes to the following files would be overwritten by checkout:
        src/app.py
Please commit your changes or stash them before you switch branches.
```

Dann hast du drei Möglichkeiten: die Arbeit als Zwischenstand committen (und später aufräumen, Kapitel 8), sie mit `git stash` beiseitelegen (Kapitel 9) oder den anderen Branch in einem zweiten Arbeitsverzeichnis öffnen, ohne den aktuellen zu verlassen (Worktrees, Kapitel 10).

== Detached HEAD

Normalerweise zeigt `HEAD` auf einen Branch. Wechselst du direkt zu einem Commit oder Tag, zeigt `HEAD` dagegen unmittelbar auf einen Commit. Git warnt dann mit _You are in 'detached HEAD' state_.

```bash
git switch --detach v1.0     # alten Stand ansehen
```

#figure(
  gitgraph(chain(("a","b","c","d"), ("A","B","C","D")) + ((id: "x", x: 2.6, y: -1, label: "X", parents: ("c",), color: c-grey),),
    refs: ((name: "main", to: "d"), (name: "v1.0", to: "b", kind: "tag"), (name: "HEAD", to: "x", kind: "head", dir: "right", dist: 1.1)),
    notes: ((pos: (4.5, -1.55), body: [Commit ohne Branch: nach dem Wegwechseln \ nur noch über das Reflog auffindbar]),)),
  caption: [Detached HEAD: Ein neuer Commit `X` hängt an keinem Branch.],
)

Zum Ansehen, Testen oder Bauen eines alten Standes ist das völlig in Ordnung. Problematisch wird es nur, wenn du dort committest und dann wegwechselst: Dann zeigt nichts mehr auf die neuen Commits. Die Lösung ist einfach, solange du noch dort stehst:

```bash
git switch -c rettung        # macht aus dem losen Stand einen richtigen Branch
```

== Namenskonventionen

Branch-Namen dürfen Schrägstriche enthalten, was sich für Gruppierungen anbietet: `feature/login`, `fix/csv-import`, `hotfix/2.3.1`, `docs/api`. Bewährt haben sich Kleinbuchstaben, Bindestriche statt Leerzeichen und, wo vorhanden, die Issue-Nummer: `feature/42-login-sperre`. Gitea und die Tab-Vervollständigung sortieren und gruppieren dann sinnvoll.

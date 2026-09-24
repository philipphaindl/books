#import "lib.typ": *

= Korrekt mergen

Mergen heißt, die Arbeit von zwei Branches zusammenzuführen. Git kennt dafür mehrere Wege, die im Ergebnis denselben Dateistand erzeugen, aber eine unterschiedlich aussehende Historie hinterlassen. Welcher Weg "korrekt" ist, hängt davon ab, was die Historie später erzählen soll. Dieses Kapitel erklärt die Varianten, zeigt, wie Gitea sie beim Pull Request anbietet, und behandelt ausführlich Konflikte.

Alle Beispiele gehen davon aus, dass du einen Branch `feature` in `main` integrieren willst. Gemergt wird immer *in den aktuellen Branch hinein*:

```bash
git switch main
git pull                 # main auf den neuesten Stand bringen
git merge feature        # feature in main integrieren
```

== Die Merge-Basis

Für jeden Merge sucht Git zuerst den jüngsten gemeinsamen Vorfahren der beiden Branches, die *Merge-Basis*. Sie ist der Punkt, an dem die Wege auseinandergegangen sind, und entscheidet, welche Änderungen von welcher Seite stammen.

```bash
git merge-base main feature    # zeigt den Hash der Merge-Basis
```

== Fast-Forward

Hat `main` seit dem Abzweigen von `feature` keine neuen Commits bekommen, ist die Merge-Basis identisch mit dem Ende von `main`. Dann gibt es nichts zusammenzuführen: Git schiebt den Zeiger `main` einfach nach vorne. Das heißt _Fast-Forward_, es entsteht kein neuer Commit.

#figure(
  vorher-nachher(
    gitgraph(chain(("a","b"), ("A","B")) + chain(("c","d"), ("C","D"), x0: 2.6, color: c-accent, first-parent: "b"),
      refs: ((name: "main", to: "b"), (name: "feature", to: "d", color: c-accent)), unit: 1cm),
    gitgraph(chain(("a","b"), ("A","B")) + chain(("c","d"), ("C","D"), x0: 2.6, color: c-accent, first-parent: "b"),
      refs: ((name: "main", to: "d", dir: "down"), (name: "feature", to: "d", color: c-accent)), unit: 1cm),
    lb: [Nach `git merge feature`],
  ),
  caption: [Fast-Forward: `main` wird nur weitergeschoben.],
)

== Der echte Merge (Drei-Wege-Merge)

Hat `main` inzwischen eigene Commits, sind die Branches auseinandergelaufen. Git vergleicht dann drei Stände: die Merge-Basis, das Ende von `main` (_ours_) und das Ende von `feature` (_theirs_). Änderungen, die nur auf einer Seite passiert sind, werden übernommen. Haben beide Seiten dieselbe Stelle unterschiedlich geändert, entsteht ein Konflikt. Das Ergebnis wird als *Merge-Commit* mit zwei Eltern festgehalten.

#figure(
  vorher-nachher(
    gitgraph(chain(("a","b","e"), ("A","B","E")) + chain(("c","d"), ("C","D"), y: -1, x0: 2.6, color: c-accent, first-parent: "b"),
      refs: ((name: "main", to: "e"), (name: "feature", to: "d", dir: "down", color: c-accent)), notes: ((pos: (1.3, 0.65), body: [Basis]),), unit: 1cm),
    gitgraph(chain(("a","b","e"), ("A","B","E")) + chain(("c","d"), ("C","D"), y: -1, x0: 2.6, color: c-accent, first-parent: "b")
      + ((id: "m", x: 5.2, y: 0, label: "M", parents: ("e", "d"), color: c-blue),),
      refs: ((name: "main", to: "m"), (name: "feature", to: "d", dir: "down", color: c-accent)), unit: 1cm),
    lb: [Nach `git merge feature`],
  ),
  caption: [Drei-Wege-Merge: Der Merge-Commit `M` hat die Eltern `E` (erstes Elternteil) und `D` (zweites).],
) <fig-dreiwege>

Das *erste Elternteil* eines Merge-Commits ist immer der Branch, in dem du standest (hier `main`). Das ist später nützlich: `git log --first-parent main` zeigt nur die Hauptlinie, also pro gemergtem Feature einen Eintrag.

=== Merge-Commit erzwingen: `--no-ff`

Auch wenn ein Fast-Forward möglich wäre, kannst du einen Merge-Commit erzwingen. Der Vorteil: Die Commits des Features bleiben in der Historie als zusammengehörige Gruppe erkennbar, und das ganze Feature lässt sich mit einem einzigen `git revert -m 1` zurücknehmen.

```bash
git merge --no-ff feature     # immer einen Merge-Commit erzeugen
git merge --ff-only feature   # nur Fast-Forward, sonst abbrechen
```

== Die Strategien im Vergleich

In der Praxis wählst du zwischen vier Formen, die Gitea auch als Schaltflächen beim Mergen eines Pull Requests anbietet (Kapitel 12). Ausgangslage ist jeweils die linke Seite von @fig-dreiwege.

#figure(
  grid(columns: (1fr, 1fr), row-gutter: 12pt, column-gutter: 10pt,
    align(center)[#text(size: 7.5pt, weight: "bold")[① Merge-Commit] #h(4pt) #text(size: 7pt, fill: c-grey.darken(10%))[`merge --no-ff`] \
      #gitgraph(chain(("a","b","e"), ("A","B","E")) + chain(("c","d"), ("C","D"), y: -0.9, x0: 2.3, dx: 1.15, color: c-accent, first-parent: "b") + ((id: "m", x: 4.6, y: 0, label: "M", parents: ("e","d"), color: c-blue),), refs: ((name: "main", to: "m", dir: "right", dist: 1.05),), unit: 0.9cm)],
    align(center)[#text(size: 7.5pt, weight: "bold")[② Squash] #h(4pt) #text(size: 7pt, fill: c-grey.darken(10%))[`merge --squash`] \
      #gitgraph(chain(("a","b","e","s"), ("A","B","E","S"), dx: 1.15) + chain(("c","d"), ("C","D"), y: -0.9, x0: 2.3, dx: 1.15, color: c-grey, first-parent: "b").map(x => x + (ghost: true)), refs: ((name: "main", to: "s", dir: "right", dist: 1.05),), notes: ((pos: (3.45, 0.55), body: [S = C + D]),), unit: 0.9cm)],
    align(center)[#text(size: 7.5pt, weight: "bold")[③ Rebase + Fast-Forward] #h(4pt) #text(size: 7pt, fill: c-grey.darken(10%))[`rebase`, `merge --ff-only`] \
      #gitgraph(chain(("a","b","e"), ("A","B","E"), dx: 1.15) + chain(("c2","d2"), ("C'","D'"), x0: 3.45, dx: 1.15, color: c-accent, first-parent: "e"), refs: ((name: "main", to: "d2", dir: "right", dist: 1.05),), unit: 0.9cm)],
    align(center)[#text(size: 7.5pt, weight: "bold")[④ Rebase + Merge-Commit] #h(4pt) #text(size: 7pt, fill: c-grey.darken(10%))[`rebase`, `merge --no-ff`] \
      #gitgraph(chain(("a","b","e"), ("A","B","E"), dx: 1.15) + chain(("c2","d2"), ("C'","D'"), y: -0.9, x0: 3.45, dx: 1.15, color: c-accent, first-parent: "e") + ((id: "m", x: 5.75, y: 0, label: "M", parents: ("e","d2"), color: c-blue),), refs: ((name: "main", to: "m", dir: "right", dist: 1.05),), unit: 0.9cm)],
  ),
  caption: [Vier Ergebnisse aus derselben Ausgangslage. Der Dateistand am Ende ist in allen vier Fällen identisch.],
)

#table(columns: (auto, 1fr, 1fr),
  [Strategie], [Vorteile], [Nachteile],
  [① Merge-Commit], [Historie zeigt exakt, was wann parallel lief. Feature als Einheit revertierbar. Keine Commits werden umgeschrieben.], [Historie wird bei vielen Branches unübersichtlich ("Gleisanlage"). Zwischencommits wie "Tippfehler" landen in `main`.],
  [② Squash], [Ein sauberer Commit pro Feature, `main` bleibt linear und lesbar. Unordentliche Zwischencommits verschwinden.], [Einzelschritte des Features gehen in `main` verloren. Der Feature-Branch gilt für Git nicht als gemergt (`branch -d` weigert sich).],
  [③ Rebase + FF], [Völlig lineare Historie mit allen Einzelcommits. `git bisect` findet Fehler auf Commit-Ebene.], [Commits bekommen neue Hashes. Jeder Einzelcommit sollte sauber sein, sonst landet Unordnung linear in `main`.],
  [④ Rebase + Merge-Commit], [Lineare Einzelcommits und trotzdem eine sichtbare Klammer pro Feature (_semi-linear_).], [Etwas mehr Commits, aber meist der beste Kompromiss für Teams.],
)

=== Welche Strategie?

Für ein kleines Team oder ein Soloprojekt mit Pull Requests hat sich folgende Faustregel bewährt:

- *Squash* für kleine Pull Requests, deren Einzelcommits niemanden interessieren (typisch: ein Bugfix, eine kleine Funktion). Das ist der häufigste Fall.
- *Rebase + Merge-Commit* (oder Rebase + FF) für größere Features, deren Commits bewusst in sinnvolle Schritte gegliedert sind.
- *Merge-Commit ohne Rebase* für langlebige Branches, die mehrfach mit `main` abgeglichen werden, etwa Release-Branches.
- Legt euch pro Repository auf *eine* Standardstrategie fest. Gitea erlaubt, nicht gewünschte Stile in den Repository-Einstellungen abzuschalten.

#merke[Egal welche Strategie: Commits auf `main`, die schon auf dem Server liegen, werden *nie* umgeschrieben. Rebase und Squash betreffen nur den Feature-Branch vor dem Mergen.]

== Konflikte lösen

Ein Konflikt entsteht, wenn beide Seiten dieselbe Stelle einer Datei unterschiedlich geändert haben, oder wenn eine Seite eine Datei ändert, die die andere gelöscht hat. Git hält dann an und überlässt dir die Entscheidung. Das ist kein Fehler, sondern Absicht: Welche Variante inhaltlich richtig ist, kann nur ein Mensch entscheiden.

```out
Auto-merging src/config.py
CONFLICT (content): Merge conflict in src/config.py
Automatic merge failed; fix conflicts and then commit the result.
```

`git status` listet die betroffenen Dateien unter _Unmerged paths_. In jeder solchen Datei markiert Git die Konfliktstelle. Mit der Einstellung `merge.conflictStyle = zdiff3` aus Kapitel 2 sieht das so aus:

#datei("src/config.py")[
```python
<<<<<<< HEAD
TIMEOUT = 30
RETRIES = 5
||||||| 91b0c4e
TIMEOUT = 10
RETRIES = 3
=======
TIMEOUT = 10
RETRIES = 3
BACKOFF = 2.0
>>>>>>> feature
```
]

Von oben nach unten: *deine Seite* (`HEAD`, hier `main`), der *gemeinsame Ursprung* (die Merge-Basis) und *die andere Seite* (`feature`). Erst durch den Ursprung wird klar, was passiert ist: `main` hat die Werte erhöht, `feature` hat eine Zeile hinzugefügt. Die richtige Lösung übernimmt also beides:

```python
TIMEOUT = 30
RETRIES = 5
BACKOFF = 2.0
```

Der Ablauf ist immer derselbe:

+ Datei im Editor öffnen, jede Konfliktstelle inhaltlich lösen und *alle Markierungszeilen entfernen*.
+ Prüfen, ob das Projekt noch funktioniert, etwa mit `make test`.
+ Die gelöste Datei mit `git add datei` als erledigt markieren.
+ Wenn alle Dateien gelöst sind: `git commit` (bei einem Merge) oder `git rebase --continue` (bei einem Rebase).

Wer mittendrin merkt, dass er den Merge doch nicht will, kehrt mit `git merge --abort` (bzw. `git rebase --abort`) zum Zustand vor dem Merge zurück.

=== Ganze Dateien von einer Seite übernehmen

Manchmal ist klar, dass eine Seite komplett richtig ist, etwa bei generierten Dateien oder Lockfiles:

```bash
git checkout --ours   -- package-lock.json   # unsere Version nehmen
git checkout --theirs -- package-lock.json   # die andere Version nehmen
git add package-lock.json
```

#achtung[Beim *Rebase* sind `--ours` und `--theirs` vertauscht! Ein Rebase setzt deine Commits auf den anderen Branch. "Ours" ist dabei der Branch, auf den du setzt (etwa `main`), "theirs" sind deine eigenen Commits. Im Zweifel die Datei öffnen und nachsehen, statt blind eine Seite zu wählen.]

=== Grafische Werkzeuge

VS Code erkennt Konfliktdateien automatisch und bietet über den Merge-Editor Schaltflächen wie _Accept Current_, _Accept Incoming_ und _Accept Both_. Als Werkzeug für `git mergetool` richtest du es so ein:

```bash
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait --merge $REMOTE $LOCAL $BASE $MERGED'
git mergetool          # öffnet nacheinander jede Konfliktdatei
```

Alternativ ist mit Xcode das Apple-Werkzeug FileMerge dabei (`git mergetool --tool=opendiff`).

=== Konflikte seltener machen

Die meisten Konflikte entstehen, weil Branches zu lange leben. Kleine Pull Requests, die in Tagen statt Wochen gemergt werden, haben wenig Konfliktpotenzial. Ein langlebiger Feature-Branch sollte regelmäßig `main` aufnehmen (per Rebase oder Merge), damit Konflikte in kleinen Portionen statt auf einen Schlag kommen. Automatische Formatierer (etwa per Pre-Commit-Hook oder in der CI) verhindern zusätzlich reine Formatierungskonflikte. Und `rerere.enabled` sorgt dafür, dass du denselben Konflikt beim wiederholten Rebase nur einmal lösen musst.

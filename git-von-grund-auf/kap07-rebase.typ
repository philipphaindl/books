#import "lib.typ": *

= Rebase im Detail

Rebase ist das mächtigste Werkzeug, um Historie zu gestalten, und gleichzeitig das, vor dem am häufigsten gewarnt wird. Beides hat denselben Grund: Rebase erzeugt neue Commits und verwirft die alten. Wer versteht, was dabei genau passiert, kann es gezielt und gefahrlos einsetzen.

== Was Rebase tut

`git rebase main` (ausgeführt auf `feature`) bedeutet: "Nimm alle Commits, die `feature` hat und `main` nicht, und spiele sie der Reihe nach auf dem aktuellen Ende von `main` neu ab." Git berechnet dafür für jeden Commit den Diff zu seinem Elternteil, wendet ihn auf der neuen Basis an und erzeugt einen neuen Commit mit gleicher Nachricht und gleichem Autor, aber neuem Elternteil und damit *neuem Hash*.

```bash
git switch feature
git rebase main
```

#figure(
  vorher-nachher(
    gitgraph(chain(("a","b","e"), ("A","B","E")) + chain(("c","d"), ("C","D"), y: -1, x0: 2.6, color: c-accent, first-parent: "b"),
      refs: ((name: "main", to: "e"), (name: "feature", to: "d", dir: "right", dist: 1.25, color: c-accent)), unit: 1cm),
    gitgraph(chain(("a","b","e"), ("A","B","E")) + chain(("c","d"), ("C","D"), y: -1, x0: 2.6, color: c-accent, first-parent: "b").map(x => x + (ghost: true))
      + chain(("c2","d2"), ("C'","D'"), x0: 3.9, color: c-accent, first-parent: "e"),
      refs: ((name: "main", to: "e"), (name: "feature", to: "d2", dir: "down", color: c-accent)), unit: 1cm),
    lb: [Nach `git rebase main`],
  ),
  caption: [`C` und `D` werden als neue Commits `C'` und `D'` auf `E` gesetzt. Die Originale bleiben unerreichbar zurück.],
)

Danach kann `main` per Fast-Forward nachgezogen werden, die Historie ist linear. Die ursprünglichen Commits `C` und `D` existieren noch (über das Reflog auffindbar), gehören aber zu keinem Branch mehr.

== Die goldene Regel

#achtung[*Rebase keine Commits, auf denen andere bereits aufbauen.* Wer deine alten Commits `C` und `D` schon geholt hat und darauf weiterarbeitet, hat nach deinem Rebase eine Historie, die nicht mehr zu deiner passt. Das Ergebnis sind doppelte Commits und verwirrende Konflikte.]

In der Praxis heißt das:

- Eigene, noch nicht gepushte Commits darfst du beliebig umbauen.
- Einen eigenen Feature-Branch, den du nur für den Pull Request gepusht hast, darfst du ebenfalls umbauen. Danach ist ein `git push --force-with-lease` nötig (Kapitel 8). Arbeitet jemand anderes auf demselben Branch mit, sprich das vorher ab.
- Gemeinsame Branches wie `main` werden nie umgeschrieben. Gitea verhindert das zusätzlich über Branch-Schutzregeln (Kapitel 12).

== Interaktiver Rebase

Mit `-i` (_interactive_) zeigt Git vor dem Abspielen eine Liste der betroffenen Commits im Editor. Durch Bearbeiten dieser Liste bestimmst du, was mit jedem Commit geschieht:

```bash
git rebase -i HEAD~4       # die letzten vier Commits bearbeiten
git rebase -i main         # alle Commits des Branches seit der Abzweigung von main
```

#datei("Editor: git-rebase-todo")[
```text
pick 3a1f2c0 Login-Formular anlegen
pick 7b9e4d1 Validierung ergänzen
pick c02d8a3 Tippfehler
pick e5f6b72 Tests für Login

# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# ...
```
]

#merke[Die Liste steht in *chronologischer Reihenfolge*, der älteste Commit oben. Das ist genau umgekehrt zu `git log`, das den neuesten zuerst zeigt.]

#table(columns: (auto, auto, 1fr),
  [Befehl], [Kurz], [Wirkung],
  [`pick`], [`p`], [Commit unverändert übernehmen.],
  [`reword`], [`r`], [Commit übernehmen, aber Nachricht im Editor ändern.],
  [`edit`], [`e`], [Nach diesem Commit anhalten, um ihn zu verändern (Dateien, Aufteilen). Weiter mit `git rebase --continue`.],
  [`squash`], [`s`], [Mit dem vorherigen Commit verschmelzen, beide Nachrichten im Editor zusammenführen.],
  [`fixup`], [`f`], [Mit dem vorherigen Commit verschmelzen, die eigene Nachricht verwerfen.],
  [`fixup -C`], [], [Verschmelzen und stattdessen die Nachricht *dieses* Commits verwenden.],
  [`drop`], [`d`], [Commit weglassen (eine Zeile zu löschen wirkt genauso).],
  [`exec`], [`x`], [Einen Shell-Befehl ausführen, z.B. `x make test` nach jedem Commit.],
  [`break`], [`b`], [An dieser Stelle anhalten, weiter mit `--continue`.],
)

Zeilen lassen sich auch umsortieren, um Commits in eine andere Reihenfolge zu bringen. Für das Beispiel oben wäre eine sinnvolle Aufräumaktion, den Tippfehler-Commit mit dem Formular-Commit zu verschmelzen:

```text
pick 3a1f2c0 Login-Formular anlegen
fixup c02d8a3 Tippfehler
pick 7b9e4d1 Validierung ergänzen
pick e5f6b72 Tests für Login
```

Nach dem Speichern und Schließen des Editors arbeitet Git die Liste ab. Aus vier Commits werden drei saubere.

== Der Fixup-Workflow

Noch eleganter ist es, Korrekturen gleich beim Committen als solche zu markieren. Angenommen, du bemerkst einen Fehler in einem früheren Commit `3a1f2c0` deines Branches:

```bash
git add src/login.py
git commit --fixup=3a1f2c0       # erzeugt einen Commit "fixup! Login-Formular anlegen"
# ... weiterarbeiten, weitere Fixups ...
git rebase -i main               # mit rebase.autoSquash = true werden die fixup!-Commits
                                 # automatisch hinter ihr Ziel sortiert und als fixup markiert
```

Du musst in der Liste nur noch speichern. Dieses Muster ist ideal für Review-Anmerkungen in Pull Requests: Jede Korrektur wird als `fixup!` committet und gepusht, der Reviewer sieht genau, was sich geändert hat, und vor dem Mergen werden alle Fixups mit einem Rebase eingefaltet.

== Branches umhängen: `--onto`

Manchmal baut ein Branch auf einem anderen auf, der inzwischen per Squash gemergt wurde. Ein einfaches `git rebase main` würde dann versuchen, auch die schon enthaltenen Commits erneut anzuwenden. Mit `--onto` sagst du Git genau, welche Commits es wohin setzen soll:

```bash
git rebase --onto main feature-1 feature-2
# Setze die Commits von feature-2, die nicht in feature-1 sind, auf main.
```

#figure(
  vorher-nachher(
    gitgraph(chain(("a","b","s"), ("A","B","S")) + chain(("c","d"), ("C","D"), y: -0.9, x0: 2.5, dx: 1.2, color: c-violet, first-parent: "b") + chain(("f","g"), ("F","G"), y: -1.8, x0: 4.9, dx: 1.2, color: c-accent, first-parent: "d"),
      refs: ((name: "main", to: "s"), (name: "feature-1", to: "d", dir: "up", dist: 0.75, color: c-violet), (name: "feature-2", to: "g", dir: "up", dist: 0.75, color: c-accent)), unit: 0.95cm),
    gitgraph(chain(("a","b","s"), ("A","B","S")) + chain(("f2","g2"), ("F'","G'"), x0: 3.9, dx: 1.2, color: c-accent, first-parent: "s"),
      refs: ((name: "main", to: "s"), (name: "feature-2", to: "g2", dir: "down", color: c-accent)), unit: 0.95cm),
    lb: [Nach `rebase --onto`],
  ),
  caption: [`feature-1` wurde als Squash-Commit `S` gemergt. Nur `F` und `G` werden auf `main` übertragen.],
)

Arbeitest du mit mehreren aufeinander aufbauenden Branches (_stacked branches_), verschiebt die Einstellung `rebase.updateRefs = true` aus Kapitel 2 beim Rebase des obersten Branches automatisch alle darunterliegenden Branch-Zeiger mit.

== Während eines Rebase

Ein Rebase kann an jedem Commit anhalten: bei `edit`, `break` oder einem Konflikt. `git status` zeigt dann an, wo du stehst (_interactive rebase in progress; onto 5e1d2f3_), und der Prompt aus Kapitel 2 zeigt `rebase-i`.

#table(columns: (auto, 1fr),
  [Befehl], [Wirkung],
  [`git rebase --continue`], [Nach dem Lösen eines Konflikts (Datei bearbeiten, `git add`) oder nach einem `edit` weitermachen.],
  [`git rebase --skip`], [Den aktuellen Commit komplett weglassen, etwa wenn seine Änderung schon in `main` enthalten ist.],
  [`git rebase --abort`], [Alles rückgängig machen, zurück zum Zustand vor dem Rebase.],
)

Weil ein Rebase Commit für Commit vorgeht, kann derselbe Konflikt in mehreren Commits hintereinander auftauchen. Das ist lästig, aber normal. Hier hilft `rerere`. Und falls das Ergebnis nach Abschluss doch nicht gefällt: Git merkt sich den Stand vor dem Rebase in `ORIG_HEAD`, `git reset --hard ORIG_HEAD` stellt ihn wieder her (solange du seitdem nichts anderes Größeres gemacht hast, sonst über das Reflog, Kapitel 9).

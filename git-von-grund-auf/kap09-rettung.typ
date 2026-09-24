#import "lib.typ": *

= Rückgängig machen und Rettung

Die gute Nachricht vorweg: In Git geht erstaunlich wenig endgültig verloren. Alles, was einmal committet wurde, lässt sich wochenlang wiederfinden. Wirklich gefährlich sind nur zwei Dinge: Änderungen, die *nie committet* wurden, und Befehle, die das Arbeitsverzeichnis überschreiben (`reset --hard`, `restore`, `clean`). Dieses Kapitel ordnet die Werkzeuge danach, was sie verändern.

== Die Werkzeuge im Überblick

#table(columns: (auto, 1fr, auto, auto),
  [Befehl], [Wirkt auf], [Historie], [Nach Push],
  [`git restore`], [Dateien im Arbeitsverzeichnis oder Index], [unverändert], [unkritisch],
  [`git reset`], [verschiebt den Branch, optional Index und Dateien], [umgeschrieben], [nur eigene Branches],
  [`git revert`], [neuer Commit, der einen alten umkehrt], [ergänzt], [sicher],
  [`git reflog`], [zeigt frühere Positionen von `HEAD`], [nur lesend], [nur lokal],
  [`git stash`], [legt Änderungen beiseite], [unverändert], [nur lokal],
  [`git cherry-pick`], [kopiert einen Commit auf den aktuellen Branch], [ergänzt], [sicher],
  [`git clean`], [löscht unversionierte Dateien], [unverändert], [unkritisch],
)

== `restore`: Dateien zurücksetzen

```bash
git restore src/app.py                  # lokale Änderungen verwerfen (Stand aus dem Index)
git restore --staged src/app.py         # Vormerkung aufheben, Änderung bleibt
git restore --source=HEAD~3 src/app.py  # Datei auf den Stand von vor drei Commits bringen
git restore -p src/app.py               # nur einzelne Abschnitte verwerfen
```

#achtung[`git restore datei` (ohne `--staged`) verwirft uncommittete Änderungen *unwiderruflich*. Sie waren nie in Git gespeichert, also kann Git sie auch nicht zurückholen. Im Zweifel vorher `git stash` ausführen.]

== `reset`: den Branch verschieben

`git reset <commit>` setzt den aktuellen Branch auf einen anderen Commit. Die drei Modi unterscheiden sich darin, was sie außer dem Branch-Zeiger noch anfassen:

#figure(
  grid(columns: (1.3fr, 1fr), column-gutter: 14pt, align: horizon,
    gitgraph(chain(("a","b"), ("A","B")) + ((id: "c", x: 2.6, y: 0, label: "C", parents: ("b",), color: c-blue, ghost: true),),
      refs: ((name: "main", to: "b", dir: "down"), (name: "HEAD", to: "main", kind: "head", dir: "down", dist: 0.7)),
      notes: ((pos: (2.6, 0.62), body: [`git reset HEAD~1`]),), unit: 1.05cm),
    table(columns: (auto, auto, auto, auto),
      [Modus], [Branch], [Index], [Dateien],
      [`--soft`], [✓ auf B], [bleibt], [bleiben],
      [`--mixed`], [✓ auf B], [✓ wie B], [bleiben],
      [`--hard`], [✓ auf B], [✓ wie B], [✓ wie B],
    ),
  ),
  caption: [Alle drei Modi entfernen `C` aus dem Branch. `--mixed` ist der Standard, wenn kein Modus angegeben wird.],
)

- *`--soft`:* Der Commit ist weg, seine Änderungen liegen aber vorgemerkt im Index. Ideal, um die letzten Commits neu zusammenzufassen: `git reset --soft HEAD~3 && git commit`.
- *`--mixed`:* Commit weg, Änderungen liegen unvorgemerkt im Arbeitsverzeichnis. Gut zum Aufteilen (siehe Kapitel 8). Ohne Commit-Angabe (`git reset`) nimmt es nur alle Vormerkungen zurück.
- *`--hard`:* Commit weg, *und alle uncommitteten Änderungen im Arbeitsverzeichnis ebenfalls*. Committetes lässt sich über das Reflog retten, Uncommittetes nicht.

Typische Anwendungen:

```bash
git reset --soft HEAD~1          # "letzten Commit rückgängig, Änderungen behalten"
git reset --hard origin/main     # lokalen Branch exakt auf den Server-Stand bringen
git reset --hard ORIG_HEAD       # missglückten Merge/Rebase direkt danach rückgängig machen
```

== `revert`: sicher rückgängig nach dem Push

Ist ein fehlerhafter Commit bereits in `main` und damit bei anderen angekommen, darfst du ihn nicht per `reset` entfernen. Stattdessen erzeugt `git revert` einen *neuen* Commit, der die Änderungen des alten exakt umkehrt. Die Historie bleibt intakt und dokumentiert sogar, dass und warum zurückgenommen wurde.

```bash
git revert 7b9e4d1               # erzeugt "Revert 'Validierung ergänzen'"
git revert -m 1 4f2a9e0          # einen Merge-Commit zurücknehmen (Elternteil 1 = main behalten)
git revert --no-commit A^..C     # mehrere Commits in einem einzigen Revert-Commit
```

#figure(
  gitgraph(chain(("a","b","c","r"), ("A","B","C","B̄")), refs: ((name: "main", to: "r"),),
    notes: ((pos: (3.9, -0.62), body: [kehrt `B` um]), (pos: (1.3, -0.62), body: [fehlerhaft])), unit: 1.05cm),
  caption: [Revert: `B̄` hebt die Änderungen von `B` auf, alle Commits bleiben erhalten.],
)

#tipp[Wird ein per Revert zurückgenommenes Feature später repariert, reicht ein erneuter Merge nicht: Git weiß, dass die ursprünglichen Commits schon enthalten sind. Dann revertierst du den Revert-Commit (`git revert B̄`) und bringst danach die Reparatur ein.]

== `reflog`: das Sicherheitsnetz

Git protokolliert lokal jede Bewegung von `HEAD` und jedes Branches: jeden Commit, Checkout, Reset, Rebase und Merge. Dieses Protokoll ist das _Reflog_, und es ist das wichtigste Rettungswerkzeug überhaupt.

```bash
git reflog
```
```out
a90c3d1 (HEAD -> main) HEAD@{0}: reset: moving to HEAD~2
e5f6b72 HEAD@{1}: commit: Tests für Login
7b9e4d1 HEAD@{2}: commit: Validierung ergänzen
3a1f2c0 HEAD@{3}: checkout: moving from feature/login to main
```

Angenommen, `git reset --hard HEAD~2` war ein Versehen. Das Reflog zeigt, dass `HEAD` vorher auf `e5f6b72` stand. Du holst den Stand zurück:

```bash
git reset --hard HEAD@{1}           # zurück zum Stand vor dem Reset
# oder vorsichtiger: den alten Stand erst als Branch sichern und ansehen
git branch rettung e5f6b72
git log --oneline rettung
```

Das Reflog hilft auch bei gelöschten Branches (den letzten Commit des Branches im Reflog suchen und neu anlegen) und bei Commits aus einem Detached-HEAD-Ausflug. Einträge werden standardmäßig 90 Tage aufbewahrt, für nicht mehr erreichbare Commits 30 Tage. `git reflog show feature/login` zeigt das Protokoll eines einzelnen Branches.

#merke[Das Reflog ist rein lokal. Es wird weder gepusht noch geklont. Auf einem frisch geklonten Rechner gibt es keine Vorgeschichte, auf die man zurückgreifen könnte.]

== `stash`: Änderungen beiseitelegen

Der Stash ist ein Stapel für halbfertige Arbeit, wenn du kurz etwas anderes tun musst:

```bash
git stash push -m "Login halbfertig"   # Änderungen sichern, Arbeitsverzeichnis sauber
git stash push -u -m "inkl. neuer Dateien"   # -u nimmt auch untracked Dateien mit
git stash list                           # stash@{0}: On feature/login: Login halbfertig
git stash show -p stash@{0}              # Inhalt als Diff ansehen
git stash pop                            # neuesten Stash anwenden und entfernen
git stash apply stash@{1}                # anwenden, aber behalten
git stash drop stash@{1}                 # einzelnen Stash löschen
git stash branch neuer-branch            # Stash in einem neuen Branch wiederherstellen
```

Stashes sind praktisch, geraten aber leicht in Vergessenheit. Für alles, was länger als ein paar Minuten liegen bleibt, ist ein WIP-Commit auf einem eigenen Branch oder ein Worktree (Kapitel 10) die robustere Wahl.

== `cherry-pick`: einzelne Commits übernehmen

`git cherry-pick` nimmt die Änderung eines einzelnen Commits (seinen Diff zum Elternteil) und wendet sie als *neuen Commit* auf den aktuellen Branch an. Nachricht und Autor bleiben gleich, Elternteil und Hash sind neu. Übernommen wird nur genau diese eine Änderung, nicht die Vorgeschichte des Commits und nicht die übrigen Commits seines Branches.

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 10pt,
    align(center)[#text(size: 7.5pt, weight: "bold")[Fix aus einem Feature-Branch vorziehen] \
      #gitgraph(chain(("a","b","e","d2"), ("A","B","E","D'"), dx: 1.2) + chain(("c","d"), ("C","D"), y: -1, x0: 2.4, dx: 1.2, color: c-accent, first-parent: "b"),
        refs: ((name: "main", to: "d2", dir: "right", dist: 0.95), (name: "feature", to: "d", dir: "right", dist: 1.15, color: c-accent)),
        notes: ((pos: (3.6, 0.55), body: [Kopie von `D`]),), unit: 0.95cm)],
    align(center)[#text(size: 7.5pt, weight: "bold")[Backport auf einen Release-Branch] \
      #gitgraph(chain(("a","b","c","f","g"), ("A","B","C","F","G"), dx: 1.1) + ((id: "f2", x: 2.2, y: -1, label: "F'", parents: ("b",), color: c-violet),),
        refs: ((name: "main", to: "g", dir: "up"), (name: "v1.2.0", to: "b", kind: "tag", dir: "up"), (name: "release/1.2", to: "f2", dir: "right", dist: 1.45, color: c-violet)),
        notes: ((pos: (3.3, 0.55), body: [Fix]),), unit: 0.95cm)],
  ),
  caption: [Links wird ein dringender Fix vorgezogen, obwohl das Feature noch nicht fertig ist. Rechts wird der Fix `F` aus `main` in die gepflegte Version 1.2 übernommen.],
)

=== Wann Cherry-Pick das richtige Werkzeug ist

- *Backports:* Du pflegst neben `main` eine ältere Version auf einem Release-Branch (etwa `release/1.2`), und ein Fix aus `main` soll dort ebenfalls ausgeliefert werden, ohne die neuen Funktionen mitzunehmen. Das ist der klassische Anwendungsfall.
- *Dringender Einzelfix:* Ein Commit auf einem unfertigen Feature-Branch behebt einen Fehler, der sofort in `main` gebraucht wird.
- *Rettung:* Commits auf dem falschen Branch gelandet (siehe Notfall-Tabelle am Ende dieses Kapitels).

=== Die Befehle

```bash
git switch release/1.2
git cherry-pick 7b9e4d1              # einen Commit übernehmen
git cherry-pick -x 7b9e4d1           # mit Herkunftsvermerk in der Nachricht
git cherry-pick 3a1f2c0 7b9e4d1      # mehrere einzelne Commits, in dieser Reihenfolge
git cherry-pick A^..C                # Bereich von A bis C, A eingeschlossen
git cherry-pick --no-commit A B C    # nur Änderungen übernehmen, dann selbst EIN Commit
git commit -m "CSRF-Fixes zurückportieren"
git cherry-pick -m 1 4f2a9e0         # Merge-Commit: Änderungen relativ zum ersten Elternteil
```

`-x` hängt an die Nachricht die Zeile `(cherry picked from commit 7b9e4d1...)` an. Das ist bei Backports auf öffentliche Branches sehr nützlich, weil man später nachvollziehen kann, woher ein Fix stammt. Bei der Rettung privater Commits, deren Original ohnehin verschwindet, verweist der Vermerk dagegen ins Leere und kann entfallen.

Bei Bereichen ist die Schreibweise wichtig: `A..C` bedeutet "alle Commits bis `C`, die nicht in `A` enthalten sind", schließt `A` selbst also *aus*. Soll `A` dabei sein, lautet der Bereich `A^..C`. Einen Merge-Commit kann Git nicht ohne Weiteres übernehmen, weil unklar ist, gegenüber welchem Elternteil die Änderung gemeint ist. `-m 1` wählt das erste Elternteil, also "alles, was dieser Merge in den Ziel-Branch gebracht hat".

=== Konflikte beim Cherry-Pick

Weil der Diff auf einer anderen Basis angewendet wird als der, auf der er entstanden ist, kann es Konflikte geben, besonders bei Backports auf ältere Versionen. Die Lösung funktioniert wie beim Merge (Kapitel 6):

```bash
# Konfliktdateien bearbeiten, dann:
git add src/auth.py
git cherry-pick --continue      # abschließen bzw. mit dem nächsten Commit weiter
git cherry-pick --skip          # diesen Commit des Bereichs auslassen
git cherry-pick --abort         # alles zurück zum Zustand vor dem Cherry-Pick
```

Anders als beim Rebase sind `--ours` und `--theirs` hier *nicht* vertauscht: "Ours" ist der Branch, auf dem du stehst, "theirs" der übernommene Commit. Meldet Git beim Übernehmen _The previous cherry-pick is now empty_, ist die Änderung auf dem Ziel-Branch bereits vorhanden. Dann ist `--skip` richtig.

=== Wenn der Quell-Branch später doch gemergt wird

Nach einem Cherry-Pick existiert dieselbe Änderung als zwei verschiedene Commits (`D` und `D'`). Das ist meist harmlos, sollte man aber kennen:

- *Rebase* erkennt, dass eine inhaltsgleiche Änderung schon im Ziel liegt, und lässt den Commit weg. Git meldet das als _skipped previously applied commit_.
- *Merge* führt beide Seiten zusammen. Da beide dieselbe Änderung enthalten, gibt es in der Regel keinen Konflikt. Wurde die betroffene Stelle danach aber auf einer Seite weiter verändert, kann doch einer entstehen.
- *Squash-Merge* eines PRs zeigt die bereits übernommene Änderung nicht mehr im Diff, weil sie im Ziel schon vorhanden ist.

=== Prüfen, was schon übernommen wurde

Bei Release-Branches stellt sich regelmäßig die Frage, welche Fixes aus `main` dort noch fehlen. Git vergleicht dafür nicht Hashes, sondern den Inhalt der Änderungen:

```bash
git cherry -v release/1.2 main
```
```out
- 7b9e4d1 CSRF-Token bei Logout prüfen
+ 3c55a0e Export für große Dateien beschleunigen
+ 91fe2d4 Neue Berichtsansicht
```

`-` bedeutet: Eine inhaltsgleiche Änderung ist in `release/1.2` schon vorhanden. `+` bedeutet: fehlt noch. Dasselbe zeigt `git log --oneline --cherry-mark release/1.2...main`, das übernommene Commits mit `=` markiert. Musste beim Cherry-Pick ein Konflikt gelöst werden, ist die Änderung nicht mehr exakt gleich und erscheint weiterhin als fehlend. Hier hilft der `-x`-Vermerk: `git log release/1.2 --grep="cherry picked from commit 7b9e4d1"` findet den Backport trotzdem.

=== Mit Pull Request statt direkt

Auch Backports sollten durch die CI laufen. Statt direkt auf den Release-Branch zu committen, legst du einen eigenen Branch an und öffnest in Gitea einen PR gegen `release/1.2`:

```bash
git fetch
git switch -c backport/1.2-csrf origin/release/1.2
git cherry-pick -x 7b9e4d1
git push                          # PR in Gitea mit Ziel-Branch release/1.2
```

#achtung[Cherry-Pick ist ein Werkzeug für Einzelfälle. Werden Branches regelmäßig per Cherry-Pick abgeglichen, entstehen viele doppelte Commits und man verliert den Überblick, was wo enthalten ist. Wer von vornherein weiß, dass ein Fix in mehrere Versionen gehört, legt den Fix-Branch besser vom ältesten betroffenen Stand an (etwa von `release/1.2`) und mergt ihn dann in `release/1.2` *und* in `main`. So existiert die Änderung nur als ein einziger Commit.]

== `clean`: unversionierte Dateien löschen

```bash
git clean -n        # Probelauf: zeigt nur, was gelöscht würde
git clean -fd       # unversionierte Dateien und Ordner löschen
git clean -fdx      # zusätzlich ignorierte Dateien (Build-Ordner, .venv, node_modules)
git clean -i        # interaktiv auswählen
```

`git clean` löscht Dateien, die Git nie gesehen hat, und kann sie deshalb auch nicht wiederherstellen. Immer zuerst mit `-n` prüfen.

== Notfall-Tabelle

#table(columns: (1fr, 1.25fr),
  [Ich habe ...], [Lösung],
  [... auf `main` committet statt auf einem Feature-Branch (noch nicht gepusht)], [`git switch -c feature/x` (nimmt die Commits mit), dann `git switch main` und `git reset --hard origin/main`.],
  [... auf dem falschen Branch committet], [Auf dem richtigen Branch `git cherry-pick <hash>`, auf dem falschen `git reset --hard HEAD~1`.],
  [... mit `reset --hard` Commits verloren], [`git reflog`, dann `git reset --hard HEAD@{n}` oder `git branch rettung <hash>`.],
  [... einen Branch mit ungemergten Commits gelöscht], [Git nennt beim Löschen den letzten Hash (_was 3a1f2c0_), sonst im Reflog suchen: `git branch name 3a1f2c0`.],
  [... einen Merge gemacht, der schiefging (nicht gepusht)], [`git reset --hard ORIG_HEAD`.],
  [... einen fehlerhaften Merge nach `main` gepusht], [`git revert -m 1 <merge-hash>`, dann pushen.],
  [... mitten in einem Merge/Rebase den Überblick verloren], [`git merge --abort` bzw. `git rebase --abort`.],
  [... ein Passwort committet und gepusht], [Sofort das Passwort austauschen, dann ggf. `git filter-repo` (Kapitel 8).],
  [... eine riesige Datei committet (noch nicht gepusht)], [`git rm --cached datei`, in `.gitignore` eintragen, `git commit --amend`.],
  [... uncommittete Änderungen mit `restore` oder `reset --hard` verloren], [Git kann nicht helfen. Eventuell hat der Editor eine lokale Historie (VS Code: _Timeline_) oder Time Machine eine Kopie.],
)

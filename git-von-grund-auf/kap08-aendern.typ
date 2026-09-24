#import "lib.typ": *

= Commits nachträglich ändern

Eine falsche Commit-Nachricht, eine vergessene Datei, ein Commit, der eigentlich zwei sein sollte: Solche Korrekturen sind in Git alltäglich. Nach Kapitel 1 ist klar, was dabei technisch passiert: Commits sind unveränderlich, "ändern" heißt immer, einen neuen Commit zu erzeugen und den Branch auf ihn umzuhängen. Die entscheidende Frage ist daher nicht _wie_, sondern *ob der Commit schon gepusht wurde*.

== Übersicht

#table(columns: (1fr, auto),
  [Situation], [Befehl],
  [Nachricht des letzten Commits ändern], [`git commit --amend`],
  [Datei im letzten Commit vergessen], [`git add datei` + `git commit --amend --no-edit`],
  [Nachricht eines älteren Commits ändern], [`git rebase -i` mit `reword`],
  [Nachrichten mehrerer Commits ändern], [`git rebase -i` mit mehreren `reword`],
  [Inhalt eines älteren Commits korrigieren], [`git commit --fixup` + `git rebase -i --autosquash`],
  [Commit in zwei aufteilen], [`git rebase -i` mit `edit` + `git reset HEAD^`],
  [Autor bzw. E-Mail korrigieren], [`git commit --amend --reset-author`],
  [bereits gepushten Feature-Branch aktualisieren], [`git push --force-with-lease`],
  [bereits in `main` gepusht], [nicht umschreiben, siehe @sec-gepusht],
)

== Die letzte Commit-Nachricht ändern

Der einfachste und häufigste Fall. `--amend` ersetzt den letzten Commit durch einen neuen:

```bash
git commit --amend                         # öffnet den Editor mit der alten Nachricht
git commit --amend -m "Login-Sperre einführen"   # neue Nachricht direkt angeben
```

#figure(
  vorher-nachher(
    gitgraph(chain(("a","b","c"), ("A","B","C")), refs: ((name: "main", to: "c"),), unit: 1cm),
    gitgraph(chain(("a","b"), ("A","B")) + ((id: "c", x: 2.6, y: 0.95, label: "C", parents: ("b",), color: c-blue, ghost: true), (id: "c2", x: 2.6, y: 0, label: "C'", parents: ("b",), color: c-blue)),
      refs: ((name: "main", to: "c2", dir: "right", dist: 1.1),), unit: 1cm),
    lb: [Nach `git commit --amend`],
  ),
  caption: [`--amend` erzeugt einen Ersatz `C'` mit gleichem Elternteil. `C` bleibt verwaist zurück.],
)

#achtung[`--amend` nimmt *alles mit, was gerade im Index liegt*. Wer nur die Nachricht korrigieren will, prüft vorher mit `git status`, dass nichts vorgemerkt ist. Sonst landet eine halbfertige Änderung versehentlich im korrigierten Commit.]

== Vergessene Dateien nachreichen

```bash
git add vergessene_datei.py
git commit --amend --no-edit     # Nachricht unverändert lassen
```

Mit dem Alias `amend` aus der Konfiguration in Kapitel 2 verkürzt sich die zweite Zeile auf `git amend`.

== Die Nachricht eines älteren Commits ändern

Hier hilft der interaktive Rebase aus Kapitel 7. Schritt für Schritt:

*1. Den Commit finden.* Mit `git log --oneline` siehst du, wie weit er zurückliegt:

```out
e5f6b72 (HEAD -> feature/login) Tests für Login
7b9e4d1 Validirung ergänzen
3a1f2c0 Login-Formular anlegen
91b0c4e (main) README ergänzt
```

*2. Den Rebase starten,* und zwar ab dem Elternteil des betroffenen Commits. Der Tippfehler steckt im zweitneuesten Commit, also reichen die letzten zwei:

```bash
git rebase -i HEAD~2      # oder: git rebase -i 7b9e4d1^   (^ = "Elternteil von")
```

*3. In der Liste `pick` durch `reword` (oder kurz `r`) ersetzen,* speichern und den Editor schließen:

```text
r 7b9e4d1 Validirung ergänzen
pick e5f6b72 Tests für Login
```

*4. Git öffnet den Editor ein zweites Mal*, jetzt mit der Nachricht dieses Commits. Korrigieren, speichern, schließen. Git spielt die restlichen Commits automatisch ab:

```out
[detached HEAD 4c8d0e2] Validierung ergänzen
Successfully rebased and updated refs/heads/feature/login.
```

#figure(
  vorher-nachher(
    gitgraph(chain(("b","c","d","e"), ("91b","3a1","7b9","e5f"), dx: 1.25, color: c-blue).map(x => if x.id in ("c","d","e") { x + (color: c-accent) } else { x }),
      refs: ((name: "feature/login", to: "e", dir: "right", dist: 1.5, color: c-accent),), unit: 0.95cm),
    gitgraph(chain(("b","c"), ("91b","3a1"), dx: 1.25).map(x => if x.id == "c" { x + (color: c-accent) } else { x }) + chain(("d2","e2"), ("4c8","a90"), x0: 2.5, dx: 1.25, color: c-accent, first-parent: "c"),
      refs: ((name: "feature/login", to: "e2", dir: "right", dist: 1.5, color: c-accent),), unit: 0.95cm),
    lb: [Nach dem `reword`],
  ),
  caption: [Der korrigierte Commit und *alle danach* bekommen neue Hashes, frühere Commits bleiben unverändert.],
)

Mehrere Nachrichten auf einmal änderst du, indem du in Schritt 3 mehrere Zeilen auf `reword` setzt. Git öffnet den Editor dann nacheinander für jede. Soll auch der allererste Commit des Repositories geändert werden, der kein Elternteil hat, verwendest du `git rebase -i --root`.

#tipp[Abkürzung ohne Bearbeiten der Liste: `git commit --fixup=reword:7b9e4d1` fragt sofort nach der neuen Nachricht und legt einen Markierungs-Commit an. Ein späteres `git rebase -i --autosquash main` wendet die Korrektur an.]

== Einen Commit aufteilen

Hat ein Commit zu viel auf einmal geändert, lässt er sich per `edit` zerlegen:

```bash
git rebase -i HEAD~3            # beim betroffenen Commit "edit" eintragen
# Git hält nach diesem Commit an
git reset HEAD^                 # Commit auflösen, Änderungen bleiben als unstaged erhalten
git add -p                      # ersten Teil auswählen
git commit -m "Validierung ergänzen"
git add -p                      # zweiten Teil auswählen
git commit -m "Fehlermeldungen übersetzen"
git rebase --continue
```

== Wenn der Commit schon gepusht ist <sec-gepusht>

Hast du einen Branch bereits gepusht und danach lokal umgeschrieben, lehnt der Server einen normalen Push ab, weil deine neue Historie die alte nicht mehr enthält. Du musst den Server anweisen, seinen Branch zu ersetzen. Dafür gibt es drei Varianten:

#table(columns: (auto, 1fr),
  [Befehl], [Verhalten],
  [`git push --force`], [Überschreibt den Server-Branch bedingungslos. Hat inzwischen jemand anderes etwas gepusht, ist es weg. *Vermeiden.*],
  [`git push --force-with-lease`], [Überschreibt nur, wenn der Server-Branch noch dort steht, wo dein `origin/feature` ihn zuletzt gesehen hat. Sonst Abbruch mit _stale info_.],
  [`git push --force-with-lease --force-if-includes`], [Prüft zusätzlich, ob du den Server-Stand auch tatsächlich in deine Arbeit aufgenommen hast. Schützt vor dem Fall, dass ein zwischenzeitliches `git fetch` die "Lease" unbemerkt erneuert hat.],
)

Die Idee der "Lease" (Pacht): Du darfst den Branch nur überschreiben, solange du nachweisen kannst, dass du den aktuellen Stand kennst. Als Alias lohnt sich `git config --global alias.pushf "push --force-with-lease --force-if-includes"`.

=== Und wenn es schon in `main` ist?

Commits auf einem geschützten, gemeinsam genutzten Branch werden nicht umgeschrieben. Gitea lehnt einen Force-Push auf `main` bei aktivem Branch-Schutz ohnehin ab. Für eine unglückliche Nachricht gibt es pragmatische Wege:

- Mit der Tippfehler-Nachricht leben. Das ist fast immer die richtige Antwort.
- Eine Notiz anhängen, ohne den Commit zu ändern: `git notes add -m "Gemeint war: ..." 7b9e4d1`. Notizen erscheinen in `git log`, müssen aber separat gepusht werden (`git push origin refs/notes/*`).
- Bei inhaltlichen Fehlern: `git revert` (Kapitel 9).

#tipp[Bei Squash-Merges in Gitea kannst du die Nachricht des entstehenden Commits im Merge-Dialog frei bearbeiten. Unordentliche Einzelnachrichten im Pull Request sind dann egal, entscheidend ist nur die Nachricht, die du beim Mergen formulierst.]

== Autor und E-Mail korrigieren

Wurde mit falscher Identität committet, etwa mit der privaten statt der dienstlichen Adresse, korrigierst du zuerst die Konfiguration und dann den Commit:

```bash
git config user.email "philipp.haindl@firma.example"
git commit --amend --reset-author --no-edit         # letzter Commit

# mehrere Commits, z.B. die letzten fünf:
git rebase HEAD~5 --exec "git commit --amend --reset-author --no-edit"
```

Ganz ohne Umschreiben geht es mit einer Datei `.mailmap`: Sie ordnet alte Namen und Adressen den richtigen zu, und `log`, `shortlog` sowie `blame` zeigen die korrigierte Identität, ohne dass sich ein Hash ändert:

#datei(".mailmap")[
```text
Philipp Haindl <philipp.haindl@firma.example> <philipp@privat.example>
```
]

== Große Umbauten: Dateien aus der gesamten Historie entfernen

Muss eine Datei aus _allen_ Commits verschwinden (Passwort, riesige Binärdatei), reicht Rebase nicht. Dafür gibt es `git filter-repo` (`brew install git-filter-repo`), den empfohlenen Nachfolger von `git filter-branch`:

```bash
git filter-repo --path .env --invert-paths    # .env aus allen Commits entfernen
```

Das schreibt *jeden* Commit ab dem ersten Vorkommen um. Danach müssen alle Branches mit Force gepusht werden (Branch-Schutz vorübergehend lockern), und alle Beteiligten klonen neu. Bei Geheimnissen gilt: zuerst austauschen, dann aufräumen.

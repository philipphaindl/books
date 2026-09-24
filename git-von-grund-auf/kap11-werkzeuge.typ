#import "lib.typ": *

= Tags, Referenzen und Werkzeuge

Dieses Kapitel sammelt, was man nicht täglich, aber regelmäßig braucht: Tags für Versionen, die Kurzschreibweisen für Commits und Bereiche sowie die Werkzeuge, mit denen man in der Historie nach Ursachen sucht.

== Tags

Ein Tag ist ein fester Name für einen Commit, typischerweise für eine veröffentlichte Version. Anders als ein Branch bewegt sich ein Tag nie weiter.

```bash
git tag -a v1.2.0 -m "Version 1.2.0"   # annotierter Tag (empfohlen)
git tag v1.2.0-rc1                     # leichtgewichtiger Tag (nur ein Name)
git tag -a v1.1.1 -m "Hotfix" 3a1f2c0  # nachträglich an einem älteren Commit
git tag                                # alle Tags auflisten
git show v1.2.0                        # Tag mit Commit anzeigen
git push origin v1.2.0                 # einen Tag pushen
git push --follow-tags                 # alle annotierten Tags pushen, die zu gepushten Commits gehören
git tag -d v1.2.0-rc1                  # lokal löschen
git push origin --delete v1.2.0-rc1    # auf dem Server löschen
```

*Annotierte Tags* sind eigene Objekte mit Autor, Datum und Nachricht, *leichtgewichtige* sind nur ein Zeiger. Für Versionen immer annotierte verwenden. `git describe` nutzt sie etwa, um einen Stand wie `v1.2.0-3-g7b9e4d1` zu beschreiben (drei Commits nach v1.2.0).

Tags werden bei einem normalen `git push` *nicht* automatisch übertragen. Das ist eine häufige Stolperfalle, besonders wenn ein Tag eine Pipeline auslösen soll (Kapitel 15). Als Versionsschema hat sich _Semantic Versioning_ durchgesetzt: `MAJOR.MINOR.PATCH`, wobei MAJOR bei inkompatiblen Änderungen, MINOR bei neuen Funktionen und PATCH bei Fehlerbehebungen steigt.

=== Commits und Tags signieren

Eine kryptografische Signatur belegt, dass ein Commit oder Tag mit einem bestimmten privaten Schlüssel erzeugt wurde. Sie verschlüsselt den Inhalt nicht und ersetzt kein Review, erschwert aber das Unterschieben fremder Releases. Git kann dafür neben OpenPGP auch SSH-Schlüssel verwenden. Sinnvoll ist ein eigener Signaturschlüssel statt des Anmeldeschlüssels:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_git_signing -C "git-signing"
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519_git_signing.pub
git config --global commit.gpgSign true
git config --global tag.gpgSign true
```

Den öffentlichen Schlüssel hinterlegst du in Gitea als Signaturschlüssel. Danach kennzeichnet Gitea passende Commits und annotierte Tags als verifiziert. Lokal benötigt `git verify-commit <hash>` beziehungsweise `git verify-tag <tag>` zusätzlich eine `gpg.ssh.allowedSignersFile`, die vertrauenswürdige Identitäten ihren öffentlichen Schlüsseln zuordnet. Signiere insbesondere Release-Tags; schütze die entsprechenden Tag-Muster zusätzlich serverseitig.

== Commits benennen

Fast jeder Befehl akzeptiert statt eines Hashes auch einen relativen Ausdruck:

#table(columns: (auto, 1fr),
  [Ausdruck], [Bedeutung],
  [`a1b2c3d`], [Commit über (eindeutigen) Hash-Anfang],
  [`HEAD`], [der aktuelle Commit],
  [`HEAD~1`, `HEAD~3`], [ein bzw. drei Schritte zurück, immer über das *erste* Elternteil],
  [`HEAD^`], [das erste Elternteil (gleich `HEAD~1`)],
  [`HEAD^2`], [das *zweite* Elternteil, nur bei Merge-Commits sinnvoll],
  [`main@{u}`, `@{u}`], [der Upstream des Branches (z.B. `origin/main`)],
  [`main@{yesterday}`], [wo `main` gestern stand (aus dem Reflog)],
  [`HEAD@{2}`], [die vorletzte Position von `HEAD` (Reflog)],
  [`:/Login`], [der jüngste Commit, dessen Nachricht "Login" enthält],
)

#figure(
  gitgraph(chain(("a","b","c"), ("A","B","C")) + chain(("d","e"), ("D","E"), y: -1, x0: 1.3, color: c-accent, first-parent: "a")
    + ((id: "m", x: 3.9, y: 0, label: "M", parents: ("c", "e"), color: c-blue),),
    refs: ((name: "HEAD", to: "m", kind: "head"),),
    notes: ((pos: (2.6, 0.55), body: [`HEAD~1` = `HEAD^`]), (pos: (1.3, 0.55), body: [`HEAD~2`]), (pos: (2.6, -1.55), body: [`HEAD^2`]), (pos: (1.3, -1.55), body: [`HEAD^2~1`])), unit: 1.1cm),
  caption: [`~` geht entlang der ersten Eltern zurück, `^2` wählt beim Merge die zweite Linie.],
)

== Bereiche: zwei und drei Punkte

Viele Fragen an die Historie lauten "Was hat der eine Branch, was der andere nicht hat?". Dafür gibt es zwei Schreibweisen, deren Unterschied man einmal verstanden haben sollte:

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 10pt,
    align(center)[#text(size: 7.5pt, weight: "bold")[`main..feature`] \
      #gitgraph(chain(("a","b","e","f"), ("A","B","E","F"), dx: 1.15).map(x => x + (color: luma(190))) + chain(("c","d"), ("C","D"), y: -0.95, x0: 2.3, dx: 1.15, color: c-accent, first-parent: "b"), refs: ((name: "main", to: "f", dir: "right", dist: 0.95), (name: "feature", to: "d", dir: "right", dist: 1.1, color: c-accent)), unit: 0.9cm) \
      #text(size: 7.5pt)[nur `C`, `D`: was `feature` hat und `main` nicht]],
    align(center)[#text(size: 7.5pt, weight: "bold")[`main...feature`] \
      #gitgraph(chain(("a","b"), ("A","B"), dx: 1.15).map(x => x + (color: luma(190))) + chain(("e","f"), ("E","F"), x0: 2.3, dx: 1.15, color: c-blue, first-parent: "b") + chain(("c","d"), ("C","D"), y: -0.95, x0: 2.3, dx: 1.15, color: c-accent, first-parent: "b"), refs: ((name: "main", to: "f", dir: "right", dist: 0.95), (name: "feature", to: "d", dir: "right", dist: 1.1, color: c-accent)), unit: 0.9cm) \
      #text(size: 7.5pt)[`C`, `D`, `E`, `F`: was jeweils nur eine Seite hat]],
  ),
  caption: [Zwei Punkte: Differenz. Drei Punkte: symmetrische Differenz seit der Merge-Basis.],
)

```bash
git log main..feature          # Commits, die in den PR gehen würden
git log feature..main          # Commits, die main inzwischen neu hat
git log @{u}..                 # meine noch nicht gepushten Commits
git diff main...feature        # nur die Änderungen des Features seit dem Abzweigen
```

Achtung, bei `git diff` ist die Bedeutung leicht verschoben: `git diff main...feature` vergleicht die Merge-Basis mit `feature` und zeigt damit genau das, was ein Pull Request in Gitea als Änderungen anzeigt. `git diff main feature` vergleicht dagegen die beiden Enden direkt und enthält auch die Änderungen, die nur in `main` passiert sind.

== Suchen in der Historie

```bash
git log -S "max_retries"          # Commits, die das Vorkommen dieses Textes verändert haben
git log -G "retr(y|ies)"          # dasselbe mit regulärem Ausdruck
git log --grep="Login" -i         # in Commit-Nachrichten suchen
git grep "TODO" v1.2.0            # im Dateistand eines beliebigen Commits suchen
```

Die Suche mit `-S` (_pickaxe_) ist besonders nützlich für die Frage "Wann ist diese Funktion verschwunden?". Sie findet genau die Commits, in denen der Text hinzugefügt oder entfernt wurde.

=== `blame`: Wer hat diese Zeile zuletzt geändert?

```bash
git blame src/login.py              # jede Zeile mit Commit, Autor und Datum
git blame -L 40,60 src/login.py     # nur Zeilen 40 bis 60
git blame -w -C src/login.py        # Leerzeichen ignorieren, verschobenen Code erkennen
```

`blame` beantwortet nicht "wer ist schuld", sondern "in welchem Zusammenhang entstand diese Zeile". Mit dem gefundenen Hash führt `git show` zur Commit-Nachricht und damit oft zum Warum. Reine Formatierungs-Commits (etwa nach Einführung eines Formatierers) verstellen den Blick. Trägt man ihre Hashes in eine Datei `.git-blame-ignore-revs` ein und setzt `git config blame.ignoreRevsFile .git-blame-ignore-revs`, überspringt `blame` sie.

== `bisect`: den schuldigen Commit finden

Ein Fehler ist da, vor zwei Wochen war er es noch nicht, dazwischen liegen 80 Commits. `git bisect` findet den verursachenden Commit per binärer Suche in etwa sieben Schritten:

```bash
git bisect start
git bisect bad                    # der aktuelle Stand ist fehlerhaft
git bisect good v1.1.0            # dieser Stand war in Ordnung
# Git checkt einen Commit in der Mitte aus. Testen, dann:
git bisect good                   # oder: git bisect bad
# ... wiederholen, bis Git meldet: "a1b2c3d is the first bad commit"
git bisect reset                  # zurück zum Ausgangspunkt
```

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    for i in range(16) {
      let x = i * 0.9
      let col = if i < 11 { c-gitea } else { c-red }
      let col = if i == 11 { c-yellow } else { col }
      circle((x, 0), radius: 0.2, fill: col.lighten(20%), stroke: col.darken(20%) + 0.6pt)
    }
    let step(x1, x2, y, lab) = {
      line((x1 * 0.9, y), (x2 * 0.9, y), stroke: (paint: c-grey.darken(10%), thickness: 0.8pt), mark: (start: "|", end: "|", scale: 0.5))
      content(((x1 + x2) * 0.45, y - 0.22), text(size: 6.5pt, fill: c-grey.darken(20%), lab))
    }
    step(0, 15, -0.55, [Schritt 1: Mitte testen])
    step(8, 15, -1.1, [Schritt 2])
    step(8, 11, -1.65, [Schritt 3])
    step(10, 11, -2.2, [Schritt 4 -> gefunden])
    content((0, 0.45), text(size: 6.8pt, fill: c-gitea)[good])
    content((13.5, 0.45), text(size: 6.8pt, fill: c-red)[bad])
    content((9.9, 0.45), text(size: 6.8pt, weight: "bold", fill: c-yellow.darken(20%))[erster schlechter])
  }),
  caption: [Jeder Schritt halbiert den Suchbereich. 1000 Commits brauchen höchstens zehn Tests.],
)

Lässt sich der Test automatisieren, erledigt Git die ganze Suche selbst: `git bisect run make test` führt den Befehl an jedem Kandidaten aus und wertet den Rückgabewert aus (0 = gut, sonst schlecht). Das funktioniert umso besser, je kleiner und in sich funktionsfähiger die einzelnen Commits sind. Das ist ein handfester Grund für die sauberen Commits aus Kapitel 3.

== Kleine Helfer

#table(columns: (auto, 1fr),
  [Befehl], [Wirkung],
  [`git shortlog -sn`], [Anzahl der Commits pro Autor],
  [`git describe --tags`], [lesbare Versionsbezeichnung für den aktuellen Stand],
  [`git archive -o demo.zip HEAD`], [Projektstand ohne `.git` als ZIP exportieren],
  [`git show HEAD~5:src/app.py`], [eine Datei in einem alten Stand ausgeben],
  [`git log --oneline --first-parent main`], [nur die Hauptlinie: ein Eintrag pro gemergtem Feature],
  [`git count-objects -vH`], [Größe des Repositories],
  [`git maintenance start`], [regelmäßige Hintergrundoptimierung für große Repositories einrichten],
)

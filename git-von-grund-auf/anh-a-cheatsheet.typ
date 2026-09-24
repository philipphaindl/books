#import "lib.typ": *

#set page(margin: (x: 1.7cm, top: 2.2cm, bottom: 1.9cm))
= Befehlsübersicht

#let blk(titel, ..rows) = block(breakable: false, below: 0.75em, width: 100%)[
  #text(size: 8pt, weight: "bold", fill: c-accent, upper(titel))
  #v(-0.45em)
  #set text(size: 7.4pt)
  #show table: set text(size: 7.4pt)
  #show raw: it => text(font: "JetBrains Mono", size: 6.7pt, fill: rgb("#2a2d33"), ligatures: false, features: (calt: 0), it.text)
  #show table.cell.where(y: 0): set text(weight: "regular")
  #table(columns: (1.35fr, 1fr), inset: (x: 3pt, y: 2.1pt),
    fill: (x, y) => if x == 0 { luma(246) } else { none },
    stroke: (x, y) => (bottom: 0.4pt + luma(222)),
    ..rows.pos().map(r => (r.at(0), r.at(1))).flatten())
]

#columns(2, gutter: 14pt)[
#blk("Einrichten",
  ([`git config --global user.name "…"`], [Name setzen]),
  ([`git config --list --show-origin`], [alle Einstellungen mit Herkunft]),
  ([`ssh-keygen -t ed25519`], [SSH-Schlüssel erzeugen]),
  ([`ssh -T gitea`], [SSH-Verbindung testen]),
  ([`git init` / `git clone url`], [Repository anlegen / klonen]),
)
#blk("Alltag",
  ([`git status -sb`], [Zustand kompakt]),
  ([`git add -p`], [stückweise vormerken]),
  ([`git diff` / `--staged`], [unvorgemerkt / vorgemerkt]),
  ([`git commit -m "…"`], [committen]),
  ([`git log --oneline --graph --all`], [Graph aller Branches]),
  ([`git show <commit>`], [einen Commit ansehen]),
  ([`git restore --staged datei`], [Vormerkung aufheben]),
  ([`git rm --cached datei`], [nicht mehr versionieren]),
)
#blk("Branches",
  ([`git switch -c name`], [anlegen und wechseln]),
  ([`git switch -`], [zum vorherigen Branch]),
  ([`git branch -vv`], [Branches mit Upstream]),
  ([`git branch -d` / `-D name`], [löschen / erzwingen]),
  ([`git branch -m neu`], [aktuellen umbenennen]),
  ([`git branch --merged`], [bereits integrierte Branches]),
)
#blk("Remotes",
  ([`git fetch --prune`], [Server-Stand holen, aufräumen]),
  ([`git pull` (rebase)], [holen und eigene Commits obenauf]),
  ([`git push -u origin name`], [erster Push mit Upstream]),
  ([`git push --force-with-lease`], [umgeschriebenen Branch pushen]),
  ([`git push origin --delete name`], [Remote-Branch löschen]),
  ([`git log @{u}..`], [noch nicht gepushte Commits]),
)
#blk("Mergen und Rebase",
  ([`git merge name`], [in aktuellen Branch mergen]),
  ([`git merge --no-ff` / `--squash`], [Merge-Commit / Squash]),
  ([`git merge --abort`], [Merge abbrechen]),
  ([`git rebase main`], [Branch auf main setzen]),
  ([`git rebase -i main`], [Commits umbauen]),
  ([`git rebase --onto neu alt branch`], [Branch umhängen]),
  ([`git rebase --continue` / `--abort`], [weiter / abbrechen]),
  ([`git checkout --ours datei`], [Konflikt: unsere Seite]),
)
#blk("Commits ändern",
  ([`git commit --amend`], [letzte Nachricht ändern]),
  ([`git commit --amend --no-edit`], [Datei nachreichen]),
  ([`git rebase -i HEAD~n` + `reword`], [ältere Nachricht ändern]),
  ([`git commit --fixup=<hash>`], [Korrektur markieren]),
  ([`git rebase -i --autosquash main`], [Fixups einfalten]),
  ([`git commit --amend --reset-author`], [Autor korrigieren]),
)
#blk("Rückgängig und Rettung",
  ([`git restore datei`], [Änderungen verwerfen (!)]),
  ([`git reset --soft HEAD~1`], [Commit auflösen, Änderungen behalten]),
  ([`git reset --hard origin/main`], [exakt auf Server-Stand (!)]),
  ([`git revert <hash>`], [Commit sicher umkehren]),
  ([`git revert -m 1 <merge>`], [Merge umkehren]),
  ([`git reflog`], [frühere Positionen von HEAD]),
  ([`git branch rettung <hash>`], [verlorenen Stand sichern]),
  ([`git stash push -u -m "…"`], [beiseitelegen]),
  ([`git stash pop`], [zurückholen]),
  ([`git cherry-pick -x <hash>`], [Commit übernehmen]),
  ([`git cherry -v ziel quelle`], [was schon übernommen ist]),
  ([`git clean -n` / `-fd`], [Probelauf / löschen (!)]),
)
#blk("Worktrees",
  ([`git worktree add ../x -b neu main`], [Worktree mit neuem Branch]),
  ([`git worktree add ../x branch`], [für bestehenden Branch]),
  ([`git worktree list`], [alle anzeigen]),
  ([`git worktree remove ../x`], [entfernen]),
  ([`git worktree prune`], [Reste aufräumen]),
  ([`git config --worktree …`], [Wert nur für diesen Worktree]),
)
#blk("Tags und Suche",
  ([`git tag -a v1.0.0 -m "…"`], [annotierten Tag setzen]),
  ([`git push origin v1.0.0`], [Tag pushen]),
  ([`git tag -s v1.0.0 -m "…"`], [signierten Release-Tag setzen]),
  ([`git log main..feature`], [was feature zusätzlich hat]),
  ([`git log -S "text"`], [wann wurde Text geändert]),
  ([`git blame -L 10,20 datei`], [Herkunft von Zeilen]),
  ([`git bisect start/good/bad`], [fehlerhaften Commit suchen]),
)
#blk("Gitea und CI",
  ([`git fetch origin pull/17/head:pr-17`], [PR lokal holen]),
  ([`.gitea/workflows/*.yml`], [Ort der Workflows]),
  ([`${{ secrets.X }}` / `${{ vars.X }}`], [Secret / Variable]),
  ([`$GITHUB_OUTPUT`], [Ausgaben eines Steps]),
  ([`needs:` / `if:`], [Abhängigkeit / Bedingung]),
  ([`git merge-base --is-ancestor A B`], [prüfen, ob A in B enthalten ist]),
)
]

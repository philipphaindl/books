#import "lib.typ": *

= Gitea und Pull Requests

Gitea ist ein selbst gehosteter Git-Server mit Weboberfläche, vergleichbar mit GitHub oder GitLab, aber schlank genug für einen kleinen Server oder eine NAS. Neben Repositories bietet es Organisationen und Teams, Issues, Pull Requests, eine Paket- und Container-Registry sowie mit _Gitea Actions_ ein CI/CD-System, das mit GitHub Actions weitgehend kompatibel ist (Kapitel 13). Die Angaben in diesem Teil beziehen sich auf Gitea 1.27.3 und Gitea Runner 3.5.

#achtung[Für öffentlich erreichbare Instanzen ist mindestens Gitea 1.27.3 wichtig: Diese Patch-Version schließt mehrere Sicherheitslücken, darunter eine Umgehung der Freigabe für Workflow-Läufe aus erstmaligen Fork-Beiträgen. Sicherheitsupdates von Gitea und Runner zeitnah einspielen und Release Notes vor jedem Upgrade lesen.]

== Ein lokales Projekt mit Gitea verbinden

Für ein bestehendes lokales Projekt legst du in Gitea zuerst ein *leeres* Repository an (über _+ -> Neues Repository_). Wichtig: Dabei keine README, `.gitignore` oder Lizenz erzeugen lassen, sonst haben Server und lokales Projekt zwei unabhängige Anfangscommits und der erste Push schlägt fehl.

```bash
cd ~/projekte/demo
git remote add origin gitea:team/demo.git   # Kurzname aus ~/.ssh/config (Kapitel 2)
git push -u origin main
```

Ist das Repository in Gitea schon mit Inhalt angelegt, klonst du es stattdessen einfach. Organisationen (etwa `team`) bündeln Repositories mehrerer Personen. Rechte vergibst du über Teams in der Organisation, nicht pro Repository und Person.

== Der Branch-basierte Arbeitsablauf

Fast alle modernen Teams arbeiten nach demselben einfachen Muster, oft _GitHub Flow_ oder _trunk-based development_ genannt:

+ `main` ist immer lauffähig und geschützt. Niemand pusht direkt darauf.
+ Jede Änderung beginnt als kurzlebiger Branch von `main`.
+ Über einen *Pull Request* (PR) wird die Änderung zur Integration vorgeschlagen.
+ Die CI prüft automatisch, ein Mensch prüft inhaltlich (Review).
+ Nach dem Mergen wird der Branch gelöscht, `main` wird ausgeliefert.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let steps = (
      ([Branch \ anlegen], white, c-dark),
      ([Commits \ + `push`], white, c-dark),
      ([Pull Request \ öffnen], rgb("#EEF6E6"), c-gitea),
      ([CI-Checks \ + Review], rgb("#FFF8E6"), c-yellow),
      ([Mergen \ (Stil wählen)], rgb("#EEF6E6"), c-gitea),
      ([Branch löschen, \ Deployment], rgb("#EAF1FB"), c-blue),
    )
    for (i, s) in steps.enumerate() {
      let x = i * 2.75
      kasten((x, 0), s.at(0), w: 2.2, h: 1.05, bg: s.at(1), col: s.at(2), size: 7.3pt)
      if i < 5 { pfeil((x + 1.12, 0), (x + 1.62, 0)) }
    }
    line((8.25, -0.55), (8.25, -1.15), (2.75, -1.15), (2.75, -0.55), stroke: (paint: c-accent, thickness: 0.8pt, dash: "dashed"), mark: (end: "stealth", fill: c-accent, scale: 0.5))
    content((5.5, -1.38), text(size: 6.8pt, fill: c-accent, style: "italic")[Anmerkungen -> weitere Commits pushen, der PR aktualisiert sich selbst])
  }),
  caption: [Lebenszyklus eines Pull Requests.],
)

== Einen Pull Request erstellen

```bash
git switch main && git pull
git switch -c feature/42-login-sperre
# ... arbeiten, committen ...
git push                      # mit push.autoSetupRemote genügt das
```
```out
remote:
remote: Create a new pull request for 'feature/42-login-sperre':
remote:   https://gitea.example.com/team/demo/compare/main...feature/42-login-sperre
remote:
```

Gitea gibt beim ersten Push eines Branches direkt den Link zum Anlegen des PRs aus (#key[⌘]-Klick im Terminal öffnet ihn). Alternativ findest du im Repository unter _Pull Requests -> Neuer Pull Request_ die Auswahl von Ziel- und Quell-Branch.

Beim Ausfüllen lohnt sich Sorgfalt, denn Titel und Beschreibung sind die Dokumentation der Änderung:

- *Titel* wie eine gute Commit-Titelzeile. Beim Squash-Merge wird er zur Commit-Nachricht.
- *Beschreibung:* Was ändert sich, warum, wie kann man es testen, was ist bewusst nicht enthalten.
- *Verknüpfung mit Issues:* Schlüsselwörter wie `Closes #42`, `Fixes #42` oder `Resolves #42` in der Beschreibung schließen das Issue automatisch, sobald der PR gemergt wird.
- *Noch nicht fertig?* Beginnt der Titel mit `WIP:` oder `[WIP]`, markiert Gitea den PR als _Work in Progress_ und verhindert das Mergen. So lässt sich früh Feedback einholen.
- Reviewer, Labels und Meilensteine setzt du in der rechten Seitenleiste.

#tipp[Eine Vorlage für PR-Beschreibungen legst du als `.gitea/PULL_REQUEST_TEMPLATE.md` ins Repository. Gitea füllt das Beschreibungsfeld jedes neuen PRs damit vor, etwa mit den Abschnitten _Was_, _Warum_, _Testen_ und einer kleinen Checkliste.]

== Review

Im Tab _Geänderte Dateien_ zeigt Gitea den Diff zwischen Merge-Basis und PR-Branch, also genau `git diff main...feature` aus Kapitel 11. Über das Plus-Symbol neben einer Zeile hinterlässt du einen Kommentar. Statt jeden Kommentar einzeln abzuschicken, sammelst du sie mit _Review beginnen_ und schließt das Review mit einer Entscheidung ab:

#table(columns: (auto, 1fr),
  [Entscheidung], [Bedeutung],
  [_Kommentieren_], [Feedback ohne Urteil.],
  [_Zustimmen_ (Approve)], [Aus Sicht des Reviewers mergebar. Zählt für die geforderte Anzahl an Freigaben.],
  [_Änderungen anfordern_], [Blockiert den Merge, wenn der Branch-Schutz das so vorsieht (siehe unten).],
)

Erledigte Diskussionen markiert man als _aufgelöst_. Bei größeren PRs lohnt es sich, im Diff-Menü die Ansicht auf einzelne Commits umzuschalten oder Leerzeichenänderungen auszublenden.

== Einen Pull Request aktualisieren

Ein PR ist keine Kopie, sondern ein Verweis auf den Branch. Jeder weitere Push auf den Branch aktualisiert den PR automatisch, und die CI läuft erneut. Für Review-Anmerkungen gibt es zwei Stile:

- *Einfach weitere Commits pushen.* Übersichtlich für Reviewer, die Historie wird beim Squash-Merge ohnehin zusammengefasst.
- *Fixup-Commits pushen* (Kapitel 7) und vor dem Mergen mit `git rebase -i --autosquash main` einfalten, dann `git push --force-with-lease`. Empfehlenswert, wenn per Rebase gemergt wird und die Einzelcommits erhalten bleiben sollen.

Ist `main` inzwischen weitergelaufen, zeigt Gitea an, dass der Branch veraltet ist, und bietet _Branch aktualisieren_ an, per Merge oder (falls erlaubt) per Rebase. Lokal erreichst du dasselbe mit `git pull --rebase origin main` und anschließendem `git push --force-with-lease`.

== Mergen: die Gitea-Merge-Stile

Beim Mergen bietet Gitea mehrere Stile an. Sie entsprechen genau den Strategien aus Kapitel 6. Die Tabelle nennt die englischen Originalbeschriftungen, in der deutschen Oberfläche sind sie sinngemäß übersetzt:

#table(columns: (auto, auto, 1fr),
  [Gitea-Schaltfläche], [entspricht], [Ergebnis],
  [_Create merge commit_], [`git merge --no-ff`], [① Merge-Commit, alle Einzelcommits bleiben unverändert],
  [_Rebase then fast-forward_], [`rebase` + `merge --ff-only`], [③ lineare Historie mit allen (neu geschriebenen) Einzelcommits],
  [_Rebase then create merge commit_], [`rebase` + `merge --no-ff`], [④ semi-linear: Einzelcommits plus Klammer],
  [_Create squash commit_], [`merge --squash`], [② ein Commit pro PR, Nachricht im Dialog editierbar],
  [_Fast-forward only_], [`merge --ff-only`], [nur möglich, wenn der Branch schon auf `main` aufsetzt],
  [_Manually merged_], [(lokal erledigt)], [markiert den PR als gemergt, wenn du lokal gemergt und gepusht hast],
)

In den Repository-Einstellungen unter _Pull Requests_ legst du fest, welche Stile erlaubt sind, welcher vorausgewählt ist und ob der Branch nach dem Mergen standardmäßig gelöscht wird. Für die meisten Projekte empfiehlt sich: Squash als Standard, Rebase + Merge-Commit zusätzlich erlaubt, Merge-Commit und Fast-Forward-only abgeschaltet, Branch nach dem Mergen löschen.

Sind die Checks noch nicht durchgelaufen, kannst du den PR über die Option _Automatisch mergen, wenn alle Checks erfolgreich sind_ vormerken. Gitea mergt dann selbstständig, sobald die Pipeline grün ist.

Nach dem Mergen räumst du lokal auf:

```bash
git switch main
git pull
git branch -D feature/42-login-sperre   # -D, weil Squash neue Commits erzeugt (Kapitel 4)
```

== Branch-Schutz

Die wichtigste Einstellung für ein geordnetes Repository findest du unter _Einstellungen -> Branches -> Branch-Schutzregel hinzufügen_. Eine Regel gilt für ein Namensmuster, meist `main`:

#table(columns: (auto, 1fr),
  [Option], [Empfehlung und Wirkung],
  [Push], [_Push deaktivieren_: Änderungen an `main` nur über PRs. Wer allein arbeitet, kann sich selbst in eine Ausnahmeliste eintragen, verliert dann aber die Garantie, dass alles durch die CI lief.],
  [Force-Push], [deaktiviert lassen, damit die Historie von `main` nie umgeschrieben wird],
  [Statusprüfungen], [aktivieren und Muster wie `ci / *` eintragen: Merge nur, wenn die passenden CI-Jobs erfolgreich waren (Kapitel 15)],
  [Erforderliche Freigaben], [z.B. 1: Mindestanzahl an Zustimmungen. Alleine sinnlos, im Team sehr wertvoll.],
  [Veraltete Freigaben verwerfen], [Neue Commits nach einer Freigabe erfordern eine erneute Freigabe.],
  [Bei abgelehnten Reviews blockieren], [Ein _Änderungen angefordert_ verhindert den Merge.],
  [Bei veraltetem Branch blockieren], [Der PR muss erst auf den aktuellen Stand von `main` gebracht werden. Garantiert, dass die CI den tatsächlichen Endzustand geprüft hat.],
  [Geschützte Dateimuster], [z.B. `.gitea/workflows/*`: Änderungen an diesen Dateien nur durch berechtigte Personen.],
)

Schütze zusätzlich Release-Tags, etwa das Muster `v*`, und beschränke das Erzeugen und Löschen auf Release-Verantwortliche. Ein Tag ist sonst nur ein frei verschiebbarer Name und kann — wenn er ein Produktions-Deployment auslöst — den normalen PR-Weg umgehen. Kapitel 15 prüft deshalb zusätzlich technisch, dass ein Release-Tag auf einen Commit aus `main` zeigt.

== Pull Requests lokal auschecken

Gitea stellt jeden PR zusätzlich unter der Referenz `refs/pull/<Nummer>/head` bereit, auch wenn der Branch aus einem Fork stammt. Damit holst du jeden PR mit einem Befehl:

```bash
git fetch origin pull/17/head:pr-17
git switch pr-17                        # oder als Worktree, siehe Kapitel 10
```

Wer das oft macht, kann Git anweisen, alle PRs bei jedem Fetch mitzuholen. Danach heißen sie `origin/pr/17` usw.:

```bash
git config --add remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"
```

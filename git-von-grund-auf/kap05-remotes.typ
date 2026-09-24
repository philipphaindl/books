#import "lib.typ": *

= Remotes: Arbeiten mit dem Server

Bis hierhin lief alles lokal. Git ist ein verteiltes System: Dein Mac hat eine vollständige Kopie des Repositories mit allen Commits, genau wie der Gitea-Server. Remotes sind die Verbindung zwischen diesen Kopien. Dabei gilt ein Grundsatz, der viele Missverständnisse erklärt: *Git spricht nur dann mit dem Server, wenn du es ausdrücklich verlangst*, also bei `clone`, `fetch`, `pull` und `push`. Alles andere, auch `git status`, arbeitet mit dem Wissensstand des letzten Kontakts.

== Remotes verwalten

Ein Remote ist nichts anderes als ein Name für eine URL. Nach `git clone` heißt er `origin`.

```bash
git remote -v                                  # alle Remotes mit URL anzeigen
git remote add origin gitea:team/demo.git      # Remote hinzufügen (nach git init)
git remote set-url origin gitea:team/demo.git  # URL ändern, z.B. nach Umzug des Servers
git remote rename origin gitea                 # umbenennen
git remote remove altes-remote                 # entfernen
```

Mehrere Remotes sind möglich und manchmal nützlich, etwa `origin` für den eigenen Gitea-Server und `github` für einen öffentlichen Spiegel. Ein Push geht immer an genau ein Remote.

== Remote-Tracking-Branches

Neben deinen lokalen Branches verwaltet Git für jedes Remote *Remote-Tracking-Branches* wie `origin/main`. Sie sind deine lokale, schreibgeschützte Erinnerung daran, wo der Branch `main` auf dem Server beim letzten Kontakt stand. Du arbeitest nie direkt auf ihnen. Sie werden nur durch `fetch`, `pull` und `push` aktualisiert.

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 10pt,
    block(stroke: 0.6pt + luma(200), radius: 4pt, inset: 8pt, width: 100%)[
      #text(size: 7.5pt, weight: "bold", fill: c-grey.darken(20%))[DEIN MAC]
      #align(center, gitgraph(chain(("a","b","c"), ("A","B","C")), refs: ((name: "main", to: "c"), (name: "origin/main", to: "b", kind: "remote", dir: "down")), unit: 1cm))],
    block(stroke: 0.6pt + luma(200), radius: 4pt, inset: 8pt, width: 100%)[
      #text(size: 7.5pt, weight: "bold", fill: c-gitea)[GITEA-SERVER]
      #align(center, gitgraph(chain(("a","b"), ("A","B")) + ((id: "d", x: 2.6, y: 0, label: "D", parents: ("b",), color: c-gitea),), refs: ((name: "main", to: "d"),), unit: 1cm))],
  ),
  caption: [Du hast lokal `C` committet, jemand anderes hat inzwischen `D` gepusht. Dein `origin/main` weiß davon noch nichts.],
) <fig-tracking>

In dieser Situation meldet `git status` fröhlich _Your branch is ahead of 'origin/main' by 1 commit_. Das stimmt aber nur gemessen am Stand des letzten Kontakts. Dass der Server weitergelaufen ist, erfährst du erst nach einem `git fetch`.

== fetch, pull und push

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [*Arbeitsverzeichnis*], w: 2.5, h: 0.9, size: 7.5pt)
    kasten((4.4, 0), [lokaler Branch \ `main`], w: 2.5, h: 0.9, bg: rgb("#EAF1FB"), col: c-blue, size: 7.5pt)
    kasten((8.8, 0), [Remote-Tracking \ `origin/main`], w: 2.5, h: 0.9, bg: luma(245), col: c-grey, size: 7.5pt)
    kasten((13.2, 0), [*Gitea-Server* \ `main`], w: 2.5, h: 0.9, bg: rgb("#EEF6E6"), col: c-gitea, size: 7.5pt)
    pfeil((11.95, 0.1), (10.05, 0.1), label: "fetch", loff: (0, 0.2), color: c-gitea)
    pfeil((7.55, 0.1), (5.65, 0.1), label: "merge/rebase", loff: (0, 0.2), color: c-blue)
    line((13.2, 0.45), (13.2, 1.25), (4.4, 1.25), (4.4, 0.47), stroke: (paint: c-teal, thickness: 0.9pt, dash: "dashed"), mark: (end: "stealth", fill: c-teal, scale: 0.6))
    content((8.8, 1.47), text(font: "JetBrains Mono", size: 6.8pt, weight: "bold", fill: c-teal)[git pull = fetch + merge/rebase])
    line((4.4, -0.45), (4.4, -1.2), (13.2, -1.2), (13.2, -0.47), stroke: (paint: c-accent, thickness: 0.9pt), mark: (end: "stealth", fill: c-accent, scale: 0.6))
    content((8.8, -1.42), text(font: "JetBrains Mono", size: 6.8pt, weight: "bold", fill: c-accent)[git push (aktualisiert auch origin/main)])
    pfeil((3.15, 0.1), (1.25, 0.1), label: "switch", loff: (0, 0.2), color: c-grey.darken(20%))
  }),
  caption: [Welcher Befehl was bewegt.],
)

- *`git fetch`* lädt neue Commits vom Server und aktualisiert die Remote-Tracking-Branches. Deine lokalen Branches und dein Arbeitsverzeichnis bleiben unangetastet. `fetch` ist deshalb *immer ungefährlich* und eine gute Gewohnheit, bevor du irgendetwas integrierst.
- *`git pull`* ist `fetch` plus Integration: Der Remote-Stand wird in deinen aktuellen Branch eingearbeitet, je nach Konfiguration per Merge oder Rebase.
- *`git push`* überträgt deine lokalen Commits und verschiebt den Branch auf dem Server. Das gelingt nur, wenn der Server-Branch ein Vorfahre deines lokalen Branches ist, der Server also nichts hat, was dir fehlt.

=== Der Upstream

Jeder lokale Branch kann einen _Upstream_ haben, den Remote-Branch, mit dem er standardmäßig abgeglichen wird. Erst dadurch wissen `git pull`, `git push` und `git status`, womit sie vergleichen sollen. Bei einem neuen Branch setzt man ihn beim ersten Push:

```bash
git push -u origin feature/login   # -u = --set-upstream
git branch -vv                     # zeigt den Upstream jedes Branches
```

Mit der Einstellung `push.autoSetupRemote = true` aus Kapitel 2 genügt ein schlichtes `git push`. In Git-Ausdrücken lässt sich der Upstream als `@{u}` ansprechen: `git log @{u}..` zeigt, welche Commits du noch nicht gepusht hast.

== Wenn der Push abgelehnt wird

Die häufigste Fehlermeldung im Umgang mit Remotes:

```out
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to 'gitea:team/demo.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally.
```

Das ist die Situation aus @fig-tracking: Server und lokaler Branch sind auseinandergelaufen. Die Lösung ist *nicht* `--force`, denn damit würdest du den Commit `D` auf dem Server vernichten. Stattdessen holst du den Server-Stand und setzt deine Arbeit obendrauf:

```bash
git pull --rebase     # mit pull.rebase = true genügt git pull
git push
```

#figure(
  vorher-nachher(
    gitgraph(chain(("a","b","c"), ("A","B","C")) + ((id: "d", x: 2.6, y: -1, label: "D", parents: ("b",), color: c-gitea),),
      refs: ((name: "main", to: "c"), (name: "origin/main", to: "d", kind: "remote", dir: "right", dist: 1.45)), unit: 1cm),
    gitgraph(chain(("a","b","d"), ("A","B","D")) + ((id: "c2", x: 3.9, y: 0, label: "C'", parents: ("d",), color: c-blue), (id: "c", x: 2.6, y: 1, label: "C", parents: ("b",), color: c-blue, ghost: true)),
      refs: ((name: "main", to: "c2", dir: "right", dist: 1.05), (name: "origin/main", to: "d", kind: "remote", dir: "down")), unit: 1cm),
    la: [Nach `git fetch`], lb: [Nach `git pull --rebase`],
  ),
  caption: [Dein Commit `C` wird als `C'` auf `D` gesetzt. Danach ist ein normaler Push möglich.],
)

== `git pull` richtig konfigurieren

Ohne Konfiguration verlangt Git bei auseinandergelaufenen Branches eine Entscheidung; mit `pull.rebase = false` erzeugt `git pull` einen Merge-Commit ("Merge branch 'main' of ..."). Ein solcher Commit kann eine bewusste Zusammenführung dokumentieren, entsteht beim beiläufigen Pull aber oft nur als technisches Nebenprodukt. Zwei sinnvolle Einstellungen gibt es:

#table(columns: (auto, 1fr),
  [Einstellung], [Verhalten bei auseinandergelaufenen Branches],
  [`pull.rebase = true`], [Deine lokalen Commits werden auf den Server-Stand gesetzt. Lineare Historie, empfohlen für die meisten Fälle.],
  [`pull.ff = only`], [`pull` verweigert und du entscheidest selbst, ob du `git rebase` oder `git merge` ausführst. Maximal kontrolliert, etwas umständlicher.],
)

== Aufräumen und Remote-Branches löschen

```bash
git push origin --delete feature/login   # Branch auf dem Server löschen
git fetch --prune                        # verschwundene origin/...-Branches lokal entfernen
git branch -vv | grep ': gone]'          # lokale Branches, deren Upstream gelöscht wurde
```

Gitea kann Branches nach dem Mergen eines Pull Requests automatisch löschen (Kapitel 12). Mit `fetch.prune = true` verschwinden dann auch die zugehörigen `origin/...`-Einträge automatisch beim nächsten Fetch.

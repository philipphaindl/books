#import "lib.typ": *

#set heading(numbering: none)
= Bevor es losgeht

Dieses Handbuch ist für jemanden geschrieben, der Git seit Jahren benutzt, aber vor allem über eine Handvoll auswendig gelernter Befehle: `add`, `commit`, `push`, `pull`, gelegentlich ein Branch. Das funktioniert, bis etwas Unerwartetes passiert: ein Merge-Konflikt, ein abgelehnter Push, eine falsche Commit-Nachricht, die schon auf dem Server liegt, oder eine CI-Pipeline, die rot wird, ohne dass klar ist, warum. Genau an diesen Stellen hilft kein weiterer Befehl, sondern nur ein brauchbares Bild davon, was Git intern tut.

Deshalb beginnt das Buch mit dem mentalen Modell (Kapitel 1). Alles Weitere, vom Mergen über Rebase bis zu Worktrees, ist danach eine Anwendung dieses Modells und lässt sich ohne Auswendiglernen herleiten.

== Aufbau

- *Teil I, Grundlagen:* das Modell hinter Git, die Einrichtung am Mac (Terminal, Homebrew, SSH-Schlüssel, Konfiguration), der tägliche Arbeitsablauf und Branches.
- *Teil II, Zusammenarbeit und Historie:* Remotes, korrektes Mergen mit allen Strategien und Konfliktlösung, Rebase, das nachträgliche Ändern von Commits und Commit-Nachrichten, Rückgängig machen und Rettung, Worktrees sowie Werkzeuge wie `bisect` und `blame`.
- *Teil III, Gitea und CI/CD:* Pull Requests in Gitea, Aufbau einer `ci.yml`, Runner-Betrieb, Secrets, Deployment per SSH und SonarQube, zum Schluss eine komplette Pipeline.
- *Anhang:* Befehlsübersicht zum Nachschlagen und ein Glossar.

== Konventionen

#grid(columns: (1fr, 1fr), column-gutter: 14pt,
[
Befehle zum Eintippen stehen in grauen Kästen:
```bash
git status
```
],
[
Ausgaben von Git sind gestrichelt umrandet:
```out
On branch main
nothing to commit, working tree clean
```
])

In Commit-Graphen ist jeder Kreis ein Commit. *Die Pfeile zeigen immer vom neueren Commit auf seinen Vorgänger* (Elterncommit), weil Git es intern genau so speichert: Ein Commit kennt seine Eltern, aber nicht seine Nachfolger. Die Zeit läuft also von links nach rechts, die Pfeile zeigen nach links.

#align(center, gitgraph(
  chain(("a","b","c"), ("A","B","C")) + chain(("d",), ("D",), y: -1, x0: 2.6, color: c-accent, first-parent: "b"),
  refs: ((name: "main", to: "c", dir: "right", dist: 1.2), (name: "HEAD", to: "main", kind: "head", dir: "up", dist: 0.75),
    (name: "feature", to: "d", dir: "right", dist: 1.3, color: c-accent), (name: "origin/main", to: "b", dir: "up", kind: "remote"), (name: "v1.0", to: "a", kind: "tag")),
))

Beschriftete Kästchen sind Referenzen: #box(fill: rgb("#EAF1FB"), stroke: 0.8pt + c-blue, radius: 3pt, inset: (x: 3pt, y: 1.5pt), text(font: "JetBrains Mono", size: 7pt, weight: "bold", fill: c-blue.darken(30%))[main]) ist ein lokaler Branch, #box(stroke: (paint: c-grey, dash: "dashed", thickness: 0.8pt), radius: 3pt, inset: (x: 3pt, y: 1.5pt), text(font: "JetBrains Mono", size: 7pt, weight: "bold", fill: c-grey.darken(30%))[origin/main]) ein Remote-Tracking-Branch, #box(fill: rgb("#FFF4D6"), stroke: 0.8pt + c-yellow, radius: 3pt, inset: (x: 3pt, y: 1.5pt), text(font: "JetBrains Mono", size: 7pt, weight: "bold", fill: c-yellow.darken(30%))[v1.0]) ein Tag und #box(fill: c-dark, radius: 3pt, inset: (x: 3pt, y: 1.5pt), text(font: "JetBrains Mono", size: 7pt, weight: "bold", fill: white)[HEAD]) zeigt, wo du gerade stehst. Gestrichelte Kreise sind Commits, die nach einer Operation nicht mehr erreichbar sind (aber noch existieren, dazu mehr in Kapitel 9).

Als durchgängiges Beispiel dient ein neutrales Projekt namens `demo`. Die Programmiersprache spielt keine Rolle: Alle Prüf- und Build-Schritte laufen über ein `Makefile` mit den Zielen `make lint`, `make test` und `make build`. So lässt sich jede Pipeline aus diesem Buch auf Python, TypeScript, Swift oder Typst übertragen, indem man nur das Makefile anpasst. Server heißen `gitea.example.com` (Gitea, SSH auf Port 2222), `sonar.example.com` und `app.example.com` (Zielserver für das Deployment).

Jedes Kapitel lässt sich für sich nachschlagen. Wer von vorne liest, sollte die Befehle in einem Wegwerf-Repository mittippen (`mkdir /tmp/spielwiese && cd /tmp/spielwiese && git init`) und nach jedem Schritt `git log --oneline --graph --all` ansehen.

#import "lib.typ": *

= Worktrees: mehrere Branches gleichzeitig

Ein Repository hat normalerweise genau ein Arbeitsverzeichnis, und darin ist genau ein Branch ausgecheckt. Das wird zum Engpass, sobald du mehrere Dinge parallel tun willst. Worktrees lösen dieses Problem elegant und sind, einmal verstanden, eines der nützlichsten und am wenigsten bekannten Werkzeuge von Git.

== Das Problem

Du bist mitten in einem Feature, der Code kompiliert gerade nicht, Dateien sind halb umgebaut. Da kommt eine dringende Anfrage: ein Hotfix auf `main`, oder ein Kollege bittet um ein Review seines Pull Requests, den du lokal ausprobieren willst. Die klassischen Auswege haben alle Nachteile:

- *Stash:* Funktioniert, aber Build-Artefakte, virtuelle Umgebungen und geöffnete Editor-Tabs passen danach nicht mehr zum Code. Und der Stash gerät leicht in Vergessenheit.
- *WIP-Commit:* Ebenfalls möglich, muss aber später wieder aufgeräumt werden, und der Branch-Wechsel ändert trotzdem alle Dateien unter dem laufenden Editor.
- *Zweiter Klon:* Ein komplett unabhängiges Repository mit doppeltem Speicherbedarf, eigenen Remotes und eigenen Branches, die erst über den Server synchronisiert werden müssen.

== Das Konzept

Ein Worktree ist ein *zusätzliches Arbeitsverzeichnis, das an dasselbe Repository angeschlossen ist*. Alle Worktrees teilen sich eine gemeinsame Objektdatenbank und dieselben Branches. Standardmäßig teilen sie auch die Repository-Konfiguration; bei Bedarf kann Git einzelne Werte pro Worktree speichern. Jeder Worktree hat seinen eigenen ausgecheckten Branch, seinen eigenen Index und seine eigenen Dateien.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    rect((-1.9, -1.6), (1.9, 1.6), radius: 0.15, fill: rgb("#EAF1FB"), stroke: (paint: c-blue, thickness: 1pt))
    content((0, 1.25), text(size: 8pt, weight: "bold", fill: c-blue.darken(20%))[gemeinsam in `demo/.git`])
    content((0, 0.05), align(left, text(size: 7.3pt)[• Objekte (alle Commits) \ • Branches und Tags \ • Remotes, Konfiguration \ • Stash, Hooks \ • `worktrees/` (Verwaltung)]))
    let wt(y, pfad, branch, col) = {
      rect((4.2, y - 0.62), (11.2, y + 0.62), radius: 0.12, fill: col.lighten(92%), stroke: (paint: col, thickness: 0.9pt))
      content((4.45, y + 0.28), anchor: "west", text(font: "JetBrains Mono", size: 7.3pt, weight: "bold", pfad))
      content((4.45, y - 0.24), anchor: "west", text(size: 6.8pt, features: (calt: 0))[`HEAD` -> #text(font: "JetBrains Mono", weight: "bold", fill: col.darken(20%), branch), eigener Index, eigene Dateien])
      line((1.95, y * 0.55), (4.15, y), stroke: (paint: c-grey.darken(10%), thickness: 0.8pt, dash: "dashed"))
    }
    wt(1.45, "~/projekte/demo/", "feature/login", c-accent)
    wt(0, "~/projekte/demo-hotfix/", "hotfix/csrf", c-violet)
    wt(-1.45, "~/projekte/demo-review/", "pr-17", c-teal)
    content((11.4, 1.45), anchor: "west", text(size: 6.8pt, fill: c-grey.darken(20%), style: "italic")[Haupt-Worktree])
    content((11.4, -0.72), anchor: "west", text(size: 6.8pt, fill: c-grey.darken(20%), style: "italic")[verknüpfte \ Worktrees])
  }),
  caption: [Ein Repository, drei Arbeitsverzeichnisse. Ein Commit in einem Worktree ist sofort in allen anderen sichtbar.],
)

In einem verknüpften Worktree ist `.git` kein Verzeichnis, sondern eine kleine Textdatei mit dem Verweis auf das Hauptrepository (`gitdir: /Users/.../demo/.git/worktrees/demo-hotfix`). Deshalb kostet ein zusätzlicher Worktree nur den Platz der ausgecheckten Dateien, nicht den der gesamten Historie.

#table(columns: (1fr, 1fr),
  [Gemeinsam für alle Worktrees], [Pro Worktree getrennt],
  [Commits und Objektdatenbank], [ausgecheckter Branch (`HEAD`)],
  [Branches, Tags, Remote-Tracking-Branches], [Index (Staging Area)],
  [Konfiguration (`.git/config`) und standardmäßig Hooks], [Dateien im Arbeitsverzeichnis],
  [Stash, Reflog der Branches], [laufender Merge, Rebase oder Cherry-Pick],
)

== Die Befehle

#table(columns: (auto, 1fr),
  [Befehl], [Wirkung],
  [`git worktree add ../demo-hotfix -b hotfix/csrf main`], [neuen Worktree mit neuem Branch `hotfix/csrf` anlegen, abgezweigt von `main`],
  [`git worktree add ../demo-login feature/login`], [Worktree für einen bestehenden Branch. Existiert der Branch nur auf dem Server, legt Git automatisch einen lokalen Tracking-Branch an.],
  [`git worktree add --detach ../demo-v1 v1.0`], [Worktree auf einem Tag oder Commit, ohne Branch (etwa zum Vergleichen)],
  [`git worktree list`], [alle Worktrees mit Pfad, Commit und Branch],
  [`git worktree remove ../demo-hotfix`], [Worktree entfernen. Verweigert, wenn dort uncommittete Änderungen liegen (`--force` erzwingt es).],
  [`git worktree prune`], [Verwaltungsdaten von Worktrees entfernen, deren Ordner manuell gelöscht wurde],
  [`git worktree move alt neu`], [Worktree-Ordner verschieben],
  [`git worktree lock pfad --reason "..."`], [vor versehentlichem Aufräumen schützen, etwa auf einer externen Platte],
  [`git worktree repair`], [Verknüpfungen reparieren, nachdem Ordner von Hand verschoben wurden],
)

== Beispiel: Hotfix mitten im Feature

```bash
cd ~/projekte/demo                    # hier liegt die halbfertige Arbeit an feature/login
git fetch
git worktree add ../demo-hotfix -b hotfix/csrf origin/main

cd ../demo-hotfix                     # komplett sauberer Stand von main
# ... Fehler beheben, testen ...
git commit -am "CSRF-Token bei Logout prüfen"
git push                              # dann Pull Request in Gitea

cd ../demo                            # zurück, alles wie verlassen
git worktree remove ../demo-hotfix    # nach dem Mergen aufräumen
git branch -d hotfix/csrf
```

Das Feature wurde nie angefasst: kein Stash, kein WIP-Commit, keine geänderten Dateien unter dem offenen Editor.

== Beispiel: Pull Request lokal prüfen

Gitea stellt jeden Pull Request unter einer eigenen Referenz bereit (Kapitel 12). Damit lässt sich ein fremder PR in einem eigenen Worktree ausprobieren, ohne die eigene Arbeit zu unterbrechen:

```bash
git fetch origin pull/17/head:pr-17        # PR Nr. 17 als lokalen Branch pr-17 holen
git worktree add ../demo-review pr-17
cd ../demo-review && make test
```

== Beispiel: parallele Arbeitsstränge mit KI-Agenten

Worktrees passen hervorragend zu Coding-Agenten wie Claude Code. Zwei Agenten im selben Arbeitsverzeichnis würden sich gegenseitig Dateien überschreiben und Tests des jeweils anderen zerschießen. In getrennten Worktrees arbeitet jeder auf seinem eigenen Branch, und du führst die Ergebnisse später über Pull Requests zusammen:

```bash
git worktree add ../demo-agent-a -b agent/export-csv main
git worktree add ../demo-agent-b -b agent/refactor-auth main
# je ein Terminal pro Worktree, dort den Agenten starten
```

== Stolpersteine

- *Ein Branch kann nur in einem Worktree ausgecheckt sein.* Versuchst du es ein zweites Mal, meldet Git _'main' is already used by worktree at ..._. Das ist Absicht, denn zwei Arbeitsverzeichnisse auf demselben Branch würden sich gegenseitig die Grundlage verschieben. Lösung: einen neuen Branch anlegen oder `--detach` verwenden.
- *Unversionierte Dateien werden nicht mitkopiert.* Ein neuer Worktree enthält nur, was in Git ist. `.env`, virtuelle Python-Umgebungen, `node_modules` und Build-Ordner müssen pro Worktree neu angelegt oder kopiert werden. Ein kleines Skript wie `make setup` im Projekt lohnt sich.
- *Ordner nicht einfach löschen.* Wer einen Worktree-Ordner im Finder löscht, hinterlässt Verwaltungsdaten, und der Branch gilt weiterhin als ausgecheckt. `git worktree prune` räumt auf, besser ist gleich `git worktree remove`.
- *Stash und Hooks sind gemeinsam.* Ein `git stash pop` im falschen Worktree holt den Stash eines anderen Arbeitsstrangs. Das ist ein weiterer Grund, in Worktrees lieber zu committen.
- *Konfiguration lässt sich bei Bedarf trennen.* Mit `git config extensions.worktreeConfig true` aktivierst du zusätzliche Konfiguration pro Worktree; danach setzt `git config --worktree <schlüssel> <wert>` einen lokalen Wert. Das ist etwa für `core.sparseCheckout` nützlich. Ältere Git-Versionen, die diese Erweiterung nicht kennen, verweigern den Zugriff auf das Repository.
- *Submodule* sind pro Worktree auszuchecken: `git submodule update --init --recursive`. Ein Worktree mit Submodulen lässt sich nicht mit `git worktree move` verschieben; notfalls verschiebst du ihn manuell und reparierst die Verknüpfung mit `git worktree repair`.

== Eine sinnvolle Ordnerstruktur

Am übersichtlichsten ist es, verknüpfte Worktrees als Geschwister des Hauptordners anzulegen und den Projektnamen voranzustellen: `demo/`, `demo-hotfix/`, `demo-review/`. So bleiben sie im Finder beieinander und landen nicht versehentlich innerhalb des Hauptprojekts (wo sie als unversionierte Dateien in `git status` auftauchen würden).

#table(columns: (auto, 1fr, 1fr, 1fr),
  [], [Stash], [Worktree], [zweiter Klon],
  [Parallel arbeiten], [nein], [ja], [ja],
  [Speicherbedarf], [minimal], [nur Arbeitsdateien], [komplette Historie],
  [Commits sofort überall sichtbar], [ja], [ja], [nein, erst über den Server],
  [Build-Artefakte bleiben erhalten], [nein], [ja], [ja],
  [Geeignet für], [kurze Unterbrechungen], [Hotfix, Review, Agenten, lange Tests], [völlig getrennte Experimente],
)

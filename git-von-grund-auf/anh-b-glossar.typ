#import "lib.typ": *

= Glossar und Quellen

#let begriffe = (
  ([Action], [Wiederverwendbarer Baustein in einem Workflow-Step, eingebunden mit `uses:`, z.B. `actions/checkout`.]),
  ([Artefakt], [Datei, die ein Job hochlädt, damit spätere Jobs oder Menschen sie herunterladen können.]),
  ([Branch], [Verschiebbarer Zeiger auf einen Commit. Wandert bei jedem Commit mit.]),
  ([Branch-Schutz], [Gitea-Regel, die Pushes, Force-Pushes und Merges auf einen Branch an Bedingungen knüpft.]),
  ([Cherry-Pick], [Übernahme der Änderung eines einzelnen Commits als neuer Commit auf einem anderen Branch, typisch für Backports.]),
  ([Commit], [Unveränderlicher Schnappschuss des Projekts mit Verweis auf seine Eltern, Autor und Nachricht.]),
  ([Detached HEAD], [Zustand, in dem `HEAD` direkt auf einen Commit statt auf einen Branch zeigt.]),
  ([Fast-Forward], [Merge ohne neuen Commit: Der Branch-Zeiger wird nur nach vorne geschoben.]),
  ([Fetch], [Neue Commits vom Server holen, ohne eigene Branches zu verändern.]),
  ([Fixup], [Korrektur-Commit, der beim interaktiven Rebase in einen früheren Commit eingefaltet wird.]),
  ([Force-with-lease], [Überschreiben eines Remote-Branches, nur wenn er seit dem letzten Fetch unverändert ist.]),
  ([HEAD], [Zeiger auf den aktuell ausgecheckten Branch (oder Commit).]),
  ([Index], [Staging Area: Entwurf des nächsten Commits zwischen Arbeitsverzeichnis und Repository.]),
  ([Job], [Teil eines Workflows, läuft in einem eigenen Container auf einem Runner.]),
  ([Label], [Name, über den `runs-on` einen passenden Runner und dessen Ausführungsumgebung wählt.]),
  ([Merge-Basis], [Jüngster gemeinsamer Vorfahre zweier Branches.]),
  ([Merge-Commit], [Commit mit zwei (oder mehr) Eltern, entsteht beim Zusammenführen auseinandergelaufener Branches.]),
  ([Pull Request], [Vorschlag in Gitea, einen Branch in einen anderen zu integrieren, mit Review und CI-Prüfung.]),
  ([Quality Gate], [Schwellwerte in SonarQube, an denen eine Analyse als bestanden oder nicht bestanden gilt.]),
  ([Rebase], [Neues Abspielen von Commits auf einer anderen Basis. Erzeugt neue Commits mit neuen Hashes.]),
  ([Reflog], [Lokales Protokoll aller Bewegungen von `HEAD` und Branches, das zentrale Rettungswerkzeug.]),
  ([Remote], [Benannte Verbindung zu einem anderen Repository, meist `origin`.]),
  ([Remote-Tracking-Branch], [Lokale Kopie des zuletzt bekannten Server-Stands, z.B. `origin/main`.]),
  ([Signatur], [Kryptografischer Nachweis, dass ein Commit oder Tag mit einem bestimmten privaten Schlüssel erzeugt wurde; keine Verschlüsselung.]),
  ([Runner], [Programm (`gitea-runner`, früher `act_runner`), das Jobs von Gitea abholt und ausführt.]),
  ([Secret], [Geschützt gespeicherter Wert in Gitea, im Workflow über `secrets.NAME` erreichbar. Die Log-Maskierung ist nur ein zusätzliches Auffangnetz.]),
  ([Squash], [Zusammenfassen mehrerer Commits zu einem einzigen.]),
  ([Stash], [Stapel für vorübergehend beiseitegelegte, uncommittete Änderungen.]),
  ([Step], [Einzelner Schritt in einem Job: Shell-Befehl (`run`) oder Action (`uses`).]),
  ([Tag], [Fester, nicht wandernder Name für einen Commit, meist eine Versionsnummer.]),
  ([Upstream], [Remote-Branch, mit dem ein lokaler Branch standardmäßig abgeglichen wird.]),
  ([Workflow], [YAML-Datei in `.gitea/workflows/`, die beschreibt, wann welche Jobs laufen.]),
  ([Worktree], [Zusätzliches Arbeitsverzeichnis, das an dasselbe Repository angeschlossen ist.]),
)

#set text(size: 8.2pt)
#columns(2, gutter: 16pt)[
  #for (b, d) in begriffe [
    #block(below: 0.5em, breakable: false)[*#b* \ #d]
  ]
]

#v(0.2em)
#heading(level: 2, numbering: none)[Weiterführende Quellen]

- *Pro Git* von Scott Chacon und Ben Straub, frei online und auch auf Deutsch: https://git-scm.com/book/de/v2. Kapitel 3 (Branches) und 10 (Git-Interna) vertiefen die Kapitel 1 und 4 dieses Handbuchs.
- *Offizielle Git-Referenz* mit allen Optionen: https://git-scm.com/docs, lokal über `git help <befehl>`.
- *Gitea-Dokumentation*, insbesondere _Usage -> Actions_ mit dem Vergleich zu GitHub Actions: https://docs.gitea.com
- *Gitea Runner*: README und Beispielkonfigurationen unter https://gitea.com/gitea/runner
- *Gitea Runner 3.x*: Installation, Upgrade-Hinweise und Sicherheitsoptionen unter https://docs.gitea.com/runner/
- *Syntax für Workflows*: Die GitHub-Dokumentation zu _Workflow syntax_ gilt mit den Einschränkungen aus Kapitel 13 auch für Gitea.
- *SonarQube*: https://docs.sonarsource.com, Abschnitt zur CI-Integration mit GitHub Actions.

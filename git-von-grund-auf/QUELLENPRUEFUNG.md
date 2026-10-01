# Quellenprüfung: inhaltliche Änderungen am Text (Stand 2026-10-01)

Beim Einarbeiten der Literaturverweise wurden die Aussagen gegen die Quellen geprüft. Hier stehen alle Stellen, an denen der Text geändert wurde, sowie Aussagen ohne Beleg. Diese Datei gehört nicht zum Buch und kann nach der Durchsicht gelöscht werden.


---

# Teil kap00–kap03

## Bericht A (kap00-vorwort, kap01-modell, kap02-mac, kap03-alltag)

Literatur: `A.yml` mit 63 Einträgen (YAML parst, alle `@key` im Text haben einen Eintrag und umgekehrt; die vier Kapitel kompilieren in einer Testkopie mit der Datei als `bibliography`).

## Inhaltliche Änderungen

1. kap01-modell.typ, Hinweiskasten `#tipp` zu Git 3.0
   - vorher: "Git 3.0, das für Ende 2026 erwartet wird, stellt neue Repositories standardmäßig auf SHA-256 um (64 statt 40 Hex-Zeichen) und nennt den Standard-Branch `main` statt `master`."
   - nachher: "Git 3.0, für das noch kein Veröffentlichungstermin feststeht, soll neue Repositories standardmäßig auf SHA-256 umstellen (64 statt 40 Hex-Zeichen) und den Standard-Branch `main` statt `master` nennen @git-scm-com-docs-breakingchanges."
   - Grund: Die offizielle Doku sagt wörtlich "There is no planned release date for this breaking version yet"; "Ende 2026" ist nur Mailinglisten-/Presse-Erwartung. Außerdem ist die Umstellung noch Plan ("will be changed"), keine Tatsache. Der Satz "Bestehende Repositories funktionieren unverändert weiter" blieb (BreakingChanges: kein Plan, sha1 abzuschaffen).
   - Key: git-scm-com-docs-breakingchanges (ergänzend bestätigt durch git-scm-com-docs-git-init: "currently master, but this will change to main when Git 3.0 is released").

2. kap02-mac.typ, Abschnitt "Der Editor für Commit-Nachrichten"
   - vorher: "Ohne Konfiguration öffnet Git für Commit-Nachrichten und interaktive Rebases den Editor `vim`."
   - nachher: "... den Editor `vi` (am Mac ist das Vim) @git-scm-com-docs-git-var."
   - Grund: Git-Doku: Fallback ist der beim Kompilieren gewählte Editor, "usually vi" (nach GIT_EDITOR, core.editor, VISUAL, EDITOR). Der Zusatz "am Mac ist das Vim" ist eigenes Wissen (macOS `vi` = Vim), nicht durch die Quelle belegt.
   - Key: git-scm-com-docs-git-var.

## Nicht belegt / offen

- kap02: `core.precomposeUnicode` "am Mac automatisch aktiv": Git-Doku nennt nur den Zweck, keinen Standardwert; Verweis steht nur am ersten Teilsatz.
- kap02: Gitea-Menüpfad "Einstellungen -> SSH/GPG-Schlüssel -> Schlüssel hinzufügen": keine offizielle Doku-Seite gefunden.
- kap02: Finder-Tastenkürzel #key[⌘] #key[⇧] #key[.] für versteckte Dateien: keine Apple-Primärquelle abrufbar.
- kap02: Zwei-Schritt-Umbenennung `git mv readme.md tmp.md && ...` bei Groß-/Kleinschreibung: keine Quelle abgerufen; `.DS_Store`-Herkunft (Finder) ebenfalls unbelegt.
- kap02: Ed25519 "aktueller Standard" steht in einem Codeblock-Kommentar (kein Verweis dort möglich); `/opt/homebrew/etc/gitconfig` als Pfad der System-Konfiguration nicht direkt belegt (Git-Doku: `$(prefix)/etc/gitconfig`).
- kap02: "hinkt der offiziellen Version meist einige Releases hinterher" (Apple Git): Quelle (git-scm.com/install/mac) sagt nur allgemein "may not be up to date"; "einige Releases" ist stärker als die Quelle.
- kap02: `diff.algorithm = histogram` "meist verständlichere Diffs bei verschobenen Codeblöcken": Doku beschreibt nur den Algorithmus ("Extends patience algorithm ..."), Qualitätsurteil bleibt Autorenmeinung (Verweis auf diff-options steht trotzdem).
- kap02: Beispielausgabe `git version 2.55.0`: Homebrew-Formel zeigt am 2026-10-01 bereits 2.56.0 (formulae.brew.sh/formula/git); nicht geändert, da Beispielausgabe.
- kap03: In Codeblöcken stehende Aussagen (`git commit -am` nur für bekannte Dateien, `git mv`, `git restore --staged`) haben keinen Verweis im Code; die zugehörigen Quellen (git-commit, git-mv, git-restore) sind nicht im Fließtext verwendet.
- kap03: Titelzeile "ohne Punkt am Ende" und "Trailer `Refs: #42`" (Issue-Verknüpfung in Gitea) nicht direkt belegt; Verweis nur auf git-interpret-trailers für Trailer allgemein.
- kap03: Pfeil-/Tabellenzeile `.env` "lokale Umgebungsvariablen und Geheimnisse", Gitattributes-Bemerkung zu CRLF in Linux-Containern und "blähen jeden Klon dauerhaft auf" (LFS) bewusst ohne bzw. nur mit allgemeinem Verweis (git-lfs.com).
- kap03: Gitea-spezifisch: "Titelzeile erscheint ... in Gitea-Listen" nur über allgemeine Git-Doku (git-commit) belegt.
- Allgemein: Aussagen ohne Verweis, weil Autorenempfehlung/Allgemeinwissen: Terminal-Befehlstabelle (pwd, ls, cd, open ...), iTerm2/Ghostty, vim-Tasten, Passphrasen-/Schlüsselhinweise, Empfehlung `git add -p`-Routine.

---

# Teil kap04–kap07

## Inhaltliche Änderungen

1. kap04-branches.typ, Abschnitt "Branches verwalten", Absatz nach der Tabelle.
   - Vorher: "Beim Löschen eines Branches wird nur der Zeiger entfernt, die Commits bleiben in der Datenbank und sind über das Reflog noch Wochen lang auffindbar (Kapitel 9)."
   - Nachher: "Beim Löschen eines Branches wird nur der Zeiger samt seinem eigenen Reflog entfernt. Die Commits bleiben zunächst in der Datenbank und sind, sofern du sie ausgecheckt hattest, über das Reflog von `HEAD` noch Wochen lang auffindbar (Kapitel 9)."
   - Grund: git-branch: "If the branch currently has a reflog then the reflog will also be deleted." Das Branch-Reflog verschwindet also; auffindbar bleiben die Commits nur über das HEAD-Reflog (Standard 30/90 Tage laut gc.reflogExpire*).
   - Keys: git-scm-com-docs-git-branch, git-scm-com-docs-git-reflog, git-scm-com-docs-git-gc
2. kap04-branches.typ, Abschnitt "Detached HEAD", Satz "Dann zeigt nichts mehr auf die neuen Commits."
   - Nachher ergänzt: "..., und die Garbage Collection kann sie irgendwann entfernen" (laut git-checkout werden unreferenzierte Commits von der GC gelöscht). Ergänzung, keine Korrektur.
   - Key: git-scm-com-docs-git-checkout
3. kap06-merge.typ, Codeblock "Grafische Werkzeuge" (Zeile `mergetool.vscode.cmd`).
   - Vorher: `'code --wait --merge $REMOTE $LOCAL $BASE $MERGED'`
   - Nachher: `'code --wait --merge "$REMOTE" "$LOCAL" "$BASE" "$MERGED"'`
   - Grund: VS-Code-Doku nennt die Variante mit Anführungszeichen; ohne sie bricht der Aufruf bei Pfaden mit Leerzeichen.
   - Key: code-visualstudio-com-docs-sourcecontrol-merge-conflicts

## Nicht belegt / offen

- kap06: "Gitea erlaubt, nicht gewünschte Stile in den Repository-Einstellungen abzuschalten" – keine Doku-Seite gefunden, die das belegt; ohne Verweis. Die vier Strategien selbst sind über die Gitea-API-Doku (rebase = FF, rebase-merge, squash, merge) belegt.
- kap06: "Mit Xcode ist das Apple-Werkzeug FileMerge dabei" – nicht belegt (Apple-man-Page nicht abrufbar). Der opendiff-Teil ist über mergetools/opendiff im Git-Repo belegt.
- kap06: Konfliktfall "eine Seite ändert, die andere löscht" ist über git-status (UD/DU) und Pro Git nur indirekt belegt.
- kap06 Strategiebewertungen (Vor-/Nachteile, Faustregeln "Welche Strategie?", Gleisanlage, "meist der beste Kompromiss"), kap05 "empfohlen für die meisten Fälle", Konflikte-seltener-Absatz (Pre-Commit-Hook, kleine PRs): Meinung/Empfehlung, bewusst ohne Verweis.
- kap05: "Ein Push geht immer an genau ein Remote" und Mehrfach-Remote-Beispiel (Spiegel): nicht belegt, ohne Verweis.
- kap05: Codeblock-Befehle `git push origin --delete` / `git branch -vv | grep ': gone]'` stehen ohne Begleitsatz; kein Verweis gesetzt (Quellen: Pro Git Remote Branches, git-push stünden bereit).
- kap04: Branch-Namenskonventionen (Kleinbuchstaben, Issue-Nummer, Gitea-Gruppierung) sind Empfehlung; Tab-Completion/Gitea-Sortierung nicht belegt.
- Verweise auf Kapitel 2 (Prompt `rebase-i`, Konfigurationswerte) und Kapitel 8–12 bewusst ohne eigene Belege.
- Hinweis: git-pull-Doku nennt `--ff-only` als Standardverhalten bei divergierten Branches, das passt zur Aussage "verlangt eine Entscheidung"; `pull.ff = only` ist damit praktisch der Standard.

---

# Teil kap08–kap11

## Bericht C (kap08-aendern, kap09-rettung, kap10-worktrees, kap11-werkzeuge)

Literaturdatei: C.yml (44 Eintraege, YAML parst, Schluessel im Text == Schluessel in der YAML; die vier Kapitel kompilieren zusammen mit C.yml fehlerfrei).

## Inhaltliche Änderungen

1. kap11-werkzeuge.typ, Abschnitt "Suchen in der Historie" (pickaxe)
   - vorher: "Sie findet genau die Commits, in denen der Text hinzugefügt oder entfernt wurde."
   - nachher: "Sie findet genau die Commits, in denen sich die Anzahl der Vorkommen des Textes geändert hat @git-scm-com-docs-git-log."
   - Grund: -S zählt Vorkommen; Verschieben/Umbauen ohne Änderung der Anzahl wird nicht gefunden, "hinzugefügt oder entfernt" war zu stark/ungenau.
   - Key: git-scm-com-docs-git-log
2. kap11-werkzeuge.typ, Abschnitt bisect, `git bisect run`
   - vorher: "(0 = gut, sonst schlecht)"
   - nachher: "(0 = gut, 1 bis 127 außer 125 = schlecht, 125 = überspringen)"
   - Grund: Laut Doku bedeuten 125 "Commit nicht testbar, überspringen" und Codes über 127 brechen die Suche ab; "sonst schlecht" war falsch.
   - Key: git-scm-com-docs-git-bisect

## Nicht belegt / offen

- kap08: Gitea-Squash-Merge-Dialog "Nachricht frei bearbeitbar" (Tipp-Kasten): in den abrufbaren Gitea-Docs nicht beschrieben, kein Verweis.
- kap08: Commits sind unveränderlich / Verweise auf andere Kapitel, Alias-Empfehlung, Empfehlungen ("Vermeiden", "Mit der Nachricht leben"): Meinung/Allgemeinwissen, ohne Verweis. Uebersichtstabelle am Kapitelanfang bewusst ohne Verweise (wiederholt die belegten Abschnitte).
- kap09: Verhalten bei Cherry-Pick-Duplikaten (Merge ohne Konflikt, Squash-Merge zeigt Diff nicht), "nach Konflikt nicht mehr patch-gleich": nicht direkt in der Doku belegbar, ohne Verweis.
- kap09: `-x`-Vermerk bleibt auch nach gelöstem Konflikt erhalten ("Hier hilft der -x-Vermerk"). Die Doku von git-cherry-pick sagt, der Vermerk werde nur bei Cherry-Picks ohne Konflikte angefügt; ein Test mit Git 2.55.0 zeigt aber, dass er nach `--continue` doch in der Nachricht steht. Text daher nicht geändert, die Konfliktaussage ohne Verweis (Autor bitte entscheiden/ggf. prüfen).
- kap09: Notfall-Tabelle ("Git nennt beim Löschen den letzten Hash (was ...)" -- lokal mit Git 2.55 bestätigt, aber keine Doku-Stelle gefunden; `git rm --cached`, `merge --abort`; Time Machine): ohne Verweis.
- kap09: Reflog-Aufbewahrungsfristen und Reflog-Verhalten belegt; "git reset --hard ORIG_HEAD" nur im Codeblock (kein Verweis).
- kap10: Submodule-Aussage ("pro Worktree auszuchecken", `git submodule update --init --recursive`): nur das Verbot von `worktree move` ist belegt.
- kap10: Pull-Request-Referenz `refs/pull/<n>/head` in Gitea: es gibt keine Seite in docs.gitea.com, die das beschreibt; belegt nur indirekt durch ein Gitea-Issue (github.com/go-gitea/gitea/issues/12074, Fehlermeldung zu refs/pull/594/head). Schwache Quelle.
- kap10: Speicherbedarf-/Eignungsvergleichstabelle am Ende, Empfehlungen (Ordnerstruktur), "Unversionierte Dateien werden nicht mitkopiert": Meinung/Allgemeinwissen, ohne Verweis.
- kap10: Claude-Code-Quelle (code.claude.com/docs/en/common-workflows) belegt nur, dass parallele Sitzungen in Worktrees laufen koennen, nicht die Aussage zu "zwei Agenten im selben Verzeichnis ueberschreiben sich".
- kap11: "Gitea kennzeichnet passende Commits und annotierte Tags als verifiziert": Gitea-Doku (administration/signing) belegt nur die Pruefung von GPG/SSH-Signaturen gegen Schluessel in der Gitea-Datenbank; Tags und der Weg "Signaturschluessel hinterlegen" sind dort nicht beschrieben.
- kap11: "`git diff main...feature` zeigt genau das, was ein Pull Request in Gitea als Aenderungen anzeigt": Gitea-Verhalten nicht belegt (git-diff-Teil belegt).
- kap11: Signatur "verschluesselt nicht / ersetzt kein Review", Empfehlung eines eigenen Signaturschluessels, `ssh-keygen`-Zeile, `git grep`, `git log --grep`: ohne Verweis (git-grep wurde abgerufen, aber nicht zitiert).
- kap11: Caption "1000 Commits brauchen hoechstens zehn Tests" und Bildunterschriften allgemein: bewusst ohne Verweis (bisect-Aussage im Text belegt).
- Hinweis: git-scm.com/docs/git-config wird fuer gpg.*, user.signingKey, commit.gpgSign, tag.gpgSign, blame.ignoreRevsFile, extensions.worktreeConfig zitiert; verifiziert ueber die zugehoerigen Quelldateien (Documentation/config/*.adoc), da die HTML-Seite beim Abruf abgeschnitten war.
- Hinweis: `git push origin refs/notes/*` wird von git-notes (via Abruf) bestaetigt; git-push selbst beschreibt das nicht ausdruecklich.

---

# Teil kap12–kap13

## Bericht D (kap12-gitea-pr.typ, kap13-actions.typ)

54 Einträge in D.yml, YAML parst, Schlüssel im Text und in der YAML stimmen überein. Probekompilation der beiden Kapitel mit D.yml: fehlerfrei.

## Inhaltliche Änderungen

1. kap13-actions.typ, Abschnitt "Unterschiede zu GitHub Actions", Aufzählungspunkt zu concurrency/permissions.
   - Vorher: "`concurrency` und `permissions` werden seit 1.26 unterstützt, `timeout-minutes` und `continue-on-error` seit 1.27."
   - Nachher: "... seit Gitea 1.26 unterstützt, `continue-on-error` seit Gitea 1.27, `timeout-minutes` seit Runner 2.0 (unabhängig von der Gitea-Version)."
   - Grund: `timeout-minutes` ist laut Runner-2.0.0-Release-Notes ein reines Runner-Feature ("Runner-only; no Gitea upgrade required"), nicht an Gitea 1.27 gebunden. Die Gitea-1.27.0-Notes erwähnen `timeout-minutes` nicht.
   - Keys: blog-gitea-com-release-of-1-26-0, blog-gitea-com-release-of-1-27-0, blog-gitea-com-release-of-runner-2-0-0

2. kap12-gitea-pr.typ, Ausgabeblock nach `git push` (Codeblock).
   - Vorher: `remote:   https://gitea.example.com/team/demo/compare/main...feature/42-login-sperre`
   - Nachher: `remote:   https://gitea.example.com/team/demo/pulls/new/feature/42-login-sperre`
   - Grund: Im aktuellen Gitea-Quellcode (main, routers/private/hook_post_receive.go) wird als Link `<repo>/pulls/new/<branch>` ausgegeben, nicht mehr `compare/...`; die Meldungszeile "Create a new pull request for '%s':" stammt aus cmd/hook.go. Der Link ist aus dem Quellcode von main abgeleitet, nicht gegen eine echte 1.27.3-Instanz geprüft.
   - Key: raw-githubusercontent-com-go-gitea-gitea-main-routers-private-hook-post-receive-go

## Nicht belegt / offen

- Runner-Version: Die Releases-Seite von gitea.com/gitea/runner nennt als neueste Version v4.0.1 (30.09.2026). Das Buch führt durchgehend "Gitea Runner 3.5" als Stand. Nicht geändert (Vorgabe im Auftrag), bitte prüfen. Zudem wurde beim Abruf erwähnt, v4.0 bringe u.a. einen eingebauten Checkout und S3-Cache; ob Kapitel 13/14 dadurch veraltet sind, ist ungeklärt.
- kap12: Leeres Repo anlegen, sonst "zwei unabhängige Anfangscommits, erster Push schlägt fehl": nicht belegt.
- kap12: "Beim Squash-Merge wird der Titel zur Commit-Nachricht" und "Nachricht im Dialog editierbar": nicht belegt (Merge-Message-Templates-Seite sagt dazu nichts Eindeutiges).
- kap12: Review-Dialog (Review beginnen, Kommentieren/Zustimmen/Änderungen anfordern, Aufgelöst-Markierung, Commit-weise Ansicht, Leerzeichen ausblenden), Seitenleiste mit Reviewern/Labels/Meilensteinen, Oberflächenpfade (_+ -> Neues Repository_, _Einstellungen -> Branches_): UI-Beschreibung, nur teilweise (Protected-Branches-Doku) belegt.
- kap12: Zuordnung der Button-Beschriftungen (_Rebase then fast-forward_ usw.) zu den Strategien: die API-Doku nennt nur die Werte merge, rebase, rebase-merge, squash, fast-forward-only, manually-merged; die englischen UI-Texte sind nicht direkt belegt. Die Tabelle wurde nicht geändert. Die Beschreibung "Manually merged markiert PR als gemergt" und "Fast-forward only nur möglich, wenn Branch auf main aufsetzt" sind nur durch die API-Doku/git-merge gestützt.
- kap13: "Für die übrigen Statusfunktionen nennt die Gitea-Dokumentation Einschränkungen": in der Vergleichsseite nicht auffindbar, bleibt ohne Verweis (Aussage ggf. prüfen/streichen).
- kap13: "Ältere Versionen ignorieren diese Schlüssel stillschweigend": nur für `continue-on-error` (vor 1.27 "parsed but ignored") belegt, für die übrigen nicht explizit.
- kap13: Artefakte "erscheinen zum Herunterladen in der Oberfläche des Laufs"; `retention-days`: UI-Verhalten in Gitea nicht belegt (upload-artifact-Doku nur für GitHub abgerufen, deshalb ohne Verweis gelassen).
- kap13: Aussagen zum Makefile-Beispielprojekt, die Beispiel-YAMLs und die Hinweise zu `actions/checkout@v4`: Beispielcode, nicht belegt. Die checkout-Seite zeigt inzwischen Version 7; Beispiele mit @v4 sind nicht falsch, aber nicht aktuell.
- kap13: Syntax-/Semantikaussagen zu on/jobs/steps/Kontexten/Ausdrücken sind mit GitHub-Docs belegt (Gitea behauptet Kompatibilität); Gitea-spezifische Abweichungen wurden nicht für jede Einzelaussage gesondert geprüft.
- kap13: "Der Runner ... braucht nur ausgehenden Zugriff auf Gitea": nur indirekt gestützt (Runner pollt Gitea).
- Titel einiger Gitea-Doku-Einträge (Design of Gitea Actions, Quick Start, Permissions, Protected tags, Caching, Labels, Upgrading, Issue and Pull Request templates, Automatically Linked References) und der Blog-Titel zu 1.26.0/1.27.3 sind aus Seitenüberschriften bzw. URL-Mustern abgeleitet, nicht wörtlich aus dem Seitentitel kopiert; bei Bedarf gegenprüfen.
- Autorenangaben: "Gitea Authors" ist Herausgeberangabe, nicht eine auf den Seiten genannte Person.

---

# Teil kap14–kap15

## Bericht E (kap14-runner-deploy.typ, kap15-pipeline.typ)

43 Literatureinträge in E.yml. Testkompilation beider Kapitel mit der Literaturdatei erfolgte ohne Fehler und Warnungen.

## Inhaltliche Änderungen

1. kap14, Abschnitt "Der Runner", Versionsangabe
   - Vorher: "... (Image `gitea/runner`, Stand September 2026 Version 3.5.0). ... sowohl 2.0 als auch 3.0 brachten absichtliche Inkompatibilitäten."
   - Nachher: "... seit der Umbenennung mit Version 1.0.0 heißt er `gitea-runner` (Image `gitea/runner`). Das Buch verwendet Version 3.5.0 vom 14. September 2026; seit dem 24. September gibt es 4.0. ... 2.0, 3.0 und 4.0 brachten absichtliche Inkompatibilitäten ..."
   - Grund: gitea.com/gitea/runner/releases zeigt v4.0.0 (2026-09-24) und v4.0.1 (2026-09-30) als stabil; 3.5.0 (2026-09-14) ist nicht mehr aktuell. v4.0.0 hat Breaking Changes (Cache-Routing, `*` in `valid_volumes` matcht nicht mehr über `/`). Die Pinnung `gitea/runner:3.5.0` im Compose-Beispiel blieb unverändert.
   - Keys: blog-gitea-com-release-of-runner-1-0-0, gitea-com-gitea-runner-releases-tag-v4-0-0, docs-gitea-com-runner-upgrade
2. kap14, Abschnitt "Secrets und Variablen", Namensregeln
   - Vorher: Namen dürfen nur Buchstaben, Ziffern, Unterstriche enthalten, nicht mit Ziffer, `GITEA_`, `GITHUB_` beginnen.
   - Nachher: Zusatz "(bei Variablen zusätzlich nicht mit `CI`)".
   - Grund: Gitea-Doku zu Variablen: "Cannot begin with CI".
   - Keys: docs-gitea-com-usage-actions-actions-variables
3. kap14, SonarQube "Server und Projekt", RAM
   - Vorher: "mindestens 2, besser 4 GB RAM"
   - Nachher: "laut Dokumentation mindestens 4 GB RAM für kleine Installationen"
   - Grund: Sonar-Doku "Server host requirements": 4 GB RAM für eine kleine Installation.
   - Keys: docs-sonarsource-com-sonarqube-community-build-server-installation-server-host-requirements
4. kap14, Ende Abschnitt "Der Sonar-Job", Action-Versionen
   - Vorher: "Die Versionsangaben `@v7` und `@v1` entsprechen der Sonar-Dokumentation von 2026."
   - Nachher: "Die Versionsangaben `@v7` und `@v1` sind die hier verwendeten Hauptversionen; die Scan-Action gibt es inzwischen als `v8` (Stand 30. September 2026: 8.3.0), das die Signaturprüfung des Scanners standardmäßig aktiviert."
   - Grund: Die Releases-Seite zeigt v8.3.0 (30. Sept.), v8.0.0 setzt `skipSignatureVerification` standardmäßig auf false. Dass v7 der Sonar-Doku "von 2026" entspricht, war nicht belegbar. Die Codeblöcke (`@v7`) blieben bewusst unverändert; ein Wechsel auf `@v8` wäre eine Entscheidung des Autors.
   - Keys: github-com-sonarsource-sonarqube-scan-action-releases
5. kap14, Abschnitt "Einrichtung mit Docker Compose" (nur Ergänzung)
   - Zusatz: "ein Job mit Zugriff auf den Docker-Socket könnte es [das Registrierungstoken] sonst per `docker inspect` aus dem Runner-Container lesen" als Begründung, das Token zu entfernen.
   - Grund: Gitea-Doku (Install with Docker) nennt genau dieses Risiko.
   - Keys: docs-gitea-com-runner-installation-docker
6. kap14, `#achtung` zum Docker-Socket: Rootless-Einschränkungen konkretisiert um "(Netzwerk, cgroups, Storage-Treiber)". Quelle nennt genau diese. Key: docs-gitea-com-runner-installation-docker
7. kap14, `#achtung` zu Docker-Gruppe: "`--wait` setzt funktionierende healthcheck-Einträge voraus" erweitert zu "`--wait` wartet, bis die Dienste laufen bzw. gesund sind, und setzt für Letzteres ... voraus", da die Compose-Doku "running|healthy" sagt. Key: docs-docker-com-reference-cli-docker-compose-up
8. kap14, Abschnitt "Schritt 3": Zusatz, dass `ssh-keyscan` allein die Echtheit der Schlüssel nicht prüfen kann (Begründung für den Fingerabdruck-Vergleich). Key: man-openbsd-org-ssh-keyscan
9. kap14, Abschnitt "Labels": Satz "Ein Job läuft nur auf einem Runner, der alle Labels aus `runs-on` besitzt" ergänzt (FAQ). Key: docs-gitea-com-usage-actions-faq. Siehe auch offener Punkt zum Zustand "Wartend".
10. kap15, Fehlersuche-Zeile `concurrency`, `timeout-minutes`: ergänzt um die Versionen, "`concurrency` gibt es ab Gitea 1.26, `timeout-minutes` ab Runner 2.0". Keys: blog-gitea-com-release-of-1-26-0, gitea-com-gitea-runner-releases-tag-v2-0-0

(Nummern 5 bis 10 sind Ergänzungen und keine Korrekturen falscher Aussagen; Nr. 1 bis 4 sind echte Korrekturen. Sämtliche Änderungen sind klein und im Fließtext.)

## Nicht belegt / offen

- kap14 Runner-Label-Zustand "Wartend": Die Runner-Doku (docs.gitea.com/runner/labels) schreibt: "If a job's `runs-on` matches none of the runner's labels, the job still runs, in the default `docker.gitea.com/runner-images:ubuntu-latest` image." Das widerspricht scheinbar der Aussage "bleibt dauerhaft im Zustand Wartend" (kap14 Labels, kap15 Fehlersuche "Job bleibt auf Wartend"). Gitea FAQ sagt nur, dass ein Job einen Runner mit allen Labels braucht. Text blieb unverändert, ohne Verweis auf "Wartend"; bitte prüfen, ob die Doku-Aussage nur für einen Runner gilt, der den Job schon angenommen hat.
- kap14 Secrets: "Nach dem Speichern lesbar: nein, nur überschreibbar", "kurzlebiges Token" für `GITEA_TOKEN` und der Alias `secrets.GITHUB_TOKEN` waren in der Gitea-Doku nicht belegbar (Token-Permissions-Seite nennt nur `GITEA_TOKEN`, nichts zu Lebensdauer). Ohne Verweis.
- kap14 Secrets: "Pull Requests aus Forks bekommen keine Secrets": nur Issue-Titel "[Intentional] Secrets are not visible in forks" gefunden, keine Doku-Seite. Ohne Verweis (die Token-Permissions-Seite belegt nur Nur-Lese-Rechte für Fork-PRs).
- kap14 Secrets-Tabelle ("In Logs durch `***` ersetzt"): nur indirekt über Runner v3.0.0 ("Secret masking for encoded forms") belegt, Verweis steht am Maskierungssatz.
- kap14 Runner-Config: Beispielwerte `capacity: 2`, `timeout: 1h` sind keine Standardwerte (Doku: capacity 1, timeout 3h); das Buch nennt sie als Beispiel, Text blieb. `container.network`, `privileged`, `valid_volumes` Defaults stimmen mit der Doku. Die Doku (3.x) nennt für die Konfiguration `gitea-runner generate-config`, die README von v3.5.0 und main nennt `gitea-runner config generate`; das Buch verwendet letzteres (README belegt es).
- kap14: "Zwei parallele Builds können 4 bis 8 GB RAM belegen", Runner-Image "enthält Git, Node.js, Docker-CLI, Build-Werkzeuge", `docker` in Gruppe/sudo-Alternative, `chmod 755`, `flock`/`deploy.sh`-Logik, `Project Analysis Token`/"Create Project -> Local project" in der Sonar-UI, Beispielwerte in `sonar-project.properties` (Keys wurden nur als Codeblock belassen): bewusst ohne Verweis (Praxisrat, Eigenleistung oder keine abrufbare Quelle).
- kap14 Sonar: "Security Hotspots" werden laut Sonar-Glossar als deprecated geführt und auslaufend; Buch nennt sie weiterhin (Text nicht geändert). Quality-Gate-Action `@v1`: Releases-Seite zeigt v1.2.1 als jüngste, ein bewegliches `v1`-Tag war nicht prüfbar.
- kap15: "Create squash commit" (Gitea-Merge-Schaltfläche) in Codeblock-Kommentar, `git commit --fixup=HEAD`, `git tag -s` im Codeblock: nicht verwiesen (Codeblöcke). Doppelte Auslösung bei `push` plus `pull_request`: Eigenbeobachtung, ohne Verweis.

---

# Teil kap16–kap17

## Bericht F (kap16-renovate.typ, kap17-ci-governance.typ)

## Inhaltliche Änderungen

Keine. Kein Codeblock und kein Fließtext wurde inhaltlich geändert, es wurden nur `@schluessel`-Verweise ergänzt.
(Beide Kapitel kompilieren mit F.yml als Literatur ohne Fehler, alle 37 Schlüssel lösen auf.)

## Nicht belegt / offen

Hinweise zur Aktualität (kein Eingriff in den Text):
- Gitea 28.0.0 wurde laut blog.gitea.com/release-of-28.0.0/ am 30.09.2026 veröffentlicht (Versionsschema ohne "1."); das Buch nennt als Stand 1. Oktober 1.27.3. Das widerspricht der Vorgabe im PROMPT, daher unverändert; ggf. Versionshinweis im Vorwort prüfen. Gitea 28 bringt außerdem Deploy Tokens (HTTPS) als Gegenstück zu SSH-Deploy-Keys und Bot-Konten (Kap. 17, Abschnitt Deploy Keys).
- kap17 "Gitea 1.27.3 schließt eine konkrete Umgehung ...": belegt durch Release-Blog 1.27.3 (CVE-2026-66877/-71184). Die ältere Lücke CVE-2026-58424 wurde bereits in 1.26.3 behoben; die Aussage "ältere 1.27-Versionen" ist durch den 1.27.3-Blog gedeckt.

Bewusst ohne Verweis bzw. nicht belegbar:
- kap16: Cron-Ausdruck `schedule` in `renovate.json` (`* 20-23,0-5 * * 1-5`) und `minimumReleaseAge: "7 days"` als konkrete Werte nicht einzeln geprüft (Doku nennt nur Beispiele wie "90 days").
- kap16: Image-Tag `renovate/renovate:44.115.2`: GitHub-Release existiert (25.09.2026), Docker-Hub-Tag selbst nicht abgerufen.
- kap16: `renovate-config-validator` im Image enthalten, `${{ gitea.workspace }}`, `timeout-minutes`, `container:`, `workflow_dispatch` in Gitea Actions: nicht einzeln gegen Gitea-Doku belegt (Comparison-Seite erwähnt sie nicht).
- kap16: Empfehlungen (mehrere Bot-Konten, Secret nur im Automatisierungs-Repo, Automerge-Strategie, Hostrules aus Umgebungsvariablen) sind Autorenmeinung.
- kap17: Aussagen über Semgrep-Baseline/Ausnahmen mit Ablaufdatum, flaky Tests, `curl | sh`, "zwei Werkzeuge erhöhen Rauschen", Zielarchitektur-Tabelle: Autorenempfehlung.
- kap17: Sonar "Blocker-/Critical-Befunde" im Quality Gate: Sonar way verlangt "keine neuen Issues"; der Verweis stützt nur den Grundsatz "Quality Gate auf neuen Code". "Community Build analysiert nur den Hauptbranch" ist nur indirekt belegt (Sonar-Blog: Community Build hat keine Branch-/PR-Analyse); eine explizite Doku-Zeile "nur main" ließ sich nicht abrufen.
- kap17: Semgrep `--config auto` kontaktiert die Registry und sendet ggf. Metriken (CLI-Referenz: `--metrics auto`); der Text deckt das über den Absatz zu "vertraulich/offline" ab, unverändert.
- kap17: `docker inspect ... RepoDigests`, `docker push` liefert Digest, `GITHUB_SHA`/`GITHUB_OUTPUT`/`needs.build.outputs` in Gitea: nicht belegt (Codeblock bzw. nicht in Doku gefunden).
- kap17: "Deploy Key standardmäßig nur lesend": nur durch das Gitea-Template (Checkbox `is_writable` ohne `checked`, Branch main = 28/29-dev) belegt, keine Doku-Textstelle gefunden.
- kap17: Scoped Workflows: Doku-Seite existiert auch unter 1.27.3 (docs.gitea.com/1.27/...), Einführung in 1.27.0 laut Websuche.
- kap17: Cron-Zeitzone UTC (kap16-Kommentar im Workflow, nur Codeblock): Gitea-Quellcode `schedule_spec.go` setzt UTC als Default; als Verweis im Fließtext bei `schedule` gesetzt.
- Hinweis zur Zentralisierung: Trivy-Schlüssel in F.yml folgen der abgerufenen URL `trivy.dev/latest/docs/...` (`trivy-dev-latest-docs-...`); das Docker-Buch nutzt `trivy.dev/docs/latest/...` (`trivy-dev-docs-latest-...`). Gleiche Schlüssel für Docker-Buch-Überschneidungen (docs-docker-com-build-building-best-practices, docs-docker-com-reference-cli-docker-buildx-build, docs-renovatebot-com-docker, docs-github-com-en-actions-reference-security-secure-use, man-openbsd-org-sshd-8, cheatsheetseries-owasp-org-...) sind identisch benannt.

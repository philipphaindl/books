#import "lib.typ": *

= Git am Mac einrichten

Bevor es um Git selbst geht, lohnt sich eine halbe Stunde für eine saubere Grundausstattung: ein aktuelles Git über Homebrew, eine durchdachte globale Konfiguration, SSH-Schlüssel mit Schlüsselbund-Anbindung und eine Shell, die den aktuellen Branch anzeigt. Das spart später viele kleine Irritationen.

== Terminal-Grundlagen in fünf Minuten

Das Terminal (`Programme -> Dienstprogramme -> Terminal`, oder schneller über #key[⌘] #key[Leertaste] und "Terminal") startet seit macOS Catalina standardmäßig die Shell *zsh*. Alternativen wie iTerm2 oder Ghostty funktionieren genauso. Die wichtigsten Befehle zum Navigieren:

#table(columns: (auto, 1fr),
  [Befehl], [Bedeutung],
  [`pwd`], [Zeigt das aktuelle Verzeichnis (_print working directory_).],
  [`ls -la`], [Listet alle Dateien, auch versteckte wie `.git` oder `.gitignore`, mit Details.],
  [`cd projekte/demo`], [Wechselt in ein Verzeichnis. `cd ..` geht eine Ebene hoch, `cd -` zurück zum vorherigen, `cd` allein ins Home-Verzeichnis `~`.],
  [`mkdir -p a/b/c`], [Legt Verzeichnisse an, inklusive fehlender Zwischenebenen.],
  [`open .`], [Öffnet das aktuelle Verzeichnis im Finder. `open datei.pdf` öffnet mit dem Standardprogramm.],
  [`cat`, `less`], [Datei ausgeben bzw. seitenweise anzeigen.],
  [`code .`], [Öffnet das Verzeichnis in VS Code (wenn der Befehl installiert ist, siehe unten).],
)

Zwei Dinge sparen im Alltag am meisten Zeit: Die #key[Tab]-Taste vervollständigt Pfade, Befehle und bei Git sogar Branch-Namen. Mit #key[↑] holst du frühere Befehle zurück, mit #key[ctrl] #key[R] durchsuchst du die gesamte Befehlshistorie.

=== Der Pager: Warum `git log` "hängen bleibt"

Längere Ausgaben wie `git log` oder `git diff` zeigt Git im Programm `less` an. Das wirkt beim ersten Mal wie ein Hänger, ist aber ein Betrachter mit eigenen Tasten:

#table(columns: (auto, 1fr, auto, 1fr),
  [Taste], [Wirkung], [Taste], [Wirkung],
  [#key[Leertaste]], [eine Seite weiter], [#key[b]], [eine Seite zurück],
  [#key[/] Text], [vorwärts suchen], [#key[n]], [nächster Treffer],
  [#key[g] / #key[G]], [Anfang / Ende], [#key[q]], [*beenden*],
)

Hilfe gibt es auf zwei Stufen: `git log -h` zeigt eine kurze Optionsübersicht im Terminal, `git help log` öffnet die vollständige Handbuchseite.

== Git installieren

macOS bringt kein vollwertiges Git mit. Beim ersten Aufruf von `git` bietet das System die Installation der _Xcode Command Line Tools_ an, die ein von Apple gepflegtes Git enthalten. Das funktioniert, hinkt aber der offiziellen Version meist einige Releases hinterher. Empfehlenswert ist Git über Homebrew, den Paketmanager für macOS:

```bash
# 1. Homebrew installieren (einmalig; Befehl von brew.sh)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Homebrew in die Shell einbinden (Apple Silicon; der Installer zeigt den Befehl an)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# 3. Git installieren und prüfen
brew install git
which -a git
git --version
```
```out
/opt/homebrew/bin/git
/usr/bin/git
git version 2.55.0
```

`which -a` zeigt alle gefundenen Git-Programme in der Reihenfolge, in der die Shell sie sucht. Steht `/opt/homebrew/bin/git` oben, wird das Homebrew-Git verwendet. Aktualisieren lässt es sich jederzeit mit `brew upgrade git`.

== Die Konfiguration

Git liest Einstellungen aus drei Ebenen, wobei die spezifischere gewinnt:

#table(columns: (auto, auto, 1fr),
  [Ebene], [Datei], [Gilt für],
  [`--system`], [`/opt/homebrew/etc/gitconfig`], [alle Benutzer des Rechners (selten gebraucht)],
  [`--global`], [`~/.gitconfig`], [alle Repositories deines Benutzers],
  [`--local`], [`.git/config` im Projekt], [nur dieses eine Repository (Standard, wenn nichts angegeben ist)],
)

Mit `git config --list --show-origin` siehst du alle aktiven Werte und aus welcher Datei sie stammen. Das ist die erste Anlaufstelle, wenn sich Git "komisch" verhält. Die folgende Datei ist eine erprobte Grundkonfiguration, jede Zeile ist in der Tabelle darunter erklärt. Du kannst sie direkt als `~/.gitconfig` speichern und Name und E-Mail anpassen.

#datei("~/.gitconfig")[
```ini
[user]
    name = Philipp Haindl
    email = philipp@example.com
[init]
    defaultBranch = main
[core]
    editor = nano
    excludesFile = ~/.config/git/ignore
[pull]
    rebase = true
[push]
    autoSetupRemote = true
[fetch]
    prune = true
[rebase]
    autoStash = true
    autoSquash = true
    updateRefs = true
[merge]
    conflictStyle = zdiff3
[rerere]
    enabled = true
[diff]
    algorithm = histogram
    colorMoved = default
[commit]
    verbose = true
[branch]
    sort = -committerdate
[tag]
    sort = version:refname
[help]
    autocorrect = prompt
[alias]
    st = status -sb
    lg = log --graph --oneline --decorate
    lga = log --graph --oneline --decorate --all
    last = log -1 --stat
    unstage = restore --staged
    amend = commit --amend --no-edit
```
]

#table(columns: (auto, 1fr),
  [Einstellung], [Wirkung],
  [`init.defaultBranch`], [Neue Repositories beginnen mit `main` statt `master`.],
  [`pull.rebase = true`], [`git pull` setzt eigene, noch nicht gepushte Commits auf den neuen Remote-Stand, statt einen Merge-Commit zu erzeugen. Hält die Historie linear (Kapitel 5).],
  [`push.autoSetupRemote`], [Beim ersten `git push` eines neuen Branches wird der Upstream automatisch gesetzt. Kein `-u origin feature` mehr nötig.],
  [`fetch.prune`], [Entfernt lokale `origin/...`-Branches, die auf dem Server gelöscht wurden, etwa nach einem gemergten Pull Request.],
  [`rebase.autoStash`], [Uncommittete Änderungen werden vor einem Rebase automatisch beiseitegelegt und danach wiederhergestellt.],
  [`rebase.autoSquash`], [`fixup!`-Commits werden beim interaktiven Rebase automatisch an die richtige Stelle sortiert (Kapitel 7).],
  [`rebase.updateRefs`], [Beim Rebase aufeinander aufbauender Branches werden die Zwischen-Branches mitverschoben.],
  [`merge.conflictStyle = zdiff3`], [Konfliktmarkierungen zeigen zusätzlich den gemeinsamen Ursprung. Das macht Konflikte deutlich leichter lesbar (Kapitel 6).],
  [`rerere.enabled`], [Git merkt sich, wie du einen Konflikt gelöst hast, und wendet die Lösung beim nächsten identischen Konflikt selbst an.],
  [`diff.algorithm = histogram`], [Liefert bei verschobenen Codeblöcken meist verständlichere Diffs als der Standardalgorithmus.],
  [`commit.verbose`], [Zeigt beim Schreiben der Commit-Nachricht im Editor den Diff darunter an.],
  [`branch.sort`], [`git branch` listet die zuletzt benutzten Branches zuerst.],
  [`help.autocorrect = prompt`], [Bei Tippfehlern wie `git stauts` fragt Git, ob `status` gemeint war.],
)

=== Unterschiedliche Identitäten pro Ordner

Wer beruflich und privat mit verschiedenen E-Mail-Adressen committet, kann die Identität abhängig vom Ordner setzen. Alle Repositories unter `~/work/` bekommen dann automatisch die Arbeitsadresse:

```ini
# in ~/.gitconfig ergänzen
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
```
#datei("~/.gitconfig-work")[
```ini
[user]
    email = philipp.haindl@firma.example
```
]

Prüfen lässt sich das im jeweiligen Repository mit `git config user.email`.

== Der Editor für Commit-Nachrichten

Ohne Konfiguration öffnet Git für Commit-Nachrichten und interaktive Rebases den Editor `vim`. Wer dort unfreiwillig landet: #key[i] schaltet in den Schreibmodus, #key[Esc] zurück, dann `:wq` und #key[⏎] speichert und beendet, `:q!` beendet ohne Speichern (bei einer Commit-Nachricht bricht das den Commit ab). Angenehmer sind:

```bash
git config --global core.editor nano             # einfacher Terminal-Editor
git config --global core.editor "code --wait"    # VS Code
```

Für VS Code muss einmalig der Shell-Befehl `code` installiert werden: In VS Code #key[⌘] #key[⇧] #key[P] drücken und _Shell Command: Install 'code' command in PATH_ wählen. Das `--wait` ist wichtig, damit Git wartet, bis du den Tab schließt. Bei `nano` speichert #key[ctrl] #key[O] und #key[ctrl] #key[X] beendet.

== SSH-Schlüssel einrichten

Für die Verbindung zu Gitea gibt es zwei Wege: HTTPS mit Benutzername und Token oder SSH mit einem Schlüsselpaar. SSH ist bequemer und sicherer, sobald es einmal eingerichtet ist. Der private Schlüssel verlässt deinen Mac nie, auf den Server kommt nur der öffentliche Teil.

```bash
# Schlüsselpaar erzeugen (Ed25519 ist der aktuelle Standard)
ssh-keygen -t ed25519 -C "philipp@macbook"
# Speicherort bestätigen (~/.ssh/id_ed25519) und eine Passphrase vergeben
```

Damit du die Passphrase nicht bei jedem Push eintippen musst, speichert macOS sie im Schlüsselbund. Dazu gehört ein Eintrag in der SSH-Konfiguration, in dem du auch gleich einen Kurznamen für den Gitea-Server anlegen kannst:

#datei("~/.ssh/config")[
```text
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519

# Kurzname für den eigenen Gitea-Server mit SSH auf Port 2222
Host gitea
    HostName gitea.example.com
    Port 2222
    User git
```
]

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519   # Passphrase einmal in den Schlüsselbund
pbcopy < ~/.ssh/id_ed25519.pub                   # öffentlichen Schlüssel in die Zwischenablage
```

In Gitea fügst du den Schlüssel unter _Einstellungen -> SSH/GPG-Schlüssel -> Schlüssel hinzufügen_ ein. Danach testest du die Verbindung:

```bash
ssh -T gitea
```
```out
Hi there, philipp! You've successfully authenticated with the key named MacBook,
but Gitea does not provide shell access.
```

Durch den Kurznamen funktionieren nun Remote-Adressen wie `gitea:team/demo.git`. Ohne Eintrag in `~/.ssh/config` müsste die volle Form mit Port geschrieben werden: `ssh://git@gitea.example.com:2222/team/demo.git`.

#achtung[Den privaten Schlüssel (`id_ed25519` ohne `.pub`) niemals kopieren, hochladen oder in ein Repository legen. Für CI-Deployments erzeugst du später eigene, eingeschränkte Schlüssel (Kapitel 14), statt deinen persönlichen Schlüssel wiederzuverwenden.]

== Globale Ignore-Datei

Manche Dateien entstehen nicht durch das Projekt, sondern durch deinen Rechner, allen voran `.DS_Store`, das der Finder in jedem geöffneten Ordner anlegt. Solche Einträge gehören nicht in die `.gitignore` jedes Projekts, sondern in eine globale Datei:

#datei("~/.config/git/ignore")[
```text
.DS_Store
.AppleDouble
._*
*.swp
*~
```
]

Diese Datei liest Git automatisch. Der Eintrag `core.excludesFile` in der Konfiguration oben macht es nur explizit.

== Branch im Prompt anzeigen

Sehr hilfreich ist es, den aktuellen Branch direkt in der Eingabezeile zu sehen. zsh bringt dafür alles mit. In die Datei `~/.zshrc` eintragen und ein neues Terminalfenster öffnen:

#datei("~/.zshrc")[
```bash
# Tab-Vervollständigung (inklusive Git-Branches)
autoload -Uz compinit && compinit

# Git-Branch im Prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a)'
setopt PROMPT_SUBST
PROMPT='%F{cyan}%~%f%F{yellow}${vcs_info_msg_0_}%f %# '
```
]

Das Ergebnis sieht so aus: `~/projekte/demo (feature/login) %`. Das `actionformats` zeigt zusätzlich an, wenn gerade ein Rebase oder Merge läuft, etwa `(main|rebase-i)`. Wer mehr möchte (Anzeige von uncommitteten Änderungen, Ahead/Behind-Zähler), findet mit _Starship_ (`brew install starship`) einen fertigen, schnellen Prompt.

#mac[
*Groß-/Kleinschreibung:* Das Mac-Dateisystem APFS unterscheidet standardmäßig nicht zwischen `readme.md` und `README.md`, Linux-Server und Git selbst aber schon. Eine reine Umbenennung der Schreibweise ist deshalb heikel. Zuverlässig funktioniert sie in zwei Schritten: `git mv readme.md tmp.md && git mv tmp.md README.md`.

*Versteckte Dateien:* Im Finder blendet #key[⌘] #key[⇧] #key[.] versteckte Dateien wie `.git` und `.gitignore` ein und aus.

*Umlaute in Dateinamen:* macOS speichert Umlaute intern zerlegt (a + Trema), Linux zusammengesetzt. Git gleicht das über `core.precomposeUnicode` aus, das am Mac automatisch aktiv ist. Trotzdem gilt: Dateinamen in Repositories am besten ohne Umlaute und Leerzeichen.
]

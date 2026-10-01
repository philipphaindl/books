# Quellenprüfung: inhaltliche Änderungen am Text (Stand 2026-10-01)

Beim Einarbeiten der Literaturverweise wurden die Aussagen gegen die Quellen geprüft. Hier stehen alle Stellen, an denen der Text geändert wurde, sowie Aussagen ohne Beleg. Diese Datei gehört nicht zum Buch und kann nach der Durchsicht gelöscht werden.

---

# Änderungen Agent Z1 (kap01, kap03, kap04, kap05, kap08)

Nur inhaltliche Textänderungen (ohne reine @key-Einfügungen).

## Inhaltliche Änderungen

1. kap01-modell.typ, "Container sind keine virtuellen Maschinen" (P1)
   - vorher: "Sie braucht Sekunden bis Minuten zum Starten und reserviert Arbeitsspeicher für ein komplettes System. ... Er startet in Millisekunden und braucht nur so viel Speicher wie die Anwendung selbst."
   - nachher: "Sie bootet dafür ein eigenes Betriebssystem und reserviert Arbeitsspeicher für ein komplettes System. ... Er startet deshalb meist deutlich schneller und braucht kaum mehr Speicher als die Anwendung selbst."
   - Grund: Konkrete Zeitangaben nicht belegbar; qualitative Aussage gestützt durch merkel-2014-docker, docs-docker-com-get-started-docker-concepts-the-basics-what-is-a-container.

2. kap03-container.typ, Tabelle Neustart-Richtlinien, Zeile unless-stopped (P9)
   - vorher: "*Empfohlen für Dienste.*"
   - nachher: "*Empfehlung dieses Buchs für Dienste.*"
   - Grund: Docker empfiehlt Restart-Policies nur generell, keine bestimmte Policy; als eigene Buchempfehlung kenntlich gemacht (kein Verweis daneben; Tabelle belegt mit docs-docker-com-engine-containers-start-containers-automatically).

3. kap04-images.typ, Tabelle CMD/Exec-Form (P5)
   - vorher: "Das Programm ist direkt PID 1 und bekommt Signale wie SIGTERM."
   - nachher: "Das Programm ist direkt PID 1 und bekommt Signale wie SIGTERM (als PID 1 muss es SIGTERM allerdings selbst behandeln)."
   - Grund: pid_namespaces(7): Signale erreichen PID 1 nur mit installiertem Handler. Keys: docs-docker-com-reference-dockerfile, man7-org-linux-man-pages-man7-pid-namespaces-7-html.

4. kap04-images.typ, Absatz zu docker stop (P5)
   - vorher: "Bei der Shell-Form kommt das SIGTERM nie bei der Anwendung an: Jeder Stopp dauert zehn Sekunden ..."
   - nachher: "Bei der Shell-Form kommt das SIGTERM in der Regel nicht bei der Anwendung an: Jeder Stopp dauert dann zehn Sekunden ..."
   - Grund: Manche Shells führen einfache Kommandos per exec aus, "nie" ist zu stark. Key: docs-docker-com-reference-dockerfile.

5. kap05-daten.typ, achtung-Kasten PostgreSQL 18 (P3)
   - vorher: "Wer bei `postgres:18` wie gewohnt `/var/lib/postgresql/data` einbindet, bekommt Fehlermeldungen oder Daten, die beim Neuerzeugen verloren gehen."
   - nachher: "... bekommt eine Fehlermeldung; ohne ein Volume auf `/var/lib/postgresql` landen die Daten in einem anonymen Volume, das beim Neuerzeugen verwaist."
   - Grund: Entrypoint seit PR #1372 bricht bei erkanntem /var/lib/postgresql/data-Mountpoint mit Fehlermeldung ab; Datenverlust droht v.a. ohne Volume auf /var/lib/postgresql. Keys: github-com-docker-library-postgres-pull-1372, hub-docker-com-postgres.

6. kap08-gute-images.typ, Tabelle Basis-Image, Zeile alpine (P2)
   - vorher: "Sehr klein, nutzt aber die C-Bibliothek musl. Viele Python-Pakete haben dafür keine fertigen Binärpakete und müssen aufwendig kompiliert werden. Für Python meist nicht die Ersparnis wert."
   - nachher: "Sehr klein, nutzt aber die C-Bibliothek musl statt glibc. Binärpakete (Wheels) müssen dafür als `musllinux` gebaut sein; fehlt eines, wird aus dem Quellcode kompiliert, und Software mit glibc-Annahmen kann sich anders verhalten. Für Python meist nicht die Ersparnis wert."
   - Grund: Pauschalaussage 2026 überzogen (musllinux-Wheels existieren, PEP 656). Keys: hub-docker-com-python, peps-python-org-pep-0656.

7. kap08-gute-images.typ, Aufzählung nach dem Dockerfile, syntax-Direktive (P4)
   - vorher: "Sie ist nötig für die `--mount`-Optionen."
   - nachher: "Die `--mount`-Optionen setzen Dockerfile-Syntax 1.2 oder neuer voraus."
   - Grund: Referenz nennt Mindestsyntax 1.2, Direktive an sich ist nicht zwingend. Key: docs-docker-com-reference-dockerfile.

8. kap08-gute-images.typ, Absatz unter Basis-Image-Tabelle (P8)
   - vorher: "Die Größenangaben sind Größenordnungen."
   - nachher: "Die Größenangaben sind Größenordnungen für entpackte Images (wie `docker image ls` sie zeigt), Docker Hub nennt kleinere, komprimierte Werte."
   - Grund: Hub zeigt komprimierte Größen (laut Recherche python:3.14-slim ca. 43 MB, nicht 150 MB). Ohne Verweis, da keine zitierfähige Primärquelle für die Größen.

## Nicht belegt / offen (ohne Verweis gelassen)

- kap01: "Sie bootet dafür ein eigenes Betriebssystem ... Er startet deshalb meist deutlich schneller" nur qualitativ durch Merkel/Docker-Doku gestützt, Verweis steht am Satz davor; Zeitangaben bewusst entfernt.
- kap01: Gitea-Registry (Kapitel 11) ohne Verweis (Beleg docs-gitea-com-usage-packages-container wurde wegen Quellenanzahl nicht gesetzt; wird in Kapitel 11 belegt).
- kap03: Restart-Tabelle "Empfehlung dieses Buchs" ist Eigenempfehlung; Kommandotabelle `logs`, `top`, `cp`, `port`, `stats`, `rm` ohne Einzelbelege.
- kap04: `docker pull`/`image ls`/`history`/`inspect`/`image rm` ohne Verweis (reine Befehlsübersicht); `docker image rm`-Referenz (docs-docker-com-reference-cli-docker-image-rm) existiert nicht in literatur.yml.
- kap05: praxis-Kasten (UID/GID, root-Dateien, "Am Mac übersetzt virtiofs einen Teil dieser Unterschiede", Volume-Initialisierung) komplett ohne Beleg (P6). Der virtiofs-Satz ist nicht belegbar; Autor sollte ihn prüfen, abschwächen oder streichen.
- kap05: Volume-Pfad-Aussage zu Rootless/VM/anderen Treibern (P7) nicht explizit belegt; Verweis nur am Standardpfad.
- kap05: `-v a:b`-Regel (Beginn mit `.` oder `/` = Bind Mount) gemäß Recherche belegt, aber nicht selbst gegen die run-Referenz geprüft.
- kap08: `PYTHONUNBUFFERED=1` (P10, docs.python.org nicht abrufbar), `UV_LINK_MODE`, `UV_PYTHON_DOWNLOADS`, ARG UV_VERSION/Stand-Datum ohne Verweis.
- kap08: Beispiel `python:3.14-slim-bookworm` im Pinning-Beispiel (P11): `python:3.14-slim` zeigt aktuell auf Debian trixie, kap03 zeigt Debian 13. Nicht geändert (bookworm existiert, kein Fehler), aber für Konsistenz `-slim-trixie` erwägen (kap08 Tabelle "Versionen festlegen"; ggf. weitere Kapitel/Anhänge).
- kap08: DHI-Lizenz/Kosten werden im Tipp nicht erwähnt (P12), keine Änderung nötig.
- kap01-Quellenanzahl (15 verschiedene) liegt leicht über dem Richtwert 12.

---

# Aenderungen Z2 (kap02, kap06, kap09, kap10)

Nur inhaltliche Aenderungen (ohne reine @key-Einfuegungen).

## kap02-mac.typ

1. OrbStack-Zeile (Tabelle)
   - vorher: "Sehr schnell und sparsam, aber kommerzielles Produkt (für private Nutzung kostenlos)."
   - nachher: "Laut Hersteller sehr schnell und sparsam, aber kommerzielles Produkt (kostenlos nur für private, nicht-kommerzielle Nutzung, beruflich lizenzpflichtig) [Key]."
   - Grund: Lizenz praezisiert, Geschwindigkeit ist Herstellerangabe. Key: docs-orbstack-dev-licensing.

2. Installation, Code-Kommentar Rosetta
   - vorher: "# 1. Rosetta 2 installieren (für x86-Images, einmalig, VOR dem ersten Start von Colima)"
   - nachher: "... (für x86-Images, einmalig, nur bis macOS 26 nötig, VOR dem ersten Start von Colima)"
   - Grund: Apple: ab macOS 27 ist Intel-Uebersetzung im System, keine Rosetta-Installation noetig. Key: developer-apple-com-documentation-virtualization-running-intel-binaries-in-linux-vms. (Der Beleg steht in der Zeile `--vz-rosetta` der Optionstabelle, da Codebloecke keine Verweise erlauben.)

3. Optionstabelle `--vz-rosetta`
   - vorher: "... Nötig, um `linux/amd64`-Images zu testen (Kapitel 9)."
   - nachher: zusaetzlicher Satz: "Ab macOS 27 ist die Übersetzung im System enthalten, eine Rosetta-Installation entfällt dann [Key]."
   - Key: developer-apple-com-documentation-virtualization-running-intel-binaries-in-linux-vms.

4. `brew install` (Codeblock)
   - vorher: `brew install colima docker docker-compose docker-buildx docker-credential-helper docker-completion`
   - nachher: ohne `docker-completion`
   - Grund: Homebrew-Formel deprecated (seit 2026-05-31, Deaktivierung 2027-05-31), Ersatz: die Formel `docker` erzeugt Completions selbst (Recherche r2-map, Probleme Nr. 2; kein Key in literatur.yml).

5. Tipp (Ende Kap. 2)
   - vorher: "...aktiviert das Homebrew-Paket `docker-completion` zusammen mit `compinit` in der `~/.zshrc` (siehe Git-Handbuch, Kapitel 2)."
   - nachher: "...liefert das Homebrew-Paket `docker` bereits mit, aktiviert wird sie mit `compinit` in der `~/.zshrc` (siehe Git-Handbuch, Kapitel 2)."
   - Grund: wie 4. Kein Verweis (kein passender Key vorhanden).

6. Optionstabelle `--vm-type vz`
   - vorher: "...statt QEMU: schneller und sparsamer."
   - nachher: "...statt QEMU: schneller [Key]."
   - Grund: Colima-Doku nennt nur "better performance"; "sparsamer" nicht belegt. Key: colima-run-docs-configuration.

7. Tabelle "Colima im Alltag", `colima delete`
   - vorher: "VM *samt allen Images, Containern und Volumes* löschen"
   - nachher: "VM löschen. Images und Volumes bleiben auf einer separaten Daten-Disk erhalten, `colima delete --data` löscht auch diese"
   - Grund: ab Colima v0.9.0 liegen Container-Runtime-Daten auf separater Disk; nur `--data` loescht sie. Keys: colima-run-docs-commands, github-com-abiosoft-colima-blob-main-docs-faq-md.

8. Umstieg, Schritt 2 (Docker-Desktop-Pfad)
   - vorher: "Docker Desktop legt einen Link unter `/usr/local/bin/docker` an."
   - nachher: "Docker Desktop legt Links auf seine Programme standardmäßig unter `~/.docker/bin` an (je nach Einstellung auch unter `/usr/local/bin`)."
   - Grund: Docker-Doku: Standard ist `$HOME/.docker/bin`. Key: docs-docker-com-desktop-setup-install-mac-permission-requirements.

## kap06-netzwerke.typ

9. Netzwerktreiber, Zeile `host`
   - vorher: "Nur auf Linux sinnvoll, am Mac ist "Host" die VM."
   - nachher: "Volle Wirkung nur auf Linux. Docker Desktop bietet es ab Version 4.34 als optionale Einstellung [Key], bei Colima ist "Host" die VM, nicht der Mac."
   - Grund: Host-Treiber auch auf Docker Desktop >= 4.34 (Einstellung). Key: docs-docker-com-engine-network-drivers-host. Der Colima-Teil ist Eigenaussage (nur offenes Issue abiosoft/colima #1262), ohne Verweis.

## kap09-plattformen.typ, kap10-fehlersuche.typ

Keine inhaltlichen Textaenderungen.

# Nicht belegt / offen (ohne Verweis belassen, Autor pruefen)

kap02
- Tipp Tab-Vervollstaendigung: Aussage, dass das Homebrew-Paket `docker` Completions mitliefert, ist nur per Recherche (Formelquelle) gestuetzt; kein Key in literatur.yml. Optional Quelle (formulae.brew.sh/formula/docker) nachtragen.
- "Docker Desktop ... `credsStore: "desktop"`": Wert `desktop` steht in der Docker-Doku nicht woertlich (Verweis auf docker-login nur fuer vorkonfigurierten Credential Store).
- Mac-Box "Speicherplatz: Alle Images und Volumes liegen in der Disk-Datei der VM": seit Colima 0.9.0 liegen die Daten auf einer separaten Daten-Disk; Formulierung evtl. anpassen.
- "Bei 16 bis 18 GB RAM ... 6 GB ... guter Start", "Keine Lizenzfragen, kein GUI-Prozess", Einleitungssatz "Container brauchen Linux-Kernel": eigene Einschaetzung / Allgemeinwissen, ohne Verweis.
- OrbStack "sehr schnell und sparsam": nur Herstellerangabe (docs.orbstack.dev/compare/docker-desktop, nicht in literatur.yml).
- `docker context create ... ssh://` Beispiel und `docker --context server ps`: nicht zitiert (Quellenlimit; Beleg waere docs-docker-com-engine-security-protect-access bzw. engine-manage-resources-contexts).

kap06
- "IP-Adressen, die sich bei jedem Neustart ändern können": Docker-Doku belegt nur "nur per IP erreichbar" (Bridge-Seite zitiert), nicht die Aenderung beim Neustart.
- Code `-v pgdaten:/var/lib/postgresql` mit `postgres:18` (Mount-Pfad ab PG 18): im Codeblock nicht zitierbar; Beleg waere hub-docker-com-postgres (in kap10 zitiert).
- Colima-Abweichungen bei aelteren Profilen/Netzwerkmodi: nur Template belegt die Namensaufloesung, Abweichungen nicht dokumentiert.
- Optional: DOCKER-USER-Chain fuer Firewall-Regeln erwaehnen (nicht verifiziert, nicht aufgenommen).
- `none`-Zeile ohne Verweis (Key docs-docker-com-engine-network-drivers-none existiert).

kap09
- `exec format error`-Erklaerung, Basis-Image und `psycopg[binary]`: nicht belegbar, ohne Verweis.
- "Docker lädt automatisch die Variante, die zum eigenen Rechner passt": Verweise nur auf Index-Struktur (OCI, Distribution); das automatische Auswaehlen steht nicht woertlich in Docker-Seiten.
- "zuverlässig" und "bei großen Kompilierungen um ein Vielfaches" (Emulation): Quelle sagt nur, dass Emulation bei rechenintensiven Aufgaben langsamer ist; "Vielfaches" nicht beziffert.
- Zugehoerigkeit "python:3.14-slim fuer viele Architekturen" ueber hub-docker-com-python zitiert (Architekturliste der Hub-Seite, nicht gesondert gegengeprueft).

kap10
- Exit 125 Beispiele "(ungültige Option, Port belegt)": nicht woertlich belegt.
- Exit 139 "typischerweise Fehler in nativem Code ..." und "falsche CPU-Architektur meldet meist `exec format error`": erfahrungsbasiert, Verweis nur auf SIGSEGV.
- Exit 0/1, `compose ps -a`, `compose logs --tail`, `compose config`, `docker events`: ohne Verweis (Quellenlimit; Keys vorhanden: docs-docker-com-reference-cli-docker-container-logs, ...-compose-config, ...-system-events, ...-compose-restart).
- `exec format error`-Zeile in Haeufige Probleme: Querverweis auf Kap. 9, ohne Verweis.

---

# Änderungen Agent Z3 (kap07, kap11, kap12)

Nur inhaltliche Textänderungen (reine @key-Einfügungen nicht aufgeführt).

## kap07-compose.typ

1. Absatz "Startreihenfolge" (unhealthy / Restart Policy)
   - Vorher: "... startet ihn Docker deshalb nicht automatisch neu. Eine Restart Policy greift erst, wenn sein Hauptprozess endet."
   - Nachher: "... startet ihn Docker deshalb nicht automatisch neu, denn der Healthcheck setzt nur den Status. Eine Restart Policy greift erst, wenn sein Hauptprozess endet [dockerfile] [start-containers-automatically]."
   - Begründung: nur indirekt belegt (Probleme 7): Dockerfile-Referenz (HEALTHCHECK setzt Status unhealthy) plus "Start containers automatically" (Restart Policies greifen beim Beenden). Zusatznebensatz macht die indirekte Herleitung explizit.
   - Keys: docs-docker-com-reference-dockerfile, docs-docker-com-engine-containers-start-containers-automatically.

2. Absatz `pre_start` (Probleme 3)
   - Vorher: "... Ein eigener Migrations-Dienst bleibt für Produktion oft klarer, weil sein einmaliger Status sichtbar ist und mehrere API-Replikate nicht gleichzeitig dieselbe Migration starten."
   - Nachher: "... weil sein einmaliger Status sichtbar ist, er von mehreren Diensten abhängig sein kann und sich unabhängig aufrufen lässt [init-containers]."
   - Begründung: Doku "Use init containers in Compose": `pre_start` läuft einmal je Dienst, nicht je Replika; das Replika-Argument war falsch. Das One-Shot-Muster bleibt sinnvoll, wenn die Arbeit von mehreren Diensten geteilt wird bzw. unabhängig adressierbar sein soll.
   - Keys: docs-docker-com-compose-how-tos-init-containers; Versionsaussage "ab 5.3": github-com-docker-compose-releases-tag-v5-3-0.

## kap11-registry.typ

3. Gitea Sichtbarkeit (Probleme 4)
   - Vorher: "Dort lässt es sich mit einem Repository verknüpfen und in der Sichtbarkeit einschränken."
   - Nachher: "Dort lässt es sich mit einem Repository verknüpfen. Die Sichtbarkeit wird vom Besitzer geerbt, für private Images muss also der Besitzer (Benutzer oder Organisation) privat sein [overview]."
   - Key: docs-gitea-com-usage-packages-overview (Access Restrictions).

4. Tipp Aufräumregeln (Probleme 5a, 5b)
   - Vorher: "Unter _Pakete -> Aufräumregeln_ legst du etwa fest, ..., Tags nach dem Muster `v*` aber nie gelöscht werden."
   - Nachher: "In den Einstellungen des Besitzers unter _Pakete -> Aufräumregeln_ legst du etwa fest, ..., Tags, die auf den regulären Ausdruck `\d+\.\d+\.\d+` passen, aber nie gelöscht werden [storage]."
   - Begründung: Gitea nutzt reguläre Ausdrücke statt Globs; `v*` passt nicht auf `v1.4.0`; die Image-Tags im Buch heißen `1.4.0` ohne `v`, daher Muster `\d+\.\d+\.\d+`. Menüpfad (Einstellungen des Besitzers) nur über Gitea-Quelltext belegt, nicht zitiert; Zitat belegt Aufräumregeln/Regex-Prinzip.
   - Key: docs-gitea-com-usage-packages-storage.

5. Docker Hub (Probleme 6)
   - Vorher: "Im September 2026 gilt ein Sechs-Stunden-Kontingent ..." und "Builds schlagen mit _toomanyrequests_ fehl."
   - Nachher: "Stand Oktober 2026 gilt ..." und "Builds schlagen mit HTTP 429 und der Meldung _You have reached your pull rate limit_ fehl [pulls]."
   - Begründung: Die Docker-Hub-Doku nennt HTTP 429 und diese Meldung; `toomanyrequests` steht nicht auf den geprüften Seiten; die Seite nennt kein Gültigkeitsdatum, Abrufdatum 2026-10-01 daher "Stand Oktober 2026".
   - Key: docs-docker-com-docker-hub-usage-pulls.

## kap12-sicherheit.typ

6. Beispiel `compose.prod.yaml (Auszug)` (Probleme 1)
   - Vorher: `limits:` mit `cpus`, `memory`, danach auf Dienstebene `pids_limit: 200`.
   - Nachher: `pids: 200  # höchstens 200 Prozesse im Container` unter `deploy.resources.limits`, `pids_limit` entfernt.
   - Begründung: `pids_limit` zusammen mit `deploy.resources.limits` war mit Compose 5.5.1 ungültig. Korrigiertes Beispiel lokal mit `docker compose config` (Compose v5.5.1) geprüft: gültig, `pids: 200` wird übernommen.
   - Key: docs-docker-com-reference-compose-file-deploy (am Tabellenzeile "Ressourcenlimits").

7. Kommentar Speicherlimit (Probleme 2b)
   - Vorher: `# bei Überschreitung: Abbruch mit Exit-Code 137`
   - Nachher: `# bei Überschreitung: OOM-Kill, meist Exit-Code 137`
   - Begründung: Exit-Code 137 ist in der Docker-Doku nirgends belegt (128 + SIGKILL, plausibel); abgeschwächt, ohne Zitat.

8. Datenbank-Images (Verallgemeinerung eingeschränkt)
   - Vorher: "Die offiziellen Datenbank-Images etwa wechseln beim Start selbst den Benutzer und brauchen dafür Rechte."
   - Nachher: "Datenbank-Images wie das offizielle PostgreSQL-Image wechseln beim Start selbst den Benutzer und brauchen dafür Rechte [postgres entrypoint]."
   - Begründung: Beleg nur für das PostgreSQL-Entrypoint-Skript (gosu), nicht für alle Datenbank-Images.
   - Key: github-com-docker-library-postgres-blob-master-docker-entrypoint-sh.

9. Trivy-Befehl und Text (Probleme 2)
   - Vorher: `trivy image --exit-code 1 --exit-on-eol --severity CRITICAL notizen:1.4.0` und "`--exit-on-eol` verhindert außerdem, dass ein nicht mehr unterstütztes Betriebssystem unbemerkt weiterläuft."
   - Nachher: `... --exit-on-eol 1 --severity ...` und "`--exit-on-eol 1` beendet Trivy außerdem mit Exit-Code 1 und verhindert so, dass ein nicht mehr unterstütztes Betriebssystem unbemerkt weiterläuft [trivy-others]."
   - Begründung: `--exit-on-eol` ist ein Integer-Flag; ohne Wert wird `--severity` als Wert geparst (Fehler). Trivy selbst war lokal nicht installiert, Korrektur nach Doku und Recherche-Test.
   - Key: trivy-dev-docs-latest-configuration-others.

## Nicht belegt / offen (ohne Verweis belassen, Autor prüfen)

- kap07: "`docker compose up -d --build` ... unveränderte Schichten dürfen aus dem Cache kommen", `logs`, `exec`, `run --rm`, `pull`, `stop/start`-Zeilen der Befehlstabelle (reine Befehlsreferenz, nur `up`/`down -v`/`config` belegt). `restart`-Aussage (Konfigurationsänderungen greifen nicht) bewusst nicht einzeln zitiert (Schlüssel docs-docker-com-reference-cli-docker-compose-restart existiert und könnte ergänzt werden).
- kap07: Aussage zu `pre_start`: "Für kleine lokale Setups ist das kompakt" und "sein einmaliger Status sichtbar" sind Buchempfehlungen, ohne Quelle. Zusatz laut Recherche: `pre_start` wird bei unverändertem Stand bei späteren `up` übersprungen (nicht in den Text übernommen).
- kap07: Beispiele `fastapi dev`, Adminer-Profil, Migration mit Alembic: Beispielprojekt, ohne Quelle.
- kap07: Erwähnung "Projektname", "-p name": nur über project-name-Seite belegt, nicht einzeln geprüft.
- kap11: Menüpfad "Einstellungen -> Pakete -> Aufräumregeln" nur über den Gitea-Quelltext belegt (nicht in der Doku). Zusatz laut Recherche: Container-Registry behält immer `latest`, "letzte 20 Versionen" gilt je Paket.
- kap11: "Kommt dieser Token abhanden, kann damit niemand manipulierte Images hochladen" und "Für den Server legt man einen eigenen Token nur mit Leserecht an": Buchempfehlung, kein Verweis (Scope `package` Read vs. Read & Write in overview belegt).
- kap11: Tag-Strategie-Tabelle (Commit-Hash, `1.4`, `1`): Buchempfehlung; Digest-Referenz-Aussage über best-practices (Kapitel 1-Verweis) nur am einleitenden Satz belegt. Zusätzlich existiert laut Recherche ein separates Docker-Hub "abuse rate limit" pro IP (nicht im Text).
- kap12: "Exit-Code 137" (siehe Änderung 7). Gruppe-`docker`-Aussage hat nur postinstall-Beleg ("root-level privileges"), "gleichbedeutend mit sudo" ist Zuspitzung.
- kap12: Vorgehensempfehlung "alles setzen, starten, Logs lesen, nur zurücknehmen", Bash-Beispiel zu Dateirechten (UID 10001, `0711`, `0400`), Python-Beispiel: Eigenempfehlung ohne Quelle. `docker run -v /:/host ...`: nicht belegt, aber Aussage zur vollen Kontrolle über engine-security zitiert.
- kap12: Checkliste: Zeilen zu Multi-Stage, Reverse Proxy/Ports, Build-Geheimnisse, SBOM/Signaturen ohne Einzelbeleg (Verweise in den Kapiteln 6, 8, 14). Sammelverweis nur an Zeile 1 (OWASP, NIST).
- kap12 optional: Notary-v1-Dienst `notary.docker.io` wird laut `docs-docker-com-engine-security-trust` am 8. Dezember 2026 abgeschaltet (nicht eingefügt).
- Hinweis außerhalb meiner Dateien: Der CI-Workflow in einem anderen Kapitel (PDF-Zeile "trivy image --exit-code 1 --exit-on-eol 1 --severity CRITICAL \") enthält bereits die korrigierte Form.

---

# Aenderungen Z4 (kap00, kap13, kap14, kap15)

Nur inhaltliche Textaenderungen (reine @key-Einfuegungen nicht aufgefuehrt).

1. kap13-server.typ, Abschnitt "Docker Engine installieren"
   - vorher: "Die Pakete der Distribution (`docker.io`) sind oft veraltet, ..."
   - nachher: "Die Pakete der Distribution (`docker.io`) sind inoffiziell und koennen mit den offiziellen Paketen kollidieren, ..."
   - Begruendung: Docker-Doku nennt sie "unofficial ... may conflict"; "veraltet" nicht belegt. Key: docs-docker-com-engine-install-debian

2. kap13-server.typ, cgroup-Absatz
   - vorher: "Docker Engine 29 bevorzugt cgroup v2 und hat cgroup v1 als veraltet markiert."
   - nachher: "Docker Engine 29 hat cgroup v1 als veraltet markiert und unterstuetzt es noch bis mindestens Mai 2029."
   - Begruendung: "bevorzugt" steht nicht in der Quelle; konkretes Datum ergaenzt. Key: docs-docker-com-engine-deprecated

3. kap13-server.typ, Backups
   - vorher: "Das `-T` bei `exec` schaltet das Terminal ab, sonst beschaedigt Compose die Binaerdaten des Dumps."
   - nachher: "Das `-T` bei `exec` schaltet die Pseudo-Terminal-Zuweisung ab, die sonst die Binaerdaten des Dumps verfaelschen kann."
   - Begruendung: Doku belegt nur TTY-Default und -T; Folgerung abgeschwaecht. Key: docs-docker-com-reference-cli-docker-compose-exec

4. kap14-cicd.typ, Trivy-Befehl im Workflow-Block
   - vorher: `trivy image --exit-code 1 --exit-on-eol --severity CRITICAL`
   - nachher: `trivy image --exit-code 1 --exit-on-eol 1 --severity CRITICAL`
   - Begruendung: --exit-on-eol erwartet Integer (CLI-Referenz; lokal mit Trivy 0.74.0 getestet). Key: trivy-dev-docs-latest-references-configuration-cli-trivy-image (im Text bei der Smoke-Test/Trivy-Aufzaehlung zitiert)

5. kap14-cicd.typ, Abschnitt "Tests gegen eine echte Datenbank"
   - vorher: "Gitea Actions kann fuer einen Job Hilfscontainer starten (_services_)."
   - nachher: "Gitea Actions kann fuer einen Job, dessen Runner-Label auf ein Docker-Image zeigt, Hilfscontainer starten (_services_)."
   - Begruendung: Host-Mode-Jobs starten keine Service-Container. Key: gitea-com-gitea-runner

6. kap14-cicd.typ, Aufzaehlung zum Build
   - vorher: "`--provenance=mode=max` dokumentiert Build-Quelle und Parameter."
   - nachher: "... Parameter, legt dabei aber auch Build-Argument-Werte offen (deshalb keine Geheimnisse in `--build-arg`)."
   - Begruendung: Docker-Doku warnt vor Offenlegung bei mode=max. Key: docs-docker-com-build-metadata-attestations-slsa-provenance

7. kap14-cicd.typ, Signatur-Absatz
   - vorher: "Docker Content Trust gehoert seit Engine 29 nicht mehr zur Docker-CLI."
   - nachher: "... nicht mehr zur Docker-CLI; sein Notary-v1-Dienst wird am 8. Dezember 2026 abgeschaltet."
   - Begruendung: Buchstand Oktober 2026, Abschaltung laut Doku. Keys: docs-docker-com-engine-release-notes-29, docs-docker-com-retired

8. kap15-ausblick.typ, Swarm-Absatz (nftables)
   - vorher: "... das neue nftables-Firewall-Backend von Docker Engine 29 ..."
   - nachher: "... das neue, noch experimentelle nftables-Firewall-Backend von Docker Engine 29 ..."
   - Begruendung: Backend ist in Engine 29 experimentell. Key: docs-docker-com-engine-network-firewall-nftables

9. kap15-ausblick.typ, MKE 4
   - vorher: "MKE 4 ist Kubernetes-basiert und unterstuetzt den frueheren Swarm-Modus von MKE 3 nicht mehr."
   - nachher: "Laut Mirantis ist MKE 4 Kubernetes-basiert und unterstuetzt den frueheren Swarm-Modus von MKE 3 nicht mehr."
   - Begruendung: nur ueber Mirantis-Blog (2024-11-13) belegt, vorsichtig attribuiert. Key: mirantis-com-blog-mirantis-kubernetes-engine-4-released

## Nicht belegt / offen
- kap15: MKE 4 nur ueber Blogbeitrag belegt; Doku-Seite (mke4k.docs.mirantis.com) vor Drucklegung manuell pruefen.
- kap15: "Nischenprodukt", "kaum noch zu empfehlen", "zukunftssicherer", "Industriestandard", Tabellenzeilen Betriebsaufwand/Konfiguration ("fast dieselbe Datei")/Compose "nein (Sekunden)": Autorenwertung, ohne Verweis (nur "langsamer geworden" belegt).
- kap14: `curl ... | sh`-Risiko ohne Primaerquelle, ohne Verweis.
- kap14: Fork-PR-Secrets bei Gitea: Gitea-FAQ belegt nur Freigabepflicht fuer Fork-PR-Actions; "keine Secrets" ist ueber GitHub-Doku belegt, Gitea-Primaerquelle fehlt.
- kap14: Das Runner-Image "per Checksum oder Signatur geprueft", Smoke-Test-Ablauf, Deployment-Skript: eigenes Design, ohne Verweis.
- kap14: Das Beispiel nutzt `runs-on: ubuntu-latest`; Service-Container funktionieren nur, wenn dieses Label auf ein Docker-Image zeigt (im Text nun als Halbsatz erwaehnt).
- kap13: `docker-ce-rootless-extras` im apt-Befehl steht nicht in der offiziellen Debian-Paketliste der Doku (Codeblock unveraendert; Autor kann es streichen).
- kap13: `/srv`-Layout, cron-Zeile, Synology-Abhaengigkeit von DSM-Modell/Release, Postgres-18-Mountpunkt und `caddy_data`-Persistenz (nur in Codeblock/Kommentar), `restart`/`depends_on`: keine Verweise gesetzt (Codeblock bzw. Eigenempfehlung).
- kap13: Bewusst ohne Verweis gelassen (Kapazitaet): Digest-Pinning-Satz, `:?`-Interpolation, Caddyfile-Direktiven, Hub-Tags caddy/postgres, Diun/Uptime Kuma (Diun ist zitiert, Kuma nicht).
- kap00: Colima/Docker-Desktop-Aussagen im Aufbau nicht belegt (Nur Erwaehnung; Belege in Teil I).

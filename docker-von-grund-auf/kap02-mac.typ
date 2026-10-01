#import "lib.typ": *

= Docker am Mac ohne GUI: Colima

Weil Container einen Linux-Kernel brauchen, läuft Docker am Mac immer in einer Linux-VM. Die Frage ist nur, wer diese VM verwaltet. Docker Desktop bringt dafür eine grafische Anwendung mit. Wer ohnehin nur im Terminal arbeitet, kommt mit *Colima* aus: ein reines Kommandozeilenwerkzeug, das die VM startet und den normalen `docker`-Befehl mit ihr verbindet @github-com-abiosoft-colima.

== Die Optionen im Vergleich

#table(columns: (auto, auto, 1fr),
  [Werkzeug], [Oberfläche], [Einordnung],
  [*Docker Desktop*], [GUI + CLI], [Offizielle Lösung mit vielen Extras. Kostenlos für Privatnutzung, Ausbildung, nicht-kommerzielle Open-Source-Projekte und kleine Unternehmen (unter 250 Beschäftigte und unter 10 Mio. USD Umsatz), darüber kostenpflichtig @docs-docker-com-subscription-billing-desktop-license. Läuft als Hintergrund-App.],
  [*Colima*], [nur CLI], [Open Source (MIT), basiert auf Lima @github-com-abiosoft-colima. Startet eine schlanke VM mit Docker-Daemon, danach funktioniert der normale `docker`-Befehl @github-com-abiosoft-colima. Keine Lizenzfragen, kein GUI-Prozess.],
  [*OrbStack*], [GUI + CLI], [Laut Hersteller sehr schnell und sparsam, aber kommerzielles Produkt (kostenlos nur für private, nicht-kommerzielle Nutzung, beruflich lizenzpflichtig) @docs-orbstack-dev-licensing.],
  [*Podman*], [CLI, optional GUI], [Alternative Container-Engine ohne Daemon, weitgehend Docker-kompatibel, mit gelegentlichen Unterschieden bei Compose @docs-podman-io-en-latest.],
)

Für eine reine Terminal-Arbeitsweise ist Colima die naheliegende Wahl. Die Docker-CLI und die Beispiele dieses Buchs funktionieren damit weitgehend wie unter Docker Desktop. Details der VM-Integration, Netzwerke, Dateifreigaben und mitgelieferte Zusatzfunktionen unterscheiden sich jedoch.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    rahmen((0, -1.6), (15.4, 1.6), [macOS], c-grey, bg: luma(250))
    kasten((1.6, 0), [`docker` \ `docker compose`], w: 2.4, h: 1.1)
    kasten((4.9, 0), [`colima` \ #text(size: 6.5pt)[startet/stoppt VM]], w: 2.3, h: 1.1)
    rahmen((6.9, -1.25), (15.1, 1.25), [Linux-VM (Apple Virtualization, `vz`)], c-blue)
    kasten((8.6, -0.1), [`dockerd`], w: 1.8, h: 0.8, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((10.9, -0.1), [Container], w: 1.7, h: 0.8, bg: rgb("#FDF1EC"), col: c-accent)
    kasten((13.2, -0.1), [Container], w: 1.7, h: 0.8, bg: rgb("#FDF1EC"), col: c-accent)
    pfeil((2.8, 0.75), (7.7, 0.35), label: "Socket", loff: (0, 0.2), color: c-blue)
    pfeil((6.05, -0.3), (6.95, -0.3), color: c-grey.darken(20%))
    content((12, -0.9), text(size: 6.5pt, fill: c-grey.darken(20%), style: "italic")[Home-Verzeichnis per virtiofs eingebunden])
  }),
  caption: [Colima verwaltet nur die VM. Der `docker`-Befehl spricht direkt mit dem Daemon darin.],
)

== Installation

```bash
# 1. Rosetta 2 installieren (für x86-Images, einmalig, nur bis macOS 26 nötig, VOR dem ersten Start von Colima)
softwareupdate --install-rosetta --agree-to-license

# 2. Colima, Docker-CLI und Plugins über Homebrew
brew install colima docker docker-compose docker-buildx \
             docker-credential-helper
```

Compose und Buildx sind bei der Homebrew-Installation *Plugins* der Docker-CLI @formulae-brew-sh-formula-docker-compose. Damit `docker compose` und `docker buildx` sie finden und Registry-Zugangsdaten im macOS-Schlüsselbund statt im Klartext landen @docs-docker-com-reference-cli-docker-login, braucht die Docker-Konfiguration zwei Einträge:

#datei("~/.docker/config.json")[
```json
{
  "credsStore": "osxkeychain",
  "cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]
}
```
]

Dann die VM erstmals starten, passend für Apple Silicon:

```bash
colima start --vm-type vz --vz-rosetta --mount-type virtiofs --cpu 4 --memory 6 --disk 60
```

#table(columns: (auto, 1fr),
  [Option], [Bedeutung],
  [`--vm-type vz`], [Apples eigenes Virtualisierungs-Framework statt QEMU: schneller @colima-run-docs-configuration.],
  [`--vz-rosetta`], [x86-Programme in der ARM-VM über Rosetta ausführen. Nötig, um `linux/amd64`-Images zu testen (Kapitel 9). Ab macOS 27 ist die Übersetzung im System enthalten, eine Rosetta-Installation entfällt dann @developer-apple-com-documentation-virtualization-running-intel-binaries-in-linux-vms.],
  [`--mount-type virtiofs`], [Schnellste Art, Mac-Verzeichnisse in Container einzubinden @colima-run-docs-configuration.],
  [`--cpu`, `--memory`, `--disk`], [Ressourcen der VM (GB). Bei 16 bis 18 GB RAM im Mac sind 6 GB für die VM ein guter Start. Die Disk lässt sich später vergrößern, aber nicht verkleinern @colima-run-docs-configuration.],
)

Prüfen, ob alles funktioniert:

```bash
docker context ls                                   # "colima" sollte mit * markiert sein
docker version                                      # Client (macOS) und Server (Linux)
docker compose version
docker run --rm hello-world
docker run --rm --platform linux/amd64 alpine uname -m   # zeigt x86_64 dank Rosetta
```

== Colima im Alltag

#table(columns: (auto, 1fr),
  [Befehl], [Wirkung],
  [`colima start`], [VM mit der gespeicherten Konfiguration starten],
  [`colima stop`], [VM herunterfahren (Container, Images und Volumes bleiben erhalten)],
  [`colima status`], [Zustand, Architektur, Laufzeit, Mount-Typ],
  [`colima list`], [alle Colima-Profile mit CPU, RAM und Disk],
  [`colima start --edit`], [Konfiguration im Editor ändern, danach Neustart der VM],
  [`colima ssh`], [Shell in der Linux-VM (selten nötig)],
  [`colima delete`], [VM löschen. Images und Volumes bleiben auf einer separaten Daten-Disk erhalten, `colima delete --data` löscht auch diese @colima-run-docs-commands @github-com-abiosoft-colima-blob-main-docs-faq-md],
  [`brew services start colima`], [Colima bei jeder Anmeldung automatisch starten],
)

Die Konfiguration liegt in `~/.colima/default/colima.yaml`. Dort lassen sich die Startoptionen dauerhaft festlegen, sodass ein schlichtes `colima start` genügt @colima-run-docs-configuration. Mehrere unabhängige VMs sind über Profile möglich (`colima start --profile test`) @colima-run-docs-profiles, was sich etwa zum Ausprobieren einer anderen Docker-Version eignet.

#mac[
*Eingebundene Verzeichnisse:* Standardmäßig ist nur dein Home-Verzeichnis in der VM sichtbar. Projekte außerhalb davon, etwa auf einem externen Laufwerk, müssen in `colima.yaml` unter `mounts:` eingetragen werden, sonst sieht der Container einen leeren Ordner @github-com-abiosoft-colima-blob-main-docs-faq-md.

*Andere Werkzeuge:* Programme, die den Docker-Socket direkt suchen (manche IDE-Plugins, Testcontainers), finden ihn nicht am Standardort. Falls ein Werkzeug keine Docker Contexts unterstützt, kann man für dessen einzelnen Aufruf `DOCKER_HOST="unix://$HOME/.colima/default/docker.sock" werkzeug ...` setzen @github-com-abiosoft-colima-blob-main-docs-faq-md. Ein globaler Export in der `~/.zshrc` ist keine gute Lösung: `DOCKER_HOST` übersteuert den aktiven Context und macht `docker context use ...` scheinbar wirkungslos @docs-docker-com-engine-manage-resources-contexts.

*Speicherplatz:* Alle Images und Volumes liegen in der Disk-Datei der VM. `docker system df` zeigt, wie viel davon belegt ist (Kapitel 10) @docs-docker-com-reference-cli-docker-system-df.
]

== Kontexte: zwischen Colima und Docker Desktop wechseln

Die CLI kann mit mehreren Daemons sprechen. Jede Verbindung ist ein *Kontext*. Colima legt beim Start den Kontext `colima` an @colima-run-docs-profiles, Docker Desktop den Kontext `desktop-linux` @docs-docker-com-desktop-setup-install-mac-permission-requirements. Der aktive Kontext entscheidet, wohin `docker` seine Befehle schickt @docs-docker-com-engine-manage-resources-contexts:

```bash
docker context ls                 # alle Kontexte, der aktive ist mit * markiert
docker context use colima         # auf Colima umschalten
docker context use desktop-linux  # zurück zu Docker Desktop
```

Kontexte können auch auf entfernte Rechner zeigen, etwa den Server per SSH (`docker context create server --docker "host=ssh://deploy@app.example.com"`). Das ist bequem, aber mit Vorsicht zu genießen: Mit dem falschen aktiven Kontext landet ein `docker compose down -v` auf dem Server statt am Mac. Wer so arbeitet, sollte sich den aktiven Kontext im Prompt anzeigen lassen oder den Kontext pro Befehl angeben (`docker --context server ps`).

== Umstieg von Docker Desktop

+ Docker Desktop beenden und in dessen Einstellungen den Autostart abschalten.
+ Prüfen, welche `docker`-CLI verwendet wird: `which -a docker`. Docker Desktop legt Links auf seine Programme standardmäßig unter `~/.docker/bin` an (je nach Einstellung auch unter `/usr/local/bin`) @docs-docker-com-desktop-setup-install-mac-permission-requirements. Die Homebrew-Version liegt unter `/opt/homebrew/bin/docker` und sollte zuerst gefunden werden.
+ Images und Volumes liegen in der VM von Docker Desktop und kommen nicht automatisch mit. Images baut oder lädt man einfach neu. Wichtige Volume-Daten (etwa eine lokale Entwicklungsdatenbank) sichert man vorher mit einem Dump (Kapitel 5).
+ In `~/.docker/config.json` einen eventuell von Docker Desktop gesetzten `credsStore: "desktop"` durch `osxkeychain` ersetzen @docs-docker-com-reference-cli-docker-login.
+ Docker Desktop kann parallel installiert bleiben, wenn es später doch einmal gebraucht wird. Der aktive Kontext entscheidet @docs-docker-com-engine-manage-resources-contexts.

#tipp[Die Tab-Vervollständigung für `docker` und `docker compose` liefert das Homebrew-Paket `docker` bereits mit, aktiviert wird sie mit `compinit` in der `~/.zshrc` (siehe Git-Handbuch, Kapitel 2). Danach vervollständigt die Shell auch Container- und Image-Namen.]

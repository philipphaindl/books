#import "lib.typ": *

= Glossar

#let begriffe = (
  ([Basis-Image], [Image, auf dem ein Dockerfile mit `FROM` aufbaut, z.B. `python:3.14-slim`.]),
  ([Bind Mount], [Direkt eingeblendetes Verzeichnis des Hosts im Container.]),
  ([Build-Kontext], [Verzeichnis, dessen Inhalt beim Bauen für `COPY` erreichbar ist, gefiltert durch `.dockerignore`.]),
  ([BuildKit / Buildx], [Aktuelles Build-System von Docker mit Cache-Mounts und Multi-Plattform-Builds.]),
  ([Attestation], [Mit einem Image veröffentlichte, überprüfbare Metadaten wie SBOM oder Build-Provenance.]),
  ([cgroups], [Kernel-Mechanismus zur Begrenzung von CPU, Speicher und Prozessen.]),
  ([Colima], [Kommandozeilenwerkzeug, das am Mac eine Linux-VM mit Docker-Daemon verwaltet.]),
  ([Compose], [Werkzeug, das eine Anwendung aus mehreren Containern deklarativ in `compose.yaml` beschreibt.]),
  ([Container], [Abgeschotteter Linux-Prozess mit eigenem Dateisystem aus einem Image und eigener Schreibschicht.]),
  ([Daemon (`dockerd`)], [Hintergrunddienst, der Images, Container, Netze und Volumes verwaltet.]),
  ([Digest], [Unveränderliche Prüfsumme eines Images (`sha256:…`).]),
  ([Dockerfile], [Bauanleitung für ein Image.]),
  ([Healthcheck], [Regelmäßig ausgeführter Befehl, der meldet, ob ein Container funktioniert.]),
  ([Image], [Unveränderliche, geschichtete Vorlage für Container.]),
  ([Image-Index], [Liste von Image-Varianten für verschiedene Architekturen unter einem Tag.]),
  ([Kontext (CLI)], [Benannte Verbindung der CLI zu einem Daemon, z.B. `colima`.]),
  ([Layer / Schicht], [Schreibgeschützte Dateisystemänderung eines Build-Schritts.]),
  ([Multi-Stage-Build], [Dockerfile mit mehreren Stufen, von denen nur die letzte zum Image wird.]),
  ([Namespace], [Kernel-Mechanismus, der einem Prozess eine eigene Sicht auf Prozesse, Netz und Dateisystem gibt.]),
  ([Port-Veröffentlichung], [Weiterleitung eines Host-Ports in einen Container (`-p`).]),
  ([Profil (Compose)], [Gruppe optionaler Dienste, die nur auf Anforderung starten.]),
  ([Registry], [Server zum Speichern und Verteilen von Images, z.B. Docker Hub oder Gitea.]),
  ([Reverse Proxy], [Vorgeschalteter Server, der Anfragen entgegennimmt, TLS erledigt und weiterleitet.]),
  ([Rosetta], [Apples Übersetzungsschicht, mit der x86-Container auf Apple Silicon laufen.]),
  ([Schreibschicht], [Beschreibbare oberste Schicht eines Containers, verschwindet mit ihm.]),
  ([Secret (Compose)], [Als Datei unter `/run/secrets/` bereitgestelltes Geheimnis.]),
  ([SBOM], [Software-Stückliste der im Image enthaltenen Pakete und Komponenten.]),
  ([Service (Compose)], [Ein Dienst in `compose.yaml`, aus dem ein oder mehrere Container entstehen.]),
  ([Swarm-Modus], [In Docker eingebaute Orchestrierung über mehrere Rechner, heute ein Nischenprodukt.]),
  ([Tag], [Beweglicher Name für ein Image, z.B. `1.4.0`.]),
  ([Volume], [Von Docker verwalteter, dauerhafter Datenspeicher.]),
)

#set text(size: 8.2pt)
#columns(2, gutter: 16pt)[
  #for (b, d) in begriffe [
    #block(below: 0.5em, breakable: false)[*#b* \ #d]
  ]
]

#v(0.4em)
#set text(size: 9pt)
Quellen und weiterführende Literatur zu den Begriffen und Werkzeugen dieses Handbuchs stehen im anschließenden Literaturverzeichnis. Für Gitea, Pull Requests, Gitea Actions, Runner, Secrets und SSH-Deployment ist das Begleitbuch "Git von Grund auf" @haindl-2026-git der Einstieg.

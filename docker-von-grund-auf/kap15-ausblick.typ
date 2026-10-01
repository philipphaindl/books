#import "lib.typ": *

= Compose, Swarm oder Kubernetes?

Docker Compose startet alle Container auf *einem* Rechner. Fällt dieser Rechner aus, steht die Anwendung. Werkzeuge zur _Orchestrierung_ verteilen Container dagegen auf mehrere Rechner, starten sie bei Ausfällen anderswo neu und aktualisieren ohne Unterbrechung. Die Frage ist, ab wann sich das lohnt.

== Ist Docker Swarm tot?

Nicht tot, aber ein Nischenprodukt. Der Open-Source-_Swarm-Modus_ ist weiterhin in Docker Engine eingebaut (`docker swarm init`) @docs-docker-com-engine-swarm und erhält Korrekturen @docs-docker-com-engine-release-notes-29. Seine Featureentwicklung und sein Ökosystem sind jedoch deutlich langsamer geworden @docs-docker-com-retired; beispielsweise lässt sich das neue, noch experimentelle nftables-Firewall-Backend von Docker Engine 29 auf Swarm-Knoten noch nicht aktivieren @docs-docker-com-engine-network-firewall-nftables. Davon zu unterscheiden ist das kommerzielle Produkt Mirantis Kubernetes Engine: Laut Mirantis ist MKE 4 Kubernetes-basiert und unterstützt den früheren Swarm-Modus von MKE 3 nicht mehr @mirantis-com-blog-mirantis-kubernetes-engine-4-released.

Für bestehende Installationen ist Swarm weiterhin eine solide, einfache Lösung. Für einen *Neueinstieg* in die Orchestrierung ist es 2026 aber kaum noch zu empfehlen, weil das Wissen und die Werkzeuge rund um Kubernetes deutlich breiter und zukunftssicherer sind.

== Die Optionen im Vergleich

#table(columns: (auto, 1fr, 1fr, 1fr),
  [], [Compose], [Swarm], [Kubernetes (z.B. k3s) @docs-k3s-io],
  [Rechner], [einer], [mehrere], [mehrere],
  [Ausfallsicherheit], [nein, Neustart nach Reboot], [ja], [ja],
  [Updates ohne Unterbrechung], [nein (Sekunden)], [ja (rolling update) @docs-docker-com-engine-swarm-swarm-tutorial-rolling-update], [ja @kubernetes-io-docs-concepts-overview],
  [Lernaufwand], [gering], [gering], [hoch],
  [Betriebsaufwand], [minimal], [gering], [spürbar, auch mit k3s],
  [Konfiguration], [`compose.yaml`], [fast dieselbe Datei], [eigene YAML-Manifeste, Helm-Charts],
  [Zukunft], [Kernwerkzeug von Docker], [weiter verfügbar, langsame Entwicklung], [Industriestandard],
)

Dazwischen gibt es Werkzeuge, die Deployments auf einzelne oder wenige Server ohne Orchestrierung komfortabler machen, etwa _Kamal_, das Container per SSH ausrollt und dabei Updates ohne Unterbrechung über einen eigenen Proxy ermöglicht @kamal-deploy-org @kamal-deploy-org-docs-configuration-proxy.

== Empfehlung

- *Eine Anwendung, ein bis zwei Server, kleines Team:* Compose, wie in diesem Buch beschrieben. Ein Update unterbricht die API für wenige Sekunden, ein Serverausfall wird durch Backups und ein vorbereitetes Wiederaufsetzen auf einem Ersatzrechner abgefangen (die Compose-Datei, `.env` und die Secrets genügen dafür).
- *Echte Hochverfügbarkeit gefordert* (vertraglich zugesicherte Verfügbarkeit, mehrere Instanzen hinter einem Load Balancer): direkt Kubernetes, für kleine Umgebungen die leichtgewichtige Distribution _k3s_ @docs-k3s-io. Images, Dockerfiles, Registries und viele Sicherheitsprinzipien bleiben nützlich. Neu gelernt werden müssen unter anderem Netzwerkmodell, Zustandsverwaltung, Identitäten, Secrets, Health- und Readiness-Semantik, Ressourcenplanung, Rollouts und Observability.
- *Swarm* nur, wenn es bereits im Einsatz ist.

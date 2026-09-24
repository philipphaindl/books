#import "lib.typ": *

= Compose, Swarm oder Kubernetes?

Docker Compose startet alle Container auf *einem* Rechner. Fällt dieser Rechner aus, steht die Anwendung. Werkzeuge zur _Orchestrierung_ verteilen Container dagegen auf mehrere Rechner, starten sie bei Ausfällen anderswo neu und aktualisieren ohne Unterbrechung. Die Frage ist, ab wann sich das lohnt.

== Ist Docker Swarm tot?

Nicht tot, aber ein Nischenprodukt. Der Open-Source-_Swarm-Modus_ ist weiterhin in Docker Engine eingebaut (`docker swarm init`) und erhält Korrekturen. Seine Featureentwicklung und sein Ökosystem sind jedoch deutlich langsamer geworden; beispielsweise lässt sich das neue nftables-Firewall-Backend von Docker Engine 29 auf Swarm-Knoten noch nicht aktivieren. Davon zu unterscheiden ist das kommerzielle Produkt Mirantis Kubernetes Engine: MKE 4 ist Kubernetes-basiert und unterstützt den früheren Swarm-Modus von MKE 3 nicht mehr.

Für bestehende Installationen ist Swarm weiterhin eine solide, einfache Lösung. Für einen *Neueinstieg* in die Orchestrierung ist es 2026 aber kaum noch zu empfehlen, weil das Wissen und die Werkzeuge rund um Kubernetes deutlich breiter und zukunftssicherer sind.

== Die Optionen im Vergleich

#table(columns: (auto, 1fr, 1fr, 1fr),
  [], [Compose], [Swarm], [Kubernetes (z.B. k3s)],
  [Rechner], [einer], [mehrere], [mehrere],
  [Ausfallsicherheit], [nein, Neustart nach Reboot], [ja], [ja],
  [Updates ohne Unterbrechung], [nein (Sekunden)], [ja (rolling update)], [ja],
  [Lernaufwand], [gering], [gering], [hoch],
  [Betriebsaufwand], [minimal], [gering], [spürbar, auch mit k3s],
  [Konfiguration], [`compose.yaml`], [fast dieselbe Datei], [eigene YAML-Manifeste, Helm-Charts],
  [Zukunft], [Kernwerkzeug von Docker], [weiter verfügbar, langsame Entwicklung], [Industriestandard],
)

Dazwischen gibt es Werkzeuge, die Deployments auf einzelne oder wenige Server ohne Orchestrierung komfortabler machen, etwa _Kamal_, das Container per SSH ausrollt und dabei Updates ohne Unterbrechung über einen eigenen Proxy ermöglicht.

== Empfehlung

- *Eine Anwendung, ein bis zwei Server, kleines Team:* Compose, wie in diesem Buch beschrieben. Ein Update unterbricht die API für wenige Sekunden, ein Serverausfall wird durch Backups und ein vorbereitetes Wiederaufsetzen auf einem Ersatzrechner abgefangen (die Compose-Datei, `.env` und die Secrets genügen dafür).
- *Echte Hochverfügbarkeit gefordert* (vertraglich zugesicherte Verfügbarkeit, mehrere Instanzen hinter einem Load Balancer): direkt Kubernetes, für kleine Umgebungen die leichtgewichtige Distribution _k3s_. Images, Dockerfiles, Registries und viele Sicherheitsprinzipien bleiben nützlich. Neu gelernt werden müssen unter anderem Netzwerkmodell, Zustandsverwaltung, Identitäten, Secrets, Health- und Readiness-Semantik, Ressourcenplanung, Rollouts und Observability.
- *Swarm* nur, wenn es bereits im Einsatz ist.

#import "lib.typ": *

= Netzwerke

Jeder Container hat ein eigenes Netzwerk-Interface mit eigener IP-Adresse. Wie Container einander finden und wie sie von außen erreichbar werden, bestimmen Docker-Netzwerke und veröffentlichte Ports. Die beiden häufigsten Fragen, "Warum erreicht meine App die Datenbank nicht?" und "Warum ist der Port von außen nicht erreichbar?", haben hier ihre Antwort.

== Eigene Netzwerke und Namensauflösung

Ohne weitere Angabe landen Container im Standardnetz `bridge`. Dort erreichen sie sich nur über IP-Adressen, die sich bei jedem Neustart ändern können. In einem *selbst angelegten* Netz dagegen löst Docker die Container-Namen automatisch als Hostnamen auf:

```bash
docker network create notizen-netz
docker run -d --name db  --network notizen-netz -v pgdaten:/var/lib/postgresql \
  -e POSTGRES_PASSWORD=geheim postgres:18
docker run -d --name api --network notizen-netz -p 8000:8000 \
  -e DATABASE_URL=postgresql://postgres:geheim@db:5432/postgres notizen:dev
```

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    rahmen((0, -1.9), (15.2, 1.7), [Host], c-grey, bg: luma(250))
    rahmen((4.4, -1.5), (14.8, 1.2), [Netzwerk `notizen-netz` (mit DNS)], c-teal)
    kasten((6.9, -0.25), [Container `api` \ #text(size: 6.5pt)[lauscht auf 0.0.0.0:8000]], w: 3.0, h: 1.0, bg: rgb("#FDF1EC"), col: c-accent)
    kasten((12.4, -0.25), [Container `db` \ #text(size: 6.5pt)[lauscht auf 5432]], w: 2.7, h: 1.0, bg: rgb("#FDF1EC"), col: c-accent)
    pfeil((8.45, -0.25), (11.0, -0.25), label: "db:5432", loff: (0, 0.22), color: c-teal)
    kasten((1.6, -0.25), [Host-Port \ `8000`], w: 2.0, h: 1.0)
    pfeil((2.65, -0.25), (5.35, -0.25), label: "-p 8000:8000", loff: (-0.45, 0.22), color: c-dark)
    content((12.4, -1.15), text(size: 6.5pt, fill: c-grey.darken(20%), style: "italic")[kein -p: von außen unerreichbar])
  }),
  caption: [Die App erreicht die Datenbank über ihren Namen `db`. Nur die App hat einen veröffentlichten Port.],
)

Das ist das Grundmuster fast jeder Anwendung: Alle zusammengehörigen Container teilen sich ein eigenes Netz und sprechen sich mit Namen an. Nur der Container, der von außen erreichbar sein muss, veröffentlicht einen Port. Die Datenbank bleibt intern. Docker Compose legt ein solches Netz pro Projekt automatisch an (Kapitel 7).

#achtung[Innerhalb eines Containers bedeutet `localhost` *der Container selbst*, nicht der Host und nicht ein anderer Container. `DATABASE_URL=...@localhost:5432` funktioniert deshalb in Docker nicht, obwohl es ohne Docker klappte. Richtig ist der Name des Datenbank-Containers.]

== Ports veröffentlichen

`-p Host-Port:Container-Port` leitet Verbindungen zu einem Port des Hosts an den Container weiter. Dabei zählt auch die Adresse:

#table(columns: (auto, 1fr),
  [Angabe], [Erreichbar von],
  [`-p 8000:8000`], [*allen* Netzwerkschnittstellen des Hosts, also auch aus dem Internet, falls der Host dort hängt],
  [`-p 127.0.0.1:8000:8000`], [nur vom Host selbst. Richtig für Dienste hinter einem Reverse Proxy und für Datenbanken, die man lokal mit einem GUI-Werkzeug ansehen will.],
  [`-p 8080:80`], [Host-Port 8080 wird auf Port 80 im Container geleitet. Die Nummern müssen nicht gleich sein.],
)

Eine zweite, häufige Ursache für "nicht erreichbar" liegt in der Anwendung selbst: Sie muss im Container auf `0.0.0.0` lauschen, nicht auf `127.0.0.1`. Ein Server, der nur auf `127.0.0.1` lauscht, nimmt ausschließlich Verbindungen aus dem Container selbst an, und die Weiterleitung von Docker kommt nie an. `fastapi run` lauscht bereits auf `0.0.0.0`, `uvicorn` dagegen standardmäßig auf `127.0.0.1`, dort ist `--host 0.0.0.0` nötig.

#achtung[*Veröffentlichte Ports umgehen die Firewall `ufw`.* Auf Linux-Servern trägt Docker eigene Regeln in die Paketfilter des Kernels ein, die vor den Regeln von `ufw` greifen. Ein `-p 5432:5432` macht die Datenbank deshalb aus dem Internet erreichbar, auch wenn `ufw` Port 5432 angeblich sperrt. Abhilfe: Dienste nur an `127.0.0.1` binden und über einen Reverse Proxy veröffentlichen (Kapitel 13), zusätzlich die Firewall des Hosting-Anbieters nutzen.]

== Vom Container zum Host

Manchmal muss ein Container einen Dienst erreichen, der direkt auf dem Host läuft, etwa eine lokal installierte Datenbank. Für `--add-host` bietet Docker den besonderen Wert `host-gateway`, der auf die Adresse des Hosts zeigt. Der frei gewählte Hostname links davon lautet im Beispiel `host.docker.internal`:

```bash
docker run --rm --add-host=host.docker.internal:host-gateway alpine \
  wget -qO- http://host.docker.internal:8080
```

Docker Desktop richtet `host.docker.internal` automatisch ein, auf Linux-Servern braucht es das `--add-host` (in Compose: `extra_hosts`). Aktuelle Colima-Versionen stellen den Namen ebenfalls bereit; bei älteren Profilen und besonderen Netzwerkmodi kann das Verhalten abweichen. Am portabelsten ist es, auch den Zieldienst als Container im selben Netz zu betreiben.

== Netzwerktreiber

#table(columns: (auto, 1fr),
  [Treiber], [Verwendung],
  [`bridge`], [Standard. Eigenes, privates Netz auf einem Host. Für fast alles richtig.],
  [`host`], [Container nutzt direkt das Netz des Hosts, ohne Isolation und ohne `-p`. Nur auf Linux sinnvoll, am Mac ist "Host" die VM.],
  [`none`], [kein Netzwerk, etwa für reine Rechenjobs],
  [`overlay`], [Netz über mehrere Hosts hinweg, nur mit Swarm (Kapitel 15)],
)

== Netzwerke untersuchen

```bash
docker network ls
docker network inspect notizen-netz                  # welche Container mit welcher IP
docker run --rm -it --network notizen-netz nicolaka/netshoot   # Werkzeugkasten im selben Netz
```

Das Image `nicolaka/netshoot` enthält alle üblichen Netzwerkwerkzeuge (`dig`, `curl`, `nc`, `ping`, `tcpdump`). In dasselbe Netz gestartet, lässt sich damit prüfen, ob ein Name aufgelöst wird (`dig db`) und ob ein Port antwortet (`nc -zv db 5432`), ohne die eigenen Images mit Werkzeugen zu belasten.

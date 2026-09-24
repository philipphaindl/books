#import "lib.typ": *
#set heading(numbering: none)
= Bevor es losgeht

Dieses Handbuch ist das Gegenstück zu "Git von Grund auf" und folgt demselben Prinzip: erst ein belastbares mentales Modell, dann die Befehle, dann der Betrieb. Wer Docker bisher vor allem über kopierte `docker run`-Zeilen und fremde `compose.yaml`-Dateien kennt, stößt früher oder später auf Fragen wie: Warum sind meine Daten nach einem Update weg? Warum startet das Image am Server nicht, obwohl es am Mac lief? Warum erreicht der Container die Datenbank nicht? Die Antworten ergeben sich fast immer aus wenigen Grundbegriffen.

== Aufbau

- *Teil I, Grundlagen:* was ein Container technisch ist, Docker am Mac rein über die Kommandozeile (Colima statt Docker Desktop), Container bedienen und das erste Dockerfile.
- *Teil II, Zusammenspiel:* Daten und Volumes, Netzwerke, Docker Compose, schlanke und sichere Images, Builds für ARM und x86, systematische Fehlersuche.
- *Teil III, Betrieb:* Registry in Gitea, Sicherheit, Betrieb auf einem Linux-Server mit Reverse Proxy, Updates und Backups, Builds und Deployment mit Gitea Actions sowie eine Einordnung von Swarm und Kubernetes.
- *Anhang:* Befehlsübersicht und Glossar.

Für Gitea, Pull Requests, Runner, Secrets und SSH-Deployment verweist dieses Buch auf das Git-Handbuch (dort Kapitel 12 bis 15), statt alles zu wiederholen.

== Konventionen

Befehle stehen in grauen Kästen, Ausgaben in gestrichelten, Dateiinhalte tragen den Dateinamen als Reiter. In den Grafiken haben Farben eine feste Bedeutung:

#align(center, cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let leg = (([Image / Schicht], c-blue), ([Container], c-accent), ([Volume / Daten], c-yellow), ([Netzwerk], c-teal), ([Registry / Gitea], c-gitea), ([Host / VM], c-grey))
  for (i, l) in leg.enumerate() {
    let x = calc.rem(i, 3) * 5.0
    let y = -calc.floor(i / 3) * 0.75
    rect((x, y - 0.22), (x + 0.6, y + 0.22), radius: 0.06, fill: l.at(1).lighten(86%), stroke: (paint: l.at(1), thickness: 0.8pt))
    content((x + 0.8, y), anchor: "west", text(size: 8pt, l.at(0)))
  }
}))

Als durchgängiges Beispiel dient das Projekt `notizen`: eine kleine REST-API mit FastAPI, die Notizen in PostgreSQL speichert. Abhängigkeiten verwaltet `uv`. Es ist bewusst klein, enthält aber alles, was in echten Projekten vorkommt: eine Anwendung, eine Datenbank mit persistenten Daten, Konfiguration über Umgebungsvariablen, Geheimnisse, Migrationen und Tests.

#datei("Projektstruktur")[
```text
notizen/
├── app/
│   ├── __init__.py
│   ├── main.py            # FastAPI-Anwendung
│   └── db.py              # Datenbankverbindung
├── tests/
├── pyproject.toml         # Abhängigkeiten
├── uv.lock                # exakt festgelegte Versionen
├── Dockerfile
├── .dockerignore
├── compose.yaml           # Entwicklung: api + db
└── compose.prod.yaml      # Produktion (liegt auf dem Server als compose.yaml)
```
]

Server heißen wie im Git-Handbuch `gitea.example.com` (Gitea mit Container-Registry) und `app.example.com` (Zielserver). Getestete Basis dieses Handbuchs sind Docker Engine 29.8 und Docker Compose 5.5 im September 2026. Die gezeigten Grundfunktionen funktionieren auch mit aktuellen Compose-v2-Versionen; neuere Funktionen sind im Text ausdrücklich gekennzeichnet. Der Befehl heißt weiterhin `docker compose` (mit Leerzeichen). Das alte, separate Programm `docker-compose` mit Bindestrich ist veraltet.

#import "lib.typ": *

= Fehlersuche

Die meisten Docker-Probleme lassen sich mit einem immer gleichen Vorgehen eingrenzen. Wer die Schritte in dieser Reihenfolge abarbeitet, findet die Ursache fast immer, bevor er im Internet suchen muss.

== Das Vorgehen

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let s = (
      ([*1 Status* \ `compose ps`], c-dark),
      ([*2 Logs* \ `compose logs`], c-dark),
      ([*3 Konfiguration* \ `compose config`], c-dark),
      ([*4 Inspizieren* \ `docker inspect`], c-dark),
      ([*5 Hineinsehen* \ `exec` / `run sh`], c-accent),
    )
    for (i, e) in s.enumerate() {
      kasten((i * 3.1, 0), e.at(0), w: 2.6, h: 1.05, bg: if i == 4 { rgb("#FDF1EC") } else { white }, col: e.at(1), size: 7.3pt)
      if i < 4 { pfeil((i * 3.1 + 1.33, 0), (i * 3.1 + 1.77, 0)) }
    }
  }),
  caption: [Von außen nach innen: erst schauen, was Docker meldet, dann in den Container hinein.],
)

+ *Status:* Läuft der Container, ist er neu gestartet worden (`Restarting`), beendet (`Exited (1)`) oder ungesund (`unhealthy`)? `docker compose ps -a` zeigt auch beendete Container.
+ *Logs:* Die letzte Fehlermeldung der Anwendung steht fast immer in `docker compose logs --tail 50 api`. Das löst die Mehrzahl aller Fälle.
+ *Konfiguration:* `docker compose config` zeigt, was nach dem Einsetzen aller Variablen tatsächlich gilt. Fehlende Werte, falsche Pfade und Tippfehler in Variablennamen fallen hier auf.
+ *Inspizieren:* `docker inspect` liefert den Zustand im Detail, etwa Exit-Code, Grund des Abbruchs, Healthcheck-Ergebnisse, Mounts und Netzwerke.
+ *Hineinsehen:* Mit einer Shell im Container prüfen, ob Dateien, Rechte, Umgebungsvariablen und Netzwerkverbindungen so sind wie erwartet.

```bash
docker inspect api --format '{{.State.Status}} {{.State.ExitCode}} OOM={{.State.OOMKilled}}'
docker inspect api --format '{{json .State.Health}}' | python3 -m json.tool
docker compose exec api env | sort                        # Umgebung im laufenden Container
docker compose run --rm --entrypoint sh api               # Shell trotz Absturz der App
docker events --since 10m                                 # was hat der Daemon zuletzt getan?
```

Der vorletzte Befehl ist der wichtigste Trick bei Containern, die sofort abstürzen: `exec` geht dann nicht, weil der Container nicht läuft. `run --entrypoint sh` startet stattdessen einen neuen Container aus demselben Image mit einer Shell statt der Anwendung. Darin lässt sich der Startbefehl von Hand ausführen und die Fehlermeldung in Ruhe lesen.

== Exit-Codes lesen

#table(columns: (auto, 1fr),
  [Code], [Bedeutung],
  [`0`], [Der Prozess hat sich regulär beendet. Bei einem Dienst heißt das oft: Er hatte nichts zu tun (falscher Befehl, Programm läuft nicht im Vordergrund).],
  [`1`], [Allgemeiner Fehler der Anwendung, Details in den Logs.],
  [`125`], [Docker selbst konnte den Container nicht starten (ungültige Option, Port belegt).],
  [`126`], [Startbefehl gefunden, aber nicht ausführbar (fehlende Rechte).],
  [`127`], [Startbefehl nicht gefunden (Tippfehler, falscher `PATH`, Programm nicht im Image).],
  [`137`], [Mit SIGKILL beendet: Speicherlimit überschritten (`OOMKilled=true`) oder `docker stop` lief in den Timeout.],
  [`139`], [Speicherzugriffsfehler (`SIGSEGV`): typischerweise Fehler in nativem Code oder inkompatible Bibliothek. Eine falsche CPU-Architektur meldet meist `exec format error`.],
  [`143`], [Mit SIGTERM beendet, der Normalfall nach `docker stop`.],
)

== Häufige Probleme

#table(columns: (1fr, 1.35fr),
  [Symptom], [Ursache und Lösung],
  [_Cannot connect to the Docker daemon_], [Colima läuft nicht (`colima start`) oder der falsche Kontext ist aktiv (`docker context ls`).],
  [_port is already allocated_], [Ein anderer Container oder Prozess nutzt den Host-Port. `docker ps` bzw. `lsof -i :8000` am Mac.],
  [App erreicht die Datenbank nicht], [`localhost` statt Dienstname verwendet, Container in verschiedenen Netzen, oder die DB war beim Start noch nicht bereit (Healthcheck plus `service_healthy`).],
  [Port von außen nicht erreichbar], [Anwendung lauscht im Container auf `127.0.0.1` statt `0.0.0.0`, oder `-p` fehlt bzw. ist an `127.0.0.1` gebunden.],
  [Daten nach Update weg], [Kein oder ein anonymes Volume, falscher Pfad (PostgreSQL 18: `/var/lib/postgresql`), oder `down -v` verwendet.],
  [Code-Änderung wirkt nicht], [Image nicht neu gebaut (`up -d --build`) oder alter Container läuft noch, weil `restart` statt `up -d` verwendet wurde.],
  [_exec format error_], [Image für die falsche Architektur gebaut (Kapitel 9).],
  [_permission denied_ auf Dateien], [Prozess läuft als Benutzer `app`, Dateien gehören `root` (Bind Mount oder `COPY` ohne `--chown`).],
  [Container startet immer wieder neu], [Absturz beim Start plus `restart: unless-stopped`. Logs lesen, zur Diagnose vorübergehend `restart: "no"`.],
  [_no space left on device_], [Platte der VM bzw. des Servers voll: `docker system df`, dann aufräumen (Kapitel 3). Bei Colima eventuell die Disk vergrößern.],
  [Build ignoriert Änderungen], [Schicht-Cache greift unerwartet, etwa bei `RUN git clone` oder heruntergeladenen Dateien. `docker build --no-cache` erzwingt einen vollständigen Neubau.],
)

#tipp[Viele Images haben keine Werkzeuge wie `ps`, `curl` oder `ping`. Statt sie ins Image einzubauen, startet man einen Werkzeug-Container im selben Netz (`nicolaka/netshoot`, Kapitel 6) oder für Prozess- und Netzsicht mit `docker run --rm -it --pid container:api --network container:api nicolaka/netshoot`. Das teilt nicht das Dateisystem der Anwendung. Dateien sieht man nur über explizite Mounts, `--volumes-from` oder - mit ausreichenden Rechten - über `/proc/<PID>/root`.]

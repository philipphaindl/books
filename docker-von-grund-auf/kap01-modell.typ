#import "lib.typ": *

= Das mentale Modell

Docker wirkt wie eine leichte virtuelle Maschine, ist aber etwas grundlegend anderes. Viele Stolpersteine, etwa verschwundene Daten, unerreichbare Ports oder Images, die auf dem Server nicht starten, lösen sich auf, sobald man das Modell dahinter kennt. Es besteht aus vier Begriffen: *Image*, *Container*, *Registry* und dem *Docker-Daemon*.

== Das Problem, das Docker löst

Eine Anwendung braucht mehr als ihren Quellcode: eine bestimmte Python-Version, Systembibliotheken, Python-Pakete in exakten Versionen, Konfiguration. Auf dem eigenen Mac ist all das irgendwann über Monate gewachsen, auf dem Server anders, beim Kollegen wieder anders. Das Ergebnis ist der Klassiker "läuft bei mir".

Docker verpackt die Anwendung mit ihren Benutzerland-Bibliotheken und Werkzeugen in ein Image. Kernel, CPU-Architektur und einige Host-Funktionen kommen weiterhin vom Zielsystem. Innerhalb einer unterstützten Plattform läuft dasselbe Image deshalb weitgehend gleich: am Mac, im CI-Runner und auf dem Produktionsserver. Die Laufzeitumgebung wird damit zu einem versionierbaren Artefakt statt zu schwer nachvollziehbarem Zustand eines Rechners.

== Container sind keine virtuellen Maschinen

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    content((2.3, 3.7), text(size: 8pt, weight: "bold")[Virtuelle Maschinen])
    stapel((2.3, 0), (([Hardware], c-grey), ([Host-Betriebssystem], c-grey), ([Hypervisor], c-grey)), w: 4.6, h: 0.5)
    stapel((1.15, 1.65), (([Gast-OS mit Kernel], c-violet), ([Bibliotheken], c-blue), ([App A], c-accent)), w: 2.25, h: 0.5, size: 6.8pt)
    stapel((3.45, 1.65), (([Gast-OS mit Kernel], c-violet), ([Bibliotheken], c-blue), ([App B], c-accent)), w: 2.25, h: 0.5, size: 6.8pt)
    content((10.4, 3.7), text(size: 8pt, weight: "bold")[Container])
    stapel((10.4, 0), (([Hardware], c-grey), ([Linux (ein gemeinsamer Kernel)], c-grey), ([Container-Runtime], c-grey)), w: 5.6, h: 0.5)
    stapel((8.5, 1.65), (([Bibliotheken], c-blue), ([App A], c-accent)), w: 1.8, h: 0.5, size: 6.8pt)
    stapel((10.4, 1.65), (([Bibliotheken], c-blue), ([App B], c-accent)), w: 1.8, h: 0.5, size: 6.8pt)
    stapel((12.3, 1.65), (([Bibliotheken], c-blue), ([App C], c-accent)), w: 1.8, h: 0.5, size: 6.8pt)
  }),
  caption: [Eine VM bringt ein komplettes Betriebssystem mit eigenem Kernel mit. Container teilen sich den Kernel des Hosts.],
)

Eine virtuelle Maschine emuliert einen ganzen Rechner, inklusive eigenem Betriebssystem-Kernel. Sie braucht Sekunden bis Minuten zum Starten und reserviert Arbeitsspeicher für ein komplettes System. Ein Container dagegen ist *ein ganz normaler Prozess auf dem Linux-Host*, den der Kernel so abschottet, dass er glaubt, allein zu sein. Er startet in Millisekunden und braucht nur so viel Speicher wie die Anwendung selbst.

== Was ein Container technisch ist

Drei Kernel-Mechanismen machen aus einem Prozess einen Container:

#table(columns: (auto, 1fr),
  [Mechanismus], [Wirkung],
  [*Namespaces*], [Eigene Sicht auf das System: eigene Prozessliste (der Hauptprozess hat PID 1), eigenes Netzwerk mit eigener IP, eigene Mount-Punkte, eigener Hostname, optional eigene Benutzer-IDs.],
  [*cgroups*], [Begrenzung und Messung von Ressourcen: CPU, Arbeitsspeicher, Anzahl der Prozesse, Ein-/Ausgabe.],
  [*Eigenes Dateisystem*], [Der Prozess sieht als Wurzelverzeichnis `/` nicht das Dateisystem des Hosts, sondern den Inhalt des Images.],
)

Daraus folgen drei Eigenschaften, die man im Alltag ständig braucht:

+ *Ein Container lebt genau so lange wie sein Hauptprozess.* Beendet sich der Prozess (weil das Programm fertig ist oder abstürzt), ist der Container beendet. Ein Container ohne dauerhaft laufenden Prozess "startet und ist sofort wieder weg".
+ *Container brauchen einen Linux-Kernel.* Auf macOS gibt es keinen, deshalb läuft Docker am Mac immer in einer kleinen Linux-VM (Kapitel 2).
+ *Die Isolation ist gut, aber nicht so stark wie bei einer VM.* Alle Container teilen sich einen Kernel. Wer im Container Root-Rechte hat und aus ihm ausbricht, steht auf dem Host (Kapitel 12).

== Image und Container

Das wichtigste Begriffspaar: Ein *Image* ist eine unveränderliche Vorlage, ein *Container* ist eine laufende (oder gestoppte) Instanz davon. Die Beziehung entspricht der zwischen Klasse und Objekt: Aus einem Image lassen sich beliebig viele Container starten.

Ein Image besteht aus übereinander liegenden, schreibgeschützten *Schichten* (_layers_). Jede Anweisung im Dockerfile, die Dateien verändert, erzeugt eine Schicht. Startet man einen Container, legt Docker darüber eine dünne, beschreibbare Schicht, die nur diesem Container gehört.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    stapel((0, 0), (([`FROM python:3.14-slim`], c-blue), ([`uv sync` (Abhängigkeiten)], c-blue), ([`COPY app/`], c-blue)), w: 4.4)
    content((0, 1.85), text(size: 7.5pt, weight: "bold", fill: c-blue.darken(20%))[Image `notizen` (schreibgeschützt)])
    stapel((6.2, 0), (([], c-blue), ([], c-blue), ([], c-blue), ([Schreibschicht A], c-accent, true)), w: 2.6)
    stapel((9.4, 0), (([], c-blue), ([], c-blue), ([], c-blue), ([Schreibschicht B], c-accent, true)), w: 2.6)
    content((6.2, 2.35), text(size: 7.5pt, weight: "bold", fill: c-accent.darken(15%))[Container A])
    content((9.4, 2.35), text(size: 7.5pt, weight: "bold", fill: c-accent.darken(15%))[Container B])
    pfeil((2.3, 0.75), (4.8, 0.75), label: "docker run", loff: (0, 0.22))
    content((7.8, -0.45), text(size: 7pt, fill: c-grey.darken(20%), style: "italic")[die Image-Schichten werden geteilt, nicht kopiert])
  }),
  caption: [Beide Container teilen sich die Schichten des Images. Jeder hat seine eigene Schreibschicht.],
)

Ändert ein Container eine Datei aus dem Image, kopiert Docker sie zuerst in seine Schreibschicht (_copy-on-write_). Das Image selbst bleibt unverändert. Daraus folgt die wichtigste Regel für den Umgang mit Daten:

#merke[Die Schreibschicht wird zusammen mit dem Container gelöscht. Alles, was einen Neustart mit neuem Image überleben soll (Datenbankdateien, Uploads), gehört in ein *Volume* (Kapitel 5). Container sind Wegwerfware, Daten nicht.]

== Registry, Namen, Tags und Digests

Images werden in einer *Registry* gespeichert und von dort geladen: Docker Hub ist die Standard-Registry, Gitea bringt eine eigene mit (Kapitel 11). Ein vollständiger Image-Name besteht aus mehreren Teilen:

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let teile = (
      ("gitea.example.com", c-gitea, "Registry"),
      ("/team", c-grey, "Namespace"),
      ("/notizen", c-blue, "Repository"),
      (":1.4.0", c-accent, "Tag"),
      ("@sha256:9f3c…", c-violet, "Digest"),
    )
    let x = 0
    for t in teile {
      let w = t.at(0).len() * 0.19 + 0.3
      rect((x, 0), (x + w, 0.6), radius: 0.06, fill: t.at(1).lighten(86%), stroke: (paint: t.at(1), thickness: 0.8pt))
      content((x + w / 2, 0.3), text(font: "JetBrains Mono", size: 8pt, weight: "bold", t.at(0)))
      content((x + w / 2, -0.3), text(size: 7pt, fill: t.at(1).darken(25%), t.at(2)))
      x += w + 0.08
    }
  }),
  caption: [Aufbau eines Image-Namens. Fehlt die Registry, ist Docker Hub gemeint.],
)

Kurzformen werden ergänzt: `python:3.14-slim` bedeutet vollständig `docker.io/library/python:3.14-slim`. Fehlt der Tag, nimmt Docker `latest`.

Wer das Git-Handbuch kennt, findet hier eine vertraute Unterscheidung wieder: Ein *Tag* ist ein beweglicher Name wie ein Branch. `python:3.14-slim` zeigt heute auf ein anderes Image als in drei Monaten, weil Sicherheitsupdates eingespielt werden. Ein *Digest* (`@sha256:…`) ist dagegen die Prüfsumme des Inhalts, unveränderlich wie ein Commit-Hash. Wer exakt reproduzierbar bauen will, pinnt auf den Digest und aktualisiert ihn kontrolliert.

#achtung[`latest` bedeutet nicht "neueste Version", sondern nur "der Tag, der verwendet wird, wenn keiner angegeben ist". Was sich dahinter verbirgt, entscheidet der Herausgeber. In Produktion und in Dockerfiles immer eine konkrete Version angeben.]

== Die Architektur hinter dem `docker`-Befehl

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [`docker` \ #text(size: 6.5pt)[CLI (Client)]], w: 1.8, h: 1.0)
    rahmen((3.4, -1.3), (15.3, 1.4), [Linux (am Mac: in der VM)], c-grey)
    kasten((5.0, -0.1), [`dockerd` \ #text(size: 6.5pt)[Docker-Daemon]], w: 2.2, h: 1.0, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((8.3, -0.1), [`containerd` \ #text(size: 6.5pt)[Container-Verwaltung]], w: 2.6, h: 1.0, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((11.4, -0.1), [`runc` \ #text(size: 6.5pt)[startet Prozess]], w: 1.9, h: 1.0, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((14.1, -0.1), [Container- \ prozess], w: 1.8, h: 1.0, bg: rgb("#FDF1EC"), col: c-accent)
    pfeil((0.95, 0), (3.85, 0), label: "API über Socket", loff: (-0.25, 0.24))
    pfeil((6.15, -0.1), (6.95, -0.1)); pfeil((9.65, -0.1), (10.4, -0.1)); pfeil((12.4, -0.1), (13.15, -0.1))
  }),
  caption: [Der `docker`-Befehl ist nur ein Client. Die eigentliche Arbeit erledigt der Daemon.],
)

Das Programm `docker`, das du im Terminal aufrufst, ist nur ein *Client*. Es schickt jeden Befehl über eine Programmierschnittstelle an den *Docker-Daemon* `dockerd`, der Images verwaltet, Netzwerke und Volumes anlegt und Container über `containerd` und `runc` startet. Die Verbindung läuft über einen Unix-Socket (auf Linux `/var/run/docker.sock`).

Das erklärt zwei Dinge. Erstens kann der Client auf einem anderen Rechner laufen als der Daemon: am Mac läuft der Client unter macOS, der Daemon in der Linux-VM. Zweitens ist *Zugriff auf den Socket gleichbedeutend mit Root-Rechten* auf dem Rechner des Daemons, denn wer Container starten darf, kann beliebige Verzeichnisse des Hosts einbinden (Kapitel 12).

#merke[Das Modell in fünf Sätzen: *(1)* Ein Container ist ein abgeschotteter Linux-Prozess. *(2)* Er entsteht aus einem unveränderlichen, geschichteten Image. *(3)* Seine eigenen Änderungen landen in einer Schreibschicht, die mit ihm verschwindet. *(4)* Images liegen in Registries und werden über Name, Tag oder Digest angesprochen. *(5)* Der `docker`-Befehl ist nur ein Client für den Daemon.]

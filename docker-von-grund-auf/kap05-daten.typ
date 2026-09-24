#import "lib.typ": *

= Daten: Volumes und Bind Mounts

Aus Kapitel 1 ist klar: Die Schreibschicht eines Containers verschwindet mit ihm. Bei jedem Update wird ein Container aber gerade gelöscht und aus dem neuen Image neu erzeugt. Alles, was bleiben soll, muss deshalb *außerhalb* des Containers liegen und nur hineingereicht werden. Dafür gibt es drei Mechanismen.

== Drei Arten, Daten einzubinden

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    rahmen((0, -2.3), (15.2, 1.8), [Host (am Mac: die Linux-VM)], c-grey, bg: luma(250))
    rahmen((4.6, -0.9), (10.6, 1.35), [Container], c-accent)
    kasten((5.9, 0.2), [`/var/lib/` \ `postgresql`], w: 2.0, h: 0.8, size: 6.8pt)
    kasten((7.6, 0.2), [`/app/app`], w: 1.3, h: 0.8, size: 6.8pt)
    kasten((9.4, 0.2), [`/tmp`], w: 1.4, h: 0.8, size: 6.8pt)
    kasten((1.9, -1.6), [*Volume* `pgdaten` \ #text(size: 6.3pt)[von Docker verwaltet]], w: 3.2, h: 0.9, bg: rgb("#FFF8E6"), col: c-yellow, size: 7.3pt)
    kasten((7.6, -1.6), [*Bind Mount* \ #text(size: 6.3pt)[`~/projekte/notizen/app`]], w: 3.0, h: 0.9, bg: rgb("#FFF8E6"), col: c-yellow, size: 7.3pt)
    kasten((12.9, -1.6), [*tmpfs* \ #text(size: 6.3pt)[nur im Arbeitsspeicher]], w: 3.0, h: 0.9, bg: rgb("#FFF8E6"), col: c-yellow, size: 7.3pt)
    line((3.5, -1.3), (5.9, -0.2), stroke: (paint: c-yellow.darken(10%), thickness: 0.9pt))
    line((7.6, -1.15), (7.6, -0.2), stroke: (paint: c-yellow.darken(10%), thickness: 0.9pt))
    line((11.4, -1.3), (9.4, -0.2), stroke: (paint: c-yellow.darken(10%), thickness: 0.9pt))
  }),
  caption: [Ein Container, drei Arten eingebundener Daten.],
)

#table(columns: (auto, 1fr, 1fr),
  [Art], [Eigenschaften], [Typische Verwendung],
  [*Volume*], [Von Docker verwaltet. Beim lokalen rootful Treiber liegt es typischerweise unter `/var/lib/docker/volumes`; Rootless-Betrieb, VM und andere Volume-Treiber können andere Pfade nutzen.], [Datenbanken, Uploads: alles Persistente in Produktion],
  [*Bind Mount*], [Ein beliebiges Verzeichnis des Hosts wird direkt eingeblendet. Änderungen sind sofort auf beiden Seiten sichtbar.], [Quellcode während der Entwicklung, Konfigurationsdateien],
  [*tmpfs*], [Nur im Arbeitsspeicher, verschwindet beim Stopp.], [temporäre Dateien, die nicht auf die Platte sollen],
)

== Volumes

```bash
docker volume create pgdaten           # anlegen (passiert bei -v auch automatisch)
docker volume ls                       # alle Volumes
docker volume inspect pgdaten          # Details, u.a. Pfad auf dem Host
docker volume rm pgdaten               # löschen (nur wenn kein Container es nutzt)

docker run -d --name db -v pgdaten:/var/lib/postgresql -e POSTGRES_PASSWORD=geheim postgres:18
# ausführlichere, gleichwertige Schreibweise:
docker run -d --name db --mount type=volume,src=pgdaten,dst=/var/lib/postgresql ... postgres:18
```

Die Syntax `-v a:b` ist mehrdeutig: Beginnt `a` mit `/` oder `.`, ist es ein Bind Mount, sonst ein Volume-Name. `--mount` ist länger, aber eindeutig und meldet einen Fehler, wenn ein Host-Pfad nicht existiert, statt stillschweigend ein leeres Verzeichnis anzulegen.

=== Anonyme Volumes

Viele Images deklarieren mit `VOLUME` im Dockerfile einen Pfad für Daten. Bindet man dort nichts ein, legt Docker automatisch ein *anonymes* Volume mit einem Zufallsnamen an. Die Daten sind dann zwar da, aber nach dem Neuerzeugen des Containers hängt ein *neues* anonymes Volume an diesem Pfad, und die alten Daten liegen verwaist in einem Volume namens `3f9a0c…`. Daher gilt: Für persistente Daten immer ein *benanntes* Volume angeben.

#achtung[*PostgreSQL 18 hat den Datenpfad geändert.* Bis Version 17 bindet man das Volume an `/var/lib/postgresql/data`. Ab dem offiziellen Image für Version 18 liegt das Datenverzeichnis unter `/var/lib/postgresql/18/docker`, das deklarierte Volume ist `/var/lib/postgresql`. Wer bei `postgres:18` wie gewohnt `/var/lib/postgresql/data` einbindet, bekommt Fehlermeldungen oder Daten, die beim Neuerzeugen verloren gehen. Also: bei 18+ an `/var/lib/postgresql` einbinden. Ein Wechsel der Hauptversion (17 -> 18) passiert zudem nie automatisch durch einen neuen Tag: Dafür ist ein Dump und Restore (siehe unten) oder `pg_upgrade` nötig.]

== Bind Mounts in der Entwicklung

Beim Entwickeln will man den Code nicht nach jeder Änderung neu bauen. Ein Bind Mount blendet das Projektverzeichnis direkt in den Container ein, zusammen mit einem Server, der bei Änderungen neu lädt:

```bash
docker run --rm -p 8000:8000 \
  -v "$PWD/app:/app/app" \
  notizen:dev fastapi dev app/main.py --host 0.0.0.0 --port 8000
```

Mit `:ro` am Ende (`-v "$PWD/config.toml:/app/config.toml:ro"`) ist der Mount im Container schreibgeschützt, was sich für Konfigurationsdateien empfiehlt. Komfortabler löst Compose das Thema mit `develop: watch` (Kapitel 7).

#praxis[Auf Linux-Servern haben Mounts eine typische Falle: Dateien, die ein Container als `root` anlegt, gehören auf dem Host ebenfalls `root`, und ein Prozess, der im Container als Benutzer mit UID 1000 läuft, darf ein Verzeichnis von UID 1001 nicht beschreiben. Benutzer-IDs sind im Container und auf dem Host dieselben Zahlen, die Namen können sich unterscheiden. Am Mac übersetzt virtiofs einen Teil dieser Unterschiede, deshalb fällt das Problem oft erst auf dem Server auf. Auch ein neues benanntes Volume ist nicht automatisch für den Anwendungsbenutzer beschreibbar: Das Image muss es beim Start initialisieren, der Administrator muss Besitzer und Modus passend setzen, oder Host und Container verwenden abgestimmte UID/GID.]

== Sichern und Wiederherstellen

Für Datenbanken ist ein logischer Dump die sichere Wahl, weil er einen konsistenten Stand liefert, während die Datenbank weiterläuft:

```bash
# Sichern (Custom-Format, komprimiert)
docker exec db pg_dump -U notizen -Fc notizen > notizen-$(date +%F).dump

# Wiederherstellen in eine laufende, leere oder zu überschreibende Datenbank
docker exec -i db pg_restore -U notizen -d notizen --clean --if-exists < notizen-2026-09-24.dump
```

Beliebige Volumes lassen sich mit einem kurzlebigen Hilfscontainer als Archiv sichern. Der Trick: Beide, das Volume und ein Verzeichnis des Hosts, werden in einen Wegwerf-Container eingebunden, der nur `tar` ausführt:

```bash
# Sichern: Volume "uploads" nach ./uploads.tgz
docker run --rm -v uploads:/daten:ro -v "$PWD":/backup alpine \
  tar czf /backup/uploads.tgz -C /daten .

# Wiederherstellen
docker run --rm -v uploads:/daten -v "$PWD":/backup alpine \
  tar xzf /backup/uploads.tgz -C /daten
```

#achtung[Die Dateien einer *laufenden* Datenbank per `tar` zu kopieren, ergibt ein inkonsistentes Backup, das sich eventuell nicht wiederherstellen lässt. Entweder die Datenbank vorher stoppen oder, besser, `pg_dump` verwenden. Und ein Backup, dessen Wiederherstellung nie getestet wurde, ist nur eine Hoffnung.]

`pg_dump` sichert eine einzelne Datenbank. Globale Objekte wie Rollen und Tablespaces sind darin nicht enthalten; falls sie nicht anderweitig als Konfiguration vorliegen, werden sie zusätzlich mit `pg_dumpall --globals-only` gesichert. Produktionsbackups gehören verschlüsselt auf einen zweiten Rechner und werden regelmäßig probeweise wiederhergestellt.

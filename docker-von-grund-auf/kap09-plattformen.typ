#import "lib.typ": *

= ARM und x86: Builds für mehrere Plattformen

Ein Mac mit Apple Silicon ist ein ARM-Rechner (`arm64`), die meisten Server und CI-Runner sind x86-Rechner (`amd64`). Ein Image enthält Maschinencode für genau eine dieser Architekturen. Wer am Mac baut und das Ergebnis auf den Server schiebt, bekommt dort eine knappe Fehlermeldung:

```out
exec /app/.venv/bin/fastapi: exec format error
```

Das heißt: Das Programm im Image ist für eine andere Prozessorarchitektur übersetzt. Bei Python betrifft das vor allem das Basis-Image und Pakete mit kompiliertem Code (etwa `psycopg[binary]`).

== Plattform gezielt wählen

```bash
uname -m                                         # am Mac: arm64
docker image inspect notizen:dev --format '{{.Os}}/{{.Architecture}}'   # linux/arm64

docker build --platform linux/amd64 -t notizen:amd64 .     # für x86 bauen (emuliert)
docker run --rm --platform linux/amd64 notizen:amd64 uname -m   # x86_64
```

Am Mac übernimmt Rosetta (Kapitel 2) oder QEMU die Emulation. Das funktioniert zuverlässig, ist aber spürbar langsamer als ein nativer Build, bei großen Kompilierungen um ein Vielfaches.

== Ein Name, mehrere Plattformen

Offizielle Images wie `python:3.14-slim` gibt es für viele Architekturen unter *einem* Namen. Dahinter steckt ein _Image-Index_ (auch _Manifest List_): Der Tag zeigt auf eine Liste, und Docker lädt automatisch die Variante, die zum eigenen Rechner passt.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [`notizen:1.4.0`], w: 2.6, h: 0.7, bg: rgb("#EEF6E6"), col: c-gitea)
    kasten((4.2, 0), [Image-Index \ #text(size: 6.5pt)[Liste der Varianten]], w: 2.6, h: 0.95, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((9.4, 0.75), [Image `linux/amd64` \ #text(size: 6.5pt)[für Server, CI]], w: 3.2, h: 0.95, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((9.4, -0.75), [Image `linux/arm64` \ #text(size: 6.5pt)[für den Mac]], w: 3.2, h: 0.95, bg: rgb("#EAF1FB"), col: c-blue)
    pfeil((1.3, 0), (2.9, 0))
    pfeil((5.5, 0.15), (7.8, 0.75)); pfeil((5.5, -0.15), (7.8, -0.75))
    content((13.2, 0), text(size: 6.8pt, fill: c-grey.darken(20%), style: "italic")[`docker pull` wählt \ passend zum Rechner])
  }),
  caption: [Ein Tag kann auf einen Index zeigen, der je eine Variante pro Architektur enthält.],
)

Eigene Multi-Plattform-Images baut `docker buildx`. Bei frischen Installationen ab Docker Engine 29 ist der containerd Image Store Standard und kann einen mehrplattformigen Index auch lokal verwalten. Aktualisierte Installationen können weiterhin den klassischen Image-Speicher nutzen; dieser kann solche Indizes nicht lokal laden. Ein `docker-container`-Builder mit direktem Push funktioniert in beiden Fällen und ist daher für CI gut geeignet:

```bash
docker buildx create --name multi --driver docker-container --use    # einmalig
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t gitea.example.com/team/notizen:1.4.0 \
  --push .
docker buildx imagetools inspect gitea.example.com/team/notizen:1.4.0   # Varianten prüfen
```

== Empfehlung für die Praxis

- *Am Mac* nativ für `arm64` bauen und testen. Das ist schnell und deckt fast alle Fehler ab.
- *Für den Server* in der CI auf einem `amd64`-Runner bauen (Kapitel 14). Der baut nativ, schnell und ohne Emulation. Nach dem Build wird genau dieses Image als Container getestet und anschließend unter seinem Digest veröffentlicht.
- *Multi-Plattform-Images* nur dann, wenn sie wirklich auf beiden Architekturen laufen müssen, etwa wenn Kollegen mit ARM-Macs das fertige Produktions-Image lokal starten sollen oder ein ARM-Server im Spiel ist.

#tipp[Wer eine Compose-Datei hat, die am Mac ein bestimmtes `amd64`-Image nutzen muss (etwa weil es kein ARM-Image gibt), kann die Plattform pro Dienst festlegen: `platform: linux/amd64`. Compose lädt dann diese Variante und Colima führt sie über Rosetta aus.]

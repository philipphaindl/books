#import "lib.typ": *

= Registries: Images speichern und verteilen

Damit ein Image vom Build-Rechner auf den Server kommt, braucht es eine Registry als Zwischenlager. Docker Hub ist die Standardquelle für öffentliche Images. Für eigene Images bietet sich die Container-Registry von Gitea an: Sie liegt neben dem Code, nutzt dieselben Benutzer und Rechte und kostet nichts extra.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [Mac oder \ CI-Runner], w: 2.4, h: 1.0)
    kasten((5.6, 0), [*Gitea-Registry* \ #text(size: 6.5pt)[`gitea.example.com/team/notizen`]], w: 4.2, h: 1.1, bg: rgb("#EEF6E6"), col: c-gitea)
    kasten((11.4, 0), [Server \ `app.example.com`], w: 2.6, h: 1.0)
    pfeil((1.25, 0), (3.45, 0), label: "docker push", loff: (0, 0.22), color: c-gitea)
    pfeil((7.75, 0), (10.05, 0), label: "docker pull", loff: (0, 0.22), color: c-gitea)
    kasten((5.6, -1.5), [Docker Hub \ #text(size: 6.5pt)[`python`, `postgres`, `caddy`]], w: 4.2, h: 0.9, bg: luma(245), col: c-grey)
    pfeil((3.45, -1.5), (1.25, -0.55), color: c-grey.darken(20%))
    pfeil((7.75, -1.5), (10.05, -0.55), color: c-grey.darken(20%))
  }),
  caption: [Eigene Images wandern über die Gitea-Registry, Basis-Images kommen von Docker Hub.],
)

== Die Gitea-Registry

Images in Gitea heißen `gitea.example.com/<besitzer>/<image>:<tag>`, wobei der Besitzer ein Benutzer oder eine Organisation ist. Zum Anmelden braucht es einen persönlichen Zugriffstoken (Gitea: _Einstellungen -> Anwendungen_) mit dem Recht, Pakete zu lesen bzw. zu schreiben. Das normale Passwort funktioniert nicht, wenn Zwei-Faktor-Authentifizierung aktiv ist, und sollte ohnehin nicht in Skripten stehen.

```bash
docker login gitea.example.com               # Benutzername + Token (Schlüsselbund)
docker tag notizen:dev gitea.example.com/team/notizen:1.4.0
docker push gitea.example.com/team/notizen:1.4.0
docker pull gitea.example.com/team/notizen:1.4.0
```

Nach dem ersten Push erscheint das Image unter _Pakete_ beim Besitzer. Dort lässt es sich mit einem Repository verknüpfen und in der Sichtbarkeit einschränken. Für den Server legt man einen eigenen Token *nur mit Leserecht* an. Kommt dieser Token abhanden, kann damit niemand manipulierte Images hochladen.

#tipp[Gitea kann alte Image-Versionen automatisch löschen: Unter _Pakete -> Aufräumregeln_ legst du etwa fest, dass von jedem Image nur die letzten 20 Versionen behalten werden, Tags nach dem Muster `v*` aber nie gelöscht werden. Ohne solche Regeln wächst die Registry mit jedem CI-Lauf.]

== Eine Tag-Strategie

Tags sind beweglich (Kapitel 1). Damit jederzeit klar ist, welcher Code in welchem Image steckt, braucht es ein festes Schema:

#table(columns: (auto, 1fr),
  [Tag], [Verwendung],
  [Vollständiger Commit-Hash], [Jeder Build aus der CI. Der 40-stellige SHA vermeidet Kollisionen und ist direkt auf einen Commit zurückführbar. Der tatsächlich deployte Inhalt wird zusätzlich über den Image-Digest festgelegt.],
  [Version, z.B. `1.4.0`], [Releases. Entsteht aus einem Git-Tag `v1.4.0`. *Wird nie überschrieben.*],
  [`1.4`, `1`], [Bequeme Zeiger auf die neueste Patch- bzw. Minor-Version. Nur für Nutzer, die automatisch aktualisieren wollen.],
  [`latest`], [Für eigene Deployments meiden. Auf dem Server steht eine unveränderliche `repository@sha256:…`-Referenz, damit der getestete Inhalt eindeutig ist.],
)

== Docker Hub

Öffentliche Images von Docker Hub lassen sich ohne Anmeldung laden. Im September 2026 gilt ein Sechs-Stunden-Kontingent von 100 Pulls je IPv4-Adresse beziehungsweise IPv6-/64-Netz für anonyme Nutzung und 200 Pulls für ein authentifiziertes Personal-Konto; bezahlte Tarife sind im Rahmen der Fair-Use-Regeln unbegrenzt. Ein Multi-Plattform-Pull zählt pro geladener Architektur. Auf gemeinsam genutzten Build-Servern ist das Kontingent schnell erreicht, und Builds schlagen mit _toomanyrequests_ fehl. Abhilfe: Runner anmelden, Builds und Pulls nicht unnötig wiederholen, Caches kontrolliert verwenden und bevorzugt offizielle Images oder Images bekannter Herausgeber einsetzen.

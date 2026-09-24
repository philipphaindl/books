#import "lib.typ": *
#set heading(numbering: none)
= Bevor es losgeht

Fast jede Anwendung bietet heute eine API an, und viele Angriffe auf Webanwendungen treffen genau diese Schnittstelle. Die Fehler sind dabei selten exotisch: Eine API liefert Daten eines fremden Kontos aus, weil nur geprüft wurde, *ob* jemand angemeldet ist, aber nicht, *wem* das Objekt gehört. Ein Endpunkt übernimmt ein Feld `is_admin` aus der Anfrage. Ein Token wird akzeptiert, das für eine ganz andere Anwendung ausgestellt wurde. Dieses Handbuch zeigt, wie man solche Fehler systematisch vermeidet, am Beispiel von FastAPI.

== Aufbau

- *Teil I, Grundlagen:* ein Bedrohungsmodell für APIs, Authentifizierung mit OAuth 2.0 und OpenID Connect über Authentik und die korrekte Prüfung von Tokens in FastAPI.
- *Teil II, die Risiken in der Praxis:* entlang der OWASP API Security Top 10 (Ausgabe 2023) Autorisierung, Datenmodelle, Ressourcenverbrauch, Fehlerbehandlung und Logging, Transport und Konfiguration sowie SSRF und fremde APIs.
- *Teil III, Betrieb:* Versionierung und Inventar sowie automatisierte Sicherheitstests in der CI.
- *Anhang:* eine Checkliste für Reviews und ein Glossar.

== Konventionen

Code und Ausgaben erscheinen wie in den Handbüchern zu Git und Docker. Codebeispiele mit Sicherheitslücken sind ausdrücklich markiert (#text(fill: c-red, weight: "bold")[unsicher]), die korrigierte Fassung folgt direkt darunter. In den Grafiken gilt:

#align(center, cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let leg = (([Client / Browser], c-grey), ([Identity Provider (Authentik)], c-violet), ([API / Prüfschritt], c-blue), ([Daten / Datenbank], c-yellow), ([Proxy / Transport], c-teal), ([Angriff / Risiko], c-red))
  for (i, l) in leg.enumerate() {
    let x = calc.rem(i, 3) * 5.2
    let y = -calc.floor(i / 3) * 0.75
    rect((x, y - 0.22), (x + 0.6, y + 0.22), radius: 0.06, fill: l.at(1).lighten(86%), stroke: (paint: l.at(1), thickness: 0.8pt))
    content((x + 0.8, y), anchor: "west", text(size: 8pt, l.at(0)))
  }
}))

Das durchgängige Beispiel ist die `notizen`-API aus dem Docker-Handbuch: FastAPI mit PostgreSQL, bei der jeder Benutzer eigene Notizen anlegt, liest und teilt, dazu Administratoren mit erweiterten Rechten und ein Hintergrunddienst, der sich ohne Benutzer an der API anmeldet. Als Identity Provider dient *Authentik* unter `auth.example.com`, die API läuft unter `api.example.com`.

#merke[Sicherheit einer API entsteht nicht durch ein einzelnes Werkzeug, sondern durch viele einfache Prüfungen, die *jede* Anfrage durchläuft. Das Leitmotiv dieses Buchs: *Nichts, was vom Client kommt, ist vertrauenswürdig*, weder Parameter noch Felder noch Header, und jede Prüfung muss im Zweifel ablehnen.]

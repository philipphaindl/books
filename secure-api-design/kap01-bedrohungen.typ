#import "lib.typ": *

= Ein Bedrohungsmodell für APIs

Eine Webanwendung mit Oberfläche verbirgt einiges hinter Formularen und Schaltflächen. Eine API dagegen legt ihre Funktionen offen: Jeder Endpunkt, jeder Parameter und jedes Feld lässt sich mit `curl` direkt ansprechen, in beliebiger Reihenfolge, mit beliebigen Werten und in beliebiger Menge. Die Oberfläche (Web-App, Mobile-App) ist nur *ein* möglicher Client. Ein Angreifer schreibt sich einfach seinen eigenen.

== Vertrauensgrenzen

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [Client \ #text(size: 6.5pt)[Browser, App, Skript]], w: 2.3, h: 1.0, bg: luma(245), col: c-grey)
    kasten((0, -1.6), [Angreifer \ #text(size: 6.5pt)[eigener Client]], w: 2.3, h: 1.0, bg: rgb("#FBEAEA"), col: c-red)
    kasten((4.0, -0.8), [Reverse Proxy \ #text(size: 6.5pt)[TLS, Limits]], w: 2.3, h: 1.0, bg: rgb("#E7F4F2"), col: c-teal)
    kasten((7.9, -0.8), [*API* \ #text(size: 6.5pt)[FastAPI]], w: 2.3, h: 1.0, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((11.6, -0.1), [Datenbank], w: 2.0, h: 0.8, bg: rgb("#FFF8E6"), col: c-yellow)
    kasten((11.6, -1.5), [fremde APIs, \ Webhooks], w: 2.0, h: 0.9, bg: luma(245), col: c-grey)
    kasten((7.9, 1.25), [Authentik \ #text(size: 6.5pt)[stellt Tokens aus]], w: 2.3, h: 0.9, bg: rgb("#F1ECF8"), col: c-violet)
    pfeil((1.2, 0), (2.8, -0.6)); pfeil((1.2, -1.6), (2.8, -1.0), color: c-red)
    pfeil((5.2, -0.8), (6.7, -0.8))
    pfeil((9.1, -0.6), (10.55, -0.1)); pfeil((9.1, -1.0), (10.55, -1.5))
    pfeil((7.9, -0.25), (7.9, 0.75), color: c-violet)
    line((6.0, 1.9), (6.0, -2.3), stroke: (paint: c-red, thickness: 1pt, dash: "dashed"))
    content((6.0, -2.55), text(size: 6.8pt, fill: c-red, weight: "bold")[Vertrauensgrenze])
    content((1.5, 1.2), text(size: 6.8pt, fill: c-grey.darken(20%), style: "italic")[nicht vertrauenswürdig])
  }),
  caption: [Alles links der Grenze steht unter Kontrolle des Clients, also potenziell des Angreifers.],
)

An jeder Vertrauensgrenze muss geprüft werden, was hereinkommt. Für eine API bedeutet das: Jede Anfrage wird so behandelt, als käme sie von einem Angreifer, der die API genau kennt. Dass die eigene Web-App nur gültige IDs und nur erlaubte Felder schickt, ist ohne Bedeutung, denn niemand zwingt einen Angreifer, die Web-App zu benutzen. Auch Antworten fremder APIs und Daten aus Webhooks liegen außerhalb der eigenen Kontrolle.

== Die OWASP API Security Top 10

Das Open Worldwide Application Security Project (OWASP) veröffentlicht eine Liste der häufigsten Sicherheitsrisiken speziell für APIs. Die aktuelle Ausgabe von 2023 bildet das Gerüst für Teil II:

#table(columns: (auto, 1fr, auto),
  [Nr.], [Risiko], [Kapitel],
  [API1], [*Broken Object Level Authorization (BOLA):* Zugriff auf fremde Objekte über deren ID], [4],
  [API2], [*Broken Authentication:* fehlerhafte Anmeldung und Token-Prüfung], [2, 3],
  [API3], [*Broken Object Property Level Authorization:* zu viele Felder lesbar oder schreibbar (Mass Assignment)], [5],
  [API4], [*Unrestricted Resource Consumption:* keine Grenzen für Menge, Größe, Häufigkeit], [6],
  [API5], [*Broken Function Level Authorization:* Admin-Funktionen für normale Benutzer erreichbar], [4],
  [API6], [*Unrestricted Access to Sensitive Business Flows:* automatisierter Missbrauch legitimer Abläufe], [6],
  [API7], [*Server Side Request Forgery (SSRF):* die API ruft vom Angreifer gewählte URLs auf], [9],
  [API8], [*Security Misconfiguration:* Header, CORS, Debug, Fehlermeldungen], [7, 8],
  [API9], [*Improper Inventory Management:* vergessene alte Versionen und Endpunkte], [10],
  [API10], [*Unsafe Consumption of APIs:* Daten fremder APIs ungeprüft übernehmen], [9],
)

Auffällig ist, dass drei der ersten fünf Punkte Autorisierung betreffen. Die meisten API-Lücken sind keine technischen Schwachstellen im engeren Sinn, sondern fehlende Prüfungen in der Geschäftslogik. Kein Scanner und keine Firewall findet sie zuverlässig, sie müssen im Code vermieden werden.

== Grundprinzipien

#table(columns: (auto, 1fr),
  [Prinzip], [Bedeutung für eine API],
  [*Standardmäßig ablehnen*], [Jeder Endpunkt ist geschützt, außer er wird ausdrücklich öffentlich gemacht. Eine vergessene Prüfung führt dann zu einem Fehler, nicht zu einer Lücke.],
  [*Minimale Rechte*], [Tokens enthalten nur die Scopes, die ein Client braucht. Dienste haben eigene Konten mit eigenen Rechten.],
  [*Verteidigung in der Tiefe*], [Proxy, Framework, Geschäftslogik und Datenbank prüfen jeweils selbst. Fällt eine Schicht aus, hält die nächste.],
  [*Im Fehlerfall schließen*], [Kann eine Prüfung nicht durchgeführt werden (etwa weil die Schlüssel des Identity Providers nicht abrufbar sind), wird die Anfrage abgelehnt, nicht durchgelassen.],
  [*Datensparsamkeit*], [Was die API nicht speichert und nicht ausliefert, kann auch nicht abfließen.],
  [*Explizit statt implizit*], [Eingabe- und Ausgabemodelle legen genau fest, welche Felder erlaubt sind, statt alles durchzureichen.],
)

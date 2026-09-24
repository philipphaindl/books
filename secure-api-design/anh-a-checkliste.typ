#import "lib.typ": *

= Checkliste für API-Reviews

#let pkt(..xs) = table(columns: (auto, 1fr), stroke: (x, y) => (bottom: 0.4pt + luma(222)), fill: none,
  ..xs.pos().map(x => ([☐], x)).flatten())
#show table.cell.where(y: 0): set text(weight: "regular")

#columns(2, gutter: 16pt)[
#text(size: 8pt, weight: "bold", fill: c-accent)[AUTHENTIFIZIERUNG]
#pkt(
  [Authorization Code + PKCE (`S256`), ggf. Device Code; kein Implicit/Password Grant],
  [Redirect-URIs exakt; `state` und bei OIDC `nonce` geprüft],
  [Signing Key in Authentik gesetzt (RS256)],
  [Signatur, feste Algorithmen, `iss`, API-`aud`, `exp` und Claim-Typen geprüft],
  [Access-Token-Vertrag beweisbar; echtes ID-Token im Test abgelehnt],
  [Kurze Token-Laufzeit; Refresh-Rotation und `offline_access` bewusst],
  [Tokens nie in URLs oder Logs],
)
#text(size: 8pt, weight: "bold", fill: c-accent)[AUTORISIERUNG]
#pkt(
  [Router-weite Anmeldepflicht, öffentliche Endpunkte explizit],
  [Besitz-/Freigabeprüfung in jeder Abfrage (BOLA)],
  [Fremde Objekte liefern 404],
  [Admin-Funktionen per Gruppe/Scope auf Router-Ebene],
  [Alle HTTP-Methoden eines Pfads geprüft],
  [Rechtetests mit zwei Benutzern und Rechtematrix],
)
#text(size: 8pt, weight: "bold", fill: c-accent)[DATEN]
#pkt(
  [Getrennte Eingabe- und Ausgabemodelle],
  [`extra="forbid"` in allen Eingabemodellen],
  [Längen-, Wert- und Listengrenzen für jedes Feld],
  [`response_model` an jedem Endpunkt],
  [Parametrisierte Datenbankabfragen],
  [Uploads: Größe, Inhaltsprüfung, Quarantäne/Scan, zufällige Namen],
)
#colbreak()
#text(size: 8pt, weight: "bold", fill: c-accent)[RESSOURCEN]
#pkt(
  [Größenlimit am Proxy und in der Anwendung],
  [Pflicht-Paginierung mit Höchstwert],
  [Rate Limits pro Benutzer und pro IP, strengere für teure Endpunkte],
  [`FORWARDED_ALLOW_IPS` nur mit Proxy-Adresse],
  [Timeouts für DB und ausgehende Aufrufe],
  [Idempotency-Key atomar per Unique-Constraint reserviert],
)
#text(size: 8pt, weight: "bold", fill: c-accent)[FEHLER UND LOGGING]
#pkt(
  [Einheitliche Fehler (RFC 9457), keine Stacktraces],
  [Validierungsfehler ohne Eingabewerte],
  [Request-ID in Logs und Antworten],
  [Keine Tokens, Passwörter oder Bodies im Log],
  [Audit-Log für sicherheitsrelevante Aktionen],
  [Audit-Log zugriffsbeschränkt, manipulationsgeschützt, mit Löschfrist],
)
#text(size: 8pt, weight: "bold", fill: c-accent)[KONFIGURATION]
#pkt(
  [Nur HTTPS, HSTS und Sicherheits-Header am Proxy],
  [CORS mit exakter Origin-Liste oder gar nicht],
  [Cookie-Sessions: `Secure`, `HttpOnly`, `SameSite` und eigener CSRF-Schutz],
  [Docs/OpenAPI in Produktion aus oder geschützt],
  [Pflicht-Konfiguration ohne Standardwerte, `SecretStr`],
  [SSRF: Allowlist/IP-Prüfung, Streaming-Limit, keine Redirects, Egress-Sperre],
  [Webhooks: HMAC, Zeitstempel, eindeutige Ereignis-ID und Replay-Speicher],
  [Alte API-Versionen abgekündigt und abgeschaltet],
  [Lockfile, Audit, Secret-Scan, SBOM; CI-Actions und Images unveränderlich gepinnt],
)
]

#import "lib.typ": *

= Transport und Authentifizierung

Ein Broker ist ein zentraler Knoten, über den alle Geschäftsvorgänge laufen. Wer ihn unbemerkt mitlesen oder beschreiben kann, kontrolliert das System. Die Grundlage jeder weiteren Maßnahme: verschlüsselte Verbindungen und eine eigene Identität für jeden Dienst.

== Die Bedrohungen

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [`shop`], w: 1.8, h: 0.8, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((6.0, 0), [Broker], w: 2.2, h: 0.9, bg: rgb("#E7F4F2"), col: c-teal)
    kasten((12.0, 0), [`provisionierung`], w: 2.8, h: 0.8, bg: rgb("#FDF1EC"), col: c-accent, size: 7.3pt)
    pfeil((0.95, 0), (4.85, 0)); pfeil((7.15, 0), (10.55, 0))
    let angriff(pos, t) = kasten(pos, t, w: 3.2, h: 0.75, bg: rgb("#FBEAEA"), col: c-red, size: 6.8pt)
    angriff((2.9, -1.4), [① Mitlesen im Netz])
    angriff((6.0, 1.45), [② fremder Dienst verbindet sich])
    angriff((9.1, -1.4), [③ kompromittierter Dienst \ sendet gefälschte Ereignisse])
    angriff((13.3, 1.45), [④ Admin/Backup liest Inhalte])
    line((2.9, -1.0), (2.9, -0.05), stroke: (paint: c-red, dash: "dashed", thickness: 0.8pt))
    line((6.0, 1.05), (6.0, 0.5), stroke: (paint: c-red, dash: "dashed", thickness: 0.8pt))
    line((9.1, -1.0), (9.1, -0.05), stroke: (paint: c-red, dash: "dashed", thickness: 0.8pt))
    line((13.3, 1.05), (12.5, 0.45), stroke: (paint: c-red, dash: "dashed", thickness: 0.8pt))
  }),
  caption: [Vier Angriffswege und ihre Gegenmaßnahmen: TLS (①), Authentifizierung (②), minimale Rechte und Signaturen (③), Verschlüsselung der Inhalte (④).],
)

Dieses Kapitel behandelt ① und ②, Kapitel 9 die Rechte gegen ③, Kapitel 10 Signaturen und Verschlüsselung gegen ③ und ④.

== TLS und gegenseitige Authentifizierung

Beide Broker unterstützen TLS, und beide können zusätzlich ein *Client-Zertifikat* verlangen (mTLS). Dann weist nicht nur der Server sich gegenüber dem Client aus, sondern auch jeder Dienst gegenüber dem Server. Ein gestohlenes Passwort allein genügt nicht mehr. Die Zertifikate stellt eine eigene, interne Zertifizierungsstelle aus, etwa mit `step-ca` oder für kleine Umgebungen mit `openssl`.

#datei("nats-server.conf (Auszug)")[
```text
listen: 0.0.0.0:4222
tls {
  cert_file: "/etc/nats/tls/server.crt"
  key_file:  "/etc/nats/tls/server.key"
  ca_file:   "/etc/nats/tls/ca.crt"
  verify:    true            # Clients müssen ein Zertifikat der internen CA vorlegen
  timeout:   2
}
http: 127.0.0.1:8222         # Überwachung nur lokal (Kapitel 11)
```
]

#datei("rabbitmq.conf (Auszug)")[
```ini
listeners.tcp = none                         # unverschlüsselten Port 5672 abschalten
listeners.ssl.default = 5671
ssl_options.cacertfile = /etc/rabbitmq/tls/ca.crt
ssl_options.certfile   = /etc/rabbitmq/tls/server.crt
ssl_options.keyfile    = /etc/rabbitmq/tls/server.key
ssl_options.verify     = verify_peer
ssl_options.fail_if_no_peer_cert = true      # mTLS erzwingen
loopback_users.guest   = true                # Standardkonto nur lokal (Standard, trotzdem löschen)
```
]

In Python wird dasselbe `ssl.SSLContext` für beide Clients verwendet:

#datei("gemeinsam/tls.py")[
```python
import ssl

def tls_kontext(dienst: str) -> ssl.SSLContext:
    ctx = ssl.create_default_context(ssl.Purpose.SERVER_AUTH, cafile="/run/secrets/ca.crt")
    ctx.load_cert_chain(f"/run/secrets/{dienst}.crt", f"/run/secrets/{dienst}.key")
    ctx.minimum_version = ssl.TLSVersion.TLSv1_2
    return ctx

# NATS
nc = await nats.connect(servers=["tls://nats.example.com:4222"], tls=tls_kontext("shop"),
                        user_credentials="/run/secrets/shop.creds")
# RabbitMQ
verbindung = await aio_pika.connect_robust(
    "amqps://shop@rabbit.example.com:5671/bestellungen", ssl_context=tls_kontext("shop"))
```
]

== Identitäten pro Dienst

#table(columns: (auto, 1fr, 1fr),
  [], [NATS], [RabbitMQ],
  [einfach], [Benutzer und Passwort in der Serverkonfiguration (Passwörter als bcrypt-Hash, erzeugt mit `nats server passwd`)], [Benutzer und Passwort in der internen Datenbank (`rabbitmqctl add_user`)],
  [stärker], [_NKeys_: Schlüsselpaare, der Server kennt nur den öffentlichen Schlüssel], [Client-Zertifikat als Identität über das Plugin `rabbitmq_auth_mechanism_ssl` (Benutzername aus dem Zertifikat)],
  [zentral verwaltet], [_Decentralized JWT Auth_: Operator, Accounts und Benutzer als signierte JWTs, verwaltet mit `nsc`, Clients erhalten `.creds`-Dateien], [externe Verzeichnisse per LDAP oder OAuth 2.0 (Plugin `rabbitmq_auth_backend_oauth2`)],
)

Für eine überschaubare Zahl von Diensten genügen Passwörter oder NKeys pro Dienst, kombiniert mit mTLS. Die JWT-basierte Verwaltung von NATS lohnt sich, sobald viele Dienste, Umgebungen oder Mandanten dazukommen, weil sich Benutzer dann ohne Neustart des Servers anlegen und widerrufen lassen.

Unabhängig vom Verfahren gilt: *ein Konto pro Dienst*, nie ein gemeinsames Konto für alle, das Standardkonto `guest` von RabbitMQ löschen, Zugangsdaten als Docker-Secrets bereitstellen (Docker-Handbuch, Kapitel 12) und die Verwaltungsoberflächen (RabbitMQ Management, NATS-Überwachung) nie öffentlich erreichbar machen, sondern nur über VPN oder lokal.

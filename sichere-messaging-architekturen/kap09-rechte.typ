#import "lib.typ": *

= Minimale Rechte pro Dienst

Authentifizierung beantwortet, *wer* sich verbindet. Autorisierung legt fest, *was* dieser Dienst darf. Das Ziel ist dasselbe wie bei APIs: Ein kompromittierter Dienst soll nur genau das tun können, was er für seine Aufgabe braucht. Kann der Dienst `benachrichtigung` das Ereignis `zahlung.eingegangen` veröffentlichen, kann ein Angreifer, der ihn übernimmt, Lieferungen ohne Bezahlung auslösen.

== Die Rechtematrix entwerfen

Vor der Konfiguration steht eine Tabelle, die für jeden Dienst festhält, was er senden und empfangen darf:

#table(columns: (auto, 1fr, 1fr),
  [Dienst], [darf senden], [darf empfangen],
  [`shop`], [`bestellung.eingegangen`], [(nur Bestätigungen des Brokers)],
  [`provisionierung`], [`provisionierung.abgeschlossen`, Dead Letters], [Consumer `provisionierung` auf `BESTELLUNGEN`],
  [`benachrichtigung`], [nichts], [Consumer `benachrichtigung`],
  [Einrichtung (Deployment)], [Streams, Consumer, Exchanges, Queues anlegen], [nichts],
)

Keiner der Anwendungsdienste darf Streams, Queues oder Exchanges anlegen, ändern oder löschen. Das erledigt ein eigenes Konto beim Deployment (Kapitel 4 und 5).

== NATS: Rechte auf Subjects

In NATS werden Rechte als erlaubte und verbotene Subjects für `publish` und `subscribe` vergeben, mit denselben Platzhaltern `*` und `>` wie bei Subjects. Zwei Besonderheiten von JetStream sind zu beachten: Die Bestätigung eines Streams kommt auf einer _Inbox_ zurück (Standard `_INBOX.>`), und ein Pull-Consumer spricht interne API-Subjects an (`$JS.API...`, `$JS.ACK...`). Damit Dienste nicht die Antworten anderer mitlesen können, bekommt jeder ein eigenes Inbox-Präfix:

#datei("nats-server.conf (Accounts)")[
```text
accounts {
  APP: {
    jetstream: enabled
    users: [
      { user: shop, password: "$2a$11$...",               # bcrypt-Hash
        permissions: {
          publish:   { allow: ["bestellung.eingegangen"] }
          subscribe: { allow: ["_INBOX_shop.>"] }
        } }
      { user: provisionierung, password: "$2a$11$...",
        permissions: {
          publish: { allow: [
            "$JS.API.CONSUMER.MSG.NEXT.BESTELLUNGEN.provisionierung",   # Nachrichten abholen
            "$JS.API.CONSUMER.INFO.BESTELLUNGEN.provisionierung",       # an Consumer binden
            "$JS.ACK.BESTELLUNGEN.provisionierung.>",                   # ack, nak, term
            "provisionierung.abgeschlossen",
            "dlq.provisionierung" ] }
          subscribe: { allow: ["_INBOX_prov.>"] }
        } }
      { user: einrichtung, password: "$2a$11$...",
        permissions: { publish: ["$JS.API.>"], subscribe: ["_INBOX.>"] } }
    ]
  }
  SYS: { users: [ { user: admin, password: "$2a$11$..." } ] }
}
system_account: SYS
```
]

```python
nc = await nats.connect(servers=[...], user="shop", password=passwort,
                        inbox_prefix=b"_INBOX_shop", tls=tls_kontext("shop"))
```

Wird ein Recht verweigert, meldet der Server `Permissions Violation` an den Client und schreibt es ins Server-Log. Diese Meldungen gehören in die Überwachung, denn im Betrieb deuten sie entweder auf einen Konfigurationsfehler oder auf einen Angriff hin. *Accounts* trennen zusätzlich ganze Bereiche: Dienste in verschiedenen Accounts sehen die Subjects des anderen überhaupt nicht, außer ein Account exportiert sie ausdrücklich. Getrennte Accounts für Produktion und Test auf demselben Server verhindern, dass ein Testdienst versehentlich echte Bestellungen verarbeitet.

== RabbitMQ: configure, write, read

RabbitMQ vergibt pro Benutzer und vhost drei Rechte, jeweils als regulärer Ausdruck über Namen von Exchanges und Queues:

#table(columns: (auto, 1fr),
  [Recht], [erlaubt],
  [*configure*], [Exchanges und Queues anlegen, ändern, löschen],
  [*write*], [in Exchanges veröffentlichen, Queues an Exchanges binden (auf Seiten der Queue)],
  [*read*], [aus Queues lesen, bestätigen, Bindings (auf Seiten des Exchanges)],
)

```bash
rabbitmqctl delete_user guest
rabbitmqctl add_vhost bestellungen
rabbitmqctl add_user shop                        # Passwort wird interaktiv abgefragt

#                         vhost             Benutzer          configure  write            read
rabbitmqctl set_permissions -p bestellungen shop              "^$"       "^ereignisse$"   "^$"
rabbitmqctl set_permissions -p bestellungen provisionierung   "^$"       "^ereignisse$"   "^provisionierung$"
rabbitmqctl set_permissions -p bestellungen benachrichtigung  "^$"       "^$"             "^benachrichtigung$"

# Topic-Rechte: shop darf in "ereignisse" nur mit Routing Keys "bestellung.*" senden
rabbitmqctl set_topic_permissions -p bestellungen shop ereignisse "^bestellung\." "^$"
rabbitmqctl set_topic_permissions -p bestellungen provisionierung ereignisse "^provisionierung\." "^$"
```

`"^$"` passt auf keinen Namen und entzieht das jeweilige Recht vollständig. Ohne _Topic-Rechte_ dürfte `shop` mit Schreibrecht auf `ereignisse` jeden beliebigen Routing Key verwenden, also auch `zahlung.eingegangen`. Erst die Topic-Rechte schränken die Routing Keys ein und schließen damit die Lücke aus der Einleitung. Ein eigener vhost pro Anwendung und Umgebung trennt Bereiche wie die Accounts in NATS.

#tipp[Dienste deklarieren ihre Exchanges und Queues in Produktion nicht selbst (Kapitel 5 verwendet `get_exchange(..., ensure=False)` und `get_queue(..., ensure=False)`). Ohne `configure`-Recht würde eine Deklaration ohnehin scheitern. Das hat den Nebeneffekt, dass ein Tippfehler im Queue-Namen nicht stillschweigend eine neue, leere Queue erzeugt.]

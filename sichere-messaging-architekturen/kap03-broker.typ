#import "lib.typ": *

= NATS JetStream und RabbitMQ im Überblick

Beide Broker lösen dieselben Aufgaben, denken aber in unterschiedlichen Begriffen. Wer die beiden Modelle nebeneinander sieht, kann Konzepte übertragen und bewusst wählen.

== NATS und JetStream

NATS ist ein sehr schlanker Nachrichtenserver @github-com-nats-io-nats-server. In seiner Grundform (_Core NATS_) leitet er Nachrichten nur an gerade verbundene Empfänger weiter, ohne sie zu speichern (at-most-once) @docs-nats-io-learn-core-nats. *JetStream* ist die eingebaute Persistenzschicht darüber: Ein *Stream* speichert alle Nachrichten zu bestimmten *Subjects*, *Consumer* sind benannte Lesepositionen auf einem Stream @docs-nats-io-concepts-jetstream.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((-0.2, 0), [`shop` \ #text(size: 6.3pt)[publish `bestellung.eingegangen`]], w: 4.0, h: 0.9, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
    rahmen((4.3, -1.6), (10.2, 1.4), [Stream `BESTELLUNGEN` (Subjects `bestellung.>`)], c-teal)
    for i in range(6) {
      rect((4.6 + i * 0.9, -0.3), (5.35 + i * 0.9, 0.3), radius: 0.05, fill: c-yellow.lighten(85%), stroke: c-yellow + 0.8pt)
      content((4.975 + i * 0.9, 0), text(size: 6.3pt, str(i + 1)))
    }
    content((7.25, -0.95), text(size: 6.5pt, fill: c-grey.darken(20%), style: "italic")[Consumer = eigene Leseposition])
    kasten((13.0, 0.75), [Consumer `provisionierung` \ #text(size: 6.3pt)[3 Worker teilen sich die Arbeit]], w: 3.6, h: 0.9, bg: rgb("#FDF1EC"), col: c-accent, size: 7pt)
    kasten((13.0, -0.75), [Consumer `benachrichtigung`], w: 3.6, h: 0.7, bg: rgb("#FDF1EC"), col: c-accent, size: 7pt)
    pfeil((1.85, 0), (4.55, 0))
    pfeil((9.95, 0.15), (11.15, 0.7)); pfeil((9.95, -0.15), (11.15, -0.7))
  }),
  caption: [Ein Stream speichert, jeder Consumer liest unabhängig. Mehrere Instanzen eines Consumers teilen sich die Nachrichten.],
)

- *Subjects* sind hierarchische Namen mit Punkten. `*` steht für genau ein Glied (`bestellung.*`), `>` für ein oder mehrere am Ende (`bestellung.>`) @docs-nats-io-concepts-subjects.
- Ein *Stream* legt fest, welche Subjects er speichert, wie lange (`max_age`, `max_msgs`, `max_bytes`) und nach welcher Regel (_retention_): `limits` (bis zur Grenze behalten, für Ereignishistorien), `workqueue` (löschen, sobald bestätigt) oder `interest` (löschen, wenn alle Consumer bestätigt haben) @docs-nats-io-learn-jetstream-your-first-stream @docs-nats-io-learn-jetstream-retention-policies.
- Ein *Consumer* ist dauerhaft (_durable_) und merkt sich, was bestätigt wurde @docs-nats-io-learn-jetstream-reading-back. _Pull-Consumer_ holen Nachrichten aktiv in Stapeln ab, das ist die gängige Form für Worker @docs-nats-io-learn-jetstream-pull-consumers.
- *Deduplizierung* ist eingebaut: Nachrichten mit gleicher `Nats-Msg-Id` innerhalb eines Zeitfensters (`duplicate_window`) speichert der Stream nur einmal @docs-nats-io-learn-jetstream-publishing @docs-nats-io-learn-jetstream-your-first-stream.

== RabbitMQ

RabbitMQ implementiert das Protokoll AMQP 0-9-1 (und AMQP 1.0) @www-rabbitmq-com-docs-amqp. Producer senden nie direkt an eine Queue, sondern an einen *Exchange*. Der Exchange verteilt anhand von *Bindings* und dem _Routing Key_ der Nachricht an Queues, aus denen Consumer lesen @www-rabbitmq-com-tutorials-amqp-concepts.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((-0.5, 0), [`shop` \ #text(size: 6.3pt)[Routing Key `bestellung.eingegangen`]], w: 4.4, h: 0.9, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
    kasten((5.6, 0), [Exchange `ereignisse` \ #text(size: 6.3pt)[Typ `topic`]], w: 2.8, h: 0.9, bg: rgb("#E7F4F2"), col: c-teal, size: 7.3pt)
    kasten((10.2, 0.8), [Queue `provisionierung`], w: 3.2, h: 0.65, bg: rgb("#E7F4F2"), col: c-teal, size: 7pt)
    kasten((10.2, -0.8), [Queue `benachrichtigung`], w: 3.2, h: 0.65, bg: rgb("#E7F4F2"), col: c-teal, size: 7pt)
    kasten((14.3, 0.8), [Consumer], w: 1.7, h: 0.65, bg: rgb("#FDF1EC"), col: c-accent, size: 7pt)
    kasten((14.3, -0.8), [Consumer], w: 1.7, h: 0.65, bg: rgb("#FDF1EC"), col: c-accent, size: 7pt)
    pfeil((1.75, 0), (4.15, 0))
    pfeil((7.05, 0.15), (8.55, 0.75), label: "bestellung.*", loff: (-0.3, 0.2), color: c-teal)
    pfeil((7.05, -0.15), (8.55, -0.75), label: "#", loff: (-0.3, -0.2), color: c-teal)
    pfeil((11.85, 0.8), (13.4, 0.8)); pfeil((11.85, -0.8), (13.4, -0.8))
  }),
  caption: [Der Exchange verteilt nach Bindings an Queues. Jede Queue hat ihre eigenen Consumer.],
)

- *Exchange-Typen:* `direct` (Routing Key muss exakt passen), `topic` (Muster mit `*` für ein Wort und `#` für beliebig viele), `fanout` (an alle gebundenen Queues), `headers` (nach Header-Werten) @www-rabbitmq-com-tutorials-amqp-concepts @www-rabbitmq-com-tutorials-tutorial-five-python.
- *Queue-Typen:* _Quorum Queues_ sind repliziert, dauerhaft und die Standardwahl, wenn eine replizierte, hochverfügbare Queue gebraucht wird @www-rabbitmq-com-docs-quorum-queues. Die alte Spiegelung klassischer Queues wurde in 4.0 entfernt, klassische Queues sind nur noch unrepliziert @www-rabbitmq-com-docs-3-13-ha @github-com-rabbitmq-rabbitmq-server-blob-v4-0-x-release-notes-4-0-1-md. _Streams_ bieten Log-Semantik wie JetStream @www-rabbitmq-com-docs-streams.
- *Virtual Hosts* (vhosts) trennen Anwendungen oder Umgebungen innerhalb eines Servers logisch voneinander, samt Rechten @www-rabbitmq-com-docs-vhosts.

== Gegenüberstellung

#table(columns: (auto, 1fr, 1fr),
  [], [NATS JetStream], [RabbitMQ],
  [Adressierung], [Subject (`bestellung.eingegangen`) @docs-nats-io-concepts-subjects], [Exchange + Routing Key -> Queue @www-rabbitmq-com-tutorials-amqp-concepts],
  [Speicher], [Stream (Log) mit Consumer-Positionen @docs-nats-io-concepts-jetstream], [Queue (Nachricht weg nach ack), optional Streams @www-rabbitmq-com-docs-streams],
  [Wiederholtes Lesen], [ja, Consumer ab beliebiger Position @docs-nats-io-learn-jetstream-reading-back], [nur mit Streams @www-rabbitmq-com-docs-streams],
  [Deduplizierung beim Senden], [eingebaut (`Nats-Msg-Id`) @docs-nats-io-learn-jetstream-publishing], [nur bei Streams eingebaut, sonst im Consumer lösen @www-rabbitmq-com-docs-streams @www-rabbitmq-com-docs-reliability],
  [Grenze wiederholter Zustellung], [`max_deliver` am Consumer @docs-nats-io-learn-jetstream-acknowledgment], [`x-delivery-limit` (Quorum Queue, Standard 20) @www-rabbitmq-com-docs-quorum-queues],
  [Dead Letters], [über Advisories oder in der Anwendung @docs-nats-io-learn-monitoring-advisories-and-events], [eingebaut: Dead-Letter-Exchange @www-rabbitmq-com-docs-dlx],
  [Standard-Maximalgröße einer Nachricht], [1 MB (`max_payload`) @docs-nats-io-reference-config], [16 MiB (seit 4.0) @github-com-rabbitmq-rabbitmq-server-blob-v4-0-x-release-notes-4-0-1-md],
  [Mandanten-Trennung], [Accounts @docs-nats-io-learn-security-accounts-and-multitenancy], [Virtual Hosts @www-rabbitmq-com-docs-vhosts],
  [Rechte], [Publish/Subscribe pro Subject @docs-nats-io-learn-security-authorization], [configure/write/read pro Ressource, Topic-Rechte @www-rabbitmq-com-docs-access-control],
  [Betrieb], [ein kleines Binary, sehr ressourcenschonend @github-com-nats-io-nats-server], [Erlang-basiert @www-rabbitmq-com-docs-which-erlang, umfangreiche Verwaltungsoberfläche @www-rabbitmq-com-docs-management],
  [Python-Client], [`nats-py` @github-com-nats-io-nats-py], [`aio-pika` (asynchron) @docs-aio-pika-com, `pika` (synchron) @www-rabbitmq-com-client-libraries-devtools @docs-aio-pika-com],
)

Beide sind für die Beispiele dieses Buchs gleichermaßen geeignet. NATS spielt seine Stärken bei hohem Durchsatz, Streams mit Wiederholung und sehr geringem Betriebsaufwand aus, RabbitMQ bei komplexem Routing, eingebauten Dead Letters und seiner ausgereiften Verwaltungsoberfläche.

== Lokal ausprobieren

#datei("compose.yaml (nur für die Entwicklung, ohne TLS und Rechte)")[
```yaml
services:
  nats:
    image: nats:2
    command: ["-js", "-sd", "/data", "-m", "8222"]
    ports: ["127.0.0.1:4222:4222", "127.0.0.1:8222:8222"]
    volumes: [natsdaten:/data]
  rabbitmq:
    image: rabbitmq:4-management
    ports: ["127.0.0.1:5672:5672", "127.0.0.1:15672:15672"]
    volumes: [rabbitdaten:/var/lib/rabbitmq]
volumes:
  natsdaten:
  rabbitdaten:
```
]

Die Verwaltungsoberfläche von RabbitMQ ist dann unter `http://localhost:15672` erreichbar, für NATS gibt es das Kommandozeilenwerkzeug `nats` (`brew install nats-io/nats-tools/nats`). Wie die Absicherung für den Betrieb aussieht, zeigt Teil III.

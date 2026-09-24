#import "lib.typ": *

= NATS JetStream und RabbitMQ im Überblick

Beide Broker lösen dieselben Aufgaben, denken aber in unterschiedlichen Begriffen. Wer die beiden Modelle nebeneinander sieht, kann Konzepte übertragen und bewusst wählen.

== NATS und JetStream

NATS ist ein sehr schlanker Nachrichtenserver. In seiner Grundform (_Core NATS_) leitet er Nachrichten nur an gerade verbundene Empfänger weiter, ohne sie zu speichern (at-most-once). *JetStream* ist die eingebaute Persistenzschicht darüber: Ein *Stream* speichert alle Nachrichten zu bestimmten *Subjects*, *Consumer* sind benannte Lesepositionen auf einem Stream.

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

- *Subjects* sind hierarchische Namen mit Punkten. `*` steht für genau ein Glied (`bestellung.*`), `>` für beliebig viele am Ende (`bestellung.>`).
- Ein *Stream* legt fest, welche Subjects er speichert, wie lange (`max_age`, `max_msgs`, `max_bytes`) und nach welcher Regel (_retention_): `limits` (bis zur Grenze behalten, für Ereignishistorien), `workqueue` (löschen, sobald bestätigt) oder `interest` (löschen, wenn alle Consumer bestätigt haben).
- Ein *Consumer* ist dauerhaft (_durable_) und merkt sich, was bestätigt wurde. _Pull-Consumer_ holen Nachrichten aktiv in Stapeln ab, das ist die empfohlene Form für Worker.
- *Deduplizierung* ist eingebaut: Nachrichten mit gleicher `Nats-Msg-Id` innerhalb eines Zeitfensters (`duplicate_window`) speichert der Stream nur einmal.

== RabbitMQ

RabbitMQ implementiert das Protokoll AMQP 0-9-1 (und AMQP 1.0). Producer senden nie direkt an eine Queue, sondern an einen *Exchange*. Der Exchange verteilt anhand von *Bindings* und dem _Routing Key_ der Nachricht an Queues, aus denen Consumer lesen.

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

- *Exchange-Typen:* `direct` (Routing Key muss exakt passen), `topic` (Muster mit `*` für ein Wort und `#` für beliebig viele), `fanout` (an alle gebundenen Queues), `headers` (nach Header-Werten).
- *Queue-Typen:* _Quorum Queues_ sind repliziert, dauerhaft und seit RabbitMQ 4.0 der empfohlene Standard. Die alte Spiegelung klassischer Queues wurde in 4.0 entfernt, klassische Queues sind nur noch unrepliziert. _Streams_ bieten Log-Semantik wie JetStream.
- *Virtual Hosts* (vhosts) trennen Anwendungen oder Umgebungen innerhalb eines Servers vollständig voneinander, samt Rechten.

== Gegenüberstellung

#table(columns: (auto, 1fr, 1fr),
  [], [NATS JetStream], [RabbitMQ],
  [Adressierung], [Subject (`bestellung.eingegangen`)], [Exchange + Routing Key -> Queue],
  [Speicher], [Stream (Log) mit Consumer-Positionen], [Queue (Nachricht weg nach ack), optional Streams],
  [Wiederholtes Lesen], [ja, Consumer ab beliebiger Position], [nur mit Streams],
  [Deduplizierung beim Senden], [eingebaut (`Nats-Msg-Id`)], [nicht eingebaut, im Consumer lösen],
  [Grenze wiederholter Zustellung], [`max_deliver` am Consumer], [`x-delivery-limit` (Quorum Queue, Standard 20)],
  [Dead Letters], [über Advisories oder in der Anwendung], [eingebaut: Dead-Letter-Exchange],
  [Standard-Maximalgröße einer Nachricht], [1 MB (`max_payload`)], [16 MiB (seit 4.0)],
  [Mandanten-Trennung], [Accounts], [Virtual Hosts],
  [Rechte], [Publish/Subscribe pro Subject], [configure/write/read pro Ressource, Topic-Rechte],
  [Betrieb], [ein kleines Binary, sehr ressourcenschonend], [Erlang-basiert, umfangreiche Verwaltungsoberfläche],
  [Python-Client], [`nats-py`], [`aio-pika` (asynchron), `pika` (synchron)],
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

#import "lib.typ": *

= RabbitMQ mit Python

Für RabbitMQ gibt es zwei verbreitete Python-Clients: `pika` (synchron) und `aio-pika` (asynchron, `uv add aio-pika`). Dieses Kapitel verwendet `aio-pika`, damit die Beispiele denen für NATS entsprechen. Aufgebaut wird dieselbe Strecke: `shop` sendet, `provisionierung` verarbeitet, gescheiterte Nachrichten landen in einer Dead-Letter-Queue.

== Topologie anlegen

Wie bei NATS gehören Exchanges, Queues und Bindings nicht in den Startcode der Dienste, sondern in die Einrichtung. RabbitMQ kann die gesamte Topologie beim Start aus einer Definitionsdatei laden (`load_definitions` in `rabbitmq.conf`), alternativ legt ein Einrichtungsskript mit Administratorrechten sie an:

#datei("einrichtung/rabbitmq_topologie.py")[
```python
import aio_pika

async def einrichten(url: str) -> None:
    async with await aio_pika.connect_robust(url) as verbindung:
        kanal = await verbindung.channel()
        ereignisse = await kanal.declare_exchange("ereignisse", aio_pika.ExchangeType.TOPIC, durable=True)
        dlx = await kanal.declare_exchange("dlx", aio_pika.ExchangeType.DIRECT, durable=True)

        queue = await kanal.declare_queue("provisionierung", durable=True, arguments={
            "x-queue-type": "quorum",
            "x-delivery-limit": 5,                          # nach 5 Zustellungen aussortieren
            "x-dead-letter-exchange": "dlx",
            "x-dead-letter-routing-key": "provisionierung",
        })
        await queue.bind(ereignisse, routing_key="bestellung.eingegangen")

        dlq = await kanal.declare_queue("provisionierung.dlq", durable=True,
                                        arguments={"x-queue-type": "quorum"})
        await dlq.bind(dlx, routing_key="provisionierung")
```
]

Die Nachricht durchläuft damit: Exchange `ereignisse` -> Queue `provisionierung` -> (nach fünf gescheiterten Zustellungen oder einem `reject` ohne Requeue) Exchange `dlx` -> Queue `provisionierung.dlq`.

== Der Producer

#datei("shop/nachrichten.py")[
```python
import json, uuid
from datetime import datetime, timezone
import aio_pika

async def verbinden(url: str) -> aio_pika.abc.AbstractRobustConnection:
    return await aio_pika.connect_robust(url, client_properties={"connection_name": "shop"})

async def bestellung_melden(verbindung, bestellung_id: str, positionen: list[dict]) -> None:
    kanal = await verbindung.channel(publisher_confirms=True, on_return_raises=True)
    ereignisse = await kanal.get_exchange("ereignisse", ensure=False)   # nicht selbst anlegen
    nachricht = aio_pika.Message(
        body=json.dumps({"bestellung_id": bestellung_id, "positionen": positionen}).encode(),
        content_type="application/json",
        delivery_mode=aio_pika.DeliveryMode.PERSISTENT,          # auf Platte speichern
        message_id=str(uuid.uuid4()),                            # für Deduplizierung beim Empfänger
        timestamp=datetime.now(timezone.utc),
        type="bestellung.eingegangen",
    )
    await ereignisse.publish(nachricht, routing_key="bestellung.eingegangen",
                             mandatory=True, timeout=5)
```
]

- *Publisher Confirms:* Mit `publisher_confirms=True` (bei `aio-pika` der Standard) wartet `publish` auf die Bestätigung des Brokers, dass die Nachricht angenommen und bei Quorum Queues repliziert gespeichert wurde. Bleibt sie aus, gibt es eine Ausnahme und der Producer sendet erneut.
- *`mandatory=True`:* Passt keine Queue zum Routing Key, meldet RabbitMQ die Nachricht als unzustellbar zurück, statt sie stillschweigend zu verwerfen. Mit `on_return_raises=True` am Kanal wird daraus eine Ausnahme beim `publish`. Ohne beides würde ein Tippfehler im Routing Key zu unbemerktem Datenverlust führen.
- *`message_id`:* RabbitMQ dedupliziert nicht selbst. Die ID ermöglicht dem Consumer, Duplikate zu erkennen (Kapitel 7).

== Der Consumer

#datei("provisionierung/worker.py")[
```python
import asyncio, json, logging
import aio_pika

log = logging.getLogger("provisionierung")
# verarbeiten(), VoruebergehenderFehler, DauerhafterFehler wie in Kapitel 4

async def worker(url: str, stopp: asyncio.Event) -> None:
    verbindung = await aio_pika.connect_robust(url, client_properties={"connection_name": "provisionierung"})
    async with verbindung:
        kanal = await verbindung.channel()
        await kanal.set_qos(prefetch_count=10)                 # höchstens 10 unbestätigte gleichzeitig
        queue = await kanal.get_queue("provisionierung", ensure=False)
        async with queue.iterator() as nachrichten:
            async for msg in nachrichten:
                try:
                    await verarbeiten(json.loads(msg.body))
                    await msg.ack()
                except VoruebergehenderFehler:
                    await msg.nack(requeue=True)               # erneut zustellen, zählt zum Limit
                except (DauerhafterFehler, json.JSONDecodeError):
                    log.error("aussortiert: %s", msg.message_id)
                    await msg.reject(requeue=False)            # direkt in die Dead-Letter-Queue
                if stopp.is_set():
                    break
```
]

#table(columns: (auto, 1fr),
  [Aufruf], [Wirkung],
  [`msg.ack()`], [erfolgreich verarbeitet, RabbitMQ löscht die Nachricht aus der Queue],
  [`msg.nack(requeue=True)`], [zurück in die Queue, erneute Zustellung (zählt bei Quorum Queues zur `x-delivery-limit`)],
  [`msg.reject(requeue=False)`], [endgültig abgelehnt, wird an den Dead-Letter-Exchange weitergeleitet],
  [`kanal.set_qos(prefetch_count=10)`], [Obergrenze für gleichzeitig zugestellte, unbestätigte Nachrichten pro Consumer],
)

Ohne `prefetch_count` schiebt RabbitMQ einem Consumer beliebig viele Nachrichten zu, die dann im Speicher des Consumers liegen und für andere Instanzen blockiert sind. Ein Wert zwischen 10 und 100 ist ein guter Start.

#tipp[Anders als JetStream kennt RabbitMQ kein `nak` mit Verzögerung. Für wachsende Abstände zwischen Wiederholungen legt man eine Warteschlange mit Ablaufzeit (`x-message-ttl`) an, deren Dead-Letter-Ziel wieder die Arbeitsqueue ist: Der Consumer lehnt ab, die Nachricht wartet in der Warteschlange und kehrt nach Ablauf zurück. Für einfache Fälle genügt das sofortige Requeue mit der Obergrenze aus `x-delivery-limit`.]

#achtung[Seit RabbitMQ 4.0 haben Quorum Queues standardmäßig eine Zustellobergrenze von 20. Ist kein Dead-Letter-Exchange konfiguriert, werden Nachrichten nach 20 gescheiterten Zustellungen *gelöscht*. Jede Quorum Queue braucht deshalb ein Dead-Letter-Ziel, am besten per Policy für alle Queues eines vhosts.]

#import "lib.typ": *

= NATS JetStream mit Python

Der offizielle Python-Client heißt `nats-py` @nats-io-download (`uv add nats-py`). Er arbeitet vollständig mit `asyncio` @github-com-nats-io-nats-py. Dieses Kapitel baut den Producer im `shop` und den Consumer in `provisionierung`, zunächst ohne Sicherheitsfunktionen, die Teil III ergänzt.

== Stream und Consumer anlegen

Streams und Consumer sind Infrastruktur und gehören nicht in den Startcode jedes Dienstes. Legt jeder Dienst sie selbst an, braucht er dafür weitreichende Rechte (Kapitel 9). Besser: Einmalig beim Deployment mit dem `nats`-Werkzeug oder einem eigenen Einrichtungsskript unter einem Administrationskonto:

```bash
nats stream add BESTELLUNGEN --subjects "bestellung.>" --storage file \
  --retention limits --max-age 30d --dupe-window 2m --replicas 1 --defaults

nats consumer add BESTELLUNGEN provisionierung --pull --filter bestellung.eingegangen \
  --ack explicit --max-deliver 5 --wait 60s --deliver all --defaults
```

#table(columns: (auto, 1fr),
  [Einstellung], [Bedeutung],
  [`--storage file`], [auf Platte speichern (sonst Arbeitsspeicher, Verlust bei Neustart) @docs-nats-io-learn-jetstream-policies],
  [`--retention limits`, `--max-age 30d`], [Nachrichten 30 Tage aufheben, auch nach Verarbeitung (Historie, Nachverarbeitung) @docs-nats-io-learn-jetstream-retention-policies @docs-nats-io-learn-jetstream-shaping-the-stream],
  [`--dupe-window 2m`], [Nachrichten mit gleicher `Nats-Msg-Id` innerhalb von zwei Minuten nur einmal speichern @docs-nats-io-nats-concepts-jetstream-streams],
  [`--replicas`], [Anzahl der Kopien im Cluster (1 bei einem Server, 3 im Cluster) @docs-nats-io-learn-jetstream-surviving-node-loss],
  [`--ack explicit`], [jede Nachricht einzeln bestätigen @docs-nats-io-learn-jetstream-acknowledgment],
  [`--max-deliver 5`], [höchstens fünfmal zustellen, dann aufgeben @docs-nats-io-learn-jetstream-acknowledgment],
  [`--wait 60s`], [_ack wait_: ohne Bestätigung nach 60 Sekunden erneut zustellen @docs-nats-io-learn-jetstream-acknowledgment],
)

Die Optionen entsprechen den Flags des `nats`-Werkzeugs @github-com-nats-io-natscli-blob-main-cli-stream-command-go @github-com-nats-io-natscli-blob-main-cli-consumer-command-go.

== Der Producer

#datei("shop/nachrichten.py")[
```python
import json, uuid
import nats
from nats.js.errors import NoStreamResponseError

async def verbinden() -> nats.NATS:
    return await nats.connect(
        servers=["nats://nats.example.com:4222"],
        name="shop",                          # erscheint in der Überwachung
        max_reconnect_attempts=-1,            # bei Netzproblemen unbegrenzt neu verbinden
    )

async def bestellung_melden(nc: nats.NATS, bestellung_id: str, positionen: list[dict]) -> None:
    js = nc.jetstream()
    nachricht_id = str(uuid.uuid4())
    daten = json.dumps({"bestellung_id": bestellung_id, "positionen": positionen}).encode()
    ack = await js.publish(
        "bestellung.eingegangen",
        daten,
        headers={"Nats-Msg-Id": nachricht_id},   # Deduplizierung im Stream
        timeout=5,
    )
    if ack.duplicate:
        print(f"bereits gespeichert: {nachricht_id}")
```
]

`js.publish` wartet auf die Bestätigung (_PubAck_) des Streams @docs-nats-io-learn-jetstream-publishing @nats-io-github-io-nats-py-modules-html, erst dann hat der Stream die Nachricht gespeichert. Bleibt sie aus, wirft der Aufruf eine Ausnahme (Zeitüberschreitung oder `NoStreamResponseError`, wenn kein Stream das Subject speichert @docs-nats-io-learn-jetstream-publishing @nats-io-github-io-nats-py-modules-html). Der Aufrufer muss dann erneut senden, *mit derselben `Nats-Msg-Id`*, damit ein doch angekommenes Original nicht doppelt gespeichert wird @docs-nats-io-learn-jetstream-publishing. Deshalb wird die ID einmal erzeugt und bei Wiederholungen beibehalten, idealerweise aus der Outbox (Kapitel 7). Eine bestätigte Nachricht ist allerdings nicht zwingend schon auf der Platte: Der Server ruft `fsync` standardmäßig nur alle zwei Minuten auf und bestätigt sofort, nach einem Absturz des Betriebssystems können kürzlich bestätigte Nachrichten fehlen @jepsen-io-analyses-nats-2-12-1.

#achtung[Ein einfaches `nc.publish(...)` (ohne `jetstream()`) ist Core NATS: Es gibt keine Bestätigung, und ist gerade kein Empfänger verbunden, ist die Nachricht weg @docs-nats-io-nats-concepts-jetstream @docs-nats-io-learn-jetstream-publishing. Für Geschäftsvorgänge immer `js.publish` verwenden.]

== Der Consumer

#datei("provisionierung/worker.py")[
```python
import asyncio, json, logging
import nats
from nats.errors import TimeoutError as NatsTimeout

log = logging.getLogger("provisionierung")

class VoruebergehenderFehler(Exception): ...     # z.B. Partnerdienst nicht erreichbar
class DauerhafterFehler(Exception): ...          # z.B. ungültige Nachricht

async def verarbeiten(daten: dict) -> None: ...  # eigentliche Arbeit, idempotent (Kapitel 7)

async def worker(stopp: asyncio.Event) -> None:
    nc = await nats.connect(servers=["nats://nats.example.com:4222"], name="provisionierung")
    js = nc.jetstream()
    psub = await js.pull_subscribe_bind("provisionierung", stream="BESTELLUNGEN")
    while not stopp.is_set():
        try:
            nachrichten = await psub.fetch(batch=10, timeout=5)
        except NatsTimeout:
            continue                                        # nichts da, weiter warten
        for msg in nachrichten:
            versuch = msg.metadata.num_delivered
            try:
                await verarbeiten(json.loads(msg.data))
                await msg.ack()
            except VoruebergehenderFehler:
                await msg.nak(delay=min(2 ** versuch, 300))  # wachsender Abstand
            except (DauerhafterFehler, json.JSONDecodeError):
                log.error("aussortiert: %s", msg.headers)
                await msg.term()                             # nie wieder zustellen
    await nc.drain()                                         # offene Arbeit sauber beenden
```
]

#table(columns: (auto, 1fr),
  [Aufruf], [Wirkung],
  [`msg.ack()`], [erfolgreich verarbeitet, der Consumer rückt vor @docs-nats-io-learn-jetstream-acknowledgment],
  [`msg.nak(delay=...)`], [fehlgeschlagen, nach der Verzögerung erneut zustellen (zählt als Zustellversuch) @docs-nats-io-learn-jetstream-acknowledgment @nats-io-github-io-nats-py-modules-html],
  [`msg.in_progress()`], [noch in Arbeit: setzt die Frist `ack_wait` zurück, für lange Verarbeitungen @docs-nats-io-learn-jetstream-acknowledgment @nats-io-github-io-nats-py-modules-html],
  [`msg.term()`], [endgültig aufgeben, keine weitere Zustellung @docs-nats-io-learn-jetstream-acknowledgment @nats-io-github-io-nats-py-modules-html],
  [`msg.metadata.num_delivered`], [wie oft diese Nachricht schon zugestellt wurde @nats-io-github-io-nats-py-modules-html],
)

`pull_subscribe_bind` bindet sich an den bereits angelegten Consumer, statt ihn selbst zu erzeugen @nats-io-github-io-nats-py-modules-html. Ein leerer Abruf ist kein Fehler: `fetch` liefert dann nach Ablauf des Timeouts nichts zurück (die Bibliothek wirft dazu einen `TimeoutError`), und der Worker wartet einfach weiter @docs-nats-io-learn-jetstream-pull-consumers @nats-io-github-io-nats-py-modules-html. Starten mehrere Instanzen des Workers mit demselben Consumer-Namen, verteilt JetStream die Nachrichten automatisch auf sie @docs-nats-io-learn-jetstream-worker-pool. Am Ende beendet `drain()` die Verbindung geordnet: Es lässt bereits empfangene Nachrichten fertig verarbeiten und sendet ausstehende Veröffentlichungen ab, bevor die Verbindung schließt. Bestätigen muss der Worker selbst, `drain()` bestätigt keine Nachrichten @docs-nats-io-learn-resilient-clients-drain-and-shutdown.

=== Dead Letters in NATS

JetStream hat keinen eingebauten Dead-Letter-Speicher @www-synadia-com-blog-jetstream-reliable-delivery-dlq-replay. Zwei übliche Wege: Die Anwendung veröffentlicht eine aussortierte Nachricht vor dem `term()` selbst auf ein eigenes Subject wie `dlq.provisionierung` (das ein eigener Stream speichert), oder ein Überwachungsdienst lauscht auf die Meldungen, die JetStream beim Erreichen von `max_deliver` verschickt (_Advisories_ unter `$JS.EVENT.ADVISORY.CONSUMER.MAX_DELIVERIES.>` @docs-nats-io-reference-jetstream-advisory-max-deliver), und holt die betroffene Nachricht anhand ihrer Sequenznummer aus dem Stream @www-synadia-com-blog-jetstream-reliable-delivery-dlq-replay. Der erste Weg ist einfacher und deckt beide Fälle ab, wenn der Worker bei `num_delivered == max_deliver` selbst aussortiert.

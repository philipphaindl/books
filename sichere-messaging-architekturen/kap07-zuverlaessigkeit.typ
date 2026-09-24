#import "lib.typ": *

= Zuverlässigkeit in der Anwendung

Die Broker liefern at-least-once, wenn Producer und Consumer richtig bestätigen. Zwei Lücken schließt aber nur die Anwendung selbst: Eine Datenbankänderung und die zugehörige Nachricht müssen *gemeinsam* gelingen oder scheitern, und eine doppelt zugestellte Nachricht darf nicht doppelt wirken.

== Das Problem der zwei Schreibvorgänge

Der Shop speichert eine Bestellung in PostgreSQL und veröffentlicht danach `bestellung.eingegangen`. Was, wenn der Dienst genau dazwischen abstürzt? Die Bestellung existiert, die Nachricht nie, die Provisionierung passiert nicht. Andersherum (erst senden, dann speichern) kann eine Nachricht für eine Bestellung existieren, deren Transaktion scheitert. Eine gemeinsame Transaktion über Datenbank und Broker gibt es nicht.

== Transactional Outbox

Die Lösung: Die Nachricht wird *in derselben Datenbanktransaktion* wie die Bestellung in eine Tabelle `outbox` geschrieben. Ein separater Prozess (_Relay_) liest die Tabelle und veröffentlicht. Beide Schreibvorgänge liegen damit in einer Transaktion, und das Veröffentlichen wird so lange wiederholt, bis es gelingt.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    rahmen((0, -1.6), (6.4, 1.5), [eine Datenbanktransaktion], c-yellow)
    kasten((3.2, 0.45), [`INSERT INTO bestellungen`], w: 5.2, h: 0.65, bg: white, col: c-yellow.darken(10%), size: 7pt)
    kasten((3.2, -0.55), [`INSERT INTO outbox (id, type, daten)`], w: 5.2, h: 0.65, bg: white, col: c-yellow.darken(10%), size: 7pt)
    kasten((9.0, -0.55), [Relay \ #text(size: 6.3pt)[liest ungesendete Zeilen]], w: 2.6, h: 1.0, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
    kasten((13.3, -0.55), [Broker \ #text(size: 6.3pt)[dedupliziert per `id`]], w: 2.6, h: 1.0, bg: rgb("#E7F4F2"), col: c-teal, size: 7.3pt)
    pfeil((5.85, -0.55), (7.65, -0.55))
    pfeil((10.35, -0.45), (11.95, -0.45), label: "publish", loff: (0, 0.22))
    pfeil((11.95, -0.75), (10.35, -0.75), label: "ack", loff: (0, -0.2), color: c-teal)
    content((9.0, -1.5), text(size: 6.5pt, fill: c-grey.darken(20%), style: "italic")[markiert als gesendet])
  }),
  caption: [Bestellung und Nachricht entstehen atomar. Der Relay veröffentlicht mit der Outbox-ID als Nachrichten-ID.],
)

#datei("shop/outbox.py")[
```python
async def relay(pool, js, stopp: asyncio.Event) -> None:
    while not stopp.is_set():
        async with pool.connection() as db, db.transaction():
            zeilen = await (await db.execute(
                """SELECT id, type, daten FROM outbox
                   WHERE gesendet_am IS NULL ORDER BY erstellt_am
                   LIMIT 100 FOR UPDATE SKIP LOCKED""")).fetchall()
            for id_, typ, daten in zeilen:
                await js.publish(typ, daten, headers={"Nats-Msg-Id": str(id_)}, timeout=5)
                await db.execute("UPDATE outbox SET gesendet_am = now() WHERE id = %s", (id_,))
        if not zeilen:
            await asyncio.sleep(1)
```
]

Stürzt der Relay nach dem Senden, aber vor dem `UPDATE` ab, sendet er die Nachricht beim nächsten Durchlauf erneut. Weil die Outbox-ID als `Nats-Msg-Id` dient, erkennt JetStream das Duplikat innerhalb des Zeitfensters. Bei RabbitMQ wird dieselbe ID als `message_id` gesetzt und erst der Consumer erkennt das Duplikat. `FOR UPDATE SKIP LOCKED` erlaubt mehrere Relay-Instanzen, ohne dass sie sich dieselben Zeilen teilen.

== Idempotente Consumer

Das Gegenstück auf der Empfängerseite: Der Consumer merkt sich, welche Nachrichten-IDs er verarbeitet hat, *in derselben Transaktion* wie die eigentliche Wirkung:

#datei("provisionierung/verarbeitung.py")[
```python
async def verarbeiten(pool, umschlag: Umschlag) -> None:
    async with pool.connection() as db, db.transaction():
        neu = await (await db.execute(
            """INSERT INTO verarbeitet (nachricht_id, typ) VALUES (%s, %s)
               ON CONFLICT (nachricht_id) DO NOTHING RETURNING nachricht_id""",
            (umschlag.id, umschlag.type))).fetchone()
        if neu is None:
            return                                    # schon verarbeitet: nichts tun, trotzdem ack
        await provisionierung_anlegen(db, umschlag.data)
```
]

Kommt die Nachricht ein zweites Mal, scheitert das `INSERT` am Primärschlüssel, die Funktion kehrt ohne Wirkung zurück, und der Worker bestätigt die Nachricht. Wird die Transaktion durch einen Fehler abgebrochen, verschwindet auch der Eintrag in `verarbeitet`, und die nächste Zustellung versucht es erneut. Die Tabelle `verarbeitet` wird regelmäßig um Einträge bereinigt, die älter sind als die längste mögliche Wiederholungszeit.

Wo keine Datenbank beteiligt ist, lässt sich Idempotenz oft über die Operation selbst erreichen: "Setze Status auf *aktiv*" ist von Natur aus idempotent, "erhöhe Zähler um 1" nicht.

== Wiederholen, aussortieren, wieder einspielen

#table(columns: (auto, 1fr),
  [Fehlerart], [Behandlung],
  [vorübergehend (Netzwerk, Partner überlastet, Sperre in der DB)], [erneut zustellen mit wachsendem Abstand (NATS `nak(delay)`, RabbitMQ Warteschlange mit TTL)],
  [dauerhaft (ungültiges Schema, ungültige Signatur, unbekannter Typ)], [sofort aussortieren: NATS `term()` plus eigenes Dead-Letter-Subject, RabbitMQ `reject(requeue=False)`],
  [unklar (Programmfehler)], [begrenzte Wiederholungen, danach Dead Letter. Nach dem Bugfix gezielt wieder einspielen.],
)

Dead Letters sind kein Mülleimer, sondern eine Arbeitsliste: Jede Nachricht darin bedeutet einen Vorgang, der nicht abgeschlossen wurde. Die Länge der Dead-Letter-Queues gehört deshalb in die Überwachung (Kapitel 11). Zum Wiedereinspielen liest ein kleines Werkzeug die Dead Letters, prüft sie und veröffentlicht sie mit *derselben* Nachrichten-ID erneut, damit bereits teilweise verarbeitete Vorgänge nicht doppelt wirken.

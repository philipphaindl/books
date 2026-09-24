#import "lib.typ": *
#set heading(numbering: none)
= Bevor es losgeht

Sobald mehrere Dienste zusammenarbeiten, stellt sich die Frage, wie sie miteinander sprechen. Direkte HTTP-Aufrufe sind einfach, koppeln die Dienste aber eng: Ist einer langsam oder ausgefallen, bleiben alle stehen, die ihn aufrufen. Nachrichtenbasierte Architekturen entkoppeln die Dienste über einen *Broker*, der Nachrichten zwischenspeichert und verteilt. Das bringt Robustheit, aber auch neue Fragen: Was passiert, wenn eine Nachricht verloren geht oder doppelt ankommt? Wer darf welche Nachrichten senden und lesen? Wie erkennt ein Empfänger, dass eine Nachricht echt ist?

Dieses Handbuch beantwortet diese Fragen für Python mit zwei Brokern, die gleichwertig behandelt werden: *NATS JetStream* und *RabbitMQ*.

== Aufbau

- *Teil I, Grundlagen:* wofür Messaging gut ist, welche Muster es gibt, was Zustellgarantien bedeuten, und wie NATS JetStream und RabbitMQ aufgebaut sind.
- *Teil II, mit Python:* Produzenten und Konsumenten mit `nats-py` und `aio-pika`, das Gestalten von Nachrichten und die Muster, die ein System zuverlässig machen (Outbox, idempotente Konsumenten, Dead Letters).
- *Teil III, Sicherheit und Betrieb:* TLS und Authentifizierung, minimale Rechte pro Dienst, signierte und verschlüsselte Nachrichten, Überwachung.
- *Anhang:* Checkliste und Glossar.

== Konventionen

Code, Ausgaben und Dateien erscheinen wie in den übrigen Handbüchern. In den Grafiken gilt:

#align(center, cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let leg = (([Producer (sendet)], c-blue), ([Broker, Stream, Queue], c-teal), ([Consumer (empfängt)], c-accent), ([Nachricht], c-yellow), ([Schlüssel, Identität], c-violet), ([Angriff / Fehler], c-red))
  for (i, l) in leg.enumerate() {
    let x = calc.rem(i, 3) * 5.2
    let y = -calc.floor(i / 3) * 0.75
    rect((x, y - 0.22), (x + 0.6, y + 0.22), radius: 0.06, fill: l.at(1).lighten(86%), stroke: (paint: l.at(1), thickness: 0.8pt))
    content((x + 0.8, y), anchor: "west", text(size: 8pt, l.at(0)))
  }
}))

Das durchgängige Beispiel ist ein Bestellablauf: Der Dienst `shop` meldet eine eingegangene Bestellung. Der Dienst `provisionierung` richtet daraufhin die bestellten Leistungen ein und meldet den Abschluss, der Dienst `benachrichtigung` informiert den Kunden. Die Ereignisse heißen `bestellung.eingegangen` und `provisionierung.abgeschlossen`. Alle Beispiele verwenden `asyncio`, weil beide Client-Bibliotheken asynchron arbeiten.

#merke[Das Leitmotiv dieses Buchs: *Jede Nachricht kann verloren gehen, doppelt ankommen, zu spät ankommen oder gefälscht sein*, solange das System nicht ausdrücklich dagegen gebaut ist. Die Kapitel zeigen, wie man jedes dieser vier Probleme löst.]

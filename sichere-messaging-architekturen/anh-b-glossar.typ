#import "lib.typ": *

= Glossar und Quellen

#let begriffe = (
  ([Ack / Nack], [Bestätigung bzw. Ablehnung einer empfangenen Nachricht durch den Consumer.]),
  ([Account (NATS)], [Isolierter Bereich mit eigenen Subjects, Streams und Benutzern.]),
  ([at-least-once], [Zustellgarantie: nichts geht verloren, Duplikate sind möglich.]),
  ([Binding], [Regel in RabbitMQ, die eine Queue mit einem Exchange und einem Muster verbindet.]),
  ([Claim Check], [Muster, bei dem große Inhalte extern gespeichert und nur per Verweis verschickt werden.]),
  ([Consumer], [Empfänger von Nachrichten, bei JetStream zugleich eine benannte Leseposition.]),
  ([Dead Letter], [Nachricht, die endgültig nicht verarbeitet werden konnte und aussortiert wurde.]),
  ([Exchange], [Verteiler in RabbitMQ, an den Producer senden.]),
  ([Idempotenz], [Mehrfache Verarbeitung hat dieselbe Wirkung wie einmalige.]),
  ([Inbox], [Temporäres Antwort-Subject in NATS für Bestätigungen und Request/Reply.]),
  ([JetStream], [Persistenzschicht von NATS mit Streams und Consumern.]),
  ([mTLS], [TLS, bei dem sich auch der Client mit einem Zertifikat ausweist.]),
  ([Outbox], [Tabelle, in die Nachrichten in derselben Transaktion wie die Geschäftsdaten geschrieben werden.]),
  ([Prefetch], [Obergrenze unbestätigter Nachrichten pro Consumer in RabbitMQ.]),
  ([Publisher Confirm], [Bestätigung von RabbitMQ an den Producer, dass eine Nachricht angenommen wurde.]),
  ([PubAck], [Bestätigung eines JetStream-Streams, dass eine Nachricht gespeichert wurde.]),
  ([Quorum Queue], [Replizierte, dauerhafte Queue in RabbitMQ auf Basis von Raft.]),
  ([Replay], [Erneutes Einspielen einer (abgefangenen) Nachricht.]),
  ([Routing Key], [Adressangabe einer Nachricht in RabbitMQ, ausgewertet vom Exchange.]),
  ([Stream], [Dauerhaft gespeicherte, geordnete Folge von Nachrichten.]),
  ([Subject], [Hierarchischer Nachrichtenname in NATS, z.B. `bestellung.eingegangen`.]),
  ([vhost], [Virtueller Host in RabbitMQ: vollständig getrennter Bereich mit eigenen Rechten.]),
)

#set text(size: 8.2pt)
#columns(2, gutter: 16pt)[
  #for (b, d) in begriffe [
    #block(below: 0.5em, breakable: false)[*#b* \ #d]
  ]
]

#v(0.2em)
#heading(level: 2, numbering: none)[Weiterführende Quellen]

- *NATS-Dokumentation*, besonders JetStream, Security und Authorization: https://docs.nats.io
- *nats-py*: https://github.com/nats-io/nats.py
- *RabbitMQ-Dokumentation*, besonders Quorum Queues, Access Control und TLS: https://www.rabbitmq.com/docs
- *aio-pika*: https://docs.aio-pika.com
- *CloudEvents-Spezifikation*: https://cloudevents.io
- *cryptography* (Ed25519, AES-GCM): https://cryptography.io
- Begleitbände: *Secure API Design* (Autorisierung, Logging), *Docker von Grund auf* (Secrets, Betrieb)

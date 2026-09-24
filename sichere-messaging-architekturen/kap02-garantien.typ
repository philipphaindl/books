#import "lib.typ": *

= Zustellgarantien

Die wichtigste Frage an jedes Messaging-System lautet: Wie oft kommt eine Nachricht an? Die ehrliche Antwort ist bei jedem Broker dieselbe: Ohne Vorkehrungen *mindestens einmal oder gar nicht*. Wer das verstanden hat, baut Systeme, die mit beidem umgehen.

== Drei Garantien, eine realistische

#table(columns: (auto, 1fr, 1fr),
  [Garantie], [Bedeutung], [Wann sinnvoll],
  [*at-most-once*], [höchstens einmal: Nachrichten können verloren gehen, kommen aber nie doppelt], [Messwerte, bei denen der nächste Wert den verlorenen ersetzt],
  [*at-least-once*], [mindestens einmal: nichts geht verloren, aber Duplikate sind möglich], [*Standard für Geschäftsvorgänge*],
  [*exactly-once*], [genau einmal], [über ein Netzwerk nicht allein durch den Broker erreichbar],
)

"Genau einmal" scheitert an einer einfachen Tatsache: Ein Konsument verarbeitet eine Nachricht und schickt die Bestätigung (_ack_). Geht die Bestätigung verloren oder stürzt der Konsument genau zwischen Verarbeitung und Bestätigung ab, weiß der Broker nicht, ob verarbeitet wurde, und stellt die Nachricht erneut zu. Was sich erreichen lässt, ist *effektiv einmal*: at-least-once-Zustellung plus Empfänger, die Duplikate erkennen und ignorieren (_idempotente Konsumenten_, Kapitel 7).

== Wo Nachrichten verloren gehen oder sich verdoppeln

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [Producer], w: 2.0, h: 0.9, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((6.2, 0), [Broker \ #text(size: 6.5pt)[persistiert auf Platte]], w: 2.8, h: 1.0, bg: rgb("#E7F4F2"), col: c-teal)
    kasten((12.4, 0), [Consumer], w: 2.0, h: 0.9, bg: rgb("#FDF1EC"), col: c-accent)
    pfeil((1.05, 0.2), (4.75, 0.2), label: "1 publish", loff: (0, 0.2))
    pfeil((4.75, -0.2), (1.05, -0.2), label: "2 PubAck / Confirm", loff: (0, -0.22), color: c-teal)
    pfeil((7.65, 0.2), (11.35, 0.2), label: "3 zustellen", loff: (0, 0.2))
    pfeil((11.35, -0.2), (7.65, -0.2), label: "4 ack nach Verarbeitung", loff: (0, -0.22), color: c-accent)
    content((2.9, -1.2), text(size: 6.8pt, fill: c-red)[ohne 2: Verlust unbemerkt])
    content((2.9, -1.55), text(size: 6.8pt, fill: c-red)[2 verloren: Producer sendet erneut])
    content((9.5, -1.2), text(size: 6.8pt, fill: c-red)[ack vor Verarbeitung: Verlust bei Absturz])
    content((9.5, -1.55), text(size: 6.8pt, fill: c-red)[4 verloren: erneute Zustellung])
  }),
  caption: [Zwei Bestätigungen sichern die Strecke ab. Jede Lücke erzeugt Verlust oder Duplikate.],
)

Daraus ergeben sich die Regeln für at-least-once:

+ *Der Broker speichert dauerhaft:* Streams bzw. Queues auf Platte (JetStream `storage: file`, RabbitMQ Quorum Queues und persistente Nachrichten).
+ *Der Producer wartet auf die Bestätigung des Brokers* und sendet bei Ausbleiben erneut. Das kann Duplikate erzeugen, die der Broker über eine Nachrichten-ID erkennt (Kapitel 4 und 5).
+ *Der Consumer bestätigt erst nach erfolgreicher Verarbeitung*, nie beim Empfang. Nicht bestätigte Nachrichten stellt der Broker nach einer Frist erneut zu.
+ *Der Consumer ist idempotent*, weil Wiederholungen trotz allem vorkommen.

== Reihenfolge

Beide Broker halten die Reihenfolge innerhalb eines Streams bzw. einer Queue ein, *solange genau ein Konsument liest und nichts wiederholt wird*. Mit mehreren parallelen Konsumenten oder nach einer erneuten Zustellung kann eine spätere Nachricht vor einer früheren verarbeitet werden. Systeme sollten deshalb so gebaut sein, dass sie Reihenfolge nicht voraussetzen: Ereignisse tragen einen Zeitstempel oder eine Versionsnummer, und der Empfänger ignoriert veraltete Zustände. Wo Reihenfolge zwingend ist (etwa pro Bestellung), verarbeitet man pro Schlüssel sequenziell.

== Giftige Nachrichten und Dead Letters

Eine Nachricht, deren Verarbeitung immer wieder fehlschlägt (ungültiges Format, Fehler im Code, dauerhaft fehlende Daten), würde ohne Begrenzung endlos erneut zugestellt, Ressourcen verbrauchen und andere Nachrichten blockieren. Dagegen helfen drei Bausteine:

#table(columns: (auto, 1fr),
  [Baustein], [Wirkung],
  [*Höchstzahl an Zustellungen*], [JetStream: `max_deliver` am Consumer. RabbitMQ: `x-delivery-limit` an Quorum Queues (seit 4.0 standardmäßig 20).],
  [*Verzögerte Wiederholung*], [vorübergehende Fehler (Partner nicht erreichbar) mit wachsendem Abstand erneut versuchen, statt sofort],
  [*Dead-Letter-Ziel*], [Nachrichten, die endgültig scheitern, landen in einer eigenen Queue bzw. einem eigenen Subject, werden überwacht, untersucht und nach der Korrektur gezielt erneut eingespielt],
)

Ein wichtiges Detail: Die Verarbeitung muss zwischen *vorübergehenden* Fehlern (erneut versuchen) und *dauerhaften* Fehlern (sofort als Dead Letter aussortieren) unterscheiden. Eine Nachricht mit ungültiger Signatur wird durch zwanzig Wiederholungen nicht gültig.

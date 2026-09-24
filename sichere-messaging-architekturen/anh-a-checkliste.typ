#import "lib.typ": *

= Checkliste

#let pkt(..xs) = table(columns: (auto, 1fr), stroke: (x, y) => (bottom: 0.4pt + luma(222)), fill: none,
  ..xs.pos().map(x => ([☐], x)).flatten())
#show table.cell.where(y: 0): set text(weight: "regular")

#columns(2, gutter: 16pt)[
#text(size: 8pt, weight: "bold", fill: c-accent)[ZUVERLÄSSIGKEIT]
#pkt(
  [Streams (`storage: file`) bzw. Quorum Queues, persistente Nachrichten],
  [Producer wartet auf PubAck bzw. Publisher Confirm],
  [Nachrichten-ID pro Nachricht, bei Wiederholung beibehalten],
  [RabbitMQ: `mandatory` + `on_return_raises`],
  [Ack erst nach erfolgreicher Verarbeitung],
  [Höchstzahl an Zustellungen, verzögerte Wiederholung],
  [Dead-Letter-Ziel für jede Queue bzw. jeden Consumer],
  [Transactional Outbox beim Producer],
  [Idempotenter Consumer (Tabelle `verarbeitet`)],
  [Keine Annahme über Reihenfolge ohne Absicherung],
)
#text(size: 8pt, weight: "bold", fill: c-accent)[NACHRICHTEN]
#pkt(
  [Einheitlicher Umschlag mit `id`, `type`, `version`, `source`, `time`],
  [Pydantic-Validierung auf beiden Seiten, `extra="forbid"`],
  [Versionierung, Consumer vor Producern aktualisieren],
  [IDs statt personenbezogener Daten, keine Geheimnisse],
  [Große Inhalte als Verweis (Claim Check)],
)
#colbreak()
#text(size: 8pt, weight: "bold", fill: c-accent)[SICHERHEIT]
#pkt(
  [TLS für alle Verbindungen, unverschlüsselte Ports aus],
  [mTLS mit interner CA],
  [Eigenes Konto pro Dienst, `guest` gelöscht],
  [Rechtematrix: senden und empfangen pro Dienst],
  [NATS: Subject-Rechte, eigenes Inbox-Präfix, Accounts],
  [RabbitMQ: configure `^$` für Dienste, Topic-Rechte, vhosts],
  [Topologie nur durch Einrichtungskonto],
  [Signaturen mit Typ-Freigabe pro Schlüssel],
  [Replay-Schutz: Zeitstempel + Deduplizierung],
  [Verschlüsselung für unvermeidbar sensible Inhalte],
  [Schlüssel als Secrets, pro Umgebung, mit Wechselplan],
  [Verwaltungsoberflächen nur über VPN/lokal],
)
#text(size: 8pt, weight: "bold", fill: c-accent)[BETRIEB]
#pkt(
  [Alarme: Rückstand, Dead Letters, fehlende Consumer],
  [Rechteverletzungen und ungültige Signaturen gemeldet],
  [Korrelations-ID in allen Logs und Folgenachrichten],
  [Topologie als Code im Repository],
)
]

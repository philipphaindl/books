# Quellenprüfung: inhaltliche Änderungen am Text (Stand 2026-10-01)

Beim Einarbeiten der Literaturverweise wurden die Aussagen gegen die Quellen geprüft. Hier stehen alle Stellen, an denen der Text geändert wurde, sowie Aussagen ohne Beleg oder mit nur teilweiser Deckung. Diese Datei gehört nicht zum Buch und kann nach der Durchsicht gelöscht werden.

Nach dem Zusammenführen zusätzlich geändert: kap07, Tabelle "Fehlerart": Hinweis auf Delayed Retry ab RabbitMQ 4.3 ergänzt (Abgleich mit kap05). Offen: kap03 nennt `brew install nats-io/nats-tools/nats`, die natscli-README nennt `brew install nats` (nicht geprüft, welche Form aktuell ist). Ebenfalls ungeprüft: ob nats-py ab NATS 2.16 die neuen Ack-Subjects für `msg.metadata` (kap04) parsen kann (siehe Notizen Fork D).

---

# Abschnitt kap00-kap03

## Notizen Fork A (kap00, kap01, kap02, kap03), Stand 2026-10-01

44 Quellen in `lit-A.yml` (nur tatsächlich zitierte). Testkompilierung der vier Kapitel mit `ieee`-Stil ohne Fehler und ohne Warnungen; temporäre Testdateien sind gelöscht.

### (a) Inhaltliche Textänderungen

1. kap02-garantien.typ, Z. 5 (Einleitung)
   - vorher: "Die ehrliche Antwort ist bei jedem Broker dieselbe: Ohne Vorkehrungen *mindestens einmal oder gar nicht*. Wer das verstanden hat, baut Systeme, die mit beidem umgehen."
   - nachher: "... dieselbe: Ohne Bestätigungen *höchstens einmal*, mit Bestätigungen *mindestens einmal* @core-nats @jetstream @reliability, und genau einmal nie von allein. Wer das verstanden hat, baut Systeme, die mit Verlust und Duplikaten umgehen."
   - Grund: RabbitMQ-Reliability-Guide: "Use of acknowledgements guarantees at least once delivery. Without acknowledgements, message loss is possible ... and only at most once delivery is guaranteed." NATS: Core NATS ist at-most-once, JetStream at-least-once. "Mindestens einmal oder gar nicht" ist keine Aussage der Quellen und widersprach der Tabelle direkt darunter.
2. kap03-broker.typ, Z. 29 (Subjects)
   - vorher: "`>` für beliebig viele am Ende"
   - nachher: "`>` für ein oder mehrere am Ende"
   - Grund: NATS-Doku: "The `>` wildcard matches one or more tokens"; `bestellung.>` trifft `bestellung` selbst nicht.
3. kap03-broker.typ, Z. 31 (Pull-Consumer)
   - vorher: "das ist die empfohlene Form für Worker"
   - nachher: "das ist die gängige Form für Worker"
   - Grund: Die aktuelle NATS-Doku (docs.nats.io/learn/jetstream/pull-consumers) sagt nur "Most services use consume" bzw. beschreibt fetch/consume; eine ausdrückliche Empfehlung "pull für neue Projekte" steht in der aktuellen Doku nicht mehr (sie taucht nur in Suchergebnis-Zusammenfassungen älterer Doku-Versionen auf, die ich nicht abrufen konnte).
4. kap03-broker.typ, Z. 56 (Quorum Queues)
   - vorher: "_Quorum Queues_ sind repliziert, dauerhaft und seit RabbitMQ 4.0 der empfohlene Standard."
   - nachher: "... sind repliziert, dauerhaft und die Standardwahl, wenn eine replizierte, hochverfügbare Queue gebraucht wird @quorum-queues."
   - Grund: RabbitMQ-Doku: "the default choice when needing a replicated, highly available queue". Dass Quorum Queues in 4.0 "der empfohlene Standard" (etwa als Default-Queue-Typ) wurden, steht nicht in den Quellen; 4.0 hat nur das Mirroring entfernt. Der Folgesatz zur Entfernung der Spiegelung ist belegt.
5. kap03-broker.typ, Z. 57 (vhosts)
   - vorher: "trennen ... vollständig voneinander, samt Rechten"
   - nachher: "trennen ... logisch voneinander, samt Rechten"
   - Grund: RabbitMQ-Doku: "logical grouping and separation of resources"; physische Ressourcentrennung ist ausdrücklich kein primäres Ziel.
6. kap03-broker.typ, Z. 66 (Tabelle, Zeile "Deduplizierung beim Senden", RabbitMQ)
   - vorher: "nicht eingebaut, im Consumer lösen"
   - nachher: "nur bei Streams eingebaut, sonst im Consumer lösen"
   - Grund: RabbitMQ Streams haben eingebaute Producer-Deduplizierung (Producer Name + Publishing ID, "Streams and Superstreams"). Für Queues empfiehlt der Reliability-Guide idempotente Consumer statt Deduplizierung.

### (b) Unbelegte Aussagen (bewusst nicht belegt)

- kap00: Aufbau, Konventionen, Leitmotiv (eigene Gliederung und Buchempfehlungen); Satz "Direkte HTTP-Aufrufe ... bleiben alle stehen" ist nur indirekt durch den Messaging-Eintrag bei Hohpe/Woolf gedeckt (Zitat steht am Ende des Folgesatzes).
- kap01: "Der Preis: Das Ergebnis steht nicht sofort fest ..." und "Für Abfragen, auf deren Antwort ein Benutzer wartet, bleibt ein direkter API-Aufruf oft die bessere Wahl" (eigene Einschätzung).
- kap01: Zeilen "Name" und "Empfänger/Rechte" der Tabelle Befehl/Ereignis (Namenskonventionen: Imperativ/Vergangenheit sind eigene Empfehlung). Der Satz "Ein gefälschtes Ereignis `zahlung.eingegangen` kann eine Lieferung auslösen" ist Beispiel/Bedrohungsüberlegung.
- kap01: Beispiele der Spalte "Beispiel" in der Mustertabelle.
- kap02: Absatz "Giftige Nachrichten": Aussage "Eine Nachricht mit ungültiger Signatur wird durch zwanzig Wiederholungen nicht gültig" (eigenes Argument); Empfehlung "pro Schlüssel sequenziell verarbeiten" und "Ereignisse tragen Zeitstempel oder Versionsnummer" (eigenes Design). Abbildung Zustellstrecke (Bildunterschrift, nicht zitiert).
- kap03: Schlussabsatz "NATS spielt seine Stärken ... RabbitMQ bei komplexem Routing ..." (wertende Einschätzung); Abschnitt "Lokal ausprobieren" (compose.yaml, `brew install ...`, Ports) ist eigenes Beispiel.
- kap03: Zeile "Betrieb", "sehr ressourcenschonend" ist nur durch die Selbstbeschreibung des nats-server-Repos ("single binary / small footprint") gestützt, nicht durch einen Vergleich.

### (c) Quelle trägt nur teilweise

- kap02, "exactly-once ... über ein Netzwerk nicht allein durch den Broker erreichbar" (Tabelle) und "Was sich erreichen lässt, ist effektiv einmal": Die Broker-Dokus belegen den Mechanismus (NATS: "if the ack is lost ... the message is redelivered. The reader handled it once and will see it again"; RabbitMQ: nicht bestätigte Deliveries werden requeued) und die Empfehlung idempotenter Consumer (RabbitMQ Reliability Guide; NATS: "when ... you can't make the handler idempotent"). Eine ausdrückliche Aussage "exactly-once ist unmöglich" bzw. "effectively-once" habe ich in keiner abgerufenen Primärquelle gefunden. Kleppmann, "Designing Data-Intensive Applications" (Kap. 11/12) wäre die klassische Quelle, ich konnte den Wortlaut aber nicht prüfen und habe sie deshalb nicht zitiert. Die Tabellenzeile "exactly-once" ist daher bewusst ohne eigenes Zitat; der Absatz darunter trägt die Belege.
- kap01, "Lastspitzen werden gepuffert statt weitergereicht": Hohpe/Woolf (Messaging, Competing Consumers) und die NATS-JetStream-Seite stützen Entkopplung in Zeit und Raum. Der Begriff "Lastentkopplung/Puffern von Lastspitzen" fällt dort nicht wörtlich. Competing Consumers nennt nur das Problem "cannot process messages as fast as they're being added to the channel".
- kap01, Zeile "Stream (Log)": "Nachrichten werden dauerhaft in Reihenfolge gespeichert" ist für NATS (sequence numbers, Re-Read) und RabbitMQ Streams (append-only log, non-destructive) belegt. Die Formulierung "zurückspulen" ist sinngemäß (NATS: neuer Consumer startet bei Sequenz 1, Start ab Sequenz/Zeit möglich).
- kap02, "Reihenfolge ... solange genau ein Konsument liest und nichts wiederholt wird": RabbitMQ (FIFO, Reihenfolge pro Kanal, Störung durch mehrere Consumer und Redelivery) und NATS (Redelivery reiht sich nicht in die Stream-Reihenfolge ein; strikte Reihenfolge mit MaxAckPending=1) stützen das. Dass "beide Broker" die Reihenfolge innerhalb eines Streams/einer Queue einhalten, ist für RabbitMQ nur für das Veröffentlichen auf einem einzigen Kanal belegt.
- kap02, "würde ohne Begrenzung endlos erneut zugestellt": Belegt für JetStream (MaxDeliver Standard -1 = unbegrenzt) und für RabbitMQ vor 4.0 (Blog: "from previous behavior where delivery attempts were unlimited"). Die Aussage "und andere Nachrichten blockieren" steht nicht wörtlich dort (RabbitMQ-Doku: wiederholte Requeues "can threaten the stability of a queue or RabbitMQ cluster").
- kap02, Tabelle "Verzögerte Wiederholung": Nur für JetStream (`nak` mit Delay) belegt; für RabbitMQ als Allgemeinaussage nicht eigens belegt (kap05 behandelt die TTL-Warteschlange).
- kap02/kap03, "Dead Letters ... über Advisories": NATS-Doku bestätigt "There's no dead-letter queue" und das `max_deliver`-Advisory als einziges eingebautes Signal; "oder in der Anwendung" ist die übliche Konsequenz, steht aber nicht wörtlich dort.
- kap03, "Pika (synchron)": Belegt durch die aio-pika-Dokumentation ("traditional pika is the synchronous RabbitMQ client"); die RabbitMQ-Clientliste nennt pika nur "a pure-Python AMQP 0-9-1 client".
- kap03, "Rechte: configure/write/read pro Ressource, Topic-Rechte": configure/write/read pro vhost per Regex ist belegt. Die Access-Control-Doku beschreibt Topic-Autorisierung als zusätzliche Prüfung der Routing Keys bei Topic Exchanges; die Seite führt dazu MQTT und STOMP als Beispiel an, die Aussage für AMQP 0-9-1 habe ich daraus nicht wörtlich verifiziert.
- kap03, "Standard-Maximalgröße 16 MiB (seit 4.0)": Release Notes 4.0.1: "Default maximum message size is reduced to 16 MiB (from 128 MiB)". Die aktuelle Konfigurationsseite (4.3) nennt 16777216 als Default, bestätigt aber das "seit 4.0" nicht.
- kap03, "NATS: Rechte Publish/Subscribe pro Subject": belegt; die Hinweise auf Wildcards in Rechten stehen in kap09 (Fork C).

### (d) Sonstige Beobachtungen

- Die NATS-Dokumentation wurde 2026 umgebaut (Docusaurus, Bereiche `concepts/`, `learn/`, `reference/`). Alte Pfade wie `/nats-concepts/jetstream` leiten um. Ich habe deshalb die endgültigen URLs als Schlüsselbasis verwendet (z.B. `docs.nats.io/learn/jetstream/retention-policies` -> `docs-nats-io-learn-jetstream-retention-policies`). Fork B/C sollten für dieselben Seiten identische Schlüssel nutzen, sonst gibt es Duplikate in der Merge-Phase. Falls Fork B/C die alten Pfade als Schlüssel gewählt haben, sind die Einträge inhaltlich dieselben Seiten.
- Die neue NATS-Doku enthält keine Aussage mehr "Pull consumers are recommended for new projects" (siehe Änderung 3). Kap04 (Fork B) behauptet "Der offizielle Python-Client heißt nats-py" und "empfohlene Form" für Pull-Consumer: bitte gegenprüfen. Das Repo nats-io/nats.py bezeichnet sich als "asyncio Python client for NATS".
- `www.rabbitmq.com` blockiert curl (Cloudflare-Challenge), alle RabbitMQ-Seiten habe ich über WebFetch gelesen. Die Seitentitel in `lit-A.yml` stammen aus HTML-`<title>`/H1 (ohne den Suffix "| RabbitMQ").
- EIP-Seiten: Als Autor nennt jede Musterseite "Bobby Woolf" (Copyright 2003, 2023). Ich habe sie als Web-Einträge mit Autor Woolf aufgenommen und zusätzlich das Buch `hohpe-2003-eip` (Hohpe/Woolf, Addison-Wesley, 2003, ISBN 0321200683, Angaben von der Buch-Website) einmal in kap00 zitiert. Die Seite nennt als Titel "Enterprise Integration Patterns: Designing, Building, and Deploying Messaging Solutions".
- Keine Datumsangaben bei NATS-/RabbitMQ-Seiten (Seiten tragen kein Veröffentlichungsdatum); nur der Blogpost (2024-08-28, Michał Kuratczyk) hat eines.
- Bei den Release Notes ist `4.0.1` die erste für die 4.0-Serie auffindbare Notiz im Branch `v4.0.x`; sie beginnt mit "RabbitMQ `4.0` is a new major release" und enthält die Highlights (Mirroring entfernt, Delivery-Limit 20, 16 MiB, AMQP 1.0 Kernprotokoll).
- Typst: Zitate in Tabellenzellen und Aufzählungen kompilieren ohne Probleme. Zitate vor dem Satzpunkt (`... @key.`) werden korrekt als Label ohne Punkt erkannt.

---

# Abschnitt kap04-kap05

## Notizen Fork B (kap04-nats.typ, kap05-rabbitmq.typ), Stand 2026-10-01

29 Quellen (`lit-B.yml`), alle abgerufen (WebFetch/WebSearch) und gegen die Aussage geprüft; Testkompilierung beider Kapitel mit `ieee`-Stil ohne Fehler/Warnungen, alle zitierten Schlüssel stehen im YAML und umgekehrt. Zusätzlich wurden die Python-APIs der Beispiele gegen die Pakete nats-py 2.16.0 und aio-pika 10.1.0 (PyPI-Download) sowie die natscli-Quellen geprüft.

### (a) Inhaltliche Textänderungen

1. kap05, Consumer-Code (Z. 90) und Tabelle (Z. 102)
   - vorher: `await msg.nack(requeue=True)  # erneut zustellen, zählt zum Limit`; Tabelle: "`msg.nack(requeue=True)`: zurück in die Queue, erneute Zustellung (zählt bei Quorum Queues zur `x-delivery-limit`)"
   - nachher: `await msg.reject(requeue=True)  # erneut zustellen, zählt zum Limit`; Tabelle: "`msg.reject(requeue=True)`: ... (zählt bei Quorum Queues zur `x-delivery-limit`, ein `nack` mit Requeue zählt ab RabbitMQ 4.3 nicht mehr dazu)"
   - Grund: RabbitMQ-Doku (Quorum Queues, "When is delivery count incremented?"): `basic.nack` erhöht `delivery-count` nicht, `basic.reject` schon; seit 4.3 basiert das Limit auf `delivery-count` statt `acquired-count`, "unlimited explicit returns (via nack ...) are allowed without counting towards the delivery limit". Mit `nack(requeue=True)` hätte ein dauerhaft scheiternder Job ab 4.3 endlos kreisen können. `reject(requeue=True)` zählt in allen 4.x-Versionen.
2. kap05, Tipp zu Wiederholungen (Z. 109)
   - vorher: "Anders als JetStream kennt RabbitMQ kein `nak` mit Verzögerung. Für wachsende Abstände ... legt man eine Warteschlange mit Ablaufzeit (`x-message-ttl`) an ..."
   - nachher: "... kennt RabbitMQ erst ab Version 4.3 eine Verzögerung für zurückgegebene Nachrichten: Quorum Queues halten sie dann auf Wunsch mit linear wachsendem Abstand zurück (_Delayed Retry_ über `x-delayed-retry-type`, `x-delayed-retry-min` und `x-delayed-retry-max`). Für ältere Versionen legt man eine Warteschlange mit Ablaufzeit ... an ..."
   - Grund: Quorum-Queues-Doku, Abschnitt "Delayed Retry": "available as of RabbitMQ 4.3", Backoff `delay = min(min_delay * delivery_count, max_delay)` (linear), Queue-Argumente wie genannt.
3. kap05, Prefetch-Absatz (Z. 107)
   - vorher: "Ohne `prefetch_count` schiebt RabbitMQ einem Consumer beliebig viele Nachrichten zu, die dann im Speicher des Consumers liegen und für andere Instanzen blockiert sind. Ein Wert zwischen 10 und 100 ist ein guter Start."
   - nachher: "Ohne `prefetch_count` (der Wert 0 heißt unbegrenzt) schiebt RabbitMQ ... zu (bei Quorum Queues höchstens 2000), die dann im Speicher ... Für den Durchsatz nennt die RabbitMQ-Dokumentation Werte zwischen 100 und 300 als meist optimal. Bei langer Verarbeitungszeit pro Nachricht ist ein kleinerer Wert wie 10 besser, damit sich die Arbeit auf mehrere Instanzen verteilt."
   - Grund: Doku "Consumer Acknowledgements and Publisher Confirms": "Values in the 100 through 300 range usually offer optimal throughput", Quorum Queues begrenzen unbegrenzten Prefetch auf 2000. Der Satz zu kleinen Werten ist Buchempfehlung (Begründung unbelegt, s. b).
4. kap05, Topologie (Z. 9)
   - vorher: "(`load_definitions` in `rabbitmq.conf`)"
   - nachher: "(`definitions.import_backend` und `definitions.local.path` in `rabbitmq.conf`)"
   - Grund: Die aktuelle Definitions-Doku nennt nur `definitions.import_backend = local_filesystem` und `definitions.local.path`; `load_definitions` kommt nicht mehr vor.
5. kap05, Tabelle `reject(requeue=False)` (Z. 103)
   - vorher: "wird an den Dead-Letter-Exchange weitergeleitet"
   - nachher: "... weitergeleitet (falls konfiguriert, sonst verworfen)"
   - Grund: Confirms-Doku: "routed to a Dead Letter Exchange if it is configured, otherwise it will be discarded."
6. kap04, Drain (Z. 113)
   - vorher: "Am Ende sorgt `drain()` dafür, dass bereits abgeholte Nachrichten noch bearbeitet und bestätigt werden, bevor die Verbindung schließt."
   - nachher: "Am Ende beendet `drain()` die Verbindung geordnet: Es lässt bereits empfangene Nachrichten fertig verarbeiten und sendet ausstehende Veröffentlichungen ab, bevor die Verbindung schließt. Bestätigen muss der Worker selbst, `drain()` bestätigt keine Nachrichten."
   - Grund: NATS-Doku "Drain & Shutdown": "It does not acknowledge a JetStream consumer's messages for you." Im Beispielcode steht `drain()` nach der Schleife, jede Nachricht ist dort bereits bestätigt, der Code bleibt korrekt.
7. kap04, Producer-Absatz (Z. 62)
   - vorher: "... erst dann ist die Nachricht dauerhaft gespeichert."
   - nachher: "... erst dann hat der Stream die Nachricht gespeichert." plus neuer Satz: "Eine bestätigte Nachricht ist allerdings nicht zwingend schon auf der Platte: Der Server ruft `fsync` standardmäßig nur alle zwei Minuten auf und bestätigt sofort, nach einem Absturz des Betriebssystems können kürzlich bestätigte Nachrichten fehlen."
   - Grund: Jepsen-Analyse NATS 2.12.1: "NATS calls fsync to flush data to disk only once every two minutes, but acknowledges messages immediately." Die NATS-Publishing-Doku verspricht nur "stored", nicht "dauerhaft". Hinweis: Die Jepsen-Analyse betrifft 2.12.1; ob spätere 2.x-Versionen den Default geändert haben, habe ich nicht geprüft (kein Beleg gefunden, die Seite sagt, NATS habe Doku ergänzt).

Einfügungen ohne Änderung der Aussage (zur Transparenz):
- kap04 Z. 30: neuer Satz "Die Optionen entsprechen den Flags des `nats`-Werkzeugs" (nur als Träger der natscli-Zitate; Flags und Hilfetexte aus `stream_command.go`/`consumer_command.go` geprüft, `30d` wird von `fisk.ParseDuration` unterstützt).
- kap04 Z. 113: Halbsatz zu leerem `fetch` ("Ein leerer Abruf ist kein Fehler ... `TimeoutError`"), erklärt das `except NatsTimeout: continue` im Beispiel.
- kap05 Z. 66: Klammer "(eine frei wählbare Nachrichteneigenschaft ...)" als Träger des Publishers-Zitats.

### (b) Unbelegte Aussagen (bewusst)

- kap04 Z. 9: Streams/Consumer gehören in die Einrichtung, nicht in den Dienst-Startcode; Rechte (Kapitel 9). Eigene Empfehlung.
- kap04: Beispielcode, Namen (`BESTELLUNGEN`, `provisionierung`, `dlq.provisionierung`), `max_reconnect_attempts=-1` (Parameter existiert, Wirkung nicht zitiert), Backoff `min(2 ** versuch, 300)`.
- kap04 Z. 117: "Der erste Weg ist einfacher und deckt beide Fälle ab, wenn der Worker bei `num_delivered == max_deliver` selbst aussortiert." Eigene Bewertung.
- kap04 Z. 62: Hinweis, `ack.duplicate` im Beispiel auszuwerten: Feld ist belegt (Publishing-Doku), der Umgang damit ist Beispielcode.
- kap05 Z. 5, 9: "zwei verbreitete Python-Clients", "Exchanges, Queues und Bindings gehören nicht in den Startcode" (Empfehlung).
- kap05 Z. 66: "RabbitMQ dedupliziert nicht selbst" (kein belastbarer Primärbeleg gefunden; die Publishers-Doku nennt `message_id` nur als frei wählbare Eigenschaft).
- kap05 Z. 107: "für andere Instanzen blockiert" und die Empfehlung, bei langer Verarbeitung einen kleineren Wert wie 10 zu wählen, sind Schlussfolgerung bzw. Buchempfehlung.
- kap05 Code-Kommentare (`delivery_mode=PERSISTENT # auf Platte speichern`, `x-delivery-limit: 5`, `get_exchange(..., ensure=False)`) tragen keine Zitate (Regel 3). API-Existenz und Defaults sind gegen aio-pika 10.1.0 geprüft (`publisher_confirms=True` Standard, `on_return_raises`, `mandatory=True` Standard, `get_exchange/get_queue(ensure=...)`, `reject(requeue=...)`, `set_qos(prefetch_count=...)`, `connect_robust(client_properties=...)`).

### (c) Quelle trägt nur teilweise

- kap04 Z. 4, "offizieller Python-Client": nats.io/download markiert Python Asyncio als von "NATS Authors" gepflegt (nats-io-Organisation); das Wort "offiziell" steht dort nicht wörtlich.
- kap04 Tabelle, `--replicas`: "1 bei einem Server, 3 im Cluster": Doku nennt R=3 als üblichen Produktionswert und lehnt R>1 auf Einzelknoten ab; "3 im Cluster" ist als Empfehlung zu lesen, nicht als Pflicht (R=5 ist möglich).
- kap04 Tabelle, `msg.nak(delay)`, "zählt als Zustellversuch": Doku sagt, MaxDeliver begrenzt, wie oft der Server zustellt; dass jede Nak-Wiederholung dazuzählt, ist daraus abgeleitet (und plausibel, weil `num_delivered` Zustellungen zählt).
- kap04 Z. 115, "JetStream hat keinen eingebauten Dead-Letter-Speicher": Synadia-Blog sagt "NATS does not ship a single-config dead-letter queue"; die Advisory-Doku bestätigt nur das Ereignis, keinen Speicher.
- kap04 Z. 113, `TimeoutError` bei leerem `fetch`: Doku nennt `FetchTimeoutError`; dass dieser von `nats.errors.TimeoutError` erbt (Beispielcode fängt diesen), ist am Paketcode von nats-py 2.16.0 geprüft, nicht an der Online-Doku.
- kap05 Z. 64, Publisher Confirms "Bleibt sie aus, gibt es eine Ausnahme": aio-pika wirft `DeliveryError` bei Nack/Reject des Brokers, bei Zeitüberschreitung (`timeout=5`) einen Timeout-Fehler; beides im Paketcode bzw. API-Docstring geprüft, die RabbitMQ-Doku selbst beschreibt nur Confirms/Nacks.
- kap05 Z. 5, `pika` "synchron": Pika-Doku nennt "pure-Python implementation of the AMQP 0-9-1 protocol" mit verschiedenen Connection-Adaptern, nicht ausdrücklich "synchron" (gemeint ist `BlockingConnection`).
- kap05 Z. 35/9, Fluss "nach fünf gescheiterten Zustellungen": Die Doku sagt, die Nachricht wird verworfen/dead-lettered, wenn sie "more times than the limit" erneut zugestellt wurde; der Kommentar "nach 5 Zustellungen aussortieren" ist also bis auf eine Zustellung genau.
- kap05 Tabelle `ack`, "RabbitMQ löscht die Nachricht aus der Queue": Confirms-Doku beschreibt positive Bestätigung, nicht ausdrücklich das Löschen.

### (d) Sonstige Beobachtungen

- RabbitMQ-Website und docs.nats.io: WebFetch liefert nur Zusammenfassungen eines kleinen Modells. Alle kritischen Stellen (Delivery-Count, Delayed Retry, Prefetch-Zahlen, Definitions-Keys) habe ich zusätzlich im Markdown-Quelltext des RabbitMQ-Website-Repos (raw.githubusercontent.com) bzw. in den PyPI-Paketen gegengeprüft. Die Seiten selbst sind per curl durch Cloudflare gesperrt, das habe ich nicht umgangen. Zitiert ist die Website-URL.
- Die NATS-Doku wurde offenbar neu strukturiert (`/learn/jetstream/...`); ältere Pfade wie `/nats-concepts/jetstream/consumers` liefern Seiten mit anderem Inhalt. Verwendet sind nur Seiten, deren Inhalt ich abgerufen habe. `nats-concepts/jetstream/streams` und `nats-concepts/jetstream` lieferten sehr knappe Abrufe, sie belegen nur die jeweils zitierte Aussage (Duplicate Window 2 Minuten bzw. Core NATS at-most-once).
- GitHub-Blob-URLs für nats.py (`nats/aio/msg.py`, `nats/js/errors.py`) lieferten 404 (Repo-Layout geändert), deshalb ist die nats.py-API über `nats-io.github.io/nats.py/modules.html` belegt.
- Auffälligkeit außerhalb meiner Kapitel: kap07 (Fehlerarten-Tabelle, Zeile "vorübergehend") nennt für RabbitMQ nur "Warteschlange mit TTL"; dort ließe sich die Delayed-Retry-Funktion ab RabbitMQ 4.3 ergänzen. kap03 (Tabelle "Grenze wiederholter Zustellung") und kap02 (Dead Letters) erwähnen die 20er-Grenze, nicht aber, dass `nack` ab 4.3 nicht mehr zählt; falls dort `nack` als Zähler genannt wird, anpassen. Außerdem nennt kap03 den Brew-Befehl `nats-io/nats-tools/nats`, die natscli-README nennt `brew install nats` (nicht geprüft, ob der Tap noch funktioniert).
- kap03 (Fork A) behauptet "Quorum Queues ... repliziert, seit 4.0 empfohlen": passt zu Quorum-Doku ("the default choice when needing a replicated, highly available queue"), nicht von mir geprüft.
- Typst: Für Hayagriva-Einträge ohne bekanntes Datum habe ich kein `date` gesetzt; der IEEE-Stil rendert dann ohne Jahr, nur mit Abrufdatum. Autor bei RabbitMQ/NATS-Seiten ist die Organisation (`name:`), so erscheint "NATS Authors" bzw. "RabbitMQ".
- Titel mancher Seiten (z.B. "Download", "max deliver", "Time-To-Live and Expiration", "Definition Export and Import") stammen aus Suchergebnissen bzw. Kenntnis der Seitenüberschrift, nicht aus dem `<title>`-Tag; bei der Merge-Phase ggf. prüfen.
- Temporäre Testdateien `_tmp-B.typ`/`_tmp-lit-B.yml` sind gelöscht. `_tmp-A.typ`/`_tmp-lit-A.yml` im Projektordner gehören zu Fork A.

---

# Abschnitt kap06-kap07

## Notizen Fork C (kap06, kap07), Stand 2026-10-01

20 Quellen (`lit-C.yml`), alle abgerufen und gegen die Aussage geprüft; Testkompilierung beider Kapitel mit `ieee`-Stil ohne Fehler und Warnungen. Bei Webquellen ohne ersichtliches Jahr wurde kein `date` angegeben (Autoren von Personen als Klartext-Strings, damit IEEE "G. Hohpe and B. Woolf" rendert; `name:` nur für Organisationen verwenden).

### (a) Inhaltliche Textänderungen

1. kap06-nachrichten.typ, Abschnitt "Ein einheitlicher Umschlag" (Z. 9)
   - vorher: "Das Format orientiert sich an der Spezifikation _CloudEvents_, die genau diese Felder standardisiert:"
   - nachher: "... _CloudEvents_ @cloudevents: `id`, `source`, `type`, `time` und `data` stammen von dort (das Pflichtattribut `specversion` ist der Kürze halber weggelassen). `version` und `korrelation_id` sind eigene Ergänzungen. `korrelation_id` wäre als CloudEvents-Erweiterung so nicht zulässig, denn Attributnamen bestehen dort nur aus Kleinbuchstaben und Ziffern @cloudevents:"
   - Grund: CloudEvents definiert `version` und eine Korrelations-ID nicht ("No correlation attribute in core spec"), `specversion` ist REQUIRED, und Attributnamen MÜSSEN aus [a-z0-9] bestehen (SOLLEN max. 20 Zeichen haben). Die Aussage "genau diese Felder" stimmte also nicht.
2. kap06-nachrichten.typ, Abschnitt "Mit Pydantic prüfen" (Z. 71): zusätzlicher Satz vor dem bestehenden Text
   - neu eingefügt: "Die Modelle weisen unbekannte Felder ab (`extra="forbid"` löst einen `ValidationError` aus) und sind unveränderlich (`frozen=True`) @pydantic-config. Wertebereiche, Muster und Längen prüft `Field` @pydantic-fields."
   - Grund: Dokumentiert das Verhalten des Beispielcodes und liefert die Beleggrundlage (reine Ergänzung, keine Aussage des Originals geändert).
3. kap06-nachrichten.typ, Abschnitt "Was nicht in Nachrichten gehört" (Z. 90)
   - vorher: "Das vereinfacht auch Löschpflichten erheblich: Ein Kunde wird an einer Stelle gelöscht, nicht in wochenlang aufbewahrten Streams."
   - nachher: "Das vereinfacht auch die Umsetzung von Löschpflichten @gdpr17: Name und E-Mail-Adresse werden an einer Stelle gelöscht, nicht in wochenlang aufbewahrten Streams."
   - Grund: Die `kunde_id` bleibt in den Streams und ist selbst ein personenbezogenes Datum (Pseudonym); "ein Kunde wird an einer Stelle gelöscht" war daher überzogen. Art. 17 DSGVO belegt nur das Bestehen der Löschpflicht.
4. kap07-zuverlaessigkeit.typ, Abschnitt "Das Problem der zwei Schreibvorgänge" (Z. 9)
   - vorher: "Eine gemeinsame Transaktion über Datenbank und Broker gibt es nicht."
   - nachher: "Eine gemeinsame, verteilte Transaktion über Datenbank und Broker ist in der Praxis keine Option @outbox."
   - Grund: microservices.io: "not viable to use a traditional distributed transaction (2PC)"; "2PC is not an option. The database and/or the message broker might not support 2PC." Absolutes "gibt es nicht" ist nicht belegt.
5. kap07-zuverlaessigkeit.typ, "Idempotente Consumer" (Z. 68)
   - vorher: "Kommt die Nachricht ein zweites Mal, scheitert das `INSERT` am Primärschlüssel, die Funktion kehrt ohne Wirkung zurück ..."
   - nachher: "... fügt das `INSERT` wegen `ON CONFLICT DO NOTHING` keine Zeile ein und liefert deshalb nichts zurück @pg-insert, die Funktion kehrt ohne Wirkung zurück ..."
   - Grund: Mit `ON CONFLICT DO NOTHING` wirft das Statement keinen Fehler, es überspringt die Zeile; `RETURNING` liefert nur tatsächlich eingefügte Zeilen. "scheitert" passte nicht zum gezeigten Code (der Zweig `if neu is None` setzt genau das voraus).
6. kap07-zuverlaessigkeit.typ, Abschnitt Outbox (Z. 48): eingefügter Satz "Dass der Relay eine Nachricht mehrfach veröffentlichen kann, nennt auch die Musterbeschreibung @outbox." (reine Ergänzung als Beleg für das beschriebene Absturzszenario).

Alle übrigen Änderungen sind reine `@key`-Einfügungen. Beispielcode wurde nicht verändert.

### (b) Unbelegte Aussagen (bewusst)

- kap06 Z. 5: "Eine Nachricht ist ein Vertrag zwischen Diensten ..." (Einordnung/Metapher).
- kap06 Tabelle Umschlag: Zeilen `type`/`version`, `source` ("wird bei signierten Nachrichten geprüft", eigenes Design), `korrelation_id`, `data` sowie "Grundlage für Replay-Schutz und Reihenfolge" bei `time` (eigenes Design). `version` als Schema-Version ist Eigenentwurf (CloudEvents hätte dafür `dataschema`).
- kap06 Schema-Tabelle: Zeile "Feld umbenennen/entfernen" (Vorgehen "beide Versionen senden") und "neues Ereignis" sind Empfehlungen des Buchs; "neue Felder mit neuer `version` einführen" ist eigene Regel, bewusst strenger als Confluent (dort wäre ein optionales Feld mit Default rückwärtskompatibel).
- kap06 Z. 88: "Nachrichten werden kopiert, gespeichert, ..., in Logs geschrieben" (Allgemeinaussage/Einschätzung).
- kap06 Z. 91: "Keine Geheimnisse, keine Zugangsdaten, keine Tokens" (Empfehlung); "Dateien gehören in einen Objektspeicher" (Empfehlung, nur das Muster Claim Check ist belegt); "große Nachrichten bremsen alle anderen aus" (Einschätzung).
- kap07 Z. 48: "Bei RabbitMQ wird dieselbe ID als `message_id` gesetzt und erst der Consumer erkennt das Duplikat." Dass RabbitMQ nicht selbst dedupliziert, habe ich in der RabbitMQ-Doku nicht ausdrücklich gefunden (amqp-concepts sagt nur, die meisten Nachrichtenattribute seien für den Broker opak). Gehört inhaltlich zu Kap. 5 (Fork B); beim Zusammenführen dessen Beleg übernehmen, falls vorhanden.
- kap07 Z. 68: Bereinigung der Tabelle `verarbeitet` "älter als die längste mögliche Wiederholungszeit" (Empfehlung).
- kap07 Z. 78 ("unklar (Programmfehler)"), Z. 81 ("Dead Letters sind kein Mülleimer, sondern eine Arbeitsliste", Überwachung der DLQ-Länge, Wiedereinspielen mit derselben ID) sind Empfehlungen/Eigenentwurf.
- kap07 Z. 9: Reihenfolge-Argument "erst senden, dann speichern" ist Herleitung (die Problemstellung selbst ist durch microservices.io gedeckt).

### (c) Quelle trägt nur teilweise

- kap06 Tabelle, Zeile `id`: "eindeutig pro Nachricht": CloudEvents verlangt nur Eindeutigkeit von `source` + `id`. Im Buch ist die ID eine UUID und damit global eindeutig, aber die Spezifikation fordert weniger. Zitiert wurde nur `Nats-Msg-Id` (docs.nats.io headers: "Unique message ID for deduplication. Messages with the same ID within the deduplication window will be rejected as duplicates").
- kap06 Tabelle, Zeile `time`: CloudEvents `time`: "Timestamp of when the occurrence happened. If the time of the occurrence cannot be determined then this attribute MAY be set to some other time." Das Buch sagt "Zeitpunkt des Ereignisses, nicht des Versands", stimmt im Normalfall; die Ausnahme steht in der Spezifikation.
- kap06 Beispielnachricht: `type: "bestellung.eingegangen"` weicht von der CloudEvents-Empfehlung ab (reverse-DNS-Präfix, "SHOULD"); `source: "shop"` ist als URI-Reference zulässig, empfohlen wäre eine absolute URI.
- kap06 "Consumer werden vor Producern aktualisiert": Confluent nennt das als Regel für BACKWARD-Kompatibilität ("upgrade all consumers before you start producing new events"); für FORWARD gilt die umgekehrte Reihenfolge. Die Buchregel entspricht dem BACKWARD-Fall, was durch "Ein Consumer, der Version 2 und 3 versteht" gedeckt ist, aber nicht allgemein gilt.
- kap07 `FOR UPDATE SKIP LOCKED`: PostgreSQL-Doku: "can be used to avoid lock contention with multiple consumers accessing a queue-like table", aber auch "Skipping locked rows provides an inconsistent view of the data, so this is not suitable for general purpose work". Für Outbox-Relays passt es (queue-like Tabelle); der Hinweis fehlt im Buch.
- kap07 "erkennt JetStream das Duplikat innerhalb des Zeitfensters": belegt durch docs.nats.io Streams ("For two minutes after a message is stored, the server turns away a second message that carries the same Nats-Msg-Id header"; 2 Minuten ist der Standard-Zeitraum). Die Aussage "Standard 2 Minuten" steht dort, nicht aber ein Beleg zur Konfigurierbarkeit (die Stream-Seite nennt das Fenster als Einstellung).
- kap07 Tabelle: NATS `nak(delay)`: docs.nats.io Acknowledgment belegt nak mit Verzögerung, `term` ("The message leaves the pending list and the server never delivers it again"). Das "eigene Dead-Letter-Subject" ist Buchentwurf (JetStream hat laut Kap. 4 keinen eingebauten DLQ), die RabbitMQ-Aussage zu TTL-Wartequeue stützt `ttl` nur für die Einzelteile (message-ttl pro Queue, Dead-Lettering abgelaufener Nachrichten, wenn DLX gesetzt); das Muster "Wartequeue mit Rückkehr in die Arbeitsqueue" ist Eigenentwurf aus Kap. 5.
- kap07 EIP Idempotent Receiver: belegt "designed to safely receive the same message multiple times" und die zwei Wege (Filtern oder idempotente Semantik). Das konkrete Beispiel "Setze Status auf aktiv" vs. "erhöhe Zähler" ist nicht Teil der EIP-Seite.
- kap07 Dead Letter Channel (EIP): zitiert für das Aussortieren nicht zustellbarer/unverarbeitbarer Nachrichten in einen eigenen Kanal ("it may elect to move the message to a Dead Letter Channel"); die Unterscheidung vorübergehend/dauerhaft steht dort nicht.

### (d) Sonstige Beobachtungen

- Beispielcode in kap07 geprüft gegen psycopg-3-Doku: `async with pool.connection() as db, db.transaction():` ist gültig (Pool-Kontext committet beim Verlassen, `transaction()` ist ein async Context Manager), `AsyncConnection.execute()` gibt einen Cursor zurück, daher funktioniert `await (await db.execute(...)).fetchone()/.fetchall()`. Nicht ausdrücklich zitiert (Codeblock), Quellen wären `psycopg.org/psycopg3/docs/advanced/pool.html`, `.../basic/transactions.html`, `.../api/connections.html`.
- kap07 `outbox.py`: `js.publish(typ, daten, ...)` setzt voraus, dass `daten` Bytes sind. Liegt die Spalte `daten` als `jsonb`, liefert psycopg ein dict; für das Beispiel bräuchte es `json.dumps(...).encode()` oder eine `bytea`/`text`-Spalte. Nicht geändert (Beispielcode, Typ der Spalte offen).
- kap07 Outbox: Der Relay hält die Zeilensperren (`FOR UPDATE`) während des Veröffentlichens (`timeout=5` je Nachricht, bis 100 Zeilen). Das ist korrekt, begrenzt aber den Durchsatz und hält die Transaktion bis zu 100 x 5 s offen. Reiner Hinweis.
- JetStream-Dedup-Fenster (Standard 2 Minuten): Dauert der Neustart eines abgestürzten Relays länger, erkennt JetStream das Duplikat nicht mehr; der idempotente Consumer fängt das ab. Das Buch erwähnt das indirekt ("innerhalb des Zeitfensters").
- Pydantic-Doku liegt inzwischen unter `pydantic.dev/docs/validation/latest/...` (`docs.pydantic.dev` leitet per 301 dorthin); die Schlüssel folgen der neuen URL. Alle im Beispiel verwendeten Parameter (`extra`, `frozen`, `ge`, `le`, `pattern`, `min_length`, `max_length`, `model_validate_json`, `model_json_schema`) existieren wie im Code. `ge`/`le` gelten nur für Zahlen, `pattern` nur für Strings, `min_length`/`max_length` für Strings und Listen; so verwendet der Code sie.
- Die CloudEvents-Spezifikation lag beim Abruf als `1.0.3-wip` (main-Branch) vor; die Seite wurde als GitHub-Link zitiert.
- NATS-Dokumentation ist umgezogen/umstrukturiert: `docs.nats.io/jetstream/concepts/streams`, `/learn/jetstream/acknowledgment` und `/reference/jetstream/api/headers` waren abrufbar; ältere Pfade (`/nats-concepts/jetstream/...`) kamen nicht mehr mit dem erwarteten Inhalt. Fork A/B sollten dieselben Schlüssel verwenden, damit beim Zusammenführen Duplikate erkannt werden.
- Die Einträge `www-enterpriseintegrationpatterns-com-...` haben kein Datum, weil die Seiten keine Jahresangabe zeigten (das Buch erschien 2003, aber das war nicht Gegenstand der Prüfung; die Webseite wird als Online-Quelle zitiert).
- Querverweise auf andere Handbücher und Kapitel (Kap. 2, 3, 10, 11) wurden nicht belegt.

---

# Abschnitt kap08-kap11

## Notizen Fork D (kap08, kap09, kap10, kap11), Stand 2026-10-01

40 Quellen (`lit-D.yml`), alle abgerufen und gegen die Aussage geprüft. Testkompilierung der vier Kapitel mit `ieee`-Stil ohne Fehler und ohne Warnungen. Die Temp-Dateien im Projektverzeichnis sind gelöscht. Die zwei Quellen RFC 8032 und RFC 5116 liegen als `rfcNNNN`-Einträge vor, die NIST-Norm als `nist-sp-800-38d`.

### (a) Inhaltliche Textänderungen

1. kap08-transport.typ, Python-Beispiel (`gemeinsam/tls.py`, Zeile ~74)
   - vorher: `# NATS` über `nats.connect(..., user_credentials="/run/secrets/shop.creds")`
   - nachher: `# NATS (.creds nur bei JWT-Authentifizierung, sonst user= und password=)`
   - Grund: Eine `.creds`-Datei enthält laut NATS-Doku das User-JWT (erster Block) plus Seed (zweiter Block) und passt nur zur dezentralen JWT-Authentifizierung. Kap. 9 verwendet für denselben Dienst `user="shop", password=...`. Nur der Kommentar wurde ergänzt, der Code blieb unverändert.

2. kap09-rechte.typ, `nats-server.conf (Accounts)`, Nutzer `provisionierung` (Zeile ~43) und Absatz davor
   - vorher: nur `"$JS.ACK.BESTELLUNGEN.provisionierung.>"`
   - nachher: zusätzlich `"$JS.ACK.*.*.BESTELLUNGEN.provisionierung.>"  # dasselbe im neuen Format`, dazu zwei Sätze im Absatz davor: "Die Bestätigungen laufen über Antwort-Subjects mit dem Präfix `$JS.ACK`, die neuere Serverversionen um Domain und Account-Hash erweitern @adr15. Deshalb erlaubt die Konfiguration beide Formen."
   - Grund: ADR-15 beschreibt zwei Formate des Ack-Reply-Subjects: v1 `$JS.ACK.<stream>.<consumer>.<5 Felder>` und v2 `$JS.ACK.<domain>.<account hash>.<stream>.<consumer>.<5 Felder>`. Im nats-server-Quelltext (`server/feature_flags.go`, main, Version 2.16.0-dev) ist `js_ack_fc_v2` auf `true` gesetzt ("Introduced: 2.14.0 ... only using v1; Enabled: 2.16.0"). Die jüngste Release (2.15.0, GitHub, 2026-10-01) verwendet noch v1. Mit der alten Regel allein würde `msg.ack()` ab 2.16 mit `Permissions Violation` scheitern, und die Nachrichten würden nach `ack_wait` endlos neu zugestellt. Die Quelltext-Aussage zu 2.16 steht nur im Quellcode, nicht in der Doku, und wird deshalb im Text nicht mit Versionsnummer behauptet.

3. kap09-rechte.typ, Tabelle der RabbitMQ-Rechte, Zeile `read`
   - vorher: "aus Queues lesen, bestätigen, Bindings (auf Seiten des Exchanges)"
   - nachher: "aus Queues lesen, Queues leeren, Bindings (auf Seiten des Exchanges)"
   - Grund: Die Berechtigungstabelle der Access-Control-Doku (AMQP 0-9-1) nennt für `read`: `basic.get`, `basic.consume`, `queue.purge`, Bindings (Exchange-Seite). Eine Bestätigung (`basic.ack`) steht dort nicht, sie erfordert kein eigenes Recht.

4. kap10-signatur.typ, Abschnitt "Inhalte verschlüsseln", nach dem Satz zur Schlüsselvergabe (Ergänzung)
   - neu: "Bei zufällig gewählten 96-Bit-Nonces darf ein Schlüssel für höchstens 2^32 Verschlüsselungen verwendet werden @nist-sp-800-38d."
   - Grund: NIST SP 800-38D, Abschn. 8.3: Bei der RBG-basierten IV-Konstruktion darf die Gesamtzahl der Aufrufe der Verschlüsselungsfunktion mit demselben Schlüssel 2^32 nicht überschreiten. Das Beispiel erzeugt den Nonce mit `os.urandom(12)` und vergibt Schlüssel pro Ereignistyp oder Empfängergruppe. Ohne den Hinweis wirkt der Schlüssel unbegrenzt nutzbar. Das ist eine Ergänzung, keine Korrektur, und lässt sich ohne Folgen wieder streichen.

5. kap11-betrieb.typ, Tabelle "Sicherung", Zeile `Nachrichten`, Spalte NATS
   - vorher: "`nats stream backup` / `restore`, bei Clustern mit Replikas 3 meist unnötig"
   - nachher: "`nats backup stream` / `nats backup restore stream`. Drei Replikas schützen vor Knotenausfall, ersetzen aber keine Sicherung"
   - Grund: (i) Die NATS-Doku (Stream backup and restore) nennt `nats backup stream ORDERS <dir>` und `nats backup restore stream <dir>`. Im natscli-Quelltext (`cli/stream_command.go`) sind `nats stream backup` und `nats stream restore` versteckt und als deprecated markiert ("use `nats backup stream` instead"). (ii) Disaster-Recovery-Doku: "R3 replication will not save you from a mistake ... R3 is availability, not a backup". Die alte Aussage "meist unnötig" widerspricht dem.

6. kap11-betrieb.typ, Tabelle "Sicherung", Zeile `Konfiguration`, Spalte RabbitMQ
   - vorher: "... `rabbitmqctl export_definitions defs.json`, im Repository versionieren"
   - nachher: "... im Repository versionieren (der Export enthält Passwort-Hashes der Benutzer)"
   - Grund: Definitions-Doku: "Exported user data contains password hashes as well as password hashing function information". Der unqualifizierte Rat, die Datei zu versionieren, ist in einem Sicherheitsbuch riskant.

7. kap11-betrieb.typ, Tabelle "Sicherung", Zeile `Nachrichten`, Spalte RabbitMQ (Ergänzung)
   - nachher angehängt: "Nachrichten ließen sich nur durch Kopieren des Datenverzeichnisses sichern, nicht aus einem laufenden Knoten"
   - Grund: Backup-Doku: "Presently this is the only way of backing up messages" und "backing them up from under a running node is highly discouraged". Der Satz belegt die bestehende Aussage "in der Regel nicht gesichert".

### (b) Unbelegte Aussagen (bewusst)

- kap08 Einleitung (Broker als zentraler Knoten), Satz "Ein gestohlenes Passwort allein genügt nicht mehr", Bedrohungsgrafik und Bildunterschrift.
- kap08: Empfehlung "Für eine überschaubare Zahl von Diensten genügen Passwörter oder NKeys ..." und "ein Konto pro Dienst, nie ein gemeinsames Konto" (eigene Empfehlung). "Docker-Secrets" bleibt Querverweis auf das Docker-Handbuch.
- kap09: Rechtematrix (Entwurf), "Keiner der Anwendungsdienste darf Streams ... anlegen", Hinweis zu getrennten Accounts für Produktion und Test, Hinweis zu Rechteverletzungen in der Überwachung (Empfehlung).
- kap10: Replay-Bullet ("Der Zeitstempel begrenzt ...", Höchstalter 600 s), "Die Metadaten werden mitsigniert", "Die Vertrauensliste enthält Typen", Reihenfolge der Prüfung (Signatur vor Schema-Validierung), Signatur-Code und Verschlüsselungs-Code (eigene Beispiele), "Datensparsamkeit ... wirksamer als Verschlüsselung". Für die Begriffsdefinition eines Replay-Angriffs gäbe es NIST SP 800-53 bzw. SP 800-63-4 (csrc.nist.gov/glossary/term/replay_attack, abgerufen), sie wurde aber nicht zitiert, weil die Bullet-Aussagen Designentscheidungen sind.
- kap11: Alarmschwellen und empfohlene Alarme (Rückstand, Dead-Letter-Queue nicht leer, Speicherplatz unter 20 Prozent), Zeilen "Dead Letters" (DLQ-Stream, `.dlq`-Queues), Spalte "Advisories zu `max_deliver`", "Redelivery-Rate", Zeile "Rückstand eines Consumers wächst", `korrelation_id`-Konzept, Outbox-Vorteil bei Brokerverlust, "kleinere Systeme ... einzelner Broker oft pragmatischer".
- kap11, Befehlsblock (`nats consumer info`, `nats stream report`, `rabbitmq-diagnostics check_running`, `rabbitmqctl list_queues`): kein Fließtext davor, daher kein Zitat. Die Befehle wurden geprüft: `nats consumer info` und `nats stream report` existieren im natscli-Quelltext, `rabbitmq-diagnostics check_running` steht in der Monitoring-Doku, `messages_ready`, `messages_unacknowledged`, `consumers` sind in der rabbitmqctl-Manpage unter `list_queues` aufgeführt (Manpage nicht zitiert).
- Konfigurations-Snippets in kap08 und kap09 (Codeblöcke werden nicht zitiert). Geprüft wurden: NATS `tls { cert_file key_file ca_file verify timeout }` (Doku, Standard `timeout` 2), `http: host:port` (Config-Referenz), `accounts { ... jetstream: enabled ... } system_account`, `permissions { publish/subscribe { allow } }`, `inbox_prefix` (nats-py: Parameter `inbox_prefix`, Standard `b'_INBOX'`, passt zu `_INBOX_shop.>`), `$JS.API.CONSUMER.MSG.NEXT.<stream>.<consumer>` und `$JS.API.CONSUMER.INFO.<stream>.<consumer>` (Consumer-API-Referenz). RabbitMQ `listeners.ssl.default`, `listeners.tcp = none`, `ssl_options.*`, `loopback_users.guest = true` (ist der Standard laut Konfigurationsdoku), `set_permissions` und `set_topic_permissions` (Argumentreihenfolge [-p vhost] user ... gemäß Manpage), `delete_user`, `add_vhost`. `rabbitmqctl add_user shop` ohne Passwort fragt tatsächlich interaktiv (Quelltext `add_user_command.ex`: `Input.infer_password("Password: ", ...)`). Die Manpage listet das Passwort als Pflichtargument, die Aussage im Code-Kommentar ist aber richtig.

### (c) Quelle trägt nur teilweise

- kap09, "Die Bestätigung eines Streams kommt auf einer _Inbox_ zurück (Standard `_INBOX.>`)": Die Autorisierungs-Doku sagt, dass Antworten auf Requests an `_INBOX.` ankommen und dass jeder JetStream-API-Aufruf ein Request ist. Das PubAck als Antwort auf `js.publish` wird dort nicht ausdrücklich genannt.
- kap09, "Damit Dienste nicht die Antworten anderer mitlesen können, bekommt jeder ein eigenes Inbox-Präfix": belegt durch NATS by Example "Private Inbox" (wörtlich: "explicit inbox prefix ... combined with explicit permissions prevents users from snooping on service replies") und `inbox_prefix` bei nats-py.
- kap09, `Permissions Violation ... schreibt es ins Server-Log`: Die Autorisierungs-Doku zeigt `[ERR] ... Publish Violation - Subject "billing.charge"` im Server-Log. Der Text `Permissions Violation` steht im Client-Fehler (`-ERR 'Permissions Violation for Publish to ...'`). Der Logtext heißt "Publish Violation"/"Subscription Violation".
- kap11, Zeile "Rechteverletzungen" (NATS): Server-Log-Eintrag lautet laut Doku `Publish Violation`, nicht `Permissions Violation`. Die Tabellenzelle blieb unverändert, Zitat belegt Existenz der Meldung. Für RabbitMQ stimmt `access_refused` (Access-Control-Doku: `operation queue.declare caused a channel exception access_refused: access to queue ...`).
- kap11, "Beide Endpunkte zeigen Interna und gehören ... nicht ins öffentliche Netz": NATS-Doku sagt ausdrücklich, dass der Monitoring-Port standardmäßig unauthentifiziert ist ("Anyone who can reach :8222 can read /connz ..."). Für den RabbitMQ-Prometheus-Port (15692) gibt es keine entsprechende Aussage, nur optionale Authentifizierung/TLS. Die RabbitMQ-Netzwerkdoku warnt nur vor Inter-Node-Ports.
- kap08, "Verwaltungsoberflächen ... nie öffentlich erreichbar": Für NATS belegt (Monitoring-Doku), für RabbitMQ Management belegt die Networking-Doku nur die Portliste (15672 HTTP API/UI) und die allgemeine Empfehlung, nur Client-Ports freizugeben.
- kap08, "Benutzername aus dem Zertifikat" (`rabbitmq_auth_mechanism_ssl`): TLS-Doku: "extracts an identity from the certificate and maps it to a RabbitMQ user".
- kap08, NKeys als "Schlüsselpaare": Die Authentifizierungs-Doku nennt "public-key credential", Seed und öffentlichen Schlüssel. Dass NKeys auf Ed25519 beruhen, steht in der Decentralized-Auth-Doku (zitiert).
- kap11, "Anzahl wartender Pull-Anfragen" ↔ `num_waiting`: Doku: "The number of pull consumers waiting for messages". Sinngemäß, nicht wörtlich.
- kap11, `num_pending`: Doku-Definition "number of messages left unconsumed", der Text nennt es "Rückstand". Deckungsgleich.
- kap11, "Quorum Queues, die automatisch auf drei Knoten repliziert werden": Standardgruppengröße ist drei, bei fünf Knoten liegen die Mitglieder auf drei der fünf Knoten. Der Text gilt für den Drei-Knoten-Cluster.
- kap10, "Ed25519 ... mit kurzen Schlüsseln": RFC 8032 nennt 32-Byte-Schlüssel und 64-Byte-Signaturen. "schnell": "high performance" (RFC 8032) bzw. cryptography-Doku ("strongly consider using this").

### (d) Sonstige Beobachtungen

- TLS-Mindestversion: `ctx.minimum_version = ssl.TLSVersion.TLSv1_2` ist konsistent mit RFC 9325 (BCP 195, Abschn. 3.1.1: "MUST support TLS 1.2", "SHOULD support TLS 1.3 ... MUST prefer to negotiate TLS 1.3", "MUST NOT negotiate TLS 1.0/1.1"). Zudem verwendet Python seit 3.10 für `PROTOCOL_TLS_CLIENT` ohnehin TLS 1.2 als Minimum, die Zeile ist redundant, aber schadet nicht. RFC 9325 wird im Text nicht erwähnt und daher nicht zitiert. Bei Bedarf kann man im Absatz vor dem Python-Beispiel einen Satz "Beide Seiten sollen nur TLS 1.2 oder neuer aushandeln und TLS 1.3 bevorzugen" mit `@rfc9325` einfügen. Der Eintrag liegt nicht in `lit-D.yml`, weil nicht zitiert.
- NATS-Ack-Format (siehe Änderung 2): Die Aussage "ab 2.16" beruht auf dem Quellcode des Hauptzweigs. Wenn 2.16 erscheint, prüfen, ob `nats-py` die 11-Token-Reply-Subjects für `msg.metadata` (Zugriff in kap04: `msg.metadata.num_delivered`) parsen kann. Das wurde nicht geprüft.
- `nsc` ist in der aktuellen NATS-Doku nicht mehr das Standardwerkzeug. Die Doku verwendet `nats auth ...`. Die Ökosystem-Seite führt `nsc` weiter als "Standalone CLI for managing operators, accounts, and users. An alternative to the `nats auth` commands". Der Text "verwaltet mit `nsc`" bleibt richtig.
- Die beiden NATS-Seiten `securing_nats/auth_intro/username_password` und `.../nkey_auth` leiten auf dieselbe Seite um (`learn/security/authentication-basics`). Die NATS-Doku wurde zwischenzeitlich umgebaut. Alle zitierten Links verwenden die Zielseiten (`docs.nats.io/learn/...`).
- nats-py: `max_reconnect_attempts` hat den Standardwert 60 (nats-py-Doku). kap04 setzt `-1` ausdrücklich, das ist korrekt. Außerhalb meines Bereichs.
- RabbitMQ 4.3.1: Passive Deklarationen (`get_queue(..., ensure=False)` führt bei aio-pika keine aus, aber andere Clients) erfordern ab 4.3.1 mindestens ein Recht auf die Ressource. In kap09 haben alle Dienste auf ihre Queues mindestens `read` bzw. auf `ereignisse` `write`, die Rechtematrix bleibt gültig.
- Die Topic-Berechtigungen betreffen laut Doku Publish und Bindings auf Topic-Exchanges. Die Access-Control-Doku sagt, Topic-Autorisierung ziele vor allem auf STOMP und MQTT, bei AMQP 0-9-1 wird sie beim Publish und beim Binden geprüft. Der Text von kap09 ist damit gedeckt.
- Keine Eigenheiten bei der Typst-Syntax: Zitate stehen unmittelbar hinter dem Wort bzw. am Zellenende, `rabbit@...` in einem Codeblock ist kein Zitat.
- NIST SP 800-38D ist mit der PDF von `nvlpubs.nist.gov` belegt (Abschn. 8.3). Der Eintrag hat bewusst keine DOI.
- Hinweis für die Merge-Phase: Die Schlüssel der RabbitMQ-Seiten tragen das Präfix `www-rabbitmq-com-docs-...`. Titel laut Quelltext der Doku: ssl = "TLS Support", access-control = "Authentication, Authorisation, Access Control", definitions = "Schema Definition Export and Import", prometheus = "Monitoring with Prometheus and Grafana", alarms = "Memory and Disk Alarms".

---


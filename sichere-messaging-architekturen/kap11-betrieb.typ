#import "lib.typ": *

= Betrieb und Überwachung

Ein Messaging-System fällt selten laut aus. Typischer ist ein stilles Symptom: Ein Consumer hängt, und Nachrichten stauen sich. Eine Dead-Letter-Queue füllt sich über Tage. Ein falsch konfigurierter Dienst bekommt `Permissions Violation`, ohne dass es jemand bemerkt. Überwachung macht diese Zustände sichtbar, bevor Kunden sie bemerken.

== Was überwacht werden muss

#table(columns: (auto, 1fr, 1fr),
  [Kennzahl], [NATS JetStream], [RabbitMQ],
  [*Rückstand* (unverarbeitete Nachrichten)], [`num_pending` pro Consumer @docs-nats-io-reference-jetstream-api-consumer-info], [`messages_ready` pro Queue @www-rabbitmq-com-docs-monitoring],
  [*Unbestätigte Nachrichten*], [`num_ack_pending` @docs-nats-io-reference-jetstream-api-consumer-info], [`messages_unacknowledged` @www-rabbitmq-com-docs-monitoring],
  [*Wiederholungen*], [`num_redelivered` @docs-nats-io-reference-jetstream-api-consumer-info, Advisories zu `max_deliver`], [Redelivery-Rate, `x-delivery-count` @www-rabbitmq-com-docs-quorum-queues],
  [*Dead Letters*], [Nachrichten im DLQ-Stream], [Länge der `.dlq`-Queues],
  [*Consumer aktiv*], [Anzahl wartender Pull-Anfragen @docs-nats-io-reference-jetstream-api-consumer-info], [`consumers` pro Queue @www-rabbitmq-com-docs-monitoring],
  [*Rechteverletzungen*], [Server-Log `Permissions Violation` @docs-nats-io-learn-security-authorization], [Server-Log `access_refused` @www-rabbitmq-com-docs-access-control],
  [*Ressourcen*], [Speicherplatz des Stores], [Speicher- und Platten-Alarme (_alarms_) @www-rabbitmq-com-docs-alarms],
)

```bash
nats consumer info BESTELLUNGEN provisionierung     # Rückstand, ack pending, Redeliveries
nats stream report
rabbitmq-diagnostics check_running
rabbitmqctl list_queues -p bestellungen name messages_ready messages_unacknowledged consumers
```

Für Dashboards und Alarme stellen beide Broker Kennzahlen bereit: NATS über den Überwachungs-Port (`http: 127.0.0.1:8222`, z.B. `/jsz` und `/varz`) @docs-nats-io-learn-monitoring-monitoring-endpoints @docs-nats-io-reference-config mit dem offiziellen Prometheus-Exporter @github-com-nats-io-prometheus-nats-exporter, RabbitMQ über das mitgelieferte Plugin `rabbitmq_prometheus` (Port 15692) @www-rabbitmq-com-docs-prometheus. Beide Endpunkte zeigen Interna und gehören, wie die Verwaltungsoberflächen, nicht ins öffentliche Netz @docs-nats-io-learn-monitoring-monitoring-endpoints.

Sinnvolle Alarme für den Anfang: Rückstand eines Consumers wächst über eine festgelegte Zeit, Dead-Letter-Queue ist nicht leer, ein Consumer hat keine aktive Verbindung, Rechteverletzungen treten auf, Speicherplatz unter 20 Prozent.

== Nachvollziehbarkeit

Die `korrelation_id` aus dem Umschlag (Kapitel 6) verbindet einen Vorgang über alle Dienste: Der Shop setzt sie bei der Bestellung, jeder Dienst übernimmt sie in seine Logs und in alle Folgenachrichten. So lässt sich eine Bestellung vom Eingang bis zur abgeschlossenen Provisionierung verfolgen. Wer verteiltes Tracing mit OpenTelemetry einsetzt, überträgt dessen Kontext (`traceparent`) als Header in der Nachricht @www-w3-org-tr-trace-context @opentelemetry-io-docs-specs-semconv-messaging-messaging-spans.

Logs enthalten Nachrichten-ID, Typ, Korrelations-ID und Ergebnis, aber keine Nutzdaten (API-Handbuch, Kapitel 7). Sicherheitsereignisse wie ungültige Signaturen, abgelehnte Nachrichten und Rechteverletzungen werden gesondert protokolliert und gemeldet.

== Sicherung und Wiederherstellung

#table(columns: (auto, 1fr, 1fr),
  [], [NATS JetStream], [RabbitMQ],
  [Konfiguration], [Stream- und Consumer-Definitionen als Dateien im Repository, angelegt per Skript], [Definitionen exportieren: `rabbitmqctl export_definitions defs.json`, im Repository versionieren (der Export enthält Passwort-Hashes der Benutzer) @www-rabbitmq-com-docs-definitions],
  [Nachrichten], [`nats backup stream` / `nats backup restore stream`. Drei Replikas schützen vor Knotenausfall, ersetzen aber keine Sicherung @docs-nats-io-learn-backup-recovery-stream-backup-restore @docs-nats-io-learn-backup-recovery-disaster-recovery], [in der Regel nicht gesichert: Queues sind Durchgangsstationen, die Quelle der Wahrheit liegt in den Datenbanken der Dienste. Nachrichten ließen sich nur durch Kopieren des Datenverzeichnisses sichern, nicht aus einem laufenden Knoten @www-rabbitmq-com-docs-backup],
)

Die Outbox (Kapitel 7) hat hier einen weiteren Vorteil: Weil jede Nachricht zuerst in der Datenbank des Senders steht, lassen sich Nachrichten eines verlorenen Brokers aus den Outbox-Tabellen erneut veröffentlichen.

== Hochverfügbarkeit in Kürze

Ein einzelner Broker ist ein zentraler Ausfallpunkt. Beide Systeme lassen sich als Cluster aus drei Knoten betreiben: NATS mit `--replicas 3` für Streams @docs-nats-io-learn-topologies-jetstream-in-a-cluster, RabbitMQ mit Quorum Queues, die automatisch auf drei Knoten repliziert werden @www-rabbitmq-com-docs-quorum-queues. Für kleinere Systeme ist ein einzelner, gut überwachter Broker mit schnellem Wiederaufbau (Konfiguration als Code, Outbox als Puffer bei den Producern) oft der pragmatischere Weg.

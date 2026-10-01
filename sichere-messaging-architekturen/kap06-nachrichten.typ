#import "lib.typ": *

= Nachrichten gestalten

Eine Nachricht ist ein Vertrag zwischen Diensten, die sich nicht kennen und unabhängig voneinander weiterentwickelt werden. Ein durchdachtes Format macht diesen Vertrag prüfbar, versionierbar und sicher.

== Ein einheitlicher Umschlag

Jede Nachricht besteht aus einem *Umschlag* mit Metadaten und den eigentlichen *Nutzdaten*. Das Format orientiert sich an der Spezifikation _CloudEvents_ @github-com-cloudevents-spec-blob-main-cloudevents-spec-md: `id`, `source`, `type`, `time` und `data` stammen von dort (das Pflichtattribut `specversion` ist der Kürze halber weggelassen). `version` und `korrelation_id` sind eigene Ergänzungen. `korrelation_id` wäre als CloudEvents-Erweiterung so nicht zulässig, denn Attributnamen bestehen dort nur aus Kleinbuchstaben und Ziffern @github-com-cloudevents-spec-blob-main-cloudevents-spec-md.

#datei("Nachricht bestellung.eingegangen")[
```json
{
  "id": "0b8f6a52-3c1e-4d7a-9f10-6e2d8a4c1b77",
  "type": "bestellung.eingegangen",
  "version": 2,
  "source": "shop",
  "time": "2026-09-24T09:15:02Z",
  "korrelation_id": "b3a1f2e4",
  "data": {
    "bestellung_id": "B-2026-00417",
    "kunde_id": "K-8812",
    "positionen": [{"produkt": "learn", "menge": 25}]
  }
}
```
]

#table(columns: (auto, 1fr),
  [Feld], [Zweck],
  [`id`], [eindeutig pro Nachricht, Grundlage für Deduplizierung (`Nats-Msg-Id` @docs-nats-io-reference-jetstream-api-headers bzw. `message_id`) und idempotente Verarbeitung],
  [`type`, `version`], [was die Nachricht bedeutet und in welcher Schema-Version sie vorliegt],
  [`source`], [welcher Dienst sie erzeugt hat, wird bei signierten Nachrichten geprüft (Kapitel 10)],
  [`time`], [Zeitpunkt des Ereignisses, nicht des Versands @github-com-cloudevents-spec-blob-main-cloudevents-spec-md. Grundlage für Replay-Schutz und Reihenfolge],
  [`korrelation_id`], [verbindet alle Nachrichten und Logs, die zu einem Vorgang gehören],
  [`data`], [die eigentlichen Nutzdaten],
)

== Mit Pydantic prüfen, auf beiden Seiten

#datei("gemeinsam/ereignisse.py")[
```python
from datetime import datetime
from typing import Literal
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field

class Streng(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True)

class Position(Streng):
    produkt: Literal["learn", "assess"]
    menge: int = Field(ge=1, le=10_000)

class BestellungEingegangenV2(Streng):
    bestellung_id: str = Field(pattern=r"^B-\d{4}-\d{5}$")
    kunde_id: str = Field(pattern=r"^K-\d{1,8}$")
    positionen: list[Position] = Field(min_length=1, max_length=100)

class Umschlag(Streng):
    id: UUID
    type: Literal["bestellung.eingegangen"]
    version: Literal[2]
    source: str
    time: datetime
    korrelation_id: str = Field(max_length=64)
    data: BestellungEingegangenV2
```
]

Die Modelle weisen unbekannte Felder ab (`extra="forbid"` löst einen `ValidationError` aus) und sind unveränderlich (`frozen=True`) @pydantic-dev-docs-validation-latest-api-pydantic-config. Wertebereiche, Muster und Längen prüft `Field` @pydantic-dev-docs-validation-latest-api-pydantic-fields. Der Producer erzeugt Nachrichten ausschließlich über diese Modelle, der Consumer prüft jede eingehende Nachricht mit `Umschlag.model_validate_json(msg.data)` @pydantic-dev-docs-validation-latest-api-pydantic-base-model, bevor er irgendetwas damit tut. Eine Nachricht, die die Prüfung nicht besteht, ist ein dauerhafter Fehler und wird sofort aussortiert (Kapitel 2), nicht wiederholt.

Die Modelle liegen in einem gemeinsamen Paket, das Producer und Consumer als Abhängigkeit einbinden, oder werden als JSON-Schema aus Pydantic erzeugt (`Umschlag.model_json_schema()` @pydantic-dev-docs-validation-latest-api-pydantic-base-model) und für Dienste in anderen Sprachen veröffentlicht.

== Schemata weiterentwickeln

#table(columns: (auto, 1fr),
  [Änderung], [Vorgehen],
  [neues optionales Feld], [kompatibel: alte Consumer ignorieren es nur, wenn sie *nicht* `extra="forbid"` für `data` verwenden @pydantic-dev-docs-validation-latest-api-pydantic-config. Deshalb: neue Felder mit neuer `version` einführen.],
  [Feld umbenennen, entfernen, Bedeutung ändern], [neue `version`. Der Producer sendet eine Zeit lang *beide* Versionen oder die Consumer verstehen beide, dann wird die alte abgeschaltet.],
  [neues Ereignis], [neuer `type`, kein Umbau bestehender Ereignisse],
)

Die Regel lautet: Consumer werden *vor* Producern aktualisiert @docs-confluent-io-platform-current-schema-registry-fundamentals-schema-evolution-html. Ein Consumer, der Version 2 und 3 versteht, kann laufen, bevor der Producer auf Version 3 umstellt, umgekehrt nicht.

== Was nicht in Nachrichten gehört

Nachrichten werden kopiert, gespeichert (bei JetStream mit `limits`-Retention wochenlang), in Dead-Letter-Queues aufbewahrt, von Überwachungswerkzeugen angezeigt und in Logs geschrieben. Jedes Feld darin vervielfältigt sich. Deshalb:

- *Keine personenbezogenen Daten, wo eine ID genügt* (Datenminimierung, Art. 5 Abs. 1 lit. c DSGVO @gdpr-info-eu-art-5-gdpr). `kunde_id` statt Name und E-Mail-Adresse. Wer die Details braucht, fragt sie beim zuständigen Dienst ab und bekommt nur, was er darf. Das vereinfacht auch die Umsetzung von Löschpflichten @gdpr-info-eu-art-17-gdpr: Name und E-Mail-Adresse werden an einer Stelle gelöscht, nicht in wochenlang aufbewahrten Streams.
- *Keine Geheimnisse*, keine Zugangsdaten, keine Tokens.
- *Keine großen Nutzdaten.* Dateien und große Dokumente gehören in einen Objektspeicher. Die Nachricht enthält nur einen Verweis (_Claim Check_ @www-enterpriseintegrationpatterns-com-patterns-messaging-storeinlibrary-html). Beide Broker haben Obergrenzen (Kapitel 3), und große Nachrichten bremsen alle anderen aus.
- Wo sensible Inhalte unvermeidlich sind, werden sie Ende-zu-Ende verschlüsselt (Kapitel 10).

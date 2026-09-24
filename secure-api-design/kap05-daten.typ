#import "lib.typ": *

= Datenmodelle: was hinein und was hinaus darf

Platz 3 der OWASP-Liste, _Broken Object Property Level Authorization_, fasst zwei früher getrennte Risiken zusammen: Eine API liefert *mehr Felder* aus, als der Aufrufer sehen darf (_Excessive Data Exposure_), oder sie übernimmt *mehr Felder* aus der Anfrage, als der Aufrufer setzen darf (_Mass Assignment_). Beides lässt sich mit getrennten, expliziten Pydantic-Modellen fast vollständig ausschließen.

== Ein Modell pro Richtung

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0.6), [`NotizNeu` \ #text(size: 6.3pt)[titel, text]], w: 2.6, h: 0.9, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
    kasten((0, -0.7), [`NotizAenderung` \ #text(size: 6.3pt)[titel?, text?]], w: 2.6, h: 0.9, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
    kasten((5.6, 0), [Datenbankmodell `Notiz` \ #text(size: 6.3pt)[id, titel, text, besitzer_id, \ erstellt, geloescht, interne_notiz]], w: 4.2, h: 1.3, bg: rgb("#FFF8E6"), col: c-yellow, size: 7.3pt)
    kasten((11.4, 0), [`NotizAusgabe` \ #text(size: 6.3pt)[id, titel, text, erstellt]], w: 3.0, h: 0.9, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
    pfeil((1.35, 0.5), (3.45, 0.2)); pfeil((1.35, -0.6), (3.45, -0.2))
    pfeil((7.75, 0), (9.85, 0))
    content((0, 1.5), text(size: 7pt, weight: "bold")[Eingabe])
    content((11.4, 0.9), text(size: 7pt, weight: "bold")[Ausgabe])
  }),
  caption: [Eingabe- und Ausgabemodelle enthalten nur erlaubte Felder, das Datenbankmodell bleibt intern.],
)

#datei("app/modelle.py")[
```python
from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field

class Eingabe(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

class NotizNeu(Eingabe):
    titel: str = Field(min_length=1, max_length=200)
    text: str = Field(max_length=20_000)

class NotizAenderung(Eingabe):
    titel: str | None = Field(default=None, min_length=1, max_length=200)
    text: str | None = Field(default=None, max_length=20_000)

class NotizAusgabe(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    titel: str
    text: str
    erstellt: datetime
```
]

- *`extra="forbid"`* lässt jede Anfrage mit unbekannten Feldern scheitern (422). Ein Angreifer, der `"besitzer_id": "..."` oder `"ist_admin": true` mitschickt, bekommt einen Fehler, statt dass das Feld stillschweigend ignoriert oder, schlimmer, übernommen wird.
- *Kein `**daten.model_dump()` direkt ins Datenbankmodell.* Felder wie `besitzer_id` setzt der Server aus dem Token, nie aus der Anfrage.
- *Das Ausgabemodell* legt über `response_model=NotizAusgabe` fest, welche Felder den Server verlassen. Kommt später ein internes Feld zum Datenbankmodell hinzu, taucht es nicht automatisch in der API auf.

#datei("app/main.py")[
```python
@notizen.patch("/{notiz_id}", response_model=NotizAusgabe)
def aendern(notiz_id: UUID, daten: NotizAenderung,
            benutzer: Benutzer = Depends(braucht_scope("notizen:schreiben"))):
    notiz = eigene_notiz_oder_404(notiz_id, benutzer)
    for feld, wert in daten.model_dump(exclude_unset=True).items():
        setattr(notiz, feld, wert)      # nur Felder, die NotizAenderung überhaupt kennt
    return notiz
```
]

Unterscheiden sich die Rechte *pro Feld* (Administratoren dürfen `interne_notiz` sehen, normale Benutzer nicht), bekommen die Rollen eigene Ausgabemodelle, statt Felder im Code dynamisch auszublenden.

== Eingaben begrenzen und validieren

Jedes Feld braucht eine Obergrenze: Länge von Zeichenketten, Anzahl von Listenelementen, Wertebereich von Zahlen. Ohne sie kann ein einzelner Request mit einem 500-MB-Textfeld oder einer Liste mit einer Million Einträgen Speicher und Datenbank überlasten (Kapitel 6).

#table(columns: (auto, 1fr),
  [Pydantic-Mittel], [Einsatz],
  [`Field(max_length=...)`, `min_length`], [Zeichenketten und Listen],
  [`Field(ge=1, le=100)`], [Zahlen, z.B. Seitengröße],
  [`Literal["privat", "team"]`, `Enum`], [feste Wertelisten statt freier Zeichenketten],
  [`EmailStr`, `HttpUrl`, `UUID`], [Formate, die Pydantic selbst prüft],
  [`Field(pattern=r"^[a-z0-9-]{3,40}$")`], [Kennungen mit festem Aufbau],
  [`model_config = ConfigDict(strict=True)`], [keine automatische Umwandlung, etwa von `"1"` in `1`],
)

Die Validierung ersetzt keine sichere Weiterverarbeitung: Datenbankabfragen laufen *immer* parametrisiert (SQLAlchemy macht das automatisch, solange keine Zeichenketten zu SQL zusammengesetzt werden), Ausgaben in HTML werden escaped, Dateinamen aus Anfragen nie direkt als Pfad verwendet.

#achtung[`text(f"SELECT * FROM notizen WHERE titel = '{titel}'")` ist auch mit SQLAlchemy eine SQL-Injection. Richtig: `text("SELECT * FROM notizen WHERE titel = :titel").bindparams(titel=titel)` oder die Abfrage-API von SQLAlchemy.]

== Datei-Uploads

- Größe begrenzen, bevor die Datei vollständig eingelesen wird (am Reverse Proxy und in der Anwendung).
- Dateityp am Inhalt prüfen, nicht an Endung oder `Content-Type` des Clients; nur eine kleine Allowlist zulassen.
- Erst in *Quarantäne* unter einem zufälligen, serverseitig erzeugten Namen speichern. Vor Freigabe Malware-Scan und – falls Archive erlaubt sind – Grenzen für Dateianzahl, entpackte Größe und Verschachtelung anwenden.
- Außerhalb des Webroots oder in privatem Object Storage speichern. Downloads autorisieren, kurzlebige signierte URLs verwenden und möglichst über eine eigene Download-Domain ohne Cookies ausliefern.
- Beim Ausliefern `Content-Disposition: attachment` mit sicher kodiertem Dateinamen, `X-Content-Type-Options: nosniff` und einen serverseitig bestimmten Typ setzen. Benutzerdateinamen werden nie als Pfad oder Header-Rohwert übernommen.

Nicht jedes Format ist gleich: SVG, HTML, Office-Dokumente und PDFs können aktive Inhalte oder externe Referenzen enthalten. Wenn die Funktion sie nicht zwingend braucht, werden sie nicht akzeptiert; sonst erfolgt eine formatspezifische Bereinigung beziehungsweise Konvertierung in einer isolierten Umgebung.

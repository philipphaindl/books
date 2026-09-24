#import "lib.typ": *

= SSRF und fremde APIs

Bei _Server Side Request Forgery_ (OWASP API7) bringt ein Angreifer die API dazu, eine von ihm gewählte Adresse aufzurufen. _Unsafe Consumption of APIs_ (API10) entsteht, wenn Antworten fremder Dienste zu viel Vertrauen bekommen.

== Server Side Request Forgery

Link-Vorschau, Bildimport, frei wählbare Webhooks oder PDF-Erzeugung aus einer URL können Zugriff auf interne Dienste, `localhost`, Docker-Netze oder Cloud-Metadaten ermöglichen.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [Angreifer], w: 2.0, h: 0.8, bg: rgb("#FBEAEA"), col: c-red)
    rahmen((3.3, -2.1), (15.2, 1.2), [internes Netz (Server, Docker-Netz, Cloud)], c-grey, bg: luma(250))
    kasten((5.3, 0), [API \ #text(size: 6.5pt)[lädt "Vorschau"]], w: 2.3, h: 1.0, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((10.2, 0.45), [`http://db:5432`, `http://redis:6379`], w: 4.2, h: 0.6, bg: rgb("#FFF8E6"), col: c-yellow, size: 7pt)
    kasten((10.2, -0.45), [`http://169.254.169.254/` \ #text(size: 6.3pt)[Cloud-Metadaten]], w: 4.2, h: 0.8, bg: rgb("#FFF8E6"), col: c-yellow, size: 7pt)
    kasten((10.2, -1.45), [`http://localhost:8000/admin`], w: 4.2, h: 0.6, bg: rgb("#FFF8E6"), col: c-yellow, size: 7pt)
    pfeil((1.05, 0.2), (4.1, 0.2), label: "url=...", loff: (0, 0.22), color: c-red)
    pfeil((6.5, 0.2), (8.05, 0.45), color: c-red); pfeil((6.5, 0), (8.05, -0.45), color: c-red); pfeil((6.5, -0.2), (8.05, -1.45), color: c-red)
  }),
  caption: [Die API erreicht Ziele, die von außen nicht erreichbar sind.],
)

=== Abwehr in Schichten

+ *Keine freien Ziele, wenn vermeidbar:* IDs oder eine exakte Allowlist vertrauenswürdiger Partner statt beliebiger URLs.
+ *Strenge URL-Regeln:* nur `https`, kein Benutzername/Passwort, erwarteter Port, normalisierter Host; alle DNS-Ergebnisse auf öffentliche Adressen prüfen.
+ *Keine Redirects* – oder jedes Ziel erneut vollständig prüfen.
+ *Antwort begrenzen:* Zeit, Bytes und erlaubte Medientypen, bevor der Body vollständig geladen ist.
+ *Egress-Kontrolle:* Proxy/Firewall blockiert interne, Link-Local- und Metadatenziele. Diese Netzwerkgrenze ist bei freien URLs unverzichtbar, weil Anwendungsprüfungen DNS-Rebinding und Parser-Unterschiede nie vollständig ausschließen.

#datei("app/ssrf.py")[
```python
import ipaddress
import socket
from urllib.parse import urlsplit

import httpx

MAX_BYTES = 100_000

class UnerlaubtesZiel(ValueError): ...

def ziel_vorpruefen(url: str) -> None:
    teile = urlsplit(url)
    if (teile.scheme != "https" or not teile.hostname or
            teile.username is not None or teile.password is not None or
            teile.port not in (None, 443)):
        raise UnerlaubtesZiel("nur https ohne Userinfo auf Port 443")
    adressen = {info[4][0] for info in socket.getaddrinfo(teile.hostname, 443)}
    if not adressen or any(not ipaddress.ip_address(a).is_global for a in adressen):
        raise UnerlaubtesZiel("Zieladresse nicht erlaubt")

def vorschau_laden(url: str) -> str:
    ziel_vorpruefen(url)
    timeout = httpx.Timeout(5.0, connect=2.0)
    with httpx.Client(timeout=timeout, follow_redirects=False) as client:
        with client.stream("GET", url, headers={"User-Agent": "notizen-vorschau"}) as antwort:
            antwort.raise_for_status()
            typ = antwort.headers.get("content-type", "").split(";", 1)[0]
            if typ not in {"text/html", "text/plain"}:
                raise UnerlaubtesZiel("Medientyp nicht erlaubt")
            laenge = antwort.headers.get("content-length")
            if laenge is not None and int(laenge) > MAX_BYTES:
                raise UnerlaubtesZiel("Antwort zu groß")
            daten = bytearray()
            for block in antwort.iter_bytes():
                if len(daten) + len(block) > MAX_BYTES:
                    raise UnerlaubtesZiel("Antwort zu groß")
                daten.extend(block)
    return daten.decode("utf-8", errors="replace")
```
]

`client.get()` wäre hier falsch: Es lädt den Body vollständig, bevor ein nachträgliches `text[:100_000]` greift. Auch der Code oben ist nur eine Anwendungsschicht; zwischen DNS-Prüfung und Verbindung kann sich die Auflösung ändern. Die robuste Produktionslösung verbindet über einen kontrollierten Egress-Proxy beziehungsweise erzwingt die Sperre im Netz.

== Fremde APIs konsumieren

Partnerantworten sind untrusted input: mit Pydantic validieren, Antwortgröße und Zeit begrenzen, TLS nie mit `verify=False` abschalten und pro Partner minimale Zugangsdaten verwenden. Fehler des Partners werden nicht ungefiltert an eigene Clients durchgereicht. Retries erfolgen nur bei sicher wiederholbaren Operationen, mit Backoff, Obergrenze und Jitter; Circuit Breaker verhindern Kaskaden.

== Webhooks signieren und Replays verhindern

Ein Zeitstempel begrenzt das Replay-Fenster, verhindert aber keine zweite Zustellung *innerhalb* dieses Fensters. Deshalb besitzt jedes Ereignis zusätzlich eine eindeutige ID, die der Empfänger für mindestens die Toleranzdauer atomar speichert und nur einmal akzeptiert.

#datei("app/webhooks.py")[
```python
import hashlib, hmac, time

def signieren(geheimnis: bytes, koerper: bytes, ereignis: str) -> dict[str, str]:
    zeit = str(int(time.time()))
    inhalt = ereignis.encode() + b"." + zeit.encode() + b"." + koerper
    sig = hmac.new(geheimnis, inhalt, hashlib.sha256).hexdigest()
    return {"X-Ereignis-ID": ereignis, "X-Signatur-Zeit": zeit,
            "X-Signatur-Key": "2026-09", "X-Signatur": sig}

def pruefen(geheimnis, koerper, ereignis, zeit, sig, toleranz=300):
    try:
        sekunden = int(zeit)
    except ValueError:
        return False
    if abs(time.time() - sekunden) > toleranz: return False
    inhalt = ereignis.encode() + b"." + zeit.encode() + b"." + koerper
    erwartet = hmac.new(geheimnis, inhalt, hashlib.sha256).hexdigest()
    return hmac.compare_digest(erwartet, sig)
```
]

Die ID stammt aus dem persistenten Outbox-Eintrag. Signiert wird der rohe Body (`await request.body()`), nicht neu serialisiertes JSON. Nach gültiger Signatur reserviert der Empfänger die ID per Unique-Constraint; ein Duplikat bleibt wirkungslos. Die Key-ID ermöglicht Rotation. Rate-/Größenlimits gelten auch hier; Geheimnisse und Rohdaten landen nie im Log.

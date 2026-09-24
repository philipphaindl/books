#import "lib.typ": *

= Nachrichten signieren und verschlüsseln

TLS schützt die Strecke, Rechte begrenzen, wer was senden darf. Zwei Lücken bleiben: Der Broker selbst (und jeder mit Zugriff auf ihn, seine Backups oder die Verwaltungsoberfläche) sieht alle Inhalte im Klartext. Und ein Empfänger kann nicht nachprüfen, *welcher Dienst* eine Nachricht erzeugt hat, sondern vertraut darauf, dass der Broker die Rechte korrekt durchsetzt. Signaturen und Verschlüsselung *auf Ebene der Nachricht* schließen diese Lücken Ende-zu-Ende, unabhängig vom Broker.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [`shop` \ #text(size: 6.3pt)[signiert mit privatem Schlüssel]], w: 3.2, h: 1.0, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
    kasten((6.2, 0), [Broker \ #text(size: 6.3pt)[sieht nur Chiffrat]], w: 2.6, h: 1.0, bg: rgb("#E7F4F2"), col: c-teal, size: 7.3pt)
    kasten((12.2, 0), [`provisionierung` \ #text(size: 6.3pt)[prüft mit öffentlichem Schlüssel]], w: 3.6, h: 1.0, bg: rgb("#FDF1EC"), col: c-accent, size: 7.3pt)
    kasten((0, -1.6), [privater Schlüssel `shop`], w: 3.2, h: 0.6, bg: rgb("#F1ECF8"), col: c-violet, size: 7pt)
    kasten((12.2, -1.75), [Vertrauensliste \ #text(size: 6.3pt)[Schlüssel -> erlaubte Typen]], w: 3.6, h: 0.9, bg: rgb("#F1ECF8"), col: c-violet, size: 7pt)
    pfeil((1.65, 0), (4.85, 0), label: "signiert", loff: (0, 0.22))
    pfeil((7.55, 0), (10.35, 0))
    line((0, -1.25), (0, -0.55), stroke: c-violet + 0.8pt)
    line((12.2, -1.3), (12.2, -0.55), stroke: c-violet + 0.8pt)
  }),
  caption: [Die Signatur beweist die Herkunft Ende-zu-Ende. Der Broker muss dafür nicht vertrauenswürdig sein.],
)

== Signieren mit Ed25519

Jeder Producer bekommt ein eigenes Schlüsselpaar. Der private Schlüssel bleibt beim Dienst (als Secret), die öffentlichen Schlüssel aller Producer sind den Consumern bekannt, zusammen mit der Angabe, *welche Ereignistypen* der jeweilige Producer erzeugen darf. Die Bibliothek `cryptography` bringt Ed25519 mit, ein modernes, schnelles Signaturverfahren mit kurzen Schlüsseln:

#datei("gemeinsam/signatur.py")[
```python
import base64, time
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey, Ed25519PublicKey

def _signierbar(typ: str, nachricht_id: str, zeit: str, koerper: bytes) -> bytes:
    # Metadaten mitsignieren, damit sie nicht ausgetauscht werden können
    return b"\n".join([typ.encode(), nachricht_id.encode(), zeit.encode(), koerper])

def signieren(schluessel: Ed25519PrivateKey, schluessel_id: str, typ: str,
              nachricht_id: str, koerper: bytes) -> dict[str, str]:
    zeit = str(int(time.time()))
    sig = schluessel.sign(_signierbar(typ, nachricht_id, zeit, koerper))
    return {"X-Schluessel": schluessel_id, "X-Zeit": zeit,
            "X-Signatur": base64.b64encode(sig).decode()}

# Welche Schlüssel-ID darf welche Ereignistypen signieren?
VERTRAUEN: dict[str, tuple[Ed25519PublicKey, set[str]]] = {}   # aus Konfiguration geladen

def pruefen(typ: str, nachricht_id: str, koerper: bytes, kopf: dict[str, str],
            max_alter: int = 600) -> None:
    eintrag = VERTRAUEN.get(kopf.get("X-Schluessel", ""))
    if eintrag is None or typ not in eintrag[1]:
        raise DauerhafterFehler("unbekannter Schlüssel oder Typ nicht erlaubt")
    if abs(time.time() - int(kopf["X-Zeit"])) > max_alter:
        raise DauerhafterFehler("zu alt: möglicher Replay")
    try:
        eintrag[0].verify(base64.b64decode(kopf["X-Signatur"]),
                          _signierbar(typ, nachricht_id, kopf["X-Zeit"], koerper))
    except InvalidSignature:
        raise DauerhafterFehler("Signatur ungültig")
```
]

Drei Details sind entscheidend:

- *Die Metadaten werden mitsigniert.* Würde nur der Körper signiert, könnte ein Angreifer eine gültig signierte Nachricht mit einem anderen `type` oder einer anderen ID erneut einspielen.
- *Die Vertrauensliste enthält Typen, nicht nur Schlüssel.* Eine gültige Signatur von `benachrichtigung` auf einem Ereignis `zahlung.eingegangen` wird abgelehnt, genau wie die Topic-Rechte aus Kapitel 9, aber unabhängig vom Broker.
- *Replay-Schutz:* Der Zeitstempel begrenzt, wie lange eine abgefangene Nachricht gültig ist. Zusammen mit der Deduplizierung über die Nachrichten-ID im idempotenten Consumer (Kapitel 7) wirkt eine wiederholt eingespielte Nachricht nicht ein zweites Mal. Das Höchstalter muss zu den Wiederholungen passen: Wer Dead Letters nach Tagen wieder einspielt, prüft beim Einspielen oder signiert neu.

Die Prüfung gehört an den Anfang der Verarbeitung, *vor* die Schema-Validierung und vor jeden Datenbankzugriff. Eine ungültige Signatur ist ein dauerhafter Fehler und ein Sicherheitsereignis, das geloggt und gemeldet wird.

== Inhalte verschlüsseln

Enthält eine Nachricht unvermeidlich sensible Inhalte, werden die Nutzdaten zusätzlich verschlüsselt, sodass weder Broker noch Backups noch Verwaltungsoberflächen sie lesen können. AES-GCM verschlüsselt und schützt gleichzeitig gegen Veränderung. Die Nachrichten-ID und der Typ werden als _zusätzliche authentifizierte Daten_ (AAD) eingebunden, damit ein Chiffrat nicht in eine andere Nachricht verpflanzt werden kann:

#datei("gemeinsam/verschluesselung.py")[
```python
import os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

def verschluesseln(schluessel: bytes, typ: str, nachricht_id: str, klartext: bytes) -> bytes:
    nonce = os.urandom(12)                                   # pro Nachricht neu, nie wiederverwenden
    aad = f"{typ}|{nachricht_id}".encode()
    return nonce + AESGCM(schluessel).encrypt(nonce, klartext, aad)

def entschluesseln(schluessel: bytes, typ: str, nachricht_id: str, daten: bytes) -> bytes:
    nonce, chiffrat = daten[:12], daten[12:]
    return AESGCM(schluessel).decrypt(nonce, chiffrat, f"{typ}|{nachricht_id}".encode())
```
]

Der Schlüssel (32 zufällige Bytes, `AESGCM.generate_key(bit_length=256)`) wird pro Ereignistyp oder pro Empfängergruppe vergeben und nur den Diensten bereitgestellt, die die Inhalte lesen müssen. Für Schlüsselwechsel trägt jede Nachricht eine Schlüssel-ID im Header, und Empfänger halten während einer Übergangszeit den alten und den neuen Schlüssel vor.

#achtung[Kryptographie auf Nachrichtenebene verschiebt das Problem in die Schlüsselverwaltung: Wer die Schlüssel hat, kann alles. Private Schlüssel und AES-Schlüssel sind Secrets wie Datenbankpasswörter (Docker-Secrets, nie im Repository, nie in Logs), brauchen einen Plan für Austausch und Widerruf und sollten pro Umgebung verschieden sein. Für viele Systeme ist *Datensparsamkeit* (Kapitel 6: IDs statt Inhalten) die einfachere und wirksamere Maßnahme als Verschlüsselung.]

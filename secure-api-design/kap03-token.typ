#import "lib.typ": *

= Tokens in FastAPI prüfen

Token-Prüfung ist mehr als Dekodieren: Die API muss kryptografisch und semantisch beweisen, dass das Token vom erwarteten Aussteller stammt, für genau diese API bestimmt, noch gültig und tatsächlich ein Access-Token ist.

== Der Prüfvertrag

#table(columns: (auto, 1fr),
  [Prüfung], [Warum],
  [*Signatur* mit einem bekannten öffentlichen Schlüssel], [Nur der erwartete Authorization Server kann gültige Tokens erzeugen.],
  [*Algorithmus* aus einer festen Liste], [Verhindert `alg: none` und Algorithmus-Verwechslungen.],
  [*Issuer* (`iss`) exakt], [Kein Token eines anderen Providers derselben Instanz.],
  [*Audience* (`aud`) der API], [Kein Token für eine andere Anwendung.],
  [*Typ* des Tokens], [ID-Token und andere JWT-Arten dürfen nie als Access-Token gelten.],
  [*Zeit* (`exp`, ggf. `nbf`, `iat`)], [Abgelaufene oder noch nicht gültige Tokens werden abgewiesen; kleine Toleranz nur für Uhrabweichung.],
  [*Claim-Formate*], [`sub`, `scope` und `groups` haben den erwarteten Typ und Inhalt.],
  [*Berechtigungen*], [Scopes und Objekt-/Funktionsrechte werden pro Endpunkt geprüft.],
)

RFC 8725 verlangt feste Algorithmen und voneinander getrennte Validierungsregeln für unterschiedliche JWT-Arten. RFC 9068 definiert für standardkonforme JWT-Access-Tokens den Header `typ: at+jwt` und eine API-spezifische Audience.

#achtung[*Stand Authentik 2026.8:* Authentik erzeugt noch keine RFC-9068-konformen Access-Tokens mit `typ: at+jwt`. Ein lokal geprüftes Authentik-JWT lässt sich daher nicht allein anhand des Standard-Headers zweifelsfrei von einem ID-Token unterscheiden. Das ist keine Kleinigkeit: Ist die Audience gleich, kann ein gültiges ID-Token sonst den lokalen Prüfvertrag erfüllen.]

Für Authentik gibt es drei belastbare Betriebsvarianten:

+ *API-spezifischer Provider/Audience* und Token Exchange: Die API akzeptiert nur Tokens des Ziel-Providers; ein Integrationstest muss ein echtes ID-Token ausdrücklich ablehnen.
+ *Opaque Token beziehungsweise Introspection:* Die API fragt den vertraulichen Provider am Introspection-Endpunkt nach Aktivität und Token-Metadaten. Das erleichtert Widerruf, kostet aber Verfügbarkeit und Latenz.
+ *Lokaler, installationsspezifischer Access-Token-Claim:* etwa `token_use=access`, der nachweislich nur im Access-Token vorkommt. Das ist kein Standardersatz für RFC 9068 und muss nach jedem IdP-Update mit echten Token-Proben getestet werden.

== Lokale JWT-Prüfung

`jwks_url` stammt aus `jwks_uri` des Discovery-Dokuments und wird als Konfiguration übernommen. So funktioniert auch der globale Authentik-Issuer-Modus, bei dem Issuer und JWKS-Adresse nicht denselben Pfad haben.

#datei("app/auth.py")[
```python
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import PyJWKClient
from jwt.exceptions import PyJWKClientError, PyJWTError
from pydantic import BaseModel, ConfigDict, Field, ValidationError, field_validator

from app.settings import settings

_jwks = PyJWKClient(
    settings.jwks_url,
    cache_jwk_set=True,
    lifespan=300,
    timeout=5,
    cooldown_duration=30,
)
_bearer = HTTPBearer(auto_error=False)

class TokenClaims(BaseModel):
    model_config = ConfigDict(extra="ignore")
    sub: str
    scope: str = ""
    groups: list[str] = Field(default_factory=list)
    token_use: str

    @field_validator("sub")
    @classmethod
    def sub_nicht_leer(cls, wert: str) -> str:
        if not wert:
            raise ValueError("sub fehlt")
        return wert

class Benutzer(BaseModel):
    id: str
    scopes: frozenset[str]
    gruppen: frozenset[str]

def _nicht_angemeldet() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Nicht angemeldet",
        headers={"WWW-Authenticate": "Bearer"},
    )

def aktueller_benutzer(
    cred: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> Benutzer:
    if cred is None or cred.scheme.lower() != "bearer":
        raise _nicht_angemeldet()
    try:
        schluessel = _jwks.get_signing_key_from_jwt(cred.credentials)
        roh = jwt.decode(
            cred.credentials,
            schluessel.key,
            algorithms=["RS256"],
            issuer=settings.issuer,
            audience=settings.audience,
            leeway=30,
            options={"require": ["exp", "iat", "iss", "aud", "sub"]},
        )
        claims = TokenClaims.model_validate(roh)
        if claims.token_use != "access":       # eigenes Authentik-Scope-Mapping
            raise ValueError("kein Access-Token")
    except (PyJWTError, PyJWKClientError, ValidationError, ValueError):
        raise _nicht_angemeldet() from None
    return Benutzer(
        id=claims.sub,
        scopes=frozenset(claims.scope.split()),
        gruppen=frozenset(claims.groups),
    )
```
]

Der Claim `token_use` ist hier ein *bewusstes lokales Vertragsmerkmal*. Das zugehörige Authentik-Scope-Mapping darf nicht ins ID-Token übernommen werden. Ein Test mit real ausgestellten Access- und ID-Tokens ist Teil des Deployments. Sobald Authentik RFC 9068 unterstützt, wird stattdessen vor dem Dekodieren der unverified Header gelesen, ausschließlich `typ` geprüft und nur `at+jwt` beziehungsweise `application/at+jwt` akzeptiert.

`PyJWKClient` hält in dieser Konfiguration das *JWKS-Set* fünf Minuten im Cache. `cache_keys=True` wird bewusst nicht verwendet: Diese Option würde einzelne Schlüssel zusätzlich ohne Zeitablauf per LRU cachen. Eine unbekannte `kid` löst, durch eine Abkühlzeit gegen Missbrauch begrenzt, eine Aktualisierung aus. Ist der IdP nicht erreichbar und kein passender Schlüssel verfügbar, gilt _fail closed_: 401.

Alle Systeme synchronisieren ihre Uhr. `leeway=30` ist eine kleine, begründete Toleranz, keine Verlängerung der Token-Laufzeit. Die API folgt niemals `jku` oder `x5u` aus einem Token; der JWKS-Endpunkt kommt ausschließlich aus vertrauenswürdiger Konfiguration.

== Scopes und Gruppen prüfen

#datei("app/auth.py (Fortsetzung)")[
```python
def braucht_scope(*erforderlich: str):
    def pruefen(benutzer: Benutzer = Depends(aktueller_benutzer)) -> Benutzer:
        if not set(erforderlich) <= benutzer.scopes:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Keine Berechtigung")
        return benutzer
    return pruefen

def braucht_gruppe(gruppe: str):
    def pruefen(benutzer: Benutzer = Depends(aktueller_benutzer)) -> Benutzer:
        if gruppe not in benutzer.gruppen:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Keine Berechtigung")
        return benutzer
    return pruefen
```
]

#datei("app/main.py (Ausschnitt)")[
```python
from fastapi import APIRouter, Depends, FastAPI
from app.auth import Benutzer, aktueller_benutzer, braucht_scope

app = FastAPI()
notizen = APIRouter(prefix="/notizen", dependencies=[Depends(aktueller_benutzer)])

@notizen.get("")
def liste(benutzer: Benutzer = Depends(braucht_scope("notizen:lesen"))): ...

@notizen.post("")
def anlegen(benutzer: Benutzer = Depends(braucht_scope("notizen:schreiben"))): ...

app.include_router(notizen)
```
]

Die Router-Abhängigkeit schützt neue Endpunkte standardmäßig; öffentliche Endpunkte gehören auf einen eigenen Router. FastAPI cached denselben Dependency-Aufruf innerhalb einer Anfrage, daher wird `aktueller_benutzer` trotz der zusätzlichen Scope-Abhängigkeit nicht doppelt ausgeführt.

== Widerruf und gebundene Tokens

Ein lokal geprüftes JWT bleibt grundsätzlich bis `exp` gültig. Deshalb sind Access-Tokens kurzlebig. Für sofortigen Widerruf wird Introspection mit kurzem, begrenztem Cache eingesetzt; Client-Credentials dafür liegen als Secret vor, Fehler schließen den Zugriff. Öffentliche Clients müssen Refresh-Tokens nach RFC 9700 rotieren oder sendergebunden einsetzen. Authentik rotiert Refresh-Tokens automatisch, wenn es im Provider konfiguriert ist.

Für Hochrisiko-APIs können mTLS-gebundene Tokens (RFC 8705) oder DPoP (RFC 9449) den Token-Diebstahl erschweren. Das Verfahren muss Access-Token, Client und API durchgängig unterstützen; ein `bound_key`-Scope, der nur ein ID-Token bindet, genügt dafür nicht.

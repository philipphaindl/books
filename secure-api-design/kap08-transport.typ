#import "lib.typ": *

= Transport, Header, CORS und Konfiguration

OWASP API8, _Security Misconfiguration_, ist ein Sammelbecken für Fehler, die nicht im Code, sondern in der Konfiguration stecken: unverschlüsselte Verbindungen, fehlende Header, zu offene CORS-Regeln, aktivierter Debug-Modus, öffentlich erreichbare Dokumentation @api-security-owasp-org-editions-2023-en-0xa8-security-misconfiguration. Einzeln harmlos wirkend, sind sie oft der erste Schritt eines Angriffs.

== TLS überall

Die API ist ausschließlich über HTTPS erreichbar @cheatsheetseries-owasp-org-cheatsheets-rest-security-cheat-sheet-html, Klartext-HTTP leitet der Reverse Proxy nur noch um. Caddy erledigt Zertifikate und Umleitung automatisch @caddyserver-com-docs-automatic-https (Docker-Handbuch, Kapitel 13). Ob die Strecke zwischen Proxy und API ebenfalls TLS braucht, folgt aus der Vertrauensgrenze: Auf demselben kontrollierten Host in einem isolierten Netz kann Klartext vertretbar sein; über Hosts, Clusterknoten, fremdverwaltete Netze oder bei besonders schützenswerten Daten wird sie mit TLS beziehungsweise mTLS geschützt.

== Sicherheits-Header für APIs

Eine API liefert JSON, keine Webseiten, braucht also weniger Header als eine Website. Die folgenden empfiehlt das OWASP _REST Security Cheat Sheet_ @cheatsheetseries-owasp-org-cheatsheets-rest-security-cheat-sheet-html trotzdem, weil Antworten im Browser landen können:

#table(columns: (auto, 1fr),
  [Header], [Wirkung],
  [`Strict-Transport-Security: max-age=63072000; includeSubDomains`], [Browser verwendet für die Domain nur noch HTTPS @developer-mozilla-org-en-us-docs-web-http-reference-headers-strict-transport-security @rfc6797],
  [`Cache-Control: no-store`], [Antworten mit persönlichen Daten landen nicht in Caches von Browsern oder Proxys @developer-mozilla-org-en-us-docs-web-http-reference-headers-cache-control],
  [`X-Content-Type-Options: nosniff`], [Browser interpretiert JSON nicht als HTML oder Skript @developer-mozilla-org-en-us-docs-web-http-reference-headers-x-content-type-options],
  [`Content-Security-Policy: frame-ancestors 'none'`], [Antworten dürfen nicht in fremde Seiten eingebettet werden @developer-mozilla-org-en-us-docs-web-http-reference-headers-content-security-policy-frame-ancestors],
  [`Content-Type: application/json`], [immer korrekt gesetzt, bei FastAPI automatisch],
)

`includeSubDomains` wird nur gesetzt, wenn *jede* Subdomain dauerhaft HTTPS unterstützt; sonst kann HSTS andere Anwendungen unerreichbar machen @developer-mozilla-org-en-us-docs-web-http-reference-headers-strict-transport-security @rfc6797. `preload` ist eine bewusste, schwer rückgängig zu machende Entscheidung @developer-mozilla-org-en-us-docs-web-http-reference-headers-strict-transport-security und gehört nicht automatisch in eine Beispielkonfiguration.

#datei("Caddyfile")[
```text
api.example.com {
    reverse_proxy api:8000
    request_body {
        max_size 1MB
    }
    header {
        Strict-Transport-Security "max-age=63072000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        Content-Security-Policy "frame-ancestors 'none'"
        Cache-Control "no-store"
        -Server
    }
}
```
]

Das `-Server` @caddyserver-com-docs-caddyfile-directives-header entfernt den Header, der Software und Version des Servers verrät. Die Header am Proxy zu setzen hat den Vorteil, dass sie für alle Antworten gelten, auch für Fehlerseiten, die die Anwendung nie erreichen.

== CORS richtig verstehen

_Cross-Origin Resource Sharing_ legt fest, welche fremden Webseiten per JavaScript im Browser auf die API zugreifen dürfen @developer-mozilla-org-en-us-docs-web-http-guides-cors. Zwei Missverständnisse sind verbreitet: CORS schützt die API *nicht* vor Angreifern mit `curl` oder eigenen Programmen, es ist ausschließlich eine Regel für Browser @developer-mozilla-org-en-us-docs-web-http-guides-cors. Und eine zu offene CORS-Konfiguration erlaubt fremden Webseiten, im Namen eingeloggter Benutzer Anfragen zu stellen und die Antworten zu lesen, wenn die API Cookies akzeptiert.

#datei("app/main.py")[
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://notizen.example.com"],     # exakte Liste, kein "*"
    allow_methods=["GET", "POST", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type", "Idempotency-Key"],
    allow_credentials=False,                            # True nur, wenn Cookies nötig sind
    max_age=600,
)
```
]

#achtung[Die Kombination aus `allow_origins=["*"]` und `allow_credentials=True` @fastapi-tiangolo-com-tutorial-cors @developer-mozilla-org-en-us-docs-web-http-guides-cors oder das Zurückspiegeln des `Origin`-Headers der Anfrage öffnet die API für jede Webseite im Internet. Braucht nur die eigene Web-App Zugriff, genügt genau deren Adresse. Wird die API nur serverseitig (BFF) oder von Apps genutzt, braucht es gar keine CORS-Middleware.]

== Cookie-Sessions und CSRF

CORS ist *kein* CSRF-Schutz. Ein BFF setzt sein Session-Cookie mindestens mit `Secure`, `HttpOnly` und möglichst `SameSite=Lax` oder `Strict`; `SameSite=None` ist nur für echte Cross-Site-Anforderungen zulässig und verlangt `Secure` @developer-mozilla-org-en-us-docs-web-http-reference-headers-set-cookie. Zustandsändernde Anfragen (`POST`, `PUT`, `PATCH`, `DELETE`) brauchen zusätzlich ein Synchronizer- oder Double-Submit-CSRF-Token oder eine gleichwertige serverseitige Prüfung von `Origin` und Fetch-Metadata-Headern @cheatsheetseries-owasp-org-cheatsheets-cross-site-request-forgery-prevention-cheat-sheet-html. `SameSite` ist Verteidigung in der Tiefe, kein alleiniger Beweis @cheatsheetseries-owasp-org-cheatsheets-cross-site-request-forgery-prevention-cheat-sheet-html. Zustandsändernde Aktionen verwenden nie `GET` @cheatsheetseries-owasp-org-cheatsheets-cross-site-request-forgery-prevention-cheat-sheet-html.

== Konfiguration und Geheimnisse

#datei("app/settings.py")[
```python
from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="NOTIZEN_", secrets_dir="/run/secrets")
    issuer: str                          # https://auth.example.com/application/o/notizen/
    audience: str                        # eigene Audience der API
    jwks_url: str                        # aus Discovery, nicht aus issuer zusammensetzen
    db_password: SecretStr               # aus Umgebung oder Datei in /run/secrets
    docs_aktiv: bool = False
    umgebung: str = "produktion"

settings = Settings()                    # fehlt ein Pflichtwert: Start schlägt fehl
```
]

- *Fehlende Pflichtwerte verhindern den Start.* Eine API ohne konfigurierten Issuer darf nicht mit einem Standardwert loslaufen @pydantic-dev-docs-validation-latest-concepts-pydantic-settings.
- *`SecretStr`* verhindert, dass ein Passwort versehentlich in Logs oder Fehlermeldungen erscheint: Es wird als `**********` ausgegeben, der echte Wert nur mit `.get_secret_value()` @pydantic-dev-docs-validation-latest-api-pydantic-types.
- *`secrets_dir`* liest Geheimnisse aus Dateien, deren Name dem Namen der Umgebungsvariable entspricht @pydantic-dev-docs-validation-latest-concepts-pydantic-settings, passend zu Docker-Secrets (Docker-Handbuch, Kapitel 12).

== Dokumentation und Debug in Produktion

FastAPI stellt unter `/docs`, `/redoc` und `/openapi.json` automatisch eine vollständige Beschreibung aller Endpunkte bereit @fastapi-tiangolo-com-tutorial-metadata. Für eine öffentliche API ist das gewollt; bei einer internen API kann man sie abschalten @fastapi-tiangolo-com-tutorial-metadata oder hinter eine Anmeldung legen, um unbeabsichtigte Informationsfreigabe zu reduzieren. Das ist *keine Sicherheitsgrenze*: Jeder Endpunkt bleibt vollständig authentifiziert und autorisiert, auch wenn seine Dokumentation unsichtbar ist.

```python
app = FastAPI(
    docs_url="/docs" if settings.docs_aktiv else None,
    redoc_url=None,
    openapi_url="/openapi.json" if settings.docs_aktiv else None,
)
```

Ebenso gilt: kein `debug=True` @www-starlette-dev-exceptions, keine Reload-Server (`fastapi dev`) in Produktion @fastapi-tiangolo-com-fastapi-cli, keine Testkonten oder Standardpasswörter, und Fehlermeldungen des Frameworks nicht an Clients durchreichen @api-security-owasp-org-editions-2023-en-0xa8-security-misconfiguration @cheatsheetseries-owasp-org-cheatsheets-rest-security-cheat-sheet-html. Forwarded-Header werden ausschließlich von den explizit konfigurierten Proxy-Netzen akzeptiert @fastapi-tiangolo-com-advanced-behind-a-proxy @uvicorn-dev-settings; die Anwendung darf nicht gleichzeitig direkt aus dem Internet erreichbar sein.

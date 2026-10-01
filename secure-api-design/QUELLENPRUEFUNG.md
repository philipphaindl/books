# Quellenprüfung: inhaltliche Änderungen am Text (Stand 2026-10-01)

Beim Einarbeiten der Literaturverweise wurden die Aussagen gegen die Quellen geprüft. Hier stehen alle Stellen, an denen der Text geändert wurde, sowie Aussagen ohne Beleg oder mit nur teilweiser Deckung. Diese Datei gehört nicht zum Buch und kann nach der Durchsicht gelöscht werden.

---

# Abschnitt kap00-kap03

## Notizen Fork A (kap00, kap01, kap02, kap03)

## (a) Inhaltliche Textänderungen

1. kap02-oidc.typ, Absatz zu Audience/Token Exchange (Ende des Abschnitts "Access-Token, ID-Token, Refresh-Token")
   - vorher: "... Authentik 2026.8 kann über _Token Exchange_ (RFC 8693) ein Token für diesen Ziel-Provider ausstellen. On-behalf-of-Delegation ist seit 2026.8 verfügbar und muss ausdrücklich aktiviert und auf vertrauenswürdige Provider begrenzt werden."
   - nachher: "... ausstellen @rfc8693 @docs-...-token-exchange. Token Exchange muss ausdrücklich als Grant Type aktiviert und auf vertrauenswürdige Provider begrenzt werden; die On-behalf-of-Delegation gibt es seit 2026.8, und sie ist mit diesem Grant Type automatisch verfügbar @docs-...-token-exchange."
   - Grund: Die Authentik-Doku (Token exchange) sagt: "OBO does not require a separate provider setting. Enabling the Token exchange grant also enables delegation." und "authentik: 2026.8.0+" für Delegation. Das Aktivieren/Begrenzen betrifft also den Grant Type Token Exchange (Trust über Federated OAuth2/OpenID Providers bzw. Sources), nicht eine eigene OBO-Einstellung.

Sonst keine inhaltlichen Änderungen; alle übrigen Änderungen sind reine @key-Einfügungen.

## (b) Unbelegte Aussagen (bewusst nicht belegt)

- kap00: "viele Angriffe auf Webanwendungen treffen genau diese Schnittstelle" (keine belastbare Primärquelle gefunden).
- kap00/kap01: Leitmotiv, Vertrauensgrenzen-Absätze, Tabelle "Grundprinzipien" (eigene Buchempfehlungen / Designprinzipien).
- kap01: Satz "Die meisten API-Lücken sind keine technischen Schwachstellen im engeren Sinn ... Kein Scanner und keine Firewall findet sie zuverlässig" (eigene Einschätzung, nicht eindeutig durch OWASP-Seiten gedeckt).
- kap02: "Zwei-Faktor-Authentifizierung erzwingt" (Allgemeinaussage über IdPs); Zeile "Application -> Policy Bindings"; Zeile "Scopes" (eigene Empfehlung); "Access token validity ... etwa `minutes=5`" (die Authentik-Doku nennt nur das Format hours=1;minutes=2;seconds=3, keinen Standard/Empfehlungswert; der Wert ist Buchempfehlung).
- kap02: Hinweis "Authentik 2026.8 ... Provider (Typ _OAuth2/OpenID Provider_) + Application" (Slug, Provider/Application-Paar): im Grundsatz durch Authentik-Doku "Create an OAuth2 provider" gedeckt, aber nicht zitiert.
- kap03: Betriebsvariante 3 (`token_use=access` als lokaler Claim) und der Code in app/auth.py sind eigenes Design; Betriebsvariante 2 "Opaque Token": Ob Authentik opake Access-Tokens ausstellt, ist in der Doku nicht belegt (nur Introspection für eigene Tokens eines vertraulichen Providers).
- kap03: "fail closed"-Verhalten, 401/403-Logik, FastAPI-Router-Abhängigkeit schützt neue Endpunkte (nur die Cache-Aussage ist belegt).
- kap03: "Ein bewegliches Scope-Mapping `token_use` darf nicht ins ID-Token übernommen werden" (eigene Anweisung).

## (c) Quelle trägt nur teilweise

- kap02, "Gruppen landen über das Standard-Mapping des Scopes `profile` im Claim `groups`": Doku sagt nur, `profile` enthalte "group membership"; der Claim-Name `groups` steht dort nicht.
- kap02, "`aud` ... typischerweise die Client-ID des Providers": belegt nur durch GitHub-Issue #22070 (Aussage eines Contributors: "authentik signs the same payload for both the access token and the ID token (aud = client_id, no typ header)") und Issue #14545, nicht durch offizielle Doku. Dasselbe Issue stützt auch die Aussage in kap03, Authentik erzeuge noch keine RFC-9068-Tokens (Issue ist am 2026-10-01 noch offen).
- kap02, Redirect URIs: Authentik erlaubt laut Doku regulären Ausdrücke ("advanced use cases"); die Empfehlung "exakt" stützt sich auf RFC 9700 (Abschn. 2.1, exact string matching). Die UI-Bezeichnung "strict" bestätigt nur das API-Schema (MatchingModeEnum: strict, regex).
- kap02, Tabelle "Access token validity ... Kurze Laufzeiten begrenzen den Schaden": RFC 9700 4.14 erwähnt Access-Tokens "with a short lifetime" als Vorteil von Refresh-Tokens; ausdrückliche Empfehlung "kurz" ist indirekt.
- kap03, "Opaque Token beziehungsweise Introspection ... erleichtert Widerruf, kostet aber Verfügbarkeit und Latenz": RFC 7662 stützt Introspection und das Cache-Aktualitäts-Tradeoff, nicht explizit Verfügbarkeit/Latenz.
- kap03, `cache_keys=True` "würde Schlüssel zusätzlich ohne Zeitablauf per LRU cachen": PyJWT-API-Doku: "cache_keys: Enable per-key LRU caching", Default False, max_cached_keys=16; "ohne Zeitablauf" ist Schlussfolgerung aus dem Fehlen eines TTL-Parameters dafür.
- kap03, "Abkühlzeit gegen Missbrauch": PyJWT: `cooldown_duration` (30 s) "Minimum seconds between forced refreshes"; "gegen Missbrauch" ist Interpretation. Aktualisierung bei unbekannter kid belegt in "Usage Examples".
- kap03, Tabellenzeile "Claim-Formate": keine direkte Quelle (RFC 8725 3.10 behandelt nur kid/jku-Injektion).

## Weitere Beobachtungen

- Die Authentik-Doku-Seiten tragen für 2026.8 im Versionsmenü noch "Pre-release"; der Blog vom 2026-09-01 ("authentik version 2026.8 is here!") bestätigt die Veröffentlichung.
- RFC 10017 ist als "August 2026", BCP 212 bestätigt (Text rfc10017.txt: Parecki, De Ryck, Waite). RFC 9745 (Deprecation) liegt in Kapitel 10 (Fork D), nicht von mir geprüft.
- Typst rendert `serial-number: RFC 6749` im IEEE-Stil als "RFC6749" (ohne Leerzeichen). Rein kosmetisch, ggf. beim Zusammenführen einheitlich lösen.
- OWASP-Seite API1: Die Abruf-Zusammenfassung lieferte "Comparing the user ID of the current session ... isn't a sufficient solution"; wer in kap04 darauf zitiert, sollte den Wortlaut gegenprüfen (Fork B).

---

# Abschnitt kap04-kap06

## Notizen Fork B (kap04, kap05, kap06), Stand 2026-10-01

41 Quellen (`lit-B.yml`), alle abgerufen und gegen die Aussage geprüft; Testkompilierung der drei Kapitel mit `ieee`-Stil ohne Fehler.

## (a) Inhaltliche Textänderungen

1. kap06-ressourcen.typ, Abschnitt Rate Limiting
   - vorher: "antwortet die API mit `429 Too Many Requests` und dem Header `Retry-After`."
   - nachher: "antwortet die API mit `429 Too Many Requests` und kann im Header `Retry-After` angeben, wann ein neuer Versuch sinnvoll ist." Dazu Satz: "Damit sie `Retry-After` mitschickt, wird der Limiter mit `headers_enabled=True` angelegt."
   - Code `app/limits.py`: `Limiter(..., default_limits=["300/minute"], headers_enabled=True)` (vorher ohne `headers_enabled`).
   - Grund: RFC 6585 §4: `Retry-After` ist ein MAY. slowapi 0.1.10 (Quellcode `Limiter._inject_headers`) schreibt `Retry-After` und die X-RateLimit-Header nur bei `headers_enabled=True` (Standard `False`); ohne den Parameter sendete der Beispiel-Limiter keinen `Retry-After`. Die slowapi-Doku nennt dabei nur die `X-RateLimit`-Header, `Retry-After` ist per Quellcode verifiziert. Keys: rfc6585, rfc9110, slowapi-readthedocs-io-en-latest-api.

2. kap06-ressourcen.typ, Achtung-Kasten zu `FORWARDED_ALLOW_IPS`
   - vorher: "... nur von Adressen, die in `FORWARDED_ALLOW_IPS` stehen."
   - nachher: "... stehen (Standard: nur `127.0.0.1` und `::1`)."
   - Grund: Uvicorn-Doku: Ohne `$FORWARDED_ALLOW_IPS` werden `127.0.0.1` und `::1` vertraut. Keys: uvicorn-dev-settings, fastapi-tiangolo-com-advanced-behind-a-proxy.

3. kap06-ressourcen.typ, Abschnitt Rate Limiting, Authentik
   - vorher: "Für Anmelde- und Registrierungsabläufe übernimmt Authentik das Begrenzen von Fehlversuchen selbst."
   - nachher: "Fehlversuche bei der Anmeldung bewertet Authentik selbst: Eine Reputation-Policy zählt sie pro IP-Adresse oder Benutzername und kann bei geringem Vertrauen zusätzliche Prüfungen wie ein CAPTCHA verlangen, sie muss dazu aber in den Anmelde-Flows eingerichtet werden."
   - Grund: Authentik-Doku zur Reputation-Policy: Policy muss angelegt und an Stages gebunden werden, sie löst zusätzliche Prüfungen aus, sperrt nicht hart; zu Registrierungsabläufen steht nichts. Key: docs-goauthentik-io-customize-policies-types-reputation.

4. kap06-ressourcen.typ, Idempotenz
   - Zusatz: "(ein Entwurf der IETF, kein verabschiedeter Standard)" hinter `Idempotency-Key`; Satz am Ende des Abschnitts: "Nach dem Entwurf antwortet der Server auf einen Schlüssel, der mit anderer Nutzlast wiederverwendet wird, mit 422 und auf eine noch laufende Anfrage mit 409."
   - Code `app/idempotenz.py`: `HTTPException(409, "Schlüssel gehört zu einer anderen Anfrage")` -> `HTTPException(422, ...)`; der 409 für "Anfrage wird bereits verarbeitet" bleibt.
   - Grund: draft-ietf-httpapi-idempotency-key-header-07 (15.10.2025; laut Datatracker am 18.04.2026 abgelaufen, kein RFC): 422 bei Wiederverwendung mit anderer Nutzlast, 409 bei noch laufender Anfrage. Der Header ist kein RFC. Key: datatracker-ietf-org-doc-draft-ietf-httpapi-idempotency-key-header.

5. kap04-autorisierung.typ, Punkt "404 statt 403" (Ergänzung, keine Korrektur)
   - Zusatz: "HTTP erlaubt es ausdrücklich, die Existenz eines Objekts mit 404 zu verbergen." Quelle: RFC 9110 §15.5.4. Key: rfc9110.

## (b) Aussagen ohne Beleg (bewusst nicht künstlich belegt, meist eigene Empfehlungen)

kap04
- Einleitungsdefinition "Authentifizierung beantwortet 'Wer bist du?', Autorisierung 'Darfst du das?'".
- "Ein 403 ... hilft beim Ausspähen, etwa von E-Mail-Adressen oder Kundennummern" (eigene Begründung; RFC belegt nur die Möglichkeit, mit 404 zu verbergen).
- "Besonders leicht vergessen werden Massenoperationen und Suchendpunkte".
- Rechtetests: Zwei-Benutzer-Test findet "fast alle" Fehler; "405 wäre kein Erfolg"; exakter Fremdbenutzer-Test als Definition of Done; Mandanten-ID in jede Abfrage; "Der Aufwand (RLS) lohnt sich bei mandantenfähigen Anwendungen".

kap05
- "Beides lässt sich ... fast vollständig ausschließen"; Rollen-spezifische Ausgabemodelle statt dynamischem Ausblenden.
- Tabellenzeile `Literal[...]`/`Enum` und `UUID` in der Pydantic-Tabelle (nicht abgerufen; `EmailStr`/`HttpUrl` sind belegt).
- Uploads: "Quarantäne"-Konzept, "eigene Download-Domain ohne Cookies" (Cheat Sheet empfiehlt nur anderen Server/außerhalb Webroot), Archiv-Grenzen "Verschachtelung".
- Hinweis: Das Beispiel "500-MB-Textfeld / Liste mit einer Million Einträgen" ist illustrativ.

kap06
- "Ein zweites, grobes Limit am Reverse Proxy fängt Lastspitzen ab".
- Timeouts für ausgehende HTTP-Aufrufe (belegt ist nur `statement_timeout`).
- Gegenmaßnahmen gegen Missbrauch: Limits pro Konto und Zeitraum (drei Einladungen/Minute), Verzögerung nach Fehlversuchen, E-Mail-Bestätigung/zweiter Faktor (API6 nennt Geräte-Fingerprinting, CAPTCHA, Verhaltensanalyse, Tor-/Proxy-Sperren, Absicherung maschinennaher APIs).
- Idempotenz-Details: SHA-256-Fingerabdruck, Speicherung von Header/Body, Aufbewahrungsfrist, `SELECT ... FOR UPDATE`; "ein vorheriges SELECT mit anschließendem INSERT würde das nicht leisten" (Race-Condition-Argument, nicht wörtlich belegt).
- Cache-Aussage "Zähler bei mehreren API-Instanzen in Redis": slowapi-Doku nennt Redis als unterstützten Backend, die `storage_uri="redis://..."`-Syntax stammt aus der `limits`-Bibliothek (nicht abgerufen).

## (c) Quelle trägt nur teilweise

- kap04 Merke-Kasten: "Anwendungs-DB-Account darf die Policy weder umgehen noch Tabellen besitzen": PostgreSQL: Superuser und `BYPASSRLS` umgehen RLS immer, Tabellenbesitzer normalerweise, außer `ALTER TABLE ... FORCE ROW LEVEL SECURITY`. "Transaktionslokal" = `SET LOCAL`/`set_config(..., true)` (belegt über sql-set).
- kap04 "Autorisierung zentralisieren": Authorization Cheat Sheet belegt nur "application-wide mechanisms/middleware" und Server-seitige Prüfung bei jeder Anfrage, nicht das Muster einer zentralen Basisabfrage.
- kap04 UUIDs: API1 empfiehlt zufällige GUIDs als zusätzliche Maßnahme, nicht als Ersatz; IDOR Cheat Sheet: Zugriffskontrolle bleibt nötig, wenn Angreifer URLs erhalten. "Referer/Logs" als Wege sind eigene Ergänzung.
- kap05 Dateinamen: MDN Content-Disposition (Pfadanteile entfernen, Sonderzeichen vermeiden) belegt "sicher kodierter Dateiname" nur sinngemäß; "Header-Rohwert" ist nicht belegt.
- kap05 Aktive Inhalte: MDN SVG `<script>` belegt, dass SVG Skripte enthalten kann (kein Sicherheitshinweis auf der Seite); für PDF/Office belegt das File Upload Cheat Sheet nur CDR (Content Disarm & Reconstruct); HTML-Aktivinhalt nicht eigens belegt.
- kap05 Signierte URLs: AWS-Doku zeigt zeitlich begrenzte Zugriffs-URLs (S3 als Beispiel); "kurzlebig" ist Empfehlung des Buchs.
- kap05/kap06 OWASP API4: nennt Größenlimits, Rate Limiting, Limits für Anzahl der Datensätze, Container/Serverless-Limits; Timeouts erwähnt die abgerufene Zusammenfassung nicht.
- kap06 PostgreSQL `statement_timeout`: Doku rät davon ab, ihn global in `postgresql.conf` zu setzen (besser pro Rolle/Sitzung); der Text sagt nur "Timeouts".
- kap06 ON CONFLICT: PostgreSQL garantiert Atomarität ausdrücklich für `DO UPDATE`; für `DO NOTHING` ergibt sich das Verhalten bei Gleichzeitigkeit aus den Unique-Index-Prüfungen (zweiter Einfüger wartet auf Ende der ersten Transaktion; Section 63.5).

## Hinweise zur Zusammenführung (für den Haupt-Agenten)

- Schlüssel ohne `www.` (wie in den Schwesterbüchern, z.B. `postgresql-org-docs-current-...`).
- OWASP API Security leitet von `owasp.org/API-Security/...` auf `https://api-security.owasp.org/editions/2023/en/<slug>` um; ich verwende diese kanonische Adresse (ohne Schluss-`/`): `api-security-owasp-org-editions-2023-en-0xa1-...`.
- Pydantic-Doku liegt jetzt unter `https://pydantic.dev/docs/validation/latest/...` (docs.pydantic.dev leitet 301 dorthin): Schlüssel `pydantic-dev-docs-validation-latest-concepts-models` usw.
- Rendering-Eigenheit: Typst-IEEE gibt `serial-number: RFC 9110` als "RFC9110" aus (Leerzeichen entfernt, wie "SP800–190" in den Schwesterbüchern). `organization` wird bei Reports nicht gedruckt, daher in `lit-B.yml` `publisher` verwendet.
- Draft-Eintrag: Titel um "(Internet-Draft, abgelaufen)" ergänzt, weil `note` im IEEE-Stil nicht gedruckt wird.

---

# Abschnitt kap07-kap09

## Notizen Fork C (kap07, kap08, kap09)

## (a) Inhaltliche Textänderungen
Keine. Es wurden ausschließlich `@key`-Zitate eingefügt; kein Satz wurde umformuliert.

## (b) Unbelegte Aussagen (keine Quelle gefunden oder bewusst eigene Empfehlung)
- kap07: "Logs werden strukturiert (JSON) mit UTC-Zeit geschrieben" (OWASP Logging nennt nur "internationales Format", nicht JSON/UTC).
- kap07: Request-ID-Muster (12 Zeichen UUID-Hex, Header `X-Request-ID`): eigene Konstruktion.
- kap07: "Datensparsamkeit ist die wirksamste Datenschutzmaßnahme": Wertung; DSGVO Art. 5 belegt nur das Prinzip der Datenminimierung. "Pseudonyme IDs (sub) statt E-Mail": eigene Empfehlung.
- kap08: "Ob die Strecke Proxy-API TLS braucht, folgt aus der Vertrauensgrenze" (Absatz zu TLS/mTLS im Backend): eigene Abwägung, nicht belegt.
- kap08: "Header am Proxy gelten für alle Antworten, auch Fehlerseiten, die die Anwendung nie erreichen": Caddy-Doku sagt dazu nichts Explizites.
- kap08: "CORS ist kein CSRF-Schutz": in den abgerufenen Quellen nicht wörtlich enthalten.
- kap08: "Dokumentation abschalten ist keine Sicherheitsgrenze", "keine Testkonten oder Standardpasswörter": eigene Empfehlungen.
- kap09: Der Beispielcode (Allowlist-/IP-Prüfung, HMAC-Schema mit Ereignis-ID.Zeit.Body, Key-ID zur Rotation) ist eigene Konstruktion; Stripe/GitHub belegen nur die Einzelprinzipien (Zeitstempel+Toleranz, Roh-Body, Duplikaterkennung per ID).

## (c) Quelle trägt nur teilweise
- kap08 `allow_credentials=True` + "Zurückspiegeln des Origin": FastAPI-Doku/MDN belegen das Wildcard-Verbot bei Credentials; das Reflektieren des Origin als Fehlkonfiguration ist dort nicht ausdrücklich genannt (MDN: nur Hinweis auf `Vary: Origin` bei dynamischen Origins).
- kap08 `secrets_dir` "Dateiname = Name der Umgebungsvariable": pydantic-settings sagt "Dateiname ist der Schlüssel" (bei Präfix kommt `env_prefix`-Logik hinzu).
- kap08 "Fehlende Pflichtwerte verhindern den Start": pydantic-settings belegt ValidationError bei fehlenden Werten, nicht ausdrücklich "Start schlägt fehl".
- kap08 `FastAPI(docs_url=...)`: Doku belegt das Abschalten per `None`; "unbeabsichtigte Informationsfreigabe reduzieren" ist Wertung.
- kap07 `ferr` (FastAPI Handling Errors) belegt nur, dass sich die Standard-Handler überschreiben lassen und die Standardantwort Eingabewerte enthalten kann; die Wahl "nur Feldnamen" ist Buchentscheidung.
- kap09 `hx` (httpx QuickStart): "lädt den Body vollständig" ist nur indirekt belegt ("streaming responses that do not load the entire response body into memory at once").
- kap09 `retry`/`jit`: AWS-Prescriptive-Guidance belegt Backoff + Idempotenz, der AWS-Architecture-Blog Jitter. Der Builders'-Library-Artikel (Brooker) war per WebFetch nicht lesbar (Weiterleitung auf Inhalt ohne Text) und wurde daher nicht zitiert. "Obergrenze" für Retries ist nur durch das Beispiel in der Prescriptive-Guidance (MAX_RETRIES) gestützt.
- kap09 Webhooks: Das Stripe-Dokument wurde auf Deutsch ausgeliefert, Titel im Eintrag daher deutsch.
- GDPR-Quelle: gdpr-info.eu ist eine inoffizielle Wiedergabe; EUR-Lex war per WebFetch nicht lesbar. Bei Bedarf ersetzen durch https://eur-lex.europa.eu/eli/reg/2016/679/oj.

## Hinweise zur Schlüsselkonvention
- OWASP-API-Seiten sind permanent (308) auf api-security.owasp.org umgezogen. Schlüssel daher `api-security-owasp-org-editions-2023-en-0xa7-server-side-request-forgery` (ebenso 0xa8, 0xaa) statt `owasp-org-api-security-...`.
- Verwendete Schlüssel decken sich mit Schwesterbuch-Einträgen: `caddyserver-com-docs-automatic-https`, `fastapi-tiangolo-com-fastapi-cli`, `uvicorn-dev-settings`.
- RFCs mit Jahr statt Monat bei RFC 9457 (2023) und RFC 9110 (2022), weil das Monatsdatum nicht aus den abgerufenen Seiten hervorging.

---

# Abschnitt kap10-kap11

## Notizen Fork D (kap10-lebenszyklus, kap11-testen)

## (a) Inhaltliche Textänderungen
1. kap10, Absatz unter dem Versionierungs-Codeblock: Satz zum `Link`-Header mit `rel="successor-version"` ergänzt (nur, um RFC 5829 belegen zu können). Schlüssel: rfc5829.
2. kap10, OpenAPI-Absatz: Satz ergänzt "OWASP empfiehlt, die API-Dokumentation automatisiert in der CI-Pipeline zu erzeugen" (API9-Prävention). Schlüssel: api-security-owasp-org-...-0xa9-improper-inventory-management. Außerdem "OpenAPI-Diff-Werkzeug" -> "... wie oasdiff" (www-oasdiff-com).
3. kap11, Abschnitt Statische Analyse:
   - vorher: "`pip-audit` prüft den *aufgelösten, gesperrten* Abhängigkeitsstand; die CycloneDX-SBOM macht ihn ... nachvollziehbar."
   - nachher: "`pip-audit` prüft die *installierten* Pakete gegen Datenbanken bekannter Schwachstellen; nach `uv sync --locked` ist das der aufgelöste, gesperrte Stand. Die CycloneDX-SBOM entsteht aus den tatsächlich installierten Paketen und macht diesen Stand ... nachvollziehbar."
   - Grund: `pip-audit` ohne Argumente prüft die aktuelle Umgebung (Lockfile-Prüfung nur mit `--locked <Pfad>`); `cyclonedx-py environment` analysiert installierte Pakete. Keys: pypi-org-project-pip-audit, docs-astral-sh-uv-concepts-projects-sync, cyclonedx-bom-tool-readthedocs-io-en-latest-usage-html.
4. kap11, Fuzzing: "tausende Anfragen" -> "viele Anfragen" (keine Quelle für die Zahl); "Serverfehler (500)" -> "(5xx)" (Check not_a_server_error); "und fehlende Validierung" ergänzt um "(unzulässige Eingaben, die nicht abgelehnt werden)" (Check negative_data_rejection). Keys: schemathesis-readthedocs-io-en-stable, ...-reference-cli.
5. kap11, ZAP: "bekannte Angriffsmuster gegen alle Endpunkte ausprobiert" -> "gegen die gefundenen Endpunkte einen aktiven Scan ausführt" (ZAP-Doku: importiert die Definition und führt einen Active Scan gegen die gefundenen URLs aus). Key: www-zaproxy-org-docs-docker-api-scan.
6. kap11, ZAP-Digest: "beweglicher `latest`-ähnlicher Tag" -> "beweglicher Tag wie `stable`" plus Begründung (Tags mutable, Digest nicht). Key: docs-docker-com-build-building-best-practices.
7. kap11, Satz zu Aktives DAST: Begründung "weil ein aktiver Scan ein echter Angriff ist" ergänzt. Key: www-zaproxy-org-getting-started.
8. kap11, Tokenfälle: Satz ergänzt "Warum `alg=none` sowie Issuer und Audience dazugehören, beschreibt RFC 8725." Key: rfc8725.
9. kap11, CI-Absatz: Satz ergänzt "Nur ein vollständiger Commit-SHA bindet eine Action unveränderlich" (GitHub-Doku, setup-uv-README zeigt SHA-Pinning). Keys: docs-github-com-en-actions-reference-security-secure-use, github-com-astral-sh-setup-uv.

Geprüft ohne Korrektur: `Deprecation = "@1788220800"` = 2026-09-01 00:00:00 UTC (per Python nachgerechnet), Format `@<Sekunden>` entspricht RFC 9745 (Structured-Field-Date). `Sunset: Thu, 31 Dec 2026 23:59:59 GMT` ist korrekt als HTTP-Date (Donnerstag stimmt). RFC 9745 ist Proposed Standard, RFC 8594 Informational.

## (b) Unbelegte Aussagen
- kap10: "`APIRouter` besitzt keine Middleware-API" - keine Doku-Aussage gefunden; per Quellcode (fastapi 0.142.2, routing.py) bestätigt: APIRouter hat keinen `middleware`-Parameter. Im Text nicht zitiert.
- kap10: `git diff --stat` zeigt nur Zeilenzahlen (Git-Doku nicht abgerufen).
- kap10: Inhalt des Inventars (Owner, Kontakt, Datenklassifikation, ...) und Staging-Hinweise ("eigene Authentik-Provider pro Umgebung") sind Buchempfehlungen.
- kap11: "Ein 500er bei Schemathesis ist fast immer ein echter Fehler" - eigene Einschätzung.
- kap11: "ZAP findet vor allem Konfigurations- und Injection-Probleme" - nur teilweise gestützt (ZAP-Doku: API-Scan ist auf APIs abgestimmt, sucht z.B. kein XSS); nicht zitiert.
- kap11: Matrix-Test, Rechtetests, Ausnahmen mit Ticket/Ablaufdatum: Buchempfehlung.
- kap11: Alg-Liste "unbekannte kid, fehlende Claims, nbf" nicht einzeln belegt (RFC 8725 deckt nur none/iss/aud).

## (c) Nur teilweise tragende Quellen
- API9 stützt alte Versionen, Staging mit Produktionsdaten, Inventar von Hosts/Umgebungen und CI-generierte Dokumentation; die konkrete Attributliste (Owner, Kontakt, Klassifikation ...) ist Buchempfehlung. "Nicht mehr benötigte Umgebungen abbauen" entspricht nur sinngemäß der "retirement strategy"-Aussage.
- GitHub-Secure-Use-Doku gilt GitHub Actions; das Gitea-Setup des Buchs (.gitea/workflows) folgt demselben Git-Ref-Prinzip, die Gitea-Doku wurde nicht ausgewertet.
- ZAP-/Docker-Seiten: Image `zaproxy/zap-stable` und `/zap/wrk` bestätigt; "Bericht liegt im aktuellen Verzeichnis" ist eine Folgerung aus dem Mount `$PWD:/zap/wrk`. Die Docker-Doku zeigt dafür `:rw`; ob Schreibrechte des Container-Benutzers im Host-Verzeichnis reichen, wurde nicht geprüft.
- Secrets-Management-Cheat-Sheet nennt Secret-Detection auf Entwickler-Ebene/pre-commit und shift-left in CI; kein Wort zu "Secret-Scanning in CI" wörtlich.
- RFC 8725 und RFC 9745: Monat im Eintrag weggelassen (nur Jahr), da nicht abgerufen; RFC 9745 laut Dokument 2025, RFC 8725 2020.
- Schlüssel der OWASP-API-Seiten nutzen die Zielhost-URL api-security.owasp.org (owasp.org/API-Security/... leitet per 308 dorthin weiter). Andere Forks sollten denselben Schlüssel nehmen.

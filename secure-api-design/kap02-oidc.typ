#import "lib.typ": *

= Authentifizierung mit OAuth 2.0, OIDC und Authentik

Selbst gebaute Anmeldungen mit Passwort-Tabellen, Sessions und Passwort-Reset sind eine der größten Fehlerquellen @api-security-owasp-org-editions-2023-en-0xa2-broken-authentication. Moderne APIs delegieren die Anmeldung an einen *Identity Provider* (IdP), der Benutzer verwaltet, Zwei-Faktor-Authentifizierung erzwingt und signierte Tokens ausstellt. Die API selbst prüft nur noch diese Tokens. In diesem Buch übernimmt *Authentik* diese Rolle, ein quelloffener IdP, der selbst gehostet wird @docs-goauthentik-io.

== Die Rollen

#table(columns: (auto, auto, 1fr),
  [Rolle (OAuth-Begriff) @rfc6749], [Im Beispiel], [Aufgabe],
  [Resource Owner], [Benutzerin], [besitzt die Daten und erteilt Zugriff],
  [Client], [Web-App, Hintergrunddienst], [möchte im Namen der Benutzerin oder im eigenen Namen auf die API zugreifen],
  [Authorization Server], [Authentik], [authentifiziert, fragt ggf. nach Zustimmung und stellt Tokens aus],
  [Resource Server], [`notizen`-API], [nimmt Tokens entgegen, prüft sie und liefert Daten],
)

*OAuth 2.0* regelt, wie ein Client ein Zugriffstoken für eine API bekommt (Autorisierung) @rfc6749. *OpenID Connect* (OIDC) setzt darauf auf und liefert zusätzlich Informationen darüber, wer sich angemeldet hat (Authentifizierung), unter anderem im _ID-Token_ @openid-net-specs-openid-connect-core-1-0-html.

== Der Authorization Code Flow mit PKCE

Für Web-, Mobile- und Desktop-Apps mit geeignetem Browser ist der _Authorization Code Flow_ mit _PKCE_ (`S256`) der empfohlene Ablauf @rfc9700 @rfc10017. Geräte mit eingeschränkter Eingabe und ohne geeigneten Browser verwenden den _Device Authorization Grant_ @rfc8628. Die früher verbreiteten Varianten _Implicit_ (Token direkt in der URL) und _Resource Owner Password_ (Client sammelt das Passwort ein) gelten als unsicher @rfc9700 und sollten in Authentik gar nicht erst aktiviert werden @docs-goauthentik-io-add-secure-apps-providers-oauth2.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let spalten = ((0, [Browser / Client], c-grey), (5.2, [Authentik], c-violet), (10.4, [`notizen`-API], c-blue))
    for (x, t, c) in spalten {
      kasten((x, 0), t, w: 2.6, h: 0.7, bg: c.lighten(88%), col: c, size: 7.5pt)
      line((x, -0.4), (x, -5.3), stroke: (paint: c.lighten(40%), thickness: 0.7pt, dash: "dashed"))
    }
    let msg(y, a, b, t, col: c-dark) = {
      line((a, y), (b, y), stroke: (paint: col, thickness: 0.9pt), mark: (end: "stealth", fill: col, scale: 0.55))
      content(((a + b) / 2, y + 0.2), text(size: 6.8pt, t))
    }
    msg(-0.9, 0, 5.2, [1 Weiterleitung mit `code_challenge`])
    content((6.9, -1.6), text(size: 6.8pt)[2 Anmeldung + 2FA])
    msg(-2.3, 5.2, 0, [3 Rückleitung mit einmaligem `code`])
    msg(-3.0, 0, 5.2, [4 `code` + `code_verifier` tauschen])
    msg(-3.7, 5.2, 0, [5 Access-Token (+ Refresh, ID-Token)])
    msg(-4.5, 0, 10.4, [6 `Authorization: Bearer <Access-Token>`], col: c-blue)
    msg(-5.1, 10.4, 0, [7 Daten], col: c-blue)
  }),
  caption: [Authorization Code Flow mit PKCE. Das Token geht nie über die Adressleiste des Browsers.],
)

PKCE (_Proof Key for Code Exchange_) schützt davor, dass jemand den einmaligen Code aus Schritt 3 abfängt und selbst eintauscht: Der Client erzeugt vor Schritt 1 ein zufälliges Geheimnis (`code_verifier`), schickt nur dessen Hash mit (`code_challenge`) und beweist beim Eintausch in Schritt 4, dass er das Original kennt @rfc7636.

#tipp[Für Browser-Anwendungen beschreibt RFC 10017 (August 2026) das _Backend for Frontend_ (BFF) als stärkstes der drei Muster @rfc10017: Ein serverseitiger Teil führt den Flow aus und hält die Tokens, der Browser bekommt nur ein `Secure`- und `HttpOnly`-Session-Cookie. Das reduziert Token-Diebstahl durch JavaScript; gegen CSRF braucht das BFF zusätzlich einen eigenen Schutz (Kapitel 8) @rfc10017.]

== Maschine zu Maschine: Client Credentials

Ein Hintergrunddienst ohne Benutzer (etwa ein nächtlicher Export) meldet sich mit eigenen Zugangsdaten an und bekommt ein Token in eigenem Namen. Das ist der _Client Credentials Grant_ @rfc6749. In Authentik läuft dieser Weg über ein eigenes Dienstkonto mit App-Passwort oder über föderierte Tokens, die Details beschreibt die Authentik-Dokumentation unter _Machine-to-Machine (M2M) authentication_ @docs-goauthentik-io-add-secure-apps-providers-oauth2-machine-to-machine. Wichtig für die API: Solche Tokens haben kein menschliches Subjekt und sollten nur genau die Rechte bekommen, die der Dienst braucht.

== Authentik einrichten

In Authentik gehören zu jeder Anwendung zwei Objekte: ein *Provider* (Typ _OAuth2/OpenID Provider_) mit den technischen Einstellungen und eine *Application*, die den Provider mit einem Namen (_Slug_) und Zugriffsregeln verbindet. Für die Web-App der Notizen:

#table(columns: (auto, 1fr),
  [Einstellung], [Empfehlung],
  [Client type], [_Confidential_ für serverseitige Clients (BFF, Dienste), _Public_ für reine Mobile- oder Desktop-Apps, die kein Geheimnis sicher speichern können @rfc6749 @docs-goauthentik-io-add-secure-apps-providers-oauth2],
  [Redirect URIs], [exakte, vollständige Adressen (_strict_), keine regulären Ausdrücke mit Platzhaltern @rfc9700],
  [Signing Key], [*ein Zertifikat auswählen* (z.B. das mitgelieferte selbstsignierte). Ohne Auswahl signiert Authentik mit dem Client-Secret per HS256, dann kann die API die Tokens nicht über öffentliche Schlüssel prüfen @docs-goauthentik-io-add-secure-apps-providers-oauth2.],
  [Access token validity], [kurz, etwa `minutes=5`. Kurze Laufzeiten begrenzen den Schaden gestohlener Tokens @rfc9700.],
  [Refresh tokens], [nur für Clients, die sie brauchen, mit begrenzter Laufzeit und Rotation @rfc9700. Seit Authentik 2024.2 muss der Client `offline_access` anfordern und das Mapping im Provider aktiviert sein @docs-goauthentik-io-releases-2024-2 @docs-goauthentik-io-add-secure-apps-providers-oauth2.],
  [Scopes], [nur benötigte Scope-Mappings, etwa `openid`, `profile`, `email` und eigene wie `notizen:lesen`],
  [Application -> Policy Bindings], [festlegen, welche Gruppen sich überhaupt an dieser Anwendung anmelden dürfen],
)

Die Tabelle gilt für den voreingestellten und empfohlenen *Issuer mode pro Provider* @docs-goauthentik-io-add-secure-apps-providers-oauth2. Beim globalen Issuer lautet `iss` nur `https://auth.example.com/`, während Discovery und JWKS weiterhin unter dem Application-Slug liegen @docs-goauthentik-io-add-secure-apps-providers-oauth2. Die Anwendung übernimmt `issuer` und `jwks_uri` deshalb aus dem Discovery-Dokument oder aus expliziter Konfiguration und setzt Adressen nicht durch String-Verkettung zusammen.

Die für die API wichtigen Adressen leiten sich aus dem Slug der Application ab (hier `notizen`). Der _Issuer_ endet mit einem Schrägstrich, der genau so im Token steht und genau so geprüft werden muss:

#table(columns: (auto, 1fr),
  [Zweck], [Adresse @docs-goauthentik-io-add-secure-apps-providers-oauth2],
  [Issuer (`iss`)], [`https://auth.example.com/application/o/notizen/`],
  [Discovery], [`https://auth.example.com/application/o/notizen/.well-known/openid-configuration`],
  [Öffentliche Schlüssel (JWKS)], [`https://auth.example.com/application/o/notizen/jwks/`],
  [Token-Endpunkt], [`https://auth.example.com/application/o/token/`],
)

== Access-Token, ID-Token, Refresh-Token

#table(columns: (auto, 1fr, 1fr),
  [Token], [Zweck], [Empfänger],
  [*Access-Token*], [berechtigt zum Zugriff auf die API], [die API (Resource Server) @rfc6749],
  [*ID-Token*], [sagt dem Client, wer sich angemeldet hat @openid-net-specs-openid-connect-core-1-0-html], [nur der Client, *nie* die API],
  [*Refresh-Token*], [holt neue Access-Tokens ohne erneute Anmeldung], [nur der Authorization Server @rfc6749],
)

#achtung[Eine API darf ausschließlich Access-Tokens akzeptieren. Ein ID-Token ist für den Client bestimmt und beweist nichts über Zugriffsrechte. Signatur, Issuer und Audience allein unterscheiden beide Token-Arten nicht immer sicher; Kapitel 3 erklärt den aktuellen Authentik-Grenzfall.]

Authentik stellt Access-Tokens als signierte JSON Web Tokens (JWT) aus @docs-goauthentik-io-add-secure-apps-providers-oauth2. Ein JWT besteht aus drei Base64-kodierten Teilen, getrennt durch Punkte: Kopf (Algorithmus und Schlüssel-ID `kid`), Nutzlast (Claims) und Signatur @rfc7519. Die Nutzlast ist *nur kodiert, nicht verschlüsselt*: Jeder, der das Token hat, kann sie lesen. Deshalb gehören keine Geheimnisse in Tokens @rfc7519.

#datei("Nutzlast eines Access-Tokens (gekürzt)")[
```json
{
  "iss": "https://auth.example.com/application/o/notizen/",
  "sub": "3f7c2e1a9b...",
  "aud": "ZkP8x4Qm...",
  "exp": 1790253000,
  "iat": 1790252700,
  "scope": "openid profile notizen:lesen notizen:schreiben",
  "groups": ["notizen-admins"]
}
```
]

Welche Claims genau enthalten sind, bestimmen die Scope-Mappings des Providers. Gruppen landen über das Standard-Mapping des Scopes `profile` im Claim `groups` @docs-goauthentik-io-add-secure-apps-providers-oauth2. `aud` (_audience_) ist bei Authentik typischerweise die Client-ID des Providers @github-com-goauthentik-authentik-issues-22070. Für eine belastbare Trennung erhält die API einen eigenen Provider beziehungsweise eine eigene Audience; Authentik 2026.8 kann über _Token Exchange_ (RFC 8693) ein Token für diesen Ziel-Provider ausstellen @rfc8693 @docs-goauthentik-io-add-secure-apps-providers-oauth2-token-exchange. Token Exchange muss ausdrücklich als Grant Type aktiviert und auf vertrauenswürdige Provider begrenzt werden; die On-behalf-of-Delegation gibt es seit 2026.8, und sie ist mit diesem Grant Type automatisch verfügbar @docs-goauthentik-io-add-secure-apps-providers-oauth2-token-exchange.

#import "lib.typ": *

= Glossar

#let begriffe = (
  ([Access-Token], [Token, das zum Zugriff auf eine API berechtigt. Die einzige Token-Art, die eine API annehmen darf.]),
  ([Audience (`aud`)], [Claim, der angibt, für welchen Empfänger ein Token bestimmt ist.]),
  ([Authentik], [Quelloffener, selbst gehosteter Identity Provider mit OAuth 2.0, OIDC und SAML.]),
  ([BFF], [Backend for Frontend: serverseitiger Teil einer Web-App, der Tokens hält, statt sie dem Browser zu geben.]),
  ([BOLA], [Broken Object Level Authorization: Zugriff auf fremde Objekte über deren ID.]),
  ([Claim], [Einzelne Angabe in einem JWT, z.B. `sub` oder `exp`.]),
  ([Client Credentials], [OAuth-Ablauf, bei dem sich ein Dienst ohne Benutzer mit eigenen Zugangsdaten ein Token holt.]),
  ([CORS], [Browser-Regel, welche fremden Webseiten per JavaScript auf eine API zugreifen dürfen.]),
  ([CSRF], [Cross-Site Request Forgery: eine fremde Seite löst mit automatisch mitgesendeten Cookies eine Aktion aus.]),
  ([DPoP], [Proof-of-Possession-Verfahren nach RFC 9449, das ein Access-Token an einen Client-Schlüssel bindet.]),
  ([ID-Token], [OIDC-Token für den Client mit Angaben zur Anmeldung, nicht für APIs.]),
  ([Idempotenz], [Eigenschaft einer Operation, bei Wiederholung dasselbe Ergebnis zu liefern, ohne doppelte Wirkung.]),
  ([Issuer (`iss`)], [Claim mit der Adresse des Ausstellers eines Tokens.]),
  ([JWKS], [JSON Web Key Set: veröffentlichte öffentliche Schlüssel eines Identity Providers.]),
  ([JWT], [JSON Web Token: signiertes, Base64-kodiertes Token aus Kopf, Nutzlast und Signatur.]),
  ([Mass Assignment], [Übernahme nicht vorgesehener Felder aus einer Anfrage in ein Objekt.]),
  ([mTLS], [Gegenseitiges TLS; kann nach RFC 8705 auch Access-Tokens an ein Client-Zertifikat binden.]),
  ([OIDC], [OpenID Connect: Anmeldeschicht auf OAuth 2.0.]),
  ([PKCE], [Proof Key for Code Exchange: schützt den Authorization Code gegen Abfangen.]),
  ([Problem Details], [Einheitliches Fehlerformat für HTTP-APIs nach RFC 9457.]),
  ([Rate Limiting], [Begrenzung der Anfragen pro Zeitfenster und Aufrufer.]),
  ([Refresh-Token], [Langlebigeres Token, mit dem ein Client neue Access-Tokens holt.]),
  ([Resource Server], [Die API, die Access-Tokens prüft und Daten liefert.]),
  ([Scope], [Benannte Berechtigung, die ein Token enthält, z.B. `notizen:lesen`.]),
  ([SSRF], [Server Side Request Forgery: die API ruft vom Angreifer gewählte Adressen auf.]),
)

#set text(size: 8.2pt)
#columns(2, gutter: 16pt)[
  #for (b, d) in begriffe [
    #block(below: 0.5em, breakable: false)[*#b* \ #d]
  ]
]

#v(0.4em)
#set text(size: 9pt)
Quellen und weiterführende Literatur zu den Begriffen, Standards und Werkzeugen dieses Handbuchs stehen im anschließenden Literaturverzeichnis.

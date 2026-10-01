#import "lib.typ": *

= Sicherheit beim Arbeiten mit Agenten

Ein Coding-Agent führt Befehle mit den Rechten dessen aus, der ihn gestartet hat. Er liest Dateien, Webseiten und Ausgaben von Werkzeugen und handelt danach. Das macht ihn nützlich und zugleich zu einem Angriffsziel: Wer beeinflussen kann, was der Agent liest, kann unter Umständen beeinflussen, was er tut @greshake.

== Das Bedrohungsmodell

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let q(y, t) = kasten((0, y), t, w: 3.4, h: 0.62, bg: rgb("#FBEAEA"), col: c-red, size: 6.8pt)
    q(1.4, [Repo-Inhalte fremder Herkunft])
    q(0.6, [Issues, Webseiten, Doku])
    q(-0.2, [Ausgaben von MCP-Servern])
    q(-1.0, [Abhängigkeiten, Testdaten])
    kasten((5.6, 0.2), [*Agent* \ #text(size: 6.3pt)[mit deinen Rechten]], w: 2.4, h: 1.2, bg: rgb("#FDF1EC"), col: c-accent, size: 7.5pt)
    let z(y, t) = kasten((11.2, y), t, w: 3.4, h: 0.62, bg: luma(245), col: c-grey, size: 6.8pt)
    z(1.4, [Dateien lesen: Secrets, SSH-Schlüssel])
    z(0.6, [Befehle ausführen])
    z(-0.2, [Netzwerk: Daten hinausschicken])
    z(-1.0, [Git: Push, Credentials])
    for y in (1.4, 0.6, -0.2, -1.0) { pfeil((1.75, y), (4.35, 0.2 + (y - 0.2) * 0.3), color: c-red) }
    for y in (1.4, 0.6, -0.2, -1.0) { pfeil((6.85, 0.2 + (y - 0.2) * 0.3), (9.45, y)) }
    rect((8.0, -1.5), (8.5, 1.9), fill: c-gitea.lighten(80%), stroke: (paint: c-gitea, thickness: 0.8pt))
    content((8.25, 0.2), text(size: 6.3pt, fill: c-gitea.darken(20%))[#std.rotate(-90deg, reflow: true)[Sandbox, Rechte]])
  }),
  caption: [Links, was der Agent liest und nicht kontrolliert wird. Rechts, was er tun kann. Dazwischen gehören die Leitplanken.],
)

Die gefährlichste Kombination beschreibt Simon Willison als _lethal trifecta_ @willison: Ein Agent hat *Zugriff auf private Daten*, liest *nicht vertrauenswürdige Inhalte* und kann *Daten nach außen schicken*. Sind alle drei gegeben, kann eine eingeschleuste Anweisung, etwa in einem Kommentar einer fremden Bibliothek oder in einer Webseite, den Agenten dazu bringen, Geheimnisse zu versenden. Das Ziel der Maßnahmen ist, mindestens eine der drei Bedingungen zu brechen.

Anthropic weist in der Sicherheitsdokumentation von Claude Code selbst darauf hin, dass Agenten durch Prompt Injection oder Modellfehler unbeabsichtigt handeln können, und empfiehlt mehrere Schutzschichten, statt sich auf eine zu verlassen @cc-security.

== Die Schutzschichten

#table(columns: (auto, 1fr, 1fr),
  [Schicht], [Claude Code @cc-security], [Codex @oa-approvals],
  [Sandbox], [`/sandbox`: Isolation von Dateisystem und Netzwerk auf Betriebssystemebene (am Mac über Seatbelt @cc-sandbox)], [Sandbox `workspace-write` bzw. `read-only`, Netzwerk standardmäßig aus],
  [Berechtigungen], [Manual-Modus fragt vor Änderungen und Befehlen, `permissions.deny` sperrt Dateien und Werkzeuge], [Freigabe-Richtlinie (`approval_policy`), Regeln und Profile],
  [Netzwerk], [`curl`, `wget` werden nicht automatisch freigegeben, Netzwerkzugriffe im Manual-Modus nur nach Rückfrage], [`network_access = false` in der Sandbox-Konfiguration],
  [Auto-Modus], [ein Klassifikator prüft Aktionen statt des Menschen; eigene Deny-Regeln gelten weiter], [automatisches Review von Aktionen (_Auto-review_)],
)

#datei(".claude/settings.json (Auszug, gehärtet)")[
```json
{
  "permissions": {
    "deny": [
      "Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)",
      "Read(~/.ssh/**)", "Read(~/.aws/**)",
      "Bash(curl:*)", "Bash(wget:*)", "Bash(git push:*)"
    ]
  }
}
```
]

#datei("~/.codex/config.toml (Auszug)")[
```toml
sandbox_mode = "workspace-write"
approval_policy = "on-request"

[sandbox_workspace_write]
network_access = false
```
]

#achtung[Deny-Regeln passen auf den Befehl, wie er geschrieben ist. Ein Agent, der statt `curl` ein Python-Skript mit `urllib` ausführt, umgeht eine Regel für `curl`. Verlässlichen Schutz gegen Datenabfluss bietet deshalb nur die Netzwerkisolation der Sandbox, nicht die Liste verbotener Befehle @cc-security.]

== Fremde Repositories

Projektdateien können Befehle auslösen: Hooks in `.claude/settings.json`, MCP-Server in `.mcp.json`, Anweisungen in `CLAUDE.md` und `AGENTS.md`. Eine 2025 bekannt gewordene Lücke in Claude Code (CVE-2025-59536) erlaubte, Code aus einem Projekt auszuführen, bevor der Vertrauensdialog beim ersten Start bestätigt war (behoben in Version 1.0.111) @cve-59536. Claude Code fragt beim ersten Öffnen eines Verzeichnisses nach Vertrauen, auch bei neuen MCP-Servern @cc-security. Für fremde Repositories (Abgaben von Studierenden, Open-Source-Projekte, Beispielcode) gilt deshalb:

+ Zuerst die agentenbezogenen Dateien selbst lesen: `.claude/`, `.codex/`, `.mcp.json`, `CLAUDE.md`, `AGENTS.md`, Git-Hooks.
+ Den Agenten zunächst nur lesend arbeiten lassen (Plan-Modus bzw. Sandbox `read-only`).
+ Dem Vertrauensdialog nur zustimmen, wenn diese Prüfung unauffällig war.
+ Für Analysen von Schadcode oder CTF-Material eine Wegwerfumgebung verwenden (Container oder VM ohne Zugangsdaten).

== Geheimnisse und Zugangsdaten

- *Keine Produktionszugänge in der Umgebung des Agenten.* Keine Deploy-Schlüssel, keine Cloud-Zugangsdaten mit Schreibrechten in der Shell, in der der Agent läuft.
- *Eigene, eingeschränkte Tokens*, etwa ein Gitea-Token nur mit Leserecht für das Repository, wenn der Agent überhaupt darauf zugreifen muss.
- *Push bleibt beim Menschen.* Der Agent committet in einen Branch, gepusht und gemergt wird nach dem Review. Geschützte Branches (Git-Handbuch, Kapitel 12 @buch-git) setzen das serverseitig durch.
- *Keine Geheimnisse in den Prompt kopieren.* Was im Kontext steht, kann in Logs, Zusammenfassungen und Commit-Nachrichten wieder auftauchen.

== MCP-Server und Abhängigkeiten

MCP-Server erweitern den Agenten um Werkzeuge, und ihre Ausgaben landen ungeprüft im Kontext. Anthropic rät, eigene Server zu schreiben oder solche von vertrauenswürdigen Anbietern zu nutzen, und prüft sie selbst nicht auf Sicherheit @cc-security. Nur Server aus vertrauenswürdiger Quelle einsetzen, Versionen festlegen, ihnen minimale Rechte geben und ihre Ausgaben als nicht vertrauenswürdig betrachten.

Ein eigenes Risiko sind erfundene Paketnamen: Ein Modell schlägt ein Paket vor, das es nicht gibt, und ein Angreifer hat genau diesen Namen vorsorglich mit Schadcode registriert (_Slopsquatting_ @claburn). Messungen an 16 Modellen fanden erfundene Paketnamen bei mindestens 5,2 Prozent der Vorschläge kommerzieller und 21,7 Prozent der Vorschläge offener Modelle @spracklen. Die Regel "keine neuen Pakete ohne Zustimmung" aus Kapitel 8 ist deshalb auch eine Sicherheitsregel. Vor der Zustimmung prüft man Name, Herkunft und Verbreitung des Pakets, danach läuft `pip-audit` in der CI.

== Unbeaufsichtigte Läufe

Goals und Auto-Modus sparen Rückfragen, entfernen aber den Menschen als letzte Kontrolle. Für solche Läufe gilt eine strengere Konfiguration:

#table(columns: (auto, 1fr),
  [], [Maßnahme],
  [☐], [Sandbox aktiv, Netzwerk nur zum Paketindex oder gar nicht],
  [☐], [eigener Worktree oder Container, keine Zugangsdaten in der Umgebung],
  [☐], [kein Push, kein Deployment, keine Datenbankzugriffe außerhalb der Testdatenbank],
  [☐], [Obergrenze an Turns bzw. Token-Budget],
  [☐], [Review des gesamten Diffs, bevor irgendetwas den Branch verlässt],
  [☐], [`bypassPermissions` bzw. vergleichbare Modi nur in Wegwerfumgebungen @cc-permissions],
)

#merke[Sicherheit mit Agenten folgt demselben Prinzip wie im Secure-API-Handbuch @buch-api: nichts, was von außen kommt, ist vertrauenswürdig, auch nicht Text, den der Agent liest. Die wirksamste Maßnahme ist, die Fähigkeiten des Agenten so zu begrenzen, dass eine erfolgreiche Manipulation keinen Schaden anrichten kann: kein Zugang zu Geheimnissen, kein freies Netzwerk, kein Push.]

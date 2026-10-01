#import "lib.typ": *

= Die Modelle im Überblick

Beide Hersteller bieten eine Staffelung von Modellen: sehr fähig und teuer, ausgewogen, schnell und günstig. Dieses Kapitel ordnet die Ende September 2026 aktuellen Modelle ein @an-models @oa-models. Die Namen ändern sich, die Staffelung bleibt.

== Anthropic: Claude

#table(columns: (auto, auto, 1fr),
  [Modell], [Alias in Claude Code], [Einordnung],
  [*Claude Fable 5.1*], [`fable`], [Das fähigste allgemein verfügbare Modell, für Aufgaben größer als eine Sitzung. Hält lange autonome Sitzungen durch, untersucht vor dem Handeln und prüft seine Arbeit häufiger als kleinere Modelle @an-fable.],
  [*Claude Opus 5.5*], [`opus`], [Das Arbeitspferd für komplexes Engineering. *Standardmodell in Claude Code auf Pro, Max, Team und Enterprise* @cc-model. Laut Anthropic bei Standard-Effort `medium` mindestens so gut wie Opus 5 auf `high`, mit weniger Schritten und Token @an-opus55.],
  [*Claude Sonnet 5.5*], [`sonnet`], [Für den täglichen Coding-Alltag, schneller und sparsamer als Opus. Arbeitet in der Ausführungsphase von `opusplan` @cc-model.],
  [*Claude Haiku 4.5*], [`haiku`], [Schnell und günstig für einfache Aufgaben. Wird von Claude Code intern für Hilfsaufgaben genutzt, etwa zur Bewertung von Goals (Kapitel 9) @cc-goal. Unterstützt keine Effort-Stufen @an-models.],
)

Über den Modellen steht die Mythos-Klasse (Claude Mythos 5.1). Fable 5.1 ist dasselbe zugrundeliegende Modell mit zusätzlichen Schutzmaßnahmen für Biologie, Cybersicherheit und KI-Forschung. Mythos selbst ist nicht öffentlich verfügbar.

Drei Besonderheiten sind für die Praxis wichtig:

- *Fable ist nirgends Standard* und muss ausdrücklich gewählt werden (`/model fable`). Je nach Plan läuft seine Nutzung über zusätzliches Nutzungsguthaben statt über das Planvolumen. Der Modellwähler zeigt dann "Requires usage credits", und Claude Code fragt vor der ersten solchen Anfrage nach @cc-model.
- *Alle aktuellen Modelle arbeiten mit einem Kontextfenster von einer Million Token*, auf allen Plänen, ohne Aufpreis für Token jenseits von 200.000 @an-models. Claude Code verdichtet automatisch bei etwa 967.000 Token @cc-model.
- *Sicherheitsklassifikatoren:* Fable, Opus 5.5 und Sonnet 5.5 prüfen Anfragen unter anderem auf Cybersicherheit. Schwachstellen im eigenen Quellcode zu finden ist erlaubt. Markiert der Klassifikator eine Anfrage, wiederholt Claude Code sie automatisch auf einem Ausweichmodell (von Fable und Opus 5.5 aus auf Opus 4.8) und zeigt einen Hinweis im Verlauf @an-opus55 @cc-model.

#praxis[Wer Security-Lehrmaterial, Pentest-Werkzeuge oder CTF-Aufgaben im Repository hat, sieht diese Umstellung häufig, oft schon bei der ersten Anfrage, weil `CLAUDE.md` und Verzeichnisnamen mitgeschickt werden. Das ist vorgesehenes Verhalten, keine Kontosperre. Mit `claude --safe-mode` lässt sich prüfen, ob eigene Anpassungen die Ursache sind, und unter `/config` kann man einstellen, dass Claude Code vor dem Wechsel fragt ("Switch models when a message is flagged") @cc-model.]

== OpenAI: Codex

Codex ist Ende September 2026 Teil der ChatGPT-Desktop-App (Bereiche _Work_ und _Codex_), der Codex CLI, der IDE-Erweiterung, von ChatGPT im Web und von Codex Cloud. Bei Anmeldung mit einem ChatGPT-Abo empfiehlt OpenAI folgende Modelle @oa-models:

#table(columns: (auto, auto, 1fr),
  [Modell], [Kennung], [Einordnung laut OpenAI],
  [*GPT-6 Astra*], [`gpt-6-astra`], [Das fähigste Modell für komplexe Arbeit über Code, Apps und Recherche. Für die schwierigsten Aufgaben über viele Schritte und Werkzeuge.],
  [*GPT-6.1 Sol*], [`gpt-6.1-sol`], [Nahe an Astra, aber günstiger. Empfohlen für komplexes Coding und agentische Abläufe, besonders für wiederholte, lang laufende Arbeit.],
  [*GPT-6 Luna*], [`gpt-6-luna`], [Das effizienteste Modell für klare, wiederholbare Aufgaben mit hohem Volumen: Extraktion, Klassifikation, fokussiertes Coding.],
)

GPT-6 Sol und die GPT-5.6-Familie (Sol, Terra, Luna) bleiben während der Einführung verfügbar. *GPT-5.5 wird am 14. Oktober 2026 aus ChatGPT und Codex entfernt*, GPT-5.4 und GPT-5.4 mini sind seit 31. August 2026 nicht mehr verfügbar. Wer diese Modelle in `config.toml`, eigenen Agenten oder Skripten eingetragen hat, muss umstellen. Verfügbarkeit hängt vom Plan, dem Client und dem Stand der Einführung ab @oa-models @oa-release-0154.

== Die Staffelung nebeneinander

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    content((2.3, 3.55), text(size: 8pt, weight: "bold", fill: c-accent.darken(10%))[Claude])
    stapel((2.3, 0), (([Haiku 4.5], c-accent), ([Sonnet 5.5], c-accent), ([Opus 5.5 (Standard)], c-accent), ([Fable 5.1], c-accent)), w: 4.2, h: 0.62, gap: 0.12, size: 7.5pt)
    content((10.3, 3.55), text(size: 8pt, weight: "bold", fill: c-teal.darken(10%))[Codex])
    stapel((10.3, 0), (([GPT-6 Luna], c-teal), ([GPT-6.1 Sol], c-teal), ([], white), ([GPT-6 Astra], c-teal)), w: 4.2, h: 0.62, gap: 0.12, size: 7.5pt)
    content((10.3, 1.83), text(size: 6.5pt, fill: c-grey.darken(10%), style: "italic")[(Sol deckt beide mittleren Stufen ab)])
    line((6.2, 0), (6.2, 3.1), stroke: (paint: c-grey, thickness: 0.8pt), mark: (end: "stealth", fill: c-grey, scale: 0.6))
    content((6.2, 3.35), text(size: 6.8pt, fill: c-grey.darken(20%))[Fähigkeit, Kosten])
  }),
  caption: [Grobe Zuordnung der Stufen. Die Stufen sind keine gleichwertigen Paare, die Einordnung ersetzt keinen Vergleich an eigenen Aufgaben.],
)

#merke[Die Standardmodelle beider Werkzeuge (Opus 5.5 in Claude Code, GPT-6.1 Sol in Codex) sind für den größten Teil der Softwareentwicklung die richtige Wahl. Nach oben (Fable, Astra) wechselt man für lange, unklare oder besonders schwierige Aufgaben, nach unten (Sonnet, Haiku, Luna) für klar umrissene Arbeit mit hohem Volumen. Kapitel 5 macht das konkret.]

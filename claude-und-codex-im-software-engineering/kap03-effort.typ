#import "lib.typ": *

= Reasoning-Effort verstehen

Neben dem Modell gibt es einen zweiten, oft wirkungsvolleren Regler: den Reasoning-Effort. Er bestimmt, wie viel das Modell nachdenkt, bevor es antwortet oder handelt, und wie gründlich es seine Arbeit prüft.

== Was Effort bewirkt

Die aktuellen Modelle beider Hersteller entscheiden bei jedem Schritt selbst, ob und wie lange sie nachdenken (_adaptive reasoning_) @an-effort @oa-models. Der Effort legt fest, wie großzügig sie das tun. Bei Claude lässt sich das Denken auf Opus 5.5, Sonnet 5.5 und Fable gar nicht mehr abschalten, der Effort ist der einzige Regler dafür @an-effort @an-migration.

Anthropic beschreibt den Unterschied an konkreten Beobachtungen: Mit höherem Effort testete Claude mehr Randfälle und prüfte mehr seiner Arbeit, bevor es antwortete, traf aber auch mehr Entscheidungen selbst. Mit niedrigerem Effort lieferte es schneller einen Ausgangspunkt, was zu Arbeit passt, bei der man jedes Ergebnis prüft und den nächsten Schritt selbst steuert @cc-model @an-effort.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    line((0, 0), (10.5, 0), stroke: c-dark + 0.8pt, mark: (end: "stealth", fill: c-dark, scale: 0.6))
    line((0, 0), (0, 4.2), stroke: c-dark + 0.8pt, mark: (end: "stealth", fill: c-dark, scale: 0.6))
    content((10.5, -0.75), anchor: "east", text(size: 7pt)[Effort (Token, Zeit)])
    content((-0.2, 4.1), anchor: "east", text(size: 7pt)[Qualität])
    bezier((0.2, 0.6), (9.8, 3.4), (2.5, 3.0), (5.5, 3.5), stroke: (paint: c-violet, thickness: 1.4pt))
    let lv = (("low", 1.2), ("medium", 3.0), ("high", 5.0), ("xhigh", 7.0), ("max", 9.0))
    for (n, x) in lv {
      line((x, -0.08), (x, 0.08), stroke: c-dark + 0.8pt)
      content((x, -0.35), text(font: "JetBrains Mono", size: 6.5pt, n))
    }
    rect((7.9, 0.2), (10.2, 3.9), fill: c-red.lighten(92%), stroke: (paint: c-red.lighten(40%), dash: "dashed", thickness: 0.7pt))
    content((9.05, 1.1), text(size: 6.5pt, fill: c-red, style: "italic")[abnehmender \ Nutzen, Gefahr \ des Zerdenkens])
    content((4.0, 1.2), text(size: 6.5pt, fill: c-grey.darken(20%), style: "italic")[schematisch, nicht gemessen])
  }),
  caption: [Mehr Effort bringt anfangs viel, dann immer weniger. Auf der höchsten Stufe warnt Anthropic ausdrücklich vor Zerdenken @an-effort.],
)

== Die Stufen bei Claude

#table(columns: (auto, 1fr),
  [Stufe], [Wann (nach Claude-Code-Dokumentation @cc-model)],
  [`low`], [Schneller Austausch, bei dem man jedes Ergebnis selbst prüft: Brainstorming, erster Entwurf, kleine Änderung wie eine Umbenennung.],
  [`medium`], [*Standard auf Opus 5.5 und Sonnet 5.5.* Tägliche Engineering-Arbeit mit klarem Umfang, etwa ein neues Feature.],
  [`high`], [Wo Verifikation zählt oder Randfälle wahrscheinlich sind, etwa ein Bugfix in bestehendem Code. Standard auf den übrigen Modellen.],
  [`xhigh`], [Tieferes Nachdenken bei höherem Verbrauch.],
  [`max`], [Schwere Probleme, die Claude ohne Rückfragen durcharbeiten soll, etwa das Suchen von Sicherheitslücken. Kann abnehmenden Nutzen bringen und zum Zerdenken neigen, vor breitem Einsatz testen.],
)

Dazu kommen zwei Werkzeuge in Claude Code, die keine eigenen Stufen sind: *`ultracode`* ist eine Einstellung, mit der Claude für größere Aufgaben selbstständig Arbeitsabläufe mit mehreren Teilagenten plant. *`ultrathink`* im Prompt verlangt für genau diese eine Anfrage gründlicheres Nachdenken, ohne die Sitzungsstufe zu ändern. Formulierungen wie "denk gründlich nach" haben dagegen keine Sonderbedeutung mehr @cc-model.

#achtung[*Die Stufen sind pro Modell kalibriert.* `medium` auf Opus 5.5 ist nicht dasselbe wie `medium` auf Opus 5. Anthropic empfiehlt beim Wechsel auf Opus 5.5 ausdrücklich, bei `medium` zu beginnen, statt die alte Stufe mitzunehmen. Wer weniger Nachdenken will, senkt zuerst den Effort: Das wirkt zuverlässiger als Anweisungen im Prompt @an-opus55.]

== Die Stufen bei Codex

In der ChatGPT-Desktop-App wählt man unter dem Eingabefeld eine _Power_-Voreinstellung, die Modell und Effort kombiniert (etwa "6 Sol Light" oder "Astra Medium"), oder unter _Advanced_ beides getrennt. In der CLI und in `config.toml` heißen die Stufen @oa-models @oa-config:

#table(columns: (auto, auto, 1fr),
  [App], [CLI / Konfiguration], [Einsatz laut OpenAI],
  [Light], [`low`], [schnelle, klar umrissene Aufgaben],
  [Medium], [`medium`], [Balance, wenn mehr Planung nötig ist],
  [High, Extra High], [`high`, `xhigh`], [schwierige Arbeit mit mehreren Schritten, Quellen oder Abwägungen],
  [Max], [`max`], [mehr Denkzeit für eine einzelne, sehr schwere Aufgabe],
  [Ultra], [(eigene Option)], [verteilt eine große Aufgabe auf parallele Teilagenten],
)

OpenAI gibt Startwerte vor: für Luna *High*, für Astra *Light*, für GPT-6.1 Sol die voreingestellte Stufe des Clients @oa-models. Auch hier gilt: Stufen entsprechen sich zwischen Modellgenerationen nicht genau. Die meisten Aufgaben brauchen weder Max noch Ultra.

== Claude und Codex nebeneinander

#table(columns: (1fr, 1fr, 1fr),
  [Absicht], [Claude Code], [Codex],
  [schnell, ich prüfe jeden Schritt], [`low`], [Light / `low`],
  [normale Feature-Arbeit], [`medium` (Opus 5.5)], [Standard von 6.1 Sol],
  [Bugfix, Randfälle, Verifikation], [`high`], [High],
  [schwierige Analyse, Architektur], [`xhigh`], [Extra High],
  [allein durcharbeiten, sehr schwer], [`max` (selten)], [Max (selten)],
  [große Aufgabe parallelisieren], [`ultracode`], [Ultra],
)

Die Tabelle ordnet Absichten zu, keine gleich starken Einstellungen. Die sinnvollste Regel für beide Werkzeuge lautet: *mit dem Standard beginnen, erst den Effort erhöhen und erst danach das Modell wechseln.* Wechsel von Modell oder Effort mitten in der Sitzung können den Prompt-Cache ungültig machen und damit zusätzlich kosten, Claude Code warnt in diesem Fall @an-effort @an-caching.

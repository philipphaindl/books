#import "lib.typ": *

= System-Prompt und Inferenz-Einstellungen

Bisher ging es um Modell und Effort als Regler. Darunter liegt eine Ebene, die man bei Coding-Werkzeugen selten sieht, die aber erklärt, warum sie sich so verhalten: Was genau geht bei jeder Anfrage an das Modell, und mit welchen Einstellungen wird die Antwort erzeugt?

== Was bei jeder Anfrage an das Modell geht

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let sch = (
      ([*System-Prompt des Werkzeugs* #h(4pt) Rolle, Regeln, Arbeitsweise (von Anthropic bzw. OpenAI)], c-violet),
      ([*Werkzeugdefinitionen* #h(4pt) Dateien lesen, Befehle, MCP-Server], c-violet),
      ([*Projektregeln* #h(4pt) `CLAUDE.md` / `AGENTS.md`, Skills], c-yellow),
      ([*Verlauf* #h(4pt) bisherige Nachrichten, Werkzeugausgaben, Denken], c-accent),
      ([*Aktuelle Nachricht* #h(4pt) deine Aufgabenstellung], c-blue),
    )
    for (i, s) in sch.enumerate() {
      let y = -i * 0.72
      rect((0, y - 0.3), (11.5, y + 0.3), radius: 0.06, fill: s.at(1).lighten(88%), stroke: (paint: s.at(1), thickness: 0.8pt))
      content((0.25, y), anchor: "west", text(size: 7.2pt, s.at(0)))
    }
    kasten((14.0, -1.44), [*Parameter* \ #text(size: 6.3pt)[Modell, Effort, \ max. Ausgabe, Sampling]], w: 3.0, h: 1.4, bg: luma(245), col: c-grey, size: 7.3pt)
    line((11.7, 0.3), (11.9, 0.3), (11.9, -3.18), (11.7, -3.18), stroke: c-grey + 0.8pt)
    content((12.1, -1.44), anchor: "west", text(size: 6.5pt, fill: c-grey.darken(20%))[+])
  }),
  caption: [Aufbau einer Anfrage an das Modell, von oben (stabil) nach unten (wechselnd). Stabile Teile vorne machen Prompt-Caching möglich.],
)

Die Reihenfolge ist kein Zufall. Alles, was sich zwischen Anfragen nicht ändert, steht vorne und kann vom Anbieter zwischengespeichert werden (_Prompt-Caching_ @an-caching). Deshalb kosten lange Sitzungen weniger als ihre Token-Zahl vermuten lässt, und deshalb machen Änderungen an den vorderen Schichten mitten in der Sitzung den Cache ungültig @an-caching.

== Der System-Prompt

Der System-Prompt legt fest, wer das Modell in diesem Gespräch ist, welche Regeln gelten und wie es arbeiten soll. Er hat mehr Gewicht als eine normale Nachricht und gilt für die ganze Sitzung.

#table(columns: (auto, 1fr),
  [Umgebung], [Wie man ihn beeinflusst],
  [Claude Code], [Das Werkzeug bringt einen umfangreichen eigenen System-Prompt mit. Der vorgesehene Weg für eigene Regeln ist `CLAUDE.md`. Für Skripte gibt es `--append-system-prompt "..."` (ergänzt) und `--system-prompt "..."` (ersetzt) @cc-memory. Ersetzen entfernt die Arbeitsanweisungen des Werkzeugs und ist für normale Entwicklung fast nie sinnvoll.],
  [Codex], [Eigene Basisanweisungen des Werkzeugs; eigene Regeln gehören in `AGENTS.md`, die Codex in jede Sitzung einbindet @oa-agentsmd.],
  [Chat-Apps], [Projekt-Anweisungen (Claude-Projekte) bzw. Anpassungen und Projekte in ChatGPT.],
  [API], [Claude: Feld `system`. OpenAI Responses API: Feld `instructions` bzw. eine Nachricht mit Rolle `developer`.],
)

Was einen guten System-Prompt ausmacht, deckt sich mit den Regeln für `CLAUDE.md` und `AGENTS.md` aus Kapitel 8:

- *Rolle und Kontext* knapp: für wen, in welchem Projekt, mit welchem Ziel.
- *Regeln als Verhalten formulieren*, nicht als Gesinnung: "Ändere nur, was verlangt ist" statt "Sei sorgfältig".
- *Ausgabeformat* festlegen, wo es gebraucht wird.
- *Nicht übersteuern.* Anthropic weist darauf hin, dass aktuelle Modelle auf Anweisungen stärker reagieren als frühere @an-prompting. Formulierungen wie "Nutze im Zweifel immer Werkzeug X" führen heute zu übermäßigem Einsatz. Großbuchstaben und "MUSS" sind selten nötig.
- *Widersprüche vermeiden.* Ein System-Prompt, der "arbeite selbstständig" und "frage bei jeder Unklarheit" enthält, erzeugt unvorhersehbares Verhalten.
- *Eingefügte Texte kennzeichnen.* Für Anwendungen, in denen Nutzer fremde Texte einfügen, empfiehlt Anthropic bei Opus 5.5, diese mit Markierungen zu umschließen und im System-Prompt zu erklären, dass Anweisungen darin nicht zu befolgen sind @an-opus55.

== Inferenz-Einstellungen: wie aus Wahrscheinlichkeiten Text wird

Ein Sprachmodell berechnet für jedes nächste Token eine Wahrscheinlichkeitsverteilung über sein gesamtes Vokabular. Die Inferenz-Einstellungen bestimmen, wie aus dieser Verteilung ausgewählt wird (_Sampling_).

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let toks = ("return", "if", "for", "raise", "yield")
    let t02 = (0.93, 0.05, 0.015, 0.004, 0.001)
    let t10 = (0.55, 0.2, 0.12, 0.08, 0.05)
    let panel(x0, werte, titel, col) = {
      content((x0 + 2.4, 2.75), text(size: 7.5pt, weight: "bold", titel))
      line((x0, 0), (x0 + 5.0, 0), stroke: c-dark + 0.6pt)
      for (i, w) in werte.enumerate() {
        let x = x0 + 0.3 + i * 0.95
        rect((x, 0), (x + 0.65, w * 2.4), fill: col.lighten(70%), stroke: col + 0.6pt)
        content((x + 0.325, -0.28), text(font: "JetBrains Mono", size: 5.8pt, toks.at(i)))
      }
    }
    panel(0, t02, [Temperature 0,2: fast immer "return"], c-blue)
    panel(7.0, t10, [Temperature 1,0: Alternativen möglich], c-accent)
  }),
  caption: [Schematisch: Niedrige Temperature schärft die Verteilung, hohe flacht sie ab. Die Werte sind illustrativ.],
)

#table(columns: (auto, 1fr),
  [Parameter], [Wirkung],
  [`temperature`], [Schärft (klein) oder glättet (groß) die Verteilung. 0 heißt: immer das wahrscheinlichste Token (_greedy_).],
  [`top_p`], [_Nucleus Sampling_ @holtzman: nur die wahrscheinlichsten Token, bis ihre Summe `p` erreicht (etwa 0,9), der Rest fällt weg.],
  [`top_k`], [nur die `k` wahrscheinlichsten Token berücksichtigen.],
  [`min_p`], [nur Token, deren Wahrscheinlichkeit mindestens `min_p` mal die des besten Tokens beträgt @min-p. Verbreitet bei lokalen Modellen.],
  [Wiederholungsstrafen], [`repeat_penalty`, `presence_penalty`, `frequency_penalty` senken die Wahrscheinlichkeit bereits verwendeter Token.],
  [`seed`], [Startwert des Zufallsgenerators, für reproduzierbare Läufe.],
  [`max_tokens`], [Obergrenze der Ausgabe. Bei Reasoning-Modellen zählt das Denken mit.],
  [Stop-Sequenzen], [Zeichenfolgen, bei denen die Ausgabe endet.],
)

== Was davon bei Claude und Codex einstellbar ist

Hier liegt die wichtigste Änderung der letzten Modellgenerationen: *Bei den aktuellen Frontier-Modellen ist Sampling kein Regler mehr.*

#table(columns: (auto, 1fr),
  [Modell / Umgebung], [Sampling-Parameter],
  [Claude Opus 4.7 und neuer (auch Opus 5.5), Sonnet 5], [`temperature`, `top_p` und `top_k` mit anderem als dem Standardwert führen zu einem Fehler 400. Anthropic nennt Effort und Prompting als die Wege, das Verhalten zu steuern @an-migration.],
  [OpenAI GPT-5.6], [Nur der Standardwert von `temperature` (1) wird akzeptiert.],
  [OpenAI GPT-6 Astra], [`temperature` und `top_p` werden abgelehnt @oa-latest.],
  [OpenAI GPT-6 Sol, Luna], [Nur ohne Reasoning (Effort `none`) zulässig, sonst abgelehnt @oa-latest @oa-reasoning.],
  [Claude Code, Codex, Desktop-Apps], [keine Sampling-Einstellungen; die Werkzeuge setzen ihre Parameter selbst.],
)

Der Grund: Reasoning-Modelle sind auf ein bestimmtes Sampling-Verhalten hin trainiert und abgestimmt. Wer die Streuung verringern will, erreicht das bei diesen Modellen über klare Anweisungen, strukturierte Ausgaben (vorgegebene JSON-Schemata) und Prüfungen, nicht über die Temperature. Für Code gilt ohnehin: Reproduzierbarkeit entsteht durch Tests, nicht durch deterministisches Sampling.

#achtung[Bibliotheken und Werkzeuge, die für ältere Modelle eine Temperature mitschicken, erzeugen bei den aktuellen Modellen Fehler. Wer eigene Anwendungen gegen die APIs baut, lässt Sampling-Parameter bei Claude Opus 4.7+ und bei OpenAI-Reasoning-Modellen einfach weg.]

== Kontextlänge

Die Kontextlänge ist die Obergrenze für alles aus der Abbildung oben zusammen, einschließlich Ausgabe und Denken. Drei Zahlen werden oft verwechselt:

#table(columns: (auto, 1fr),
  [Größe], [Bedeutung],
  [Kontextfenster des Modells], [Was das Modell technisch verarbeiten kann, bei den aktuellen Claude-Modellen eine Million Token @an-models.],
  [Wirksames Fenster im Werkzeug], [Was das Werkzeug tatsächlich nutzt. Bei Codex lag es laut Berichten von Nutzern zeitweise deutlich unter dem Wert der API-Dokumentation. Claude Code verdichtet bei etwa 967.000 Token @cc-model.],
  [Maximale Ausgabe], [Obergrenze einer einzelnen Antwort, einschließlich Denken.],
)

Ein großes Fenster ist kein Freibrief. Jedes Token im Verlauf wird bei jeder Anfrage erneut verarbeitet, das kostet Nutzungsvolumen, und mit wachsendem Verlauf steigt das Risiko, dass frühe Details übersehen oder durch spätere überlagert werden @liu-lost. Die Regel aus Kapitel 1 gilt deshalb unabhängig von der Fenstergröße: eine Aufgabe pro Sitzung, dauerhafte Informationen in Dateien statt im Verlauf.

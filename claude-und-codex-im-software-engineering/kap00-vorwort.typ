#import "lib.typ": *
#set heading(numbering: none)
= Bevor es losgeht

Coding-Agenten wie Claude Code und Codex schreiben heute ganze Features, führen Migrationen durch und reparieren Tests. Ob das Ergebnis brauchbar ist, entscheidet sich aber weniger am Modell selbst als an vier Fragen: Welches Modell mit welchem Reasoning-Effort passt zur Aufgabe? Was weiß der Agent wirklich, und was vermutet er nur? Hält er sich an das, was gefragt war, oder baut er mehr? Und wie wird sichergestellt, dass am Ende nicht nur "fertig" behauptet, sondern nachweislich richtig ist?

Dieses Handbuch beantwortet diese Fragen für die tägliche Softwareentwicklung. Der rote Faden lautet: *genau das Gefragte, in hoher Qualität, nicht mehr.* Overengineering ist dabei kein Schönheitsfehler, sondern ein Qualitätsproblem. Jede nicht angeforderte Abstraktion ist Code, der gelesen, getestet und gewartet werden muss.

== Aufbau

- *Teil I, Grundlagen:* wie Coding-Agenten arbeiten, welche Modelle es Ende September 2026 bei Anthropic und OpenAI gibt und was Reasoning-Effort tatsächlich bewirkt.
- *Teil II, Auswahl in der Praxis:* Einrichtung auf allen Oberflächen (CLI, Desktop-Apps, VS Code), Entscheidungstabellen pro Aufgabentyp, eine Methode, Modell und Effort am eigenen Code zu kalibrieren, und das Zusammenspiel von Claude und Codex als gegenseitige Prüfer, auch parallel in Worktrees.
- *Teil III, Qualität:* Halluzinationen vermeiden, Aufgabentreue sichern, Goals sinnvoll einsetzen, mit ADRs und Anforderungen als Leitplanken arbeiten, ohne neue Artefakte einzuführen, die Qualitätssicherung im Ablauf einschließlich Mutation Testing, Sicherheit beim Arbeiten mit Agenten und zum Abschluss ein vollständiger Durchlauf von der Anforderung bis zum Commit.
- *Teil IV, Unter der Haube:* was bei jeder Anfrage an das Modell geht, System-Prompt, Inferenz-Einstellungen wie Temperature und Kontextlänge und warum sie bei den aktuellen Frontier-Modellen gesperrt sind, sowie lokale Modelle mit ihren Formaten (safetensors, MLX, GGUF), Speicherbedarf und Sampling.
- *Anhang:* Vorlagen für `CLAUDE.md`, `AGENTS.md` und Aufgabenstellungen sowie ein Glossar.

== Stand und Haltbarkeit

Modellnamen, Standardwerte und Effort-Stufen ändern sich im Rhythmus weniger Monate. Alle konkreten Angaben entsprechen dem Stand Ende September 2026 und stammen aus den offiziellen Dokumentationen von Anthropic und OpenAI @an-models @cc-model @oa-models. Das Literaturverzeichnis am Ende des Buchs nennt alle verwendeten Quellen im IEEE-Stil, die Kapitel verweisen mit Nummern in eckigen Klammern darauf. Die Prinzipien in Teil III sind davon unabhängig und bleiben gültig, wenn die Namen wechseln. Vor jeder Umstellung lohnt ein Blick in `/model` bzw. den Modellwähler der jeweiligen App.

== Konventionen

Befehle, Ausgaben und Dateien erscheinen wie in den übrigen Handbüchern. In den Grafiken gilt:

#align(center, cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let leg = (([Claude], c-accent), ([Codex], c-teal), ([Modell / Effort], c-violet), ([Anforderung / ADR], c-yellow), ([Prüfung / Test], c-gitea), ([Review / Mensch], c-blue), ([Risiko / Fehler], c-red))
  for (i, l) in leg.enumerate() {
    let x = calc.rem(i, 4) * 4.0
    let y = -calc.floor(i / 4) * 0.75
    rect((x, y - 0.22), (x + 0.6, y + 0.22), radius: 0.06, fill: l.at(1).lighten(86%), stroke: (paint: l.at(1), thickness: 0.8pt))
    content((x + 0.8, y), anchor: "west", text(size: 8pt, l.at(0)))
  }
}))

Das durchgängige Beispiel ist wieder die `notizen`-API aus den Handbüchern zu Docker und Secure API Design @buch-docker @buch-api: FastAPI mit PostgreSQL, deren Anforderungen als Markdown-Dateien mit Akzeptanzkriterien unter `docs/anforderungen/` und deren Architekturentscheidungen als ADRs unter `docs/adr/` im Repository liegen.

#merke[Ein Agent ist so gut wie die Prüfung, die sein Ergebnis bestehen muss. Das wichtigste Werkzeug gegen Halluzinationen und Overengineering ist deshalb keine Formulierung im Prompt, sondern eine *automatisch prüfbare Definition von "fertig"*: Tests aus Akzeptanzkriterien, Architekturregeln aus ADRs und ein Review gegen genau diese Vorgaben.]

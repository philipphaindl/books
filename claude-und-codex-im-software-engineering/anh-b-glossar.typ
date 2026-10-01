#import "lib.typ": *

= Glossar

#let begriffe = (
  ([Adaptive Reasoning], [Das Modell entscheidet pro Schritt, ob und wie lange es nachdenkt; der Effort bestimmt, wie großzügig.]),
  ([ADR], [Architecture Decision Record: kurzes Dokument zu einer Architekturentscheidung mit Kontext und Konsequenzen.]),
  ([Chat-Vorlage], [Format mit Sondertoken, in dem ein Modell System-Prompt, Benutzer- und Antwortteile erwartet.]),
  ([Akzeptanzkriterium], [Prüfbare Bedingung, unter der eine Anforderung als erfüllt gilt; idealerweise ein Test.]),
  ([AGENTS.md], [Regeldatei für Codex (und andere Agenten) im Repository.]),
  ([CLAUDE.md], [Regeldatei für Claude Code; kann andere Dateien per `@pfad` einbinden.]),
  ([Effort], [Regler für die Gründlichkeit des Nachdenkens (Claude: `low` bis `max`, Codex: Light bis Max).]),
  ([GGUF], [Einzeldatei-Format von llama.cpp mit quantisierten Gewichten, Tokenizer, Metadaten und Chat-Vorlage.]),
  ([Goal], [Zielbedingung, bis zu deren Erfüllung der Agent selbstständig weiterarbeitet (`/goal`).]),
  ([Halluzination], [Plausible, aber unbelegte Behauptung, etwa eine erfundene API oder ein nicht ausgeführter Test.]),
  ([Hook], [Befehl, den das Werkzeug bei einem Ereignis automatisch ausführt, etwa nach jeder Dateiänderung.]),
  ([import-linter], [Python-Werkzeug, das Regeln über erlaubte Importe als Verträge prüft.]),
  ([KV-Cache], [Zwischenspeicher der Aufmerksamkeitswerte bisheriger Token; wächst linear mit der Kontextlänge.]),
  ([Kontextfenster], [Menge an Text, die ein Modell gleichzeitig berücksichtigt; wird bei Überlauf verdichtet.]),
  ([MLX], [Apples Framework für maschinelles Lernen auf Apple Silicon; MLX-Modelle sind Verzeichnisse mit safetensors.]),
  ([MoE], [Mixture of Experts: Modell, das pro Token nur einen Teil seiner Parameter aktiviert.]),
  ([Mutation Testing], [Prüft Tests, indem gezielt Fehler in den Code eingebaut werden; überlebende Mutanten zeigen Testlücken.]),
  ([NFR], [Nicht-funktionale Anforderung, etwa zu Antwortzeit, Sicherheit oder Verfügbarkeit.]),
  ([opusplan], [Claude-Code-Alias: Opus im Plan-Modus, Sonnet für die Ausführung.]),
  ([Overengineering], [Mehr Abstraktion, Konfigurierbarkeit oder Funktion als verlangt.]),
  ([Plan-Modus], [Modus, in dem der Agent liest und plant, aber nichts ändert.]),
  ([Prompt Injection], [Anweisungen in gelesenen Inhalten (Dateien, Webseiten, Werkzeugausgaben), die den Agenten manipulieren.]),
  ([Sandbox], [Isolation von Dateisystem und Netzwerk, in der Befehle des Agenten laufen.]),
  ([Quantisierung], [Speichern der Gewichte mit weniger Bits (etwa 4 statt 16), spart Speicher, kostet etwas Qualität.]),
  ([safetensors], [Standardformat für Modellgewichte auf Hugging Face, ohne ausführbaren Code ladbar.]),
  ([Sampling], [Auswahl des nächsten Tokens aus der Wahrscheinlichkeitsverteilung, gesteuert über Temperature, top-p u. a.]),
  ([Scope Creep], [Schleichende Ausweitung einer Änderung über den Auftrag hinaus.]),
  ([Slopsquatting], [Registrierung von Paketnamen, die Modelle erfinden, mit Schadcode.]),
  ([Spec-Driven Development], [Vorgehen, bei dem Spezifikation, Plan und Aufgaben vor dem Code entstehen.]),
  ([Subagent / Teilagent], [Vom Hauptagenten beauftragter Agent mit eigenem Kontext, oft auf kleinerem Modell.]),
  ([System-Prompt], [Anweisungen, die Rolle und Regeln für eine ganze Sitzung festlegen.]),
  ([Temperature], [Parameter, der die Wahrscheinlichkeitsverteilung schärft oder glättet; bei aktuellen Frontier-Modellen gesperrt.]),
  ([Test-Gaming], [Tests werden abgeschwächt oder Sonderfälle hart codiert, damit Prüfungen grün werden.]),
  ([ultracode / Ultra], [Modus, in dem eine große Aufgabe auf parallele Teilagenten verteilt wird.]),
  ([Worktree], [Zusätzliches Arbeitsverzeichnis desselben Repositories mit eigenem Branch, für parallele Agenten.]),
)

#set text(size: 8.2pt)
#columns(2, gutter: 16pt)[
  #for (b, d) in begriffe [
    #block(below: 0.5em, breakable: false)[*#b* \ #d]
  ]
]

#v(0.4em)
Quellen und weiterführende Literatur stehen im anschließenden Literaturverzeichnis. Die Begleitbände sind *Git von Grund auf* (CI mit Gitea Actions) @buch-git und *Secure API Design* (Beispielprojekt, Fehlerformat) @buch-api.

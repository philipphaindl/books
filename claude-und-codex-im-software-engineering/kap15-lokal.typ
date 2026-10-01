#import "lib.typ": *

= Lokale Modelle: Formate, Speicher und Sampling

Für manche Aufgaben ist ein lokal betriebenes Modell die bessere Wahl: wenn Daten das Haus nicht verlassen dürfen (etwa Freitextantworten von Kunden), wenn große Mengen gleichartiger Aufgaben anfallen oder wenn Kosten pro Anfrage eine Rolle spielen. Für agentisches Coding reichen lokale Modelle an Claude und Codex nicht heran, für Extraktion, Klassifikation, Zusammenfassung und qualitative Codierung aber oft sehr wohl. Hier kommen genau die Einstellungen ins Spiel, die bei den Frontier-Modellen gesperrt sind.

== Die Formate

Ein Modell besteht aus Gewichten (den gelernten Zahlen), einem Tokenizer, einer Konfiguration und einer Vorlage für das Chat-Format. Die Formate unterscheiden sich darin, wie diese Teile verpackt sind und welche Laufzeitumgebung sie liest.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let spalte(x, titel, col, teile, fuss) = {
      content((x, 2.55), text(size: 8pt, weight: "bold", titel))
      rect((x - 2.2, -1.3), (x + 2.2, 2.2), radius: 0.1, fill: col.lighten(92%), stroke: (paint: col, thickness: 0.8pt))
      for (i, t) in teile.enumerate() {
        let y = 1.75 - i * 0.55
        rect((x - 1.9, y - 0.22), (x + 1.9, y + 0.22), radius: 0.05, fill: white, stroke: col.lighten(30%) + 0.6pt)
        content((x, y), text(font: "JetBrains Mono", size: 6.2pt, t))
      }
      content((x, -1.65), text(size: 6.6pt, fill: c-grey.darken(20%), fuss))
    }
    spalte(0, [safetensors], c-blue, ("config.json", "tokenizer.json", "model-0001.safetensors", "model-0002.safetensors", "(Chat-Vorlage in Config)"), [Hugging-Face-Standard, meist bf16])
    spalte(5.4, [MLX], c-violet, ("config.json", "tokenizer.json", "model.safetensors", "(MLX-quantisiert)"), [Verzeichnis, nur Apple Silicon])
    spalte(10.8, [GGUF], c-accent, ("modell-Q4_K_M.gguf", "  Gewichte (quantisiert)", "  Tokenizer", "  Metadaten", "  Chat-Vorlage"), [eine Datei, überall lauffähig])
  }),
  caption: [safetensors und MLX sind Verzeichnisse mit mehreren Dateien, GGUF packt alles in eine einzige Datei.],
)

#table(columns: (auto, 1fr, 1fr, 1fr),
  [], [safetensors], [MLX], [GGUF],
  [Was es ist], [Standardformat für Gewichte auf Hugging Face, sicher ladbar (kein ausführbarer Code) @safetensors], [Modellverzeichnis für Apples Framework MLX, Gewichte als safetensors in MLX-Quantisierung @mlx-lm], [Container von llama.cpp mit Gewichten, Tokenizer, Metadaten und Chat-Vorlage in einer Datei @gguf @llamacpp],
  [Laufzeit], [transformers, vLLM, TGI], [mlx-lm, LM Studio, Ollama (MLX-Backend)], [llama.cpp, Ollama, LM Studio],
  [Plattform], [vor allem NVIDIA-GPUs], [nur Apple Silicon], [Mac, Linux, Windows, CPU, CUDA, Metal],
  [Quantisierung], [meist volle Genauigkeit; GPTQ und AWQ speichern quantisierte Gewichte ebenfalls als safetensors], [3 bis 8 Bit], [2 bis 8 Bit in vielen Varianten (K-Quants wie `Q4_K_M`)],
  [Stärke], [Ausgangspunkt für alles andere, Feinabstimmung, Server-Betrieb], [höchste Geschwindigkeit auf dem Mac, nutzt den gemeinsamen Speicher direkt], [Portabilität, riesiges Angebot, eine Datei],
)

Auf einem Mac mit Apple Silicon ist MLX nach übereinstimmenden Messungen verschiedener Quellen spürbar schneller als GGUF bei gleicher Quantisierungsstufe, die genannten Werte reichen je nach Modell und Werkzeug von etwa 15 bis 50 Prozent @terminalbytes @ollama-mlx. LM Studio nutzt MLX automatisch, wenn eine MLX-Fassung eines Modells existiert @lmstudio-mlx, Ollama hat seit Version 0.19 (Frühjahr 2026) ein MLX-Backend für Apple Silicon @ollama-mlx. Umgekehrt halten die gemischten K-Quants von GGUF bei 4 Bit die Qualität teils etwas besser als eine einfache 4-Bit-Quantisierung in MLX. Weitere Namen, die man antrifft: _GPTQ_ @gptq und _AWQ_ @awq sind Quantisierungsverfahren (gespeichert als safetensors, für NVIDIA-GPUs), _EXL2_ ist das Format von ExLlamaV2, ebenfalls für NVIDIA.

#tipp[Für den Mac gilt als Faustregel: MLX, wenn es eine Fassung von `mlx-community` oder dem Hersteller gibt, sonst GGUF in `Q4_K_M` oder `Q5_K_M`. Wer dasselbe Modell auch auf einem Linux-Server betreiben will, ist mit GGUF auf beiden Seiten einheitlicher. Konvertierungen von GGUF nach MLX sind möglich, übernehmen aber die Quantisierungsfehler der GGUF-Datei. Besser konvertiert man aus den ursprünglichen safetensors.]

== Quantisierung und Speicherbedarf

Quantisierung speichert Gewichte mit weniger Bits: statt 16 Bit pro Gewicht etwa 8 oder 4. Das spart Speicher und beschleunigt die Ausgabe, kostet aber etwas Qualität. 4 Bit gilt als üblicher Kompromiss, 8 Bit ist von voller Genauigkeit kaum zu unterscheiden, unter 4 Bit sinkt die Qualität deutlich.

Der Speicherbedarf setzt sich aus zwei Teilen zusammen:

#table(columns: (auto, 1fr),
  [Teil], [Näherung],
  [Gewichte], [Parameterzahl × Bits ÷ 8, plus etwa 10 Prozent für Verwaltung],
  [KV-Cache], [wächst linear mit der Kontextlänge: 2 × Schichten × KV-Köpfe × Kopfdimension × Token × Bytes pro Wert],
)

#table(columns: (auto, auto, auto, 1fr),
  [Modellgröße], [4 Bit], [8 Bit], [Hinweis],
  [8 Mrd.], [ca. 5 GB], [ca. 9 GB], [läuft auf fast jedem Mac],
  [32 Mrd.], [ca. 18 GB], [ca. 35 GB], [ab 32 GB Arbeitsspeicher sinnvoll],
  [122 Mrd.], [ca. 65 GB], [ca. 130 GB], [ab 96 bis 128 GB],
  [397 Mrd. (MoE, 17 Mrd. aktiv)], [ca. 210 GB], [ca. 420 GB], [4 Bit braucht 256 GB],
)

*Beispielrechnung KV-Cache* (der Cache wächst je Anfrage dynamisch mit der Kontextlänge @kwon-vllm): Ein typisches 32-Milliarden-Modell mit 64 Schichten, 8 KV-Köpfen und Kopfdimension 128 braucht in 16 Bit pro Token 2 × 64 × 8 × 128 × 2 Byte, also 256 KB. Bei 32.000 Token Kontext sind das 8 GB zusätzlich zu den Gewichten, bei 128.000 Token 32 GB. Ein 8-Bit-KV-Cache halbiert das bei kaum messbarem Qualitätsverlust.

#merke[*Mixture-of-Experts-Modelle* (MoE @shazeer-moe, erkennbar an Namen wie `397B-A17B`) aktivieren pro Token nur einen Teil ihrer Parameter, hier 17 von 397 Milliarden. Das macht sie schnell wie ein 17-Milliarden-Modell. Im Speicher liegen müssen aber *alle* Parameter. Für die Speicherplanung zählt die Gesamtzahl, für die Geschwindigkeit die aktive.]

Auf dem Mac darf die GPU standardmäßig nicht den gesamten gemeinsamen Speicher nutzen. Die Grenze lässt sich mit `sudo sysctl iogpu.wired_limit_mb=<Wert>` anheben (bis zum nächsten Neustart). Für das Betriebssystem und andere Programme muss trotzdem genug frei bleiben, etwa 8 bis 16 GB.

== Kontextlänge lokal einstellen

Bei lokalen Modellen ist die Kontextlänge eine bewusste Einstellung, und hier lauert die häufigste Falle: *Ollama verwendet standardmäßig ein Fenster von 4.096 Token* @ollama-faq, auch wenn das Modell viel mehr unterstützt. Längere Eingaben werden gekürzt, ohne dass es auffällt. Für die Codierung langer Texte oder das Lesen ganzer Dokumente muss das Fenster ausdrücklich vergrößert werden:

```bash
OLLAMA_CONTEXT_LENGTH=32768 ollama serve             # Standard für alle Modelle
OLLAMA_FLASH_ATTENTION=1 OLLAMA_KV_CACHE_TYPE=q8_0 ollama serve   # KV-Cache halbieren
```

In der API setzt man pro Anfrage `"options": {"num_ctx": 32768}`. Zu beachten: Mit `OLLAMA_NUM_PARALLEL` verarbeitet Ollama mehrere Anfragen gleichzeitig, der Speicherbedarf für den Kontext vervielfacht sich entsprechend @ollama-faq. In LM Studio stellt man die Kontextlänge beim Laden des Modells ein. Mehr als das Modell im Training gelernt hat (steht in der Model Card), bringt nichts oder verschlechtert die Qualität.

== Sampling für lokale Modelle

Hier sind Temperature und Co. echte Stellschrauben. Zwei Regeln haben Vorrang vor jeder Tabelle:

+ *Die Model Card zuerst.* Viele Hersteller geben empfohlene Werte an. Qwen etwa empfiehlt für Qwen3 im Denkmodus `temperature` 0,6, `top_p` 0,95, `top_k` 20 und `min_p` 0, ohne Denkmodus 0,7 und 0,8, und rät ausdrücklich von _greedy decoding_ (Temperature 0) im Denkmodus ab, weil es zu Endlosschleifen und Wiederholungen führt @qwen3-card @qwen3.
+ *Reasoning-Modelle nicht auf 0 setzen.* Was bei älteren Modellen für "präzise" stand, kann bei Modellen mit Denkphase das Gegenteil bewirken.

#table(columns: (auto, auto, 1fr),
  [Aufgabe], [Startwerte], [Begründung],
  [Extraktion, Klassifikation, Codierung], [`temperature` 0,1 bis 0,3, `top_p` 0,9], [wenig Streuung, gleiche Eingabe soll gleiche Kategorie ergeben],
  [Code ohne Denkmodus], [`temperature` 0,2, `top_p` 0,95], [präzise, aber nicht starr],
  [Modelle mit Denkmodus], [Werte der Model Card], [auf diese Werte hin trainiert],
  [Formulieren, Zusammenfassen], [`temperature` 0,6 bis 0,8], [natürlichere Sprache],
)

Für Auswertungen, die nachvollziehbar sein müssen, etwa die qualitative Codierung von Freitextantworten, reicht eine niedrige Temperature allein nicht. Auch mit `seed` und Temperature 0 sind Läufe nicht garantiert bitgleich, weil parallele Berechnung und Rundung auf der GPU leicht variieren. Nachvollziehbarkeit entsteht deshalb durch:

- *festgehaltene Konfiguration:* Modelldatei samt Prüfsumme, Quantisierung, Laufzeitversion, System-Prompt, alle Sampling-Parameter, Kontextlänge;
- *strukturierte Ausgabe:* ein festes Kategorienschema, das Ollama, LM Studio und llama.cpp über JSON-Schemata bzw. Grammatiken erzwingen können;
- *Konsistenzprüfung:* dieselben Texte mehrfach codieren lassen und die Übereinstimmung zwischen den Läufen messen, wie zwischen zwei menschlichen Codierern (etwa mit Krippendorffs Alpha @krippendorff).

== Chat-Vorlage und System-Prompt lokal

Jedes Modell erwartet seine Eingabe in einem bestimmten Format mit Sondertoken für System, Benutzer und Antwort. Diese _Chat-Vorlage_ steckt in GGUF-Dateien in den Metadaten, bei safetensors und MLX in der Tokenizer-Konfiguration. Ist sie falsch oder fehlt sie, ignoriert das Modell den System-Prompt, antwortet mit seltsamen Token oder hört nicht auf zu schreiben. Seriöse Quellen (offizielle Fassungen, `mlx-community`, bekannte Quantisierer) liefern korrekte Vorlagen mit, bei selbst konvertierten Modellen ist das die erste Fehlerquelle.

In Ollama bündelt eine _Modelfile_ Modell, Parameter und System-Prompt zu einer wiederverwendbaren Konfiguration, die sich versionieren lässt:

#datei("Modelfile")[
```text
FROM ./modell-Q4_K_M.gguf
PARAMETER num_ctx 32768
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER seed 42
SYSTEM """
Du codierst Freitextantworten von Kunden nach dem Codebuch unten.
Antworte ausschließlich mit JSON nach dem vorgegebenen Schema.
Wenn keine Kategorie passt, verwende "sonstiges" und begründe in einem Satz.
"""
```
]

```bash
ollama create codierer -f Modelfile
ollama run codierer
```

== Lokale Modelle in Claude Code und Codex

Beide Werkzeuge lassen sich technisch mit lokalen Modellen verbinden: Codex bringt dafür einen eigenen Modus (`--oss`) für Ollama und LM Studio mit @oa-commands, Claude Code kann über `ANTHROPIC_BASE_URL` auf einen Server mit Anthropic-kompatibler Schnittstelle zeigen, wie ihn aktuelle Versionen von LM Studio anbieten @lmstudio-claude. Für agentisches Coding im Sinne dieses Buchs ist das derzeit aber keine gute Wahl. Die Werkzeuge sind auf die Fähigkeiten der Frontier-Modelle abgestimmt, und die Qualitätsunterschiede bei langen, werkzeuglastigen Aufgaben sind groß. Der sinnvolle Einsatz lokaler Modelle liegt bei klar umrissenen Aufgaben mit hohem Volumen und bei Daten, die das Haus nicht verlassen dürfen.

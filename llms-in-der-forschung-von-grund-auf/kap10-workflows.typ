#import "lib.typ": *

= Reproduzierbare Forschungs-Workflows

Stell dir vor, du annotierst im März 20.000 Kommentare mit einem Sprachmodell. Im Herbst schreibt dir ein Gutachter: "Bitte wiederholen Sie die Analyse mit einem leicht geänderten Codebuch." Du startest dein Skript und bekommst eine Fehlermeldung, weil der Anbieter das Modell abgeschaltet hat. Du nimmst ein neueres, und plötzlich passen die Zahlen nicht mehr zu deiner Tabelle 2. Wer ist schuld: dein Code, das neue Modell, der Zufall oder eine stille Änderung beim Anbieter? Ohne Aufzeichnungen kannst du das nicht beantworten.

Das ist kein Randfall. Ein gehostetes Sprachmodell ist ein Messinstrument, das sich hinter demselben Namen ändern kann, bei gleicher Eingabe unterschiedlich antwortet und nach etwa einem Jahr verschwindet. Dazu entfernen Anbieter Einstellungen, auf die man sich verlassen hat: Wer bei Anthropic die API-Version `2026-10-21` benutzt und `temperature` mitschickt, bekommt einen Fehler (Stand: 11. November 2026) @anthropic2026versions.

Dieses Kapitel zeigt, wie du ein Projekt so aufsetzt, dass eine fremde Person jede Zahl nachvollziehen kann, auch wenn das Modell längst weg ist. Es erklärt, woher die Schwankungen kommen und wie man sie misst, baut eine Pipeline in acht Stufen auf, schätzt Kosten, schaut auf Literaturreviews und endet bei Berichtsregeln, Ethik und Recht. Es gehört zu Foliensatz 10; das Notebook `notebooks/10_reproducible_pipeline.ipynb` setzt die Pipeline mit einem simulierten Annotator um.

#lernziele[
  erklären, warum ein gehostetes Modell kein fester Messstab ist, und drei Quellen für unterschiedliche Antworten unterscheiden,
][
  begründen, warum "Temperatur 0" keine gleichen Antworten garantiert, und die Stabilität einer Pipeline mit TAR\@N messen,
][
  ein Projekt in acht Stufen so aufsetzen, dass jeder Modellaufruf eine prüfbare Spur hinterlässt,
][
  die Kosten eines Annotationslaufs mit Batch und Caching in Grundrechenarten schätzen,
][
  Evidenz zu LLM-Literaturreviews, Berichtsleitlinien, Verlagsregeln und EU-Recht einordnen.
]

== Das Instrument hält nicht still

#alltag[
  Eine Küchenwaage, die über Nacht still ihre Eichung ändert, bei jedem Wiegen ein paar Gramm anders anzeigt und nach einem Jahr aus dem Handel genommen wird. Mit so einer Waage kannst du kein Rezept festhalten. Ein gehostetes Sprachmodell verhält sich als Messinstrument genau so.
]

Das Lehrbuch dieser Lehrveranstaltung sagt es so: Der Untersuchungsgegenstand "hält nicht still" @haindl2027research. Zuerst brauchst du drei Begriffe, die oft durcheinandergeraten (@k10-fig-spektrum).

#figure(
  diagram(spacing: (7mm, 6mm),
    fknoten((0, 0), [*reproduzierbar* \ gleiche Daten, gleicher Code, \ gleiches Ergebnis], col: c-blue, filled: true, w: 46mm),
    fknoten((1, 0), [*replizierbar* \ neue Daten, gleiche Methode, \ gleiche Schlüsse], col: c-teal, w: 46mm),
    fknoten((2, 0), [*generalisierbar* \ gilt auch in anderen \ Kontexten], col: c-violet, w: 46mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"),
    node((0, 1), text(font: "Inter", size: 7.5pt, fill: c-grey.darken(20%))[Rezept, Zutaten, Küche gleich: derselbe Kuchen], stroke: none),
    node((2, 1), text(font: "Inter", size: 7.5pt, fill: c-grey.darken(20%))[schmeckt in jeder Familie], stroke: none),
  ),
  caption: [Drei Aussagen steigender Stärke nach dem Lehrbuch @haindl2027research. Bei gehosteten Modellen ist schon die linke nicht selbstverständlich.],
) <k10-fig-spektrum>

Ein Ergebnis kann perfekt reproduzierbar sein und trotzdem nicht replizieren, weil es ein Zufallsprodukt eines einzigen Datensatzes war @Peng2011. Bei einem gehosteten Modell scheitert sogar die schwächste Stufe, wenn es abgeschaltet ist, bevor jemand deinen Code erneut ausführt. Der Test zum Merken: Könnte eine fremde Person, oder du in fünf Jahren, das Repository klonen und jede Zahl neu erzeugen?

=== Kleine Entscheidungen, große Wirkung

Zum Messinstrument gehören auch der Prompt und der Parser, also der Code, der aus der Antwort das Label liest. Jede dieser Entscheidungen kann das Ergebnis verschieben, und wer mehrere ausprobiert, findet fast immer etwas "Signifikantes" (nach dem p-Wert nicht nach Zufall aussehend, siehe _Das Nötigste vorab_).

#studie(titel: [Baumann et al., 2025 (Preprint)])[
  *Gemacht:* 37 Annotationsaufgaben aus 21 sozialwissenschaftlichen Studien, 13 Millionen Labels von 18 Sprachmodellen, 2.361 Hypothesen neu geprüft @baumann2025large. *Herausgekommen:* Mit den besten Modellen führten etwa 31 % der Hypothesen zu falschen Schlüssen, mit kleineren etwa die Hälfte. Eine Handvoll Prompt-Umformulierungen reichte, um fast jedes Ergebnis signifikant aussehen zu lassen. *Heißt:* Modell, Prompt und Parser müssen feststehen, bevor du Ergebnisse siehst.
]

Auch Formatierung wirkt: Biderman et al. maßen bei einem Multiple-Choice-Test (ARC) für Mixtral 56,7~% in einem Prompt-Format und 81,3~% in einem anderen @biderman2024lessons. Bei Sclar et al. machten Leerzeichen oder Doppelpunkte im schlimmsten Fall bis zu 76 Punkte Unterschied @Sclar2024.

== Woher die Schwankungen kommen

Schickst du dieselbe Anfrage zweimal ab und bekommst zwei Antworten, gibt es drei mögliche Ursachen mit jeweils eigenem Gegenmittel (@k10-tab-quellen).

#figure(
  table(columns: (auto, 1fr, 1fr),
    table.header([Quelle], [Was passiert], [Gegenmittel]),
    [*Sampling*], [Das Modell würfelt gewollt unter den wahrscheinlichen nächsten Wörtern (Temperatur über 0).], [Mehrfach laufen lassen, Streuung berichten.],
    [*Numerisches Rauschen*], [Auch bei Temperatur 0 rechnet der Server je nach Auslastung minimal anders, und ein anderes Wort gewinnt.], [Wiederholen und vergleichen; lokal ein stabiles Setup nutzen.],
    [*Drift*], [Das Modell hinter dem Namen ändert sich, oder ein Alias zeigt auf ein neueres.], [Datierte Version festlegen, Probe-Set am Anfang und Ende laufen lassen.],
  ),
  kind: table, supplement: [Tab.],
  caption: [Drei Quellen unterschiedlicher Ausgaben und was jeweils hilft.],
) <k10-tab-quellen>

=== Temperatur 0 ist nicht "immer dasselbe"

Die Temperatur steuert, wie stark das Modell vom wahrscheinlichsten nächsten Wort abweicht. Bei 0 nimmt es immer das wahrscheinlichste. Auf dem Papier wäre das stabil, in der Praxis ist es das nicht.

#studie(titel: [Atil et al., 2025])[
  *Gemacht:* Fünf gehostete Modelle, acht Aufgaben, Temperatur 0, fester Seed (Startwert des Zufallszahlen-Erzeugers), jede Aufgabe zehnmal identisch gestellt @atil2025nondeterminism. *Herausgekommen:* Die Genauigkeit schwankte zwischen den Läufen um bis zu 15 Prozentpunkte. Zählt man ein Item als richtig, wenn irgendein Lauf es richtig hatte ("bestmöglich"), oder nur, wenn alle Läufe es richtig hatten ("schlechtestmöglich"), lagen beide Werte bis zu 70 Punkte auseinander. *Heißt:* Ein einzelner Lauf sagt wenig. Die Modelle sind großteils abgeschaltet, der Mechanismus bleibt.
]

Andere finden dasselbe: Bei Ouyang et al. bekamen 18 bis 44 % der Programmieraufgaben bei Temperatur 0 nicht jedes Mal dasselbe Testergebnis @ouyang2025empirical, und Yuan et al. sahen bei einem Reasoning-Modell bis zu 9~% Schwankung allein durch Zahl und Typ der GPUs @yuan2025understanding. Von 76 untersuchten Arbeiten zur Code-Erzeugung bedachten nur 16 den Nichtdeterminismus.

=== Warum ein Server nicht gleich rechnet

#alltag[
  Du addierst drei Zahlen und rundest nach jedem Schritt auf drei Stellen. Je nachdem, womit du anfängst, kommt etwas leicht anderes heraus. Eine Grafikkarte (GPU) tut das mit Tausenden Zahlen, und die Reihenfolge hängt davon ab, wie viele Anfragen anderer Nutzer gerade im selben Paket (Batch) mitlaufen.
]

#rechnung(titel: [Reihenfolge ändert das Ergebnis])[
  Gerechnet wird mit 1000, 4 und 4, nach jedem Schritt auf drei Stellen gerundet. Erst 1000 + 4 = 1004, gerundet 1000, dann 1000 + 4 = 1004, gerundet 1000: Ergebnis 1000. Andersherum erst 4 + 4 = 8, dann 1000 + 8 = 1008, gerundet 1010: Ergebnis 1010. Dieselben Zahlen, ein Prozent Unterschied, nur wegen der Reihenfolge.
]

Das ist die Idee hinter dem Befund von He und dem Thinking Machines Lab (ein Blogbeitrag mit DOI, nicht begutachtet) @he2025defeating. Ein einzelner Rechendurchlauf ist stabil, aber die Rechenroutinen (Kernels) wählen ihre Reihenfolge je nach Batch-Größe, und die hängt von der Serverlast ab, die du nicht siehst. Fehlende *Batch-Invarianz* heißt: Das Ergebnis für deine Anfrage hängt davon ab, wer sonst noch fragt (@k10-fig-batch). Sind zwei Wörter fast gleich wahrscheinlich, kippt die Wahl, und der Text läuft ab da anders weiter.

#figure(
  diagram(spacing: (4mm, 6mm),
    fknoten((0, 0), [Server ist \ ausgelastet], col: c-grey, w: 25mm),
    fknoten((1, 0), [Batch-Größe \ ändert sich], col: c-grey, w: 25mm),
    fknoten((2, 0), [Zahlen werden \ anders addiert], col: c-accent, w: 25mm),
    fknoten((3, 0), [Rundung \ weicht leicht ab], col: c-accent, w: 25mm),
    fknoten((4, 0), [ein anderes \ Wort gewinnt], col: c-red, filled: true, w: 25mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"), edge((3, 0), (4, 0), "-|>"),
  ),
  caption: [Ursachenkette des numerischen Rauschens bei Temperatur 0 nach He et al. @he2025defeating.],
) <k10-fig-batch>

#studie(titel: [He und Thinking Machines Lab, 2025])[
  *Gemacht:* 1.000 Antworten desselben Prompts ("Tell me about Richard Feynman") bei Temperatur 0 mit einem großen Modell auf einem üblichen Server (vLLM) @he2025defeating. *Herausgekommen:* 80 verschiedene Texte. Die ersten 102 Wörter (Token) waren identisch, bei Token 103 kam 992-mal "Queens, New York" und 8-mal "New York City". Mit batch-invarianten Rechenroutinen waren alle 1.000 Texte identisch, der Testlauf auf einer GPU dauerte aber 42 statt 26 Sekunden. *Heißt:* Stabile Ausgabe geht und kostet Tempo. Sie gilt nur für dieselbe Hardware und Software @cooper2026accelerating.
]

Lokal schaltest du das mit `VLLM_BATCH_INVARIANT=1` ein; die Funktion ist noch Beta und braucht aktuelle Grafikkarten (Stand: 11. November 2026) @vllm2026batch. "Lokal" heißt aber nicht automatisch "identisch": Nicholsons lokaler Lauf hatte bei Temperatur 0 immer noch einen *Unique-Output-Anteil* von 0,093 (die Zahl verschiedener Texte unter den Wiederholungen geteilt durch die Zahl der Läufe, niedriger heißt wiederholbarer) @nicholson2026quantifying.

=== Seeds, Fingerprints und verschwindende Stellschrauben

Auch ein `seed` rettet dich nicht. OpenAI nennt ihn eine Beta-Funktion: "Determinism is not guaranteed" @openai2023reproducible. Azure schreibt, dass selbst gleicher Seed und gleicher `system_fingerprint` (eine Kennung der Server-Einrichtung) unterschiedliche Antworten liefern können @microsoft2026reproducible. Mitloggen solltest du ihn trotzdem: Er verrät, dass sich etwas geändert hat.

Bei Anthropic verschwinden die Stellschrauben ganz. Auf der API-Version `2026-10-21` führt jedes Senden von `temperature`, `top_p` oder `top_k` zu einem 400-Fehler. Claude-Modelle ab 4.7 lehnen Nicht-Standardwerte auf jeder Version ab, die Version `2023-06-01` erlaubt sie nur für Claude 4.6 und früher @anthropic2026migration. Das SDK (die Bibliothek, die du benutzt) wechselt mit einer neuen Hauptversion still auch die API-Version: Ein Skript kann nach einem Update abbrechen oder mit anderen Einstellungen laufen. Viele Reasoning-Modelle (die vor der Antwort erst "nachdenken") nehmen gar keine Temperatur an @microsoft2026reasoning. Stabilität entsteht heute deshalb durch *Wiederholen und Vergleichen*, nicht durch Einstellungen (eine Schlussfolgerung aus den Anbieter-Dokumentationen, keine veröffentlichte Leitlinie).

=== Drift und kurze Lebensdauer

Die dritte Quelle zeigt nichts an. Chen, Zaharia und Zou schickten im März und Juni 2023 dieselben Prompts an GPT-4: Die Trefferquote beim Erkennen von Primzahlen fiel von 84,0~% auf 51,1~%, während GPT-3.5 von 49,6~% auf 76,2~% stieg @chen2024chatgpts. Heute gibt es datierte *Snapshots* (Modellversionen mit Datum im Namen, etwa `claude-sonnet-4-5-20250929`), die sich nicht mehr ändern sollen. Daneben stehen *Aliase* wie `latest`, die auf neuere Versionen zeigen. Bei Google leiten manche Aliase automatisch um, bei OpenAI wurde `chatgpt-4o-latest` am 17. Februar 2026 abgeschaltet @google2026geminideprecations @openai2026deprecations. Nimm in Studien nie einen Alias.

Snapshots sind dafür endlich. Rechnet man vom Datum im Namen bis zum Abschalttermin, leben neun ausgewählte Snapshots etwa ein bis zweieinhalb Jahre (@k10-fig-lebensdauer; keine systematische Auswertung) @anthropic2026model @openai2026deprecations.

#figure(
  balken((
    ([`claude-3-haiku-20240307`], 25),
    ([`claude-3-7-sonnet-20250219`], 12),
    ([`claude-sonnet-4-20250514`], 13),
    ([`claude-opus-4-1-20250805`], 12),
    ([`claude-sonnet-4-5-20250929`], 14),
    ([`gpt-4o-2024-08-06`], 29),
    ([`gpt-4.1-2025-04-14`], 21),
    ([`gpt-5.1-2025-11-13`], 17),
    ([`gpt-5.4-nano-2026-03-17`], 13),
  ), max: 30, breite: 6.5, hoehe: 0.28, farbe: c-violet, einheit: " Monate", nachkomma: 0),
  caption: [Lebensdauer ausgewählter Snapshots in Monaten, gerundet (Stand: 11. November 2026). Manche Abschalttermine liegen noch in der Zukunft @anthropic2026model @openai2026deprecations.],
) <k10-fig-lebensdauer>

Jüngere Snapshots leben hier etwa 12 bis 17 Monate, kürzer als Begutachtung plus Replikationsfenster. Die Vorwarnung unterscheidet sich: OpenAI mindestens sechs Monate für allgemein verfügbare Modelle, Anthropic mindestens 60 Tage, Google keine feste Frist. Gewichte aufbewahren will Anthropic zwar, zugänglich halten nicht. Sicher bleibt nur ein Modell mit offenen Gewichten (*open weights*), das du selbst archivierst. Auch Werkzeuge der Anbieter sind keine Forschungsartefakte: OpenAI schaltet seine gehostete Evals-Plattform und die gespeicherten Prompts am 30. November 2026 ab. Prompts und Auswertungen gehören in dein Repository.

#hoersaal([Was heißt "reproduzierbar" noch, wenn das Modell nach einem Jahr weg ist?], [
  Zweierlei. Erstens *Re-Analysierbarkeit*: Aus archivierten Rohantworten, Prompts, Parser und Analysecode lässt sich jede Zahl neu berechnen. Zweitens eine *Replikation mit einem Ersatzinstrument*, etwa einem archivierten Open-Weight-Modell. Dieselben Antworten vom Modell kannst du nicht versprechen.
])

== Stabilität messen: TAR\@N

Wie stabil ist deine Pipeline? Dafür gibt es eine einfache Kennzahl von Atil et al., die *Total Agreement Rate*, kurz TAR\@N @atil2025nondeterminism.

#alltag[
  Du gibst demselben Studenten dieselben 100 Klausurfragen dreimal an drei Tagen. TAR\@3 ist der Anteil der Fragen, bei denen alle drei Abgaben identisch sind. Es zählt nicht, ob die Antworten richtig sind, nur ob sie gleich bleiben.
]

Du lässt dieselben Items N-mal mit identischen Einstellungen laufen und zählst, bei wie vielen *jeder* Lauf dasselbe lieferte. Dieser Anteil in Prozent ist TAR\@N. 100 heißt perfekt stabil, einen offiziellen Schwellenwert gibt es nicht. *TARr* vergleicht den rohen Text, *TARa* die geparste Antwort, also das Label nach dem Parser.

#beispiel(titel: [Vier Items, drei Läufe])[
  Item 1 lautet in allen Läufen "B", Item 2 "C", Item 3 liefert "A", "D", "A", Item 4 liefert "B", "Answer: B", "B". Roh stimmen nur die Items 1 und 2 überein: 2 von 4, TARr\@3 = 50~%. Nach dem Parser, der "Answer:" abschneidet, stimmt auch Item 4: 3 von 4, TARa\@3 = 75~%. Item 3 ist ein echter Widerspruch, Item 4 nur Formatierung.
]

#datei("stability.py")[```python
def tar_at_n(outputs, parse=None):
    """outputs: Item -> Liste der N Ausgaben."""
    agree = 0
    for outs in outputs.values():
        vals = [parse(o) if parse else o for o in outs]
        agree += len(set(vals)) == 1
    return 100 * agree / len(outputs)

toy = {1: ["B", "B", "B"], 2: ["C", "C", "C"],
       3: ["A", "D", "A"], 4: ["B", "Answer: B", "B"]}
parse = lambda s: s.replace("Answer:", "").strip()
print(tar_at_n(toy), tar_at_n(toy, parse))
```]

```out
50.0 75.0
```

TARa ist die Zahl für Label-Stabilität, TARr zählt bei Freitext. Weil der Parser festlegt, was "gleich" ist, versionierst du ihn wie den Prompt. TAR\@N sinkt, wenn N wächst, denn mit mehr Läufen hat jedes Item mehr Gelegenheiten für einen Ausreißer; vergleiche TAR also nur bei gleichem N. Bei der eigentlichen Aufgabenkennzahl (etwa Accuracy) berichtest du Minimum, Median und Maximum über die Läufe.

#fallstrick[
  Liefert dein Cache bei jeder Wiederholung die gespeicherte erste Antwort, misst du kein Rauschen mehr und bekommst TAR\@10 = 100~%. Der Wiederholungsindex gehört in den Cache-Schlüssel.
]

#hoersaal([Ist Variation nicht einfach Rauschen, das man wegmitteln sollte?], [
  Gegen Rauschen hilft Mitteln (etwa das Mehrheitslabel aus mehreren Läufen), gegen systematische Fehler nicht: Versteht das Modell ein Item immer falsch, ist es in jedem Lauf falsch. Das siehst du nur an Gold-Labels (Kapitel 5).
])

== Die Referenz-Pipeline in acht Stufen

Die Vorlage ist eine Synthese dieser Lehrveranstaltung, kein veröffentlichter Standard. Jede Stufe hinterlässt eine Datei im Repository, damit jede Zahl im Bericht auf Rohdaten zurückgeht (@k10-fig-pipeline).

#figure(
  diagram(spacing: (5mm, 9mm),
    fknoten((0, 0), [*1 Design* \ `analysis_plan.md`], col: c-blue, filled: true, w: 33mm),
    fknoten((1, 0), [*2 Preregistration* \ `preregistration.md`], col: c-blue, w: 33mm),
    fknoten((2, 0), [*3 Modellwahl* \ `models.yaml`], col: c-blue, w: 33mm),
    fknoten((3, 0), [*4 Prompts* \ `codebook_v1.md`], col: c-blue, w: 33mm),
    fknoten((3, 1), [*5 Code* \ `src/`], col: c-teal, w: 33mm),
    fknoten((2, 1), [*6 Provenienz* \ `manifest.json`], col: c-teal, w: 33mm),
    fknoten((1, 1), [*7 Validierung* \ `stability.py`], col: c-accent, w: 33mm),
    fknoten((0, 1), [*8 Reporting* \ `paper.md`], col: c-accent, filled: true, w: 33mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"),
    edge((3, 0), (3, 1), "-|>"), edge((3, 1), (2, 1), "-|>"), edge((2, 1), (1, 1), "-|>"), edge((1, 1), (0, 1), "-|>"),
  ),
  caption: [Die acht Stufen und ihre Dateien. Obere Reihe: Planung, von links nach rechts. Untere Reihe: Durchführung und Berichten, von rechts nach links.],
) <k10-fig-pipeline>

*Stufe 1, Design.* Du begründest das Design, statt es nur zu benennen. Dazu gehört eine *Power-Analyse*: Wie viele Testitems brauchst du, damit ein echter Unterschied eine faire Chance hat aufzufallen? Übliche Testsets sind dafür oft zu klein (ein Übersetzungs-Testset mit 2.000 Sätzen hat etwa drei Viertel der nötigen Aussagekraft für einen Unterschied von einem Punkt) @Card2020. Die *Baseline* (Vergleichsmethode) tunest du so sorgfältig wie dein System, und mit *Ablationen* schaltest du Bausteine einzeln ab, um ihren Beitrag zu sehen.

*Stufe 2, Preregistration.* Du schreibst deinen Plan mit Zeitstempel auf, bevor du Ergebnisse siehst @Nosek2018. Was du später findest, ist erlaubt, gilt aber als Idee für die nächste Studie. Bei LLMs gehören Modell, Prompt, Parser, Läufe und Batching in den Plan: Figalova et al. fanden mit GPT-5.4 bei Datei-Batches 82,3 bis 82,9~% der geeigneten Datensätze, mit "alle auf einmal" nur 66,8~% @figalova2026evaluating. Dazu planst du ein *Multiverse*: viele vernünftige Prompt- und Modellvarianten, um zu sehen, ob dein Schluss überlebt.

*Stufe 3, Modellwahl.* Liegt das Abschalt-Datum vor deiner Einreichung? Verwende einen datierten Snapshot, halte die Bibliotheksversionen in einer Lockfile fest und plane einen *Replikationsarm* mit archivierbarem Open-Weight-Modell. Die Angaben im Beispiel sind Platzhalter; den genauen Snapshot entnimmst du der Modellübersicht des Anbieters.

#datei("config/models.yaml")[```yaml
primary:
  model: claude-sonnet-5-5
  api_version: "2026-10-21"
  sdk_version: PINNED      # per Lockfile festnageln
  retirement: CHECK        # Abschalttermin eintragen
replication:
  model: OPEN-WEIGHT-MODEL
  runtime: vllm 0.33.0
  batch_invariant: true
```]

*Stufe 4, Prompts.* Ein Prompt ist Code: Codebuch und Vorlage liegen im Repository, jede Änderung ist eine neue Version. Für jeden fertigen Prompt speicherst du einen *Hash* (SHA-256), einen Fingerabdruck des Textes. Ändert sich ein Zeichen, ändert er sich völlig, so lässt sich beweisen, welcher Prompt welche Ausgabe erzeugt hat.

```python
import hashlib

def sha256(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()

assert sha256("Label: A") != sha256("Label: A ")   # ein Leerzeichen genügt
```

#tipp[
  Setze den immer gleichen Teil des Prompts (Anweisung, Kategorien, Beispiele) an den Anfang und das einzelne Item ans Ende. Dann können Anbieter den Anfang zwischenspeichern, und das spart Geld (siehe unten).
]

*Stufe 5, Code.* Ordner für Konfiguration, Prompts, Rohdaten, Gold-Labels, Code und Läufe (`runs/RUN_ID/` mit `requests.jsonl`, `responses.jsonl`, `manifest.json`) halten alles getrennt, Rohantworten werden nie überschrieben, und Texte werden vor jedem API-Aufruf *pseudonymisiert* (Namen durch Codes ersetzt). Das Herzstück ist eine Funktion, die für jedes Item einen Schlüssel bildet, im Cache nachsieht und nur bei einem Fehlschlag das Modell fragt. Im Schlüssel steckt alles, was die Antwort ändern kann: Modell, API-Version, Einstellungen, fertiger Prompt und Wiederholungsindex.

*Stufe 6, Provenienz.* Provenienz heißt Herkunftsnachweis. Das *Manifest* ist die Prüfspur eines Laufs und beantwortet, was ein Gutachter in zwei Jahren fragt.

#datei("runs/.../manifest.json")[```json
{
  "run_id": "2027-03-14_annot_v1_r03",
  "model": "claude-sonnet-5-5",
  "api_version_header": "2026-10-21",
  "decoding": {"temperature": "default"},
  "prompt_template_sha256": "...",
  "codebook_sha256": "...",
  "n_requests": 20000,
  "cost_usd_estimated": 20.80,
  "results_sha256": "..."
}
```]

Lade Batch-Ergebnisse *sofort* herunter: Anthropic hält sie 29 Tage, OpenAI löscht Ausgabedateien 30 Tage nach Abschluss @anthropic2026batch @openai2026batch. Lokal gehört der GPU-Typ ins Manifest. Eine kleine Funktion `verify_run()` prüft vor jeder Auswertung, ob die Hashes im Manifest noch zu den Dateien passen. Hat jemand "nur schnell" eine Zeile korrigiert, schlägt sie an, bevor eine Zahl im Paper davon abhängt.

*Stufe 7, Validierung.* Fünf Prüfungen (@k10-tab-pruefungen) führen zu den Kapiteln 5 und 6 zurück. Miss außerdem die Basis-Schwankung, bevor du eine Stabilisierungstechnik testest, sonst verwechselst du Rauschen mit Wirkung @nicholson2026quantifying.

#figure(
  table(columns: (auto, 1fr),
    table.header([Prüfung], [So geht es]),
    [*Stabilität*], [Mindestens 10 Läufe auf einer gemischten Stichprobe, TARr, TARa, Minimum, Median, Maximum.],
    [*Gültigkeit*], [Modell-Labels gegen menschliche Gold-Labels prüfen (Kapitel 5).],
    [*Schlüsse*], [Endergebnisse für Fehler in den Labels korrigieren (Kapitel 6).],
    [*Drift*], [Ein festes Probe-Set am Anfang und am Ende der Studie laufen lassen.],
    [*Replikation*], [Dieselbe Pipeline mit dem archivierten Open-Weight-Modell.],
  ),
  kind: table, supplement: [Tab.],
  caption: [Fünf Prüfungen der Validierungsstufe.],
) <k10-tab-pruefungen>

*Stufe 8, Reporting.* Der Methodenteil bekommt einen Unterabschnitt "LLM-Nutzung und Stabilität", du berichtest die Streuung statt eines Einzellaufs, und Prompts, Konfigurationen und Rohantworten kommen in ein Replikationspaket mit dauerhafter Kennung (DOI). Fremde Reproduktion ist schwer: Im Benchmark CORE-Bench (270 Aufgaben aus 90 Arbeiten) schaffte der beste Agent auf der schwierigsten Stufe nur 21 % (Basis von 2024), mit sauberen Paketen gelingt sie eher @siegel2025corebench.

#hoersaal([Ist dieser Aufwand für eine Masterarbeit nicht übertrieben?], [
  Er fällt fast ganz am Anfang an. Einen Prompt zu protokollieren oder eine Version festzulegen kostet am Tag des Experiments fast nichts, dieselbe Information nach der Abschaltung zu rekonstruieren ist oft unmöglich @haindl2027research. Das Notebook zu Foliensatz 10 zeigt, dass es an einem Nachmittag steht.
])

== Werkzeuge und Kosten

Die erste Entscheidung ist, wo das Modell läuft. Ein gehostetes Modell ist wie ein Taxi: stark, aber die Route kann sich ändern. Ein eigenes Modell ist das eigene Auto: mehr Arbeit, volle Kontrolle (@k10-tab-hosting).

#figure(
  table(columns: (auto, 1fr, 1fr),
    table.header([Merkmal], [Gehostete API], [Eigene offene Gewichte]),
    [*Leistung*], [stärkste Modelle], [kann niedriger sein],
    [*Stabilität*], [nicht garantiert; `seed` nur "best effort"], [mit Batch-Invarianz identische Ausgabe möglich],
    [*Einstellungen*], [bei vielen Modellen entfernt], [volle Kontrolle],
    [*Lebensdauer*], [etwa ein Jahr; Aliase wandern], [Gewichte selbst archivieren],
    [*Preis*], [pro Token; Batch-APIs 50 %], [eigene Hardware; Stabilität kostet Tempo],
    [*Personendaten*], [Aufbewahrung und Transfer beim Anbieter], [bleiben in der Einrichtung],
  ),
  kind: table, supplement: [Tab.],
  caption: [Gehostet oder selbst betrieben (Stand: 11. November 2026) @he2025defeating @vllm2026batch @anthropic2026migration @openai2026batch.],
) <k10-tab-hosting>

Für eine Masterarbeit reicht oft ein Python-Skript mit Cache und Manifest. Bei gemeinsamen Auswertungen helfen *Inspect AI* und *lm-eval* (Evaluationen), *promptfoo* (Prompt-Tests), *DSPy*, *MLflow* (Lauf-Verfolgung) und *vLLM* (lokaler Server); Versionen stehen in Foliensatz 10.

=== Batch und Caching

#alltag[
  *Batch* ist, einen Stapel Briefe auf einmal einzuwerfen und die Antworten später zum halben Preis abzuholen. *Caching* ist eine Notiz am Kopf jedes Briefes, die der Empfänger schon kennt: Er muss sie nicht jedes Mal neu lesen und berechnet sie billiger.
]

Anthropic und OpenAI bieten Batch zum halben Preis an. Bei Anthropic sind die meisten Batches binnen einer Stunde fertig, bei OpenAI gilt ein 24-Stunden-Fenster; die Grenzen liegen bei 100.000 Anfragen oder 256 MB (Anthropic) und 50.000 Anfragen oder 200 MB je Datei (OpenAI) @anthropic2026batch @openai2026batch. Beim Caching kostet Speichern das 1,25-Fache (5 Minuten) oder das Doppelte (1 Stunde) des normalen Eingabepreises, Lesen das 0,1-Fache, bei Opus und Sonnet 5.5 nur das 0,05-Fache @anthropic2026pricing. Batch ist bei beiden Anbietern nicht "Zero Data Retention"-fähig (ZDR: Inhalte landen nicht in Missbrauchs-Protokollen), siehe Datenschutz.

=== Was ein Lauf kostet

Die Rechnung hat vier Schritte. *Erstens* zählst du die Token pro Anfrage: Item-Text und Antwort. *Zweitens* addierst du das gemeinsame Codebuch am Anfang, zum billigen Lesepreis bei einem Cache-Treffer, sonst zum Schreibpreis. *Drittens* multiplizierst du mit dem Preis je Million Token (Eingabe und Ausgabe unterscheiden sich). *Viertens* halbierst du bei Batch und schlägst einen regionalen Aufschlag drauf, falls es einen gibt (Anthropic `inference_geo` "us": das 1,1-Fache). Als Code (`hit` ist der Anteil der Cache-Treffer, `d` der Batch-Faktor 0,5 oder 1, `r` der regionale Faktor):

#datei("cost.py")[```python
def cost_usd(n, prefix, item, out, p_in, p_out,
             p_hit, p_write, hit, d=1.0, r=1.0):
    plain = item * p_in + out * p_out
    cached = prefix * (hit * p_hit
                       + (1 - hit) * p_write)
    return d * r * n * (plain + cached) / 1e6
```]

Ohne Caching zählst du das Codebuch zum Item-Text. Das Notebook hat dieselbe Rechnung.

#beispiel(titel: [20.000 Texte mit Claude Sonnet 5.5])[
  Preise je Million Token (Stand: 11. November 2026): 2 USD Eingabe, 10 USD Ausgabe, 0,10 USD Cache-Treffer, 2,50 USD Schreiben (5 Minuten), 4 USD Schreiben (1 Stunde) @anthropic2026pricing. Codebuch 2.000 Token, Text 400, Antwort 60. Eine Anfrage hat 2.400 Eingabe-Token und 60 Ausgabe-Token: 2.400 mal 2 plus 60 mal 10 USD je Million, also 0,0054 USD, mal 20.000 sind 108 USD. Mit Batch die Hälfte, 54 USD. Mit 5-Minuten-Cache und 90 % Treffern: 8 Mio. Item-Token zu 2 USD sind 16 USD, 1,2 Mio. Ausgabe-Token zu 10 USD sind 12 USD, 36 Mio. gelesene Codebuch-Token zu 0,10 USD sind 3,60 USD, 4 Mio. geschriebene zu 2,50 USD sind 10 USD. Summe 41,60 USD, halbiert 20,80 USD.
]

@k10-tab-kosten zeigt alle Szenarien. Bei nur 30 % Treffern ist der 1-Stunden-Cache teurer als Batch ohne Cache.

#figure(
  table(columns: (1fr, auto),
    table.header([Szenario], [Kosten in USD]),
    [Standard, ohne Cache], [108,00],
    [Batch, ohne Cache], [54,00],
    [Batch, 5-Minuten-Cache, 90 % Treffer], [20,80],
    [Batch, 1-Stunden-Cache, 90 % Treffer], [23,80],
    [Batch, 5-Minuten-Cache, 30 % Treffer], [49,60],
    [Batch, 1-Stunden-Cache, 30 % Treffer], [70,60],
  ),
  kind: table, supplement: [Tab.],
  caption: [Kosten des Beispiels (20.000 Texte) in sechs Szenarien.],
) <k10-tab-kosten>

#rechnung(titel: [Ab wann lohnt sich der Cache?])[
  Betrachte nur das Codebuch, je Million Token. Ohne Cache kostet es 2 USD. Mit 5-Minuten-Cache und 50 % Treffern kostet es im Schnitt halb 0,10 und halb 2,50, also 0,05 plus 1,25 gleich 1,30 USD: günstiger. Bei 20 % Treffern sind es 0,02 plus 2,00 gleich 2,02 USD: knapp teurer. Die Schwelle liegt bei etwa 21 % Treffern (5-Minuten-Cache) und etwa 51 % (1-Stunden-Cache) und hängt nur von den Preisen ab.
]

Die Trefferquote in Batches ist Glückssache: Anthropic nennt "typisch" 30 bis 98 % @anthropic2026batch. Miss sie in einem Pilotlauf mit 1 bis 5 % der Items, bevor du den teuren Lauf startest.

== LLM-gestützte Literaturreviews

Ein systematischer Review folgt einer festen Abfolge: Frage, Schlüsselwörter und Datenbanken, Suchstrings, Suche ausführen, Titel und Abstracts sichten, Daten aus den Volltexten ziehen (@k10-fig-review). Eine Übersichtsarbeit (Scoping-Review) von Lieberum et al. (Stand: Februar 2024) fand 196 Berichte, davon 37 zu LLMs. Modelle wurden in 10 von 13 Schritten ausprobiert, am häufigsten bei Suche (41 %), Auswahl (38 %) und Datenextraktion (30 %). Ihr Fazit: mit Vorsicht, für klar begrenzte Aufgaben, unter menschlicher Aufsicht @lieberum2024large.

#figure(
  diagram(spacing: (4mm, 5mm),
    fknoten((0, 0), [Frage], col: c-blue, filled: true, w: 22mm),
    fknoten((1, 0), [Keywords und \ Datenbanken], col: c-blue, w: 24mm),
    fknoten((2, 0), [Such- \ strings], col: c-blue, w: 22mm),
    fknoten((3, 0), [Ausführen \ und Export], col: c-blue, w: 24mm),
    fknoten((4, 0), [Titel und \ Abstracts], col: c-blue, w: 24mm),
    fknoten((5, 0), [Daten \ extrahieren], col: c-blue, filled: true, w: 24mm),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"), edge((3, 0), (4, 0), "-|>"), edge((4, 0), (5, 0), "-|>"),
    node((2, 1), text(font: "Inter", size: 7.5pt, fill: c-grey.darken(20%))[Suche: 41 %], stroke: none),
    node((4, 1), text(font: "Inter", size: 7.5pt, fill: c-grey.darken(20%))[Auswahl: 38 %], stroke: none),
    node((5, 1), text(font: "Inter", size: 7.5pt, fill: c-grey.darken(20%))[Extraktion: 30 %], stroke: none),
  ),
  caption: [Schritte eines Reviews und Anteil der LLM-Studien, die dafür ein Modell nutzten @lieberum2024large.],
) <k10-fig-review>

=== Sichten und Extrahieren

Die wichtigste Kennzahl heißt *Sensitivität*: Von allen Arbeiten, die wirklich in den Review gehören, wie viele findet der Screener? Das ist der Recall aus _Das Nötigste vorab_.

#beispiel(titel: [Eine Sensitivität von 0,73])[
  Ein Review hat 2.000 Treffer, davon 100 wirklich relevante. Ein Modell sichtet Titel und Abstracts mit Sensitivität 0,73, dem Wert aus Dai et al. @dai2025accuracy. Es findet 73 der 100 und übersieht 27. Die Arbeitsersparnis ist groß, aber ein gutes Viertel der Evidenz fehlt, und zwar dort, wo das Modell systematisch anders urteilt als ein Mensch.
]

Die Studienlage ist uneinheitlich (@k10-tab-screening). Beim Preprint otto-SR nennen Abstract und Ergebnisteil verschiedene Zahlen (96,7 % und 96,6 % gegenüber 81,7 % und 87,3 % für Menschen), ein Beispiel, warum man Preprints nachrechnet @cao2025automation. Bei Dai et al. gab es 0,98 nur mit Prompts, die nach Sicht der Ergebnisse überarbeitet wurden @dai2025accuracy.

#figure(
  table(columns: (auto, 1fr, 1fr),
    table.header([Studie], [Wert], [Einschränkung]),
    [*otto-SR (2025)*], [96,7 % gegenüber 81,7 % für Menschen], [Preprint, Abstract und Ergebnisteil weichen ab],
    [*Dai et al. (2025)*], [0,73 Titel/Abstract, 0,87 Volltext], [0,98 nur mit nachträglich geänderten Prompts],
    [*Figalova et al. (2026)*], [etwa 83 % in Batches, 66,8 % "alle auf einmal"], [zwei identische Läufe widersprachen sich bei 29 von 316 geeigneten Datensätzen],
  ),
  kind: table, supplement: [Tab.],
  caption: [Drei Studien zum Sichten @cao2025automation @dai2025accuracy @figalova2026evaluating.],
) <k10-tab-screening>

Die Position der Lehrveranstaltung: Das Modell ist ein *zweiter Screener*, dessen Sensitivität du auf einer von Menschen gelabelten Stichprobe misst, nie der alleinige. Prompt und Batching legst du in der Preregistration fest. Für die Extraktion (Fakten wie Stichprobengröße aus Papers in eine Tabelle ziehen) fanden Gartlehner et al. mit Claude 2 96,3 % Genauigkeit über 160 Datenelemente aus 10 Studien, bei erneuter Frage gab es zu 96,9 und 95,0 % dieselbe Antwort (_Test-Retest_) @gartlehner2024data. Khraisha et al. sahen nur "moderate" Übereinstimmung jenseits des Zufalls @khraisha2024can. Berichte darum auch hier die Wiederholbarkeit, nicht nur die Genauigkeit.

=== Erfundene Quellen

Das schwerste Risiko ist die erfundene Referenz: echt klingende Autoren, plausibler Titel, manchmal ein Link auf ein ganz anderes Paper. Bei Walters und Wilder waren in 84 kurzen Reviews mit 636 Zitaten etwa 55 % (GPT-3.5) und 18 % (GPT-4) erfunden, und von den echten hatten 43 % und 24 % inhaltliche Fehler, meist falsche Zahlen @walters2023fabrication. Rao et al. prüften 2026 über 220.000 Links von Modellen und Agenten: 5 bis 18 % ließen sich nicht auflösen, Deep-Research-Agenten schnitten schlechter ab als Modelle mit Websuche, ein URL-Prüfer drückte den Anteil auf unter 1 % @rao2026detecting.

#fallstrick[
  Ein funktionierender Link ist noch keine richtige Quelle. Öffne jede Referenz und prüfe, ob die zitierte Aussage dort steht. Die Pflicht dazu liegt bei dir, nicht beim Werkzeug @europeancommission2026living.
]

Programmatisch lässt sich vorsortieren: Eine Abfrage der DOI bei Crossref zeigt, ob sie existiert und ob der Titel passt (zehn Zeilen mit `urllib`). Das findet nur offensichtliche Fälle. Beim Berichten eines LLM-gestützten Reviews gilt zusätzlich zu PRISMA-Flussdiagramm (der Standardform für Reviews), Suchstrings mit Datum und Werkzeugversionen @Page2021: Modell-Snapshot, Prompts, Batching-Strategie, Sensitivität auf der Gold-Stichprobe, Übereinstimmung zwischen Läufen und Ergebnis der Referenzprüfung angeben.

== Berichten: Leitlinien und Methodenteil

Zu schreiben, eine Studie habe "GPT verwendet", ist so, als würde man schreiben, ein Experiment habe "einen Computer verwendet" @haindl2027research. Ein Methodenteil nennt: genaues Modell und Version, Datum des Zugriffs, alle Prompts samt Systemanweisung, tatsächlich gesendete Einstellungen, Zahl der Wiederholungen und den Umgang mit der Streuung. Nach IMRAD (Einleitung, Methoden, Ergebnisse, Diskussion) gehört die Rolle des LLM in die Einleitung, die Technik in die Methoden, die Streuung über Läufe in die Ergebnisse, Drift und Abschaltung in die Diskussion.

Dazu gibt es Checklisten (@k10-tab-leitlinien): Wähle die deines Fachs und ergänze REFORMS für den allgemeinen ML-Teil.

#figure(
  table(columns: (auto, auto, 1fr),
    table.header([Leitlinie], [Fach], [Umfang]),
    [*llm-guidelines.org*], [Software Engineering], [7 Studientypen, 8 Leitlinien mit "must" und "should"],
    [*TRIPOD-LLM*], [Biomedizin], [19 Hauptitems, 50 Unteritems, modular],
    [*GUIDE-LLM*], [Verhaltens- und Sozialwissenschaft], [14 Items in 7 Gruppen],
    [*CHART*], [Chatbots für Gesundheitsauskunft], [12 Items, 39 Unteritems],
    [*REFORMS*], [Wissenschaft mit maschinellem Lernen], [32 Items in 8 Abschnitten, nicht LLM-spezifisch],
  ),
  kind: table, supplement: [Tab.],
  caption: [Berichtsleitlinien (Stand: 11. November 2026) @baltes2025guidelines @gallifant2025tripodllm @feuerriegel2026reporting @huo2025reporting @kapoor2024reforms.],
) <k10-tab-leitlinien>

Bei llm-guidelines.org zählt jedes Modalverb. Zwingend ("must") sind Modellversion samt Datum der Durchführung und alle Prompts. Empfohlen ("should") sind Wiederholungen mit Bericht der Verteilung, Temperatur 0 nicht als Garantie zu behandeln, ein offenes LLM unter den Modellen und Inferenzstatistik (Tests, Konfidenzintervalle) mit Effektgrößen @baltes2025guidelines. Das offene Modell ist also kein Muss. Allen Leitlinien gemeinsam: Rolle des LLM nennen, Version und Konfiguration angeben, Prompts veröffentlichen, gegen Menschen validieren, Nichtdeterminismus ansprechen. Weil sie mehr verlangen als Verlage, folgst du der strengeren Regel.

Für ein proprietäres Modell fordern Palmer, Smith und Spirling eine ausdrückliche Begründung, weil Firmen Algorithmen "at any time" ändern oder unzugänglich machen können @palmer2024using. Dein Absatz sagt, warum das geschlossene Modell nötig ist (etwa weil du es selbst untersuchst oder Spitzenleistung brauchst) und welche offenen du verglichen hast.

== Ethik, Policy und Recht

Dieser Abschnitt hat den Stand 11. November 2026 und ist Orientierung, keine Rechtsberatung. Das Lehrbuch fasst die Ethik der KI-Nutzung in drei Pflichten @haindl2027research: *Offenlegen*, welches Modell für welche Aufgabe in welcher Phase genutzt wurde. *Nie als Autor nennen*, denn Autorschaft heißt, für die Arbeit geradezustehen. *Prüfen*, weil ein Modell Zitate erfinden oder einen Test empfehlen kann, dessen Voraussetzungen deine Daten verletzen: Solche Fehler werden zu deinen eigenen.

Die Verlage sind sich in der Grundlinie einig und unterscheiden sich im Ort der Offenlegung (@k10-tab-verlage). Elsevier und Springer Nature verbieten zudem KI-erzeugte Forschungsbilder.

#figure(
  table(columns: (auto, 1fr, 1fr),
    table.header([Stelle], [Autorschaft], [Wo offenlegen]),
    [*Elsevier*], [KI kann nicht Autor sein], [eigene Erklärung; Forschungsnutzung in den Methoden],
    [*Springer Nature*], [LLMs erfüllen die Kriterien nicht], [Methodenteil],
    [*IEEE*], [nicht geregelt], [Danksagung, mit System und betroffenen Abschnitten],
    [*ACM*], [dürfen nicht als Autoren stehen], [Danksagung],
    [*COPE*], [können keine Verantwortung übernehmen], [Materials and Methods],
  ),
  kind: table, supplement: [Tab.],
  caption: [Regeln zu generativer KI @elsevier2026generative @springernature2026artificial @ieee2024author @acm2023policy @cope2024authorship.],
) <k10-tab-verlage>

Die Living Guidelines der EU-Kommission (4. Ausgabe vom 15. Oktober 2026) verlangen zusätzlich: KI ist nie (Mit-)Autor, wesentliche Nutzung wird samt Prüfschritten offengelegt, unveröffentlichte oder sensible Arbeiten werden nicht ohne Zusicherung der Nicht-Weiterverwendung hochgeladen, jede KI-erzeugte Referenz wird geprüft. "In case of doubt, disclosure is advised." Agenten dürfen nur "advanced research tools, not independent scientists" sein @europeancommission2026living.

*EU AI Act, Artikel 4.* Anbieter und Betreiber von KI-Systemen müssen Maßnahmen treffen, die die KI-Kompetenz ihres Personals unterstützen. Der Artikel gilt seit 2. Februar 2025. Durch den Digital Omnibus (Verordnung (EU) 2026/1744 vom 8. Juli 2026, in Kraft seit 27. Juli 2026) wurde aus der Pflicht, ein ausreichendes Niveau sicherzustellen, die Pflicht, die Entwicklung zu unterstützen. Die Aufsicht der nationalen Behörden beginnt am 2. August 2026. Ein Zertifikat ist nicht nötig, eine interne Dokumentation der Schulung genügt @europeancommission2026article @europeancommission2026ai @europeanparliament2026regulation. Eine Gruppe, die eine LLM-API nutzt, ist in dieser Lesart ein *Betreiber* (_deployer_: setzt ein KI-System ein, baut es aber nicht). So legt es die Lehrveranstaltung aus.

*Datenschutz.* Wer personenbezogene Daten an eine API schickt, braucht eine Rechtsgrundlage. Der Europäische Datenschutzausschuss (EDPB) hält in Stellungnahme 28/2024 fest: Keine Rechtsgrundlage steht über den anderen, das berechtigte Interesse braucht einen dreistufigen Test, und ob ein Modell anonym ist, wird im Einzelfall entschieden @edpb2024opinion. Praktisch heißt das: vor dem Upload pseudonymisieren und nur Nötiges senden, keine kostenlosen Tarife für Personendaten, wenn möglich EU-Verarbeitung oder ein lokales Open-Weight-Modell.

Die Anbieter unterscheiden sich (Stand: 11. November 2026). Bei OpenAI werden API-Daten ohne Opt-in nicht zum Training genutzt, Missbrauchs-Protokolle bis zu 30 Tage aufbewahrt; Batches sind nicht ZDR-fähig, der EU-Endpunkt braucht eine Genehmigung @openai2026data. Anthropic hält Batches 29 Tage und schließt sie von ZDR aus, eine EU-Region ist auf der Preisseite nicht aufgeführt @anthropic2026batch @anthropic2026pricing. Bei Google fließen Inhalte im kostenlosen Tarif in die Produktverbesserung ein, im bezahlten nicht @google2026geminipricing. Daraus folgt ein Zielkonflikt: Batch ist billig, aber nicht ZDR-fähig, lokale Inferenz ist datenschutzfreundlich, aber womöglich schwächer. Entschärfen lässt er sich, wenn Rohdaten lokal bleiben und nur pseudonymisierte Texte zur API gehen.

*Die Menschen hinter den Daten.* Gold-Labels stammen von Menschen, oft online bezahlten Crowdworkern. Faire Bezahlung ist nötig, aber nicht genug: Wer belastende Inhalte labeln lässt, muss die psychische Belastung bedenken @Shmueli2021. Berichte außerdem den Rechenaufwand @Strubell2019.

#hoersaal([Bin ich als Studierende selbst an Artikel 4 gebunden?], [
  Die Pflicht trifft Anbieter und Betreiber, also die Hochschule oder Forschungsgruppe, und laut Kommission auch Personen, die in deren Auftrag arbeiten. Ob und wie Studierende darunterfallen, hängt von der Konstellation ab, das ist eine Rechtsfrage. Sicher ist: Der Artikel verlangt seit dem Omnibus kein bestimmtes Niveau mehr vom Einzelnen, sondern Maßnahmen der Organisation @europeancommission2026article.
])

== In der Praxis: Checkliste für dein Projekt

+ Schreibe Design, Hypothesen, Metrik, Zahl der Läufe und Umfang der Gold-Stichprobe auf und friere sie mit Datum ein.
+ Wähle einen datierten Snapshot, trage das Abschalt-Datum ein, plane einen Replikationsarm mit offenen Gewichten und lege Prompts, Codebuch, Parser und Konfiguration mit Hash ins Repository.
+ Mache einen Pilotlauf mit 1 bis 5 % der Items (Token, Cache-Treffer, Parser-Fehler, Kosten), dann den Produktivlauf, am besten als Batch. Lade die Ergebnisse sofort herunter und schreibe pro Lauf ein Manifest.
+ Lasse `verify_run()` vor jeder Auswertung laufen und miss die Stabilität mit mindestens 10 Läufen.
+ Validiere gegen Gold-Labels, korrigiere die Endergebnisse (Kapitel 5 und 6) und wiederhole das Probe-Set am Ende.
+ Pseudonymisiere vor jedem API-Aufruf, kläre Datenschutz und Anbieterregeln, berichte nach der Leitlinie deines Fachs, lege die KI-Nutzung offen und prüfe jede Referenz.

== Für die Lehre

*"Temperatur 0 heißt immer dieselbe Antwort."* Zeichne die Kette aus @k10-fig-batch an die Tafel und rechne das Rundungsbeispiel durch. Danach ist klar, dass der Server nicht nur deine Anfrage rechnet.

*"Reproduzierbar heißt, das Modell antwortet wieder gleich."* Re-Analysierbarkeit aus Rohantworten ist etwas anderes als ein wiederholter Aufruf. Der Cache-Teil im Notebook macht den Unterschied erlebbar.

*"Mehr Läufe machen TAR besser."* Umgekehrt: TAR\@N sinkt mit N. Mehr Läufe machen die Messung ehrlicher, nicht den Wert höher.

*"Caching spart immer."* Die Kostentabelle mit 30 % Treffern ist das Gegenbeispiel, die Rechnung passt auf die Tafel.

Zeitkritisches (Preise, Versionen, Rechtsstand) gehört am Tag der Lehrveranstaltung geprüft.

#kurz[
  Ein gehostetes Modell ändert sich still, antwortet zufällig anders und verschwindet nach etwa einem Jahr: Behandle es als Instrument mit Version und Verfallsdatum.
][
  Drei Quellen der Schwankung: gewolltes Sampling, numerisches Rauschen auch bei Temperatur 0 und Drift. Gegen jede hilft etwas anderes.
][
  TAR\@N misst, bei wie vielen Items alle N Läufe dasselbe liefern; TARa vergleicht das Label, TARr den Rohtext, und N muss beim Vergleich gleich sein.
][
  Acht Stufen, jede mit einer Datei: Hashes, ein Manifest pro Lauf und unveränderte Rohantworten machen jede Zahl prüfbar.
][
  Batch halbiert den Preis, Caching lohnt sich erst ab einer Mindest-Trefferquote: mit Grundrechenarten rechnen, im Pilot messen.
][
  In Reviews ist das Modell ein zweiter Screener mit gemessener Sensitivität, und jede Referenz wird geöffnet. Berichte nach der Leitlinie deines Fachs, lege KI-Nutzung offen und schütze die Personen in den Daten.
]

#selbsttest(
  ([Nenne die drei Quellen unterschiedlicher Antworten und je ein Gegenmittel.], [Sampling (mehrfach laufen lassen), numerisches Rauschen (wiederholen und vergleichen, lokal stabiles Setup), Drift (datierten Snapshot nutzen, Probe-Set am Anfang und Ende).]),
  ([Warum liefert ein Server bei Temperatur 0 nicht immer dasselbe?], [Die Rundung hängt von der Reihenfolge der Rechenschritte ab, die von der Batch-Größe und damit der Serverlast. Ein anderes Wort kippt, wenn zwei Kandidaten fast gleich wahrscheinlich sind.]),
  ([Berechne TARr\@3 und TARa\@3: Item 1 "ja, ja, ja"; Item 2 "nein, Nein., nein"; Item 3 "ja, nein, ja"; Item 4 "Antwort: ja, ja, ja". Der Parser entfernt "Antwort:", Satzzeichen und Großschreibung.], [Roh stimmt nur Item 1 überein: 1 von 4, also 25 %. Nach dem Parser stimmen die Items 1, 2 und 4 überein: 3 von 4, also 75 %.]),
  ([Was kosten 20.000 Texte im Batch mit 5-Minuten-Cache und 90 % Treffern, und warum kann Caching teurer sein?], [Etwa 20,80 USD statt 54 USD ohne Cache. Bei geringer Trefferquote (beim 5-Minuten-Cache unter etwa 21 %) zahlst du das teurere Schreiben öfter, als das billige Lesen einspart.]),
  ([Ein Modell sichtet 100 relevante Arbeiten mit Sensitivität 0,73. Wie viele übersieht es, und welche Rolle sollte es haben?], [Es übersieht 27. Es sollte ein zweiter Screener sein, dessen Sensitivität auf einer von Menschen gelabelten Stichprobe gemessen und berichtet wird.]),
)

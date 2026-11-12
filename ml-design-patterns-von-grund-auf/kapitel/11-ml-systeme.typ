#import "../lib.typ": *
#import "@preview/cetz-plot:0.1.2": plot, chart

#let gruen = rgb("#2EAE7D")
#let orange = rgb("#B5651D")
#let orange-hell = rgb("#FBF1E6")
#let gruen-hell = rgb("#E4F5EE")
#let nebel = luma(240)

// Ausschnitt aus einer Code-Datei: ab der ersten Zeile mit `ab` bis vor die erste folgende Zeile mit `bis`.
// Der gezeigte Code ist damit zeichengleich mit der ausgeführten Datei.
#let code-aus(datei, ab, bis: none) = {
  let zeilen = read(datei).split("\n")
  let a = zeilen.position(z => z.contains(ab))
  let b = if bis == none { zeilen.len() } else { a + 1 + zeilen.slice(a + 1).position(z => z.contains(bis)) }
  block(breakable: false, raw(zeilen.slice(a, b).join("\n").trim("\n", at: end), lang: "python", block: true))
}
// Echte Ausgabe eines Laufs als Konsolenfenster, davor der Befehl.
#let ausgabe(befehl, datei, von: 0, bis: none) = {
  let z = read(datei).trim("\n", at: end).split("\n")
  block(breakable: false, raw("$ " + befehl + "\n" + z.slice(von, bis).join("\n"), lang: "terminal", block: true))
}
// Wie `ausgabe`, aber mit ausgewählten Zeilen; Lücken werden mit "..." markiert.
#let ausgabe-zeilen(befehl, datei, indizes) = {
  let z = read(datei).trim("\n", at: end).split("\n")
  let aus = ()
  let letzte = -1
  for i in indizes {
    if letzte >= 0 and i > letzte + 1 { aus.push("...") }
    aus.push(z.at(i))
    letzte = i
  }
  block(breakable: false, raw("$ " + befehl + "\n" + aus.join("\n"), lang: "terminal", block: true))
}
#let knoten(pos, body, farbe: blau, grund: blau-hell, ..args) = node(pos, body, stroke: farbe, fill: grund, ..args)
#let neben(pos, body, ..args) = node(pos, body, stroke: 0.6pt + luma(150), fill: nebel, ..args)
#let klein(body) = text(size: 8.5pt, fill: grau, body)
#show figure.where(kind: table): set block(breakable: true)

= ML-Systeme in Produktion

Ein Notebook beantwortet die Frage, ob sich aus diesen Daten ein brauchbares Modell trainieren lässt. Ein produktives ML-System beantwortet eine andere: Liefert das Modell in drei Monaten, nach zwei Änderungen an den Datenquellen, einem Teamwechsel und einem Serverausfall noch brauchbare Vorhersagen, und merken wir es, wenn nicht? Für einen Software Engineer ist das vertrautes Gelände. Man kennt Deployments, Tests, Monitoring und Rollbacks. Neu ist, dass in einem ML-System nicht nur Code, sondern auch Daten das Verhalten bestimmen, und dass Fehler leise auftreten: Das System wirft keine Exception, es liefert plausibel aussehende, falsche Zahlen.

Die Kapitel zu den Patterns haben diese einzeln behandelt. Dieses Kapitel setzt sie zusammen. Es beschreibt, was ein ML-System über das Modell hinaus enthält, wie reif der Betrieb sein kann (die Reifegrade des MLOps), welche Werkzeuge und Tests es dafür gibt und wo die Patterns in diesem Gesamtbild stehen. Wir bleiben beim Lieferdienst aus Pattern 16, damit alle Beispiele auf derselben Datengrundlage laufen. Wo dieses Kapitel ein Pattern nur erwähnt, steht die Nummer in Klammern; die Erklärung findet sich im jeweiligen Kapitel.

#kasten([Lernziele.], [
  Nach diesem Kapitel können Sie erklären, warum der Modellcode nur einen kleinen Teil eines ML-Systems ausmacht und welche technische Schuld daraus folgt, die drei MLOps-Reifegrade nach Google Cloud sowie CI, CD und CT unterscheiden, Experimente und Modelle mit MLflow ablegen, Daten mit einem Schema prüfen, die vier Testkategorien des ML Test Score anwenden, Drift mit PSI und KS-Test erkennen und deren Grenzen benennen, Shadow, Canary und A/B-Test unterscheiden und jedes der 30 Patterns einer Station im Betrieb zuordnen.
])

== Vom Notebook zum System

In klassischer Software legt der Code das Verhalten fest. Bei einem ML-System entsteht es aus drei Dingen zugleich: dem Trainingscode, den Trainingsdaten und der Konfiguration (Hyperparameter, Zufallsstartwert, Merkmalsauswahl). Ändert sich eines davon, ändert sich das Modell, auch wenn niemand eine Zeile Code anfasst: Es genügt, dass eine Datenquelle ihr Format leicht ändert. Man kann das Modell als Build-Artefakt verstehen, dessen Quelltext zu großen Teilen aus Daten besteht, und diese Quelle ändert sich ohne Commit.

Daraus folgen drei Eigenheiten. Erstens gibt es keine Spezifikation im üblichen Sinn: Ein Test kann nicht „die Lieferzeit ist 27 Minuten“ prüfen, nur statistische Erwartungen („der mittlere Fehler liegt unter 2,5 Minuten“). Zweitens altert ein Modell, ohne dass sich an ihm etwas ändert, weil sich die Welt ändert, aus der seine Eingaben kommen. Drittens sind die Fehler leise: Ein Modell mit falschen Eingaben rechnet trotzdem und gibt eine Zahl zurück. Das Risiko schleichender Wartungsprobleme ist entsprechend hoch, und genau das hat eine Gruppe bei Google 2015 systematisch beschrieben.

== Hidden Technical Debt

=== Die Aussage des Papiers

Der Begriff *Technical Debt* stammt von Ward Cunningham @cunningham_wycash_1992: Schnell geschriebener Code ist wie ein Kredit, er bringt sofort Tempo und kostet dauerhaft Zinsen in Form von Mehraufwand bei jeder Änderung, bis man die Schuld tilgt. #cite(<sculley_hidden_debt_2015>, form: "prose") argumentieren, dass ML-Systeme diese Schuld besonders leicht anhäufen, weil sie alle Wartungsprobleme normaler Software haben und zusätzlich solche, die erst auf Ebene des Gesamtsystems sichtbar werden. Das Papier ist eine Sammlung von Beobachtungen aus der Praxis bei Google, keine Studie mit Messreihen; seine Stärke ist ein präzises Vokabular für Probleme, die jeder kennt, der ein ML-System betrieben hat.

Das berühmteste Bild des Papiers zeigt den ML-Code als kleinen Kasten in der Mitte, umgeben von einer weitaus größeren Infrastruktur (@abb-sculley). Die Autoren schätzen, dass in reifen Systemen höchstens fünf Prozent des Codes eigentlicher ML-Code sind und mindestens 95 Prozent Verbindungscode (*Glue Code*). Das ist eine Schätzung aus Erfahrung, keine Messung, aber die Größenordnung deckt sich mit der Praxis: Das Modell ist oft ein `fit()`-Aufruf, der Rest ist Datenbeschaffung, Prüfung, Auslieferung und Überwachung.

#figure(
  canvas(length: 1cm, {
    import draw: *
    let feld(x0, y0, x1, y1, t) = {
      rect((x0, y0), (x1, y1), fill: nebel, stroke: 0.6pt + luma(150), radius: 2pt)
      content(((x0 + x1) / 2, (y0 + y1) / 2), text(size: 9pt, t))
    }
    rect((0, 0), (15.4, 7.4), stroke: 0.6pt + luma(190), radius: 3pt)
    feld(0.2, 5.6, 5.1, 7.2, [Datenerfassung])
    feld(5.25, 5.6, 10.2, 7.2, [Datenprüfung])
    feld(10.35, 5.6, 15.2, 7.2, [Feature-Extraktion])
    feld(0.2, 3.75, 3.6, 5.45, [Konfiguration])
    feld(0.2, 1.85, 3.6, 3.6, [Ressourcen-\ verwaltung])
    feld(11.8, 3.75, 15.2, 5.45, [Analyse-\ werkzeuge])
    feld(11.8, 1.85, 15.2, 3.6, [Prozess-\ verwaltung])
    feld(0.2, 0.2, 7.6, 1.7, [Serving-Infrastruktur])
    feld(7.75, 0.2, 15.2, 1.7, [Monitoring])
    rect((6.5, 3.35), (9.0, 4.65), fill: blau-hell, stroke: blau, radius: 2pt)
    content((7.75, 4.0), text(size: 9pt, weight: "bold")[ML-Code])
    content((7.75, 5.0), text(size: 8.5pt, fill: grau)[(maßstabsgetreu wäre der Kasten noch kleiner)])
  }),
  caption: [ Ein ML-System besteht überwiegend aus Umgebung. Die Darstellung folgt Abbildung 1 bei @sculley_hidden_debt_2015; die Beschriftungen sind übersetzt und frei gruppiert.],
) <abb-sculley>

=== Entanglement und das CACE-Prinzip

Die erste ML-eigene Form der Schuld heißt *Entanglement*, Verflechtung. In einem klassischen System kann man eine Komponente austauschen, solange ihre Schnittstelle gleich bleibt. Ein Modell hat diese Isolation nicht, denn es lernt die Merkmale *gemeinsam*. Die Autoren fassen das im Prinzip *CACE* zusammen: Changing Anything Changes Everything. Fügt man ein Merkmal hinzu, entfernt eines oder verändert die Verteilung eines Merkmals, kann sich das Verhalten bei allen übrigen verschieben. Das gilt nicht nur für Eingaben, sondern auch für Hyperparameter, Stichprobenverfahren und Abbruchkriterien.

Das lässt sich im Kleinen zeigen. Wir ergänzen die Lieferdaten um ein Merkmal `routing_min`, die Fahrzeitschätzung eines externen Routing-Dienstes. Der Dienst kennt die tatsächliche Strecke samt Umweg, die Luftlinie `distanz_km` nicht. Beide Merkmale sind also stark korreliert, und das Modell verteilt das Gewicht auf sie:

#code-aus("../code/11-ml-systeme/cace_abhaengigkeiten.py", "train, test = daten", bis: "# Derselbe Dienst")

#ausgabe("uv run --with scikit-learn --with pandas --with numpy python cace_abhaengigkeiten.py", "../code/11-ml-systeme/cace_abhaengigkeiten.out.txt", bis: 3)

Ohne das neue Merkmal gewichtet das Modell einen Kilometer mit 2,88 Minuten, mit dem neuen nur noch mit 0,27. Das Gewicht der Distanz ist nicht „falsch“ geworden, es hat sich verschoben, weil ein anderes Merkmal einen Teil der Information übernimmt. Wer in diesem Modell die Bedeutung von `distanz_km` erklären will, muss wissen, was sonst noch im Modell steckt. Die Gegenmaßnahmen im Papier sind pragmatisch: Modelle isolieren, etwa als Ensemble getrennt trainierter Teilmodelle, und Veränderungen im Vorhersageverhalten sichtbar machen, bevor eine Änderung live geht. Beides setzt Werkzeuge voraus, die wir weiter unten besprechen.

=== Datenabhängigkeiten kosten mehr als Codeabhängigkeiten

Die zweite Form betrifft die Eingabedaten. Das Papier hält fest, dass Datenabhängigkeiten ähnlich teuer sind wie Codeabhängigkeiten, aber schwerer zu erkennen, weil Compiler und Linter sie nicht prüfen.

*Instabile Datenabhängigkeiten* entstehen, wenn ein Eingabesignal von einem System kommt, das sich ändert, typischerweise von einem anderen Modell, das sein Team verbessert, ohne uns zu informieren. Wir nehmen an, dass der Routing-Dienst nach einem Update 25 Prozent längere Fahrzeiten schätzt:

#code-aus("../code/11-ml-systeme/cace_abhaengigkeiten.py", "# Derselbe Dienst nach einem Update")

#ausgabe-zeilen("uv run --with scikit-learn --with pandas --with numpy python cace_abhaengigkeiten.py", "../code/11-ml-systeme/cace_abhaengigkeiten.out.txt", (4, 5, 6))

Das Modell mit dem externen Merkmal war vor dem Update das bessere (2,63 gegen 3,71 Minuten) und ist danach das deutlich schlechtere (5,63). Niemand hat das Modell geändert, kein Test schlägt an, die Eingaben sind formal gültig. Die Antwort des Software Engineerings lautet: Abhängigkeiten pinnen. Für Datensignale heißt das, eine versionierte Kopie zu verwenden (Pattern 26, Feature Store) und die Verteilung zu überwachen. *Nicht genutzte Datenabhängigkeiten* sind das Gegenstück: Merkmale, die kaum etwas zur Genauigkeit beitragen, aber Abhängigkeiten schaffen, etwa Altlasten früherer Modellversionen. Das Papier empfiehlt, durch Weglassen einzelner Merkmale regelmäßig zu prüfen, ob jedes seinen Platz verdient.

#figure(
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (24mm, 9mm),
    neben((0, 0), [Routing-Dienst \ #klein[anderes Team]]),
    knoten((1, 0), [Merkmal \ `routing_min`]),
    knoten((2, 0), [Lieferzeit-Modell]),
    knoten((3, -1), [App]),
    knoten((3, 0), [Disposition]),
    knoten((3, 1), [Abrechnung \ #klein[nicht bekannt]], farbe: orange, grund: orange-hell),
    edge((0, 0), (1, 0), "->", label: text(fill: orange)[Update: +25 %], label-side: left, stroke: orange),
    edge((1, 0), (2, 0), "->"),
    edge((2, 0), (3, -1), "->"), edge((2, 0), (3, 0), "->"),
    edge((2, 0), (3, 1), "->", stroke: (paint: orange, dash: "dashed")),
  )),
  caption: [Zwei Formen von Schuld in einem Bild. Links die instabile Datenabhängigkeit: Der Dienst ändert sich, das Modell bemerkt es nicht. Rechts der undeklarierte Konsument: Die Abrechnung liest die Vorhersagen, ohne dass das Modellteam davon weiß.],
) <abb-systeme-abhaengigkeiten>

Das Bild zeigt noch eine dritte Form, die *undeklarierten Konsumenten*: Vorhersagen sind leicht zugänglich, irgendwann liest sie ein System, von dem das Modellteam nichts weiß, und jede Modelländerung wird zur Änderung für Unbekannte. Es ist die undokumentierte Nutzung einer API, und die Antwort ist dieselbe: eine definierte Schnittstelle mit Authentifizierung und Protokollierung. Schlüssel in den Vorhersagen (Pattern 20) machen sichtbar, wer was abgefragt hat.

=== Glue Code, Pipeline Jungles und weitere Anti-Patterns

*Glue Code* ist der Code, der Daten zwischen allgemeinen Bibliotheken und dem eigenen System hin- und herschiebt: Spalten umbenennen, Formate umwandeln, Ergebnisse umpacken. Das Papier rät, solche Pakete hinter einer einheitlichen Schnittstelle zu kapseln; das entspricht dem bekannten Adapter-Muster @gamma_design_patterns_1994. *Pipeline Jungles* sind der Spezialfall in der Datenvorbereitung: Mit jeder neuen Quelle und jedem neuen Merkmal kommt ein Schritt hinzu, bis niemand mehr das Ganze versteht und Tests kaum möglich sind. Das Papier empfiehlt, Datensammlung und Merkmalsberechnung als Ganzes zu entwerfen; das Pattern 25 (Workflow Pipeline) macht aus einer losen Folge von Skripten einen benannten, versionierbaren, testbaren Ablauf. Weitere Formen sind tote experimentelle Codepfade, Konfigurationsschuld, Rückkopplungsschleifen (das Modell beeinflusst die Daten, auf denen es später trainiert wird) und fest einprogrammierte Schwellenwerte in einer Welt, in der sich Verteilungen ändern. @tab-schuld ordnet die Formen ihren Gegenstücken zu.

#figure(
  table(
    columns: (auto, 1fr, auto),
    align: (left, left, left),
    [*Schuldform*], [*Entspricht im klassischen Software Engineering*], [*Patterns*],
    [Entanglement (CACE)], [Starke Kopplung über gemeinsamen Zustand: eine Änderung wirkt überall], [7, 18],
    [Undeklarierte Konsumenten], [Undokumentierte Nutzer einer API], [20, 27],
    [Instabile Datenabhängigkeit], [Ungepinnte Version einer Bibliothek], [21, 26],
    [Glue Code], [Wildwuchs aus Adaptern ohne gemeinsame Schnittstelle], [16, 21],
    [Pipeline Jungle], [Gewachsene Build-Skripte ohne Struktur und Tests], [25, 26],
    [Tote Codepfade], [Feature-Flags, die nie entfernt wurden], [25, 27],
    [Rückkopplung], [Regelkreis, dessen Ausgang den eigenen Eingang verändert], [18, 30],
  ),
  caption: [Formen technischer Schuld nach @sculley_hidden_debt_2015, ihre Gegenstücke im Software Engineering und die Patterns, die sie mildern. Die Zuordnung der Patterns ist eine Einschätzung dieses Handbuchs, keine Aussage des Papiers.],
) <tab-schuld>

== MLOps und seine Reifegrade

=== CI, CD und CT

*MLOps* bezeichnet die Übertragung der DevOps-Praxis auf ML-Systeme: Entwicklung und Betrieb sollen nicht zwei getrennte Welten sein, und alles, was sich automatisieren lässt, wird automatisiert. Den bekanntesten Leitfaden dazu hat Google Cloud veröffentlicht @googlecloud_mlops_2020. Er greift die drei Begriffe aus der Continuous-Delivery-Welt @humble_continuous_delivery_2010 auf und erweitert sie um einen vierten Gedanken, der in klassischer Software keine Entsprechung hat.

*Continuous Integration (CI)* heißt bei ML nicht nur, Code zu testen und zu bauen, sondern auch Daten, Schemata und Modelle. *Continuous Delivery (CD)* betrifft nicht mehr ein einzelnes Softwarepaket, sondern ein System: die Trainingspipeline, die ihrerseits ein Modell als Dienst bereitstellt. Neu ist *Continuous Training (CT)*, das automatische Neutrainieren und Bereitstellen von Modellen. Das hat kein Gegenstück in normaler Software, denn ein Webshop wird nicht dadurch schlechter, dass die Zeit vergeht. Ein Modell schon. Ausgelöst wird CT durch einen Zeitplan, neue Daten, nachlassende Qualität oder erkannten Drift.

=== Level 0, 1 und 2

Der Leitfaden unterscheidet drei Reifegrade. Sie sind keine Pflichtstufen, sondern beschreiben, wie viel des Weges vom Notebook zum betriebenen System automatisiert ist (@abb-mlops).

#figure(
  {
    set text(size: 8.5pt)
    let kopf(t) = block(above: 1.1em, below: 0.4em, text(weight: "bold", t))
    let d(..args) = align(center, diagram(node-inset: 5pt, node-corner-radius: 3pt, ..args))
    kopf[Level 0: manueller Prozess]
    d(
      spacing: (12mm, 6mm),
      knoten((0, 0), [Notebook: Daten, \ Training, Evaluation], farbe: orange, grund: orange-hell),
      neben((1, 0), [Modell- \ datei]),
      knoten((2, 0), [Prediction \ Service]),
      neben((3, 0), [Monitoring: \ kaum oder keins]),
      edge((0, 0), (1, 0), "->", label: klein[manuell], label-side: left),
      edge((1, 0), (2, 0), "->", label: klein[manuell], label-side: left),
      edge((2, 0), (3, 0), "-->"),
    )
    kopf[Level 1: automatisierte Pipeline (Continuous Training)]
    d(
      spacing: (8mm, 6mm),
      neben((0, 0), [Trigger: \ #klein[Zeit, Daten, \ Drift]]),
      knoten((1, 0), [Daten- \ validierung]),
      knoten((2, 0), [Training]),
      knoten((3, 0), [Modell- \ validierung]),
      knoten((4, 0), [Registry, \ Service], farbe: gruen, grund: gruen-hell),
      node(enclose: ((1, 0), (3, 0)), inset: 7pt, stroke: (paint: blau, dash: "dashed"), fill: none, snap: -1, corner-radius: 4pt),
      neben((2, 1), [Feature Store, Metadata Store]),
      edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"), edge((3, 0), (4, 0), "->"),
      edge((2, 1), (2, 0), "<->", stroke: 0.6pt + luma(150)),
    )
    kopf[Level 2: zusätzlich CI/CD für die Pipeline selbst]
    d(
      spacing: (8mm, 6mm),
      neben((0, 0), [Quellcode- \ verwaltung]),
      knoten((1, 0), [CI: bauen, \ testen]),
      knoten((2, 0), [CD: Pipeline \ ausrollen]),
      knoten((3, 0), [Pipeline \ aus Level 1]),
      knoten((4, 0), [Prediction \ Service], farbe: gruen, grund: gruen-hell),
      edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"), edge((3, 0), (4, 0), "->"),
    )
  },
  caption: [Die drei Reifegrade nach @googlecloud_mlops_2020, vereinfacht. Orange: manuell; blau gestrichelt: automatisch wiederholte Pipeline; grün: bereitgestelltes Ergebnis. In Level 2 läuft die Pipeline aus Level 1 weiterhin und wird vom Monitoring neu angestoßen.],
) <abb-mlops>

*Level 0* ist der manuelle Prozess. Analyse, Aufbereitung, Training, Evaluation und Auslieferung laufen als einzelne, oft interaktive Schritte. Ein Data Scientist übergibt eine Modelldatei an das Engineering, das sie als Dienst bereitstellt. Releases sind selten (im Leitfaden: wenige pro Jahr), CI und CD gibt es nicht, und ausgeliefert wird nur das Modell, nicht das System. Das genügt, solange sich Modelle selten ändern. Das Risiko liegt in der Übergabe: Notebook und Dienst sind zwei Implementierungen, dazwischen entsteht Training-Serving Skew (Pattern 21 verhindert ihn), und das Monitoring fehlt häufig.

*Level 1* automatisiert die ML-Pipeline für kontinuierliches Training. Der Unterschied: Ausgeliefert wird nicht mehr ein Modell, sondern die Trainingspipeline, die wiederkehrend läuft und das Modell selbst bereitstellt. Dazu kommen eine *Datenvalidierung* (ändert sich das Schema, hält die Pipeline an; ändern sich die Werte, stößt sie ein Neutrainieren an), eine *Modellvalidierung* (das neue Modell wird offline gegen das aktuelle und auf Teilmengen geprüft, online per Canary oder A/B), ein optionaler *Feature Store* gegen Skew (Pattern 26) und ein *Metadata Store*, der festhält, welche Pipelineversion mit welchen Parametern lief und wo das Vorgängermodell liegt. Ausgelöst wird auf Abruf, nach Zeitplan, bei neuen Daten, bei sinkender Qualität oder bei erkanntem Drift.

*Level 2* ergänzt eine CI/CD-Strecke für die Pipeline selbst. Level 1 setzt eine stabile Pipeline voraus, Level 2 erlaubt, auch sie schnell und zuverlässig zu ändern: neue Merkmale, Architekturen, Hyperparameter. Die Auslieferung durchläuft Stufen: automatisch in der Testumgebung, halbautomatisch in der Vorproduktion, in Produktion manuell ausgelöst nach mehreren erfolgreichen Läufen. Manuell bleiben laut Leitfaden die Analyse der Daten und des Modells.

Die Reifegrade sind ein Orientierungsrahmen, kein Ziel um jeden Preis. Ein Modell, das einmal im Jahr neu trainiert wird, rechtfertigt keinen Orchestrator; eines, dessen Qualität jede Woche sinkt, schon. Die Frage lautet: Wie schnell veraltet unser Modell, und was kostet jede Woche Verzögerung? Pattern 18 liefert die Messung. In Patterns ausgedrückt kommt Level 0 mit der Auslieferung aus (16, 17, 20). Level 1 braucht zusätzlich Pattern 25 (Workflow Pipeline), 21 (Transform), 22 (Repeatable Splitting) für vergleichbare Läufe, 27 (Model Versioning) für die Registry und 18 als Auslöser. Level 2 ergänzt Freigabeprüfungen wie 28 (Heuristic Benchmark) als Mindestschwelle und 30 (Fairness Lens) als Kriterium sowie 15 (Hyperparameter Tuning) als automatisierten Schritt.

== Experiment Tracking und Model Registry

Wer vierzig Trainingsläufe gemacht hat, fragt sich irgendwann, welche Parameter, Daten und welcher Code zu dem Modell mit dem MAE (mittlerer absoluter Fehler in Minuten) von 2,31 gehörten. Ein *Experiment Tracker* beantwortet das, indem er jeden Lauf mit Parametern, Kennzahlen und Artefakten festhält. Eine *Model Registry* verwaltet die auslieferbaren Modelle als versionierte Objekte, vergleichbar mit einem Paketregister.

MLflow @zaharia_mlflow_2018 @mlflow_docs ist dafür das verbreitetste quelloffene Werkzeug. *Tracking* speichert Läufe (Runs) eines Experiments mit Parametern, Metriken und Artefakten. *Models* beschreiben ein Modell in einem einheitlichen Format mit Flavors (etwa `sklearn`), sodass Werkzeuge es laden können, ohne das Trainingsframework zu kennen. Die *Model Registry* verwaltet benannte Modelle mit Versionen, Tags und Aliasen; statt der früheren Stufen „Staging“ und „Production“ empfiehlt die Dokumentation inzwischen Aliase. Das Beispiel trainiert drei Varianten, protokolliert sie, registriert die beste und lädt sie über einen Alias, lokal mit SQLite als Datenbank. Gezeigt sind die Läufe und die Registry; die Abfrage der Läufe steht in der Datei.

#code-aus("../code/11-ml-systeme/mlflow_tracking.py", "# 1) Drei", bis: "# 2)")

#code-aus("../code/11-ml-systeme/mlflow_tracking.py", "# 3) Das beste")

#ausgabe("uv run --with mlflow --with scikit-learn --with pandas --with numpy python mlflow_tracking.py", "../code/11-ml-systeme/mlflow_tracking.out.txt")

Die Tabelle ist nach dem Fehler sortiert. Das einfachste Modell (50 Bäume, Tiefe 2) ist mit 2,26 Minuten das schlechteste, das mit 100 Bäumen und Tiefe 3 mit 2,03 das beste. Dass 300 Bäume nicht besser sind (2,05), ist eine nützliche Beobachtung für sich: Mehr Aufwand zahlt sich nicht automatisch aus. Das beste Modell wurde als Version 1 von `lieferzeit` registriert, und die letzte Zeile lädt es über den Alias und liefert eine Vorhersage. Weil Parameter, Kennzahl und Modell zusammen gespeichert sind, lässt sich die Wahl später nachvollziehen.

#figure(
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (14mm, 5mm),
    neben((0, 0), [Lauf 1 \ #klein[MAE a]]),
    neben((0, 1), [Lauf 2 \ #klein[MAE b]]),
    neben((0, 2), [Lauf 3 \ #klein[MAE c]]),
    knoten((1, 1), [Registry \ `lieferzeit`]),
    knoten((2, 0), [Version 1 \ #klein[Alias `champion`]], farbe: gruen, grund: gruen-hell),
    knoten((2, 2), [Version 2 \ #klein[Alias `challenger`]]),
    knoten((3, 1), [Serving \ #klein[`@champion`]]),
    edge((0, 0), (1, 1), "->"), edge((0, 1), (1, 1), "->"), edge((0, 2), (1, 1), "->"),
    edge((1, 1), (2, 0), "->"), edge((1, 1), (2, 2), "->"),
    edge((2, 0), (3, 1), "->"), edge((2, 2), (3, 1), "-->"),
  )),
  caption: [Läufe, Registry und Serving. Das Serving lädt nur den Alias. Ein neues Modell geht live, indem der Alias umgehängt wird (gestrichelt); ein Rollback ist dieselbe Operation in die andere Richtung. Versionen und Aliase sind ein Beispiel.],
) <abb-registry>

Der Alias entkoppelt Serving und Training, ganz wie ein Symlink bei einer Software-Auslieferung. Das ist die konkrete Form von Pattern 27 (Model Versioning): Versionen sind unveränderlich und eindeutig, die Frage „welche Version läuft gerade?“ hat genau eine Antwort, und ein Rollback verlangt kein neues Training (im ML Test Score ist das Infrastruktur-Test 7).

#achtung[Das Laden von Modelldateien ist nicht harmlos. `pickle` und Verwandte (`joblib`, `cloudpickle`) können beim Laden beliebigen Code ausführen. MLflow 3 nutzt für sklearn-Modelle deshalb standardmäßig skops, das nur ausdrücklich vertraute Typen lädt, und hat unser Modell (eigene Funktion, Baumstrukturen) abgelehnt; im Beispiel wählen wir für das eigene Modell bewusst `cloudpickle`. Man lädt nie Modelldateien aus unbekannter Quelle.]

== Datenvalidierung

Das Modell ist nur so zuverlässig wie seine Daten, und Daten ändern sich ohne Ankündigung. Eine *Datenvalidierung* prüft, ob ein Datenbestand die Erwartungen erfüllt: Spalten, Typen, Wertebereiche, Anteile fehlender Werte, Verteilungen. Sie ist das Gegenstück zur Eingabevalidierung einer API, prüft aber meist ganze Batches und kann daher auch statistische Aussagen prüfen („im Mittel liegt die Distanz zwischen 3 und 12 km“). Geprüft wird an drei Stellen (@abb-validierung): am Eingang der Pipeline gegen Fehler der Datenquelle, vor dem Training, damit kein Modell aus fehlerhaften Daten lernt, und im Serving, bevor fehlerhafte Anfragen das Modell erreichen.

#figure(
  text(size: 9pt, diagram(
    node-inset: 6pt, node-corner-radius: 3pt, spacing: (13mm, 10mm),
    neben((0, 0), [Quellsysteme]),
    knoten((1, 0), [Rohdaten]),
    knoten((2, 0), [Trainings- \ daten]),
    knoten((3, 0), [Modell]),
    knoten((4, 0), [Anfragen \ im Betrieb]),
    knoten((1, 1), [Prüfung 1: \ Eingang], farbe: orange, grund: orange-hell),
    knoten((2, 1), [Prüfung 2: \ vor dem Training], farbe: orange, grund: orange-hell),
    knoten((4, 1), [Prüfung 3: \ im Serving], farbe: orange, grund: orange-hell),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->", label: klein[Aufbereitung], label-side: left), edge((2, 0), (3, 0), "->"), edge((4, 0), (3, 0), "->"),
    edge((1, 1), (1, 0), "->", stroke: orange), edge((2, 1), (2, 0), "->", stroke: orange), edge((4, 1), (4, 0), "->", stroke: orange),
  )),
  caption: [Drei Stellen für Datenvalidierung. Alle drei verwenden dasselbe Schema als gemeinsamen Vertrag.],
) <abb-validierung>

Mit pandera @bantilan_pandera_2020, einer Python-Bibliothek zur Validierung von DataFrames, sieht ein solcher Vertrag für unsere Bestelldaten so aus:

#code-aus("../code/11-ml-systeme/daten_validierung.py", "class Bestellungen", bis: "def pruefen")

Das Schema steht in einer Klasse und ist damit versionierbar, reviewbar und testbar. `strict` lehnt unbekannte Spalten ab, `coerce = False` verbietet stille Typumwandlung, `lazy=True` sammelt alle Verstöße. Wir prüfen einen sauberen Batch, einen mit vier eingebauten Fehlern und einen, in dem das Quellsystem plötzlich Meilen statt Kilometer liefert:

#code-aus("../code/11-ml-systeme/daten_validierung.py", "def pruefen", bis: "X = lieferdaten")

#ausgabe("uv run --with pandera --with pandas --with numpy --with scikit-learn python daten_validierung.py", "../code/11-ml-systeme/daten_validierung.out.txt")

Batch B wird vollständig erkannt: negative Distanz, Stunde 24, unzulässige Regenkategorie und unerwartete Spalte. Batch C besteht die Prüfung, obwohl er falsch ist. Meilen sind ebenso positive Zahlen unter 30, und die mittlere Distanz fällt von 7,8 auf 4,8, bleibt also im erlaubten Bereich. Das ist die wichtigste Lehre dieses Abschnitts: Ein Schema prüft, was man vorher als Regel aufschreiben konnte. Fehler, die jede Regel einhalten und nur die Verteilung verschieben, findet erst der Vergleich mit einer Referenzverteilung, also das Monitoring.

*Einordnung.* TensorFlow Data Validation (TFDV), die Validierungskomponente von TFX, folgt demselben Gedanken @breck_data_validation_2019 @baylor_tfx_2017: Es berechnet Statistiken, leitet daraus ein Schema ab, das ein Mensch nachbessert, prüft neue Daten dagegen und vergleicht Verteilungen zwischen Training und Serving (Skew) sowie zwischen aufeinanderfolgenden Tagen (Drift). Great Expectations @greatexpectations_docs formuliert Erwartungen als deklarative Aussagen in Suiten, prüft Datenquellen (auch SQL-Datenbanken) gegen sie und erzeugt lesbare Berichte. pandera ist leichtgewichtig und passt, wo ohnehin pandas läuft. Wichtiger als das Werkzeug ist, dass der Vertrag existiert, versioniert wird und im Betrieb tatsächlich blockiert.

== Testen von ML-Systemen

Wie testet man ein System, dessen richtiges Verhalten man nicht aufschreiben kann? #cite(<breck_ml_test_score_2017>, form: "prose") haben bei Google dazu den *ML Test Score* veröffentlicht: 28 konkrete Tests und Überwachungsaufgaben in vier Kategorien zu je sieben (Features und Daten, Modellentwicklung, ML-Infrastruktur, Monitoring). Die Autoren haben sie mit den Betreibern von 36 Systemen bei Google durchgesprochen. @tab-mlts gibt sie in eigenen Worten wieder.

Die Punktevergabe ist einfach: ein halber Punkt, wenn ein Test manuell durchgeführt und das Ergebnis dokumentiert und verteilt wird, ein ganzer, wenn ein System ihn wiederholt automatisch ausführt. Die Punkte werden je Kategorie addiert, und die Gesamtwertung ist das *Minimum* der vier Summen. Das erzwingt Ausgewogenheit: Wer die Daten perfekt, die Infrastruktur gar nicht prüft, bekommt null. Ein erfundenes Beispiel: 4,5 Punkte bei den Daten, 3,0 beim Modell, 2,0 bei der Infrastruktur und 1,5 beim Monitoring ergeben einen Score von 1,5. Nach der Interpretationstabelle der Autoren heißt ein Wert über 1 bis 2 „erster Schritt zur Produktionsreife, weitere Investitionen nötig“, und ab über 3 beginnt „starke Automatisierung, geeignet für unternehmenskritische Systeme“.

#block(breakable: false)[
#figure(
  {
    set text(size: 8.5pt)
    set par(leading: 0.5em)
    table(
      columns: (1fr, 1fr, 1fr, 1fr),
      align: top + left,
      inset: (x: 0.5em, y: 0.4em),
      [*Features und Daten*], [*Modellentwicklung*], [*ML-Infrastruktur*], [*Monitoring*],
      [*1 Erwartungen an Features stehen in einem Schema.*], [1 Modellspezifikation wird per Review geprüft und eingecheckt.], [*1 Training ist reproduzierbar.*], [1 Änderungen an Abhängigkeiten lösen Benachrichtigungen aus.],
      [2 Jedes Feature ist nützlich.], [2 Offline-Kennzahlen korrelieren mit der Wirkung online.], [2 Modellspezifikation ist unit-getestet.], [*2 Invarianten der Eingabedaten gelten.*],
      [3 Kein Feature ist zu teuer.], [3 Alle Hyperparameter sind getunt.], [3 Pipeline ist integrationsgetestet.], [3 Training und Serving laufen nicht auseinander.],
      [4 Features erfüllen übergeordnete Vorgaben.], [4 Der Einfluss veralteter Modelle ist bekannt.], [4 Modellqualität wird vor dem Serving geprüft.], [4 Modelle sind nicht zu alt.],
      [5 Datenschutz in der Pipeline ist angemessen.], [*5 Ein einfacheres Modell ist nicht besser.*], [5 Das Modell ist debugbar.], [*5 Modelle sind numerisch stabil.*],
      [6 Neue Features lassen sich schnell ergänzen.], [*6 Qualität auf wichtigen Teilmengen reicht.*], [6 Modelle laufen vor dem Serving als Canary.], [6 Rechenleistung hat sich nicht verschlechtert.],
      [7 Code zur Feature-Berechnung ist getestet.], [7 Inklusion (Fairness) ist getestet.], [7 Rollback auf frühere Versionen ist möglich.], [*7 Vorhersagequalität hat sich nicht verschlechtert.*],
    )
  },
  caption: [Die 28 Tests des ML Test Score in eigener Übersetzung, nach @breck_ml_test_score_2017. Fett: im Code dieses Kapitels umgesetzt.],
) <tab-mlts>
]

Vieles ist bekanntes Handwerk an neuer Stelle. *Unit-Tests* gehören an den Feature-Code, denn ein Fehler dort ist im Modell kaum zu erkennen (zum Beispiel: Gehört 20 Uhr zur Abendspitze?). *Datentests* prüfen das Schema. *Modelltests* prüfen Verhalten statt Ausgaben: Der CheckList-Ansatz von #cite(<ribeiro_checklist_2020>, form: "prose") für Sprachmodelle, der sich übertragen lässt, unterscheidet Mindestfunktionalität, Invarianz (irrelevante Änderungen ändern die Ausgabe nicht) und Richtungserwartung (eine Änderung bewegt die Ausgabe in eine bekannte Richtung). *Infrastrukturtests* prüfen, ob Training reproduzierbar ist und das ausgelieferte Artefakt dasselbe tut wie das trainierte Modell. Die Datei `test_modell.py` setzt zehn Tests für unser Lieferzeit-Modell um; zwei im Ausschnitt, in normalem pytest-Code:

#code-aus("../code/11-ml-systeme/test_modell.py", "@pytest.mark.parametrize", bis: "def test_regen")

#code-aus("../code/11-ml-systeme/test_modell.py", "def test_extrapolation_distanz", bis: "# --- 3.")

#ausgabe-zeilen("uv run --with scikit-learn --with pandas --with numpy --with pytest pytest -q --tb=line test_modell.py", "../code/11-ml-systeme/test_modell.out.txt", (0, 2, 6))

Neun Tests bestehen, einer schlägt fehl, und das ist beabsichtigt. `test_extrapolation_distanz` formuliert eine fachliche Erwartung: Jeder zusätzliche Kilometer kostet Zeit, auch über die Trainingsdaten hinaus. Das Boosting-Modell hat Distanzen nur bis 15 km gesehen und liefert für 25 km exakt dieselbe Vorhersage wie für 15 km (43,3 Minuten): Baumverfahren extrapolieren nicht, sie halten jenseits des Trainingsbereichs den letzten Wert. Der Test macht eine Eigenschaft sichtbar, die man sonst erst bemerkt, wenn der Lieferdienst sein Gebiet erweitert. Im Alltag löscht man ihn nicht, sondern markiert ihn als bekanntes Problem oder ergänzt ein lineares Teilmodell für lange Strecken. Der Test auf Teilmengen stellt sicher, dass eine gute Gesamtkennzahl keine schlechte Untergruppe versteckt, und der Vergleich mit einer Faustformel ist im Kern Pattern 28 (Heuristic Benchmark) als automatisierter Wächter.

== Monitoring

=== Drei Ebenen

Monitoring fragt auf mehreren Ebenen, ob das System noch tut, was es soll. Die erste kennt jeder Software Engineer: Antwortet der Dienst, wie schnell, mit wie vielen Fehlern? Die übrigen sind ML-spezifisch und unterscheiden sich vor allem darin, *wann* sie ein Signal liefern (@tab-monitoring).

#figure(
  table(
    columns: (auto, 1fr, auto),
    align: (left, left, left),
    [*Ebene*], [*Frage und typische Kennzahlen*], [*Labels nötig?*],
    [System], [Läuft der Dienst? Latenz, Fehlerrate, Durchsatz, Speicher], [nein],
    [Daten], [Sehen die Eingaben aus wie im Training? Schemaverstöße, fehlende Werte, Verteilungsvergleich je Merkmal (PSI, KS-Test, siehe unten)], [nein],
    [Vorhersagen], [Verhält sich das Modell wie gewohnt? Verteilung der Vorhersagen, PSI der Vorhersage], [nein],
    [Qualität], [Stimmen die Vorhersagen? MAE, Genauigkeit, auch je Teilmenge], [ja, verzögert],
  ),
  caption: [Vier Ebenen des Monitorings. Nur die letzte braucht die tatsächlichen Ergebnisse (Labels), und die liegen oft erst spät vor.],
) <tab-monitoring>

Der Grund für die Staffelung ist das Label-Problem: Ob die Lieferzeitvorhersage stimmte, weiß man erst nach der Lieferung, bei einem Kreditmodell nach Monaten oder nie. Die Daten- und Vorhersageebene liefern sofort Signale, wenn auch indirekte: Sie sagen nicht, dass das Modell schlechter ist, sondern dass sich etwas geändert hat, das es sein könnte. Pattern 18 (Continued Model Evaluation) führt beide Wege zusammen und zeigt in einer Simulation über 24 Wochen, dass Eingabe-Alarm und Qualitätsverlust unabhängig voneinander auftreten können. Dort stehen auch die Begriffe: Beim *Covariate Shift* ändert sich die Verteilung der Eingaben, beim *Concept Drift* der Zusammenhang mit dem Ergebnis @gama_concept_drift_2014 @moreno_torres_dataset_shift_2012. Eingabetests erkennen nur den ersten Fall.

=== PSI und KS-Test

Zwei Verfahren vergleichen eine Verteilung mit einer Referenz. Der *Population Stability Index* teilt den Wertebereich in Klassen (Dezile der Referenz, also zehn gleich stark besetzte Klassen; bei wenigen Werten jeder Wert) und vergleicht die Anteile $p_i$ der Referenz mit den aktuellen $q_i$:
$ "PSI" = sum_i (q_i - p_i) dot ln(q_i / p_i) $
Er ist null bei gleichen Verteilungen und wächst mit der Abweichung. Üblich sind die Faustregeln unter 0,1 stabil, bis 0,25 Warnung, darüber Alarm; sie stammen aus der Kreditrisikomodellierung und haben keine statistische Begründung. Der *Kolmogorov-Smirnov-Test* (KS-Test) nimmt den größten Abstand der kumulativen Verteilungsfunktionen zweier Stichproben:
$ D = max_x |F_"ref" (x) - F_"akt" (x)| $
Er liefert zusätzlich einen p-Wert, die Wahrscheinlichkeit, einen mindestens so großen Abstand zu sehen, wenn beide Stichproben in Wahrheit aus derselben Verteilung stammen. Beide Verfahren sind auf einzelne Merkmale zugeschnitten; #cite(<rabanser_failing_loudly_2019>, form: "prose") vergleichen Kombinationen aus Dimensionsreduktion und Zwei-Stichproben-Tests für viele Merkmale gleichzeitig.

Wir simulieren drei Produktionswochen mit je 3 000 Bestellungen gegen die 5 000 des Trainings. Woche 1 ist sauber. In Woche 2 hat die Datenerfassung einen Zeitzonenfehler: Die Stunde wird um zwei verschoben gespeichert, alle Werte bleiben gültige Uhrzeiten. In Woche 3 hat der Lieferdienst sein Gebiet erweitert, die Distanzen reichen bis 22 statt 15 km.

#code-aus("../code/11-ml-systeme/monitoring.py", "def psi", bis: "def bewertung")

#ausgabe-zeilen("uv run --with scikit-learn --with pandas --with numpy --with scipy python monitoring.py", "../code/11-ml-systeme/monitoring.out.txt", (0, 2, 3, 4, 5, 6, 8, 9, 10, 11, 13, 14, 15, 16))

Woche 1 liegt überall unter 0,02. In Woche 2 meldet der PSI der Stunde 1,94, einen klaren Alarm bei sonst unauffälligen Merkmalen. Das Schema hätte das nicht gefunden: 8 bis 20 sind gültige Uhrzeiten. Der Fehler wirkt sich aber aus, denn die Abendspitze fällt auf die falschen Stunden, und der MAE steigt von 2,0 auf 3,0 Minuten. Der PSI der Vorhersage bleibt dabei bei 0,003: Das Vorhersage-Monitoring sieht Verschiebungen, nicht jeden Fehler. In Woche 3 schlagen Distanz (0,54) und Vorhersage (0,36) an, der MAE steigt auf 3,95 Minuten. Jenseits von 15 km kennt das Modell keine Beispiele, wie der Test oben vorhergesagt hat.

#let stunden = csv("../code/11-ml-systeme/stunde_verteilung.csv").slice(1).map(z => z.map(float))
#let distanzen = csv("../code/11-ml-systeme/distanz_verteilung.csv").slice(1).map(z => z.map(float))

#figure(
  grid(
    columns: (1fr, 1fr), column-gutter: 8pt,
    canvas(length: 1cm, {
      import draw: *
      set-style(axes: (stroke: 0.5pt + luma(120)))
      plot.plot(
        size: (6.4, 3.6), x-label: [Stunde (gespeichert)], y-label: [Anteil],
        x-min: 7, x-max: 23, y-min: 0, y-max: 0.14, x-tick-step: 2, y-tick-step: 0.04,
        legend: "north", legend-style: (orientation: ltr, item: (spacing: 0.3)),
        {
          plot.add(stunden.map(z => (z.at(0), z.at(1))), mark: "o", mark-size: 0.08, style: (stroke: blau + 1.2pt), mark-style: (fill: blau, stroke: none), label: [Referenz])
          plot.add(stunden.map(z => (z.at(0), z.at(2))), mark: "o", mark-size: 0.08, style: (stroke: orange + 1.2pt), mark-style: (fill: orange, stroke: none), label: [Woche 2])
        },
      )
    }),
    canvas(length: 1cm, {
      import draw: *
      set-style(axes: (stroke: 0.5pt + luma(120)))
      plot.plot(
        size: (6.4, 3.6), x-label: [Distanz in km (Klassenmitte)], y-label: [Anteil],
        x-min: -1, x-max: 23, y-min: 0, y-max: 0.16, x-tick-step: 4, y-tick-step: 0.04,
        legend: "north", legend-style: (orientation: ltr, item: (spacing: 0.3)),
        {
          plot.add(distanzen.map(z => (z.at(0) + 1, z.at(1))), mark: "o", mark-size: 0.08, style: (stroke: blau + 1.2pt), mark-style: (fill: blau, stroke: none), label: [Referenz])
          plot.add(distanzen.map(z => (z.at(0) + 1, z.at(2))), mark: "o", mark-size: 0.08, style: (stroke: orange + 1.2pt), mark-style: (fill: orange, stroke: none), label: [Woche 3])
        },
      )
    }),
  ),
  caption: [Links: Verteilung der gespeicherten Stunde in der Referenz und in Woche 2 (Zeitzonenfehler, um zwei Stunden verschoben). Rechts: Verteilung der Distanz in Klassen von 2 km in der Referenz und in Woche 3 (erweitertes Gebiet). Werte aus `monitoring.py`.],
) <abb-drift>

=== Wann ein Alarm ein Alarm ist

Die Tests liefern Zahlen, keine Entscheidungen, und drei Eigenschaften machen sie heikel. Die erste ist die *Abhängigkeit von der Stichprobengröße*: Ein Signifikanztest beantwortet, ob ein Unterschied existiert, nicht ob er relevant ist, und bei genug Daten ist jeder Unterschied „signifikant“. Wir haben die Distanz um 0,05 km verschoben, 0,3 Prozent des Wertebereichs, und den KS-Test je Stichprobengröße 20-mal wiederholt:

#ausgabe-zeilen("uv run --with scikit-learn --with pandas --with numpy --with scipy python monitoring.py", "../code/11-ml-systeme/monitoring.out.txt", (18, 19, 20, 21))

Bei 1 000 Beobachtungen schlägt der Test fast nie an, bei einer Million immer, obwohl die Verschiebung dieselbe und bedeutungslos klein ist. Deshalb sind Effektmaße (PSI, KS-Abstand $D$) mit Schwellen verlässlicher als der p-Wert allein, und man verlangt zusätzlich, dass die Abweichung über mehrere Zeitfenster anhält. Die zweite Eigenschaft ist das *Mehrfachtest-Problem*: Wer 50 Merkmale mit 5 Prozent Signifikanzniveau prüft, erwartet je Fenster etwa 2,5 Fehlalarme, auch wenn alles in Ordnung ist. Die dritte ist die *Handlungsfähigkeit*: Ein Alarm, auf den niemand reagieren kann oder muss, wird ignoriert. Jeder Alarm braucht einen Verantwortlichen und eine hinterlegte Reaktion (Datenquelle prüfen, neu trainieren, zurückrollen oder bewusst nichts tun). Die Abschnitte dieses Kapitels entsprechen den Monitoring-Aufgaben 2 (Invarianten der Eingabedaten) und 7 (Vorhersagequalität) des ML Test Score.

== Rollout-Strategien

Ein offline besseres Modell ist nicht automatisch online besser: Die Offline-Kennzahl ist ein Stellvertreter für die eigentliche Wirkung (Test Model 2 im ML Test Score), und Trainings- und Produktionsdaten unterscheiden sich fast immer. Deshalb liefert man neue Modelle schrittweise aus. Drei Strategien beantworten verschiedene Fragen (@abb-rollout).

#figure(
  {
    set text(size: 8.5pt)
    grid(
      columns: (1fr, 1fr, 1fr), column-gutter: 6pt, align: top,
      [*Shadow*\ #diagram(
        node-inset: 4pt, node-corner-radius: 3pt, spacing: (14mm, 7mm),
        neben((0, 0), [Anfrage]),
        knoten((0, 1), [Router]),
        knoten((-0.6, 2), [Altes \ Modell], farbe: gruen, grund: gruen-hell),
        neben((0.6, 2), [Neues \ Modell]),
        neben((0.6, 3), [Vergleich im Log]),
        node((-0.6, 3), [Antwort], stroke: none),
        edge((0, 0), (0, 1), "->"), edge((0, 1), (-0.6, 2), "->"), edge((0, 1), (0.6, 2), "-->"),
        edge((-0.6, 2), (-0.6, 3), "->"), edge((0.6, 2), (0.6, 3), "-->"),
      )],
      [*Canary*\ #diagram(
        node-inset: 4pt, node-corner-radius: 3pt, spacing: (14mm, 7mm),
        neben((0, 0), [Anfrage]),
        knoten((0, 1), [Router]),
        knoten((-0.6, 2), [Altes \ Modell], farbe: gruen, grund: gruen-hell),
        knoten((0.6, 2), [Neues \ Modell], farbe: orange, grund: orange-hell),
        node((0, 3), [Antwort], stroke: none),
        edge((0, 0), (0, 1), "->"),
        edge((0, 1), (-0.6, 2), "->", label: klein[95 %], label-side: right),
        edge((0, 1), (0.6, 2), "->", label: klein[5 %], label-side: left),
        edge((-0.6, 2), (0, 3), "->"), edge((0.6, 2), (0, 3), "->"),
      )],
      [*A/B-Test*\ #diagram(
        node-inset: 4pt, node-corner-radius: 3pt, spacing: (14mm, 7mm),
        neben((0, 0), [Nutzer]),
        knoten((0, 1), [Zufällige \ Zuteilung]),
        knoten((-0.6, 2), [A: altes \ Modell]),
        knoten((0.6, 2), [B: neues \ Modell]),
        knoten((0, 3), [Geschäfts- \ kennzahl], farbe: gruen, grund: gruen-hell),
        edge((0, 0), (0, 1), "->"),
        edge((0, 1), (-0.6, 2), "->", label: klein[50 %], label-side: right),
        edge((0, 1), (0.6, 2), "->", label: klein[50 %], label-side: left),
        edge((-0.6, 2), (0, 3), "->"), edge((0.6, 2), (0, 3), "->"),
      )],
    )
  },
  caption: [Drei Rollout-Strategien. Shadow: Das neue Modell sieht alle Anfragen, doch nur das alte antwortet. Canary: Ein kleiner Anteil der echten Antworten kommt vom neuen Modell. A/B-Test: Zufällig getrennte Gruppen werden über eine Geschäftskennzahl verglichen.],
) <abb-rollout>

*Shadow* (auch Traffic Mirroring) leitet jede Anfrage zusätzlich an das neue Modell, verwirft aber dessen Antwort: reale Eingaben, echte Latenzen und Vorhersagen ohne Nutzerwirkung; sobald die Ergebnisse bekannt sind, vergleicht man beide Modelle Anfrage für Anfrage. Die Grenze: Shadow verrät nichts über die Reaktion der Nutzer und verdoppelt die Rechenlast. *Canary* gibt dem neuen Modell einen kleinen Anteil des echten Verkehrs, etwa ein Prozent, und steigert ihn stufenweise, solange Schutzgrößen (Fehlerrate, Latenz, Vorhersageverteilung) im Rahmen bleiben; sonst rollt das System zurück. Canary erkennt grobe Probleme schnell, kann aber wegen der kleinen Stichprobe kleine Verbesserungen nicht nachweisen. Das leistet der *A/B-Test*: Nutzer werden zufällig getrennten Gruppen zugeteilt, jede sieht ein Modell, verglichen wird eine Geschäftskennzahl. #cite(<kohavi_trustworthy_experiments_2020>, form: "prose") behandeln die Fallen ausführlich; die wichtigsten sind, nach Nutzer statt nach Anfrage zuzuteilen, die Laufzeit vorher festzulegen statt ständig nachzusehen und zu prüfen, ob die Gruppen im geplanten Verhältnis befüllt wurden.

Wie lange ein A/B-Test dauern muss, lässt sich vorab ausrechnen. Wir vergleichen das alte Modell (lineare Regression ohne Abendspitze) mit dem Boosting-Modell; Zielgröße ist der Anteil der Lieferungen, bei denen die Vorhersage höchstens drei Minuten abweicht (eine vereinfachte Kennzahl; im echten Test stünde hier eher eine Geschäftsgröße wie Beschwerden oder Stornos):

#code-aus("../code/11-ml-systeme/rollout.py", "def n_pro_gruppe", bis: "def zeile")

#ausgabe("uv run --with scikit-learn --with pandas --with numpy --with scipy python rollout.py", "../code/11-ml-systeme/rollout.out.txt")

Die Trefferquote steigt von 63,6 auf 76,0 Prozent; diese 12,4 Prozentpunkte weisen schon rund 215 Beobachtungen je Gruppe nach. Für einen Prozentpunkt wären es über 36 000: Der Bedarf wächst mit dem Kehrwert des Quadrats des Unterschieds, ein halbierter Effekt heißt ungefähr vierfachen Aufwand. Wer kleine Verbesserungen belegen will, braucht viel Verkehr oder Geduld. Der Shadow-Modus ist im Vorteil, weil beide Modelle dieselben Anfragen sehen und gepaart verglichen wird: Der mittlere Fehler sinkt um 0,59 Minuten, und schon rund 67 Anfragen genügten. Die Zahlen 215 und 67 betreffen verschiedene Zielgrößen und sind nicht gegeneinander aufzurechnen; sie zeigen aber, dass ein gepaarter Vergleich einer kontinuierlichen Größe viel weniger Daten braucht als zwei getrennte Gruppen mit einer Trefferquote.

Alle Strategien setzen einen schnellen Rollback voraus (ML Test Score, Infrastruktur-Test 7); mit der Registry ist das ein Umhängen des Alias. In der Praxis kombiniert man sie: Offline-Prüfung gegen das aktuelle Modell, Shadow, Canary mit Schutzgrößen und, wenn der Nutzen belegt werden muss, ein A/B-Test. Der Leitfaden von Google Cloud @googlecloud_mlops_2020 nennt Canary und A/B als Online-Validierung in Level 1.

== Rollen im Team

Wer die Tätigkeiten ausführt, ist eine organisatorische Frage. #cite(<kreuzberger_mlops_2023>, form: "prose") unterscheiden unter anderem Business Stakeholder, Solution Architect, Data Scientist, Data Engineer, Software Engineer, DevOps Engineer und ML Engineer; in kleinen Teams übernimmt eine Person mehrere Rollen. Hier genügen vier: Der *Data Scientist* formuliert das Problem, entwickelt und bewertet Modelle. Der *ML Engineer* macht aus dem Experiment ein Produkt (Pipeline, Tests, Serving, Rollout). Der *Data Engineer* verantwortet Datenquellen, Datenpipelines und Datenqualität. Die *Plattform* betreibt Orchestrierung, Registry, CI/CD und Observability.

#block(breakable: false)[
#figure(
  {
    set text(size: 9pt)
    let f = text(weight: "bold", fill: blau)[führt]
    let m = text(fill: grau)[wirkt mit]
    table(
      columns: (1fr, auto, auto, auto, auto),
      align: (left, center, center, center, center),
      [*Tätigkeit*], [*Data Scientist*], [*ML Engineer*], [*Data Engineer*], [*Plattform*],
      [Problem und Zielgröße festlegen], f, m, m, [],
      [Experimente, Modellentwicklung], f, m, [], [],
      [Datenquellen, Datenpipelines, Schemata], m, m, f, [],
      [Feature-Berechnung (Transform, Feature Store)], m, f, f, m,
      [Trainingspipeline, Tests, Modellvalidierung], m, f, [], m,
      [Registry, CI/CD, Orchestrierung], [], m, [], f,
      [Serving und Rollout], [], f, [], m,
      [Monitoring und Alarmierung], m, f, m, f,
      [Fairness- und Erklärbarkeitsprüfung], f, m, [], [],
    )
  },
  caption: [Eine mögliche Verteilung der Verantwortung. „Führt“ meint, dass die Rolle am Ende dafür geradesteht; die Zuordnung ist ein Vorschlag dieses Handbuchs und je nach Organisation anders.],
) <tab-rollen>
]

Aufschlussreich sind die Nahtstellen. Zwischen Data Scientist und ML Engineer entsteht das Level-0-Problem der doppelten Implementierung; die Antwort ist eine gemeinsame, getestete Pipeline (Patterns 21 und 25). Zwischen Data Engineer und ML Engineer liegt der Feature-Vertrag (Pattern 26 oder ein gemeinsames Schema), zwischen ML Engineer und Plattform die Frage, wer nachts geweckt wird. #cite(<amershi_se4ml_2019>, form: "prose") berichten aus einer Fallstudie bei Microsoft, dass ML-Teams Fachleute mit sehr unterschiedlichem Hintergrund zusammenbringen und Übergänge Reibung erzeugen.

== Die 30 Patterns im Betrieb

@abb-karte ordnet alle 30 Patterns den Stationen eines betriebenen ML-Systems zu. Der Kreislauf läuft im Uhrzeigersinn: Daten und Features bereitstellen, trainieren, vor der Freigabe prüfen, registrieren und ausrollen, ausliefern, überwachen; das Monitoring stößt bei Bedarf einen neuen Lauf an. Oben stehen die Patterns des Modellentwurfs, unten das Pattern, das alle Schritte verbindet. Jedes Pattern erscheint genau einmal; gehört eines fachlich zu zwei Stationen, gilt die dominierende.

Die Patterns des Modellentwurfs haben Betriebsfolgen, die man leicht übersieht. Ein Hashed Feature (1) erspart ein Vokabular, das man pflegen müsste, nimmt aber Kollisionen in Kauf. Embeddings (2) sind gelernte Teile des Modells und müssen mit demselben Modellstand ausgeliefert werden. Ensemble (7) und Cascade (8) vervielfachen die Zahl der Modelle, die versioniert, ausgerollt und überwacht werden müssen. Rebalancing (10) verändert die Klassenverhältnisse im Training, sodass die Vorhersageverteilung nicht mehr direkt mit der Realität vergleichbar ist; beim Monitoring ist das zu berücksichtigen. Umgekehrt dient die Karte als Prüfliste: Gibt es einen Feature-Vertrag? Eine Freigabeprüfung, die ein schlechteres Modell tatsächlich blockiert? Weiß der Serving-Code, welche Version er lädt? Hört jemand auf die Alarme?

#figure(
  canvas(length: 1cm, {
    import draw: *
    let station(x0, y0, x1, y1, titel, zeilen, farbe: blau, grund: blau-hell) = {
      rect((x0, y0), (x1, y1), fill: grund, stroke: 0.8pt + farbe, radius: 3pt)
      content((x0 + 0.2, y1 - 0.18), anchor: "north-west", box(width: (x1 - x0 - 0.4) * 1cm, align(left)[
        #text(size: 9pt, weight: "bold", fill: farbe, titel) \
        #v(0.1em)
        #set text(size: 8.5pt)
        #zeilen.join(linebreak())
      ]))
    }
    let pfeil(..punkte) = line(..punkte, mark: (end: ">", size: 0.2), stroke: 0.9pt + luma(90))
    let grau-station = (farbe: luma(130), grund: nebel)
    station(0, 8.75, 16.2, 10.55, [Modellentwurf (Notebook-Phase)],
      ([1 Hashed Feature · 2 Embeddings · 3 Feature Cross · 4 Multimodal Input],
       [5 Reframing · 6 Multilabel · 7 Ensembles · 8 Cascade · 9 Neutral Class · 10 Rebalancing]), ..grau-station)
    station(0, 5.3, 4.9, 8.25, [1 Daten und Features],
      ([21 Transform], [22 Repeatable Splitting], [23 Bridged Schema], [26 Feature Store]))
    station(5.65, 5.3, 10.55, 8.25, [2 Training],
      ([11 Useful Overfitting], [12 Checkpoints], [13 Transfer Learning], [14 Distribution Strategy], [15 Hyperparameter Tuning]))
    station(11.3, 5.3, 16.2, 8.25, [3 Prüfung vor Freigabe],
      ([28 Heuristic Benchmark], [29 Explainable Predictions], [30 Fairness Lens]))
    station(11.3, 1.85, 16.2, 4.8, [4 Registry und Rollout],
      ([27 Model Versioning],), farbe: gruen, grund: gruen-hell)
    station(5.65, 1.85, 10.55, 4.8, [5 Serving],
      ([16 Stateless Serving Function], [17 Batch Serving], [19 Two-Phase Predictions], [20 Keyed Predictions], [24 Windowed Inference]),
      farbe: gruen, grund: gruen-hell)
    station(0, 1.85, 4.9, 4.8, [6 Monitoring],
      ([18 Continued Model Evaluation],), farbe: orange, grund: orange-hell)
    station(0, 0, 16.2, 1.35, [Orchestrierung über alle Stationen], ([25 Workflow Pipeline],), ..grau-station)
    pfeil((8.1, 8.75), (8.1, 8.25))
    pfeil((4.9, 6.8), (5.65, 6.8))
    pfeil((10.55, 6.8), (11.3, 6.8))
    pfeil((13.75, 5.3), (13.75, 4.8))
    pfeil((11.3, 3.3), (10.55, 3.3))
    pfeil((5.65, 3.3), (4.9, 3.3))
    pfeil((2.45, 4.8), (2.45, 5.3))
    content((2.6, 5.05), anchor: "west", text(size: 8.5pt, fill: grau)[Trigger: neuer Lauf])
  }),
  caption: [Alle 30 Patterns auf einer Landkarte des betriebenen ML-Systems. Blau: Vorbereitung und Training; grün: Auslieferung; orange: Überwachung; grau: übergreifend. Die Pfeile zeigen den Kreislauf im Uhrzeigersinn.],
) <abb-karte>

== Das Wichtigste in Kürze

- Der ML-Code ist der kleinste Teil eines ML-Systems. Technische Schuld entsteht an den Rändern: Verflechtung der Merkmale (CACE), instabile Datenabhängigkeiten, unbekannte Konsumenten, Glue Code und gewachsene Pipelines @sculley_hidden_debt_2015. Weil Daten das Verhalten mitbestimmen und sich ohne Commit ändern, müssen auch Daten, Modelle und Pipelines versioniert und geprüft werden.
- Die Reifegrade nach #cite(<googlecloud_mlops_2020>, form: "prose"): Level 0 liefert ein Modell manuell aus, Level 1 eine Trainingspipeline, die selbst neu trainiert (Continuous Training), Level 2 zusätzlich die Pipeline automatisiert. Welcher genügt, hängt davon ab, wie schnell das Modell veraltet.
- Experiment Tracking und Model Registry (etwa MLflow) machen Läufe vergleichbar und Modelle versioniert; ein Alias trennt Serving von Training und macht den Rollback zu einer einzigen Operation.
- Ein Schema ist der Vertrag zwischen Datenquelle und Modell. Es findet, was man als Regel formulieren konnte, nicht Fehler, die alle Regeln einhalten und nur die Verteilung verschieben.
- Der ML Test Score hat 28 Tests in vier Kategorien und zählt das Minimum der Kategorien. Modelltests prüfen Verhalten: Teilmengen, Richtungserwartungen, Vergleich mit einer Faustformel.
- PSI und KS-Test sind Frühwarnungen ohne Labels. Sie hängen von der Stichprobengröße ab, erzeugen bei vielen Merkmalen Fehlalarme und brauchen Schwellen, Verantwortliche und hinterlegte Reaktionen.
- Shadow prüft ohne Nutzerwirkung, Canary begrenzt das Risiko, der A/B-Test belegt den Nutzen. Kleine Effekte brauchen sehr viele Beobachtungen.

== Weiterführende Literatur

- #cite(<sculley_hidden_debt_2015>, form: "prose") und #cite(<breck_ml_test_score_2017>, form: "prose"): die Ausgangspapiere des Kapitels, beide kurz und im Original lesenswert.
- #cite(<googlecloud_mlops_2020>, form: "prose"): der Leitfaden zu den Reifegraden, mit Architekturdiagrammen der drei Stufen.
- #cite(<huyen_designing_ml_systems_2022>, form: "prose"): ein modernes Lehrbuch zum gesamten Thema, mit Schwerpunkt auf Daten, Deployment und Monitoring.
- #cite(<paleyes_challenges_2022>, form: "prose") und #cite(<kreuzberger_mlops_2023>, form: "prose"): eine Übersicht über Probleme aus Fallstudien zum Betrieb von ML-Systemen und eine Referenzarchitektur für MLOps.
- #cite(<kohavi_trustworthy_experiments_2020>, form: "prose"): das Standardwerk zu A/B-Tests mit allen Fallstricken.
- #cite(<sato_cd4ml_2019>, form: "prose"): Continuous Delivery für ML, als Artikel frei lesbar.
- #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose"): die Patterns selbst; Kapitel 5 (Resilient Serving) und 6 (Reproducibility) des Buches sind hier am wichtigsten.

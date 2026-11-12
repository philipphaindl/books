#import "../lib.typ": *

// Hilfen für dieses Kapitel: Code und Ausgaben direkt aus den ausgeführten Dateien in code/ lesen,
// damit das Handbuch exakt zeigt, was gelaufen ist.
#let code-datei(pfad, von: 1, bis: none) = {
  let z = read(pfad).split("\n")
  raw(z.slice(von - 1, if bis == none { z.len() } else { bis }).join("\n"), lang: "python", block: true)
}
#let lauf(skript, pfad) = raw("$ python " + skript + "\n" + read(pfad).trim("\n", at: end), lang: "terminal", block: true)
#let gruen = rgb("#2EAE7D")
#let orange = rgb("#B5651D")
#let nebenbei(t) = text(size: 8.5pt, fill: grau, t)
#let so-erklaere-ich-es(text-, frage, antwort) = kasten([So erkläre ich es.], [
  #text-
  #v(0.4em)
  *Verständnisfrage:* #frage \
  *Antwort:* #antwort
])

= Reproducibility

Ein Modell, das sich nicht reproduzieren lässt, lässt sich auch nicht reparieren, vergleichen oder prüfen. Dieses Kapitel behandelt die sieben Patterns, die ein ML-System in diesem Sinn zu einem kontrollierbaren Software-Artefakt machen. Alle Beispielprogramme liegen im Ordner `code/08-reproducibility/` und werden mit `uv run --with scikit-learn --with pandas --with numpy python <datei>.py` gestartet. Die gezeigten Ausgaben sind die tatsächlichen Ausgaben dieser Läufe; die Daten sind simuliert (feste Seeds), damit die Effekte reproduzierbar sind und die richtige Antwort bekannt ist.

== Warum ML-Systeme schwer reproduzierbar sind

Bei klassischer Software ist die Frage „Welche Version läuft in Produktion?“ mit einem Commit-Hash beantwortet: Gleicher Code und gleiche Eingabe ergeben gleiche Ausgabe. Ein ML-System hat zwei Phasen, und das Verhalten des fertigen Modells ist das Ergebnis eines _Trainingslaufs_, in den mehr eingeht als Code. Der Commit-Hash allein reicht nicht.

Es lohnt sich, drei Quellen von Nichtreproduzierbarkeit zu trennen. Die erste ist der *Zufall*: Gewichte werden zufällig initialisiert, Trainingsdaten werden zufällig gemischt, Random Forests ziehen zufällige Stichproben, und parallele Berechnungen (insbesondere auf GPUs) summieren Gleitkommazahlen nicht immer in derselben Reihenfolge. Fixiert man den _Seed_ (den Startwert des Zufallsgenerators; in scikit-learn der Parameter `random_state`), wird das meiste wiederholbar, aber nicht alles. Die zweite Quelle sind die *Daten*: Eine Tabelle, die heute 3 Millionen Zeilen hat, hat morgen 3,1 Millionen; Spalten werden umbenannt, ein Zulieferer ändert das Format (Pattern 23), und ein Split in Trainings- und Testdaten, der bei jedem Lauf neu gewürfelt wird, macht Ergebnisse unvergleichbar (Pattern 22). Die dritte ist die *Umgebung*: Bibliotheksversionen, Betriebssystem, Hardware und, besonders tückisch, der Code, der die Eingaben im Betrieb aufbereitet und nicht derselbe ist wie beim Training (Pattern 21).

#cite(<sculley_hidden_debt_2015>, form: "prose") beschreiben, warum das mehr ist als ein Komfortproblem. ML-Systeme erzeugen auf allen Ebenen _technische Schulden_: Datenabhängigkeiten, die schwerer zu erkennen sind als Code-Abhängigkeiten, Glue Code zwischen Bibliotheken und ganze „Pipeline Jungles“ aus zusammengeklebten Vorverarbeitungsschritten. Ihr Prinzip „Changing Anything Changes Everything“ (CACE) beschreibt, dass sich in einem trainierten Modell keine Eingabe isoliert verändern lässt: Wer ein Feature ändert, verändert die Gewichte aller anderen. Reproduzierbarkeit heißt deshalb, alles festzuhalten und explizit zu machen, was in ein Modell eingeht. Auch der ML Test Score von #cite(<breck_ml_test_score_2017>, form: "prose") enthält Tests für Produktionsreife, die nach genau diesen Dingen fragen; einer davon prüft, ob Features in Training und Betrieb dieselben Werte berechnen.

#figure(
  diagram(
    node-stroke: 0.7pt + luma(140), node-fill: luma(240), node-corner-radius: 3pt, node-inset: 6pt,
    spacing: (8mm, 5mm),
    {
      let quelle(pos, titel, pat) = node(pos, box(width: 70mm, align(left)[*#titel* \ #nebenbei(pat)]))
      quelle((0, 0), [Code und Transformationen], [21 Transform · 24 Windowed Inference])
      quelle((0, 1), [Daten (Stand, Schema, Split)], [22 Repeatable Splitting · 23 Bridged Schema · 26 Feature Store])
      quelle((0, 2), [Konfiguration und Ablauf], [25 Workflow Pipeline])
      quelle((0, 3), [Zufall (Seeds)], [`random_state` überall setzen])
      quelle((0, 4), [Umgebung (Bibliotheken, Hardware)], [25 Workflow Pipeline: ein Container je Schritt])
      node((1, 2), [*Trainings-\ lauf*], fill: blau-hell, stroke: 0.9pt + blau)
      node((2, 2), [*Modell-\ artefakt*], fill: blau-hell, stroke: 0.9pt + blau)
      node((3, 2), [*Serving*], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      for y in range(5) { edge((0, y), (1, 2), "->", stroke: 0.6pt + luma(110)) }
      edge((1, 2), (2, 2), "->")
      edge((2, 2), (3, 2), "->")
      node((2, 3), nebenbei[27 Model Versioning \ hält den Stand fest], stroke: none, fill: none)
    },
  ),
  caption: [Was in ein trainiertes Modell eingeht und welches Pattern welche Quelle kontrolliert. Das Modellartefakt ist erst dann reproduzierbar, wenn alle fünf Eingänge festgehalten sind.],
)

Die Patterns dieses Kapitels lassen sich entlang dieses Bildes lesen. _Transform_, _Windowed Inference_ und _Feature Store_ sorgen dafür, dass Training und Betrieb dieselben Features berechnen. _Repeatable Splitting_ und _Bridged Schema_ halten den Datenstand und seine Veränderung unter Kontrolle. _Workflow Pipeline_ macht den gesamten Ablauf ausführbar und wiederholbar. _Model Versioning_ hält fest, welches Ergebnis welches Laufs gerade im Betrieb ist.

== Pattern 21: Transform

*Szenario.* Ein Fahrdienst sagt den Preis einer Fahrt voraus. Eingaben sind die Distanz in Kilometern und die Stadt (Wien, Graz oder Linz). Ein Data Scientist bereitet die Daten im Notebook auf: Die Distanz wird _standardisiert_, das heißt, vom Mittelwert abgezogen und durch die Standardabweichung geteilt, damit alle numerischen Features ähnliche Größenordnung haben; die Stadt wird per One-Hot-Encoding in drei Spalten mit 0/1 zerlegt. Das Modell ist gut. Zwei Wochen später baut ein anderes Team den Service und schreibt die Aufbereitung noch einmal, in seinen eigenen Worten.

*Das Problem.* Die Transformation hat _gelernte Parameter_: Mittelwert und Standardabweichung stammen aus den Trainingsdaten, die Liste der bekannten Städte ebenso. Das sind Teile des Modells, auch wenn sie nicht in den Gewichten stehen. Wer die Aufbereitung im Service neu implementiert, muss diese Parameter und die Reihenfolge der Spalten exakt übernehmen. Schon kleine Abweichungen führen zu _Training-Serving Skew_: Das Modell sieht im Betrieb Eingaben, die anders aufbereitet sind als im Training, und liefert ohne Fehlermeldung falsche Vorhersagen.

Das folgende Programm macht den Fehler sichtbar: Der nachgebaute Serving-Code standardisiert mit Mittelwert und Standardabweichung der gerade eingehenden Anfragen statt mit denen des Trainings, ein in Reviews leicht zu übersehender Fehler.

#code-datei("../code/08-reproducibility/21_transform_skew.py", von: 29, bis: 35)

Fünf Anfragen mit bekannten Preisen zeigen den Effekt:

#lauf("21_transform_skew.py", "../code/08-reproducibility/out/21_transform_skew.txt")

Die erste Zeile ist der Preis, den das Modell im Idealfall liefern müsste (die Zufallskomponente der Daten ausgenommen), die zweite die Antwort des Service: für die letzte Fahrt 46,3 statt 19,2. Die Abweichung ist kein Zufall und kein Rauschen, sondern systematisch: Der Service standardisiert die fünf Anfragen relativ zueinander, sodass die kürzeste Fahrt immer „unterdurchschnittlich“ und die längste „überdurchschnittlich“ erscheint, egal wie lang sie tatsächlich sind. Bei einer einzelnen Anfrage wäre die Standardabweichung nicht definiert (pandas liefert `NaN`). Kein Syntaxtest findet das, die Zahlen sehen plausibel aus.

*Die Lösung.* Das Pattern trennt drei Dinge sauber voneinander: die _Eingaben_ (roh, so wie der Client sie schickt), die _Features_ (das, was das Modell tatsächlich verarbeitet) und die _Transformation_ zwischen beiden. Die Transformation wird dann nicht neben dem Modell gepflegt, sondern ist _Teil des Modells_: Sie wird beim Training gelernt, zusammen mit den Gewichten gespeichert und im Betrieb unverändert angewendet. Es gibt dann nur noch eine Implementierung. Das Buch zeigt dies in TensorFlow (Transformationen als Schichten im Modell, TensorFlow Transform für Vorberechnungen, die TRANSFORM-Klausel in BigQuery ML) und verweist darauf, dass das Prinzip frameworkunabhängig ist @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 21]. In scikit-learn heißt das Werkzeug `Pipeline` @pedregosa_scikit_learn_2011:

#code-datei("../code/08-reproducibility/21_transform_skew.py", von: 45, bis: 56)

Der `ColumnTransformer` wendet auf jede Spalte ihre eigene Transformation an, die `Pipeline` hängt das Modell dahinter. `fit` lernt Mittelwert, Standardabweichung und Stadtliste aus den Trainingsdaten, `predict` wendet sie unverändert an. `joblib.dump` speichert das Ganze als ein Artefakt. Der Service lädt es und übergibt rohe Anfragen; seine eigene Aufbereitung entfällt. Die dritte Zeile der Ausgabe zeigt, dass die Preise jetzt bis auf wenige Hundertstel zu den erwarteten passen; auch eine Einzelanfrage funktioniert (vierte Zeile). Der gelernte Mittelwert der Distanz (letzte Zeile) steckt jetzt im Artefakt.

#figure(
  diagram(
    node-stroke: 0.7pt + luma(140), node-fill: luma(240), node-corner-radius: 3pt, node-inset: 6pt,
    spacing: (9mm, 7mm),
    {
      let orange-box(pos, t) = node(pos, t, fill: rgb("#FBF1E6"), stroke: 0.8pt + orange)
      node((0, 0), text(fill: orange, weight: "bold")[Vorher], stroke: none, fill: none)
      orange-box((1, 0), [Training: \ Notebook-Code])
      orange-box((2, 0), [Modell A])
      orange-box((3, 0), [Serving: \ nachgebauter Code])
      orange-box((4, 0), [Anfrage → Modell A])
      edge((1, 0), (2, 0), "->")
      edge((2, 0), (3, 0), "->", label: nebenbei[Parameter \ abgetippt?], label-side: left)
      edge((3, 0), (4, 0), "->")

      node((0, 1.4), text(fill: gruen, weight: "bold")[Mit Transform], stroke: none, fill: none)
      node((1, 1.4), [Trainingsdaten \ (roh)])
      node((2, 1.4), [*Pipeline.fit* \ lernt Parameter \ und Gewichte], fill: blau-hell, stroke: 0.9pt + blau)
      node((3, 1.4), [*Ein Artefakt* \ Transformation \ + Modell], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      node((4, 1.4), [*Pipeline.predict* \ Anfrage (roh) \ → Vorhersage], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      edge((1, 1.4), (2, 1.4), "->")
      edge((2, 1.4), (3, 1.4), "->")
      edge((3, 1.4), (4, 1.4), "->", label: nebenbei[laden], label-side: left)
    },
  ),
  caption: [Oben der Zustand vor dem Pattern: Training und Serving haben je eigenen Aufbereitungscode, der auseinanderlaufen kann. Unten nach dem Pattern: Die Transformation wird beim Training gelernt und liegt im selben Artefakt wie das Modell.],
)

Die Pipeline schützt auch vor einem Datenleck (vgl. Pattern 22): Ein Scaler, der vor dem Split auf _alle_ Daten angepasst wird, kennt die Testdaten schon. In einer Pipeline innerhalb der Kreuzvalidierung wird er nur auf den jeweiligen Trainingsanteil angepasst.

*Trade-offs und Grenzen.* Die Transformation läuft bei jeder Vorhersage mit; das kostet Latenz, aufwendige Berechnungen wiederholt man besser einmal im Voraus. Das gespeicherte Artefakt ist an Bibliotheksversionen gebunden, und `joblib`/`pickle` können beim Laden beliebigen Code ausführen, dürfen also nie aus unvertrauter Quelle stammen. Das Pattern deckt zudem nur Transformationen ab, die sich aus den Eingaben _einer_ Anfrage berechnen lassen; was Verlauf oder fremde Tabellen braucht („Bestellungen der letzten 30 Tage“), gehört in Windowed Inference (Pattern 24) oder einen Feature Store (Pattern 26).

*Wann nicht.* Bei einmaligen Analysen ohne Serving bringt das Pattern wenig. Bei Baummodellen entfällt die Standardisierung, nicht aber die Kodierung kategorialer Features.

*Bezug zu Software Engineering.* Das Pattern ist _Don't Repeat Yourself_ und _Single Source of Truth_ für Wissen: Die Aufbereitungsregel existiert an genau einer Stelle. Der Skew ist verwandt mit unterschiedlichen Test- und Produktionsumgebungen („works on my machine“); der passende Test schickt dieselben Rohdaten durch beide Wege und vergleicht.

#so-erklaere-ich-es(
  [Ich zeige zuerst die Ausgabe des fehlerhaften Service und lasse raten, was falsch ist: Das Modell ist fehlerfrei, die Zahlen sind falsch. Dann frage ich, wo der Mittelwert „wohnt“: Er entsteht beim Training und gehört deshalb zum Modell. Erst danach zeige ich die Pipeline, die das erzwingt.],
  [Warum reicht es nicht, Mittelwert und Standardabweichung in eine Konfigurationsdatei zu schreiben, die der Service lädt?],
  [Es funktioniert, solange beide Dateien bei jedem Neutraining gemeinsam und konsistent aktualisiert werden. Das ist aber ein manueller Schritt zwischen zwei Artefakten, der vergessen werden kann; die Pipeline macht ihn unmöglich zu vergessen, weil es nur ein Artefakt gibt.],
)

*Quellen.* @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 21] @sculley_hidden_debt_2015 @breck_ml_test_score_2017 @pedregosa_scikit_learn_2011

== Pattern 22: Repeatable Splitting

_Namenshinweis:_ Im Inhaltsverzeichnis des Buchs heißt das Pattern „Repeatable Splitting“, im Code-Repository zum Buch „Repeatable Sampling“.

*Szenario.* Eine Klinik sammelt Messwerte von 500 Patienten, je 10 Messungen pro Person, also 5000 Zeilen. Ein Modell soll aus den Messwerten einen Befund vorhersagen. Wie jedes ML-Projekt teilt das Team die Daten in Trainings- und Testdaten: Mit dem Training lernt das Modell, mit den Testdaten, die es nie gesehen hat, misst man, wie gut es auf neuen Fällen funktioniert. Üblich ist `train_test_split(df, test_size=0.2)`.

*Das Problem.* Es gibt zwei getrennte Probleme, die man oft verwechselt. Das erste ist das *Datenleck* (_Data Leakage_) durch korrelierte Zeilen. Die zehn Messungen eines Patienten sind einander sehr ähnlich. Würfelt man jede Zeile einzeln, landen manche in den Trainings- und andere in den Testdaten. Das Modell kann dann Patienten _wiedererkennen_ statt etwas zu verallgemeinern, und die Testgenauigkeit ist geschönt. Das zweite Problem ist die *fehlende Wiederholbarkeit*. Ein Zufallssplit mit festem Seed ist nur so lange stabil, wie die Daten unverändert bleiben; kommen neue Zeilen hinzu oder ändert sich die Sortierung, wird alles neu gemischt, und Zeilen, die gestern in den Testdaten waren, sind heute im Training. Dann sind Messungen von gestern und heute nicht mehr vergleichbar, und die Testdaten sind „verbraucht“.

#code-datei("../code/08-reproducibility/22_repeatable_splitting.py", von: 37, bis: 53)

#lauf("22_repeatable_splitting.py", "../code/08-reproducibility/out/22_repeatable_splitting.txt")

Beim zeilenweisen Split stehen 448 der 500 Patienten auf beiden Seiten, und die Genauigkeit beträgt 0,748. Das ist trügerisch: Der Random Forest hat sich Patienten gemerkt. Teilt man nach Patienten (Hash-Split: kein Patient auf beiden Seiten, 4010 Zeilen im Training und 990 im Test), fällt die Genauigkeit auf 0,572, und `GroupShuffleSplit` liefert mit 0,566 praktisch dasselbe. Das ist die ehrliche Zahl: In diesem simulierten Beispiel hängt der Befund nur schwach von den Messwerten ab. Die rund 0,18 Unterschied (0,748 gegen 0,572 beziehungsweise 0,566) sind ein reines Datenleck. #cite(<roberts_cross_validation_2017>, form: "prose") zeigen für Daten mit zeitlicher, räumlicher, hierarchischer oder phylogenetischer Struktur, dass zufälliges Aufteilen den Vorhersagefehler tendenziell unterschätzt; #cite(<kaufman_leakage_2012>, form: "prose") systematisieren Datenlecks allgemein.

*Die Lösung.* Das Pattern teilt nach einem *Gruppierungsschlüssel* und bestimmt die Zuordnung mit einer _Hashfunktion_. Eine Hashfunktion bildet beliebige Eingaben deterministisch auf eine Zahl ab; bei kryptografischen Hashfunktionen wie SHA-256 landen auch ähnliche Eingaben auf völlig verschiedenen Zahlen. Der Ablauf ist in drei Schritten festgelegt:

+ Den Schlüssel wählen, der korrelierte Zeilen zusammenhält: die Patienten-ID, die Kunden-ID, das Datum. Alle Zeilen mit demselben Schlüssel müssen auf dieselbe Seite fallen.
+ Den Schlüssel hashen und den Rest einer Division bilden (_Modulo_): `hash(schluessel) mod 10` ergibt einen _Bucket_ von 0 bis 9.
+ Buckets den Teilen zuordnen, zum Beispiel 0–7 Training, 8 Validierung, 9 Test.

Das Buch zeigt dies mit der Funktion `FARM_FINGERPRINT` in BigQuery @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 22]; in Python genügt `hashlib`. Die Zuordnung hängt allein vom Schlüssel ab, nicht von der Reihenfolge, der Größe des Datensatzes oder dem Zeitpunkt des Laufs. Kommen 100 neue Patienten hinzu, behalten die bisherigen 500 ihren Bucket (die Ausgabe prüft das); die Testmenge wächst, ohne dass alte Testfälle ins Training wandern.

#figure(
  diagram(
    node-stroke: 0.7pt + luma(140), node-fill: luma(240), node-corner-radius: 3pt, node-inset: 6pt,
    spacing: (9mm, 4mm),
    {
      node((0, 0), [Zeile \ #nebenbei[P0001 · m0…m4]])
      node((0, 1), [Zeile \ #nebenbei[P0001 · m0…m4]])
      node((0, 2), [Zeile \ #nebenbei[P0417 · m0…m4]])
      node((1, 1), [*Schlüssel* \ `patient_id`], fill: blau-hell, stroke: 0.9pt + blau)
      node((2, 1), [*SHA-256* \ erste 8 Byte], fill: blau-hell, stroke: 0.9pt + blau)
      node((3, 1), [*mod 10* \ Bucket 0–9], fill: blau-hell, stroke: 0.9pt + blau)
      node((4, 0), [Bucket 0–7 \ Training], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      node((4, 1), [Bucket 8 \ Validierung], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      node((4, 2), [Bucket 9 \ Test], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      for y in range(3) { edge((0, y), (1, 1), "->", stroke: 0.6pt + luma(110)) }
      edge((1, 1), (2, 1), "->")
      edge((2, 1), (3, 1), "->")
      for y in range(3) { edge((3, 1), (4, y), "->", stroke: 0.6pt + luma(110)) }
    },
  ),
  caption: [Hash-basierter Split. Beide Zeilen von Patient P0001 liefern denselben Schlüssel und damit denselben Bucket, egal in welcher Reihenfolge oder zu welchem Zeitpunkt sie eintreffen.],
)

Ein Stolperstein steht in der letzten Zeile der Ausgabe: Pythons eingebautes `hash()` taugt dafür _nicht_. Für Strings ist es pro Prozess zufällig gesalzen (Schutz gegen Hash-Kollisionsangriffe); zwei Läufe liefern verschiedene Werte, und der Split wäre nicht wiederholbar. Man braucht eine Funktion mit stabiler Ausgabe wie die aus `hashlib`.

*Alternative in scikit-learn.* `GroupShuffleSplit` (und `GroupKFold` für Kreuzvalidierung) gruppieren ebenfalls und sind für ein einmaliges Experiment einfacher. Sie sind aber nur bei festem Seed _und_ unverändertem Datensatz reproduzierbar. Der Hash-Split ist für Systeme gedacht, deren Daten fortlaufend wachsen und deren Testdaten über Monate vergleichbar bleiben sollen.

*Trade-offs und Grenzen.* Die Anteile stimmen nur ungefähr: Bei vielen Schlüsselwerten liegt der Split nahe 80/20, bei wenigen (etwa 5 verschiedene Tage) kann er stark abweichen, und ein einzelner sehr großer Kunde kann das Verhältnis verzerren. Der Hash garantiert keine ausgewogene Klassenverteilung; bei seltenen Klassen muss man das nachprüfen. Der Schlüssel darf kein Feature des Modells sein, denn sonst sieht das Modell im Training nur Schlüsselwerte, die im Test nie vorkommen. *Wann nicht:* Bei Zeitreihen und überall, wo das Modell in die Zukunft vorhersagen soll, muss der Split zeitlich sein (Training = Vergangenheit, Test = Zukunft); ein Hash-Split mischt Vergangenheit und Zukunft und überschätzt die Qualität.

*Bezug zu Software Engineering.* Das Verfahren ist dasselbe wie beim _Sharding_ von Datenbanken: `hash(key) mod N` entscheidet über die Partition. (Konsistentes Hashing ist die Verfeinerung, die bei einem geänderten N möglichst wenige Schlüssel umzieht; hier bleibt N fest.) Der Gedanke dahinter ist _Idempotenz_ und _Determinismus_: dieselbe Eingabe, dieselbe Zuordnung, unabhängig vom Zustand der Umgebung. Der Gruppierungsschlüssel entspricht der Frage, was in einem Test als „unabhängige Einheit“ gilt.

#so-erklaere-ich-es(
  [Ich lasse raten, warum ein Modell mit guter Testgenauigkeit im Betrieb deutlich schlechter sein kann, und zeige dann die zwei Zahlen der Ausgabe nebeneinander. Dann der Vergleich mit einer Klausur, deren Fragen aus denselben Übungsbeispielen stammen: Sie sagt nichts darüber, ob jemand das Thema verstanden hat. Testdaten müssen _unabhängig_ sein.],
  [Warum löst `random_state=42` das Problem nicht?],
  [Ein fester Seed macht den Zufall wiederholbar, aber nur für genau diese Daten in genau dieser Reihenfolge; sobald Zeilen hinzukommen, ändert sich die Zuordnung. Außerdem trennt ein Seed nichts nach Gruppen: Zeilen desselben Patienten können weiterhin auf beiden Seiten stehen.],
)

*Quellen.* @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 22] @kaufman_leakage_2012 @roberts_cross_validation_2017

== Pattern 23: Bridged Schema

*Szenario.* Ein Fahrdienst will vorhersagen, wie viel Trinkgeld eine Fahrt bekommt. Ein wichtiges Feature ist die Zahlungsart. Über Jahre hinweg gab es in den Daten nur `cash` und `card`. Seit dem Umstieg auf ein neues Zahlungssystem unterscheidet die Erfassung bei Karten zwischen `gift_card`, `debit_card` und `credit_card`, und das Modell soll im Betrieb mit genau diesen vier Werten arbeiten. Das Beispiel orientiert sich am Zahlungsart-Beispiel des Buchs @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 23]; Zahlen und Zielgröße (Trinkgeld) sind hier frei gewählt und simuliert.

*Das Problem.* Im neuen Schema gibt es erst 60 Zeilen, im alten 3000, und das Modell hat neben der Zahlungsart sechs weitere Fahrt-Features, deren Zusammenhang es aus den Daten lernen muss. Das neue Schema ist feiner, das alte ist eine _Vergröberung_ davon. Drei naive Wege führen nicht zum Ziel. Nur die neuen Daten zu verwenden, verschenkt den größten Teil der Beispiele. Das neue Schema auf `cash`/`card` zurückzuführen (_Roll-up_) lässt das Modell die Unterschiede zwischen den Kartenarten nie lernen, obwohl sie im Betrieb vorkommen. Und eine fünfte Kategorie „card“ zuzulassen (_Union Schema_) lehrt das Modell einen Wert, der im Betrieb nie auftritt. Das ist keine gute Lösung.

*Die Lösung.* Das Pattern _überbrückt_ (bridges) das alte Schema ins neue, indem es die fehlende Information für die alten Zeilen _schätzt_ und beide Datenstände zusammen trainiert. Es gibt zwei Methoden, die beide die Häufigkeiten der Kartenarten in den neuen Daten verwenden:

- Die *statische Methode* kodiert die alten Zeilen mit einem Vektor aus Häufigkeiten: Eine alte `card`-Zeile erhält bei `cash` eine 0 und bei den drei Kartenarten die Anteile aus den neuen Daten (etwa 0,1; 0,3; 0,6) statt der üblichen 0/1.
- Die *probabilistische Methode* zieht für jede alte `card`-Zeile zufällig eine konkrete Kartenart, mit den Anteilen aus den neuen Daten als Wahrscheinlichkeiten. Die Zeile erscheint dann mit einem echten One-Hot-Wert.

Beide setzen voraus, dass die Anteile der Kartenarten in alten und neuen Daten ungefähr gleich sind; das ist eine Annahme, keine Garantie. Die probabilistische Methode fügt dem alten Teil Rauschen hinzu (jede Zeile bekommt einen Wert, der falsch sein kann). Die statische vermeidet das, benutzt aber Eingaben, die das Modell im Betrieb nie bekommt.

#code-datei("../code/08-reproducibility/23_bridged_schema.py", von: 37, bis: 50)

#lauf("23_bridged_schema.py", "../code/08-reproducibility/out/23_bridged_schema.txt")

Die Zahlen sind der mittlere absolute Fehler (_MAE_, in Prozentpunkten Trinkgeld) auf 2000 Testzeilen im neuen Schema, gemittelt über 30 Wiederholungen mit verschiedenen Zufallsdaten (die Streuung steht daneben). Das Ergebnis ist differenzierter, als man es erwartet. Die *statische* Methode (2,52) ist im Mittel besser als der Verzicht auf die alten Daten (2,65) und kommt der Referenz nahe, bei der das Kartendetail nie verloren ging (2,40). Der Gewinn dürfte hauptsächlich daher kommen, dass die 3000 alten Zeilen helfen, die Wirkung der sechs anderen Features zu schätzen (das ist eine Vermutung, die ich hier nicht getrennt gemessen habe); über die _Unterschiede zwischen den Kartenarten_ erfahren die alten Zeilen nichts, das bleibt Aufgabe der 60 neuen. Die *probabilistische* Methode (3,70) ist hier kaum besser als der Roll-up (3,76) und deutlich schlechter als der Verzicht auf die alten Daten. Eine naheliegende Erklärung: Die zufällig gezogene Kartenart ist für die einzelne alte Zeile meist falsch, und das wirkt wie Rauschen in der Eingabe, das die gelernten Gewichte der Kartenarten aufeinander zu zieht (die Ursache habe ich nicht eigens nachgemessen). Bei anderen Modellen und Daten kann das Ergebnis anders ausfallen. Das Beispiel zeigt vor allem, dass man beide Methoden nicht blind wählen darf, sondern gegen die Alternative „alte Daten weglassen“ testen muss.

#figure(
  diagram(
    node-stroke: 0.7pt + luma(140), node-fill: luma(240), node-corner-radius: 3pt, node-inset: 6pt,
    spacing: (16mm, 5mm),
    {
      node((0, -0.8), text(weight: "bold")[Altes Schema], stroke: none, fill: none)
      node((2, -0.8), text(weight: "bold")[Neues Schema], stroke: none, fill: none)
      node((0, 0), [`cash`], fill: rgb("#FBF1E6"), stroke: 0.8pt + orange)
      node((0, 2), [`card`], fill: rgb("#FBF1E6"), stroke: 0.8pt + orange)
      node((2, 0), [`cash`])
      node((2, 1), [`gift_card`])
      node((2, 2), [`debit_card`])
      node((2, 3), [`credit_card`])
      edge((0, 0), (2, 0), "->")
      edge((0, 2), (2, 1), "->", label: nebenbei[#sym.tilde 0,1], label-pos: 0.6, label-fill: true)
      edge((0, 2), (2, 2), "->", label: nebenbei[#sym.tilde 0,3], label-pos: 0.6, label-fill: true)
      edge((0, 2), (2, 3), "->", label: nebenbei[#sym.tilde 0,6], label-pos: 0.6, label-fill: true)
    },
  ),
  caption: [Bridged Schema. Eine alte `card`-Zeile wird auf die drei neuen Kartenarten verteilt, gewichtet mit den Häufigkeiten aus den neuen Daten (hier symbolisch 0,1/0,3/0,6). _Statisch_: ein Vektor mit diesen Anteilen. _Probabilistisch_: eine Kartenart wird gezogen.],
)

*Trade-offs und Grenzen.* Beide Methoden brauchen genug neue Daten, um die Anteile zuverlässig zu schätzen, und die Annahme gleicher Verteilungen kann falsch sein, etwa wenn Kunden mit Gutscheinkarten erst durch eine Kampagne hinzugekommen sind. Je größer der Anteil geschätzter Information, desto vorsichtiger muss man bei der Interpretation sein. *Wann nicht:* Wenn die neuen Daten für sich schon reichen, oder wenn sich das Verhalten selbst (nicht nur die Erfassung) geändert hat, ist eine Brücke falsch; dann zählen nur die neuen Daten.

*Bezug zu Software Engineering.* Das ist _Schema Evolution_ und _Rückwärtskompatibilität_, wie man sie aus Datenbankmigrationen und API-Versionierung kennt, nur dass man hier kein Feld „migrieren“ kann, weil die Information nie erhoben wurde. Das Gegenstück in der Datenbank ist eine Migration mit Standardwert; die probabilistische Methode ist ein Standardwert mit Verteilung. Das Muster ähnelt dem _Adapter_: Der alte Datenstand wird an die neue Schnittstelle angepasst.

#so-erklaere-ich-es(
  [Ich beginne mit einer Datenbankanalogie: Eine Spalte wird in drei neue zerlegt, für alte Zeilen gibt es keine Werte. Standardwert, NULL oder weglassen sind die bekannten Antworten; das Pattern ist die statistische. Dann zeige ich die Vergleichstabelle der Ausgabe.],
  [Warum ist es schlechter, die alte Kategorie `card` einfach als fünfte Kategorie zu behalten?],
  [Im Betrieb kommt `card` nie vor, es gibt nur die drei feinen Kartenarten. Das Modell lernt dann ein Gewicht für einen Wert, den es nie wieder sieht, und die alten Zeilen helfen nicht beim Verstehen der drei Kartenarten.],
)

*Quellen.* @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 23]

== Pattern 24: Windowed Inference

*Szenario.* An einer Werkzeugmaschine misst ein Sensor jede Minute die Temperatur. Ein Modell soll den nächsten Wert vorhersagen und Abweichungen melden. Es braucht dafür nicht nur den aktuellen Wert, sondern den _Mittelwert der letzten fünf Messungen_ als Feature.

*Das Problem.* Im Training ist das einfach: Man berechnet `rolling(5).mean()` über eine Spalte in pandas. Im Betrieb kommt jeder Messwert einzeln als Anfrage. Ein Serving-Modell ist in der Regel zustandslos (Pattern 16): Es kennt nur die Anfrage, nicht die vier davor. Jemand muss also die letzten Werte festhalten, bis das Fenster voll ist, und für jeden neuen Wert das Feature bilden. Entsteht dieser Code getrennt vom Trainingscode, droht dasselbe Skew wie bei Pattern 21, und schon ein um eins verschobenes Fenster fällt kaum auf. Tückisch ist ein Fehler wie `rolling(5).mean()` ohne vorheriges `shift(1)`: Das Fenster enthält dann den aktuellen Wert, also genau den, der vorhergesagt werden soll. Im Training sieht das Modell einen Teil der Lösung mit, im Betrieb nicht.

*Die Lösung.* Das Pattern verlegt das Fenster aus dem Modell hinaus in eine _Stream-Verarbeitung_, die den Zustand hält. Die Verarbeitung ordnet die Ereignisse einem _Zeitfenster_ zu, berechnet daraus das Feature und ruft erst dann das (zustandslose) Modell auf. Wichtig ist, dass dieselbe Fensterlogik im Training auf historischen Daten läuft: Das Buch nutzt dafür Apache Beam, dessen Programme sowohl als Batch als auch als Stream ausgeführt werden können @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 24]. Das zugrundeliegende Modell der Fensterung stammt aus dem Dataflow Model @akidau_dataflow_model_2015. Es kennt drei gängige Fensterarten: _Tumbling Windows_ (feste, überlappungsfreie Abschnitte, etwa jede volle Stunde; im Dataflow-Paper „fixed windows“), _Sliding Windows_ (feste Länge, die sich in kleinen Schritten verschiebt; das Beispiel unten vereinfacht das zu einem Fenster über die letzten fünf Werte statt über eine Zeitspanne) und _Session Windows_ (Abschnitte, die durch Pausen begrenzt werden). Für die Zuordnung zählt die _Ereigniszeit_ (wann etwas passierte), nicht die Verarbeitungszeit (wann es ankam); verspätete Ereignisse werden über sogenannte Watermarks behandelt.

Das Beispiel kommt ohne Stream-Framework aus: _eine_ Funktion definiert das Feature, zwei Treiber wenden sie an.

#code-datei("../code/08-reproducibility/24_windowed_inference.py", von: 11, bis: 46)

#lauf("24_windowed_inference.py", "../code/08-reproducibility/out/24_windowed_inference.txt")

Batch- und Stream-Variante liefern auf allen 1495 gültigen Zeitpunkten dieselben Werte (`np.allclose` ist wahr). Die beiden unteren Zeilen sind die Warnung. Das Modell mit dem richtigen Fenster (`'richtig'`) hat offline wie im Stream einen mittleren absoluten Fehler von 0,880. Wurde es mit dem fehlerhaften Fenster ohne `shift` trainiert (`'leck'`), meldet die Offline-Bewertung 0,727, scheinbar 17 % besser. Im Stream, wo der aktuelle Wert nicht zur Verfügung steht, erreicht dasselbe Modell 0,883. Es ist im Betrieb also kaum schlechter als das richtige, aber die Zahl, auf die das Team seine Entscheidungen stützt, ist falsch.

#figure(
  diagram(
    node-stroke: 0.7pt + luma(140), node-fill: luma(240), node-corner-radius: 3pt, node-inset: 6pt,
    spacing: (7mm, 5mm),
    {
      node((0, 0), [Sensor \ #nebenbei[Messwert pro Minute]])
      node((1, 0), [*Fensterung* \ #nebenbei[Ringpuffer, letzte 5]], fill: blau-hell, stroke: 0.9pt + blau)
      node((2, 0), [*Feature* \ #nebenbei[Mittelwert]], fill: blau-hell, stroke: 0.9pt + blau)
      node((3, 0), [Modell \ #nebenbei[zustandslos]])
      node((4, 0), [Vorhersage], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      node((0, 1.5), [Historische \ Messreihe])
      node((1, 1.5), [*Fensterung* \ #nebenbei[`rolling` + `shift`]], fill: blau-hell, stroke: 0.9pt + blau)
      node((2, 1.5), [*Feature* \ #nebenbei[Mittelwert]], fill: blau-hell, stroke: 0.9pt + blau)
      node((3, 1.5), [Training])
      node((4, 1.5), [Modell], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      edge((0, 0), (1, 0), "->")
      edge((1, 0), (2, 0), "->")
      edge((2, 0), (3, 0), "->")
      edge((3, 0), (4, 0), "->")
      edge((0, 1.5), (1, 1.5), "->")
      edge((1, 1.5), (2, 1.5), "->")
      edge((2, 1.5), (3, 1.5), "->")
      edge((3, 1.5), (4, 1.5), "->")
      edge((4, 1.5), (3, 0), "->", bend: -20deg, stroke: (dash: "dashed", paint: luma(120)))
      node((2, 0.75), text(size: 8.5pt, fill: gruen, weight: "bold")[eine Funktion für beide], stroke: none, fill: none)
    },
  ),
  caption: [Oben der Betrieb (Stream), unten das Training (Batch): beide rufen dieselbe Feature-Funktion auf. Das Modell selbst bleibt zustandslos; der Zustand liegt im Ringpuffer der Fensterung.],
)

*Trade-offs und Grenzen.* Das Fenster muss erst gefüllt sein, bevor die erste Vorhersage möglich ist (_Cold Start_). Der Zustand im Stream-Prozessor muss einen Absturz überstehen (Checkpoints), sonst fehlen nach einem Neustart Messwerte. Ereignisse kommen verspätet oder in falscher Reihenfolge an; ob man warten oder weiterrechnen soll, ist ein Kompromiss zwischen Latenz und Genauigkeit. Das größte praktische Risiko bleibt der Unterschied zwischen _Ereigniszeit_ im Training und _Verarbeitungszeit_ im Stream: Rechnet das Training nach Zeitstempeln der Daten und der Stream nach Ankunftszeit, stimmen die Fenster nicht überein. *Wann nicht:* Braucht das Modell kein Gedächtnis, ist das Pattern unnötiger Aufwand. Reichen Aggregate, die einmal täglich neu berechnet werden, genügt Batch Serving (Pattern 17) mit vorberechneten Features.

*Bezug zu Software Engineering.* Hier trennt man einen _funktionalen Kern_ (die reine Funktion `fenster_merkmale`) von einer _imperativen Hülle_ (dem Zustand, dem Puffer). Reine Funktionen lassen sich leicht testen, und der Test, der Batch und Stream auf denselben Daten vergleicht (`np.allclose` in der Ausgabe), ist ein klassischer Äquivalenztest. Der Ringpuffer ist eine _Queue fester Größe_, wie sie aus Rate Limitern und Buffern bekannt ist.

#so-erklaere-ich-es(
  [Ich lasse an der Tafel eine Messreihe aufschreiben und die Studierenden das Fenster-Feature für den sechsten Wert von Hand bilden. Danach frage ich, wo diese fünf Werte im Betrieb herkommen, wenn jede Anfrage nur einen Wert enthält. Daraus entsteht von selbst die Idee eines Zustandsspeichers vor dem Modell.],
  [Warum ist `rolling(5).mean()` ohne `shift(1)` ein Fehler, obwohl die Zahlen plausibel aussehen?],
  [Das Fenster schließt den aktuellen Wert ein, den das Modell vorhersagen soll. Im Training steht ein Teil der Antwort im Feature, im Betrieb nicht. Die Offline-Bewertung ist dadurch geschönt, und das Team weiß nicht, wie gut das Modell wirklich ist.],
)

*Quellen.* @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 24] @akidau_dataflow_model_2015

== Pattern 25: Workflow Pipeline

*Szenario.* Ein Team hat sein Churn-Modell (Vorhersage, welche Kundinnen und Kunden kündigen) in einem Notebook entwickelt: Daten laden, bereinigen, Features bauen, trainieren, bewerten, exportieren. Die Zellen müssen in einer bestimmten Reihenfolge laufen. Die Feature-Berechnung dauert drei Stunden, das Training eine. Wer das Notebook erneut ausführt, bekommt andere Zahlen, weil eine Variable aus einer gelöschten Zelle noch im Speicher liegt. Niemand weiß mehr genau, mit welchem Datenstand das Modell in Produktion gebaut wurde.

*Das Problem.* Ein Notebook ist ein hervorragendes Werkzeug für Exploration, aber ein schlechtes Ausführungsmodell: Zustand versteckt sich im Interpreter, Schritte sind nicht einzeln wiederholbar, Abhängigkeiten stehen nirgends. Fällt Schritt 4 aus, beginnt man bei Schritt 1. Ein Skript, das alles am Stück ausführt, bleibt ein Monolith, den man nicht stückweise wiederholen, parallelisieren oder auf andere Hardware legen kann.

*Die Lösung.* Das Pattern zerlegt den Ablauf in _Schritte_ mit klar benannten Ein- und Ausgaben. Jeder Schritt läuft für sich, bekommt seine Eingaben als _Artefakte_ (Dateien, Tabellen, Modelle) und legt seine Ausgaben als Artefakte ab. Die Abhängigkeiten zwischen den Schritten bilden einen _gerichteten azyklischen Graphen_ (DAG): Pfeile zeigen, welcher Schritt auf welchen wartet, Zyklen gibt es nicht. Ein _Orchestrator_ führt den Graphen aus, wiederholt fehlgeschlagene Schritte, startet unabhängige Schritte parallel und merkt sich, was schon gelaufen ist. Im Buch läuft jeder Schritt in einem eigenen _Container_ @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 25]: Ein Container bündelt Code, Bibliotheken und Betriebssystemumgebung, sodass der Schritt überall gleich läuft. Damit ist auch die dritte Quelle aus der Einleitung, die Umgebung, festgeschrieben.

Das Beispielprogramm ist ein Mini-Orchestrator: ein gerichteter azyklischer Graph (DAG) aus vier Funktionen, ausgeführt in topologischer Reihenfolge (`graphlib` aus der Standardbibliothek). Das Wesentliche ist der _Fingerabdruck_ jedes Schritts, ein Hash aus seinem Quelltext, seinen Parametern und den Fingerabdrücken seiner Vorgänger. Liegt ein Ergebnis mit diesem Fingerabdruck im Cache, wird der Schritt nicht neu berechnet.

#code-datei("../code/08-reproducibility/25_mini_pipeline.py", von: 38, bis: 58)

#lauf("25_mini_pipeline.py", "../code/08-reproducibility/out/25_mini_pipeline.txt")

Im ersten Lauf werden alle vier Schritte berechnet, der Fingerabdruck steht in Klammern. Der zweite Lauf mit unveränderten Parametern kommt komplett aus dem Cache. Im dritten Lauf wird nur `n_estimators` des Trainings von 100 auf 300 geändert: `laden` und `teilen` bleiben im Cache, `trainieren` und `evaluieren` werden neu berechnet, weil sich der Fingerabdruck von `trainieren` ändert und `evaluieren` ihn als Vorgänger in den eigenen aufnimmt. Das kennt man von einem Build-System.

#figure(
  diagram(
    node-stroke: 0.7pt + luma(140), node-fill: luma(240), node-corner-radius: 3pt, node-inset: 6pt,
    spacing: (9mm, 5mm),
    {
      let schritt(pos, name, sub, ..args) = node(pos, [*#name* \ #nebenbei(sub)], ..args)
      schritt((0, 1), [laden], [Container A])
      schritt((1, 1), [validieren], [Container B])
      schritt((2, 0), [Features], [Container C], fill: blau-hell, stroke: 0.9pt + blau)
      schritt((2, 2), [Benchmark], [Container D])
      schritt((3, 0), [trainieren], [Container E, GPU], fill: blau-hell, stroke: 0.9pt + blau)
      schritt((4, 1), [bewerten], [Container F])
      schritt((5, 1), [registrieren], [Container G], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      edge((0, 1), (1, 1), "->")
      edge((1, 1), (2, 0), "->")
      edge((1, 1), (2, 2), "->")
      edge((2, 0), (3, 0), "->")
      edge((3, 0), (4, 1), "->")
      edge((2, 2), (4, 1), "->")
      edge((4, 1), (5, 1), "->")
    },
  ),
  caption: [Eine Workflow Pipeline als DAG. Jeder Kasten ist ein eigener Container mit festgelegter Umgebung. Unabhängige Zweige (hier Features/Training und Benchmark) können parallel laufen, ein Fehler in `trainieren` wiederholt nur diesen Schritt.],
)

*Werkzeuge einordnen.* Die Begriffe werden oft vermischt, deshalb eine Abgrenzung.

- *Apache Airflow* ist ein allgemeiner Workflow-Scheduler. DAGs werden in Python beschrieben, Tasks laufen nach Zeitplan oder auf Auslöser, auch in Containern. Airflow kennt weder Modelle noch ML-Artefakte; es ist ein Werkzeug für beliebige Datenpipelines, ETL eingeschlossen.
- *Kubeflow Pipelines* ist ein Orchestrator speziell für ML auf Kubernetes. Jeder Schritt (eine _Komponente_) ist ein Container, Pipelines werden mit einem Python-SDK definiert, Artefakte und Läufe werden mit Metadaten festgehalten. Das Buch nutzt es als Beispiel für die Umsetzung des Patterns @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 25].
- *TFX* (TensorFlow Extended) ist keine Laufzeit, sondern eine Bibliothek standardisierter Komponenten für ML-Pipelines (unter anderem ExampleGen, StatisticsGen, SchemaGen, Transform, Trainer, Evaluator, Pusher; so heißen sie in der TFX-Dokumentation), die auf einem Orchestrator ausgeführt werden, etwa Airflow, Apache Beam oder Kubeflow Pipelines. Das Konzept der Plattform beschreiben #cite(<baylor_tfx_2017>, form: "prose").
- Leichtgewichtige Alternativen für kleinere Vorhaben sind Dagster, Prefect oder Metaflow, oder noch einfacher DVC mit einer `dvc.yaml`, die Schritte, Abhängigkeiten und Ausgaben beschreibt und das Zwischenergebnis nach Eingabe-Hash wiederverwendet.

Im Kubeflow-SDK (Version 2) sieht eine Komponente so aus; die Skizze wurde nicht ausgeführt (Ausführen braucht einen Kubernetes-Cluster) und ist unvollständig: `merkmale` wäre eine weitere Komponente nach demselben Muster.

```python
from kfp import dsl

@dsl.component(base_image="python:3.12", packages_to_install=["scikit-learn"])
def trainieren(daten: dsl.Input[dsl.Dataset], modell: dsl.Output[dsl.Model],
               n_estimators: int = 100):
    ...  # liest daten.path, schreibt modell.path

@dsl.pipeline(name="churn")
def pipeline(n_estimators: int = 100):
    m = merkmale()
    trainieren(daten=m.outputs["daten"], n_estimators=n_estimators)
```

*Trade-offs und Grenzen.* Pipelines kosten Aufwand: Schritte brauchen Schnittstellen, Container müssen gebaut und versioniert werden, und die Fehlersuche ist anstrengender als im interaktiven Notebook, weil man nicht „einfach in die Zelle schauen“ kann. Dazu kommt Overhead für Containerstart und das Übergeben von Artefakten. *Wann nicht:* In der Explorationsphase und bei einmaligen Analysen. Der übliche Weg ist, erst im Notebook zu erkunden und die Schritte dann in eine Pipeline zu überführen, sobald der Ablauf feststeht und wiederholt werden soll.

*Bezug zu Software Engineering.* Das Konzept ist ein _Build-System_: Make, Bazel oder Gradle kennen DAGs, Abhängigkeiten und Caching nach Eingaben. Die Pipeline ist dazu das Äquivalent einer CI-Pipeline für Daten und Modelle. Die Container-Seite entspricht der Idee, Anwendungen als reproduzierbare Images zu bauen; die Fingerabdrücke entsprechen der Content-Addressable Storage, wie sie Git oder Docker-Layer nutzen.

#so-erklaere-ich-es(
  [Ich zeige das 3-Stunden-Notebook und frage, was passiert, wenn Zelle 5 nach einer Änderung an Zelle 2 neu laufen soll. Wer ein Build-System kennt, versteht den DAG sofort: Die Pipeline ist `make` für Daten, mit Containern statt lokaler Compiler.],
  [Warum identifiziert der Cache ein Ergebnis über einen Hash und nicht über den Zeitstempel der Datei?],
  [Ein Zeitstempel sagt nur, _wann_ etwas entstand, nicht, _woraus_. Der Hash über Code, Parameter und Eingaben ändert sich genau dann, wenn sich das Ergebnis ändern könnte, und bleibt gleich, wenn jemand dieselbe Datei neu schreibt.],
)

*Quellen.* @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 25] @baylor_tfx_2017 @zaharia_mlflow_2018

== Pattern 26: Feature Store

*Szenario.* Zwei Teams eines Onlinehändlers trainieren Modelle, die beide das Feature „Bestellungen der letzten 30 Tage“ brauchen. Das eine Team zählt gleitend 30 Tage rückwärts, das andere den Kalendermonat, ein drittes rechnet in lokaler Zeit statt UTC. Im Betrieb kann ein Service die Summe über Millionen Bestellungen nicht bei jeder Anfrage neu berechnen; man legt sie also in einer Tabelle ab, die ein Team pflegt, das nicht das Training macht.

*Das Problem.* Es kommen vier Probleme zusammen. Erstens _Doppelarbeit und Inkonsistenz_: Dasselbe Feature existiert in mehreren Varianten, die niemand abgleicht. Zweitens _Training-Serving Skew_: Offline wird das Feature anders berechnet als online. Drittens _Latenz_: Aggregate über große Datenmengen sind im Online-Pfad zu langsam. Viertens, am wenigsten offensichtlich, die _zeitliche Korrektheit_: Beim Bau von Trainingsdaten braucht man für jedes Beispiel den Wert, den das Feature _zum damaligen Zeitpunkt_ hatte, nicht den heutigen.

*Die Lösung.* Ein *Feature Store* ist ein System, das Features als wiederverwendbare, benannte und versionierte Objekte verwaltet. Es besteht aus mehreren Teilen:

- einer *Registry* mit Definition, Besitzer und Beschreibung jedes Features (im Wesentlichen ein Katalog),
- einem *Offline-Store* mit der _gesamten Historie_ der Feature-Werte, optimiert für große Abfragen (Data Warehouse, Parquet-Dateien), aus dem Trainingsdaten gebaut werden,
- einem *Online-Store* mit dem _jeweils letzten_ Wert je Entität, optimiert für Schlüsselzugriffe in Millisekunden (Redis, DynamoDB oder Bigtable),
- einer *Materialisierung*, die regelmäßig oder kontinuierlich Werte vom Offline- in den Online-Store schreibt.

Training und Betrieb fragen denselben Katalog; die Definition des Features steht an einer Stelle. Das Buch beschreibt das Pattern entsprechend @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 26]. Ein bekanntes Open-Source-Beispiel ist Feast @feast_docs; Hopsworks, Tecton und mehrere Cloud-Anbieter haben eigene Produkte; das Buch nennt Feast und Hopsworks.

#figure(
  diagram(
    node-stroke: 0.7pt + luma(140), node-fill: luma(240), node-corner-radius: 3pt, node-inset: 6pt,
    spacing: (9mm, 6mm),
    {
      node((0, 0.5), [Rohdaten \ #nebenbei[Batch und Stream]])
      node((1, 0.5), [*Features-\ berechnung* \ #nebenbei[eine Definition]], fill: blau-hell, stroke: 0.9pt + blau)
      node((2.2, 0), [*Offline-Store* \ #nebenbei[Historie, große Scans]], fill: blau-hell, stroke: 0.9pt + blau)
      node((2.2, 1), [*Online-Store* \ #nebenbei[letzter Wert je Schlüssel]], fill: blau-hell, stroke: 0.9pt + blau)
      node((3.7, 0), [Training \ #nebenbei[Point-in-Time-Join]], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      node((3.7, 1), [Serving \ #nebenbei[Lookup per ID]], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      edge((0, 0.5), (1, 0.5), "->")
      edge((1, 0.5), (2.2, 0), "->")
      edge((1, 0.5), (2.2, 1), "->")
      edge((2.2, 0), (2.2, 1), "->", label: nebenbei[Materialisierung], label-side: right, label-sep: 2pt)
      edge((2.2, 0), (3.7, 0), "->")
      edge((2.2, 1), (3.7, 1), "->")
    },
  ),
  caption: [Aufbau eines Feature Stores: Eine Feature-Berechnung füllt Offline- und Online-Store; Training liest die Historie, der Betrieb liest den aktuellen Wert.],
)

*Point-in-Time-Korrektheit.* Dieser Punkt wird in der Praxis häufig falsch gemacht. Angenommen, man sagt auf Basis der Bestellungen am 1. Juli voraus, wer bis Jahresende kündigt. Wer gekündigt hat, bestellt danach nichts mehr. Nimmt man als Trainings-Feature den „aktuellen“ Wert der Tabelle (Dezember), steht dort für jeden Kündiger eine 0, und das Modell sieht die Antwort im Feature. Richtig ist der _As-of-Join_: Für jedes Beispiel nimmt man den letzten Wert, dessen Zeitstempel _vor oder gleich_ dem Vorhersagezeitpunkt liegt.

#code-datei("../code/08-reproducibility/26_point_in_time.py", von: 26, bis: 38)

#lauf("26_point_in_time.py", "../code/08-reproducibility/out/26_point_in_time.txt")

Die _AUC_ ist hier die Wahrscheinlichkeit, dass ein Kunde mit Kündigung einen niedrigeren Feature-Wert hat als einer ohne (0,5 heißt Raten, 1 heißt perfekt). Der naive Join erreicht allein mit diesem einen Feature eine AUC von 0,969, der Point-in-Time-Join nur 0,576. Der erste Wert ist ein Zukunftsleck: Das Feature verrät nur deshalb die Kündigung, weil es nach der Kündigung gemessen wurde. Die ausgegebenen Zeilen zeigen das Ergebnis des korrekten Joins: Alle Beispiele tragen den Zeitstempel 1. Juli und den dazu passenden Feature-Wert.

Ein Feature Store macht diesen Join zur Standardoperation. In Feast sieht das so aus; die Skizze ist hier nicht ausgeführt:

```python
merkmal = ["bestellverhalten:bestellungen_30d"]   # "Feature View:Feature"

# Training: Point-in-Time-Join gegen den Offline-Store
trainingsdaten = store.get_historical_features(
    entity_df=beispiele,                # Spalten: kunde, event_timestamp
    features=merkmal,
).to_df()

# Betrieb: Online-Store, nach der Materialisierung
store.materialize_incremental(end_date=datetime.now())
werte = store.get_online_features(
    features=merkmal, entity_rows=[{"kunde": 42}],
).to_dict()
```

*Trade-offs und Grenzen.* Ein Feature Store ist eine weitere Infrastrukturkomponente, die jemand betreiben muss, und er lohnt sich erst, wenn mehrere Modelle oder Teams Features gemeinsam nutzen. Die Aktualität des Online-Stores hängt vom Rhythmus der Materialisierung ab; ein stündlicher Lauf liefert Werte, die bis zu einer Stunde alt sind. Features, die erst aus den Daten der Anfrage entstehen (die Distanz einer Fahrt), gehören weiter in die Transformation des Modells (Pattern 21) und nicht in den Store. *Wann nicht:* Bei einem einzelnen Modell mit wenigen, billig berechenbaren Features ist eine gut getestete Funktion, die Training und Betrieb teilen, der einfachere Weg.

*Bezug zu Software Engineering.* Der Offline-Store ist die „Quelle der Wahrheit“, der Online-Store ein auf Schlüsselzugriffe optimierter, materialisierter Cache davon, vergleichbar mit einer Read-Replica oder einer Materialized View. Die Registry entspricht einem Service-Katalog oder einer Paketverwaltung für Features; ein Feature hat einen Besitzer und eine Version wie eine Bibliothek.

#so-erklaere-ich-es(
  [Ich beginne mit zwei Teams und zwei Definitionen von „aktiver Kunde“, das kennt jeder aus Reportings. Dann zeichne ich die Zeitachse an die Tafel und markiere „heute“ und den Vorhersagezeitpunkt. Dass man beim Bau der Trainingsdaten versehentlich in die Zukunft schauen kann, überrascht viele.],
  [Warum braucht der Trainingsdatensatz den Wert des Features vom damaligen Zeitpunkt und nicht den aktuellen?],
  [Im Betrieb steht dem Modell zum Vorhersagezeitpunkt nur der damalige Stand zur Verfügung. Wer im Training spätere Werte verwendet, trainiert auf Informationen, die es im Betrieb nie geben wird (Zukunftsleck), und das Modell wirkt offline besser, als es ist.],
)

*Quellen.* @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 26] @feast_docs @sculley_hidden_debt_2015

== Pattern 27: Model Versioning

*Szenario.* Ein Modell bewertet Zahlungen auf Betrug. Drei Anwendungen rufen es auf. Das Team hat ein neues, besseres Modell trainiert, das etwas anders kalibriert ist und für dieselben Eingaben teilweise andere Wahrscheinlichkeiten liefert. Man tauscht das Modell einfach aus.

*Das Problem.* Ein Austausch „an Ort und Stelle“ hat vier Nachteile. Clients, die sich auf das alte Verhalten verlassen (Schwellenwerte, die auf die alten Wahrscheinlichkeiten abgestimmt sind), brechen ohne Vorwarnung. Bei einer Verschlechterung gibt es keinen schnellen Rückweg. Man kann die Modelle nicht auf denselben Anfragen vergleichen. Und später ist unklar, welches Modell eine bestimmte Entscheidung getroffen hat, was bei Beschwerden und Audits wichtig ist.

*Die Lösung.* Das Pattern betreibt neue Modellversionen _neben_ den alten, jede unter einem eigenen Endpunkt, etwa `/v1/vorhersage` und `/v2/vorhersage` @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 27]. Clients wechseln, wenn sie bereit sind; die alte Version wird erst abgeschaltet, wenn niemand sie mehr braucht. Das setzt *Rückwärtskompatibilität* voraus: Eine neue Version soll die Eingabe der alten akzeptieren (neue Eingaben sind optional mit Standardwert) und möglichst dieselbe Ausgabestruktur liefern. Nicht vermeidbare Brüche, etwa eine andere Bedeutung des Ausgabewerts, rechtfertigen eine neue Hauptversion.

Hinter den Endpunkten steht eine *Modell-Registry*, ein Katalog der Modellartefakte mit Versionsnummer und Metadaten: Trainingsdaten-Stand, Code-Commit, Metriken, erwartete Eingabestruktur (die _Signatur_), Ersteller und Freigabestatus. Zusätzlich vergibt man _Aliase_ für den Betrieb, etwa `production` und `canary`, die auf Versionen zeigen. Das Beispielprogramm baut eine winzige Registry:

#code-datei("../code/08-reproducibility/27_model_versioning.py", von: 14, bis: 31)

#code-datei("../code/08-reproducibility/27_model_versioning.py", von: 41, bis: 49)

#lauf("27_model_versioning.py", "../code/08-reproducibility/out/27_model_versioning.txt")

Version 2 (Gradient Boosting) erreicht eine Genauigkeit von 0,843 gegenüber 0,791 für Version 1 (logistische Regression). Beim Canary mit 10 % gehen 89 von 1000 Anfragen an Version 2; der Anteil weicht von 100 ab, weil die Zuordnung per Hash der Anfrage-ID erfolgt und damit nur im Mittel genau 10 % ergibt. Die beiden Versionen stimmen bei 87 % der Testanfragen überein, bei den übrigen 13 % entscheidet die Version über das Ergebnis; das sind die Fälle, die man sich im Shadow-Vergleich genauer ansieht. Der Rollback in den letzten Zeilen ist ein einziger Alias-Wechsel.

*Betriebsmuster.* Aus parallelen Versionen ergeben sich Einführungsstrategien, die man aus dem Deployment kennt. Beim _Shadow Mode_ erhält die neue Version die Anfragen mit, ihre Antworten werden aber nur protokolliert und verglichen. Beim _Canary_ bekommt ein kleiner Anteil (hier 10 %) der Anfragen die neue Version; die Zuordnung per Hash der Anfrage-ID bleibt für dieselbe ID stabil; für eine feste Zuordnung je Client hasht man die Client-ID. Beim _A/B-Test_ vergleicht man beide Versionen an einer Geschäftskennzahl. Der _Rollback_ ist ein Alias-Wechsel, kein Neu-Deployment. Werkzeuge: MLflow bietet eine Model Registry mit Versionen und Aliasen (ältere Versionen kannten feste Stufen wie Staging und Production, neuere frei benennbare Aliase), TFX hat mit der Komponente Pusher einen Schritt, der ein freigegebenes Modell an ein Ziel wie ein Serving-System ausliefert @zaharia_mlflow_2018 @baylor_tfx_2017.

#figure(
  diagram(
    node-stroke: 0.7pt + luma(140), node-fill: luma(240), node-corner-radius: 3pt, node-inset: 6pt,
    spacing: (10mm, 4mm),
    {
      node((0, 1), [Clients])
      node((1, 1), [*Router* \ #nebenbei[Alias + Hash der Anfrage]], fill: blau-hell, stroke: 0.9pt + blau)
      node((2.3, 0), [`/v1`  Version 1 \ #nebenbei[Alias: production, 90 %]])
      node((2.3, 2), [`/v2`  Version 2 \ #nebenbei[Alias: canary, 10 %]], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      node((2.3, 1), [*Registry* \ #nebenbei[Version · Metriken · Daten · Commit]], fill: blau-hell, stroke: 0.9pt + blau)
      edge((0, 1), (1, 1), "->")
      edge((1, 1), (2.3, 0), "->")
      edge((1, 1), (2.3, 2), "->")
      edge((1, 1), (2.3, 1), "<->", stroke: (dash: "dashed", paint: luma(120)), label: nebenbei[Alias], label-side: left)
      edge((2.3, 1), (2.3, 0), "->", stroke: (dash: "dashed", paint: luma(120)), label: nebenbei[Artefakt], label-side: right)
      edge((2.3, 1), (2.3, 2), "->", stroke: (dash: "dashed", paint: luma(120)), label: nebenbei[Artefakt], label-side: right)
    },
  ),
  caption: [Model Versioning: mehrere Versionen laufen nebeneinander. Die Registry verwaltet die Artefakte und sagt dem Router, welche Version welchen Alias trägt; ein Rollback ändert nur diesen Alias.],
)

*Trade-offs und Grenzen.* Jede laufende Version kostet Rechenleistung und Betriebsaufwand, und ohne Abkündigungsregeln sammeln sich Altversionen an. A/B-Vergleiche brauchen genug Verkehr und oft verzögerte Labels (erst Wochen später weiß man, ob die Zahlung Betrug war), weshalb sie mit Continued Model Evaluation (Pattern 18) zusammen gedacht werden müssen. Schließlich ist die Modellversion nur dann reproduzierbar, wenn auch Daten und Code hinter ihr festgehalten sind; die Registry hilft dabei nur, wenn sie diese Verweise tatsächlich speichert. *Wann nicht:* Bei internen Modellen mit genau einem Aufrufer, die in Minuten neu ausgerollt werden können, reicht ein sauberes Deployment mit Versionsmarkierung im Log.

*Bezug zu Software Engineering.* Das ist API-Versionierung (Semantic Versioning, Expand/Contract bei Schemaänderungen) kombiniert mit Release-Strategien wie Blue-Green und Canary Deployment. Die Registry entspricht einem Artefakt-Repository für Pakete, die Aliase den Tags in Git oder Container-Registries.

#so-erklaere-ich-es(
  [Ich frage, was ein Team tut, wenn es die Signatur einer Bibliotheksfunktion ändern will, ohne die Aufrufer zu brechen: Version parallel anbieten, Aufrufer migrieren lassen, alte Version abkündigen. Mit diesem Vergleich ist klar, dass ein Modell dasselbe Problem hat.],
  [Warum reicht ein Git-Tag auf dem Trainingscode nicht, um ein Modell eindeutig zu identifizieren?],
  [Das Modell entsteht aus Code, Daten, Parametern und Zufall. Derselbe Commit auf anderen Daten liefert ein anderes Modell. Die Registry hält das Ergebnis samt allen Verweisen fest.],
)

*Quellen.* @lakshmanan_ml_design_patterns_2020[Kapitel 6, Pattern 27] @zaharia_mlflow_2018 @baylor_tfx_2017

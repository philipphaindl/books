#import "../lib.typ": *

// Kapitelinterne Hilfen: Studien- und Beweisboxen nicht über Seiten trennen
#let studie-fest(..args) = block(breakable: false, width: 100%, studie(..args))
#let beweis-fest(body) = block(breakable: false, width: 100%, beweis(body))
#let hoersaal-fest(frage, antwort) = block(breakable: false, width: 100%, hoersaal(frage, antwort))
#let datei-fest(name, body) = block(breakable: false, width: 100%, datei(name, body))

= Forschungsmethoden: qualitativ, quantitativ, gemischt <k01>

Wer ein Large Language Model als Forschungsinstrument einsetzt, betreibt keine neue Wissenschaft, sondern alte Wissenschaft mit einem neuen, schwer durchschaubaren Werkzeug. Ein LLM, das Interviews codiert, ersetzt einen menschlichen Codierer in einer qualitativen Analyse. Ein LLM, das Fragebögen "beantwortet", tritt an die Stelle von Befragten in einem Survey. Ein LLM, das zwei Systeme bewertet, wird zum Messinstrument eines Experiments, dessen Ergebnisse in einen Hypothesentest fließen. In jedem dieser Fälle erbt der LLM-Einsatz die Gütekriterien, die Fallstricke und die Debatten der Methode, in die er eingebettet ist. Wer diese Methoden nicht sicher beherrscht, kann auch nicht beurteilen, ob ein LLM sie verbessert oder still beschädigt.

Dieses Kapitel legt deshalb das methodische Fundament für das ganze Buch. Es folgt der Gliederung des Lehrbuchs *Research Methods for Computer Science and Software Engineering* @haindl2027research, aus dem Begriffe, Hierarchien und Entscheidungsrahmen übernommen werden, und ergänzt es um den Forschungsstand bis zu den großen Replikations- und Robustheitsstudien des SCORE-Programms, die im April 2026 in _Nature_ erschienen sind @tyner2026investigating @aczel2026investigating @miske2026investigating. Die Darstellung ist bewusst doppelt angelegt: Jedes Konzept wird zuerst intuitiv motiviert, dann formal gefasst und, wo es Mathematik gibt, hergeleitet und an einem durchgerechneten Beispiel geprüft. Alle Zahlen in den Rechenbeispielen wurden mit Python nachgerechnet; die Codeausschnitte stammen aus dem Notebook `notebooks/01_power_and_leakage.ipynb` und aus der Wissensbasis der Lehrveranstaltung und gehören zu Foliensatz 01 der LV.

Für die Arbeit mit LLMs sind drei Einsichten dieses Kapitels zentral. Erstens entscheidet das Paradigma einer Studie über ihre Gütekriterien; ob eine Übereinstimmung zwischen LLM und Mensch überhaupt ein sinnvolles Qualitätsmaß ist, hängt davon ab, welche Variante der Thematischen Analyse automatisiert wird @braun2021one. Zweitens produziert jede analytische Wahlfreiheit implizite Mehrfachvergleiche; Prompt-Formulierung, Modellversion, Temperatur und Metrik sind genau solche Gabelungen @gelman2014statistical. Drittens ist die Glaubwürdigkeit empirischer Forschung messbar schlechter als ihr Ruf, und maschinelles Lernen hat mit dem Datenleck (_data leakage_) eine eigene Variante der Replikationskrise hervorgebracht @kapoor2023leakage.

#lernziele[
  die Hierarchie Paradigma -> Methodologie -> Methode -> Instrument anwenden und Paradigmen einer Studie zuordnen,
][
  Forschungsfragen nach ihrem Zweck klassifizieren und daraus begründet ein Design ableiten,
][
  eine Interviewstudie mit Sättigungs- oder Information-Power-Begründung planen und die passende TA-Variante wählen,
][
  Effektstärken ($d$, $d_z$, $eta_p^2$) und den Stichprobenumfang eines $t$-Tests herleiten, berechnen und interpretieren,
][
  PPV, familienweise Fehlerrate und Forking Paths formal begründen und simulieren, Leakage nach REFORMS prüfen,
][
  ein Mixed-Methods-Design mit Integrationspunkten und Joint Display entwerfen,
][
  Validitätsbedrohungen einer LLM-Evaluation benennen und für jede Methode den Eintrittspunkt eines LLM bestimmen.
]

== Forschung, Begriffshierarchie und Paradigmen <k01-hierarchie>

=== Was Forschung ist und was nicht

Bevor man Studien entwirft, lohnt eine präzise Bestimmung dessen, was Forschung überhaupt ist. Das Lehrbuch definiert sie als *systematische Untersuchung*, die darauf angelegt ist, *generalisierbares Wissen* zu entwickeln oder dazu beizutragen @haindl2027research. Jedes Element der Definition trägt Gewicht. *Systematisch* heißt, organisierten, methodischen Verfahren zu folgen statt planlos zu explorieren, und diese Verfahren so gründlich zu dokumentieren, dass andere sie bewerten, kritisieren und gegebenenfalls replizieren können. *Entwickeln oder beitragen* heißt, dass Forschung dem vorhandenen Wissen etwas hinzufügen muss: einen neuen Algorithmus, eine bisher unbekannte Schwachstelle, aber auch die Verfeinerung, Erweiterung oder Infragestellung bestehenden Wissens; selbst negative Ergebnisse tragen bei, wenn sie belastbar zeigen, dass ein vielversprechender Ansatz nicht funktioniert. *Generalisierbar* heißt, dass das Wissen über den untersuchten Einzelfall hinausreicht; wer ein Konsensprotokoll evaluiert, interessiert sich nicht nur für das eigene Testnetz, sondern für das Verhalten unter anderen Netzbedingungen, Größenordnungen und Fehlermodi @haindl2027research.

Davon grenzt das Lehrbuch die *Suche* ab. Suchen heißt, vorhandene Information zu finden und abzurufen, etwa bestehende Modellarchitekturen und Strategien des Hyperparameter-Tunings nachzuschlagen. Forschung heißt, systematisch zu untersuchen, warum bestimmte Architekturen bei bestimmten Dateneigenschaften besser abschneiden, theoretische Erklärungen dafür zu entwickeln und sie experimentell zu prüfen. Der Unterschied liegt nicht im Gegenstand, sondern darin, ob vorhandenes Wissen entdeckt oder neues erzeugt wird. Ein Literaturreview ist zunächst Suche; Forschung wird es, wenn die Synthese Muster, Lücken oder Widersprüche sichtbar macht, die vorher nicht erkannt waren @haindl2027research.

#merke[Die Unterscheidung von Forschung und Suche ist für LLM-gestützte Arbeit besonders relevant. Ein LLM, das Literatur zusammenfasst oder Architekturvorschläge macht, unterstützt die Suche. Ob daraus Forschung wird, hängt davon ab, ob die Synthese systematisch, dokumentiert und überprüfbar erfolgt; genau diese Eigenschaften gehen verloren, wenn Prompts, Modellversionen und Zwischenergebnisse nicht festgehalten werden.]

=== Eine Hierarchie gegen die Begriffsverwirrung

Methodische Diskussionen scheitern erstaunlich oft an unscharfen Begriffen. Das Lehrbuch ordnet die Vokabeln deshalb in eine Hierarchie aus vier Ebenen, bei der jede Ebene auf der darüberliegenden aufbaut und von ihr eingeschränkt wird @haindl2027research (@k01-fig-hierarchie).

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let ebenen = (
      ([Forschungsparadigma], [philosophische Ebene], [Grundannahmen über Realität (Ontologie) und Erkenntnis (Epistemologie)], [Positivismus, Konstruktivismus, transformatives Paradigma, Pragmatismus], c-blue),
      ([Forschungsmethodologie], [strategische Ebene], [Gesamtstrategie, die Philosophie und Praxis verbindet und die Forschungslogik liefert], [Fallstudie, Experiment, Ethnografie, Design Science], c-teal),
      ([Forschungsmethoden], [taktische Ebene], [konkrete Techniken zur Erhebung und Analyse von Daten], [Interviews, Surveys, Beobachtung, Dokumentenanalyse, Performance-Benchmarks], c-violet),
      ([Forschungsinstrumente], [operative Ebene], [die tatsächlichen Werkzeuge der Datenerhebung], [Interviewleitfaden, Fragebogen, Codierschema, Messskala, Benchmark-Suite, Prompt], c-accent),
    )
    for (i, (t, lvl, desc, ex, col)) in ebenen.enumerate() {
      let y = -i * 1.75
      rect((0, y - 0.65), (12, y + 0.65), radius: 0.1, fill: col.lighten(90%), stroke: 0.8pt + col)
      content((0.25, y + 0.35), anchor: "west", text(font: "Inter", size: 8pt, weight: "bold", fill: col.darken(20%), t) + text(font: "Inter", size: 7pt, style: "italic", fill: c-grey.darken(20%), [ (#lvl)]))
      content((0.25, y - 0.02), anchor: "west", text(font: "Inter", size: 7.2pt, desc))
      content((0.25, y - 0.38), anchor: "west", text(font: "Inter", size: 6.6pt, fill: c-grey.darken(30%), [Beispiele: #ex]))
      if i < 3 { pfeil((6, y - 0.68), (6, y - 1.07)) }
    }
    line((-0.35, 0.65), (-0.35, -3 * 1.75 - 0.65), stroke: 0.8pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.6))
    content((-0.6, -2.6), angle: 90deg, text(font: "Inter", size: 7pt, fill: c-dark, [zunehmende Konkretheit]))
  }),
  caption: [Die Begriffshierarchie der Forschung nach @haindl2027research; Benchmarks und Benchmark-Suite nach dem Lehrbuchtext, der Prompt als Instrument ist eine Ergänzung dieses Buchs. Ein Prompt ist in dieser Ordnung ein Instrument, kein Methodenbestandteil, und muss wie ein Fragebogen entwickelt und validiert werden.],
) <k01-fig-hierarchie>

Das *Paradigma* liegt auf der philosophischen Ebene und umfasst Annahmen über die Natur der Wirklichkeit und über Erkenntnis. In der Informatik dominiert ein positivistisches Grundverständnis, nach dem Systeme objektive, messbare Eigenschaften haben; wer aber Programmiererverhalten oder Technologieakzeptanz untersucht, arbeitet oft interpretativ oder pragmatisch @haindl2027research. Die *Methodologie* ist die Strategie: Fallstudie, Experiment oder Design Science liefern die Logik, die Forschungsfrage, Datenerhebung und Analyse verbindet. *Methoden* sind die taktischen Werkzeuge der Erhebung und Auswertung, etwa Surveys, Interviews, Systemlogs oder Benchmarks; eine Methodologie verwendet typischerweise mehrere Methoden. *Instrumente* schließlich übersetzen Methoden in konkrete Werkzeuge wie Interviewleitfäden, Fragebögen oder Benchmark-Suites, die selbst entworfen und validiert werden müssen @haindl2027research.

Der praktische Nutzen der Hierarchie liegt in den Fehlern, die sie verhindert. Wer von einer "qualitativen Methodologie" spricht, vermischt einen Zugang (qualitativ) mit einer Methodologie (etwa Ethnografie); wer "Survey-Methodologie" sagt, verwechselt eine Methode mit einer Methodologie, denn Surveys lassen sich in ganz unterschiedlichen methodologischen Rahmen einsetzen @haindl2027research.

#merke[Für LLM-gestützte Forschung ist die Hierarchie mehr als Terminologie. Ein LLM kann auf jeder Ebene unterhalb des Paradigmas auftauchen: als Bestandteil einer Methode (automatische Codierung), als Instrument (ein Prompt, der Labels erzeugt) oder als Untersuchungsgegenstand. Die Frage "Welche Rolle spielt das LLM in meiner Studie?" ist deshalb immer auch die Frage, auf welcher Ebene es angesiedelt ist und welche Validierungspflichten daraus folgen.]

Neben der Hierarchie unterscheidet das Lehrbuch *Theorien*, *Modelle* und *Frameworks*. Theorien erklären Phänomene durch Beziehungen zwischen Konzepten und erzeugen prüfbare Aussagen; das Technology Acceptance Model etwa postuliert, dass wahrgenommene Nützlichkeit und Benutzerfreundlichkeit die Adoption bestimmen. Modelle repräsentieren Phänomene vereinfacht, oft formal oder grafisch, etwa als Warteschlangenmodell. Frameworks benennen relevante Faktoren und grenzen eine Untersuchung ein, ohne die genauen Zusammenhänge festzulegen @haindl2027research. Eine Masterarbeit verwendet meist alle drei: eine Theorie zur Erklärung, ein konzeptionelles Framework zur Abgrenzung und gegebenenfalls Modelle zur Darstellung der Befunde.

=== Empirische und nicht-empirische Forschung

Empirische Forschung gründet Wissensansprüche auf systematische Beobachtung oder Experimente, etwa auf Performance-Messungen, beobachtetes Nutzerverhalten, Repository-Mining oder Netzwerkmitschnitte @haindl2027research. Innerhalb der empirischen Forschung unterscheidet das Lehrbuch drei Typen mit unterschiedlicher Aussagekraft. *Deskriptive* Forschung dokumentiert Phänomene, wie sie sind, und liefert die Grundlage, auf der Theoriebildung und Interventionen aufbauen. *Korrelative* Forschung untersucht Zusammenhänge zwischen Variablen ohne Manipulation, etwa zwischen Komplexitätsmetriken und Fehlerraten; der Schritt von der Korrelation zur Kausalität wird dabei oft unzulässig getan. *Experimentelle* Forschung stellt Kausalität durch kontrollierte Manipulation her, etwa durch A/B-Tests @haindl2027research.

Nicht-empirische Beiträge sind keineswegs zweitrangig. Theoretische Informatik arbeitet mit Beweisen statt Beobachtungen, konzeptionelle Forschung entwickelt Taxonomien und Entwurfsprinzipien, systematische Literaturreviews, Mapping-Studien und Metaanalysen synthetisieren vorhandene Evidenz, und methodologische Forschung verbessert die Forschung selbst, etwa durch neue Evaluationsmetriken @haindl2027research. Ein Großteil dessen, was in diesem Buch über LLM-as-a-Judge oder Bias-Metriken zu sagen ist, gehört in diese letzte Kategorie.

=== Paradigmen: was man glaubt, entscheidet, was man prüft

Ein Paradigma bündelt Annahmen über die Wirklichkeit (Ontologie), über Wissen (Epistemologie) und über angemessene Verfahren (Methodologie). Creswell und Creswell fassen die Wahl eines Forschungszugangs als Kombination aus philosophischer Weltsicht, Design und konkreten Methoden @creswell2022research. Für dieses Buch genügen vier Positionen, deren Unterschiede in @k01-tab-paradigmen zusammengefasst sind.

Der *Postpositivismus* nimmt eine Wirklichkeit an, die sich durch Messung, Falsifikation und Kontrolle konkurrierender Erklärungen annähern lässt. Sein Qualitätsvokabular sind Validität und Reliabilität, wie sie Shadish, Cook und Campbell für kausale Studien systematisiert haben @shadish2002experimental. Der *Konstruktivismus* oder *Interpretivismus*, bei Lincoln und Guba als "naturalistische" Forschung bezeichnet, stellt diesem "rationalistischen" Paradigma eine andere Sicht auf Wirklichkeit, auf das Verhältnis von Subjekt und Objekt, auf Generalisierung, Kausalität und die Rolle von Werten gegenüber und ersetzt Validität und Reliabilität durch Kriterien der Vertrauenswürdigkeit @lincoln1985naturalistic. Der *Pragmatismus* ist das Paradigma, auf das sich Mixed-Methods-Forschung am häufigsten beruft: Nicht eine metaphysische Festlegung, sondern die Forschungsfrage bestimmt die Kombination der Methoden @creswell2022research @venkatesh2013bridging. Der *kritische Realismus* schließlich vertritt eine geschichtete Ontologie: Es gibt eine Wirklichkeit unabhängig von unserem Wissen, aber unser Wissen darüber ist fehlbar und theoriegeladen. Die vierte Auflage von Creswell und Plano Clark nimmt ihn neu als Grundlage für Mixed Methods auf @creswell2025designing.

#figure(
  table(columns: (auto, 1fr, 1fr, 1fr),
    [Paradigma], [Annahme über Wirklichkeit und Wissen], [Typische Designs], [Qualitätsvokabular],
    [Postpositivismus], [Wirklichkeit existiert und ist durch Messung und Falsifikation annäherbar @shadish2002experimental], [Experiment, Quasi-Experiment, Survey, Benchmark], [Statistische Schluss-, interne, Konstrukt- und externe Validität; Reliabilität],
    [Konstruktivismus], [Bedeutung entsteht in Interaktion; Forschende sind Teil des Erkenntnisprozesses @lincoln1985naturalistic], [Fallstudie, Ethnografie, reflexive Thematische Analyse, Grounded Theory], [Glaubwürdigkeit, Übertragbarkeit, Verlässlichkeit, Bestätigbarkeit],
    [Pragmatismus], [Die Forschungsfrage entscheidet, nicht die Metaphysik @creswell2022research], [Mixed Methods, Design Science], [Inferenzqualität der Metainferenzen @venkatesh2013bridging],
    [Kritischer Realismus], [Reale Welt, aber fehlbares, theoriegeladenes Wissen @creswell2025designing], [Mixed Methods, erklärende Fallstudien], [Erklärungskraft für Mechanismen; Inferenzqualität],
  ),
  caption: [Vier Forschungsparadigmen und ihre Konsequenzen für Design und Gütekriterien.],
) <k01-tab-paradigmen>

Paradigmen sind kein Einleitungsschmuck, sie steuern Analyseentscheidungen. Das deutlichste Beispiel liefert die Thematische Analyse. Braun und Clarke ordnen ihre Varianten Paradigmen zu: Die codierreliabilitätsorientierte TA ist "neopositivistisch", die Codebuch-TA bewegt sich in einem qualitativen Paradigma mit pragmatischen Kompromissen, und die reflexive TA will "fully embrace qualitative research values" @braun2021one[Problem 1]. Daraus folgt direkt, ob eine Kennzahl wie Cohens Kappa zwischen zwei Codierenden ein Qualitätsbeweis oder ein Kategorienfehler ist. Kapitel 5 kommt darauf zurück, wenn ein LLM einer dieser Codierenden ist.

#hoersaal-fest([Ist ein Kaggle-Benchmark nicht einfach "objektiv"? Wozu brauche ich da ein Paradigma?], [Ein Benchmark-Vergleich ist implizit postpositivistisch: Er unterstellt, dass "Leistung" eine messbare Eigenschaft des Modells ist und dass der Testdatensatz sie repräsentiert. Genau diese Annahmen sind prüfbar und oft angreifbar, etwa wenn Benchmarkgenauigkeit als "Reasoning-Fähigkeit" ausgegeben wird, was eine Frage der Konstruktvalidität ist (@k01-guete). Was der Benchmark ausblendet, ist alles, was erst durch Interpretation sichtbar wird: wie Nutzende Fehler erleben, welche Fehler in der Praxis zählen, welche Gruppen systematisch schlechter bedient werden. Das Paradigma zu benennen heißt, diese blinden Flecken offenzulegen, nicht, die Messung abzuwerten @creswell2022research @lincoln1985naturalistic.])

#fallstrick[Paradigmeninkonsistenz ist einer der häufigsten Fehler in Abschlussarbeiten: Die Einleitung bekennt sich zu einem interpretativen Zugang, die Auswertung zählt dann Codehäufigkeiten und berichtet Kappa-Werte als Qualitätsnachweis. Benenne das Paradigma explizit und prüfe, ob jedes Gütekriterium, das du später berichtest, zu ihm passt @braun2021one @levitt2018journal.]

== Forschungsdesigns und ihre Wahl <k01-designs>

=== Drei Zugänge und vier Forschungszwecke

Forschungszugänge lassen sich grob in quantitative, qualitative und gemischte einteilen @haindl2027research. *Quantitative Zugänge* betonen objektive Messung und statistische Analyse numerischer Daten, wurzeln überwiegend im (Post-)Positivismus, wollen Theorien testen, Zusammenhänge zwischen Variablen etablieren und auf Populationen generalisieren; die Forschenden halten Distanz zu den Teilnehmenden und arbeiten mit standardisierten Instrumenten. *Qualitative Zugänge* zielen auf Verstehen und Interpretation nicht-numerischer Daten wie Texte, Bilder und Beobachtungen; die Forschenden sind selbst das primäre Instrument, und Subjektivität wird anerkannt statt eliminiert. *Mixed-Methods-Zugänge* integrieren beide absichtsvoll innerhalb einer Studie oder eines Forschungsprogramms, meist auf pragmatischer Grundlage @haindl2027research.

Quer dazu liegen die Zwecke empirischer Forschung. Runeson und Höst unterscheiden für die Softwaretechnik vier: *explorativ* (herausfinden, was passiert, neue Einsichten und Hypothesen gewinnen), *deskriptiv* (eine Situation oder ein Phänomen beschreiben), *erklärend* (eine Erklärung für eine Situation oder ein Problem suchen, oft kausal) und *verbessernd* (einen Aspekt des untersuchten Phänomens verbessern, ähnlich der Aktionsforschung) @runeson2009guidelines[Abschn. 2.2]. Diese Einteilung ist nützlich, weil sie die häufig gestellte Frage "Welche Methode soll ich nehmen?" in die bessere Frage "Was will ich mit meiner Forschungsfrage eigentlich erreichen?" verwandelt.

=== Die wichtigsten Designs im Überblick

#definition(titel: [Experiment und Quasi-Experiment])[
  Ein *Experiment* liegt vor, wenn die Forschenden eine Behandlung (_treatment_) manipulieren und Untersuchungseinheiten zufällig den Bedingungen zuweisen; das randomisierte Experiment ist das Referenzdesign für kausale Inferenz @shadish2002experimental. Fehlt die Zufallszuweisung aus ethischen oder praktischen Gründen, spricht man von einem *Quasi-Experiment*; alternative Erklärungen sind dann schwerer auszuschließen @shadish2002experimental.
]

Das Lehrbuch begründet die Sonderstellung des Experiments mit drei Bedingungen für Kausalität: *Kovariation* (Ursache und Wirkung variieren gemeinsam), *zeitliche Priorität* (die Ursache geht der Wirkung voraus) und *Ausschluss alternativer Erklärungen* durch Kontrolle und Randomisierung @haindl2027research. Randomisierung sorgt dafür, dass die Gruppen vor der Behandlung probabilistisch äquivalent sind, sodass beobachtete Unterschiede der Behandlung zugeschrieben werden können. In der Informatik stößt das schnell an Grenzen: Man kann Unternehmen nicht zufällig Entwicklungsmethoden zuweisen. Quasi-Experimente stärken die kausale Schlussfolgerung dann durch *Matching* (Teams nach Größe, Erfahrung und Projektkomplexität paaren), *Vorher-nachher-Messungen* und *statistische Kontrolle*; *natürliche Experimente* nutzen externe Ereignisse, die einer Zufallszuweisung nahekommen @haindl2027research. Shadish, Cook und Campbell ordnen Quasi-Experimente in Designs ohne Kontrollgruppe oder Vortest, Designs mit Kontrollgruppe und Vortest, unterbrochene Zeitreihen und Regressions-Diskontinuitäts-Designs @shadish2002experimental.

Innerhalb von Experimenten unterscheidet man *Between-Subjects-Designs* (verschiedene Teilnehmende pro Bedingung), *Within-Subjects-Designs* (dieselben Teilnehmenden durchlaufen alle Bedingungen, was individuelle Unterschiede kontrolliert, aber Reihenfolgeeffekte erzeugt, die durch Ausbalancieren getrennt werden), *faktorielle Designs* mit mehreren unabhängigen Variablen und ihren Wechselwirkungen sowie das Solomon-Vier-Gruppen-Design, das Testeffekte von Behandlungseffekten trennt @haindl2027research. Für LLM-Evaluationen ist die Unterscheidung zwischen Between und Within besonders wichtig: Werden zwei Modelle auf denselben Testitems bewertet, ist das ein gepaartes Design, und das hat Folgen für die Wahl der Effektstärke (@k01-effekt).

#definition(titel: [Fallstudie (Softwaretechnik)])[
  Eine *Fallstudie* ist eine empirische Methode zur Untersuchung eines zeitgenössischen Phänomens in seinem Kontext, die sich auf mehrere Evidenzquellen stützt, ein flexibles Design hat und keine strikte Kontrolle über das Setting ausübt @runeson2009guidelines[Abschn. 2.1].
]

Runeson und Höst beschreiben den Fallstudienprozess als iterative Folge aus Design, Vorbereitung der Datenerhebung, Sammeln der Evidenz, Analyse und Bericht @runeson2009guidelines[Abschn. 2.4]. Sie unterscheiden drei Grade der Datenerhebung: ersten Grades (direkt, etwa Interviews), zweiten Grades (indirekt, etwa Tool-Monitoring) und dritten Grades (Archivanalyse von Arbeitsartefakten) @runeson2009guidelines[Abschn. 4.1]. Diese Grade passen erstaunlich gut auf Studien über ML-Systeme in Organisationen: Interviews mit Data Scientists, Telemetrie und Logs, Mining von Repositories und Modell-Hubs.

#definition(titel: [Survey])[
  Ein *Survey* ist die systematische Erhebung standardisierter Selbstauskünfte einer Stichprobe, um eine Population zu beschreiben oder zu erklären. Wohlin et al. haben in der zweiten Auflage ihres Standardwerks ein eigenes Kapitel zur Survey-Forschung ergänzt @wohlin2024experimentation.
]

Hinzu kommen in der Informatik Design Science (Kapitel 2) und Aktionsforschung, die Forschung und Praxisverbesserung verbindet @haindl2027research, sowie die qualitativen Methodologien Ethnografie, Phänomenologie und Grounded Theory (@k01-qual). Mixed Methods werden in @k01-mixed behandelt.

=== Ein Entscheidungsrahmen für die Designwahl

Das Lehrbuch stellt einen Entscheidungsrahmen bereit, der von der Art der Forschungsfrage ausgeht @haindl2027research (@k01-fig-designwahl). Fragen nach Kausalität ("Verursacht X Y?") verlangen experimentelle oder quasi-experimentelle Designs. Fragen nach Verstehen ("Wie erleben Entwickelnde X?") verlangen qualitative Zugänge wie Fallstudie oder Ethnografie. Fragen nach Verbreitung ("Wie häufig ist X?") legen Surveys nahe, und Fragen nach Entwicklung ("Wie können wir X lösen?") führen zu Design Science oder Aktionsforschung @haindl2027research.

#figure(
  diagram(spacing: (9mm, 9mm), edge-stroke: 0.8pt, mark-scale: 70%, label-size: 7pt,
    fknoten((1.5, 0), [Forschungsfrage], col: c-dark, filled: true, w: 30mm),
    fknoten((1.5, 1), [Kausalbeziehung nachweisen?], col: c-yellow, w: 36mm),
    fknoten((0.5, 2), [Zufallszuweisung möglich?], col: c-yellow, w: 34mm),
    fknoten((2.5, 2), [Breite Generalisierung nötig?], col: c-yellow, w: 36mm),
    fknoten((0, 3), [Experiment], col: c-blue, filled: true, w: 24mm),
    fknoten((1, 3), [Quasi-Experiment], col: c-blue, w: 28mm),
    fknoten((2, 3), [Survey], col: c-teal, filled: true, w: 22mm),
    fknoten((3, 3), [Tiefes Kontextverständnis nötig?], col: c-yellow, w: 36mm),
    fknoten((2.5, 4), [Fallstudie], col: c-violet, filled: true, w: 24mm),
    fknoten((3.5, 4), [Design Science], col: c-accent, filled: true, w: 28mm),
    edge((1.5, 0), (1.5, 1), "-|>"),
    edge((1.5, 1), (0.5, 2), "-|>", [ja], label-side: right, label-pos: 0.45),
    edge((1.5, 1), (2.5, 2), "-|>", [nein], label-side: left, label-pos: 0.45),
    edge((0.5, 2), (0, 3), "-|>", [ja], label-side: right, label-pos: 0.45),
    edge((0.5, 2), (1, 3), "-|>", [nein], label-side: left, label-pos: 0.45),
    edge((2.5, 2), (2, 3), "-|>", [ja], label-side: right, label-pos: 0.45),
    edge((2.5, 2), (3, 3), "-|>", [nein], label-side: left, label-pos: 0.45),
    edge((3, 3), (2.5, 4), "-|>", [ja], label-side: right, label-pos: 0.45),
    edge((3, 3), (3.5, 4), "-|>", [nein], label-side: left, label-pos: 0.45),
  ),
  caption: [Entscheidungsrahmen für die Designwahl, übertragen aus @haindl2027research. Zusätzlich zu prüfen: Aktionsforschung (Verbesserung in der eigenen Organisation), Mixed Methods (Frage braucht Breite und Tiefe), Ethnografie und Grounded Theory (neues Phänomen ohne tragfähige Theorie).],
) <k01-fig-designwahl>

Neben der Frage zählen drei weitere Faktoren @haindl2027research. Die *paradigmatische Passung* sichert philosophische Kohärenz: Positivistische Paradigmen passen zu Experimenten und Surveys, konstruktivistische zu Fallstudien und Ethnografie, transformative zur Aktionsforschung, pragmatische zu Mixed Methods und Design Science; ein Paradigma diktiert die Methode nicht, aber die Passung verhindert philosophische Inkohärenz. *Praktische Restriktionen* wie Zeit, Feldzugang, Ressourcen und Kompetenzen begrenzen den machbaren Raum; Ethnografie oder Längsschnittdesigns sind in einer Masterarbeit kaum realisierbar. Und die *Erwartungen des Publikums* beeinflussen, wie eine Arbeit aufgenommen wird: Systems-Konferenzen erwarten Performance-Evaluationen, CHI schätzt Nutzerstudien.

Das Lehrbuch ergänzt diesen Rahmen um eine Umkehrung, die in der Praxis oft wichtiger ist: Statt eine Methode zu wählen und auf Qualität zu hoffen, soll man fragen, welche Gütekriterien das Projekt tatsächlich erfüllen kann, und daraus die Methode ableiten. Eine kleine, ehrlich abgegrenzte Interviewstudie ist mehr wert als ein unterpowertes Experiment, dessen unerfüllte Kriterien stillschweigend übergangen werden @haindl2027research. Wir kommen darauf in @k01-guete zurück.

#beispiel(titel: [Designwahl für eine LLM-Studie])[
  Eine Masterarbeit will wissen, ob ein LLM-gestütztes Screening-Werkzeug die Arbeit in systematischen Literaturreviews verbessert. Drei Teilfragen führen zu drei Designs. "Erreicht das Werkzeug auf einem gelabelten Korpus einen höheren Recall als die Stichwortsuche?" ist eine kausale Frage mit manipulierbarer Bedingung und zufälliger Zuweisung von Abstracts; das ist ein Experiment, genauer ein gepaartes Design, weil beide Verfahren dieselben Abstracts bearbeiten. "Wie verbreitet ist der Einsatz solcher Werkzeuge in Review-Teams?" ist eine Prävalenzfrage, also ein Survey. "Warum vertrauen Reviewer den Vorschlägen des Werkzeugs oder nicht?" ist eine Verstehensfrage, also Interviews mit Thematischer Analyse. Zusammengenommen ergibt das ein Mixed-Methods-Design, dessen Integration in @k01-mixed ausgearbeitet wird.
]

#tipp[Formuliere vor jeder Designentscheidung die Forschungsfrage so, dass ihr Zweck (explorativ, deskriptiv, erklärend, verbessernd) aus dem Fragewort ablesbar ist: "Wie erleben ...", "Wie häufig ...", "Verursacht ...", "Wie kann ... verbessert werden". Unscharfe Fragen wie "Untersuchung des Einsatzes von LLMs in ..." legen kein Design fest und führen zu Methodenwahl nach Gewohnheit.]

== Qualitative Forschung <k01-qual>

Qualitative Forschung will Phänomene aus der Perspektive der Beteiligten verstehen, Bedeutungen und Prozesse erkunden und reichhaltige Beschreibungen oder Theorien entwickeln @haindl2027research. Ihr Datenmaterial sind Texte, Bilder und Beobachtungen; ihre Stärke ist die Tiefe, ihre klassische Schwäche aus quantitativer Sicht die fehlende statistische Generalisierbarkeit. Diese Kritik geht aber am Ziel vorbei, denn qualitative Studien generalisieren analytisch, nicht statistisch: Sie entwickeln theoretische Aussagen, deren Anwendbarkeit Lesende in ihrem eigenen Kontext prüfen können @haindl2027research @runeson2009guidelines[Abschn. 5.2.3].

=== Interviews als Erhebungsmethode

Das Interview ist die häufigste qualitative Erhebungsmethode in der Informatik. Das Lehrbuch beschreibt die Vorbereitung in mehreren Schritten: Einschlusskriterien präzise definieren, zweckgerichtet (_purposive_) auf Vielfalt hin rekrutieren, für sich herausbildende Themen theoretisches Sampling vorsehen und 20 bis 30 % zusätzliche Teilnehmende für Ausfälle einplanen @haindl2027research. Der Leitfaden schreitet von Einstiegsfragen, die Vertrauen aufbauen, über Übergangs- und Schlüsselfragen zu vertiefenden Nachfragen (_probes_) und Abschlussfragen fort. Fortgeschrittene Techniken sind das *Laddering*, das durch wiederholtes Nachfragen nach dem "Warum" zugrunde liegende Werte freilegt, die *Critical-Incident-Technik*, die nach einem konkreten Vorfall und dem damaligen Denken fragt, und die *Foto-Elizitation*, die mit Screenshots oder Architekturdiagrammen Erinnerungen anstößt; im Gespräch helfen stilles Nachfragen (eine strategische Pause), Echo- und Zusammenfassungsfragen @haindl2027research.

#praxis[Ein Interviewleitfaden ist ein Instrument im Sinn von @k01-fig-hierarchie und verdient dieselbe Sorgfalt wie ein Fragebogen: ein Pilotinterview, eine Überarbeitung, eine dokumentierte Versionierung. Wer später ein LLM Transkripte zusammenfassen oder vorcodieren lässt, muss zusätzlich den Prompt als zweites Instrument behandeln und versionieren (Kapitel 3 und 10).]

=== Grounded Theory

Grounded Theory (GT) baut, anders als theorietestende Forschung, neue Theorien aus empirischen Daten auf und eignet sich deshalb für Phänomene, für die vorhandene Theorien nicht ausreichen @haindl2027research. Das Verfahren beginnt mit *theoretischer Sensibilität*, also der Fähigkeit, theoretisch relevante Daten zu erkennen, ohne sich vorschnell festzulegen. *Theoretisches Sampling* wählt Teilnehmende nicht nach Repräsentativität, sondern danach, was die entstehenden Konzepte weiterentwickelt. Analytisch folgt auf *offenes Codieren*, das die Daten Zeile für Zeile in Konzepte zerlegt, das *axiale Codieren*, das Kategorien mit Subkategorien in Beziehung setzt, und das *selektive Codieren*, das alles um eine Kernkategorie integriert. Begleitend halten *Memos* analytische Gedanken fest, deren Sortierung die Struktur der Theorie zeigt; *theoretische Sättigung* ist erreicht, wenn neue Daten keine neuen theoretischen Einsichten mehr liefern, was nicht dasselbe ist wie bloße Wiederholung @haindl2027research.

#definition(titel: [Grounded Theory nach Stol, Ralph und Fitzgerald])[
  Grounded Theory ist eine Familie von Methoden (klassisch nach Glaser, Strauss'sche Variante, konstruktivistisch nach Charmaz), deren Kernpraktiken gleichzeitige Datenerhebung und -analyse, theoretisches Sampling, Codieren, Memoing, ständiger Vergleich und theoretische Sättigung sind, mit dem Ziel einer kohärenten Theorie @stol2016grounded[Abschn. 2]. Einzelne GT-Techniken ohne diese Praktiken zu verwenden, ist keine GT (_method slurring_) @stol2016grounded[Abschn. 5.1].
]

#studie-fest(titel: [Stol, Ralph und Fitzgerald 2016])[
  *Design:* kritisches Review von 98 Zeitschriftenartikeln der Softwaretechnik, die GT erwähnen, aus 1763 Kandidaten in neun Zeitschriften @stol2016grounded[Abschn. 3]. *Befund:* Nur 52 Artikel (53 %) beanspruchten explizit GT, 46 (47 %) entlehnten lediglich Techniken. Von den 52 lieferten 18 (35 %) keine methodischen Details, 4 (8 %) wichen so weit ab, dass es keine GT mehr war. Unter den 30 detaillierten Arbeiten berichteten 97 % Codieren, aber nur 50 % theoretische Sättigung, 43 % ständigen Vergleich, 40 % theoretisches Sampling, 40 % Memoing und 13 % Memo-Sortierung. 39 von 52 Arbeiten (75 %) nannten keine GT-Variante, keine einzige beanspruchte konstruktivistische GT, und nur 5 (10 %) legten eine epistemologische Position offen @stol2016grounded. *Grenzen:* nur Zeitschriftenartikel, keine Konferenzbeiträge @stol2016grounded[Abschn. 3]. *Bedeutung:* Die Liste der Kernpraktiken ist eine fertige Checkliste für jede Arbeit, die "Grounded Theory" im Methodenteil stehen hat.
]

=== Fallstudie, Phänomenologie und Ethnografie

Die *Fallstudie* untersucht zeitgenössische Phänomene in der Tiefe und in ihrem realen Kontext, besonders wenn die Grenze zwischen Phänomen und Kontext unscharf ist; die Untersuchungseinheit ist der Fall, klar begrenzt in Raum und Zeit @haindl2027research. Das Lehrbuch reserviert den Begriff ausdrücklich für das Forschungsdesign und grenzt ihn von der Marketing-"Case Study" und von illustrativen Lehrvignetten ab @haindl2027research. Fallstudien sind stark, wenn "Wie"- oder "Warum"-Fragen zu Ereignissen gestellt werden, über die die Forschenden wenig Kontrolle haben, und wenn das Phänomen ohne seinen Kontext nicht zu verstehen ist, etwa die Einführung von Continuous Deployment in einer Organisation mit ihrer Kultur, Infrastruktur und ihren Geschäftszwängen @haindl2027research.

*Einzelfalldesigns* erlauben große Tiefe und sind gerechtfertigt, wenn der Fall einen kritischen Test einer Theorie darstellt, eine extreme oder einzigartige Situation ist, einen sonst verschlossenen Zugang eröffnet (revelatorischer Fall) oder über lange Zeit begleitet wird @haindl2027research. *Mehrfallstudien* folgen einer Replikationslogik: *Wörtliche Replikation* wählt ähnliche Fälle, um zu zeigen, dass Befunde über Instanzen hinweg halten; *theoretische Replikation* wählt kontrastierende Fälle, um Randbedingungen auszuloten; *Maximum-Variation-Sampling* sucht gezielt Vielfalt. Die Auswahl folgt theoretischer, nicht statistischer Logik: Fälle werden danach gewählt, was sie lehren können, nicht danach, was sie repräsentieren @haindl2027research. Analysiert wird zuerst innerhalb jedes Falls (detaillierte Beschreibungen, Chronologien, Muster), dann fallübergreifend (Vergleichsmatrizen, Typologien, Kausalketten, notwendige und hinreichende Bedingungen); das Ziel ist analytische Generalisierung @haindl2027research.

Für die Fallstudie in der Softwaretechnik bieten Runeson und Höst eine Checkliste mit 50 Punkten: 38 für Forschende, nach Prozessschritten gegliedert, und 12 für Lesende @runeson2009guidelines. Sie ist eine brauchbare Selbstprüfung für jede Masterarbeit, die eine Fallstudie über den Einsatz eines ML-Systems in einer Organisation durchführt.

Zwei weitere qualitative Methodologien ergänzen das Spektrum. Die *Phänomenologie* will die wesentliche Struktur gelebter Erfahrung verstehen, etwa Frustration beim Debuggen oder den Flow-Zustand beim Programmieren. Sie beginnt mit der _Epoché_, dem Einklammern eigener Annahmen, arbeitet mit phänomenologischer Reduktion (wiederholtes Lesen, um Schicht für Schicht zum Wesentlichen vorzudringen) und mit imaginativer Variation (Gedankenexperimente, ob das Phänomen ohne ein bestimmtes Element noch erkennbar wäre) und mündet in eine Beschreibung der invarianten Struktur. Die Stichproben sind wegen der nötigen Tiefe klein, typischerweise 3 bis 15 Teilnehmende @haindl2027research. Die *Ethnografie* untersucht kulturelle Muster durch ausgedehnte Feldarbeit. Ihr Kern ist die teilnehmende Beobachtung, deren Rollen von der vollständigen Teilnahme bis zur reinen Beobachtung reichen; ihre Primärdaten sind Feldnotizen, die Beschreibung, Analyse, Reflexion und methodische Notizen verbinden; ihr Ziel ist kulturelle Interpretation, etwa was "Refactoring" über Werte wie Handwerksstolz und Eigentum an Code ausdrückt @haindl2027research.

#hoersaal-fest([Kann ein LLM eine Ethnografie oder Phänomenologie "unterstützen"?], [Bei Hilfsarbeiten wie der Transkription oder dem Strukturieren von Feldnotizen vielleicht, im Kern nicht. Beide Methodologien beruhen auf der Erfahrung und dem reflektierten Urteil der Forschenden: Die Epoché ist eine Haltung der Forscherin, die teilnehmende Beobachtung setzt Anwesenheit im Feld voraus @haindl2027research. Ein LLM kann diese Haltung nicht einnehmen, und jede maschinell erzeugte "Essenz" wäre eine Behauptung über Erfahrung ohne erfahrendes Subjekt. Das ist dieselbe Argumentationslinie, mit der 419 Forschende GenAI für reflexive Ansätze ablehnen @jowsey2025reject.])

=== Thematische Analyse und ihre drei Familien

#definition(titel: [Thematische Analyse])[
  Die *Thematische Analyse* (TA) ist eine Methode zum Identifizieren, Analysieren und Berichten von Mustern (Themen) in qualitativen Daten, von Braun und Clarke als "an accessible and theoretically flexible approach" eingeführt @braun2006using. In der *reflexiven* TA ist ein Thema ein Muster geteilter Bedeutung, das von einem zentralen organisierenden Konzept zusammengehalten wird; eine bloße *Domänenzusammenfassung*, die um ein Thema im Sinn von "Topic" organisiert ist, aber keine geteilte Bedeutung trägt, gilt als unterentwickeltes Thema @braun2019reflecting.
]

Die sechs Phasen des Aufsatzes von 2006 sind Vertrautmachen mit den Daten, Erzeugen erster Codes, Suchen nach Themen, Überprüfen der Themen, Definieren und Benennen der Themen sowie Verfassen des Berichts @braun2006using. Später haben die Autorinnen eingeräumt, dass der Aufsatz seine Annahmen implizit ließ und dadurch zu konzeptuellen Fehlpassungen in publizierten Studien beitrug; sie nannten ihren Ansatz "reflexive TA" und ersetzten "Suchen nach Themen" durch "Generieren (erster) Themen", weil Themen nicht fertig in den Daten warten @braun2019reflecting. Themen "tauchen" also nicht "auf"; sie werden von Forschenden konstruiert.

Entscheidend für alles, was in Kapitel 5 über LLM-gestütztes Codieren gesagt wird, ist die Einsicht, dass TA keine einzelne Methode, sondern eine Familie ist (@k01-tab-ta).

#figure(
  table(columns: (auto, 1fr, 1fr, 1fr),
    [], [Codierreliabilitäts-TA], [Codebuch-TA], [Reflexive TA],
    [Paradigma], [neopositivistisch], [qualitativ mit pragmatischen Kompromissen], [voll qualitativ ("fully embrace qualitative research values")],
    [Codierung], [Codebuch, mehrere Codierende], [strukturierte Frameworks (Template, Framework-Analyse)], [organisch, iterativ; kein Team und kein Konsens nötig],
    [Inter-Rater-Reliabilität], [zentrales Qualitätsmaß], [meist kein Kriterium], [kein Kriterium; mehrere Codierende zielen auf reichere Lesart],
    [Rolle der Subjektivität], [Fehlerquelle], [teilweise kontrolliert], [Ressource],
    [Sättigung als Stoppregel], [passt], [passt], [passt nicht],
  ),
  caption: [Die drei Familien der Thematischen Analyse nach @braun2021one[Problem 1] und @braun2019reflecting; Zeile "Sättigung" nach @braun2021saturate.],
) <k01-tab-ta>

Braun und Clarke argumentieren, dass Codierreliabilitätsmaße die Kluft zwischen den Paradigmen nicht überbrücken ("bridge the divide"), ohne die Integrität qualitativer Forschung aufzugeben; mehrere Codierende sollen in der reflexiven TA eine reichere Lesart ermöglichen, nicht Übereinstimmung herstellen @braun2019reflecting. In ihrem Qualitätsaufsatz von 2021 bezeichnen sie Reliabilitätsmaße für reflexive TA deshalb als unlogisch und listen zehn typische Probleme publizierter Studien: TA für einen einzigen Ansatz halten; zitieren, ohne zu lesen; unbegründete oder inkompatible "Mash-ups"; TA für atheoretisch halten; TA nur für realistisch, essenzialistisch oder erfahrungsbezogen halten; TA nur für deskriptiv halten; Codes und Themen verwechseln; Themen und Topics verwechseln; "auftauchende" Themen; und die unkritische Übernahme dessen, was die Autorinnen selbst sagen @braun2021one. Dazu liefern sie zwanzig kritische Fragen für Gutachtende, von denen sich die ersten dreizehn auf Methode und Methodologie beziehen @braun2021one[Tab. 1].

#hoersaal-fest([Wenn ich ein LLM als zweiten Codierer neben mir einsetze und Kappa berechne, ist meine reflexive TA dann nicht sogar besser abgesichert als ohne?], [Nein, und zwar aus einem prinzipiellen Grund. In der reflexiven TA ist deine positionierte Subjektivität die analytische Ressource @braun2019reflecting; ein hohes Kappa würde nur zeigen, dass ein Modell deine Lesart reproduzieren kann, nicht dass sie gut ist. Kappa ist ein Qualitätsmaß der Codierreliabilitäts-TA @braun2021one. Wenn du das LLM als Gesprächspartner nutzt, der alternative Lesarten vorschlägt, kann das legitim sein, muss aber offen deklariert werden; 419 qualitative Forschende lehnen selbst das für reflexive Ansätze ab @jowsey2025reject. Wenn du dagegen Codierreliabilität willst, dann wähle bewusst eine Codierreliabilitäts- oder Codebuch-TA und begründe das paradigmatisch. Kapitel 5 behandelt die Maße im Detail.])

=== Stichprobenumfang I: Sättigung

Wie viele Interviews sind genug? Die verbreitetste Antwort beruft sich auf *Sättigung*, üblicherweise definiert als Informationsredundanz: der Punkt, an dem kaum noch neue relevante Codes gefunden werden @hennink2022sample. Hennink, Kaiser und Marconi unterscheiden dabei zwei Arten @hennink2017code.

#definition(titel: [Code-Sättigung und Bedeutungssättigung])[
  *Code-Sättigung* ist erreicht, wenn die Bandbreite der Themen identifiziert ist ("heard it all"). *Bedeutungssättigung* ist erreicht, wenn jeder Code in seinen Dimensionen und Nuancen vollständig verstanden ist ("understand it all") @hennink2017code @hennink2022sample.
]

#studie-fest(titel: [Guest, Bunce und Johnson 2006])[
  *Design:* 60 Tiefeninterviews mit Frauen in zwei westafrikanischen Ländern (je 30 in Ghana und Nigeria) mit strukturiertem Leitfaden; die Codebuchentwicklung wurde Transkript für Transkript in Sechserblöcken protokolliert @guest2006many. *Befund:* In Ghana lagen nach 30 Transkripten 109 Codes vor; 80 davon (73 %) waren nach 6 Interviews, 100 (92 %) nach 12 Interviews vorhanden. Die 30 nigerianischen Interviews fügten nur 5 Codes hinzu, 4 davon nicht substanziell, insgesamt also 114 Codes @guest2006many. Die Diskussion berichtet 88 % nach 12 Interviews, bezogen auf alle 114 Codes @guest2006many. *Grenzen (der Autoren):* homogene Stichprobe, enge Ziele, strukturierter Leitfaden; "twelve interviews will likely not be enough if a selected group is relatively heterogeneous"; Sättigung hängt von den Analysierenden ab @guest2006many. *Bedeutung:* Quelle der viel zitierten Faustregel "12 Interviews", die fast immer ohne diese Vorbehalte zitiert wird @braun2021saturate.
]

#studie-fest(titel: [Hennink und Kaiser 2022])[
  *Design:* systematisches Review über vier Datenbanken mit Zitations- und Referenzsuche; 23 Artikel, davon 17 empirische Sättigungstests und 6 statistische Modelle @hennink2022sample. *Befund:* Interviews erreichten Sättigung insgesamt in 5 bis 24 Interviews, ohne Ausreißer in 9 bis 17 (Mittel 12 bis 13); Fokusgruppen insgesamt in 1 bis 16, ohne Ausreißer in 4 bis 8 (Mittel 5 bis 6). Ausreißer betrafen Metathemen über vier Länder (20 bis 40 Interviews) und Bedeutungssättigung (16 bis 24 Interviews). Statistische Modelle, etwa mit 10, 10 und 13 Interviews bei 95 % Konfidenz, wurden nicht übernommen, weil ihre Annahmen (Zufallsstichprobe, bekannte Prävalenz der Themen) nicht zu qualitativer Forschung passen @hennink2022sample. *Grenzen:* nur englischsprachige Literatur, Grounded Theory ausgeschlossen, überwiegend Gesundheitsforschung mit homogenen Stichproben @hennink2022sample. Für die Interviewanalyse gingen genau genommen 16 Tests ein, weil eine Studie ausgeschlossen wurde.
]

In einer Einzelstudie fanden Hennink, Kaiser und Marconi bei 25 Tiefeninterviews Code-Sättigung nach 9 Interviews, Bedeutungssättigung aber erst nach 16 bis 24 @hennink2017code. Eine Angabe "Sättigung nach $n$ Interviews" ist deshalb ohne Angabe der Sättigungsart wertlos.

#block(above: 1.1em, below: 0.55em, sticky: true, text(size: 9.6pt, weight: "bold", style: "italic", fill: c-dark)[Ein einfaches Modell der Sättigungskurve])

Eine Sättigungskurve trägt die kumulierte Zahl verschiedener Codes gegen die Zahl analysierter Interviews ab. Buckley argumentiert, dass eine prozentuale Sättigungsangabe nur sinnvoll ist, wenn sich diese Kurve durch eine negative Exponentialfunktion beschreiben lässt, und empfiehlt, die Fallzahl bis zur Sättigung pro Ebene des Codebaums zu berichten @buckley2022ten. Die funktionale Form folgt Buckley; die folgende Parametrisierung und Herleitung sind eine eigene Ausarbeitung.

#definition(titel: [Exponentielles Sättigungsmodell])[
  Sei $C(n)$ die kumulierte Zahl verschiedener Codes nach $n$ Interviews, $C_max$ die asymptotische Gesamtzahl der Codes und $lambda > 0$ die Entdeckungsrate. Das Modell lautet
  $ C(n) = C_max (1 - e^(-lambda n)). $ <k01-eq-saett>
  Der Sättigungsgrad nach $n$ Interviews ist $C(n) slash C_max = 1 - e^(-lambda n)$.
]

#satz(titel: [Interviewzahl bis zum Sättigungsgrad $s$])[
  Im Modell @k01-eq-saett wird der Sättigungsgrad $s in (0, 1)$ genau bei
  $ n_s = - ln(1 - s) / lambda $ <k01-eq-ns>
  Interviews erreicht. Werden zwei Kurvenpunkte $C(m) = a$ und $C(2m) = b$ beobachtet, so gilt $e^(-lambda m) = b slash a - 1$, also $lambda = - ln(b slash a - 1) slash m$ und $C_max = a slash (2 - b slash a)$.
]

#beweis-fest[
  Aus $1 - e^(-lambda n_s) = s$ folgt $e^(-lambda n_s) = 1 - s$ und durch Logarithmieren $-lambda n_s = ln(1 - s)$, also @k01-eq-ns. Für die Zweipunktschätzung setze $q = e^(-lambda m)$. Dann ist $a = C_max (1 - q)$ und $b = C_max (1 - q^2) = C_max (1 - q)(1 + q)$. Division ergibt $b slash a = 1 + q$, also $q = b slash a - 1$, und damit $lambda = -ln(q) slash m$. Einsetzen in die erste Gleichung liefert $C_max = a slash (1 - q) = a slash (2 - b slash a)$.
]

#beispiel(titel: [Sättigungskurve aus den Ghana-Daten von Guest et al.])[
  Nach $m = 6$ Interviews lagen $a = 80$, nach $2m = 12$ Interviews $b = 100$ Codes vor @guest2006many. Dann ist $q = 100 slash 80 - 1 = 0.25$, also $lambda = ln(4) slash 6 approx 0.231$ und $C_max = 80 slash 0.75 approx 106.7$. Nach @k01-eq-ns werden 90 % Sättigung bei $n_(0.9) = ln(10) slash 0.231 approx 10.0$ Interviews erreicht, 95 % bei $n_(0.95) = ln(20) slash 0.231 approx 13.0$. Das Modell sagt allerdings eine Asymptote von etwa 107 Codes voraus, während nach 30 Interviews tatsächlich 109 vorlagen @guest2006many: Die späten Codes kommen langsamer, als ein einziger Exponentialterm erlaubt. Genau deshalb verlangt Buckley, die Kurvenanpassung zu prüfen, bevor man Prozentwerte berichtet, und die Reihenfolge der Fälle zu permutieren, weil Studien, die mit den reichhaltigsten Fällen beginnen, früher Sättigung erreichen @buckley2022ten.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let sx = 0.36
    let sy = 0.042
    let lam = calc.ln(4) / 6
    let cmax = 80 / 0.75
    // Achsen
    line((0, 0), (30 * sx + 0.3, 0), stroke: 0.7pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.5))
    line((0, 0), (0, 120 * sy + 0.3), stroke: 0.7pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.5))
    for x in (0, 6, 12, 18, 24, 30) {
      line((x * sx, 0), (x * sx, -0.08), stroke: 0.5pt + c-dark)
      content((x * sx, -0.3), text(font: "Inter", size: 7pt, str(x)))
    }
    for y in (0, 20, 40, 60, 80, 100, 120) {
      line((0, y * sy), (-0.08, y * sy), stroke: 0.5pt + c-dark)
      content((-0.35, y * sy), text(font: "Inter", size: 7pt, str(y)))
      if y > 0 { line((0, y * sy), (30 * sx, y * sy), stroke: 0.3pt + luma(225)) }
    }
    content((15 * sx, -0.75), text(font: "Inter", size: 7.5pt, [Anzahl analysierter Interviews $n$]))
    content((-1.0, 60 * sy), angle: 90deg, text(font: "Inter", size: 7.5pt, [kumulierte Codes $C(n)$]))
    // Asymptote und 90-%-Linie
    line((0, cmax * sy), (30 * sx, cmax * sy), stroke: (paint: c-grey, dash: "dashed", thickness: 0.7pt))
    content((1.0 * sx, cmax * sy + 0.2), anchor: "west", text(font: "Inter", size: 6.8pt, fill: c-grey.darken(20%), [$C_max approx 106.7$]))
    let n90 = calc.ln(10) / lam
    line((0, 0.9 * cmax * sy), (n90 * sx, 0.9 * cmax * sy), stroke: (paint: c-accent, dash: "dotted", thickness: 0.8pt))
    line((n90 * sx, 0), (n90 * sx, 0.9 * cmax * sy), stroke: (paint: c-accent, dash: "dotted", thickness: 0.8pt))
    content((n90 * sx + 0.1, 0.62), anchor: "west", text(font: "Inter", size: 6.8pt, fill: c-accent.darken(10%), [$n_(0.9) approx 10$]))
    // Kurve
    let pts = range(0, 121).map(i => { let n = i / 4; (n * sx, cmax * (1 - calc.exp(-lam * n)) * sy) })
    line(..pts, stroke: 1.2pt + c-blue)
    // Datenpunkte Guest et al.
    for (n, c) in ((6, 80), (12, 100), (30, 109)) {
      circle((n * sx, c * sy), radius: 0.08, fill: c-dark, stroke: none)
    }
    content((6 * sx - 0.15, 80 * sy + 0.18), anchor: "east", text(font: "Inter", size: 6.8pt, [6 Int.: 80 Codes]))
    content((12 * sx + 0.15, 100 * sy - 0.3), anchor: "west", text(font: "Inter", size: 6.8pt, [12 Int.: 100 Codes]))
    content((30 * sx - 0.1, 109 * sy + 0.25), anchor: "east", text(font: "Inter", size: 6.8pt, [30 Int.: 109 Codes]))
    // Bandbreite Hennink und Kaiser
    rect((9 * sx, 0.02), (17 * sx, 0.22), fill: c-teal.lighten(60%), stroke: none)
    content((13 * sx, 0.12), text(font: "Inter", size: 6pt, fill: c-teal.darken(30%), [9 bis 17]))
  }),
  caption: [Exponentielles Sättigungsmodell, angepasst an zwei Punkte der Ghana-Daten von @guest2006many (Punkte: beobachtete Werte). Grüner Balken: Bandbreite empirischer Sättigung ohne Ausreißer nach @hennink2022sample. Die Unterschätzung der späten Codes zeigt die Grenzen eines einparametrigen Modells.],
) <k01-fig-saettigung>

=== Stichprobenumfang II: Information Power und die Kritik an der Sättigung

Gegen die Zahlenlogik der Sättigung gibt es grundsätzliche Einwände. Braun und Clarke halten Sättigung für passend in Codierreliabilitäts- und Codebuch-TA, die Bedeutung als in den Daten liegend behandeln, aber nicht für reflexive TA, in der Bedeutung durch Interpretation erzeugt wird; Stichprobengröße und Abbruchentscheidung seien situiert und nicht vorab fixierbar @braun2021saturate. Als nützlicheres Konzept verweisen sie auf *Information Power*, mit dem Hinweis, dass auch dieses Konzept Kritiker hat @braun2021saturate.

#definition(titel: [Information Power])[
  *Information Power* bezeichnet das Prinzip, dass eine Stichprobe umso weniger Teilnehmende braucht, je mehr studienrelevante Information sie enthält. Sie hängt von fünf Dimensionen ab: Studienziel (eng oder breit), Spezifität der Stichprobe (dicht oder dünn), Nutzung etablierter Theorie (angewandt oder keine), Qualität des Dialogs (stark oder schwach) und Analysestrategie (Einzelfall oder fallübergreifend) @malterud2016sample. Das Modell dient der Planung und der laufenden Bewertung während der Erhebung @malterud2016sample.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let dims = (
      ([Studienziel], [eng], [breit]),
      ([Spezifität der Stichprobe], [dicht], [dünn]),
      ([Etablierte Theorie], [angewandt], [keine]),
      ([Qualität des Dialogs], [stark], [schwach]),
      ([Analysestrategie], [Einzelfall], [fallübergreifend]),
    )
    for (i, (d, lo, hi)) in dims.enumerate() {
      let y = -i * 0.62
      content((3.4, y), anchor: "east", text(font: "Inter", size: 7.5pt, weight: "bold", d))
      content((4.85, y), anchor: "east", text(font: "Inter", size: 7pt, fill: c-teal.darken(20%), lo))
      content((8.55, y), anchor: "west", text(font: "Inter", size: 7pt, fill: c-accent.darken(10%), hi))
      line((5.0, y), (8.4, y), stroke: 0.6pt + luma(190), mark: (start: "stealth", end: "stealth", fill: luma(190), scale: 0.4))
    }
    line((5.0, -3.25), (8.4, -3.25), stroke: (paint: c-dark, thickness: 0.9pt), mark: (start: "stealth", end: "stealth", fill: c-dark, scale: 0.6))
    content((4.85, -3.25), anchor: "east", text(font: "Inter", size: 7pt, fill: c-teal.darken(20%), align(right)[hohe Information Power: \ kleinere Stichprobe]))
    content((8.55, -3.25), anchor: "west", text(font: "Inter", size: 7pt, fill: c-accent.darken(10%), [niedrige Information Power: \ größere Stichprobe]))
  }),
  caption: [Die fünf Dimensionen der Information Power nach @malterud2016sample. Jede Dimension verschiebt den benötigten Stichprobenumfang; das Modell liefert keine Zahl, sondern eine begründbare Richtung.],
) <k01-fig-infopower>

Die Debatte lässt sich in drei Positionen ordnen @hennink2022sample @braun2021saturate @buckley2022ten. *Für Zahlen:* Empirische Sättigungstests konvergieren auf 9 bis 17 Interviews und 4 bis 8 Fokusgruppen für homogene Stichproben und enge Ziele, was die Autorinnen als Orientierung für A-priori-Schätzungen anbieten @hennink2022sample. *Gegen Zahlen:* Für reflexive TA ist der Stichprobenumfang ein situiertes, interpretatives Urteil @braun2021saturate, und selbst Guest et al. warnen, dass 12 Interviews bei heterogenen Gruppen kaum reichen @guest2006many. *Vermittelnd:* Sättigung beibehalten, aber durch zehn Berichtsschritte interpretierbar machen, nämlich disziplinärer Rahmen, Zielklasse, Fallauswahl, Maßnahmen gegen Selektionsverzerrung, Homogenität relativ zum analytischen Fokus, Erhebungsmethode, Sättigungsart, Granularität der Codes, Randomisierung der Fallreihenfolge und Präzision der nachträglichen Tests @buckley2022ten.

#hoersaal-fest([Kann ich nicht einfach das statistische Modell von Rowlands et al. nehmen und sagen "13 Interviews bei 95 % Konfidenz"?], [Formal kannst du, inhaltlich wird es schwer zu verteidigen. Hennink und Kaiser haben solche Modelle in ihrem Review ausdrücklich nicht übernommen, weil sie eine Zufallsstichprobe und eine bekannte Prävalenz der Themen voraussetzen, die es in qualitativer Forschung praktisch nie gibt @hennink2022sample. Eine bessere Begründung kombiniert die empirische Bandbreite (9 bis 17 Interviews für homogene Gruppen) mit einer Information-Power-Argumentation entlang der fünf Dimensionen @malterud2016sample und einem Plan, die Sättigung nachträglich mit permutierter Fallreihenfolge zu prüfen @buckley2022ten.])

=== Vertrauenswürdigkeit statt Validität

Wie argumentiert man Qualität ohne $p$-Werte? Lincoln und Guba haben dafür vier Kriterien der *Vertrauenswürdigkeit* (_trustworthiness_) vorgeschlagen, die als Parallelen zu den klassischen Kriterien gedacht sind @lincoln1985naturalistic: *Glaubwürdigkeit* (_credibility_) als Pendant zur internen Validität, *Übertragbarkeit* (_transferability_) zur externen Validität, *Verlässlichkeit* (_dependability_) zur Reliabilität und *Bestätigbarkeit* (_confirmability_) zur Objektivität.

Das Lehrbuch übersetzt diese Kriterien in konkrete Strategien @haindl2027research. Für die *Glaubwürdigkeit*: die *Negativfallanalyse*, die gezielt Daten sucht, die den sich abzeichnenden Mustern widersprechen; die *progressive Subjektivität*, die dokumentiert, wie sich das Verständnis der Forschenden verändert; und die *referenzielle Adäquatheit*, bei der ein Teil der Rohdaten vor der Analyse zurückgelegt und später zur Prüfung der Interpretationen herangezogen wird. Für die *Übertragbarkeit*: theoretisches Sampling, das die Grenzen der entstehenden Theorie testet, und *analytische Generalisierung*, die theoretische Aussagen statt Populationsaussagen entwickelt. Für die *Verlässlichkeit*: die *schrittweise Replikation*, bei der Teammitglieder Teilmengen unabhängig analysieren und dann vergleichen, und das *Inquiry Audit*, das Rohdatenverzeichnis, Reduktions- und Rekonstruktionsprodukte, Prozessnotizen, Absichtsmaterialien und Instrumentenentwicklung für externe Prüfung strukturiert. Für die *Bestätigbarkeit*: ein *Bestätigbarkeits-Audit*, das jeden Hauptbefund über eine "Beweiskette" bis zu den Rohdaten zurückverfolgt, inklusive verworfener Alternativinterpretationen @haindl2027research.

Ein neuerer Rahmen stammt von der APA. Die Berichtsstandards JARS-Qual gründen die Bewertung qualitativer Vertrauenswürdigkeit auf *methodologische Integrität*, die aus *Treue zum Gegenstand* (Datenadäquatheit, Perspektivenmanagement in Erhebung und Analyse, Verankerung in den Daten) und *Nützlichkeit für die Forschungsziele* (Kontextualisierung, Anstoß zu Einsichten, bedeutsamer Beitrag, Kohärenz) besteht @levitt2018journal. Braun und Clarke warnen zudem davor, einen einzigen universellen Qualitätsstandard über qualitative Ansätze mit unterschiedlichen Paradigmen zu legen @braun2021one.

#merke[Für LLM-gestützte qualitative Forschung ist das *Audit Trail* das wichtigste Werkzeug der Vertrauenswürdigkeit. Es muss nun zusätzlich Modellversion, Prompts, Parameter und die vollständigen Ausgaben enthalten, und jede Stelle, an der eine LLM-Ausgabe in eine Interpretation eingeht, muss rückverfolgbar sein. Dyers, Bello und Guetterman empfehlen für Mixed-Methods-Integration ausdrücklich Audit Trails mit Memos und Versionskontrolle @dyers2025separate; das gilt hier erst recht (Kapitel 10).]

== Quantitative Forschung <k01-quant>

Quantitative Forschung misst, zählt und testet. Ihr Ziel ist es, Theorien zu prüfen, Zusammenhänge zwischen Variablen zu etablieren und auf Populationen zu generalisieren @haindl2027research. Dieser Abschnitt behandelt die Logik des Hypothesentests, die richtige Lesart des $p$-Werts, Effektstärken und die Power-Analyse mit vollständiger Herleitung. Er ist der mathematische Kern des Kapitels und die Grundlage für Kapitel 6, in dem LLM-Ausgaben als Messwerte in statistische Inferenz eingehen.

=== Experiment, Quasi-Experiment und Survey in der Datenwissenschaft

Viele Data-Science-Arbeiten sind Experimente, ohne es zu sagen. Ein Modellvergleich auf einem Benchmark ist ein (Quasi-)Experiment mit dem Modell als Behandlung und den Testitems als Untersuchungseinheiten; eine Anforderungs- oder Nutzerstudie ist qualitativ; eine Evaluation, die Metriken mit Interviews von Praktikerinnen kombiniert, ist ein Mixed-Methods-Design @creswell2022research @venkatesh2013bridging. Wohlin et al. haben die zweite Auflage ihres Standardwerks zur experimentellen Softwaretechnik um A/B-Tests, Replikationen, Open Science, Validitätsbedrohungen und gepaarte Vergleichsdesigns erweitert @wohlin2024experimentation, also genau um die Themen, die für Modellvergleiche zählen.

Surveys sind in der Informatik populär, weil sie Hunderte Personen günstig erreichen, während qualitative Interviews viel Zeit pro Person kosten @haindl2027research. Sie liefern eine quantitative Beschreibung von Trends, Einstellungen, Meinungen oder Merkmalen einer Population über eine Stichprobe und eignen sich für Fragen nach Prävalenz, Verteilung und Zusammenhängen @haindl2027research. *Querschnitt-Surveys* erheben zu einem Zeitpunkt; sie zeigen Korrelationen, können aber keine zeitliche Priorität herstellen. *Längsschnitt-Surveys* erheben über die Zeit, als Trendstudien (verschiedene Stichproben derselben Population), Kohortenstudien (eine durch ein gemeinsames Merkmal definierte Gruppe) oder Panelstudien (dieselben Personen wiederholt), jeweils mit dem Preis des Stichprobenschwunds @haindl2027research. Online-Surveys an externe oder unaufgeforderte Zielgruppen erreichen oft Rücklaufquoten unter 25 %, bei Kaltakquise noch weniger, was die Frage nach dem Non-Response-Bias aufwirft @haindl2027research.

Das Lehrbuch nennt die typischen Verzerrungen: *soziale Erwünschtheit* (sich vorteilhaft darstellen), *Zustimmungstendenz* (zustimmen unabhängig vom Inhalt) und *Satisficing* (minimal akzeptable Antworten geben). Surveys messen gut das "Was", aber schlecht das "Warum", lassen sich nach dem Versand nicht mehr korrigieren und können ohne Manipulation keine Kausalität zeigen @haindl2027research. Die Stichprobenstrategie entscheidet über die Generalisierungsansprüche: Wahrscheinlichkeitsstichproben (zufällig, geschichtet, Cluster) erlauben statistische Inferenz, Gelegenheits- und zweckgerichtete Stichproben nur eingeschränkte Generalisierung. Fragen müssen vorab mit kognitiven Interviews und Piloten getestet werden, weil Suggestivfragen, doppelte Fragen und mehrdeutige Begriffe die Validität bedrohen; Begriffe wie "technische Schuld" bedeuten in verschiedenen Kontexten Verschiedenes @haindl2027research.

#fallstrick[Werden LLMs als "synthetische Befragte" eingesetzt, fallen die klassischen Survey-Probleme nicht weg, sie verschieben sich. Es gibt keinen Non-Response-Bias, aber die Frage, welche Population die Antworten repräsentieren, ist offener als bei jeder Gelegenheitsstichprobe; soziale Erwünschtheit kann als Tendenz des Modells zu "angemessenen" Antworten wiederkehren. Das ist eine Frage der Konstrukt- und externen Validität, die Kapitel 4 vertieft.]

Ihre Qualität hängt außerdem an der Konstruktvalidität der Skalen. Das Lehrbuch nennt dafür Inhaltsvalidität (Fachleute bestätigen, dass die Items den Konstruktbereich abdecken), konvergente Validität (Korrelation mit verwandten Maßen), diskriminante Validität (geringe Korrelation mit unverwandten Konstrukten) und Faktorstruktur, geprüft mit konfirmatorischer Faktorenanalyse; vor Gruppenvergleichen muss zudem Messinvarianz gezeigt werden @haindl2027research.

=== Die Logik des Hypothesentests

Der Signifikanztest nach Fisher, Neyman und Pearson operationalisiert die Idee der Falsifikation: Man nimmt die Nullhypothese $H_0$ (typischerweise "kein Effekt") an, berechnet, wie wahrscheinlich die beobachteten oder extremere Daten unter dieser Annahme wären, und verwirft $H_0$, wenn diese Wahrscheinlichkeit klein genug ist; angenommen wird $H_0$ dabei nie, sie wird nur nicht verworfen @haindl2027research. Hypothesen und Signifikanzniveau müssen vor der Datenerhebung feststehen, um p-Hacking und HARKing (Hypothesenbildung nach Kenntnis der Ergebnisse) zu vermeiden @haindl2027research.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let w = 4.2
    let h = 1.35
    content((w / 2 + 2.4, 2 * h + 0.75), text(font: "Inter", size: 7.5pt, weight: "bold", [$H_0$ ist wahr]))
    content((w * 1.5 + 2.4, 2 * h + 0.75), text(font: "Inter", size: 7.5pt, weight: "bold", [$H_0$ ist falsch]))
    content((w + 2.4, 2 * h + 1.2), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%), [Wirklichkeit]))
    content((1.15, 1.5 * h), align(right, text(font: "Inter", size: 7.5pt, weight: "bold", [$H_0$ verwerfen])))
    content((1.15, 0.5 * h), align(right, text(font: "Inter", size: 7.5pt, weight: "bold", [$H_0$ nicht \ verwerfen])))
    content((0.0, h), angle: 90deg, text(font: "Inter", size: 7pt, fill: c-grey.darken(20%), [Entscheidung]))
    let zellen = (
      (0, 1, c-red, [*Fehler 1. Art* \ falsch positiv \ Wahrscheinlichkeit $alpha$]),
      (1, 1, c-green, [*korrekt* \ richtig positiv \ Power $1 - beta$]),
      (0, 0, c-green, [*korrekt* \ richtig negativ \ $1 - alpha$]),
      (1, 0, c-red, [*Fehler 2. Art* \ falsch negativ \ Wahrscheinlichkeit $beta$]),
    )
    for (cx, cy, col, body) in zellen {
      let x0 = 2.4 + cx * w
      let y0 = cy * h
      rect((x0, y0), (x0 + w, y0 + h), fill: col.lighten(88%), stroke: 0.8pt + col)
      content((x0 + w / 2, y0 + h / 2), align(center, text(font: "Inter", size: 7.3pt, body)))
    }
  }),
  caption: [Die vier Ausgänge eines Hypothesentests, nach @haindl2027research. $alpha$ wird direkt durch das Signifikanzniveau kontrolliert, $beta$ nur indirekt durch Stichprobenumfang, Effektgröße und $alpha$.],
) <k01-fig-fehler>

Ein *Fehler 1. Art* ($alpha$) ist ein falsch positiver Befund, ein *Fehler 2. Art* ($beta$) ein falsch negativer; die *Power* $1 - beta$ ist die Wahrscheinlichkeit, einen tatsächlich vorhandenen Effekt zu entdecken @haindl2027research (@k01-fig-fehler). Konvention ist eine Power von 0.80; sie steigt mit größeren Effekten, größeren Stichproben und einem weniger strengen $alpha$ @haindl2027research. Zweiseitige Tests sind der Normalfall; ein einseitiger Test braucht eine starke, vorab festgelegte Begründung, weil er den entgegengesetzten Effekt nicht entdecken kann. Wenn eine Optimierung die Performance theoretisch auch verschlechtern könnte, ist ein einseitiger Test auf Verbesserung unangemessen @haindl2027research.

=== Was ein $p$-Wert ist und was nicht

#definition(titel: [$p$-Wert nach der ASA])[
  "Informally, a p-value is the probability under a specified statistical model that a statistical summary of the data (e.g., the sample mean difference between two compared groups) would be equal to or more extreme than its observed value." @wasserstein2016asa Formal für eine Teststatistik $T$ mit beobachtetem Wert $t_"obs"$ und zweiseitigem Test: $p = P(|T| >= |t_"obs"| mid(|) H_0)$.
]

Der häufigste Fehler ist der inverse Schluss: Der $p$-Wert ist $P("Daten so extrem oder extremer" mid(|) H_0)$, nicht $P(H_0 mid(|) "Daten")$ @haindl2027research. Die American Statistical Association hat 2016 in ihrer ersten formalen Stellungnahme zu $p$-Werten, vom Executive Committee am 29. Januar 2016 verabschiedet, sechs Prinzipien formuliert @wasserstein2016asa:

+ $p$-Werte können anzeigen, wie inkompatibel die Daten mit einem spezifizierten statistischen Modell sind.
+ $p$-Werte messen nicht die Wahrscheinlichkeit, dass die Hypothese wahr ist, oder dass die Daten allein durch Zufall entstanden sind.
+ Wissenschaftliche Schlussfolgerungen und Entscheidungen sollten nicht allein darauf beruhen, ob ein $p$-Wert eine Schwelle unterschreitet.
+ Korrekte Inferenz erfordert vollständige Berichterstattung und Transparenz.
+ Ein $p$-Wert misst weder Effektgröße noch Bedeutsamkeit eines Ergebnisses.
+ Für sich genommen ist ein $p$-Wert kein gutes Maß für Evidenz bezüglich eines Modells oder einer Hypothese.

Die Stellungnahme schreibt bewusst keinen Ersatz vor und erwähnt Alternativen wie Konfidenzintervalle oder bayesianische Methoden nur knapp @wasserstein2016asa. Das Lehrbuch ergänzt die Unterscheidung zwischen statistischer und praktischer Signifikanz: Bei $n = 10 thin 000$ kann eine Verbesserung um 0.1 % hochsignifikant und praktisch belanglos sein, während eine Verbesserung um 50 % bei $n = 10$ wegen geringer Power nicht signifikant wird @haindl2027research.

#fallstrick[Eine Leaderboard-Tabelle mit fett gedrucktem "bestem" Wert verletzt in der Regel gleich mehrere ASA-Prinzipien: Sie trifft eine binäre Entscheidung ohne Unsicherheitsangabe (Prinzip 3), verschweigt, wie viele Konfigurationen ausprobiert wurden (Prinzip 4), und sagt nichts über die praktische Größe des Unterschieds (Prinzip 5). Formuliere stattdessen eine Schätzung mit Intervall: "Modell A ist um 2.1 Prozentpunkte genauer (95-%-KI ...)".]

=== Effektstärken <k01-effekt>

Effektstärken quantifizieren die Größe eines Effekts unabhängig vom Stichprobenumfang, machen Studien vergleichbar, ermöglichen Metaanalysen und sind die Eingangsgröße jeder Power-Analyse @haindl2027research. Lakens bringt es auf die knappe Forderung, Forschende sollten Effektstärken immer berichten @lakens2013calculating.

#definition(titel: [Cohens $d$ mit gepoolter Standardabweichung])[
  Für zwei unabhängige Gruppen mit Mittelwerten $macron(x)_1, macron(x)_2$, erwartungstreuen Stichprobenvarianzen $s_1^2, s_2^2$ und Umfängen $n_1, n_2$ ist
  $ d = (macron(x)_1 - macron(x)_2) / s_p, quad s_p = sqrt(((n_1 - 1) s_1^2 + (n_2 - 1) s_2^2) / (n_1 + n_2 - 2)). $ <k01-eq-d>
  $s_p$ heißt gepoolte Standardabweichung. Cohens Konventionen sind $d = 0.20$ (klein), $0.50$ (mittel) und $0.80$ (groß) @cohen1992power[Tab. 1].
]

Cohen hat "mittel" als einen Effekt definiert, der "visible to the naked eye of a careful observer" sei @cohen1992power. Die Konventionen sind also Urteile, keine empirischen Benchmarks eines bestimmten Fachs. @k01-tab-cohen zeigt alle acht Indizes seines Primers.

#figure(
  table(columns: (1fr, auto, auto, auto, auto),
    [Test], [Index], [klein], [mittel], [groß],
    [Differenz unabhängiger Mittelwerte], [$d$], [0.20], [0.50], [0.80],
    [Signifikanz einer Produkt-Moment-Korrelation], [$r$], [0.10], [0.30], [0.50],
    [Differenz unabhängiger Korrelationen], [$q$], [0.10], [0.30], [0.50],
    [Vorzeichentest], [$g = P - 0.50$], [0.05], [0.15], [0.25],
    [Differenz unabhängiger Anteile], [$h$], [0.20], [0.50], [0.80],
    [Chi-Quadrat (Anpassung, Kontingenz)], [$w$], [0.10], [0.30], [0.50],
    [Einfaktorielle ANOVA], [$f$], [0.10], [0.25], [0.40],
    [Multiple und partielle Korrelation], [$f^2$], [0.02], [0.15], [0.35],
  ),
  caption: [Cohens Konventionen für kleine, mittlere und große Effekte, nach @cohen1992power[Tab. 1]. Cohen selbst nennt die Tabellen "convenient, although not comprehensive"; die vollständige Behandlung steht in @cohen1988statistical.],
) <k01-tab-cohen>

#beispiel(titel: [Cohens $d$ für zwei Annotationsoberflächen])[
  Zwei Annotationsoberflächen werden je mit $n_1 = n_2 = 5$ Personen getestet; die Genauigkeitswerte sind Gruppe 1: 72, 75, 78, 80, 83 und Gruppe 2: 68, 70, 71, 74, 77. Die Mittelwerte sind $macron(x)_1 = 77.6$ und $macron(x)_2 = 72.0$, die Varianzen $s_1^2 = 18.3$ und $s_2^2 = 12.5$. Nach @k01-eq-d ist
  $ s_p = sqrt((4 dot 18.3 + 4 dot 12.5) / 8) = sqrt(15.4) approx 3.92, quad d = 5.6 / 3.92 approx 1.43. $
  Das ist weit über Cohens "groß". Der zugehörige Zweistichproben-$t$-Test liefert aber $t = d sqrt(n_1 n_2 slash (n_1 + n_2)) = 1.427 dot sqrt(2.5) approx 2.26$ mit 8 Freiheitsgraden und $p approx 0.054$, ist also bei $alpha = 0.05$ nicht signifikant. Der Standardfehler von $d$ beträgt näherungsweise $sqrt((n_1 + n_2) slash (n_1 n_2) + d^2 slash (2(n_1 + n_2))) approx 0.71$, das approximative 95-%-Intervall reicht von etwa 0.04 bis 2.82. Ein "großer" Effekt aus fünf Personen pro Gruppe ist schlicht sehr unpräzise geschätzt.
]

Der Zusammenhang zwischen $d$ und $t$ im Beispiel ist kein Zufall. Mit gepoolter Varianz lautet die $t$-Statistik $t = (macron(x)_1 - macron(x)_2) slash (s_p sqrt(1 slash n_1 + 1 slash n_2))$; Einsetzen von @k01-eq-d gibt
$ t = d dot sqrt((n_1 n_2) / (n_1 + n_2)). $ <k01-eq-dt>
Die Gleichung zeigt in einer Zeile, warum $p$-Werte keine Effektstärken sind (ASA-Prinzip 5): Bei festem $d$ wächst $t$ mit $sqrt(n)$, und jeder noch so kleine Effekt wird bei genügend großem $n$ signifikant.

#block(above: 1.1em, below: 0.55em, sticky: true, text(size: 9.6pt, weight: "bold", style: "italic", fill: c-dark)[Gepaarte Designs: $d_z$ und $d_"av"$])

Werden zwei Modelle auf denselben Testitems bewertet, sind die Messungen gepaart. Lakens unterscheidet dann zwei Indizes @lakens2013calculating:
$ d_z = macron(x)_"diff" / s_"diff", quad d_"av" = macron(x)_"diff" / ((s_1 + s_2) slash 2), $ <k01-eq-dz>
wobei $macron(x)_"diff"$ der Mittelwert der itemweisen Differenzen, $s_"diff"$ deren Standardabweichung und $s_1, s_2$ die Standardabweichungen der beiden Bedingungen sind. Für den gepaarten $t$-Test mit $n$ Paaren gilt analog zu @k01-eq-dt die Identität $d_z = t slash sqrt(n)$. Weil $s_"diff"$ die große Streuung der Itemschwierigkeit herausrechnet, kann $d_z$ ein Vielfaches von $d_"av"$ betragen; das Notebook zeigt mit synthetischen Daten (40 Items, gemeinsame Itemschwierigkeit, Prompt B im Mittel 2 Punkte besser) ein $d_z$, das etwa dreimal so groß ist wie $d_"av"$. Keiner der beiden Werte ist falsch, aber sie beantworten verschiedene Fragen und sind nicht in gleicher Weise mit Cohens Konventionen vergleichbar; Lakens verlangt deshalb, immer zu kennzeichnen, welches $d$ berichtet wird @lakens2013calculating.

#fallstrick[Wer zwei LLMs auf demselben Benchmark vergleicht und $d_z$ berichtet, dann aber mit Cohens "groß" ab 0.8 argumentiert, vergleicht Äpfel mit Birnen. Cohens Konventionen beziehen sich auf die Streuung zwischen Personen bzw. Einheiten, nicht auf die Streuung von Differenzen. Berichte bei gepaarten Modellvergleichen beide Indizes oder begründe die Wahl explizit @lakens2013calculating.]

#block(above: 1.1em, below: 0.55em, sticky: true, text(size: 9.6pt, weight: "bold", style: "italic", fill: c-dark)[Varianzanalyse und Korrelationen])

Für eine ANOVA mit festen Faktoren lässt sich das partielle Eta-Quadrat aus dem $F$-Wert und den Freiheitsgraden des Effekts ($"df"_1$) und des Fehlers ($"df"_2$) zurückrechnen @lakens2013calculating[Formel 13]:
$ eta_p^2 = (F dot "df"_1) / (F dot "df"_1 + "df"_2). $ <k01-eq-eta>
Lakens empfiehlt, zusätzlich oder stattdessen das generalisierte $eta_G^2$ zu berichten, weil $eta_p^2$ zwischen Designs schlecht vergleichbar ist @lakens2013calculating. Für Korrelationen ist $r$ selbst die Effektstärke, und $r^2$ ist der Anteil erklärter Varianz @haindl2027research. Zwischen $r$ und $d$ wird mit der Standardumrechnung
$ d = (2 r) / sqrt(1 - r^2) $ <k01-eq-rd>
übersetzt, die für zwei gleich große Gruppen gilt.

#beispiel(titel: [Effektstärke aus einem publizierten $F$-Test])[
  Simmons, Nelson und Simonsohn berichten für ihre absichtlich "falsch positive" Studie 2 den Wert $F(1, 17) = 4.92$ @simmons2011false. Nach @k01-eq-eta ist $eta_p^2 = 4.92 slash (4.92 + 17) approx 0.22$. Ein Fünftel erklärter Varianz für die Behauptung, ein Beatles-Song mache Menschen jünger, zeigt, dass eine große Effektstärke aus einer kleinen, flexibel ausgewerteten Studie keinerlei Schutz vor falschen Befunden bietet.
]

#block(above: 1.1em, below: 0.55em, sticky: true, text(size: 9.6pt, weight: "bold", style: "italic", fill: c-dark)[Effektstärken anschaulich machen])

Das Lehrbuch veranschaulicht Cohens Konventionen als überlappende Normalverteilungen: Bei $d = 0.2$ überlappen sich die Verteilungen zu 85 %, bei $d = 0.5$ zu 67 % und bei $d = 0.8$ zu 53 %; bei $d = 0.8$ liegt die durchschnittliche behandelte Person etwa beim 79. Perzentil der Kontrollverteilung @haindl2027research. Die Überlappungswerte entsprechen $1 - U_1$, dem Komplement von Cohens Nichtüberlappungsmaß $U_1 = (2 Phi(d slash 2) - 1) slash Phi(d slash 2)$, das Perzentil entspricht $U_3 = Phi(d)$, wobei $Phi$ die Verteilungsfunktion der Standardnormalverteilung ist. Ein anderes, ebenfalls gebräuchliches Überlappungsmaß, der Überlappungskoeffizient $2 Phi(-d slash 2)$, ergäbe 92 %, 80 % und 69 %; wer Überlappungen berichtet, sollte also das Maß nennen.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let f(x, m) = calc.exp(-calc.pow(x - m, 2) / 2) / calc.sqrt(2 * calc.pi)
    let panels = ((0.2, [85 %], [58 %]), (0.5, [67 %], [69 %]), (0.8, [53 %], [79 %]))
    for (k, (d, ov, u3)) in panels.enumerate() {
      let ox = k * 5.0
      let sx = 0.55
      let sy = 4.2
      let xs = range(0, 161).map(i => -3.5 + i * 0.05)
      let ovpts = xs.map(x => ((ox + x * sx + 2.0), calc.min(f(x, 0), f(x, d)) * sy))
      line((ox + 2.0 - 3.5 * sx, 0), ..ovpts, (ox + 2.0 + 4.5 * sx, 0), close: true, fill: c-teal.lighten(75%), stroke: none)
      line(..xs.map(x => (ox + x * sx + 2.0, f(x, 0) * sy)), stroke: 1pt + c-blue)
      line(..xs.map(x => (ox + x * sx + 2.0, f(x, d) * sy)), stroke: 1pt + c-accent)
      line((ox + 2.0 - 3.5 * sx, 0), (ox + 2.0 + 4.5 * sx, 0), stroke: 0.6pt + c-dark)
      content((ox + 2.0 + d * sx / 2, 2.05), text(font: "Inter", size: 7.5pt, weight: "bold", [$d = #d$]))
      content((ox + 2.0 + d * sx / 2, -0.35), text(font: "Inter", size: 6.8pt, [$1 - U_1$ = #ov · $U_3$ = #u3]))
    }
    content((2.0, -0.85), text(font: "Inter", size: 6.8pt, fill: c-blue, [Kontrolle]))
    content((7.0, -0.85), text(font: "Inter", size: 6.8pt, fill: c-accent, [Behandlung]))
    content((12.0, -0.85), text(font: "Inter", size: 6.8pt, fill: c-teal.darken(20%), [Fläche: Überlappungskoeffizient]))
  }),
  caption: [Cohens Konventionen als überlappende Normalverteilungen (Werte nach @haindl2027research; Überlappung als $1 - U_1$, $U_3$ als Perzentil der mittleren behandelten Einheit in der Kontrollverteilung). Die schattierte Fläche zeigt dagegen den Überlappungskoeffizienten $2 Phi(-d slash 2)$ (92 %, 80 %, 69 %).],
) <k01-fig-overlap>

=== Power-Analyse: Herleitung und Rechnung

Die Power-Analyse beantwortet vor der Datenerhebung die Frage, wie groß eine Stichprobe sein muss, damit ein Effekt einer angenommenen Größe mit ausreichender Wahrscheinlichkeit entdeckt wird. Wir leiten die Standardformel für den Zweistichproben-$t$-Test zuerst mit der Normalapproximation her und vergleichen sie dann mit der exakten Rechnung über die nichtzentrale $t$-Verteilung.

#satz(titel: [Stichprobenumfang pro Gruppe, Normalapproximation])[
  Für einen zweiseitigen Test auf Mittelwertunterschied zweier unabhängiger Gruppen mit je $n$ Einheiten, Signifikanzniveau $alpha$, angestrebter Power $1 - beta$ und standardisiertem Populationseffekt $d > 0$ gilt näherungsweise
  $ n approx (2 (z_(1 - alpha slash 2) + z_(1 - beta))^2) / d^2, $ <k01-eq-n>
  wobei $z_q$ das $q$-Quantil der Standardnormalverteilung bezeichnet.
]

#beweis-fest[
  Seien die Messwerte in beiden Gruppen normalverteilt mit gemeinsamer Standardabweichung $sigma$ und Mittelwerten $mu_1, mu_2$, und sei $d = (mu_1 - mu_2) slash sigma$. Die Differenz der Gruppenmittel $D = macron(x)_1 - macron(x)_2$ hat Varianz $sigma^2 (1 slash n + 1 slash n) = 2 sigma^2 slash n$. Bei bekanntem $sigma$ ist die Teststatistik $Z = D slash (sigma sqrt(2 slash n))$ unter $H_0$ standardnormalverteilt und unter $H_1$ normalverteilt mit Erwartungswert
  $ delta = (mu_1 - mu_2) / (sigma sqrt(2 slash n)) = d sqrt(n slash 2) $
  und Varianz 1. Der zweiseitige Test verwirft, wenn $|Z| > z_(1 - alpha slash 2)$. Die Power ist daher
  $ 1 - beta = P(Z > z_(1 - alpha slash 2)) + P(Z < -z_(1 - alpha slash 2)) approx Phi(delta - z_(1 - alpha slash 2)), $
  weil der zweite Summand für $delta > 0$ vernachlässigbar ist. Setzt man die Power gleich $1 - beta$, folgt $delta = z_(1 - alpha slash 2) + z_(1 - beta)$, also $d sqrt(n slash 2) = z_(1 - alpha slash 2) + z_(1 - beta)$. Quadrieren und Auflösen nach $n$ liefert @k01-eq-n.
]

Bei unbekanntem $sigma$ wird $sigma$ durch $s_p$ geschätzt; die Teststatistik folgt dann unter $H_0$ einer zentralen $t$-Verteilung mit $2n - 2$ Freiheitsgraden und unter $H_1$ einer *nichtzentralen* $t$-Verteilung mit demselben Nichtzentralitätsparameter $delta = d sqrt(n slash 2)$. Die exakte Power ist
$ 1 - beta = 1 - F_(t, 2n-2, delta)(t_"krit") + F_(t, 2n-2, delta)(-t_"krit"), quad t_"krit" = t_(2n-2, 1 - alpha slash 2), $ <k01-eq-power>
wobei $F_(t, nu, delta)$ die Verteilungsfunktion der nichtzentralen $t$-Verteilung mit $nu$ Freiheitsgraden ist. Den kleinsten Umfang findet man, indem man $n$ erhöht, bis die Power den Zielwert erreicht.

#beispiel(titel: [64 pro Gruppe für einen mittleren Effekt])[
  Für $alpha = 0.05$, Power $0.80$ und $d = 0.5$ ist $z_(0.975) approx 1.960$ und $z_(0.80) approx 0.842$. Nach @k01-eq-n ist
  $ n approx (2 (1.960 + 0.842)^2) / 0.25 approx 62.8. $
  Die exakte Rechnung nach @k01-eq-power ergibt $n = 64$ pro Gruppe und stimmt mit Cohens Tabelle überein @cohen1992power[Tab. 2]. Für $d = 0.2$ und $d = 0.8$ liefert die exakte Rechnung 394 und 26 Einheiten pro Gruppe; Cohen tabelliert 393 und 26 @cohen1992power[Tab. 2]. Die Abweichung um eins bei $d = 0.2$ geht vermutlich auf Rundung oder Approximation in den Originaltabellen zurück (statsmodels liefert ungerundet 393.4), eine gute Gelegenheit, Studierenden das Nachrechnen von Primärquellen beizubringen. Umgekehrt hat eine Studie mit $n = 20$ pro Gruppe bei einem wahren $d = 0.5$ nur eine Power von 0.34: Zwei von drei solchen Studien "scheitern", obwohl der Effekt existiert. Für das Annotationsbeispiel mit $n = 5$ pro Gruppe läge die Power selbst bei einem wahren $d = 1.43$ nur bei etwa 0.51.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let ns = (5, 10, 20, 30, 40, 50, 64, 80, 100, 120, 150)
    let p2 = (0.059, 0.071, 0.095, 0.119, 0.143, 0.168, 0.202, 0.242, 0.291, 0.339, 0.408)
    let p5 = (0.108, 0.185, 0.338, 0.478, 0.598, 0.697, 0.801, 0.882, 0.94, 0.971, 0.991)
    let p8 = (0.201, 0.395, 0.693, 0.861, 0.942, 0.977, 0.994, 0.999, 1.0, 1.0, 1.0)
    let sx = 0.075
    let sy = 4.2
    line((0, 0), (150 * sx + 0.3, 0), stroke: 0.7pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.5))
    line((0, 0), (0, sy + 0.3), stroke: 0.7pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.5))
    for x in (0, 25, 50, 75, 100, 125, 150) {
      line((x * sx, 0), (x * sx, -0.08), stroke: 0.5pt)
      content((x * sx, -0.3), text(font: "Inter", size: 7pt, str(x)))
    }
    for y in (0, 0.2, 0.4, 0.6, 0.8, 1.0) {
      line((0, y * sy), (-0.08, y * sy), stroke: 0.5pt)
      content((-0.35, y * sy), text(font: "Inter", size: 7pt, str(y)))
      if y > 0 { line((0, y * sy), (150 * sx, y * sy), stroke: 0.3pt + luma(225)) }
    }
    line((0, 0.8 * sy), (150 * sx, 0.8 * sy), stroke: (paint: c-red, dash: "dashed", thickness: 0.7pt))
    content((150 * sx, 0.8 * sy + 0.18), anchor: "east", text(font: "Inter", size: 6.8pt, fill: c-red, [Ziel: Power 0.80]))
    for (vals, col, lab, ly) in ((p2, c-grey, [$d = 0.2$], 0.408), (p5, c-blue, [$d = 0.5$], 0.991), (p8, c-accent, [$d = 0.8$], 1.0)) {
      line(..ns.zip(vals).map(((n, p)) => (n * sx, p * sy)), stroke: 1.1pt + col)
      for (n, p) in ns.zip(vals) { circle((n * sx, p * sy), radius: 0.045, fill: col, stroke: none) }
    }
    content((150 * sx + 0.1, 0.408 * sy), anchor: "west", text(font: "Inter", size: 7pt, fill: c-grey.darken(20%), [$d = 0.2$]))
    content((110 * sx, 0.93 * sy), anchor: "north", text(font: "Inter", size: 7pt, fill: c-blue, [$d = 0.5$]))
    content((25 * sx, 0.93 * sy), anchor: "east", text(font: "Inter", size: 7pt, fill: c-accent, [$d = 0.8$]))
    line((64 * sx, 0), (64 * sx, 0.801 * sy), stroke: (paint: c-blue, dash: "dotted", thickness: 0.7pt))
    content((64 * sx + 0.08, 0.25), anchor: "west", text(font: "Inter", size: 6.8pt, fill: c-blue, [$n = 64$]))
    circle((20 * sx, 0.338 * sy), radius: 0.09, stroke: 0.9pt + c-dark, fill: none)
    content((20 * sx + 0.15, 0.338 * sy - 0.3), anchor: "west", text(font: "Inter", size: 6.8pt, [$n = 20$: Power 0.34]))
    content((75 * sx, -0.75), text(font: "Inter", size: 7.5pt, [Stichprobenumfang $n$ pro Gruppe]))
    content((-1.0, 0.5 * sy), angle: 90deg, text(font: "Inter", size: 7.5pt, [Power $1 - beta$]))
  }),
  caption: [Exakte Power des zweiseitigen Zweistichproben-$t$-Tests ($alpha = 0.05$) nach @k01-eq-power, berechnet mit `scipy.stats.nct`. Für einen kleinen Effekt bleibt die Power selbst bei 150 Einheiten pro Gruppe unter 0.5.],
) <k01-fig-power>

#figure(
  table(columns: (1fr, auto, auto, auto, auto),
    [Test], [klein], [mittel], [groß], [$N$ bezieht sich auf],
    [Mittelwertdifferenz ($t$-Test)], [393], [64], [26], [pro Gruppe],
    [Signifikanz von $r$], [783], [85], [28], [gesamt],
    [Differenz zweier $r$], [1573], [177], [66], [pro Gruppe],
    [Vorzeichentest], [783], [85], [30], [gesamt],
    [Differenz zweier Anteile], [392], [63], [25], [pro Gruppe],
  ),
  caption: [Benötigter Stichprobenumfang für Power 0.80 bei $alpha = 0.05$ (zweiseitig), nach @cohen1992power[Tab. 2]. Achtung: Für die Signifikanz von $r$ und den Vorzeichentest ist $N$ der Gesamtumfang, nicht der Umfang pro Gruppe.],
) <k01-tab-cohen-n>

#datei-fest("power.py")[
```python
import numpy as np
from scipy import stats

def power_two_sample_t(n, d, alpha=0.05):
    """Exakte Power eines zweiseitigen Zweistichproben-t-Tests, n pro Gruppe."""
    df = 2 * n - 2
    nc = d * np.sqrt(n / 2)                     # Nichtzentralitaet delta
    tcrit = stats.t.ppf(1 - alpha / 2, df)
    return 1 - stats.nct.cdf(tcrit, df, nc) + stats.nct.cdf(-tcrit, df, nc)

def n_per_group(d, power=0.80, alpha=0.05):
    n = 2
    while power_two_sample_t(n, d, alpha) < power:
        n += 1
    return n

for d in (0.2, 0.5, 0.8):
    print(d, n_per_group(d))                    # 394, 64, 26
print(round(power_two_sample_t(20, 0.5), 2))   # 0.34

from statsmodels.stats.power import TTestIndPower
TTestIndPower().solve_power(effect_size=0.5, alpha=0.05, power=0.8)  # 63.77 -> 64
```
]

Dieselbe Rechnung liefern `statsmodels` (`TTestIndPower`) und `pingouin` (`power_ttest`) mit 63.77, aufgerundet 64 pro Gruppe; als grafische Alternative dient G\*Power @faul2007gpower. Getestet wurde der Code laut Wissensbasis mit SciPy 1.18.1, statsmodels 0.15.0 und pingouin 0.7.0 (Stand: 11. November 2026). In statsmodels 0.15.0 ersetzt der Parameter `rng` die älteren Parameter `random_state` und `seed`, was bei Simulationen relevant ist (Stand: 11. November 2026).

#merke[Power-Analyse ist nur eine von sechs Arten, einen Stichprobenumfang zu begründen. Lakens nennt außerdem die Messung (fast) der ganzen Population, Ressourcengrenzen, die Planung auf Genauigkeit (Breite eines Konfidenzintervalls), Heuristiken und das offene Eingeständnis, dass es keine Begründung gibt @lakens2022sample. "Andere haben auch 100 genommen" ist keine davon. Das gilt ausdrücklich auch für die Größe menschlicher Validierungsstichproben in LLM-Annotationsstudien (Kapitel 5 und 6).]

#hoersaal-fest([Für meinen Modellvergleich habe ich keine Ahnung, wie groß der Effekt ist. Soll ich dann einfach $d = 0.5$ annehmen?], [Bitte nicht reflexhaft. Cohens Konventionen sind feldunabhängige Voreinstellungen, die auf seinem Urteil beruhen @cohen1992power; für ML-Benchmarks ist "mittel" meist unbegründet. Besser ist, einen kleinsten interessierenden Effekt aus der Anwendung abzuleiten, etwa "eine Verbesserung um zwei Prozentpunkte Genauigkeit würde den Umstieg rechtfertigen", und zu fragen, wie informativ die Daten über Effekte dieser Größe sein werden @lakens2022sample. Bei einem gepaarten Design auf festen Testitems ist zudem nicht $d$, sondern $d_z$ die richtige Eingangsgröße der Power-Rechnung @lakens2013calculating.])

== Replikationskrise, Forking Paths und Leakage <k01-krise>

Die Werkzeuge des vorigen Abschnitts sind korrekt, aber sie setzen voraus, dass Forschende genau einen vorab festgelegten Test durchführen und alles berichten. Die letzten zwei Jahrzehnte haben gezeigt, wie weit die Praxis davon entfernt ist. Dieser Abschnitt verbindet ein formales Modell der Glaubwürdigkeit signifikanter Befunde mit der empirischen Evidenz bis 2026 und mit der Variante der Krise, die das maschinelle Lernen betrifft.

=== Die Replikationskrise in Zahlen

#studie-fest(titel: [Open Science Collaboration 2015])[
  *Design:* 100 Replikationen von Studien aus Artikeln des Jahres 2008 in drei führenden psychologischen Zeitschriften, mit hoher Power und, wo verfügbar, Originalmaterialien @collaboration2015estimating. *Befund:* 97 % der Originalstudien, aber nur 36 % (35 von 97; 95-%-KI 26.6 bis 46.2 %) der Replikationen waren signifikant. Die mittlere Effektstärke sank von $r = 0.403$ auf $r = 0.197$. 47 % der Originaleffekte lagen im 95-%-Intervall der Replikation, 39 % galten im subjektiven Urteil der Teams als repliziert, 68 % waren in der metaanalytischen Kombination von Original und Replikation signifikant @collaboration2015estimating. Sozialpsychologie replizierte zu 25 % (14 von 55), kognitive Psychologie zu 50 % (21 von 42). Originale mit $p < 0.02$ replizierten zu 41 %, mit $0.02 < p < 0.04$ zu 26 % und mit $p > 0.04$ zu 18 %; Haupteffekte zu 47 %, Interaktionseffekte zu 22 % @collaboration2015estimating. *Grenzen (der Autoren):* Eine gescheiterte Replikation beweist nicht, dass das Original falsch positiv war; Methode, Stichprobe oder Setting können sich unterscheiden, und eine direkte Replikation prüft vor allem die Reliabilität eines Ergebnisses, nicht die Theorie dahinter @collaboration2015estimating.
]

Mit @k01-eq-rd lassen sich die mittleren Effektstärken der OSC-Studie übersetzen: $r = 0.403$ entspricht $d approx 0.88$, $r = 0.197$ entspricht $d approx 0.40$. Ein im Original "großer" Effekt schrumpft in der Replikation auf einen "kleinen bis mittleren". Die Korrelation zwischen der Power der Replikation und ihrem Erfolg betrug $r = 0.368$ @collaboration2015estimating[Tab. 2].

=== Ein formales Modell: der positive Vorhersagewert

Warum sind signifikante Befunde so oft nicht replizierbar? Ioannidis hat dafür 2005 ein einfaches Modell vorgelegt, das sich direkt aus dem Satz von Bayes ergibt @ioannidis2005why.

#definition(titel: [Positiver Vorhersagewert (PPV)])[
  Sei $R$ das Verhältnis wahrer zu nicht vorhandener Zusammenhänge unter den in einem Feld getesteten (Prä-Studien-Odds), $1 - beta$ die Power und $alpha$ das Signifikanzniveau. Der *positive Vorhersagewert* ist die Wahrscheinlichkeit, dass ein als signifikant berichteter Befund wahr ist @ioannidis2005why:
  $ "PPV" = ((1 - beta) R) / (R - beta R + alpha). $ <k01-eq-ppv>
]

#beweis-fest[
  Sei $pi$ der Anteil wahrer Hypothesen unter den getesteten, also $R = pi slash (1 - pi)$. Ein signifikantes Ergebnis entsteht entweder aus einer wahren Hypothese (Wahrscheinlichkeit $pi (1 - beta)$) oder als Fehler 1. Art aus einer falschen (Wahrscheinlichkeit $(1 - pi) alpha$). Nach Bayes ist
  $ "PPV" = (pi (1 - beta)) / (pi (1 - beta) + (1 - pi) alpha). $
  Division von Zähler und Nenner durch $1 - pi$ ergibt $(1 - beta) R slash ((1 - beta) R + alpha)$, und $(1 - beta) R + alpha = R - beta R + alpha$.
]

Ioannidis erweitert das Modell um einen Bias-Term $u$, den Anteil von Analysen, die nur durch Verzerrung zu "Befunden" werden @ioannidis2005why:
$ "PPV" = ((1 - beta) R + u beta R) / (R + alpha - beta R + u - u alpha + u beta R). $ <k01-eq-ppv-bias>

#beispiel(titel: [PPV für typische Forschungssituationen])[
  Ohne Bias ($u = 0$) und mit $alpha = 0.05$: Bei $R = 1 slash 9$ (jede zehnte getestete Hypothese ist wahr) und Power 0.80 ist $"PPV" = (0.8 dot 1 slash 9) slash (0.8 dot 1 slash 9 + 0.05) approx 0.64$. Bei Power 0.35 sinkt er auf $0.0389 slash (0.0389 + 0.05) approx 0.44$: Weniger als die Hälfte der signifikanten Befunde ist dann wahr. Bei $R = 1$ und Power 0.80 steigt er auf $0.8 slash 0.85 approx 0.94$. Mit Bias tabelliert Ioannidis etwa 0.85 für eine angemessen gepowerte RCT mit wenig Bias ($R = 1$, Power 0.80, $u = 0.10$), 0.23 für eine unterpowerte frühe RCT (Power 0.20, $R = 1 slash 5$, $u = 0.20$), 0.20 für angemessen gepowerte explorative Epidemiologie (Power 0.80, $R = 1 slash 10$, $u = 0.30$) und 0.0010 für entdeckungsorientiertes Massentesten (Power 0.20, $R = 1 slash 1000$, $u = 0.80$) @ioannidis2005why[Tab. 4]. Alle Werte lassen sich mit @k01-eq-ppv-bias nachrechnen.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let sx = 9.0
    let sy = 4.2
    let ppv(p, r) = p * r / (p * r + 0.05)
    line((0, 0), (sx + 0.3, 0), stroke: 0.7pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.5))
    line((0, 0), (0, sy + 0.3), stroke: 0.7pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.5))
    for x in (0, 0.2, 0.4, 0.6, 0.8, 1.0) {
      line((x * sx, 0), (x * sx, -0.08), stroke: 0.5pt)
      content((x * sx, -0.3), text(font: "Inter", size: 7pt, str(x)))
    }
    for y in (0, 0.2, 0.4, 0.6, 0.8, 1.0) {
      line((0, y * sy), (-0.08, y * sy), stroke: 0.5pt)
      content((-0.35, y * sy), text(font: "Inter", size: 7pt, str(y)))
      if y > 0 { line((0, y * sy), (sx, y * sy), stroke: 0.3pt + luma(225)) }
    }
    for (r, col, lab) in ((1.0, c-green, [$R = 1$]), (0.25, c-blue, [$R = 1 slash 4$]), (1 / 9, c-accent, [$R = 1 slash 9$]), (1 / 50, c-red, [$R = 1 slash 50$])) {
      let pts = range(1, 101).map(i => { let p = i / 100; (p * sx, ppv(p, r) * sy) })
      line(..pts, stroke: 1.1pt + col)
      content((sx + 0.1, ppv(1, r) * sy), anchor: "west", text(font: "Inter", size: 7pt, fill: col, lab))
    }
    for (p, v) in ((0.8, 0.64), (0.35, 0.4375)) {
      circle((p * sx, v * sy), radius: 0.08, fill: c-dark, stroke: none)
      content((p * sx + 0.12, v * sy - 0.22), anchor: "west", text(font: "Inter", size: 6.8pt, [#calc.round(v, digits: 2)]))
    }
    content((0.5 * sx, -0.75), text(font: "Inter", size: 7.5pt, [Power $1 - beta$]))
    content((-1.0, 0.5 * sy), angle: 90deg, text(font: "Inter", size: 7.5pt, [PPV]))
  }),
  caption: [Positiver Vorhersagewert nach @k01-eq-ppv für $alpha = 0.05$ und $u = 0$ in Abhängigkeit von Power und Prä-Studien-Odds $R$. Punkte: die Werte 0.64 und 0.44 aus dem Rechenbeispiel ($R = 1 slash 9$).],
) <k01-fig-ppv>

Ioannidis leitet daraus sechs Korollare ab: Befunde sind seltener wahr, wenn Studien klein sind, wenn Effekte klein sind, wenn mehr Zusammenhänge mit weniger Vorauswahl getestet werden, wenn Designs, Definitionen, Outcomes und Analysen flexibel sind, wenn finanzielle oder andere Interessen größer sind und wenn mehr Teams in einem "heißen" Feld nach Signifikanz jagen @ioannidis2005why. Das dritte und vierte Korollar beschreiben ziemlich genau Hyperparametersuche und Benchmark-Jagd im maschinellen Lernen. Die Grenze des Modells: $R$ und $u$ sind selten bekannt; Replikationsprojekte liefern dagegen beobachtete statt modellierte Raten @tyner2026investigating.

=== Forscherfreiheitsgrade und p-Hacking

#definition(titel: [Forscherfreiheitsgrade])[
  *Forscherfreiheitsgrade* (_researcher degrees of freedom_) sind nicht offengelegte Flexibilitäten bei Datenerhebung, Analyse und Berichterstattung, etwa die Wahl der abhängigen Variablen, der Abbruchregel, der Kovariaten oder weggelassener Bedingungen, die die Falsch-positiv-Rate über das nominelle $alpha$ treiben @simmons2011false.
]

#studie-fest(titel: [Simmons, Nelson und Simonsohn 2011])[
  *Design:* Computersimulation mit 15 000 simulierten Stichproben ohne wahren Effekt sowie zwei reale Experimente @simmons2011false. *Befund:* Die Wahrscheinlichkeit, mindestens ein Ergebnis mit $p < 0.05$ zu erhalten, beträgt 9.5 % bei zwei korrelierten abhängigen Variablen ($r = 0.50$; Situation A), 7.7 % beim Nacherheben von 10 Beobachtungen pro Zelle (B), 11.7 % bei Kontrolle für Geschlecht oder dessen Interaktion (C), 12.6 % beim Weglassen oder Beibehalten einer von drei Bedingungen (D), 14.4 % für A und B, 30.9 % für A bis C und 60.7 % für A bis D @simmons2011false[Tab. 1]. In Studie 2 "zeigten" die Autoren, dass Teilnehmende nach "When I'm Sixty-Four" rund 1.5 Jahre jünger waren als nach einem Kontrollsong (adjustierte Mittel 20.1 vs. 21.5 Jahre, $F(1, 17) = 4.92$, $p = 0.040$, $N = 20$), allein durch nicht offengelegte Flexibilität @simmons2011false. *Konsequenz:* Sechs Anforderungen an Autorinnen (Abbruchregel vorab festlegen und berichten; mindestens 20 Beobachtungen pro Zelle oder eine überzeugende Kostenbegründung; alle erhobenen Variablen nennen; alle Bedingungen berichten; bei Ausschlüssen auch die Ergebnisse mit ihnen berichten; bei Kovariaten auch ohne sie) und vier Richtlinien für Gutachtende @simmons2011false. *Grenzen:* Die simulierten Raten hängen von den angenommenen Korrelationen ab; sie illustrieren den Mechanismus, schätzen aber keine realen Raten.
]

#figure(
  balken((
    ([A: zwei abhängige Variablen], 9.5),
    ([B: 10 Beobachtungen nacherheben], 7.7),
    ([C: Kovariate Geschlecht], 11.7),
    ([D: Bedingung weglassen], 12.6),
    ([A + B], 14.4),
    ([A + B + C], 30.9),
    ([A + B + C + D], 60.7),
  ), max: 65, breite: 8, farbe: c-red, einheit: " %", nachkomma: 1),
  caption: [Falsch-positiv-Raten bei $alpha = 0.05$ unter kombinierten Forscherfreiheitsgraden ohne wahren Effekt, nach @simmons2011false[Tab. 1]. Nominell wären 5 % zu erwarten.],
) <k01-fig-simmons>

=== Der Garten der Gabelungen

Gelman und Loken haben einen subtileren Punkt gemacht: Mehrfachvergleiche sind auch dann ein Problem, wenn niemand bewusst "fischt" und die Forschungshypothese vorab feststand. Weil Analyseentscheidungen von den Daten abhängen, hätte ein anderer Datensatz zu anderen, ebenso "vernünftigen" Entscheidungen geführt @gelman2014statistical. Ein $p$-Wert ist nur dann aussagekräftig, wenn dieselbe Analyse auch auf allen anderen möglichen Datensätzen gelaufen wäre @gelman2014statistical. Ihre Fallbeispiele reichen von Armkraft und politischen Einstellungen über Bems ESP-Studien bis zu "50 shades of gray", wo ein signifikantes Ergebnis in einer größeren präregistrierten Folgestudie mit $p = 0.59$ verschwand @gelman2014statistical.

#satz(titel: [Familienweise Fehlerrate])[
  Kann eine Forscherin unter $H_0$ aus $k$ unabhängigen Tests zum Niveau $alpha$ (Outcomes, Subgruppen, Modellvarianten) jeden signifikanten berichten, so ist die Wahrscheinlichkeit mindestens eines falsch positiven Befunds
  $ "FWER" = 1 - (1 - alpha)^k. $ <k01-eq-fwer>
]

#beweis-fest[
  Unter $H_0$ ist jeder Test mit Wahrscheinlichkeit $1 - alpha$ nicht signifikant. Wegen der Unabhängigkeit ist die Wahrscheinlichkeit, dass keiner der $k$ Tests signifikant ist, das Produkt $(1 - alpha)^k$. Das Gegenereignis "mindestens einer signifikant" hat die Wahrscheinlichkeit $1 - (1 - alpha)^k$.
]

Für $alpha = 0.05$ ergibt @k01-eq-fwer bei $k = 4$ den Wert 0.185, bei $k = 10$ den Wert 0.401 und bei $k = 20$ den Wert 0.642. Unabhängigkeit ist eine Vereinfachung; korrelierte Gabelungen blähen weniger auf. Gelmans und Lokens Pointe ist aber, dass $k$ implizit groß ist, selbst wenn nur ein Test gerechnet wird, weil der gewählte Test von den Daten abhängt @gelman2014statistical. Die klassischen Korrekturen, die das Lehrbuch nennt, sind Bonferroni (Teilen von $alpha$ durch die Zahl der Tests), das weniger konservative sequenzielle Holm-Verfahren, die Kontrolle der False Discovery Rate und Tukeys HSD für Post-hoc-Paarvergleiche @haindl2027research. Sie helfen aber nur bei Vergleichen, die man kennt und zählt, nicht bei den unsichtbaren Gabelungen.

#satz(titel: [Bonferroni-Schranke])[
  Werden $k$ Nullhypothesen jeweils zum Niveau $alpha slash k$ getestet, so ist die Wahrscheinlichkeit, mindestens eine wahre Nullhypothese zu verwerfen, höchstens $alpha$, und zwar ohne jede Annahme über die Abhängigkeit der Tests.
]

#beweis-fest[
  Sei $A_i$ das Ereignis, dass die wahre Nullhypothese $H_(0,i)$ verworfen wird, also $P(A_i) <= alpha slash k$. Nach der Booleschen Ungleichung (Subadditivität des Wahrscheinlichkeitsmaßes) gilt
  $ P(union.big_(i=1)^k A_i) <= sum_(i=1)^k P(A_i) <= k dot alpha / k = alpha. $
  Die Ungleichung gilt für beliebige Abhängigkeiten. Der Preis dafür: Die tatsächliche familienweise Fehlerrate liegt meist unter $alpha$, bei positiv korrelierten Tests deutlich, das Verfahren ist also konservativ.
]

Das sequenzielle Holm-Verfahren nutzt dieselbe Schranke schärfer: Man ordnet die $p$-Werte aufsteigend, $p_((1)) <= dots.h <= p_((k))$, und verwirft schrittweise $H_((i))$, solange $p_((i)) <= alpha slash (k - i + 1)$ gilt; beim ersten Wert, der die Schwelle verfehlt, bricht man ab. Es kontrolliert die familienweise Fehlerrate ebenfalls bei $alpha$, verwirft aber nie weniger Hypothesen als Bonferroni.

#beispiel(titel: [Bonferroni und Holm im Vergleich])[
  Vier Prompt-Varianten werden gegen eine Baseline getestet; die $p$-Werte sind 0.010, 0.015, 0.030 und 0.20, $alpha = 0.05$. *Bonferroni:* Schwelle $0.05 slash 4 = 0.0125$; nur die erste Variante ist signifikant. *Holm:* $0.010 <= 0.05 slash 4 = 0.0125$, verwerfen; $0.015 <= 0.05 slash 3 approx 0.0167$, verwerfen; $0.030 > 0.05 slash 2 = 0.025$, Abbruch. Holm erklärt also zwei Varianten für signifikant. Ohne Korrektur wären es drei, und bei $k = 4$ läge die familienweise Fehlerrate nach @k01-eq-fwer bei 0.185.
]

Für eine Multiversumsanalyse (siehe unten) ist die Zahl der Analysen das Produkt der Optionen: Hat eine Pipeline $m$ Entscheidungspunkte mit je $o_j$ vertretbaren Optionen, so umfasst das Multiversum $product_(j=1)^m o_j$ Analysen. Schon drei Prompt-Formulierungen, zwei Modellversionen, zwei Temperaturen und zwei Parsing-Regeln ergeben $3 dot 2 dot 2 dot 2 = 24$ Varianten, von denen eine einzelne berichtete Zahl nur eine ist.

#datei-fest("forking_paths.py")[
```python
import numpy as np
from scipy import stats
rng = np.random.default_rng(0)

def false_positive_rate(k, n=30, reps=5000):
    """Kein wahrer Effekt, aber k Metriken/Subgruppen zur Auswahl."""
    hits = 0
    for _ in range(reps):
        a = rng.normal(size=(k, n)); b = rng.normal(size=(k, n))
        p = stats.ttest_ind(a, b, axis=1).pvalue
        hits += (p < 0.05).any()
    return hits / reps

for k in (1, 4, 10, 20):
    print(k, false_positive_rate(k), 1 - 0.95**k)
```
]

Die Simulation der Wissensbasis liefert 0.0514, 0.1754, 0.4118 und 0.6254 gegenüber den theoretischen Werten 0.05, 0.185, 0.401 und 0.642 (@k01-fig-fwer); die vektorisierte Variante im Notebook ergibt leicht andere simulierte Werte, weil sie Zufallszahlen in anderer Reihenfolge zieht. Im Notebook folgen Bonferroni-, Holm- und Benjamini-Hochberg-Korrekturen.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let sx = 0.5
    let sy = 5.0
    line((0, 0), (20 * sx + 0.4, 0), stroke: 0.7pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.5))
    line((0, 0), (0, 0.8 * sy + 0.3), stroke: 0.7pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.5))
    for x in (1, 4, 8, 10, 12, 16, 20) {
      line((x * sx, 0), (x * sx, -0.08), stroke: 0.5pt)
      content((x * sx, -0.3), text(font: "Inter", size: 7pt, str(x)))
    }
    for y in (0, 0.2, 0.4, 0.6, 0.8) {
      line((0, y * sy), (-0.08, y * sy), stroke: 0.5pt)
      content((-0.35, y * sy), text(font: "Inter", size: 7pt, str(y)))
      if y > 0 { line((0, y * sy), (20 * sx, y * sy), stroke: 0.3pt + luma(225)) }
    }
    line((0, 0.05 * sy), (20 * sx, 0.05 * sy), stroke: (paint: c-grey, dash: "dashed", thickness: 0.7pt))
    content((20 * sx, 0.05 * sy + 0.2), anchor: "east", text(font: "Inter", size: 6.8pt, fill: c-grey.darken(20%), [nominelles $alpha = 0.05$]))
    let pts = range(1, 21).map(k => (k * sx, (1 - calc.pow(0.95, k)) * sy))
    line(..pts, stroke: 1.2pt + c-blue)
    for (k, v) in ((1, 0.0514), (4, 0.1754), (10, 0.4118), (20, 0.6254)) {
      rect((k * sx - 0.08, v * sy - 0.08), (k * sx + 0.08, v * sy + 0.08), fill: c-accent, stroke: none)
    }
    content((10 * sx - 0.2, 0.401 * sy + 0.35), anchor: "east", text(font: "Inter", size: 6.8pt, fill: c-blue, [Theorie $1 - 0.95^k$]))
    content((11 * sx, 0.22 * sy), anchor: "west", text(font: "Inter", size: 6.8pt, fill: c-accent.darken(10%), [Quadrate: Simulation (5000 Wiederholungen)]))
    content((10 * sx, -0.75), text(font: "Inter", size: 7.5pt, [Anzahl wählbarer Tests $k$]))
    content((-1.0, 0.4 * sy), angle: 90deg, text(font: "Inter", size: 7.5pt, [P(mind. ein $p < 0.05$)]))
  }),
  caption: [Familienweise Fehlerrate nach @k01-eq-fwer und simulierte Werte (Quadrate) aus `forking_paths.py`. Jede wählbare Metrik, jeder Prompt und jede Subgruppe ist eine Gabelung.],
) <k01-fig-fwer>

=== Viele Analysierende, ein Datensatz

#studie-fest(titel: [Silberzahn et al. 2018])[
  *Design:* 29 Teams mit insgesamt 61 Analysierenden prüften mit demselben Datensatz dieselbe Frage: Bekommen Fußballspieler mit dunklerer Hautfarbe häufiger Rote Karten von Schiedsrichtern? @silberzahn2018many *Befund:* Die geschätzten Odds Ratios reichten von 0.89 bis 2.93 (Median 1.31); 20 Teams (69 %) fanden einen signifikant positiven, 9 Teams (31 %) einen nicht signifikanten Effekt; es gab 21 verschiedene Kombinationen von Kovariaten. Die Variation ließ sich weder durch Vorannahmen noch durch Expertise oder die von Peers bewertete Analysequalität erklären @silberzahn2018many. *Grenzen:* ein Datensatz, eine Frage.
]

Die *Multiversumsanalyse* macht aus dieser Einsicht eine Methode: Statt einen Datensatz zu analysieren, analysiert man alle Datensätze, die aus vernünftigen Verarbeitungsentscheidungen entstehen, und berichtet die Verteilung der Ergebnisse @steegen2016increasing. Steegen et al. reanalysierten eine Studie zu Fruchtbarkeit und Religiosität mit fünf Verarbeitungsentscheidungen; von 120 Datensatzvarianten in Studie 1 waren 7, von 210 in Studie 2 waren 88 bei $p < 0.05$ signifikant @steegen2016increasing. Die offensichtliche Grenze: Was "vernünftig" ist, bleibt ein Urteil. Für LLM-Studien ist das Multiversum die natürliche Robustheitsprüfung: ein Gitter über Prompt-Varianten, Modellversionen, Temperaturen, Parsing-Regeln und Seeds (Kapitel 6 und 10).

=== SCORE 2026: Replizierbarkeit, Robustheit und Reproduzierbarkeit

Das SCORE-Programm hat im April 2026 in _Nature_ die bisher breiteste Evidenz zur Glaubwürdigkeit der Sozial- und Verhaltenswissenschaften vorgelegt. Drei Begriffe sind dabei zu trennen: *Replizierbarkeit* fragt, ob eine Behauptung in neuen Daten hält @tyner2026investigating; *analytische Robustheit* fragt, ob sie hält, wenn andere Analysierende dieselben Daten auswerten @aczel2026investigating; *Reproduzierbarkeit* fragt, ob dieselben Daten mit derselben Analyse dasselbe Ergebnis liefern @miske2026investigating.

#studie-fest(titel: [Tyner et al. 2026 (SCORE, Replizierbarkeit)])[
  *Design:* 274 positive Behauptungen aus 164 Artikeln in 54 Zeitschriften (2009 bis 2018), repliziert mit sehr hoher Power (Median 99.6 % für die Originaleffekte), Originalmaterialien und vorab begutachteten Protokollen @tyner2026investigating. *Befund:* 151 von 274 Behauptungen (55.1 %; 95-%-KI 49.2 bis 60.9 %) replizierten mit signifikantem Ergebnis in Originalrichtung, gewichtet nach Artikel 49.3 % (95-%-KI 43.8 bis 54.7 %). Die Raten der Disziplinen lagen zwischen 42.5 % und 63.1 %. Die mediane Effektstärke sank von $r = 0.25$ auf $r = 0.10$, eine Reduktion der geteilten Varianz um 82.4 %. Dreizehn alternative Erfolgskriterien ergaben Raten von 28.6 % bis 74.8 % (Median 49.3 %) @tyner2026investigating. *Grenzen (der Autoren):* Ein Teil des Rückgangs ist durch Regression zur Mitte zu erwarten, weil nur positive Ergebnisse repliziert wurden @tyner2026investigating.
]

Die 82.4 % sind die Angabe der Arbeit; aus den gerundeten Medianen ergäbe sich $1 - (0.10 slash 0.25)^2 = 0.84$. Vermutlich liegen der Angabe ungerundete Mediane zugrunde; in der Lehre sollte man die Zahl als Angabe der Arbeit zitieren und nicht nachrechnen lassen. In $d$ übersetzt nach @k01-eq-rd entspricht der Rückgang etwa $d approx 0.52$ -> $d approx 0.20$.

#studie-fest(titel: [Aczel et al. 2026 (SCORE, Robustheit)])[
  *Design:* geschichtete Zufallsstichprobe von 100 Studien (2009 bis 2018); je eine Behauptung wurde von mindestens fünf unabhängigen Reanalysierenden mit den Originaldaten neu ausgewertet @aczel2026investigating. *Befund:* Nur 34 % der Reanalysen trafen das Originalergebnis innerhalb von $plus.minus 0.05$ Cohens $d$, 57 % innerhalb einer viermal breiteren Toleranz; 74 % kamen zur selben Schlussfolgerung, 24 % zu einem Null- oder unklaren Ergebnis, 2 % zum gegenteiligen Effekt @aczel2026investigating. *Grenzen:* Sozial- und Verhaltenswissenschaften; die Toleranzen sind Konventionen.
]

#studie-fest(titel: [Miske et al. 2026 (SCORE, Reproduzierbarkeit)])[
  *Design:* 600 Artikel aus 62 Zeitschriften (2009 bis 2018) @miske2026investigating. *Befund:* Für 144 Artikel (24.0 %; 95-%-KI 20.8 bis 27.6 %) stellten die Autorinnen Daten bereit, 143 Datensätze wurden geprüft. 53.6 % (95-%-KI 45.8 bis 60.7 %) waren exakt reproduzierbar, 73.5 % (95-%-KI 66.4 bis 80.0 %) exakt oder näherungsweise (innerhalb von 15 % des Originaleffekts oder 0.05 des Original-$p$-Werts). Die Reproduzierbarkeit war in Politikwissenschaft und Ökonomie, bei neueren Artikeln und in Zeitschriften mit Datenpflicht höher @miske2026investigating.
]

#merke[Es gibt keine "Replikationsrate" ohne Kriterium. Dieselben 274 SCORE-Behauptungen ergeben je nach Erfolgskriterium zwischen 28.6 % und 74.8 % @tyner2026investigating. Wer die Replikation eines LLM-Benchmark-Ergebnisses über Modellversionen hinweg plant, muss das Erfolgskriterium vorab festlegen.]

=== Präregistrierung: was sie leistet und was nicht

#definition(titel: [Präregistrierung])[
  *Präregistrierung* heißt, Forschungsfragen und Analyseplan festzulegen, bevor die Ergebnisse beobachtet werden, um Vorhersage (Hypothesentest) von Nachhersage (Hypothesenbildung) zu trennen @nosek2018preregistration.
]

Nosek et al. argumentieren, dass die Verwechslung von Nachhersage und Vorhersage die Glaubwürdigkeit untergräbt, dass gewöhnliche Denkfehler wie der Rückschaufehler sie schwer vermeidbar machen und dass Präregistrierung ein wirksames Gegenmittel ist; sie diskutieren auch Strategien für unvollkommene Situationen, etwa wenn die Daten schon existieren @nosek2018preregistration. Die Autoren behandeln neun praktische Herausforderungen, darunter Änderungen am Vorgehen während der Durchführung, entdeckte Verletzungen von Annahmen, bereits vorhandene Daten, große multivariate Datensätze und Forschungsprogramme mit wenigen A-priori-Erwartungen @nosek2018preregistration.

#studie-fest(titel: [Brodeur et al. 2024])[
  *Design:* 15 992 Teststatistiken aus RCT-Studien in 15 führenden ökonomischen Zeitschriften @brodeur2024preregistration. *Befund:* Präregistrierungen enthalten oft keinen Pre-Analysis-Plan (PAP) oder keinen ausreichend detaillierten; für Präregistrierung allein fand sich kein Hinweis auf weniger p-Hacking oder Publikationsbias, für Präregistrierung mit PAP dagegen schon @brodeur2024preregistration. *Grenzen:* beobachtend, nur ökonomische RCTs.
]

Die Konsequenz ist eine Verschärfung der Empfehlung von 2018: Es zählt der detaillierte Analyseplan, nicht der Zeitstempel. Wo sich Entscheidungen nicht vorab fixieren lassen, sind Multiversumsanalysen @steegen2016increasing oder Many-Analysts-Designs @silberzahn2018many @aczel2026investigating die Ergänzung. Auf der Berichtsseite verlangt JARS-Quant, Hypothesen, Analysen und Schlussfolgerungen als primär, sekundär oder explorativ zu kennzeichnen @appelbaum2018journal; das ist das Berichtsgegenstück zur Präregistrierung.

#praxis[Eine Präregistrierung für ein Prompt-basiertes Klassifikationsexperiment legt mindestens fest: Modell und exakte Version, Prompt im Wortlaut, Temperatur und weitere Parameter, Parsing-Regel für die Ausgabe, Umgang mit unparsebaren Antworten, primäre Metrik und Vergleich, Ausschlussregeln, Zahl der Wiederholungen und das Kriterium für "repliziert". Alles andere wird als explorativ berichtet.]

=== Leakage: die Replikationskrise des maschinellen Lernens

#definition(titel: [Data Leakage])[
  *Leakage* liegt vor, wenn Information über die Testdaten oder das Outcome, die im beabsichtigten Einsatz nicht verfügbar wäre, in Training oder Evaluation eines Modells gelangt. Kapoor und Narayanan unterscheiden acht Typen in drei Klassen @kapoor2023leakage:
  - *L1, keine saubere Trennung von Training und Test:* L1.1 kein Testset, L1.2 Vorverarbeitung auf Training und Test gemeinsam, L1.3 Feature-Selektion auf Training und Test gemeinsam, L1.4 Duplikate;
  - *L2, illegitime Features;*
  - *L3, Testset nicht aus der Verteilung des wissenschaftlichen Interesses:* L3.1 zeitliches Leakage, L3.2 Abhängigkeit zwischen Training und Test, L3.3 Stichprobenverzerrung in der Testverteilung.
]

#studie-fest(titel: [Kapoor und Narayanan 2023])[
  *Design:* Synthese von 22 früheren Reviews zu ML-Fehlern über viele Fächer hinweg und Reproduktion von 12 Arbeiten zur Vorhersage von Bürgerkriegen mit Code und Daten @kapoor2023leakage. *Befund:* Leakage betrifft mindestens 294 Arbeiten in 17 Fächern (eine Untergrenze; die arXiv-Fassung nennt 329 Arbeiten aus 20 Reviews, zitiert werden sollten die publizierten Zahlen). Alle vier Arbeiten, die behaupteten, komplexe ML-Modelle schlügen die logistische Regression, enthielten Leakage; nach der Korrektur waren die komplexen Modelle nicht besser, in einem Fall schrumpfte die AUC-Differenz von 0.14 auf 0.01. 9 der 12 Arbeiten hatten keinen Signifikanztest und keine Unsicherheitsangabe @kapoor2023leakage. *Vorschlag:* "Model Info Sheets", die Argumente für saubere Trennung, legitime Features und ein Testset aus der Zielverteilung verlangen. *Grenzen (der Autoren):* Die Angaben sind ohne rechnerische Reproduzierbarkeit nicht prüfbar, falsche Angaben können Gutachtende in falscher Sicherheit wiegen, und Ausfüllen wie Prüfen erfordern ML-Expertise @kapoor2023leakage.
]

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 8pt,
    align(center)[#text(size: 8pt, weight: "bold", fill: c-red)[Mit Leakage (L1.3)] \
      #diagram(spacing: (4mm, 5mm), edge-stroke: 0.8pt, mark-scale: 70%,
        fknoten((0, 0), [alle 100 Fälle, 5000 Rauschfeatures], col: c-dark, w: 46mm),
        fknoten((0, 1), [Feature-Selektion mit allen Labels (k = 20)], col: c-red, filled: true, w: 46mm),
        fknoten((0, 2), [5-fache Kreuzvalidierung], col: c-grey, w: 46mm),
        fknoten((0, 3), [Genauigkeit $approx 0.85$], col: c-red, w: 46mm),
        edge((0, 0), (0, 1), "-|>"), edge((0, 1), (0, 2), "-|>"), edge((0, 2), (0, 3), "-|>"),
      )],
    align(center)[#text(size: 8pt, weight: "bold", fill: c-green)[Sauber (Pipeline)] \
      #diagram(spacing: (4mm, 5mm), edge-stroke: 0.8pt, mark-scale: 70%,
        fknoten((0, 0), [alle 100 Fälle, 5000 Rauschfeatures], col: c-dark, w: 46mm),
        fknoten((0, 1), [5-fache Kreuzvalidierung], col: c-grey, w: 46mm),
        fknoten((0, 2), [in jedem Fold: Skalierung und Selektion nur auf Trainingsteil], col: c-green, filled: true, w: 46mm),
        fknoten((0, 3), [Genauigkeit $approx 0.48$], col: c-green, w: 46mm),
        edge((0, 0), (0, 1), "-|>"), edge((0, 1), (0, 2), "-|>"), edge((0, 2), (0, 3), "-|>"),
      )],
  ),
  caption: [Leakage-Typ L1.3 auf reinem Rauschen: Dieselben Daten ohne jedes Signal ergeben je nach Position der Feature-Selektion 85 % oder 48 % Genauigkeit (Code aus der Wissensbasis, getestet mit scikit-learn 1.9.1, Stand: 11. November 2026).],
) <k01-fig-leakage>

#datei-fest("leakage_demo.py")[
```python
import numpy as np
from sklearn.feature_selection import SelectKBest, f_classif
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

rng = np.random.default_rng(0)
X = rng.normal(size=(100, 5000)); y = rng.integers(0, 2, 100)   # kein Signal

X_sel = SelectKBest(f_classif, k=20).fit_transform(X, y)        # LEAKY
print(cross_val_score(LogisticRegression(max_iter=1000), X_sel, y, cv=5).mean())

pipe = make_pipeline(StandardScaler(), SelectKBest(f_classif, k=20),
                     LogisticRegression(max_iter=1000))
print(cross_val_score(pipe, X, y, cv=5).mean())                 # SAUBER
```
]

Die Konsensus-Antwort auf Leakage ist die *REFORMS*-Checkliste: 19 Forschende aus Informatik, Datenwissenschaft, Mathematik, Sozial- und Biomedizinwissenschaften haben 32 Items in acht Abschnitten formuliert, nämlich Studiendesign, rechnerische Reproduzierbarkeit, Datenqualität, Vorverarbeitung, Modellierung, Leakage, Metriken und Unsicherheitsquantifizierung sowie Generalisierbarkeit @kapoor2024reforms. REFORMS zielt auf ML, das für wissenschaftliche Behauptungen eingesetzt wird, nicht auf Arbeiten über ML-Methoden selbst @kapoor2024reforms; für eine Data-Science-Masterarbeit ist sie das engste Gegenstück zu JARS und den Empirical Standards.

#hoersaal-fest([Ist Benchmark-Kontamination durch Pretraining-Daten auch Leakage im Sinn von Kapoor und Narayanan?], [In der Rahmung der Wissensbasis ja: Wenn Benchmark-Items in den Pretraining-Daten enthalten sind, fehlt eine saubere Trennung von Training und Test, also Klasse L1 @kapoor2023leakage. Der Unterschied zur klassischen Situation ist, dass Forschende die Trainingsdaten eines proprietären Modells nicht kennen und die Trennung daher nicht selbst herstellen können. Das ist einer der Gründe, warum LLM-Richtlinien verlangen, ein offenes Modell als Vergleichsbasis aufzunehmen @baltes2025guidelines. Kapitel 4 behandelt Kontamination ausführlich.])

#fallstrick[Leakage betrifft auch LLM-Annotationsstudien: Wer Prompt und Few-Shot-Beispiele so lange am selben Goldstandard optimiert, an dem er später die Genauigkeit berichtet, hat Vorverarbeitung und Modellwahl auf den Testdaten durchgeführt (sinngemäß L1.2 und L1.3). Halte einen Teil des Goldstandards bis zur finalen Evaluation zurück.]

== Mixed Methods <k01-mixed>

Viele Fragen der Informatik haben eine messbare und eine interpretative Seite, die keine Methode allein erfasst. Mixed-Methods-Forschung kombiniert quantitative und qualitative Methoden innerhalb einer einzigen Untersuchung, um Einsichten zu gewinnen, die keine der beiden allein liefert @venkatesh2013bridging. Das Schlüsselwort ist *Integration*: Ein Survey und ein paar Interviews in derselben Arbeit sind noch kein Mixed-Methods-Design; erst die durchdachte Verbindung, aus der neue Einsichten entstehen, macht es dazu @haindl2027research. Das Lehrbuch illustriert das mit Open-Source-Projekten: Repository-Daten zeigen, dass erfolgreiche Projekte schneller auf Pull Requests reagieren; erst Interviews erklären, wie Reaktionszeit die Motivation von Beitragenden beeinflusst. Die Statistik liefert das "Was", die qualitative Analyse das "Warum", und die Integration zeigt, wie technische und soziale Faktoren zusammenwirken @haindl2027research.

=== Zwecke und Kerndesigns

Venkatesh, Brown und Bala nennen sieben Zwecke des Mischens: Komplementarität, Vollständigkeit, Entwicklung (eine Methode entwickelt die andere), Erweiterung, Bestätigung, Kompensation (Schwächen einer Methode ausgleichen) und Diversität (gegensätzliche Sichtweisen sichtbar machen) @venkatesh2013bridging[Tab. 1]. Für die Designs hat sich eine Dreiteilung durchgesetzt @fetters2013achieving[Tab. 1] @creswell2025designing (@k01-fig-mmdesigns).

#figure(
  diagram(spacing: (6mm, 7mm), edge-stroke: 0.8pt, mark-scale: 70%,
    node((0.5, -0.7), text(font: "Inter", size: 7.5pt, weight: "bold")[Konvergent]),
    fknoten((0, 0), [QUAN \ Erhebung + Analyse], col: c-blue, w: 24mm),
    fknoten((1, 0), [QUAL \ Erhebung + Analyse], col: c-violet, w: 24mm),
    fknoten((0.5, 1), [Zusammenführen (_merging_)], col: c-accent, filled: true, w: 30mm),
    fknoten((0.5, 2), [Interpretation, Metainferenz], col: c-dark, w: 30mm),
    edge((0, 0), (0.5, 1), "-|>"), edge((1, 0), (0.5, 1), "-|>"), edge((0.5, 1), (0.5, 2), "-|>"),
    node((2, -0.7), text(font: "Inter", size: 7.5pt, weight: "bold")[Erklärend sequenziell]),
    fknoten((2, 0), [QUAN \ Erhebung + Analyse], col: c-blue, filled: true, w: 32mm),
    fknoten((2, 1), [Fälle auswählen (_connecting_), Fragen ableiten (_building_)], col: c-accent, w: 32mm),
    fknoten((2, 2), [QUAL erklärt die Befunde], col: c-violet, w: 32mm),
    edge((2, 0), (2, 1), "-|>"), edge((2, 1), (2, 2), "-|>"),
    node((3, -0.7), text(font: "Inter", size: 7.5pt, weight: "bold")[Explorativ sequenziell]),
    fknoten((3, 0), [QUAL \ Exploration], col: c-violet, filled: true, w: 32mm),
    fknoten((3, 1), [Instrument oder Intervention entwickeln (_building_)], col: c-accent, w: 32mm),
    fknoten((3, 2), [QUAN testet in der Breite], col: c-blue, w: 32mm),
    edge((3, 0), (3, 1), "-|>"), edge((3, 1), (3, 2), "-|>"),
  ),
  caption: [Die drei Kerndesigns der Mixed-Methods-Forschung nach @fetters2013achieving und @creswell2025designing; Darstellung angelehnt an @haindl2027research. Großbuchstaben kennzeichnen die Stränge; gefüllte Knoten markieren bei den sequenziellen Designs den Startstrang, beim konvergenten Design den Integrationspunkt.],
) <k01-fig-mmdesigns>

Im *konvergenten* Design werden beide Stränge im selben Zeitraum erhoben und analysiert und dann zusammengeführt. Das Lehrbuch nennt eine Studie zu Burnout bei Entwickelnden: Ein Survey liefert die Breite, Interviews die Tiefe; integriert wird durch den Vergleich, ob die Interviewthemen zu den Survey-Faktoren passen @haindl2027research. Im *erklärend sequenziellen* Design kommt zuerst der quantitative Strang, und der qualitative erklärt unerwartete Korrelationen, Ausreißer oder rätselhafte Muster. Im *explorativ sequenziellen* Design kommt zuerst die qualitative Exploration, aus der Variablen, Instrumente oder Interventionen für den quantitativen Strang entstehen; es passt zu neuen Phänomenen, für die es noch keine tragfähigen Theorien und Messinstrumente gibt @haindl2027research.

Auf diesen Kerndesigns bauen komplexere Rahmen auf: mehrstufige, Interventions-, Fallstudien- und partizipative Designs @fetters2013achieving. Die vierte Auflage von Creswell und Plano Clark (Dezember 2025) beschreibt sieben Designs, drei Kerndesigns und vier hybride, betont stärker die Metainferenzen und trennt Analyse und Integration in zwei Kapitel mit neuen Joint-Display-Vorlagen @creswell2025designing. Bibliothekskataloge verzeichnen das Werk teils mit dem Impressum 2027 (Stand: 11. November 2026).

=== Integration auf drei Ebenen

Fetters, Curry und Creswell beschreiben Integration auf der Design-, der Methoden- und der Interpretationsebene @fetters2013achieving. Auf der Methodenebene unterscheiden sie *Verbinden* (_connecting_, über die Stichprobenziehung), *Aufbauen* (_building_, ein Strang formt die Datenerhebung des anderen), *Zusammenführen* (_merging_, beide Datensätze gemeinsam analysieren) und *Einbetten* (_embedding_, Verknüpfung an mehreren Punkten, typisch bei Interventionen) @fetters2013achieving[Tab. 2]. Auf der Interpretations- und Berichtsebene stehen narrative Integration (verwoben, nebeneinander oder gestaffelt), Datentransformation und *Joint Displays* @fetters2013achieving. Bei der Datentransformation werden qualitative Themen *quantifiziert* (gezählt oder in ihrer Intensität bewertet) oder quantitative Cluster *qualifiziert* (über Beispielfälle reich beschrieben) @haindl2027research.

#definition(titel: [Metainferenz und Passung der Integration])[
  Eine *Metainferenz* ist eine theoretische Aussage, Erzählung oder Geschichte, die aus der Integration der Befunde beider Stränge erschlossen wird @venkatesh2013bridging. Die *Passung der Integration* (_fit of integration_) ist entweder *Bestätigung* (beide Stränge stützen sich), *Erweiterung* (sie ergänzen sich) oder *Diskordanz* (sie widersprechen sich); bei Diskordanz empfehlen Fetters et al., nach Verzerrungen zu suchen, mehr Daten zu erheben, neu zu analysieren oder Theorie heranzuziehen @fetters2013achieving.
]

Venkatesh et al. beschreiben für widersprüchliche Befunde zwei Strategien: *Bracketing*, das die Widersprüche als Spannweite stehen lässt und zu konkurrenten Designs passt, und *Bridging*, das Konsens herstellt und zu sequenziellen Designs passt @venkatesh2013bridging. Das Lehrbuch betont, dass Divergenz zwischen Methoden oft aufschlussreicher ist als Konvergenz: Bei Pair Programming mögen Experimente geringere Produktivität, Surveys höhere Zufriedenheit, Interviews besseres Lernen und Beobachtungen bessere Codequalität zeigen, und gerade das macht die Vielschichtigkeit der Praxis sichtbar @haindl2027research.

=== Joint Displays

Ein Joint Display stellt quantitative und qualitative Befunde so nebeneinander, dass die Integration selbst sichtbar und prüfbar wird. Dyers, Bello und Guetterman kritisieren, dass viele Mixed-Methods-Studien bei paralleler Berichterstattung stehen bleiben, und empfehlen, Joint Displays als analytische Werkzeuge zu bauen, die Divergenz und Unsicherheit zeigen statt eine erzwungene Übereinstimmung; dazu gehören Integrationsfragen schon in der Fragestellung ("wie und in welchem Ausmaß"), eine Integrations-Planungsmatrix als lebendes Dokument, früh geplante Quantifizierung, Integrations-Checkpoints, Gleichberechtigung der Stränge und ein Audit Trail mit Memos und Versionskontrolle; bewertet wird Integration nach Kohärenz, Transparenz und Produktivität, dem "1+1=3"-Test @dyers2025separate.

#figure(
  table(columns: (1.2fr, 1.5fr, 1.6fr, auto),
    [Quantitativer Befund (Fehlertyp)], [Qualitatives Thema aus Interviews], [Metainferenz], [Passung],
    [Recall bei Studien mit nicht-englischem Abstract deutlich niedriger], [Reviewer misstrauen Vorschlägen bei fremdsprachigen Texten und prüfen diese ohnehin manuell], [Schwäche ist real, wird in der Praxis aber kompensiert; Werkzeug spart dort keine Zeit], [Bestätigung],
    [Präzision bei Methodenpapieren hoch], [Reviewer berichten, gerade diese Vorschläge seien "offensichtlich" und brächten wenig], [Hohe Präzision bei leichten Fällen erklärt geringen wahrgenommenen Nutzen], [Erweiterung],
    [Gesamtrecall 0.95 erfüllt Zielwert], [Reviewer fühlen sich unsicher, ob übersehene Studien relevant waren], [Metrik deckt das Vertrauensproblem nicht ab; Bedarf an Erklärungen], [Diskordanz],
  ),
  caption: [Joint Display für das Screening-Beispiel aus dem Abschnitt zur Designwahl (konvergentes Design). Alle Inhalte sind konstruierte Lehrbeispiele, keine empirischen Befunde; die Struktur folgt @fetters2013achieving, die Passungskategorien ebenfalls.],
) <k01-tab-joint>

=== Inferenzqualität und Berichtsstandards

Für die Qualität von Mixed-Methods-Studien haben Venkatesh et al. einen eigenen Rahmen entwickelt: *Inferenzqualität* mit den Dimensionen *Designqualität* (Eignung, Adäquatheit und analytische Adäquatheit des Designs) und *Erklärungsqualität* für quantitative, qualitative und integrative Inferenzen, wobei Letztere integrative Wirksamkeit, Übertragbarkeit der Inferenzen und integrative Korrespondenz umfassen @venkatesh2013bridging[Tab. 6]. Neun Richtlinien behandeln Angemessenheit, Designstrategie, Analysestrategie, Metainferenzen und die Validierung @venkatesh2013bridging[Tab. 5]. Mixed Methods waren in den Informationssystemen damals selten: Die Einleitung nennt weniger als 5 % der empirischen Studien in den Basket-Zeitschriften (2001 bis 2007), die Review-Sektion zählt 31 Arbeiten oder etwa 3 %; der Aufsatz gleicht die beiden Angaben nicht ab @venkatesh2013bridging.

Das Lehrbuch ergänzt Legitimationskriterien für die Integration: ob die Stichproben beider Stränge sinnvoll zusammenhängen, ob Innen- und Außenperspektive ausgewogen sind, ob die Mischung die Schwächen der Einzelmethoden tatsächlich ausgleicht, ob die Phasen logisch aufeinander aufbauen, ob Datentransformationen angemessen sind und ob paradigmatische Spannungen adressiert werden @haindl2027research. Metainferenzen werden systematisch entwickelt: Inferenzen beider Stränge auflisten, Konvergenz, Komplementarität und Divergenz identifizieren, integrierte Interpretationen entwickeln und diese gegen beide Stränge prüfen @haindl2027research.

Für die Berichterstattung verlangt der APA-Standard MMARS unter anderem getrennte qualitative, quantitative und Mixed-Methods-Ziele, die Benennung und Definition des Designs, eine Begründung für den Mehrwert der Integration, getrennte Analyseabschnitte, eine Erklärung, wie integriert wurde (Joint Displays, Datentransformation, Diskussion), und eine Reihenfolge der Befunde gemäß der Designsequenz @levitt2018journal[Tab. 3].

#hoersaal-fest([Ist eine Arbeit, die ein Modell benchmarkt und danach drei Leute fragt, wie sie es finden, schon Mixed Methods?], [Formal enthält sie beide Datenarten, methodisch meist nicht. Entscheidend ist, ob es Integrationspunkte gibt: Wurden die Interviewpartner aufgrund der quantitativen Befunde ausgewählt (_connecting_)? Fragen die Interviews gezielt nach den Fehlerclustern des Benchmarks (_building_)? Werden beide Befundlagen in einem Joint Display gegenübergestellt und daraus eine Metainferenz abgeleitet? Ohne solche Punkte ist es parallele Berichterstattung, die Dyers et al. als typisches Defizit beschreiben @dyers2025separate @fetters2013achieving. MMARS liefert die Checkliste, an der man das prüfen kann @levitt2018journal.])

== Gütekriterien und Validitätstypen <k01-guete>

Gütekriterien sind kein Pflichtabschnitt am Ende des Methodenkapitels, sondern der Maßstab, an dem jede Designentscheidung gemessen wird. Das Lehrbuch formuliert ihren praktischen Zweck als einheitlich: Sie sollen erlauben, die Gültigkeit der eigenen Schlüsse zu begründen und ehrlich abzugrenzen, was die Studie nicht behaupten kann @haindl2027research.

=== Die Typologie nach Shadish, Cook und Campbell

Die vier Validitätstypen von Shadish, Cook und Campbell strukturieren die Kapitel 2 und 3 ihres Standardwerks und sind das Vokabular, das Softwaretechnik und Informationssysteme übernommen haben @shadish2002experimental (@k01-tab-scc).

#figure(
  table(columns: (auto, 1.2fr, 1.4fr),
    [Validitätstyp], [Frage], [Typische Bedrohungen],
    [Statistische Schlussvalidität], [Ist die Kovariation von Behandlung und Ergebnis real und korrekt geschätzt?], [geringe Power, verletzte Testannahmen, Fishing und Mehrfachtests, unreliable Messungen],
    [Interne Validität], [Ist die Kovariation in dieser Studie kausal?], [unklare zeitliche Abfolge, Selektion, History, Reifung, Regression zur Mitte, Ausfall (Mortalität), Testeffekte, Instrumentierung],
    [Konstruktvalidität], [Repräsentieren die Operationalisierungen die gemeinten Konstrukte?], [unzureichende Explikation der Konstrukte, Mono-Operation-Bias, Reaktivität, Erwartungen der Versuchsleitung],
    [Externe Validität], [Gilt die Kausalbeziehung über Personen, Settings, Behandlungen und Outcomes hinweg?], [Wechselwirkung der Kausalbeziehung mit Einheiten, Settings und Behandlungsvarianten],
  ),
  caption: [Die vier Validitätstypen nach @shadish2002experimental. Die Bedrohungen der internen Validität folgen der Darstellung in @haindl2027research; die Wissensbasis konnte die Bezeichnungen jenseits der ersten fünf nicht am Originaltext prüfen.],
) <k01-tab-scc>

Das Lehrbuch erläutert die Bedrohungen der internen Validität mit Beispielen aus der Informatik: *History*, wenn ein Systemupdate während eines langen Experiments die Performance unabhängig von der Manipulation verbessert; *Reifung*, wenn Programmierende im Lauf einer mehrwöchigen Studie besser werden; *Testeffekte*, wenn ein Vortest den Nachtest beeinflusst; *Instrumentierung*, wenn sich die Messung ändert, etwa durch Profiling-Overhead; *Selektion* in Quasi-Experimenten; *Mortalität*, also ungleicher Ausfall zwischen den Bedingungen @haindl2027research. Für die statistische Schlussvalidität empfiehlt es Power-Analysen, geprüfte und berichtete Annahmen, vorab festgelegte Analysen und reliable Messungen @haindl2027research. In der Softwaretechnik adaptieren Runeson und Höst die Typologie zu Konstruktvalidität, interner Validität, externer Validität und Reliabilität, wobei externe Validität auf analytischer statt statistischer Generalisierung beruht @runeson2009guidelines[Abschn. 5.2.3].

Die Übersetzung in computergestützte Studien ist direkt, aber nicht trivial. "History" wird zur stillen Aktualisierung eines Modells durch den Anbieter während der Datenerhebung, "Instrumentierung" zu einer Änderung von Prompt oder Tokenizer @shadish2002experimental. @k01-tab-llm-threats zeigt eine Zuordnung, die als Übung im Foliensatz 01 verwendet wird.

#figure(
  table(columns: (auto, 1.3fr, 1.3fr),
    [Validitätstyp], [Beispielbedrohung in einer DS-/LLM-Studie], [Mögliche Gegenmaßnahme],
    [Statistische Schlussvalidität], [ein Lauf pro Konfiguration, kein Konfidenzintervall, viele Metriken], [wiederholte Läufe und Seeds, Intervalle, präregistrierte primäre Metrik @nosek2018preregistration],
    [Interne Validität], [Anbieter aktualisiert das Modell während der Datenerhebung (History)], [Modellversion fixieren, Zeitstempel protokollieren],
    [Konstruktvalidität], [Benchmarkgenauigkeit wird als "Reasoning-Fähigkeit" ausgegeben], [Konstrukt explizieren, mehrere Operationalisierungen],
    [Externe Validität], [Ergebnisse auf einem englischen Datensatz werden auf alle Sprachen übertragen], [Population der Texte und Aufgaben benennen, replizieren],
    [Reliabilität (SE)], [undokumentierte Prompts und Vorverarbeitung], [Prompts und Code veröffentlichen, Audit Trail],
  ),
  caption: [Validitätsbedrohungen in LLM-Studien. Die Einträge der Spalten 2 und 3 sind Lehrbeispiele der Wissensbasis, keine Befunde der zitierten Werke; die Typologie folgt @shadish2002experimental und @runeson2009guidelines.],
) <k01-tab-llm-threats>

=== Messqualität und Vertrauenswürdigkeit im Vergleich

Neben der Validität kausaler Schlüsse steht die Qualität der Messung. Für Instrumente verlangt das Lehrbuch Inhalts-, konvergente und diskriminante Validität, eine geprüfte Faktorstruktur und Reliabilität, etwa Cronbachs $alpha > 0.70$ pro Konstrukt; bei Gruppenvergleichen zudem Messinvarianz @haindl2027research. Für ein LLM, das als Messinstrument eingesetzt wird, sind das genau die Fragen, die Kapitel 4 und 6 stellen: Misst die Ausgabe, was sie messen soll? Ist sie über Wiederholungen stabil? Verhält sie sich über Gruppen gleich?

Für qualitative Forschung gelten die Kriterien der Vertrauenswürdigkeit nach Lincoln und Guba @lincoln1985naturalistic, für Mixed Methods die Inferenzqualität nach Venkatesh et al. @venkatesh2013bridging. @k01-tab-kriterien stellt die drei Welten nebeneinander.

#figure(
  table(columns: (1fr, 1fr, 1fr),
    [Quantitativ @shadish2002experimental], [Qualitativ @lincoln1985naturalistic], [Mixed Methods @venkatesh2013bridging],
    [Interne Validität], [Glaubwürdigkeit], [Designqualität: Eignung, Adäquatheit],
    [Externe Validität], [Übertragbarkeit], [Übertragbarkeit der Inferenzen],
    [Reliabilität], [Verlässlichkeit], [analytische Adäquatheit],
    [Objektivität], [Bestätigbarkeit], [integrative Wirksamkeit und Korrespondenz],
    [Statistische Schlussvalidität], [(kein direktes Pendant)], [Erklärungsqualität der quantitativen Inferenzen],
  ),
  caption: [Gütekriterien der drei Methodenfamilien. Die Zeilen der ersten beiden Spalten sind die von Lincoln und Guba vorgeschlagenen Parallelen; die dritte Spalte ordnet die Dimensionen von Venkatesh et al. nur sinngemäß zu.],
) <k01-tab-kriterien>

=== Berichtsstandards

Berichtsstandards übersetzen Gütekriterien in prüfbare Anforderungen. JARS-Quant, die Revision der APA-Standards von 2008, verlangt die Gruppierung von Hypothesen, Analysen und Schlüssen in primär, sekundär und explorativ, ergänzt Module für Beobachtungsstudien, klinische Studien, Längsschnitt-, Replikations- und N-of-1-Studien sowie Standards für Strukturgleichungsmodelle und bayesianische Analysen @appelbaum2018journal. ML-spezifische Punkte wie Datensplits und Leakage fehlen dort; dafür ist REFORMS da @kapoor2024reforms. JARS-Qual und MMARS decken qualitative und gemischte Forschung ab; sie beschreiben, was zu berichten ist, nicht wie Studien zu entwerfen sind @levitt2018journal.

In der Softwaretechnik haben sich die ACM SIGSOFT Empirical Standards etabliert: natürlichsprachliche Beschreibungen dessen, was die Community von jedem Studientyp erwartet, gegliedert in *essenzielle* (für die Publikation notwendig, sofern keine starke Begründung vorliegt), *wünschenswerte* und *außergewöhnliche* Eigenschaften, gepflegt als lebende Dokumente @ralph2020empirical. Die Website bietet 19 Standards, darunter Experiment, Data Science, Grounded Theory, Replikation, Systematic Review, Case Study und Engineering Research; ein LLM-spezifischer Standard war auf den geprüften Seiten nicht gelistet (Stand: 11. November 2026) @ralph2020empirical. Für Arbeiten, die GitHub, Issue-Tracker oder Modell-Hubs minen, gibt es einen eigenen Repository-Mining-Standard, dessen essenzielle Eigenschaften unter anderem die Begründung der Datenquellen, Auswahlkriterien und die Beschreibung der Extraktion umfassen @chatterjee2022empirical.

=== Limitationen als Ledger

Das Lehrbuch formuliert einen Gedanken, der den ganzen Abschnitt zusammenfasst: Gütekriterien und Limitationen sind zwei Seiten derselben Münze. Jede Bedrohung, die eine Studie nicht vollständig neutralisieren kann, wird zu einer Limitation, die zu benennen ist; jede Qualitätsstrategie ist Evidenz dafür, dass eine Bedrohung kontrolliert wurde. Ein Limitationsabschnitt ist deshalb kein Anhängsel und keine Entschuldigung, sondern ein Kontobuch darüber, welche Kriterien voll, teilweise oder gar nicht erfüllt wurden und wie weit die Behauptungen folglich reichen @haindl2027research (@k01-fig-ledger).

#figure(
  diagram(spacing: (8mm, 6mm), edge-stroke: 0.8pt, mark-scale: 70%,
    fknoten((0, 0), [Kandidatenmethode], col: c-dark, filled: true, w: 36mm),
    fknoten((0, 1), [Kann das Projekt die Kerngütekriterien der Methode erfüllen?], col: c-yellow, w: 44mm),
    fknoten((-1, 2), [tragfähig: Qualitätsstrategien und Evidenz von Anfang an planen], col: c-green, w: 44mm),
    fknoten((1, 2), [überdenken: Design anpassen oder Methode wechseln, Behauptungen begrenzen], col: c-red, w: 44mm),
    fknoten((0, 3), [verbleibende Bedrohungen -> explizite Limitationen], col: c-blue, filled: true, w: 64mm),
    edge((0, 0), (0, 1), "-|>"),
    edge((0, 1), (-1, 2), "-|>", [ja], label-side: right),
    edge((0, 1), (1, 2), "-|>", [nein], label-side: left),
    edge((-1, 2), (0, 3), "-|>"), edge((1, 2), (0, 3), "-|>"),
  ),
  caption: [Methodenwahl nach erfüllbaren Gütekriterien und Überführung der Restbedrohungen in explizite Limitationen, nach @haindl2027research.],
) <k01-fig-ledger>

#tipp[Baue den Limitationsabschnitt einer Arbeit als Tabelle mit drei Spalten: Gütekriterium, Status (erfüllt, teilweise, nicht erfüllt) und Konsequenz für die Reichweite der Behauptungen. Wenn eine Proxy-Metrik für ein reicheres Konstrukt steht, etwa Fehleranzahl für "Codequalität", gehört diese Lücke ausdrücklich in die Tabelle @haindl2027research.]

== Wo LLMs in jede Methode eingreifen <k01-llm>

Die bisherigen Abschnitte haben die Methoden so dargestellt, wie sie vor dem Einzug generativer Modelle formuliert wurden. Dieser Abschnitt schlägt die Brücke zu den Kapiteln 4 bis 7. Der Grundgedanke ist einfach: LLMs dringen inzwischen in jede Methodenfamilie ein, als Codierer in der Thematischen Analyse (Kapitel 5), als synthetische Befragte in Surveys (Kapitel 4), als Messinstrumente, deren Ausgaben in statistische Tests fließen (Kapitel 6), und als Bewertende in Evaluationen (Kapitel 7). Jede dieser Verwendungen erbt die Validitätsfragen der Gastmethode; dieses Kapitel liefert das Vokabular, um sie zu stellen.

#figure(
  diagram(spacing: (3mm, 8mm), edge-stroke: 0.8pt, mark-scale: 70%,
    fknoten((1.5, 0), [LLM im Forschungsprozess], col: c-dark, filled: true, w: 50mm),
    fknoten((0, 1), [Qualitativ: Codierer, Themenvorschläge], col: c-violet, w: 36mm),
    fknoten((1, 1), [Survey: synthetische Befragte], col: c-teal, w: 36mm),
    fknoten((2, 1), [Experiment: Messinstrument, Labels als Daten], col: c-blue, w: 36mm),
    fknoten((3, 1), [Evaluation: Bewertender (Judge)], col: c-accent, w: 36mm),
    fknoten((0, 2), [Vertrauenswürdigkeit, Paradigma der TA (Kap. 5)], col: c-violet, filled: true, w: 36mm),
    fknoten((1, 2), [Konstrukt- und externe Validität (Kap. 4)], col: c-teal, filled: true, w: 36mm),
    fknoten((2, 2), [statistische Schlussvalidität, Messfehler (Kap. 6)], col: c-blue, filled: true, w: 36mm),
    fknoten((3, 2), [Reliabilität, Bias, Validierung (Kap. 7)], col: c-accent, filled: true, w: 36mm),
    edge((1.5, 0), (0, 1), "-|>"), edge((1.5, 0), (1, 1), "-|>"), edge((1.5, 0), (2, 1), "-|>"), edge((1.5, 0), (3, 1), "-|>"),
    edge((0, 1), (0, 2), "-|>"), edge((1, 1), (1, 2), "-|>"), edge((2, 1), (2, 2), "-|>"), edge((3, 1), (3, 2), "-|>"),
  ),
  caption: [Eintrittspunkte von LLMs in die Methodenfamilien und die jeweils geerbte Validitätsfrage; die unteren Knoten verweisen auf die Kapitel, die sie behandeln.],
) <k01-fig-llm>

=== Eine Taxonomie der LLM-Studien

Baltes et al. haben in einer Gemeinschaftsarbeit von 22 Autorinnen und Autoren Richtlinien für empirische Softwaretechnik-Studien mit LLMs vorgelegt, die die Reproduzierbarkeitsprobleme solcher Studien adressieren: Nichtdeterminismus, intransparente Trainingsdaten und schneller Modellwandel @baltes2025guidelines. Sie unterscheiden sieben Studientypen: LLMs als Annotatoren, als Bewertende (Judges), zur Synthese und als Untersuchungssubjekte; die Untersuchung der LLM-Nutzung; LLMs für neue Werkzeuge; und das Benchmarking von LLMs @baltes2025guidelines. Acht Richtlinien, jeweils als Anforderung ("must") oder Empfehlung ("should") markiert, lauten: LLM-Nutzung und Rolle deklarieren; Modellversionen, Konfigurationen und Anpassungen berichten; System- und Prompt-Design dokumentieren; Sitzungsprotokolle berichten; geeignete Baselines, Benchmarks und Metriken verwenden; ein offenes LLM als Baseline aufnehmen; LLM-Ausgaben gegen menschliches Urteil validieren; Limitationen und Gegenmaßnahmen benennen @baltes2025guidelines. Die Arbeit ist ein lebendes Preprint (arXiv-Version 8 vom 18. September 2026, nicht begutachtet); zitiert werden sollte die verwendete Version (Stand: 11. November 2026).

Die sieben Studientypen passen auffallend gut auf die Struktur dieses Buchs: Annotatoren auf Kapitel 5, Judges auf Kapitel 7, Subjekte und synthetische Befragte auf Kapitel 4, Benchmarking auf Kapitel 4 und 6. @k01-tab-llm-methoden ordnet die Eintrittspunkte den Methoden dieses Kapitels zu.

#figure(
  table(columns: (auto, 1.2fr, 1.4fr, auto),
    [Methode], [Rolle des LLM], [Geerbte Validitätsfrage], [Kapitel],
    [Thematische Analyse], [Codieren, Themen vorschlagen], [Passt das zur TA-Variante? Ist Übereinstimmung ein sinnvolles Maß? Wie sieht das Audit Trail aus? @braun2021one], [5],
    [Interview, Fallstudie], [Transkribieren, Zusammenfassen], [Bleibt die Beweiskette zu den Rohdaten erhalten? @haindl2027research], [5, 10],
    [Survey], [synthetische Befragte], [Repräsentiert die Ausgabe die Population (Konstrukt- und externe Validität)? @shadish2002experimental], [4],
    [Experiment, Benchmark], [Messinstrument, Labelquelle], [Messfehler, Power, Forking Paths über Prompts und Versionen @gelman2014statistical], [4, 6],
    [Evaluation], [Bewertender], [Reliabilität und Bias des Bewertenden, Validierung gegen Menschen @baltes2025guidelines], [7],
    [ML-basierte Wissenschaft], [Feature-Erzeugung, Klassifikation], [Leakage, insbesondere Kontamination @kapoor2023leakage], [4, 6],
  ),
  caption: [Eintrittspunkte von LLMs in die Methoden dieses Kapitels und die Validitätsfragen, die sie erben.],
) <k01-tab-llm-methoden>

=== Die Debatte um GenAI in der reflexiven qualitativen Forschung

Nirgends prallen die Paradigmen so direkt aufeinander wie bei der Frage, ob generative KI in der qualitativen Analyse eingesetzt werden darf.

#studie-fest(titel: [Jowsey et al. 2025])[
  *Art:* Positionspapier von 419 erfahrenen qualitativen Forschenden aus 32 Ländern, unter den Autorinnen Braun und Clarke; online seit 17. Dezember 2025 @jowsey2025reject. *Position:* Reflexive Ansätze wie die reflexive TA sind menschliche Praktiken, die eine subjektive, positionierte, reflexive Forscherin voraussetzen; der Einsatz generativer KI sei deshalb "not methodologically congruent". Zusätzlich wird GenAI aus Gründen sozialer und ökologischer Gerechtigkeit abgelehnt @jowsey2025reject.
]

Eine direkte Erwiderung argumentiert, dass die als methodologisch präsentierten Einwände vor allem auf philosophischen Annahmen beruhen, die zum Dogma erstarren könnten, und dass ein pauschales Verbot Debatte und Innovation behindere @depaoli2026why. Auf der empirischen Seite steht eine Studie aus der Softwaretechnik.

#studie-fest(titel: [Martinez Montes et al. 2025])[
  *Design:* reproduzierbare Prompts für LLM-Unterstützung in den Phasen 2 bis 5 der reflexiven TA; 15 Interviews über das Wohlbefinden von Softwareentwicklerinnen und -entwicklern; vier Expertinnen und Experten bewerteten LLM- und menschliche Codes und Themen verblindet mit Rubriken nach Braun und Clarkes Qualitätskriterien @martinezmontes2025large. *Befund:* Die Bewertenden bevorzugten LLM-generierte Codes in 61 % der Fälle; die LLMs fragmentierten aber Daten, verfehlten latente Interpretationen und erzeugten teils Themen mit unklaren Grenzen @martinezmontes2025large. *Grenzen:* kleine Stichprobe, Preprint.
]

Die Auflösung für die Lehre folgt aus dem Paradigma, nicht aus der Technik: In der Codierreliabilitäts- oder Codebuch-TA kann ein LLM als zusätzlicher Codierer evaluiert werden, und Übereinstimmungsmaße sind dann legitim; in der reflexiven TA ist die Subjektivität der Forschenden die analytische Ressource, und ein Vergleich "LLM gegen Mensch" braucht Qualitätsrubriken statt Übereinstimmungskoeffizienten @braun2021one @braun2019reflecting @martinezmontes2025large. Die SE-Richtlinien verlangen statt eines Verbots, LLM-Nutzung zu deklarieren und Ausgaben gegen menschliches Urteil zu validieren @baltes2025guidelines.

#hoersaal-fest([Sollte eine Masterarbeit mit reflexiver TA überhaupt ein LLM verwenden dürfen?], [Beide Seiten lassen sich sauber begründen. Dagegen spricht, dass die reflexive TA ihre Qualität aus der positionierten Interpretation der Forschenden bezieht und 419 Fachleute einen GenAI-Einsatz für inkongruent halten @jowsey2025reject. Dafür spricht, dass die Einwände teils philosophisch statt methodisch sind @depaoli2026why und dass Fachleute in einer verblindeten Studie LLM-Codes oft bevorzugten @martinezmontes2025large. Meine Antwort für Betreuungen: Wenn ein LLM eingesetzt wird, dann deklariert, mit dokumentierten Prompts und Ausgaben, nicht als Ersatz für die Interpretation, und die Arbeit muss die Debatte selbst reflektieren. Wer das nicht leisten kann, wählt besser eine Codebuch-TA oder verzichtet auf das LLM.])

=== Forking Paths und Replikation in LLM-Pipelines

Drei offene Probleme der LLM-gestützten Forschung lassen sich direkt aus diesem Kapitel ableiten. Erstens sind Prompt-Formulierung, Modellversion, Temperatur, Parsing und Metrikwahl Gabelungen im Sinn von Gelman und Loken @gelman2014statistical; Multiversumsanalysen @steegen2016increasing und detaillierte Analysepläne @brodeur2024preregistration sind die Gegenmittel (Kapitel 3 und 6). Zweitens ist Kontamination durch Pretraining-Daten eine Form fehlender Trennung von Training und Test @kapoor2023leakage (Kapitel 4). Drittens überträgt sich die Mehrkriterien-Logik von SCORE @tyner2026investigating auf die Frage, ob ein Ergebnis mit Modellversion A auch mit Version B hält: Auch hier gibt es keine Replikationsrate ohne vorab festgelegtes Kriterium.

#hoersaal-fest([Eine Replikation mit einer neueren Modellversion scheitert. War das Original also falsch positiv?], [Nicht notwendigerweise. Die OSC betont, dass eine gescheiterte Replikation das Original nicht widerlegt, weil Methode, Stichprobe oder Setting abweichen können @collaboration2015estimating. Für LLMs gibt es mindestens drei weitere Erklärungen: Die neue Version ist faktisch ein anderes Instrument (eine Instrumentierungsänderung im Sinn von @k01-tab-scc); das Original war bei festem Prompt nur eine von vielen Gabelungen und ist durch Selektion überschätzt; und Regression zur Mitte ist zu erwarten, wenn man nur positive Ergebnisse nachprüft, wie SCORE ausdrücklich anmerkt @tyner2026investigating. Man prüft das am besten mit einem vorab festgelegten Erfolgskriterium und mehreren Versionen statt einer.])

== Debatten und offene Fragen <k01-debatten>

Ein souveräner Umgang mit Methodenfragen verlangt, die großen Kontroversen nicht als gelöst darzustellen. Vier davon prägen dieses Kapitel.

*Inkommensurabilität oder Pragmatismus.* Eine Position hält Paradigmen für teilweise unvereinbar: Lincoln und Guba ersetzen Validität und Reliabilität durch Vertrauenswürdigkeit @lincoln1985naturalistic, und Braun und Clarke halten Reliabilitätsmaße für reflexive TA für unlogisch @braun2021one. Die Gegenposition stellt die Forschungsfrage an erste Stelle und kombiniert Methoden für Komplementarität, Vollständigkeit und Bestätigung @venkatesh2013bridging; Creswell und Plano Clark bieten mit dem kritischen Realismus eine Grundlage an, die eine reale Welt annimmt und doch fehlbares, theoriegeladenes Wissen anerkennt @creswell2025designing. Praktische Konsequenz: Das Paradigma muss benannt werden, und die Gütekriterien müssen dazu passen @braun2021one @levitt2018journal.

*Zahl oder Urteil bei der Sättigung.* Die empirische Bandbreite von 9 bis 17 Interviews @hennink2022sample steht gegen die Position, dass Stichprobengröße in reflexiver Forschung ein situiertes Urteil ist @braun2021saturate, mit Buckleys Berichtsschritten als Mittelweg @buckley2022ten. Ein neueres systematisches Review zur Sättigung als Hennink und Kaiser 2022 wurde in der Wissensbasis nicht gefunden; diese Aussage ist nur so gut wie die Suche dahinter.

*Signifikanztests.* Die ASA-Prinzipien wenden sich gegen schwellenbasiertes Denken, schreiben aber keinen Ersatz vor @wasserstein2016asa. Dass Originale mit $p > 0.04$ nur zu 18 % replizierten, solche mit $p < 0.02$ zu 41 % @collaboration2015estimating, passt zur Sicht, dass knapp signifikante Ergebnisse schwache Evidenz sind. Das modellierte Bild nach Ioannidis @ioannidis2005why und die beobachteten Raten von SCORE @tyner2026investigating zeigen in dieselbe Richtung, sind aber verschiedene Arten von Evidenz, und die beobachtete Rate hängt stark vom Kriterium ab.

*Präregistrierung.* Sie trennt konfirmatorische von explorativer Analyse und wirkt dem Rückschaufehler entgegen @nosek2018preregistration. Aber eine vorab formulierte Hypothese kann immer noch datenabhängig getestet werden, wenn die Analyse nicht festgelegt ist @gelman2014statistical, für bereits existierende Daten, den Normalfall der Datenwissenschaft, braucht es besondere Strategien @nosek2018preregistration, und empirisch wirkt Präregistrierung nur mit detailliertem Analyseplan @brodeur2024preregistration.

#hoersaal-fest([Wenn selbst Replikationen nur zur Hälfte gelingen, warum sollte ich dann überhaupt noch einem einzelnen Paper glauben?], [Weil "glauben" die falsche Kategorie ist. Ein einzelnes Paper ist ein Datenpunkt mit einer bestimmten Glaubwürdigkeit, die man anhand der Kriterien dieses Kapitels einschätzen kann: Wie groß war die Power, wie flexibel die Analyse, war sie präregistriert, liegen Daten und Code vor, ist der Effekt im Verhältnis zur Unsicherheit groß? SCORE zeigt zugleich, dass 74 % der Reanalysen zur selben Schlussfolgerung kamen @aczel2026investigating und dass die Reproduzierbarkeit in Zeitschriften mit Datenpflicht höher war @miske2026investigating. Die richtige Reaktion ist kalibriertes Vertrauen und die Bereitschaft, die eigenen Studien so zu bauen, dass andere sie prüfen können.])

#vertiefung[
  *Einstieg:* Gelman und Loken @gelman2014statistical ist kurz, gut lesbar und eignet sich als Vorbereitungslektüre statt des längeren Manuskripts von 2013 @gelman2013garden. *Quantitativ:* Cohens Power Primer @cohen1992power auf fünf Seiten, dann Lakens zu Effektstärken @lakens2013calculating und zur Begründung von Stichprobengrößen @lakens2022sample. *Glaubwürdigkeit:* Ioannidis @ioannidis2005why und Simmons et al. @simmons2011false als Klassiker, die drei SCORE-Arbeiten @tyner2026investigating @aczel2026investigating @miske2026investigating als aktueller Stand. *Qualitativ:* Braun und Clarke 2021 @braun2021one mit der Tabelle der zwanzig Fragen als Gutachten-Rubrik, dazu Hennink und Kaiser @hennink2022sample und als Gegenstimme Braun und Clarke zur Sättigung @braun2021saturate. *Mixed Methods:* Fetters et al. @fetters2013achieving als Kernreferenz zur Integration, Venkatesh et al. @venkatesh2013bridging für die Nähe zu den Informationssystemen. *Data Science:* Kapoor und Narayanan @kapoor2023leakage und die REFORMS-Checkliste @kapoor2024reforms. *Lehrbuch:* Kapitel 1 bis 4 und 6 von @haindl2027research decken die Begriffe, Designs, Gütekriterien und Statistik dieses Kapitels im Zusammenhang ab.
]

== Für die Lehre <k01-lehre>

Dieses Kapitel entspricht Foliensatz 01 der LV ELEC1-GAIRI mit acht Abschnitten (Einführung, Paradigmen und Designs, qualitative Forschung, quantitative Forschung, statistische Strenge und Replikation, Mixed Methods, Gütekriterien, Eintrittspunkte von LLMs) und dem Notebook `notebooks/01_power_and_leakage.ipynb`. Der Foliensatz ist laut seinem Review vollständig mit Wissensbasis und Lehrbuch abgeglichen; offen sind zwei Abschnittsbilder, die noch Platzhalter sind.

*Zeitbedarf.* Für den Stoff sind realistisch zwei Einheiten zu je drei Stunden anzusetzen, wenn die Übungen im Unterricht stattfinden. Die Wissensbasis schlägt folgende Bausteine vor: Power-Analyse von Hand und in Python (30 Minuten), Zuordnung der Validitätsbedrohungen an einem LLM-Paper nach Wahl (45 Minuten), Forking-Paths-Simulation als Demo (20 Minuten), Sättigungskurve aus codierten Interviews mit permutierter Reihenfolge und Kurvenanpassung (45 Minuten), strukturierte Debatte "12 Interviews reichen" (30 Minuten), Joint Display für eine Mixed-Methods-Evaluation eines Screening-Werkzeugs (60 Minuten), Leakage-Audit mit REFORMS (60 Minuten) und als Hausübung ein Review mit dem Checklistengenerator der Empirical Standards.

*Typische Missverständnisse.* Erstens halten Studierende "qualitativ" für eine Methodologie oder ein Paradigma; die Hierarchie aus @k01-fig-hierarchie räumt das in fünf Minuten auf. Zweitens lesen sie den $p$-Wert als Wahrscheinlichkeit der Nullhypothese; hier hilft es, die Bayes-Herleitung des PPV direkt danebenzustellen, weil sie zeigt, dass die Wahrscheinlichkeit einer Hypothese nach einem signifikanten Ergebnis von der Prä-Studien-Wahrscheinlichkeit abhängt, die im $p$-Wert gar nicht vorkommt. Drittens verwechseln sie Effektstärke und Signifikanz; @k01-eq-dt ist das Gegenmittel. Viertens berichten sie bei gepaarten Modellvergleichen $d_z$ und argumentieren mit Cohens Schwellen. Fünftens halten sie Kappa zwischen LLM und Mensch für ein universelles Gütemaß, unabhängig von der TA-Variante. Sechstens glauben sie, Präregistrierung sei bei Data-Science-Projekten mit vorhandenen Daten unmöglich oder sinnlos; die Beispielpräregistrierung eines Prompt-Experiments zeigt das Gegenteil.

*Didaktische Reihenfolge.* Bewährt hat sich, die Krise vor der Statistik zu erzählen: Wer zuerst die Simmons-Balken (@k01-fig-simmons) und die Leakage-Demo sieht, versteht anschließend, wozu Power-Analyse und Präregistrierung gut sind. Die Leakage-Demo auf reinem Rauschen (85 % gegen 48 %) ist der wirksamste Einzelmoment des Foliensatzes, weil sie eine Erwartung der Studierenden direkt bricht.

*Diskussionsfragen.* Welches Paradigma liegt einem Kaggle-Benchmark-Vergleich zugrunde, und was blendet es aus? Ist Inter-Rater-Reliabilität zwischen einem LLM und einem menschlichen Codierer in der reflexiven TA sinnvoll? Welches ASA-Prinzip verletzt eine Leaderboard-Tabelle mit fettem "bestem" Wert am häufigsten? Wie sähe ein Audit Trail für eine Studie aus, in der GPT-artige Modelle Interviews codiert haben? Welches der dreizehn SCORE-Kriterien würdest du für die Replikation eines LLM-Benchmark-Ergebnisses präregistrieren?

#fallstrick[In der Lehre zu diesem Kapitel ist die Versuchung groß, die Replikationskrise als Versagen "der Psychologie" zu erzählen. Das verfehlt die Pointe für eine Data-Science-Zielgruppe. Leakage in mindestens 294 ML-Arbeiten @kapoor2023leakage und das Verschwinden des Vorteils komplexer Modelle nach der Korrektur zeigen, dass das eigene Fach mindestens ebenso betroffen ist.]

#selbsttest(
  [Ordne die folgenden Begriffe der Ebene der Forschungshierarchie zu und begründe kurz: Pragmatismus, Fallstudie, Interviews, Interviewleitfaden, Prompt für eine automatische Codierung. Warum ist "qualitative Methodologie" eine unglückliche Formulierung?],
  [Eine Masterarbeit kündigt eine reflexive Thematische Analyse an und berichtet im Ergebnisteil Cohens Kappa von 0.82 zwischen der Autorin und einem GPT-artigen Modell als Qualitätsnachweis. Begründe aus paradigmatischer Sicht, was daran problematisch ist, und schlage zwei Alternativen vor.],
  [Leite mit dem exponentiellen Sättigungsmodell $C(n) = C_max (1 - e^(-lambda n))$ aus den Beobachtungen $C(5) = 40$ und $C(10) = 55$ die Parameter $lambda$ und $C_max$ her und berechne, nach wie vielen Interviews 90 % Sättigung erreicht werden. Nenne zwei Gründe, warum dieser Wert nicht als Stoppregel taugt.],
  [Berechne Cohens $d$ mit gepoolter Standardabweichung für Gruppe A = {10, 12, 14} und Gruppe B = {8, 9, 10}. Berechne daraus mit $t = d sqrt(n_1 n_2 slash (n_1 + n_2))$ die $t$-Statistik.],
  [Zeige mit der Normalapproximation, wie viele Einheiten pro Gruppe für $d = 0.3$, $alpha = 0.05$ (zweiseitig) und Power 0.90 nötig sind. Um welchen Faktor ändert sich $n$, wenn sich der angenommene Effekt halbiert?],
  [Zwei Prompts werden auf denselben 50 Testitems verglichen; der gepaarte $t$-Test ergibt $t = 3.5$. Berechne $d_z$ und erkläre, warum ein Vergleich dieses Werts mit Cohens Schwelle 0.8 irreführend sein kann.],
  [Ein Feld testet Hypothesen mit Prä-Studien-Odds $R = 1 slash 4$ bei einer typischen Power von 0.5 und $alpha = 0.05$. Berechne den PPV ohne Bias. Wie ändert er sich, wenn die Power auf 0.9 steigt?],
  [Eine Analystin kann zwischen sechs Metriken und zwei Subgruppen frei wählen und berichtet jede signifikante Kombination. Wie groß ist die familienweise Fehlerrate unter $H_0$ bei Unabhängigkeit? Welches $alpha$ pro Test bräuchte man nach Bonferroni?],
  [Klassifiziere die folgenden Fälle nach den Leakage-Typen von Kapoor und Narayanan: (a) Standardisierung auf dem gesamten Datensatz vor dem Split; (b) zufälliger Split von Zeitreihendaten zur Vorhersage künftiger Ereignisse; (c) Patientendaten mit mehreren Aufnahmen pro Person, zufällig auf Training und Test verteilt; (d) ein Feature, das erst nach dem vorherzusagenden Ereignis bekannt ist.],
  [Entwirf für die Frage "Warum nutzen Data-Science-Teams LLM-Codeassistenten unterschiedlich intensiv, und wie verbreitet sind die Gründe?" ein Mixed-Methods-Design. Benenne Design, Integrationspunkte auf Methodenebene, eine Zeile eines Joint Displays und das mögliche Ergebnis "Diskordanz".],
  [Ordne für ein LLM-as-a-Judge-Experiment, in dem ein Anbieter-Modell zwei Chatbots bewertet, je eine Bedrohung der statistischen Schluss-, der internen, der Konstrukt- und der externen Validität zu und nenne je eine Gegenmaßnahme.],
  [SCORE berichtet je nach Kriterium Replikationsraten zwischen 28.6 % und 74.8 %. Erkläre, warum das kein Widerspruch ist, und warum die beobachtete Schrumpfung der Effektstärken von $r = 0.25$ auf $r = 0.10$ nicht allein als Beleg für falsche Originalbefunde gelesen werden darf.],
)

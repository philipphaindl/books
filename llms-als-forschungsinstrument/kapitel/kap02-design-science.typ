#import "../lib.typ": *
#show figure: set text(hyphenate: false)

= Design Science Research und generative KI <k02>

Viele Masterarbeiten in Data Science bauen etwas: eine Pipeline, ein Modell, ein Evaluationswerkzeug, ein RAG-System, einen Codierassistenten. Die Frage, die bei der Begutachtung früher oder später kommt, lautet: Ist das Forschung oder Entwicklung? Design Science Research (DSR) ist das Paradigma, das diese Frage systematisch beantwortet. Es behandelt das Bauen *und* Evaluieren eines Artefakts als Forschung, sofern das Artefakt ein relevantes Problem adressiert, rigoros evaluiert wird und einen überprüfbaren Beitrag liefert @hevner2004design[Tab. 1, S. 83]. Für ein Buch über LLMs als Forschungsinstrument ist DSR aus zwei Gründen zentral. Erstens sind LLM-basierte Systeme eine neue Klasse von Artefakten, deren Zusammensetzung, Kontextualisierung und innere Konsistenz schwer zu spezifizieren sind und deren präskriptives Wissen mit jedem Modellwechsel erodiert @zurheiden2026design. Zweitens kann generative KI die DSR-Arbeit selbst unterstützen, von der Wissenssuche über das Formulieren von Designprinzipien bis zum Prototyping und zur Evaluation @gau2025aibased @blohm2025nextgeneration[Tab. 1].

Dieses Kapitel baut DSR von Grund auf auf: die Richtlinien von Hevner et al., die drei Zyklen, die Artefakttypen, den Prozess nach Peffers et al., das Positionieren eines Wissensbeitrags, Designtheorien und Designprinzipien, Evaluationsstrategien und Action Design Research. Danach wechselt der Blick auf generative KI in beiden Rollen, als Artefakt und als Werkzeug, und auf die Frage, wie man ein stochastisches Artefakt überhaupt misst. Ein durchgehendes Fallbeispiel, ein LLM-gestützter Codierassistent, zieht sich durch alle Abschnitte und wird am Ende zu einem vollständigen DSR-Plan zusammengesetzt. Die Inhalte entsprechen Foliensatz 02 der LV und der Übung 02; zum Foliensatz gibt es kein eigenes Notebook, die Rechenbeispiele in diesem Kapitel ersetzen es.

#lernziele[
  Design Science von verhaltenswissenschaftlicher Forschung abgrenzen und einen Forschungsoutput einem der vier Artefakttypen nach Hevner et al. zuordnen.
][
  Eine Studie auf die sechs DSRM-Aktivitäten nach Peffers et al. abbilden, ihren Einstiegspunkt bestimmen und sie im Relevanz-, Design- und Rigorzyklus verorten.
][
  Einen Beitrag im Knowledge Contribution Framework (Invention, Improvement, Exaptation, Routine Design) und auf einer Abstraktionsebene positionieren und die Wahl begründen.
][
  Designprinzipien nach dem Schema von Gregor, Chandra Kruse und Seidel und technologische Regeln der Form "Um E in S zu erreichen, wende I an" formulieren.
][
  Mit FEDS eine Evaluationsstrategie für ein LLM-basiertes Artefakt entwerfen und begründen.
][
  Strukturelle Metriken (Precision, Recall, $F_1$, Jaccard) und Stabilitätsmaße über Paraphrasen und Läufe berechnen, die Varianzzerlegung herleiten und die Grenzen des Stability Index erklären.
][
  Für jede DSRM-Aktivität einschätzen, wo generative KI unterstützen kann und welche Validitätsbedrohungen dabei entstehen.
]

== Warum Design Science für LLM-gestützte Forschung zählt <k02-warum>

=== Forschung, die etwas baut

Die Informatik untersucht nicht nur bestehende Systeme, sie erschafft neue. Das Lehrbuch formuliert den Unterschied zwischen Routinedesign und Design Science in Analogie zu Programmieren und Informatikforschung: Eine weitere Webanwendung nach etablierten Mustern zu bauen ist Design; ein neues Framework zu schaffen, das eine ganze Klasse bisher unmöglicher Anwendungen erlaubt, ist Design Science. Einen bekannten Algorithmus zu implementieren ist Programmieren; einen neuen Algorithmus mit nachgewiesenen Eigenschaften zu entwickeln ist Design Science Research. Das entscheidende Kriterium ist die Erzeugung neuen Wissens durch den Designprozess @haindl2027research[Kap. 2]. Als Beispiel nennt das Lehrbuch MapReduce: Der Beitrag lag nicht nur im System, sondern in der Abstraktion, im Programmiermodell und im Nachweis, dass sich komplexe verteilte Verarbeitung auf zwei Operationen reduzieren lässt @haindl2027research[Kap. 2].

Für ein LLM-Projekt übersetzt sich das unmittelbar. Ein Chatbot, der eine kommerzielle LLM-API mit einem Standard-RAG-Muster auf ein gut verstandenes Problem anwendet, liegt nahe am Routinedesign. Ein Projekt, das zeigt, unter welchen Bedingungen ein bestimmter Mechanismus (etwa Quellenbelege pro Antwortsatz) zu angemessenem Vertrauen in LLM-Antworten führt, erzeugt dagegen übertragbares Designwissen. @k02-beitrag macht diese Unterscheidung präzise.

=== Software Engineering betreibt längst Design Science

Engström et al. haben 38 Arbeiten untersucht, die zwischen 2014 und 2018 auf der ICSE mit dem ACM SIGSOFT Distinguished Paper Award ausgezeichnet wurden. Die meisten ließen sich als Design Science rahmen, aber keine einzige verwendete den Begriff, und keine formulierte ihre technologische Regel in verdichteter Form @engstrom2020software[Abschn. 1, 5.3, 9]. Software-Engineering-Forschung folgt also der Logik von Design Science, ohne sie zu benennen, und verschenkt damit die Chance, ihren Beitrag auf der Ebene übertragbarer Regeln zu argumentieren. @k02-se vertieft diese Studie.

=== Was DSR-Arbeiten einflussreich macht

Dass die Artikulation eines Wissensbeitrags kein akademisches Ritual ist, zeigt eine Metastudie von Wagner, Prester und Schryen.

#studie(titel: [Wagner, Prester und Schryen 2021])[
  *Design.* Bibliometrische Analyse von 115 DSR-Arbeiten aus der Wirtschaftsinformatik (2004-2014) im AIS Senior Scholars' Basket; Zitationszahlen modelliert mit einem negativ-binomialen verallgemeinerten linearen Modell @wagner2021exploring[Abschn. 4-5].

  *Befund.* Die Zitationen reichten von 2 bis 339 (Mittel 53.3); rund 60 % der Arbeiten hatten weniger als 30 Zitationen; fünf Journals publizierten über 90 % der Arbeiten @wagner2021exploring[Abschn. 4.1]. Theoretisierung und Neuheitstyp erklärten den Zitationserfolg signifikant über Journal-Impact-Factor und h-Index der Autorinnen und Autoren hinaus; das Nagelkerke-$R^2$ stieg von 0.38 (nur Kontrollvariablen) auf 0.45 (plus Neuheit) und 0.55 (plus Theoretisierung) @wagner2021exploring[Tab. 3]. Eine durchschnittliche DSR-Arbeit mit rund 60 Referenzen teilte nur etwa drei davon (4.8 %) mit anderen DSR-Arbeiten, was auf eine schwach kumulative Wissensbasis hindeutet @wagner2021exploring[Abschn. 6.2].

  *Grenzen.* Zitationen sind nur ein Proxy für Wirkung, das Design ist beobachtend, und der Zeitraum liegt vor der GenAI-Ära.
]

Die praktische Konsequenz für Abschlussarbeiten: Ein Data-Science-Artefakt ohne formuliertes Designprinzip und ohne positionierten Wissensbeitrag bleibt "nur ein Werkzeug". @k02-beitrag rechnet die Koeffizienten dieser Studie nach.

=== Drei Rollen generativer KI in DSR

Generative KI tritt in DSR in drei Rollen auf @zurheiden2026design @gau2025aibased: als *Gegenstand* (das Artefakt enthält ein LLM), als *Werkzeug* (das LLM unterstützt Aktivitäten des Forschungsprozesses) und als *Quelle methodischer Risiken* (Nichtdeterminismus, Kontamination, Erosion des Designwissens). Führende Journals der Wirtschaftsinformatik haben darauf mit expliziten Editorials reagiert: Information Systems Research identifiziert sechs Hürden für die Publikation von KI-Designforschung und illustriert sie an LLMs @abbasi2024pathways; das Journal of Information Technology nennt generative KI den "elephant in the room" der Forschungsmethoden der nächsten Generation @blohm2025nextgeneration; Business & Information Systems Engineering diskutiert generative KI für konzeptuelle Modellierung und das Fehlen einer einzigen Ground Truth bei der Evaluation @fill2026generative[Abschn. 1].

#merke[
  DSR ist der Rahmen, in dem du ein LLM-basiertes Artefakt baust und zugleich begründen musst, *wie* du es evaluierst, *welche* Metriken du verwendest und *wie* du Reproduzierbarkeit sicherstellst. Die späteren Kapitel dieses Buchs (Annotation, valide Inferenz, LLM-as-a-Judge, RAG-Qualität) liefern die Messinstrumente; dieses Kapitel liefert die Forschungslogik, in die sie eingebettet werden.
]

=== Das durchgehende Fallbeispiel: der Codierassistent KoDa <k02-fall-intro>

Damit die Begriffe nicht abstrakt bleiben, begleitet dich ein konstruiertes Fallbeispiel durch das Kapitel. Es ist bewusst nah an typischen Masterarbeiten gewählt; alle Zahlen im Fallbeispiel sind *fiktiv* und dienen nur der Illustration der Rechenwege.

#praxis[
  *Ausgangslage.* Eine Forschungsgruppe führt eine Befragung unter Sicherheitsverantwortlichen in KMU durch. Neben geschlossenen Items gibt es offene Fragen ("Beschreiben Sie den letzten Sicherheitsvorfall und wie Sie reagiert haben"). Pro Erhebungswelle fallen rund 2000 Freitextantworten an, die deduktiv mit einem Codebuch (etwa zwölf Codes wie _Phishing_, _Ransomware_, _Fehlkonfiguration_, _Meldung an Behörde_) codiert werden sollen. Zwei Codierende brauchen dafür mehrere Wochen.

  *Artefakt.* *KoDa* (Kodier-Assistent) ist ein LLM-gestütztes Werkzeug. Es zerlegt Antworten in Segmente, schlägt pro Segment einen Code mit Begründung und wörtlicher Belegstelle vor und markiert unsichere Vorschläge. Die Codiererin bestätigt, korrigiert oder verwirft. Optional schlägt KoDa auf Basis einer Stichprobe Ergänzungen zum Codebuch vor.

  *Forschungsfrage (vorläufig).* Wie muss ein LLM-gestützter Codierassistent gestaltet sein, damit er die Codierzeit senkt, ohne die Übereinstimmung mit einem Goldstandard und die kritische Prüfung durch die Codierenden zu verschlechtern?
]

In jedem Hauptabschnitt kommt ein Unterabschnitt "Im Fallbeispiel" vor, der das jeweilige Konzept auf KoDa anwendet. @k02-fall-synthese fasst alles in einem einseitigen Forschungsplan zusammen.

== Grundlagen: Paradigma, Artefakte, Richtlinien, Zyklen <k02-grundlagen>

=== Design Science und Behavioral Science

Hevner et al. stellen in ihrem Grundlagenartikel zwei komplementäre Paradigmen der Wirtschaftsinformatik gegenüber. *Behavioral Science* entwickelt und rechtfertigt Theorien, die Phänomene erklären oder vorhersagen. *Design Science* baut und evaluiert Artefakte, die identifizierte Bedürfnisse erfüllen sollen @hevner2004design[S. 79-81]. Beide sind aufeinander angewiesen: Verhaltenswissenschaftliche Theorien liefern die Begründung, warum ein Design funktionieren sollte, und Artefakte schaffen neue Phänomene, die erklärt werden wollen.

Das Rahmenmodell von Hevner et al. (ihre Abb. 2) verbindet drei Bereiche @hevner2004design[Abb. 2, S. 80]. Die *Umwelt* (_environment_) besteht aus Menschen, Organisationen und Technologie; aus ihr kommen die Bedürfnisse, die *Relevanz* stiften. Die *Wissensbasis* (_knowledge base_) besteht aus Grundlagen und Methodologien; aus ihr kommt das anwendbare Wissen, das *Rigor* stiftet. Dazwischen liegt die Forschung selbst, die Artefakte entwickelt und rechtfertigt bzw. evaluiert. Die Ergebnisse fließen in beide Richtungen zurück: in die Umwelt als Anwendung und in die Wissensbasis als Beitrag.

#definition(titel: [Design Science Research])[
  Design Science Research ist ein Forschungsparadigma, in dem Wissen über ein Problem und seine Lösung durch das Bauen und Evaluieren eines innovativen Artefakts gewonnen wird. Ein DSR-Projekt muss (a) ein relevantes Problem der Umwelt adressieren, (b) ein Artefakt hervorbringen, (c) dieses mit rigorosen Methoden evaluieren und (d) einen klaren, überprüfbaren Beitrag zur Wissensbasis leisten @hevner2004design[Tab. 1, S. 83].
]

Wieringa beschreibt dieselbe Aufteilung aus Sicht von Wirtschaftsinformatik und Software Engineering etwas anders @wieringa2014design. Design Science ist für ihn lösungsorientiert und untersucht *Artefakte im Kontext*. Sie wechselt ständig zwischen zwei Arten von Fragen:

- *Designprobleme* (_design problems_) fragen nach einem Artefakt, das einen Problemkontext verbessert. Sie werden mit dem *Engineering Cycle* gelöst.
- *Wissensfragen* (_knowledge questions_) fragen, wie sich das Artefakt im Kontext verhält. Sie werden mit dem *Empirical Cycle* beantwortet.

Diese Unterscheidung ist für LLM-Projekte äußerst hilfreich. "Wie sollte KoDa unsichere Vorschläge kennzeichnen?" ist ein Designproblem. "Senkt KoDa die Codierzeit bei gleichbleibender Übereinstimmung?" ist eine Wissensfrage. Viele unklare Forschungsfragen in Abschlussarbeiten vermischen beides in einem Satz.

=== Die drei Zyklen

Hevner verdichtet das Rahmenmodell in einem Kommentar zu einem Essay von Iivari zur *Drei-Zyklen-Sicht* @hevner2007three[Abb. 1, S. 88]. Das Lehrbuch übernimmt sie als zentrale Darstellung des DSR-Prozesses @haindl2027research[Kap. 2].

- Der *Relevanzzyklus* (_relevance cycle_) verbindet die Anwendungsumgebung mit den Designaktivitäten. Er liefert Anforderungen und die Akzeptanzkriterien für die Evaluation und bringt Artefakte zum Feldtest in die Umgebung zurück @hevner2007three[S. 89].
- Der *Rigorzyklus* (_rigor cycle_) verbindet die Designaktivitäten mit der Wissensbasis. Er liefert fundierende Theorien und Methoden und bringt neues Wissen zurück: Erweiterungen von Theorien und Methoden, neue Meta-Artefakte und Erfahrungen aus dem Feldtest @hevner2007three[S. 89-90].
- Der *Designzyklus* (_design cycle_) ist die innere Schleife, die zwischen Bauen und Evaluieren von Artefakten und Prozessen iteriert @hevner2007three[S. 90-91].

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let box3(x, titel, body, col) = {
      rect((x - 1.75, -1.25), (x + 1.75, 1.25), radius: 0.12, fill: col.lighten(90%), stroke: 0.9pt + col)
      content((x, 0.9), text(font: "Inter", size: 8pt, weight: "bold", fill: col.darken(20%), titel))
      content((x, -0.15), align(center, text(font: "Inter", size: 7pt, body)))
    }
    box3(-6.1, [Umwelt], [Anwendungsdomäne: \ Menschen, Organisationen, \ technische Systeme, \ Probleme und Chancen], c-teal)
    box3(6.1, [Wissensbasis], [Grundlagen: \ Theorien, Methoden, \ Erfahrung, Expertise, \ Meta-Artefakte], c-blue)
    rect((-1.95, -1.25), (1.95, 1.25), radius: 0.12, fill: c-accent.lighten(92%), stroke: 0.9pt + c-accent)
    content((0, 0.95), text(font: "Inter", size: 8pt, weight: "bold", fill: c-accent.darken(20%))[Design Science Research])
    kasten((0, 0.35), [Artefakte bauen], col: c-accent, w: 2.4, h: 0.45, size: 7pt)
    kasten((0, -0.72), [Artefakte evaluieren], col: c-accent, w: 2.4, h: 0.45, size: 7pt)
    pfeil((-1.5, 0.3), (-1.5, -0.7), color: c-accent)
    pfeil((1.5, -0.7), (1.5, 0.3), color: c-accent)
    content((0, -0.18), text(font: "Inter", size: 6.8pt, weight: "bold", fill: c-accent)[Designzyklus])
    for (x0, x1, col, t1, t2) in ((-4.35, -2.0, c-teal, [Relevanzzyklus], [Anforderungen, \ Feldtest]), (2.0, 4.35, c-blue, [Rigorzyklus], [Fundierung, \ Beiträge])) {
      line((x0, 0), (x1, 0), stroke: 0.9pt + col, mark: (start: "stealth", end: "stealth", fill: col, scale: 0.6))
      content(((x0 + x1) / 2, 0.42), text(font: "Inter", size: 6.8pt, weight: "bold", fill: col.darken(15%), t1))
      content(((x0 + x1) / 2, -0.5), align(center, text(font: "Inter", size: 6.5pt, fill: col.darken(15%), t2)))
    }
  }),
  caption: [Drei-Zyklen-Sicht von DSR nach @hevner2007three[Abb. 1]; Darstellung wie im Lehrbuch @haindl2027research[Kap. 2]. Der Relevanzzyklus liefert Akzeptanzkriterien, der Rigorzyklus fundiert und nimmt Beiträge auf, der Designzyklus iteriert zwischen Bauen und Evaluieren.],
) <k02-abb-zyklen>

Die Drei-Zyklen-Sicht ist kein Schrittmodell; sie sagt nicht, in welcher Reihenfolge du vorgehst und wie du evaluierst @hevner2007three. Ihr Wert liegt in der Diagnose: Eine Arbeit ohne Relevanzzyklus löst ein Problem, das niemand hat; eine Arbeit ohne Rigorzyklus erfindet das Rad neu und kann keinen Beitrag behaupten, weil sie den Stand des Wissens nicht kennt. Bemerkenswert ist, dass Studien der GenAI-Ära die drei Zyklen direkt als Methodengerüst verwenden, etwa eine Action-Design-Science-Studie zu einer LLM-Evaluationsplattform @jin2026developing und die Konstruktion einer Forschungsroadmap für generative KI im Software Engineering @amalfitano2025research.

=== Vier Artefakttypen

Hevner et al. unterscheiden vier Typen von Artefakten @hevner2004design[S. 77-79]. Die Tabelle ergänzt Beispiele aus dem LLM-Umfeld.

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    table.header([Artefakttyp], [Definition (sinngemäß)], [Beispiel mit LLM-Bezug]),
    [Konstrukt (_construct_)], [Vokabular und Symbole, mit denen Probleme und Lösungen beschrieben werden], [eine Taxonomie von Halluzinationstypen],
    [Modell (_model_)], [Repräsentation der Problemsituation und des Lösungsraums mithilfe von Konstrukten], [eine Referenzarchitektur für GenAI-Systeme @grau2025rethinking],
    [Methode (_method_)], [Anleitung zur Problemlösung bzw. Suche im Lösungsraum, von Algorithmen bis zu Best Practices], [ein Co-Creation-Prozess zum Identifizieren von GenAI-Agenten @reinhard2025genaicop],
    [Instanziierung (_instantiation_)], [implementiertes System oder Prototyp, das die Machbarkeit zeigt], [ein RAG-Prototyp mit Erklärungsfunktionen @reinhard2026design],
  ),
  caption: [Artefakttypen nach @hevner2004design[S. 77-79] mit Beispielen aus der GenAI-Literatur (Zuordnung nach dem Dossier zu Foliensatz 02).],
) <k02-tab-artefakte>

Zwei Beobachtungen sind für LLM-Projekte wichtig. Erstens muss ein Artefakt nicht Software sein: Amalfitano et al. behandeln eine Forschungsroadmap als DSR-Artefakt @amalfitano2025research, und der GenAI-CoP-Prozess von Reinhard et al. ist eine Methode *über* generative KI, die selbst kein LLM enthält @reinhard2025genaicop. Zweitens produzieren viele Projekte mehrere Artefakttypen zugleich. KoDa ist eine Instanziierung; die Regeln, nach denen KoDa Unsicherheit anzeigt, sind eine Methode; das Schema, mit dem KoDa Begründung und Belegstelle strukturiert, ist ein Konstrukt. Was du als *Hauptbeitrag* deklarierst, bestimmt, wie du evaluieren musst.

=== Die sieben Richtlinien

Hevner et al. formulieren sieben Richtlinien zum Durchführen und Begutachten von DSR @hevner2004design[Tab. 1, S. 83]. Als Prüfraster für ein Exposé sind sie unschlagbar, solange man sie nicht als mechanische Checkliste missversteht.

#figure(
  table(
    columns: (auto, auto, 1fr),
    table.header([Nr.], [Richtlinie], [Prüffrage für ein LLM-Projekt]),
    [1], [Design als Artefakt], [Entsteht ein tragfähiges Konstrukt, Modell, Methode oder eine Instanziierung, und ist klar, welche Teile (Modell, Prompts, Korpus, Orchestrierung) dazugehören?],
    [2], [Problemrelevanz], [Löst das Artefakt ein wichtiges, technologiebasiertes Problem, das nicht schon trivial gelöst ist?],
    [3], [Designevaluation], [Werden Nutzen, Qualität und Wirksamkeit mit gut ausgeführten Methoden gezeigt, einschließlich Wiederholungsläufen?],
    [4], [Forschungsbeitrag], [Gibt es einen klaren, überprüfbaren Beitrag im Artefakt, in den Designgrundlagen oder in den Methoden?],
    [5], [Forschungsrigor], [Sind Konstruktion und Evaluation methodisch fundiert und dokumentiert (Modellversion, Parameter, Prompts)?],
    [6], [Design als Suchprozess], [Werden verfügbare Mittel genutzt, um das Ziel unter den Gesetzmäßigkeiten der Problemumgebung zu erreichen, und sind Alternativen dokumentiert?],
    [7], [Kommunikation], [Wird das Ergebnis für technik- und managementorientiertes Publikum verständlich dargestellt?],
  ),
  caption: [Die sieben DSR-Richtlinien nach @hevner2004design[Tab. 1, S. 83]; die Prüffragen sind eine eigene Operationalisierung für LLM-Projekte.],
) <k02-tab-richtlinien>

Das Lehrbuch nennt drei Qualitätskriterien, die DSR von bloßer Entwicklung unterscheiden @haindl2027research[Kap. 2]. *Problemrelevanz* heißt nicht Marktnachfrage, sondern Fortschritt der Fähigkeiten eines Feldes; das Lehrbuch nennt die Public-Key-Kryptografie, die das Problem sicherer Kommunikation ohne gemeinsames Geheimnis löste, lange bevor der Internethandel massive praktische Nachfrage erzeugte. *Designrigor* verlangt systematische, in Kerntheorien fundierte Entwicklung: "Herumprobieren, bis es funktioniert" ist keine Forschung; Designentscheidungen müssen mit Anforderungen und theoretischen Grundlagen verknüpft sein. Der *Forschungsbeitrag* schließlich klärt, welches neue Wissen über das Artefakt hinaus entsteht, häufig in Form von Abstraktion und Generalisierung statt in der konkreten Implementierung @haindl2027research[Kap. 2].

#fallstrick[
  Bei LLM-Projekten ist "Herumprobieren, bis es funktioniert" die Standardversuchung: Prompt ändern, Ausgabe ansehen, Prompt ändern. Das ist legitim als *formative* Iteration im Designzyklus, aber nur, wenn die Iterationen protokolliert werden (Prompt-Version, Modellversion, Parameter, beobachtete Wirkung). Ohne Protokoll lässt sich weder der Suchprozess (Richtlinie 6) noch die Rigorbehauptung (Richtlinie 5) belegen.
]

#hoersaal([Ist nicht jede Masterarbeit, die ein Tool baut, automatisch Design Science?], [
  Nein. DSR verlangt neben dem Artefakt ein relevantes Problem, eine rigorose Evaluation und einen überprüfbaren Wissensbeitrag @hevner2004design[Tab. 1]. Ein Tool, das eine bekannte Lösung auf ein bekanntes Problem anwendet, ist Routinedesign, das Gregor und Hevner ausdrücklich nicht als Forschungsbeitrag werten @gregor2013positioning[S. 347]. Eine Arbeit kann trotzdem eine gute Ingenieursleistung sein; sie muss dann aber ehrlich als Entwicklungsprojekt eingeordnet werden oder ihren Beitrag woanders verorten, etwa in einer Evaluation, die neues Wissen über das Verhalten des Artefakts im Kontext erzeugt.
])

=== Im Fallbeispiel

Für KoDa ergibt sich folgende Zuordnung. Die *Umwelt* sind Forschungsgruppen, die große Mengen Freitext deduktiv codieren, mit dem Bedürfnis, Zeit zu sparen, ohne die Qualität der Codierung zu gefährden. Die *Wissensbasis* umfasst Literatur zur qualitativen Inhaltsanalyse und Intercoder-Reliabilität (Kapitel 5), zu LLM-Annotation und zu angemessenem Vertrauen in KI-Vorschläge. Der *Hauptbeitrag* soll kein Prototyp sein, sondern ein Satz von Designprinzipien für Codierassistenten, instanziiert in KoDa. Damit ist bereits klar, dass die Evaluation zwei Dinge zeigen muss: dass KoDa funktioniert, und dass die Wirkung auf die Prinzipien zurückgeht und nicht auf Zufall oder ein besonders starkes Modell.

== Der DSRM-Prozess nach Peffers et al. <k02-dsrm>

=== Sechs Aktivitäten

Hevners Richtlinien sagen, *was* gute DSR auszeichnet, aber nicht, *wie* man sie Schritt für Schritt durchführt. Diese Lücke schließen Peffers et al. mit der *Design Science Research Methodology* (DSRM), einem nominalen Prozessmodell, das aus früheren Prozessbeschreibungen synthetisiert und an vier Fallstudien demonstriert wurde: einem Data Warehouse für Gesundheitsbewertungen, einem Maß für Softwarewiederverwendung, einer SIP-basierten Videotelefonie-Anwendung und einer IS-Planungsmethode @peffers2007design[S. 57 ff.]. Das Modell besteht aus sechs Aktivitäten @peffers2007design[S. 52-56, Abb. 1 S. 54]:

+ *Problemidentifikation und Motivation.* Das konkrete Forschungsproblem definieren und den Wert einer Lösung begründen.
+ *Ziele einer Lösung definieren.* Aus der Problemdefinition und dem Wissen darüber, was möglich und machbar ist, Ziele ableiten.
+ *Design und Entwicklung.* Das Artefakt erschaffen.
+ *Demonstration.* Die Verwendung des Artefakts an einer oder mehreren Instanzen des Problems zeigen.
+ *Evaluation.* Beobachten und messen, wie gut das Artefakt die Lösung unterstützt; Ziele mit beobachteten Ergebnissen vergleichen, etwa über Funktionsprüfungen gegen die Ziele, objektive quantitative Maße, Zufriedenheitsbefragungen, Kundenfeedback, Simulationen oder Leistungsmaße. Danach wird entweder zurück zum Design iteriert oder zur Kommunikation übergegangen.
+ *Kommunikation.* Problem, Artefakt, Nutzen und Neuheit sowie die Rigorosität des Designs kommunizieren.

Die Aktivitäten sind *nominal* sequenziell, aber nicht starr. Peffers et al. betonen, dass Forschende nicht immer bei Aktivität 1 beginnen müssen, und definieren vier *Einstiegspunkte* @peffers2007design[S. 56]. Die Erläuterungen ("typisch, wenn ...") sind eigene Lesehilfen:

- *problemzentriert* (Start bei 1), typisch, wenn ein beobachtetes Problem den Ausgangspunkt bildet;
- *zielzentriert* (Start bei 2), typisch, wenn sich ein Bedarf unmittelbar als Ziel formulieren lässt;
- *design- und entwicklungszentriert* (Start bei 3), typisch, wenn bereits ein Artefakt existiert, das nun rigoros untersucht wird;
- *kunden- bzw. kontextinitiiert* (Start bei 4), typisch, wenn eine in der Praxis beobachtete Lösung den Ausgangspunkt bildet.

#figure(
  {
    set text(font: "Inter", size: 7.5pt)
    diagram(
      spacing: (3.2mm, 9mm),
      node-stroke: 0.8pt,
      fknoten((0, 1), [1 Problem \ identifizieren, \ motivieren], col: c-blue, w: 21mm),
      fknoten((1, 1), [2 Ziele einer \ Lösung \ definieren], col: c-blue, w: 21mm),
      fknoten((2, 1), [3 Design und \ Entwicklung], col: c-accent, filled: true, w: 21mm),
      fknoten((3, 1), [4 Demon- \ stration], col: c-teal, w: 21mm),
      fknoten((4, 1), [5 Evaluation], col: c-teal, filled: true, w: 21mm),
      fknoten((5, 1), [6 Kommuni- \ kation], col: c-violet, w: 21mm),
      edge((0, 1), (1, 1), "-|>"),
      edge((1, 1), (2, 1), "-|>"),
      edge((2, 1), (3, 1), "-|>"),
      edge((3, 1), (4, 1), "-|>"),
      edge((4, 1), (5, 1), "-|>"),
      edge((4, 1), (2, 1), "-|>", bend: 40deg, stroke: (paint: c-accent, dash: "dashed", thickness: 0.8pt), label: text(size: 6.8pt, fill: c-accent)[Prozessiteration], label-side: left),
      node((0, 0), text(size: 6.8pt, fill: c-dark)[problem- \ zentriert], stroke: none),
      node((1, 0), text(size: 6.8pt, fill: c-dark)[ziel- \ zentriert], stroke: none),
      node((2, 0), text(size: 6.8pt, fill: c-dark)[design- \ zentriert], stroke: none),
      node((3, 0), text(size: 6.8pt, fill: c-dark)[kontext- \ initiiert], stroke: none),
      edge((0, 0), (0, 1), "-|>", stroke: 0.8pt + c-grey),
      edge((1, 0), (1, 1), "-|>", stroke: 0.8pt + c-grey),
      edge((2, 0), (2, 1), "-|>", stroke: 0.8pt + c-grey),
      edge((3, 0), (3, 1), "-|>", stroke: 0.8pt + c-grey),
    )
  },
  caption: [DSRM-Prozessmodell nach @peffers2007design[Abb. 1, S. 54] mit den vier Einstiegspunkten (oben). Nach der Evaluation wird entweder zum Design zurückiteriert oder zur Kommunikation übergegangen.],
) <k02-abb-dsrm>

Unter den GenAI-Beispielstudien dieses Kapitels ist die DSRM das am häufigsten verwendete Prozessgerüst; Reinhard et al. strukturieren etwa ihre Studie zu erklärbaren GenAI-Designmerkmalen explizit nach Peffers et al. @reinhard2026design[Abschn. 3]. Ihre Stärke liegt in der Kommunikation: Ein Paper, dessen Abschnitte sich auf die sechs Aktivitäten abbilden lassen, ist für Gutachtende sofort lesbar. Ihre Schwäche ist der nominal sequenzielle Charakter, der organisationalen Kontext und gleichzeitige Evaluation nur schwach abbildet. Diese Kritik greift Action Design Research auf (@k02-adr).

#merke[
  Demonstration ist nicht Evaluation. Die Demonstration zeigt, dass das Artefakt *an einer Instanz* funktioniert; das Lehrbuch formuliert: Sie belegt Machbarkeit, aber nicht Generalität @haindl2027research[Kap. 2]. Erst die Evaluation vergleicht Ziele systematisch mit beobachteten Ergebnissen. LLM-Papers, die einige gelungene Ausgaben zeigen, haben in der Regel demonstriert, nicht evaluiert.
]

=== Das DSR Grid als Einseitenplan

Für die Planung und Kommunikation eines Projekts auf einer Seite schlagen vom Brocke, Hevner und Maedche das *DSR Grid* mit sechs Dimensionen vor @vombrocke2020introduction[S. 10-11]:

+ *Problembeschreibung* einschließlich Kontext und Gütekriterien (_goodness criteria_);
+ *Input-Wissen*: Kerntheorien, Designtheorien, Design-Entitäten;
+ *Forschungsprozess*: geplante Aktivitäten des Bauens, Evaluierens und Theoretisierens;
+ *Schlüsselkonzepte*;
+ *Lösungsbeschreibung*: Mechanismen und Repräsentation als Konstrukt, Modell, Methode, Instanziierung oder Designtheorie;
+ *Output-Wissen*.

Das Grid zwingt dazu, Input- und Output-Wissen getrennt zu benennen, und macht damit sichtbar, ob ein Projekt überhaupt einen Wissensbeitrag plant. Das Grid ist in der LV die Vorlage für den Einseitenplan einer Abschlussarbeit; @k02-fall-synthese füllt es für KoDa aus.

=== Wieringas Engineering Cycle: Validierung versus Evaluation

Wieringa ergänzt die DSRM um eine Unterscheidung, die bei LLM-Artefakten Gold wert ist @wieringa2014design. Sein *Engineering Cycle* besteht aus Problemuntersuchung (_problem investigation_), Behandlungsentwurf (_treatment design_), Behandlungsvalidierung (_treatment validation_), Implementierung (_treatment implementation_) und Implementierungsevaluation (_implementation evaluation_). Die letzten beiden liegen außerhalb eines Forschungsprojekts, denn sie finden statt, wenn das Artefakt tatsächlich in die Praxis übergeht. Eine *Behandlung* (_treatment_) ist die Interaktion eines Artefakts mit seinem Kontext; nicht das Artefakt allein, sondern Artefakt plus Kontext erzeugt die Wirkung.

#definition(titel: [Validierung und Evaluation nach Wieringa])[
  *Validierung* sagt *vor* dem Transfer in die Praxis vorher, ob das Artefakt im Kontext die Anforderungen erfüllen würde, etwa durch Expertenurteil, Simulation, Single-Case Mechanism Experiments oder Technical Action Research. *Evaluation* prüft die tatsächlichen Effekte *nach* der Implementierung in der realen Welt @wieringa2014design.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let r = 2.6
    let hw = 1.15
    let hh = 0.42
    let stufen = (
      ([Problem- \ untersuchung], 90deg, c-blue),
      ([Behandlungs- \ entwurf], 18deg, c-accent),
      ([Behandlungs- \ validierung], -54deg, c-teal),
      ([Implemen- \ tierung], -126deg, c-grey),
      ([Implementierungs- \ evaluation], 162deg, c-grey),
    )
    let pos = stufen.map(s => (r * calc.cos(s.at(1)), r * 0.8 * calc.sin(s.at(1))))
    for (i, (lab, w, col)) in stufen.enumerate() {
      kasten(pos.at(i), lab, col: col, bg: col.lighten(88%), w: 2 * hw, h: 2 * hh, size: 7.2pt)
    }
    for i in range(5) {
      let a = pos.at(i)
      let b = pos.at(calc.rem(i + 1, 5))
      let dx = b.at(0) - a.at(0)
      let dy = b.at(1) - a.at(1)
      let t = calc.min(if dx == 0 { 9 } else { hw / calc.abs(dx) }, if dy == 0 { 9 } else { hh / calc.abs(dy) }) + 0.05
      let col = if i >= 2 { c-grey } else { c-dark }
      pfeil((a.at(0) + dx * t, a.at(1) + dy * t), (b.at(0) - dx * t, b.at(1) - dy * t), color: col)
    }
    content((0, 0.35), text(font: "Inter", size: 7.5pt, weight: "bold", fill: c-accent)[Designzyklus])
    content((0, -0.1), text(font: "Inter", size: 6.8pt, fill: c-dark)[im Forschungsprojekt])
    content((0, -0.5), text(font: "Inter", size: 6.8pt, fill: c-grey.darken(20%))[grau: Praxis, nach Transfer])
  }),
  caption: [Engineering Cycle nach @wieringa2014design. Problemuntersuchung, Entwurf und Validierung bilden den Designzyklus innerhalb eines Forschungsprojekts; Implementierung und Implementierungsevaluation finden nach dem Transfer in die Praxis statt.],
) <k02-abb-wieringa>

Für Data Scientists liefert Wieringa ein präzises Vokabular. Ein *Single-Case Mechanism Experiment* ist ein kontrollierter Lauf eines Artefakts auf kuratierten Eingaben, um zu verstehen, *welcher Mechanismus* eine Wirkung erzeugt, also genau das, was du tust, wenn du ein LLM-Artefakt auf einem Testset mit variierten Prompts laufen lässt. *Technical Action Research* (TAR) wendet einen Prototyp in einem realen Kundenkontext an, um ihn zu validieren und dem Kunden zugleich zu helfen @wieringa2014design. Für Regelmäßigkeiten über Stichproben hinweg nennt Wieringa statistische Difference-Making-Experimente @wieringa2014design. Die meisten Evaluationen in LLM-Masterarbeiten sind im Sinne Wieringas *Validierungen*; es ist ehrlicher, sie auch so zu nennen.

#hoersaal([Peffers, Hevner, Wieringa, vom Brocke: Welches Modell soll ich in meiner Arbeit verwenden?], [
  Die Modelle konkurrieren weniger, als es scheint. Die Drei-Zyklen-Sicht @hevner2007three ist eine Diagnose der Verbindungen zu Umwelt und Wissensbasis; die DSRM @peffers2007design ist ein Prozess- und Gliederungsmodell; Wieringa @wieringa2014design liefert die Begriffe für die empirischen Teilfragen; das DSR Grid @vombrocke2020introduction ist ein Planungswerkzeug. Für eine Masterarbeit ist eine bewährte Kombination: Gliederung und Prozess nach DSRM, Verbindung von Relevanz und Rigor mit der Drei-Zyklen-Sicht begründen, Evaluationsepisoden mit FEDS planen (@k02-evaluation) und den Plan auf einer Seite mit dem DSR Grid festhalten. Wichtig ist nur, dass du *ein* Prozessmodell konsequent durchziehst und nicht drei halb.
])

=== Im Fallbeispiel

KoDa hat einen *problemzentrierten* Einstieg: Die Forschungsgruppe beobachtet, dass manuelle Codierung zum Engpass wird. Die sechs Aktivitäten lassen sich so planen:

+ *Problem:* Zeitaufwand der Codierung, Risiko unreflektierter Übernahme von KI-Vorschlägen; Belege aus Literatur und Interviews mit Codierenden.
+ *Ziele:* Codierzeit pro Antwort um mindestens ein Drittel senken; Übereinstimmung mit dem Goldstandard nicht schlechter als zwischen zwei menschlichen Codierenden; Vorschläge werden nachweislich geprüft und nicht blind übernommen. Die Schwellen werden *vorab* festgelegt.
+ *Design und Entwicklung:* Segmentierung, Prompt mit Codebuch, Begründung und Belegstelle, Unsicherheitsmarkierung, Benutzeroberfläche.
+ *Demonstration:* Codierung von 50 Antworten einer Pilotwelle mit Beispielen.
+ *Evaluation:* mehrere Episoden, geplant mit FEDS (@k02-evaluation).
+ *Kommunikation:* Paper mit Designprinzipien, LLM-Log, Prompt-Archiv und Daten.

== Den Wissensbeitrag positionieren <k02-beitrag>

=== Deskriptives und präskriptives Wissen

Gregor und Hevner unterscheiden zwei Wissensarten, die gemeinsam die DSR-Wissensbasis bilden @gregor2013positioning[S. 343, Abb. 1]. *Deskriptives Wissen* ($Omega$) ist Wissen über das "Was": Phänomene, Beobachtungen, Gesetzmäßigkeiten, Theorien. *Präskriptives Wissen* ($Lambda$) ist Wissen über das "Wie": von Menschen gebaute Artefakte, also Konstrukte, Modelle, Methoden, Instanziierungen und Designtheorien. DSR greift auf beide zurück und trägt vor allem zu $Lambda$ bei, kann aber über die Evaluation auch neues $Omega$-Wissen erzeugen, etwa wenn sich zeigt, dass Codierende KI-Vorschläge unter Zeitdruck seltener prüfen.

=== Abstraktionsebenen von Beiträgen

Nicht jeder Beitrag ist gleich abstrakt. Gregor und Hevner unterscheiden drei Ebenen @gregor2013positioning[Tab. 1]:

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    table.header([Ebene], [Beitragsart], [Beispiel KoDa]),
    [Ebene 1], [situierte Implementierung: Softwareprodukte, implementierte Prozesse], [der lauffähige Prototyp KoDa mit konkretem Prompt und Modell],
    [Ebene 2], [entstehende (_nascent_) Designtheorie: Konstrukte, Methoden, Modelle, Designprinzipien, technologische Regeln], [Designprinzipien für LLM-gestützte Codierassistenten],
    [Ebene 3], [gut entwickelte Designtheorie über eingebettete Phänomene], [eine Theorie angemessener Verlässlichkeit in Mensch-KI-Codierung mit geprüften Propositionen],
  ),
  caption: [Abstraktionsebenen von DSR-Beiträgen nach @gregor2013positioning[Tab. 1]; Spalte rechts eigene Illustration.],
) <k02-tab-ebenen>

Für eine Masterarbeit ist Ebene 2 das realistische und angemessene Ziel. Eine reine Ebene-1-Arbeit ist schwer als Forschung zu verteidigen; Ebene 3 erfordert in der Regel mehrere Projekte. Bei LLM-Artefakten kommt ein Problem hinzu, das zur Ebene 2 drängt: Ein Ebene-1-Beitrag ist an ein Modell gebunden, das in absehbarer Zeit nicht mehr verfügbar ist (@k02-risiken). Nur die abstraktere Ebene hat eine Chance, den Modellwechsel zu überleben.

=== Das Knowledge Contribution Framework

Das bekannteste Werkzeug von Gregor und Hevner ist eine 2×2-Matrix @gregor2013positioning[Abb. 3, S. 344-347]. Die x-Achse gibt die *Reife der Anwendungsdomäne* (des Problemkontexts) an, die y-Achse die *Reife bestehender Lösungsartefakte*. Daraus ergeben sich vier Beitragstypen.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let q(x, y, titel, text1, col) = {
      rect((x, y), (x + 4.4, y + 2.4), fill: col.lighten(88%), stroke: 0.8pt + col)
      content((x + 2.2, y + 1.75), text(font: "Inter", size: 8.5pt, weight: "bold", fill: col.darken(20%), titel))
      content((x + 2.2, y + 0.85), align(center, text(font: "Inter", size: 7pt, text1)))
    }
    q(0, 2.4, [Exaptation], [bekannte Lösung auf \ neues Problem übertragen \ #text(fill: c-dark)[_Forschungsbeitrag_]], c-teal)
    q(4.4, 2.4, [Routine Design], [bekannte Lösung für \ bekanntes Problem \ #text(fill: c-red)[_meist kein Forschungsbeitrag_]], c-grey)
    q(0, 0, [Invention], [neue Lösung für \ neues Problem \ #text(fill: c-dark)[_Forschungsbeitrag_]], c-accent)
    q(4.4, 0, [Improvement], [neue Lösung für \ bekanntes Problem \ #text(fill: c-dark)[_Forschungsbeitrag_]], c-blue)
    line((-0.2, -0.2), (9.2, -0.2), stroke: 0.8pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.6))
    line((-0.2, -0.2), (-0.2, 5.1), stroke: 0.8pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.6))
    content((4.5, -0.65), text(font: "Inter", size: 7.5pt)[Reife der Anwendungsdomäne (Problem bekannt?) #h(0.5em) niedrig #sym.arrow hoch])
    content((-0.65, 2.5), angle: 90deg, text(font: "Inter", size: 7.5pt)[Reife der Lösungsartefakte (Lösung bekannt?)])
    content((9.6, 3.6), anchor: "west", align(left, text(font: "Inter", size: 6.8pt, fill: c-dark)[Wrapper um LLM-API \ mit Standard-RAG \ für gut untersuchtes \ Problem]))
    pfeil((9.5, 3.6), (8.85, 3.6), color: c-grey)
    content((9.6, 1.1), anchor: "west", align(left, text(font: "Inter", size: 6.8pt, fill: c-dark)[KoDa: neuer Mechanismus \ für bekanntes Problem \ (deduktive Codierung)]))
    pfeil((9.5, 1.1), (8.85, 1.1), color: c-blue)
  }),
  caption: [Knowledge Contribution Framework nach @gregor2013positioning[Abb. 3]. Routine Design ist nach den Autoren in der Regel kein Forschungsbeitrag @gregor2013positioning[S. 347]. Die Annotationen rechts sind eigene Einordnungen.],
) <k02-abb-kcf>

Formal lässt sich die Matrix als Entscheidungsregel schreiben. Sei $p in {0, 1}$ der Indikator dafür, dass das Problem (die Anwendungsdomäne) bereits gut verstanden ist, und $s in {0, 1}$ der Indikator dafür, dass bereits ein wirksames Lösungsartefakt existiert. Dann gilt @gregor2013positioning[Abb. 3]

$ "Typ"(p, s) = cases(
  "Invention" & "falls" p = 0\, s = 0,
  "Improvement" & "falls" p = 1\, s = 0,
  "Exaptation" & "falls" p = 0\, s = 1,
  "Routine Design" & "falls" p = 1\, s = 1,
) $ <k02-eq-kcf>

Die Regel ist trivial, ihre Anwendung nicht. Die Schwierigkeit liegt darin, $p$ und $s$ ehrlich zu bestimmen. "Das Problem ist neu" ist eine der am häufigsten überzogenen Behauptungen in Exposés; meist ist das Problem bekannt, aber in einem neuen Kontext untersucht. Ebenso ist "es gibt keine Lösung" selten wahr; meist gibt es Lösungen mit bekannten Schwächen, was ein Improvement begründet. Die Gregor-Hevner-Matrix verlangt also eine Literaturrecherche, die nicht nur nach dem *Problem*, sondern auch nach *Lösungen* sucht, also einen funktionierenden Rigorzyklus.

#block(breakable: false)[#beispiel(titel: [Einordnung von drei LLM-Projekten])[
  (a) Ein Chatbot, der mit einer kommerziellen API und Standard-RAG Fragen zu einer Studienordnung beantwortet: Das Problem (Informationszugang) ist gut verstanden, das Lösungsmuster etabliert; $p = 1$, $s = 1$, also nach @k02-eq-kcf Routine Design.

  (b) Ein bekanntes Verfahren zur Unsicherheitsschätzung aus der Sprachverarbeitung wird erstmals auf ein Problem angewendet, für das es noch keine Problemformulierung gibt, etwa die Frage, wann eine LLM-gestützte Literaturauswahl abgebrochen werden darf: $p = 0$, $s = 1$, also Exaptation.

  (c) KoDa: Deduktive Codierung und ihre Gütekriterien sind gut verstanden ($p = 1$); ein Mechanismus, der Codierende durch Belegstellen und selektive Unsicherheitsmarkierung zu kritischer Prüfung anleitet, existiert in dieser Form nicht ($s = 0$). Ergebnis: Improvement. Der Beitrag muss deshalb zeigen, dass KoDa *besser* ist als bestehende Lösungen, und braucht einen Vergleichsmaßstab.
]]

=== Rechnen mit Wirkung: die Regression von Wagner et al.

Dass die Positionierung zählt, quantifiziert die bereits erwähnte Metastudie. Wagner et al. modellieren die Zitationszahl einer DSR-Arbeit $j$ mit einem negativ-binomialen GLM. Neuheit geht als Dummy-Variablen für den Beitragstyp (Referenz: Improvement) ein, Theoretisierung als Score, Kontrollvariablen sind Journal-Impact-Factor, h-Index und Publikationsalter @wagner2021exploring[Abschn. 5.1, Tab. 3]. Die Arbeit gibt selbst eine "canonical logit link function" an und berichtet nur rohe Koeffizienten, ohne sie zu exponieren. Die folgende Log-Link-Lesart ist eine *eigene Interpretation* (der Log-Link ist der Standard in gängiger Software für negativ-binomiale Modelle), nicht die der Autoren:

$ log EE["Zitationen"_j] = beta_0 + beta_1 dot "Neuheit"_j + beta_2 dot "Theoretisierung"_j + bold(gamma)^top bold(z)_j $ <k02-eq-wagner>

Unter dem Log-Link gilt für eine Erhöhung von $x_k$ um eine Einheit bei sonst gleichen Werten

$ (EE["Zit." | x_k + 1])/(EE["Zit." | x_k]) = (exp(dots.c + beta_k (x_k + 1)))/(exp(dots.c + beta_k x_k)) = e^(beta_k). $ <k02-eq-irr>

Der Faktor $e^(beta_k)$ heißt Inzidenzratenverhältnis (_incidence rate ratio_).

#beispiel(titel: [Koeffizienten von Wagner et al. umrechnen])[
  Aus Modell 2 in @wagner2021exploring[Tab. 3]: Theoretisierung $beta_2 = 0.29$ (p < 0.001), Exaptation $0.51$ (p < 0.01), Invention $0.40$ (p < 0.05), Routine Design $0.01$ (n. s.), Journal-Impact-Factor $0.24$ (p < 0.001). Unter der Log-Link-Lesart von @k02-eq-irr:

  - Theoretisierung: $e^(0.29) = 1.336$, also rund 34 % mehr erwartete Zitationen pro Einheit Theoretisierungsscore;
  - Exaptation: $e^(0.51) = 1.665$, also rund das 1.67-Fache der erwarteten Zitationen einer vergleichbaren Improvement-Arbeit;
  - Invention: $e^(0.40) = 1.492$;
  - Routine Design: $e^(0.01) = 1.010$, praktisch kein Unterschied und nicht signifikant;
  - Journal-Impact-Factor: $e^(0.24) = 1.271$.

  Bemerkenswert ist der Vergleich: Der Theoretisierungseffekt übertrifft den des Journal-Impact-Factors @wagner2021exploring[Tab. 3, Abschn. 5.1]. Der Theoretisierungseffekt war einseitig getestet mit $t = 5.51$, und das Hinzufügen der Neuheit verbesserte die Modellgüte signifikant (partieller F-Test, $p = 0.008$) @wagner2021exploring[Tab. 3]. Die Ergebnisse blieben robust ohne Ausreißer ($n = 111$) und ohne Sonderfälle ($n = 110$) @wagner2021exploring[Tab. 5-6].
]

#fallstrick[
  Unter einem echten Logit-Link wären die Koeffizienten *keine* Zählratenverhältnisse; der Logit-Link bildet eine Wahrscheinlichkeit, nicht einen Erwartungswert einer Zählvariable ab. Da die Arbeit nicht offenlegt, wie der Link für eine Zählvariable umgesetzt wurde, sind die Faktoren oben als Größenordnung zu lesen, nicht als exakte Effektgrößen. Im Hörsaal ist genau das eine gute Diskussionsfrage: Welche Interpretation erlaubt ein Koeffizient, wenn die Linkfunktion unklar ist?
]

#figure(
  balken((
    ([Exaptation], 0.51),
    ([Invention], 0.40),
    ([Theoretisierung], 0.29),
    ([Journal-Impact-Factor], 0.24),
    ([Routine Design], 0.01),
  ), max: 0.6, breite: 8, farbe: c-teal, nachkomma: 2),
  caption: [Rohe Koeffizienten aus Modell 2 von @wagner2021exploring[Tab. 3]; Beitragstypen relativ zu Improvement. Routine Design ist nicht signifikant.],
) <k02-abb-wagner>

=== Artefakt oder Theorie?

Die Frage, ob ein akzeptabler DSR-Beitrag das Artefakt, die Designtheorie oder beides ist, behandelt ein Editorial im Journal of the Association for Information Systems mit Positionierungsaussagen und Empfehlungen für Autorinnen, Autoren und Gutachtende @baskerville2018design. Die Debatte hat zwei Seiten.

Die *theorieorientierte* Seite argumentiert, DSR-Beiträge sollten über die Instanziierung hinaus zu entstehender oder gut entwickelter Designtheorie führen @gregor2013positioning[Tab. 1], und kann sich auf den empirischen Befund stützen, dass Theoretisierung der stärkste Prädiktor für Wirkung ist @wagner2021exploring[Tab. 3]. Die *artefaktorientierte* Seite warnt vor Vereinfachung: In Interviews mit Autorinnen und Autoren hochzitierter DSR-Arbeiten wurde davor gewarnt, dass vereinfachte Schablonen komplexe Probleme zu stark vereinfachen; gefordert wurde, Zwischenartefakte und Zwischenbeiträge stärker wertzuschätzen @reiners2025past[Abschn. 5, Tab. 3]. Murphy argumentiert zudem, dass die Anatomien von Designtheorie und Designprinzip in Kombination ontologisch inkonsistent sind, und schlägt ein synthetisiertes Schema vor @murphy2025dissecting.

Generative KI verschärft die Debatte. Wenn präskriptives Wissen mit dem Modellwechsel schnell erodiert @zurheiden2026design, wird Theorie auf abstrakterer Ebene wichtiger, aber auch schwerer zu prüfen. Ein Designprinzip wie "Zeige Belegstellen pro Vorschlag" überlebt den Modellwechsel eher als die Aussage "GPT-4 mit Prompt X erreicht $F_1 = 0.78$".

#studie(titel: [Reiners et al. 2025])[
  *Design.* 14 halbstrukturierte Interviews (je rund 30 min) mit je einer Autorin oder einem Autor hochzitierter DSR-Arbeiten; Codierung in 508 Konzepte erster Ordnung, 10 Themen zweiter Ordnung und 3 Dimensionen @reiners2025past[Abschn. 3.2].

  *Befund.* Größtes Thema war Komplexität (110 Konzepte), gefolgt von Transdisziplinarität (69), Reife (55), Positionierung (49), Rigor (48) und Anleitung (48); Evolution war am kleinsten (9) @reiners2025past[Tab. 2]. Genannte Herausforderungen sind Planung, Zwischenartefakte, iterative Zyklen, Abbruchregeln (_stopping rules_), Rigor und Problempositionierung; Evaluation ist ressourcenintensiv @reiners2025past[Abschn. 4.2]. Die Arbeit leitet sechs Zukunftsrichtungen ab, darunter Zwischenartefakte voranzubringen und iterative, adaptive Methoden zu fördern @reiners2025past[Tab. 3].

  *Grenzen.* Selektion zugunsten hochzitierter Autorinnen und Autoren, Rückschaufehler; generative KI wird nicht behandelt @reiners2025past[Abschn. 5].
]

#hoersaal([Ist ein RAG-Chatbot für X Invention, Improvement, Exaptation oder Routine Design?], [
  Das hängt nicht vom Chatbot ab, sondern von $p$ und $s$ in @k02-eq-kcf. Ein Standard-RAG für ein gut untersuchtes Informationsproblem ist Routine Design @gregor2013positioning[S. 347]. Zur Forschung wird das Projekt, wenn entweder das Problem neu formuliert wird (etwa: angemessenes Vertrauen in eine Domäne mit sicherheitskritischen Antworten, in der es keine etablierte Problemformulierung gibt) oder wenn ein neuer Mechanismus vorgeschlagen und gegen bestehende Lösungen geprüft wird. Engström et al. fanden, dass keine der untersuchten ICSE-Arbeiten Neuheit auf der Ebene der technologischen Regel diskutierte @engstrom2020software[Abschn. 5.4]; genau dort solltest du sie argumentieren, nicht auf der Ebene des Tools.
])

=== Im Fallbeispiel

KoDa wird als *Improvement* positioniert, mit einem Hauptbeitrag auf *Ebene 2* (Designprinzipien) und einer Instanziierung auf Ebene 1 als Nachweis. Daraus folgen zwei Anforderungen: Es braucht einen Vergleich mit bestehenden Lösungen (etwa rein manueller Codierung und einem LLM ohne Belege und Unsicherheitsmarkierung), und die Prinzipien müssen modellunabhängig formuliert sein, damit der Beitrag den absehbaren Modellwechsel überlebt.

== Designtheorie, Designprinzipien und technologische Regeln <k02-theorie>

=== Die Anatomie einer Designtheorie

Gregor und Jones spezifizieren die strukturellen Komponenten einer IS-Designtheorie in Erweiterung früherer Arbeiten von Walls, Widmeyer und El Sawy @gregor2007anatomy[Tab. 2]. Sie nennen sechs Kernkomponenten und zwei zusätzliche Komponenten. Das Lehrbuch empfiehlt, diese Elemente explizit zu dokumentieren, um zu zeigen, wie ein Artefakt über die konkrete Instanziierung hinaus theoretisches Wissen beiträgt @haindl2027research[Kap. 3].

#figure(
  table(
    columns: (auto, auto, 1fr),
    table.header([Nr.], [Komponente], [Formulierung für KoDa (illustrativ)]),
    [1], [Zweck und Geltungsbereich], [Unterstützung deduktiver Codierung von Freitext mit festem Codebuch; nicht für induktive Codeentwicklung],
    [2], [Konstrukte], [Segment, Codevorschlag, Belegstelle, Unsicherheitsmarkierung, Prüfentscheidung],
    [3], [Prinzipien von Form und Funktion], [Vorschlag stets mit wörtlicher Belegstelle; Unsicherheit nur unterhalb einer Schwelle anzeigen; Entscheidung immer beim Menschen],
    [4], [Veränderlichkeit des Artefakts (_artifact mutability_)], [Austausch des LLM erlaubt, sofern Belegtreue und Stabilität erneut validiert werden],
    [5], [Testbare Propositionen], [Mit Belegstellen sinkt der Anteil unbegründet übernommener falscher Vorschläge gegenüber Vorschlägen ohne Beleg],
    [6], [Rechtfertigendes Wissen (Kerntheorien)], [Literatur zu angemessenem Vertrauen und zu Erklärungen in Mensch-KI-Interaktion],
    [7], [Implementierungsprinzipien], [Schwellen zuerst an einer Kalibrierstichprobe festlegen; Codebuch im Prompt versionieren],
    [8], [Expositorische Instanziierung], [der Prototyp KoDa],
  ),
  caption: [Acht Komponenten einer Designtheorie nach @gregor2007anatomy[Tab. 2] (1-6 Kern, 7-8 zusätzlich), angewendet auf das Fallbeispiel.],
) <k02-tab-anatomie>

Die vierte Komponente, die *Veränderlichkeit des Artefakts*, ist bei LLM-Artefakten der natürliche Ansatzpunkt. Sie verlangt, vorab zu sagen, welche Veränderungen das Artefakt verträgt, ohne dass die Theorie ihre Gültigkeit verliert. Für ein Artefakt mit austauschbarem Sprachmodell ist das eine der wichtigsten Aussagen überhaupt.

Kuechler und Vaishnavi zeigen an einem detailliert berichteten DSR-Projekt, dass das Entwickeln und Testen eines Artefakts zur Erzeugung einer präskriptiven Designtheorie eng mit dem Testen und Verfeinern der *Kerntheorie* des Artefakts verbunden ist @kuechler2008theory. Für KoDa heißt das: Wenn sich zeigt, dass Belegstellen die Prüfquote nicht erhöhen, ist das nicht nur ein Misserfolg des Artefakts, sondern ein Befund über die Kerntheorie angemessenen Vertrauens in diesem Kontext.

=== Die Anatomie eines Designprinzips

Designprinzipien sind die typische Form präskriptiven Wissens auf Ebene 2. Gregor, Chandra Kruse und Seidel haben ein Schema vorgelegt, das Designprinzipien für IT-basierte Artefakte in soziotechnischen Systemen spezifiziert und dabei menschliche Akteursrollen, Zerlegung, probabilistische Kausalität, unterschiedliche Mechanismen und optionales rechtfertigendes Wissen berücksichtigt @gregor2020research[Tab. 4, S. 1633].

#definition(titel: [Designprinzip nach Gregor, Chandra Kruse und Seidel])[
  "Damit Implementierende $I$ das Ziel $A$ für Nutzende $U$ im Kontext $C$ erreichen oder ermöglichen, setze die Mechanismen $M_1, M_2, dots, M_n$ unter Beteiligung der Akteure $E_1, E_2, dots, E_n$ ein, wegen der Begründung $R$." @gregor2020research[S. 1633]

  Dabei ist $I$ der Akteur, der das Prinzip instanziiert; $A$ das Ziel; $U$ der Akteur, für den das Ziel erreicht wird; $C$ die Randbedingungen und das Umsetzungsumfeld; $M_k$ Handlungen, Aktivitäten, Prozesse, Architektur oder Manipulation anderer Artefakte; $E_k$ die Akteure, die die Mechanismen ausführen; $R$ die Rechtfertigung, warum $M$ zu $A$ führen soll.
]

#figure(
  {
    set text(font: "Inter", size: 7.5pt)
    diagram(
      spacing: (13mm, 7mm),
      node-stroke: 0.8pt,
      fknoten((1, 0), [Implementierende \ *I*], col: c-grey, w: 28mm),
      fknoten((0, 1), [Kontext *C*], col: c-grey, w: 24mm),
      fknoten((1, 1), [Mechanismen \ *M#sub[1]* ... *M#sub[n]*], col: c-accent, filled: true, w: 28mm),
      fknoten((2, 1), [Ziel *A* \ für Nutzende *U*], col: c-blue, filled: true, w: 28mm),
      fknoten((1, 2), [Akteure (Enactors) \ *E#sub[1]* ... *E#sub[n]*], col: c-teal, w: 28mm),
      fknoten((2, 2), [Begründung *R* \ (rechtfertigendes Wissen)], col: c-violet, w: 30mm),
      edge((1, 0), (1, 1), "-|>", label: text(size: 6.8pt)[instanziiert], label-side: left),
      edge((0, 1), (1, 1), "-", stroke: (dash: "dashed")),
      edge((1, 1), (2, 1), "-|>", label: text(size: 6.8pt)[führt zu], label-side: left),
      edge((1, 2), (1, 1), "-|>", label: text(size: 6.8pt)[führen aus], label-side: right),
      edge((2, 2), (2, 1), "-|>", stroke: (paint: c-violet, dash: "dashed"), label: text(size: 6.8pt)[erklärt, warum], label-side: right),
    )
  },
  caption: [Anatomie eines Designprinzips nach @gregor2020research[Abb. 2, Tab. 4]. Mechanismen erzeugen das Ziel für die Nutzenden im Kontext; die Begründung rechtfertigt den erwarteten Zusammenhang (probabilistisch, nicht deterministisch).],
) <k02-abb-prinzip>

Drei Eigenschaften des Schemas verdienen Beachtung. Erstens trennt es Implementierende, Nutzende und ausführende Akteure; bei KoDa ist die Toolbauerin $I$, die Codiererin $U$ und zugleich ein $E$ (sie prüft). Zweitens erlaubt es *probabilistische* Kausalität: Ein Mechanismus erhöht die Wahrscheinlichkeit des Ziels, garantiert es aber nicht, was bei stochastischen LLM-Artefakten die einzig ehrliche Lesart ist. Drittens unterscheidet es die Rolle der Theoretisierenden vom Prinzip selbst @gregor2020research[S. 1634]. Komplexe Artefakte können in Prinzipien niedrigerer Ebene zerlegt werden @gregor2020research[Tab. 4].

#beispiel(titel: [Ein Designprinzip aus einer publizierten Studie ableiten])[
  Reinhard et al. haben für Wissensarbeit im Service sieben Erklärungsmerkmale entwickelt, darunter DF1 (Referenzen/Quellen) und DF6 (Konfidenzwert aus Kosinus-Ähnlichkeit); in der Evaluation wurden Konfidenzwerte als zu hoch wahrgenommen, mit dem Vorschlag, sie nur bei Unsicherheit anzuzeigen @reinhard2026design[Tab. 2, Abschn. 5]. Daraus lässt sich ein Prinzip nach dem Schema formulieren (Inhalt illustrativ, nicht aus der Quelle):

  "Damit Entwickelnde von Support-Werkzeugen ($I$) eine kalibrierte Verlässlichkeit ($A$) von Support-Mitarbeitenden ($U$) auf LLM-Antworten in wissensintensiver Servicearbeit mit kuratierter Wissensbasis ($C$) ermöglichen, setze Quellenlinks pro Antwortsatz und einen Konfidenzhinweis aus der Retrieval-Ähnlichkeit ein, der nur unterhalb einer Schwelle angezeigt wird ($M_1$, $M_2$), unter Beteiligung der Mitarbeitenden als Prüfende ($E_1$), weil quellenbasierte Erklärungen faktisches Abwägen unterstützen ($R$)."

  Prüfe das Ergebnis an den sieben Slots: Fehlt einer, ist das Prinzip unvollständig. Fehlt $C$, ist es übergeneralisiert; fehlt $R$, ist es eine Behauptung ohne Begründung.
]

=== Technologische Regeln

Im Software Engineering wird die Design-Science-Sicht häufig über die *technologische Regel* operationalisiert @engstrom2020software[Abschn. 2.2.1]:

$ "Um" chevron.l E chevron.r "in" chevron.l S chevron.r "zu erreichen, wende" chevron.l I chevron.r "an," $ <k02-eq-regel>

wobei $E$ der gewünschte Effekt, $S$ die Situation (der Problemkontext) und $I$ die Intervention (das Artefakt) ist. Die technologische Regel ist eine verdichtete Form des Designprinzips: Sie enthält Ziel, Kontext und Mechanismus, aber keine Akteursrollen und keine Begründung. Für KoDa: "Um die Übernahme falscher Codevorschläge zu reduzieren (E) bei deduktiver Codierung großer Freitextmengen mit LLM-Unterstützung (S), zeige zu jedem Vorschlag eine wörtliche Belegstelle und markiere nur unsichere Vorschläge (I)."

#tipp[
  Formuliere technologische Regel und Designprinzip *vor* dem Bauen als Hypothese und *nach* der Evaluation als Ergebnis. Der Unterschied zwischen beiden Fassungen ist ein ehrliches Protokoll dessen, was das Projekt gelernt hat, und gehört in den Diskussionsteil.
]

=== Menschliche und KI-generierte Designprinzipien

Lässt man ein LLM Designprinzipien formulieren, entstehen formal saubere Sätze. Ob sie wiederverwendbar sind, haben Böhmer, Kuehnel und Damarowsky untersucht.

#studie(titel: [Böhmer, Kuehnel und Damarowsky 2025])[
  *Design.* Befragungsbasierter Vergleich menschlich und KI-generierter Designprinzipien hinsichtlich Wiederverwendbarkeitskriterien, theoretische Linse: begrenzte Rationalität (Research-in-Progress) @bohmer2025should.

  *Befund.* Beide Varianten erzielten hohe Werte bei Zugänglichkeit, Wichtigkeit, Neuheit, Erklärungskraft und Prägnanz; subtilere Unterschiede zeigten sich bei Handlungsorientierung (_actionability_), Wirksamkeit und praktischer Anwendbarkeit @bohmer2025should. Die Richtung dieser Unterschiede ist im Abstract nicht angegeben.

  *Grenzen.* Research-in-Progress; Stichprobengrößen und Tests sind nicht verifiziert. Ob KI-generierte Prinzipien zu besseren Artefakten führen, wird nicht getestet.
]

Memmert, Tavanapour und Bittner berichten aus Experteninterviews, dass KI-Vorschläge vor allem als Inspiration, nicht als fertiger Inhalt gesehen werden @memmert2023learning. Beide Befunde zusammen legen eine Arbeitsteilung nahe: Das LLM kann Entwürfe liefern und Lücken im Schema aufzeigen; die Verantwortung für Kontext $C$ und Begründung $R$ bleibt beim Menschen, weil genau diese Slots Wissen über die konkrete Umwelt und die Kerntheorien voraussetzen.

#hoersaal([Wenn das LLM in meinem Artefakt durch ein neueres ersetzt wird, gelten meine Designprinzipien dann noch?], [
  Das hängt davon ab, wie du sie formuliert hast. Prinzipien, deren Mechanismen modellspezifisch sind ("verwende Prompt X mit Modell Y"), erodieren mit dem Modell; zur Heiden et al. nennen die rasche Erosion präskriptiven Wissens als eine von fünf Herausforderungen GenAI-bezogener DSR @zurheiden2026design. Prinzipien, deren Mechanismen auf Interaktions- oder Architekturebene liegen ("zeige Belegstellen", "trenne Vorschlag und Entscheidung"), haben bessere Chancen. Die Komponente "Veränderlichkeit des Artefakts" @gregor2007anatomy[Tab. 2] ist der Ort, an dem du vorab festhältst, unter welchen Bedingungen ein Modellwechsel zulässig ist und welche Validierungen danach zu wiederholen sind.
])

== Evaluation in DSR <k02-evaluation>

Evaluation ist die Aktivität, in der sich DSR von Entwicklung am deutlichsten unterscheidet, und zugleich die, an der LLM-Projekte am häufigsten scheitern. Hevner et al. fordern, Nutzen, Qualität und Wirksamkeit eines Artefakts mit gut ausgeführten Methoden rigoros zu zeigen @hevner2004design[Tab. 1]. Was "gut ausgeführt" heißt, beantworten mehrere Rahmenwerke, die aufeinander aufbauen.

=== Methodenfamilien nach Hevner et al.

Hevner et al. ordnen zwölf Evaluationsmethoden in fünf Familien @hevner2004design[Tab. 2, S. 86]; das Lehrbuch übernimmt diese Einteilung @haindl2027research[Kap. 2].

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    table.header([Familie], [Methoden], [Beispiel für ein LLM-Artefakt]),
    [beobachtend], [Fallstudie, Feldstudie], [KoDa wird eine Erhebungswelle lang von einer Forschungsgruppe genutzt],
    [analytisch], [statische Analyse, Architekturanalyse, Optimierung, dynamische Analyse], [Analyse der Kosten pro Antwort und der Latenz in Abhängigkeit von der Segmentlänge],
    [experimentell], [kontrolliertes Experiment, Simulation], [Codierende mit und ohne Belegstellen im Vergleich; Wiederholungsläufe auf einem Testset],
    [testend], [funktional (Black Box), strukturell (White Box)], [Testfälle für Segmentierung und Ausgabeformat],
    [deskriptiv], [informiertes Argument, Szenarien], [Argumentation anhand von Szenarien, warum KoDa Fehlklassifikationen sichtbar macht],
  ),
  caption: [Familien von Evaluationsmethoden nach @hevner2004design[Tab. 2, S. 86]; Beispiele eigene Illustration.],
) <k02-tab-methoden>

Die Tabelle ist ein Menü, keine Strategie. Sie sagt nicht, *wann* welche Methode passt und wie mehrere Methoden zu einem Evaluationsplan zusammenwirken. Das leistet FEDS.

=== FEDS: zwei Dimensionen

Das *Framework for Evaluation in Design Science* (FEDS) von Venable, Pries-Heje und Baskerville gibt praktische Anleitung dafür, warum, wann, wie und was evaluiert werden soll @venable2016feds. Es ist eine Weiterentwicklung eines früheren Frameworks derselben Autoren von der DESRIST 2012, das zwischen ex ante und ex post sowie zwischen artifiziellen und naturalistischen Strategien in Abhängigkeit von Kontextfaktoren (erforderlicher Rigor, Artefakttyp, formative Bedürfnisse, Artefakteigenschaften, Ressourcen) wählte und danach Methoden je Strategie vorschlug @venable2012comprehensive.

FEDS spannt zwei Dimensionen auf @venable2016feds[Abb. 2, S. 80]:

- *Funktionaler Zweck*: *formativ* (um das Artefakt zu verbessern) versus *summativ* (um zu beurteilen, wie gut die Ergebnisse den Erwartungen entsprechen).
- *Paradigma*: *artifiziell* (kontrolliert, etwa Laborexperimente, Simulationen, Beweise) versus *naturalistisch* (echte Nutzende, echte Probleme, echte Umgebungen, etwa Fall- und Feldstudien, Action Research).

Hinzu kommt die zeitliche Lage: *Ex-ante*-Evaluation findet vor der Konstruktion statt, *Ex-post*-Evaluation nach der Implementierung; beide sind Etiketten auf einem Kontinuum @venable2016feds[Abb. 1, S. 79]. Das Lehrbuch fasst die Unterscheidung zusammen: Starke DSR kombiniert mehrere Evaluationstypen, etwa Komplexitätsanalyse und Benchmarks (artifiziell) mit Feldeinsatz und Nutzerstudien (naturalistisch) @haindl2027research[Kap. 3].

=== Vier Strategien

Aus den Dimensionen leitet FEDS vier Strategien ab, die als Trajektorien durch den Raum aus Zweck und Paradigma verlaufen @venable2016feds[S. 81-82, Tab. 1].

#figure(
  table(
    columns: (auto, 1fr),
    table.header([Strategie], [Wähle sie, wenn ...]),
    [Quick & Simple], [das Design klein und einfach ist und geringe soziale und technische Risiken und Unsicherheiten bestehen],
    [Human Risk & Effectiveness], [das Hauptrisiko sozial oder nutzerbezogen ist, eine Evaluation mit echten Nutzenden im echten Kontext relativ günstig ist und das kritische Ziel ist zu zeigen, dass der Nutzen in realen Situationen über die Zeit bestehen bleibt],
    [Technical Risk & Efficacy], [das Hauptrisiko technisch ist, eine Evaluation mit echten Nutzenden oder Systemen prohibitiv teuer ist und das kritische Ziel ist zu zeigen, dass der Nutzen vom Artefakt selbst ausgeht],
    [Purely Technical], [das Artefakt keine sozialen Aspekte hat oder seine Verwendung weit in der Zukunft liegt],
  ),
  caption: [FEDS-Evaluationsstrategien und ihre Wahlbedingungen nach @venable2016feds[Tab. 1, S. 82].],
) <k02-tab-feds>

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 9.6
    let H = 5.6
    rect((0, 0), (W, H), stroke: 0.8pt + c-dark)
    line((W / 2, 0), (W / 2, H), stroke: (paint: luma(190), thickness: 0.6pt, dash: "dashed"))
    line((0, H / 2), (W, H / 2), stroke: (paint: luma(190), thickness: 0.6pt, dash: "dashed"))
    content((W / 4, -0.35), text(font: "Inter", size: 7.5pt)[formativ])
    content((3 * W / 4, -0.35), text(font: "Inter", size: 7.5pt)[summativ])
    content((W / 2, -0.8), text(font: "Inter", size: 7.5pt, weight: "bold")[Funktionaler Zweck])
    content((-0.4, H / 4), angle: 90deg, text(font: "Inter", size: 7.5pt)[artifiziell])
    content((-0.4, 3 * H / 4), angle: 90deg, text(font: "Inter", size: 7.5pt)[naturalistisch])
    content((-0.95, H / 2), angle: 90deg, text(font: "Inter", size: 7.5pt, weight: "bold")[Paradigma])
    // Trajektorien
    let traj(pts, col, lab, k) = {
      for i in range(pts.len() - 1) {
        line(pts.at(i), pts.at(i + 1), stroke: 1.2pt + col, mark: (end: "stealth", fill: col, scale: 0.55))
      }
      for p in pts { circle(p, radius: 0.07, fill: col, stroke: none) }
      let ly = H - 0.5 - k * 0.55
      line((W + 0.4, ly), (W + 1.1, ly), stroke: 1.4pt + col)
      content((W + 1.25, ly), anchor: "west", text(font: "Inter", size: 7pt, weight: "bold", fill: col.darken(10%), lab))
    }
    traj(((0.8, 3.4), (2.6, 4.4), (4.6, 4.9), (8.8, 5.25)), c-blue, [Human Risk & Effectiveness], 0)
    traj(((0.8, 0.9), (2.2, 1.9), (4.0, 2.4), (5.8, 3.8), (8.6, 5.0)), c-accent, [Technical Risk & Efficacy], 1)
    traj(((1.0, 3.0), (8.8, 4.3)), c-violet, [Quick & Simple], 2)
    traj(((0.6, 0.6), (2.0, 1.2), (3.6, 1.8), (5.6, 2.2), (8.6, 2.5)), c-teal, [Purely Technical], 3)
    content((W + 0.4, H - 0.5 - 5.2 * 0.55), anchor: "west", text(font: "Inter", size: 6.6pt, fill: c-grey.darken(20%))[Punkte = Evaluationsepisoden; \ Verlauf qualitativ, \ nicht maßstäblich])
  }),
  caption: [FEDS-Strategien als Trajektorien von Evaluationsepisoden im Raum aus funktionalem Zweck und Paradigma, schematisch nach @venable2016feds[Abb. 2, S. 80-82]. Technical Risk & Efficacy beginnt artifiziell und formativ und endet naturalistisch und summativ; Human Risk & Effectiveness bewegt sich früh in den naturalistischen Bereich.],
) <k02-abb-feds>

=== Der Vier-Schritt-Prozess

FEDS gibt einen Prozess in vier Schritten vor @venable2016feds[S. 82-83]:

+ *Evaluationsziele explizieren*;
+ *Strategie wählen* nach den Bedingungen in @k02-tab-feds;
+ *zu evaluierende Eigenschaften bestimmen*;
+ *einzelne Evaluationsepisoden entwerfen*: Für jede Episode werden Zeitpunkt, Methode, Zweck und Paradigma festgelegt.

Eine Bemerkung zur Anwendung auf LLM-Artefakte ist eine eigene Ableitung aus der FEDS-Logik, keine Empfehlung aus FEDS selbst: Das dominante technische Risiko eines LLM-basierten Artefakts (Nichtdeterminismus, Halluzinationen, Promptsensitivität) spricht typischerweise für *Technical Risk & Efficacy*, also für frühe artifizielle, formative Episoden (etwa Benchmark-Experimente mit Wiederholungsläufen), gefolgt von naturalistischen, summativen Episoden mit echten Nutzenden, sobald das technische Risiko unter Kontrolle ist. FEDS selbst behandelt stochastische Artefakte nicht; Wiederholungsdesigns (@k02-messung) sind eine notwendige Ergänzung.

#merke[
  Wird in einer Episode ein LLM als Bewerter eingesetzt (LLM-as-a-Judge), ist das eine eigene, im FEDS-Plan deklarierte Evaluationsepisode, artifiziell, formativ oder summativ, und sie muss gegen menschliche Urteile validiert werden. Die Details dazu behandelt Kapitel 7.
]

=== Evaluationspraxis: Was tatsächlich evaluiert wird

Prat, Comyn-Wattiau und Akoka haben eine Taxonomie von Evaluationsmethoden entwickelt und auf zehn Jahre DSR-Publikationen im AIS-Basket angewendet @prat2015taxonomy. Sie identifizieren sieben typische Muster:

+ Demonstration;
+ simulations- und metrikbasiertes Benchmarking;
+ praxisbasierte Evaluation der Wirksamkeit;
+ simulations- und metrikbasierte absolute Evaluation;
+ praxisbasierte Evaluation von Nützlichkeit oder Bedienbarkeit;
+ laborbasierte, studierendenbasierte Evaluation der Nützlichkeit;
+ Analyse der algorithmischen Komplexität.

Die Praxis konzentriert sich auf wenige Kriterien; die Autoren fordern Methoden, um langfristige organisationale und gesellschaftliche Wirkungen zu evaluieren @prat2015taxonomy. Wenn du ein aktuelles LLM-Paper in diese Taxonomie einordnest, landest du meist bei Muster 2; das ist eine Einschätzung aus dem Dossier zur LV, keine gezählte Häufigkeit. Das ist kein Vorwurf, aber eine Diagnose: Benchmarking zeigt, dass ein Artefakt auf einem Datensatz besser abschneidet, nicht, dass es in einer Organisation nützt.

=== Das Lehrbuch zur DSR-Qualität

Das Lehrbuch ergänzt FEDS um zwei Gedanken @haindl2027research[Kap. 3]. Erstens die Forderung nach mehreren Evaluationstypen: Ein neuer Algorithmus könnte Komplexitätsanalyse (artifiziell), Benchmarktests (artifiziell), Feldeinsatz (naturalistisch) und Nutzerstudien (naturalistisch) durchlaufen. Zweitens die Rolle der Designtheorie als Rigornachweis: Wer Zweck und Geltungsbereich, Prinzipien von Form und Funktion, Veränderlichkeit, testbare Propositionen und rechtfertigendes Wissen dokumentiert, zeigt, dass das Artefakt über die konkrete Instanziierung hinaus beiträgt. Für die Begrenzung der Aussagen gilt dieselbe Disziplin wie in jeder empirischen Arbeit: Jede Bedrohung, die nicht vollständig neutralisiert werden kann, wird zu einer explizit benannten Limitation @haindl2027research[Kap. 3].

#hoersaal([Darf ich mit LLM-simulierten Nutzenden evaluieren, wenn ich keine echten bekomme?], [
  Blohm et al. nennen das Simulieren von Nutzenden für die Anforderungserhebung als mögliche GenAI-Anwendung in der Designforschung, betonen aber, dass Zuverlässigkeit und Validität synthetischer Daten rigoros evaluiert werden müssen, etwa durch den Vergleich mit realen Daten @blohm2025nextgeneration[S. 110-111]. Simulierte Nutzende können also in einer *artifiziellen, formativen* Episode helfen, offensichtliche Schwächen früh zu finden. Als Ersatz für eine naturalistische summative Episode taugen sie nicht, solange ihre Validität für deinen Kontext nicht gezeigt ist; Kapitel 4 behandelt Silicon Sampling ausführlich. In FEDS-Begriffen: Die Episode ist artifiziell, auch wenn sie "Nutzende" enthält.
])

=== Im Fallbeispiel

Für KoDa ist das Hauptrisiko zunächst technisch (falsche, instabile Codevorschläge), danach sozial (unreflektierte Übernahme). Gewählt wird *Technical Risk & Efficacy*. Der Plan umfasst vier Episoden:

+ *Ex ante, artifiziell, formativ:* Experteninterview mit zwei erfahrenen Codierenden zum Entwurf der Benutzeroberfläche (deskriptiv; adressiert Relevanz).
+ *Ex post, artifiziell, formativ:* Wiederholungsexperiment auf einem Goldstandard von 120 Segmenten, 3 Prompt-Paraphrasen × 10 Läufe, Metrik Makro-$F_1$, plus Stabilitätsmaße (@k02-messung; adressiert Nichtdeterminismus und Promptsensitivität). Zusätzlich ein Kontaminationscheck: Der Goldstandard stammt aus einer neuen, unveröffentlichten Erhebungswelle.
+ *Ex post, artifiziell, summativ:* kontrolliertes Laborexperiment mit Studierenden der Datenwissenschaft; Bedingungen "KoDa mit Belegstellen" versus "KoDa ohne Belegstellen"; gemessen werden Codierzeit, Übereinstimmung mit dem Goldstandard und Anteil übernommener *falscher* Vorschläge (adressiert Übervertrauen).
+ *Ex post, naturalistisch, summativ:* Einsatz in einer echten Erhebungswelle mit zwei Codierenden der Forschungsgruppe; Interviews und Logdaten (adressiert Selbstevaluation, weil nicht die Entwicklerin codiert).

== Action Design Research <k02-adr>

=== Die Kritik an "erst bauen, dann evaluieren"

Sein et al. kritisieren, dass klassische DSR das Bauen vom Evaluieren trennt und damit technischen Rigor über organisationale Relevanz stellt @sein2011action. In ihrer *Action Design Research* (ADR) entstehen IT-Artefakte aus der Interaktion mit dem organisationalen Kontext; Bauen, Intervention in der Organisation und Evaluation laufen *gleichzeitig* ab. ADR besteht aus vier Stufen mit sieben Prinzipien @sein2011action[Abb. 1, S. 41, S. 40-45].

#figure(
  {
    set text(font: "Inter", size: 7.5pt)
    diagram(
      spacing: (5mm, 5mm),
      node-stroke: 0.8pt,
      fknoten((0, 0), [*1 Problemformulierung* \ #text(size: 6.8pt)[P1 praxisinspirierte Forschung \ P2 theoriegeprägtes Artefakt]], col: c-blue, w: 40mm),
      fknoten((1, 0), [*2 Bauen, Intervention, Evaluation (BIE)* \ #text(size: 6.8pt)[P3 wechselseitige Formung \ P4 gegenseitig einflussreiche Rollen \ P5 authentische, gleichzeitige Evaluation]], col: c-accent, w: 48mm),
      fknoten((0, 1), [*4 Formalisierung des Lernens* \ #text(size: 6.8pt)[P7 generalisierte Ergebnisse]], col: c-violet, w: 40mm),
      fknoten((1, 1), [*3 Reflexion und Lernen* \ #text(size: 6.8pt)[P6 geleitete Emergenz]], col: c-teal, w: 48mm),
      edge((0, 0), (1, 0), "-|>"),
      edge((1, 0), (1, 1), "<|-|>", label: text(size: 6.8pt)[laufend], label-side: left),
      edge((0, 0), (1, 1), "<|-", stroke: (dash: "dashed", paint: c-grey), label: text(size: 6.8pt, fill: c-grey.darken(20%))[Rückkopplung], label-side: right),
      edge((1, 1), (0, 1), "-|>"),
    )
  },
  caption: [Stufen und Prinzipien von Action Design Research nach @sein2011action[Abb. 1, S. 41]. Reflexion und Lernen begleiten die BIE-Stufe fortlaufend; Erkenntnisse können zur Problemformulierung zurückführen.],
) <k02-abb-adr>

Die BIE-Stufe gibt es in zwei Varianten @sein2011action[Abb. 3, Abb. 4]. In der *IT-dominanten* Variante steht die Gestaltung des IT-Artefakts im Vordergrund, in der *organisationsdominanten* Variante die organisationale Intervention. Das illustrative Fallbeispiel bei Sein et al. ist ein Kompetenzmanagementsystem bei Volvo IT, das aus einer früheren Action-Research-Studie reinterpretiert wurde @sein2011action[S. 45-51]; aus dem Fall leiten die Autoren überarbeitete Designprinzipien ab @sein2011action[Tab. 3, S. 51]. Dass der Fall eine Reinterpretation und keine prospektive ADR-Studie ist, ist eine Grenze der Methodenpublikation.

=== Action Research als Hintergrund

ADR verbindet DSR mit Action Research. Das Lehrbuch beschreibt Action Research als Ansatz, der Untersuchung und Intervention verbindet und Veränderung untersucht, während die Forschenden aktiv an ihr mitwirken @haindl2027research[Kap. 2]. Der Zyklus durchläuft fünf Phasen: *Diagnose* (Probleme gemeinsam mit Stakeholdern identifizieren, Ursachen statt Symptome), *Aktionsplanung* (Interventionen auf Basis von Diagnose und Theorie entwerfen), *Aktion* (Änderungen umsetzen und dabei Daten erheben), *Evaluation* (Ergebnisse und Prozesse bewerten) und *Lernen* (Reflexion für den nächsten Zyklus). Drei bis vier Zyklen sind in substanziellen Projekten üblich @haindl2027research[Kap. 2].

Die Doppelrolle als Forscherin und Praktikerin verlangt *Reflexivität*: Erfolgreiche und gescheiterte Interventionen werden dokumentiert, der eigene Einfluss auf die Situation wird benannt. Das Lehrbuch nennt fünf spezifische Gütekriterien @haindl2027research[Kap. 2]:

- *Ergebnisvalidität* (_outcome validity_): Hat die Forschung das Ausgangsproblem gelöst?
- *Prozessvalidität* (_process validity_): Waren die Methoden angemessen und systematisch?
- *Demokratische Validität* (_democratic validity_): Wurden die Perspektiven mehrerer Stakeholder einbezogen?
- *Katalytische Validität* (_catalytic validity_): Hat die Forschung die Beteiligten zur Weiterentwicklung angeregt?
- *Dialogische Validität* (_dialogic validity_): Halten die Befunde kritischer Prüfung stand?

=== ADR in der GenAI-Ära

ADR ist die Methode der Wahl für Abschlussarbeiten mit Industriepartner. Zwei aktuelle Beispiele zeigen, wie sie bei generativer KI eingesetzt wird.

#studie(titel: [Reinhard et al. 2025 (GenAI-CoP)])[
  *Design.* Action Design Research kombiniert mit Collaboration Engineering; der Prozess wurde über Simulationen, Experteninterviews und Pilottests verfeinert @reinhard2025genaicop.

  *Befund.* Ein verpackter, ohne Vorschulung nutzbarer Moderationsprozess, mit dem Domänenexpertinnen und -experten identifizieren, wo GenAI-Agenten Produkte und Arbeitsabläufe ergänzen können, samt Richtlinien zum Zusammenfassen dieses Potenzials als GenAI-Agenten @reinhard2025genaicop.

  *Bedeutung.* Ein Methodenartefakt *über* generative KI, das selbst kein LLM enthält. Anzahl und Ergebnisse der Evaluationen sind nicht verifiziert.
]

#studie(titel: [Jin et al. 2026 (PsyCogMetrics AI Lab)])[
  *Design.* Eine Cloud-Plattform, die psychometrische und kognitionswissenschaftliche Methoden zur Evaluation von LLMs anwendet, gerahmt als Drei-Zyklen-Action-Design-Science-Studie @jin2026developing. Relevanzzyklus: Benchmark-Sättigung, Kontamination, entwicklerorientierte Werkzeuge (Abschn. 2); Rigorzyklus: Falsifizierbarkeit, klassische Testtheorie, Cognitive-Load-Theorie (Abschn. 3); Designzyklus mit fünf Zielen (Tab. 1) und verschachtelten BIE-Schleifen, einschließlich "Dogfooding" durch die Forschenden (Abschn. 4.4).

  *Befund.* In einer TAM-basierten Studie mit je 500 Antworten pro LLM (GPT-3.5, GPT-4o, LLaMA-2, LLaMA-3) und 248 Menschen erklärte das Modell die Kaufabsicht (_purchase intention_) mit $R^2$ von 18.4 % (GPT-3.5), 44.3 % (GPT-4o), 19.7 % (LLaMA-2), 37.3 % (LLaMA-3) und 59.9 % (Menschen) @jin2026developing[Tab. 2].

  *Grenzen.* Evaluation durch die Autorinnen und Autoren auf der eigenen Plattform, keine unabhängige Nutzerstudie; Signifikanz nur über Sterne berichtet; inkonsistente Ladungsschwellen (0.60 vs. 0.50) @jin2026developing. Preprint, Stand: 11. November 2026.
]

Jin et al. sind ein lehrreiches Warnbeispiel: Wenn das Artefakt selbst LLMs evaluiert, stellt sich die Frage, wer das Artefakt evaluiert. Dogfooding ist als formative Episode wertvoll, als summative Evidenz aber eine Selbstevaluation.

#hoersaal([Worin unterscheidet sich ADR von Wieringas Technical Action Research?], [
  Beide bringen ein Artefakt in einen realen Kontext. Bei Technical Action Research nach Wieringa wird ein Prototyp in einem realen Kundenkontext angewendet, um ihn zu *validieren* und zugleich dem Kunden zu helfen @wieringa2014design; das Artefakt ist im Kern vorab entworfen. Bei ADR entsteht das Artefakt erst durch die wechselseitige Formung mit der Organisation (Prinzip P3), und Bauen, Intervention und Evaluation sind gleichzeitig @sein2011action. ADR ist also stärker emergent und verlangt eine echte Partnerschaft; TAR passt, wenn du ein weitgehend fertiges Artefakt unter realen Bedingungen prüfen willst.
])

=== Im Fallbeispiel

Hätte die Forschungsgruppe keinen eigenen Bedarf, sondern käme KoDa über eine Kooperation mit einem Marktforschungsinstitut zustande, wäre ADR die naheliegende Methode: Codierende des Instituts gestalten die Oberfläche mit (P3, P4), die Evaluation läuft während der echten Projekte (P5), und die Designprinzipien werden am Ende als generalisierte Ergebnisse formalisiert (P7). Im gewählten Szenario mit eigener Forschungsgruppe bleibt die DSRM das Prozessgerüst, die naturalistische Episode 4 trägt aber Züge von Technical Action Research.

== DSR in Software Engineering und Data Science <k02-se>

=== Die Analyse von Engström et al.

Engström et al. haben untersucht, wie gut Software-Engineering-Forschung mit Design Science übereinstimmt, und dazu den *Visual Abstract* von Storey et al. verwendet, der auf technologischen Regeln aufbaut @engstrom2020software.

#studie(titel: [Engström et al. 2020])[
  *Design.* 38 Arbeiten mit ACM SIGSOFT Distinguished Paper Award der ICSE 2014-2018; jede Arbeit wurde von zwei Autorinnen bzw. Autoren unabhängig anhand von neun Design-Science-Fragen analysiert; Erstellung von Visual Abstracts und Clustering @engstrom2020software[Tab. 1, Abschn. 3]. Member Check: Die Autorinnen und Autoren der Arbeiten von 2014-2015 wurden befragt; 7 von 14 antworteten, überwiegend bestätigend @engstrom2020software[Abschn. 7].

  *Befund.* Fünf Cluster: Problem-Lösungs-Paar (13), Lösungsvalidierung (7), Lösungsdesign (7), deskriptiv (8), meta (3) @engstrom2020software[Abschn. 4, 5]. Die meisten Arbeiten lassen sich als Design Science rahmen, keine verwendet den Begriff @engstrom2020software[Abschn. 1, 9]. Technologische Regeln ließen sich aus den meisten Arbeiten extrahieren, aber keine nannte eine in verdichteter Form @engstrom2020software[Abschn. 5.3]; keine diskutierte Neuheit auf Ebene der Regel, und industrielle Validierung war in den Clustern Lösungsdesign und Lösungsvalidierung selten @engstrom2020software[Abschn. 5.4].

  *Empfehlungen.* Designkonstrukte explizit machen, echte Probleminstanzen verwenden, Validierungsmethoden an den Geltungsbereich der Regel anpassen @engstrom2020software[Abschn. 6].

  *Grenzen.* Gezielte, explorative Stichprobe; das Clustering ist potenziell subjektiv @engstrom2020software[Abschn. 7].
]

#figure(
  balken((
    ([Problem-Lösungs-Paar], 13),
    ([deskriptiv], 8),
    ([Lösungsvalidierung], 7),
    ([Lösungsdesign], 7),
    ([meta], 3),
  ), max: 13, breite: 8, farbe: c-blue, nachkomma: 0),
  caption: [Verteilung der 38 ICSE-Distinguished-Papers (2014-2018) auf die fünf Cluster nach @engstrom2020software[Abschn. 4-5].],
) <k02-abb-engstroem>

Der Visual Abstract hält auf einer Seite das Problem-Lösungs-Paar, die Instanziierungen sowie Einschätzungen zu Relevanz, Rigor und Neuheit fest @engstrom2020software[Abschn. 2.2, 2.2.3]. Er ist damit das SE-Gegenstück zum DSR Grid und eignet sich hervorragend als Übungsformat: Lies ein LLM-Paper, extrahiere die technologische Regel und bewerte Relevanz, Rigor und Neuheit.

=== Generative KI im Software Engineering: eine Roadmap als DSR-Artefakt

Amalfitano et al. haben mit DSR eine Forschungsroadmap für generative KI im Software Engineering erstellt @amalfitano2025research. Das Artefakt entstand in drei Zyklen: Problemstrukturierung mit Peer-Validierung, schnelle Literaturreviews plus McLuhan-Tetraden pro Augmentationsform und eine formübergreifende Synthese, die alle elf Autorinnen und Autoren begutachteten; Ausgangspunkt war der SE-2030-Workshop auf der FSE 2025 @amalfitano2025research.

Inhaltlich unterscheidet die Roadmap vier Formen der GenAI-Augmentation entlang zweier Dimensionen: Augmentation von *Prozessen* versus *Produkten* und *passive* (vom Menschen ausgelöste) versus *aktive* (von der KI ausgelöste) Rollen. Die vier Formen heißen GenAI Copilot, GenAIware, GenAI Teammate und GenAI Robot @amalfitano2025research. Welche Form welcher Kombination der beiden Dimensionen entspricht, geht aus den für dieses Buch geprüften Unterlagen (Dossier und Foliensatz 02) nicht hervor; die Zuordnung wird hier deshalb offen gelassen und ist vor einer Verwendung in der Lehre an der Originalarbeit zu prüfen.

Copilots sind die am meisten untersuchte Form; übergreifende Herausforderungen sind Prompt Engineering, Verantwortlichkeit und die Dynamik von Mensch-KI-Teams @amalfitano2025research. Für das Verständnis von DSR ist die Arbeit aus einem anderen Grund wertvoll: Sie zeigt, dass ein DSR-Artefakt kein Software-Artefakt sein muss, und sie macht ihre Zyklusstruktur transparent.

=== Was das für Data-Science-Abschlussarbeiten heißt

Die Übertragung von DSR auf Data Science ist weniger ein Methodenimport als eine Explizierung dessen, was ohnehin geschieht. Eine typische Data-Science-Arbeit baut eine Pipeline oder ein Modell (Instanziierung), schlägt dabei eine Vorgehensweise vor (Methode) und evaluiert auf einem Benchmark (Prat-Muster 2). Aus DSR-Sicht fehlen meist drei Dinge: eine explizite technologische Regel oder ein Designprinzip, eine Neuheitsargumentation auf dieser Ebene und mindestens eine Episode, die über den Benchmark hinausgeht. Wieringas Vokabular hilft, die Benchmark-Evaluation als das zu benennen, was sie ist: eine Validierung im artifiziellen Kontext @wieringa2014design.

#fallstrick[
  Engström et al. empfehlen, die Validierungsmethode an den *Geltungsbereich der Regel* anzupassen @engstrom2020software[Abschn. 6]. Eine Regel, die für "Codierung offener Antworten in Befragungen" gelten soll, ist mit einem einzigen Datensatz aus einer einzigen Befragung nicht validiert. Entweder du schränkst den Geltungsbereich ($S$ in @k02-eq-regel) ein, oder du erweiterst die Validierung.
]

== Generative KI als Artefakt <k02-artefakt>

=== Was genau ist das Artefakt?

Sobald ein LLM Teil des Artefakts ist, wird die scheinbar einfache Frage "Was hast du gebaut?" schwierig. Feuerriegel et al. unterscheiden drei Ebenen generativer KI @feuerriegel2024generative[Abb. 1]: die *Modellebene* (etwa GPT-4 oder LLaMA 2), die *Systemebene* (das Modell plus Infrastruktur und nutzerseitige Komponenten, etwa Codex in GitHub Copilot) und die *Anwendungsebene* (Systeme, die auf konkrete betriebliche Probleme angewendet werden). Ein DSR-Projekt in der Wirtschaftsinformatik oder Data Science baut fast nie ein Modell, sondern ein System oder eine Anwendung; das Modell ist eine zugekaufte, veränderliche Komponente.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    rect((0, 0), (11, 5.0), radius: 0.15, fill: c-violet.lighten(93%), stroke: 0.9pt + c-violet)
    content((0.25, 4.7), anchor: "west", text(font: "Inter", size: 8pt, weight: "bold", fill: c-violet.darken(20%))[Anwendungsebene: Codierung offener Antworten in einer Befragung])
    rect((0.4, 0.35), (10.6, 4.25), radius: 0.12, fill: c-blue.lighten(92%), stroke: 0.9pt + c-blue)
    content((0.6, 3.95), anchor: "west", text(font: "Inter", size: 8pt, weight: "bold", fill: c-blue.darken(20%))[Systemebene: KoDa])
    kasten((2.0, 2.9), [Codebuch, \ Prompts (versioniert)], col: c-blue, w: 2.7, h: 0.8, size: 7pt)
    kasten((5.3, 2.9), [Segmentierung, \ Orchestrierung], col: c-blue, w: 2.7, h: 0.8, size: 7pt)
    kasten((8.6, 2.9), [Oberfläche: Beleg, \ Unsicherheitsmarke], col: c-blue, w: 2.7, h: 0.8, size: 7pt)
    kasten((2.0, 1.4), [Goldstandard, \ Testset], col: c-blue, w: 2.7, h: 0.8, size: 7pt)
    rect((3.65, 0.85), (6.95, 1.95), radius: 0.1, fill: c-accent.lighten(85%), stroke: (paint: c-accent, thickness: 1pt, dash: "dashed"))
    content((5.3, 1.6), text(font: "Inter", size: 7.5pt, weight: "bold", fill: c-accent.darken(15%))[Modellebene: LLM])
    content((5.3, 1.15), text(font: "Inter", size: 6.6pt, fill: c-dark)[Version, Parameter, Anbieter])
    kasten((8.6, 1.4), [Protokoll (LLM-Log), \ Prüfentscheidungen], col: c-blue, w: 2.7, h: 0.8, size: 7pt)
    content((5.5, -0.4), text(font: "Inter", size: 6.8pt, fill: c-grey.darken(20%))[gestrichelt: austauschbare Komponente, deren Veränderlichkeit die Designtheorie regeln muss])
  }),
  caption: [Modell-, System- und Anwendungsebene nach @feuerriegel2024generative[Abb. 1], angewendet auf das Fallbeispiel. Die Artefaktgrenze muss explizit gezogen werden: Gehören Prompts, Testset und Codebuch zum Artefakt oder zum Kontext?],
) <k02-abb-ebenen>

=== Fünf theoretische Herausforderungen

Zur Heiden et al. haben in einem integrativen Literaturreview neuerer DSR-Publikationen in führenden IS-Outlets fünf theoretische Herausforderungen für GenAI-bezogene DSR synthetisiert @zurheiden2026design:

+ *undurchsichtige Zusammensetzung* des Artefakts (_obscure composition_): Welche Teile gehören dazu, und wie wirken sie zusammen?
+ *opake Kontextualisierung* des LLM: Was "weiß" das Modell über den Kontext, und woher?
+ *fragile innere Konsistenz* des Artefakts: Kleine Änderungen an Prompts oder Modellen können das Verhalten unvorhersehbar verändern;
+ *rasche Erosion präskriptiven Wissens*: Designwissen, das an ein Modell gebunden ist, veraltet mit diesem;
+ *fehlende methodische Anleitung*.

Die Autoren leiten drei Richtlinien ab, um GenAI-bezogene DSR-Prozesse zu entwerfen und zu begründen und die theoretische Fundierung von Designentscheidungen und Evaluationsstrategien zu artikulieren; sie argumentieren, der Wandel sei "much more profound than it has been discussed so far" @zurheiden2026design. Da die Arbeit nur auf Abstract-Ebene verifiziert ist, werden die drei Richtlinien hier nicht inhaltlich wiedergegeben.

Jede der fünf Herausforderungen lässt sich in einen Prüfpunkt für eine Abschlussarbeit übersetzen: (1) Artefaktgrenze zeichnen wie in @k02-abb-ebenen; (2) dokumentieren, welche Kontextinformation das Modell über Prompt, Retrieval oder Feinabstimmung erhält; (3) Stabilität über Paraphrasen und Läufe messen (@k02-messung); (4) Designprinzipien modellunabhängig formulieren und die Veränderlichkeit regeln; (5) das gewählte Vorgehen explizit begründen, statt eine Standardmethode unkommentiert zu übernehmen.

=== Editorials: was Top-Journals erwarten

Abbasi et al. behandeln im ISR-Editorial Forschung, die "prescribe[s] solutions to problems using AI approaches rather than describing or explaining AI-related phenomena" @abbasi2024pathways. Sie identifizieren sechs große Hürden für die Publikation solcher Arbeiten, illustriert an den raschen Fortschritten von LLMs, schlagen Publikationspfade vor und zeigen an Beispielartikeln, wie diese für verschiedene KI-Artefakttypen gelten @abbasi2024pathways. Die einzelnen Hürden sind nur auf Abstract-Ebene verifiziert. Die Botschaft ist trotzdem klar: Top-Journals erwarten von KI-Designforschung eine Positionierung, die über "wir haben ein Modell gebaut" hinausgeht.

Fill et al. diskutieren im BISE-Editorial LLM-basierte Generierung und Analyse konzeptueller Modelle @fill2026generative. Zwei Punkte sind für jede Evaluation eines generierenden Artefakts zentral. Erstens sind offene Modelle für Reproduzierbarkeit vorzuziehen, weil alle Komponenten inspiziert und validiert werden können, proprietäre Modelle seien aber in der Generierungsqualität "still far ahead" @fill2026generative[Abschn. 1]. Zweitens setzt eine Evaluation gegen ein von Expertinnen und Experten erstelltes "ideales" Modell implizit eine einzige Ground Truth voraus; generierte Modelle könnten eine mehrdimensionale Evaluation jenseits strikter Konformitätsmetriken brauchen @fill2026generative[Abschn. 1]. Das Sonderheft enthält unter anderem eine DSR-Studie zu einem Multi-Agenten-System für die Erhebung von Prozesswissen @fill2026generative.

Verma et al. schlagen mit *GeDSR* eine "generative" Variante des echeloned DSR für KI-Systeme vor, die sich innerhalb ethischer Grenzen selbst mitgestalten, prüfen und weiterentwickeln @verma2026toward. Vier Ebenen bzw. Prinzipien (verantwortliche Autonomie, Selbsterklärbarkeit, KI-Bootstrapping, wissensinformiertes maschinelles Lernen) werden jeweils mit Artefakten und Gate-Evidenz versehen und auf EU AI Act, NIST AI RMF und ISO/IEC 42001 abgebildet. Die Autoren betonen, es handle sich um "a framework rather than a full architecture", und KI-Systemen werde keine Handlungsfähigkeit (_agency_) zugeschrieben @verma2026toward. Eine empirische Validierung ist in den verifizierten Teilen nicht berichtet; die Arbeit taugt als Diskussionsstück darüber, wo "KI gestaltet sich selbst" endet und die Verantwortung der Forschenden beginnt.

=== Studien: LLM-Artefakte als Gegenstand von DSR

Die folgenden Studien sind die verifizierten Beispiele aus 2023-2026, an denen sich die Konzepte dieses Kapitels konkret zeigen lassen.

#studie(titel: [Reinhard et al. 2026])[
  *Design.* DSRM nach Peffers et al.; zwei Expertenworkshops ($n = 13$, $n = 12$); Review von 107 experimentellen XAI-Studien (2000-2025); GPT-4-basierter RAG-Prototyp auf einer Telekom-Wissensbasis mit 191 Einträgen, getestet mit RAGAS @es2024ragas; Think-aloud-Evaluation mit $n = 8$ erfahrenen GenAI-Nutzenden (Durchschnittsalter 29.9 Jahre, rund 45 min) @reinhard2026design[Abschn. 3, 5, Tab. 1].

  *Befund.* Sieben Designmerkmale, Argumentationstypen zugeordnet, etwa DF1 Referenzen/Quellen, DF2 Quellenzuordnung, DF6 Konfidenzwert aus Kosinus-Ähnlichkeit, DF7 Chain-of-Thought @reinhard2026design[Tab. 2]. Nutzende konzentrierten sich weiterhin vor allem auf die Antwort; das Merkmal "ähnliche Fälle" wurde als am wenigsten intuitiv wahrgenommen; Konfidenzwerte wurden als zu hoch empfunden, was blindes Vertrauen riskiert, mit dem Vorschlag, Konfidenz nur bei Unsicherheit anzuzeigen @reinhard2026design[Abschn. 5].

  *Grenzen.* $n = 8$, keine Domänenprofis, statische Erklärungen, keine quantitative Wirksamkeitsanalyse @reinhard2026design[Abschn. 6]. Eigene Einordnung in FEDS-Begriffen: eher artifiziell (keine Domänenprofis, keine echten Arbeitsaufgaben) und formativ.
]

#studie(titel: [Klievtsova et al. 2023])[
  *Design.* DSR nach vom Brocke und Maedche; Literaturreview; Taxonomie von Anwendungsszenarien; 21 textuelle Prozessbeschreibungen aus 6 Domänen mit je 8-11 BPMN-Modellen von Noviz:innen; PET-Datensatz für Prompt Engineering und Ground Truth; GPT-3, GPT-3.5 und GPT-4; KPIs, Jaccard, Precision, Recall; Befragung mit 40 Teilnehmenden @klievtsova2023conversational. Preprint, Stand: 11. November 2026.

  *Befund.* GPT-4 mit der Prompting-Strategie MER erzeugte 17 von 21 korrekten Modellen (81 %) gegenüber 12 (57 %) mit GV; GPT-3 erzeugte 7 (GV) bzw. 6 (MER) @klievtsova2023conversational[Tab. 17, Abschn. 5.3]. Auf den sieben PET-Fällen erzeugte GPT-4 sechs logisch korrekte Modelle gegenüber sieben bei menschlichen Modellierenden und vier beim automatischen System @klievtsova2023conversational[Tab. 15]; eine Kontrollevaluation ergab durchschnittlich 43 % Genauigkeit @klievtsova2023conversational[Abschn. 5.5]. Nur 52 % der Modelle erhielten für dieselbe Beschreibung über Generierungen hinweg dasselbe Korrektheitslabel @klievtsova2023conversational[Abschn. 5.5]. Kontrollfluss-Jaccard 0.59 (GPT-4) gegenüber 0.47 (Menschen) und 0.58 (automatisch) @klievtsova2023conversational[Tab. 10]; Precision 0.70 gegenüber 0.38 und 0.65 @klievtsova2023conversational[Tab. 11]. In der Befragung wählten 69 % das LLM-generierte Modell gegenüber 19 % das Standardmodell ($p = 0.0001$) @klievtsova2023conversational[Abschn. 5.4].

  *Grenzen.* Trainingsdatenkontamination ist nicht auszuschließen, die Ergebnisse sind eine Momentaufnahme geschlossener Modelle @klievtsova2023conversational[Abschn. 5.5, 5.6]; zwei Genauigkeitswerte (81 % vs. 43 %) je nach Setting; Temperatur und Wiederholungsläufe werden nicht kontrolliert berichtet.
]

#studie(titel: [Brehmer und Buonassisi 2024])[
  *Design.* DSR; ein Lernobjekt zu Passwortsicherheit, erstellt mit ChatGPT Plus (GPT-4); Evaluation mit 31 Bachelorstudierenden auf der fünfstufigen LOES-S-Skala @brehmer2024educators.

  *Befund.* Drei Designprinzipien: Pädagogik zuerst; Prompt Engineering (Data Priming, Personas, Selbstreflexion, iteratives Feedback); LLM-Grenzen berücksichtigen. Rund 130 min mit GenAI gegenüber geschätzten 180-210 min ohne, von zwei Lehrenden geschätzt; die Autoren nennen den Vergleich selbst nicht rigoros. 2 von 24 generierten Quizfragen waren faktisch falsch; rund 5 % des Sprechertexts musste überarbeitet werden. Mittelwerte: Lernen 4.13 (SD 0.922), Engagement 4.13 (SD 0.806), Qualität 4.65 (SD 0.503); Cronbachs $alpha$ = 0.906/0.793/0.624 @brehmer2024educators.

  *Grenzen.* Kleine Stichprobe, subjektive Codierung, keine Kontrollgruppe (letzteres eine eigene Einschätzung). Typischer Schwachpunkt von GenAI-DSR: Effizienzbehauptungen ohne kontrollierten Vergleich.
]

Ergänzend sind ein Modell- und ein Methodenartefakt zu nennen, deren Evaluationsdetails nicht verifiziert sind: eine Referenzarchitektur für GenAI-Systeme, die wesentliche Designentscheidungen hervorhebt, auf acht Designanforderungen gründet und in Konsortialworkshops, Literaturreviews und Experteninterviews entwickelt wurde @grau2025rethinking, sowie der bereits besprochene GenAI-CoP-Prozess @reinhard2025genaicop.

#beispiel(titel: [Was die Zahlen von Klievtsova et al. bedeuten])[
  17 von 21 korrekten Modellen entsprechen $17 / 21 = 0.810$, 12 von 21 entsprechen $0.571$. Der Unterschied zwischen MER und GV beträgt also 5 Modelle oder 23.8 Prozentpunkte. Bei 21 Beschreibungen ist das ein großer, aber unsicherer Unterschied: Ein einzelnes Modell entspricht bereits 4.8 Prozentpunkten. Gleichzeitig erhielten nur 52 % der Modelle über Generierungen hinweg dasselbe Korrektheitslabel @klievtsova2023conversational[Abschn. 5.5]. Wenn das Korrektheitslabel bei fast der Hälfte der Modelle zwischen Generierungen wechselt, kann ein Unterschied von fünf Modellen in einem einzigen Lauf zu einem erheblichen Teil Laufrauschen sein. Die Konsequenz für eigene Studien: Prompting-Strategien nur über mehrere Läufe vergleichen.
]

#hoersaal([Wenn ein Artefakt LLMs evaluiert, wer evaluiert dann das Artefakt?], [
  Diese Frage stellt sich bei Jin et al. ganz konkret: Die Plattform wurde von den Autorinnen und Autoren selbst evaluiert, auch durch Dogfooding, ohne unabhängige Nutzerstudie @jin2026developing. Die Antwort ist dieselbe wie bei jedem Messinstrument: Das Artefakt muss gegen eine unabhängige Referenz validiert werden, etwa gegen menschliche Urteile oder gegen etablierte Instrumente, und die Validierung muss von Personen durchgeführt werden, die nicht die Entwickelnden sind. In FEDS-Begriffen braucht es mindestens eine naturalistische summative Episode mit externen Nutzenden. Kapitel 4 und Kapitel 7 behandeln die Validierung von LLM-Instrumenten und LLM-Bewertern im Detail.
])

== Generative KI als Werkzeug im DSR-Prozess <k02-werkzeug>

=== Drei Rollen der Forschenden

Bevor es um einzelne Aktivitäten geht, lohnt ein Blick auf das Verhältnis zwischen Forschenden und KI. Blohm et al. halten fest, dass generative KI hochwertige Forschung noch nicht allein produzieren kann, und schlagen Mensch-KI-Zusammenarbeit mit drei Rollen vor @blohm2025nextgeneration[Tab. 3]: KI als *Assistent* (Kontrolle über den Output: die Forschenden prüfen Ergebnisse), als *Lehrer* (Verhaltenskontrolle: die Forschenden steuern das Vorgehen) und als *Kollaborateur* (Clan-Kontrolle: geteilte Normen und Werte steuern die Zusammenarbeit). Die Rolle bestimmt die Art der Aufsicht: Je kollaborativer die KI eingesetzt wird, desto weniger lässt sich ihr Beitrag über eine reine Ergebnisprüfung kontrollieren.

Gau et al. schlagen ein exploratives Framework vor, das KI-Unterstützung auf konkrete DSR-Aufgaben abbildet und den wahrscheinlichen Nutzen je Aufgabe bewertet @gau2025aibased. Sie argumentieren, KI könne Erzeugung und Wiederverwendung von Designwissen effizienter und wirksamer machen, der Erfolg hänge aber davon ab, die Fähigkeiten und Grenzen von KI je Aufgabe zu verstehen @gau2025aibased. Die Aufgabenliste und die Bewertungen selbst sind nicht verifiziert.

=== Unterstützung je DSRM-Aktivität

@k02-tab-evidenz ordnet die verifizierte Evidenz den sechs DSRM-Aktivitäten zu. Sie ist bewusst nüchtern: Für einige Aktivitäten gibt es nur konzeptuelle Vorschläge, für die Kommunikation wurde keine eigene verifizierte Studie gefunden.

#figure(
  {
    set text(size: 7.9pt)
    table(
    columns: (18mm, 1.5fr, 1fr),
    table.header([Aktivität], [Dokumentierte GenAI-Unterstützung (Evidenzart)], [Hauptrisiko]),
    [1 Problem], [Vorschläge für Aspekte einer DSR-Studie @memmert2023humanai (Befragung, $n = 33$); Nutzerbedürfnisse aus unstrukturierten Daten @blohm2025nextgeneration[Tab. 1] (konzeptuell); Zugang zu Designwissen @gau2025facilitating (Prototyp, formativ); latentes Designwissen ausgraben @strohmann2026making (Demonstration, Expertenvalidierung)], [erfundene Quellen @gau2025facilitating, oberflächliche Problemrahmung, Übervertrauen @memmert2023learning],
    [2 Ziele], [simulierte Nutzende zur Anforderungserhebung @blohm2025nextgeneration[Tab. 1]; vorläufige Anforderungen, von Menschen verfeinert @fill2026generative[Abschn. 1] (beides konzeptuell)], [synthetische Nutzende nicht gegen reale validiert @blohm2025nextgeneration[S. 110-111]],
    [3 Design], [Entwürfe für Designprinzipien @bohmer2025should (Befragung); UML-Designsynthese @iftikhar2026reliability (kontrollierte Experimente); Prozessmodelle @klievtsova2023conversational (Benchmark, Befragung); Prototyping, Coding @blohm2025nextgeneration[Tab. 1]; Artefaktinhalte @brehmer2024educators], [Nichtdeterminismus, Promptsensitivität, Unterschiede in der Handlungsorientierung],
    [4 Demonstration], [schnelles Prototyping von Instanziierungen @blohm2025nextgeneration[Tab. 1] (konzeptuell)], [Demonstration an ausgewählten Glanzbeispielen],
    [5 Evaluation], [strukturelle Metriken gegen Referenzmodelle @klievtsova2023conversational; RAGAS @reinhard2026design[Abschn. 5]; psychometrische LLM-Evaluation @jin2026developing (Experimente, Think-aloud)], [eine einzige Ground Truth @fill2026generative; Kontamination; Selbstevaluation],
    [6 Kommuni- kation], [keine verifizierte eigene Studie; Anleitung zur Artikulation der Fundierung @zurheiden2026design (Literaturreview)], [Offenlegung von Modell, Version, Prompts nicht standardisiert],
  )},
  caption: [Evidenzkarte: GenAI-Unterstützung je DSRM-Aktivität nach @peffers2007design, Stand der verifizierten Literatur 2023-2026 (Dossier zu Foliensatz 02).],
) <k02-tab-evidenz>

=== Aktivitäten 1 und 2: Problem und Ziele

Die frühesten Studien zur LLM-Unterstützung in DSR stammen aus der GPT-3-Ära und betreffen das Konzipieren von DSR-Studien.

#studie(titel: [Memmert, Cvetkovic und Bittner 2023])[
  *Design.* Auszüge aus einer publizierten DSR-Studie; GPT-3 generierte Vorschläge zu Aspekten der Studie; eine Befragung mit $n = 33$ bewertete die Hilfreichkeit @memmert2023humanai.

  *Befund.* Die Vorschläge wurden überwiegend als hilfreich bewertet; die Bewertungen variierten mit der Expertise; hohes Interesse an künftiger Nutzung @memmert2023humanai.

  *Grenzen.* Eine einzige Ausgangsstudie, GPT-3, gemessen wurde wahrgenommene Hilfreichkeit, nicht die Qualität der resultierenden Forschung. Detailzahlen je Aspekt sind nicht verifiziert.
]

#studie(titel: [Memmert, Tavanapour und Bittner 2023])[
  *Design.* DSR-Projekt zum Entwurf eines GPT-3-basierten Werkzeugs, das Studierenden beim Konzipieren einer DSR-Studie inhaltliche Vorschläge macht; Anforderungen und Prinzipien aus der Scaffolding-Literatur; 13 Experteninterviews (7 Doktorierende, 3 Postdocs, 3 Professorinnen bzw. Professoren; 28-55 min; 8 Universitäten in 4 Ländern) @memmert2023learning.

  *Befund.* Sieben Probleme von Studierenden (I1-I7) und sieben Designprinzipien (DP1-DP7: übergreifende Struktur, inhaltliche Unterstützung, Integration von Vorschlägen, rechtzeitige Information, Abdeckungsunterstützung, Beziehungsvorschläge, Formulierungsunterstützung). Die häufigste Sorge der Expertinnen und Experten war unbeabsichtigte Nutzung: Studierende übernehmen Vorschläge ohne Reflexion; Gegenmaßnahmen sind Reflexionsphasen und das Kennzeichnen KI-generierter Elemente @memmert2023learning.

  *Grenzen.* Das Werkzeug wurde weder technisch implementiert noch mit Studierenden getestet.
]

Für die Wissensbasis, also den Rigorzyklus, gibt es zwei neuere Ansätze. Gau und Gnewuch entwickeln in einem ersten DSR-Zyklus einen GenAI-Gesprächsassistenten, der DSR-Forschenden hilft, Designwissen zu erkunden und wiederzuverwenden, und dabei das Erfinden von Inhalten und schwache Erklärungen generischer Assistenten adressiert; die Ergebnisse der formativen Evaluation sind nicht verifiziert @gau2025facilitating. Strohmann et al. stellen mit *AIDE* eine Human-in-the-Loop-Pipeline vor, die implizites Designwissen aus Nicht-DSR-Publikationen extrahiert und formalisiert; demonstriert an einem interdisziplinären Korpus zu KI-gestützter Kreislaufwirtschaft, mit einem rekonstruierten Designprinzip pro Studie und Expertenvalidierung @strohmann2026making. Dieser Ansatz adressiert direkt die schwach kumulative Wissensbasis, die Wagner et al. gefunden haben @wagner2021exploring[Abschn. 6.2].

=== Aktivität 3: Design und Entwicklung

Hier ist die Evidenz am dichtesten, weil sich generierte Designartefakte vergleichsweise gut messen lassen. Neben den bereits besprochenen Studien zu Designprinzipien @bohmer2025should und Prozessmodellen @klievtsova2023conversational ist die Arbeit von Iftikhar und Rausch methodisch die wichtigste.

#studie(titel: [Iftikhar und Rausch 2026])[
  *Design.* Können LLMs Designsynthese leisten, also UML-Klassendiagramme nach OO-Prinzipien und Entwurfsmustern erzeugen, und wie stabil ist ihr Designdenken unter Prompt-Paraphrasen und Wiederholung? 2 Design-Intent-Benchmarks × 3 paraphrasierte Prompts × 10 Läufe × 3 LLMs (GPT-4o-mini, Claude 3.5 Sonnet, Gemini 2.5 Flash) × 3 Strategien (Standard, Regelinjektion, präferenzbasiertes Few-Shot) = 540 Experimente; Temperatur 0.5 @iftikhar2026reliability[Abschn. III]. Laut Institut der Autoren auf der IEEE ICSA 2026 angenommen; zitiert wird die arXiv-Fassung (Stand: 11. November 2026).

  *Befund.* Präferenzbasiertes Prompting verbessert die Einhaltung der Designintention, beseitigt aber den Nichtdeterminismus nicht; die Modellwahl beeinflusst die Zuverlässigkeit stark @iftikhar2026reliability. Stability Index: Claude 0.77 (Standard) gegenüber 1 (andere Strategien), GPT-4o-mini 1 unter allen Strategien, Gemini etwa 0.905-0.907 @iftikhar2026reliability[Tab. XV]. Das Observer-Muster erhielt im Sensor-Network-Benchmark für alle Modelle und Strategien den Wert 0 @iftikhar2026reliability[Tab. XII-XIV].

  *Grenzen.* Zwei Domänen, manuelle Expertenbewertung, kleine synthetische Präferenzmenge (5 Beispiele) @iftikhar2026reliability[Abschn. IV.C, VI]; Text und Tab. XV sind teilweise widersprüchlich in der Frage, welches Modell am stabilsten ist; die Varianzschätzung für den Stability Index ist nicht spezifiziert.
]

=== Aktivitäten 4 bis 6: Demonstration, Evaluation, Kommunikation

Für die Demonstration nennen Blohm et al. schnelles Prototyping @blohm2025nextgeneration[Tab. 1]. Das Risiko ist offensichtlich: Wer mit generativer KI schnell viele Varianten erzeugt, kann ebenso schnell die gelungenste auswählen und als Demonstration präsentieren. Für die Evaluation gibt es Werkzeuge wie RAGAS @es2024ragas, das Reinhard et al. zum Test ihres Prototyps nutzen @reinhard2026design[Abschn. 5], sowie strukturelle Metriken gegen Referenzmodelle @klievtsova2023conversational, die der nächste Abschnitt formal behandelt. Für die Kommunikation wurde keine verifizierte empirische Arbeit gefunden; das einzige gefundene DSR-Dokumentationswerkzeug, DSR Buddy, ein Gesprächsagenten-Prototyp zum Dokumentieren von DSR-Aktivitäten, stammt aus der Zeit vor LLM-basierten Assistenten und wird nicht als GenAI-basiert beschrieben @gau2022dsr. Das ist eine echte Forschungslücke.

#fallstrick[
  Die Forschenden-Rolle "Assistent mit Outputkontrolle" @blohm2025nextgeneration[Tab. 3] funktioniert nur, wenn die Prüfenden die Ergebnisse auch beurteilen können. Ein LLM, das Designprinzipien für eine Domäne vorschlägt, die du nicht kennst, ist faktisch ein Kollaborateur ohne Kontrolle. Die von Memmert et al. befürchtete unreflektierte Übernahme @memmert2023learning ist keine Charakterschwäche, sondern die erwartbare Folge, wenn die Kontrollform nicht zur Rolle passt.
]

=== Im Fallbeispiel

Bei KoDa wird generative KI auf zwei Ebenen eingesetzt, die sauber getrennt werden müssen. *Im Artefakt* erzeugt das LLM Codevorschläge; das ist Gegenstand der Evaluation. *Im Forschungsprozess* hilft ein LLM beim Entwerfen von Prompt-Paraphrasen (Aktivität 3) und beim Programmieren der Auswerteskripte. Beides wird im LLM-Log dokumentiert (Modell, Version, Datum, Zugangsweg, Parameter, vollständiger Prompt), so wie es Übung 02 der LV verlangt. Die Designprinzipien selbst formuliert das Team ohne LLM; ein LLM-Entwurf dient anschließend nur als Gegenprobe, ob ein Slot des Schemas vergessen wurde.

== Messung LLM-basierter Artefakte <k02-messung>

DSR selbst ist keine statistische Methode; ihre "Formeln" sind Schablonen und Entscheidungsregeln. Sobald das Artefakt aber ein LLM enthält oder ein LLM ein Designartefakt erzeugt, werden artefaktbezogene Metriken unverzichtbar. Dieser Abschnitt behandelt drei Fragen: Ist das erzeugte Artefakt strukturell korrekt? Hält es sich an Designregeln? Und wie stabil ist es über Paraphrasen und Läufe? Alle Metriken stammen aus den zitierten Quellen; Herleitungen und Rechenbeispiele sind eigene Ausarbeitungen.

=== Strukturelle Korrektheit gegen eine Referenz

Klievtsova et al. vergleichen LLM-generierte Prozessmodelle mit Referenzmodellen, indem sie jedes Modell in eine Menge von Kanten überführen, also 3-Tupel als geordnete Folge von BPMN-Objekten @klievtsova2023conversational[Abschn. 5.2.2]. Iftikhar und Rausch verwenden dieselbe Precision-Recall-Logik für Elemente von UML-Klassendiagrammen @iftikhar2026reliability[Abschn. III].

#definition(titel: [Precision, Recall, $F_1$, Jaccard für Artefaktelemente])[
  Sei $G$ die Menge der Elemente (etwa Kanten) des generierten Artefakts und $R$ die Menge der Elemente des Referenzartefakts. Dann ist $"TP" = |G inter R|$ die Zahl der generierten Elemente, die auch in der Referenz vorkommen, $"FP" = |G without R|$ die Zahl der generierten Elemente, die nicht in der Referenz vorkommen, und $"FN" = |R without G|$ die Zahl der Referenzelemente, die nicht generiert wurden. Damit
  $ "Precision" = "TP" / ("TP" + "FP"), quad "Recall" = "TP" / ("TP" + "FN"), quad F_1 = (2 dot "Precision" dot "Recall") / ("Precision" + "Recall") $ <k02-eq-prf>
  @klievtsova2023conversational[Abschn. 5.2.2] @iftikhar2026reliability[Abschn. III] sowie den Jaccard-Index als reihenfolgeunabhängige Mengenähnlichkeit @klievtsova2023conversational[Abschn. 5.2.2]
  $ J(G, R) = (|G inter R|) / (|G union R|). $ <k02-eq-jaccard>
]

Die Quelle druckt die Jaccard-Formel nicht in der TP/FP/FN-Form; die folgende Umformung und der Zusammenhang mit $F_1$ sind Standardmengenlehre.

#satz(titel: [Jaccard und $F_1$])[
  Für endliche Mengen $G$, $R$ mit $G union R != emptyset$ gilt
  $ J = "TP" / ("TP" + "FP" + "FN"), quad F_1 = (2 "TP") / (2 "TP" + "FP" + "FN"), quad J = F_1 / (2 - F_1), quad J <= F_1. $ <k02-eq-jf1>
]

#beweis[
  Die Mengen $G inter R$, $G without R$ und $R without G$ sind paarweise disjunkt und vereinigen sich zu $G union R$. Also $|G union R| = "TP" + "FP" + "FN"$, und mit @k02-eq-jaccard folgt die erste Gleichung. Für $F_1$ setze $P = "TP" / ("TP" + "FP")$ und $R_c = "TP" / ("TP" + "FN")$ ein. Der harmonische Mittelwert ergibt
  $ F_1 = 2 / (1 / P + 1 / R_c) = 2 / (("TP" + "FP") / "TP" + ("TP" + "FN") / "TP") = (2 "TP") / (2 "TP" + "FP" + "FN"). $
  Mit der Abkürzung $f = "FP" + "FN"$ ist $J = "TP" / ("TP" + f)$ und $F_1 = 2 "TP" / (2 "TP" + f)$. Dann
  $ F_1 / (2 - F_1) = (2 "TP") / (2 (2 "TP" + f) - 2 "TP") = (2 "TP") / (2 "TP" + 2 f) = "TP" / ("TP" + f) = J. $
  Schließlich ist $g(F) = F / (2 - F)$ auf $[0, 1]$ wegen $2 - F >= 1$ nie größer als $F$, also $J <= F_1$, mit Gleichheit genau für $F_1 in {0, 1}$.
]

Der Satz hat eine praktische Konsequenz: Jaccard und $F_1$ enthalten dieselbe Information, sie sind streng monoton ineinander umrechenbar. Wer beide berichtet, berichtet eine Zahl zweimal. Jaccard ist strenger, weil sie Fehler beider Art im Nenner voll zählt, während $F_1$ die Treffer doppelt gewichtet.

#beispiel(titel: [Ein generiertes Prozessmodell bewerten])[
  Ein generiertes BPMN-Modell hat $|G| = 10$ Kanten, die Referenz $|R| = 9$, und $|G inter R| = 7$. Dann ist $"TP" = 7$, $"FP" = 10 - 7 = 3$, $"FN" = 9 - 7 = 2$ und
  $ "Precision" = 7 / 10 = 0.700, quad "Recall" = 7 / 9 = 0.778, quad F_1 = (2 dot 7) / (14 + 5) = 14 / 19 = 0.737, quad J = 7 / 12 = 0.583. $
  Kontrolle mit @k02-eq-jf1: $0.737 / (2 - 0.737) = 0.583$. Zum Vergleich die berichteten Werte bei Klievtsova et al.: GPT-4 erreichte mit dem besten Prompt einen Kontrollfluss-Jaccard von 0.59 gegenüber 0.47 bei Noviz:innen und 0.58 beim automatischen System, und eine Precision von 0.70 gegenüber 0.38 und 0.65 @klievtsova2023conversational[Tab. 10-11].

  *Im Fallbeispiel* lässt die Forschungsgruppe KoDa aus 200 Antworten einer Pilotwelle ein Codebuch vorschlagen und vergleicht es mit dem Codebuch der Expertinnen (fiktive Zahlen): KoDa schlägt 12 Codes vor, das Expertencodebuch hat 10, übereinstimmend sind 8. Also Precision $8 / 12 = 0.667$, Recall $8 / 10 = 0.800$, $F_1 = 16 / 22 = 0.727$, $J = 8 / 14 = 0.571$.
]

#fallstrick[
  Die Referenzmetrik setzt voraus, dass es *eine* richtige Lösung gibt. Fill et al. weisen darauf hin, dass eine Evaluation gegen ein ideales Expertenmodell implizit eine einzige Ground Truth annimmt und valide alternative Designs bestraft @fill2026generative[Abschn. 1]. Im Fallbeispiel: Wenn KoDa "Phishing" und "Spear-Phishing" trennt, das Expertencodebuch nicht, zählt das als ein FP und gegebenenfalls ein FN, obwohl die feinere Unterscheidung für manche Forschungsfragen besser sein kann. Ergänze daher Referenzmetriken um eine Expertenbeurteilung abweichender Elemente.
]

=== Einhaltung von Designregeln

Iftikhar und Rausch definieren für LLM-generierte UML-Designs zwei Adhärenzmaße @iftikhar2026reliability[Abschn. III]:

$ "PAS" = (\#"erfüllte Regeln") / (\#"geprüfte Regeln"), quad "PES" = (\#"angewandte Muster") / (\#"geprüfte Muster"), $ <k02-eq-pas>

wobei jede Regel bzw. jedes Muster mit 0, 0.5 (teilweise) oder 1 bewertet wird. PAS (_principle adherence score_) misst die Einhaltung von Designprinzipien, PES (_pattern_) die Anwendung von Entwurfsmustern. Die Maße sind einfach, aber ihre Güte hängt vollständig an der Bewertung: Wer bewertet, nach welcher Rubrik, und wie stimmen mehrere Bewertende überein? Iftikhar und Rausch bewerten manuell durch Expertinnen und Experten @iftikhar2026reliability[Abschn. VI]; die Übereinstimmung zwischen Bewertenden ist ein Thema von Kapitel 5.

=== Stabilität über Paraphrasen und Läufe

Ein LLM-Artefakt liefert für dieselbe Eingabe nicht immer dieselbe Ausgabe, und schon eine Umformulierung des Prompts kann das Ergebnis verändern. Iftikhar und Rausch fassen beides in einem *Stability Index* zusammen @iftikhar2026reliability[Abschn. III]:

$ "SI" = 1 / (1 + (sigma^2_"prompt" + sigma^2_"run")), $ <k02-eq-si>

wobei $sigma^2_"prompt"$ die Varianz über paraphrasierte Prompts und $sigma^2_"run"$ die Varianz über wiederholte Läufe ist; $"SI" = 1$ bedeutet vollständige Stabilität. Die Arbeit spezifiziert nicht, wie die beiden Varianzen geschätzt werden @iftikhar2026reliability[Abschn. III]. Für Übungen schlägt das Dossier der LV eine transparente Operationalisierung vor, die hier übernommen und anschließend analysiert wird.

#definition(titel: [Varianzkomponenten eines Wiederholungsdesigns])[
  Sei $x_(p r)$ der Score (etwa $F_1$) für Paraphrase $p = 1, dots, P$ und Lauf $r = 1, dots, R$. Mit den Paraphrasenmitteln $macron(x)_(p dot) = 1/R sum_r x_(p r)$ und dem Gesamtmittel $macron(x)_(dot dot) = 1/P sum_p macron(x)_(p dot)$ setze
  $ sigma^2_"prompt" = 1/P sum_(p=1)^P (macron(x)_(p dot) - macron(x)_(dot dot))^2, quad sigma^2_"run" = 1/P sum_(p=1)^P 1/R sum_(r=1)^R (x_(p r) - macron(x)_(p dot))^2. $ <k02-eq-varkomp>
  $sigma^2_"prompt"$ ist die (Populations-)Varianz der Paraphrasenmittel, $sigma^2_"run"$ die mittlere Varianz innerhalb der Paraphrasen.
]

Diese Operationalisierung hat eine schöne Eigenschaft: Die beiden Komponenten addieren sich genau zur Gesamtvarianz aller $P R$ Scores. Das ist die Stichprobenversion des Satzes von der totalen Varianz.

#satz(titel: [Varianzzerlegung im balancierten Design])[
  Mit der Gesamtvarianz $sigma^2_"ges" = 1/(P R) sum_(p, r) (x_(p r) - macron(x)_(dot dot))^2$ gilt
  $ sigma^2_"ges" = sigma^2_"prompt" + sigma^2_"run". $ <k02-eq-zerlegung>
]

#beweis[
  Schreibe $x_(p r) - macron(x)_(dot dot) = (x_(p r) - macron(x)_(p dot)) + (macron(x)_(p dot) - macron(x)_(dot dot))$ und quadriere:
  $ sum_(p, r) (x_(p r) - macron(x)_(dot dot))^2 = sum_(p, r) (x_(p r) - macron(x)_(p dot))^2 + R sum_p (macron(x)_(p dot) - macron(x)_(dot dot))^2 + 2 sum_p (macron(x)_(p dot) - macron(x)_(dot dot)) sum_r (x_(p r) - macron(x)_(p dot)). $
  Die innere Summe im letzten Term ist null, weil sich Abweichungen vom Paraphrasenmittel innerhalb einer Paraphrase zu null summieren. Division durch $P R$ liefert links $sigma^2_"ges"$ und rechts $sigma^2_"run" + sigma^2_"prompt"$ nach @k02-eq-varkomp.
]

Daraus folgt eine zweite, weniger offensichtliche Eigenschaft, die erklärt, warum der Stability Index auf beschränkten Scores fast immer nahe 1 liegt.

#satz(titel: [Untere Schranke des Stability Index])[
  Liegen alle Scores in $[0, 1]$ und werden die Varianzen wie in @k02-eq-varkomp geschätzt, dann gilt $sigma^2_"prompt" + sigma^2_"run" <= 1/4$ und damit
  $ 0.8 <= "SI" <= 1. $ <k02-eq-schranke>
]

#beweis[
  Nach @k02-eq-zerlegung ist die Summe der Komponenten die Populationsvarianz von $P R$ Werten in $[0, 1]$. Für eine Zufallsgröße $X in [a, b]$ gilt $"Var"(X) = min_c EE[(X - c)^2] <= EE[(X - (a+b)/2)^2] <= ((b - a)/2)^2$, denn der Erwartungswert minimiert die mittlere quadratische Abweichung, und jeder Wert liegt höchstens $(b-a)/2$ von der Intervallmitte entfernt (Ungleichung von Popoviciu). Angewendet auf die empirische Verteilung mit $a = 0$, $b = 1$ folgt $sigma^2_"ges" <= 1/4$, also $"SI" >= 1 / (1 + 1/4) = 0.8$. Die obere Schranke folgt aus $sigma^2 >= 0$.
]

Die Schranke ist mehr als eine Kuriosität. Sie zeigt, dass ein SI von 0.95 auf einer [0,1]-Skala bereits eine sehr große Streuung bedeutet: $"SI" = 0.95$ entspricht $sigma^2_"ges" = 1/0.95 - 1 = 0.0526$, also einer Standardabweichung von 0.23 auf einer Skala von 0 bis 1. Iftikhar und Rausch berichten für Claude 3.5 Sonnet unter Standard-Prompting $"SI" = 0.77$ @iftikhar2026reliability[Tab. XV], also einen Wert *unterhalb* der Schranke. Unter der Operationalisierung @k02-eq-varkomp ist das mit Scores in $[0, 1]$ unmöglich; die Arbeit muss also eine andere Skala oder andere Schätzer verwendet haben, etwa Stichprobenvarianzen mit Nenner $n - 1$. Mit diesen läge eine untere Schranke bei $P = 3$, $R = 10$ nur noch bei $1 / (1 + 3/8 + 10/36) = 0.605$, weil die Stichprobenvarianz von $n$ Werten in $[0, 1]$ höchstens $n / (4(n-1))$ beträgt. Genau deshalb ist die fehlende Spezifikation der Varianzschätzung keine Formalie: Ohne sie lässt sich ein SI-Wert nicht interpretieren.

#beispiel(titel: [Stability Index aus dem Dossier nachrechnen])[
  $P = 3$ Paraphrasen, $R = 10$ Läufe, $F_1$-Scores mit Paraphrasenmitteln 0.50, 0.55 und 0.45; mittlere Varianz innerhalb der Paraphrasen $sigma^2_"run" = 0.01$. Das Gesamtmittel ist 0.50, also
  $ sigma^2_"prompt" = ((0)^2 + (0.05)^2 + (-0.05)^2) / 3 = 0.005 / 3 = 0.00167, quad "SI" = 1 / (1 + 0.00167 + 0.01) = 0.988. $
  Die Standardabweichungen sind $sqrt(0.00167) = 0.041$ zwischen den Paraphrasen und $sqrt(0.01) = 0.10$ innerhalb. Ein Lauf-zu-Lauf-Rauschen von 0.10 im $F_1$ ist für die meisten Anwendungen erheblich, der SI von 0.988 suggeriert dagegen fast perfekte Stabilität.
]

#beispiel(titel: [Stabilität von KoDa (fiktive Daten)])[
  KoDa wird mit drei Prompt-Paraphrasen je zehnmal bei Temperatur 0.7 auf dem Goldstandard von 120 Segmenten ausgeführt; Score ist der Makro-$F_1$ je Lauf. Die Paraphrasenmittel sind 0.700, 0.655 und 0.740 (Gesamtmittel 0.698). Aus @k02-eq-varkomp folgen $sigma^2_"prompt" = 0.00121$ (SD 0.035) und $sigma^2_"run" = 0.00068$ (SD 0.026), deren Summe nach @k02-eq-zerlegung genau die Gesamtvarianz 0.00188 ist. Damit ist
  $ "SI" = 1 / (1 + 0.00188) = 0.998. $
  Trotzdem liegt zwischen der schwächsten und der stärksten Paraphrase ein Unterschied von $0.740 - 0.655 = 0.085$ im Makro-$F_1$, also mehr als ein Zehntel des Wertebereichs, den man realistischerweise erwarten kann. Die Wahl der Formulierung beeinflusst das Ergebnis stärker als der Zufall der Läufe ($sigma_"prompt" > sigma_"run"$). Bei Temperatur 0 (fiktiv: alle Läufe je Paraphrase identisch mit 0.70, 0.66 und 0.74) verschwindet $sigma^2_"run"$, aber $sigma^2_"prompt" = 0.00107$ bleibt: Temperatur 0 beseitigt die Promptsensitivität nicht.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let daten = (
      (0.71, 0.68, 0.74, 0.70, 0.66, 0.72, 0.69, 0.73, 0.70, 0.67),
      (0.64, 0.69, 0.62, 0.66, 0.70, 0.63, 0.65, 0.68, 0.61, 0.67),
      (0.75, 0.72, 0.77, 0.73, 0.70, 0.76, 0.74, 0.71, 0.78, 0.74),
    )
    let ymin = 0.58
    let ymax = 0.80
    let H = 5.0
    let sy(v) = (v - ymin) / (ymax - ymin) * H
    let cols = (c-blue, c-accent, c-teal)
    // Achsen
    line((0, 0), (8.2, 0), stroke: 0.7pt + c-dark)
    line((0, 0), (0, H + 0.2), stroke: 0.7pt + c-dark)
    for t in (0.60, 0.65, 0.70, 0.75, 0.80) {
      line((-0.08, sy(t)), (0, sy(t)), stroke: 0.6pt + c-dark)
      line((0, sy(t)), (8.2, sy(t)), stroke: (paint: luma(225), thickness: 0.4pt))
      content((-0.15, sy(t)), anchor: "east", text(font: "Inter", size: 6.8pt, str(t)))
    }
    content((-1.0, H / 2), angle: 90deg, text(font: "Inter", size: 7.5pt)[Makro-$F_1$ je Lauf])
    // Gesamtmittel
    line((0, sy(0.6983)), (8.2, sy(0.6983)), stroke: (paint: c-grey, thickness: 0.8pt, dash: "dashed"))
    content((8.25, sy(0.6983)), anchor: "west", text(font: "Inter", size: 6.6pt, fill: c-grey.darken(20%))[Gesamtmittel 0.698])
    for (p, reihe) in daten.enumerate() {
      let xc = 1.5 + p * 2.6
      let m = reihe.sum() / reihe.len()
      for (r, v) in reihe.enumerate() {
        circle((xc - 0.55 + r * 0.12, sy(v)), radius: 0.06, fill: cols.at(p), stroke: none)
      }
      line((xc - 0.8, sy(m)), (xc + 0.8, sy(m)), stroke: 1.4pt + cols.at(p).darken(15%))
      content((xc, -0.35), text(font: "Inter", size: 7.2pt)[Paraphrase #(p + 1)])
      content((xc + 0.82, sy(m) - 0.18), anchor: "west", text(font: "Inter", size: 6.6pt, fill: cols.at(p).darken(20%), ("0.700", "0.655", "0.740").at(p)))
    }
    // Klammer für Spanne der Mittel
    content((4.1, -0.9), text(font: "Inter", size: 6.8pt, fill: c-dark)[Spanne der Mittel 0.085; $sigma_"prompt"$ = 0.035; $sigma_"run"$ = 0.026; SI = 0.998])
  }),
  caption: [Wiederholungsdesign im Fallbeispiel (fiktive Daten): je zehn Läufe für drei Prompt-Paraphrasen. Querbalken = Paraphrasenmittel. Der Stability Index von 0.998 verdeckt eine Spanne von 0.085 zwischen den Paraphrasen.],
) <k02-abb-laeufe>

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let W = 9.0
    let H = 4.6
    let xmax = 0.30
    let ymin = 0.75
    let sx(v) = v / xmax * W
    let sy(v) = (v - ymin) / (1.0 - ymin) * H
    line((0, 0), (W + 0.2, 0), stroke: 0.7pt + c-dark)
    line((0, 0), (0, H + 0.2), stroke: 0.7pt + c-dark)
    for t in (0.0, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30) {
      line((sx(t), -0.08), (sx(t), 0), stroke: 0.6pt + c-dark)
      content((sx(t), -0.3), text(font: "Inter", size: 6.8pt, str(t)))
    }
    for t in (0.75, 0.80, 0.85, 0.90, 0.95, 1.0) {
      line((-0.08, sy(t)), (0, sy(t)), stroke: 0.6pt + c-dark)
      line((0, sy(t)), (W, sy(t)), stroke: (paint: luma(228), thickness: 0.4pt))
      content((-0.15, sy(t)), anchor: "east", text(font: "Inter", size: 6.8pt, str(t)))
    }
    content((W / 2, -0.8), text(font: "Inter", size: 7.5pt)[$sigma^2_"prompt" + sigma^2_"run"$ (Gesamtvarianz)])
    content((-1.0, H / 2), angle: 90deg, text(font: "Inter", size: 7.5pt)[Stability Index])
    // zulässiger Bereich für [0,1]-Scores
    rect((sx(0.25), 0), (sx(0.30), H), fill: c-red.lighten(90%), stroke: none)
    content((sx(0.275), sy(0.97)), align(center, text(font: "Inter", size: 6.4pt, fill: c-red.darken(10%))[unmöglich \ für Scores \ in [0, 1]]))
    // Kurve
    let pts = range(0, 61).map(i => { let v = i * 0.005; (sx(v), sy(1 / (1 + v))) })
    line(..pts, stroke: 1.3pt + c-blue)
    // Markierungen
    let mark(v, lab, col, ly) = {
      let s = 1 / (1 + v)
      circle((sx(v), sy(s)), radius: 0.08, fill: col, stroke: none)
      line((sx(v), sy(s)), (sx(0.085), sy(ly)), stroke: 0.4pt + col)
      content((sx(0.088), sy(ly)), anchor: "west", text(font: "Inter", size: 6.6pt, fill: col.darken(15%), lab))
    }
    mark(0.00188, [KoDa: SI = 0.998], c-teal, 0.995)
    mark(0.01167, [Dossier-Beispiel: SI = 0.988], c-accent, 0.978)
    mark(0.0526, [SI = 0.95 entspricht SD 0.23], c-violet, 0.961)
    circle((sx(0.25), sy(0.8)), radius: 0.08, fill: c-red, stroke: none)
    content((sx(0.25) - 0.15, sy(0.8) - 0.22), anchor: "east", text(font: "Inter", size: 6.6pt, fill: c-red.darken(15%))[Schranke 0.8])
    line((0, sy(0.77)), (W, sy(0.77)), stroke: (paint: c-yellow, thickness: 0.8pt, dash: "dashed"))
    content((sx(0.01), sy(0.77) + 0.2), anchor: "west", text(font: "Inter", size: 6.6pt, fill: c-yellow.darken(25%))[berichtet: Claude 3.5 Sonnet, Standard, 0.77 @iftikhar2026reliability])
  }),
  caption: [Stability Index $1 / (1 + sigma^2)$ als Funktion der Gesamtvarianz. Für Scores in $[0, 1]$ und Populationsvarianzen ist $sigma^2 <= 1/4$, also $"SI" >= 0.8$ nach @k02-eq-schranke. Der berichtete Wert 0.77 ist nur mit anderer Skala oder anderen Schätzern möglich.],
) <k02-abb-si>

#merke[
  Berichte bei stochastischen Artefakten nicht nur einen verdichteten Index, sondern die Komponenten: Mittel je Paraphrase, $sigma_"prompt"$ und $sigma_"run"$ (als Standardabweichungen in der Einheit des Scores), Anzahl der Paraphrasen und Läufe, Temperatur und weitere Parameter, Modellversion und Datum. Das Dossier zur LV formuliert es so: Die beiden Varianzkomponenten getrennt zu berichten ist informativer als der SI.
]

=== Lauf-zu-Lauf-Übereinstimmung von Labels

Klievtsova et al. berichten, dass nur 52 % der generierten Modelle für dieselbe Prozessbeschreibung über Generierungen hinweg dasselbe Korrektheitslabel erhielten @klievtsova2023conversational[Abschn. 5.5]. Eine einfache Formalisierung für Übungen ist die rohe Übereinstimmung

$ A = 1/N sum_(i=1)^N bb(1)[ell_i^((1)) = ell_i^((2))], $ <k02-eq-agree>

wobei $N$ die Zahl der Eingaben, $ell_i^((k))$ das Label der $k$-ten Generierung für Eingabe $i$ und $bb(1)[dot]$ die Indikatorfunktion ist. Im Fallbeispiel vergibt KoDa in zwei Läufen für 103 von 120 Segmenten denselben Code, also $A = 103 / 120 = 0.858$ (fiktiv). Diese rohe Übereinstimmung korrigiert nicht für Zufall: Bei einem dominanten Code wäre auch zufälliges Raten oft übereinstimmend. Zufallskorrigierte Maße der Kappa-Familie behandelt Kapitel 5.

=== Umsetzung in Python

Das folgende Skript berechnet die Größen des KoDa-Beispiels. Es ersetzt das fehlende Notebook zu Foliensatz 02 und entspricht den Aufgaben 2 und 3 der Übung 02.

#datei("stabilitaet.py")[
```python
import numpy as np

# Makro-F1 je Lauf: 3 Prompt-Paraphrasen x 10 Läufe (fiktive Daten KoDa)
x = np.array([
    [0.71, 0.68, 0.74, 0.70, 0.66, 0.72, 0.69, 0.73, 0.70, 0.67],
    [0.64, 0.69, 0.62, 0.66, 0.70, 0.63, 0.65, 0.68, 0.61, 0.67],
    [0.75, 0.72, 0.77, 0.73, 0.70, 0.76, 0.74, 0.71, 0.78, 0.74],
])
mittel_p = x.mean(axis=1)                 # Mittel je Paraphrase
var_prompt = mittel_p.var()               # Varianz der Paraphrasenmittel (ddof=0)
var_run = x.var(axis=1).mean()            # mittlere Varianz innerhalb (ddof=0)
si = 1 / (1 + var_prompt + var_run)

print("Mittel je Paraphrase:", mittel_p.round(3))
print(f"var_prompt = {var_prompt:.5f}  (SD {np.sqrt(var_prompt):.3f})")
print(f"var_run    = {var_run:.5f}  (SD {np.sqrt(var_run):.3f})")
print(f"Summe      = {var_prompt + var_run:.5f}  Gesamtvarianz = {x.var():.5f}")
print(f"SI         = {si:.4f}")

# Lauf-zu-Lauf-Übereinstimmung zweier Läufe auf 120 Segmenten
gleich = 103
print(f"A = {gleich / 120:.3f}")
```
]

```out
Mittel je Paraphrase: [0.7   0.655 0.74 ]
var_prompt = 0.00121  (SD 0.035)
var_run    = 0.00068  (SD 0.026)
Summe      = 0.00188  Gesamtvarianz = 0.00188
SI         = 0.9981
A = 0.858
```

Die Zeile "Summe = Gesamtvarianz" ist die numerische Bestätigung von @k02-eq-zerlegung. Wer `ddof=1` setzt, erhält andere Werte und verliert die exakte Zerlegung; beides ist vertretbar, muss aber berichtet werden.

#hoersaal([Warum nicht einfach Temperatur 0 setzen und das Problem ist gelöst?], [
  Aus drei Gründen. Erstens beseitigt Temperatur 0 nur $sigma^2_"run"$, nicht $sigma^2_"prompt"$; das Rechenbeispiel zu KoDa zeigt, dass die Promptsensitivität der größere Anteil sein kann. Zweitens ist auch bei Temperatur 0 nicht garantiert, dass ein über eine API angebotenes Modell bitgenau dieselbe Ausgabe liefert; ob das für dein Modell gilt, musst du messen, nicht annehmen. Drittens ändert Temperatur 0 das Artefakt: Wenn KoDa im Einsatz mit Temperatur 0.7 läuft, evaluierst du mit Temperatur 0 ein anderes System. Die Übung 02 verlangt deshalb Läufe bei Temperatur 0 *und* einer Temperatur über 0.
])

== Risiken und gute Praxis <k02-risiken>

=== Validitätsbedrohungen bei GenAI in DSR

Die bisher besprochenen Studien zeigen ein wiederkehrendes Muster von Bedrohungen. @k02-tab-bedrohungen fasst sie zusammen; jede Zeile ist mit einer Quelle belegt, in der die Bedrohung beobachtet oder benannt wurde.

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    table.header([Bedrohung], [Beschreibung], [Beleg]),
    [Nichtdeterminismus, Promptsensitivität], [gleiche Eingabe, andere Ausgabe; Paraphrasen ändern Ergebnisse], [SI < 1 für manche Modelle und Strategien @iftikhar2026reliability[Tab. XV]; 52 % Label-Übereinstimmung @klievtsova2023conversational[Abschn. 5.5]],
    [Datenkontamination], [Benchmark (etwa PET) könnte in den Trainingsdaten sein], [@klievtsova2023conversational[Abschn. 5.5]; als Problem der LLM-Evaluation benannt @jin2026developing],
    [eine einzige Ground Truth], [Referenzmetriken bestrafen valide alternative Designs], [@fill2026generative[Abschn. 1]],
    [Momentaufnahme geschlossener Modelle], [Ergebnisse hängen an proprietären Modellversionen], [@klievtsova2023conversational[Abschn. 5.6]; @fill2026generative[Abschn. 1]],
    [Übervertrauen], [Nutzende übernehmen KI-Vorschläge ohne Reflexion], [@memmert2023learning; überhöhte Konfidenzhinweise @reinhard2026design[Abschn. 5]],
    [Selbstevaluation], [Entwickelnde evaluieren ihr eigenes Artefakt], [Dogfooding @jin2026developing],
    [schwache Effizienzbehauptungen], [Zeitersparnis geschätzt statt kontrolliert gemessen], [@brehmer2024educators],
    [Faktenfehler im generierten Inhalt], [Fehler in Artefaktinhalten, die GenAI erzeugt hat], [2 von 24 Quizfragen falsch @brehmer2024educators],
    [synthetische Nutzende und Daten], [Validität simulierter Stakeholder unbekannt], [@blohm2025nextgeneration[S. 110-111]],
    [undurchsichtige Artefaktzusammensetzung], [unklare Grenze des Artefakts], [@zurheiden2026design],
  ),
  caption: [Validitätsbedrohungen bei generativer KI in DSR mit Belegen (Dossier zu Foliensatz 02).],
) <k02-tab-bedrohungen>

=== Modelle verschwinden

Die Bedrohung "Momentaufnahme geschlossener Modelle" ist keine theoretische. Fast alle LLMs, die in den verifizierten Studien dieses Kapitels verwendet wurden, sind über die Anbieter-APIs nicht mehr oder nur noch kurz abrufbar (Stand: 11. November 2026). Laut OpenAI wurden die GPT-3-Basismodelle und InstructGPT am 4. Januar 2024 abgeschaltet; `gpt-3.5-turbo`, `gpt-4` und `gpt-4o-2024-05-13` am 23. Oktober 2026; für `gpt-4o-2024-08-06`, `gpt-4o-2024-11-20` und `gpt-4o-mini-2024-07-18` ist die Abschaltung für den 14. Jänner 2027 angekündigt @openai2026deprecations. Beide Snapshots von Claude 3.5 Sonnet wurden laut Anthropic am 28. Oktober 2025 außer Betrieb genommen @anthropic2026model. Für `gemini-2.5-flash` nennt Google kein Abschaltdatum, das Modell ist aber auf bestehende Nutzende beschränkt @google2026geminideprecations. LLaMA-2 und LLaMA-3 sind Open-Weight-Modelle ohne API-Abschaltung durch einen Anbieter.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let x0 = 2023.0
    let x1 = 2027.3
    let W = 11.8
    let sx(t) = (t - x0) / (x1 - x0) * W
    line((0, 0), (W, 0), stroke: 0.9pt + c-dark, mark: (end: "stealth", fill: c-dark, scale: 0.6))
    for j in (2023, 2024, 2025, 2026, 2027) {
      line((sx(j), -0.1), (sx(j), 0.1), stroke: 0.7pt + c-dark)
      content((sx(j), -0.32), text(font: "Inter", size: 7pt, str(j)))
    }
    // ev: Zeitpunkt, Text, Höhe, Farbe, Anker, Studie (Kreis) oder Abschaltung (Quadrat)
    let ev(t, lab, y, col, anc, kreis) = {
      let x = sx(t)
      let yend = if anc == "center" { if y > 0 { y - 0.32 } else { y + 0.32 } } else { y }
      line((x, 0), (x, yend), stroke: 0.5pt + col)
      if kreis { circle((x, 0), radius: 0.07, fill: col, stroke: none) } else { rect((x - 0.07, -0.07), (x + 0.07, 0.07), fill: col, stroke: none) }
      let dx = if anc == "east" { -0.1 } else if anc == "west" { 0.1 } else { 0 }
      content((x + dx, y), anchor: anc, text(font: "Inter", size: 6.4pt, fill: col.darken(15%), lab))
    }
    ev(2023.3, [Klievtsova et al. \ (GPT-3/3.5/4)], 1.0, c-blue, "center", true)
    ev(2024.0, [Brehmer & Buonassisi \ (GPT-4)], 1.8, c-blue, "center", true)
    ev(2026.0, [Reinhard et al. \ (GPT-4)], 1.5, c-blue, "east", true)
    ev(2026.25, [Iftikhar & Rausch (GPT-4o-mini, \ Claude 3.5 Sonnet, Gemini 2.5 Flash)], 2.5, c-blue, "center", true)
    ev(2024.01, [GPT-3, InstructGPT \ abgeschaltet], -1.0, c-red, "center", false)
    ev(2025.82, [Claude 3.5 Sonnet \ außer Betrieb], -1.0, c-red, "east", false)
    ev(2026.81, [gpt-3.5-turbo, gpt-4, \ gpt-4o-2024-05-13 abgeschaltet], -1.8, c-red, "east", false)
    ev(2027.04, [gpt-4o-mini u. a. \ (angekündigt)], -1.0, c-yellow, "west", false)
    line((sx(2026.86), -2.4), (sx(2026.86), 1.0), stroke: (paint: c-accent, thickness: 0.8pt, dash: "dashed"))
    content((sx(2026.86) + 0.1, -2.4), anchor: "west", text(font: "Inter", size: 6.6pt, weight: "bold", fill: c-accent)[Stand 11.11.2026])
  }),
  caption: [Erscheinungsjahr ausgewählter Studien (oben, Jahr laut Quellenangabe, Lage im Jahr schematisch) und Abschaltdaten der verwendeten Modelle (unten) nach @openai2026deprecations @anthropic2026model. Eine Replikation mit den Original-Snapshots ist weitgehend unmöglich.],
) <k02-abb-modelle>

Für DSR hat das zwei Konsequenzen. Erstens sind Ebene-1-Beiträge, die an ein bestimmtes Modell gebunden sind, nach kurzer Zeit nicht mehr nachprüfbar; das verstärkt das Argument für Ebene-2-Beiträge. Zweitens spricht es für Open-Weight-Modelle, deren Version fest bleibt, wenn die Gewichte archiviert werden; Fill et al. formulieren den Zielkonflikt zwischen Reproduzierbarkeit offener und Generierungsqualität proprietärer Modelle @fill2026generative[Abschn. 1]. Die Übung 02 der LV empfiehlt deshalb ein lokales Open-Weight-Modell.

=== Gute Praxis: eine Checkliste

Aus Bedrohungen und Studien lässt sich eine Praxis ableiten, die über alle DSRM-Aktivitäten reicht. Die Liste ist eine eigene Synthese aus den zitierten Quellen.

+ *Artefaktgrenze ziehen.* Benenne Modell-, System- und Anwendungsebene @feuerriegel2024generative[Abb. 1] und lege fest, ob Prompts, Korpus, Codebuch und Testset Teil des Artefakts oder des Kontexts sind (Herausforderung 1 bei @zurheiden2026design).
+ *Beitrag positionieren.* Ordne den Beitrag im Knowledge Contribution Framework und auf einer Abstraktionsebene ein @gregor2013positioning und formuliere Neuheit auf der Ebene der technologischen Regel @engstrom2020software[Abschn. 5.4].
+ *Prinzipien modellunabhängig formulieren* und die Veränderlichkeit des Artefakts regeln @gregor2007anatomy[Tab. 2].
+ *Evaluation mit FEDS planen* @venable2016feds, mit mindestens einer artifiziellen formativen Episode mit Wiederholungsläufen und einer naturalistischen summativen Episode mit externen Nutzenden.
+ *Stabilität messen und zerlegt berichten* (@k02-messung): Paraphrasen × Läufe, $sigma_"prompt"$ und $sigma_"run"$, Temperatur.
+ *Kontamination prüfen*, etwa durch unveröffentlichte Testdaten.
+ *Referenzmetriken ergänzen* um Expertenurteile abweichender Elemente @fill2026generative[Abschn. 1].
+ *Selbstevaluation vermeiden* oder als formativ deklarieren @jin2026developing.
+ *Effizienz kontrolliert messen*, nicht schätzen @brehmer2024educators.
+ *Alles protokollieren*: Modell, exakte Version, Zugangsdatum, Zugangsweg, Parameter, vollständige Prompts, auch für LLM-Hilfe im Forschungsprozess.

=== Debatten und offene Fragen

Mehrere Fragen sind in der Literatur offen; sie sind zugleich die besten Diskussionsthemen im Hörsaal.

*Erosion präskriptiven Wissens.* Designprinzipien, die an eine Modellversion gebunden sind, können ihre Gültigkeit verlieren, wenn das Modell ersetzt wird @zurheiden2026design. Offen ist, auf welcher Abstraktionsebene Prinzipien formuliert werden müssen, um Modellwechsel zu überleben, und wie man das prüft, ohne die Theorie zu immunisieren.

*Spezifikation des Artefakts.* Welche Teile gehören zum Artefakt: Modell, Prompts, Retrieval-Korpus, Orchestrierung? Diese Frage betrifft die ersten drei Herausforderungen bei zur Heiden et al. @zurheiden2026design und die Ebenen bei Feuerriegel et al. @feuerriegel2024generative[Abb. 1].

*Evaluation ohne einzige Ground Truth.* Für generierte Designartefakte gibt es oft mehrere korrekte Lösungen @fill2026generative[Abschn. 1]. Mehrdimensionale Evaluation ist gefordert, aber nicht standardisiert.

*Reproduzierbarkeit unter Nichtdeterminismus und geschlossenen Modellen* @iftikhar2026reliability[Tab. XV] @klievtsova2023conversational[Abschn. 5.5] @fill2026generative[Abschn. 1].

*Fehlende methodische Anleitung* für GenAI-bezogene DSR @zurheiden2026design und für KI-Unterstützung je DSR-Aufgabe @gau2025aibased.

*Kommunikation.* Für GenAI in der Kommunikationsaktivität wurde keine verifizierte empirische Arbeit gefunden @gau2022dsr.

*Relevanz versus Rigor.* ADR argumentiert, dass "erst bauen, dann evaluieren" technischen Rigor über organisationale Relevanz stellt @sein2011action; die DSRM behält eine nominale Abfolge, erlaubt aber Iteration und mehrere Einstiegspunkte @peffers2007design[S. 56]. Im Software Engineering war industrielle Validierung in Lösungsdesign- und Lösungsvalidierungsarbeiten selten @engstrom2020software[Abschn. 5.4], eine Relevanzlücke, die für rein benchmarkbasierte Evaluation von LLM-Artefakten genauso gilt.

*Veraltete Befunde.* Die GPT-3-Studien @memmert2023humanai @memmert2023learning und die GPT-3/GPT-4-Ergebnisse zur Prozessmodellierung @klievtsova2023conversational sind Momentaufnahmen einer Modellgeneration. Es ist plausibel, aber nicht getestet, dass neuere Modelle die absoluten Zahlen verändern, während die methodischen Lehren (Übervertrauen, Instabilität) relevant bleiben. Ebenso ist offen, ob Theoretisierung auch bei GenAI-Artefakten die Wirkung treibt; die Analyse von Wagner et al. deckt 2004-2014 ab @wagner2021exploring.

#hoersaal([Offene oder proprietäre Modelle: Was ist für eine DSR-Arbeit wichtiger, Reproduzierbarkeit oder Qualität?], [
  Fill et al. benennen genau diesen Zielkonflikt: Offene Modelle erlauben die Inspektion und Validierung aller Komponenten, proprietäre sind in der Generierungsqualität "still far ahead" @fill2026generative[Abschn. 1]. Eine vertretbare Antwort für eine Abschlussarbeit ist ein Design mit beiden: Das Hauptergebnis wird mit einem archivierten Open-Weight-Modell erzielt und damit reproduzierbar; ein proprietäres Modell dient als Obergrenze. Wenn sich die Designprinzipien mit beiden Modellen bestätigen, ist das zugleich ein erster Beleg dafür, dass sie modellunabhängig sind. Wichtig ist, dass du die Entscheidung begründest, statt sie aus Bequemlichkeit zu treffen.
])

#hoersaal([Ist es nicht widersprüchlich, ein LLM zur Bewertung eines LLM-Artefakts einzusetzen?], [
  Es ist nicht widersprüchlich, aber es häuft Bedrohungen: geteilte Verzerrungen, Kontamination, ein einzelnes Modell als Referenz. Fill et al. fordern mehrdimensionale Evaluation statt strikter Konformität mit einer einzigen Referenz @fill2026generative[Abschn. 1]. Für dieses Kapitel gilt die Minimalregel: Jede LLM-Bewertungsepisode wird im FEDS-Plan als eigene Episode deklariert @venable2016feds[Abb. 2] und gegen menschliche Urteile validiert. Wie man diese Validierung statistisch sauber durchführt und welche Verzerrungen LLM-Bewerter haben, ist Gegenstand von Kapitel 7.
])

== Das Fallbeispiel als vollständiger DSR-Plan <k02-fall-synthese>

Die Unterabschnitte "Im Fallbeispiel" haben KoDa schrittweise entwickelt. Zusammengesetzt im DSR Grid nach vom Brocke, Hevner und Maedche @vombrocke2020introduction[S. 10-11] ergibt sich ein Einseitenplan, wie ihn Aufgabe 4 der Übung 02 verlangt.

#figure(
  table(
    columns: (auto, 1fr),
    table.header([Dimension], [KoDa]),
    [Problem], [Deduktive Codierung von rund 2000 Freitextantworten pro Welle ist zeitaufwendig; LLM-Vorschläge drohen unreflektiert übernommen zu werden. Gütekriterien: Codierzeit, Übereinstimmung mit dem Goldstandard, Anteil übernommener falscher Vorschläge.],
    [Input-Wissen], [Kerntheorien zu angemessenem Vertrauen und Erklärungen in Mensch-KI-Interaktion; Gütekriterien qualitativer Codierung (Kapitel 5); verwandte Designmerkmale wie Quellenbelege und Konfidenzhinweise @reinhard2026design[Tab. 2].],
    [Forschungsprozess], [DSRM, problemzentrierter Einstieg; Designzyklus mit protokollierten Prompt-Iterationen; FEDS-Strategie Technical Risk & Efficacy mit vier Episoden (@k02-evaluation).],
    [Schlüsselkonzepte], [Segment, Codevorschlag, Belegstelle, Unsicherheitsmarkierung, Prüfentscheidung; Stabilität ($sigma_"prompt"$, $sigma_"run"$).],
    [Lösung], [Instanziierung KoDa; Mechanismen: Vorschlag mit wörtlicher Belegstelle, selektive Unsicherheitsmarkierung, Trennung von Vorschlag und Entscheidung. Positionierung: Improvement, Ebene 2.],
    [Output-Wissen], [Designprinzipien für LLM-gestützte Codierassistenten; technologische Regel; Befunde zur Stabilität und zur Wirkung von Belegstellen auf die Prüfquote; LLM-Log, Prompts und Daten.],
  ),
  caption: [DSR Grid nach @vombrocke2020introduction[S. 10-11] für das Fallbeispiel KoDa (illustrativ).],
) <k02-tab-grid>

Das zentrale Designprinzip lautet im Schema von @gregor2020research[S. 1633]: "Damit Entwickelnde von Forschungswerkzeugen ($I$) eine kritische, aber effiziente Prüfung von Codevorschlägen ($A$) durch Codierende ($U$) bei deduktiver Codierung großer Freitextmengen mit festem Codebuch ($C$) ermöglichen, setze zu jedem Vorschlag eine wörtliche Belegstelle ein und markiere nur Vorschläge unterhalb einer vorab kalibrierten Sicherheitsschwelle ($M_1$, $M_2$), unter Beteiligung der Codierenden als Entscheidende ($E_1$), weil belegte Vorschläge die Prüfung auf eine überprüfbare Textstelle lenken und selektive Warnungen nicht durch Gewöhnung entwertet werden ($R$)." Die Begründung $R$ ist eine Hypothese, die die Laborepisode prüft. Die Prinzipien enthalten keinen Modellnamen; die Veränderlichkeitsregel verlangt, nach jedem Modellwechsel die Episoden 2 und 3 zu wiederholen.

Die erwartbaren Schwachstellen des Plans sollten ebenso offen benannt werden: Der Goldstandard ist selbst eine Codierung mit begrenzter Reliabilität; die Laborepisode mit Studierenden hat eingeschränkte externe Validität; die naturalistische Episode umfasst nur zwei Codierende. Das Lehrbuch beschreibt den Limitationsabschnitt als "Hauptbuch" der vollständig, teilweise und nicht erfüllten Gütekriterien @haindl2027research[Kap. 3].

== Für die Lehre <k02-lehre>

=== Aufbau und Zeitbedarf

Der Foliensatz 02 umfasst acht Teile (Einführung, Grundlagen, Prozess, Evaluation, Beiträge, GenAI, Messung, Risiken) mit insgesamt 55 Folien. Realistisch sind zwei Einheiten zu je 90 Minuten: In der ersten Grundlagen, Prozess und Beiträge (Richtlinien, Zyklen, DSRM, Knowledge Contribution Framework), in der zweiten Evaluation, GenAI, Messung und Risiken. Zum Foliensatz gibt es kein Notebook; die Übung 02 verlangt in den Aufgaben 2 und 3 ein eigenes kurzes Python-Skript, für das das Skript in @k02-messung als Vorlage dienen kann. Die Übung umfasst fünf Aufgaben: ein publiziertes DSR-Paper abbilden, die strukturelle Korrektheit und die Stabilität eines LLM-generierten Artefakts messen, einen DSR-Plan für das eigene Thema schreiben und eine kritische Reflexion verfassen, die ohne LLM-Hilfe entstehen muss.

=== Bewährte Übungsformate

Das Dossier zur LV schlägt mehrere Formate vor, die sich direkt einsetzen lassen:

- *Paper-Mapping (90 min, Paare):* Reinhard et al. 2026 @reinhard2026design oder Klievtsova et al. 2023 @klievtsova2023conversational auf die DSRM abbilden, Einstiegspunkt bestimmen, jede Evaluationsepisode in der FEDS-Matrix verorten, den Beitrag im Knowledge Contribution Framework positionieren und als Visual Abstract mit expliziter technologischer Regel abgeben.
- *Strukturelle Evaluation replizieren (2-3 h):* Mit dem PET-Datensatz, auf den sich Klievtsova et al. beziehen, Kontrollflusskanten extrahieren lassen und Precision, Recall, $F_1$ und Jaccard berechnen; die Verfügbarkeit des Datensatzes vor der Einheit prüfen.
- *Stabilitätsexperiment (2-3 h):* 3 Paraphrasen × 10 Läufe × 2 Temperaturen nach dem Design von Iftikhar und Rausch @iftikhar2026reliability, Varianzkomponenten, SI und $A$ berechnen; Diskussion, warum ein SI nahe 1 Varianz verbirgt.
- *Menschliche versus LLM-Designprinzipien (60 min):* Studierende schreiben zwei Prinzipien nach dem Schema, ein LLM zwei weitere; alle vier werden blind auf den Kriterien von Böhmer et al. @bohmer2025should bewertet.
- *Live-Demo:* Denselben Designprompt fünfmal laufen lassen und die unterschiedlichen Ausgaben zeigen; Bezug zur 52-%-Übereinstimmung @klievtsova2023conversational[Abschn. 5.5].

=== Typische Missverständnisse

*"Demonstration ist Evaluation."* Die häufigste Schwäche in Exposés. Hilfreich ist die Frage: "Gegen welches vorab festgelegte Ziel vergleichst du, und auf wie vielen Instanzen?"

*"Ein Artefakt ist eine Software."* Konstrukte, Modelle und Methoden sind gleichwertige Artefakttypen @hevner2004design; die Roadmap von Amalfitano et al. ist ein gutes Gegenbeispiel @amalfitano2025research.

*"Das Problem ist neu."* Fast immer ist der Kontext neu, nicht das Problem. Die 2×2-Matrix von Gregor und Hevner zwingt zur Unterscheidung von $p$ und $s$.

*"Temperatur 0 macht das Artefakt deterministisch und damit stabil."* Das Rechenbeispiel zu KoDa zeigt, dass die Promptsensitivität bleibt.

*"Ein hoher SI heißt stabil."* Die Schranke in @k02-eq-schranke ist ein gutes Tafelbeispiel: Mit drei Zeilen Rechnung sehen Studierende, dass ein SI von 0.95 auf einer [0,1]-Skala bereits eine Standardabweichung von 0.23 bedeutet.

*"DSR heißt, dass ich keine Hypothesen brauche."* Testbare Propositionen sind eine Kernkomponente jeder Designtheorie @gregor2007anatomy[Tab. 2], und die Evaluation einer Wirkung ist eine Wissensfrage im Sinne Wieringas @wieringa2014design.

=== Kritische Fragen, mit denen du rechnen solltest

Studierende mit Software-Engineering-Hintergrund fragen oft, warum sie IS-Literatur lesen sollen, wenn ihr Feld ein eigenes Vokabular hat. Die Studie von Engström et al. ist die beste Antwort: Das Feld betreibt Design Science, ohne es zu sagen, und verliert dabei die Neuheitsargumentation auf Regelebene @engstrom2020software. Studierende mit Statistik-Hintergrund fragen, ob DSR nicht "weiche" Forschung sei. Hier hilft der Hinweis, dass jede Evaluationsepisode eine empirische Studie mit eigenen Gütekriterien ist und dass die Wirkungsanalyse von Wagner et al. zeigt, dass Theoretisierung messbar zählt @wagner2021exploring.

#tipp[
  Lass die Studierenden ihre eigene Forschungsfrage vor der Einheit in einem Satz notieren und am Ende in "Designproblem" und "Wissensfrage" nach Wieringa zerlegen. Kaum eine Übung macht den Unterschied zwischen DSR und anderen Designs schneller greifbar.
]

#vertiefung[
  Als Einstieg @hevner2004design (Richtlinien und Rahmenmodell) und @peffers2007design (Prozess); beide sind die Anker für jede DSR-Arbeit. Für die Positionierung des Beitrags @gregor2013positioning, für Designprinzipien @gregor2020research und für Designtheorien @gregor2007anatomy. FEDS @venable2016feds ist frei verfügbar (CC BY 3.0) und für die Evaluationsplanung unverzichtbar. Für die Brücke zum Software Engineering @engstrom2020software (CC BY 4.0). Für ADR @sein2011action, für die Validierungsbegriffe @wieringa2014design. Zur GenAI-Ära: @zurheiden2026design für die Risiken, @blohm2025nextgeneration für die Rollen der KI im Forschungsprozess, @fill2026generative für die Evaluationsfrage und @iftikhar2026reliability als methodisches Vorbild für Wiederholungsdesigns. Im Lehrbuch @haindl2027research behandeln Kapitel 2 (DSR und Action Research) und Kapitel 3 (DSR-Qualität) die Grundlagen.
]

#selbsttest(
  [Ordne die folgenden Ergebnisse je einem Artefakttyp nach Hevner et al. zu: (a) eine Taxonomie von Fehlertypen in LLM-generierten Codierungen, (b) eine Referenzarchitektur für Codierassistenten, (c) ein Vorgehen zur Kalibrierung von Unsicherheitsschwellen, (d) der Prototyp KoDa.],
  [Eine Arbeit beginnt mit einem bereits existierenden LLM-Tool aus einem Industrieprojekt und untersucht es rigoros. Welcher DSRM-Einstiegspunkt liegt vor, und welche Aktivitäten muss die Arbeit dennoch nachholen?],
  [Erkläre den Unterschied zwischen Demonstration und Evaluation in der DSRM und zwischen Validierung und Evaluation bei Wieringa. Wie heißen die Benchmark-Experimente einer typischen LLM-Masterarbeit in Wieringas Begriffen?],
  [Positioniere mit $p$ und $s$ aus @k02-eq-kcf: (a) einen RAG-Chatbot für Prüfungsordnungen mit Standardarchitektur, (b) die Übertragung eines bekannten Verfahrens zur Unsicherheitsschätzung auf die automatisierte Auswahl von Studien in systematischen Reviews, wenn es für diese Auswahl noch keine Problemformulierung zur Unsicherheit gibt. Begründe.],
  [Berechne unter der Log-Link-Lesart $e^beta$ für Invention ($beta = 0.40$) und Theoretisierung ($beta = 0.29$) aus Wagner et al. und interpretiere beide Werte. Warum ist Vorsicht geboten?],
  [Formuliere für ein Artefakt deiner Wahl ein Designprinzip mit allen sieben Slots nach Gregor, Chandra Kruse und Seidel und die zugehörige technologische Regel. Welche Information geht beim Übergang zur Regel verloren?],
  [Ein LLM-generiertes Klassendiagramm hat 14 Elemente, die Referenz 12, und 9 stimmen überein. Berechne Precision, Recall, $F_1$ und Jaccard und prüfe @k02-eq-jf1.],
  [Gegeben sind $P = 2$ Paraphrasen mit je $R = 4$ Läufen und den Scores $(0.60, 0.64, 0.62, 0.62)$ und $(0.70, 0.66, 0.68, 0.68)$. Berechne $sigma^2_"prompt"$, $sigma^2_"run"$, die Gesamtvarianz und den SI. Welche Komponente dominiert?],
  [Zeige, dass der Stability Index nach @k02-eq-si mit Populationsvarianzen auf Scores in $[0, 1]$ nie unter 0.8 fallen kann. Was folgt daraus für einen berichteten Wert von 0.77?],
  [Wähle für ein LLM-gestütztes Werkzeug zur Erstellung von Prüfungsfragen eine FEDS-Strategie und entwirf drei Evaluationsepisoden mit Zeitpunkt, Zweck, Paradigma und der jeweils adressierten Validitätsbedrohung.],
  [Nenne die fünf Herausforderungen nach zur Heiden et al. und gib zu jeder eine konkrete Maßnahme für eine Abschlussarbeit an.],
  [Warum ist die Evaluation gegen ein einziges Referenzartefakt problematisch, und wie lässt sich die Evaluation eines generierten Codebuchs so ergänzen, dass valide Alternativen nicht bestraft werden?],
)

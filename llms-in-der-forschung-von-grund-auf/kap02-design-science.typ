#import "lib.typ": *

= Design Science Research

Stell dir vor, du baust für ein Unternehmen einen Assistenten für den Support. Die Mitarbeiter tippen eine Kundenfrage ein, der Assistent sucht in der Wissensdatenbank die passenden Texte heraus und lässt ein Sprachmodell daraus eine Antwort formulieren, jede mit Link auf die Quelle. Dieses Muster heißt _Retrieval-Augmented Generation_, kurz RAG: Dem Modell werden zur Frage passende Textstellen mitgegeben. Nach drei Wochen läuft er. Ist das Forschung? Ein Gutachter würde fragen: Welches Problem löst das, und ist es wichtig? Woher weißt du, dass der Assistent hilft? Und was können andere daraus lernen, die nicht in genau diesem Unternehmen arbeiten?

Diese drei Fragen sind der Kern von _Design Science Research_ (DSR), einem Forschungsansatz für alle, die etwas bauen und dabei Wissen erzeugen wollen. In diesem Kapitel heißt der Assistent durchgehend _Support-Desk-Assistent_. An ihm spielen wir jeden Schritt durch: wie man das Vorhaben als Studie aufsetzt, wie man es bewertet und wie man aufschreibt, was man gelernt hat.

Mit Sprachmodellen im Artefakt wird das schwieriger: Derselbe Assistent antwortet beim zweiten Lauf anders als beim ersten, und das Modell, mit dem du gebaut hast, kann in einem Jahr abgeschaltet sein. Deshalb behandelt die zweite Hälfte des Kapitels, wie man ein solches Artefakt misst und welche Fallen drohen (Foliensatz 02).

#lernziele(
  [erklären, wann Bauen zur Forschung wird und worin sich das von Routinearbeit unterscheidet],
  [eine Studie auf die sechs Schritte des DSR-Ablaufs und auf die drei Zyklen abbilden],
  [eine Evaluation mit dem FEDS-Rahmen planen und die Wahl der Methoden begründen],
  [einen Beitrag als Erfindung, Verbesserung, Exaptation oder Routine einordnen und als Designprinzip oder technologische Regel formulieren],
  [Korrektheit und Stabilität eines LLM-Artefakts messen und die Zahlen richtig lesen],
  [die typischen Risiken von Sprachmodellen in der DSR benennen und im Projektplan vorsorgen],
)

== Bauen als Forschung

#alltag[Ein Tischler baut nach einem Katalog einen weiteren Stuhl. Ein anderer entwickelt eine neue Verbindung, die ohne Leim hält, und schreibt auf, warum sie hält und wann nicht. Beide bauen. Nur der zweite hinterlässt etwas, das andere Tischler benutzen können.]

Das ist der Unterschied zwischen Routine und Forschung. Eine weitere Web-Anwendung aus bekannten Mustern zu bauen, ist handwerklich wertvoll, aber der Erfolg heißt nur: Es funktioniert. Bei DSR heißt er: Es funktioniert, und wir wissen jetzt, warum. MapReduce lieferte zum Beispiel nicht nur ein System, sondern ein Programmiermodell, das andere übernehmen konnten @haindl2027research.

#begriff[Artefakt (artefact)][Etwas von Menschen Gebautes, das ein Problem lösen soll: ein Begriffssystem, ein Modell, ein Verfahren oder ein lauffähiges System. In deinem Fall meist ein Stück Software oder ein Prozess.]

DSR ergänzt die Verhaltenswissenschaft, ersetzt sie aber nicht. Sie fragt: Warum passiert X? Die Design Science fragt: Wie sollte man etwas bauen, damit es hilft? Hevner und Kollegen sehen beide als Partner @hevner2004design. Wieringa sagt, ein DSR-Projekt wechsle zwischen _Designproblemen_ ("Finde etwas, das die Lage verbessert") und _Wissensfragen_ ("Wie verhält sich das Gebaute in seiner Umgebung?") @wieringa2014design. Viele Abschlussarbeiten mischen beides: erst die Pipeline bauen, dann ein Experiment mit ihr durchführen.

Viel Forschung ist DSR, ohne sich so zu nennen. Engström und Kollegen prüften 38 preisgekrönte Arbeiten der Software-Engineering-Konferenz ICSE (2014 bis 2018) mit neun Fragen aus der Design Science @engstrom2020software.

#studie(titel: [Engström et al., 2020])[
  *Gemacht:* Zwei Autoren bewerteten jede der 38 Arbeiten unabhängig mit denselben neun Design-Science-Fragen. \
  *Ergebnis:* Die meisten Arbeiten ließen sich als Design Science beschreiben, keine nannte den Begriff, und keine formulierte ihre technologische Regel (dazu unten mehr) in einem Satz. \
  *Heißt:* Die Arbeiten stellten Werkzeuge vor, ohne das übertragbare Prinzip zu benennen; das macht sie schwerer wiederverwendbar.
]

#merke[Ein Artefakt ohne ausgesprochenes Designprinzip und ohne Wissensbeitrag ist nur ein Werkzeug. Es wird erst Forschung, wenn du sagen kannst, was andere daraus lernen.]

#hoersaal([Ist meine App dann keine Forschung?], [Sie kann es werden. Entscheidend ist nicht, was du gebaut hast, sondern ob du ein relevantes Problem gelöst, das Ergebnis streng bewertet und etwas Übertragbares festgehalten hast. Eine App, die nur funktioniert, ist ein gutes Projekt, aber noch keine Studie.])

== Das Gerüst: drei Zyklen, vier Artefakttypen, sieben Leitlinien

Hevner beschreibt DSR als drei ineinandergreifende Zyklen @hevner2007three. Das Bild dazu ist eine Restaurantküche: Aus dem Gastraum kommen die Bestellungen (die Umwelt), im Regal stehen die Kochbücher (das vorhandene Wissen), und in der Mitte wird gekocht und probiert.

#figure(
  diagram(spacing: (19mm, 8mm), node-corner-radius: 3pt,
    fknoten((0, 0), [*Umwelt* \ Support-Agenten, Tickets, Wissensdatenbank], col: c-teal, filled: true, w: 40mm),
    fknoten((1, 0), [*Design-Zyklus* \ bauen und evaluieren im Wechsel], col: c-accent, w: 42mm),
    fknoten((2, 0), [*Wissensbasis* \ Theorien, Methoden, frühere Studien], col: c-blue, filled: true, w: 40mm),
    edge((0, 0), (1, 0), "->", shift: 2.5mm, label: text(font: "Inter", size: 6.6pt)[Anforderungen], label-side: left, label-sep: 2pt),
    edge((1, 0), (0, 0), "->", shift: 2.5mm, label: text(font: "Inter", size: 6.6pt)[Feldtest], label-side: left, label-sep: 2pt),
    edge((2, 0), (1, 0), "->", shift: 2.5mm, label: text(font: "Inter", size: 6.6pt)[Grundlagen], label-side: left, label-sep: 2pt),
    edge((1, 0), (2, 0), "->", shift: 2.5mm, label: text(font: "Inter", size: 6.6pt)[neues Wissen], label-side: left, label-sep: 2pt),
  ),
  caption: [Die drei Zyklen. Der Relevanz-Zyklus verbindet das Projekt mit der Umwelt, der Rigour-Zyklus mit dem Wissensstand, der Design-Zyklus ist die Bauschleife dazwischen.],
) <k02-zyklen>

Der _Relevanz-Zyklus_ (_relevance cycle_) liefert Anforderungen und die Kriterien, nach denen später bewertet wird, und bringt das fertige Artefakt zum Test zurück in die Praxis. Der _Rigour-Zyklus_ (_rigour cycle_) liefert Theorien und Methoden als Fundament und nimmt neues Wissen auf. Der _Design-Zyklus_ (_design cycle_) ist die innere Schleife aus Bauen und Bewerten. Die häufigste Lücke in Abschlussarbeiten ist der Rigour-Zyklus: Es wird gebaut und getestet, aber nie gesagt, auf welchem Wissen der Entwurf beruht.

Hevner und Kollegen unterscheiden vier Arten von Artefakten @hevner2004design. Eine Arbeit liefert oft mehrere zugleich, etwa ein Verfahren und seine Umsetzung.

#figure(
  table(columns: (auto, 1fr, 1fr),
    [Typ], [Was es ist], [Beispiel für LLM-Systeme],
    [*Construct*], [Begriffe und Symbole, mit denen man Probleme beschreibt], [eine Ordnung der Arten von Halluzinationen],
    [*Model*], [eine Darstellung von Problem und Lösungsraum], [eine Referenzarchitektur für GenAI-Systeme @grau2025rethinking],
    [*Method*], [eine Anleitung, wie man Lösungen sucht, vom Algorithmus bis zur Arbeitsweise], [ein gemeinsamer Arbeitsprozess, mit dem Fachleute Einsatzstellen für KI-Agenten finden @reinhard2025genaicop],
    [*Instantiation*], [ein lauffähiges System, das zeigt, dass es geht], [ein RAG-Prototyp mit Erklärfunktionen @reinhard2026design],
  ),
  caption: [Die vier Artefakttypen. Der Support-Desk-Assistent ist eine Instantiation.],
)

Achtung: Ein _Model_ in diesem Sinn ist eine Darstellung, etwa eine Architektur, kein trainiertes Machine-Learning-Modell.

Dazu kommen sieben Leitlinien von Hevner und Kollegen @hevner2004design, die du als Checkliste für den Projektplan lesen kannst: ein brauchbares Artefakt erzeugen, ein wichtiges Problem lösen, Nutzen und Qualität streng nachweisen, einen klaren Beitrag leisten, strenge Methoden verwenden, das Bauen als Suche unter Randbedingungen verstehen (und verworfene Alternativen festhalten) und für technische wie betriebswirtschaftliche Leser berichten. Bei LLM-Arbeiten sind Bewertung und Beitrag am häufigsten dünn.

== Der Ablauf: Sechs Schritte, vier Einstiege

#alltag[Ein Kochrezept mit sechs Schritten, bei dem du im fünften Schritt abschmeckst und notfalls zu Schritt drei zurückgehst.]

Peffers und Kollegen haben aus früheren Prozessbeschreibungen den _DSRM-Ablauf_ (_Design Science Research Methodology_) zusammengestellt und an vier Fällen erprobt @peffers2007design. Er hat sechs Aktivitäten, und die Bewertung entscheidet, ob man zurück zum Entwurf geht oder zur Berichterstattung weiter.

#figure(
  diagram(spacing: (5mm, 8mm), node-corner-radius: 3pt,
    fknoten((0, 0), [Problem \ erkennen], col: c-accent, filled: true, w: 24mm),
    fknoten((1, 0), [Ziele \ festlegen], col: c-blue, w: 24mm),
    fknoten((2, 0), [Entwerfen \ und bauen], col: c-blue, w: 24mm),
    fknoten((3, 0), [Vorführen \ (Demo)], col: c-blue, w: 24mm),
    fknoten((4, 0), [Evaluieren], col: c-blue, w: 24mm),
    fknoten((5, 0), [Berichten], col: c-accent, filled: true, w: 24mm),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"), edge((2, 0), (3, 0), "->"),
    edge((3, 0), (4, 0), "->"), edge((4, 0), (5, 0), "->"),
    edge((4, 0), (2, 0), "->", bend: 40deg, label: text(font: "Inter", size: 6.6pt)[iterieren], label-sep: 2pt),
  ),
  caption: [Die sechs Aktivitäten des DSRM-Ablaufs mit der Rückschleife von der Bewertung zum Entwurf.],
) <k02-dsrm>

#figure(
  table(columns: (auto, 1fr, 1fr),
    [Aktivität], [Was sie verlangt], [Beim Support-Desk-Assistenten],
    [Problem], [ein Problem, das wichtig ist und von bestehenden Lösungen nicht gut gelöst wird], [Mitarbeiter verlieren Minuten mit der Suche in der Wissensdatenbank],
    [Ziele], [aus dem Problem ableiten, was die Lösung leisten soll], [Antworten mit Quelle innerhalb weniger Sekunden],
    [Entwurf], [auf vorhandene Theorie und Muster aufbauen, nicht bei null beginnen], [ein RAG-Aufbau, der pro Satz einen Quellenlink liefert],
    [Demonstration], [zeigen, dass es an mindestens einem Fall funktioniert: Machbarkeit, noch kein Beweis für alle Fälle], [ein echtes Ticket korrekt beantworten],
    [Evaluation], [beobachten und messen, wie gut die Lösung das Problem löst, und Ziele mit Ergebnissen vergleichen], [Antwortqualität und Bearbeitungszeit gegen die alte Suche],
    [Berichten], [Problem, Artefakt, Nutzen, Neuheit und Strenge des Vorgehens darlegen], [Abschlussarbeit oder Paper],
  ),
  caption: [Was jede Aktivität verlangt, am durchgehenden Beispiel.],
)

Die Reihenfolge ist nur der Normalfall. Peffers und Kollegen nennen vier Einstiege: beim Problem, bei den Zielen, beim Entwurf oder bei einem Auftraggeber, der schon einen Prototyp mitbringt. Aufgeschrieben werden trotzdem alle sechs Aktivitäten.

=== Wenn das Bauen die Organisation verändert

Manchmal lässt sich "erst bauen, dann bewerten" nicht durchhalten, weil das Artefakt die Organisation selbst verändert. Dann passt _Action Design Research_ (ADR) von Sein und Kollegen @sein2011action: Bauen, Eingreifen und Bewerten laufen gleichzeitig, wie beim Renovieren einer Wohnung, in der man weiter wohnt. ADR ist die Wahl, wenn du mit einem Industriepartner arbeitest; der Lehrfall der Autoren ist ein System zur Kompetenzverwaltung bei Volvo IT.

Verwandt ist die _Aktionsforschung_ (_action research_) @haindl2027research: ein Zyklus aus Diagnose, Planen, Umsetzen, Auswerten und Lernen, üblich sind drei bis vier Runden. Du bist selbst Teil der Situation und musst festhalten, wie deine Anwesenheit sie verändert hat (_reflexivity_). Ein Beispiel aus dem Buch: Ein Softwareunternehmen verbessert seine Code-Reviews, nachdem sich Releases verzögert hatten, weil unklar war, wer für das Review zuständig ist.

#hoersaal([Muss ich die sechs Schritte strikt der Reihe nach abarbeiten?], [Nein. Die Reihenfolge ist nominell. Du darfst an vier Stellen einsteigen und nach der Bewertung zurückspringen. Wichtig ist nur, dass dein Bericht am Ende alle sechs Aktivitäten abdeckt.])

== Evaluieren: Wann, wie, was

Die zentrale Frage lautet: Woher weißt du, dass dein Artefakt etwas taugt? Hevner und Kollegen ordnen die Bewertungsmethoden in fünf Familien mit zusammen zwölf Methoden @hevner2004design.

#figure(
  table(columns: (auto, 1fr, 1fr),
    [Familie], [Methoden], [Alltagsbild: ein neues Fahrrad],
    [*Observational*], [Fallstudie, Feldstudie], [im Alltag beobachten, wie es gefahren wird],
    [*Analytical*], [statische, Architektur- und dynamische Analyse, Optimierung], [Übersetzung und Gewicht nachrechnen],
    [*Experimental*], [kontrolliertes Experiment, Simulation], [gegen ein anderes Rad antreten],
    [*Testing*], [funktional (von außen, Black Box), strukturell (mit Blick in den Aufbau, White Box)], [jeden Hebel einmal drücken],
    [*Descriptive*], [begründetes Argument, Szenarien], [erklären, warum es gut sein muss],
  ),
  caption: [Fünf Familien von Bewertungsmethoden. Starke Arbeiten kombinieren mehrere.],
)

Frag bei jeder Methode, welche Eigenschaft des Artefakts sie überhaupt zeigen kann, und kombiniere mehrere, etwa Komplexitätsanalyse, Benchmark (ein fester Testsatz mit bekannten Soll-Ergebnissen) und Nutzerstudie für einen Algorithmus @haindl2027research.

Wieringa trennt zwei Arten von Belegen @wieringa2014design. _Validation_ sagt vor dem Einsatz voraus, ob das Artefakt in seiner Umgebung die Anforderungen erfüllen wird, etwa durch Expertenurteil, Simulation oder kontrollierte Läufe auf ausgewählten Beispielen. _Evaluation_ misst nach dem realen Einsatz die tatsächlichen Wirkungen und liegt meist außerhalb eines Forschungsprojekts. Das ist wie der Crashtest im Labor gegen die Unfallstatistik von der Straße.

=== FEDS: zwei Fragen sortieren jede Evaluation

Venable und Kollegen haben mit dem Rahmen _FEDS_ (_Framework for Evaluation in Design Science_) eine praktische Hilfe geliefert, die Evaluation zu planen @venable2016feds. Zwei Fragen genügen. Erstens: Wozu bewerte ich? Entweder um das Artefakt zu verbessern (_formative_) oder um zu beurteilen, wie gut das Ergebnis zu den Erwartungen passt (_summative_). Das ist der Unterschied zwischen Suppe abschmecken, während man kocht, und dem Urteil des Gasts. Zweitens: Wo bewerte ich? Entweder unter kontrollierten Bedingungen (_artificial_: Labor, Simulation, Beweis) oder mit echten Nutzern, echten Problemen und echter Umgebung (_naturalistic_).

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    content((5.4, 4.15), text(font: "Inter", size: 8pt, weight: "bold")[artificial: kontrolliert])
    content((11.9, 4.15), text(font: "Inter", size: 8pt, weight: "bold")[naturalistic: echte Nutzer, echte Aufgaben])
    content((1.3, 2.7), align(center, text(font: "Inter", size: 8pt, weight: "bold")[formative \ verbessern]))
    content((1.3, 0.7), align(center, text(font: "Inter", size: 8pt, weight: "bold")[summative \ beurteilen]))
    kasten((5.4, 2.7), [Entwurf nachschärfen: \ Wiederholungstests], col: c-blue, w: 6.0, h: 1.6)
    kasten((11.9, 2.7), [Mit Nutzern verfeinern: \ lautes Denken beim Benutzen], col: c-teal, w: 6.0, h: 1.6)
    kasten((5.4, 0.7), [Wirkung belegen: \ kontrollierter Vergleich mit Vergleichslösung], col: c-accent, w: 6.0, h: 1.6)
    kasten((11.9, 0.7), [Praxistauglichkeit belegen: \ echte Aufgaben über längere Zeit], col: c-violet, w: 6.0, h: 1.6)
  }),
  caption: [Die FEDS-Matrix mit Beispielen für den Support-Desk-Assistenten.],
) <k02-feds>

Aus beiden Fragen und dem Hauptrisiko folgt die Strategie. FEDS nennt vier @venable2016feds.

#figure(
  table(columns: (auto, 1fr),
    [Strategie], [Wähle sie, wenn ...],
    [*Quick and Simple*], [der Entwurf klein und einfach ist und das soziale wie technische Risiko gering],
    [*Human Risk and Effectiveness*], [das Hauptrisiko bei den Menschen liegt (nimmt man es an?) und Tests mit echten Nutzern verhältnismäßig billig sind],
    [*Technical Risk and Efficacy*], [das Hauptrisiko technisch ist (funktioniert es?) und Tests mit echten Nutzern unverhältnismäßig teuer wären],
    [*Purely Technical*], [es keine sozialen Aspekte gibt oder der Einsatz noch weit in der Zukunft liegt],
  ),
  caption: [Die vier FEDS-Strategien.],
)

Die Planung hat vier Schritte: (1) Ziele der Evaluation klären, (2) Strategie wählen, (3) festlegen, welche Eigenschaften bewertet werden, (4) einzelne _Episoden_ entwerfen, die jeweils formativ oder summativ und künstlich oder naturalistisch sind. Eine Grenze: FEDS wurde nicht für Artefakte mit Zufallsanteil geschrieben, die bei gleicher Eingabe verschieden antworten. Bei LLM-Artefakten kommen deshalb Episoden mit Wiederholungsläufen und umformulierten Eingaben hinzu. Zehn Jahre DSR-Arbeiten zeigen sieben typische Bewertungsmuster; langfristige Wirkungen werden kaum bewertet @prat2015taxonomy.

== Der Beitrag: Mehr als das Werkzeug

#alltag[Ein Handwerker baut eine Schublade, die nicht klemmt. Das ist das Werkstück. Wenn er aufschreibt, wie man Schubladen für schiefe Wände baut, ist das der Beitrag.]

Eine Arbeit ist Forschung, wenn drei Dinge zusammenkommen @haindl2027research. Das Problem ist _relevant_, aber relevant heißt nicht: der Markt will es. Die Public-Key-Kryptografie löste das Problem sicherer Kommunikation ohne gemeinsames Geheimnis schon, bevor es einen E-Commerce gab, der sie verlangte. Das Vorgehen ist _streng_: Jede Entwurfsentscheidung hängt an einer Anforderung oder einer Theorie, und der Prozess ist nachvollziehbar. Und es gibt einen _Beitrag_, also neues Wissen über das Artefakt hinaus. Bastelei, bis etwas funktioniert, ist keine Forschung.

=== Neuheit einordnen

Gregor und Hevner fragen zwei Dinge: Ist das Problem schon bekannt, und gibt es dafür schon eine Lösung? Daraus ergeben sich vier Felder @gregor2013positioning.

#figure(
  table(columns: (auto, 1fr, 1fr),
    [], [Problem neu], [Problem bekannt],
    [*Lösung bekannt*], [*Exaptation:* bekannte Lösung auf ein neues Problem übertragen], [*Routine design:* meist kein Forschungsbeitrag],
    [*Lösung neu*], [*Invention:* neue Lösung für ein neues Problem], [*Improvement:* bessere Lösung für ein bekanntes Problem],
  ),
  caption: [Die vier Beitragsarten nach Gregor und Hevner.],
)

Ein Chatbot, der ein Standard-RAG-Muster mit einer gängigen Sprachmodell-Schnittstelle auf ein gut verstandenes Problem anwendet, liegt nah an der Routine. Überträgst du dagegen eine bekannte LLM-Technik auf eine neue Art von Problem, ist das Exaptation. Fragt dich jemand, ob dein "RAG-Chatbot für X" Forschung ist, lautet die ehrliche Antwort: Es hängt davon ab, ob du eine der drei oberen Zeilen glaubwürdig begründen kannst.

#studie(titel: [Wagner et al., 2021])[
  *Gemacht:* 115 DSR-Arbeiten aus führenden Zeitschriften der Wirtschaftsinformatik (2004 bis 2014); verglichen wurde, wie oft sie zitiert wurden, nach Beitragsart und nach Grad der Theoriebildung. Ansehen der Zeitschrift, Stellung der Autoren und Alter der Arbeit wurden herausgerechnet. \
  *Ergebnis:* Mit jeder Einheit mehr Theoriebildung (auf der Skala der Studie) stieg die erwartete Zitierzahl um etwa 34 %. Für Exaptation-Arbeiten lag sie beim 1,67-Fachen einer vergleichbaren Improvement-Arbeit, Inventions-Arbeiten wurden ebenfalls häufiger zitiert, Routine-Arbeiten nicht. Der Einfluss der Theorie war größer als der des Zeitschriftenansehens. Nebenbefund: Eine DSR-Arbeit teilt nur etwa drei ihrer rund 60 Quellen (4,8 %) mit anderen DSR-Arbeiten, die gemeinsame Wissensbasis ist dünn. \
  *Heißt:* Das gilt für Arbeiten bis 2014 und ist ein Zusammenhang, keine Ursache. Die Prozentwerte sind die Lesart des Kurses: Die Studie nennt nur die rohen Modellwerte, die Umrechnung in Prozent setzt eine übliche Annahme über das Modell voraus @wagner2021exploring.
]

=== Vom Prototyp zur Theorie

Wie weit ein Beitrag reicht, beschreiben drei Stufen @gregor2013positioning: Stufe 1 ist die einzelne Umsetzung, etwa ein Softwareprodukt. Stufe 2 ist eine beginnende Designtheorie aus Begriffen, Methoden, Modellen, Designprinzipien und technologischen Regeln. Stufe 3 ist eine ausgearbeitete Theorie über die zugrunde liegenden Phänomene. Dahinter steht die Unterscheidung zwischen _beschreibendem Wissen_ (was es gibt und wie es sich verhält) und _vorschreibendem Wissen_ (wie man Dinge baut, die funktionieren). Eine Einzelumsetzung ist ein Haus, ein Bauplan für viele Grundstücke ist Stufe 2. Die meisten Abschlussarbeiten liefern Stufe 1 und sollten mindestens eine Aussage auf Stufe 2 anstreben. Ob der Beitrag das Artefakt, die Theorie oder beides sein soll, ist umstritten @baskerville2018design; Autoren hoch zitierter Arbeiten warnen zudem vor zu einfachen Vorlagen @reiners2025past.

Eine vollständige Designtheorie hat nach Gregor und Jones acht Bausteine, darunter Zweck und Geltungsbereich, Begriffe, prüfbare Aussagen und _artefact mutability_ @gregor2007anatomy. Für LLM-Artefakte ist der Baustein _Mutability_ der wichtigste: Er sagt, welche Veränderungen (anderes Modell, anderer Prompt, anderes Textkorpus) die Theorie noch abdeckt.

Zwei Formeln aus Sätzen machen den Beitrag greifbar. Das _Designprinzip_ nach Gregor und Kollegen ist ein Lückensatz @gregor2020research: Damit der Umsetzer ein Ziel für den Nutzer in einem Kontext erreicht, setze bestimmte Mechanismen ein, die bestimmte Akteure ausführen, und zwar aus einem bestimmten Grund. Die _technologische Regel_ nach Engström und Kollegen ist kürzer @engstrom2020software: Um einen Effekt in einer Situation zu erreichen, wende eine Maßnahme an.

#beispiel(titel: [Zwei Sätze für den Support-Desk-Assistenten])[
  *Regel:* Um _kalibriertes Vertrauen_ in LLM-gestützter Servicearbeit zu erreichen, wende _Quellenlinks pro Antwortsatz_ an. \
  *Prinzip:* Damit ein Werkzeughersteller erreicht, dass Support-Mitarbeiter den LLM-Antworten angemessen vertrauen, setze er in einer Umgebung mit gepflegter Wissensdatenbank Quellenlinks pro Antwortsatz und einen Konfidenzhinweis ein, der nur bei Unsicherheit erscheint, und lasse den Mitarbeiter als Prüfer mitwirken, weil Erklärungen, die auf Quellen gründen, faktisches Denken stützen.
]

Das Beispiel ist aus dem Schema gebaut, nicht aus einer Quelle abgeschrieben; der Konfidenzhinweis folgt der Studie von Reinhard und Kollegen, in der Konfidenzwerte als zu hoch wahrgenommen wurden @reinhard2026design. Engström und Kollegen raten, Neuheit auf der Ebene der Regel auszusprechen und nicht nur beim Werkzeug.

== GenAI als Artefakt und als Werkzeug

Sprachmodelle tauchen in DSR an drei Stellen auf: im Artefakt, im Werkzeugkasten der Forscher und als Quelle von Risiken (zum Risiko siehe den letzten Abschnitt). Zwei Entwicklungen verändern damit gleichzeitig, _was_ wir bauen und _wie_ wir forschen @zurheiden2026design.

=== Was genau ist das Artefakt?

Bei einem LLM-System ist die erste Frage: Was gehört zum Artefakt? Das Modell, die Prompts, die Dokumentensammlung, der Code, der alles verbindet? Feuerriegel und Kollegen unterscheiden drei Ebenen @feuerriegel2024generative: das _Modell_ selbst (etwa GPT-4), das _System_ aus Modell, Infrastruktur und Benutzeroberfläche (etwa Codex in GitHub Copilot) und die _Anwendung_, in der ein System ein Geschäftsproblem löst. Amalfitano und Kollegen zeigen mit ihrer Forschungs-Roadmap für GenAI im Software Engineering, dass DSR auch Artefakte ohne Software hervorbringt: Die Roadmap entstand in drei Zyklen @amalfitano2025research.

#studie(titel: [Reinhard et al., 2026])[
  *Gemacht:* Eine vollständige kleine DSR-Studie nach Peffers. Zwei Expertenworkshops (13 und 12 Teilnehmer) und eine Auswertung von 107 Experimentalstudien zu erklärbarer KI bildeten die Grundlage, daraus entstanden sieben Gestaltungsmerkmale für Erklärungen. Ein RAG-Prototyp auf GPT-4-Basis mit einer Telekommunikations-Wissensdatenbank aus 191 Einträgen wurde mit dem Werkzeug RAGAS getestet und anschließend von 8 erfahrenen GenAI-Nutzern beim lauten Denken (_think-aloud_: sie sagen laut, was sie denken) beobachtet, etwa 45 Minuten je Person. \
  *Ergebnis:* Die Nutzer schauten weiter vor allem auf die Antwort selbst. Konfidenzwerte wirkten zu hoch und können blindes Vertrauen erzeugen, deshalb der Vorschlag, sie nur bei Unsicherheit zu zeigen. \
  *Heißt:* Ein gutes Muster für eine Abschlussarbeit. Die Autoren nennen selbst die Grenzen: nur 8 Teilnehmer, keine Fachleute aus der Domäne, statische Erklärungen und keine quantitative Wirksamkeitsprüfung @reinhard2026design.
]

Mit FEDS beschrieben ist das laute Denken formativ und naturalistisch; die Wirksamkeit blieb unbelegt.

=== GenAI im Werkzeugkasten

Die Tabelle zeigt, wo in den sechs Schritten Sprachmodelle dokumentiert helfen und was dort schiefgehen kann. Die Belege sind unterschiedlich stark: Früh gibt es Umfragen und Prototypen, kontrollierte Experimente nur bei Entwurf und Bewertung.

#figure(
  table(columns: (auto, 1fr, 1fr),
    [Schritt], [Dokumentierte Hilfe], [Hauptrisiko],
    [Problem], [Vorschläge für Studienaspekte, Bedürfnisse aus Texten ziehen, Zugriff auf Designwissen], [erfundene Quellen, übermäßiges Vertrauen],
    [Ziele], [simulierte Nutzer, um Anforderungen zu sammeln], [künstliche Nutzer sind nicht geprüft],
    [Entwurf], [Entwürfe für Prinzipien, Modelle und Prototypen], [Antworten schwanken, Ergebnis hängt von der Formulierung ab],
    [Demonstration], [schnelles Prototyping], [nur besonders gut gelungene Beispiele],
    [Evaluation], [Kennzahlen gegen Referenzmodelle, RAG-Prüfwerkzeuge], [nur eine "richtige" Lösung, Testdaten im Training, Selbstbewertung],
    [Berichten], [keine dazu geprüfte Studie gefunden], [Modell, Version und Prompts werden nicht genannt],
  ),
  caption: [GenAI in den sechs DSRM-Schritten. Eine Lücke bleibt beim Berichten @gau2025aibased @blohm2025nextgeneration @klievtsova2023conversational @fill2026generative.],
)

Zwei Studien zeigen, wie man solche Hilfe einordnet. Memmert und Kollegen ließen GPT-3 Vorschläge zum Aufsetzen einer DSR-Studie machen; 33 Befragte hielten sie für hilfreich, mit Unterschieden je nach Erfahrung @memmert2023humanai. In 13 Experteninterviews war die größte Sorge, dass Studierende Vorschläge ohne Nachdenken übernehmen; als Gegenmittel nennen die Autoren Nachdenkphasen und gekennzeichnete KI-Inhalte @memmert2023learning. Von KI und Menschen formulierte Designprinzipien schnitten bei Zugänglichkeit, Wichtigkeit und Neuheit ähnlich ab und unterschieden sich eher bei Umsetzbarkeit @bohmer2025should. Insgesamt kann GenAI allein noch keine hochwertige Forschung liefern; je nach Rolle (Assistent, Lehrer, Kollaborateur) braucht sie andere Kontrolle @blohm2025nextgeneration.

== Messen: Korrektheit und Stabilität

Sobald ein Sprachmodell im Artefakt steckt, braucht die Bewertung Zahlen. Zwei Fragen stehen am Anfang: Wie nah ist das Ergebnis an dem, was ein Experte gebaut hätte? Und kommt beim nächsten Mal dasselbe heraus?

=== Strukturelle Korrektheit

Klievtsova und Kollegen ließen Sprachmodelle aus Textbeschreibungen Prozessmodelle erzeugen, also Diagramme für Geschäftsabläufe in der Notation BPMN. Zum Vergleichen wandelten sie jedes Modell in eine Liste von _Kanten_ um, also Pfeilen zwischen zwei Elementen, und verglichen sie mit der Liste eines Referenzmodells @klievtsova2023conversational. Iftikhar und Rausch machen dasselbe mit den Elementen von UML-Klassendiagrammen (Diagrammen für den Aufbau von Software) @iftikhar2026reliability. Aus zwei Listen lassen sich vier Kennzahlen ablesen.

#alltag[Du gibst eine Prüfung ab: 10 Antworten, davon sind 7 richtig. Die Prüfung hatte 9 Punkte zu vergeben, du hast 7 davon gefunden.]

*Precision* beantwortet: Von allem, was das Modell gezeichnet hat, wie viel stimmt? Im Bild: 7 richtige von 10 abgegebenen Antworten. *Recall* fragt: Von allem, was hätte gezeichnet werden sollen, wie viel hat das Modell gefunden? Im Bild: 7 von den 9 möglichen Punkten. *F1* mischt beides zu einer Zahl und sinkt, sobald eines von beiden niedrig ist. *Jaccard* fragt nach der Überlappung: Wie viele Elemente stehen in beiden Listen, gemessen an allen, die in mindestens einer Liste vorkommen? Alle vier Werte liegen zwischen 0 (nichts passt) und 1 (alles passt), höher ist besser.

#beispiel(titel: [Ein erzeugtes Prozessmodell])[
  Das Sprachmodell hat 10 Pfeile gezeichnet, das Referenzmodell hat 9, und 7 Pfeile stehen in beiden Listen. 3 gezeichnete Pfeile sind zu viel, 2 erwartete fehlen. Precision: 7 von 10, also 70 %. Recall: 7 von 9, also 78 %. Jaccard: 7 von 12 verschiedenen Pfeilen insgesamt (10 und 9 und dann die 7 gemeinsamen abziehen), also 58 %. F1 liegt bei 0,74, zwischen den beiden Werten und etwas näher am niedrigeren.
]

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    circle((-1.2, 0), radius: 1.9, fill: c-accent.transparentize(80%), stroke: 0.9pt + c-accent)
    circle((1.2, 0), radius: 1.9, fill: c-blue.transparentize(80%), stroke: 0.9pt + c-blue)
    content((-2.1, 2.45), text(font: "Inter", size: 7.5pt, weight: "bold", fill: c-accent.darken(10%))[Modell zeichnete: 10])
    content((2.1, 2.45), text(font: "Inter", size: 7.5pt, weight: "bold", fill: c-blue.darken(10%))[Referenz erwartet: 9])
    content((-2.1, 0), text(font: "Inter", size: 12pt, weight: "bold")[3])
    content((0, 0), text(font: "Inter", size: 12pt, weight: "bold")[7])
    content((2.1, 0), text(font: "Inter", size: 12pt, weight: "bold")[2])
    content((-2.1, -0.65), text(font: "Inter", size: 6.8pt)[zu viel])
    content((0, -0.65), text(font: "Inter", size: 6.8pt)[in beiden])
    content((2.1, -0.65), text(font: "Inter", size: 6.8pt)[fehlt])
  }),
  caption: [Zwei Listen, ein Überlapp: 7 Pfeile stimmen, 3 sind zu viel, 2 fehlen.],
) <k02-venn>

So rechnest du das in Python, ohne Bibliothek, weil es nur Mengen sind:

#datei("kanten.py")[
```python
ref = {("A","B"), ("B","C"), ("C","D"), ("C","E"), ("D","F"),
       ("E","F"), ("F","G"), ("G","H"), ("H","I")}          # 9 erwartete Pfeile
gen = {("A","B"), ("B","C"), ("C","D"), ("C","E"), ("D","F"),
       ("E","F"), ("F","G"), ("B","D"), ("G","I"), ("A","C")}  # 10 gezeichnete

treffer = len(gen & ref)                 # in beiden Listen
precision = treffer / len(gen)
recall = treffer / len(ref)
f1 = 2 * precision * recall / (precision + recall)
jaccard = treffer / len(gen | ref)       # in mindestens einer Liste

print(f"Treffer {treffer}, precision {precision:.2f}, recall {recall:.2f}")
print(f"F1 {f1:.2f}, Jaccard {jaccard:.2f}")
```
]

```out
Treffer 7, precision 0.70, recall 0.78
F1 0.74, Jaccard 0.58
```

Wie gut ist das nun? In der Studie erreichte GPT-4 mit der besten Eingabe bei den Kontrollfluss-Kanten (Pfeile, die die Reihenfolge der Schritte festlegen) einen Jaccard-Wert von 0,59 und eine Precision von 0,70. Das automatische Vergleichssystem kam auf 0,58 und 0,65, die Novizen unter den menschlichen Modellierern auf 0,47 und 0,38 @klievtsova2023conversational.

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 14pt,
    align(center)[#text(size: 8pt, weight: "bold")[Jaccard (in Prozent)] \ #balken((("GPT-4, beste Eingabe", 59), ("Automatisches System", 58), ("Novizen", 47)), max: 100, breite: 3.4, farbe: c-accent, einheit: " %", nachkomma: 0)],
    align(center)[#text(size: 8pt, weight: "bold")[Precision (in Prozent)] \ #balken((("GPT-4, beste Eingabe", 70), ("Automatisches System", 65), ("Novizen", 38)), max: 100, breite: 3.4, farbe: c-blue, einheit: " %", nachkomma: 0)],
  ),
  caption: [Kontrollfluss-Werte aus Klievtsova et al. (2023); 59 % entsprechen einem Jaccard-Wert von 0,59.],
)

GPT-4 schlug also die Novizen und lag etwa gleichauf mit dem automatischen System, mehr nicht. Zwei Einschränkungen gehören dazu: Der Testdatensatz (PET) kann in den Trainingsdaten des Modells gelandet sein, und die Ergebnisse gelten für geschlossene Modelle in genau dem Stand der Studie. Außerdem unterstellt jede Bewertung gegen ein einzelnes Expertenmodell, dass es nur eine richtige Lösung gibt. Eine gleichwertige Alternative zählt dann als Fehler @fill2026generative.

=== Stabilität bei Wiederholung

#alltag[Du stellst einem Kollegen dieselbe Frage zweimal, einmal anders formuliert. Du erwartest, dass er in beiden Fällen etwa gleich gut antwortet. Bei einem Sprachmodell darfst du das nicht voraussetzen.]

Iftikhar und Rausch haben das gemessen: 2 Aufgaben, jeweils in 3 Formulierungen, je 10 Läufe, 3 Sprachmodelle und 3 Prompt-Strategien ergeben 540 Experimente bei Temperatur 0,5 (der Einstellung, die steuert, wie stark Antworten streuen). Experten gaben jeder Entwurfsregel 0, 0,5 (teilweise) oder 1 Punkt. Daraus entsteht der *Adherence-Score* (PAS), der Anteil der erfüllten Regeln, zum Beispiel 12 von 15, also 0,8. Zusätzlich berechneten sie einen *Stability Index* (SI): eine Zahl zwischen 0 und 1, die bei 1 sagt, dass die Qualität weder durch Umformulieren noch durch Wiederholen schwankt @iftikhar2026reliability.

Gemessen wurde zum Beispiel ein SI von 0,77 für Claude 3.5 Sonnet mit Standard-Prompt und 1 mit den anderen Strategien, bei GPT-4o-mini überall 1, bei Gemini 2.5 Flash etwa 0,905 bis 0,907; Text und Tabelle der Arbeit widersprechen sich teilweise, welches Modell am stabilsten ist. Die Arbeit sagt auch nicht, wie die beiden Schwankungen geschätzt wurden. Der folgende Ablauf ist deshalb der Vorschlag des Kurses: Man vergleicht die Mittelwerte der drei Formulierungen untereinander (Schwankung durch Umformulieren) und die Läufe innerhalb einer Formulierung (Schwankung durch Wiederholen).

#datei("stabilitaet.py")[
```python
from statistics import mean, pstdev, pvariance

# F1-Wert je Lauf: 3 Formulierungen der Aufgabe x 10 Läufe
abw = [-0.15, -0.10, -0.10, -0.05, -0.05, 0.05, 0.05, 0.10, 0.10, 0.15]
scores = {
    "A": [round(0.50 + d, 2) for d in abw],
    "B": [round(0.55 + d, 2) for d in reversed(abw)],
    "C": [round(0.45 + d, 2) for d in abw[3:] + abw[:3]],
}
mittel = {k: mean(v) for k, v in scores.items()}
zw_form = pstdev(mittel.values())                       # zwischen Formulierungen
zw_lauf = mean(pstdev(v) for v in scores.values())      # zwischen Läufen
si = 1 / (1 + pvariance(mittel.values())
            + mean(pvariance(v) for v in scores.values()))
print({k: round(m, 2) for k, m in mittel.items()})
print(f"Streuung: Formulierung {zw_form:.3f}, Lauf {zw_lauf:.3f}, SI {si:.3f}")
```
]

```out
{'A': 0.5, 'B': 0.55, 'C': 0.45}
Streuung: Formulierung 0.041, Lauf 0.097, SI 0.989
```

Der SI beträgt fast 1 und sieht damit makellos aus. Trotzdem weicht ein einzelner Lauf typischerweise um etwa 0,10 von seinem Mittelwert ab, und das ist viel auf einer Skala, die nur von 0 bis 1 reicht. Der Grund: Bei Werten zwischen 0 und 1 sind die Schwankungen immer klein, und der Index wird zwangsläufig Richtung 1 gedrückt. Der Foliensatz rechnet dieselbe Idee mit leicht anderen Zahlen vor (SI 0,988).

#fallstrick[Berichte nie nur den Stability Index. Gib immer die beiden Schwankungen getrennt an, also wie stark die Ergebnisse zwischen den Formulierungen und wie stark sie zwischen den Läufen auseinanderliegen. Ein SI von 0,99 kann eine Streuung verbergen, die für deine Aussage zu groß ist.]

Dass das kein Randproblem ist, zeigt die Studie von Klievtsova und Kollegen: Für dieselbe Prozessbeschreibung bekamen nur 52 % der erzeugten Modelle bei mehrfacher Erzeugung dasselbe Korrektheitsurteil @klievtsova2023conversational. Eine einfache Art, das selbst zu prüfen, ist die _Übereinstimmung zwischen Läufen_: bei wie vielen von 100 Eingaben bekommen zwei Läufe dasselbe Urteil? Diese Zahl berücksichtigt den Zufall nicht (das geht mit Cohen's kappa, siehe Kapitel 5).

#hoersaal([Ist ein Jaccard von 0,59 denn gut?], [Das lässt sich nur im Vergleich sagen. In der Studie schlug es die menschlichen Novizen und lag gleichauf mit einem automatischen System. Ob es für deinen Zweck reicht, hängt davon ab, was ein Fehler im Diagramm kostet, und das musst du vorab festlegen.])

Die Übung zum Foliensatz (Exercise 02, kein Notebook) lässt dich beides selbst messen: Teil 1 mit den 45 Prozessbeschreibungen des PET-Datensatzes (MIT-Lizenz, Stand: 11. November 2026), Teil 2 mit drei Formulierungen, 10 Läufen und zwei Temperaturen. Protokolliere Modellname, Version, Datum, Parameter und alle Prompts im Wortlaut.

== Risiken und gute Praxis

zur Heiden und Kollegen werteten neuere DSR-Arbeiten aus führenden Fachzeitschriften aus und nennen fünf Herausforderungen, die sie für wesentlich tiefgreifender halten, als bisher diskutiert @zurheiden2026design. Dazu formulieren sie drei Leitlinien, deren Inhalt uns nicht vorliegt. Die Fragen in der zweiten Spalte sind unsere: je ein Prüfpunkt für deine Arbeit.

#figure(
  table(columns: (auto, 1fr),
    [Herausforderung], [Prüffrage für deine Arbeit],
    [Unklare Zusammensetzung], [Welche Teile gehören zum Artefakt: Modell, Prompts, Dokumente, Ablaufsteuerung?],
    [Undurchsichtiger Kontext], [Welches Modell, in welcher Version, in welcher Umgebung läuft es?],
    [Brüchige innere Stimmigkeit], [Verhalten sich die Teile über mehrere Läufe hinweg gleich?],
    [Verfall des Gestaltungswissens (_eroding prescriptive knowledge_)], [Gelten deine Prinzipien noch, wenn das Modell ausgetauscht wird?],
    [Fehlende Methodenanleitung], [Wie begründest du deine Prozessentscheidungen?],
  ),
  caption: [Fünf Herausforderungen für DSR mit generativer KI.],
)

Der vierte Punkt ist der wichtigste: Designprinzipien, die an eine Modellversion (einen _Snapshot_, also einen festgeschriebenen Stand) gebunden sind, können ungültig werden, wenn das Modell ersetzt wird. Wie schnell das geht, zeigen die Modelle der besprochenen Studien (Stand: 11. November 2026, laut den Abkündigungsseiten der Anbieter): `gpt-3.5-turbo`, `gpt-4` und `gpt-4o-2024-05-13` hat OpenAI am 23. Oktober 2026 abgeschaltet, drei weitere GPT-4o-Versionen sollen am 14. Januar 2027 folgen. Beide Snapshots von Claude 3.5 Sonnet sind seit dem 28. Oktober 2025 abgeschaltet. Gemini 2.5 Flash läuft weiter, aber nur für bestehende Nutzer. LLaMA 2 und 3 haben offene Gewichte, ob sie verfügbar bleiben, haben wir nicht geprüft. Eine Wiederholung mit den Originalmodellen ist deshalb meist unmöglich. Offene Modelle sind besser prüfbar, geschlossene liegen bei der Qualität noch deutlich vorne @fill2026generative.

Neben diesen grundsätzlichen gibt es handfeste Gefahren für die Gültigkeit deiner Ergebnisse:

#figure(
  table(columns: (auto, 1fr),
    [Gefahr], [Was passiert],
    [*Non-determinism*], [Gleiche Eingabe, andere Ausgabe; Umformulieren ändert das Ergebnis @iftikhar2026reliability],
    [*Data contamination*], [Der Benchmark steckt womöglich schon in den Trainingsdaten @klievtsova2023conversational],
    [*Single ground truth*], [Kennzahlen gegen ein Referenzmodell bestrafen gleichwertige Entwürfe @fill2026generative],
    [*Self-evaluation*], [Die Entwickler bewerten ihr eigenes Artefakt, wie bei der Plattform PsyCogMetrics @jin2026developing],
    [*Over-reliance*], [Nutzer übernehmen Vorschläge ungeprüft; Konfidenzhinweise verleiten zu blindem Vertrauen @memmert2023learning],
    [*Schwache Effizienzaussagen*], [Zeitersparnis wird geschätzt statt gemessen: Eine Studie nannte etwa 130 Minuten mit GenAI gegen geschätzte 180 bis 210 ohne und nennt den Vergleich selbst nicht streng @brehmer2024educators],
    [*Synthetic users*], [Gültigkeit simulierter Beteiligter unbekannt; sie müssen gegen echte Daten geprüft werden @blohm2025nextgeneration],
  ),
  caption: [Gültigkeitsgefahren bei Artefakten mit Sprachmodellen.],
)

Daraus ergibt sich eine Reihenfolge für die Evaluation (die _Baseline_ ist eine einfache Vergleichslösung, etwa die alte Suche): zuerst das technische Risiko beherrschen, dann zeigen, dass echte Nutzer einen Nutzen haben. Das wendet die FEDS-Logik auf Artefakte mit Zufallsanteil an; FEDS selbst nennt diese Abfolge nicht. Setzt du ein Sprachmodell als Bewerter ein, gilt das ebenfalls als künstliche Episode, die du gegen menschliche Urteile prüfen musst (Kapitel 7).

#figure(
  diagram(spacing: (7mm, 8mm), node-corner-radius: 3pt,
    fknoten((0, 0), [*Künstlich, formativ* \ Wiederholungsläufe, Umformulierungen, Contamination-Check], col: c-accent, filled: true, w: 50mm),
    fknoten((1, 0), [*Künstlich, summativ* \ Vergleich mit Baseline; LLM-Judge gegen Menschen geprüft], col: c-blue, w: 50mm),
    fknoten((2, 0), [*Naturalistisch, summativ* \ echte Nutzer, echte Aufgaben, über längere Zeit], col: c-accent, filled: true, w: 50mm),
    edge((0, 0), (1, 0), "->"), edge((1, 0), (2, 0), "->"),
  ),
  caption: [Eine Evaluationsfolge für ein LLM-Artefakt.],
)

Zur Planung der ganzen Arbeit auf einer Seite dient das _DSR Grid_ von vom Brocke, Hevner und Maedche mit sechs Feldern: Problem, vorhandenes Wissen, Forschungsprozess, Schlüsselbegriffe, Lösung und neues Wissen @vombrocke2020introduction. Für LLM-Artefakte ergänzt du Grenze des Artefakts, Mutability, Wiederholungs- und Contamination-Episoden und versionierte Protokolle von Modellen, Prompts und Ausgaben.

== In der Praxis: Dein DSR-Plan in neun Schritten

Mit diesem Ablauf planst du eine Abschlussarbeit, die ein LLM-Artefakt baut. Jeder Schritt ist ein Satz in deinem Plan.

+ *Problem benennen.* Wer hat welches Problem, woran erkennst du es, und warum lösen bestehende Lösungen es nicht?
+ *Ziele festlegen.* Was muss die Lösung leisten, messbar formuliert? Lege Schwellen vorab fest.
+ *Artefakt abgrenzen.* Welche Ebene (Modell, System, Anwendung) und welche Teile (Prompts, Dokumente, Steuerung) gehören dazu?
+ *Beitragsart bestimmen.* Erfindung, Verbesserung, Exaptation oder Routine, und warum?
+ *Prinzip und Regel formulieren.* Je ein Satz im Lückenformat.
+ *Evaluation mit FEDS planen.* Strategie wählen, Eigenschaften festlegen, Episoden entwerfen; mindestens eine künstlich-formative mit Wiederholungsläufen und eine naturalistisch-summative.
+ *Messen.* Korrektheit gegen eine Referenz, dazu Stabilität über Formulierungen und Läufe; beide Streuungen getrennt berichten.
+ *Alles protokollieren.* Modellname, exakte Version, Datum, Parameter, vollständige Prompts, Ausgaben. Offene Modelle mit festem Stand erleichtern das.
+ *Risiken benennen.* Pro Episode die Gefahr nennen, die sie adressiert (Contamination, Selbstbewertung, Modell-Snapshot, übermäßiges Vertrauen).

#praxis[Nimm eine Mutability-Aussage in den Plan auf, etwa "Das Prinzip gilt für jedes Modell dieser Größenklasse, solange die Quellenlinks erhalten bleiben." Ein Modellwechsel wird dann zum Test deiner Theorie statt zum Ende deiner Arbeit.]

== Für die Lehre

*"DSR heißt, ich baue etwas."* Nein, es heißt, ich baue etwas und sage, was andere daraus lernen. Frag nach dem Satz, der mit "Um ... zu erreichen, wende ... an" beginnt. Kann ihn der Studierende nicht formulieren, fehlt der Beitrag.

*"Mein Prototyp läuft, also ist er evaluiert."* Demonstration zeigt nur, dass es an einem Fall geht. Lass die Gruppe den Prototyp in die FEDS-Matrix einordnen und fragen, welches Feld noch leer ist.

*"Ein hoher Jaccard-Wert beweist Qualität."* Er sagt nur, wie ähnlich zwei Listen sind. Ist die Referenz nur eine von mehreren gleichwertigen Lösungen, wird eine gute Alternative bestraft.

*"Ein Sprachmodell antwortet auf dieselbe Frage immer gleich."* Lass die Gruppe live fünfmal denselben Entwurfs-Prompt laufen und die Ausgaben vergleichen. Die 52 % Übereinstimmung kommen dann von allein.

#kurz(
  [DSR macht aus Bauen Forschung, wenn Problem, Bewertung und übertragbarer Beitrag zusammenkommen.],
  [Drei Zyklen und sechs DSRM-Schritte geben dem Projekt ein Gerüst; man darf an vier Stellen einsteigen und zurückspringen.],
  [FEDS ordnet jede Evaluation nach Zweck (verbessern oder beurteilen) und Ort (kontrolliert oder real), die Strategie folgt dem Hauptrisiko.],
  [Beitragsarten (Invention, Improvement, Exaptation, Routine) und Stufen der Theorie zeigen, wie viel Neues drinsteckt; ein Prinzip und eine Regel machen es greifbar.],
  [Bei LLM-Artefakten gehören Wiederholungsläufe dazu: Precision, Recall, F1 und Jaccard für die Korrektheit, getrennte Streuungen für die Stabilität.],
  [Die größten Risiken sind Antwortschwankung, Testdaten im Training, Selbstbewertung und abgeschaltete Modellversionen; Protokolle und ein Plan fangen sie ab.],
)

#selbsttest(
  ([Wodurch unterscheidet sich ein Forschungsprojekt von einem normalen Entwicklungsprojekt, wenn beide ein Artefakt bauen?], [Das Forschungsprojekt löst ein relevantes Problem, bewertet das Ergebnis streng und hält einen übertragbaren Beitrag fest, etwa ein Prinzip. Beim Routineprojekt reicht, dass es funktioniert.]),
  ([Nenne die drei Zyklen und was jeder liefert.], [Der Relevanz-Zyklus liefert Anforderungen aus der Umwelt, der Rigour-Zyklus Theorien und Methoden aus der Wissensbasis, der Design-Zyklus ist die Schleife aus Bauen und Bewerten.]),
  ([Du hast einen RAG-Chatbot gebaut und lässt Support-Mitarbeiter ihn eine Woche lang im Alltag nutzen, um ihn zu verbessern. In welches FEDS-Feld gehört das?], [Formativ (zum Verbessern) und naturalistisch (echte Nutzer, echte Aufgaben).]),
  ([Von 10 gezeichneten Pfeilen sind 6 richtig, im Referenzmodell stehen 8. Wie groß sind Precision und Recall?], [Precision 6 von 10, also 60 %. Recall 6 von 8, also 75 %.]),
  ([Warum reicht ein Stability Index von 0,99 nicht als Nachweis, dass ein LLM-Artefakt stabil ist?], [Der Index wird bei Werten zwischen 0 und 1 immer nahe an 1 gedrückt und verbirgt etwa 0,10 Abweichung pro Lauf. Darum berichtet man beide Streuungen getrennt.]),
  ([Was heißt "Verfall des Gestaltungswissens", und was kannst du dagegen tun?], [An eine Modellversion gebundene Prinzipien können mit dem Modell ungültig werden. Dagegen helfen eine Mutability-Aussage, ein Protokoll von Modell, Version und Prompts und abstraktere Prinzipien.]),
)

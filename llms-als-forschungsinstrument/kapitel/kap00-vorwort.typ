#import "../lib.typ": *

#set heading(numbering: none)
= Bevor es losgeht

Große Sprachmodelle sind in der Forschung in wenigen Jahren von einer Kuriosität zu einem Werkzeug geworden, das in fast jeder Phase eines Projekts auftaucht. Sie formulieren Suchstrings für Literaturreviews, codieren Interviewtranskripte, beantworten Fragebögen als "synthetische Befragte", bewerten die Ausgaben anderer Modelle und stecken als Generator in RAG-Systemen, die selbst wieder Forschungsgegenstand sind. Jede dieser Rollen wirft dieselbe alte Frage der empirischen Forschung neu auf: Was genau misst dieses Instrument, wie zuverlässig tut es das, und welche Schlüsse sind auf dieser Grundlage noch zulässig?

Die Antworten darauf sind unbequemer, als der Alltag mit Chat-Oberflächen vermuten lässt. Übereinstimmung auf Label-Ebene garantiert keine korrekten Regressionskoeffizienten: In der großen Replikationsstudie von Baumann et al. kamen unkorrigierte Mensch-LLM-Mischdesigns auf Fehlerraten erster Art von etwa 30 bis 40 Prozent, während schon rund 100 rein menschliche Labels den Fehler erster Art bei etwa 10 Prozent hielten @baumann2025large. Ein LLM-Richter, der bei einer binären Bewertung nicht besser urteilt, als das bewertete Modell seine Aufgabe löst, kann die Zahl der benötigten menschlichen Referenzlabels höchstens halbieren, egal wie viele Richterurteile man zusätzlich sammelt @dorner2025limits. Und selbst "deterministische" Einstellungen gehosteter Modelle liefern bei wiederholten Läufen nicht zuverlässig identische Ausgaben @atil2025nondeterminism. Wer mit LLMs forscht, braucht deshalb nicht nur gute Prompts, sondern Messtheorie, Inferenzstatistik und ein sauberes Protokoll.

Genau dafür ist dieses Handbuch geschrieben. Es behandelt LLMs durchgehend als *messbare Forschungsinstrumente*: Jedes Kapitel endet bei etwas, das man berechnen, implementieren oder empirisch prüfen kann, und jede Methode wird so weit hergeleitet, dass du sie nicht nur anwenden, sondern auch verteidigen kannst.

== Für wen dieses Buch ist

Das Buch ist in erster Linie ein persönliches Arbeitsbuch für die Vorbereitung und Durchführung der Lehrveranstaltung ELEC1-GAIRI "Generative AI in Research and Innovation" im Master Data Intelligence an der USTP. Es richtet sich an dich als jemanden, der Forschungsmethodik bereits unterrichtet, Statistik auf Master-Niveau beherrscht und selbst empirisch zu LLMs publiziert, der aber die neuen Methodenstränge (Prediction-Powered Inference, LLM-as-a-Judge-Metaevaluation, Bias-Messung, RAG-Qualitätsmodelle) so sicher können will, dass auch die unangenehme Frage aus der dritten Reihe keine Verlegenheit auslöst.

Daraus folgen drei Ansprüche, die das Buch von den Folien der LV unterscheiden:

- *Tiefe vor Breite.* Wo die Folien eine Formel zeigen, leitet das Buch sie her, rechnet ein Beispiel vollständig durch und benennt die Annahmen, unter denen sie gilt. Wo die Folien eine Studie zitieren, nennt das Buch Design, Daten, Befund und Grenzen.
- *Forschungsstand mit Kontroversen.* Zu fast jedem Thema gibt es eine optimistische und eine skeptische Literatur. Beide kommen zu Wort, mit konkreten Zahlen und Quellen, und jedes Kapitel hat einen Abschnitt zu offenen Fragen.
- *Lehrperspektive.* Jedes Kapitel schließt mit einem Abschnitt "Für die Lehre": wie man das Thema aufbaut, welche Missverständnisse bei Studierenden typisch sind und wie viel Zeit man realistisch braucht.

Das Buch ist trotzdem nicht nur für dich lesbar. Wer an einer Dissertation oder Masterarbeit mit LLM-gestützter Datenerhebung arbeitet und die statistischen Grundlagen mitbringt, findet hier ein vollständiges Methodenhandbuch. Vorausgesetzt werden Wahrscheinlichkeitsrechnung, lineare Regression, Konfidenzintervalle und Hypothesentests sowie Grundkenntnisse in Python. Was über diesen Standard hinausgeht (M-Schätzer, Sandwich-Varianzen, Kontrollvariaten), wird dort eingeführt, wo es gebraucht wird.

== Aufbau in vier Teilen

Die zehn Kapitel folgen der Reihenfolge der zehn Foliensätze der LV und sind in vier Teile gegliedert. @vw-tab-aufbau gibt den Überblick.

#figure(
  table(
    columns: (auto, 1fr, 1.6fr),
    table.header([Teil], [Kapitel], [Kernfragen]),
    [I · Forschen mit Methode], [1 Forschungsmethoden \ 2 Design Science Research], [Paradigmen, Designs, qualitative und quantitative Forschung, Mixed Methods, Effektstärken und Power, Replikationskrise, Validität; Artefakte, DSRM-Prozess, Wissensbeitrag, Evaluation und GenAI als Artefakt und Werkzeug im DSR-Prozess],
    [II · Das LLM als Werkzeug und Instrument], [3 Prompt- und Context-Engineering \ 4 LLMs als Forschungsinstrument], [Promptsensitivität, Mehrprompt-Evaluation, strukturierte Ausgaben, Kosten und Caching, Context-Engineering, Prompt Injection; Silicon Samples, Repräsentativität, Flattening, Effektvalidität simulierter Experimente, AI Scientists],
    [III · Messen, Schließen, Bewerten], [5 LLMs als Annotatoren \ 6 Valide Inferenz mit LLM-Labels \ 7 LLM-as-a-Judge], [Übereinstimmungsmaße und ihre Paradoxa, Alternative Annotator Test, induktives Codieren; PPI, PPI++, DSL, aktive Inferenz; Verzerrungen von Richtern, Bradley-Terry, Längenkontrolle, Grenzen der Labelersparnis],
    [IV · Qualität, Fairness, Reproduzierbarkeit], [8 Bias-Metriken \ 9 Qualitätsmodelle für RAG \ 10 Reproduzierbare Workflows], [WEAT, StereoSet, BBQ, Gruppenfairness, kontrafaktische Audits; ISO/IEC 25010, IR- und claim-basierte Metriken, Validität automatischer Metriken; Nichtdeterminismus, TAR\@N, Kostenmodell, LLM-gestützte Literaturreviews, Berichtsstandards, Regulierung],
  ),
  caption: [Die vier Teile des Buchs und ihre Kernfragen.],
) <vw-tab-aufbau>

Teil I legt das methodische Fundament und knüpft eng an das Lehrbuch @haindl2027research an. Teil II betrachtet das LLM zuerst als Werkzeug, dessen Verhalten von Formulierung, Format und Kontext abhängt, und dann als Instrument, das menschliche Befragte oder Versuchspersonen ersetzen soll. Teil III ist das statistische Herzstück: Er verfolgt die Messkette vom einzelnen LLM-Label über die Übereinstimmung mit Menschen bis zur korrigierten Populationsschätzung und überträgt sie auf LLMs als Bewerter. Teil IV wendet diese Werkzeuge auf drei Qualitätsdimensionen an, die in Abschlussarbeiten und Publikationen regelmäßig gefordert werden: Fairness, Qualität von RAG-Systemen und Reproduzierbarkeit.

Im Anhang findest du eine *Formelsammlung* (Anhang A) mit allen zentralen Formeln nach Themen geordnet, die *Lösungen* aller Selbsttestfragen (Anhang B) und ein *Glossar* (Anhang C) mit deutschen und englischen Fachbegriffen.

=== Aufbau eines Kapitels

Alle Kapitel folgen demselben Muster. Nach einer kurzen Einstiegsprosa nennt ein Kasten die Lernziele. Jedes Konzept wird dann in derselben Reihenfolge entwickelt: Intuition, formale Definition, Herleitung oder Begründung, Rechenbeispiel mit nachgerechneten Zahlen, Grenzen und Fallstricke, Bezug zur eigenen Forschung. Studienkästen fassen einzelne Arbeiten zusammen, ein Abschnitt zu Debatten sammelt die offenen Streitpunkte. Ein Praxisteil zeigt Python-Ausschnitte und verweist auf das passende Notebook. Der Abschnitt "Für die Lehre" und ein Selbsttest mit zwölf bis sechzehn Fragen schließen das Kapitel ab.

== Lesepfade

Das Buch lässt sich linear lesen, muss es aber nicht. Je nach Ziel bieten sich drei Wege an.

*Schnell vorbereiten.* Vor einem Blocktag reicht oft ein gezielter Durchgang: Lernziele, die Merke- und Fallstrick-Kästen, die Rechenbeispiele, die Fragen aus dem Hörsaal und der Abschnitt "Für die Lehre". Danach den Selbsttest ohne Blick in den Text beantworten und nur dort nachlesen, wo es hakt. Für die Formeln genügt in diesem Modus Anhang A.

*Tief einarbeiten.* Wer ein Thema wirklich beherrschen will, liest das Kapitel von vorne, rechnet die Beispiele mit Papier und Python mit, arbeitet die Beweisskizzen durch und öffnet parallel das Notebook. Die Kästen "Zum Weiterlesen" nennen die Primärquellen, die sich als nächster Schritt lohnen.

*Nachschlagen.* Für die Betreuung von Abschlussarbeiten oder ein Review genügt oft eine einzelne Kennzahl oder Definition. Dafür sind Formelsammlung und Glossar gedacht; beide verweisen auf das Kapitel, in dem der Begriff ausführlich behandelt wird.

=== Abhängigkeiten zwischen den Kapiteln

Die Kapitel bauen nicht streng linear aufeinander auf. @vw-abb-pfade zeigt, welche Kapitel für welche anderen vorausgesetzt werden (durchgezogene Pfeile) und wo ein früheres Kapitel hilfreich, aber nicht nötig ist (gestrichelte Pfeile).

#figure(
  {
    set text(font: "Inter", size: 7.5pt)
    diagram(
      spacing: (9mm, 7mm),
      edge-stroke: 0.8pt + c-dark,
      mark-scale: 70%,
      node((0, -0.75), text(weight: "bold", fill: c-grey.darken(20%), tracking: 0.08em)[TEIL I]),
      node((1, -0.75), text(weight: "bold", fill: c-grey.darken(20%), tracking: 0.08em)[TEIL II]),
      node((2, -0.75), text(weight: "bold", fill: c-grey.darken(20%), tracking: 0.08em)[TEIL III]),
      node((3, -0.75), text(weight: "bold", fill: c-grey.darken(20%), tracking: 0.08em)[TEIL IV]),
      fknoten((0, 0), [*1* Forschungs-\ methoden], col: c-blue, name: <k1>),
      fknoten((0, 2), [*2* Design Science\ Research], col: c-blue, name: <k2>),
      fknoten((1, 0), [*3* Prompt- und\ Context-Engineering], col: c-violet, name: <k3>),
      fknoten((1, 2), [*4* LLMs als\ Instrument], col: c-violet, name: <k4>),
      fknoten((2, 0), [*5* LLMs als\ Annotatoren], col: c-accent, name: <k5>),
      fknoten((2, 1), [*6* Valide Inferenz\ (PPI, DSL)], col: c-accent, name: <k6>),
      fknoten((2, 2), [*7* LLM-as-a-\ Judge], col: c-accent, name: <k7>),
      fknoten((3, 0), [*8* Bias-\ Metriken], col: c-teal, name: <k8>),
      fknoten((3, 1), [*9* RAG-\ Qualität], col: c-teal, name: <k9>),
      fknoten((3, 2), [*10* Forschungs-\ workflows], col: c-teal, name: <k10>),
      edge(<k1>, <k2>, "-|>"),
      edge(<k1>, <k3>, "-|>", stroke: (dash: "dashed")),
      edge(<k1>, <k4>, "-|>"),
      edge(<k3>, <k5>, "-|>"),
      edge(<k3>, <k4>, "-|>", stroke: (dash: "dashed")),
      edge(<k5>, <k6>, "-|>"),
      edge(<k6>, <k7>, "-|>"),
      edge(<k5>, <k8>, "-|>", stroke: (dash: "dashed")),
      edge(<k6>, <k9>, "-|>"),
      edge(<k7>, <k9>, "-|>"),
      edge(<k7>, <k10>, "-|>", stroke: (dash: "dashed")),
      edge(<k2>, <k4>, "-|>", stroke: (dash: "dashed")),
      edge(<k4>, <k7>, "-|>", stroke: (dash: "dashed")),
    )
  },
  caption: [Abhängigkeiten der Kapitel. Durchgezogen: wird vorausgesetzt; gestrichelt: hilfreich. Die Farben markieren die vier Teile.],
) <vw-abb-pfade>

Drei Achsen tragen das ganze Buch und eignen sich auch als thematische Lesepfade:

- *Die Messkette* (Kapitel 5 -> 6 -> 7): Wie gut stimmen LLM-Labels mit Menschen überein, wie wird aus fehlerbehafteten Labels eine valide Schätzung, und was ändert sich, wenn das LLM nicht Texte codiert, sondern Modellausgaben bewertet? Wer nur Zeit für einen Pfad hat, sollte diesen wählen.
- *Die Evaluationsachse* (Kapitel 3 -> 7 -> 9): Von der Sensitivität einzelner Prompts über die Metaevaluation von Richtern bis zu den Metriken für RAG-Systeme, die zu einem großen Teil selbst LLM-Richter sind.
- *Die Protokollachse* (Kapitel 1 -> 3 -> 10): Präregistrierung, Gabelungen im Analysepfad und multiple Tests in Kapitel 1 finden ihre LLM-spezifische Fortsetzung in der Konfigurationsvielfalt von Prompts und Modellen und in den Reproduzierbarkeitsprotokollen von Kapitel 10.

Kapitel 2 und Kapitel 8 stehen etwas abseits: Design Science Research ist der methodische Rahmen, in dem viele Abschlussarbeiten im Data-Intelligence-Master entstehen, und Bias-Metriken lassen sich nach Kapitel 5 weitgehend eigenständig lesen.

== Konventionen

=== Kästen

Wiederkehrende Elemente sind farbig abgesetzt. @vw-tab-kaesten listet alle Kastentypen, darunter folgen drei Beispiele in Originalgestalt.

#figure(
  table(
    columns: (auto, auto, 1fr),
    table.header([Kasten], [Farbe], [Inhalt und Gebrauch]),
    [In diesem Kapitel], text(fill: c-accent)[orange], [Lernziele am Kapitelanfang, als prüfbare Fähigkeiten formuliert],
    [Definition], text(fill: c-blue)[blau], [formale Definition eines Begriffs, pro Kapitel nummeriert (Definition 5.3)],
    [Satz], text(fill: c-violet)[violett], [mathematische Aussage mit Voraussetzungen, meist gefolgt von einer Beweisskizze],
    [Beweisskizze], text(fill: c-grey.darken(20%))[grau, Linie], [Herleitung in nachvollziehbaren Schritten, endet mit $square$],
    [Rechenbeispiel], text(fill: c-teal)[türkis], [vollständig durchgerechnetes Beispiel; alle Zahlen mit Python nachgerechnet],
    [Studie], text(fill: c-yellow)[gelb], [eine Arbeit mit Design, Daten, Befund und Grenzen],
    [Merke], text(fill: c-blue)[blau], [die Kernaussage eines Abschnitts in ein bis drei Sätzen],
    [Fallstrick], text(fill: c-red)[rot], [typischer Fehler in Analyse, Berichterstattung oder Interpretation],
    [Aus der Praxis], text(fill: c-yellow)[gelb], [Umsetzung in eigenen Projekten, Werkzeuge, Betreuungserfahrung],
    [Tipp], text(fill: c-green)[grün], [kurze, sofort anwendbare Empfehlung],
    [Frage aus dem Hörsaal], text(fill: c-violet)[violett], [realistische, oft kritische Frage mit ausformulierter Antwort],
    [Zum Weiterlesen], text(fill: c-grey.darken(20%))[grau], [kommentierte Primär- und Übersichtsliteratur],
  ),
  caption: [Kastentypen und ihre Bedeutung.],
) <vw-tab-kaesten>

#callout("Definition · Cohens Kappa", c-blue)[
  Für zwei Codierende mit beobachteter Übereinstimmung $p_o$ und der aus ihren eigenen Randverteilungen erwarteten Zufallsübereinstimmung $p_e^C$ ist $kappa = (p_o - p_e^C) \/ (1 - p_e^C)$ @cohen1960coefficient.
]
#fallstrick[
  Dieselbe prozentuale Übereinstimmung von 90 Prozent kann je nach Prävalenz der Kategorien ein Kappa von 0.80, von 0.44 oder von knapp unter null ergeben. Ein fester Schwellenwert ohne Randverteilungen ist deshalb wenig aussagekräftig (Kapitel 5).
]
#hoersaal([Wenn das LLM mit meinem Codierer besser übereinstimmt als die zweite Codiererin, ist es dann nicht einfach besser?], [Nicht unbedingt. Ob "LLM-Mensch-Übereinstimmung übersteigt Mensch-Mensch-Übereinstimmung" gilt, hängt davon ab, welcher Mensch als Referenz dient. Genau deshalb arbeitet der Alternative Annotator Test mit einem Leave-one-out-Design über alle menschlichen Annotatoren @calderon2025alternative.])

Die Nummerierung von Definitionen, Sätzen, Rechenbeispielen und Studien läuft pro Kapitel über einen gemeinsamen Zähler: Auf Definition 6.1 folgt Rechenbeispiel 6.2, nicht Rechenbeispiel 6.1. So findest du jedes Element über eine einzige Nummer wieder.

=== Notation

Mathematik folgt der in der Statistik üblichen Schreibweise. Skalare sind kursiv ($n$, $theta$), Matrizen groß ($X$), Schätzer tragen ein Dach ($hat(theta)$), Mittelwerte einen Querstrich ($macron(x)$ oder $overline(x)$). $bb(E)$, $"Var"$ und $"Cov"$ bezeichnen Erwartungswert, Varianz und Kovarianz, $bb(1)[dot.op]$ die Indikatorfunktion und $z_q$ das $q$-Quantil der Standardnormalverteilung. Die folgenden Konventionen ziehen sich durch die Kapitel 5 bis 9:

#figure(
  table(
    columns: (auto, 1fr),
    table.header([Symbol], [Bedeutung]),
    [$n$, $N$], [Anzahl der Einheiten mit menschlichem Referenzlabel (Goldstichprobe) bzw. Anzahl der nur vom LLM gelabelten Einheiten],
    [$Y_i$, $f(X_i)$, $hat(Y)_i$], [menschliches Label, Vorhersage oder Label des LLM für Einheit $i$; $f(X_i)$ und $hat(Y)_i$ werden synonym verwendet],
    [$theta$, $theta^*$], [Zielgröße (Estimand), z. B. eine Prävalenz oder ein Regressionskoeffizient; $theta^*$ ist ihr wahrer Wert],
    [$p_o$, $p_e$], [beobachtete bzw. unter einem Zufallsmodell erwartete Übereinstimmung],
    [$rho$], [je nach Kontext Korrelation (PPI, Dorner-Schranke) oder Vorteilswahrscheinlichkeit (Alt-Test); die Formelsammlung nennt die Bedeutung jeweils explizit],
    [$alpha$], [Signifikanzniveau oder Krippendorffs Alpha; die Bedeutung ergibt sich aus dem Kontext, die Formelsammlung nennt sie explizit],
  ),
  caption: [Häufig verwendete Symbole.],
) <vw-tab-notation>

Die Mehrfachbelegung von $rho$ und $alpha$ ist in der Literatur so verbreitet, dass eine buchweite Umbenennung das Lesen der Primärquellen erschweren würde. Gleichungen werden pro Kapitel nummeriert, (6.3) ist also die dritte nummerierte Gleichung in Kapitel 6; die Formelsammlung verweist mit diesen Nummern auf die Kapitel.

=== Zahlen

Dezimalzahlen werden im ganzen Buch mit Punkt geschrieben (z. B. 0.85), weil Formeln, Code, Bibliotheksausgaben und die zitierten Quellen diese Schreibweise verwenden. Tausender ab 10 000 werden mit einem schmalen geschützten Leerzeichen gegliedert (19 830), Zahlen unter 10 000 stehen ohne Trenner (1573).

=== Code

Codeausschnitte sind in Python geschrieben und mit den Paketversionen getestet, die in der Wissensbasis dokumentiert sind (unter anderem Python 3.13, scikit-learn 1.9.1, statsmodels 0.15.0, krippendorff 0.9.0, pingouin 0.7.0 und ppi_py 0.2.3; Stand: 11. November 2026). Ein dunkler Dateikopf nennt den Dateinamen, Ausgaben sind gestrichelt umrandet:

#grid(columns: (1.75fr, 1fr), column-gutter: 12pt,
[
#datei("kappa_e1.py")[
```python
from sklearn.metrics import cohen_kappa_score

human = [0] * 50 + [1] * 50
llm = [0] * 40 + [1] * 10 + [0] * 5 + [1] * 45
p_o = sum(h == l for h, l in zip(human, llm)) / 100
print(f"p_o   = {p_o:.3f}")
print(f"kappa = {cohen_kappa_score(human, llm):.3f}")
```
]
],
[
#v(1.4em)
```out
p_o   = 0.850
kappa = 0.700
```
])

Die Ausschnitte sind bewusst kurz und rechnen meist ein Beispiel aus dem Text nach. Vollständige, lauffähige Analysen stehen in den Notebooks der LV; der Text verweist darauf mit dem Dateinamen, etwa `notebooks/05_agreement_and_codebooks.ipynb`.

=== Zitierweise

Quellen werden numerisch zitiert, etwa @angelopoulos2023prediction; das Literaturverzeichnis am Ende des Buchs enthält nur Arbeiten, die im Text tatsächlich vorkommen. Jede Zahl, jeder Befund und jede Formel aus der Literatur trägt ein Zitat. Wo die Wissensbasis eine genauere Fundstelle (Abschnitt, Tabelle, Gleichung) belegt, wird sie bei wichtigen Zahlen im Text genannt, damit du sie in der Primärquelle schnell wiederfindest. Das Lehrbuch @haindl2027research wird zitiert, wo Definitionen, Rahmenmodelle oder Abbildungen von dort stammen, und nur für Aussagen, die es tatsächlich macht.

Zwei Kennzeichnungen verdienen Beachtung. Zeitkritische Angaben (Preise, Modell- und Versionsnamen, API-Verhalten, Rechtsdaten) tragen den Zusatz "(Stand: 11. November 2026)". Aussagen, die bei der Prüfung der Wissensbasis nicht bestätigt werden konnten, werden nicht als Fakt dargestellt; wo sie didaktisch trotzdem erwähnenswert sind, stehen sie ausdrücklich als ungeprüft markiert im Text. Eigene Herleitungen und Synthesen, etwa ein aus mehreren Quellen zusammengesetztes Validierungsprotokoll, sind als solche gekennzeichnet und nicht einer einzelnen Quelle zugeschrieben.

== Bezug zur Lehrveranstaltung

Das Buch begleitet die LV ELEC1-GAIRI im Sommersemester 2027. Die LV ist auf vier Blocktage mit zusammen 30 Unterrichtseinheiten angelegt; Folien, Notebooks und Übungen sind englischsprachig. Die Kapitelnummern entsprechen den Nummern der Foliensätze, sodass sich jedes Kapitel direkt einem Deck zuordnen lässt (@vw-abb-lv).

#figure(
  {
    set text(font: "Inter", size: 7.5pt)
    diagram(
      spacing: (11mm, 8mm),
      edge-stroke: 0.8pt + c-dark,
      mark-scale: 70%,
      fknoten((1, 0), [*Wissensbasis* \ 10 geprüfte Dossiers \ Stand 11.11.2026], col: c-dark, filled: true, w: 34mm, name: <wb>),
      fknoten((0, 1), [*Lehrbuch* \ Haindl & Eigner \ (CRC Press, 2027)], col: c-blue, w: 34mm, name: <lb>),
      fknoten((2, 1), [*Dieses Handbuch* \ Kapitel 1-10 \ Formeln, Glossar], col: c-accent, filled: true, w: 34mm, name: <hb>),
      fknoten((0, 2.2), [*Foliensätze 01-10* \ mit Sprechernotizen], col: c-violet, w: 34mm, name: <fs>),
      fknoten((1, 2.2), [*Notebooks* \ 01, 03-10, offline \ synthetische Daten], col: c-teal, w: 34mm, name: <nb>),
      fknoten((2, 2.2), [*Übungen 01-10* \ je 20 Punkte \ mit Raster], col: c-green, w: 34mm, name: <ue>),
      edge(<wb>, <lb>, "-", stroke: (dash: "dotted")),
      edge(<wb>, <hb>, "-|>"),
      edge(<lb>, <hb>, "-|>"),
      edge(<wb>, <fs>, "-|>"),
      edge(<wb>, <nb>, "-|>"),
      edge(<wb>, <ue>, "-|>"),
      edge(<hb>, <fs>, "<|-|>", stroke: (dash: "dashed")),
      edge(<hb>, <nb>, "<|-|>", stroke: (dash: "dashed")),
      edge(<hb>, <ue>, "<|-|>", stroke: (dash: "dashed")),
    )
  },
  caption: [Quellen und Materialien der LV. Alle Inhalte stammen aus der geprüften Wissensbasis und dem Lehrbuch; das Handbuch verweist gestrichelt auf Folien, Notebooks und Übungen derselben Nummer.],
) <vw-abb-lv>

*Foliensätze.* Die zehn Decks "01 Research Methods" bis "10 Applied Research Workflows" enthalten je rund 50 Folien mit Sprechernotizen. Das Buch geht in jedem Kapitel deutlich über die Folien hinaus, verwendet aber dieselben Rechenbeispiele und Zahlen, sodass du im Hörsaal aus dem Buch heraus argumentieren kannst, ohne dass Folie und Begründung auseinanderlaufen. Die englischen Fachbegriffe der Folien stehen beim ersten Auftreten kursiv in Klammern, damit der Wechsel zwischen deutscher Vorbereitung und englischem Vortrag reibungslos gelingt.

*Notebooks.* Zu neun der zehn Themen gibt es ein Jupyter-Notebook (Deck 02 hat keines). Alle Notebooks laufen offline und ohne API-Schlüssel auf synthetischen Daten oder kleinen Beispielen aus der Wissensbasis; jede Methode wird zuerst von Hand implementiert und dann gegen eine Bibliothek geprüft. Ein optionaler Live-Modus mit einem lokal betriebenen Modell ist vorgesehen. Wenn ein Kapitel auf ein Notebook verweist, lohnt es sich, die Zelle beim Lesen auszuführen: Viele Fallstricke (etwa die Kappa-Paradoxien oder ein PPI-Intervall, das breiter ist als das klassische) versteht man erst, wenn man die Parameter selbst verschiebt.

*Übungen.* Die zehn Übungsangaben umfassen je 20 Punkte mit Bewertungsraster und verlangen mindestens eine Anwendung auf das eigene Thema der Studierenden sowie eine kurze kritische Reflexion ohne LLM-Hilfe. Die Selbsttestfragen dieses Buchs sind keine Kopie der Übungen, decken aber dieselben Kompetenzen ab und eignen sich deshalb gut, um vor der Korrektur die erwarteten Lösungswege noch einmal durchzudenken. Für die kommissionelle Prüfung existiert ein eigener Fragenpool.

=== Bezug zum Lehrbuch

Das Lehrbuch @haindl2027research behandelt Forschungsmethoden der Informatik und des Software Engineering allgemein: Paradigmen und Designs, qualitative und quantitative Verfahren, Design Science, systematische Literaturreviews, Statistik und Berichterstattung. Dieses Handbuch setzt dort an, wo LLMs die etablierten Methoden verändern oder neue erfordern. Kapitel 1 und 2 fassen die Grundlagen aus dem Lehrbuch deshalb nur so weit zusammen, wie sie für die LLM-spezifischen Kapitel gebraucht werden, und vertiefen vor allem Effektstärken, Power, multiples Testen und Evaluationsstrategien. Wo du eine Grundlage ausführlicher brauchst, verweist der Text auf das Lehrbuch statt sie zu wiederholen. Umgekehrt enthält dieses Handbuch nichts, was dem Lehrbuch widerspricht; wo Terminologie abweicht, weil die LLM-Literatur andere Begriffe verwendet, ist das vermerkt.

== Stand und Prüfstatus

Die inhaltliche Grundlage des Buchs ist die Wissensbasis der LV, zehn Dossiers mit zusammen mehreren hundert Quellen, die am *11. November 2026* abgeschlossen und unabhängig geprüft wurde. Jedes Dossier wurde gegen die Primärquellen kontrolliert: Literaturangaben auf Existenz und korrekte Metadaten, Zahlen und Zitate gegen die genannte Fundstelle, Formeln gegen die definierenden Arbeiten oder die Referenzimplementierungen, Code durch erneutes Ausführen. Korrekturbedarf wurde in den Dossiers selbst behoben; was nicht bestätigt werden konnte, ist dort als ungeprüft markiert und in diesem Buch nicht als Fakt verwendet. Die Rechenbeispiele des Buchs wurden zusätzlich mit Python nachgerechnet.

#merke[
  Die Methoden in diesem Buch altern langsam, die Werkzeuge und Rahmenbedingungen schnell. Alles mit dem Zusatz "(Stand: 11. November 2026)" ist vor dem Semester erneut zu prüfen.
]

Wie schnell sich solche Angaben ändern, zeigt ein Beispiel aus Kapitel 8: Die Perspective API, über Jahre der De-facto-Standard für Toxizitätsklassifikation in der Bias-Forschung, wird Ende 2026 eingestellt @hartmann2026bye. Jede Metrik, die darauf aufbaut, muss in Abschlussarbeiten ab 2027 anders operationalisiert werden. Ähnliches gilt für Modellnamen und Preise, für die Standardwerte von Bibliotheken und für Rechtsdaten. Vor Semesterbeginn solltest du deshalb mindestens Folgendes kontrollieren:

+ *Preise und Rabatte* der in Kapitel 3 und 10 verwendeten Anbieter (Token-Preise, Batch-Rabatt, Cache-Multiplikatoren) und die daraus abgeleiteten Rechenbeispiele.
+ *Modellnamen und Lebenszyklen*: ob die genannten Modelle und Snapshots noch angeboten werden und welche Abkündigungen anstehen.
+ *Bibliotheksversionen und Signaturen*, insbesondere von `ppi_py`, `pingouin`, `irrCAC`, RAGAS und DeepEval; Standardwerte wie das voreingestellte Konfidenzniveau oder das voreingestellte Richtermodell ändern sich ohne Vorwarnung.
+ *API-Verhalten*, etwa welche Sampling-Parameter ein Anbieter noch akzeptiert, und die Dokumentation zu Seeds und Reproduzierbarkeit.
+ *Regulierung und Publikationsrichtlinien*: Fristen des AI Act, Änderungen durch das Digital-Omnibus-Paket und die KI-Richtlinien der Zielverlage.

Methodische Aussagen, Herleitungen und die Befunde publizierter Studien bleiben davon unberührt. Wenn neue Arbeiten einen Befund relativieren, gehört das in die Debattenabschnitte der Kapitel; die Grundstruktur des Buchs, von der Messtheorie über die valide Inferenz bis zur Reproduzierbarkeit, ist darauf angelegt, solche Aktualisierungen aufzunehmen, ohne dass sich ihr Fundament verschiebt.

Und nun: Viel Freude beim Lesen, Rechnen und Unterrichten.

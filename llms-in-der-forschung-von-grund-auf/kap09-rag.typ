#import "lib.typ": *

// Codeblock samt Dateikopf nie über einen Seitenumbruch trennen
#let kdatei(name, body) = block(breakable: false, datei(name, body))

= RAG-Systeme bewerten

Du hast einen Assistenten gebaut, der Fragen zu 1200 Fachartikeln beantwortet. Er sucht passende Textstellen heraus, gibt sie einem Sprachmodell mit und liefert eine Antwort mit Quellenangabe. Im Test sieht das gut aus. Dann fragt jemand nach dem Geburtsdatum eines Forschers, und der Assistent nennt ein falsches Datum, obwohl die richtige Stelle im Text stand. Lag es an der Suche? Hat das Modell die Stelle ignoriert? Oder stand in der Stelle selbst ein Fehler?

Genau diese Frage beantwortet dieses Kapitel. Ein System mit Dokumentensuche kann an zwei Stellen scheitern, und eine einzige Genauigkeitszahl verrät nicht, an welcher. Du lernst, jede Stelle getrennt zu messen, die gängigen Kennzahlen an einer kurzen Trefferliste nachzuzählen, Werkzeuge wie RAGAS und DeepEval (Bibliotheken, die RAG-Kennzahlen berechnen) zu starten und zu prüfen, ob ihren Zahlen zu trauen ist. Gerechnet wird nur mit Zählen und Prozenten. Den Rest übernimmt Code.

#lernziele(
  [Du erklärst, was ein RAG-System ist und an welchen zwei Stellen es scheitern kann.],
  [Du zählst Precision, Recall, MRR, MAP und nDCG an einer konkreten Trefferliste nach und liest die Werte.],
  [Du erklärst, wie Faithfulness, Context Recall und verwandte Kennzahlen mit Behauptungen arbeiten und warum gleich benannte Kennzahlen in RAGAS, DeepEval und TruLens Verschiedenes messen.],
  [Du baust ein kleines Testset, prüfst den LLM-Richter an menschlichen Labels und vergleichst zwei Konfigurationen mit einem Intervall.],
  [Du findest bei einer schlechten Antwort heraus, ob Retriever oder Generator schuld ist.],
)

== Was RAG ist und wie man es baut <k09-aufbau>

*Retrieval-Augmented Generation* (_RAG_, Antworten erzeugen mit vorgeschalteter Suche) kombiniert eine Suche über eigene Dokumente mit einem Sprachmodell, das die Antwort schreibt. Der Begriff stammt von Lewis et al., die ein Textmodell mit einem Suchindex über Wikipedia koppelten und Antworten berichteten, die spezifischer, vielfältiger und faktentreuer waren als die des Modells allein @lewis2020retrieval.

#alltag[Stell dir eine *Open-Book-Prüfung* vor. Ein gewöhnliches Sprachmodell schreibt die Antwort aus dem Gedächtnis, wie bei einer Prüfung ohne Unterlagen. Bei RAG sitzt neben dir eine Bibliothekarin. Du nennst die Frage, sie holt die passenden Seiten, und erst dann schreibst du die Antwort, mit den Seiten vor dir. Es gibt zwei Fehlerquellen: Die Bibliothekarin bringt die falschen Seiten, oder du schreibst trotz der richtigen Seiten Unsinn.]

@k09-fig-pipeline zeigt das Schema. Die obere Zeile läuft einmal pro Dokumentenbestand, die untere bei jeder Frage.

#figure(
  diagram(spacing: (7mm, 11mm),
    fknoten((0,0), [Dokumente], col: c-grey, w: 33mm),
    fknoten((1,0), [In *Chunks* \ schneiden], col: c-blue, w: 33mm),
    fknoten((2,0), [Einbetten, \ im *Index* speichern], col: c-blue, filled: true, w: 33mm),
    fknoten((0,1), [Frage], col: c-grey, w: 33mm),
    fknoten((1,1), [Die *Top k* Chunks \ holen], col: c-blue, filled: true, w: 33mm),
    fknoten((2,1), [Frage + Chunks \ als Prompt], col: c-blue, w: 33mm),
    fknoten((3,1), [LLM schreibt \ die Antwort], col: c-accent, filled: true, w: 33mm),
    edge((0,0), (1,0), "-|>"), edge((1,0), (2,0), "-|>"),
    edge((0,1), (1,1), "-|>"), edge((1,1), (2,1), "-|>"), edge((2,1), (3,1), "-|>"),
    edge((2,0), (1,1), "-|>", bend: -20deg, stroke: (paint: c-grey, dash: "dashed", thickness: 0.8pt)),
  ),
  caption: [Eine RAG-Pipeline. Die gestrichelte Kante zeigt, dass die Suche den Index benutzt.],
) <k09-fig-pipeline>

#begriff[Chunk, Embedding, Index, Top k][Ein *Chunk* ist ein Textstück von einigen hundert Wörtern. Ein *Embedding* ist eine Liste von Zahlen, die den Inhalt eines Chunks beschreibt, sodass ähnliche Texte ähnliche Zahlen bekommen. Der *Index* speichert die Embeddings und findet die ähnlichsten zu einer Frage schnell. *Top k* sind die k besten Treffer, die ins Prompt wandern; ihre Reihenfolge heißt *Ranking*. Ein *Re-Ranker* sortiert diese Treffer in einem zweiten Schritt noch einmal neu.]

Das folgende Programm baut die Suchhälfte mit scikit-learn. Es nimmt statt eines Embedding-Modells das einfachere TF-IDF (zählt gewichtet gemeinsame Wörter). Das Prinzip ist dasselbe, und es läuft ohne API-Schlüssel.

#kdatei("mini_rag.py")[
```python
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

chunks = [
    "Einstein was born on 14 March 1879 in Ulm, Germany.",
    "Einstein received the Nobel Prize in Physics in 1921.",
    "Ulm is a city on the river Danube in Baden-Wuerttemberg.",
    "The theory of relativity was published in 1905 and 1915.",
]
vec = TfidfVectorizer().fit(chunks)      # Platzhalter für ein Embedding-Modell
index = vec.transform(chunks)

def retrieve(question, k=2):
    scores = cosine_similarity(vec.transform([question]), index)[0]
    best = scores.argsort()[::-1][:k]    # Positionen der k ähnlichsten Chunks
    return [chunks[i] for i in best]

def answer(question):
    context = "\n".join(retrieve(question))
    prompt = f"Antworte nur mit dem Kontext.\nKontext:\n{context}\nFrage: {question}"
    return call_llm(prompt)              # dein API-Aufruf, siehe Das Nötigste vorab
```
]

```out
>>> retrieve("When was Einstein born?")
['Einstein was born on 14 March 1879 in Ulm, Germany.',
 'Einstein received the Nobel Prize in Physics in 1921.']
```

Jede Zeile hat Stellschrauben: Chunk-Größe, Embedding-Modell, Zahl k, Wortlaut des Prompts, Sprachmodell. Jede verändert die Qualität. Ändere pro Lauf nur eine Schraube und lass dieselben Testfragen noch einmal laufen, sonst kannst du einen Gewinn keiner Änderung zuordnen.

== Was Qualität bei RAG heißt <k09-qualitaet>

Bevor du Kennzahlen wählst, musst du wissen, was "gut" bedeutet. Drei Wörter, die im Alltag verschwimmen, musst du sauber trennen @haindl2027research.

#figure(table(columns: (auto, 1fr),
  [Begriff], [Bedeutung],
  [*Faithfulness* (Treue)], [Die Antwort stimmt mit der *bereitgestellten Quelle* überein, egal ob die Quelle wahr ist.],
  [*Factuality* (Faktizität)], [Die Antwort stimmt mit der *Welt* überein, egal welche Quelle vorliegt.],
  [*Hallucination*], [Die Antwort ist durch nichts *verankert*, weder durch den Kontext noch oft durch Fakten.],
), caption: [Drei Begriffe, die man nicht vermischen darf.]) <k09-tab-begriffe>

#alltag[Ein Zeuge liest vor Gericht aus der Akte vor. Liest er genau vor, was drinsteht, ist er der Akte *treu*, auch wenn in der Akte ein Fehler steht. Ob die Aussage *wahr* ist, ist eine andere Frage. Eine treue Wiedergabe eines falschen Dokuments bekommt von jeder Faithfulness-Kennzahl die Bestnote.]

Miss Treue und Faktizität deshalb getrennt. Für Forschungsassistenten steht meist die Treue zu den zitierten Quellen im Vordergrund, aber eine treu wiedergegebene, später zurückgezogene Studie richtet trotzdem Schaden an @haindl2027research.

Auch Normen helfen. *ISO/IEC 25010:2023* beschreibt Softwarequalität in neun Merkmalen (darunter performance efficiency, reliability, security, maintainability und neu safety), *ISO/IEC 25059:2023* ergänzt Merkmale für KI-Systeme wie robustness, transparency und user controllability @isoiec2023systems @isoiec2023software. Die Revision von 25059 ist in Arbeit (Stand: 11. November 2026), ihr Inhalt gilt bis zur Veröffentlichung als vorläufig. Nutze die Normen als Checkliste: Was deckt deine Evaluation ab, was lässt du bewusst aus? Faithfulness und Factual Correctness passen etwa zu functional correctness, Noise Sensitivity zu robustness, Antwortzeit und Kosten zu performance efficiency (ein Lehrvorschlag, nicht Teil der Normen). Zu security, safety und maintainability sagen die gängigen RAG-Werkzeuge nichts.

@k09-fig-messorte zeigt, welche Kennzahl welche Stationen vergleicht. *Referenzfreie* Kennzahlen kommen ohne Musterantwort aus, *referenzbasierte* brauchen für jede Testfrage eine geschriebene Antwort oder bekannte relevante Chunks. Das bestimmt den Aufwand für dein Testset.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let xs = (1.45, 4.75, 8.05, 11.35, 14.65)
    let namen = ([Frage], [Retriever], [Kontext \ (Chunks)], [Generator], [Antwort])
    for (i, n) in namen.enumerate() {
      kasten((xs.at(i), 0), n, col: if i == 0 or i == 4 { c-blue } else { c-dark }, bg: if i == 0 or i == 4 { c-blue.lighten(88%) } else { white }, w: 2.8, h: 1.0)
      if i < 4 { pfeil((xs.at(i) + 1.45, 0), (xs.at(i + 1) - 1.45, 0)) }
    }
    kasten((4.75, -1.9), [*Retriever-Kennzahlen* \ Precision\@k, Recall\@k, MRR, MAP, nDCG, Context Recall], col: c-blue, bg: c-blue.lighten(88%), w: 9.4, h: 1.1)
    kasten((11.35, -3.4), [*Generator-Kennzahlen* \ Faithfulness, Answer Relevancy], col: c-accent, bg: c-accent.lighten(88%), w: 9.4, h: 1.1)
    kasten((8.05, -4.9), [*Ende-zu-Ende gegen Musterantwort* \ Factual Correctness, Nuggets, CRAG-Truthfulness], col: c-teal, bg: c-teal.lighten(88%), w: 15.2, h: 1.1)
  }),
  caption: [Jede Kennzahl vergleicht bestimmte Stationen der Pipeline. Retriever-Kennzahlen sehen nur die Suche, Generator-Kennzahlen nur das Schreiben, Ende-zu-Ende-Kennzahlen nur das Ergebnis.],
) <k09-fig-messorte>

== Retrieval messen: Treffer zählen <k09-retrieval>

Die Suche gibt eine Trefferliste zurück. Jede Retrieval-Kennzahl ist eine andere Art, an dieser Liste zu zählen. Eine Liste reicht, um alle zu verstehen.

#beispiel(titel: [Eine Trefferliste mit fünf Einträgen])[
  Du hast eine Frage gestellt. Der Index liefert fünf Chunks. Der erste und der vierte sind brauchbar, die anderen nicht. Im ganzen Bestand gibt es drei brauchbare Chunks, einer davon liegt irgendwo jenseits von Platz 5.

  #figure(
    cetz.canvas(length: 1cm, {
      import cetz.draw: *
      for i in range(5) {
        let ok = i == 0 or i == 3
        kasten((1.4 + i * 3.1, 0), [Platz #(i + 1) \ #if ok [brauchbar] else [nicht brauchbar]], col: if ok { c-green } else { c-grey }, bg: if ok { c-green.lighten(80%) } else { white }, w: 2.8, h: 1.1)
      }
    }),
    caption: [Fünf Treffer, zwei brauchbar. Alle Zahlen dieses Abschnitts beziehen sich auf diese Liste.],
  ) <k09-fig-treffer>
]

Jetzt zählen wir.

- *Precision\@5* (Treffsicherheit): Wie viele der fünf gezeigten sind brauchbar? 2 von 5 sind 40 %.
- *Recall\@5* (Vollständigkeit): Wie viele der brauchbaren Chunks haben wir gefunden? 2 von 3 sind 67 %.
- *MRR* (_mean reciprocal rank_): Wie weit oben steht der erste brauchbare Treffer? Platz 1 ergibt 1, Platz 2 ergibt 0.5, Platz 3 ergibt 0.33. Bei mehreren Fragen nimmt man den Durchschnitt. Hier: 1.0.
- *MAP* (_mean average precision_): Man prüft die Precision an jedem brauchbaren Treffer und mittelt. An Platz 1 sind es 100 %, an Platz 4 sind es 2 von 4, also 50 %, und der nie gefundene dritte zählt 0. Der Durchschnitt aus 100, 50 und 0 ist 50 %.
- *nDCG* (_normalized discounted cumulative gain_): Stehen die besten Treffer weit oben? Die Kennzahl vergleicht deine Reihenfolge mit der bestmöglichen. 1.0 heißt perfekte Reihenfolge, 0 heißt, nichts Brauchbares kam. Hier: 0.67.

#figure(table(columns: (auto, 1fr),
  [Kennzahl], [Wann sie die richtige Wahl ist],
  [Precision\@k], [Jeder gezeigte Treffer kostet Aufmerksamkeit oder Tokens.],
  [Recall\@k], [Eine verpasste Quelle ist teuer, etwa bei Recherche oder Medizin.],
  [MRR], [Nur der erste gute Treffer zählt, etwa bei Faktenfragen.],
  [MAP], [Mehrere brauchbare Treffer sollen früh und vollständig kommen.],
  [nDCG], [Treffer sind unterschiedlich nützlich und die Reihenfolge zählt.],
), caption: [Welche Retrieval-Kennzahl wann passt.]) <k09-tab-retrieval>

Oft gibt es Zwischenstufen: Noten von 0 (nutzlos) bis 3 (perfekt). Dann spielt die Reihenfolge eine größere Rolle. Im Foliensatz liefert das System bei der ersten Beispielfrage Chunks mit den Noten 2, 0, 3, 0, 1. Die bestmögliche Reihenfolge aller bewerteten Chunks wäre 3, 2, 2, 1; ein 2er-Chunk lag im System auf Platz 10, also außerhalb. nDCG\@5 ist hier 0.68. Dieselben fünf Chunks nach Note sortiert (3, 2, 1, 0, 0) kämen auf etwa 0.84, in umgekehrter Reihenfolge auf etwa 0.44. Die Kennzahl reagiert also auf die *Reihenfolge*, die Precision nicht.

Die Benchmark-Sammlung BEIR wählte nDCG\@10 als einzige Zahl, weil Precision und Recall den Rang ignorieren und MRR und MAP keine Noten kennen @thakur2021beir. Schreib immer dazu, bei welchem Cut-off (Abbruchstelle: gezählt werden nur die ersten 10 Plätze) und mit welcher Gewichtung der Noten (linear oder exponentiell) du gerechnet hast, denn Bibliotheken unterscheiden sich darin @manning2008introduction @jarvelin2002cumulated.

Die Zählfunktionen sind kurz. Dieses Programm rechnet die Beispielliste nach; das Notebook `notebooks/09_rag_metrics.ipynb` (Foliensatz 09) zeigt dieselben Funktionen an drei Fragen.

#kdatei("retrieval_metriken.py")[
```python
import numpy as np
from sklearn.metrics import ndcg_score

rel = [1, 0, 0, 1, 0]       # Trefferliste: 1 = brauchbar
gesamt = 3                  # brauchbare Chunks im ganzen Bestand

def precision_at_k(rel, k):
    return sum(rel[:k]) / k

def recall_at_k(rel, k, gesamt):
    return sum(rel[:k]) / gesamt

def reciprocal_rank(rel):
    for i, r in enumerate(rel, start=1):
        if r:
            return 1 / i
    return 0.0

print(precision_at_k(rel, 5), round(recall_at_k(rel, 5, gesamt), 2),
      reciprocal_rank(rel))
# nDCG mit scikit-learn: der dritte brauchbare Chunk liegt unterhalb der Liste
print(round(ndcg_score([[1, 0, 0, 1, 0, 1]], [[5, 4, 3, 2, 1, 0]], k=5), 3))
```
]

```out
0.4 0.67 1.0
0.671
```

Bei den drei Fragen des Foliensatzes ergibt sich ein Mittelwert von MRR 0.444 und MAP 0.344. Die dritte Frage liefert überall null, weil ihr einziger brauchbarer Chunk nie gefunden wird. Mit nur drei Fragen verschiebt eine einzige den Durchschnitt stark.

#fallstrick[*Context Precision* heißt in RAGAS und DeepEval etwas anderes als in RAGChecker. In RAGAS und DeepEval beurteilt ein LLM jeden abgerufenen Chunk als brauchbar oder nicht, und brauchbare Chunks weiter oben zählen mehr (ein brauchbarer Chunk auf Rang 1 ergibt etwa 1.0, auf Rang 2 etwa 0.5). Ein brauchbarer Chunk, der gar nicht abgerufen wurde, schadet dort nicht @ragas2026contextprecision @deepeval2026contextualprecision. In RAGChecker ist es ein einfacher Anteil ohne Rangfolge @ru2024ragchecker. Kombiniere die RAGAS-Variante deshalb immer mit Context Recall.]

== Antworten messen: Behauptungen zählen <k09-generierung>

Die zweite Hälfte prüft, was das Modell aus den Chunks macht. Ein Absatz ist als Ganzes schwer zu bewerten. Deshalb zerlegen die meisten Werkzeuge ihn in kleine Behauptungen (_claims_) und urteilen über jede einzeln.

#alltag[Ein Lehrer korrigiert einen Aufsatz nicht mit "gefällt mir". Er streicht jede Behauptung an, die nicht im Lesetext steht, und zählt am Ende, wie viele richtig waren. Claim-basierte Kennzahlen funktionieren genauso.]

Bei der *Faithfulness* zerlegt man die Antwort in einzelne Fakten, ein Richter-LLM (ein Sprachmodell, das Antworten bewertet, Kapitel 7) prüft jede gegen den Kontext, und gezählt wird der Anteil gestützter Behauptungen @es2024ragas.

#beispiel(titel: [Das Einstein-Beispiel aus der RAGAS-Dokumentation])[
  Kontext: "Einstein wurde am 14. März 1879 in Ulm geboren." Antwort: "Einstein wurde in Deutschland am 20. März 1879 geboren." Zwei Behauptungen: (1) in Deutschland geboren, vom Kontext gestützt; (2) am 20. März 1879 geboren, vom Kontext widerlegt. Faithfulness: 1 von 2, also 0.5 @ragas2026faithfulness.
]

Der Wert zeigt auf die *fehlerhafte Behauptung*. Die Schwächen: Das Zerlegen übernimmt selbst ein LLM und kann Fehler machen, und eine Randbemerkung zählt so viel wie die Kernaussage. FineSurE zählt nach demselben Prinzip Sätze und benennt den fehlerhaften Satz, hat aber Probleme mit Sätzen, die Wahres und Falsches mischen @Song2024.

Die großen Werkzeuge nennen verschiedene Dinge "Faithfulness". Die Unterschiede liegen im Urteilskriterium.

#figure(table(columns: (auto, auto, 1fr),
  [Werkzeug], [Kennzahl], [Eine Behauptung besteht, wenn ...],
  [*RAGAS*], [faithfulness], [sie sich aus dem Kontext *ableiten* lässt.],
  [*DeepEval*], [faithfulness], [sie dem Kontext *nicht widerspricht*. Unbelegte, aber nicht widerlegte Behauptungen bestehen.],
  [*TruLens*], [groundedness], [sie als gestützt bewertet wird. Eine Enthaltung zählt als gestützt, Skala 0 bis 3.],
  [*RAGChecker*], [faithfulness], [ein Chunk sie *entailt* (logisch erzwingt).],
), caption: [Vier Werkzeuge, vier Bedeutungen von Faithfulness @ragas2026faithfulness @deepeval2026faithfulness @trulens2026providers @ru2024ragchecker.]) <k09-tab-gleich>

Ein Beispiel: Der Kontext sagt "Die Studie wurde in Wien durchgeführt", die Antwort "in Wien mit 200 Teilnehmenden". Die Zahl 200 lässt sich aus dem Kontext nicht ableiten, RAGAS wertet sie als nicht gestützt. DeepEval lässt sie bestehen, weil nichts widerspricht. Deshalb gehört zu jedem Wert die Angabe von Werkzeug, Version und Richtermodell.

Weitere Kennzahlen aus RAGAS:

- *Answer Relevancy*: Passt die Antwort zur Frage? Ein LLM erzeugt Fragen, zu denen die Antwort passen würde, und vergleicht sie mit der echten Frage. Faktenprüfung ist das nicht: Eine falsche Antwort kann relevant sein @ragas2026answerrelevancy.
- *Context Recall*: Hat die Suche geliefert, was die Musterantwort braucht? Beispiel aus der Dokumentation: Die Musterantwort stützt sich auf 4 Dokumente, gefunden wurde 1, der Wert ist also 1 von 4, 0.25 @ragas2026contextrecall.
- *Factual Correctness*: Sagt die Antwort dasselbe wie die Musterantwort? Gemessen wird, welcher Anteil der Antwort-Behauptungen stimmt (Precision), welcher Anteil der Musterantwort abgedeckt ist (Recall), und der *F1-Wert* balanciert beides @ragas2026factualcorrectness.
- *Noise Sensitivity*: Wie oft führt irrelevanter Kontext zu falschen Behauptungen? Je kleiner, desto besser @ragas2026noisesensitivity.

*RAGChecker* prüft jede Behauptung der Antwort zweimal: Steht sie in der Musterantwort, und wird sie durch einen abgerufenen Chunk gestützt? Daraus entsteht eine 2x2-Tabelle (@k09-fig-matrix), die Fehler der Suche von Fehlern des Modells trennt.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    content((4.0, 1.4), text(font: "Inter", size: 8pt, weight: "bold")[im Chunk gestützt])
    content((8.4, 1.4), text(font: "Inter", size: 8pt, weight: "bold")[nicht im Chunk])
    content((1.7, 0), anchor: "east", text(font: "Inter", size: 8pt, weight: "bold")[in der Musterantwort])
    content((1.7, -2.0), anchor: "east", text(font: "Inter", size: 8pt, weight: "bold")[nicht in der \ Musterantwort])
    kasten((4.0, 0), [Richtig und belegt], col: c-green, bg: c-green.lighten(80%), w: 4.0, h: 1.7)
    kasten((8.4, 0), [Eigenwissen des Modells], col: c-blue, bg: c-blue.lighten(85%), w: 4.0, h: 1.7)
    kasten((4.0, -2.0), [Störung durch \ falschen Kontext], col: c-yellow, bg: c-yellow.lighten(80%), w: 4.0, h: 1.7)
    kasten((8.4, -2.0), [Halluzination], col: c-red, bg: c-red.lighten(85%), w: 4.0, h: 1.7)
  }),
  caption: [Die Behauptungsmatrix von RAGChecker. Jede Zelle ist ein Anteil aller Antwort-Behauptungen @ru2024ragchecker.],
) <k09-fig-matrix>

Wer Quellenangaben verlangt, kann auch diese prüfen. *ALCE* misst, ob die zitierten Stellen die Aussage stützen (Citation Recall) und ob die Zitate nicht irrelevant sind (Citation Precision) @gao2023enabling. *FActScore* gibt den Anteil atomarer Fakten an, den eine verlässliche Quelle stützt; er kennt nur Precision @min2023factscore. Die besten getesteten Modelle erreichten bei ELI5-Fragen in 50 % der Fälle keine vollständige Zitatstützung, und ChatGPT kam bei FActScore nur auf 58 %.

*Nuggets* sind kleine Fakten, die eine gute Antwort enthalten sollte, wie die Punkte eines Bewertungsschemas bei einer Klausur. Im TREC-RAG-Track 2024 wird jedes Nugget als gestützt, teilweise gestützt oder nicht gestützt beurteilt, und der strenge Wert gibt nur für volle Stützung Punkte @pradeep2025great.

#beispiel(titel: [Ein Nugget-Spielbeispiel])[
  Vier Nuggets zum Thema nDCG, zwei davon "vital": (1) normiert durch die ideale Reihenfolge (vital, gestützt), (2) kann Noten verarbeiten (vital, teilweise), (3) nutzt einen Rangabschlag (okay, gestützt), (4) Gewinn linear oder exponentiell (okay, nicht gestützt). Über alle Nuggets: 2 von 4, also 50 %. Nur "vital": 1 von 2, ebenfalls 50 %. Die teilweise Stützung bringt nichts.
]

Die automatische Nugget-Wertung ordnet *Systeme* fast gleich wie die manuelle (Kendall's tau, ein Maß für die Ähnlichkeit zweier Rangfolgen: 1 hieße identisch, 0 unabhängig; hier 0.887 und 0.901), bei einzelnen Antworten stimmt sie nur schwach überein (0.360 bis 0.539). Die Autoren nennen das "inadequate for fine-grained debugging" @pradeep2025great. Sie ist gut zum Ranken und schlecht zum Fehlersuchen.

== Die Werkzeuge: RAGAS, DeepEval und Co. <k09-frameworks>

RAGAS braucht pro Testfrage einen Eintrag (Frage, abgerufene Chunks, Antwort, Musterantwort), eine Liste von Kennzahlen und ein Richtermodell. Das Beispiel nutzt die klassischen Metrik-Klassen; die alte Schnittstelle ist in RAGAS 0.4 als veraltet markiert und soll in 1.0 entfallen (Stand: 11. November 2026: Version 0.4.3) @ragas2026pypi. Übernimm die Imports aus der Dokumentation deiner festgelegten Version.

#kdatei("ragas_lauf.py")[
```python
from ragas import evaluate, EvaluationDataset
from ragas.metrics import Faithfulness, LLMContextRecall

data = EvaluationDataset.from_list([{
    "user_input": "When was Einstein born?",
    "retrieved_contexts": ["Born 14.3.1879 in Ulm."],
    "response": "On 20.3.1879.",
    "reference": "14.3.1879 in Ulm.",
}])
result = evaluate(data, llm=judge_llm,        # judge_llm: dein Richtermodell
                  metrics=[Faithfulness(), LLMContextRecall()])
print(result)
```
]

DeepEval folgt dem Muster eines Unit-Tests: ein Testfall, eine Kennzahl, ein Schwellenwert.

#kdatei("deepeval_lauf.py")[
```python
from deepeval.metrics import FaithfulnessMetric
from deepeval.test_case import LLMTestCase

case = LLMTestCase(
    input="When was Einstein born?",
    actual_output="On 20.3.1879.",
    retrieval_context=["Born 14.3.1879 in Ulm."],
)
metric = FaithfulnessMetric(threshold=0.5)   # Schwellenwert fürs Bestehen
metric.measure(case)
print(metric.score, metric.reason)           # Wert und Begründung des Richters
```
]

Beide Beispiele zeigen die Form eines Aufrufs nach der Dokumentation. Sie wurden beim Schreiben des Kapitels nicht gegen die genannten Versionen ausgeführt; prüfe sie, bevor du sie in einer Arbeit zitierst. DeepEval erlaubt drei Auswertungsmodi (`llm`, `hybrid`, `system_one`), die verschiedene Werte liefern; vergleiche Läufe nur im selben Modus @deepeval2026faithfulness.

Forschungsframeworks gehen anders vor. *ARES* trainiert kleine Richter an künstlich erzeugten Fragen und korrigiert sie mit wenigen hundert menschlichen Labels; unter etwa 100 bis 150 Labels lassen sich Systeme nicht verlässlich ordnen @saadfalcon2024ares. *eRAG* gibt jedes abgerufene Dokument einzeln dem Generator und nimmt die Qualität der entstandenen Antwort als Relevanzlabel. Solche Labels passen besser zur Endqualität als Urteile über die bloße Themenrelevanz (Kendall's tau mit der Endqualität bei Natural Questions: 0.492 gegenüber 0.181 und 0.045) @salemi2024evaluating. *RAGChecker*, *TREC RAG* und *RAGBench* nutzen Behauptungen, Nuggets und markierte Textabschnitte @ru2024ragchecker @pradeep2025great @friel2024ragbench.

#studie(titel: [Es et al., 2024 (RAGAS-Paper)])[Die Autoren prüften drei Kennzahlen an WikiEval: 50 Fragen zu Wikipedia-Seiten über Ereignisse seit 2022, Antworten von ChatGPT, zwei Annotatoren. Die Übereinstimmung mit Menschen (Anteil richtig geordneter Paare) lag bei 0.95 für Faithfulness und bei 0.78 und 0.70 für die beiden Relevanzkennzahlen. Das gilt für 50 Fragen und ein Richtermodell. Context Precision, Context Recall und Noise Sensitivity der Bibliothek sind im Paper nicht validiert @es2024ragas.]

Werkzeuge ändern sich monatlich. Stand: 11. November 2026 sind es RAGAS 0.4.3, DeepEval 4.3.3 und TruLens 2.16.0 @ragas2026pypi @deepeval2026pypi @trulens2026releases. DeepEval 4.2.0 hat die Bewertungsrichtung von vier Kennzahlen umgedreht (nicht die der RAG-Kennzahlen) @deepeval2026changelog. Notiere deshalb zu jedem Ergebnis Werkzeug, Version, Auswertungsmodus, Richtermodell samt Datum, Prompt, Temperatur und Zahl der Wiederholungen.

== Benchmarks und Robustheit <k09-benchmarks>

Benchmarks stressen Systeme gezielt. *RGB* prüft vier Fähigkeiten: mit Störtext umgehen, Nichtwissen eingestehen, Quellen kombinieren und falsche Information erkennen. Die geprüften Modelle zeigten bei Störtext eine gewisse Robustheit und taten sich bei den anderen schwer @chen2024benchmarking. *CRAG* gibt für eine perfekte Antwort 1, eine brauchbare 0.5, eine fehlende 0 und eine falsche -1 @yang2024crag. Weil "keine Antwort" damit besser ist als eine falsche, kodiert die Wertung eine Präferenz. TruLens zählt Enthaltungen sogar als gestützt @trulens2026providers. Ohne Abdeckungsmaß belohnt beides ein System, das immer schweigt. Im CRAG-Test (4409 Frage-Antwort-Paare) erreichten die besten Modelle allein höchstens 34 % Genauigkeit, ein einfaches RAG 44 %, und industrielle Lösungen beantworteten 63 % der Fragen ohne Halluzination, bei 3.4 bis 11.6 Sekunden Antwortzeit.

Weitere Befunde: Modelle nutzen Informationen in der Mitte eines langen Kontexts schlechter als am Anfang oder Ende @liu2024lost. Zufällige Dokumente erhöhten die Genauigkeit in einer Studie um bis zu 35 %, während hoch bewertete, aber unpassende schadeten, sodass Suchwert und Antwortqualität nicht gleichläufig sind @cuconasu2024power. Ein Preprint aus 2026 (ein noch nicht begutachteter Vorabdruck, EnterpriseRAG, 13 Modelle) fand, dass unbeantwortbare Fragen in höchstens 42.7 % der Fälle abgelehnt wurden @miao2026enterpriserag.

== Kann man den Kennzahlen trauen? <k09-validitaet>

Eine Kennzahl, die ein LLM-Richter berechnet, ist nur so gut wie der Richter. Die Belege sind gemischt. Dafür spricht: RAGAS-Faithfulness stimmt in 95 % der Paare mit Menschen überein @es2024ragas, und die automatische Wertung von CRAG kommt auf F1 94.7 bis 98.9 % gegenüber Menschen @yang2024crag. Dagegen: Die beiden Relevanzkennzahlen von RAGAS erreichen nur 0.78 und 0.70, die besten Faithfulness-Richter in MEMERAG etwa 72 % @cruzblandon2025memerag, und bei RAGBench liegt die Erkennung von Halluzinationen bei RAGAS und TruLens oft nur bei 0.5 bis 0.65 (gemessen als AUROC; 0.5 ist Münzwurf, 1.0 perfekt) @friel2024ragbench. Bei JudgeBench erreichte GPT-4o 50.86 % (Zufall wäre 50 %), o3-mini (high) 80.86 % @tan2025judgebench. Viele der positiven Zahlen stammen aus den eigenen Messungen der Autoren.

Validität gilt also nur für eine bestimmte Kennzahl, einen Richter, ein Fachgebiet und eine Sprache. Wer "RAGAS ist validiert" schreibt, überträgt eine Prüfung an 50 Fragen auf alles andere. Prüfe selbst, mit einer menschlich beurteilten Stichprobe. Welche Prüfung passt, hängt davon ab, was du behaupten willst:

#figure(table(columns: (auto, 1fr, auto),
  [Du willst ...], [Prüfe, ob ...], [Name],
  [Systeme ordnen], [Kennzahl und Menschen die Systeme gleich ordnen], [Kendall's tau],
  [Einzelwerten trauen], [Werte mit den menschlichen Werten steigen und fallen], [Pearson, Spearman],
  [Fehler anzeigen], [der Ja/Nein-Befund oft genug stimmt], [AUROC, Genauigkeit],
  [Übereinstimmung belegen], [Richter und Menschen über den Zufall hinaus übereinstimmen], [Cohen's kappa, AC1 (ein verwandtes Maß)],
), caption: [Welche Prüfung zu welcher Behauptung passt.]) <k09-tab-validierung>

#rechnung(titel: [Warum 90 % Übereinstimmung täuschen können])[
  90 von 100 Antworten sind laut Menschen treu. Ein fauler Richter sagt immer "treu". Er stimmt mit den Menschen in 90 von 100 Fällen überein, also 90 %, und hat nichts gelernt. *Cohen's kappa* zieht die Übereinstimmung ab, die man durch Raten erwartet, und kommt hier auf 0. Berichte deshalb nie nur die rohe Übereinstimmung (Kapitel 5).
]

Außerdem gilt: *Zuverlässig ist nicht gültig*. Ein Richter, der immer dasselbe sagt, ist zuverlässig und trotzdem nutzlos. Eine Übersichtsstudie fand zudem, dass keine Kennzahl über alle Einstellungen hinweg überlegen war @Kulkarni2025Mirage. Nimm deshalb nie eine Zahl allein, sondern vergleiche mehrere Messebenen (Wortüberlappung, Behauptungsprüfung, Verhaltensmaße) miteinander.

#hoersaal([Warum lasse ich nicht einfach das Modell prüfen, ob seine eigene Antwort stimmt?], [Genau das passiert bei LLM-Richtern, aber jeder Richter macht Fehler, und Modelle bevorzugen oft ihre eigenen Texte. CRAG setzt deshalb zwei verschiedene LLM-Bewerter ein, um das zu vermeiden @yang2024crag. Nimm für den Richter ein anderes Modell als für den Generator und prüfe ihn an menschlichen Labels.])

== Eine Evaluation entwerfen <k09-design>

=== Ein Testset aufbauen

Ohne Testset hat keine Kennzahl, die eine Musterantwort braucht, etwas zum Vergleichen. Ein Testset ist eine Liste von Fragen, jede mit erwarteter Antwort und Quellstellen. So gehst du vor:

+ Sammle *echte Fragen* von künftigen Nutzern. Fragen, die du allein aus den Dokumenten ableitest, sind ihrer Quelle sprachlich oft so nah, dass eine einfache Suche im Vorteil ist.
+ Notiere für jede Frage die erwartete Antwort und die Chunks, in denen sie steht.
+ Lass ein LLM zusätzliche Fragen aus den Dokumenten erzeugen (ARES arbeitet so @saadfalcon2024ares) und prüfe jede von Hand.
+ Nimm *unbeantwortbare Fragen* auf. Dann ist "Ich weiß es nicht" die richtige Antwort, und du siehst, ob das System rät.
+ Friere das Testset ein, bevor du das System änderst. Wer Fragen nach den ersten Ergebnissen umformuliert, optimiert auf die Probe.

Den Richter prüfst du so: Er bewertet alle Antworten, Menschen beurteilen eine Zufallsstichprobe, dann vergleichst du beides. ARES nennt etwa 100 bis 150 Labels als Untergrenze und nutzte 300 in den Hauptexperimenten @saadfalcon2024ares. Die Korrekturmethode *PPI* (Kapitel 6) macht aus beidem einen Wert mit Intervall @angelopoulos2023prediction.

#kdatei("richter_pruefen.py")[
```python
from sklearn.metrics import cohen_kappa_score

mensch = [1, 1, 0, 1, 1, 0, 1, 1, 1, 0]   # 1 = Antwort treu
richter = [1, 1, 1, 1, 1, 0, 1, 1, 0, 0]  # Urteile des LLM-Richters
roh = sum(m == r for m, r in zip(mensch, richter)) / len(mensch)
print(roh, round(cohen_kappa_score(mensch, richter), 2))
```
]

```out
0.8 0.58
```

Hier stimmen beide in 8 von 10 Fällen überein, kappa liegt bei 0.58. Das ist mehr als Zufall, aber bei zehn Antworten sagt es noch kaum etwas aus.

=== Retriever oder Generator? Fehlersuche

Die erste Frage lautet immer gleich: *War die Passage mit der Antwort unter den abgerufenen Chunks?* Wenn nein, kann der Generator nichts retten. Wenn ja, hat die Suche ihre Arbeit gemacht, und der Fehler liegt woanders (@k09-fig-fluss).

#figure(
  diagram(spacing: (8mm, 9mm),
    fknoten((1,0), [Antwort schlecht \ oder falsch], col: c-dark, filled: true, w: 32mm),
    fknoten((1,1), [Stand die nötige Passage \ unter den abgerufenen Chunks?], col: c-blue, w: 46mm),
    fknoten((0,2), [*Nein: Retriever* \ Recall\@k, Chunk-Größe, \ Re-Ranker, größeres k], col: c-teal, filled: true, w: 40mm),
    fknoten((2,2), [Wurde sie in der Antwort \ treu verwendet?], col: c-blue, w: 40mm),
    fknoten((1,3), [*Nein: Generator* \ Prompt, Modell, \ "Ich weiß nicht" erlauben], col: c-accent, filled: true, w: 40mm),
    fknoten((3,3), [*Ja: Quelle oder Frage* \ Quelle prüfen, \ Answer Relevancy], col: c-grey, filled: true, w: 40mm),
    edge((1,0), (1,1), "-|>"),
    edge((1,1), (0,2), "-|>", label: text(size: 7pt)[nein], label-side: left),
    edge((1,1), (2,2), "-|>", label: text(size: 7pt)[ja], label-side: right),
    edge((2,2), (1,3), "-|>", label: text(size: 7pt)[nein], label-side: left),
    edge((2,2), (3,3), "-|>", label: text(size: 7pt)[ja], label-side: right),
  ),
  caption: [Entscheidungsweg für die Fehlersuche. Context Recall beantwortet die erste, Faithfulness die zweite Frage.],
) <k09-fig-fluss>

#kdatei("diagnose.py")[
```python
def diagnose(context_recall, faithfulness):
    if context_recall < 0.8:
        return "Retriever prüfen: relevante Chunks fehlen"
    if faithfulness < 0.8:
        return "Generator prüfen: Antwort weicht vom Kontext ab"
    return "Beide ok: Quelle und Fragestellung prüfen"

print(diagnose(context_recall=1.0, faithfulness=0.5))
```
]

```out
Generator prüfen: Antwort weicht vom Kontext ab
```

Die Schwellen 0.8 sind frei gewählt und müssen zu deinem Einsatz passen. Das Einstein-Beispiel liefert genau diese Konstellation: Der Kontext enthielt Datum und Ort (Context Recall 1.0), die Antwort nannte ein falsches Datum (Faithfulness 0.5), der Fehler lag also im Generator. Ist die Quelle selbst veraltet oder falsch, misst keine der beiden Kennzahlen das; dann musst du die Quelle prüfen.

Barnett et al. leiteten aus drei Fallstudien sieben typische Fehlerpunkte ab: fehlender Inhalt, verpasste Top-Dokumente, nicht im Kontext, nicht extrahiert, falsches Format, falsche Genauigkeit, unvollständig @barnett2024seven. Die Liste hilft, Fehlschläge einzusortieren. Die Autoren schließen, "validation of a RAG system is only feasible during operation": Plane deshalb auch Beobachtung im Betrieb ein und nicht nur ein Testset.

=== Zwei Konfigurationen vergleichen

Konfiguration B hat im Durchschnitt einen höheren nDCG als A. Ist das ein echter Gewinn oder Zufall in deiner Fragenauswahl? Lass beide auf *denselben* Fragen laufen und betrachte den Unterschied pro Frage.

#alltag[Schreib jede Testfrage auf einen Zettel und lege alle in einen Hut. Zieh so viele Zettel, wie du Fragen hast, und lege jeden nach dem Ziehen zurück. Manche Fragen erscheinen doppelt, andere gar nicht. Rechne den durchschnittlichen Gewinn von B über A für diese neue Auswahl aus und wiederhole das tausendmal. Die mittleren 95 % dieser Gewinne ergeben das Intervall.]

Dieses *Konfidenzintervall* nennt den Bereich, in dem der wahre Gewinn plausibel liegt (siehe _Das Nötigste vorab_).

Das heißt *paired bootstrap* @Koehn2004. Die *approximate randomisation* vertauscht stattdessen pro Frage zufällig, welches System welchen Wert bekam, und zählt, wie oft der Zufall allein einen mindestens so großen Gewinn erzeugt; dieser Anteil ist der p-Wert (Kapitel 6). Ein gewöhnlicher Test aus dem Statistikbuch passt hier schlecht, weil Werte wie nDCG seine Annahmen nicht erfüllen.

#kdatei("bootstrap.py")[
```python
import numpy as np

diff = scores_b - scores_a          # ein Wert pro Frage: B minus A
rng = np.random.default_rng(0)
gains = []
for _ in range(5000):
    pick = rng.integers(0, len(diff), len(diff))   # Fragen mit Zurücklegen ziehen
    gains.append(diff[pick].mean())
low, high = np.quantile(gains, [0.025, 0.975])
print(f"Gewinn {diff.mean():.3f}, 95 %-Intervall [{low:.3f}, {high:.3f}]")
```
]

```out
Gewinn 0.063, 95 %-Intervall [0.033, 0.093]
```

Die Zahlen stammen aus Abschnitt 4 des Notebooks (200 simulierte Fragen). B ist dort nur bei 64 % der Fragen besser und bei 36 % schlechter, und trotzdem schließt das Intervall die Null aus. Berichte deshalb den Gewinn mit Intervall, nicht zwei nackte Mittelwerte. Vergleichst du viele Konfigurationen gleichzeitig, musst du für Mehrfachvergleiche korrigieren, und ein statistisch eindeutiger Unterschied kann praktisch trotzdem unbedeutend sein.

Qualität ist auch, wie schnell und wie teuer. Miss die Antwortzeit als Median und als 95. Perzentil (so lange braucht jede zwanzigste Anfrage mindestens), getrennt nach Suche, Neuordnung und Generierung. Die Kosten pro Anfrage ergeben sich aus Tokens mal Preis für jeden Aufruf, für den Generator *und* den Richter. Richteraufrufe können die Kosten dominieren, weil claim-basierte Kennzahlen pro Probe mehrere Aufrufe brauchen. Preise ändern sich: Prüfe sie am Tag des Experiments.

== In der Praxis: Eine RAG-Evaluation in acht Schritten <k09-praxis>

Das ist der Ablauf für ein eigenes Projekt oder eine Abschlussarbeit.

+ *Merkmale festlegen.* Gehe die Checkliste aus ISO/IEC 25010 und 25059 durch und notiere, was du misst und was bewusst nicht (etwa security).
+ *Konstrukte trennen.* Entscheide, ob du Treue, Faktizität, Vollständigkeit, Zitate und Enthaltung messen willst, und miss sie getrennt.
+ *Testset bauen.* Echte und erzeugte Fragen, beantwortbar und unbeantwortbar, eingefroren vor dem ersten Lauf.
+ *Kennzahlen je Ebene wählen.* Mindestens eine für die Suche (etwa Recall\@k, nDCG), eine für den Generator (Faithfulness) und, falls du Musterantworten hast, eine Ende-zu-Ende-Kennzahl.
+ *Richter validieren.* Menschliche Zufallsstichprobe, kappa, Intervall; bei schwachen Werten den Richter nicht verwenden.
+ *Konfigurationen vergleichen.* Gepaart auf denselben Fragen, Gewinn mit Intervall.
+ *Fehlschläge ansehen.* Zieh eine Stichprobe schlechter Antworten und ordne sie nach Retriever, Generator oder Quelle ein.
+ *Berichten.* Ein Qualitätsprofil statt einer Gesamtnote, Faithfulness als Schwelle statt als Mittelwert, dazu Richter, Prompt, Temperatur, Wiederholungen, Werkzeugversionen und Grenzen @haindl2027research @rau2024bergen.

#hoersaal([Wie viele Testfragen brauche ich?], [Eine feste Zahl gibt es nicht. Mehr Fragen machen das Intervall schmaler, aber sie reparieren keinen verzerrten Richter. Für die menschliche Prüfung des Richters nennt ARES etwa 100 bis 150 Labels als Untergrenze @saadfalcon2024ares. Plane lieber Fragen aus dem echten Einsatz als viele gleichartige.])

#hoersaal([Darf ich RAGAS in meiner Arbeit einfach so verwenden?], [Ja, als Werkzeug, aber nicht als Validitätsnachweis. Die Prüfung im Paper betrifft 50 Fragen und ein Richtermodell @es2024ragas. Für deine Daten brauchst du eine eigene menschliche Stichprobe.])

== Für die Lehre <k09-lehre>

Fünf Missverständnisse, die in der Lehrveranstaltung am häufigsten auftreten, und wie du sie auflöst:

- *"Context Precision zeigt, ob die Suche die richtigen Dokumente findet."* Nein, sie bewertet die Reihenfolge innerhalb des Gefundenen. Fehlende Dokumente fängt Context Recall ab. Zeige beides an derselben Liste.
- *"Faithfulness 1.0 heißt, die Antwort stimmt."* Nein, sie heißt: im Kontext gestützt. Verweise auf den Zeugen mit der falschen Akte.
- *"Answer Relevancy prüft, ob die Antwort richtig ist."* Nein, nur ob sie zur Frage passt @ragas2026answerrelevancy.
- *"Ein Richter mit 90 % Übereinstimmung ist gut."* Es kommt auf kappa an. Rechne das Beispiel des faulen Richters vor.
- *"Mehr Fragen machen das Ergebnis richtiger."* Sie machen das Intervall schmaler. Gegen einen verzerrten Richter helfen sie nicht.

Zum Ausprobieren gehört das Notebook `notebooks/09_rag_metrics.ipynb` mit Retrieval-Kennzahlen, claim-basierten Kennzahlen, Nuggets und dem Bootstrap-Vergleich. Es läuft ohne API-Schlüssel mit Spielbeispielen; die Übung 09 baut auf dem Bootstrap-Teil auf.

#kurz(
  [Ein RAG-System kann an der Suche oder am Schreiben scheitern. Miss beide getrennt und beginne die Fehlersuche mit der Frage, ob die nötige Passage abgerufen wurde.],
  [Retrieval-Kennzahlen sind Zählen an einer Trefferliste: Precision (wie viele gezeigte sind brauchbar), Recall (wie viele brauchbare gefunden), MRR (wie weit oben der erste), nDCG (stehen die besten oben).],
  [Generator-Kennzahlen zerlegen die Antwort in Behauptungen und zählen die gestützten. Faithfulness (Treue zum Kontext) ist nicht Factuality (Wahrheit).],
  [Gleich benannte Kennzahlen aus RAGAS, DeepEval und TruLens messen Verschiedenes. Nenne immer Werkzeug, Version und Richtermodell.],
  [Prüfe jeden LLM-Richter an einer menschlichen Stichprobe, mit Cohen's kappa statt roher Übereinstimmung, und gib ein Intervall an.],
  [Vergleiche Konfigurationen gepaart auf denselben Fragen und berichte den Gewinn mit Intervall. Ändere dabei nur eine Schraube pro Lauf.],
)

#selbsttest(
  ([Eine Trefferliste hat fünf Plätze. Platz 2 und 3 sind brauchbar. Im Bestand gibt es vier brauchbare Chunks. Wie groß sind Precision\@5, Recall\@5 und der Reciprocal Rank?], [Precision\@5: 2 von 5, also 40 %. Recall\@5: 2 von 4, also 50 %. Der erste brauchbare Treffer steht auf Platz 2, also ist der Reciprocal Rank 0.5.]),
  ([Eine Antwort hat sechs Behauptungen: vier vom Kontext ableitbar, eine nicht im Kontext, aber ohne Widerspruch, eine im Widerspruch. Wie lauten Faithfulness nach RAGAS und DeepEval?], [RAGAS (ableitbar): 4 von 6, also 0.67. DeepEval (nicht widersprechend): 5 von 6, also 0.83. Die Werkzeuge messen verschiedene Dinge.]),
  ([Context Recall ist 1.0, Faithfulness 0.4. Wo suchst du den Fehler?], [Im Generator. Die nötigen Passagen wurden gefunden, die Antwort weicht aber stark vom Kontext ab.]),
  ([Ein Richter sagt bei 100 Antworten immer "treu", und 90 sind es auch. Warum ist 90 % Übereinstimmung nichts wert?], [Der Richter rät mit der Mehrheit und hat nichts gelernt. Cohen's kappa zieht die Zufallsübereinstimmung ab und ergibt hier 0.]),
  ([Warum eignet sich die Nugget-Wertung zum Ordnen von Systemen, aber schlecht zur Fehlersuche an einzelnen Antworten?], [Die Rangfolge der Systeme stimmt mit der manuellen gut überein (Kendall's tau 0.887 und 0.901), die Wertung einzelner Antworten nur schwach (0.360 bis 0.539).]),
  ([Du änderst Chunk-Größe und Embedding-Modell gleichzeitig, und die Werte steigen. Was ist das Problem?], [Du kannst den Gewinn keiner Änderung zuordnen. Ändere pro Lauf nur eine Schraube.]),
  ([Was gehört zu jedem berichteten RAG-Wert?], [Werkzeug mit Version und Auswertungsmodus, Richtermodell mit Datum, Prompt, Temperatur, Wiederholungen und bei Richterkennzahlen die Prüfung an einer menschlichen Stichprobe.]),
)

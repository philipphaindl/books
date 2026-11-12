#import "lib.typ": *

#set heading(numbering: none)
= Das Nötigste vorab

In diesem Buch fallen Wörter, die im Alltag eines Entwicklers selten vorkommen: Stichprobe, Konfidenzintervall, p-Wert, kappa, Validität. Sie klingen nach Hörsaal und Formelsammlung, beschreiben aber einfache Ideen. Dieses Kapitel erklärt sie ohne eine einzige Formel. Zu jedem Begriff gibt es einen Vergleich aus dem Alltag, ein kleines Zahlenbeispiel und den Hinweis, wo er dir später wieder begegnet.

Lies das Kapitel einmal ganz durch. Danach kannst du aus den Fachkapiteln hierher zurückblättern, wenn ein Begriff wieder auftaucht. Zuerst kommen die vier Begriffe rund um Sprachmodelle, die du für alles Weitere brauchst. Dann folgen die Zahlen: Wie liest man Anteile, Unsicherheit, Fehler und Übereinstimmung, ohne zu rechnen?

#beispiel(titel: [Das Beispiel dieses Kapitels])[
  Ein Online-Shop hat *10~000 Kundenrezensionen*. Du willst wissen, wie viele davon positiv und wie viele negativ sind. Ein Sprachmodell ordnet alle 10~000 Rezensionen ein. Zusätzlich ordnen zwei Menschen *200 zufällig gezogene Rezensionen* von Hand ein und einigen sich bei Meinungsverschiedenheiten. Ihre Einordnung gilt als Maßstab. In diesen 200 sind *120 positiv* und *80 negativ*.

  Mit diesen Zahlen arbeiten wir das ganze Kapitel hindurch. Die Fachkapitel greifen sie wieder auf.
]

#let imbuch(body) = block(above: 0.7em, below: 0.9em, text(size: 8.6pt, fill: c-grey.darken(30%))[*Im Buch:* #body])

== Rund um Sprachmodelle

=== Ein Sprachmodell sagt das nächste Textstück voraus

Kennst du die Wortvorschläge über der Tastatur deines Handys? Du tippst "Ich komme gleich", und das Handy bietet "zu" oder "nach" an. Ein *Large Language Model* (_LLM_, Sprachmodell) ist im Kern dasselbe, nur mit unvorstellbar viel mehr Training. Es hat riesige Mengen Text gesehen und gibt zu jedem Textanfang an, welches Stück Text mit welcher Wahrscheinlichkeit als Nächstes folgt. Dann wählt es eines aus, hängt es an und macht weiter, Stück für Stück, bis die Antwort fertig ist.

Das Modell schlägt nichts nach wie eine Datenbank. Es setzt Muster fort, die es beim Training gelernt hat. Deshalb kann es erstaunlich viel, was nie jemand programmiert hat, und deshalb irrt es sich manchmal mit großer Selbstsicherheit.

Die "Textstücke", mit denen es arbeitet, heißen Token.

#begriff[Token (_token_)][Das Stück Text, mit dem ein Sprachmodell rechnet: ein kurzes Wort, ein Wortteil oder ein Satzzeichen. Lange oder seltene Wörter zerfallen in mehrere Token. Deutsche Texte brauchen meist mehr Token als englische mit gleichem Inhalt. Anbieter rechnen nach Token ab.]

Der Text, den du dem Modell schickst, heißt *Prompt*: die Anweisung, eventuell Beispiele und die Rezension, um die es geht. Stell dir einen Schreibtisch vor, auf dem Prompt und Antwort zusammen Platz haben müssen. Seine Größe heißt *Kontextfenster* (_context window_) und wird in Token angegeben. Was nicht auf den Schreibtisch passt, sieht das Modell nicht. Deshalb schickst du die 10~000 Rezensionen aus unserem Beispiel nicht in einem Rutsch, sondern jede in einem eigenen Aufruf.

=== Temperatur: warum dieselbe Frage verschiedene Antworten liefert

Beim Wortvorschlag auf dem Handy gibt es mehrere gute Kandidaten. Das Modell würfelt gewissermaßen zwischen ihnen, und zwar nicht fair, sondern gewichtet: Wahrscheinliche Textstücke kommen öfter dran als unwahrscheinliche. Die *Temperatur* (_temperature_) bestimmt, wie mutig gewürfelt wird. Bei niedriger Temperatur nimmt das Modell fast immer das wahrscheinlichste Stück, bei hoher auch ausgefallenere. Darum kann dieselbe Frage bei jedem Aufruf eine etwas andere Antwort liefern. Selbst bei niedrigster Temperatur sind die Antworten meist, aber nicht garantiert identisch.

Für das Einordnen von Rezensionen willst du wenig Streuung, also eine niedrige Temperatur. Nicht jedes Modell lässt sich aber noch so einstellen: Manche Anbieter erlauben es bei neueren Modellen nicht mehr, die Temperatur selbst zu setzen (Stand: 11. November 2026). Dann musst du mit der Streuung leben und sie messen, statt sie wegzustellen.

=== Halluzination

Ein Kollege, der nie "das weiß ich nicht" sagt, antwortet auch dann flüssig, wenn er raten muss. Genau so verhält sich ein Sprachmodell. Eine *Halluzination* (_hallucination_) ist ein flüssiger, plausibel klingender Text, der falsch oder erfunden ist, etwa eine Literaturangabe, die es nicht gibt. Das Modell setzt Muster fort und prüft dabei keine Fakten. Eine erfundene Quelle sieht deshalb genauso überzeugend aus wie eine echte.

=== Der API-Aufruf statt des Chatfensters

Im Chat tippst du eine Frage und liest die Antwort. In der Forschung rufst du das Modell aus Programmcode auf, per *API*, und zwar tausendfach und mit festem Prompt. Das Beispiel nutzt das Python-SDK von Anthropic. Bei anderen Anbietern sieht der Aufruf sehr ähnlich aus.

#datei("einordnen.py")[
```python
import anthropic

client = anthropic.Anthropic()   # liest den Schlüssel aus ANTHROPIC_API_KEY

rezension = "Kam nach drei Tagen kaputt an, so ein Reinfall."

antwort = client.messages.create(
    model="MODELL",              # Platzhalter: Modellname laut Anbieter
    max_tokens=1000,             # Obergrenze für die Länge der Antwort
    system="Ordne die Rezension ein. Antworte nur mit: positiv oder negativ.",
    messages=[{"role": "user", "content": rezension}],
)

# Die Antwort besteht aus Blöcken; den Textblock herausholen
text = next(b.text for b in antwort.content if b.type == "text")
print(text)
print(antwort.usage.input_tokens, antwort.usage.output_tokens)
```
]
```out
negativ
38 2
```

Die zweite Ausgabezeile zeigt die verbrauchten Token für Eingabe und Antwort (Beispielwerte). Daraus ergeben sich die Kosten. Eine Temperatur setzt der Code absichtlich nicht, aus dem eben genannten Grund. Packst du den Aufruf in eine Schleife über alle 10~000 Rezensionen, hast du die Einordnung des Modells für den ganzen Datensatz.

#imbuch[Token und Kontextfenster spielen in Kapitel 3 (Prompts) und Kapitel 9 (Dokumentensuche) eine Rolle. Temperatur und Halluzination kehren in Kapitel 4 und Kapitel 10 zurück. Den API-Aufruf baut Kapitel 5 zu einer vollständigen Einordnung aus.]

== Zahlen lesen ohne Formeln

Ab hier geht es um Zahlen. Gerechnet wird nur durch Zählen und mit Prozenten. Die Namen der Kennzahlen musst du trotzdem kennen, denn sie stehen in jedem Paper.

=== Grundgesamtheit und Stichprobe

#alltag[Um zu wissen, ob eine Suppe richtig gewürzt ist, isst du nicht den ganzen Topf leer. Du rührst um und probierst einen Löffel. Nur wenn du vorher gut umgerührt hast, sagt der Löffel etwas über den ganzen Topf.]

Mit den Rezensionen verhält es sich genauso. Die *Grundgesamtheit* (_population_) ist alles, worüber du etwas wissen willst: hier alle 10~000 Rezensionen. Die *Stichprobe* (_sample_) ist der Teil, den du dir tatsächlich ansiehst: hier die 200 von Menschen eingeordneten.

Das "Umrühren" ist das Zufallsziehen: Jede Rezension hat dieselbe Chance, in die Stichprobe zu kommen. Nimmst du stattdessen die ersten 200, erwischst du vielleicht nur den Januar mit den Weihnachtsretouren, und dein Löffel stammt von der Oberfläche des Topfes. In Python genügt `df.sample(200, random_state=42)`. Der feste Startwert `random_state` sorgt dafür, dass du später dieselben 200 wieder ziehen kannst.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((1.8, 0), [*10~000 Rezensionen* \ #text(size: 7pt, fill: c-grey.darken(20%))[alle, die uns interessieren \ (Grundgesamtheit)]], w: 3.6, h: 1.5, bg: rgb("#EAF1FB"), col: c-blue)
    kasten((8.0, 0), [*200 Rezensionen* \ #text(size: 7pt, fill: c-grey.darken(20%))[zufällig gezogen \ (Stichprobe)]], w: 3.6, h: 1.5, bg: rgb("#FFF8E6"), col: c-yellow)
    kasten((14.2, 0), [*60~% positiv* \ #text(size: 7pt, fill: c-grey.darken(20%))[Menschen zählen: \ 120 von 200]], w: 3.6, h: 1.5, bg: rgb("#EAF6EE"), col: c-green)
    pfeil((3.7, 0), (6.1, 0), label: "zufällig ziehen")
    pfeil((9.9, 0), (12.3, 0), label: "einordnen, zählen")
    line((14.2, -0.85), (14.2, -1.5), (1.8, -1.5), stroke: (paint: c-grey.darken(20%), thickness: 0.9pt, dash: "dashed"))
    line((1.8, -1.5), (1.8, -0.85), stroke: (paint: c-grey.darken(20%), thickness: 0.9pt, dash: "dashed"), mark: (end: "stealth", fill: c-grey.darken(20%), scale: 0.6))
    content((8.0, -1.8), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[Rückschluss: bei allen 10~000 liegt der Anteil vermutlich in der Nähe von 60~%])
  }),
  caption: [Aus wenigen Rezensionen schließt man auf alle. Das klappt nur, wenn die kleine Menge zufällig gezogen wurde.],
)

#imbuch[Stichproben begegnen dir in Kapitel 1 (Studien planen), Kapitel 5 (wie viele Rezensionen Menschen einordnen müssen) und Kapitel 6 (Schlüsse auf die Grundgesamtheit).]

=== Anteil und Mittelwert

Das sind die beiden häufigsten Zusammenfassungen. Der *Anteil* (_proportion_) sagt, wie viele von hundert ein Merkmal haben: 120 von 200 Rezensionen sind positiv, also 60~%. Der *Mittelwert* (_mean_, Durchschnitt) entsteht, indem du alle Werte addierst und durch ihre Anzahl teilst. Fünf Rezensionen mit 5, 4, 4, 2 und 5 Sternen ergeben zusammen 20 Sterne, geteilt durch 5 also im Mittel 4 Sterne. Ein Anteil ist übrigens nur ein Mittelwert aus Einsen (positiv) und Nullen (negativ).

Zwei Dinge solltest du im Kopf behalten. Ein Mittelwert verrät nicht, wie die Werte streuen: Eine Reihe aus lauter 3-Sterne-Rezensionen und eine aus lauter 1- und 5-Sterne-Rezensionen haben beide den Durchschnitt 3. Und ein Anteil aus der Stichprobe ist nur eine Schätzung. Ein anderer Löffel Suppe ergäbe vielleicht 58 oder 63~%. Wie viel Spielraum dabei bleibt, klären die nächsten Abschnitte.

#imbuch[Anteile und Mittelwerte tragen praktisch jede Auswertung in den Kapiteln 5, 6 und 8.]

=== Zufallsschwankung und systematischer Fehler

#alltag[Stell dir ein Dartspiel vor. Wer mal links, mal rechts neben die Mitte trifft, dessen Würfe streuen, aber im Schnitt sitzt die Mitte. Wer dagegen immer knapp rechts oben landet, dessen Würfe gleichen sich alle, verfehlen die Mitte aber in dieselbe Richtung.]

Die Streuung nennt man *Rauschen* (_noise_, Zufallsschwankung), die gleichgerichtete Abweichung *Verzerrung* (_bias_, systematischer Fehler).

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let scheibe(cx, punkte, titel) = {
      circle((cx, 0), radius: 1.25, fill: rgb("#F4F3EF"), stroke: 0.7pt + c-grey)
      circle((cx, 0), radius: 0.85, fill: white, stroke: 0.7pt + c-grey)
      circle((cx, 0), radius: 0.45, fill: rgb("#F4F3EF"), stroke: 0.7pt + c-grey)
      circle((cx, 0), radius: 0.07, fill: c-grey, stroke: none)
      for (dx, dy) in punkte { circle((cx + dx, dy), radius: 0.09, fill: c-accent, stroke: none) }
      content((cx, -1.85), align(center, text(font: "Inter", size: 7.3pt, titel)))
    }
    scheibe(1.6, ((0.12, 0.1), (-0.2, 0.05), (0.05, -0.2), (-0.1, -0.15), (0.2, -0.1), (0, 0.2)), [Wenig Rauschen, \ keine Verzerrung])
    scheibe(5.9, ((0.8, 0.3), (-0.7, 0.6), (0.2, -0.9), (-0.6, -0.5), (0.9, -0.4), (-0.2, 0.95)), [Viel Rauschen, \ keine Verzerrung])
    scheibe(10.2, ((0.75, 0.55), (0.55, 0.4), (0.85, 0.45), (0.65, 0.7), (0.6, 0.3), (0.8, 0.62)), [Wenig Rauschen, \ Verzerrung])
    scheibe(14.5, ((0.95, 0.8), (0.2, 0.9), (1.0, 0.1), (0.3, 0.2), (0.8, -0.3), (0.55, 0.5)), [Viel Rauschen, \ Verzerrung])
  }),
  caption: [Die Mitte ist der wahre Wert, jeder Punkt ein Ergebnis (eine Messung, eine Studie, ein Durchlauf).],
)

Dasselbe passiert mit einer Waage. Zeigt sie einmal 71,8 und einmal 72,3 Kilo an, ist das Rauschen. Zeigt sie bei jeder Messung zwei Kilo zu viel, ist sie falsch geeicht, und das ist eine Verzerrung. Daraus folgt die wichtigste Regel dieses Kapitels:

#merke[Mehr Daten verkleinern das Rauschen, aber nicht die Verzerrung. Wer die Waage zehntausend Mal benutzt, kennt den falschen Wert nur genauer.]

Angenommen, das Sprachmodell hielte ironische Rezensionen ("Toll, nach drei Tagen kaputt!") oft für positiv. Dann wäre sein Ergebnis im Schnitt zu positiv, ob du 200 oder 2 Millionen Rezensionen einordnen lässt. Gegen Verzerrung hilft kein größerer Datensatz, sondern nur, sie zu entdecken und zu korrigieren. Das geht, indem man das Modell mit menschlichen Einordnungen vergleicht.

#imbuch[Verzerrungen von Sprachmodellen sind das Thema von Kapitel 8. Wie man trotz Verzerrung gültige Schlüsse zieht, zeigt Kapitel 6.]

=== Konfidenzintervall

Der Wetterbericht sagt nicht "morgen genau 17,3 Grad", sondern "zwischen 14 und 20 Grad". Das ist ehrlicher, weil Vorhersagen unsicher sind. Ein *Konfidenzintervall* (_confidence interval_) tut dasselbe mit einer Zahl aus einer Stichprobe: Es gibt eine Spanne plausibler Werte an. Lies es so: Werte innerhalb der Spanne sind mit den Daten gut vereinbar, Werte weit außerhalb eher nicht. Streng genommen gilt das "95~%", das meist dabei steht, dem Verfahren und nicht der einzelnen Spanne: Wiederholte man die Studie sehr oft, dann enthielten etwa 95 von 100 so berechneten Spannen den wahren Wert.

Je mehr Daten, desto enger die Spanne. Nehmen wir an, in einer Stichprobe wären immer genau 60~% der Rezensionen positiv, aber die Stichproben hätten verschiedene Größen:

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let xs(v) = (v - 30) / 5
    let zeile(y, label, lo, hi, txt) = {
      content((-0.2, y), anchor: "east", text(font: "Inter", size: 7.5pt, label))
      rect((xs(lo), y - 0.15), (xs(hi), y + 0.15), fill: c-blue.lighten(60%), stroke: 0.8pt + c-blue)
      circle((xs(60), y), radius: 0.09, fill: c-blue.darken(20%), stroke: none)
      content((xs(hi) + 0.2, y), anchor: "west", text(font: "Inter", size: 7pt, txt))
    }
    line((xs(60), 0.5), (xs(60), -1.95), stroke: (paint: c-grey, thickness: 0.6pt, dash: "dashed"))
    content((xs(60), 0.75), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[Anteil in der Stichprobe: 60~%])
    zeile(0, [20 Rezensionen], 40, 80, [grob 40 bis 80~%])
    zeile(-0.8, [200 Rezensionen], 53, 67, [53 bis 67~%])
    zeile(-1.6, [2~000 Rezensionen], 58, 62, [58 bis 62~%])
    line((0, -2.1), (12, -2.1), stroke: 0.7pt + c-dark)
    for v in (30, 40, 50, 60, 70, 80, 90) {
      line((xs(v), -2.1), (xs(v), -2.22), stroke: 0.7pt + c-dark)
      content((xs(v), -2.5), text(font: "Inter", size: 7pt, [#v %]))
    }
  }),
  caption: [Konfidenzintervalle (gerundet) für denselben Anteil bei verschieden großen Stichproben. Zehnmal so viele Daten machen die Spanne ungefähr dreimal enger.],
)

Mit 20 Rezensionen weißt du fast nichts: Der wahre Anteil könnte bei 40 oder bei 80~% liegen. Mit 200 kannst du "gut die Hälfte bis zwei Drittel" sagen, mit 2~000 steht der Wert auf wenige Prozentpunkte genau. Die Spanne schrumpft aber nur langsam: Für die halbe Breite brauchst du viermal so viele Daten. Und sie schrumpft nur beim Rauschen. Eine Verzerrung bleibt unsichtbar in der Mitte der Spanne stecken. In Python liefert `proportion_confint(120, 200, method="wilson")` aus dem Paket statsmodels für unser Beispiel etwa 0,53 bis 0,67.

#imbuch[Ohne Konfidenzintervall ist in diesem Buch keine Zahl vollständig. Besonders wichtig wird es in Kapitel 5, 6 und 8.]

=== Signifikanz und p-Wert

Eine Münze zeigt bei 10 Würfen 9 Mal Kopf. Ist sie gezinkt, oder war das Zufall? Du kannst das durch Zählen beantworten. Bei 10 Würfen mit einer fairen Münze gibt es 1~024 mögliche Abfolgen von Kopf und Zahl. Das Diagramm unten zeigt, bei wie vielen davon genau 0, 1, 2 ... Mal Kopf vorkommt.

Genau 9 oder 10 Mal Kopf kommt nur in 11 Abfolgen vor. Auch 9 oder 10 Mal Zahl würde dich misstrauisch machen, das sind noch einmal 11. Zusammen 22 von 1~024, also rund 2~%. Dieser Wert ist der *p-Wert* (_p-value_): Er sagt, wie oft ein mindestens so auffälliges Ergebnis vorkäme, wenn nur der Zufall im Spiel wäre. Ein kleiner p-Wert spricht gegen "reiner Zufall". Üblicherweise nennt man ein Ergebnis *signifikant* (_significant_), wenn der p-Wert unter 5~% liegt. Diese Grenze ist eine Vereinbarung und kein Naturgesetz.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let zahlen = (1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1)
    for (i, n) in zahlen.enumerate() {
      let x = i * 1.25
      let h = n / 252 * 3.0
      let auffaellig = i <= 1 or i >= 9
      rect((x - 0.45, 0), (x + 0.45, h), fill: if auffaellig { c-accent } else { c-blue.lighten(45%) }, stroke: none)
      content((x, h + 0.22), text(font: "Inter", size: 6.5pt, str(n)))
      content((x, -0.27), text(font: "Inter", size: 7pt, str(i)))
    }
    line((-0.7, 0), (14.0, 0), stroke: 0.7pt + c-dark)
    content((6.25, -0.8), text(font: "Inter", size: 7.3pt)[Anzahl Kopf bei 10 Würfen])
    rect((0.0, 3.75), (0.25, 4.0), fill: c-accent, stroke: none)
    content((0.4, 3.87), anchor: "west", text(font: "Inter", size: 7pt)[mindestens 9 Mal dieselbe Seite: 22 von 1~024 Abfolgen, rund 2~%])
  }),
  caption: [So viele der 1~024 möglichen Abfolgen führen bei einer fairen Münze zu jeder Kopfzahl.],
)

Zwei Fehldeutungen kommen besonders oft vor:

+ *"p gleich 2~% heißt: Mit 98~% Wahrscheinlichkeit ist die Münze gezinkt."* Das stimmt nicht. Der p-Wert sagt etwas über die Daten, wenn man den Zufall annimmt. Er sagt nicht, wie wahrscheinlich diese Annahme selbst ist.
+ *"Nicht signifikant heißt: kein Unterschied."* Auch das stimmt nicht. Bei 7 Mal Kopf in 10 Würfen wäre das Ergebnis unauffällig, und die Münze könnte trotzdem leicht gezinkt sein. Man hatte nur zu wenig Daten, um es zu merken.

Dazu kommt ein dritter Punkt: Signifikant heißt nicht groß. Die *Effektstärke* (_effect size_) sagt, wie groß ein Unterschied tatsächlich ist. Bei sehr vielen Daten wird schon ein winziger Unterschied signifikant, etwa wenn ein neuer Prompt 0,3 Prozentpunkte mehr richtige Einordnungen bringt. Praktisch ist das bedeutungslos. Umgekehrt kann ein großer Unterschied bei wenigen Daten untergehen. Berichte deshalb immer beides: die Größe des Unterschieds mit seinem Konfidenzintervall und erst danach den p-Wert.

#imbuch[Immer wenn zwei Dinge verglichen werden, etwa zwei Prompts oder zwei Gruppen, taucht der p-Wert auf: in Kapitel 1, 4 und 8.]

=== Korrelation

Im Sommer steigen die Verkäufe von Speiseeis, und es gibt mehr Sonnenbrände. Beide Zahlen bewegen sich gemeinsam. Die *Korrelation* (_correlation_) misst genau das: wie gleichläufig sich zwei Zahlenreihen bewegen. Ihr Wert liegt zwischen -1 und +1. Bei +1 steigt die eine Reihe immer, wenn die andere steigt. Bei 0 gibt es keinen erkennbaren Zusammenhang. Bei -1 fällt die eine, wenn die andere steigt.

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let feld(x0, punkte, titel) = {
      line((x0, 0), (x0, 3), stroke: 0.7pt + c-dark)
      line((x0, 0), (x0 + 4, 0), stroke: 0.7pt + c-dark)
      for (px, py) in punkte { circle((x0 + 4 * px, 3 * py), radius: 0.08, fill: c-blue, stroke: none) }
      content((x0 + 2, -0.6), align(center, text(font: "Inter", size: 7.3pt, titel)))
    }
    feld(0, ((0.08, 0.15), (0.15, 0.1), (0.22, 0.3), (0.3, 0.28), (0.38, 0.45), (0.45, 0.4), (0.52, 0.58), (0.6, 0.55), (0.68, 0.72), (0.75, 0.7), (0.85, 0.88), (0.92, 0.82)), [gleichläufig \ (Wert nahe +1)])
    feld(5.8, ((0.1, 0.6), (0.2, 0.2), (0.28, 0.85), (0.35, 0.4), (0.45, 0.7), (0.5, 0.15), (0.58, 0.5), (0.65, 0.9), (0.72, 0.3), (0.8, 0.65), (0.88, 0.12), (0.93, 0.55)), [kein Zusammenhang \ (Wert nahe 0)])
    feld(11.6, ((0.08, 0.88), (0.15, 0.8), (0.22, 0.74), (0.3, 0.78), (0.38, 0.6), (0.45, 0.62), (0.52, 0.45), (0.6, 0.42), (0.68, 0.3), (0.75, 0.22), (0.85, 0.18), (0.92, 0.1)), [gegenläufig \ (Wert nahe -1)])
  }),
  caption: [Jeder Punkt ist ein Fall mit zwei Messwerten, etwa die Note eines Menschen und die eines Modells für denselben Text.],
)

Zwei Warnungen gehören dazu. Erstens: Zusammenhang ist nicht Ursache. Das Eis verursacht keinen Sonnenbrand, beides folgt aus dem Wetter. Zweitens: Korrelation ist nicht Gleichheit. Ein Modell, das jeden Text genau einen Punkt besser bewertet als die Menschen, korreliert perfekt mit ihnen (+1) und liegt trotzdem immer daneben. Werte ab etwa 0,7 gelten meist als starker Zusammenhang. Wie viel du für "gut genug" verlangst, hängt von der Aufgabe ab. Varianten wie Pearson und Spearman unterscheiden sich im Detail, die Idee bleibt dieselbe.

#imbuch[Korrelationen vergleichen in Kapitel 7 die Noten eines Sprachmodells mit denen von Menschen. In Kapitel 5 und 9 begegnen sie dir ebenfalls.]

=== Gold-Labels und die Vierfeldertafel

Eine Lehrerin korrigiert Tests mit einem Lösungsschlüssel. Bei der Prüfung eines Sprachmodells übernehmen die menschlichen Einordnungen diese Rolle. Man nennt sie *Gold-Labels* oder *Ground Truth*: Einordnungen, die als richtig gelten, weil sorgfältige Menschen sie vergeben haben. Sie sind nicht fehlerfrei, aber die beste verfügbare Wahrheit. In unserem Beispiel sind das die 200 Rezensionen mit 120 positiven und 80 negativen. Das Sprachmodell hat dieselben 200 ebenfalls eingeordnet. Eine Zähltabelle der Treffer und Fehler heißt *Vierfeldertafel* (_confusion matrix_):

#figure(
  kind: table, supplement: [Tabelle],
  table(columns: (auto, 1fr, 1fr, auto),
    [], [Modell sagt "positiv"], [Modell sagt "negativ"], [Summe],
    [*Mensch: positiv*], [108 (richtig positiv, _true positive_)], [12 (übersehen, _false negative_)], [120],
    [*Mensch: negativ*], [16 (Fehlalarm, _false positive_)], [64 (richtig negativ, _true negative_)], [80],
    [*Summe*], [124], [76], [200],
  ),
  caption: [Das Sprachmodell gegen die menschlichen Gold-Labels, ausgezählt an den 200 Rezensionen.],
)

Aus den vier Zahlen im Inneren lassen sich alle gängigen Kennzahlen zählen. Der Rauchmelder hilft beim Merken:

#alltag[Ein Rauchmelder piept manchmal ohne Feuer und übersieht vielleicht einen echten Brand. Die *precision* fragt, wie viele der Alarme echte Brände waren. Der *recall* fragt, wie viele der echten Brände gemeldet wurden.]

#figure(
  kind: table, supplement: [Tabelle],
  table(columns: (auto, 1fr, auto),
    [Kennzahl], [Frage und Zählung], [Ergebnis],
    [*accuracy*], [Wie oft liegt das Modell insgesamt richtig? 108 + 64 = 172 von 200 Rezensionen.], [86~%],
    [*precision*], [Wenn das Modell "positiv" sagt, wie oft stimmt das? 108 von 124 Aussagen.], [87~%],
    [*recall*], [Wie viele der wirklich positiven findet das Modell? 108 von 120.], [90~%],
    [*F1*], [Eine einzige Zahl, die precision und recall zusammenfasst. Sie ist nur hoch, wenn beide hoch sind.], [88,5~%],
  ),
  caption: [Die Kennzahlen aus der Vierfeldertafel, in Worten gezählt.],
)

Die accuracy täuscht, wenn eine Klasse selten ist. Wären nur 5 von 100 Rezensionen negativ, erreichte ein Modell, das stur "positiv" sagt, 95~% accuracy und wäre nutzlos. Schau deshalb immer auch auf precision und recall. Berechnen lässt sich alles mit `classification_report(gold, modell)` aus scikit-learn. Eine Kleinigkeit steckt noch in der Tabelle: Das Modell nennt 124 Rezensionen positiv, die Menschen nur 120. Das kann ein kleiner Hang zu "positiv" sein, bei 200 Rezensionen lässt sich das aber noch nicht sicher sagen.

#imbuch[Gold-Labels und diese Kennzahlen sind das Rückgrat von Kapitel 5 (Annotation), Kapitel 7 (Sprachmodell als Gutachter) und Kapitel 9 (Dokumentensuche).]

=== Übereinstimmung zwischen zwei Beurteilern

Unsere zwei Menschen ordnen dieselben 200 Rezensionen unabhängig voneinander ein und stimmen bei 184 überein, also bei 92~%. Das klingt hervorragend. Aber auch zwei Beurteiler, die ohne hinzuschauen raten, stimmen oft überein, weil es nur zwei Antworten gibt und eine davon häufig ist. Man muss diese Zufallstreffer herausrechnen. Das tut *Cohen's kappa*: Es fragt, wie viel von der Übereinstimmung, die über den Zufall hinaus möglich wäre, tatsächlich erreicht wurde. Der Wert 0 heißt "nicht besser als Zufall", der Wert 1 "vollkommen einig". Werte ab etwa 0,8 gelten üblicherweise als gut, unter 0,6 als mäßig. Das sind grobe Faustregeln.

#rechnung(titel: [Kappa für unser Beispiel])[
  Raten beide nach dem Anteil (60~% positiv, 40~% negativ), stimmen sie zufällig in 36~% der Fälle überein, beide positiv, und in 16~%, beide negativ. Zufallsübereinstimmung also 52~%. Möglich über den Zufall hinaus wären 100 - 52 = 48 Prozentpunkte. Erreicht wurden 92 - 52 = 40. Zwei Beurteiler schaffen also 40 von 48 möglichen Punkten, das ist kappa von etwa 0,83.
]

Für mehr als zwei Beurteiler gibt es *Krippendorff's alpha*, Details dazu in Kapitel 5. Dieselbe Idee misst auch die Übereinstimmung zwischen Mensch und Sprachmodell.

#imbuch[Kappa bestimmt in Kapitel 5, wie verlässlich die Gold-Labels selbst sind, und in Kapitel 7, wie gut ein Sprachmodell als Gutachter zu Menschen passt.]

=== Reliabilität und Validität

#alltag[Eine Waage zeigt bei derselben Person jeden Morgen genau 72,0 Kilo an, aber die Person wiegt 75.]

Die Waage ist *reliabel* (_reliable_, verlässlich), denn sie liefert bei Wiederholung dasselbe Ergebnis, aber nicht *valide* (_valid_, gültig), denn sie misst nicht das Richtige. Im Zielscheibenbild entspricht die Reliabilität dem engen Streukreis und die Validität dem Treffer in der Mitte. Die Scheibe "wenig Rauschen, Verzerrung" ist zuverlässig und trotzdem falsch.

Bei Sprachmodellen ist das ein reales Risiko. Ordnet das Modell dieselbe Rezension bei zehn Aufrufen zehn Mal gleich ein, ist die Einordnung reliabel. Ob sie valide ist, ist eine andere Frage. Mit "positiv" meinst du vielleicht "der Kunde war zufrieden". Das Modell reagiert womöglich eher auf freundliche Wörter und misst damit etwas anderes. Prüfen kannst du es nur, indem du die Ergebnisse mit einem Maßstab vergleichst, im einfachsten Fall mit den Gold-Labels. Verlässlichkeit ist notwendig, aber nicht hinreichend: Man kann auch zuverlässig danebenliegen.

#imbuch[Reliabilität und Validität strukturieren die Qualitätsfragen in Kapitel 1, 5 und 7.]

=== Reproduzierbarkeit

Ein gutes Rezept lässt sich nachkochen: Jemand anderes nimmt dieselben Zutaten, folgt denselben Schritten und bekommt dasselbe Gericht. *Reproduzierbarkeit* (_reproducibility_) heißt dasselbe für Forschung: Andere, oder du selbst in einem Jahr, kommen mit denselben Daten und demselben Vorgehen zum selben Ergebnis. Etwas weiter geht die *Replizierbarkeit* (_replicability_): Neue Daten, gleiche Methode, ähnliches Ergebnis.

Bei Sprachmodellen ist das schwieriger als bei einer Tabellenkalkulation. Die Antworten schwanken (siehe Temperatur), Anbieter ändern Modelle im Hintergrund oder nehmen alte Versionen vom Netz, und ein Prompt wird beim Ausprobieren laufend umgeschrieben. Halte deshalb fest: Modellname und Version, Datum, den vollständigen Prompt, alle Einstellungen, den Startwert der Zufallsziehung, die Rohantworten und den Code.

#imbuch[Wie man das ohne Mehraufwand organisiert, zeigt Kapitel 10.]

== Die Begriffe auf einen Blick

#figure(
  kind: table, supplement: [Tabelle],
  table(columns: (auto, 1fr, auto),
    [Begriff], [Frage, die er beantwortet], [Kapitel],
    [Token, Kontextfenster], [Wie viel Text passt in einen Aufruf, und was kostet er?], [3, 9],
    [Temperatur, Halluzination], [Wie stark streuen die Antworten, und wo erfindet das Modell etwas?], [4, 10],
    [Stichprobe], [Darf ich von diesen 200 auf alle 10~000 schließen?], [1, 5, 6],
    [Anteil, Mittelwert], [Wie viele sind es, oder wie hoch ist es im Schnitt?], [5, 6, 8],
    [Rauschen und Verzerrung], [Ist der Fehler zufällig oder gleichgerichtet?], [6, 8],
    [Konfidenzintervall], [Wie sicher ist diese Zahl?], [5, 6, 8],
    [p-Wert, Effektstärke], [Ist der Unterschied mehr als Zufall, und ist er groß?], [1, 4, 8],
    [Korrelation], [Bewegen sich zwei Reihen gemeinsam?], [5, 7, 9],
    [Gold-Labels, accuracy, precision, recall], [Wie oft liegt das Modell gegenüber dem Maßstab richtig?], [5, 7, 9],
    [Kappa], [Stimmen zwei Beurteiler über den Zufall hinaus überein?], [5, 7],
    [Reliabilität, Validität], [Ist die Messung stabil, und misst sie das Richtige?], [1, 5, 7],
    [Reproduzierbarkeit], [Kann jemand anderes das nachmachen?], [10],
  ),
  caption: [Die Begriffe dieses Kapitels und das Kapitel, in dem sie wichtig werden.],
)

#kurz(
  [Ein Sprachmodell sagt Token für Token das wahrscheinlich Nächste voraus. Deshalb schwanken seine Antworten (Temperatur), es hat ein Platzlimit (Kontextfenster) und erfindet gelegentlich Dinge (Halluzination).],
  [Aus einer zufällig gezogenen Stichprobe schließt man auf die Grundgesamtheit. Das Konfidenzintervall zeigt, wie sicher dieser Schluss ist, und wird mit mehr Daten enger.],
  [Mehr Daten verkleinern das Rauschen, aber nicht die Verzerrung. Eine Verzerrung findet man nur im Vergleich mit einem Maßstab.],
  [Ein kleiner p-Wert spricht gegen reinen Zufall, er ist keine Wahrscheinlichkeit für die Hypothese. Signifikant heißt nicht groß, deshalb gehört die Effektstärke dazu.],
  [Korrelation misst Gleichlauf zwischen -1 und +1, nicht Gleichheit und nicht Ursache.],
  [Gold-Labels sind der Lösungsschlüssel. Aus der Vierfeldertafel zählst du accuracy, precision und recall. Kappa rechnet Zufallstreffer zwischen Beurteilern heraus.],
  [Reliabel heißt stabil, valide heißt richtig. Und nur was jemand anderes nachmachen kann, ist reproduzierbar.],
)

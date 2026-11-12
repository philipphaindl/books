#import "../lib.typ": *
#import "@preview/cetz-plot:0.1.2": plot

// Hilfen für dieses Kapitel. Code und Ausgaben stammen direkt aus den ausgeführten Dateien in code/12/,
// alle Zahlen im Text und in den Abbildungen aus den dort geschriebenen JSON-Dateien.
#let code-aus(datei, ab, bis: none, lang: "python") = {
  let z = read("../code/12/" + datei).split("\n")
  let i = z.position(l => l.contains(ab))
  let rest = z.slice(i)
  let k = if bis == none { none } else { rest.slice(1).position(l => l.contains(bis)) }
  let teil = if k == none { rest } else { rest.slice(0, k + 2) }
  raw(teil.join("\n").trim("\n", at: end), lang: lang, block: true)
}
#let lauf(skript, pfad) = block(breakable: false, raw("$ python " + skript + "\n" + read("../code/12/out/" + pfad).trim("\n", at: end), lang: "terminal", block: true))
#let gruen = rgb("#2EAE7D")
#let orange = rgb("#B5651D")
#let nebenbei(t) = text(size: 8.5pt, fill: grau, t)
#let j(name) = json("../code/12/out/" + name + ".json")
#let zahl(x, n: 1) = {
  let s = str(calc.round(x, digits: n))
  let t = s.split(".")
  let f = if t.len() > 1 { t.at(1) } else { "" }
  t.at(0) + if n > 0 { "," + f + "0" * (n - f.len()) } else { "" }
}
#let proz(x, n: 1) = zahl(x * 100, n: n) + " %"
#let eur(x) = zahl(x, n: 0) + " €"
#let tsd(n) = {
  let s = str(calc.round(n))
  let r = ""
  for (i, c) in s.clusters().rev().enumerate() {
    if i > 0 and calc.rem(i, 3) == 0 { r = "\u{202F}" + r }
    r = c + r
  }
  r
}
#let achse(v) = if v == calc.round(v) { str(int(v)) } else { str(calc.round(v, digits: 2)).replace(".", ",") }
#let daten-plot(..args) = block(width: 100%, align(center, text(size: 9pt, canvas(length: 1cm, {
  draw.set-style(axes: (stroke: 0.6pt, tick: (stroke: 0.5pt)))
  plot.plot(x-format: achse, y-format: achse, ..args)
}))))
#let so-erklaere-ich-es(text-, frage, antwort) = kasten([So erkläre ich es.], [
  #text-
  #v(0.4em)
  *Verständnisfrage:* #frage \
  *Antwort:* #antwort
])

#let d1 = j("01_heuristik")
#let d2 = j("02_naiv")
#let d3 = j("03_split")
#let d4 = j("04_rebalancing")
#let d5 = j("05_transform")
#let d6 = j("06_erklaerung")
#let d7 = j("07_fairness")
#let d8 = j("08_monitoring")

#show heading.where(level: 1): set text(hyphenate: false)
= Fallstudie A: Kundenabwanderung bei einem Streamingdienst

In den Kapiteln zuvor stand jedes Pattern für sich: ein Szenario, ein Problem, eine Lösung. Ein Projekt verläuft anders. Man beginnt mit einem Notebook, das „funktioniert“, und stößt der Reihe nach auf die Probleme, die einzelne Patterns lösen, oft erst, nachdem jemand eine falsche Zahl präsentiert hat. Dieses Kapitel erzählt ein solches Projekt: Ein Team soll vorhersagen, welche Kundinnen und Kunden eines Streamingdienstes demnächst kündigen, startet mit einem naiven Notebook und verbessert es in acht Schritten. Jeder Schritt wird mit Zahlen aus lauffähigem Code (`code/12/`) gemessen, und hinter jedem steht ein Pattern, das Sie bereits kennen. Wichtiger als jedes Detail ist die Abfolge: warum man das eine vor dem anderen tut und woran man merkt, dass es fehlt.

#kasten([Lernziele.], [
  Nach diesem Kapitel können Sie erklären, warum ein Projekt mit einer Faustregel beginnt und nicht mit einem Modell; wie ein Split nach Zeilen eine PR-AUC von #zahl(d3.ergebnis.gross.kunden.ap, n: 2) auf #zahl(d3.ergebnis.gross.zeilen.ap, n: 2) aufbläht und warum er sogar die Modellwahl verfälscht; weshalb eine hohe Genauigkeit bei seltenen Ereignissen nichts aussagt und wie man stattdessen aus Kosten eine Entscheidungsregel ableitet; wie eine Pipeline Training und Betrieb zusammenhält; was eine Erklärung und eine Auswertung nach Gruppen im Projektalltag leisten; und wie man ein Modell im Betrieb überwacht, wenn die Wahrheit erst Monate später bekannt wird.
])

== Ausgangslage und Daten

Der Streamingdienst verkauft monatlich kündbare Abonnements in drei Tarifen (ab Monat 16 in vier). Das Retention-Team kann jeden Monat einigen Kundinnen und Kunden ein Halteangebot schicken, etwa einen Gutschein über einen Gratismonat. Es möchte wissen, _wen_ es ansprechen soll: Das Modell soll jeden Kunden am Monatsende bewerten, und zwar mit einer Wahrscheinlichkeit, dass das Abonnement innerhalb der nächsten drei Monate endet. Aus den Wahrscheinlichkeiten macht eine Entscheidungsregel eine Liste.

Die Daten sind simuliert (`daten.py`, fester Seed). Das hat einen Preis und einen Nutzen. Der Preis: Echte Daten sind unordentlicher, und Effekte sind selten so sauber trennbar wie hier. Der Nutzen: Wir kennen die Mechanik hinter den Zahlen, weil wir sie gebaut haben, und können deshalb prüfen, ob eine Methode das Richtige findet. Der Dienst startet in Monat 0 und wächst; insgesamt entstehen #tsd(d1.kunden_gesamt) Kunden mit zusammen #tsd(d1.zeilen_gesamt) Zeilen, im Mittel also gut elf Zeilen je Kunde. _Eine Zeile ist ein Kunde in einem Monat_, mit den Werten vom Monatsende. Das Ziel `abwanderung_3m` ist 1, wenn das Abonnement spätestens mit dem Monat _m_ + 2 endet (@abb-zeilen). Im Entwicklungsfenster trifft das auf #proz(d1.basisrate) der Zeilen zu: Die Daten sind stark unausgewogen.

#figure(
  canvas(length: 1cm, {
    import draw: *
    let w = 1.1
    let b = w - 0.08
    for m in range(0, 13) {
      let x = m * w
      let aktiv = m <= 9
      let pos = m >= 7 and m <= 9
      rect((x, 0), (x + b, 0.8),
        fill: if not aktiv { white } else if pos { rgb("#FBF1E6") } else { rgb("#E1F3EB") },
        stroke: (paint: if not aktiv { luma(190) } else if pos { orange } else { gruen }, thickness: 0.8pt, dash: if aktiv { "solid" } else { "dashed" }))
      if aktiv { content((x + b / 2, 0.4), text(size: 9pt, str(if pos { 1 } else { 0 }))) }
      content((x + b / 2, -0.3), text(size: 8.5pt, str(m)))
    }
    content((-0.15, 0.4), anchor: "east", text(size: 8.5pt)[Ziel])
    content((-0.15, -0.3), anchor: "east", text(size: 8.5pt)[Monat _m_])
    // Der Kunde zahlt zuletzt in Monat 9
    line((10 * w - 0.04, -0.6), (10 * w - 0.04, 1.35), stroke: (paint: orange, thickness: 1pt, dash: "dashed"))
    content((10 * w + 0.08, 1.2), anchor: "west", text(size: 8.5pt, fill: orange)[Abo endet nach Monat 9])
    // Horizont der Zeile aus Monat 7
    line((7 * w, 1.15), (9 * w + b, 1.15), mark: (start: "|", end: "|"), stroke: 0.8pt + blau)
    content((7 * w + (2 * w + b) / 2, 1.65), text(size: 8.5pt, fill: blau)[Horizont der Zeile aus Monat 7: Monate 7 bis 9])
  }),
  caption: [Ein Kunde, der von Monat 0 an dabei war und nach Monat 9 kündigt, liefert Zeilen für die Monate 0 bis 9. Die letzten drei tragen das Ziel 1, weil sein Abo spätestens zwei Monate nach dem jeweiligen Zeilenmonat endet. Der Kunde besteht also aus zehn Zeilen, die einander sehr ähnlich sehen.],
) <abb-zeilen>

Dieser Aufbau trägt das ganze Kapitel: Die Zeilen eines Kunden sind keine unabhängigen Beispiele. Sie teilen Alter, Land und Anschlussgeschwindigkeit, und bei Abwanderern folgen auf eine Zeile mit Ziel 1 meist zwei weitere.

#figure(
  table(columns: (auto, 1fr), align: (left, left),
    table.header[Gruppe][Spalten und Bedeutung],
    [Kunde (konstant)], [`alter`, `land`, `kanal` (wie gewonnen: organisch, Werbung, Partner, Aktion), `geraet`, `anmeldetag` (Tage seit Start des Dienstes), `bandbreite_mbit` (typische Anschlussgeschwindigkeit)],
    [Vertrag], [`tarif` (basic, standard, premium, ab Monat 16 auch mobil), `preis` pro Monat, `tenure` (Monate seit Anmeldung), `aktion_restmonate` (Rest des Aktionspreises)],
    [Nutzung], [`stunden`, `sessions`, `tage_seit_login`, `stunden_trend` (Stunden dieses Monats geteilt durch den Schnitt der drei Vormonate)],
    [Betreuung, Zahlung], [`tickets_30d` (Supportanfragen), `zahlungsfehler_90d` (fehlgeschlagene Abbuchungen)],
  ),
  caption: [Die Merkmale der Tabelle; Ziel ist `abwanderung_3m`. Die Altersgruppe in Schritt 7 wird aus `alter` abgeleitet.],
)

Zwei Festlegungen gelten für das ganze Kapitel. Erstens die Zeit (@abb-kalender): Die Monate 0 bis 12 stehen zur Entwicklung bereit, danach beginnt der „Betrieb“. In Monat 16 ändert sich die Welt: Der Dienst führt den Tarif _mobil_ ein und erhöht die Preise von _standard_ und _premium_ um zwei Euro. Das Ziel einer Zeile ist erst drei Monate später bekannt, deshalb enden die Daten mit gültigem Ziel in Monat 20, obwohl der Dienst bis Monat 23 beobachtet wurde. Zweitens das Geld. Ein Halteangebot kostet 5 €, hält 30 % der angesprochenen Abwanderer, und ein gehaltener Kunde bringt 60 € Deckungsbeitrag (angenommene Zahlen, keine Messwerte). Damit lassen sich Entscheidungen in Euro bewerten: Ein Kontakt lohnt sich, wenn die Abwanderungswahrscheinlichkeit größer ist als 5 / (0,3 · 60) = #zahl(d4.kosten.schwelle, n: 3), also rund 28 %.

#figure(
  canvas(length: 1cm, {
    import draw: *
    let w = 0.66
    let seg(von, bis, farbe, rand, text-) = {
      rect((von * w, 0), ((bis + 1) * w, 0.8), fill: farbe, stroke: 0.8pt + rand)
      content(((von + bis + 1) * w / 2, 0.4), text(size: 8.5pt, text-))
    }
    seg(0, 12, blau-hell, blau, [Entwicklung, Monate 0 bis 12])
    seg(13, 20, rgb("#E1F3EB"), gruen, [Betrieb mit Ziel, 13 bis 20])
    seg(21, 23, luma(240), luma(160), [ohne Ziel])
    for m in (0, 6, 12, 13, 16, 20, 23) {
      content(((m + 0.5) * w, -0.3), text(size: 8.5pt, str(m)))
    }
    line((16 * w, 0.8), (16 * w, 1.3), stroke: (paint: orange, thickness: 1pt))
    content((16 * w + 0.1, 1.15), anchor: "west", text(size: 8.5pt, fill: orange)[Monat 16: Tarif _mobil_, höhere Preise])
  }),
  caption: [Die Zeitachse des Projekts. Bis Monat 12 wird entwickelt, ab Monat 13 läuft das Modell im Betrieb. Ab Monat 21 ist das Ziel der Zeilen noch nicht bekannt.],
) <abb-kalender>

== Schritt 1: Zuerst der Maßstab (Heuristic Benchmark)

Bevor jemand ein Modell trainiert, fragt die Teamleiterin das Retention-Team, wie es heute vorgeht. Die Antwort ist eine Faustregel: Wer seit mindestens vier Tagen nicht mehr eingeloggt war oder in diesem Monat weniger als halb so viele Stunden geschaut hat wie im Schnitt der drei Vormonate, bekommt ein Angebot. Das ist der _Heuristic Benchmark_ (Pattern 28): ein einfacher Vergleichsmaßstab, den ein Modell schlagen muss, um seinen Aufwand zu rechtfertigen. Die Regel braucht kein Training, also auch keinen Split; man darf sie auf allen Entwicklungsdaten messen.

#code-aus("01_heuristik.py", "# Maßstab 1", bis: "ap_login = ")

#lauf("01_heuristik.py", "01_heuristik.txt")

Die Zahlen sind aufschlussreicher, als es zunächst scheint. Wer niemandem ein Angebot schickt, hat eine Genauigkeit von #zahl(d1.nie.accuracy, n: 3), und die Faustregel schneidet mit #zahl(d1.regel.accuracy, n: 3) _schlechter_ ab als das Nichtstun. Genauigkeit ist bei einer Quote von #proz(d1.basisrate) offenbar die falsche Währung, dazu mehr in Schritt 4. Die Faustregel erwischt #proz(d1.regel.recall, n: 0) der späteren Abwanderer (Recall), aber nur #proz(d1.regel.precision, n: 0) der Angeschriebenen kündigen tatsächlich (Precision). Weil das unter den 28 % liegt, die ein Angebot kosten darf, verliert die Kampagne mit dieser Regel Geld: #eur(d1.regel.nutzen) je 1000 Kunden-Monate. Rangiert man die Kunden nur nach der Zahl der Tage seit dem letzten Login, ergibt sich eine PR-AUC (average precision; dazu Pattern 10) von #zahl(d1.ap_login, n: 3), gegenüber #zahl(d1.basisrate, n: 3) bei zufälligem Raten. Das sind die Messlatten: #zahl(d1.ap_login, n: 3) beim Ranking, 0 € bei der Kampagne.

== Schritt 2: Das naive Notebook

Zwei Wochen später zeigt die Data Scientist ihr Notebook: ein Gradient-Boosting-Modell (viele nacheinander gelernte Entscheidungsbäume), großzügig dimensioniert, weil es „alles lernen kann“, mit `pd.get_dummies` für die Kategorien und dem Standardsplit `train_test_split` (80 % Training, 20 % Test).

#code-aus("02_naives_notebook.py", "X = pd.get_dummies", bis: "k = kennzahlen")

#lauf("02_naives_notebook.py", "02_naives_notebook.txt")

Auf den ersten Blick ein Erfolg: Genauigkeit #zahl(d2.accuracy, n: 3), Precision #zahl(d2.precision, n: 2), PR-AUC #zahl(d2.ap, n: 3), fast doppelt so viel wie beim Ranking nach Login-Tagen (#zahl(d1.ap_login, n: 3)). Drei Dinge sollten das Team misstrauisch machen. Die Genauigkeit liegt kaum über dem Wert für „niemand kündigt“ (#zahl(d1.nie.accuracy, n: 3)). Das Modell findet nur #proz(d2.recall, n: 0) der Abwanderer. Und die Testzeilen wurden zufällig aus einer Tabelle gezogen, in der jeder Kunde im Mittel #zahl(d1.zeilen / d1.kunden) Zeilen hat. Der letzte Punkt bekommt als nächstes eine eigene Prüfung.

== Schritt 3: Der Split nach Kunden (Repeatable Splitting)

*Das Leck.* Beim zufälligen Zeilen-Split landen die Zeilen eines Kunden in Training _und_ Test. Im Skript `03_split.py` sind es #tsd(d3.ueberlapp) Kunden, und bei #proz(d3.geschwister_anteil) der Testzeilen gibt es mindestens eine Zeile desselben Kunden im Training. Das Modell muss einen Kunden nicht verstehen, es genügt, ihn wiederzuerkennen: `anmeldetag` und `bandbreite_mbit` ändern sich nie und wirken wie ein Fingerabdruck, und die benachbarte Zeile im Training verrät das Ziel (bei Abwanderern sind drei Zeilen hintereinander positiv). Ein großes Modell mit winzigen Blättern kann solche Muster auswendig lernen. Die Testzahl misst dann zum Teil Gedächtnis. Das lässt sich nachweisen: Ohne die beiden Spalten sinkt die PR-AUC des großen Modells auf dem Zeilen-Split von #zahl(d3.ergebnis.gross.zeilen.ap, n: 3) auf #zahl(d3.ergebnis.gross.zeilen_ohne_fingerabdruck.ap, n: 3) (Ausgabe unten). Die restliche Lücke bis #zahl(d3.ergebnis.gross.kunden.ap, n: 3) beim Kunden-Split erklärt dieser Versuch nicht. Plausibel ist, dass auch weniger auffällige, über Monate stabile Merkmale wie Alter, Land und Nutzungsniveau helfen, einen Kunden wiederzuerkennen; dazu kommt, dass beide Splits verschiedene Testkunden verwenden. Die übliche Zufallsmischung setzt voraus, dass Zeilen unabhängig sind, und diese Voraussetzung ist hier verletzt.

*Die Lösung.* Das Pattern _Repeatable Splitting_ (Pattern 22) trennt nach der Einheit, die unabhängig ist, hier dem Kunden, und macht die Zuordnung deterministisch. Ein Hash der Kunden-ID bestimmt den Bucket (0 bis 9). Die Buckets 0 bis 5 gehören zum Training, 6 und 7 zur Validierung, 8 und 9 zum Test, und diese Zuordnung gilt für jede Zeile jedes Kunden.

#code-aus("daten.py", "def bucket(", bis: "return df[df.bucket < 6]")

Der Hash ist SHA-256 und nicht Pythons eingebautes `hash()`. Die Begründung steht in der Ausgabe weiter unten: Das eingebaute `hash()` für Strings ist pro Prozess gesalzen, liefert also bei jedem Start eine andere Zuordnung (die Zahlen dieser Ausgabezeile ändern sich bei jedem Aufruf). Ein Split, der sich bei jedem Lauf ändert, ist kein Split, auf den man ein Ergebnis stützen kann.

#figure(
  {
    let r = d3.raster
    canvas(length: 1cm, {
      import draw: *
      let w = 0.6
      let h = 0.52
      let x0 = 2.1
      let feld(x, y, seite, ziel) = {
        let (farbe, rand) = if seite == none { (white, luma(215)) } else if seite == "test" { (rgb("#FBF1E6"), orange) } else { (blau-hell, blau) }
        rect((x, y), (x + w - 0.05, y + h - 0.05), fill: farbe, stroke: 0.6pt + rand)
        if ziel == 1 { circle((x + w / 2 - 0.025, y + h / 2 - 0.025), radius: 0.09, fill: rgb("#8B2E2E"), stroke: none) }
      }
      for panel in (0, 1) {
        let dx = panel * 8.9
        content((x0 + dx + 3.9, 4.7), text(size: 9pt, weight: "bold")[#if panel == 0 [Zeilen-Split (zufällig)] else [Hash-Split (nach Kunde)]])
        for (i, k) in r.enumerate() {
          let y = (7 - i) * h
          if panel == 0 { content((x0 + dx - 0.15, y + h / 2), anchor: "east", text(size: 8pt, fill: grau, k.id)) }
          for m in range(13) {
            let seite = if k.zeile.at(m) == none { none } else if panel == 0 { k.zeile.at(m) } else if k.bucket >= 8 { "test" } else { "train" }
            feld(x0 + dx + m * w, y, seite, k.ziel.at(m))
          }
        }
      }
      let lx = 2.1
      rect((lx, -0.75), (lx + 0.3, -0.5), fill: blau-hell, stroke: 0.6pt + blau)
      content((lx + 0.4, -0.62), anchor: "west", text(size: 8.5pt)[Training])
      rect((lx + 2.0, -0.75), (lx + 2.3, -0.5), fill: rgb("#FBF1E6"), stroke: 0.6pt + orange)
      content((lx + 2.4, -0.62), anchor: "west", text(size: 8.5pt)[Test])
      circle((lx + 3.9, -0.62), radius: 0.09, fill: rgb("#8B2E2E"), stroke: none)
      content((lx + 4.1, -0.62), anchor: "west", text(size: 8.5pt)[Ziel = 1])
      content((lx + 6.3, -0.62), anchor: "west", text(size: 8.5pt)[Spalten: Monate 0 bis 12, Zeilen: acht Kunden])
    })
  },
  caption: [Zuordnung der Zeilen von acht Kunden unter beiden Verfahren (die ersten acht mit mindestens zehn Zeilen, echte Zuordnung aus dem Skript; beim Hash-Split sind hier Training und Validierung zusammengefasst). Links gehört fast jeder Kunde zu beiden Seiten, rechts nur zu einer. Die roten Punkte markieren Zeilen mit Ziel 1: Links liegen sie neben Trainingszeilen desselben Kunden.],
) <abb-leck>

#lauf("03_split.py", "03_split.txt")

Die Tabelle in der Ausgabe enthält drei Befunde. Der erste betrifft das Modell aus dem Notebook (das „große“): Seine PR-AUC fällt von #zahl(d3.ergebnis.gross.zeilen.ap, n: 3) beim Zeilen-Split auf #zahl(d3.ergebnis.gross.kunden.ap, n: 3) beim Kunden-Split, ein Verlust von #proz(1 - d3.ergebnis.gross.kunden.ap / d3.ergebnis.gross.zeilen.ap, n: 0). Dieselben Daten, dasselbe Modell, nur eine andere Trennlinie. Ein Drittel der schönen Zahl der Data Scientist war Wiedererkennen statt Verallgemeinern.

Der zweite Befund ist heimtückischer. Auf dem Zeilen-Split gewinnt das große Modell (#zahl(d3.ergebnis.gross.zeilen.ap, n: 3) gegenüber #zahl(d3.ergebnis.klein.zeilen.ap, n: 3) für ein kleineres mit flachen Bäumen und großen Blättern). Wer so auswählt, nimmt das größere. Auf den Validierungskunden dreht sich die Reihenfolge um (#zahl(d3.ergebnis.gross.validierung.ap, n: 3) gegenüber #zahl(d3.ergebnis.klein.validierung.ap, n: 3)), und auf den Testkunden bestätigt sie sich (#zahl(d3.ergebnis.gross.kunden.ap, n: 3) gegenüber #zahl(d3.ergebnis.klein.kunden.ap, n: 3)). Ein leckender Split verzerrt also nicht nur eine Zahl, sondern auch die Entscheidungen, die man auf Grundlage dieser Zahl trifft. Für den Rest des Kapitels gilt das kleinere Modell.

Der dritte Befund betrifft die Wiederholbarkeit. Kommen neue Monate hinzu, wächst die Tabelle von #tsd(d1.zeilen) auf #tsd(d1.zeilen_gesamt) Zeilen. Ruft man `train_test_split` mit demselben `random_state` auf der größeren Tabelle auf, wechseln #proz(d3.wechsel_zeile, n: 0) der alten Zeilen die Seite. Zeilen, mit denen ein Modell trainiert wurde, tauchen im neuen Test auf, und Vergleiche zwischen Läufen sind wertlos. Beim Hash-Split wechselt keine (#proz(d3.wechsel_hash, n: 0)): Wer einmal im Test war, bleibt im Test.

#achtung[Der Hash-Split schützt vor Kunden-Leck, nicht vor Zeit-Leck. Zeilen anderer Kunden aus späteren Monaten können im Training liegen, während ein Testkunde aus einem früheren Monat stammt. Für Marktveränderungen wie die in Monat 16 reicht ein Split nach Kunden deshalb nicht; dort hilft nur der zeitliche Test, den Schritt 8 durchführt.]

== Schritt 4: Seltene Ereignisse (Rebalancing)

Mit dem sauberen Split sieht die Lage nüchterner aus, aber noch nicht hoffnungslos: Das kleine Modell erreicht auf dem Test eine PR-AUC von #zahl(d3.ergebnis.klein.kunden.ap, n: 3). Nun fehlt noch die Entscheidung. Aus Wahrscheinlichkeiten muss eine Liste werden, und dafür gibt es Stellschrauben, die das Pattern _Rebalancing_ (Pattern 10) beschreibt: Klassengewichte, Downsampling der Mehrheitsklasse und eine verschobene Schwelle. Das Skript `04_rebalancing.py` probiert sie nebeneinander aus; alle Modelle sind auf den Trainingskunden gelernt, Schwellen auf den Validierungskunden gewählt und alle Zahlen auf den Testkunden gemessen.

#code-aus("04_rebalancing.py", "m_plain = fit", bis: "m_down = fit")

#lauf("04_rebalancing.py", "04_rebalancing.txt")

Die Tabelle lässt sich auf vier Beobachtungen verdichten.

*Die PR-AUC bleibt, wo sie ist.* Sie liegt für alle sechs Varianten zwischen #zahl(calc.min(..d4.varianten.values().map(v => v.ap)), n: 3) und #zahl(calc.max(..d4.varianten.values().map(v => v.ap)), n: 3). Gewichte und Downsampling ändern kaum, wie gut das Modell Kunden _ordnet_, und die Schwelle ändert die PR-AUC per Definition nicht; sie legt nur fest, wo die Linie „angesprochen / nicht angesprochen“ verläuft. Rebalancing ist hier eine Entscheidungsfrage, keine Lernfrage (@abb-pr).

*Die Genauigkeit zeigt nichts.* Variante A erreicht #zahl(d4.varianten.A.accuracy, n: 3), „niemand kündigt“ erreicht #zahl(1 - d4.basisrate, n: 3). Der Unterschied liegt in der dritten Stelle, während der Recall zwischen #zahl(calc.min(..d4.varianten.values().map(v => v.recall)), n: 2) und #zahl(calc.max(..d4.varianten.values().map(v => v.recall)), n: 2) schwankt.

*Gewichte ohne neue Schwelle sind gefährlich.* Variante B (`class_weight="balanced"` und Schwelle 0,5) findet #proz(d4.varianten.B.recall, n: 0) der Abwanderer, gut zweieinhalbmal so viele wie A. Dafür kündigen nur #proz(d4.varianten.B.precision, n: 0) der Angesprochenen, weit unter den 28 % der Kostenrechnung; die Kampagne verliert #eur(-d4.varianten.B.nutzen) je 1000 Kunden-Monate. Der Grund steht in der letzten Zeile der Ausgabe: Mit Gewichten liegt die mittlere vorhergesagte Wahrscheinlichkeit bei #zahl(d4.mittel_gew, n: 3), tatsächlich sind es #zahl(d4.basisrate, n: 3). Das Modell sagt nun nicht mehr „rund 5 von 100“, sondern im Mittel „39 von 100“. Die Zahlen sind verschoben, und die Kostenregel „ab 28 %“ ist auf ihnen sinnlos. Wer gewichtet, muss die Schwelle auf Validierungsdaten neu suchen (Variante E).

*Die Kostenregel genügt.* Das Modell ohne Gewichte liefert Wahrscheinlichkeiten, die zur Realität passen (#zahl(d4.mittel_plain, n: 3) gegenüber #zahl(d4.basisrate, n: 3)). Deshalb darf man die Schwelle aus der Wirtschaftlichkeit ableiten: Variante F spricht Kunden ab 28 % an und erzielt mit #eur(d4.varianten.F.nutzen) den höchsten Nutzen, ohne dass dafür etwas abgestimmt werden musste (die Unterschiede zu A und D sind klein und liegen im Bereich der Stichprobenschwankung). Die auf F1 optimierte Schwelle (D) hat einen höheren F1-Wert als A, aber kaum mehr Nutzen: F1 gewichtet Precision und Recall gleich, die Kasse tut das nicht.

#figure(
  {
    let farben = (blau, orange)
    daten-plot(size: (11, 5.4), x-label: [Recall], y-label: [Precision], x-min: 0, x-max: 1, y-min: 0, y-max: 1.02, x-tick-step: 0.2, y-tick-step: 0.2, {
      plot.add(d4.kurve_plain, style: (stroke: 1.4pt + blau), label: [ohne Gewichte])
      plot.add(d4.kurve_gew, style: (stroke: (paint: orange, thickness: 1.2pt, dash: "dashed")), label: [mit Klassengewichten])
      plot.add(((0, d4.basisrate), (1, d4.basisrate)), style: (stroke: (paint: luma(150), dash: "dotted", thickness: 1pt)), label: [Basisrate #proz(d4.basisrate)])
      for (k, farbe, name) in (("A", luma(80), [A: Schwelle 0,5]), ("B", orange, [B: Gewichte, Schwelle 0,5]), ("F", gruen, [F: Kostenregel])) {
        let v = d4.varianten.at(k)
        plot.add(((v.recall, v.precision),), mark: "o", mark-size: 0.22, style: (stroke: none), mark-style: (fill: farbe, stroke: none), label: name)
      }
    })
  },
  caption: [Precision-Recall-Kurven des Modells ohne und mit Klassengewichten (Testkunden). Die Kurven liegen fast aufeinander: Gewichte ändern die Rangfolge kaum. Die Punkte sind Betriebspunkte aus der Tabelle.],
) <abb-pr>

Für das System gilt ab hier Variante F: kein Gewicht, Schwelle aus der Kostenrechnung. Der Preis dafür ist eine Abhängigkeit, die man dokumentieren muss: Ändert sich der Wert eines Kunden oder der Preis des Angebots, ändert sich die Schwelle, ohne dass das Modell neu trainiert werden muss.

== Schritt 5: Vorverarbeitung gehört ins Modell (Transform)

Bisher hat das Notebook die Daten mit `pd.get_dummies` aufbereitet, auf der ganzen Tabelle. Jetzt soll das Modell in Betrieb gehen, und das Platform-Team schreibt einen Dienst, der jeden Monat alle Kunden bewertet. Dazu muss die Aufbereitung ein zweites Mal existieren, im Service. Das Pattern _Transform_ (Pattern 21) verlangt, dass sie nur einmal existiert, als Teil des Modells. In scikit-learn heißt das `Pipeline`:

#code-aus("modell.py", "def vorverarbeitung(", bis: "    ])")

Vier rechtsschiefe Spalten (`stunden`, `sessions`, `tage_seit_login`, `stunden_trend`) werden mit `log1p` gestaucht und dann standardisiert, die übrigen Zahlen nur standardisiert, die Kategorien one-hot kodiert, wobei `handle_unknown="ignore"` unbekannte Werte nicht abbrechen lässt, sondern als Nullen behandelt. Mittelwerte, Standardabweichungen und Kategorienlisten sind _gelernte_ Parameter und stecken im Artefakt. @abb-pipeline zeigt, wie dasselbe Objekt Training und Betrieb bedient; @abb-schiefe zeigt, was `log1p` mit einer der Spalten macht.

#figure(
  diagram(
    node-stroke: 0.7pt + luma(140), node-fill: luma(240), node-corner-radius: 3pt, node-inset: 6pt, spacing: (8mm, 5mm),
    {
      node((-0.7, 0.3), text(size: 9pt)[Trainings-\ kunden], name: <tr>)
      node((-0.7, 1.7), text(size: 9pt)[Anfrage \ (roh)], name: <an>)
      node((1, 0), text(size: 9pt)[`log1p` und \ Skalierung (4)], name: <a>)
      node((1, 1), text(size: 9pt)[Skalierung (6)], name: <b>)
      node((1, 2), text(size: 9pt)[One-Hot (4)], name: <c>)
      node((2, 1), text(size: 9pt)[Gradient \ Boosting], name: <m>)
      node((3, 1), text(size: 9pt)[Score], name: <sc>)
      node((1.5, -0.62), text(size: 9pt, fill: blau, weight: "bold")[Pipeline = ein Artefakt], name: <t>, stroke: none, fill: none)
      node(enclose: (<t>, <a>, <b>, <c>, <m>), stroke: 0.9pt + blau, fill: blau-hell.lighten(40%), inset: 8pt, corner-radius: 5pt, snap: false, name: <pipe>)
      edge(<tr>, <pipe>, "->", label: text(size: 8.5pt)[`fit`], label-side: left, label-pos: 0.5)
      edge(<an>, <pipe>, "->", label: text(size: 8.5pt)[`predict`], label-side: right, label-pos: 0.5)
      edge(<a>, <m>, "->")
      edge(<b>, <m>, "->")
      edge(<c>, <m>, "->")
      edge(<m>, <sc>, "->")
    },
  ),
  caption: [Eine Pipeline für beide Phasen. Beim Training (`fit`) lernt sie Parameter und Modell, im Betrieb (`predict`) wendet sie dieselben Parameter auf rohe Anfragen an. Die Zahlen in Klammern geben die Anzahl der Spalten an (Stand ab Schritt 6; in Schritt 5 kommen zwei Spalten zur Skalierung hinzu, die Schritt 6 entfernt).],
) <abb-pipeline>

#figure(
  {
    let n = d5.hist_roh.len()
    grid(columns: (1fr, 1fr), column-gutter: 6mm,
      daten-plot(size: (6.4, 3.0), x-label: [Stunden pro Monat (roh)], y-label: [Anteil der Zeilen], x-min: 0, x-max: 100, y-min: 0, y-max: 0.35, x-tick-step: 20, y-tick-step: 0.1,
        { plot.add-bar(d5.hist_roh.enumerate().map(((i, v)) => (i * 10 + 5, v)), bar-width: 9, style: (fill: orange, stroke: none)) }),
      daten-plot(size: (6.4, 3.0), x-label: [`log1p(stunden)`], y-label: none, x-min: 0, x-max: 5, y-min: 0, y-max: 0.35, x-tick-step: 1, y-tick-step: 0.1,
        { plot.add-bar(d5.hist_log.enumerate().map(((i, v)) => (i * 0.5 + 0.25, v)), bar-width: 0.46, style: (fill: gruen, stroke: none)) }),
    )
  },
  caption: [Die Stunden pro Monat vor und nach `log1p` (Testkunden; im linken Bild fasst der letzte Balken alle Werte ab 90 Stunden zusammen). Die Schiefe sinkt von #zahl(d5.schiefe_roh, n: 2) auf #zahl(d5.schiefe_log, n: 2).],
) <abb-schiefe>

#lauf("05_transform.py", "05_transform.txt")

Die Ausgabe zeigt zuerst, was die Transformation _nicht_ bringt: Das Gradient-Boosting-Modell verändert sich nicht (#zahl(d5.ap_hgb_roh, n: 3) ohne, #zahl(d5.ap_hgb_log, n: 3) mit `log1p`). Bäume schneiden Wertebereiche und kennen nur die Reihenfolge der Werte, jede monotone Umformung ist ihnen gleich. Auch die logistische Regression, die mit Größenordnungen rechnet, gewinnt nichts (#zahl(d5.ap_lr_roh, n: 3) ohne, #zahl(d5.ap_lr_log, n: 3) mit `log1p`). Die Pipeline lohnt sich also nicht wegen der Metrik, sondern wegen des Betriebs. (Die Zeile „Pipeline vs. Einzelaufruf“ der Ausgabe ist die Gegenprobe: Ruft man Vorverarbeitung und Modell einzeln auf, kommt dasselbe heraus wie aus der Pipeline, die größte Abweichung ist null.)

Das zeigt der zweite Teil. Ein Team, das die Vorverarbeitung nachbaut, kann die richtigen Mittelwerte und Standardabweichungen übernehmen und trotzdem `log1p` vergessen. Das Modell bekommt dann Eingaben, die nicht wie im Training aussehen, und antwortet ohne Fehlermeldung: Die PR-AUC fällt von #zahl(d5.ap_hgb_log, n: 3) auf #zahl(d5.ap_service, n: 3), und bei #proz(d5.flip, n: 0) der Zeilen kippt die Entscheidung. Das ist _Training-Serving Skew_ in Reinform. Die Pipeline schließt diese Fehlerklasse aus, weil es nur eine Implementierung gibt. Der letzte Teil der Ausgabe zeigt eine zweite Klasse: Taucht in Monat 16 der neue Tarif _mobil_ auf, liefert die Pipeline weiter Werte, während der Notebook-Weg mit `get_dummies` mit einem `ValueError` abbricht. Der Abbruch ist laut, die Pipeline leise; Schritt 8 zeigt, dass auch „ignorieren“ seinen Preis hat.

== Schritt 6: Warum steht dieser Kunde auf der Liste? (Explainable Predictions)

Das Retention-Team stellt zwei Fragen. Die erste ist global: Woran erkennt das Modell Abwanderer, und passt das zu dem, was das Team über seine Kunden weiß? Die zweite ist lokal: Warum steht ausgerechnet dieser Kunde auf der Liste, und was soll das Angebot sagen? Beides beantwortet das Pattern _Explainable Predictions_ (Pattern 29) mit zwei Werkzeugen (`06_erklaerung.py`).

*Global: Permutation Importance.* Man mischt auf den Testdaten die Werte einer Spalte zufällig durcheinander und misst, wie stark die PR-AUC sinkt. Eine Spalte, auf die sich das Modell stützt, hinterlässt eine Lücke; eine ignorierte Spalte nicht (@abb-perm). Das Ergebnis ist plausibel: Wer lange nicht eingeloggt war (`tage_seit_login`) und weniger schaut als sonst (`stunden_trend`), ist gefährdet. Dahinter folgen die Dauer der Kundenbeziehung, der Kanal (Aktionskunden mit ihrem Preissprung nach drei Monaten), offene Supportfälle und das Alter. Dass `stunden` und `sessions` kaum zählen, heißt nicht, dass sie unwichtig sind: Sie sind mit Trend und Login korreliert, und bei korrelierten Spalten kann die Methode jede einzelne unterschätzen (siehe Pattern 29).

#figure(
  canvas(length: 1cm, {
    import draw: *
    let r = d6.rang.slice(0, 8)
    let skala = 8.2 / 0.17
    for (i, z) in r.enumerate() {
      let y = -i * 0.55
      content((-0.15, y), anchor: "east", text(size: 9pt, raw(z.merkmal)))
      rect((0, y - 0.17), (z.abfall * skala, y + 0.17), fill: blau.lighten(20%), stroke: none)
      line(((z.abfall - z.streuung) * skala, y), ((z.abfall + z.streuung) * skala, y), stroke: 0.9pt + luma(60))
      content((calc.max(z.abfall + z.streuung, 0) * skala + 0.15, y), anchor: "west", text(size: 8.5pt)[#zahl(z.abfall, n: 3)])
    }
    line((0, 0.35), (0, -7 * 0.55 - 0.35), stroke: 0.6pt)
  }),
  caption: [Permutation Importance des Modells (Testkunden): Abfall der PR-AUC beim Durchmischen der Spalte, die acht wichtigsten Spalten. Die dünnen Linien zeigen die Streuung über fünf Wiederholungen.],
) <abb-perm>

*Debugging.* Die Erklärung hat noch eine zweite, unspektakuläre Aufgabe. Das Modell aus Schritt 5 enthielt `anmeldetag` und `bandbreite_mbit`, die Fingerabdruck-Spalten aus Schritt 3. Ihre Wichtigkeit ist winzig (#zahl(d6.rang0.find(z => z.merkmal == "anmeldetag").abfall, n: 4) und #zahl(d6.rang0.find(z => z.merkmal == "bandbreite_mbit").abfall, n: 4)), und ohne sie ändert sich die PR-AUC nicht (#zahl(d6.ap0, n: 3) mit, #zahl(d6.ap1, n: 3) ohne). Eine Spalte, die für jeden Kunden konstant ist und keinen fachlichen Bezug zur Kündigung hat, kann nichts verallgemeinern, sondern nur Kunden wiedererkennen. Sie fliegt raus, bevor ein späterer Split sie wieder zum Leck macht; die weiteren Schritte verwenden das Modell ohne sie (`modell_v1.joblib`).

*Lokal: Beiträge für einen Kunden.* Für die einzelne Entscheidung braucht es eine Zerlegung der Vorhersage auf die Merkmale. Der exakte Weg über alle 2#super[14] = 16 384 Teilmengen von 14 Merkmalen wäre je Kunde sehr aufwendig; das Skript schätzt die Shapley-Werte stattdessen durch Stichproben (Vorgehen nach #cite(<strumbelj_explaining_2014>, form: "prose")). Es zieht für jede Reihenfolge eine zufällige Zeile aus 2000 Trainingszeilen als Hintergrund und ersetzt deren Merkmale in zufälliger Reihenfolge nacheinander durch die des zu erklärenden Kunden. Der Sprung der Vorhersage bei jedem Ersetzen wird dem Merkmal gutgeschrieben; über 400 Reihenfolgen ergibt sich der Mittelwert. Die Beiträge summieren sich so exakt zur Differenz zwischen der Vorhersage für den Kunden und dem Mittel der Hintergrundkunden, wie die Zeile „Summe der Beiträge“ in der Ausgabe zeigt. Die Spalte `andere_ziehung` wiederholt die Schätzung mit anderen Zufallszahlen; die sieben gezeigten Werte weichen um höchstens 0,02 voneinander ab, die Rangfolge ändert sich nicht.

#code-aus("06_erklaerung.py", "def shapley_lokal", bis: "return phi")

#lauf("06_erklaerung.py", "06_erklaerung.txt")

#figure(
  {
    let f = d6.fall
    let top = f.beitraege.slice(0, 6)
    let rest = f.beitraege.slice(6).map(z => z.beitrag).sum()
    let skala = 9.0 / 0.7
    canvas(length: 1cm, {
      import draw: *
      let zeile(i, name, lo, hi, farbe, beschr) = {
        let y = -i * 0.55
        content((-0.15, y), anchor: "east", name)
        rect((lo * skala, y - 0.17), (hi * skala, y + 0.17), fill: farbe.lighten(35%), stroke: 0.8pt + farbe)
        content((hi * skala + 0.15, y), anchor: "west", text(size: 8.5pt, beschr))
      }
      zeile(0, text(size: 9pt)[Basis (Hintergrund)], 0, f.basis, blau, [#zahl(f.basis, n: 3)])
      let stand = f.basis
      for (i, z) in top.enumerate() {
        let neu = stand + z.beitrag
        zeile(i + 1, text(size: 9pt)[#raw(z.merkmal) = #z.wert.replace(".", ",")], calc.min(stand, neu), calc.max(stand, neu), if z.beitrag >= 0 { orange } else { gruen }, [#(if z.beitrag >= 0 { "+" } else { "−" })#zahl(calc.abs(z.beitrag), n: 3)])
        stand = neu
      }
      let neu = stand + rest
      zeile(7, text(size: 9pt)[übrige 8 Merkmale], calc.min(stand, neu), calc.max(stand, neu), luma(130), [#(if rest >= 0 { "+" } else { "−" })#zahl(calc.abs(rest), n: 3)])
      zeile(8, text(size: 9pt, weight: "bold")[Vorhersage], 0, f.vorhersage, blau, [#zahl(f.vorhersage, n: 3)])
      line((0, 0.35), (0, -8 * 0.55 - 0.35), stroke: 0.6pt)
    })
  },
  caption: [Beiträge der Merkmale zur Vorhersage für Kunde #d6.fall.id in Monat #d6.fall.monat (Altersgruppe #d6.fall.gruppe, ein Abwanderer, den das Modell markiert). Orange erhöht das Risiko gegenüber dem Hintergrund, grün senkt es. Werte aus der Ausgabe oben.],
) <abb-waterfall>

Für das Retention-Team lässt sich das in einen Satz übersetzen: Dieser Kunde hat im letzten Monat nur #zahl(float(d6.fall.beitraege.find(z => z.merkmal == "stunden_trend").wert) * 100, n: 0) % der Stunden geschaut, die er im Schnitt der drei Vormonate geschaut hatte, war vor #d6.fall.beitraege.find(z => z.merkmal == "tage_seit_login").wert Tagen zuletzt im Dienst und hat sich in den letzten 30 Tagen an den Support gewandt; dazu kommt, dass er über eine Aktion gewonnen wurde. Das ist ein Anlass für ein Gespräch statt eines Pauschalrabatts. Die Grenzen sind die bekannten: Die Erklärung beschreibt das _Modell_, nicht die Kündigungsgründe des Kunden; sie hängt vom Hintergrund ab, und weil Merkmale einzeln ausgetauscht werden, bildet sie auch Kombinationen, die es in Wirklichkeit nicht gibt. Als Gesprächsanlass ist sie wertvoll, als Kausalaussage nicht.

== Schritt 7: Für wen funktioniert das Modell? (Fairness Lens)

Bis hierher stand pro Kennzahl nur eine Zahl in der Tabelle, ein Durchschnitt über alle. Ein Durchschnitt kann ein Loch verbergen. Die _Fairness Lens_ (Pattern 30) wertet dieselben Kennzahlen getrennt nach Gruppen aus, hier nach Altersgruppe: Das Alter ist ein Merkmal des Modells und spielt in der Kundenansprache eine nachvollziehbare Rolle. Zuerst die Auswertung mit einer Schwelle für alle, dann eine Gegenmaßnahme: Gruppen, deren Recall auf den Validierungsdaten unter dem Gesamtwert liegt, bekommen eine niedrigere Schwelle, alle anderen behalten die gemeinsame.

#code-aus("07_fairness.py", "ziel_recall = ", bis: "if kennzahlen(z[ZIEL], z.p, s)")

#lauf("07_fairness.py", "07_fairness.txt")

Die erste Tabelle zeigt ein deutliches Bild. Bei den Kunden ab 55 findet das Modell nur #proz(d7.vorher.at(3).recall, n: 0) der Abwanderer, bei den anderen Gruppen zwischen #proz(calc.min(d7.vorher.at(0).recall, d7.vorher.at(1).recall, d7.vorher.at(2).recall), n: 0) und #proz(calc.max(d7.vorher.at(0).recall, d7.vorher.at(1).recall, d7.vorher.at(2).recall), n: 0). Die Gruppe wird nur zu #proz(d7.vorher.at(3).markiert) angesprochen (die anderen zu #proz(calc.min(..d7.vorher.slice(0, 3).map(z => z.markiert))) bis #proz(calc.max(..d7.vorher.slice(0, 3).map(z => z.markiert)))), obwohl ihre tatsächliche Abwanderungsquote mit #proz(d7.vorher.at(3).basisrate) sogar leicht über dem Durchschnitt von #proz(d7.vorher.at(4).basisrate) liegt. Weil die Daten simuliert sind, kennen wir die Ursache: In `daten.py` verändern Kunden ab 55 ihre Nutzung vor einer Kündigung nur etwa ein Drittel so stark wie die übrigen. Ein Modell, das fast nur auf Nutzungsrückgänge schaut, hat bei ihnen keine Chance. In echten Daten müsste man diese Ursache erst suchen.

Welches Kriterium ist das richtige? Man fragt nach dem Schaden. Ein Halteangebot ist ein Vorteil, und übersehen zu werden ist der Nachteil, den man vermeiden will. Das spricht für _Equal Opportunity_ nach #cite(<hardt_equality_of_opportunity_2016>, form: "prose"): Von allen, die tatsächlich kündigen, soll jede Gruppe gleich viele erreichen. Die zweite Tabelle zeigt den Preis. Der Recall der Gruppe ab 55 steigt von #proz(d7.vorher.at(3).recall, n: 0) auf #proz(d7.nachher.at(3).recall, n: 0), aber ihre Precision fällt von #proz(d7.vorher.at(3).precision, n: 0) auf #proz(d7.nachher.at(3).precision, n: 0): Weniger als jedes fünfte Angebot erreicht einen Abwanderer. Das liegt unter der Rentabilitätsschwelle von 28 %, die Kampagne verliert in dieser Gruppe #eur(-d7.nachher.at(3).nutzen) je 1000 Kunden-Monate, und der Gesamtnutzen sinkt von #eur(d7.vorher.at(4).nutzen) auf #eur(d7.nachher.at(4).nutzen), also um #proz(1 - d7.nachher.at(4).nutzen / d7.vorher.at(4).nutzen, n: 0). Auch die 18- bis 24-Jährigen bekommen eine niedrigere Schwelle (#zahl(d7.schwellen.at("18-24"), n: 2)), weil ihr Recall auf den Validierungsdaten mit #proz(d7.val_recall.at("18-24"), n: 0) unter dem Ziel von #proz(d7.ziel_recall, n: 0) lag. Auf den Testdaten lag er mit #proz(d7.vorher.at(0).recall, n: 0) schon vorher darüber: Das Verfahren folgt hier der Zufallsschwankung der Validierung, und die Gruppe zahlt dafür (Precision #proz(d7.vorher.at(0).precision, n: 0) auf #proz(d7.nachher.at(0).precision, n: 0), Nutzen #eur(d7.vorher.at(0).nutzen) auf #eur(d7.nachher.at(0).nutzen)). Das spricht dafür, Schwellen je Gruppe nur bei deutlichen Abständen anzupassen.

#figure(
  {
    let gruppen = ("18-24", "25-39", "40-54", "55+")
    canvas(length: 1cm, {
      import draw: *
      let skala = 3.4 / 0.35
      for (i, g) in gruppen.enumerate() {
        let x = i * 3.0
        for (k, (reihe, farbe)) in ((d7.vorher, luma(150)), (d7.nachher, blau)).enumerate() {
          let v = reihe.at(i).recall
          rect((x + k * 1.05, 0), (x + k * 1.05 + 0.95, v * skala), fill: farbe.lighten(20%), stroke: none)
          content((x + k * 1.05 + 0.475, v * skala + 0.25), text(size: 8.5pt)[#proz(v, n: 0)])
        }
        content((x + 1.0, -0.4), text(size: 9pt)[#g])
      }
      line((-0.3, 0), (11.6, 0), stroke: 0.6pt)
      let gesamt = d7.vorher.at(4).recall * skala
      line((-0.3, gesamt), (11.6, gesamt), stroke: (paint: orange, dash: "dashed", thickness: 0.9pt))
      line((8.3, -0.92), (8.8, -0.92), stroke: (paint: orange, dash: "dashed", thickness: 0.9pt))
      content((8.9, -0.92), anchor: "west", text(size: 8.5pt)[Gesamt-Recall (eine Schwelle)])
      rect((0, -1.05), (0.3, -0.8), fill: luma(150).lighten(20%), stroke: none)
      content((0.4, -0.92), anchor: "west", text(size: 8.5pt)[eine Schwelle für alle])
      rect((4.2, -1.05), (4.5, -0.8), fill: blau.lighten(20%), stroke: none)
      content((4.6, -0.92), anchor: "west", text(size: 8.5pt)[Schwelle je Gruppe])
    })
  },
  caption: [Recall je Altersgruppe auf den Testkunden, vor und nach der gruppenspezifischen Schwelle. Orange gestrichelt: Gesamt-Recall mit einer gemeinsamen Schwelle.],
) <abb-fairness>

Ob man diese Rechnung bezahlen will, ist keine Frage für das Data-Science-Team allein. Vertretbar sind drei Antworten: die Unterschiede dokumentieren und akzeptieren, die Schwelle je Gruppe verwenden und die Kosten bewusst tragen, oder die Ursache beheben, indem man Merkmale findet, die Kündigungen dieser Gruppe ankündigen (etwa Zahlungsereignisse oder die Nutzung am Fernseher statt in der App). Die dritte ist die beste, aber nicht die schnellste. Ob die Verwendung des Alters für Entscheidungsschwellen zulässig ist, ist keine ML-Frage, sondern eine rechtliche, und bleibt hier offen. Gleichstellen lässt sich außerdem nicht alles: Bei unterschiedlichen Basisraten lassen sich gleiche Precision, gleicher Recall und gleiche Rate falscher Alarme im Allgemeinen nicht gleichzeitig erreichen, wie #cite(<chouldechova_fair_prediction_2017>, form: "prose") gezeigt hat; #cite(<kleinberg_inherent_2016>, form: "prose") kommen für Risikoscores zu einem verwandten Ergebnis. In jedem Fall gehört das Ergebnis in die Dokumentation des Modells, die _Model Card_ nach #cite(<mitchell_model_cards_2019>, form: "prose").

== Schritt 8: Das Modell im Betrieb (Continued Model Evaluation)

Das Modell geht in Monat 13 in den Betrieb. Jeden Monatsanfang bewertet ein Batch-Job alle aktiven Kunden (Pattern 17), das Retention-Team erhält die Liste. Was fehlt, ist die Antwort auf die Frage „Funktioniert es noch?“, und die ist hier schwerer als üblich, weil die Wahrheit mit Verzögerung eintrifft: Den Recall der Zeilen aus Monat _m_ kennt man erst in Monat _m_ + 3. Das Pattern _Continued Model Evaluation_ (Pattern 18) unterscheidet deshalb zwei Wege. Eingaben und Vorhersagen lassen sich sofort überwachen, die Qualität nur gegen die später bekannten Ziele. `08_monitoring.py` wertet beides für die Monate 13 bis 20 aus, ausschließlich auf Testkunden, die das Modell nie gesehen hat. Die Verschiebung einer Verteilung misst der _Population Stability Index_ (PSI) mit der verbreiteten Faustregel 0,25 als Alarmschwelle (sie stammt aus der Kreditrisikomodellierung und hat keine theoretische Begründung).

#code-aus("08_monitoring.py", "def psi(", bis: "return float")

#figure(
  {
    let m = d8.monate
    let linie(feld, farbe, name, dash: "solid") = plot.add(m.map(z => (z.monat, z.at(feld))), style: (stroke: (paint: farbe, thickness: 1.3pt, dash: dash)), mark: "o", mark-size: 0.1, mark-style: (fill: farbe, stroke: none), label: name)
    stack(spacing: 4mm,
      daten-plot(size: (12, 3.0), x-label: none, y-label: [Kennzahl], x-min: 12.7, x-max: 20.3, x-tick-step: 1, y-min: 0, y-max: 1.0, y-tick-step: 0.25, legend: "inner-north-west", {
        linie("precision", gruen, [Precision])
        linie("ap", blau, [PR-AUC])
        linie("recall", orange, [Recall])
        plot.add-vline(d8.drift_ab, style: (stroke: (paint: luma(120), dash: "dotted")))
      }),
      daten-plot(size: (12, 2.8), x-label: [Monat der Zeile], y-label: [PSI], x-min: 12.7, x-max: 20.3, x-tick-step: 1, y-min: 0, y-max: 0.75, y-tick-step: 0.25, legend: "inner-north-west", {
        linie("psi_tarif", blau, [PSI `tarif`])
        linie("psi_score", gruen, [PSI Score])
        plot.add-hline(0.25, style: (stroke: (paint: orange, dash: "dashed", thickness: 1pt)))
        plot.add-vline(d8.drift_ab, style: (stroke: (paint: luma(120), dash: "dotted")))
      }),
    )
  },
  caption: [Modell v1 im Betrieb (Testkunden). Oben: Precision, PR-AUC und Recall bei Schwelle 0,28 je Zeilenmonat. Unten: PSI des Tarifs und der Modellausgabe gegenüber den Validierungskunden; orange gestrichelt die Faustregel 0,25. Der PSI des Preises (#zahl(d8.monate.at(3).psi_preis, n: 1) bis #zahl(d8.monate.at(7).psi_preis, n: 1) ab Monat 16) liegt weit über dem Bild und ist nicht eingezeichnet. Gepunktet: Monat 16.],
) <abb-monitoring>

#lauf("08_monitoring.py", "08_monitoring.txt")

*Die Eingaben schlagen sofort an, die Ausgabe nie.* Der PSI des Preises springt in Monat 16 auf #zahl(d8.monate.at(3).psi_preis, n: 1), denn die Preiserhöhung verschiebt die Verteilung auf einen Schlag. Der PSI des Tarifs wächst schleichend (#zahl(d8.monate.at(3).psi_tarif, n: 2) in Monat 16, #zahl(d8.monate.at(7).psi_tarif, n: 2) in Monat 20) und überschreitet die Schwelle von 0,25 erst in Monat #d8.monate.find(z => z.psi_tarif > 0.25).monat, weil Neukunden den Tarif _mobil_ wählen, den das Modell nie gesehen hat. Die Verteilung der Scores bleibt bei höchstens #zahl(calc.max(..d8.monate.map(z => z.psi_score)), n: 2). Wer nur die Ausgabe überwacht, merkt nichts. Die Pipeline verarbeitet den unbekannten Tarif ohne Fehler (`handle_unknown="ignore"`), das Modell rechnet mit lauter Nullen in den Tarif-Spalten. Das ist bequem und verdeckt, dass etwas Neues im System ist.

*Die Qualität sinkt, aber nicht dort, wo man zuerst schaut.* Die Precision bleibt zwischen #zahl(calc.min(..d8.monate.map(z => z.precision)), n: 2) und #zahl(calc.max(..d8.monate.map(z => z.precision)), n: 2): Was das Modell meldet, stimmt weiter. Die PR-AUC fällt von #zahl(d8.monate.at(0).ap, n: 2) in Monat 13 auf #zahl(calc.min(..d8.monate.map(z => z.ap)), n: 2) bis #zahl(calc.max(..d8.monate.slice(1).map(z => z.ap)), n: 2) in den späteren Monaten, bleibt aber weit über der Basisrate von #proz(calc.min(..d8.monate.slice(3).map(z => z.basisrate)), n: 0) bis #proz(calc.max(..d8.monate.slice(3).map(z => z.basisrate)), n: 0): Die Rangfolge der Kunden taugt weiter. Der Recall dagegen fällt von #proz(d8.monate.at(0).recall, n: 0) in Monat 13 auf #proz(d8.monate.at(3).recall, n: 0) in Monat 16. Die Abwanderungsquote hat sich mehr als verdoppelt (#proz(d8.monate.at(0).basisrate) auf #proz(d8.monate.at(3).basisrate)), aber die zusätzlichen Kündigungen kommen von Kunden der Tarife standard und premium, die auf die Preiserhöhung reagieren (in `daten.py` ein nicht sichtbarer Teil von ihnen, dazu ältere Kunden), und ihre Nutzung nimmt vorher nicht ab. Das Modell sieht sie nicht. Der Nutzen der Kampagne bleibt dabei bei #eur(calc.min(..d8.monate.map(z => z.nutzen))) bis #eur(calc.max(..d8.monate.map(z => z.nutzen))) je 1000 Kunden-Monate, weil er nur die Angesprochenen zählt: Die Zahl der gefundenen Abwanderer je 1000 Zeilen liegt in allen Monaten zwischen #zahl(calc.min(..d8.monate.map(z => z.recall * z.basisrate * 1000)), n: 0) und #zahl(calc.max(..d8.monate.map(z => z.recall * z.basisrate * 1000)), n: 0), während es mehr Abwanderer gibt. Das Modell findet ähnlich viele und übersieht mehr. Eine Kennzahl, die nur das Erreichte misst, kann das Verpasste nicht sehen. Dass schon die Zeilen aus den Monaten 14 und 15 mehr Abwanderer enthalten, liegt am Horizont: Ihre Ziele reichen bis in die Monate 16 und 17.

*Der Alarm kommt drei Monate vor dem Beweis.* Der Preis-PSI schlägt in Monat 16 an, den Recall dieses Monats kennt man erst in Monat 19. Dazwischen weiß man, dass sich etwas geändert hat, aber nicht, ob es dem Modell schadet. Die Eingabeüberwachung löst also eine Untersuchung aus, kein automatisches Retraining.

*Neu trainieren hilft hier nur wenig.* In Monat 20 sind die Ziele aller Zeilen bis Monat 17 bekannt. Das Modell v2 wird auf den Monaten 8 bis 17 der Trainingskunden gelernt und mit v1 auf den Monaten 18 bis 20 der Testkunden verglichen. v2 findet etwas mehr Abwanderer (Recall #proz(d8.vergleich.at(0).recall, n: 0) auf #proz(d8.vergleich.at(1).recall, n: 0)), verliert dafür Precision (#proz(d8.vergleich.at(0).precision, n: 0) auf #proz(d8.vergleich.at(1).precision, n: 0)), und der Nutzen bleibt praktisch gleich (#eur(d8.vergleich.at(0).nutzen) gegenüber #eur(d8.vergleich.at(1).nutzen)). Preisempfindlichkeit ist kein Merkmal der Tabelle, und ein Retraining kann keine Information erzeugen, die nicht in den Spalten steckt. Die Antwort auf diesen Alarm liegt eher bei den Daten und der Fachseite: ein Merkmal für die Reaktion auf Preisankündigungen oder eine gezielte Aktion rund um Preisänderungen. Auch die Fenstergröße des Retrainings (hier zehn Zeilenmonate, davon nur zwei ab dem Preissprung) ist eine eigene Entscheidung.

== Das fertige System

Aus den acht Schritten ist ein System geworden, dessen Teile jeweils einem Pattern entsprechen (@abb-system). Der monatliche Ablauf ist ein Workflow (Pattern 25): Features berechnen, mit dem versionierten Pipeline-Artefakt (Pattern 27, 21) alle aktiven Kunden im Batch bewerten (Pattern 17), mit der Kostenschwelle (Pattern 10) eine Liste erzeugen und jedem Kunden darauf die drei wichtigsten Beiträge mitgeben (Pattern 29). Darunter läuft die Überwachung: PSI auf den Eingaben sofort, Recall und Precision je Altersgruppe (Pattern 30) mit drei Monaten Verzögerung. Der Heuristic Benchmark (Pattern 28) ist Teil des Freigabetests: Ein neues Modell sollte nur live gehen, wenn es auf den Hash-getrennten Testkunden (Pattern 22) die Faustregel und das Vorgängermodell schlägt. Die Skripte führen die Teile einzeln vor; die Verkettung zu einem Monatsjob und der Freigabetest sind Entwurf und nicht als Code ausgeführt. Einen Feature Store (Pattern 26) gibt es nicht; bei einem Monatsjob mit einer Quelle wäre er Aufwand ohne Nutzen.

#figure(
  diagram(
    node-stroke: 0.7pt + luma(140), node-fill: luma(240), node-corner-radius: 3pt, node-inset: 4pt, node-shape: rect, spacing: (5mm, 8mm),
    {
      let k(pos, titel, pat, ..a) = node(pos, box(width: 25mm, align(center, { set par(justify: false); set text(hyphenate: false);  [#text(size: 8pt, weight: "bold", titel) \ #text(size: 7pt, fill: grau, pat)] })), ..a)
      k((0, 0), [Abrechnung, Events, Support], [Quellen])
      k((1, 0), [Features je Kunde und Monat], [25 Workflow Pipeline])
      k((2, 0), [Pipeline-Artefakt `modell_v1`], [21 Transform, 27 Model Versioning], fill: blau-hell, stroke: 0.9pt + blau)
      k((3, 0), [Scores und Top-3-Gründe], [17 Batch Serving, 29 Explainable], fill: blau-hell, stroke: 0.9pt + blau)
      k((4, 0), [Retention-Team, Schwelle 28 %], [10 Rebalancing], fill: rgb("#E1F3EB"), stroke: 0.9pt + gruen)
      k((1, 1), [PSI auf den Eingaben], [18 Continued Evaluation])
      k((2, 1), [Freigabetest: schlägt Faustregel und Vorgänger?], [28 Benchmark, 22 Splitting])
      k((3, 1), [Ziele nach drei Monaten], [18 Continued Evaluation])
      k((1, 2), [Alarm, Untersuchung, Retraining], [27 Model Versioning], fill: rgb("#FBF1E6"), stroke: 0.9pt + orange)
      k((2, 2), [Recall und Precision je Altersgruppe], [30 Fairness Lens])
      edge((0, 0), (1, 0), "->")
      edge((1, 0), (2, 0), "->")
      edge((2, 0), (3, 0), "->")
      edge((3, 0), (4, 0), "->")
      edge((1, 0), (1, 1), "->")
      edge((3, 0), (3, 1), "->")
      edge((2, 1), (2, 0), "->", stroke: (dash: "dashed", paint: luma(110)))
      edge((1, 1), (1, 2), "->")
      edge((3, 1), (2, 2), "->")
      edge((2, 2), (1, 2), "->")
    },
  ),
  caption: [Architektur des Systems. Oben der monatliche Ablauf, darunter die Überwachung und der Freigabetest (gestrichelt). Die Zahlen nennen das jeweilige Pattern.],
) <abb-system>

Zum Abschluss die Bilanz aller Schritte. Sie zeigt, dass die Schritte unterschiedliche Größen verbessern und dass die „ehrlichste“ Verbesserung einmal eine schlechtere Zahl war.

#show figure.where(kind: table): set block(breakable: true)
#figure(
  table(columns: (auto, auto, 1fr, auto, auto), align: (left, left, left, right, right), inset: (x: 0.5em, y: 0.4em),
    table.header[Schritt][Pattern][Metrik][vorher][nachher],
    [1], [28], [Ranking nach Login-Tagen (PR-AUC); Nutzen der Regel], [#zahl(d1.basisrate, n: 3) (Zufall)], [#zahl(d1.ap_login, n: 3) und #eur(d1.regel.nutzen)],
    [2], [–], [PR-AUC des Notebooks, Zeilen-Split], [#zahl(d1.ap_login, n: 3)], [#zahl(d2.ap, n: 3)],
    [3], [22], [PR-AUC, dasselbe Modell ehrlich gemessen], [#zahl(d3.ergebnis.gross.zeilen.ap, n: 3)], [#zahl(d3.ergebnis.gross.kunden.ap, n: 3)],
    [3], [22], [PR-AUC nach Modellwahl (Test)], [#zahl(d3.ergebnis.gross.kunden.ap, n: 3)], [#zahl(d3.ergebnis.klein.kunden.ap, n: 3)],
    [4], [10], [Nutzen je 1000 Kunden-Monate (Recall)], [#eur(d4.varianten.A.nutzen) (#zahl(d4.varianten.A.recall, n: 2))], [#eur(d4.varianten.F.nutzen) (#zahl(d4.varianten.F.recall, n: 2))],
    [5], [21], [PR-AUC, Service-Nachbau ohne `log1p`], [#zahl(d5.ap_service, n: 3)], [#zahl(d5.ap_hgb_log, n: 3)],
    [6], [29], [PR-AUC ohne Fingerabdruck-Spalten], [#zahl(d6.ap0, n: 3)], [#zahl(d6.ap1, n: 3)],
    [7], [30], [Recall ab 55 (Gesamtnutzen)], [#zahl(d7.vorher.at(3).recall, n: 2) (#eur(d7.vorher.at(4).nutzen))], [#zahl(d7.nachher.at(3).recall, n: 2) (#eur(d7.nachher.at(4).nutzen))],
    [8], [18], [Recall v1, Monat 13 und 16], [#zahl(d8.monate.at(0).recall, n: 2)], [#zahl(d8.monate.at(3).recall, n: 2)],
    [8], [18], [Recall v1 und v2, Monate 18 bis 20], [#zahl(d8.vergleich.at(0).recall, n: 2)], [#zahl(d8.vergleich.at(1).recall, n: 2)],
  ),
  caption: [Schritt, Pattern, Metrik und Zahlen vor und nach dem Schritt (alle aus den Ausgaben der Skripte). Die Zeile zu Schritt 3 zeigt, dass der Schritt eine Zahl _verschlechtert_ und das Ergebnis dadurch wahrer macht; Schritt 8 beschreibt eine Verschlechterung im Betrieb und einen schwachen Gegenzug.],
) <abb-bilanz>

== Das Wichtigste in Kürze

- Ein Projekt beginnt mit einem Vergleichsmaßstab. Die Faustregel kostete eine Zeile Code und zeigte, dass Genauigkeit bei einer Quote von #proz(d1.basisrate, n: 0) nichts aussagt und eine Kampagne mit zu geringer Precision Geld verliert.
- Zeilen desselben Kunden sind keine unabhängigen Beispiele. Ein Split nach Zeilen lässt ein großes Modell Kunden wiedererkennen, bläht die PR-AUC von #zahl(d3.ergebnis.gross.kunden.ap, n: 2) auf #zahl(d3.ergebnis.gross.zeilen.ap, n: 2) auf und wählt das falsche Modell. Der Hash der Kunden-ID trennt sauber und bleibt stabil, wenn Daten dazukommen.
- Gewichte, Downsampling und Schwelle ändern vor allem die Entscheidung, nicht die Rangfolge. Mit Gewichten stimmen die Wahrscheinlichkeiten nicht mehr, und eine Schwelle aus Kosten ist nur ohne sie zulässig.
- Die Vorverarbeitung gehört ins Modell. Ein Nachbau, der `log1p` vergisst, senkt die PR-AUC von #zahl(d5.ap_hgb_log, n: 2) auf #zahl(d5.ap_service, n: 2), ohne eine Fehlermeldung zu erzeugen.
- Erklärungen helfen beim Debuggen und im Gespräch, sie sind keine Kausalaussagen. Gruppenauswertungen zeigen Löcher, die Durchschnitte verdecken; sie zu schließen kostet Geld, das jemand entscheiden muss.
- Im Betrieb schlagen Eingaben sofort an, Qualitätsmaße mit Verzögerung. Ein Alarm ist ein Anlass zur Untersuchung, und ob Retraining hilft, hängt davon ab, ob die fehlende Information in den Spalten steckt.

*Grenzen der Fallstudie.* Die Daten sind simuliert, und viele Effekte (die Fingerabdruck-Spalten, die „leisen“ Kündigungen ab 55, die Preisempfindlichkeit) sind so gebaut, dass sie sichtbar werden. In echten Projekten sind sie kleiner und vermischter. Die Zahlen für Angebotskosten, Erfolgsquote und Kundenwert sind angenommen. Das Kostenmodell zählt jede Zeile als eigenen Kontakt; dass derselbe Kunde in drei aufeinanderfolgenden Monaten angesprochen würde, ist nicht modelliert. Alle Zahlen stammen aus einem Lauf mit festem Seed. Schwankungen zwischen Läufen wurden nicht gemessen, kleine Unterschiede (etwa zwischen den Varianten A, D und F) sind deshalb nicht belegt. Die Beispiele sind je Schritt mit einem Modell und einer Metrik gerechnet; weder wurden Hyperparameter systematisch gesucht noch Alternativen wie eine Überlebenszeitanalyse geprüft, die für Kündigungen oft die natürlichere Formulierung ist.

#so-erklaere-ich-es(
  [Ich lasse die Studierenden die Schritte in der Reihenfolge erleben und halte vor jedem Schritt an: „Welche Zahl würden Sie jetzt glauben?“ Der stärkste Moment ist Schritt 3: Dasselbe Modell auf denselben Daten verliert durch eine andere Trennlinie ein Drittel seiner PR-AUC. Danach lasse ich sie erklären, warum das große Modell auf dem Zeilen-Split gewinnt und auf dem Kunden-Split nicht.],
  [Ein Modell zeigt auf den Testdaten eine PR-AUC von 0,39, aber im Betrieb nur 0,26. Nennen Sie zwei mögliche Ursachen, die nichts mit dem Modell selbst zu tun haben.],
  [Erstens ein Split, der Zeilen desselben Kunden auf Training und Test verteilt (Leck durch zusammengehörige Zeilen). Zweitens ein Unterschied zwischen Aufbereitung im Training und im Betrieb (Training-Serving Skew). Drittens eine Veränderung der Welt, die im Test noch nicht vorkam, oder eine andere Basisrate im Betrieb, die die PR-AUC allein schon verschiebt.],
)

*Quellen und weiterführende Literatur.* Die Patterns stammen aus #cite(<lakshmanan_ml_design_patterns_2020>, form: "prose") (Kapitel 3: Pattern 10; Kapitel 5: 17 und 18; Kapitel 6: 21, 22 und 25 bis 27; Kapitel 7: 28 bis 30). Leckagen (Leakage) behandeln #cite(<kaufman_leakage_2012>, form: "prose") mit Beispielen aus Data-Mining-Wettbewerben; die Wahl zwischen ROC- und PR-Kurve bei unausgewogenen Daten begründen #cite(<saito_precision_recall_2015>, form: "prose"), die Herleitung von Entscheidungsregeln aus Kosten #cite(<elkan_cost_sensitive_2001>, form: "prose"). Zu Shapley-Beiträgen siehe #cite(<lundberg_shap_2017>, form: "prose") und #cite(<strumbelj_explaining_2014>, form: "prose"). Die Permutation Importance stammt von #cite(<breiman_random_forests_2001>, form: "prose") (für Random Forests), #cite(<fisher_model_reliance_2019>, form: "prose") verallgemeinern sie auf beliebige Modelle. Zur Gruppenfairness siehe #cite(<hardt_equality_of_opportunity_2016>, form: "prose"), #cite(<kleinberg_inherent_2016>, form: "prose") und #cite(<chouldechova_fair_prediction_2017>, form: "prose"), zum Betrieb #cite(<sculley_hidden_debt_2015>, form: "prose") und die Prüfliste von #cite(<breck_ml_test_score_2017>, form: "prose"), zu den Arten von Drift #cite(<gama_concept_drift_2014>, form: "prose").

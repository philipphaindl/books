// Design-Bibliothek für "LLMs in der Forschung von Grund auf".
// Stil der Reihe "Documents/Sources/books" (Inter + JetBrains Mono, Akzent orange, Callouts mit Seitenbalken).
// Abgeleitet von git-von-grund-auf/lib.typ. Bewusst ohne Satz/Beweis/Formel-Umgebungen:
// dieses Buch erklärt in Worten, Bildern und Zahlenbeispielen.
#import "@preview/cetz:0.5.2"
#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

// ---------- Farben ----------
#let c-accent = rgb("#D9480F")
#let c-green  = rgb("#4E8A1E")
#let c-blue   = rgb("#2F6DB5")
#let c-violet = rgb("#7048B0")
#let c-teal   = rgb("#12877A")
#let c-yellow = rgb("#C98A00")
#let c-red    = rgb("#C92A2A")
#let c-grey   = rgb("#8A8F98")
#let c-dark   = rgb("#24272C")
#let c-light  = rgb("#F4F3EF")
#let palette = (c-blue, c-accent, c-teal, c-violet, c-yellow, c-green, c-red, c-grey)

// ---------- Callouts ----------
#let callout(title, color, body, breakable: false) = block(
  width: 100%, breakable: breakable,
  fill: color.lighten(93%),
  stroke: (left: 2.5pt + color),
  inset: (left: 11pt, right: 10pt, y: 8pt),
  radius: (right: 3pt),
  above: 1.1em, below: 1.1em,
)[
  #block(sticky: true, below: 0.55em, text(font: "Inter", size: 7.5pt, weight: "bold", tracking: 0.08em, fill: color.darken(15%), upper(title)))
  #set text(size: 9.3pt)
  #body
]
// Reihen-Standard
#let merke(body) = callout("Merke", c-blue, body)
#let achtung(body) = callout("Achtung", c-red, body)
#let fallstrick(body) = callout("Fallstrick", c-red, body)
#let tipp(body) = callout("Tipp", c-green, body)
#let praxis(body) = callout("Aus der Praxis", c-yellow, body)

// Einsteiger-Bausteine
// Alltagsvergleich, bevor ein Fachbegriff fällt
#let alltag(body) = callout("Stell dir vor", c-teal, body)
// Fachbegriff in einem Satz, ohne Formel
#let begriff(name, body) = callout([Begriff · #name], c-blue, body)
// Durchgespieltes Beispiel mit konkreten Zahlen oder Texten
#let beispiel(titel: none, body) = callout(if titel == none [Beispiel] else [Beispiel · #titel], c-teal, body, breakable: true)
// Nur wenn eine Rechnung fürs Verständnis nötig ist: Grundrechenarten, Schritt für Schritt
#let rechnung(titel: none, body) = callout(if titel == none [Zum Nachrechnen] else [Zum Nachrechnen · #titel], c-violet, body, breakable: true)
// Studie: Was wurde gemacht, was kam heraus, was heißt das
#let studie(titel: none, body) = callout(if titel == none [Studie] else [Studie · #titel], c-yellow, body, breakable: true)
// Frage, die im Hörsaal kommen kann, mit Antwort in zwei bis vier Sätzen
#let hoersaal(frage, antwort) = callout("Frage aus dem Hörsaal", c-violet, [
  #text(weight: "semibold", style: "italic", frage)
  #v(0.15em)
  #antwort
], breakable: true)
// Kapitelanfang: was du danach kannst
#let lernziele(..items) = callout("In diesem Kapitel", c-accent, list(..items))
// Kapitelende: das Wichtigste in fünf bis sieben Punkten
#let kurz(..items) = callout("Kurz gesagt", c-accent, list(..items), breakable: true)
// Kapitelende: Fragen mit Antworten. Aufruf: #selbsttest(([Frage], [Antwort]), ([Frage], [Antwort]), ...)
#let selbsttest(..paare) = {
  heading(level: 2, numbering: none, outlined: false)[Selbsttest]
  set enum(numbering: n => text(fill: c-accent, weight: "bold")[#n.])
  enum(..paare.pos().map(p => p.at(0)))
  block(above: 1em, below: 0.4em, text(size: 7.5pt, weight: "bold", tracking: 0.08em, fill: c-grey.darken(20%), upper[Antworten]))
  set text(size: 8.6pt, fill: c-dark.lighten(10%))
  set enum(numbering: n => text(fill: c-grey.darken(20%), weight: "bold")[#n.])
  enum(..paare.pos().map(p => p.at(1)))
}

// Dateikopf über einem Codeblock
#let datei(name, body) = block(width: 100%, above: 1em, below: 1em, breakable: true)[
  #box(fill: c-dark, radius: (top: 3pt), inset: (x: 7pt, y: 3.5pt),
    text(font: "JetBrains Mono", size: 7pt, fill: white, weight: "bold", name))
  #v(-0.62em)
  #body
]

// Zweispaltiger Vergleich
#let vorher-nachher(a, b, la: [Vorher], lb: [Nachher]) = grid(
  columns: (1fr, 1fr), column-gutter: 12pt,
  align(center)[#text(size: 8pt, weight: "bold", fill: c-grey.darken(20%), la) \ #a],
  align(center)[#text(size: 8pt, weight: "bold", fill: c-grey.darken(20%), lb) \ #b],
)

// ---------- cetz-Bausteine ----------
#let kasten(pos, body, name: none, bg: white, col: c-dark, w: 3.2, h: 1.0, size: 8pt) = {
  import cetz.draw: *
  let (x, y) = pos
  rect((x - w / 2, y - h / 2), (x + w / 2, y + h / 2), radius: 0.12, fill: bg, stroke: (paint: col, thickness: 0.9pt), name: name)
  content((x, y), align(center, text(font: "Inter", size: size, features: (calt: 0), body)))
}
#let pfeil(a, b, label: none, color: c-dark, dash: none, lpos: 0.5, loff: (0, 0.22)) = {
  import cetz.draw: *
  line(a, b, stroke: (paint: color, thickness: 0.9pt, dash: dash), mark: (end: "stealth", fill: color, scale: 0.6))
  if label != none {
    let (ax, ay) = a
    let (bx, by) = b
    content((ax + (bx - ax) * lpos + loff.at(0), ay + (by - ay) * lpos + loff.at(1)),
      text(font: "Inter", size: 6.8pt, fill: color.darken(10%), weight: "bold", label))
  }
}
// Fletcher-Knoten im Buchstil
#let fknoten(pos, body, col: c-blue, filled: false, w: 30mm, name: none) = node(pos,
  align(center, text(font: "Inter", size: 7.8pt, weight: if filled { "bold" } else { "regular" }, fill: if filled { white } else { c-dark }, body)),
  fill: if filled { col } else { col.lighten(88%) }, stroke: 0.8pt + col, corner-radius: 3pt, width: w, inset: 6pt, name: name)

// Einfaches Balkendiagramm (cetz), werte: ((label, wert), ...)
#let balken(werte, max: none, breite: 9, hoehe: 0.42, farbe: c-blue, einheit: "", nachkomma: 2) = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let m = if max == none { calc.max(..werte.map(w => w.at(1))) } else { max }
  for (i, (lab, v)) in werte.enumerate() {
    let y = -i * (hoehe + 0.22)
    content((-0.15, y), anchor: "east", text(font: "Inter", size: 7.5pt, lab))
    rect((0, y - hoehe / 2), (breite * v / m, y + hoehe / 2), fill: farbe.lighten(15%), stroke: none)
    content((breite * v / m + 0.12, y), anchor: "west", text(font: "Inter", size: 7pt, fill: c-dark, [#calc.round(v, digits: nachkomma)#einheit]))
  }
})

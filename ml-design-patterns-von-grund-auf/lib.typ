// Layout und Hilfsfunktionen für "ML Design Patterns von Grund auf".
// Design der Reihe Documents/Sources/books (Referenz: git-von-grund-auf): Inter + JetBrains Mono,
// Akzent orange, Callouts mit Seitenbalken, große Kapitelnummer, Teil-Labels über <teil>.
// Die Helfernamen (kasten, tipp, achtung, kiste, vergleich, konsole, teil, blau, grau ...) bleiben
// gleich wie in der ersten Fassung, damit die Kapitel unverändert bauen.

#import "@preview/cetz:0.4.1" as cetz: draw
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@local/ai-disclosure:1.0.0": ai-disclosure

// ---------- Farben der Reihe ----------
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

// Namen aus der ersten Fassung, auf die Reihenfarben gelegt
#let blau = c-blue
#let blau-hell = c-blue.lighten(86%)
#let grau = c-grey.darken(25%)
#let code-grund = c-light
#let terminal-grund = rgb("#2B2F36")
#let terminal-leiste = rgb("#3D424B")
#let mono = "JetBrains Mono"

// Diagramme, die breiter als die Textspalte sind, werden auf Textbreite verkleinert.
#let _passend(body) = context layout(size => {
  let m = measure(body)
  if size.width != float.inf and m.width > size.width {
    align(center, scale(size.width / m.width * 100%, reflow: true, body))
  } else {
    body
  }
})
// In Diagrammen bleibt die schmalere Latin Modern Sans: Alle Knotenbreiten wurden damit gesetzt
// und geprüft, Inter läuft breiter und würde Beschriftungen aus den Kästen drücken.
#let _dfont(body) = [#set text(font: "Latin Modern Sans")
#body]
#let diagram(..args) = _passend(_dfont(fletcher.diagram(..args)))
#let canvas(..args) = _passend(_dfont(cetz.canvas(..args)))

// ---------- Konsolenfenster ----------
#let _hart(s) = s.replace("\t", "    ").replace(" ", "\u{00A0}")
#let _konsole-zeile(z) = {
  let m = z.match(regex("^((?:\\(\\.venv\\) )?(?:\\$|>>>)(?: |$))(.*)$"))
  if m == none {
    text(fill: rgb("#B9C0CB"), _hart(z))
  } else {
    let rest = m.captures.at(1)
    let k = rest.match(regex("^(.*?)(\\s{2,}#.*)$"))
    let befehl = if k == none { rest } else { k.captures.at(0) }
    let kommentar = if k == none { "" } else { k.captures.at(1) }
    text(fill: rgb("#8BD18B"), _hart(m.captures.at(0)))
    text(fill: white, _hart(befehl))
    text(fill: rgb("#8C95A4"), _hart(kommentar))
  }
}

#let konsole(inhalt, titel: "Terminal") = block(
  width: 100%, radius: 5pt, clip: true, above: 1.1em, below: 1.2em,
  stroke: 0.6pt + rgb("#1E2126"),
  breakable: inhalt.split("\n").len() > 16,
)[
  #block(width: 100%, fill: terminal-leiste, inset: (x: 8pt, y: 4.5pt), spacing: 0pt)[
    #grid(
      columns: (1fr, auto, 1fr),
      align: (left + horizon, center + horizon, right),
      box(for c in ("#FF5F57", "#FEBC2E", "#28C840") {
        box(circle(radius: 3.2pt, fill: rgb(c), stroke: none))
        h(4pt)
      }),
      text(font: "Inter", size: 7.5pt, fill: rgb("#C9CED6"), titel),
      [],
    )
  ]
  #block(width: 100%, fill: terminal-grund, inset: (x: 11pt, y: 9pt), spacing: 0pt)[
    #set text(font: mono, size: 7.6pt)
    #set par(justify: false, leading: 0.55em)
    #inhalt.trim("\n", at: end).split("\n").map(_konsole-zeile).join(linebreak())
  ]
]


// ---------- Callouts im Stil der Reihe ----------
#let callout(title, color, body, breakable: false) = block(
  width: 100%, breakable: breakable,
  fill: color.lighten(93%),
  stroke: (left: 2.5pt + color),
  inset: (left: 11pt, right: 10pt, y: 8pt),
  radius: (right: 3pt),
  above: 1.1em, below: 1.1em,
)[
  #if title != none { block(sticky: true, below: 0.55em, text(font: "Inter", size: 7.5pt, weight: "bold", tracking: 0.08em, fill: color.darken(15%), upper(title))) }
  #set text(size: 9.3pt)
  #body
]
// kasten(titel, body): Titel wie "Lernziele." wird zur Callout-Überschrift (ohne Schlusspunkt)
#let _ohne-punkt(t) = {
  if t == none { return none }
  if type(t) == content and t.has("text") { return t.text.trim(".").trim(":") }
  t
}
#let kasten(titel, body, farbe: c-blue, grund: none) = callout(_ohne-punkt(titel), farbe, body, breakable: true)
#let merke(body) = callout("Merke", c-blue, body)
#let achtung(body) = callout("Achtung", c-red, body)
#let tipp(body) = callout("Tipp", c-green, body)
#let praxis(body) = callout("Aus der Praxis", c-yellow, body)

#let prompt(body) = callout("Prompt", c-violet, body)

#let vergleich(a, b, links: "Vorher", rechts: "Nachher") = block(breakable: false, above: 1.2em, below: 1.2em)[
  #grid(columns: (1fr, 1fr), column-gutter: 10pt, row-gutter: 4pt,
    text(size: 8pt, weight: "bold", fill: c-grey.darken(20%))[#links],
    text(size: 8pt, weight: "bold", fill: c-blue)[#rechts],
    a, b)
]
#let mac-win(mac, win) = grid(columns: (1fr, 1fr), column-gutter: 10pt, mac, win)

// Kleine Bausteine für Diagramme
#let kiste(body, fill: luma(242), stroke: 0.6pt + luma(150), width: auto) = box(
  fill: fill, stroke: stroke, radius: 3pt, inset: (x: 7pt, y: 5pt), width: width, body,
)

// Teil-Label: erscheint über den Kapitelköpfen und im Inhaltsverzeichnis (keine eigene Trennseite)
#let teil(nr, titel, intro, bild: none) = [#metadata("Teil " + nr + " · " + titel.text) <teil>]
#let anhang-label() = [#metadata("Anhang") <teil>]

// ---------- Inhaltsverzeichnis der Reihe ----------
#let inhalt() = context {
  let items = query(selector(<teil>).or(heading.where(level: 1)).or(heading.where(level: 2)))
  set text(size: 8.8pt)
  set par(justify: false)
  for it in items {
    if it.func() == metadata {
      v(0.7em)
      text(size: 7.5pt, weight: "bold", tracking: 0.12em, fill: c-accent, upper(it.value))
      v(0.15em)
    } else {
      let loc = it.location()
      let pg = str(counter(page).at(loc).first())
      let num = if it.numbering != none { numbering(it.numbering, ..counter(heading).at(loc)) } else { [] }
      if it.level == 1 {
        v(0.25em)
        link(loc, grid(columns: (2.0em, 1fr, auto), text(weight: "bold", num), text(weight: "bold", it.body), text(weight: "bold", pg)))
        v(0.05em)
      } else {
        link(loc, grid(columns: (2.0em, 2.3em, 1fr, auto), [], text(fill: c-grey.darken(10%), num), [#it.body #box(width: 1fr, repeat(text(fill: luma(190))[.#h(2pt)]))], text(fill: c-grey.darken(20%), pg)))
      }
    }
  }
}

// ---------- Seitenlayout (1:1 nach git-von-grund-auf/main.typ) ----------
#let handbuch(titel: none, untertitel: none, autor: none, fusszeile: none, stand: none, body) = {
  set document(title: titel, author: autor)
  set text(font: "Inter", size: 9.6pt, lang: "de", region: "at", hyphenate: true, fill: rgb("#1d1f23"), features: (calt: 0))
  set par(justify: true, leading: 0.66em, spacing: 1.0em)
  set list(indent: 0.4em, body-indent: 0.5em, spacing: 0.65em, marker: text(fill: c-accent, [•]))
  set enum(indent: 0.4em, body-indent: 0.5em, spacing: 0.65em)
  show strong: set text(weight: "semibold")
  show link: set text(fill: c-blue.darken(10%))
  show math.equation: set text(font: "New Computer Modern Math")

  // Code
  show raw: set text(font: "JetBrains Mono", ligatures: false, features: (calt: 0))
  show raw.where(block: false): it => box(fill: luma(240), inset: (x: 2.4pt), outset: (y: 2.3pt), radius: 2pt, text(size: 0.9em, it))
  show raw.where(block: true): it => {
    if it.lang == "terminal" { konsole(it.text) }
    else if it.lang == "mac" { konsole(it.text, titel: "Terminal am Mac") }
    else if it.lang == "win" { konsole(it.text, titel: "PowerShell unter Windows") }
    else if it.lang == "out" {
      block(width: 100%, fill: white, stroke: (paint: luma(200), thickness: 0.6pt, dash: "dashed"), radius: 4pt,
        inset: (x: 10pt, y: 7pt), above: 0.8em, below: 1em, breakable: true, text(size: 7.6pt, fill: c-dark.lighten(15%), it))
    } else {
      block(width: 100%, fill: c-light, stroke: 0.5pt + luma(222), radius: 4pt,
        inset: (x: 10pt, y: 8pt), above: 0.8em, below: 1em, breakable: true, text(size: 7.8pt, it))
    }
  }

  // Tabellen. Tabellen, die als Zeichnung dienen, setzen `fill: none` und eigene Linien.
  set table(
    stroke: (x, y) => (bottom: if y == 0 { 0.8pt + c-dark } else { 0.4pt + luma(215) }),
    inset: (x: 5pt, y: 4.5pt),
    fill: (x, y) => if y == 0 { luma(238) } else { none },
  )
  show table: set text(size: 8.6pt)
  show table: set par(justify: false)
  show table.cell.where(y: 0): set text(weight: "bold")

  // Abbildungen
  set figure(gap: 0.6em)
  show figure: set block(above: 1.3em, below: 1.3em)
  show figure: set par(justify: false)
  show figure.caption: it => text(size: 8pt, fill: c-grey.darken(25%))[#text(weight: "bold")[#it.supplement #context it.counter.display(it.numbering):] #it.body]
  show figure.where(kind: table): set figure.caption(position: top)

  // Überschriften
  set heading(numbering: "1.1")
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(0.9cm)
    context {
      let parts = query(selector(<teil>).before(here()))
      if parts.len() > 0 and it.numbering != none {
        text(size: 7.5pt, weight: "bold", tracking: 0.12em, fill: c-grey, upper(parts.last().value))
      } else { v(0.6em) }
    }
    v(0.1em)
    block(below: 0.4em, grid(columns: (auto, 1fr), column-gutter: 14pt, align: bottom,
      if it.numbering != none { text(size: 40pt, weight: "bold", fill: c-accent, counter(heading).display(it.numbering)) },
      par(justify: false, text(size: 21pt, weight: "bold", hyphenate: false, it.body))))
    line(length: 100%, stroke: 0.8pt + c-dark)
    v(0.9em)
  }
  show heading.where(level: 2): it => block(above: 1.55em, below: 0.75em, sticky: true,
    text(size: 12.5pt, weight: "bold", hyphenate: false)[#if it.numbering != none [#text(fill: c-accent)[#counter(heading).display(it.numbering)]#h(7pt)]#it.body])
  show heading.where(level: 3): it => block(above: 1.2em, below: 0.6em, sticky: true,
    text(size: 10pt, weight: "bold", fill: c-dark, it.body))

  // Seite
  set page(paper: "a4", margin: (x: 2.2cm, top: 2.4cm, bottom: 2.2cm),
    header: context {
      let pg = here().page()
      let chs = query(heading.where(level: 1))
      if chs.any(h => h.location().page() == pg) { return }
      let prev = chs.filter(h => h.location().page() < pg)
      if prev.len() == 0 { return }
      let hd = prev.last()
      set text(size: 7.3pt, fill: c-grey)
      grid(columns: (1fr, auto), titel,
        [#if hd.numbering != none [#numbering(hd.numbering, ..counter(heading).at(hd.location()))#h(5pt)]#hd.body])
      v(-0.45em)
      line(length: 100%, stroke: 0.4pt + luma(215))
    },
    footer: context {
      if here().page() > 1 { align(center, text(size: 7.8pt, fill: c-grey, counter(page).display())) }
    },
  )
  body
}

// Titelseite der Reihe
#let titelseite(titel: none, untertitel: none, lv: none, semester: none, autor: none, stand: none, grafik: none) = page(
  header: none, footer: none, margin: (x: 2.2cm, y: 2.4cm))[
  #v(2.2cm)
  #text(size: 9pt, weight: "bold", tracking: 0.15em, fill: c-accent)[PERSÖNLICHES HANDBUCH]
  #v(0.2cm)
  #par(justify: false, text(size: 40pt, weight: "bold", hyphenate: false)[#titel])
  #v(0.1cm)
  #par(justify: false, text(size: 14pt, fill: c-dark.lighten(20%), hyphenate: false)[#untertitel])
  #v(1.6cm)
  #if grafik != none { align(center, grafik) }
  #v(1fr)
  #line(length: 100%, stroke: 0.6pt + c-dark)
  #grid(columns: (1fr, auto), text(size: 9pt)[Für #autor \ #lv · #semester], align(right, text(size: 9pt)[#stand]))
]

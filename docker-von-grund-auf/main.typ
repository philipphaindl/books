#import "lib.typ": *

#set document(title: "Docker von Grund auf", author: "Philipp Haindl")
#set text(font: "Inter", size: 9.6pt, lang: "de", region: "at", hyphenate: true, fill: rgb("#1d1f23"), features: (calt: 0))
#set par(justify: true, leading: 0.66em, spacing: 1.0em)
#set list(indent: 0.4em, body-indent: 0.5em, spacing: 0.65em, marker: text(fill: c-accent, [•]))
#set enum(indent: 0.4em, body-indent: 0.5em, spacing: 0.65em)
#show strong: set text(weight: "semibold")
#show link: set text(fill: c-blue.darken(10%))

// ---------- Code ----------
#show raw: set text(font: "JetBrains Mono", ligatures: false, features: (calt: 0))
#show raw.where(block: false): it => box(fill: luma(240), inset: (x: 2.4pt), outset: (y: 2.3pt), radius: 2pt, text(size: 0.9em, it))
#show raw.where(block: true): it => {
  if it.lang == "out" {
    block(width: 100%, fill: white, stroke: (paint: luma(200), thickness: 0.6pt, dash: "dashed"), radius: 4pt,
      inset: (x: 10pt, y: 7pt), above: 0.8em, below: 1em, breakable: true,
      text(size: 7.6pt, fill: c-dark.lighten(15%), it))
  } else {
    block(width: 100%, fill: c-light, stroke: 0.5pt + luma(222), radius: 4pt,
      inset: (x: 10pt, y: 8pt), above: 0.8em, below: 1em, breakable: true,
      text(size: 7.8pt, it))
  }
}

// ---------- Tabellen ----------
#set table(
  stroke: (x, y) => (bottom: if y == 0 { 0.8pt + c-dark } else { 0.4pt + luma(215) }),
  inset: (x: 5pt, y: 4.5pt),
  fill: (x, y) => if y == 0 { luma(238) } else { none },
  align: left + top,
)
#show table: set text(size: 8.6pt)
#show table: set par(justify: false)
#show table: it => block(breakable: false, width: 100%, it)
#show table.cell.where(y: 0): set text(weight: "bold")

// ---------- Abbildungen ----------
#set figure(kind: image, supplement: [Abb.], gap: 0.6em)
#show figure: set block(above: 1.3em, below: 1.3em)
#show figure: set par(justify: false)
#show figure.caption: it => text(size: 8pt, fill: c-grey.darken(25%))[#text(weight: "bold")[#it.supplement #context it.counter.display(it.numbering):] #it.body]
#show figure.where(kind: table): set figure.caption(position: top)

// ---------- Überschriften ----------
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
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
#show heading.where(level: 2): it => block(above: 1.55em, below: 0.75em, sticky: true,
  text(size: 12.5pt, weight: "bold", hyphenate: false)[#if it.numbering != none [#text(fill: c-accent)[#counter(heading).display(it.numbering)]#h(7pt)]#it.body])
#show heading.where(level: 3): it => block(above: 1.2em, below: 0.6em, sticky: true,
  text(size: 10pt, weight: "bold", fill: c-dark, it.body))

// ---------- Seite ----------
#set page(paper: "a4", margin: (x: 2.2cm, top: 2.4cm, bottom: 2.2cm),
  header: context {
    let pg = here().page()
    let chs = query(heading.where(level: 1))
    if chs.any(h => h.location().page() == pg) { return }
    let prev = chs.filter(h => h.location().page() < pg)
    if prev.len() == 0 { return }
    let hd = prev.last()
    set text(size: 7.3pt, fill: c-grey)
    grid(columns: (1fr, auto), [Docker von Grund auf],
      [#if hd.numbering != none [#numbering(hd.numbering, ..counter(heading).at(hd.location()))#h(5pt)]#hd.body])
    v(-0.45em)
    line(length: 100%, stroke: 0.4pt + luma(215))
  },
  footer: context {
    if here().page() > 1 { align(center, text(size: 7.8pt, fill: c-grey, counter(page).display())) }
  },
)

// ---------- Titelseite ----------
#page(header: none, footer: none, margin: (x: 2.2cm, y: 2.4cm))[
  #v(2.2cm)
  #text(size: 9pt, weight: "bold", tracking: 0.15em, fill: c-accent)[PERSÖNLICHES HANDBUCH]
  #v(0.2cm)
  #text(size: 40pt, weight: "bold", hyphenate: false)[Docker von Grund auf]
  #v(0.1cm)
  #text(size: 14pt, fill: c-dark.lighten(20%), hyphenate: false)[Container per Kommandozeile am Mac, Dockerfiles, Compose, Betrieb auf dem Server und CI/CD mit Gitea]
  #v(1.4cm)
  #align(center, cetz.canvas(length: 1cm, {
    import cetz.draw: *
    stapel((0, 0), (([Basis-Image `python:3.14-slim`], c-blue), ([Abhängigkeiten], c-blue), ([Anwendungscode], c-blue)), w: 4.2)
    content((0, 1.85), text(size: 7.5pt, weight: "bold", fill: c-blue.darken(20%))[Image `notizen:1.4.0`])
    for (i, n) in ("api-1", "api-2", "api-3").enumerate() {
      let x = 5.2 + i * 2.3
      stapel((x, 0), (([], c-blue), ([], c-blue), ([], c-blue), ([Schreibschicht], c-accent, true)), w: 2.0, size: 6.5pt)
      content((x, 2.35), text(font: "JetBrains Mono", size: 7pt, weight: "bold", fill: c-accent.darken(15%), n))
    }
    line((2.2, 0.75), (4.1, 0.75), stroke: (paint: c-dark, thickness: 0.9pt), mark: (end: "stealth", fill: c-dark, scale: 0.6))
    content((3.15, 1.0), text(font: "JetBrains Mono", size: 6.8pt, weight: "bold")[docker run])
  }))
  #v(1fr)
  #line(length: 100%, stroke: 0.6pt + c-dark)
  #grid(columns: (1fr, auto), text(size: 9pt)[Für Philipp Haindl \ Docker Engine 29.8 · Compose 5.5 · Colima · Gitea Actions], align(right, text(size: 9pt)[Stand: September 2026]))
]

// ---------- Inhaltsverzeichnis ----------
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
#page(header: none)[
  #text(size: 21pt, weight: "bold")[Inhalt]
  #v(0.2em)
  #line(length: 100%, stroke: 0.8pt + c-dark)
  #v(0.4em)
  #columns(2, gutter: 16pt, inhalt())
]

#include "kap00-vorwort.typ"
#metadata("Teil I · Grundlagen") <teil>
#include "kap01-modell.typ"
#include "kap02-mac.typ"
#include "kap03-container.typ"
#include "kap04-images.typ"
#metadata("Teil II · Zusammenspiel") <teil>
#include "kap05-daten.typ"
#include "kap06-netzwerke.typ"
#include "kap07-compose.typ"
#include "kap08-gute-images.typ"
#include "kap09-plattformen.typ"
#include "kap10-fehlersuche.typ"
#metadata("Teil III · Betrieb") <teil>
#include "kap11-registry.typ"
#include "kap12-sicherheit.typ"
#include "kap13-server.typ"
#include "kap14-cicd.typ"
#include "kap15-ausblick.typ"
#metadata("Anhang") <teil>
#counter(heading).update(0)
#set heading(numbering: "A.1")
#include "anh-a-befehle.typ"
#include "anh-b-glossar.typ"

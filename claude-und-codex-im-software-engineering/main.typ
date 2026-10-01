#import "lib.typ": *

#set document(title: "Claude und Codex im Software Engineering", author: "Philipp Haindl")
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
    grid(columns: (1fr, auto), [Claude und Codex im Software Engineering],
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
  #set par(justify: false)
  #v(2.2cm)
  #text(size: 9pt, weight: "bold", tracking: 0.15em, fill: c-accent)[PERSÖNLICHES HANDBUCH]
  #v(0.2cm)
  #text(size: 34pt, weight: "bold", hyphenate: false)[Claude und Codex im Software Engineering]
  #v(0.1cm)
  #text(size: 14pt, fill: c-dark.lighten(20%), hyphenate: false)[Modelle und Reasoning-Effort richtig wählen, Halluzinationen vermeiden, Aufgabentreue sichern und genau das Gefragte in hoher Qualität liefern]
  #v(1.4cm)
  #align(center, cetz.canvas(length: 1cm, {
    import cetz.draw: *
    kasten((0, 0), [Anforderung \ #text(size: 6.5pt)[FR, NFR, ADR]], w: 2.3, h: 1.0, bg: rgb("#FFF8E6"), col: c-yellow, size: 7.3pt)
    kasten((3.4, 0), [Modell + Effort \ #text(size: 6.5pt)[passend gewählt]], w: 2.5, h: 1.0, bg: rgb("#F1ECF8"), col: c-violet, size: 7.3pt)
    kasten((7.0, 0), [Agent \ #text(size: 6.5pt)[Claude / Codex]], w: 2.3, h: 1.0, bg: rgb("#FDF1EC"), col: c-accent, size: 7.3pt)
    kasten((10.5, 0), [Prüfungen \ #text(size: 6.5pt)[Tests, Lint, Architektur]], w: 2.7, h: 1.0, bg: rgb("#EEF6E6"), col: c-gitea, size: 7.3pt)
    kasten((13.9, 0), [Review \ #text(size: 6.5pt)[Modell + Mensch]], w: 2.2, h: 1.0, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
    pfeil((1.2, 0), (2.1, 0)); pfeil((4.7, 0), (5.8, 0)); pfeil((8.2, 0), (9.1, 0)); pfeil((11.9, 0), (12.75, 0))
    line((10.5, -0.55), (10.5, -1.2), (7.0, -1.2), (7.0, -0.55), stroke: (paint: c-red, thickness: 0.8pt, dash: "dashed"), mark: (end: "stealth", fill: c-red, scale: 0.5))
    content((8.75, -1.45), text(size: 6.8pt, fill: c-red, style: "italic")[rot -> nachbessern, nicht behaupten])
  }))
  #v(1fr)
  #line(length: 100%, stroke: 0.6pt + c-dark)
  #grid(columns: (1fr, auto), text(size: 9pt)[Für Philipp Haindl \ Claude Code · Claude-Desktop-App · Codex CLI · ChatGPT-Desktop-App · VS Code], align(right, text(size: 9pt)[Stand: Ende September 2026]))
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
#include "kap01-agenten.typ"
#include "kap02-modelle.typ"
#include "kap03-effort.typ"
#metadata("Teil II · Auswahl in der Praxis") <teil>
#include "kap04-einrichtung.typ"
#include "kap05-auswahl.typ"
#include "kap06-crossreview.typ"
#metadata("Teil III · Qualität") <teil>
#include "kap07-halluzinationen.typ"
#include "kap08-adherence.typ"
#include "kap09-goals.typ"
#include "kap10-adr-anforderungen.typ"
#include "kap11-qualitaet.typ"
#include "kap12-sicherheit.typ"
#include "kap13-durchlauf.typ"
#metadata("Teil IV · Unter der Haube") <teil>
#include "kap14-inferenz.typ"
#include "kap15-lokal.typ"
#metadata("Anhang") <teil>
#counter(heading).update(0)
#set heading(numbering: "A.1")
#include "anh-a-vorlagen.typ"
#include "anh-b-glossar.typ"
#metadata("Verzeichnisse") <teil>
#include "literatur.typ"

#import "@preview/cetz:0.5.2"

// ---------- Farben ----------
#let c-accent = rgb("#D9480F")
#let c-gitea  = rgb("#4E8A1E")
#let c-blue   = rgb("#2F6DB5")
#let c-violet = rgb("#7048B0")
#let c-teal   = rgb("#12877A")
#let c-yellow = rgb("#C98A00")
#let c-red    = rgb("#C92A2A")
#let c-grey   = rgb("#8A8F98")
#let c-dark   = rgb("#24272C")
#let c-light  = rgb("#F4F3EF")

// ---------- Commit-Graph ----------
// commits: Array von Dictionaries
//   (id: "c1", x: 0, y: 0, label: "A", parents: ("c0",), color: c-blue, ghost: false, hl: false)
// refs: Array von Dictionaries
//   (name: "main", to: "c1", dir: "up", dist: 0.95, kind: "branch")
//   to kann eine Commit-ID oder der name eines anderen Refs sein (z.B. HEAD -> main)
#let gitgraph(commits, refs: (), unit: 1.1cm, r: 0.27, notes: (), extra: none) = {
  cetz.canvas(length: unit, {
    import cetz.draw: *
    let cmap = (:)
    for c in commits { cmap.insert(c.id, c) }
    // Kanten (Kind -> Elternteil)
    for c in commits {
      for p in c.at("parents", default: ()) {
        let pc = cmap.at(p)
        let (x1, y1) = (c.x, c.y)
        let (x2, y2) = (pc.x, pc.y)
        let dx = x2 - x1
        let dy = y2 - y1
        let len = calc.sqrt(dx * dx + dy * dy)
        let ux = dx / len
        let uy = dy / len
        let ghost = c.at("ghost", default: false)
        line(
          (x1 + ux * r, y1 + uy * r), (x2 - ux * (r + 0.02), y2 - uy * (r + 0.02)),
          stroke: (paint: if ghost { c-grey.lighten(30%) } else { c-grey.darken(20%) }, thickness: 0.9pt, dash: if ghost { "dashed" } else { none }),
          mark: (end: "stealth", fill: if ghost { c-grey.lighten(30%) } else { c-grey.darken(20%) }, scale: 0.55),
        )
      }
    }
    // Knoten
    for c in commits {
      let col = c.at("color", default: c-blue)
      let ghost = c.at("ghost", default: false)
      let hl = c.at("hl", default: false)
      if hl {
        circle((c.x, c.y), radius: r + 0.09, stroke: (paint: c-yellow, thickness: 1.6pt), fill: none)
      }
      circle((c.x, c.y), radius: r,
        fill: if ghost { white } else { col },
        stroke: if ghost { (paint: col.lighten(20%), thickness: 1pt, dash: "dashed") } else { (paint: col.darken(25%), thickness: 0.8pt) },
        name: c.id)
      content((c.x, c.y), text(font: "Inter", size: 7.5pt, weight: "bold", fill: if ghost { col } else { white }, c.at("label", default: "")))
    }
    // Refs
    let rpos = (:)
    let i = 0
    for rf in refs {
      let kind = rf.at("kind", default: "branch")
      let dir = rf.at("dir", default: "up")
      let dist = rf.at("dist", default: 0.95)
      let tgt = rf.to
      let is-commit = tgt in cmap
      let (tx, ty) = if is-commit { (cmap.at(tgt).x, cmap.at(tgt).y) } else { rpos.at(tgt) }
      let v = if dir == "up" { (0, 1) } else if dir == "down" { (0, -1) } else if dir == "right" { (1, 0) } else { (-1, 0) }
      let px = tx + v.at(0) * dist
      let py = ty + v.at(1) * dist
      rpos.insert(rf.name, (px, py))
      let (fillc, txtc, strk) = if kind == "head" {
        (c-dark, white, c-dark)
      } else if kind == "remote" {
        (white, c-grey.darken(30%), (paint: c-grey, dash: "dashed", thickness: 0.8pt))
      } else if kind == "tag" {
        (rgb("#FFF4D6"), c-yellow.darken(30%), (paint: c-yellow, thickness: 0.8pt))
      } else {
        (rgb("#EAF1FB"), c-blue.darken(30%), (paint: c-blue, thickness: 0.8pt))
      }
      let col = rf.at("color", default: none)
      if col != none and kind == "branch" { fillc = col.lighten(85%); txtc = col.darken(35%); strk = (paint: col, thickness: 0.8pt) }
      let nm = "ref" + str(i)
      content((px, py),
        box(fill: fillc, stroke: strk, radius: 3pt, inset: (x: 4pt, y: 2.5pt),
          text(font: "JetBrains Mono", size: 7pt, weight: "bold", fill: txtc, ligatures: false, features: (calt: 0), rf.name)),
        name: nm)
      // Pfeil vom Label zum Ziel
      let (a-from, a-to) = if dir == "up" {
        (nm + ".south", if is-commit { (tx, ty + r + 0.03) } else { (tx, ty + 0.2) })
      } else if dir == "down" {
        (nm + ".north", if is-commit { (tx, ty - r - 0.03) } else { (tx, ty - 0.2) })
      } else if dir == "right" {
        (nm + ".west", if is-commit { (tx + r + 0.03, ty) } else { (tx + 0.55, ty) })
      } else {
        (nm + ".east", if is-commit { (tx - r - 0.03, ty) } else { (tx - 0.55, ty) })
      }
      line(a-from, a-to, stroke: (paint: c-dark.lighten(20%), thickness: 0.7pt), mark: (end: "stealth", fill: c-dark.lighten(20%), scale: 0.45))
      i += 1
    }
    for n in notes {
      content(n.pos, text(font: "Inter", size: n.at("size", default: 7.5pt), fill: n.at("fill", default: c-grey.darken(30%)), style: n.at("style", default: "italic"), n.body), anchor: n.at("anchor", default: "center"))
    }
    if extra != none { extra }
  })
}

// Kurzform: lineare Commit-Kette erzeugen
#let chain(ids, labels, y: 0, x0: 0, dx: 1.3, color: c-blue, first-parent: none) = {
  let out = ()
  for (k, id) in ids.enumerate() {
    let parents = if k == 0 { if first-parent == none { () } else { (first-parent,) } } else { (ids.at(k - 1),) }
    out.push((id: id, x: x0 + k * dx, y: y, label: labels.at(k), parents: parents, color: color))
  }
  out
}


// ---------- Textbausteine ----------
#let callout(title, color, body) = block(
  width: 100%, breakable: false,
  fill: color.lighten(93%),
  stroke: (left: 2.5pt + color),
  inset: (left: 11pt, right: 10pt, y: 8pt),
  radius: (right: 3pt),
  above: 1.1em, below: 1.1em,
)[
  #text(font: "Inter", size: 7.5pt, weight: "bold", tracking: 0.08em, fill: color.darken(15%), upper(title))
  #v(-0.35em)
  #set text(size: 9.3pt)
  #body
]
#let merke(body) = callout("Merke", c-blue, body)
#let achtung(body) = callout("Achtung", c-red, body)
#let tipp(body) = callout("Tipp", c-gitea, body)
#let mac(body) = callout("Speziell am Mac", c-violet, body)
#let praxis(body) = callout("Aus der Praxis", c-yellow, body)

// Dateikopf über einem Codeblock
#let datei(name, body) = block(width: 100%, above: 1em, below: 1em, breakable: true)[
  #box(fill: c-dark, radius: (top: 3pt), inset: (x: 7pt, y: 3.5pt),
    text(font: "JetBrains Mono", size: 7pt, fill: white, weight: "bold", name))
  #v(-0.62em)
  #body
]

// Tastenkürzel
#let key(k) = box(stroke: 0.6pt + c-grey, radius: 2pt, inset: (x: 3pt, y: 0pt), outset: (y: 2pt), fill: white,
  text(font: "Inter", size: 0.82em, weight: "medium", k))

// Zweispaltiger Vorher/Nachher-Vergleich
#let vorher-nachher(a, b, la: [Vorher], lb: [Nachher]) = grid(
  columns: (1fr, 1fr), column-gutter: 12pt,
  align(center)[#text(size: 8pt, weight: "bold", fill: c-grey.darken(20%), la) \ #a],
  align(center)[#text(size: 8pt, weight: "bold", fill: c-grey.darken(20%), lb) \ #b],
)

// Ablaufkasten für Diagramme
#let kasten(pos, body, name: none, bg: white, col: c-dark, w: 3.2, h: 1.0, size: 8pt) = {
  import cetz.draw: *
  let (x, y) = pos
  rect((x - w / 2, y - h / 2), (x + w / 2, y + h / 2), radius: 0.12, fill: bg, stroke: (paint: col, thickness: 0.9pt), name: name)
  content((x, y), align(center, text(font: "Inter", size: size, features: (calt: 0), body)))
}
#let pfeil(a, b, label: none, color: c-dark, dash: none, lpos: 0.5, loff: (0, 0.22), bend: none) = {
  import cetz.draw: *
  line(a, b, stroke: (paint: color, thickness: 0.9pt, dash: dash), mark: (end: "stealth", fill: color, scale: 0.6))
  if label != none {
    let (ax, ay) = a
    let (bx, by) = b
    content((ax + (bx - ax) * lpos + loff.at(0), ay + (by - ay) * lpos + loff.at(1)),
      text(font: "JetBrains Mono", size: 6.8pt, fill: color.darken(10%), weight: "bold", ligatures: false, features: (calt: 0), label))
  }
}

// ---------- Docker-Diagramme ----------
// Schichtenstapel, items von unten nach oben: (label, farbe) oder (label, farbe, true) für gestrichelt
#let stapel(pos, items, w: 3.6, h: 0.46, gap: 0.05, size: 7pt) = {
  import cetz.draw: *
  let (x, y) = pos
  for (i, it) in items.enumerate() {
    let lab = it.at(0)
    let col = it.at(1)
    let gestrichelt = it.len() > 2 and it.at(2)
    let y0 = y + i * (h + gap)
    rect((x - w / 2, y0), (x + w / 2, y0 + h), radius: 0.06, fill: col.lighten(86%),
      stroke: (paint: col, thickness: 0.8pt, dash: if gestrichelt { "dashed" } else { none }))
    content((x, y0 + h / 2), text(font: "Inter", size: size, features: (calt: 0), lab))
  }
}
// Rahmen mit Titel oben links; a = unten links, b = oben rechts
#let rahmen(a, b, titel, col, bg: none, size: 7.8pt) = {
  import cetz.draw: *
  rect(a, b, radius: 0.15, fill: if bg == none { col.lighten(94%) } else { bg }, stroke: (paint: col, thickness: 1pt))
  content((a.at(0) + 0.2, b.at(1) - 0.26), anchor: "west", text(font: "Inter", size: size, weight: "bold", fill: col.darken(20%), features: (calt: 0), titel))
}

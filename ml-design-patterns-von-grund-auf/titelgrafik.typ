#import "lib.typ": *
// Titelgrafik: der ML-Lebenszyklus als Kette, darunter die sechs Pattern-Kategorien.
#{
  let k(pos, body, col: c-blue, filled: false) = node(pos,
    align(center, text(font: "Inter", size: 8pt, weight: if filled { "bold" } else { "medium" }, fill: if filled { white } else { c-dark }, body)),
    fill: if filled { col } else { col.lighten(88%) }, stroke: 0.8pt + col, corner-radius: 3pt, width: 23mm, height: 10mm)
  diagram(spacing: (5mm, 9mm),
    k((0, 0), [Daten], filled: true),
    k((1, 0), [Features]),
    k((2, 0), [Training], col: c-accent),
    k((3, 0), [Evaluation], col: c-accent),
    k((4, 0), [Serving], col: c-teal),
    k((5, 0), [Monitoring], col: c-teal, filled: true),
    edge((0, 0), (1, 0), "-|>"), edge((1, 0), (2, 0), "-|>"), edge((2, 0), (3, 0), "-|>"),
    edge((3, 0), (4, 0), "-|>"), edge((4, 0), (5, 0), "-|>"),
    edge((5, 0), (5, 0.9), (0, 0.9), (0, 0), "-|>", stroke: (paint: c-grey, dash: "dashed"), label: text(size: 7pt, fill: c-grey.darken(20%))[neu trainieren], label-pos: 0.5, label-side: center, label-fill: white),
  )
}

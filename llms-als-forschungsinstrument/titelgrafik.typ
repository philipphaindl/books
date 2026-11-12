#import "lib.typ": *
// Titelgrafik: viele LLM-Labels + wenige Gold-Labels -> korrigierte Schätzung mit Konfidenzintervall
#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  // Punktwolke LLM-Labels
  let pts = ((0.2,0.5),(0.6,1.1),(1.0,0.3),(1.3,1.4),(0.4,1.8),(1.7,0.8),(2.0,1.6),(0.9,2.1),(1.5,2.3),(2.2,0.4),(0.1,1.2),(1.9,2.0))
  for p in pts { circle(p, radius: 0.09, fill: c-blue.lighten(30%), stroke: none) }
  for p in ((0.7,0.7),(1.6,1.2),(1.1,1.7)) { circle(p, radius: 0.12, fill: c-accent, stroke: none) }
  content((1.15, -0.45), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[viele LLM-Labels, wenige Gold-Labels])
  kasten((5.0, 1.2), [LLM-Annotator \ + Validierung], w: 2.6, h: 1.0, col: c-dark)
  kasten((8.6, 1.2), [Korrektur \ (PPI, DSL)], w: 2.4, h: 1.0, col: c-accent)
  pfeil((2.6, 1.2), (3.65, 1.2))
  pfeil((6.35, 1.2), (7.35, 1.2))
  // Schätzer mit KI
  line((10.4, 1.2), (12.6, 1.2), stroke: 0.6pt + c-grey)
  line((11.0, 1.2), (12.0, 1.2), stroke: 2.2pt + c-accent)
  circle((11.5, 1.2), radius: 0.11, fill: c-dark, stroke: none)
  content((11.5, 0.55), text(font: "Inter", size: 7pt, fill: c-grey.darken(20%))[gültige Schlussfolgerung])
  pfeil((9.85, 1.2), (10.35, 1.2))
})

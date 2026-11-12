#import "lib.typ": *
// Titelgrafik: Forschungsfrage -> LLM arbeitet -> Menschen prüfen eine Stichprobe -> belastbares Ergebnis
#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  kasten((0, 0), [Forschungs- \ frage], w: 2.6, h: 1.1, col: c-dark)
  kasten((3.7, 0), [LLM \ erledigt die Masse], w: 3.0, h: 1.1, col: c-blue, bg: c-blue.lighten(90%))
  kasten((7.7, 0), [Menschen prüfen \ eine Stichprobe], w: 3.2, h: 1.1, col: c-accent, bg: c-accent.lighten(90%))
  kasten((11.6, 0), [Belastbares \ Ergebnis], w: 2.6, h: 1.1, col: c-teal, bg: c-teal.lighten(90%))
  pfeil((1.3, 0), (2.2, 0))
  pfeil((5.2, 0), (6.1, 0))
  pfeil((9.3, 0), (10.3, 0))
  content((5.8, -1.15), text(font: "Inter", size: 7.5pt, fill: c-grey.darken(20%), style: "italic")[Der rote Faden des Buchs: Das Modell arbeitet, der Mensch belegt, dass man dem Ergebnis trauen darf.])
})

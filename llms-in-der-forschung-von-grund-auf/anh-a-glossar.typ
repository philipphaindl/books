#import "lib.typ": *
#import "glossar-00.typ": begriffe as g00
#import "glossar-01.typ": begriffe as g01
#import "glossar-02.typ": begriffe as g02
#import "glossar-03.typ": begriffe as g03
#import "glossar-04.typ": begriffe as g04
#import "glossar-05.typ": begriffe as g05
#import "glossar-06.typ": begriffe as g06
#import "glossar-07.typ": begriffe as g07
#import "glossar-08.typ": begriffe as g08
#import "glossar-09.typ": begriffe as g09
#import "glossar-10.typ": begriffe as g10

= Glossar

Alle Fachbegriffe des Buchs in einem Satz. Die Zahl in Klammern nennt das Kapitel, in dem der Begriff erklärt wird (0 steht für "Das Nötigste vorab"). Englische Begriffe stehen so da, wie sie auf den Folien vorkommen.

// Einträge: (Begriff als String, Erklärung als Content, Kapitelnummer). Doppelte Begriffe: der erste Eintrag gewinnt.
#let alle = (g00 + g01 + g02 + g03 + g04 + g05 + g06 + g07 + g08 + g09 + g10)
#let gesehen = (:)
#let eindeutig = ()
#for e in alle {
  let k = lower(e.at(0))
  if k not in gesehen {
    gesehen.insert(k, true)
    eindeutig.push(e)
  }
}
#let sortiert = eindeutig.sorted(key: e => lower(e.at(0)).replace("ä", "a").replace("ö", "o").replace("ü", "u"))

#set par(justify: false)
#table(columns: (auto, 1fr),
  [Begriff], [Bedeutung],
  ..sortiert.map(e => (
    text(weight: "semibold", e.at(0)),
    [#e.at(1) #text(size: 7.5pt, fill: c-grey.darken(10%))[(#e.at(2))]],
  )).flatten()
)

#import "lib.typ": *
#set heading(numbering: none)

= Literaturverzeichnis

#text(size: 8.6pt, fill: c-grey.darken(20%))[Die Nummern verweisen auf die Quellenangaben im Text. Alle Quellen wurden für die Wissensbasis der Lehrveranstaltung am 11. November 2026 geprüft. Das Verzeichnis enthält nur Quellen, die im Text zitiert werden.]
#v(0.4em)

#{
  set text(size: 7.8pt)
  set par(justify: false, leading: 0.55em)
  show link: set text(fill: c-blue.darken(10%))
  bibliography("literatur.bib", style: "ieee", title: none)
}

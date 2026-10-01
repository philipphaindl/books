#import "lib.typ": *
#set heading(numbering: none)

= Literaturverzeichnis

#text(size: 8.6pt, fill: c-grey.darken(20%))[Die Nummern verweisen auf die Quellenangaben im Text. Online-Quellen wurden am 1. Oktober 2026 abgerufen. Das Verzeichnis enthält nur Quellen, die im Text zitiert werden.]
#v(0.4em)

#{
  set text(size: 7.8pt)
  set par(justify: false, leading: 0.55em)
  show link: set text(fill: c-blue.darken(10%))
  bibliography("literatur.yml", style: "ieee", title: none)
}

#import "lib.typ": *
#set heading(numbering: none)

= Literaturverzeichnis

#text(size: 8.6pt, fill: c-grey.darken(20%))[Die Nummern verweisen auf die Quellenangaben im Text. Das Verzeichnis enthält nur Quellen, die im Text zitiert werden.]
#v(0.4em)

#{
  set text(size: 7.8pt)
  set par(justify: false, leading: 0.55em)
  bibliography("literatur.bib", style: "ieee", title: none)
}

#v(1.5em)
#ai-disclosure(
  lang: "de",
  text-tools: (
    (model: "claude-opus-5.5", purposes: ("ideation", "drafting", "rephrasing", "formatting", "fact-checking")),
  ),
  image-tools: ("GPT Image 2",)
)

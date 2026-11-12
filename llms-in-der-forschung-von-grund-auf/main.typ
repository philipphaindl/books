#import "layout.typ": *
#show: layout

// ---------- Titelseite ----------
#page(header: none, footer: none, margin: (x: 2.2cm, y: 2.4cm))[
  #v(2.2cm)
  #text(size: 9pt, weight: "bold", tracking: 0.15em, fill: c-accent)[PERSÖNLICHES HANDBUCH]
  #v(0.2cm)
  #par(justify: false, text(size: 40pt, weight: "bold", hyphenate: false)[LLMs in der Forschung von Grund auf])
  #v(0.1cm)
  #par(justify: false, text(size: 14pt, fill: c-dark.lighten(20%), hyphenate: false)[Forschungsmethoden, Prompts, Annotation, Bewertung, Bias, RAG und reproduzierbare Workflows, erklärt ohne Formeln])
  #v(1.6cm)
  #align(center, include "titelgrafik.typ")
  #v(1fr)
  #line(length: 100%, stroke: 0.6pt + c-dark)
  #grid(columns: (1fr, auto), text(size: 9pt)[Für Philipp Haindl \ Begleitbuch zur LV Generative AI in Research and Innovation (SS 2027)], align(right, text(size: 9pt)[Stand: November 2026]))
]

#page(header: none)[
  #text(size: 21pt, weight: "bold")[Inhalt]
  #v(0.2em)
  #line(length: 100%, stroke: 0.8pt + c-dark)
  #v(0.4em)
  #columns(2, gutter: 16pt, inhalt())
]

#include "kap00-vorwort.typ"
#include "kap00-grundbegriffe.typ"
#metadata("Teil I · Forschen mit Methode") <teil>
#include "kap01-forschungsmethoden.typ"
#include "kap02-design-science.typ"
#metadata("Teil II · Das LLM als Werkzeug") <teil>
#include "kap03-prompts.typ"
#include "kap04-forschungsinstrument.typ"
#metadata("Teil III · Messen, Schließen, Bewerten") <teil>
#include "kap05-annotation.typ"
#include "kap06-inferenz.typ"
#include "kap07-judge.typ"
#metadata("Teil IV · Qualität, Fairness, Nachvollziehbarkeit") <teil>
#include "kap08-bias.typ"
#include "kap09-rag.typ"
#include "kap10-workflows.typ"
#metadata("Anhang") <teil>
#counter(heading).update(0)
#set heading(numbering: "A.1")
#include "anh-a-glossar.typ"
#include "literatur.typ"

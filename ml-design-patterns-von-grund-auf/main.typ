// "ML Design Patterns von Grund auf" - Manifest. Bauen:
//   typst compile --font-path fonts main.typ ML-Design-Patterns-von-Grund-auf.pdf

#import "lib.typ": *

#show: handbuch.with(
  titel: [ML Design Patterns von Grund auf],
  autor: "Philipp Haindl",
)

#titelseite(
  titel: [ML Design Patterns von Grund auf],
  untertitel: [Dreißig Patterns für Daten, Training und Betrieb, erklärt für Software Engineers ohne ML-Vorwissen, mit lauffähigen Beispielen, Fallstudien und Übungen],
  lv: [Clean Code und Software Engineering (MDI)],
  semester: [WS 2027],
  autor: [Philipp Haindl],
  stand: [Stand: November 2026],
  grafik: include "titelgrafik.typ",
)

#page(header: none)[
  #text(size: 21pt, weight: "bold")[Inhalt]
  #v(0.2em)
  #line(length: 100%, stroke: 0.8pt + c-dark)
  #v(0.4em)
  #columns(2, gutter: 16pt, inhalt())
]

#teil("I", [Grundlagen], [Was ein Modell ist, wie Training funktioniert und welche Begriffe man kennen muss, um die Patterns zu verstehen. Geschrieben für Leserinnen und Leser, die Software bauen können, aber noch nie ein Modell trainiert haben.], bild: "images/teil-1-grundlagen.png")

#include "kapitel/01-einleitung.typ"
#include "kapitel/02-ml-grundlagen.typ"
#include "kapitel/02b-neuronale-netze.typ"
#include "kapitel/03-landkarte.typ"

#teil("II", [Daten und Problem], [Wie Eingaben für ein Modell aufbereitet werden und wie man ein fachliches Problem so formuliert, dass ein Modell es lösen kann.], bild: "images/teil-2-daten-problem.png")

#include "kapitel/04-data-representation.typ"
#include "kapitel/05-problem-representation.typ"

#teil("III", [Training und Betrieb], [Wie man Modelle zuverlässig trainiert und wie man sie so betreibt, dass Vorhersagen schnell, skalierbar und nachvollziehbar bleiben.], bild: "images/teil-3-training-betrieb.png")

#include "kapitel/06-model-training.typ"
#include "kapitel/07-resilient-serving.typ"

#teil("IV", [Reproduzierbarkeit und Verantwortung], [Warum dasselbe Modell morgen andere Ergebnisse liefern kann, wie man das verhindert und wie man prüft, ob ein Modell fair und erklärbar entscheidet.], bild: "images/teil-4-reproduzierbarkeit.png")

#include "kapitel/08-reproducibility.typ"
#include "kapitel/09-responsible-ai.typ"

#teil("V", [ML-Systeme bauen], [Vom Notebook zum betriebenen System: wie die Patterns in Pipelines, Registries, Monitoring und Rollouts zusammenwirken und welche technische Schuld dabei typischerweise entsteht.], bild: "images/teil-6-ml-systeme.png")

#include "kapitel/11-ml-systeme.typ"

#teil("VI", [Fallstudien], [Drei durchgehende Beispiele mit lauffähigem Code: Ein Team beginnt jeweils mit einem naiven Notebook und verbessert es Schritt für Schritt. Jede Verbesserung wird gemessen, nicht behauptet.], bild: "images/teil-7-fallstudien.png")

#include "kapitel/12-fallstudie-churn.typ"
#include "kapitel/13-fallstudie-wartung.typ"
#include "kapitel/14-fallstudie-shop.typ"

#teil("VII", [Unterrichten und Üben], [Wie man die Patterns Studierenden ohne ML-Schwerpunkt vermittelt, typische Missverständnisse, die Verbindung zu den Praxisprojekten und ein Fundus an Übungen mit ausführlichen Lösungen.], bild: "images/teil-5-unterrichten.png")

#include "kapitel/10-lehre.typ"
#include "kapitel/15-uebungen.typ"

#anhang-label()
#counter(heading).update(0)
#set heading(numbering: "A.1")

#include "kapitel/a-spickzettel.typ"
#include "kapitel/b-glossar.typ"

#include "literatur.typ"

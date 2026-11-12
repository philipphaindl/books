#import "lib.typ": *

#set heading(numbering: none)
= Bevor es losgeht

Dieses Handbuch begleitet die Lehrveranstaltung _Generative AI in Research and Innovation_. Es ist für jemanden geschrieben, der die Themen der zehn Foliensätze unterrichten und Fragen dazu beantworten will, ohne eine Ausbildung in Statistik oder maschinellem Lernen mitzubringen. Es setzt deshalb nichts voraus außer Neugier, etwas Programmiererfahrung und die Bereitschaft, ein Beispiel durchzudenken.

Die Themen klingen technischer, als sie sind. Hinter fast allem steckt dieselbe einfache Frage: _Ein Sprachmodell hat mir ein Ergebnis geliefert. Woran erkenne ich, ob ich ihm trauen darf, und wie belege ich das gegenüber anderen?_ Ob das Modell Texte einordnet, Antworten benotet, Interviews zusammenfasst oder Fragen aus Dokumenten beantwortet, die Antwort hat immer dieselbe Form: einen Teil von Menschen prüfen lassen, den Unterschied zwischen Mensch und Modell sichtbar machen und ehrlich berichten, was man getan hat.

== Was dieses Buch anders macht

Es gibt zu dieser Lehrveranstaltung bereits ein ausführliches Handbuch mit Herleitungen und Formelsammlung (_LLMs als Forschungsinstrument_). Das hier ist die Fassung für den Einstieg:

- *Keine Formeln.* Wo eine Kennzahl vorkommt, steht, was sie misst, wie man ihren Wert liest und mit welchem Werkzeug man sie berechnen lässt. Rechnen muss das Werkzeug, verstehen musst du.
- *Erst das Bild, dann der Begriff.* Jedes neue Konzept beginnt mit einem Vergleich aus dem Alltag. Der Fachbegriff kommt danach und bleibt englisch, wenn er auf den Folien englisch ist.
- *Zahlenbeispiele statt Symbole.* Wenn eine Rechnung wirklich hilft, dann mit konkreten Zahlen und Grundrechenarten, Schritt für Schritt.
- *Umsetzung vor Theorie.* Welche Schritte, welche Werkzeuge, welcher Code, welche Fehler passieren in der Praxis.

Wer es danach genauer wissen will, findet im großen Handbuch zu jedem Kapitel die formale Fassung unter derselben Kapitelnummer.

== Aufbau

Die Kapitelnummern entsprechen den Foliensätzen: Kapitel 5 gehört zu Foliensatz 05.

- *Das Nötigste vorab:* zehn Begriffe aus der Statistik und rund um Sprachmodelle, die in jedem Kapitel wiederkehren, in Alltagssprache.
- *Teil I, Forschen mit Methode:* wie Forschung überhaupt zu belastbaren Aussagen kommt (Kapitel 1) und wie man etwas baut und dabei forscht (Kapitel 2).
- *Teil II, Das LLM als Werkzeug:* Prompts und Kontext (Kapitel 3) und die Rollen, die ein Sprachmodell in einer Studie spielen kann (Kapitel 4).
- *Teil III, Messen, Schließen, Bewerten:* das Modell als Annotator (Kapitel 5), saubere Schlüsse aus seinen Labels (Kapitel 6) und das Modell als Gutachter (Kapitel 7).
- *Teil IV, Qualität, Fairness, Nachvollziehbarkeit:* Verzerrungen messen (Kapitel 8), Systeme mit Dokumentensuche bewerten (Kapitel 9) und alles so aufsetzen, dass andere es wiederholen können (Kapitel 10).
- *Anhang:* Glossar und Literatur.

== Konventionen

Jedes Kapitel hat denselben Ablauf: ein Einstieg mit dem Problem, die Lernziele, dann die Abschnitte in der Reihenfolge der Folien, am Ende "Kurz gesagt" und ein Selbsttest mit Antworten. Dazwischen stehen farbige Kästen:

#alltag[Ein Vergleich aus dem Alltag, der die Idee trägt, bevor der Fachbegriff fällt.]

#begriff[Fachbegriff][Was der Begriff bedeutet, in ein bis drei Sätzen und ohne Formel.]

#beispiel(titel: [Durchgespielt])[Ein konkreter Fall mit echten Zahlen oder Texten.]

#fallstrick[Ein Fehler, der in der Praxis häufig passiert, und woran man ihn erkennt.]

#hoersaal[Eine Frage, die Studierende stellen könnten?][Eine Antwort in wenigen Sätzen, die du so geben kannst.]

Code steht in grauen Kästen und ist Python, weil auch die Notebooks der Lehrveranstaltung Python verwenden. Du musst ihn nicht ausführen, um das Kapitel zu verstehen. Er zeigt, wie wenig Code die meisten Schritte brauchen.

Zahlen aus Studien tragen eine Quellenangabe in eckigen Klammern. Angaben, die schnell veralten (Preise, Modellnamen, Versionen, Rechtslage), haben den Stand 11. November 2026 und gehören vor dem Semester geprüft.

#import "lib.typ": *

= Warum Messaging?

== Enge und lose Kopplung

#figure(
  grid(columns: (1fr, 1fr), column-gutter: 12pt,
    align(center)[#text(size: 7.5pt, weight: "bold")[Synchron: Aufrufkette] \
      #cetz.canvas(length: 1cm, {
        import cetz.draw: *
        kasten((0, 0), [`shop`], w: 1.7, h: 0.7, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
        kasten((2.9, 0), [`provisio-` \ `nierung`], w: 1.7, h: 0.9, bg: rgb("#FDF1EC"), col: c-accent, size: 7pt)
        kasten((5.8, 0), [`benach-` \ `richtigung`], w: 1.7, h: 0.9, bg: rgb("#FBEAEA"), col: c-red, size: 7pt)
        pfeil((0.85, 0), (2.05, 0)); pfeil((3.75, 0), (4.95, 0), color: c-red)
        content((2.9, -1.0), text(size: 6.8pt, fill: c-red)[fällt einer aus, scheitert die Bestellung])
      })],
    align(center)[#text(size: 7.5pt, weight: "bold")[Asynchron: über einen Broker] \
      #cetz.canvas(length: 1cm, {
        import cetz.draw: *
        kasten((0, 0), [`shop`], w: 1.7, h: 0.7, bg: rgb("#EAF1FB"), col: c-blue, size: 7.3pt)
        kasten((2.9, 0), [Broker], w: 1.7, h: 0.7, bg: rgb("#E7F4F2"), col: c-teal, size: 7.3pt)
        kasten((5.8, 0.55), [`provisionierung`], w: 2.3, h: 0.6, bg: rgb("#FDF1EC"), col: c-accent, size: 6.8pt)
        kasten((5.8, -0.55), [`benachrichtigung`], w: 2.3, h: 0.6, bg: rgb("#FDF1EC"), col: c-accent, size: 6.8pt)
        pfeil((0.85, 0), (2.05, 0)); pfeil((3.75, 0.1), (4.65, 0.5)); pfeil((3.75, -0.1), (4.65, -0.5))
        content((2.9, -1.2), text(size: 6.8pt, fill: c-gitea.darken(10%))[Broker hält Nachrichten, bis Empfänger bereit sind])
      })],
  ),
  caption: [Links hängt der Erfolg an allen Beteiligten, rechts nur am Broker.],
)

Bei direkten Aufrufen muss jeder Dienst in dem Moment erreichbar sein, in dem ein anderer ihn braucht. Ein Broker entkoppelt in drei Dimensionen: *zeitlich* (der Empfänger kann später verarbeiten), *räumlich* (der Sender muss nicht wissen, wer empfängt und wie viele es sind) und *in der Last* (Lastspitzen werden gepuffert statt weitergereicht).

Der Preis: Das Ergebnis steht nicht sofort fest, Fehler werden später sichtbar, und die Frage "wurde die Nachricht verarbeitet?" braucht eigene Antworten (Kapitel 2 und 7). Für Abfragen, auf deren Antwort ein Benutzer wartet, bleibt ein direkter API-Aufruf oft die bessere Wahl.

== Die vier Grundmuster

#table(columns: (auto, 1fr, auto),
  [Muster], [Verhalten], [Beispiel],
  [*Queue* (Arbeitswarteschlange)], [Jede Nachricht wird von *genau einem* von mehreren gleichartigen Konsumenten verarbeitet (_competing consumers_). Skalierung durch mehr Konsumenten.], [Provisionierungsaufträge auf drei Worker verteilen],
  [*Publish/Subscribe*], [Jede Nachricht erreicht *alle* interessierten Empfängergruppen.], [Bestellung an Provisionierung *und* Benachrichtigung],
  [*Stream* (Log)], [Nachrichten werden dauerhaft in Reihenfolge gespeichert. Konsumenten lesen ab einer Position und können zurückspulen.], [Ereignishistorie, neue Dienste lesen alte Ereignisse nach],
  [*Request/Reply*], [Anfrage über den Broker, Antwort auf einer temporären Rückadresse.], [Preis abfragen, ohne die Adresse des Preisdienstes zu kennen],
)

In der Praxis werden die Muster kombiniert: Ein Ereignis wird per Pub/Sub an mehrere Gruppen verteilt, innerhalb jeder Gruppe teilen sich mehrere Instanzen die Arbeit wie in einer Queue.

== Befehle und Ereignisse

Nachrichten sind entweder *Befehle* oder *Ereignisse*, und der Unterschied prägt das Design:

#table(columns: (auto, 1fr, 1fr),
  [], [Befehl], [Ereignis],
  [Bedeutung], ["Tu das!"], ["Das ist passiert."],
  [Name], [Imperativ: `provisionierung.starten`], [Vergangenheit: `bestellung.eingegangen`],
  [Empfänger], [genau ein zuständiger Dienst], [beliebig viele, dem Sender unbekannt],
  [Rechte], [Wer darf diesen Auftrag erteilen?], [Wer darf behaupten, dass das passiert ist?],
)

Die letzte Zeile ist sicherheitsrelevant: Ein gefälschtes Ereignis `zahlung.eingegangen` kann eine Lieferung auslösen, ohne dass bezahlt wurde. Wer welche Ereignisse veröffentlichen darf, ist deshalb eine der zentralen Fragen in Teil III.

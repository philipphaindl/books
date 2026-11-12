# Typografischer Vereinheitlichungsdurchgang (Zahlen)

Stand: 11. November 2026. Betroffen: kap01, kap02, kap05-kap10 und loesungen-01/02/05-10. Nicht angefasst: kap00, kap03, kap04, loesungen-03/04, anh-*.

Konvention: Dezimalpunkt (0.85), auch im Fließtext und in Abbildungslabels. Tausendertrennung ab 10 000 mit U+202F (Markup) bzw. `thin` (Mathemodus), darunter ohne Trenner (1573). Prozent: "93 %" (Leerzeichen vor %).

Werkzeug: Kandidatensuche per Python mit einem einfachen Typst-Moduserkenner (Markup/Mathe/Code/String/Raw/Kommentar); Code-Blöcke, Inline-Raw, Kommentare und Code-Argumente (Koordinaten) ausgenommen. Die Treffer mit Punkt-Tausendern wurden einzeln im Kontext entschieden. Prüfung: jede Datei über `_fmt.typ` (Kopf von main.typ + Kapitel + Lösungen + literatur.typ) kompiliert, alle fehlerfrei; Stichproben im PDF angesehen.

## Änderungen je Datei

| Datei | Änderungen | Art |
|---|---:|---|
| kap01 | 5 | Punkt-Tausender (1.763 -> 1763, 15.000 -> 15 000, $n = 10.000$ -> `10 thin 000`) |
| kap02 | 92 | 87 Dezimalkommas, 2 Punkt-Tausender, 3 Abbildungs-Achsen (`.replace(".", ",")` entfernt) |
| kap05 | 599 | 350 Dezimalkommas im Text/Tabellen, 219 `0","85` im Mathemodus, 23 Punkt-Tausender, 2 Zahlen ab 10 000 im Mathemodus, 5 Achsenlabels |
| kap06 | 112 | 63 Dezimalkommas, 49 Tausender (`50~000` -> 50 000, `2~361` -> 2361, `9 thin 500` -> 9500) |
| kap07 | 25 | 24 Punkt-Tausender, 1 Intervall-Trenner |
| kap08 | 39 | Punkt-Tausender |
| kap09 | 471 | 264 Dezimalkommas, 169 `"0,85"` im Mathemodus (-> `0.85`), 23 Punkt-Tausender, 8 Intervalle `["a"; "b"]` -> `[a, b]`, 7 Abbildungslabels |
| kap10 | 276 | 132 Dezimalkommas, 107 `0","85` im Mathemodus, 35 Punkt-Tausender, 2 Abbildungs-Helfer (`dez()` gibt jetzt Punkt aus) |
| loesungen-01 | 0 | nur Dezimalzahlen, bereits korrekt |
| loesungen-02 | 5 | Dezimalkommas |
| loesungen-05 | 95 | Mathe-Dezimalkommas, 1 Punkt-Tausender, 15750 -> `15 thin 750` |
| loesungen-06 | 1 | Dezimalkomma |
| loesungen-07 | 1 | 3.000 -> 3000 |
| loesungen-08 | 2 | 1.600/2.000 -> 1600/2000 |
| loesungen-09 | 77 | Mathe-Strings, Dezimalkommas, 2 Punkt-Tausender, 1 Intervall |
| loesungen-10 | 48 | Mathe-Dezimalkommas, 8 Punkt-Tausender |

Prozentangaben waren in allen Dateien bereits einheitlich "93 %"; keine Änderung.

## Zweifelsfälle und bewusst unverändert

- kap08: $t(33.599)$ und $t(26.528)$ als Freiheitsgrade gelesen (33 600 Prompts -> df = 33 599) und zu `33 thin 599` bzw. `26 thin 528` geändert. Nicht im Dossier belegt; bitte gegenprüfen.
- kap08: $beta = -16.260$, $beta = -1.141$ und "1.047 mit Feedback-Training" sind Dezimalzahlen (Dossier: "-16.260", "1.047") und bleiben. "5.956 Anfragen" ist laut Dossier "5,956" -> 5956.
- kap01: "1.573" in der Cohen-Tabelle (Differenz zweier r) als Stichprobengröße gelesen -> 1573. 1.427, 1.960 usw. sind Dezimalzahlen.
- kap07: "rund 1.560 rein menschliche Labels" (= 1000 * 1.56) -> 1560. $e_5 approx 1.163$ usw. bleiben Dezimalzahlen.
- kap09: "2,468-mal schneller" als Dezimalzahl gelesen -> 2.468.
- kap02/loesungen-02, kap06 Tabelle 1.423/1.270/1.087, loesungen-06/07: Werte der Form x.yyy sind Dezimalzahlen und bleiben.
- ISO/IEC-Normnummern (25000, 25010, 25059, 42001 usw.) nicht getrennt.
- kap05: Matrixnotation `[[45,5],[5,45]]` und `ICC(1,1)` unverändert (Komma ist dort Listentrenner). kap02: "[0,1]-Skala" (Intervall) unverändert.
- Wörtliche englische Zitate ("over 80%", "50% of the time") und der Literaturtitel "15,992 test statistics" unverändert.
- Code-Blöcke, Inline-Code, Versionsnummern (5.5, 3.5.0), Jahreszahlen, DOIs und Labels nicht angefasst.

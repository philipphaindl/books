# Review Kapitel 6 - Valide statistische Inferenz mit LLM-Labels

Stand: 11. November 2026. Geprüft: `kap06-valide-inferenz.typ`, `loesungen-06.typ` gegen `knowledge-base/06-valid-inference-llm-labels/dossier.md` (inkl. `verification_report.md`) und `source/book/ch6.tex`. Testdatei: `_review-06.typ` (Kopf aus `main.typ`, 40 Seiten, kompiliert fehlerfrei).

## Mathematik (alles nachgerechnet)

Schritt für Schritt geprüft und korrekt:
- Bias-Varianz-Zerlegung, Konsistenz, ZGS/Slutsky, Delta-Methode, Sandwich-Formel (inkl. HC0 für OLS).
- Überdeckungsformel Phi(z-k)-Phi(-z-k): k=1 -> 0.830, k=2 -> 0.484, k=4 -> 0.021; alle 19 Stützpunkte der Abb. "Mehr Daten" mit scipy reproduziert.
- Verzerrter Anteil (E[Yhat] = s theta + r(1-theta), Nullstelle theta = r/(r+1-s)), Youden-Abschwächung (s-r), Satz zum differenziellen Fehler (0.300/0.370, Steigung 0.070, -53 %).
- Abschwächungsbias: klassischer Messfehler Var(X)/(Var(X)+Var(U)); misklassifizierter binärer Regressor beta(PPV+NPV-1), Beispiel 0.794 + 0.955 - 1 = 0.749.
- PPI: Unverzerrtheit, Varianz sigma_f^2/N + sigma_{f-Y}^2/n, sigma_{f-Y}^2 = P(f != Y) - Delta^2, Handrechnung (SE 0.01762, Breite 0.0691).
- PPI-OLS (Gruppenbeispiel 0.070 - (-0.080) = 0.150), ökonometrische Form.
- PPI++: Varianz in lambda, lambda* = c/((1+r) sigma_f^2), Minimum sigma_Y^2/n (1 - rho^2 N/(n+N)), Bedingung lambda* > 1/2, allgemeines lambda* reduziert sich korrekt auf den Mittelwert; Handrechnung Cov 0.1453, rho 0.669, lambda* 0.626, Faktor 0.574, Breite 0.0614.
- Effektive Stichprobengröße n(n+N)/(n+(1-rho^2)N), Schranke n/(1-rho^2) (1.33/1.81/5.26), n_eff = 870; Hörsaalrechnung 469/781/833.
- Kostenformel: Faktor 0.658 bei gamma = 0.01; 604 + 0.01 * 5416 = 658.16.
- Aktive Inferenz: Unverzerrtheit, Varianzformel, Wurzelregel per Cauchy-Schwarz, Beispiel (pi = 0.061/0.192, Budget 0.1, Varianzreduktion 22 %).
- DSL: Unverzerrtheit des Pseudo-Outcomes, doppelte Robustheit, Var(Ytilde), Gleichheit mit PPI für g = Q und konstantes pi.
- Simulationsskript der Wissensbasis neu ausgeführt: Tab. 4 (Exp. 1) und Tab. 2 (Exp. 2) Ziffer für Ziffer identisch; Daten der Abb. 2 (Seed 3, 25 Läufe) reproduziert (0/25 bzw. 23/25 Überdeckung).
- Selbsttest-Lösungen 1-12 nachgerechnet (u. a. 0.125/+0.025/0.20; 0.40 +- 0.0346, klassisch +- 0.0484, 28 % schmaler; n_eff 583, Schranke 588, rho = 0.711; 1.645/1.960 = 0.839).

Keine mathematischen Fehler gefunden.

## Korrekturen

Fachlich (4):
1. Rogan-Gladen-Zuschreibung entfernt (in keiner Quelle der Wissensbasis belegt); die Inversion bleibt als elementare Umformung.
2. "macht Tests konservativ" bei Abschwächung präzisiert: Test behält Niveau, verliert Teststärke.
3. "unabhängig formuliert" (Ludwig et al. vs. PPI) gestrichen, nicht belegt.
4. Boyeau et al. "up to 50%": Fundort (arXiv-v2-Zusammenfassung, nicht PMLR) ergänzt, gemäß Verifikationsbericht.

Mathematik/Darstellung von Zahlen (3):
5. Kostenbeispiel: Annahme c_X = 0 ergänzt und Kostenaufschlüsselung 604 + 0.01 * 5416 angegeben.
6. Tab. 3 (Landkarte): "Die ersten sieben sind Residuenkorrekturen" schloss Plug-in ein; korrigiert.
7. Abb. 6: "lambda* nahe 1" bei rho = 0.9 durch den Wert 0.86 ersetzt.

Darstellung/Sprache (7):
8. Abb. 8: gelbes Rechteck lag über den Kurven (verdeckte sie zwischen 0.75 und 0.85); Zeichenreihenfolge korrigiert.
9. Abb. 3: Beschriftung "Bias +0.057" lag weit vom Punkt entfernt auf der a = 0.70-Linie; mit Führungslinie neben den Punkt versetzt.
10. Abb. 5: Beschriftung von Delta-hat überlappte die gestrichelte Linie; versetzt.
11. ppi_power-Ausgabe brach im Kasten um; gekürzt, ppi_corr als Kommentarzeile.
12. "vier Stichprobengrößen ... diese fünf Zahlen" vereinheitlicht; Grammatikfehler im ppi_corr-Satz behoben.
13. Für die Lehre: Demodauer an Wissensbasis angepasst (20 min); "Temperatur 0" mit Hinweis auf Kapitel 10 (API nimmt Parameter teils nicht mehr an).
14. Lösungsdatei: unbelegte Aussage ("mehr als viele Annotationsaufgaben erreichen") durch Vergleich mit dem Kapitelbeispiel ersetzt; Lösung 10 an den Schätzer @k06-eq-ppi angeglichen; echte Gleichungsverweise ergänzt (@k06-eq-prevbias, -ppi-ci, -lamstar, -neff, -pistar, -dsl-var, -ppi); im PDF als (6.x) aufgelöst.

## Geprüft ohne Befund

Alle Studienzahlen gegen das Dossier (Egami Tab. 3/Abb. 1a/Abb. 2, Angelopoulos Tab. 2 und Anh. G, Fong & Tyler Tab. 1-2, TeBlunthuis, Baumann, Ludwig, Gligorić Tab. 1, Zrnic & Candès, Ji v2, Mehrotra, Nakamura v2, Halterman, Chew, ppi_py-Signaturen/README). Lehrbuchaussagen (n > 30, große Stichproben machen Triviales signifikant, Teststärke 0.80) in ch6.tex belegt. Keine "—"/"–"/"--" in den Kapiteldateien.

## Offene Punkte

- Literatur erscheint in der Testdatei numerisch ([1], [2]); Zitierstil ist globale Sache von `literatur.typ`/`main.typ`.
- DSL-Flussdiagramm (Abb. 10): Pfeil zwischen "Kreuzanpassung" und "Pseudo-Outcome" sehr kurz; lesbar, aber eng.
- `dsl()`-Signatur mit Standardwerten bleibt laut Wissensbasis ungeprüft (im Text bereits so gekennzeichnet).
- Seed für rho-hat = 0.6675 im Kostenbeispiel nicht dokumentiert (im Text vermerkt).

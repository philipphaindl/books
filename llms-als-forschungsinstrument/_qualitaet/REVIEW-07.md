# Review Kapitel 7 "LLM-as-a-Judge" (unabhängiges Review, 11.11.2026)

Geprüft: `kap07-llm-as-a-judge.typ`, `loesungen-07.typ` gegen Dossier und `verification_report.md` (KB 07) sowie Lehrbuch `ch8.tex`. Testdatei: `_review-07.typ` (41 Seiten, kompiliert fehlerfrei). `main.typ` wurde nicht kompiliert.

## Befunde und Korrekturen (16)

### Mathematik
1. **Dorner-Schranke, symmetrischer Fall (Beweisskizze):** Monotonie von rho^2 in a war nur "numerisch auf einem Gitter geprüft". Ersetzt durch einen analytischen Beweis in vier Schritten mit expliziten Annahmen (A1 binär, 0 < b < 1, 0 < c < 1; A2 p = q = a, 0.5 <= a <= b, erzwingt b >= 0.5; A3 Schranke für optimales lambda und N -> unendlich). Umparametrisierung u = 2a - 1, w = 2b - 1 liefert die neue Gleichung `k07-eq-rho-sym`: rho^2 = (1 - w^2) u^2 / (1 - w^2 u^2), streng wachsend in u^2; am Rand rho^2 = w^2/(1 + w^2) < 1/2. Der Gleichheitsfall b = 1 ist durch A1 ausgeschlossen (vorher als "Grenzfall" mit Gleichheit formuliert). Allgemeiner Fall (p != q) zusätzlich numerisch geprüft: max rho^2 unter 0.5 <= AG <= b auf 300x300x100-Gitter = 0.494 < 0.5, konsistent mit Thm. 6. Herleitung von Gl. (7.25) (Cov = b(1-b)(p+q-1)) nachgerechnet: korrekt.
2. **Effizienzschranke (PPI):** Beweis korrekt; ergänzt, dass lambda* als bekannt unterstellt ist (PPI++ schätzt es, asymptotisch gleich) und dass für endliches N der Term lambda^2 Var(s~)/N den Faktor verkleinert.
3. **Bradley-Terry:** "Transitivität im Erwartungswert: xi_A > xi_B und xi_B > xi_C => xi_A > xi_C" war trivial/unpräzise; ersetzt durch starke stochastische Transitivität mit Begründung und Hinweis, dass zyklische Präferenzen nicht abbildbar sind. Annahme unabhängiger Störterme über Duelle explizit gemacht. "Konkav, Optimum eindeutig" präzisiert zu streng konkav bei fixiertem xi_1 und verbundenem Vergleichsgraphen. Elo-Bemerkung um Basis 10/Faktor 400 ergänzt. Gumbel-Herleitung, Gradient, Bedingung erster Ordnung und Rechenbeispiel (xi_B = -0.417, xi_C = -0.834; 0.603/0.603/0.697; Siege 130/100/70) mit scipy nachgerechnet: korrekt.
4. **Binomialtest auf Positionsverzerrung:** Die Behauptung "Test auf Paarebene ist konservativer" ist falsch im Allgemeinen. Mit c konsistenten und f, g inkonsistenten Paaren ist die Urteilsstatistik das sqrt(2(f+g)/(c+f+g))-Fache der Paarstatistik: zu liberal bei c < f + g, zu konservativ bei c > f + g. Text, Selbsttestfrage 5 ("vorzuziehen" statt "konservativer") und Lösung 5 korrigiert (Vorzeichen-/exakter McNemar-Test auf inkonsistenten Paaren).
5. **EvalGen-Alignment:** "F1-Maß, in dem 1 - FFR die Rolle der Präzision übernimmt" korrigiert: 1 - FFR ist die Spezifität, die Formel ist das harmonische Mittel aus Sensitivität und Spezifität.
6. **BPC:** Varianzreduktion um Faktor 2k nur bei unabhängigem Rauschen; ergänzt.
7. **Best-of-N:** "wächst etwa wie sqrt(2 ln N)" -> "asymptotisch" (für N = 50: 2.25 vs. 2.80).

### Fakten und Fassungen
8. **Thakur et al.:** Skalen vereinheitlicht (pi = 0.962, 0.59, "über 0.80", "rund 0.08" statt 96.2, 59, 80, "8 Punkte"); "Scott's-Pi-Punkte" in Abschn. 7.10 ersetzt. Fassungshinweis konkretisiert: Zahlen aus GEM-Fassung (Scotts pi); überholte arXiv-v2-Werte (kappa 0.62 für Llama-3 8B, bis 20 Punkte, P+ 0.36-0.94, contains 0.98) benannt. Lösung 2 angepasst.
9. **Krumdick et al.:** als arXiv v2 gekennzeichnet, v1-Werte (0.14/0.28/0.80) genannt.
10. **RM-R1:** Werte als arXiv v3 (entspricht ICLR-Zusammenfassung) gekennzeichnet; v1 nannte 92.9.
11. **LMArena-Gegenrede:** Die 8.8 % standen unerklärt im Text; jetzt als die von LMArena bestrittene Zahl gekennzeichnet, die in der ausgewerteten arXiv-Fassung nicht lokalisiert ist. Ergänzt, dass Singh et al. den 112-%-Wert selbst auf Arena-Hard angeben (strittig ist die Aussagekraft, nicht die Messung), dass auch die "rund 100 Punkte" eine Simulation sind und dass die NeurIPS-Fassung abweichen kann (verification_report CONSIDER 5). Damit sind beide Seiten symmetrisch eingeordnet.
12. **Agent-as-a-Judge:** "1.297.50 US-Dollar" (gemischte Trennzeichen) -> 1297.50; Locator "Tab. 4" für Memory/Planning entfernt (laut Verifikation Abschn. 4.1, Anh. K).

### Darstellung
13. Abb. 16 (tau-Schranke): Beschriftung "1.56 bei rho = 0.6" lag auf der gestrichelten tau = 2-Linie; verschoben.
14. Beweisschritte als eigene Absätze gesetzt; Abb. 17 verweist jetzt auf die neue Gleichung.

### Gleichungsverweise in der Lösungsdatei
15. Alle textlichen Verweise ("Formel in @k07-meta", "nach der Formel für rho^2 (@k07-grenzen)", "Formel für e_N in @k07-arena" usw.) durch echte Referenzen ersetzt: `k07-eq-po`, `-kappa`, `-pe-cohen`, `-pe-scott`, `-leniency`, `-geval`, `-bpc`, `-maj`, `-tau`, `-ppi`, `-ag`, `-rho-binaer`, `-rho-sym`, `-bt`, `-bt-ll`, `-emax`, `-conflict`. Im PDF als (7.x) aufgelöst.
16. Lösung 10 zusätzlich mit der geschlossenen Form (w = 0, u = 0.9) verknüpft.

## Nachgerechnet (python3, alle korrekt)
Kappa/Pi/P+ (0.529, 0.524, 0.75; Lösung 1: 0.474, 0.467), Kappa-Paradoxon (0.70, 0.457, 0.307), G-Eval 3.70 und 3.4, EvalGen 0.665, Binomialtests (p = 0.021, CI [0.517; 0.715]; p = 0.082), BPDE 1.011, Condorcet 0.896/0.942/0.784/0.352, tau 1.5625, 1.64, 5.09, 5.26, 1.16, MCC 0.545 -> tau 1.42, BT-Beispiel, sigma(0.5) = 0.622, e_N-Tabelle (0.5642 ... 2.2491), Best-of-5 23 Punkte, Separierbarkeit 86.7 %, Agent-as-a-Judge 2.36 %/2.28 %. Alle zitierten Zahlen kommen im Dossier vor; Lehrbuchaussagen (`@haindl2027research`) gegen ch8.tex geprüft (zirkuläre Validierung, Operationalisierung, "persist at any scale", U-Muster, Kulkarni-Meta-Evaluation, Rangfolgen konsistenter): korrekt.

## Offene Punkte
- Die 8.8 % (Anteil offener Modelle) sind in Singh et al. nicht lokalisiert; NeurIPS-Camera-ready von Singh et al. und COLM-Fassung von Dubois et al. wurden in der Wissensbasis nicht mit arXiv verglichen (im Text gekennzeichnet).
- Der allgemeine Fall von Dorner Thm. 6 (p != q) ist im Buch nur zitiert und numerisch plausibilisiert, nicht bewiesen.
- G-Eval Fluency (0.455 vs. 0.506) bleibt versionsabhängig (im Text gekennzeichnet).
- Abb. 7 (Kappa-Paradoxon): Kappa- und Pi-Kurve liegen fast aufeinander; inhaltlich korrekt, optisch schwer zu trennen. Nicht geändert.
- Teil-Label in `_review-07.typ` ist nur für die Testdatei gesetzt.

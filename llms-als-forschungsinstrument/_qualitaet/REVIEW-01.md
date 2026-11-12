# Review Kapitel 1 - Forschungsmethoden: qualitativ, quantitativ, gemischt

Unabhängiges Review nach REVIEW_PLAN.md, 11. November 2026. Geprüft: `kap01-forschungsmethoden.typ`, `loesungen-01.typ` gegen Dossier und Verification Report von `01-research-methods` sowie Lehrbuch ch1-ch4, ch6 (Hauptquelle für Definitionen und Rahmenmodelle). Testdatei: `_review-01.typ` (41 Seiten, fehlerfrei kompiliert).

## Geprüft und bestätigt (ohne Änderung)

- **Power-Analyse:** Herleitung der Normalapproximation (δ = d·sqrt(n/2), Vernachlässigung des zweiten Schwanzes, Auflösen nach n) und exakte Power über die nichtzentrale t-Verteilung korrekt. Nachgerechnet: 62.79 (Approximation), exakt 394/64/26, statsmodels 63.77 bzw. 393.4/25.5, Power 0.338 bei n = 20, 0.51 bei n = 5 und d = 1.43; alle 33 Kurvenpunkte von Abb. 7 stimmen.
- **Effektstärken:** d (Beispiel 77.6/72.0, 18.3/12.5, s_p 3.924, d 1.427, t 2.256, p 0.054, SE 0.708, KI 0.04 bis 2.82), t-d-Identität, d_z = t/sqrt(n) (auch gegen Notebook: d_z 1.042 vs. d_av 0.331), η_p² = 0.224, r -> d (0.881, 0.402, 0.516, 0.201), U1/U3/OVL (85/67/53 %, 58/69/79 %, 92/80/69 %).
- **Cohen-Tabellen:** Tab. 1 alle acht Indizes, Tab. 2 korrekt mit Gesamt-N für Signifikanz von r (783/85/28) und Vorzeichentest (783/85/30), pro Gruppe für die übrigen; entspricht der Korrektur im Verification Report.
- **SCORE 2026:** Tyner (274/164/54, 99.6 %, 151 = 55.1 % [49.2-60.9], 49.3 % [43.8-54.7], 42.5-63.1 %, r 0.25 -> 0.10, 13 Kriterien 28.6-74.8 %), Aczel (100 Studien, ≥ 5 Reanalysierende, 34/57 %, 74/24/2 %), Miske (600/62, 144 = 24.0 %, 143 geprüft, 53.6 %, 73.5 % mit KIs). Die nur per Pressemitteilung belegte Daten-und-Code-Zahl wird nicht verwendet.
- Sättigungsmodell (λ = 0.231, C_max = 106.7, n_0.9 = 10.0, n_0.95 = 13.0), PPV inkl. Ioannidis Tab. 4 (0.850/0.231/0.204/0.00104), FWER, Bonferroni/Holm, OSC, Simmons, Silberzahn, Steegen, Stol, Guest, Hennink, Kapoor, REFORMS, Baltes gegen Dossier.
- Alle Selbsttest-Lösungen nachgerechnet (64/0.196/11.7; d 1.897, t 2.324, p 0.081; 233.5 -> 234, exakt 235; d_z 0.495; PPV 0.714/0.818; FWER 0.460, 0.00417).
- Lehrbuch-Abgleich: Forschungsdefinition, Forschung vs. Suche, Hierarchie, Theorie/Modell/Framework, empirische Typen, Designwahl-Baum, Experimentbedingungen, Survey-Rücklauf, Vertrauenswürdigkeitsstrategien, Ledger, Überlappungswerte, p-Wert, Fehlerarten, ein-/zweiseitige Tests, Korrekturverfahren.

## Korrekturen

### Fachlich (5)
1. Abb. 1 (Hierarchie): Beispiele an das Lehrbuch angepasst (Paradigmen: Positivismus, Konstruktivismus, transformatives Paradigma, Pragmatismus statt Postpositivismus/kritischer Realismus; Instrumente um Messskala ergänzt); Caption kennzeichnet den Prompt als Ergänzung dieses Buchs.
2. Paradigmatische Passung: fehlende Zuordnung "transformativ -> Aktionsforschung" und der Satz "Paradigma diktiert die Methode nicht" aus ch2 ergänzt.
3. SCORE 82.4 %: Die Behauptung "stammen aus den ungerundeten Medianen" war nicht belegt (Verification Report CONSIDER 11); jetzt als Vermutung gekennzeichnet, Zahl als Angabe der Arbeit.
4. Abb. 12 (Mixed-Methods-Designs): Fallauswahl im erklärend sequenziellen Design war als _building_ beschriftet; nach Fetters et al. ist das _connecting_ (Fragenableitung = _building_). Caption zu den gefüllten Knoten präzisiert.
5. Lösung 12: Die aufgezählten Replikationskriterien wurden SCORE zugeschrieben, stammen aber aus OSC 2015; jetzt korrekt zugeordnet. Zusätzlich Jowsey et al. als Positionspapier statt "offener Brief, unterzeichnet" (Dossier: Positionspapier mit Braun und Clarke als Mitautorinnen).

### Mathematisch (3)
1. Lösung 6: Aussage "d_z kann größer oder kleiner sein" mit der Beziehung d_z = d_av / sqrt(2(1-ρ)) präzisiert (größer genau bei ρ > 0.5).
2. Bonferroni-Beweis: Fehlschluss "deshalb konservativ, wenn positiv korreliert" umformuliert.
3. Abweichung 393 vs. 394: als Vermutung gekennzeichnet, ungerundeter statsmodels-Wert 393.4 ergänzt.

### Darstellung (3)
1. Abb. 3 (Sättigung): Beschriftung C_max lag auf der Kurve, n_0.9 auf dem Bandbreitenbalken, "6 Int." kreuzte die 90-%-Hilfslinie; alle drei verschoben.
2. Abb. 6 (Überlappung): Beschriftung "Überlappung 85 %" stand unter einer Fläche, die den Überlappungskoeffizienten (92 %) zeigt; jetzt "1 - U1 = 85 %", Legende und Caption eindeutig.
3. Lösungsdatei: echte Gleichungsverweise ergänzt (@k01-eq-ns, @k01-eq-d, @k01-eq-dt, @k01-eq-dz).

## Offene Punkte

- Tab. 4: "1.573" (Tausenderpunkt) neben Dezimalpunkten im Buch ist mehrdeutig; buchweite Konvention klären (z. B. schmales Leerzeichen).
- Selbsttest-Kasten: Frage 12 rutscht allein auf eine neue Seite; im Gesamtbuch erneut prüfen, da der Umbruch vom Vorlauf abhängt.
- Rechenbeispiel 1.17 (Cohens d) wird über einen Seitenumbruch getrennt; unkritisch.
- Unverändert aus dem Verification Report: SCC-Bedrohungsnamen jenseits der ersten fünf nur sekundär belegt (in der Caption von Tab. 6 bereits vermerkt); Buckley-Volume offen.
- Wortumfang des Kapitels nicht gegen die 14.000-Wörter-Vorgabe geprüft (nicht Teil des Review-Auftrags).

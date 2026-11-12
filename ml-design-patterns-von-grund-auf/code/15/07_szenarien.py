"""Zahlen zu den Szenarien K1 bis K3. Alle Eingangsgrößen sind Annahmen der Aufgabe, keine Messwerte.

Start: uv run --with scikit-learn --with pandas --with numpy python 07_szenarien.py
"""
import math

# --- K1: Betrugserkennung --------------------------------------------------------------------------------------
print("K1  Betrugserkennung")
n, rate = 40_000_000, 0.001
betrug = n * rate
print(f"Betrugsfälle am Tag: {betrug:,.0f}; ein Modell, das nie Alarm schlägt: Genauigkeit {1 - rate:.3%}")
print(f"Das bisherige Modell: Recall 8 % -> {betrug * 0.08:,.0f} gefunden, {betrug * 0.92:,.0f} übersehen")
euro_je_abfrage = 0.0005
print(f"Teure Abfragen für alle: {n * euro_je_abfrage:,.0f} Euro am Tag")
durch = 0.05
print(f"Cascade, Stufe 1 lässt {durch:.0%} durch: {n * durch:,.0f} Zahlungen, {n * durch * euro_je_abfrage:,.0f} Euro am Tag")
r2, ziel = 0.90, 0.85
print(f"Soll der Gesamt-Recall {ziel:.0%} erreichen, braucht Stufe 1 bei r2 = {r2:.0%} einen Recall von {ziel / r2:.4f}")
r1, fpr2 = 0.95, 0.001
tp = betrug * r1 * r2
fp = (n * durch - betrug * r1) * fpr2
print(f"Mit r1 = {r1:.0%}: Treffer {tp:,.0f}, Fehlalarme {fp:,.0f}, Precision {tp / (tp + fp):.4f}, "
      f"Gesamt-Recall {r1 * r2:.3f}, Alarme am Tag {tp + fp:,.0f}")

# --- K2: Röntgen-Triage ----------------------------------------------------------------------------------------------
print("\nK2  Röntgen-Triage")
patienten, bilder = 3_200, 11_840
print(f"Aufnahmen je Patient im Mittel: {bilder / patienten:.1f}")
for k in (1, 2, 4, 6):
    print(f"  Patient mit {k} Aufnahmen steht bei zufälliger 80/20-Aufteilung auf beiden Seiten: {1 - 0.8 ** k - 0.2 ** k:.4f}")
print(f"Test bei Aufteilung nach Patienten (20 %): rund {0.2 * patienten:.0f} Patienten, rund {0.2 * bilder:.0f} Aufnahmen")
print(f"Uneinigkeit bei 22 %: {0.22 * bilder:,.0f} Aufnahmen als Klasse \"unklar\"")
print(f"Treffen drei Radiologen mit je 85 % Zustimmung zur Mehrheit: alle einig {0.85 ** 3 + 0.15 ** 3:.4f}")

# --- K3: Smart Meter ---------------------------------------------------------------------------------------------------
print("\nK3  Smart-Meter-Prognose")
zaehler, je_tag = 1_500_000, 96
print(f"Messwerte am Tag: {zaehler * je_tag:,}")
print(f"Zustand für ein 24-Stunden-Fenster (96 Werte, float64) je Zähler: {je_tag * 8} Byte, gesamt {zaehler * je_tag * 8 / 1e9:.2f} GB")
print(f"Zustand, wenn nur Summe und Anzahl geführt werden (zwei Zahlen): {zaehler * 16 / 1e6:.0f} MB")
print(f"Nachts bewerten: {zaehler * je_tag:,} Prognosen; bei 4 ms je Einzelaufruf wären das {zaehler * je_tag * 0.004 / 3600:.0f} Stunden")
print(f"Gleiches Fenster zentriert statt rückwärts: nutzt {je_tag // 2} Werte aus der Zukunft des Prognosezeitpunkts (24 h Fenster)")

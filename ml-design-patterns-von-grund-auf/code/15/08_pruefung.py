"""Prüft die Zahlen des Kapitels, die in den Skripten 01 bis 07 nicht ohnehin ausgegeben werden.

Start: python 08_pruefung.py (nur Standardbibliothek)
"""
import math


def pruefe(name, wert, soll, toleranz):
    ok = abs(wert - soll) <= toleranz
    print(f"{'ok ' if ok else 'FEHLER'} {name}: {wert:.4f} (erwartet {soll})")
    assert ok, name


# D3
pruefe("Fahrten je Zelle bei 1 104 Zellen", 1_000_000 / (2 * 24 * 23), 906, 0.5)
pruefe("Zellen Wochentag x Stunde x Bezirk", 7 * 24 * 23, 3864, 0)
# P4
pruefe("Recall Stufe 1 für Gesamt-Recall 0,88", 0.88 / 0.90, 0.978, 0.001)
pruefe("Betrug von Stufe 1 aussortiert", 1000 - 960, 40, 0)
pruefe("Betrug von Stufe 2 übersehen", 960 - 864, 96, 0)
# P5
pruefe("Break-even-Wahrscheinlichkeit", 5 / 205, 0.0244, 0.0001)
# T2
pruefe("Anteil des Optimums an 60 Stunden", (3 / math.sqrt(2) + 1.5 * math.sqrt(2)) / 60, 0.07, 0.002)
# S2
pruefe("Faktor Einzelaufrufe zu Batch", 802 / 2.02, 400, 5)
# S7
n = ((1.96 * 0.3 + 0.84 * math.sqrt(0.87 * 0.13)) / 0.03) ** 2
pruefe("Stichprobe mit gerundeten Quantilen", n, 842, 1)
pruefe("Tage bis zur Stichprobe", 843 / 100 + 30, 38.4, 0.05)
pruefe("95-%-Intervall bei n = 100 in Punkten", 196 * math.sqrt(0.9 * 0.1 / 100), 5.9, 0.05)
# R1
alter = [62, 58, 66]
m = sum(alter) / 3
s = math.sqrt(sum((a - m) ** 2 for a in alter) / 3)
pruefe("Standardabweichung der Anfrage", s, 3.27, 0.005)
# V2
pruefe("Baseline-Vorhersage", 8 + 2.5 * 4 + 0.6 * 3 + 5 * 0.3, 21.3, 1e-9)
pruefe("Fall-Vorhersage", 8 + 2.5 * 9 + 0.6 * 5 + 5 * 1, 38.5, 1e-9)
# V4
pruefe("Gesamtgenauigkeit", (860 + 420) / 1500, 0.853, 0.0005)
pruefe("Verhältnis der Auswahlraten", 0.20 / 0.38, 0.526, 0.0005)
# K1
pruefe("Recall Stufe 1 für Gesamt-Recall 0,85", 0.85 / 0.90, 0.944, 0.0005)
# K2
pruefe("Patient mit 4 Aufnahmen auf beiden Seiten", 1 - 0.8 ** 4 - 0.2 ** 4, 0.589, 0.0005)
pruefe("Uneinigkeit in Aufnahmen", 0.22 * 11840, 2605, 0.5)
# K3
pruefe("Zustand gleitendes Fenster in GB", 1_500_000 * 96 * 8 / 1e9, 1.15, 0.005)
pruefe("Einzelaufrufe in Stunden", 144e6 * 0.004 / 3600, 160, 0.01)
print("Alle Prüfungen bestanden.")

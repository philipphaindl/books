"""Monitoring ohne Labels: PSI und KS-Test pro Merkmal, plus Vorhersageverteilung und (verzögerter) MAE.

Drei Wochen Produktionsdaten: eine saubere, eine mit Zeitzonenfehler (stunde um 2
verschoben, alle Werte bleiben gültige Uhrzeiten), eine nach Ausweitung des Liefergebiets.
Ausführen:  uv run --with scikit-learn --with pandas --with numpy --with scipy python monitoring.py
"""
import numpy as np
import pandas as pd
from scipy.stats import ks_2samp
from sklearn.metrics import mean_absolute_error

from lieferdaten import MERKMALE, lieferdaten, modell_trainieren


def psi(referenz, aktuell, klassen=10):
    """Population Stability Index. Wenige verschiedene Werte: je Wert eine Klasse.
    Sonst Dezile der Referenz."""
    referenz, aktuell = np.asarray(referenz), np.asarray(aktuell)
    if len(np.unique(referenz)) <= 25:
        werte = np.union1d(referenz, aktuell)
        p = np.array([(referenz == w).mean() for w in werte])
        q = np.array([(aktuell == w).mean() for w in werte])
    else:
        kanten = np.quantile(referenz, np.linspace(0, 1, klassen + 1))
        kanten[0], kanten[-1] = -np.inf, np.inf
        p = np.histogram(referenz, kanten)[0] / len(referenz)
        q = np.histogram(aktuell, kanten)[0] / len(aktuell)
    p, q = np.clip(p, 1e-4, None), np.clip(q, 1e-4, None)
    return float(np.sum((q - p) * np.log(q / p)))


def bewertung(wert, warn=0.10, alarm=0.25):
    return "ALARM" if wert > alarm else ("Warnung" if wert > warn else "ok")


referenz = lieferdaten(5000, seed=42)
modell = modell_trainieren(referenz)
vorhersage_ref = modell.predict(referenz[MERKMALE])

wochen = {
    "W1 sauber": lieferdaten(3000, seed=101),
    "W2 Zeitzone": lieferdaten(3000, seed=102, stunden_versatz=-2),
    "W3 Gebiet": lieferdaten(3000, seed=103, distanz_max=22.0),
}

print(f"Referenz: 5000 Bestellungen, MAE im Training "
      f"{mean_absolute_error(referenz['lieferzeit_min'], vorhersage_ref):.2f} min\n")
print(f"{'':12s}  {'PSI der Merkmale':>34s}  {'PSI der':>8s}")
print(f"{'':12s}  {'distanz':>7s} {'artikel':>7s} {'stunde':>7s} {'regen':>7s}"
      f"  {'Vorhers.':>8s} {'MAE':>5s}")
ergebnis = {}
for name, df in wochen.items():
    psis = {m: psi(referenz[m], df[m]) for m in MERKMALE}
    vorhersage = modell.predict(df[MERKMALE])
    psis["Vorhersage"] = psi(vorhersage_ref, vorhersage)
    fehler = mean_absolute_error(df["lieferzeit_min"], vorhersage)
    ergebnis[name] = psis
    print(f"{name:12s}  " + " ".join(f"{v:7.3f}" for v in list(psis.values())[:4])
          + f"  {psis['Vorhersage']:8.3f} {fehler:5.2f}")

print("\nEinstufung (ok < 0,10 <= Warnung < 0,25 <= ALARM):")
for name, psis in ergebnis.items():
    auffaellig = [f"{k} ({bewertung(v)}, {v:.2f})" for k, v in psis.items() if v > 0.10]
    print(f"  {name}: {', '.join(auffaellig) if auffaellig else 'nichts Auffälliges'}")

print("\nKS-Test gegen die Referenz (D = größter Abstand der Verteilungsfunktionen)")
for name, df in wochen.items():
    d1, p1 = ks_2samp(referenz["distanz_km"], df["distanz_km"])
    d2, p2 = ks_2samp(referenz["stunde"], df["stunde"])
    print(f"  {name:12s} distanz: D={d1:.3f} p={p1:.0e}   stunde: D={d2:.3f} p={p2:.0e}")

# Stichprobengröße: dieselbe winzige Verschiebung (0,05 km), 20 Wiederholungen je Stichprobengröße
print("\nDistanz um 0,05 km verschoben (0,3 % des Wertebereichs), KS-Test, p < 0,05:")
rng = np.random.default_rng(0)
for n in (1_000, 100_000, 1_000_000):
    treffer = sum(ks_2samp(rng.uniform(0.5, 15, n), rng.uniform(0.5, 15, n) + 0.05).pvalue < 0.05
                  for _ in range(20))
    print(f"  je {n:>9,d} Beobachtungen: Alarm in {treffer:2d} von 20 Wiederholungen".replace(",", "."))

# Daten für die Diagramme im Handbuch
stunde = pd.DataFrame({
    "stunde": range(8, 23),
    "referenz": [(referenz["stunde"] == h).mean() for h in range(8, 23)],
    "woche2": [(wochen["W2 Zeitzone"]["stunde"] == h).mean() for h in range(8, 23)],
})
stunde.round(4).to_csv("stunde_verteilung.csv", index=False)
klassen = np.arange(0, 24, 2)
distanz = pd.DataFrame({
    "von": klassen,
    "referenz": np.histogram(referenz["distanz_km"], np.append(klassen, 24))[0] / len(referenz),
    "woche3": np.histogram(wochen["W3 Gebiet"]["distanz_km"], np.append(klassen, 24))[0] / 3000,
})
distanz.round(4).to_csv("distanz_verteilung.csv", index=False)

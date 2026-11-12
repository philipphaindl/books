"""Lösungen zu den Aufgaben T2 bis T7 (Model Training).

Start: uv run --with scikit-learn --with pandas --with numpy python 03_training.py
"""
import json
import math

import numpy as np
from sklearn.model_selection import cross_val_score
from sklearn.tree import DecisionTreeClassifier

# --- T2: Checkpoint-Intervall ---------------------------------------------------------------
print("T2  Training mit 60 Stunden Arbeit, Ausfall im Mittel alle 20 Stunden, Checkpoint kostet 3 Minuten")
ARBEIT, MTBF, DELTA = 60.0, 20.0, 0.05


def overhead_formel(T):
    """Erste Näherung: Kosten der Checkpoints plus erwarteter Verlust pro Ausfall (T/2)."""
    return ARBEIT / T * DELTA + ARBEIT / MTBF * T / 2


def simuliere(T, rng):
    uhr, gesichert = 0.0, 0.0
    ausfall = rng.exponential(MTBF)
    while gesichert < ARBEIT - 1e-9:
        stueck = min(T, ARBEIT - gesichert)
        dauer = stueck + (DELTA if gesichert + stueck < ARBEIT - 1e-9 else 0.0)
        if uhr + dauer <= ausfall:
            uhr += dauer
            gesichert += stueck
        else:
            uhr = ausfall
            ausfall = uhr + rng.exponential(MTBF)
    return uhr - ARBEIT


rng = np.random.default_rng(1)
T_opt = math.sqrt(2 * DELTA * MTBF)
print(f"Optimum nach sqrt(2 * delta * MTBF) = {T_opt:.2f} Stunden, Overhead nach Formel {overhead_formel(T_opt):.2f} Stunden")
print(f"{'Intervall T':>12} {'Formel':>8} {'simuliert':>10}")
punkte = []
for T in (0.25, 0.5, 1.0, 1.41, 2.0, 4.0, 8.0, 15.0):
    sim = float(np.mean([simuliere(T, rng) for _ in range(4000)]))
    print(f"{T:>10.2f} h {overhead_formel(T):>8.2f} {sim:>10.2f}")
    punkte.append({"T": T, "sim": sim})
ohne = MTBF * (math.exp(ARBEIT / MTBF) - 1) - ARBEIT
print(f"Ganz ohne Checkpoints (jeder Ausfall startet bei null): erwarteter Mehraufwand {ohne:.0f} Stunden")
print(f"Checkpoint alle 2 h, Ausfall bei Stunde 41: letzter Stand bei Stunde 40, verloren {41 - 40} Stunde")
print(f"Overhead nur durch das Schreiben: alle 2 h = {ARBEIT / 2 * DELTA:.1f} h ({ARBEIT / 2 * DELTA / ARBEIT:.1%}); "
      f"alle 30 min = {ARBEIT / 0.5 * DELTA:.1f} h ({ARBEIT / 0.5 * DELTA / ARBEIT:.1%})")
kurve = [{"T": float(t), "formel": overhead_formel(t)} for t in np.logspace(math.log10(0.2), math.log10(20), 60)]
with open("checkpoint_t2.json", "w") as f:
    json.dump({"kurve": kurve, "punkte": punkte, "T_opt": T_opt}, f)

# --- T4: Verteiltes Training -----------------------------------------------------------------
print("\nT4  8 Worker, je 64 Beispiele, 25 Mio. Parameter (float32), Rechenzeit 0,30 s je Schritt")
N, je_worker, lr0, basis = 8, 64, 0.1, 64
print(f"Effektive Batch-Größe {N * je_worker}; lineare Skalierung: Lernrate {lr0 * N * je_worker / basis:.1f}")
S = 25e6 * 4
volumen = 2 * (N - 1) / N * S
print(f"Gradientengröße {S / 1e6:.0f} MB; Ring-All-Reduce sendet je Worker {volumen / 1e6:.0f} MB")
for name, bandbreite in (("100 Gbit/s (12,5 GB/s)", 12.5e9), ("1 Gbit/s (0,125 GB/s)", 0.125e9)):
    t_kom = volumen / bandbreite
    effizienz = 0.30 / (0.30 + t_kom)
    print(f"{name:<24} Kommunikation {t_kom * 1000:>7.0f} ms, Effizienz {effizienz:.3f}, Beschleunigung {N * effizienz:.2f}x")

# --- T5: Zufallssuche -----------------------------------------------------------------------------
print("\nT5  Zufallssuche: Wahrscheinlichkeit, mindestens einmal in die besten 5 % zu treffen")
for n in (14, 30, 60, 90):
    print(f"n = {n:>3}: {1 - 0.95 ** n:.4f}")
print(f"Für 99 %: n >= {math.log(0.01) / math.log(0.95):.2f} -> {math.ceil(math.log(0.01) / math.log(0.95))}")
print("Raster mit 4 Werten je Hyperparameter und 3 Hyperparametern:", 4 ** 3, "Läufe, aber nur 4 verschiedene Werte je Achse")

# --- T6: Auswahl auf den Testdaten ---------------------------------------------------------------------
print("\nT6  Reines Rauschen (kein Zusammenhang), 100 zufällige Konfigurationen eines Entscheidungsbaums")
r = np.random.default_rng(0)
X_tr, y_tr = r.normal(size=(100, 20)), r.integers(0, 2, 100)
X_te, y_te = r.normal(size=(100, 20)), r.integers(0, 2, 100)
X_neu, y_neu = r.normal(size=(5000, 20)), r.integers(0, 2, 5000)
konfigs = [dict(max_depth=int(r.integers(1, 11)), min_samples_leaf=int(r.integers(1, 20)),
                max_features=int(r.integers(1, 21)), random_state=int(r.integers(0, 10_000))) for _ in range(100)]
test_acc, cv_acc = [], []
for k in konfigs:
    m = DecisionTreeClassifier(**k).fit(X_tr, y_tr)
    test_acc.append(m.score(X_te, y_te))
    cv_acc.append(cross_val_score(DecisionTreeClassifier(**k), X_tr, y_tr, cv=5).mean())
def bewerte(konfig, X, y):
    return DecisionTreeClassifier(**konfig).fit(X_tr, y_tr).score(X, y)


wahl_test = np.argmax(test_acc)  # Auswahl auf den Testdaten (falsch)
wahl_cv = np.argmax(cv_acc)      # Auswahl per Kreuzvalidierung auf den Trainingsdaten
beste_fresh = bewerte(konfigs[wahl_test], X_neu, y_neu)
cv_fresh = bewerte(konfigs[wahl_cv], X_te, y_te)
print(f"Mittel aller Konfigurationen auf den Testdaten: {np.mean(test_acc):.3f}")
print(f"Auswahl auf den Testdaten: bester Wert {max(test_acc):.2f}; auf 5000 frischen Beispielen {beste_fresh:.3f}")
print(f"Auswahl per Kreuzvalidierung (CV-Wert {max(cv_acc):.2f}): einmalig auf den Testdaten {cv_fresh:.2f}")
# Erwartetes Maximum von 100 Binomial(100; 0,5)-Werten
sim = np.random.default_rng(3).binomial(100, 0.5, size=(20_000, 100)).max(axis=1) / 100
print(f"Erwartetes Maximum von 100 reinen Zufallsergebnissen bei 100 Testbeispielen: {sim.mean():.3f}")

# --- T7: Early Stopping ----------------------------------------------------------------------------------
print("\nT7  Early Stopping (Geduld 3, Mindestverbesserung 0,001)")
val = [0.80, 0.62, 0.51, 0.45, 0.42, 0.405, 0.398, 0.399, 0.401, 0.396, 0.397, 0.402, 0.410, 0.425]
best, best_ep, zaehler = float("inf"), 0, 0
for ep, v in enumerate(val, start=1):
    if v < best - 0.001:
        best, best_ep, zaehler = v, ep, 0
        gesichert = " <- best geschrieben"
    else:
        zaehler += 1
        gesichert = f" ({zaehler} ohne Besserung)"
    print(f"Epoche {ep:>2}: {v:.3f}{gesichert}")
    if zaehler >= 3:
        print(f"Stopp nach Epoche {ep}; behalten wird Epoche {best_ep} mit {best:.3f}")
        break

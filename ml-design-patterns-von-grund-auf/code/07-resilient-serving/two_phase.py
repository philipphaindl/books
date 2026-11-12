"""Pattern 19: Zwei-Phasen-Vorhersage. Kleines Modell auf dem Gerät, großes Modell in der Cloud.

Kleines Modell: logistische Regression auf 4x4-Bildern (16 Merkmale). Großes Modell: SVM auf 8x8-Bildern.
Ausführen:  uv run --with scikit-learn --with numpy python two_phase.py
"""
import json

import numpy as np
from sklearn.datasets import load_digits
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.svm import SVC

X, y = load_digits(return_X_y=True)
X = X / 16.0
# 8x8 -> 4x4 (Mittel)
klein = lambda A: A.reshape(-1, 4, 2, 4, 2).mean(axis=(2, 4)).reshape(-1, 16)

X_tr, X_rest, y_tr, y_rest = train_test_split(X, y, train_size=0.5, stratify=y, random_state=0)
X_va, X_te, y_va, y_te = train_test_split(X_rest, y_rest, test_size=0.5, stratify=y_rest, random_state=0)

edge = LogisticRegression(max_iter=3000).fit(klein(X_tr), y_tr)
cloud = SVC(gamma=0.05).fit(X_tr, y_tr)
print(f"Edge-Modell (16 Merkmale):  Genauigkeit Test={edge.score(klein(X_te), y_te):.3f}")
print(f"Cloud-Modell (64 Merkmale): Genauigkeit Test={cloud.score(X_te, y_te):.3f}")


def zweiphasig(X, tau):
    """Edge entscheidet bei Sicherheit >= tau, sonst fragt es die Cloud."""
    p = edge.predict_proba(klein(X))
    sicherheit, vorhersage = p.max(axis=1), edge.classes_[p.argmax(axis=1)]
    weiter = sicherheit < tau
    if weiter.any():
        vorhersage = vorhersage.copy()
        vorhersage[weiter] = cloud.predict(X[weiter])
    return vorhersage, weiter


print("\nSchwellwert tau auf den Testdaten")
print(f"{'tau':>6s} {'an Cloud weitergereicht':>25s} {'Genauigkeit gesamt':>20s} {'Edge allein entschieden':>25s}")
sweep = []
for tau in (0.0, 0.5, 0.7, 0.8, 0.9, 0.95, 0.99, 1.01):
    v, weiter = zweiphasig(X_te, tau)
    acc = float(np.mean(v == y_te))
    lokal = ~weiter
    acc_lokal = float(np.mean(v[lokal] == y_te[lokal])) if lokal.any() else float("nan")
    sweep.append([tau, float(weiter.mean()), acc])
    print(f"{tau:6.2f} {weiter.mean():25.1%} {acc:20.3f} {acc_lokal:25.3f}")

# tau mit den Validierungsdaten wählen: kleinster Wert, der höchstens 1 Prozentpunkt unter der Cloud liegt
acc_cloud_va = cloud.score(X_va, y_va)
tau = next(t for t in np.arange(0.0, 1.0001, 0.01) if np.mean(zweiphasig(X_va, t)[0] == y_va) >= acc_cloud_va - 0.01)
v, weiter = zweiphasig(X_te, tau)
EDGE_MS, CLOUD_MS = 5, 120          # ANNAHME für die Rechnung, nicht gemessen
print(f"\ntau={tau:.2f} (auf Validierungsdaten gewählt)")
print(f"  Genauigkeit Test: {np.mean(v == y_te):.3f}, "
      f"an die Cloud weitergereicht: {weiter.mean():.1%}")
mittel = EDGE_MS + weiter.mean() * CLOUD_MS
print(f"  mittlere Latenz: {mittel:.0f} ms gegen {CLOUD_MS} ms nur Cloud")
print(f"  (angenommen: {EDGE_MS} ms Edge, {CLOUD_MS} ms Cloud inkl. Netz)")
json.dump(sweep, open("two_phase_sweep.json", "w"))

# Kalibrierung des Edge-Modells: Wie sicher ist es, und wie oft liegt es dann richtig?
p = edge.predict_proba(klein(X_te))
sicherheit, treffer = p.max(axis=1), edge.classes_[p.argmax(axis=1)] == y_te
print("\nEdge-Modell auf den Testdaten: Sicherheit gegen tatsächliche Trefferquote")
print(f"{'Sicherheit':>12s} {'Anzahl':>7s} {'Mittel Sicherheit':>18s} {'Trefferquote':>13s}")
for lo, hi in [(0.0, 0.5), (0.5, 0.7), (0.7, 0.9), (0.9, 1.01)]:
    m = (sicherheit >= lo) & (sicherheit < hi)
    print(f"{lo:5.1f} bis {min(hi, 1.0):3.1f} {m.sum():7d} {sicherheit[m].mean():18.2f} {treffer[m].mean():13.2f}")

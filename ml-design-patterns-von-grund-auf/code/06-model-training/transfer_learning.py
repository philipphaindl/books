"""Pattern 13: Transfer Learning mit scikit-learn.

Vortraining: alle zehn Ziffern erkennen (900 beschriftete Bilder).
Zielaufgabe: gerade oder ungerade, aber nur mit sehr wenigen beschrifteten Beispielen.
Die Bilder der Zielaufgabe kommen nicht im Vortraining vor.
Ausführen:  uv run --with scikit-learn --with numpy python transfer_learning.py
"""
import json
import warnings

import numpy as np
from sklearn.datasets import load_digits
from sklearn.exceptions import ConvergenceWarning
from sklearn.linear_model import LogisticRegression
from sklearn.neural_network import MLPClassifier

warnings.filterwarnings("ignore", category=ConvergenceWarning)

X, y = load_digits(return_X_y=True)
X = X / 16.0
perm = np.random.RandomState(0).permutation(len(X))
quelle, ziel = perm[:900], perm[900:]
Xq, yq = X[quelle], y[quelle]                    # Vortraining: Ziffer 0-9
# Zielaufgabe: 0 = gerade, 1 = ungerade
Xz, yz = X[ziel], y[ziel] % 2

basis = MLPClassifier(hidden_layer_sizes=(32,), max_iter=500, random_state=0)
basis.fit(Xq, yq)
print(f"Vortraining auf {len(Xq)} Bildern, Ziffernerkennung auf den übrigen "
      f"{len(Xz)}: {basis.score(X[ziel], y[ziel]):.3f}")


def merkmale(Xin):
    """Eingefrorene Basis: versteckte Schicht (ReLU) des vortrainierten Netzes."""
    return np.maximum(0.0, Xin @ basis.coefs_[0] + basis.intercepts_[0])


def ziehen(n_pro_klasse, wiederholung):
    rng = np.random.RandomState(wiederholung)
    tr = np.concatenate([rng.choice(np.where(yz == k)[0], n_pro_klasse, replace=False) for k in (0, 1)])
    te = np.setdiff1d(np.arange(len(yz)), tr)
    return tr, te


ergebnis = {}
print("\nGenauigkeit für gerade/ungerade, Mittel +- Std. über 20 Stichproben")
print(f"{'Beispiele':>9s} {'Pixel+LogReg':>13s} {'von Null':>13s} {'Feature-Extr.':>13s} {'Fine-Tuning':>13s}")
for n in (3, 5, 10, 25):
    punkte = {"roh": [], "null": [], "extr": [], "ft": []}
    for rep in range(20):
        tr, te = ziehen(n, rep)
        Xt, yt, Xe, ye = Xz[tr], yz[tr], Xz[te], yz[te]
        punkte["roh"].append(LogisticRegression(max_iter=2000).fit(Xt, yt).score(Xe, ye))
        punkte["null"].append(MLPClassifier(hidden_layer_sizes=(32,), max_iter=500, random_state=rep).fit(Xt, yt).score(Xe, ye))
        punkte["extr"].append(LogisticRegression(max_iter=2000).fit(merkmale(Xt), yt).score(merkmale(Xe), ye))
        # Fine-Tuning: erste Schicht übernehmen, neuer Kopf, alles trainieren
        ft = MLPClassifier(hidden_layer_sizes=(32,), max_iter=1, warm_start=True,
                           n_iter_no_change=1000, random_state=rep).fit(Xt, yt)
        ft.coefs_[0] = basis.coefs_[0].copy()
        ft.intercepts_[0] = basis.intercepts_[0].copy()
        ft.set_params(max_iter=200)
        ft.fit(Xt, yt)
        punkte["ft"].append(ft.score(Xe, ye))
    m = {k: (float(np.mean(v)), float(np.std(v))) for k, v in punkte.items()}
    ergebnis[2 * n] = m
    print(f"{2 * n:9d} " + " ".join(f"{m[k][0]:.3f}+-{m[k][1]:.3f}".rjust(13) for k in ("roh", "null", "extr", "ft")))
json.dump(ergebnis, open("transfer_ergebnis.json", "w"))

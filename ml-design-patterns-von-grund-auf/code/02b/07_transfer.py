"""Transfer Learning im Kleinen, zweimal: ein naher und ein ferner Transfer auf den 8x8-Ziffernbildern."""
import copy

import numpy as np
from sklearn.datasets import load_digits

from mlp import MLP, speichere, trainiere

ziffern = load_digits()
X, y = ziffern.data / 16.0, ziffern.target  # 8x8-Graustufenbilder als 64 Zahlen in [0, 1]
perm = np.random.default_rng(0).permutation(len(X))
X, y = X[perm], y[perm]
GROESSEN = [64, 64, 32]  # zwei versteckte Schichten; die Ausgabeschicht kommt je Aufgabe dazu
VARIANTEN = ["von Grund auf", "zufällig, eingefroren", "vortrainiert, eingefroren", "vortrainiert, feinjustiert"]
NS = (1, 2, 5, 10, 30)  # beschriftete Beispiele je Klasse in der Zielaufgabe


def experiment(titel, quelle, ziel_pool, ziel_test, klassen):
    """quelle, ziel_pool, ziel_test sind (X, y)-Paare; klassen = Anzahl der Klassen der Zielaufgabe."""
    vor = MLP(GROESSEN + [int(quelle[1].max()) + 1], seed=0)
    trainiere(vor, *quelle, epochen=60, lr=0.1, batch=32, rng=np.random.default_rng(1))

    def lauf(n, w, variante):
        r = np.random.default_rng(100 + w)
        idx = np.concatenate([r.choice(np.where(ziel_pool[1] == k)[0], n, replace=False) for k in range(klassen)])
        if variante.startswith("zufällig") or variante.startswith("von"):
            netz = MLP(GROESSEN + [klassen], seed=w)
            netz.eingefroren, lr = (0 if variante.startswith("von") else 2), 0.1
        else:
            netz = copy.deepcopy(vor)
            netz.neuer_kopf(klassen, seed=w)
            # Feintuning mit kleineren Schritten
            netz.eingefroren, lr = (2, 0.1) if "eingefroren" in variante else (0, 0.02)
        trainiere(netz, ziel_pool[0][idx], ziel_pool[1][idx], epochen=100, lr=lr, batch=16, rng=np.random.default_rng(w))
        return (netz.vorhersage(ziel_test[0]) == ziel_test[1]).mean()

    print(f"\n{titel} (Genauigkeit auf ungesehenen Testbildern, Mittel über 20 Wiederholungen)")
    print(f"{'Beispiele je Klasse':28}" + "".join(f"{n:>7}" for n in NS))
    ergebnis = {}
    for v in VARIANTEN:
        ergebnis[v] = [round(float(np.mean([lauf(n, w, v) for w in range(20)])), 3) for n in NS]
        print(f"{v:28}" + "".join(f"{a:7.3f}" for a in ergebnis[v]))
    return ergebnis


# Ferner Transfer: Quelle sind die Ziffern 0-4, Ziel die Ziffern 5-9 (andere Klassen, gleiche Bildart)
A, B = y < 5, y >= 5
fern = experiment("Ferner Transfer: Ziffern 0-4 -> Ziffern 5-9", (X[A], y[A]), (X[B][:300], y[B][:300] - 5),
                  (X[B][300:], y[B][300:] - 5), klassen=5)

# Naher Transfer: gleiche Bilder, aber neue Frage. Quelle: alle zehn Ziffern, Ziel: gerade oder ungerade?
nah = experiment("Naher Transfer: zehn Ziffern -> gerade/ungerade", (X[:900], y[:900]), (X[:900], y[:900] % 2),
                 (X[900:], y[900:] % 2), klassen=2)
speichere("transfer", {"n": list(NS), "fern": fern, "nah": nah})

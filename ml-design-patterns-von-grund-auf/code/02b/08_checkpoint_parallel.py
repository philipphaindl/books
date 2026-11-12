"""Checkpoints und Datenparallelität, mechanisch: was zum Zustand gehört und warum Gradienten sich mitteln lassen."""
import json
import tempfile
from pathlib import Path

import numpy as np

from daten import spirale
from mlp import MLP, trainiere

X, y = spirale(seed=0)
OPT = dict(lr=0.1, batch=32, momentum=0.9)


def max_diff(a, b):
    return max(float(np.abs(p - q).max()) for p, q in zip(a.W + a.b, b.W + b.b))


# 1) Checkpoints: 20 + 20 Epochen mit Unterbrechung gegen 40 Epochen am Stück
durch = MLP([2, 32, 32, 3], seed=1)
trainiere(durch, X, y, 40, rng=np.random.default_rng(2), **OPT)

netz, rng = MLP([2, 32, 32, 3], seed=1), np.random.default_rng(2)
trainiere(netz, X, y, 20, rng=rng, **OPT)
ordner = Path(tempfile.mkdtemp())
alles = {}
for name, liste in (("W", netz.W), ("b", netz.b), ("vW", netz.vW), ("vb", netz.vb)):
    alles.update({f"{name}{i}": a for i, a in enumerate(liste)})
np.savez(ordner / "gewichte.npz", **alles)  # Gewichte und Momentum
rest = {"epoche": 20, "rng": rng.bit_generator.state}
(ordner / "rest.json").write_text(json.dumps(rest))  # Zähler, Zufallsgenerator
print("Checkpoint-Dateien:", sorted(p.name for p in ordner.iterdir()))


def lade(mit_optimizer, mit_rng):
    n, r = MLP([2, 32, 32, 3], seed=99), np.random.default_rng(777)  # frisches Objekt, falsche Startwerte
    d = np.load(ordner / "gewichte.npz")
    n.W = [d[f"W{i}"] for i in range(3)]
    n.b = [d[f"b{i}"] for i in range(3)]
    if mit_optimizer:
        n.vW = [d[f"vW{i}"] for i in range(3)]
        n.vb = [d[f"vb{i}"] for i in range(3)]
    else:
        n.vW, n.vb = [np.zeros_like(W) for W in n.W], [np.zeros_like(b) for b in n.b]
    if mit_rng:
        r.bit_generator.state = json.loads((ordner / "rest.json").read_text())["rng"]
    return n, r


print("\nNach insgesamt 40 Epochen: größter Unterschied der Parameter zum durchgehenden Lauf")
for name, o, r in (("alles gesichert", True, True), ("ohne Optimizer-Zustand", False, True), ("ohne Zufallsgenerator", True, False)):
    n, rn = lade(o, r)
    trainiere(n, X, y, 20, rng=rn, **OPT)
    print(f"  {name:24} {max_diff(durch, n):.2e}")

# 2) Datenparallelität: vier Worker, je ein Viertel des Mini-Batches, Gradienten mitteln
netz = MLP([2, 32, 32, 3], seed=1)
batch = np.random.default_rng(3).choice(len(X), 256, replace=False)
gW, gb, loss = netz.gradienten(X[batch], y[batch])
shards = np.array_split(batch, 4)  # vier Teile zu je 64 Beispielen
teil = [netz.gradienten(X[s], y[s]) for s in shards]
gemittelt = [sum(len(s) * t[0][i] for s, t in zip(shards, teil)) / 256
             for i in range(3)]
print("\nGradient: ein Gerät (Batch 256) gegen Mittel aus 4 Workern (je 64):",
      f"max. Abweichung {max(np.abs(gW[i] - gemittelt[i]).max() for i in range(3)):.1e}")
ungleich = np.split(batch, [100, 200])  # 100 + 100 + 56 Beispiele
teil = [netz.gradienten(X[s], y[s]) for s in ungleich]
gew = [sum(len(s) * t[0][i] for s, t in zip(ungleich, teil)) / 256 for i in range(3)]
einfach = [sum(t[0][i] for t in teil) / 3 for i in range(3)]
print("ungleiche Shards (100/100/56):",
      f"gewichtetes Mittel {max(np.abs(gW[i] - gew[i]).max() for i in range(3)):.1e},",
      f"ungewichtetes Mittel {max(np.abs(gW[i] - einfach[i]).max() for i in range(3)):.1e}")

# 100 synchrone Schritte: ein Gerät gegen vier Worker
a, b = MLP([2, 32, 32, 3], seed=1), MLP([2, 32, 32, 3], seed=1)
r = np.random.default_rng(4)
for _ in range(100):
    idx = r.choice(len(X), 256, replace=False)
    ga, gba, _ = a.gradienten(X[idx], y[idx])
    a.schritt(ga, gba, 0.1)
    teile = [b.gradienten(X[s], y[s]) for s in np.array_split(idx, 4)]
    b.schritt([sum(t[0][i] for t in teile) / 4 for i in range(3)], [sum(t[1][i] for t in teile) / 4 for i in range(3)], 0.1)
print(f"Nach 100 Schritten: größter Unterschied der Parameter {max_diff(a, b):.1e}")

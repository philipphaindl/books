"""Ein MLP von Grund auf: Spirale mit drei Armen, Gradienten-Check, Training, Entscheidungsgrenze."""
import numpy as np

from daten import spirale
from mlp import MLP, speichere, trainiere


def raster(netz, n=50, grenze=1.25):
    ticks = np.linspace(-grenze, grenze, n)
    gx, gy = np.meshgrid(ticks, ticks)
    p = netz.forward(np.c_[gx.ravel(), gy.ravel()])[0]
    return p.argmax(axis=1).reshape(n, n).tolist()  # Zeile = y, Spalte = x


X, y = spirale(seed=0)
Xt, yt = spirale(seed=123)  # frisch gezogene Testdaten, nie zum Training benutzt
netz = MLP([2, 32, 32, 3], seed=1)
vorher = raster(netz)
print("Beispiele:", X.shape[0], "| Parameter:", sum(W.size + b.size for W, b in zip(netz.W, netz.b)))
p0 = netz.forward(X)[0]
print(f"Vor dem Training: Loss {netz.loss(p0, y):.3f}  (Raten wäre ln 3 = {np.log(3):.3f}), Genauigkeit {(p0.argmax(1) == y).mean():.3f}")

# Gradienten-Check: Backpropagation gegen numerische Differenz (f(w+h) - f(w-h)) / 2h
gW, gb, _ = netz.gradienten(X, y)
rng = np.random.default_rng(0)
worst = 0.0
for i in range(len(netz.W)):
    for _ in range(5):
        r, c = rng.integers(netz.W[i].shape[0]), rng.integers(netz.W[i].shape[1])
        w0, h = netz.W[i][r, c], 1e-5
        netz.W[i][r, c] = w0 + h
        lp = netz.loss(netz.forward(X)[0], y)
        netz.W[i][r, c] = w0 - h
        lm = netz.loss(netz.forward(X)[0], y)
        netz.W[i][r, c] = w0
        num = (lp - lm) / (2 * h)
        worst = max(worst, abs(num - gW[i][r, c]) / max(1e-8, abs(num) + abs(gW[i][r, c])))
print(f"Gradienten-Check: größte relative Abweichung über 15 Gewichte = {worst:.1e}")

verlauf = trainiere(netz, X, y, epochen=100, lr=0.5, batch=32, rng=np.random.default_rng(2))
for e in (0, 9, 49, 99):
    print(f"Epoche {e + 1:3d}: Loss {verlauf['loss'][e]:.3f}  Genauigkeit {verlauf['acc'][e]:.3f}")
print(f"Testdaten: Genauigkeit {(netz.vorhersage(Xt) == yt).mean():.3f}")
nachher = raster(netz)

speichere("spirale", {
    "punkte": [[round(a, 3), round(b, 3), int(c)] for (a, b), c in zip(X, y)],
    "vorher": vorher, "nachher": nachher, "loss": verlauf["loss"], "acc": verlauf["acc"],
})

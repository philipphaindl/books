"""Ein mehrschichtiges Netz (MLP) nur mit numpy.

ReLU, Softmax mit Cross-Entropy, Mini-Batch-SGD mit Momentum.
"""
import json
from pathlib import Path

import numpy as np

OUT = Path(__file__).parent / "out"
OUT.mkdir(exist_ok=True)


def speichere(name, daten):
    """Schreibt Werte für die Plots im Handbuch (JSON) nach out/."""
    (OUT / f"{name}.json").write_text(json.dumps(daten))


def softmax(z):
    z = z - z.max(axis=1, keepdims=True)  # größten Wert abziehen: kein Überlauf
    e = np.exp(z)
    return e / e.sum(axis=1, keepdims=True)


class MLP:
    def __init__(self, groessen, seed=0):
        rng = np.random.default_rng(seed)
        # He-Initialisierung: Streuung sqrt(2 / Eingänge), passend zu ReLU
        self.W = [rng.normal(0, np.sqrt(2 / m), (m, n))
                  for m, n in zip(groessen[:-1], groessen[1:])]
        self.b = [np.zeros(n) for n in groessen[1:]]
        self.vW = [np.zeros_like(W) for W in self.W]  # Momentum: Schwung der
        self.vb = [np.zeros_like(b) for b in self.b]  # letzten Schritte
        self.eingefroren = 0  # so viele Schichten von vorn bleiben unverändert

    def forward(self, X, dropout=0.0, rng=None):
        """Gibt Wahrscheinlichkeiten, Aktivierungen und Dropout-Masken zurück."""
        a, masken = [X], []
        for i, (W, b) in enumerate(zip(self.W, self.b)):
            z = a[-1] @ W + b
            if i == len(self.W) - 1:
                return softmax(z), a, masken
            h = np.maximum(z, 0)  # ReLU
            if dropout > 0:  # "inverted dropout": Überlebende hochskalieren
                m = (rng.random(h.shape) >= dropout) / (1 - dropout)
                h, masken = h * m, masken + [m]
            a.append(h)

    def loss(self, p, y, l2=0.0):
        """Mittlere Cross-Entropy plus L2-Strafterm l2/2 * Summe(W^2)."""
        ce = -np.log(p[np.arange(len(y)), y] + 1e-12).mean()
        return ce + 0.5 * l2 * sum((W ** 2).sum() for W in self.W)

    def gradienten(self, X, y, l2=0.0, dropout=0.0, rng=None):
        """Backpropagation: Kettenregel Schicht für Schicht von hinten nach vorn."""
        p, a, masken = self.forward(X, dropout, rng)
        dz = p.copy()
        dz[np.arange(len(y)), y] -= 1  # Softmax + Cross-Entropy: p - one_hot(y)
        dz /= len(y)
        gW, gb = [None] * len(self.W), [None] * len(self.W)
        for i in reversed(range(len(self.W))):
            gW[i] = a[i].T @ dz + l2 * self.W[i]
            gb[i] = dz.sum(axis=0)
            if i > 0:
                da = dz @ self.W[i].T  # Gradient an der Ausgabe der Schicht davor
                if dropout > 0:
                    da = da * masken[i - 1]
                dz = da * (a[i] > 0)  # ReLU: nur dort, wo das Neuron aktiv war
        return gW, gb, self.loss(p, y, l2)

    def schritt(self, gW, gb, lr, momentum=0.0):
        for i in range(self.eingefroren, len(self.W)):  # Eingefrorenes bleibt
            self.vW[i] = momentum * self.vW[i] - lr * gW[i]
            self.vb[i] = momentum * self.vb[i] - lr * gb[i]
            self.W[i] += self.vW[i]  # in place: ändert das Array des Netzes
            self.b[i] += self.vb[i]

    def neuer_kopf(self, klassen, seed=0):
        """Transfer Learning: letzte Schicht neu mit `klassen` Ausgängen."""
        m = self.W[-1].shape[0]
        self.W[-1] = np.random.default_rng(seed).normal(0, np.sqrt(2 / m), (m, klassen))
        self.b[-1] = np.zeros(klassen)
        self.vW[-1], self.vb[-1] = np.zeros_like(self.W[-1]), np.zeros_like(self.b[-1])

    def vorhersage(self, X):
        return self.forward(X)[0].argmax(axis=1)


def trainiere(netz, X, y, epochen, lr, batch, rng,
              l2=0.0, dropout=0.0, momentum=0.0, val=None, verlauf=None):
    """Mini-Batch-SGD. `verlauf` sammelt je Epoche Loss und Genauigkeit."""
    if verlauf is None:
        verlauf = {"loss": [], "acc": [], "val_loss": [], "val_acc": []}
    for _ in range(epochen):
        reihenfolge = rng.permutation(len(X))  # neue Reihenfolge je Epoche
        for s in range(0, len(X), batch):
            i = reihenfolge[s:s + batch]
            gW, gb, _ = netz.gradienten(X[i], y[i], l2, dropout, rng)
            netz.schritt(gW, gb, lr, momentum)
        p = netz.forward(X)[0]  # Messung ohne Dropout auf allen Trainingsdaten
        verlauf["loss"].append(float(netz.loss(p, y)))
        verlauf["acc"].append(float((p.argmax(1) == y).mean()))
        if val is not None:
            pv = netz.forward(val[0])[0]
            verlauf["val_loss"].append(float(netz.loss(pv, val[1])))
            verlauf["val_acc"].append(float((pv.argmax(1) == val[1]).mean()))
    return verlauf

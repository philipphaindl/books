"""Gemeinsame Datensätze für Kapitel 2b."""
import numpy as np


def spirale(n=100, k=3, rauschen=0.2, seed=0):
    rng = np.random.default_rng(seed)
    X, y = [], []
    for c in range(k):
        r = np.linspace(0.05, 1, n)
        t = np.linspace(c * 4, (c + 1) * 4, n) + rng.normal(0, rauschen, n)
        X.append(np.c_[r * np.sin(t), r * np.cos(t)])
        y += [c] * n
    return np.vstack(X), np.array(y)

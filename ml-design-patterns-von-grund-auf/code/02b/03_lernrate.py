"""Lernrate und Batch-Größe: dasselbe Netz, dieselben Daten, nur ein Parameter ändert sich."""
import numpy as np

from daten import spirale
from mlp import MLP, speichere, trainiere

X, y = spirale(seed=0)
ergebnis = {}
print("Lernrate | Loss nach Epoche 1 / 10 / 50 | Genauigkeit | aktive Neuronen")
for lr in (0.005, 0.05, 0.5, 5.0):
    netz = MLP([2, 32, 32, 3], seed=1)
    v = trainiere(netz, X, y, epochen=50, lr=lr, batch=32, rng=np.random.default_rng(2))
    ergebnis[str(lr)] = v["loss"]
    aktiv = sum(int((h > 0).any(axis=0).sum()) for h in netz.forward(X)[1][1:])  # Neuronen, die für irgendein Beispiel > 0 liefern
    print(f"{lr:8} | {v['loss'][0]:7.3f} {v['loss'][9]:7.3f} {v['loss'][49]:7.3f} | {v['acc'][-1]:.3f} | {aktiv} von 64")

print("\nBatch-Größe, 50 Epochen")
print("Batch Lernrate | Updates je Epoche | Loss nach Epoche 10 / 50")
for batch, lr in ((1, 0.5), (1, 0.05), (32, 0.5), (300, 0.5)):
    netz = MLP([2, 32, 32, 3], seed=1)
    v = trainiere(netz, X, y, epochen=50, lr=lr, batch=batch, rng=np.random.default_rng(2))
    print(f"{batch:5d} {lr:7} | {-(-300 // batch):17d} | {v['loss'][9]:.3f} / {v['loss'][49]:.3f}")
speichere("lernrate", ergebnis)

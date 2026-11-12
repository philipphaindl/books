"""Die Trainingsschleife in ihrer einfachsten Form: lineare Regression per Gradientenabstieg."""
import numpy as np

rng = np.random.default_rng(42)
x = rng.uniform(0, 10, size=200)
# Wahrheit: y = 3x + 2 plus Rauschen
y = 3.0 * x + 2.0 + rng.normal(0, 1.5, size=200)

w, b = 0.0, 0.0           # die Parameter des Modells, Startwert beliebig
lr = 0.002                # Lernrate: wie weit pro Schritt korrigiert wird
batch = 20                # Mini-Batch: so viele Beispiele pro Schritt

# eine Epoche = alle Daten einmal gesehen
for epoch in range(1, 101):
    idx = rng.permutation(len(x))
    for start in range(0, len(x), batch):
        i = idx[start:start + batch]
        fehler = (w * x[i] + b) - y[i]           # Vorhersage minus Wahrheit
        # Ableitung des quadratischen Fehlers nach w
        grad_w = 2 * np.mean(fehler * x[i])
        grad_b = 2 * np.mean(fehler)
        w -= lr * grad_w                         # einen kleinen Schritt bergab
        b -= lr * grad_b
    if epoch in (1, 2, 5, 10, 25, 50, 100):
        loss = np.mean((w * x + b - y) ** 2)
        print(f"Epoche {epoch:2d}: w={w:5.2f}  b={b:5.2f}  Loss={loss:6.2f}")

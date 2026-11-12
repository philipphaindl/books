"""Ein Neuron, Nichtlinearität und warum ohne sie Schichten nichts bringen."""
import numpy as np

# Ein Neuron: gewichtete Summe plus Bias, danach eine Aktivierungsfunktion
x = np.array([0.8, 0.3])
w = np.array([0.5, -1.0])
b = 0.2
z = w @ x + b
print(f"z = 0.5*0.8 + (-1.0)*0.3 + 0.2 = {z:.2f}")
print(f"ReLU(z) = {max(z, 0):.2f}   sigmoid(z) = {1 / (1 + np.exp(-z)):.3f}   tanh(z) = {np.tanh(z):.3f}")

# XOR: kein einzelnes Neuron kann es (die Klassen sind nicht durch eine Gerade trennbar),
# zwei Schichten mit ReLU schaffen es mit von Hand gesetzten Gewichten
X = np.array([[0, 0], [1, 0], [0, 1], [1, 1]])
W1 = np.array([[1, 1], [1, 1]])  # beide Neuronen der ersten Schicht summieren x1 + x2 ...
b1 = np.array([0, -1])  # ... das zweite zieht noch 1 ab
W2 = np.array([[1], [-2]])
h = np.maximum(X @ W1 + b1, 0)
print("\nx1 x2 | h1 h2 | Ausgabe")
for xi, hi, ai in zip(X, h, h @ W2):
    print(f" {xi[0]}  {xi[1]} |  {hi[0]}  {hi[1]} |  {ai[0]}")

# Ohne Nichtlinearität lassen sich zwei Schichten zu einer zusammenfassen
rng = np.random.default_rng(0)
A, B = rng.normal(size=(2, 5)), rng.normal(size=(5, 3))
daten = rng.normal(size=(4, 2))
print("\nzwei lineare Schichten == eine Schicht mit Gewichten A @ B:", np.allclose((daten @ A) @ B, daten @ (A @ B)))

# Backpropagation von Hand an einem Neuron: Eingabe 2, Gewicht 0.5, Bias 0.3, ReLU, Ziel 1, Loss (a - Ziel)^2
x, w, b, ziel = 2.0, 0.5, 0.3, 1.0


def loss(w, b):
    return (max(w * x + b, 0) - ziel) ** 2


z = w * x + b
a = max(z, 0)
dL_da = 2 * (a - ziel)  # Ableitung des Loss nach der Aktivierung
dL_dz = dL_da * (1.0 if z > 0 else 0.0)  # ReLU lässt den Gradienten durch, wenn z > 0
dL_dw, dL_db = dL_dz * x, dL_dz  # z = w*x + b: dz/dw = x, dz/db = 1
print(f"\nVorwärts: z = {z:.2f}, a = {a:.2f}, Loss = {loss(w, b):.2f}")
print(f"Rückwärts: dL/da = {dL_da:.2f}, dL/dz = {dL_dz:.2f}, dL/dw = {dL_dw:.2f}, dL/db = {dL_db:.2f}")
h = 1e-6
print(f"Numerisch geprüft: dL/dw = {(loss(w + h, b) - loss(w - h, b)) / (2 * h):.2f}, dL/db = {(loss(w, b + h) - loss(w, b - h)) / (2 * h):.2f}")
lr = 0.1
w2, b2 = w - lr * dL_dw, b - lr * dL_db
print(f"Schritt mit Lernrate {lr}: w = {w2:.2f}, b = {b2:.2f}, Loss danach = {loss(w2, b2):.2f}")

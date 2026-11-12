"""Self-Attention (scaled dot-product) in numpy: ein Block aus drei Tokens."""
import numpy as np

from mlp import softmax

rng = np.random.default_rng(3)
tokens = ["der", "drucker", "streikt"]
d = 4
X = rng.normal(size=(3, d))  # Embeddings der drei Tokens (hier zufällig, im Modell gelernt)
Wq, Wk, Wv = (rng.normal(size=(d, d)) / np.sqrt(d) for _ in range(3))  # drei gelernte Matrizen


def attention(X):
    Q, K, V = X @ Wq, X @ Wk, X @ Wv  # Frage, Schlüssel, Wert je Token
    gewichte = softmax(Q @ K.T / np.sqrt(d))  # Zeile i: wie viel Token i von jedem Token übernimmt
    return gewichte @ V, gewichte


ausgabe, gewichte = attention(X)
print("Attention-Gewichte (Zeile = fragendes Token, Spalte = betrachtetes Token):")
print(f"{'':10}" + "".join(f"{t:>9}" for t in tokens))
for t, z in zip(tokens, gewichte):
    print(f"{t:10}" + "".join(f"{g:9.2f}" for g in z) + f"   Summe {z.sum():.1f}")

# Ohne Positionsinformation ist Attention blind für die Reihenfolge: Umsortieren der Eingabe sortiert nur die Ausgabe um
perm = [2, 0, 1]
print("\nEingabe umsortiert -> Ausgabe nur umsortiert:", np.allclose(attention(X[perm])[0], ausgabe[perm]))

for n in (10, 1_000, 100_000):
    print(f"{n:>7} Tokens: Gewichtsmatrix {n}x{n} = {n * n:,} Einträge je Kopf und Schicht".replace(",", "."))

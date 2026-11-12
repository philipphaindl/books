"""Eine Embedding-Schicht ist eine Nachschlagetabelle: One-Hot mal Matrix gleich Zeile."""
import numpy as np

vokabular = ["drucker", "scanner", "passwort", "login", "vpn"]
E = np.array([[0.9, 0.1, -0.3],
              [0.8, 0.2, -0.4],
              [-0.5, 0.9, 0.2],
              [-0.4, 0.8, 0.3],
              [0.1, -0.7, 0.9]])  # Tabelle: 5 Wörter x 3 Dimensionen

idx = vokabular.index("login")
one_hot = np.eye(len(vokabular))[idx]
print("One-Hot für 'login':", one_hot)
print("one_hot @ E        :", one_hot @ E)
print("E[idx]             :", E[idx])

# Beim Training: Der Gradient der Tabelle ist null in allen Zeilen außer in der benutzten
d_ausgabe = np.array([0.5, -1.0, 2.0])  # Gradient, der von der nächsten Schicht ankommt
# d(one_hot @ E)/dE = one_hot^T mal d_ausgabe; "+ 0.0" macht aus -0 eine 0
grad_E = np.outer(one_hot, d_ausgabe) + 0.0
print("\nGradient der Tabelle:\n", grad_E)

# Der Aufwand: Matrixmultiplikation gegen Nachschlagen bei realistischer Größe
V, d = 50_000, 300
punkt = lambda n: f"{n:_}".replace("_", ".")  # deutsche Tausenderpunkte
print(f"\nTabelle {punkt(V)} x {d}: {punkt(V * d)} Gewichte = {V * d * 4 / 1e6:.0f} MB in float32")
print(f"One-Hot-Matmul: {punkt(V * d)} Multiplikationen, davon {punkt((V - 1) * d)} mit null; Lookup: {d} Werte kopieren")

# Mehrere Wörter: Satz aus Indizes, ein Lookup liefert eine Matrix (Wörter x Dimension)
satz = [vokabular.index(w) for w in ["drucker", "login", "vpn"]]
print("\nE[[0, 3, 4]] =\n", E[satz])

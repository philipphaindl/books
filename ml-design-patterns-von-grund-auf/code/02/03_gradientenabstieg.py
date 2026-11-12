"""Gradientenabstieg: Parameter schrittweise gegen die Steigung der Loss-Kurve verschieben."""
import numpy as np

from common import speichere, wohnungen

df = wohnungen()
# Standardisieren: Mittelwert 0, Streuung 1. Dann ist der beste Achsenabschnitt 0
# und es bleibt eine einzige Stellschraube, die Steigung w.
x = (df.flaeche_m2 - df.flaeche_m2.mean()) / df.flaeche_m2.std()
y = (df.miete_eur - df.miete_eur.mean()) / df.miete_eur.std()
x, y = x.to_numpy(), y.to_numpy()


def loss(w):
    return np.mean((w * x - y) ** 2)  # mittlerer quadratischer Fehler (MSE)


def gradient(w):
    return np.mean(2 * (w * x - y) * x)  # Ableitung des Loss nach w


w_opt = np.sum(x * y) / np.sum(x * x)
print(f"Analytisches Optimum: w = {w_opt:.3f}, Loss = {loss(w_opt):.3f}")
print("w nach Schritt 0, 1, ..., 8 bei verschiedenen Lernraten:")

verlaeufe = {}
for lr in (0.1, 0.9, 1.05):
    w = -1.0
    pfad = [(w, loss(w))]
    for _ in range(8):
        w = w - lr * gradient(w)
        pfad.append((w, loss(w)))
    verlaeufe[str(lr)] = pfad
    print(f"Lernrate {lr:<4}: w = " + " ".join(f"{wi:6.2f}" for wi, _ in pfad))
    print(f"{'':13s}  loss nach Schritt 8: {pfad[-1][1]:.3f}")

# Kurve für den Plot
ws = np.linspace(-1.2, 2.2, 69)
kurve = [(float(a), float(loss(a))) for a in ws]

# Mini-Batch-SGD mit zwei Parametern (w, b): Epoche und Batch
rng = np.random.default_rng(0)
w, b, lr, batch = -1.0, 0.0, 0.1, 32
schritte_pro_epoche = int(np.ceil(len(x) / batch))
print(f"\n{len(x)} Beispiele, Batch {batch} -> {schritte_pro_epoche} Schritte pro Epoche")
epochen_loss = []
for epoche in range(1, 6):
    idx = rng.permutation(len(x))
    for start in range(0, len(x), batch):
        i = idx[start:start + batch]
        fehler = w * x[i] + b - y[i]
        w -= lr * np.mean(2 * fehler * x[i])
        b -= lr * np.mean(2 * fehler)
    gesamt = np.mean((w * x + b - y) ** 2)
    epochen_loss.append(float(gesamt))
    print(f"Epoche {epoche}: w = {w:.3f}, b = {b:.3f}, loss = {gesamt:.3f}")

speichere("gradient", {"kurve": kurve, "verlaeufe": verlaeufe, "w_opt": w_opt, "epochen_loss": epochen_loss})

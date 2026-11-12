"""Pattern 14: Datenparallelität, synchron gegen asynchron, All-Reduce, Linear Scaling Rule.

Nur numpy; die "Worker" sind hier Schleifendurchläufe im selben Prozess. Es geht um die Mathematik
und den Datenverkehr, nicht um Geschwindigkeit.
Ausführen:  uv run --with numpy python distribution_strategy.py
"""
import numpy as np

rng = np.random.default_rng(0)
n, d = 8000, 10
X = rng.normal(size=(n, d))
w_wahr = rng.normal(size=d)
# Rauschen mit Varianz 0.25
y = X @ w_wahr + 0.5 * rng.normal(size=n)


def grad(w, Xb, yb):
    # Gradient des mittleren quadratischen Fehlers
    return 2 * Xb.T @ (Xb @ w - yb) / len(yb)


def verlust(w):
    return float(np.mean((X @ w - y) ** 2))


# 1) Datenparallelität: gemittelter Shard-Gradient = Gesamtgradient
w0 = np.zeros(d)
voll = grad(w0, X, y)
# 4 Worker, je 2000 Beispiele
shards = np.array_split(np.arange(n), 4)
lokal = [grad(w0, X[s], y[s]) for s in shards]
print("1) Gradient aus 4 Shards (gemittelt) gegen Gradient über alle Daten")
print(f"   größte Abweichung einer Komponente: {np.max(np.abs(np.mean(lokal, axis=0) - voll)):.2e}")

# 2) Synchron gegen asynchron: veraltete Gradienten ("Staleness")
def sgd_mit_staleness(staleness, lr=0.05, schritte=300, batch=64, seed=1):
    r = np.random.default_rng(seed)
    # Gewichte nach jedem Schritt
    historie = [np.zeros(d)]
    for t in range(schritte):
        # der Worker rechnet mit einem alten Stand
        w_alt = historie[max(0, t - staleness)]
        i = r.integers(0, n, batch)
        historie.append(historie[-1] - lr * grad(w_alt, X[i], y[i]))
    return [verlust(historie[k]) for k in (50, 100, 200, 300)]

print("\n2) Verlust nach 50 / 100 / 200 / 300 Schritten (Rauschgrenze 0.25), Lernrate 0.05")
for s in (0, 4, 10, 20):
    v = sgd_mit_staleness(s)
    name = "synchron" if s == 0 else f"asynchron, {s} Schritte alt"
    print(f"   {name:28s} " + "  ".join(f"{x:10.3g}" for x in v))

# 3) Größerer Batch: Linear Scaling Rule (Goyal et al. 2017)
def sgd_epochen(batch, lr, epochen=2, seed=2):
    r = np.random.default_rng(seed)
    w = np.zeros(d)
    schritte = 0
    for _ in range(epochen):
        idx = r.permutation(n)
        for a in range(0, n, batch):
            i = idx[a:a + batch]
            w -= lr * grad(w, X[i], y[i])
            schritte += 1
    return verlust(w), schritte

print("\n3) Zwei Epochen Training, Verlust am Ende (Rauschgrenze 0.25)")
for batch, lr, bem in [(32, 0.01, "Ausgangslage"), (256, 0.01, "8x Batch"),
                       (256, 0.08, "8x Batch, 8x Rate")]:
    v, s = sgd_epochen(batch, lr)
    print(f"   Batch {batch:3d}, Lernrate {lr:<5} {s:4d} Schritte  Verlust={v:6.3f}   {bem}")

# 4) Ring-All-Reduce: Summe über alle Worker, ohne zentralen Koordinator
def ring_allreduce(vektoren):
    k = len(vektoren)
    # teile[worker][chunk]
    teile = [np.array_split(v.copy(), k) for v in vektoren]
    gesendet = [0] * k
    # Phase 1: reduce-scatter
    for schritt in range(k - 1):
        post = [(w, (w + 1) % k, (w - schritt) % k) for w in range(k)]
        pakete = [(dst, c, teile[src][c].copy(), src) for src, dst, c in post]
        for dst, c, daten, src in pakete:
            teile[dst][c] += daten
            gesendet[src] += daten.size
    # Phase 2: all-gather
    for schritt in range(k - 1):
        post = [(w, (w + 1) % k, (w + 1 - schritt) % k) for w in range(k)]
        pakete = [(dst, c, teile[src][c].copy(), src) for src, dst, c in post]
        for dst, c, daten, src in pakete:
            teile[dst][c] = daten
            gesendet[src] += daten.size
    return [np.concatenate(t) for t in teile], gesendet

# Länge des Gradientenvektors
D = 240_000
print(f"\n4) All-Reduce über einen Gradientenvektor der Länge {D:,}".replace(",", "."))
print(f"   {'Worker':>6s} {'Ring: je Worker':>16s} {'Koordinator gesamt':>19s}  Summe korrekt")
for k in (4, 8, 16):
    vek = [np.random.default_rng(100 + j).normal(size=D) for j in range(k)]
    ergebnisse, gesendet = ring_allreduce(vek)
    ok = all(np.allclose(e, np.sum(vek, axis=0)) for e in ergebnisse)
    # (k-1)*D empfangen + (k-1)*D zurückschicken
    koordinator = 2 * (k - 1) * D
    print(f"   {k:6d} {gesendet[0]:16,d} {koordinator:19,d}  {ok}".replace(",", "."))

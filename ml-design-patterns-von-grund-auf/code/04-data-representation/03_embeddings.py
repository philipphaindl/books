"""Pattern 2 Embeddings: Die erste Gewichtsmatrix eines Netzes ist die Embedding-Tabelle."""
import json
from pathlib import Path

import numpy as np
from sklearn.neural_network import MLPClassifier

themen = {
    "Sport":    ["Tor", "Elfmeter", "Trainer", "Liga", "Stadion", "Pokal"],
    "Finanzen": ["Aktie", "Zins", "Kredit", "Börse", "Rendite", "Dividende"],
    "Kochen":   ["Pfanne", "Sosse", "Rezept", "Zutat", "Teig", "Gewürz"],
    "Technik":  ["Server", "Compiler", "Prozessor", "Netzwerk", "Kernel", "Speicher"],
}
vokabular = [w for ws in themen.values() for w in ws]
thema_von = {w: t for t, ws in themen.items() for w in ws}
idx = {w: i for i, w in enumerate(vokabular)}
V = len(vokabular)

# Synthetische Dokumente: je 3 Wörter, 85 % aus dem Thema des Dokuments, 15 % aus einem beliebigen
rng = np.random.default_rng(3)
namen = list(themen)
X, y = [], []
for _ in range(6000):
    t = rng.choice(namen)
    x = np.zeros(V)
    for _ in range(3):
        quelle = themen[t] if rng.random() < 0.85 else vokabular
        x[idx[rng.choice(quelle)]] = 1
    X.append(x)
    y.append(t)
X = np.array(X)

# Versteckte Schicht mit nur 2 Neuronen: jedes Wort bekommt einen 2-D-Vektor
net = MLPClassifier(hidden_layer_sizes=(2,), activation="tanh",
                    max_iter=2000, random_state=1).fit(X, y)
W = net.coefs_[0]       # Form (24, 2): eine Zeile pro Wort = Embedding-Tabelle
print("Form der ersten Gewichtsmatrix:", W.shape)

# One-Hot mal Matrix ist nichts anderes als das Herausgreifen einer Zeile
one_hot = np.zeros(V); one_hot[idx["Aktie"]] = 1
print("one_hot @ W == W[Zeile]:", np.allclose(one_hot @ W, W[idx["Aktie"]]))
for w in ("Aktie", "Tor", "Pfanne"):
    print(f"{w:9s}", W[idx[w]].round(2))

# Ähnlichkeit: Kosinus des Winkels zwischen zwei Vektoren
def kosinus(a, b):
    return float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b)))

gleich, anders = [], []
for a in vokabular:
    for b in vokabular:
        if a < b:
            (gleich if thema_von[a] == thema_von[b] else anders).append(kosinus(W[idx[a]], W[idx[b]]))
print(f"\nmittlerer Kosinus, gleiches Thema : {np.mean(gleich):+.2f}")
print(f"mittlerer Kosinus, anderes Thema  : {np.mean(anders):+.2f}")

rang = sorted((w for w in vokabular if w != "Aktie"), key=lambda w: -kosinus(W[idx["Aktie"]], W[idx[w]]))
print("ähnlichste Wörter zu 'Aktie':", rang[:3])
print("unähnlichstes Wort zu 'Aktie':", rang[-1])

# Faustregel aus dem TensorFlow-Blog (Google, 2017): Dimension ~ Kategorien ** 0.25
for k in (24, 5_000, 1_000_000):
    print(f"Kategorien {k:>9,} -> Faustregel {k ** 0.25:5.1f} Dimensionen")

Path(__file__).with_name("embeddings.json").write_text(json.dumps(
    [{"wort": w, "thema": thema_von[w], "x": round(float(W[idx[w], 0]), 3), "y": round(float(W[idx[w], 1]), 3)} for w in vokabular],
    ensure_ascii=False))

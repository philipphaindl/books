"""Pattern 6 Multilabel: ein Sigmoid pro Label statt eines gemeinsamen Softmax."""
import json
from pathlib import Path

import numpy as np
from sklearn.datasets import make_multilabel_classification
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import f1_score, hamming_loss
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier

X, Y = make_multilabel_classification(n_samples=4000, n_features=20, n_classes=5, n_labels=2,
                                      allow_unlabeled=False, random_state=0)
Xtr, Xte, Ytr, Yte = train_test_split(X, Y, test_size=0.3, random_state=0)
Xva, Xte, Yva, Yte = train_test_split(Xte, Yte, test_size=0.5, random_state=0)
print("Labels pro Beispiel im Mittel:", Y.sum(1).mean().round(2),
      "| verschiedene Label-Kombinationen:", len({tuple(r) for r in Y}))

# A) Sigmoid pro Label: bei Multilabel-Zielen nutzt MLPClassifier Sigmoid
# am Ausgang und binäre Kreuzentropie als Fehlerfunktion
net = MLPClassifier(hidden_layer_sizes=(32,), max_iter=1000,
                    random_state=0).fit(Xtr, Ytr)
P = net.predict_proba(Xte)
print("\nSigmoid-Ausgaben für 3 Beispiele (Summe muss nicht 1 sein):")
for p, y in zip(P[:3], Yte[:3]):
    print(" ", p.round(2), "Summe", p.sum().round(2), "| wahr", y)

def bericht(name, pred):
    mi = f1_score(Yte, pred, average="micro")
    ma = f1_score(Yte, pred, average="macro")
    exakt = np.mean((pred == Yte).all(1))       # alle Labels des Beispiels richtig
    print(f"{name:27s} Hamming {hamming_loss(Yte, pred):.3f}"
          f"  F1 micro {mi:.3f}  macro {ma:.3f}  exakt {exakt:.3f}")

print()
bericht("Sigmoid, Schwelle 0,5", (P >= 0.5).astype(int))

# Schwelle je Label auf der Validierungsmenge wählen (F1 maximieren)
Pva = net.predict_proba(Xva)
schwellen = []
for j in range(5):
    kand = np.linspace(0.1, 0.9, 33)
    schwellen.append(kand[np.argmax([f1_score(Yva[:, j], Pva[:, j] >= s) for s in kand])])
print("gewählte Schwellen:", np.round(schwellen, 2))
bericht("Sigmoid, Schwelle je Label", (P >= np.array(schwellen)).astype(int))

# B) Softmax: nur ein Label je Beispiel möglich. Wir trainieren auf einem zufällig gewählten Label
rng = np.random.default_rng(0)
einzel = np.array([rng.choice(np.flatnonzero(r)) for r in Ytr])
sm = LogisticRegression(max_iter=1000).fit(Xtr, einzel)
top1 = np.eye(5, dtype=int)[sm.predict(Xte)]
bericht("Softmax (nur Top-1)", top1)
p_sm = sm.predict_proba(Xte[1:2])[0]
print("  Softmax-Ausgabe, zweites Testbeispiel:", p_sm.round(2), "Summe", p_sm.sum().round(2))

# C) Label Powerset: jede Kombination wird eine eigene Klasse
kombi = [tuple(r) for r in Ytr]
ids = {k: i for i, k in enumerate(sorted(set(kombi)))}
rev = {i: k for k, i in ids.items()}
ps = LogisticRegression(max_iter=2000).fit(Xtr, [ids[k] for k in kombi])
pred_ps = np.array([rev[i] for i in ps.predict(Xte)])
bericht(f"Label Powerset ({len(ids)} Klassen)", pred_ps)
json_p = [[round(float(v), 2) for v in p] for p in P[:2]]
Path(__file__).with_name("multilabel.json").write_text(json.dumps({"p": json_p, "y": Yte[:2].tolist(), "softmax": [round(float(v), 2) for v in p_sm]}))

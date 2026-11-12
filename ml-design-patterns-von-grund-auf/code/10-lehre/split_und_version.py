"""Seed-Split vs. Hash-Split, und was zu einer Modellversion gehört (Checkpoint reicht nicht)."""
import hashlib
import io
import json
import pickle

import numpy as np
import pandas as pd
from sklearn.linear_model import SGDClassifier
from sklearn.model_selection import train_test_split

# --- Repeatable Splitting: Zuordnung bleibt stabil, wenn neue Zeilen dazukommen ---------------
kunden = pd.DataFrame({"kunde": [f"K{i:04d}" for i in range(1, 1001)]})
neu = pd.DataFrame({"kunde": ["K0000"]})                  # eine einzige neue Zeile, ganz vorn
beide = pd.concat([neu, kunden], ignore_index=True)

def seed_split(df):
    train, _ = train_test_split(df["kunde"], test_size=0.2, random_state=42)
    return set(train)

def hash_split(df):
    bucket = df["kunde"].map(lambda k: int(hashlib.md5(k.encode()).hexdigest(), 16) % 10)
    return set(df["kunde"][bucket < 8])                   # 8 von 10 Buckets: Training

for name, f in [("random_state=42", seed_split), ("md5(kunde) % 10 < 8", hash_split)]:
    vorher, nachher = f(kunden), f(beide)
    gewechselt = len(vorher & set(kunden["kunde"]) - nachher) + len(nachher & set(kunden["kunde"]) - vorher)
    print(f"{name:22s} Zeilen, die nach 1 neuer Zeile die Seite wechseln: {gewechselt} von 1000")

# --- Checkpoint vs. Modellversion --------------------------------------------------------------
rng = np.random.default_rng(0)
X = rng.normal(size=(1000, 5))
y = (X[:, 0] + 0.5 * X[:, 1] + rng.normal(0, 0.5, 1000) > 0).astype(int)
modell = SGDClassifier(loss="log_loss", random_state=0)
checkpoints = {}
for epoche in range(1, 11):
    modell.partial_fit(X, y, classes=[0, 1])
    if epoche in (3, 10):
        puffer = io.BytesIO(); pickle.dump(modell.coef_, puffer)
        checkpoints[epoche] = (hashlib.sha256(puffer.getvalue()).hexdigest()[:12], modell.score(X, y))
for epoche, (h, acc) in checkpoints.items():
    print(f"Checkpoint nach Epoche {epoche:2d}: Gewichte-Hash {h}, Accuracy {acc:.3f}")

manifest = {
    "checkpoint": checkpoints[10][0],
    "code": hashlib.sha256(open(__file__, "rb").read()).hexdigest()[:12],
    "daten": hashlib.sha256(X.tobytes() + y.tobytes()).hexdigest()[:12],
    "hyperparameter": {"loss": "log_loss", "epochen": 10, "random_state": 0},
    "transform": "keine (Rohmerkmale)",
    "metrik": {"accuracy_train": round(checkpoints[10][1], 3)},
}
print(json.dumps(manifest, indent=2, ensure_ascii=False))

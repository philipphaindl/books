"""Pattern 1 Hashed Feature: Kollisionen quantifiziert, Wirkung auf die Modellgüte, Cold Start."""
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from sklearn.feature_extraction import FeatureHasher
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
from sklearn.utils import murmurhash3_32

# --- 0) Das Prinzip an sechs Werten und nur 4 Buckets ---------------------------
beispiel = ["Wasserkocher", "Kaffeemühle", "Toaster", "Mixer", "Teekanne", "Pfanne"]
for wert in beispiel:
    h = murmurhash3_32(wert, positive=True)
    print(f"{wert:13s} murmurhash3_32 = {h:>10}  ->  Bucket {h % 4}")
print()

# --- 1) Kollisionen: 10.000 verschiedene Schlüssel, B Buckets ------------------
n_keys = 10_000
keys = [f"produkt_{i:05d}" for i in range(n_keys)]
print(f"{'B':>9} {'belegt':>7} {'leer':>8} {'größter':>8} "
      f"{'kollidiert':>11} {'Formel':>7}")
kollision = []
for B in (1_000, 5_000, 10_000, 50_000, 100_000, 1_000_000):
    bucket = np.array([murmurhash3_32(k, positive=True) % B for k in keys])
    n = np.bincount(bucket, minlength=B)              # Schlüssel je Bucket
    kollidiert = (n[bucket] > 1).mean()               # Anteil der Schlüssel
    formel = 1 - (1 - 1 / B) ** (n_keys - 1)
    print(f"{B:>9,} {np.count_nonzero(n):>7,} {np.sum(n == 0):>8,}",
          f"{n.max():>8} {kollidiert:>11.1%} {formel:>7.1%}")
    kollision.append((B, kollidiert, formel))

# --- 2) Wirkung auf die Modellgüte ------------------------------------------
# 5.000 Kategorien mit Zipf-ähnlicher Häufigkeit; jede hat ihre eigene Klickrate
rng = np.random.default_rng(7)
n_cat, n = 5_000, 200_000
p_cat = 1 / np.arange(1, n_cat + 1) ** 0.9
p_cat /= p_cat.sum()
rate = rng.beta(0.6, 6.0, n_cat)                         # Klickrate je Kategorie
cat = rng.choice(n_cat, n, p=p_cat)
y = rng.random(n) < rate[cat]
namen = [[f"kat_{c}"] for c in cat]
tr, te = train_test_split(np.arange(n), test_size=0.3, random_state=0)

def auc_mit_buckets(B):
    h = FeatureHasher(n_features=B, input_type="string", alternate_sign=False)
    m = LogisticRegression(max_iter=300, C=1.0).fit(h.transform([namen[i] for i in tr]), y[tr])
    return roc_auc_score(y[te], m.predict_proba(h.transform([namen[i] for i in te]))[:, 1])

print(f"\n{n_cat} Kategorien, {n:,} Zeilen, Basisrate {y.mean():.3f}")
auc = []
for B in (16, 64, 256, 1024, 4096, 16384, 65536):
    a = auc_mit_buckets(B)
    print(f"B = {B:>6}: AUC {a:.3f}")
    auc.append({"B": B, "auc": round(float(a), 4)})

# Referenz ohne Hashing: klassisches One-Hot über alle 5.000 Kategorien
oh = OneHotEncoder(handle_unknown="ignore")
ref = LogisticRegression(max_iter=300).fit(oh.fit_transform(cat[tr].reshape(-1, 1)), y[tr])
auc_ref = roc_auc_score(y[te], ref.predict_proba(oh.transform(cat[te].reshape(-1, 1)))[:, 1])
print(f"One-Hot ohne Hashing ({n_cat} Spalten): AUC {auc_ref:.3f}")

# --- 3) Cold Start: unbekannte Kategorie zur Serving-Zeit -------------------
h = FeatureHasher(n_features=4096, input_type="string", alternate_sign=False)
m = LogisticRegression(max_iter=300).fit(h.transform([namen[i] for i in tr]), y[tr])
neu = h.transform([["kat_999999"]])               # kam im Training nie vor
print("\nunbekannte Kategorie landet in Bucket", int(neu.indices[0]))
print(f"P(Klick) = {m.predict_proba(neu)[0, 1]:.3f}  (Basisrate {y.mean():.3f})")

# --- 4) Python-hash() ist für Feature-Hashing ungeeignet ----------------------
befehl = [sys.executable, "-c", "print(hash('Berlin') % 1000)"]
print("\nhash('Berlin') % 1000 in drei Prozessen:",
      [subprocess.run(befehl, capture_output=True, text=True).stdout.strip() for _ in range(3)])
print("murmurhash3_32('Berlin') % 1000 in drei Aufrufen:",
      [murmurhash3_32("Berlin", positive=True) % 1000 for _ in range(3)])

Path(__file__).with_name("hashed_feature.json").write_text(json.dumps({"beispiel": [[w, murmurhash3_32(w, positive=True) % 4] for w in beispiel], "kollision": [{"B": b, "emp": round(float(e), 4), "theorie": round(float(t), 4)} for b, e, t in kollision], "auc": auc, "auc_onehot": round(float(auc_ref), 4)}))

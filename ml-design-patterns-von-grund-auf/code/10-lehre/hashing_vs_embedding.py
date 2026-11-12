"""Hashing ist keine Embedding: Kollisionen sind Zufall, Ähnlichkeit wird nur gelernt."""
import hashlib
from collections import Counter

import numpy as np
from sklearn.decomposition import TruncatedSVD

begriffe = ["kuendigung", "kuendigen", "rechnung", "mahnung", "passwort", "login", "vertrag",
            "tarif", "zahlung", "storno", "umzug", "adresse", "router", "internet", "störung",
            "rufnummer", "sim", "roaming", "datenvolumen", "gutschrift"]

def bucket(wort, n):                                # md5 statt hash(): in Python je Lauf anders gesalzen
    return int(hashlib.md5(wort.encode()).hexdigest(), 16) % n

for n in (64, 8):
    belegung = Counter(bucket(w, n) for w in begriffe)
    kollisionen = sum(1 for c in belegung.values() if c > 1)
    print(f"{len(begriffe)} Begriffe in {n:2d} Buckets: {kollisionen} Buckets mit Kollision, "
          f"kuendigung={bucket('kuendigung', n)}, kuendigen={bucket('kuendigen', n)}")

# Embedding-Ersatz ohne neuronales Netz: Wortvektoren aus gemeinsamem Vorkommen (SVD).
saetze = [
    "kuendigung vertrag tarif", "kuendigen vertrag tarif", "kuendigung vertrag storno",
    "kuendigen vertrag umzug", "rechnung zahlung mahnung", "rechnung zahlung gutschrift",
    "mahnung zahlung rechnung", "gutschrift rechnung storno", "passwort login internet",
    "login passwort router", "router internet störung", "internet störung router",
    "sim roaming datenvolumen", "roaming sim rufnummer", "datenvolumen sim tarif",
    "umzug adresse vertrag", "adresse umzug tarif",
]
vokabular = sorted({w for s in saetze for w in s.split()})
idx = {w: i for i, w in enumerate(vokabular)}
M = np.zeros((len(vokabular), len(vokabular)))
for s in saetze:
    for a in s.split():
        for b in s.split():
            if a != b:
                M[idx[a], idx[b]] += 1
E = TruncatedSVD(n_components=4, random_state=0).fit_transform(M)
E /= np.linalg.norm(E, axis=1, keepdims=True)

def cos(a, b):
    return float(E[idx[a]] @ E[idx[b]])

for a, b in [("kuendigung", "kuendigen"), ("rechnung", "mahnung"), ("router", "störung"),
             ("kuendigung", "router"), ("rechnung", "roaming")]:
    print(f"Kosinus-Ähnlichkeit {a:10s} / {b:10s}: {cos(a, b):5.2f}")

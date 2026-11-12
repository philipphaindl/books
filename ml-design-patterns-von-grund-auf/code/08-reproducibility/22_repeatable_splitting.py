"""Pattern 22 Repeatable Splitting: Hash-Split nach Gruppenschluessel vs. zeilenweiser Zufalls-Split."""
import hashlib
import subprocess
import sys

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from sklearn.model_selection import GroupShuffleSplit, train_test_split

# 500 Patienten, je 10 Messungen. Die Messungen eines Patienten ähneln sich stark.
rng = np.random.default_rng(7)
n_pat, n_mess = 500, 10
z = rng.normal(size=(n_pat, 5))                                  # stabile Eigenschaften je Patient
y_pat = rng.random(n_pat) < 1 / (1 + np.exp(-0.8 * z[:, 0]))      # Befund hängt nur schwach an z0
df = pd.DataFrame(
    np.repeat(z, n_mess, axis=0) + rng.normal(0, 0.3, (n_pat * n_mess, 5)),
    columns=[f"m{i}" for i in range(5)],
)
df["patient_id"] = [f"P{i:04d}" for i in np.repeat(np.arange(n_pat), n_mess)]
df["befund"] = np.repeat(y_pat, n_mess).astype(int)
merkmale = [f"m{i}" for i in range(5)]

def bewerte(train, test):
    rf = RandomForestClassifier(n_estimators=100, random_state=0).fit(train[merkmale], train["befund"])
    return accuracy_score(test["befund"], rf.predict(test[merkmale]))

def beide(tr, te) -> int:
    return len(set(tr.patient_id) & set(te.patient_id))

# 1) Zeilenweise zufällig: Zeilen eines Patienten landen in Train UND Test
tr, te = train_test_split(df, test_size=0.2, random_state=0)
print(f"zeilenweiser Split : Accuracy {bewerte(tr, te):.3f}"
      f" | Patienten in beiden Teilen: {beide(tr, te)}")

# 2) Hash-Split auf dem Gruppenschlüssel
def bucket(key: str, n: int = 10) -> int:
    digest = hashlib.sha256(key.encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big") % n

df["bucket"] = df["patient_id"].map(bucket)
tr = df[df["bucket"] < 8]
te = df[df["bucket"] >= 8]
print(f"Hash-Split         : Accuracy {bewerte(tr, te):.3f}"
      f" | Patienten in beiden Teilen: {beide(tr, te)}")
print(f"Zeilen Train/Test  : {len(tr)}/{len(te)}")

# 3) Alternative in scikit-learn
gss = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=0)
i_tr, i_te = next(gss.split(df, groups=df["patient_id"]))
print(f"GroupShuffleSplit  : Accuracy "
      f"{bewerte(df.iloc[i_tr], df.iloc[i_te]):.3f}")

# Wiederholbarkeit: gleiche Zuordnung nach Neustart, auch wenn Daten wachsen
neu = pd.DataFrame({"patient_id": [f"P{i:04d}" for i in range(500, 600)]})
alle = pd.concat([df[["patient_id"]].drop_duplicates(), neu])
alle["bucket"] = alle["patient_id"].map(bucket)
alt = df[["patient_id", "bucket"]].drop_duplicates().set_index("patient_id")["bucket"]
unveraendert = (alle.set_index("patient_id")["bucket"].loc[alt.index] == alt).all()
print("Bisherige 500 Patienten nach Datenzuwachs unverändert:",
      bool(unveraendert))

# Falle: Pythons eingebautes hash() ist für Strings pro Prozess zufällig gesalzen
befehl = [sys.executable, "-c", "print(hash('P0001'))"]
h = [subprocess.run(befehl, capture_output=True, text=True).stdout.strip()
     for _ in range(2)]
print("hash('P0001') in zwei Prozessen gleich:", h[0] == h[1])

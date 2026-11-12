"""Pattern 12: Checkpoints - Training ueber viele Pakete mit partial_fit,
Abbruch und Wiederaufnahme."""
import os

import joblib
import numpy as np
from sklearn.linear_model import SGDClassifier
from sklearn.metrics import average_precision_score
from sklearn.preprocessing import StandardScaler

from pumpen import *

t = tabelle()
tr, va, te = zeit_split(t)
tr = tr.sort_values("minute")
pakete = np.array_split(np.arange(len(tr)), 30)           # 30 "Tagesdateien"
EPOCHEN = 5
SCHRITTE = EPOCHEN * len(pakete)
skal = StandardScaler().fit(tr[NAMEN])    # fest, gehoert zum Modell (Pattern 21)
X, y = skal.transform(tr[NAMEN]), tr.fail24.to_numpy()


class Abbruch(Exception):
    pass


def trainiere(modell=None, start=0, abbruch_bei=None, ckpt_alle=None,
              pfad="out/ckpt.joblib"):
    """Ein Schritt = ein Paket. Auf einem Cluster waeren das Stunden."""
    modell = modell or SGDClassifier(loss="log_loss", alpha=1e-4, random_state=0)
    for schritt in range(start, SCHRITTE):
        if schritt == abbruch_bei:
            raise Abbruch(f"Knoten entzogen vor Schritt {schritt}")
        i = pakete[schritt % len(pakete)]
        modell.partial_fit(X[i], y[i], classes=[0, 1])
        if ckpt_alle and (schritt + 1) % ckpt_alle == 0:
            stand = {"modell": modell, "naechster_schritt": schritt + 1}
            joblib.dump(stand, pfad + ".tmp")
            os.replace(pfad + ".tmp", pfad)    # atomar: nie eine halbe Datei
    return modell


def ap(m):
    return average_precision_score(
        te.fail24, m.decision_function(skal.transform(te[NAMEN])))


referenz = trainiere()
print(f"A) ohne Unterbrechung:  {SCHRITTE} Schritte, PR-AUC Test {ap(referenz):.4f}")

# B) Abbruch ohne Checkpoint: alles von vorn
try:
    trainiere(abbruch_bei=97)
except Abbruch as e:
    print(f"B) {e}; kein Checkpoint, Neustart bei Schritt 0")
b = trainiere()
print(f"   Aufwand: 97 + {SCHRITTE} = {97 + SCHRITTE} Schritte, "
      f"identisch zu A: {np.array_equal(b.coef_, referenz.coef_)}")

# C) Abbruch mit Checkpoint alle 10 Schritte
try:
    trainiere(abbruch_bei=97, ckpt_alle=10)
except Abbruch as e:
    print(f"C) {e}")
ck = joblib.load("out/ckpt.joblib")
start = ck["naechster_schritt"]
print(f"   letzter Checkpoint: vor Schritt {start}, "
      f"Datei {os.path.getsize('out/ckpt.joblib')} Bytes")
c = trainiere(ck["modell"], start=start)
print(f"   Aufwand: 97 + {SCHRITTE - start} = {97 + SCHRITTE - start} Schritte, "
      f"identisch zu A: {np.array_equal(c.coef_, referenz.coef_)}")
print(f"   PR-AUC Test {ap(c):.4f}")

# Wie oft sichern? Verlust im Mittel ein halbes Intervall
print(f"\n{'Intervall':>10}{'Checkpoints':>13}{'max. Verlust':>14}{'mittl. Verlust':>16}")
for k in (1, 5, 10, 25, 50):
    print(f"{k:>10}{SCHRITTE // k:>13}{k:>10} Schr.{k / 2:>12.1f} Schr.")

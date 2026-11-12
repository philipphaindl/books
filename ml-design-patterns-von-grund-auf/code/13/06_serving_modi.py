"""Pattern 16/17: dasselbe Modell einzeln (online) und gebuendelt (batch)."""
import time

import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier

from pumpen import *


def punkt(x):
    return f"{x:,}".replace(",", ".")


t = tabelle()
tr, va, te = zeit_split(t)
modell = HistGradientBoostingClassifier(random_state=0)
modell.fit(tr[NAMEN].to_numpy(), tr.fail24)
X = te[NAMEN].to_numpy()
print(f"Testzeilen: {punkt(len(X))}")

n = 500
t0 = time.perf_counter()
einzeln = np.array([modell.predict_proba(X[i:i + 1])[0, 1] for i in range(n)])
d1 = (time.perf_counter() - t0) / n
for groesse in (1000, len(X)):
    t0 = time.perf_counter()
    paket = modell.predict_proba(X[:groesse])[:, 1]
    d2 = (time.perf_counter() - t0) / groesse
    print(f"Paket mit {punkt(groesse):>6} Zeilen: {d2 * 1e6:5.1f} us je Zeile "
          f"(Einzelaufruf {d1 * 1e6:.0f} us, Faktor {punkt(round(d1 / d2))})")
print("identische Ergebnisse:", np.allclose(einzeln, paket[:n]))

# Wie oft muss entschieden werden? Die Vorhersage betrifft die naechsten 24 h.
pumpen = 2000
print(f"\nFlotte mit {punkt(pumpen)} Pumpen, Zeilen pro Tag:")
print(f"  alle {SCHRITT} min: {punkt(pumpen * 24 * 60 // SCHRITT)}")
print(f"  stuendlich: {punkt(pumpen * 24)}")
print(f"  einmal nachts: {punkt(pumpen)}")

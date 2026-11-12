"""Klassifikation: logistische Regression, Wahrscheinlichkeit, Schwellwert, Softmax."""
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split

from common import maschinen, speichere

df = maschinen()
X = df[["temperatur_c", "schwingung_mm_s"]]
X_tr, X_te, y_tr, y_te = train_test_split(X, df.ausfall, test_size=0.3, random_state=0)

log = LogisticRegression().fit(X_tr, y_tr)
w1, w2 = log.coef_[0]
print(f"z = {w1:.3f} * temperatur + {w2:.3f} * schwingung + ({log.intercept_[0]:.3f})")

probe = pd.DataFrame({"temperatur_c": [78.0], "schwingung_mm_s": [5.0]})
z = log.decision_function(probe)[0]
p = 1 / (1 + np.exp(-z))
print(f"\nMaschine mit 78 °C, 5 mm/s: z = {z:.3f}, sigmoid(z) = {p:.3f}")
print("predict_proba:", log.predict_proba(probe)[0].round(3))

p_te = log.predict_proba(X_te)[:, 1]
for schwelle in (0.5, 0.3):
    markiert = (p_te >= schwelle).astype(int)
    print(f"Schwellwert {schwelle}: {markiert.sum()} von {len(markiert)} Maschinen als 'fällt aus' markiert, "
          f"Genauigkeit {np.mean(markiert == y_te):.3f}")

# Softmax bei drei Klassen
X_tr3, X_te3, y_tr3, y_te3 = train_test_split(X, df.fehlerart, test_size=0.3, random_state=0)
multi = LogisticRegression(max_iter=1000).fit(X_tr3, y_tr3)
logits = multi.decision_function(probe)[0]
softmax = np.exp(logits) / np.exp(logits).sum()
print("\nDrei Klassen (kein Fehler, Überhitzung, Lagerschaden)")
print("Logits :", logits.round(3))
print("Softmax:", softmax.round(3), "Summe =", softmax.sum().round(3))
print("predict_proba:", multi.predict_proba(probe)[0].round(3))

# Drei unabhängige Sigmoide (Mehrfachetiketten) dagegen
sig = 1 / (1 + np.exp(-logits))
print("Sigmoid je Logit:", sig.round(3), "Summe =", sig.sum().round(3))

speichere("klassifikation", {
    "punkte": [[a, b, int(c)] for a, b, c in zip(df.temperatur_c, df.schwingung_mm_s, df.ausfall)][:300],
    "w1": w1, "w2": w2, "b": float(log.intercept_[0]),
})

"""Pattern 20: Keyed Predictions. Verteilte Batch-Vorhersage liefert Ergebnisse in beliebiger Reihenfolge.

Die Bearbeitungsdauer je Stück ist hier fest vorgegeben und steht für schwankende Last im Cluster.
Ausführen:  uv run --with scikit-learn --with pandas --with numpy python keyed_predictions.py
"""
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import numpy as np
import pandas as pd
from sklearn.datasets import load_digits
from sklearn.linear_model import LogisticRegression

X, y = load_digits(return_X_y=True)
modell = LogisticRegression(max_iter=3000).fit(X[:1500] / 16, y[:1500])
# 120 Beispiele zu bewerten
X_neu, y_neu = X[1500:1620] / 16, y[1500:1620]

df = pd.DataFrame(X_neu).assign(schluessel=[f"img-{i:03d}" for i in range(120)])
# 12 Stücke à 10 Zeilen
stuecke = [df.iloc[i * 10:(i + 1) * 10] for i in range(12)]
# Sekunden, alle verschieden
DAUER = [0.9, 0.3, 1.5, 0.1, 1.1, 0.5, 1.9, 0.7, 0.2, 1.3, 0.4, 1.7]


def bewerten(nr):
    # Last, Netz, langsamer Knoten ...
    time.sleep(DAUER[nr])
    s = stuecke[nr]
    X = s.drop(columns="schluessel").to_numpy()
    return nr, s["schluessel"].tolist(), modell.predict(X)


eingang = []
with ThreadPoolExecutor(max_workers=12) as pool:
    for f in as_completed([pool.submit(bewerten, i) for i in range(12)]):
        eingang.append(f.result())

print("Stücke in Reihenfolge des Eintreffens:", [nr for nr, _, _ in eingang])

# a) ohne Schlüssel: Ergebnisse in Ankunftsreihenfolge an die Eingabe heften
ohne = np.concatenate([p for _, _, p in eingang])
print(f"\na) positionsbasiert zugeordnet:  Genauigkeit = "
      f"{np.mean(ohne == y_neu):.3f}")

# b) mit Schlüssel: Join über die mitgereichte ID
schluessel = sum((k for _, k, _ in eingang), [])
erg = pd.DataFrame({"schluessel": schluessel, "vorhersage": ohne})
wahrheit = pd.DataFrame({"schluessel": df["schluessel"], "wahr": y_neu})
verbunden = wahrheit.merge(erg, on="schluessel")
richtig = np.mean(verbunden.wahr == verbunden.vorhersage)
print(f"b) per Schlüssel zugeordnet:     Genauigkeit = {richtig:.3f}")
print(verbunden.head(4).to_string(index=False))

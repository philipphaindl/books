"""Schritt 2: das naive Notebook. Zufälliger Zeilen-Split, Accuracy als Maß."""
import pandas as pd
from sklearn.model_selection import train_test_split

from daten import ZIEL, lade_daten
from modell import ALLE0, ENTWICKLUNG_BIS, kennzahlen, modell_gross, nutzen, speichere

df = lade_daten()
dev = df[df.monat <= ENTWICKLUNG_BIS]

X = pd.get_dummies(dev[ALLE0]).astype(float)       # One-Hot "von Hand" im Notebook
y = dev[ZIEL]
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=42)

modell = modell_gross().fit(X_tr, y_tr)
p = modell.predict_proba(X_te)[:, 1]
k = kennzahlen(y_te, p, 0.5)
k["nutzen"] = nutzen(k, len(y_te))
print(f"Zeilen Training {len(X_tr):,} | Test {len(X_te):,}")
print(f"Accuracy {k['accuracy']:.3f} | Precision {k['precision']:.3f} | Recall {k['recall']:.3f} | PR-AUC {k['ap']:.3f}")
speichere("02_naiv", k)

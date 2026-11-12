"""Metriken: Konfusionsmatrix, Precision, Recall, F1, ROC-AUC, MAE und RMSE."""
import numpy as np
from sklearn.datasets import make_classification
from sklearn.dummy import DummyClassifier
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.metrics import (accuracy_score, confusion_matrix, f1_score, mean_absolute_error,
                             mean_squared_error, precision_score, recall_score, roc_auc_score, roc_curve)
from sklearn.model_selection import train_test_split

from common import speichere, wohnungen

# 20 000 Transaktionen, rund 1 % Betrug
X, y = make_classification(n_samples=20000, n_features=8, n_informative=4, weights=[0.99, 0.01],
                           class_sep=1.0, flip_y=0.0, random_state=42)
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.25, stratify=y, random_state=0)
print(f"Betrugsanteil im Test: {y_te.mean():.3f} ({y_te.sum()} von {len(y_te)})")

immer_nein = DummyClassifier(strategy="most_frequent").fit(X_tr, y_tr)
print(f"\n'Immer kein Betrug': Accuracy {accuracy_score(y_te, immer_nein.predict(X_te)):.4f}, "
      f"Recall {recall_score(y_te, immer_nein.predict(X_te)):.2f}")

modell = LogisticRegression(max_iter=1000).fit(X_tr, y_tr)
p = modell.predict_proba(X_te)[:, 1]
for schwelle in (0.5, 0.1):
    pred = (p >= schwelle).astype(int)
    tn, fp, fn, tp = confusion_matrix(y_te, pred).ravel()
    print(f"\nSchwelle {schwelle}: TN={tn} FP={fp} FN={fn} TP={tp}")
    print(f"  Accuracy {accuracy_score(y_te, pred):.4f}  Precision {precision_score(y_te, pred, zero_division=0):.2f}  "
          f"Recall {recall_score(y_te, pred):.2f}  F1 {f1_score(y_te, pred):.2f}")
print(f"\nROC-AUC (schwellenunabhängig): {roc_auc_score(y_te, p):.3f}")

fpr, tpr, _ = roc_curve(y_te, p)
schritt = max(1, len(fpr) // 60)
speichere("roc", {"punkte": [[float(a), float(b)] for a, b in zip(fpr[::schritt], tpr[::schritt])] + [[1.0, 1.0]]})

# Regression: MAE und RMSE
df = wohnungen()
Xw, yw = df[["flaeche_m2", "zimmer", "baujahr"]], df.miete_eur
Xw_tr, Xw_te, yw_tr, yw_te = train_test_split(Xw, yw, test_size=0.25, random_state=0)
reg = LinearRegression().fit(Xw_tr, yw_tr)
pr = reg.predict(Xw_te)
print(f"\nMiete: MAE {mean_absolute_error(yw_te, pr):.1f} Euro, RMSE {mean_squared_error(yw_te, pr) ** 0.5:.1f} Euro")
pr_aus = pr.copy()
pr_aus[0] += 1000  # ein einzelner grober Ausreißer
print(f"Mit einem Ausreißer von +1000 Euro: MAE {mean_absolute_error(yw_te, pr_aus):.1f}, "
      f"RMSE {mean_squared_error(yw_te, pr_aus) ** 0.5:.1f}")

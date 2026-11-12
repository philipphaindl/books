"""Pattern 10 Rebalancing: stark unbalancierte Daten (ca. 0,5 % positiv), vier Strategien."""
import json
from pathlib import Path

import numpy as np
from imblearn.over_sampling import SMOTE
from sklearn.datasets import make_classification
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (average_precision_score, confusion_matrix, f1_score,
                             precision_recall_curve, precision_score, recall_score,
                             roc_auc_score)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

X, y = make_classification(n_samples=200_000, n_features=15, n_informative=6,
                           n_redundant=2, weights=[0.995], flip_y=0.0,
                           class_sep=1.1, random_state=1)
Xtr, Xrest, ytr, yrest = train_test_split(X, y, test_size=0.4, random_state=0, stratify=y)
Xva, Xte, yva, yte = train_test_split(Xrest, yrest, test_size=0.5, random_state=0,
                                      stratify=yrest)
print(f"Positive: {y.mean():.2%}; Train {ytr.sum()} / {len(ytr):,}, "
      f"Test {yte.sum()} / {len(yte):,}")
print(f"Triviales Modell 'nie Betrug': Genauigkeit {1 - yte.mean():.3f}, Recall 0.000")


def modell(**kw):
    return make_pipeline(StandardScaler(), LogisticRegression(max_iter=1000, **kw))


rng = np.random.default_rng(0)
pos, neg = np.flatnonzero(ytr == 1), np.flatnonzero(ytr == 0)
weg = rng.choice(neg, size=10 * len(pos), replace=False)
down = np.concatenate([pos, weg])                     # Verhältnis 1:10
Xs, ys = SMOTE(random_state=0).fit_resample(Xtr, ytr)   # nur Trainingsdaten!

strategien = {
    "Baseline (nichts getan)": modell().fit(Xtr, ytr),
    "Klassengewichte (balanced)": modell(class_weight="balanced").fit(Xtr, ytr),
    "Downsampling 1:10": modell().fit(Xtr[down], ytr[down]),
    "SMOTE (Upsampling)": modell().fit(Xs, ys),
}
print(f"\n{'Strategie':27s} {'Prec':>5} {'Rec':>5} {'F1':>5} {'F1*':>5}"
      f" {'PR-AUC':>6} {'ROC':>5} {'mittl.P':>7}")
kurven, ap, schwellen = {}, {}, {}
for name, m in strategien.items():
    p = m.predict_proba(Xte)[:, 1]
    pred = p >= 0.5
    # Schwelle verschieben: beste F1-Schwelle auf den Validierungsdaten suchen
    pva = m.predict_proba(Xva)[:, 1]
    kand = np.unique(np.quantile(pva, np.linspace(0.9, 0.9999, 300)))
    t = kand[np.argmax([f1_score(yva, pva >= s) for s in kand])]
    print(f"{name:27s} {precision_score(yte, pred, zero_division=0):5.3f}"
          f" {recall_score(yte, pred):5.3f} {f1_score(yte, pred):5.3f}"
          f" {f1_score(yte, p >= t):5.3f} {average_precision_score(yte, p):6.3f}"
          f" {roc_auc_score(yte, p):5.3f} {p.mean():7.4f}")
    pr, rc, _ = precision_recall_curve(yte, p)
    k = np.linspace(0, len(pr) - 1, 60).astype(int)
    kurven[name] = {"recall": rc[k].round(4).tolist(), "precision": pr[k].round(4).tolist()}
    ap[name] = round(float(average_precision_score(yte, p)), 3)
    schwellen[name] = round(float(t), 3)
print("F1*: F1 mit der auf den Validierungsdaten gewählten Schwelle")

base = strategien["Baseline (nichts getan)"]
gew = strategien["Klassengewichte (balanced)"]
print("\nKonfusionsmatrix Baseline bei 0,5 (Zeilen: wahr, Spalten: Vorhersage)")
print(confusion_matrix(yte, base.predict(Xte)))
print("Konfusionsmatrix Klassengewichte bei 0,5")
print(confusion_matrix(yte, gew.predict(Xte)))
Path(__file__).with_name("rebalancing.json").write_text(json.dumps(
    {"kurven": kurven, "ap": ap, "schwellen": schwellen,
     "basisrate": round(float(yte.mean()), 4)}, ensure_ascii=False))

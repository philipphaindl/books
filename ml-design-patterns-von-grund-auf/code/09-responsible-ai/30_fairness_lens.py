"""Pattern 30 Fairness Lens: Metriken je Gruppe, Equal Opportunity, gruppenspezifische Schwellen."""
import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import confusion_matrix
from sklearn.model_selection import train_test_split

rng = np.random.default_rng(12)
n = 12000
gruppe = np.where(rng.random(n) < 0.3, "B", "A")
einkommen = rng.normal(np.where(gruppe == "A", 3400, 2900), 800)
schulden = rng.beta(2, 5, n)
jahre = rng.gamma(2.0, 3.0, n)
rueckzahlung = (0.0012 * (einkommen - 3200) - 4.0 * (schulden - 0.28) + 0.08 * (jahre - 6)
                + rng.logistic(size=n)) > 0                        # tatsächlich zurückgezahlt
# Historische Entscheidungen: kreditwürdige Antragsteller aus B wurden nur zu 70 % bewilligt
bewilligt = rueckzahlung & ((gruppe == "A") | (rng.random(n) < 0.7))
df = pd.DataFrame({"einkommen": einkommen, "schulden": schulden, "jahre": jahre,
                   "gruppe": gruppe, "rueckzahlung": rueckzahlung, "bewilligt": bewilligt})
tr, te = train_test_split(df, test_size=0.4, random_state=0)
merkmale = ["einkommen", "schulden", "jahre"]            # "gruppe" ist KEIN Merkmal
modell = HistGradientBoostingClassifier(random_state=0).fit(tr[merkmale], tr["bewilligt"])
score = modell.predict_proba(te[merkmale])[:, 1]

def tabelle(pred: np.ndarray) -> pd.DataFrame:
    zeilen = {}
    for g in ("A", "B"):
        m = (te["gruppe"] == g).to_numpy()
        tn, fp, fn, tp = confusion_matrix(te["rueckzahlung"][m], pred[m]).ravel()
        zeilen[g] = {"n": int(m.sum()), "Bewilligungsrate": pred[m].mean(),
                     "TPR": tp / (tp + fn), "FPR": fp / (fp + tn),
                     "Precision": tp / (tp + fp)}
    return pd.DataFrame(zeilen).T

pred = score >= 0.5
print("Ein Schwellwert 0.5 für alle (Referenz: tatsächliche Rückzahlung):")
t1 = tabelle(pred)
print(t1.round(3).to_string())
print(f"Differenz TPR (A - B): {t1.loc['A', 'TPR'] - t1.loc['B', 'TPR']:.3f}\n")

# Post-Processing nach Hardt et al.: Schwelle je Gruppe, TPR von A als Ziel
ziel = t1.loc["A", "TPR"]
schwellen = {"A": 0.5}
gut_B = (te["gruppe"] == "B").to_numpy() & te["rueckzahlung"].to_numpy()
schwellen["B"] = float(np.quantile(score[gut_B], 1 - ziel))
ist_A = (te["gruppe"] == "A").to_numpy()
pred2 = np.where(ist_A, score >= schwellen["A"], score >= schwellen["B"])
print(f"Schwellen je Gruppe: A {schwellen['A']:.2f}, B {schwellen['B']:.2f}")
t2 = tabelle(pred2)
print(t2.round(3).to_string())
print(f"Differenz TPR (A - B): {t2.loc['A', 'TPR'] - t2.loc['B', 'TPR']:.3f}")

# Dieselben Zahlen mit Fairlearn (falls installiert)
try:
    from fairlearn.metrics import MetricFrame, selection_rate, true_positive_rate
    mf = MetricFrame(metrics={"TPR": true_positive_rate,
                              "Selection": selection_rate},
                     y_true=te["rueckzahlung"], y_pred=pred,
                     sensitive_features=te["gruppe"])
    print("\nFairlearn MetricFrame:")
    print(mf.by_group.round(3).to_string())
    print("TPR-Differenz (max-min):", round(float(mf.difference()["TPR"]), 3))
except ImportError:
    print("\n(fairlearn nicht installiert)")

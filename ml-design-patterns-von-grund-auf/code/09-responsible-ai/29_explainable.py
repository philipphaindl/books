"""Pattern 29 Explainable Predictions: Permutation Importance, exakte Shapley-Werte, Integrated Gradients."""
from itertools import combinations
from math import factorial

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.inspection import permutation_importance
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

rng = np.random.default_rng(4)
n = 4000
df = pd.DataFrame({
    "einkommen": rng.normal(3200, 900, n),
    "schuldenquote": rng.beta(2, 5, n),
    "beschaeftigung_jahre": rng.gamma(2.0, 3.0, n),
    "alter": rng.integers(21, 65, n).astype(float),
    "rauschen": rng.normal(size=n),
})
score = (0.0012 * (df.einkommen - 3200) - 4.0 * (df.schuldenquote - 0.28)
         + 0.08 * (df.beschaeftigung_jahre - 6) + rng.logistic(size=n))
df["bewilligt"] = (score > 0).astype(int)
X, y = df.drop(columns="bewilligt"), df["bewilligt"]
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.3, random_state=0)

wald = RandomForestClassifier(n_estimators=200, min_samples_leaf=20, random_state=0).fit(X_tr, y_tr)
print(f"Accuracy Test: {wald.score(X_te, y_te):.3f}\n")

# --- Global: Permutation Importance auf Testdaten ---
def zeige_pi(modell, X_test, titel):
    pi = permutation_importance(modell, X_test, y_te, scoring="roc_auc", n_repeats=20, random_state=0)
    t = pd.DataFrame({"Mittel": pi.importances_mean, "Std": pi.importances_std}, index=X_test.columns)
    print(titel)
    print(t.sort_values("Mittel", ascending=False).round(3).to_string(), "\n")

zeige_pi(wald, X_te, "Permutation Importance (AUC-Abfall)")

# --- Grenze: korreliertes Duplikat verteilt die Wichtigkeit ---
X2_tr, X2_te = X_tr.copy(), X_te.copy()
rng2 = np.random.default_rng(0)
X2_tr["einkommen_netto"] = 0.75 * X2_tr["einkommen"] + rng2.normal(0, 40, len(X2_tr))
X2_te["einkommen_netto"] = 0.75 * X2_te["einkommen"] + rng2.normal(0, 40, len(X2_te))
wald2 = RandomForestClassifier(n_estimators=200, min_samples_leaf=20, random_state=0).fit(X2_tr, y_tr)
zeige_pi(wald2, X2_te, "Mit Duplikat 'einkommen_netto'")

# --- Lokal: exakte Shapley-Werte gegen eine Baseline (alle 2^n Teilmengen) ---
def shapley(f, x: np.ndarray, baseline: np.ndarray) -> np.ndarray:
    """Merkmale außerhalb der Koalition werden durch die Baseline ersetzt."""
    d = len(x)
    phi = np.zeros(d)
    for i in range(d):
        rest = [j for j in range(d) if j != i]
        for k in range(d):
            gewicht = factorial(k) * factorial(d - k - 1) / factorial(d)
            for S in combinations(rest, k):
                a = baseline.copy(); a[list(S)] = x[list(S)]
                b = a.copy(); b[i] = x[i]
                phi[i] += gewicht * (f(b[None, :])[0] - f(a[None, :])[0])
    return phi

baseline = X_tr.mean().to_numpy()
person = X_te.iloc[[0]].to_numpy()[0]
f_wald = lambda M: wald.predict_proba(pd.DataFrame(M, columns=X.columns))[:, 1]
phi = shapley(f_wald, person, baseline)
print("Exakte Shapley-Werte für Antrag 0 (Wahrscheinlichkeit 'bewilligt'):")
print(pd.Series(phi, index=X.columns).round(3).to_string())
f_b, f_x = f_wald(baseline[None, :])[0], f_wald(person[None, :])[0]
print(f"Baseline f(b) = {f_b:.3f} | Vorhersage f(x) = {f_x:.3f}"
      f" | Summe = {phi.sum():.3f} = f(x) - f(b): {np.isclose(phi.sum(), f_x - f_b)}\n")

# --- Probe an einem linearen Modell: Shapley = coef * (x - baseline) ---
lin = make_pipeline(StandardScaler(), LogisticRegression(max_iter=1000)).fit(X_tr, y_tr)
f_lin = lambda M: lin.decision_function(pd.DataFrame(M, columns=X.columns))
w = lin[-1].coef_[0] / lin[0].scale_
print("Shapley (Brute Force) == coef*(x-b) beim linearen Modell:",
      bool(np.allclose(shapley(f_lin, person, baseline), w * (person - baseline))))

# --- Integrated Gradients (numerischer Gradient) am linearen Modell mit Sigmoid-Ausgang ---
f_prob = lambda M: lin.predict_proba(pd.DataFrame(M, columns=X.columns))[:, 1]
def integrated_gradients(f, x, b, schritte=200, eps=1e-4):
    ig = np.zeros(len(x))
    for a in (np.arange(schritte) + 0.5) / schritte:           # Mittelpunktsregel auf dem Pfad b -> x
        punkt = b + a * (x - b)
        for i in range(len(x)):
            h = eps * max(1.0, abs(x[i]))
            hoch, runter = punkt.copy(), punkt.copy()
            hoch[i] += h; runter[i] -= h
            ig[i] += (f(hoch[None, :])[0] - f(runter[None, :])[0]) / (2 * h) / schritte
    return (x - b) * ig
ig = integrated_gradients(f_prob, person, baseline)
print("Integrated Gradients (logistisches Modell):")
print(pd.Series(ig, index=X.columns).round(3).to_string())
diff = f_prob(person[None, :])[0] - f_prob(baseline[None, :])[0]
print(f"Summe IG = {ig.sum():.4f} | f(x) - f(b) = {diff:.4f}")

"""Lösungen zu den Aufgaben P2 bis P7 (Problem Representation).

Start: uv run --with scikit-learn --with pandas --with numpy python 02_problem.py
"""
import json
import math

import numpy as np
from scipy.stats import betabinom, binom
from sklearn.linear_model import LogisticRegression

# --- P2: Softmax gegen Sigmoid ------------------------------------------------------
print("P2  Logits (2,2; 1,9; -0,5; -2,0) für die Tags A, B, C, D")
z = np.array([2.2, 1.9, -0.5, -2.0])
softmax = np.exp(z) / np.exp(z).sum()
sigmoid = 1 / (1 + np.exp(-z))
print("softmax:", np.round(softmax, 3), "Summe", round(softmax.sum(), 3))
print("sigmoid:", np.round(sigmoid, 3), "Summe", round(sigmoid.sum(), 3))

# --- P3: Mehrheitsentscheid -------------------------------------------------------------
print("\nP3  Mehrheitsentscheid von k Klassifikatoren mit je 70 % Genauigkeit")
p = 0.7


def mehrheit_unabhaengig(k):
    return binom.sf((k - 1) // 2, k, p)


def mehrheit_korreliert(k, s):
    """Jedes Beispiel hat eine Schwierigkeit q ~ Beta(p s, (1-p) s); gegeben q sind die Modelle unabhängig."""
    return betabinom.sf((k - 1) // 2, k, p * s, (1 - p) * s)


print("k=3 (3 * 0,7^2 * 0,3 + 0,7^3):", round(mehrheit_unabhaengig(3), 4), "| von Hand:", round(3 * 0.49 * 0.3 + 0.343, 4))
print("k=5:", round(mehrheit_unabhaengig(5), 4))
ks = list(range(1, 22, 2))
kurven = {}
for name, s in (("unabhängig", None), ("schwach korreliert", 6), ("stark korreliert", 2)):
    kurven[name] = [mehrheit_unabhaengig(k) if s is None else mehrheit_korreliert(k, s) for k in ks]
    rho = "" if s is None else f" (Korrelation der Treffer {1 / (s + 1):.2f})"
    print(f"{name + rho:<46} k=3: {kurven[name][1]:.4f}  k=5: {kurven[name][2]:.4f}  k=21: {kurven[name][-1]:.4f}")
from scipy.stats import beta  # noqa: E402

print("Grenzwert für k -> unendlich:", {s: round(float(beta.sf(0.5, p * s, (1 - p) * s)), 4) for s in (6, 2)})

# --- P4: Cascade ----------------------------------------------------------------------
print("\nP4  Cascade: 100 000 Zahlungen am Tag, 1 % Betrug")
N, betrug = 100_000, 1_000
durch_anteil, r1, r2, fpr2 = 0.08, 0.96, 0.90, 0.01
cent_je_abfrage = 0.4
durch = N * durch_anteil
betrug_durch = betrug * r1
harmlos_durch = durch - betrug_durch
tp2 = betrug_durch * r2
fp2 = harmlos_durch * fpr2
print(f"Stufe 2 prüft {durch:.0f} Zahlungen, davon {betrug_durch:.0f} Betrug und {harmlos_durch:.0f} harmlos")
print(f"Kosten der teuren Abfragen: {N * cent_je_abfrage / 100:.0f} Euro (alle) gegen {durch * cent_je_abfrage / 100:.0f} Euro (Cascade)")
print(f"Ersparnis: {(1 - durch_anteil) * 100:.0f} % = {(N - durch) * cent_je_abfrage / 100:.0f} Euro am Tag")
print(f"Gesamt-Recall: {r1} * {r2} = {r1 * r2:.3f}; Treffer {tp2:.0f}, Fehlalarme {fp2:.0f}, Precision {tp2 / (tp2 + fp2):.3f}")

# --- P5: Konfusionsmatrizen ---------------------------------------------------------------
print("\nP5  Zwei Schwellen auf denselben 10 000 Zahlungen (100 Betrugsfälle)")
for name, tp, fp, fn, tn in (("A (Schwelle hoch)", 80, 40, 20, 9860), ("B (Schwelle niedrig)", 90, 150, 10, 9750)):
    n = tp + fp + fn + tn
    prec, rec = tp / (tp + fp), tp / (tp + fn)
    f1 = 2 * prec * rec / (prec + rec)
    kosten = fn * 200 + fp * 5
    print(f"{name:<22} n={n} Genauigkeit {(tp + tn) / n:.4f} Precision {prec:.3f} Recall {rec:.3f} F1 {f1:.3f} Kosten {kosten} Euro")
print("Immer \"kein Betrug\": Genauigkeit", 9900 / 10000, "Kosten", 100 * 200, "Euro")

# --- P6: Neutral Class ------------------------------------------------------------------------
print("\nP6  Drei Labeler, je mit Wahrscheinlichkeit q für \"positiv\"")
for q in (0.55, 0.65, 0.90):
    mehrheit_pos = 3 * q ** 2 * (1 - q) + q ** 3
    einig = q ** 3 + (1 - q) ** 3
    print(f"q={q}: Mehrheitslabel positiv {mehrheit_pos:.4f}, alle drei einig {einig:.4f}, 2:1 {1 - einig:.4f}")

# --- P7: Undersampling und Wahrscheinlichkeiten -------------------------------------------------
print("\nP7  Undersampling der Mehrheitsklasse")
n_kunden, positive = 50_000, 1_000
neg = n_kunden - positive
behalten = 10_000
beta_ = behalten / neg
print(f"Negative: {neg}, behalten: {behalten}, Faktor beta = {beta_:.4f}")
print(f"class_weight=balanced: Gewicht positiv {n_kunden / (2 * positive):.1f}, negativ {n_kunden / (2 * neg):.4f}")


def korrigiere(p_sample, beta_):
    odds = p_sample / (1 - p_sample) * beta_
    return odds / (1 + odds)


print(f"Modell sagt 0,5 -> wahre Wahrscheinlichkeit {korrigiere(0.5, beta_):.4f}")
print(f"Modell sagt 0,9 -> wahre Wahrscheinlichkeit {korrigiere(0.9, beta_):.4f}")

rng = np.random.default_rng(7)


def kunden(n):
    X = rng.normal(size=(n, 3))
    logit = -5.0 + 1.2 * X[:, 0] + 0.8 * X[:, 1] + 0.5 * X[:, 2]
    return X, (rng.random(n) < 1 / (1 + np.exp(-logit))).astype(int)


X_tr, y_tr = kunden(n_kunden)
X_te, y_te = kunden(n_kunden)
print(f"\nSimulation: Anteil positiv im Training {y_tr.mean():.4f}, im Test {y_te.mean():.4f}")
voll = LogisticRegression(max_iter=1000).fit(X_tr, y_tr)
pos = np.flatnonzero(y_tr == 1)
neg_idx = np.flatnonzero(y_tr == 0)
behalte = rng.choice(neg_idx, size=len(pos) * 10, replace=False)
sel = np.concatenate([pos, behalte])
beta_sim = len(behalte) / len(neg_idx)
unter = LogisticRegression(max_iter=1000).fit(X_tr[sel], y_tr[sel])
p_unter = unter.predict_proba(X_te)[:, 1]
print(f"mittlere P(positiv): voll trainiert {voll.predict_proba(X_te)[:, 1].mean():.4f}, "
      f"unterabgetastet {p_unter.mean():.4f}, korrigiert {korrigiere(p_unter, beta_sim).mean():.4f}, wahr {y_te.mean():.4f}")

with open("ensemble_p3.json", "w") as f:
    json.dump({"k": ks, **kurven}, f)

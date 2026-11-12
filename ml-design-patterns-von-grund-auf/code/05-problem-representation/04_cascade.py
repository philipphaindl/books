"""Pattern 8, Variante Konfidenz-Kaskade: billiges Modell vor teurem Modell bei einem seltenen Ereignis (ca. 1 %)."""
import json
from pathlib import Path

import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import precision_score, recall_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

# 60.000 künstliche Zahlungen, ca. 1 % Betrug. Vier Merkmale sind billig (stehen in
# der Zahlung selbst), 16 sind teuer (Abfragen bei anderen Diensten). Betrug zeigt
# sich in beiden Gruppen, in den billigen deutlicher.
rng = np.random.default_rng(0)
n = 60_000
y = (rng.random(n) < 0.01).astype(int)
billig = rng.normal(size=(n, 4)) + 1.6 * y[:, None]
teuer = rng.normal(size=(n, 16)) + 0.6 * y[:, None]
X = np.hstack([billig, teuer])
Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.4, random_state=0, stratify=y)
print(f"positive Beispiele: {y.mean():.2%} (Test: {yte.sum()} von {len(yte):,})")

# Stufe 1: einfaches Modell nur auf den billigen Merkmalen. Die Schwelle liegt so
# niedrig, dass im Training 95 % der Betrugsfälle durchkommen.
s1 = make_pipeline(StandardScaler(), LogisticRegression())
s1.fit(Xtr[:, :4], ytr)
p_tr = s1.predict_proba(Xtr[:, :4])[:, 1]
schwelle = np.quantile(p_tr[ytr == 1], 0.05)
durch_tr = p_tr >= schwelle
durch_te = s1.predict_proba(Xte[:, :4])[:, 1] >= schwelle
print(f"Stufe 1: lässt {durch_te.mean():.1%} durch,"
      f" Recall {recall_score(yte, durch_te):.3f}")

# Stufe 2: stärkeres Modell auf allen Merkmalen, trainiert nur auf dem, was
# Stufe 1 durchlässt (so sieht es im Betrieb auch aus)
s2 = HistGradientBoostingClassifier(max_iter=100, random_state=0)
s2.fit(Xtr[durch_tr], ytr[durch_tr])
pred = np.zeros(len(yte), dtype=int)
pred[durch_te] = s2.predict(Xte[durch_te])
print(f"Stufe 2 auf den Durchgelassenen: "
      f"Recall {recall_score(yte[durch_te], pred[durch_te]):.3f}")
print(f"Kaskade gesamt: Recall {recall_score(yte, pred):.3f}"
      f"  Precision {precision_score(yte, pred):.3f}")

# Vergleich: das stärkere Modell auf allen Zahlungen
m_alle = HistGradientBoostingClassifier(max_iter=100, random_state=0).fit(Xtr, ytr)
pa = m_alle.predict(Xte)
print(f"Modell auf allen: Recall {recall_score(yte, pa):.3f}"
      f"  Precision {precision_score(yte, pa):.3f}")
print(f"Abfragen der teuren Merkmale: Kaskade {durch_te.sum():,}"
      f" statt {len(yte):,}")

# Fehlerfortpflanzung: Recall der Kaskade = Recall 1 * Recall 2
r1 = recall_score(yte, durch_te)
r2 = recall_score(yte[durch_te], pred[durch_te])
print(f"Recall 1 * Recall 2 = {r1:.3f} * {r2:.3f} = {r1 * r2:.3f}")
Path(__file__).with_name("cascade.json").write_text(json.dumps({
    "n": int(len(yte)), "pos": int(yte.sum()), "durch": int(durch_te.sum()),
    "r1": round(float(r1), 3), "r2": round(float(r2), 3),
    "r_gesamt": round(float(recall_score(yte, pred)), 3),
    "p_gesamt": round(float(precision_score(yte, pred)), 3),
    "r_alle": round(float(recall_score(yte, pa)), 3),
    "p_alle": round(float(precision_score(yte, pa)), 3)}))

"""Pattern 19: Two-Phase Predictions - kleines Modell am Rand, grosses in der Cloud."""
import time

import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import average_precision_score
from sklearn.preprocessing import StandardScaler

from auswertung import *
from pumpen import *

t = tabelle()
t = t[t.rul_h.notna()]
tr, va, te = zeit_split(t)

EDGE = ["vib_delta", "vib_anstieg", "temp_delta"]
cloud = HistGradientBoostingClassifier(random_state=0).fit(tr[NAMEN], tr.fail24)
sk = StandardScaler().fit(tr[EDGE])
edge = LogisticRegression(class_weight="balanced")
edge.fit(sk.transform(tr[EDGE]), tr.fail24)
# auf Rohwerte umgerechnet: Score = Merkmale @ w + b
w = edge.coef_[0] / sk.scale_
b = edge.intercept_[0] - (w * sk.mean_).sum()

def edge_score(X):         # nur eine Multiplikation: laeuft auf dem Gateway
    return X[EDGE].to_numpy() @ w + b


# Schwelle: 98 % der Positiven der Validierung sollen Stufe 1 passieren
e_va, e_te = edge_score(va), edge_score(te)
th_edge = np.quantile(e_va[va.fail24 == 1], 0.02)
weiter = e_te >= th_edge
print(f"Edge-Schwelle auf Validierung: Recall {(e_va[va.fail24 == 1] >= th_edge).mean():.3f}")
print(f"Anteil der Testzeilen, die an die Cloud gehen: {weiter.mean():.1%}")
print(f"Positive im Test, die Stufe 1 passieren: {weiter[te.fail24 == 1].mean():.1%}")

p_cloud = cloud.predict_proba(te[NAMEN])[:, 1]
p_zwei = np.where(weiter, p_cloud, 0.0)         # nicht weitergereicht = 0
p_va = cloud.predict_proba(va[NAMEN])[:, 1]
stufen = np.linspace(0.70, 0.995, 60)
th, _ = beste_schwelle(va, p_va, np.quantile(p_va, stufen))
th_e, _ = beste_schwelle(va, e_va, np.quantile(e_va, stufen))
print(f"\n{'Variante':<28}{'PR-AUC':>8}{'erkannt':>9}{'Fehlalarme':>12}{'Kosten/Test':>13}")
for name, p, schwelle in [("nur Cloud", p_cloud, th), ("nur Edge", e_te, th_e),
                          ("zweistufig", p_zwei, th)]:
    e, n, f = ereignis_bilanz(te, p >= schwelle)
    k = f"{kosten(e, n, f):,}".replace(",", ".")
    print(f"{name:<28}{average_precision_score(te.fail24, p):>8.3f}{f'{e}/{n}':>9}{f:>12}{k:>13}")

# Laufzeit je Einzelvorhersage (auf diesem Rechner gemessen)
x1, a1 = te[NAMEN].iloc[[0]], te[EDGE].iloc[0].to_numpy()


def median_us(f, n=300):
    d = []
    for _ in range(n):
        t0 = time.perf_counter()
        f()
        d.append(time.perf_counter() - t0)
    return np.median(d) * 1e6


print(f"\nMedian je Einzelvorhersage: Edge {median_us(lambda: a1 @ w + b):.1f} us, "
      f"Cloud-Modell (lokal) {median_us(lambda: cloud.predict_proba(x1)):.0f} us")

# Hochrechnung fuer eine Flotte (Annahmen, keine Messwerte)
pumpen, pro_tag, preis = 2000, 24 * 60 // SCHRITT, 0.40
ohne, mit = pumpen * pro_tag, pumpen * pro_tag * weiter.mean()


def eur(x):
    return f"{x:,.0f}".replace(",", ".")


print(f"\nFlotte: {pumpen} Pumpen, {pro_tag} Vorhersagen/Tag, {preis:.2f} EUR je 1000 Aufrufe")
print(f"  alles in die Cloud: {eur(ohne)} Aufrufe/Tag = {eur(ohne / 1000 * preis * 365)} EUR/Jahr")
print(f"  zweistufig:         {eur(mit)} Aufrufe/Tag = {eur(mit / 1000 * preis * 365)} EUR/Jahr")
ersparnis = (ohne - mit) / 1000 * preis * 365 / pumpen
print(f"  Ersparnis: {ersparnis:.2f} EUR je Pumpe und Jahr")

# Gegenrechnung: Kosten der zusaetzlichen Fehler der zweistufigen Variante
tage = (te.minute.max() - te.minute.min() + SCHRITT) / MIN_TAG
pumpenjahre = te.pumpe.nunique() * tage / 365
mehr = kosten(*ereignis_bilanz(te, p_zwei >= th)) - kosten(*ereignis_bilanz(te, p_cloud >= th))
print(f"Mehrkosten durch Fehler im Test: {mehr} EUR bei {pumpenjahre:.2f} Pumpenjahren")
print(f"  = {mehr / pumpenjahre:.0f} EUR je Pumpe und Jahr")

"""Pattern 8 Cascade (Variante des Buchs): ein Router wählt, welcher Spezialist die Aufgabe löst."""
import json
from pathlib import Path

import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import average_precision_score, roc_auc_score
from sklearn.model_selection import train_test_split

# 40.000 künstliche Schadensmeldungen. 25 % kommen von Werkstätten, 75 % von Privatkunden.
# Betrug (4 %) zeigt sich in beiden Gruppen am Merkmal x0, aber in entgegengesetzter Richtung.
# Das Segment steht nicht in der Meldung; der Router muss es aus drei anderen Merkmalen r schätzen.
rng = np.random.default_rng(4)
n = 40_000
werkstatt = (rng.random(n) < 0.25).astype(int)
betrug = (rng.random(n) < 0.04).astype(int)
x = rng.normal(size=(n, 3))
x[:, 0] += np.where(werkstatt == 1, -1.2, 1.2) * betrug       # Richtung hängt vom Segment ab
r = rng.normal(size=(n, 3)) + 1.5 * werkstatt[:, None]        # Hinweise auf das Segment
idx = np.arange(n)
tr, te = train_test_split(idx, test_size=0.4, random_state=0, stratify=betrug * 2 + werkstatt)

def bewerte(name, score):
    print(f"{name:42s} ROC-AUC {roc_auc_score(betrug[te], score):.3f}"
          f"  PR-AUC {average_precision_score(betrug[te], score):.3f}")
    return {"name": name, "auc": round(float(roc_auc_score(betrug[te], score)), 3),
            "ap": round(float(average_precision_score(betrug[te], score)), 3)}

ergebnis = []
# a) ein lineares Modell für alle Meldungen
alle = LogisticRegression().fit(x[tr], betrug[tr])
ergebnis.append(bewerte("ein lineares Modell auf allen", alle.predict_proba(x[te])[:, 1]))

# b) ein Baummodell, das das Segment nur indirekt über die Merkmale r sieht
xr = np.hstack([x, r])
baum = HistGradientBoostingClassifier(random_state=0).fit(xr[tr], betrug[tr])
ergebnis.append(bewerte("ein Baummodell auf x und r", baum.predict_proba(xr[te])[:, 1]))

# c) Cascade: Router (Segment aus r) und je ein linearer Spezialist, trainiert auf dem WAHREN Segment
router = LogisticRegression().fit(r[tr], werkstatt[tr])
spez = {s: LogisticRegression().fit(x[tr][werkstatt[tr] == s], betrug[tr][werkstatt[tr] == s]) for s in (0, 1)}
seg_hat = router.predict(r[te])
print(f"Router-Genauigkeit auf den Testdaten: {np.mean(seg_hat == werkstatt[te]):.1%}")

def kaskade(seg):
    s = np.zeros(len(te))
    for k in (0, 1):
        m = seg == k
        s[m] = spez[k].predict_proba(x[te][m])[:, 1]
    return s

ergebnis.append(bewerte("Cascade: Router + 2 Spezialisten", kaskade(seg_hat)))
ergebnis.append(bewerte("Cascade mit wahrem Segment (Orakel)", kaskade(werkstatt[te])))
fehl = seg_hat != werkstatt[te]
print(f"falsch geroutet: {fehl.mean():.1%}; AUC nur über diese Fälle: "
      f"{roc_auc_score(betrug[te][fehl], kaskade(seg_hat)[fehl]):.3f}")
Path(__file__).with_name("cascade_router.json").write_text(json.dumps(
    {"ergebnis": ergebnis, "router_acc": round(float(np.mean(seg_hat == werkstatt[te])), 3)}, ensure_ascii=False))

"""Pattern 22: Repeatable Splitting - Zeile, Pumpe, Zeit, Pumpe und Zeit."""
import hashlib

from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import average_precision_score

from pumpen import *

t = tabelle()
t["tag"] = t.minute / MIN_TAG


def bucket(pumpe, n=10):
    """Stabil ueber Laeufe und Rechner (Pythons hash() ist es nicht)."""
    return int(hashlib.md5(pumpe.encode()).hexdigest(), 16) % n


t["bucket"] = t.pumpe.map(bucket)
test_pumpe = t.bucket >= 7              # 30 % der Pumpen
vor, nach = t.tag < 30, t.tag >= 46     # 3 Tage Luecke > Horizont (24 h)
alle = t.index

schemata = {
    "zufaellig je Zeile": (t.sample(frac=0.7, random_state=0).index, None),
    "nach Pumpe (Hash)": (alle[~test_pumpe], alle[test_pumpe]),
    "zeitlich": (alle[vor], alle[nach]),
    "nach Pumpe und zeitlich": (alle[~test_pumpe & vor], alle[test_pumpe & nach]),
}
print(f"{'Schema':<26}{'Training':>9}{'Test':>8}{'Positiv':>9}{'Ausf.':>7}{'PR-AUC':>8}")
for name, (tr, te) in schemata.items():
    if te is None:
        te = alle.difference(tr)
    a, b = t.loc[tr], t.loc[te]
    m = HistGradientBoostingClassifier(random_state=0).fit(a[NAMEN], a.fail24)
    ap = average_precision_score(b.fail24, m.predict_proba(b[NAMEN])[:, 1])
    ausfaelle = b[b.fail24 == 1].groupby(["pumpe", "zyklus"]).ngroups
    print(f"{name:<26}{len(a):>9}{len(b):>8}{b.fail24.mean():>9.1%}"
          f"{ausfaelle:>7}{ap:>8.3f}")

pumpen = sorted(t.pumpe.unique())
print("Test-Pumpen:", " ".join(p for p in pumpen if bucket(p) >= 7))
pd.DataFrame({"pumpe": pumpen, "test": [int(bucket(p) >= 7) for p in pumpen]}
             ).to_csv("out/split_pumpen.csv", index=False)

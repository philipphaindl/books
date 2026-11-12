"""Schritt 4, Pattern 10 Rebalancing: Accuracy-Falle, Gewichte, Schwellwert, PR-Kurve."""
import numpy as np
import pandas as pd
from sklearn.metrics import precision_recall_curve

from daten import ZIEL, lade_daten, teile
from modell import (ALLE0, ENTWICKLUNG_BIS, ERFOLGSQUOTE, KOSTEN_ANGEBOT, SCHWELLE, WERT, bester_schwellwert,
                    kennzahlen, modell_hgb, nutzen, speichere)

dev = lade_daten()
dev = dev[dev.monat <= ENTWICKLUNG_BIS]
X = pd.get_dummies(dev[ALLE0]).astype(float)
tr, va, te = teile(dev)
print(f"Training {len(tr):,} | Validierung {len(va):,} | Test {len(te):,}")


def fit(idx, **kw):
    return modell_hgb(**kw).fit(X.loc[idx], dev.loc[idx, ZIEL])


def proba(m, d):
    return m.predict_proba(X.loc[d.index])[:, 1]


schwelle_kosten = SCHWELLE


m_plain = fit(tr.index)
m_gew = fit(tr.index, class_weight="balanced")
neg = tr.index[tr[ZIEL] == 0]
pos = tr.index[tr[ZIEL] == 1]
rng = np.random.default_rng(0)
m_down = fit(pos.union(pd.Index(rng.choice(neg, size=4 * len(pos), replace=False))))

p_plain, p_gew, p_down = proba(m_plain, te), proba(m_gew, te), proba(m_down, te)
v_plain, v_gew = proba(m_plain, va), proba(m_gew, va)
s_plain = bester_schwellwert(va[ZIEL], v_plain)
s_gew = bester_schwellwert(va[ZIEL], v_gew)

varianten = [
    ("A  Schwelle 0.5", p_plain, 0.5),
    ("B  Gewichte, Schwelle 0.5", p_gew, 0.5),
    ("C  Downsampling 1:4, Schw. 0.5", p_down, 0.5),
    (f"D  F1-Schwelle {s_plain:.2f}", p_plain, s_plain),
    (f"E  Gewichte, F1-Schwelle {s_gew:.2f}", p_gew, s_gew),
    (f"F  Kostenregel, Schwelle {schwelle_kosten:.2f}", p_plain, schwelle_kosten),
]
y = te[ZIEL].to_numpy()
print(f"\nNiemand kündigt: Accuracy {1 - y.mean():.3f}")
print(f"{'Variante':<32}{'Acc':>6}{'Prec':>6}{'Rec':>6}{'F1':>6}{'PR-AUC':>7}{'Euro':>7}")
ergebnis = {}
for name, p, s in varianten:
    k = kennzahlen(y, p, s)
    k["nutzen"] = nutzen(k, len(y)); k["schwelle"] = float(s)
    ergebnis[name[0]] = k
    print(f"{name:<32}{k['accuracy']:>6.3f}{k['precision']:>6.3f}{k['recall']:>6.3f}{k['f1']:>6.3f}"
          f"{k['ap']:>7.3f}{k['nutzen']:>7.0f}")

print("(Euro = Nutzen je 1000 Kunden-Monate)")
print(f"\nMittlere Wahrscheinlichkeit: ohne Gewichte {p_plain.mean():.3f}, mit {p_gew.mean():.3f}; tatsächlich {y.mean():.3f}")

# Daten für die PR-Kurve (Abbildung im Kapitel)
def kurve(p):
    prec, rec, _ = precision_recall_curve(y, p)
    grid = np.linspace(0, 1, 51)
    return [[float(r), float(q)] for r, q in zip(grid, np.interp(grid, rec[::-1], prec[::-1]))]


speichere("04_rebalancing", {"varianten": ergebnis, "basisrate": float(y.mean()),
                             "kurve_plain": kurve(p_plain), "kurve_gew": kurve(p_gew),
                             "mittel_plain": float(p_plain.mean()), "mittel_gew": float(p_gew.mean()),
                             "kosten": {"angebot": KOSTEN_ANGEBOT, "erfolg": ERFOLGSQUOTE, "wert": WERT, "schwelle": schwelle_kosten}})

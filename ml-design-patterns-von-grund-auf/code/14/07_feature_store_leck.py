"""Fallstudie C, Pattern 26 Feature Store: Point-in-Time-korrekte Popularität, Leck und Behebung."""
import json
from pathlib import Path

import numpy as np
from sklearn.metrics import roc_auc_score

from gemeinsam import lade_zeilen, metriken, modell
from merkmale import Merkmale

E = np.load(Path(__file__).with_name("out") / "embedding.npy")
MODI = {"gesamt": "gesamter Datensatz", "mit_tag": "7 Tage bis einschließlich heute", "pit": "7 Tage bis gestern (Point in Time)"}
daten = {m: lade_zeilen(m) for m in MODI}
_, z_pit, train = daten["pit"]

# --- 1) Alarmzeichen: ein einzelnes Popularitätsfeature, das zu gut ist ------------------------------------------------
print("Kaufrate der drei Produkte allein als Score (AUC, Testtage):")
einzel = {}
for m, text in MODI.items():
    zt = daten[m][1][~train]
    einzel[m] = roc_auc_score(zt.kauf, zt.rate_7d)
    print(f"  {text:<38} AUC {einzel[m]:.3f}")

# --- 2) Training mit jeder Variante, Test offline (gleiche Variante) und online (so, wie der Dienst sie berechnet) --------
print(f"\n{'Training mit':<38} {'AUC offline':>12} {'AUC online':>11} {'Differenz':>10}")
erg = []
for m_tr, text in MODI.items():
    tr = daten[m_tr][1][train]
    mk = Merkmale(ids="hash", kreuz=True, band=True, text=True, embedding=E, store=True).fit(tr)
    clf = modell().fit(mk.transform(tr), tr.kauf)
    off = daten[m_tr][1][~train]
    on = daten["pit"][1][~train]
    a_off = metriken(off.kauf, clf.predict_proba(mk.transform(off))[:, 1])
    a_on = metriken(on.kauf, clf.predict_proba(mk.transform(on))[:, 1])
    print(f"{text:<38} {a_off['auc']:>12.3f} {a_on['auc']:>11.3f} {a_on['auc'] - a_off['auc']:>+10.3f}")
    erg.append({"modus": m_tr, "text": text, "offline": a_off, "online": a_on})

# Referenz: dasselbe Modell ganz ohne Popularitätsfeatures
tr = z_pit[train]
mk = Merkmale(ids="hash", kreuz=True, band=True, text=True, embedding=E, store=False).fit(tr)
clf = modell().fit(mk.transform(tr), tr.kauf)
te = z_pit[~train]
ohne = metriken(te.kauf, clf.predict_proba(mk.transform(te))[:, 1])
print(f"{'ohne Popularitätsfeatures':<38} {ohne['auc']:>12.3f} {ohne['auc']:>11.3f} {0:>+10.3f}")

Path(__file__).with_name("feature_store.json").write_text(json.dumps({"lauf": erg, "ohne": ohne, "einzel": einzel}))

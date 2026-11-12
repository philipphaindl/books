"""Fallstudie C, Pattern 1 Hashed Feature: Produkt-ID und Marke ohne Wörterbuch."""
import json
from pathlib import Path

import numpy as np

from gemeinsam import lade_zeilen, metriken, modell
from merkmale import Merkmale, bucket

d, z, train = lade_zeilen("pit")
tr, te = z[train], z[~train]
produkte = d["produkte"]

# --- 1) Kollisionen: Anteil der Schlüssel, die ihren Bucket mit mindestens einem anderen teilen ------------
def kollision(werte, b, salz):
    werte = np.unique(werte)
    zaehler = np.bincount(bucket(list(werte), b, salz), minlength=b)
    return float((zaehler[bucket(list(werte), b, salz)] > 1).mean())

ids = produkte.produkt_id.to_numpy()
marken = produkte.marke.unique()
print(f"{'Buckets':>8} | {'Produkt-IDs':>26} | {'Marken':>24}")
print(f"{'':>8} | {'gemessen':>12} {'Formel':>12} | {'gemessen':>11} {'Formel':>11}")
kol = []
for e in (6, 8, 10, 12, 14, 16, 18):
    b = 2 ** e
    k_id, k_m = kollision(ids, b, "produkt"), kollision(marken, b, "marke")
    f_id, f_m = 1 - (1 - 1 / b) ** (len(ids) - 1), 1 - (1 - 1 / b) ** (len(marken) - 1)
    print(f"{b:>8,} | {k_id:>12.1%} {f_id:>12.1%} | {k_m:>11.1%} {f_m:>11.1%}")
    kol.append({"b": b, "id": k_id, "id_formel": f_id, "marke": k_m, "marke_formel": f_m})

# --- 2) Wirkung auf das Modell ---------------------------------------------------------------------------------
gesehen = set(tr.produkt_id) | set(tr.vorher_1) | set(tr.vorher_2)
neu = ~te.produkt_id.isin(gesehen).to_numpy()
print(f"\nTest: {len(te):,} Sitzungen; unbekanntes Produkt: {neu.sum():,} ({neu.mean():.1%}), {int(te.kauf[neu].sum())} Käufe")


def lauf(name, **kw):
    m = Merkmale(**kw).fit(tr)
    X = m.transform(tr)
    clf = modell().fit(X, tr.kauf)
    p = clf.predict_proba(m.transform(te))[:, 1]
    g, u = metriken(te.kauf, p), metriken(te.kauf[neu], p[neu])
    print(f"{name:<34} {X.shape[1]:>8,} {g['auc']:>8.3f} {g['ap']:>8.3f} {u['auc']:>10.3f}")
    return {"name": name, "spalten": X.shape[1], "auc": g["auc"], "ap": g["ap"], "auc_neu": u["auc"]}


print(f"{'Variante (Marke: Wörterbuch)':<34} {'Spalten':>8} {'AUC':>8} {'AP':>8} {'AUC neu':>10}")
erg = [lauf("Produkt-ID weglassen", ids=None),
       lauf("Produkt-ID mit Wörterbuch", ids="vokabular")]
for e in (8, 10, 12, 14, 16):
    erg.append(lauf(f"Produkt-ID gehasht, B = 2^{e}", ids="hash", b_id=2 ** e))

print(f"\n{'Variante (Produkt-ID weggelassen)':<34} {'Spalten':>8} {'AUC':>8} {'AP':>8} {'AUC neu':>10}")
erg_m = [lauf("Marke weglassen", ids=None, marke=None),
         lauf("Marke mit Wörterbuch", ids=None, marke="vokabular")]
for e in (4, 6, 8, 10):
    erg_m.append(lauf(f"Marke gehasht, B = 2^{e}", ids=None, marke="hash", b_marke=2 ** e))

# --- 3) Unbekannte Werte: Wörterbuch ignoriert sie, Hash weist ihnen einen Bucket zu -----------------------------
m_v = Merkmale(ids="vokabular").fit(tr)
m_h = Merkmale(ids="hash", b_id=2 ** 14).fit(tr)
beispiel = te[neu].head(1)
spalten_v = m_v.transform(beispiel)[:, -len(m_v.vok_marke) - len(m_v.vok_id):-len(m_v.vok_marke)]
print(f"\nneues Produkt {int(beispiel.produkt_id.iloc[0])}: aktive ID-Spalten mit Wörterbuch = {spalten_v.nnz}, "
      f"mit Hash = 1 (Bucket {int(bucket(beispiel.produkt_id.to_numpy(), 2 ** 14, 'produkt')[0])})")

Path(__file__).with_name("hashed_feature.json").write_text(json.dumps({"kollision": kol, "id": erg, "marke": erg_m}))

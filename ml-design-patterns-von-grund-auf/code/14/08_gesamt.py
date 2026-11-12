"""Fallstudie C, Zusammenfassung: Wirkung der Patterns, einzeln und aufeinander aufbauend."""
import json
from pathlib import Path

import numpy as np

from gemeinsam import lade_zeilen, metriken, modell
from merkmale import Merkmale

d, z, train = lade_zeilen("pit")
tr, te = z[train], z[~train]
E = np.load(Path(__file__).with_name("out") / "embedding.npy")
gesehen = set(tr.produkt_id) | set(tr.vorher_1) | set(tr.vorher_2)
neu = ~te.produkt_id.isin(gesehen).to_numpy()
print(f"Test: {len(te):,} Sitzungen, {int(te.kauf.sum()):,} Käufe")
print(f"unbekanntes Produkt: {neu.sum():,} Sitzungen, {int(te.kauf[neu].sum())} Käufe")

# Die Zutaten in Reihenfolge der Patterns im Buch. Jede Zutat ist ein Schalter von Merkmale.
ZUTATEN = [
    ("Hashed Feature (Produkt-ID, B = 2^14)", dict(ids="hash")),
    ("Embeddings (32 Dim., Mittel der 3 Produkte)", dict(embedding=E)),
    ("Feature Cross (Kategorie x Preisband)", dict(band=True, kreuz=True)),
    ("Multimodal Input (Titeltext TF-IDF)", dict(text=True)),
    ("Feature Store (Popularität, Point in Time)", dict(store=True)),
]
BASIS = dict(ids="vokabular", marke="vokabular")


def lauf(**kw):
    m = Merkmale(**kw).fit(tr)
    X = m.transform(tr)
    pr = modell().fit(X, tr.kauf).predict_proba(m.transform(te))[:, 1]
    return X.shape[1], metriken(te.kauf, pr), metriken(te.kauf[neu], pr[neu])["auc"]


spalten, g, un = lauf(**BASIS)
zeilen = [{"name": "Ausgangsmodell (Wörterbuch für ID und Marke)", "spalten": spalten, **g, "auc_neu": un, "einzeln": g["auc"]}]
kum = dict(BASIS)
print(f"\n{'Stufe':<46} {'Spalten':>8} {'AUC einzeln':>12} {'AUC kumuliert':>14} {'AP':>6} {'LogLoss':>8} {'AUC neu':>8}")
print(f"{zeilen[0]['name']:<46} {spalten:>8,} {'':>12} {g['auc']:>14.3f} {g['ap']:>6.3f} {g['logloss']:>8.4f} {un:>8.3f}")
for name, kw in ZUTATEN:
    _, g1, _ = lauf(**{**BASIS, **kw})                 # Zutat allein zum Ausgangsmodell
    kum.update(kw)
    spalten, g, un = lauf(**kum)                       # alle bisherigen Zutaten zusammen
    zeilen.append({"name": name, "spalten": spalten, **g, "auc_neu": un, "einzeln": g1["auc"]})
    print(f"+ {name:<44} {spalten:>8,} {g1['auc']:>12.3f} {g['auc']:>14.3f} {g['ap']:>6.3f} {g['logloss']:>8.4f} {un:>8.3f}")

Path(__file__).with_name("gesamt.json").write_text(json.dumps({"stufen": zeilen, "n_test": len(te), "n_neu": int(neu.sum())}))

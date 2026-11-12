"""Fallstudie C, Pattern 3 Feature Cross: Kategorie x Preisband."""
import json
from pathlib import Path

import numpy as np

import shop
from gemeinsam import lade_zeilen, metriken, modell
from merkmale import Merkmale, preisband

d, z, train = lade_zeilen("pit")
tr, te = z[train], z[~train]
z["band"] = preisband(z.preis.to_numpy())
tr_b = z[train]

# --- 1) Kaufrate je Kategorie und Preisband (nur Trainingsdaten) ------------------------------------------------
tab = tr_b.groupby(["kategorie", "band"]).kauf.agg(["mean", "size"]).reset_index()
rate = {(r.kategorie, r.band): (r["mean"], r["size"]) for _, r in tab.iterrows()}
bands = len(shop.PREISBAND_GRENZEN) + 1
print("Kaufrate in % (Zahl der Trainingssitzungen in Klammern bei weniger als 200):")
print(f"{'':<13}" + "".join(f"{'<' + str(g) if i < bands - 1 else '>700':>8}" for i, g in enumerate(shop.PREISBAND_GRENZEN + [None])))
for k in shop.KAT:
    zeile = ""
    for b in range(bands):
        r, n = rate.get((k, b), (np.nan, 0))
        zeile += f"{'-' if n < 200 else format(100 * r, '.1f'):>8}"
    print(f"{k:<13}{zeile}")

# --- 2) Modelle ---------------------------------------------------------------------------------------------------------
print(f"\n{'Variante':<46} {'Spalten':>8} {'AUC':>7} {'AP':>7} {'LogLoss':>9}")


def lauf(name, **kw):
    m = Merkmale(ids=None, marke="vokabular", **kw).fit(tr)
    X = m.transform(tr)
    clf = modell().fit(X, tr.kauf)
    pr = clf.predict_proba(m.transform(te))[:, 1]
    g = metriken(te.kauf, pr)
    print(f"{name:<46} {X.shape[1]:>8,} {g['auc']:>7.3f} {g['ap']:>7.3f} {g['logloss']:>9.4f}")
    return {"name": name, "spalten": X.shape[1], **g}


erg = [lauf("Kategorie + log(Preis), linear"),
       lauf("+ Preisband (8 Spalten, für alle Kategorien gleich)", band=True),
       lauf("+ Kreuz Kategorie x Preisband (96 Spalten)", band=True, kreuz=True)]

# --- 3) Vorzeichen des Preiseffekts je Kategorie: günstigstes gegen teuerstes ausreichend belegtes Band ----------------
print("\nKaufrate im günstigsten und im teuersten Band mit mindestens 200 Trainingssitzungen:")
for k in shop.KAT:
    belegt = [b for b in range(bands) if rate.get((k, b), (0, 0))[1] >= 200]
    lo, hi = rate[(k, belegt[0])][0], rate[(k, belegt[-1])][0]
    print(f"  {k:<13} {100 * lo:5.1f} % -> {100 * hi:5.1f} %   {'steigt' if hi > lo else 'fällt'} mit dem Preis")

Path(__file__).with_name("feature_cross.json").write_text(json.dumps({
    "rate": [[k, b, float(rate[(k, b)][0]) if rate.get((k, b), (0, 0))[1] >= 200 else None] for k in shop.KAT for b in range(bands)],
    "kategorien": shop.KAT, "modelle": erg}))

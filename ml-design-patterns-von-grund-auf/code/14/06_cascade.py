"""Fallstudie C, Pattern 8 Cascade: erst 'kauft die Sitzung?', dann 'welche Kategorie?'."""
import json
from pathlib import Path

import numpy as np
import scipy.sparse as sp
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score

import shop
from gemeinsam import lade_zeilen, metriken, modell
from merkmale import Merkmale

d, z, train = lade_zeilen("pit")
p = d["produkte"]
E = np.load(Path(__file__).with_name("out") / "embedding.npy")
kat_nr = p.kategorie.map({k: i for i, k in enumerate(shop.KAT)}).to_numpy()
K = len(shop.KAT)
tr, te = z[train], z[~train]

# Merkmale: das volle Modell der Fallstudie plus, wie oft jede Kategorie unter den drei Ansichten vorkommt
f = Merkmale(ids="hash", kreuz=True, band=True, text=True, embedding=E, store=True).fit(tr)


def matrix(df):
    zaehl = np.zeros((len(df), K))
    for spalte in ("produkt_id", "vorher_1", "vorher_2"):
        zaehl[np.arange(len(df)), kat_nr[df[spalte].to_numpy()]] += 1
    return sp.hstack([f.transform(df), sp.csr_matrix(zaehl)], format="csr")


X_tr, X_te = matrix(tr), matrix(te)
kat_tr = np.array([shop.KAT.index(k) if k else -1 for k in tr.kauf_kategorie])
kat_te = np.array([shop.KAT.index(k) if k else -1 for k in te.kauf_kategorie])
kauf_tr, kauf_te = tr.kauf.to_numpy(), te.kauf.to_numpy()
print(f"Trainingssitzungen {len(tr):,}, davon Käufe {kauf_tr.sum():,}; Testsitzungen {len(te):,}, davon Käufe {kauf_te.sum():,}")

# Variante A: ein Modell mit 13 Klassen (0 = kein Kauf, 1..12 = Kategorie)
mono = LogisticRegression(C=0.5, max_iter=1000).fit(X_tr, kat_tr + 1)
P_m = mono.predict_proba(X_te)                      # Spalten: Klasse 0 .. 12
p_kauf_m = 1 - P_m[:, 0]
kat_m = P_m[:, 1:].argmax(1)

# Variante B: Cascade. Stufe 1 auf allen Zeilen, Stufe 2 nur auf den Käufern
stufe1 = modell().fit(X_tr, kauf_tr)
p_kauf_c = stufe1.predict_proba(X_te)[:, 1]
kaeufer = kauf_tr == 1
stufe2 = LogisticRegression(C=0.5, max_iter=1000).fit(X_tr[kaeufer], kat_tr[kaeufer])
kat_c = stufe2.classes_[stufe2.predict_proba(X_te).argmax(1)]

# --- Referenzen: einfache Heuristik und häufigste Kategorie
kat_heur = kat_nr[te.produkt_id.to_numpy()]
haeufigste = np.bincount(kat_tr[kauf_tr == 1]).argmax()

kb = kauf_te == 1
print(f"\n{'':<32} {'Kauf-AUC':>9} {'Kategorie richtig':>18}")
print(f"{'ein Modell, 13 Klassen':<32} {roc_auc_score(kauf_te, p_kauf_m):>9.3f} {(kat_m[kb] == kat_te[kb]).mean():>18.1%}")
print(f"{'Cascade (Stufe 1 + Stufe 2)':<32} {roc_auc_score(kauf_te, p_kauf_c):>9.3f} {(kat_c[kb] == kat_te[kb]).mean():>18.1%}")
print(f"{'Heuristik: Kategorie der Seite':<32} {'':>9} {(kat_heur[kb] == kat_te[kb]).mean():>18.1%}")
print(f"{'immer die häufigste Kategorie':<32} {'':>9} {(haeufigste == kat_te[kb]).mean():>18.1%}")

# --- Betrieb: nur die 20 % aussichtsreichsten Sitzungen bekommen eine Kategorie-Vorhersage ----------------------------
print("\nBetrieb: Stufe 2 nur für die Sitzungen mit dem höchsten Score")
print(f"{'Anteil an Stufe 2':>18} {'Käufer erfasst':>16} {'Kategorie richtig (erfasst)':>28}")
zeilen = []
for anteil in (0.10, 0.20, 0.30, 1.00):
    schwelle = np.quantile(p_kauf_c, 1 - anteil) if anteil < 1 else -1
    durch = p_kauf_c >= schwelle
    erfasst = durch & kb
    acc = (kat_c[erfasst] == kat_te[erfasst]).mean()
    print(f"{anteil:>18.0%} {erfasst.sum() / kb.sum():>16.1%} {acc:>28.1%}")
    zeilen.append({"anteil": anteil, "erfasst": float(erfasst.sum() / kb.sum()), "acc": float(acc)})
print(f"\nTrainingszeilen: ein Modell {len(tr):,} x 13 Klassen; Stufe 1 {len(tr):,} x 2; Stufe 2 {int(kauf_tr.sum()):,} x {K}")

Path(__file__).with_name("cascade.json").write_text(json.dumps({
    "auc_mono": float(roc_auc_score(kauf_te, p_kauf_m)), "auc_cascade": float(roc_auc_score(kauf_te, p_kauf_c)),
    "acc_mono": float((kat_m[kb] == kat_te[kb]).mean()), "acc_cascade": float((kat_c[kb] == kat_te[kb]).mean()),
    "acc_heur": float((kat_heur[kb] == kat_te[kb]).mean()), "betrieb": zeilen,
    "n_train": int(len(tr)), "n_kaeufer": int(kauf_tr.sum())}))

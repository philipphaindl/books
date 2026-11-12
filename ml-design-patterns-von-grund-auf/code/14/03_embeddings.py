"""Fallstudie C, Pattern 2 Embeddings: Produktvektoren aus Ko-Klick-Daten (PPMI + SVD)."""
import json
from pathlib import Path

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import Ridge

import shop
from embedding import DIM, kookkurrenz, lerne_embeddings
from gemeinsam import lade_zeilen, metriken, modell
from merkmale import Merkmale

d, z, train = lade_zeilen("pit")
p, s, ans = d["produkte"], d["sitzungen"], d["ans"]
n = len(p)
ans_train = ans[(s.tag < shop.TEST_AB).to_numpy()]

c = kookkurrenz(ans_train, n)
print(f"Ko-Klick-Matrix: {c.shape[0]:,} x {c.shape[1]:,}, {c.nnz:,} belegte Zellen "
      f"({c.nnz / c.shape[0] ** 2:.3%})")
E, m, svd = lerne_embeddings(ans_train, n)
bekannt = np.linalg.norm(E, axis=1) > 0
print(f"PPMI-Matrix: {m.nnz:,} Einträge, Rang {DIM}, Embedding-Tabelle {E.shape}")
print(f"Produkte mit Vektor: {int(bekannt.sum()):,}, ohne (nie gemeinsam gesehen): {int((~bekannt).sum()):,}")
np.save(Path(__file__).with_name("out") / "embedding.npy", E)

# --- Nachbarn -----------------------------------------------------------------------------------------------------
haeufig = np.flatnonzero(c.sum(1).A1 >= 60)
print(f"Produkte mit mindestens 60 Ko-Klicks: {len(haeufig):,}")


def nachbarn(i, k=4):
    kos = E @ E[i]
    kos[i] = -1
    kos[~bekannt] = -1
    top = np.argsort(-kos)[:k]
    return [(int(t), float(kos[t])) for t in top]


rng = np.random.default_rng(1)
for kat in ("Zelte", "Uhren", "Schuhe"):
    i = int(rng.choice([h for h in haeufig if p.kategorie[h] == kat]))
    print(f"\n{p.titel[i]} ({p.kategorie[i]}, Welt {p.welt[i]})")
    for t, k in nachbarn(i):
        print(f"   {k:5.2f}  {p.titel[t]:<38} {p.kategorie[t]:<13} {p.welt[t]}")

# --- Wie gut sind die Nachbarn? Anteil der 10 nächsten Nachbarn mit derselben Welt ---------------------------------------
welt = p.welt.to_numpy()
stichprobe = rng.choice(haeufig, 1500, replace=False)
treffer = []
for i in stichprobe:
    kos = E @ E[i]
    kos[i] = -1
    kos[~bekannt] = -1
    treffer.append((welt[np.argsort(-kos)[:10]] == welt[i]).mean())
zufall = float(np.sum((p.welt.value_counts(normalize=True)) ** 2))
print(f"\nGleiche Welt unter den 10 nächsten Nachbarn: {np.mean(treffer):.0%} (Zufall: {zufall:.0%}); "
      f"gleiche Kategorie: {np.mean([(p.kategorie.to_numpy()[np.argsort(-(E @ E[i]))[1:11]] == p.kategorie[i]).mean() for i in stichprobe]):.0%}")

# --- Wirkung auf das Modell -----------------------------------------------------------------------------------------------
tr, te = z[train], z[~train]
gesehen = set(tr.produkt_id) | set(tr.vorher_1) | set(tr.vorher_2)
neu = ~te.produkt_id.isin(gesehen).to_numpy()


def lauf(name, **kw):
    mm = Merkmale(**kw).fit(tr)
    clf = modell().fit(mm.transform(tr), tr.kauf)
    pr = clf.predict_proba(mm.transform(te))[:, 1]
    g, u = metriken(te.kauf, pr), metriken(te.kauf[neu], pr[neu])
    print(f"{name:<44} {g['auc']:>7.3f} {g['ap']:>7.3f} {g['logloss']:>9.4f} {u['auc']:>9.3f}")
    return {"name": name, **g, "auc_neu": u["auc"]}


print(f"\n{'Variante':<44} {'AUC':>7} {'AP':>7} {'LogLoss':>9} {'AUC neu':>9}")
v0 = lauf("ohne Embedding (ohne ID, Marke Wörterbuch)", ids=None)
v1 = lauf(f"+ Embedding-Mittel der drei Produkte ({DIM} Dim.)", ids=None, embedding=E)

# --- Kaltstart-Brücke: Embedding aus dem Titel vorhersagen ---------------------------------------------------------------
tf = TfidfVectorizer(min_df=2, sublinear_tf=True).fit(p.titel[bekannt])
ridge = Ridge(alpha=1.0).fit(tf.transform(p.titel[bekannt]), E[bekannt])
E_br = E.copy()
E_br[~bekannt] = ridge.predict(tf.transform(p.titel[~bekannt]))
nrm = np.linalg.norm(E_br, axis=1, keepdims=True)
E_br = np.divide(E_br, nrm, out=np.zeros_like(E_br), where=nrm > 0)
unbek = np.flatnonzero(~bekannt & (p.start_tag.to_numpy() >= 0))[:400]
tr_b = []
for i in unbek:
    kos = E[bekannt] @ E_br[i]
    top = np.flatnonzero(bekannt)[np.argsort(-kos)[:10]]
    tr_b.append((welt[top] == welt[i]).mean())
print(f"\nKaltstart-Brücke: für {len(unbek)} Produkte ohne Ko-Klicks wird der Vektor aus dem Titel geschätzt; "
      f"gleiche Welt unter den 10 Nachbarn: {np.mean(tr_b):.0%}")
v2 = lauf("+ Embedding mit Titel-Brücke für neue Produkte", ids=None, embedding=E_br)

# --- 2-D-Projektion für die Abbildung (nur zur Darstellung) -----------------------------------------------------------------
auswahl_welten = ["Camping", "Golf", "Tauchen"]
pts = []
for w in auswahl_welten:
    ix = [h for h in haeufig if welt[h] == w][:100]
    pts += [(int(h), w) for h in ix]
X = E[[h for h, _ in pts]]
X = X - X.mean(0)
u, sv, vt = np.linalg.svd(X, full_matrices=False)
xy = X @ vt[:2].T
Path(__file__).with_name("embeddings.json").write_text(json.dumps({
    "punkte": [{"welt": w, "x": round(float(a), 3), "y": round(float(b), 3)} for (h, w), (a, b) in zip(pts, xy)],
    "anteil_varianz": float((sv[:2] ** 2).sum() / (sv ** 2).sum()),
    "treffer": float(np.mean(treffer)), "bruecke": float(np.mean(tr_b)), "zufall": zufall,
    "modelle": [v0, v1, v2],
}))
print(f"Anteil der Varianz der beiden Achsen in der Abbildung: {(sv[:2] ** 2).sum() / (sv ** 2).sum():.0%}")

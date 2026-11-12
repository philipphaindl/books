"""Fallstudie C, Pattern 4 Multimodal Input: Titeltext (TF-IDF) und Tabellenmerkmale zusammen."""
import json
from pathlib import Path

import numpy as np

from gemeinsam import lade_zeilen, metriken, modell
from merkmale import Merkmale

d, z, train = lade_zeilen("pit")
tr, te = z[train], z[~train]
gesehen = set(tr.produkt_id) | set(tr.vorher_1) | set(tr.vorher_2)
neu = ~te.produkt_id.isin(gesehen).to_numpy()

print(f"{'Eingabe des Modells':<24} {'Spalten':>8} {'AUC':>7} {'AP':>7} {'LogLoss':>9} {'AUC neu':>9}")
erg = []
modelle = {}


def lauf(name, **kw):
    m = Merkmale(**kw).fit(tr)
    X = m.transform(tr)
    clf = modell().fit(X, tr.kauf)
    pr = clf.predict_proba(m.transform(te))[:, 1]
    g, u = metriken(te.kauf, pr), metriken(te.kauf[neu], pr[neu])
    print(f"{name:<24} {X.shape[1]:>8,} {g['auc']:>7.3f} {g['ap']:>7.3f} {g['logloss']:>9.4f} {u['auc']:>9.3f}")
    erg.append({"name": name, "spalten": X.shape[1], **g, "auc_neu": u["auc"]})
    modelle[name] = (m, clf)


lauf("nur Tabelle", ids=None)
lauf("nur Titeltext", ids=None, marke=None, tabelle=False, text=True)
lauf("Tabelle und Titeltext", ids=None, text=True)

# --- Was hat der Text gelernt? Wörter mit den größten Gewichten ----------------------------------------------------------
m, clf = modelle["Tabelle und Titeltext"]
w = clf.coef_[0][-len(m.tfidf.vocabulary_):]
wort = np.array(m.tfidf.get_feature_names_out())
o = np.argsort(w)
print("\nWörter, die die Kaufwahrscheinlichkeit am stärksten erhöhen:", ", ".join(f"{wort[i]} ({w[i]:+.2f})" for i in o[::-1][:6]))
print("Wörter, die sie am stärksten senken:", ", ".join(f"{wort[i]} ({w[i]:+.2f})" for i in o[:6]))
print(f"Titelvokabular: {len(wort)} Wörter; Spalten der Tabellenhälfte: {erg[0]['spalten']}")

Path(__file__).with_name("multimodal.json").write_text(json.dumps({"modelle": erg}))

"""Trainiert die beiden Modellversionen des Dienstes und legt sie samt Popularitäts-Schnappschuss ab."""
from pathlib import Path

import joblib
import numpy as np

import shop
from gemeinsam import lade_zeilen, metriken, modell
from merkmale import Merkmale
from store import Protokoll

ordner = Path(__file__).with_name("modelle")
ordner.mkdir(exist_ok=True)
d, z, train = lade_zeilen("pit")
tr, te = z[train], z[~train]
E = np.load(Path(__file__).with_name("out") / "embedding.npy")

VERSIONEN = {
    "v1": ("Tabelle, gehashte ID, Kreuz Kategorie x Preis", dict(ids="hash", band=True, kreuz=True)),
    "v2": ("v1 + Titeltext, Embeddings, Popularität",
           dict(ids="hash", band=True, kreuz=True, text=True, embedding=E, store=True)),
}
for version, (beschreibung, kw) in VERSIONEN.items():
    m = Merkmale(**kw).fit(tr)
    clf = modell().fit(m.transform(tr), tr.kauf)
    auc = metriken(te.kauf, clf.predict_proba(m.transform(te))[:, 1])["auc"]
    joblib.dump({"version": version, "beschreibung": beschreibung, "trainingstage": f"0-{shop.TEST_AB - 1}",
                 "auc_test": round(auc, 3), "merkmale": m, "klassifikator": clf}, ordner / f"{version}.joblib")
    print(f"{version}: {beschreibung}  (AUC auf Tag {shop.TEST_AB}-{shop.TAGE - 1}: {auc:.3f})")

# Schnappschuss der Popularität "heute" (Tag 70): Fenster Tag 63 bis 69, für alle Produkte
pr = Protokoll(d["ansichten_tag"], d["kaeufe_tag"])
alle = np.arange(len(d["produkte"]))
ans, kauf = pr.fenster(np.full(len(alle), shop.TAGE), alle, "pit")
np.savez(ordner / "store.npz", ans=ans, kauf=kauf)
print(f"Feature-Store-Schnappschuss für {len(alle):,} Produkte gespeichert")

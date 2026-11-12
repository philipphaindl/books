"""Gemeinsame Bausteine der Skripte: Datensatz laden, Zeilen bauen, Zeitsplit, Metriken, Modell."""
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import average_precision_score, log_loss, roc_auc_score

import shop
from store import Protokoll, aggregiere


def lade_zeilen(modus="pit"):
    """Eine Zeile je Sitzung (Zustand nach der dritten Ansicht), Popularität nach `modus` (siehe store.py)."""
    d = shop.lade()
    p, s = d["produkte"], d["sitzungen"]
    z = pd.DataFrame({
        "tag": s.tag, "stunde": s.stunde, "geraet": s.geraet,
        "produkt_id": s.produkt_3, "vorher_1": s.produkt_1, "vorher_2": s.produkt_2,
        "kategorie": p.kategorie.to_numpy()[s.produkt_3], "marke": p.marke.to_numpy()[s.produkt_3],
        "preis": p.preis.to_numpy()[s.produkt_3], "titel": p.titel.to_numpy()[s.produkt_3],
        "welt": p.welt.to_numpy()[s.produkt_3],
        "kauf": s.kauf, "kauf_kategorie": s.kauf_kategorie,
    })
    pr = Protokoll(d["ansichten_tag"], d["kaeufe_tag"])
    tag = s.tag.to_numpy()
    paare = [pr.fenster(tag, s[f"produkt_{i}"].to_numpy(), modus) for i in (1, 2, 3)]
    ans = np.column_stack([a for a, _ in paare])
    kauf = np.column_stack([k for _, k in paare])
    for name, werte in aggregiere(ans, kauf).items():
        z[name] = werte
    train = (s.tag < shop.TEST_AB).to_numpy()
    return d, z, train


def modell():
    return LogisticRegression(C=0.5, max_iter=2000)


def metriken(y, p):
    return {"auc": roc_auc_score(y, p), "ap": average_precision_score(y, p), "logloss": log_loss(y, p)}

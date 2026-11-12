"""Schritt 7, Pattern 30 Fairness Lens: Kennzahlen je Altersgruppe, dann gruppenspezifische Schwellen."""
import joblib
import numpy as np
import pandas as pd

from daten import ZIEL, lade_daten, teile
from modell import ALLE, ENTWICKLUNG_BIS, OUT, SCHWELLE, kennzahlen, nutzen, speichere

dev = lade_daten()
dev = dev[dev.monat <= ENTWICKLUNG_BIS]
tr, va, te = teile(dev)
pipe = joblib.load(OUT / "modell_v1.joblib")
GRUPPEN = ["18-24", "25-39", "40-54", "55+"]
for d in (va, te):
    d["p"] = pipe.predict_proba(d[ALLE])[:, 1]


def tabelle(d, schwellen):
    zeilen = []
    for g in GRUPPEN:
        z = d[d.altersgruppe == g]
        k = kennzahlen(z[ZIEL], z.p, schwellen[g])
        fpr = k["fp"] / max(k["fp"] + k["tn"], 1)
        zeilen.append({"gruppe": g, "n": len(z), "basisrate": float(z[ZIEL].mean()), "markiert": k["markiert"],
                       "precision": k["precision"], "recall": k["recall"], "fpr": fpr, "ap": k["ap"], "nutzen": nutzen(k, len(z))})
    k = kennzahlen(d[ZIEL], d.p, np.array([schwellen[g] for g in d.altersgruppe]))
    zeilen.append({"gruppe": "gesamt", "n": len(d), "basisrate": float(d[ZIEL].mean()), "markiert": k["markiert"],
                   "precision": k["precision"], "recall": k["recall"], "fpr": k["fp"] / (k["fp"] + k["tn"]), "ap": k["ap"], "nutzen": nutzen(k, len(d))})
    return pd.DataFrame(zeilen)


def zeige(t):
    print(t.to_string(index=False, formatters={c: "{:.3f}".format for c in ["basisrate", "markiert", "precision", "recall", "fpr", "ap"]} | {"nutzen": "{:.0f}".format}))


gleich = {g: SCHWELLE for g in GRUPPEN}
vorher = tabelle(te, gleich)
print(f"Eine Schwelle für alle ({SCHWELLE:.3f}), Testkunden")
zeige(vorher)

# Gegenmaßnahme: Gruppen, deren Recall unter dem Gesamt-Recall liegt, bekommen eine niedrigere Schwelle (Validierungsdaten);
# alle anderen behalten die gemeinsame Schwelle. Es wird also nur angehoben, nicht abgesenkt.
ziel_recall = kennzahlen(va[ZIEL], va.p, SCHWELLE)["recall"]
schwellen = {}
for g in GRUPPEN:
    z = va[va.altersgruppe == g]
    kandidaten = np.unique(np.round(z.p, 4))[::-1]
    if kennzahlen(z[ZIEL], z.p, SCHWELLE)["recall"] >= ziel_recall:
        schwellen[g] = SCHWELLE
    else:
        schwellen[g] = next(float(s) for s in kandidaten
                            if kennzahlen(z[ZIEL], z.p, s)["recall"] >= ziel_recall)
print(f"\nZiel-Recall (Validierung): {ziel_recall:.3f}")
val_recall = {g: kennzahlen(va[va.altersgruppe == g][ZIEL], va[va.altersgruppe == g].p, SCHWELLE)["recall"] for g in GRUPPEN}
print("Recall je Gruppe (Validierung): " + ", ".join(f"{g} {v:.2f}" for g, v in val_recall.items()))
print("Schwellen je Gruppe: " + ", ".join(f"{g} {s:.3f}" for g, s in schwellen.items()))
nachher = tabelle(te, schwellen)
zeige(nachher)
speichere("07_fairness", {"vorher": vorher.to_dict("records"), "nachher": nachher.to_dict("records"), "schwellen": schwellen, "ziel_recall": ziel_recall, "val_recall": val_recall})

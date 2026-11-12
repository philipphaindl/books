"""Overfitting sichtbar machen und mit Early Stopping, L2 und Dropout dämpfen (5 Wiederholungen)."""
import numpy as np

from daten import spirale
from mlp import MLP, speichere, trainiere

RAUSCHEN, EPOCHEN, GROESSEN = 0.8, 500, [2, 128, 128, 3]


def experiment(s):
    """Ein Durchlauf: 60 Trainings-, 300 Validierungs-, 300 Testbeispiele, alle neu gezogen."""
    X, y = spirale(n=20, rauschen=RAUSCHEN, seed=10 * s)
    val = spirale(n=100, rauschen=RAUSCHEN, seed=10 * s + 1)  # zum Wählen des Stopp-Zeitpunkts
    test = spirale(n=100, rauschen=RAUSCHEN, seed=10 * s + 2)  # nur zum Berichten

    def lauf(epochen=EPOCHEN, **opt):
        netz = MLP(GROESSEN, seed=s)
        v = trainiere(netz, X, y, epochen, lr=0.1, batch=20, rng=np.random.default_rng(s), val=val, **opt)
        p = netz.forward(test[0])[0]
        return v, float(netz.loss(p, test[1])), float((p.argmax(1) == test[1]).mean())

    ohne = lauf()
    beste = int(np.argmin(ohne[0]["val_loss"])) + 1  # Epoche mit dem niedrigsten Validierungs-Loss
    return {"ohne": ohne, "beste": beste, "frueh": lauf(epochen=beste), "l2": lauf(l2=0.01), "dropout": lauf(dropout=0.3)}


laeufe = [experiment(s) for s in range(5)]
print("Erster Durchlauf: niedrigster Val-Loss in Epoche", laeufe[0]["beste"], "| Val-Loss dort",
      round(min(laeufe[0]["ohne"][0]["val_loss"]), 3), "| Val-Loss am Ende", round(laeufe[0]["ohne"][0]["val_loss"][-1], 3))
print("Stopp-Epochen der 5 Durchläufe:", [l["beste"] for l in laeufe])
print("\nVariante            | Train-Loss | Test-Loss    | Test-Genauigkeit  (Mittel ± Std über 5 Durchläufe)")
tabelle = []
for name, schluessel in (("ohne", "ohne"), ("Early Stopping", "frueh"), ("L2 (0.01)", "l2"), ("Dropout (0.3)", "dropout")):
    tr = [l[schluessel][0]["loss"][-1] for l in laeufe]
    tl = [l[schluessel][1] for l in laeufe]
    ta = [l[schluessel][2] for l in laeufe]
    tabelle.append([name, float(np.mean(tr)), float(np.mean(tl)), float(np.std(tl)), float(np.mean(ta)), float(np.std(ta))])
    print(f"{name:19} | {np.mean(tr):.3f}      | {np.mean(tl):.3f} ± {np.std(tl):.3f} | {np.mean(ta):.3f} ± {np.std(ta):.3f}")
k = laeufe[0]
speichere("regularisierung", {"train": k["ohne"][0]["loss"], "val": k["ohne"][0]["val_loss"], "beste": k["beste"],
                              "l2_val": k["l2"][0]["val_loss"], "dropout_val": k["dropout"][0]["val_loss"],
                              "tabelle": tabelle, "stopp": [l["beste"] for l in laeufe]})

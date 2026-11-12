"""Schritt 6, Pattern 29 Explainable Predictions: Permutation Importance (global), Shapley-Schätzung (lokal)."""
import joblib
import numpy as np
import pandas as pd
from sklearn.inspection import permutation_importance
from sklearn.metrics import average_precision_score

from daten import ZIEL, lade_daten, teile
from modell import ALLE, ALLE0, ENTWICKLUNG_BIS, OUT, SCHWELLE, modell_hgb, pipeline, speichere

dev = lade_daten()
dev = dev[dev.monat <= ENTWICKLUNG_BIS]
tr, va, te = teile(dev)
v0 = joblib.load(OUT / "modell_v0.joblib")


def rangfolge(modell, spalten):
    pi = permutation_importance(modell, te[spalten], te[ZIEL], scoring="average_precision", n_repeats=5, random_state=0)
    return pd.DataFrame({"merkmal": spalten, "abfall": pi.importances_mean, "streuung": pi.importances_std}).sort_values("abfall", ascending=False)


# Global: wie stark sinkt die PR-AUC, wenn ein Merkmal durchgemischt wird?
rang0 = rangfolge(v0, ALLE0)
for m in ("anmeldetag", "bandbreite_mbit"):
    print(f"Modell aus Schritt 5, Wichtigkeit von {m}: {rang0.set_index('merkmal').abfall[m]:+.4f}")

# Konsequenz: Fingerabdruck-Spalten ohne fachliche Aussage fliegen raus
pipe = pipeline(modell_hgb(), mit_fingerabdruck=False).fit(tr[ALLE], tr[ZIEL])
joblib.dump(pipe, OUT / "modell_v1.joblib")
ap0 = average_precision_score(te[ZIEL], v0.predict_proba(te[ALLE0])[:, 1])
ap1 = average_precision_score(te[ZIEL], pipe.predict_proba(te[ALLE])[:, 1])
print(f"PR-AUC Test: mit Fingerabdruck-Spalten {ap0:.3f}, ohne {ap1:.3f}")
rang = rangfolge(pipe, ALLE)


# Lokal: Shapley-Werte, geschätzt über zufällige Reihenfolgen der Merkmale
def shapley_lokal(pipe, x, hintergrund, n_reihen=400, seed=0):
    rng = np.random.default_rng(seed)
    d = len(ALLE)
    zeilen = rng.integers(len(hintergrund), size=n_reihen)
    basis = hintergrund[ALLE].to_numpy(dtype=object)[zeilen]
    reihen = np.array([rng.permutation(d) for _ in range(n_reihen)])
    xv = x[ALLE].to_numpy(dtype=object)
    # schritte[i, k]: Hintergrundkunde i, bei dem die ersten k Merkmale seiner
    # Reihenfolge durch die Werte von x ersetzt sind
    schritte = np.repeat(basis[:, None, :], d + 1, axis=1)
    for k in range(d):
        i, j = np.arange(n_reihen), reihen[:, k]
        schritte[i, k + 1:, j] = xv[j][:, None]
    tab = pd.DataFrame(schritte.reshape(-1, d), columns=ALLE).infer_objects()
    p = pipe.predict_proba(tab)[:, 1].reshape(n_reihen, d + 1)
    phi = np.zeros(d)
    for k in range(d):
        np.add.at(phi, reihen[:, k], p[:, k + 1] - p[:, k])
    return phi / n_reihen, p[:, 0].mean(), p[0, -1]


# Ein Kunde aus den Testdaten: tatsächlicher Abwanderer, vom Modell markiert, unteres Viertel der Treffer (kein Extremfall)
p_te = pipe.predict_proba(te[ALLE])[:, 1]
treffer = te[(te[ZIEL] == 1) & (p_te >= SCHWELLE)].assign(p=p_te[(te[ZIEL] == 1) & (p_te >= SCHWELLE)])
fall = treffer.iloc[(treffer.p - treffer.p.quantile(0.25)).abs().argmin()]
hintergrund = tr.sample(2000, random_state=0)
phi, basis, vorhersage = shapley_lokal(pipe, fall, hintergrund)
phi2, _, _ = shapley_lokal(pipe, fall, hintergrund, seed=1)
print(f"\nKunde {fall.kunden_id}, Monat {fall.monat}: Vorhersage {vorhersage:.3f}, Basis {basis:.3f}")
print(f"Summe der Beiträge {phi.sum():+.4f} = Vorhersage - Basis {vorhersage - basis:+.4f}")
ausgabe = pd.DataFrame({"merkmal": ALLE, "wert": [f"{fall[m]:g}" if isinstance(fall[m], (int, float, np.number)) else fall[m] for m in ALLE],
                        "beitrag": phi, "andere_ziehung": phi2})
ausgabe = ausgabe.reindex(ausgabe.beitrag.abs().sort_values(ascending=False).index)
print(ausgabe.head(7).to_string(index=False, float_format=lambda v: f"{v:+.3f}"))
print(f"Rest ({len(ALLE) - 7} Merkmale): {ausgabe.beitrag.iloc[7:].sum():+.3f}")

speichere("06_erklaerung", {
    "rang0": rang0.to_dict("records"), "rang": rang.to_dict("records"), "ap0": float(ap0), "ap1": float(ap1),
    "fall": {"id": fall.kunden_id, "monat": int(fall.monat), "gruppe": fall.altersgruppe, "vorhersage": float(vorhersage), "basis": float(basis),
             "beitraege": [{"merkmal": r.merkmal, "wert": str(r.wert), "beitrag": float(r.beitrag)} for r in ausgabe.itertuples()]},
})

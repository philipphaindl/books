"""Schritt 8, Pattern 18 Continued Model Evaluation: Betrieb ab Monat 13, Drift ab Monat 16, Retraining."""
import joblib
import numpy as np
import pandas as pd
from sklearn.metrics import average_precision_score

from daten import DRIFT_AB, LETZTER_MONAT_MIT_LABEL, ZIEL, lade_daten, mit_bucket
from modell import ALLE, ENTWICKLUNG_BIS, OUT, SCHWELLE, kennzahlen, modell_hgb, nutzen, pipeline, speichere

df = mit_bucket(lade_daten())
train = df[(df.bucket < 6) & (df.monat <= ENTWICKLUNG_BIS)]
referenz = df[df.bucket.isin([6, 7]) & (df.monat <= ENTWICKLUNG_BIS)]       # Kunden, die das Modell nie gesehen hat
live = df[(df.bucket >= 8) & (df.monat > ENTWICKLUNG_BIS)]           # nur Test-Kunden, die nie im Training waren
v1 = joblib.load(OUT / "modell_v1.joblib")
live = live.assign(p1=v1.predict_proba(live[ALLE])[:, 1])


def psi(referenz, aktuell, kategorisch=False, bins=10):
    """Population Stability Index (Dezile der Referenz bzw. Kategorien)."""
    if kategorisch:
        kat = sorted(set(referenz) | set(aktuell))
        a = np.array([(referenz == k).mean() for k in kat])
        b = np.array([(aktuell == k).mean() for k in kat])
    else:
        q = np.linspace(0, 1, bins + 1)[1:-1]
        grenzen = np.unique(np.quantile(referenz, q))
        k = len(grenzen) + 1

        def anteile(x):
            n = np.bincount(np.searchsorted(grenzen, x), minlength=k)
            return n / n.sum()

        a, b = anteile(referenz), anteile(aktuell)
    a, b = np.maximum(a, 1e-4), np.maximum(b, 1e-4)
    return float(((b - a) * np.log(b / a)).sum())


ref_score = v1.predict_proba(referenz[ALLE])[:, 1]
zeilen = []
for m in range(ENTWICKLUNG_BIS + 1, LETZTER_MONAT_MIT_LABEL + 1):
    d = live[live.monat == m]
    k = kennzahlen(d[ZIEL], d.p1, SCHWELLE)
    zeilen.append({"monat": m, "n": len(d), "basisrate": float(d[ZIEL].mean()), "ap": k["ap"], "recall": k["recall"], "precision": k["precision"],
                   "nutzen": nutzen(k, len(d)),
                   "psi_tarif": psi(referenz.tarif.to_numpy(), d.tarif.to_numpy(), True),
                   "psi_preis": psi(referenz.preis.to_numpy(), d.preis.to_numpy()),
                   "psi_login": psi(referenz.tage_seit_login.to_numpy(), d.tage_seit_login.to_numpy()),
                   "psi_score": psi(ref_score, d.p1.to_numpy())})
t = pd.DataFrame(zeilen)
print(f"Modell v1 im Betrieb (Testkunden, Schwelle {SCHWELLE:.3f}); Drift ab Monat {DRIFT_AB}")
anzeige = t[["monat", "basisrate", "ap", "recall", "precision", "nutzen", "psi_tarif", "psi_preis", "psi_score"]]
print(anzeige.to_string(index=False, formatters={c: "{:.3f}".format for c in anzeige.columns if c not in ("monat", "nutzen")}
                        | {"nutzen": "{:.0f}".format}))

# Retraining in Monat 20: Ziele sind für alle Zeilen bis Monat 17 bekannt (Monat + 3 <= 20)
RETRAIN_VON, RETRAIN_BIS = 8, 17
neu_tr = df[(df.bucket < 6) & df.monat.between(RETRAIN_VON, RETRAIN_BIS)]
v2 = pipeline(modell_hgb(), mit_fingerabdruck=False).fit(neu_tr[ALLE], neu_tr[ZIEL])
joblib.dump(v2, OUT / "modell_v2.joblib")
spaet = live[live.monat > RETRAIN_BIS]
spaet = spaet.assign(p2=v2.predict_proba(spaet[ALLE])[:, 1])
vergleich = []
for name, spalte in (("v1", "p1"), ("v2", "p2")):
    k = kennzahlen(spaet[ZIEL], spaet[spalte], SCHWELLE)
    vergleich.append({"modell": name, "nutzen": nutzen(k, len(spaet)), **{x: k[x] for x in ("ap", "precision", "recall", "f1", "markiert")}})
    for m in range(RETRAIN_BIS + 1, LETZTER_MONAT_MIT_LABEL + 1):
        d = spaet[spaet.monat == m]
        vergleich[-1][f"ap_{m}"] = float(average_precision_score(d[ZIEL], d[spalte]))
print(f"\nMonate {RETRAIN_BIS + 1}-{LETZTER_MONAT_MIT_LABEL}: v1 gegen v2 (v2 trainiert auf Monaten {RETRAIN_VON}-{RETRAIN_BIS})")
print(pd.DataFrame(vergleich)[["modell", "nutzen", "ap", "precision", "recall", "f1"]].to_string(index=False, float_format=lambda v: f"{v:.3f}"))
speichere("08_monitoring", {"monate": t.to_dict("records"), "vergleich": vergleich, "retrain": [RETRAIN_VON, RETRAIN_BIS], "drift_ab": DRIFT_AB})

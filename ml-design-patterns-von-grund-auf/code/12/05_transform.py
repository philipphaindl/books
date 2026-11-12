"""Schritt 5, Pattern 21 Transform: Vorverarbeitung als Teil des Modells (sklearn Pipeline)."""
import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import average_precision_score

from daten import ZIEL, lade_daten, teile
from modell import (ALLE0, ENTWICKLUNG_BIS, ID_ARTIG, KAT, OUT, SCHIEF, SCHWELLE, ZAHL, kennzahlen, modell_hgb,
                    nutzen, pipeline, speichere)

dev = lade_daten()
dev = dev[dev.monat <= ENTWICKLUNG_BIS]
tr, va, te = teile(dev)
y_te = te[ZIEL]


def ap(pipe):
    pipe.fit(tr[ALLE0], tr[ZIEL])
    return average_precision_score(y_te, pipe.predict_proba(te[ALLE0])[:, 1]), pipe


# 1) Was bringt die Transformation? Logistische Regression ohne und mit log1p vor der Standardisierung
lr = lambda: LogisticRegression(max_iter=1000)
ap_lr_roh, _ = ap(pipeline(lr(), mit_log=False))
ap_lr_log, _ = ap(pipeline(lr(), mit_log=True))
ap_hgb_roh, _ = ap(pipeline(modell_hgb(), mit_log=False))
ap_hgb_log, pipe = ap(pipeline(modell_hgb(), mit_log=True))
print(f"Logistische Regression: PR-AUC {ap_lr_roh:.3f} ohne log1p, {ap_lr_log:.3f} mit log1p")
print(f"Gradient Boosting     : PR-AUC {ap_hgb_roh:.3f} ohne log1p, {ap_hgb_log:.3f} mit log1p")
print(f"Schiefe von 'stunden' vor/nach log1p: {te['stunden'].skew():.2f} / {np.log1p(te['stunden']).skew():.2f}")

# 2) Eine Reimplementierung im Service, die log1p vergisst, merkt niemand an einer Fehlermeldung
vor = pipe.named_steps["vor"]
mu_l, sd_l = vor.named_transformers_["log"]["skala"].mean_, vor.named_transformers_["log"]["skala"].scale_
mu_z, sd_z = vor.named_transformers_["zahl"].mean_, vor.named_transformers_["zahl"].scale_
kategorien = vor.named_transformers_["kat"].categories_


def service_features(anfragen: pd.DataFrame) -> np.ndarray:
    """Nachbau durch ein anderes Team: Mittelwerte stimmen, aber log1p fehlt."""
    teile_ = [(anfragen[SCHIEF].to_numpy() - mu_l) / sd_l,
              (anfragen[ZAHL + ID_ARTIG].to_numpy() - mu_z) / sd_z]
    for spalte, kat in zip(KAT, kategorien):
        teile_.append((anfragen[spalte].to_numpy()[:, None] == kat[None, :]).astype(float))
    return np.hstack(teile_)


kern = pipe.named_steps["modell"]
p_pipe = pipe.predict_proba(te[ALLE0])[:, 1]
p_serv = kern.predict_proba(service_features(te[ALLE0]))[:, 1]
korrekt_nachbau = kern.predict_proba(vor.transform(te[ALLE0]))[:, 1]
print(f"Pipeline vs. Einzelaufruf der Teile: größte Abweichung {np.abs(p_pipe - korrekt_nachbau).max():.1e}")
print(f"Service ohne log1p: PR-AUC {average_precision_score(y_te, p_serv):.3f} (Pipeline {ap_hgb_log:.3f})")
print(f"  mittlere Wahrscheinlichkeit {p_serv.mean():.3f} (Pipeline {p_pipe.mean():.3f})")
print(f"  Entscheidung ändert sich bei {((p_serv >= SCHWELLE) != (p_pipe >= SCHWELLE)).mean():.1%} der Zeilen")

# 3) Ein Tarif, den das Training nie gesehen hat
neu = te[ALLE0].head(5).copy(); neu["tarif"] = "mobil"
print("Unbekannter Tarif 'mobil', Pipeline :", np.round(pipe.predict_proba(neu)[:, 1], 3))
notebook = HistGradientBoostingClassifier(max_iter=20, random_state=0).fit(pd.get_dummies(tr[ALLE0]).astype(float), tr[ZIEL])
try:
    notebook.predict_proba(pd.get_dummies(neu).astype(float))
except ValueError as fehler:
    print("Unbekannter Tarif 'mobil', get_dummies:", type(fehler).__name__)
    print("  " + str(fehler).splitlines()[0])

# 4) Das Artefakt: Vorverarbeitung und Modell in einer Datei
joblib.dump(pipe, OUT / "modell_v0.joblib")
k = kennzahlen(y_te, p_pipe, SCHWELLE)
k["nutzen"] = nutzen(k, len(y_te))
print(f"modell_v0.joblib gespeichert (PR-AUC Test {k['ap']:.3f}).")

# Daten für die Histogramme im Kapitel: Stunden roh (Klassen von 10 h bis 100 h, Rest in der letzten Klasse) und nach log1p
roh = np.histogram(np.minimum(te["stunden"], 99.99), bins=np.arange(0, 101, 10))[0] / len(te)
logh = np.histogram(np.log1p(te["stunden"]), bins=np.linspace(0, 5, 11))[0] / len(te)
speichere("05_transform", {"hist_roh": roh.tolist(), "hist_log": logh.tolist(),
                           "schiefe_roh": float(te["stunden"].skew()), "schiefe_log": float(np.log1p(te["stunden"]).skew()), "ap_lr_roh": ap_lr_roh, "ap_lr_log": ap_lr_log, "ap_hgb_roh": ap_hgb_roh, "ap_hgb_log": ap_hgb_log,
                           "ap_service": float(average_precision_score(y_te, p_serv)),
                           "flip": float(((p_serv >= SCHWELLE) != (p_pipe >= SCHWELLE)).mean()), "v1": k})

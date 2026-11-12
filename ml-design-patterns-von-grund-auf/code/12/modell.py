"""Gemeinsame Bausteine ab Schritt 4: Merkmalslisten, Vorverarbeitung als Pipeline, Kennzahlen."""
import json
from pathlib import Path

import numpy as np
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import average_precision_score, precision_recall_curve
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import FunctionTransformer, OneHotEncoder, StandardScaler

OUT = Path(__file__).parent / "out"
OUT.mkdir(exist_ok=True)

ENTWICKLUNG_BIS = 12          # Monate 0..12 stehen zur Entwicklung bereit, danach beginnt der "Betrieb"
SCHIEF = ["stunden", "sessions", "tage_seit_login", "stunden_trend"]
ZAHL = ["alter", "tenure", "tickets_30d", "zahlungsfehler_90d", "preis", "aktion_restmonate"]
KAT = ["land", "tarif", "kanal", "geraet"]
ID_ARTIG = ["anmeldetag", "bandbreite_mbit"]     # je Kunde konstant, fachlich ohne Aussage: fliegt in Schritt 6 raus
ALLE0 = SCHIEF + ZAHL + ID_ARTIG + KAT            # Merkmale des naiven Notebooks
ALLE = SCHIEF + ZAHL + KAT                        # Merkmale ab Schritt 6


# Annahmen für die Kostenrechnung der Kampagne (angenommen, nicht gemessen)
KOSTEN_ANGEBOT, ERFOLGSQUOTE, WERT = 5.0, 0.30, 60.0       # Euro, Anteil, Euro
SCHWELLE = KOSTEN_ANGEBOT / (ERFOLGSQUOTE * WERT)           # Kontakt lohnt sich, wenn p * 0,3 * 60 > 5


def nutzen(k, n):
    """Erwarteter Nutzen der Kampagne in Euro je 1000 Kunden-Monate (aus den Kennzahlen kennzahlen())."""
    return (k["tp"] * ERFOLGSQUOTE * WERT - (k["tp"] + k["fp"]) * KOSTEN_ANGEBOT) / n * 1000


def vorverarbeitung(mit_log=True, mit_fingerabdruck=True) -> ColumnTransformer:
    """Schiefe Spalten: log1p und standardisieren; Zahlen: standardisieren; Kategorien: One-Hot."""
    log = "passthrough"
    if mit_log:
        log = FunctionTransformer(np.log1p, feature_names_out="one-to-one")
    zahlen = ZAHL + (ID_ARTIG if mit_fingerabdruck else [])
    return ColumnTransformer([
        ("log", Pipeline([("log", log), ("skala", StandardScaler())]), SCHIEF),
        ("zahl", StandardScaler(), zahlen),
        ("kat", OneHotEncoder(handle_unknown="ignore"), KAT),
    ])


def modell_gross(**kw) -> HistGradientBoostingClassifier:
    """Das große Modell des naiven Notebooks: viele Blätter, winzige Blattgröße, kaum Regularisierung."""
    return HistGradientBoostingClassifier(max_iter=300, learning_rate=0.1, max_leaf_nodes=127, min_samples_leaf=5,
                                          random_state=0, **kw)


def modell_hgb(**kw) -> HistGradientBoostingClassifier:
    """Das kleinere Modell: flache Bäume, große Blätter. Wird ab Schritt 3 verwendet."""
    return HistGradientBoostingClassifier(max_iter=200, learning_rate=0.05, max_leaf_nodes=15, min_samples_leaf=100,
                                          random_state=0, **kw)


def pipeline(schaetzer, mit_log=True, mit_fingerabdruck=True) -> Pipeline:
    return Pipeline([("vor", vorverarbeitung(mit_log, mit_fingerabdruck)), ("modell", schaetzer)])


def bester_schwellwert(y, p, ziel="f1"):
    """Schwelle mit maximalem F1 auf (y, p). Gehört auf die Validierungsdaten, nie auf den Test."""
    prec, rec, thr = precision_recall_curve(y, p)
    f1 = 2 * prec[:-1] * rec[:-1] / np.maximum(prec[:-1] + rec[:-1], 1e-12)
    return float(thr[np.argmax(f1)])


def kennzahlen(y, p, schwelle=0.5):
    y = np.asarray(y)
    pred = np.asarray(p) >= schwelle
    tp = int((pred & (y == 1)).sum()); fp = int((pred & (y == 0)).sum())
    fn = int((~pred & (y == 1)).sum()); tn = int((~pred & (y == 0)).sum())
    prec = tp / max(tp + fp, 1); rec = tp / max(tp + fn, 1)
    return {"accuracy": (tp + tn) / len(y), "precision": prec, "recall": rec,
            "f1": 2 * prec * rec / max(prec + rec, 1e-12), "ap": float(average_precision_score(y, p)),
            "markiert": float(pred.mean()), "tp": tp, "fp": fp, "fn": fn, "tn": tn}


def speichere(name: str, daten: dict) -> None:
    (OUT / f"{name}.json").write_text(json.dumps(daten, indent=1, ensure_ascii=False))

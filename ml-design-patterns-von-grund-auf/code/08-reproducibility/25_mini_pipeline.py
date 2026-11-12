"""Pattern 25 Workflow Pipeline: ein winziger DAG-Executor mit Caching nach Hash."""
import hashlib
import inspect
import json
import pickle
import tempfile
from graphlib import TopologicalSorter
from pathlib import Path

import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

def laden(p):
    rng = np.random.default_rng(0)
    X = rng.normal(size=(2000, 6))
    y = (X[:, 0] + X[:, 1] * X[:, 2] + rng.normal(0, 0.5, 2000) > 0).astype(int)
    return X, y

def teilen(p, laden):
    X, y = laden
    return train_test_split(X, y, test_size=0.25, random_state=0)

def trainieren(p, teilen):
    X_tr, _, y_tr, _ = teilen
    wald = RandomForestClassifier(n_estimators=p["n_estimators"], random_state=0)
    return wald.fit(X_tr, y_tr)

def evaluieren(p, teilen, trainieren):
    _, X_te, _, y_te = teilen
    return {"accuracy": round(float(trainieren.score(X_te, y_te)), 4)}

SCHRITTE = {"laden": laden, "teilen": teilen,
            "trainieren": trainieren, "evaluieren": evaluieren}
ABHAENGIG = {"laden": set(), "teilen": {"laden"}, "trainieren": {"teilen"},
             "evaluieren": {"teilen", "trainieren"}}

def fingerabdruck(name, p, vorgaenger):
    """Hash aus Quelltext, eigenen Parametern und Fingerabdrücken der Vorgänger."""
    quelle = inspect.getsource(SCHRITTE[name])
    stoff = json.dumps([quelle, p, vorgaenger], sort_keys=True)
    return hashlib.sha256(stoff.encode()).hexdigest()[:12]

def ausfuehren(params, cache: Path):
    schluessel, ergebnis = {}, {}
    for name in TopologicalSorter(ABHAENGIG).static_order():
        vor = sorted(ABHAENGIG[name])
        p = params.get(name, {})          # nur die Parameter dieses Schritts
        schluessel[name] = fingerabdruck(name, p, [schluessel[d] for d in vor])
        datei = cache / f"{name}-{schluessel[name]}.pkl"
        if datei.exists():
            ergebnis[name] = pickle.loads(datei.read_bytes())
            print(f"  {name:11s} aus Cache  ({schluessel[name]})")
        else:
            ergebnis[name] = SCHRITTE[name](p, *[ergebnis[d] for d in vor])
            datei.write_bytes(pickle.dumps(ergebnis[name]))
            print(f"  {name:11s} berechnet  ({schluessel[name]})")
    return ergebnis["evaluieren"]

with tempfile.TemporaryDirectory() as tmp:
    cache = Path(tmp)
    laeufe = [("Lauf 1", 100), ("Lauf 2 (unverändert)", 100),
              ("Lauf 3 (n_estimators=300)", 300)]
    for titel, n_estimators in laeufe:
        print(titel)
        params = {"trainieren": {"n_estimators": n_estimators}}
        print("  Ergebnis:", ausfuehren(params, cache))

"""Experiment Tracking und Model Registry mit MLflow (lokal, SQLite als Backend).

Ausführen:  uv run --with mlflow --with scikit-learn --with pandas --with numpy python mlflow_tracking.py
Die erste Installation von MLflow ist groß (ca. 90 Pakete) und dauert; danach startet das Skript in Sekunden.
"""
import tempfile
from pathlib import Path

import mlflow
import pandas as pd
from mlflow import MlflowClient
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import train_test_split

from lieferdaten import MERKMALE, lieferdaten, modell_trainieren

ordner = Path(tempfile.mkdtemp())
mlflow.set_tracking_uri(f"sqlite:///{ordner / 'mlflow.db'}")
experiment_id = mlflow.create_experiment("lieferzeit", artifact_location=str(ordner / "artefakte"))
mlflow.set_experiment("lieferzeit")

df = lieferdaten(5000, seed=42)
train, test = train_test_split(df, test_size=0.2, random_state=0)

# 1) Drei Läufe mit verschiedenen Hyperparametern, je Lauf Parameter und Modell.
modell_uris = {}
for n_baeume, tiefe in [(50, 2), (100, 3), (300, 3)]:
    with mlflow.start_run(run_name=f"gbr-{n_baeume}-{tiefe}") as lauf:
        modell = modell_trainieren(train, n_estimators=n_baeume, max_depth=tiefe)
        vorhersage = modell.predict(test[MERKMALE])
        mae = mean_absolute_error(test["lieferzeit_min"], vorhersage)
        mlflow.log_params({"n_estimators": n_baeume, "max_depth": tiefe})
        mlflow.log_metric("mae_test", mae)
        # MLflow 3 speichert mit skops und lehnt unsere eigene Funktion ab.
        # Für das eigene, vertrauenswürdige Modell: cloudpickle.
        info = mlflow.sklearn.log_model(
            modell, name="modell", serialization_format="cloudpickle",
            pip_requirements=["scikit-learn", "pandas"],  # spart die Ermittlung
        )
        modell_uris[lauf.info.run_id] = info.model_uri

# 2) Die Läufe sind abfragbar, nicht nur ansehbar.
laeufe = mlflow.search_runs(experiment_ids=[experiment_id],
                            order_by=["metrics.mae_test ASC"])
spalten = ["tags.mlflow.runName", "params.n_estimators", "params.max_depth",
           "metrics.mae_test"]
print(laeufe[spalten].rename(columns=lambda c: c.split(".", 1)[-1])
      .round(3).to_string(index=False))

# 3) Das beste Modell wird als Version registriert, Alias "champion".
bester = laeufe.iloc[0]
version = mlflow.register_model(modell_uris[bester["run_id"]], "lieferzeit")
client = MlflowClient()
client.set_registered_model_alias("lieferzeit", "champion", version.version)
print(f"\nRegistriert: lieferzeit, Version {version.version}, Alias 'champion'")

# 4) Der Serving-Code kennt nur den Alias, nie die Versionsnummer.
champion = mlflow.sklearn.load_model("models:/lieferzeit@champion")
beispiel = pd.DataFrame({"distanz_km": [3.0], "artikel": [4],
                         "stunde": [19], "regen": [1]})
minuten = champion.predict(beispiel)[0]
print(f"Vorhersage für 3 km, 4 Artikel, 19 Uhr, Regen: {minuten:.1f} min")

"""Pattern 21 Transform: Training-Serving Skew zeigen und mit einer Pipeline beheben."""
import io

import joblib
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.linear_model import Ridge
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

rng = np.random.default_rng(42)
n = 2000
df = pd.DataFrame({
    "distanz_km": rng.gamma(3.0, 4.0, n),
    "stadt": rng.choice(["Wien", "Graz", "Linz"], n, p=[0.5, 0.3, 0.2]),
})
zuschlag = {"Wien": 4.0, "Graz": 1.0, "Linz": 0.0}
df["preis"] = (3.5 + 1.8 * df["distanz_km"] + df["stadt"].map(zuschlag)
               + rng.normal(0, 1.5, n))

# --- Naiv: Aufbereitung im Notebook, Serving-Code separat nachgebaut ---
X_train = pd.get_dummies(df[["distanz_km", "stadt"]], columns=["stadt"],
                         dtype=float)
mu, sigma = X_train["distanz_km"].mean(), X_train["distanz_km"].std()
X_train["distanz_km"] = (X_train["distanz_km"] - mu) / sigma
modell_naiv = Ridge(alpha=1.0).fit(X_train, df["preis"])

def serving_naiv(anfragen: pd.DataFrame) -> np.ndarray:
    X = pd.get_dummies(anfragen, columns=["stadt"], dtype=float)
    X = X.reindex(columns=X_train.columns, fill_value=0.0)
    d = X["distanz_km"]
    # Fehler: Statistik der Anfragen statt der Trainingsdaten
    X["distanz_km"] = (d - d.mean()) / d.std()
    return modell_naiv.predict(X)

anfragen = pd.DataFrame({
    "distanz_km": [2.0, 3.5, 4.0, 5.0, 6.5],
    "stadt": ["Wien", "Graz", "Wien", "Linz", "Wien"],
})
richtig = 3.5 + 1.8 * anfragen["distanz_km"] + anfragen["stadt"].map(zuschlag)
print("erwarteter Preis      :", richtig.round(2).tolist())
print("Serving (naiv)        :", serving_naiv(anfragen).round(2).tolist())

# --- Transform-Pattern: Transformation gehört zum Modell ---
vorverarbeitung = ColumnTransformer([
    ("zahl", StandardScaler(), ["distanz_km"]),
    ("kat", OneHotEncoder(handle_unknown="ignore"), ["stadt"]),
])
pipeline = Pipeline([("vor", vorverarbeitung), ("modell", Ridge(alpha=1.0))])
pipeline.fit(df[["distanz_km", "stadt"]], df["preis"])

puffer = io.BytesIO()
joblib.dump(pipeline, puffer)      # ein Artefakt: Transformation + Modell
puffer.seek(0)
serving_modell = joblib.load(puffer)
print("Serving (Pipeline)    :",
      serving_modell.predict(anfragen).round(2).tolist())
print("Einzelanfrage         :",
      serving_modell.predict(anfragen.iloc[[0]]).round(2).tolist())
mittel = vorverarbeitung.named_transformers_["zahl"].mean_[0]
print("gelernter Mittelwert  :", round(float(mittel), 3))

"""Kap. 4, Vorspann: aus Rohwerten werden Zahlen, mit denen ein Modell rechnen kann."""
import json
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import skew
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import KBinsDiscretizer, MinMaxScaler, OneHotEncoder, StandardScaler

rng = np.random.default_rng(42)
n = 1000
df = pd.DataFrame({
    "flaeche_m2": rng.normal(75, 20, n).clip(25, 200).round(),
    "jahreseinkommen": rng.lognormal(mean=10.6, sigma=0.6, size=n).round(),   # stark rechtsschief
    "stadtteil": rng.choice(["Mitte", "Nord", "Sued", "Ost"], n, p=[0.4, 0.3, 0.2, 0.1]),
})
train, test = train_test_split(df, test_size=0.2, random_state=42)

# 1) Skalierung: Parameter nur aus den Trainingsdaten lernen, dann auf alles anwenden
mm = MinMaxScaler().fit(train[["flaeche_m2"]])
zs = StandardScaler().fit(train[["flaeche_m2"]])
probe = pd.DataFrame({"flaeche_m2": [40.0, 75.0, 120.0]})
print("Fläche roh      :", probe.flaeche_m2.tolist())
print("min-max (0..1)  :", mm.transform(probe).ravel().round(2).tolist())
print("z-score         :", zs.transform(probe).ravel().round(2).tolist())

# 2) Log-Transformation bei schiefen Verteilungen
e = train.jahreseinkommen
print(f"\nEinkommen roh: Mittel {e.mean():,.0f}, Median {e.median():,.0f}, Schiefe {skew(e):.2f}")
le = np.log(e)
print(f"Einkommen log: Mittel {le.mean():.2f}, Median {le.median():.2f}, Schiefe {skew(le):.2f}")

# 3) Bucketizing: Quartile des Trainingsdatensatzes
kb = KBinsDiscretizer(n_bins=4, encode="ordinal", strategy="quantile").fit(train[["jahreseinkommen"]])
print("\nQuartilgrenzen:", kb.bin_edges_[0].round(0).tolist())
print("Bucket für 20.000 / 40.000 / 90.000 / 300.000:",
      kb.transform(pd.DataFrame({"jahreseinkommen": [20000, 40000, 90000, 300000]})).ravel().astype(int).tolist())

# 4) One-Hot für Kategorien
oh = OneHotEncoder(sparse_output=False).fit(train[["stadtteil"]])
print("\nSpalten:", oh.get_feature_names_out().tolist())
print(oh.transform(pd.DataFrame({"stadtteil": ["Nord", "Ost"]})).astype(int))

# Daten für das Histogramm-Diagramm im Handbuch
Path(__file__).with_name("einfache_repraesentationen.json").write_text(json.dumps({
    "roh_hist": np.histogram(e / 1000, bins=np.arange(0, 301, 20))[0].tolist(),
    "log_hist": np.histogram(le, bins=np.arange(8.6, 13.01, 0.4))[0].tolist(),
    "log_bins": np.arange(8.6, 13.01, 0.4).round(1).tolist(),
}))

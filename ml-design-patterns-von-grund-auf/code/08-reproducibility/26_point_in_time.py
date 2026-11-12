"""Pattern 26 Feature Store: Point-in-Time-Korrektheit mit pandas.merge_asof."""
import numpy as np
import pandas as pd
from sklearn.metrics import roc_auc_score

rng = np.random.default_rng(5)
n = 3000
monate = pd.date_range("2025-01-01", periods=12, freq="MS")

# Feature-Tabelle: monatlicher Schnappschuss "Bestellungen der letzten 30 Tage"
kunde = np.arange(n)
abwanderer = rng.random(n) < 0.3
rate = rng.gamma(4.0, 1.0, n) * np.where(abwanderer, 0.8, 1.0)  # vorher schon etwas weniger
zeilen = []
for i, ts in enumerate(monate):
    bestellungen = rng.poisson(rate)
    bestellungen = np.where(abwanderer & (i >= 8), 0, bestellungen)  # ab September nichts mehr
    zeilen.append(pd.DataFrame({"kunde": kunde, "ts": ts,
                                "bestellungen_30d": bestellungen}))
features = pd.concat(zeilen).sort_values("ts").reset_index(drop=True)

# Trainingsbeispiele: Vorhersagezeitpunkt 1. Juli; Label = bis Jahresende gekündigt
beispiele = pd.DataFrame({"kunde": kunde, "ts": pd.Timestamp("2025-07-01"),
                          "gekuendigt": abwanderer.astype(int)})

# a) Naiver Join: "aktueller Stand" der Feature-Tabelle (hier Dezember)
dezember = features[features["ts"] == features["ts"].max()]
naiv = beispiele.merge(dezember[["kunde", "bestellungen_30d"]], on="kunde")

# b) Point-in-Time-Join: letzter Wert, der zum Zeitpunkt des Beispiels galt
pit = pd.merge_asof(beispiele.sort_values("ts"), features,
                    on="ts", by="kunde", direction="backward")

for name, df in [("naiver Join", naiv), ("Point-in-Time-Join", pit)]:
    auc = roc_auc_score(df["gekuendigt"], -df["bestellungen_30d"])
    print(f"{name:20s} AUC allein aus 'bestellungen_30d': {auc:.3f}")

print(pit.head(3).to_string(index=False))

"""Pattern 3 Feature Cross: Pendlerverkehr, eine Wechselwirkung, die ein lineares Modell nicht sieht."""
import json
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.pipeline import make_pipeline
from sklearn.tree import DecisionTreeClassifier
from sklearn.preprocessing import OneHotEncoder

rng = np.random.default_rng(0)
n = 20_000
df = pd.DataFrame({
    "richtung": rng.choice(["stadteinwaerts", "stadtauswaerts"], n),
    "tageszeit": rng.choice(["vormittag", "nachmittag"], n),
})
# Stau, wenn der Verkehr in Hauptrichtung läuft: morgens rein, nachmittags raus (XOR) plus 10 % Rauschen
stau = ((df.richtung == "stadteinwaerts") == (df.tageszeit == "vormittag"))
df["stau"] = np.where(rng.random(n) < 0.10, ~stau, stau).astype(int)

print(df.groupby(["richtung", "tageszeit"]).stau.mean().round(2).unstack())
train, test = train_test_split(df, test_size=0.3, random_state=0)

def lauf(name, spalten, df_tr, df_te):
    enc = ColumnTransformer([("oh", OneHotEncoder(), spalten)])
    m = make_pipeline(enc, LogisticRegression()).fit(df_tr[spalten], df_tr.stau)
    print(f"{name:42s} Genauigkeit {m.score(df_te[spalten], df_te.stau):.3f}")
    return m.score(df_te[spalten], df_te.stau)

a_ohne = lauf("lineares Modell, ohne Cross", ["richtung", "tageszeit"], train, test)

# Feature Cross: ein neues kategoriales Feature aus der Kombination
for d in (train, test):
    d["richtung_x_tageszeit"] = d.richtung + "_x_" + d.tageszeit
mit_cross = ["richtung", "tageszeit", "richtung_x_tageszeit"]
a_cross = lauf("lineares Modell, mit Cross", mit_cross, train, test)

# Zum Vergleich: ein kleines Netz mit versteckter Schicht findet die Wechselwirkung selbst
enc = ColumnTransformer([("oh", OneHotEncoder(), ["richtung", "tageszeit"])])
mlp = make_pipeline(enc, MLPClassifier(hidden_layer_sizes=(8,), max_iter=2000, random_state=0)).fit(
    train[["richtung", "tageszeit"]], train.stau)
a_mlp = mlp.score(test[["richtung", "tageszeit"]], test.stau)
print(f"{'Netz mit versteckter Schicht, ohne Cross':42s} Genauigkeit {a_mlp:.3f}")

# Ein Entscheidungsbaum bildet die Kombination durch seine Verzweigungen ebenfalls selbst
baum = make_pipeline(enc, DecisionTreeClassifier(max_depth=2, random_state=0)).fit(
    train[["richtung", "tageszeit"]], train.stau)
a_baum = baum.score(test[["richtung", "tageszeit"]], test.stau)
print(f"{'Entscheidungsbaum (Tiefe 2), ohne Cross':42s} Genauigkeit {a_baum:.3f}")

# Zellenexplosion: Anzahl der Cross-Zellen
print("\nAnzahl der Cross-Zellen:")
print("  Wochentag x Stunde                  ", 7 * 24)
print("  ... x Stadtteil (40)                ", 7 * 24 * 40)
print("  ... x Stadtteil x Fahrzeugtyp (12)  ", 7 * 24 * 40 * 12)

zellen = df.groupby(["richtung", "tageszeit"]).stau.mean().round(2).reset_index().to_dict("records")
Path(__file__).with_name("feature_cross.json").write_text(json.dumps(
    {"zellen": zellen, "ohne": round(a_ohne, 3), "cross": round(a_cross, 3), "mlp": round(a_mlp, 3), "baum": round(a_baum, 3)}))

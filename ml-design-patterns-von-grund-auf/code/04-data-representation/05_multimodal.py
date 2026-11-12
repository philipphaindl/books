"""Pattern 4 Multimodal Input: Tabelle, Text und Bild in einem Modell (synthetische Schadensmeldungen)."""
import json
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import FunctionTransformer, KBinsDiscretizer, StandardScaler

rng = np.random.default_rng(5)
n = 4000
y = rng.integers(0, 2, n)                              # 1 = Totalschaden

# Tabelle: geschätzte Schadenshöhe (log-normal), bei Totalschaden im Mittel etwas höher
schaden = rng.lognormal(mean=8.0 + 0.8 * y, sigma=1.0)
# Text: kurze Beschreibung, Wörter mit klassenabhängigen Wahrscheinlichkeiten
neutral = ["Auto", "Straße", "Kreuzung", "Fahrer", "Regen", "Zeuge", "Parkplatz", "Ampel"]
schwer = ["Überschlag", "Feuer", "Airbag", "abgeschleppt", "Achsbruch"]
leicht = ["Kratzer", "Delle", "Spiegel", "Stoßstange", "Lack"]
def beschreibung(label):
    woerter = list(rng.choice(neutral, 4))
    woerter += list(rng.choice(schwer if rng.random() < (0.45 if label else 0.10) else leicht, 1))
    return " ".join(rng.permutation(woerter))
text = [beschreibung(l) for l in y]
# Bild: 8x8 Graustufen-Foto, Totalschaden hat ein etwas helleres Zentrum (4x4 Pixel), viel Rauschen
vorlage = np.zeros((8, 8)); vorlage[2:6, 2:6] = 1
bild = (0.19 * y[:, None, None] * vorlage + rng.normal(0, 1.0, (n, 8, 8))).reshape(n, 64)

df = pd.DataFrame(bild, columns=[f"px{i}" for i in range(64)])
df["schaden"] = schaden
df["text"] = text
df["y"] = y
train, test = train_test_split(df, test_size=0.3, random_state=0, stratify=y)

log_zahl = make_pipeline(FunctionTransformer(np.log1p), StandardScaler())
bucket = KBinsDiscretizer(n_bins=8, encode="onehot", strategy="quantile")
px = [f"px{i}" for i in range(64)]

def modell(teile):
    return make_pipeline(ColumnTransformer(teile), LogisticRegression(max_iter=1000))

tab = ("tabelle", log_zahl, ["schaden"])
buck = ("buckets", bucket, ["schaden"])
txt = ("text", TfidfVectorizer(), "text")
bild = ("bild", StandardScaler(), px)
varianten = {
    "nur Tabelle (Schadenshöhe)": [tab],
    "nur Text (Bag of Words)": [txt],
    "nur Bild (64 Pixel)": [bild],
    "Tabelle + Text": [tab, txt],
    "Tabelle + Text + Bild": [tab, txt, bild],
    "dito, Höhe zusätzlich in Buckets": [tab, buck, txt, bild],
}
ergebnis = []
for name, teile in varianten.items():
    m = modell(teile).fit(train, train.y)
    acc = m.score(test, test.y)
    print(f"{name:42s} Genauigkeit {acc:.3f}")
    ergebnis.append({"name": name, "acc": round(float(acc), 3)})
Path(__file__).with_name("multimodal.json").write_text(json.dumps(ergebnis, ensure_ascii=False))

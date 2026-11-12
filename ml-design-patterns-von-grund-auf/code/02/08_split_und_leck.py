"""Train/Validation/Test, Kreuzvalidierung und Datenleck durch zu frühe Feature-Auswahl."""
import numpy as np
from sklearn.feature_selection import SelectKBest, f_classif
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score, train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.tree import DecisionTreeClassifier

from common import maschinen

df = maschinen()
X, y = df[["temperatur_c", "schwingung_mm_s"]], df.ausfall

# 60 / 20 / 20
X_rest, X_test, y_rest, y_test = train_test_split(X, y, test_size=0.2, random_state=0)
X_train, X_val, y_train, y_val = train_test_split(X_rest, y_rest, test_size=0.25, random_state=0)
print("Training/Validierung/Test:", len(X_train), len(X_val), len(X_test))

for tiefe in (1, 2, 3, 5, 10):
    m = DecisionTreeClassifier(max_depth=tiefe, random_state=0).fit(X_train, y_train)
    print(f"max_depth={tiefe:2d}: Validierung {m.score(X_val, y_val):.3f}")

# Kreuzvalidierung: fünf Aufteilungen, fünf Ergebnisse
werte = cross_val_score(DecisionTreeClassifier(max_depth=3, random_state=0), X_rest, y_rest, cv=5)
print("\n5-fache Kreuzvalidierung:", werte.round(3))
print(f"Mittel {werte.mean():.3f}, Streuung {werte.std():.3f}")

# Datenleck: 100 Beispiele, 2000 reine Zufallsfeatures, zufällige Labels.
# Es gibt nichts zu lernen; ehrlich wären rund 50 % Genauigkeit.
# Wir wiederholen das Experiment mit zehn verschiedenen Zufallsdatensätzen.
falsch, richtig = [], []
for seed in range(10):
    rng = np.random.default_rng(seed)
    Xz = rng.normal(size=(100, 2000))
    yz = rng.integers(0, 2, 100)
    # Falsch: die 20 "besten" Features auf ALLEN Daten wählen, danach erst validieren
    Xz_gewaehlt = SelectKBest(f_classif, k=20).fit_transform(Xz, yz)
    falsch.append(cross_val_score(LogisticRegression(), Xz_gewaehlt, yz, cv=5).mean())
    # Richtig: Die Auswahl liegt in der Pipeline und wird pro Fold nur auf den Trainingsdaten gelernt
    pipeline = make_pipeline(SelectKBest(f_classif, k=20), LogisticRegression())
    richtig.append(cross_val_score(pipeline, Xz, yz, cv=5).mean())
print(f"\nZufallsdaten, Auswahl vor dem Split  : {np.mean(falsch):.2f} Genauigkeit im Mittel (Leck)")
print(f"Zufallsdaten, Auswahl in der Pipeline: {np.mean(richtig):.2f} Genauigkeit im Mittel (ehrlich)")

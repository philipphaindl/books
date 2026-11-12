"""Hyperparameter vs. Parameter, Training-Serving Skew und Drift."""
import numpy as np
import pandas as pd
from scipy.stats import ks_2samp
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.tree import DecisionTreeClassifier
from sklearn.linear_model import LogisticRegression

from common import maschinen

df = maschinen()
X, y = df[["temperatur_c", "schwingung_mm_s"]], df.ausfall
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.3, random_state=0)

# Hyperparameter legt der Mensch vorher fest, Parameter findet das Training
baum = DecisionTreeClassifier(max_depth=2, random_state=0).fit(X_tr, y_tr)
print("Hyperparameter (vorher gewählt): max_depth =", baum.max_depth)
print("Parameter (gelernt): Schwellen =", baum.tree_.threshold[baum.tree_.feature >= 0].round(2))

# Training-Serving Skew: Training in Celsius, Serving bekommt Fahrenheit
pipe = make_pipeline(StandardScaler(), LogisticRegression()).fit(X_tr, y_tr)
print(f"\nOffline-Genauigkeit (Celsius)      : {pipe.score(X_te, y_te):.3f}")
X_serving = X_te.copy()
X_serving["temperatur_c"] = X_serving["temperatur_c"] * 9 / 5 + 32  # Fahrenheit, Spaltenname unverändert
print(f"Serving mit Fahrenheit-Werten      : {pipe.score(X_serving, y_te):.3f}")
print(f"Anteil echter Ausfälle im Test     : {y_te.mean():.3f}")

# Data Drift: Eingabeverteilung verschiebt sich (Sommer), Regel bleibt
rng = np.random.default_rng(11)
n = 1000
temp = rng.normal(82, 10, n)
schw = rng.normal(4, 1.5, n)
ausfall_alt = ((temp > 80) | (schw > 6)).astype(int)
ausfall_alt = np.where(rng.random(n) < 0.05, 1 - ausfall_alt, ausfall_alt)  # wie im Training: 5 % Etikettenrauschen
sommer = pd.DataFrame({"temperatur_c": temp, "schwingung_mm_s": schw})
stat = ks_2samp(X_tr["temperatur_c"], sommer["temperatur_c"])
print(f"\nData Drift: Temperatur Training Mittel {X_tr.temperatur_c.mean():.1f}, Sommer {temp.mean():.1f}, "
      f"KS-Statistik {stat.statistic:.2f}, p = {stat.pvalue:.1e}")
baum_voll = DecisionTreeClassifier(max_depth=3, random_state=0).fit(X_tr, y_tr)
print(f"Genauigkeit im Sommer, Regel unverändert: {baum_voll.score(sommer, ausfall_alt):.3f}")

# Concept Drift: neue Wartung, Ausfälle treten schon ab 75 °C auf (gleiche Eingaben, andere Wahrheit)
ausfall_neu = ((X_te["temperatur_c"] > 75) | (X_te["schwingung_mm_s"] > 6)).astype(int).to_numpy()
ausfall_neu = np.where(rng.random(len(ausfall_neu)) < 0.05, 1 - ausfall_neu, ausfall_neu)
print(f"\nConcept Drift (Schwelle jetzt 75 °C): Genauigkeit {baum_voll.score(X_te, ausfall_neu):.3f} "
      f"statt {baum_voll.score(X_te, y_te):.3f}")

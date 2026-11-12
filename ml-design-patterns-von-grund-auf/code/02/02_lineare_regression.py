"""Lineare Regression: ein Modell ist eine Funktion mit gelernten Parametern."""
import pandas as pd
from sklearn.linear_model import LinearRegression

from common import speichere, wohnungen

df = wohnungen()
X, y = df[["flaeche_m2"]], df["miete_eur"]

modell = LinearRegression().fit(X, y)
print(f"Steigung w = {modell.coef_[0]:.2f} Euro pro m²")
print(f"Achsenabschnitt b = {modell.intercept_:.2f} Euro")
neu = pd.DataFrame({"flaeche_m2": [75.0]})
print(f"Vorhersage für 75 m²: {modell.predict(neu)[0]:.0f} Euro")

# Mit allen drei Features
X3 = df[["flaeche_m2", "zimmer", "baujahr"]]
m3 = LinearRegression().fit(X3, y)
print()
print("Drei Features:", {name: round(float(g), 2) for name, g in zip(X3.columns, m3.coef_)}, "b =", round(m3.intercept_, 1))

speichere("wohnungen", {
    "punkte": [[a, b] for a, b in zip(df.flaeche_m2.tolist(), df.miete_eur.tolist())],
    "w": modell.coef_[0], "b": modell.intercept_,
})

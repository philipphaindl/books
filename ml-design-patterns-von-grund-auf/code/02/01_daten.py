"""Beispiele, Features und Label: Aufbau eines Trainingsdatensatzes."""
from common import wohnungen

df = wohnungen()
print(df.head())
print()
print("Form:", df.shape, "(Zeilen = Beispiele, Spalten = Merkmale + Label)")

X = df[["flaeche_m2", "zimmer", "baujahr"]]  # Features
y = df["miete_eur"]  # Label
print("Features X:", list(X.columns), X.shape)
print("Label y:", y.name, y.shape)
print()
print(df.describe().loc[["mean", "min", "max"]].round(1))

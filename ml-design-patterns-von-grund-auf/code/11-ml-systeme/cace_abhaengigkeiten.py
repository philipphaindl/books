"""Hidden Technical Debt im Kleinen: Entanglement (CACE) und eine instabile Datenabhängigkeit.

Ausführen:  uv run --with scikit-learn --with pandas --with numpy python cace_abhaengigkeiten.py
"""
import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error

from lieferdaten import lieferdaten

BASIS = ["distanz_km", "artikel", "regen"]


def daten(n, seed, routing_faktor=1.0):
    """Lieferdaten plus ein Zusatzmerkmal `routing_min`: die Fahrzeitschätzung eines externen
    Routing-Dienstes. Die echte Strecke ist je nach Umweg 0 bis 60 % länger als die Luftlinie;
    der Dienst kennt den Umweg, `distanz_km` (Luftlinie) nicht."""
    rng = np.random.default_rng(seed + 1000)  # anderer Strom als in lieferdaten()
    df = lieferdaten(n, seed)
    umweg = rng.uniform(1.0, 1.6, n)
    df["lieferzeit_min"] += 2.2 * df["distanz_km"] * (umweg - 1)
    fahrzeit = 2.2 * df["distanz_km"] * umweg + rng.normal(0, 1, n)
    df["routing_min"] = routing_faktor * fahrzeit
    return df


train, test = daten(5000, seed=1), daten(2000, seed=2)
ohne = LinearRegression().fit(train[BASIS], train["lieferzeit_min"])
mit_cols = BASIS + ["routing_min"]
mit = LinearRegression().fit(train[mit_cols], train["lieferzeit_min"])

print("Gewichte (Minuten pro km bzw. pro Routing-Minute)")
print(f"  ohne routing_min: distanz_km = {ohne.coef_[0]:.2f}")
print(f"  mit  routing_min: distanz_km = {mit.coef_[0]:.2f}, "
      f"routing_min = {mit.coef_[3]:.2f}")

# Derselbe Dienst nach einem Update: Das neue Verkehrsmodell schätzt 25 % mehr.
test_update = daten(2000, seed=2, routing_faktor=1.25)


def mae(modell, merkmale, df):
    return mean_absolute_error(df["lieferzeit_min"], modell.predict(df[merkmale]))


print("\nMAE auf Testdaten (Minuten)")
varianten = [("ohne routing_min", ohne, BASIS),
             ("mit  routing_min", mit, mit_cols)]
for name, modell, cols in varianten:
    print(f"  {name}: vor dem Update {mae(modell, cols, test):.2f}, "
          f"nach dem Update {mae(modell, cols, test_update):.2f}")

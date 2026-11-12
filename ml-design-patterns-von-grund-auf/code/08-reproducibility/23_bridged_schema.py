"""Pattern 23 Bridged Schema: altes Schema (cash/card), neues (cash/gift/debit/credit)."""
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error

KATEGORIEN = ["cash", "gift_card", "debit_card", "credit_card"]
KARTEN = KATEGORIEN[1:]
TRINKGELD = {"cash": 8.0, "gift_card": 2.0, "debit_card": 11.0, "credit_card": 17.0}
P = [0.40, 0.10, 0.30, 0.20]
MERKMALE = [f"m{i}" for i in range(1, 7)]         # sechs weitere Fahrtmerkmale
GEWICHTE = np.array([1.5, -1.0, 0.8, 0.6, -0.5, 0.4])

def erzeuge(rng, n: int) -> pd.DataFrame:
    zahlart = rng.choice(KATEGORIEN, n, p=P)
    m = rng.normal(size=(n, len(MERKMALE)))
    prozent = (np.array([TRINKGELD[z] for z in zahlart]) + m @ GEWICHTE
               + rng.normal(0, 3.0, n))
    return pd.DataFrame({"zahlart": zahlart, **dict(zip(MERKMALE, m.T)),
                         "trinkgeld_pct": prozent})

def onehot(zahlart) -> pd.DataFrame:
    return pd.DataFrame({k: (np.asarray(zahlart) == k).astype(float)
                         for k in KATEGORIEN})

def design(df: pd.DataFrame, oh: pd.DataFrame) -> pd.DataFrame:
    return pd.concat([oh.reset_index(drop=True),
                      df[MERKMALE].reset_index(drop=True)], axis=1)

def design_rollup(df: pd.DataFrame) -> pd.DataFrame:
    r = df["zahlart"].where(df["zahlart"] == "cash", "card")
    return pd.DataFrame({"cash": (r == "cash").astype(float).values,
                         "card": (r == "card").astype(float).values,
                         **{k: df[k].values for k in MERKMALE}})

# --- Die beiden Brücken: alte "card"-Zeilen ins neue Schema übersetzen ---
def bruecke_statisch(alt: pd.DataFrame, anteile: pd.Series) -> pd.DataFrame:
    """Vektor mit den Häufigkeiten der neuen Daten statt 0/1."""
    oh = onehot(alt["zahlart"])
    karte = (alt["zahlart"] == "card").to_numpy()
    for k in KARTEN:
        oh.loc[karte, k] = anteile[k]
    return oh

def bruecke_probabilistisch(alt: pd.DataFrame, anteile: pd.Series, rng):
    """Pro Zeile eine Kartenart ziehen, Wahrscheinlichkeit = Häufigkeit."""
    zahlart = alt["zahlart"].to_numpy().astype(object)
    karte = zahlart == "card"
    zahlart[karte] = rng.choice(KARTEN, karte.sum(), p=anteile[KARTEN].values)
    return onehot(zahlart)

def einmal(seed: int) -> dict:
    rng = np.random.default_rng(seed)
    alt_detail = erzeuge(rng, 3000)    # Kartendetail in Wirklichkeit verloren
    neu = erzeuge(rng, 60)             # neues Schema, aber wenig Daten
    test = erzeuge(rng, 2000)          # Inferenz erfolgt im neuen Schema
    alt = alt_detail.assign(zahlart=alt_detail["zahlart"]
                            .where(alt_detail["zahlart"] == "cash", "card"))
    y = pd.concat([alt["trinkgeld_pct"], neu["trinkgeld_pct"]])
    X_test = design(test, onehot(test["zahlart"]))
    X_neu = design(neu, onehot(neu["zahlart"]))

    def bewerte(X, y_train, X_eval=X_test) -> float:
        modell = LinearRegression(fit_intercept=False).fit(X, y_train)
        return mean_absolute_error(test["trinkgeld_pct"], modell.predict(X_eval))

    karten = neu[neu["zahlart"] != "cash"]["zahlart"]
    anteile = karten.value_counts(normalize=True).reindex(KARTEN).fillna(0.0)
    X_ref = pd.concat([design(alt_detail, onehot(alt_detail["zahlart"])), X_neu])
    return {
        "nur neue Daten": bewerte(X_neu, neu["trinkgeld_pct"]),
        "Roll-up auf cash/card": bewerte(
            pd.concat([design_rollup(alt), design_rollup(neu)]), y,
            design_rollup(test)),
        "Bridged, statisch": bewerte(
            pd.concat([design(alt, bruecke_statisch(alt, anteile)), X_neu]), y),
        "Bridged, probabilistisch": bewerte(
            pd.concat([design(alt, bruecke_probabilistisch(alt, anteile, rng)),
                       X_neu]), y),
        "Referenz (Detail nie verloren)": bewerte(X_ref, y),
    }

laeufe = pd.DataFrame([einmal(s) for s in range(30)])
print("MAE (Prozentpunkte Trinkgeld), Test im neuen Schema, 30 Wiederholungen")
print(pd.DataFrame({"Mittel": laeufe.mean(), "Std": laeufe.std()}).round(2).to_string())

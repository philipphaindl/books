"""Pattern 24 Windowed Inference: dieselbe Fensterlogik im Training und im Stream."""
from collections import deque

import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error

FENSTER = 5

def fenster_merkmal(werte: np.ndarray) -> float:
    """Die EINE Stelle, an der das Merkmal definiert ist."""
    return float(np.mean(werte))

rng = np.random.default_rng(11)
t = np.arange(1500)
temp = (60 + 5 * np.sin(t / 60) + np.cumsum(rng.normal(0, 0.4, t.size)) * 0.2
        + rng.normal(0, 1.0, t.size))
serie = pd.Series(temp, name="temperatur")

# --- Batch (Training): Fenster = die fünf Messwerte VOR dem Zeitpunkt ---
batch = serie.shift(1).rolling(FENSTER).apply(fenster_merkmal, raw=True)

# --- Stream (Serving): Zustand = Ringpuffer der letzten fünf Werte ---
class FensterZustand:
    def __init__(self, groesse: int = FENSTER) -> None:
        self.puffer: deque[float] = deque(maxlen=groesse)

    def merkmal(self) -> float | None:
        """Merkmal für den NÄCHSTEN Wert, sobald das Fenster voll ist."""
        if len(self.puffer) < self.puffer.maxlen:
            return None
        return fenster_merkmal(np.array(self.puffer))

    def aufnehmen(self, wert: float) -> None:
        self.puffer.append(wert)

zustand = FensterZustand()
stream = []
for wert in serie:
    stream.append(zustand.merkmal())   # erst Merkmal ziehen, dann Wert aufnehmen
    zustand.aufnehmen(wert)
stream = pd.Series(stream, dtype=float)
gleich = np.allclose(batch.dropna(), stream.dropna())
print("Batch und Stream identisch:", bool(gleich),
      "| gültige Werte:", int(batch.notna().sum()))

# --- Skew durch falsches Fenster: rolling() ohne shift() enthält den Wert selbst ---
leck = serie.rolling(FENSTER).apply(fenster_merkmal, raw=True)
daten = pd.DataFrame({"y": serie, "richtig": batch, "leck": leck,
                      "stream": stream}).dropna()
train, test = daten.iloc[:1000], daten.iloc[1000:]

for name in ("richtig", "leck"):
    m = LinearRegression().fit(train[[name]], train["y"])
    offline = mean_absolute_error(test["y"], m.predict(test[[name]]))
    im_stream = test[["stream"]].rename(columns={"stream": name})
    online = mean_absolute_error(test["y"], m.predict(im_stream))
    print(f"Fenster '{name}':".ljust(18),
          f"MAE offline {offline:.3f} | MAE im Stream {online:.3f}")

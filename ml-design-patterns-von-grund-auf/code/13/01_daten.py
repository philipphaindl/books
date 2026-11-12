"""Pattern-unabhaengig: erzeugt die Daten, beschreibt sie und exportiert eine Pumpe fuer das Diagramm."""
import numpy as np
from pumpen import *

df = erzeuge_daten()
print(f"Zeilen: {len(df):,}  Pumpen: {df.pumpe.nunique()}  Tage: {TAGE}".replace(",", "."))
zyk = df.groupby(["pumpe", "zyklus"]).agg(laenge=("minute", "size"), ausfall=("rul_min", lambda s: s.notna().any()))
print(f"Betriebszyklen: {len(zyk)}, davon mit Ausfall: {int(zyk.ausfall.sum())}")
print(f"mittlere Laufzeit bis Ausfall: {zyk[zyk.ausfall].laenge.mean() / MIN_TAG:.1f} Tage")
print(f"Anteil Minuten mit Label 'Ausfall in 24 h': {(df.fail24 == 1).mean():.3%}")
print(df[SENSOREN].describe().loc[["mean", "std", "min", "max"]].round(2).to_string())

tab = merkmals_tabelle(df)
n_tab = f"{len(tab):,}".replace(",", ".")
print(f"Merkmalszeilen (alle {SCHRITT} min, Fenster {FENSTER // 60} h): {n_tab}, davon Positive: {(tab.fail24 == 1).mean():.1%}")

# Eine Pumpe, ein Zyklus mit Ausfall: stuendliche Mittelwerte der letzten 6 Tage vor dem Ausfall
g = df[(df.pumpe == "P03") & df.rul_min.notna()]
z = g[g.zyklus == g.zyklus.iloc[0]]
z = z[z.minute >= z.minute.max() - 6 * MIN_TAG].copy()
z["h_vor_ausfall"] = -(z.rul_min / 60)
h = z.groupby((z.h_vor_ausfall // 1).astype(int))[SENSOREN].mean().reset_index()
h.round(3).to_csv("out/pumpe_verlauf.csv", index=False)
print(f"Verlauf P03 exportiert: {len(h)} Stundenwerte")

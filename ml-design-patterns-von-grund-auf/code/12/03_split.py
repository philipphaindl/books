"""Schritt 3, Pattern 22 Repeatable Splitting: Split nach Kunden-ID statt nach Zeilen."""
import subprocess
import sys

import pandas as pd
from sklearn.model_selection import train_test_split

from daten import ZIEL, lade_daten, mit_bucket
from modell import ALLE0, ENTWICKLUNG_BIS, ID_ARTIG, kennzahlen, modell_gross, modell_hgb, speichere

df = lade_daten()
dev = mit_bucket(df[df.monat <= ENTWICKLUNG_BIS])
X = pd.get_dummies(dev[ALLE0]).astype(float)
y = dev[ZIEL]


def bewerte(modell, tr_idx, te_idx, spalten=None):
    spalten = list(X.columns) if spalten is None else spalten
    m = modell.fit(X.loc[tr_idx, spalten], y.loc[tr_idx])
    return kennzahlen(y.loc[te_idx], m.predict_proba(X.loc[te_idx, spalten])[:, 1], 0.5)


# a) Zufällig nach Zeilen (wie im naiven Notebook): 80 / 20
tr_z, te_z = train_test_split(dev.index, test_size=0.2, random_state=42)
ueberlapp = len(set(dev.loc[tr_z, "kunden_id"]) & set(dev.loc[te_z, "kunden_id"]))
anteil = dev.loc[te_z, "kunden_id"].isin(set(dev.loc[tr_z, "kunden_id"])).mean()

# b) Nach Kunden-ID gehasht: Buckets 0-5 Training, 6-7 Validierung, 8-9 Test
tr_k, va_k, te_k = (dev.index[dev.bucket < 6], dev.index[dev.bucket.isin([6, 7])], dev.index[dev.bucket >= 8])

ergebnis = {}
for name, fabrik in (("gross", modell_gross), ("klein", modell_hgb)):
    ergebnis[name] = {"zeilen": bewerte(fabrik(), tr_z, te_z), "kunden": bewerte(fabrik(), tr_k, te_k),
                      "validierung": bewerte(fabrik(), tr_k, va_k)}

print(f"Zeilen-Split: {ueberlapp:,} Kunden in Training UND Test; bei {anteil:.1%} der")
print("              Testzeilen liegen Zeilen desselben Kunden im Training")
print(f"Kunden-Split: {len(set(dev.loc[tr_k, 'kunden_id']) & set(dev.loc[te_k, 'kunden_id']))} Kunden in beiden Teilen\n")
print(f"{'PR-AUC (Test)':<18}{'Zeilen-Split':>14}{'Kunden-Split':>14}")
for name, text in (("gross", "großes Modell"), ("klein", "kleines Modell")):
    print(f"{text:<18}{ergebnis[name]['zeilen']['ap']:>14.3f}{ergebnis[name]['kunden']['ap']:>14.3f}")
ohne = [c for c in X.columns if c not in ID_ARTIG]
ohne_fp = bewerte(modell_gross(), tr_z, te_z, ohne)
ergebnis["gross"]["zeilen_ohne_fingerabdruck"] = ohne_fp
print(f"Großes Modell, Zeilen-Split, ohne {' und '.join(ID_ARTIG)}: {ohne_fp['ap']:.3f}")
print(f"Validierungskunden: großes Modell {ergebnis['gross']['validierung']['ap']:.3f}, "
      f"kleines Modell {ergebnis['klein']['validierung']['ap']:.3f}")

# Wiederholbarkeit: Ein neuer Monat kommt hinzu. Wer bleibt, wo er war?
alle = mit_bucket(df)
gleich = (alle.set_index(["kunden_id", "monat"]).loc[dev.set_index(["kunden_id", "monat"]).index, "bucket"].to_numpy()
          == dev["bucket"].to_numpy()).mean()
tr_neu, te_neu = train_test_split(df.index, test_size=0.2, random_state=42)       # Zeilen-Split auf der größeren Tabelle
alt = pd.Series("train", index=dev.index); alt.loc[te_z] = "test"
neu = pd.Series("train", index=df.index); neu.loc[te_neu] = "test"
kennung = lambda d: d["kunden_id"] + "/" + d["monat"].astype(str)
vergleich = pd.DataFrame({"alt": alt.values}, index=kennung(dev)).join(pd.DataFrame({"neu": neu.values}, index=kennung(df)))
wechsel_zeile = float((vergleich.alt != vergleich.neu).mean())
print(f"\nTabelle wächst auf {len(df):,} Zeilen. Alte Zeilen, die die Seite wechseln:")
print(f"  Zeilen-Split: {wechsel_zeile:.1%}")
print(f"  Hash-Split  : {(1 - gleich):.1%}")

# Falle: Pythons eingebautes hash() ist pro Prozess gesalzen
code = "print(hash('K000001') % 10)"
print("hash('K000001') % 10, drei Prozesse:", [subprocess.run([sys.executable, '-c', code], capture_output=True, text=True).stdout.strip() for _ in range(3)])
print("bucket('K000001')     , drei Prozesse:", [subprocess.run([sys.executable, '-c', 'from daten import bucket; print(bucket("K000001"))'], capture_output=True, text=True).stdout.strip() for _ in range(3)])

# Für die Abbildung: die ersten acht Kunden mit mindestens 10 Zeilen und ihre Zuordnung unter beiden Verfahren
anzahl = dev.groupby("kunden_id").size()
ids = list(anzahl[anzahl >= 10].index[:8])
raster = []
for kid in ids:
    z = dev[dev.kunden_id == kid]
    seite = dict(zip(z.monat, alt.loc[z.index]))
    ziel = dict(zip(z.monat, z[ZIEL]))
    raster.append({"id": kid, "bucket": int(z.bucket.iloc[0]),
                   "zeile": [seite.get(m) for m in range(ENTWICKLUNG_BIS + 1)],
                   "ziel": [int(ziel[m]) if m in ziel else None for m in range(ENTWICKLUNG_BIS + 1)]})
speichere("03_split", {"ergebnis": ergebnis, "ueberlapp": ueberlapp, "geschwister_anteil": float(anteil),
                       "wechsel_zeile": wechsel_zeile, "wechsel_hash": float(1 - gleich), "raster": raster})

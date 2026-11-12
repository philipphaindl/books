"""Pattern 24: Windowed Inference - derselbe Fensterschnitt im Training und im Stream."""
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import average_precision_score, precision_recall_curve

from pumpen import *

df = erzeuge_daten()
nachher = merkmals_tabelle(df, versatz=0)       # Fenster endet im Vorhersagezeitpunkt
zentriert = merkmals_tabelle(df, versatz=719)   # Fenster ragt 12 h in die Zukunft

# 1) Aequivalenz: eine Pumpe, ein Zyklus, Minute fuer Minute durch den Stream
zyklus = df[(df.pumpe == "P05") & (df.zyklus == 0)]
strom, ergebnis = PumpenStrom(), {}
for minute, werte in zip(zyklus.minute, zyklus[SENSOREN].to_numpy(np.float64)):
    f = strom.neue_messung(minute, werte)
    if f is not None:
        ergebnis[minute] = f
batch = nachher[(nachher.pumpe == "P05") & (nachher.zyklus == 0)].set_index("minute")
zent = zentriert[(zentriert.pumpe == "P05") & (zentriert.zyklus == 0)].set_index("minute")
gemeinsam = batch.index.intersection(list(ergebnis)).intersection(zent.index)
s = np.array([ergebnis[m] for m in gemeinsam])
print(f"Vorhersagezeitpunkte verglichen: {len(gemeinsam)}")
print(f"max. Abweichung Stream vs. Batch (Fenster endet bei t): {np.abs(s - batch.loc[gemeinsam, NAMEN].to_numpy()).max():.2e}")
print(f"max. Abweichung Stream vs. Batch (Fenster zentriert):   {np.abs(s - zent.loc[gemeinsam, NAMEN].to_numpy()).max():.2f}")


# Kontrolle: der Versatz entspricht pandas' rolling(center=True)
roh = zyklus.set_index("minute").vib.astype(np.float64)
pandas_mittel = roh.rolling(FENSTER, center=True).mean()
print(f"max. Abweichung vib_mittel zentriert vs. pandas rolling(center=True): {np.abs(pandas_mittel.loc[gemeinsam].to_numpy() - zent.loc[gemeinsam, 'vib_mittel'].to_numpy())[~np.isnan(pandas_mittel.loc[gemeinsam].to_numpy())].max():.1e}")


# 2) Folgen: Modell auf zentrierten Fenstern gegen Modell auf nachlaufenden Fenstern
def schwelle_fuer_praezision(y, p, ziel=0.8):
    pr, rc, th = precision_recall_curve(y, p)
    return th[np.argmax(pr[:-1] >= ziel)]


def kennzahlen(y, p, schwelle):
    alarm = p >= schwelle
    return (y[alarm].mean() if alarm.any() else 0.0), alarm[y == 1].mean()


def modell(tab):
    tr, va, te = zeit_split(tab)
    m = HistGradientBoostingClassifier(random_state=0).fit(tr[NAMEN], tr.fail24)
    return m, va, te


print(f"\n{'Modell / Auswertung':<44}{'PR-AUC':>8}{'Precision':>11}{'Recall':>8}")
mz, vaz, tez = modell(zentriert)
m0, va0, te0 = modell(nachher)
th_z = schwelle_fuer_praezision(vaz.fail24, mz.predict_proba(vaz[NAMEN])[:, 1])
th_0 = schwelle_fuer_praezision(va0.fail24, m0.predict_proba(va0[NAMEN])[:, 1])
zeilen = [
    ("zentriert trainiert, offline (Notebook)", mz, tez, th_z),
    ("zentriert trainiert, im Stream", mz, te0, th_z),
    ("nachlaufend trainiert, offline = Stream", m0, te0, th_0),
]
for name, m, te, th in zeilen:
    p = m.predict_proba(te[NAMEN])[:, 1]
    pr, rc = kennzahlen(te.fail24.to_numpy(), p, th)
    print(f"{name:<44}{average_precision_score(te.fail24, p):>8.3f}{pr:>11.2f}{rc:>8.2f}")
print("(Schwelle: Precision >= 0,80 auf den Validierungsdaten)")
print(f"Testzeilen: zentriert {len(tez)}, nachlaufend {len(te0)}")

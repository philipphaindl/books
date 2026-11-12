"""Pattern 5: Reframing - Restlebensdauer (Regression) gegen 'Ausfall in 24 h' (Klassifikation)."""
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier, HistGradientBoostingRegressor
from sklearn.metrics import average_precision_score

from auswertung import *
from pumpen import *

t = tabelle()
t = t[t.rul_h.notna()]                 # nur Zyklen mit bekanntem Ausfall (ohne zensiertes Ende)
tr, va, te = zeit_split(t)
print(f"Zeilen Training/Validierung/Test: {len(tr)}/{len(va)}/{len(te)}; Ausfaelle im Test: {te.groupby(['pumpe', 'zyklus']).ngroups}")

modelle = {}
reg = HistGradientBoostingRegressor(random_state=0).fit(tr[NAMEN], tr.rul_h)
modelle["Regression, Ziel = RUL in h"] = (reg, lambda X: -reg.predict(X))
gek = HistGradientBoostingRegressor(random_state=0).fit(tr[NAMEN], tr.rul_h.clip(upper=72))
modelle["Regression, Ziel auf 72 h gekappt"] = (gek, lambda X: -gek.predict(X))
clf = HistGradientBoostingClassifier(random_state=0).fit(tr[NAMEN], tr.fail24)
modelle["Klassifikation, Ziel = Ausfall in 24 h"] = (clf, lambda X: clf.predict_proba(X)[:, 1])

# Fehler der Regression, nach Entfernung vom Ausfall getrennt
pred = reg.predict(te[NAMEN])
for lo, hi in [(0, 24), (24, 72), (72, 1e9)]:
    m = (te.rul_h > lo) & (te.rul_h <= hi)
    print(f"MAE (RUL roh) bei wahrer RUL {lo:>3} bis {min(hi, 999):>3} h: {np.abs(pred[m] - te.rul_h[m]).mean():6.1f} h  ({m.sum()} Zeilen)")

print(f"\n{'Ansatz':<40}{'PR-AUC':>8}{'erkannt':>9}{'Fehlalarme':>12}{'Kosten/Test':>13}")
for name, (m, score) in modelle.items():
    s_va, s_te = score(va[NAMEN]), score(te[NAMEN])
    schwellen = np.quantile(s_va, np.linspace(0.70, 0.995, 60))
    th, _ = beste_schwelle(va, s_va, schwellen)
    e, n, f = ereignis_bilanz(te, s_te >= th)
    k = f"{kosten(e, n, f):,}".replace(",", ".")
    print(f"{name:<40}{average_precision_score(te.fail24, s_te):>8.3f}{f'{e}/{n}':>9}{f:>12}{k:>13}")
print(f"ohne Ueberwachung (alle Ausfaelle ungeplant): {te.groupby(['pumpe', 'zyklus']).ngroups * KOSTEN_AUSFALL:,}".replace(",", "."))

# Verlauf eines Testzyklus fuer das Diagramm (letzte 120 h vor dem Ausfall, stuendliche Werte)
z = te[(te.rul_h <= 120) & (te.minute % 60 == 0)]
z = z[(z.pumpe == z.pumpe.iloc[0]) & (z.zyklus == z.zyklus.iloc[0])]
pd.DataFrame({
    "h": -z.rul_h.round(2), "rul_roh": reg.predict(z[NAMEN]).round(2),
    "rul_gekappt": gek.predict(z[NAMEN]).round(2), "wahrsch": clf.predict_proba(z[NAMEN])[:, 1].round(4),
}).to_csv("out/reframing_verlauf.csv", index=False)
print(f"\nVerlauf exportiert: {z.pumpe.iloc[0]}, Zyklus {z.zyklus.iloc[0]}, {len(z)} Stundenwerte")

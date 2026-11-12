"""Pattern 9 Neutral Class: Uneinigkeit der Labeler als eigene Klasse (synthetische Stimmungsdaten)."""
import json
from pathlib import Path

import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.model_selection import train_test_split

rng = np.random.default_rng(2)
n = 30_000
s = rng.normal(0, 1, n)                                    # wahre, unbeobachtete Stimmung
X = np.column_stack([s + rng.normal(0, 0.25, n), rng.normal(size=(n, 5))])   # 1 Signal + 5 Rauschspalten
# drei Labeler, jeder sagt "positiv" mit Wahrscheinlichkeit sigmoid(5 s): nahe 0 fast ein Münzwurf
stimmen = rng.random((n, 3)) < 1 / (1 + np.exp(-5 * s[:, None]))
summe = stimmen.sum(1)
mehrheit = (summe >= 2).astype(int)          # binäres Label per Mehrheit
einig = (summe == 0) | (summe == 3)          # alle drei gleicher Meinung
# dreiwertiges Label: 0 negativ, 1 neutral (uneinig), 2 positiv
drei = np.where(einig, np.where(summe == 3, 2, 0), 1)
print(f"Labeler einstimmig: {einig.mean():.1%}, Uneinigkeit (2:1): {(~einig).mean():.1%}")

Xtr, Xte, mtr, mte, dtr, dte, etr, ete, str_, ste = train_test_split(
    X, mehrheit, drei, einig, s, test_size=0.3, random_state=0)

zwei = HistGradientBoostingClassifier(max_iter=200, random_state=0).fit(Xtr, mtr)
dreik = HistGradientBoostingClassifier(max_iter=200, random_state=0).fit(Xtr, dtr)

p = zwei.predict_proba(Xte)[:, 1]
pred2 = (p >= 0.5).astype(int)
pred3 = dreik.predict(Xte)
print(f"\nTest: {len(mte):,} Beispiele, davon strittig {np.mean(~ete):.1%}")

# Binär: jede Vorhersage wird automatisch ausgespielt
print("\nBinäres Modell")
print(f"  Fehlerrate bei einstimmigen Fällen: {np.mean(pred2[ete] != mte[ete]):.1%}")
print(f"  Fehlerrate bei strittigen Fällen  : {np.mean(pred2[~ete] != mte[~ete]):.1%}   (Mehrheitslabel als Referenz)")
print(f"  Gesamtfehler gegen Mehrheitslabel  : {np.mean(pred2 != mte):.1%}")
print(f"  mittlere Sicherheit max(p,1-p) bei strittigen Fällen: {np.mean(np.maximum(p, 1 - p)[~ete]):.2f}")

# Drei Klassen: neutral = nicht automatisch entscheiden
auto = pred3 != 1
print("\nModell mit Neutral-Klasse")
print(f"  als neutral erkannt: {np.mean(pred3[~ete] == 1):.1%} der strittigen, {np.mean(pred3[ete] == 1):.1%} der einstimmigen Fälle")
print(f"  automatisch entschieden: {auto.mean():.1%} aller Fälle")
print(f"  Fehlerrate unter den automatisch entschiedenen (Mehrheitslabel): {np.mean((pred3[auto] == 2).astype(int) != mte[auto]):.1%}")
print(f"  Fehlerrate bei einstimmigen Fällen: {np.mean((pred3[ete] == 2).astype(int) != mte[ete]):.1%} "
      f"(neutral-Vorhersagen mitgezählt: {np.mean(pred3[ete] != dte[ete]):.1%})")

# Fairer Vergleich: binäres Modell mit Sicherheitsschwelle, die denselben Anteil automatisch entscheidet
sicher = np.maximum(p, 1 - p)
t = np.quantile(sicher, 1 - auto.mean())
a2 = sicher >= t
print("\nBinäres Modell mit Konfidenzschwelle (gleicher Automatisierungsanteil)")
print(f"  automatisch entschieden: {a2.mean():.1%}, Fehlerrate darunter: {np.mean(pred2[a2] != mte[a2]):.1%}")
# Verlauf über der (im Betrieb unbekannten) wahren Stimmung s, für das Diagramm im Handbuch
kurve = []
for lo in np.arange(-2.0, 2.0, 0.25):
    m = (ste >= lo) & (ste < lo + 0.25)
    kurve.append({"s": round(float(lo + 0.125), 3), "einig": round(float(ete[m].mean()), 3),
                  "neg": round(float(np.mean(pred3[m] == 0)), 3), "neu": round(float(np.mean(pred3[m] == 1)), 3),
                  "pos": round(float(np.mean(pred3[m] == 2)), 3), "binpos": round(float(np.mean(pred2[m] == 1)), 3)})
Path(__file__).with_name("neutral_class.json").write_text(json.dumps({"kurve": kurve,
    "einig": round(float(einig.mean()), 3),
    "err2_einig": round(float(np.mean(pred2[ete] != mte[ete])), 3),
    "err2_strittig": round(float(np.mean(pred2[~ete] != mte[~ete])), 3),
    "err3_auto": round(float(np.mean((pred3[auto] == 2).astype(int) != mte[auto])), 3),
    "auto": round(float(auto.mean()), 3),
    "err2_konf": round(float(np.mean(pred2[a2] != mte[a2])), 3)}))

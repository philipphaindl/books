"""Pattern 20: Keyed Predictions - parallel bewertete Pakete kommen
in anderer Reihenfolge zurueck."""
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import average_precision_score

from pumpen import *

t = tabelle()
t = t[t.rul_h.notna()]
tr, va, te = zeit_split(t)
modell = HistGradientBoostingClassifier(random_state=0).fit(tr[NAMEN], tr.fail24)
te = te.reset_index(drop=True)

N_PAKETE = 12
pakete = np.array_split(np.arange(len(te)), N_PAKETE)
rng = np.random.default_rng(1)
dauer = rng.permutation(N_PAKETE) * 0.1    # Pakete brauchen verschieden lang


def bewerte(i):
    """Der Worker kennt nur sein Paket. Rueckgabe: ohne und mit Schluessel."""
    time.sleep(dauer[i])
    teil = te.iloc[pakete[i]]
    p = modell.predict_proba(teil[NAMEN])[:, 1]
    return p, teil[["pumpe", "minute"]].assign(score=p)


with ThreadPoolExecutor(max_workers=N_PAKETE) as pool:
    futures = [pool.submit(bewerte, i) for i in range(N_PAKETE)]
    fertig = [f.result() for f in as_completed(futures)]   # Ankunftsreihenfolge

ankunft = sorted(range(N_PAKETE), key=lambda i: dauer[i])
print("Pakete in Reihenfolge der Fertigstellung:", ankunft)

# Ohne Schluessel: Ergebnisse aneinanderhaengen, der Tabelle zeilenweise zuordnen
ohne = np.concatenate([p for p, _ in fertig])
# Mit Schluessel: Pumpen-ID und Minute reisen mit und bestimmen die Zuordnung
mit = pd.concat([k for _, k in fertig]).merge(
    te[["pumpe", "minute", "fail24"]], on=["pumpe", "minute"], validate="one_to_one")

referenz = modell.predict_proba(te[NAMEN])[:, 1]    # sequentielle Referenz
falsch = (np.abs(ohne - referenz) > 0.01).mean()
alarme = ohne >= 0.5
print(f"Zeilen mit fremder Vorhersage (ohne Schluessel): {falsch:.1%}")
print(f"Alarme ohne Schluessel: {alarme.sum()}, davon an einer Zeile, "
      f"die keinen verdient: {(referenz[alarme] < 0.5).mean():.1%}")
print(f"PR-AUC ohne Schluessel: {average_precision_score(te.fail24, ohne):.3f}")
print(f"PR-AUC mit Schluessel:  {average_precision_score(mit.fail24, mit.score):.3f}"
      f"  (sequentielle Referenz: {average_precision_score(te.fail24, referenz):.3f})")

schluessel = pd.MultiIndex.from_frame(te[["pumpe", "minute"]])
nach_schluessel = mit.set_index(["pumpe", "minute"]).score.reindex(schluessel)
print("Zuordnung ueber (pumpe, minute) identisch zur Referenz:",
      np.allclose(nach_schluessel.to_numpy(), referenz))

# Beispiel: der hoechste Score der Referenz, und was ohne Schluessel dort steht
z = int(np.argmax(referenz))
print(f"\nhoechster Score der Referenz: Zeile {z} = {te.pumpe[z]}, "
      f"Minute {te.minute[z]}, Score {referenz[z]:.2f}")
print(f"ohne Schluessel steht an dieser Stelle: {ohne[z]:.2f}")

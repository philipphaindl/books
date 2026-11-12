"""Schritt 1, Pattern 28 Heuristic Benchmark: Maßstab bestimmen, bevor ein Modell trainiert wird."""
import numpy as np
from sklearn.metrics import average_precision_score

from daten import ZIEL, lade_daten
from modell import ENTWICKLUNG_BIS, kennzahlen, nutzen, speichere

df = lade_daten()
dev = df[df.monat <= ENTWICKLUNG_BIS]
y = dev[ZIEL].to_numpy()
n_k, n_z = dev.kunden_id.nunique(), len(dev)
print(f"Kunden {n_k:,} | Zeilen {n_z:,} | Zeilen je Kunde {n_z / n_k:.1f}")
print(f"Abwanderung in den nächsten 3 Monaten: {y.mean():.1%}")

# Maßstab 1: "Niemand kündigt" (die häufigste Klasse)
nie = kennzahlen(y, np.zeros(len(y)))

# Maßstab 2: die Faustregel des Retention-Teams. Sie lernt nichts, braucht also
# keinen Split und darf auf allen Entwicklungsdaten gemessen werden.
regel = (dev.tage_seit_login >= 4) | (dev.stunden_trend < 0.5)
r = kennzahlen(y, regel.to_numpy().astype(float), 0.5)
r["nutzen"] = nutzen(r, len(y))
ap_login = average_precision_score(y, dev.tage_seit_login)

print(f"\nNiemand kündigt: Accuracy {nie['accuracy']:.3f}")
print(f"Faustregel     : Accuracy {r['accuracy']:.3f}, Precision {r['precision']:.3f}, "
      f"Recall {r['recall']:.3f}")
print(f"                 F1 {r['f1']:.3f}, markiert {r['markiert']:.1%} der Zeilen")
print(f"Nutzen mit Faustregel: {r['nutzen']:.0f} Euro je 1000 Kunden-Monate")
print(f"PR-AUC nach Login-Tagen: {ap_login:.3f} (Zufall {y.mean():.3f})")

speichere("01_heuristik", {"basisrate": float(y.mean()), "nie": nie, "regel": r, "ap_login": float(ap_login),
                           "kunden": int(n_k), "zeilen": int(n_z),
                           "kunden_gesamt": int(df.kunden_id.nunique()), "zeilen_gesamt": int(len(df)),
                           "basisrate_gesamt": float(df[ZIEL].mean())})

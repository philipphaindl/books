"""Fallstudie C, Schritt 1: Der synthetische Shop in Zahlen."""
import json
from pathlib import Path

import numpy as np

import shop
from gemeinsam import lade_zeilen

d, z, train = lade_zeilen("pit")
p, s, ans = d["produkte"], d["sitzungen"], d["ans"]
n = len(p)
print(f"Produkte         : {n:,} (davon {shop.N_ALT:,} zum Start, {n - shop.N_ALT:,} neu in {shop.TAGE} Tagen)")
print(f"Marken           : {p.marke.nunique()}   Kategorien: {p.kategorie.nunique()}   Welten: {p.welt.nunique()}")
print(f"Sitzungen        : {len(s):,} (Training Tag 0-{shop.TEST_AB - 1}: {train.sum():,}, Test Tag {shop.TEST_AB}-{shop.TAGE - 1}: {(~train).sum():,})")
print(f"Kaufrate         : {s.kauf.mean():.1%} (Training {s.kauf[train].mean():.1%}, Test {s.kauf[~train].mean():.1%})")
print(f"Ansichten gesamt : {(ans >= 0).sum():,}   Ø je Sitzung {s.n_ansichten.mean():.2f}")

# Long Tail: wie viel Prozent der Ansichten entfallen auf die beliebtesten Produkte?
ans_je_produkt = d["ansichten_tag"].sum(0)
sortiert = np.sort(ans_je_produkt)[::-1]
kum = np.cumsum(sortiert) / sortiert.sum()
for anteil in (0.01, 0.10, 0.50):
    k = int(anteil * n)
    print(f"die beliebtesten {anteil:>4.0%} der Produkte ({k:>6,}) haben {kum[k - 1]:.0%} der Ansichten")
print(f"Produkte ohne eine einzige Ansicht: {(ans_je_produkt == 0).sum():,} ({(ans_je_produkt == 0).mean():.1%})")
print(f"größte Marke: {p.marke.value_counts().iloc[0]} Produkte, kleinste: {p.marke.value_counts().iloc[-1]}; "
      f"Marken mit weniger als 5 Produkten: {(p.marke.value_counts() < 5).sum()}")

# Kaltstart: wie oft kommt das aktuelle Produkt einer Testsitzung in keiner Trainingssitzung vor (erste drei Ansichten)?
tr = z[train]
unbekannt = ~z.produkt_id.isin(set(tr.produkt_id) | set(tr.vorher_1) | set(tr.vorher_2)).to_numpy()
print(f"\nTestsitzungen mit einem Produkt, das im Training nie vorkam: {unbekannt[~train].sum():,} ({unbekannt[~train].mean():.1%})")
print(f"  davon erst nach Tag {shop.TEST_AB - 1} eingeführt: {(p.start_tag.to_numpy()[z.produkt_id.to_numpy()][~train][unbekannt[~train]] >= shop.TEST_AB).mean():.0%}")
print("\nBeispielprodukte:")
print(p.sample(5, random_state=2)[["produkt_id", "kategorie", "marke", "preis", "titel"]].to_string(index=False))

# Werte für die Abbildungen
tage = range(shop.TEST_AB, shop.TAGE)
ub_tag = [float(unbekannt[(z.tag == t).to_numpy()].mean()) for t in tage]
Path(__file__).with_name("daten.json").write_text(json.dumps({
    "kumuliert": [[int(k), float(kum[k - 1])] for k in (1, 10, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 15000, 20000, n)],
    "unbekannt_tag": [[t, v] for t, v in zip(tage, ub_tag)],
    "n_produkte": n,
}))

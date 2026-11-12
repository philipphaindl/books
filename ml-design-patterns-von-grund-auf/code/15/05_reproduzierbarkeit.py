"""Lösungen zu den Aufgaben R1 bis R6 (Reproducibility).

Start: uv run --with scikit-learn --with pandas --with numpy python 05_reproduzierbarkeit.py
"""
import hashlib
from collections import deque
from graphlib import TopologicalSorter

import numpy as np
import pandas as pd

# --- R1: Skalierung im Betrieb --------------------------------------------------------------------------------
print("R1  Standardisierung mit Trainingskonstanten gegen Konstanten der Anfrage")
mittel, abw = 40.0, 10.0                  # gelernt im Training
alter = np.array([62.0, 58.0, 66.0])      # drei Kunden, die gerade eine Anfrage stellen
richtig = (alter - mittel) / abw
falsch = (alter - alter.mean()) / alter.std()
print("Alter:                  ", alter)
print("mit Trainingskonstanten:", np.round(richtig, 2))
print("mit Konstanten der Anfrage:", np.round(falsch, 2))
einzeln = alter[:1]
print("Einzelanfrage, Konstanten der Anfrage: Standardabweichung =", einzeln.std(), "-> Division durch null")

# --- R2: Repeatable Splitting ----------------------------------------------------------------------------------
print("\nR2  Split nach Patienten-ID über eine Hashfunktion")


def ist_training(patient_id: str, anteil: int = 8) -> bool:
    """Stabil über Prozesse und Rechner, anders als hash()."""
    h = int.from_bytes(hashlib.sha256(patient_id.encode()).digest()[:8], "big")
    return h % 10 < anteil


rng = np.random.default_rng(0)
patienten = [f"P{i:05d}" for i in range(1000)]
zeilen = pd.DataFrame({"patient": rng.choice(patienten, 10_000)})
zeilen["training"] = zeilen["patient"].map(ist_training)
anteil_pat = np.mean([ist_training(p) for p in patienten])
print(f"Anteil Training: Patienten {anteil_pat:.3f}, Zeilen {zeilen['training'].mean():.3f}")
beide = set(zeilen.loc[zeilen.training, "patient"]) & set(zeilen.loc[~zeilen.training, "patient"])
print("Patienten auf beiden Seiten:", len(beide))
neue = patienten + [f"P{i:05d}" for i in range(1000, 1200)]
vorher = {p: ist_training(p) for p in patienten}
nachher = {p: ist_training(p) for p in neue}
print("Zuordnung der alten Patienten nach 200 neuen Patienten geändert:", sum(vorher[p] != nachher[p] for p in patienten))
wechsel = [np.mean((np.random.default_rng(2 * s).random(1000) < 0.8) != (np.random.default_rng(2 * s + 1).random(1000) < 0.8))
           for s in range(200)]
print(f"Zum Vergleich zwei Zufallsaufteilungen mit anderem Seed (200 Paare): {np.mean(wechsel):.3f} der Patienten wechseln die Seite (erwartet 0,32)")
sigma = np.sqrt(1000 * 0.8 * 0.2)
print(f"Standardabweichung der Trainingszahl bei 1000 Patienten: {sigma:.2f} = {sigma / 10:.2f} Prozentpunkte")

# --- R3: Bridged Schema ------------------------------------------------------------------------------------------
print("\nR3  Bridged Schema, probabilistische Methode")
p_kredit = 0.7
treffer = p_kredit ** 2 + (1 - p_kredit) ** 2
print(f"Zufällig nach 70/30 zugewiesen: richtig {treffer:.2f}, falsch {1 - treffer:.2f}")
print(f"Immer \"Kreditkarte\" (häufigster Wert): richtig {p_kredit:.2f}, falsch {1 - p_kredit:.2f}")
anteil_alt = 0.5
print(f"Waren die Anteile früher 50/50 und man nimmt 70/30 an: richtig {p_kredit * anteil_alt + (1 - p_kredit) * (1 - anteil_alt):.2f}")

# --- R4: Windowed Inference -----------------------------------------------------------------------------------------
print("\nR4  Mittelwert der letzten drei Messwerte: Batch gegen Stream")
werte = pd.Series([10.0, 12.0, 11.0, 15.0, 20.0, 18.0, 17.0])


def fenster_mittel(letzte: deque) -> float:
    return sum(letzte) / len(letzte)


batch = werte.rolling(3, min_periods=1).mean()
puffer, stream = deque(maxlen=3), []
for w in werte:
    puffer.append(w)
    stream.append(fenster_mittel(puffer))
zentriert = werte.rolling(3, center=True, min_periods=1).mean()
tab = pd.DataFrame({"messwert": werte, "batch": batch.round(2), "stream": np.round(stream, 2), "zentriert": zentriert.round(2)})
print(tab.to_string())
print("Batch und Stream identisch:", np.allclose(batch, stream))
print("Zentriertes Fenster weicht ab in", int((~np.isclose(zentriert, stream)).sum()), "von", len(werte), "Zeilen (nutzt die Zukunft)")

# --- R5: Point-in-time-Join ---------------------------------------------------------------------------------------------
print("\nR5  Feature Store: Zeitpunktrichtiger Join")
merkmale = pd.DataFrame({
    "kunde": [1, 1, 1, 2, 2],
    "gueltig_ab": pd.to_datetime(["2026-03-01", "2026-03-10", "2026-03-20", "2026-03-05", "2026-03-25"]),
    "bestellungen_30d": [2, 5, 1, 7, 3],
})
ereignisse = pd.DataFrame({
    "kunde": [1, 1, 2, 2],
    "zeit": pd.to_datetime(["2026-03-12", "2026-03-25", "2026-03-03", "2026-03-15"]),
}).sort_values("zeit")
merkmale = merkmale.sort_values("gueltig_ab")
richtig = pd.merge_asof(ereignisse, merkmale, left_on="zeit", right_on="gueltig_ab", by="kunde")
neueste = merkmale.groupby("kunde").tail(1)[["kunde", "bestellungen_30d"]].rename(columns={"bestellungen_30d": "neuester_wert"})
naiv = ereignisse.merge(neueste, on="kunde")
ergebnis = richtig[["kunde", "zeit", "bestellungen_30d"]].merge(naiv, on=["kunde", "zeit"])
print(ergebnis.rename(columns={"bestellungen_30d": "zeitpunktrichtig"}).sort_values(["kunde", "zeit"]).to_string(index=False))

# --- R6: DAG ----------------------------------------------------------------------------------------------------------------
print("\nR6  Workflow Pipeline: was muss neu laufen?")
vorgaenger = {
    "clean": {"ingest"}, "featurize": {"clean"}, "split": {"clean"},
    "train": {"featurize", "split"}, "evaluate": {"train", "split"}, "register": {"train", "evaluate"},
}
nachfolger = {}
for ziel, quellen in vorgaenger.items():
    for q in quellen:
        nachfolger.setdefault(q, set()).add(ziel)


def betroffen(schritt):
    offen, gesehen = [schritt], {schritt}
    while offen:
        for n in nachfolger.get(offen.pop(), ()):
            if n not in gesehen:
                gesehen.add(n)
                offen.append(n)
    return gesehen


print("Topologische Ordnung:", list(TopologicalSorter(vorgaenger).static_order()))
for s in ("train", "split", "featurize", "clean"):
    b = sorted(betroffen(s))
    print(f"Änderung an {s:<9} -> neu: {', '.join(b)} ({len(b)} von 7)")
ts = TopologicalSorter(vorgaenger)
ts.prepare()
stufen = []
while ts.is_active():
    bereit = sorted(ts.get_ready())
    stufen.append(bereit)
    ts.done(*bereit)
print("Stufen (parallel ausführbar):", stufen)

"""Synthetische Pumpendaten und die gemeinsame Merkmalsfunktion (Fallstudie B).

Alles, was Training und Betrieb teilen muessen, steht in dieser Datei:
Datengenerator, Fensterlogik (`merkmale`), Batch-Variante und Stream-Variante.
"""
from collections import deque

import numpy as np
import pandas as pd
from numpy.lib.stride_tricks import sliding_window_view

N_PUMPEN = 30
TAGE = 56
MIN_TAG = 1440
FENSTER = 1440         # 24 Stunden in Minuten
KURZ = 120             # kurzes Teilfenster: die letzten 2 Stunden
SCHRITT = 10           # alle 10 Minuten wird eine Vorhersage gemacht
HORIZONT = 24 * 60     # "Ausfall in den naechsten 24 h"
SENSOREN = ["vib", "temp", "druck"]
NAMEN = [f"{s}_{k}" for k in ("mittel", "std", "delta", "anstieg") for s in SENSOREN]
START = pd.Timestamp("2027-01-04")


def erzeuge_daten(seed=13):
    """Minutenwerte fuer N_PUMPEN Pumpen; jede durchlaeuft mehrere Zyklen bis zum Ausfall."""
    rng = np.random.default_rng(seed)
    ende = TAGE * MIN_TAG
    teile = []
    for p in range(N_PUMPEN):
        basis = {"vib": rng.uniform(2.0, 3.2), "temp": rng.uniform(55, 68), "druck": rng.uniform(5.6, 6.4)}
        t0, zyklus = 0, 0
        while t0 < ende - 2 * 60:
            ausfall_zeit = t0 + int(rng.uniform(6, 14) * MIN_TAG)
            hat_ausfall = ausfall_zeit <= ende
            t1 = ausfall_zeit if hat_ausfall else ende
            m = np.arange(t0, t1)
            n = len(m)
            last = 0.5 + 0.5 * np.sin(2 * np.pi * ((m % MIN_TAG) / MIN_TAG - 0.25))
            sev = np.zeros(n)
            amp = {"vib": 1.0, "temp": 1.0, "druck": 1.0}
            if hat_ausfall:
                dauer = rng.uniform(60, 140) * 60              # Degradation beginnt so viele Minuten vor dem Ausfall
                rest = ausfall_zeit - m
                sev = np.clip(1 - rest / dauer, 0, 1) ** 2 + 1.5 * np.clip(1 - rest / 240, 0, 1) ** 2
                amp = {"vib": rng.uniform(0.6, 1.4), "temp": rng.uniform(0.2, 1.2), "druck": rng.uniform(0.2, 1.0)}
            vib = basis["vib"] * (1 + 0.1 * last) + 2.0 * amp["vib"] * sev + rng.normal(0, 0.3, n) + np.cumsum(rng.normal(0, 0.0015, n))
            temp = basis["temp"] + 4 * last + 12 * amp["temp"] * sev + rng.normal(0, 1.0, n) + np.cumsum(rng.normal(0, 0.01, n))
            druck = basis["druck"] - 0.15 * last - 0.5 * amp["druck"] * sev + rng.normal(0, 0.1, n)
            # harmlose Stoerungen: Lastspitzen, die der Degradation aehneln, aber keine sind
            for _ in range(rng.poisson(0.25 * n / MIN_TAG)):
                d = int(rng.uniform(60, 240))
                if n > d:
                    a = int(rng.integers(0, n - d))
                    bump = np.hanning(d)
                    vib[a:a + d] += rng.uniform(0.6, 1.5) * bump
                    temp[a:a + d] += rng.uniform(3, 8) * bump
            if hat_ausfall:
                rul = (ausfall_zeit - m).astype(np.float32)
                label = (rul <= HORIZONT).astype(np.int8)
            else:
                rul = np.full(n, np.nan, dtype=np.float32)
                label = np.where(ende - m > HORIZONT, 0, -1).astype(np.int8)   # -1: unbekannt (Datenende)
            teile.append(pd.DataFrame({
                "pumpe": f"P{p + 1:02d}", "zyklus": zyklus, "minute": m.astype(np.int32),
                "vib": vib.astype(np.float32), "temp": temp.astype(np.float32), "druck": druck.astype(np.float32),
                "rul_min": rul, "fail24": label,
            }))
            t0, zyklus = ausfall_zeit + 8 * 60, zyklus + 1     # 8 Stunden Reparatur ohne Messwerte
    return pd.concat(teile, ignore_index=True)


def merkmale(fenster):
    """EINE Definition der Fenstermerkmale. fenster: (n, 3, FENSTER) -> (n, 12)."""
    mittel = fenster.mean(-1)
    std = fenster.std(-1)
    delta = fenster[..., -KURZ:].mean(-1) - mittel   # letzte 2 h gegen 24 h
    t = np.arange(FENSTER) - (FENSTER - 1) / 2
    anstieg = (fenster * t).sum(-1) / (t ** 2).sum() * 60   # pro Stunde
    return np.concatenate([mittel, std, delta, anstieg], axis=1)


def merkmals_tabelle(df, versatz=0):
    """Batch-Variante: Fenster pro Zyklus.
    versatz=0: Fenster endet im Vorhersagezeitpunkt (richtig).
    versatz=719: Fenster ist um den Zeitpunkt zentriert, wie
    rolling(1440, center=True) (der Fehler)."""
    teile = []
    for (pumpe, zyklus), g in df.groupby(["pumpe", "zyklus"], sort=False):
        x = g[SENSOREN].to_numpy(np.float64)
        n, minute = len(x), g["minute"].to_numpy()
        if n < FENSTER:
            continue
        if versatz > 0:    # Zyklusende auffuellen, wie ffill nach rolling
            x = np.vstack([x, np.repeat(x[-1:], versatz, axis=0)])
        fenster = sliding_window_view(x, FENSTER, axis=0)   # (n, 3, FENSTER)
        i = np.arange(n)
        j = i + versatz - (FENSTER - 1)   # Fenster, das bei i + versatz endet
        ok = (minute % SCHRITT == 0) & (j >= 0) & (g["fail24"].to_numpy() >= 0)
        t = pd.DataFrame(merkmale(fenster[j[ok]]), columns=NAMEN)
        t.insert(0, "pumpe", pumpe)
        t.insert(1, "zyklus", zyklus)
        t.insert(2, "minute", minute[ok])
        t["rul_h"] = g["rul_min"].to_numpy()[ok] / 60
        t["fail24"] = g["fail24"].to_numpy()[ok]
        teile.append(t)
    return pd.concat(teile, ignore_index=True)


class PumpenStrom:
    """Stream-Variante: Ringpuffer der letzten FENSTER Messungen einer Pumpe."""

    def __init__(self):
        self.puffer = deque(maxlen=FENSTER)

    def neue_messung(self, minute, werte):
        self.puffer.append(werte)
        if len(self.puffer) < FENSTER or minute % SCHRITT:
            return None
        return merkmale(np.array(self.puffer).T[None])[0]

    def wartung(self):
        self.puffer.clear()


def tabelle(versatz=0):
    return merkmals_tabelle(erzeuge_daten(), versatz=versatz)


# Zeitliche Aufteilung: Training < Tag 30, Validierung Tag 33-43, Test ab Tag 46.
# Die Luecken von 3 Tagen sind laenger als der Vorhersagehorizont (24 h).
def zeit_split(t):
    tag = t["minute"] / MIN_TAG
    return t[tag < 30], t[(tag >= 33) & (tag < 43)], t[tag >= 46]

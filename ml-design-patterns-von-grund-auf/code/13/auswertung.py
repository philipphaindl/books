"""Ereignisbezogene Auswertung: zaehlt Ausfaelle und Fehlalarme statt einzelner Zeilen."""
import numpy as np
import pandas as pd

# Annahmen fuer die Kostenrechnung (keine Messwerte, siehe Text)
KOSTEN_AUSFALL = 18_000      # ungeplanter Stillstand
KOSTEN_GEPLANT = 2_500       # geplanter Austausch nach Alarm
KOSTEN_FEHLALARM = 1_500     # unnoetige Inspektion


def ereignis_bilanz(te, alarm):
    """te: Testtabelle (nur Zyklen mit Ausfall), alarm: bool-Array.
    Episode = Alarme mit hoechstens 6 h Abstand.
    Fehlalarm = Episode, die mehr als 48 h vor dem Ausfall liegt.
    Erkannt = Alarm 1 bis 24 h vor dem Ausfall."""
    te = te.assign(alarm=np.asarray(alarm, dtype=bool))
    erkannt = fehlalarme = 0
    ausfaelle = te.groupby(["pumpe", "zyklus"]).ngroups
    for _, g in te.groupby(["pumpe", "zyklus"], sort=False):
        a = g[g.alarm]
        if a.empty:
            continue
        neue_episode = a.minute.diff().fillna(1e9) > 360
        episode = neue_episode.cumsum()
        fehlalarme += int((a.groupby(episode).rul_h.min() > 48).sum())
        erkannt += int(a.rul_h.between(1, 24).any())
    return erkannt, ausfaelle, fehlalarme


def kosten(erkannt, ausfaelle, fehlalarme):
    return (ausfaelle - erkannt) * KOSTEN_AUSFALL + erkannt * KOSTEN_GEPLANT + fehlalarme * KOSTEN_FEHLALARM


def beste_schwelle(te, score, schwellen):
    """Schwelle mit den geringsten Gesamtkosten (Alarm, wenn score >= Schwelle)."""
    k = [kosten(*ereignis_bilanz(te, score >= s)) for s in schwellen]
    return schwellen[int(np.argmin(k))], min(k)

"""Synthetischer Onlineshop für die Fallstudie C (Kapitel 14).

Erzeugt Produkte (rund 20 000 zu Beginn, täglich kommen 50 neue dazu), Sitzungen mit Produktansichten
und Käufen sowie die Tagesstatistiken, aus denen später die Popularitätsfeatures berechnet werden.
Alles hängt nur von SEED ab. Die Effekte (Welt, Marke, Preislage, Produktqualität) sind absichtlich
in die Daten eingebaut; die Fallstudie zeigt, wie man sie findet, nicht wie stark sie in einem echten
Shop wären.
"""
import pickle
from pathlib import Path

import numpy as np
import pandas as pd

SEED = 14
TAGE = 70                 # Beobachtungszeitraum
TEST_AB = 50              # Tag 0-49 Training, Tag 50-69 Test
N_ALT = 20_000            # Produkte zu Beginn
NEU_PRO_TAG = 50          # Neuzugänge pro Tag
N_SITZUNGEN = 150_000
N_MARKEN = 800
MAX_ANS = 10              # längste betrachtete Sitzung
W_NUTZEN = 1.6            # Gewicht des mittleren Produktnutzens
W_POP = 1.0               # Gewicht der Beliebtheit (Käufe der letzten 7 Tage)
B0 = -4.2                 # Grundniveau der Kaufneigung (so gewählt, dass ca. 7 % der Sitzungen kaufen)

# Kategorie -> (Nomen im Titel, Medianpreis in Euro, Preisvorliebe: +1 Kundschaft kauft eher das teure
# Modell der Kategorie, -1 eher das günstige)
KATEGORIEN = {
    "Schuhe": (["Schuhe", "Stiefel"], 90, -1),
    "Jacken": (["Jacke", "Weste"], 150, +1),
    "Hosen": (["Hose", "Shorts"], 70, -1),
    "Rucksäcke": (["Rucksack", "Tasche"], 110, +1),
    "Zelte": (["Zelt", "Tarp"], 280, -1),
    "Schlafsäcke": (["Schlafsack", "Isomatte"], 120, +1),
    "Uhren": (["Uhr", "Pulsmesser"], 200, -1),
    "Helme": (["Helm", "Schutzbrille"], 80, +1),
    "Lampen": (["Stirnlampe", "Laterne"], 40, -1),
    "Flaschen": (["Trinkflasche", "Thermosflasche"], 25, +1),
    "Kocher": (["Kocher", "Kochset"], 60, -1),
    "Fahrradteile": (["Klingel", "Pumpe"], 35, +1),
}
KAT = list(KATEGORIEN)

# Welt = Anlass, zu dem ein Produkt gehört; jede Welt hat vier typische Titelwörter
WELTEN = {
    "Trailrunning": ["Trail", "Gelände", "Ultraleicht", "Laufweste"],
    "Bergwandern": ["Trekking", "Gipfel", "Hüttentour", "Bergstiefel"],
    "Camping": ["Camping", "Biwak", "Lagerfeuer", "Familienzelt"],
    "Radreisen": ["Gravel", "Bikepacking", "Radreise", "Fernroute"],
    "Wintersport": ["Ski", "Schnee", "Thermo", "Piste"],
    "Klettern": ["Kletter", "Fels", "Seilschaft", "Grip"],
    "Wassersport": ["Kajak", "Paddel", "Wasserdicht", "Seetour"],
    "Angeln": ["Angel", "Uferzone", "Tarnfarbe", "Fischer"],
    "Kinder": ["Kinder", "Junior", "Schulweg", "Mini"],
    "Stadt": ["Urban", "Pendler", "Büro", "Citytrip"],
    "Reisen": ["Reise", "Handgepäck", "Flughafen", "Kompakt"],
    "Fitness": ["Fitness", "Studio", "Intervall", "Workout"],
    "Laufsport": ["Marathon", "Asphalt", "Tempo", "Laufband"],
    "Yoga": ["Yoga", "Pilates", "Matte", "Balance"],
    "Golf": ["Golf", "Fairway", "Green", "Caddie"],
    "Reiten": ["Reit", "Turnier", "Stall", "Dressur"],
    "Jagd": ["Revier", "Pirsch", "Loden", "Ansitz"],
    "Tauchen": ["Tauch", "Riff", "Neopren", "Tiefsee"],
    "Segeln": ["Segel", "Regatta", "Deck", "Seemann"],
    "Vogelbeobachtung": ["Fernglas", "Beobachtung", "Naturpark", "Tarnnetz"],
}
WELT = list(WELTEN)
ZUSATZ = ["Pro", "Basic", "Set", "Light", "Plus", "Neu", ""]   # Titelzusatz, nur im Text sichtbar
Q_ZUSATZ = np.array([0.5, -0.4, 0.2, -0.2, 0.3, 0.0, 0.0])    # sein Beitrag zum Nutzen eines Produkts
GERAETE = ["mobil", "desktop", "tablet"]
PREISBAND_GRENZEN = [20, 40, 80, 150, 250, 400, 700]            # 8 Preisbänder in Euro


def _marken_namen(rng, n):
    silben = ["al", "bor", "cen", "dar", "el", "fi", "gor", "hal", "in", "jur", "kal", "lum", "mar", "nor",
              "or", "pal", "quen", "ras", "sol", "tur", "ur", "val", "wen", "xan", "yor", "zel", "ska", "tri"]
    namen = []
    gesehen = set()
    while len(namen) < n:
        name = "".join(rng.choice(silben, size=rng.integers(2, 4))).capitalize()
        if name not in gesehen:
            gesehen.add(name)
            namen.append(name)
    return np.array(namen)


def erzeuge():
    rng = np.random.default_rng(SEED)
    n = N_ALT + NEU_PRO_TAG * TAGE

    # ---- Produkte --------------------------------------------------------------------------------
    start = np.r_[np.full(N_ALT, -1), np.repeat(np.arange(TAGE), NEU_PRO_TAG)]
    kat_p = 1 / (np.arange(len(KAT)) + 3.0)
    kat = rng.choice(len(KAT), n, p=kat_p / kat_p.sum())
    kompatibel = np.array([rng.choice(len(WELT), 8, replace=False) for _ in KAT])    # je Kategorie 8 Welten
    welt = kompatibel[kat, rng.integers(0, 8, n)]
    marken = _marken_namen(rng, N_MARKEN)
    marke_p = 1 / (np.arange(N_MARKEN) + 1.0) ** 0.9
    marke = rng.choice(N_MARKEN, n, p=marke_p / marke_p.sum())
    median = np.array([KATEGORIEN[k][1] for k in KAT], dtype=float)
    z = rng.normal(size=n)                                                           # Preislage in der Kategorie
    preis = np.floor(np.exp(np.log(median[kat]) + 0.6 * z)) + 0.9

    zusatz = rng.integers(len(ZUSATZ), size=n)
    titel = []
    for i in range(n):
        wwoerter = list(rng.choice(WELTEN[WELT[welt[i]]], 2, replace=False))
        if rng.random() < 0.10:                                                      # Rauschen: Wort einer fremden Welt
            fremd = WELTEN[WELT[rng.integers(len(WELT))]]
            wwoerter[1] = fremd[rng.integers(4)]
        nomen = KATEGORIEN[KAT[kat[i]]][0][rng.integers(2)]
        teile = wwoerter + [nomen, ZUSATZ[zusatz[i]]]
        titel.append(" ".join(t for t in teile if t))

    produkte = pd.DataFrame({
        "produkt_id": np.arange(n), "kategorie": np.array(KAT)[kat], "welt": np.array(WELT)[welt],
        "marke": marken[marke], "preis": preis, "titel": titel, "start_tag": start,
    })

    # ---- verborgene Wirkung der Produkte auf die Kaufneigung -----------------------------------------
    q_welt = rng.normal(0, 0.55, len(WELT))
    q_marke = rng.normal(0, 0.5, N_MARKEN)
    vorliebe = np.array([KATEGORIEN[k][2] for k in KAT])
    q_prod = rng.normal(0, 0.6, n)
    nutzen = q_welt[welt] + q_marke[marke] + vorliebe[kat] * 1.1 * z + q_prod + Q_ZUSATZ[zusatz]        # Nutzen u_p eines Produkts

    # ---- Sitzungen -------------------------------------------------------------------------------
    S = N_SITZUNGEN
    tag = rng.integers(0, TAGE, S)
    stunde = rng.choice(24, S, p=_stunden_p())
    geraet = rng.choice(3, S, p=[0.60, 0.35, 0.05])
    welt_p = 1 / (np.arange(len(WELT)) + 1.0) ** 0.6
    s_welt = rng.choice(len(WELT), S, p=welt_p / welt_p.sum())
    n_ans = np.minimum(3 + rng.geometric(0.55, S) - 1, MAX_ANS)

    ansicht_gewicht = rng.lognormal(0, 1.0, n)                                        # Beliebtheit beim Stöbern
    in_welt = [np.flatnonzero(welt == w) for w in range(len(WELT))]
    kumuliert = [np.cumsum(ansicht_gewicht[ix]) for ix in in_welt]
    alle = np.arange(n)
    kum_alle = np.cumsum(ansicht_gewicht)

    ans = np.full((S, MAX_ANS), -1)
    for j in range(MAX_ANS):
        aktiv = np.flatnonzero(n_ans > j)
        offen = aktiv
        for _ in range(40):                                  # ziehen, bis das Produkt am Sitzungstag existiert
            if len(offen) == 0:
                break
            wahl = np.empty(len(offen), dtype=int)
            aus_welt = rng.random(len(offen)) < 0.75
            for w in range(len(WELT)):
                m = aus_welt & (s_welt[offen] == w)
                if m.any():
                    u = rng.random(m.sum()) * kumuliert[w][-1]
                    wahl[m] = in_welt[w][np.searchsorted(kumuliert[w], u)]
            m = ~aus_welt
            if m.any():
                u = rng.random(m.sum()) * kum_alle[-1]
                wahl[m] = alle[np.searchsorted(kum_alle, u)]
            ans[offen, j] = wahl
            offen = offen[start[wahl] > tag[offen]]
        if len(offen):                                       # Rest: Fallback auf ein Produkt der Startmenge
            ans[offen, j] = rng.integers(0, N_ALT, len(offen))

    maske = ans >= 0
    u_ans = np.where(maske, nutzen[np.where(maske, ans, 0)], 0.0)
    mittel_u = u_ans.sum(1) / n_ans
    stunden_eff = 0.3 * np.cos(2 * np.pi * (stunde - 20) / 24)
    geraet_eff = np.array([-0.2, 0.4, 0.0])[geraet]
    basis = B0 + W_NUTZEN * mittel_u + geraet_eff + stunden_eff

    # Käufe Tag für Tag: Beliebtheit (Käufe der letzten 7 Tage) wirkt auf die Kaufneigung zurück
    kaeufe_tag = np.zeros((TAGE, n), dtype=np.int32)
    kauf = np.zeros(S, dtype=bool)
    kauf_produkt = np.full(S, -1)
    g = np.where(maske, np.exp(u_ans) * 1.35 ** np.arange(MAX_ANS), 0.0)   # spätere Ansichten etwas wahrscheinlicher
    for t in range(TAGE):
        fenster = kaeufe_tag[max(t - 7, 0):t].sum(0)
        ix = np.flatnonzero(tag == t)
        pop = np.where(maske[ix], np.log1p(fenster[np.where(maske[ix], ans[ix], 0)]), 0.0).sum(1) / n_ans[ix]
        k = rng.random(len(ix)) < 1 / (1 + np.exp(-(basis[ix] + W_POP * pop)))
        cum = np.cumsum(g[ix], 1)
        pos = (cum < (rng.random(len(ix)) * cum[:, -1])[:, None]).sum(1)
        gekauft = ans[ix, np.minimum(pos, MAX_ANS - 1)]
        kauf[ix] = k
        kauf_produkt[ix[k]] = gekauft[k]
        np.add.at(kaeufe_tag[t], gekauft[k], 1)

    sitzungen = pd.DataFrame({
        "sitzung_id": np.arange(S), "tag": tag, "stunde": stunde, "geraet": np.array(GERAETE)[geraet],
        "n_ansichten": n_ans, "produkt_1": ans[:, 0], "produkt_2": ans[:, 1], "produkt_3": ans[:, 2],
        "kauf": kauf.astype(int), "kauf_produkt": kauf_produkt,
    })
    sitzungen["kauf_kategorie"] = np.where(
        kauf, produkte["kategorie"].to_numpy()[np.maximum(kauf_produkt, 0)], "")

    # ---- Tagesstatistik (Ereignisprotokoll des Shops): Ansichten und Käufe je Tag und Produkt ---------
    ans_tag = np.broadcast_to(tag[:, None], ans.shape)[maske]
    ansichten_tag = np.bincount(ans_tag * n + ans[maske], minlength=TAGE * n).reshape(TAGE, n)

    return {"produkte": produkte, "sitzungen": sitzungen, "ans": ans,
            "ansichten_tag": ansichten_tag.astype(np.int32), "kaeufe_tag": kaeufe_tag}


def _stunden_p():
    h = np.arange(24)
    p = 1.0 + 1.6 * np.exp(-0.5 * ((h - 20) / 2.5) ** 2) + 0.9 * np.exp(-0.5 * ((h - 12) / 2.0) ** 2)
    p[1:6] *= 0.25
    return p / p.sum()


def lade():
    """Erzeugt den Datensatz einmal und legt ihn in out/ ab (reproduzierbar, aber schneller bei Wiederholung)."""
    pfad = Path(__file__).with_name("out") / "shop.pkl"
    if pfad.exists():
        return pickle.loads(pfad.read_bytes())
    d = erzeuge()
    pfad.parent.mkdir(exist_ok=True)
    pfad.write_bytes(pickle.dumps(d))
    return d


if __name__ == "__main__":
    d = erzeuge()
    print(d["sitzungen"]["kauf"].mean(), d["produkte"].shape)

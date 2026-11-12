"""Synthetischer Datengenerator für die Fallstudie "Kundenabwanderung bei einem Streamingdienst".

Ein Streamingdienst startet in Monat 0 und wächst. Jede Zeile der Tabelle ist ein Kunde in einem
Monat (Stand Monatsende). Ziel `abwanderung_3m` = 1, wenn das Abonnement des Kunden spätestens mit
dem Monat m+2 endet. Da die Daten simuliert sind, kennen wir die Mechanik hinter den Zahlen:

* Ein Kunde ist meistens "normal" und gerät selten in eine Phase der Abkehr (versteckter Zustand s).
  In dieser Phase sinkt seine Nutzung, und seine Kündigungsneigung ist etwa 60-mal so hoch.
* Das Aktionsangebot (Kanal "aktion") endet nach drei Monaten, danach steigt der Preis: Kündigungsspitze.
* Zahlungsfehler und Supporttickets erhöhen die Neigung.
* Bei Kundinnen und Kunden ab 55 kündigt man häufiger "leise": ihre Nutzung sinkt in der Abkehrphase
  kaum, dafür wirken Zahlungsfehler und Preis stärker. Das Modell wird sie schlechter erkennen.
* Ab Monat 16 kommen ein neuer Tarif "mobil" und eine Preiserhöhung für "standard" und "premium".
  Ein Teil der Kunden ist preisempfindlich; das ist in den Daten nicht sichtbar.
"""
import hashlib
from pathlib import Path

import numpy as np
import pandas as pd

SEED = 2027
N_KUNDEN = 50_000
N_MONATE = 24            # Monate 0..23
HORIZONT = 3             # Kündigung innerhalb der nächsten 3 Monate
LETZTER_MONAT_MIT_LABEL = N_MONATE - 1 - HORIZONT   # 20
DRIFT_AB = 16            # Monat, ab dem sich die Welt ändert
ZIEL = "abwanderung_3m"

PREISE = {"basic": 7.99, "standard": 12.99, "premium": 17.99, "mobil": 4.99}
PREISERHOEHUNG = {"standard": 2.0, "premium": 2.0}


def _sigmoid(x):
    return 1 / (1 + np.exp(-x))


def erzeuge_daten(n_kunden: int = N_KUNDEN, seed: int = SEED) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    n, T = n_kunden, N_MONATE

    # --- Kundenmerkmale, die sich nicht ändern ------------------------------------------------
    anmeldung = np.where(rng.random(n) < 0.25, 0, rng.integers(1, 21, n))
    anmeldetag = anmeldung * 30 + rng.integers(0, 30, n)       # Tage seit Start des Dienstes
    bandbreite = rng.lognormal(np.log(50), 0.5, n).round(1)   # typische Anschlussgeschwindigkeit in Mbit/s, ändert sich nie
    alter = np.clip(rng.normal(40, 15, n).round(), 18, 85).astype(int)
    land = rng.choice(["AT", "DE", "CH"], n, p=[0.45, 0.40, 0.15])
    nach_drift = anmeldung >= DRIFT_AB
    plan = np.empty(n, dtype=object)
    plan[~nach_drift] = rng.choice(["basic", "standard", "premium"], (~nach_drift).sum(), p=[0.30, 0.50, 0.20])
    plan[nach_drift] = rng.choice(["mobil", "basic", "standard", "premium"], nach_drift.sum(),
                                  p=[0.40, 0.18, 0.30, 0.12])
    kanal = rng.choice(["organisch", "werbung", "partner", "aktion"], n, p=[0.45, 0.25, 0.12, 0.18])
    geraet = np.where(plan == "mobil", "handy", rng.choice(["tv", "handy", "web"], n, p=[0.45, 0.35, 0.20]))
    preisempfindlich = rng.random(n) < 0.30            # nicht beobachtbar

    basis_stunden = rng.lognormal(np.log(22), 0.55, n)
    basis_stunden *= np.select([geraet == "tv", geraet == "handy"], [1.3, 0.7], 1.0)
    basis_stunden *= np.select([plan == "mobil", plan == "premium"], [0.5, 1.15], 1.0)

    ab55 = alter >= 55
    beta_zahl = np.where(ab55, 2.4, 1.8)
    alt_effekt = np.select([alter < 25, ab55], [0.45, 0.0], 0.0)
    plan_effekt = np.select([plan == "basic", plan == "premium", plan == "mobil"], [0.25, -0.30, 0.80], 0.0)
    kanal_effekt = np.select([kanal == "aktion", kanal == "werbung", kanal == "partner"], [0.25, 0.20, -0.45], 0.0)
    preis_liste = np.array([PREISE[p] for p in plan])

    # --- Monat für Monat simulieren -------------------------------------------------------------
    felder = ["stunden", "sessions", "tage_seit_login", "tickets_30d", "zahlungsfehler_90d", "preis",
              "stunden_trend", "aktion_restmonate"]
    werte = {f: np.full((T, n), np.nan, dtype=np.float32) for f in felder}
    aktiv = np.zeros((T, n), dtype=bool)
    letzter_monat = np.full(n, -1)
    gekuendigt = np.zeros(n, dtype=bool)
    lebt = np.ones(n, dtype=bool)

    e = rng.normal(0, 0.3, n)
    s = np.zeros(n, dtype=bool)                       # versteckt: befindet sich der Kunde in einer Phase der Abkehr?
    eintritt = 0.009 * np.where(plan == "mobil", 3.0, 1.0)
    h_hist = [None, None, None]
    zf_hist = [np.zeros(n), np.zeros(n), np.zeros(n)]
    for t in range(T):
        imd = lebt & (anmeldung <= t)                  # in diesem Monat Kunde
        tenure = t - anmeldung
        s = np.where(s, rng.random(n) > 0.15, rng.random(n) < eintritt)
        e = 0.6 * e + rng.normal(0, 0.2, n) - 0.9 * s * np.where(ab55, 0.35, 1.0)
        stunden = basis_stunden * np.exp(e) * rng.lognormal(0, 0.15, n)
        sessions = rng.poisson(np.maximum(stunden * 1.4, 0.1))
        tage = np.minimum(30, rng.poisson(1.5 * np.exp(-1.5 * e)))
        tickets = rng.poisson(0.12 + 0.45 * s)
        zf_neu = rng.poisson(0.06, n)
        zf = zf_hist[0] + zf_hist[1] + zf_hist[2] + zf_neu
        vorher = [h for h in h_hist if h is not None]
        trend = stunden / np.maximum(np.mean(vorher, axis=0), 0.5) if vorher else np.ones(n)
        trend = np.where(tenure >= 1, trend, 1.0)

        aktion_aktiv = (kanal == "aktion") & (tenure < 3)
        rest = np.where(kanal == "aktion", np.maximum(0, 3 - tenure), 0)
        preis = preis_liste * np.where(aktion_aktiv, 0.5, 1.0)
        if t >= DRIFT_AB:
            preis = preis + np.array([PREISERHOEHUNG.get(p, 0.0) for p in plan])

        logit = (-5.8 + 5.1 * s + plan_effekt + kanal_effekt + alt_effekt
                 + beta_zahl * np.minimum(zf_neu, 2)
                 + 0.20 * np.minimum(tickets, 3)
                 + 0.45 * np.exp(-np.maximum(tenure, 0) / 3.0)
                 + np.where((kanal == "aktion") & (tenure == 3), 2.8, 0.0))
        if t >= DRIFT_AB:
            logit = logit + np.where(preisempfindlich & np.isin(plan, ["standard", "premium"]), 2.6, 0.0)
            logit = logit + np.where(ab55 & np.isin(plan, ["standard", "premium"]), 1.2, 0.0)
        kuendigt = imd & (rng.random(n) < _sigmoid(logit)) & (t <= T - 2)

        for f, v in zip(felder, [stunden, sessions, tage, tickets, zf, preis, trend, rest]):
            werte[f][t, imd] = v[imd]
        aktiv[t] = imd
        letzter_monat[imd] = t
        gekuendigt |= kuendigt
        lebt &= ~kuendigt
        h_hist = [stunden, h_hist[0], h_hist[1]]
        zf_hist = [zf_neu, zf_hist[0], zf_hist[1]]

    # --- Tabelle bauen ---------------------------------------------------------------------------
    monat_idx, kunde_idx = np.nonzero(aktiv)
    df = pd.DataFrame({
        "kunden_id": np.array([f"K{i:06d}" for i in range(n)])[kunde_idx],
        "monat": monat_idx,
        "alter": alter[kunde_idx],
        "land": land[kunde_idx],
        "tarif": plan[kunde_idx],
        "kanal": kanal[kunde_idx],
        "geraet": geraet[kunde_idx],
        "tenure": monat_idx - anmeldung[kunde_idx],
        "anmeldetag": anmeldetag[kunde_idx],
        "bandbreite_mbit": bandbreite[kunde_idx],
    })
    for f in felder:
        df[f] = werte[f][monat_idx, kunde_idx]
    for f in ["sessions", "tage_seit_login", "tickets_30d", "zahlungsfehler_90d", "aktion_restmonate"]:
        df[f] = df[f].astype(int)
    df["preis"] = df["preis"].astype(float).round(2)
    df["stunden"] = df["stunden"].astype(float).round(2)
    df["stunden_trend"] = df["stunden_trend"].astype(float).round(3)
    # Label: Kündigung in den nächsten drei Monaten (letzter bezahlter Monat liegt in [m, m+2])
    df[ZIEL] = (gekuendigt[kunde_idx] & (letzter_monat[kunde_idx] - monat_idx <= HORIZONT - 1)).astype(int)
    df = df[df["monat"] <= LETZTER_MONAT_MIT_LABEL]    # spätere Monate: Label noch nicht bekannt
    df["altersgruppe"] = pd.cut(df["alter"], [0, 24, 39, 54, 200], labels=["18-24", "25-39", "40-54", "55+"]).astype(str)
    return df.sort_values(["kunden_id", "monat"]).reset_index(drop=True)


def lade_daten() -> pd.DataFrame:
    """Daten erzeugen und auf der Platte zwischenspeichern (Dateiname enthält den Hash dieser Datei)."""
    h = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()[:10]
    cache = Path(__file__).parent / ".cache" / f"daten_{h}.pkl"
    if cache.exists():
        return pd.read_pickle(cache)
    df = erzeuge_daten()
    cache.parent.mkdir(exist_ok=True)
    df.to_pickle(cache)
    return df


# --- Repeatable Splitting: Zuordnung per Hash der Kunden-ID -------------------------------------
def mit_bucket(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    tabelle = {k: bucket(k) for k in df["kunden_id"].unique()}
    df["bucket"] = df["kunden_id"].map(tabelle)
    return df


def bucket(kunden_id: str, n: int = 10) -> int:
    """Stabil über Prozesse und Rechner hinweg (nicht Pythons gesalzenes hash())."""
    digest = hashlib.sha256(kunden_id.encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big") % n


def teile(df: pd.DataFrame):
    """60 % Training, 20 % Validierung, 20 % Test, nach Kunde statt nach Zeile."""
    df = mit_bucket(df)
    return df[df.bucket < 6], df[df.bucket.isin([6, 7])], df[df.bucket >= 8]


if __name__ == "__main__":
    df = lade_daten()
    print(df.shape, df.kunden_id.nunique(), df[ZIEL].mean())
    print(df.head())

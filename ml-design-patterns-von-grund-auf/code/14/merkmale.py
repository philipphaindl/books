"""Merkmalsbau der Fallstudie. Eine Klasse, die beim Training und im Dienst identisch benutzt wird.

Eingabe ist ein DataFrame mit einer Zeile je Sitzung (Zustand nach der dritten Produktansicht):
produkt_id, marke, kategorie, preis, titel, vorher_1, vorher_2, geraet, stunde, ans_7d, kauf_7d, rate_7d.
Ausgabe ist eine Sparse-Matrix. Jede Zutat der Fallstudie lässt sich über einen Schalter zuschalten.
"""
import numpy as np
import pandas as pd
import scipy.sparse as sp
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.utils import murmurhash3_32

from shop import GERAETE, KAT, PREISBAND_GRENZEN

BAENDER = len(PREISBAND_GRENZEN) + 1


def bucket(werte, b, salz):
    """Hashed Feature: Bucket je Wert per MurmurHash3, deterministisch, ohne Wörterbuch."""
    h = {w: murmurhash3_32(f"{salz}={w}", positive=True) % b
         for w in set(werte)}
    return np.array([h[w] for w in werte])


def position(serie, vokabular):
    """Spaltennummer jedes Werts laut Wörterbuch; -1 für Werte, die das Wörterbuch nicht kennt."""
    return pd.Series(serie).map(vokabular).fillna(-1).astype(int).to_numpy()


def einsen(spalte, breite):
    """One-Hot als Sparse-Matrix; Spalte -1 (unbekannter Wert) ergibt eine Nullzeile."""
    spalte = np.asarray(spalte)
    zeilen = np.flatnonzero(spalte >= 0)
    return sp.csr_matrix((np.ones(len(zeilen)), (zeilen, spalte[zeilen])), shape=(len(spalte), breite))


def preisband(preis):
    return np.digitize(preis, PREISBAND_GRENZEN)


def zaehle(werte):
    return {w: i for i, w in enumerate(werte)}


class Merkmale:
    def __init__(self, ids="vokabular", marke="vokabular", b_id=16384, b_marke=1024, tabelle=True,
                 band=False, kreuz=False, text=False, embedding=None, store=False):
        self.ids, self.marke, self.b_id, self.b_marke = ids, marke, b_id, b_marke
        self.tabelle, self.band, self.kreuz = tabelle, band, kreuz
        self.text, self.embedding, self.store = text, embedding, store

    # -- Wörterbücher und Skalierung werden nur aus den Trainingsdaten gelernt ------------------------
    def fit(self, df):
        self.vok_id = zaehle(sorted(df.produkt_id.unique()))
        self.vok_marke = zaehle(sorted(df.marke.unique()))
        self.vok_kreuz = zaehle(f"{k}|{b}" for k in KAT for b in range(BAENDER))
        if self.text:
            self.tfidf = TfidfVectorizer(min_df=2, sublinear_tf=True).fit(df.titel)
        zahlen = self._zahlen(df)
        self.mw, self.sd = zahlen.mean(0), zahlen.std(0) + 1e-9
        return self

    def _zahlen(self, df):
        stunde = 2 * np.pi * df.stunde / 24
        sp_ = [np.log(df.preis.to_numpy()), np.sin(stunde), np.cos(stunde)]
        if self.store:
            sp_ += [df.ans_7d.to_numpy(), df.kauf_7d.to_numpy(), df.rate_7d.to_numpy()]
        return np.column_stack(sp_)

    def transform(self, df):
        b = []                                              # Blöcke, am Ende nebeneinander
        if self.tabelle:
            b.append(einsen(position(df.kategorie, zaehle(KAT)), len(KAT)))
            b.append(einsen(position(df.geraet, zaehle(GERAETE)), len(GERAETE)))
            b.append(sp.csr_matrix((self._zahlen(df) - self.mw) / self.sd))
        if self.band:
            b.append(einsen(preisband(df.preis.to_numpy()), BAENDER))
        if self.ids == "vokabular":
            b.append(einsen(position(df.produkt_id, self.vok_id), len(self.vok_id)))
        elif self.ids == "hash":
            b.append(einsen(bucket(df.produkt_id.to_numpy(), self.b_id, "produkt"), self.b_id))
        if self.marke == "vokabular":
            b.append(einsen(position(df.marke, self.vok_marke), len(self.vok_marke)))
        elif self.marke == "hash":
            b.append(einsen(bucket(df.marke.to_numpy(), self.b_marke, "marke"), self.b_marke))
        if self.kreuz:
            band = preisband(df.preis.to_numpy())
            kreuz = [f"{k}|{p}" for k, p in zip(df.kategorie, band)]
            spalten = position(kreuz, self.vok_kreuz)
            b.append(einsen(spalten, len(self.vok_kreuz)))
        if self.text:
            b.append(self.tfidf.transform(df.titel))
        if self.embedding is not None:
            b.append(sp.csr_matrix(self._mittel_embedding(df)))
        return sp.hstack(b, format="csr")

    def _mittel_embedding(self, df):
        e = self.embedding
        summe = np.zeros((len(df), e.shape[1]))
        for spalte in ("produkt_id", "vorher_1", "vorher_2"):
            ids = df[spalte].to_numpy()
            ok = (ids >= 0) & (ids < len(e))
            summe[ok] += e[ids[ok]]
        return summe / 3

"""Popularitätsfeatures aus dem Ereignisprotokoll: drei Varianten, nur eine ist Point-in-Time-korrekt."""
import numpy as np

FENSTER = 7           # Tage
PRIOR_RATE = 0.017    # grobe Käufe je Ansicht, Glättung für Produkte mit wenig Ansichten
PRIOR_GEWICHT = 30


def _kumuliert(mat):
    """c[d] = Summe über alle Tage < d (c hat einen Tag mehr als mat)."""
    return np.vstack([np.zeros((1, mat.shape[1]), dtype=np.int64), np.cumsum(mat, 0, dtype=np.int64)])


class Protokoll:
    def __init__(self, ansichten_tag, kaeufe_tag):
        self.cv = _kumuliert(ansichten_tag)
        self.ck = _kumuliert(kaeufe_tag)
        self.tage = ansichten_tag.shape[0]

    def fenster(self, tag, produkt, modus):
        """Ansichten und Käufe des Produkts im Fenster, das für `modus` gilt.

        pit     : Tage tag-7 bis tag-1 (Stand am Morgen des Sitzungstags)
        mit_tag : Tage tag-6 bis tag   (enthält die Sitzung selbst)
        gesamt  : alle Tage            (enthält auch die Zukunft)
        """
        tag = np.asarray(tag)
        if modus == "pit":
            von, bis = np.maximum(tag - FENSTER, 0), tag
        elif modus == "mit_tag":
            von, bis = np.maximum(tag - FENSTER + 1, 0), tag + 1
        elif modus == "gesamt":
            von, bis = np.zeros_like(tag), np.full_like(tag, self.tage)
        else:
            raise ValueError(modus)
        ans = self.cv[bis, produkt] - self.cv[von, produkt]
        kauf = self.ck[bis, produkt] - self.ck[von, produkt]
        return ans, kauf


def kaufrate(ans, kauf):
    """Geglättete Kaufrate: wenige Ansichten ziehen die Rate Richtung Durchschnitt."""
    return (kauf + PRIOR_GEWICHT * PRIOR_RATE) / (ans + PRIOR_GEWICHT)


def aggregiere(ans, kauf):
    """Sitzungsmerkmale aus den Fensterwerten der drei angesehenen Produkte (Arrays der Form n x 3)."""
    return {"ans_7d": np.log1p(ans).mean(1), "kauf_7d": np.log1p(kauf).mean(1), "rate_7d": kaufrate(ans, kauf).mean(1)}

"""Produkt-Embeddings aus Ko-Klick-Daten: PPMI-Matrix, danach TruncatedSVD (Matrixfaktorisierung)."""
import numpy as np
import scipy.sparse as sp
from sklearn.decomposition import TruncatedSVD

DIM = 32


def kookkurrenz(ans, n_produkte):
    """Symmetrische Zählmatrix C: C[i, j] = in wie vielen Sitzungen wurden i und j beide angesehen."""
    zeilen, spalten = [], []
    for a in range(ans.shape[1]):
        for b in range(a + 1, ans.shape[1]):
            ok = (ans[:, a] >= 0) & (ans[:, b] >= 0) & (ans[:, a] != ans[:, b])
            zeilen.append(ans[ok, a])
            spalten.append(ans[ok, b])
    i, j = np.concatenate(zeilen), np.concatenate(spalten)
    c = sp.coo_matrix((np.ones(len(i)), (i, j)), shape=(n_produkte, n_produkte)).tocsr()
    return c + c.T


def ppmi(c):
    """Positive Pointwise Mutual Information: max(0, log P(i,j) / (P(i) P(j)))."""
    c = c.tocoo()
    gesamt = c.sum()
    zeile = np.asarray(c.sum(1)).ravel()
    pmi = np.log(c.data * gesamt / (zeile[c.row] * zeile[c.col]))
    keep = pmi > 0
    return sp.csr_matrix((pmi[keep], (c.row[keep], c.col[keep])), shape=c.shape)


def lerne_embeddings(ans, n_produkte, dim=DIM, seed=0):
    """Tabelle (n_produkte x dim); Produkte ohne Ko-Klicks bleiben Nullvektoren."""
    m = ppmi(kookkurrenz(ans, n_produkte))
    svd = TruncatedSVD(n_components=dim, random_state=seed)
    e = svd.fit_transform(m)                            # = U * Sigma
    norm = np.linalg.norm(e, axis=1, keepdims=True)
    # Länge 1, damit das Skalarprodukt der Kosinus ist; Nullvektoren bleiben 0
    e = np.divide(e, norm, out=np.zeros_like(e), where=norm > 0)
    return e, m, svd

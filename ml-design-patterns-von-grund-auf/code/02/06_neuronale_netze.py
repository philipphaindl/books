"""Neuronales Netz (Parameter zählen) und Embedding als Nachschlagetabelle."""
import numpy as np
from sklearn.decomposition import TruncatedSVD
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import StandardScaler

from common import maschinen

df = maschinen()
X = df[["temperatur_c", "schwingung_mm_s"]]
X_tr, X_te, y_tr, y_te = train_test_split(X, df.ausfall, test_size=0.3, random_state=0)
skala = StandardScaler().fit(X_tr)

netz = MLPClassifier(hidden_layer_sizes=(16, 8), max_iter=2000, random_state=0)
netz.fit(skala.transform(X_tr), y_tr)
print("Genauigkeit Test:", round(netz.score(skala.transform(X_te), y_te), 3))
for i, (W, b) in enumerate(zip(netz.coefs_, netz.intercepts_), 1):
    print(f"Schicht {i}: Gewichte {W.shape}, Bias {b.shape}")
n = sum(W.size + b.size for W, b in zip(netz.coefs_, netz.intercepts_))
print("Parameter insgesamt:", n)

# Embedding als Nachschlagetabelle: Zeile idx der Matrix E = "One-hot mal E"
print()
vokabular = ["drucker", "scanner", "passwort", "login", "vpn"]
rng = np.random.default_rng(1)
E = rng.normal(size=(len(vokabular), 3)).round(2)  # (Wörter x Dimension), hier zufällig; beim Training würde sie gelernt
print("Embedding-Tabelle E (eine Zeile pro Wort):")
for wort, zeile in zip(vokabular, E):
    print(f"  {wort:9s}", zeile)
idx = vokabular.index("passwort")
one_hot = np.eye(len(vokabular))[idx]
print("One-hot für 'passwort':", one_hot)
print("one_hot @ E            :", one_hot @ E)
print("E[idx]                 :", E[idx])

# Bedeutung aus Daten: Wörter, die in denselben Tickets vorkommen, bekommen ähnliche Vektoren
tickets = [
    "drucker druckt nicht scanner offline",
    "scanner und drucker streiken",
    "drucker papierstau scanner kaputt",
    "passwort vergessen login gesperrt",
    "login fehlgeschlagen passwort zurücksetzen",
    "passwort abgelaufen login nicht möglich",
    "vpn verbindet nicht",
    "vpn bricht ab verbindung getrennt",
    "vpn langsam verbindung instabil",
    "vpn login fehlgeschlagen",
    "drucker braucht login passwort",
    "scanner offline vpn getrennt",
]
cv = CountVectorizer()
dok_wort = cv.fit_transform(tickets)  # Dokument x Wort
vektoren = TruncatedSVD(n_components=3, random_state=0).fit(dok_wort).components_.T  # Wort x 3
namen = list(cv.get_feature_names_out())


def kosinus(a, b):
    va, vb = vektoren[namen.index(a)], vektoren[namen.index(b)]
    return va @ vb / (np.linalg.norm(va) * np.linalg.norm(vb))


for a, b in [("drucker", "scanner"), ("passwort", "login"), ("drucker", "passwort"), ("vpn", "drucker")]:
    print(f"Ähnlichkeit({a}, {b}) = {kosinus(a, b):+.2f}")

"""Accuracy, Klassenungleichgewicht und zwei klassische Fallen beim Rebalancing."""
import numpy as np
from sklearn.datasets import make_classification
from sklearn.dummy import DummyClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, precision_score, recall_score
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsClassifier


def daten(n, anteil=0.01, seed=0):
    return make_classification(n_samples=n, n_features=10, n_informative=4, n_redundant=0,
                               weights=[1 - anteil, anteil], class_sep=1.5, flip_y=0.0,
                               random_state=seed)


def bericht(name, modell, X_test, y_test):
    pred = modell.predict(X_test)
    print(f"{name:34s} Accuracy {accuracy_score(y_test, pred):.3f}  "
          f"Recall {recall_score(y_test, pred):.2f}  "
          f"Precision {precision_score(y_test, pred, zero_division=0):.2f}")


print("== 1. Accuracy reicht nicht (1 % Betrug) ==")
X, y = daten(20_000)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.5, stratify=y, random_state=0)
bericht("Immer 'kein Betrug'", DummyClassifier(strategy="most_frequent").fit(X_train, y_train), X_test, y_test)
bericht("Logistische Regression", LogisticRegression(max_iter=1000).fit(X_train, y_train), X_test, y_test)
bericht("... mit class_weight='balanced'", LogisticRegression(max_iter=1000, class_weight="balanced").fit(X_train, y_train), X_test, y_test)

print("\n== 2. Mehr Daten: Anteil bleibt, Metrik-Falle auch ==")
X_pool, y_pool = daten(300_000)                     # ein Pool, damit Training und Test dieselbe Verteilung haben
X_test2, y_test2 = X_pool[-100_000:], y_pool[-100_000:]
for n in [2_000, 20_000, 200_000]:
    Xn, yn = X_pool[:n], y_pool[:n]
    m = LogisticRegression(max_iter=1000).fit(Xn, yn)
    pred = m.predict(X_test2)
    print(f"n={n:7d}  Betrugsfälle im Training: {yn.sum():5d}  Anteil {yn.mean():.3f}  "
          f"Accuracy {accuracy_score(y_test2, pred):.3f}  Recall {recall_score(y_test2, pred):.2f}")

print("\n== 3. Oversampling VOR dem Split täuscht (5 % Minderheit, 1-Nächster-Nachbar) ==")
X, y = daten(4_000, anteil=0.05, seed=3)
X[:, :] += np.random.default_rng(0).normal(0, 1.0, X.shape)       # Rauschen: kein Fall ist ein Zwilling
fall = np.flatnonzero(y == 1)
X_dup, y_dup = np.vstack([X, np.repeat(X[fall], 9, axis=0)]), np.concatenate([y, np.ones(9 * len(fall), int)])
modell = lambda: KNeighborsClassifier(n_neighbors=1)

Xa, Xb, ya, yb = train_test_split(X_dup, y_dup, test_size=0.3, random_state=0)      # falsch: erst duplizieren
bericht("Duplizieren, dann splitten (falsch)", modell().fit(Xa, ya), Xb, yb)

Xa, Xb, ya, yb = train_test_split(X, y, test_size=0.3, stratify=y, random_state=0)   # richtig: erst splitten
fa = np.flatnonzero(ya == 1)
Xa2, ya2 = np.vstack([Xa, np.repeat(Xa[fa], 9, axis=0)]), np.concatenate([ya, np.ones(9 * len(fa), int)])
bericht("Splitten, dann duplizieren (richtig)", modell().fit(Xa2, ya2), Xb, yb)

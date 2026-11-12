"""Ein linearer Klassifikator sieht Kombinationen nur, wenn man sie ihm gibt (Feature Cross)."""
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier

rng = np.random.default_rng(42)
X = rng.uniform(-1, 1, size=(2000, 2))                 # z. B. (Entfernung, Preis), zentriert
y = (X[:, 0] * X[:, 1] > 0).astype(int)                # Klasse hängt von der Kombination ab
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=0)

linear = LogisticRegression().fit(X_train, y_train)
print(f"Logistische Regression, Rohmerkmale:      {linear.score(X_test, y_test):.2f}")

cross = lambda A: np.column_stack([A, A[:, 0] * A[:, 1]])  # drittes Feature: das Produkt
mit_cross = LogisticRegression().fit(cross(X_train), y_train)
print(f"Logistische Regression, mit Feature Cross: {mit_cross.score(cross(X_test), y_test):.2f}")

baum = DecisionTreeClassifier(max_depth=4, random_state=0).fit(X_train, y_train)
print(f"Entscheidungsbaum, Rohmerkmale (Tiefe 4):  {baum.score(X_test, y_test):.2f}")

np.savetxt("out/xor_punkte.csv", np.column_stack([X[:80], y[:80]]), delimiter=",",
           header="x1,x2,klasse", comments="", fmt="%.3f")

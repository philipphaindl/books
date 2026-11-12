"""Live-Demo für "ML in 20 Minuten": Overfitting an einem Entscheidungsbaum."""
from sklearn.datasets import make_moons
from sklearn.dummy import DummyClassifier
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier

X, y = make_moons(n_samples=400, noise=0.35, random_state=0)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=0)

basis = DummyClassifier(strategy="most_frequent").fit(X_train, y_train)
test = basis.score(X_test, y_test)
print(f"Baseline (immer häufigste Klasse): Test {test:.2f}")
print("Tiefe  Train  Test")
for tiefe in [1, 2, 3, 4, 6, 8, 12, 20]:
    baum = DecisionTreeClassifier(max_depth=tiefe, random_state=0)
    baum.fit(X_train, y_train)
    train, test = baum.score(X_train, y_train), baum.score(X_test, y_test)
    print(f"{tiefe:5d}  {train:.2f}   {test:.2f}")

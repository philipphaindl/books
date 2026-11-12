"""Entscheidungsbaum, Random Forest und Gradient Boosting auf denselben Daten."""
from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier, export_text

from common import maschinen

df = maschinen()
X = df[["temperatur_c", "schwingung_mm_s"]]
X_tr, X_te, y_tr, y_te = train_test_split(X, df.ausfall, test_size=0.3, random_state=0)

baum2 = DecisionTreeClassifier(max_depth=2, random_state=0).fit(X_tr, y_tr)
print(export_text(baum2, feature_names=list(X.columns)))

modelle = {
    "Logistische Regression": LogisticRegression(),
    "Baum, Tiefe 2": baum2,
    "Baum, unbegrenzt": DecisionTreeClassifier(random_state=0),
    "Random Forest (200 Bäume)": RandomForestClassifier(n_estimators=200, random_state=0),
    "Gradient Boosting (100 Bäume)": GradientBoostingClassifier(random_state=0),
}
print(f"{'Modell':32s} {'Training':>9s} {'Test':>7s}")
for name, m in modelle.items():
    m.fit(X_tr, y_tr)
    print(f"{name:32s} {m.score(X_tr, y_tr):9.3f} {m.score(X_te, y_te):7.3f}")

voll = modelle["Baum, unbegrenzt"]
print("\nUnbegrenzter Baum: Tiefe", voll.get_depth(), ", Blätter", voll.get_n_leaves())

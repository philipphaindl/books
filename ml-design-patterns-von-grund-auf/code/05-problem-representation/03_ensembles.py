"""Pattern 7 Ensembles: Bagging, Boosting und Stacking im Vergleich zu einem einzelnen Baum."""
import json
from pathlib import Path

import numpy as np
from sklearn.datasets import make_classification
from sklearn.ensemble import (AdaBoostClassifier, BaggingClassifier, GradientBoostingClassifier,
                              RandomForestClassifier, StackingClassifier)
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score, StratifiedKFold
from sklearn.neighbors import KNeighborsClassifier
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.tree import DecisionTreeClassifier

# 2.000 Beispiele, 20 Features (8 informativ), 8 % verrauschte Labels
X, y = make_classification(n_samples=2000, n_features=20, n_informative=8, n_redundant=4,
                           flip_y=0.08, class_sep=0.8, random_state=0)
cv = StratifiedKFold(5, shuffle=True, random_state=0)

stack = StackingClassifier(
    estimators=[("rf", RandomForestClassifier(100, random_state=0)),
                ("gb", GradientBoostingClassifier(random_state=0)),
                ("knn", make_pipeline(StandardScaler(), KNeighborsClassifier(15)))],
    final_estimator=LogisticRegression(), cv=5)

modelle = {
    "ein Entscheidungsbaum": DecisionTreeClassifier(random_state=0),
    "Logistische Regression": make_pipeline(StandardScaler(), LogisticRegression()),
    "Bagging (100 Bäume)": BaggingClassifier(DecisionTreeClassifier(),
                                             n_estimators=100, random_state=0),
    "Random Forest (100 Bäume)": RandomForestClassifier(100, random_state=0),
    "AdaBoost (100 Stümpfe)": AdaBoostClassifier(n_estimators=100, random_state=0),
    "Gradient Boosting (100 Bäume)": GradientBoostingClassifier(random_state=0),
    "Stacking (RF + GB + kNN -> LR)": stack,
}
res = []
for name, m in modelle.items():
    s = cross_val_score(m, X, y, cv=cv)
    print(f"{name:34s} Genauigkeit {s.mean():.3f} ± {s.std():.3f}")
    res.append({"name": name, "mean": round(float(s.mean()), 3), "std": round(float(s.std()), 3)})
Path(__file__).with_name("ensembles.json").write_text(json.dumps(res, ensure_ascii=False))

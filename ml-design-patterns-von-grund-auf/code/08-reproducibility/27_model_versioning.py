"""Pattern 27 Model Versioning: Registry mit Versionen, Alias und Canary-Routing."""
import hashlib

import numpy as np
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split

rng = np.random.default_rng(1)
X = rng.normal(size=(4000, 3))
y = (X[:, 0] + 0.8 * X[:, 1] * X[:, 2] + rng.normal(0, 0.5, 4000) > 0).astype(int)
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.25, random_state=0)

class Registry:
    """Minimale Modell-Registry: Versionen mit Metadaten, dazu Aliase."""
    def __init__(self):
        self.versionen: dict[int, dict] = {}
        self.alias: dict[str, int] = {}

    def registrieren(self, modell, metriken: dict) -> int:
        nr = len(self.versionen) + 1
        self.versionen[nr] = {"modell": modell, "metriken": metriken}
        return nr

    def setze_alias(self, alias: str, version: int) -> None:
        self.alias[alias] = version

    def lade(self, version: int):
        return self.versionen[version]["modell"]

reg = Registry()
v1 = reg.registrieren(LogisticRegression().fit(X_tr, y_tr), {})
v2 = reg.registrieren(GradientBoostingClassifier(random_state=0).fit(X_tr, y_tr), {})
for nr in (v1, v2):
    acc = round(float(reg.lade(nr).score(X_te, y_te)), 3)
    reg.versionen[nr]["metriken"]["accuracy"] = acc
    print(f"Version {nr}: {type(reg.lade(nr)).__name__:28s} accuracy {acc}")

reg.setze_alias("production", v1)

def vorhersage(anfrage_id: str, merkmale, canary_anteil: float = 0.0):
    """(Version, Vorhersage); Canary per Hash der Anfrage-ID, daher stabil."""
    version = reg.alias["production"]
    if "canary" in reg.alias:
        bucket = int(hashlib.sha256(anfrage_id.encode()).hexdigest(), 16) % 100
        if bucket < canary_anteil * 100:
            version = reg.alias["canary"]
    x = np.asarray(merkmale).reshape(1, -1)
    return version, int(reg.lade(version).predict(x)[0])

reg.setze_alias("canary", v2)
verteilung = {v1: 0, v2: 0}
for i in range(1000):
    version, _ = vorhersage(f"req-{i}", X_te[i % len(X_te)], canary_anteil=0.1)
    verteilung[version] += 1
print("Anfragen je Version bei 10 % Canary:", verteilung)

# Shadow-Vergleich: beide Versionen auf denselben Anfragen
p1 = reg.lade(v1).predict(X_te)
p2 = reg.lade(v2).predict(X_te)
print(f"Übereinstimmung v1/v2: {np.mean(p1 == p2):.3f}")

# Rollback ist ein Alias-Wechsel, kein Neu-Deployment
reg.setze_alias("production", v2)
print("production ->", reg.alias["production"])
reg.setze_alias("production", v1)
print("Rollback: production ->", reg.alias["production"])

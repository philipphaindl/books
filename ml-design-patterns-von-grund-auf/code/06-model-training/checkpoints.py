"""Pattern 12: Checkpoints, Wiederaufnahme, Early Stopping, Fine-Tuning ab Checkpoint.

Ausführen:  uv run --with scikit-learn --with numpy python checkpoints.py
"""
import json
import tempfile
import warnings
from pathlib import Path

import joblib
import numpy as np
from sklearn.datasets import load_digits
from sklearn.exceptions import ConvergenceWarning
from sklearn.metrics import log_loss
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier

warnings.filterwarnings("ignore", category=ConvergenceWarning)

X, y = load_digits(return_X_y=True)
X = X / 16.0                                              # Pixelwerte auf 0..1
X_tr, X_rest, y_tr, y_rest = train_test_split(X, y, train_size=300, stratify=y, random_state=0)
X_va, X_neu, y_va, y_neu = train_test_split(X_rest, y_rest, train_size=600, stratify=y_rest, random_state=0)
# später eintreffende Daten (Fine-Tuning)
X_neu, y_neu = X_neu[:300], y_neu[:300]
KLASSEN = np.arange(10)


def neues_modell():
    return MLPClassifier(hidden_layer_sizes=(256,), solver="adam", learning_rate_init=0.003,
                         batch_size=50, random_state=0)


def eine_epoche(modell, X, y):
    # genau ein Durchlauf über die Daten
    modell.partial_fit(X, y, classes=KLASSEN)


def val_loss(modell):
    return log_loss(y_va, modell.predict_proba(X_va), labels=KLASSEN)


ordner = Path(tempfile.mkdtemp(prefix="ckpt_"))
latest, best = ordner / "latest.joblib", ordner / "best.joblib"

# 1) Training mit Checkpoints und Early Stopping ----------------------------------------
modell = neues_modell()
verlauf = {"epoche": [], "train": [], "val": []}
bester_loss, bester_epoche, ohne_besserung = np.inf, 0, 0
GEDULD, MIN_DELTA, MAX_EPOCHEN = 10, 0.001, 150
for epoche in range(1, MAX_EPOCHEN + 1):
    eine_epoche(modell, X_tr, y_tr)
    lv = val_loss(modell)
    lt = log_loss(y_tr, modell.predict_proba(X_tr), labels=KLASSEN)
    verlauf["epoche"].append(epoche)
    verlauf["train"].append(round(lt, 4))
    verlauf["val"].append(round(lv, 4))
    # jederzeit wiederaufnehmbar
    joblib.dump(modell, latest)
    if lv < bester_loss - MIN_DELTA:
        bester_loss, bester_epoche, ohne_besserung = lv, epoche, 0
        joblib.dump(modell, best)                         # bester Stand bisher
    else:
        ohne_besserung += 1
    if ohne_besserung >= GEDULD:
        break
verlauf["best"], verlauf["stop"] = bester_epoche, epoche
Path("checkpoints_kurve.json").write_text(json.dumps(verlauf))

modell_best = joblib.load(best)
print("1) Early Stopping")
for e in (1, 5, 10, 20, 30, 40, 60, 80, epoche):
    if e <= epoche:
        i = e - 1
        print(f"   Epoche {e:3d}: Loss Training={verlauf['train'][i]:.4f}  Validierung={verlauf['val'][i]:.4f}")
print(f"   Abbruch nach Epoche {epoche}, bester Stand in Epoche {bester_epoche} "
      f"(Validierungs-Loss {bester_loss:.4f})")
print(f"   Genauigkeit Validierung: letzter Stand={modell.score(X_va, y_va):.3f}  "
      f"bester Checkpoint={modell_best.score(X_va, y_va):.3f}")
print(f"   Größe eines Checkpoints: {best.stat().st_size / 1024:.0f} KiB")

# 2) Absturz und Wiederaufnahme ----------------------------------------------------------
durchgehend = neues_modell()
for _ in range(40):
    eine_epoche(durchgehend, X_tr, y_tr)

unterbrochen = neues_modell()
for _ in range(25):
    eine_epoche(unterbrochen, X_tr, y_tr)
# letzter Checkpoint vor dem Absturz
joblib.dump(unterbrochen, ordner / "absturz.joblib")
del unterbrochen                                          # Prozess ist weg
# Neustart: Zustand zurückholen
wieder = joblib.load(ordner / "absturz.joblib")
for _ in range(15):
    eine_epoche(wieder, X_tr, y_tr)

gleich = all(np.array_equal(a, b) for a, b in zip(durchgehend.coefs_, wieder.coefs_))
print("\n2) Absturz nach 25 Epochen, Neustart aus Checkpoint, 15 weitere Epochen")
print("   gegen 40 Epochen am Stück:")
print(f"   Gewichte bitgleich: {gleich}   Genauigkeit: {durchgehend.score(X_va, y_va):.3f} / {wieder.score(X_va, y_va):.3f}")

# 3) warm_start: weitermachen, aber ohne Optimierer-Zustand ------------------------------
am_stueck = MLPClassifier(hidden_layer_sizes=(256,), learning_rate_init=0.003, batch_size=50,
                          max_iter=40, random_state=0).fit(X_tr, y_tr)
geteilt = MLPClassifier(hidden_layer_sizes=(256,), learning_rate_init=0.003, batch_size=50,
                        max_iter=20, warm_start=True, random_state=0)
# zweiter Aufruf startet bei den alten Gewichten
geteilt.fit(X_tr, y_tr); geteilt.fit(X_tr, y_tr)
gleich_ws = all(np.array_equal(a, b) for a, b in zip(am_stueck.coefs_, geteilt.coefs_))
print("\n3) fit(max_iter=40) gegen zweimal fit(max_iter=20, warm_start=True)")
print(f"   Gewichte bitgleich: {gleich_ws}   Genauigkeit: {am_stueck.score(X_va, y_va):.3f} / {geteilt.score(X_va, y_va):.3f}")

# 4) Fine-Tuning ab Checkpoint ------------------------------------------------------------
ft = joblib.load(best)
vorher = ft.score(X_va, y_va)
for _ in range(10):
    # nur auf den neu eingetroffenen Daten
    eine_epoche(ft, X_neu, y_neu)
print("\n4) Fine-Tuning des besten Checkpoints mit 300 neuen Beispielen (10 Epochen)")
print(f"   Genauigkeit Validierung: vorher={vorher:.3f}  nachher={ft.score(X_va, y_va):.3f}")

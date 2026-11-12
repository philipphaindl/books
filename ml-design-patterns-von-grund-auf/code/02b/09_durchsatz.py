"""Warum Batches? Durchsatz eines Forward Passes in Abhängigkeit von der Batch-Größe (auf diesem Rechner gemessen)."""
import platform
import time

import numpy as np

from mlp import speichere

rng = np.random.default_rng(0)
groessen = [1024, 1024, 1024, 1024]
W = [rng.normal(size=(m, n)).astype(np.float32) for m, n in zip(groessen[:-1], groessen[1:])]
flops_je_beispiel = sum(2 * m * n for m, n in zip(groessen[:-1], groessen[1:]))  # multiplizieren + addieren
gewichte_mb = sum(w.nbytes for w in W) / 1e6
print(f"{platform.machine()}, numpy {np.__version__}; Netz 3 x (1024 x 1024), {gewichte_mb:.1f} MB Gewichte, {flops_je_beispiel / 1e6:.1f} MFLOP je Beispiel")


def forward(x):
    for w in W:
        x = np.maximum(x @ w, 0)
    return x


ergebnis = []
print("Batch | Zeit je Aufruf | Beispiele/s | GFLOP/s")
for batch in (1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024):
    x = rng.normal(size=(batch, 1024)).astype(np.float32)
    wdh = max(5, 4000 // batch)  # Wiederholungen je Messung
    forward(x)  # Aufwärmen
    zeiten = []
    for _ in range(15):  # 15 Messungen, die kleinste zählt (am wenigsten von anderen Prozessen gestört)
        t0 = time.perf_counter()
        for _ in range(wdh):
            forward(x)
        zeiten.append((time.perf_counter() - t0) / wdh)
    beste = min(zeiten)
    bps, gf = batch / beste, batch * flops_je_beispiel / beste / 1e9
    ergebnis.append({"batch": batch, "bps": round(bps), "gflops": round(gf, 1)})
    print(f"{batch:5d} | {beste * 1e6:10.1f} µs | {bps:11.0f} | {gf:7.1f}")
speichere("durchsatz", ergebnis)

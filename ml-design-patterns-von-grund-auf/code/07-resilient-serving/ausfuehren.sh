#!/bin/sh
# Führt alle Beispiele dieses Ordners aus (Reihenfolge wichtig: zuerst das Modell exportieren).
cd "$(dirname "$0")" || exit 1
export OMP_NUM_THREADS=1
uv run --with scikit-learn --with pandas --with numpy python modell_exportieren.py > modell_exportieren.out.txt
uv run --with scikit-learn --with pandas --with fastapi --with httpx python serving_test.py > serving_test.out.txt
uv run --with scikit-learn --with pandas --with numpy python batch_serving.py > batch_serving.out.txt
uv run --with scikit-learn --with numpy --with scipy python drift.py > drift.out.txt
uv run --with scikit-learn --with numpy python two_phase.py > two_phase.out.txt
uv run --with scikit-learn --with pandas --with numpy python keyed_predictions.py > keyed_predictions.out.txt

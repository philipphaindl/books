#!/bin/sh
# Führt alle Beispiele dieses Ordners aus (Ausgaben nach <name>.out.txt, Diagrammdaten als JSON).
cd "$(dirname "$0")" || exit 1
export OMP_NUM_THREADS=1
uv run --with numpy python trainingsschleife.py > trainingsschleife.out.txt
uv run --with scikit-learn --with numpy python useful_overfitting.py > useful_overfitting.out.txt
uv run --with scikit-learn --with numpy python checkpoints.py > checkpoints.out.txt
uv run --with scikit-learn --with numpy python transfer_learning.py > transfer_learning.out.txt
uv run --with numpy python distribution_strategy.py > distribution_strategy.out.txt
uv run --with scikit-learn --with numpy python hyperparameter_tuning.py > hyperparameter_tuning.out.txt

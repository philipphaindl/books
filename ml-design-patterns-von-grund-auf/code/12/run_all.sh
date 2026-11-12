#!/bin/sh
# Alle Skripte der Fallstudie der Reihe nach ausführen; die Ausgaben landen in out/.
# Aufruf im Ordner code/12:  sh run_all.sh
set -e
cd "$(dirname "$0")"
mkdir -p out
for s in 01_heuristik 02_naives_notebook 03_split 04_rebalancing 05_transform 06_erklaerung 07_fairness 08_monitoring; do
  uv run --with scikit-learn --with pandas --with numpy python $s.py | tee out/$s.txt
done

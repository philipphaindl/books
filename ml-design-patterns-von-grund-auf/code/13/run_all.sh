#!/bin/sh
# Fuehrt alle Skripte der Fallstudie B aus und schreibt die Ausgaben nach out/.
# OMP_NUM_THREADS=1: auf stark ausgelasteten Rechnern vermeidet das Wartezeiten der Thread-Pools.
cd "$(dirname "$0")" || exit 1
export OMP_NUM_THREADS=1
for s in "$@"; do
  uv run --with scikit-learn --with pandas --with numpy python "$s.py" > "out/$s.txt" 2>&1 || echo "FEHLER in $s"
done

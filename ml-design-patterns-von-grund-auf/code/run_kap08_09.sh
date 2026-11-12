#!/bin/sh
# Führt alle Beispiele der Kapitel 8 und 9 aus und legt die Ausgaben in out/ ab.
cd "$(dirname "$0")"
mkdir -p 08-reproducibility/out 09-responsible-ai/out
for f in 08-reproducibility/2*.py 09-responsible-ai/*.py; do
  d=$(dirname "$f"); b=$(basename "$f" .py)
  uv run --with scikit-learn --with pandas --with numpy --with fairlearn python "$f" > "$d/out/$b.txt" 2>&1
  echo "$f -> $?"
done

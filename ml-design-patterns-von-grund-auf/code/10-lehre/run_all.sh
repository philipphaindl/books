#!/bin/sh
# Führt alle Beispiele des Kapitels 10 aus und legt die echten Ausgaben in out/ ab.
cd "$(dirname "$0")"
mkdir -p out
for f in "$@"; do
  uv run --with scikit-learn --with pandas --with numpy python "$f.py" > "out/$f.txt" 2>&1
done

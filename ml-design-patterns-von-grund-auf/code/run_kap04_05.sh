#!/bin/sh
# Führt alle Beispielskripte aus und speichert die Ausgabe unter ausgabe/ (das Handbuch liest diese Dateien).
# Aufruf im Ordner code/:  sh run_all.sh 04-data-representation 05-problem-representation
PY="${PY:-uv run --quiet --with scikit-learn --with pandas --with numpy --with imbalanced-learn python}"
for d in "$@"; do
  (cd "$d" && for f in [0-9]*.py; do PYTHONUNBUFFERED=1 $PY "$f" > "ausgabe/${f%.py}.txt" 2>&1; echo "fertig: $d/$f"; done)
done

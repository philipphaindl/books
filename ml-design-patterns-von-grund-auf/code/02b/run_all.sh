#!/bin/sh
# Führt alle Skripte von Kapitel 2b aus und schreibt die Ausgaben nach out/ (Ausführen im Ordner code/02b).
cd "$(dirname "$0")"
for f in 01_neuron 02_spirale 03_lernrate 04_regularisierung 05_embedding_lookup 06_skipgram 08_checkpoint_parallel 09_durchsatz 10_attention; do
  uv run --with numpy python $f.py > out/$f.out.txt
done
uv run --with numpy --with scikit-learn python 07_transfer.py > out/07_transfer.out.txt

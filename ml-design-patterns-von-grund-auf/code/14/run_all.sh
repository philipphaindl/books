#!/bin/bash
cd "$(dirname "$0")"
for f in 01_daten 02_hashed_feature 03_embeddings 04_feature_cross 05_multimodal 06_cascade 07_feature_store_leck 08_gesamt; do
  uv run --with scikit-learn --with pandas --with numpy python $f.py > ausgabe/$f.tmp 2>&1 && mv ausgabe/$f.tmp ausgabe/$f.txt || echo FAIL $f
done
uv run --with scikit-learn --with pandas --with numpy python trainiere_modelle.py > ausgabe/09_trainiere_modelle.txt 2>&1 || echo FAIL train
uv run --with scikit-learn --with pandas --with numpy --with fastapi --with httpx python test_dienst.py > ausgabe/09_dienst_test.tmp 2>&1 && mv ausgabe/09_dienst_test.tmp ausgabe/09_dienst_test.txt || echo FAIL test
echo FERTIG

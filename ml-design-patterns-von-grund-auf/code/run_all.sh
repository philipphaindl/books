#!/bin/sh
# Führt alle Code-Beispiele der Kapitel 2 und 4 bis 10 aus. Ein Befehl, nichts vorab installieren
# (nur uv, https://docs.astral.sh/uv/ ):
#
#   sh code/run_all.sh                         # alle Kapitel
#   sh code/run_all.sh 05-problem-representation 09-responsible-ai   # nur diese Ordner
#
# Die Skripte laufen in einer Kopie in einem temporären Ordner, damit die Dateien nicht
# überschrieben werden, die das Handbuch beim Bauen liest. Die Ausgaben landen in
# code/_lauf/<ordner>/<skript>.txt. Zu jedem Skript steht, ob die Ausgabe mit der im Handbuch
# verwendeten übereinstimmt. Abweichungen sind bei Skripten mit Zeitmessung (batch_serving.py)
# erwartet, ebenso beim absichtlich zufälligen hash() in 02_hashed_feature.py; bei allen anderen ist der Seed fixiert und die Ausgabe sollte gleich sein.
# Rückgabewert 0, wenn alle Skripte fehlerfrei durchlaufen.

HIER=$(cd "$(dirname "$0")" && pwd)
ERGEBNIS="$HIER/_lauf"
ARBEIT=$(mktemp -d "${TMPDIR:-/tmp}/ml-patterns-code.XXXXXX") || exit 1
trap 'rm -rf "$ARBEIT"' EXIT

export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 PYTHONUNBUFFERED=1
PY="uv run --quiet --with numpy --with pandas --with scipy --with scikit-learn --with imbalanced-learn --with fairlearn --with fastapi --with httpx --with joblib python"

ALLE="02 04-data-representation 05-problem-representation 06-model-training 07-resilient-serving 08-reproducibility 09-responsible-ai 10-lehre"
ORDNER="${*:-$ALLE}"

# Skripte je Ordner; wo die Reihenfolge zählt (07: zuerst das Modell exportieren), steht sie hier fest.
skripte() {
  case "$1" in
    06-model-training) echo trainingsschleife distribution_strategy checkpoints useful_overfitting transfer_learning hyperparameter_tuning ;;
    07-resilient-serving) echo modell_exportieren serving_test batch_serving drift two_phase keyed_predictions ;;
    10-lehre) echo accuracy_und_imbalance feature_cross_xor hashing_vs_embedding ml_in_20_minuten split_und_version ;;
    *) (cd "$HIER/$1" && for f in [0-9]*.py; do basename "$f" .py; done) ;;
  esac
}

# Gespeicherte Handbuch-Ausgabe zu einem Skript (je Kapitel liegt sie an anderer Stelle)
gespeichert() {
  for p in "$HIER/$1/ausgabe/$2.txt" "$HIER/$1/out/$2.txt" "$HIER/$1/$2.out.txt"; do
    [ -f "$p" ] && { echo "$p"; return; }
  done
}

mkdir -p "$ERGEBNIS"
for d in $ORDNER; do
  [ -d "$HIER/$d" ] || { echo "Ordner fehlt: $d" >&2; exit 2; }
  mkdir -p "$ARBEIT/$d" "$ERGEBNIS/$d"
  cp -R "$HIER/$d/." "$ARBEIT/$d/"
done

ok=0; fehler=0; abweichend=0
for d in $ORDNER; do
  for s in $(skripte "$d"); do
    aus="$ERGEBNIS/$d/$s.txt"
    if (cd "$ARBEIT/$d" && $PY "$s.py") > "$aus" 2>&1; then
      ok=$((ok + 1)); status="ok"
      alt=$(gespeichert "$d" "$s")
      if [ -n "$alt" ]; then
        if cmp -s "$alt" "$aus"; then status="ok, Ausgabe gleich wie im Handbuch"
        else status="ok, Ausgabe weicht ab (Zeitmessung oder hash()?)"; abweichend=$((abweichend + 1)); fi
      fi
    else
      fehler=$((fehler + 1)); status="FEHLER, siehe $aus"
    fi
    printf '%-52s %s\n' "$d/$s.py" "$status"
  done
done

echo
echo "$ok Skripte fehlerfrei, $fehler mit Fehler, $abweichend mit abweichender Ausgabe. Ausgaben unter $ERGEBNIS"
[ "$fehler" -eq 0 ]

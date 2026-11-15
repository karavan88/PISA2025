#!/bin/bash
# The price of progress -- entry point. Run from anywhere.
#   run_all.sh report                 verify the approved snapshot, redraw figures, render the PDF. Fits no models.
#   run_all.sh estimate <new_dir>     run every estimation step into a NEW directory (must not exist). 04_output is not touched.
#   run_all.sh compare <new_dir>      compare <new_dir> with 04_output, file by file.
#   run_all.sh test                   check the cutoff estimators against direct 2SLS on simulated data. Reads no data, writes nothing.
# After a deliberate re-estimation: compare, record the reason in 01_code/README.md, copy the new CSVs into 04_output,
# then promote them with: python3 05_papers/04_price_of_progress/01_code/snapshot.py refresh --replace
set -e; cd "$(dirname "$0")/../../.."
P=05_papers/04_price_of_progress; export RENV_PROJECT="$PWD"
case "$1" in
  report)
    python3 $P/01_code/snapshot.py check
    Rscript $P/01_code/10_figures.R
    quarto render $P/03_manuscript/price_of_progress.qmd ;;
  estimate)
    OUT="$2"; [ -n "$OUT" ] || { echo "usage: run_all.sh estimate <new_dir>"; exit 2; }
    [ -e "$OUT" ] && { echo "Refusing to write into an existing directory: $OUT"; exit 1; }
    mkdir -p "$OUT/logs"; OUT="$(cd "$OUT" && pwd)"
    printf '{"utc":"%s","git_commit":"%s","r":"%s"}\n' "$(date -u +%FT%TZ)" "$(git rev-parse HEAD)" "$(Rscript -e 'cat(R.version.string)' 2>/dev/null)" > "$OUT/run.json"
    for s in 08_cutoff 09_extras; do echo "$(date +%T) $s"; PAPER_OUT="$OUT" Rscript $P/01_code/$s.R > "$OUT/logs/$s.log" 2>&1 || { echo "FAILED: $OUT/logs/$s.log"; exit 1; }; done
    echo "Done: $OUT  (next: run_all.sh compare $OUT)" ;;
  compare)
    Rscript 02_scripts/02_legacy/wellbeing_shared/compare_outputs.R "$2" $P/04_output ;;
  test)
    Rscript $P/01_code/test_tsls.R ;;
  *) sed -n 2,8p "$0"; exit 2 ;;
esac

#!/bin/bash
# The cost of resilience -- entry point. Run from anywhere.
#   run_all.sh report                 verify the approved snapshot, redraw figures, render the report PDF. Fits no models.
#   run_all.sh paper                  verify the approved snapshot, redraw the country figures, render the paper draft. Fits no models.
#   run_all.sh estimate <new_dir>     run every estimation step into a NEW directory (must not exist). 04_output is not touched.
#   run_all.sh compare <new_dir>      compare <new_dir> with 04_output, file by file.
# After a deliberate re-estimation: compare, record the reason in 01_code/README.md, copy the new CSVs into 04_output,
# then promote them with: python3 05_papers/03_resilience_cost/01_code/snapshot.py refresh --replace
set -e; cd "$(dirname "$0")/../../.."
P=05_papers/03_resilience_cost; export RENV_PROJECT="$PWD"
case "$1" in
  report)
    python3 $P/01_code/snapshot.py check
    Rscript $P/01_code/10_figures.R
    quarto render $P/03_manuscript/cost_of_resilience.qmd ;;
  paper)
    python3 $P/01_code/snapshot.py check
    Rscript $P/01_code/11_figures_paper.R
    quarto render $P/03_manuscript/cost_of_resilience_paper.qmd ;;
  estimate)
    OUT="$2"; [ -n "$OUT" ] || { echo "usage: run_all.sh estimate <new_dir>"; exit 2; }
    [ -e "$OUT" ] && { echo "Refusing to write into an existing directory: $OUT"; exit 1; }
    mkdir -p "$OUT/logs"; OUT="$(cd "$OUT" && pwd)"
    printf '{"utc":"%s","git_commit":"%s","r":"%s"}\n' "$(date -u +%FT%TZ)" "$(git rev-parse HEAD)" "$(Rscript -e 'cat(R.version.string)' 2>/dev/null)" > "$OUT/run.json"
    for s in 02_describe 03_response_style 04_gap 05_mechanism 06_oriv 07_curiosity 08_threshold 09_focal 12_benchmark 15_regions 13_forest 14_cutoff; do echo "$(date +%T) $s"; PAPER_OUT="$OUT" Rscript $P/01_code/$s.R > "$OUT/logs/$s.log" 2>&1 || { echo "FAILED: $OUT/logs/$s.log"; exit 1; }; done
    # robustness: achievement as a composite weighted towards reading (1/2 reading, 1/4 mathematics, 1/4 science); main steps only
    mkdir -p "$OUT/robust_achw/logs"
    for s in 03_response_style 04_gap 12_benchmark; do echo "$(date +%T) $s (weighted composite)"; PAPER_ACH=ACHW PAPER_OUT="$OUT/robust_achw" Rscript $P/01_code/$s.R > "$OUT/robust_achw/logs/$s.log" 2>&1 || { echo "FAILED: $OUT/robust_achw/logs/$s.log"; exit 1; }; done
    # robustness: the gap with achievement measured by science, or by the simple average of the three domains (step 4 only)
    for x in SCIE ACH; do lx=$(echo $x | tr A-Z a-z); mkdir -p "$OUT/robust_$lx/logs"; echo "$(date +%T) 04_gap ($x)"; PAPER_ACH=$x PAPER_OUT="$OUT/robust_$lx" Rscript $P/01_code/04_gap.R > "$OUT/robust_$lx/logs/04_gap.log" 2>&1 || { echo "FAILED: $OUT/robust_$lx/logs/04_gap.log"; exit 1; }; done
    echo "Done: $OUT  (next: run_all.sh compare $OUT)" ;;
  compare)
    Rscript 02_scripts/02_legacy/wellbeing_shared/compare_outputs.R "$2" $P/04_output ;;
  *) sed -n 2,8p "$0"; exit 2 ;;
esac

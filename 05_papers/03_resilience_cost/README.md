# 03 — The cost of resilience

**Full title:** The cost of resilience: Life satisfaction among disadvantaged high achievers in PISA 2025.

**Target journal:** Child Indicators Research. **Companion paper:** [04 — The price of progress](../04_price_of_progress/). The two papers were one project (`resilwb`) until 14 November 2026 and are now maintained separately, each in its own working session.

## Files

- `03_manuscript/cost_of_resilience.qmd`: report source (problem statement, hypotheses, tests, results). The rendered PDF is local.
- `01_code/`: estimation steps, figures, reporting helpers, `snapshot.py`, `run_all.sh`; see its README for the analysis notes.
- `02_results/snapshot/` + `snapshot_manifest.json`: the approved results the report reads (CSVs local, manifest tracked). `02_results/figs/`: figures. The cutoff-design estimate and one descriptive table are snapshots of paper 04's output.
- `04_output/`: local estimates and logs. `05_archive/`: superseded snapshots. `06_submissions/`: submission artifacts.

## Reproduction

```sh
bash 05_papers/03_resilience_cost/01_code/run_all.sh report                 # verify snapshot, redraw figures, render PDF; fits no models
bash 05_papers/03_resilience_cost/01_code/run_all.sh estimate /abs/new/dir  # full re-estimation into a new directory
bash 05_papers/03_resilience_cost/01_code/run_all.sh compare /abs/new/dir   # against 04_output
```

## Reproducibility status

Not certified against the central harmonization pipeline. Data preparation is the frozen legacy layer in `02_scripts/02_legacy/wellbeing_shared` (its own provider read and variable construction); it must be migrated into `02_scripts/01_harmonization` before fresh processing is treated as maintained. The snapshot holds the estimates of 14 November 2026. When the project was split, every estimation step was re-run from its new location into a scratch directory and compared with those estimates; the outcome is recorded in `02_scripts/02_legacy/wellbeing_shared/README.md`.

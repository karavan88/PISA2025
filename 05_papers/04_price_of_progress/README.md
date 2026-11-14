# 04 — The price of progress

**Full title:** The price of progress: Achievement, school progression and adolescent life satisfaction in PISA 2025.

**Target journal:** Economics of Education Review. **Companion paper:** [03 — The cost of resilience](../03_resilience_cost/). The two papers were one project (`resilwb`) until 14 November 2026 and are now maintained separately, each in its own working session.

## Files

- `03_manuscript/price_of_progress.qmd`: report source (problem statement, hypotheses, tests, results). The rendered PDF is local.
- `01_code/`: estimation steps, figures, reporting helpers, `snapshot.py`, `run_all.sh`; see its README for the analysis notes.
- `02_results/snapshot/` + `snapshot_manifest.json`: the approved results the report reads (CSVs local, manifest tracked). `02_results/figs/`: figures. The two-rater estimates are a snapshot of paper 03's output. The 20 cutoff systems are defined in `01_code/systems.R`.
- `04_output/`: local estimates and logs. `05_archive/`: superseded snapshots. `06_submissions/`: submission artifacts.

## Reproduction

```sh
bash 05_papers/04_price_of_progress/01_code/run_all.sh report                 # verify snapshot, redraw figures, render PDF; fits no models
bash 05_papers/04_price_of_progress/01_code/run_all.sh estimate /abs/new/dir  # full re-estimation into a new directory
bash 05_papers/04_price_of_progress/01_code/run_all.sh compare /abs/new/dir   # against 04_output
```

## Reproducibility status

Not certified against the central harmonization pipeline. Data preparation is the frozen legacy layer in `02_scripts/02_legacy/wellbeing_shared` (its own provider read and variable construction); it must be migrated into `02_scripts/01_harmonization` before fresh processing is treated as maintained. The snapshot holds the estimates of 14 November 2026. When the project was split, every estimation step was re-run from its new location into a scratch directory and compared with those estimates; the outcome is recorded in `02_scripts/02_legacy/wellbeing_shared/README.md`.

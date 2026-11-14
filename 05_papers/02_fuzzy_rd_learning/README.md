# 02 — Grade Gain Report — what a year of schooling adds at age 15 in every eligible PISA 2025 system

## Report and coverage

Source: [report.qmd](03_manuscript/report.qmd). The local rendered report is `03_manuscript/report.html`.

The study estimates the gain associated with an additional school year using school-entry cutoffs, covering science, mathematics, reading, and socio-emotional outcomes. The latest saved eligibility audit (October 14, 2026) screens 83 systems, identifies 44 cutoff candidates, and retains 36 systems. Saved estimates cover those same 36 systems, including explicitly flagged cohort-edge cases.

## Files and reproduction status

- `01_code/`: preparation, estimation, and summary scripts.
- `02_results/`: reserved for approved results snapshots.
- `03_manuscript/`: report source and local rendering.
- `04_output/`: local estimates, eligibility checks, and logs.
- `05_archive/` and `06_submissions/`: local historical and submission artifacts.

This is the active broad-coverage fuzzy-RD project. The later 14-system same-school extension is preserved in `06_scoping/07_schoolgain`.

## Reproduction

Preparation and design screening now run centrally. See [data placement](../../01_data/README.md) and [complete reproduction instructions](../../00_documentation/REPRODUCE.md).

```sh
python3 02_scripts/00_tools/build_shared.py
python3 05_papers/02_fuzzy_rd_learning/01_code/run_all.py estimate --output /absolute/new/results/directory
python3 05_papers/02_fuzzy_rd_learning/01_code/run_all.py report --results /absolute/new/results/directory
```

The result directory must not exist before estimation. Estimation never replaces the historical bundle. Reporting reads the chosen completed run and fits no models.

**Correction identified during reproduction:** the legacy 2SLS function misaligned fitted grade values when an outcome was missing. This affects skill-outcome IV estimates, not the complete achievement outcomes. The corrected function uses the identical outcome-complete sample in both stages and is tested against the direct matrix 2SLS estimator. Historical results remain in `02_results`; `report --historical` is only for explicit inspection of that old version. New estimates include a row-by-row historical comparison.

## Verified local run (2026-11-14)

The corrected run is `04_output/corrected_20261114/`; its `historical_comparison.csv` records every coefficient change. All 36 systems completed. Achievement and LSDV estimates are unchanged; 1,626 skill-outcome IV coefficient entries change after correcting alignment. The report at `03_manuscript/report.html` was rendered from this corrected run. These generated files are local, not in Git.

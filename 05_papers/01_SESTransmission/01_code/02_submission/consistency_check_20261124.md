# Final consistency check — 24 November 2026

Submission snapshot: `01_ijed_20261124_v15`.

The manuscript and appendix were rendered from current sources and saved results. No raw estimation was rerun.

## Numerical checks

All 657 reporting/data checks passed. Independent checks of saved country estimates confirmed the following positive counts. The second column excludes the first: “more” means 0.05 ≤ p < 0.10.

| Quantity | p < 0.05 | More at p < 0.10 |
|---|---:|---:|
| Joint skills pathway | 52 | 7 |
| Sorting increment | 27 | 9 |
| Curiosity | 46 | 5 |
| Perseverance | 23 | 4 |
| Cognitive adaptability | 8 | 1 |
| Enjoyment of problem solving | 7 | 0 |
| Help seeking | 7 | 5 |
| Goal setting | 4 | 1 |
| Gap reduction | 57 | 5 |
| Total between-minus-within contribution | 46 | 1 |
| Skills between-minus-within contribution | 14 | 8 |
| Positive gap reduction across main and all 3 alternatives | 56 | 4 |

BH-adjusted results are identified separately at a 5% false discovery rate. Stars and symbols retain their documented thresholds; confidence bars remain 95% intervals.

## Exhibits and text

All 19 retained appendix tables and all 3 appendix figures are referenced in the manuscript. Table references match the sample, measurement, mediation, decomposition, equalization, and robustness sections. Figure notes were checked against plotting code, including the F7 subtraction and interval construction. Both PDFs pass text integrity checks without literal figure-note commands.

An unescaped percent sign had truncated the abstract in prior packages. The source is corrected. Packaging now checks the rendered abstract's final sentence and key results, in addition to successful compilation. The v15 abstract was inspected after packaging.

## Repository checks

`check_repo.py`, Python compilation of the package builder, and `git diff --check` passed. Data, aggregate CSVs, rendered PDFs, and previous local submission snapshots remain ignored. Other projects' changes are excluded from this commit.

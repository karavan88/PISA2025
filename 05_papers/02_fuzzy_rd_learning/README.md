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

The historical pipeline has not yet been migrated to central harmonization or certified end to end in the new layout. Do not run its legacy driver as a certified reproduction command. Shared-variable construction must be moved centrally before fresh estimation. No analysis was rerun during this folder reorganization; the saved estimates and original eligibility rules are preserved.

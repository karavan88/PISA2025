# 01 — Do socio-emotional skills transmit socio-economic (dis)advantage? Evidence from PISA 2025 data

Active manuscript: `03_manuscript/ijed_ses_seg_rev2.qmd`.
Topically organized appendix with tables, figures, and model-specification snippets: `03_manuscript/ijed_ses_seg_supplement_rev2.qmd`.
The study has 67 SES systems, 62 supplementary deprivation systems, and 6 skills.

## Folders

- `01_code/`: models, diagnostics, figure/report functions, and pipeline entry point.
- `02_results/`: local frozen aggregate CSV snapshot; only its manifest is in Git.
- `03_manuscript/`: active sources, bibliography, and citation style; PDFs are local.
- `04_output/`: generated artifacts, country checkpoints, draws, and run logs.
- `05_archive/`: earlier versions and review materials, retained locally.
- `06_submissions/`: local frozen journal packages when prepared.

## Commands

```sh
python3 02_scripts/00_tools/build_shared.py
python3 05_papers/01_SESTransmission/01_code/run_all.py report
python3 05_papers/01_SESTransmission/01_code/run_all.py check
python3 05_papers/01_SESTransmission/01_code/run_all.py draw-check
```

`report` validates the frozen aggregate snapshot, builds figures, checks accounting
identities and headline counts, then renders the 2 PDFs. It needs the local
02_results snapshot and installed tools, but no pupil records or regression draws.
`check` omits PDF rendering; `draw-check` additionally requires saved draws and
parental-model fits. Typical reporting takes minutes; no runtime promise is made
for a new machine.

`python3 05_papers/01_SESTransmission/01_code/run_all.py estimate --fresh` explicitly
runs the central build, original multilevel bootstrap pipeline, parental-control
comparison, and counterfactual alternatives. This is expensive (499 resamples,
10 plausible values, country-specific jobs). It is not run by report/check.
The retained historical snapshot supplies country metadata and reference
eligibility. Fresh-raw end-to-end re-estimation has not been validated during
this migration. Keep a backup and use fresh checkpoints when specifications change.

Shared inputs are under `03_outputs/01_harmonized/`. No maintained paper script
reads SPSS files. Local code estimates models and forms estimands, not alternative
versions of the shared variables. Historical render scripts remain for provenance;
use run_all.py for the maintained reporting workflow.

## Reproduction verification

See the [environment, data, and command guide](../../00_documentation/REPRODUCE.md). The 2026-11-14 audit rebuilt all 157 prepared inputs without numerical changes, refit all 157 main point models, and reproduced 5 seeded bootstrap draws for each Korean exposure. Reporting rebuilt both PDFs under renv. This does not claim a new full 499-draw rerun of every main and alternative model. Fresh estimation now includes the previously missing evidence-classification postprocessor; historical pilot checks are optional. Use `report --current-results` after a successful `estimate --fresh` to avoid restoring the frozen snapshot over new estimates.

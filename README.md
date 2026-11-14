# PISA2025

Garen Avanesian's PISA research repository. Shared harmonization runs centrally;
paper folders consume prepared inputs and perform analysis. The active migrated
paper is **01_SESTransmission** (IJED draft). Other projects are registered as legacy,
not certified as reproducing through the new shared build.

## Numbered layout

- `00_documentation/`: variable definitions, provenance, and migration record.
- `01_data/`: local provider files. No data are versioned.
- `02_scripts/00_tools/`: repository checks and shared-build entry point.
- `02_scripts/01_harmonization/`: the authoritative current variable construction.
- `03_outputs/01_harmonized/`: local shared data and hash-based build manifest.
- `04_manuscripts/`: active shortcuts `ijed_ses_seg`, `fuzzy_rd_learning` (gradegain), and `resilwb`; inactive drafts are under `00_archived/`.
- `05_papers/`: numbered paper folders; see `05_papers/REGISTRY.md`.
- `06_scoping/`: new ideas before they become papers.
- `07_archive/`: local historical material.

The active paper contains `01_code/`, `02_results/`, `03_manuscript/`,
`04_output/`, `05_archive/`, and `06_submissions/`. Earlier numbered paths remain
as local compatibility links so existing PDF links continue to work.

## Reproduction on this machine

Run these commands from the repository root (Python entry points also resolve it
when launched elsewhere):

```sh
python3 02_scripts/00_tools/build_shared.py
python3 05_papers/01_SESTransmission/01_code/run_all.py report
python3 05_papers/01_SESTransmission/01_code/run_all.py draw-check
python3 02_scripts/00_tools/check_repo.py
```

The central build compares source, code, and product hashes and skips an unchanged
build. `report` reconstructs figures and PDFs from the checked local aggregate
snapshot; it does not harmonize data or fit regressions. `draw-check` additionally
checks retained coefficient draws. Each stage records its Git commit and UTC time
under the paper's ignored `04_output/00_logs/`.

## New-machine setup

1. Clone the private repository. Install R 4.4.1, Python 3, Quarto, and XeLaTeX.
   PDF rendering currently uses the PT Serif font; install that font too.
2. Install renv if needed (`install.packages("renv")`), then restore the pinned R packages:
   `Rscript -e 'renv::restore(prompt=FALSE)'`.
   The tracked `.Rprofile` activates the platform-specific project library automatically.
   Python entry points also set the project profile when launching R or Quarto.
   `DESCRIPTION` declares direct dependencies; `renv.lock` pins all 87 packages.
   Run `Rscript -e 'renv::status()'` to check synchronization.
3. Place the licensed/provider files in `01_data/`, or set `PISA_DATA`.
   See `01_data/README.md` for exact filenames.
4. Restore the local aggregate snapshot to the paper's `02_results/` if reproducing
   the current manuscript. Its tracked manifest contains hashes, not the data.
5. Run the commands above. Optional expensive model recomputation is documented
   in the paper README. Do not claim a fresh raw-to-paper reproduction solely from
   a successful cached report build.
6. Enable checks: `git config core.hooksPath 02_scripts/00_tools/hooks`.

## What Git holds

Code, QMD/BibTeX/CSL sources, documentation, package lockfile, and provenance
manifests. **All data files are ignored**, including aggregate CSVs. Individual
records, RDS objects, bootstrap draws, cached results, figures, rendered PDFs,
and local backups are not committed. This is intentional: a clone needs local
provider files and/or the local results snapshot. No data are downloaded or
published automatically.

## Rules

Shared variables have one central definition. Paper scripts must not read provider
files, reconstruct SES rank, redefine deprivation, or rescale the shared skills.
Model-specific centering, counterfactual contrasts, regression interactions, and
estimation weights belong to analysis and must be documented as such. Changes to
central definitions require a new shared build and explicit re-estimation; do not
silently reuse country checkpoints. Legacy pipelines are preserved for provenance
and migrated before being treated as maintained.

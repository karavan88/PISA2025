# Submission packaging

Run `python3 05_papers/01_SESTransmission/01_code/02_submission/build_package.py` from the repository root after rendering the current manuscript and supplement. This packaging step uses their generated TeX, removes author metadata and revision shading, embeds declarations, collects figure dependencies, and compiles with XeLaTeX. It does not harmonize data or estimate models. Outputs are ignored under `06_submissions/01_ijed_20261124_v3`.

Upload the clean manuscript PDF with `anonymous_latex_sources.zip` (editable TeX and figures), the anonymous supplement, title page, and separate highlights. Title-page and highlights TeX files are editable. No cover letter is generated. The named GitHub/data note is editor-only, not an anonymous reviewer attachment. The repository remains private.

The anonymous analysis archive includes source code, central preparation, dependency records, and data-placement instructions; it excludes provider data, result snapshots, Git history, and author files. It is not a self-contained raw-to-paper replication. Snapshot/reference inputs are still required for the maintained retained-result workflow. A complete fresh 499-resample rerun was not performed. Anonymization changes source bytes, so historical source hashes cannot validate the anonymized files. The separate typesetting archive reproduces frozen PDFs without those analytical inputs.

## Environment finding

The project was estimated with R 4.4.1. The machine default now invokes R 4.6.1, which lacks knitr/rmarkdown in its project library. Select a working R 4.4.1 installation before renv restore/status and Quarto rendering; do not change the system-wide R selector while other sessions are active. On macOS, a framework Rscript can resolve the Current framework even from a versioned path: verify `R.version.string` and `.libPaths()` rather than relying on the executable path alone. Packaging already-rendered TeX needs only XeLaTeX and PT Serif and avoids that ambiguity.

## Remaining submission checks

Confirm exact provider release and access URL in the editor-only data statement. Supply any desired acknowledgments (none invented). Exact historical AI model versions were not consistently recorded; the manuscript says so rather than inventing them. No public DOI archive has been deposited. Submission itself remains the author's action.

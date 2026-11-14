# IJED working draft

27 September 2026

Read **ijed_paper.pdf** (11 pages) or **ijed_paper.html**. Edit **ijed_paper.qmd**.

The paper reports reading for Armenia, Azerbaijan, Georgia, Kazakhstan, Kyrgyzstan and Moldova, and science for Uzbekistan. Results are country-specific. Existing estimates were reused; no analysis was rerun. The original Paper A is unchanged.

## Files needed to render

- `ijed_paper.qmd`: manuscript
- `ijed_references.bib`: cited literature
- `elsevier-harvard.csl`: automatic author-date style
- `ijed_reporting.R`: reporting-only helper
- `ijed_data/`: 16 filtered saved result files and provenance manifest

Keep these together. No raw data or analytic RDS is required. Rendering calls no estimation scripts.

With Quarto, R and knitr installed, render from this folder using `quarto render ijed_paper.qmd --to html` or `quarto render ijed_paper.qmd --to pdf`. PDF also requires XeLaTeX and the PT Serif font installed on this Mac.

## Revision status

`ijed_revision_notes.md` explains what changed and which analysis issues remain. The mediation outputs contain inherited inference and provenance limitations, reported in the appendix. This is the working draft for the next revision, not a claim that those issues have been resolved.

The older `ijed_review_notes.md` reviews the original Paper A. It is retained separately for reference and is not part of the manuscript bundle.

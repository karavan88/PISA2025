# Alternative chart comparison

This reporting-only script produces six alternative figures from saved aggregate results and copies seven current figures for comparison. It never fits models or reads pupil-level data. The manuscript is unchanged.

From the repository root, using the project R environment:

```sh
Rscript 05_papers/01_SESTransmission/01_code/03_chart_alternatives/build.R
quarto render 05_papers/01_SESTransmission/03_manuscript/chart_alternatives.qmd --to pdf
```

Saved tables and current figures in `04_output/rev2` must already exist. The script refuses to overwrite its dated output snapshot. For a new build, select a new snapshot directory in the script and update the corresponding image paths in the comparison QMD. Existing snapshots can be rendered without rebuilding figures.

The booklet explains the uncertainty information retained or omitted by each design. Country estimates, samples, and model definitions are unchanged.

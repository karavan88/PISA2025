# Where to put the data

Download the official **PISA 2025 public-use SPSS files** from the [OECD database](https://www.oecd.org/en/data/datasets/pisa-2025-database.html), then extract them. Put these 2 files directly in this folder:

```
PISA2025/
  01_data/
    CY09_MS_STU_PUF.sav
    CY09_MS_SCH_PUF.sav
```

Do not rename the files or place the ZIP archives here instead of the extracted `.sav` files. The student file supplies both active designs. The school file supplies the level-2 weights used by project 01. No teacher, parent, timing, or cognitive-item file is needed for projects 01 and 02; their parental background variables and plausible values are in the student file.

Alternatively, keep the 2 files together elsewhere and set an absolute directory before building:

```sh
export PISA_DATA="/absolute/path/to/extracted/PISA2025"
python3 02_scripts/00_tools/build_shared.py
```

The central build reads each provider file once and creates `03_outputs/01_harmonized/`. Paper 01 uses its country/exposure inputs; paper 02 uses `cutoff/analytic.rds`, `systems.csv`, and the eligibility audit. Do not put manually prepared files in that output directory. Input/code/output hashes decide whether preparation needs to run again.

`01_data/derived/` contains historical local artifacts; it is not an input requirement for the maintained workflows of projects 01 and 02. Shared preparation now replaces those dependencies. Project 03 is still being migrated separately.

## Reproduce the current reports without re-estimating

A Git clone intentionally contains no data or saved estimates. To reproduce the frozen reports without fitting models, restore the local CSV bundles to:

- `05_papers/01_SESTransmission/02_results/` — preserve the subfolder structure in `snapshot_manifest.json`.
- `05_papers/02_fuzzy_rd_learning/02_results/` — the files listed in `snapshot_manifest.json`.

Both runners verify these file hashes. The manifests alone cannot reconstruct missing estimates. Project 01's retained-draw checks additionally require its local `04_output/upstream/` and parental-control fit caches. A fresh raw-data estimation does not require these historical caches.

All data, including aggregate CSVs, stay Git-ignored. See [reproduction instructions](../00_documentation/REPRODUCE.md) for environment setup, commands, and the tested scope.

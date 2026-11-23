# Local generated outputs

`01_harmonized/` holds central outputs: all_data.rds, base_data.rds,
parental_background.rds, deprivation inputs/counts, country/exposure prepared
inputs, metadata, and build_manifest.json. All contents are ignored by Git.
`04_entry_rules/` holds the central school-entry rules built from the pinned UIS
snapshot (`build_shared.py --entry-rules`).
Old project directories are legacy outputs. `ijed_ses_seg` is a local
compatibility link to the maintained paper's 04_output directory.

# Repository rules

- Read README.md and the relevant numbered paper README first.
- Shared harmonization belongs only in 02_scripts/01_harmonization. No raw-provider reads or shared-variable construction in maintained paper code.
- Do not duplicate processing: use build_shared.py and its content hashes. Reporting never triggers estimation.
- All data files remain Git-ignored, including aggregate CSVs. Never force-add data.
- Keep structural folders numbered. Current paper folders use 01_code, 02_results, 03_manuscript, 04_output, 05_archive, 06_submissions.
- Preserve original inputs and snapshots. Never silently overwrite a checkpoint after model/sample/definition changes.
- Run check_repo.py and relevant reporting/validation checks before completion. State whether raw estimation was actually rerun.
- Do not treat legacy papers as migrated. Register their actual status in 05_papers/REGISTRY.md.

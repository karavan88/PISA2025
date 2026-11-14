# Central variable definitions and reproduction boundary

## Authoritative build

`02_scripts/00_tools/build_shared.py` runs `extract_base.R` then `prepare.R`.
The first loads the student and school sources once, attaches school weights,
constructs the national weighted midpoint SES rank, defines age/gender coding,
and standardizes released skill indices on the established SES sample. The
second uses that saved extract to construct deprivation and prepare common
country/exposure inputs. It never rereads SPSS files. Parental education and
occupation come from the same central student read.

- SES exposure: weighted national midpoint percentile rank of ESCS / 10,
  computed before complete-case selection.
- Skills: PERSEV, CURIO, ENPROBS, COGABIL, GOALSET, SELFREG; existing weighted
  SES-sample means and SDs; deprivation keeps the SES scale.
- Deprivation: response 2 means cannot afford. Select an item when valid
  responses cover at least 90% of those answering any candidate in that system.
  Require all retained items. The common-4 alternative is also constructed once.
- Parental controls: PAREDINT and HISEI, numeric source values, no paper recoding.
- Prepared eligibility preserves the existing minimum 100 pupils/30 schools.
  The full all_data.rds is retained centrally for other samples and coverage audits.
- Paper 01 selects 6-skill systems and its recorded country exclusions, giving
  67 SES and 62 deprivation systems. These are analysis choices, not altered raw data.

Within/between centering and model-specific conditional weights occur in shared
model functions called by the paper. They depend on the fitted analytic sample;
they are statistical specification steps, not alternative definitions of the
underlying SES, skill, deprivation, or parental variables.

## Frozen results versus fresh estimation

The current 72-file aggregate snapshot predates this repository migration. Its
SHA-256 manifest identifies the imported artifacts. Reporting verifies those
hashes and regenerates figures and PDFs. The package lock describes the available
reproduction environment, not proof that every historical fit used every locked
package version. Original session/package records remain in local input outputs.

The migration tests central raw-data preparation and cached reporting separately.
It does not certify a fresh rerun of all 499-draw regressions. The expensive
estimate entry point is explicit. Never infer current provenance from output
mtime alone. After changing central definitions or estimation code, use a fresh
analysis checkpoint directory and compare results before publishing a new snapshot.

A fresh clone has no data and no aggregate CSVs by author instruction. Restore
local source files and the approved result snapshot. The snapshot includes
historical country metadata/reference eligibility used to check reconstruction.
The manifest alone cannot regenerate absent observations or estimates.

## Verified migration — 14 November 2026

The central build reproduced all 157 archived country/exposure input objects without numerical differences (attributes excluded from comparison). An unchanged second run skipped processing. Cached reporting passed 657 checks; all 62 saved parental-control fits passed the retained-draw checks. A clean staged-file checkout, with only the local aggregate CSV snapshot restored and no raw data or model caches, rebuilt both PDFs with identical extracted text. No full bootstrap re-estimation was run.

When a central build exists locally, reporting checks its source/code fingerprints against the approved snapshot and rejects changed inputs. Without raw data or a central build, reporting is explicitly frozen-snapshot reproduction.

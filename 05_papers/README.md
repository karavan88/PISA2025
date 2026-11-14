# Active papers

| Project | Full draft/report title | Status |
|---|---|---|
| [01_SESTransmission](01_SESTransmission/) | **Do socio-emotional skills transmit socio-economic (dis)advantage? Evidence from PISA 2025 data** | Current manuscript and appendix; shared inputs and cached reporting validated |
| [02_fuzzy_rd_learning](02_fuzzy_rd_learning/) | **Grade Gain Report — what a year of schooling adds at age 15 in every eligible PISA 2025 system** | Central preparation; 36-system rerun; skill-outcome alignment correction documented |
| [03_resilience_cost](03_resilience_cost/) | **The cost of resilience: Life satisfaction among disadvantaged high achievers in PISA 2025** | Report draft (target: Child Indicators Research); frozen result snapshot; central migration pending |
| [04_price_of_progress](04_price_of_progress/) | **The price of progress: Achievement, school progression and adolescent life satisfaction in PISA 2025** | Report draft (target: Economics of Education Review); frozen result snapshot; central migration pending |

Each project contains `01_code`, `02_results`, `03_manuscript`, `04_output`, `05_archive`, and `06_submissions`. Manuscripts belong inside their project, with no separate top-level manuscripts directory. All other projects are in [06_scoping](../06_scoping/).

Shared data preparation belongs exclusively in `02_scripts/01_harmonization`. Projects 03 and 04 were one wellbeing project until 14 November 2026; they share the frozen legacy preparation in `02_scripts/02_legacy/wellbeing_shared`, which still needs central migration, and exchange results only through hashed snapshots in each project's `02_results`. See [reproduction guide](../00_documentation/REPRODUCE.md) for the verified scope of projects 01 and 02. Data, estimates, and rendered artifacts remain local and Git-ignored.

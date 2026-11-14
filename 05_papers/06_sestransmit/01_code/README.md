# sestransmit — Do socio-emotional skills transmit socio-economic (dis)advantage? All PISA 2025 systems

Independent pipeline, started 8 November 2026. It reads only the raw PUF (`01_data/CY09_MS_*_PUF.sav`) and writes only to
`01_data/derived/sestransmit_*`, `03_outputs/sestransmit/` and `04_manuscripts/sestransmit/`. Nothing in `paperA/`, `paperA_eap/`
or the IJED draft is read or changed. Target journal: *Education Economics*.

## Run

```sh
sh 02_scripts/sestransmit/run_all.sh      # from the repo root; ~6 min; needs pyreadstat, data.table, mediation, sandwich, ggplot2, ggrepel, patchwork, quarto
```

| Script | Does | Writes |
|---|---|---|
| `01_build.py` | reads the student and school PUF for every system; MALE for sex (ST004D01T is blank in 15 systems); growth mindset from ST420Q01 | `01_data/derived/sestransmit_students.csv.gz`, `audit/coverage_raw.csv` |
| `02_prepare.R` | drops KHM (no scales), CRI and SLV (no ESCS); within-system weighted percentile rank of ESCS; fielded mediators per system (≥ 20 % non-missing); complete cases on exposure, science PV and fielded mediators; controls with missing indicators; skills re-standardised across the pooled sample; between-school ICC | `sestransmit_analytic.rds`, `sestransmit_selection.rds`, `audit/sample_coverage.csv`, `audit/fielded.csv` |
| `03_estimate.R` | per system × domain × specification: total gradient, single-mediator ACMEs (LSEM: π_k·b_k), joint Gelbach decomposition, ρ* sensitivity; everything from one weighted cross-product matrix, 80 Fay BRR replicates × 10 PVs; robustness runs `ipw`, `escs_index`, `core5` | `tables/estimates_long.csv` (1000 units) |
| `04_validate.R` | Hong Kong: cross-product vs `lm()` (exact), vs `mediation::mediate()` and `medsens()` | `audit/validation.csv` |
| `05_figures.R` | Figures 1–7 (PDF + PNG) | `figures/` |
| `06_tables.R` | Tables 1–6 as CSV + `headline.csv` for in-text numbers; shares reported only where the gradient has \|t\| > 2 | `tables/t*.csv` |

## Design (follows the author's standing rules)

- One model per system; no pooled or bloc models. Summaries are medians and interquartile ranges across systems; OECD/partner only as a label.
- Exposure: ESCS as a within-system percentile rank / 10 (one unit = 10 percentile points; P10→P90 = 8 units). ESCS index units as a check.
- Mediators: PERSEV, CURIO, ENPROBS, COGABIL, GOALSET, SELFREG (WLE scales) and binary GROWTH (disagree that intelligence is fixed). Every scale a system fielded enters; 73 of 87 systems have all seven.
- Estimates of record: single-mediator Imai–Keele–Tingley ACMEs; the joint share from the Gelbach decomposition (= total − direct with all skills). Conditional per-skill contributions kept as a collinearity check.
- "Total" = student controls (sex, age, grade, immigrant background, home language; missing indicators). "Within-school" adds the leave-one-out school mean of the exposure, private, urbanicity (Mundlak). Not a school fixed-effects model.
- Estimation never runs when the .qmd renders; the manuscript reads CSVs only.

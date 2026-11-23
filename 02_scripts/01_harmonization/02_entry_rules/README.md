# School-entry rules (central, from UIS)

The repository's only source of official school-entry rules. Every paper reads the products below; no paper keeps its own table of entry ages,
school-year months or cutoffs. The tables kept earlier inside paper 04 (`04_output/external_uis`, `external_entry_rules`) are superseded and are
not read here.

## Source

UNESCO Institute for Statistics, public API, six indicators (the Data Browser view the user defined on 2026-11-22):

| Code | Indicator |
|---|---|
| 299905 | Official entrance age to primary education |
| 299932 | Theoretical duration of primary education |
| 999975 | Official entrance age to lower secondary education |
| 999977 | Official entrance age to upper secondary education |
| 403 | Start month of the academic school year |
| 404 | End month of the academic school year |

All countries, 2005–2026, so the entry years of the PISA 2018, 2022 and 2025 cohorts are covered. Lower-secondary duration is 999977 − 999975.
Values flagged NIL or NA by UIS (stored as 0) are missing.

## Commands

```sh
python3 02_scripts/01_harmonization/02_entry_rules/fetch_uis.py --pin   # only for a new UIS release
python3 02_scripts/00_tools/build_shared.py --entry-rules
```

`fetch_uis.py` stores the API response verbatim in `01_data/external_uis/` under the UIS release version and never overwrites a stored file.
`uis_pin.json` (tracked: file name, SHA-256, release, URL, retrieval time) names the snapshot the build reads. The build needs no network, checks
the snapshot against the pin, and skips when the snapshot, `cutoff_provider.rds`, the two central cutoff files and `prepare.R` are unchanged.
Run the main shared build first. It fits no model.

## Products (`03_outputs/04_entry_rules/`, Git-ignored)

- `uis_rules_long.csv` — one row per PISA system and year: the six indicators as UIS reports them, plus lower-secondary duration.
- `entry_rules.csv` — one row per PISA system: the rule that applied to the PISA 2025 cohort and how PISA grades sit against it.
- `grade_by_birth_month.csv` — per system and birth month: students, mean grade, the grade each reading of the rule assigns, repetition.
- `manifest.json` — input and product hashes.

## Rules

1. **System to country.** A PISA system takes the rule of its ISO country. B-S-J-Z (QCI), Kurdistan Region (QKI), Dushanbe (QTJ) and the Ukrainian
   regions (QUA) take the national rule of China, Iraq, Tajikistan and Ukraine and are marked `national rule, regional sample`. Kosovo (KSV) and
   Chinese Taipei (TAP) are not in UIS: Kosovo takes Albania's rule and Chinese Taipei takes China's (user's decision, 2026-11-22), marked
   `proxy country: ALB` and `proxy country: CHN`.
2. **Entry age of the cohort.** The cohort starts with births in 2009. The entry age `a` is the one for which the official age in year 2009 + `a`
   equals `a`; that year is `entry_year`. Level durations and ages are read in that year; their 2025 values are kept beside them and any difference
   is written to `structure_changed`.
3. **School-year months.** UIS start months flip in single years in some countries. At entry the most frequent value of the three years around
   `entry_year` is used; at the test the most frequent value of 2022–2025, keeping the entry value when it ties. All values seen are in
   `start_month_values`.
4. **Assigned grade.** UIS gives an entry age and a school calendar, not a cutoff date. Two readings are computed for every student and nothing else
   is inferred from the data:
   - `S`: a child must have turned `a` before the school year starts (cutoff at the start month);
   - `C`: a child enters in the calendar year in which they turn `a` (cutoff on 1 January).
   The grade is counted from the school year in session at the test (test month = birth month + AGE). `reading` is the one that matches more
   students; `fit_S` and `fit_C` are both kept.
5. **Whole-grade shift.** Where most students sit one grade away from the rule (national grade 1 is not the first UIS primary year, or the cohort
   entered at another age than UIS records), the shift is reported in `grade_offset` and the shares below are measured after it. It is never hidden:
   `fit_S` and `fit_C` are before the shift.
6. **What PISA adds.** `grade_jump` is the difference in mean actual grade between the two grades the rule assigns: a first stage defined by the
   rule alone. `late_entry` and `early_entry` are the shares of never-repeaters below and above the assigned grade. PISA 2025 has no question on
   the age at starting primary school (only pre-primary, ST125), so actual entry age is not observed directly.
7. **Cutoff month from PISA.** UIS has no indicator for the date by which a child must reach the entry age (all 5,556 indicators searched,
   2026-11-22). The month is therefore read from PISA grades, and only by the central cutoff definition (`prepare_cutoff_analytic.R`,
   `cutoff/eligibility.csv`); this build copies it and detects nothing itself. `pisa_cut` is the first birth month on the lower-grade side;
   `pisa_partial_month` says the month before it is split between the two grades, so the cutoff falls inside that month; `pisa_eligible` and
   `pisa_reason` are that definition's verdict. `pisa_minus_uis_months` sets it against the month where the UIS reading switches grade
   (`uis_cut_month`: the school-year start month under `S`, January under `C`). Division of labour: UIS gives entry age, school calendar and level
   structure; PISA gives the cutoff month.
8. **School levels.** `first_upsec_grade_uis` is primary plus lower-secondary duration plus one (2025 structure); `first_upsec_grade_pisa` is the
   lowest grade in which most students are in an upper-secondary programme (ISCEDP). `top2_cross_levels` marks systems whose two main grades lie on
   either side of that boundary.

## Limits

- The exact cutoff date is not in UIS. Among the 36 systems with an eligible PISA cutoff, the UIS reading names the same month in 10, a
  neighbouring month in 13 and a month two or more away in 13; in 9 of the 36 the UIS readings assign the whole cohort a single grade.
  The UIS readings are a cross-check, not the cutoff.
- The PISA cutoff is read from the same cohort the papers analyse. It uses grades only, never test scores. Deriving it from an earlier PISA
  cycle would remove the objection and is not done here.
- UIS reports one national rule. Federal systems (Germany, Switzerland, the United States, Australia, the United Kingdom) vary inside the country.
- Austria, Ireland, Iceland, Norway and Sweden have no grade in the PISA 2025 file; Luxembourg and El Salvador have no birth month. They get a UIS
  rule but no comparison with PISA grades.
- The stand-ins are approximations: China's rule reproduces Chinese Taipei's grades almost exactly (99% of students on the rule), Albania's
  fits Kosovo less well (81%, and Kosovo's cutoff in PISA is December, not Albania's).

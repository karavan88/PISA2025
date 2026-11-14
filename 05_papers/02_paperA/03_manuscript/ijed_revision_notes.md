# Seven-country IJED revision

27 September 2026

The new `ijed_paper.qmd` is a rewritten working draft based on Paper A. The original Paper A and its saved estimates have been preserved. No preparation, model fitting, mediation simulations or sensitivity analyses were rerun. Formatting a table, selecting saved country rows and multiplying a saved slope by eight are reporting operations only.

## Scope

| Country | Outcome |
|---|---|
| Armenia | Reading |
| Azerbaijan | Reading |
| Georgia | Reading |
| Kazakhstan | Reading |
| Kyrgyzstan | Reading |
| Moldova | Reading |
| Uzbekistan | Science |

Every result table identifies individual countries. No regional, pooled, cross-country mean, median or interquartile-range result is reported. Uzbekistan is explicitly marked as science in the text and every table that includes it. Its science results are not used to rank countries' reading performance.

## What changed

- Main text reduced from approximately 8,266 to approximately 3,600 words; the abstract is 137 words. The rendered draft has 11 pages including references and a one-page technical appendix.
- The results now focus on the socio-economic gradient, the joint skill block, country-specific skill profiles and the deprivation extension. Parallel outcome comparisons, broad regional summaries, lengthy scale inventories and repeated institutional claims were removed.
- The “real but flat” heading was replaced with “Socio-economic differences in skills.” Section 5.1 now explains the units. The fitted curiosity difference from the 10th to the 90th percentile is about 0.37 reference SD in Azerbaijan and 0.35 in Kazakhstan. These are eight times the saved ten-percentile-point slopes, not observed top-versus-bottom-decile differences.
- School-composition adjustment is called **school-adjusted**, rather than school fixed effects or a causal comparison among classmates.
- Indirect associations are distinguished from intervention effects. Single-mediator shares are explicitly non-additive. Claims that sensitivity estimates establish causal upper bounds were removed.
- Cognitive adaptability is labelled according to the local COGABIL inventory. ENPROBS remains enjoyment of problem-solving.
- Country-level deprivation results replace the assertion that hardship operates mainly through effort everywhere. The country evidence does not support that generalisation.
- Formulaic verdicts and metaphors about the “strength of the school,” the “width of the conduit,” and a universal opposition between intellectual disposition and diligence were removed.
- Citations and the references section are generated from `ijed_references.bib` using the Elsevier Harvard CSL. There is no manually typed bibliography in the manuscript.

## Important limits carried forward for the analysis revision

1. **Armenia is unstable.** Its joint reading association is imprecise in the survey-based companion decomposition. The joint share changes from 11.4% to -14.4% under the existing nonresponse adjustment. The manuscript now reports this, instead of relying on a regional robustness summary.
2. **Kazakhstan lacks perseverance.** Its joint block contains six dispositions, compared with seven elsewhere. The saved point estimate is retained, with the composition difference stated.
3. **Uzbekistan has no matching saved science deprivation or sample-selection robustness estimates.** Those extensions contain the six reading countries only. No science value was substituted or invented.
4. **Mediation point estimates and survey-based companion estimates differ.** The former use a smaller plausible-value selection and model-based simulation routines; the latter use all ten plausible values and the existing replicate-weight variance routine. The exact Monte Carlo settings are not recorded in each saved CSV, and some mediator rows were updated separately. Appendix A reports these provenance limits. Standard errors from the companion decomposition have not been attached to different headline point estimates.
5. **The continuous scales retain their original reference standardisation.** The seven-country subset has not been restandardised. All coefficients are from the saved models.
6. **The new framing needs a focused country-context literature revision.** The paper now avoids unsupported institutional explanations. A later literature pass should develop the relevant country histories and closest comparative studies without treating the shared post-Soviet setting as an explanatory variable.
7. **Measurement and causal identification remain research tasks.** Prior achievement, reporting differences and complete-case selection cannot be repaired by editing. These are documented so the writing does not outrun the design.

## How to use the draft

Read `ijed_paper.pdf` or the self-contained `ijed_paper.html`. Edit `ijed_paper.qmd`. Keep it alongside `ijed_reporting.R`, `ijed_references.bib`, `elsevier-harvard.csl` and `ijed_data/`.

The source bundle contains these files and the filtered saved estimates. The reporting helper only reads those estimates and formats values. The provenance manifest records original source filenames and checksums. It also preserves the original CSV labels for audit purposes; the manuscript uses the corrected terminology described above.

The older `ijed_review_notes.md` is a historical review of the original Paper A, not a description of the current draft. Its original word counts and findings remain useful for tracing the revision.

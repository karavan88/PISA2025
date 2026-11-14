# Run from the project/bundle root: Rscript 02_scripts/ijed_ses_seg/render_rev2.R
# This is deliberately a reporting-only entry point.
source('02_scripts/ijed_ses_seg/11_summarize_counterfactual_robustness_rev2.R')
source('02_scripts/ijed_ses_seg/02_figures_rev2.R')
source('02_scripts/ijed_ses_seg/07_equalization_figures_rev2.R')
source('02_scripts/ijed_ses_seg/12_counterfactual_robustness_figures_rev2.R')
source('02_scripts/ijed_ses_seg/03_validate_rev2.R')
source('02_scripts/ijed_ses_seg/08_validate_equalization_rev2.R')
source('02_scripts/ijed_ses_seg/05_link_index_rev2.R')
if(!file.exists(file.path(OUT,'tables/descriptives.csv')))
  stop('Cached descriptives missing. Restore the bundle or run 01_descriptives.R with saved inputs.')
q <- Sys.which('quarto')
if(!nzchar(q)) stop('Quarto is required.')
for(f in c('ijed_ses_seg_rev2','ijed_ses_seg_supplement_rev2')) {
  doc <- file.path('04_manuscripts/ijed_ses_seg',paste0(f,'.qmd'))
  status <- system2(q,c('render',shQuote(doc),'--to','pdf'))
  if(status!=0) stop('PDF rendering failed: ',f)
}
message('Main manuscript and supplement rendered to PDF. Earlier reports are unchanged.')

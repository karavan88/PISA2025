# Run from the project/bundle root: Rscript 05_papers/01_SESTransmission/01_code/render.R
# This is deliberately a reporting-only entry point.
source('05_papers/01_SESTransmission/01_code/02_figures.R')
source('05_papers/01_SESTransmission/01_code/03_validate.R')
if(!file.exists(file.path(OUT,'tables/descriptives.csv')))
  stop('Cached descriptives missing. Restore the bundle or run 01_descriptives.R with saved inputs.')
q <- Sys.which('quarto')
if(!nzchar(q)) stop('Quarto is required.')
for(f in c('ijed_ses_seg','ijed_ses_seg_supplement')) {
  doc <- file.path('05_papers/01_SESTransmission/03_manuscript',paste0(f,'.qmd'))
  status <- system2(q,c('render',shQuote(doc),'--to','pdf'))
  if(status!=0) stop('PDF rendering failed: ',f)
}
message('Main manuscript and supplement rendered to PDF. Earlier reports are unchanged.')

# Reporting only: this routine never estimates a regression.
invisible(Sys.setlocale('LC_CTYPE', 'en_US.UTF-8'))
library(data.table)
setDTthreads(1)
find_root <- function() {
  p <- normalizePath(getwd())
  repeat {
    if (file.exists(file.path(p, '05_papers/01_SESTransmission/04_output/input/estimates.csv'))) return(p)
    q <- dirname(p)
    if (identical(p, q)) stop('Run from within the ijed_ses_seg project or bundle.')
    p <- q
  }
}
ROOT <- find_root()
OUT <- file.path(ROOT, '05_papers/01_SESTransmission/04_output')
read_input <- function(name) fread(file.path(OUT, 'input', paste0(name, '.csv')))
E <- read_input('estimates')
A <- read_input('eligibility')
G <- read_input('country_groups')
H <- read_input('hypothesis_country_classification')
R <- read_input('ratio_audit')
V <- read_input('sensitivity')
L <- read_input('lmer')
sklab <- c(PERSEV='Perseverance', CURIO='Curiosity', ENPROBS='Enjoyment of problem solving',
           COGABIL='Cognitive adaptability', GOALSET='Goal setting', SELFREG='Self-regulated learning')
fmt <- function(x, digits=2) formatC(x, digits=digits, format='f', big.mark=',')
num <- function(x) format(x, big.mark=',', scientific=FALSE, trim=TRUE)
est <- function(cc, tt, ex='SES') E[CNT==cc & term==tt & exposure==ex, estimate]
ci <- function(cc, tt, ex='SES', digits=2) {
  z <- E[CNT==cc & term==tt & exposure==ex]
  if(nrow(z)!=1) stop('Missing or duplicated result: ', cc, '/', tt, '/', ex)
  paste0(fmt(z$estimate,digits), ' [', fmt(z$lower,digits), ', ', fmt(z$upper,digits), ']')
}
supported <- function(tt, ex='SES', adjusted=FALSE) {
  z <- H[scope=='Six-skill systems only' & exposure==ex & term==tt]
  if (adjusted) sum(z$adjusted_support) else sum(z$classification=='Supports')
}
summary_h <- function(ex='SES', terms=c('skills_sorting','sorting_increment',paste0('indS_',names(sklab)))) {
  rbindlist(lapply(terms, function(tt) {
    z <- H[scope=='Six-skill systems only' & exposure==ex & term==tt]
    lab <- if(tt=='skills_sorting') 'All six skills' else if(tt=='sorting_increment') 'Addition from sorting' else unname(sklab[sub('indS_','',tt)])
    data.table(Quantity=lab, Supports=sum(z$classification=='Supports'),
      Opposite=sum(z$classification=='Opposite'), Uncertain=sum(z$classification=='Inconclusive'),
      `BH support`=sum(z$adjusted_support), Systems=nrow(z))
  }))
}
# kable longtables remain editable and repeat headers across page breaks.
tbl <- function(x, caption=NULL, size=8, widths=NULL, long=TRUE) {
  k <- knitr::kable(x, format='latex', booktabs=TRUE, longtable=long, row.names=FALSE,
                   caption=caption, escape=TRUE, linesep='')
  k <- kableExtra::kable_styling(k, latex_options=if(long)'repeat_header' else 'HOLD_position', font_size=size,
                               repeat_header_text='(continued)')
  if(!is.null(widths)) for(j in seq_along(widths)) if(!is.na(widths[j])) k <- kableExtra::column_spec(k,j,width=widths[j])
  k
}
stopifnot(nrow(E[term=='skills_sorting' & exposure=='SES' & skills==6])==69,
          nrow(E[term=='skills_sorting' & exposure=='DEP' & skills==6])==63,
          !anyDuplicated(E[,.(CNT,exposure,term)]), all(E$bootstrap_valid==499))

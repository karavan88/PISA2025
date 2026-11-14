# Reporting only: this routine never estimates a regression.
invisible(Sys.setlocale('LC_CTYPE', 'en_US.UTF-8'))
library(data.table)
setDTthreads(1)
find_root <- function() {
  p <- normalizePath(getwd())
  repeat {
    if (file.exists(file.path(p, '03_outputs/ijed_ses_seg/input/estimates.csv'))) return(p)
    q <- dirname(p)
    if (identical(p, q)) stop('Run from within the ijed_ses_seg project or bundle.')
    p <- q
  }
}
ROOT <- find_root()
BASE_OUT <- file.path(ROOT, '03_outputs/ijed_ses_seg')
OUT <- file.path(BASE_OUT, 'rev2')
read_input <- function(name) fread(file.path(BASE_OUT, 'input', paste0(name, '.csv')))
E <- read_input('estimates')
A <- read_input('eligibility')
G <- read_input('country_groups')
H <- read_input('hypothesis_country_classification')
R <- read_input('ratio_audit')
V <- read_input('sensitivity')
L <- read_input('lmer')
# Manuscript scope: six measured skills; explicit country restriction.
A <- A[skills==6 & status=='Eligible' & !CNT %in% c('QUA','UKR')]
scope_filter <- function(x) {
  if(all(c('CNT','exposure') %in% names(x))) return(x[A[,.(CNT,exposure)],on=.(CNT,exposure),nomatch=0])
  if('CNT' %in% names(x)) return(x[CNT %in% A$CNT])
  x
}
E <- scope_filter(E); G <- scope_filter(G); R <- scope_filter(R)
V <- scope_filter(V); L <- scope_filter(L)
H <- scope_filter(H)[scope=='Six-skill systems only']
# Keep the original test-family definitions, but only the retained countries.
H[E,on=.(CNT,exposure,term),p_value:=i.p_approx]
H[,summary_q:=p.adjust(p_value,'BH'),by=.(exposure,family)]
H[,adjusted_support:=classification=='Supports' & summary_q<.05]
E[,`:=`(q_primary=NA_real_,q_skill=NA_real_)]
E[term %in% c('skills_sorting','sorting_increment'),q_primary:=p.adjust(p_approx,'BH'),by=exposure]
E[grepl('^indS_',term),q_skill:=p.adjust(p_approx,'BH'),by=exposure]
DS <- scope_filter(fread(file.path(OUT,'tables/descriptives.csv')))
nsys <- function(ex='SES') A[exposure==ex,.N]

sklab <- c(PERSEV='Perseverance', CURIO='Curiosity', ENPROBS='Enjoyment of problem solving',
           COGABIL='Cognitive adaptability', GOALSET='Goal setting', SELFREG='Self-regulated help seeking')
fmt <- function(x, digits=2) formatC(x, digits=digits, format='f', big.mark=',')
share_displayable <- function(cc,ex) {
  z<-E[CNT==cc & exposure==ex & term=='share']
  isTRUE(R[CNT==cc & exposure==ex,share_reportable]) && !(z$lower<0 && z$upper>100)
}
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
tbl <- function(x, caption=NULL, size=8, widths=NULL, long=TRUE, escape=TRUE) {
  if(!escape) {
    x <- copy(x)
    names(x) <- gsub('%','\\%',names(x),fixed=TRUE)
  }
  k <- knitr::kable(x, format='latex', booktabs=TRUE, longtable=long, row.names=FALSE,
                   caption=caption, escape=escape, linesep='')
  k <- kableExtra::kable_styling(k, latex_options=if(long)'repeat_header' else 'HOLD_position', font_size=size,
                               repeat_header_text='(continued)')
  if(!is.null(widths)) for(j in seq_along(widths)) if(!is.na(widths[j])) k <- kableExtra::column_spec(k,j,width=widths[j])
  k
}
stopifnot(nrow(E[term=='skills_sorting' & exposure=='SES' & skills==6])==68,
          nrow(E[term=='skills_sorting' & exposure=='DEP' & skills==6])==62,
          !anyDuplicated(E[,.(CNT,exposure,term)]), all(E$bootstrap_valid==499))

CE <- scope_filter(fread(file.path(OUT,'tables/equalization_estimates.csv')))
CE[term=='gap_reduction',q_gap:=p.adjust(p_value,'BH'),by=exposure]
CD <- scope_filter(fread(file.path(OUT,'tables/equalization_diagnostics.csv')))
cfest <- function(cc,tt,ex='SES') CE[CNT==cc & term==tt & exposure==ex,estimate]
cfci <- function(cc,tt,ex='SES',digits=2) {
 z<-CE[CNT==cc & term==tt & exposure==ex]
 stopifnot(nrow(z)==1)
 paste0(fmt(z$estimate,digits),' [',fmt(z$lower,digits),', ',fmt(z$upper,digits),']')
}
cfshare <- function(cc,ex='SES') {
 z<-CE[CNT==cc & term=='gap_fraction' & exposure==ex]
 if(!isTRUE(z$fraction_reportable) || (z$lower<0 && z$upper>100)) return('Withheld')
 cfci(cc,'gap_fraction',ex,1)
}

cfcount <- function(ex='SES',adjusted=FALSE) CE[exposure==ex & term=='gap_reduction',sum(lower>0 & (!adjusted | q_gap<.05))]
evidence <- function(tt,ex='SES',kind='Supports') H[exposure==ex & term==tt,sum(classification==kind)]
# Publication tables are scoped; original estimation caches remain unchanged.
fwrite(A,file.path(OUT,'tables/analysis_sample.csv'))
fwrite(E,file.path(OUT,'tables/manuscript_estimates.csv'))
fwrite(H,file.path(OUT,'tables/manuscript_hypothesis_classification.csv'))
fwrite(DS,file.path(OUT,'tables/manuscript_descriptives.csv'))
fwrite(CE,file.path(OUT,'tables/manuscript_equalization_estimates.csv'))

for(nm in c('sorting_calibration','share_display_audit')) {
 x<-scope_filter(fread(file.path(OUT,'tables',paste0(nm,'.csv'))))
 fwrite(x,file.path(OUT,'tables',paste0('manuscript_',nm,'.csv')))
}

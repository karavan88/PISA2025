# Cached publication helpers: no estimation or draw processing during knitting.
WB <- fread(file.path(OUT,'tables/within_between_decomposition.csv'))
stopifnot(setequal(WB$CNT,A[exposure=='SES',CNT]),nrow(WB)==67L*12L)
wbest <- function(cc,tt) WB[CNT==cc & term==tt,estimate]
wbci <- function(cc,tt,digits=2) {
  z<-WB[CNT==cc & term==tt];stopifnot(nrow(z)==1L)
  paste0(fmt(z$estimate,digits),' [',fmt(z$lower,digits),', ',fmt(z$upper,digits),']')
}
wbshare <- function(cc,tt) {
  if(isTRUE(WB[CNT==cc & term==tt,ratio_reportable])) wbci(cc,tt,1) else 'Withheld'
}
wbcount <- function(tt,adjusted=FALSE,negative=FALSE) {
  z<-WB[term==tt]
  sum(if(negative) z$upper<0 & (!adjusted | z$q_contrast<.05)
      else z$lower>0 & (!adjusted | z$q_contrast<.05))
}

# Presentation only: read saved estimates; never fit models.
sig_label <- function(p) {
 stopifnot(length(p)==1L,is.finite(p))
 if(p<.001)'p < 0.001' else if(p<.01)'p < 0.01' else if(p<.05)'p < 0.05' else if(p<.1)'p < 0.10' else 'p >= 0.10'
}
sig_stars <- function(p) {
 ifelse(p<.01,'***',ifelse(p<.05,'**',ifelse(p<.1,'*','')))
}
result_text <- function(z,digits=2,table=FALSE) {
 stopifnot(nrow(z)==1L,is.finite(z$estimate),is.finite(z$se))
 pv<-if('p_approx'%in%names(z))z$p_approx else z$p_value
 stopifnot(length(pv)==1L,is.finite(pv))
 if(table) paste0(fmt(z$estimate,digits),sig_stars(pv),' (',fmt(z$se,digits),')')
 else paste0(fmt(z$estimate,digits),' (',sig_label(pv),')')
}
publication_format <- function(table=FALSE) {
 ci <<- function(cc,tt,ex='SES',digits=2) result_text(E[CNT==cc&term==tt&exposure==ex],digits,table)
 cfci <<- function(cc,tt,ex='SES',digits=2) result_text(CE[CNT==cc&term==tt&exposure==ex],digits,table)
 wbci <<- function(cc,tt,digits=2) result_text(WB[CNT==cc&term==tt],digits,table)
 crci <<- function(cc,v,ex='SES',term='gap_reduction',digits=2) {
  wanted_term<-term
  result_text(CR[CNT==cc&variant==v&exposure==ex&term==wanted_term],digits,table)
 }
 mean_ci <<- function(tt,ex='SES',digits=2,kind='mediation') {
  z<-if(kind=='equalisation')CE[exposure==ex&term==tt] else E[exposure==ex&term==tt]
  result_text(system_mean(z),digits,table)
 }
}

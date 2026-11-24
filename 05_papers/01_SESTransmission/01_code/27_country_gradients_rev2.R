# Publication table and summaries; called from the main QMD after reporting_rev2.R.
country_gradient_table <- function(landscape=FALSE) {
 z<-E[exposure=='SES' & grepl('^a[WB]_',term)]
 cell<-function(cc,k) {
  one<-function(lev) {
   v<-z[CNT==cc & term==paste0('a',lev,'_',k)]
   stopifnot(nrow(v)==1)
   paste0(fmt(v$estimate,3),if(v$p_approx<.05)'*' else if(v$p_approx<.1)'†' else '')
  }
  paste(one('W'),one('B'),sep='/')
 }
 tab<-rbindlist(lapply(A[exposure=='SES'][order(economy),CNT],function(cc){
  v<-data.table(System=A[exposure=='SES' & CNT==cc,economy])
  for(k in names(sklab))v[,(k):=cell(cc,k)]
  v
 }))
 setnames(tab,names(sklab),c('Perseverance','Curiosity','Problem solving','Adaptability','Goal setting','Help seeking'))
 fwrite(z,file.path(OUT,'tables/country_skill_gradients_main.csv'))
 out<-tbl(tab,'Socio-economic gradients in each skill, by system. Each cell gives within / between-school coefficients in pupil skill SD per 10 SES rank points. * p < 0.05; † p < 0.10 (unadjusted; strongest threshold met). Between-school coefficients refer to school-average rank. Models adjust for age and gender at both levels. Full 95 percent intervals are in the supplement.',size=if(landscape) 9 else 7.1,widths=if(landscape) c('3.5cm',rep('3cm',6)) else c('2.6cm',rep('1.9cm',6)))
 if(landscape) return(knitr::asis_output(paste0('\\begingroup\n\\renewcommand{\\tblsize}{\\fontsize{9}{11}\\selectfont}\n',as.character(out),'\n\\endgroup')))
 knitr::asis_output(paste0('\\begingroup\n\\renewcommand{\\tblsize}{\\fontsize{8}{9.5}\\selectfont}\n',as.character(out),'\n\\endgroup'))
}
M_SUM<-rbindlist(list(system_mean(E[exposure=='SES'],by='term')[,quantity:='mediation'],
 system_mean(CE[exposure=='SES'],by='term')[,quantity:='equalisation']),fill=TRUE)
fwrite(M_SUM,file.path(OUT,'tables/equal_weight_system_means.csv'))

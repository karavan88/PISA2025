# Validate the new estimand against independent identities, country coverage and saved draws.
source('05_papers/01_SESTransmission/01_code/reporting_rev2.R')
stopifnot(!anyDuplicated(CE[,.(CNT,exposure,term)]),nrow(CE)==129*14,
 all(CD$bootstrap_valid==499),max(CD[exposure=="SES",max_bootstrap_pairing_error])<1e-10,
 max(CD[exposure=="SES",direct_prediction_error])<1e-9,max(CD[exposure=="SES",school_mean_identity_error])<1e-8,
 all(CD$recipient_N>0),all(CD$reference_N>0),
 all(CD$recipient_share_in_school_with_reference>=0 & CD$recipient_share_in_school_with_reference<=1))
x<-dcast(CE,CNT+exposure~term,value.var='estimate')
checks<-data.table(check=c('recipient minus reference','within plus between','projected gap','skill sum'),
 error=c(max(abs(x$recipient_change-x$reference_change-x$gap_reduction)),
 max(abs(x$within_component+x$between_component-x$gap_reduction)),
 max(abs(x$baseline_gap-x$gap_reduction-x$projected_gap)),
 max(abs(rowSums(x[,paste0('contribution_',names(sklab)),with=FALSE])-x$gap_reduction))))
stopifnot(all(checks$error<1e-9))
for(ex in c('SES','DEP')) {
 stopifnot(setequal(CE[exposure==ex,CNT],A[exposure==ex&status=='Eligible'&skills==6,CNT]))
 z<-CE[exposure==ex & term=='gap_reduction']
 stopifnot(max(abs(z$q_gap-p.adjust(z$p_value,'BH')))<1e-12)
}
# Verify selected saved uncertainty calculations from the 499 x 10 matrices.
for(id in c('SES_KOR','SES_MYS')) {
 d<-readRDS(file.path(OUT,'counterfactual',paste0(id,'.rds')))
 se<-sqrt(rowMeans(apply(d$bootstrap,c(1,2),var))+1.1*apply(d$point,1,var))
 z<-CE[paste0(exposure,'_',CNT)==id];stopifnot(max(abs(z$se-se[match(z$term,names(se))]))<1e-10)
}
fwrite(checks,file.path(OUT,'audit/equalization_checks.csv'))
message('Equalization coverage, decomposition, bootstrap pairing, prediction, inference and BH checks passed.')

# The current deprivation counterfactual comes from paired parental-model fits.
for(cc in A[exposure=='DEP',CNT]) {
 d<-readRDS(file.path(PC,'fits',paste0(cc,'.rds')))
 bt<-d$bootstrap[[2]]$counterfactual;pt<-d$point[[2]]$counterfactual
 se<-sqrt(rowMeans(apply(bt,c(1,2),var))+1.1*apply(pt,1,var))
 z<-CE[CNT==cc&exposure=='DEP']
 stopifnot(dim(bt)[3]==499,max(abs(z$se-se[match(z$term,names(se))]))<1e-10,
 max(abs(z$estimate-rowMeans(pt)[match(z$term,rownames(pt))]))<1e-10)
}
message('Parental-control counterfactual estimates and pooled uncertainty verified against all 62 saved fits.')

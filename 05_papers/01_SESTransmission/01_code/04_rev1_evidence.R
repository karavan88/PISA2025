# Descriptive review follow-up only. Does not estimate or re-estimate models.
source('05_papers/01_SESTransmission/01_code/reporting_rev1.R')
raw_path <- '03_outputs/01_harmonized/all_data.rds'
d <- readRDS(raw_path)
ids <- A[exposure=='SES' & status=='Eligible' & skills==6 & complete_share<.5,CNT]
ans <- desc <- avail <- list()
for(cc in ids) {
 z<-d[CNT==cc]; a<-A[CNT==cc & exposure=='SES']
 controls<-strsplit(a$controls,';',fixed=TRUE)[[1]]
 tests<-list('Source pupils'=rep(TRUE,nrow(z)),
   'Valid weights and school'=is.finite(z$W_FSTUWT)&z$W_FSTUWT>0&!is.na(z$school)&is.finite(z$school_weight)&z$school_weight>0,
   'Observed SES'=is.finite(z$status),
   'Ten reading plausible values'=complete.cases(z[,paste0('PV',1:10,'READ'),with=FALSE]),
   'Observed controls'=complete.cases(z[,..controls]),
   'All six skill indices'=complete.cases(z[,names(sklab),with=FALSE]))
 keep<-rep(TRUE,nrow(z)); prev<-nrow(z)
 for(step in names(tests)) {
  keep<-keep&tests[[step]]
  ans[[paste(cc,step)]]<-data.table(CNT=cc,economy=a$economy,step=step,available_source=sum(tests[[step]]),remaining=sum(keep),excluded_at_step=prev-sum(keep))
  prev<-sum(keep)
 }
 stopifnot(sum(keep)==a$N)
 saved<-readRDS(file.path('03_outputs/01_harmonized/input',paste0('SES_',cc,'.rds')))$data
 stopifnot(setequal(z$CNTSTUID[keep],saved$CNTSTUID))
 z[,reading:=rowMeans(.SD),.SDcols=paste0('PV',1:10,'READ')]
 for(v in c('ESCS','reading','AGE')) for(group in c('Retained','Excluded')) {
  ix<-if(group=='Retained')keep else !keep
  ok<-ix&is.finite(z[[v]])&is.finite(z$W_FSTUWT)&z$W_FSTUWT>0
  desc[[paste(cc,v,group)]]<-data.table(CNT=cc,economy=a$economy,group=group,variable=v,N_available=sum(ok),weighted_mean=if(any(ok))weighted.mean(z[[v]][ok],z$W_FSTUWT[ok])else NA_real_)
 }
 for(k in names(sklab))avail[[paste(cc,k)]]<-data.table(CNT=cc,skill=k,N_available=sum(is.finite(z[[k]])),source_N=nrow(z))
}
fwrite(rbindlist(ans),file.path(OUT,'tables/coverage_stages.csv'))
fwrite(rbindlist(desc),file.path(OUT,'tables/coverage_comparison.csv'))
fwrite(rbindlist(avail),file.path(OUT,'tables/skill_availability_low_coverage.csv'))
print(rbindlist(ans));print(rbindlist(desc))
rm(d);gc()
# Direct index for country-level link coefficients, preserving all saved intervals.
fwrite(E[grepl('^[ab][WB]_',term)][order(exposure,economy,term)],file.path(OUT,'tables/country_link_coefficients.csv'))
# Sorting diagnostic compares the same non-singleton sample on both definitions.
fwrite(read_input('audit')[,.(CNT,exposure,N,loo_N,delta,delta_full_loo_sample,delta_loo)],file.path(OUT,'tables/sorting_calibration.csv'))
# All ratios whose intervals extend beyond both 0 and 100 are explicitly flagged.
rr<-merge(E[term=='share',.(CNT,exposure,estimate,lower,upper,skills)],R[,.(CNT,exposure,share_reportable)],by=c('CNT','exposure'))
rr[,broad_ratio_interval:=share_reportable & lower<0 & upper>100]
fwrite(rr,file.path(OUT,'tables/share_display_audit.csv'))
message('Descriptive follow-up complete; no fitted-model estimates changed.')

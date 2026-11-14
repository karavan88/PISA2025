# Read-only diagnostic: no models fitted and no current deprivation results replaced.
source('05_papers/01_SESTransmission/01_code/reporting_rev2.R')
library(haven)
rawfile<-file.path(ROOT,'01_data/CY09_MS_STU_PUF.sav')
vars<-c('CNTSTUID','P1ISCED','P2ISCED','BP1MJ','BP2MJ','PAREDINT','HISEI','HOMEPOS')
dat<-as.data.table(read_sav(rawfile,col_select=all_of(vars)))
labels<-data.table(variable=names(dat),label=vapply(dat,function(x)attr(x,'label'),character(1)))
dat[, CNTSTUID:=as.character(CNTSTUID)]
dat[, (setdiff(names(dat),'CNTSTUID')):=lapply(.SD,as.numeric),.SDcols=setdiff(names(dat),'CNTSTUID')]
stopifnot(!anyDuplicated(dat$CNTSTUID))
wc<-function(x,y,w) {
 ok<-is.finite(x)&is.finite(y)&is.finite(w)&w>0
 x<-x[ok];y<-y[ok];w<-w[ok];x<-x-weighted.mean(x,w);y<-y-weighted.mean(y,w)
 sum(w*x*y)/sqrt(sum(w*x*x)*sum(w*y*y))
}
work<-Sys.getenv('IJED_MEDIATION_WORK','05_papers/01_SESTransmission/04_output/upstream')
ans<-lapply(A[exposure=='DEP',CNT],function(cc) {
 z<-readRDS(file.path(work,'input',paste0('DEP_',cc,'.rds')))
 d<-merge(z$data,dat,by='CNTSTUID',all.x=TRUE)
 stopifnot(nrow(d)==nrow(z$data),all(z$data$CNTSTUID %in% dat$CNTSTUID))
 # Labelled SPSS missing codes are converted to NA by haven.
 d[,both_parent_complete:=complete.cases(P1ISCED,P2ISCED,BP1MJ,BP2MJ)]
 d[,highest_parent_complete:=complete.cases(PAREDINT,HISEI)]
 d[,`:=`(depW=DEP-weighted.mean(DEP,W_FSTUWT),escsW=ESCS-weighted.mean(ESCS,W_FSTUWT)),by=school]
 rbindlist(lapply(c('Full analytic sample','Lower national SES quartile'),function(g) {
  s<-if(g=='Full analytic sample')d else d[SES_rank<=2.5]
  data.table(CNT=cc,economy=z$data$economy[1],group=g,N=nrow(s),
   corr_DEP_ESCS=wc(s$DEP,s$ESCS,s$W_FSTUWT),
   corr_DEP_HOMEPOS=wc(s$DEP,s$HOMEPOS,s$W_FSTUWT),
   corr_DEP_ESCS_within=wc(s$depW,s$escsW,s$W_FSTUWT),
   complete_both_parents_N=sum(s$both_parent_complete),
   complete_both_parents_share=mean(s$both_parent_complete),
   complete_highest_parent_N=sum(s$highest_parent_complete),
   complete_highest_parent_share=mean(s$highest_parent_complete))
 }))
})
fwrite(rbindlist(ans),file.path(OUT,'audit/deprivation_parental_controls_diagnostic.csv'))
fwrite(labels,file.path(OUT,'audit/parental_variable_labels.csv'))
print(rbindlist(ans)[,.(systems=.N,min_corr=min(corr_DEP_ESCS),median_corr=median(corr_DEP_ESCS),max_corr=max(corr_DEP_ESCS),
 min_parent_complete=min(complete_both_parents_share),median_parent_complete=median(complete_both_parents_share),max_parent_complete=max(complete_both_parents_share)),by=group])
print(rbindlist(ans)[CNT%in%c('DNK','KOR','MYS'),.(CNT,group,N,corr_DEP_ESCS,complete_both_parents_share,complete_highest_parent_share)])
print(labels)

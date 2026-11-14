# Reporting preparation only: promote saved parental-control results; no model fits.
library(data.table);setDTthreads(1)
ROOT<-normalizePath(getwd());BASE<-file.path(ROOT,'05_papers/01_SESTransmission/04_output');OUT<-file.path(BASE,'rev2');PC<-file.path(BASE,'parental_controls_comparison')
WORK<-Sys.getenv('IJED_MEDIATION_WORK','05_papers/01_SESTransmission/04_output/upstream')
EE<-fread(file.path(PC,'tables/estimates_adjusted.csv'))[specification=='Parental_background'];COV<-fread(file.path(PC,'tables/coverage.csv'))
parents<-readRDS('03_outputs/01_harmonized/parental_background.rds')
SK<-c('PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG');PV<-paste0('PV',1:10,'READ')
ans<-lapply(COV$CNT,function(cc){
 x<-readRDS(file.path(PC,'fits',paste0(cc,'.rds')));pt<-x$point[[2]];bt<-x$bootstrap[[2]]
 e<-EE[CNT==cc&estimand=='mediation'&term=='total'];tot<-mean(pt$mediation['total',]);ind<-mean(pt$mediation['skills_sorting',]);rem<-mean(pt$mediation['remaining',]);signagree<-mean(sign(bt$mediation['total',,])==sign(tot));reason<-'Reportable model-implied share'
 if(e$lower<=0&&e$upper>=0)reason<-'Total interval includes zero'
 else if(signagree<.99||any(sign(pt$mediation['total',])!=sign(tot)))reason<-'Unstable denominator across resamples or PVs'
 else if(ind*tot<0||rem*tot<0)reason<-'Opposing components: no proportional interpretation'
 else if(!all(is.finite(bt$mediation['share',,])))reason<-'Non-finite ratio in resamples'
 ratio<-data.table(CNT=cc,exposure='DEP',share_reportable=reason=='Reportable model-implied share',share_reason=reason,bootstrap_total_sign_agreement=signagree,minimum_total=min(bt$mediation['total',,]),maximum_total=max(bt$mediation['total',,]))
 z<-readRDS(file.path('03_outputs/01_harmonized/input',paste0('DEP_',cc,'.rds')))
 d<-merge(z$data,parents,by='CNTSTUID',all.x=TRUE)[is.finite(PAREDINT)&is.finite(HISEI)]
 stopifnot(nrow(d)==COV[CNT==cc,matched_N],uniqueN(d$school)==COV[CNT==cc,schools])
 d[,Reading:=rowMeans(.SD),.SDcols=PV];d[,Age_years:=AGE+15]
 ds<-rbindlist(lapply(c('Reading','SES_rank','DEP','ESCS','PAREDINT','HISEI','Age_years','nonmale',SK),function(v){xx<-d[[v]];w<-d$W_FSTUWT;mu<-weighted.mean(xx,w);data.table(CNT=cc,exposure='DEP',variable=v,N=nrow(d),mean=mu,SD=sqrt(weighted.mean((xx-mu)^2,w)),min=min(xx),max=max(xx))}))
 w<-d$W_FSTUWT;r<-d$DEP>=1;h<-d$DEP==0;d[,has_reference:=any(DEP==0),by=school]
 cd<-data.table(CNT=cc,exposure='DEP',recipient_N=sum(r),reference_N=sum(h),recipient_weight_share=sum(w*r)/sum(w),reference_weight_share=sum(w*h)/sum(w),recipient_share_in_school_with_reference=sum(w*r*d$has_reference)/sum(w*r),bootstrap_valid=499)
 gap<-EE[CNT==cc&estimand=='counterfactual'&term=='baseline_gap'];cfok<-gap$lower>0&&mean(bt$counterfactual['baseline_gap',,]>0)>=.99
 list(ratio=ratio,descriptives=ds,diagnostics=cd,cfok=data.table(CNT=cc,fraction_reportable=cfok))
})
for(n in c('ratio','descriptives','diagnostics','cfok'))fwrite(rbindlist(lapply(ans,`[[`,n)),file.path(OUT,'tables',paste0('parental_',n,'.csv')))
fwrite(EE,file.path(OUT,'tables/parental_main_results.csv'))
message('Saved parental results and matched-sample publication data prepared for 62 systems; no regressions fitted.')

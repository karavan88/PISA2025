# Reproduce original full-sample point estimates and uncertainty in selected countries.
Sys.setenv(IJED_COMPARE_DEFINE_ONLY='1')
source('05_papers/01_SESTransmission/01_code/16_parental_controls_comparison.R')
old<-fread(file.path(BASE,'input/estimates.csv'))
out<-lapply(c('DNK','KOR','MYS'),function(cc){
 z<-readRDS(file.path('03_outputs/01_harmonized/input',paste0('DEP_',cc,'.rds')));s<-prepare_model(z);J<-length(s$base$n)
 pt<-calcmed(s)$mediation
 dr<-readRDS(file.path(WORK,'draws',paste0('DEP_',cc,'.rds')))
 set.seed(dr$seed)
 boot<-array(NA_real_,c(nrow(pt),10,499),dimnames=list(rownames(pt),PVS,NULL))
 for(b in 1:499){mult<-tabulate(sample.int(J,J,replace=TRUE),nbins=J);boot[,,b]<-calcmed(s,mult)$mediation}
 pooled<-pool_any(pt,boot,data.table(CNT=cc))
 cmp<-merge(pooled,old[CNT==cc&exposure=='DEP'],by=c('CNT','term'),suffixes=c('_new','_old'))
 core<-cmp[term!='share'];err<-max(abs(core$estimate_new-core$estimate_old));seerr<-max(abs(core$se_new-core$se_old))
 stopifnot(err<.001,seerr<.001)
 data.table(CNT=cc,point_max_error=err,se_max_error=seerr,bootstrap_draws=499)
})
fwrite(rbindlist(out),file.path(DEST,'audit/original_model_reproduction.csv'));print(rbindlist(out))

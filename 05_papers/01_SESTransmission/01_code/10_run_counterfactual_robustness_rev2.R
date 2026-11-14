# Refit only M2, the model needed by the counterfactual; preserve original M1/M2/S inputs.
source('05_papers/01_SESTransmission/01_code/reporting_rev2.R')
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/engine.R')
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/functions.R')
source('05_papers/01_SESTransmission/01_code/09_counterfactual_robustness_functions.R')

suppressPackageStartupMessages(library(lme4))
WORK<-Sys.getenv('IJED_MEDIATION_WORK','05_papers/01_SESTransmission/04_output/upstream')
DEST<-file.path(OUT,'counterfactual_robustness');dir.create(DEST,showWarnings=FALSE)
B<-499L
# Optional compiled equivalent; the pure-R fallback remains available.
FAST<-FALSE
if(Sys.getenv('IJED_FAST_ML','1')=='1' && requireNamespace('Rcpp',quietly=TRUE) && requireNamespace('RcppArmadillo',quietly=TRUE)) {
 old_env<-Sys.getenv(c('R_MAKEVARS_USER','PKG_LIBS','VECLIB_MAXIMUM_THREADS'),unset=NA)
 if(Sys.info()[['sysname']]=='Darwin') {
  mk<-tempfile();writeLines('FLIBS =',mk)
  Sys.setenv(R_MAKEVARS_USER=mk,PKG_LIBS='-framework Accelerate',VECLIB_MAXIMUM_THREADS='1')
 }
 FAST<-tryCatch({Rcpp::sourceCpp('05_papers/01_SESTransmission/01_code/counterfactual_ml.cpp',cacheDir='/tmp/ijed_cpp_cache',showOutput=FALSE);TRUE},error=function(e){message('Using pure-R ML: ',conditionMessage(e));FALSE})
 for(nm in names(old_env))if(is.na(old_env[[nm]]))Sys.unsetenv(nm)else do.call(Sys.setenv,setNames(list(old_env[[nm]]),nm))
}
cat('Compiled equivalent active:',FAST,'; two worker processes\n')
jobs<-rbindlist(lapply(seq_len(nrow(A[status=='Eligible'&skills==6])),function(i){
 a<-A[status=='Eligible'&skills==6][i]
 variants<-c('unscaled_weights','minimum_10','lmer_unweighted')
 if(a$exposure=='DEP')variants<-c(variants,'core_four','SES_on_deprivation_sample')
 data.table(CNT=a$CNT,source_exposure=a$exposure,variant=variants)
}))
jobs[,job_id:=paste(source_exposure,CNT,variant,sep='_')]
fwrite(jobs,file.path(DEST,'jobs.csv'))
run_one<-function(job) {
 fname<-file.path(DEST,paste0(job$job_id,'.rds'))
 if(file.exists(fname))return(TRUE)
 z<-readRDS(file.path('03_outputs/01_harmonized/input',paste0(job$source_exposure,'_',job$CNT,'.rds')))
 co<-readRDS(file.path(WORK,'compressed',paste0(job$source_exposure,'_',job$CNT,'.rds')))$s
 v<-job$variant;ex<-job$source_exposure;groupvars<-'DEP';variants<-v
 if(v=='minimum_10') {keep<-z$data[,.N,by=school][N>=10,school];z$data<-copy(z$data[school%in%keep])}
 if(v=='core_four') {
  if(!all(is.finite(z$data$DEP_core4))||sd(z$data$DEP_core4)==0) {
   saveRDS(list(skipped=data.table(job,reason='Common-four count unavailable or constant on original analytic sample')),fname);return(TRUE)
  }
  z$data<-copy(z$data);z$data[,status:=DEP_core4]
  groupvars<-c('DEP','DEP_core4');variants<-c('core_four_fixed_groups','core_four_redefined_groups')
 }
 if(v=='SES_on_deprivation_sample') {z$data<-copy(z$data);z$data[,status:=SES_rank];z$controls<-setdiff(z$controls,'ESCS');z$exposure<-'SES';ex<-'SES'}
 if(v=='lmer_unweighted') {d<-co$d;s<-general_compress(d,c('status',z$controls,z$skills));reference_fit<-function(mult)general_fit(s,mult);fit<-if(FAST)function(mult){a<-fast_unweighted_ml(s,mult);rownames(a)<-s$nm;a}else reference_fit}
 else {
  d<-copy(z$data);d[,school:=droplevels(school)];d[,w1:=W_FSTUWT/school_weight]
  if(v!='unscaled_weights')d[,w1:=w1*.N/sum(w1),by=school]
  for(nm in c('status',z$controls,z$skills)) {
   d[,(paste0(nm,'_B')):=wm(get(nm),w1),by=school];d[,(paste0(nm,'_W')):=get(nm)-get(paste0(nm,'_B'))]
  }
  s<-compress_model(d,c('status',z$controls,z$skills),PVS)
  reference_fit<-function(mult)do.call(cbind,lapply(fit_compressed(s,mult),`[[`,'coef'));fit<-if(FAST)function(mult){a<-fast_weighted_ml(s,mult);rownames(a)<-c(s$wn,s$bn);a}else reference_fit
 }
 J<-length(s$n);stopifnot(J>=30)
 mm<-lapply(groupvars,function(g)cf_moments(d,ex,z$skills,g))
 cf<-fit(rep(1,J));pp<-lapply(mm,function(m)cf_predict(cf,m))
 # Independent prediction checks at the pupil level for every alternative and group rule.
 direct_error<-vapply(seq_along(mm),function(i){
  m<-mm[[i]];r<-if(ex=='SES')d$SES_rank<=2.5 else d[[groupvars[i]]]>=1
  h<-if(ex=='SES')d$SES_rank>=7.5 else d[[groupvars[i]]]==0
  w<-d$W_FSTUWT;M<-as.matrix(d[,z$skills,with=FALSE]);mu<-colSums(M*(w*h))/sum(w*h)
  sh<-r*(matrix(mu,nrow(d),length(z$skills),byrow=TRUE)-M);j<-match(as.character(d$school),m$schools)
  db<-unname(rowsum(sh*w,j,reorder=TRUE))/m$wj
  pred<-(sh-db[j,,drop=FALSE])%*%cf[paste0(z$skills,'_W'),]+db[j,,drop=FALSE]%*%cf[paste0(z$skills,'_B'),]
  gap<-colSums(pred*(w*r))/sum(w*r)-colSums(pred*(w*h))/sum(w*h)
  max(abs(gap-pp[[i]]['gap_reduction',]))
 },numeric(1));stopifnot(max(direct_error)<1e-8)
 # Verify the optimized general ML against direct lmer for a varied country set.
 validation<-NULL
 if(FAST) {
  err<-max(abs(cf-reference_fit(rep(1,J))));stopifnot(err<.001)
  validation<-data.table(CNT=job$CNT,exposure=ex,variant=v,method='Compiled versus reference R point fit',max_coefficient_error=err)
 }
 if(v=='lmer_unweighted' && job$CNT%in%c('DNK','KOR','MYS','MNG','DEU','USA','BRA','LBN','PHL','ARM')) {
  pr<-c('status',z$controls,z$skills)
  ff<-as.formula(paste('PV1READ ~',paste(c(paste0(pr,'_W'),paste0(pr,'_B'),'(1|school)'),collapse='+')))
  warnings<-character()
  lm<-withCallingHandlers(lmer(ff,data=d,REML=FALSE),warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')})
  err<-max(abs(cf[names(fixef(lm)),1]-fixef(lm)))
  validation<-rbind(validation,data.table(CNT=job$CNT,exposure=ex,variant=v,method='direct lmer point fit',max_coefficient_error=err,singular=isSingular(lm),warnings=paste(warnings,collapse=';')),fill=TRUE)
  stopifnot(err<.02)
 }
 boot<-lapply(pp,function(p)array(NA_real_,c(nrow(p),10,B),dimnames=list(rownames(p),PVS,NULL)))
 seed<-280926+sum(utf8ToInt(job$CNT)*c(1,100,10000))+if(job$source_exposure=='DEP')1000000L else 0L
 set.seed(seed);failures<-character()
 for(b in seq_len(B)) {
  mult<-tabulate(sample.int(J,J,replace=TRUE),nbins=J)
  vals<-tryCatch({cfb<-fit(mult);if(FAST&&b==1){err<-max(abs(cfb-reference_fit(mult)));stopifnot(err<.001);validation<-rbind(validation,data.table(CNT=job$CNT,exposure=ex,variant=v,method='Compiled versus reference R first bootstrap',max_coefficient_error=err),fill=TRUE)};lapply(mm,function(m)cf_predict(cfb,m,mult))},error=function(e){failures<<-c(failures,paste(b,conditionMessage(e)));NULL})
  if(!is.null(vals))for(i in seq_along(vals))boot[[i]][,,b]<-vals[[i]]
 }
 est<-rbindlist(lapply(seq_along(mm),function(i){
  m<-mm[[i]];meta<-data.table(CNT=job$CNT,economy=d$economy[1],exposure=ex,source_exposure=job$source_exposure,
  variant=variants[i],N=nrow(d),schools=J,recipient_N=m$recipient_N,reference_N=m$reference_N,
  direct_prediction_error=direct_error[i])
  cf_pool(pp[[i]],boot[[i]],meta)
 }))
 saveRDS(list(estimates=est,point=pp,bootstrap=boot,coefficients=cf,seed=seed,
              validation=validation,failures=failures,group_variables=groupvars,compiled_backend=FAST),fname)
 cat(format(Sys.time(),'%H:%M:%S'),job$job_id,'COMPLETE',min(est$bootstrap_valid),'draws\n');flush.console();TRUE
}
res<-parallel::mclapply(seq_len(nrow(jobs)),function(i)tryCatch(run_one(jobs[i]),error=function(e){
 writeLines(conditionMessage(e),file.path(DEST,paste0(jobs$job_id[i],'_ERROR.txt')));cat(jobs$job_id[i],'ERROR',conditionMessage(e),'\n');FALSE}),mc.cores=2,mc.preschedule=FALSE)
stopifnot(all(unlist(res)))
all<-lapply(file.path(DEST,paste0(jobs$job_id,'.rds')),readRDS)
rr<-rbindlist(lapply(all,`[[`,'estimates'),fill=TRUE)
rr[,p_value:=2*pnorm(-abs(estimate/se))]
rr[term=='gap_reduction',q_gap:=p.adjust(p_value,'BH'),by=.(exposure,variant)]
fwrite(rr,file.path(OUT,'tables/equalization_robustness_estimates.csv'))
fwrite(rbindlist(lapply(all,`[[`,'validation'),fill=TRUE),file.path(OUT,'audit/equalization_robustness_engine_validation.csv'))
fwrite(rbindlist(lapply(all,`[[`,'skipped'),fill=TRUE),file.path(OUT,'audit/equalization_robustness_skipped.csv'))
cat('ALL COUNTERFACTUAL ROBUSTNESS JOBS COMPLETE\n')

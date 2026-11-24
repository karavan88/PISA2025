# Grade sensitivity on exactly the existing pupils; paired original bootstrap draws.
library(data.table);setDTthreads(1)
Sys.setenv(VECLIB_MAXIMUM_THREADS='1',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1')
BASE<-Sys.getenv('GRADE_DIAG_OUT','05_papers/01_SESTransmission/04_output/grade_diagnostics_20261117_v2')
OUT<-Sys.getenv('GRADE_CONTROL_OUT','05_papers/01_SESTransmission/04_output/grade_control_20261117_v2');dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
CODE<-'05_papers/01_SESTransmission/01_code/01_grade_diagnostics'
paths<-c(file.path(CODE,c('05_grade_control.R','02_mediation.R')),'05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/engine.R','05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/functions.R','05_papers/01_SESTransmission/01_code/counterfactual_ml.cpp','03_outputs/02_grade_diagnostics/dictionary.rds',list.files(BASE,pattern='^(med_|sample_).*rds$',full.names=TRUE))
sig<-tools::md5sum(paths);sf<-file.path(OUT,'signature.rds');if(file.exists(sf)){stopifnot(identical(sig,readRDS(sf)))}else{stopifnot(!length(list.files(OUT,pattern='^fit_')));saveRDS(sig,sf)}
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/engine.R');source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/functions.R')
# Import only pure fitting helpers: sourcing the estimator would launch a different analysis.
for(e in parse(file.path(CODE,'02_mediation.R')))if(is.call(e)&&identical(e[[1]],as.name('<-'))&&as.character(e[[2]])%in%c('fast','calc'))eval(e)
if(Sys.info()[['sysname']]=='Darwin'){mk<-tempfile();writeLines('FLIBS =',mk);Sys.setenv(R_MAKEVARS_USER=mk,PKG_LIBS='-framework Accelerate')}
Rcpp::sourceCpp('05_papers/01_SESTransmission/01_code/counterfactual_ml.cpp',cacheDir='/tmp/grade_diag_cpp')
DICT<-readRDS('03_outputs/02_grade_diagnostics/dictionary.rds');SUB<-c('All','Never repeated','Urban female non-repeaters','Urban male non-repeaters');B<-499L
gradecalc<-function(s,m){
 for(v in c('med','full')){
  a<-s[[v]];w<-a$w2*m;within<-matrix(colSums(a$xx*w),a$p);between<-crossprod(a$B,(w*a$n)*a$B)
  for(mat in list(within,between)){
   dv<-sqrt(diag(mat));if(any(!is.finite(dv))||any(dv<1e-10))stop('Unidentified bootstrap design')
   scaled<-mat/outer(dv,dv);if(!is.finite(rcond(scaled))||rcond(scaled)<1e-12)stop('Rank-deficient bootstrap design')
  }
 }
 calc(s,m)
}
select_terms<-function(x,delta=x['delta',]){
 rbind(joint_within=x['joint_W',],curiosity_within=x['indW_CURIO',],joint_sorting=(1-delta)*x['joint_W',]+delta*x['joint_B',],curiosity_sorting=(1-delta)*x['indW_CURIO',]+delta*x['indB_CURIO',],sorting_increment=delta*(x['joint_B',]-x['joint_W',]))
}
process_country<-function(cc){
results<-list();fails<-list();validation<-list()
for(ii in 1:4){
 key<-paste0(cc,'_',ii);oldfile<-file.path(BASE,paste0('med_',key,'.rds'));f<-file.path(OUT,paste0('fit_',key,'.rds'))
 if(!file.exists(oldfile))next
 if(file.exists(f)){r<-readRDS(f);results[[key]]<-r$summary;validation[[key]]<-r$validation;next}
 d<-readRDS(file.path(BASE,paste0('sample_',key,'.rds')));old<-readRDS(oldfile)
 stopifnot(all(is.finite(d$grade)),nrow(d)==unique(old$summary$N));d[,school:=factor(school)];d[,AGE:=age_months/12]
 ctr<-c('AGE',if(sd(d$nonmale)>1e-8)'nonmale')
 res<-tryCatch({
  original<-prepare_model(list(data=d,skills=DICT$skills,controls=ctr,exposure='SES'))
  s<-prepare_model(list(data=d,skills=DICT$skills,controls=c(ctr,'grade'),exposure='SES'))
  stopifnot(identical(s$base$schools,original$base$schools))
  baseline_error<-max(abs(calc(original,rep(1,length(s$base$n)))-old$point));stopifnot(baseline_error<1e-6)
  rawpoint<-gradecalc(s,rep(1,length(s$base$n)));ref<-evaluate_model(s);engine_error<-max(abs(rawpoint-ref[rownames(rawpoint),]));stopifnot(engine_error<1e-5)
  point<-select_terms(rawpoint);baseline<-select_terms(old$point);fixedpoint<-select_terms(rawpoint,old$point['delta',])
  boot<-fixedboot<-array(NA_real_,c(5,10,B),dimnames=list(rownames(point),PVS,NULL));baseboot<-boot
  J<-length(s$base$n);stratum<-as.character(s$base$strata);stratum[is.na(stratum)|stratum=='']<-'Unreported';strata<-split(seq_len(J),stratum)
  stopifnot(old$seed==701117+match(cc,DICT$countries$CNT)*10+ii);set.seed(old$seed);pair_error<-0
  for(b in seq_len(B)){
   ids<-unlist(lapply(strata,function(ix)ix[sample.int(length(ix),length(ix),replace=TRUE)]),use.names=FALSE);mult<-tabulate(ids,nbins=J)
   if(b<=2){errors<-abs(calc(original,mult)-old$draws[,,b]);stopifnot(any(is.finite(errors)));er<-max(errors,na.rm=TRUE);pair_error<-max(pair_error,er);stopifnot(er<1e-6)}
   baseboot[,,b]<-select_terms(old$draws[,,b])
   raw<-tryCatch(gradecalc(s,mult),error=function(e)NULL)
   if(!is.null(raw)){boot[,,b]<-select_terms(raw);fixedboot[,,b]<-select_terms(raw,old$draws['delta',,b])}
  }
  # All three estimates and their change use the same successful bootstrap resamples.
  ok<-vapply(1:B,function(b)all(is.finite(boot[,,b]))&&all(is.finite(baseboot[,,b]))&&all(is.finite(fixedboot[,,b])),logical(1));stopifnot(sum(ok)>=.95*B)
  values<-list(baseline=list(p=baseline,b=baseboot),grade_adjusted=list(p=point,b=boot),change=list(p=point-baseline,b=boot-baseboot),grade_fixed_sorting=list(p=fixedpoint,b=fixedboot),change_fixed_sorting=list(p=fixedpoint-baseline,b=fixedboot-baseboot))
  rr<-rbindlist(lapply(names(values),function(n){v<-values[[n]];a<-pool_model(v$p,v$b[,,ok,drop=FALSE],cc,s);a[,`:=`(sample=SUB[ii],specification=n)];a}))
  vv<-data.table(CNT=cc,sample=SUB[ii],N=nrow(d),schools=J,valid_draws=sum(ok),baseline_error,engine_error,pair_error)
  saveRDS(list(summary=rr,validation=vv,point=rawpoint,selected_draws=boot,fixed_sorting_draws=fixedboot,valid=ok,seed=old$seed),f)
  results[[key]]<-rr;validation[[key]]<-vv;TRUE
 },error=function(e){fails[[key]]<<-data.table(CNT=cc,sample=SUB[ii],reason=conditionMessage(e));FALSE})
 cat(key,if(res)'complete'else'not estimable','\n');flush.console()
}
list(results=results,fails=fails,validation=validation)
}
jobs<-parallel::mclapply(DICT$countries$CNT,process_country,mc.cores=2L,mc.preschedule=FALSE)
stopifnot(!any(vapply(jobs,inherits,logical(1),'try-error')))
results<-unlist(lapply(jobs,`[[`,'results'),recursive=FALSE);fails<-unlist(lapply(jobs,`[[`,'fails'),recursive=FALSE);validation<-unlist(lapply(jobs,`[[`,'validation'),recursive=FALSE)
E<-rbindlist(results);E[,p:=2*pnorm(-abs(estimate/se))];E[,q:=p.adjust(p,'BH'),by=.(term,sample,specification)]
fwrite(E,file.path(OUT,'comparison.csv'));fwrite(rbindlist(validation),file.path(OUT,'validation.csv'));fwrite(if(length(fails))rbindlist(fails)else data.table(CNT=character(),sample=character(),reason=character()),file.path(OUT,'failures.csv'))

library(data.table);setDTthreads(1)
Sys.setenv(VECLIB_MAXIMUM_THREADS='1',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1')
OUT<-Sys.getenv('GRADE_DIAG_OUT','05_papers/01_SESTransmission/04_output/grade_diagnostics_20261117_v2')
source('05_papers/01_SESTransmission/01_code/01_grade_diagnostics/guard.R');guard_stage('mediation')
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/engine.R')
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/functions.R')
if(Sys.info()[['sysname']]=='Darwin'){mk<-tempfile();writeLines('FLIBS =',mk);Sys.setenv(R_MAKEVARS_USER=mk,PKG_LIBS='-framework Accelerate')}
Rcpp::sourceCpp('05_papers/01_SESTransmission/01_code/counterfactual_ml.cpp',cacheDir='/tmp/grade_diag_cpp')
DICT<-readRDS('03_outputs/02_grade_diagnostics/dictionary.rds');SUB<-c('All','Never repeated','Urban female non-repeaters','Urban male non-repeaters')
fast<-function(x,m){a<-fast_weighted_ml(x,m);dimnames(a)<-list(c(x$wn,x$bn),x$outcomes);a}
calc<-function(s,m){
 a<-fast(s$med,m);b<-fast(s$full,m);base<-fast(s$base,m)
 k<-length(s$sortnames);dd<-solve(matrix(colSums(s$sortxx*m),k),colSums(s$sortxy*m));delta<-unname(dd[match('status',s$sortnames)])
 aw<-a['status_W',];ab<-a['status_B',];iw<-b[paste0(s$sk,'_W'),,drop=FALSE]*aw;ib<-b[paste0(s$sk,'_B'),,drop=FALSE]*ab
 ans<-rbind(joint_W=colSums(iw),joint_B=colSums(ib),skills_sorting=colSums((1-delta)*iw+delta*ib),sorting_increment=delta*colSums(ib-iw),base_W=base['status_W',],base_B=base['status_B',],delta=rep(delta,10))
 rownames(iw)<-paste0('indW_',s$sk);rownames(ib)<-paste0('indB_',s$sk)
 rbind(ans,iw,ib)
}
B<-499L;results<-list();fails<-list();checks<-list()
for(cc in DICT$countries$CNT)for(ii in seq_along(SUB)){
 key<-paste0(cc,'_',ii);file<-file.path(OUT,paste0('med_',key,'.rds'))
 if(file.exists(file)){results[[key]]<-readRDS(file)$summary;next}
 d<-readRDS(file.path(OUT,paste0('sample_',key,'.rds')))
 if(nrow(d)<200||uniqueN(d$school)<20){fails[[key]]<-data.table(CNT=cc,sample=SUB[ii],reason='Fewer than 200 pupils or 20 schools');next}
 d[,school:=factor(school)];d[,AGE:=age_months/12]
 controls<-c('AGE',if(sd(d$nonmale)>1e-8)'nonmale')
 z<-list(data=d,skills=DICT$skills,controls=controls,exposure='SES')
 res<-tryCatch({
  s<-prepare_model(z);point<-calc(s,rep(1,length(s$base$n)))
  if(length(checks)<3){reference<-evaluate_model(s);err<-max(abs(point-reference[rownames(point),]));stopifnot(err<1e-5);checks[[key]]<-data.table(CNT=cc,sample=SUB[ii],max_difference=err)}
  set.seed(701117+match(cc,DICT$countries$CNT)*10+ii)
  boot<-array(NA_real_,c(nrow(point),10,B),dimnames=list(rownames(point),PVS,NULL));J<-length(s$base$n)
  # Stratified school bootstrap, preserving each observed stratum's school count.
  stratum<-as.character(s$base$strata);stratum[is.na(stratum)|stratum=='']<-'Unreported';strata<-split(seq_len(J),stratum)
  for(b in seq_len(B)){
   ids<-unlist(lapply(strata,function(ix)ix[sample.int(length(ix),length(ix),replace=TRUE)]),use.names=FALSE);mult<-tabulate(ids,nbins=J)
   boot[,,b]<-tryCatch(calc(s,mult),error=function(e)matrix(NA_real_,nrow(point),10))
  }
  out<-pool_model(point,boot,cc,s);out[,sample:=SUB[ii]]
  saveRDS(list(summary=out,point=point,draws=boot,seed=701117+match(cc,DICT$countries$CNT)*10+ii),file)
  out
 },error=function(e){fails[[key]]<<-data.table(CNT=cc,sample=SUB[ii],reason=conditionMessage(e));NULL})
 if(!is.null(res))results[[key]]<-res
 cat(key,if(is.null(res))'failed'else'complete','\n');flush.console()
}
E<-rbindlist(results,fill=TRUE);E[,p:=2*pnorm(-abs(estimate/se))];E[,q:=p.adjust(p,'BH'),by=.(sample,term)]
fwrite(E,file.path(OUT,'mediation.csv'));fwrite(rbindlist(fails,fill=TRUE),file.path(OUT,'mediation_failures.csv'));if(length(checks))fwrite(rbindlist(checks),file.path(OUT,'mediation_validation.csv')) else if(!file.exists(file.path(OUT,'mediation_validation.csv')))stop('Cached run lacks validation evidence')

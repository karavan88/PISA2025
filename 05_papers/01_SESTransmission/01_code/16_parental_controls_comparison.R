# Paired comparison on identical deprivation pupils: parental education/occupation vs ESCS.
# No manuscript files or original model caches are modified.
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/engine.R')
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/functions.R')
source('05_papers/01_SESTransmission/01_code/09_counterfactual_robustness_functions.R')
library(haven)
ROOT<-normalizePath(getwd()); BASE<-file.path(ROOT,'05_papers/01_SESTransmission/04_output')
DEST<-file.path(BASE,'parental_controls_comparison');dir.create(DEST,recursive=TRUE,showWarnings=FALSE)
for(n in c('inputs','fits','tables','audit','figures'))dir.create(file.path(DEST,n),showWarnings=FALSE)
WORK<-Sys.getenv('IJED_MEDIATION_WORK','05_papers/01_SESTransmission/04_output/upstream')
B<-499L
A<-fread(file.path(BASE,'input/eligibility.csv'))[exposure=='DEP' & status=='Eligible' & skills==6 & !CNT%in%c('QUA','UKR')]
stopifnot(nrow(A)==62)
papers<-file.path(ROOT,'05_papers/01_SESTransmission/03_manuscript',c('ijed_ses_seg_rev2.qmd','ijed_ses_seg_rev2.pdf','ijed_ses_seg_supplement_rev2.qmd','ijed_ses_seg_supplement_rev2.pdf'))
if(!file.exists(file.path(DEST,'audit/manuscript_hashes_before.csv')))fwrite(data.table(path=papers,md5=unname(tools::md5sum(papers))),file.path(DEST,'audit/manuscript_hashes_before.csv'))
parentfile<-'03_outputs/01_harmonized/parental_background.rds'
if(!file.exists(parentfile)) stop('Run the central data build first.')
parents<-readRDS(parentfile)
# Compile the independently validated equivalent of the archived weighted ML engine.
Sys.setenv(VECLIB_MAXIMUM_THREADS='1',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1')
if(Sys.info()[['sysname']]=='Darwin') {mk<-tempfile();writeLines('FLIBS =',mk);Sys.setenv(R_MAKEVARS_USER=mk,PKG_LIBS='-framework Accelerate')}
Rcpp::sourceCpp('05_papers/01_SESTransmission/01_code/counterfactual_ml.cpp',cacheDir='/tmp/ijed_cpp_cache',showOutput=FALSE)
fastcoef<-function(s,mult) {x<-fast_weighted_ml(s,mult);dimnames(x)<-list(c(s$wn,s$bn),s$outcomes);stopifnot(all(is.finite(x)));x}
# Same fixed-slope mediation estimands as evaluate_model(); residual-bias stress scales
# are not part of this control-specification comparison.
calcmed<-function(s,mult=rep(1,length(s$base$n))) {
 m<-fastcoef(s$med,mult); f<-fastcoef(s$full,mult); base<-fastcoef(s$base,mult)
 pz<-length(s$sortnames);dd<-solve(matrix(colSums(s$sortxx*mult),pz),colSums(s$sortxy*mult))
 delta<-unname(dd[match('status',s$sortnames)])
 aw<-m['status_W',];ab<-m['status_B',];bw<-f[paste0(s$sk,'_W'),,drop=FALSE];bb<-f[paste0(s$sk,'_B'),,drop=FALSE]
 iw<-aw*bw;ib<-ab*bb;jw<-colSums(iw);jb<-colSums(ib);js<-(1-delta)*jw+delta*jb
 rem<-(1-delta)*f['status_W',]+delta*f['status_B',];total<-rem+js
 out<-rbind(delta=rep(delta,10),joint_W=jw,joint_B=jb,skills_same_school=jw,skills_sorting=js,sorting_increment=js-jw,
 within_allocation=(1-delta)*jw,between_allocation=delta*jb,remaining=rem,total=total,share=100*js/total,
 total_fixed=f['status_W',]+jw,total_sorting_increment=total-f['status_W',]-jw,
 remaining_sorting_increment=delta*(f['status_B',]-f['status_W',]),
 skill_level_sorting=delta*colSums((ab-aw)*bw),skill_context_sorting=delta*colSums(ab*(bb-bw)),
 baseline_profile=(1-delta)*base['status_W',]+delta*base['status_B',],base_W=base['status_W',],base_B=base['status_B',],
 full_W=f['status_W',],full_B=f['status_B',])
 add<-function(x,pre) {if(is.null(dim(x)))x<-matrix(x,nrow=6,ncol=10);rownames(x)<-paste0(pre,s$sk);x}
 out<-rbind(out,add(aw,'aW_'),add(ab,'aB_'),add(bw,'bW_'),add(bb,'bB_'),add(iw,'indW_'),add(ib,'indB_'),add((1-delta)*iw+delta*ib,'indS_'))
 list(mediation=out,coefficients=f)
}
pool_any<-function(point,boot,meta) {
 core<-setdiff(rownames(point),c('share','gap_fraction'));ok<-apply(boot[core,,,drop=FALSE],3,function(x)all(is.finite(x)))
 stopifnot(sum(ok)>=.95*B);boot<-boot[,,ok,drop=FALSE]
 sv<-rowMeans(apply(boot,c(1,2),function(x)if(sum(is.finite(x))>=.95*length(x))var(x[is.finite(x)])else NA_real_));pv<-1.1*apply(point,1,var)
 z<-data.table(term=rownames(point),estimate=rowMeans(point),sampling_se=sqrt(sv),pv_se=sqrt(pv),se=sqrt(sv+pv),bootstrap_valid=sum(ok))
 z[,`:=`(lower=estimate-1.96*se,upper=estimate+1.96*se,p_value=2*pnorm(-abs(estimate/se)))]
 cbind(meta,z)
}
run_country<-function(cc) {
 fn<-file.path(DEST,'fits',paste0(cc,'.rds'));if(file.exists(fn))return(TRUE)
 z<-readRDS(file.path('03_outputs/01_harmonized/input',paste0('DEP_',cc,'.rds')))
 originalN<-nrow(z$data);d<-merge(z$data,parents,by='CNTSTUID',all.x=TRUE)
 stopifnot(nrow(d)==originalN);d<-d[is.finite(PAREDINT)&is.finite(HISEI)]
 stopifnot(nrow(d)>=100,uniqueN(d$school)>=30)
 d[,school:=droplevels(school)];z$data<-d
 specs<-c('ESCS_same_pupils','Parental_background')
 ss<-lapply(specs,function(v){zz<-z;zz$controls<-if(v=='ESCS_same_pupils')c('nonmale','AGE','ESCS')else c('nonmale','AGE','PAREDINT','HISEI');prepare_model(zz)})
 names(ss)<-specs;J<-length(ss[[1]]$base$n)
 stopifnot(identical(ss[[1]]$d$CNTSTUID,ss[[2]]$d$CNTSTUID),identical(ss[[1]]$base$schools,ss[[2]]$base$schools),identical(ss[[1]]$d$w1,ss[[2]]$d$w1))
 moments<-cf_moments(ss[[1]]$d,'DEP',z$skills)
 stopifnot(identical(moments$schools,ss[[1]]$base$schools))
 fit<-function(i,mult){v<-calcmed(ss[[i]],mult);list(mediation=v$mediation,counterfactual=cf_predict(v$coefficients,moments,mult))}
 pt<-lapply(1:2,function(i)fit(i,rep(1,J)))
 # Validate all point mediation quantities against original R engine.
 validation<-rbindlist(lapply(1:2,function(i){ref<-evaluate_model(ss[[i]]);diff<-abs(pt[[i]]$mediation-ref[rownames(pt[[i]]$mediation),]);err<-max(diff[setdiff(rownames(diff),'share'),]);relative_error<-max(diff/(1+abs(ref[rownames(pt[[i]]$mediation),])));stopifnot(err<.001,relative_error<1e-4)
 # Independent unit-profile predictions verify the mediation definition.
 pred<-prediction_check(ss[[i]],pt[[i]]$mediation['delta',1]);pe<-max(abs(pred['indirect',]-pt[[i]]$mediation['skills_sorting',]));stopifnot(pe<.001)
 data.table(CNT=cc,specification=specs[i],reference_R_max_error=err,prediction_error=pe)}))
 # Direct pupil-level replacement, independent of compressed group-moment expression.
 for(i in 1:2){s<-ss[[i]];cf<-fastcoef(s$full,rep(1,J));dd<-s$d;w<-dd$W_FSTUWT;r<-dd$DEP>=1;h<-dd$DEP==0
 M<-as.matrix(dd[,z$skills,with=FALSE]);mu<-colSums(M*(w*h))/sum(w*h);change<-r*(matrix(mu,nrow(dd),6,byrow=TRUE)-M)
 j<-match(as.character(dd$school),moments$schools);db<-unname(rowsum(change*w,j,reorder=TRUE))/moments$wj
 pr<-(change-db[j,,drop=FALSE])%*%cf[paste0(z$skills,'_W'),]+db[j,,drop=FALSE]%*%cf[paste0(z$skills,'_B'),]
 gap<-colSums(pr*(w*r))/sum(w*r)-colSums(pr*(w*h))/sum(w*h)
 stopifnot(max(abs(gap-pt[[i]]$counterfactual['gap_reduction',]))<1e-8)}
 boot<-lapply(pt,function(v)lapply(v,function(x)array(NA_real_,c(nrow(x),10,B),dimnames=list(rownames(x),PVS,NULL))))
 seed<-281113+sum(utf8ToInt(cc)*c(1,100,10000));set.seed(seed);failures<-character()
 start<-proc.time()[3]
 for(b in seq_len(B)) {
  mult<-tabulate(sample.int(J,J,replace=TRUE),nbins=J)
  vals<-tryCatch(lapply(1:2,function(i)fit(i,mult)),error=function(e){failures<<-c(failures,paste(b,conditionMessage(e)));NULL})
  if(!is.null(vals))for(i in 1:2)for(k in names(vals[[i]]))boot[[i]][[k]][,,b]<-vals[[i]][[k]]
  if(b%%100==0){cat(format(Sys.time(),'%H:%M:%S'),cc,b,'/',B,'paired draws;',round(proc.time()[3]-start,1),'seconds\n');flush.console()}
 }
 estimates<-rbindlist(lapply(1:2,function(i)rbindlist(lapply(names(pt[[i]]),function(k)pool_any(pt[[i]][[k]],boot[[i]][[k]],data.table(CNT=cc,economy=d$economy[1],specification=specs[i],estimand=k,N=nrow(d),schools=J))))))
 # Paired contrast, parental-background minus ESCS, with both models on each same resample.
 differences<-rbindlist(lapply(names(pt[[1]]),function(k)pool_any(pt[[2]][[k]]-pt[[1]][[k]],boot[[2]][[k]]-boot[[1]][[k]],data.table(CNT=cc,economy=d$economy[1],estimand=k,N=nrow(d),schools=J))))
 coverage<-data.table(CNT=cc,economy=d$economy[1],original_N=originalN,matched_N=nrow(d),retained_share=nrow(d)/originalN,schools=J,recipient_N=moments$recipient_N,reference_N=moments$reference_N)
 errfile<-file.path(DEST,'audit',paste0(cc,'_ERROR.txt'));if(file.exists(errfile))unlink(errfile)
 saveRDS(list(estimates=estimates,differences=differences,coverage=coverage,validation=validation,point=pt,bootstrap=boot,seed=seed,failures=failures,controls=list(ESCS_same_pupils=ss[[1]]$controls,Parental_background=ss[[2]]$controls)),fn)
 cat(format(Sys.time(),'%H:%M:%S'),cc,'COMPLETE',min(estimates$bootstrap_valid),'paired draws\n');flush.console();TRUE
}
if(Sys.getenv('IJED_COMPARE_DEFINE_ONLY','0')!='1') {
ids<-A$CNT
if(nzchar(Sys.getenv('IJED_COMPARE_COUNTRIES')))ids<-intersect(ids,strsplit(Sys.getenv('IJED_COMPARE_COUNTRIES'),',')[[1]])
# Two worker processes; common resamples within each country preserve paired inference.
ans<-parallel::mclapply(ids,function(cc)tryCatch(run_country(cc),error=function(e){writeLines(conditionMessage(e),file.path(DEST,'audit',paste0(cc,'_ERROR.txt')));cat(cc,'ERROR',conditionMessage(e),'\n');FALSE}),mc.cores=2,mc.preschedule=FALSE)
stopifnot(all(unlist(ans)))
res<-lapply(file.path(DEST,'fits',paste0(ids,'.rds')),readRDS)
for(nm in c('estimates','differences','coverage','validation'))fwrite(rbindlist(lapply(res,`[[`,nm)),file.path(DEST,'tables',paste0(nm,'.csv')))
old<-fread(file.path(DEST,'audit/manuscript_hashes_before.csv'));stopifnot(identical(old$md5,unname(tools::md5sum(old$path))))
cat('PAIRED COMPARISON COMPLETE:',length(ids),'countries. Manuscript hashes unchanged.\n')

}

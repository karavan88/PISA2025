source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/engine.R');source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/functions.R')
WORK<-Sys.getenv('GM_WORK','05_papers/01_SESTransmission/04_output/upstream');OUT<-'05_papers/01_SESTransmission/04_output/input'
dir.create(file.path(WORK,'draws'),showWarnings=FALSE)
dir.create(file.path(OUT,'countries'),showWarnings=FALSE)
jobs<-fread(file.path(OUT,'jobs.csv'))
if(nzchar(Sys.getenv('GM_JOBS')))jobs<-jobs[job_id%in%strsplit(Sys.getenv('GM_JOBS'),',')[[1]]]
B<-as.integer(Sys.getenv('GM_BOOTSTRAPS','499'))
run_one<-function(job_id) {
  ix<-which(jobs$job_id==job_id);job<-jobs[ix];stopifnot(nrow(job)==1)
  obj<-readRDS(file.path(WORK,'compressed',paste0(job_id,'.rds')));s<-obj$s;point<-obj$point
  seed<-280926+sum(utf8ToInt(job$CNT)*c(1,100,10000))+if(job$exposure=='DEP')1000000L else 0L
  set.seed(seed);J<-length(s$base$n)
  boot<-array(NA_real_,c(nrow(point),10,B),dimnames=list(rownames(point),PVS,NULL))
  failures<-character()
  for(b in seq_len(B)) {
    mult<-tabulate(sample.int(J,J,replace=TRUE),nbins=J)
    v<-tryCatch(evaluate_model(s,mult),error=function(e){failures<<-c(failures,conditionMessage(e));NULL})
    if(!is.null(v))boot[,,b]<-v
  }
  out<-pool_model(point,boot,job$CNT,s)
  saveRDS(list(point=point,bootstrap=boot,failures=failures,seed=seed),file.path(WORK,'draws',paste0(job_id,'.rds')))
  fwrite(out,file.path(OUT,'countries',paste0(job_id,'.csv')))
  cat(format(Sys.time(),'%H:%M:%S'),job_id,'COMPLETE',out$bootstrap_valid[1],'draws\n');flush.console()
  TRUE
}
pending<-jobs[!file.exists(file.path(OUT,'countries',paste0(job_id,'.csv')))|
              !file.exists(file.path(WORK,'draws',paste0(job_id,'.rds'))),job_id]
res<-parallel::mclapply(pending,function(id)tryCatch(run_one(id),error=function(e){writeLines(conditionMessage(e),file.path(WORK,paste0(id,'_ERROR.txt')));cat(id,'ERROR',conditionMessage(e),'\n');FALSE}),mc.cores=2,mc.preschedule=FALSE)
allfiles<-file.path(OUT,'countries',paste0(jobs$job_id,'.csv'))
stopifnot(all(file.exists(allfiles)),all(unlist(res)))
fwrite(rbindlist(lapply(allfiles,fread)),file.path(OUT,'estimates.csv'))
cat('ALL',nrow(jobs),'COUNTRY-EXPOSURE FITS COMPLETE\n')

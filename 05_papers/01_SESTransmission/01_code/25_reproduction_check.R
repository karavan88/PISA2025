# Refit point estimates from rebuilt inputs and reproduce a small seeded bootstrap.
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/engine.R')
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/functions.R')
work<-'05_papers/01_SESTransmission/04_output/upstream'
files<-list.files('03_outputs/01_harmonized/input',pattern='\\.rds$',full.names=TRUE)
checks<-list()
for(f in files){
 id<-sub('\\.rds$','',basename(f));z<-readRDS(f);s<-prepare_model(z);p<-evaluate_model(s)
 old<-readRDS(file.path(work,'draws',paste0(id,'.rds')))
 err<-max(abs(p-old$point));stopifnot(err<1e-7)
 booterr<-NA_real_
 if(id%in%c('SES_KOR','DEP_KOR')){
  set.seed(old$seed);J<-length(s$base$n);errs<-numeric(5)
  for(b in 1:5){mult<-tabulate(sample.int(J,J,replace=TRUE),nbins=J);v<-evaluate_model(s,mult);errs[b]<-max(abs(v-old$bootstrap[,,b]))}
  booterr<-max(errs);stopifnot(booterr<1e-7)
 }
 checks[[id]]<-data.table(job_id=id,point_max_error=err,first_5_draws_max_error=booterr)
 cat(id,'point verified\n');flush.console()
}
out<-'05_papers/01_SESTransmission/04_output/00_logs/reproduction_points.csv'
fwrite(rbindlist(checks),out)
cat('PASS:',length(checks),'fresh point fits and 2 seeded 5-draw bootstrap checks.\n')

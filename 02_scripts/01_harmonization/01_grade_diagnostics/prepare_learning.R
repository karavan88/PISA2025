library(data.table);setDTthreads(1)
BASE<-'05_papers/01_SESTransmission/04_output/grade_diagnostics_20261117_v2';OUT<-'03_outputs/03_learning_diagnostics';dir.create(OUT,showWarnings=FALSE)
x<-readRDS('03_outputs/01_harmonized/cutoff_provider.rds');pv<-paste0('PV',1:10,'MATH');x<-as.data.table(x[,c('CNT','CNTSTUID',pv)]);x[,`:=`(CNT=as.character(CNT),CNTSTUID=as.character(CNTSTUID))];for(v in pv)set(x,j=v,value=as.numeric(x[[v]]));stopifnot(!anyDuplicated(x[,.(CNT,CNTSTUID)]))
audit<-list()
for(f in list.files(BASE,pattern='^sample_.*rds$',full.names=TRUE)){
 d<-readRDS(f);d[,CNTSTUID:=as.character(CNTSTUID)];ids<-d[,.(CNT,CNTSTUID)];d<-merge(d,x,by=c('CNT','CNTSTUID'),all.x=TRUE,sort=FALSE)
 stopifnot(nrow(d)==nrow(ids),!anyDuplicated(d[,.(CNT,CNTSTUID)]));missing<-sum(!complete.cases(d[,..pv]));if(missing)stop(basename(f),': math missing for ',missing,' original pupils; preserve same-pupil requirement')
 saveRDS(d,file.path(OUT,basename(f)));audit[[basename(f)]]<-data.table(file=basename(f),N=nrow(d),missing_math=missing)
}
fwrite(rbindlist(audit),file.path(OUT,'sample_audit.csv'))

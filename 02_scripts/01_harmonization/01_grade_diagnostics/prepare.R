library(data.table);library(haven);setDTthreads(1)
out<-'03_outputs/02_grade_diagnostics';dir.create(out,showWarnings=FALSE)
S<-c('PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG');PV<-paste0('PV',1:10,'READ');RW<-paste0('W_FSTURWT',1:80)
a<-fread('05_papers/01_SESTransmission/02_results/rev2/tables/analysis_sample.csv')[exposure=='SES',.(CNT,economy)]
stopifnot(nrow(a)==67,!any(a$CNT%in%c('ISR','UKR','QUA')))
x<-readRDS('03_outputs/01_harmonized/cutoff_provider.rds')
needed<-c('CNT','CNTSTUID','ST001D01T','REPEAT','ST004D01T',RW)
x<-as.data.table(lapply(x[,needed],function(v)if(is.character(v))as.character(v)else as.numeric(v)))
x[,CNTSTUID:=as.character(CNTSTUID)];stopifnot(!anyDuplicated(x[,.(CNT,CNTSTUID)]))
d<-readRDS('03_outputs/01_harmonized/all_data.rds')[CNT%in%a$CNT]
d[,CNTSTUID:=as.character(CNTSTUID)]
d<-merge(d,x,by=c('CNT','CNTSTUID'),all.x=TRUE,suffixes=c('','_sampling'))
# The school questionnaire measures school location, not the pupil's residence.
s<-read_sav(file.path(Sys.getenv('PISA_DATA','01_data'),'CY09_MS_SCH_PUF.sav'),col_select=c('CNT','CNTSCHID','SC001Q01TA'))
loclabels<-attr(s$SC001Q01TA,'labels');s<-as.data.table(lapply(s,function(v)if(is.character(v))as.character(v)else as.numeric(v)))
s[,school:=as.character(as.integer(CNTSCHID))];stopifnot(!anyDuplicated(s[,.(CNT,school)]))
d<-merge(d,s[,.(CNT,school,location=SC001Q01TA)],by=c('CNT','school'),all.x=TRUE)
d[,`:=`(grade=ST001D01T,never_repeat=fifelse(REPEAT%in%0:1,REPEAT==0,NA),urban=fifelse(location%in%1:6,location>=4,NA),female_sampling=fifelse(ST004D01T%in%c(1,2),ST004D01T==1,NA),age_months=(AGE-15)*12)]
d[,Reading:=rowMeans(.SD),.SDcols=PV]
cal<-list()
for(cc in a$CNT){
 obj<-readRDS(paste0('03_outputs/01_harmonized/input/SES_',cc,'.rds'));ids<-as.character(obj$data$CNTSTUID)
 ix<-which(d$CNT==cc);d[ix,in_paper:=CNTSTUID%in%ids]
 z<-d[ix][in_paper==TRUE]
 for(k in S){mu<-weighted.mean(z[[k]],z$W_FSTUWT);sd<-sqrt(weighted.mean((z[[k]]-mu)^2,z$W_FSTUWT));d[ix,(k):=(get(k)-mu)/sd];cal[[paste(cc,k)]]<-data.table(CNT=cc,skill=k,mean=mu,SD=sd)}
 check<-merge(d[ix][in_paper==TRUE],as.data.table(obj$data)[,c('CNTSTUID',S),with=FALSE][,CNTSTUID:=as.character(CNTSTUID)],by='CNTSTUID',suffixes=c('','_old'))
 stopifnot(nrow(check)==nrow(obj$data),max(abs(as.matrix(check[,..S])-as.matrix(check[,paste0(S,'_old'),with=FALSE])))<1e-9)
}
d[,w2:=school_weight/mean(unique(school_weight)),by=CNT]
saveRDS(d,file.path(out,'pupils.rds'));saveRDS(list(countries=a,calibration=rbindlist(cal),location_labels=loclabels,urban_definition='School located in a city of at least 100,000 people (SC001Q01TA categories 4–6).',skills=S),file.path(out,'dictionary.rds'))
cat(nrow(d),'source pupils; ',sum(d$in_paper),'original-paper pupils; 67 systems.\n')

# Reconstruct the preceding global sample directly from the two local SPSS inputs.
suppressPackageStartupMessages({library(haven);library(data.table)})
invisible(Sys.setlocale('LC_CTYPE','en_US.UTF-8'));setDTthreads(1)
WORK<-'03_outputs/01_harmonized';OUT<-'03_outputs/01_harmonized/metadata'
dir.create(WORK,recursive=TRUE,showWarnings=FALSE);dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
base<-Sys.getenv('PISA_DATA','01_data')
skall<-c('PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG');pv<-paste0('PV',1:10,'READ')
items<-c('ST488Q01DA','ST488Q02DA','ST488Q08DA','ST488Q09DA',paste0('ST401Q0',3:7,'DA'))
cols<-c('CNT','CNTSTUID','CNTSCHID','STRATUM','OECD','ESCS','PAREDINT','HISEI','ST004D01T','MALE','AGE',skall,'W_FSTUWT',pv,items)
rdcols<-unique(c('CNT','CNTSCHID','CNTSTUID','STRATUM','OECD','ST001D01T','ISCEDP','ST003D02T','ST003D03T','AGE','REPEAT','ST004D01T','ST022Q01TA','IMMIG','ESCS',skall,'BELONG','ST420Q01DA','W_FSTUWT','SENWT',paste0('W_FSTURWT',1:80),unlist(lapply(c('SCIE','MATH','READ'),function(v)paste0('PV',1:10,v)))))
x<-read_sav(file.path(base,'CY09_MS_STU_PUF.sav'),col_select=all_of(unique(c(cols,rdcols))))
# Both designs share this one provider read; keep mediation's original schema.
saveRDS(x[,rdcols],file.path(WORK,'cutoff_provider.rds'))
x<-x[,cols]
lab<-attr(x$CNT,'labels');econ<-setNames(names(lab),as.character(lab))
saveRDS(lapply(x[,c('CNT','CNTSTUID',items)],attributes),file.path(WORK,'deprivation_metadata.rds'))
d<-as.data.table(lapply(x,function(v)if(is.character(v))as.character(v)else as.numeric(v)));rm(x);gc()
saveRDS(d[,c('CNT','CNTSTUID',items),with=FALSE],file.path(WORK,'deprivation_raw.rds'))
saveRDS(d[,.(CNTSTUID=as.character(CNTSTUID),PAREDINT,HISEI)],file.path(WORK,'parental_background.rds'))
d[,(items):=NULL]
d[,economy:=unname(econ[CNT])];d[,school:=as.character(as.integer(CNTSCHID))]
d[,female:=fifelse(is.na(ST004D01T),NA_real_,as.numeric(ST004D01T==1))]
d[,nonmale:=fifelse(MALE%in%c(0,1),1-MALE,female)]
s<-read_sav(file.path(base,'CY09_MS_SCH_PUF.sav'),col_select=c('CNT','CNTSCHID','W_NRASCHBWT'))
s<-as.data.table(lapply(s,function(v)if(is.character(v))as.character(v)else as.numeric(v)))
s[,school:=as.character(as.integer(CNTSCHID))];setnames(s,'W_NRASCHBWT','school_weight')
stopifnot(!anyDuplicated(s[,.(CNT,school)]))
d<-merge(d,s[,-'CNTSCHID'],by=c('CNT','school'),all.x=TRUE,sort=FALSE)
wrank<-function(x,w){z<-data.table(x=x,w=w);q<-z[is.finite(x)&is.finite(w)&w>0,.(sw=sum(w)),by=x][order(x)];q[,rank:=100*(cumsum(sw)-sw/2)/sum(sw)];q[z,on='x']$rank}
wm<-function(x,w)sum(x*w)/sum(w)
d[,status:=wrank(ESCS,W_FSTUWT)/10,by=CNT]
saveRDS(d,file.path(WORK,'all_data.rds'))
dat<-list();audit<-list()
for(cc in sort(unique(d$CNT))) {
 z<-d[CNT==cc];sk<-skall[vapply(z[,..skall],function(x)any(is.finite(x)),logical(1))]
 controls<-c('nonmale','AGE');controls<-controls[vapply(z[,..controls],function(x)any(is.finite(x))&&sd(x,na.rm=TRUE)>0,logical(1))]
 valid<-is.finite(z$status)&is.finite(z$W_FSTUWT)&z$W_FSTUWT>0&!is.na(z$school)&is.finite(z$school_weight)&z$school_weight>0&complete.cases(z[,c(controls,pv,sk),with=FALSE])
 if(!length(sk))valid[]<-FALSE
 a<-copy(z[valid]);if(nrow(a)<100||uniqueN(a$school)<30)a<-z[0]
 audit[[cc]]<-data.table(CNT=cc,economy=z$economy[1],N_all=nrow(z),N=nrow(a),schools=uniqueN(a$school),skills=length(sk),skill_set=paste(sk,collapse=';'),missing_skills=paste(setdiff(skall,sk),collapse=';'),controls=paste(controls,collapse=';'),status=if(nrow(a))'Eligible' else 'Insufficient complete data')
 if(!nrow(a))next
 a[,school:=factor(school)]
 for(k in sk){mu<-wm(a[[k]],a$W_FSTUWT);sdv<-sqrt(wm((a[[k]]-mu)^2,a$W_FSTUWT));a[,(k):=(get(k)-mu)/sdv]}
 a[,AGE:=AGE-15];a[,w2:=school_weight/mean(unique(school_weight))]
 dat[[cc]]<-list(data=a,skills=sk,controls=controls)
}
audit<-rbindlist(audit)
refpath<-file.path(OUT,'original_eligibility.csv')
if(file.exists(refpath)) {
 reference<-fread(refpath)
 check<-merge(audit,reference[,.(CNT,reference_N=N,reference_schools=schools,reference_skills=skills)],by='CNT')
 stopifnot(nrow(check)==nrow(reference),all(check$N==check$reference_N),all(check$schools==check$reference_schools),all(check$skills==check$reference_skills))
 fwrite(check,file.path(OUT,'fresh_sample_validation.csv'))
} else fwrite(audit,refpath)
if(!file.exists(file.path(OUT,'country_groups.csv'))) {
 groups<-unique(d[,.(CNT,economy,OECD)])
 groups[,`:=`(region=NA_character_,income=NA_character_,scope_note='Source PISA population; geographic/income grouping not assigned')]
 fwrite(groups,file.path(OUT,'country_groups.csv'))
}
saveRDS(dat,file.path(WORK,'base_data.rds'))

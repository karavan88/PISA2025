# All-system extension of the validated mediation pilot.
suppressPackageStartupMessages({library(data.table);library(haven)})
setDTthreads(1)
WORK<-'03_outputs/01_harmonized'
OUT<-'03_outputs/01_harmonized/metadata';dir.create(WORK,recursive=TRUE,showWarnings=FALSE);dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
dir.create(file.path(WORK,'input'),recursive=TRUE,showWarnings=FALSE)
dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
input<-Sys.getenv('GM_PREPARED',file.path(WORK,'base_data.rds'))
rawfile<-file.path(WORK,'deprivation_raw.rds')
items<-c('ST488Q01DA','ST488Q02DA','ST488Q08DA','ST488Q09DA',paste0('ST401Q0',3:7,'DA'))
core<-items[1:4]
if(!file.exists(rawfile)) stop('Run extract_base.R through the central build.')
r<-readRDS(rawfile)
stopifnot(!anyDuplicated(r[,.(CNT,CNTSTUID)]))
for(v in items)stopifnot(all(is.na(r[[v]])|r[[v]]%in%1:3))
meta<-readRDS(file.path(WORK,'deprivation_metadata.rds'))
fwrite(data.table(variable=items,label=vapply(meta[items],function(m)m$label,character(1))),file.path(OUT,'deprivation_item_dictionary.csv'))
audit<-list();itemaudit<-list()
for(cc in unique(r$CNT)) {
  ix<-which(r$CNT==cc);M<-as.matrix(r[ix,..items]);reached<-rowSums(!is.na(M))>0
  coverage<-if(any(reached))colMeans(!is.na(M[reached,,drop=FALSE]))else rep(0,length(items))
  selected<-items[coverage>=.90]
  D<-rep(NA_real_,length(ix))
  if(length(selected)) {
    Z<-M[,selected,drop=FALSE];ok<-rowSums(is.na(Z))==0
    D[ok]<-rowSums(Z[ok,,drop=FALSE]==2)
  }
  C<-M[,core,drop=FALSE];dc<-rep(NA_real_,length(ix));ok<-rowSums(is.na(C))==0
  if(all(core%in%selected))dc[ok]<-rowSums(C[ok,,drop=FALSE]==2)
  r[ix,`:=`(DEP=D,DEP_core4=dc)]
  audit[[cc]]<-data.table(CNT=cc,N_all=length(ix),module_reached=sum(reached),items=length(selected),
       item_set=paste(selected,collapse=';'),complete_DEP=sum(is.finite(D)),
       core4_available=all(core%in%selected),complete_core4=sum(is.finite(dc)))
  itemaudit[[cc]]<-data.table(CNT=cc,variable=items,coverage_among_module=coverage,
       fielded=items%in%selected,N_valid=colSums(!is.na(M)),cannot_afford=colSums(M==2,na.rm=TRUE))
}
audit<-rbindlist(audit);fwrite(audit,file.path(OUT,'deprivation_availability.csv'))
fwrite(rbindlist(itemaudit),file.path(OUT,'deprivation_item_audit.csv'))
fwrite(r[,.(CNT,CNTSTUID,DEP,DEP_core4)],file.path(WORK,'deprivation_counts.csv'))
dat<-readRDS(input)
old<-fread(file.path(OUT,'original_eligibility.csv'))
fwrite(old,file.path(OUT,'original_eligibility.csv'))
jobs<-list();elig<-list();stats<-list()
for(cc in old$CNT) {
  o<-old[CNT==cc];di<-audit[CNT==cc]
  for(ex in c('SES','DEP')) {
    reason<-o$status;N<-schools<-0L;ctrl<-o$controls;ndep<-NA_integer_
    if(cc%in%names(dat)) {
      z<-dat[[cc]];d<-copy(z$data)
      keep<-unique(c('CNT','CNTSTUID','school','STRATUM','economy','ESCS','status',z$controls,
                      'W_FSTUWT','school_weight','w2',z$skills,paste0('PV',1:10,'READ')))
      d<-d[,..keep]
      d<-merge(d,r[CNT==cc,.(CNTSTUID,DEP,DEP_core4)],by='CNTSTUID',all.x=TRUE,sort=FALSE)
      d[,SES_rank:=status]
      co<-z$controls
      if(ex=='DEP') {
        if(di$items==0)reason<-'Deprivation module unavailable under fielded-item rule'
        d<-d[is.finite(DEP)];d[,status:=DEP];co<-unique(c(co,'ESCS'))
      }
      co<-co[vapply(d[,..co],function(x)length(x)>1&&any(is.finite(x))&&sd(x,na.rm=TRUE)>0,logical(1))]
      N<-nrow(d);schools<-uniqueN(d$school);ctrl<-paste(co,collapse=';')
      if(reason=='Eligible'&&(N<100||schools<30))reason<-'Fewer than 100 complete students or 30 schools'
      if(reason=='Eligible'&&(!is.finite(sd(d$status))||sd(d$status)==0))reason<-'Exposure has no variation'
      if(reason=='Eligible') {
        zz<-list(data=d,skills=z$skills,controls=co,exposure=ex,CNT=cc)
        key<-paste(ex,cc,sep='_');saveRDS(zz,file.path(WORK,'input',paste0(key,'.rds')))
        jobs[[key]]<-data.table(job_id=key,CNT=cc,exposure=ex)
        w<-d$W_FSTUWT
        stats[[key]]<-data.table(CNT=cc,exposure=ex,N=N,schools=schools,
          mean_exposure=weighted.mean(d$status,w),sd_exposure=sqrt(weighted.mean((d$status-weighted.mean(d$status,w))^2,w)),
          pct_any_deprivation=if(ex=='DEP')100*weighted.mean(d$DEP>0,w)else NA_real_,
          pct_two_plus=if(ex=='DEP')100*weighted.mean(d$DEP>=2,w)else NA_real_,
          skills=length(z$skills))
      }
    }
    elig[[paste(cc,ex)]]<-data.table(CNT=cc,economy=o$economy,exposure=ex,N_all=o$N_all,N=N,schools=schools,
       status=reason,skills=o$skills,skill_set=o$skill_set,missing_skills=o$missing_skills,
       controls=ctrl,items=if(ex=='DEP')di$items else NA_integer_,item_set=if(ex=='DEP')di$item_set else '',
       core4_available=di$core4_available,complete_share=N/o$N_all)
  }
}
fwrite(rbindlist(jobs),file.path(OUT,'jobs.csv'))
fwrite(rbindlist(elig),file.path(OUT,'eligibility.csv'))
fwrite(rbindlist(stats),file.path(OUT,'exposure_descriptives.csv'))
print(rbindlist(elig)[,.(systems=.N,students=sum(N)),by=.(exposure,status)])
print(audit[,.(systems=.N),by=items][order(items)])

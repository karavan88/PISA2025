source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/engine.R');source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/functions.R')
suppressPackageStartupMessages({library(lme4);library(WeMix)})
WORK<-Sys.getenv('GM_WORK','05_papers/01_SESTransmission/04_output/upstream');OUT<-'05_papers/01_SESTransmission/04_output/input'
jobs<-fread(file.path(OUT,'jobs.csv'))
dir.create(file.path(OUT,'diagnostics'),showWarnings=FALSE)
terms<-c('delta','joint_W','joint_B','skills_sorting','sorting_increment','remaining','total','share')
one<-function(id) {
  z<-readRDS(file.path('03_outputs/01_harmonized/input',paste0(id,'.rds')))
  obj<-readRDS(file.path(WORK,'compressed',paste0(id,'.rds')));s<-obj$s;point<-obj$point
  cc<-z$CNT;ex<-z$exposure;d<-s$d;sk<-s$sk;ctrl<-s$controls
  warnings<-character();failure<-list()
  fit_variant<-function(zz,name,mode='scaled') {
    tryCatch({ss<-prepare_model(zz,mode);pp<-evaluate_model(ss);
      data.table(CNT=cc,exposure=ex,variant=name,term=terms,estimate=rowMeans(pp)[terms],N=nrow(ss$d),schools=length(ss$base$n))
    },error=function(e){failure[[name]]<<-data.table(CNT=cc,exposure=ex,variant=name,error=conditionMessage(e));NULL})
  }
  variants<-list(fit_variant(z,'unscaled_weights','unscaled'))
  small<-d[,.N,by=school][N<10,school]
  zz<-z;zz$data<-d[!school%in%small]
  if(uniqueN(zz$data$school)>=30)variants[[length(variants)+1]]<-fit_variant(zz,'minimum_10')
  if(ex=='DEP') {
    zz<-z;zz$data<-copy(z$data);zz$data[,status:=SES_rank];zz$controls<-setdiff(z$controls,'ESCS');zz$exposure<-'SES'
    variants[[length(variants)+1]]<-fit_variant(zz,'SES_on_deprivation_sample')
    if(all(is.finite(d$DEP_core4))) {
      zz<-z;zz$data<-copy(z$data);zz$data[,status:=DEP_core4]
      if(sd(zz$data$status)>0)variants[[length(variants)+1]]<-fit_variant(zz,'core_four_same_sample')
    }
  }
  # lmer comparison: same sample/centred variables, unweighted ML; delta unchanged.
  makef<-function(y,pr)as.formula(paste(y,'~',paste(c(paste0(pr,'_W'),paste0(pr,'_B'),'(1|school)'),collapse='+')))
  dd<-as.data.frame(d)
  mer<-tryCatch(withCallingHandlers({
    mm<-lapply(sk,function(k)lmer(makef(k,c('status',ctrl)),dd,REML=FALSE))
    yy<-lapply(PVS,function(y)lmer(makef(y,c('status',ctrl,sk)),dd,REML=FALSE))
    aw<-vapply(mm,function(m)unname(fixef(m)['status_W']),numeric(1))
    ab<-vapply(mm,function(m)unname(fixef(m)['status_B']),numeric(1))
    vv<-sapply(yy,function(m){b<-fixef(m);iw<-sum(aw*b[paste0(sk,'_W')]);ib<-sum(ab*b[paste0(sk,'_B')]);delta<-point['delta',1];ind<-(1-delta)*iw+delta*ib;rem<-unname((1-delta)*b['status_W']+delta*b['status_B']);c(joint_W=iw,joint_B=ib,skills_sorting=ind,sorting_increment=ind-iw,total=ind+rem)})
    data.table(CNT=cc,exposure=ex,term=rownames(vv),WeMix=rowMeans(point)[rownames(vv)],lmer_unweighted=rowMeans(vv),singular_fits=sum(vapply(c(mm,yy),isSingular,logical(1))))
  },warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')}),error=function(e){failure[['lmer']]<<-data.table(CNT=cc,exposure=ex,variant='lmer',error=conditionMessage(e));NULL})
  # Leave-one-out diagnostic on the same retained non-singleton pupils.
  d<-copy(d);d[,`:=`(sum_w=sum(w1),school_n=.N),by=school]
  d[,loo:=fifelse(sum_w>w1,(sum_w*status_B-w1*status)/(sum_w-w1),NA_real_)]
  ds<-d[is.finite(loo)]
  ff<-function(y)reformulate(c('status',ctrl,paste0(ctrl,'_B')),response=y)
  delta_full<-unname(coef(lm(ff('status_B'),ds,weights=W_FSTUWT))['status'])
  delta_loo<-unname(coef(lm(ff('loo'),ds,weights=W_FSTUWT))['status'])
  if(ex=='SES')ov<-d[,.(lo=sum(status>=4&status<5),hi=sum(status>=5&status<6)),by=school]
  else ov<-d[,.(lo=sum(status==0),hi=sum(status==1)),by=school]
  d<-merge(d,ov,by='school',sort=FALSE)
  audit<-data.table(CNT=cc,exposure=ex,N=nrow(d),schools=length(s$base$n),
       small_schools=length(small),median_school_n=median(unique(d[,.(school,school_n)])$school_n),
       delta=point['delta',1],delta_full_loo_sample=delta_full,delta_loo=delta_loo,loo_N=nrow(ds),
       overlap_pct=100*wm(as.numeric(d$lo>0&d$hi>0),d$W_FSTUWT),
       overlap_3each_pct=100*wm(as.numeric(d$lo>=3&d$hi>=3),d$W_FSTUWT),
       min_exposure=min(d$status),max_exposure=max(d$status),
       lmer_warning_count=length(warnings),lmer_warnings=paste(unique(warnings),collapse='; '))
  valid<-NULL
  # Validate new deprivation fits across item sets, block sizes and school contexts.
  if(ex=='DEP'&&cc%in%c('DNK','KOR','MYS','MNG','RWA','LTU','SAU','USA','KEN','TUR')) {
    f<-makef('PV1READ',c('status',ctrl,sk));m<-mix(f,dd,weights=c('w1','w2'),cWeights=TRUE)
    ef<-fit_compressed(s$full)[[1]]
    valid<-data.table(CNT=cc,exposure=ex,max_coef_error=max(abs(m$coef-ef$coef[names(m$coef)])),
         residual_variance_error=abs(m$vars['Residual']-ef$sigma2),school_variance_error=abs(m$vars[1]-ef$tau2))
    stopifnot(valid$max_coef_error<.01,valid$residual_variance_error<.2,valid$school_variance_error<.2)
  }
  out<-list(sensitivity=rbindlist(variants),lmer=mer,audit=audit,validation=valid,failures=rbindlist(failure,fill=TRUE))
  saveRDS(out,file.path(WORK,paste0(id,'_diagnostics.rds')))
  fwrite(audit,file.path(OUT,'diagnostics',paste0(id,'.csv')))
  cat(id,'DIAGNOSTICS COMPLETE\n');TRUE
}
pending<-jobs[!file.exists(file.path(OUT,'diagnostics',paste0(job_id,'.csv')))|
              !file.exists(file.path(WORK,paste0(job_id,'_diagnostics.rds'))),job_id]
ok<-parallel::mclapply(pending,function(id)tryCatch(one(id),error=function(e){writeLines(conditionMessage(e),file.path(WORK,paste0(id,'_DIAGNOSTICS_ERROR.txt')));cat(id,'ERROR',conditionMessage(e),'\n');FALSE}),mc.cores=2,mc.preschedule=FALSE)
stopifnot(all(unlist(ok)))
all<-lapply(jobs$job_id,function(id)readRDS(file.path(WORK,paste0(id,'_diagnostics.rds'))))
for(nm in c('sensitivity','lmer','audit','validation','failures')) {
  rr<-rbindlist(lapply(all,`[[`,nm),fill=TRUE)
  if(ncol(rr))fwrite(rr,file.path(OUT,paste0(nm,'.csv')))
}
sink(file.path(OUT,'R_session_info.txt'));print(sessionInfo());sink()

source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/functions.R')
WORK<-Sys.getenv('GM_WORK','05_papers/01_SESTransmission/04_output/upstream');OUT<-'05_papers/01_SESTransmission/04_output/input'
jobs<-fread(file.path(OUT,'jobs.csv'))
E<-rbindlist(lapply(jobs$job_id,function(id)fread(file.path(OUT,'countries',paste0(id,'.csv')))))
E[,p_approx:=2*pnorm(-abs(estimate/se))]
E[term%in%c('skills_sorting','sorting_increment'),q_primary:=p.adjust(p_approx,'BH'),by=exposure]
E[grepl('^indS_',term),q_skill:=p.adjust(p_approx,'BH'),by=exposure]
curves<-list();thresholds<-list();checks<-list();ratios<-list()
for(j in seq_len(nrow(jobs))) {
  job<-jobs[j];id<-job$job_id;cc<-job$CNT;ex<-job$exposure
  dd<-readRDS(file.path(WORK,'draws',paste0(id,'.rds')));p<-dd$point;b<-dd$bootstrap
  core<-setdiff(rownames(p),c('share','bias_scale_W','bias_scale_B'))
  ok<-apply(b[core,,,drop=FALSE],3,function(x)all(is.finite(x)))
  b<-b[,,ok,drop=FALSE]
  kp<-(1-p['delta',])*p['bias_scale_W',]+p['delta',]*p['bias_scale_B',]
  kb<-(1-b['delta',,])*b['bias_scale_W',,]+b['delta',,]*b['bias_scale_B',,]
  sk<-sub('^indS_','',grep('^indS_',rownames(p),value=TRUE))
  for(lv in c('W','B','S')) {
    term<-if(lv=='S')'skills_sorting'else paste0('joint_',lv)
    Kp<-if(lv=='S')kp else p[paste0('bias_scale_',lv),]
    Kb<-if(lv=='S')kb else b[paste0('bias_scale_',lv),,]
    joint<-mean(p[term,]);scale<-mean(Kp)
    direction<-if(joint<0)-1 else 1
    thresholds[[paste(id,lv)]]<-data.table(CNT=cc,exposure=ex,level=lv,direction=direction,
        point_zero_rho=abs(joint)/sqrt(joint^2+scale^2))
    if(all(is.finite(Kp))&&mean(is.finite(Kb))>=.95)for(rho in seq(0,.5,.01)) {
      fac<-direction*rho/sqrt(1-rho^2)
      v<-p[term,]-fac*Kp;bs<-b[term,,]-fac*Kb
      se<-sqrt(mean(apply(bs,1,var,na.rm=TRUE))+1.1*var(v))
      curves[[paste(id,lv,rho)]]<-data.table(CNT=cc,exposure=ex,level=lv,rho_magnitude=rho,
          rho_signed=direction*rho,estimate=mean(v),se=se,lower=mean(v)-1.96*se,upper=mean(v)+1.96*se)
    }
  }
  e<-E[CNT==cc&exposure==ex&term=='total'];ind<-mean(p['skills_sorting',]);total<-mean(p['total',]);rem<-mean(p['remaining',])
  sign_agreement<-mean(sign(b['total',,])==sign(total))
  reason<-'Reportable model-implied share'
  if(e$lower<=0&&e$upper>=0)reason<-'Total interval includes zero'
  else if(sign_agreement<.99||any(sign(p['total',])!=sign(total)))reason<-'Unstable denominator across resamples or PVs'
  else if(ind*total<0||rem*total<0)reason<-'Opposing components: no proportional interpretation'
  else if(!all(is.finite(b['share',,])))reason<-'Non-finite ratio in resamples'
  ratios[[id]]<-data.table(CNT=cc,exposure=ex,share_reportable=reason=='Reportable model-implied share',
       share_reason=reason,bootstrap_total_sign_agreement=sign_agreement,
       minimum_total=min(b['total',,]),maximum_total=max(b['total',,]))
  checks[[id]]<-data.table(CNT=cc,exposure=ex,requested_draws=dim(dd$bootstrap)[3],valid_draws=sum(ok),
       failures=length(dd$failures),
       max_joint_sum_error=max(abs(b['skills_sorting',,]-apply(b[paste0('indS_',sk),,,drop=FALSE],c(2,3),sum))),
       max_total_identity_error=max(abs(b['total',,]-b['remaining',,]-b['skills_sorting',,])),
       max_sorting_identity_error=max(abs(b['sorting_increment',,]-b['skill_level_sorting',,]-b['skill_context_sorting',,])))
}
S<-rbindlist(curves);T<-rbindlist(thresholds)
cross<-S[lower<=0&upper>=0,.(first_grid_rho_CI_includes_zero=min(rho_magnitude)),by=.(CNT,exposure,level)]
T<-merge(T,cross,by=c('CNT','exposure','level'),all.x=TRUE)
fwrite(S,file.path(OUT,'sensitivity_curves.csv'));fwrite(T,file.path(OUT,'sensitivity_thresholds.csv'))
R<-rbindlist(ratios);fwrite(R,file.path(OUT,'ratio_audit.csv'))
B<-rbindlist(checks);stopifnot(max(B$max_joint_sum_error)<1e-8,max(B$max_total_identity_error)<1e-8,max(B$max_sorting_identity_error)<1e-8)
fwrite(B,file.path(OUT,'bootstrap_checks.csv'));fwrite(E,file.path(OUT,'estimates.csv'))

# Reproduce the three-country pilot, including its uncertainty (identical seeds).
old<-fread(file.path(OUT,'pilot_reference_estimates.csv'))
pv<-merge(E[exposure=='SES'&CNT%in%old$CNT,.(CNT,term,estimate,se)],old[,.(CNT,term,old_estimate=estimate,old_se=se)],by=c('CNT','term'))
pc<-pv[,.(max_point_error=max(abs(estimate-old_estimate)),max_se_error=max(abs(se-old_se))),by=CNT]
stopifnot(max(pc$max_point_error)<1e-5,max(pc$max_se_error)<1e-5)
fwrite(pc,file.path(OUT,'pilot_replication.csv'))

# One row per exposure/country, with uncertainty and availability retained.
A<-fread(file.path(OUT,'eligibility.csv'));G<-fread(file.path(OUT,'country_groups.csv'))
sel<-c('delta','skills_same_school','skills_sorting','sorting_increment','remaining','total','share','joint_W','joint_B')
D<-dcast(E[term%in%sel],CNT+exposure~term,value.var=c('estimate','lower','upper','q_primary'))
D<-merge(A,D,by=c('CNT','exposure'),all.x=TRUE)
D<-merge(D,G[,.(CNT,OECD,region,income,scope_note)],by='CNT',all.x=TRUE)
D<-merge(D,R,by=c('CNT','exposure'),all.x=TRUE)
D<-merge(D,T[level=='S',.(CNT,exposure,point_zero_rho,first_grid_rho_CI_includes_zero)],by=c('CNT','exposure'),all.x=TRUE)
lead<-E[grepl('^indS_',term)][order(-abs(estimate)),.SD[1],by=.(CNT,exposure)]
lead<-lead[,.(CNT,exposure,largest_absolute_skill=sub('^indS_','',term),largest_skill_estimate=estimate,largest_skill_lower=lower,largest_skill_upper=upper,largest_skill_q=q_skill)]
D<-merge(D,lead,by=c('CNT','exposure'),all.x=TRUE)
diag<-fread(file.path(OUT,'audit.csv'))
D<-merge(D,diag[,.(CNT,exposure,small_schools,median_school_n,delta_loo,overlap_pct,lmer_warning_count)],by=c('CNT','exposure'),all.x=TRUE)
lm<-fread(file.path(OUT,'lmer.csv'))[term=='skills_sorting',.(CNT,exposure,lmer_joint=lmer_unweighted)]
D<-merge(D,lm,by=c('CNT','exposure'),all.x=TRUE)
D[,joint_evidence:=fifelse(is.na(lower_skills_sorting),'Unavailable',fifelse(lower_skills_sorting>0,'Positive',fifelse(upper_skills_sorting<0,'Negative','Interval includes zero')))]
D[,sorting_evidence:=fifelse(is.na(lower_sorting_increment),'Unavailable',fifelse(lower_sorting_increment>0,'Positive increment',fifelse(upper_sorting_increment<0,'Negative increment','Interval includes zero')))]
D[,hypothesis_direction:=fifelse(exposure=='SES','Positive','Negative')]
D[,lmer_sign_change:=sign(estimate_skills_sorting)!=sign(lmer_joint)]
setorder(D,economy,exposure);fwrite(D,file.path(OUT,'decision_matrix.csv'))
fwrite(dcast(D,CNT+economy+OECD+region+income~exposure,value.var=c('N','skills','status','items','estimate_skills_sorting','lower_skills_sorting','upper_skills_sorting','estimate_sorting_increment','share_reportable','estimate_share','largest_absolute_skill','point_zero_rho')),file.path(OUT,'country_comparison.csv'))
cat('POSTPROCESSING COMPLETE:',nrow(jobs),'models\n')

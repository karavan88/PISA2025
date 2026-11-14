suppressPackageStartupMessages({library(data.table);library(fixest)})
setDTthreads(2);setFixest_nthreads(2)
O<-'03_outputs/caucasus_central_asia/armenia_redesign/';D<-'01_data/derived/caucasus_central_asia/armenia_redesign/'
datasets<-readRDS(paste0(D,'samples.rds'));all<-fread('01_data/derived/caucasus_central_asia/analysis_input.csv.gz')[CNT=='ARM']
wm<-function(x,w)sum(x*w)/sum(w)
pool<-function(z,keys)z[, {u<-mean(se^2);bb<-var(est);v<-u+1.1*bb;df<-min(min(df_cluster),if(bb<1e-14)Inf else 9*(1+u/(1.1*bb))^2);est0<-mean(est);list(est=est0,se=sqrt(v),lo=est0-qt(.975,df)*sqrt(v),hi=est0+qt(.975,df)*sqrt(v),df=df,p=2*pt(-abs(est0/sqrt(v)),df),npv=.N)},by=keys]
bb<-list();bal<-list();profiles<-list();ni<-0
for(sp in names(datasets)){
 d<-copy(datasets[[sp]]$d);parent<-datasets[[sp]]$parent;w<-d$W_FSTUWT
 set(d,j='ow',value=w*d$e0*(1-d$e0))
 rhs<-paste(c('W','HOMEPOS','female','lang',parent),collapse='+')
 for(dom in c('SCIE','MATH','READ'))for(k in 1:10){
  set(d,j='y',value=d[[paste0('PV',k,dom)]])
  stopifnot(identical(d$y,d[[paste0('PV',k,dom)]]))
  fit<-feols(as.formula(paste0('y~',rhs,'|school+age')),d,weights=~ow,cluster=~school,notes=FALSE)
  ni<-ni+1;bb[[ni]]<-data.table(spec=sp,domain=dom,pv=k,est=coef(fit)['W'],se=fixest::se(fit)['W'],df_cluster=uniqueN(d$school)-1)
 }
 vars<-c('HOMEPOS','HOMEPOS_school','age','female','lang',parent,if(!is.null(parent))paste0(parent,'_school'))
 X<-cbind(as.matrix(d[,vars,with=FALSE]),model.matrix(~0+factor(age),d))
 for(v in colnames(X)){
  x<-X[,v];den<-sqrt(wm((x-wm(x,w))^2,w));if(den<1e-10)next
  for(ty in c('original','overlap_balance')){
   ww<-if(ty=='original')w else w*ifelse(d$W==1,1-d$e0,d$e0)
   delta<-wm(x[d$W==1],ww[d$W==1])-wm(x[d$W==0],ww[d$W==0])
   bal[[length(bal)+1]]<-data.table(spec=sp,variable=v,weighting=ty,smd=delta/den)
  }
 }
 profiles[[sp]]<-rbindlist(lapply(vars,function(v)data.table(spec=sp,variable=v,raw_mean=wm(d[[v]],w),overlap_target_mean=wm(d[[v]],d$ow))))
}
fwrite(rbindlist(bb),paste0(O,'school_FE_benchmark_pv.csv'));fwrite(pool(rbindlist(bb),c('spec','domain')),paste0(O,'school_FE_benchmark.csv'));fwrite(rbindlist(bal),paste0(O,'balance.csv'));fwrite(rbindlist(profiles),paste0(O,'target_profiles.csv'))
# Context and attainment of selected and excluded students: descriptive PV means only.
main<-datasets$possessions_main$d
counts<-all[,.(n=.N,schools=uniqueN(CNTSCHID))]
means<-rbindlist(lapply(c('SCIE','MATH','READ'),function(dom){
 q<-sapply(1:10,function(k)wm(all[[paste0('PV',k,dom)]],all$W_FSTUWT));z<-sapply(1:10,function(k)wm(main[[paste0('PV',k,dom)]],main$W_FSTUWT));data.table(domain=dom,full_mean=mean(q),selected_mean=mean(z))}))
fwrite(means,paste0(O,'sample_achievement.csv'))
print(pool(rbindlist(bb)[spec=='possessions_main'],c('spec','domain')))
print(rbindlist(bal)[,.(max_abs_smd=max(abs(smd)),number_above_01=sum(abs(smd)>.1)),by=.(spec,weighting)])
# Descriptive stock/flow context on the same target sample; points only, no tests.
vv<-list();ll<-list()
for(ss in c('full_ARM','overlap_sample')){
 z<-if(ss=='full_ARM')copy(all)else copy(main)
 z[,sid:=CNTSCHID]
 for(dom in c('SCIE','MATH','READ'))for(k in 1:10){
  yy<-z[[paste0('PV',k,dom)]];ww<-z$W_FSTUWT
  sy<-ave(seq_along(yy),z$sid,FUN=function(i)wm(yy[i],ww[i]));mu<-wm(yy,ww);tot<-wm((yy-mu)^2,ww);bw<-wm((sy-mu)^2,ww)
  vv[[length(vv)+1]]<-data.table(sample=ss,domain=dom,pv=k,mean=mu,total=tot,between=bw,within=tot-bw,between_share=bw/tot)
 }
}
for(v in c('HOMEPOS','HOMEPOS_school'))for(dom in c('SCIE','MATH','READ'))for(k in 1:10){
 z<-copy(main);set(z,j='score',value=z[[paste0('PV',k,dom)]]);ll[[length(ll)+1]]<-z[,.(moderator=v,domain=dom,pv=k,mean=wm(score,W_FSTUWT)),by=.(group=get(paste0('group_',v)))]
}
fwrite(rbindlist(vv)[,lapply(.SD,mean),by=.(sample,domain),.SDcols=c('mean','total','between','within','between_share')],paste0(O,'variance_partition.csv'))
fwrite(rbindlist(ll)[,.(mean=mean(mean)),by=.(moderator,domain,group)],paste0(O,'achievement_groups.csv'))

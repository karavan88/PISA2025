# PISA 2025: survey-weighted descriptive / within-between estimates, all ten PVs.
# Random effects are an UNWEIGHTED model-based sensitivity, not survey estimates.
suppressPackageStartupMessages({library(data.table);library(fixest);library(lme4)})
setFixest_nthreads(2); setDTthreads(2)
O <- '03_outputs/caucasus_central_asia/'
a <- fread('01_data/derived/caucasus_central_asia/analysis_input.csv.gz')
a[, `:=`(grade=ST001D01T,school=factor(CNTSCHID),agegroup=factor(round(12*AGE)),female=as.numeric(ST004D01T==1),lang=as.numeric(ST022Q01TA!=1))]
# Do not infer an actual assessment date from rounded AGE.
wm <- function(x,w) sum(x*w)/sum(w)
means <- function(d,w) {d<-copy(d); d[, `:=`(gb=wm(grade,w[.I]),sb=wm(ESCS,w[.I]),fb=wm(female,w[.I]),lb=wm(lang,w[.I])),by=school]; d[,`:=`(gw=grade-gb,sw=ESCS-sb)]; d}
pool <- function(z,keys) z[, {q<-mean(est); b<-var(est); v<-mean(se^2)+(1+1/.N)*b; list(est=q,se=sqrt(v),lo=q-1.96*sqrt(v),hi=q+1.96*sqrt(v),npv=.N)},by=keys]
repnames <- grep('^W_FSTURWT[0-9]+$',names(a),value=TRUE); stopifnot(length(repnames)==80)
regs<-list(); desc<-list(); mix<-list(); coverage<-list(); n<-0; nd<-0; nm<-0
for(cc in unique(a$CNT)) {
 full<-a[CNT==cc]; d<-full[complete.cases(grade,AGE,ESCS,female,lang)&W_FSTUWT>0]
 d<-means(d,d$W_FSTUWT)
 coverage[[cc]]<-data.table(CNT=cc,n=nrow(d),schools=uniqueN(d$school),retained_weight=sum(d$W_FSTUWT)/sum(full$W_FSTUWT),retained_n=nrow(d)/nrow(full),repeat_rate=wm(d$REPEAT[!is.na(d$REPEAT)],d$W_FSTUWT[!is.na(d$REPEAT)]))
 # Replicate-specific means preserve the within-between decomposition under reweighting.
 designs<-lapply(c('W_FSTUWT',repnames),function(ww) {z<-means(d,d[[ww]]); list(z=z,w=z[[ww]])})
 for(dom in c('SCIE','MATH','READ')) {
  if(all(is.na(d[[paste0('PV1',dom)]]))) next
  Y<-as.matrix(d[,paste0('PV',1:10,dom),with=FALSE])
  # Weighted coefficients for all PVs in one matrix operation; age effects categorical.
  forms<-list(within_between=~gw+gb+sw+sb+female+lang+fb+lb+agegroup,grade_basic=~grade+female+lang+agegroup)
  for(spec in names(forms)) {
   co<-lapply(designs,function(dd) {X<-model.matrix(forms[[spec]],dd$z); fit<-lm.wfit(X,Y,dd$w); fit$coefficients})
   b<-co[[1]]; vr<-Reduce('+',lapply(co[-1],function(x)(x-b)^2))/20
   for(k in 1:10) {n<-n+1; regs[[n]]<-data.table(CNT=cc,domain=dom,spec=spec,pv=k,term=rownames(b),est=b[,k],se=sqrt(vr[,k]))}
  }
  # School fixed effects + age categories: compare to between-school adjusted model.
  for(k in 1:10) {
   d[,y:=Y[,k]]
   ff<-feols(y~grade+ESCS+female+lang|school+agegroup,d,weights=~W_FSTUWT,notes=FALSE)
   br<-sapply(repnames,function(ww) coef(feols(y~grade+ESCS+female+lang|school+agegroup,d,weights=d[[ww]],notes=FALSE)))
   b<-coef(ff); se<-sqrt(rowSums((br-b)^2)/20)
   n<-n+1;regs[[n]]<-data.table(CNT=cc,domain=dom,spec='school_FE',pv=k,term=names(b),est=b,se=se)
   # Original architecture retained as sensitivity: partial pooling of monthly ages.
   fm<-suppressWarnings(lmer(y~gw+gb+sw+sb+female+lang+fb+lb+(1|school)+(1|agegroup),d,REML=TRUE,control=lmerControl(optimizer='bobyqa')))
   b<-fixef(fm); se<-sqrt(diag(vcov(fm))); v<-as.data.frame(VarCorr(fm))
   nm<-nm+1;mix[[nm]]<-data.table(CNT=cc,domain=dom,pv=k,term=c(names(b),'school_variance','age_variance','residual_variance','singular'),est=c(b,v$vcov[match(c('school','agegroup','Residual'),v$grp)],as.numeric(isSingular(fm))),se=c(se,rep(NA_real_,4)))
  }
  # Exact descriptive weighted variance partition, on ALL domain-available students.
  for(k in 1:10) {
   f<-full[!is.na(get(paste0('PV',k,dom)))]; y<-f[[paste0('PV',k,dom)]]
   calc<-function(w) {mu<-wm(y,w); sy<-ave(seq_along(y),f$school,FUN=function(ii)wm(y[ii],w[ii])); total<-wm((y-mu)^2,w); between<-wm((sy-mu)^2,w); c(mean=mu,total=total,between=between,within=wm((y-sy)^2,w),between_share=between/total)}
   b<-calc(f$W_FSTUWT); br<-sapply(repnames,function(ww)calc(f[[ww]])); se<-sqrt(rowSums((br-b)^2)/20)
   nd<-nd+1;desc[[nd]]<-data.table(CNT=cc,domain=dom,pv=k,term=names(b),est=b,se=se)
  }
  cat(cc,dom,'complete\n'); flush.console()
  fwrite(pool(rbindlist(regs),c('CNT','domain','spec','term')),paste0(O,'regression.csv'))
  fwrite(pool(rbindlist(desc),c('CNT','domain','term')),paste0(O,'descriptive.csv'))
  fwrite(rbindlist(mix),paste0(O,'mixed_pv.csv'))
 }
}
fwrite(rbindlist(coverage),paste0(O,'model_coverage.csv'))
fwrite(pool(rbindlist(mix)[!is.na(se)],c('CNT','domain','term')),paste0(O,'mixed_coefficients.csv'))
fwrite(rbindlist(mix)[is.na(se),.(est=mean(est)),by=.(CNT,domain,term)],paste0(O,'mixed_variances.csv'))
writeLines(capture.output(sessionInfo()),paste0(O,'sessionInfo_models.txt'))

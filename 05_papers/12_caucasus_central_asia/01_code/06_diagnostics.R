# Null ICC, non-repeater sensitivity, and contextual SES contrast with covariance retained.
suppressPackageStartupMessages({library(data.table);library(lme4)})
setDTthreads(2);O<-'03_outputs/caucasus_central_asia/';a<-fread('01_data/derived/caucasus_central_asia/analysis_input.csv.gz')
a[,`:=`(grade=ST001D01T,school=factor(CNTSCHID),agegroup=factor(round(12*AGE)),female=as.numeric(ST004D01T==1),lang=as.numeric(ST022Q01TA!=1))]
wm<-function(x,w)sum(x*w)/sum(w);rn<-grep('^W_FSTURWT[0-9]+$',names(a),value=TRUE)
r<-list();v<-list();nr<-0;nv<-0
for(cc in unique(a$CNT))for(dom in c('SCIE','MATH','READ')){
 f<-a[CNT==cc];if(all(is.na(f[[paste0('PV1',dom)]])))next
 for(k in 1:10){f[,y:=get(paste0('PV',k,dom))];fit<-lmer(y~1+(1|school),f);vc<-as.data.frame(VarCorr(fit));nv<-nv+1;v[[nv]]<-data.table(CNT=cc,domain=dom,pv=k,ICC=vc$vcov[vc$grp=='school']/sum(vc$vcov))}
 for(samp in c('all','nonrepeat')){
  d<-f[complete.cases(grade,AGE,ESCS,female,lang)&W_FSTUWT>0];if(samp=='nonrepeat')d<-d[REPEAT==0]
  if(nrow(d)<100)next
  Y<-as.matrix(d[,paste0('PV',1:10,dom),with=FALSE])
  fits<-lapply(c('W_FSTUWT',rn),function(ww){z<-copy(d);w<-z[[ww]];z[,`:=`(gb=wm(grade,w[.I]),sb=wm(ESCS,w[.I]),fb=wm(female,w[.I]),lb=wm(lang,w[.I])),by=school];z[,`:=`(gw=grade-gb,sw=ESCS-sb)];fit<-lm.wfit(model.matrix(~gw+gb+sw+sb+female+lang+fb+lb+agegroup,z),Y,w);b<-fit$coefficients;rbind(grade=b['gw',],contextual=b['sb',]-b['sw',])})
  b<-fits[[1]];vr<-Reduce('+',lapply(fits[-1],function(x)(x-b)^2))/20;q<-rowMeans(b);se<-sqrt(rowMeans(vr)+1.1*apply(b,1,var));nr<-nr+1;r[[nr]]<-data.table(CNT=cc,domain=dom,sample=samp,n=nrow(d),term=names(q),est=q,se=se,lo=q-1.96*se,hi=q+1.96*se)
 }
 fwrite(rbindlist(v)[,.(ICC=mean(ICC)),by=.(CNT,domain)],paste0(O,'null_icc.csv'));fwrite(rbindlist(r),paste0(O,'diagnostics.csv'));cat(cc,dom,'diagnostics complete\n');flush.console()
}

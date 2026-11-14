suppressPackageStartupMessages({library(data.table);library(grf)})
setDTthreads(2);O<-'03_outputs/caucasus_central_asia/overlap_diagnostics/'
a<-fread('01_data/derived/caucasus_central_asia/analysis_input.csv.gz')
wm<-function(x,w)sum(x*w)/sum(w)
a[,`:=`(grade=ST001D01T,age=round(12*AGE),female=as.numeric(ST004D01T==1),lang=as.numeric(ST022Q01TA!=1))]
r<-list();s<-list();g<-list();ii<-0
for(cc in c('ARM','GEO','AZE')) {
 f<-a[CNT==cc];f[,complete:=complete.cases(grade,AGE,ESCS,female,lang)]
 g[[cc]]<-f[,.(n=.N,weight=sum(W_FSTUWT),complete_weight=wm(as.numeric(complete),W_FSTUWT),escs_missing=wm(as.numeric(is.na(ESCS)),W_FSTUWT),science_PV1=wm(PV1SCIE,W_FSTUWT)),by=.(CNT,grade)]
 for(ss in c('full','complete')){
  z<-if(ss=='full')copy(f[!is.na(grade)])else copy(f[complete==TRUE]);z[,`:=`(n9=sum(grade==9),n10=sum(grade==10),ng=uniqueN(grade)),by=CNTSCHID]
  z[,agmix:=uniqueN(grade)>1,by=.(CNTSCHID,age)]
  s[[paste(cc,ss)]]<-data.table(CNT=cc,sample=ss,n=nrow(z),schools=uniqueN(z$CNTSCHID),share_any_multigrade=wm(as.numeric(z$ng>1),z$W_FSTUWT),share_both_9_10=wm(as.numeric(z$n9>0&z$n10>0),z$W_FSTUWT),share_5_each=wm(as.numeric(z$n9>=5&z$n10>=5),z$W_FSTUWT),share_school_age_mixed=wm(as.numeric(z$agmix),z$W_FSTUWT))
 }
 d<-f[complete==TRUE&grade%in%c(9,10)];d[,`:=`(W=as.numeric(grade==10),gb=wm(grade,W_FSTUWT),sb=wm(ESCS,W_FSTUWT),n9=sum(grade==9),n10=sum(grade==10)),by=CNTSCHID]
 forms<-list(age=~factor(age)-1,age_SES=~factor(age)+ESCS+sb+female+lang-1,age_SES_grade_mix=~factor(age)+ESCS+sb+female+lang+gb-1)
 for(v in names(forms)){
  X<-model.matrix(forms[[v]],d);fit<-regression_forest(X,d$W,num.trees=1000,min.node.size=20,clusters=d$CNTSCHID,sample.weights=d$W_FSTUWT,num.threads=4,seed=13)
  e<-predict(fit)$predictions
  ii<-ii+1;r[[ii]]<-data.table(CNT=cc,spec=v,n=nrow(d),fraction_grade10=wm(d$W,d$W_FSTUWT),outside_10_90=wm(as.numeric(e<.1|e>.9),d$W_FSTUWT),outside_05_95=wm(as.numeric(e<.05|e>.95),d$W_FSTUWT),brier=wm((d$W-e)^2,d$W_FSTUWT))
 }
 d<-d[n9>=5&n10>=5];X<-model.matrix(~factor(age)+ESCS+sb+female+lang-1,d)
 fit<-regression_forest(X,d$W,num.trees=1000,min.node.size=20,clusters=d$CNTSCHID,sample.weights=d$W_FSTUWT,num.threads=4,seed=13);e<-predict(fit)$predictions
 ii<-ii+1;r[[ii]]<-data.table(CNT=cc,spec='5_each_age_SES',n=nrow(d),fraction_grade10=wm(d$W,d$W_FSTUWT),outside_10_90=wm(as.numeric(e<.1|e>.9),d$W_FSTUWT),outside_05_95=wm(as.numeric(e<.05|e>.95),d$W_FSTUWT),brier=wm((d$W-e)^2,d$W_FSTUWT))
 cat(cc,'done\n');flush.console()
}
fwrite(rbindlist(r),paste0(O,'propensity.csv'));fwrite(rbindlist(s),paste0(O,'school_support.csv'));fwrite(rbindlist(g),paste0(O,'grade_selection.csv'))
print(rbindlist(r));print(rbindlist(s));print(rbindlist(g))

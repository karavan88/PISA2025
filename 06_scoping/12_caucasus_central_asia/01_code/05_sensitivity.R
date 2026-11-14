# Replacement SES exposures, matched versus available sample; ten PVs and Fay-BRR.
suppressPackageStartupMessages(library(data.table));setDTthreads(2)
O<-'03_outputs/caucasus_central_asia/';a<-fread('01_data/derived/caucasus_central_asia/analysis_input.csv.gz')
a[,`:=`(grade=ST001D01T,school=factor(CNTSCHID),agegroup=factor(round(12*AGE)),female=as.numeric(ST004D01T==1),lang=as.numeric(ST022Q01TA!=1))]
material<-c('ST250Q08DA','ST250Q09DA','ST250Q12DA','ST250Q15DA');educ<-c('ST250Q02JA','ST250Q05JA','ST250Q20DA')
for(v in c(material,educ))set(a,which(!a[[v]]%in%c(1,2)),v,NA_real_)
a[,deprivation:=rowSums(as.matrix(.SD)==2),.SDcols=material]
a[,educ_deprivation:=rowSums(as.matrix(.SD)==2),.SDcols=educ]
wm<-function(x,w)sum(x*w)/sum(w)
repnames<-grep('^W_FSTURWT[0-9]+$',names(a),value=TRUE)
a[,digital_deprivation:=rowSums(as.matrix(.SD)==2),.SDcols=c('ST250Q02JA','ST250Q05JA')]
sets<-list(digital_deprivation='digital_deprivation',ESCS='ESCS',parent_education='PAREDINT',parent_occupation='HISEI',possessions='HOMEPOS',components=c('PAREDINT','HISEI','HOMEPOS'),material_deprivation='deprivation',educational_deprivation='educ_deprivation')
res<-list();cov<-list();nr<-0;nc<-0
for(cc in unique(a$CNT)){
 f<-a[CNT==cc];baseok<-complete.cases(f[,.(grade,AGE,female,lang)])&f$W_FSTUWT>0
 for(ss in names(sets))for(samp in c('available','matched_ESCS')){
  vars<-sets[[ss]];ok<-baseok&complete.cases(f[,vars,with=FALSE]);if(samp=='matched_ESCS')ok<-ok&!is.na(f$ESCS)
  d<-copy(f[ok]); if(nrow(d)<100)next
  nc<-nc+1;cov[[nc]]<-data.table(CNT=cc,exposure=ss,sample=samp,n=nrow(d),schools=uniqueN(d$school),retained_weight=sum(d$W_FSTUWT)/sum(f$W_FSTUWT),zero_share=if(ss%in%c('material_deprivation','educational_deprivation','digital_deprivation'))wm(as.numeric(d[[vars]]==0),d$W_FSTUWT)else NA_real_)
  # Use raw units; grade slopes remain points per grade regardless of exposure units.
  designs<-lapply(c('W_FSTUWT',repnames),function(ww){z<-copy(d);w<-z[[ww]];z[,gb:=wm(grade,w[.I]),by=school];z[,gw:=grade-gb]
   for(v in vars){bn<-paste0(v,'_b');wn<-paste0(v,'_w');z[,(bn):=wm(get(v),w[.I]),by=school];z[,(wn):=get(v)-get(bn)]}
   terms<-c('gw','gb',paste0(vars,'_w'),paste0(vars,'_b'),'female','lang','agegroup');X<-model.matrix(reformulate(terms),z);list(X=X,w=w)})
  for(dom in c('SCIE','MATH','READ')){
   Y<-as.matrix(d[,paste0('PV',1:10,dom),with=FALSE]);if(all(is.na(Y)))next
   co<-lapply(designs,function(dd)lm.wfit(dd$X,Y,dd$w)$coefficients);b<-co[[1]];vr<-Reduce('+',lapply(co[-1],function(x)(x-b)^2))/20
   q<-rowMeans(b);se<-sqrt(rowMeans(vr)+1.1*apply(b,1,var));nr<-nr+1;res[[nr]]<-data.table(CNT=cc,domain=dom,exposure=ss,sample=samp,term=names(q),est=q,se=se,lo=q-1.96*se,hi=q+1.96*se)
   # On the identical rows, fit ESCS reference for genuine measurement comparisons.
   if(samp=='matched_ESCS'&&ss!='ESCS'){
    co2<-lapply(c('W_FSTUWT',repnames),function(ww){z<-copy(d);w<-z[[ww]];z[,`:=`(gb=wm(grade,w[.I]),sb=wm(ESCS,w[.I])),by=school];z[,`:=`(gw=grade-gb,sw=ESCS-sb)];lm.wfit(model.matrix(~gw+gb+sw+sb+female+lang+agegroup,z),Y,w)$coefficients})
    b2<-co2[[1]];vr2<-Reduce('+',lapply(co2[-1],function(x)(x-b2)^2))/20;q<-rowMeans(b2);se<-sqrt(rowMeans(vr2)+1.1*apply(b2,1,var));nr<-nr+1;res[[nr]]<-data.table(CNT=cc,domain=dom,exposure=paste0('ESCS_reference_for_',ss),sample=samp,term=names(q),est=q,se=se,lo=q-1.96*se,hi=q+1.96*se)
   }
  }
 }
 cat(cc,'sensitivity complete\n');flush.console();fwrite(rbindlist(res),paste0(O,'sensitivity.csv'));fwrite(rbindlist(cov),paste0(O,'sensitivity_coverage.csv'))
}
writeLines(capture.output(sessionInfo()),paste0(O,'sessionInfo_sensitivity.txt'))

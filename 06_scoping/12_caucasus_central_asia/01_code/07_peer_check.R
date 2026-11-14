# Leave-one-out peer SES removes mechanical self-inclusion; does not identify peer causality.
suppressPackageStartupMessages(library(data.table));setDTthreads(2)
O<-'03_outputs/caucasus_central_asia/';a<-fread('01_data/derived/caucasus_central_asia/analysis_input.csv.gz')
a[,`:=`(grade=ST001D01T,school=factor(CNTSCHID),agegroup=factor(round(12*AGE)),female=as.numeric(ST004D01T==1),lang=as.numeric(ST022Q01TA!=1))]
wm<-function(x,w)sum(x*w)/sum(w);rn<-grep('^W_FSTURWT[0-9]+$',names(a),value=TRUE);rr<-list();nn<-0
for(cc in unique(a$CNT)){
 d<-a[CNT==cc&complete.cases(grade,AGE,ESCS,female,lang)&W_FSTUWT>0];d[,ns:=.N,by=school];d<-d[ns>1]
 top<-d[,.(weight=sum(W_FSTUWT)),by=grade][order(-weight)]$grade[1:2]
 for(spec in c('inclusive','leave_one_out','modal_two_grades')){
  z0<-copy(d);if(spec=='modal_two_grades')z0<-z0[grade%in%top]
  designs<-lapply(c('W_FSTUWT',rn),function(ww){z<-copy(z0);w<-z[[ww]];z[,`:=`(gb=wm(grade,w[.I]),sb=wm(ESCS,w[.I]),swgt=sum(w[.I]),fb=wm(female,w[.I]),lb=wm(lang,w[.I])),by=school];z[,`:=`(gw=grade-gb,peer=(sb*swgt-w*ESCS)/(swgt-w))];if(spec!='leave_one_out')z[,peer:=sb];list(X=model.matrix(~gw+gb+ESCS+peer+female+lang+fb+lb+agegroup,z),w=w)})
  for(dom in c('SCIE','MATH','READ')){
   Y<-as.matrix(z0[,paste0('PV',1:10,dom),with=FALSE]);if(all(is.na(Y)))next
   fits<-lapply(designs,function(dd)lm.wfit(dd$X,Y,dd$w)$coefficients[c('gw','peer'),,drop=FALSE]);b<-fits[[1]];vr<-Reduce('+',lapply(fits[-1],function(x)(x-b)^2))/20;q<-rowMeans(b);se<-sqrt(rowMeans(vr)+1.1*apply(b,1,var));nn<-nn+1;rr[[nn]]<-data.table(CNT=cc,domain=dom,spec=spec,n=nrow(z0),grades=paste(sort(top),collapse=','),term=names(q),est=q,se=se,lo=q-1.96*se,hi=q+1.96*se)
  }
 }
 cat(cc,'peer check complete\n');flush.console();fwrite(rbindlist(rr),paste0(O,'peer_check.csv'))
}

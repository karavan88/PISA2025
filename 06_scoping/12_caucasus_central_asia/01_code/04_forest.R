# Exploratory heterogeneous CONDITIONAL grade slopes; causal interpretation requires unconfounded grade.
# All 10 PVs; honest school-clustered forests; school-clustered score SEs + PV uncertainty.
# These intervals are not full PISA BRR intervals (forests are not refitted 80 times).
suppressPackageStartupMessages({library(data.table);library(grf)})
setDTthreads(2); O<-'03_outputs/caucasus_central_asia/'
a<-fread('01_data/derived/caucasus_central_asia/analysis_input.csv.gz')
a[,`:=`(grade=ST001D01T,school=as.integer(factor(CNTSCHID)),agegroup=round(12*AGE),female=as.numeric(ST004D01T==1),lang=as.numeric(ST022Q01TA!=1))]
wm<-function(x,w)sum(x*w)/sum(w)
# Weighted inverse-CDF quantiles; tied school values always stay together.
decile<-function(x,w){o<-order(x); breaks<-sapply((1:9)/10,function(p)x[o][which(cumsum(w[o])/sum(w)>=p)[1]]);findInterval(x,unique(breaks))+1L}
pool<-function(z,keys)z[, {q<-mean(est);v<-mean(se^2)+(1+1/.N)*var(est);list(est=q,se=sqrt(v),lo=q-1.96*sqrt(v),hi=q+1.96*sqrt(v),npv=.N)},by=keys]
# Cluster influence SE for a weighted mean / contrast of scores.
scoremean<-function(s,w,cl){mu<-wm(s,w);u<-rowsum(w*(s-mu)/sum(w),cl,reorder=FALSE);J<-nrow(u);c(est=mu,se=sqrt(sum(u^2)*J/(J-1)))}
allg<-list();allc<-list();allt<-list(); alls<-list();ng<-0;nc<-0;nt<-0;ns<-0
for(cc in unique(a$CNT)){
 d<-a[CNT==cc & complete.cases(grade,AGE,ESCS,female,lang)&W_FSTUWT>0]
 d[,`:=`(gb=wm(grade,W_FSTUWT),sb=wm(ESCS,W_FSTUWT),fb=wm(female,W_FSTUWT),lb=wm(lang,W_FSTUWT)),by=school]
 d[,`:=`(student_decile=decile(ESCS,W_FSTUWT),school_decile=decile(sb,W_FSTUWT))]
 X<-model.matrix(~ESCS+sb+gb+female+lang+fb+lb+factor(agegroup)-1,d)
 w<-d$W_FSTUWT/mean(d$W_FSTUWT)
 for(dom in c('SCIE','MATH','READ')){
  if(all(is.na(d[[paste0('PV1',dom)]])))next
  for(k in 1:10){
   f<-causal_forest(X,Y=d[[paste0('PV',k,dom)]],W=d$grade,num.trees=2000,min.node.size=20,clusters=d$school,sample.weights=w,equalize.cluster.weights=FALSE,honesty=TRUE,num.threads=4,seed=20261113+k)
   score<-get_scores(f,num.trees.for.weights=1000)
   tau<-predict(f)$predictions
   resw<-d$grade-f$W.hat
   av<-scoremean(score,w,d$school);nt<-nt+1;allt[[nt]]<-data.table(CNT=cc,domain=dom,pv=k,est=av[1],se=av[2])
   for(axis in c('student_decile','school_decile')){
    for(q in sort(unique(d[[axis]]))){ii<-which(d[[axis]]==q);b<-scoremean(score[ii],w[ii],d$school[ii]);ng<-ng+1;allg[[ng]]<-data.table(CNT=cc,domain=dom,pv=k,axis=axis,decile=q,est=b[1],se=b[2],n=length(ii),schools=uniqueN(d$school[ii]),neff=sum(w[ii])^2/sum(w[ii]^2),residual_grade_variance=wm(resw[ii]^2,w[ii]),prediction=wm(tau[ii],w[ii]))}
    # D10 minus D1 with covariance across students in the same school preserved.
    lo<-which(d[[axis]]==1); hi<-which(d[[axis]]==10)
    if(length(lo)&&length(hi)){
     mlo<-wm(score[lo],w[lo]);mhi<-wm(score[hi],w[hi]);u<-numeric(nrow(d));u[hi]<-w[hi]*(score[hi]-mhi)/sum(w[hi]);u[lo]<--w[lo]*(score[lo]-mlo)/sum(w[lo]);z<-rowsum(u,d$school);J<-nrow(z);nc<-nc+1;allc[[nc]]<-data.table(CNT=cc,domain=dom,pv=k,axis=axis,est=mhi-mlo,se=sqrt(sum(z^2)*J/(J-1)))
    }
   }
   if(k==1){
    z<-d[,.(CNT,school,student_decile,school_decile)];z[,`:=`(w=w,tau=tau,resw=resw)]
    support<-z[,.(n=.N,schools=uniqueN(school),neff=sum(w)^2/sum(w^2),residual_grade_variance=wm(resw^2,w)),by=.(CNT,student_decile,school_decile)]
    ns<-ns+1;alls[[ns]]<-data.table(domain=dom,support)
   }
  }
  cat(cc,dom,'forest complete\n');flush.console()
  fwrite(pool(rbindlist(allg),c('CNT','domain','axis','decile')),paste0(O,'forest_deciles.csv'))
  fwrite(rbindlist(allg)[,.(n=first(n),schools=first(schools),neff=first(neff),residual_grade_variance=mean(residual_grade_variance),prediction=mean(prediction)),by=.(CNT,domain,axis,decile)],paste0(O,'forest_support.csv'))
  ct<-pool(rbindlist(allc),c('CNT','domain','axis'));ct[,p:=2*pnorm(-abs(est/se))];ct[,p_holm:=p.adjust(p,'holm')];fwrite(ct,paste0(O,'forest_contrasts.csv'))
  fwrite(pool(rbindlist(allt),c('CNT','domain')),paste0(O,'forest_average.csv'))
  fwrite(rbindlist(alls),paste0(O,'forest_joint_support.csv'))
 }
}
writeLines(capture.output(sessionInfo()),paste0(O,'sessionInfo_forest.txt'))

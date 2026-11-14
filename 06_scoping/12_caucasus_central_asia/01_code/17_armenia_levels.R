suppressPackageStartupMessages({library(data.table);library(fixest);library(lme4)})
setDTthreads(2);setFixest_nthreads(2)
O<-'03_outputs/caucasus_central_asia/armenia_levels/'
a<-fread('01_data/derived/caucasus_central_asia/analysis_input.csv.gz')[CNT=='ARM']
a[,`:=`(school=factor(CNTSCHID),age=factor(round(12*AGE)),grade=factor(ST001D01T),female=as.numeric(ST004D01T==1),lang=as.numeric(ST022Q01TA!=1))]
repnames<-grep('^W_FSTURWT[0-9]+$',names(a),value=TRUE);stopifnot(length(repnames)==80)
wm<-function(x,w)sum(x*w)/sum(w)
pool<-function(d,keys)d[, {m<-.N;q<-mean(est);u<-mean(se^2);b<-var(est);v<-u+(1+1/m)*b;df<-if(b<1e-14)Inf else (m-1)*(1+u/((1+1/m)*b))^2;crit<-qt(.975,df);list(est=q,se=sqrt(v),lo=q-crit*sqrt(v),hi=q+crit*sqrt(v),p=2*pt(-abs(q/sqrt(v)),df),npv=m)},by=keys]
base<-a[complete.cases(age,grade,female,lang)&W_FSTUWT>0]
specs<-list(possessions='HOMEPOS',education='PAREDINT',joint=c('HOMEPOS','PAREDINT'),escs='ESCS',possessions_matched_joint='HOMEPOS',possessions_matched_escs='HOMEPOS',escs_matched_possessions='ESCS')
required<-list(possessions='HOMEPOS',education='PAREDINT',joint=c('HOMEPOS','PAREDINT'),escs='ESCS',possessions_matched_joint=c('HOMEPOS','PAREDINT'),possessions_matched_escs=c('HOMEPOS','ESCS'),escs_matched_possessions=c('HOMEPOS','ESCS'))
results<-list();cover<-list();mixed<-list();varsout<-list();selection<-list();ni<-0;nm<-0;nv<-0;ns<-0
for(sp in names(specs)){
 vv<-specs[[sp]];req<-required[[sp]];d<-base[complete.cases(base[,..req])]
 cover[[sp]]<-data.table(sample=sp,n=nrow(d),schools=uniqueN(d$school),weighted_share=sum(d$W_FSTUWT)/sum(a$W_FSTUWT),unweighted_share=nrow(d)/nrow(a))
 # All sampled schoolmates with an outcome contribute to the peer-score mean.
 # SES school means use the analytic sample, preserving the exact within/between identity.
 designs<-lapply(c('W_FSTUWT',repnames),function(wn){z<-copy(d);w<-z[[wn]];z[,sw:=sum(w[.I]),by=school]
 for(v in vv){z[,(paste0(v,'_school')):=wm(get(v),w[.I]),by=school];z[,(paste0(v,'_loo')):=(get(paste0(v,'_school'))*sw-w*get(v))/(sw-w)]}
 list(z=z,w=w,wn=wn)})
 for(dom in c('SCIE','MATH','READ')){
 Y<-as.matrix(d[,paste0('PV',1:10,dom),with=FALSE]);stopifnot(!anyNA(Y))
 # Compare retained/excluded achievement, recomputing means under all replicate weights.
 keep<-a$CNTSTUID%in%d$CNTSTUID
 sc<-sapply(c('W_FSTUWT',repnames),function(wn)sapply(1:10,function(k){y<-a[[paste0('PV',k,dom)]];wm(y[keep],a[[wn]][keep])-wm(y[!keep],a[[wn]][!keep])}))
 ns<-ns+1;selection[[ns]]<-data.table(sample=sp,domain=dom,pv=1:10,est=sc[,1],se=sqrt(rowSums((sc[,-1]-sc[,1])^2)/20))
 for(model in c('composition','school_FE','loo_composition','peer_score','joint_peer')){
 cat(sp,dom,model,'start\n');flush.console()
 co<-lapply(designs,function(dd){z<-copy(dd$z);w<-dd$w
 if(model%in%c('peer_score','joint_peer')){
 f<-copy(a);f[,ww:=get(dd$wn)];f[,totalw:=sum(ww),by=school]
 peer<-sapply(1:10,function(k){v<-paste0('PV',k,dom);f[,sy:=sum(get(v)*ww),by=school];(f$sy-f$ww*f[[v]])/(f$totalw-f$ww)})
 peer<-peer[match(z$CNTSTUID,a$CNTSTUID),,drop=FALSE]
 }else peer<-NULL
 own<-vv;context<-if(model=='loo_composition')paste0(vv,'_loo')else paste0(vv,'_school')
 terms<-c(own,if(model%in%c('composition','loo_composition','joint_peer'))context,'female','lang')
 if(model=='school_FE'){
 b<-sapply(1:10,function(k){set(z,j='y',value=Y[,k]);coef(feols(as.formula(paste('y~',paste(terms,collapse='+'),'|school+age+grade')),z,weights=w,notes=FALSE))})
 }else if(is.null(peer)){
 X<-model.matrix(as.formula(paste('~',paste(c(terms,'age','grade'),collapse='+'))),z);ok<-as.integer(rownames(X));b<-lm.wfit(X,Y[ok,,drop=FALSE],w[ok])$coefficients
 }else{
 b<-sapply(1:10,function(k){set(z,j='peer_score',value=peer[,k]/10);ok<-is.finite(z$peer_score);X<-model.matrix(as.formula(paste('~',paste(c(terms,'peer_score','age','grade'),collapse='+'))),z[ok]);lm.wfit(X,Y[ok,k],w[ok])$coefficients})
 }
 # Own coefficient is within; own + school is between; school coefficient is contextual.
 if(model=='composition'){
 extra<-sapply(vv,function(v)b[v,]+b[paste0(v,'_school'),]);if(length(vv)==1)extra<-matrix(extra,ncol=1)
 extra<-t(extra);rownames(extra)<-paste0(vv,'_between');b<-rbind(b,extra)
 }
 b
 })
 b<-co[[1]];se<-sqrt(Reduce('+',lapply(co[-1],function(x)(x-b)^2))/20)
 for(k in 1:10){ni<-ni+1;results[[ni]]<-data.table(sample=sp,domain=dom,model=model,pv=k,term=rownames(b),est=b[,k],se=se[,k])}
 }
 if(sp%in%c('possessions','education','joint')){
 z<-designs[[1]]$z
 for(k in 1:10){set(z,j='y',value=Y[,k])
 for(model in c('null','controls','composition','random_age_grade')){
 rhs<-switch(model,null='1+(1|school)',controls='female+lang+age+grade+(1|school)',composition=paste(paste(c(vv,paste0(vv,'_school'),'female','lang','age','grade'),collapse='+'),'+(1|school)'),random_age_grade=paste(paste(c(vv,paste0(vv,'_school'),'female','lang'),collapse='+'),'+(1|school)+(1|age)+(1|grade)'))
 fit<-suppressWarnings(lmer(as.formula(paste('y~',rhs)),z,REML=TRUE,control=lmerControl(optimizer='bobyqa')))
 cf<-fixef(fit);ss<-sqrt(diag(vcov(fit)));nm<-nm+1;mixed[[nm]]<-data.table(sample=sp,domain=dom,model=model,pv=k,term=names(cf),est=cf,se=ss)
 vc<-as.data.frame(VarCorr(fit));nv<-nv+1;varsout[[nv]]<-data.table(sample=sp,domain=dom,model=model,pv=k,component=vc$grp,variance=vc$vcov,singular=isSingular(fit),no_lme4_messages=is.null(fit@optinfo$conv$lme4$messages))
 }
 }
 }
 cat(sp,dom,'done\n');flush.console()
 rr<-rbindlist(results);fwrite(rr,paste0(O,'regression_pv.csv'));fwrite(pool(rr[is.finite(est)&is.finite(se)],c('sample','domain','model','term')),paste0(O,'regression.csv'))
 }
}
fwrite(rbindlist(cover),paste0(O,'coverage.csv'));fwrite(pool(rbindlist(selection),c('sample','domain')),paste0(O,'selection.csv'))
fwrite(rbindlist(mixed),paste0(O,'mixed_pv.csv'));fwrite(pool(rbindlist(mixed),c('sample','domain','model','term')),paste0(O,'mixed.csv'));fwrite(rbindlist(varsout),paste0(O,'variance_components_pv.csv'))
fwrite(rbindlist(varsout)[,.(variance=mean(variance),singular_fits=sum(singular),flagged_fits=sum(!no_lme4_messages)),by=.(sample,domain,model,component)],paste0(O,'variance_components.csv'))
fwrite(data.table(stage=c('all_Armenia','age_grade_sex_language'),n=c(nrow(a),nrow(base)),schools=c(uniqueN(a$school),uniqueN(base$school)),weighted_share=c(1,sum(base$W_FSTUWT)/sum(a$W_FSTUWT))),paste0(O,'base_coverage.csv'))
writeLines(capture.output(sessionInfo()),paste0(O,'sessionInfo.txt'))

# Armenia: honest binary grade forests targeting overlap; all ten PVs in three domains.
# Grade is observational. Neither overlap weighting nor forests establishes causal identification.
suppressPackageStartupMessages({library(data.table);library(grf);library(sandwich);library(fixest)})
setDTthreads(2);setFixest_nthreads(2)
O<-'03_outputs/caucasus_central_asia/armenia_redesign/'
D<-'01_data/derived/caucasus_central_asia/armenia_redesign/'
a<-fread('01_data/derived/caucasus_central_asia/analysis_input.csv.gz')[CNT=='ARM']
a[,`:=`(grade=ST001D01T,W=as.numeric(ST001D01T==10),age=round(12*AGE),female=as.numeric(ST004D01T==1),lang=as.numeric(ST022Q01TA!=1),school=as.integer(factor(CNTSCHID)))]
wm<-function(x,w)sum(x*w)/sum(w)
# Context means use all Armenia respondents with the relevant input, not parent-complete cases.
for(v in c('HOMEPOS','PAREDINT','HISEI')) {
 b<-a[!is.na(get(v)),.(val=wm(get(v),W_FSTUWT),nmean=.N),by=school]
 a[b,on='school',(paste0(v,'_school')):=i.val]
 a[b,on='school',(paste0(v,'_school_n')):=i.nmean]
}
base<-a[grade%in%c(9,10)&complete.cases(age,female,lang,HOMEPOS,HOMEPOS_school)&W_FSTUWT>0]
qualify<-function(d,k){d<-copy(d);d[,`:=`(n9=sum(W==0),n10=sum(W==1)),by=school];d[n9>=k&n10>=k]}
base2<-qualify(base,2)
xmat<-function(d,parent=NULL){v<-c('HOMEPOS','HOMEPOS_school','female','lang',parent,if(!is.null(parent))paste0(parent,'_school'));model.matrix(reformulate(c(v,'factor(age)'),intercept=FALSE),d)}
prop<-function(d,parent=NULL){rf<-regression_forest(xmat(d,parent),d$W,num.trees=2000,min.node.size=15,clusters=d$school,sample.weights=d$W_FSTUWT,num.threads=4,seed=202611130);predict(rf)$predictions}
quantcuts<-function(x,w){o<-order(x);unique(sapply(c(1/3,2/3),function(p)x[o][which(cumsum(w[o])/sum(w)>=p)[1]]))}
maincuts<-list(HOMEPOS=quantcuts(base2$HOMEPOS,base2$W_FSTUWT),HOMEPOS_school=quantcuts(base2$HOMEPOS_school,base2$W_FSTUWT))
coverage<-list();cutsout<-list();co<-0;datasets<-list()
prepare<-function(label,parent=NULL,k=2,trim=.1){
 d<-copy(base);if(!is.null(parent))d<-d[complete.cases(d[,c(parent,paste0(parent,'_school')),with=FALSE])]
 nresponse<-nrow(d);d<-qualify(d,k);nschool<-nrow(d);npre9<-sum(d$W==0);Jpre<-uniqueN(d$school)
 e<-prop(d,parent);d[,e0:=e];d<-d[e0>=trim&e0<=1-trim];ntrim<-nrow(d);d<-qualify(d,1)
 co<<-co+1;coverage[[co]]<<-data.table(spec=label,parent=if(is.null(parent))'none' else parent,minimum_per_grade=k,trim=trim,n_response=nresponse,n_school_supported=nschool,n_grade9_before_trim=npre9,schools_before_trim=Jpre,n_after_probability_trim=ntrim,n=nrow(d),n9=sum(d$W==0),n10=sum(d$W==1),schools=uniqueN(d$school),weight_share_all_ARM=sum(d$W_FSTUWT)/sum(a$W_FSTUWT),weight_share_base=sum(d$W_FSTUWT)/sum(base$W_FSTUWT),e_min=min(d$e0),e_max=max(d$e0),overlap_neff=sum(d$W_FSTUWT*d$e0*(1-d$e0))^2/sum((d$W_FSTUWT*d$e0*(1-d$e0))^2))
 cuts<-maincuts
 if(!is.null(parent))for(v in c(parent,paste0(parent,'_school')))cuts[[v]]<-quantcuts(d[[v]],d$W_FSTUWT)
 for(v in names(cuts))d[,(paste0('group_',v)):=as.integer(cut(get(v),breaks=c(-Inf,cuts[[v]],Inf),right=TRUE))]
 cutsout[[label]]<<-rbindlist(lapply(names(cuts),function(v)data.table(spec=label,moderator=v,cut=cuts[[v]])))
 list(d=d,parent=parent)
}
datasets$possessions_main<-prepare('possessions_main')
datasets$possessions_trim05<-prepare('possessions_trim05',trim=.05)
datasets$possessions_strict5<-prepare('possessions_strict5',k=5)
for(p in c('PAREDINT','HISEI')){
 label<-if(p=='PAREDINT')'plus_education' else 'plus_occupation'
 datasets[[label]]<-prepare(label,parent=p)
 z<-copy(datasets[[label]]$d);z[,e0:=prop(z)]
 ml<-paste0('possessions_matched_',p)
 datasets[[ml]]<-list(d=z,parent=NULL)
 co<-co+1;cr<-copy(coverage[[co-1]]);cr[,`:=`(spec=ml,parent='none',e_min=min(z$e0),e_max=max(z$e0),overlap_neff=sum(z$W_FSTUWT*z$e0*(1-z$e0))^2/sum((z$W_FSTUWT*z$e0*(1-z$e0))^2))];coverage[[co]]<-cr
}
fwrite(rbindlist(coverage),paste0(O,'coverage.csv'));fwrite(rbindlist(cutsout),paste0(O,'group_cutpoints.csv'))
# Retain sample support and estimated overlap weights as local analysis data.
saveRDS(datasets,paste0(D,'samples.rds'))
support<-rbindlist(lapply(names(datasets),function(sp){d<-datasets[[sp]]$d;p<-datasets[[sp]]$parent;vars<-c('HOMEPOS','HOMEPOS_school',p,if(!is.null(p))paste0(p,'_school'));rbindlist(lapply(vars,function(v)d[,.(spec=sp,moderator=v,n=.N,n9=sum(W==0),n10=sum(W==1),schools=uniqueN(school),overlap_neff=sum(W_FSTUWT*e0*(1-e0))^2/sum((W_FSTUWT*e0*(1-e0))^2),e_min=min(e0),e_max=max(e0)),by=.(group=get(paste0('group_',v)))]))}))
support[,adequate:=n9>=20&n10>=20&schools>=10]
fwrite(support,paste0(O,'group_support.csv'))
# Sampling variances are school-clustered, not full replicate-refitted forest inference.
# MI df capped at schools-1; intervals are exploratory, especially with few schools.
pool<-function(z,keys){z[,{
 est0<-mean(est);u<-mean(se^2);b<-var(est);vv<-u+1.1*b;dfmi<-if(b<1e-14)Inf else 9*(1+u/(1.1*b))^2;df0<-min(min(df_cluster),dfmi);crit<-qt(.975,df0)
 list(est=est0,se=sqrt(vv),lo=est0-crit*sqrt(vv),hi=est0+crit*sqrt(vv),df=df0,p=2*pt(-abs(est0/sqrt(vv)),df0),npv=.N)
 },by=keys]}
results<-list();groups<-list();contrasts<-list();benchmark<-list();stable<-list();nr<-0;ng<-0;nc<-0;nb<-0;nt<-0
for(sp in names(datasets)){
 d<-datasets[[sp]]$d;parent<-datasets[[sp]]$parent;X<-xmat(d,parent);w<-d$W_FSTUWT;cl<-d$school;J<-uniqueN(cl)
 vars<-c('HOMEPOS','HOMEPOS_school',parent,if(!is.null(parent))paste0(parent,'_school'))
 for(dom in c('SCIE','MATH','READ'))for(k in 1:10){
  y<-d[[paste0('PV',k,dom)]]
  f<-causal_forest(X,y,d$W,W.hat=d$e0,num.trees=2000,min.node.size=15,clusters=cl,sample.weights=w,equalize.cluster.weights=FALSE,num.threads=4,seed=202611130+k)
  at<-average_treatment_effect(f,target.sample='overlap')
  yr<-y-f$Y.hat;wr<-d$W-f$W.hat
  m<-lm(yr~wr,weights=w);vc<-vcovCL(m,cluster=cl)
  stopifnot(abs(coef(m)[2]-at[1])<1e-8,abs(sqrt(vc[2,2])-at[2])<1e-8)
  nr<-nr+1;results[[nr]]<-data.table(spec=sp,domain=dom,pv=k,est=at[1],se=at[2],df_cluster=J-1)
  for(v in vars){
   g<-factor(d[[paste0('group_',v)]]);gm<-lm(yr~0+g+g:wr,weights=w);gv<-vcovCL(gm,cluster=cl);bn<-names(coef(gm));ix<-grep(':wr$',bn);valid<-TRUE
   for(j in seq_along(ix)){
    q<-as.integer(sub(':wr','',sub('^g','',bn[ix[j]])));ok<-which(as.integer(as.character(g))==q);subat<-average_treatment_effect(f,target.sample='overlap',subset=ok)
    # Separate and joint regressions give identical slopes; covariance preserves cross-group school dependence.
    stopifnot(abs(coef(gm)[ix[j]]-subat[1])<1e-7)
    ng<-ng+1;groups[[ng]]<-data.table(spec=sp,domain=dom,pv=k,moderator=v,group=q,est=coef(gm)[ix[j]],se=sqrt(gv[ix[j],ix[j]]),df_cluster=uniqueN(cl[ok])-1)
   }
   low<-ix[1];high<-tail(ix,1);de<-coef(gm)[high]-coef(gm)[low];se<-sqrt(gv[high,high]+gv[low,low]-2*gv[high,low]);nc<-nc+1
   contrasts[[nc]]<-data.table(spec=sp,domain=dom,pv=k,moderator=v,est=de,se=se,df_cluster=J-1)
  }
  # School-FE benchmark on the same rows and estimated overlap target weights.
  set(d,j='y',value=y);set(d,j='ow',value=w*d$e0*(1-d$e0))
  rhs<-paste(c('W','HOMEPOS','female','lang',parent),collapse='+')
  b<-feols(as.formula(paste0('y~',rhs,'|school+age')),d,weights=~ow,cluster=~school,notes=FALSE)
  nb<-nb+1;benchmark[[nb]]<-data.table(spec=sp,domain=dom,pv=k,est=coef(b)['W'],se=fixest::se(b)['W'],df_cluster=J-1)
  if(sp=='possessions_main'&&k==1){
   fwrite(data.table(domain=dom,school=cl,w=w,e=d$e0,W=d$W,yr=yr,wr=wr,tau=predict(f)$predictions),paste0(D,'validation_residuals_',dom,'.csv'))
  }
  if(sp=='possessions_main'&&dom=='SCIE'&&k==1){
   for(seed in c(717,818)){
    fs<-causal_forest(X,y,d$W,W.hat=d$e0,num.trees=2000,min.node.size=15,clusters=cl,sample.weights=w,num.threads=4,seed=seed)
    st<-average_treatment_effect(fs,target.sample='overlap');nt<-nt+1;stable[[nt]]<-data.table(seed=seed,pv=1,domain=dom,est=st[1],se=st[2])
   }
  }
  if(k==10){
   cat(sp,dom,'complete\n');flush.console()
   fwrite(pool(rbindlist(results),c('spec','domain')),paste0(O,'forest_average.csv'))
   fwrite(pool(rbindlist(groups),c('spec','domain','moderator','group')),paste0(O,'forest_groups.csv'))
   ct<-pool(rbindlist(contrasts),c('spec','domain','moderator'));ct[,family:=fcase(spec=='possessions_main','primary',spec%in%c('plus_education','plus_occupation')&moderator%in%c('PAREDINT','PAREDINT_school','HISEI','HISEI_school'),'parental',default='sensitivity')];ct[,p_holm:=p.adjust(p,'holm'),by=family]
   fwrite(ct,paste0(O,'forest_contrasts.csv'));fwrite(pool(rbindlist(benchmark),c('spec','domain')),paste0(O,'school_FE_benchmark.csv'))
  }
 }
}
fwrite(rbindlist(results),paste0(O,'forest_average_pv.csv'));fwrite(rbindlist(groups),paste0(O,'forest_groups_pv.csv'));fwrite(rbindlist(contrasts),paste0(O,'forest_contrasts_pv.csv'));fwrite(rbindlist(stable),paste0(O,'seed_check.csv'))
writeLines(capture.output(sessionInfo()),paste0(O,'sessionInfo.txt'))

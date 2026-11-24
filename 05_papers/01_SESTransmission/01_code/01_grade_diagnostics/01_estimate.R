library(data.table);setDTthreads(1)
ROOT<-normalizePath(getwd());OUT<-Sys.getenv('GRADE_DIAG_OUT','05_papers/01_SESTransmission/04_output/grade_diagnostics_20261117_v2');dir.create(OUT,recursive=TRUE,showWarnings=FALSE)
source('05_papers/01_SESTransmission/01_code/01_grade_diagnostics/guard.R');guard_stage('ols')
D<-readRDS('03_outputs/02_grade_diagnostics/pupils.rds');DICT<-readRDS('03_outputs/02_grade_diagnostics/dictionary.rds');S<-DICT$skills;PV<-paste0('PV',1:10,'READ');RW<-paste0('W_FSTURWT',1:80)
SUB<-c('All','Never repeated','Urban female non-repeaters','Urban male non-repeaters')
mask<-function(d,ss){switch(ss,'All'=rep(TRUE,nrow(d)),'Never repeated'=d$never_repeat%in%TRUE,'Urban female non-repeaters'=d$never_repeat%in%TRUE & d$urban%in%TRUE & d$female_sampling%in%TRUE,'Urban male non-repeaters'=d$never_repeat%in%TRUE & d$urban%in%TRUE & d$female_sampling%in%FALSE)}
valid<-function(d) is.finite(d$grade)&is.finite(d$age_months)&is.finite(d$status)&is.finite(d$nonmale)&is.finite(d$W_FSTUWT)&d$W_FSTUWT>0 & is.finite(d$school_weight)&d$school_weight>0 & !is.na(d$school)
wm<-function(x,w)sum(x*w)/sum(w)
# Within-school absorption is recalculated using each replicate's weights.
fit<-function(X,Y,w,g=NULL){
 if(any(!is.finite(w))||sum(w)<=0)return(NULL)
 if(!is.null(g)){
  sw<-rowsum(w,g,reorder=FALSE);xx<-rowsum(X*w,g,reorder=FALSE)/drop(sw);yy<-rowsum(Y*w,g,reorder=FALSE)/drop(sw)
  xx[!is.finite(xx)]<-0;yy[!is.finite(yy)]<-0;ix<-match(g,rownames(sw))
  X<-X-xx[ix,,drop=FALSE];Y<-Y-yy[ix,,drop=FALSE]
 }
 A<-crossprod(X,w*X)
 if(rcond(A)<1e-11)return(NULL)
 solve(A,crossprod(X,w*Y))
}
reg<-function(d,model,ys,target='grade'){
 fe<-model%in%c('School FE','School FE + quadratic age','Within-school SES slope')
 if(nrow(d)<200 || uniqueN(d$school)<20)return(list(error='Fewer than 200 pupils or 20 schools'))
 vary<-d[,.(vary=uniqueN(grade)>1),by=school]
 if(target=='grade' && (uniqueN(d$grade)<2 || (fe&&sum(vary$vary)<10)))return(list(error='Insufficient grade variation (FE needs at least 10 mixed-grade schools)'))
 if(target=='status'){vars<-'status'}else{
  vars<-c('grade','age_months');if(sd(d$nonmale)>1e-8)vars<-c(vars,'nonmale')
  if(model!='Age adjusted')vars<-c(vars,'status')
  if(model=='School FE + quadratic age'){d<-copy(d);d[,age_squared:=age_months^2];vars<-c(vars,'age_squared')}
 }
 X<-as.matrix(d[,..vars]);if(!fe)X<-cbind('(Intercept)'=1,X)
 Y<-as.matrix(d[,..ys]);point<-fit(X,Y,d$W_FSTUWT,if(fe)d$school else NULL)
 if(is.null(point))return(list(error='Rank-deficient or poorly conditioned design'))
 rr<-lapply(RW,function(r){b<-fit(X,Y,d[[r]],if(fe)d$school else NULL);if(is.null(b))rep(NA_real_,length(ys))else b[target,]})
 reps<-do.call(rbind,rr);if(any(!is.finite(reps)))return(list(error='At least one BRR replicate is not estimable'))
 list(point=point[target,],reps=reps,N=nrow(d),schools=uniqueN(d$school),mixed_schools=sum(vary$vary))
}
pool<-function(r,ys){
 if(!is.null(r$error))return(NULL)
 outcomes<-c(if(any(ys%in%PV))'Reading',intersect(S,ys))
 rbindlist(lapply(outcomes,function(o){j<-which(ys%in%if(o=='Reading')PV else o);pt<-r$point[j];u<-colSums(sweep(r$reps[,j,drop=FALSE],2,pt)^2)/20;se<-sqrt(mean(u)+if(length(j)>1)1.1*var(pt)else 0);data.table(outcome=o,estimate=mean(pt),se=se,N=r$N,schools=r$schools,mixed_schools=r$mixed_schools)}))
}
coverage<-list();desc<-list();coef<-list();fails<-list();bins<-list();draws<-list();inter<-list();plans<-list();models<-c('Age adjusted','SES adjusted','School FE','School FE + quadratic age')
for(cc in DICT$countries$CNT){
 d<-D[CNT==cc];eco<-DICT$countries[CNT==cc,economy]
 for(ss in SUB){
  q<-d[mask(d,ss)];z<-q[in_paper==TRUE & valid(q)]
  # Primary sample has the original paper's complete six-skill profiles and reading PVs.
  stopifnot(all(complete.cases(z[,c(S,PV),with=FALSE])))
  coverage[[paste(cc,ss)]]<-data.table(CNT=cc,economy=eco,sample=ss,source_N=nrow(d),paper_N=sum(d$in_paper),source_subsample_N=nrow(q),N=nrow(z),schools=uniqueN(z$school),mixed_grade_schools=z[,uniqueN(grade)>1,by=school][,sum(V1)],repeat_unknown=sum(is.na(d$never_repeat)),location_unknown=sum(is.na(d$urban)),sampling_gender_unknown=sum(is.na(d$female_sampling)),age_min=if(nrow(z))min(z$age_months+180)else NA,age_max=if(nrow(z))max(z$age_months+180)else NA)
  if(nrow(z)){
   for(v in c('grade','age_months','status','Reading',S)) {mu<-wm(z[[v]],z$W_FSTUWT);desc[[length(desc)+1]]<-data.table(CNT=cc,sample=ss,variable=v,mean=mu,SD=sqrt(wm((z[[v]]-mu)^2,z$W_FSTUWT)))}
   z[,decile:=pmin(10,pmax(1,ceiling(status)))];bd<-melt(z,id.vars=c('CNT','decile','W_FSTUWT'),measure.vars=S,variable.name='skill',value.name='score')
   bins[[length(bins)+1]]<-bd[,.(mean=wm(score,W_FSTUWT),N=.N),by=.(CNT,decile,skill)][,sample:=ss]
  }
  yy<-c(PV,S)
  for(m in c(models,'Total SES slope','Within-school SES slope')){
   r<-reg(z,m,yy,if(grepl('SES slope',m))'status'else'grade');key<-paste(cc,ss,m,sep='|')
   if(!is.null(r$error)){fails[[key]]<-data.table(CNT=cc,sample=ss,model=m,basis='Common six-skill sample',reason=r$error);next}
   rr<-pool(r,yy);rr[,`:=`(CNT=cc,economy=eco,sample=ss,model=m,basis='Common six-skill sample')];coef[[key]]<-rr;draws[[key]]<-r
  }
  # Outcome-specific availability sensitivity uses the same original country scales.
  for(o in c('Reading',S)){
   ys<-if(o=='Reading')PV else o;v<-q[valid(q) & complete.cases(q[,..ys])]
   for(m in c('SES adjusted','School FE')){
    r<-reg(v,m,ys)
    if(!is.null(r$error)){fails[[paste(cc,ss,m,o,'available')]]<-data.table(CNT=cc,sample=ss,model=m,basis=paste('Outcome available:',o),reason=r$error);next}
    rr<-pool(r,ys);rr[,`:=`(CNT=cc,economy=eco,sample=ss,model=m,basis='Outcome-specific availability')];coef[[paste(cc,ss,m,o,'available')]]<-rr
   }
  }
  saveRDS(z,file.path(OUT,paste0('sample_',cc,'_',match(ss,SUB),'.rds')))
 }
 # Sex contrasts use the same BRR replicate numbers across disjoint pupil groups.
 for(m in models){
  f<-draws[[paste(cc,SUB[3],m,sep='|')]];b<-draws[[paste(cc,SUB[4],m,sep='|')]]
  if(!is.null(f)&&!is.null(b)){r<-f;r$point<-f$point-b$point;r$reps<-f$reps-b$reps;rr<-pool(r,c(PV,S));rr[,`:=`(CNT=cc,model=m,contrast='Urban female minus urban male')];inter[[paste(cc,m)]]<-rr}
 }
 cat(cc,'OLS complete\n');flush.console()
}
E<-rbindlist(coef,fill=TRUE);E[,`:=`(lower=estimate-1.96*se,upper=estimate+1.96*se,p=2*pnorm(-abs(estimate/se)))];E[,q:=p.adjust(p,'BH'),by=.(sample,model,basis,outcome)]
fwrite(E,file.path(OUT,'ols_coefficients.csv'));fwrite(rbindlist(coverage),file.path(OUT,'coverage.csv'));fwrite(rbindlist(desc),file.path(OUT,'descriptives.csv'));fwrite(rbindlist(fails,fill=TRUE),file.path(OUT,'failures.csv'));fwrite(rbindlist(bins),file.path(OUT,'ses_deciles.csv'));fwrite(rbindlist(inter),file.path(OUT,'sex_contrasts.csv'));saveRDS(draws,file.path(OUT,'ols_draws.rds'))

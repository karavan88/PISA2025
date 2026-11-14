# Joint additive multilevel mediation: SES rank/10 or deprivation count at fixed ESCS.
suppressPackageStartupMessages(library(data.table))
invisible(Sys.setlocale('LC_CTYPE','en_US.UTF-8'))
setDTthreads(1)
wm <- function(x,w) sum(x*w)/sum(w)
SKILLS <- c('PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG')
PVS <- paste0('PV',1:10,'READ')
CONTROLS <- c('nonmale','AGE')

prepare_model <- function(z, mode='scaled') {
  SKILLS<-z$skills;CONTROLS<-z$controls
  d <- copy(z$data); d[,school:=droplevels(school)]
  d[,w1:=W_FSTUWT/school_weight]
  if(mode=='scaled') d[,w1:=w1*.N/sum(w1),by=school]
  for(v in c('status',CONTROLS,SKILLS)) {
    d[,(paste0(v,'_B')):=wm(get(v),w1),by=school]
    d[,(paste0(v,'_W')):=get(v)-get(paste0(v,'_B'))]
  }
  base <- compress_model(d,c('status',CONTROLS),PVS)
  full <- compress_model(d,c('status',CONTROLS,SKILLS),PVS)
  med <- compress_model(d,c('status',CONTROLS),SKILLS)
  groups <- split(seq_len(nrow(d)),d$school,drop=TRUE)
  # Conditional descriptive sorting projection; controls and their means held fixed.
  Z <- model.matrix(reformulate(c('status',CONTROLS,paste0(CONTROLS,'_B'))),d)
  sortxx <- sortxy <- mcross <- vector('list',length(groups))
  for(j in seq_along(groups)) {
    ix<-groups[[j]]; w<-d$W_FSTUWT[ix]
    sortxx[[j]]<-as.vector(crossprod(Z[ix,,drop=FALSE],w*Z[ix,,drop=FALSE]))
    sortxy[[j]]<-as.vector(crossprod(Z[ix,,drop=FALSE],w*d$status_B[ix]))
    M<-as.matrix(d[ix,paste0(SKILLS,'_W'),with=FALSE])
    mcross[[j]]<-as.vector(crossprod(M,d$w1[ix]*M))
  }
  list(d=d,base=base,full=full,med=med,sk=SKILLS,controls=CONTROLS,exposure=z$exposure,
       sortxx=do.call(rbind,sortxx),sortxy=do.call(rbind,sortxy),
       sortnames=colnames(Z),mcross=do.call(rbind,mcross))
}

# Worst-direction residual-confounding bias in a fixed weighted linear projection.
# A unit-variance score along Sigma^{-1} a is the residual mediator combination
# that maximises bias in a'b for a given residual-error correlation rho.
bias_scale <- function(a,Sigma,sigma_y) {
  tryCatch(sigma_y*sqrt(max(0,drop(crossprod(a,solve(Sigma,a))))),error=function(e)NA_real_)
}

evaluate_model <- function(s,mult=rep(1,length(s$base$n))) {
  SKILLS<-s$sk
  base<-fit_compressed(s$base,mult); full<-fit_compressed(s$full,mult)
  med<-fit_compressed(s$med,mult)
  pz<-length(s$sortnames)
  ds<-solve(matrix(colSums(s$sortxx*mult),pz),colSums(s$sortxy*mult))
  delta<-unname(ds[match('status',s$sortnames)])
  aW<-vapply(med,function(m)unname(m$coef['status_W']),numeric(1))
  aB<-vapply(med,function(m)unname(m$coef['status_B']),numeric(1))
  ww<-s$med$w2*mult; nw<-sum(ww*s$med$n)
  A<-matrix(colSums(s$med$xx*ww),s$med$p)
  XM<-matrix(colSums(s$med$xy*ww),s$med$p,length(SKILLS))
  MM<-matrix(colSums(s$mcross*ww),length(SKILLS))
  SigmaW<-(MM-crossprod(XM,solve(A,XM)))/nw
  allXy<-matrix(colSums(s$full$xy*(s$full$w2*mult)),s$full$p,s$full$q)
  ans<-sapply(seq_along(PVS),function(i) {
    cf<-full[[i]]$coef; cb<-base[[i]]$coef
    bW<-unname(cf[paste0(SKILLS,'_W')]); bB<-unname(cf[paste0(SKILLS,'_B')])
    iw<-aW*bW; ib<-aB*bB; jointW<-sum(iw); jointB<-sum(ib)
    iw_sort<-(1-delta)*iw; ib_sort<-delta*ib
    jointS<-sum(iw_sort+ib_sort)
    remaining<-unname((1-delta)*cf['status_W']+delta*cf['status_B'])
    total<-remaining+jointS
    # Within residual variance: same orthogonal weighted within projection as fit.
    Xy<-allXy[,i]
    bwfull<-cf[s$full$wn]
    sseW<-sum(s$full$yy[,i]*s$full$w2*mult)-sum(Xy*bwfull)
    KW<-bias_scale(aW,SigmaW,sqrt(max(0,sseW/nw)))
    # Between stress test conditions on this outcome model's fitted GLS weights.
    lambda<-full[[i]]$tau2/full[[i]]$sigma2
    wb<-ww*s$full$n/(1+s$full$n*lambda)
    XB<-s$med$B; MB<-s$med$Y
    br<-solve(crossprod(XB,wb*XB),crossprod(XB,wb*MB))
    rm<-MB-XB%*%br
    SigmaB<-crossprod(rm,wb*rm)/sum(wb)
    ry<-s$full$Y[,i]-drop(s$full$B%*%cf[s$full$bn])
    KB<-bias_scale(aB,SigmaB,sqrt(wm(ry^2,wb)))
    z<-c(delta=delta,joint_W=jointW,joint_B=jointB,
         skills_same_school=jointW,skills_sorting=jointS,
         sorting_increment=jointS-jointW,
         within_allocation=sum(iw_sort),between_allocation=sum(ib_sort),
         remaining=remaining,total=total,share=if(abs(total)>1e-12)100*jointS/total else NA_real_,
         total_fixed=unname(cf['status_W'])+jointW,
         total_sorting_increment=total-(unname(cf['status_W'])+jointW),
         remaining_sorting_increment=delta*unname(cf['status_B']-cf['status_W']),
         skill_level_sorting=delta*sum((aB-aW)*bW),
         skill_context_sorting=delta*sum(aB*(bB-bW)),
         baseline_profile=unname((1-delta)*cb['status_W']+delta*cb['status_B']),
         base_W=unname(cb['status_W']),base_B=unname(cb['status_B']),
         full_W=unname(cf['status_W']),full_B=unname(cf['status_B']),
         bias_scale_W=KW,bias_scale_B=KB,
         setNames(aW,paste0('aW_',SKILLS)),setNames(aB,paste0('aB_',SKILLS)),
         setNames(bW,paste0('bW_',SKILLS)),setNames(bB,paste0('bB_',SKILLS)),
         setNames(iw,paste0('indW_',SKILLS)),setNames(ib,paste0('indB_',SKILLS)),
         setNames(iw_sort+ib_sort,paste0('indS_',SKILLS)))
    z
  })
  colnames(ans)<-PVS
  ans
}

pool_model <- function(point,boot,cc,s) {
  core<-setdiff(rownames(point),c('share','bias_scale_W','bias_scale_B'))
  ok<-apply(boot[core,,,drop=FALSE],3,function(x)all(is.finite(x)))
  stopifnot(sum(ok)>=.95*dim(boot)[3])
  boot<-boot[,,ok,drop=FALSE]
  sv<-rowMeans(apply(boot,c(1,2),function(v)if(sum(is.finite(v))>=.95*length(v))var(v[is.finite(v)])else NA_real_))
  pv<-1.1*apply(point,1,var)
  out<-data.table(CNT=cc,economy=s$d$economy[1],exposure=s$exposure,term=rownames(point),
    estimate=rowMeans(point),sampling_se=sqrt(sv),pv_se=sqrt(pv),se=sqrt(sv+pv),
    N=nrow(s$d),schools=length(s$base$n),skills=length(s$sk),bootstrap_valid=sum(ok))
  out[,`:=`(lower=estimate-1.96*se,upper=estimate+1.96*se)]
  out
}

# Independent prediction-based calculation. Evaluates full design rows; no a*b call.
prediction_check <- function(s,delta) {
  SKILLS<-s$sk
  med<-fit_compressed(s$med); full<-fit_compressed(s$full)
  d<-copy(s$d)
  predict_fixed<-function(fit,data) {
    nm<-setdiff(names(fit$coef),'(Intercept)')
    unname(fit$coef['(Intercept)'])+drop(as.matrix(data[,..nm])%*%fit$coef[nm])
  }
  high<-copy(d);high[,status:=status+1]
  high[,status_B:=status_B+delta];high[,status_W:=status-status_B]
  mlo<-copy(d);mhi<-copy(high)
  for(k in SKILLS) {
    # Use the multilevel mean system: means from B regressors, deviations from W.
    f<-med[[k]];bn<-grep('_B$',names(f$coef),value=TRUE)
    for(which in c('lo','hi')) {
      dd<-if(which=='lo')d else high
      mb<-unname(f$coef['(Intercept)'])+drop(as.matrix(dd[,..bn])%*%f$coef[bn])
      mm<-predict_fixed(f,dd)
      if(which=='lo') {mlo[,(paste0(k,'_B')):=mb];mlo[,(paste0(k,'_W')):=mm-mb]}
      else {mhi[,(paste0(k,'_B')):=mb];mhi[,(paste0(k,'_W')):=mm-mb]}
    }
  }
  held<-copy(mhi)
  for(k in SKILLS)for(lv in c('_W','_B'))held[,(paste0(k,lv)):=mlo[[paste0(k,lv)]]]
  sapply(full,function(f) c(indirect=wm(predict_fixed(f,mhi)-predict_fixed(f,held),d$W_FSTUWT),
    remaining=wm(predict_fixed(f,held)-predict_fixed(f,mlo),d$W_FSTUWT),
    total=wm(predict_fixed(f,mhi)-predict_fixed(f,mlo),d$W_FSTUWT)))
}

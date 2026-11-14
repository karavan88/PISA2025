# Exact profiled Gaussian random-intercept pseudo-likelihood for WeMix weights.
# The within predictors are group-centred using the conditional level-1 weights.
compress_model <- function(d, predictors, outcomes) {
  W <- as.matrix(d[,paste0(predictors,'_W'),with=FALSE])
  B <- cbind('(Intercept)'=1,as.matrix(d[,paste0(predictors,'_B'),with=FALSE]))
  Y <- as.matrix(d[,outcomes,with=FALSE]); groups<-split(seq_len(nrow(d)),d$school,drop=TRUE)
  p<-ncol(W); q<-ncol(Y)
  xx<-xy<-yy<-ym<-bm<-vector('list',length(groups)); n<-w2<-numeric(length(groups)); strata<-character(length(groups))
  for(j in seq_along(groups)) {
    ix<-groups[[j]];w<-d$w1[ix];n[j]<-sum(w);w2[j]<-d$w2[ix[1]];strata[j]<-as.character(d$STRATUM[ix[1]])
    ym[[j]]<-colSums(Y[ix,,drop=FALSE]*w)/n[j]; bm[[j]]<-B[ix[1],]
    yc<-sweep(Y[ix,,drop=FALSE],2,ym[[j]],'-'); x<-W[ix,,drop=FALSE]
    xx[[j]]<-as.vector(crossprod(x,w*x));xy[[j]]<-as.vector(crossprod(x,w*yc));yy[[j]]<-colSums(w*yc^2)
  }
  list(xx=do.call(rbind,xx),xy=do.call(rbind,xy),yy=do.call(rbind,yy),Y=do.call(rbind,ym),B=do.call(rbind,bm),
       n=n,w2=w2,strata=strata,schools=names(groups),p=p,q=q,wn=colnames(W),bn=colnames(B),outcomes=outcomes)
}
fit_compressed <- function(s,mult=rep(1,length(s$n))) {
  ww<-s$w2*mult; A<-matrix(colSums(s$xx*ww),s$p);b<-matrix(colSums(s$xy*ww),s$p,s$q)
  bw<-solve(A,b);ssw<-colSums(s$yy*ww)-colSums(b*bw);nn<-sum(ww*s$n)
  out<-vector('list',s$q)
  for(k in seq_len(s$q)) {
    ym<-s$Y[,k]
    evaluate<-function(lambda,ret=FALSE) {
      wb<-ww*s$n/(1+s$n*lambda)
      bb<-solve(crossprod(s$B,wb*s$B),crossprod(s$B,wb*ym))[,1]
      q<-ssw[k]+sum(wb*(ym-as.vector(s$B%*%bb))^2)
      val<-nn*log(q/nn)+sum(ww*log1p(s$n*lambda))
      if(ret)list(coef=c(setNames(bw[,k],s$wn),setNames(bb,s$bn)),sigma2=q/nn,tau2=lambda*q/nn,objective=val) else val
    }
    opt<-optimize(function(x)evaluate(exp(x)),c(-18,12),tol=1e-8)
    lambda<-if(evaluate(0)<opt$objective)0 else exp(opt$minimum)
    out[[k]]<-evaluate(lambda,TRUE)
  }
  names(out)<-s$outcomes;out
}

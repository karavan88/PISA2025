# Independent matrix 2SLS comparison, including outcome missingness in the middle of the sample.
source('05_papers/02_fuzzy_rd_learning/01_code/model_functions.R')
set.seed(1729);n<-150;r<-rnorm(n);Z<-as.numeric(r<0);x<-rnorm(n);D<-as.numeric(.8*Z+.2*x+rnorm(n)>.4);w<-runif(n,.5,3)
y<-2+1.7*D+.3*r+.2*x+rnorm(n);W<-cbind(1,r=r,x=x)
for(missing in list(integer(),c(3,17,28,62,84,119))){
 yy<-y;yy[missing]<-NA_real_;ok<-is.finite(yy)
 X<-cbind(W,D=D)[ok,,drop=FALSE];Q<-cbind(W,Z=Z)[ok,,drop=FALSE]
 QQ<-crossprod(Q,w[ok]*Q);XQ<-crossprod(X,w[ok]*Q)
 b<-drop(solve(XQ%*%solve(QQ,t(XQ)),XQ%*%solve(QQ,crossprod(Q,w[ok]*yy[ok]))))
 actual<-tsls(yy,D,Z,W,w)
 stopifnot(abs(actual['tau']-b['D'])<1e-10,abs(actual['beta']+12*b['r'])<1e-10,abs(actual['gamma']-b['D']+12*b['r'])<1e-10)
}
cat('PASS: weighted 2SLS agrees with independent matrix solution with and without missing outcomes.\n')

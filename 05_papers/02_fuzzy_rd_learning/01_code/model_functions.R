# Weighted 2SLS; form both stages on the identical outcome-complete sample.
tsls <- function(y, D, Z, W, w) {
  ok <- is.finite(y) & complete.cases(W) & is.finite(D) & is.finite(Z) & is.finite(w) & w>0
  W <- W[ok,,drop=FALSE];y<-y[ok];D<-D[ok];Z<-Z[ok];w<-w[ok]
  X1<-cbind(W,Z=Z);b1<-lm.wfit(X1,D,w)$coefficients
  Dhat<-as.numeric(X1%*%b1)
  b2<-lm.wfit(cbind(W,D=Dhat),y,w)$coefficients
  c(fs=unname(b1['Z']),tau=unname(b2['D']),beta=unname(-12*b2['r']),gamma=unname(b2['D']-12*b2['r']))
}

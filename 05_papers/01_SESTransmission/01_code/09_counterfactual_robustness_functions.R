# Full-design Gaussian random-intercept ML for the existing unweighted lmer sensitivity.
general_compress<-function(d,pr) {
 X<-cbind('(Intercept)'=1,as.matrix(d[,c(paste0(pr,'_W'),paste0(pr,'_B')),with=FALSE]));Y<-as.matrix(d[,..PVS]);gr<-split(seq_len(nrow(d)),d$school,drop=TRUE)
 n<-lengths(gr);p<-ncol(X);q<-ncol(Y);xx<-xy<-yy<-xm<-ym<-vector('list',length(gr))
 for(j in seq_along(gr)) {i<-gr[[j]];xm[[j]]<-colMeans(X[i,,drop=FALSE]);ym[[j]]<-colMeans(Y[i,,drop=FALSE]);xc<-sweep(X[i,,drop=FALSE],2,xm[[j]]);yc<-sweep(Y[i,,drop=FALSE],2,ym[[j]]);xx[[j]]<-as.vector(crossprod(xc));xy[[j]]<-as.vector(crossprod(xc,yc));yy[[j]]<-colSums(yc^2)}
 list(n=n,p=p,q=q,xx=do.call(rbind,xx),xy=do.call(rbind,xy),yy=do.call(rbind,yy),X=do.call(rbind,xm),Y=do.call(rbind,ym),nm=colnames(X))
}
general_fit<-function(s,mult=rep(1,length(s$n))) {
 A<-matrix(colSums(s$xx*mult),s$p);XY<-matrix(colSums(s$xy*mult),s$p,s$q);YY<-colSums(s$yy*mult);nn<-sum(s$n*mult)
 ans<-lapply(seq_len(s$q),function(k) {
  eval<-function(lambda,ret=FALSE){w<-mult*s$n/(1+s$n*lambda);xx<-A+crossprod(s$X,w*s$X);xy<-XY[,k]+drop(crossprod(s$X,w*s$Y[,k]));cf<-solve(xx,xy);ss<-YY[k]+sum(w*s$Y[,k]^2)-sum(cf*xy);v<-nn*log(ss/nn)+sum(mult*log1p(s$n*lambda));if(ret)setNames(cf,s$nm)else v}
  op<-optimize(function(v)eval(exp(v)),c(-18,12),tol=1e-8);lm<-if(eval(0)<op$objective)0 else exp(op$minimum);eval(lm,TRUE)
 });do.call(cbind,ans)
}

# Compress recipient/donor moments using the same normalized weights as school means.
cf_moments<-function(d,ex,skills,group_variable='DEP') {
 schools<-levels(droplevels(d$school));j<-match(as.character(d$school),schools)
 r<-if(ex=='SES')d$SES_rank<=2.5 else d[[group_variable]]>=1
 h<-if(ex=='SES')d$SES_rank>=7.5 else d[[group_variable]]==0
 stopifnot(any(r),any(h),!any(r&h))
 w<-d$W_FSTUWT;M<-as.matrix(d[,..skills]);Y<-as.matrix(d[,..PVS])
 agg<-function(x)unname(rowsum(x,j,reorder=TRUE))
 list(wj=drop(agg(w)),wr=drop(agg(w*r)),wh=drop(agg(w*h)),mr=agg(M*(w*r)),mh=agg(M*(w*h)),
      yr=agg(Y*(w*r)),yh=agg(Y*(w*h)),N=nrow(d),schools=schools,recipient_N=sum(r),reference_N=sum(h),sk=skills)
}
cf_predict<-function(cf,m,mult=rep(1,length(m$wj))) {
 nr<-sum(m$wr*mult);nh<-sum(m$wh*mult);if(nr<=0||nh<=0)stop('Empty recipient/reference bootstrap group')
 muH<-colSums(m$mh*mult)/nh;muR<-colSums(m$mr*mult)/nr
 db<-(outer(m$wr,muH)-m$mr)/m$wj
 dbR<-colSums(db*(m$wr*mult))/nr;dbH<-colSums(db*(m$wh*mult))/nh
 bw<-cf[paste0(m$sk,'_W'),,drop=FALSE];bb<-cf[paste0(m$sk,'_B'),,drop=FALSE]
 r<-colSums(bw*(muH-muR)+(bb-bw)*dbR);h<-colSums((bb-bw)*dbH)
 sk<-bw*(muH-muR-dbR+dbH)+bb*(dbR-dbH);rownames(sk)<-paste0('contribution_',m$sk)
 base<-colSums(m$yh*mult)/nh-colSums(m$yr*mult)/nr
 rbind(baseline_gap=base,recipient_change=r,reference_change=h,gap_reduction=r-h,
       projected_gap=base-r+h,within_component=colSums(bw*(muH-muR-dbR+dbH)),
       between_component=colSums(bb*(dbR-dbH)),gap_fraction=100*(r-h)/base,sk)
}
cf_pool<-function(point,boot,meta) {
 core<-setdiff(rownames(point),'gap_fraction')
 ok<-apply(boot[core,,,drop=FALSE],3,function(x)all(is.finite(x)))
 stopifnot(sum(ok)>=.95*dim(boot)[3]);boot<-boot[,,ok,drop=FALSE]
 sv<-rowMeans(apply(boot,c(1,2),function(x)if(sum(is.finite(x))>=.95*length(x))var(x[is.finite(x)])else NA_real_))
 pv<-1.1*apply(point,1,var)
 a<-data.table(term=rownames(point),estimate=rowMeans(point),sampling_se=sqrt(sv),pv_se=sqrt(pv),se=sqrt(sv+pv))
 a[,`:=`(lower=estimate-1.96*se,upper=estimate+1.96*se,bootstrap_valid=sum(ok))]
 a[,fraction_reportable:=a[term=='baseline_gap',lower]>0 && mean(boot['baseline_gap',,]>0)>=.99]
 cbind(meta,a)
}

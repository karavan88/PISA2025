# Equal-weight summaries of the retained, separately estimated systems.
# Country SEs include bootstrap and PV variance. Independent country samples:
# Var(mean) = sum(Var(country estimate))/K^2, conditional on the fixed country set.
system_mean <- function(z, by='term') {
 z<-copy(z)
 stopifnot(nrow(z)>0,all(is.finite(z$estimate)),all(is.finite(z$se)))
 ans<-z[,.(estimate=mean(estimate),se=sqrt(sum(se^2))/.N,
           systems=.N,country_sd=sd(estimate)),by=by]
 ans[,`:=`(lower=estimate-1.96*se,upper=estimate+1.96*se,
            p_value=2*pnorm(-abs(estimate/se)),CNT='MEAN')]
 ans[,`:=`(p_approx=p_value,economy=paste0('Mean (',systems,' systems)'))]
 ans
}
mean_ci <- function(tt,ex='SES',digits=2,kind='mediation') {
 z<-if(kind=='equalisation') CE[exposure==ex & term==tt] else E[exposure==ex & term==tt]
 m<-system_mean(z)
 paste0(fmt(m$estimate,digits),' [',fmt(m$lower,digits),', ',fmt(m$upper,digits),']')
}
mean_note <- 'Means give each system equal weight; intervals describe uncertainty in the fixed-system average.'

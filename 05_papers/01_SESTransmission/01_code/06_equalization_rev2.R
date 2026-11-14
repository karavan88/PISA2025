# Joint empirical-profile replacement, using saved model and school-bootstrap draws.
# Does not refit models. Group definitions and prepared ranks are fixed in resampling.
source('05_papers/01_SESTransmission/01_code/reporting_rev1.R')
OUT <- file.path(BASE_OUT,'rev2')
WORK <- Sys.getenv('IJED_MEDIATION_WORK','05_papers/01_SESTransmission/04_output/upstream')
dir.create(file.path(OUT,'counterfactual'),showWarnings=FALSE)
SK <- names(sklab); PV <- paste0('PV',1:10,'READ')
wm <- function(x,w) sum(x*w)/sum(w)
run_cf <- function(cc,ex) {
 id<-paste0(ex,'_',cc)
 z<-readRDS(file.path('03_outputs/01_harmonized/input',paste0(id,'.rds')))
 d<-z$data; dr<-readRDS(file.path(WORK,'draws',paste0(id,'.rds')))
 co<-readRDS(file.path(WORK,'compressed',paste0(id,'.rds')))$s
 stopifnot(identical(z$skills,SK),dim(dr$bootstrap)[3]==499)
 schools<-co$base$schools; j<-match(as.character(d$school),schools); J<-length(schools)
 stopifnot(!anyNA(j),setequal(unique(j),seq_len(J)))
 rr<-if(ex=='SES') d$SES_rank<=2.5 else d$DEP>=1
 hh<-if(ex=='SES') d$SES_rank>=7.5 else d$DEP==0
 stopifnot(any(rr),any(hh),!any(rr&hh))
 w<-d$W_FSTUWT; M<-as.matrix(d[,..SK]); Y<-as.matrix(d[,..PV])
 agg<-function(x) {a<-rowsum(x,j,reorder=TRUE);stopifnot(identical(as.integer(rownames(a)),seq_len(J)));unname(a)}
 wj<-drop(agg(w)); wr<-drop(agg(w*rr)); wh<-drop(agg(w*hh))
 mr<-agg(M*(w*rr)); mh<-agg(M*(w*hh)); yr<-agg(Y*(w*rr)); yh<-agg(Y*(w*hh))
 calc<-function(cf,mult) {
  nr<-sum(wr*mult); nh<-sum(wh*mult)
  muH<-colSums(mh*mult)/nh; muR<-colSums(mr*mult)/nr
  # Expected school-mean change after replacing recipients' full profiles.
  db<-(outer(wr,muH)-mr)/wj
  dbR<-colSums(db*(wr*mult))/nr; dbH<-colSums(db*(wh*mult))/nh
  bW<-cf[paste0('bW_',SK),,drop=FALSE]; bB<-cf[paste0('bB_',SK),,drop=FALSE]
  gR<-colSums(bW*(muH-muR)+(bB-bW)*dbR)
  gH<-colSums((bB-bW)*dbH)
  byskill<-bW*(muH-muR-dbR+dbH)+bB*(dbR-dbH)
  within<-colSums(bW*(muH-muR-dbR+dbH)); between<-colSums(bB*(dbR-dbH))
  base<-colSums(yh*mult)/nh-colSums(yr*mult)/nr
  reduction<-gR-gH
  ans<-rbind(baseline_gap=base,recipient_change=gR,reference_change=gH,
             gap_reduction=reduction,projected_gap=base-reduction,
             within_component=within,between_component=between,
             gap_fraction=100*reduction/base)
  rownames(byskill)<-paste0('contribution_',SK)
  rbind(ans,byskill)
 }
 point<-calc(dr$point,rep(1,J)); boot<-array(NA_real_,c(nrow(point),10,499),dimnames=list(rownames(point),PV,NULL))
 set.seed(dr$seed); delta_error<-numeric(499)
 for(b in 1:499) {
  mult<-tabulate(sample.int(J,J,replace=TRUE),nbins=J)
  boot[,,b]<-calc(dr$bootstrap[,,b],mult)
  # Verify exact pairing of resampled group moments and saved model draws.
  pz<-length(co$sortnames)
  delta<-solve(matrix(colSums(co$sortxx*mult),pz),colSums(co$sortxy*mult))[match('status',co$sortnames)]
  delta_error[b]<-abs(delta-dr$bootstrap['delta',1,b])
 }
 stopifnot(max(delta_error)<1e-10,all(is.finite(boot)))
 vs<-rowMeans(apply(boot,c(1,2),var)); vp<-1.1*apply(point,1,var)
 out<-data.table(CNT=cc,economy=d$economy[1],exposure=ex,term=rownames(point),
                  estimate=rowMeans(point),sampling_se=sqrt(vs),pv_se=sqrt(vp),se=sqrt(vs+vp))
 out[,`:=`(lower=estimate-1.96*se,upper=estimate+1.96*se)]
 baseok<-out[term=='baseline_gap',lower]>0 && mean(boot['baseline_gap',,]>0)>=.99
 out[,fraction_reportable:=baseok]
 diag<-data.table(CNT=cc,exposure=ex,recipient_N=sum(rr),reference_N=sum(hh),
   recipient_weight_share=sum(w*rr)/sum(w),reference_weight_share=sum(w*hh)/sum(w),
   recipient_share_in_school_with_reference=sum(wr[wh>0])/sum(wr),
   max_bootstrap_pairing_error=max(delta_error),bootstrap_valid=499,
   school_mean_identity_error=max(abs(colSums(outer(wr,colSums(mh)/sum(wh))-mr)-
     (sum(wr)*colSums(mh)/sum(wh)-colSums(mr)))))
 # Verify the reduced calculation against explicit pupil-level predictions at point estimates.
 mu<-colSums(mh)/sum(wh); shift<-rr*(matrix(mu,nrow(d),6,byrow=TRUE)-M)
 db<-agg(shift*w)/wj
 BW<-dr$point[paste0('bW_',SK),]; BB<-dr$point[paste0('bB_',SK),]
 direct<-(shift-db[j,,drop=FALSE])%*%BW+db[j,,drop=FALSE]%*%BB
 chkR<-colSums(direct*(w*rr))/sum(w*rr); chkH<-colSums(direct*(w*hh))/sum(w*hh)
 stopifnot(max(abs(chkR-point['recipient_change',]))<1e-9,
           max(abs(chkH-point['reference_change',]))<1e-9,
           max(abs(point['within_component',]+point['between_component',]-point['gap_reduction',]))<1e-9)
 diag[,direct_prediction_error:=max(abs(chkR-chkH-point['gap_reduction',]))]
 skills<-data.table(CNT=cc,exposure=ex,skill=SK,recipient_mean=colSums(mr)/sum(wr),reference_mean=mu)
 saveRDS(list(point=point,bootstrap=boot,seed=dr$seed),file.path(OUT,'counterfactual',paste0(id,'.rds')))
 list(estimates=out,diagnostics=diag,skills=skills)
}
jobs<-A[status=='Eligible'&skills==6,.(CNT,exposure)]
res<-lapply(seq_len(nrow(jobs)),function(i){
 cat(i,'/',nrow(jobs),jobs$exposure[i],jobs$CNT[i],'\n');flush.console()
 run_cf(jobs$CNT[i],jobs$exposure[i])
})
CE<-rbindlist(lapply(res,`[[`,'estimates'))
CE[,p_value:=2*pnorm(-abs(estimate/se))]
CE[term=='gap_reduction',q_gap:=p.adjust(p_value,'BH'),by=exposure]
fwrite(CE,file.path(OUT,'tables/equalization_estimates.csv'))
fwrite(rbindlist(lapply(res,`[[`,'diagnostics')),file.path(OUT,'tables/equalization_diagnostics.csv'))
fwrite(rbindlist(lapply(res,`[[`,'skills')),file.path(OUT,'tables/equalization_skill_means.csv'))
print(CE[term=='gap_reduction',.(systems=.N,positive=sum(lower>0),negative=sum(upper<0),BH_positive=sum(lower>0&q_gap<.05)),by=exposure])

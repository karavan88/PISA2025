# Reporting transformation of existing paired draws; no regression estimation.
source('05_papers/01_SESTransmission/01_code/reporting_rev2.R')
WORK <- Sys.getenv('IJED_MEDIATION_WORK',
  '05_papers/01_SESTransmission/04_output/upstream')
ids <- A[exposure=='SES'][order(economy), CNT]
derive_wb <- function(x) {
  d <- x['delta',]; iw <- x['joint_W',]; ib <- x['joint_B',]
  rw <- (1-d)*x['full_W',]; rb <- d*x['full_B',]
  sw <- (1-d)*iw; sb <- d*ib
  tw <- rw+sw; tb <- rb+sb
  rbind(total_within=tw, total_between=tb, skills_within=sw, skills_between=sb,
        remaining_within=rw, remaining_between=rb,
        total_gradient=tw+tb, skills_total=sw+sb,
        total_between_minus_within=tb-tw, skills_between_minus_within=sb-sw,
        between_share_total=100*tb/(tw+tb), between_share_skills=100*sb/(sw+sb))
}
checks <- list(); provenance <- list()
results <- lapply(ids, function(cc) {
  path <- file.path(WORK, 'draws', paste0('SES_',cc,'.rds'))
  dr <- readRDS(path)
  stopifnot(identical(dim(dr$bootstrap)[2:3], c(10L,499L)),
            all(is.finite(dr$point)), all(is.finite(dr$bootstrap)))
  pt <- derive_wb(dr$point)
  bt <- simplify2array(lapply(seq_len(499), function(b) derive_wb(dr$bootstrap[,,b])))
  stopifnot(all(is.finite(pt)), all(is.finite(bt)))
  # Preserve covariance: form each sum, difference and ratio before pooling.
  se <- sqrt(rowMeans(apply(bt,c(1,2),var)) + 1.1*apply(pt,1,var))
  out <- data.table(CNT=cc,economy=A[CNT==cc & exposure=='SES',economy],
    term=rownames(pt),estimate=rowMeans(pt),se=se,bootstrap_valid=499L)
  out[,`:=`(lower=estimate-1.96*se, upper=estimate+1.96*se,
            p_value=2*pnorm(-abs(estimate/se)), ratio_reportable=NA)]
  for(kind in c('total','skills')) {
    denominator <- if(kind=='total') 'total_gradient' else 'skills_total'
    tt <- paste0('between_share_',kind)
    allowed <- out[term==denominator,lower]>0 && all(pt[denominator,]>0) &&
      mean(bt[denominator,,]>0)>=.99 &&
      all(out[term %in% paste0(kind,c('_within','_between')),estimate]>=0) &&
      out[term==tt,lower]>=0 && out[term==tt,upper]<=100
    out[term==tt,ratio_reportable:=allowed]
  }
  identity_error <- function(original, derived) {
    max(abs(dr$point[original,]-pt[derived,]),
        abs(dr$bootstrap[original,,]-bt[derived,,]))
  }
  checks[[cc]] <<- data.table(CNT=cc,
    total_error=identity_error('total','total_gradient'),
    skills_error=identity_error('skills_sorting','skills_total'),
    within_error=identity_error('within_allocation','skills_within'),
    between_error=identity_error('between_allocation','skills_between'),
    sorting_error=max(abs(dr$point['sorting_increment',] -
      (pt['skills_between',]-dr$point['delta',]*dr$point['joint_W',])),
      abs(dr$bootstrap['sorting_increment',,] -
      (bt['skills_between',,]-dr$bootstrap['delta',,]*dr$bootstrap['joint_W',,]))))
  provenance[[cc]] <<- data.table(CNT=cc,path=path,md5=unname(tools::md5sum(path)),
                                 plausible_values=10L,bootstrap_draws=499L)
  out
})
WB <- rbindlist(results)
contrasts <- c('total_between_minus_within','skills_between_minus_within')
WB[,q_contrast:=NA_real_]
WB[term %in% contrasts,q_contrast:=p.adjust(p_value,'BH')]
audit <- rbindlist(checks)
stopifnot(nrow(WB)==67L*12L,!anyDuplicated(WB[,.(CNT,term)]),
          max(as.matrix(audit[,-1]))<1e-9)
# Independently reconcile pooled results with the publication's saved estimates.
for(pair in list(c('total_gradient','total'),c('skills_total','skills_sorting'),
                c('skills_within','within_allocation'),c('skills_between','between_allocation'))) {
  x <- merge(WB[term==pair[1]],E[exposure=='SES' & term==pair[2]],by='CNT')
  stopifnot(nrow(x)==67L,max(abs(x$estimate.x-x$estimate.y))<1e-9,
            max(abs(x$lower.x-x$lower.y))<1e-8,max(abs(x$upper.x-x$upper.y))<1e-8)
}
fwrite(WB,file.path(OUT,'tables/within_between_decomposition.csv'))
fwrite(audit,file.path(OUT,'audit/within_between_checks.csv'))
fwrite(rbindlist(provenance),file.path(OUT,'audit/within_between_draw_sources.csv'))
print(WB[term %in% contrasts,.(positive=sum(lower>0),negative=sum(upper<0),
  positive_BH=sum(lower>0&q_contrast<.05),negative_BH=sum(upper<0&q_contrast<.05)),by=term])
print(WB[CNT=='KOR',.(term,estimate,lower,upper,ratio_reportable)])
message('Within/between decomposition verified for 67 systems, 10 PVs and 499 paired draws. No models refitted.')

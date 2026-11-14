source('05_papers/01_SESTransmission/01_code/reporting.R')
input_root <- Sys.getenv('IJED_ANALYTIC_INPUT', '03_outputs/01_harmonized/input')
jobs <- A[status=='Eligible']
ans <- lapply(seq_len(nrow(jobs)), function(j) {
  cc <- jobs$CNT[j]; ex <- jobs$exposure[j]
  f <- file.path(input_root,paste0(ex,'_',cc,'.rds'))
  if(!file.exists(f)) stop('Saved analytic input required for descriptives: ',f)
  obj <- readRDS(f); d <- obj$data; w <- d$W_FSTUWT
  d[, Reading := rowMeans(.SD), .SDcols=paste0('PV',1:10,'READ')]
  if('AGE' %in% names(d)) d[, Age_years := AGE+15]
  vars <- intersect(c('Reading','SES_rank','DEP','ESCS','Age_years','nonmale',obj$skills),names(d))
  rbindlist(lapply(vars,function(v) {
    x <- d[[v]]; ok <- is.finite(x)&is.finite(w)&w>0
    if(!any(ok)) return(NULL)
    mu <- weighted.mean(x[ok],w[ok])
    data.table(CNT=cc,exposure=ex,variable=v,N=sum(ok),
      mean=mu,SD=sqrt(weighted.mean((x[ok]-mu)^2,w[ok])),min=min(x[ok]),max=max(x[ok]))
  }))
})
fwrite(rbindlist(ans),file.path(OUT,'tables/descriptives.csv'))
message('Descriptives from saved inputs only; no regression refitted.')

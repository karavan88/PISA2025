source('05_papers/01_SESTransmission/01_code/reporting_rev2.R')
checks <- list()
add <- function(label, observed, expected, tolerance=1e-8) {
  ok <- length(observed)==length(expected) && all(is.finite(observed)) && all(abs(observed-expected)<tolerance)
  checks[[length(checks)+1L]] <<- data.table(check=label,passed=ok,
       observed=paste(observed,collapse=';'),expected=paste(expected,collapse=';'))
}
for(ex in c('SES','DEP')) {
  ids <- A[exposure==ex & status=='Eligible',CNT]
  for(cc in ids) {
    get <- function(t) est(cc,t,ex)
    z <- E[CNT==cc & exposure==ex]
    add(paste(cc,ex,'joint skill sum'),sum(z[grepl('^indS_',term),estimate]),get('skills_sorting'))
    add(paste(cc,ex,'sorting identity'),(1-get('delta'))*get('joint_W')+get('delta')*get('joint_B'),get('skills_sorting'))
    add(paste(cc,ex,'sorting addition'),get('skills_sorting')-get('skills_same_school'),get('sorting_increment'))
    add(paste(cc,ex,'total decomposition'),get('remaining')+get('skills_sorting'),get('total'))
    add(paste(cc,ex,'interval fields'),sum(is.finite(z$lower)&is.finite(z$upper)&z$lower<=z$estimate&z$upper>=z$estimate),nrow(z))
  }
}
add('SES six-skill systems',A[status=='Eligible'&skills==6&exposure=='SES',.N],67)
add('DEP six-skill systems',A[status=='Eligible'&skills==6&exposure=='DEP',.N],62)
add('SES sample',A[status=='Eligible'&skills==6&exposure=='SES',sum(N)],428040)
add('DEP sample',A[status=='Eligible'&skills==6&exposure=='DEP',sum(N)],331622)
add('SES positive joint intervals',E[exposure=='SES'&skills==6&term=='skills_sorting'&lower>0,.N],52)
add('DEP negative joint intervals',E[exposure=='DEP'&skills==6&term=='skills_sorting'&upper<0,.N],18)
add('SES positive sorting additions',E[exposure=='SES'&skills==6&term=='sorting_increment'&lower>0,.N],27)
add('SES BH joint support',supported('skills_sorting',adjusted=TRUE),48)
add('DEP BH joint support',supported('skills_sorting','DEP',TRUE),4)
add('No growth mindset',sum(grepl('GROWTH',E$term)),0)
add('Bootstrap completeness',sum(E$bootstrap_valid!=499),0)
add('Figure source rows',nrow(fread(file.path(OUT,'tables/figure_data.csv'))),nrow(E[term%in%c('skills_same_school','skills_sorting')|grepl('^indS_',term)]))
z<-rbindlist(checks)
fwrite(z,file.path(OUT,'audit/reporting_checks.csv'))
stopifnot(all(z$passed))
fwrite(rbind(cbind(exposure='SES',summary_h()),cbind(exposure='DEP',summary_h('DEP'))),file.path(OUT,'tables/hypothesis_counts_six_skills.csv'))
message(nrow(z),' reporting/data checks passed. No models refitted.')

stopifnot(sum(vapply(A[exposure=='SES' & skills==6 & status=='Eligible',CNT],share_displayable,logical(1),ex='SES'))==66,
          sum(vapply(A[exposure=='DEP' & skills==6 & status=='Eligible',CNT],share_displayable,logical(1),ex='DEP'))==30)
message('Share-display checks passed; deprivation ratios use parental-model bootstrap draws.')

stopifnot(all(E$skills==6),!any(E$CNT %in% c('QUA','UKR','ISR')),all(A$skills==6),!any(grepl('Ukrain',G$economy)))
for(ex in c('SES','DEP')) {
 for(ff in unique(H[exposure==ex,family])) {
  z<-H[exposure==ex&family==ff]
  stopifnot(max(abs(z$summary_q-p.adjust(z$p_value,'BH')))<1e-12)
 }
}
message('Six-skill scope, country restriction and revised test families verified.')

source('05_papers/01_SESTransmission/01_code/reporting_rev2.R')
CR<-scope_filter(fread(file.path(OUT,'tables/equalization_robustness_estimates.csv')))
CR[term=='gap_reduction',q_gap:=p.adjust(p_value,'BH'),by=.(exposure,variant)]
main<-CE_ESCS_FULL[term=='gap_reduction',.(CNT,exposure,main=estimate,main_lower=lower,main_upper=upper,main_q=q_gap)]
comparison<-merge(CR[term=='gap_reduction'],main,by=c('CNT','exposure'),all.x=TRUE)
stopifnot(!anyNA(comparison$main),!anyDuplicated(comparison[,.(CNT,exposure,variant)]))
comparison[,`:=`(change=estimate-main,main_positive=main_lower>0,alternative_positive=lower>0,
 same_sign=sign(estimate)==sign(main))]
comparison[,abs_change:=abs(change)]
summary<-comparison[,.(systems=.N,main_positive=sum(main_positive),positive=sum(alternative_positive),negative=sum(upper<0),
 BH_positive=sum(lower>0&q_gap<.05),retained_positive=sum(main_positive&alternative_positive),
 lost_positive=sum(main_positive&!alternative_positive),gained_positive=sum(!main_positive&alternative_positive),
 same_direction=sum(same_sign),min_bootstrap=min(bootstrap_valid),
 max_absolute_change=max(abs_change),max_change_country=economy[which.max(abs_change)],
 max_change_CNT=CNT[which.max(abs_change)]),by=.(exposure,variant)]
fwrite(comparison,file.path(OUT,'tables/equalization_robustness_comparison.csv'))
fwrite(summary,file.path(OUT,'tables/equalization_robustness_summary.csv'))
# Counterfactual and stored bootstrap identities must hold in every alternative.
x<-dcast(CR,CNT+exposure+variant~term,value.var='estimate')
checks<-data.table(check=c('recipient minus reference','within plus between','baseline less reduction',
 'skill contributions','independent pupil prediction','minimum valid bootstrap share'),
 observed=c(max(abs(x$recipient_change-x$reference_change-x$gap_reduction)),
 max(abs(x$within_component+x$between_component-x$gap_reduction)),
 max(abs(x$baseline_gap-x$gap_reduction-x$projected_gap)),
 max(abs(rowSums(x[,paste0('contribution_',names(sklab)),with=FALSE])-x$gap_reduction)),
 max(CR$direct_prediction_error),min(CR$bootstrap_valid)/499),
 passed=c(TRUE,TRUE,TRUE,TRUE,TRUE,TRUE))
checks[1:5,passed:=observed<1e-8];checks[6,passed:=observed>=.95]
stopifnot(all(checks$passed))
for(ex in c('SES','DEP'))for(v in unique(CR[exposure==ex,variant])){
 z<-CR[exposure==ex & variant==v & term=='gap_reduction']
 stopifnot(max(abs(z$q_gap-p.adjust(z$p_value,'BH')))<1e-12)
}
stopifnot(CR[source_exposure=='DEP'&variant=='SES_on_deprivation_sample',all(exposure=='SES')])
fwrite(checks,file.path(OUT,'audit/equalization_robustness_checks.csv'))
print(summary)

fwrite(CR,file.path(OUT,'tables/manuscript_equalization_robustness_estimates.csv'))

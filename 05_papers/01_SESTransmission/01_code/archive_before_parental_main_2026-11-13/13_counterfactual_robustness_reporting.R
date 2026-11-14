# Loaded by the manuscripts after reporting_rev2.R.
CR<-scope_filter(fread(file.path(OUT,'tables/equalization_robustness_estimates.csv')))
CR[term=='gap_reduction',q_gap:=p.adjust(p_value,'BH'),by=.(exposure,variant)]
CS<-fread(file.path(OUT,'tables/equalization_robustness_summary.csv'))
CP<-fread(file.path(OUT,'tables/equalization_robustness_comparison.csv'))
cf_variant_names<-c(unscaled_weights='Unscaled weights',minimum_10='Minimum 10 pupils',
 lmer_unweighted='Unweighted mixed model',core_four_fixed_groups='Four items: original groups',
 core_four_redefined_groups='Four items: new groups',SES_on_deprivation_sample='Deprivation-complete sample')
crci<-function(cc,v,ex='SES',term='gap_reduction',digits=2) {
 wanted_term<-term
 z<-CR[CNT==cc & variant==v & exposure==ex & term==wanted_term]
 stopifnot(nrow(z)==1)
 paste0(fmt(z$estimate,digits),' [',fmt(z$lower,digits),', ',fmt(z$upper,digits),']')
}
crstat<-function(v,ex,field) {
 z<-CS[variant==v&exposure==ex];stopifnot(nrow(z)==1);z[[field]]
}
crtable<-function() {
 z<-copy(CS);z[,Exposure:=ifelse(exposure=='SES','SES','Deprivation')]
 z[,Specification:=unname(cf_variant_names[variant])]
 z[,.(Exposure,Specification,Systems=systems,`Positive CI`=positive,`BH positive`=BH_positive,
       `Retained main support`=paste0(retained_positive,' / ',main_positive))]
}

crretained <- function(ex) CP[exposure==ex & variant %in% c('unscaled_weights','minimum_10','lmer_unweighted'),
 .(retained=all(main_positive & alternative_positive)),by=CNT][,sum(retained)]

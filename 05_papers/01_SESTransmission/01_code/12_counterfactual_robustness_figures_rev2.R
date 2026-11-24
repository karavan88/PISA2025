# Run after the shared figures routine: reuse its theme and export helper.
CR<-scope_filter(fread(file.path(OUT,'tables/equalization_robustness_estimates.csv')))
CR[term=='gap_reduction',q_gap:=p.adjust(p_value,'BH'),by=.(exposure,variant)]
CS<-fread(file.path(OUT,'tables/equalization_robustness_summary.csv'))
CP<-fread(file.path(OUT,'tables/equalization_robustness_comparison.csv'))
variant_names<-c(unscaled_weights='Unscaled weights',minimum_10='Minimum 10 pupils',
 lmer_unweighted='Unweighted model',core_four_fixed_groups='4 items; original groups',
 core_four_redefined_groups='4 items; redefined groups',SES_on_deprivation_sample='Deprivation-complete sample')
cf_robust_panel<-function(ex,v) {
 z<-copy(CP[exposure==ex & variant==v]);z[,Status:=ifelse(main_positive&alternative_positive,'Positive interval in both',
  ifelse(main_positive!=alternative_positive,'Interval status changes','Neither interval positive'))]
 lab<-z[order(-abs_change)][seq_len(min(3,.N))]
 zz<-if(v%in%c('unscaled_weights','minimum_10','lmer_unweighted'))CP[exposure==ex & variant%in%c('unscaled_weights','minimum_10','lmer_unweighted')] else z
 lim<-range(c(0,zz$main,zz$estimate));lim<-lim+c(-1,1)*max(1,diff(lim)*.08)
 ggplot(z,aes(main,estimate,colour=Status))+
  geom_abline(slope=1,intercept=0,colour='#7A8B91',linewidth=.5)+
  geom_hline(yintercept=0,colour='#D3DADD',linewidth=.25)+geom_vline(xintercept=0,colour='#D3DADD',linewidth=.25)+
  geom_point(size=1.8,alpha=.85)+
  ggrepel::geom_text_repel(data=lab,aes(label=economy),size=2.8,max.overlaps=Inf,seed=1108,show.legend=FALSE)+
  scale_colour_manual(values=c('Positive interval in both'='#17677E','Interval status changes'='#BB5839','Neither interval positive'='#8C969B'),drop=FALSE)+
  geom_point(data=data.table(main=mean(z$main),estimate=mean(z$estimate)),aes(main,estimate),inherit.aes=FALSE,shape=23,fill='black',colour='white',size=3)+
  coord_equal(xlim=lim,ylim=lim)+labs(title=paste0(ex,': ',variant_names[v]),
    subtitle=paste0(nrow(z),' systems; diamond = mean'),x='Main gap reduction (points)',y='Alternative gap reduction (points)')+
  theme(plot.title=element_text(size=10),plot.subtitle=element_text(size=8),legend.text=element_text(size=8),
        axis.title=element_text(size=8),axis.text=element_text(size=7),plot.margin=margin(9,9,9,9))
}
shared<-c('unscaled_weights','minimum_10','lmer_unweighted')
p<-patchwork::wrap_plots(lapply(shared,function(v)lapply(c('SES','DEP'),function(ex)cf_robust_panel(ex,v))) |> unlist(recursive=FALSE),ncol=2,guides='collect',axis_titles='collect')
p<-p+plot_annotation(title='Does skill-profile equalization still narrow the reading gap?',
 caption='Diagonal: identical point estimates. Colours compare separate 95% intervals, not a test of the difference.\nAll eligible systems retained; labels identify the 3 largest point changes in each panel.') & theme(legend.position='bottom')
save_fig(p,'equalization_robustness_shared',7,9.3)
p2<-(cf_robust_panel('DEP','core_four_fixed_groups')|cf_robust_panel('DEP','core_four_redefined_groups')|cf_robust_panel('SES','SES_on_deprivation_sample'))+
 plot_layout(guides='collect',axis_titles='collect')+plot_annotation(title='Exposure definitions and sample composition',
 caption='Original versus redefined deprivation groups separates model-control and target-population changes.\nThe SES complete-sample comparison remains an SES analysis.') & theme(legend.position='bottom')
save_fig(p2,'equalization_robustness_definitions',10,4.5)
# Current publication: SES checks and matched parental-controls comparison.
p3<-patchwork::wrap_plots(lapply(shared,function(v)cf_robust_panel('SES',v)),ncol=1,guides='collect',axis_titles='collect')+
 plot_annotation(title='Rank-gap equalization under alternative specifications') & theme(legend.position='bottom')
save_fig(p3,'ses_equalization_robustness',7,10)
panel_parent<-function(tt){
 z<-copy(PCOMP[term==tt]);z[,Status:=ifelse(escs_support&parental_support,'Supported in both',ifelse(escs_support!=parental_support,'Interval status changes','Neither supported'))]
 lab<-z[order(-abs(change))][1:3]
 lim<-range(c(z$escs,z$parental,0));lim<-lim+c(-1,1)*diff(lim)*.15
 ggplot(z,aes(escs,parental,colour=Status))+geom_abline(slope=1,intercept=0,colour='grey60')+
 geom_point(size=2)+ggrepel::geom_text_repel(data=lab,aes(label=economy),seed=1108,size=3,max.overlaps=Inf,show.legend=FALSE)+
 scale_colour_manual(values=c('Supported in both'='#17677E','Interval status changes'='#BB5839','Neither supported'='#8C969B'))+
 geom_point(data=data.table(escs=mean(z$escs),parental=mean(z$parental)),aes(escs,parental),inherit.aes=FALSE,shape=23,fill='black',colour='white',size=3)+
 coord_equal(xlim=lim,ylim=lim)+labs(title=if(tt=='skills_sorting')'Joint mediation' else 'Skill-profile equalization',x='ESCS controls: reading points',y='Parental controls: reading points')+theme(legend.position='bottom',axis.title=element_text(size=9))
}
p4<-(panel_parent('skills_sorting')|panel_parent('gap_reduction'))+plot_layout(guides='collect',axis_titles='collect')+
 plot_annotation(title='Material deprivation: changing controls on the same pupils',caption='62 systems; 331,622 pupils. The diagonal marks identical point estimates; black diamonds are equal-weight means.') & theme(legend.position='bottom')
save_fig(p4,'parental_controls_comparison',8,5)

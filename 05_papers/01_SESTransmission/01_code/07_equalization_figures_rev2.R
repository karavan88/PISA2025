# Invoked after 02_figures_rev2.R: shared font, colours and output devices.
cf_forest <- function(ex) {
 z<-copy(CE[exposure==ex & term=='gap_reduction'][order(economy)])
 n<-nrow(z); n1<-ceiling(n/2); z[,panel:=ifelse(seq_len(.N)<=n1,'A','B')]
 z[,yy:=n1-seq_len(.N)+1,by=panel]
 z[,Evidence:=factor(ifelse(p_value<.05,'p < 0.05',ifelse(p_value<.1,'p < 0.10','Not significant')),levels=c('p < 0.05','p < 0.10','Not significant'))]
 lim<-range(c(0,z$lower,z$upper));lim<-c(floor(lim[1]),ceiling(lim[2]))
 mm<-system_mean(z);mm[,yy:=0];mm[,Evidence:=factor(ifelse(p_value<.05,'p < 0.05',ifelse(p_value<.1,'p < 0.10','Not significant')),levels=levels(z$Evidence))]
 ps<-lapply(c('A','B'),function(pn) {
  zz<-rbindlist(list(z[panel==pn],if(pn=='B') mm else NULL),fill=TRUE)
  ggplot(zz,aes(estimate,yy,shape=Evidence))+
   geom_hline(yintercept=seq_len(n1),colour='#EDF0F1',linewidth=.25)+
   geom_vline(xintercept=0,colour='#71838A',linewidth=.4)+
   geom_segment(aes(x=lower,xend=upper,yend=yy),linewidth=.6,show.legend=FALSE)+geom_point(size=1.8,colour='#17677E')+
   scale_shape_manual(values=c(16,17,1),drop=FALSE)+
   guides(shape=guide_legend(nrow=1,override.aes=list(size=2.5)))+
   scale_y_continuous(breaks=zz$yy,labels=zz$economy,limits=c(-.6,n1+.6),expand=c(0,0))+
   scale_x_continuous(limits=lim,breaks=scales::breaks_pretty(5))+
   labs(x='Predicted gap reduction (reading points)',y=NULL)+
   theme(axis.text.y=element_text(size=8),panel.grid.major.x=element_line(colour='#E4E9EB'))
 })
 p<-(ps[[1]]|ps[[2]])+plot_layout(guides='collect',axis_titles='collect') & theme(legend.position='top')
 p<-p+plot_annotation(title='Equalizing joint skill profiles: the change in the reading gap',
   subtitle=if(ex=='SES')'Lower national SES quartile receives the upper-quartile skill distribution' else 'Pupils reporting deprivation receive the non-deprived skill distribution',
   caption=paste0(mean_note,'\nSymbols: strongest threshold met; not significant at 10%.\nSchool membership and exposures fixed; school skill means updated. Whole-school bootstrap / PV 95% intervals.\nPositive values indicate a narrower gap. This is an endowment-replacement benchmark.'),
   theme=theme(plot.caption=element_text(size=8,hjust=0,colour='#475961')))
 save_fig(p,paste0(tolower(ex),'_equalization'),8.6,10.7)
}
cf_forest('SES'); cf_forest('DEP')
fwrite(CE,file.path(OUT,'tables/equalization_figure_data.csv'))

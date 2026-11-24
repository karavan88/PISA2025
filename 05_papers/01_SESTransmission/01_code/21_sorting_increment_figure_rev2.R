# Reporting only: direct bootstrap/PV intervals for the sorting addition.
source('05_papers/01_SESTransmission/01_code/reporting_rev2.R')
library(ggplot2)
library(patchwork)
z<-copy(E[exposure=='SES' & term=='sorting_increment'][order(-estimate,economy)])
stopifnot(nrow(z)==67,all(z$bootstrap_valid==499),sum(z$lower>0)==27,
          sum(z$lower>0 & z$q_primary<.05)==23)
expected<-E[exposure=='SES' & term=='skills_sorting',.(CNT,total=estimate)][
 E[exposure=='SES' & term=='skills_same_school',.(CNT,within=estimate)],on='CNT']
stopifnot(max(abs(z$estimate-(expected$total-expected$within)[match(z$CNT,expected$CNT)]))<1e-10)
z[,`:=`(position=seq_len(.N),Evidence=factor(ifelse(p_approx<.05,'p < 0.05',ifelse(p_approx<.1,'p < 0.10','Not significant')),levels=c('p < 0.05','p < 0.10','Not significant')),
 Adjustment=factor(ifelse(q_primary<.05,'BH q < 0.05','BH q >= 0.05'),levels=c('BH q < 0.05','BH q >= 0.05')))]
z[,panel:=ifelse(position<=34,1L,2L)]
z[,y:=35-seq_len(.N),by=panel]
lim<-c(-1.5,4.5)
mn<-system_mean(z);mn[,`:=`(y=0,Evidence=factor(ifelse(p_value<.05,'p < 0.05',ifelse(p_value<.1,'p < 0.10','Not significant')),levels=levels(z$Evidence)),Adjustment=factor('Mean: unadjusted',levels=c(levels(z$Adjustment),'Mean: unadjusted')))]
z[,Adjustment:=factor(Adjustment,levels=levels(mn$Adjustment))]
pp<-lapply(1:2,function(k){
 d<-rbindlist(list(z[panel==k],if(k==1L) mn else NULL),fill=TRUE)
 ggplot(d,aes(estimate,y,colour=Adjustment,shape=Evidence))+
 geom_hline(yintercept=1:34,colour='#EDF0F1',linewidth=.25)+
 geom_vline(xintercept=0,colour='#596D77',linewidth=.5)+
 geom_segment(aes(x=lower,xend=upper,yend=y),linewidth=.55)+geom_point(size=1.9)+
 scale_colour_manual(values=c('#17677E','#9CA6AB','#202B30'),drop=FALSE)+scale_shape_manual(values=c(16,17,1),drop=FALSE)+
 scale_y_continuous(breaks=d$y,labels=d$economy,limits=c(-.6,34.6),expand=c(0,0))+
 scale_x_continuous(limits=lim,breaks=-1:4)+labs(x='Reading points per 10 SES rank points',y=NULL)+
 theme_minimal(base_size=9,base_family='Helvetica')+
 theme(panel.grid.minor=element_blank(),panel.grid.major.y=element_blank(),panel.grid.major.x=element_line(colour='#E4E9EB'),
 axis.text.y=element_text(size=8,colour='#263A45'),axis.text.x=element_text(size=8),legend.title=element_blank(),legend.text=element_text(size=8),plot.margin=margin(8,8,8,8))
})
p<-(pp[[1]]|pp[[2]])+plot_layout(guides='collect')+
 plot_annotation(title='How much does school sorting add to the skills pathway?',
 subtitle='27 of 67 systems have positive 95% intervals; 23 retain support after BH adjustment',
 caption=paste0(mean_note,'\nAdditional reading points per 10 socio-economic rank points. Bars: direct 95% intervals for the difference.\nOrdered by the estimated addition, continuing from left to right. Both panels use the same scale.\nShapes: strongest unadjusted threshold met; not significant at 10%. Colour: BH adjustment across joint-pathway and sorting tests.'),
 theme=theme(plot.title=element_text(size=13,face='bold',colour='#172F3B'),plot.subtitle=element_text(size=9,colour='#475961'),plot.caption=element_text(size=8,hjust=0,colour='#475961'))) & theme(legend.position='top')
for(ext in c('pdf','png','svg')) {
 dev<-switch(ext,pdf=cairo_pdf,png=ragg::agg_png,svg=svglite::svglite)
 ggsave(file.path(OUT,'figures',paste0('ses_sorting_increment.',ext)),p,width=7.4,height=8.2,dpi=300,device=dev,bg='white')
}
fwrite(z,file.path(OUT,'tables/ses_sorting_increment_figure_data.csv'))
message('Sorting-addition figure verified against all 67 saved contrasts; no regressions fitted.')

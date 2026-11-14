# Korea worked example alongside the equal-weight mean of all retained systems.
terms <- c('recipient_change','reference_change','gap_reduction')
z <- copy(CE[CNT=='KOR' & exposure=='SES' & term %in% terms])
mn<-system_mean(CE[exposure=='SES' & term %in% terms])
z[,Profile:='Korea'];mn[,Profile:=paste0('Mean (',nsys(),' systems)')]
z<-rbindlist(list(z,mn),fill=TRUE)
z[,row:=match(term,rev(terms))]
z[,yy:=row+ifelse(Profile=='Korea',.16,-.16)]
stopifnot(z[,max(abs(estimate[term=='recipient_change']-estimate[term=='reference_change']-estimate[term=='gap_reduction'])),by=Profile][,max(V1)]<1e-9)
labels<-c('Net gap reduction','Comparison-group gain','Recipient gain')
p<-ggplot(z,aes(estimate,yy,colour=Profile))+
 geom_vline(xintercept=0,colour='#71838A',linewidth=.35)+
 geom_segment(aes(x=0,xend=estimate,yend=yy),linewidth=3.3,alpha=.22)+
 geom_segment(aes(x=lower,xend=upper,yend=yy),linewidth=.7)+
 geom_point(aes(shape=Profile),size=2.7)+
 geom_text(aes(x=43,label=sprintf('%.2f',estimate)),hjust=1,size=3.1,show.legend=FALSE)+
 scale_colour_manual(values=c('Korea'='#17677E',setNames('#BB5839',paste0('Mean (',nsys(),' systems)'))))+
 scale_shape_manual(values=c(16,18))+
 scale_y_continuous(breaks=1:3,labels=labels,limits=c(.5,3.5),expand=c(0,0))+
 scale_x_continuous(breaks=seq(0,40,10),limits=c(0,44),expand=c(0,0))+
 labs(title='Recipient gains and the reduction in inequality',
 subtitle='Korea and the equal-weight mean across retained systems',
 x='Predicted change (reading points)',y=NULL,
 caption=paste0('Gap reduction = recipient gain minus comparison-group gain. Lines: 95% intervals.\n',mean_note))+
 theme(legend.position='top',legend.text=element_text(size=8),
 axis.text.y=element_text(size=9),plot.title=element_text(size=12),
 plot.subtitle=element_text(size=9),plot.caption=element_text(size=7.8,hjust=0,colour='#475961'))
save_fig(p,'ses_recipient_gap_korea',7.4,3.5)
fwrite(z,file.path(OUT,'tables/ses_recipient_gap_korea.csv'))

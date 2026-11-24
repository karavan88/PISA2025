# Approved accounting waterfall; saved estimates only.
terms<-c('recipient_change','reference_change','gap_reduction')
z<-rbindlist(list(CE[CNT=='KOR'&exposure=='SES'&term%in%terms],system_mean(CE[exposure=='SES'&term%in%terms])),fill=TRUE)
z[,Profile:=factor(ifelse(CNT=='KOR','Korea',paste0('Mean (',nsys(),' systems)')),levels=c('Korea',paste0('Mean (',nsys(),' systems)')))]
bars<-rbindlist(lapply(levels(z$Profile),function(pr) {
 zz<-z[Profile==pr];r<-zz[term=='recipient_change',estimate];g<-zz[term=='gap_reduction',estimate]
 data.table(Profile=pr,step=1:3,start=c(0,g,0),end=c(r,r,g),value=c(r,-zz[term=='reference_change',estimate],g))
}))
errs<-z[term!='reference_change'];errs[,step:=ifelse(term=='recipient_change',1L,3L)]
p<-ggplot(bars)+geom_hline(yintercept=0,colour='grey60')+
 geom_rect(aes(xmin=step-.32,xmax=step+.32,ymin=start,ymax=end,fill=factor(step)))+
 geom_segment(data=bars[step==1],aes(x=1.32,xend=1.68,y=end,yend=end),linetype='dotted',colour='grey50')+
 geom_segment(data=bars[step==3],aes(x=2.32,xend=2.68,y=end,yend=end),linetype='dotted',colour='grey50')+
 geom_errorbar(data=errs,aes(x=step,ymin=lower,ymax=upper),width=.1,linewidth=.45)+
 geom_text(data=bars[abs(end-start)>=2],aes(x=step,y=(start+end)/2,label=sprintf('%+.2f',value)),colour='white',fontface='bold',size=3.6)+
 geom_text(data=bars[abs(end-start)<2],aes(x=step,y=pmax(start,end)+1,label=sprintf('%+.2f',value)),colour='#263A45',fontface='bold',size=3.6,vjust=0)+
 scale_fill_manual(values=c('#17677E','#929FA7','#BB5839'),guide='none')+
 scale_x_continuous(breaks=1:3,labels=c('Recipient\ngain','Subtract advantaged\ngroup gain','Gap\nreduction'))+
 facet_wrap(~Profile,nrow=1)+labs(x=NULL,y='Predicted reading change (points)')
stopifnot(z[,max(abs(estimate[term=='recipient_change']-estimate[term=='reference_change']-estimate[term=='gap_reduction'])),by=Profile][,max(V1)]<1e-9)
save_fig(p,'ses_recipient_gap_korea',7.4,4.2)
fwrite(z,file.path(OUT,'tables/ses_recipient_gap_korea.csv'))

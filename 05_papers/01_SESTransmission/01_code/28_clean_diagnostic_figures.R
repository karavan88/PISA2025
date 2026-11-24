# Reporting only: read previously saved descriptive coordinates and grade estimates.
library(data.table);library(ggplot2)
FIGOUT <- '05_papers/01_SESTransmission/04_output/rev2/figures'
base <- '05_papers/01_SESTransmission/04_output/escs_skill_scatter_20261117_v2'
pt <- fread(file.path(base,'scatter_bin_means.csv'))[sample=='All analytic pupils']
ln <- fread(file.path(base,'fitted_lines.csv'))[sample=='All analytic pupils']
labels <- c('Perseverance','Curiosity','Enjoyment of problem solving','Cognitive adaptability','Goal setting','Self-regulated help seeking')
pt[,skill:=factor(skill,levels=labels)];ln[,skill:=factor(skill,levels=labels)]
p <- ggplot()+geom_hline(yintercept=0,color='grey85',linewidth=.3)+geom_point(data=pt,aes(ESCS,value,color=CNT),alpha=.23,size=.65)+geom_line(data=ln,aes(ESCS,value,color=CNT,group=CNT),alpha=.7,linewidth=.45)+facet_wrap(~skill,ncol=3)+scale_color_viridis_d(option='D',end=.95)+labs(x='Socio-economic status (continuous ESCS)',y='Skill (within-country SD)')+theme_minimal(base_size=12)+theme(legend.position='none',panel.grid.minor=element_blank(),strip.text=element_text(face='bold'))
ggplot2::ggsave(file.path(FIGOUT,'escs_skills_clean.png'),p,width=15,height=8,dpi=180,bg='white')
G<-fread('05_papers/01_SESTransmission/04_output/grade_diagnostics_20261117_v2/matched_grade_means.csv')
MOD<-c('Age adjusted','SES adjusted','School FE','School FE + quadratic age');SUB<-c('All','Never repeated','Urban female non-repeaters','Urban male non-repeaters')
G[,`:=`(model=factor(model,MOD),sample=factor(sample,SUB),outcome=factor(outcome,c('Reading','PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG'),labels=c('Reading',labels)))]
p<-ggplot(G,aes(model,estimate,color=sample,group=sample))+geom_hline(yintercept=0,color='grey65')+geom_line(position=position_dodge(.4))+geom_errorbar(aes(ymin=lower,ymax=upper),width=.15,position=position_dodge(.4))+geom_point(position=position_dodge(.4))+facet_wrap(~outcome,scales='free_y',ncol=2)+scale_color_manual(values=c('#224B5E','#CB703A','#629782','#815E9C'))+labs(x=NULL,y='Difference associated with 1 higher grade',color=NULL)+theme_minimal(base_size=11)+theme(axis.text.x=element_text(angle=20,hjust=1),legend.position='bottom')
ggplot2::ggsave(file.path(FIGOUT,'grade_means_clean.png'),p,width=12,height=11,dpi=180,bg='white')

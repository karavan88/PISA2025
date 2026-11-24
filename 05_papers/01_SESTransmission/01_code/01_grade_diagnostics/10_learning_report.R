library(data.table);library(ggplot2)
OUT<-'05_papers/01_SESTransmission/04_output/learning_gradients_20261117';E<-fread(file.path(OUT,'country_models.csv'));M<-fread(file.path(OUT,'gradient_associations.csv'));P<-fread(file.path(OUT,'gradient_scatter.csv'));V<-fread(file.path(OUT,'validation.csv'))
stopifnot(nrow(V)==16,all(V$lm_error<1e-7),all(is.finite(E$se)),all(is.finite(M$se)),all(E[,uniqueN(N),by=.(CNT,sample)]$V1==1))
audit<-fread('03_outputs/03_learning_diagnostics/sample_audit.csv');stopifnot(all(audit$missing_math==0));cat('PASS: all 16 model families validated against lm; identical pupils across skills and domains; all math values present.\n')
S<-c('PERSEV','CURIO','ENPROBS','COGABIL','GOALSET','SELFREG');labs<-c('Perseverance','Curiosity','Enjoyment of problem solving','Cognitive adaptability','Goal setting','Help seeking')
theme_set(theme_minimal(base_size=12)+theme(panel.grid.minor=element_blank(),strip.text=element_text(face='bold')))
for(y in c('Reading','Math')){
 x<-P[sample=='Never repeated'&model=='Adjusted'&outcome==y];x[,skill:=factor(skill,S,labels=labs)]
 lines<-x[,.(intercept=coef(lm(learning_gradient~skill_gradient))[1],slope=coef(lm(learning_gradient~skill_gradient))[2]),by=skill]
 g<-ggplot(x,aes(skill_gradient,learning_gradient))+geom_hline(yintercept=0,color='grey75')+geom_vline(xintercept=0,color='grey75')+geom_point(color='#25556A',alpha=.65,size=2)+geom_abline(data=lines,aes(intercept=intercept,slope=slope),color='#BD643D',linewidth=.7)+facet_wrap(~skill,scales='free_x',ncol=2)+labs(title=paste('Do larger skill differences between grades accompany larger',tolower(y),'differences?'),subtitle='Each point is a country. Never-repeaters; age, gender, and SES adjusted. Lines are descriptive.',x='Skill difference per additional grade (original-country SDs)',y=paste(y,'points per additional grade'))
 ggsave(file.path(OUT,paste0('gradients_',tolower(y),'.png')),g,width=12,height=10,dpi=180,bg='white');ggsave(file.path(OUT,paste0('gradients_',tolower(y),'.pdf')),g,width=12,height=10,bg='white')
}

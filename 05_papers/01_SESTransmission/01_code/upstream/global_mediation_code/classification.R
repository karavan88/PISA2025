# Deterministic evidence summaries; estimates are never refitted here.
library(data.table)
root <- Sys.getenv('PISA_MEDIATION_INPUT','05_papers/01_SESTransmission/04_output/input')
E <- fread(file.path(root,'estimates.csv')); A <- fread(file.path(root,'eligibility.csv'))
sklab <- c(PERSEV='Perseverance', CURIO='Curiosity', ENPROBS='Enjoyment of problem solving', COGABIL='Cognitive adaptability', GOALSET='Goal setting', SELFREG='Self-regulated learning')
# Evidence rules are calculated once over the full available families, before any
# six-skill reporting restriction. Existing model estimates and q values are intact.
HE<-copy(E)
HE[,summary_q:=NA_real_]
HE[term%in%c('skills_sorting','sorting_increment'),summary_q:=q_primary]
HE[grepl('^indS_',term),summary_q:=q_skill]
HE[grepl('^a[WB]_',term),summary_q:=p.adjust(p_approx,'BH'),by=exposure]
HE[term=='skills_same_school',summary_q:=p.adjust(p_approx,'BH'),by=exposure]
checks<-rbindlist(list(
 data.table(question='H2 / joint pathway',term=c('skills_same_school','skills_sorting'),measure=c('Skills pathway: school context fixed','Skills pathway: allowing for sorting'),family=c('Within-pathway tests across systems, separately by exposure','Joint/sorting tests across systems, separately by exposure')),
 data.table(question='School sorting',term='sorting_increment',measure='Sorting adds a component in the expected direction',family='Joint/sorting tests across systems, separately by exposure'),
 data.table(question='H1 / skill gradient',term=as.vector(outer(c('aW_','aB_'),names(sklab),paste0)),measure=as.vector(outer(c('Within school: ','Between schools: '),unname(sklab),paste0)),family='All available within/between skill-gradient tests, separately by exposure'),
 data.table(question='RQ3 / skill contribution',term=paste0('indS_',names(sklab)),measure=unname(sklab),family='All available individual skill-contribution tests, separately by exposure')
))
HM<-merge(HE,checks,by='term',allow.cartesian=FALSE)
HM[,expected_sign:=ifelse(exposure=='SES',1,-1)]
HM[,classification:=fifelse(expected_sign*lower>0 & expected_sign*upper>0,'Supports',
 fifelse(expected_sign*lower<0 & expected_sign*upper<0,'Opposite','Inconclusive'))]
HM[,adjusted_support:=classification=='Supports' & is.finite(summary_q) & summary_q<.05]
HM<-rbind(copy(HM)[,scope:='All available blocks'],copy(HM[skills==6])[,scope:='Six-skill systems only'])
HS<-HM[,.(estimated=.N,supports=sum(classification=='Supports'),opposite=sum(classification=='Opposite'),
 inconclusive=sum(classification=='Inconclusive'),adjusted_support=sum(adjusted_support)),by=.(scope,exposure,question,term,measure,family)]
HS[,scope_systems:=vapply(seq_len(.N),function(i){ex<-exposure[i];ss<-scope[i];A[exposure==ex&status=='Eligible'&(ss=='All available blocks'|skills==6),.N]},integer(1))]
HS[,not_estimable:=scope_systems-estimated]
stopifnot(all(HS$supports+HS$opposite+HS$inconclusive==HS$estimated),all(HS$not_estimable>=0),all(HS$adjusted_support<=HS$supports))
fwrite(HS,file.path(root,'hypothesis_summary.csv'))
fwrite(HM[,.(scope,exposure,question,term,measure,CNT,economy,skills,expected_sign,estimate,lower,upper,classification,summary_q,adjusted_support,family)],file.path(root,'hypothesis_country_classification.csv'))

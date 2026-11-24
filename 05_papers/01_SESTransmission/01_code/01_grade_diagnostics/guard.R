# Refuse to mix changed data/model definitions into an existing diagnostic run.
guard_stage<-function(stage){
 folder<-'05_papers/01_SESTransmission/01_code/01_grade_diagnostics'
 paths<-c('03_outputs/02_grade_diagnostics/manifest.json',file.path(folder,if(stage=='ols')'01_estimate.R'else'02_mediation.R'))
 if(stage=='mediation')paths<-c(paths,file.path(folder,'01_estimate.R'),'05_papers/01_SESTransmission/01_code/counterfactual_ml.cpp','05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/functions.R','05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/engine.R')
 state<-tools::md5sum(paths);f<-file.path(OUT,paste0(stage,'_signature.rds'))
 if(file.exists(f)){if(!identical(readRDS(f),state))stop('Inputs or estimation code changed. Set GRADE_DIAG_OUT to a fresh directory; preserve this checkpoint.')}
 else {
  if(length(list.files(OUT,pattern=if(stage=='ols')'^ols_'else'^med_')))stop('Existing results lack a matching signature; do not overwrite them. Use a fresh directory.')
  saveRDS(state,f)
 }
 invisible(state)
}

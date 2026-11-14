# Run from the folder containing global_mediation_report.qmd.
# Main fits checkpoint by country and exposure; at most two workers are used.
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/preflight.R')
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/run.R')
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/diagnostics.R')
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/finish.R')
source('05_papers/01_SESTransmission/01_code/upstream/global_mediation_code/classification.R')

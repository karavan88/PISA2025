local({
  project <- Sys.getenv("RENV_PROJECT", unset = getwd())
  Sys.setenv(RENV_CONFIG_SANDBOX_ENABLED = "FALSE",
             RENV_PATHS_LIBRARY = file.path(project, "renv", "library"))
  source(file.path(project, "renv", "activate.R"))
})

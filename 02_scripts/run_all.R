# One-click project build runner
scripts <- c(
  "00_install_packages.R",
  "01_build_from_provided_rda.R",
  "03_extension_balance_tradeoff.R",
  "02_run_reduced_resim_validation.R",
  "04_polished_replication_visuals.R",
  "05_extension_mspe_placebo.R",
  "06_extension_entropy_balance.R",
  "08_export_detailed_data.R",
  "09_additional_r_figures.R"
)

script_root <- "c:/Users/hatem/Downloads/cem_replication_project/02_scripts"
for (s in scripts) {
  cat("Running", s, "...\n")
  local_env <- new.env(parent = globalenv())
  sys.source(file.path(script_root, s), envir = local_env, chdir = TRUE)
}
cat("All scripts completed.\n")

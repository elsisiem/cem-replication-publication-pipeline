repos <- "https://cloud.r-project.org"
needed <- c(
  "cem", "Matching", "MatchIt", "WeightIt",
  "xtable", "ggplot2", "dplyr", "readr", "tidyr",
  "scales", "forcats"
)
installed <- rownames(installed.packages())
to_install <- setdiff(needed, installed)
if (length(to_install) > 0) {
  install.packages(to_install, repos = repos)
}
cat("Installed/verified packages:", paste(needed, collapse = ", "), "\n")

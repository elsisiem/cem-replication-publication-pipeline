suppressPackageStartupMessages({
  library(cem)
  library(Matching)
  library(ggplot2)
  library(dplyr)
  library(readr)
})

source("99_figure_style.R")

root <- "c:/Users/hatem/Downloads/cem_replication_project"
out_fig <- file.path(root, "03_outputs", "figures", "main")
out_tab <- file.path(root, "03_outputs", "tables", "main")

# Extension: coarsening-sensitivity frontier (imbalance vs retained sample)
data(LL)

# Candidate breaks for key continuous variables (progressively coarser)
break_sets <- list(
  list(age = 6, education = 5, re74 = 6, re75 = 6),
  list(age = 5, education = 4, re74 = 5, re75 = 5),
  list(age = 4, education = 4, re74 = 4, re75 = 4),
  list(age = 3, education = 3, re74 = 3, re75 = 3)
)

mk_breaks <- function(x, k) unique(quantile(x, probs = seq(0, 1, length.out = k + 1), na.rm = TRUE))

rows <- list()
for (i in seq_along(break_sets)) {
  bs <- break_sets[[i]]
  br <- list(
    age = mk_breaks(LL$age, bs$age),
    education = mk_breaks(LL$education, bs$education),
    re74 = mk_breaks(LL$re74, bs$re74),
    re75 = mk_breaks(LL$re75, bs$re75)
  )

  m <- cem(treatment = "treated", data = LL, drop = "re78", cutpoints = br)
  idx <- which(m$matched)

  l1_raw <- L1.meas(LL$treated, LL[, setdiff(names(LL), c("treated", "re78"))], breaks = br)$L1
  l1_mat <- L1.meas(LL$treated[idx], LL[idx, setdiff(names(LL), c("treated", "re78"))], breaks = br)$L1

  rows[[i]] <- data.frame(
    Spec = paste0("S", i),
    AgeBins = bs$age,
    EduBins = bs$education,
    Re74Bins = bs$re74,
    Re75Bins = bs$re75,
    MatchedN = length(idx),
    MatchedTreated = sum(LL$treated[idx] == 1),
    MatchedControl = sum(LL$treated[idx] == 0),
    L1Raw = l1_raw,
    L1Matched = l1_mat,
    L1ReductionPct = 100 * (l1_raw - l1_mat) / l1_raw
  )
}

frontier <- bind_rows(rows)
write_csv(frontier, file.path(out_tab, "extension_coarsening_frontier.csv"))

p <- ggplot(frontier, aes(x = MatchedN, y = L1Matched, label = Spec)) +
  geom_line(color = "black", linewidth = 0.7, linetype = "22") +
  geom_point(size = 3.1, color = "black", shape = 21, fill = "white", stroke = 0.8) +
  geom_text(vjust = -0.8, size = 4) +
  labs(
    x = "Matched sample size",
    y = "Post-match L1 imbalance"
  ) +
  theme_pub()
save_pub(file.path(out_fig, "fig6_extension_coarsening_frontier.png"), p, width = 10, height = 6)

cat("Extension sensitivity analysis complete.\n")

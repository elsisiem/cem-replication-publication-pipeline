suppressPackageStartupMessages({
  library(cem)
  library(WeightIt)
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(tidyr)
})

source("99_figure_style.R")

root <- "c:/Users/hatem/Downloads/cem_replication_project"
out_fig_main <- file.path(root, "03_outputs", "figures", "main")
out_fig_app <- file.path(root, "03_outputs", "figures", "appendix")
out_tab_main <- file.path(root, "03_outputs", "tables", "main")
out_tab_app <- file.path(root, "03_outputs", "tables", "appendix")

# Compare CEM against a contemporary baseline: entropy balancing
data(LL)
Y <- LL$re78
Tt <- LL$treated
X <- LL[, -c(1, 9)]
for (i in seq_len(ncol(X))) X[, i] <- as.numeric(X[, i])

# Helper for weighted SMD
wmean <- function(x, w) sum(w * x) / sum(w)
wvar <- function(x, w) {
  m <- wmean(x, w)
  sum(w * (x - m)^2) / sum(w)
}

smd_weighted <- function(x, tr, w_t, w_c) {
  xt <- x[tr == 1]
  xc <- x[tr == 0]
  wt <- w_t[tr == 1]
  wc <- w_c[tr == 0]
  mt <- wmean(xt, wt)
  mc <- wmean(xc, wc)
  sp <- sqrt((wvar(xt, wt) + wvar(xc, wc)) / 2)
  if (!is.finite(sp) || sp == 0) return(0)
  (mt - mc) / sp
}

covars <- names(X)

# Raw SMDs
raw_smd <- sapply(covars, function(v) smd_weighted(X[[v]], Tt, rep(1, length(Tt)), rep(1, length(Tt))))

# CEM weights
LL2 <- data.frame(treated = Tt, X, re78 = Y)
cem_fit <- cem("treated", LL2, drop = "re78")
wc <- cem_fit$w
cem_smd <- sapply(covars, function(v) smd_weighted(X[[v]], Tt, wc, wc))

# Entropy balancing weights
eb <- weightit(treated ~ age + education + re74 + re75 + black + hispanic + nodegree + married + u74 + u75,
               data = LL2, method = "ebal", estimand = "ATT")
we <- eb$weights
ebal_smd <- sapply(covars, function(v) smd_weighted(X[[v]], Tt, we, we))

bal_tab <- tibble(
  Covariate = covars,
  Raw = raw_smd,
  CEM = cem_smd,
  EBAL = ebal_smd
)

bal_long <- bal_tab %>%
  pivot_longer(cols = c(Raw, CEM, EBAL), names_to = "Method", values_to = "SMD") %>%
  mutate(absSMD = abs(SMD))

write_csv(bal_tab, file.path(out_tab_main, "extension_balance_comparison_cem_vs_ebal.csv"))

# ATT comparison for context
att_raw <- mean(Y[Tt == 1]) - mean(Y[Tt == 0])
att_cem <- {
  tr_idx <- which(cem_fit$groups == "1" & cem_fit$matched)
  ct_idx <- which(cem_fit$groups == "0" & cem_fit$matched)
  weighted.mean(Y[tr_idx], wc[tr_idx]) - weighted.mean(Y[ct_idx], wc[ct_idx])
}
att_ebal <- weighted.mean(Y[Tt == 1], we[Tt == 1]) - weighted.mean(Y[Tt == 0], we[Tt == 0])

att_tab <- tibble(Method = c("Raw", "CEM", "EBAL"), ATT = c(att_raw, att_cem, att_ebal))
write_csv(att_tab, file.path(out_tab_app, "appendix_att_comparison_raw_cem_ebal.csv"))

# MAIN: Love plot
p_love <- ggplot(bal_long, aes(x = absSMD, y = reorder(Covariate, absSMD), shape = Method, fill = Method)) +
  geom_point(size = 2.9, alpha = 1, stroke = 0.75, color = "black") +
  geom_vline(xintercept = 0.1, linetype = "dashed", color = "gray40", linewidth = 0.7) +
  scale_shape_manual(values = c("Raw" = 21, "CEM" = 22, "EBAL" = 24)) +
  scale_fill_manual(values = c("Raw" = "gray35", "CEM" = "white", "EBAL" = "gray70")) +
  labs(
    x = "|Standardized Mean Difference|",
    y = NULL,
    shape = "Method"
  ) +
  theme_pub() +
  guides(
    shape = guide_legend(order = 1),
    fill = "none"
  )

save_pub(file.path(out_fig_main, "fig5_extension_loveplot_cem_vs_ebal.png"), p_love, width = 11, height = 8)

# APPENDIX: ATT comparison bars
p_att <- ggplot(att_tab, aes(x = Method, y = ATT, fill = Method)) +
  geom_col(width = 0.65, show.legend = FALSE, color = "black", linewidth = 0.3) +
  scale_fill_manual(values = c("Raw" = "white", "CEM" = "gray55", "EBAL" = "gray30")) +
  geom_text(aes(label = sprintf("%.1f", ATT)), vjust = -0.35, size = 3.6) +
  expand_limits(y = max(att_tab$ATT) * 1.08) +
  labs(
    x = NULL,
    y = "Estimated ATT"
  ) +
  theme_pub() +
  theme(legend.position = "none")

save_pub(file.path(out_fig_app, "figA5_att_raw_cem_ebal.png"), p_att, width = 8, height = 6)

cat("Entropy balancing extension complete.\n")

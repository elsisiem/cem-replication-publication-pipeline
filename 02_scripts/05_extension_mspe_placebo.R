suppressPackageStartupMessages({
  library(cem)
  library(Matching)
  library(WeightIt)
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(readr)
})

source("99_figure_style.R")

set.seed(20260416)

root <- "c:/Users/hatem/Downloads/cem_replication_project"
out_fig_main <- file.path(root, "03_outputs", "figures", "main")
out_fig_app <- file.path(root, "03_outputs", "figures", "appendix")
out_tab_main <- file.path(root, "03_outputs", "tables", "main")
out_tab_app <- file.path(root, "03_outputs", "tables", "appendix")
out_data <- file.path(root, "03_outputs", "data")

# Data for perturbation/placebo diagnostics
data(DW)
X <- DW[, -c(1, 9)]
for (i in seq_len(ncol(X))) X[, i] <- as.numeric(X[, i])
n <- nrow(X)

# Treatment assignment model from replication script design
prop0 <- glm(DW$treated ~ I(age^2) + I(education^2) + black + hispanic + married + nodegree + I(re74^2) + I(re75^2) + u74 + u75,
             family = binomial, data = X)
M <- cbind(rep(1, n), prop0$linear.pred, I(log(X$age)^2), I(log(X$education)^2), I(log(X$re74 + 0.01)^2), I(log(X$re75 + 0.01)^2))
coefs <- matrix(c(1, .5, .01, -.3, -0.01, 0.01), ncol = 1)
Tr.pred <- exp(M %*% coefs) / (1 + exp(M %*% coefs))

estimate_all <- function(d, tr, y) {
  out <- c(CEM.W = NA_real_, PSC = NA_real_, MAH = NA_real_, EBAL = NA_real_)
  d1 <- data.frame(treat = tr, d)

  # CEM weighted ATT
  cm <- tryCatch(cem("treat", d1), error = function(e) NULL)
  if (!is.null(cm)) {
    tr_idx <- which(cm$groups == "1" & cm$matched)
    ct_idx <- which(cm$groups == "0" & cm$matched)
    if (length(tr_idx) > 2 && length(ct_idx) > 2) {
      out["CEM.W"] <- weighted.mean(y[tr_idx], cm$w[tr_idx]) - weighted.mean(y[ct_idx], cm$w[ct_idx])
    }
  }

  # PSC matching
  pfit <- tryCatch(glm(tr ~ age + education + re74 + re75 + black + hispanic + nodegree + married + u74 + u75,
                       family = binomial, data = d1), error = function(e) NULL)
  if (!is.null(pfit)) {
    psm <- tryCatch(Match(Tr = tr, X = pfit$fitted, M = 1, replace = FALSE), error = function(e) NULL)
    if (!is.null(psm)) {
      out["PSC"] <- mean(y[psm$index.treated]) - mean(y[psm$index.control])
    }
  }

  # MAH matching
  mah <- tryCatch(Match(Tr = tr, X = d, Weight = 2, M = 1, replace = FALSE), error = function(e) NULL)
  if (!is.null(mah)) {
    out["MAH"] <- mean(y[mah$index.treated]) - mean(y[mah$index.control])
  }

  # Entropy balancing baseline
  ebal <- tryCatch(weightit(tr ~ age + education + re74 + re75 + black + hispanic + nodegree + married + u74 + u75,
                            data = d1, method = "ebal", estimand = "ATT"), error = function(e) NULL)
  if (!is.null(ebal)) {
    w <- ebal$weights
    out["EBAL"] <- weighted.mean(y[tr == 1], w[tr == 1]) - weighted.mean(y[tr == 0], w[tr == 0])
  }

  out
}

# 1) MSPE-ratio diagnostic under perturbation
R <- 180
truth <- 1000
base_err <- matrix(NA_real_, nrow = R, ncol = 4, dimnames = list(NULL, c("CEM.W", "PSC", "MAH", "EBAL")))
pert_err <- base_err

for (r in 1:R) {
  tr <- rbinom(n, 1, Tr.pred)
  if (sum(tr == 1) < 10 || sum(tr == 0) < 10) next

  y <- truth * tr + .1 * exp(.7 * log(X$re74 + 0.01) + .7 * log(X$re75 + 0.01)) + rnorm(n, 0, 10)
  est_base <- estimate_all(X, tr, y)

  Xp <- X
  Xp$re75 <- X$re75 + rnorm(n, mean = 1000, sd = 1000)
  Xp$re75[Xp$re75 < 0] <- 0
  est_pert <- estimate_all(Xp, tr, y)

  base_err[r, ] <- (est_base - truth)^2
  pert_err[r, ] <- (est_pert - truth)^2
}

mspe_tab <- tibble(
  Method = colnames(base_err),
  MSPE_Base = colMeans(base_err, na.rm = TRUE),
  MSPE_Perturbed = colMeans(pert_err, na.rm = TRUE),
  MSPE_Ratio_Perturbed_over_Base = MSPE_Perturbed / MSPE_Base
)
write_csv(mspe_tab, file.path(out_tab_main, "extension_mspe_ratio_diagnostic.csv"))

mspe_long <- tibble(
  rep = rep(seq_len(nrow(base_err)), times = ncol(base_err)),
  method = rep(colnames(base_err), each = nrow(base_err)),
  mspe_base = as.vector(base_err),
  mspe_perturbed = as.vector(pert_err)
) %>%
  mutate(mspe_ratio = mspe_perturbed / mspe_base)
write_csv(mspe_long, file.path(out_data, "extension_mspe_replication_long.csv"))

p_mspe <- ggplot(mspe_tab, aes(x = reorder(Method, MSPE_Ratio_Perturbed_over_Base), y = MSPE_Ratio_Perturbed_over_Base)) +
  geom_col(show.legend = FALSE, width = 0.68, fill = "gray60", color = "black", linewidth = 0.32) +
  geom_text(aes(label = sprintf("%.2f", MSPE_Ratio_Perturbed_over_Base)), hjust = -0.15, size = 3.6) +
  coord_flip() +
  labs(
    x = NULL,
    y = "MSPE ratio (perturbed / base)"
  ) +
  expand_limits(y = max(mspe_tab$MSPE_Ratio_Perturbed_over_Base) * 1.08) +
  theme_pub()

save_pub(file.path(out_fig_main, "fig4_extension_mspe_ratio.png"), p_mspe, width = 11, height = 7)

# 2) Placebo reweighting/permutation diagnostic on LL data
data(LL)
y_obs <- LL$re78
tr_obs <- LL$treated
D_obs <- LL[, -c(1, 9)]
for (i in seq_len(ncol(D_obs))) D_obs[, i] <- as.numeric(D_obs[, i])

obs_est <- estimate_all(D_obs, tr_obs, y_obs)
B <- 250
plac <- matrix(NA_real_, nrow = B, ncol = length(obs_est), dimnames = list(NULL, names(obs_est)))

for (b in 1:B) {
  tr_p <- sample(tr_obs)
  plac[b, ] <- estimate_all(D_obs, tr_p, y_obs)
}

placebo_tab <- tibble(
  Method = names(obs_est),
  Observed_ATT = as.numeric(obs_est),
  Placebo_Mean = colMeans(plac, na.rm = TRUE),
  Placebo_SD = apply(plac, 2, sd, na.rm = TRUE),
  Placebo_p_two_sided = sapply(seq_along(obs_est), function(j) {
    pj <- plac[, j]
    mean(abs(pj) >= abs(obs_est[j]), na.rm = TRUE)
  })
)
write_csv(placebo_tab, file.path(out_tab_app, "appendix_placebo_reweighting_results.csv"))

plac_df <- as.data.frame(plac) %>%
  pivot_longer(cols = everything(), names_to = "Method", values_to = "PlaceboATT")
obs_df <- data.frame(Method = names(obs_est), ObservedATT = as.numeric(obs_est))
write_csv(plac_df, file.path(out_data, "extension_placebo_samples_long.csv"))
write_csv(obs_df, file.path(out_data, "extension_placebo_observed.csv"))

p_placebo <- ggplot(plac_df, aes(x = PlaceboATT)) +
  geom_histogram(bins = 35, fill = "gray85", alpha = 1, color = "black", linewidth = 0.3) +
  geom_vline(data = obs_df, aes(xintercept = ObservedATT), linewidth = 1, linetype = "longdash", color = "black") +
  facet_wrap(~ Method, scales = "free", ncol = 2) +
  labs(
    x = "Placebo ATT",
    y = "Count"
  ) +
  theme_pub() +
  theme(legend.position = "none")

save_pub(file.path(out_fig_app, "figA4_placebo_distributions.png"), p_placebo, width = 12, height = 9)

cat("MSPE ratio and placebo diagnostics complete.\n")

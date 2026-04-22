suppressPackageStartupMessages({
  library(cem)
  library(Matching)
  library(ggplot2)
  library(dplyr)
  library(readr)
})

source("99_figure_style.R")

set.seed(20260416)

root <- "c:/Users/hatem/Downloads/cem_replication_project"
out_fig <- file.path(root, "03_outputs", "figures", "appendix")
out_tab <- file.path(root, "03_outputs", "tables", "appendix")

# Reduced simulation adapted from cemsim-penta.R for internal validity check
# Uses data included in cem package
data(DW)

tsub <- which(DW$treated == 1)
csub <- which(DW$treated == 0)
dati <- DW[, -c(1, 9)]
n <- nrow(dati)

for (i in seq_len(ncol(dati))) dati[, i] <- as.numeric(dati[, i])

treated0 <- DW$treated

propensity <- glm(treated0 ~ I(age^2) + I(education^2) + black + hispanic + married + nodegree + I(re74^2) + I(re75^2) + u74 + u75,
                  family = binomial, data = dati)

M <- cbind(rep(1, n), propensity$linear.pred, I(log(dati$age)^2), I(log(dati$education)^2), I(log(dati$re74 + 0.01)^2), I(log(dati$re75 + 0.01)^2))
coeffs <- matrix(c(1, .5, .01, -.3, -0.01, 0.01), ncol = 1)
mu <- M %*% coeffs
Tr.pred <- exp(mu) / (1 + exp(mu))

MCSim <- 120
TreatmentEffect <- 1000

res <- matrix(NA_real_, nrow = MCSim, ncol = 5)
colnames(res) <- c("RAW", "MAH", "PSC", "GEN", "CEM.W")

for (mc in 1:MCSim) {
  tr <- rbinom(n, 1, Tr.pred)
  if (sum(tr == 1) < 5 || sum(tr == 0) < 5) {
    next
  }
  y <- TreatmentEffect * tr + .1 * exp(.7 * log(dati$re74 + 0.01) + .7 * log(dati$re75 + 0.01)) + rnorm(n, 0, 10)

  # CEM
  d1 <- data.frame(treat = tr, dati)
  cem.mat <- tryCatch(cem("treat", d1), error = function(e) NULL)
  if (is.null(cem.mat)) {
    next
  }
  cem.tr <- which(cem.mat$groups == "1" & cem.mat$matched == TRUE)
  cem.ct <- which(cem.mat$groups == "0" & cem.mat$matched == TRUE)
  if (length(cem.tr) < 3 || length(cem.ct) < 3) {
    next
  }

  # MAH
  mah <- tryCatch(Match(Tr = tr, X = dati, Weight = 2, M = 1, replace = FALSE), error = function(e) NULL)
  if (is.null(mah)) {
    next
  }
  # PSC
  psc <- tryCatch(glm(tr ~ age + education + re74 + re75 + black + hispanic + nodegree + married + u74 + u75, family = binomial, data = d1), error = function(e) NULL)
  if (is.null(psc)) {
    next
  }
  psm <- tryCatch(Match(Tr = tr, X = psc$fitted, M = 1, replace = FALSE), error = function(e) NULL)
  if (is.null(psm)) {
    next
  }
  # GEN
  genw <- tryCatch(GenMatch(X = dati, Tr = tr, pop.size = 40, max.generations = 4, wait.generations = 1, print.level = 0), error = function(e) NULL)
  if (is.null(genw)) {
    next
  }
  genm <- tryCatch(Match(Y = y, Tr = tr, X = dati, Weight.matrix = genw), error = function(e) NULL)
  if (is.null(genm)) {
    next
  }

  res[mc, "RAW"] <- mean(y[tr == 1]) - mean(y[tr == 0])
  res[mc, "MAH"] <- mean(y[mah$index.treated]) - mean(y[mah$index.control])
  res[mc, "PSC"] <- mean(y[psm$index.treated]) - mean(y[psm$index.control])
  res[mc, "GEN"] <- genm$est
  res[mc, "CEM.W"] <- weighted.mean(y[cem.tr], cem.mat$w[cem.tr]) - weighted.mean(y[cem.ct], cem.mat$w[cem.ct])
}

summary_tab <- data.frame(
  Method = colnames(res),
  Bias = colMeans(res, na.rm = TRUE) - 1000,
  SD = apply(res, 2, sd, na.rm = TRUE),
  RMSE = sqrt(colMeans((res - 1000)^2, na.rm = TRUE))
)
write_csv(summary_tab, file.path(out_tab, "reduced_resim_summary.csv"))

p <- ggplot(summary_tab, aes(x = Method, y = RMSE, fill = Method)) +
  geom_col(show.legend = FALSE, color = "black", linewidth = 0.3) +
  scale_fill_manual(values = c("RAW" = "white", "MAH" = "gray75", "PSC" = "gray55", "GEN" = "gray35", "CEM.W" = "black")) +
  geom_text(aes(label = sprintf("%.1f", RMSE)), vjust = -0.3, size = 3.6, color = "black") +
  expand_limits(y = max(summary_tab$RMSE) * 1.08) +
  labs(
    y = "RMSE",
    x = "Method"
  ) +
  theme_pub()
save_pub(file.path(out_fig, "figA7_reduced_resim_rmse.png"), p, width = 10, height = 6)

cat("Reduced resimulation complete.\n")

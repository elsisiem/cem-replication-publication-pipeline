suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(scales)
  library(forcats)
})

source("99_figure_style.R")

root <- "c:/Users/hatem/Downloads/cem_replication_project"
out_fig_main <- file.path(root, "03_outputs", "figures", "main")
out_fig_app <- file.path(root, "03_outputs", "figures", "appendix")
out_tab_main <- file.path(root, "03_outputs", "tables", "main")
out_tab_app <- file.path(root, "03_outputs", "tables", "appendix")
raw_dir <- file.path(root, "00_raw_dataverse")

# Load core simulation results used in original replication package
load(file.path(raw_dir, "cemsim-penta.rda"))

# Build tidy summaries
perf <- data.frame(Method = colnames(tmp)) %>%
  mutate(
    Bias = colMeans(tmp, na.rm = TRUE) - 1000,
    SD = apply(tmp, 2, sd, na.rm = TRUE),
    RMSE = sqrt(colMeans((tmp - 1000)^2, na.rm = TRUE)),
    Runtime = c(0, colMeans(times, na.rm = TRUE), colMeans(times, na.rm = TRUE)["CEM"]),
    L1 = c(colMeans(ELLE1, na.rm = TRUE), colMeans(ELLE1, na.rm = TRUE)["CEM"])
  )

# Keep methods most relevant to paper text
perf_main <- perf %>% filter(Method %in% c("MAH", "PSC", "GEN", "CEM", "CEM.W"))

# Assign cleaner labels
method_labels <- c(
  "MAH" = "Mahalanobis",
  "PSC" = "Propensity Score",
  "GEN" = "Genetic Matching",
  "CEM" = "CEM (Unweighted)",
  "CEM.W" = "CEM (Weighted)",
  "RAW" = "Unmatched"
)

perf <- perf %>% mutate(MethodLabel = recode(Method, !!!method_labels))
perf_main <- perf_main %>% mutate(MethodLabel = recode(Method, !!!method_labels))

method_order <- c("Mahalanobis", "Propensity Score", "Genetic Matching", "CEM (Unweighted)", "CEM (Weighted)")
perf_main$MethodLabel <- factor(perf_main$MethodLabel, levels = method_order)
perf$MethodLabel <- factor(perf$MethodLabel, levels = c("Unmatched", method_order))

write_csv(perf, file.path(out_tab_app, "appendix_full_method_performance.csv"))
write_csv(perf_main, file.path(out_tab_main, "main_method_performance.csv"))

# MAIN FIGURE 1: RMSE vs L1 frontier
p1 <- ggplot(perf_main, aes(x = L1, y = RMSE, shape = MethodLabel, size = Runtime)) +
  geom_point(color = "black", fill = "white", stroke = 0.85, alpha = 0.98) +
  scale_shape_manual(values = unname(method_shape_map[method_order])) +
  scale_x_continuous(expand = expansion(mult = c(0.03, 0.08))) +
  scale_y_continuous(expand = expansion(mult = c(0.03, 0.08))) +
  scale_size_continuous(range = c(3, 10), labels = number_format(accuracy = 0.01)) +
  labs(
    x = "Average L1 imbalance (lower is better)",
    y = "RMSE of ATT estimate (lower is better)",
    shape = "Method",
    size = "Runtime (s)"
  ) +
  guides(
    shape = guide_legend(order = 1, override.aes = list(size = 3.8, fill = "white")),
    size = guide_legend(order = 2)
  ) +
  theme_pub() +
  theme(legend.box = "vertical")

save_pub(file.path(out_fig_main, "fig1_frontier_rmse_l1_runtime.png"), p1, width = 12, height = 8)

# MAIN FIGURE 2: Bias and SD comparison
long2 <- perf_main %>%
  dplyr::select(MethodLabel, Bias, SD) %>%
  tidyr::pivot_longer(cols = c(Bias, SD), names_to = "Metric", values_to = "Value") %>%
  mutate(Metric = factor(Metric, levels = c("Bias", "SD")))

seg2 <- perf_main %>%
  transmute(
    MethodLabel,
    x_min = pmin(Bias, SD),
    x_max = pmax(Bias, SD)
  )

p2 <- ggplot(long2, aes(x = Value, y = MethodLabel)) +
  geom_vline(xintercept = 0, color = "gray45", linewidth = 0.55) +
  geom_segment(
    data = seg2,
    aes(x = x_min, xend = x_max, y = MethodLabel, yend = MethodLabel),
    inherit.aes = FALSE,
    color = "gray35",
    linewidth = 0.65
  ) +
  geom_point(aes(shape = Metric, fill = Metric), color = "black", size = 3.1, stroke = 0.8) +
  scale_shape_manual(values = c("Bias" = 21, "SD" = 24)) +
  scale_fill_manual(values = c("Bias" = "black", "SD" = "white")) +
  labs(
    x = "Estimated value",
    y = NULL,
    shape = "Metric",
    fill = "Metric"
  ) +
  theme_pub()

save_pub(file.path(out_fig_main, "fig2_bias_sd_profile.png"), p2, width = 11, height = 7)

# MAIN FIGURE 3: L1 comparison focused on core methods
p3 <- ggplot(perf_main, aes(x = fct_reorder(MethodLabel, L1), y = L1)) +
  geom_col(show.legend = FALSE, width = 0.68, fill = "gray55", color = "black", linewidth = 0.3) +
  coord_flip() +
  geom_text(aes(label = sprintf("%.3f", L1)), hjust = -0.1, size = 3.8) +
  expand_limits(y = max(perf_main$L1) * 1.12) +
  labs(
    x = NULL,
    y = "Average L1 imbalance"
  ) +
  theme_pub()

save_pub(file.path(out_fig_main, "fig3_l1_core_methods.png"), p3, width = 11, height = 7)

# APPENDIX FIGURE A1: distribution of ATT estimates
att_long <- as.data.frame(tmp) %>%
  tidyr::pivot_longer(cols = everything(), names_to = "Method", values_to = "ATT") %>%
  mutate(MethodLabel = recode(Method, !!!method_labels))

pA1 <- ggplot(att_long, aes(x = MethodLabel, y = ATT, fill = MethodLabel)) +
  geom_violin(alpha = 0.92, trim = FALSE, color = "black", linewidth = 0.35, fill = "white") +
  geom_boxplot(width = 0.12, outlier.alpha = 0.06, fill = "gray92", color = "black", linewidth = 0.3) +
  geom_hline(yintercept = 1000, linetype = "longdash", linewidth = 0.95, color = "black") +
  coord_flip() +
  guides(fill = "none") +
  labs(
    x = NULL,
    y = "Estimated ATT"
  ) +
  theme_pub()

save_pub(file.path(out_fig_app, "figA1_att_distributions_violin.png"), pA1, width = 12, height = 8)

# APPENDIX FIGURE A2: runtime on log scale
pA2 <- ggplot(perf %>% filter(Method != "RAW"), aes(x = fct_reorder(MethodLabel, Runtime), y = Runtime)) +
  geom_col(show.legend = FALSE, width = 0.68, fill = "gray55", color = "black", linewidth = 0.3) +
  scale_y_log10(labels = label_number(accuracy = 0.01)) +
  coord_flip() +
  labs(
    x = NULL,
    y = "Average runtime (seconds, log scale)"
  ) +
  theme_pub()

save_pub(file.path(out_fig_app, "figA2_runtime_logscale.png"), pA2, width = 11, height = 7)

# APPENDIX FIGURE A3: matched sample composition
size_df <- data.frame(Method = colnames(sizes), value = colMeans(sizes, na.rm = TRUE))
# sizes columns: RAW(nt), RAW(nc), MAH(nt), ...
size_df <- tibble(
  Method = c("RAW", "RAW", "MAH", "MAH", "PSC", "PSC", "GEN", "GEN", "CEM", "CEM"),
  Group = rep(c("Treated", "Control"), 5),
  N = colMeans(sizes, na.rm = TRUE)
) %>% mutate(MethodLabel = recode(Method, !!!method_labels))

pA3 <- ggplot(size_df, aes(x = MethodLabel, y = N, fill = Group)) +
  geom_col(
    aes(linetype = Group),
    position = position_dodge(width = 0.72),
    width = 0.64,
    color = "black",
    linewidth = 0.3
  ) +
  coord_flip() +
  scale_fill_manual(values = c("Treated" = "gray35", "Control" = "white")) +
  scale_linetype_manual(values = c("Treated" = "solid", "Control" = "22")) +
  labs(
    x = NULL,
    y = "Average number of units",
    fill = "Group",
    linetype = "Group"
  ) +
  theme_pub() +
  guides(
    linetype = guide_legend(order = 2),
    fill = guide_legend(order = 1)
  )

save_pub(file.path(out_fig_app, "figA3_sample_size_composition.png"), pA3, width = 11, height = 7)

cat("Polished replication visuals complete.\n")

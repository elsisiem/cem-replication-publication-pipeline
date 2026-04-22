suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(forcats)
  library(scales)
})

source("99_figure_style.R")

root <- "c:/Users/hatem/Downloads/cem_replication_project"
out_fig_main <- file.path(root, "03_outputs", "figures", "main")
out_fig_app <- file.path(root, "03_outputs", "figures", "appendix")
out_data <- file.path(root, "03_outputs", "data")
out_tab_main <- file.path(root, "03_outputs", "tables", "main")

method_labels <- c(
  "RAW" = "Unmatched",
  "MAH" = "Mahalanobis",
  "PSC" = "Propensity Score",
  "GEN" = "Genetic Matching",
  "CEM" = "CEM (Unweighted)",
  "CEM.W" = "CEM (Weighted)"
)

main_perf <- read_csv(file.path(out_tab_main, "main_method_performance.csv"), show_col_types = FALSE)
att_long <- read_csv(file.path(out_data, "simulation_att_long.csv"), show_col_types = FALSE)
l1_long <- read_csv(file.path(out_data, "simulation_l1_long.csv"), show_col_types = FALSE)
runtime_long <- read_csv(file.path(out_data, "simulation_runtime_long.csv"), show_col_types = FALSE)
measerr_common <- read_csv(file.path(out_data, "measerr_common_units_long.csv"), show_col_types = FALSE)

if (!"MethodLabel" %in% names(main_perf) && "Method" %in% names(main_perf)) {
  main_perf <- main_perf %>% mutate(MethodLabel = recode(Method, !!!method_labels))
}

main_perf <- main_perf %>%
  mutate(MethodLabel = factor(MethodLabel, levels = method_order))

# MAIN FIGURE 7: absolute ATT error ECDF
plot7 <- att_long %>%
  mutate(MethodLabel = recode(method, !!!method_labels), AbsError = abs(att - 1000)) %>%
  filter(MethodLabel %in% c("Unmatched", "Mahalanobis", "Propensity Score", "Genetic Matching", "CEM (Weighted)"))

plot7_levels <- c("Unmatched", "Mahalanobis", "Propensity Score", "Genetic Matching", "CEM (Weighted)")
plot7 <- plot7 %>% mutate(MethodLabel = factor(MethodLabel, levels = plot7_levels))

p7 <- ggplot(
  plot7,
  aes(x = AbsError, linetype = MethodLabel)
) +
  stat_ecdf(color = "black", linewidth = 0.92, alpha = 1) +
  scale_linetype_manual(values = unname(method_linetype_map[plot7_levels])) +
  labs(
    x = "|Estimated ATT - true ATT|",
    y = "Empirical cumulative probability",
    linetype = "Method"
  ) +
  theme_pub()

save_pub(file.path(out_fig_main, "fig7_abs_error_ecdf.png"), p7, width = 11, height = 7)

# MAIN FIGURE 8: rank profile across criteria
rank_df <- main_perf %>%
  mutate(AbsBias = abs(Bias)) %>%
  dplyr::select(MethodLabel, RMSE, L1, Runtime, AbsBias)

rank_long <- rank_df %>%
  pivot_longer(cols = c(RMSE, L1, Runtime, AbsBias), names_to = "Metric", values_to = "Value") %>%
  group_by(Metric) %>%
  mutate(Rank = rank(Value, ties.method = "min")) %>%
  ungroup() %>%
  mutate(
    Metric = factor(Metric, levels = c("RMSE", "L1", "Runtime", "AbsBias")),
    MethodLabel = factor(MethodLabel, levels = method_order)
  )

p8 <- ggplot(rank_long, aes(x = Metric, y = Rank, group = MethodLabel, linetype = MethodLabel, shape = MethodLabel)) +
  geom_line(linewidth = 0.8, color = "black", alpha = 0.95) +
  geom_point(size = 2.8, color = "black", fill = "white", stroke = 0.8) +
  scale_linetype_manual(values = unname(method_linetype_map[method_order])) +
  scale_shape_manual(values = unname(method_shape_map[method_order])) +
  scale_y_reverse(breaks = seq_along(unique(rank_long$MethodLabel))) +
  labs(
    x = NULL,
    y = "Rank (1 = best)",
    linetype = "Method"
  ) +
  theme_pub() +
  guides(
    linetype = guide_legend(order = 1),
    shape = "none"
  )

save_pub(file.path(out_fig_main, "fig8_rank_profile.png"), p8, width = 11.5, height = 6.8)

# APPENDIX FIGURE A6: rank heatmap
heat_df <- rank_long %>% dplyr::select(MethodLabel, Metric, Rank)

pA6 <- ggplot(heat_df, aes(x = Metric, y = fct_reorder(MethodLabel, Rank, .fun = mean), fill = Rank)) +
  geom_tile(color = "white", linewidth = 0.35) +
  geom_text(aes(label = sprintf("%.0f", Rank)), color = "black", size = 3.7) +
  scale_fill_gradient(low = "white", high = "gray35") +
  labs(
    x = NULL,
    y = NULL,
    fill = "Rank"
  ) +
  theme_pub()

save_pub(file.path(out_fig_app, "figA6_method_rank_heatmap.png"), pA6, width = 9, height = 6)

# APPENDIX FIGURE A8: L1 distribution by method
plotA8 <- l1_long %>%
  mutate(MethodLabel = recode(method, !!!method_labels)) %>%
  filter(MethodLabel %in% c("Unmatched", "Mahalanobis", "Propensity Score", "Genetic Matching", "CEM (Unweighted)"))

pA8 <- ggplot(plotA8, aes(x = l1, y = fct_reorder(MethodLabel, l1, .fun = median), fill = MethodLabel)) +
  geom_boxplot(outlier.alpha = 0.05, linewidth = 0.34, color = "black", fill = "white", show.legend = FALSE) +
  labs(
    x = "L1 imbalance",
    y = NULL
  ) +
  theme_pub()

save_pub(file.path(out_fig_app, "figA8_l1_distribution_boxplot.png"), pA8, width = 11, height = 7)

# APPENDIX FIGURE A9: runtime distribution (log scale)
plotA9 <- runtime_long %>%
  mutate(MethodLabel = recode(method, !!!method_labels)) %>%
  filter(MethodLabel %in% c("Mahalanobis", "Propensity Score", "Genetic Matching", "CEM (Unweighted)"))

pA9 <- ggplot(plotA9, aes(x = seconds, y = fct_reorder(MethodLabel, seconds, .fun = median), fill = MethodLabel)) +
  geom_violin(trim = TRUE, alpha = 1, color = "black", linewidth = 0.35, fill = "white", show.legend = FALSE) +
  scale_x_log10(labels = label_number(accuracy = 0.01)) +
  labs(
    x = "Runtime (seconds, log scale)",
    y = NULL
  ) +
  theme_pub()

save_pub(file.path(out_fig_app, "figA9_runtime_distribution_violin.png"), pA9, width = 11, height = 7)

# APPENDIX FIGURE A10: measurement-error stability
plotA10 <- measerr_common %>%
  mutate(method = factor(method, levels = c("CEM(T)", "CEM(C)", "PSC(C)", "MAH(C)", "GEN(C)"))) %>%
  group_by(method) %>%
  summarise(
    mean_share = mean(common_units_share, na.rm = TRUE),
    q10 = quantile(common_units_share, probs = 0.10, na.rm = TRUE),
    q90 = quantile(common_units_share, probs = 0.90, na.rm = TRUE),
    .groups = "drop"
  )

pA10 <- ggplot(plotA10, aes(x = method, y = mean_share * 100)) +
  geom_col(fill = "white", color = "black", linewidth = 0.32, width = 0.64) +
  geom_errorbar(aes(ymin = q10 * 100, ymax = q90 * 100), width = 0.14, linewidth = 0.42) +
  geom_point(shape = 21, fill = "black", color = "black", size = 2.4) +
  labs(
    x = NULL,
    y = "Common matched units (%)"
  ) +
  theme_pub()

save_pub(file.path(out_fig_app, "figA10_measerr_stability.png"), pA10, width = 10, height = 6.6)

cat("Additional R figures complete.\n")

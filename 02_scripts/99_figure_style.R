suppressPackageStartupMessages({
  library(ggplot2)
  library(scales)
})

# Unified grayscale-first styling for all manuscript figures.
theme_pub <- function(base_size = 12) {
  theme_bw(base_size = base_size) +
    theme(
      plot.title = element_blank(),
      plot.subtitle = element_blank(),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "gray90", linewidth = 0.32),
      axis.title = element_text(face = "bold", color = "black"),
      axis.text = element_text(color = "black"),
      axis.ticks = element_line(color = "black", linewidth = 0.35),
      axis.line = element_line(color = "black", linewidth = 0.45),
      legend.position = "bottom",
      legend.title = element_text(face = "bold", color = "black"),
      legend.text = element_text(color = "black"),
      legend.key = element_rect(fill = "white", color = NA),
      strip.background = element_rect(fill = "gray95", color = "gray70", linewidth = 0.35),
      strip.text = element_text(face = "bold", color = "black")
    )
}

save_pub <- function(filename, plot, width, height, dpi = 420) {
  ggsave(
    filename = filename,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
}

method_shape_map <- c(
  "Unmatched" = 21,
  "Mahalanobis" = 22,
  "Propensity Score" = 24,
  "Genetic Matching" = 23,
  "CEM (Unweighted)" = 25,
  "CEM (Weighted)" = 4
)

method_linetype_map <- c(
  "Unmatched" = "dotdash",
  "Mahalanobis" = "dashed",
  "Propensity Score" = "longdash",
  "Genetic Matching" = "twodash",
  "CEM (Unweighted)" = "solid",
  "CEM (Weighted)" = "dotted"
)

method_order <- c(
  "Unmatched",
  "Mahalanobis",
  "Propensity Score",
  "Genetic Matching",
  "CEM (Unweighted)",
  "CEM (Weighted)"
)

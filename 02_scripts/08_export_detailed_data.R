suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
})

root <- "c:/Users/hatem/Downloads/cem_replication_project"
raw_dir <- file.path(root, "00_raw_dataverse")
out_data <- file.path(root, "03_outputs", "data")

# Detailed simulation outputs from cemsim-penta.rda
load(file.path(raw_dir, "cemsim-penta.rda"))

att_long <- as.data.frame(tmp) %>%
  mutate(sim = row_number()) %>%
  pivot_longer(cols = -sim, names_to = "method", values_to = "att")
write_csv(att_long, file.path(out_data, "simulation_att_long.csv"))

l1_long <- as.data.frame(ELLE1) %>%
  mutate(sim = row_number()) %>%
  pivot_longer(cols = -sim, names_to = "method", values_to = "l1")
write_csv(l1_long, file.path(out_data, "simulation_l1_long.csv"))

time_long <- as.data.frame(times) %>%
  mutate(sim = row_number()) %>%
  pivot_longer(cols = -sim, names_to = "method", values_to = "seconds")
write_csv(time_long, file.path(out_data, "simulation_runtime_long.csv"))

size_long <- as.data.frame(sizes)
size_long$sim <- seq_len(nrow(size_long))
size_long <- size_long %>%
  pivot_longer(cols = -sim, names_to = "key", values_to = "n") %>%
  mutate(
    method = sub("\\(.*$", "", key),
    group = ifelse(grepl("\\(nt\\)", key), "treated", "control")
  )
write_csv(size_long, file.path(out_data, "simulation_size_long.csv"))

# Measurement-error replication details from measerr2.rda
load(file.path(raw_dir, "measerr2.rda"))

com_long <- as.data.frame(com) %>%
  mutate(sim = row_number()) %>%
  pivot_longer(cols = -sim, names_to = "method", values_to = "common_units_share")
write_csv(com_long, file.path(out_data, "measerr_common_units_long.csv"))

time2_long <- as.data.frame(times) %>%
  mutate(sim = row_number()) %>%
  pivot_longer(cols = -sim, names_to = "method", values_to = "seconds")
write_csv(time2_long, file.path(out_data, "measerr_runtime_long.csv"))

cat("Detailed data export complete.\n")

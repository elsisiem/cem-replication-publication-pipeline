suppressPackageStartupMessages({
  library(xtable)
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(tidyr)
})

root <- "c:/Users/hatem/Downloads/cem_replication_project"
raw_dir <- file.path(root, "00_raw_dataverse")
out_tab_main <- file.path(root, "03_outputs", "tables", "main")
out_tab_app <- file.path(root, "03_outputs", "tables", "appendix")

# Build Table 1 from measerr2.rda (as in measerr.R)
load(file.path(raw_dir, "measerr2.rda"))
# Expected: objects 'times' and 'com'
if (!exists("times") || !exists("com")) stop("measerr2.rda missing expected objects")

tm <- colMeans(times)
cm <- sprintf("%.1f", colMeans(com) * 100)
tab1 <- rbind(cm, sprintf("%.2f", c(tm[1], tm)))
colnames(tab1) <- c("CEM(K_T)", "CEM(K_C)", "PSC(K_C)", "MAH(K_C)", "GEN(K_C)")
rownames(tab1) <- c("Percent Common Units", "Seconds")

write.csv(as.data.frame(tab1), file.path(out_tab_app, "table1_reproduced.csv"), row.names = TRUE)

# Build Table 2 from cemsim-penta.rda (as in lalonde-sim.R)
load(file.path(raw_dir, "cemsim-penta.rda"))
# Expected: tmp, sizes, times, ELLE1
needed <- c("tmp", "sizes", "times", "ELLE1")
if (!all(needed %in% ls())) stop("cemsim-penta.rda missing expected objects")

buf <- colMeans(tmp, na.rm = TRUE) - 1000
buf <- rbind(buf, apply(tmp, 2, function(x) sd(x, na.rm = TRUE)))
buf <- rbind(buf, sqrt(colMeans((tmp - 1000)^2, na.rm = TRUE)))
rownames(buf) <- c("BIAS", "SD", "RMSE")
buf <- t(buf)
tt <- colMeans(sizes, na.rm = TRUE)
tab2 <- cbind(buf[-5, ], matrix(as.integer(tt), 5, 2, byrow = TRUE))
colnames(tab2)[4:5] <- c("treated", "controls")
rownames(tab2)[5] <- "CEM"
tab2 <- cbind(tab2, c(0, colMeans(times)), colMeans(ELLE1))
colnames(tab2) <- c(colnames(tab2)[-(4:7)], "Treated", "Controls", "Seconds", "L1")

write.csv(as.data.frame(tab2), file.path(out_tab_main, "table2_reproduced.csv"), row.names = TRUE)

cat("Build complete from provided .rda files.\n")

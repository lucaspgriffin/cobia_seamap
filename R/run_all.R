# Whole pipeline. First run downloads a few hundred MB.
source("R/01_download_seamap.R")
source("R/02_build_data.R")
source("R/03_figures.R")
sink(file.path(dir_log, "qc.txt")); source("R/04_qc.R"); sink()
file.show(file.path(dir_log, "qc.txt"))

# Packages, paths and constants. Sourced by everything else.

suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(terra)
  library(marmap)
  library(patchwork)
  library(rnaturalearth)
})

dir_raw     <- "data/raw"
dir_seamap  <- file.path(dir_raw, "seamap")
dir_derived <- "data/derived"
dir_fig     <- "output/figures"
dir_log     <- "output/logs"
for (d in c(dir_seamap, dir_derived, dir_fig, dir_log)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

# Study box: US Gulf, shelf and slope.
BOX     <- list(lon = c(-98, -80), lat = c(18, 31))
MAP_LAT <- c(23.5, 31)      # map extent, trimmed north of the Yucatan
SHELF_M <- 200              # shelf cut-off, metres
PEAK    <- c(6, 7)          # spawning-season months
SERIES  <- 1982:2016        # June-July plankton sampling ends with the 2016 summer trawl survey

# Regions used for the two-shelf comparison.
REGIONS <- tribble(
  ~region,                  ~lat1, ~lat2, ~lon1, ~lon2,
  "Texas-Louisiana shelf",   26,    30.5,  -98,   -88,
  "West Florida shelf",      25,    30.5,  -88,   -82
)

# SEAMAP code lookups (Section II of the survey documentation).
GEAR <- c("01" = "Bongo", "17" = "Bongo", "11" = "Bongo", "14" = "Bongo", "05" = "Bongo",
          "12" = "Bongo", "13" = "Bongo", "15" = "Bongo",
          "03" = "Neuston", "08" = "Neuston",
          "07" = "Tucker trawl", "09" = "MOCNESS", "02" = "Ring", "04" = "Ring",
          "16" = "Methot", "06" = "Other")
SORTED  <- c("1", "2", "4", "D")                     # SORT_IST: sample was sorted
ALIQ_MULT <- c("1/1" = 1, "1/2" = 2, "1/4" = 4, "1/8" = 8)
FATHOM  <- 1.8288                                    # DEPTH_SSTA is in fathoms

# Size classes. Descriptive only, round numbers either side of the tertiles (6.8 and 12.7 mm).
# Not stages: nobody has examined these specimens, and there is no age-length relation for wild
# cobia larvae, so length cannot be turned into age.
SIZE_LEVELS <- c("Small (<5 mm)", "Medium (5-15 mm)", "Large (>15 mm)")
SIZE_COLS   <- c("Small (<5 mm)" = "#D55E00", "Medium (5-15 mm)" = "#009E73", "Large (>15 mm)" = "#0072B2")
size_class  <- function(mm) factor(case_when(mm <  5 ~ SIZE_LEVELS[1],
                                             mm <= 15 ~ SIZE_LEVELS[2],
                                             TRUE     ~ SIZE_LEVELS[3]), levels = SIZE_LEVELS)

DWH <- tibble(lon = -88.3660, lat = 28.7366)         # Deepwater Horizon wellhead

theme_set(theme_bw(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom",
        legend.key.height = unit(10, "pt")))

read_seamap <- function(f) {
  read_csv(file.path(dir_seamap, f), col_types = cols(.default = col_character()),
           show_col_types = FALSE, name_repair = "minimal") %>%
    rename_with(~ str_remove(.x, "^﻿"))         # first header carries a BOM
}

in_box <- function(d, lat = "lat", lon = "lon") {
  d[[lon]] >= BOX$lon[1] & d[[lon]] <= BOX$lon[2] &
  d[[lat]] >= BOX$lat[1] & d[[lat]] <= BOX$lat[2]
}

tag_region <- function(d) {
  d$region <- NA_character_
  for (i in seq_len(nrow(REGIONS))) {
    r <- REGIONS[i, ]
    hit <- d$lat >= r$lat1 & d$lat <= r$lat2 & d$lon >= r$lon1 & d$lon < r$lon2 &
           d$sta_depth_m > 0 & d$sta_depth_m <= SHELF_M
    d$region[hit & is.na(d$region)] <- r$region
  }
  d
}

save_fig <- function(p, name, width, height, dpi = 360) {
  ggsave(file.path(dir_fig, paste0(name, ".png")), p, width = width, height = height,
         dpi = dpi, bg = "white")
  ggsave(file.path(dir_fig, paste0(name, ".tiff")), p, width = width, height = height,
         dpi = dpi, bg = "white", compression = "lzw")
}

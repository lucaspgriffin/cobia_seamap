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
for (d in c(dir_seamap, dir_derived, file.path(dir_derived, "panels"), dir_fig, dir_log)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

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

# Basemap pieces, built once and cached: analyses that map share them.
basemap <- function() {
  f <- file.path(dir_derived, "basemap.rds")
  if (file.exists(f)) return(readRDS(f))
  b <- getNOAA.bathy(BOX$lon[1], BOX$lon[2], BOX$lat[1], BOX$lat[2], resolution = 1, keep = TRUE,
                     path = dir_derived)
  out <- list(
    bathy = as.xyz(b) %>% set_names(c("lon", "lat", "z")) %>% filter(z <= 0),
    iso   = as.contour(rast(as.xyz(b), type = "xyz", crs = "EPSG:4326"),
                       levels = c(-200, -1000, -2000, -3000)) %>%
            st_as_sf() %>% st_set_crs(4326) %>% mutate(depth_m = -level),
    land  = ne_countries(scale = "medium", returnclass = "sf") %>% st_make_valid() %>%
            st_crop(st_bbox(c(xmin = BOX$lon[1], xmax = BOX$lon[2],
                              ymin = BOX$lat[1], ymax = BOX$lat[2]), crs = st_crs(4326))))
  saveRDS(out, f); out
}

map_frame <- list(coord_sf(xlim = BOX$lon, ylim = MAP_LAT, expand = FALSE), labs(x = NULL, y = NULL),
                  theme(panel.grid = element_blank()))

# Derived tables the analyses all start from.
load_data <- function() {
  rec <- read_csv(file.path(dir_derived, "cobia_records.csv"), show_col_types = FALSE) %>%
    mutate(size_class = factor(size_class, levels = SIZE_LEVELS))
  list(records = rec,
       gulf    = rec %>% filter(in_box(.)),
       # numerator for any rate: same gears and sorted status as the effort pool
       rates   = rec %>% filter(in_box(.), gear %in% c("Bongo", "Neuston"), sort_ist %in% SORTED),
       lengths = read_csv(file.path(dir_derived, "lengths.csv"), show_col_types = FALSE) %>%
                   mutate(size = factor(size, levels = SIZE_LEVELS)),
       effort  = read_csv(file.path(dir_derived, "effort.csv"), show_col_types = FALSE))
}

# Each analysis stashes its panel so 08 can assemble without recomputing.
save_panel <- function(p, name) saveRDS(p, file.path(dir_derived, "panels", paste0(name, ".rds")))
load_panel <- function(name) readRDS(file.path(dir_derived, "panels", paste0(name, ".rds")))

# main_  figures that carry a result
# explore_  working figures and checks
save_fig <- function(p, name, width, height, dpi = 300) {
  ggsave(file.path(dir_fig, paste0(name, ".png")), p, width = width, height = height,
         dpi = dpi, bg = "white")
  invisible(file.path(dir_fig, paste0(name, ".png")))
}

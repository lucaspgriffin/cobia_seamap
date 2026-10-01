# The results figure. Six panels:
#   A  distribution, by the size class holding most of the tow
#   B  June-July sampling effort per cell
#   C  June-July catch rate per cell
#   D  catch rate by month, split by size class
#   E  the two shelves compared within June-July
#   F  larval length against station depth
#
# Two rules run through it. Rates always divide by effort from the same pool as the numerator, and
# place is never compared on all-year effort: the survey does not sample the same areas in every
# month, so an annual map reads partly as where the survey went.

source("R/00_setup.R")

records <- read_csv(file.path(dir_derived, "cobia_records.csv"), show_col_types = FALSE) %>%
  mutate(size_class = factor(size_class, levels = SIZE_LEVELS))
lengths <- read_csv(file.path(dir_derived, "lengths.csv"), show_col_types = FALSE) %>%
  mutate(size = factor(size, levels = SIZE_LEVELS))
effort  <- read_csv(file.path(dir_derived, "effort.csv"), show_col_types = FALSE)

gulf <- records %>% filter(in_box(.))
# Numerator for any rate: same gears and sorted status as the effort pool.
rate_recs <- gulf %>% filter(gear %in% c("Bongo", "Neuston"), sort_ist %in% SORTED)
message(sprintf("off-gear or unsorted, excluded from rates: %d records, %.0f larvae",
                nrow(gulf) - nrow(rate_recs), sum(gulf$n_total) - sum(rate_recs$n_total)))

# ---- basemap -----------------------------------------------------------------
bathy <- getNOAA.bathy(BOX$lon[1], BOX$lon[2], BOX$lat[1], BOX$lat[2], resolution = 1, keep = TRUE,
                       path = dir_derived)
bathy_df <- as.xyz(bathy) %>% set_names(c("lon", "lat", "z")) %>% filter(z <= 0)
iso <- as.contour(rast(as.xyz(bathy), type = "xyz", crs = "EPSG:4326"),
                  levels = c(-200, -1000, -2000, -3000)) %>%
  st_as_sf() %>% st_set_crs(4326) %>% mutate(depth_m = -level)
land <- ne_countries(scale = "medium", returnclass = "sf") %>% st_make_valid() %>%
  st_crop(st_bbox(c(xmin = BOX$lon[1], xmax = BOX$lon[2], ymin = BOX$lat[1], ymax = BOX$lat[2]),
                  crs = st_crs(4326)))
map_frame <- list(coord_sf(xlim = BOX$lon, ylim = MAP_LAT, expand = FALSE), labs(x = NULL, y = NULL),
                  theme(panel.grid = element_blank()))

# ---- A: distribution ---------------------------------------------------------
pA <- ggplot() +
  geom_raster(data = bathy_df, aes(lon, lat, fill = z), interpolate = TRUE) +
  scale_fill_gradient(low = "#1f3d6b", high = "#dbe9f6", name = "Depth (m)",
                      labels = function(x) -x, guide = guide_colourbar(order = 3)) +
  geom_sf(data = filter(iso, depth_m == 200), colour = "grey20", linewidth = 0.35) +
  geom_sf(data = filter(iso, depth_m > 200), colour = "grey35", linewidth = 0.2, linetype = "dotted") +
  geom_sf(data = land, fill = "grey85", colour = "grey40", linewidth = 0.2) +
  geom_point(data = DWH, aes(lon, lat), shape = 8, size = 2.6, stroke = 0.9) +
  annotate("text", x = DWH$lon + 0.3, y = DWH$lat - 0.45, label = "DWH", size = 2.9, hjust = 0) +
  # smallest drawn last so they are not buried under the commoner medium tows
  geom_point(data = gulf %>% filter(!is.na(size_class)) %>%
               arrange(desc(as.integer(size_class)), desc(n_total)),
             aes(lon, lat, size = n_total, colour = size_class), alpha = 0.75) +
  scale_colour_manual(values = SIZE_COLS, name = "Most of the tow", drop = FALSE) +
  # catches are skewed: median tow holds one larva, the largest held 232
  scale_size_binned(breaks = c(1, 5, 20, 100), range = c(1.2, 6.5), name = "Larvae per tow",
                    nice.breaks = FALSE) +
  guides(colour = guide_legend(order = 1, override.aes = list(size = 3.6, alpha = 1)),
         size = guide_bins(order = 2, override.aes = list(colour = "grey45"), axis = FALSE)) +
  map_frame +
  theme(panel.background = element_rect(fill = "#dbe9f6"), legend.box = "horizontal",
        legend.box.just = "top", legend.spacing.x = unit(10, "pt"))

# ---- B, C: June-July effort and catch rate by cell ---------------------------
CELL <- 0.5
cell <- function(d) mutate(d, cx = floor(lon / CELL) * CELL + CELL / 2,
                              cy = floor(lat / CELL) * CELL + CELL / 2)
eff_cell <- effort %>% filter(month %in% PEAK) %>% cell() %>% count(cx, cy, name = "n_tows")
cob_cell <- rate_recs %>% filter(month %in% PEAK) %>% cell() %>%
  group_by(cx, cy) %>% summarise(n_larvae = sum(n_total), .groups = "drop")
cells <- eff_cell %>% left_join(cob_cell, by = c("cx", "cy")) %>%
  mutate(n_larvae = coalesce(n_larvae, 0), per_100 = 100 * n_larvae / n_tows,
         searched = n_tows >= 10)
message(sprintf("cells with >=10 June-July tows: %d; of those with no cobia: %d",
                sum(cells$searched), sum(cells$searched & cells$n_larvae == 0)))

cell_frame <- list(geom_sf(data = filter(iso, depth_m == 200), colour = "grey35", linewidth = 0.3),
                   geom_sf(data = land, fill = "grey85", colour = "grey40", linewidth = 0.2),
                   map_frame, theme(panel.background = element_rect(fill = "white")))
pB <- ggplot() + geom_tile(data = cells, aes(cx, cy, fill = n_tows)) +
  scale_fill_viridis_c(trans = "log10", option = "mako", direction = -1,
                       name = "Sorted June-July\ndeployments", breaks = c(1, 10, 100)) +
  cell_frame + ggtitle("June-July sampling")
pC <- ggplot() +
  geom_tile(data = filter(cells, searched, n_larvae == 0), aes(cx, cy), fill = "grey88") +
  geom_tile(data = filter(cells, n_larvae > 0), aes(cx, cy, fill = per_100)) +
  scale_fill_viridis_c(trans = "sqrt", option = "inferno", direction = -1,
                       name = "Cobia larvae per\n100 deployments", breaks = c(10, 100, 300)) +
  cell_frame + ggtitle("June-July catch rate")

# ---- D: month, split by size class -------------------------------------------
# Shelf stations and 1982-2016 only, so months are compared on one footprint and one year range.
shelf_eff <- effort %>% filter(sta_depth_m > 0, sta_depth_m <= SHELF_M, year %in% SERIES) %>%
  count(month, name = "n_tows")
shelf_rec <- rate_recs %>% filter(sta_depth_m > 0, sta_depth_m <= SHELF_M, year %in% SERIES)
cpue <- shelf_rec %>% count(month, wt = n_total, name = "n_larvae") %>%
  complete(month = 1:12, fill = list(n_larvae = 0)) %>%
  left_join(shelf_eff, by = "month") %>%
  mutate(per_100 = if_else(n_tows > 0, 100 * n_larvae / n_tows, NA_real_),
         month_lab = factor(month.abb[month], levels = month.abb))
write_csv(cpue, file.path(dir_derived, "cpue_by_month.csv"), na = "")

# Two thirds of larvae were measured, so split the total by the measured composition of that month.
mix <- lengths %>% inner_join(select(shelf_rec, v_c_p_s_cat, month), by = "v_c_p_s_cat") %>%
  count(month, size, name = "n_meas") %>%
  group_by(month) %>% mutate(share = n_meas / sum(n_meas)) %>% ungroup()
pD <- cpue %>% select(month, month_lab, per_100) %>% inner_join(mix, by = "month") %>%
  ggplot(aes(month_lab, per_100 * share, fill = size)) +
  geom_col(colour = "grey20", linewidth = 0.2) +
  scale_fill_manual(values = SIZE_COLS, name = NULL, drop = FALSE,
                    guide = guide_legend(reverse = TRUE)) +
  scale_x_discrete(labels = substr(month.abb, 1, 1), drop = FALSE) +
  theme(legend.position = "right", legend.key.size = unit(8, "pt"),
        legend.text = element_text(size = 7)) +
  labs(x = NULL, y = "Cobia larvae per 100 sorted\nshelf tows, 1982-2016")

# ---- E: the two shelves, within June-July ------------------------------------
# Bootstrap over tows: larvae cluster within a tow, so a Poisson interval would be far too tight.
set.seed(7)
boot_ci <- function(x, n = 2000) quantile(replicate(n, 100 * mean(sample(x, replace = TRUE))),
                                          c(0.025, 0.975))
tow_catch <- shelf_rec %>% filter(month %in% PEAK) %>%
  mutate(gear_class = if_else(gear == "Neuston", "Neuston", "Bongo")) %>%
  group_by(v_c_p, gear_class) %>% summarise(n = sum(n_total), .groups = "drop")
# A deployment is a station-and-gear pair, which is what the denominator counts. Joining on station
# alone would give each tow's larvae to both the bongo and the neuston row.
reg <- effort %>% filter(!is.na(region), month %in% PEAK, year %in% SERIES) %>%
  select(v_c_p, gear, region) %>%
  left_join(tow_catch, by = c("v_c_p", "gear" = "gear_class")) %>%
  mutate(n = coalesce(n, 0)) %>%
  group_by(region) %>%
  summarise(tows = n(), larvae = sum(n), rate = 100 * mean(n),
            lo = boot_ci(n)[1], hi = boot_ci(n)[2], .groups = "drop")
write_csv(reg, file.path(dir_derived, "shelf_comparison.csv"))
print(reg)

pE <- ggplot(reg, aes(reorder(str_remove(region, " shelf"), -rate), rate)) +
  geom_col(fill = "#0072B2", colour = "grey20", linewidth = 0.2, width = 0.6) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.15, linewidth = 0.4) +
  geom_text(aes(y = hi, label = sprintf("%d tows\n%.0f larvae", tows, larvae)),
            vjust = -0.3, size = 2.5, lineheight = 0.95) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.28))) +
  labs(x = NULL, y = "Larvae per 100 shelf tows,\nJune-July 1982-2016")

# ---- F: length against depth -------------------------------------------------
pF <- lengths %>%
  inner_join(select(gulf, v_c_p_s_cat, sta_depth_m), by = "v_c_p_s_cat") %>%
  filter(sta_depth_m > 0) %>%
  ggplot(aes(sta_depth_m, length_mm, colour = size)) +
  geom_point(alpha = 0.45, size = 1.4) +
  scale_colour_manual(values = SIZE_COLS, guide = "none") +
  scale_x_log10(breaks = c(10, 30, 100, 300, 1000, 3000)) +
  geom_vline(xintercept = SHELF_M, linetype = "dashed", colour = "grey40") +
  labs(x = "Station depth (m, log scale)", y = "Larval length (mm)")

title_small <- theme(plot.title = element_text(size = 8.5, face = "plain"))
fig <- pA / ((pB + title_small) | (pC + title_small)) / (pD | pE | pF) +
  plot_layout(heights = c(1.9, 1.5, 1.05)) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(size = 11, face = "bold"))
save_fig(fig, "cobia_results", width = 9.5, height = 11.5)
message("wrote ", file.path(dir_fig, "cobia_results.png"))

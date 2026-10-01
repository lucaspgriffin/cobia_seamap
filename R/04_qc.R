# Checks. Each prints PASS, FAIL or FLAG with the numbers behind it.
# FLAG marks a limitation worth knowing, not an error.

source("R/00_setup.R")

records <- read_csv(file.path(dir_derived, "cobia_records.csv"), show_col_types = FALSE)
lengths <- read_csv(file.path(dir_derived, "lengths.csv"), show_col_types = FALSE)
effort  <- read_csv(file.path(dir_derived, "effort.csv"), show_col_types = FALSE)
gulf    <- records %>% filter(in_box(.))

fails <- character()
say <- function(ok, label, detail = "") {
  tag <- if (is.na(ok)) "FLAG" else if (ok) "PASS" else "FAIL"
  if (!is.na(ok) && !ok) fails <<- c(fails, label)
  cat(sprintf("  [%s] %-54s %s\n", tag, label, detail))
}

cat("\n-- extraction --\n")
isarwk <- read_seamap("ISARWK.csv")
loose <- isarwk %>% filter(str_detect(toupper(TAXON), "RACHYCENTR")) %>% distinct(TAXON)
tight <- isarwk %>% filter(str_detect(toupper(TAXON), "^RACHYCENTR")) %>% distinct(TAXON)
say(nrow(loose) == nrow(tight), "taxon filter admits no partial-name matches",
    paste(tight$TAXON, collapse = "; "))
raw <- isarwk %>% filter(str_detect(toupper(TAXON), "^RACHYCENTR")) %>%
  mutate(n = (coalesce(as.numeric(MEAS), 0) + coalesce(as.numeric(NOT_MEAS), 0)) *
             coalesce(ALIQ_MULT[ALIQUOT], 1))
say(nrow(raw) == nrow(records), "record count matches the raw table", sprintf("%d", nrow(records)))
say(abs(sum(raw$n) - sum(records$n_total)) < 1e-6, "aliquot-corrected larva count matches",
    sprintf("%.0f larvae, %d records sub-sampled", sum(records$n_total), sum(records$aliquot != "1/1")))
say(all(raw$ALIQUOT %in% names(ALIQ_MULT)), "every aliquot value is recognised",
    paste(sort(unique(raw$ALIQUOT)), collapse = ", "))
say(!any(duplicated(records$v_c_p_s_cat)), "catalogue keys are unique")

cat("\n-- station join --\n")
say(all(!is.na(records$lat)), "every record joined to a station")
say(all(records$lat > 17 & records$lat < 40), "latitudes plausible",
    sprintf("%.1f to %.1f N", min(records$lat), max(records$lat)))
say(all(records$date >= as.Date("1982-01-01") & records$date <= Sys.Date()), "dates in range",
    sprintf("%s to %s", min(records$date), max(records$date)))
say(NA, "records outside the study box", sprintf("%d", nrow(records) - nrow(gulf)))

cat("\n-- numerator against denominator --\n")
off <- gulf %>% filter(!gear %in% c("Bongo", "Neuston")) %>% count(gear, wt = n_total)
say(NA, "cobia taken by gear outside the effort pool",
    if (nrow(off) == 0) "none" else sprintf("%.0f larvae in %s; excluded from rates",
                                            sum(off$n), paste(off$gear, collapse = ", ")))
say(NA, "cobia tows not flagged sorted", sprintf("%d; excluded from rates",
                                                 sum(!gulf$sort_ist %in% SORTED)))
cpue <- read_csv(file.path(dir_derived, "cpue_by_month.csv"), show_col_types = FALSE)
chk <- gulf %>% filter(gear %in% c("Bongo", "Neuston"), sort_ist %in% SORTED,
                       sta_depth_m > 0, sta_depth_m <= SHELF_M, year %in% SERIES)
say(abs(sum(cpue$n_larvae) - sum(chk$n_total)) < 1e-6,
    "rate numerator reproduces under all four filters",
    sprintf("%.0f in the rates, %.0f in the box", sum(cpue$n_larvae), sum(gulf$n_total)))

cat("\n-- lengths --\n")
say(NA, "measurement coverage",
    sprintf("%d of %.0f larvae (%.0f%%)", sum(gulf$n_meas, na.rm = TRUE), sum(gulf$n_total),
            100 * sum(gulf$n_meas, na.rm = TRUE) / sum(gulf$n_total)))
big <- gulf %>% filter(n_total > 10)
say(NA, "large tows with under half measured",
    sprintf("%d of %d tows holding >10 larvae", sum(big$n_meas / big$n_total < 0.5, na.rm = TRUE), nrow(big)))
say(all(lengths$length_mm > 1 & lengths$length_mm < 70), "lengths plausible",
    sprintf("%.1f to %.1f mm", min(lengths$length_mm), max(lengths$length_mm)))
say(all(gulf$n_meas <= gulf$n_total, na.rm = TRUE), "measured never exceeds counted")
say(all(gulf$n_small + gulf$n_mid + gulf$n_big == gulf$n_meas, na.rm = TRUE),
    "size-class counts sum to the measured total")

cat("\n-- depth --\n")
bathy_r <- rast(as.xyz(getNOAA.bathy(BOX$lon[1], BOX$lon[2], BOX$lat[1], BOX$lat[2],
                                     resolution = 1, keep = TRUE, path = dir_derived)),
                type = "xyz", crs = "EPSG:4326")
gulf$etopo_m <- -terra::extract(bathy_r, as.matrix(gulf[, c("lon", "lat")]))[, 1]
cmp <- gulf %>% filter(sta_depth_m > 0, etopo_m > 0)
r <- cor(log10(cmp$sta_depth_m), log10(cmp$etopo_m))
say(r > 0.9, "recorded depth agrees with ETOPO", sprintf("r = %.3f on log depth, n = %d", r, nrow(cmp)))

cat("\n-- confounding --\n")
# Does the seasonal peak survive on one fixed area, and the regional difference within one season?
tx <- effort %>% filter(region == "Texas-Louisiana shelf", year %in% SERIES) %>% count(month, name = "tows")
txl <- gulf %>% filter(region == "Texas-Louisiana shelf", year %in% SERIES,
                       gear %in% c("Bongo", "Neuston"), sort_ist %in% SORTED) %>%
  count(month, wt = n_total, name = "larvae")
txr <- left_join(tx, txl, by = "month") %>% mutate(rate = 100 * coalesce(larvae, 0) / tows)
pk <- min(txr$rate[txr$month %in% PEAK]); sep <- txr$rate[txr$month == 9]
say(pk > 2 * sep, "June-July peak survives on one fixed area",
    sprintf("TX-LA shelf Jun %.1f, Jul %.1f, Sep %.1f",
            txr$rate[txr$month == 6], txr$rate[txr$month == 7], sep))

# June-July sampling is piggybacked on the shrimp trawl survey, which works daylight hours, so the
# peak has to show up within day tows and within night tows, not only pooled.
tod_e <- effort %>% filter(!is.na(night), sta_depth_m > 0, sta_depth_m <= SHELF_M, year %in% SERIES) %>%
  count(month, night, name = "tows")
tod_l <- gulf %>% filter(!is.na(night), sta_depth_m > 0, sta_depth_m <= SHELF_M, year %in% SERIES,
                         gear %in% c("Bongo", "Neuston"), sort_ist %in% SORTED) %>%
  count(month, night, wt = n_total, name = "larvae")
tod <- left_join(tod_e, tod_l, by = c("month", "night")) %>%
  mutate(rate = 100 * coalesce(larvae, 0) / tows)
pk_d <- max(tod$rate[tod$month %in% PEAK & !tod$night]); sp_d <- tod$rate[tod$month == 9 & !tod$night]
pk_n <- max(tod$rate[tod$month %in% PEAK & tod$night]);  sp_n <- tod$rate[tod$month == 9 & tod$night]
say(pk_d > 3 * sp_d && pk_n > 3 * sp_n, "peak present in day and night tows separately",
    sprintf("day %.1f vs Sep %.1f; night %.1f vs Sep %.1f", pk_d, sp_d, pk_n, sp_n))

wf <- effort %>% filter(!is.na(region), sta_depth_m <= SHELF_M) %>%
  group_by(region) %>% summarise(pct = 100 * mean(month %in% PEAK), .groups = "drop")
say(NA, "share of shelf tows taken in June-July",
    paste(sprintf("%s %.0f%%", str_remove(wf$region, " shelf"), wf$pct), collapse = "; "))

# A tenfold rise in catch rate across a documented protocol change is not a trend to trust.
era <- gulf %>% filter(!is.na(night), month %in% PEAK, sta_depth_m <= SHELF_M, year %in% SERIES,
                       gear %in% c("Bongo", "Neuston"), sort_ist %in% SORTED) %>%
  mutate(era = if_else(year < 1995, "pre", "post")) %>% count(era, night, wt = n_total, name = "larvae")
era_e <- effort %>% filter(!is.na(night), month %in% PEAK, sta_depth_m <= SHELF_M, year %in% SERIES) %>%
  mutate(era = if_else(year < 1995, "pre", "post")) %>% count(era, night, name = "tows")
er <- left_join(era_e, era, by = c("era", "night")) %>% mutate(rate = 100 * coalesce(larvae, 0) / tows)
say(NA, "daytime rate across the 1995 protocol change",
    sprintf("day x%.0f, night x%.1f -- no interannual trend plotted",
            er$rate[er$era == "post" & !er$night] / er$rate[er$era == "pre" & !er$night],
            er$rate[er$era == "post" & er$night] / er$rate[er$era == "pre" & er$night]))

say(NA, "June-July series ends before the records do",
    sprintf("last year with >=20 June-July shelf tows: %d; records to %d",
            max(effort %>% filter(month %in% PEAK, sta_depth_m <= SHELF_M) %>%
                  count(year) %>% filter(n >= 20) %>% pull(year)),
            max(gulf$year)))

cat("\n")
if (length(fails)) { cat("FAILED:\n"); for (f in fails) cat("  -", f, "\n") } else
  cat("All hard checks passed. FLAG lines are limitations, not errors.\n")
cat("\n")

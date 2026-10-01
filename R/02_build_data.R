# Build the two things the analysis needs: cobia catch records, and sampling effort to divide by.
#
# Effort is one deployment per station per gear class, restricted to sorted bongo and neuston
# samples. Only sorted samples could have yielded an identified larva, and the catch rates compare
# cobia against that pool, so anything taken by other gear is dropped from the rates (it is kept in
# the records file and still mapped).

source("R/00_setup.R")

# ---- stations ----------------------------------------------------------------
starec <- read_seamap("STAREC.csv") %>%
  transmute(v_c_p    = V_C_P,
            date     = as.Date(substr(MO_DAY_YR, 1, 10)),
            time_mil = TIME_MIL,
            gears    = GEARS,
            lat = as.numeric(S_LATD) + as.numeric(S_LATM) / 60,
            lon = (as.numeric(S_LOND) + as.numeric(S_LONM) / 60) * if_else(S_LONH == "W", -1, 1),
            sta_depth_m = as.numeric(DEPTH_SSTA) * FATHOM) %>%
  filter(!is.na(date), !is.na(lat), !is.na(lon)) %>%
  arrange(v_c_p, date) %>%
  distinct(v_c_p, .keep_all = TRUE)        # V_C_P should be unique; keep the first if not

# ---- plankton samples --------------------------------------------------------
istrwk <- read_seamap("ISTRWK.csv") %>%
  transmute(v_c_p = substr(V_C_P_S, 1, 10), v_c_p_s = V_C_P_S,
            gear = GEAR[GEAR_ICD], sort_ist = SORT_IST,
            vol_filt_m3 = as.numeric(VOL_FILT))

# A bongo pair or a double neuston frame is one deployment.
effort <- istrwk %>%
  filter(gear %in% c("Bongo", "Neuston"), sort_ist %in% SORTED) %>%
  distinct(v_c_p, gear) %>%
  inner_join(starec, by = "v_c_p") %>%
  filter(in_box(.)) %>%
  mutate(year = year(date), month = month(date),
         hour = suppressWarnings(as.integer(substr(str_pad(time_mil, 4, "left", "0"), 1, 2))),
         night = if_else(is.na(hour) | hour > 23, NA, hour >= 20 | hour < 6)) %>%
  tag_region()
write_csv(effort, file.path(dir_derived, "effort.csv"), na = "")

# ---- cobia catch -------------------------------------------------------------
# Anchor the match so Poromitra megalops and similar do not come along.
catch <- read_seamap("ISARWK.csv") %>%
  filter(str_detect(toupper(TAXON), "^RACHYCENTR")) %>%
  transmute(v_c_p = substr(V_C_P_S, 1, 10), v_c_p_s = V_C_P_S, v_c_p_s_cat = V_C_P_S_CAT,
            taxon = TAXON, aliquot = ALIQUOT, sort_isa = SORT_ISA,
            n_sorted = coalesce(as.numeric(MEAS), 0) + coalesce(as.numeric(NOT_MEAS), 0),
            n_total  = n_sorted * coalesce(ALIQ_MULT[ALIQUOT], 1))   # undo the sub-sample

# ---- individual lengths ------------------------------------------------------
lengths <- read_seamap("ILFRWK.csv") %>%
  filter(V_C_P_S_CAT %in% catch$v_c_p_s_cat) %>%
  transmute(v_c_p_s_cat = V_C_P_S_CAT, length_mm = as.numeric(LENGTH)) %>%
  filter(!is.na(length_mm)) %>%
  mutate(size = size_class(length_mm))
write_csv(lengths, file.path(dir_derived, "lengths.csv"))

# Per record: how many of each class, and which class holds most of the tow. Classified one larva
# at a time; a tow median buries mixed catches.
by_rec <- lengths %>%
  group_by(v_c_p_s_cat) %>%
  summarise(n_meas = n(), len_med = median(length_mm), len_min = min(length_mm),
            n_small = sum(size == SIZE_LEVELS[1]),
            n_mid   = sum(size == SIZE_LEVELS[2]),
            n_big   = sum(size == SIZE_LEVELS[3]), .groups = "drop") %>%
  mutate(has_small = n_small > 0,
         size_class = factor(SIZE_LEVELS[max.col(cbind(n_small, n_mid, n_big), ties.method = "first")],
                             levels = SIZE_LEVELS))

records <- catch %>%
  left_join(by_rec, by = "v_c_p_s_cat") %>%
  left_join(istrwk %>% select(v_c_p_s, gear, sort_ist, vol_filt_m3), by = "v_c_p_s") %>%
  inner_join(starec, by = "v_c_p") %>%
  mutate(year = year(date), month = month(date),
         hour = suppressWarnings(as.integer(substr(str_pad(time_mil, 4, "left", "0"), 1, 2))),
         night = if_else(is.na(hour) | hour > 23, NA, hour >= 20 | hour < 6),
         has_small = coalesce(has_small, FALSE)) %>%
  tag_region()
write_csv(records, file.path(dir_derived, "cobia_records.csv"), na = "")

gulf <- records %>% filter(in_box(.))
message(sprintf("%d records, %.0f larvae (%.0f before aliquot correction); %d in the box",
                nrow(records), sum(records$n_total), sum(records$n_sorted), nrow(gulf)))
message(sprintf("measured %d of %.0f larvae", sum(gulf$n_meas, na.rm = TRUE), sum(gulf$n_total)))

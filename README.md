# Cobia larvae in the SEAMAP plankton survey

Code and derived data for Robichaud et al. (in preparation, *Fishery Bulletin*), on the
distribution and seasonality of cobia (*Rachycentron canadum*) larvae in the northern Gulf of
Mexico from the SEAMAP ichthyoplankton survey, 1982-2024.

## Running it

```r
rmarkdown::render("01_data.Rmd",     output_dir = "docs")
rmarkdown::render("02_analysis.Rmd", output_dir = "docs")
```

| file | |
|---|---|
| `01_data.Rmd` | stations, environment, effort, catch, lengths into `data/derived/` |
| `02_analysis.Rmd` | distribution, season, the two shelves, size, day and night, temperature and salinity |
| `docs/*.html` | knitted output |

Figures land in `output/figures/`, with the journal versions in `output/figures/journal/`.

Packages: tidyverse, sf, terra, marmap, patchwork, rnaturalearth, ggspatial, ragg, suncalc,
rmarkdown.

## Data

Plankton Survey Data (CSV), release of August 13, 2026, from the SEAMAP data download form of
the Gulf States Marine Fisheries Commission (https://seamapdata.gsmfc.org/pages/download-form.php).
Choose that package on the form, download it, and unzip its contents into `data/raw/seamap/`
before running `01_data.Rmd`. The environmental table `ENVREC_4DB.csv` and the two documentation
files from the same package are committed under `data/raw/seamap/`, so the analysis does not
depend on a later re-release.

| table | one row per | fields used |
|---|---|---|
| `STAREC` | station | date, time, position, depth, surface temperature |
| `ENVREC_4DB` | station | surface salinity, dissolved oxygen, turbidity |
| `ISTRWK` | plankton sample | gear code, mesh, sorted flag, survey code |
| `ISARWK` | taxon within a sample | counts, aliquot |
| `ILFRWK` | measured larva | length |

Keys: `V_C_P` (vessel, cruise, station), `V_C_P_S` (+ sample), `V_C_P_S_CAT` (+ catalogue).

Figure 1 also uses the Deepwater Horizon cumulative surface oiling layer (Cumulative TCNNA SAR
Oiling, Days of Oiling, NRDA cumulative oiling workgroup) from NOAA ERMA. The 2 km reduction
drawn on the figure is committed as `data/derived/dwh_days_oiling_2km.tif`; the notebook rebuilds
it from the original layer if that file is removed.

## Notes

- `DEPTH_SSTA` is fathoms. `TEMP_SSURF` is zero when no reading was taken.
- `ISARWK` counts are of the sorted fraction; the aliquot is divided out.
- Effort is sorted bongo and neuston deployments of the standard gears, one per station and gear.
- Station times are converted to GMT before day and night are assigned.
- Surface salinity, oxygen and turbidity are `sal_surf`, `oxy_surf` and `turb_surf` on
  `effort.csv` and `cobia_records.csv`; values outside the physical range are set to NA.

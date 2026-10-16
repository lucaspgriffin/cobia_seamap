# Cobia larvae in the SEAMAP plankton survey

Distribution and seasonality of cobia (*Rachycentron canadum*) larvae in the northern Gulf of
Mexico from the SEAMAP ichthyoplankton survey, 1982-2024. 549 catch records, 1,501 larvae.

## What's already known

Ditty and Shaw (1992) is the standard reference for cobia early life history in the Gulf. They
examined 70 eggs and 76 larvae of 2.6-25 mm SL, 70 of them under 20 mm taken in the Gulf between
1967 and 1988, from museum collections and early SEAMAP samples.

- Eggs average 1.24 mm with a single oil globule. Hatching at about 2.5 mm SL; incubation of
  about 24 h at 29 C, inferred from an egg-diameter and temperature relation rather than observed.
- Yolk-sac larvae 2.6-3.2 mm. Eye unpigmented until 3.5-4.0 mm.
- Larvae first appear in late May; 98% were taken June-September.
- 85% at 25-30 C, most above 27 ppt, 75% at station depths under 100 m (median 50 m).
- Spawning inferred to occur during the day, from the developmental stage of eggs at collection.
- Seven larvae over 9.5 mm beyond the 180 m contour, all off the Mississippi delta. Offshore
  waters were well sampled in May, when adults are ripe, but no larvae were identified there.
- Collection locations suggested spawning on the shelf 50-90 km from the coast.

On the Atlantic coast, Lefebvre and Denson (2012) documented inshore spawning in two South
Carolina sounds, with eggs and larvae 10-15 km inside the sound mouths, actively spawning females
confirmed by histology, and spawning in the afternoon and early evening.

SEDAR 28 (Gulf cobia, 2013, updated 2019) carries no larval index. Ditty and Shaw is its only
early-life-history document.

## Running it

```r
rmarkdown::render("01_data.Rmd",     output_dir = "docs")   # first run downloads ~300 MB
rmarkdown::render("02_analysis.Rmd", output_dir = "docs")
```

| file | |
|---|---|
| `01_data.Rmd` | download, stations, effort, catch, lengths into `data/derived/` |
| `02_analysis.Rmd` | distribution, season, the two shelves, size, day and night, checks |
| `docs/*.html` | knitted output |

Each document is self-contained: constants, gear lookups and basemap are defined where they are
used rather than hidden in a sourced file.

Figures land in `output/figures/`, `main_` for results and `explore_` for checks.

tidyverse, sf, terra, marmap, patchwork, rnaturalearth, ggspatial, ragg, rmarkdown. Journal figures
land in `output/figures/journal/` as PDF and 600 dpi TIFF.

## Data

https://seamapdata.gsmfc.org/, Plankton Survey Data (CSV). One zip, re-released periodically;
`01_download_seamap.R` records the release used in `data/raw/seamap/SOURCE.txt`.

| table | one row per | fields used |
|---|---|---|
| `STAREC` | station | date, time, position, depth, gears deployed |
| `ISTRWK` | plankton sample | gear code, mesh, volume filtered, sorted flag |
| `ISARWK` | taxon within a sample | counts, aliquot |
| `ILFRWK` | measured larva | length |

Keys: `V_C_P` (vessel, cruise, station), `V_C_P_S` (+ sample), `V_C_P_S_CAT` (+ catalogue, links
lengths to a catch record).

## Data notes

- `DEPTH_SSTA` is fathoms. x 1.8288 for metres.
- `ISARWK` counts are of the sorted fraction. Divide out `ALIQUOT`; 12 cobia records are 1/2.
- Effort = sorted bongo and neuston deployments. 23 MOCNESS larvae and 2 unsorted tows are out of
  the rates, still on the map.
- A deployment is station x gear. Joining catch on `V_C_P` alone doubles the rate.
- Sampling is uneven by month and area. Spring survey = open Gulf, fall = shelf, June-July =
  piggybacked on the shrimp trawl survey, west of 88 W only. Regional comparisons here are
  restricted to June-July, monthly comparisons to shelf stations.
- June-July sampling ended 2016 with the summer trawl survey. Seasonal series is 1982-2016;
  records run to 2024.
- `LIFE_STAGE` is unused; its codes are crustacean stages.

## Results

- June-July peak: 26.4 and 16.1 larvae per 100 sorted shelf tows, against ~4 in May, August,
  September. Holds with area, year range and time of day fixed.
- West Florida shelf ~6x scarcer than Texas-Louisiana within June-July (4.1 vs 25.8 per 100 tows),
  matched for depth, gear and years. Scarcer, not absent.
- Smallest larvae peak in May, abundance in June.
- Neuston catch: 12.2 per 100 neuston tows vs 1.0 per 100 bongo.

## Limitations

- No ages. No age-length relation for wild cobia larvae; published rates are from hatchery
  rearing. Size classes are cuts on length, not stages.
- No interannual trend. Rates rise ~10x from the 1980s to the 2010s, but daytime sampling on the
  early trawl surveys was a known bias corrected around 1995, and across that break the day rate
  rises ~29x while the night rate barely moves.
- Two thirds of larvae measured; 11 of the 21 tows holding >10 larvae had under half measured.

## References

Ditty, J.G. and R.F. Shaw. 1992. Larval development, distribution, and ecology of cobia
*Rachycentron canadum* (Family: Rachycentridae), in the northern Gulf of Mexico.
*Fishery Bulletin* 90:668-677.

Lefebvre, L.S. and M.R. Denson. 2012. Inshore spawning of cobia (*Rachycentron canadum*) in South
Carolina. *Fishery Bulletin* 110:397-412.

# Cobia larvae in the SEAMAP plankton survey

Distribution and seasonality of cobia (*Rachycentron canadum*) larvae in the northern Gulf of
Mexico from the SEAMAP ichthyoplankton survey, 1982-2024.

SEAMAP identifies cobia to species, so this runs off the public archive with no specimen loan or
re-sorting. 549 catch records, 1,501 larvae. Ditty and Shaw (1992), the standard reference for
cobia early life history in the Gulf, examined 76.

## Running it

```r
source("R/run_all.R")     # first run downloads ~300 MB from GSMFC
```

| script | does |
|---|---|
| `R/00_setup.R` | packages, paths, SEAMAP code lookups, size bins |
| `R/01_download_seamap.R` | fetch and unzip the plankton archive |
| `R/02_build_data.R` | stations, effort, cobia catch, lengths into `data/derived/` |
| `R/03_figures.R` | results figure |
| `R/04_qc.R` | 24 checks, writes `output/logs/qc.txt` |

tidyverse, sf, terra, marmap, patchwork, rnaturalearth.

## Data

https://seamapdata.gsmfc.org/, Plankton Survey Data (CSV). One zip of the whole archive,
re-released periodically; `01_download_seamap.R` records the release used in
`data/raw/seamap/SOURCE.txt`.

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
- Smallest larvae peak in May, abundance in June. Fits a cohort spawned in or before May.
- Neuston catch: 12.2 per 100 neuston tows vs 1.0 per 100 bongo.

## Limitations

- No ages. No age-length relation exists for wild cobia larvae; published growth rates are from
  hatchery rearing. Size classes are cuts on length, not stages.
- No interannual trend. Rates rise ~10x from the 1980s to the 2010s, but daytime sampling on the
  early trawl surveys was a known bias corrected around 1995, and across that break the day rate
  rises ~29x while the night rate barely moves.
- Two thirds of larvae measured; 11 of the 21 tows holding >10 larvae had under half measured.

## Reference

Ditty, J.G. and R.F. Shaw. 1992. Larval development, distribution, and ecology of cobia
*Rachycentron canadum* (Family: Rachycentridae), in the northern Gulf of Mexico.
*Fishery Bulletin* 90:668-677.

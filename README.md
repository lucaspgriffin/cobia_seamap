# Cobia larvae in the SEAMAP plankton survey

Distribution and seasonality of cobia (*Rachycentron canadum*) larvae in the northern Gulf of
Mexico, from the SEAMAP ichthyoplankton survey, 1982–2024.

The survey identifies cobia to species itself, so everything here comes from the public archive —
no specimen loan or re-sorting. 549 catch records holding 1,501 larvae, against 76 in Ditty and
Shaw (1992), the standard reference for cobia early life history in the Gulf.

## Running it

```r
source("R/run_all.R")     # first run downloads ~300 MB from GSMFC
```

Or step by step:

| | |
|---|---|
| `R/00_setup.R` | packages, paths, SEAMAP code lookups, size bins |
| `R/01_download_seamap.R` | fetch and unzip the plankton archive |
| `R/02_build_data.R` | stations, effort, cobia catch, lengths → `data/derived/` |
| `R/03_figures.R` | the results figure |
| `R/04_qc.R` | 24 checks; writes `output/logs/qc.txt` |

Needs tidyverse, sf, terra, marmap, patchwork, rnaturalearth.

## Getting the SEAMAP data

`https://seamapdata.gsmfc.org/` → Plankton Survey Data (CSV). One zip of the whole archive,
re-released periodically; `01_download_seamap.R` records the release it used in
`data/raw/seamap/SOURCE.txt`.

Four tables matter:

| table | one row per | used for |
|---|---|---|
| `STAREC` | station | date, time, position, depth (**fathoms**), gears deployed |
| `ISTRWK` | plankton sample | gear code, mesh, volume filtered, sorted flag |
| `ISARWK` | taxon × sample | counts, aliquot |
| `ILFRWK` | measured larva | length |

They join on `V_C_P` (vessel-cruise-station) and `V_C_P_S` (+ sample), with `V_C_P_S_CAT`
(+ catalogue) linking lengths to a catch record.

## Things that will bite you

- **`DEPTH_SSTA` is fathoms, not metres.** Multiply by 1.8288.
- **Counts are of what was sorted.** 12 cobia records come from half the sample; divide the
  `ALIQUOT` back out or you undercount.
- **Effort must come from the same pool as the catch.** Rates here divide by sorted bongo and
  neuston deployments, so 23 larvae taken by MOCNESS and 2 tows never flagged sorted are excluded
  from the rates. They stay on the map.
- **A deployment is a station *and* gear.** Joining catch on station alone gives each tow's larvae
  to both the bongo and the neuston row and doubles the rate.
- **The survey does not sample the same places every month.** The spring survey works the open
  Gulf, the fall survey the shelf, and the June–July sampling is piggybacked on the shrimp trawl
  survey and so only runs west of 88°W. Comparing places on all-year effort reads as where the
  survey went, not where the fish were.
- **June–July sampling stopped in 2016**, when plankton work on the summer trawl survey was
  discontinued. There is not one June or July shelf tow after that, so the seasonal series is
  1982–2016 even though records run to 2024.
- **`LIFE_STAGE` is documented as "currently not in use"** and its values are crustacean stages.

## What the data supports

- a sharp **June–July** peak, 26.4 and 16.1 larvae per 100 sorted shelf tows against ~4 in May,
  August and September; survives fixing the area, the year range and the time of day
- cobia larvae about **six times scarcer on the west Florida shelf** than the Texas–Louisiana
  shelf within June–July, matched for depth, gear and years — scarcer, not absent
- small larvae peak in **May** while abundance peaks in June, which is a cohort growing rather
  than peak spawning in June
- larvae are a **neuston catch**: 12.2 per 100 neuston tows against 1.0 per 100 bongo

## What it does not

No ages. There is no age–length relation for wild cobia larvae — the published growth rates are
from hatchery rearing — so no hatch dates and no back-calculated spawning times. The size classes
are descriptive cuts, not stages; nobody has examined these specimens.

No interannual trend. Catch rates rise about tenfold from the 1980s to the 2010s, but daytime
sampling on the early trawl surveys is a documented bias corrected around 1995, and across that
break the daytime rate rises ~29× while the night rate barely moves. That is the sampling.

## Reference

Ditty, J.G. and R.F. Shaw. 1992. Larval development, distribution, and ecology of cobia
*Rachycentron canadum* (Family: Rachycentridae), in the northern Gulf of Mexico.
*Fishery Bulletin* 90:668–677.

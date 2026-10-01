# Cobia larvae in the SEAMAP plankton survey

Distribution and seasonality of cobia (*Rachycentron canadum*) larvae in the northern Gulf of
Mexico from the SEAMAP ichthyoplankton survey, 1982-2024.

SEAMAP identifies cobia to species, so the analysis runs off the public archive with no specimen
loan or re-sorting. The archive holds 549 catch records and 1,501 larvae. Ditty and Shaw (1992),
the standard reference for cobia early life history in the Gulf, examined 76.

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

Requires tidyverse, sf, terra, marmap, patchwork, rnaturalearth.

## The SEAMAP data

Download from https://seamapdata.gsmfc.org/ under Plankton Survey Data (CSV). It comes as one zip
of the whole archive and is re-released periodically. `01_download_seamap.R` writes the release it
used to `data/raw/seamap/SOURCE.txt`.

Four tables are used:

| table | one row per | fields used |
|---|---|---|
| `STAREC` | station | date, time, position, depth (fathoms), gears deployed |
| `ISTRWK` | plankton sample | gear code, mesh, volume filtered, sorted flag |
| `ISARWK` | taxon within a sample | counts, aliquot |
| `ILFRWK` | measured larva | length |

Keys are `V_C_P` (vessel, cruise, station), `V_C_P_S` (plus sample) and `V_C_P_S_CAT` (plus
catalogue), which is what links a length to a catch record.

## Working with these tables

A few things in the data are easy to get wrong.

`DEPTH_SSTA` is in fathoms. Multiply by 1.8288 for metres.

Counts in `ISARWK` are of the fraction that was sorted. Twelve cobia records come from half the
sample, so the `ALIQUOT` has to be divided back out.

Catch rates need a denominator drawn from the same pool as the numerator. Effort here is sorted
bongo and neuston deployments, which means 23 larvae taken by MOCNESS and two tows that were never
flagged as sorted are left out of the rates. They are still mapped.

A deployment is a station and a gear, not a station. Joining catch on `V_C_P` alone assigns each
tow's larvae to both the bongo and the neuston row and doubles the rate.

Sampling is not spread evenly through the year or the Gulf. The spring survey works the open Gulf,
the fall survey the shelf, and June-July plankton sampling was piggybacked on the shrimp trawl
survey, which works west of 88 W. Dividing catch by all-year effort therefore describes where the
survey went as much as where the fish were, so the regional comparison here is restricted to
June-July and the monthly comparison to shelf stations.

June-July sampling ended in 2016 when plankton work on the summer trawl survey was discontinued.
There are no June or July shelf tows after that, so the seasonal series runs 1982-2016 even though
records continue to 2024.

`LIFE_STAGE` is documented as not in use, and its codes are crustacean stages.

## Results

Larval abundance peaks sharply in June and July, at 26.4 and 16.1 larvae per 100 sorted shelf tows
against about 4 in May, August and September. The peak holds when the area, year range and time of
day are held fixed.

Within June-July, cobia larvae are about six times scarcer on the west Florida shelf than on the
Texas-Louisiana shelf (4.1 against 25.8 per 100 tows), matched for depth, gear and years. Scarcer,
not absent.

The smallest larvae peak in May while abundance peaks in June, which fits a cohort spawned in or
before May rather than peak spawning in June.

Larvae are overwhelmingly a neuston catch: 12.2 per 100 neuston tows against 1.0 per 100 bongo.

## Limitations

No ages. There is no age-length relation for wild cobia larvae and the published growth rates come
from hatchery rearing, so hatch dates and spawning times cannot be back-calculated. The size
classes are descriptive cuts on length, not developmental stages, and no one has examined these
specimens.

No interannual trend. Catch rates rise roughly tenfold between the 1980s and the 2010s, but
daytime sampling on the early trawl surveys was a known bias that was corrected around 1995.
Across that break the daytime rate rises about 29-fold while the night rate barely changes, which
points at the sampling rather than at abundance.

Two thirds of larvae were measured, and coverage is worst in the largest tows: 11 of the 21 tows
holding more than 10 larvae had fewer than half measured.

## Reference

Ditty, J.G. and R.F. Shaw. 1992. Larval development, distribution, and ecology of cobia
*Rachycentron canadum* (Family: Rachycentridae), in the northern Gulf of Mexico.
*Fishery Bulletin* 90:668-677.

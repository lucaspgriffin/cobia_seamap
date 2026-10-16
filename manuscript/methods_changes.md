# Changes to carry into the Methods (branch `fix-time-zone`)

Running list of data-handling decisions made during review, and the Methods statements each one
affects. Numbers come from the re-rendered `docs/*.html`. The text itself still needs writing by
the authors.

## 1. Station times read in their recorded time zone

`STAREC.TIME_ZN` records the clock each `TIME_MIL` is on (EST, EDT, CST, CDT, AST, ADT or GMT).
From about 2000 nearly all stations are logged in GMT; the original code read every time as local,
which misclassified 31-41% of tows from 2000 onward. Times are now converted to GMT, and a tow is
night when the sun is below the horizon at its time and position (NOAA solar position
approximation). The share of night tows is now steady at 42-47% across decades
(`check-time-zone` in `02_analysis.Rmd`).

Methods to update:
- Definition of night: currently "taking night as 2000 to 0600 h".
- Trend paragraph: diurnal rate now 1.3 -> 7.5 and nocturnal 16.5 -> 74.2 larvae per 100
  deployments (June-July shelf, 1982-1994 vs 1995-2016). Both rise, so the stated reason for not
  fitting a trend no longer holds.
- Any day/night result: neuston catches are 3-9x higher at night; bongo catches are about equal.

## 2. Standard SEAMAP gear only

Effort and catch rates are restricted to the standard gears as defined in the SEAMAP
documentation: 61 or 60 cm bongo with 0.333 mm mesh (gear 01 or 17, mesh 03), and single or
double neuston with 0.947 mm mesh (gear 03 or 08, mesh 09). Excluded from rates, kept on the map:
36 cobia larvae from non-standard mesh (19 bongo, 17 neuston, mesh 05), in addition to the 23
MOCNESS larvae and 3 from unsorted samples already excluded.

Methods to update:
- Neuston mesh: the documentation gives 0.947 mm; the Methods says 0.950 mm.
- Deployments: 29,479 -> 29,127 (bongo 14,135 -> 13,931; neuston 15,344 -> 15,196).
- Excluded larvae: add the 36 from non-standard nets.
- Surface temperature: recorded for 96.7% of deployments and 1406 of the larvae (was 96.6%, 1,442).
- West Florida share of shelf tows in June-July: 12% (unchanged); Texas-Louisiana 26% (was 27%).

## 3. Smaller fixes

- 36 samples have a 9-character station key; they were dropped from effort by a 10-character
  substring. The station key is now read directly. None held cobia.
- Bootstrap intervals now take both limits from one set of 2000 resamples (previously two).

## 4. Notes for tables

- Day/night by gear and size: the bongo large-larva row (0.01 day vs 0.05 night per 100
  deployments) rests on very few larvae. Keep it with a footnote saying so; do not interpret the
  ratio.

## 5. Supporting numbers now in the code

These numbers are in the draft Table 2 and Results. They were first computed in a review script and
now come from the "Numbers for the text" section of `02_analysis.Rmd`.

- Table 2 robustness rows (June-July shelf, 1982-2016): cruise-resampled 95% CIs (13.5-45.5 vs
  0.9-10.1); without the 2 largest catches (18.3 vs 4.3); 1995-2016 only (39.7 vs 6.0); diurnal
  (5.7 vs 0.5); nocturnal (76.6 vs 9.6); neuston only (52.7 vs 8.8); bongo only (2.2 vs 0.3);
  share of nocturnal deployments (29% vs 42%).
- Rates by gear, all effort: neuston 8.58 vs bongo 0.95 per 100; 2.69% vs 0.67% of deployments
  with cobia; neuston share of larvae in the rates 90.7%.
- Comparisons with Ditty and Shaw (1992): 98.5% of larvae in May-September (85.7% June-September);
  84.7% at stations <100 m; larva-weighted median station depth 42 m; 141 larvae in 83 records
  beyond 200 m.
- Overall day vs night: neuston 16.5 vs 2.0, bongo 1.0 vs 0.9 per 100.

## Results after all three changes

| | Original | Now |
|---|---|---|
| Shelf rate, June / July / Sept (per 100, 1982-2016) | 26.4 / 16.1 / 4.2 | 27.1 / 16.6 / 4.2 |
| May | 4.8 | 3.8 |
| Texas-Louisiana vs west Florida, June-July | 25.8 (15.7-42.9) vs 4.1 (1.2-8.9) | 26.5 (15.9-43.1) vs 4.3 (1.2-9.2) |
| Larvae in the rates | 1473 | 1437 |
| Larvae at 25-30 C vs all tows | 84.3% vs 69.1% | 84.5% vs 69.3% |

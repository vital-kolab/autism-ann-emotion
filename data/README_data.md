# Data directory

This folder contains the curated numerical tables and optional raw analysis files used by the figure-generation scripts.

## Curated data

`data/curated/` contains summary-level data tables that are sufficient to regenerate the plotted figure elements.

## Raw data

`data/raw/` is the location for raw analysis files that are needed for selected recomputation steps but may not be distributed publicly.

For Figure 3E, place the following files in `data/raw/`:

```text
na_yeon_data_msfde80.mat
ann_scores.mat
```

For Figure 1, place subject-level matrices either in `data/raw/figure1/` or directly in `data/raw/`:

```text
nt_matrix.csv
asd_matrix.csv
```

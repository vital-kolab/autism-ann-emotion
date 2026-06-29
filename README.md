# AI-guided stimulus optimization for facial emotion perception in autism

This repository accompanies the manuscript:

**AI-guided stimulus discovery and generation to optimize facial emotion perception studies in autism**

It contains curated numerical data tables and MATLAB scripts for regenerating the figure elements included with the manuscript. The repository is structured to support reproducibility while sharing only the data needed for the plotted analyses.

## Repository structure

```text
run_figure1.m
run_figure3_BCDE.m
run_figure4B.m
data/
  curated/          Curated numerical tables used by plotting scripts
  raw/              Optional raw analysis files for local recomputation
scripts/
  common/           Shared helper functions
  figure1/          Figure 1 analysis and plotting code
  figure3/          Figure 3B-E analysis and plotting code
  figure4/          Figure 4B analysis and plotting code
  analysis_optional/
                    Optional recomputation scripts
outputs/
  figure1/          Generated Figure 1 outputs
  figure3_panels/   Generated Figure 3 panel outputs
  figure3_combined/ Generated combined Figure 3B-E output
  figure4/          Generated Figure 4B outputs
```

## MATLAB requirements

The scripts were developed for MATLAB R2021b or later. The scripts use core MATLAB functions and include local helper functions for several common operations. The Statistics and Machine Learning Toolbox and Curve Fitting Toolbox are useful when available, but most plotting code includes summary tables where possible.

## Quick start

From the repository root:

```matlab
run_figure1
run_figure3_BCDE
run_figure4B
```

Generated outputs are written to the `outputs/` folder.

## Figure 1

`run_figure1.m` regenerates the cross-validated image-level sparsity analysis for the Wang and Adolphs facial emotion dataset.

Required local files:

```text
data/raw/figure1/nt_matrix.csv
data/raw/figure1/asd_matrix.csv
```

Each file should be an image-by-subject matrix. Entries should correspond to the probability of choosing “happy” or the trial-averaged happy-choice response.

If these files are placed directly under `data/raw/`, the script will also detect them.

## Figure 3B-E

`run_figure3_BCDE.m` regenerates:

- **Figure 3B**: diagnostic power of ANN-selected versus random image sets
- **Figure 3C**: random versus CLIP-selected image-set distributions
- **Figure 3D**: relationship between model alignment and selected diagnostic power
- **Figure 3E**: sparsity of diagnostic image effects with the ANN-selected point

Figure 3B-D use curated tables in `data/curated/`.

Figure 3E requires the raw analysis files used for the MSFDE/ANN analysis:

```text
data/raw/na_yeon_data_msfde80.mat
data/raw/ann_scores.mat
```

The first file should contain the `nt` and `asd` matrices. The second file should contain the ANN score tables used to compute predicted autistic-neurotypical differences.

## Figure 4B

`run_figure4B.m` regenerates the phenotype-matched validation of gap-reducing synthesis using:

```text
data/curated/figure4B_phenotype_matched_corr_imagelevel.csv
```

The plotted quantity is the image-level autistic-neurotypical behavioral gap for each diagnostic base image and its corresponding gap-reduced synthesized image.

## Data included

This repository includes only curated numerical data tables and selected raw analysis files needed for figure regeneration. It does not include identifiable participant information, raw face images, generated face images, or model checkpoints.

## Reproducibility notes

Randomized analyses set the MATLAB random-number generator where appropriate. Small numerical differences can occur across MATLAB versions or when optional toolboxes are unavailable.

## Contact

For questions about the manuscript or code, contact the corresponding author listed in the manuscript.

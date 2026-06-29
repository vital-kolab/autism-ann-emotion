# Raw data for exact Figure 3E

To reproduce Figure 3E exactly as in the analysis, add these files here:

```text
data/raw/na_yeon_data_msfde80.mat
data/raw/ann_scores.mat
```

The first file must contain `nt` and `asd`.
The second file must contain `scores_vit.vit_scores` and/or `scores_clip.clip_scores`.

By default, the script uses `scores_vit.vit_scores`, matching the analysis workflow where `init_ctrl` and `init_asd` were overwritten with ViT scores. To use CLIP instead, edit:

```matlab
optsE.modelForPanelE = 'clip';
```

in `scripts/plot_figure3_panelE_sparsity.m` and `scripts/run_figure3_BCDE.m`.

%% run_figure4B.m
% -------------------------------------------------------------------------
% Regenerate Figure 4B: gap-reducing synthesis in a correlation-based
% phenotype-matched validation.
%
% This uses only curated image-level data:
%   data/curated/figure4B_phenotype_matched_corr_imagelevel.csv
%
% It does not require raw participant-level trial data or face images.
% -------------------------------------------------------------------------

clear; clc; close all;

thisFile = mfilename('fullpath');
scriptDir = fileparts(thisFile);
rootDir = fileparts(fileparts(scriptDir));

addpath(genpath(fullfile(rootDir, 'scripts')));

dataDir = fullfile(rootDir, 'data', 'curated');
outDir  = fullfile(rootDir, 'outputs', 'figure4');

fig = plot_figure4B_paired_gap_reduction(dataDir, outDir);

fprintf('\nSaved Figure 4B outputs to:\n  %s\n', outDir);

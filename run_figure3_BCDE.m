%% run_figure3_BCDE.m
% Regenerate Figure 3B-E from the repository root.

clear; clc; close all;

repoRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(repoRoot, 'scripts')));

run(fullfile(repoRoot, 'scripts', 'figure3', 'run_figure3_BCDE_impl.m'));

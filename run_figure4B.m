%% run_figure4B.m
% Regenerate Figure 4B from the repository root.

clear; clc; close all;

repoRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(repoRoot, 'scripts')));

run(fullfile(repoRoot, 'scripts', 'figure4', 'run_figure4B_impl.m'));

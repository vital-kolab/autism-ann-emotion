%% run_figure1.m
% Regenerate Figure 1 from the repository root.

clear; clc; close all;

repoRoot = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(repoRoot, 'scripts')));

run(fullfile(repoRoot, 'scripts', 'figure1', 'run_figure1_impl.m'));

%% run_figure1.m
% -------------------------------------------------------------------------
% Regenerate Figure 1B: cross-validated sparsity of image-level
% autistic-neurotypical behavioral differences.
%
% Required input files:
%   data/raw/nt_matrix.csv
%   data/raw/asd_matrix.csv
%
% Rows = images, columns = subjects.
% Entries = probability of choosing happy or trial-averaged happy choice.
% -------------------------------------------------------------------------

clear; clc; close all;
rng(1);

rootDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
rawDir  = fullfile(rootDir, 'data', 'raw', 'figure1');
if ~exist(fullfile(rawDir, 'nt_matrix.csv'), 'file')
    rawDir = fullfile(rootDir, 'data', 'raw');
end
outData = fullfile(rootDir, 'data', 'curated');
outFig  = fullfile(rootDir, 'outputs', 'figure1');

if ~exist(outData, 'dir'); mkdir(outData); end
if ~exist(outFig, 'dir'); mkdir(outFig); end

ntFile  = fullfile(rawDir, 'nt_matrix.csv');
asdFile = fullfile(rawDir, 'asd_matrix.csv');

if ~exist(ntFile, 'file') || ~exist(asdFile, 'file')
    error(['Missing raw matrices. Add files here:\n' ...
        '  %s\n  %s\n\n' ...
        'Each should be image x subject. See data/raw/README_raw_data.md.'], ...
        ntFile, asdFile);
end

nt  = readmatrix(ntFile);
asd = readmatrix(asdFile);

% Remove all-NaN header/template rows if present.
nt  = nt(~all(isnan(nt),2), :);
asd = asd(~all(isnan(asd),2), :);

if size(nt,1) ~= size(asd,1)
    error('NT and ASD matrices must have the same number of image rows.');
end

fprintf('\nLoaded matrices:\n');
fprintf('  NT:  %d images x %d subjects\n', size(nt,1), size(nt,2));
fprintf('  ASD: %d images x %d subjects\n', size(asd,1), size(asd,2));

%% Analysis options
opts = struct;
opts.dels = 0:0.02:0.20;
opts.nBoot = 1000;
opts.maxSubjectsPerGroup = 20;
opts.useMAD = true;
opts.rngSeed = 1;

im_loc = true(size(nt,1),1);

[result, bootTable] = compute_figure1_crossvalidated_sparsity( ...
    opts.dels, nt, asd, im_loc, opts);

writetable(result, fullfile(outData, 'figure1_crossvalidated_sparsity.csv'));
writetable(bootTable, fullfile(outData, 'figure1_crossvalidated_sparsity_bootstrap.csv'));

%% Plot
plot_figure1_sparsity(result, outFig);

fprintf('\nSaved outputs:\n');
fprintf('  %s\n', fullfile(outData, 'figure1_crossvalidated_sparsity.csv'));
fprintf('  %s\n', fullfile(outData, 'figure1_crossvalidated_sparsity_bootstrap.csv'));
fprintf('  %s\n', fullfile(outFig, 'Figure1_sparsity.png'));
fprintf('  %s\n', fullfile(outFig, 'Figure1_sparsity.pdf'));

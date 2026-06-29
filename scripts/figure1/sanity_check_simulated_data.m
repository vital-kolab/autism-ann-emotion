%% sanity_check_simulated_data.m
% -------------------------------------------------------------------------
% Optional sanity check only. This generates fake NT/ASD matrices so the
% Figure 1 code path can be tested. Do not use these matrices for the paper.
% -------------------------------------------------------------------------

clear; clc;
rng(1);

rootDir = fileparts(fileparts(mfilename('fullpath')));
rawDir = fullfile(rootDir, 'data', 'raw');

nImg = 28;
nNT = 15;
nASD = 18;

base = linspace(0.05, 0.95, nImg)';
base = base(randperm(nImg));

nt = repmat(base, 1, nNT) + 0.10*randn(nImg, nNT);
asd = repmat(base, 1, nASD) + 0.10*randn(nImg, nASD);

% Add sparse group differences to a few images.
asd(1:5,:) = asd(1:5,:) - 0.12;
asd(6:8,:) = asd(6:8,:) + 0.08;

nt = min(max(nt,0),1);
asd = min(max(asd,0),1);

writematrix(nt, fullfile(rawDir, 'nt_matrix.csv'));
writematrix(asd, fullfile(rawDir, 'asd_matrix.csv'));

fprintf('Wrote simulated matrices to data/raw/. Do not use for manuscript figures.\n');

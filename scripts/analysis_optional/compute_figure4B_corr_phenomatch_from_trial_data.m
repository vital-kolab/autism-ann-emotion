%% compute_figure4B_corr_phenomatch_from_trial_data.m
% -------------------------------------------------------------------------
% Optional script: recompute Figure 4B image-level table from trial-level
% validation data.
%
% This mirrors the phenotype-matched validation logic used for the manuscript
% but is NOT needed to regenerate the figure from the curated repository.
%
% Required files to add locally:
%   data/raw/full_data_decoded.csv
%       columns required:
%       image_number, subject_id, MainGroup, AQ, SRS, happy_choose
%
%   data/raw/top15_reducing_delta.csv
%       columns required:
%       true_ctrl_score, true_asd_score
%
% Image mapping:
%   Base images  = image_number 45:59
%   Synth images = image_number 30:44
%
% Matching:
%   leave-one-image-out correlation phenotype matching
% -------------------------------------------------------------------------

clear; clc; close all;
rng(1);

thisFile = mfilename('fullpath');
scriptDir = fileparts(thisFile);
rootDir = fileparts(fileparts(scriptDir));

addpath(genpath(fullfile(rootDir, 'scripts')));

rawDir = fullfile(rootDir, 'data', 'raw');
outDir = fullfile(rootDir, 'data', 'curated');

fullDataFile = fullfile(rawDir, 'full_data_decoded.csv');
reduceFile   = fullfile(rawDir, 'top15_reducing_delta.csv');

if ~exist(fullDataFile, 'file') || ~exist(reduceFile, 'file')
    error(['Missing raw files. Add:\n  %s\n  %s\n'], fullDataFile, reduceFile);
end

data = readtable(fullDataFile);
reduce = readtable(reduceFile);

redSynthNums = (30:44)';
redBaseNums  = (45:59)';

oldNT  = reduce.true_ctrl_score(:);
oldASD = reduce.true_asd_score(:);

AQrange  = [1 60];
SRSrange = [1 300];

[NT_base,  ~] = make_response_matrix(data, 'Control', redBaseNums,  AQrange, SRSrange);
[NT_synth, ~] = make_response_matrix(data, 'Control', redSynthNums, AQrange, SRSrange);

[ASD_base,  ~] = make_response_matrix(data, 'ASD', redBaseNums,  AQrange, SRSrange);
[ASD_synth, ~] = make_response_matrix(data, 'ASD', redSynthNums, AQrange, SRSrange);

opts = struct;
opts.keepFrac = 0.50;
opts.minKeep  = 8;
opts.metric   = 'corr';
opts.minTrain = 8;
opts.equalN   = true;

pm = phenotype_match_loo_corr(NT_base, ASD_base, NT_synth, ASD_synth, oldNT, oldASD, opts);

T = table( ...
    (1:numel(redBaseNums))', redBaseNums, redSynthNums, oldNT, oldASD, ...
    pm.ntBaseMean, pm.asdBaseMean, pm.ntSynthMean, pm.asdSynthMean, ...
    pm.baseGap, pm.synthGap, pm.effect, ...
    'VariableNames', {'ImageIndex','BaseImageNumber','SynthImageNumber', ...
    'OldNTTemplate','OldASDTemplate','NTBase','ASDBase','NTSynth','ASDSynth', ...
    'BaseGap','SynthGap','GapReduction'});

writetable(T, fullfile(outDir, 'figure4B_phenotype_matched_corr_imagelevel_RECOMPUTED.csv'));

fprintf('\nRecomputed Figure 4B data saved to data/curated/.\n');
fprintf('Base gap mean:  %.4f\n', mean(T.BaseGap,'omitnan'));
fprintf('Synth gap mean: %.4f\n', mean(T.SynthGap,'omitnan'));
fprintf('Reduction:      %.4f +/- %.4f SEM\n', mean(T.GapReduction,'omitnan'), localSEM(T.GapReduction));

%% ------------------------------------------------------------------------
% Helper functions
%% ------------------------------------------------------------------------

function [R, subjIDs] = make_response_matrix(data, groupName, imgNums, AQrange, SRSrange)
groupVec = string(data.MainGroup);
subjVec  = string(data.subject_id);

groupMask = contains(groupVec, groupName);

subjectMask = ...
    data.AQ  > AQrange(1)  & data.AQ  < AQrange(2) & ...
    data.SRS > SRSrange(1) & data.SRS < SRSrange(2);

baseMask = groupMask & subjectMask;
subjIDs = unique(subjVec(baseMask), 'stable');

R = nan(numel(imgNums), numel(subjIDs));

for s = 1:numel(subjIDs)
    for i = 1:numel(imgNums)
        rows = baseMask & subjVec == subjIDs(s) & data.image_number == imgNums(i);
        R(i,s) = mean(data.happy_choose(rows), 'omitnan');
    end
end
end

function out = phenotype_match_loo_corr(NT_base, ASD_base, NT_synth, ASD_synth, oldNT, oldASD, opts)
nImg = size(NT_base, 1);
nNT  = size(NT_base, 2);
nASD = size(ASD_base, 2);

if opts.equalN
    nKeep = max(opts.minKeep, round(opts.keepFrac * min(nNT, nASD)));
    nKeep = min([nKeep, nNT, nASD]);
else
    error('Only equalN = true is implemented.');
end

ntBaseMean   = nan(nImg,1);
asdBaseMean  = nan(nImg,1);
ntSynthMean  = nan(nImg,1);
asdSynthMean = nan(nImg,1);
baseGap      = nan(nImg,1);
synthGap     = nan(nImg,1);
effect       = nan(nImg,1);

for i = 1:nImg
    trainIdx = setdiff(1:nImg, i);

    ntSel  = select_subjects_by_corr_template(NT_base, oldNT, trainIdx, nKeep, opts.minTrain);
    asdSel = select_subjects_by_corr_template(ASD_base, oldASD, trainIdx, nKeep, opts.minTrain);

    ntBaseMean(i)   = mean(NT_base(i,ntSel), 'omitnan');
    asdBaseMean(i)  = mean(ASD_base(i,asdSel), 'omitnan');
    ntSynthMean(i)  = mean(NT_synth(i,ntSel), 'omitnan');
    asdSynthMean(i) = mean(ASD_synth(i,asdSel), 'omitnan');

    baseGap(i)  = abs(asdBaseMean(i)  - ntBaseMean(i));
    synthGap(i) = abs(asdSynthMean(i) - ntSynthMean(i));
    effect(i)   = baseGap(i) - synthGap(i);
end

out = struct;
out.ntBaseMean = ntBaseMean;
out.asdBaseMean = asdBaseMean;
out.ntSynthMean = ntSynthMean;
out.asdSynthMean = asdSynthMean;
out.baseGap = baseGap;
out.synthGap = synthGap;
out.effect = effect;
end

function sel = select_subjects_by_corr_template(M, template, trainIdx, nKeep, minTrain)
nSub = size(M,2);
score = nan(nSub,1);
t = template(:);

for s = 1:nSub
    x = M(trainIdx,s);
    y = t(trainIdx);
    good = isfinite(x) & isfinite(y);

    if sum(good) < minTrain || std(x(good)) == 0 || std(y(good)) == 0
        score(s) = inf;
    else
        r = corr(x(good), y(good), 'type', 'Pearson', 'rows', 'complete');
        score(s) = -r; % larger correlation is better
    end
end

[~, order] = sort(score, 'ascend');
order = order(isfinite(score(order)));
sel = order(1:min(nKeep, numel(order)));
end

function [curveTable, annTable, raw] = compute_figure3E_analysis_exact(paperDir, modelName)
% compute_figure3E_analysis_exact
% -------------------------------------------------------------------------
% Implementation of the analysis used for the manuscript's
% Figure 3E.
%
% This intentionally mirrors:
%
%   load('data/raw/na_yeon_data_msfde80.mat')  % nt, asd
%   load('data/raw/ann_scores.mat')            % scores_clip, scores_vit
%
%   % NOTE: in the analysis workflow, CLIP is first assigned but then
%   %
%
%   init_ctrl = scores_vit.vit_scores.init_ctrl_score;
%   init_asd  = scores_vit.vit_scores.init_asd_score;
%   delta_pred = abs(init_ctrl - init_asd);
%
%   dels = 0:0.02:0.2;
%   parfor k = 1:28
%       rng('shuffle')
%       im_loc = ismember(1:80, randsample(80,28,false));
%       nt_tmp = nt(im_loc,:);
%       asd_tmp = asd(im_loc,:);
%       [valc(:,k),~,number_imgc(:,:,k)] = get_vals_eff(dels, nt_tmp, asd_tmp, im_loc);
%   end
%
%   im_loc = delta_pred > prctile(delta_pred,65);
%   nt_ann_pred = nt(im_loc,:);
%   asd_ann_pred = asd(im_loc,:);
%   [valt, valt_err, number_imgt] = get_vals_eff(0, nt_ann_pred, asd_ann_pred, im_loc);
%
% Important details preserved:
%   - random subsets are 28 images from all 80 images
%   - red point uses delta_pred > prctile(delta_pred,65)
%   - get_vals_eff receives im_loc but does not use it, matching the original
%   - black curve uses nanmean(nanmean(number_imgc,3),1)
%   - error bars use mad(...) exactly when available
% -------------------------------------------------------------------------

if nargin < 1 || isempty(paperDir)
    paperDir = resolve_paper_dir();
end
if nargin < 2 || isempty(modelName)
    modelName = 'vit';
end

rawDir = fullfile(paperDir, 'data', 'raw');

dataFile = fullfile(rawDir, 'na_yeon_data_msfde80.mat');
scoresFile = fullfile(rawDir, 'ann_scores.mat');

if ~exist(dataFile, 'file') || ~exist(scoresFile, 'file')
    error(['Missing required raw files for exact Figure 3E.\n\n' ...
        'Expected:\n  %s\n  %s\n\n' ...
        'Run from the main 2026.Paper folder or edit paperDir.'], ...
        dataFile, scoresFile);
end

S = load(dataFile);      % nt, asd
A = load(scoresFile);    % scores_clip, scores_vit

if ~isfield(S, 'nt') || ~isfield(S, 'asd')
    error('na_yeon_data_msfde80.mat must contain variables nt and asd.');
end

nt = S.nt;
asd = S.asd;

switch lower(string(modelName))
    case "vit"
        init_ctrl = A.scores_vit.vit_scores.init_ctrl_score;
        init_asd  = A.scores_vit.vit_scores.init_asd_score;
    case "clip"
        init_ctrl = A.scores_clip.clip_scores.init_ctrl_score;
        init_asd  = A.scores_clip.clip_scores.init_asd_score;
    otherwise
        error('modelName must be vit or clip.');
end

delta_pred = abs(init_ctrl - init_asd);

if size(nt,1) ~= 80 || size(asd,1) ~= 80
    warning('Expected nt/asd to have 80 rows. Found nt=%d, asd=%d.', size(nt,1), size(asd,1));
end

%% Random subset curve
dels = 0:0.02:0.2;
valc = nan(length(dels),28);
number_imgc = nan(100,length(dels),28);

for k = 1:28
    rng('shuffle');

    im_loc = ismember(1:size(nt,1), local_randsample(size(nt,1),28,false));

    nt_tmp = nt(im_loc,:);
    asd_tmp = asd(im_loc,:);

    [valc(:,k), ~, number_imgc(:,:,k)] = get_vals_eff_original(dels, nt_tmp, asd_tmp, im_loc);
end

x = nanmean(valc,2);
y = nanmean(nanmean(number_imgc,3),1)';

xerr = local_mad_matlab(valc, [], 2);
yerr = local_mad_matlab(nanmean(number_imgc,3), [], 1)';

curveTable = table(dels(:), x(:), xerr(:), y(:), yerr(:), ...
    'VariableNames', {'DeltaThreshold','MeanEffect','EffectMAD','MeanNDiscriminativeImages','NImagesMAD'});

%% ANN optimized red point
im_loc_ann = delta_pred > prctile(delta_pred,65);

nt_ann_pred  = nt(im_loc_ann,:);
asd_ann_pred = asd(im_loc_ann,:);

[valt, valt_err, number_imgt] = get_vals_eff_original(0, nt_ann_pred, asd_ann_pred, im_loc_ann);

annTable = table( ...
    string(modelName), ...
    65, ...
    sum(im_loc_ann), ...
    valt(1), ...
    valt_err(1), ...
    nanmean(number_imgt(:,1)), ...
    local_mad_matlab(number_imgt(:,1), [], 1), ...
    'VariableNames', {'ModelForPanelE','PercentileThreshold','NSelected', ...
    'AnnEffect','AnnEffectMAD','AnnNDiscriminativeImages','AnnNImagesMAD'});

raw = struct;
raw.paperDir = paperDir;
raw.modelName = modelName;
raw.nt = nt;
raw.asd = asd;
raw.delta_pred = delta_pred;
raw.valc = valc;
raw.number_imgc = number_imgc;
raw.valt = valt;
raw.valt_err = valt_err;
raw.number_imgt = number_imgt;
raw.im_loc_ann = im_loc_ann;
end


function paperDir = resolve_paper_dir()
candidateDirs = {
    pwd
    fileparts(pwd)
    fileparts(fileparts(mfilename('fullpath')))
    fileparts(fileparts(fileparts(mfilename('fullpath'))))
    };

paperDir = '';

for i = 1:numel(candidateDirs)
    d = candidateDirs{i};

    if exist(fullfile(d, 'data', 'raw', 'na_yeon_data_msfde80.mat'), 'file') && ...
       exist(fullfile(d, 'data', 'raw', 'ann_scores.mat'), 'file')
        paperDir = d;
        return;
    end
end

paperDir = pwd;
end

function [val, val_err, number_img] = get_vals_eff_original(dels, nt, asd, im_loc) %#ok<INUSD>
% Original get_vals_eff logic from the analysis. im_loc is intentionally
% not used.

num_sub1 = size(nt,2);
num_sub2 = size(asd,2);

num_sub = min([20, min([num_sub1, num_sub2])]);

C = nchoosek(1:num_sub, round(num_sub/2));
nrBS = min([100, size(C,1)]);

val        = nan(length(dels),1);
val_err    = nan(length(dels),1);
number_img = nan(nrBS, length(dels));

for xx = 1:length(dels)

    mean_eff = nan(nrBS,1);
    num      = nan(nrBS,1);

    for i = 1:nrBS

        l1 = C(i,:);
        l2 = setdiff(1:num_sub, l1);

        del = abs( ...
            nanmean(nt(:,l1),2) - ...
            nanmean(asd(:,l1),2) );

        ll = find(del > dels(xx));

        eff = abs( ...
            nanmean(nt(ll,l2),2) - ...
            nanmean(asd(ll,l2),2) );

        mean_eff(i) = mean(eff);
        num(i) = numel(find(eff > dels(xx)));

        number_img(i,xx) = num(i);
    end

    val(xx)     = nanmean(mean_eff);
    val_err(xx) = local_mad_matlab(mean_eff, [], 1);
end
end


function idx = local_randsample(n, k, replace)
% Use randsample if available, otherwise randperm.
if nargin < 3
    replace = false;
end

if exist('randsample', 'file') == 2
    idx = randsample(n, k, replace);
else
    if replace
        idx = randi(n, k, 1);
    else
        idx = randperm(n, k);
    end
end
end


function out = local_mad_matlab(x, flag, dim)
% Use MATLAB mad if available; fall back to median absolute deviation.
if nargin < 2
    flag = [];
end
if nargin < 3
    dim = 1;
end

try
    out = mad(x, flag, dim);
catch
    med = median(x, dim, 'omitnan');
    out = median(abs(x - med), dim, 'omitnan');
end
end

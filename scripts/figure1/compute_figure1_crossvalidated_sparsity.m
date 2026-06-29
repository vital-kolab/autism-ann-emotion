function [summaryTable, bootTable] = compute_figure1_crossvalidated_sparsity(dels, nt, asd, im_loc, opts)
% compute_figure1_crossvalidated_sparsity
% -------------------------------------------------------------------------
% Cross-validated image-selection analysis for Figure 1.
%
% This version intentionally accepts OPTS as a 5th positional struct:
%
%   [summaryTable, bootTable] = compute_figure1_crossvalidated_sparsity( ...
%       dels, nt, asd, im_loc, opts);
%
% It also works if OPTS is omitted.
%
% For each behavioral-difference threshold:
%   1. Split subjects into selection and held-out sets.
%   2. Select images whose NT-ASD difference exceeds threshold in selection set.
%   3. Evaluate behavioral difference in held-out subjects.
%   4. Count held-out images still exceeding the threshold.
%
% INPUTS
%   dels   : vector of selection thresholds
%   nt     : image x subject matrix for neurotypical group
%   asd    : image x subject matrix for autistic group
%   im_loc : logical vector selecting image rows
%   opts   : optional struct with fields:
%            nBoot, maxSubjectsPerGroup, useMAD, rngSeed
%
% OUTPUTS
%   summaryTable : one row per threshold
%   bootTable    : one row per bootstrap split x threshold
% -------------------------------------------------------------------------

%% Defaults
if nargin < 5 || isempty(opts)
    opts = struct;
end
if ~isfield(opts, 'nBoot'); opts.nBoot = 1000; end
if ~isfield(opts, 'maxSubjectsPerGroup'); opts.maxSubjectsPerGroup = 20; end
if ~isfield(opts, 'useMAD'); opts.useMAD = true; end
if ~isfield(opts, 'rngSeed'); opts.rngSeed = 1; end

dels = dels(:);

if nargin < 4 || isempty(im_loc)
    im_loc = true(size(nt,1),1);
end
im_loc = logical(im_loc(:));

rng(opts.rngSeed);

%% Restrict images
nt = nt(im_loc,:);
asd = asd(im_loc,:);

nImg = size(nt,1);
num_sub1 = size(nt,2);
num_sub2 = size(asd,2);

% Use equal subject count across groups.
num_sub = min([opts.maxSubjectsPerGroup, num_sub1, num_sub2]);

nt = nt(:,1:num_sub);
asd = asd(:,1:num_sub);

nSelect = round(num_sub/2);

%% Generate random half-splits
% Use randperm rather than randsample to avoid requiring Statistics Toolbox.
ntSelect  = nan(opts.nBoot, nSelect);
asdSelect = nan(opts.nBoot, nSelect);

for b = 1:opts.nBoot
    ntSelect(b,:)  = randperm(num_sub, nSelect);
    asdSelect(b,:) = randperm(num_sub, nSelect);
end

%% Main bootstrap loop
bootRows = table;

for d = 1:numel(dels)

    threshold = dels(d);

    for b = 1:opts.nBoot

        nt_l1  = ntSelect(b,:);
        asd_l1 = asdSelect(b,:);

        nt_l2  = setdiff(1:num_sub, nt_l1);
        asd_l2 = setdiff(1:num_sub, asd_l1);

        % Selection split effect.
        delta_select = abs( ...
            mean(nt(:,nt_l1),2,'omitnan') - ...
            mean(asd(:,asd_l1),2,'omitnan'));

        selectedImages = find(delta_select > threshold);

        % Held-out effect on selected images.
        if isempty(selectedImages)
            meanHeldoutEffect = NaN;
            nHeldoutDiscriminative = 0;
        else
            heldoutEffects = abs( ...
                mean(nt(selectedImages,nt_l2),2,'omitnan') - ...
                mean(asd(selectedImages,asd_l2),2,'omitnan'));

            meanHeldoutEffect = mean(heldoutEffects,'omitnan');
            nHeldoutDiscriminative = sum(heldoutEffects > threshold);
        end

        bootRows = [bootRows; table( ...
            threshold, b, numel(selectedImages), ...
            meanHeldoutEffect, nHeldoutDiscriminative, ...
            'VariableNames', {'Threshold','Bootstrap','NSelectedTrain', ...
            'MeanHeldoutEffect','NHeldoutDiscriminative'})]; %#ok<AGROW>
    end
end

bootTable = bootRows;

%% Summarize by threshold
summaryTable = table;

for d = 1:numel(dels)
    threshold = dels(d);
    rows = bootTable(bootTable.Threshold == threshold, :);

    x = rows.MeanHeldoutEffect;
    y = rows.NHeldoutDiscriminative;

    if opts.useMAD
        effectErr = local_mad(x);
        countErr = local_mad(y);
    else
        effectErr = std(x, 'omitnan');
        countErr = std(y, 'omitnan');
    end

    summaryTable = [summaryTable; table( ...
        threshold, ...
        mean(x,'omitnan'), effectErr, ...
        mean(y,'omitnan'), std(y,'omitnan'), countErr, ...
        median(y,'omitnan'), ...
        'VariableNames', {'SelectionThreshold','MeanHeldoutEffect', ...
        'HeldoutEffectErr','MeanNDiscriminativeImages','StdNDiscriminativeImages', ...
        'RobustNDiscriminativeImagesErr','MedianNDiscriminativeImages'})]; %#ok<AGROW>
end

%% Store correlation summary
x = summaryTable.MeanHeldoutEffect;
y = summaryTable.MeanNDiscriminativeImages;
valid = isfinite(x) & isfinite(y) & x > 0 & y > 0;

if sum(valid) >= 3
    [r,p] = corr(x(valid), y(valid), 'Rows','complete', 'Type','Pearson');
else
    r = NaN;
    p = NaN;
end

summaryTable.PearsonR_allRows = repmat(r, height(summaryTable), 1);
summaryTable.PearsonP_allRows = repmat(p, height(summaryTable), 1);
summaryTable.NImagesTotal = repmat(nImg, height(summaryTable), 1);
summaryTable.NSubjectsPerGroupUsed = repmat(num_sub, height(summaryTable), 1);
summaryTable.NBootstrap = repmat(opts.nBoot, height(summaryTable), 1);

end

function m = local_mad(x)
% Median absolute deviation, NaN-safe, without relying on the Statistics Toolbox.
x = x(:);
x = x(isfinite(x));
if isempty(x)
    m = NaN;
else
    medx = median(x);
    m = median(abs(x - medx));
end
end

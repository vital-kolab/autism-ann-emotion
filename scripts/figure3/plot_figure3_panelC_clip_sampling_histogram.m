function fig = plot_figure3_panelC_clip_sampling_histogram(dataDir, outDir)
% Panel C: Random versus CLIP-selected sampling distributions.
% -------------------------------------------------------------------------
% This panel now uses the SAME selected-image definition as Figure 3B.
%
% Critical point:
%   Figure 3B's CLIP mean is about 0.15 because it uses the CLIP-selected
%   top image set, not the broader top-40% pool. Therefore Panel C must use
%   that same selected-image mask before making the histogram.
%
% Selection priority:
%   1. If the table contains is_clip_selected_top20pct, use that exact mask.
%      This is the curated mask used to reproduce Figure 3B.
%   2. Otherwise, compute delta_pred = abs(init_ctrl_score - init_asd_score)
%      or use clip_pred_delta_abs, and select images above the 80th percentile
%      (top 20%), matching the Figure 3B CLIP-selected set size.
%
% Histogram logic:
%   For each iteration, draw half of the CLIP-selected image pool and the
%   same number of random images from all 80 images. Plot the distributions
%   of the resulting mean observed behavioral gaps.
%
% Expected means with the curated data:
%   Random image sets:       ~0.09
%   CLIP-selected image sets: ~0.15
% -------------------------------------------------------------------------

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

rng(1);

clipFile = fullfile(dataDir, 'clip_scores.csv');
summaryTableFile = fullfile(dataDir, 'figure3_panelC_clip_imagelevel.csv');

if exist(clipFile, 'file')
    t3 = readtable(clipFile);
elseif exist(summaryTableFile, 'file')
    t3 = readtable(summaryTableFile);
else
    error('Could not find clip_scores.csv or figure3_panelC_clip_imagelevel.csv in %s', dataDir);
end

vars = string(t3.Properties.VariableNames);

% Observed behavioral gap.
if ~all(ismember(["true_ctrl_score","true_asd_score"], vars))
    error('Need true_ctrl_score and true_asd_score.');
end
true_gap = abs(t3.true_ctrl_score - t3.true_asd_score);

% Use the exact Figure 3B CLIP-selected image mask when available.
if ismember("is_clip_selected_top20pct", vars)
    im_loc = local_to_logical(t3.is_clip_selected_top20pct);
    selectionLabel = 'curated Figure 3B top-20% CLIP mask';
else
    % Fall back to predicted CLIP diagnostic score and select top 20%.
    if all(ismember(["init_ctrl_score","init_asd_score"], vars))
        delta_pred = abs(t3.init_ctrl_score - t3.init_asd_score);
    elseif ismember("clip_pred_delta_abs", vars)
        delta_pred = abs(t3.clip_pred_delta_abs);
    else
        error('Need init_ctrl_score/init_asd_score, clip_pred_delta_abs, or is_clip_selected_top20pct.');
    end

    threshold = local_prctile(delta_pred, 80);  % top 20%, to match Figure 3B
    im_loc = delta_pred > threshold;
    selectionLabel = 'top 20% by predicted CLIP gap';
end

selectedPool = find(im_loc);

nImages = height(t3);
nIter = 50;

% This preserves your resampling logic while using the correct Figure 3B
% selected pool. The expected CLIP histogram mean remains the selected-pool
% mean, ~0.15 for the curated data.
nDraw = round(numel(selectedPool) / 2);

if nDraw < 1
    error('Selection pool is too small.');
end

targ_eff = nan(nIter,1);
rand_eff = nan(nIter,1);

for i = 1:nIter
    val_loc  = selectedPool(randperm(numel(selectedPool), nDraw));
    rand_loc = randperm(nImages, nDraw);

    targ_eff(i,1) = mean(true_gap(val_loc), 'omitnan');
    rand_eff(i,1) = mean(true_gap(rand_loc), 'omitnan');
end

uplift = targ_eff - rand_eff;

% Save iteration and summary tables.
iterTable = table((1:nIter)', rand_eff, targ_eff, uplift, ...
    'VariableNames', {'Iteration','RandomEffect','CLIPSelectedEffect','SelectionUplift'});
writetable(iterTable, fullfile(outDir, 'Figure3C_random_vs_clip_histogram_iterations.csv'));

meanRand = mean(rand_eff, 'omitnan');
meanClip = mean(targ_eff, 'omitnan');
semRand  = local_sem(rand_eff);
semClip  = local_sem(targ_eff);
meanUplift = mean(uplift, 'omitnan');
semUplift  = local_sem(uplift);

try
    [~, pRight, ~, stats] = ttest(uplift, 0, 'Tail', 'right');
    tVal = stats.tstat;
    df = stats.df;
catch
    pRight = NaN;
    tVal = NaN;
    df = nIter - 1;
end

pSignFlip = signflip_p(uplift, 10000);

summaryTable = table(nImages, numel(selectedPool), nDraw, nIter, ...
    meanRand, semRand, meanClip, semClip, meanUplift, semUplift, ...
    tVal, df, pRight, pSignFlip, string(selectionLabel), ...
    'VariableNames', {'NImages','NSelectedPool','NDrawPerIteration','NIterations', ...
    'RandomMean','RandomSEM','CLIPMean','CLIPSEM','UpliftMean','UpliftSEM', ...
    't','df','pRight','pSignFlip','SelectionRule'});
writetable(summaryTable, fullfile(outDir, 'Figure3C_random_vs_clip_histogram_summary.csv'));

fprintf('\nFigure 3C check:\n');
fprintf('  Selection rule: %s\n', selectionLabel);
fprintf('  Selected pool N: %d; draw per iteration N: %d\n', numel(selectedPool), nDraw);
fprintf('  Random mean: %.4f\n', meanRand);
fprintf('  CLIP mean:   %.4f\n', meanClip);

% Histogram bins shared across random and CLIP distributions.
allVals = [rand_eff(:); targ_eff(:)];
binEdges = linspace(min(allVals), max(allVals), 12);

fig = figure('Position', [100 100 580 430]);
hold on;

histogram(rand_eff, binEdges, ...
    'Normalization', 'probability', ...
    'FaceColor', [0.70 0.70 0.70], ...
    'FaceAlpha', 0.65, ...
    'EdgeColor', [0.25 0.25 0.25], ...
    'LineWidth', 0.8);

histogram(targ_eff, binEdges, ...
    'Normalization', 'probability', ...
    'DisplayStyle', 'stairs', ...
    'EdgeColor', [0 0 0], ...
    'LineWidth', 2.0);

% Mean markers.
yl = ylim;
plot([meanRand meanRand], yl, '--', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.3);
plot([meanClip meanClip], yl, '-', 'Color', [0 0 0], 'LineWidth', 1.6);
ylim(yl);

xlabel('Mean behavioral separation |ASD - NT|');
ylabel('Proportion of resamples');
box off;
set(gca, 'LineWidth', 1.2, 'FontSize', 12);

legend({'Random image sets','CLIP-selected image sets','Random mean','CLIP mean'}, ...
    'Location','northwest', 'Box','off');

title('C. Random vs. CLIP-selected image sets', 'FontWeight','bold');

txt = sprintf('Random = %.3f \\pm %.3f SEM\\nCLIP = %.3f \\pm %.3f SEM\\n\\Delta = %.3f, p = %.3g', ...
    meanRand, semRand, meanClip, semClip, meanUplift, pSignFlip);
text(0.98, 0.95, txt, 'Units','normalized', ...
    'HorizontalAlignment','right', 'VerticalAlignment','top', ...
    'FontSize', 9);

saveFigure(fig, outDir, 'Figure3C_random_vs_clip_histogram');

end


function y = local_to_logical(x)
% Convert numeric/logical/string/cell truth values to logical vector.
% Handles CSV columns read as true/false, TRUE/FALSE, 1/0, or cells.
if islogical(x)
    y = x;
elseif isnumeric(x)
    y = x ~= 0;
elseif iscell(x)
    y = false(size(x));
    for ii = 1:numel(x)
        v = x{ii};
        if islogical(v)
            y(ii) = v;
        elseif isnumeric(v)
            y(ii) = v ~= 0;
        else
            s = lower(strtrim(string(v)));
            y(ii) = any(strcmp(s, ["true","t","1","yes","y"]));
        end
    end
elseif isstring(x) || ischar(x)
    s = lower(strtrim(string(x)));
    y = ismember(s, ["true","t","1","yes","y"]);
else
    error('Cannot convert is_clip_selected_top20pct column to logical.');
end
y = y(:);
end


function q = local_prctile(x, pct)
% Percentile without Statistics Toolbox.
x = x(:);
x = x(isfinite(x));
if isempty(x)
    q = NaN;
    return;
end
x = sort(x);
if numel(x) == 1
    q = x;
    return;
end
pos = 1 + (pct/100) * (numel(x)-1);
lo = floor(pos);
hi = ceil(pos);
if lo == hi
    q = x(lo);
else
    q = x(lo) + (pos-lo) * (x(hi)-x(lo));
end
end

function s = local_sem(x)
x = x(:);
x = x(isfinite(x));
if numel(x) <= 1
    s = NaN;
else
    s = std(x) ./ sqrt(numel(x));
end
end

function p = signflip_p(x, nPerm)
x = x(:);
x = x(isfinite(x));
if isempty(x)
    p = NaN;
    return;
end
obs = mean(x, 'omitnan');
nullVals = nan(nPerm,1);
for b = 1:nPerm
    signs = randi([0 1], numel(x), 1);
    signs(signs == 0) = -1;
    nullVals(b) = mean(x .* signs, 'omitnan');
end
p = (1 + sum(nullVals >= obs)) ./ (nPerm + 1);
end

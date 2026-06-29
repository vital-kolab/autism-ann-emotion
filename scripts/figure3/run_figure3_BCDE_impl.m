%% run_figure3_BCDE.m
% -------------------------------------------------------------------------
% Regenerate Figure 3 panels B-E from curated summary data.
%
% This repository intentionally includes only numerical summary tables
% needed for the plotted panels. It does not include raw trial-level
% participant data, face stimuli, or model checkpoints.
%
% Panels:
%   B: ANN-selected versus random image-set diagnostic power
%   C: CLIP-selected image-level behavioral difference distribution
%   D: Model NT alignment versus selected diagnostic power
%   E: Sparsity of diagnostic image effects
% -------------------------------------------------------------------------

clear; clc; close all;

thisFile = mfilename('fullpath');
scriptDir = fileparts(thisFile);
rootDir = fileparts(fileparts(scriptDir));

addpath(genpath(fullfile(rootDir, 'scripts')));

dataDir = fullfile(rootDir, 'data', 'curated');
outPanelDir = fullfile(rootDir, 'outputs', 'figure3_panels');
outCombinedDir = fullfile(rootDir, 'outputs', 'figure3_combined');

if ~exist(outPanelDir, 'dir'); mkdir(outPanelDir); end
if ~exist(outCombinedDir, 'dir'); mkdir(outCombinedDir); end

fprintf('\nRegenerating Figure 3 panels B-E from curated data...\n');

figB = plot_figure3_panelB_model_comparison(dataDir, outPanelDir);
figC = plot_figure3_panelC_clip_sampling_histogram(dataDir, outPanelDir);
figD = plot_figure3_panelD_alignment(dataDir, outPanelDir);
figE = plot_figure3_panelE_sparsity(dataDir, outPanelDir);

%% Combined layout
T = readtable(fullfile(dataDir, 'figure3_panelB_D_model_selection.csv'));
H = readtable(fullfile(dataDir, 'figure3_panelC_clip_histogram.csv'));
C = readtable(fullfile(dataDir, 'figure3_panelD_model_correlations.csv'));
S = readtable(fullfile(dataDir, 'figure3_panelE_sparsity_thresholds.csv'));

fig = figure('Position', [100 100 1250 900]);
tiledlayout(2,2, 'Padding','compact', 'TileSpacing','compact');

%% B
nexttile; hold on;
x = 1:height(T);
for i = 1:height(T)
    plot([x(i) x(i)], [T.random_gap_mean(i), T.selected_gap_mean(i)], '-', ...
        'Color', [0.60 0.60 0.60], 'LineWidth', 1.2);
end
errorbar(x, T.random_gap_mean, T.random_gap_sem, 'o', ...
    'Color', [0.25 0.25 0.25], 'MarkerFaceColor',[0.70 0.70 0.70], ...
    'LineWidth', 1.0, 'CapSize',0, 'MarkerSize',5);
errorbar(x, T.selected_gap_mean, T.selected_gap_sem, 'o', ...
    'Color', [0 0 0], 'MarkerFaceColor','w', ...
    'LineWidth', 1.0, 'CapSize',0, 'MarkerSize',5);
for i = 1:height(T)
    if ismember('top_full_p', T.Properties.VariableNames) && T.top_full_p(i) < 0.05
        yy = max([T.random_gap_mean(i)+T.random_gap_sem(i), T.selected_gap_mean(i)+T.selected_gap_sem(i)]);
        text(x(i), yy + 0.012, '*', 'HorizontalAlignment','center', 'FontSize',14, 'FontWeight','bold');
    end
end
set(gca, 'XTick', x, 'XTickLabel', string(T.model), 'XTickLabelRotation', 35);
ylabel('|ASD - NT|'); xlabel('ANN architecture');
title('B. ANN-selected vs. random', 'FontWeight','bold'); box off;

%% C
nexttile; hold on;
% Combined-layout version of Panel C, using the same CLIP-selected mask as Figure 3B.
clipFile = fullfile(dataDir, 'clip_scores.csv');
summaryTableFile = fullfile(dataDir, 'figure3_panelC_clip_imagelevel.csv');
if exist(clipFile, 'file')
    t3 = readtable(clipFile);
else
    t3 = readtable(summaryTableFile);
end
vars = string(t3.Properties.VariableNames);
true_gap = abs(t3.true_ctrl_score - t3.true_asd_score);

if ismember("is_clip_selected_top20pct", vars)
    im_loc = local_to_logical_combined(t3.is_clip_selected_top20pct);
else
    if all(ismember(["init_ctrl_score","init_asd_score"], vars))
        delta_pred = abs(t3.init_ctrl_score - t3.init_asd_score);
    else
        delta_pred = abs(t3.clip_pred_delta_abs);
    end
    im_loc = delta_pred > local_prctile_combined(delta_pred, 80);
end

selectedPool = find(im_loc);
nDraw = round(numel(selectedPool)/2);
nIter = 50;
rand_eff = nan(nIter,1);
targ_eff = nan(nIter,1);

rng(1);
for ii = 1:nIter
    val_loc  = selectedPool(randperm(numel(selectedPool), nDraw));
    rand_loc = randperm(height(t3), nDraw);
    targ_eff(ii) = mean(true_gap(val_loc), 'omitnan');
    rand_eff(ii) = mean(true_gap(rand_loc), 'omitnan');
end

allVals = [rand_eff(:); targ_eff(:)];
binEdges = linspace(min(allVals), max(allVals), 12);

histogram(rand_eff, binEdges, ...
    'Normalization','probability', ...
    'FaceColor',[0.70 0.70 0.70], ...
    'FaceAlpha',0.65, ...
    'EdgeColor',[0.25 0.25 0.25], ...
    'LineWidth',0.8);

histogram(targ_eff, binEdges, ...
    'Normalization','probability', ...
    'DisplayStyle','stairs', ...
    'EdgeColor',[0 0 0], ...
    'LineWidth',2.0);

yl = ylim;
plot([mean(rand_eff,'omitnan') mean(rand_eff,'omitnan')], yl, '--', 'Color',[0.35 0.35 0.35], 'LineWidth',1.1);
plot([mean(targ_eff,'omitnan') mean(targ_eff,'omitnan')], yl, '-', 'Color',[0 0 0], 'LineWidth',1.4);
ylim(yl);

xlabel('Mean |ASD - NT|');
ylabel('Proportion of resamples');
title(sprintf('C. Random %.2f vs CLIP %.2f', mean(rand_eff,'omitnan'), mean(targ_eff,'omitnan')), 'FontWeight','bold');
box off;

%% D
nexttile; hold on;
xx = T.nt_alignment_all_r;
yy = T.selected_gap_mean;
plot(xx, yy, 'ko', 'MarkerFaceColor',[0.70 0.70 0.70], 'MarkerSize',6);
for i = 1:numel(xx)
    text(xx(i), yy(i), " " + string(T.model{i}), 'FontSize',8);
end
good = isfinite(xx) & isfinite(yy);
if sum(good) >= 2
    pfit = polyfit(xx(good), yy(good), 1);
    xlinefit = linspace(min(xx(good)), max(xx(good)), 100);
    ylinefit = polyval(pfit, xlinefit);
    plot(xlinefit, ylinefit, 'k-', 'LineWidth',1.3);
end
idx = find(strcmp(string(C.y), 'selected_gap_median') | strcmp(string(C.y), 'top_full_gap_mean'), 1, 'first');
if isempty(idx); idx = 1; end
text(0.05, 0.95, sprintf('r = %.2f, p = %.3g', C.pearson_r(idx), C.pearson_p(idx)), ...
    'Units','normalized', 'VerticalAlignment','top', 'FontSize',9);
xlabel('NT behavioral alignment');
ylabel('Selected |ASD - NT|');
title('D. Alignment predicts selection', 'FontWeight','bold'); box off;

%% E
nexttile; hold on;

% Use manuscript-recomputed data saved by plot_figure3_panelE_sparsity above.
curveFile = fullfile(dataDir, 'figure3_panelE_exact_curve_from_analysis.csv');
annFile   = fullfile(dataDir, 'figure3_panelE_exact_ann_point_from_analysis.csv');

if ~exist(curveFile, 'file') || ~exist(annFile, 'file')
    error('Exact Figure 3E files were not created. Check raw Fig2_data files.');
end

SE = readtable(curveFile);
AE = readtable(annFile);

sx = SE.MeanEffect(:);
sy = SE.MeanNDiscriminativeImages(:);
sxerr = SE.EffectMAD(:);
syerr = SE.NImagesMAD(:);

errorbar(sx, sy, syerr, 'ko', 'capsize', 0);
errorbar(sx, sy, sxerr, 'ko', 'horizontal', 'capsize', 0);

expDecay = fittype('a*exp(b*x) + c', 'independent', 'x');
fitresult = fit(sx, sy, expDecay, 'StartPoint', [20, -10, 0]);
x_fit = linspace(min(sx), max(sx), 100);
y_fit = fitresult.a * exp(fitresult.b * x_fit) + fitresult.c;
plot(x_fit, y_fit, 'k-', 'LineWidth', 2);

rx = AE.AnnEffect(1);
ry = AE.AnnNDiscriminativeImages(1);
rxerr = AE.AnnEffectMAD(1);
ryerr = AE.AnnNImagesMAD(1);

errorbar(rx, ry, ryerr, 'ro', 'capsize', 0);
errorbar(rx, ry, rxerr, 'ro', 'horizontal', 'capsize', 0);

xlabel('\Delta Behavior');
ylabel('Num images');
set(gca, 'xscale', 'log', 'yscale', 'linear');
title('E. Sparse diagnostic effects', 'FontWeight','bold'); box off;

set(findall(fig, '-property', 'LineWidth'), 'LineWidth', 1.1);
set(findall(fig, '-property', 'FontSize'), 'FontSize', 11);

saveFigure(fig, outCombinedDir, 'Figure3_BCDE_combined');

fprintf('\nSaved panel outputs to:\n  %s\n', outPanelDir);
fprintf('Saved combined output to:\n  %s\n', outCombinedDir);


function y = local_to_logical_combined(x)
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
    error('Cannot convert logical mask column.');
end
y = y(:);
end

function q = local_prctile_combined(x, pct)
x = x(:);
x = x(isfinite(x));
x = sort(x);
if isempty(x)
    q = NaN;
    return;
end
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

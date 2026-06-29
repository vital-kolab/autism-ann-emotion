function fig = plot_figure4B_paired_gap_reduction(dataDir, outDir)
% plot_figure4B_paired_gap_reduction
% -------------------------------------------------------------------------
% Regenerates Figure 4B from curated image-level phenotype-matched data.
%
% Positive reduction means:
%   BaseGap - SynthGap > 0
%
% Primary data are from leave-one-image-out correlation-based phenotype
% matching. This is the current Figure 4B analysis:
%
%   Base gap mean  ≈ 0.138
%   Synth gap mean ≈ 0.076
%   Gap reduction  ≈ 0.062 ± 0.026 SEM
% -------------------------------------------------------------------------

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

T = readtable(fullfile(dataDir, 'figure4B_phenotype_matched_corr_imagelevel.csv'));

baseGap  = T.BaseGap(:);
synthGap = T.SynthGap(:);
effect   = T.GapReduction(:);

stats = reportEffect(effect);

% Save stats table recalculated from image-level data
summary = table( ...
    numel(effect), ...
    mean(baseGap,'omitnan'), localSEM(baseGap), ...
    mean(synthGap,'omitnan'), localSEM(synthGap), ...
    stats.mean, stats.sem, stats.median, stats.positive, ...
    stats.t, stats.df, stats.pRight, stats.pSignFlip, ...
    'VariableNames', {'N','BaseGapMean','BaseGapSEM','SynthGapMean','SynthGapSEM', ...
    'GapReductionMean','GapReductionSEM','GapReductionMedian','NPositive', ...
    't','df','pRight','pSignFlip'});
writetable(summary, fullfile(outDir, 'Figure4B_recomputed_summary.csv'));

fig = figure('Position', [100 100 520 470]);
hold on;

% Individual image-pair lines
for i = 1:numel(baseGap)
    plot([1 2], [baseGap(i) synthGap(i)], '-o', ...
        'Color', [0.58 0.58 0.58], ...
        'MarkerFaceColor', [0.78 0.78 0.78], ...
        'MarkerEdgeColor', 'k', ...
        'MarkerSize', 5, ...
        'LineWidth', 1.0);
end

% Mean ± SEM overlay
m = [mean(baseGap,'omitnan'), mean(synthGap,'omitnan')];
e = [localSEM(baseGap), localSEM(synthGap)];

errorbar([1 2], m, e, 'ko-', ...
    'LineWidth', 2.5, ...
    'MarkerFaceColor', 'k', ...
    'MarkerSize', 7, ...
    'CapSize', 0);

xlim([0.7 2.3]);
ylim([0 max([baseGap(:); synthGap(:)]) * 1.25]);

set(gca, 'XTick', [1 2], ...
    'XTickLabel', {'Diagnostic base','Gap-reduced synth'}, ...
    'LineWidth', 1.2, ...
    'FontSize', 12);

ylabel('|ASD - NT|');
title('Figure 4B. Gap-reducing synthesis', 'FontWeight','bold');
box off;

txt = sprintf(['base = %.3f, synth = %.3f\n' ...
               'reduction = %.3f \\pm %.3f SEM\n' ...
               '%d/%d images reduced, p = %.3g'], ...
    m(1), m(2), stats.mean, stats.sem, stats.positive, stats.n, stats.pSignFlip);

text(0.05, 0.96, txt, ...
    'Units','normalized', ...
    'VerticalAlignment','top', ...
    'FontSize', 10);


fprintf('\nFigure 4B check:\n');
fprintf('  Base gap mean:  %.4f\n', m(1));
fprintf('  Synth gap mean: %.4f\n', m(2));
fprintf('  Reduction:      %.4f +/- %.4f SEM\n', stats.mean, stats.sem);
fprintf('  Positive:       %d / %d\n', stats.positive, stats.n);
fprintf('  Sign-flip p:    %.4g\n', stats.pSignFlip);

end

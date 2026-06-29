function fig = plot_figure3_panelD_alignment(dataDir, outDir)
% Panel D: Model NT alignment predicts selected diagnostic power.
T = readtable(fullfile(dataDir, 'figure3_panelB_D_model_selection.csv'));
C = readtable(fullfile(dataDir, 'figure3_panelD_model_correlations.csv'));

x = T.nt_alignment_all_r;
y = T.selected_gap_mean;
models = string(T.model);

fig = figure('Position', [100 100 560 460]);
hold on;

plot(x, y, 'ko', ...
    'MarkerFaceColor', [0.70 0.70 0.70], ...
    'MarkerSize', 7, ...
    'LineWidth', 1.0);

for i = 1:numel(x)
    text(x(i), y(i), " " + models(i), 'FontSize', 9);
end

% Linear fit for visualization.
good = isfinite(x) & isfinite(y);
if sum(good) >= 2
    p = polyfit(x(good), y(good), 1);
    xx = linspace(min(x(good)), max(x(good)), 100);
    yy = polyval(p, xx);
    plot(xx, yy, 'k-', 'LineWidth', 1.5);
end

% Stats from curated table.
idx = find(strcmp(string(C.y), 'selected_gap_median') | strcmp(string(C.y), 'top_full_gap_mean'), 1, 'first');
if isempty(idx)
    idx = 1;
end

txt = sprintf('r = %.2f, p = %.3g\\n\\rho = %.2f, p = %.3g', ...
    C.pearson_r(idx), C.pearson_p(idx), ...
    C.spearman_rho(idx), C.spearman_p(idx));

text(0.05, 0.95, txt, 'Units','normalized', ...
    'VerticalAlignment','top', 'FontSize', 10);

xlabel('Model alignment with NT behavior');
ylabel('Selected image-set |ASD - NT|');
box off;
set(gca, 'LineWidth', 1.2, 'FontSize', 12);
title('D. Behavioral alignment predicts diagnostic selection', 'FontWeight','bold');

saveFigure(fig, outDir, 'Figure3D_alignment');
end

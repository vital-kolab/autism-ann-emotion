function fig = plot_figure3_panelB_model_comparison(dataDir, outDir)
% Panel B: ANN-selected versus random image-set diagnostic power.
T = readtable(fullfile(dataDir, 'figure3_panelB_D_model_selection.csv'));

models = string(T.model);
x = 1:height(T);

fig = figure('Position', [100 100 760 430]);
hold on;

for i = 1:height(T)
    plot([x(i) x(i)], [T.random_gap_mean(i), T.selected_gap_mean(i)], '-', ...
        'Color', [0.60 0.60 0.60], 'LineWidth', 1.5);
end

% Random baseline
errorbar(x, T.random_gap_mean, T.random_gap_sem, 'o', ...
    'Color', [0.25 0.25 0.25], ...
    'MarkerFaceColor', [0.70 0.70 0.70], ...
    'MarkerEdgeColor', [0.25 0.25 0.25], ...
    'LineWidth', 1.2, ...
    'CapSize', 0, ...
    'MarkerSize', 6);

% ANN-selected
errorbar(x, T.selected_gap_mean, T.selected_gap_sem, 'o', ...
    'Color', [0 0 0], ...
    'MarkerFaceColor', 'w', ...
    'MarkerEdgeColor', [0 0 0], ...
    'LineWidth', 1.2, ...
    'CapSize', 0, ...
    'MarkerSize', 6);

% Stars for model-wise empirical comparisons, if p < .05.
for i = 1:height(T)
    if ismember('top_full_p', T.Properties.VariableNames) && T.top_full_p(i) < 0.05
        yy = max([T.random_gap_mean(i)+T.random_gap_sem(i), T.selected_gap_mean(i)+T.selected_gap_sem(i)]);
        text(x(i), yy + 0.012, '*', 'HorizontalAlignment','center', ...
            'FontSize', 16, 'FontWeight','bold');
    end
end

xlim([0.5 height(T)+0.5]);
ylim([0 max([T.random_gap_mean+T.random_gap_sem; T.selected_gap_mean+T.selected_gap_sem])*1.22]);
set(gca, 'XTick', x, 'XTickLabel', models, 'XTickLabelRotation', 35);
ylabel('Behavioral separation |ASD - NT|');
xlabel('ANN architecture ordered by NT alignment');
box off;
set(gca, 'LineWidth', 1.2, 'FontSize', 12);

legend({'paired model comparison','random image sets','ANN-selected image sets'}, ...
    'Location','northwest', 'Box','off');

title('B. ANN-selected versus random image sets', 'FontWeight','bold');

saveFigure(fig, outDir, 'Figure3B_model_selection');
end

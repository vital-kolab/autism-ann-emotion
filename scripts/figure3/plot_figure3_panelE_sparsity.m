function fig = plot_figure3_panelE_sparsity(dataDir, outDir)
% Figure 3E analysis.
%
% This script intentionally does NOT use curated summary table data because the
% manuscript panel depends on the raw nt/asd matrices and ANN scores.

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% The analysis workflow overwrites CLIP with ViT before delta_pred is used.
% Keep 'vit' to reproduce the manuscript figure. Change to 'clip' only if desired.
modelForPanelE = 'vit';

% Resolve paperDir automatically. To force a path, replace [] with:
% pwd
[curveTable, annTable] = compute_figure3E_analysis_exact([], modelForPanelE);

% Save recomputed numerical data.
writetable(curveTable, fullfile(dataDir, 'figure3_panelE_exact_curve_from_analysis.csv'));
writetable(annTable, fullfile(dataDir, 'figure3_panelE_exact_ann_point_from_analysis.csv'));

x = curveTable.MeanEffect(:);
y = curveTable.MeanNDiscriminativeImages(:);
xerr = curveTable.EffectMAD(:);
yerr = curveTable.NImagesMAD(:);

% Fit only the black curve.
expDecay = fittype('a*exp(b*x) + c', 'independent', 'x');
[fitresult, gof] = fit(x, y, expDecay, 'StartPoint', [20, -10, 0]); %#ok<ASGLU>

x_fit = linspace(min(x), max(x), 100);
y_fit = fitresult.a * exp(fitresult.b * x_fit) + fitresult.c;

fig = figure('Position', [100 100 520 480]);
hold on;

% Black random-subset points and error bars.
errorbar(x, y, yerr, 'ko', 'capsize', 0);
errorbar(x, y, xerr, 'ko', 'horizontal', 'capsize', 0);

% Red ANN-optimized point.
rx = annTable.AnnEffect(1);
ry = annTable.AnnNDiscriminativeImages(1);
rxerr = annTable.AnnEffectMAD(1);
ryerr = annTable.AnnNImagesMAD(1);

errorbar(rx, ry, ryerr, 'ro', 'capsize', 0);
errorbar(rx, ry, rxerr, 'ro', 'horizontal', 'capsize', 0);

plot(x_fit, y_fit, 'k-', 'LineWidth', 2);

xlabel('\Delta Behavior');
ylabel('Num discriminative images');
set(gca, 'xscale', 'log');
set(gca, 'yscale', 'linear');
box off;
set(gca, 'LineWidth', 1.2, 'FontSize', 12);
title('E. Sparse diagnostic effects', 'FontWeight','bold');

fprintf('\nFigure 3E analysis\n');
fprintf('  Model for red point: %s\n', annTable.ModelForPanelE(1));
fprintf('  Red point x = %.4f\n', rx);
fprintf('  Red point y = %.4f\n', ry);
fprintf('  Red xerr = %.4f\n', rxerr);
fprintf('  Red yerr = %.4f\n', ryerr);
fprintf('  Selected images = %d\n', annTable.NSelected(1));

saveFigure(fig, outDir, 'Figure3E_sparsity');

end

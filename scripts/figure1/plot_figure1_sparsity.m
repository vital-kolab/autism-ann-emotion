function plot_figure1_sparsity(S, outDir)
% plot_figure1_sparsity
% -------------------------------------------------------------------------
% Recreates Figure 1 sparsity panel from summary table.
% -------------------------------------------------------------------------

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

x = S.MeanHeldoutEffect(:);
y = S.MeanNDiscriminativeImages(:);
yerr = S.StdNDiscriminativeImages(:);
xerr = S.HeldoutEffectErr(:);

valid = isfinite(x) & isfinite(y) & x > 0 & y > 0;

xv = x(valid);
yv = y(valid);

% Exponential fit: y = a*exp(b*x) + c
[xfit, yfit, fitInfo] = fit_exp_decay_summary_table(xv, yv);

fig = figure('Position', [100 100 520 430]);
hold on;

% Vertical error bars for image counts.
errorbar(x, y, yerr, 'ko', ...
    'MarkerFaceColor', [0.70 0.70 0.70], ...
    'MarkerSize', 6, ...
    'LineWidth', 1.2, ...
    'CapSize', 0);

% Horizontal error bars for held-out effect variability.
draw_horizontal_errorbars(x, y, xerr, [0 0 0], 1.0);

plot(xfit, yfit, 'k-', 'LineWidth', 2.0);

xlabel('\Delta Behavior |ASD - NT|');
ylabel('Number of discriminative images');
box off;
set(gca, 'LineWidth', 1.3, 'FontSize', 13);

% Log x-axis if all x values are positive.
if all(x(valid) > 0)
    set(gca, 'XScale', 'log');
end

title('Figure 1. Sparse diagnostic image effects', 'FontWeight', 'bold');

% Stats annotation
if isfinite(fitInfo.r)
    txt = sprintf('r = %.2f, p = %.3g', fitInfo.r, fitInfo.p);
    text(0.05, 0.95, txt, 'Units','normalized', ...
        'VerticalAlignment','top', 'FontSize', 10);
end

try
    exportgraphics(fig, fullfile(outDir, 'Figure1_sparsity.png'), 'Resolution', 300);
    exportgraphics(fig, fullfile(outDir, 'Figure1_sparsity.pdf'));
catch
    print(fig, fullfile(outDir, 'Figure1_sparsity.png'), '-dpng', '-r300');
    saveas(fig, fullfile(outDir, 'Figure1_sparsity.pdf'));
end

end

function draw_horizontal_errorbars(x, y, xerr, colorVal, lw)
for i = 1:numel(x)
    if isfinite(x(i)) && isfinite(y(i)) && isfinite(xerr(i))
        plot([x(i)-xerr(i), x(i)+xerr(i)], [y(i), y(i)], '-', ...
            'Color', colorVal, 'LineWidth', lw);
    end
end
end

function [xfit, yfit, info] = fit_exp_decay_summary_table(x, y)
% Fit y = a*exp(b*x)+c without requiring Curve Fitting Toolbox.

x = x(:);
y = y(:);
valid = isfinite(x) & isfinite(y);
x = x(valid);
y = y(valid);

info = struct;
info.r = NaN;
info.p = NaN;
info.params = [NaN NaN NaN];

if numel(x) < 3
    xfit = x;
    yfit = y;
    return;
end

% Starting parameters.
a0 = max(y) - min(y);
b0 = -10;
c0 = min(y);
p0 = [a0 b0 c0];

obj = @(p) nansum((y - (p(1).*exp(p(2).*x) + p(3))).^2);

opts = optimset('Display','off');
p = fminsearch(obj, p0, opts);

xfit = linspace(min(x), max(x), 300);
yfit = p(1).*exp(p(2).*xfit) + p(3);

try
    [r,pval] = corr(x, y, 'Rows','complete', 'Type','Pearson');
catch
    r = NaN;
    pval = NaN;
end

info.r = r;
info.p = pval;
info.params = p;
end

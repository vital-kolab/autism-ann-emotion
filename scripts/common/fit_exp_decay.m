function [xfit, yfit, fitInfo] = fit_exp_decay(x, y)
% Fit y = a*exp(b*x)+c without requiring Curve Fitting Toolbox.
x = x(:); y = y(:);
good = isfinite(x) & isfinite(y) & x > 0 & y > 0;
x = x(good); y = y(good);

fitInfo = struct('params',[NaN NaN NaN], 'r',NaN, 'p',NaN, 'rsq',NaN);

if numel(x) < 3
    xfit = x; yfit = y; return;
end

a0 = max(y) - min(y);
b0 = -10;
c0 = min(y);
p0 = [a0 b0 c0];

obj = @(p) sum((y - (p(1).*exp(p(2).*x) + p(3))).^2, 'omitnan');
opts = optimset('Display','off');
p = fminsearch(obj, p0, opts);

xfit = linspace(min(x), max(x), 300)';
yfit = p(1).*exp(p(2).*xfit) + p(3);

yhat = p(1).*exp(p(2).*x) + p(3);
ssRes = sum((y-yhat).^2, 'omitnan');
ssTot = sum((y-mean(y,'omitnan')).^2, 'omitnan');
fitInfo.rsq = 1 - ssRes ./ ssTot;
fitInfo.params = p;

[fitInfo.r, fitInfo.p] = pearson_basic(x, y);
end

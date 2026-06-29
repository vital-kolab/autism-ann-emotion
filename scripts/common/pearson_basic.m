function [r, p] = pearson_basic(x, y)
% Pearson correlation with approximate p-value using Student t.
x = x(:); y = y(:);
good = isfinite(x) & isfinite(y);
x = x(good); y = y(good);
n = numel(x);
if n < 3 || std(x)==0 || std(y)==0
    r = NaN; p = NaN; return;
end
x = x - mean(x);
y = y - mean(y);
r = sum(x.*y) ./ sqrt(sum(x.^2).*sum(y.^2));
t = r .* sqrt((n-2) ./ max(eps, 1-r.^2));
% tcdf requires Statistics Toolbox. If absent, return NaN p.
try
    p = 2 .* (1 - tcdf(abs(t), n-2));
catch
    p = NaN;
end
end

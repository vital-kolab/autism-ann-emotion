function s = localSEM(x)
x = x(:);
x = x(isfinite(x));
if numel(x) <= 1
    s = NaN;
else
    s = std(x) ./ sqrt(numel(x));
end
end

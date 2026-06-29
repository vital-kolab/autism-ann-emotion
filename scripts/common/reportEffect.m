function stats = reportEffect(effect)
effect = effect(:);
effect = effect(isfinite(effect));

stats = struct;
stats.n = numel(effect);
stats.mean = mean(effect,'omitnan');
stats.median = median(effect,'omitnan');
stats.sem = localSEM(effect);
stats.positive = sum(effect > 0);

try
    [~, p, ci, tstats] = ttest(effect, 0, 'Tail', 'right');
    stats.t = tstats.tstat;
    stats.df = tstats.df;
    stats.pRight = p;
    stats.ciLow = ci(1);
    stats.ciHigh = ci(2);
catch
    stats.t = NaN;
    stats.df = stats.n - 1;
    stats.pRight = NaN;
    stats.ciLow = NaN;
    stats.ciHigh = NaN;
end

stats.pSignFlip = signflip_p(effect, 10000, 'right');
end

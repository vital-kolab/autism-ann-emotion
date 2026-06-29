function p = signflip_p(x, nPerm, tail)
% p = signflip_p(x, nPerm, tail)
% One-sample sign-flip permutation test against zero.
% tail: 'right', 'left', or 'both'. Default = 'right'.
if nargin < 2 || isempty(nPerm); nPerm = 10000; end
if nargin < 3 || isempty(tail); tail = 'right'; end

x = x(:);
x = x(isfinite(x));

if isempty(x)
    p = NaN;
    return;
end

obs = mean(x, 'omitnan');
nullVals = nan(nPerm,1);

for b = 1:nPerm
    signs = randi([0 1], numel(x), 1);
    signs(signs == 0) = -1;
    nullVals(b) = mean(x .* signs, 'omitnan');
end

switch lower(tail)
    case 'right'
        p = (1 + sum(nullVals >= obs)) ./ (nPerm + 1);
    case 'left'
        p = (1 + sum(nullVals <= obs)) ./ (nPerm + 1);
    case 'both'
        p = (1 + sum(abs(nullVals) >= abs(obs))) ./ (nPerm + 1);
    otherwise
        error('tail must be right, left, or both');
end
end

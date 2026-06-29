function saveFigure(figHandle, outDir, baseName)
% saveFigure(figHandle, outDir, baseName)
% Save PNG, PDF, and MATLAB FIG with graceful fallbacks.
if ~exist(outDir, 'dir'); mkdir(outDir); end
baseName = regexprep(baseName, '[^a-zA-Z0-9_]', '_');

pngFile = fullfile(outDir, [baseName '.png']);
pdfFile = fullfile(outDir, [baseName '.pdf']);
figFile = fullfile(outDir, [baseName '.fig']);

try
    exportgraphics(figHandle, pngFile, 'Resolution', 300);
catch
    print(figHandle, pngFile, '-dpng', '-r300');
end

try
    exportgraphics(figHandle, pdfFile);
catch
    print(figHandle, pdfFile, '-dpdf', '-painters');
end

try
    savefig(figHandle, figFile);
catch
    warning('Could not save .fig file.');
end
end

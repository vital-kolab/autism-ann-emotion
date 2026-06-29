function rootDir = repoRoot()
% Return repository root assuming this file is in scripts/common.
thisFile = mfilename('fullpath');
commonDir = fileparts(thisFile);
scriptsDir = fileparts(commonDir);
rootDir = fileparts(scriptsDir);
end

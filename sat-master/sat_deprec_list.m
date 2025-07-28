%% deprecation list



FILE_START = 'sdoAnalysis_demo_v2.m';
[files, products] = matlab.codetools.requiredFilesAndProducts(FILE_START);

% === CONFIGURATION ===
pkgFolder = '/home/ubkm2/Documents/MATLAB/Trevor_Analysis/sdoAnalysisToolkit/sat-master/*';           % Set your package folder path
%{
deprecFolder = 'deprecationFolder';        % Folder to move unused functions

% Create deprecation folder if it doesn't exist
if ~exist(deprecFolder, 'dir')
    mkdir(deprecFolder);
end
%}

% === GATHER FUNCTION FILES ===
funcFiles = dir(fullfile(pkgFolder, '*.m'));
funcNames = arrayfun(@(f) erase(f.name, '.m'), funcFiles, 'UniformOutput', false);

% === SCAN USAGE ===
usedFuncs = {};
for i = 1:length(funcNames)
    isUsed = false;
    for j = 1:length(funcFiles)
        % Skip checking function file against itself
        if i == j, continue; end
        % Read content
        fPath = fullfile(funcFiles(j).folder, funcFiles(j).name);
        content = fileread(fPath);
        % Look for usage (basic name match)
        if contains(content, funcNames{i})
            isUsed = true;
            break;
        end
    end
    if isUsed
        usedFuncs{end+1} = funcNames{i}; %#ok<AGROW>
    end
end

% === IDENTIFY UNUSED FUNCTIONS ===
unusedFuncs = setdiff(funcNames, usedFuncs);
fprintf('Found %d unused function(s):\n', length(unusedFuncs));
disp(unusedFuncs');
%{
% === MOVE UNUSED FILES ===
for i = 1:length(unusedFuncs)
    src = fullfile(pkgFolder, [unusedFuncs{i} '.m']);
    dest = fullfile(deprecFolder, [unusedFuncs{i} '.m']);
    movefile(src, dest);
    fprintf('Moved: %s → %s\n', unusedFuncs{i}, deprecFolder);
end
%}
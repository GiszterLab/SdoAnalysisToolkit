%% Concatenate Trialwise X(t) Data
% Temporary Recompile method for concatenating trialwise xtData into a
% single 'xtData' data holder for time-series data. 
%
% Only needs to be run once. 
% 
% When prompted by the UI window, select all 'xtDataTrial##' data within
% the 'demoData' folder. 

% Trevor S. Smith, 2023
% Drexel University College of Medicine. 

[fName, fDir] = uigetfile("Select ALL xtDataTrial matfiles to concatenate", "MultiSelect","on","MultiSelect","on"); 

if isa(fName, 'char')
    N_FILES = 1; 
    fName = {fName}; 
else
    N_FILES = length(fName); 
end

disp(strcat(num2str(N_FILES), " selected.")); 

xtData = cell(2, N_FILES); 

%_______
for f = 1:N_FILES
    ffName = fullfile(fDir, fName{f});
    temp = load(ffName); 
    xtData(:,f) = temp.xtData; 
    disp(strcat("Added file, #", num2str(f))); 
end
%_____ 

ffNameFinal = fullfile(fDir, "xtData.mat"); 
save(ffNameFinal, 'xtData'); 

disp("All files successfully concatenated."); 

clear fName fDir N_FILES f ffName temp ffNameFinal 
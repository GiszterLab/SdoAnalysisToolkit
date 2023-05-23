%% Concatenate Trialwise X(t) Data
% Temporary Recompile method for concatenating trialwise xtData into a
% single 'xtData' data holder for time-series data. 
%
% Only needs to be run once. 
% 
% When prompted by the UI window, select all 'xtDataTrial##' data within
% the 'demoData' folder. 

% Copyright (C) 2023 Trevor S. Smith
% Drexel University College of Medicine
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

disp(strcat("Writing out to ", ffNameFinal)); 

save(ffNameFinal, 'xtData'); 

disp("All files successfully concatenated."); 

clear fName fDir N_FILES f ffName temp ffNameFinal 
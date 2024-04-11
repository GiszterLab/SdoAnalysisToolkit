%// temporary method for explicitly defining ppData components for OOP

%_______________________________________
% Copyright (C) 2024 Trevor S. Smith
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

function ppDC = getPpDataHolder(N_TRIALS, N_PP_CHANNELS)
%// Generic method for defining (all) fields in ppDataCell struct
   arguments
       N_TRIALS = 1; 
       N_PP_CHANNELS = 1; 
   end

ppData = struct( ...
    'sensor',           cell(1,N_PP_CHANNELS), ...
    'times',            cell(1,N_PP_CHANNELS), ...
    'envelope',         cell(1,N_PP_CHANNELS), ... 
    'nEvents',          cell(1,N_PP_CHANNELS), ... 
    'fs',               cell(1,N_PP_CHANNELS), ... 
    'shuffle',          cell(1,N_PP_CHANNELS)); %added as empty here 

ppMC = struct( ...
    'trialNumber', 0); 

ppDC = cell(2,N_TRIALS); 
for tr=1:N_TRIALS
    ppDC{1,tr} = ppData; 
    %
    ppDC{2,tr} = ppMC;
    ppDC{2,tr}.trialNumber = tr; 
end

1; 
end
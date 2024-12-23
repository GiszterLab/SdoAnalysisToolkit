%% sdoAnalysis_ppDataCell_new
% Generates a data structure for point-process data ('ppDataCell'),
% pre-populated with fields used in the SDO Analysis toolkit. 
%
% PREREQUSITE: None
%
% INPUT PARAMETERS: 
%   N_TRIALS : A postive integer, corresponding to the number of
%       independent recording trials/sessions used. If not provided, will
%       default to 1. 
%   N_PP_CHANNELS: A positive integer, corresponding to the number of spike
%       train/event channels recorded in parallel during a trial. If not
%       provided, will default to 1. 
% OUTPUT: 
%   ppDataCell
%
% ppDataCell is a 2x NumberTrials cell; Each element in the first row is a
% struct containing trial data with fields; 
%   - 'electrode' : [string/char] Unique channel identifier
%   - 'times'      : [1xN Doubles Array] Event times for point process
%       (must be in same units as compared timeseries datacell)
%   - 'envelope'  : [NxM] Doubles array containing the spike waveforms
%   - 'nEvents'   : [integer] sum of event times; 
% The second row of ppDataCell is reserved for any parameters or metadata
% associated with the same trial (column). This cell is passed to the sdo
% structure. Ideally the elements will be in the form of a struct; 

%_______________________________________
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
%__________________________________________


function [ppDataHolder] = ppDataHolder_new(N_TRIALS, N_PP_CHANNELS)
%// constructor function for generating an empty ppDataCell
%// Only utilized fields are defined

if ~exist('N_TRIALS', 'var')
    N_TRIALS = 1; 
end
if ~exist('N_PP_CHANNELS', 'var')
    N_PP_CHANNELS = 1; 
end
try
    ppDataHolder = dataCell.constructors.getPpDataHolder(N_TRIALS, N_PP_CHANNELS); 
catch
    %// Without argument parsing; MATLAB < 2019
    % Not preferable, as these names may not be conserved
    ppDC = struct( ...
        'sensor',           cell(1,N_PP_CHANNELS), ...
        'times',            cell(1,N_PP_CHANNELS), ...
        'envelope',         cell(1,N_PP_CHANNELS), ... 
        'nEvents',          cell(1,N_PP_CHANNELS), ... 
        'fs',               cell(1,N_PP_CHANNELS), ... 
        'shuffle',          cell(1,N_PP_CHANNELS)); %added as empty here 
    
    ppMC = struct( ...
        'trialNumber', 0); 
    
    ppDataHolder = cell(2,N_TRIALS); 
    for tr=1:N_TRIALS
        ppDataHolder{1,tr} = ppDC; 
        %
        ppDataHolder{2,tr} = ppMC; 
        ppDataHolder{2,tr}.trialNumber = tr; 
    end
end

end

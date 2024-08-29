%% computeSDO_xtDataCell_new()
% Generates a data structure for time series data ('xtDataCell'),
% pre-populated with fields used in the SDO Analysis toolkit. 
%
% PREREQUSITE: None
%
% INPUT PARAMETERS: 
%   N_TRIALS : A postive integer, corresponding to the number of
%       independent recording trials/sessions used. If not provided, will
%       default to 1. 
%   N_XT_CHANNELS: A positive integer, corresponding to the number of time
%       series channels recorded in parallel during a trial. If not
%       provided, will default to 1. 
% OUTPUT: 
%   xtDataCell
%
% xtDataCell is a 2x NumberTrials cell; Each element in the first row is a
% struct containing trial data with fields; 
%   - 'sensor'      : [string/char] Unique channel identifier
%   - 'fs'          : [integer] Sample frequency for timeseries data
%   - 'times'       : [1xN Doubles Array] Matching time elements for data to
%       position. Units must be as in the point process dataset. 
%   - 'envelope'    : [1xN Doubles Array] Processed timeseries data 
%   - 'raw'         : [1xN Doubles Array] Original data
%   - 'offset'      : [1x1 or 1xN] Doubles array. If 1x1, a constant offset
%       used to level envelope. If 1xN, elementwise offset between
%       processed and original data. 
%   - 'stateSignal'  : [1xN] Integer array. The state-discretized signal. 
%   - 'signalLevels' : [1xN_STATES+1] doubles vector containing the bin
%       edges for quantizing signal to state. 

% The second row of xtDataCell is reserved for any parameters or metadata
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


function [xtDataHolder] = xtDataHolder_new(N_TRIALS, N_XT_CHANNELS)
%// constructor function for generating an empty xtDataCell
%// Only utilized fields are defined

if ~exist('N_TRIALS', 'var')
    N_TRIALS = 1; 
end
if ~exist('N_XT_CHANNELS', 'var')
    N_XT_CHANNELS = 1; 
end

try
    xtDataHolder = dataCell.constructors.getXtDataHolder(N_TRIALS, N_XT_CHANNELS); 
catch
    %// Direct Define
    %
    %// Standardized fields used/populated for dataCell. 
    xtDC = struct(...
        'sensor',           cell(1, N_XT_CHANNELS), ...
        'fs',               cell(1, N_XT_CHANNELS), ...
        'times',            cell(1, N_XT_CHANNELS), ... 
        'envelope',         cell(1, N_XT_CHANNELS), ...
        'raw',              cell(1, N_XT_CHANNELS), ... 
        'offset',           cell(1, N_XT_CHANNELS), ... 
        'stateSignal',      cell(1, N_XT_CHANNELS), ... 
        'signalLevels',     cell(1, N_XT_CHANNELS) ); 
    
    %// Standardized fields for metadata; 
    xtMC = struct(...
        'trialNumber', 0); 
    
    xtDataHolder = cell(2,N_TRIALS); 
    for tr=1:N_TRIALS
        xtDataHolder{1,tr} = xtDC; 
        %
        xtDataHolder{2,tr} = xtMC; 
        xtDataHolder{2,tr}.trialNumber = tr; 
    end
end

end
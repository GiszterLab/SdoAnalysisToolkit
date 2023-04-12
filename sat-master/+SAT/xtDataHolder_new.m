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
%   - 'electrode' : [string/char] Unique channel identifier
%   - 'envelope'  : [1x N Doubles Array] Processed timeseries data 
%    - 'fs'       : [integer] Sample frequency for timeseries data
%   - 'times'      : [1xN Doubles Array] Matching time elements for data to
%       position. Units must be as in the point process dataset. 
% The second row of xtDataCell is reserved for any parameters or metadata
% associated with the same trial (column). This cell is passed to the sdo
% structure. Ideally the elements will be in the form of a struct; 

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function [xtDataCell] = sdoAnalysis_xtDataCell_new(N_TRIALS, N_XT_CHANNELS)
%// constructor function for generating an empty xtDataCell
%// Only utilized fields are defined

if ~exist('N_TRIALS', 'var')
    N_TRIALS = 1; 
end
if ~exist('N_XT_CHANNELS', 'var')
    N_XT_CHANNELS = 1; 
end

xtDC = struct(...
    'electrode',    cell(1,N_XT_CHANNELS), ...
    'envelope',     cell(1,N_XT_CHANNELS), ...
    'fs',           cell(1,N_XT_CHANNELS), ...
    'times',        cell(1,N_XT_CHANNELS)); 

xtMC = struct(...
    'trialNumber', 0); 

xtDataCell = cell(2,N_TRIALS); 
for tr=1:N_TRIALS
    xtDataCell{1,tr} = xtDC; 
    %
    xtDataCell{2,tr} = xtMC; 
    xtDataCell{2,tr}.trialNumber = tr; 
end

end
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
%   - 'time'      : [1xN Doubles Array] Event times for point process
%       (must be in same units as compared timeseries datacell)
%   - 'counts'    : [integer] sum of event times; 
% The second row of ppDataCell is reserved for any parameters or metadata
% associated with the same trial (column). This cell is passed to the sdo
% structure. Ideally the elements will be in the form of a struct; 

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function [ppDataCell] = ppDataHolder_new(N_TRIALS, N_PP_CHANNELS)
%// constructor function for generating an empty ppDataCell
%// Only utilized fields are defined

if ~exist('N_TRIALS', 'var')
    N_TRIALS = 1; 
end
if ~exist('N_PP_CHANNELS', 'var')
    N_PP_CHANNELS = 1; 
end

ppDC = struct( ...
    'sensor',           cell(1,N_PP_CHANNELS), ...
    'time',             cell(1,N_PP_CHANNELS), ...
    'counts',           cell(1,N_PP_CHANNELS)); 

ppMC = struct( ...
    'trialNumber', 0); 

ppDataCell = cell(2,N_TRIALS); 
for tr=1:N_TRIALS
    ppDataCell{1,tr} = ppDC; 
    %
    ppDataCell{2,tr} = ppMC; 
    ppDataCell{2,tr}.trialNumber = tr; 
end

end

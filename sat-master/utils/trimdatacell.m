%% trimdatacell
% Small utility to trim a dataCell to a given set of trials or channel row
% indices. 
%
% INPUTS: 
%   dc 
%       - dataCell structure; either xtDataCell or ppDataCell
%   TRIAL_LIST
%       - Vector/Integer
%       - Trial indices (dataCell columns) to include in trimmed dataCell
%   CHANNEL_LIST
%       - Vector/Integer
%       - Channel indices (dataCell Rows) to include in trimmed dataCell
% OUTPUT: 
%   dc_trim
%       - dataCell, of specified dimensions

% Trevor S. Smith, 2022
% Drexel Univeristy College of Medicine

function [dc_trim] = trimdatacell(dc, TRIAL_LIST, CHANNEL_LIST)
if isempty(TRIAL_LIST)
    TRIAL_LIST = 1:size(dc,2); 
end
if ~exist('CHANNEL_LIST', 'var')
    CHANNEL_LIST = 1:length(dc{1,1}); 
end

dc_trim = dc(:,TRIAL_LIST);

nTrials = length(TRIAL_LIST);  

for tr = 1:nTrials
    dc_trim{1,tr} = dc_trim{1,tr}(CHANNEL_LIST); 
    
end

end


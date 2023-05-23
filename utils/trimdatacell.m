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


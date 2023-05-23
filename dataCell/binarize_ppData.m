%% binarizePPData
%General method for converting spiking events into a binary signal (xt)
%representation; (i.e. rounding 'continuous' measured times to discrete
%indices)
%
% INPUTS: 
% 'eventTimes': {N x1 } cell. If N > 1, use each cell element as a
%   new row in the resulting binArr. If passed as a vector, treate as a cell
%
% Differential behavior based on ARR_LENGTH data type. If integer, treat
% ARR_LENGTH as a total length index (i.e. the length of binArr). If a
% float/double, treat ARR_LENGTH as a time index (in sec; same unit as RASTER_HZ),
% and calculate binArr length from RASTER_HZ; 

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

function [binArr] = binarize_ppData(eventTimes, RASTER_HZ, ARR_LENGTH)

eventClss = class(eventTimes); 
switch eventClss
    case 'cell'
        N_CHANNELS = length(eventTimes); 
    case 'double' %// vector
        N_CHANNELS = 1; 
        eventTimes = {eventTimes}; %temp cellwrap; 
end

if isinteger(ARR_LENGTH)
    binArrLen = ARR_LENGTH; 
else
    binArrLen = round(ARR_LENGTH*RASTER_HZ); 
end

binArr = zeros(N_CHANNELS, binArrLen); 
for ch = 1:N_CHANNELS
    ts = eventTimes{ch}; 
    cnfrm_ts = round(ts*RASTER_HZ); %conformed spiketimes == indices
    LI = (cnfrm_ts >=1) & (cnfrm_ts <= binArrLen);
    cnfrm_ts = cnfrm_ts(LI);     
    binArr(ch, cnfrm_ts) = 1; 
end
    

end
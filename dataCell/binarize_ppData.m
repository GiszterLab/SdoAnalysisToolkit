%% binarizePPData
%// General method for converting spiking events into a binary signal (xt)
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


% Trevor S. Smith, 2022

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
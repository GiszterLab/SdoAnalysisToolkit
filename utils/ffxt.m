%% filtfilt xt
%// Variation of filt-filt which is better designed for short signals
%(which will be more affected by signal endpoint artifacts). 
%
% Reduce endpoint artifacts by appending 0-value rows to the passed
% elements. 
%
% B = input filtering coefficient (as filtfilt)
% A = input filtering coefficient (as filtfilt); 
% xt= timeseries data/ collection of data to process (as filtfilt.
%
% If xt is a NxM doubles array, applying the filtering columnwise, as with
% filtfilt. 

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function [fxt] = ffxt(b, a, xt)

N_PTS = length(b); 

[SIZE_X, SIZE_Y] = size(xt); 

if SIZE_X > 1
    %// normal colwise filtering; 
    
    buffArr = zeros(N_PTS, SIZE_Y); 
    
    xtArr = [buffArr; xt; buffArr]; 
    
    %
    fxtArr = filtfilt(b,a,xtArr); 
    
    fxt = fxtArr(N_PTS+1:end-N_PTS,:);
else
    %// perform row-wise 1x; 
    buffArr = zeros(1, N_PTS); 
    
    xtArr = [buffArr, xt, buffArr]; 
    
    fxtArr = filtfilt(b,a,xtArr);    
    
    fxt = fxtArr(1, N_PTS+1:end-N_PTS);
    
end


end
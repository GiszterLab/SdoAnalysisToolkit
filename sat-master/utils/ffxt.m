%% filtfilt xt
%// Variation of filt-filt which is better designed for short signals
%(which will be more affected by signal endpoint artifacts). 
%
% Reduce endpoint artifacts by appending 0-value rows to the passed
% elements. 
%
% B = input filtering coefficient (as filtfilt)
% A = input filtering coefficient (as filtfilt); 
% xt= timeseries data/ collection of data to process (as in filtfilt).
%   [ N_OBS x N_CHANNELS] array; operating on columns independently; 
%

% 10.23.2024 - Upgrade for better handling. 

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

function [fxt] = ffxt(b, a, xt)

N_PTS = length(b); 

[sz_y, sz_x] = size(xt); 

TRANSPOSE = 0; 
if sz_y == 1 && sz_x > 1
    xt = xt'; 
    TRANSPOSE = 1; 
    [~, sz_x] = size(xt); 
end

%{
if sz_y > 1
    %// normal colwise filtering; 
    %}

    buffArr = zeros(N_PTS, sz_x); 
    
    xtArr = [buffArr; xt; buffArr]; 
    
    nanLI = isnan(xtArr); 
    
    xtArr(nanLI) = 0; % temporary; 
    
    %
    fxtArr = filtfilt(b,a,xtArr); 
    
    fxtArr(nanLI) = NaN; 


    fxt = fxtArr(N_PTS+1:end-N_PTS,:);
    %{
else
    %// perform row-wise 1x; 
    buffArr = zeros(1, N_PTS); 
    
    xtArr = [buffArr, xt, buffArr]; 
    
    fxtArr = filtfilt(b,a,xtArr);    
    
    fxt = fxtArr(1, N_PTS+1:end-N_PTS);
    
end
    %}

if TRANSPOSE
    fxt = fxt'; 
end


end
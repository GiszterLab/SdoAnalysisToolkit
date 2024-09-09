%% getidealaxislength
% Utility to find an ideal axis length, given a maximum/mininum observed value
% Used to commonly set many subplots 
% Essentially finds the nearest whole number of the significant digit
%
% INPUT: 
%   Y = A single number, representing the aggregate max or min of
%      values to plot
%   MODE: 'max' or 'min': Whether to use higher or lower bound. 


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

function [yLen] = getidealaxislength(Y, MODE)

nDigits     = numel(num2str(round(abs(Y)))); 
denom       = 10^(nDigits-1); 
switch MODE
    case 'max'
        yMax    = ceil(Y/denom)*denom; 
        yLen    = min(yMax, round(floor(Y/denom)*denom*1.5)); 
        %yLen    = min(yMax, round(Y*1.5)); 
        if yLen == 0
            yLen = yMax; 
        end

        1; 
    case 'min'
        yMin    = floor(Y/denom)*denom; 
        %yLen    = max(yMin, round(ceil(Y/denom)*denom*1.5)); 
        yLen    = max(yMin, round(ceil(Y/denom)/denom*1.5)); 
        %yLen    = max(yMin, round(Y*1.5)); 
        if yLen == 0
            yLen = yMin; 
        end
        
end
1; 
end
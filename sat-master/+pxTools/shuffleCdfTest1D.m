%% (pxTools) ShuffleCdfTest1D
%
% Takes a distribution of [N_SHUFFS,1] 1D (scalar) shuffle values and
% a [1,1] testStat value, and determines if testStat is >(1-SIG_PVAL) 
% percentile of the observed shuffle data

% Trevor Smith, 2025
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


function [H,P,threshVal]= shuffleCdfTest1D(shuffStat, testStat, alpha)
arguments
    shuffStat
    testStat
    alpha = 0.05; 
end

sigProb = (1-alpha); 

[CDF,X] = ecdf(shuffStat); 
idx = find(X>=testStat,1); 
if isempty(idx)
    % No value in shuff greater than testStat;
    P = 0; 
else
    % This is the value in shuff ~testStat
    P = 1-CDF(max(idx-1,1)); 
end

threshVal = dataAtPercentile(X,sigProb); % Approximate threshold val

% Make call 
if testStat > threshVal
    H = true;
else
    H = false; 
end

if nargout == 1
    P = []; 
    threshVal = []; 
elseif nargout == 2
    threshVal = []; 
end

end
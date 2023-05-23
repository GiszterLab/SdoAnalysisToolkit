%% cifReshuffle
% Utility to reshuffle spiketimes based upon the Conditional Intensity
% Function (CIF) generated from the supplied spikes. The number of output
% spikes will equal the number of input spikes. 
%
% Used here to generate an arbitrary number of reshuffled timestamps. 
%
% INPUTS
%   timeStamps - [1 x N] Doubles array containing the observed spiking
%       events (in sec). 
%   OUT_HZ      - Int. The resolution of the sampling HZ to use for generating
%       the CIF, and hence the output timestamps
%               - WARNING: Setting this too high will decrease
%               performance as it affects output array size. 
%   N_SHUFFLES  - Int. The number of shuffled timestamps to generate. 
%   TAU         - Doubles. The characteristic time delay for the smoothing
%       filter used to estimate the CIF (in Sec). 
%   OPTIONAL NAME-VALUE PAIRS
%       maxTime     - Doubles. The maximum time value to use to for output.
%          If not provided, will default to the maximum observed value in
%          'timeStamps'
%       method      - {'sg', '-hg', 'expd', 'sgs', 'tb'} The filtering
%           method for the smoothing filter with response characterized by
%           TAU. 
%           - If not provided, will default to 'sg' (symmetrical gaussian)
% OUTPUT: 
%   shuffArr - [N_SHUFFLES x N_SPIKES] doubles array containing reshuffled
%       timestamps using the given function. 


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

function [shuffArr] = cifReshuffle(timeStamps, OUT_HZ, N_SHUFFLES, TAU, varargin)
p = inputParser; 
addParameter(p, 'maxTime', max(timeStamps)); 
addParameter(p, 'method', 'sg'); 
parse(p, varargin{:}); 
pR = p.Results; 

METHOD  = pR.method; 
T_MAX   = pR.maxTime;
%_________

N_SPIKES = length(timeStamps); 

condIF = filterSpiketimeContinuous(timeStamps, OUT_HZ, T_MAX, METHOD, TAU); 

%// cumulative distribution 
CDF = cumsum(condIF); 

%// Norm CDF between 0-1; 
normCDF = CDF/max(CDF); 

%// Generate random time points 0-1; 
LI = sort(rand(N_SHUFFLES, N_SPIKES),2); 

%// rand has a resolution of 10^4; need to compensate for number of digits
%we are calc'ing over
nDigits = length(num2str(ceil(T_MAX))); 

%// Uniform random jitter to avoid oversampling individual points; 
jitterArr = randi([-10^nDigits 10^nDigits], size(LI)).*10^-(4+nDigits); 

ci_tm = (1:length(normCDF))/OUT_HZ;

LI_Flat = reshape((LI+jitterArr)', [], 1)'; 

%// interpolate breaks down if there are multiple outputs to the same
%input; We will condense redundancies down to their first occuurrence
[uniqueV, uniqueLI] = unique(normCDF); 

shuffArr_0 = interp1(uniqueV, ci_tm(uniqueLI), LI_Flat); 

shuffArr = reshape(shuffArr_0', N_SPIKES, [])'; 

%// Post-hoc conform NaNs to min;  
shuffArr(isnan(shuffArr)) = ci_tm(1); 
1;
end

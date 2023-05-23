%% dataAtPercentile
% Simple macro for establishing a cdf of the observed data, setting up
%the appropriate percentile search, and returning value which is at x% of
%the data amplitude

%// Data should be rectified prior to percentile search if absolute
%magnitude of percentile is sought

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

function [dataPoint] = dataAtPercentile(xt, pct)

if pct > 1 
    pct = pct/100; 
end

xts = sort(xt); 

dataPoint = xts(max(round(length(xt)*pct),1)); 

end
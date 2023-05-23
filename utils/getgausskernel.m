%% Gaussian Kernel 
%// grab a generic gaussian kernel for 1D filtering of discrete-sampled
% points
%
% INPUTS
%   WID (Integer) - Number of states/positions adjacent to mean to estimate
%       the kernel over
%   STD (Integer) - The standard deviation of the gaussian
% OUTPUT
%   kn - Kernel for filtering, sum normalized to 1. 

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

function [kn] = getgausskernel(WID, STD)
if ~exist('WID', 'var')
    WID = 1; 
end
if ~exist('STD', 'var')
    STD = 1; 
end

fcoeff=exp(-(-WID:WID).^2/(2*STD^2));
kn=fcoeff/sum(fcoeff);

end

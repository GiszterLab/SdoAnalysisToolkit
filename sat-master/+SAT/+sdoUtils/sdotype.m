%% sdotype
% Utility to quickly classify an SDO matrix as 'L' (linear/ dpx) or 'M'
% (markov/transition matrix). An array of all zeros should be passed as
% 'L'.
%
% Tolerance value calculated is relative to the number of states. 

% Copyright (C) 2023  Trevor S. Smith
%  Drexel University College of Medicine
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

function matType = sdotype(sdoMatrix)

matType = 'L'; 
N_STATES = length(sdoMatrix); 

tolVal = 1/sqrt(N_STATES); 

if nnz(sdoMatrix<0) == 0 && sum(sum(sdoMatrix)) > tolVal
    matType = 'M'; 
end


end
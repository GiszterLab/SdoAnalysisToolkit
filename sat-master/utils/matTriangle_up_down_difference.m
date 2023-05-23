%% Matrix Triangle Up/Down Difference
% The difference in the sums of the upper and lower matrix diagonals. 
% If sdo is more than 2 dimensional, assume dim 1 and 2 comprise an array,
% with the 3rd dimension serving as a stack iterator
%
% If matrix is 3D, assume dimensions 1 and 2 comprise the square matrix,
% and iterate over every XY page, indexed by Z. 
%
% Used in SDO analysis to calculate the directional bias of the
% differential SDO (which sums to 0 if diagonal included). In this case,
% due to matrix indexing, higher numbered columns and rows correspond to 
% higher state; (i.e. lower matrix triangle = upper sdo triangle); 
%
% INPUT: 
%   M - matrix square over dimensions 1,2. 
% OUTPUT: 
%   netDiff: Total absolute magnitude of off-diagonal elements for each
%   page of M. 

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

function [netDiff] = matTriangle_up_down_difference(sdo)
% Note that 'upper' here is in the context of the matrix indexing and
% actually refers to transition to LOWER states, while 'lower' refers to
% transition to HIGHER states

% Trevor Smith

% upper/lower triangles, sans diagonal


sz_dim = size(sdo); 
N_DIM = length(sz_dim); 

if N_DIM == 3
    Z_HEIGHT = sz_dim(3); 
else
    Z_HEIGHT  = 1; 
end

netDiff = zeros([1,sz_dim(2:end)]); 

for z = 1:Z_HEIGHT
    upX = tril(sdo(:,:,z),-1); %lower diagonal = increasing states; 
    dnX = triu(sdo(:,:,z),+1); %upper diagonal = decreasing states;
    netDiff(:,:,z) = sum(upX-dnX); 
end

end
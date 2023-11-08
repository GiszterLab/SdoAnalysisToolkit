%% Matrix Triangle Up/Down Sum
% Computes the sum of the absolute values of the upper and lower matrix
% triangles (Off-diagonal elements) for each matrix column. Then takes sum
% over all columns. 
%
% If matrix is 3D, assume dimensions 1 and 2 comprise the square matrix,
% and iterate over every XY page, indexed by Z. 
%
% Used in SDO analysis to calculate the total magnitude of off-diagonal
% elements. In this case, due to matrix indexing, higher numbered columns
% and rows correspond to higher state; (i.e. lower matrix triangle = upper
% sdo triangle); 
%
% INPUT: 
%   M - matrix square over dimensions 1,2. 
% OUTPUT: 
%   netSum: Total absolute magnitude of off-diagonal elements for each
%   page of M. 

% 7.23.2023 - Switched the sign on the diagonal offset to the proper
% config.


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


function [netSum] = matTriangle_up_down_sum(M)
% NOTE: 'upper' here is in the context of the matrix indexing and
% actually refers to transition to LOWER states, while 'lower' refers to
% transition to HIGHER states

% upper/lower triangles, sans diagonal


sz_dim = size(M); 
N_DIM = length(sz_dim); 

if N_DIM == 3
    Z_HEIGHT = sz_dim(3); 
else
    Z_HEIGHT  = 1; 
end

netSum = zeros([1,sz_dim(2:end)]); 

for z = 1:Z_HEIGHT
    %upX = tril(M(:,:,z),+1); %lower diagonal = increasing states; 
    upX = tril(M(:,:,z),-1); %lower diagonal = increasing states; 
    %dnX = triu(M(:,:,z),-1); %upper diagonal = decreasing states;
    dnX = triu(M(:,:,z),+1); %upper diagonal = decreasing states;
    netSum(:,:,z) = sum(abs(upX)+abs(dnX)); 
end

end
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


% Trevor S. Smith
% Drexel University College of Medicine


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
    upX = tril(M(:,:,z),+1); %lower diagonal = increasing states; 
    dnX = triu(M(:,:,z),-1); %upper diagonal = decreasing states;
    netSum(:,:,z) = sum(abs(upX)+abs(dnX)); 
end

end
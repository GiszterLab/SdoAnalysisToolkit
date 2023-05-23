%% pxTools_splinePx
% Probability distributions behave poorly when there are values of 0 probability
% for states within the domain; spline existing probability columns to
% estimate what these experimentally un-observed values should be. Uses
% 'pchip' as a splining function
%
% Also compatible with the joint sdo matrix, but not the differential sdo
% matrix
%
% INPUT: 
%   pxIn - [N_STATES x M] doubles array containing a probability
%       distribution, observed columnwise. 
%   OP_DIM - [1/2] Integer. Which dimension to spline over. Default = 1
%       (columnwise)
% OUTPUT: 
%   pxOut - [N_STATES x M] doubles array, containing the normed values.
%       Elements are normalized to the sum of the active dimension. 

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

function [pxOut] = splinePx(pxIn, OP_DIM)

if ~exist('OP_DIM', 'var') 
    OP_DIM = 1; 
end

if OP_DIM ==2
    pxIn = pxIn';
end

[NBINS, NCOLS] =  size(pxIn);

pxOut = zeros(NBINS, NCOLS);

for c=1:NCOLS 
    px0 = pxIn(:,c); 
    x0  = find(px0> 0)'; 
    if isempty(x0)
        pxOut(:,c) = pxIn(:,c); 
        continue; 
    end
    
    y0  = px0(x0)'; 
    %// constrained spline
    px1 = pchip([0, x0, NBINS+1], [0, y0, 0], 1:NBINS); 
    pxOut(:,c) = px1*(sum(pxIn(:,c))/sum(px1)); 
end
    
if OP_DIM == 2 
    pxOut = pxOut'; 
end

end


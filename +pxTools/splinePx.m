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

% Trevor S Smith, 2022
% Drexel University College of Medicine

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


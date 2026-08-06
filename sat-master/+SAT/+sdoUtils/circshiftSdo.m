%% SAT.sdoUtils.circshift
%
% Variant of the circle shift method, which performs a 'rotation' of the
% SDO matrix, but shifted along the diagonal, rather than straight columns.
% 
% NOTE: SDOs can change slightly if gating out some of the (dpx); normalize
% to restore SDO definition. 
%
% Equivalent to shear mat --> circshift --> unshear mat

% Trevor S. Smith, 2026


function [sdoOut] = circshiftSdo(sdoM, K, NORM)
if nargs == 2
    NORM = 1; 
end

nBins = length(sdoM); 

% 1. Shear. 
shearMat = zeros(nBins*2-1,nBins); 
for b = 1:nBins
   shearMat(nBins-b+1:2*nBins-b,b) = sdoM(:,b); 
end
% 2. Shift. 
circShiftShear = circshift(shearMat,K,2); 

% 3. (un)Shear 
circ_sdoM = zeros(nBins); 
for b = 1:nBins
   circ_sdoM(:,b) = circShiftShear(nBins-b+1:2*nBins-b,b);  
end

% 4. Norm (Ensure conforming; 
if NORM == 1
    sdoOut = SAT.sdoUtils.conformsdo(circ_sdoM); 
else
    sdoOut = circ_sdoM; 
end
1; 


end
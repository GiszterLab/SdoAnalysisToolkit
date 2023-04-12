%% stashiftmat
%
% Used to generate a 'constant' shift (STA) operator from an SDO matrix.
% This is the dpx 'STA' (rowsum of dSDO), then sheared about its center of
% mass to produce a 'dSDO' which provides a constant shift (of mu) for the
% probability distributions provided.
% 
%
% INPUTS
%   sdomat - The sdo matrix to use (may be the differential matrix, or the
%       joint matrix [transition matrix])
%   staVal - A column vector of values to use as the STA effect. If not
%       provided, STA is described as the rowsum of sdomat


% Trevor S. Smith, 2023
% Drexel University College of Medicine


function [sstamat] = stashiftmat(sdoMatrix, staVal)

N_STATES = length(sdoMatrix); 

px0  = sum(abs(sdoMatrix)); 
if ~exist('staVal', 'var')
    dpx1 = sum(sdoMatrix,2);  
else
    dpx1 = staVal; 
end

%// Find central state as the basis around which to (window) shear
csPx = cumsum(px0); 
meanX = find(csPx >= csPx(end)/2, 1); 

%// we are effectively 'shearing' the SDO matrix; 
% if we simply apply the sdoShear, and then choose the 'window' from which
% to trim/conform the SDO, we effectively replicate a shift in mu

sdoShear = zeros(2*N_STATES+1,N_STATES); 
for xx = 1:N_STATES
    %// apply consistent 1:step shear; 
    sdoShear(xx:xx+N_STATES-1,xx) = dpx1;  
end

sdoShearWinMat = sdoShear(meanX:N_STATES+meanX-1, :);

%// Apply a constant hi/low offset to the edge rows of the shear 

%// Find elements above/below shearing window window
sdoShearLoWin = sdoShear(1:meanX-1,:); 
sdoShearHiWin = sdoShear(N_STATES+meanX:end,:); 

%// take the simple sum of elements as an offset for p(x) saturation
loWinSum    = sum(sdoShearLoWin,1); 
hiWinSum    = sum(sdoShearHiWin,1); 

%// offset edges of the windowed matrix by out-of-window saturation. 
sdoShearNet = sdoShearWinMat; 
if (meanX > 1) 
    sdoShearNet(1,:) = sdoShearNet(1,:)+loWinSum; 
end
if (meanX < N_STATES)
    sdoShearNet(N_STATES,:) = sdoShearNet(N_STATES,:) + hiWinSum; 
end

%// Post-hoc 'Conform' to Linear Assumptions; 

sstamat = SAT.sdoUtils.conformsdo(sdoShearNet); 

if all(all(sstamat >0)) 
    sstamat = sstamat*diag(1./sum(sstamat)); 
end 

end
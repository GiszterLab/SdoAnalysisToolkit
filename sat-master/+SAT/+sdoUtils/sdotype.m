%% sdotype
% Utility to quickly classify an SDO matrix as 'L' (linear/ dpx) or 'M'
% (markov/transition matrix). An array of all zeros should be passed as
% 'L'.
%
% Tolerance value calculated is relative to the number of states. 

function matType = sdotype(sdoMatrix)

matType = 'L'; 
N_STATES = length(sdoMatrix); 

tolVal = 1/sqrt(N_STATES); 

if nnz(sdoMatrix<0) == 0 && sum(sum(sdoMatrix)) > tolVal
    matType = 'M'; 
end


end
%% convolve joint sdo
% given a (recovered) joint matrix/distribution, appropriately convolve the matrix
% N_STEPS. 
% jsdo is first scaled to px0 (colsum), and 1's are added to the matrix
% diagonal to ensure the matrix functions as a transition matrix.
% It is multipled N_STEP times, and then row elements are
% back-scaled by px0

function [jsdo2, tMat] = convolvejointsdo(jsdo, N_STEPS)

px0 = sum(jsdo,1); 

N_STATES = length(px0); 

%// find populated columns
popCols = (px0 > 0);

buffMat = eye(N_STATES); 
buffMat(:,popCols) = jsdo(:,popCols); 

px0_1 = sum(buffMat,1); 

buffMat2 = buffMat./repmat(px0_1, N_STATES,1); 

%// Convolve
tMat = buffMat2^N_STEPS; 

%// rescale
jsdo2 = tMat.*repmat(px0, N_STATES, 1); 

if nargout ==1
    tMat = []; 
end

end


%% SAT.sdoUtils.matrixMotifAlignment (alignments)
%
% Identify the best alignment of (columns) between two SDOs, permitting
% that the state definition may be different. States are assumed ordinal.  
%
% Assume that A and B have the same number of states (at least for now). 
%
% INPUTS: 
%   - sdoA - An SDO matrix, (NxN array)
%   - sdoB - An SDO matrix, (NxN array)
% NAME-VALUE PAIRS
%   - 'errorFunction' : 'norm' (Frobenius); 'emd' (Earth Mover's Distance).
%       Default = 'norm'
%   
% OUTPUTS: 
%   - sdoB_aligned - An aligned SDO Matrix (NxN array)
%   - K  [Integer]: Calculated optimial alignment index
%   - minErr: Calculated error Statistic. 

% Trevor S. Smith, 2026


function [sdoB_aligned, K, minErr] = matrixMotifAlignment(sdoA, sdoB, vars)
arguments
    sdoA
    sdoB
    vars.errorFunction {mustBeMember(vars.errorFunction, {'norm', 'emd'})} = 'norm';
    vars.alignment = 'circshift'; % DUMMY 
end

% METHOD: Currently, just implement circshift; 
% TODO: allow for locally-preserving structure

% 

nBins = length(sdoA); 

shearMat_A = zeros(nBins*2-1, nBins); 
shearMat_B = shearMat_A; 

% __ Zero Pad __ %
for b = 1:nBins
    % put matrix 'diagonal' on horizontal
   shearMat_A(nBins-b+1:2*nBins-b,b) = sdoA(:,b); 
   shearMat_B(nBins-b+1:2*nBins-b,b) = sdoB(:,b); 
end

FUNC = vars.errorFunction; 
%FUNC = 'NORM'; % Frob norm; EMB earth movers' distance
%FUNC = 'EMD'; 
% ; just blind-scan for now 

colVal = inf(nBins, nBins); 
for b = 1:nBins
    
    A = shearMat_A; 
    B = circshift(shearMat_B, b-1,2); 
    
    % Exclude 'diagonals' because they don't provide anything useful. 
    A(nBins,:) = 0; 
    B(nBins,:) = 0; 
    
    colVal(b,:) = sum(A-B); 
    
end

switch FUNC
    case 'norm' % frob. norm
        err = sqrt(sum(colVal.^2,2)); 
    case 'end' %  earth movers distance/ Wasserstein
        err = sum(abs(colVal),2); 
end

[minErr,k1] = min(err);
K = k1-1; % Optimal Shift; 


% Check for ad-hoc utilization of the toolkit
try 
   sdoB_aligned = SDO.sdoUtils.circshiftSdo(sdoB, K); 
catch
    sdoB_aligned = circshiftSdo(sdoB, K); 
end

% -- 

if nargout == 2
    minErr = []; 
end
if nargout == 3
    minErr = []; 
    K = []; 
end

end
%% singular function for implementing predictions
% in time. This uses the iterative update method.  
%
% Note that each probability vector is handled independently; 
%
% sdo = Singlular SDO matrix to apply to px0
%
% px0 = NSTATES x nObs column-vector array of initial probability. 
%
% N_STEPS = This is the relative number of steps from the original
% creation of the SDO vs. the prediction; 
%
%Alpha = weights (static)
%
% OUTPUT: 
%   pxt = [N_STATES x nObs] output vector for the prediction at time t. 

function [pxt] = sdo_pxt(sdo, px0, N_STEPS, alpha)

nObs = size(px0,2); 

if ~exist('alpha', 'var')
    ones(1, nObs); 
end

residual = N_STEPS - floor(N_STEPS); 

pxt = px0; 
t = 1; 
while t <= N_STEPS
    dxt = sdo * diag(alpha) *pxt; 
    pxt = pxt+dxt; 
    t = t+1; 
end

% __ Mimic residuals; 
if residual > 0
    scl_sdo = sdo*residual; %bascially weight by remaining; 
    dxt_r = scl_sdo*diag(alpha)*pxt; 
    pxt = pxt+dxt_r; 
end

pxt = normpdfcol2unity(pxt); 

end
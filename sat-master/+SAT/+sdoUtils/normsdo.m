%% normSDO
%// Utility to normalize SDO for cross-unit comparision or combination; 
% Each element of the (diff) sdo tries to represent dp(x1|x0), but this
% is implicitly biased by p(x0), the distribution of spikes present at type
% of spikes. 
% 
% Normalization seeks to generalize the expected change in the pos-spike
% distribution [dp(x1)], so spike effects can be predicted by varying
% pre-spike distributions
%
% Various methods theoretically exist for normalization, depending upon the
% desired outcome

function [dNSdo, jNSdo,  normMat] = normsdo(dSDO, jSDO, varargin)
defaultMethod = 'px0'; 
expectMethod = {'px0', 'px1px0', 'unity'}; 
p = inputParser;
addOptional(p, 'normMethod', defaultMethod, ...
    @(x) any(validatestring(x,expectMethod)) ); 
parse(p, varargin{:}); 
pR = p.Results; 

method = pR.normMethod; 

%_____


ZDIM_DSDO = size(dSDO,3); 
ZDIM_JSDO = size(jSDO,3); 

N_BINS = size(dSDO, 1); 

dsdo_flat = reshape(dSDO, N_BINS, N_BINS, []); 
jsdo_flat = reshape(jSDO, N_BINS, N_BINS, []); 

switch method
    case 'px0'
        %// normalize jSdo by px0 (colsum); 
        
        px0_raw = sum(jsdo_flat,1); 
        
        normMat = repmat(px0_raw, N_BINS, 1, 1); 
        
    case 'px1px0'
        %// normalize by joint-conditional probablity of state 
        % dp(x1|x0)/p(x1|x0)
        
        px0px1 = jsdo_flat; 
        
        
        %// spline pre-spike obs to estimate frequency (alpha vals)
        px0px1 = pxTools.splinePx(px0px1,1); 
        normMat = pxTools.splinePx(px0px1,2); 

    case 'unity'
        %// normalize joint SDO matrix matix to 1; apply equivalent norm
        %operation to diff SDO;     
        
        invNormMat = normpdfcol2unity(jsdo_flat); 
        normMat = jsdo_flat./invNormMat; 

end

%//Shared element-wise division normalization;  

normMat(normMat ==0) = 1; 

popCols = (sum(jSDO)>0); 

jNSdo2   = eye(N_BINS); 

jNSdo = repmat(jNSdo2,1, ZDIM_DSDO); 

buffMat = jsdo_flat./normMat; 

jNSdo(:,popCols) = buffMat(:,popCols); 

dNSdo = dSDO./normMat; 
dNSdo(isnan(dNSdo)) = 0; 

jNSdo = reshape(jNSdo, N_BINS, N_BINS, []); 
dNSdo = reshape(dNSdo, N_BINS, N_BINS, []); 

end

%% computeSDO_KLDMeasures
% Compute the Knullback-Liebler Divergence (KLD) between two provided
% probability distributions, from M1 --> M2. 
% If M1 is 3D, while M1 is 2D, calculate the KLD for each xy 2D array page,
% indexed by the third dimension (z). 
%
% DEPENDENCIES:
%   pxTools Library (pxTools_KLDiv)
%
% INPUTS
%   M1 - 2D or 3D Matrix of state distributions 
%           "P" Component of KLD
%   M2 - 2D or 3D Matrix of state distributions
%           "Q" Component of KLD
% OUTPUTS
%   KL2D    - KLD calculated over the entire 2D matrix page
%   KLpx0   - KLD calculated from column-sum of 2D Matrix ("pre-spike"); 
%   KLpx1   = KLD calculated from normalized column-normalized matrices

% Maryam Abolfath-Beygi, 2018

% TODO: Expand capability into 3 dimensions, if necessary. 

function [KL2D, KLpx0, KLpx1]=KLDMeasures(M1,M2)
%M1 and M2 are two 2-D distributions but could be 3 or 4 D the first two dimensions contain 2D SDOs
KL2D=0;
if ~isempty(M1) && ~isempty(M2)
    
    KL2D=pxTools.KLDiv(M1,M2,[1,2]);
    px0=sum(M1,1); % here I assume that cols of M1 are x_t and rows are x_(t+1) therefore this marginal is p(x_t)
    px1=sum(M2,1);
    KLpx0=pxTools.KLDiv(px0,px1,[1 2]);
    %
    px0xtplus0_1_xt = normpdfcol2unity(M1); %TS upgrades
    px1xtplus0_1_xt = normpdfcol2unity(M2); 
    
    %p0xtplus0_1_xt=bsxfun(@times,M1,1./sum(M1,1)); %p1(x_(t+1)|x_t) corresponding to M1
    %p1xtplus0_1_xt=bsxfun(@times,M2,1./sum(M2,1));
    KLpx1=pxTools.KLDiv(px0xtplus0_1_xt,px1xtplus0_1_xt,1);
end
end



        

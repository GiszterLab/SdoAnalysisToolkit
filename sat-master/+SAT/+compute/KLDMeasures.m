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
%   KLpx1_x0   = KLD calculated from the COLUMNS normalized column-normalized
%       MATRICES (i.e. similarity conditional to state)
%
% NOTE: This only meaures the differences between the distributions, as
% provided. Any normalization should occur upstream. 

%_______________________________________
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
%__________________________________________


% TODO: Expand capability into 3 dimensions, if necessary. 

function [KL2D, KLpx0, KLpx1_x0]=KLDMeasures(M1,M2)
%M1 and M2 are two 2-D distributions but could be 3 or 4 D the first two dimensions contain 2D SDOs
KL2D=0;
if ~isempty(M1) && ~isempty(M2)
    
    KL2D=pxTools.KLDiv(M1,M2,[1,2]);
    px0_1=sum(M1,1); % here I assume that cols of M1 are x_t and rows are x_(t+1) therefore this marginal is p(x_t)
    px1_1=sum(M2,1);
    KLpx0=pxTools.KLDiv(px0_1,px1_1,[1 2]);
    %
    px0xtplus0_1_xt = normpdfcol2unity(M1); %TS upgrades
    px1xtplus0_1_xt = normpdfcol2unity(M2); 
    
    %p0xtplus0_1_xt=bsxfun(@times,M1,1./sum(M1,1)); %p1(x_(t+1)|x_t) corresponding to M1
    %p1xtplus0_1_xt=bsxfun(@times,M2,1./sum(M2,1));
    KLpx1_x0=pxTools.KLDiv(px0xtplus0_1_xt,px1xtplus0_1_xt,1);
    1; 
end
end



        

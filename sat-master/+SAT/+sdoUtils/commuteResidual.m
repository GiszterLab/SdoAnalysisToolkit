function [nL1, L1] = commuteResidual(L0, px0, px1, vars)
arguments
    L0
    px0 
    px1
    vars.method {mustBeMember(vars.method, {'V3', 'V5', 'V7'})} = 'V3'; 
end
% Take a (normalized) SDO (L0), and generate a prediction of Px1; Take the
% difference between the predicted and and observed Px1 (i.e., residuals)
% and generate a second SDO which goes: Px1 = L1 * (L0Px0+Px0). 
%
% When L0 is the background SDO, this provides an estimation of spike-only
% effects over a short time interval. 
%
% INPUTS: 
%   - L0: Original SDO, normed to conditional form. 
%   - px0: Prespike/initial distributions
%   - px1: Postspike/posterior distributions
% NAME-VALUE PAIRS: 
%   - 'method' {'V3', 'V5', 'V7'}. Algorithm. Default = 'V3'; 
% OUTPUTS:
%   - nL1= Unity Normalized Residual SDO. dp(x1,x0)
%   - L1 = Px0-Covariance Normalized Residual SDO. dp(x1|x0)
%

% TODO: Implement these into the SDO estimation scripts directly 

% Copyright (C) 2024  Trevor S. Smith
%  Drexel University College of Medicine
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

px1_pdBck = L0*px0+px0; % expected Px1 from L0

% Now, we consider the distance between the (bck) predicted px1 and the 
% spike-observed px1 as the 'spike effect' 

%// Solve the short-term different SDO via a residual estimation; 
switch vars.method
    case {"V3", "default"}
        [L1, ~,nL1] = SAT.compute.sdo3(px1_pdBck, px1);
    case {"V5", "asymmetric"}
        [L1, ~,nL1] = SAT.compute.sdo5(px1_pdBck, px1);
    case {"V7", 'optimized'}
        [L1, ~,nL1] = SAT.compute.sdo7(px1_pdBck, px1);
end

if nargout == 1
    % Default to normalized; 
    L1 = []; 
end

end
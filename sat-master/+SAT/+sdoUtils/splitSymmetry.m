%% Split Drift/Diff SDOs. 
%
% If the Fokker-Planck Equation underlying the stochastic process is an
% appropriate estimation of the underlying Kraymer-Moyals' Expansion, then
% the effects in probability DRIFT and DIFFUSION can be segregated as the
% first and second order approximations. 
%
% In the SDO, passive diffusion corresponds to symmetry in the sdo matrix,
% while drift components correspond to assymmetry. 
%
% INPUT: 
%   - sdoM = An SDO Matrix
% OUTPUT: 
%   - driftSDO = The directional shift of the SDO
%   - diffSDO  = The unbiased increase of variance captured by the SDO. 


% When summing SDOs across multiple sources, we will need to segregate
% passive increases in signal dispersion vs. the directional shifts in the
% probability distribution, otherwise this later components will be
% addded twice. 

% Upgrade for 3D arrays

% Copyright (C) 2023  Trevor S. Smith
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

function [driftSDO, diffSDO] = splitSymmetry(sdoM, method)
arguments
    sdoM
    method = 1; 
end

[sz_X, ~, sz_Z] = size(sdoM);

driftSDO    = zeros(sz_X, sz_X, sz_Z); 
diffSDO     = zeros(sz_X, sz_X, sz_Z); 

for zz = 1:sz_Z

    if method == 1
        %|| Diagonalized Antisymmetry
        loMat = triu(sdoM(:,:,zz),1); 
        hiMat = tril(sdoM(:,:,zz),-1); 
    
        hMatT = hiMat'; %flip this around to be analogous
    
        h_pos = hMatT-loMat; 
    
        common_mat = zeros(sz_X); 
        LI_1 = h_pos > 0;
        LI_2 = h_pos < 0; 
    
        common_mat(LI_1) = loMat(LI_1); 
        common_mat(LI_2) = hMatT(LI_2); 
    
        cMat = common_mat + common_mat'; 
    
        sumX = sum(cMat); 
    
        % Offset diags to negative (Definition of SDO)
        diffSDO(:,:,zz) = cMat + -diag(sumX); 
    
        driftSDO(:,:,zz) = sdoM(:,:,zz)-diffSDO(:,:,zz); 
    
    elseif method == 2
        %|| Columnwise Symmmetric
        
        % TODO: Shear + calculate low vs. high
        N_STATES = length(sdoM(:,:,zz));
        
        shearMat = zeros(2*N_STATES-1, N_STATES); 
        for xx = 1:N_STATES
            x0 = N_STATES-xx+1; 
            shearMat(x0:x0+N_STATES-1, xx) = sdoM(:,xx);  
        end
        h_pos = shearMat - flipud(shearMat); 
        LI = h_pos > 0; 
        driftShear = h_pos.*(LI);  
        %driftSDO = zeros(N_STATES); 
        for xx = 1:N_STATES
             x0 = N_STATES-xx+1;  
            driftSDO(:,xx,zz) = driftShear(x0:x0+N_STATES-1, xx); 
        end
        driftSDO(:,:,zz) = driftSDO(:,:,zz) - diag(sum(driftSDO(:,:,zz))); 
        diffSDO(:,:,zz)  = sdoM(:,:,zz)-driftSDO(:,:,zz);
    end

end

% // Ensure refactoring doesn't violate assumptions of SDO. Refactor as
% necessary. 
for zz = 1:sz_Z
    diffSDO(:,:,zz)     = SAT.sdoUtils.conformsdo(diffSDO(:,:,zz)); 
    driftSDO(:,:,zz)    = SAT.sdoUtils.conformsdo(driftSDO(:,:,zz)); 
end

if nargout == 1
    diffSDO = []; 
end

end
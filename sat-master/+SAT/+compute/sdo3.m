%%
% 3rd Generation of the compute SDO Matrix (backup for existing methods)
%
% This is the 'original' definition of the SDO, which fits the identity: 
% L*p(x,0) = dp(x,) --exactly--, but which may overestimate diffusion
% effects for combinations of multiple SDOs. 


%_______________________________________
% Copyright (C) 2024 Trevor S. Smith
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

function [L, M, L_norm] = sdo3(px0, px1, obswise, vars)
arguments
    px0
    px1
    obswise = 0; 
    vars.rescale = 1; 
    vars.parallelCompute = 0; 
end

% If 'rescale' is set to 0, the output will NOT be markovian or bounded in
% probability space. Used to perform weighted averaging of SDOs with
% unequal number of contributing observations; 

[N_STATES, N_XT, N_BLOCKS] = size(px0); 

if obswise == 1
    v_px0 = reshape(px0, 1, N_STATES, N_XT*N_BLOCKS); 
    v_px1 = reshape(px1, N_STATES, 1, N_XT*N_BLOCKS); 
    M = pagemtimes(v_px1, v_px0); 
    %
    %dM_v = M - min(M, permute(M, [2,1,3]));
    L = zeros(N_STATES, N_STATES, N_XT*N_BLOCKS); 
    if vars.parallelCompute
        parfor t = 1:N_XT*N_BLOCKS
            % GPU-Accelerated
            %L(:,:,t) = dM_v(:,:,t)  - diag(sum(dM_v(:,:,t)));
            L(:,:,t) = M(:,:,t)  - diag(sum(M(:,:,t)));
        end
    else
        for t = 1:N_XT*N_BLOCKS
            L(:,:,t) = M(:,:,t)  - diag(sum(M(:,:,t)));
            %L(:,:,t) = dM_v(:,:,t)  - diag(sum(dM_v(:,:,t)));
        end
    end
else
    if N_BLOCKS > 1
        M = pagemtimes(px1, permute(px0, [2,1,3])); %outer product; 
        L = zeros(N_STATES, N_STATES, N_BLOCKS); 
        if vars.parallelCompute
            parfor b = 1:N_BLOCKS
                L(:,:,b) = M(:,:,b) - diag(sum(M(:,:,b))); 
            end
        else
            for b = 1:N_BLOCKS
                L(:,:,b) = M(:,:,b) - diag(sum(M(:,:,b))); 
            end
        end
    else
        M = (px1*px0'); %./N_XT; %scale here; 
        % __ Correlation matrix, minus mirrored components; 
        %dM = M-min(M,M'); 
        %L = dM - diag(sum(dM)); 
        L = M - diag(sum(M));
    end
end

if vars.rescale
    L = L./N_XT; 
    M = M./N_XT; 
end

if nargout == 1
    M = []; 
end
if nargout == 3
    L_norm = SAT.sdoUtils.normsdo(L, M); 
end

end
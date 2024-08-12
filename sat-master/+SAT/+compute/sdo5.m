%%
% 5th Variant of the compute SDO Matrix algorithm 

% NOTE: The assymmetrization of the net matrix DOES NOT give the same
% matrix as the sum of assymmetrized matrices; 

% To 'asymmetrize' the matrix, we find the 'symmetrical' component around the matrix diagonal,
% which is the elementwise minimum between M(i,j) & M(j,i)
% The symmetrical matrix diagonal then becomes the columnwise sum -1 (i.e.
% SDO rebalancing). 
% This symmetrical component is then subtracted from the original SDO. 


% if px0, px1 are passed as 3d arrays, the output will treat the third
% dimension as independent; 

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

function [L, M, L_norm] = sdo5(px0, px1, obswise, vars)
arguments
    px0
    px1
    obswise = 0;
    vars.asymmetry {mustBeMember(vars.asymmetry, {'step', 'final'})} = 'step'; 
    vars.rescale = 1; % normally on, unless we are weighted summing across conditions; 
    vars.parallelCompute = 0; 
end

[N_STATES, N_XT, N_BLOCKS] = size(px0);
% __>> Blocks used to temporarily flatten; 

    dpx_pos = max(px1-px0,0); % Positive elements of the difference; This is all we need.

   
switch vars.asymmetry 
    case 'step'
        if obswise == 0
            %D = zeros(N_STATES, N_STATES, N_BLOCKS); 
            L = pagemtimes(dpx_pos, permute(px0, [2,1,3])); %pos-shift; 
            M = pagemtimes(px1, permute(px0, [2,1,3])); % outer product
            
            if vars.parallelCompute
                parfor b = 1:N_BLOCKS
                    % GPU acceleration; 
                    L(:,:,b) = L(:,:,b) - diag(sum(L(:,:,b))); 
                end
            else
                for b = 1:N_BLOCKS
                    L(:,:,b) = L(:,:,b) - diag(sum(L(:,:,b))); 
                end
            end
            %__________
            if vars.rescale
                L = L./N_XT; 
                M = M./N_XT; 
            end
        else % i.e. OBSERVATION WISE
            v_px0 = reshape(px0, 1, N_STATES, N_XT*N_BLOCKS); 
            v_px1 = reshape(px1, N_STATES, 1, N_XT*N_BLOCKS); 
            v_dpx = reshape(dpx_pos, N_STATES, 1, N_XT*N_BLOCKS); 
            M = pagemtimes(v_px1, v_px0); 
            L = pagemtimes(v_dpx, v_px0); 
            if vars.parallelCompute
                parfor t = 1:N_XT*N_BLOCKS
                    %gpu acceleration
                    L(:,:,t) = L(:,:,t) - diag(sum(L(:,:,t))); 
                end
            else
                for t = 1:N_XT*N_BLOCKS
                    L(:,:,t) = L(:,:,t) - diag(sum(L(:,:,t))); 
                end
            end
            %_________
            if N_BLOCKS > 1
                % // need to sum within-blocks; convert matrices to vectors
                L2 = reshape(L, N_STATES*N_STATES, N_XT, N_BLOCKS); 
                L = reshape(sum(L2,2), N_STATES, N_STATES, N_BLOCKS); 
                %
                M2 = reshape(M, N_STATES*N_STATES, N_XT, N_BLOCKS); 
                M = reshape(sum(M2,2), N_STATES, N_STATES, N_BLOCKS); 
                if vars.rescale
                    L = L./N_XT; 
                    M = M./N_XT; 
                end
            end
        end

%======================================================
 
    case 'final'
        % // This is depreciated
        % ___ final asymmetry
        M = zeros(N_STATES, N_STATES, N_BLOCKS); 
        L = zeros(N_STATES, N_STATES, N_BLOCKS); 
        if vars.parallelCompute
            parfor b = 1:N_BLOCKS
                m = (squeeze(px1(:,:,b))*squeeze(px0(:,:,b)')./N_XT);
                dM = m-min(m,m');
                M(:,:,b) = m; 
                L(:,:,b) = dM - diag(sum(dM)); 
            end
        else
            for b = 1:N_BLOCKS
                m = (squeeze(px1(:,:,b))*squeeze(px0(:,:,b)')./N_XT);
                dM = m-min(m,m');
                M(:,:,b) = m; 
                L(:,:,b) = dM - diag(sum(dM)); 
            end
        end
    1; 
        %{
        else
            M = (px1*px0')./N_XT; %scale here; 
            % __ Correlation matrix, minus mirrored components; 
            dM = M-min(M,M'); 
            L = dM - diag(sum(dM)); 
        %}
end
%


if nargout == 1
    M = []; 
end
if nargout == 3
    L_norm = SAT.sdoUtils.normsdo(L, M); 
end

end
%% unitplusbackground
% Util to permit the combination(s) of the background SDO and
% spike-triggered unit SDO given their joint and differential SDOs
%
% Unit SDOs may be provided as a single matrix, or as a {1,N} Cell. If a
% Cell, all units will be added together.
%
% "Undos" background subtraction; 
%
% INPUT
%   bk_dSdo         background difference SDO (numeric array)
%   bk_jSdo         background joint SDO (numeric array)
%   unit_dSdoCell   unitwise difference SDO (either {1,N} cell or numeric
%                   array)
%   unit_jSdoCell   unitwise joint SDO (either {1,N} cell or numeric array)
% NAME-VALUE PAIRS
%   'weightVector'  [1 x N] scaling vector for weighting multiple units. Default = []; 
%   'conform'       [0/1]. Whether to ensure output matrix is conforming.
%                   Default = 1. 
%
% OUTPUT 
%   sum_unit_dSdo   summed output difference SDO (unit[s] + background)
%   sum_unit jSDo   summed output joint SDO      (


%_______________________________________
% Copyright (C) 2025 Trevor S. Smith
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


function [sum_unit_dSdo, sum_unit_jSdo] = unitplusbackground(bk_dSdo, bk_jSdo, unit_dSdoCell, unit_jSdoCell, vars)
arguments
    bk_dSdo double
    bk_jSdo double
    unit_dSdoCell
    unit_jSdoCell
    vars.weightVector = []; %for scaling sums; 
    vars.conform = 1; % Ensure conforming SDO unless otherwise noted; 
    vars.null ; % For future use; perhaps L v. M type sdos
    vars.method = 3; %[1,2,3]; TEMP; for testing accuracy - There isn't any obvious difference in prediction performance from what I can tell
end

if isnumeric(unit_dSdoCell) % i.e. double
    nUnits = 1; 
    unit_dSdoCell = {unit_dSdoCell}; 
    unit_jSdoCell = {unit_jSdoCell}; 
else
    nUnits = length(unit_jSdoCell); 
end

%{
[n_bk_dSdo, n_bk_jSdo] = SAT.sdoUtils.normsdo(bk_dSdo, bk_jSdo); 

n_unit_dSdoCell = cell(1, nUnits); 
n_unit_jSdoCell = cell(1, nUnits); 
%}

if isempty(vars.weightVector)
    if vars.conform
        vars.weightVector = 1/nUnits*ones(1,nUnits); 
    else
        %// Unity
        vars.weightVector = ones(1,nUnits); 
    end
end


%% Preferred (?)

switch vars.method
    case 1
        % ? Norm-then-sum or sum-then-norm ?
        
        %________ Strategy 1 :: Sum then Norm
        sum_unit_dSdo = zeros(size(bk_dSdo)); 
        sum_unit_jSdo = zeros(size(bk_jSdo)); 
        for u = 1:nUnits
            sum_unit_dSdo = sum_unit_dSdo + vars.weightVector(u)*unit_dSdoCell{u}; 
            sum_unit_jSdo = sum_unit_jSdo + vars.weightVector(u)*unit_jSdoCell{u}; 
        end
        
        sum_dSdo = sum_unit_dSdo + bk_dSdo; 
        sum_jSdo = sum_unit_jSdo + bk_jSdo; % Does this even make sense? 
        
        [n_out_sum_dSdo, n_out_sum_jSdo] = SAT.sdoUtils.normsdo(sum_dSdo, sum_jSdo); %bk_jSdo); %
        
        if ~SAT.sdoUtils.islinearsdo(n_out_sum_dSdo)
            if vars.conform == 1
                n_out_sum_dSdo = SAT.sdoUtils.conformsdo(n_out_sum_dSdo); 
            end
        end
        
        
        sum_unit_dSdo = n_out_sum_dSdo; 
        sum_unit_jSdo = n_out_sum_jSdo; 
 
    case 2
        
        %% Less-Preferred
        %_______ Strategy 2 :: Norm then Sum
        1; 
        n_sum_dSdo = zeros(size(bk_dSdo)); 
        n_sum_jSdo = zeros(size(bk_jSdo)); 
        
        for u = 1:nUnits
            % Normalize; 
            [n_u_d, n_u_j] = SAT.sdoUtils.normsdo(unit_dSdoCell{u}, unit_jSdoCell{u}); 
            n_unit_dSdoCell{u} = n_u_d; 
            n_unit_jSdoCell{u} = n_u_j; 
            %
            n_sum_dSdo = n_sum_dSdo + vars.weightVector(u)*n_u_d; 
            n_sum_jSdo = n_sum_jSdo + vars.weightVector(u)*n_u_j; 
        end
        
        n_net_sum_dSdo = n_sum_dSdo + bk_dSdo; 
        n_net_sum_jSdo = n_sum_jSdo + bk_jSdo; 
        
        %}

%% Commonly parameterize, then sum
% ___ Strategy 3 :: Reparameterize then sum 

    case 3
        px0 = sum(bk_jSdo); 
        
        z_unit_dSdo = cellzcat(unit_dSdoCell'); 
        z_unit_jSdo = cellzcat(unit_jSdoCell'); 
        
        
        [reparam_unit_dSdo] = SAT.sdoUtils.reparameterizeSdo(z_unit_dSdo, z_unit_jSdo, px0); 
        
        w = reshape(vars.weightVector, 1, 1, nUnits); 
        
        try 
            sc_re_unit_dSdo = tensorprod(reparam_unit_dSdo, w, 3); 
            sc_re_unit_jSdo0 = repmat(bk_jSdo, 1, 1, nUnits); 
            sc_re_unit_jSdo = tensorprod(sc_re_unit_jSdo0, w, 3); 
            %sc_re_unit_jSdo = tensorprod(z_unit_jSdo, w, 3); 
            % // This is should have the same 
            
        catch
            % ------ for older MATLAB
            nStates = size(reparam_unit_dSdo,1); 
                        
            sc_re_unit_dSdo = zeros(nStates, nStates, nUnits); 
            sc_re_unit_jSdo = zeros(nStates, nStates, nUnits); 
            for z = 1:nUnits
                sc_re_unit_dSdo(:,:,z) = reparam_unit_dSdo(:,:,z)*w(z); 
                sc_re_unit_jSdo(:,:,z) = bk_jSdo(:,:,z)*w(z); 
            end
            
            
        end
       
        
        d_sc_sum = sc_re_unit_dSdo + bk_dSdo; 
        j_sc_sum = sc_re_unit_jSdo + bk_jSdo; 
        
        % Rescaled-normed
        [sc_sum_dSdo, sc_sum_jSdo] = SAT.sdoUtils.normsdo(d_sc_sum, j_sc_sum); %bk_jSdo); 
        
        %
        sum_unit_dSdo = sc_sum_dSdo; 
        sum_unit_jSdo = sc_sum_jSdo; 
end




end
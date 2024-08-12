%% SDO (7)
% SDO matrix constrained optimization 
%
% This is an alternative, slower, direct optimization of the SDO estimation,
% which uses MATLAB's Optimization Toolbox to try to find the (SDO)
% matrix which maps the dpx from px0, given the 4 SDO constraints; 1)
% Nonpositive diagonal; 2) non-negative off-diagonal, 3) Columnsum to 0, 4)
% matrix element magnitude no greater than 1.
%
% Generally the speed cost of this method isn't worth the extra accuracy.
%
% NOTE: The 'obswise' flag is NOT recommended in this case, as the
% optimization for a single component is not good. 


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

function [L, M, L_norm] = sdo7(px0, px1, obswise, vars)
arguments
    px0 
    px1
    obswise = 0; 
    vars.rescale = 1;
    vars.parallelCompute = 0; % requires parallel Computing toolbox; 
    vars.initialization {mustBeMember(vars.initialization, {'zero', 'v3', 'v5', 'custom'})} = 'zero'; 
    vars.customMatrix = []; % This is used for optimization of existing matrices; 
    vars.errorOrder {mustBeMember(vars.errorOrder, [2,4])} = 2; 
end

[N_STATES, N_XT, N_BLOCKS] = size(px0); 

% // Parallelization is not well-defined here. Parallelization may be used
% within the optimization toolbox, below; 

% __ Seed original values here prior to optimization; 
L0 = []; 
switch vars.initialization
    case 'zero'
        if obswise == 1
            L0 = zeros(N_STATES, N_STATES, N_XT*N_BLOCKS); 
        else
            L0 = zeros(N_STATES, N_STATES, N_BLOCKS); 
        end
    case 'v3'
        %// Linear estimation
        L0 = SAT.compute.sdo3(px0, px1, obswise); 
    case 'v5'
        %// Asymmetric
        L0 = SAT.compute.sdo5(px0, px1, obswise); 

    case 'custom'
        % // Pull in + validate 'custom matrix'; 
        [sz_x, sz_y, sz_z] = size(vars.customMatrix); 

        if sz_x == N_STATES
            if sz_z == N_BLOCKS
                L0 = vars.customMatrix; 
            end
        end
        if isempty(L0)
            disp("Initial matrix not well defined for input sizes"); 
            return
        end

        

end


% Initialize Optmization Equation Upfront
[L_var, constraintStruct] = getConstraintVars(N_STATES); 

%% 
dpx = px1-px0; 
warning('off','all') % Different inputs may get tossed to different solvers w/ warnings
if obswise == 1
    %
    L_opt = zeros(N_STATES, N_STATES, N_XT*N_BLOCKS);
    M = zeros(N_STATES, N_STATES, N_XT*N_BLOCKS); 
    z = 1; 
    for b = 1:N_BLOCKS
        for t = 1:N_XT*N_BLOCKS
            L_opt(:,:,z) = findL2(L_var, L0(:,:,t), constraintStruct, px0(:,t,b), dpx(:,t,b), vars.errorOrder, vars.parallelCompute); 
            %L_opt(:,:,z) = findL(px0(:,t,b), dpx(:,t,b), vars.parallelCompute); 
            %
            M(:,:,z) = px1(:,t,b)*px0(:,t,b)'; 
        end
    end
else
    L_opt = zeros(N_STATES, N_STATES, N_BLOCKS);  
    M = zeros(N_STATES, N_STATES, N_BLOCKS); 
    for b = 1:N_BLOCKS
        L_opt(:,:,b) = findL2(L_var, L0(:,:,b), constraintStruct, px0(:,:,b), dpx(:,:,b), vars.errorOrder, vars.parallelCompute); 
        %L_opt(:,:,b) = findL(px0(:,:,b), dpx(:,:,b), vars.parallelCompute); 
        %
        M(:,:,b) = (px1(:,:,b)*(px0(:,:,b)'))/N_XT;
    end
end
warning('on', 'all'); 

% __> The output of 'findL' is the 'normed' SDO. 

avg_px0 = mean(px0,2); 
if (N_BLOCKS == 1) && (obswise == 0) 
    L = L_opt*diag(avg_px0); 
else
   L = L_opt; 
   for z = 1:size(L_opt,3)
       L(:,:,z) = L_opt(:,:,z)*diag(avg_px0(:,b));
   end
end

if vars.rescale == 0
    % // We have to invert rescaling to mimic V5 and V3
    if obswise == 0
        L = L*N_XT; 
        M = M*N_XT; 
    end
end

if nargout == 1
    M = [];
end
if nargout == 3
    [L_norm] = SAT.sdoUtils.normsdo(L,M);  
end

end

%
% -- Core Optimization Function based fitting;  
function L = findL2(L, L0, constraintStruct, px0_data, dpx_data, errorOrder, parallelCompute) 

    %% Objective: Minimize the prediction error
    
    % __ >> FLATTEN Observations into Observationwise error
    % __>> Not recommended
    %{
    px0_data = mean(px0_data,2); 
    dpx_data = mean(dpx_data,2); 
    %}

    dpx_predicted = L * px0_data;

    if errorOrder == 2
        % Quicker, choppy
        prediction_error = sum(sum((dpx_data - dpx_predicted).^2)); % SSE
    elseif errorOrder == 4
        % Smoother, Slower
        prediction_error = sum(sum((dpx_data - dpx_predicted).^4)); % Sum of fourth power of residuals; 
    end

    %

    %// Define the optimization problem
    prob = optimproblem('Objective', prediction_error, 'Constraints', constraintStruct);
    
    %// Solve the optimization problem
    %x0.L = zeros(nStates, nStates);  % Initial guess = Zeros; 
    x0.L = L0;
    %options = optimoptions('fmincon', 'Display','off'); 
    %options = optimoptions('quadprog', 'Display', 'off'); 
    %
    if parallelCompute 
        options = optimoptions('fmincon', 'Display','off', 'UseParallel',true); 
        %options = optimoptions('quadprog', 'Display', 'off', 'UseParallel', true);  % Use quadprog solver [
        % --> quadprog doesn't allow 'UseParallel'
    else
        %options = optimoptions('lsqnonlin', 'Display', 'off');  % Use quadprog solver
        options = optimoptions('quadprog', 'Display', 'off');  % Use quadprog solver
    end
    %}
    [sol, ~,~,~] = solve(prob, x0, 'Options', options);
    %[sol, fval, exitflag, output] = solve(prob, x0, 'Options', options);
    
    %// Return the solution == SDO
    L = sol.L;
end
%}

function [L, constraintStruct] = getConstraintVars(N_STATES)

    % Define the optimization variables
    L = optimvar('L', N_STATES, N_STATES, 'LowerBound', -1', 'UpperBound',1); 
    % // This is also a constraint for maximum matrix element magnitude
    
    % Remaining Constraints
    %
    constraintStruct = struct(... 
        'c1', [], ...
        'c2', [], ...
        'c3', []); 
    
    %% Diagonal elements must be non-positive
    diagNeg = optimconstr(N_STATES); 
    for i = 1:N_STATES
        diagNeg(i,i) =  (L(i, i) <= 0) ; %== i; 
    end
    
    constraintStruct.c1 = diagNeg; 

    %% Off-diagonal elements must be non-negative
    offDiagPos = optimconstr(N_STATES); 
    for i = 1:N_STATES
        for j = 1:N_STATES
            if i ~= j
                offDiagPos(i,j) = (L(i,j) >=0); 
            end
        end
    end

    constraintStruct.c2 = offDiagPos; 
    
    %% Each column must sum to 0
    colSum = optimconstr(N_STATES);
    for j = 1:N_STATES
        colSum(:,j) = sum(L(:,j)) ==0; 
    end
    
    constraintStruct.c3 = colSum;

end
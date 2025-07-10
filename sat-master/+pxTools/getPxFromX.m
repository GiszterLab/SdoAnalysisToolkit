%% getPxFromX (Core)
% Newer core kernel for distributions of signal. 
% Avoids the built-in smoothing and distributions. 
%
% In the rebuilt kernel functions, the intervals are drawn along DIM 1.
% (columns). --> Shuffles are placed on Z. 
%
% INPUTS: 
%   - x      :{x,y} cell of[k,n,m] doubles array of [k,n,m] doubles array
%   - MAX_X  : maximum value of x. [INTEGER]. 
%   - method : {'equal'} - Positional weighting of states (x) --> p(x)
% OUTPUTS
%   px      

% 

% Trevor S. Smith, 2025

function [px] = getPxFromX(x, MAX_X, method) 
arguments
    x
    MAX_X
    method = 'equal'; 
end
%{
if ~iscell(x)
    ISCELL = 0; 
    x = {x}; 
else
    ISCELL = 1; 
end

[cl_x, cl_y] = size(x); 
%}

[sz_x, sz_y, sz_z] = size(x); 

px = zeros(MAX_X, sz_y, sz_z); 

switch method
    case 'equal'
        % equivalent to histcounts, but faster
        for xi = 1:MAX_X
            px(xi,:,:) = sum(x==xi,1)/sz_x; 
        end
end


end
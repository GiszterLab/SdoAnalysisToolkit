%% getPxFromX (Core)
% Newer core kernel for distributions of signal. 
% Avoids the built-in smoothing and distributions. 

% 2025

function [px] = getPxFromX(x, MAX_X, method)
arguments
    x
    MAX_X
    method = 'equal'; 
end

[sz_x, sz_y] = size(x); 

px = zeros(sz_x, sz_y); 

switch method
    case 'equal'
        % equivalent to histcounts, but faster
        for xi = 1:MAX_X
            px(xi,:) = sum(x==xi)/sz_x; 
        end
end


end
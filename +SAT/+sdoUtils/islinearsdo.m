%% islinearsdo()
% Script to provide a quick check if the provided matrix satifices the
% assumptions necessary for use as a linear differential operator. 
%
% INPUT
%   L = 'Linear Operator' to test
% OUPUT
%   flag = Boolean [0/1]
%       0 - L fails to suffice assumptions
%       1 - L satisfices assumptions of linear operators
%   REASON - Integer
%       0 - No failures
%       1 - Columns do not sum to 0
%       2 - Positive Elements on the Diagonal
%       3 - Negative Elements on the Off-Diagonal

% 11.06.2022 - Fixed a bug in logic of upper/lower triangle test
% 12.12.2022 - Added a 'Reason' output for determining failure; 

% Trevor S. Smith, 2022
% Drexel University College of Medicine


function [flag, REASON] = islinearsdo(L)

flag = 1; 
REASON = 0; 
tol = 1e-12; %default tol

% // Overall Mag excessive
%{
if sum(sum(abs(L))) > 2
    flag = 0; 
    return
end
%}

%// Nonzero cols
if any(abs(sum(L,1))>tol)
    flag = 0; 
    REASON = 1; 
    return
end
    
% // Main Diagonal Positive
if any(diag(L)>0)
    flag = 0; 
    REASON = 2; 
    return
end

% // Off-Diagonal Negative
if (nnz(triu(L,1) < 0) > 0) %upper triangle
    flag = 0; 
    REASON = 3; 
    return
end
if (nnz(tril(L,-1) < 0) > 0) %lower triangle
    flag = 0; 
    REASON = 3; 
    return
end

if nargout == 1
    REASON = []; 
end

end
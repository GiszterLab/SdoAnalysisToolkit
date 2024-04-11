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
%       4 - Element Magnitude > 1

% 11.06.2022 - Fixed a bug in logic of upper/lower triangle test
% 12.12.2022 - Added a 'Reason' output for determining failure; 
% 01.22.2024 - Added Element magnitude flag; 

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

function [flag, REASON] = islinearsdo(L)


[~, ~, sz_3] = size(L); 

    % Stack
    flag = ones(sz_3, 1); 
    REASON = zeros(sz_3,1); 
    tol = 1e-12;

for z = 1:sz_3
        mat = L(:,:,z);
        %// Nonzero cols
        if any(abs(sum(mat,1))>tol)
            flag(z) = 0; 
            REASON(z) = 1; 
            continue
        end
        % // Main Diagonal Positive
        if any(diag(mat)>0)
            flag(z) = 0; 
            REASON(z) = 2; 
            continue
        end
        % // Off-Diagonal Negative
        if (nnz(triu(mat,1) < 0) > 0) %upper triangle
            flag(z) = 0; 
            REASON(z) = 3; 
            continue
        end
        if (nnz(tril(mat,-1) < 0) > 0) %lower triangle
            flag(z) = 0; 
            REASON(z) = 3; 
            continue
        end
        %// Element Magnitude; 
        % ||Dpx|| > 1
        if any(abs(mat)>1, 'all')
            flag(z) = 0; 
            REASON(z)=4; 
        end
end
%{
else
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
    
    %// Element Magnitude; 
    % ||Dpx|| > 1
    if any(abs(L)>1, 'all')
        flag = 0; 
        REASON=4; 
    end
end
%}

if nargout == 1
    REASON = []; 
end

end
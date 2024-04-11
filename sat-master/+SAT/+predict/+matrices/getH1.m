

% Hypothesis 1: No-change


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


function [mat] = getH1(nStates, vars)
    arguments
        nStates
        vars.type {mustBeMember(vars.type, {'M', 'L'})} = 'L'; 
    end
    switch vars.type 
        case 'M'
            mat = eye(nStates); 
        case 'L'
            mat = zeros(nStates);  
    end
end
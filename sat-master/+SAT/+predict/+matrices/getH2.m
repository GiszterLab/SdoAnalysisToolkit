
% Hypothesis 2: Gaussian Blurring


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

function [mat] = getH2(nStates,vars)
arguments
    nStates = 20; 
    vars.filterWidth = 1; 
    vars.filterStd = 1; 
    vars.type {mustBeMember(vars.type, {'L', 'M'})} = 'L'; 
end

M = pxTools.getH0Array(nStates, vars.filterWidth, vars.filterStd); 
switch vars.type
    case 'M'    
        mat = M; 
    case 'L'
        mat = M-diag(sum(M)); 
end


end


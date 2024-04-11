%% SDO Sum
% Simple Util for conform-summing SDO operators (dSDOs)
%
% Does not do any checks, assume all inputs provided to matrix are of
% compatible sizes. Can be SDO stacks, if ALL arguments are the same size. 
%
% If multiple matrices are added as independent arguments; these will be
% added together. These may be provided as a {1xN} cell of matrices, or as
% a commented list. 
% 
% If only a single, 3D array (SDO-Stack) is provided, will sum across
% dimension 3, then run the normalization to conform

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

function [sumMat] = sdosum(varargin)

if nargin == 1 && iscell(varargin)
%if (length(varargin) == 1) && iscell(varargin)
    varargin = varargin{1}; 
end
if nargin == 1 && size(varargin,3) > 1
    %// z-stack; 
    sumMat = SAT.sdoUtils.conformsdo(sum(varargin,3)); 
    return
end

nSdos = length(varargin); 

sumMat = varargin{1}; 
for L = 2:nSdos
    sumMat = sumMat+varargin{L}; 
end

sumMat = SAT.sdoUtils.conformsdo(sumMat); 

end
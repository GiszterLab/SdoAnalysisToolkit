%% ensure2DMatOrientation
% Macro to ensure that the direction of data is as expected.
% (Occassionally, MATLAB will represent what should be a [1xN] vector as
% [Nx1] or vice-versa, which causes issues when concatenating w/ [NxK]
% data. 

% Copyright (C) 2023 Trevor S. Smith
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

function [arr] = ensure2DMatOrientation(arr, varargin)
%// input array, ideal row count (if defined), ideal col count (if defined)
if isempty(varargin)
    disp('Ideal dimensions not defined')
    return
end
if ~isempty(varargin{1})
    ir = varargin{1}; 
    sz = size(arr); 
    if find(sz==ir) ~=1
        arr= arr';
    end
elseif ~isempty(varargin{2})
    ic = varargin{2};
    sz = size(arr);
    if find(sz==ic) ~=2
        arr = arr'; 
    end
end
    
end
%% (pxTools) getCovArrFromJointArr; 
%// Resampling method to quickly convert p(X1|X0) into P(X1|X1) or P(X0|X0)

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

function [covArr] = getCovArrFromJointArr(arr, OP_DIM)

if ~exist('OP_DIM', 'var')
    OP_DIM = 1; 
end

if OP_DIM == 1
    px = sum(arr,1); 
    covArr = px'*px; 
    
else
    px = sum(arr,2); 
    covArr = px*px'; 
end

end



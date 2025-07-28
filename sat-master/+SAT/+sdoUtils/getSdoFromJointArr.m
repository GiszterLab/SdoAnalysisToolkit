%% pxTools_getSdoFromJointArr; 
%// Resampling Method to quickly convert p(x1|x0) into p([x1-x0]|x0) * p(x0);
% 
% NOTE: Due to differences in sampling smoothing, the extracted 'sdoMat'
% will not exactly resemble the spike-triggered sdo extracted with
% 'computeSDO.m', but will grossly approximate it. 

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

function sdoMat = getSdoFromJointArr(arr)

sumMag = sum(sum(arr)); 
% Norm to 1
arr = arr/sumMag; 

px0 = sum(arr,1); %colsum
px1 = sum(arr,2); %rowsum

dpx = px1-px0'; 

sdoMat = dpx*px0; 

end
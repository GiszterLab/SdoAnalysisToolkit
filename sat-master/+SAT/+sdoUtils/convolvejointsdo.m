%% convolve joint sdo
% given a (recovered) joint matrix/distribution, appropriately convolve the matrix
% N_STEPS. 
% jsdo is first scaled to px0 (colsum), and 1's are added to the matrix
% diagonal to ensure the matrix functions as a transition matrix.
% It is multipled N_STEP times, and then row elements are
% back-scaled by px0

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

function [jsdo2, tMat] = convolvejointsdo(jsdo, N_STEPS)

px0 = sum(jsdo,1); 

N_STATES = length(px0); 

%// find populated columns
popCols = (px0 > 0);

buffMat = eye(N_STATES); 
buffMat(:,popCols) = jsdo(:,popCols); 

px0_1 = sum(buffMat,1); 

buffMat2 = buffMat./repmat(px0_1, N_STATES,1); 

%// Convolve
tMat = buffMat2^N_STEPS; 

%// rescale
jsdo2 = tMat.*repmat(px0, N_STATES, 1); 

if nargout ==1
    tMat = []; 
end

end


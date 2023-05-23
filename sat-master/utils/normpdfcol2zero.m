%% normpdfcol2zero
% A method to nomalize the negative components of a column vector/ SDO such 
% that the sum of the column is 0. 
%

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

function out = normpdfcol2zero(arr)
%// normalize negative components of a column vector to sum zero
zi = sum(arr,1);        %bias; 
zp = sum(abs(arr),1);   %magnitude; 

%zN = (zp+zi)./(zp-zi); 

msk = repmat((zp+zi)./(zp-zi), size(arr,1),1); 

msk(arr>=0) = 1; %/apply scalar to negatives; 

out = arr.*msk; 
end

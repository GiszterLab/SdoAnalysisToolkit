%% xvect2px
% Generic method for turning a state signal (1 x M) into a (M x N) array
%of 0/1, which corresponds the 'probability' of state, represented as
%sequential column vectors

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

function px = xvect2px(xt, MAX_X)
if ~exist('MAX_X', 'var') 
    MAX_X = max(xt); 
end

nObs = length(xt); 

px = zeros(MAX_X, nObs); 

for xx = 1:MAX_X
    xi = (xt == xx); 
    px(xx,xi) = 1; 
end

end
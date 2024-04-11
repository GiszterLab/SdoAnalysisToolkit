%% reparameterizeSdo
%
% Used to 'normalize' SDOs by the initial/prior probability distribution of state
%
%

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

function [LStack_out] = reparameterizeSdo(LStack, JStack, px0)

[sz_x0_1, sz_x0_2] = size(px0); 

if sz_x0_1 == sz_x0_2
    %// matrix
    lambda = sum(px0); 
elseif (sz_x0_1 > sz_x0_2) && (sz_x0_2 == 1)
    %// colvect
    lambda = px0'; 
else
    lambda = px0; 
end
lambda = lambda./sum(lambda); 

[~, sz_x0_2] = size(lambda); 
%
[sz_L1, sz_L2, sz_L3] = size(LStack); 
[sz_J1, sz_J2, sz_J3] = size(JStack); 

if ~(sz_x0_2 == sz_L2)
    disp("Input Sizes not compatible!");
end

scMat = repmat(lambda, sz_L1, 1, sz_L3); 

normL = SAT.sdoUtils.normsdo(LStack, JStack); 

LStack_out = normL.*scMat; 

1; 

end
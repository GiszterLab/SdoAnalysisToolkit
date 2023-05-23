%% conformMarkov
% Small utility to take a 2D array, assumed to be a (left) Markov
% Stochastic Matrix, and conform it. Assume all elements >=0
% 1) Rescale columns to sum to 1. 
% 2) Ensure non-populated columns have a 1 on diagonal to preserve
% probability. 

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

function [mkvOut] = conformMarkov(mkv)

N_STATES = length(mkv); 
colSum = sum(mkv); 
% -- Rescale
LI = colSum>0; %logical index
iDiag = ones(1, N_STATES); 
iDiag(LI) = 1./colSum(LI); 
% -- Populate
scMat = mkv*diag(iDiag); %scale cols
mkvOut = eye(N_STATES); 
mkvOut(:,LI) = scMat(:,LI); 
end
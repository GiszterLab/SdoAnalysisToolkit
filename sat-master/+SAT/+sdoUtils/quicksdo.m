%% quicksdo
%
% A function to quickly get the SDO matrix (and covariance matrix) from a
% prespike and postspike distribution, without the full SDO script. This
% provides one variant of a matrix which satisfies the least-squares fit
% between prespike-->postspike, but often subpar. 
%
% Uses the V3 algorithm. 
%
% INPUTS: 
%   px0: A [nStates x nSpikes] doubles array of prespike state distributions; 
%   px1: A [nStates x nSpikes] doubles array of postspike state
%       distributions
% OUTPUTS; 
%   sdoMat: A [nStates x nStates] matrix corresponding to the SDO
%   covMat: A [nStates x nStates] matrix corresponding to the background
%       covariance matrix of px0--> px1. 

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

function [sdoMat, covMat] = quicksdo(px0, px1)

%// Assume that px0 and px1 are provided as [N_STATES x N_OBSERVATIONS]
%arrays. 

px0_arr = normpdfcol2unity(px0); 
px1_arr = normpdfcol2unity(px1); 

[~, N_SPIKES] = size(px0); 

sdoMat = (px1_arr*px0_arr') - diag(sum(px0_arr,2))/ N_SPIKES; 
covMat = (px1_arr*px0_arr') / N_SPIKES; 

if nargout == 1
    covMat = []; 
end
end
%% pairedResample
%
% Used when we have paired data which we are 'resampling'; ensures that the
% shuffle points which are randomly drawn from one group matches the other
% groups EXACTLY. 
%
% Returns a tensor of the observations for later manipulation; 
%
% Assume data is a [nObservations x nGroups], with each row corresponding
% to a paired observation. 

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

function [dataShuff] = pairedresample(dataMat, N_SHUFFLES)

[N_OBS, N_GROUPS] = size(dataMat); 

LI_0 = randi(N_OBS, N_OBS, N_SHUFFLES); 
LI = reshape(LI_0, N_SHUFFLES, N_OBS)'; %assume N_SHUFF > N_OBS; 

dataShuff = zeros(N_OBS, N_GROUPS, N_SHUFFLES); 

for gg = 1:N_GROUPS
    shuff = dataMat(LI,gg); 
    
    dataShuff(:,gg,:) = reshape(shuff, N_OBS, []); 
end


end
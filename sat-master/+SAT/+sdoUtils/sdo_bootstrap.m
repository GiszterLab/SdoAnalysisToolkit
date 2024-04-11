%% SDO Bootstrap
% Simple utility to iterate through the post-spike distributions using a
% bootstrapped combination of the existing distributions. 
% Could be used to evaluate the sensitivity of particular spikes on the SDO
% matrix. 
%
% INPUTS: 
%   - px0 -[N_STATES, N_SPIKES] column vectors of pre-spike probability distributions. 
%   - px0 -[N_STATES, N_SPIKES] column vectors of postspike probability distributions. 
% OUTPUT: 
%   - bootSDO = [N_STATES,N_STATES,N_SPIKES], each sheet containing a
%   differential SDO. 

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

function [bootSDO] = sdo_bootstrap(px0, px1, N_BOOTSRAPS)

[N_STATES, N_SPIKES] = size(px0); 

bootSDO = zeros(N_STATES,N_STATES,N_SPIKES); 

for bb = 1:N_BOOTSRAPS
    LI = randi(N_SPIKES, 1,N_SPIKES); 
    %
    p0 = px0(:,LI); 
    p1 = px1(:,LI); 
    % V3 Algorithm
    bootSDO(:,:,bb) = ((p1*p0')-diag(sum(p0,2)))/(N_SPIKES-1); 
end


end
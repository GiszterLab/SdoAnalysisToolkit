%% getpxTimeEvolution "getPxTE"
% Utility to generate a feedforward prediction of Px over N_STEPS using an initial
%probability distribution and a linear (L) update operator (SDO) under the
% framework px1 = x0 + dx(0), where dx0 is calculated by an update matrix. 
%
% Permits the time evolution of multiple Ls in parallel if a time-varying 
% scaling amplitude a(t) is applied as a N_MATRICES x N_STEPS array
%
% INPUTS
%   pxt0
%       - A [Nx1] Initial probability distribution. May be binary (sums to 1). 
%   L 
%       - Either a: 
%           1) [NxN] scaled/normalized SDO matrix. 
%           2) {Mx1} cell array containing M [NxN] SDO matrices 
%   N_STEPS
%       - Int. Number of steps to make (predict), including point px0. 
%           --> Floating point values can be passed, but may be inprecise; 
%   scaleArr 
%       -A [MxN_STEPS] doubles array containing real-valued scaling
%       amplitudes for sdo at each time step. 
%       - If omitted, or Dimension 2 < N_STEPS, missing values will be
%       treated as 1. 
% OUTPUTS
%   pxTE
%       - A [N x N_STEPS] doubles array containing the projected
%       probability distribution for each time step. 


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

function [pxTE] = getPxTE(px0, L, N_STEPS, varargin)
switch class(L)
    case {'double'}
        %// L is an Array; 
        N_L_ARR = 1; 
        L = {L}; %common wrap
    case {'cell'}
        %// L is a cell of operators
        N_L_ARR = length(L); 
end
%_______
p = inputParser; 
addOptional(p,'ctrlOn', ones(N_L_ARR,N_STEPS)); 
parse(p, varargin{:}); 
pR = p.Results; 
CTRL_ON = pR.ctrlOn; 
%// Need to ensure the length of CTRLSig matches obs. 


N_STEPS = floor(N_STEPS); %whole integer numbers only 

%// Treat user input errors
[nDim, nPoints] = size(CTRL_ON); 
if nPoints < N_STEPS
    if nDim > N_L_ARR
        %// assume input array is wrong direction
        CTRL_ON = CTRL_ON';
        [~,nPoints] = size(CTRL_ON); 
    end
    if nPoints < N_STEPS
        %// fill missing values
        buffArr = ones(N_L_ARR, N_STEPS); 
        buffArr(:,1:nPoints) = CTRL_ON; 
        CTRL_ON = buffArr; 
        disp("WARNING: Length of Scaling Matrix < # Queried Points. Treating missing values as 1");  
    end
end
%% CORE x+dx update code
N_BINS = length(px0); 

pxTE = zeros(N_BINS, N_STEPS); 

t = 1;
pxt = px0; 
while t <= N_STEPS
    pxTE(:,t) = pxt; 
    dxt = zeros(N_BINS,1); 
    for a = 1:N_L_ARR
        %// sum predicted differentials
        dxt = dxt+CTRL_ON(a,t)*L{a}*pxt; 
    end
    %// update
    pxt = pxt+dxt; 
    t = t+1; 
end


end
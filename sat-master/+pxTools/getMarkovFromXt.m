%% pxTools_getMarkovFromXt()
% 
% Estimate first-order Markov transition matrix between subsequent
% observations of discrete state, captured as column vectors. 
%
% If multiple independent observations (columns) are used, find average
% transition matrix over all points. 
%
% Because script is designed for SDO framework, if NxM matrix passed assume
% subsequent rows are subsequent transitions; columns are independent
% observations
%
% INPUTS
%   xtArr - a NxM matrix of integer values (corresponding to state).
%       State-state transitions are observed between rows. Independent sets
%       of observations are arranged as different columns. 
%       --> Columns must be of equal size. 
%   N_BINS - Integer. The maximal value of state which may or may not be
%       observed in xtArr. Order of the output Markov matrix. 
%       --> If not defined, assume this for max value in xtArr. 
%   OPTIONAL NAME-VALUE PAIRS: 
%       'conform' : [0/1] - Ensure completeness of Markov matrix by setting
%           transitions from unobserved states to 1 on diagonal
%           (stationary): Default = 1
%       'order':  : [1] - Reserved flag for future use. 
%           (Currently Unused)
%       'Normalization'
%           {'array', 'column', 'none'}
%           How to normalize the Markov Transition Matrix
%           Default = 'column'
% OUTPUT: 
%   mkv - Calculated Markov Matrix

%TODO: Enable second order markov chaining to be made; 

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

function [mkv] = getMarkovFromXt(xtArr, N_BINS, varargin)
defaultNorm= 'column'; 
expectNorm = {'array', 'column', 'none', 'None'}; 

p = inputParser; 
addOptional(p, 'conform', 1); %[0/1]; 
addOptional(p, 'order', 1); % --> Eventual upgrade to 2nd Order matrix
addParameter(p, 'Normalization', defaultNorm, ...
    @(x) any(validatestring(x, expectNorm)) ); 

parse(p, varargin{:}); 
pR = p.Results; 
CONFORM_ARRAY   = pR.conform;
NORM_TYPE       = pR.Normalization; 

if ~exist('N_BINS', 'var')
    N_BINS = max(max(xtArr)); 
end

[N_ROWS, N_COLS] = size(xtArr);

N_POP_DIM = (N_ROWS > 1) + (N_COLS > 1);

if CONFORM_ARRAY
    %// if skipping state, default 1 to diagonal
    mkv = eye(N_BINS); 
else
    mkv = zeros(N_BINS); 
end

if N_POP_DIM == 1
    if N_ROWS == 1 
        xtArr = xtArr';
        [N_ROWS, ~] = size(xtArr); 
    end
end
%// Multidim
subArr1 = xtArr(1:N_ROWS-1,:); 
subArr2 = xtArr(2:N_ROWS,:); 
for xx = 1:N_BINS
    xi = (subArr1 == xx); 
    if nnz(xi) == 0 
        continue
    end
    x2 = (subArr2(xi)); 
    if strcmp(NORM_TYPE,'column')
       mkv(:,xx) = histcounts(x2, 1:N_BINS+1)/sum(sum(xi)); 
    else
        mkv(:,xx) =  histcounts(x2, 1:N_BINS+1); 
    end
end
    
if strcmp(NORM_TYPE, 'array')
    dsum = sum(sum(mkv)); 
    mkv = mkv/dsum; 
end

%// implicit null-handling of 'none'
    
end
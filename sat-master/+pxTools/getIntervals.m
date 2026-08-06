%% getPerieventIntervals
%
% This is the kernel function to return perievent Indicies (intervals) from
% a given set of timepoints. 

% Here, we are going to scan across ROWS, and populate COLUMNS. 
% For (n) spikes, for (m) shuffles, for (k) bins
%
% If the input is 1D [1,n] output should be [k,n]
% if the input is 2D [m,n] output should be [k,n,m]; 
%
% Intervals are calculated as ix+[ixRange]+n_shift
%
% INPUTS: 
%   - ix    :  {x,y} cell of [m,n] event indices INTEGERS!
% NAME-VALUE ARGUMENTS:
%   - 'nPoints': Number of points to include in interval.
%           If x > 0: interval = ix:ix+nPoints; 
%           If x < 0: interval = ix+nPoints+1:ix 
%   - 'nShift' : (default = 0). Positive indicies offset
%   - 'maxLen' : Maximal Integer value. 
%
% x,y are treated independent, but are typically {nChannels, nTrials}
% 
% OUTPUT: 
%   xi  - {x,y} cell of [k,n,m] event indicies [INTEGERS]. If input is not
%       a cell (i.e., [m,n] double) output is a (k,n,m) array. 

%_______________________________________
% Copyright (C) 2025 Trevor S. Smith
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
%__________________________________________

function [xi] = getIntervals(ix, vars)
arguments
    ix   
    vars.nShift = 0; %note this differs from documentation...  
    vars.nPoints = 20; 
    vars.maxLen = []; 
end

if isempty(ix)
    xi = []; 
    return
end

% _>> parsing <<__
ISCELL = 1; 
if ~iscell(ix) 
    ISCELL = 0; 
    ix = {ix}; 
end
% >>_________<<

[sz_x, sz_y] = size(ix); % Cell size; outer wrapper; 
%
nRows = cellfun(@size, ix, repelem({1}, sz_x, sz_y)); %cellwise
nCols = cellfun(@size, ix, repelem({2}, sz_x, sz_y)); %cellwise

% I think we can just iterate over x and y w/o a hit to performance.

if vars.nPoints > 0
    xRng = (1:vars.nPoints)+vars.nShift; 
else
    xRng = (vars.nPoints+1:0)+vars.nShift; 
end
nPts = abs(vars.nPoints); 

xi_cell = cell(sz_x, sz_y); 
for xx = 1:sz_x
    for yy = 1:sz_y
        xDat = ix{xx,yy}(:); % convert to [M*N,1]
        nK = numel(xDat); 
        %
        [xOff_ix] = repmat(xDat,1, nPts); 
        [xRng_ix,~] = meshgrid(xRng, 1:nK); 
        %
        if isempty(xOff_ix)% No spikes = no perispikes
            continue; 
        end
        
        xTen = reshape(xOff_ix+xRng_ix, nRows(xx,yy), nCols(xx,yy), []); 
        xi_cell{xx,yy} = permute(xTen, [3,2,1]); 
    end
end

if ~ISCELL
    xi = xi_cell{1,1}; 
else
    xi = xi_cell; 
end

end
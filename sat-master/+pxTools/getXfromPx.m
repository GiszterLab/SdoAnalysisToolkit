%% pxTools_getXfromPx
% Assign a single state from a distribution, using a given metric; 
% if passing an MxN array, evaluate each column as a distribution; 
%
% If input is a doubles array, output a doubles array. 
% If input is a struct, output a struct, with x calculated over all fields
%
% Current methods include 'max', 'mean', and 'median'
% INPUTS: 
%   px  - columnwise probability vector/array; or struct containing
%       probability vectors. 
%   method 
%       {'mean', 'median', 'max'}; 

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

function [X] = pxTools_getXfromPx(px, method)
if ~exist('method', 'var')
    method = 'max'; 
end

pxType = class(px); 
switch pxType
    case 'double'
        %// default; 
        [NBINS, NCOLS] = size(px); 
         X = xFromPx(px, NBINS, NCOLS, method); 
    case 'struct'
        sfields = fields(px);
        nFields = length(sfields); 
        for sf = 1:nFields
            [NBINS, NCOLS] = size(px.(sfields{sf})); 
            X.(sfields{sf}) = xFromPx(px.(sfields{sf}), NBINS, NCOLS, method); 
        end
end
        
end

function [X] = xFromPx(px, NBINS, NCOLS, method) 
X = zeros(1, NCOLS); 
switch method
    case 'max'
        [~, X] = max(px); 
    case 'mean'
        % weight pdf by state ID
        normArr = repmat([1:NBINS]', 1, NCOLS); 
        normPx = px.*normArr; 
        X = round(sum(normPx)); 
    case 'median'
        %// closest val to 0.5 integral
        pxCDF = cumsum(px); 
        [~, X] = min(abs(pxCDF-0.5)); 
end
end
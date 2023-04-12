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

% Trevor S. Smith, 2022
% Drexel University College of Medicine

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
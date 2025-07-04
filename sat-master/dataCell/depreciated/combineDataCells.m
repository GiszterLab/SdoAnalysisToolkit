%% (DataCell Util - Combine DataCells)
% Used to combine like dataCells OF THE SAME TRIAL together 
% (representing subsets of the like-data; the output of split dataCells)

%_______________________________________
% Copyright (C) 2025 Trevor S. Smith
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

function [cat_dc] = combineDataCells(dcCell)
    % Use to combine like datacells together, stacked vertically; 
    arguments
        dcCell cell
    end
    nDataCells = length(dcCell); 
    
    % test for the similar dataCells; assume these are primary data 
    
    CLASS = class(dcCell{1}); 

    for cl = 1:nDataCells
        if ~strcmp(class(dcCell{cl}), CLASS)
            disp("Input cell does not contain homogenous classes.")
            cat_dc = []; 
            return
        end
    end

    
    % Stack these as a [n x 1] 
    
    nTrials     = zeros(nDataCells,1); 
    nChannels   = zeros(nDataCells,1); 
    sensorNames = cell(nDataCells,1); 
    
    for n = 1:nDataCells
        nTrials(n)      = dcCell{n}.nTrials; 
        nChannels(n)    = dcCell{n}.nChannels; %sensors/channels; 
        sensorNames{n}  = dcCell{n}.sensor; 
    end
    
    maxTrials = max(nTrials); 
    
    trDataLength = zeros(nDataCells, maxTrials); 
    
    for n = 1:nDataCells
        trDataLength(n,:) = dcCell{n}.trTimeLen; 
    end
    
    % __ CONCAT __ 
    cat_data = cell(1, maxTrials); 
    cat_meta = cell(1, maxTrials); 
    
    for tr = 1:nTrials 
        for n = 1:nDataCells
            dat = dcCell{n}.data{1,tr}(:)'; 
            if ~isempty(dcCell{n}.metadata)
                met = dcCell{n}.metadata{1,tr};
            else
                met = []; 
            end
            %
            cat_data{1,tr} = [cat_data{1,tr}(:)', dat]; 
            %
            % Scan for unique fields; 
            if isempty(cat_meta{1,tr})
                ref_fields = {}; 
            else
                ref_fields = fieldnames(cat_meta{1,tr}); 
            end
            % copy only novel fields; 
            % NOTE: IF there is a mismatch in query/reference field values for
            % the same key, this will be missed
            que_fields = fieldnames(met); 
            que_not_ref = setdiff(que_fields, ref_fields); 
            if ~isempty(que_not_ref)
                for f = 1:length(que_not_ref)
                    cat_meta{1,tr}.(que_not_ref{f}) = met.(que_not_ref{f}); 
                end
            end
        end
    end
    
    
    cat_combined = [cat_data; cat_meta]; 
    % swap this by element; no good way to avoid
    % Need to go exhaustive with this; 
    switch CLASS
        case 'ppDataCell'
            cat_dc = ppDataCell; 
        case 'xtDataCell'
            cat_dc = xtDataCell; 
        case 'xtSampleDataCell'
    end
    cat_dc.import(cat_combined); 
    
    % __ update cat with the appropriate properties 
    
    cat_dc.trTimeLen = max(trDataLength,[], 1); 

end
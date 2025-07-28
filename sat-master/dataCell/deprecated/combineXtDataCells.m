        % ___ Implementation of the 'combine' function; 
        % For sanity, we will pass in a {1, nDataCells} cell rather than
        % maintain varargin; 
        
        
        function [dcCombine] = combineXtDataCells(dataCellCell)
            nDC = length(dataCellCell); 
            for c = 1:nDC
                if ~isa(dataCellCell{c}, 'xtDataCell')
                    disp("Error: Unlike DataCells provided")
                    dcCombine = []; 
                    return
                end
            end
            dcCombine = dataCell.manipulate.combineDataCells(dataCellCell); 
        end
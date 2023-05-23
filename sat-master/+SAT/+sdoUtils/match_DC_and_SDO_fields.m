%% match_DC_and_SDO_fields
% Ad-hoc utility function used to validate the possible matching inputs between
% fieldname string and numerical index for the dataCell and the SDO; 
%
% INPUTS: 
%   dataCell
%       - Input {2xN} dataCell (xtDataCell, ppDataCell}
%   sdoNameList
%       - A {1xM} cell, which each element containing strings or character to string-compare against. 
%   DC_CH_NO
%       - The reference row in the supplied DataCell to use as a row-index.      
%   DC_FIELDNAME
%       - Reference field within the datacell structure which corresponds
%       to the string/char name for the row. 
%       - If not provided, defaults to 'electrode'
%  DC_ID_NAME
%       - String/Char to directly test string/chars in sdoNameList against.


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

function [DC_CH_NO, SDO_CH_NO] = match_DC_and_SDO_fields(dataCell, sdoNameList, DC_CH_NO, DC_FIELDNAME, DC_ID_NAME)
    if ~exist('DC_FIELDNAME', 'var')
        DC_FIELDNAME = 'electrode'; 
    end
    if ~exist('DC_ID_NAME', 'var')
        DC_ID_NAME = ""; 
    end

    dcNameList = {dataCell{1,1}.(DC_FIELDNAME)};  
    
    try
       try
            SAME_CH_NO = all(cellfun(@strcmpi, dcNameList, sdoNameList));
       catch
            SAME_CH_NO = all(strcmpi(dcNameList, sdoNameList));
       end
    catch
        SAME_CH_NO = 0; 
    end
    %// Find matching elements in DC & SDO
    if ~strcmp(DC_ID_NAME, "")
        if isempty(DC_CH_NO)
            % -- DC Match; 
            xtI     = strcmpi(dcNameList, DC_ID_NAME); 
            if nnz(xtI) > 1
                xtI = strcmp(dcNameList, DC_ID_NAME); 
                if nnz(xtI) > 1
                    disp("Warning! Redundancy in xtDataCell fieldnames, only first matching channel will be used."); 
                elseif nnz(xtI) < 1
                    disp("No matching fields in xtDataCell"); 
                    return
                end
            end
            DC_CH_NO = find(xtI,1); 
           %--  sdo Match
           if SAME_CH_NO
               SDO_CH_NO = DC_CH_NO; 
           else
               try
                    xtI2 = cellfun(@strcmpi, sdoNameList, DC_ID_NAME); 
               catch
                    xtI2 = strcmp(sdoNameList, DC_ID_NAME); 
               end
               SDO_CH_NO = find(xtI2,1);
           end
        else
            dc_ID2 = dataCell{1,1}(DC_CH_NO).(DC_FIELDNAME); 
            try
                sdoI = cellfun(@strcmpi, sdoNameList, dc_ID2); 
            catch
                sdoI = strcmp(sdoNameList, dc_ID2);
            end
            SDO_CH_NO = find(sdoI, 1); 
        end
    else
        if isempty(DC_CH_NO)
            %// channel neither indexed nor defined; 
            disp("Warning, no unique channel given, defaulting to 1"); 
            if SAME_CH_NO == 1
                DC_CH_NO     = 1; 
                SDO_CH_NO    = 1; 
            else
                DC_ID_NAME = dataCell{1,1}(1).(DC_FIELDNAME); 
                try
                    sdoI = cellfun(@strcmpi, sdoNameList, DC_ID_NAME); 
                catch
                    sdoI = strcmp(sdoNameList, DC_ID_NAME);
                end
                DC_CH_NO     = 1; 
                SDO_CH_NO    = find(sdoI,1); 
            end
        else
            if SAME_CH_NO == 1
                SDO_CH_NO = DC_CH_NO; 
            else
                DC_ID_NAME = dataCell{1,1}(DC_CH_NO).(DC_FIELDNAME); 
                try
                    sdoI = cellfun(@strcmpi, sdoNameList, DC_ID_NAME); 
                catch
                    sdoI  = strcmp(sdoNameList, DC_ID_NAME); 
                end
                val = find(sdoI,1); 
                if ~isempty(val)
                    SDO_CH_NO = val; 
                else
                    disp("WARNING: No matching detected between fieldnames. Check field names."); 
                end
            end
        end
    end
end

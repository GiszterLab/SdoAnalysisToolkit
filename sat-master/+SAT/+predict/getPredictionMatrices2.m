%% Get Prediction Matrices (V2) 
% Segregated function for calling and evaluating the different predictions;
%
% Used as a single common method to call and create these elements; 
% 
% Upgrade for the newer SAT.analyzer class. 

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
% along with this program.  If not, see <https://www.gnu.org/licenses/>

function H_Struct = getPredictionMatrices2(sdo, xtdc, ppdc, XT_CH_NO, PP_CH_NO, vars)
arguments
    sdo % either sdoStruct, sdoMat, sdoMultiMat
    xtdc xtDataCell
    ppdc ppDataCell
    XT_CH_NO = 1; 
    PP_CH_NO = 1; 
    vars.type {mustBeMember(vars.type, {'M', 'L'})} = 'L'; 
    vars.staMethod {mustBeMember(vars.staMethod, {'dpx', 'px'})} = 'px'; 
    vars.backgroundSubraction = 0; % New
end
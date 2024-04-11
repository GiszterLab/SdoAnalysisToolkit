%H7: SDO Proper
% Sort-of-redundant; Just rips from the sdoStruct

%_______________________________________
% Copyright (C) 2024 Trevor S. Smith
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

function [mat] = getH7(sdoStruct, XT_CH_NO, PP_CH_NO, vars)
arguments
    sdoStruct
    XT_CH_NO
    PP_CH_NO
    vars.type {mustBeMember(vars.type, {'L', 'M'})} = 'L'; 
end

dSDO = sdoStruct(XT_CH_NO).sdos{PP_CH_NO}; 
jSDO = sdoStruct(XT_CH_NO).sdosJoint{PP_CH_NO}; 

switch vars.type
    case 'L'
        mat = SAT.sdoUtils.normsdo(dSDO,jSDO); 
    case 'M'
        mat = normpdfcol2unity(jSDO); 
end


end
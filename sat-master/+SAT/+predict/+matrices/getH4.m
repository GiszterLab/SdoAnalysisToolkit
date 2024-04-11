

%H4: (Normalized) Background SDO; Normalize from struct; 

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

function [mat] = getH4(sdoStruct, XT_CH_NO, vars)
% [mat] = getH4(sdoStruct, XT_CH_NO);
arguments
    sdoStruct
    XT_CH_NO = 1; 
    vars.type {mustBeMember(vars.type, {'L', 'M'})} = 'L'; 
end

dSDO = sdoStruct(XT_CH_NO).bkgrndSDO; 
jSDO = sdoStruct(XT_CH_NO).bkgrndJointSDO; 

switch vars.type
    case 'L'
        mat = SAT.sdoUtils.normsdo(dSDO,jSDO); 
    case 'M'
        mat = normpdfcol2unity(jSDO); 
end


end
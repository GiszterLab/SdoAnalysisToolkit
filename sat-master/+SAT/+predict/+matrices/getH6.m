%H6 STA-Effects on Background; 

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

function [mat] = getH6(at0, at1, sdoStruct, XT_CH_NO, vars)
arguments
    at0
    at1
    sdoStruct
    XT_CH_NO
    vars.type {mustBeMember(vars.type, {'L', 'M'})} = 'L'; 
    vars.method = 'effect'; %idk (Currently STA Method (as in H3)
end

sta_method = vars.method; 

sigLevels = sdoStruct(XT_CH_NO).levels; 
nStates = length(sigLevels)-1; 

% __>> or whatever

[dSdo, jSdo, rdSdo, rjSdo] = ...
    SAT.sdoUtils.get_UnitBkgdShuff_Matrices(sdoStruct, XT_CH_NO, 1, ...
    'reparameterize', 1, 'nShuffles', 1); 


px0  = sum(jSdo.Unit); 
dpx1x0 = sum(dSdo.Unit'); 

%{
%__ shift-mat
ssmat = SAT.sdoUtils.stashiftmat(jSdo.Unit, px0); 
dssmat = SAT.sdoUtils.stashiftmat(dSdo.Unit, dpx1x0); 
%}
% __ sta mat; 
staMat = SAT.predict.matrices.getH3(nStates, ...
    at0, at1, sigLevels, ...
    'type', vars.type, ...
    'method', sta_method); 


%// note that both of these are conditional (i.e. 'deparameterized')
mat = SAT.sdoUtils.sdosum(dSdo.Bkgd,staMat); 


%bk_NjSDO*SAT.sdoUtils.stashiftmat(obj.sdoJoint, staPx); 


end
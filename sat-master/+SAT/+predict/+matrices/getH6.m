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
    vars.method {mustBeMember(vars.method, {'dpx', 'px'})} = 'px';
    %vars.method = 'effect'; %idk (Currently STA Method (as in H3)
end

%sta_method = vars.method; 

sigLevels = sdoStruct(XT_CH_NO).levels; 
nStates = length(sigLevels)-1; 

% __>> or whatever

[dSdo, jSdo, rdSdo, rjSdo] = ...
    SAT.sdoUtils.get_UnitBkgdShuff_Matrices(sdoStruct, XT_CH_NO, 1, ...
    'reparameterize', 1, 'nShuffles', 1); 


%px0  = sum(jSdo.Unit); 
%dpx1x0 = sum(dSdo.Unit'); 

%{
%__ shift-mat
ssmat = SAT.sdoUtils.stashiftmat(jSdo.Unit, px0); 
dssmat = SAT.sdoUtils.stashiftmat(dSdo.Unit, dpx1x0); 
%}
% __ sta mat; 
[normStaMat, staMat, sta_mMat] = SAT.predict.matrices.getH3(nStates, ...
    at0, at1, sigLevels, ...
    'type', vars.type, ...
    'method', 'dpx'); 


nBkdM = SAT.sdoUtils.normsdo(jSdo.Bkgd, jSdo.Bkgd); 
nStaM = SAT.sdoUtils.normsdo(sta_mMat, sta_mMat); 

HConv = nBkdM*nStaM; %convolution of M ~~ Sum of effects (L); 

%sta_px0 = sum(sta_mMat); 
sta_px0 = sum(jSdo.Unit); 

%H5_M = HConv*diag(sta_px0); 
%H5_L = H5_M - diag(sum(H5_M)); 

switch vars.type
    case 'L'
        %mat = H5_L;
        mat = HConv - diag(sum(HConv)); 
    case 'M'
        %mat = H5_M; 
        mat = HConv; 
end


%// note that both of these are conditional (i.e. 'deparameterized')
%mat = SAT.sdoUtils.sdosum(dSdo.Bkgd,staMat); 


%bk_NjSDO*SAT.sdoUtils.stashiftmat(obj.sdoJoint, staPx); 


end
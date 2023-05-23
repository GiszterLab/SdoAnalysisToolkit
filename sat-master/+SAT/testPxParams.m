%% sdoAnalysis_testPxParams
% Utility to test the state mapping and filtering parameters on the
% background distribution of state. Useful for testing different parameters
% to optimize the state transitions
%
% NOT RECOMMENDED: Use 'xtDataCell' class w/ 'plot' method to test
% different state defintions

%_______________________________________
% Copyright (C) 2023 Trevor S. Smith
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
%__________________________________________


N_BINS      = 20; 
XT_MAP_MODE = 'log'; 
PX0_DURA_MS = 10; 
PX1_DURA_MS = 10; 
PX_FSM_WID  = 1; 
PX_FSM_STD  = 1; 
PX_NSHIFT   = 1; 
PX_ZDELAY   = 1; 

XT_CH_NO    = 8; 

testMat = pxTools.getTransitionMatrixFromDC(xtDataCell, XT_DC_CH_NO, ...
    'N_BINS',       N_BINS, ...
    'XT_MAP_MODE',  XT_MAP_MODE, ...
    'PX0_DURA_MS',  PX0_DURA_MS, ...
    'PX1_DURA_MS',  PX1_DURA_MS, ...
    'PX_FSM_WID',   PX_FSM_WID, ...
    'PX_FSM_STD',   PX_FSM_STD, ...
    'PX_NSHIFT',    PX_NSHIFT, ...
    'PX_ZDELAY',    PX_ZDELAY); 

figure; imagesc(testMat); 
xlabel('X_0');
ylabel('X_1'); 
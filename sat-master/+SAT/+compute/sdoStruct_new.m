%% computeSDO_new()
% Construct an empty 'sdo' structure array and populate it with the
% relevant fields; 

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


function [sdo] = sdoStruct_new(N_XT_CHANNELS, N_PP_CHANNELS)
if ~exist("N_PP_CHANNELS", "var")
    N_PP_CHANNELS = 1; 
end

sdo = struct( ...
    'signalType',       cell(1,N_XT_CHANNELS), ...
    'neuronNames',      cell(1,N_XT_CHANNELS), ...
    'levels',           cell(1,N_XT_CHANNELS), ...
    'unit',             cell(1,N_XT_CHANNELS), ...
    'sdosJoint',        cell(1,N_XT_CHANNELS), ...
    'sdos',             cell(1,N_XT_CHANNELS), ...
    'bkgrndJointSDO',   cell(1,N_XT_CHANNELS), ...
    'bkgrndSDO',        cell(1,N_XT_CHANNELS), ...
    'shuffles',         cell(1,N_XT_CHANNELS), ...
    'stats',            cell(1,N_XT_CHANNELS), ...
    'params',           cell(1,N_XT_CHANNELS));%, ...  
    %'shuffledSpikes',   cell(1,N_XT_CHANNELS) ); 

for m = 1:N_XT_CHANNELS
    sdo(m).neuronNames  = cell(1,N_PP_CHANNELS); 
    sdo(m).sdosJoint    = cell(1,N_PP_CHANNELS); 
    sdo(m).sdos         = cell(1,N_PP_CHANNELS); 
    sdo(m).shuffles     = cell(1,N_PP_CHANNELS); 
    sdo(m).stats        = cell(1,N_PP_CHANNELS); 
end


end
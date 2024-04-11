% Support Function which forms of the basis of analysis between a
% ppDataCell and xtDataCell 

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

function [x0_vals, x1_vals] = stateNearSpike(xtdc, ppdc, XT_DC_NO, PP_DC_NO, vars)
    arguments
        xtdc xtDataCell
        ppdc ppDataCell
        XT_DC_NO = 1; 
        PP_DC_NO = 1; 
        vars.dataField {mustBeMember( vars.dataField, {'stateSignal', 'envelope', 'raw'})} = 'stateSignal'; 
        vars.n_shift    = 0; %note this differs from documentation... 
        vars.z_delay    = 0; 
        vars.t0_nPoints {mustBeInteger} = 20; 
        vars.t1_nPoints {mustBeInteger} = 20;
        vars.fs         = xtdc.fs
    end
    % As written, this is consistent with a core 'get' method for both the STA
    % and STIRPD.
    
    % __ >> extract methods; 
    
    if ~xtdc.discretizedData
        xtdc.discretize; 
    end
    
    [ix0, ix1] = ppdc.getPerieventIndices(1:xtdc.nTrials, PP_DC_NO, "fs", xtdc.fs, ...
        'n_shift', vars.n_shift, 'z_delay', vars.z_delay, ... 
        't0_nPoints', vars.t0_nPoints, 't1_nPoints', vars.t1_nPoints, 'fs', vars.fs); 
    
    %// this will only really work when we have the stateSignals;  
    x0 = xtdc.getValuesAtIndices(ix0, "useChannels", XT_DC_NO, 'dataField', vars.dataField); 
    x1 = xtdc.getValuesAtIndices(ix1, "useChannels", XT_DC_NO, 'dataField', vars.dataField); 
    
    x0_vals = cellhcat(x0); 
    x1_vals = cellhcat(x1); 

end

% Handling for probability data/Samplings

% common uses for the pxtDataCell, sdoMat, any use of the stirpd estimation

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

classdef probabilityData < handle
    properties
        stirpd  = zeros(20); 
        nStates = 20; 
        %nBins   = 20; 
    end
    properties (Dependent)
        calculatedStirpd
    end
    methods
        function LI = get.calculatedStirpd(obj)
            if sum(obj.stirpd(:,1)) == 0
                LI = false;
            else
                LI = true; 
            end
        end
        function obj = calculateStirpd(obj, xtdc, ppdc, XT_DC_NO, PP_DC_NO, vars)
            arguments
                obj
                xtdc xtDataCell
                ppdc ppDataCell
                XT_DC_NO = 1; 
                PP_DC_NO = 1; 
                vars.dataField {mustBeMember( vars.dataField, {'stateSignal', 'envelope'})} = 'stateSignal'; 
                vars.n_shift    = 0; %note this differs from documentation... 
                vars.z_delay    = 0; 
                vars.t0_nPoints {mustBeInteger} = 20; 
                vars.t1_nPoints {mustBeInteger} = 20;
                vars.fs         = xtdc.fs
            end
            [x0_vals, x1_vals] = dataCell.calculate.stateNearSpike(xtdc,ppdc, ... 
                XT_DC_NO, PP_DC_NO, 'dataField', vars.dataField, 'n_shift', vars.n_shift, ... 
                'z_delay', vars.z_delay, 't0_nPoints', vars.t0_nPoints, 't1_nPoints', vars.t1_nPoints, ...
                'fs', vars.fs); 
            %
            if isempty(x0_vals)
                x0_vals = []; 
            end
            if isempty(x1_vals)
                x1_vals = []; 
            end
            %
            obj.stirpd = pxTools.getStirpd(x0_vals, x1_vals, obj.nStates); 
        end
    end


end
%% dataCell.properties.intervalProperties
%
% lightweight support parameter class for intervals
% --> Used to sync and pass parameters for intervalSampling.
%
% This class works in concert with 'intervalSampler; 
% Handle class to support inheritance

% Trevor S. Smith, 2025
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

classdef intervalProperties < handle & matlab.mixin.Copyable
    properties
        n_shift     = 0; 
        z_delay     = 0; 
        dura_ms     = 10; 
        fs          = 0; % x(t).fs; 
    end
    properties (Dependent)
        dura_nPoints
    end
    methods 
        % Constructor
        function obj = intervalProperties(N_SHIFT,Z_DELAY,DURA_MS)
            arguments
                N_SHIFT = 0; Z_DELAY = 0; DURA_MS = +10; 
            end
            obj.n_shift = N_SHIFT; 
            obj.z_delay = Z_DELAY;
            obj.dura_ms = DURA_MS; 
            % empty constructor; 
        end
        % ---- 
        function nPoints = get.dura_nPoints(obj)
            nPoints = ceil(obj.fs*obj.dura_ms/1000); % this allows nans; 
        end
        % --- 
        function LI = isChanged(obj, iP)
            arguments
                obj
                iP dataCell.properties.intervalProperties
            end
            sf = fieldnames(obj);
            for f = 1:length(sf)
                LI = (obj.(sf{f}) == iP.(sf{f}));  
                if LI == false
                    break
                end
            end
        end
        % ---- 
    end
    
end

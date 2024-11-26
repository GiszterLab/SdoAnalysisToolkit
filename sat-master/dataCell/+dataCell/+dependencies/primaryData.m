%%

% Primary Data Dependencies 

% Used for the classes which directly interact with data, ensuring good
% handling between interconversion and sampling; 

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

classdef primaryData < handle
    properties
        %// Added here as common utils. 
        data        = []; 
        metadata    = []; 
        dataField   = []; 
        nTrials     {mustBeInteger} = 0; 
        nChannels   {mustBeInteger} = 0; 
        sensor      = []; 
        fs          double {mustBeNonnegative} = 0 
    end

    properties (Hidden, Dependent)
        sampledData {mustBeNumericOrLogical}
    end
    methods
            %% Dynamic/Dependent methods
        function LI = get.sampledData(obj)
            if isempty(obj.data)
                LI = false; 
                return
            end
            N_CHANNELS = size(obj.data{1,1},1); 
            LI = false; 
            %
            tr = 1; 
            while tr <= obj.nTrials
                m = 1; 
                while m <= N_CHANNELS
                    if ~isempty(obj.data{1,tr}(m).(obj.dataField))
                        LI = true; 
                        break
                    end
                    m = m+1; 
                end
                tr = tr+1; 
                if LI == true
                    break
                end
            end
        end
    end
end
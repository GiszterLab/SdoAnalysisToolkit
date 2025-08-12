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
        data        cell = {}; 
        metadata    = {}; 
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
        %_______ Reordering ________
        function obj = reorder(obj, trialOrder, channelOrder)
            arguments
               obj
               trialOrder = []; 
               channelOrder = []; 
            end
            if isempty(trialOrder)
                trialOrder = 1:obj.nTrials; 
            end
            if isempty(channelOrder)
                channelOrder = 1:obj.nChannels; 
            end
            % Easiest way to do this is probably to just reorder and recast
            % the data
            nTr = length(trialOrder); 
            nCh = length(channelOrder); 
            
            CLASS = class(obj); 
            switch CLASS
                case 'ppDataCell'
                    dh = dataCell.constructors.getPpDataHolder(nTr,nCh); 
                case 'xtDataCell'
                    dh = dataCell.constructors.getXtDataHolder(nTr,nCh);
            end
            
            d_dat = obj.data(1,trialOrder); 
            m_dat = obj.metadata(1,trialOrder);
            for tri = 1:nTr
                d_dat{1,tri} = d_dat{1,tri}(channelOrder);
                %m_dat{1,tri} = m_dat{1,tri}(channelOrder);
            end
            dh(1,:) = d_dat; 
            dh(2,:) = m_dat; 
            
            obj.import(dh);
            1; 
            
        end
    end
end
%% stateMap Class (OOP) - D2
%
% Support class for handling the data discretization
% For composition with time series --> State definining public classes

% Do we want this to actually hold probabilistic data, or just have
% everything we need for inheritances?

%_______________________________________
% Copyright (C) 2025 Trevor S. Smith
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

classdef stateMap < handle & matlab.mixin.Copyable
    properties (SetObservable)
        mapMethod   char {mustBeMember(mapMethod, {'linear', 'log', 'linearsigned', 'logsigned'})} = 'log'; 
        maxMode     char {mustBeMember(maxMode, {'pTrial','xTrialxSeg'})} = 'xTrialxSeg'
        nBins       {mustBeInteger, mustBeNonnegative} = 20; 
        %
        channelDefMax = []; % Keep the observed vs. defined max/min separate; 
        channelDefMin = []; % Keep the observed vs. defined max/min separate;
        channelAmpMax = []; % Observed Max x(t)
        channelAmpMin = []; % Observed Min x(t)
        %
        stateMapping = [];  % [N_STATES+1, N_CH, N_TRIALS]
        allowClipping = 0; 
    end
    events
        propertiesChanged
    end
    %-------------------------
    properties (Dependent)
       nTrials 
       nChannels
    end
    properties (Hidden, Dependent)
        determinedMinMax % auto
        definedMinMax    % custom
        definedState
        trialwise 
    end
    %% --------------------------------------------------------------------
    methods
        function LI = get.definedMinMax(obj)
            LI = false; 
            if (~isempty(obj.channelDefMax)) && (~isempty(obj.channelDefMin))
                LI = true; 
            end
        end
        %----------------------------------%
        function LI = get.determinedMinMax(obj)
            LI = false;
            if ~(isempty(obj.channelAmpMax)) && (~isempty(obj.channelAmpMin))
                LI = true; 
            end
        end
        %-----------------------------------%
        function LI = get.definedState(obj)
            LI = false;
            if ~obj.definedMinMax 
                LI = false; 
                return
            end
            if isempty(obj.stateMapping)
                LI = false; 
                return
            end
            if all( diff(obj.stateMapping, [], 1) > 0)
                LI = true; 
            end
        end
        %-----------------------------------%
        function LI = get.trialwise(obj)
            LI = false; 
            if size(obj.stateMapping,3) > 1
                obj.trialwise = true;
            end
        end
        %----------------------------------%
        function n = get.nChannels(obj)
            n = size(obj.channelAmpMax,1); 
        end
        %---
        function n = get.nTrials(obj)
            n = size(obj.channelAmpMax,2); 
        end
        %----------------------------------%
        % // for now, let's just assume we're composing with classes; 
        function obj = getChannelAmp(obj, primaryData)
            arguments
                obj
                primaryData dataCell.primaryData
            end
            %
            obj.channelAmpMax = zeros(primaryData.nChannels, primaryData.nTrials);
            obj.channelAmpMin = zeros(primaryData.nChannels, primaryData.nTrials);
            
            USE_FIELD = primaryData.dataField; 
            for tr = 1:primaryData.nTrials
                for ch = 1:primaryData.nChannels
                    xt = primaryData.data{1,tr}(ch).(USE_FIELD); 
                    obj.channelAmpMax(ch,tr) = max(xt); 
                    obj.channelAmpMin(ch,tr) = min(xt);
                end
            end
            if ~obj.definedMinMax
                obj.channelDefMax = obj.channelAmpMax; 
                obj.channelDefMin = obj.channelAmpMin; 
            end
        end
        %-----------------------------------------------------------%
        function obj = combine(obj, obj2)
            arguments
                obj
                obj2 stateMap
            end
            if ~strcmp(obj.dataType, obj2.dataType)
                disp("Data fields are not the same");
                return
            end
            if ~(obj.nBins == obj2.nBins)
                disp("Bin sizes not compatible"); 
                return
            end
            obj.data        = {obj.data, obj2.data}; 
            obj.metadata    = {obj.metadata, obj2.metadata}; 
            % Retain obj1's classification       
        end
        %-----------------------------------------------------------%
        function obj = buildStateMap(obj)
            obj.stateMapping = zeros(obj.nBins+1, obj.nChannels,  obj.nTrials); 
            for ch = 1:obj.nChannels
                 switch obj.maxMode
                    case {'xTrialxSeg'}
                        sigLv = pxTools.getXtSignalLevels( ...
                            obj.channelDefMax(ch,1), obj.channelDefMin(ch,1), ...
                            obj.nBins, obj.mapMethod); 
                        sigArr = repmat(sigLv, obj.nTrials,1); 
                    case {'pTrial'}
                       sigArr = zeros(obj.nTrials, obj.nBins+1); 
                       for tr = 1:obj.nTrials
                           sigLv = pxTools.getXtSignalLevels(xtMaxArr(tr), xtMinArr(tr), obj.nBins, obj.mapMethod); 
                           sigArr(tr,:) = sigLv; 
                       end                    
                 end               
                obj.stateMapping(:,ch,:) = sigArr'; 
                
            end
            
            if ~obj.allowClipping 
                % Force all values to a state; 
                % this 'should' work, but doesn't with discretize; 
                obj.stateMapping(1,:,:)     = -inf; 
                obj.stateMapping(end,:,:)   = inf; 
            end
        end
        
        %------------------------------------------------------------%
        function data = discretizeSignal(obj, data, vars)
            arguments
                obj
                data dataCell.primaryData
                vars.dataField = data.dataField; 
            end
            
            if ~obj.definedState
                disp("State not yet defined"); 
                return
            end
            
            % NOTE: There may be some difficulties with handling here if
            % the number of trials in the stateMap varies from the data in
            % the primaryData
            
            for tr = 1:data.nTrials
                for ch = 1:data.nChannels
                    data.data{1,tr}(ch).stateSignal = discretize(...
                        data.data{1,tr}(ch).(vars.dataField), ...
                        obj.stateMapping(:,ch,tr)); 
                    %
                    data.data{1,tr}(ch).signalLevels = obj.stateMapping(:,ch,tr);
                end
            end
            
        end
        %---------------------------------------------------------------
        % Pared alternative for use on raw data; 
        function data_out = discretizeSignalRaw(obj, data, useMapCh, useMapTr)
            stateMap = obj.stateMapping; 
            % COPILOT OPT
            if iscell(data)
                [d_row, d_col, d_lvf] = size(data);
                % Generate indices for each cell
                [R, C, L] = ndgrid(1:d_row, 1:d_col, 1:d_lvf);
                % Flatten indices for linear access
                idx = [R(:), C(:), L(:)];
                % Apply discretize using cellfun
                data_out = reshape(cellfun(@(i) discretize(data{i(1), i(2), i(3)}, stateMap(:, i(1), i(2))), ...
                               num2cell(idx, 2), 'UniformOutput', false), d_row, d_col, d_lvf);
            else
                data_out = discretize(data, obj.stateMapping(:, useMapCh, useMapTr(1)));  % Array input-output
            end
            
            %{
            stateMap = obj.stateMapping; 
            if iscell(data) % UPGRADE for 3d [ assume independent channels on X, Trials on y; independent SAMPLES of chanels, on zz
                [d_row, d_col, d_lvf] = size(data); 
                data_out = cell(d_row, d_col, d_lvf); 
                for l = 1:d_lvf
                    for r = 1:d_row
                        for c = 1:d_col
                            data_out{r,c,l} = discretize(data{r,c,l}, stateMap(:,r, c)); 
                        end
                    end
                end
            else
                % Array input-output
                data_out = discretize(data, obj.stateMapping(:,useMapCh, useMapTr(1))); 
            end
            %}
        end
        %-------------------
        function obj_out = subsample(obj, useTrials, useChannels)
            arguments
                obj
                useTrials   = []; 
                useChannels = 1:obj.nChannels; 
            end
            
            if isempty (useTrials)
                useTrials = 1:obj.nTrials; 
            end
            % >> 
            obj_out = copy(obj); 
            sfields = {'channelDefMax', 'channelDefMin', 'channelAmpMax', 'channelAmpMin'};
            for f = 1:4
                obj_out.(sfields{f}) = obj.(sfields{f})(useChannels, useTrials); 
            end
            if obj.definedState
                obj_out.stateMapping = obj.stateMapping(:,useChannels,useTrials); 
            end
        end
        %---
    end
            
end

%% Auxillary Functions
% These are functions ONLY to be called within the validation of this
% class, but are not accessible outside of this class
function validateBounds(x, lowerBound, upperBound)
    if any(x < lowerBound) || any(x > upperBound)
        error('Each element must be between %d and %d.', lowerBound, upperBound);
    end
end

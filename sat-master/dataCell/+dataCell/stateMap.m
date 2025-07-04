%% stateMap Class (OOP) - D2

% Support class for handling the data discretization
% For composition with time series --> State definining public classes

% Do we want this to actually hold probabilistic data, or just have
% everything we need for inheritances?
% --> Probably make this lightweight and composable

%TODO: Better subsampling for trialwise handling [x]


classdef stateMap < handle & matlab.mixin.Copyable
    properties
        mapMethod   char {mustBeMember(mapMethod, {'linear', 'log', 'linearsigned', 'logsigned'})} = 'log'; 
        maxMode     char {mustBeMember(maxMode, {'pTrial','xTrialxSeg'})} = 'xTrialxSeg'
        nChannels   = 0; 
        nTrials     = 0; 
        nBins       {mustBeInteger, mustBeNonnegative} = 20; 
        %
        channelDefMax = []; % Keep the observed vs. defined max/min separate; 
        channelDefMin = []; % Keep the observed vs. defined max/min separate;
        %
        stateMapping = []; % Let's set this up as a [N_STATES+1, N_CH, N_TRIALS]
        % These should be defined on sample; 
        channelAmpMax 
        channelAmpMin
        %
        allowClipping = 0; 
    end
    
    properties (Hidden, Dependent)
        determinedMinMax % auto
        definedMinMax    % custom
        definedState
        trialwise 
    end
    
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
        % // for now, let's just assume we're composing with classes; 
        function obj = getChannelAmp(obj, primaryData)
            arguments
                obj
                primaryData dataCell.primaryData
            end
            %
            obj.nChannels   = primaryData.nChannels; 
            obj.nTrials     = primaryData.nTrials; 
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
                disp("nC"); 
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

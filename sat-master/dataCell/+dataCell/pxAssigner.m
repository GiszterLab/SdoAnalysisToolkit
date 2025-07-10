%% pxAssigner (OOP) V2

% Support class for probability-based methods 
% (Replaces probalistic inheritance). 
%
% How to assign probability distributions to intervals of signal. 

% --> Not sure whether it makes more sense to including reverse mapping
% functions from p(x)-->x or to place in a different class. 

% TO ADD; Kernel-level operations on the distributions; splining/gaussians

% Trevor S. Smith, 2025

classdef pxAssigner < handle & matlab.mixin.Copyable
    properties
        data        = {};   
        weighting   = 'equal';
        sensor cell = {}; 
        % __ For (Gaussian) filter Kernel______
        G_smoothFWidth_Pts = 0; 
        G_smoothFStdev_Pts = 0; 
    end
    properties (Dependent)
        nStates
        nChannels
        nTrials
        nObservations 
    end
    properties (Hidden)
        filteredDistributions   = 0; 
    end
    properties(Dependent, Hidden)
        sampledData
    end
    
    methods
        function LI = get.sampledData(obj)
            LI = ~isempty(obj.data); 
        end
        %----------------------------------
        function n = get.nChannels(obj) 
            n = size(obj.data,1); 
        end
        function n = get.nTrials(obj)
            n = size(obj.data,2); 
        end
        %----------------------------------
        function n = get.nStates(obj)
            if ~obj.sampledData
                n = 0;
                return
            else
                n = size(obj.data{1,1}); 
            end
        end
        %-----------------------------------
        function mat = get.nObservations(obj)
            mat = zeros(obj.nChannels, obj.nTrials); 
            for ch = 1:obj.nChannels
                for tr = 1:obj.nTrials
                    mat(ch,tr) = size(obj.data{ch,tr},2); 
                end
            end
        end
            
        %-----------------------------------
        % TODO: I should probably pare this back a bit
        
        % >> This is kind of weird that we define state upstream in xtdc,
        % but then have to reasample it here...
                  
        function obj = assignPx(obj, stateMap, intervalData)
            arguments
                obj
                stateMap        dataCell.stateMap
                intervalData    dataCell.intervalSampler
            end
            if ~stateMap.definedState
                disp("state map not yet defined"); 
            end
            
            %TODO: Better extract discretized signals... or else pull
            %discretized data from xtdc.data; 

            xOut    = stateMap.discretizeSignalRaw(intervalData.data);
            %{
            binArr = repelem({stateMap.nBins}, obj.nChannels, obj.nTrials); 
            weiArr = repelem({obj.weighting}, obj.nChannels, obj.nTrials); 
            %}
            binArr = repelem({stateMap.nBins}, intervalData.n_XT_Channels, intervalData.nTrials); 
            weiArr = repelem({obj.weighting}, intervalData.n_XT_Channels, intervalData.nTrials);             
            
            pxOut = cellfun(@pxTools.getPxFromX, xOut, binArr, weiArr, 'uniformOut', 0); 
            %
            if ~iscell(pxOut)
                pxOut = {pxOut}; 
            end
            obj.data   = pxOut; 
            if iscell(intervalData.sensor_xt())
                obj.sensor = intervalData.sensor_xt(); 
            else
                % Temp patch; 
                obj.sensor = {intervalData.sensor_xt()}; 
            end
        end
        %----------------------------------------------------------------%
        function obj = gaussianFilter(obj)
            if obj.filteredDistributions == 1
                disp("Distributions already filtered"); 
                return
            end
            G = pxTools.getH0Array(obj.nStates, obj.G_smoothFWidth_Pts, obj.G_smoothFStdev_Pts); 
            for tr = 1:obj.nTrials
                for ch = 1:obj.nChannels
                    obj.data{ch,tr} = G*obj.data{ch,tr}; 
                end
            end
        end
        %----------------------------------------------------------------
        function obj = hcat(obj)
            obj.data = cellhcat(obj.data); 
        end
        %----------------------------------------------------------------
        function obj = vcat(obj)
            obj.data = cellvcat(obj.data); 
        end
        %----------------------------------------------------------------
        % // Use to ensure compability prior to operations; 
        function LI = isCompatible(obj, pxa)
            arguments
                obj
                pxa dataCell.pxAssigner
            end
            LI = true; 
            if ~(obj.nChannels == pxa.nChannels)
                LI = false; 
                return
            end
            if ~(obj.nTrials == pxa.nTrials)
                LI = false; 
                return
            end
            for ch = 1:obj.nChannels
                for tr = 1:obj.nTrials
                    if ~(obj.nObservations(ch,tr) == pxa.nObservations(ch,tr))
                        LI = false; 
                    end
                end
            end
        end
        %------------------------------------------------------------
        function pxCell = assignPxRaw(obj, stateMap, xCell)
            arguments
                obj
                stateMap    dataCell.stateMap 
                xCell       cell
            end
            % xCell is a {x,y} cell of [idx, col, shuff] array; 
            
            nUseTr = stateMap.nTrials; 
            nUseCh = stateMap.nChannels;
            
            pxCell = cell(nUseCh, nUseTr);  
            for tr = 1:nUseTr
                for ch = 1:nUseCh
                    pxCell{ch,tr} = pxTools.getPxFromX(xCell{ch,tr}, stateMap.nBins, obj.weighting); 
                end
            end
        end
        %-------------------------------------------------------------
        function f = imagesc(obj, useTrials, useChannels)
            arguments
                obj
                useTrials   = 1:obj.nTrials
                useChannels = 1:obj.nChannels
            end
            obj_tmp = copy(obj); 
            obj_tmp.data = obj_tmp.data(:,useTrials); 
            obj_tmp.data = obj_tmp.data(useChannels,:);
            obj_tmp.hcat(); 
            obj_tmp.vcat(); 
            %-----------------------------------------------------------
            if nargout > 0
                f = figure; 
            end
            imagesc(obj_tmp.data);
            title(strcat("P(x,t):", obj.sensor{useChannels})); 
            axis xy
            xlabel("Position")
            ylabel("State (x)");    
        end
        %-------------------------------------
        function f = plot(obj) % alias
            if nargout > 0
                f = obj.imagesc(); 
            else
                figure; 
                obj.imagesc;
            end
        end
    end 
end

function CH_IDX = getChannelIndex(obj, NAME)
[CH_IDX] = find(ismember(cellfun(@char, obj.sensor, ...
    'uniformOutput',0), cellfun(@char, NAME, 'uniformOutput',0))); 
end
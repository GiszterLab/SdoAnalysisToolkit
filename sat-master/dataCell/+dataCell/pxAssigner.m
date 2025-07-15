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
        data  cell = {};  %OUTPUT
        % __ Import_Only:  
        sensor cell = {}; 
        config dataCell.properties.pxProperties
    end
    properties (Dependent)
        nStates
        nChannels % I think this is nXTChannels
        nReplicates
        nTrials
        nObservations 
    end
    properties (Hidden)
        filteredDistributions = 0; 
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
        function n = get.nReplicates(obj)
            n = size(obj.data,3); 
        end
        %----------------------------------
        function n = get.nStates(obj)
            if ~obj.sampledData
                n = 0;
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
        % ____ Slaves; 
        function obj = pxAssigner(pxProperties)
            arguments
                pxProperties dataCell.properties.pxProperties = dataCell.pxProperties(); 
            end
            obj.config = pxProperties;
        end
        
        %--------
        function obj = assignPx(obj, stateMap, intervalData)
            arguments
                obj
                stateMap        dataCell.stateMap
                intervalData    dataCell.intervalSampler
            end
            if ~stateMap.definedState
                disp("state map not yet defined"); 
            end
            
            % We assume interval.data is of the form {N_CHAN, N_TRIAL,
            % N_SAMP/SPIKES} % stateMaps are applied to each value of DIM
            % 1. 
            
            %TODO: Better extract discretized signals... or else pull
            % data from xtdc.data; 
            
            xOut    = stateMap.discretizeSignalRaw(intervalData.data);
            pxOut = obj.assignPxRaw(stateMap, xOut);
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
            if ~all( (obj.nObservations - pxa.nObservations) == 0)
                LI = false; 
            end
        end
        %------------------------------------------------------------
        function pxCell = assignPxRaw(obj, stateMap, xCell)
            arguments
                obj
                stateMap    dataCell.stateMap 
                xCell       cell
            end
            % xCell is a {x,y,z} cell of [Xi, col, shuff] array; 
            [ix_x, ix_y, ix_z] = size(xCell); 
            
            smBins3 = repelem({stateMap.nBins}, ix_x, ix_y, ix_z); 
            weight3 = repelem({obj.config.weighting},  ix_x, ix_y, ix_z); 
            
            pxCell = cellfun(@pxTools.getPxFromX, xCell, smBins3, weight3,'uniformOut', 0); 
            %{
                        nUseTr = stateMap.nTrials; 
            nUseCh = stateMap.nChannels;
            pxCell = cell(nUseCh, nUseTr);  
            for tr = 1:nUseTr
                for ch = 1:nUseCh
                    pxCell{ch,tr} = pxTools.getPxFromX(xCell{ch,tr}, stateMap.nBins, obj.weighting); 
                end
            end
            %}
        end
        %-------------------------------------------------------------
        function obj_out = subsample(obj, useXtChannels, useTrials, usePpChannels)
            arguments
                obj
                useXtChannels   = 1:obj.nChannels; 
                useTrials       = 1:obj.nTrials; 
                usePpChannels   = 1:obj.nReplicates;
            end
            obj_out = copy(obj); 
            if ~obj.sampledData
                return
            end
            obj_out.data = obj_out.data(useXtChannels,useTrials,usePpChannels); 
            obj_out.sensor = obj_out.sensor(useXtChannels); 
        end
        %-------------------------------------------------------------
        function f = imagesc(obj, useTrials, useChannels, useReplicates)
            arguments
                obj
                useTrials       = 1:obj.nTrials
                useChannels     = 1:obj.nChannels
                useReplicates   = 1:obj.nReplicates;
            end
            obj_tmp = copy(obj);
            obj_tmp.data = obj_tmp.data(:,:,useReplicates);
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
        %-----------------------------------
    end 
end

function CH_IDX = getChannelIndex(obj, NAME)
[CH_IDX] = find(ismember(cellfun(@char, obj.sensor, ...
    'uniformOutput',0), cellfun(@char, NAME, 'uniformOutput',0))); 
end
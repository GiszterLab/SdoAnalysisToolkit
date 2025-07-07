%% pxAssigner (OOP) V2

% Support class for probability-based methods 
% (Replaces probalistic inheritance). 
%
% How to assign probability distributions to intervals of signal. 

% --> Not sure whether it makes more sense here to go from px-->x or at a
% different class

% TO ADD; Kernel-level operations on the distributions; splining/gaussians

% 2025

classdef pxAssigner < handle & matlab.mixin.Copyable
    properties
        data        = {};   
        weighting   = 'equal';
        sensor cell = {}; 
        % __ For filter Kernel______
        G_smoothFWidth_Pts = 0; 
        G_smoothFStdev_Pts = 0; 
    end
    properties (Hidden)
        filteredDistributions   = 0; 
    end
    properties(Dependent, Hidden)
        nStates
        sampledData
        nChannels
        nTrials
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
            
            xOut = cell(intervalData.n_XT_Channels, intervalData.nTrials); 
            for tr = 1:intervalData.nTrials
                for ch = 1:intervalData.n_XT_Channels
                    
                    % TODO: Better validate which rows are are looking at;
                    % indices; 
                    
                    xOut{ch, tr} =  stateMap.discretizeSignalRaw(intervalData.data{ch,tr}, ch, tr); 
                end                
            end
            % _______ >> assign px
            
            % TODO: Pare back this library a bit; 
            
            pxOut = cell(intervalData.n_XT_Channels, intervalData.nTrials); 
            for tr = 1:intervalData.nTrials
                for ch = 1:intervalData.n_XT_Channels
                    pxOut = pxTools.getPxFromX(xOut{ch,tr}, stateMap.nBins, obj.weighting); 
                end
            end
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
            %obj.sensor = intervalData.sensor(); %for now, simple copy; 
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
        
    end 
end

function CH_IDX = getChannelIndex(obj, NAME)
[CH_IDX] = find(ismember(cellfun(@char, obj.sensor, ...
    'uniformOutput',0), cellfun(@char, NAME, 'uniformOutput',0))); 
end
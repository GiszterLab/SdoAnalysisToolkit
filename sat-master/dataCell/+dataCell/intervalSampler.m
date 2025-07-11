%% dataCell.intervalSampler
% 
% Support Class for drawing intervals from time events
%
% Useful for defining intervals. 
% A mix-in for classes which have events, around which we may want to draw
% distributions; 
%   - ppDataCell, pxtDataCell, eventDataCell, sdos
%
% called by pxtDataCell

% This is going to be the new method for defining the sampling properties
% from data; used to draw distributions, as necessary. 

% How we should handle pre-spike vs. post-spike intervals is a bit murky.
% It may make sense to have an intervalSampler for both prepspike and
% post-spike. 
% --> The only issue is that we will need to have some way to interface
% between them if we use a bootstrapping method. (Draw from both)

% UPGRADES: 
    % --> Here, we should replace the intervals in bins, to intervals in
    % times. 
    
    % NOTE: 'fs' here should be matched to the .fs of the SAMPLED signal,
    % not the times. 

    % It 'may' make sense to convert this from px0 OR px1 to px0&px1 (i.e.,
    % sample the entire interval of interest) --> SDO. 
    
classdef intervalSampler < handle & matlab.mixin.Copyable
    properties
        config dataCell.properties.intervalProperties
        data        = []; %{N_XT_CHANNELS, N_TRIALS}
        indices     = []; %{N_PP_CHANNELS, N_TRIALS}
        % >> We want a way to define these directly; 
        sensor_idx  = []; % For index origin
        sensor_xt   = []; % For sampling origin
    end
    properties (Dependent)
        nTrials
        n_IDX_Channels
        n_XT_Channels
        % Slaved
        %{
        dura_nPoints
        n_shift     %= 0; 
        z_delay     %= 0; 
        dura_ms     %= 10; 
        fs          %= 0; % x(t).fs; 
        %}
    end
    properties (Dependent, Hidden)
        calculatedIndices
        sampledData 
    end
    methods
        %---------------------------------%
        function LI = get.calculatedIndices(obj)
            LI = ~isempty(obj.indices); 
        end
        function LI = get.sampledData(obj)
            LI = ~isempty(obj.data); 
        end
        function n = get.nTrials(obj)
            n = size(obj.indices,2); 
        end
        function n = get.n_IDX_Channels(obj)
            n = size(obj.indices,1); 
        end
        function n = get.n_XT_Channels(obj)
            n = size(obj.data, 1); 
        end
        %{
        % -- Define Set/Get with slaves -- %
        function n = get.dura_nPoints(obj)
            n = obj.config.dura_nPoints; 
        end
        function n = get.n_shift(obj)
            n = obj.config.n_shift; 
        end
        function set.n_shift(obj, n)
            obj.config.n_shift = n; 
        end
        function n = get.z_delay(obj)
            n = obj.config.z_delay; 
        end
        function set.z_delay(obj, n)
            obj.config.z_delay = n; 
        end
        function n = get.dura_ms(obj)
            n = obj.config.dura_ms; 
        end
        function set.dura_ms(obj,n)
            obj.config.dura_ms = n; 
        end
        function n = get.fs(obj)
            n = obj.config.fs; 
        end
        function set.fs(obj,n)
            obj.config.fs = n; 
        end
        %}
        %---------------------------------%
        function obj = intervalSampler(intervalProperties)
            arguments
                intervalProperties dataCell.properties.intervalProperties = dataCell.properties.intervalProperties; 
            end
            obj.config = intervalProperties;
            % Constructor -- To Fill 
        end

        % -----------------------------%
        % // Get indicies from ppDataCell, etc. 
        function obj = getIntervalIndices(obj, data, useTrials, useChannels, vars)
            arguments
                obj
                data dataCell.primaryData % SPIKES
                useTrials   = 1:data.nTrials;
                useChannels = 1:data.nChannels; 
                vars.dataField = data.dataField; 
                vars.input {mustBeMember(vars.input, {'times', 'indices'})} = 'times'; 
            end
            if ~strcmp(data.dataType, 'ppData')
                disp("Intervals not defined for provided dataType"); 
            end
            if isnan(obj.config.dura_nPoints)
                disp("Sample Frequency must be defined first"); 
            end
            
            nUseChannels    = length(useChannels); 
            nUseTrials      = length(useTrials); 
            
            % Convert from sec --> xtdc.indices; 
            st_tr = data.getData(useTrials, useChannels, 'dataField', vars.dataField); 
            idx_tr = cellfun(@times, st_tr, repelem({obj.config.fs}, nUseChannels, nUseTrials), 'uniformOutput', 0); 
            idx_tr = cellfun(@round, idx_tr, 'uniformOutput', 0); 
            
            idx = cell(nUseChannels, nUseTrials);
            
            % __>> this is converting to 3D for some reason; 
            for tri = 1:nUseTrials
                maxIdx = data.trTimeLen(tri)*obj.config.fs; 
                idx(:,tri) = pxTools.getIntervals(idx_tr(:,tri), ...
                    'nShift', obj.config.n_shift, 'nPoints', obj.config.dura_nPoints, 'maxLen', maxIdx); 
            end
            obj.indices = idx;  
            obj.sensor_idx = data.sensor{useChannels};
        end
        % // use existing indices to sample points; 
        % --> Here we assume nTrials is comparable; if not, we need to
        % subsample. 
        function obj = samplePrimaryData(obj, data, vars)
            arguments
                obj
                data dataCell.primaryData % e.g. xtDataCell.data; 
                vars.useTrials      = 1:obj.nTrials; 
                vars.useChannels    = 1:data.nChannels;
            end
            if ~obj.calculatedIndices
                disp("Calculate indices first")
                return
            end
            %  
            obj.conform(data, 'type', 'indices'); 
            
            obj.data = data.getValuesAtIndices( obj.indices(:,vars.useTrials), ...    
                'useChannels',  vars.useChannels, ...
                'useTrials',    vars.useTrials, ...
                'dataField',    data.dataField); 
            %
            obj.sensor_xt = data.sensor{vars.useChannels};
            obj.config.fs = data.fs;
        end
        %----------------- These are 'raw' overrides for shuffle -------
        function indexCell = getIntervalIndicesRaw(obj, stCell, TYPE, fs)
            arguments
                obj
                stCell % spike-time Cell {times!!!!}
                TYPE {mustBeMember(TYPE, {'signal', 'state'})} = 'signal';
                fs = obj.config.fs; 
            end
            % operate directly on trains; 
            [nUseChannels, nUseTrials] = size(stCell); 
            % convert times --> idx
            switch TYPE
                case 'signal'
                    ixCell = cellfun(@times, stCell, repelem({fs}, nUseChannels, nUseTrials), 'uniformOutput', 0); 
                    ixCell = cellfun(@round, ixCell, 'uniformOutput', 0); 
                case 'state'
                    ixCell = stCell; %override 
            end
            %
            indexCell = pxTools.getIntervals(ixCell, ...
                    'nShift', obj.n_shift, 'nPoints', obj.dura_nPoints);  
        end
        %--------------
        % // This is a simple fusion method // 
        function obj_out = discretize(obj, stateMap)
            arguments
                obj
                stateMap dataCell.stateMap
            end
            obj_out = copy(obj);
            obj_out.data  = stateMap.discretizeSignalRaw(obj.data); 
        end
        %--------------------
        % // Conform method for min/max indices; 
        function obj = conform(obj, data, vars)
            arguments
                obj
                data dataCell.primaryData
                vars.type {mustBeMember(vars.type, {'times', 'indices'})} = 'times'; 
            end
            % TODO: Make this a generic setter method w/ concrete
            % implementation. 
            obj.config.fs = data.fs; 
            for tr = 1:obj.nTrials
                for ch = 1:obj.n_XT_Channels
                    switch vars.type
                        case 'indices'
                            % include interval start/ends
                            tMin = 1 + max([-obj.dura_nPoints,0]); %TODO: Upgrade for multi
                            tMax = ceil(data.trTimeLen(1,tr)*data.fs) - max([obj.dura_nPoints,0]);
                            %
                            IX = obj.indices{ch,tr}; 
                            IX(IX < tMin) = tMin; 
                            IX(IX > tMax) = tMax; 
                            obj.indices{ch,tr} = IX;
                        case 'times'
                            % include interval start/ends
                            tMin = 0 + max(+[-obj.dura_ms, 0]); %TODO: passthrough upgrade for xt
                            tMax = data.trTimeLen(1,tr) - max([obj.dura_ms, 0]); 
                            %
                            tX = obj.data{ch,tr}; 
                            tX(tX<tMin) = tMin; 
                            tX(tX>tMax) = tMax; 
                            obj.data{ch,tr} = tX; 
                    end     
                end
            end
        end
        % ------------------>> Simple plotter; 
        function f = plot(obj, vars)
            arguments
                obj
                vars.useTrials      = 1:obj.nTrials;
                vars.useChannels    = 1:obj.n_XT_Channels; 
            end
            if nargout > 0
                f = figure; 
            end
            % >> cat down? 
            for chi = 1:length(vars.useChannels)
                ch = vars.useChannels(chi); 
                for tri = 1:length(vars.useTrials) 
                    tr = vars.useTrials(tri);
                    plot(obj.data{ch,tr}); 
                    hold on;
                end
            end
        end
    end
end
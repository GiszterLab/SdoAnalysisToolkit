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
    
    % --> Let's try to make this as lightweight as possible; no shoving
    % data in here. 
    
    % NOTE: 'fs' here should be matched to the .fs of the SAMPLED signal,
    % not the times. 

classdef intervalSampler < handle & matlab.mixin.Copyable
    properties
        data        = []; %{N_XT_CHANNELS, N_TRIALS}
        indices    = []; %{N_PP_CHANNELS, N_TRIALS}
        n_shift     = 0; 
        z_delay     = 0; 
        dura_ms     = 10; 
        fs = 0; 
        %
        sensor_idx  = []; % For index origin
        sensor_xt   = []; % For sampling origin
    end
    properties (Dependent)
        nTrials
        n_IDX_Channels
        n_XT_Channels
        dura_nPoints
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
        %---------------------------------%
        function obj = intervalSampler(fs)
            obj.fs = fs; getValuesAtIndices
            % Constructor -- To Fill 
        end
        %------------------------------%
        function nPoints = get.dura_nPoints(obj)
            nPoints = ceil(obj.fs*obj.dura_ms/1000); % this allows nans; 
        end
        % -----------------------------%
        % // Get indicies from ppDataCell, etc. 
        function obj = getIntervalIndices(obj, data, useTrials, useChannels)
            arguments
                obj
                data dataCell.primaryData
                useTrials   = 1:data.nTrials;
                useChannels = 1:data.nChannels; 
            end
            if ~strcmp(data.dataType, 'ppData')
                disp("Intervals not defined for provided dataType"); 
            end
            
            if isnan(obj.dura_nPoints)
                disp("Sample Frequency must be defined first"); 
            end
            
            nUseChannels    = length(useChannels); 
            nUseTrials      = length(useTrials); 
            
            % Convert from sec --> xtdc.indices; 
            st_tr = data.getData(useTrials, useChannels); 
            idx_tr = cellfun(@times, st_tr, repelem({obj.fs}, nUseChannels, nUseTrials), 'uniformOutput', 0); 
            idx_tr = cellfun(@round, idx_tr, 'uniformOutput', 0); 
            
            idx = cell(nUseChannels, nUseTrials);
            
            for tri = 1:nUseTrials
                maxIdx = data.trTimeLen(tri)*obj.fs; 
            
                [idx_t0, ~] = pxTools.getPerieventIndices(idx_tr(:,tri), ...
                    'n_shift', obj.n_shift, 'z_delay', obj.z_delay, ...
                    't0_nPoints', obj.dura_nPoints, 't1_nPoints', 0, 'maxLen', maxIdx); 
                idx(:,tri) = idx_t0; 
            
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
                       
            obj.data = data.getValuesAtIndices( obj.indices(:,vars.useTrials), ...    
                'useChannels',  vars.useChannels, ...
                'useTrials',    vars.useTrials, ...
                'dataField',    data.dataField); 
            
            obj.sensor_xt = data.sensor{vars.useChannels};
            
        end
        
    end
end
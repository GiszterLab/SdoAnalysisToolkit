%% dataCell.shuffler
%
% Support class handling the resampling and shuffling operations handled by
% the probablistic and statistical testing methods; 
% 
% >> Eventually, it would be nice to upgrade this to compensate for other
% methods of sampling, including GLMs. 

classdef shuffler < handle & matlab.mixin.Copyable
    properties
        data        = {}; % for holding data; 
        nShuffles   {mustBeInteger} = 1000; 
        shuffMethod char    {mustBeMember(shuffMethod, {'isi', 'cif', 'random'})} = 'isi'; 
        shuffTau    double  = 0.2; 
        shuffCIF    char    {mustBeMember(shuffCIF, {'sg', '-hg', 'expd', 'tb'})} = '-hg'; 
        %
        shuffleData = {}; %{nTrials, nChannels} of [nShuffles, dat]
    end
    
    properties(Dependent)
        importedData 
        shuffledData  % This is a logical; 
        nTrialEvents 
        nChannels
        nTrials
        sensor 
        fs
    end
    
    %% ------------------------------------- %%
    methods 
        function obj = shuffler()
            % empty constructor; 
        end
        
        function LI = get.shuffledData(obj)
            LI = false; 
            if ~isempty(obj.shuffleData)
                LI = true;
            end
        end
        %------------------
        function nTrials = get.nTrials(obj)
            if ~obj.importedData
                nTrials = size(obj.shuffleData,2); 
            else
                nTrials = obj.data.nTrials;
            end
        end
        %-------------------------------
        function nChannels = get.nChannels(obj)
            if ~obj.importedData
                nChannels = size(obj.shuffleData,1);  
            else
                nChannels = obj.data.nChannels;
            end
        end       
        %------------------------------
        function sensor = get.sensor(obj)
            sensor = obj.data.sensor; 
        end
        %-------------------------------
        function LI = get.importedData(obj)
            LI = ~isempty(obj.data); 
        end
        %----------------------------------%
        function fs = get.fs(obj)
            if ~obj.importedData
                fs = []; 
            else
                fs = obj.data.fs; 
            end
        end
        %------------------------------------------
        function obj = import(obj, data)
            arguments
                obj
                data dataCell.primaryData; 
            end
            data.validateData;
            obj.data = data; 
        end
        %------------------------------------------
        function [obj] = random(obj, nTrials, nChannels, nEvents, vars)
            arguments
                obj
                nTrials
                nChannels
                nEvents
                vars.maxX % either in X (if index) or T (if times)
                vars.type {mustBeMember(vars.type, {'times', 'index'})} = 'index'; 
                vars.seed = []; 
            end
            % // basically just randomly populate the shuffler; For null
            % hypothesis testing/background. 
            randCell = cell(nChannels, nTrials); 
            
            % could place this as 'all-at-once' but may hit a memory
            % bottleneck
            
            % TODO: Implement a seed pass for reproducibility; 
            
            % --> shuffling index can be odd. 
            
            for tr = 1:nTrials
                for ch = 1:nChannels
                    switch vars.type
                        case 'index'
                            % --> This gets a bit awkward to work with.
                            randCell{ch,tr} = sort(randi(vars.maxX, [1,nEvents]));
                        case 'times'
                            % TODO: Add in a FS multiplier. 
                            randCell{ch,tr} = sort(rand(1, nEvents))*vars.maxX; 
                    end
                end
            end
            
            % Not sure if I should override the property here. 
            obj.shuffleData = randCell; 
        end
        
        % // If data is already populated, we can use this command to
        % regenerate different shuffles // 
        function [obj,data] = shuffle(obj, data, vars)
            arguments
                obj
                data                dataCell.primaryData = obj.data;
                vars.useTrials      {mustBeNumeric} = 1:data.nTrials; 
                vars.useChannels    {mustBeNumeric} = 1:data.nChannels; 
            end
            N_USE_CH = length(vars.useChannels); 
            N_USE_TR = length(vars.useTrials); 
            shuffData = cell(N_USE_CH, N_USE_TR); 
            % ___ TRIALWISE SHUFFLE RESAMPLER
            for chi = 1:N_USE_CH
                ch = vars.useChannels(chi); 
                for tri = 1:N_USE_TR
                    tr = vars.useTrials(tri); 
                    ppTrData = data.data{1,tr}(ch).(data.dataField); 
                    nTrEvents = data.nTrialEvents(ch,tr); 
                    if nTrEvents > 1
                        switch obj.shuffMethod
                            case {'isi'}
                                shuff = shuffleSpikesInsideRange(ppTrData, ppTrData(1), ppTrData(end), obj.nShuffles); 
                            case {'cif'} 
                                shuff = cifReshuffle(ppTrData, data.fs, obj.nShuffles, obj.shuffTau,  'method', obj.shuffCIF); 
                                shuff = sort(shuff,2); 
                        end
                    else
                        shuff = repmat(ppTrData, N_SHUFFLES, 1);
                    end
                    shuffData{ch,tr} = shuff; 
                    if nargout > 1
                        % This populates the 'shuffle' field of ppData;
                        data.data{1,tr}(ch).shuffle = shuff; 
                    end
                end
            end
            obj.shuffleData = shuffData;  %{nChannels,nTrials} of [nShuff, dat]            
        end
        %-------------------------------------------------------------
        function ppData = getPpData(obj)
            % extract a (shuffled) primaryData; 
            % !!! This 'does' work, but it can cause downstream issues, if
            % shuffles are pegged to 'times'
            % --> better to leave within the dedicated 'shuffle' or just
            % pass the whole shuffler.
            if obj.importedData
                ppData = obj.data; 
            else
                ppData = dataCell.primaryData('ppData', obj.nTrials, obj.nChannels);
            end
            for tr = 1:obj.nTrials
                for ch = 1:obj.nChannels
                    % // originally we ran this in the 'shuffle' field, but
                    % it may make sense to take it from spikes; 
                    
                    ppData.data{1,tr}(ch).times     = obj.shuffleData{ch,tr}; 
                    %{
                   ppData.data{1,tr}(ch).shuffle   = ...
                    obj.shuffleData{ch,tr};
                    %}
                end
            end
            ppData.dataType = 'ppData'; 
            ppData.calc_trTimeLen(); 
            ppData.validateData(); 
        end
    end
end
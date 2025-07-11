%% SAT.analyzer (V2-OOP)
%
% NEW analysis class for SDO analysis. >> This is a breakout of existing
% methods, which allows us to better segreate SDOs for spike-triggered
% analysis vs. SDO for utilities.
%
% This class is designed for running the unit, background, and shuffle
% SDOs, and extracting the various analyzes/significance testing as
% intersections of these SDOs. 
% 
% --> This better segregates the base SDO methods/computations from the
% analysis methods. 

% --> I may want to rename/integrate the 'sdoMat' class to better hold
% everything we need. 

% NOTE: {sdoMat}.stateMapping properties are bidirectionally lined to the
% analyzer.stateMapping properties; modifying one will modify the others.

% WARNING: Shifts to SDO definitions properties are only unimodal analzyer
% --> sdoMats; 

classdef analyzer < handle & matlab.mixin.Copyable
    properties
        unitSDO         sdoMat   % This is the master input data component; 
        shuffleSDO      sdoMat
        backgroundSDO   sdoMat
        %
        stateMapping    dataCell.stateMap % MASTER --> Slave downstream; 
        %
        sdoConfig       SAT.properties.computerProperties
        % __ These pass through __ 
        x0Config        dataCell.properties.intervalProperties 
        x1Config        dataCell.properties.intervalProperties 
        pxConfig        dataCell.properties.pxProperties
        %
        % Core Properties
        errorStruct 
        nBackgroundPts        = 10000; % per-trial  
        %% ------------------------------
        handleTrials          = 'concat'; % DUMMY 
        pValue                = 0.05; 
    end  
    properties (Hidden)
        configSnapshot
        %wasChanged = false; % used to flag for changed properties
        stateMapListenerObj
        %
        ListenerObj_algo
        ListenerObj_bckSub
        ListenerObj_parComp
        ListenerObj_lowMem
        ListenerObj_verbose
        ListenerObj_trialHandle
    end
    
    properties (Dependent)
        stateMap    % slaved to unit?
        nPpChannels
        nXtChannels
        nTrials 
        % --> Bidirectional Get/Set
         %% ____ >> THESE NEED CALLBACKS WHEN CHANGED
         %{
        algorithm           %{mustBeMember(algorithm, {'v3', 'v5', 'v7'})} = 'v3';
        backgroundSubtraction %= true; % This should be handled upstream. [or here]
        parallelCompute       %= false; 
        lowMemory             %= false; 
        nShuffles             %= 1000; 
        %  __ State Definitions ___ 
         %}
        nStates
        
    end
    properties (Hidden, Dependent)
        importedData
        definedState
        computedBackgroundSdo
        computedShuffleSdo
        changedProperties; 
    end
    
    methods 
        % -------- Constructor --------
        function obj = analyzer(N_XT, N_PP)
            arguments
                N_XT = 1; 
                N_PP = 1;
            end
            % // Masters// 
            stateMap = dataCell.stateMap(); % Generate 1x; slave;
            x0Config = dataCell.properties.intervalProperties(0,0,-10);
            x1Config = dataCell.properties.intervalProperties(0,0,+10); 
            pxConfig = dataCell.properties.pxProperties();
            %
            sdoConfig = SAT.properties.computerProperties;
            % __ Init Listeners ___ 
            %{
            obj.ListenerObj_algo        = addlistener(sdoConfig, ...
                'algorithm', @(src, event)obj.syncConfig(src));
            %}
            obj.ListenerObj_algo        = addlistener(sdoConfig, ...
                'algorithm_configChanged', @(src, event)obj.syncConfig(src));
            obj.ListenerObj_bckSub      = addlistener(sdoConfig, ...
                'backgroundSubtraction_configChanged', @(src, event)obj.syncConfig(src));
            obj.ListenerObj_parComp     = addlistener(sdoConfig, ...
                'parallelCompute_configChanged', @(src, event)obj.syncConfig(src));
            obj.ListenerObj_lowMem      = addlistener(sdoConfig, ...
                'lowMemory_configChanged', @(src, event)obj.syncConfig(src));
            obj.ListenerObj_verbose      = addlistener(sdoConfig, ...
                'verbose_configChanged', @(src, event)obj.syncConfig(src));
            obj.ListenerObj_trialHandle  = addlistener(sdoConfig, ...
                'trialHandling_configChanged', @(src, event)obj.syncConfig(src));
            %--------------

            obj.sdoConfig = sdoConfig;
            %
            % // Slaves // 
            obj.stateMapping    = stateMap; 
            obj.unitSDO         = sdoMat(N_XT, N_PP,'unit', stateMap, ...
                x0Config, x1Config, pxConfig); 
            obj.shuffleSDO      = sdoMat(N_XT, N_PP,'shuffle', stateMap, ...
                x0Config, x1Config, pxConfig); 
            obj.backgroundSDO   = sdoMat(N_XT, N_PP,'background',stateMap, ...
                x0Config, x1Config, pxConfig); 
            % // add listener for dynamic updates to stateMap; 
            % __ Configs for Downstream __
            obj.x0Config = x0Config; 
            obj.x1Config = x1Config; 
            obj.pxConfig = pxConfig; 
            %
            obj.saveSnapshot(); 
        end
        function syncStateMaps(obj, src)
            obj.unitSDO.stateMapping = src; 
            obj.shuffSDO.stateMapping = src; 
            obj.backgroundSDO.stateMapping = src; 
        end
        function obj= saveSnapshot(obj)
            obj.configSnapshot.x0Config = obj.x0Config;
            obj.configSnapshot.x1Config = obj.x1Config;
            obj.configSnapshot.pxConfig = obj.pxConfig;
        end
        % -- Aliasing
        function LI = get.importedData(obj)
            LI = obj.unitSDO.importedXtData && obj.unitSDO.importedPpData;
        end
        %----
        function n = get.nPpChannels(obj)
            if ~obj.importedData
                n = 0; 
            else
                n = obj.unitSDO.nPpChannels; 
            end
        end
        %-----
        function n = get.nXtChannels(obj)
            if ~obj.importedData
                n = 0; 
            else
                n = obj.unitSDO.nXtChannels; 
            end
        end
        % --- 
        function n = get.nTrials(obj)
            if ~obj.importedData
                n = 0; 
            else
                n = obj.unitSDO.nTrials; 
            end
        end
        % ----
        function LI = get.computedBackgroundSdo(obj)
            LI = obj.backgroundSDO.computedSdo; 
        end
        % --- 
        function LI = get.computedShuffleSdo(obj)
            LI = obj.shuffleSDO.computedSdo; 
        end
        % -- 
        function LI = get.definedState(obj)
            LI = obj.unitSDO.definedState; 
        end
        %
        function n = get.nStates(obj)
            n = obj.stateMapping.nBins; 
        end
        % --> generate a compare method within lightweight class; query 
        %{
        function LI = get.changedProperties(obj)
            LI = false; 
            sf = fieldnames(obj.configSnapshot); 
            for f = 1:length(sf)
                if ~obj.(sf{f}).isChanged(obj.configSnapshot.(sf{f}))
                    LI = true;
                    break
                end
            end
        end
        %}
       %--------------------
%}
        %---------------
        %% GET / SET Components
        %---
        %{
        function algo = get.algorithm(obj)
            algo = obj.unitSDO.sdo(1,1).algorithm;
        end
        function set.algorithm(obj, algo)
            obj.unitSDO.sdo = deal2struct(obj.unitSDO.sdo, 'algorithm', algo); 
            obj.shuffleSDO.sdo = deal2struct(obj.shuffleSDO.sdo, 'algorithm', algo); 
            obj.backgroundSDO.sdo = deal2struct(obj.backgroundSDO.sdo, 'algorithm', algo); 
        end
        %---
        function LI = get.backgroundSubtraction(obj)
            LI = obj.unitSDO.sdo(1,1).backgroundSubtraction; 
        end
        function set.backgroundSubtraction(obj, LI)
            obj.unitSDO.sdo = deal2struct(obj.unitSDO.sdo, 'backgroundSubtraction', LI); 
            obj.shuffleSDO.sdo = deal2struct(obj.shuffleSDO.sdo, 'backgroundSubtraction', LI); 
            obj.backgroundSDO.sdo = deal2struct(obj.backgroundSDO.sdo, 'backgroundSubtraction', LI); 
        end
        %--- 
        function LI = get.parallelCompute(obj)
            LI = obj.unitSDO.sdo(1,1).parallelCompute;
        end
        function set.parallelCompute(obj, LI)
            obj.unitSDO.sdo = deal2struct(obj.unitSDO.sdo, 'parallelCompute', LI); 
            obj.shuffleSDO.sdo = deal2struct(obj.shuffleSDO.sdo, 'parallelCompute', LI);
            obj.backgroundSDO.sdo = deal2struct(obj.backgroundSDO.sdo, 'parallelCompute', LI); 
        end
        %---
        function LI = get.lowMemory(obj)
            LI = obj.unitSDO.sdo(1,1).lowMemory; 
        end
        function set.lowMemory(obj, LI)
            obj.unitSDO.sdo = deal2struct(obj.unitSDO.sdo, 'lowMemory', LI); 
            obj.shuffleSDO.sdo = deal2struct(obj.shuffleSDO.sdo, 'lowMemory', LI);
            obj.backgroundSDO.sdo = deal2struct(obj.backgroundSDO.sdo, 'lowMemory', LI);             
        end
        %---
        function n = get.nShuffles(obj)
            n = obj.shuffleSDO.sdo.nShuffles;
        end
        function set.nShuffles(obj, n)
            obj.unitSDO.sdo = deal2struct(obj.unitSDO.sdo, 'nShuffles', n);
            obj.shuffleSDO.sdo = deal2struct(obj.shuffleSDO.sdo, 'nShuffles', n);
            obj.backgroundSDO.sdo = deal2struct(obj.backgroundSDO.sdo, 'nShuffles', n);
        end
        %}
        %---
        % Unidirectional SET Components
        function set.nBackgroundPts(obj, n)
            obj.nBackgroundPts = n; 
            shuffle(obj, 'background')
        end
        %%
        % --------------------------
        function obj = discretize(obj)
            if ~obj.stateMapping.determinedMinMax
                obj.stateMapping.getChannelAmp( ...
                    obj.unitSDO.xtData); 
            end
            obj.buildStateMap(); 
        end
        %------------------------------
        function obj = import(obj, xtdc, ppdc, useXtChannels, usePpChannels)
            arguments
                obj
                xtdc    xtDataCell
                ppdc    ppDataCell
                useXtChannels = 1:xtdc.nChannels; 
                usePpChannels = 1:ppdc.nChannels; 
            end
            N_XT = length(useXtChannels); N_PP = length(usePpChannels);
            % __> Reconstruct here <__ 
            obj.unitSDO         = sdoMat(N_XT, N_PP,'unit'); 
            obj.shuffleSDO      = sdoMat(N_XT, N_PP,'shuffle'); 
            obj.backgroundSDO   = sdoMat(N_XT, N_PP,'background'); 
            %
            obj.unitSDO.import(xtdc, ppdc, useXtChannels, usePpChannels); 
            obj.shuffleSDO.import(xtdc, ppdc, useXtChannels, usePpChannels); 
            obj.backgroundSDO.import(xtdc, ppdc, useXtChannels, usePpChannels);
            %
            %
            obj.x0Config.fs = xtdc.data.fs;
            obj.x1Config.fs = xtdc.data.fs;
            % __ Init Relevant Structures __ 
            obj.init; %
        end
        %--------------------------
        function obj = init(obj)
            obj.shuffleSDO.eventShuffle.import(obj.shuffleSDO.ppData); 
            obj.backgroundSDO.eventShuffle.import(obj.backgroundSDO.ppData); %init/conform
                        tMax = min(obj.unitSDO.xtData.trTimeLen); 
            obj.backgroundSDO.eventShuffle.random( ...
                obj.nTrials, obj.nXtChannels, obj.nBackgroundPts, ...
                        'maxX', tMax, 'type', 'times'); 
            obj.shuffle; 
        end
        %-------------------------
        % // Callback function; 
        function obj = syncConfig(obj, ~)
            % __> I think we can just push them all commonly; 
            
            %A = strsplit(src, '_configChanged'); 
            sfields = [ ...
                "algorithm", ...
                "backgroundSubtraction", ...
                "parallelCompute", ...
                "obswise", ...
                "lowMemory", ...
                "verbose", ...
                "trialHandling"]; 
            for f = 1:length(sfields)
                obj.unitSDO.config.(sfields(f))      = obj.sdoConfig.(sfields(f));
                obj.shuffleSDO.config.(sfields(f))   = obj.sdoConfig.(sfields(f));
                obj.backgroundSDO.config.(sfields(f))= obj.sdoConfig.(sfields(f));
            end
        end
        %------------------------------
        function obj = compute(obj, TARGET)
            if ~exist('TARGET', 'var')
                TARGET = []; 
            end
            % // Assume we don't want to recalculate background & shuffles
            % -->> But we might want/need to if we change parameters... 
            
            syncConfig(obj); % force-push sdoCompute Properties; 
            
            OVERRIDE = 0; 
            %{
            if obj.changedProperties
                disp("Properties Changed. Recomputing All"); 
                OVERRIDE = 1; 
            end
            %}
            
            if (~obj.computedBackgroundSdo) || OVERRIDE || strcmp(TARGET, 'background');
                zArr = zeros(obj.nStates); 
                obj.backgroundSDO.sdo = deal2struct(obj.backgroundSDO.sdo, 'backgroundSdo', zArr);  
                %
                tic
                disp("Computing Background SDOs");
                obj.backgroundSDO.compute('useEvents', 'times'); 
                toc; 
            end
            
            % >> We will patch in the background SDOs here for subtraction

            for m = 1:obj.nXtChannels
                for u =1:obj.nPpChannels
                    obj.unitSDO.sdo(m,u).backgroundSdo = ...
                        obj.backgroundSDO.sdo(m,u).sdoMatrixNormed;
                    obj.shuffleSDO.sdo(m,u).backgroundSdo = ...
                        obj.backgroundSDO.sdo(m,u).sdoMatrixNormed;
                end
            end
            %
            if (~obj.computedShuffleSdo) || OVERRIDE || strcmp(TARGET, 'shuffle')
                tic;
                disp("Computing Shuffle SDOs"); 
                obj.shuffleSDO.compute('useEvents', 'shuffle'); 
                toc; 
            end
            if isempty(TARGET) || strcmp(TARGET, 'shuffle')
                disp("Computing Unit SDOs");
                tic;
                obj.unitSDO.compute(); 
                toc;
            end
        end
        %-----------------------------
        function obj = shuffle(obj, TARGET)
            arguments
                obj 
                TARGET = 'shuffle'; % {'background', 'shuffle'}; 
            end
            % // here we assume we only want to reshuffle 'shuffle'; 

            switch TARGET
                case 'background'
                    tMax = min(obj.unitSDO.xtData.trTimeLen); 
                    obj.backgroundSDO.eventShuffle.random( ...
                        obj.nTrials, obj.nXtChannels, obj.nBackgroundPts, ...
                                'maxX', tMax, 'type', 'times'); 
                case 'shuffle'
                    obj.shuffleSDO.eventShuffle.shuffle();                     
            end
        end
       %---------------------------- 
       function obj = performStats(obj, SIG_PVAL, Z_SCORE)
            arguments 
                obj
                SIG_PVAL    double = obj.sigPVal; 
                Z_SCORE     {mustBeNumericOrLogical} = obj.zScore;  
            end
            sMat = bungleSdoStruct(obj);
            sMat = SAT.compute.performStats(sMat); 
            % __ Test
            sMat = SAT.compute.testStatSig(sMat, SIG_PVAL, Z_SCORE);
            obj.stats   = sMat.stats{1};
            obj.sigPVal = SIG_PVAL; 
            obj.zScore  = Z_SCORE; 
        end
    end 
end
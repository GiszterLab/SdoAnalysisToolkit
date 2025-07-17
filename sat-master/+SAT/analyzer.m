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
        %predictionMatrices  SAT.predict.HH_predictionMatrices
        errorStruct         SAT.predict.predictionError2
        sdoStruct       = []; % dummy for deprecated
        nBackgroundPts        = 10000; % per-trial  
        nShuffles             = 1000; % One-way-push
        % ------------------------------
        handleTrials          = 'concat'; % DUMMY 
        %--------------------------
        % // Stats testing // 
        pValue                = 0.05; 
        zScore                = false; 
    end  
    properties (Hidden)
        configSnapshot
        stateMapListenerObj
        % // Listeners for pushing mode-specific changes //
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
        nStates
    end
    
    properties (Hidden, Dependent)
        importedData                    
        definedState
        shuffledSpikes 
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
            % // Master
            stateMap = dataCell.stateMap(); % Generate 1x; slave;
            x0Config = dataCell.properties.intervalProperties(0,0,-10);
            x1Config = dataCell.properties.intervalProperties(0,0,+10); 
            pxConfig = dataCell.properties.pxProperties();
            %
            sdoConfig = SAT.properties.computerProperties;
            % __ Init Listeners ___ 
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
            %obj.errorStruct = SAT.predict.predictionError2
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
        %
        function LI = get.shuffledSpikes(obj)
            LI = obj.shuffleSDO.eventShuffle.shuffledData;
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
        %
        function n = get.nShuffles(obj)
            n = obj.shuffleSDO.eventShuffle.nShuffles;
        end
        
        function set.nShuffles(obj, n)
            obj.nShuffles = n; 
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
            %
            N_XT = length(useXtChannels); N_PP = length(usePpChannels);
            % __ Expand computers __ 
            obj.unitSDO.sdo = repelem(SAT.sdoComputer('unit', ...
                obj.sdoConfig), N_XT, N_PP); 
            obj.shuffleSDO.sdo = repelem(SAT.sdoComputer('shuffle', ...
                obj.sdoConfig), N_XT, N_PP);            
            obj.backgroundSDO.sdo = repelem(SAT.sdoComputer('background', ...
                obj.sdoConfig), N_XT, N_PP); 
            %
            obj.stateMapping = xtdc.stateMap; 
            %
            obj.unitSDO.import(xtdc, ppdc, useXtChannels, usePpChannels); 
            obj.shuffleSDO.import(xtdc, ppdc, useXtChannels, usePpChannels); 
            obj.backgroundSDO.import(xtdc, ppdc, useXtChannels, usePpChannels);
            %
            obj.x0Config.fs = xtdc.data.fs;
            obj.x1Config.fs = xtdc.data.fs;
            % __ Init Relevant Structures __
            if ~obj.stateMapping.definedMinMax
                obj.stateMapping.getChannelAmp(xtdc.data); 
            end
            if ~obj.stateMapping.definedState
                %// need state def; 
                obj.stateMapping.buildStateMap(); 
            end           
            %
            obj.init; %
        end
        %--------------------------
        function obj = init(obj)
            %
            obj.shuffleSDO.eventShuffle.import(obj.shuffleSDO.ppData); 
            obj.backgroundSDO.eventShuffle.import(obj.backgroundSDO.ppData); %init/conform
                        tMax = min(obj.unitSDO.xtData.trTimeLen); 
            obj.backgroundSDO.eventShuffle.random( ...
                obj.nTrials, obj.nXtChannels, obj.nBackgroundPts, ...
                        'maxX', tMax, 'type', 'times'); 
           % obj.shuffle; 
        end
        %-------------------------
        
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
            % // conform shuffles;
            % psuedo-link
            obj.shuffleSDO.eventShuffle.nShuffles = obj.nShuffles;
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
            
            if (~obj.computedBackgroundSdo) || OVERRIDE || strcmp(TARGET, 'background')
                zArr = zeros(obj.nStates); 
                obj.backgroundSDO.sdo = deal2struct(obj.backgroundSDO.sdo, 'backgroundSdo', zArr);  
                %
                tic
                disp("Computing Background SDOs");
                obj.backgroundSDO.compute('useEvents', 'times'); 
                toc; 
            end
            % __ Deal background SDOs to sdoComputers___
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
                if ~obj.shuffledSpikes
                    obj.shuffle('shuffle'); 
                    1; 
                end
                FAST_SHUFF = 1;
                tic;
                if FAST_SHUFF == 1
                    disp("FAST SHUFFLE")
                    obj.shuffleSDO = SAT.sdoUtils.fastShuff(obj.shuffleSDO); 
                else
                    disp("Computing Shuffle SDOs"); 
                    obj.shuffleSDO.compute('useEvents', 'shuffle');
                end
                %}
                toc; 
            end
            if isempty(TARGET) || strcmp(TARGET, 'unit')
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
            disp(strcat("Shuffling ", TARGET));
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
        % -----------------
        % // call to sub-method
        
        function sdoStack = getSdos(obj, useXtChannels, usePpChannels, vars)
            arguments
                obj
                useXtChannels = 1:obj.nXtChannels;
                usePpChannels = 1:obj.nPpChannels;
                vars.norm = 0; 
                vars.target {mustBeMember(vars.target, {'unit', 'background', 'shuffle'})} = 'unit'; 
            end
            switch vars.target
                case 'unit'
                    sdoStack = obj.unitSDO.getSdos(useXtChannels, usePpChannels, vars.norm); 
                case 'background'
                    sdoStack = obj.backgroundSDO.getSdos(useXtChannels, usePpChannels, vars.norm);
                case 'shuffle'
                    sdoStack = obj.shuffleSDO.getSdos(useXtChannels, usePpChannels, vars.norm);
            end
        end
        
        % -------------
        function obj = getPredictionMatrices(obj, XT_CH_NO, PP_CH_NO, vars)
            arguments
                obj
                XT_CH_NO = 1; 
                PP_CH_NO = 1; 
                vars.type {mustBeMember(vars.type, {'M', 'L'})} = 'L'; 
                vars.staMethod {mustBeMember(vars.staMethod, {'dpx', 'px'})} = 'px'; 
                vars.backgroundSubraction = 0; % New
            end
            %----------
            % TODO: Better handling for trials
            %----------
            HH_predict = SAT.predict.HH_predictionMatrices(); 
            HH_predict.type = vars.type; 
            HH_predict.getPredictionMatrices( obj, XT_CH_NO, PP_CH_NO);
            
            obj.predictionMatrices = HH_predict;
        end
       %--------------------------
       function sdoS = getSdoStruct(obj)
           % // call to external bungler
           sdoS = SAT.deprecated.getSdoStructFunc(obj);
       end
       %---------------------------- 
       % // Legacy Struct // 
       function obj = performStats(obj, SIG_PVAL, Z_SCORE)
            arguments 
                obj
                SIG_PVAL    double = obj.pValue; %obj.sigPVal; 
                Z_SCORE     {mustBeNumericOrLogical} = obj.zScore;  
            end
            sMat = SAT.deprecated.getSdoStructFunc(obj);
            sMat = SAT.compute.performStats(sMat); 
            % __ Test __ 
            sMat = SAT.compute.testStatSig(sMat, SIG_PVAL, Z_SCORE);
            obj.sdoStruct = sMat; 
            obj.sigPVal = SIG_PVAL; 
            obj.zScore  = Z_SCORE; 
       end
       % 
       function pxData = getPxData(obj, USE_XT_CH, USE_PP_CH, target, element) 
           arguments
               obj
               USE_XT_CH = 1:obj.nXtChannels;
               USE_PP_CH = 1:obj.nPpChannels;
               target {mustBeMember(target, {'px0', 'px1'})} = 'px0'; 
               element {mustBeMember(element, {'unitSDO'})} = 'unitSDO';
           end
           switch target
               case 'px0'
                    pxData = obj.(element).px0Data.subsample( ...
                        USE_XT_CH, 1:obj.nTrials, USE_PP_CH);
               case 'px1'
                    pxData = obj.(element).px1Data.subsample( ...
                        USE_XT_CH, 1:obj.nTrials, USE_PP_CH);                  
           end
       end
       %
       function xData = getxData(obj, USE_XT_CH, USE_PP_CH, target, element)
           arguments
               obj
               USE_XT_CH
               USE_PP_CH
               target   {mustBeMember(target, {'x0', 'x1'})} = 'x0'; 
               element  {mustBeMember(element, {'unitSDO'})} = 'unitSDO';
           end
           switch target
               case 'x0'
                   xData = obj.(element).x0Data.subsample(...
                       USE_XT_CH, 1:obj.nTrials, USE_PP_CH);
               case 'x1'
                      xData = obj.(element).x1Data.subsample(...
                       USE_XT_CH, 1:obj.nTrials, USE_PP_CH);    
           end
       end
       %
       function obj = computePredictionError(obj, XT_CH_NO, PP_CH_NO)
           % // import x0/1 px0/1
           % Construct
           obj.errorStruct = SAT.predict.predictionError2(obj.pValue, obj.nShuffles);
           % Import; 
           obj.errorStruct.import(obj, XT_CH_NO, PP_CH_NO); 
           %
           obj.errorStruct.predictPxError(); 
           %
           obj.errorStruct = obj.errorStruct.computeError(); 
          
       end
    end 
end
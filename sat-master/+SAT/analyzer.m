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

% NOTE: {sdoMat}.stateMapping properties are bidirectionally lined to the
% analyzer.stateMapping properties; modifying one will modify the others.

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


classdef analyzer < handle & matlab.mixin.Copyable
    properties
        unitSDO         sdoMat2   % This is the master input data component; 
        shuffleSDO      sdoMat2
        backgroundSDO   sdoMat2
        %
        stateMapping    dataCell.stateMap % MASTER --> Slave downstream; 
        % __ These pass through __ 
        x0Config        dataCell.properties.intervalProperties 
        x1Config        dataCell.properties.intervalProperties 
        pxConfig        dataCell.properties.pxProperties
        %
        % Core Properties
        sdoConfig       SAT.properties.computerProperties
        predictionError SAT.predict.predictionError2
        % ------------------------------
        handleTrials          = 'concat'; % DUMMY 
        %--------------------------
        % // Stats testing // 
        sdoStruct               = []; % holder for deprecated struct; 
        sigMat                  = []; 
        nBackgroundPts          = 10000; % per-trial  
        % - SDO stats testing -
        nShuffles               = 1000; % One-way-push
        pValue                  = 0.05; 
        nSigValues   {mustBeInteger} = 1; 
        zScore                  = false; 
    end  
    properties (Hidden)
        configSnapshot
        stateMapListenerObj
        % // Listeners for pushing mode-specific changes //
        %{
        ListenerObj_algo
        ListenerObj_bckSub
        ListenerObj_parComp
        ListenerObj_lowMem
        ListenerObj_verbose
        ListenerObj_trialHandle
        %}
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
        computedUnitSdo
        computedSDOs
        changedProperties;
        %
        computedFullSDOStruct
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
            %{
            obj.ListenerObj_algo        = addlistener(sdoConfig, ...
                'algorithm_configChanged', @(src, event)obj.syncConfig(src));
            obj.ListenerObj_bckSub      = addlistener(sdoConfig, ...
                'backgroundSubtraction_configChanged', @(src, event)obj.syncConfig(src));
            obj.ListenerObj_parComp     = addlistener(sdoConfig, ...
                'parallelCompute_configChanged', @(src, event)obj.syncConfig(src));
            obj.ListenerObj_lowMem      = addlistener(sdoConfig, ...
                'lowMemory_configChanged', @(src, event)obj.syncConfig(src));
            obj.ListenerObj_verbose     = addlistener(sdoConfig, ...
                'verbose_configChanged', @(src, event)obj.syncConfig(src));
            obj.ListenerObj_trialHandle = addlistener(sdoConfig, ...
                'trialHandling_configChanged', @(src, event)obj.syncConfig(src));
            %}
            %--------------
            obj.sdoConfig = sdoConfig;
            % // Slaves // 
            obj.stateMapping    = stateMap; 
            obj.unitSDO         = sdoMat2.empty(); 
            obj.shuffleSDO      = sdoMat2.empty(); 
            obj.backgroundSDO   = sdoMat2.empty(); 
            obj.unitSDO         = sdoMat2(N_XT, N_PP,'unit', stateMap, ...
                x0Config, x1Config, pxConfig); 
            obj.shuffleSDO      = sdoMat2(N_XT, N_PP,'shuffle', stateMap, ...
                x0Config, x1Config, pxConfig); 
            obj.backgroundSDO   = sdoMat2(N_XT, N_PP,'background',stateMap, ...
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
            obj.configSnapshot.sdoConfig= obj.sdoConfig;
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
        function LI = get.computedUnitSdo(obj)
            LI = obj.unitSDO.computedSdo; 
        end
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
        %
        function LI = get.computedSDOs(obj)
            LI = all(obj.computedUnitSdo, obj.computedBackgroundSdo, obj.computedShuffleSdo);
        end
        %
        function LI = get.changedProperties(obj)
            LI = false; 
            sf = fieldnames(obj.configSnapshot); 
            for f = 1:length(sf)
                if ~isequal(obj.(sf{f}), obj.configSnapshot.(sf{f}))
                    LI = true; 
                end
            end
        end
        %
        function LI = get.computedFullSDOStruct(obj)
            if ~isstruct(obj.sdoStruct); LI = 0; return; end
            LI = ~any(cellfun(@isempty, {obj.sdoStruct(:).sdosJoint})); 
            if LI == 0; return; end
            for m = 1:obj.nXtChannels
                for u = 1:obj.nPpChannels
                    if isempty(obj.sdoStruct(m).sdosJoint{u}); LI = 0; return;end
                end
            end
        end
       
       %--------------------
        % Unidirectional SET Components
        function set.nBackgroundPts(obj, n)
            obj.nBackgroundPts = n; 
            shuffle(obj, 'background')
        end
        %%
        % --------------------------
        function obj = discretize(obj)
            if ~obj.stateMapping.determinedMinMax
                obj.stateMapping.getChannelAmp(obj.unitSDO.xtData); 
            end
            obj.buildStateMap(); 
        end
        %------------------------------
        function obj = import(obj, xtdc, ppdc, useXtChannels, usePpChannels)
            arguments
                obj
                xtdc  {mustBeA(xtdc, {'xtDataCell', 'xtDataCell2'})}
                ppdc  {mustBeA(ppdc, {'ppDataCell', 'ppDataCell2'})}
                useXtChannels = 1:xtdc.nChannels; 
                usePpChannels = 1:ppdc.nChannels; 
            end
            %
            if obj.importedData
                disp("Data already imported"); return;
            end
            
            if isa(xtdc, 'xtDataCell') 
                xtdc = xtdc.getVersion(2); 
            end
            if isa(ppdc, 'ppDatacell') 
                ppdc = ppdc.getVersion(2); 
            end
            
            N_XT = length(useXtChannels); N_PP = length(usePpChannels);
            % __ Expand computers __ 
            % // We have to modify this to avoid pointing to the same handl
            %
            unit_proto = obj.unitSDO.sdo; 
            shff_proto = obj.shuffleSDO.sdo; 
            bkgd_proto = obj.backgroundSDO.sdo; 
            
            if (obj.nXtChannels < N_XT) && (obj.nPpChannels < N_PP)
                % -- force recopy
                for m = 1:N_XT
                    for u = 1:N_PP
                        obj.unitSDO.sdo(m,u)        = copy(unit_proto); 
                        obj.shuffleSDO.sdo(m,u)     = copy(shff_proto); 
                        obj.backgroundSDO.sdo(m,u)  = copy(bkgd_proto); 
                    end
                end
                
            end
            %}
            %
            obj.stateMapping = xtdc.stateMap; 
            %
            obj.unitSDO.import      (xtdc, ppdc, useXtChannels, usePpChannels); 
            obj.shuffleSDO.import   (xtdc, ppdc, useXtChannels, usePpChannels); 
            obj.backgroundSDO.import(xtdc, ppdc, useXtChannels, usePpChannels);
            %
            obj.x0Config.fs = xtdc.data.fs;
            obj.x1Config.fs = xtdc.data.fs;
            % __ Init Relevant Structures __
            if ~obj.stateMapping.definedMinMax
                obj.stateMapping.getChannelAmp(xtdc.data); 
            end
            if ~obj.stateMapping.definedState
                obj.stateMapping.buildStateMap(); 
            end           
            %
            obj.init; %
        end
        %--------------------------
        function obj = init(obj)
            %
            obj.shuffleSDO.eventShuffle.import(obj.shuffleSDO.ppData);  %init/conform
            tMax = min(obj.unitSDO.xtData.trTimeLen); 
            %
            obj.backgroundSDO.eventShuffle.random( ...
                obj.nTrials, 1, obj.nBackgroundPts, ...
                'maxX', tMax, 'type', 'times', 'link', 'channels');    
            %
            obj.backgroundSDO.ppData = obj.backgroundSDO.eventShuffle.getPpData; 
        end
        %-------------------------
        function obj = syncConfig(obj, ~)
            % __> I think we can just push them all commonly; 
            sfields = fieldnames(obj.sdoConfig); 
            sfields = setdiff(sfields, 'obswise'); % shuff overrides this;
            for f = 1:length(sfields)
                obj.unitSDO.config.(sfields{f})      = obj.sdoConfig.(sfields{f});
                obj.shuffleSDO.config.(sfields{f})   = obj.sdoConfig.(sfields{f});
                obj.backgroundSDO.config.(sfields{f})= obj.sdoConfig.(sfields{f});
            end
            % // conform shuffles;
            % pseudo-link
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
            
            if obj.changedProperties
                disp("Properties Changed. Recomputing All"); 
                OVERRIDE = 1; 
            end
            % ---- Background ---- %
            if (~obj.computedBackgroundSdo && isempty(TARGET)) || OVERRIDE || strcmp(TARGET, 'background')
                zArr = zeros(obj.nStates); 
                obj.backgroundSDO.sdo = deal2struct(obj.backgroundSDO.sdo, 'backgroundSdo', zArr);  
                tic
                disp("Computing Background SDOs");
                obj.backgroundSDO.compute('useEvents', 'shuffle'); 
                % --> posthoc copy for utility; 
                for u = 2:obj.nPpChannels
                   obj.backgroundSDO.sdo(:,u) = obj.backgroundSDO.sdo(:,1);
                end
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
            % ---- Shuffle ---- %
            if (~obj.computedShuffleSdo && isempty(TARGET)) || OVERRIDE || strcmp(TARGET, 'shuffle')
                if ~obj.shuffledSpikes; obj.shuffle('shuffle'); end
                FAST_SHUFF = 1;
                
                if FAST_SHUFF == 1
                    disp("FAST SHUFFLE")
                    obj.shuffleSDO = SAT.sdoUtils.fastShuff(obj); 
                    %obj.shuffleSDO = SAT.sdoUtils.fastShuff(obj.shuffleSDO); 
                else
                    tic;
                    disp("Computing Shuffle SDOs"); 
                    obj.shuffleSDO.compute('useEvents', 'shuffle');
                    toc; 
                end
            end
            % ----- Unit ---- %
            if (isempty(TARGET) || strcmp(TARGET, 'unit')) 
                disp("Computing Unit SDOs");
                tic;
                obj.unitSDO.compute(); 
                toc;
            end
            obj.saveSnapshot(); 
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
            FFIELD = strcat(vars.target,'SDO'); 
            sdoStack = obj.(FFIELD).getSdos(useXtChannels, usePpChannels, vars.norm); 
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
       function obj = makeSdoStruct(obj,USE_XT_CH, USE_PP_CH)
           if ~exist('USE_XT_CH', 'var'); USE_XT_CH = []; end
           if ~exist('USE_PP_CH', 'var'); USE_PP_CH = []; end
           if isempty(USE_XT_CH);USE_XT_CH = 1:obj.nXtChannels; end
           if isempty(USE_PP_CH);USE_PP_CH = 1:obj.nPpChannels; end
           sdoS = SAT.deprecated.getSdoStructFunc(obj, USE_XT_CH, USE_PP_CH);
           obj.sdoStruct = sdoS; 
       end
       function sdoS = getSdoStruct(obj,USE_XT_CH, USE_PP_CH)
           if ~exist('USE_XT_CH', 'var'); USE_XT_CH = []; end
           if ~exist('USE_PP_CH', 'var'); USE_PP_CH = []; end
           if isempty(USE_XT_CH);USE_XT_CH = 1:obj.nXtChannels; end
           if isempty(USE_PP_CH);USE_PP_CH = 1:obj.nPpChannels; end
           if obj.computedFullSDOStruct
               sdoS = obj.sdoStruct;
           else
               sdoS = SAT.deprecated.getSdoStructFunc(obj, USE_XT_CH, USE_PP_CH);
           end
       end
       %--------------------------
       function plot(obj, XT_CH_NO, PP_CH_NO, INCLUDE_STATS)
           arguments
               obj
               XT_CH_NO = 1; 
               PP_CH_NO = 1; 
               INCLUDE_STATS = 1;
           end
           
           obj.sdoStruct = obj.getSdoStruct(XT_CH_NO, PP_CH_NO); 
           obj.sdoStruct = SAT.compute.performStats(obj.sdoStruct, XT_CH_NO, PP_CH_NO);
           
           % TODO: Implement a plot CONFIG element, we can
           % pass/autopopulate
           
           SAT.plot.plotHeader(obj, ...
                XT_CH_NO, PP_CH_NO, ...
                'filter', 0, ...
                'saveFig', 0, ...
                'outputDirectory', []); 
           
           obj.unitSDO.plotStirpd([], XT_CH_NO, PP_CH_NO)
                     
           if INCLUDE_STATS
               obj.computePredictionError(XT_CH_NO, PP_CH_NO); 
               obj.predictionError.plot(); 
           end
       end
       
       %---------------------------- 
       % // Legacy Struct // 
       function obj = performStats(obj, SIG_PVAL, Z_SCORE)
            arguments 
                obj
                SIG_PVAL    double = obj.pValue; %obj.sigPVal; 
                Z_SCORE     {mustBeNumericOrLogical} = obj.zScore;  
            end
            disp("Computing Stats...")
            tic;
            sMat = SAT.deprecated.getSdoStructFunc(obj);
            sMat = SAT.compute.performStats(sMat); 
            % __ Test __ 
            sMat = SAT.compute.testStatSig(sMat, SIG_PVAL, Z_SCORE);
            obj.sdoStruct   = sMat; 
            obj.pValue      = SIG_PVAL; 
            obj.zScore      = Z_SCORE; 
            toc;
       end
       % 
       function data = getData(obj, USE_XT_CH, USE_PP_CH, target, element) 
           arguments
               obj
               USE_XT_CH = 1:obj.nXtChannels;
               USE_PP_CH = 1:obj.nPpChannels;
               target   {mustBeMember(target, {'x0Data', 'x1Data','px0Data', 'px1Data'})} = 'x0Data'; 
               element  {mustBeMember(element, {'unitSDO'})} = 'unitSDO';
           end
           data = obj.(element).(target).subsample(USE_XT_CH, 1:obj.nTrials, USE_PP_CH);
       end
       %
       function obj = computePredictionError(obj, XT_CH_NO, PP_CH_NO)
           % // import x0/1 px0/1
           % Construct
           obj.predictionError = SAT.predict.predictionError2(obj.pValue, obj.nShuffles);
           % Import; 
           obj.predictionError.import(obj, XT_CH_NO, PP_CH_NO); 
           obj.predictionError.predictPxError(); 
           obj.predictionError = obj.predictionError.computeError(); 
       end
       % ---- 
       function obj = findSigSdos(obj, SIG_THRESH)
            arguments
                obj
                SIG_THRESH {mustBeInteger} = obj.nSigValues; 
            end
            if ~obj.computedFullSDOStruct
                disp("SDO Structures have not been generated. Please use the 'compute' method first"); 
                return
            end
            obj.sigMat = SAT.sdoUtils.findSigSdos(obj.sdoStruct, SIG_THRESH);
        end
       
    end 
end
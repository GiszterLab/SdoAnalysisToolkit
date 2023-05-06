%% SDO Matrix
% OOP-based data holder for SDO methods
% -- Wrapper for existing methods 
%
% 1) sdoMat may be generated from 2 'pxtDataCell' classes
% 2) sdoMat may be generated fom the 'sdo' common data structure
% 3) sdoMat may be extracted from an 'sdoMultiMat' Class

% TODO: Further optimization, parameter reduction

% Trevor S. Smith, 2023
% Drexel University College of Medicine

classdef sdoMat < handle & matlab.mixin.Copyable & dataCellSuperClass
    properties (Access = public)
        xtName          char = []; 
        ppName          char = [];
        xtChName        char = [];
        ppChName        char = []; 
        % ___ 
        pxtNames        = {}; %
        nPxtTypes       {mustBeInteger} = 0; 
        nStates         {mustBeInteger} = 20; 
        nEvents         {mustBeInteger} = 0; 
        fs              {mustBeNumeric} = 0; 
        % __ Meta data
        xtProperties    = []; 
        ppProperties    = []; 
        pxProperties    = []; 
        % __ Derived params
        stateMapping    = zeros(1,21)
        px0_duraMs      {mustBeNumeric} = 0; 
        px1_duraMs      {mustBeNumeric} = 0; 
        %__
        nShuffles       {mustBeInteger} = 1000; 
        sigPVal         double = 0.05; 
        zScore          = false; 
        % __ data matrices
        sdo             = zeros(20); 
        sdoJoint        = zeros(20); 
        sdoBkgrnd       = zeros(20); 
        sdoBkgrndJoint  = zeros(20);
        shuffles        = {}; 
        stats           = {}; 
        markovMatrix    = zeros(20); 
        % __ Transition matrices
        transitionMat       = {}; 
        transitionMatType   (1,:) char {mustBeMember(transitionMatType,{'M','L'})} = 'M';
        markovType          (1,3) char {mustBeMember(markovType,{'px0','px1'})} = 'px0'; 
    end
    properties (Access = protected)
        generatedTransitionMatrices = false; 
        generatedExactBackground = false;  
    end
    methods
        %% Import (from 'sdoStruct')
        function obj = import(obj, elem, VAR_1, VAR_2)
           %// Future-proofing method; 
           if isstruct(elem)
               obj = obj.importSdoStruct(obj, elem, VAR_1, VAR_2); 
           end
           if isa(elem, 'pxtDataCell')
               obj = obj.computeSdo(elem, VAR_1); 
           end
        end
        
        % __ Import from mass/multicompare struct 
        function obj = importSdoStruct(obj, sdoStruct, XT_CH_NO, PP_CH_NO)
            arguments
                obj
                sdoStruct
                XT_CH_NO {mustBeInteger} = 1; 
                PP_CH_NO {mustBeInteger} = 1;
            end
            %// import from standard sdo multicompare Struct; 
            obj.xtChName        = sdoStruct(XT_CH_NO).signalType; 
            obj.ppChName        = sdoStruct(XT_CH_NO).neuronNames{PP_CH_NO};
            obj.pxtNames        = {'sdo'}; 
            obj.nPxtTypes       = 1; 
            %obj.nEvents         = 0; 
            obj.xtProperties    = sdoStruct(XT_CH_NO).params.xt; 
            obj.ppProperties    = sdoStruct(XT_CH_NO).params.pp; 
            obj.pxProperties    = sdoStruct(XT_CH_NO).params.px;
            obj.stateMapping       = sdoStruct(XT_CH_NO).levels; 
            obj.nStates         = length(sdoStruct(XT_CH_NO).levels) - 1; 
            obj.px0_duraMs      = sdoStruct(XT_CH_NO).params.px.px0DurationMs; 
            obj.px1_duraMs      = sdoStruct(XT_CH_NO).params.px.px1DurationMs; 
            obj.nShuffles       = size(sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff, 3); 
            obj.sdo             = sdoStruct(XT_CH_NO).sdos{PP_CH_NO}; 
            obj.sdoJoint        = sdoStruct(XT_CH_NO).sdosJoint{PP_CH_NO}; 
            obj.sdoBkgrnd       = sdoStruct(XT_CH_NO).bkgrndSDO; 
            obj.sdoBkgrndJoint  = sdoStruct(XT_CH_NO).bkgrndJointSDO; 
            obj.shuffles        = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}; 
            obj.stats           = sdoStruct(XT_CH_NO).stats{PP_CH_NO}; 
            %__
            obj.generatedExactBackground = true;  
        end
        
        function obj = computeSdo(obj, pxt_0, pxt_1)
            arguments
                obj
                pxt_0 pxtDataCell
                pxt_1 pxtDataCell
            end
            %// one-off generation from pxtDataCell classes (All necessary
            %params are upstream)
            if isa(pxt_0.data, 'cell')
                ISCELL = 1; 
            else
                ISCELL = 0; 
            end
            N_SHUFF  = pxt_0.nShuffles; 
            N_STATES = pxt_0.nStates;  
            
            if ISCELL
                px1_data    = pxt_1.data{1}; 
                px0_data    = pxt_0.data{1}; 
            else
                px1_data = pxt_1.data; 
                px0_data = pxt_0.data; 
            end
            jArr    = (px1_data*px0_data'); 
            dArr    = jArr - diag(sum(px0_data,2));
            
            px1_shuff   = pxt_1.shuffData; 
            px0_shuff   = pxt_0.shuffData; 
            sdoSS       = zeros(N_STATES,N_STATES,N_SHUFF); 
            sdoJointSS  = zeros(N_STATES,N_STATES,N_SHUFF); 
            for ss = 1:N_SHUFF
               ssPx = px1_shuff(:,:,ss)*px0_shuff(:,:,ss)';
               sdoJointSS(:,:,ss)   =  ssPx; 
               sdoSS(:,:,ss)        =  ssPx - diag(sum(px0_shuff(:,:,ss),2)); 
            end 
            %
            %___ %// Quadruple-Mean Transition => ~ Average Background
            bckMkv      = (pxt_0.backgroundMkv + pxt_1.backgroundMkv).^1/2;
            bckJoint    = diag(pxt_0.backgroundPx)*bckMkv; 
            bckSDO      = bckJoint - diag(pxt_0.backgroundPx); 
            % __ WRITEOUT
            obj = copyProperties(obj, pxt_0, {'fs', 'xtName', 'ppName', ...
                'xtChName', 'ppChName','nEvents', 'xtProperties', ...
                'ppProperties', 'stateMapping'}); 
            
            obj.pxtNames        = {pxt_0.pxtNames, pxt_1.pxtNames}; 
            obj.px1_duraMs      = abs(pxt_1.duraMs); 
            obj.px0_duraMs      = abs(pxt_0.duraMs);
            obj.sdo             = dArr/obj.nEvents; 
            obj.sdoJoint        = jArr/obj.nEvents; 
            obj.sdoBkgrnd       = bckSDO; 
            obj.sdoBkgrndJoint  = bckJoint; 
            %___
            obj.shuffles.SDOShuff       = sdoSS/obj.nEvents; 
            obj.shuffles.SDOJointShuff  = sdoJointSS/obj.nEvents; 
            % ___ Append Params as expected; 
            obj.pxProperties.smoothingFilterWidth   = pxt_0.filterWid; 
            obj.pxProperties.smoothingFilterStd     = pxt_0.filterStd; 
            netDelay = (pxt_1.zDelay-pxt_0.zDelay)+1; %temp
            obj.pxProperties.zDelay = netDelay; 
            switch obj.markovType
                case 'px0'
                    obj.markovMatrix = pxt_0.markovMatrix; 
                case 'px1'
                    obj.markovMatrix = pxt_1.markovMatrix; 
            end
            
        end
        % ++ Method to replace the estimated background SDO ++ 
        function obj = computeBackgroundSdo(obj, xtdc)
            arguments
                obj
                xtdc xtDataCell
            end
            %// We can directly extract statemapping from xtdc
            XT_CH_NO = find(strcmp(obj.xtChName, xtdc.electrode)); 
            xData = getTensor(xtdc, XT_CH_NO, 'DATAFIELD', 'stateSignal', 'CONFORM_METHOD', 'trim');
            flatMat = reshape(squeeze(xData), 1, []); 
            SAM_PER_MS = obj.fs/1000; 

            [px0, px1] = pxTools.getPxtFromXt(flatMat, 'all', 1:obj.nStates+1, ...
                'navg', round([obj.px0_duraMs, obj.px1_duraMs] * SAM_PER_MS), ...
                'smoothwid', obj.pxProperties.smoothingFilterWidth, ...
                'smoothstd', obj.pxProperties.smoothingFilterStd, ... 
                'z_delay',   obj.pxProperties.zDelay); 
            N_PTS = size(px0,2); 
            obj.sdoBkgrndJoint  = (px1*px0')/N_PTS; 
            obj.sdoBkgrnd       = ((px1*px0') - diag(sum(px0,2)))/N_PTS; 
            %
            obj.generatedExactBackground = true;  
        end
        %// Class-Wrapped method for Stat testing/ analysis; 
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
            obj.stats = sMat.stats{1};
            obj.sigPVal = SIG_PVAL; 
            obj.zScore = Z_SCORE; 
        end
        %}
        %% Operate
        
        % ___ Generate normalized Hypothesized Matrices from observed dat; 
        function obj = makeTransitionMatrices(obj, ALL_MAT)
            arguments
                obj 
                ALL_MAT {mustBeNumericOrLogical} = 1; 
            end

            %// This one requires the definition of the STA as mean of px
            MATTYPE = obj.transitionMatType; 
            
            nmCell = {'t0t1', 'gauss', 'STA', 'bck', 'mkv', 'staBck', 'SDO'};
            PX_FSM_WID = obj.pxProperties.smoothingFilterWidth; 
            PX_FSM_STD = obj.pxProperties.smoothingFilterStd; 
            
            if ~obj.generatedExactBackground 
                disp("Using Estimated (non-exact) Background"); 
            end
            % __ 7 hypotheses
            N_MAT = length(nmCell); 
            matCell = cell(1, N_MAT); 
            staPx   = sum(obj.sdoJoint,2);
            
            % _________ Ripped from gen script; 
            % [H1] __ t0t1 
            matCell{1} = pxTools.getH0Array(obj.nStates, 0,0, MATTYPE);
            % [H2] __ gauss 
            matCell{2} = pxTools.getH0Array(obj.nStates, max(1, PX_FSM_WID), max(1, PX_FSM_STD), MATTYPE); 
            % [H3] __ STA (simple)
            matCell{3} = staPx* ones(1,obj.nStates); 
            % [H4] __ bck
            [~, bk_NjSDO]    = SAT.sdoUtils.normsdo(obj.sdoBkgrnd, obj.sdoBkgrndJoint, 'px0'); 
            matCell{4} = bk_NjSDO; 
            % [H5] __ Mkv
            try
                matCell{5} = obj.markovMatrix^round(obj.fs*obj.px1_duraMs/1000); 
            catch
                matCell{5} = zeros(obj.nStates); 
            end
            % [H6] __ sta+Bckgrnd
            matCell{6} = bk_NjSDO*SAT.sdoUtils.stashiftmat(obj.sdoJoint, staPx); 
            % [H7] __ SDO
            matCell{7} = SAT.sdoUtils.normsdo(obj.sdo, obj.sdoJoint); 
            if ALL_MAT
                obj.transitionMat = matCell; 
               % _____
               obj.pxtNames     = nmCell; 
               obj.nPxtTypes    = N_MAT;
            else
                obj.transitionMat   = matCell{end}; 
                obj.pxtNames        = nmCell{end}; 
                obj.nPxtTypes       = 1;
            end
           obj.generatedTransitionMatrices = true; 
        end
        
        %% Bungle
        function sMat = bungleSdoStruct(obj)
           %// temporary method to 'reconstruct' a miniSDO array for the
           %common plotter method; 
           sMat = struct( ...
               'signalType',        obj.xtChName, ...
               'neuronNames',       {{obj.ppChName}}, ... 
               'levels',            obj.stateMapping, ...  
               'sdosJoint',         {{obj.sdoJoint}}, ... 
               'sdos',              {{obj.sdo}}, ... 
               'bkgrndJointSDO',    obj.sdoBkgrndJoint, ... 
               'bkgrndSDO',         obj.sdoBkgrnd , ... 
               'shuffles',          {{obj.shuffles}}, ... 
               'stats',             {{obj.stats}}); 
        end
        
        %% Plot (Overload)
        function plot(obj, options)
            arguments
                obj
                options.saveFig         {mustBeNumericOrLogical} = 0; 
                options.saveFormat      {mustBeMember(options.saveFormat, {'png', 'svg'})} = 'png'; 
                options.outputDirectory = []; 
            end
            % MASTER 'plot all' method; 
            % ____
            if isempty(obj.stats)
                performStats(obj);  
            end
            sMat = bungleSdoStruct(obj); 
            SAT.plotSDO(sMat, 1,1, ...
                'saveFig', options.saveFig, ...
                'saveFormat', options.saveFormat, ...
                'outputDirectory', options.outputDirectory); 
        end
        
        %% Export to pxtDataCell
        %// use transition matrices of SDO to predict pxt1 from an
        %input pxtDataCell
        function pxt_est = getPredictionPxt(obj, px0, duraMs)
            arguments
                obj
                px0 pxtDataCell
                duraMs double = 0; 
            end
            
            if ~obj.generatedTransitionMatrices
                disp("Transition Matrices have not Generated yet!"); 
                return
            end

            %TODO: Check for mismatch in filters/etc. 
            
            pxt_est = pxtDataCell(); 
            pxt_est.data        = cell(1, obj.nPxtTypes); 
            pxt_est.pxtNames    = cell(1, obj.nPxtTypes);  
            if isa(px0.data, 'cell')
                ISCELL = 1; 
            else
                ISCELL = 0; 
            end
            
            for hh = 1:obj.nPxtTypes
                if ISCELL
                    pxData = px0.data{1}; 
                else
                    pxData = px0.data; 
                end
               pdPx = pxTools.predictPxtfromPx0(obj.transitionMat{hh}, pxData); 
               pxt_est.data{hh} = pdPx;  
               pxt_est.pxtNames{hh} = obj.pxtNames{hh}; 
            end
            %______ BACK COPY_________
            pxt_est.copyProperties(obj, {'xtName', 'ppName', 'xtChName', ...
                'ppChName', 'nPxtTypes', 'nEvents', 'xtProperties', ...
                'ppProperties', 'nStates', 'markovMatrix', 'stateMapping'}); 
    
            %__ Be Cautious !!
            %pxt_est.markovMatrix    = obj.markovMatrix; %// this isn't exactly the same. Px of prediction  
            % __ Unique/ Differing Calls
            pxt_est.duraMs          = obj.px1_duraMs; 
            %pxt_est.stateMapping    = obj.stateMapping; 
            pxt_est.zDelay          = obj.pxProperties.zDelay; 
            pxt_est.filterWid       = obj.pxProperties.smoothingFilterWidth; 
            pxt_est.filterStd       = obj.pxProperties.smoothingFilterStd; 
            
           % // export to a pxt;  
            
        end
        
    end
end
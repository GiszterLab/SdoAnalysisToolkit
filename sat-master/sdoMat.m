%% SDO Matrix
% Data Class for dealing with the SDO matrices. For use with the SDO
% Analysis Toolkit. 
%
% 1) sdoMat may be generated from 2 'pxtDataCell' classes
% 2) sdoMat may be generated fom the 'sdo' common data structure
% 3) sdoMat may be extracted from an 'sdoMultiMat' Class

% TODO: Further optimization, parameter reduction. 
%
% NOTE: This class is becoming somewhat obsolete due to the extra refinements
% and optimization of the 'sdoMultiMat' class. Recommended to use the
% 'sdoMultiMat' class


%_______________________________________
% Copyright (C) 2023 Trevor S. Smith
% Drexel University College of Medicine
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
%__________________________________________

classdef sdoMat < handle & matlab.mixin.Copyable & dataCellSuperClass & dataCell.dependencies.primaryData
    
    %inherited properties; 
        % fs; 
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
        %fs              {mustBeNumeric} = 0; 
        % __ Meta data
        xtProperties    = []; 
        ppProperties    = []; 
        pxProperties    = []; 
        params          = []; %dummy; 
        % __ Derived params
        stateMapping    = zeros(1,21)
        px0DuraMs      {mustBeNumeric} = 0; 
        px1DuraMs      {mustBeNumeric} = 0; 
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
        %
        stirpd          = zeros(20, 40); %N_STATES x [N_T0 + N_T1 points]
        % __ Transition matrices
        transitionMat       = {}; 
        transitionMatType   (1,:) char {mustBeMember(transitionMatType,{'M','L'})} = 'L';
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
            obj.stateMapping    = sdoStruct(XT_CH_NO).levels; 
            obj.nStates         = length(sdoStruct(XT_CH_NO).levels) - 1; 
            obj.px0DuraMs      = sdoStruct(XT_CH_NO).params.px.px0DurationMs; 
            obj.px1DuraMs      = sdoStruct(XT_CH_NO).params.px.px1DurationMs; 
            obj.nShuffles       = size(sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff, 3); 
            obj.sdo             = sdoStruct(XT_CH_NO).sdos{PP_CH_NO}; 
            obj.sdoJoint        = sdoStruct(XT_CH_NO).sdosJoint{PP_CH_NO}; 
            obj.sdoBkgrnd       = sdoStruct(XT_CH_NO).bkgrndSDO; 
            obj.sdoBkgrndJoint  = sdoStruct(XT_CH_NO).bkgrndJointSDO; 
            obj.shuffles        = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}; 
            obj.stats           = sdoStruct(XT_CH_NO).stats{PP_CH_NO}; 
            obj.markovMatrix    = eye(obj.nStates); %This is just a DUMMY!
            try
                %// For depreciated
                obj.params      = sdoStruct(XT_CH_NO).params; 
            end
            try
                obj.stirpd      = sdoStruct(XT_CH_NO).stirpd{PP_CH_NO}; 
                obj.nEvents     = sdoStruct(XT_CH_NO).stats{PP_CH_NO}.nEvents; 
            end

            %__
            obj.generatedExactBackground = true;  
        end
        
        function obj = computeSdo(obj, pxt_0, pxt_1, vars)
            % Direct computation of the SDO; 
            arguments
                obj
                pxt_0 pxtDataCell
                pxt_1 pxtDataCell
                vars.method {mustBeMember(vars.method, {'original', 'asymmetric', 'optimized'})} = 'original'; %'asymmetric'; 
            end
            %// one-off generation from pxtDataCell classes (All necessary
            %params are upstream)
            if pxt_0.nPxtTypes > 1
                MULTICOMP = 1; 
                px1_data    = pxt_1.data{1}; 
                px0_data    = pxt_0.data{1};
            else
                MULTICOMP = 0; 
                px1_data = pxt_1.data; 
                px0_data = pxt_0.data; 
            end
            N_SHUFF  = pxt_0.nShuffles; 
            N_STATES = pxt_0.nStates;  
            
            %% ___ P(x,t0 - P(x,t1) SDO Calculations

            switch vars.method
                case 'original'
                    [dArr, jArr]        = SAT.compute.sdo3(px0_data, px1_data); 
                    [sdoSS, sdoJointSS] = SAT.compute.sdo3(pxt_0.shuffData, pxt_1.shuffData); 
                case 'asymmetric'
                    [dArr, jArr]        = SAT.compute.sdo5(px0_data, px1_data); 
                    [sdoSS, sdoJointSS] = SAT.compute.sdo5(pxt_0.shuffData, pxt_1.shuffData); 
                case 'optimized'
                    [dArr, jArr]        = SAT.compute.sdo7(px0_data, px1_data); 
                    [sdoSS, sdoJointSS] = SAT.compute.sdo7(pxt_0.shuffData, pxt_1.shuffData); 
            end


            %___ %// Quadruple-Mean Transition => ~ Average Background
            bckMkv      = (pxt_0.backgroundMkv + pxt_1.backgroundMkv).^1/2;
            bckJoint    = diag(pxt_0.backgroundPx)*bckMkv; 
            bckSDO      = bckJoint - diag(pxt_0.backgroundPx); 
            
            % __ WRITEOUT
            obj = copyProperties(obj, pxt_0, {'fs', 'xtName', 'ppName', ...
                'xtChName', 'ppChName','nEvents', 'xtProperties', ...
                'ppProperties', 'stateMapping'}); 
            %% Write out; 
            obj.pxtNames        = {pxt_0.pxtNames, pxt_1.pxtNames}; 
            obj.px1DuraMs       = abs(pxt_1.duraMs); 
            obj.px0DuraMs       = abs(pxt_0.duraMs);
            obj.nStates         = N_STATES; 
            obj.sdo             = dArr; 
            obj.sdoJoint        = jArr; 
            obj.sdoBkgrnd       = bckSDO; 
            obj.sdoBkgrndJoint  = bckJoint; 
            %___
            obj.shuffles.SDOShuff       = sdoSS; 
            obj.shuffles.SDOJointShuff  = sdoJointSS; 
            % ___ (TEMPORARY) Append Params as expected (Somewhat redundant) 
            obj.pxProperties.smoothingFilterWidth   = pxt_0.filterWid; 
            obj.pxProperties.smoothingFilterStd     = pxt_0.filterStd; 
            netDelay = (pxt_1.zDelay-pxt_0.zDelay)+1; %temp
            obj.pxProperties.zDelay = netDelay; 
            obj.pxProperties.nShift = 0; %TODO: Correct this
            obj.pxProperties.px0DurationMs = obj.px0DuraMs; 
            obj.pxProperties.px1DurationMs = obj.px1DuraMs; 

            switch obj.markovType
                case 'px0'
                    obj.markovMatrix = pxt_0.markovMatrix; 
                case 'px1'
                    obj.markovMatrix = pxt_1.markovMatrix; 
            end
            obj.stirpd = [pxt_0.stirpd, pxt_1.stirpd]; 

        end
        % ++ Method to replace the estimated background SDO ++ 
        function obj = computeBackgroundSdo(obj, xtdc)
            arguments
                obj
                xtdc xtDataCell
            end
            %// We can directly extract statemapping from xtdc
            XT_CH_NO = find(strcmp(obj.xtChName, xtdc.sensor)); 
            xData = getTensor(xtdc, XT_CH_NO, 'DATAFIELD', 'stateSignal', 'CONFORM_METHOD', 'trim');
            flatMat = reshape(squeeze(xData), 1, []); 
            SAM_PER_MS = obj.fs/1000; 

            [px0, px1] = pxTools.getPxtFromXt(flatMat, 'all', 1:obj.nStates+1, ...
                'navg', round([obj.px0DuraMs, obj.px1DuraMs] * SAM_PER_MS), ...
                'smoothwid', obj.pxProperties.smoothingFilterWidth, ...
                'smoothstd', obj.pxProperties.smoothingFilterStd, ... 
                'z_delay',   obj.pxProperties.zDelay); 
            
            [obj.sdoBkgrnd, obj.sdoBkgrndJoint] = SAT.compute.sdo5(px0, px1); 
            %{
            N_PTS = size(px0,2); 
            obj.sdoBkgrndJoint  = (px1*px0')/N_PTS; 
            obj.sdoBkgrnd       = ((px1*px0') - diag(sum(px0,2)))/N_PTS; 
            %}
            obj.generatedExactBackground = true;  
        end
        % ++ Method to replace the Markov Matrix; 
    
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
            obj.stats   = sMat.stats{1};
            obj.sigPVal = SIG_PVAL; 
            obj.zScore  = Z_SCORE; 
        end
        %}
        %% Operate
        % ___ Generate normalized Hypothesized Matrices from observed dat; 
        function obj = makeTransitionMatrices(obj, xtdc, ppdc, ALL_MAT)
            arguments
                obj 
                xtdc xtDataCell
                ppdc ppDataCell
                ALL_MAT {mustBeNumericOrLogical} = 1; 
            end
     
            %// This one requires the definition of the STA as mean of px
            MATTYPE = obj.transitionMatType; 
            
            %
            %// for some reason the 'sensor' field doesn't work 
            useXtChNo = find(strcmp(obj.xtChName, [xtdc.data{1,1}(:).sensor]), 1); 
            usePpChNo = find(strcmp(obj.ppChName, [ppdc.data{1,1}(:).sensor]), 1); 
            if isempty(useXtChNo)
                disp("Warning: No matching for XtChNo"); 
                useXtChNo = 1;
            end
            if isempty(usePpChNo)
                disp("Warning: No matching for XtChNo"); 
                usePpChNo = 1;

            end
            %}
            %useXtChNo = 1; 
            %usePpChNo = 1; 

            HStruct = SAT.predict.getPredictionMatrices(obj, xtdc, ppdc, useXtChNo,usePpChNo,...
                'type', MATTYPE); 
            
            nmCell = fieldnames(HStruct); 
            nFields = length(nmCell); 
            matCell = cell(1, nFields); 
            for f = 1:nFields
                matCell{f} = HStruct.(nmCell{f}); 
            end

            if ALL_MAT
                obj.transitionMat = matCell; 
               % _____
               obj.pxtNames     = nmCell; 
               obj.nPxtTypes    = nFields;
            else
                obj.transitionMat   = matCell{end}; 
                obj.pxtNames        = nmCell{end}; 
                obj.nPxtTypes       = 1;
            end
           obj.generatedTransitionMatrices = true; 
        end
        
        %% Bungle
        function sMat = bungleSdoStruct(obj)
           %// Method to 'reconstruct' a miniSDO array for the
           % common plotter method; 
           % __ >> Double-wrap a cell to make it look like a stacked 
            sMat = SAT.compute.sdoStruct_new(1,1); 
            sMat.signalType     = obj.xtChName; 
            sMat.neuronNames    = {obj.ppChName}; 
            sMat.levels         = obj.stateMapping; 
            sMat.sdosJoint      = {obj.sdoJoint}; 
            sMat.sdos           = {obj.sdo}; 
            sMat.bkgrndJointSDO = obj.sdoBkgrndJoint; 
            sMat.bkgrndSDO      = obj.sdoBkgrnd; 
            sMat.shuffles       = {obj.shuffles}; 
            sMat.stats          = {obj.stats};
            if ~isempty(obj.params)
                sMat.params         = obj.params; 
            else
                % __ for posterity__ (Redundant)
                sMat.params      = struct( ...
                    'xt', obj.xtProperties, ...
                    'pp', obj.ppProperties, ...
                    'px', obj.pxProperties); 
            end
            sMat.stirpd         = {obj.stirpd}; 

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
                'filter', 0, ...
                'saveFig', options.saveFig, ...
                'saveFormat', options.saveFormat, ...
                'outputDirectory', options.outputDirectory); 
           
            N_PX0_PTS = round(abs(obj.px0DuraMs*obj.fs/1000));  

            pxTools.plot.stirpd(obj.stirpd, N_PX0_PTS, 'binDuraMs', 1000/obj.fs, 'nSpikes', obj.nEvents); 

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
            pxt_est.markovMatrix    = obj.markovMatrix; %// this isn't exactly the same. Px of prediction  
            % __ Unique/ Differing Calls
            pxt_est.duraMs          = obj.px1DuraMs; 
            %pxt_est.stateMapping    = obj.stateMapping; 
            pxt_est.zDelay          = obj.pxProperties.zDelay; 
            pxt_est.filterWid       = obj.pxProperties.smoothingFilterWidth; 
            pxt_est.filterStd       = obj.pxProperties.smoothingFilterStd; 
            %  __ DUMMY FILL ___ 
            pxt_est.backgroundPx    = zeros(obj.nStates,1); 
            pxt_est.backgroundMkv   = zeros(obj.nStates,1); 

            %
            pxt_est.dataMatrices = obj.transitionMat; 

           % // export to a pxt;  
            
        end
    end
    %{
    methods (Static)
        function plotMatrix(mat)

        end
    end
    %}  

end
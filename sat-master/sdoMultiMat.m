%% SDO Multi-Mat
% Data Class for holding and manipulating multiple sdoMat classes. Designed
% for use within the SDO Analysis Toolkit.
%
% Used to rapidly compute multiple SDOs at once. 
% Can be exported to 'sdoMat' class for analysis. 

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

% 2.2.2024 - Upgrade to the V5 (asymmetric) estimation script, parallel compute

%// caution should be taken w/ inherited methods from the superclass; 
classdef sdoMultiMat < handle & matlab.mixin.Copyable   %& dataCellSuperClass
    properties
        fs              = 0; 
        % __ SuperSet ___
        nXtChannels     {mustBeInteger}= 0; 
        nPpChannels     {mustBeInteger}= 0; 
        % __ PXT PARAMS
        px0DuraMs       = -10; 
        px1DuraMs       = 10; 
        zDelay          {mustBeInteger}= 0; 
        nShift          {mustBeInteger}= 1; 
        filterWid       = 0; 
        filterStd       = 0; 
        nEventsUsed     = 0; 
        % __ Significance Testing
        sigPVal         = 0.05; 
        nSigValues      {mustBeInteger}= 1; 
        zScore          = false; 
        sigMat          = []; 
        %_____
        sdoMatCell      = {}; %// Reserved; 
        sdoStruct       = {}; 
        %__ MetaData
        xtProperties    = []; 
        ppProperties    = []; 
        pxProperties    = [];           
    end
    properties (Access = protected)
        populatedStructure = false; 
    end

    methods
        % __ Wrap the actual programmatic method; 
        function obj = compute(obj, xtdc, ppdc, useXtChannels, usePpChannels, useTrials, vars)
            arguments
                obj 
                xtdc xtDataCell
                ppdc ppDataCell
                useXtChannels {mustBeInteger} = 1:xtdc.nChannels;
                usePpChannels {mustBeInteger} = 1:ppdc.nChannels; 
                useTrials     {mustBeInteger} = 1:xtdc.nTrials; 
                vars.condenseShuffles = 0; 
                vars.method {mustBeMember(vars.method, {'original', 'asymmetric', 'optimized'})} = 'original';%'asymmetric'; 
                vars.parallelCompute = 0;
                vars.backgroundSubtraction = 0; % NOT yet fully implemented; default = 0; 
                %useTrials = []; 
            end
            %___ Just run the SDO Pipeline for all combinations using common params
            %//  use the programmatic method
            %(efficient) for calculating the core code; 
            xtdc = subsample(xtdc, useTrials, useXtChannels); 
            ppdc = subsample(ppdc, useTrials, usePpChannels); 

            if ~xtdc.discretizedData
                xtdc.discretize; 
            end

            obj.fs = xtdc.fs; 

            SIG_FACTOR = xtdc.fs/1000; 
            
            %Maybe we eventually use fractions of neurons or trials, but
            %for now, we'll just use ALL elements
            obj.nEventsUsed = sum(ppdc.nTrialEvents, 2); 
    
            % // 12.8.2023 Update
            if vars.backgroundSubtraction == 1
                % Experimental; 
            obj.sdoStruct = SAT.compute.populateSDOArray4(xtdc, ppdc, ... 
                'px0nPoints', obj.px1DuraMs*SIG_FACTOR, 'px1nPoints', obj.px1DuraMs*SIG_FACTOR, ...
                'pxShift', obj.nShift, 'pxDelay', obj.zDelay, ...
                'method', vars.method, 'parallelCompute', vars.parallelCompute); %, 'useTrials', useTrials); 
            else

            try 
            obj.sdoStruct = SAT.compute.populateSDOArray3(xtdc, ppdc, ... 
                'px0nPoints', obj.px1DuraMs*SIG_FACTOR, 'px1nPoints', obj.px1DuraMs*SIG_FACTOR, ...
                'pxShift', obj.nShift, 'pxDelay', obj.zDelay, ...
                'method', vars.method, 'parallelCompute', vars.parallelCompute); %, 'useTrials', useTrials); 
          %
            catch
                1; 
                %in case I forget to update the public release
            obj.sdoStruct = SAT.compute.populateSDOArray2(xtdc, ppdc, ... 
                'px0nPoints', obj.px1DuraMs*SIG_FACTOR, 'px1nPoints', obj.px1DuraMs*SIG_FACTOR, ...
                'pxShift', obj.nShift, 'pxDelay', obj.zDelay); %, 'useTrials', useTrials); 
            end
            end
          %}
            %}
            obj.nXtChannels = length(obj.sdoStruct); 
            obj.nPpChannels = length(obj.sdoStruct(1).sdos); 
            obj.populatedStructure = true; 
            %__ Append Params; 
            params.xt.xtDataName            = ''; 
            params.xt.DataFieldname         = xtdc.dataField; 
            params.xt.IDFieldname           = 'sensor'; 
            params.xt.MapMethod             = xtdc.mapMethod; 
            params.xt.MaxMode               = xtdc.maxMode; 
            params.pp.ppDataName            = ''; 
            params.pp.IDFieldname           = 'sensor';
            params.px.px0DurationMs         = obj.px0DuraMs; 
            params.px.px1DurationMs         = obj.px1DuraMs; 
            params.px.smoothingFilterWidth  = obj.filterWid; 
            params.px.smoothingFilterStd    = obj.filterStd; 
            % __ Depreciate one of these; Both here for redundancy
            params.px.x1StartShift          = obj.nShift; 
            params.px.x0x1Delay             = obj.zDelay; 
            params.px.nShift                = obj.nShift; 
            params.px.zDelay                = obj.zDelay; 
            %___
            obj.xtProperties = params.xt; 
            obj.ppProperties = params.pp; 
            obj.pxProperties = params.px; 
            %__ 
            for m=1:obj.nXtChannels
                obj.sdoStruct(m).params = params; 
            end
            %___ 
            if ~vars.condenseShuffles
                % otherwise, we perform stats during the direct computation
                obj.sdoStruct = SAT.compute.performStats(obj.sdoStruct);
            end
            if ppdc.nShuffles > 0
                obj.sdoStruct = SAT.compute.testStatSig(obj.sdoStruct, obj.sigPVal, obj.zScore);
            end
            %___ 
        end
        %// find sig combos at specified threshold; 
        function obj = findSigSdos(obj, SIG_THRESH)
            arguments
                obj
                SIG_THRESH {mustBeInteger} = obj.nSigValues; 
            end
            obj.sigMat = SAT.sdoUtils.findSigSdos(obj.sdoStruct, SIG_THRESH);
        end
        %// Extract an 'sdoMat' Class from multi-Mat; 
        function sdoM = extract(obj, XT_CH_NO, PP_CH_NO)
            % Return an 'sdoMat' structure from the 'sdoMultiMat'
            arguments
                obj
                XT_CH_NO {mustBeInteger}
                PP_CH_NO {mustBeInteger}
            end
            if ~obj.populatedStructure
                disp("SDO Structures have not been generated. Please use the 'compute' method first"); 
                return
            end
            sdoM = sdoMat();
            sdoM.importSdoStruct(obj.sdoStruct, XT_CH_NO, PP_CH_NO); 
            % __>> Need to copy properties here; 
            propList = {'sigPVal', 'px0DuraMs', 'px1DuraMs', 'fs'};  
            sdoM.copyProperties(obj, propList);
            %
            % Temp fix, not ideal; 
            
            %
        end
        % ___ 
        function sdos = getSdos(obj, useXtChannels, usePpChannels)
            arguments
                obj
                useXtChannels = 1; 
                usePpChannels = 1; 
            end
            N_USE_XT = length(useXtChannels); 
            N_USE_PP = length(usePpChannels); 
            nBins = length(obj.sdoStruct(1).bkgrndSDO); %non-optimal call; 
            sdos = cell(1,N_USE_XT); 
            for m_i = 1:N_USE_XT
                m = useXtChannels(m_i); 
                sdos{m_i} =  zeros(nBins, nBins, N_USE_PP); 
                for u_i = 1:N_USE_PP
                    u = usePpChannels(u_i);
                    sdos{m_i}(:,:,u_i) = obj.sdoStruct(m).sdos{u}; 
                end
            end
            if N_USE_XT == 1
                % unwrap
                sdos = sdos{1};
            end
        end
        %___ Optimization (ad-hoc)
        % Order 2 is faster; Order 4 is smoother
        function obj = optimize(obj, xtdc, ppdc, XT_CH_NO, PP_CH_NO, vars)
            arguments
                obj
                xtdc
                ppdc
                XT_CH_NO = 1:obj.nXtChannels; 
                PP_CH_NO = 1:obj.nPpChannels;
                vars.errorOrder {mustBeMember(vars.errorOrder, [2,4])} = 2; 
            end
            % Wrapper for the V7
            obj = SAT.sdoUtils.optimize(obj, xtdc, ppdc, ...
                XT_CH_NO, PP_CH_NO, 'errorOrder', vars.errorOrder); 
        end

        %___ Prediction
        function errorStruct = getPredictionError(obj, xtdc, ppdc, XT_CH_NO, PP_CH_NO, vars)
            arguments
                obj
                xtdc xtDataCell
                ppdc ppDataCell
                XT_CH_NO = 1; 
                PP_CH_NO = 1; 
                vars.plot = 0; 
                vars.testSignificance = 1; 
            end

            % __ This is the efficient 'internal' based prediction using
            % classes; 
            
            if isempty(xtdc.trTimeLen) || isempty(ppdc.trTimeLen)
                disp("xtDataCell or ppDataCell needs to be passed to generate predictions.")
                errorStruct = []; 
                return
            end

            px0 = dataCell.adaptors.getConformedPxtDataCell(obj, 'px0'); 
            
            % TODO: Streamline stirpd extraction; 
           
            px0.import(xtdc,ppdc,XT_CH_NO,PP_CH_NO, ...
                'includeShuffles', 0, ...
                'calculateStirpd', 0); 

            px1 = dataCell.adaptors.getConformedPxtDataCell(obj, 'px1'); 
            px1.import(xtdc,ppdc,XT_CH_NO,PP_CH_NO, ...
                'includeShuffles', 0, ...
                'calculateStirpd', 0); 

            sdo = obj.extract(XT_CH_NO, PP_CH_NO); 

            % __ Necessary to point to the correct data; 
            xtdc_mini = xtdc.subsample(1:xtdc.nTrials, XT_CH_NO); 
            ppdc_mini = ppdc.subsample(1:ppdc.nTrials, PP_CH_NO); 

            % SDO only uses a single comp; we demo this here; 
            sdo.makeTransitionMatrices(xtdc_mini,ppdc_mini); 

            pd_px1 = sdo.getPredictionPxt(px0);

            errorStruct = SAT.predict.predictionError(); %Constructor; 
            errorStruct.computeError(pd_px1, px1, 'testSignificance', vars.testSignificance); 
 
            if vars.plot
                errorStruct.plot(); 
            end

        end
        %% ____ 
        function [px0, px1] = getPx0Px1(obj, xtdc, ppdc, USE_XT_CH, USE_PP_CH)
            arguments
                obj sdoMultiMat
                xtdc xtDataCell
                ppdc ppDataCell
                USE_XT_CH = 1:xtdc.nChannels;  % --> Maybe make these ranges?
                USE_PP_CH = 1:ppdc.nChannels; 
            end
            % After importing original data classes, return the probability
            % distributions used for calculating the SDO/dpx. Use the parameters
            % stored in the sdoMultiMat Class. 
            
            % // Get pre and post-spike distributions/classes from data
            
            nUsePpChannels = length(USE_PP_CH);
            nUseXtChannels = length(USE_XT_CH); 
            
            ppdcs = ppdc.subsample(1:ppdc.nTrials, USE_PP_CH); 
            xtdcs = xtdc.subsample(1:xtdc.nTrials, USE_XT_CH); 
            ppData = ppdcs.data; 
            xtData = xtdcs.data; 
            
            useXtChannels = 1:nUseXtChannels; 
            
            % __ >> RIP Parameters; 
            [obsPxt0Cell, obsPxt1Cell] = pxTools.getTrialwisePxt( ...
                    xtData, ppData, ...
                    1:xtdc.nTrials, useXtChannels, ...
                    'xtDataField', xtdc.dataField,...
                    'ppDataField', ppdc.dataField, ... 
                    'pxNPoints', [abs(obj.pxProperties.px0DurationMs), obj.pxProperties.px1DurationMs], ...
                    'pxFilter',  [obj.pxProperties.smoothingFilterWidth, obj.pxProperties.smoothingFilterStd], ...
                    'pxShift',   obj.pxProperties.nShift, ...
                    'pxDelay',   obj.pxProperties.zDelay); 
            
            % __>> TODO: Export/Standardize these functions to a macro; 
            if nUsePpChannels > 1
                % We have [1 x nTrials] cell of [1 x nChannels]
                px0 = cell(nUseXtChannels,nUsePpChannels); 
                px1 = cell(nUseXtChannels,nUsePpChannels); 
                for u = 1:nUsePpChannels
                    x0Cell = cell(nUseXtChannels,xtdc.nTrials); 
                    x1Cell = cell(nUseXtChannels,xtdc.nTrials); 
                    %
                    for m = 1:nUseXtChannels
                        for tr = 1:xtdc.nTrials
                            x0Cell{m,tr} = obsPxt0Cell{1,tr}{m,u}; 
                            x1Cell{m,tr} = obsPxt1Cell{1,tr}{m,u}; 
                        end
                    end
                    px0(:,u) = cellhcat(x0Cell); 
                    px1(:,u) = cellhcat(x1Cell); 
                end
            
            else
                p0_0 = cellhcat(obsPxt0Cell); 
                p0_1 = cellhcat(obsPxt1Cell);  
                %
                px0 = cellhcat(p0_0); 
                px1 = cellhcat(p0_1); 
            end
        
        end

        %%

        %// Because we often care about the properly normalized SDOs; 
        % Returning these as a STACK 
        function nSdos = getNormSdos(obj, useXtChannels, usePpChannels, background)
            arguments
                obj
                useXtChannels = 1; 
                usePpChannels = 1; 
                background = 0; 
            end
            N_USE_XT = length(useXtChannels); 
            N_USE_PP = length(usePpChannels); 

            nBins = length(obj.sdoStruct(1).bkgrndSDO); %non-optimal call; 
            nSdos = cell(1, N_USE_XT); 
            for m_i = 1:N_USE_XT
                m = useXtChannels(m_i); 
                if background == 1
                    nSdos{m_i} = SAT.sdoUtils.normsdo( ...
                        obj.sdoStruct(m_i).bkgrndSDO, ... 
                        obj.sdoStruct(m_i).bkgrndJointSDO); 
                else
                    nSdos{m_i} = zeros(nBins, nBins, N_USE_PP); 
                    for u_i = 1:N_USE_PP
                        u = usePpChannels(u_i); 
                        %
                        nSdos{m_i}(:,:,u_i) = SAT.sdoUtils.normsdo(obj.sdoStruct(m).sdos{u}, ... 
                            obj.sdoStruct(m).sdosJoint{u}); 
                    end
                end
            end
            if N_USE_XT == 1
                % unwrap cell; 
                nSdos = nSdos{1}; 
            end
        end


        function plotMatrix(obj, useXtChannels, usePpChannels, vars)
            arguments
                obj
                useXtChannels = 1; 
                usePpChannels = 1; 
                vars.matField  {mustBeMember(vars.matField, {'sdos', 'sdosJoint', 'drift', 'bkgrndSDO'})} = 'sdos'; 
                vars.norm      {mustBeNumericOrLogical} = 0;  
            end
            N_USE_XT = length(useXtChannels); 
            N_USE_PP = length(usePpChannels); 

            nTotal = N_USE_XT*N_USE_PP; 
            N_COLS = ceil(sqrt(nTotal)); 
            N_ROWS = ceil(nTotal/N_COLS);             
            %
            figure;
            %
            ii = 1; 
            for mi = 1:N_USE_XT
                m = useXtChannels(mi); 
                xtName = obj.sdoStruct(m).signalType; 
                for uii = 1:N_USE_PP
                    u = usePpChannels(uii); 
                    ppName = obj.sdoStruct(m).neuronNames{u}; 
                    switch vars.matField
                        case {'sdos', 'sdosJoint'}
                            mat = obj.sdoStruct(m).(vars.matField){u}; 
                        case 'bkgrndSDO'
                        mat = obj.sdoStruct(m).(vars.matField); 
                        case 'drift'
                            m1 = obj.sdoStruct(m).sdos{u}; 
                            [mat, ~] = SAT.sdoUtils.splitSymmetry(m1);
                    end
                    if vars.norm == 1
                           M = obj.sdoStruct(m).sdosJoint{u}; 
                           [mat] = SAT.sdoUtils.normsdo(mat, M); 
                    end

                    %
                    subplot(N_ROWS, N_COLS, ii)
                    imagesc(mat); 
                    switch vars.matField
                        case {'sdos', 'drift', 'bkgrndSDO'}
                            cMap = SAT.sdoUtils.getSdoColormap(mat); 
                            colormap(cMap);
                            line([1, length(mat)], [1, length(mat)], 'lineStyle', '--', 'color', 'black'); 
                        case {'sdosJoint'}
                            line([1, length(mat)], [1, length(mat)], 'lineStyle', '--', 'color', 'white'); 
                    end

                    axis xy
                    axis square
                    
                    title(strcat(ppName, '\rightarrow', xtName)); 
                    ii = ii+1; 
                end
            end
            
        end
        % __ X-Class plotting Methods; 
        function plot(obj, XT_CH_NO, PP_CH_NO, options)
            arguments
                obj
                XT_CH_NO {mustBeInteger} = 1; 
                PP_CH_NO {mustBeInteger} = 1; 
                options.saveFig         {mustBeNumericOrLogical} = 0; 
                options.saveFormat      {mustBeMember(options.saveFormat, {'png', 'svg'})} = 'png'; 
                options.outputDirectory = []; 
                options.filter          = 1; 

            end
            n_xt = length(XT_CH_NO); 
            n_pp = length(PP_CH_NO); 
            for m = 1:n_xt 
                for u = 1:n_pp
                    SAT.plot.plotHeader(obj, XT_CH_NO(m), PP_CH_NO(u), ...
                        'filter', options.filter, ...
                        'saveFig', options.saveFig, ....
                        'saveFormat', options.saveFormat, ...
                        'outputDirectory', options.outputDirectory); 
                    %
                end
                obj.plotStirpd(XT_CH_NO(m), PP_CH_NO); 
            end
        end
        % __ Quick -plots; 
        function plotStirpd(obj, useXtChannels, usePpChannels)
            % General, "PLOT ALL" method for evaluating 
            arguments
                obj
                useXtChannels = 1; 
                usePpChannels = 1; 
            end
            N_USE_XT = length(useXtChannels); 
            N_USE_PP = length(usePpChannels); 

            nTotal = N_USE_XT*N_USE_PP; 
            N_COLS = ceil(sqrt(nTotal)); 
            N_ROWS = ceil(nTotal/N_COLS); 

            N_PX0_PTS = round(abs(obj.px0DuraMs*obj.fs/1000));  

            f = figure;
            ii  = 1; 
            n = get(gcf,'Number'); 
            for mi = 1:N_USE_XT
                m = useXtChannels(mi); 
                for ui = 1:N_USE_PP
                    u = usePpChannels(ui); 
                    %
                    titleStr = strcat(obj.sdoStruct(m).neuronNames{u}, '\rightarrow', obj.sdoStruct(m).signalType); 

                    pxTools.plot.stirpd(obj.sdoStruct(m).stirpd{u}, ...
                        N_PX0_PTS, 'binDuraMs', 1000/obj.fs, ...
                        'nSpikes', obj.sdoStruct(m).stats{u}.nEvents, ... 
                        'titleStr', titleStr); 
                    ax = gca; 
                    ax_copy = copyobj(ax,f); 
                    subplot(N_ROWS, N_COLS, ii, ax_copy);
                    f.Colormap = bone; 
                    colorbar; 
                    close(n+1);
                    ii = ii+1; 
                end
                sgtitle("STA-P(x)"); 
            end
        end
        %______ 
    end
end

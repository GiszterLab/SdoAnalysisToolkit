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

% 2.2.2024 - Upgrade to the V5 (assymetric) estimation script, parallel compute

%// caution should be taken w/ inherited methods from the superclass; 
classdef sdoMultiMat < handle %& dataCellSuperClass
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
                vars.condenseShuffles = 1; 
                vars.method {mustBeMember(vars.method, {'original', 'asymmetric'})} = 'asymmetric'; 
                vars.parallelCompute = 0; 
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
            try 
            obj.sdoStruct = SAT.compute.populateSDOArray3(xtdc, ppdc, ... 
                'px0nPoints', obj.px1DuraMs*SIG_FACTOR, 'px1nPoints', obj.px1DuraMs*SIG_FACTOR, ...
                'pxShift', obj.nShift, 'pxDelay', obj.zDelay, ...
                'method', vars.method, 'parallelCompute', vars.parallelCompute); %, 'useTrials', useTrials); 
          %
            catch
                %in case I forget to update the public release
            obj.sdoStruct = SAT.compute.populateSDOArray2(xtdc, ppdc, ... 
                'px0nPoints', obj.px1DuraMs*SIG_FACTOR, 'px1nPoints', obj.px1DuraMs*SIG_FACTOR, ...
                'pxShift', obj.nShift, 'pxDelay', obj.zDelay); %, 'useTrials', useTrials); 
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
            %__ 
            for m=1:obj.nXtChannels
                obj.sdoStruct(m).params = params; 
            end
            %___ 
            if ~vars.condenseShuffles
                % otherwise, we perform stats during the direct computation
                obj.sdoStruct = SAT.compute.performStats(obj.sdoStruct);
            end
            obj.sdoStruct = SAT.compute.testStatSig(obj.sdoStruct, obj.sigPVal, obj.zScore); 
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

        %___ Prediction
        function errorStruct = getPredictionError(obj, xtdc, ppdc, XT_CH_NO, PP_CH_NO, vars)
            arguments
                obj
                xtdc xtDataCell
                ppdc ppDataCell
                XT_CH_NO = 1; 
                PP_CH_NO = 1; 
                vars.plot = 0; 
            end

            % __ This is the efficient 'internal' based prediction using
            % classes; 
           
            px0 = pxtDataCell(); 
            px0.duraMs = obj.px0DuraMs; 
            
            % TODO: Streamline stirpd extraction; 
           
            px0.import(xtdc,ppdc,XT_CH_NO,PP_CH_NO, ...
                'includeShuffles', 0, ...
                'calculateStirpd', 0); 

            px1 = pxtDataCell(); 
            px1.duraMs = obj.px1DuraMs; 
            px1.import(xtdc,ppdc,XT_CH_NO,PP_CH_NO, ...
                'includeShuffles', 0, ...
                'calculateStirpd', 0); 

            sdo = obj.extract(XT_CH_NO, PP_CH_NO); 

            sdo.makeTransitionMatrices(xtdc,ppdc); 

            pd_px1 = sdo.getPredictionPxt(px0);

            errorStruct = SAT.predict.predictionError(); 
            errorStruct.computeError(pd_px1, px1); 
 
            if vars.plot
                errorStruct.plot(); 
            end

        end
%

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
                vars.matField  {mustBeMember(vars.matField, {'sdos', 'sdosJoint', 'drift'})} = 'sdos'; 
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
                        case 'drift'
                            m1 = obj.sdoStruct(m).sdos{u}; 
                            [mat, ~] = SAT.sdoUtils.splitSymmetry(m1);
                    end
                    %
                    subplot(N_ROWS, N_COLS, ii)
                    imagesc(mat); 
                    axis xy
                    line([1, length(mat)], [1, length(mat)], 'lineStyle', '--', 'color', 'white'); 
                    title(strcat(ppName, '\rightarrow', xtName)); 
                    ii = ii+1; 
                end
            end
            
        end
        % __ X-Class plotting Methods; 
        function plot(obj, XT_CH_NO, PP_CH_NO)
            arguments
                obj
                XT_CH_NO {mustBeInteger} = 1; 
                PP_CH_NO {mustBeInteger} = 1; 
            end
            n_xt = length(XT_CH_NO); 
            n_pp = length(PP_CH_NO); 
            for m = 1:n_xt 
                for u = 1:n_pp
                    sdoM = obj.extract(XT_CH_NO(m), PP_CH_NO(u));
                    plot(sdoM); 
                end
            end
        end
        % __ Quick -plots; 
        function plotStirpd(obj, useXtChannels, usePpChannels)
            % General, "PLOT ALL" method for evaluating 
            % useXtChannels = []
            % usePpChannels = []; 
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

%% P(x,t) Data Structure 
% Data Class for holding measured probability data (pX(t)). Designed for
% use within the SDO Analysis Toolkit.
%
% 1) pxtDataCells may be derived from xtdc + ppdc
% 2) pxtDataCells may be derived from predictions from sdoMat

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


classdef pxtDataCell < handle & matlab.mixin.Copyable & dataCellSuperClass &dataCell.dependencies.probabilityData
    properties (Access = public)
        %// Initialize w/ Default Parameters; 
        xtName          char = []; 
        ppName          char = [];
        xtChName        char = []; 
        ppChName        char = [];
        % __ 
        pxtSampling     = 'ppWise'; % Reserved for Future Use; 
        pxtNames        = {}; %HH String
        nPxtTypes       {mustBeInteger} = 0; % Number HH; 
        nEvents         {mustBeInteger} = 0; 
        nShuffles       {mustBeInteger} = 0; 
        % __ Meta data
        xtMetaData      = []; 
        ppMetaData      = []; 
        xtProperties    = []; %reserved
        ppProperties    = []; %reserved
        % __ Gen params (Default)
        duraMs          double = 10; 
        nShift          {mustBeInteger} = 1; 
        zDelay          {mustBeInteger} = 0; 
        filterWid       double = 0; 
        filterStd       double = 0; 
        % ___ Inherited (Default)
        %nStates         {mustBeInteger} = 20; %inherited from above; 
        fs              double {mustBeNonnegative} = 0; 
        stateMapping    = zeros(1,21);
        % ___ 
        backgroundPx    = zeros(20,1);
        backgroundMkv   = zeros(20); 
        markovMatrix    = zeros(20); 
        %
        dataMatrices    = {}; % Containing the actual SDOs/Markovs; 
        %
        xs              = []; % State-at-spike; 
        data            = {}; %{nPxTypes x 1} cell of doubles;  Probability
        data_x          = {}; %{nPxTypes x 1} cell of doubles;  Single State
        shuffData       = {}; %{nPxTypes x NShuff} cell of doubles; 
        % ___
        %stirpd          = zeros(20); %half-stirpd; inherited
        % ___ 
        stateAssignment char {mustBeMember(stateAssignment,{'max','mean','median'})} = 'max'; 
        errorStruct     = {}; 
        dofPxCorrect    = 0; % Experimental rescaling of H1-H3; 
    end
    properties (Dependent)
        generatedErrorStruct
    end
    methods
        %% Dependencies
        function LI = get.generatedErrorStruct(obj)
            if ~isempty(obj.errorStruct)
                LI = true; 
            else
                LI = false;
            end
        end
        %% IMPORT: (Get Data from xtDC and ppDC)
        function obj = import(obj, xtdc, ppdc, XT_CH_NO, PP_CH_NO, vars)
            arguments
                obj
                xtdc        xtDataCell
                ppdc        ppDataCell
                XT_CH_NO    {mustBeInteger} = 1; 
                PP_CH_NO    {mustBeInteger} = 1; 
                vars.includeShuffles = 1; 
                vars.calculateStirpd = 1; 
            end
            % __ Sample Data; 
            obj.xtName          = xtdc.dataField; 
            obj.ppName          = ppdc.dataField; 
            obj.xtChName        = xtdc.sensor{XT_CH_NO}; 
            obj.ppChName        = ppdc.sensor{PP_CH_NO}; 
            %obj.xtProperties    = xtdc.metadata; 
            %obj.ppProperties    = ppdc.metadata; 

            %__ Append Params; 
            params.xt.xtDataName            = ''; 
            params.xt.DataFieldname         = xtdc.dataField; 
            params.xt.IDFieldname           = 'sensor'; 
            params.xt.MapMethod             = xtdc.mapMethod; 
            params.xt.MaxMode               = xtdc.maxMode; 
            params.pp.ppDataName            = ''; 
            params.pp.IDFieldname           = 'sensor';
            %params.px.px0DurationMs         = obj.px0DuraMs; 
            %params.px.px1DurationMs         = obj.px1DuraMs; 
            params.px.px0DurationMs         = obj.duraMs; 
            params.px.px1DurationMs         = obj.duraMs; 
            params.px.smoothingFilterWidth  = obj.filterWid; 
            params.px.smoothingFilterStd    = obj.filterStd; 
            % __ Depreciate one of these; Both here for redundancy
            params.px.x1StartShift          = obj.nShift; 
            params.px.x0x1Delay             = obj.zDelay; 
            params.px.nShift                = obj.nShift; 
            params.px.zDelay                = obj.zDelay; 
            %___________
            obj.xtProperties = params.xt; 
            obj.ppProperties = params.pp; 
            %__________
            obj.xtMetaData      = xtdc.metadata; 
            obj.ppMetaData      = ppdc.metadata; 
            % __ Inherit; 
            obj.nStates         = xtdc.nBins; 
            if ~ppdc.shuffledSpikes
                ppdc.shuffle; 
            end
            obj.nShuffles       = ppdc.nShuffles; 
            obj.fs              = xtdc.fs; 
            if ~xtdc.discretizedData
                xtdc.discretize; 
            end
            obj.stateMapping    = xtdc.data{1,1}(XT_CH_NO).signalLevels; %WARNING:: temporary 
            
            N_STATES = length(obj.stateMapping)-1; 
            if obj.duraMs > 0
                N_PX0_PTS = 0; 
                N_PX1_PTS = round((obj.fs/1000)*obj.duraMs);
            else
                N_PX0_PTS = abs(round((obj.fs/1000)*obj.duraMs));
                N_PX1_PTS = 0; 
            end
            
            xData = squeeze(getTensor(xtdc, XT_CH_NO, 'DATAFIELD', 'stateSignal', 'CONFORM_METHOD', 'pad')); 
            XT_LEN = size(xData,1); 

            spikeIdx = ppdc.getRasterIndices(xtdc.fs, 1:xtdc.nTrials, PP_CH_NO); 

            xs_val = xtdc.getValuesAtIndices(spikeIdx, 'dataField', 'stateSignal', 'useChannels',XT_CH_NO); % directly reference state-at-spike; 
            if iscell(xs_val)  
                obj.xs = cellhcat(xs_val); 
            else
                obj.xs = xs_val; 
            end


            if vars.includeShuffles
                shuffIdx = ppdc.getRasterIndices(xtdc.fs, 1:xtdc.nTrials, PP_CH_NO, 'dataField', 'shuffle'); 
            end
            % __ Calculate Offset
            IDX_OFF = num2cell(0:XT_LEN:(xtdc.nTrials-1)*XT_LEN, 1); 
            spikeOff = cellfun(@plus, IDX_OFF, spikeIdx, 'UniformOutput', false); 
            st = cellhcat(spikeOff); 

            if vars.includeShuffles
                shuffOff = cellfun(@plus, IDX_OFF, shuffIdx, 'UniformOutput', false);  
                stSS= cellhcat(shuffOff); 
            end

            xt = reshape(xData, 1, []);

            [pxt_0, pxt_1, ix_t0, ix_t1] = pxTools.getPxtFromXt(xt, st, 1:N_STATES+1, ...
                 'navg',        [N_PX0_PTS, N_PX1_PTS], ... 
                 'smoothwid',   obj.filterWid, ...
                 'smoothstd',   obj.filterStd, ... 
                 'n_shift',     obj.nShift, ....  
                 'z_delay',     obj.zDelay);

            if vars.includeShuffles
                [pxt0SS, pxt1SS] = pxTools.getPxtFromXt(xt, stSS, 1:N_STATES+1, ...
                     'navg',        [N_PX0_PTS, N_PX1_PTS], ... 
                     'smoothwid',   obj.filterWid, ...
                     'smoothstd',   obj.filterStd, ... 
                     'n_shift',     obj.nShift, ....  
                     'z_delay',     obj.zDelay);
            else
                pxt0SS = []; 
                pxt1SS = []; 
            end
            
            if obj.duraMs < 0
                pxtData     = pxt_0; 
                pxtShuff    = pxt0SS; 
                mkvData     = xData(ix_t0); 
                pxName      = 't0_actual';
                II          = N_PX0_PTS + obj.zDelay; 
            else
                pxtData     = pxt_1; 
                pxtShuff    = pxt1SS; 
                pxName      = 't1_actual'; 
                mkvData     = xData(ix_t1); 
                II          = N_PX1_PTS + obj.zDelay; 
            end
            %___ 
            obj.pxtNames        = pxName; 
            obj.nPxtTypes       = 1;
            obj.backgroundPx    = histcounts(xt, N_STATES)/length(xt); 
            obj.data            = pxtData; 
            obj.data_x          = pxTools.getXfromPx(pxtData, obj.stateAssignment); 
            obj.shuffData       = pxtShuff;  
            obj.markovMatrix    = pxTools.getMarkovFromXt(mkvData, N_STATES); 
            obj.backgroundMkv   = pxTools.getMarkovFromXt([xt(1:end-II); xt(II+1:end)], N_STATES); 
            [~, obj.nEvents]    = size(pxtData); 
            %
            obj.dataMatrices = {obj.markovMatrix}; 
            %
            if vars.calculateStirpd
                obj.calculateStirpd(xtdc, ppdc, XT_CH_NO, PP_CH_NO, ...
                    'dataField', 'stateSignal', 'n_shift', obj.nShift-1, ... 
                    'z_delay', obj.zDelay, 't0_nPoints', N_PX0_PTS, ... 
                    't1_nPoints', N_PX1_PTS, 'fs', obj.fs);  
            end

        end
       
        %%


        %% OPERATE
        
        % __ BIT-WISE FUNCTION OPERATION
        function obj = bsxop(obj, pxtdc, funcHandle, DATAFIELD) 
            arguments
                obj
                pxtdc pxtDataCell 
                funcHandle function_handle 
                DATAFIELD char = 'data'; 
            end

            if isa(obj.(DATAFIELD), 'cell')
                ISCELL = 1; 
            else
                ISCELL = 0; 
            end
            % __ EXTRACT; OPERATE; REPACKAGE
            % __ Extract
            if ISCELL
                pxtTen1 = cellvcat(obj.(DATAFIELD));
                pxtTen2 = cellvcat(pxtdc.(DATAFIELD));
            else
                pxtTen1 = obj.(DATAFIELD); 
                pxtTen2 = pxtdc.(DATAFIELD); 
            end
            % __ Operate
            pxtNet  = bsxfun(funcHandle, pxtTen1, pxtTen2); 
            % __ Repackage; 
            if ISCELL
                pxtCell  = mat2cell(pxtNet, obj.nStates, obj.nEvents); 
                obj.(DATAFIELD) = pxtCell; 
            else
                obj.(DATAFIELD) = pxtNet;
            end
        end
        
        %% COMPARE
        function obj = comparePxt(obj,px1)
            arguments
                obj
                px1 pxtDataCell
            end
            % __ Bungle pxtData to fit prior expectations; 
            %{
            errorSAll = []; 
            
            errorSAll = cell(1, px1.nPxtTypes); 

            for gg = 1:px1.nPxtTypes
                if isa(px1.data, 'cell')
                   PX_NAME = px1.pxtNames{gg}; 
                   x1PxArr.(px1.pxtNames{gg})   = px1.data{gg}; 
                   x1StateArr.(px1.pxtNames{gg})= pxTools.getXfromPx(px1.data{gg}, px1.stateAssignment);  
                else
                   x1PxArr.(px1.pxtNames)   = px1.data; 
                   PX_NAME = px1.pxtNames; 
                   x1StateArr.(px1.pxtNames)= pxTools.getXfromPx(px1.data, px1.stateAssignment);  
                end
                %__________
                for hh = 1:obj.nPxtTypes
                   pdPxArr.(obj.pxtNames{hh})       = obj.data{hh}; 
                   pdStateArr.(obj.pxtNames{hh})    = pxTools.getXfromPx(obj.data{hh}, obj.stateAssignment);  
                end
                
                N_BINS   = obj.nStates; 
                N_XT_PTS = obj.nEvents;  
                
                %// Temp hack-around; 
                x1StateArr   = x1StateArr.(px1.pxtNames); 
                x0StateArr   = x1StateArr; 
                x1PxArr      = x1PxArr.(px1.pxtNames); 
                
                errorS = SAT.predict.calcPredictionError(x0StateArr, x1StateArr, pdStateArr, x1PxArr, pdPxArr, N_BINS, ...
                'refName', PX_NAME, ... 
                'nXtPts', N_XT_PTS); 
                
                % __ concat; 
                errorSAll = [errorSAll errorS]; 
            end
            obj.errorStruct = errorSAll; 
            %}

            errorS = SAT.predict.predictionError(); 
            errorS.computeError(obj, px1); 

            obj.errorStruct = errorS; 
            if obj.dofPxCorrect == 1
                obj.errorStruct = SAT.predict.dofPxCorrectError(obj.errorStruct, 1); 
            end
            %obj.generatedErrorStruct = true; 
        end
        
        %% Direct Plotter Method
        function plot(obj, DATA_FIELD) %overload
            arguments
                obj
                DATA_FIELD char = 'data'; 
            end

            % __ may be unstable for shuffles;
            % --> CDFs may be preferable to direct heatmaps; 
            
            if isa(obj.(DATA_FIELD), 'cell')
                ISCELL = 1; 
            else
                ISCELL = 0; 
            end
            
            % // Unsure how to handle all shuffles ... 
            N_ELEM = length(obj.(DATA_FIELD)); 
            
            if ISCELL
                for elm = 1:N_ELEM    
                    figure; 
                    if ISCELL 
                        imagesc(obj.(DATA_FIELD){elm}); 
                        title(strcat("P(x,t):", obj.pxtNames{elm})); 
                        axis xy
                        xlabel("Position")
                        ylabel("Event State");     
                    end
                end
            else
                imagesc(obj.(DATA_FIELD)); 
                title(strcat("P(x,t:", obj.pxtNames));  
                axis xy
                xlabel("Position")
                ylabel("Event State"); 
                %caxis; 
            end
        end
        

        %
        % __ Error Plotter; 
        function plotError(obj)
            if ~obj.generatedErrorStruct
                disp("Error Structure not generated."); 
                return
            end
            % Sort of redundant now
            obj.errorStruct.plot(); 

        end
        %}
        
    end
    
    
end
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


classdef pxtDataCell < handle & matlab.mixin.Copyable & dataCellSuperClass
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
        xtProperties    = []; %reserved
        ppProperties    = []; %reserved
        % __ Gen params (Default)
        duraMs          double = 10; 
        nShift          {mustBeInteger} = 1; 
        zDelay          {mustBeInteger} = 0; 
        filterWid       double = 0; 
        filterStd       double = 0; 
        % ___ Inherited (Default)
        nStates         {mustBeInteger} = 20; 
        fs              double {mustBeNonnegative} = 0; 
        stateMapping    = zeros(1,21);
        % ___ 
        backgroundPx    = zeros(20,1); 
        backgroundMkv   = zeros(20); 
        markovMatrix    = zeros(20); 
        data            = {}; %{nPxTypes x 1} cell of doubles;  
        shuffData       = {}; %{nPxTypes x NShuff} cell of doubles; 
        % ___
        stateAssignment (1,:) char {mustBeMember(stateAssignment,{'max','mean','median'})} = 'max'; 
        errorStruct     = {}; 
        dofPxCorrect    = 0; % Experimental rescaling of H1-H3; 
    end
    properties (Access = protected)
        generatedErrorStruct = false; 
    end
    methods
        %% IMPORT: (Get Data from xtDC and ppDC)
        function obj = import(obj, xtdc, ppdc, XT_CH_NO, PP_CH_NO)
            arguments
                obj
                xtdc        xtDataCell
                ppdc        ppDataCell
                XT_CH_NO    {mustBeInteger} = 1; 
                PP_CH_NO    {mustBeInteger} = 1; 
            end
            % __ Sample Data; 
            obj.xtName          = xtdc.dataField; 
            obj.ppName          = ppdc.dataField; 
            obj.xtChName        = xtdc.sensor{XT_CH_NO}; 
            obj.ppChName        = ppdc.sensor{PP_CH_NO}; 
            obj.xtProperties    = xtdc.metadata; 
            obj.ppProperties    = ppdc.metadata; 
            % __ Inherit; 
            obj.nStates         = xtdc.nBins; 
            obj.nShuffles       = ppdc.nShuffles; 
            obj.fs              = xtdc.fs; 
            try 
                obj.stateMapping    = xtdc.data{1,1}(XT_CH_NO).signalLevels; %WARNING:: temporary 
            catch
                %// Not preferable mthod here, as it isn't shown to the
                %user directly. 
                obj.stateMapping    = pxTools.getXtSignalLevels( ...
                    max(xtdc.channelAmpMax(XT_CH_NO,:)), ...
                    min(xtdc.channelAmpMin(XT_CH_NO,:)), ... 
                    xtdc.nBins, xtdc.mapMethod); 
            end
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
            shuffIdx = ppdc.getRasterIndices(xtdc.fs, 1:xtdc.nTrials, PP_CH_NO, 'shuffle'); 
            % __ Calculate Offset
            IDX_OFF = num2cell(0:XT_LEN:(xtdc.nTrials-1)*XT_LEN, 1); 
            spikeOff = cellfun(@plus, IDX_OFF, spikeIdx, 'UniformOutput', false); 
            shuffOff = cellfun(@plus, IDX_OFF, shuffIdx, 'UniformOutput', false);  

            xt = reshape(xData, 1, []); 
            st = cellhcat(spikeOff); 
            stSS= cellhcat(shuffOff); 

            [pxt_0, pxt_1, ix_t0, ix_t1] = pxTools.getPxtFromXt(xt, st, 1:N_STATES+1, ...
                 'navg',        [N_PX0_PTS, N_PX1_PTS], ... 
                 'smoothwid',   obj.filterWid, ...
                 'smoothstd',   obj.filterStd, ... 
                 'n_shift',     obj.nShift, ....  
                 'z_delay',     obj.zDelay);

            [pxt0SS, pxt1SS] = pxTools.getPxtFromXt(xt, stSS, 1:N_STATES+1, ...
                 'navg',        [N_PX0_PTS, N_PX1_PTS], ... 
                 'smoothwid',   obj.filterWid, ...
                 'smoothstd',   obj.filterStd, ... 
                 'n_shift',     obj.nShift, ....  
                 'z_delay',     obj.zDelay);                
            
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
            obj.shuffData       = pxtShuff;  
            obj.markovMatrix    = pxTools.getMarkovFromXt(mkvData, N_STATES); 
            obj.backgroundMkv   = pxTools.getMarkovFromXt([xt(1:end-II); xt(II+1:end)], N_STATES); 
            [~, obj.nEvents]    = size(pxtData); 
        end
        
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
            errorSAll = []; 
            
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
            if obj.dofPxCorrect == 1
                obj.errorStruct = SAT.predict.dofPxCorrectError(obj.errorStruct, 1); 
            end
            obj.generatedErrorStruct = true; 
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
        
        % __ Error Plotter; 
        function plotError(obj)
            if ~obj.generatedErrorStruct
                disp("Error Structure not generated."); 
                return
            end
            [nmC, LIc] = findClassesFromStructFields(obj.errorStruct, 'reference'); 
            N_COMPS = length(LIc); 
            for cc = 1:N_COMPS
                useRows = find(nmC == cc); 
                miniStruct = obj.errorStruct(useRows); 
                fNames = {miniStruct.fieldname}; 
                % ___ Plot from Sdo Analysis Toolkit (SAT)
                plotProp = SAT.predict.assignPlotterProperties(fNames); 
                SAT.predict.plot.error_v_state(miniStruct, 'plotProp', plotProp); 
                SAT.predict.plot.error_rates(miniStruct, 'plotProp', plotProp); 
                %SAT.predict.plot.relative_error_rates(miniStruct); 
                SAT.predict.plot.pxDistance(miniStruct, 'KLD', 'plotProp', plotProp); 
                SAT.predict.plot.pxDistance(miniStruct, 'logLikelihood', 'plotProp', plotProp);
                % ____
                eFields =  {'L0_running', 'L1_running', 'KLD', 'logLikelihood'}; 
                N_E_FIELDS = length(eFields); 
                for f = 1:N_E_FIELDS
                    SAT.predict.testSig(miniStruct, 'dataField', eFields{f}, 'plotProp', plotProp); 
                end
            end
            
        end
        
    end
    
    
end
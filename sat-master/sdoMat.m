%% SDO Matrix - V2 OOP
% Data Class for dealing with the SDO matrices. For use with the SDO
% Analysis Toolkit. 
%
% 1) sdoMat may be generated from 2 'pxtDataCell' classes
% 2) sdoMat may be generated fom the 'sdo' common data structure
% 3) sdoMat may be extracted from an 'sdoMultiMat' Class

% TODO: Further optimization, parameter reduction. 
%
% --> I NEED a way to save a reduced form of the SDO, which is
% class-resilent. {XML + CSV? }

% --> Note that we don't have callers which read changes to the properties
% of pxData and x0Data before making predictions, relative to predicting
% from this class ... 

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

classdef sdoMat < handle & matlab.mixin.Copyable %& dataCellSuperClass & dataCell.dependencies.primaryData
    properties (Access = public)
        % >> In the rebuild, I think it makes most sense to rip fields as
        % components of the imported data
        xtData          dataCell.primaryData; 
        ppData          dataCell.primaryData;
        %---------------------------------
        eventShuffle    dataCell.shuffler;
        stateMapping    dataCell.stateMap;
        %--------------------------------
        % // pull in interval data //
        x0Data          dataCell.intervalSampler; 
        x1Data          dataCell.intervalSampler; 
        x0Config        dataCell.properties.intervalProperties;
        x1Config        dataCell.properties.intervalProperties;
        %-------------------------------
        % // convert intervals to px //
        px0Data         dataCell.pxAssigner;
        px1Data         dataCell.pxAssigner;
        pxConfig        dataCell.properties.pxProperties; 
        %--------------------------------------
        % || core Mix-in || 
        config      SAT.properties.computerProperties; 
        sdo         SAT.sdoComputer; % I can multiStack this, if I want ...
        % N_XT, N_PP
    end
    properties (Dependent)
        %fs
        nTrials
        nXtChannels 
        nPpChannels
        xtSensor
        ppSensor
        nStates
    end
    properties (Dependent, Hidden)
        definedState
        shuffledPpData
        importedXtData
        importedPpData
        computedSdo
    end

    methods
        %function obj = sdoMat(N_XT, N_PP, Type, stateMapping, config, x0Config, x1Config)
        function obj = sdoMat(N_XT, N_PP, Type, stateMapping, x0Config, x1Config, pxConfig)
            arguments
                N_XT = 1; 
                N_PP = 1; 
                Type {mustBeMember(Type, {'unit', 'background', 'shuffle'})} = 'unit'; 
                % these are for syncing w/ master; 
                stateMapping dataCell.stateMap = dataCell.stateMap(); 
                %config  SAT.properties.computerProperties = SAT.properties.computerProperties(); 
                x0Config dataCell.properties.intervalProperties = dataCell.properties.intervalProperties(0,0,-10); 
                x1Config dataCell.properties.intervalProperties = dataCell.properties.intervalProperties(0,0,+10); 
                pxConfig dataCell.properties.pxProperties = dataCell.properties.pxProperties();
            end
            % There's a LOT of stuff to construct. 
            obj.eventShuffle    = dataCell.shuffler(); 
            obj.stateMapping    = stateMapping; % subconstructor moved to argparse; 
            obj.x0Data          = dataCell.intervalSampler(x0Config); 
            obj.x0Config        = x0Config; % LINK
            obj.x1Data          = dataCell.intervalSampler(x1Config); 
            obj.x1Config        = x1Config; % LINK
            %
            obj.px0Data         = dataCell.pxAssigner(pxConfig); 
            obj.px1Data         = dataCell.pxAssigner(pxConfig); 
            obj.pxConfig        = pxConfig; % LINK
            % ____ Slave properties _____
            config = SAT.properties.computerProperties(); 
            obj.config          = config; 
            obj.sdo             = repelem(SAT.sdoComputer(Type, config), N_XT, N_PP); 
            % __ >> this may be reorganized; 
        end
        %{
        %-------------
        function fs = get.fs(obj)
            if ~isempty(obj.xtData)
                fs = obj.xtData.config.fs; 
            else
                fs = 0; 
            end
        end
        function set.fs(obj, fs)
            obj.x0Data.config.fs = fs; 
            obj.x1Data.config.fs = fs; 
        end
        %}
        %-------------
        function n = get.nTrials(obj)
            n = obj.xtData.nTrials; 
        end
        %--------------
        function n = get.nXtChannels(obj)
            n = obj.xtData.nChannels; 
        end
        %-------------
        function n = get.nPpChannels(obj)
            n = obj.ppData.nChannels; 
        end
        %---------------------
        function LI = get.definedState(obj)
            LI = obj.stateMapping.definedState; 
        end
        %--------------------
        function sensor = get.xtSensor(obj)
            sensor = obj.xtData.sensor(); 
        end
        function sensor = get.ppSensor(obj)
            sensor = obj.ppData.sensor(); 
        end
        %----
        function LI = get.importedXtData(obj)
            if isempty(obj.xtData)
                LI = false; 
            else
                LI = obj.xtData.sampledData;
            end
        end
        % ----
        function LI = get.importedPpData(obj)
            if isempty(obj.ppData)
                LI = false;
            else
                LI = obj.ppData.sampledData; 
            end
        end
        %------
        function LI = get.shuffledPpData(obj)
            if isempty(obj.eventShuffle)
                LI = false; 
            else
                LI = obj.eventShuffle.shuffledData; 
            end
        end
        %--------
        function LI = get.computedSdo(obj)
            LI = obj.sdo.computedSdo; 
        end
        %-------
        function n = get.nStates(obj)
            n = obj.stateMapping.nBins; 
        end
        
        %---------------------------------
        %% Import (from 'sdoStruct')
        function obj = import(obj, VAR_1, VAR_2, VAR_3, VAR_4)
            %% Usage: 
            % sdoMat.import(xtdc, ppdc, XT_CH_NO, PP_CH_NO); % for multi
            % sdoMat.import(xtdc, XT_CH_NO); 
            % sdoMat.import(ppdc, PP_CH_NO); 
            % sdoMat.import(xtdc, ppdc); % for single; 
            % sdoMat.import(pxdc, pxdc); % for pxtDataCells; 
            % sdoMat.import(px0, px1); for dataCell.pxAssigners
            if ~exist('VAR_1', 'var')
                return
            end
            % RIP FIELDS: 
            switch class(VAR_1)
                case 'xtDataCell'
                    %---------
                    if ~exist('VAR_2', 'var')
                        obj.xtData          = VAR_1.data; 
                        if VAR_1.definedState
                            obj.stateMapping    = VAR_1.stateMap; 
                        end
                        return; 
                    end
                    %-----------
                    if isnumeric(VAR_2)
                        obj.xtData = VAR_1.data.subsample(1:VAR_1.nTrials, VAR_2); % take a channel; 
                        return
                    end
                    %-----------
                    if exist('VAR_3', 'var') % xtdc, ppdc, chNO, chNO
                        obj.xtData  = VAR_1.data.subsample(1:VAR_1.nTrials, VAR_3); % take a channel; 
                        if VAR_1.definedState
                            obj.stateMapping    = VAR_1.stateMap; 
                            obj.stateMapping.subsample(1:VAR_1.nTrials, VAR_3); 
                        end
                        if exist('VAR_4', 'var')
                            obj.ppData = VAR_2.data.subsample(1:VAR_1.nTrials, VAR_4); %take a channel;
                        else
                            obj.ppData = VAR_2.data; 
                        end
                        if VAR_2.shuffledData
                            obj.eventShuffle = VAR_2.shuffler; 
                        end
                        return
                    else % xtdc, ppdc, 
                        obj.xtData = VAR_1.data; 
                        obj.ppData = VAR_2.data; 
                        if VAR_1.definedState
                            obj.stateMapping    = VAR_1.stateMap; 
                        end
                        if VAR_2.shuffledData
                            obj.eventShuffle = VAR_2.shuffler; 
                        end
                    end
                    return
                %----------------------------------------------------
                case 'dataCell.primaryData'
                    if exist('VAR_2', 'var')
                        obj.xtData = VAR_1; 
                        obj.ppData = VAR_2; 
                    else
                        obj.(VAR_1.dataType) = VAR_1; 
                    end
                case 'dataCell.pxtDataCell'
                    obj.x0Data  = VAR_1.interval; 
                    obj.px0Data = VAR_1.pxAssignment; 
                    if exist('VAR_2', 'var')
                        obj.x1Data  = VAR_2.interval;
                        obj.px1Data = VAR_2.pxAssignment; 
                    end
                case 'dataCell.pxAssigner'
                    obj.px0Data = VAR_1; 
                    if exist('VAR_2', 'var')
                        obj.px1Data = VAR_2; 
                    end
            end
        end
        
        function obj = discretize(obj)
            if ~obj.stateMapping.definedState
                disp("[sdoMat]: State Definitions not yet defined"); 
                return
            end
            obj.stateMapping.discretizeSignal; 
        end
        
        %------------------------------------------------------------------
        % // these are a series of temporary functions; 
        % --> I think I can put the shuffle/backgrounds at this step; 
        function obj = drawIntervals(obj, vars)
            arguments
                obj
                vars.useEvents {mustBeMember(vars.useEvents, {'times', 'shuffle'})} = 'times';
            end
            % __ Load from the onboard memory_
            if ~(obj.importedPpData)
                disp("ppData must be imported first");
                return
            end
            if obj.x0Data.config.fs == 0
                % haven't init'd params; 
                obj.x0Data.conform(obj.xtData); 
                obj.x1Data.conform(obj.xtData); 
            end
            
            obj.x0Data.getIntervalIndices(obj.ppData, 'dataField', vars.useEvents); 
            obj.x1Data.getIntervalIndices(obj.ppData, 'dataField', vars.useEvents);
        end
        function obj = sampleIntervals(obj)
            %___ Load from onboard memory_
            if ~(obj.importedXtData)
                disp("xtData must be imported first");
                return
            end
            obj.x0Data.conform(obj.xtData); 
            obj.x1Data.conform(obj.xtData); 
            obj.x0Data.samplePrimaryData(obj.xtData);
            obj.x1Data.samplePrimaryData(obj.xtData);
        end
        function obj = drawDistributions(obj)
            obj.px0Data.assignPx(obj.stateMapping, obj.x0Data); 
            obj.px1Data.assignPx(obj.stateMapping, obj.x1Data); 
        end
        
        function obj = compute(obj, vars)
            arguments
                obj
                vars.useEvents {mustBeMember(vars.useEvents, {'times', 'shuffle'})} = 'times';
                vars.rebuild = 0; 
            end
            
            % TODO: Better handling of shuffles in the time data; -->
            % Avoids downstream handling. 
            
            if ~obj.definedState
                % State needs to be defined first; 
                obj.stateMapping.getChannelAmp(obj.xtData); 
                obj.stateMapping.buildStateMap();
            end
            
            % __> Reading from temp onboard memory_ 
            % ___ Rebuild / Standardization / 
            switch vars.useEvents
                case 'shuffle' % 3D data
                    % // ppData is slaved from shuffle; 
                    obj.ppData = obj.eventShuffle.getPpData; 
            end
            
            % __ >> I should link these under dependencies. 
            
            if (~(obj.x0Data.calculatedIndices && obj.x1Data.calculatedIndices)) || vars.rebuild == 1
                obj.drawIntervals();%, 'useEvents', vars.useEvents); 
            end
            if (~(obj.x0Data.sampledData && obj.x1Data.sampledData)) || vars.rebuild == 1
                obj.sampleIntervals()
            end
            %
            if (~(obj.px0Data.sampledData && obj.px1Data.sampledData)) || vars.rebuild == 1
                obj.drawDistributions()
            end
            
            % ___>> This needs an upgrade for multi-comp <<___
            % Also not sure if this is an implicit flag. 
            
            % --> unless otherwise stated iterate over all. 
            
            for m = 1:obj.nXtChannels
                for u = 1:obj.nPpChannels
                    obj.sdo(m,u).compute(obj.px0Data, obj.px1Data); 
                end
                disp(strcat("Finished ", num2str(m), "/", num2str(obj.nXtChannels)));
            end

        end
            
        % || Operations on SDOs (Not analysis) ||
        % Plot; Predict; Compute; Extract; 
        %-----------------------------------------------------------------%
        function [stirpd] = getStirpd(obj, useTrials, useChannels)
            arguments
                obj
                useTrials   = 1:obj.nTrials; 
                useChannels = 1:obj.nPpChannels; 
                % --> not sure exactly how this multiplexes. 
            end
            xTmp0 = obj.x0Data.discretize(obj.stateMapping); 
            xTmp1 = obj.x1Data.discretize(obj.stateMapping); 
            
            hx0 = cellhcat(xTmp0.data(useTrials)); 
            hx1 = cellhcat(xTmp1.data(useTrials)); 
            if length(useChannels) > 1
                % --> how do we want to plot these? Separately? 
                hx0 = cellhcat(hx0(useChannels,:)'); % cat on top of each other; flatten
                hx1 = cellhcat(hx1(useChannels,:)'); % cat on top of each other; flatten;
            end
            stirpd = pxTools.getStirpd(hx0, hx1, obj.stateMapping.nBins); 
        end
        %
        function f = plotStirpd(obj, useTrials, useChannels)
            arguments
                obj
                useTrials   = 1:obj.nTrials; 
                useChannels = 1:obj.nPpChannels; 
            end
            stirpd = obj.getStirpd(useTrials, useChannels); % pass; 
            if nargout > 0
                f = figure;
            end
            % NOTE: There are other things we can pass into this function.
            pxTools.plot.stirpd(stirpd,abs(obj.x0Data.dura_nPoints) );
        end

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

            HStruct = SAT.predict.getPredictionMatrices(obj, xtdc, ppdc, useXtChNo,usePpChNo,...
                'type', MATTYPE, ...
                'backgroundSubraction', obj.backgroundSubtraction); 
            
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
        
        %% Plot (Overload)
        function plot(obj, options)
            arguments
                obj
                options.saveFig         {mustBeNumericOrLogical} = 0; 
                options.saveFormat      {mustBeMember(options.saveFormat, {'png', 'svg'})} = 'png'; 
                options.outputDirectory = []; 
                options.filter          = 1; 
            end
            % MASTER 'plot all' method; 
            % ____
            if isempty(obj.stats)
                performStats(obj);  
            end

            SAT.plot.plotHeader(obj, ...
                1,1, ...
                'filter', options.filter, ...indices
                'saveFig', options.saveFig, ....
                'saveFormat', options.saveFormat, ...
                'outputDirectory', options.outputDirectory); 
           
            N_PX0_PTS = round(abs(obj.px0DuraMs*obj.fs/1000));  
            pxTools.plot.stirpd(obj.stirpd, N_PX0_PTS, 'binDuraMs', 1000/obj.fs, 'nSpikes', obj.nEvents); 
        end

        %% Export to pxtDataCell
        %// use transition matrices of SDO to predict pxt1 from an
        %input pxtDataCell
        %{
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
            
            pxt_est = dataCell.adaptors.getConformedPxtDataCell(obj, 'px1'); 

            %pxt_est = pxtDataCell(); 
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
            %{
            pxt_est.duraMs          = obj.px1DuraMs; 
            %pxt_est.stateMapping    = obj.stateMapping; 
            pxt_est.zDelay          = obj.pxProperties.zDelay; 
            pxt_est.filterWid       = obj.pxProperties.smoothingFilterWidth; 
            pxt_est.filterStd       = obj.pxProperties.smoothingFilterStd; 
            %}
            %  __ DUMMY FILL ___ 
            pxt_est.backgroundPx    = zeros(obj.nStates,1); 
            pxt_est.backgroundMkv   = zeros(obj.nStates,1); 
            %
            pxt_est.dataMatrices = obj.transitionMat; 

           % // export to a pxt;  
            
        end
        %}
        
    end
end

%------------------------------- Depreciated Support Func ---------------%


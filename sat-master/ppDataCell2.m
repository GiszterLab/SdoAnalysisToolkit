%% ppDataCell (OOP) -- V2
% OOP-based class for handling of point-process datatypes. Designed for use
% within the SDO Analysis Toolkit and //dataCell// backbone. 

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


classdef ppDataCell2 < handle & matlab.mixin.Copyable %& dataCellSuperClass & dataCell.dependencies.primaryData
    properties
        data        dataCell.primaryData
        shuffler    dataCell.shuffler
    end
    properties (Dependent)
        % // These are piped from composed classes; 
        nTrialEvents 
        nChannels
        nTrials
        sensor
    end
    % These are just shortcut aliases
    properties (Hidden, Dependent)
        shuffledData    
    end   
    %
    methods
        %% __ CONSTRUCTOR
        function obj = ppDataCell2(N_TRIALS, N_CHANNELS)
            arguments
                N_TRIALS    {mustBeInteger} = 0; 
                N_CHANNELS  {mustBeInteger} = 0; 
            end
            obj.data         = dataCell.primaryData('ppData', N_TRIALS, N_CHANNELS);
            obj.shuffler     = dataCell.shuffler; 
        end
        
        %% Dependencies
         % Wrapper pipe
        %-------------------------------
        function nTrials = get.nTrials(obj)
            nTrials = obj.data.nTrials; 
        end
        %-------------------------------
        function nChannels = get.nChannels(obj)
            nChannels = obj.data.nChannels; 
        end
        %-----------------------------
        function sensor = get.sensor(obj)
            sensor = obj.data.sensor; 
        end
        %-----------------------------
        function nTrialEvents = get.nTrialEvents(obj)
            if ~obj.data.sampledData
                nTrialEvents = 0; 
                return
            end
           nTrialEvents = zeros(obj.nChannels, obj.nTrials); 
           for tr =1:obj.nTrials
               for ch = 1:obj.nChannels
                   nTrialEvents(ch,tr) = obj.data.data{1,tr}(ch).nEvents; 
               end
           end
        end        
        %-------------------------------
        function LI = get.shuffledData(obj)
            LI = false; 
            if ~isempty(obj.shuffler)
                LI = obj.shuffler.shuffledData; 
            end
        end

        %% Operation Methods 
        function obj = import(obj,dataHolder)
            arguments
                obj
                dataHolder
            end
            obj.data.import(dataHolder, inputname(2)); 
            obj.data.dataField = 'times'; 
            obj.data.dataType = 'ppData'; 
            obj.data.validateData; 
            obj.shuffler.data = obj.data; 
        end

        % Added 8.29.2024
        % Concatenate and flatten multiple trials; 
        % --> Put this in primary data
        function obj = combineTrials(obj, useTrials)
            arguments
                obj
                useTrials = 1:obj.nTrials;
            end
            obj = dataCell.manipulate.concatenateTrials(obj, useTrials); 
        end

        function obj = subsample(obj, useTrials, useChannels)
            arguments
                obj
                % __ Default to empty to allow for better parsing
                useTrials = []; 
                useChannels = []; 
            end
            if isempty(useTrials)
                useTrials = 1:obj.nTrials; 
            end
            if isempty(useChannels)
                useChannels = 1:obj.nChannels; 
            end
            obj.data.subsample(useTrials, useChannels); 
            %// added concrete implementation for extra fields
        end
        %---------------------------------%
        function [obj] = hcat(obj, dcList)
            arguments
                obj
                dcList
            end
            if ismember(class(dcList), 'ppDataCell')
                dcList = {dcList}; 
            end
             for c = 1:length(dcList)
                dc = dcList{c}; 
                obj.data.hcat(dc.data); 
             end
        end
        %----------------------------------%
        function [obj] = vcat(obj, dcList)
            arguments
                obj
                dcList
            end
            if ismember(class(dcList), 'ppDataCell')
                dcList = {dcList}; 
            end
            for c = 1:length(dcList)
                dc = dcList{c}; 
                obj.data.vcat(dc.data); 
            end
        end
        %-----------------------------------%
        % Used for thresholding imperfect data; 
        % --> Not really statistically valid though. 
        function obj = setMinimumISI(obj, minISI)
            arguments
                obj 
                minISI {mustBeNumeric} = 0.001; % 1 ms; 
            end
            counter = 0; 
            for tr = 1:obj.nTrials
                for n = 1:obj.nChannels
                    % per trial, if we need
                    times =  [obj.data{1,tr}(n).times]; 
                    dt = diff(times); 
                    %
                    useLI = [true dt>minISI]; % Note padding; 
                    % __ WRITEOUT___
                    obj.data{1,tr}(n).times = times(useLI); 
                    obj.data{1,tr}(n).envelope = obj.data{1,tr}(n).envelope(useLI,:); 
                    if ~isempty(obj.data{1,tr}(n).shuffle)
                        obj.data{1,tr}(n).shuffle = obj.data{1,tr}(n).shuffle(useLI,:); % not sure if this orientation is correct; 
                    end
                    obj.data{1,tr}(n).nEvents = nnz(useLI); 
                    %
                    obj.nTrialEvents(n,tr) = nnz(useLI); 
                    %
                    counter = counter + nnz(~useLI); 
                end
            end
            disp(strcat("Removed ", num2str(counter), " short timestamps"));  
        end
        
        %% EXTRACTION Methods
        
        function catTimes = getConcatEventTimes(obj, useTrials, useChannels) 
            arguments
                obj
                useTrials   {mustBeNumeric} = 1:obj.nTrials; 
                useChannels {mustBeNumeric} = 1:obj.nChannels; 
            end           
            % Call from primaryData
            catTimes = obj.data.getData(useTrials, useChannels, ...
                'dataField', 'times', 'trialwise', 0, 'channelwise', 1, ...
                'mergeMethod', 'time'); 
        end
      
        function idxArr = getRasterIndices(obj, SAMPLE_HZ, useTrials, useChannels, vars)
            % Return an {N_CHANNELS x N_TRIALS} cell of indices
            arguments
                obj
                SAMPLE_HZ   {mustBeNumeric} = obj.fs;  
                useTrials   {mustBeNumeric} = 1:obj.nTrials; 
                useChannels {mustBeNumeric} = 1:obj.nChannels; 
                vars.dataField   char {mustBeMember(vars.dataField, {'times', 'shuffle'})}  = obj.dataField; 
            end                  
            %
            N_USE_CHANNELS  = length(useChannels); 
            N_USE_TRIALS    = length(useTrials); 
            
            idxArr = cell(N_USE_CHANNELS, N_USE_TRIALS); 
            for ti=1:N_USE_TRIALS
                tr = useTrials(ti); 
                for chi = 1:N_USE_CHANNELS
                    ch = useChannels(chi); 
                    ts = obj.data{1,tr}(ch).(vars.dataField); 
                    idxArr{chi,tr} = round(ts*SAMPLE_HZ); %/SAMPLE_HZ; 
                end
            end
        end
        %_____________________________________________________
        % || X-Correlogram for inferring spike lags || 

        function [xCrlgm] = getCorrelogram(obj, vars)
        arguments
            obj
            vars.useChannels    = 1:obj.nChannels
            vars.useTrials      = 1:obj.nTrials; 
            vars.leadDura       = 0.20; 
            vars.lagDura        = 0.20; 
            vars.dt             = 0.005; % Seconds; 
            vars.norm           = 1; 
            vars.plot           = 0; 
        end

        nUseChannels = length(vars.useChannels); 
        xpsth_cell  = cell(nUseChannels); 

        for ri = 1:nUseChannels
            rr = vars.useChannels(ri); 
            for qi = 1:nUseChannels
                qq = vars.useChannels(qi); 
                %
                if ri == qi
                    % This should just a normal autocorrelogram; 
                    AUTO = 1; 
                else
                    AUTO = 0; 
                end
                %/ spiketimes here are unique and ordinal; 
                ref_st = obj.getConcatEventTimes(vars.useTrials, rr); 
                que_st = obj.getConcatEventTimes(vars.useTrials, qq); 
                ref_st = ref_st{1}; %strip
                que_st = que_st{1}; %strip

                xhist = dataCell.calculate.spikeCorrelogram(ref_st, que_st, ...
                    'dt', vars.dt, ...
                    'leadDura', vars.leadDura, ...
                    'lagDura', vars.lagDura, ...
                    'autoISI', AUTO, ...
                    'norm',   vars.norm); 
                xpsth_cell{ri,qi} = xhist; 
            end
        end
        
        if nUseChannels == 1 
            xCrlgm = xhist; 
        else
            xCrlgm = xpsth_cell; 
        end

        if vars.plot
            ppDataCell.plotCorrelogram(xCrlgm, ...
                'leadDura', vars.leadDura, 'lagDura', vars.lagDura, ...
                'dt', vars.dt); 
        end
        
        end
        %_____________________________________________________
        
        %// Set the maximal time length to each trial
        function obj = setMaxTrTime(obj, trTimeLen)
            if length(trTimeLen) == 1
                timeArr = repmat(trTimeLen, 1, obj.nTrials); 
            else
                if length(trTimeLen) ~= obj.nTrials
                    error("Mismatch in the number of time elements and the ppDataCell"); 
                else
                    timeArr = trTimeLen; 
                end
            end
            obj.data.trTimeLen = timeArr; 
        end
        %_______
        function obj = shuffle(obj,USE_TRIALS, USE_CHANNELS)
            arguments
                obj
                USE_TRIALS     {mustBeNumeric} = 1:data.nTrials; 
                USE_CHANNELS   {mustBeNumeric} = 1:data.nChannels; 
            end
            
            obj.shuffler.shuffle(...
                'useTrials', USE_TRIALS, ...
                'useChannels', USE_CHANNELS); 
            
        end
        %% Extraction Methods 

        %// Extract subsets of the dataCell containing points within a given range.  
        % --> Probably should put this in the primaryData method, if we
        % still want it. 
        function obj_out = getBinnedTimestamps(obj, tStart, tStop, useChannels, useTrials)
            arguments
                obj
                tStart      = -inf
                tStop       = inf; 
                useChannels = 1:obj.nChannels; 
                useTrials   = 1:obj.nTrials
            end
            
            obj_out = copy(obj); 
            obj_out.data.getDataInRange( [tStart,tStop], useChannels, useTrials); 

        end

        %% Conversion Methods; 
        function xtdc = getXtDataCell(obj, SAMPLE_HZ, vars)
            arguments
                obj
                SAMPLE_HZ {mustBeNumeric} = obj.fs;  
                vars.rateCode = 1; % this isn't a filter; but a bin-count;  
            end
            xtdc = xtDataCell2();
            xtData = obj.data.convertDataType('xtData', 'fs', SAMPLE_HZ, ...
                'rateCode', vars.rateCode); 
            xtdc.data = xtData; % No need to call import directly; just rip primaryData; 
            
        end
        
        %% PLOTTER METHODS
        %// Plot Spike-Rasters Rasters; 
        function f = plotSpikes(obj, useTrials, useChannels, PLOT_ALL)
            arguments
                obj
                useTrials     {mustBeNumeric} = 1:obj.nTrials;
                useChannels   {mustBeNumeric} = 1:obj.nChannels;  
                PLOT_ALL      {mustBeNumeric} = 0; 
            end
            %
            % __ Add pre-check here to exclude completely-empty channels
            useChannels = intersect(useChannels, find(sum(obj.nTrialEvents, 2))); 
            % __ 
            
            trialDurations= cumsum(obj.data.trTimeLen(useTrials));
            catSpikeTimes        = obj.getConcatEventTimes(useTrials, useChannels);  
            
            if nargout > 0
                f = figure; 
            end
                
           dataCell.plotters.plotSpikes(catSpikeTimes, ...
                obj.sensor(useChannels), ...
                trialDurations, ...
                'trialNumber', useTrials, ...
                'PLOT_ALL', PLOT_ALL); 
            %

        end
        
        function plotWaves(obj, useTrials, useRows, PLOT_ALL)
            arguments
                obj
                useTrials   {mustBeNumeric} = 1:obj.nTrials; 
                useRows     {mustBeNumeric} = 1:obj.nChannels; 
                PLOT_ALL  = 0; 
            end            
            % __ Add pre-check here to exclude completely-empty channels
            try 
                useRows = intersect(useRows, find(sum(obj.nTrialEvents, 2))); 
                plot_spikeWaveforms(obj.data, useTrials, useRows, PLOT_ALL, 'useField', 'envelope');
            catch
                return
            end
        end
        function plotISI(obj, useTrials, useRows, method)
            arguments
                obj
                useTrials   {mustBeNumeric} = 1:obj.nTrials; 
                useRows     {mustBeNumeric} = 1:obj.nChannels; 
                method      {mustBeMember(method, {'linear', 'log'})} = 'linear'; 
            end
            plot_spikeISI(obj.data, useTrials, useRows, 'useField', obj.dataField, 'type', method); 
        end
        
        %__ Plot all
        function plot(obj, useTrials, useRows, PLOT_ALL)
            arguments
                obj
                useTrials {mustBeNumeric} = 1:obj.nTrials; 
                useRows   {mustBeNumeric} = 1:obj.nChannels; 
                PLOT_ALL  = 0; 
            end   
            plotSpikes(obj, useTrials, useRows, PLOT_ALL); 
            plotWaves( obj, useTrials, useRows, PLOT_ALL); 
        end

    end  
    methods (Static)
        function [dcCombine] = combinePpDataCells(dataCellCell)
            nDC = length(dataCellCell); 
            for c = 1:nDC
                if ~isa(dataCellCell{c}, 'xtDataCell')
                    disp("Error: Unlike DataCells provided")
                    dcCombine = []; 
                    return
                end
            end
            dcCombine = dataCell.manipulate.combineDataCells(dataCellCell); 
        end
        % 
        function f = plotCorrelogram(xCrlgm, vars)
            arguments
                xCrlgm % data; either cell or vector; 
                vars.leadDura = []; 
                vars.lagDura = []; 
                vars.dt = []; 
            end
            
            if ~iscell(xCrlgm)
                xCrlgm = {xCrlgm}; %wrap; 
            end
            if isempty(vars.leadDura) || isempty(vars.lagDura)
                % if not specified, assume equal-width
                %nPts = length(xCrlgrm); 
                tVect = (1:length(xCrlgm)) - length(xCrlGrm)/2; 
            else
                tVect = (-vars.leadDura:vars.dt:vars.lagDura); 
            end
            nComps = length(xCrlgm); 
            %
            f = figure; 
            tiledlayout(nComps, nComps); 
            for r = 1:nComps
                for c = 1:nComps 
                    nexttile; 
                    area(tVect, xCrlgm{r,c}); 
                end
            end
        end
    end

end
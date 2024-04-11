%% ppDataCell
% OOP-based class for handling of point-process datatypes. Designed for use
% within the SDO Analysis Toolkit. 

% TODO: Optimize input validations
% TODO: Modularize Plotters

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

classdef ppDataCell < handle & matlab.mixin.Copyable & dataCellSuperClass & dataCell.dependencies.primaryData
        %% 'Inherited Properties'
        % data
        % metadata
        % dataField
        % nTrials
        % nChannels
        % sensor
        % fs; 
    properties
        %// List of values; 
        %data        = []; 
        %metadata    = []; 
        %nTrials     {mustBeInteger} = 0; 
        %nChannels   {mustBeInteger} = 0; 
        %sensor      = []; 
        %fs          double = 0; 
        trTimeLen   = []; 
        %dataField   char = [];  
        dataSource  char = []; 
        % __ 
        nTrialEvents = 0; %counter for spikes/trial

        % __ Shuffling Parameters; 
        nShuffles   {mustBeInteger} = 1000; 
        shuffMethod char    {mustBeMember(shuffMethod, {'isi', 'cif'})} = 'isi'; 
        shuffTau    double  = 0.2; 
        shuffCIF    char    {mustBeMember(shuffCIF, {'sg', '-hg', 'expd', 'tb'})} = '-hg'; 
    end
    properties (Dependent)
        shuffledSpikes 
    end
    %
    methods
        %% Dependencies
        function LI = get.shuffledSpikes(obj)
            if ~obj.sampledData
                LI = false;
                return
            end
            ix_tr = find(any(obj.nTrialEvents),1); 
            ix_n = any(obj.nTrialEvents(:,1:ix_tr)); 
            %ix_n = find(any(obj.nTrialEvents(:,1:ix_tr),1)); 
            if isempty(obj.data{1,ix_tr}(ix_n).shuffle) 
                LI = false; 
            else
                LI = true; 
            end
        end

        %% __ CONSTRUCTOR
        function obj = ppDataCell(N_TRIALS, N_CHANNELS)
            arguments
                N_TRIALS    {mustBeInteger} = 0; 
                N_CHANNELS  {mustBeInteger} = 0; 
            end
            S = dataCell.constructors.getPpDataHolder(N_TRIALS, N_CHANNELS); 
            obj.data        = S(1,:); 
            obj.metadata    = S(2,:); 
            obj.nTrials     = N_TRIALS; 
            obj.nChannels   = N_CHANNELS; 
        end

        %% Operation Methods 
        function obj = import(obj,dataHolder)
            %// Generic Input from the point-process type datasets; 
            % --> Theoretically, we could use whatever type of
            % spike/wavelet type extraction... 

            % --> Temporarily get this from 
            if isfield(dataHolder{1,1}, 'sensor')
                nameField = 'sensor'; 
            else
                %// depreciated legacy name
                nameField = 'electrode';   
            end

            [~, obj.nTrials] = size(dataHolder); 
            obj.nChannels   = length(dataHolder{1,1}); 
            if size(dataHolder, 1) > 1
                obj.metadata    = dataHolder(2,:); 
            end
            % -->> TODO: We will need to pass a validation here; 
            obj.sensor      = {dataHolder{1,1}.(nameField)}; 
            obj.fs          = dataHolder{1,1}.fs;    
            obj.dataField   = 'times'; %temporary
            obj.dataSource  = inputname(2); 
            obj.trTimeLen   = zeros(1,obj.nTrials); 
            
            obj.nTrialEvents = zeros(obj.nChannels, obj.nTrials); 
            
            obj.data = dataCell.constructors.getPpDataHolder(obj.nTrials, obj.nChannels); 
            %obj.data = SAT.ppDataHolder_new(obj.nTrials, obj.nChannels);
          
            %// Grab elements from the existing 'spikeTimeCell'; 
            for tr = 1:obj.nTrials
                for ch = 1:obj.nChannels
                    obj.data{1,tr}(ch).sensor           = dataHolder{1,tr}(ch).(nameField); 
                    obj.data{1,tr}(ch).fs               = obj.fs; 
                    try
                        obj.data{1,tr}(ch).(obj.dataField)  = dataHolder{1,tr}(ch).times; 
                        obj.data{1,tr}(ch).nEvents          = dataHolder{1,tr}(ch).nEvents; 
                        obj.data{1,tr}(ch).envelope         = dataHolder{1,tr}(ch).envelope; 
                    catch
                        %// depreciated naming
                        obj.data{1,tr}(ch).(obj.dataField)  = dataHolder{1,tr}(ch).time; 
                        obj.data{1,tr}(ch).nEvents          = dataHolder{1,tr}(ch).counts; 
                        try
                            obj.data{1,tr}(ch).envelope         = dataHolder{1,tr}(ch).waves;
                        catch
                            obj.data{1,tr}(ch).envelope     = 1; 
                        end
                    end
                    obj.nTrialEvents(ch,tr) = obj.data{1,tr}(ch).nEvents; 
                end
                % __ Metadata (copy)
                obj.data{2,tr} = dataHolder{2,tr}; 
            end
            % __ >> Trialwise Max value = trMaxTime
            %// We can use a separate method to set the max times... 
            for tr = 1:obj.nTrials
                for ch = 1:obj.nChannels
                    if max(obj.data{1,tr}(ch).(obj.dataField)) >  obj.trTimeLen(tr)
                        obj.trTimeLen(tr) = max(obj.data{1,tr}(ch).(obj.dataField)); 
                    end
                end
            end
        end

        function obj = subsample(obj, useTrials, useChannels)
            arguments
                obj
                % __ Default to empty to allow for better parsing
                %useTrials   = 1:obj.nTrials
                %useChannels = 1:obj.nChannels
                useTrials = []; 
                useChannels = []; 
            end
            if isempty(useTrials)
                useTrials = 1:obj.nTrials; 
            end
            if isempty(useChannels)
                useChannels = 1:obj.nChannels; 
            end

            %// added concrete implementation for extra fields
            ppdc = subsample@dataCellSuperClass(obj, useTrials, useChannels); 
            ppdc.nTrialEvents = obj.nTrialEvents(useChannels, useTrials); 
            obj = ppdc;
        end
        
        %% EXTRACTION Methods
        function binXtCell = getBinaryImpulses(obj, SAMPLE_HZ, useTrials, useChannels)
            arguments 
                obj
                SAMPLE_HZ   {mustBeNumeric} = obj.fs; 
                useTrials   {mustBeNumeric} = 1:obj.nTrials; 
                useChannels {mustBeNumeric} = 1:obj.nChannels; 
            end
            %// Use to discretize event times into index positions, at some
            %set sample Hz.           
            
            N_USE_TRIALS    = length(useTrials); 

            binXtCell = cell(1,N_USE_TRIALS); 
            
            for tri = 1:N_USE_TRIALS
                tr = useTrials(tri); 
                trEventTimesAll = {obj.data{1,tr}.(obj.dataField)}; 
                trEventTimes    = trEventTimesAll(useChannels); 
                %// Call to external function; 
                binXtCell{tr} = binarize_ppData(trEventTimes, SAMPLE_HZ, obj.trTimeLen(tr)); 
            end
        end
        
        %// Concat event times (w/ proper offset); 
        function catTimes = getConcatEventTimes(obj, useTrials, useChannels) 
            arguments
                obj
                useTrials   {mustBeNumeric} = 1:obj.nTrials; 
                useChannels {mustBeNumeric} = 1:obj.nChannels; 
            end           

            N_USE_CHANNELS  = length(useChannels); 
            N_USE_TRIALS    = length(useTrials);  
            
            tempCatCell = cell(N_USE_CHANNELS, N_USE_TRIALS); 
            tsOffset_cs = [0 cumsum(obj.trTimeLen(useTrials))]; 
            for ti = 1:N_USE_TRIALS
                tr = useTrials(ti);                 
                for chi = 1:N_USE_CHANNELS
                    ch = useChannels(chi);                 
                    ts = obj.data{1,tr}(ch).(obj.dataField); 
                    tempCatCell{chi,ti} = ts + tsOffset_cs(ti); 
                end
            end
            
            if N_USE_TRIALS == 1
                catTimes = tempCatCell; 
            else
                try 
                    % [1 x N] Vector
                    catTimes = cellhcat(tempCatCell); 
                catch
                    % [N x 1] Vector
                    catTimes = cellvcat(tempCatCell'); 
                end
                if N_USE_CHANNELS == 1
                    catTimes = {catTimes}; 
                end
            end
        end
        
        %// convert event times into positional indices of set sampleHz
        function idxArr = getRasterIndices(obj, SAMPLE_HZ, useTrials, useChannels, vars)
            % sample_hz, useTrials, useChannels, 'dataField' {'times',
            % 'shuffle'}
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
        function [idx0_Cell, idx1_Cell] = getPerieventIndices(obj, useTrials, useChannels, vars)
            arguments
                obj
                useTrials       = 1:obj.nTrials; 
                useChannels     = 1:obj.nChannels; 
                vars.n_shift    = 0; %note this differs from documentation...  
                vars.z_delay    = 0; 
                vars.t0_nPoints {mustBeInteger} = 20; 
                vars.t1_nPoints {mustBeInteger} = 20;
                vars.fs         = obj.fs
                vars.useField   {mustBeMember(vars.useField, {'times', 'shuffle'})} = 'times'; 
            end
            
            N_USE_TRIALS    = length(useTrials); 
            N_USE_PP        = length(useChannels); 
            %// Push out to the pxTools.getPerieventIndices.m script of the same name; 
            
            spkData = obj.getRasterIndices(vars.fs, useTrials, useChannels, 'dataField', vars.useField); 
            %
            idx0_Cell = cell(N_USE_PP, N_USE_TRIALS); 
            idx1_Cell = cell(N_USE_PP, N_USE_TRIALS); 
            
            for tri =1:N_USE_TRIALS
                tr = useTrials(tri); 
                maxT = round(obj.trTimeLen(tr)*vars.fs); 
                if ~all(cellfun(@isempty, spkData(:,tr)))
                    [ix0, ix1] = pxTools.getPerieventIndices(spkData(:, tr), ...
                        'n_shift', vars.n_shift, 'z_delay', vars.z_delay, ... 
                        't0_nPoints', vars.t0_nPoints, 't1_nPoints', vars.t1_nPoints, 'maxLen', maxT); 
                    % ___ 
                    idx0_Cell(:,tri) = ix0'; 
                    idx1_Cell(:,tri) = ix1'; 
                end
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
            obj.trTimeLen = timeArr; 
        end
        %_______
        function obj = shuffle(obj, useChannels, N_SHUFFLES, SHUFF_METHOD) 
            arguments
                obj
                useChannels    {mustBeNumeric} = 1:obj.nChannels; 
                N_SHUFFLES  {mustBeInteger} = obj.nShuffles;  
                SHUFF_METHOD char = obj.shuffMethod; 
            end
            N_USE_CH = length(useChannels); 
            % ___ TRIALWISE SHUFFLE RESAMPLER
            for chi = 1:N_USE_CH
                ch = useChannels(chi); 
                for tr = 1:obj.nTrials 
                    ppTrData = obj.data{1,tr}(ch).(obj.dataField); 
                    nTrEvents = obj.data{1,tr}(ch).nEvents; 
                    if nTrEvents > 1
                        switch SHUFF_METHOD
                            case {'ISI', 'isi'}
                                shuff = shuffleSpikesInsideRange(ppTrData, ppTrData(1), ppTrData(end), N_SHUFFLES); 
                            case {'CIF', 'cif'} 
                                shuff = cifReshuffle(ppTrData, obj.fs, N_SHUFFLES, obj.shuffTau,  'method', obj.shuffCIF); 
                                shuff = sort(shuff,2); 
                        end
                    else
                        shuff = repmat(ppTrData, N_SHUFFLES, 1);
                    end
                    obj.data{1,tr}(ch).shuffle = shuff; 
                end
            end
            %______ 
        end
        
        %% Extraction Methods 

        %// Extract subsets of the dataCell containing points within a given range.  
        function timeStamps = getBinnedTimestamps(obj, tStart, tStop, useChannels, useTrials)
            % tStart, tStop, useChannels, useTrials 
            arguments
                obj
                tStart      = -inf
                tStop       = inf; 
                useChannels = 1:obj.nChannels; 
                useTrials   = 1:obj.nTrials
            end
            % _____
            trialTimeStamps = obj.data(1,useTrials);
            %
            N_USE_TR = length(useTrials); 
            N_USE_CH = length(useChannels); 
            %
            timeStamps = cell(1, N_USE_TR); 

            for tr = 1:N_USE_TR
                %__ Subset
                trial_times = trialTimeStamps{tr}(useChannels); 
                
                for ch = 1:N_USE_CH
                    %// Now, bin
                    LI = (trial_times(ch).times >= tStart) & (trial_times(ch).times <= tStop); 
                    if nnz(LI) == 0 
                        trial_times(ch).envelope    = []; 
                        trial_times(ch).times       = []; 
                        trial_times(ch).nEvents     = 0; 
                    else
                        trial_times(ch).envelope    = trial_times(ch).envelope(LI,:); 
                        trial_times(ch).times       = trial_times(ch).times(LI); 
                        trial_times(ch).nEvents     = sum(LI); 
                    end
                end
                timeStamps{tr} = trial_times; 
            end
        end

        %% Conversion Methods; 
        function xtDC = getXtDataCell(obj, SAMPLE_HZ)
            % // Method to convert the observed point process data into some
            % an xtDataCell; 
            arguments
                obj
                SAMPLE_HZ {mustBeNumeric} = obj.fs;  
            end
            xtDC = xtDataCell();
            %// Copy-Over Primary data; 
            %___
            xtDC.data       = obj.data; 
            xtDC.metadata   = obj.metadata; 
            xtDC.nTrials    = obj.nTrials; 
            xtDC.nChannels  = obj.nChannels; 
            xtDC.sensor     = obj.sensor; 
            xtDC.fs         = SAMPLE_HZ; 
            xtDC.trTimeLen  = obj.trTimeLen; 
            xtDC.dataField  = 'envelope'; %obj.dataField; 
            %____
            binXtCell = getBinaryImpulses(obj, SAMPLE_HZ); %, useTrials, useChannels)
            S = dataCell.constructors.getXtDataHolder(xtDC.nTrials, xtDC.nChannels); 
            for tr = 1:xtDC.nTrials
                timeArr = 0:1/xtDC.fs: (xtDC.trTimeLen(tr)- 1/xtDC.fs); 
                %___
                for ch = 1:xtDC.nChannels
                    if ch == 1
                        S{1,tr}(ch).times = timeArr;
                    end
                    S{1,tr}(ch).sensor  = xtDC.sensor{ch}; 
                    S{1,tr}(ch).fs      = xtDC.fs; 
                    S{1,tr}(ch).raw = binXtCell{tr}(ch,:); 
                    S{1,tr}(ch).(xtDC.dataField) = binXtCell{tr}(ch,:); 
                end
            end
            xtDC.import(S); 

        end
        
        %% PLOTTER METHODS
        %// Plot Spike-Rasters Rasters; 
        function plotSpikes(obj, useTrials, useChannels, PLOT_ALL)
            arguments
                obj
                useTrials     {mustBeNumeric} = 1:obj.nTrials;
                useChannels   {mustBeNumeric} = 1:obj.nChannels;  
                PLOT_ALL      {mustBeNumeric} = 0; 
            end
            %
            % __ Add pre-check here to exclude completely-empty channels
            try 
                useChannels = intersect(useChannels, find(sum(obj.nTrialEvents, 2))); 
            end
            % __ 
            N_USE_CHANNELS  = length(useChannels); 
            N_TRIALS        = length(useTrials); 
            catTimes = getConcatEventTimes(obj, useTrials, useChannels);  
            %
            if PLOT_ALL
                cArr = rgb_colorGen(N_USE_CHANNELS, 'default'); 
            end
            timeOffVect = cumsum(obj.trTimeLen(useTrials));
            offsets = [0 timeOffVect]; 
            T_MAX = timeOffVect(end); 
            figure; 
            for chi = 1:N_USE_CHANNELS
                nSpikes = length(catTimes{chi}); 
                if PLOT_ALL == 1
                    hold on; 
                    yy = 1-chi;
                    for s = 1:nSpikes
                        line([catTimes{chi}(s) catTimes{chi}(s)], [yy-0.25, yy+0.25], 'Color', cArr(chi,:) ); 
                    end
                else
                    scatter(catTimes{chi}, (1-chi)*ones(1, nSpikes), 'square');
                end
                hold on; 
                line([0, T_MAX], [1-chi, 1-chi], 'Color', 'k')
            end
            
            for ti = 1:N_TRIALS
                line([timeOffVect(ti) timeOffVect(ti)], [0+0.5 1-chi-0.5], 'Color', 'k', 'lineStyle', '--'); 
                text(offsets(ti), -N_USE_CHANNELS+0.5, strcat("Trial#", num2str(useTrials(ti)))); 
            end
            hold off 
            yticks(-N_USE_CHANNELS+1:0); 
            yticklabels(flip(obj.sensor(useChannels))); 
            xlabel("Time (S)");     
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
            end
            plot_spikeWaveforms(obj.data, useTrials, useRows, PLOT_ALL, 'useField', 'envelope');
        end
        function plotISI(obj, useTrials, useRows, method)
            arguments
                obj
                useTrials   {mustBeNumeric} = 1:obj.nTrials; 
                useRows     {mustBeNumeric} = 1:obj.nChannels; 
                method {mustBeMember(method, {'linear', 'log'})} = 'linear'; 
            end
            plot_spikeISI(obj.data, useTrials, useRows, 'useField', obj.dataField, 'type', method); 
        end
        %__ Plot all
        function plot(obj, useTrials, useRows, PLOT_ALL)
            arguments
                obj
                useTrials {mustBeNumeric} = 1:obj.nTrials; 
                useRows  {mustBeNumeric} = 1:obj.nChannels; 
                PLOT_ALL  = 0; 
            end   

            try 
                useChannels = intersect(useChannels, find(sum(obj.nTrialEvents, 2))); 
            end

            plotSpikes(obj, useTrials, useRows, PLOT_ALL); 
            plotWaves( obj, useTrials, useRows, PLOT_ALL); 
        end
    end  
end
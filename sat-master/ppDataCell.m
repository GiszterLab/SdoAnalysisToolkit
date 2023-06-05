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

classdef ppDataCell < handle & matlab.mixin.Copyable & dataCellSuperClass
    properties
        %// List of values; 
        data        = []; 
        metadata    = []; 
        nTrials     {mustBeInteger} = 0; 
        nChannels   {mustBeInteger} = 0; 
        sensor      = []; 
        fs          double = 0; 
        trTimeLen   = []; 
        dataField   char = [];  
        dataSource  char = []; 
        % __ Shuffling Parameters; 
        nShuffles   {mustBeInteger} = 1000; 
        shuffMethod char    {mustBeMember(shuffMethod, {'isi', 'cif'})} = 'isi'; 
        shuffTau    double  = 0.2; 
        shuffCIF    char    {mustBeMember(shuffCIF, {'sg', '-hg', 'expd', 'tb'})} = '-hg'; 
    end
    %
    methods
        %% __ CONSTRUCTOR
        function obj = ppDataCell(N_TRIALS, N_CHANNELS)
            arguments
                N_TRIALS    {mustBeInteger} = 0; 
                N_CHANNELS  {mustBeInteger} = 0; 
            end
            S = SAT.ppDataHolder_new(N_TRIALS, N_CHANNELS); 
            obj.data        = S(1,:); 
            obj.metadata    = S(2,:); 
            obj.nTrials     = N_TRIALS; 
            obj.nChannels   = N_CHANNELS; 
        end

        %% Operation Methods 
        function obj = import(obj,dataCell)
            %// Generic Input from the point-process type datasets; 
            % --> Theoretically, we could use whatever type of
            % spike/wavelet type extraction... 

            % --> Temporarily get this from 
            if isfield(dataCell{1,1}, 'sensor')
                nameField = 'sensor'; 
            else
                %// depreciated legacy name
                nameField = 'electrode';   
            end

            [~, obj.nTrials] = size(dataCell); 
            obj.nChannels   = length(dataCell{1,1}); 
            obj.metadata    = dataCell(2,:); 
            % -->> TODO: We will need to pass a validation here; 
            obj.sensor      = {dataCell{1,1}.(nameField)}; 
            obj.fs          = dataCell{1,1}.fs;    
            obj.dataField   = 'times'; %temporary
            obj.dataSource  = inputname(2); 
            obj.trTimeLen   = zeros(1,obj.nTrials); 
            
            obj.data = SAT.ppDataHolder_new(obj.nTrials, obj.nChannels); 
            %// Grab elements from the existing 'spikeTimeCell'; 
            for tr = 1:obj.nTrials
                for ch = 1:obj.nChannels
                    obj.data{1,tr}(ch).sensor           = dataCell{1,tr}(ch).(nameField); 
                    try
                        obj.data{1,tr}(ch).(obj.dataField)  = dataCell{1,tr}(ch).times; 
                        obj.data{1,tr}(ch).nEvents          = dataCell{1,tr}(ch).nEvents; 
                        obj.data{1,tr}(ch).envelope         = dataCell{1,tr}(ch).envelope; 
                    catch
                        %// depreciated naming
                        obj.data{1,tr}(ch).(obj.dataField)  = dataCell{1,tr}(ch).time; 
                        obj.data{1,tr}(ch).nEvents          = dataCell{1,tr}(ch).counts; 
                        obj.data{1,tr}(ch).envelope         = dataCell{1,tr}(ch).waves; 
                    end
                end
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
        
        %% EXTRACTION Methods
        function binXtCell = getBinaryImpulses(obj, SAMPLE_HZ, useTrials, useChannels)
            arguments 
                obj
                SAMPLE_HZ   {mustBeNumeric} = obj.fs; 
                useTrials   {mustBeNumeric} = obj.nTrials; 
                useChannels {mustBeNumeric} = obj.nChannels; 
            end
            %// Use to discretize event times into index positions, at some
            %set sample Hz.           
            
            N_USE_TRIALS    = length(useTrials); 

            binXtCell = cell(1,N_USE_TRIALS); 
            
            for ti = 1:N_USE_TRIALS
                tr = useTrials(ti); 
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
                useTrials   {mustBeNumeric} = obj.nTrials; 
                useChannels {mustBeNumeric} = obj.nChannels; 
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
                catTimes = cellhcat(tempCatCell); 
                if N_USE_CHANNELS == 1
                    catTimes = {catTimes}; 
                end
            end
        end
        
        %// convert event times into positional indices of set sampleHz
        function idxArr = getRasterIndices(obj, SAMPLE_HZ, useTrials, useChannels, dataField)
            arguments
                obj
                SAMPLE_HZ   {mustBeNumeric} = obj.fs;  
                useTrials   {mustBeNumeric} = obj.nTrials; 
                useChannels {mustBeNumeric} = 1:obj.nChannels; 
                dataField   char {mustBeMember(dataField, {'times', 'shuffle'})}  = obj.dataField; 
            end                  
            %
            N_USE_CHANNELS  = length(useChannels); 
            N_USE_TRIALS    = length(useTrials); 
            
            idxArr = cell(N_USE_CHANNELS, N_USE_TRIALS); 
            for ti=1:N_USE_TRIALS
                tr = useTrials(ti); 
                for chi = 1:N_USE_CHANNELS
                    ch = useChannels(chi); 
                    ts = obj.data{1,tr}(ch).(dataField); 
                    idxArr{chi,tr} = round(ts*SAMPLE_HZ); %/SAMPLE_HZ; 
                end
            end
        end
        
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
                                %shuffSpikeCell{1,tr} = cifReshuffle(ppTrData, obj.fs, N_SHUFFLES, CIF_TAU, 'method', CIF_FIR); 
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
            xtDC.data        = obj.data; 
            xtDC.metadata    = obj.metadata; 
            xtDC.nTrials     = obj.nTrials; 
            xtDC.nChannels   = obj.nChannels; 
            xtDC.sensor   = obj.sensor; 
            xtDC.fs          = SAMPLE_HZ; 
            xtDC.trTimeLen   = obj.trTimeLen; 
            xtDC.dataField   = 'envelope'; %obj.dataField; 
            %____
           
            binXtCell = getBinaryImpulses(obj, SAMPLE_HZ); %, useTrials, useChannels)

            for tr = 1:xtDC.nTrials
                timeArr = 0:1/xtDC.fs: (xtDC.trTimeLen(tr)- 1/xtDC.fs); 
                %___
                dataStruct = struct( ... 
                    'sensor',     xtDC.sensor, ...
                    'fs',           xtDC.fs, ... 
                    'time',          cell(1,xtDC.nChannels), ... 
                    xtDC.dataField,  cell(1,xtDC.nChannels) ); 
                    xtDC.data{1,tr} = dataStruct; 
                    %___
                for ch = 1:xtDC.nChannels
                    if ch == 1
                       xtDC.data{1,tr}(ch).time = timeArr; 
                    end
                    xtDC.data{1,tr}(ch).(xtDC.dataField) = binXtCell{tr}(ch,:); 
                end
            end

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
            N_USE_CHANNELS  = length(useChannels); 
            N_TRIALS        = length(useTrials); 
            catTimes = getConcatEventTimes(obj, useTrials, useChannels);  
            %
            T_MAX = 0; 
            for chi=1:N_USE_CHANNELS
                if max(catTimes{chi} > T_MAX)
                    T_MAX = max(catTimes{chi}); 
                end
            end
            %
            if PLOT_ALL
                cArr = rgb_colorGen(N_USE_CHANNELS, 'default'); 
            end
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
            timeOffVect = cumsum(obj.trTimeLen(useTrials)); 
            for ti = 1:N_TRIALS
                line([timeOffVect(ti) timeOffVect(ti)], [0, 1-chi], 'Color', 'k', 'lineStyle', '--'); 
                text(timeOffVect(ti)-5, -N_USE_CHANNELS, strcat("Trial#", num2str(useTrials(ti)))); 
            end
            hold off 
            yticks(-N_USE_CHANNELS+1:0); 
            yticklabels(flip(obj.sensor(useChannels))); 
            xlabel("Time (S)");     
        end
        function plotWaves(obj, useTrials, useRows, PLOT_ALL)
            arguments
                obj
                useTrials {mustBeNumeric} = 1:obj.nTrials; 
                useRows  {mustBeNumeric} = 1:obj.nChannels; 
                PLOT_ALL  = 0; 
            end            
            %// Call External Function; 
            try
                plot_spikeWaveforms(obj.data, useTrials, useRows, PLOT_ALL, 'useField', 'envelope');
            catch
                %// depreciated
                plot_spikeWaveforms(obj.data, useTrials, useRows, PLOT_ALL, 'useField', 'waves');
            end
        end
        %__ Plot all
        function plot(obj, useTrials, useRows, PLOT_ALL)
            arguments
                obj
                useTrials {mustBeNumeric} = 1:obj.nTrials; 
                useRows  {mustBeNumeric} = 1:obj.nChannels; 
                PLOT_ALL  = 0; 
            end   
            plotSpikes(obj, useTrials, useRows, PLOT_ALL); 
            plotWaves( obj, useTrials, useRows, PLOT_ALL); 
        end
    end  
end
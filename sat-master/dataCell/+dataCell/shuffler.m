%% dataCell.shuffler
%
% Support class handling the resampling and shuffling operations handled by
% the probablistic and statistical testing methods; 
% 
% TODO: Future extension to more exotic shuffle methods, such as GLMs.

% Copyright (C) 2025  Trevor S. Smith
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

classdef shuffler < handle & matlab.mixin.Copyable
    properties
        data        = {}; % [INPUT] for holding data; 
        shuffleData = {}; % [OUTPUT] {nTrials, nChannels} of [nShuffles, dat]
        %
        nShuffles   {mustBeInteger} = 1000; 
        shuffMethod char    {mustBeMember(shuffMethod, {'isi', 'cif', 'random'})} = 'isi'; 
        shuffTau    double  = 0.2; 
        shuffCIF    char    {mustBeMember(shuffCIF, {'sg', '-hg', 'expd', 'tb'})} = '-hg'; 
    end
    properties(Dependent)
        importedData 
        shuffledData  % This is a logical; 
        nTrialEvents 
        nChannels
        nTrials
        sensor 
        fs
    end
    
    %% ------------------------------------- %%
    methods 
        function obj = shuffler()
            % empty constructor; 
        end
        
        function LI = get.shuffledData(obj)
            LI = false; 
            if ~isempty(obj.shuffleData)
                LI = true;
            end
        end
        %------------------
        function nTrials = get.nTrials(obj)
            if ~obj.importedData
                nTrials = size(obj.shuffleData,2); 
            else
                nTrials = obj.data.nTrials;
            end
        end
        %-------------------------------
        function nChannels = get.nChannels(obj)
            if ~obj.importedData
                nChannels = size(obj.shuffleData,1);  
            else
                nChannels = obj.data.nChannels;
            end
        end       
        %------------------------------
        function sensor = get.sensor(obj)
            sensor = obj.data.sensor; 
        end
        %-------------------------------
        function LI = get.importedData(obj)
            LI = ~isempty(obj.data); 
        end
        %----------------------------------%
        function fs = get.fs(obj)
            if ~obj.importedData
                fs = []; 
            else
                fs = obj.data.fs; 
            end
        end
        %------------------------------------------
        function obj = import(obj, data)
            arguments
                obj
                data dataCell.primaryData; 
            end
            data.validateData;
            obj.data = data; 
        end
        %------------------------------------------
        function [obj] = random(obj, nTrials, nChannels, nEvents, vars)
            arguments
                obj
                nTrials
                nChannels
                nEvents
                vars.maxX  = nEvents; % either in X (if index) or T (if times)
                vars.type {mustBeMember(vars.type, {'times', 'index'})} = 'index'; 
                vars.seed = []; 
            end
            % TODO: Implement a seed pass for reproducibility; 
            randCell = cell(nChannels, nTrials); 
            
            switch vars.type
                case 'index'
                    randCell = cellfun(@(~) ...
                        sort(randi(vars.maxX, [1,nEvents])), randCell, ...
                        'UniformOutput', 0); 
                case 'times'
                    randCell = cellfun(@(~) ...
                        sort(rand(1, nEvents)*vars.maxX), randCell, ...
                        'UniformOutput', 0); 
            end
            % Not sure if I should override the property here. 
            obj.shuffleData = randCell; 
        end
        
        % // If data is already populated, we can use this command to
        % regenerate different shuffles // 
        function [obj,data] = shuffle(obj, data, vars)
            arguments
                obj
                data                dataCell.primaryData = obj.data;
                vars.useTrials      {mustBeNumeric} = 1:data.nTrials; 
                vars.useChannels    {mustBeNumeric} = 1:data.nChannels; 
            end
            N_USE_CH = length(vars.useChannels); 
            N_USE_TR = length(vars.useTrials); 
            shuffData = cell(N_USE_CH, N_USE_TR); 
            % ___ TRIALWISE SHUFFLE RESAMPLER
            for chi = 1:N_USE_CH
                ch = vars.useChannels(chi); 
                for tri = 1:N_USE_TR
                    tr = vars.useTrials(tri); 
                    ppTrData = data.data{1,tr}(ch).(data.dataField); 
                    nTrEvents = data.nTrialEvents(ch,tr); 
                    if nTrEvents > 1
                        switch obj.shuffMethod
                            case {'isi'}
                                shuff = shuffleSpikesInsideRange(ppTrData, ppTrData(1), ppTrData(end), obj.nShuffles); 
                            case {'cif'} 
                                shuff = cifReshuffle(ppTrData, data.fs, obj.nShuffles, obj.shuffTau,  'method', obj.shuffCIF); 
                                shuff = sort(shuff,2); 
                        end
                    else
                        shuff = repmat(ppTrData, N_SHUFFLES, 1);
                    end
                    shuffData{ch,tr} = shuff; 
                    if nargout > 1
                        % This populates the 'shuffle' field of ppData;
                        data.data{1,tr}(ch).shuffle = shuff; 
                    end
                end
            end
            obj.shuffleData = shuffData;  %{nChannels,nTrials} of [nShuff, dat]            
        end
        %-------------------------------------------------------------
        function ppData = getPpData(obj, vars)
            arguments
                obj
                vars.flatten = 0; % flatten shuffles; 
            end
            % extract a (shuffled) primaryData; 
            % !!! This 'does' work, but it can cause downstream issues, if
            % shuffles are pegged to 'times'
            if obj.importedData
                ppData = obj.data; 
            else
                ppData = dataCell.primaryData('ppData', obj.nTrials, obj.nChannels);
            end
            for tr = 1:obj.nTrials
                for ch = 1:obj.nChannels
                    % // originally we ran this in the 'shuffle' field, but
                    % it may make sense to take it from spikes; 
                    if vars.flatten
                        st = obj.shuffleData{ch,tr}';
                        ppData.data{1,tr}(ch).times     = st(:);
                    else
                        ppData.data{1,tr}(ch).times     = obj.shuffleData{ch,tr}; 
                    end
                end
            end
            ppData.dataType = 'ppData'; 
            ppData.calc_trTimeLen(); 
            ppData.validateData(); 
        end
    end
end
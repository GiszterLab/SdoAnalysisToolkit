%% dataCell.shuffler
%
% Support class handling the resampling and shuffling operations handled by
% the probablistic and statistical testing methods; 
% 
% >> Eventually, it would be nice to upgrade this to compensate for other
% methods of sampling, including GLMs. 

classdef shuffler < handle & matlab.mixin.Copyable
    properties
        nShuffles   {mustBeInteger} = 1000; 
        shuffMethod char    {mustBeMember(shuffMethod, {'isi', 'cif'})} = 'isi'; 
        shuffTau    double  = 0.2; 
        shuffCIF    char    {mustBeMember(shuffCIF, {'sg', '-hg', 'expd', 'tb'})} = '-hg'; 
        %
        shuffleData = []; 
    end
    
    properties(Dependent)
        shuffledData
        nTrialEvents 
        nChannels
        nTrials
        sensor 
    end
    
    %% ------------------------------------- %%
    methods 
        function LI = get.shuffledData(obj)
            LI = false; 
            if ~isempty(obj.shuffleData)
                LI = true;
            end
        end
        %------------------
         function nTrials = get.nTrials(obj)
            nTrials = obj.data.nTrials; 
        end
        %-------------------------------
        function nChannels = get.nChannels(obj)
            nChannels = obj.data.nChannels; 
        end       
        %------------------------------
        function sensor = get.sensor(obj)
            sensor = obj.data.sensor; 
        end
        %------------------------------------------
        function obj = shuffle(obj, data, vars)
            arguments
                obj
                data                dataCell.primaryData
                vars.useTrials      {mustBeNumeric} = 1:obj.nTrials; 
                vars.useChannels    {mustBeNumeric} = 1:obj.nChannels; 
            end
            N_USE_CH = length(vars.useChannels); 
            N_USE_TR = length(vars.useTrials); 
            
            % ___ TRIALWISE SHUFFLE RESAMPLER
            for chi = 1:N_USE_CH
                ch = vars.useChannels(chi); 
                for tri = 1:N_USE_TR
                    tr = vars.useTrials(tri); 
                    ppTrData = data{1,tr}(ch).(data.dataField); 
                    nTrEvents = data.nTrialEvents(ch,tr); 
                    if nTrEvents > 1
                        switch SHUFF_METHOD
                            case {'isi'}
                                shuff = shuffleSpikesInsideRange(ppTrData, ppTrData(1), ppTrData(end), N_SHUFFLES); 
                            case {'cif'} 
                                shuff = cifReshuffle(ppTrData, obj.fs, obj.nShuffles, obj.shuffTau,  'method', obj.shuffCIF); 
                                shuff = sort(shuff,2); 
                        end
                    else
                        shuff = repmat(ppTrData, N_SHUFFLES, 1);
                    end
                    obj.data{1,tr}(ch).shuffle = shuff; 
                end
            end
            if ~obj.importedData
                return; 
            end
            
        end
    end
end
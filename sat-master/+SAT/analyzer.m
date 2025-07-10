%% SAT.analyzer (V2-OOP)
%
% NEW analysis class for SDO analysis. >> This is a breakout of existing
% methods, which allows us to better segreate SDOs for spike-triggered
% analysis vs. SDO for utilities.
%
% This class is designed for running the unit, background, and shuffle
% SDOs, and extracting the various analyzes/significance testing as
% intersections of these SDOs. 
% 
% --> This better segregates the base SDO methods/computations from the
% analysis methods. 

% --> I may want to rename/integrate the 'sdoMat' class to better hold
% everything we need. 

classdef analyzer < handle & matlab.mixin.Copyable
    properties
        unitSDO         sdoMat   % This is the master input data component; 
        shuffleSDO      sdoMat
        backgroundSDO   sdoMat
        % 
        % --Put the run properties here --
        % >> These are master; downstream components are slaved <<
        %% ____ >> THESE NEED CALLBACKS WHEN CHANGED
        algorithm {mustBeMember(algorithm, {'v3', 'v5', 'v7'})} = 'v3';
        backgroundSubtraction = true; % This should be handled upstream. [or here]
        parallelCompute       = false; 
        lowMemory             = false; 
        nShuffles             = 1000; 
        nBackgroundPts        = 10000; % per-trial
        %% ------------------------------
        %
        handleTrials          = 'concat'; % DUMMY 
        %
        pValue                = 0.05; 
        % -- Put the analysis/outputs here -- 
        errorStruct 
    end  
    properties (Dependent)
        stateMap    % slaved to unit?
        nPpChannels
        nXtChannels
        nTrials 
    end
    properties (Hidden, Dependent)
        importedData
        computedBackgroundSdo
        computedShuffleSdo
    end
    
    methods 
        % -------- Constructor --------
        function obj = analyzer(N_XT, N_PP)
            arguments
                N_XT = 1; 
                N_PP = 1;
            end
            obj.unitSDO         = sdoMat(N_XT, N_PP,'unit'); 
            obj.shuffleSDO      = sdoMat(N_XT, N_PP,'shuffle'); 
            obj.backgroundSDO   = sdoMat(N_XT, N_PP,'background'); 
        end
        % -- Aliasing
        function LI = get.importedData(obj)
            LI = obj.unitSDO.importedXtData && obj.unitSDO.importedPpData;
        end
        %----
        function n = get.nPpChannels(obj)
            if ~obj.importedData
                n = 0; 
            else
                n = obj.unitSDO.nPpChannels; 
            end
        end
        %-----
        function n = get.nXtChannels(obj)
            if ~obj.importedData
                n = 0; 
            else
                n = obj.unitSDO.nXtChannels; 
            end
        end
        % --- 
        function n = get.nTrials(obj)
            if ~obj.importedData
                n = 0; 
            else
                n = obj.unitSDO.nTrials; 
            end
        end
        % ----
        function LI = get.computedBackgroundSdo(obj)
            LI = obj.backgroundSDO.computedSdo; 
        end
        % --- 
        function LI = get.computedShuffleSdo(obj)
            LI = obj.shuffleSDO.computedSdo; 
        end
        %------------------------------
        function obj = import(obj, xtdc, ppdc, useXtChannels, usePpChannels)
            arguments
                obj
                xtdc    xtDataCell
                ppdc    ppDataCell
                useXtChannels = 1:xtdc.nChannels; 
                usePpChannels = 1:ppdc.nChannels; 
            end
            N_XT = length(useXtChannels); N_PP = length(usePpChannels);
            % __> Reconstruct here <__ 
            obj.unitSDO         = sdoMat(N_XT, N_PP,'unit'); 
            obj.shuffleSDO      = sdoMat(N_XT, N_PP,'shuffle'); 
            obj.backgroundSDO   = sdoMat(N_XT, N_PP,'background'); 
            %
            obj.unitSDO.import(xtdc, ppdc, useXtChannels, usePpChannels); 
            obj.shuffleSDO.import(xtdc, ppdc, useXtChannels, usePpChannels); 
            obj.backgroundSDO.import(xtdc, ppdc, useXtChannels, usePpChannels);
            % __ Init Relevant Structures __ 
            obj.init; %
        end

        %--------------------------
        function obj = init(obj)
            % 
            obj.shuffleSDO.eventShuffle.import(obj.shuffleSDO.ppData); 
            obj.backgroundSDO.eventShuffle.import(obj.backgroundSDO.ppData); %init/conform
                        tMax = min(obj.unitSDO.xtData.trTimeLen); 
            obj.backgroundSDO.eventShuffle.random( ...
                obj.nTrials, obj.nXtChannels, obj.nBackgroundPts, ...
                        'maxX', tMax, 'type', 'times'); 
            obj.shuffle; 
        end
        
        %------------------------------
        function obj = compute(obj)
            % // Assume we don't want to recalculate background & shuffles
            % -->> But we might want/need to if we change parameters... 
            if ~obj.computedBackgroundSdo
                for m = 1:obj.nXtChannels
                    for u = 1:obj.nPpChannels 
                        nStates = obj.backgroundSDO.stateMapping.nBins; 
                        obj.backgroundSDO.sdo(m,u).backgroundSdo = zeros(nStates); 
                    end
                end
                %obj.backgroundSDO.sdo(m,u).setBackgroundMatrix(zeros(nStates
                disp("Computing Background SDOs");
                obj.backgroundSDO.compute('useEvents', 'times'); 
            end
            
            % >> We will patch in the background SDOs here for subtraction
            
            for m = 1:obj.nXtChannels
                for u =1:obj.nPpChannels
                    obj.unitSDO.sdo(m,u).backgroundSdo = ...
                        obj.backgroundSDO.sdo(m,u).sdoMatrixNormed;
                    obj.shuffleSDO.sdo(m,u).backgroundSdo = ...
                        obj.backgroundSDO.sdo(m,u).sdoMatrixNormed;
                end
            end
            %
            if ~obj.computedShuffleSdo
                disp("Computing Shuffle SDOs"); 
                obj.shuffleSDO.compute('useEvents', 'shuffle'); 
            end
            disp("Computing Unit SDOs");
            obj.unitSDO.compute(); 
        end
        %-----------------------------
        function obj = shuffle(obj, TARGET)
            arguments
                obj 
                TARGET = 'shuffle'; % {'background', 'shuffle'}; 
            end
            % // here we assume we only want to reshuffle 'shuffle'; 
            %{
            if ~obj.importedData
                disp("Data must be imported first");
                return
            end
            %}
            switch TARGET
                case 'background'
                    tMax = min(obj.unitSDO.xtData.trTimeLen); 
                    obj.backgroundSDO.eventShuffle.random( ...
                        obj.nTrials, obj.nXtChannels, obj.nBackgroundPts, ...
                                'maxX', tMax, 'type', 'times'); 
                case 'shuffle'
                    obj.shuffleSDO.eventShuffle.shuffle();                     
            end
        end
        
    end
    
end